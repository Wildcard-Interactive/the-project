# Facility pack — how this is set up

Source pack: *Abandoned Horror Sci-Fi Facility, Pack 1 — Facility Basics* (see `README.txt`).

## `facility_tileset.tres`

Contains **only the 10 floor tiles**, because those are the only images in the pack
that are actually grid-uniform:

| Tile | Source size |
|---|---|
| `floor_grated`, `floor_grated_heavy_rust` | 256×256 |
| `floor_metal_plate_v1..v4` | 256×256 (see anomaly below) |
| `floor_metal_plate_more_rust_v1..v4` | 256×256 |

- **Grid size: 256×256**, chosen to match the source art 1:1 so nothing is resampled
  or bleeds between tiles.
- **`surface` custom data layer** (String) is set to `"metal"` on every tile. This is
  the hook for surface-aware footsteps — see "Footsteps" below.
- **`physics_layer_0`** is declared but no tile has a collision polygon yet: floors are
  walkable. The layer exists so wall/obstacle tiles can be added without restructuring.

### Scale caveat — check this in the editor

256px tiles are large relative to the current game scale: the player's collision box is
26×64 units and `level_0`'s walls are 32 units thick, so one tile is ~4 player-heights
across. Expect to **scale the `TileMapLayer` node down in the level** rather than change
the tile size — e.g. `scale = 0.125` gives 32-unit tiles, matching `level_0`'s wall
thickness. Worth eyeballing once there's a real level to judge it against.

### Source art anomaly

`floor_metal_plate_v1` and `v3` are 265×256, and `v2` and `v4` are 256×265 — a stray 9px
on one edge, inconsistent with the other six plates. At a 256×256 region size Godot uses
the top-left 256×256 and ignores the extra strip, so they tile correctly, but the raw
files are not clean squares if you ever re-export them.

## What is deliberately *not* in the TileSet

**Walls** (`wall_*`) are not grid-uniform — `wall_damaged` is 256×192, `wall_front_left/right`
are 256×85, `wall_left/right` are 138×528, `wall_top_edge` is 32×290, `wall_end_cap` is
27×30. None divide into a 256 grid, and the pack README describes them as modular pieces
placed against room boundaries, not tiles. Place them as `Sprite2D`/`StaticBody2D` pieces.

**Doors** (`Doors/`) are *states* of the same door (`close` / `open` / `open_up` / `broken`
/ `background`), not tiles. Wiring them up means deciding how doors behave — that's a
gameplay-design call, not an import step, so nothing was built for them.

**Props** (`Props/`) — the five solid ones have placeable scenes in
`scenes/props/facility/`. The four warning signs and two emergency lights are flat wall
decor with no collision; drop them in as a plain `Sprite2D` with the texture assigned.

**Decals** (`Decals/`) are pure overlay art with no collision or logic. A scene per decal
would add nothing over dragging the PNG in as a `Sprite2D`, so none were created.

## Footsteps

`AudioManager` currently resolves the player's surface from `Area2D` zones tagged
`surface_<name>` (see `autoload/audio_manager.gd`). The `surface` custom data on these
tiles is **populated but not yet read** — wiring `TileMapLayer` → footstep surface is a
follow-up once a TileMap-based level exists.
