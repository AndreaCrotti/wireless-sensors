#include "NeighBor.h"

/**
 * @file   NeighBourMod.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Tue May 11 17:16:24 2010
 * 
 * @brief  Module to keep the neighbour list of every mote.
 * We use the RADIO package to send beacons through the wireless
 * The neighbor list is simply a 16 bit integer mask
 * 
 */

module NeighBorMod {
    // radio part
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface Receive;

    // maybe seconds could be also enough
    uses interface Timer<TMilli> as Timer;
    
    provides interface startSensing();
}

// use a task to post the event that makes the list of neighbors update

implementation {
    // this could be bigger in case we have more motes?
    uint16_t neighbors = 0;
    // motes that answered in the last TIMEOUT period
    uint16_t last_seen = 0;
    
    uint8_t LAST_ARRIVAL[MAX_MOTES];
    void simple_check(uint32_t);

    // 2 seconds every beacon, 15 seconds is the timeout
    command void startSensing() {
        Timer.startPeriodic(PERIOD);
        int i;
        // setup initially to -1
        for (i = 0; i < MAX_MOTES; i++) {
            LAST_ARRIVAL[i] = -1;
        }
        
        // checking if multiple
        assert(TIMEOUT % BEACON == 0);
    }

    
    event void Timer.fired() {
        uint32_t delay = Timer.getdt();

        simple_check(delay);
    }
    
    /** 
     * Use the LAST_ARRIVAL array to determine when we're actually having a timeout
     * 
     * @param delay time passed from Timer start
     */
    void smart_check(uint32_t delay) {
        int i;
        for (i = 0; i < MAX_MOTES; i++) {
            
        }
    }

    /** 
     * Simply set the neighbors list as the last seen motes
     * 
     * @param delay 
     */
    void simple_check(uint32_t delay) {

        if (delay % (BEACON * PERIOD) == 0) {
            // start to broacast the beacon package
        }
        
        if (delay % (TIMEOUT * PERIOD) == 0) {
            // send a timeout package for who didn't answer?
            // we must also keep a stack of all the motes that answered in the last
            // 15 seconds to make sure we are not doing useless operations
            // who didn't answer and is not in the list gets removed
            
            // This is the simple way, just replace with the last seen motes
            neighbors = last_seen;
            last_seen = 0;
        }
    }

    /** 
     * Set the bit corresponding to mote idx to 0
     * 
     * @param idx index of the mote
     */
    void removeNeighbor(uint8_t idx) {
        neighbors &= !(1 << idx);
    }
    
    /** 
     * Set the bit corresponding to mote idx to 1
     * 
     * @param idx 
     */
    void addNeighbor(uint8_t idx) {
        neighbors |= (1 << idx);
    }

    // TODO: implement the receive part where it makes a distinction between
    // a broacast beacon message and a ACK to the beacon

    event message_t* Receive.receive(message_t* message, void* payload, uint8_t len) {
        // in the payload there could be contained the type of the message
        // in case it's a ACK we can add a neighbor, removing is actually never done automatically
    }
}
