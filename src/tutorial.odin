package main

TutorialStep :: enum {
    Intro1,
    Intro2,
    Intro3,
    Intro4,
    ArrowLadder,
    WaitForClimb,
    ArrowTrap,
    WaitForTrapPass,
    ArrowItem,
    RockInfo2,
    WaitForPickup,
    ThrowInfo,
    Level3Intro,
    Complete,
}

TUTORIAL_INTRO1 :: "Shhhh, be quiet! Each step you take with A or D will\nincrease your Noise meter. So will jumping (Spacebar)\nand landing on the ground."

TUTORIAL_INTRO2 :: "If your Noise meter becomes full, you will be captured!\nIf any patrolling guard sees or hears you, you will be\ncaptured. Stay out of their sensory region shown in red!"

TUTORIAL_INTRO3 :: "The guards' sensory regions will grow as your\nNoise meter grows too."

TUTORIAL_INTRO4 :: "Standing still will deplete your noise meter and\nthe guards' sensory region. Be patient!"

TUTORIAL_LADDER :: "Head up this ladder with W.\nBut be careful, climbing makes noise too!"

TUTORIAL_TRAP :: "Be careful of trash or objects on the ground,\nthey can make a lot of noise and get you caught!"

TUTORIAL_ROCK1 :: "If you find a rock, you can pick it up and throw it.\nIf it hits a guard, they will be stunned for 5 seconds."

TUTORIAL_ROCK2 :: "But if you miss, you will make a lot of noise!\nMake sure you are close enough to hit the guard!"

TUTORIAL_THROW :: "Left click in the direction of the guard\nto throw the rock at them."

TUTORIAL_LEVEL3 :: "The legendary Moog is close by, you must find it!"
