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
    // used to control the ActiveMessageC component
    uses interface SplitControl as AMControl;

    uses interface Timer<TMilli> as Timer;
    uses interface Boot;
    uses interface Leds;
}

implementation {
    uint8_t led_idx;
    // variables to control the channel
    bool busy = FALSE;
    message_t pkt;
    uint8_t id = 0;

    event void Boot.booted() {
        dbg("Boot", "Booting mote number %d\n", TOS_NODE_ID);
        // booted now must wait until the radio channel is actually available
        // handling of timer starting is done in AMControl now
        call AMControl.start();
    }
 
    event void Timer.fired() {
        /* dbg("Boot", "Timer 0 fired @ %s.\n", sim_time_string()); */

        if (TOS_NODE_ID == 0) {

            // TODO: use instead the random generator included in tinyos
            // Choose a random LED, * and / is faster then % operator
            led_idx = (int) (3 * (random() / (RAND_MAX + 1.0)));
            // Turn all LEDs off
            dbg("BlinkC", "Node 0 turn on led %d and propagates the message\n", led_idx);
            call Leds.set(0);

            // Turn on the new LED
            switch(led_idx) {
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

            /// check if the channel is busy, take the payload of the message and manipulate it
            if (!busy) {
                // TODO: is the casting actually needed in nesc?
                BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, NULL));

                /// setting the id of the message and incrementing it for the next call
                btrpkt->id = id++;
                btrpkt->led_idx = led_idx;
                /// if the send was successful make the channel busy, will be freed in sendDone
                if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
                    busy = TRUE;
                }
            }
        }
    }
    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            call Timer.startPeriodic(INTERVAL);
        }
        else {
            call AMControl.start();
        }
    }
    event void AMControl.stopDone(error_t err) {
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
    }
}

