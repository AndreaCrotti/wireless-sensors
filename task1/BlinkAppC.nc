/**
 * @file   BlinkAppC.nc
 * @author andrea <andrea@64-176.eduroam.rwth-aachen.de>
 * @date   Wed Apr 28 13:14:44 2010
 * 
 * @brief  First task, node number 0 of the network select a random led
 * and broadcast it to the whole network.
 * The other nodes accept the command, make sure they only receive once
 * and set the led also.
 * 
 */

#include <Timer.h>
#include "Blink.h"

configuration BlinkAppC {

}

implementation {
  components MainC, BlinkC, LedsC;
  components new TimerMilliC() as Timer;
  components ActiveMessageC;
  components new AMSenderC(AM_BLINKTORADIO);
  components new AMReceiverC(AM_BLINKTORADIO);
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

  BlinkC.Random -> RandomC;
  /* BlinkC.ParameterInit<uint16_t> -> RandomC; */
}

