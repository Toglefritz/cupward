# Localization

Never hard-code user-facing strings in widgets.

## Setup in this repo

- Strings live in `cupward_app/lib/l10n/app_en.arb` (config in `cupward_app/l10n.yaml`).
- Generate classes with `flutter gen-l10n` from `cupward_app/`.
- Access with `AppLocalizations.of(context)!.keyName`, importing from `l10n/app_localizations.dart`.

```dart
Text(AppLocalizations.of(context)!.welcomeMessage)   // correct
Text('How can I help you today?')                    // never
```

## ARB requirements

- Every string has an `@key` entry with a `description` that explains where and how it is used.
- Use descriptive keys with consistent prefixes (`button*`, `error*`, `title*`).

```json
{
  "buttonSave": "Save",
  "@buttonSave": {
    "description": "Label for the save button in forms"
  }
}
```

## Placeholders

```json
{
  "welcomeUser": "Welcome back, {userName}!",
  "@welcomeUser": {
    "description": "Personalized welcome message for returning users",
    "placeholders": {
      "userName": { "type": "String", "description": "The user's display name" }
    }
  }
}
```

Usage: `AppLocalizations.of(context)!.welcomeUser(user.name)`

## Plurals

```json
{
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Shows the number of items in a list",
    "placeholders": {
      "count": { "type": "int", "description": "The number of items" }
    }
  }
}
```

## Workflow

1. Add the string and its description to `app_en.arb`.
2. Run `flutter gen-l10n`.
3. Use `AppLocalizations.of(context)!.key` in the widget.
4. Account for text expansion in layouts for other languages.
