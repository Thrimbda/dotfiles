use std::collections::HashSet;
use std::env;
use std::ffi::{OsStr, OsString};
use std::fmt;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{self, Command, ExitStatus};

const AXIOM_CLI_TARGET: &str = "axiom-cli.target";
const GRAPHICAL_TARGET: &str = "graphical.target";
const SYSTEMCTL: &str = env!("C1CTL_SYSTEMCTL");
const HEY: &str = env!("C1CTL_HEY");
const SSH: &str = env!("C1CTL_SSH");
const AUTOSSH_REMOTE_HOST: &str = env!("C1CTL_AUTOSSH_REMOTE_HOST");
const AUTOSSH_REMOTE_USER: &str = env!("C1CTL_AUTOSSH_REMOTE_USER");
const AUTOSSH_REMOTE_PORT: &str = env!("C1CTL_AUTOSSH_REMOTE_PORT");
const AUTOSSH_REMOTE_HOST_KEY: &str = env!("C1CTL_AUTOSSH_REMOTE_HOST_KEY");
const LOCAL_SSH_HOST_KEY: &str = "/etc/ssh/ssh_host_ed25519_key.pub";
const SUDO: &str = "/run/wrappers/bin/sudo";

const STATUS_UNITS: &[&str] = &[
    AXIOM_CLI_TARGET,
    GRAPHICAL_TARGET,
    "multi-user.target",
    "getty@tty1.service",
    "greetd.service",
    "sshd.service",
    "autossh-reverse-ssh.service",
    "cloudflared.service",
    "opencode-server.service",
];

const DELEGATED_COMMANDS: &[&str] = &[
    "b", "build", "gc", "get", "hook", "info", "ops", "pr", "profile", "pull", "re", "repl", "s",
    "set", "sw", "swap", "sync", "test", "vars",
];

unsafe extern "C" {
    fn geteuid() -> u32;
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum Op {
    Call,
    Help,
    Which,
}

#[derive(Clone, Copy)]
enum Mode {
    Cli,
    Desktop,
    Status,
    Help,
}

#[derive(Debug, Default)]
struct GlobalOptions {
    dry_run: bool,
    debug: Option<u8>,
    help: bool,
}

#[derive(Debug)]
struct Invocation {
    globals: GlobalOptions,
    args: Vec<String>,
}

#[derive(Debug)]
struct ResolvedCommand {
    program: PathBuf,
    args: Vec<String>,
}

#[derive(Debug)]
struct Ctx {
    dotfiles_home: PathBuf,
    exec_path: Vec<PathBuf>,
}

#[derive(Debug)]
enum Error {
    InvalidUtf8(OsString),
    UnknownCommand(String),
    UnknownMode(String),
    UnexpectedArgument(String),
    MissingSudo,
    MissingEnv(String),
    InvalidConfig(String),
    InvalidKeyFile(PathBuf),
    CurrentExe(std::io::Error),
    Io {
        path: PathBuf,
        source: std::io::Error,
    },
    Spawn {
        program: String,
        source: std::io::Error,
    },
    Failed {
        program: String,
        status: ExitStatus,
    },
    OutputFailed {
        program: String,
        status: ExitStatus,
        stderr: String,
    },
    CheckFailed(String),
    Help(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidUtf8(value) => write!(f, "argument is not valid UTF-8: {value:?}"),
            Self::UnknownCommand(command) => write!(f, "unknown command: {command}"),
            Self::UnknownMode(mode) => write!(f, "unknown mode: {mode}"),
            Self::UnexpectedArgument(arg) => write!(f, "unexpected argument: {arg}"),
            Self::MissingSudo => write!(f, "root privileges required and {SUDO} is unavailable"),
            Self::MissingEnv(name) => write!(f, "environment variable {name} is required"),
            Self::InvalidConfig(message) => write!(f, "invalid build-time config: {message}"),
            Self::InvalidKeyFile(path) => {
                write!(f, "invalid SSH public host key file: {}", path.display())
            }
            Self::CurrentExe(error) => write!(f, "could not resolve current executable: {error}"),
            Self::Io { path, source } => write!(f, "{}: {source}", path.display()),
            Self::Spawn { program, source } => write!(f, "failed to start {program}: {source}"),
            Self::Failed { program, status } => write!(f, "{program} exited with {status}"),
            Self::OutputFailed {
                program,
                status,
                stderr,
            } => {
                write!(f, "{program} exited with {status}")?;
                if !stderr.is_empty() {
                    write!(f, ": {stderr}")?;
                }
                Ok(())
            }
            Self::CheckFailed(message) => write!(f, "{message}"),
            Self::Help(message) => write!(f, "{message}"),
        }
    }
}

struct TempFile {
    path: PathBuf,
}

impl Drop for TempFile {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.path);
    }
}

fn main() {
    let args: Vec<OsString> = env::args_os().collect();

    if let Err(error) = run(&args) {
        eprintln!("c1ctl: {error}");
        if matches!(error, Error::UnknownCommand(_) | Error::UnknownMode(_)) {
            eprintln!();
            usage();
            process::exit(2);
        }
        process::exit(1);
    }
}

fn run(args: &[OsString]) -> Result<(), Error> {
    let invocation = parse_invocation(args)?;

    if invocation.args.is_empty() {
        if invocation.globals.help {
            usage();
            return Ok(());
        }
        return run_mode(Mode::Status, args);
    }

    let first = invocation.args[0].as_str();
    match first {
        "help" | "h" => run_operation(Op::Help, &invocation.args[1..], &invocation.globals),
        "which" => run_operation(Op::Which, &invocation.args[1..], &invocation.globals),
        "mode" if invocation.globals.help => run_mode(Mode::Help, args),
        _ if invocation.globals.help => {
            run_operation(Op::Help, &invocation.args, &invocation.globals)
        }
        _ => run_call(&invocation.args, &invocation.globals, args),
    }
}

fn parse_invocation(args: &[OsString]) -> Result<Invocation, Error> {
    let mut globals = GlobalOptions::default();
    let mut parsed = Vec::new();
    let mut before_double_dash = true;

    for arg in args.iter().skip(1) {
        let arg = arg
            .to_str()
            .ok_or_else(|| Error::InvalidUtf8(arg.clone()))?;

        if before_double_dash {
            match arg {
                "--" => {
                    before_double_dash = false;
                    parsed.push(arg.to_owned());
                }
                "-!" => globals.dry_run = true,
                "-?" => globals.debug = Some(globals.debug.unwrap_or(0).max(1)),
                "-??" => globals.debug = Some(globals.debug.unwrap_or(0).max(2)),
                "-???" => globals.debug = Some(globals.debug.unwrap_or(0).max(3)),
                "-h" | "--help" => globals.help = true,
                _ => parsed.push(arg.to_owned()),
            }
        } else {
            parsed.push(arg.to_owned());
        }
    }

    if !globals.dry_run {
        globals.dry_run = env::var_os("HEYDRYRUN").is_some_and(|value| !value.is_empty());
    }

    if globals.debug.is_none() {
        globals.debug = env::var("HEYDEBUG")
            .ok()
            .and_then(|value| value.parse::<u8>().ok());
    }

    Ok(Invocation {
        globals,
        args: parsed,
    })
}

fn run_call(args: &[String], globals: &GlobalOptions, raw_args: &[OsString]) -> Result<(), Error> {
    match args.first().map(String::as_str) {
        Some("mode") => run_mode(
            parse_mode(args.get(1).map(String::as_str), &args[2..])?,
            raw_args,
        ),
        Some("cli" | "headless" | "tty") => {
            ensure_no_extra(&args[1..])?;
            run_mode(Mode::Cli, raw_args)
        }
        Some("desktop" | "graphical" | "gui") => {
            ensure_no_extra(&args[1..])?;
            run_mode(Mode::Desktop, raw_args)
        }
        Some("status") => {
            ensure_no_extra(&args[1..])?;
            run_mode(Mode::Status, raw_args)
        }
        Some("autossh") => run_autossh(&args[1..]),
        Some("reload") => {
            ensure_no_extra(&args[1..])?;
            let ctx = Ctx::new()?;
            delegate(globals, args, &ctx)
        }
        Some("path") => {
            let ctx = Ctx::new()?;
            path_command(&args[1..], &ctx)
        }
        Some(command) if DELEGATED_COMMANDS.contains(&command) => {
            let ctx = Ctx::new()?;
            delegate(globals, args, &ctx)
        }
        Some(command) if command.starts_with('@') => {
            let namespace = parse_namespace(command)?;
            let ctx = Ctx::new()?;
            if namespace == "rofi" {
                delegate(globals, args, &ctx)
            } else {
                run_resolved(Op::Call, args, globals, &ctx)
            }
        }
        Some(_) => {
            let ctx = Ctx::new()?;
            run_resolved(Op::Call, args, globals, &ctx)
        }
        None => unreachable!(),
    }
}

fn run_operation(op: Op, args: &[String], globals: &GlobalOptions) -> Result<(), Error> {
    let Some(command) = args.first().map(String::as_str) else {
        usage();
        return Ok(());
    };

    match command {
        "mode" => run_builtin_operation(op, "mode", mode_usage),
        "path" => run_builtin_operation(op, "path", path_usage),
        "autossh" => run_builtin_operation(op, "autossh", autossh_usage),
        "help" | "h" | "which" => run_builtin_operation(op, command, usage),
        command if DELEGATED_COMMANDS.contains(&command) => {
            let ctx = Ctx::new()?;
            let mut delegated = Vec::with_capacity(args.len() + 1);
            delegated.push(match op {
                Op::Call => unreachable!(),
                Op::Help => "help".to_owned(),
                Op::Which => "which".to_owned(),
            });
            delegated.extend(args.iter().cloned());
            return delegate(globals, &delegated, &ctx);
        }
        command if command.starts_with('@') => {
            let namespace = parse_namespace(command)?;
            let ctx = Ctx::new()?;
            if namespace == "rofi" {
                let mut delegated = Vec::with_capacity(args.len() + 1);
                delegated.push(match op {
                    Op::Call => unreachable!(),
                    Op::Help => "help".to_owned(),
                    Op::Which => "which".to_owned(),
                });
                delegated.extend(args.iter().cloned());
                return delegate(globals, &delegated, &ctx);
            }
            return run_resolved(op, args, globals, &ctx);
        }
        _ => {
            let ctx = Ctx::new()?;
            return run_resolved(op, args, globals, &ctx);
        }
    }

    Ok(())
}

fn run_builtin_operation(op: Op, name: &str, help: fn()) {
    match op {
        Op::Help => help(),
        Op::Which => println!("c1ctl {name}"),
        Op::Call => unreachable!(),
    }
}

fn run_resolved(op: Op, args: &[String], globals: &GlobalOptions, ctx: &Ctx) -> Result<(), Error> {
    let resolved = resolve_command(args, ctx)?;
    if is_rofi_path(&resolved.program, ctx) {
        return Err(Error::UnknownCommand(args[0].clone()));
    }

    match op {
        Op::Call => run_dynamic(&resolved, globals, ctx),
        Op::Help => script_help(&resolved.program),
        Op::Which => {
            println!(
                "{}{}",
                resolved.program.display(),
                format_args_suffix(&resolved.args)
            );
            Ok(())
        }
    }
}

fn parse_mode(arg: Option<&str>, rest: &[String]) -> Result<Mode, Error> {
    let mode = match arg.unwrap_or("status") {
        "cli" | "headless" | "tty" => Mode::Cli,
        "desktop" | "graphical" | "gui" => Mode::Desktop,
        "status" => Mode::Status,
        "help" => Mode::Help,
        value => return Err(Error::UnknownMode(value.to_owned())),
    };

    ensure_no_extra(rest)?;
    Ok(mode)
}

fn ensure_no_extra(args: &[String]) -> Result<(), Error> {
    if let Some(arg) = args.first() {
        Err(Error::UnexpectedArgument(arg.to_owned()))
    } else {
        Ok(())
    }
}

impl Ctx {
    fn new() -> Result<Self, Error> {
        let dotfiles_home = env::var_os("DOTFILES_HOME")
            .map(PathBuf::from)
            .ok_or_else(|| Error::MissingEnv("DOTFILES_HOME".to_owned()))?;
        let exec_path = exec_path(&dotfiles_home);

        Ok(Self {
            dotfiles_home,
            exec_path,
        })
    }

    fn path(&self, area: &str, segments: &[String]) -> Result<PathBuf, Error> {
        let mut base = match area {
            "home" => self.dotfiles_home.clone(),
            "bin" => self.dotfiles_home.join("bin"),
            "cache" => xdg_path("XDG_CACHE_HOME")?.join("hey"),
            "config" => self.dotfiles_home.join("config"),
            "data" => xdg_path("XDG_DATA_HOME")?.join("hey"),
            "hosts" => self.dotfiles_home.join("hosts"),
            "host" => self.dotfiles_home.join("hosts").join(host_name()?),
            "lib" => self.dotfiles_home.join("lib"),
            "modules" => self.dotfiles_home.join("modules"),
            "runtime" => xdg_path("XDG_RUNTIME_DIR")?.join("hey"),
            "state" => xdg_path("XDG_STATE_HOME")?.join("hey"),
            "themes" => self.dotfiles_home.join("modules/themes"),
            "theme" => self
                .dotfiles_home
                .join("modules/themes")
                .join(theme_name()?),
            "wm" => self.dotfiles_home.join("config").join(wm_name()?),
            "wm*" => xdg_path("XDG_CONFIG_HOME")?.join(wm_name()?),
            "profile" => PathBuf::from("/nix/var/nix/profiles/system"),
            "profile*" => xdg_path("XDG_STATE_HOME")?.join("nix/profiles/profile"),
            value => return Err(Error::Help(format!("unknown path area: {value}"))),
        };

        for segment in segments {
            base.push(segment);
        }

        Ok(base)
    }

    fn find_executable(&self, name: &str) -> Option<PathBuf> {
        let path = Path::new(name);
        if path.is_absolute() || name.contains('/') {
            return path.exists().then(|| path.to_path_buf());
        }

        self.exec_path
            .iter()
            .map(|dir| dir.join(name))
            .find(|path| path.exists())
    }
}

fn path_command(args: &[String], ctx: &Ctx) -> Result<(), Error> {
    let mut exists = false;
    let mut file = false;
    let mut directory = false;
    let mut abbrev = false;
    let mut rest = Vec::new();

    for arg in args {
        match arg.as_str() {
            "-e" => exists = true,
            "-f" => file = true,
            "-d" => directory = true,
            "-a" => abbrev = true,
            _ => rest.push(arg.clone()),
        }
    }

    let path = if rest.first().is_some_and(|arg| arg == "xdg") {
        let key = rest
            .get(1)
            .ok_or_else(|| Error::Help("path xdg requires DIR".to_owned()))?;
        let mut path = xdg_path(&format!("XDG_{}_HOME", key.to_ascii_uppercase()))?;
        for segment in &rest[2..] {
            path.push(segment);
        }
        path
    } else {
        let area = rest.first().map(String::as_str).unwrap_or("home");
        ctx.path(area, &rest[1..])?
    };

    if exists && !path.exists() {
        process::exit(1);
    }
    if file && !path.is_file() {
        process::exit(1);
    }
    if directory && !path.is_dir() {
        process::exit(1);
    }

    if abbrev {
        println!("{}", abbreviate_home(&path));
    } else {
        println!("{}", path.display());
    }

    Ok(())
}

fn resolve_command(args: &[String], ctx: &Ctx) -> Result<ResolvedCommand, Error> {
    let Some(command) = args.first() else {
        return Err(Error::UnknownCommand("".to_owned()));
    };

    if command.starts_with("./") || command.starts_with('/') {
        let program = PathBuf::from(command);
        if program.exists() {
            return Ok(ResolvedCommand {
                program,
                args: args[1..].to_vec(),
            });
        }
        return Err(Error::UnknownCommand(command.clone()));
    }

    if command.starts_with('.') {
        let name = command.trim_start_matches('.');
        let mut command_args = Vec::with_capacity(args.len());
        command_args.push(name.to_owned());
        command_args.extend(args[1..].iter().cloned());
        let bases = vec![
            ctx.path("host", &[])?.join("bin"),
            ctx.path("wm", &[])?.join("bin"),
            ctx.path("bin", &[])?,
        ];
        return resolve_from_bases(&bases, &command_args)
            .ok_or_else(|| Error::UnknownCommand(command.clone()));
    }

    match command.as_str() {
        "exec" => {
            let name = args
                .get(1)
                .ok_or_else(|| Error::UnexpectedArgument("exec requires NAME".to_owned()))?;
            let program = ctx
                .find_executable(name)
                .ok_or_else(|| Error::UnknownCommand(name.clone()))?;
            Ok(ResolvedCommand {
                program,
                args: args[2..].to_vec(),
            })
        }
        "wm" | "host" | "theme" => {
            let base = ctx.path(command, &[])?.join("bin");
            resolve_from_bases(&[base], &args[1..])
                .ok_or_else(|| Error::UnknownCommand(command.clone()))
        }
        value if value.starts_with('@') => {
            let namespace = parse_namespace(value)?;
            if namespace == "rofi" {
                return Err(Error::UnknownCommand(value.to_owned()));
            }
            let base = ctx.dotfiles_home.join("config").join(namespace).join("bin");
            resolve_from_bases(&[base], &args[1..])
                .ok_or_else(|| Error::UnknownCommand(value.to_owned()))
        }
        value => Err(Error::UnknownCommand(value.to_owned())),
    }
}

fn resolve_from_bases(bases: &[PathBuf], args: &[String]) -> Option<ResolvedCommand> {
    bases.iter().find_map(|base| resolve_from_base(base, args))
}

fn parse_namespace(command: &str) -> Result<&str, Error> {
    let Some(namespace) = command.strip_prefix('@') else {
        return Err(Error::UnknownCommand(command.to_owned()));
    };

    if namespace.is_empty()
        || !namespace
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_')
    {
        return Err(Error::UnknownCommand(command.to_owned()));
    }

    Ok(namespace)
}

fn is_safe_command_segment(arg: &str) -> bool {
    !arg.is_empty() && arg != "." && arg != ".." && !arg.contains('/') && !arg.contains('\\')
}

fn is_rofi_path(path: &Path, ctx: &Ctx) -> bool {
    let rofi_root = ctx.dotfiles_home.join("config/rofi");
    let path = fs::canonicalize(path).unwrap_or_else(|_| path.to_path_buf());
    let rofi_root = fs::canonicalize(&rofi_root).unwrap_or(rofi_root);

    path.starts_with(rofi_root)
}

fn resolve_from_base(base: &Path, args: &[String]) -> Option<ResolvedCommand> {
    if base.is_file() {
        return Some(ResolvedCommand {
            program: base.to_path_buf(),
            args: args.to_vec(),
        });
    }
    if !base.is_dir() {
        return None;
    }

    let mut dir = base.to_path_buf();
    let mut crumbs = Vec::new();
    let mut consumed = 0;

    for arg in args {
        if arg == "--" || is_option_like(arg) {
            break;
        }
        if !is_safe_command_segment(arg) {
            return None;
        }

        let crumb = dir.join(arg);
        consumed += 1;
        crumbs.push(crumb.clone());

        if let Some(next_dir) = sibling(&crumb, &["", ".d"], |path| path.is_dir()) {
            dir = next_dir;
        } else {
            break;
        }
    }

    for crumb in crumbs.iter().rev() {
        if let Some(program) = sibling(crumb, &[".janet", ".zsh", ".sh", ""], |path| path.is_file())
        {
            return Some(ResolvedCommand {
                program,
                args: args[consumed..].to_vec(),
            });
        }
        consumed = consumed.saturating_sub(1);
    }

    None
}

fn sibling<F>(path: &Path, suffixes: &[&str], predicate: F) -> Option<PathBuf>
where
    F: Fn(&Path) -> bool,
{
    let base = without_known_suffix(path, suffixes);
    suffixes
        .iter()
        .map(|suffix| PathBuf::from(format!("{}{}", base.display(), suffix)))
        .find(|path| predicate(path))
}

fn without_known_suffix(path: &Path, suffixes: &[&str]) -> PathBuf {
    let value = path.to_string_lossy();
    for suffix in suffixes {
        if !suffix.is_empty() && value.ends_with(suffix) {
            return PathBuf::from(&value[..value.len() - suffix.len()]);
        }
    }
    path.to_path_buf()
}

fn run_dynamic(
    resolved: &ResolvedCommand,
    globals: &GlobalOptions,
    ctx: &Ctx,
) -> Result<(), Error> {
    let mut command = Command::new(&resolved.program);
    command.args(&resolved.args);
    apply_child_env(&mut command, globals, ctx, Some(&resolved.program));
    run_command(command, &resolved.program.display().to_string())
}

fn delegate(globals: &GlobalOptions, args: &[String], ctx: &Ctx) -> Result<(), Error> {
    let mut command = Command::new(HEY);
    command.args(global_args(globals));
    command.args(args);
    apply_child_env(&mut command, globals, ctx, None);
    run_command(command, HEY)
}

fn apply_child_env(
    command: &mut Command,
    globals: &GlobalOptions,
    ctx: &Ctx,
    script: Option<&Path>,
) {
    command.env("DOTFILES_HOME", &ctx.dotfiles_home);
    command.env("PATH", join_paths(&ctx.exec_path));

    if let Some(script) = script {
        command.env("HEYSCRIPT", script);
    } else {
        command.env_remove("HEYSCRIPT");
    }

    apply_global_env(command, globals);
}

fn apply_global_env(command: &mut Command, globals: &GlobalOptions) {
    if globals.dry_run {
        command.env("HEYDRYRUN", "1");
    } else {
        command.env_remove("HEYDRYRUN");
    }

    if let Some(debug) = globals.debug {
        command.env("HEYDEBUG", debug.to_string());
    } else {
        command.env_remove("HEYDEBUG");
    }
}

fn global_args(globals: &GlobalOptions) -> Vec<&'static str> {
    let mut args = Vec::new();
    if globals.dry_run {
        args.push("-!");
    }
    match globals.debug {
        Some(1) => args.push("-?"),
        Some(2) => args.push("-??"),
        Some(_) => args.push("-???"),
        None => {}
    }
    args
}

fn script_help(path: &Path) -> Result<(), Error> {
    let content = fs::read_to_string(path).map_err(|source| Error::Io {
        path: path.to_path_buf(),
        source,
    })?;
    let mut lines = content.lines();
    let Some(first) = lines.next() else {
        return Err(Error::Help(format!("not a script: {}", path.display())));
    };
    if !first.starts_with("#!/") {
        return Err(Error::Help(format!("not a script: {}", path.display())));
    }

    let mut docs = Vec::new();
    for line in lines {
        let Some(stripped) = line.strip_prefix('#') else {
            break;
        };
        docs.push(stripped.strip_prefix(' ').unwrap_or(stripped));
    }

    if docs.is_empty() {
        return Err(Error::Help(format!(
            "no documentation for {}",
            path.display()
        )));
    }

    println!("{}", docs.join("\n").trim_end());
    Ok(())
}

fn usage() {
    println!("Usage: c1ctl [OPTIONS] COMMAND [ARGS]");
    println!();
    println!("Options:");
    println!("  -!            Enable dry-run mode for compatible delegated scripts.");
    println!("  -?, -??, -??? Enable debug mode.");
    println!("  -h, --help    Show help for c1ctl or a resolved command.");
    println!();
    println!("Commands:");
    println!("  mode [cli|desktop|status]  Manage the persistent Axiom systemd target.");
    println!("  cli                        Alias for `mode cli`.");
    println!("  desktop                    Alias for `mode desktop`.");
    println!("  status                     Alias for `mode status`.");
    println!("  autossh check              Verify the Axiom reverse SSH endpoint on demand.");
    println!("  reload                     Delegate to the existing hey reload path.");
    println!("  path                       Print a dotfiles or XDG path.");
    println!("  which COMMAND [ARGS]       Resolve a built-in or dynamic command.");
    println!("  help COMMAND [ARGS]        Show help for a built-in or dynamic command.");
    println!("  exec NAME [ARGS]           Execute NAME from the computed hey path.");
    println!("  wm|host|theme COMMAND      Dispatch into the matching dotfiles bin dir.");
    println!("  .COMMAND                   Search host, WM, then dotfiles bin dirs.");
    println!("  @NAMESPACE COMMAND         Dispatch into config/NAMESPACE/bin, except @rofi.");
}

fn mode_usage() {
    println!("Usage: c1ctl mode {{cli|desktop|status}}");
    println!();
    println!("  cli      Persist and switch to SSH-friendly TTY mode.");
    println!("  desktop  Persist and switch to graphical Hyprland mode.");
    println!("  status   Show the default target and key unit states.");
}

fn path_usage() {
    println!("Usage: c1ctl path [-e|-f|-d] [-a] [AREA] [SEGMENTS...]");
    println!();
    println!("Areas: home, bin, cache, config, data, hosts, host, lib, modules,");
    println!("       runtime, state, themes, theme, wm, wm*, profile, profile*, xdg DIR");
}

fn autossh_usage() {
    println!("Usage: c1ctl autossh check");
    println!();
    println!("  check  Verify remote 127.0.0.1:{AUTOSSH_REMOTE_PORT} exposes Axiom's local SSH host key.");
}

fn run_autossh(args: &[String]) -> Result<(), Error> {
    match args.first().map(String::as_str) {
        Some("check") => {
            ensure_no_extra(&args[1..])?;
            autossh_check()
        }
        Some("help" | "h") | None => {
            autossh_usage();
            Ok(())
        }
        Some(command) => Err(Error::UnknownCommand(format!("autossh {command}"))),
    }
}

fn autossh_check() -> Result<(), Error> {
    validate_autossh_config()?;

    let expected_key = local_ssh_host_key()?;
    let known_hosts = autossh_known_hosts_file()?;
    let remote = format!("{AUTOSSH_REMOTE_USER}@{AUTOSSH_REMOTE_HOST}");
    let global_known_hosts = format!("GlobalKnownHostsFile={}", known_hosts.path.display());
    let remote_scan =
        format!("timeout 8 ssh-keyscan -T 5 -p {AUTOSSH_REMOTE_PORT} 127.0.0.1 2>/dev/null");

    let mut command = Command::new(SSH);
    command.args([
        "-o",
        "BatchMode=yes",
        "-o",
        "ConnectTimeout=8",
        "-o",
        "StrictHostKeyChecking=yes",
        "-o",
        "UpdateHostKeys=no",
        "-o",
        &global_known_hosts,
        "-o",
        "UserKnownHostsFile=/dev/null",
        &remote,
        &remote_scan,
    ]);

    let output = command_stdout(command, SSH)?;
    let remote_key = first_ed25519_key(&output).ok_or_else(|| {
        Error::CheckFailed(format!(
            "no ED25519 key found on remote 127.0.0.1:{AUTOSSH_REMOTE_PORT}; is autossh-reverse-ssh.service active?"
        ))
    })?;

    if remote_key != expected_key {
        return Err(Error::CheckFailed(format!(
            "autossh endpoint key mismatch: expected {expected_key}, got {remote_key}"
        )));
    }

    println!(
        "autossh endpoint ok: {AUTOSSH_REMOTE_HOST}:127.0.0.1:{AUTOSSH_REMOTE_PORT} exposes Axiom local SSH host key"
    );
    Ok(())
}

fn validate_autossh_config() -> Result<(), Error> {
    if AUTOSSH_REMOTE_HOST.is_empty() {
        return Err(Error::InvalidConfig(
            "C1CTL_AUTOSSH_REMOTE_HOST is empty".to_owned(),
        ));
    }
    if AUTOSSH_REMOTE_USER.is_empty() {
        return Err(Error::InvalidConfig(
            "C1CTL_AUTOSSH_REMOTE_USER is empty".to_owned(),
        ));
    }
    if AUTOSSH_REMOTE_PORT.is_empty() || AUTOSSH_REMOTE_PORT == "0" {
        return Err(Error::InvalidConfig(
            "C1CTL_AUTOSSH_REMOTE_PORT is empty or zero".to_owned(),
        ));
    }
    if first_two_fields(AUTOSSH_REMOTE_HOST_KEY).is_none() {
        return Err(Error::InvalidConfig(
            "C1CTL_AUTOSSH_REMOTE_HOST_KEY is not an SSH public key".to_owned(),
        ));
    }

    Ok(())
}

fn autossh_known_hosts_file() -> Result<TempFile, Error> {
    let dir = env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(env::temp_dir);
    let content = format!("{AUTOSSH_REMOTE_HOST} {AUTOSSH_REMOTE_HOST_KEY}\n");

    for attempt in 0..100 {
        let path = dir.join(format!(
            "c1ctl-autossh-known-hosts-{}-{attempt}",
            process::id()
        ));
        match fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(&path)
        {
            Ok(mut file) => {
                file.write_all(content.as_bytes())
                    .map_err(|source| Error::Io {
                        path: path.clone(),
                        source,
                    })?;
                return Ok(TempFile { path });
            }
            Err(source) if source.kind() == std::io::ErrorKind::AlreadyExists => continue,
            Err(source) => {
                return Err(Error::Io {
                    path: path.clone(),
                    source,
                })
            }
        }
    }

    Err(Error::CheckFailed(format!(
        "could not create temporary autossh known-hosts file in {}",
        dir.display()
    )))
}

fn local_ssh_host_key() -> Result<String, Error> {
    let path = PathBuf::from(LOCAL_SSH_HOST_KEY);
    let content = fs::read_to_string(&path).map_err(|source| Error::Io {
        path: path.clone(),
        source,
    })?;
    first_two_fields(&content).ok_or(Error::InvalidKeyFile(path))
}

fn first_ed25519_key(output: &str) -> Option<String> {
    for line in output.lines() {
        let mut fields = line.split_whitespace();
        let Some(_) = fields.next() else {
            continue;
        };
        let Some(key_type) = fields.next() else {
            continue;
        };
        let Some(key) = fields.next() else {
            continue;
        };
        if key_type == "ssh-ed25519" {
            return Some(format!("{key_type} {key}"));
        }
    }

    None
}

fn first_two_fields(content: &str) -> Option<String> {
    let mut fields = content.split_whitespace();
    let first = fields.next()?;
    let second = fields.next()?;
    Some(format!("{first} {second}"))
}

fn run_mode(mode: Mode, args: &[OsString]) -> Result<(), Error> {
    match mode {
        Mode::Cli => {
            ensure_root(args)?;
            set_default(AXIOM_CLI_TARGET)?;
            isolate(AXIOM_CLI_TARGET)
        }
        Mode::Desktop => {
            ensure_root(args)?;
            set_default(GRAPHICAL_TARGET)?;
            isolate(GRAPHICAL_TARGET)
        }
        Mode::Status => status(),
        Mode::Help => {
            mode_usage();
            Ok(())
        }
    }
}

fn ensure_root(args: &[OsString]) -> Result<(), Error> {
    if effective_uid() == 0 {
        return Ok(());
    }

    if !Path::new(SUDO).exists() {
        return Err(Error::MissingSudo);
    }

    let current_exe = env::current_exe().map_err(Error::CurrentExe)?;
    let mut command = Command::new(SUDO);
    command.arg(current_exe).args(args.iter().skip(1));
    let status = command.status().map_err(|source| Error::Spawn {
        program: SUDO.to_owned(),
        source,
    })?;

    process::exit(status.code().unwrap_or(1));
}

fn effective_uid() -> u32 {
    unsafe { geteuid() }
}

fn set_default(target: &str) -> Result<(), Error> {
    systemctl(["set-default", target])
}

fn isolate(target: &str) -> Result<(), Error> {
    systemctl(["isolate", target])
}

fn status() -> Result<(), Error> {
    print!("default: ");
    systemctl(["get-default"])?;
    println!();
    println!("key units:");

    let mut args = vec!["--no-pager", "--plain", "list-units", "--all"];
    args.extend_from_slice(STATUS_UNITS);
    systemctl(args)
}

fn systemctl<I, S>(args: I) -> Result<(), Error>
where
    I: IntoIterator<Item = S>,
    S: AsRef<OsStr>,
{
    let mut command = Command::new(SYSTEMCTL);
    command.args(args);
    run_command(command, SYSTEMCTL)
}

fn run_command(mut command: Command, program: &str) -> Result<(), Error> {
    let status = command.status().map_err(|source| Error::Spawn {
        program: program.to_owned(),
        source,
    })?;

    if status.success() {
        Ok(())
    } else {
        Err(Error::Failed {
            program: program.to_owned(),
            status,
        })
    }
}

fn command_stdout(mut command: Command, program: &str) -> Result<String, Error> {
    let output = command.output().map_err(|source| Error::Spawn {
        program: program.to_owned(),
        source,
    })?;

    if !output.status.success() {
        return Err(Error::OutputFailed {
            program: program.to_owned(),
            status: output.status,
            stderr: String::from_utf8_lossy(&output.stderr).trim().to_owned(),
        });
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

fn exec_path(dotfiles_home: &Path) -> Vec<PathBuf> {
    let mut paths = Vec::new();

    if let Ok(current_exe) = env::current_exe() {
        if let Some(bin_dir) = current_exe.parent() {
            paths.push(bin_dir.to_path_buf());
        }
    }

    if let Some(value) = non_empty_env("XDG_BIN_HOME") {
        paths.push(PathBuf::from(value));
    }

    if let Some(data_home) = non_empty_env("XDG_DATA_HOME") {
        let path_file = PathBuf::from(data_home).join("hey/path");
        if let Ok(content) = fs::read_to_string(&path_file) {
            paths.extend(split_paths(content.trim_end()));
        } else {
            paths.extend(fallback_profile_paths());
        }
    } else {
        paths.extend(fallback_profile_paths());
    }

    paths.push(dotfiles_home.join("bin"));

    if let Some(path) = env::var_os("PATH") {
        paths.extend(env::split_paths(&path));
    }

    distinct_paths(paths)
}

fn fallback_profile_paths() -> Vec<PathBuf> {
    let mut paths = vec![PathBuf::from("/run/wrappers/bin")];
    if let Some(user) = non_empty_env("USER") {
        paths.push(PathBuf::from(format!("/etc/profiles/per-user/{user}/bin")));
    }
    paths.push(PathBuf::from("/run/current-system/sw/bin"));
    paths
}

fn split_paths(value: &str) -> Vec<PathBuf> {
    env::split_paths(OsStr::new(value)).collect()
}

fn distinct_paths(paths: Vec<PathBuf>) -> Vec<PathBuf> {
    let mut seen = HashSet::new();
    let mut distinct = Vec::new();
    for path in paths {
        let key = path.to_string_lossy().to_string();
        if seen.insert(key) {
            distinct.push(path);
        }
    }
    distinct
}

fn join_paths(paths: &[PathBuf]) -> OsString {
    env::join_paths(paths).unwrap_or_else(|_| OsString::new())
}

fn xdg_path(name: &str) -> Result<PathBuf, Error> {
    non_empty_env(name)
        .map(PathBuf::from)
        .ok_or_else(|| Error::MissingEnv(name.to_owned()))
}

fn non_empty_env(name: &str) -> Option<String> {
    env::var(name).ok().filter(|value| !value.is_empty())
}

fn host_name() -> Result<String, Error> {
    if let Some(host) = non_empty_env("HOST") {
        return Ok(host);
    }

    let path = PathBuf::from("/etc/hostname");
    fs::read_to_string(&path)
        .map(|value| value.trim().to_owned())
        .map_err(|source| Error::Io { path, source })
}

fn theme_name() -> Result<String, Error> {
    if let Some(theme) = non_empty_env("THEME") {
        return Ok(theme);
    }

    let data_home = xdg_path("XDG_DATA_HOME")?;
    let path = data_home.join("hey/info.json");
    let content = fs::read_to_string(&path).map_err(|source| Error::Io { path, source })?;
    find_json_string_after(&content, "active")
        .ok_or_else(|| Error::Help("could not determine active theme".to_owned()))
}

fn find_json_string_after(content: &str, key: &str) -> Option<String> {
    let marker = format!("\"{key}\"");
    let start = content.find(&marker)?;
    let rest = &content[start + marker.len()..];
    let colon = rest.find(':')?;
    let after_colon = rest[colon + 1..].trim_start();
    let after_quote = after_colon.strip_prefix('"')?;
    let end = after_quote.find('"')?;
    Some(after_quote[..end].to_owned())
}

fn wm_name() -> Result<String, Error> {
    match non_empty_env("XDG_CURRENT_DESKTOP").as_deref() {
        Some("Hyprland") => Ok("hypr".to_owned()),
        Some(value) => Err(Error::Help(format!("unrecognized desktop: {value}"))),
        None => Err(Error::MissingEnv("XDG_CURRENT_DESKTOP".to_owned())),
    }
}

fn abbreviate_home(path: &Path) -> String {
    if let Some(home) = env::var_os("HOME") {
        let home = PathBuf::from(home);
        if let Ok(rest) = path.strip_prefix(&home) {
            if rest.as_os_str().is_empty() {
                return "~".to_owned();
            }
            return format!("~/{}", rest.display());
        }
    }
    path.display().to_string()
}

fn is_option_like(arg: &str) -> bool {
    arg.starts_with('-') && arg.len() > 1
}

fn format_args_suffix(args: &[String]) -> String {
    if args.is_empty() {
        String::new()
    } else {
        format!(" {}", args.join(" "))
    }
}
