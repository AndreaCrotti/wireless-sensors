// use generic modules instead to make it more modular
// and get some arguments passed in
configuration EasyRoutingC @safe() {
    // we provide sending and receiving interface
    provides {
        interface AMSend;
        interface Receive;
        interface Packet;
        interface Init;
    }
    // we can also declare our own interface now
}

implementation {
    components RultiC;
    // Using the Queue for sending
    components new SendQueueC(10, sizeof(BlinkMsg)) as SendQueue;

    components EasyRoutingP;
    components LedsModC;
    components LedsC;
    components new TimerMilliC() as BeaconTimer;
    
    components new AMSenderC(AM_BEACON) as BeaconSender;
    components new AMReceiverC(AM_BEACON) as BeaconReceiver;

#ifndef TOSSIM
    // needed for checking link quality
    components CC2420ActiveMessageC;
#endif

    EasyRoutingP.Packet -> BeaconSender.Packet;
    EasyRoutingP.BeaconSend -> BeaconSender.AMSend;
    EasyRoutingP.BeaconReceive -> BeaconReceiver;
    EasyRoutingP.Timer -> BeaconTimer;
    EasyRoutingP.Leds -> LedsC;

    EasyRoutingP.RelReceive -> RultiC.Receive;
    EasyRoutingP.RelSend -> SendQueue.AMSend;
    
    // Tell the sending Queue to use the Rulti module for sending
    SendQueue.LowSend -> RultiC.AMSend;
    SendQueue.AMPacket -> RultiC.AMPacket;

#ifndef TOSSIM
    EasyRoutingP.CC2420Packet -> CC2420ActiveMessageC;
#endif

    AMSend = EasyRoutingP;
    Receive = EasyRoutingP;
    Init = EasyRoutingP;
    Packet = RultiC.Packet;
}