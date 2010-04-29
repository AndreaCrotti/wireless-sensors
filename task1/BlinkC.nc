/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/

#include <stdlib.h> // Used for random call

module BlinkC {
    // required interfaces to manage and send/receive packages
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface Receive;    

    // used to control the ActiveMessageC component
    uses interface SplitControl as AMControl;

    uses interface Timer<TMilli> as Timer;
    uses interface Boot;
    uses interface Leds;

    uses interface Random;
    /* uses interface ParameterInit as SeedInit; */
}

implementation {

    void setLed(uint8_t);
    uint8_t selectRandomLed();
    bool broadcastLed(uint8_t, uint8_t);
    

    // variables to control the channel
    bool busy = FALSE;
    message_t pkt;
    uint8_t curr_id = 0;

    event void Boot.booted() {
        dbg("Boot", "Booting mote number %d\n", TOS_NODE_ID);
        // booted now must wait until the radio channel is actually available
        // handling of timer starting is done in AMControl now
        /* call SeedInit.init(0); */
        call AMControl.start();
    }
 
    // We can split in more functions to avoid code duplication
    // - ID == 0
    //   + set random led
    //   + broadcast
    // - ID != 0
    //   + receive
    //   + check if already got or set led and broadcast

    event void Timer.fired() {
        if (TOS_NODE_ID == 0) {
            uint8_t led_idx = selectRandomLed();
            /* dbg("BlinkC", "got led %d\n", led_idx); */
            setLed(led_idx);
            broadcastLed(++curr_id, led_idx);
        }
    }

    // normal functions can still call events or tasks
    uint8_t selectRandomLed() {
        // TODO: seed the random generator
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
    }

    /** 
     * Broadcast a led information through the radio
     * 
     * 
     * @return 
     */
    bool broadcastLed(uint8_t id, uint8_t led_idx) {
        /// check if the channel is busy, take the payload of the message and manipulate it
        if (!busy) {
            // TODO: is the casting actually needed in nesc?
            // This differs from tutorial where it was NULL, check correctness
            BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg *)(call Packet.getPayload(&pkt, 0));

            /// setting the id of the message and incrementing it for the next call
            btrpkt->id = id;
            btrpkt->led_idx = led_idx;
            /// if the send was successful make the channel busy, will be freed in sendDone
            if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
                busy = TRUE;
            }
        }
        return TRUE;
    }

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            dbg("BlinkC", "Radio channel is started correctly, starting timer\n");
            call Timer.startPeriodic(INTERVAL);
        }
        else {
            call AMControl.start();
        }
    }
    event void AMControl.stopDone(error_t err) {
    }
    
    BlinkToRadioMsg* btrpkt_loc;
    event void AMSend.sendDone(message_t* msg, error_t error) {
        if (&pkt == msg) {
            busy = FALSE;
            btrpkt_loc = (BlinkToRadioMsg *)(call Packet.getPayload(&pkt, 0));
            dbg("BlinkC", "sended message with sequential number %i and led number %i\n", btrpkt_loc->id, btrpkt_loc->led_idx);
        }
    }

    event message_t* Receive.receive(message_t* message, void* payload, uint8_t len){
        dbg("BlinkC", "receive entered\n");
        if (len == sizeof(BlinkToRadioMsg)){
            BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*) payload;
            uint8_t seq_num = btrpkt->id; 
            dbg("BlinkC", "Message received\n");
            if(seq_num > curr_id){
                dbg("BlinkC", "received led %d and broadcasted", btrpkt->led_idx);
                curr_id = seq_num;
                setLed(btrpkt->led_idx);
                broadcastLed(curr_id, btrpkt->led_idx);
            }
        }
        return message;
    }
}

