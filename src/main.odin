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
    rl.InitWindow(1280, 720, "Silent Night")
    defer rl.CloseWindow()

    // Load sprite sheets
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
        y      = 650,
        width  = 1280,
        height = 70,
    }

    player := Player{
        x             = 640,
        y             = 642,
        vel_y         = 0,
        grounded      = true,
        state         = .Idle,
        facing_left   = false,
        current_frame = 0,
        frame_timer   = 0,
    }

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        // Track if moving this frame
        moving := false

        // Horizontal movement
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

        // Jumping
        if rl.IsKeyPressed(.SPACE) && player.grounded {
            player.vel_y = -JUMP_FORCE
            player.grounded = false
        }

        // Apply gravity
        if !player.grounded {
            player.vel_y += GRAVITY * dt
            player.y += player.vel_y * dt
        }

        // Ground collision
        ground_top := ground.y - 8  // half sprite height
        if player.y >= ground_top {
            player.y = ground_top
            player.vel_y = 0
            player.grounded = true
        }

        // Determine player state
        prev_state := player.state
        if !player.grounded {
            player.state = .Jumping
        } else if moving {
            player.state = .Moving
        } else {
            player.state = .Idle
        }

        // Reset animation if state changed
        if player.state != prev_state {
            player.current_frame = 0
            player.frame_timer = 0
        }

        // Get current animation
        current_anim: ^Animation
        switch player.state {
        case .Idle:
            current_anim = &idle_anim
        case .Moving:
            current_anim = &move_anim
        case .Jumping:
            current_anim = &jump_anim
        }

        // Update animation frame
        player.frame_timer += dt
        if player.frame_timer >= current_anim.frame_time {
            player.frame_timer = 0
            player.current_frame = (player.current_frame + 1) % current_anim.frame_count
        }

        // Drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        // Draw ground
        rl.DrawRectangle(
            i32(ground.x),
            i32(ground.y),
            i32(ground.width),
            i32(ground.height),
            rl.GRAY,
        )

        // Draw player sprite
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

        rl.EndDrawing()
    }
}
