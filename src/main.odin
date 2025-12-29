package main

import rl "vendor:raylib"

Ground :: struct {
    x, y:          f32,
    width, height: f32,
}

Player :: struct {
    x, y:           f32,
    vel_y:          f32,
    grounded:       bool,
}

PLAYER_SPEED  :: 200.0
JUMP_FORCE    :: 400.0
GRAVITY       :: 800.0

main :: proc() {
    rl.InitWindow(1280, 720, "Silent Night")
    defer rl.CloseWindow()

    ground := Ground{
        x      = 0,
        y      = 650,
        width  = 1280,
        height = 70,
    }

    player := Player{
        x        = 640,
        y        = 642,
        vel_y    = 0,
        grounded = true,
    }

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        // Horizontal movement
        if rl.IsKeyDown(.A) {
            player.x -= PLAYER_SPEED * dt
        }
        if rl.IsKeyDown(.D) {
            player.x += PLAYER_SPEED * dt
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
        ground_top := ground.y - 8  // player radius
        if player.y >= ground_top {
            player.y = ground_top
            player.vel_y = 0
            player.grounded = true
        }

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

        // Draw player placeholder (16x16 ellipse)
        rl.DrawEllipse(
            i32(player.x),
            i32(player.y),
            8,  // radius x (16/2)
            8,  // radius y (16/2)
            rl.WHITE,
        )

        rl.EndDrawing()
    }
}
