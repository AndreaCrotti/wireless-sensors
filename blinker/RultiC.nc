/**
 * Implementation of the reliable one-hop multicast primitive.
 * We will transmit a message repeatedly until we receive an acknowledgement from ALL recipients.
 * 
 * @file RultiC.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date Su 16. Mai 17:14:53 CEST 2010
 **/

#include "Blink.h"

configuration RultiC @safe() {
    provides interface AMSend;
    provides interface Receive;
    provides interface Packet;
    provides interface AMPacket;
}
implementation {
    components RultiP;
    
    components new AMSenderC(AM_RULTI_RTX) as RultiRtxSender;
    components new AMReceiverC(AM_RULTI_RTX) as RultiRtxReceiver;

    components new AMSenderC(AM_RULTI_ACK) as RultiAckSender;
    components new AMReceiverC(AM_RULTI_ACK) as RultiAckReceiver;
    // Using the SendQueue for Acknowledgements
    components new SendQueueC(6, sizeof(RultiMsg)) as AckQueue;
    
    components new TimerMilliC() as RultiRtxTimer;
    components new TimerMilliC() as RultiAckTimer;

    components RandomC as RultiRandom;

    components LedsC;

    RultiP.Packet -> RultiRtxSender.Packet;
    RultiP.AMPacket -> RultiRtxSender.AMPacket;
    RultiP.PayloadSend -> RultiRtxSender.AMSend;
    RultiP.PayloadReceive -> RultiRtxReceiver.Receive;
    // Queue wiring 
    RultiP.AckSend -> AckQueue.AMSend;
    AckQueue.LowSend ->  RultiAckSender.AMSend;
    AckQueue.AMPacket -> RultiAckSender.AMPacket;
    RultiP.AckReceive -> RultiAckReceiver.Receive;
    RultiP.RtxTimer -> RultiRtxTimer;
    RultiP.AckTimer -> RultiAckTimer;
    RultiP.Random -> RultiRandom;
    RultiP.SeedInit -> RultiRandom;
    RultiP.Leds -> LedsC;

    AMSend = RultiP;
    Receive = RultiP;
    Packet = RultiRtxSender;
    AMPacket = RultiRtxSender.AMPacket;
}
