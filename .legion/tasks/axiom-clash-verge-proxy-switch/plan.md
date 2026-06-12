# Axiom Clash Verge Proxy Switch

## Goal
Provide a small Node 24 TypeScript CLI script for axiom that controls the local Clash Verge/Mihomo API and switches the default proxy selection without opening the GUI.

## Problem
Axiom already runs Clash Verge with a local external controller at `127.0.0.1:9090`, and the current selectable outbound group in `config/clash/config.yaml` is `Nexitally`. Switching nodes through the GUI is slower than using a shell command or terminal selector, especially when repeating common node changes.

## Acceptance
- A script can list all entries in the target proxy group, defaulting to `Nexitally`.
- A script can switch the target proxy group to a node specified by command-line argument.
- Running the script without a node argument opens an interactive terminal selector similar in spirit to `opencode auth login` vendor selection.
- The script uses Node 24-compatible TypeScript and avoids third-party runtime dependencies.
- Controller URL, group name, and optional API secret are configurable through flags and environment variables.
- Local syntax/type verification succeeds, or any environmental blocker is documented with evidence.

## Scope
- Add a standalone TypeScript script under the dotfiles `bin/` area.
- Add minimal usage documentation adjacent to the script if needed by the script itself.
- Use Clash/Mihomo controller endpoints only; do not parse or rewrite subscription YAML for switching.
- Record Legion verification, review, walkthrough, and wiki evidence for the change.

## Non-goals
- Do not change the Clash subscription contents or proxy group definitions.
- Do not add Node package managers, `package.json`, or vendored dependencies to the dotfiles root.
- Do not modify system service configuration for Clash Verge in this task.
- Do not implement latency testing, subscription refresh, or multi-group batch switching.
- Do not expose or persist API secrets in repository files.

## Assumptions
- Axiom's Clash Verge/Mihomo external controller listens on `http://127.0.0.1:9090` as declared in `config/clash/config.yaml`.
- The default group to switch is `Nexitally`, confirmed by the user.
- Node 24 is available when the script is run; built-in `fetch`, `readline/promises`, and TypeScript stripping support are sufficient for this script.
- If an external controller secret is configured later, passing it through an environment variable or flag is acceptable.

## Constraints
- Follow Legion workflow for contract, implementation, verification, review, walkthrough, and wiki writeback.
- Keep implementation minimal and dependency-free so the script remains useful in a dotfiles repository without a Node project scaffold.
- Preserve unrelated worktree changes.
- Avoid printing or committing subscription credentials or secrets.

## Risks
- Clash/Mihomo API shapes can vary slightly; the script should validate responses and produce actionable errors.
- Interactive selector behavior depends on a TTY; non-interactive shells need explicit command arguments.
- TypeScript execution on Node 24 depends on the user's runtime flags/version behavior, so the script should remain plain enough to be checked and run predictably.

## Design Summary
Add a single executable TypeScript CLI in `bin/` that talks to the local Clash/Mihomo REST API. The CLI supports `list`, explicit `switch <node>`, and default interactive selection modes. Defaults are tuned for axiom (`http://127.0.0.1:9090`, group `Nexitally`) while flags and environment variables allow reuse for other controller URLs, group names, and secrets.

## Phases
1. Materialize Legion task contract.
2. Enter the git worktree PR envelope and implement the standalone TypeScript CLI.
3. Verify syntax/type behavior and CLI help/list logic as far as local runtime permits.
4. Review the change for scope, safety, and secrets exposure.
5. Produce walkthrough/wiki evidence and complete delivery closeout.
