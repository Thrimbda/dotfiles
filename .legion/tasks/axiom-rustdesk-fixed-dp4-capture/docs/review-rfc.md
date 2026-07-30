# RFC Review: Persistent unattended DP-4 capture

## Verdict

**PASS**

## Findings

1. **Config boundary is explicit and implementable.** The design leaves the
   root service, its root `HOME`/`XDG_CONFIG_HOME`, and the root-owned password
   file unchanged. It gives c1 ownership only of `RustDesk2.toml`, which is the
   upstream `Config2` file used for the Wayland restore token.
2. **Startup and atomic-update behavior are accounted for.** The state-access
   script runs before `rustdesk --service` can launch its c1 child, so the
   child can load an existing restore token on its first capture request after
   a restart. The directory must be writable
   by c1 because the upstream config writer may replace the file atomically.
   Making `RustDesk2.toml` c1-owned before capture and setting the directory
   sticky prevents c1 from deleting or renaming the root-owned password file.
3. **Alternatives are adequately ruled out.** A virtual output does not expose
   the active DP-4 desktop; moving the full service config to c1 would expand
   the state and credential boundary more than needed.
4. **Verification is credible but has one external dependency.** A portal
   ScreenCast request cannot be completed locally without initiating an actual
   capture session. The RFC correctly makes a new remote connection the final
   acceptance test and requires a second connection after restart to prove
   token persistence.
5. **Rollback is sufficient.** It specifies both the declarative revert and
   the mutable ACL, sticky-bit, and ownership cleanup required to restore the
   previous root-only storage boundary.

## Residual Risk

The c1 account can alter `RustDesk2.toml`, including the saved portal token and
non-secret client options. This is an intentional, scoped change within the
existing single-owner trust boundary. It must not be extended to a shared or
untrusted account.
