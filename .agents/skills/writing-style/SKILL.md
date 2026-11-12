---
name: writing-style
description: Defines the engineering voice for code comments, Dartdoc, READMEs, and any prose written in this repo. Use whenever writing or editing comments, documentation, commit-adjacent text, or Markdown content. Covers tone, structure, and punctuation rules such as no em-dashes.
---

# Writing Style

Write like an experienced engineer explaining a system to another engineer: clear, direct, and respectful of the reader's time. Avoid generic, promotional, or AI-sounding prose.

## Principles

- Be clear before being clever. No marketing tone, hype, or filler.
- Explain intent: what it does, why it exists, when to use it, and which constraints shaped it. Do not restate code in prose.
- Prefer precision over brevity when precision prevents misuse.
- Lead with the most important idea. Put caveats and edge cases after.
- Use short paragraphs. Use lists only for assumptions, requirements, constraints, side effects, steps, or criteria, and not when a paragraph reads better.
- Write durable comments that stay true when small implementation details change.
- Do not comment obvious code.

## Tone

Calm, matter-of-fact, and confident without being absolute. Useful phrasing: "This allows...", "This avoids...", "This is intentionally...", "The main reason for this approach is...". Do not condescend or explain obvious syntax.

State platform or timing dependence directly, for example "On Android, this callback may arrive more than once for the same device."

## Word choice

- Prefer concrete verbs: stores, tracks, normalizes, converts, coordinates, prevents, represents. Avoid "handles", "deals with", "works with", and "manages" when something more specific fits.
- Avoid empty emphasis: simple, easy, powerful, robust, clean, efficient, seamlessly, "just", "simply", unless the text explains exactly why.
- Do not end with generic wrap-ups such as "This ensures smooth operation" or "This improves the user experience." Name the specific mechanism instead.

## Punctuation and formatting (hard rules)

- Never use em-dashes (`—`). Use commas, parentheses, or separate sentences.
- No decorative separators (`---`, `===`, `***`, long dash or equals runs) in comments or prose. Use headings and spacing. (YAML frontmatter delimiters are fine.)
- No emojis unless the user asks.
- Use conventional punctuation. Avoid ellipses, exclamation points, and stacked punctuation.
- Avoid "AI list cadence": long runs of short, same-rhythm bullets.
- Keep bold and italics minimal.

## What to document, by element

- Classes: responsibility, place in the architecture, what callers must know, lifecycle and state assumptions.
- Methods: purpose, side effects, state expectations, failure behavior, async or timing behavior.
- Fields: source of truth, ownership, units or format, meaning of null, lifecycle.
- Inline comments: why a step is needed, non-obvious approach, platform behavior, invariants, temporary workarounds and their boundary.

## Dartdoc

- Summary-first style. Add paragraphs only when they carry architectural or behavioral context.
- Link related types with brackets, such as `[BleDevice]`.

Example:

```dart
/// Represents a device discovered during an active BLE scan.
///
/// This model contains the information that is stable and broadly useful across
/// platforms. Platform-specific scan details should be normalized before they
/// are stored here.
class BleDevice {
  /// The identifier used by the current platform to refer to this device.
  final String address;
}
```

## README and Markdown

Write for real work: understanding the system, setup, navigation, safe changes, troubleshooting. Use informative headings (`Architecture`, `Local Development`, `Platform Constraints`) rather than vague ones (`Important Notes`). Document tradeoffs explicitly. Check the `markdown-discipline` skill before creating any file.

When unsure, write the comment that would help a skilled engineer understand the code six months from now.
