// use generic modules instead to make it more modular
// and get some arguments passed in
configuration EasyRoutingC @safe() {
    // we provide sending and receiving interface
    provides {
        interface AMSend;
        interface Receive;
    }
    // we can also declare our own interface now
}

implementation {
    components RultiC;
    components EasyRoutingP;
    components LedsModC;

    AMSend = EasyRoutingP;
    Receive = EasyRoutingP;
}