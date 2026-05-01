# maestro-council

`maestro-council` is a tmux-first council runner built on top of
[`smux`](https://github.com/XiaoConstantine/smux), specifically the
`XiaoConstantine/smux` fork and its `tmux-bridge` CLI. It starts a fixed
council of `codex`, `cc` (Claude Code), and `amp`, then coordinates a
planning phase and execution phase using tmux for control messages and
shared files for artifacts.

The repo is deliberately shell-first. The public entry point is
`bin/council`, with `bin/council-round` available as a thin orchestration
wrapper and `bin/maestro-council` kept as a compatibility alias.

## Dependency

`maestro-council` assumes the `smux` layout conventions and
`tmux-bridge` behavior from
[`XiaoConstantine/smux`](https://github.com/XiaoConstantine/smux). If
you install a different `smux` variant, pane control and one-way message
dispatch may not match what this repo expects.

Shout out to
[`ShawnPana/smux`](https://github.com/ShawnPana/smux), the original
upstream project that my fork builds on.

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

Configuration is layered so local projects can override personal
defaults without editing this repo. Config files are shell files, so use
normal `MAESTRO_COUNCIL_*=...` assignments.

1. `~/.config/maestro-council/council.conf`
2. `~/.maestro-council.conf`
3. `.maestro-council.conf` in the current git root
4. `.maestro-council.conf` in the current directory, when different
5. `MAESTRO_COUNCIL_CONFIG=<path>`
6. environment variables
7. command-line flags such as `--instance`

Generate a starter config with:

```bash
council init-config          # project config
council init-config --global # user config
```

Inspect the exact effective config and preflight the local setup with:

```bash
council config
council doctor
```

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
- `claude --permission-mode bypassPermissions` for `cc`
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

Run the default end-to-end flow from any pane in the target workspace:

```bash
council start
council run "Design a new tmux-native council tool"
```

For longer or multi-line tasks, avoid shell quoting by reading the task
from a file or stdin:

```bash
council run --task-file task.md
pbpaste | council run --task-file -
```

By default, `council run` opens a dedicated orchestration pane beneath
the pane you launched it from, keeps your original pane focused, and
leaves the run pane open after completion so the full status log stays
visible. Set `MAESTRO_COUNCIL_ORCHESTRATE_IN_PANE=0` for the old inline
behavior.

You can choose where that orchestration pane lives with
`MAESTRO_COUNCIL_ORCHESTRATOR_PANE_TARGET`:

- `current`: split the pane you launched `council run` from
- `council`: add or reuse an orchestration pane inside the
  `maestro-council` tmux window as a slim left rail, with `cc` and
  `amp` on the top row and `codex` across the bottom on the right

Adjust the pane height with
`MAESTRO_COUNCIL_ORCHESTRATOR_PANE_LINES=<lines>` for `current`, or the
left column width with
`MAESTRO_COUNCIL_ORCHESTRATOR_PANE_WIDTH=<columns>` for `council`.
Output color follows `MAESTRO_COUNCIL_COLOR=auto|always|never` and
respects `NO_COLOR`.

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

For an explicit handoff between planning and execution, use:

```bash
council start
council plan "Design a new tmux-native council tool"

# review council-out/runs/<run-id>/plan.final.md
council exec <run-id>
```

`council plan` runs only the planning stages:

1. Independent plans
2. Cross-critiques
3. Final merged plan

It then stops and records:

- `target.txt` as `plan`
- `phase.txt` as `plan-complete`
- `workspace.snapshot.txt` with the workspace path, branch, HEAD, and dirty state

`council exec` loads an existing run, verifies `plan.final.md` exists,
checks `workspace.snapshot.txt` for drift, upgrades `target.txt` to
`complete`, and runs only the execution stages.
It reuses the existing council window when possible; if an agent pane has
dropped back to a shell, that pane is restarted in place instead of
recreating the whole council.

Each run records the active stage in `stage.txt`, the coarse phase in
`phase.txt`, and the intended stop boundary in `target.txt`. If a run is
interrupted or an agent stalls, continue from the next incomplete stage
with:

```bash
council resume <run-id>
```

`council continue <run-id>` is an alias for the same command. Run it
from the same workspace the council run targets.

To inspect existing work without searching the artifact directory by
hand:

```bash
council runs
council show <run-id>
council status --all
```

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
- `implementation/codex.revise-round-N.md`
- `reviews/cc.round-N.md`
- `reviews/amp.round-N.md`
- `bundles/reviews.round-N.md`
- `target.txt`
- `phase.txt`
- `workspace.snapshot.txt`
- `stage.txt`
- `progress.log`

## Install

Install `smux` first. This repo currently uses the
[`XiaoConstantine/smux`](https://github.com/XiaoConstantine/smux) fork,
which is based on
[`ShawnPana/smux`](https://github.com/ShawnPana/smux). `maestro-council`
depends on the tmux layout and `tmux-bridge` CLI that fork provides:

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

### mycli Integration

`maestro-council` can also be managed through
[`mycli`](https://github.com/XiaoConstantine/mycli)'s first-class council
command:

```bash
mycli council install
mycli council install-agents --config config.yaml
mycli council doctor
mycli council start
mycli council run --config config.yaml --task-file task.md
```

The `mycli-*` wrappers in this repo are compatibility shims for mycli's
extension-style executable layout, but the intended user flow is
`mycli council ...`.

## tmux Binding

The included tmux snippet adds:

- `prefix + C`: start the default council layout

It intentionally does not bind a full free-form `run` prompt by default,
because quoting multi-line tasks through `command-prompt` gets brittle.
Once the council window is up, run `council run "..."` or
`maestro-council run "..."` from a pane in the target workspace.

## License

MIT. See [LICENSE](LICENSE).
