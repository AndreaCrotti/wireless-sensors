#include <Timer.h>
#include "BlinkThread.h"

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

configuration BlinkThreadAppC {

}

implementation {
    components MainC, BlinkThreadC, LedsC;
    components new TimerMilliC() as Timer;
    components ActiveMessageC;
    components new AMSenderC(AM_BLINKTORADIO);
    components new AMReceiverC(AM_BLINKTORADIO);
    components RandomC;
    
    BlinkThreadC -> MainC.Boot;
    
    BlinkThreadC.Timer -> Timer;
    BlinkThreadC.Leds -> LedsC;

    /// Linking all our interfaces to the correct components
    BlinkThreadC.Packet -> AMSenderC;
    BlinkThreadC.AMPacket -> AMSenderC;
    BlinkThreadC.AMSend -> AMSenderC;
    BlinkThreadC.AMControl -> ActiveMessageC;
    BlinkThreadC.Receive -> AMReceiverC;
    
    /// Connect the Random component for the LED choice
    BlinkThreadC.Random -> RandomC;
    BlinkThreadC.SeedInit -> RandomC;
}

