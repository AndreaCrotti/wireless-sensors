#include "AM.h"
#include "Tosthreads.h"

module RadioStressC {
    uses {
        interface Boot;
        interface BlockingStdControl as BlockingAMControl;
        interface Packet;

        interface Thread as BlockingReceiveThread;
        interface BlockingReceive as BlockingReceive;

        interface Thread as BlockingSendThread;
        interface BlockingAMSend as BlockingAMSend;
    
        /*interface Thread as RadioStressThread1;
        interface BlockingAMSend as BlockingAMSend1;
        interface BlockingReceive as BlockingReceive1;
    
        interface Thread as RadioStressThread2;
        interface BlockingAMSend as BlockingAMSend2;
        interface BlockingReceive as BlockingReceive2;*/

        interface Leds;
    }
}

implementation {
    message_t mr;
    message_t ms;
  
    event void Boot.booted() {
        call BlockingReceiveThread.start(NULL);
        call BlockingSendThread.start(NULL);
    }

    event void BlockingReceiveThread.run(void* arg) {
        CmdMsg* cmdr = (CmdMsg*)Packet.getPayload(&mr,sizeof(CmdMsg));
        call BlockingAMControl.start();
        for(;;) {
            if (call BlockingReceive.receive(&mr,BRECEIVE_TIMEOUT) == SUCCESS) {
                Leds.set(cmdr->instr);
            }
        }
    }

    event void BlockingSendThread.run(void* arg) {
        CmdMsg* cmds = (CmdMsg*)Packet.getPayload(&ms,sizeof(CmdMsg));
        call BlockingAMControl.start();
        for(;;) {
            call BlockingAMSend.send(AM_BROADCAST_ADDR,&ms,sizeof(CmdMsg));
            call BlockingSendThread.sleep(BSEND_SLEEP);
        }
    }
}
