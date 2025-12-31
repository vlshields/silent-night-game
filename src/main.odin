package main

import rl "vendor:raylib"
import "core:os"
import "core:strings"
import "core:math"

TILE_SIZE :: 16

Level :: struct {
    grounds:      [dynamic]Ground,
    ladders:      [dynamic]Ladder,
    enemies:      [dynamic]Enemy,
    doors:        [dynamic]Door,
    traps:        [dynamic]Trap,
    items:        [dynamic]Item,
    player_spawn: rl.Vector2,
    width:        f32,
    height:       f32,
}

load_level :: proc(path: string) -> Level {
    level := Level{
        grounds      = make([dynamic]Ground),
        ladders      = make([dynamic]Ladder),
        enemies      = make([dynamic]Enemy),
        doors        = make([dynamic]Door),
        traps        = make([dynamic]Trap),
        items        = make([dynamic]Item),
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
            case 'D':
                append(&level.doors, Door{x, y, TILE_SIZE, TILE_SIZE})
            case 'T':
                append(&level.traps, Trap{x, y, TILE_SIZE, TILE_SIZE, false})
            case 'I':
                append(&level.items, Item{x, y, TILE_SIZE, TILE_SIZE, false})
            }
        }
    }

    level.width = f32(max_cols * TILE_SIZE)
    level.height = f32(row_count * TILE_SIZE)

    return level
}

unload_level :: proc(level: ^Level) {
    delete(level.grounds)
    delete(level.ladders)
    delete(level.enemies)
    delete(level.doors)
    delete(level.traps)
    delete(level.items)
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
    x, y:          f32,
    start_x:       f32,
    direction:     f32,  // 1 = right, -1 = left
    stun_timer:    f32,  // Seconds remaining stunned (0 = not stunned)
    current_frame: i32,
    frame_timer:   f32,
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

Rock :: struct {
    x, y:       f32,
    vel_x:      f32,
    vel_y:      f32,
    active:     bool,
    start_x:    f32,  // Track starting position for 40px travel
}

TutorialStep :: enum {
    Intro1,         // Movement and noise meter
    Intro2,         // Guard detection
    Intro3,         // Sensory regions grow
    Intro4,         // Standing still depletes noise
    ArrowLadder,    // Flashing arrow + climb dialogue
    WaitForClimb,   // Player must climb
    ArrowTrap,      // Flashing arrow + trap warning
    WaitForTrapPass,// Player must pass the trap
    ArrowItem,      // Flashing arrow + rock dialogue
    RockInfo2,      // Miss penalty dialogue
    WaitForPickup,  // Player must pick up
    ThrowInfo,      // Left click dialogue
    Complete,       // Tutorial done
}

// Tutorial dialogue strings
TUTORIAL_INTRO1 :: "Shhhh, be quiet! Each step you take with A or D will\nincrease your Noise meter. So will jumping (Spacebar)\nand landing on the ground."

TUTORIAL_INTRO2 :: "If your Noise meter becomes full, you will be captured!\nIf any patrolling guard sees or hears you, you will be\ncaptured. Stay out of their sensory region shown in red!"

TUTORIAL_INTRO3 :: "The guards' sensory regions will grow as your\nNoise meter grows too."

TUTORIAL_INTRO4 :: "Standing still will deplete your noise meter and\nthe guards' sensory region. Be patient!"

TUTORIAL_LADDER :: "Head up this ladder with W.\nBut be careful, climbing makes noise too!"

TUTORIAL_TRAP :: "Be careful of trash or objects on the ground,\nthey can make a lot of noise and get you caught!"

TUTORIAL_ROCK1 :: "If you find a rock, you can pick it up and throw it.\nIf it hits a guard, they will be stunned for 5 seconds."

TUTORIAL_ROCK2 :: "But if you miss, you will make a lot of noise!\nMake sure you are close enough to hit the guard!"

TUTORIAL_THROW :: "Left click in the direction of the guard\nto throw the rock at them."

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
    has_rock:      bool,
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

    // Enemy animations
    enemy_move_anim := Animation{
        texture     = rl.LoadTexture("assets/sprites/enemy_movement.png"),
        frame_count = 7,
        frame_time  = 0.12,
    }
    defer rl.UnloadTexture(enemy_move_anim.texture)

    enemy_stunned_anim := Animation{
        texture     = rl.LoadTexture("assets/sprites/enemy_stunned.png"),
        frame_count = 7,
        frame_time  = 0.15,
    }
    defer rl.UnloadTexture(enemy_stunned_anim.texture)

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
    rock := Rock{}  // Thrown rock projectile

    // Tutorial state
    tutorial_step := TutorialStep.Intro1
    tutorial_active := true  // Pauses game when true
    arrow_timer: f32 = 0     // For flashing animation
    first_ladder_x: f32 = 0
    first_ladder_top: f32 = 999999
    item_pos := rl.Vector2{0, 0}
    trap_pos := rl.Vector2{0, 0}

    // Find first ladder position and item position for tutorial arrows
    for ladder in level.ladders {
        if first_ladder_x == 0 || ladder.x < first_ladder_x {
            first_ladder_x = ladder.x
            first_ladder_top = ladder.y
        }
    }
    for item in level.items {
        item_pos = {item.x + item.width / 2, item.y}
        break  // Just get first item position
    }
    for trap in level.traps {
        trap_pos = {trap.x + trap.width / 2, trap.y}
        break  // Just get first trap position
    }

    // Camera setup - follows the player
    camera := rl.Camera2D{
        target = {player.x, player.y},
        offset = {320, 180},  // Center of 640x360 window
        rotation = 0,
        zoom = 1,
    }

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        // Update arrow animation timer (always runs)
        arrow_timer += dt

        // Tutorial input handling
        if tutorial_active && rl.IsKeyPressed(.ENTER) {
            switch tutorial_step {
            case .Intro1:
                tutorial_step = .Intro2
            case .Intro2:
                tutorial_step = .Intro3
            case .Intro3:
                tutorial_step = .Intro4
            case .Intro4:
                tutorial_step = .ArrowLadder
            case .ArrowLadder:
                tutorial_step = .WaitForClimb
                tutorial_active = false
            case .ArrowTrap:
                tutorial_step = .WaitForTrapPass
                tutorial_active = false
            case .ArrowItem:
                tutorial_step = .RockInfo2
            case .RockInfo2:
                tutorial_step = .WaitForPickup
                tutorial_active = false
            case .ThrowInfo:
                tutorial_step = .Complete
                tutorial_active = false
            case .WaitForClimb, .WaitForTrapPass, .WaitForPickup, .Complete:
                // No action for these states
            }
        }

        if game_over && rl.IsKeyPressed(.R) {
            noise_meter = 0
            player.x = level.player_spawn.x
            player.y = level.player_spawn.y
            player.vel_y = 0
            player.grounded = true
            player.state = .Idle
            player.has_rock = false
            // Reset rock projectile
            rock = Rock{}
            // Reset enemies to starting positions
            for &enemy in level.enemies {
                enemy.x = enemy.start_x
                enemy.stun_timer = 0
                enemy.current_frame = 0
                enemy.frame_timer = 0
            }
            // Reset traps
            for &trap in level.traps {
                trap.triggered = false
            }
            // Reset items
            for &item in level.items {
                item.collected = false
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
        if !game_over && !tutorial_active {
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

        // Trap collision - adds +40 noise when stepped on (once per trap)
        for &trap in level.traps {
            if !trap.triggered {
                trap_top := trap.y - 8
                if player.x >= trap.x && player.x <= trap.x + trap.width &&
                   player.y >= trap_top && player.y <= trap_top + 8 {
                    trap.triggered = true
                    noise_meter += 40
                }
            }
        }

        // Item pickup (rocks) - player gains ability to throw
        for &item in level.items {
            if !item.collected && !player.has_rock {
                if player.x >= item.x && player.x <= item.x + item.width &&
                   player.y >= item.y && player.y <= item.y + item.height {
                    item.collected = true
                    player.has_rock = true
                    // Tutorial trigger: picked up item
                    if tutorial_step == .WaitForPickup {
                        tutorial_step = .ThrowInfo
                        tutorial_active = true
                    }
                }
            }
        }

        // Rock throwing - left click to throw
        if player.has_rock && !rock.active && rl.IsMouseButtonPressed(.LEFT) {
            rock.active = true
            rock.x = player.x
            rock.y = player.y
            rock.start_x = player.x
            // Throw in direction player is facing - travels straight for 120px then drops
            rock.vel_x = 160.0 if !player.facing_left else -160.0
            rock.vel_y = 0  // No vertical velocity until rock drops
            player.has_rock = false
            noise_meter += 10  // +10 noise when thrown
        }

        // Update rock projectile
        if rock.active {
            rock.x += rock.vel_x * dt

            // Check if rock has traveled 120px horizontally
            if abs(rock.x - rock.start_x) >= 120.0 {
                // Rock falls straight down after 120px travel
                rock.vel_x = 0
                rock.vel_y += GRAVITY * 0.5 * dt  // Apply gravity only after 120px
                rock.y += rock.vel_y * dt
            }

            // Check collision with enemies (stun them)
            hit_enemy := false
            for &enemy in level.enemies {
                dx := rock.x - enemy.x
                dy := rock.y - enemy.y
                distance := rl.Vector2Length(rl.Vector2{dx, dy})
                if distance <= 10.0 {  // Hit radius
                    enemy.stun_timer = 5.0  // Stun for 5 seconds
                    enemy.current_frame = 0  // Reset animation for clean transition
                    enemy.frame_timer = 0
                    rock.active = false
                    hit_enemy = true
                    break
                }
            }

            // Check collision with ground (miss penalty)
            if !hit_enemy {
                for ground in level.grounds {
                    if rock.x >= ground.x && rock.x <= ground.x + ground.width &&
                       rock.y >= ground.y && rock.y <= ground.y + ground.height {
                        rock.active = false
                        noise_meter += 60  // +60 noise for missing
                        break
                    }
                }
            }

            // Deactivate if rock falls below map
            if rock.y > level.height + 50 {
                rock.active = false
                noise_meter += 60  // Missed - fell off map
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
            noise_meter -= 3.0 * dt
        }
        noise_meter = clamp(noise_meter, 0, 100)

        if noise_meter >= 100 {
            game_over = true
        }

        // Enemy patrol movement and collision detection
        visibility_radius := 20.0 + noise_meter
        for &enemy in level.enemies {
            // Update enemy animation
            enemy.frame_timer += dt
            enemy_anim := &enemy_stunned_anim if enemy.stun_timer > 0 else &enemy_move_anim
            if enemy.frame_timer >= enemy_anim.frame_time {
                enemy.frame_timer = 0
                enemy.current_frame = (enemy.current_frame + 1) % enemy_anim.frame_count
            }

            // Decrement stun timer
            if enemy.stun_timer > 0 {
                enemy.stun_timer -= dt
                // Reset animation when recovering from stun
                if enemy.stun_timer <= 0 {
                    enemy.current_frame = 0
                    enemy.frame_timer = 0
                } else {
                    continue  // Skip movement and detection while stunned
                }
            }

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

        // Tutorial trigger: climbed the first ladder (reached top platform area)
        if tutorial_step == .WaitForClimb && player.y < first_ladder_top + 16 {
            tutorial_step = .ArrowTrap
            tutorial_active = true
        }

        // Tutorial trigger: passed the trap (player x is past the trap, must be grounded)
        if tutorial_step == .WaitForTrapPass && player.x > trap_pos.x + TILE_SIZE && player.grounded {
            tutorial_step = .ArrowItem
            tutorial_active = true
        }
        } // end if !game_over && !tutorial_active

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

        // Update camera to follow player, clamped to map bounds
        camera.target.x = clamp(player.x, camera.offset.x, level.width - camera.offset.x)
        camera.target.y = clamp(player.y, camera.offset.y, level.height - camera.offset.y)

        // And here we do the drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        // Begin camera mode for world drawing
        rl.BeginMode2D(camera)

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

        // Draw all doors (placeholder - blue rectangle)
        for door in level.doors {
            rl.DrawRectangle(
                i32(door.x),
                i32(door.y),
                i32(door.width),
                i32(door.height),
                rl.BLUE,
            )
        }

        // Draw all traps (slightly off-colored tile)
        for trap in level.traps {
            trap_color := rl.Color{100, 100, 100, 255} if !trap.triggered else rl.Color{80, 80, 80, 255}
            rl.DrawRectangle(
                i32(trap.x),
                i32(trap.y),
                i32(trap.width),
                i32(trap.height),
                trap_color,
            )
        }

        // Draw all items (placeholder - yellow rectangle)
        for item in level.items {
            if !item.collected {
                rl.DrawRectangle(
                    i32(item.x),
                    i32(item.y),
                    i32(item.width),
                    i32(item.height),
                    rl.YELLOW,
                )
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
            is_stunned := enemy.stun_timer > 0
            if !is_stunned {
                // Draw visibility radius (circle) only when not stunned
                rl.DrawCircleLines(i32(enemy.x), i32(enemy.y), vis_radius, rl.Color{255, 100, 100, 150})
                rl.DrawCircle(i32(enemy.x), i32(enemy.y), vis_radius, rl.Color{255, 0, 0, 30})
            }

            // Draw enemy sprite
            enemy_anim := &enemy_stunned_anim if is_stunned else &enemy_move_anim
            enemy_facing_left := enemy.direction < 0

            enemy_source_rect := rl.Rectangle{
                x      = f32(enemy.current_frame * FRAME_SIZE),
                y      = 0,
                width  = FRAME_SIZE if !enemy_facing_left else -FRAME_SIZE,
                height = FRAME_SIZE,
            }

            enemy_dest_rect := rl.Rectangle{
                x      = enemy.x - FRAME_SIZE / 2,
                y      = enemy.y - FRAME_SIZE / 2,
                width  = FRAME_SIZE,
                height = FRAME_SIZE,
            }

            rl.DrawTexturePro(
                enemy_anim.texture,
                enemy_source_rect,
                enemy_dest_rect,
                rl.Vector2{0, 0},
                0,
                rl.WHITE,
            )
        }

        // Draw rock projectile
        if rock.active {
            rl.DrawCircle(i32(rock.x), i32(rock.y), 4, rl.Color{139, 119, 101, 255})  // Brown rock
        }

        // End camera mode before drawing UI
        rl.EndMode2D()

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

        // Guard stunned indicator - show countdown for stunned enemy
        for enemy in level.enemies {
            if enemy.stun_timer > 0 {
                stun_text := rl.TextFormat("Guard Stunned %.0fs", enemy.stun_timer)
                rl.DrawText(stun_text, METER_X + METER_WIDTH + 10, METER_Y, 10, rl.SKYBLUE)
                break
            }
        }

        // Rock indicator
        if player.has_rock {
            rl.DrawCircle(130, 16, 6, rl.Color{139, 119, 101, 255})
            rl.DrawText("LMB", 140, 10, 10, rl.WHITE)
        }

        // Tutorial overlay
        if tutorial_step != .Complete {
            // Draw flashing arrow for ladder/item steps
            if tutorial_step == .ArrowLadder || tutorial_step == .WaitForClimb {
                // Calculate screen position of first ladder
                arrow_world_x := first_ladder_x + TILE_SIZE / 2
                arrow_world_y := first_ladder_top - 20
                arrow_screen_x := arrow_world_x - camera.target.x + camera.offset.x
                arrow_screen_y := arrow_world_y - camera.target.y + camera.offset.y

                // Flashing effect using sin wave
                alpha := u8(150 + 100 * math.sin(arrow_timer * 5.0))
                arrow_color := rl.Color{255, 255, 0, alpha}

                // Draw downward pointing arrow (triangle)
                rl.DrawTriangle(
                    rl.Vector2{arrow_screen_x, arrow_screen_y + 15},      // Bottom point
                    rl.Vector2{arrow_screen_x + 8, arrow_screen_y},       // Top right
                    rl.Vector2{arrow_screen_x - 8, arrow_screen_y},       // Top left
                    arrow_color,
                )
            }

            if tutorial_step == .ArrowTrap || tutorial_step == .WaitForTrapPass {
                // Calculate screen position of trap
                arrow_world_x := trap_pos.x
                arrow_world_y := trap_pos.y - 20
                arrow_screen_x := arrow_world_x - camera.target.x + camera.offset.x
                arrow_screen_y := arrow_world_y - camera.target.y + camera.offset.y

                // Flashing effect using sin wave
                alpha := u8(150 + 100 * math.sin(arrow_timer * 5.0))
                arrow_color := rl.Color{255, 255, 0, alpha}

                // Draw downward pointing arrow (triangle)
                rl.DrawTriangle(
                    rl.Vector2{arrow_screen_x, arrow_screen_y + 15},      // Bottom point
                    rl.Vector2{arrow_screen_x + 8, arrow_screen_y},       // Top right
                    rl.Vector2{arrow_screen_x - 8, arrow_screen_y},       // Top left
                    arrow_color,
                )
            }

            if tutorial_step == .ArrowItem || tutorial_step == .RockInfo2 || tutorial_step == .WaitForPickup {
                // Calculate screen position of item
                arrow_world_x := item_pos.x
                arrow_world_y := item_pos.y - 20
                arrow_screen_x := arrow_world_x - camera.target.x + camera.offset.x
                arrow_screen_y := arrow_world_y - camera.target.y + camera.offset.y

                // Flashing effect using sin wave
                alpha := u8(150 + 100 * math.sin(arrow_timer * 5.0))
                arrow_color := rl.Color{255, 255, 0, alpha}

                // Draw downward pointing arrow (triangle)
                rl.DrawTriangle(
                    rl.Vector2{arrow_screen_x, arrow_screen_y + 15},      // Bottom point
                    rl.Vector2{arrow_screen_x + 8, arrow_screen_y},       // Top right
                    rl.Vector2{arrow_screen_x - 8, arrow_screen_y},       // Top left
                    arrow_color,
                )
            }

            // Draw dialogue box when tutorial is active
            if tutorial_active {
                // Semi-transparent background
                rl.DrawRectangle(40, 220, 560, 120, rl.Color{0, 0, 0, 200})
                rl.DrawRectangleLines(40, 220, 560, 120, rl.WHITE)

                // Get the dialogue text for current step
                dialogue_text: cstring = ""
                switch tutorial_step {
                case .Intro1:
                    dialogue_text = TUTORIAL_INTRO1
                case .Intro2:
                    dialogue_text = TUTORIAL_INTRO2
                case .Intro3:
                    dialogue_text = TUTORIAL_INTRO3
                case .Intro4:
                    dialogue_text = TUTORIAL_INTRO4
                case .ArrowLadder:
                    dialogue_text = TUTORIAL_LADDER
                case .ArrowTrap:
                    dialogue_text = TUTORIAL_TRAP
                case .ArrowItem:
                    dialogue_text = TUTORIAL_ROCK1
                case .RockInfo2:
                    dialogue_text = TUTORIAL_ROCK2
                case .ThrowInfo:
                    dialogue_text = TUTORIAL_THROW
                case .WaitForClimb, .WaitForTrapPass, .WaitForPickup, .Complete:
                    // No dialogue for these states
                }

                // Draw dialogue text
                rl.DrawText(dialogue_text, 55, 235, 15, rl.WHITE)

                // Draw "Press Enter" prompt (flashing)
                prompt_alpha := u8(150 + 100 * math.sin(arrow_timer * 3.0))
                rl.DrawText("Press Enter", 270, 315, 15, rl.Color{255, 255, 255, prompt_alpha})
            }
        }

        // Game over screen
        if game_over {
            rl.DrawRectangle(0, 0, 640, 360, rl.Color{0, 0, 0, 180})
            rl.DrawText("GAME OVER", 220, 150, 40, rl.RED)
            rl.DrawText("Press R to restart", 240, 200, 20, rl.WHITE)
        }

        rl.EndDrawing()
    }
}
