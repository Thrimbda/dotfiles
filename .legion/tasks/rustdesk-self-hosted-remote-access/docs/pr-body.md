## Summary

- Charlie's direct listener first advertised the wrong fake-IP. After correcting it to the LAN address, the controller still received `No route to host`; the attempted client-side force-relay path did not actually engage.
- With user approval, enable RustDesk Server 1.1.14's server-side force-relay mechanism by adding only `ALWAYS_USE_RELAY=Y` to Acorn's hbbs service.

The production diff is one line in `hosts/acorn/default.nix`. Generated hbbr configuration is unchanged, as are package, key, authentication, listener, port and firewall settings.

## Validation

- Exact hbbs-only differential, generated units, full Acorn build/closure and pinned 1.1.14 source semantics: **PASS**.
- Change review: **PASS** for PR entry, with no blocking findings.
- Runtime relay: **NOT RUN / NOT PASS**.

## After Merge

From clean merged `origin/master`, prove an hbbs-only restart and hbbr PID/listener continuity. Then use a fresh Axiom↔Charlie session to prove actual hbbr pairing/traffic and no winning direct path, revalidate Charlie's ready-bound PID identities, rerun authentication positive/negative controls, and record relay bandwidth/egress cost with an owner and containment threshold.

Walkthrough: [`.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md`](.legion/tasks/rustdesk-self-hosted-remote-access/docs/report-walkthrough.md)
