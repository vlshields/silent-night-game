
Noise n => BPF bpf => ADSR env => JCRev j => Gain g => dac => WvOut wav => blackhole;
0.25 => j.mix;
0.15 => g.gain;
8 => bpf.Q;
for (0 => int i; i < 5; i++) {
    
    
    "footstep_" + i + ".wav" => wav.wavFilename;
    
    1000 + Math.random2f(-300, 300) => bpf.freq;

    env.set(0.5::ms, 15::ms, 0.0, 10::ms);
    
    env.keyOn();
    50::ms => now;
    
    wav.closeFile();
}