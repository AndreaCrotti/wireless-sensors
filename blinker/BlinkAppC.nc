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
 * @author Oscar Dustmann
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
    components new SerialAMSenderC(AM_SERIAL_BLINK) as SerialBlinkSender;
    components new SerialAMReceiverC(AM_SERIAL_BLINK) as SerialBlinkReceiver;
    //components CC2420PacketC;
    
    components new AMSenderC(AM_BEACON) as BeaconSender;
    components new AMReceiverC(AM_BEACON) as BeaconReceiver;
    components new AMSenderC(AM_RULTI_RTX) as RultiRtxSender;
    components new AMReceiverC(AM_RULTI_RTX) as RultiRtxReceiver;
    components new AMSenderC(AM_RULTI_ACK) as RultiAckSender;
    components new AMReceiverC(AM_RULTI_ACK) as RultiAckReceiver;
    components RandomC as RultiRandom;
    components new TimerMilliC() as BeaconTimer;
    components new TimerMilliC() as RultiRtxTimer;
    components new TimerMilliC() as RultiAckTimer;

    ////// The sensor components //////
    // Humidity and temperature 
    components new SensirionSht11C() as SensirionC;
    // Infrared
    components new HamamatsuS10871TsrC() as PhotoActiveC;
    // Normal light
    components new HamamatsuS1087ParC() as TotalSolarC;
    
    components RultiC;
    components EasyRoutingC;
    
    BlinkC -> MainC.Boot;
    
    BlinkC.Timer -> Timer;
    BlinkC.Leds -> LedsC;

    /// Wirering for the reliable multi-cast module
    RultiC.Packet -> RultiRtxSender.Packet;
    RultiC.PayloadSend -> RultiRtxSender.AMSend;
    RultiC.PayloadReceive -> RultiRtxReceiver.Receive;
    RultiC.AckSend -> RultiAckSender.AMSend;
    RultiC.AckReceive -> RultiAckReceive.Receive;
    RultiC.RtxTimer -> RultiRtxTimer;
    RultiC.AckTimer -> RultiAckTimer;
    RultiC.Random -> RandomC;
    RultiC.SeedInit -> RandomC;

    /// Linking for the neighbor module
    EasyRoutingC.Packet -> BeaconSender.Packet;
    EasyRoutingC.AMSend -> BeaconSender.AMSend;
    EasyRoutingC.Receive -> BeaconReceiver;
    EasyRoutingC.Timer -> BeaconTimer;

    /// Linking all our interfaces to the correct components
    BlinkC.Packet -> BlinkSender.Packet;
    BlinkC.AMPacket -> BlinkSender.AMPacket;
    BlinkC.AMSend -> BlinkSender.AMSend;
    BlinkC.AMControl -> ActiveMessageC;
    BlinkC.Receive -> BlinkReceiver;
    //BlinkC.CC2420Packet -> CC2420PacketC;

    /// serial communication
    BlinkC.SerialPacket -> SerialBlinkSender;
    BlinkC.SerialAMPacket -> SerialBlinkSender;
    BlinkC.SerialAMSend -> SerialBlinkSender;
    BlinkC.SerialControl -> SerialActiveMessageC;
    BlinkC.SerialReceive -> SerialBlinkReceiver;
    
    // Linking the sensor components
    BlinkC.LightSensor -> TotalSolarC;
    BlinkC.InfraSensor -> PhotoActiveC;
    BlinkC.TempSensor -> SensirionC.Temperature;
    BlinkC.HumSensor -> SensirionC.Humidity;
}

