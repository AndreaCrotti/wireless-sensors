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
    uses {
        interface Packet;
        interface AMSend as BeaconSend;
        interface Receive as BeaconReceive;

        interface AMSend as RelSend;
        interface Receive as RelReceive;

        // maybe seconds could be also enough
        interface Timer<TMilli> as Timer;
        interface PacketAcknowledgements;
    }

#ifndef TOSSIM
    uses interface CC2420Packet;
#endif

    provides {
        interface Init;
        interface AMSend;
        interface Receive;
    }
}

// use a task to post the event that makes the list of neighbours update
// Protocol is not symmetric, we send the command in broadcast but try to find
// the shortest path to give back the answer.
// The shortest path is discovered using beacons

// TODO: if possible make only one structure or use some binary ways to do this
implementation {
    // could that be bigger in case of more motes?
    uint16_t neighbours = 0;
    // array keeping the last arrival time of the motes
    uint8_t LAST_ARRIVAL[MAX_MOTES];
    // structure keeping the message to forward
    message_t pkt;

    // structure that keeps the hop count for every of the neighbors
    uint8_t HOP_COUNTS[MAX_MOTES];

    // minimal number of hops to reach the base station
    uint8_t min_hops;
    
    uint16_t best_link;

    nodeid_t parent;

    void check_timeout(uint32_t);
    void init_msgs();
    void broadcast_beacon();
    void addNeighbour(nodeid_t);
    void removeNeighbour(nodeid_t);
    void updateHops(uint8_t);
    void checkParent(uint8_t, nodeid_t, message_t *);
    uint8_t otherReceivers(nodeid_t destinations);

    // Using tasks we can't pass arguments to them and we must use instead global variables

    command error_t Init.init() {
        int i;
        BeaconMsg* message =  ((BeaconMsg *) (call Packet.getPayload(&pkt, 0)));
        
        call Timer.startPeriodic(PERIOD);
        // set all to 0 initially
        for (i = 0; i < MAX_MOTES; i++) {
            LAST_ARRIVAL[i] = 0;
        }

        // create a message with the correct message created
        message->src_node = TOS_NODE_ID;
        best_link = 0;

        // Initializing the hop count structures
        // the HOP_COUNTS keeps track of the minimal distances between every mote and the base station
        // This means that it's at first set to \infinity for all except the base station itself

        for (i = 0; i < MAX_MOTES; i++) {
            HOP_COUNTS[i] = MAX_HOPS;
        }

        if (TOS_NODE_ID == 0) {
            // in the base station of course there can't be shortest paths
            HOP_COUNTS[0] = 0;
            message->hops_count = 0;
            min_hops = 0;
        } else {
            min_hops = MAX_HOPS;
            message->hops_count = MAX_HOPS;
        }
        return SUCCESS;
    }

    event void Timer.fired() {
        // motes in timeout can be checked at every 
        broadcast_beacon();
        check_timeout(call Timer.getNow());
        //dbg("Routing", "Now the neighbor list is %d\n", neighbours);
        /* { */
        /*     int i; */
        /*     for (i = 0; i < MAX_MOTES; i++) { */
        /*         dbg("Routing", "hops to %d = %d\n", i, HOP_COUNTS[i]); */
        /*     } */
        /* } */
    }

    /** 
     * Broadcast the beacon package
     * 
     */
    void broadcast_beacon() {
        call BeaconSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BeaconMsg));
    }

    /** 
     * Sends a message over the network by making use of the neighbourhood list.
     * If one destination is not in the neighborhood the message is forwarded to all neighbours.
     *
     * @param dest Should be AM_BROADCAST_ADDR in general, otherwise the package is passed directly to the reliability module.
     * @param msg The message to send.
     * @param len The length of the message.
     * 
     * @return status of the call
     */ 
    command error_t AMSend.send(am_addr_t dest, message_t* msg, uint8_t len) {
        error_t result;
        if (dest == AM_BROADCAST_ADDR) {
            // This is the general case, since the above layer should not care, how the 
            // message is delivered.
            
            // Get the destination inside BlinkMsg
            BlinkMsg* bMsg = (BlinkMsg *)(call Packet.getPayload(msg, 0));
            nodes_t destinations = bMsg->dests;

            dbg("Routing", "Sending started with destinations %d\n", destinations);
            
            if (!otherReceivers(destinations))
                return SUCCESS;

            // If one of the destinations is not in our neighbour list, we make a broadcast,
            // otherwise a multi/unicast
            if ((destinations & ~neighbours) != 0) {
                dbg("Routing", "Forwarding to all neighbours %d\n",  neighbours);
                result = call RelSend.send(neighbours, msg, len);
            } else {
                dbg("Routing", "Sending to nodes %d\n", destinations);
                result = call RelSend.send(destinations, msg, len);
            }
        } else {
            // Should normally not be used
            // For now, everything is only forwarded.
            result = call RelSend.send(dest, msg, len);
        }

        return result;
    }

    /**
     * This function checks, whether there is another receiver than this node.
     *
     * @param destinations The destination bitmask to check.
     * @return 1, if there is another destination and 0 otherwise.
     */
    uint8_t otherReceivers(nodeid_t destinations){
        if((destinations & ~(1 << TOS_NODE_ID)) == 0)
            return 0;
        else 
            return 1;
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
            uint32_t arrivalTime = call Timer.getNow();
            uint8_t hops_count = beacon->hops_count;
            nodeid_t sender = beacon->src_node;

            // set the time of the last arrival and then add the source node to the neighbours list
            /* dbg("Routing", "Received a beacon from node %d\n", beacon->src_node); */
            LAST_ARRIVAL[sender] = arrivalTime / PERIOD;
            addNeighbour(sender);

            // Should I always set it or should I check it first?
            // Maybe the mote has moved away from the base and then the path became longer
            HOP_COUNTS[sender] = hops_count;
            /* dbg("Routing", "Now neighbours list %d\n", neighbours); */
            checkParent(hops_count, sender, msg);
        }
        return msg;
    }

    
    /** 
     * Checks if the last node was closer to the base station or if
     * at same dinstance if the signal is better than the last best one
     *
     */
    void checkParent(uint8_t hops_count, nodeid_t sender, message_t *msg) {
        /* dbg("Routing", "Hops count = %d and min_hops = %d\n", hops_count, min_hops); */
        if (hops_count < min_hops) {
            // we should enter here very quickly in theory
            /* dbg("Routing", "Found a shortest path to the base station from node %d\n", sender); */
            // then we found a shortest path to the base station
            updateHops(hops_count);
            dbg("Routing", "Now the parent is %d\n", sender);
            parent = sender;
        }

        // when using the device we can also check the quality of the link
#ifndef TOSSIM
        {
            int8_t rssi_val;
            // in case it's equal to the minimum we must check the quality of the link
            // otherwise we can just keep the last best one and it still works fine
            if (hops_count == min_hops) {
                rssi_val = call CC2420Packet.getRssi(msg);
                dbg("Routing", "Equal distance, now checking for RSSI value");
                if (rssi_val < best_link) {
                    parent = sender;
                }
            }
        }
#endif
    }
    
    /** 
     * Update the variable hops_count in the global variable pkt
     */
    void updateHops(uint8_t hops_count) {
        BeaconMsg* message =  ((BeaconMsg *) (call Packet.getPayload(&pkt, 0)));
        // update the hop count to the minimum path given in input +1
        // careful here with variables with the same names
        message->hops_count = hops_count + 1;
        // minimal number of hops to reach the base from here without considering the node itself
        min_hops = hops_count;
    }

    event message_t * RelReceive.receive(message_t *msg, void *payload, uint8_t len) {
        dbg("Routing", "Received message not fully");
        if (len == sizeof(BlinkMsg)) {
            // just forward the message
            dbg("Routing", "Received a message");
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
            
            /* dbg("Routing", "delay = %d and LAST_ARRIVAL[i] = %d\n", delay, LAST_ARRIVAL[i]); */
            // adding and removing have no effect if they are already in or out the list
            if (((delay / PERIOD) - LAST_ARRIVAL[i]) >= TIMEOUT) {
                removeNeighbour(i);
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
