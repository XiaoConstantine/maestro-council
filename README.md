# maestro-council

`maestro-council` is a tmux-first council runner built on top of
`tmux-bridge`. It starts a fixed council of `codex`, `cc` (Claude Code),
and `amp`, then coordinates a design -> critique -> implementation ->
review workflow using tmux for control messages and shared files for
artifacts.

The repo is deliberately shell-first. The public entry point is
`bin/council`, with `bin/council-round` available as a thin orchestration
wrapper and `bin/maestro-council` kept as a compatibility alias.

## Model

- Control plane: `tmux-bridge` messages sent into agent panes.
- Data plane: files written into `council-out/runs/<run-id>/`.
- Default roles:
  - `codex`: primary implementer and final plan synthesizer
  - `cc`: design critic and implementation reviewer
  - `amp`: design critic and implementation reviewer

This avoids trying to move long, structured outputs through a terminal
pane. Agents receive short tmux messages that point them at instruction
files, and they write their actual artifacts to disk.

Runtime defaults live in [council.conf](council.conf).

## Layout

`council start` creates a dedicated tmux window with three visible panes:

- `council-codex`
- `council-cc`
- `council-amp`

By default the agent commands are:

- `codex`
- `claude` for `cc`
- `amp`

Override them with environment variables:

- `MAESTRO_COUNCIL_CODEX_CMD`
- `MAESTRO_COUNCIL_CC_CMD`
- `MAESTRO_COUNCIL_AMP_CMD`

## Workflow

Run the default flow from any pane in the target workspace:

```bash
council start
council run "Design a new tmux-native council tool"
```

The default `run` workflow is:

1. All three agents write independent design plans.
2. All three agents critique the anonymized plan bundle.
3. `codex` writes the final implementation plan.
4. `codex` implements in the council workspace.
5. `cc` and `amp` review the resulting implementation.
6. `cc` and `amp` start their review files with `VERDICT: LGTM` or `VERDICT: REVISE`.

Artifacts are written under:

```text
council-out/runs/<run-id>/
```

The key outputs are:

- `plans/codex.md`
- `plans/cc.md`
- `plans/amp.md`
- `critiques/codex.md`
- `critiques/cc.md`
- `critiques/amp.md`
- `plan.final.md`
- `implementation/codex.md`
- `reviews/cc.md`
- `reviews/amp.md`

## Install

Install the script and tmux binding snippet into your local smux setup:

```bash
./install.sh
```

This will:

- symlink `bin/council` into `~/.smux/bin/council`
- symlink `bin/council` into `~/.smux/bin/maestro-council`
- symlink `bin/council-round` into `~/.smux/bin/council-round`
- write `~/.smux/maestro-council.conf`
- print the `source-file` line to add to your tmux config

## tmux Binding

The included tmux snippet adds:

- `prefix + C`: start the default council layout

It intentionally does not bind a full free-form `run` prompt by default,
because quoting multi-line tasks through `command-prompt` gets brittle.
Once the council window is up, run `council run "..."` or
`maestro-council run "..."` from a pane in the target workspace.
