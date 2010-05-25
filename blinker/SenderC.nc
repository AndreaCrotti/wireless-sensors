/**
 * @file   SenderC.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Tue May 25 10:43:59 2010
 * 
 * @brief  Fresh start point to rewrite the sending stuff
 * 
 * 
 */

module SenderC {
    uses {
        interface AMSend as RelSend;
        interface Receive;
        interface Leds;
        interface PacketAcknowledgements;
        interface Timer<TMilli>;
    }

    provides {
        interface AMSend;
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
    event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
        return msg;
    }
  
    // Starting the timer
    command error_t Init.init() {
        // set up the message maybe?
        return SUCCESS;
    }
    
    event void Timer.fired() {
    }

    /***************** AMSend Events ****************/
    event void RelSend.sendDone(message_t *msg, error_t error) {
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
        if(call AMSend.send(1, &myMsg, 0) != SUCCESS) {
            // repost another task until it's succesfully transmitted
            post send();
        }
    }
    command error_t AMSend.send(am_addr_t dest, message_t* msg, uint8_t len) {
        // setup the message and post the task then
        return SUCCESS;
    }

    command error_t AMSend.cancel(message_t* msg) {
        return call RelSend.cancel(msg);
    }
    /**
     * Getter. Patched through from the lower layer.
     */
    command uint8_t AMSend.maxPayloadLength() {
        return call RelSend.maxPayloadLength();
    }
    /**
     * Getter. Patched through from the lower layer.
     */
    command void* AMSend.getPayload(message_t* m, uint8_t len) {
        return call RelSend.getPayload(m,len);
    }

}
