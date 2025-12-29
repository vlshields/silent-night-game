package main

import rl "vendor:raylib"

Ground :: struct {
    x, y:          f32,
    width, height: f32,
}

PlayerState :: enum {
    Idle,
    Moving,
    Jumping,
}

Animation :: struct {
    texture:     rl.Texture2D,
    frame_count: i32,
    frame_time:  f32,
}

Enemy :: struct {
    x, y: f32,
}

Player :: struct {
    x, y:          f32,
    vel_y:         f32,
    grounded:      bool,
    state:         PlayerState,
    facing_left:   bool,
    current_frame: i32,
    frame_timer:   f32,
}

PLAYER_SPEED  :: 200.0
JUMP_FORCE    :: 400.0
GRAVITY       :: 800.0
FRAME_SIZE    :: 16

main :: proc() {
    rl.InitWindow(640, 360, "Silent Night")
    defer rl.CloseWindow()

    
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

    ground := Ground{
        x      = 0,
        y      = 325,
        width  = 640,
        height = 35,
    }

    player := Player{
        x             = 320,
        y             = 317,
        vel_y         = 0,
        grounded      = true,
        state         = .Idle,
        facing_left   = false,
        current_frame = 0,
        frame_timer   = 0,
    }

    // Enemy patroller on the right side of the map
    enemy := Enemy{
        x = 580,
        y = 317,
    }

    // Noise meter: 0 to 100
    noise_meter: f32 = 0
    game_over := false

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        // Restart game
        if game_over && rl.IsKeyPressed(.R) {
            noise_meter = 0
            player.x = 320
            player.y = 317
            player.vel_y = 0
            player.grounded = true
            player.state = .Idle
            game_over = false
        }

        // Track if moving this frame
        moving := false

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


        if rl.IsKeyPressed(.SPACE) && player.grounded {
            player.vel_y = -JUMP_FORCE
            player.grounded = false
            noise_meter += 20  // Jumping adds noise
        }

        was_airborne := !player.grounded

        if !player.grounded {
            player.vel_y += GRAVITY * dt
            player.y += player.vel_y * dt
        }

        ground_top := ground.y - 8
        if player.y >= ground_top {
            player.y = ground_top
            player.vel_y = 0
            player.grounded = true
            if was_airborne {
                noise_meter += 10  // Landing adds noise
            }
        }

        // This sections sets up animation based on player state
        prev_state := player.state
        if !player.grounded {
            player.state = .Jumping
        } else if moving {
            player.state = .Moving
        } else {
            player.state = .Idle
        }

        // Update noise meter
        if moving {
            // Increase by 0.01 * PLAYER_SPEED per second when moving
            noise_meter += 0.01 * PLAYER_SPEED * dt
        } else {
            // Decrease by 0.01 * PLAYER_SPEED per 3 seconds when idle
            noise_meter -= 0.01 * PLAYER_SPEED * dt / 3
        }
        // Clamp noise meter between 0 and 100
        noise_meter = clamp(noise_meter, 0, 100)

        // Check for game over (noise meter)
        if noise_meter >= 100 {
            game_over = true
        }

        // Check if player is within enemy's visibility radius
        visibility_radius := 20.0 + noise_meter
        dx := player.x - enemy.x
        dy := player.y - enemy.y
        distance := rl.Vector2Length(rl.Vector2{dx, dy})
        if distance <= visibility_radius {
            game_over = true
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

        
        rl.DrawRectangle(
            i32(ground.x),
            i32(ground.y),
            i32(ground.width),
            i32(ground.height),
            rl.GRAY,
        )

        
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

        // Draw enemy visibility radius (circle)
        vis_radius := 20.0 + noise_meter
        rl.DrawCircleLines(i32(enemy.x), i32(enemy.y), vis_radius, rl.Color{255, 100, 100, 150})
        rl.DrawCircle(i32(enemy.x), i32(enemy.y), vis_radius, rl.Color{255, 0, 0, 30})

        // Draw enemy (16x16 ellipse placeholder)
        rl.DrawEllipse(i32(enemy.x), i32(enemy.y), 8, 8, rl.RED)

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
