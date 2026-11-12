# File Organization

## Naming

- Files: `snake_case`. Classes: `PascalCase`. Variables and methods: `camelCase`.
- Suffix files with `_route.dart`, `_controller.dart`, or `_view.dart`.
- Avoid generic file names such as `models.dart` or `utils.dart`.

## Directories

- Organize by feature, not by file type.
- Shared widgets: `lib/components/`. Business logic: `lib/services/`. Models: `lib/models/`.

## One class per file

Each file contains exactly one class or enum, regardless of relationship. The file name is the snake_case form of that type name.

```
lib/services/authentication/models/
  auth_method.dart        # AuthMethod enum
  auth_credentials.dart   # AuthCredentials class
  auth_result.dart        # AuthResult class
```

Import each file individually:

```dart
import '../models/auth_method.dart';
import '../models/auth_credentials.dart';
import '../models/auth_result.dart';
```

Do not put several types in one file, even closely related ones.

## The library directive

Use `library;` only when the file also declares `part` directives that group files into one logical unit. Files without `part` directives must not include `library;`.

```dart
// auth_result.dart
library;

part 'auth_method.dart';
part 'auth_credentials.dart';

class AuthResult {}
```

```dart
// auth_method.dart
part of 'auth_result.dart';

enum AuthMethod { basicAuth, google, apple }
```
