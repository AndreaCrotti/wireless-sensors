#include <Timer.h>
#include "Blink.h"

#ifndef TOSSIM
#include "StorageVolumes.h"
#endif

/**
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
    components new TimerMilliC() as MsgRtxTimer;
    components new TimerMilliC() as SenseRtxTimer;

    components ActiveMessageC;
#ifndef TOSSIM
    components ActiveMessageAddressC;
#endif
    components SerialActiveMessageC;

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

#ifndef TOSSIM
    // needed for checking link quality
    components CC2420ActiveMessageC;
    // support for storage
    components new ConfigStorageC(VOLUME_CONFIGTEST);
#endif

#ifdef TOSSIM
    // For TOSSIM debugging only
    components new DemoSensorC() as DemoSensorC;
#else
    ////// The sensor components //////
    
    // Humidity and temperature
    components new SensirionSht11C() as SensirionC;
    // Infrared
    components new HamamatsuS10871TsrC() as PhotoActiveC;
    // Normal light
    components new HamamatsuS1087ParC() as TotalSolarC;
#endif

    // trying out a new leds abstraction
    components LedsModC;

    components RultiP;
    // TODO: change this value to what is really needed
    components EasyRoutingP;

    BlinkC -> MainC.Boot;
    
    BlinkC.SenseRtxTimer -> SenseRtxTimer;
    BlinkC.MsgRtxTimer -> MsgRtxTimer;
    BlinkC.Leds -> LedsC;

#ifndef TOSSIM
    // wiring configuration stuff
    BlinkC.Config -> ConfigStorageC.ConfigStorage;
    BlinkC.Mount  -> ConfigStorageC.Mount;
#endif

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
    EasyRoutingP.Timer -> BeaconTimer;
    EasyRoutingP.Leds -> LedsC;

    EasyRoutingP.RelReceive -> RultiP.Receive;
    EasyRoutingP.RelSend -> RultiP.AMSend;
    
#ifndef TOSSIM
    EasyRoutingP.CC2420Packet -> CC2420ActiveMessageC;
#endif

    /// Linking all our interfaces to the correct components
    BlinkC.Packet -> RultiRtxSender.Packet;
    BlinkC.AMSend -> EasyRoutingP.AMSend;
    BlinkC.AMControl -> ActiveMessageC;
    BlinkC.Receive -> EasyRoutingP;
    BlinkC.RoutingInit -> EasyRoutingP;
#ifndef TOSSIM
    BlinkC.ActiveMessageAddress -> ActiveMessageAddressC;
#endif

    /// serial communication
    BlinkC.SerialAMSend -> SerialBlinkSender;
    BlinkC.SerialControl -> SerialActiveMessageC;
    BlinkC.SerialReceive -> SerialBlinkReceiver;
    
#ifdef TOSSIM
    BlinkC.LightSensor -> DemoSensorC;
    BlinkC.InfraSensor -> DemoSensorC;
    BlinkC.TempSensor -> DemoSensorC;
    BlinkC.HumSensor -> DemoSensorC;
#else
    // Linking the sensor components
    BlinkC.LightSensor -> TotalSolarC;
    BlinkC.InfraSensor -> PhotoActiveC;
    BlinkC.TempSensor -> SensirionC.Temperature;
    BlinkC.HumSensor -> SensirionC.Humidity;
#endif
}

