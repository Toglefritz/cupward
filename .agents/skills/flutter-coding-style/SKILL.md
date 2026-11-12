---
name: flutter-coding-style
description: Flutter and Dart coding standards for this repo, including the Route/Controller/View MVC pattern, setState-only state management, widget composition, Padding-based spacing, direct Navigator use, explicit typing, linting, and error handling. Use whenever writing, editing, or reviewing Dart or Flutter code, creating a screen, or adding a widget.
---

# Flutter and Dart Coding Standards

The app lives in `cupward_app/`. Lints come from `very_good_analysis`. Related skills: `documentation-standards`, `writing-style`, `development-behavior`.

Detailed guidance:

- Localization and ARB files: `references/localization.md`
- JSON models: `references/json-handling.md`
- File naming and layout: `references/file-organization.md`

## MVC for every screen

Each screen has three files:

- Route (`*_route.dart`): a `StatefulWidget` whose `createState()` returns the controller. It only defines the entry point.
- Controller (`*_controller.dart`): extends `State<XRoute>`, owns state, event handlers, and business logic, calls `setState()`, and builds the view by passing itself: `build(context) => XView(this)`.
- View (`*_view.dart`): a `StatelessWidget` taking the controller (`const XView(this.state, {super.key})`). Purely declarative UI, no business logic.

```dart
class WelcomeRoute extends StatefulWidget {
  const WelcomeRoute({super.key});

  @override
  State<WelcomeRoute> createState() => WelcomeController();
}

class WelcomeController extends State<WelcomeRoute> {
  late Device selectedDevice;

  void onDeviceSelected(Device device) {
    setState(() => selectedDevice = device);
  }

  @override
  Widget build(BuildContext context) => WelcomeView(this);
}

class WelcomeView extends StatelessWidget {
  const WelcomeView(this.state, {super.key});

  final WelcomeController state;

  @override
  Widget build(BuildContext context) => const Scaffold();
}
```

## State management

- Use `setState()`. Do not introduce Provider, Bloc, Riverpod, or similar.
- State variables are instance fields on the controller. Initialize in `initState()` when needed. Use `late` with an explicit type for values set before first use.

## Widget composition

- Never write helper methods that return widgets (`Widget _buildHeader()`). Extract a `StatelessWidget` class instead.
- Screen-specific widgets go in a `components/` subdirectory next to the screen. Shared widgets go in `lib/components/`.
- Prefer composition over inheritance.

### Spacing

Use `Padding` with a child to create space, not `SizedBox` and not an empty `Padding`. Use values from the `Insets` class when it exists.

```dart
Column(
  children: [
    Text('First item'),
    Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text('Second item'),
    ),
  ],
)
```

## Navigation

- Use the `MaterialApp` Navigator with `MaterialPageRoute`. No named routes.
- Pass data through constructor parameters, not route arguments.
- Navigate from controllers, never from views.
- Use `pushReplacement` when the current screen must not be reachable via back.

```dart
await Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (BuildContext context) => const TargetRoute()),
);
```

## Typing and style

- Every variable has an explicit type, including locals. Do not use `var`, and avoid `dynamic` unless unavoidable.
- Declare full collection types (`List<String>`, `Map<String, int>`, `<String, int>{}`).
- Declare return types and parameter types on all functions.
- Prefer nullable types (`String?`) over `dynamic`. Prefer strong typing over `as` casts.
- Single quotes, relative imports for local files, lines of 80 characters or fewer where practical.

```dart
final List<Application> applications = getApplications();
final Map<String, int> statusCounts = <String, int>{};
for (final Application app in applications) {
  final String status = app.status ?? 'pending';
  statusCounts[status] = (statusCounts[status] ?? 0) + 1;
}
```

## Error handling

- Throw specific exception types.
- Log with `debugPrint()` in debug mode.
- Wrap async operations in try/catch.
- Provide error boundaries in the UI.

## Documentation

Follow the `documentation-standards` skill. Use `///` Dartdoc.

## Testing

- Mirror `lib/` in `test/`.
- Unit test controllers and services, widget test complex UI, and mock external dependencies.
- Cover error scenarios and edge cases.
- Run `flutter analyze` and `flutter test` from `cupward_app/` after changes.
