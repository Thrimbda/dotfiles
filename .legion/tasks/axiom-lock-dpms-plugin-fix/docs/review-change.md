# Change Review: Axiom Caelestia Lock DPMS Behavior

Result: PASS

Review scope: correctness, scope compliance, validation evidence, rollback, and
session-lock security.

## Blocking Findings

None.

## Findings

- `modules/desktop/caelestia-lock-dpms-shell.patch` arms the one-shot timer only
  from `WlSessionLock.secureChanged` when `secure` is true. Its
  `lockedChanged` handler only cleans up after the lock is false, avoiding the
  Quickshell 0.3 missing lock-acquisition notify.
- `hosts/axiom/default.nix` enables only Axiom's native
  `key_press_enables_dpms` and `mouse_move_enables_dpms` settings. It does not
  alter another host's wake policy, idle timeout, idle owner, or authentication
  implementation.
- The focused Node assertion and zero-fuzz patch application cover the patched
  QML structure. Full Axiom system builds and generated Lua evaluation passed.
- Live samples prove DPMS off at 65 seconds while `LOCK` remains active;
  virtual pointer motion wakes both displays while `LOCK` and IPC lock state
  remain true; another 65 seconds does not rearm the timer; and a fresh
  timer-owned DPMS-off cycle restores displays on authorized unlock.
- Temporary Howdy and fingerprint suppression was user-authorized for the
  controlled test, restored to `true`, and removed from final source.

## Session-Lock Security

Security lens applied and passed. The change adds no unlock IPC, authentication
bypass, or user-controlled privileged command. Native compositor wake restores
display power before lock-surface input handling; runtime samples prove wake
does not release the lock boundary.

## Non-Blocking Note

The former QML zero-timeout wake monitor remains non-authoritative. Axiom now
uses the compositor-native wake path, which is the explicitly approved behavior.
