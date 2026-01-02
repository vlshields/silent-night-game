package main

import rl "vendor:raylib"
import "core:os"
import "core:strings"
import "core:math/rand"

TILE_SIZE :: 16

Level :: struct {
    grounds:            [dynamic]Ground,
    ground_tiles:       [dynamic]GroundTile,
    ladders:            [dynamic]Ladder,
    enemies:            [dynamic]Enemy,
    doors:              [dynamic]Door,
    traps:              [dynamic]Trap,
    items:              [dynamic]Item,
    instruments:        [dynamic]Instrument,
    moon_tiles:         [dynamic]MoonTile,
    angry_planet_tiles: [dynamic]AngryPlanetTile,
    buildings:          [dynamic]BuildingTile,
    win_tiles:          [dynamic]WinTile,
    player_spawn:       rl.Vector2,
    width:              f32,
    height:             f32,
}

Ground :: struct {
    x, y:          f32,
    width, height: f32,
}

GroundTile :: struct {
    x, y:    f32,
    variant: i32,  // 0, 1, or 2 for the three textures
}

Ladder :: struct {
    x, y:          f32,
    width, height: f32,
}

Door :: struct {
    x, y:          f32,
    width, height: f32,
}

Trap :: struct {
    x, y:          f32,
    width, height: f32,
    triggered:     bool,
}

Item :: struct {
    x, y:          f32,
    width, height: f32,
    collected:     bool,
}

Instrument :: struct {
    x, y:          f32,
    width, height: f32,
    collected:     bool,
}

MoonTile :: struct {
    x, y:       f32,
    grid_x:     i32,
    grid_y:     i32,
}

AngryPlanetTile :: struct {
    x, y:       f32,
    grid_x:     i32,
    grid_y:     i32,
}

BuildingType :: enum {
    Static1,    // B - Parallax_bg_buildting_static.png
    Static2,    // F - Paralax_building_static_bg2.png
}

BuildingTile :: struct {
    x, y:       f32,
    grid_x:     i32,
    grid_y:     i32,
    type:       BuildingType,
}

WinTile :: struct {
    x, y:          f32,
    width, height: f32,
}

load_level :: proc(path: string) -> Level {
    level := Level{
        grounds            = make([dynamic]Ground),
        ground_tiles       = make([dynamic]GroundTile),
        ladders            = make([dynamic]Ladder),
        enemies            = make([dynamic]Enemy),
        doors              = make([dynamic]Door),
        traps              = make([dynamic]Trap),
        items              = make([dynamic]Item),
        instruments        = make([dynamic]Instrument),
        moon_tiles         = make([dynamic]MoonTile),
        angry_planet_tiles = make([dynamic]AngryPlanetTile),
        buildings          = make([dynamic]BuildingTile),
        win_tiles          = make([dynamic]WinTile),
        player_spawn       = {100, 317},
    }

    moon_origin_x: i32 = -1
    moon_origin_y: i32 = -1
    planet_origin_x: i32 = -1
    planet_origin_y: i32 = -1

    building_origins: [BuildingType][2]i32 = {
        .Static1 = {-1, -1},
        .Static2 = {-1, -1},
    }

    data, ok := os.read_entire_file(path)
    if !ok {
        return level
    }
    defer delete(data)

    content := string(data)
    lines := strings.split_lines(content)
    defer delete(lines)

    max_cols := 0
    row_count := 0
    for line, row in lines {
        if len(line) == 0 do continue
        row_count = row + 1
        if len(line) > max_cols do max_cols = len(line)

        for char, col in line {
            x := f32(col * TILE_SIZE)
            y := f32(row * TILE_SIZE)

            switch char {
            case '#':
                // Add individual tile for rendering with random variant
                append(&level.ground_tiles, GroundTile{
                    x       = x,
                    y       = y,
                    variant = rand.int31_max(3),  // 0, 1, or 2
                })
                // Merge adjacent grounds for collision detection
                merged := false
                if len(level.grounds) > 0 {
                    last := &level.grounds[len(level.grounds) - 1]
                    if last.y == y && last.x + last.width == x {
                        last.width += TILE_SIZE
                        merged = true
                    }
                }
                if !merged {
                    append(&level.grounds, Ground{x, y, TILE_SIZE, TILE_SIZE})
                }
            case 'L':
                merged := false
                for &ladder in level.ladders {
                    if ladder.x == x && ladder.y + ladder.height == y {
                        ladder.height += TILE_SIZE
                        merged = true
                        break
                    }
                }
                if !merged {
                    append(&level.ladders, Ladder{x, y, TILE_SIZE, TILE_SIZE})
                }
            case 'P':
                level.player_spawn = {x + TILE_SIZE / 2, y + TILE_SIZE / 2}
            case 'E':
                append(&level.enemies, Enemy{
                    x         = x + TILE_SIZE / 2,
                    y         = y + TILE_SIZE / 2,
                    start_x   = x + TILE_SIZE / 2,
                    direction = -1,
                })
            case 'D':
                append(&level.doors, Door{x, y, TILE_SIZE, TILE_SIZE})
            case 'T':
                append(&level.traps, Trap{x, y, TILE_SIZE, TILE_SIZE, false})
            case 'I':
                append(&level.items, Item{x, y, TILE_SIZE, TILE_SIZE, false})
            case 'G':
                append(&level.instruments, Instrument{x, y, TILE_SIZE, TILE_SIZE, false})
            case 'M':
                if moon_origin_x < 0 || col < int(moon_origin_x) {
                    moon_origin_x = i32(col)
                }
                if moon_origin_y < 0 || row < int(moon_origin_y) {
                    moon_origin_y = i32(row)
                }
                append(&level.moon_tiles, MoonTile{
                    x      = x,
                    y      = y,
                    grid_x = i32(col),
                    grid_y = i32(row),
                })
            case 'O':
                // Angry planet (8x8 tiles, 128x128 px)
                if planet_origin_x < 0 || col < int(planet_origin_x) {
                    planet_origin_x = i32(col)
                }
                if planet_origin_y < 0 || row < int(planet_origin_y) {
                    planet_origin_y = i32(row)
                }
                append(&level.angry_planet_tiles, AngryPlanetTile{
                    x      = x,
                    y      = y,
                    grid_x = i32(col),
                    grid_y = i32(row),
                })
            case 'A', 'B':
                // Static building 1 (windows)
                if building_origins[.Static1][0] < 0 || col < int(building_origins[.Static1][0]) {
                    building_origins[.Static1][0] = i32(col)
                }
                if building_origins[.Static1][1] < 0 || row < int(building_origins[.Static1][1]) {
                    building_origins[.Static1][1] = i32(row)
                }
                append(&level.buildings, BuildingTile{
                    x      = x,
                    y      = y,
                    grid_x = i32(col),
                    grid_y = i32(row),
                    type   = .Static1,
                })
            case 'F':
                // Static building 2 (cityscape)
                if building_origins[.Static2][0] < 0 || col < int(building_origins[.Static2][0]) {
                    building_origins[.Static2][0] = i32(col)
                }
                if building_origins[.Static2][1] < 0 || row < int(building_origins[.Static2][1]) {
                    building_origins[.Static2][1] = i32(row)
                }
                append(&level.buildings, BuildingTile{
                    x      = x,
                    y      = y,
                    grid_x = i32(col),
                    grid_y = i32(row),
                    type   = .Static2,
                })
            case 'W':
                // Win tile (level exit for final level)
                append(&level.win_tiles, WinTile{x, y, TILE_SIZE, TILE_SIZE})
            }
        }
    }

    level.width = f32(max_cols * TILE_SIZE)
    level.height = f32(row_count * TILE_SIZE)

    for &moon in level.moon_tiles {
        moon.grid_x = moon.grid_x - moon_origin_x
        moon.grid_y = moon.grid_y - moon_origin_y
    }

    for &planet in level.angry_planet_tiles {
        planet.grid_x = planet.grid_x - planet_origin_x
        planet.grid_y = planet.grid_y - planet_origin_y
    }

    for &building in level.buildings {
        origin := building_origins[building.type]
        if origin[0] >= 0 {
            building.grid_x = building.grid_x - origin[0]
            building.grid_y = building.grid_y - origin[1]
        }
    }

    return level
}

unload_level :: proc(level: ^Level) {
    delete(level.grounds)
    delete(level.ground_tiles)
    delete(level.ladders)
    delete(level.enemies)
    delete(level.doors)
    delete(level.traps)
    delete(level.items)
    delete(level.instruments)
    delete(level.moon_tiles)
    delete(level.angry_planet_tiles)
    delete(level.buildings)
    delete(level.win_tiles)
}
