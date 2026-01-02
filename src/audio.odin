package main

import rl "vendor:raylib"
import "core:fmt"

FOOTSTEP_COUNT :: 5
FOOTSTEP_INTERVAL :: 0.25  // Time between footstep sounds

footsteps: [FOOTSTEP_COUNT]rl.Sound
footstep_timer: f32 = 0

jump_sound: rl.Sound
land_sound: rl.Sound
trap_sound: rl.Sound
moog_sound: rl.Sound
moog_pickup_sound: rl.Sound
rock_throw_sound: rl.Sound
rock_collision_sound: rl.Sound

bg_music: rl.Music

init_audio :: proc() {
    rl.InitAudioDevice()
    for i in 0..<FOOTSTEP_COUNT {
        path := fmt.ctprintf("audio_engine/footstep_%d.wav", i)
        footsteps[i] = rl.LoadSound(path)
    }
    jump_sound = rl.LoadSound("audio_engine/jump.wav")
    land_sound = rl.LoadSound("audio_engine/land.wav")
    trap_sound = rl.LoadSound("audio_engine/trap_sound.wav")
    moog_sound = rl.LoadSound("audio_engine/mighty_moog.wav")
    moog_pickup_sound = rl.LoadSound("audio_engine/moog_pickup.wav")
    rock_throw_sound = rl.LoadSound("audio_engine/player_throws_rock.wav")
    rock_collision_sound = rl.LoadSound("audio_engine/rock_enemy_colision.wav")

    bg_music = rl.LoadMusicStream("audio_engine/background_music.wav")
    bg_music.looping = true
    rl.PlayMusicStream(bg_music)
}

cleanup_audio :: proc() {
    for i in 0..<FOOTSTEP_COUNT {
        rl.UnloadSound(footsteps[i])
    }
    rl.UnloadSound(jump_sound)
    rl.UnloadSound(land_sound)
    rl.UnloadSound(trap_sound)
    rl.UnloadSound(moog_sound)
    rl.UnloadSound(moog_pickup_sound)
    rl.UnloadSound(rock_throw_sound)
    rl.UnloadSound(rock_collision_sound)
    rl.UnloadMusicStream(bg_music)
    rl.CloseAudioDevice()
}

update_music :: proc() {
    rl.UpdateMusicStream(bg_music)
}

update_footsteps :: proc(is_moving: bool, is_grounded: bool, dt: f32) {
    if is_moving && is_grounded {
        footstep_timer += dt
        if footstep_timer >= FOOTSTEP_INTERVAL {
            footstep_timer = 0
            play_footstep()
        }
    } else {
        footstep_timer = 0
    }
}

play_footstep :: proc() {
    idx := rl.GetRandomValue(0, FOOTSTEP_COUNT - 1)
    rl.PlaySound(footsteps[idx])
}

play_jump :: proc() {
    rl.PlaySound(jump_sound)
}

play_land :: proc() {
    rl.PlaySound(land_sound)
}

play_trap :: proc() {
    rl.PlaySound(trap_sound)
}

play_moog :: proc() {
    rl.PlaySound(moog_sound)
}

is_moog_playing :: proc() -> bool {
    return rl.IsSoundPlaying(moog_sound)
}

play_moog_pickup :: proc() {
    rl.PlaySound(moog_pickup_sound)
}

play_rock_throw :: proc() {
    rl.PlaySound(rock_throw_sound)
}

play_rock_collision :: proc() {
    rl.PlaySound(rock_collision_sound)
}
