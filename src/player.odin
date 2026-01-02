package main

PlayerState :: enum {
    Idle,
    Moving,
    Jumping,
    Climbing,
}

Player :: struct {
    x, y:                 f32,
    vel_y:                f32,
    grounded:             bool,
    state:                PlayerState,
    facing_left:          bool,
    current_frame:        i32,
    frame_timer:          f32,
    has_rock:             bool,
    has_instrument:       bool,
    instrument_cooldown:  f32,
    playing_moog:         bool,
}

Rock :: struct {
    x, y:       f32,
    vel_x:      f32,
    vel_y:      f32,
    active:     bool,
    start_x:    f32,
}

PLAYER_SPEED        :: 100.0
JUMP_FORCE          :: 300.0
GRAVITY             :: 800.0
FRAME_SIZE          :: 16
INSTRUMENT_STUN     :: 3.0
INSTRUMENT_COOLDOWN :: 14.0
