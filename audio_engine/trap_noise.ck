Shakers quarters => Gain g => NRev rev => dac => WvOut wav => blackhole;
Shakers dimes => g;
"trap_sound.wav" => wav.wavFilename;
0.05 => rev.mix;
0.9 => g.gain;

17 => quarters.preset;  // Quarter
16 => dimes.preset;     // Dime

repeat (9) {
    Math.random2f(0.3, 0.8) => float e;
    e => quarters.energy;
    e * 0.7 => dimes.energy;
    
    1 => quarters.noteOn;
    1 => dimes.noteOn;
    
    Math.random2f(0.05, 0.13)::second => now;
}

wav.closeFile();