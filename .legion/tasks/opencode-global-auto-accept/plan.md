# OpenCode global auto-accept permissions

## 目标

Enable OpenCode global permission auto-accept behavior for this user by updating the global OpenCode config.

## 问题陈述

OpenCode permission prompts interrupt the requested workflow; the user wants the default behavior changed globally rather than per project.

## 验收标准

- [ ] Global OpenCode config exists at ~/.config/opencode/opencode.json.
- [ ] The config sets OpenCode permissions to allow by default so approval prompts are not shown for allowed operations.
- [ ] Existing unrelated OpenCode config values are preserved if present.
- [ ] The change is verified by inspecting the resolved config file contents.

## 假设 / 约束 / 风险

- **假设**: The user intentionally accepts the local security trade-off of globally auto-approving OpenCode permissions.
- **假设**: Project-level opencode.json files may still override the global config.
- **假设**: No repository application code needs to change.
- **约束**: Modify only the user-level OpenCode config and Legion task documentation.
- **约束**: Do not change project-level OpenCode config files.
- **约束**: Do not alter unrelated config keys.
- **风险**: Global permission allow mode can let future OpenCode sessions run tools without prompts, including edits and shell commands unless overridden by project or agent rules.
- **风险**: Malformed JSON would break OpenCode config loading.

## 要点

- 待补充

## 范围

- ~/.config/opencode/opencode.json
- .legion/tasks/opencode-global-auto-accept/

## 设计索引 (Design Index)

> **Design Source of Truth**: Design-lite in plan.md; no formal RFC because the implementation is a single reversible user config edit.

**摘要**:
- Use the documented OpenCode permission config rather than UI-only session toggles.
- Set the global permission value to allow while preserving other top-level config keys.

## 阶段概览

1. **brainstorm** - Create a stable task contract for the global OpenCode permission change.
2. **design-lite** - Record the minimal design decision and safety trade-off.
3. **engineer** - Update the user-level OpenCode config without touching project config.
4. **verify-change** - Validate the config file is valid JSON and contains the intended permission value.
5. **review-change** - Check the final change for scope and safety notes.
6. **report-walkthrough** - Summarize the completed change and residual caveats.
7. **legion-wiki** - Write back durable task knowledge if applicable.

---

*创建于: 2026-05-15 | 最后更新: 2026-05-15*
