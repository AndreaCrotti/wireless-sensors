/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/

#include <stdlib.h>

module BlinkC
{
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface SplitControl as AMControl;
    uses interface Timer<TMilli> as Timer;
    uses interface Boot;
    uses interface Leds;
}

implementation {
    int led_idx;

    event void Boot.booted() {
        dbg("Boot", "Booting mote number %d\n", TOS_NODE_ID);
        call Timer.startPeriodic( 1000 );
    }
 
    event void Timer.fired() {
        dbg("Boot", "Timer 0 fired @ %s.\n", sim_time_string());
       
        if (TOS_NODE_ID == 0) {
	       
            // Choose a random LED
            led_idx = (int) (random() * 3);
            // Turn all LEDs off
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
        }
    }
    event void AMControl.startDone(error_t err) {
    }

    event void AMControl.stopDone(error_t err) {
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
    }
}

