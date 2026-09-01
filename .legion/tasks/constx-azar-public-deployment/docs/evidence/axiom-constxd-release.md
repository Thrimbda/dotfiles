# Axiom Const X Release Build

## Scope

Build the exact Const X source on Axiom, prove its portable runtime with `doctor`, then stage the immutable release artifact on Azar without starting it.

## Input

- Const X source commit: `45c21f0a2f437cb11cb5e316c29d5ff08cbef471`
- source staging root: `/home/c1/.cache/constx-azar-public-deployment/constx-45c21f0a2f437cb11cb5e316c29d5ff08cbef471`
- build: `CARGO_BUILD_JOBS=1 cargo build --release -p constxd`
- doctor runtime: the generated Acorn Node 22.23.2 path, with a fresh temporary XDG state.

## Result

- release build exit: `0` in `4m 17s`
- `doctor` exit: `0`
- portable Pi observed version: `0.84.3`
- RPC `get_state`: success; no model provider/configuration was used and no database was created in the fresh doctor state.
- SHA-256:

```text
a8a69e9fbede3aca665fddc3921ba7be1b54d9b319370c23d473eb5682c489d5
```

## Staging

- Axiom and Azar both hold the exact executable at:

```text
/home/c1/.local/share/constx/releases/45c21f0a2f437cb11cb5e316c29d5ff08cbef471/constxd
```

- Azar copy hash matches Axiom and is executable.
- No systemd unit was started and no DNS record was changed in this staging step.
