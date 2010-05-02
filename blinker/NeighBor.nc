configuration NeighBor {
    
}

implementation {
    components new TimerMilliC() as Timer;
    // components needed for the radio communication
    components ActiveMessageC;
    components SerialActiveMessageC;
    components new AMSenderC(AM_BLINK) as BlinkSender;
    components new AMReceiverC(AM_BLINK) as BlinkReceiver;
    //components new SerialAMSenderC(AM_SERIAL_BLINK) as SerialBlinkSender;
    components new SerialAMReceiverC(AM_SERIAL_BLINK) as SerialBlinkReceiver;

    // now wire all the components together
    
    
}