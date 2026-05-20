## GraphQL Endpoint

The Flutter app selects its GraphQL endpoint in this order:

1. `--dart-define=GRAPHQL_URL=...`
2. `.env` `GRAPHQL_URL=...`
3. Android emulator fallback: `http://10.0.2.2:3000/graphql`
4. iOS simulator, desktop, and web fallback: `http://localhost:3000/graphql`

`ip=` is deprecated. If `GRAPHQL_URL` is missing and old `ip` exists, the app
will still use `http://<ip>:3000/graphql` in debug builds and print a warning.

Examples:

```env
# Android emulator: leave empty
GRAPHQL_URL=

# iOS simulator: leave empty
GRAPHQL_URL=

# Desktop/web on the same machine as the backend: leave empty
GRAPHQL_URL=

# Mac real iPhone
GRAPHQL_URL=http://<mac-hostname>.local:3000/graphql

# Windows real Android phone
GRAPHQL_URL=http://<windows-lan-ip>:3000/graphql
```

You can also override without editing `.env`:

```sh
flutter run --dart-define=GRAPHQL_URL=http://<host>:3000/graphql
```
