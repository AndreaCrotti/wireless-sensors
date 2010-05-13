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

module NeighborC {
    // radio part
    uses interface Packet;
    uses interface AMSend;
    uses interface Receive;

    // maybe seconds could be also enough
    uses interface Timer<TMilli> as Timer;
    
    provides interface Init;
}

// use a task to post the event that makes the list of neighbors update

implementation {
    // could that be bigger in case of more motes?
    uint16_t neighbors = 0;
    
    /// array keeping the last arrival time of the motes
    uint8_t LAST_ARRIVAL[MAX_MOTES];
    /// structure keeping the message to forward
    message_t pkt;

    void check_timeout(uint32_t);
    void init_msgs();
    void broadcast_beacon();
    void addNeighbor(uint8_t);
    void removeNeighbor(uint8_t);
    
    // 2 seconds every beacon, 15 seconds is the timeout
    command error_t Init.init() {
        int i;
        call Timer.startPeriodic(PERIOD);
        // set all to 0 initially
        for (i = 0; i < MAX_MOTES; i++) {
            LAST_ARRIVAL[i] = 0;
        }
        
        /* // checking if multiple */
        /* assert(TIMEOUT % PERIOD == 0); */
        // create a message with the correct message created
        ((BeaconMsg *) (call Packet.getPayload(&pkt, 0)))->src_node = TOS_NODE_ID;
        return SUCCESS;
    }

    event void Timer.fired() {
        // working with smaller int, safe because we're using seconds
        uint32_t delay = (call Timer.getdt()) / PERIOD;
        
        // this can be checked at every period
        // or every BEACON if we're sure that TIMEOUT is divisible by the BEACON
        check_timeout(delay);

        /// send a beacon every BEACON seconds
        if ((delay % BEACON) == 0) {
            broadcast_beacon();
        }
    }
    
    /** 
     * Broadcast the beacon message through the radio
     * 
     */
    void broadcast_beacon() {
        // setting to the global variable, make sure it's a pointer
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BeaconMsg)) == SUCCESS) 
            dbg("NeighBor", "broadcasting beacon message\n");
    }

    event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
        if (len == sizeof(BeaconMsg)) {
            BeaconMsg* beacon = (BeaconMsg *) payload;
            // when should this get called?
            uint32_t time = call Timer.getdt();
            LAST_ARRIVAL[beacon->src_node] = time;
            dbg("NeighBor", "got beacon %d at time %d\n", beacon->src_node, time);
        }
        return msg;
    }

    /** 
     * Check for every mote if there is a timeout
     * 
     * @param delay time passed from Timer start
     */
    void check_timeout(uint32_t delay) {
        int i;
        for (i = 0; i < MAX_MOTES; i++) {
            // in case it's still 0 we don't touch it at all, means that no answer arrived
            if (LAST_ARRIVAL[i] == 0)
                continue;

            if ((delay - LAST_ARRIVAL[i]) >= TIMEOUT) {
                removeNeighbor(i);
            }
            // adding has no effect if already present of course
            else {
                addNeighbor(i);
            }
        }
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
    }

    /** 
     * Set the bit corresponding to mote idx to 0
     * 
     * @param idx index of the mote
     */
    void removeNeighbor(uint8_t idx) {
        neighbors &= ~(1 << idx);
        dbg("NeighBor", "removing node %d to neighbors\n", idx);
    }
    
    /** 
     * Set the bit corresponding to mote idx to 1
     * 
     * @param idx 
     */
    void addNeighbor(uint8_t idx) {
        neighbors |= (1 << idx);
        dbg("NeighBor", "adding node %d to neighbors\n", idx);
    }
}
