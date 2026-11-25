# HIS 与基础数据字典测试环境访问

连接 aTrust 后，用医院配置的 SSH 别名经堡垒机登录院内测试机。以下 HTTP 请求在测试机终端执行。院内主机名、SSH 别名和凭据由项目的内部联调资料提供。

```bash
ssh -o BatchMode=yes -o PreferredAuthentications=publickey \
  -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no \
  -o ConnectionAttempts=1 "$HIS_TEST_SSH_ALIAS"
```

先在本机把 `HIS_TEST_SSH_ALIAS` 设为院方配置的别名。登录后，在测试机上将下面命令里的 `HIS_TEST_HOST` 和 `INTEGRATION_TEST_HOST` 分别设为内部联调资料提供的主机地址。上一次启用的本机 `127.0.0.1:38080` 转发在 2026-11-25 检查时已停止。需要从本机工具直接访问时，请使用院方允许的转发方式。

## HIS REST 接口

测试入口为 `http://${HIS_TEST_HOST}:38080`。Base、Clinic、Bill 和统一网关的已知路径使用 `/heren/api` 前缀，消息平台入口使用 `/heren-notify`。

```bash
curl --noproxy '*' --connect-timeout 4 --max-time 8 --get \
  "http://${HIS_TEST_HOST}:38080/heren/api/base/v3/open/organization/dept" \
  --data-urlencode 'branchHosp=1' \
  --data-urlencode 'deptName=生殖' \
  --data-urlencode 'withDirectorDoctor=false'
```

2026-11-25 从测试机执行上面的科室查询，收到 HTTP 200 和 3 条科室记录。

| 入口 | 方法与路径 | 最近结果 |
| --- | --- | --- |
| 换取 token | `POST /heren/api/openplatform/auth/token` | 2026-11-12 使用 JSON 字段 `appKey` 换取成功，当次有效期 90 分钟 |
| 统一业务网关 | `POST /heren/api/openplatform/invoke` | 2026-11-12 使用有效 `accessToken` 和文档中的操作名作为 `serviceName`，9 个查询均为 HTTP 200、业务码 401，需确认应用权限和正式映射 |
| 患者详情查询 | `POST /heren/api/bill/v3/open/patient/query-patient-info` | 院方 V2 提供接口和调用样例，测试环境待验证 |

接口定义见院方《生殖小程序 HIS 接口整合文档 V2》。测试参数、返回值与待确认路由见内部《生殖小程序 HIS 接口文档（测试环境）》Markdown。V2 的示例来自院方标注的正式环境，联调时使用上面的测试入口。

## 基础数据字典与集成平台

| 入口 | 地址 | 用途和状态 |
| --- | --- | --- |
| 和仁集成平台 | `http://${INTEGRATION_TEST_HOST}:1080` | SZAPP SOAP WSDL 在 2026-11-25 返回 HTTP 200。具体 WSDL 路径见内部联调资料 |
| 本项目订阅回调 | `http://<订阅方主机>:<约定端口>/mdmService` | 由订阅方提供，和仁平台向其主动推送。实际地址、端口、订阅范围和认证串待院方与订阅方确认 |
| 历史订阅目标 | `8090` 端口下的 `/mdmSyn`、`/mdmSynList` | 平台历史配置中的投递目标。2026-11-12 从测试机访问超时，本项目的订阅地址仍待确认 |

接口定义见院方《和仁信息集成平台接口文档 — 主数据订阅系统》V2.0 第 3—5 节。文档的 `/mdmService` 示例使用 `8080`，实际回调端口以部署约定为准。订阅数据按 `Head` 和 `Body` 封装，覆盖人员、科室、费用项目、检查和检验项目等字典。若需订阅，请确认回调的网络可达性、认证方式和初始全量数据交付方式。SZAPP 的 WSDL 可达仅验证集成平台入口，字典推送需通过订阅回调单独验收。
