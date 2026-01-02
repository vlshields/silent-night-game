package main

import rl "vendor:raylib"
import "core:math"

// Pause menu state
PauseMenu :: struct {
    is_paused:      bool,
    selected_index: int,
    blink_timer:    f32,
}

PAUSE_MENU_OPTIONS :: 4  // Resume, Toggle Tutorial, Select Level, Quit
MAX_LEVELS :: 3

// Initialize pause menu
init_pause_menu :: proc() -> PauseMenu {
    return PauseMenu{
        is_paused      = false,
        selected_index = 0,
        blink_timer    = 0,
    }
}

// Update pause menu - returns level to load (0 = no change, -1 = quit)
update_pause_menu :: proc(menu: ^PauseMenu, tutorial_enabled: ^bool, dt: f32) -> int {
    menu.blink_timer += dt

    // Navigation
    if rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP) {
        menu.selected_index -= 1
        if menu.selected_index < 0 {
            menu.selected_index = PAUSE_MENU_OPTIONS - 1
        }
    }
    if rl.IsKeyPressed(.S) || rl.IsKeyPressed(.DOWN) {
        menu.selected_index += 1
        if menu.selected_index >= PAUSE_MENU_OPTIONS {
            menu.selected_index = 0
        }
    }

    // Selection
    if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
        switch menu.selected_index {
        case 0:  // Resume
            menu.is_paused = false
            menu.selected_index = 0
            return 0
        case 1:  // Toggle Tutorial
            tutorial_enabled^ = !tutorial_enabled^
            return 0
        case 2:  // Select Level (cycles through levels 1-3)
            // This case is handled separately with A/D keys
            return 0
        case 3:  // Quit
            return -1
        }
    }

    return 0
}

// Get selected level from pause menu (use A/D to change)
get_pause_level_selection :: proc(current_level: int) -> int {
    new_level := current_level

    if rl.IsKeyPressed(.A) || rl.IsKeyPressed(.LEFT) {
        new_level -= 1
        if new_level < 1 {
            new_level = MAX_LEVELS
        }
    }
    if rl.IsKeyPressed(.D) || rl.IsKeyPressed(.RIGHT) {
        new_level += 1
        if new_level > MAX_LEVELS {
            new_level = 1
        }
    }

    return new_level
}

// Draw pause menu
draw_pause_menu :: proc(menu: ^PauseMenu, tutorial_enabled: bool, selected_level: int, font: rl.Font) {
    // Darken background
    rl.DrawRectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, rl.Color{0, 0, 0, 180})

    // Title
    title: cstring = "PAUSED"
    title_size := rl.MeasureTextEx(font, title, 20, 1)
    rl.DrawTextEx(font, title, {(GAME_WIDTH - title_size.x) / 2, 60}, 20, 1, rl.WHITE)

    // Menu options
    menu_y_start: f32 = 130
    menu_spacing: f32 = 35

    options: [PAUSE_MENU_OPTIONS]cstring = {
        "Resume",
        tutorial_enabled ? "Tutorial: ON" : "Tutorial: OFF",
        rl.TextFormat("Level: < %d >", i32(selected_level)),
        "Quit",
    }

    for i in 0..<PAUSE_MENU_OPTIONS {
        y := menu_y_start + f32(i) * menu_spacing
        text := options[i]
        text_size := rl.MeasureTextEx(font, text, 20, 1)
        x := (GAME_WIDTH - text_size.x) / 2

        if i == menu.selected_index {
            // Selected item - draw with highlight and blinking
            alpha := u8(180 + 75 * math.sin(menu.blink_timer * 5.0))
            rl.DrawRectangle(i32(x - 10), i32(y - 5), i32(text_size.x + 20), 30, rl.Color{255, 255, 255, 50})
            rl.DrawTextEx(font, text, {x, y}, 20, 1, rl.Color{255, 255, 0, alpha})

            // Draw arrows for level selection
            if i == 2 {
                arrow_alpha := u8(150 + 100 * math.sin(menu.blink_timer * 4.0))
                rl.DrawTextEx(font, "<", {x - 25, y}, 20, 1, rl.Color{255, 255, 0, arrow_alpha})
                rl.DrawTextEx(font, ">", {x + text_size.x + 10, y}, 20, 1, rl.Color{255, 255, 0, arrow_alpha})
            }
        } else {
            rl.DrawTextEx(font, text, {x, y}, 20, 1, rl.GRAY)
        }
    }

    // Controls hint
    hint: cstring = "W/S: Navigate   Enter: Select   A/D: Change Level"
    hint_size := rl.MeasureTextEx(font, hint, 20, 1)
    rl.DrawTextEx(font, hint, {(GAME_WIDTH - hint_size.x) / 2, GAME_HEIGHT - 40}, 20, 1, rl.Color{150, 150, 150, 255})
}

// Draw pause hint in upper right corner
draw_pause_hint :: proc(font: rl.Font) {
    hint: cstring = "[P] to pause"
    hint_size := rl.MeasureTextEx(font, hint, 20, 1)
    x := GAME_WIDTH - hint_size.x - 10
    rl.DrawTextEx(font, hint, {x, 10}, 20, 1, rl.Color{200, 200, 200, 180})
}
