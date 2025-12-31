package main

import rl "vendor:raylib"

Animation :: struct {
    texture:     rl.Texture2D,
    frame_count: i32,
    frame_time:  f32,
}
