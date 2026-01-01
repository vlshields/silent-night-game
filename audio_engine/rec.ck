
dac => WvOut2 w => blackhole;


"chuck-session" => w.autoPrefix;

// this is the output file name
"background_music" => w.wavFilename;


// print it out
<<<"writing to file: ", w.filename()>>>;

// any gain you want for the output
.7 => w.fileGain;

// infinite time loop...
// ctrl-c will stop it, or modify to desired duration
while( true ) 1::second => now;