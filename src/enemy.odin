package main

Enemy :: struct {
    x, y:          f32,
    start_x:       f32,
    direction:     f32,
    stun_timer:    f32,
    current_frame: i32,
    frame_timer:   f32,
}

ENEMY_SPEED        :: 30.0
ENEMY_PATROL_RANGE :: 30.0
