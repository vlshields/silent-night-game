TriOsc tri => LPF lpf => ADSR env => JCRev mix => Gain g => dac => WvOut wav => blackhole;
Noise n => ResonZ f => ADSR e => mix;
0.25 => mix.mix;
"land.wav" => wav.wavFilename;

// Triosc thud
100 => lpf.freq;
15 => lpf.Q;
180 => tri.freq;
0.65 => g.gain;
env.set(0.1::ms, 40::ms, 0.0, 20::ms);

// Gravel/sand noise click
e.set( 1::ms, 8::ms, 0.0, 50::ms );
18 => f.Q;
6000 => f.freq;
.9 => e.gain;

env.keyOn();
e.keyOn();
.2::second => now;







wav.closeFile();
