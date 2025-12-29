package main

import rl "vendor:raylib"
import "core:os"
import "core:strings"

TILE_SIZE :: 16

Level :: struct {
    grounds:      [dynamic]Ground,
    ladders:      [dynamic]Ladder,
    enemies:      [dynamic]Enemy,
    player_spawn: rl.Vector2,
}

load_level :: proc(path: string) -> Level {
    level := Level{
        grounds      = make([dynamic]Ground),
        ladders      = make([dynamic]Ladder),
        enemies      = make([dynamic]Enemy),
        player_spawn = {100, 317}, // default
    }

    data, ok := os.read_entire_file(path)
    if !ok {
        return level
    }
    defer delete(data)

    content := string(data)
    lines := strings.split_lines(content)
    defer delete(lines)

    for line, row in lines {
        if len(line) == 0 do continue

        for char, col in line {
            x := f32(col * TILE_SIZE)
            y := f32(row * TILE_SIZE)

            switch char {
            case '#':
                // Check if we can extend the previous ground (horizontal merge)
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
                // Check if we can extend the previous ladder (vertical merge)
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
            // Add more cases here as needed:
            // case 'D': // door
            // case 'S': // spikes
            // case 'C': // collectible
            }
        }
    }

    return level
}

unload_level :: proc(level: ^Level) {
    delete(level.grounds)
    delete(level.ladders)
    delete(level.enemies)
}

Ground :: struct {
    x, y:          f32,
    width, height: f32,
}

PlayerState :: enum {
    Idle,
    Moving,
    Jumping,
    Climbing,
}

Ladder :: struct {
    x, y:          f32,
    width, height: f32,
}

Animation :: struct {
    texture:     rl.Texture2D,
    frame_count: i32,
    frame_time:  f32,
}

Enemy :: struct {
    x, y:      f32,
    start_x:   f32,
    direction: f32,  // 1 = right, -1 = left
}

ENEMY_SPEED :: 30.0
ENEMY_PATROL_RANGE :: 30.0

Player :: struct {
    x, y:          f32,
    vel_y:         f32,
    grounded:      bool,
    state:         PlayerState,
    facing_left:   bool,
    current_frame: i32,
    frame_timer:   f32,
}

PLAYER_SPEED  :: 100.0
JUMP_FORCE    :: 400.0
GRAVITY       :: 800.0
FRAME_SIZE    :: 16

main :: proc() {
    rl.InitWindow(640, 360, "Silent Night")
    defer rl.CloseWindow()

    // Here we configure the animations
    idle_anim := Animation{
        texture     = rl.LoadTexture("assets/sprites/player_idle-sheet.png"),
        frame_count = 6,
        frame_time  = 0.15,
    }
    defer rl.UnloadTexture(idle_anim.texture)

    move_anim := Animation{
        texture     = rl.LoadTexture("assets/sprites/player_movement.png"),
        frame_count = 5,
        frame_time  = 0.1,
    }
    defer rl.UnloadTexture(move_anim.texture)

    jump_anim := Animation{
        texture     = rl.LoadTexture("assets/sprites/player_jump.png"),
        frame_count = 4,
        frame_time  = 0.15,
    }
    defer rl.UnloadTexture(jump_anim.texture)

    // Load level from file
    level := load_level("assets/maps/level1.txt")
    defer unload_level(&level)

    player := Player{
        x             = level.player_spawn.x,
        y             = level.player_spawn.y,
        vel_y         = 0,
        grounded      = true,
        state         = .Idle,
        facing_left   = false,
        current_frame = 0,
        frame_timer   = 0,
    }

    // This section details the game logic
    noise_meter: f32 = 0
    game_over := false

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        
        if game_over && rl.IsKeyPressed(.R) {
            noise_meter = 0
            player.x = level.player_spawn.x
            player.y = level.player_spawn.y
            player.vel_y = 0
            player.grounded = true
            player.state = .Idle
            // Reset enemies to starting positions
            for &enemy in level.enemies {
                enemy.x = enemy.start_x
            }
            game_over = false
        }

        // Track if moving this frame
        moving := false
        climbing := false

        on_ladder := false
        for ladder in level.ladders {
            if player.x >= ladder.x && player.x <= ladder.x + ladder.width &&
               player.y >= ladder.y && player.y <= ladder.y + ladder.height {
                on_ladder = true
                break
            }
        }

        // This section sets up movement, gravity, and tile colision
        if !game_over {
        if rl.IsKeyDown(.A) {
            player.x -= PLAYER_SPEED * dt
            player.facing_left = true
            moving = true
        }
        if rl.IsKeyDown(.D) {
            player.x += PLAYER_SPEED * dt
            player.facing_left = false
            moving = true
        }

        // Climbing controls (W/S)
        if on_ladder {
            if rl.IsKeyDown(.W) {
                player.y -= PLAYER_SPEED * 0.5 * dt
                player.vel_y = 0
                climbing = true
            }
            if rl.IsKeyDown(.S) {
                player.y += PLAYER_SPEED * 0.5 * dt
                player.vel_y = 0
                climbing = true
            }
            // Add noise when climbing (8 per second)
            if climbing {
                noise_meter += 8.0 * dt
            }
        }

        if rl.IsKeyPressed(.SPACE) && player.grounded && !on_ladder {
            player.vel_y = -JUMP_FORCE
            player.grounded = false
            noise_meter += 20  // Jumping adds noise
        }

        was_airborne := !player.grounded

        // Apply gravity only when not on ladder
        if !player.grounded && !on_ladder {
            player.vel_y += GRAVITY * dt
            player.y += player.vel_y * dt
        } else if on_ladder && !climbing {
            // Hold position on ladder when not actively climbing
            player.vel_y = 0
        }

        // Ground/platform collision (only when falling)
        for ground in level.grounds {
            ground_top := ground.y - 8
            if player.x >= ground.x && player.x <= ground.x + ground.width {
                if player.y >= ground_top && player.y <= ground_top + 16 && player.vel_y >= 0 {
                    player.y = ground_top
                    player.vel_y = 0
                    if was_airborne && !on_ladder {
                        noise_meter += 10  // Landing adds noise
                    }
                    player.grounded = true
                }
            }
        }

        // Check if player is still grounded (for walking off platforms)
        if player.grounded && !on_ladder {
            still_on_ground := false
            for ground in level.grounds {
                ground_top := ground.y - 8
                if player.x >= ground.x && player.x <= ground.x + ground.width &&
                   player.y >= ground_top - 1 && player.y <= ground_top + 1 {
                    still_on_ground = true
                    break
                }
            }
            if !still_on_ground {
                player.grounded = false
            }
        }

        // This sections sets up animation based on player state
        prev_state := player.state
        if climbing {
            player.state = .Climbing
        } else if !player.grounded {
            player.state = .Jumping
        } else if moving {
            player.state = .Moving
        } else {
            player.state = .Idle
        }

        // Reset animation frame when state changes
        if player.state != prev_state {
            player.current_frame = 0
            player.frame_timer = 0
        }

        if moving {
            // Increase by +1 every 0.25 seconds (+4 per second)
            noise_meter += 4.0 * dt
        } else {
            // Decrease by 2 per second (half of movement rate)
            noise_meter -= 2.0 * dt
        }
        noise_meter = clamp(noise_meter, 0, 100)

        if noise_meter >= 100 {
            game_over = true
        }

        // Enemy patrol movement and collision detection
        visibility_radius := 20.0 + noise_meter
        for &enemy in level.enemies {
            enemy.x += enemy.direction * ENEMY_SPEED * dt
            if enemy.x <= enemy.start_x - ENEMY_PATROL_RANGE {
                enemy.direction = 1
            } else if enemy.x >= enemy.start_x + ENEMY_PATROL_RANGE {
                enemy.direction = -1
            }

            // Check if player is within enemy's visibility radius
            dx := player.x - enemy.x
            dy := player.y - enemy.y
            distance := rl.Vector2Length(rl.Vector2{dx, dy})
            if distance <= visibility_radius {
                game_over = true
            }
        }
        } // end if !game_over

        // Animation (runs even during game over to keep sprite visible)
        current_anim: ^Animation
        switch player.state {
        case .Idle:
            current_anim = &idle_anim
        case .Moving:
            current_anim = &move_anim
        case .Jumping:
            current_anim = &jump_anim
        case .Climbing:
            current_anim = &idle_anim  // Reuse idle animation for climbing
        }

        if !game_over {
            player.frame_timer += dt
            if player.frame_timer >= current_anim.frame_time {
                player.frame_timer = 0
                player.current_frame = (player.current_frame + 1) % current_anim.frame_count
            }
        }

        // And here we do the drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        // Draw all grounds
        for ground in level.grounds {
            rl.DrawRectangle(
                i32(ground.x),
                i32(ground.y),
                i32(ground.width),
                i32(ground.height),
                rl.GRAY,
            )
        }

        // Draw all ladders
        for ladder in level.ladders {
            rl.DrawRectangle(
                i32(ladder.x),
                i32(ladder.y),
                i32(ladder.width),
                i32(ladder.height),
                rl.BROWN,
            )
            // Ladder rungs
            rung_count := i32(ladder.height / TILE_SIZE) + 1
            for i in 0..<rung_count {
                rung_y := i32(ladder.y) + i32(f32(i) * ladder.height / f32(rung_count)) + 6
                rl.DrawRectangle(i32(ladder.x) + 2, rung_y, i32(ladder.width) - 4, 2, rl.DARKBROWN)
            }
        }

        
        source_rect := rl.Rectangle{
            x      = f32(player.current_frame * FRAME_SIZE),
            y      = 0,
            width  = FRAME_SIZE if !player.facing_left else -FRAME_SIZE,
            height = FRAME_SIZE,
        }

        dest_rect := rl.Rectangle{
            x      = player.x - FRAME_SIZE / 2,
            y      = player.y - FRAME_SIZE / 2,
            width  = FRAME_SIZE,
            height = FRAME_SIZE,
        }

        rl.DrawTexturePro(
            current_anim.texture,
            source_rect,
            dest_rect,
            rl.Vector2{0, 0},
            0,
            rl.WHITE,
        )

        // Draw enemies
        vis_radius := 20.0 + noise_meter
        for enemy in level.enemies {
            // Draw visibility radius (circle)
            rl.DrawCircleLines(i32(enemy.x), i32(enemy.y), vis_radius, rl.Color{255, 100, 100, 150})
            rl.DrawCircle(i32(enemy.x), i32(enemy.y), vis_radius, rl.Color{255, 0, 0, 30})
            // Draw enemy (16x16 ellipse placeholder)
            rl.DrawEllipse(i32(enemy.x), i32(enemy.y), 8, 8, rl.RED)
        }

        // Draw noise meter
        METER_X      :: 10
        METER_Y      :: 10
        METER_WIDTH  :: 100
        METER_HEIGHT :: 12

        // Background (empty meter)
        rl.DrawRectangle(METER_X, METER_Y, METER_WIDTH, METER_HEIGHT, rl.DARKGRAY)
        // Filled portion
        filled_width := i32(noise_meter)
        rl.DrawRectangle(METER_X, METER_Y, filled_width, METER_HEIGHT, rl.RED)
        // Border
        rl.DrawRectangleLines(METER_X, METER_Y, METER_WIDTH, METER_HEIGHT, rl.WHITE)
        // Label
        rl.DrawText("NOISE", METER_X, METER_Y + METER_HEIGHT + 2, 10, rl.WHITE)

        // Game over screen
        if game_over {
            rl.DrawRectangle(0, 0, 640, 360, rl.Color{0, 0, 0, 180})
            rl.DrawText("GAME OVER", 220, 150, 40, rl.RED)
            rl.DrawText("Press R to restart", 240, 200, 20, rl.WHITE)
        }

        rl.EndDrawing()
    }
}
