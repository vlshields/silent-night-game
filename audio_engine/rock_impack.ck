
// Use a sawtooth oscillator for a bright, buzzy tone
SqrOsc osc => ADSR env => WvOut wav => dac;

// Set up the wav file output
"rock_impact.wav" => wav.wavFilename;
wav.record();

// Configure the envelope for a quick "zap"
env.set(1::ms, 50::ms, 0.0, 10::ms);

300.0 => float startFreq;
40.0 => float endFreq;


startFreq => osc.freq;


env.keyOn();


now => time start;
40::ms => dur sweepTime;

while (now - start < sweepTime) {
    (now - start) / sweepTime => float progress;
    
    startFreq + (endFreq - startFreq) * progress => osc.freq;
    
    1::ms => now;
}

env.keyOff();

10::ms => now;

// Close the wav file
wav.closeFile();