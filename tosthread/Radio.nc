/**
 * @file   Radio.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Wed Jun 13 12:02:18 2010
 * 
 * @brief  Main module for all active nodes (that is nodes != 0).
 * 
 */
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
    
        interface Leds;
    }
}

implementation {
    // the message buffer we use for receiving
    message_t mr;
    // the message buffer we use for sending
    message_t ms;
    // NOTE: since we usually only either receive or send, one buffer should be enough, but we use two to support future modifications to this module
  
    /**
     * Boot this module
     */
    event void Boot.booted() {
        call BlockingReceiveThread.start(NULL);
        if (TOS_NODE_ID == 1) {
            call BlockingSendThread.start(NULL);
        }
    }

    /**
     * Thread to receive messages over the radio.
     * 
     * @param arg not used
     */
    event void BlockingReceiveThread.run(void* arg) {
        CmdMsg* cmdr = (CmdMsg*)(call Packet.getPayload(&mr,sizeof(CmdMsg)));
        call BlockingAMControl.start();
        for(;;) {
            if (call BlockingReceive.receive(&mr,BRECEIVE_TIMEOUT) == SUCCESS) {
                call Leds.set(cmdr->instr);
            }
        }
    }

    /**
     * Thread to send messages over the radio. This is only run if we are node 1.
     * 
     * @param arg not used
     */
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
