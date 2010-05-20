#include "printf.h"
#include "EasyRouting.h"

/**
 * @file   EasyRouting.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Tue May 11 17:16:24 2010
 * 
 * @brief  Module to keep the neighbour list of every mote.
 * We use the RADIO package to send beacons through the wireless
 * The neighbour list is simply a 16 bit integer mask
 * This EasyRouting protocol uses a reliable protocol for commands
 * and an unreliable protocol for discovering the neighbours.
 * 
 */

// TODO: providing an interface for radio communication which in truth will just call the reliable
// communication module
// TODO: implement also an unreliable protocol otherwise the reliable interface could override my setting

generic module EasyRoutingP (uint8_t test) {
    uses interface Packet;
    uses interface AMSend as BeaconSend;
    uses interface Receive as BeaconReceive;

    uses interface AMSend as RelSend;
    uses interface Receive as RelReceive;

    // maybe seconds could be also enough
    uses interface Timer<TMilli> as Timer;
    
    provides interface Init;
    provides interface AMSend;
    provides interface Receive;
}

// use a task to post the event that makes the list of neighbours update
// Protocol is not symmetric, we send the command in broadcast but try to find
// the shortest path to give back the answer.
// The shortest path is discovered using beacons

implementation {
    // could that be bigger in case of more motes?
    uint16_t neighbours = 0;
    
    /// array keeping the last arrival time of the motes
    nodeid_t LAST_ARRIVAL[MAX_MOTES];
    /// structure keeping the message to forward
    message_t pkt;

    void check_timeout(uint32_t);
    void init_msgs();
    void broadcast_beacon();
    void addNeighbour(nodeid_t);
    void removeNeighbour(nodeid_t);
    
    command error_t Init.init() {
        int i;
        call Timer.startPeriodic(PERIOD);
        // set all to 0 initially
        for (i = 0; i < MAX_MOTES; i++) {
            LAST_ARRIVAL[i] = 0;
        }

        // create a message with the correct message created
        ((BeaconMsg *) (call Packet.getPayload(&pkt, 0)))->src_node = TOS_NODE_ID;
        return SUCCESS;
    }

    event void Timer.fired() {
        // working with smaller int, safe because we're using seconds
        uint32_t delay = (call Timer.getdt()) / PERIOD;
        printf("in easyrouting timer\n");
        printfflush();

        // motes in timeout can be checked at every 
        // or every BEACON if we're sure that TIMEOUT is divisible by the BEACON
        if ((delay % BEACON) == 0) {
            broadcast_beacon();
        }
        // Does it make any difference if called before or after the IF?
        check_timeout(delay);
    }

    /** 
     * Broadcast the beacon package
     * 
     */
    void broadcast_beacon() {
        call BeaconSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(pkt));
    }

    /** 
     * Implementation of send call using the neighbour list as destination
     * 
     * @param dest Destination of the message, we can just skip it
     * @param msg 
     * @param len 
     * 
     * @return status of the call
     */ 
    command error_t AMSend.send(am_addr_t dest, message_t* msg, uint8_t len) {
        // we should just discard the destination since we look in our own neighbour table
        // just modify the message with the correct stuff and then call or post the sending
                
        // change the name for easier understanding
        if (dest == AM_BROADCAST_ADDR)
            call RelSend.send(neighbours, msg, len);
        
        else {
            dest = neighbours & (1 << dest);

            if (dest != 0) {
                call RelSend.send(dest, msg, len);
            }
            // otherwise sends to all neighbours
            else {
                call RelSend.send(neighbours, msg, len);
            }
        }
        return SUCCESS;
    }

    // Just calling the lower layer
    command error_t AMSend.cancel(message_t* msg) {
        return call AMSend.cancel(msg);
    }

    command uint8_t AMSend.maxPayloadLength() {
        return call AMSend.maxPayloadLength();
    }
    
    command void* AMSend.getPayload(message_t* m, uint8_t len) {
        return call AMSend.getPayload(m, len);
    }

    /** 
     * Overriding of the receive function, takes a beacon and sets the last arrival of its origin
     */
    event message_t * BeaconReceive.receive(message_t *msg, void *payload, uint8_t len) {
        if (len == sizeof(BeaconMsg)) {
            BeaconMsg* beacon = (BeaconMsg *) payload;
            uint32_t time = call Timer.getdt();
            // set the time of the last arrival
            LAST_ARRIVAL[beacon->src_node] = time;
        }
        return msg;
    }

    event message_t * RelReceive.receive(message_t *msg, void *payload, uint8_t len) {
        if (len == sizeof(BlinkMsg)) {
            // just forward the message
            signal Receive.receive(msg, payload, len);
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
            // in case it's still 0 we don't touch it at all, means that no beacons from node i arrived
            if (LAST_ARRIVAL[i] == 0)
                continue;

            // adding and removing have no effect if they are already in or out the list
            if ((delay - LAST_ARRIVAL[i]) >= TIMEOUT) {
                removeNeighbour(i);
            }
            else {
                addNeighbour(i);
            }
        }
    }

    event void RelSend.sendDone(message_t* msg, error_t error) {
        signal AMSend.sendDone(msg, error);
    }

    // we don't need to signal anything in this case
    event void BeaconSend.sendDone(message_t* msg, error_t error) {
    }

    /** 
     * Set the bit corresponding to mote idx to 0
     * 
     * @param idx index of the mote
     */
    void removeNeighbour(nodeid_t idx) {
        neighbours &= ~(1 << idx);
    }
    
    /** 
     * Set the bit corresponding to mote idx to 1
     * 
     * @param idx 
     */
    void addNeighbour(nodeid_t idx) {
        neighbours |= (1 << idx);
    }
}