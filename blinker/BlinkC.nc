#include "Blink.h"
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
    // The current message
    message_t pkt;
    // The current sequential ID
    seqno_t curr_sn = 0;
    // led mask
    uint8_t ledMask = 0;
    
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
     *  Helper function to start a one-shot timer for node 0 and do
     *  nothing for other nodes.
     */
    void timer(void) {
        if (!TOS_NODE_ID) {
            // if we use one time shots, we do not need a busy flag or anything
            // also: we cannot have timer fires while we are still busy
            call Timer.startOneShot(BLINK_GENERATE_INTERVAL_MS);
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
            timer();
        }
        else {
            call AMControl.start();
        }
    }

    /**
     * Called, when the radio module has stopped.
     * - not used -
     */
    event void AMControl.stopDone(error_t err) {
    }

    /**
     * This event is triggered whenever the timer fires.
     * If the mote has ID 0, a LED is randomly choosen and activated,
     * and the choice is braodcasted over the network. 
     */
    event void Timer.fired() {
        if (TOS_NODE_ID == 0) {
            instr_t leds = (instr_t)selectRandomLed();
            /* dbg("BlinkC", "got led %d\n", led_idx); */
            setLed(leds);
            broadcastLed(++curr_sn, leds);
        }
    }

    /**
     * Selects a LED number randomly.
     *
     * @return An interger between 0 and 2
     */
    uint8_t selectRandomLed() {
        return 1 << ((call Random.rand16()) % 3);
    }
  
    /**
     * Applies an instruction to the leds.
     *
     * @param led Number of the LED to turn on.
     */
    void setLed(instr_t led) {
        ledMask = (ledMask & (~led >> 3)) ^ led;
        call Leds.set(ledMask);
    }

    /**
     * Broadcast a led number over the radio network.
     *
     * @param id The sequential ID of the message.
     * @param led_idx The ID of the LED.
     */
    void broadcastLed(uint8_t id, uint8_t led_idx) {
        BlinkMsg* btrpkt;
        // TODO: is the casting actually needed in nesc?
        // This differs from tutorial where it was NULL, check correctness
        btrpkt = (BlinkMsg *)(call Packet.getPayload(&pkt, 0));

        /// setting the id of the message and incrementing it for the next call
        btrpkt->seqno = seqno;
        btrpkt->instr = instr;
        btrpkt->dest = AM_BROADCAST_ADDR;
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkMsg)) == SUCCESS)
            dbg("BlinkC", "Broadcasting message with sequential number %i and led number %i\n", btrpkt->seqno, btrpkt->instr);
    }

    
    /**
     * When the sending is completed successfully, we set the busy-flag to false.
     *
     * @param msg The packet which was submitted as a send request.
     * @param error SUCCESS if it was sent successfully, FAIL if it was not, 
     *   ECANCEL if it was cancelled 
     */
    event void AMSend.sendDone(message_t* msg, error_t error) {
        if (&pkt == msg)
            if (error == SUCCESS) {
              timer();
            } else {
              while (call AMSend.send(AM_BROADCAST_ADD,msg,sizeof(PrlMsg)) == FAIL);
            }
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
            seqno_t sn = btrpkt->seqno;
            /* dbg("BlinkC", "Message received\n"); */
	    
            if(sn > curr_sn || (!sn && curr_sn)) {
                /* dbg("BlinkC", "received led %d and broadcasted", btrpkt->led_idx); */
                curr_sn = sn;
                setLed(btrpkt->instr);
                broadcastLed(curr_id, btrpkt->led_idx);
            } else {
                dbg("BlinkC", "A message was dumped, because sequential number was to small\n");
	    }
        }
        return message;
    }
}
