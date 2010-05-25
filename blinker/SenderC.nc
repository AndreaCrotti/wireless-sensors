module SenderC {
    uses {
        interface Boot;
        interface SplitControl;
        interface AMSend as LowSend;
        interface Receive as LowReceive;
        interface Leds;
 interface PacketAcknowledgements;
        interface Timer<TMilli>;
    }

    provides {
        interface AMSend;
        interface Receive;
        interface Init;
    }
}

implementation {
  
    /** Message to transmit */
    message_t myMsg;
  
    // we can also randomize the delay better
    enum {  
        DELAY_BETWEEN_MESSAGES = 50,
    };
  
  
    /***************** Prototypes ****************/
    task void send();
  
    /***************** Receive Events ****************/
    event message_t *LowReceive.receive(message_t *msg, void *payload, uint8_t len) {
        return msg;
    }
  
    /***************** AMSend Events ****************/
    event void AMSend.sendDone(message_t *msg, error_t error) {
        // do something about it
        call PacketAcknowledgements.wasAcked(msg);
    
        if (DELAY_BETWEEN_MESSAGES > 0) {
            call Timer.startOneShot(DELAY_BETWEEN_MESSAGES);
        } else {
            post send();
        }
    }
  
    /***************** Tasks ****************/
    task void send() {
        call PacketAcknowledgements.requestAck(&myMsg);
        if(call AMSend.LowSend(1, &myMsg, 0) != SUCCESS) {
            // repost another task until it's succesfully transmitted
            post send();
        }
    }
    command error_t AMSend.cancel(message_t* msg) {
        stopRtx();
        return call PayloadSend.cancel(msg);
    }
    /**
     * Getter. Patched through from the lower layer.
     */
    command uint8_t AMSend.maxPayloadLength() {
        return call PayloadSend.maxPayloadLength();
    }
    /**
     * Getter. Patched through from the lower layer.
     */
    command void* AMSend.getPayload(message_t* m, uint8_t len) {
        return call PayloadSend.getPayload(m,len);
    }

}
