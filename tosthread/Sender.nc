#include "AM.h"

module RadioStressC {
    uses {
        interface Boot;
        interface BlockingStdControl as BlockingAMControl;

        interface Thread as RadioStressThread0;
        interface BlockingAMSend as BlockingAMSend0;
        interface BlockingReceive as BlockingReceive0;
    
        interface Thread as RadioStressThread1;
        interface BlockingAMSend as BlockingAMSend1;
        interface BlockingReceive as BlockingReceive1;
    
        interface Thread as RadioStressThread2;
        interface BlockingAMSend as BlockingAMSend2;
        interface BlockingReceive as BlockingReceive2;

        interface Leds;
    }
}

implementation {
    message_t m0;
    message_t m1;
    message_t m2;
  
    event void Boot.booted() {
        call RadioStressThread0.start(NULL);
        call RadioStressThread1.start(NULL);
        call RadioStressThread2.start(NULL);
    }

    event void RadioStressThread0.run(void* arg) {
        call BlockingAMControl.start();
        for(;;) {
            if(TOS_NODE_ID == 0) {
                // receive something, put it on m0 with the timeout 5000
                call BlockingReceive0.receive(&m0, 5000);
                call Leds.led0Toggle();
            }
            else {
                // send to all the other nodes?
                call BlockingAMSend0.send(!TOS_NODE_ID, &m0, 0);
                call Leds.led0Toggle();
                //call RadioStressThread0.sleep(500);
            }
        }
    }
  
    event void RadioStressThread1.run(void* arg) {
        call BlockingAMControl.start();
        for(;;) {
            if(TOS_NODE_ID == 0) {
                call BlockingReceive1.receive(&m1, 5000);
                call Leds.led1Toggle();
            }
            else {
                call BlockingAMSend1.send(!TOS_NODE_ID, &m1, 0);
                call Leds.led1Toggle();
                //call RadioStressThread1.sleep(500);
            }
        }
    }
  
    event void RadioStressThread2.run(void* arg) {
        call BlockingAMControl.start();
        for(;;) {
            if(TOS_NODE_ID == 0) {
                call BlockingReceive2.receive(&m2, 5000);
                call Leds.led2Toggle();
            }
            else {
                call BlockingAMSend2.send(!TOS_NODE_ID, &m2, 0);
                call Leds.led2Toggle();
                //call RadioStressThread2.sleep(500);
            }
        }
    }
}
