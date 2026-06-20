use std::env;
use std::ffi::OsString;
use std::fmt;
use std::path::Path;
use std::process::{self, Command, ExitStatus};

const AXIOM_CLI_TARGET: &str = "axiom-cli.target";
const GRAPHICAL_TARGET: &str = "graphical.target";
const SYSTEMCTL: &str = env!("AXIOM_MODE_SYSTEMCTL");
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
enum Mode {
    Cli,
    Desktop,
    Status,
    Help,
}

impl Mode {
    fn parse(arg: Option<&str>) -> Result<Self, Error> {
        match arg.unwrap_or("status") {
            "cli" | "headless" | "tty" => Ok(Self::Cli),
            "desktop" | "graphical" | "gui" => Ok(Self::Desktop),
            "status" => Ok(Self::Status),
            "help" | "-h" | "--help" => Ok(Self::Help),
            value => Err(Error::UnknownMode(value.to_owned())),
        }
    }
}

#[derive(Debug)]
enum Error {
    UnknownMode(String),
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
            Self::UnknownMode(mode) => write!(f, "unknown mode: {mode}"),
            Self::MissingSudo => write!(f, "root privileges required and {SUDO} is unavailable"),
            Self::CurrentExe(error) => write!(f, "could not resolve current executable: {error}"),
            Self::Spawn { program, source } => write!(f, "failed to start {program}: {source}"),
            Self::Failed { program, status } => write!(f, "{program} exited with {status}"),
        }
    }
}

fn main() {
    let args: Vec<OsString> = env::args_os().collect();
    let mode_arg = args.get(1).and_then(|arg| arg.to_str());

    if let Err(error) = run(Mode::parse(mode_arg), &args) {
        eprintln!("axiom-mode: {error}");
        if matches!(error, Error::UnknownMode(_)) {
            eprintln!();
            usage();
            process::exit(2);
        }
        process::exit(1);
    }
}

fn run(mode: Result<Mode, Error>, args: &[OsString]) -> Result<(), Error> {
    match mode? {
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
            usage();
            Ok(())
        }
    }
}

fn usage() {
    println!("Usage: axiom-mode {{cli|desktop|status}}");
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

fn systemctl<I, S>(args: I) -> Result<(), Error>
where
    I: IntoIterator<Item = S>,
    S: AsRef<std::ffi::OsStr>,
{
    let status = Command::new(SYSTEMCTL)
        .args(args)
        .status()
        .map_err(|source| Error::Spawn {
            program: SYSTEMCTL,
            source,
        })?;

    if status.success() {
        Ok(())
    } else {
        Err(Error::Failed {
            program: SYSTEMCTL,
            status,
        })
    }
}
