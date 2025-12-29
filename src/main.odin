package main

import rl "vendor:raylib"

main :: proc() {
    rl.InitWindow(1280, 720, "Silent Night")
    defer rl.CloseWindow()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.EndDrawing()
    }
}
