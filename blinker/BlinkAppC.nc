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
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 *
 * @date   So 2. Mai 21:11:02 CEST 2010
 * 
 */

configuration BlinkAppC @safe() {
    // here I have to put some configuration wiring to allow for splitting
}

implementation {
    components MainC, BlinkC, LedsC;
    components new TimerMilliC() as Timer;
    components ActiveMessageC;
    components SerialActiveMessageC;
    //components new AMSenderC(AM_BLINK) as BlinkSender;
    //components new AMReceiverC(AM_BLINK) as BlinkReceiver;
    components new SerialAMSenderC(AM_SERIAL_BLINK) as SerialBlinkSender;
    components new SerialAMReceiverC(AM_SERIAL_BLINK) as SerialBlinkReceiver;
    
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
    /*
    components new SensirionSht11C() as SensirionC;
    // Infrared
    components new HamamatsuS10871TsrC() as PhotoActiveC;
    // Normal light
    components new HamamatsuS1087ParC() as TotalSolarC;
    */

    // For TOSSIM debugging only
    components new DemoSensorC() as DemoSensorC;

    components RultiP;
    // TODO: change this value to what is really needed
    components new EasyRoutingP(0) as EasyRoutingP;
    
    BlinkC -> MainC.Boot;
    
    BlinkC.Timer -> Timer;
    BlinkC.Leds -> LedsC;

    /// Wirering for the reliable multi-cast module
    RultiP.Packet -> RultiRtxSender.Packet;
    RultiP.AMPacket -> RultiRtxSender.AMPacket;
    RultiP.PayloadSend -> RultiRtxSender.AMSend;
    RultiP.PayloadReceive -> RultiRtxReceiver.Receive;
    RultiP.AckSend -> RultiAckSender.AMSend;
    RultiP.AckReceive -> RultiAckReceiver.Receive;
    RultiP.RtxTimer -> RultiRtxTimer;
    RultiP.AckTimer -> RultiAckTimer;
    RultiP.Random -> RultiRandom;
    RultiP.SeedInit -> RultiRandom;
    RultiP.Leds -> LedsC;
    
    /// Linking for the neighbor module
    
    EasyRoutingP.Packet -> BeaconSender.Packet;
    EasyRoutingP.BeaconSend -> BeaconSender.AMSend;
    EasyRoutingP.BeaconReceive -> BeaconReceiver;
    EasyRoutingP.RelSend -> RultiP.AMSend;
    EasyRoutingP.RelReceive -> RultiP.Receive;
    EasyRoutingP.Timer -> BeaconTimer;
    
    /// Linking all our interfaces to the correct components
    BlinkC.Packet -> RultiRtxSender.Packet;
    BlinkC.AMSend -> EasyRoutingP.AMSend;
    BlinkC.AMControl -> ActiveMessageC;
    BlinkC.Receive -> EasyRoutingP;

    /// serial communication
    BlinkC.SerialAMSend -> SerialBlinkSender;
    BlinkC.SerialControl -> SerialActiveMessageC;
    BlinkC.SerialReceive -> SerialBlinkReceiver;
    
    // Linking the sensor components
    /*
    BlinkC.LightSensor -> TotalSolarC;
    BlinkC.InfraSensor -> PhotoActiveC;
    BlinkC.TempSensor -> SensirionC.Temperature;
    BlinkC.HumSensor -> SensirionC.Humidity;
    */

    BlinkC.LightSensor -> DemoSensorC;
    BlinkC.InfraSensor -> DemoSensorC;
    BlinkC.TempSensor -> DemoSensorC;
    BlinkC.HumSensor -> DemoSensorC;
}

