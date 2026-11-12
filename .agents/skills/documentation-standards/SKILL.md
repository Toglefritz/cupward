---
name: documentation-standards
description: Requirements for documenting Dart and Flutter code with Dartdoc, including classes, members, errors, algorithms, tests, and MARK comments. Use whenever adding or changing Dart code, writing tests, or reviewing code for documentation completeness.
---

# Documentation Standards

Undocumented code is incomplete code. Assume another developer will need to maintain and extend what you write. Voice and tone follow the `writing-style` skill.

## What must be documented

Use `///` Dartdoc on every class, enum, extension, constructor, method, function, field, getter, and constant, public or private. Each comment should explain purpose, expected values or constraints, and relationships, not restate the name.

- Classes: responsibility, usage, relationships to other types.
- Methods: parameters (use `[param]` references), return value, side effects, thrown errors, async behavior.
- Fields and getters: purpose, units or format, what null means, lifecycle.
- Enums and constants: meaning and usage context.
- Configuration objects: every property and its effect.
- Environment variables and platform settings: purpose and expected values.

## Source files

Add a file-level or library-level doc comment only where it adds context (for example a `library;` file that groups `part` files). Do not add boilerplate headers to every file.

## Complex logic

Non-trivial algorithms get a Dartdoc block that lists the competing factors and the steps taken. Inline comments explain why a step exists, the formula used, and any magic number (name it as a constant where possible).

## Errors

Document every custom exception type: when it is thrown, common scenarios, what the caller should do to recover, and what each field means. Note fields that must not be shown to users.

## Tests

- Document each test file with what is covered and which dependencies are mocked.
- Document `setUp` and `tearDown` when they do more than trivial work.
- Give each `group` and non-trivial `test` a Dartdoc comment stating what behavior is verified and why it matters.
- Structure test bodies as arrange, act, assert with short comments.

## Section markers

Do not use decorative banners:

```dart
// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
```

Use a concise `MARK:` comment for meaningful top-level sections only:

```dart
// MARK: Constants
```

## Review checklist

Before code is considered complete:

- Every class has a doc comment covering purpose and usage.
- Every method documents parameters, return value, and exceptions.
- Every field and property has a purpose description.
- Complex algorithms are explained step by step.
- Error conditions are documented.
- Non-trivial usage has an example.
- Concurrency or thread-safety concerns and performance characteristics are noted where relevant.
- Deprecations include migration guidance.

Documentation must be accurate, complete, clear, consistent, maintainable (updated with the code), and actionable.

## Scope note

The source standard also covers TypeScript (JSDoc) and SQL. This project is Flutter and Dart only, so those sections are omitted. Add them if a backend is introduced.
