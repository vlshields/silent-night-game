.43::second => dur T;
T - (now % T) => now;
Moog moog => dac;

// scale
[36, 38, 39, 41, 43, 45, 46, 48] @=> int notes[];
[0, 0, 3, 5, 0, 7, 3, 2] @=> int pattern[];

// Sync LFO to tempo (cycles per beat)
1.0 / (T/second) => float tempoHz;

// Moog settings
0.82 => moog.filterQ;
0.92 => moog.filterSweepRate;
tempoHz * 10 => moog.lfoSpeed;
1 => moog.lfoDepth;
1 => moog.volume;
400 => moog.vibratoFreq;
0.03 => moog.vibratoGain;
// start the note once
.9 => moog.noteOn;

// infinite time loop
0 => int step;
while( true )
{
    Math.random2f(0.5,0.7) => moog.noteOn;
    // just change freq - no retriggering
    Std.mtof(notes[pattern[step]] + 24) => moog.freq;

    // advance time
    1::T => now;

    // next step
    (step + 1) % pattern.cap() => step;
}
