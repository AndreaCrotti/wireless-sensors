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
    components SerialActiveMessageC;
    components new AMSenderC(AM_BLINK) as BlinkSender;
    components new AMReceiverC(AM_BLINK) as BlinkReceiver;
    //components new SerialAMSenderC(AM_SERIAL_BLINK) as SerialBlinkSender;
    components new SerialAMReceiverC(AM_SERIAL_BLINK) as SerialBlinkReceiver;
    components RandomC;
    
    BlinkC -> MainC.Boot;
    
    BlinkC.Timer -> Timer;
    BlinkC.Leds -> LedsC;

    /// Linking all our interfaces to the correct components
    BlinkC.Packet -> BlinkSender.Packet;
    BlinkC.AMPacket -> BlinkSender.AMPacket;
    BlinkC.AMSend -> BlinkSender.AMSend;
    BlinkC.AMControl -> ActiveMessageC;
    BlinkC.Receive -> BlinkReceiver;

    /// serial communication
    //BlinkC.SerialPacket -> SerialBlinkSender;
    //BlinkC.SerialAMPacket -> SerialBlinkSender;
    //BlinkC.SerialAMSend -> SerialBlinkSender;
    BlinkC.SerialControl -> SerialActiveMessageC;
    BlinkC.SerialReceive -> SerialBlinkReceiver;

    
    /// Connect the Random component for the LED choice
    BlinkC.Random -> RandomC;
    BlinkC.SeedInit -> RandomC;
}

