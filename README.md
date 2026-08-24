# KaratFlow mobile

Flutter application for the role-aware jewellery operations experience.

## Current vertical slice

- Adaptive mobile/tablet shell for Admin, Front Office and Process Manager roles.
- Admin status pivots by order, employee and stage.
- Status detail with inherited context.
- Trackable Admin instruction composer.
- Process Manager acknowledgement, start and resolution lifecycle.
- Admin task view reflects the same instruction state.

The current repository uses an in-memory demo store so the complete interaction can be reviewed before the API and authentication contracts are connected.

## Local commands

Use the repository-local Flutter SDK:

```sh
CI=true FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true \
PUB_CACHE=../work/pub-cache ../work/flutter-sdk/bin/flutter run -d chrome
```

Run validation:

```sh
CI=true FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true \
PUB_CACHE=../work/pub-cache ../work/flutter-sdk/bin/flutter analyze

CI=true FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true \
PUB_CACHE=../work/pub-cache ../work/flutter-sdk/bin/flutter test
```
