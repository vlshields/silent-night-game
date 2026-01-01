Shakers s => Pan2 pan => Chorus c1 => JCRev rev => Chorus c2 => Chorus c3 =>dac;

0 => s.which;
.6 => s.gain;
1 => float theTime;

while( true )
{
    Math.random2f( -1,1) => pan.pan;

    1.0 => s.noteOn;
    theTime::second => now;

    1.0 => s.noteOff;
    theTime::second => now;   

    ( s.which() + 1 ) % 20 => s.which;
    Math.random2f( 2, 4 ) => theTime;
}
