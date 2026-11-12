---
name: markdown-discipline
description: Rules for when Markdown files may be created or edited in the repository. Use before creating any .md file, summary, report, notes, or documentation, and when deciding whether information belongs in chat or in the repo.
---

# Markdown Discipline

Markdown files document the project. Chat communicates with the human. Never reverse these roles.

## Core rule

Do not create new Markdown files unless the developer explicitly asks for one. This includes summaries, progress reports, "what was done" write-ups, architecture explanations addressed to the user, and standalone design rationales.

Forbidden unless requested: `Summary.md`, `Implementation Notes.md`, `AI Decisions.md`, `Changes Overview.md`, `Next Steps.md`, or any document written to the developer.

## Allowed

Modify existing Markdown files when it directly improves the project:

- Update an existing `README.md`
- Add setup instructions to an existing doc
- Correct inaccurate or outdated information
- Expand documentation only to reflect implemented code

Changes must stay within the file's existing purpose, avoid speculative or future-facing content, and reflect the current codebase.

## Belongs in chat, not the repo

- What was implemented
- Why a decision was made
- What could be done next
- Tradeoffs and alternatives
- Requests for feedback or confirmation

## Why

Every committed file must be maintained indefinitely. If a document would not still be valuable in six months, it does not belong in the repository.

## When in doubt

Do not create the file. Use chat, and ask whether documentation changes are wanted.
