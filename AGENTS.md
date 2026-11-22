# AGENTS.md

Instructions for coding agents working in this repo. `CLAUDE.md` points here; this file is the source of truth.

## Messages to the user

Every message you send back for the user to read falls into exactly one of these three groups:

1. **`[DECISION]`**: the user must answer your question. Start the message with `[DECISION]`.
2. **`[INFORM]`**: something the user must read and know, but does not need to reply to. Start the message with `[INFORM]`.
3. **No label**: a log of what you did. The user may read it or skip it.

Never use any other label.

## Agent skills

### Issue tracker

Issues and specs live in this repo's GitHub Issues (`noppamas/Nop`), via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

### Implementing issues

To implement an issue, follow the project skill `.claude/skills/implement/SKILL.md`: one branch and PR per issue, tests first, `tool/check.sh` passes locally, then an `[INFORM]` with evidence for every acceptance criterion and a review before merging.
