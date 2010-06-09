#include "Tosthreads.h"

/**
 * TODO: Dokumentation!!!!!1111elf
 * 
 * @file BlinkC.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date So 2. Mai 21:14:53 CEST 2010
 **/

module TosthreadsP /*@safe()*/ {
    // required interfaces to manage and send/receive packets
    uses {
        // standart components
        interface Boot;
        interface Leds;
        
        // For accessing packets
        interface Packet;

        // Radio interfaces
        interface BlockingAMSend as RadioSend[uint8_t id];
        interface BlockingReceive as RadioReceive;

        // Serial interfaces
        interface BlockingAMSend as SerialSend[uint8_t id];
        interface BlockingReceive as SerialReceive;

        // For setting the node's addresses
        interface ActiveMessageAddress;

        // used to control the ActiveMessageC component
        interface BlockingStdControl as RadioControl;
        interface BlockingStdControl as SerialControl;

        // Threads
        interface Thread as BootThread;
    }
}

implementation {
  
    /********************/
    /* Global variables */
    /********************/

    /**********/
    /* Events */
    /**********/
    
    /** 
     * Starts the radio and serial module when the mote is booted.
     */
    event void Boot.booted(){
        call BootThread.start(NULL);
    }
    
    async event void ActiveMessageAddress.changed() {
    }

    /***********/
    /* Threads */
    /***********/
    
    /** 
     * Starts the radio and serial module.
     * 
     * @param arg A pointer... 
     */
    event void BootThread.run(void* arg){
        call RadioControl.start();
        call SerialControl.start();

        // set the active message address to workaround the testbed bug
        call ActiveMessageAddress.setAddress(call ActiveMessageAddress.amGroup(), 
                                             TOS_NODE_ID);
    }

}
