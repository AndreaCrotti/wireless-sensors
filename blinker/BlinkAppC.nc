#include <Timer.h>
#include "Blink.h"

/**
 * Configuration for the first task.
 * Node number 0 of the network select a random led
 * and broadcast it to the whole network.
 * The other nodes accept the command, make sure they only receive once
 * and set the led also.
 * 
 * @file   BlinkAppC.nc
 * @author Andrea Crotti and Marius Grysla
 * @date   So 2. Mai 21:11:02 CEST 2010
 * 
 */

configuration BlinkAppC {

}

implementation {
    components MainC, BlinkC, LedsC;
    components new TimerMilliC() as Timer;
    components ActiveMessageC;
    components new AMSenderC(AM_BLINK);
    components new AMReceiverC(AM_BLINK);
    components RandomC;
    
    BlinkC -> MainC.Boot;
    
    BlinkC.Timer -> Timer;
    BlinkC.Leds -> LedsC;

    /// Linking all our interfaces to the correct components
    BlinkC.Packet -> AMSenderC;
    BlinkC.AMPacket -> AMSenderC;
    BlinkC.AMSend -> AMSenderC;
    BlinkC.AMControl -> ActiveMessageC;
    BlinkC.Receive -> AMReceiverC;
    
    /// Connect the Random component for the LED choice
    BlinkC.Random -> RandomC;
    BlinkC.SeedInit -> RandomC;
}

