use std::{
    collections::HashSet,
    env,
    net::SocketAddr,
    sync::Arc,
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

use axum::{
    Json, Router,
    extract::{Query, State},
    http::{
        HeaderMap, StatusCode,
        header::{AUTHORIZATION, CONTENT_TYPE},
    },
    response::{IntoResponse, Response},
    routing::get,
};
use base64::{Engine as _, engine::general_purpose::URL_SAFE_NO_PAD};
use ed25519_dalek::{Signer, SigningKey};
use hmac::{Hmac, Mac};
use reqwest::{Client, RequestBuilder, redirect::Policy};
use serde::{Deserialize, Serialize, de::DeserializeOwned};
use serde_json::json;
use sha2::Sha256;
use tokio::{net::TcpListener, time::timeout};
use uuid::Uuid;

const ACCOUNT_PREFIX: &str = "ONEEX_PORTFOLIO";
const AUTH_BASE_URL: &str = "https://auth.ntnl.io";
const ONEEX_BASE_URL: &str = "https://1ex.ntnl.io";
const INBOUND_TOKEN_CONTEXT: &[u8] = b"1ex-portfolio-adapter/inbound-token/v1";
const START_TIMEOUT: Duration = Duration::from_millis(1_500);
const VERIFY_TIMEOUT: Duration = Duration::from_millis(1_500);
const READ_TIMEOUT: Duration = Duration::from_millis(4_500);
const LOGOUT_TIMEOUT: Duration = Duration::from_secs(1);
const MAX_POSITIONS_RESPONSE_BYTES: usize = 1_048_576;

type HmacSha256 = Hmac<Sha256>;

#[derive(Clone)]
struct AppState {
    config: Arc<Config>,
    client: Client,
}

struct Config {
    user_id: Uuid,
    account_id: String,
    signing_key: SigningKey,
    excluded_fund_id: String,
    auth_base_url: String,
    oneex_base_url: String,
    bind_addr: SocketAddr,
}

impl Config {
    fn from_env() -> Result<Self, String> {
        let user_id = Uuid::parse_str(&required_env("USER_ID")?)
            .map_err(|_| "USER_ID must be a UUID".to_string())?;
        let signing_key = signing_key_from_env()?;
        let excluded_fund_id = required_env("EXCLUDED_FUND_ID")?;
        let auth_base_url = origin_from_env("AUTH_BASE_URL", AUTH_BASE_URL)?;
        let oneex_base_url = origin_from_env("ONEEX_BASE_URL", ONEEX_BASE_URL)?;
        let bind_addr = env::var("BIND_ADDR")
            .unwrap_or_else(|_| "0.0.0.0:8080".to_string())
            .parse()
            .map_err(|_| "BIND_ADDR must be a socket address".to_string())?;

        Ok(Self {
            account_id: format!("{ACCOUNT_PREFIX}/{user_id}"),
            user_id,
            signing_key,
            excluded_fund_id,
            auth_base_url,
            oneex_base_url,
            bind_addr,
        })
    }
}

#[derive(Deserialize)]
struct PositionsQuery {
    account_id: Option<String>,
}

#[derive(Serialize)]
struct AccountMeta {
    account_id: String,
}

#[derive(Debug, Serialize)]
struct Position {
    position_id: String,
    product_id: String,
    account_id: String,
    updated_at: i64,
    base_currency: String,
    quote_currency: String,
    amount: f64,
    position_price: f64,
    closable_price: f64,
    notional_value: f64,
    notional_currency: String,
    settlement_currency: String,
    valuation: f64,
    floating_profit: f64,
    comment: String,
}

#[derive(Deserialize)]
struct ChallengeResponse {
    request_id: String,
    challenge: String,
}

#[derive(Deserialize)]
struct SessionResponse {
    access_token: String,
}

#[derive(Deserialize)]
struct AccessTokenClaims {
    sub: String,
}

#[derive(Deserialize)]
struct UpstreamFund {
    id: String,
    name: String,
    target_currency: String,
    unit_price: f64,
    viewer: Option<FundViewer>,
}

#[derive(Deserialize)]
struct FundViewer {
    share: f64,
    after_tax_assets: f64,
}

#[derive(Deserialize)]
struct UpstreamBalance {
    user_id: String,
    currency: String,
    balance: f64,
}

#[derive(Clone, Copy)]
enum ApiError {
    BadRequest,
    Unauthorized,
    Upstream,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            Self::BadRequest => (StatusCode::BAD_REQUEST, "invalid request"),
            Self::Unauthorized => (StatusCode::UNAUTHORIZED, "invalid authorization"),
            Self::Upstream => (StatusCode::BAD_GATEWAY, "upstream request failed"),
        };
        (status, Json(json!({ "message": message }))).into_response()
    }
}

#[derive(Debug)]
struct UpstreamError;

#[tokio::main]
async fn main() {
    if let Err(error) = run().await {
        eprintln!("adapter startup failed: {error}");
        std::process::exit(1);
    }
}

async fn run() -> Result<(), String> {
    let args: Vec<String> = env::args().collect();
    if args.len() > 1 {
        if args.len() == 2 && args[1] == "--print-inbound-token" {
            println!(
                "{}",
                derive_inbound_token(&signing_key_from_env()?.to_bytes())
            );
            return Ok(());
        }
        return Err("usage: oneex-portfolio-adapter [--print-inbound-token]".to_string());
    }

    let config = Arc::new(Config::from_env()?);
    let client = Client::builder()
        .redirect(Policy::none())
        .build()
        .map_err(|_| "failed to create HTTP client".to_string())?;
    let state = AppState { config, client };
    let app = app(state.clone());
    let listener = TcpListener::bind(state.config.bind_addr)
        .await
        .map_err(|_| "failed to bind BIND_ADDR".to_string())?;

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .map_err(|_| "HTTP server stopped unexpectedly".to_string())
}

fn app(state: AppState) -> Router {
    Router::new()
        .route("/api/accounts", get(accounts))
        .route("/api/positions", get(positions))
        .with_state(state)
}

async fn shutdown_signal() {
    let _ = tokio::signal::ctrl_c().await;
}

async fn accounts(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<AccountMeta>>, ApiError> {
    require_authorization(&headers, &state.config)?;
    Ok(Json(vec![AccountMeta {
        account_id: state.config.account_id.clone(),
    }]))
}

async fn positions(
    State(state): State<AppState>,
    headers: HeaderMap,
    Query(query): Query<PositionsQuery>,
) -> Result<Response, ApiError> {
    require_authorization(&headers, &state.config)?;
    let account_id = query.account_id.ok_or(ApiError::BadRequest)?;
    if account_id != state.config.account_id {
        return positions_response(Vec::new());
    }

    let started = Instant::now();
    match load_positions(&state).await {
        Ok(rows) => {
            let position_count = rows.len();
            match positions_response(rows) {
                Ok(response) => {
                    eprintln!(
                        "event=positions status=200 duration_ms={} positions={position_count}",
                        started.elapsed().as_millis()
                    );
                    Ok(response)
                }
                Err(error) => {
                    eprintln!(
                        "event=positions status=502 duration_ms={}",
                        started.elapsed().as_millis()
                    );
                    Err(error)
                }
            }
        }
        Err(_) => {
            eprintln!(
                "event=positions status=502 duration_ms={}",
                started.elapsed().as_millis()
            );
            Err(ApiError::Upstream)
        }
    }
}

fn positions_response(rows: Vec<Position>) -> Result<Response, ApiError> {
    let body = serialize_positions(&rows)?;
    Ok(([(CONTENT_TYPE, "application/json")], body).into_response())
}

fn serialize_positions(rows: &[Position]) -> Result<Vec<u8>, ApiError> {
    let body = serde_json::to_vec(rows).map_err(|_| ApiError::Upstream)?;
    if body.len() > MAX_POSITIONS_RESPONSE_BYTES {
        Err(ApiError::Upstream)
    } else {
        Ok(body)
    }
}

fn require_authorization(headers: &HeaderMap, config: &Config) -> Result<(), ApiError> {
    if is_authorized(headers, config) {
        Ok(())
    } else {
        Err(ApiError::Unauthorized)
    }
}

fn is_authorized(headers: &HeaderMap, config: &Config) -> bool {
    let Some(header) = headers
        .get(AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
    else {
        return false;
    };
    let Some(token) = header.strip_prefix("Bearer ") else {
        return false;
    };
    let Ok(token) = URL_SAFE_NO_PAD.decode(token) else {
        return false;
    };
    let mut mac = HmacSha256::new_from_slice(&config.signing_key.to_bytes())
        .expect("Ed25519 seeds always have a valid HMAC key length");
    mac.update(INBOUND_TOKEN_CONTEXT);
    mac.verify_slice(&token).is_ok()
}

async fn load_positions(state: &AppState) -> Result<Vec<Position>, UpstreamError> {
    let session = start_session(state).await?;
    let result = async {
        require_matching_subject(&session.access_token, state.config.user_id)?;
        let updated_at = current_millis()?;
        let (funds, balances) = fetch_upstream_data(state, &session.access_token).await?;
        map_positions(&state.config, funds, balances, updated_at)
    }
    .await;
    let logout_result = logout_session(state, &session.access_token).await;

    let rows = result?;
    logout_result?;
    Ok(rows)
}

async fn start_session(state: &AppState) -> Result<SessionResponse, UpstreamError> {
    let public_key = URL_SAFE_NO_PAD.encode(state.config.signing_key.verifying_key().to_bytes());
    let challenge: ChallengeResponse = with_timeout(
        START_TIMEOUT,
        request_json(
            state
                .client
                .post(format!("{}/ed25519/start", state.config.auth_base_url))
                .json(&json!({ "public_key": public_key })),
        ),
    )
    .await?;
    let signature = URL_SAFE_NO_PAD.encode(
        state
            .config
            .signing_key
            .sign(challenge.challenge.as_bytes())
            .to_bytes(),
    );

    with_timeout(
        VERIFY_TIMEOUT,
        request_json(
            state
                .client
                .post(format!("{}/ed25519/verify", state.config.auth_base_url))
                .json(&json!({
                    "request_id": challenge.request_id,
                    "signature": signature,
                    "redirect_uri": state.config.oneex_base_url.as_str(),
                })),
        ),
    )
    .await
}

async fn fetch_upstream_data(
    state: &AppState,
    access_token: &str,
) -> Result<(Vec<UpstreamFund>, Vec<UpstreamBalance>), UpstreamError> {
    with_timeout(READ_TIMEOUT, async {
        tokio::try_join!(
            request_json(
                state
                    .client
                    .get(format!("{}/api/funds", state.config.oneex_base_url))
                    .bearer_auth(access_token),
            ),
            request_json(
                state
                    .client
                    .get(format!("{}/api/balances", state.config.oneex_base_url))
                    .bearer_auth(access_token),
            ),
        )
    })
    .await
}

async fn logout_session(state: &AppState, access_token: &str) -> Result<(), UpstreamError> {
    with_timeout(
        LOGOUT_TIMEOUT,
        request_success(
            state
                .client
                .post(format!("{}/session/logout", state.config.auth_base_url))
                .bearer_auth(access_token),
        ),
    )
    .await
}

async fn request_json<T>(request: RequestBuilder) -> Result<T, UpstreamError>
where
    T: DeserializeOwned,
{
    let response = request.send().await.map_err(|_| UpstreamError)?;
    if !response.status().is_success() {
        return Err(UpstreamError);
    }
    response.json().await.map_err(|_| UpstreamError)
}

async fn request_success(request: RequestBuilder) -> Result<(), UpstreamError> {
    let response = request.send().await.map_err(|_| UpstreamError)?;
    if response.status().is_success() {
        Ok(())
    } else {
        Err(UpstreamError)
    }
}

async fn with_timeout<T>(
    duration: Duration,
    operation: impl std::future::Future<Output = Result<T, UpstreamError>>,
) -> Result<T, UpstreamError> {
    timeout(duration, operation)
        .await
        .map_err(|_| UpstreamError)?
}

fn require_matching_subject(
    access_token: &str,
    expected_user_id: Uuid,
) -> Result<(), UpstreamError> {
    let mut segments = access_token.split('.');
    let (Some(header), Some(payload), Some(signature), None) = (
        segments.next(),
        segments.next(),
        segments.next(),
        segments.next(),
    ) else {
        return Err(UpstreamError);
    };
    if header.is_empty() || payload.is_empty() || signature.is_empty() {
        return Err(UpstreamError);
    }
    let payload = URL_SAFE_NO_PAD.decode(payload).map_err(|_| UpstreamError)?;
    let claims: AccessTokenClaims = serde_json::from_slice(&payload).map_err(|_| UpstreamError)?;
    let subject = Uuid::parse_str(&claims.sub).map_err(|_| UpstreamError)?;
    if subject == expected_user_id {
        Ok(())
    } else {
        Err(UpstreamError)
    }
}

fn map_positions(
    config: &Config,
    funds: Vec<UpstreamFund>,
    balances: Vec<UpstreamBalance>,
    updated_at: i64,
) -> Result<Vec<Position>, UpstreamError> {
    let mut positions = Vec::new();

    for fund in funds {
        if fund.id == config.excluded_fund_id {
            continue;
        }
        let Some(viewer) = fund.viewer else {
            continue;
        };
        if !viewer.share.is_finite()
            || !viewer.after_tax_assets.is_finite()
            || !fund.unit_price.is_finite()
            || viewer.share < 0.0
            || viewer.after_tax_assets < 0.0
            || fund.unit_price < 0.0
            || fund.target_currency != "USD"
            || fund.id.trim().is_empty()
            || fund.name.trim().is_empty()
        {
            return Err(UpstreamError);
        }
        if viewer.share == 0.0 {
            continue;
        }

        positions.push(Position {
            position_id: format!("{ACCOUNT_PREFIX}/FUND/{}", fund.id),
            product_id: format!("FUND/{}", fund.id),
            account_id: config.account_id.clone(),
            updated_at,
            base_currency: "USD".to_string(),
            quote_currency: "USD".to_string(),
            amount: viewer.share,
            position_price: 0.0,
            closable_price: fund.unit_price,
            notional_value: viewer.after_tax_assets,
            notional_currency: "USD".to_string(),
            settlement_currency: "USD".to_string(),
            valuation: viewer.after_tax_assets,
            floating_profit: 0.0,
            comment: format!("{}; after-tax valuation", fund.name.trim()),
        });
    }

    for balance in balances {
        if !balance.balance.is_finite()
            || balance.balance < 0.0
            || balance.user_id != config.user_id.to_string()
            || balance.currency != "USD"
        {
            return Err(UpstreamError);
        }
        if balance.balance == 0.0 {
            continue;
        }

        positions.push(Position {
            position_id: format!("{ACCOUNT_PREFIX}/CASH/USD"),
            product_id: "CASH/USD".to_string(),
            account_id: config.account_id.clone(),
            updated_at,
            base_currency: "USD".to_string(),
            quote_currency: "USD".to_string(),
            amount: balance.balance,
            position_price: 1.0,
            closable_price: 1.0,
            notional_value: balance.balance,
            notional_currency: "USD".to_string(),
            settlement_currency: "USD".to_string(),
            valuation: balance.balance,
            floating_profit: 0.0,
            comment: "Available USD balance".to_string(),
        });
    }

    let mut ids = HashSet::with_capacity(positions.len());
    if positions
        .iter()
        .any(|position| !ids.insert(&position.position_id))
    {
        return Err(UpstreamError);
    }
    Ok(positions)
}

fn current_millis() -> Result<i64, UpstreamError> {
    let elapsed = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|_| UpstreamError)?;
    i64::try_from(elapsed.as_millis()).map_err(|_| UpstreamError)
}

fn derive_inbound_token(seed: &[u8; 32]) -> String {
    let mut mac = HmacSha256::new_from_slice(seed)
        .expect("Ed25519 seeds always have a valid HMAC key length");
    mac.update(INBOUND_TOKEN_CONTEXT);
    URL_SAFE_NO_PAD.encode(mac.finalize().into_bytes())
}

fn signing_key_from_env() -> Result<SigningKey, String> {
    let encoded = required_env("ED25519_PRIVATE_KEY")?;
    let decoded = URL_SAFE_NO_PAD
        .decode(encoded)
        .map_err(|_| "ED25519_PRIVATE_KEY must be unpadded base64url".to_string())?;
    let seed: [u8; 32] = decoded
        .as_slice()
        .try_into()
        .map_err(|_| "ED25519_PRIVATE_KEY must decode to 32 bytes".to_string())?;
    Ok(SigningKey::from_bytes(&seed))
}

fn required_env(name: &str) -> Result<String, String> {
    let value = env::var(name).map_err(|_| format!("{name} is required"))?;
    let value = value.trim();
    if value.is_empty() {
        Err(format!("{name} is required"))
    } else {
        Ok(value.to_string())
    }
}

fn origin_from_env(name: &str, default: &str) -> Result<String, String> {
    let value = env::var(name).unwrap_or_else(|_| default.to_string());
    let url = reqwest::Url::parse(value.trim())
        .map_err(|_| format!("{name} must be an HTTP(S) origin"))?;
    if !matches!(url.scheme(), "http" | "https")
        || url.host_str().is_none()
        || !url.username().is_empty()
        || url.password().is_some()
        || url.query().is_some()
        || url.fragment().is_some()
        || url.path() != "/"
    {
        return Err(format!(
            "{name} must be an HTTP(S) origin without path or credentials"
        ));
    }
    let origin = url.origin().ascii_serialization();
    if origin == "null" {
        Err(format!("{name} must be an HTTP(S) origin"))
    } else {
        Ok(origin)
    }
}

#[cfg(test)]
mod tests {
    use std::sync::{
        Arc,
        atomic::{AtomicUsize, Ordering},
    };

    use axum::{
        Router,
        extract::State,
        http::HeaderValue,
        routing::{get, post},
    };
    use serde_json::Value;
    use tokio::task::JoinHandle;

    use super::*;

    const USER_ID: &str = "739886fd-2137-4d2a-92dd-cab5cfe29249";

    #[derive(Clone)]
    struct MockState {
        token: String,
        funds: Value,
        balances: Value,
        fail_funds: bool,
        fail_logout: bool,
        logout_calls: Arc<AtomicUsize>,
    }

    #[test]
    fn derived_bearer_requires_the_derived_value() {
        let config = test_config("http://127.0.0.1:1");
        let mut headers = HeaderMap::new();
        headers.insert(
            AUTHORIZATION,
            HeaderValue::from_str(&format!(
                "Bearer {}",
                derive_inbound_token(&config.signing_key.to_bytes())
            ))
            .unwrap(),
        );
        assert!(is_authorized(&headers, &config));

        headers.insert(AUTHORIZATION, HeaderValue::from_static("Bearer invalid"));
        assert!(!is_authorized(&headers, &config));
    }

    #[tokio::test]
    async fn inbound_endpoints_require_authentication_and_keep_discovery_static() {
        let state = test_state("http://127.0.0.1:1");
        let token = derive_inbound_token(&state.config.signing_key.to_bytes());
        let account_id = state.config.account_id.clone();
        let (base_url, server) = serve_router(app(state)).await;
        let client = Client::new();

        let unauthorized = client
            .get(format!("{base_url}/api/accounts"))
            .send()
            .await
            .unwrap();
        assert_eq!(unauthorized.status(), StatusCode::UNAUTHORIZED);

        let accounts = client
            .get(format!("{base_url}/api/accounts"))
            .header(AUTHORIZATION, format!("Bearer {token}"))
            .send()
            .await
            .unwrap();
        assert_eq!(accounts.status(), StatusCode::OK);
        assert_eq!(
            accounts.json::<Value>().await.unwrap(),
            json!([{ "account_id": account_id }])
        );

        let unknown = client
            .get(format!("{base_url}/api/positions"))
            .header(AUTHORIZATION, format!("Bearer {token}"))
            .query(&[("account_id", "unknown")])
            .send()
            .await
            .unwrap();
        assert_eq!(unknown.status(), StatusCode::OK);
        assert_eq!(unknown.json::<Value>().await.unwrap(), json!([]));

        server.abort();
    }

    #[test]
    fn rejects_access_token_for_a_different_user() {
        let other = Uuid::new_v4();
        assert!(require_matching_subject(&test_jwt(other), test_user()).is_err());
    }

    #[test]
    fn maps_funds_and_cash_with_one_timestamp() {
        let config = test_config("http://127.0.0.1:1");
        let rows = map_positions(
            &config,
            sample_funds(),
            sample_balances(),
            1_787_068_800_000,
        )
        .unwrap();

        assert_eq!(rows.len(), 2);
        assert_eq!(rows[0].position_id, "ONEEX_PORTFOLIO/FUND/fund-a");
        assert_eq!(rows[0].amount, 482.831_322_72);
        assert_eq!(rows[0].valuation, 1_067.171_716_6);
        assert_eq!(rows[1].position_id, "ONEEX_PORTFOLIO/CASH/USD");
        assert!(rows.iter().all(|row| row.updated_at == 1_787_068_800_000));
    }

    #[test]
    fn rejects_a_non_usd_held_fund() {
        let config = test_config("http://127.0.0.1:1");
        let funds = vec![UpstreamFund {
            id: "fund-cny".to_string(),
            name: "CNY Fund".to_string(),
            target_currency: "CNY".to_string(),
            unit_price: 1.0,
            viewer: Some(FundViewer {
                share: 1.0,
                after_tax_assets: 1.0,
            }),
        }];

        assert!(map_positions(&config, funds, Vec::new(), 1).is_err());
    }

    #[test]
    fn rejects_positions_larger_than_the_custom_source_limit() {
        let config = test_config("http://127.0.0.1:1");
        let mut rows = map_positions(&config, sample_funds(), sample_balances(), 1).unwrap();
        rows[0].comment = "x".repeat(MAX_POSITIONS_RESPONSE_BYTES);

        assert!(serialize_positions(&rows).is_err());
    }

    #[tokio::test]
    async fn fetches_both_sources_and_logs_out() {
        let mock = sample_mock(test_jwt(test_user()));
        let logout_calls = mock.logout_calls.clone();
        let (base_url, server) = serve_mock(mock).await;
        let state = test_state(&base_url);

        let rows = load_positions(&state).await.unwrap();

        assert_eq!(rows.len(), 2);
        assert_eq!(logout_calls.load(Ordering::SeqCst), 1);
        server.abort();
    }

    #[tokio::test]
    async fn logs_out_after_a_read_failure() {
        let mut mock = sample_mock(test_jwt(test_user()));
        mock.fail_funds = true;
        let logout_calls = mock.logout_calls.clone();
        let (base_url, server) = serve_mock(mock).await;
        let state = test_state(&base_url);

        assert!(load_positions(&state).await.is_err());
        assert_eq!(logout_calls.load(Ordering::SeqCst), 1);
        server.abort();
    }

    #[tokio::test]
    async fn logs_out_after_an_identity_mismatch() {
        let mock = sample_mock(test_jwt(Uuid::new_v4()));
        let logout_calls = mock.logout_calls.clone();
        let (base_url, server) = serve_mock(mock).await;
        let state = test_state(&base_url);

        assert!(load_positions(&state).await.is_err());
        assert_eq!(logout_calls.load(Ordering::SeqCst), 1);
        server.abort();
    }

    #[tokio::test]
    async fn fails_when_logout_fails() {
        let mut mock = sample_mock(test_jwt(test_user()));
        mock.fail_logout = true;
        let logout_calls = mock.logout_calls.clone();
        let (base_url, server) = serve_mock(mock).await;
        let state = test_state(&base_url);

        assert!(load_positions(&state).await.is_err());
        assert_eq!(logout_calls.load(Ordering::SeqCst), 1);
        server.abort();
    }

    fn test_user() -> Uuid {
        Uuid::parse_str(USER_ID).unwrap()
    }

    fn test_config(base_url: &str) -> Config {
        let user_id = test_user();
        Config {
            user_id,
            account_id: format!("{ACCOUNT_PREFIX}/{user_id}"),
            signing_key: SigningKey::from_bytes(&[7; 32]),
            excluded_fund_id: "portfolio-nav-fund".to_string(),
            auth_base_url: base_url.to_string(),
            oneex_base_url: base_url.to_string(),
            bind_addr: "127.0.0.1:0".parse().unwrap(),
        }
    }

    fn test_state(base_url: &str) -> AppState {
        AppState {
            config: Arc::new(test_config(base_url)),
            client: Client::builder().redirect(Policy::none()).build().unwrap(),
        }
    }

    fn test_jwt(user_id: Uuid) -> String {
        let payload = URL_SAFE_NO_PAD.encode(json!({ "sub": user_id }).to_string());
        format!("header.{payload}.signature")
    }

    fn sample_funds() -> Vec<UpstreamFund> {
        vec![
            UpstreamFund {
                id: "fund-a".to_string(),
                name: "CRYPTO predict MM".to_string(),
                target_currency: "USD".to_string(),
                unit_price: 2.245_017_24,
                viewer: Some(FundViewer {
                    share: 482.831_322_72,
                    after_tax_assets: 1_067.171_716_6,
                }),
            },
            UpstreamFund {
                id: "portfolio-nav-fund".to_string(),
                name: "Portfolio NAV".to_string(),
                target_currency: "USD".to_string(),
                unit_price: 1.0,
                viewer: Some(FundViewer {
                    share: 99.0,
                    after_tax_assets: 99.0,
                }),
            },
        ]
    }

    fn sample_balances() -> Vec<UpstreamBalance> {
        vec![UpstreamBalance {
            user_id: USER_ID.to_string(),
            currency: "USD".to_string(),
            balance: 5.25,
        }]
    }

    fn sample_mock(token: String) -> MockState {
        MockState {
            token,
            funds: json!([
                {
                    "id": "fund-a",
                    "name": "CRYPTO predict MM",
                    "target_currency": "USD",
                    "unit_price": 2.24501724,
                    "viewer": { "share": 482.83132272, "after_tax_assets": 1067.1717166 }
                },
                {
                    "id": "portfolio-nav-fund",
                    "name": "Portfolio NAV",
                    "target_currency": "USD",
                    "unit_price": 1.0,
                    "viewer": { "share": 99.0, "after_tax_assets": 99.0 }
                }
            ]),
            balances: json!([
                { "user_id": USER_ID, "currency": "USD", "balance": 5.25 }
            ]),
            fail_funds: false,
            fail_logout: false,
            logout_calls: Arc::new(AtomicUsize::new(0)),
        }
    }

    async fn serve_mock(state: MockState) -> (String, JoinHandle<()>) {
        let app = Router::new()
            .route("/ed25519/start", post(mock_start))
            .route("/ed25519/verify", post(mock_verify))
            .route("/session/logout", post(mock_logout))
            .route("/api/funds", get(mock_funds))
            .route("/api/balances", get(mock_balances))
            .with_state(state);
        serve_router(app).await
    }

    async fn serve_router(app: Router) -> (String, JoinHandle<()>) {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        let server = tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });
        (format!("http://{address}"), server)
    }

    async fn mock_start() -> Json<Value> {
        Json(json!({ "request_id": "request-1", "challenge": "challenge" }))
    }

    async fn mock_verify(
        State(state): State<MockState>,
        Json(request): Json<Value>,
    ) -> Result<Json<Value>, StatusCode> {
        if request
            .get("redirect_uri")
            .and_then(Value::as_str)
            .is_none()
        {
            return Err(StatusCode::BAD_REQUEST);
        }
        Ok(Json(json!({ "access_token": state.token })))
    }

    async fn mock_logout(State(state): State<MockState>) -> Result<Json<Value>, StatusCode> {
        state.logout_calls.fetch_add(1, Ordering::SeqCst);
        if state.fail_logout {
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        } else {
            Ok(Json(json!({ "ok": true })))
        }
    }

    async fn mock_funds(State(state): State<MockState>) -> Result<Json<Value>, StatusCode> {
        if state.fail_funds {
            Err(StatusCode::BAD_GATEWAY)
        } else {
            Ok(Json(state.funds))
        }
    }

    async fn mock_balances(State(state): State<MockState>) -> Json<Value> {
        Json(state.balances)
    }
}
