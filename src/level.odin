package main

import rl "vendor:raylib"
import "core:os"
import "core:strings"

TILE_SIZE :: 16

Level :: struct {
    grounds:      [dynamic]Ground,
    ladders:      [dynamic]Ladder,
    enemies:      [dynamic]Enemy,
    doors:        [dynamic]Door,
    traps:        [dynamic]Trap,
    items:        [dynamic]Item,
    moon_tiles:   [dynamic]MoonTile,
    stars:        [dynamic]Star,
    player_spawn: rl.Vector2,
    width:        f32,
    height:       f32,
}

Ground :: struct {
    x, y:          f32,
    width, height: f32,
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

MoonTile :: struct {
    x, y:       f32,
    grid_x:     i32,
    grid_y:     i32,
}

Star :: struct {
    x, y:       f32,
}

load_level :: proc(path: string) -> Level {
    level := Level{
        grounds      = make([dynamic]Ground),
        ladders      = make([dynamic]Ladder),
        enemies      = make([dynamic]Enemy),
        doors        = make([dynamic]Door),
        traps        = make([dynamic]Trap),
        items        = make([dynamic]Item),
        moon_tiles   = make([dynamic]MoonTile),
        stars        = make([dynamic]Star),
        player_spawn = {100, 317},
    }

    moon_origin_x: i32 = -1
    moon_origin_y: i32 = -1

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
            case 'S':
                append(&level.stars, Star{x, y})
            }
        }
    }

    level.width = f32(max_cols * TILE_SIZE)
    level.height = f32(row_count * TILE_SIZE)

    for &moon in level.moon_tiles {
        moon.grid_x = moon.grid_x - moon_origin_x
        moon.grid_y = moon.grid_y - moon_origin_y
    }

    return level
}

unload_level :: proc(level: ^Level) {
    delete(level.grounds)
    delete(level.ladders)
    delete(level.enemies)
    delete(level.doors)
    delete(level.traps)
    delete(level.items)
    delete(level.moon_tiles)
    delete(level.stars)
}
