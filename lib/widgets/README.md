# `lib/widgets/` — Reusable Bento Glass UI Components

Entrypoint barrel: **`glass_widgets.dart`** re-exports core glass containers, indicators, marquee, effects, and actions.

- **`glass_surfaces.dart` / `glass_dialog.dart` / `glass_dropdown.dart` / `glass_scaffold.dart`**: `BentoCard`, `GlassDialog`, `DetailDialog`, frosted dropdowns, and glass scaffold helpers.
- **`glass_background.dart` / `glass_effects.dart`**: `MeshBackground` / `MeshOrb`, `BorderBeam`, and `SpotlightGlow` (gated by `AppPowerManager`).
- **`glass_indicators.dart` / `glass_marquee.dart` / `glass_actions.dart`**: `PillBadge`, `WaveIndicator`, `DynamicIslandCapsule`, `BounceMarqueeText` (Session Epoch Guard), and glowing buttons.
- **`command_palette.dart` / `app_toast.dart` / `glass_terminal.dart`**: `Ctrl+K`/`Cmd+K` spotlight palette, auto-dismiss toast overlay, and interactive diagnostic terminal panel.
