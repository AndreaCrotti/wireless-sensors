configuration EasyRouting {
    // we provide sending and receiving interface
    provides {
        interface AMSend;
        interface Receive;
    }
}

implementation {
    /* components new AMSenderC(AM_BEACON) as BeaconSender; */
    /* components new AMReceiverC(AM_BEACON) as BeaconReceiver; */
    /* components new AMSenderC(AM_RULTI_RTX) as RultiRtxSender; */
    /* components new AMReceiverC(AM_RULTI_RTX) as RultiRtxReceiver; */
    /* components new AMSenderC(AM_RULTI_ACK) as RultiAckSender; */
    /* components new AMReceiverC(AM_RULTI_ACK) as RultiAckReceiver; */
    /* components new TimerMilliC() as BeaconTimer; */

    /* components RultiP; */
    components EasyRoutingP;
    AMSend = EasyRoutingP;
    Receive = EasyRoutingP;
    // AMsend looks not connected in this case

    /* EasyRoutingC.Packet -> BeaconSender.Packet; */
    /* EasyRoutingC.BeaconSend -> BeaconSender.AMSend; */
    /* EasyRoutingC.BeaconReceive -> BeaconReceiver; */
    /* EasyRoutingC.RelSend -> RultiP.AMSend; */
    /* EasyRoutingC.RelReceive -> RultiP.Receive; */
    /* EasyRoutingC.Timer -> BeaconTimer; */
}
