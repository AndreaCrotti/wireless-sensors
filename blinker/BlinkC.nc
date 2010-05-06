/**
 * Implementation of the first task.
 * Node number 0 of the network select a random led
 * and broadcast it to the whole network.
 * The other nodes accept the command, make sure they only receive once
 * and set the led also.
 * 
 * @file BlinkC.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date So 2. Mai 21:14:53 CEST 2010
 **/

module BlinkC {
    // required interfaces to manage and send/receive packages
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface Receive;    

    // used to control the ActiveMessageC component
    uses interface SplitControl as AMControl;
    
    // additional needed components
    // TODO: is it possible to add the timer ONLY to mote 0?
    uses interface Timer<TMilli> as Timer;
    uses interface Boot;
    uses interface Leds;
    uses interface Random;
    uses interface ParameterInit<uint16_t> as SeedInit;
}

implementation {
  
    void setLed(uint8_t);
    uint8_t selectRandomLed();
    void broadcastLed(uint8_t, uint8_t);
    

    //// variables to control the channel ////
    // Is true when the sending module is busy
    bool busy = FALSE;
    // The current message
    message_t pkt;
    // The current sequential ID
    uint8_t curr_id = 0;
    
    /**
     * This event is called, after the device was booted and we start AMControl here.
     */
    event void Boot.booted() {
        /* dbg("Boot", "Booting mote number %d\n", TOS_NODE_ID); */
        // booted now must wait until the radio channel is actually available
        // handling of timer starting is done in AMControl now
        call SeedInit.init(13);
        call AMControl.start();
    }

    /**
     * This event is triggered whenever the timer fires.
     * If the mote has ID 0, a LED is randomly choosen and activated,
     * and the choice is braodcasted over the network. 
     */
    event void Timer.fired() {
	if (TOS_NODE_ID == 0) {
            uint8_t led_idx = selectRandomLed();
            /* dbg("BlinkC", "got led %d\n", led_idx); */
            setLed(led_idx);
            broadcastLed(++curr_id, led_idx);
        }
    }

    /**
     * Selects a LED number randomly.
     *
     * @return An interger between 0 and 2
     */
    uint8_t selectRandomLed() {
        uint8_t led = (call Random.rand16()) % 3;
        return led;
    }
  
    /**
     * Turns on one Led and turns off all the others.
     *
     * @param led Number of the LED to turn on.
     */
    void setLed(uint8_t led) {
        call Leds.set(0);

        // Turn on the new LED
        switch(led) {
        case '0':
            call Leds.led0On();
            break;
        case '1':
            call Leds.led1On();
            break;
        case '2':
            call Leds.led2On();
            break;
        }

	dbg("BlinkC", "Turned on LED %i\n", led);
    }

    /**
     * Broadcast a led number over the radio network.
     *
     * @param id The sequential ID of the message.
     * @param led_idx The ID of the LED.
     */
    void broadcastLed(uint8_t id, uint8_t led_idx) {
        /// check if the channel is busy, take the payload of the message and manipulate it
        if (!busy) {
            // TODO: is the casting actually needed in nesc?
            // This differs from tutorial where it was NULL, check correctness
            BlinkMsg* btrpkt = (BlinkMsg *)(call Packet.getPayload(&pkt, 0));

            /// setting the id of the message and incrementing it for the next call
            btrpkt->id = id;
            btrpkt->led_idx = led_idx;
            /// if the send was successful make the channel busy, will be freed in sendDone
            if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkMsg)) == SUCCESS) {
		dbg("BlinkC", "Broadcasting message with sequential number %i and led number %i\n", btrpkt->id, btrpkt->led_idx);

                busy = TRUE;
            }
        }
    }

    /**
     * Is called, if the radio module is started.
     * In this case, we start the timer.
     *
     * @param err SUCCESS if the component was successfully turned on, FAIL otherwise.
     */
    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            /* dbg("BlinkC", "Radio channel is started correctly, starting timer\n"); */
            call Timer.startPeriodic(INTERVAL);
        }
        else {
            call AMControl.start();
        }
    }

    /**
     * Called, when the radio module has stopped.
     * - not implemented -
     */
    event void AMControl.stopDone(error_t err) {
    }
    
    /**
     * When the sending is completed successfully, we set the busy-flag to false.
     *
     * @param msg The packet which was submitted as a send request.
     * @param error SUCCESS if it was sent successfully, FAIL if it was not, 
     *   ECANCEL if it was cancelled 
     */
    event void AMSend.sendDone(message_t* msg, error_t error) {
        if (&pkt == msg) {
            busy = FALSE;
        }
    }
    
    /**
     * This event is triggered, whenever a message is received.
     * If the message is new to the mote, it sets his LED to the LED number specified in
     * the messages payload and broadcasts the message.
     *
     * @param message The received packet.
     * @param payload A pointer to the packet's payload.
     * @param len The length of the data region pointed to by payload. 
     * @return The received message.
     */
    event message_t* Receive.receive(message_t* message, void* payload, uint8_t len){
        if (len == sizeof(BlinkMsg)){

            BlinkMsg* btrpkt = (BlinkMsg*) payload;
            uint8_t seq_num = btrpkt->id; 
            /* dbg("BlinkC", "Message received\n"); */
	    
            if(seq_num > curr_id) {
                /* dbg("BlinkC", "received led %d and broadcasted", btrpkt->led_idx); */
                curr_id = seq_num;
                setLed(btrpkt->led_idx);
                broadcastLed(curr_id, btrpkt->led_idx);

            } 
            else {
                dbg("BlinkC", "A message was dumped, because sequential number was to small\n");
	    }
        }
        return message;
    }
}
