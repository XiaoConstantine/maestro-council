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

- Control plane: one-way `tmux-bridge send` messages sent into agent panes.
- Data plane: files written into the active workspace's
  `council-out/runs/<run-id>/` by default.
- Default roles:
  - `codex`: primary implementer and final plan synthesizer
  - `cc`: design critic and implementation reviewer
  - `amp`: design critic and implementation reviewer

This avoids trying to move long, structured outputs through a terminal
pane. Agents receive short one-way tmux messages that point them at
instruction files, and they write their actual artifacts to disk.

Runtime defaults live in [council.conf](council.conf).

By default, `council` targets the `default` instance. Named instances
append `-<instance>` to the base window and pane labels, which lets you
run multiple councils side by side in the same tmux session.

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

To run multiple councils at once, give each one an instance name:

```bash
council start --instance feature-a
council run --instance feature-a "Design option A"

council start --instance feature-b
council run --instance feature-b "Design option B"
```

You can also set `MAESTRO_COUNCIL_INSTANCE=<name>` instead of passing
`--instance` on every command.

## Workflow

Run the default flow from any pane in the target workspace:

```bash
council start
council run "Design a new tmux-native council tool"
```

Or target a specific named instance:

```bash
council start --instance infra
council run --instance infra "Harden the tmux transport layer"
```

The default `run` workflow is:

1. All three agents write independent design plans.
2. All three agents critique the anonymized plan bundle.
3. `codex` writes the final implementation plan.
4. `codex` implements in the council workspace.
5. `cc` and `amp` review the resulting implementation.
6. `cc` and `amp` start their review files with `VERDICT: LGTM` or `VERDICT: REVISE`.

`council run` now prints the run directory immediately and records the
active stage in `stage.txt`. If the run is interrupted or an agent
stalls, continue from the next incomplete stage with:

```bash
council resume <run-id>
```

`council continue <run-id>` is an alias for the same command. Run it
from the same workspace the council run targets.

`council run` without `--instance` allocates a fresh instance if the
default council window already exists. Pass `--instance <name>` or set
`MAESTRO_COUNCIL_INSTANCE` to pin and reuse a specific instance.
To intentionally recreate an existing instance's panes, use
`council reset` or `council start --force`.

Artifacts are written under the active workspace by default:

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
- `stage.txt`
- `progress.log`

## Install

Install `smux` first. `maestro-council` depends on the tmux layout and
`tmux-bridge` CLI that `smux` provides:

```bash
curl -fsSL https://raw.githubusercontent.com/XiaoConstantine/smux/main/install.sh | bash
```

Then install the council commands and tmux binding snippet into that
smux setup:

```bash
./install.sh
```

This will:

- symlink `bin/council` into `~/.smux/bin/council`
- symlink `bin/council` into `~/.smux/bin/maestro-council`
- symlink `bin/council-round` into `~/.smux/bin/council-round`
- write `~/.smux/maestro-council.conf`
- print the `source-file` line to add to your tmux config
- remind you to put `~/.smux/bin` on your shell `PATH` if needed

## tmux Binding

The included tmux snippet adds:

- `prefix + C`: start the default council layout

It intentionally does not bind a full free-form `run` prompt by default,
because quoting multi-line tasks through `command-prompt` gets brittle.
Once the council window is up, run `council run "..."` or
`maestro-council run "..."` from a pane in the target workspace.
