#include "AM.h"
#include "Tosthreads.h"

module Radio {
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
        if (TOS_NODE_ID == 1) {
            call BlockingSendThread.start(NULL);
        }
    }

    event void BlockingReceiveThread.run(void* arg) {
        CmdMsg* cmdr = (CmdMsg*)(call Packet.getPayload(&mr,sizeof(CmdMsg)));
        call BlockingAMControl.start();
        for(;;) {
            if (call BlockingReceive.receive(&mr,BRECEIVE_TIMEOUT) == SUCCESS) {
                call Leds.set(cmdr->instr);
            }
        }
    }

    event void BlockingSendThread.run(void* arg) {
        CmdMsg* cmds = (CmdMsg*)(call Packet.getPayload(&ms,sizeof(CmdMsg)));
        call BlockingAMControl.start();
        for(;;) {
            cmds->instr++;
            cmds->seqno++;
            call BlockingAMSend.send(AM_BROADCAST_ADDR,&ms,sizeof(CmdMsg));
            call BlockingSendThread.sleep(BSEND_SLEEP);
        }
    }
}
