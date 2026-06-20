use std::env;
use std::ffi::OsString;
use std::fmt;
use std::path::Path;
use std::process::{self, Command, ExitStatus};

const AXIOM_CLI_TARGET: &str = "axiom-cli.target";
const GRAPHICAL_TARGET: &str = "graphical.target";
const SYSTEMCTL: &str = env!("AXIOMCTL_SYSTEMCTL");
const HEY: &str = env!("AXIOMCTL_HEY");
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

unsafe extern "C" {
    fn geteuid() -> u32;
}

#[derive(Clone, Copy)]
enum Action {
    Mode(Mode),
    Reload,
    Help,
}

#[derive(Clone, Copy)]
enum Mode {
    Cli,
    Desktop,
    Status,
    Help,
}

#[derive(Debug)]
enum Error {
    InvalidUtf8(OsString),
    UnknownCommand(String),
    UnknownMode(String),
    UnexpectedArgument(String),
    MissingSudo,
    CurrentExe(std::io::Error),
    Spawn {
        program: &'static str,
        source: std::io::Error,
    },
    Failed {
        program: &'static str,
        status: ExitStatus,
    },
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidUtf8(value) => write!(f, "argument is not valid UTF-8: {value:?}"),
            Self::UnknownCommand(command) => write!(f, "unknown command: {command}"),
            Self::UnknownMode(mode) => write!(f, "unknown mode: {mode}"),
            Self::UnexpectedArgument(arg) => write!(f, "unexpected argument: {arg}"),
            Self::MissingSudo => write!(f, "root privileges required and {SUDO} is unavailable"),
            Self::CurrentExe(error) => write!(f, "could not resolve current executable: {error}"),
            Self::Spawn { program, source } => write!(f, "failed to start {program}: {source}"),
            Self::Failed { program, status } => write!(f, "{program} exited with {status}"),
        }
    }
}

fn main() {
    let args: Vec<OsString> = env::args_os().collect();

    if let Err(error) = run(&args) {
        eprintln!("axiomctl: {error}");
        if matches!(error, Error::UnknownCommand(_) | Error::UnknownMode(_)) {
            eprintln!();
            usage();
            process::exit(2);
        }
        process::exit(1);
    }
}

fn run(args: &[OsString]) -> Result<(), Error> {
    match parse_action(args)? {
        Action::Mode(mode) => run_mode(mode, args),
        Action::Reload => reload(),
        Action::Help => {
            usage();
            Ok(())
        }
    }
}

fn parse_action(args: &[OsString]) -> Result<Action, Error> {
    let args = parse_args(args)?;

    match args.first().copied().unwrap_or("status") {
        "help" | "-h" | "--help" => Ok(Action::Help),
        "mode" => Ok(Action::Mode(parse_mode(
            args.get(1).copied(),
            args.get(2..).unwrap_or(&[]),
        )?)),
        "cli" | "headless" | "tty" => Ok(Action::Mode(parse_mode_alias(Mode::Cli, &args[1..])?)),
        "desktop" | "graphical" | "gui" => {
            Ok(Action::Mode(parse_mode_alias(Mode::Desktop, &args[1..])?))
        }
        "status" => Ok(Action::Mode(parse_mode_alias(Mode::Status, &args[1..])?)),
        "reload" => {
            ensure_no_extra(&args[1..])?;
            Ok(Action::Reload)
        }
        value => Err(Error::UnknownCommand(value.to_owned())),
    }
}

fn parse_args(args: &[OsString]) -> Result<Vec<&str>, Error> {
    args.iter()
        .skip(1)
        .map(|arg| arg.to_str().ok_or_else(|| Error::InvalidUtf8(arg.clone())))
        .collect()
}

fn parse_mode(arg: Option<&str>, rest: &[&str]) -> Result<Mode, Error> {
    let mode = match arg.unwrap_or("status") {
        "cli" | "headless" | "tty" => Mode::Cli,
        "desktop" | "graphical" | "gui" => Mode::Desktop,
        "status" => Mode::Status,
        "help" | "-h" | "--help" => Mode::Help,
        value => return Err(Error::UnknownMode(value.to_owned())),
    };

    ensure_no_extra(rest)?;
    Ok(mode)
}

fn parse_mode_alias(mode: Mode, rest: &[&str]) -> Result<Mode, Error> {
    ensure_no_extra(rest)?;
    Ok(mode)
}

fn ensure_no_extra(args: &[&str]) -> Result<(), Error> {
    if let Some(arg) = args.first() {
        Err(Error::UnexpectedArgument((*arg).to_owned()))
    } else {
        Ok(())
    }
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

fn usage() {
    println!("Usage: axiomctl COMMAND [ARGS]");
    println!();
    println!("Commands:");
    println!("  mode [cli|desktop|status]  Manage the persistent Axiom systemd target.");
    println!("  cli                        Alias for `mode cli`.");
    println!("  desktop                    Alias for `mode desktop`.");
    println!("  status                     Alias for `mode status`.");
    println!("  reload                     Trigger the reviewed Axiom reload hook path.");
}

fn mode_usage() {
    println!("Usage: axiomctl mode {{cli|desktop|status}}");
    println!();
    println!("  cli      Persist and switch to SSH-friendly TTY mode.");
    println!("  desktop  Persist and switch to graphical Hyprland mode.");
    println!("  status   Show the default target and key unit states.");
}

fn ensure_root(args: &[OsString]) -> Result<(), Error> {
    if effective_uid() == 0 {
        return Ok(());
    }

    if !Path::new(SUDO).exists() {
        return Err(Error::MissingSudo);
    }

    let current_exe = env::current_exe().map_err(Error::CurrentExe)?;
    let status = Command::new(SUDO)
        .arg(current_exe)
        .args(args.iter().skip(1))
        .status()
        .map_err(|source| Error::Spawn {
            program: SUDO,
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

fn reload() -> Result<(), Error> {
    run_fixed(HEY, ["reload"])
}

fn systemctl<I, S>(args: I) -> Result<(), Error>
where
    I: IntoIterator<Item = S>,
    S: AsRef<std::ffi::OsStr>,
{
    run_fixed(SYSTEMCTL, args)
}

fn run_fixed<I, S>(program: &'static str, args: I) -> Result<(), Error>
where
    I: IntoIterator<Item = S>,
    S: AsRef<std::ffi::OsStr>,
{
    let status = Command::new(program)
        .args(args)
        .status()
        .map_err(|source| Error::Spawn { program, source })?;

    if status.success() {
        Ok(())
    } else {
        Err(Error::Failed { program, status })
    }
}
