package main

import rl "vendor:raylib"
import "core:math"

GAME_WIDTH  :: 640
GAME_HEIGHT :: 360

main :: proc() {
    rl.SetConfigFlags({.FULLSCREEN_MODE})
    rl.InitWindow(0, 0, "Silent Night")
    defer rl.CloseWindow()

    init_audio()
    defer cleanup_audio()

    screen_width := rl.GetScreenWidth()
    screen_height := rl.GetScreenHeight()

    target := rl.LoadRenderTexture(GAME_WIDTH, GAME_HEIGHT)
    defer rl.UnloadRenderTexture(target)

    scale := min(f32(screen_width) / GAME_WIDTH, f32(screen_height) / GAME_HEIGHT)

    // Load animations
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

    // Load textures
    rock_texture := rl.LoadTexture("assets/sprites/Item_Rock_Pickup.png")
    defer rl.UnloadTexture(rock_texture)

    trap_texture := rl.LoadTexture("assets/sprites/Trap_tile.png")
    defer rl.UnloadTexture(trap_texture)

    door_texture := rl.LoadTexture("assets/sprites/Level_door_exit.png")
    defer rl.UnloadTexture(door_texture)

    moon_texture := rl.LoadTexture("assets/sprites/Evil_moon_bg.png")
    defer rl.UnloadTexture(moon_texture)

    angry_planet_texture := rl.LoadTexture("assets/sprites/parallax_bg_angry_planet.png")
    defer rl.UnloadTexture(angry_planet_texture)

    // Parallax building textures
    building_static1_texture := rl.LoadTexture("assets/sprites/Parallax_bg_buildting_static.png")
    defer rl.UnloadTexture(building_static1_texture)

    building_static2_texture := rl.LoadTexture("assets/sprites/Paralax_building_static_bg2.png")
    defer rl.UnloadTexture(building_static2_texture)

    moog_texture := rl.LoadTexture("assets/sprites/mighty_moog.png")
    defer rl.UnloadTexture(moog_texture)

    // Ground tile textures
    ground_textures: [3]rl.Texture2D = {
        rl.LoadTexture("assets/sprites/ground_tile1.png"),
        rl.LoadTexture("assets/sprites/ground_tile2.png"),
        rl.LoadTexture("assets/sprites/ground_tile3.png"),
    }
    defer for tex in ground_textures {
        rl.UnloadTexture(tex)
    }

    // Load level
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

    // Game state
    noise_meter: f32 = 0
    game_over := false
    level_complete := false
    current_level := 1
    rock := Rock{}

    // Tutorial state
    tutorial_step := TutorialStep.Intro1
    tutorial_active := true
    arrow_timer: f32 = 0
    first_ladder_x: f32 = 0
    first_ladder_top: f32 = 999999
    item_pos := rl.Vector2{0, 0}
    trap_pos := rl.Vector2{0, 0}

    // Find tutorial positions
    for ladder in level.ladders {
        if first_ladder_x == 0 || ladder.x < first_ladder_x {
            first_ladder_x = ladder.x
            first_ladder_top = ladder.y
        }
    }
    for item in level.items {
        item_pos = {item.x + item.width / 2, item.y}
        break
    }
    for trap in level.traps {
        trap_pos = {trap.x + trap.width / 2, trap.y}
        break
    }

    // Camera setup
    camera := rl.Camera2D{
        target = {player.x, player.y},
        offset = {GAME_WIDTH / 2, GAME_HEIGHT / 2},
        rotation = 0,
        zoom = 1,
    }

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        arrow_timer += dt
        update_music()

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
            case .Level3Intro:
                tutorial_step = .Complete
                tutorial_active = false
            case .MoogPickup:
                tutorial_step = .Complete
                tutorial_active = false
            case .WaitForClimb, .WaitForTrapPass, .WaitForPickup, .Complete:
                // No action
            }
        }

        // Restart handling
        if game_over && rl.IsKeyPressed(.R) {
            noise_meter = 0
            player.x = level.player_spawn.x
            player.y = level.player_spawn.y
            player.vel_y = 0
            player.grounded = true
            player.state = .Idle
            player.has_rock = false
            player.has_instrument = false
            player.instrument_cooldown = 0
            rock = Rock{}
            for &enemy in level.enemies {
                enemy.x = enemy.start_x
                enemy.stun_timer = 0
                enemy.current_frame = 0
                enemy.frame_timer = 0
            }
            for &trap in level.traps {
                trap.triggered = false
            }
            for &item in level.items {
                item.collected = false
            }
            for &instrument in level.instruments {
                instrument.collected = false
            }
            game_over = false
        }

        // Level transition
        if level_complete {
            current_level += 1
            level_complete = false
            unload_level(&level)

            if current_level == 2 {
                level = load_level("assets/maps/level2.txt")
                tutorial_step = .Complete
                tutorial_active = false
            } else if current_level == 3 {
                level = load_level("assets/maps/level3.txt")
                tutorial_step = .Level3Intro
                tutorial_active = true
            } else {
                current_level = 1
                level = load_level("assets/maps/level1.txt")
            }

            player.x = level.player_spawn.x
            player.y = level.player_spawn.y
            player.vel_y = 0
            player.grounded = true
            player.state = .Idle
            player.has_rock = false
            player.has_instrument = false
            player.instrument_cooldown = 0
            rock = Rock{}
            noise_meter = 0

            first_ladder_x = 0
            first_ladder_top = 999999
            for ladder in level.ladders {
                if first_ladder_x == 0 || ladder.x < first_ladder_x {
                    first_ladder_x = ladder.x
                    first_ladder_top = ladder.y
                }
            }
            for item in level.items {
                item_pos = {item.x + item.width / 2, item.y}
                break
            }
            for trap in level.traps {
                trap_pos = {trap.x + trap.width / 2, trap.y}
                break
            }
        }

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

        // Game logic
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
                if climbing {
                    noise_meter += 8.0 * dt
                }
            }

            if rl.IsKeyPressed(.SPACE) && player.grounded && !on_ladder {
                player.vel_y = -JUMP_FORCE
                player.grounded = false
                noise_meter += 5
                play_jump()
            }

            was_airborne := !player.grounded

            if !player.grounded && !on_ladder {
                player.vel_y += GRAVITY * dt
                player.y += player.vel_y * dt
            } else if on_ladder && !climbing {
                player.vel_y = 0
            }

            // Ground collision
            for ground in level.grounds {
                ground_top := ground.y - 8
                if player.x >= ground.x && player.x <= ground.x + ground.width {
                    if player.y >= ground_top && player.y <= ground_top + 16 && player.vel_y >= 0 {
                        player.y = ground_top
                        player.vel_y = 0
                        if was_airborne && !on_ladder {
                            noise_meter += 15
                            play_land()
                        }
                        player.grounded = true
                    }
                }
            }

            // Trap collision (solid)
            for trap in level.traps {
                trap_top := trap.y - 8
                if player.x >= trap.x && player.x <= trap.x + trap.width {
                    if player.y >= trap_top && player.y <= trap_top + 16 && player.vel_y >= 0 {
                        player.y = trap_top
                        player.vel_y = 0
                        if was_airborne && !on_ladder {
                            noise_meter += 10
                            play_land()
                        }
                        player.grounded = true
                    }
                }
            }

            // Check still grounded
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
                    for trap in level.traps {
                        trap_top := trap.y - 8
                        if player.x >= trap.x && player.x <= trap.x + trap.width &&
                           player.y >= trap_top - 1 && player.y <= trap_top + 1 {
                            still_on_ground = true
                            break
                        }
                    }
                }
                if !still_on_ground {
                    player.grounded = false
                }
            }

            // Map boundary collision (invisible walls)
            half_frame := f32(FRAME_SIZE) / 2
            player.x = clamp(player.x, half_frame, level.width - half_frame)
            player.y = clamp(player.y, half_frame, level.height)

            // Trap trigger
            for &trap in level.traps {
                trap_top := trap.y - 8
                on_trap := player.x >= trap.x && player.x <= trap.x + trap.width &&
                           player.y >= trap_top && player.y <= trap_top + 8
                if on_trap && !trap.triggered {
                    trap.triggered = true
                    noise_meter += 40
                    play_trap()
                } else if !on_trap && trap.triggered {
                    trap.triggered = false
                }
            }

            // Item pickup
            for &item in level.items {
                if !item.collected && !player.has_rock {
                    if player.x >= item.x && player.x <= item.x + item.width &&
                       player.y >= item.y && player.y <= item.y + item.height {
                        item.collected = true
                        player.has_rock = true
                        if tutorial_step == .WaitForPickup {
                            tutorial_step = .ThrowInfo
                            tutorial_active = true
                        }
                    }
                }
            }

            // Instrument pickup
            for &instrument in level.instruments {
                if !instrument.collected && !player.has_instrument {
                    if player.x >= instrument.x && player.x <= instrument.x + instrument.width &&
                       player.y >= instrument.y && player.y <= instrument.y + instrument.height {
                        instrument.collected = true
                        player.has_instrument = true
                        tutorial_step = .MoogPickup
                        tutorial_active = true
                    }
                }
            }

            // Door collision
            for door in level.doors {
                if player.x >= door.x && player.x <= door.x + door.width &&
                   player.y >= door.y && player.y <= door.y + door.height + 8 {
                    level_complete = true
                    break
                }
            }

            // Rock throwing
            if player.has_rock && !rock.active && rl.IsMouseButtonPressed(.LEFT) {
                rock.active = true
                rock.x = player.x
                rock.y = player.y
                rock.start_x = player.x
                rock.vel_x = 160.0 if !player.facing_left else -160.0
                rock.vel_y = 0
                player.has_rock = false
                noise_meter += 5
            }

            // Instrument use
            if player.has_instrument && player.instrument_cooldown <= 0 && rl.IsKeyPressed(.E) {
                for &enemy in level.enemies {
                    enemy.stun_timer = INSTRUMENT_STUN
                    enemy.current_frame = 0
                    enemy.frame_timer = 0
                }
                player.instrument_cooldown = INSTRUMENT_COOLDOWN
            }

            // Update instrument cooldown
            if player.instrument_cooldown > 0 {
                player.instrument_cooldown -= dt
            }

            // Update rock
            if rock.active {
                rock.x += rock.vel_x * dt

                if abs(rock.x - rock.start_x) >= 120.0 {
                    rock.vel_x = 0
                    rock.vel_y += GRAVITY * 0.5 * dt
                    rock.y += rock.vel_y * dt
                }

                hit_enemy := false
                for &enemy in level.enemies {
                    dx := rock.x - enemy.x
                    dy := rock.y - enemy.y
                    distance := rl.Vector2Length(rl.Vector2{dx, dy})
                    if distance <= 10.0 {
                        enemy.stun_timer = 5.0
                        enemy.current_frame = 0
                        enemy.frame_timer = 0
                        rock.active = false
                        hit_enemy = true
                        break
                    }
                }

                if !hit_enemy {
                    for ground in level.grounds {
                        if rock.x >= ground.x && rock.x <= ground.x + ground.width &&
                           rock.y >= ground.y && rock.y <= ground.y + ground.height {
                            rock.active = false
                            noise_meter += 60
                            break
                        }
                    }
                }

                if rock.y > level.height + 50 {
                    rock.active = false
                    noise_meter += 60
                }
            }

            // Update player state
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

            if player.state != prev_state {
                player.current_frame = 0
                player.frame_timer = 0
            }

            // Update noise meter
            if moving {
                noise_meter += 4.0 * dt
            } else {
                noise_meter -= 3.0 * dt
            }
            noise_meter = clamp(noise_meter, 0, 100)

            // Update footstep sounds
            update_footsteps(moving, player.grounded, dt)

            if noise_meter >= 100 {
                game_over = true
            }

            // Enemy update
            visibility_radius := 20.0 + noise_meter
            for &enemy in level.enemies {
                enemy.frame_timer += dt
                enemy_anim := &enemy_stunned_anim if enemy.stun_timer > 0 else &enemy_move_anim
                if enemy.frame_timer >= enemy_anim.frame_time {
                    enemy.frame_timer = 0
                    enemy.current_frame = (enemy.current_frame + 1) % enemy_anim.frame_count
                }

                if enemy.stun_timer > 0 {
                    enemy.stun_timer -= dt
                    if enemy.stun_timer <= 0 {
                        enemy.current_frame = 0
                        enemy.frame_timer = 0
                    } else {
                        continue
                    }
                }

                enemy.x += enemy.direction * ENEMY_SPEED * dt
                if enemy.x <= enemy.start_x - ENEMY_PATROL_RANGE {
                    enemy.direction = 1
                } else if enemy.x >= enemy.start_x + ENEMY_PATROL_RANGE {
                    enemy.direction = -1
                }

                dx := player.x - enemy.x
                dy := player.y - enemy.y
                distance := rl.Vector2Length(rl.Vector2{dx, dy})
                if distance <= visibility_radius {
                    game_over = true
                }
            }

            // Tutorial triggers
            if tutorial_step == .WaitForClimb && player.y < first_ladder_top + 16 {
                tutorial_step = .ArrowTrap
                tutorial_active = true
            }

            if tutorial_step == .WaitForTrapPass && player.x > trap_pos.x + TILE_SIZE && player.grounded {
                tutorial_step = .ArrowItem
                tutorial_active = true
            }
        }

        // Animation update
        current_anim: ^Animation
        switch player.state {
        case .Idle:
            current_anim = &idle_anim
        case .Moving:
            current_anim = &move_anim
        case .Jumping:
            current_anim = &jump_anim
        case .Climbing:
            current_anim = &idle_anim
        }

        if !game_over {
            player.frame_timer += dt
            if player.frame_timer >= current_anim.frame_time {
                player.frame_timer = 0
                player.current_frame = (player.current_frame + 1) % current_anim.frame_count
            }
        }

        // Update camera
        camera.target.x = clamp(player.x, camera.offset.x, level.width - camera.offset.x)
        camera.target.y = clamp(player.y, camera.offset.y, level.height - camera.offset.y)

        // Drawing
        rl.BeginTextureMode(target)
        rl.ClearBackground(rl.BLACK)
        rl.BeginMode2D(camera)

        // Parallax background
        MOON_PARALLAX :: 0.65

        level_center_x := level.width / 2
        level_center_y := level.height / 2
        camera_offset_x := camera.target.x - level_center_x
        camera_offset_y := camera.target.y - level_center_y

        for moon in level.moon_tiles {
            parallax_x := moon.x - camera_offset_x * (1 - MOON_PARALLAX)
            parallax_y := moon.y - camera_offset_y * (1 - MOON_PARALLAX)

            moon_source := rl.Rectangle{
                x      = f32(moon.grid_x * TILE_SIZE),
                y      = f32(moon.grid_y * TILE_SIZE),
                width  = TILE_SIZE,
                height = TILE_SIZE,
            }
            moon_dest := rl.Rectangle{
                x      = parallax_x,
                y      = parallax_y,
                width  = TILE_SIZE,
                height = TILE_SIZE,
            }
            rl.DrawTexturePro(moon_texture, moon_source, moon_dest, rl.Vector2{0, 0}, 0, rl.WHITE)
        }

        // Draw angry planet (same parallax as moon)
        for planet in level.angry_planet_tiles {
            parallax_x := planet.x - camera_offset_x * (1 - MOON_PARALLAX)
            parallax_y := planet.y - camera_offset_y * (1 - MOON_PARALLAX)

            planet_source := rl.Rectangle{
                x      = f32(planet.grid_x * TILE_SIZE),
                y      = f32(planet.grid_y * TILE_SIZE),
                width  = TILE_SIZE,
                height = TILE_SIZE,
            }
            planet_dest := rl.Rectangle{
                x      = parallax_x,
                y      = parallax_y,
                width  = TILE_SIZE,
                height = TILE_SIZE,
            }
            rl.DrawTexturePro(angry_planet_texture, planet_source, planet_dest, rl.Vector2{0, 0}, 0, rl.WHITE)
        }

        
        // Draw grounds
        for tile in level.ground_tiles {
            rl.DrawTexture(ground_textures[tile.variant], i32(tile.x), i32(tile.y), rl.WHITE)
        }

        // Draw ladders
        for ladder in level.ladders {
            rl.DrawRectangle(i32(ladder.x), i32(ladder.y), i32(ladder.width), i32(ladder.height), rl.BROWN)
            rung_count := i32(ladder.height / TILE_SIZE) + 1
            for i in 0..<rung_count {
                rung_y := i32(ladder.y) + i32(f32(i) * ladder.height / f32(rung_count)) + 6
                rl.DrawRectangle(i32(ladder.x) + 2, rung_y, i32(ladder.width) - 4, 2, rl.DARKBROWN)
            }
        }

        // Draw doors
        for door in level.doors {
            rl.DrawTexture(door_texture, i32(door.x), i32(door.y), rl.WHITE)
        }

        // Draw traps
        for trap in level.traps {
            rl.DrawTexture(trap_texture, i32(trap.x), i32(trap.y), rl.WHITE)
        }

        // Draw items
        for item in level.items {
            if !item.collected {
                rl.DrawTexture(rock_texture, i32(item.x), i32(item.y), rl.WHITE)
            }
        }

        // Draw instruments (Mighty Moog)
        for instrument in level.instruments {
            if !instrument.collected {
                rl.DrawTexture(moog_texture, i32(instrument.x), i32(instrument.y), rl.WHITE)
            }
        }

        // Draw player
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

        rl.DrawTexturePro(current_anim.texture, source_rect, dest_rect, rl.Vector2{0, 0}, 0, rl.WHITE)

        // Draw enemies
        vis_radius := 20.0 + noise_meter
        for enemy in level.enemies {
            is_stunned := enemy.stun_timer > 0
            if !is_stunned {
                rl.DrawCircleLines(i32(enemy.x), i32(enemy.y), vis_radius, rl.Color{255, 100, 100, 150})
                rl.DrawCircle(i32(enemy.x), i32(enemy.y), vis_radius, rl.Color{255, 0, 0, 30})
            }

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

            rl.DrawTexturePro(enemy_anim.texture, enemy_source_rect, enemy_dest_rect, rl.Vector2{0, 0}, 0, rl.WHITE)
        }

        // Draw rock projectile
        if rock.active {
            rock_source := rl.Rectangle{0, 0, 16, 16}
            rock_dest := rl.Rectangle{rock.x - 4, rock.y - 4, 8, 8}
            rl.DrawTexturePro(rock_texture, rock_source, rock_dest, rl.Vector2{0, 0}, 0, rl.WHITE)
        }

        rl.EndMode2D()

        // Draw UI
        METER_X      :: 10
        METER_Y      :: 10
        METER_WIDTH  :: 100
        METER_HEIGHT :: 12

        rl.DrawRectangle(METER_X, METER_Y, METER_WIDTH, METER_HEIGHT, rl.DARKGRAY)
        filled_width := i32(noise_meter)
        rl.DrawRectangle(METER_X, METER_Y, filled_width, METER_HEIGHT, rl.RED)
        rl.DrawRectangleLines(METER_X, METER_Y, METER_WIDTH, METER_HEIGHT, rl.WHITE)
        rl.DrawText("NOISE", METER_X, METER_Y + METER_HEIGHT + 2, 10, rl.WHITE)

        for enemy in level.enemies {
            if enemy.stun_timer > 0 {
                stun_text := rl.TextFormat("Guard Stunned %.0fs", enemy.stun_timer)
                rl.DrawText(stun_text, METER_X + METER_WIDTH + 10, METER_Y, 10, rl.SKYBLUE)
                break
            }
        }

        if player.has_rock {
            rl.DrawCircle(130, 16, 6, rl.Color{139, 119, 101, 255})
            rl.DrawText("LMB", 140, 10, 10, rl.WHITE)
        }

        if player.has_instrument {
            inst_x: i32 = 170
            rl.DrawRectangle(inst_x, 10, 12, 12, rl.GOLD)
            if player.instrument_cooldown > 0 {
                cooldown_text := rl.TextFormat("%.0fs", player.instrument_cooldown)
                rl.DrawText(cooldown_text, inst_x + 16, 10, 10, rl.GRAY)
            } else {
                rl.DrawText("[E]", inst_x + 16, 10, 10, rl.WHITE)
            }
        }

        // Goal text for level 1
        if current_level == 1 {
            goal_text : cstring = "Goal: Locate the exit!"
            text_width := rl.MeasureText(goal_text, 12)
            rl.DrawText(goal_text, (GAME_WIDTH - text_width) / 2, 8, 12, rl.YELLOW)
        }

        // Tutorial overlay
        if tutorial_step != .Complete {
            // Flashing arrows
            if tutorial_step == .ArrowLadder || tutorial_step == .WaitForClimb {
                arrow_world_x := first_ladder_x + TILE_SIZE / 2
                arrow_world_y := first_ladder_top - 20
                arrow_screen_x := arrow_world_x - camera.target.x + camera.offset.x
                arrow_screen_y := arrow_world_y - camera.target.y + camera.offset.y

                alpha := u8(150 + 100 * math.sin(arrow_timer * 5.0))
                arrow_color := rl.Color{255, 255, 0, alpha}

                rl.DrawTriangle(
                    rl.Vector2{arrow_screen_x, arrow_screen_y + 15},
                    rl.Vector2{arrow_screen_x + 8, arrow_screen_y},
                    rl.Vector2{arrow_screen_x - 8, arrow_screen_y},
                    arrow_color,
                )
            }

            if tutorial_step == .ArrowTrap || tutorial_step == .WaitForTrapPass {
                arrow_world_x := trap_pos.x
                arrow_world_y := trap_pos.y - 20
                arrow_screen_x := arrow_world_x - camera.target.x + camera.offset.x
                arrow_screen_y := arrow_world_y - camera.target.y + camera.offset.y

                alpha := u8(150 + 100 * math.sin(arrow_timer * 5.0))
                arrow_color := rl.Color{255, 255, 0, alpha}

                rl.DrawTriangle(
                    rl.Vector2{arrow_screen_x, arrow_screen_y + 15},
                    rl.Vector2{arrow_screen_x + 8, arrow_screen_y},
                    rl.Vector2{arrow_screen_x - 8, arrow_screen_y},
                    arrow_color,
                )
            }

            if tutorial_step == .ArrowItem || tutorial_step == .RockInfo2 || tutorial_step == .WaitForPickup {
                arrow_world_x := item_pos.x
                arrow_world_y := item_pos.y - 20
                arrow_screen_x := arrow_world_x - camera.target.x + camera.offset.x
                arrow_screen_y := arrow_world_y - camera.target.y + camera.offset.y

                alpha := u8(150 + 100 * math.sin(arrow_timer * 5.0))
                arrow_color := rl.Color{255, 255, 0, alpha}

                rl.DrawTriangle(
                    rl.Vector2{arrow_screen_x, arrow_screen_y + 15},
                    rl.Vector2{arrow_screen_x + 8, arrow_screen_y},
                    rl.Vector2{arrow_screen_x - 8, arrow_screen_y},
                    arrow_color,
                )
            }

            // Dialogue box
            if tutorial_active {
                rl.DrawRectangle(40, 220, 560, 120, rl.Color{0, 0, 0, 200})
                rl.DrawRectangleLines(40, 220, 560, 120, rl.WHITE)

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
                case .Level3Intro:
                    dialogue_text = TUTORIAL_LEVEL3
                case .MoogPickup:
                    dialogue_text = TUTORIAL_MOOG_PICKUP
                case .WaitForClimb, .WaitForTrapPass, .WaitForPickup, .Complete:
                    // No dialogue
                }

                rl.DrawText(dialogue_text, 55, 235, 15, rl.WHITE)

                prompt_alpha := u8(150 + 100 * math.sin(arrow_timer * 3.0))
                rl.DrawText("Press Enter", 270, 315, 15, rl.Color{255, 255, 255, prompt_alpha})
            }
        }

        // Game over screen
        if game_over {
            rl.DrawRectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, rl.Color{0, 0, 0, 180})
            rl.DrawText("GAME OVER", 220, 150, 40, rl.RED)
            rl.DrawText("Press R to restart", 240, 200, 20, rl.WHITE)
        }

        rl.EndTextureMode()

        // Draw scaled to screen
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.DrawTexturePro(
            target.texture,
            rl.Rectangle{0, 0, GAME_WIDTH, -GAME_HEIGHT},
            rl.Rectangle{
                (f32(screen_width) - GAME_WIDTH * scale) * 0.5,
                (f32(screen_height) - GAME_HEIGHT * scale) * 0.5,
                GAME_WIDTH * scale,
                GAME_HEIGHT * scale,
            },
            rl.Vector2{0, 0},
            0,
            rl.WHITE,
        )

        rl.EndDrawing()
    }
}
