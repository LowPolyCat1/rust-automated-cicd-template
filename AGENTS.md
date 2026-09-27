# AGENTS.md

## Chat style

Write your replies to the operator in a terse style. Keep all technical substance.
Remove only the filler.

Obey these rules in a chat reply:

- Do not write articles, filler words, pleasantries, or hedges.
- Fragments are permitted. Use short words. Keep technical terms exact.
- Keep code and error text unchanged.
- Give the thing, the action, and the reason. Then give the next step.

Do not write: "Sure! I'd be happy to help you with that."
Write: "Bug in auth middleware. Fix:"

To change the level, use `/caveman lite|full|ultra|wenyan-lite|wenyan-full|wenyan-ultra`.
To stop this style, the operator says "stop caveman" or "normal mode".

Use full grammar for a security warning, for an irreversible action, and when the
operator is confused. Then continue with the terse style.

## User-facing text

The terse style is for chat replies and working notes only. It never goes into a file.

Text that goes to a reader has different rules. This text includes:

- The `README.md` file and the documents in `docs/`
- Error messages and UI text
- Commit bodies
- Issue text and pull request text

Write this text in ASD-STE100 Simplified Technical English:

- Use a maximum of 20 words in an instruction. Use a maximum of 25 words in a description.
- Use the active voice. Use the imperative for a step.
- Put the condition before the command.
- Use one word for one concept. Keep the articles and the full grammar.
- Do not use "should", "may", "however", or "therefore".

Before you write or rewrite this text, load the `simple-english` skill. Do not copy
the rules of that skill into this file.

## Pull requests

One pull request contains one cohesive change. The commit count is free. The scope is
not free. If the description of the pull request needs the word "and", divide the work
into two pull requests.

Keep a refactor and a change of behavior in separate pull requests.

If you find an unrelated bug, or unrelated code that is difficult to read, do not
correct it here. Complete the current change first. Then open a GitHub issue for the
finding. Name that issue in your summary.

## Commands

The commands of this repository are in `docs/readiness.md`.

## Completion

Before you report a task as completed, the lint command and the test command of
`docs/readiness.md` must pass. Run the command exactly as that document writes it.

A command without the flag for the full workspace reads the default member only. CI
reads every crate, and a task that passes a smaller command still fails CI.

If a check fails, tell the operator and quote the line that failed. Do not report the
task as completed.

## Task wrap-up

After you complete a task, open a pull request to `master` for the task.

## Errors

Return a `Result`. Do not use `unwrap` or `expect` outside a test.

An error message names the input that failed.

## Comments

A comment gives the reason. A comment does not repeat the code.

If a comment is not correct, remove it.

## Task scope

Build what the task asks for. Do not add a module, a trait, or a configuration layer
for a future need.

If a design decision is necessary, ask the operator before you write the code.

## Subagents

Give a complex task to a subagent. `docs/subagents.md` gives the triggers and the
workflow.

## Git

Work on a branch. Do not commit to `master`.

Use stacked pull requests for a feature. `docs/stacked-pull-requests.md` gives the
workflow.

A change that is not part of a feature targets `master` directly. A CI change, a
document, and a dependency update are such changes.

Name the branch per `docs/branch-naming.md`.

Write the commit subject in the Conventional Commits form. Use 50 characters or less.
Write a body only when the diff does not make the reason clear.

## Tests

Put a unit test in the same file, in a `#[cfg(test)] mod tests` block. Put an
integration test in the `tests/` folder of its crate.

A test must not use the network. Use a recorded response. `docs/testing.md` gives the
fixture and the coverage rule of this repository.

## Content of this file

This file stays generic. Project detail belongs in `README.md` and in `docs/`. Project
detail includes the stack, the data model, and the rules of an external API.
