# Frontend Architecture — Feature-First, Thin-Client

This repository uses a feature-first (vertical-slice) frontend architecture with Riverpod state management and a thin service layer for network calls.

## High-level summary

- Feature-first: organize code by feature (e.g. `auth`, `playlist`, `song`, `home`, `onboarding`).
- Thin-client: frontend handles presentation and UI state only; business logic lives on the backend.
- State: Riverpod (`Provider`, `FutureProvider`, `NotifierProvider`, etc.) wires services to UI.
- Network: GraphQL client lives in `core/network/graphql_config.dart` and GraphQL queries in `core/network/queries.dart`.

## Feature folder layout (recommended)

Each feature follows this vertical structure:

- `features/<feature>/models/` — DTOs for API payloads (`fromJson()`/`toJson()` only).
- `features/<feature>/services/` — thin API clients (GraphQL/HTTP calls). Prefer `*_service.dart` file names.
- `features/<feature>/providers/` — Riverpod providers that expose data and local UI state.
- `features/<feature>/screens/` — UI widgets and pages.

Example:
```
features/playlist/
  models/playlist.dart
  services/playlist_service.dart
  providers/playlist_provider.dart
  screens/no_playlists_screen.dart
```

## Naming guidance

- Use `*_service.dart` for thin API clients. Use `*_repository.dart` only when implementing caching, aggregation, or offline fallback.
- Keep `models` as plain DTOs — no domain rules, no business logic.
- Providers are the single place to compose `services` into UI state.

## Core responsibilities

- `core/theme/` — app ThemeData and typography.
- `core/constants/` — colors, text styles, mock data for UI development.
- `core/network/` — GraphQL client and queries.
- `core/routing/` — app routing and top-level `AuthWrapper`.

## When to evolve the structure

- Add `repositories/` or `domain/usecases/` when the frontend needs rich local logic, caching, or multiple data sources.
- Keep changes minimal until real frontend-side business logic is required.

---

If you'd like, I can add a short CONTRIBUTING section that enforces these conventions for future contributors.