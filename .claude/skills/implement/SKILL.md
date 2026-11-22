---
name: implement
description: Implement one GitHub issue of JSON Better Editor (noppamas/Nop) end to end - read the spec, branch, test first, build and check locally on the Mac, open a PR, and post acceptance-criteria evidence for review before merging. Use when asked to implement, build or work on an issue or ticket number in this repo, or to work through a phase's issues in order.
---

# Implement an issue

One issue at a time, one branch and one PR per issue. Work locally on the Mac;
no GitHub Actions.

## Inputs

- An issue number (or a parent tracking issue, then take its sub-issues in
  dependency order: an issue is startable when every "Blocked by" issue is
  closed or approved).

## 1. Understand before coding

1. Read the issue: `gh issue view <n> --json number,title,body,labels,comments`.
2. Read what it points to in `docs/plans/`:
   - `requirements-checklist.md` for the § sections it cites,
   - `decision-log.md` for the decisions it cites (decisions win over older text),
   - `development-phases.md` for the phase scope.
3. Read `AGENTS.md`, `GLOSSARY.md` and `docs/adr/` if they exist.
4. Stay inside the issue and its phase. Work a later phase owns (for example
   highlighting, pretty-print on save, Thai strings, One Light/Dark) stays out.
5. If anything is unclear, or a choice changes what the user gets, **stop all
   work** and ask the user with a `[DECISION]` message (see Messages). Do not
   guess and continue. Resume only when the answer is clear.

## 2. Branch

```bash
git checkout main && git pull
git checkout -b issue-<n>-<short-slug>
```

If the previous issue's PR is approved but not merged yet, branch from that
branch instead and rebase onto `main` once it is merged:
`git fetch origin main && git rebase origin/main`.

## 3. Build it test first

- For each acceptance criterion, write the test that proves it first, then the
  code. Unit tests for logic (`test/`), widget tests for UI (`test/`),
  integration tests on the real macOS app for anything that needs the native
  side or the real disk (`integration_test/`).
- Keep the seams that make this testable: file dialogs and disk access go
  through `DocumentFiles` (fake in `test/support/fake_document_files.dart`);
  native window calls go through `NativeWindow`.
- Every user-visible string goes in `lib/l10n/app_en.arb` (English only until
  Phase 4). `use-escaping` is on: write `'}'` for a literal brace and use `’`
  instead of `'` in text.
- Flutter here uses `package:material_ui/material_ui.dart`, not
  `package:flutter/material.dart`.
- Give widgets the tests need a `ValueKey` in a `...Keys` class next to them.

## 4. Check locally

```bash
tool/check.sh
```

It runs analyze, unit and widget tests, the macOS debug build and the
integration tests on macOS, and stops at the first failure. Flutter is found on
`PATH`, in `$FLUTTER`, or at `~/Documents/flutter/bin/flutter`. Everything must
pass before the PR. Run `dart format lib test integration_test` first.

If a check needs something the machine lacks (for example Xcode, or Screen
Recording / Accessibility permission for a UI check), say so in the evidence
and ask the user to check it by hand.

## 5. Commit and PR

- Commit message: title `<Issue title> (#<n>)`, a short body on what changed.
- `git push -u origin <branch>` then
  `gh pr create --base main --title "<Issue title>" --body-file <file>`, body
  starting with `Closes #<n> (part of #<parent>).`, then What and Checked
  locally sections.
- If `git push` or `gh` write commands are blocked, give the user the exact
  command to run.

## 6. Acceptance review, then merge

Post an `[INFORM]` message listing **every** acceptance criterion of the issue,
each with:

- ✅ / ❌,
- the evidence: which test proves it (file and what it asserts), or what you
  ran and its output (numbers, not adjectives).

Also list limits (what could not be checked automatically) and anything done
beyond the criteria.

Wait for the reviewer (the main chat) to approve. Then merge
(`gh pr merge <n> --merge --delete-branch`, or ask the user to run it if
blocked) and start the next issue from the updated `main`.

## Messages

Every message to the user is exactly one of (see `AGENTS.md`):

- `[DECISION]`: the user must answer. Stop all work until they do.
- `[INFORM]`: must read, no reply needed (acceptance evidence goes here).
- No label: a log of what you did.

## Subagents

Issues in a phase usually build on each other, so run them in order in one
session. Use a subagent only for independent work (for example two issues that
touch different files, or a wide read of the code). The main session always
reviews each issue's acceptance evidence itself.
