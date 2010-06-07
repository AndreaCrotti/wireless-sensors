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

#ifndef TOSSIM
    // needed for checking link quality
    components CC2420ActiveMessageC;
    // support for storage
    components new ConfigStorageC(VOLUME_CONFIGTEST);
    // log storage, TRUE stands for circular log
    components new LogStorageC(VOLUME_LOG_LIGHT, TRUE) as LogLight;
    components new LogStorageC(VOLUME_LOG_HUM, TRUE) as LogHum;
    components new LogStorageC(VOLUME_LOG_TEMP, TRUE) as LogTemp;
    components new LogStorageC(VOLUME_LOG_INFRA, TRUE) as LogInfra;
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

    components RultiC;
    // TODO: change this value to what is really needed
    components EasyRoutingC;

    // just needed as a facility
    BlinkC -> MainC.Boot;
    
    BlinkC.SenseRtxTimer -> SenseRtxTimer;
    BlinkC.MsgRtxTimer -> MsgRtxTimer;
    BlinkC.Leds -> LedsC;

#ifndef TOSSIM
    // wiring configuration stuff
    BlinkC.Config -> ConfigStorageC.ConfigStorage;
    BlinkC.Mount  -> ConfigStorageC.Mount;
    BlinkC.LogReadLight -> LogLight;
    BlinkC.LogWriteLight -> LogLight;
    /* BlinkC.LogReadHum -> LogHum; */
    /* BlinkC.LogWriteHum -> LogHum; */
    /* BlinkC.LogReadInfra -> LogInfra; */
    /* BlinkC.LogWriteInfra -> LogInfra; */
    /* BlinkC.LogReadTemp -> LogTemp; */
    /* BlinkC.LogWriteTemp -> LogTemp; */
#endif

    /// Linking all our interfaces to the correct components
    BlinkC.Packet -> EasyRoutingC.Packet;
    BlinkC.AMSend -> EasyRoutingC.AMSend;
    BlinkC.AMControl -> ActiveMessageC;
    BlinkC.Receive -> EasyRoutingC;
    BlinkC.RoutingInit -> EasyRoutingC;
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

