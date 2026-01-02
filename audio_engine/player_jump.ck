Noise n => ResonZ f =>  JCRev j => Gain g => dac => WvOut wav => blackhole;
"jump.wav" => wav.wavFilename;
0.25 => j.mix;
0.75 => g.gain;

12 => f.Q;
2000 => f.freq;
.2::second => now;
wav.closeFile();
