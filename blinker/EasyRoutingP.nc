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
 * We also keep a value on the parent to send the results only on the shortest path.
 *
 */

module EasyRoutingP {
    uses {
        interface Packet;
        interface AMSend as BeaconSend;
        interface Receive as BeaconReceive;

        interface AMSend as RelSend;
        interface Receive as RelReceive;

        // maybe seconds could be also enough
        interface Timer<TMilli> as Timer;
        interface PacketAcknowledgements;
        interface Leds;
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

/*******************************************************************************/
/* use a task to post the event that makes the list of neighbours update       */
/* Protocol is not symmetric, we send the command in broadcast but try to find */
/* the shortest path to give back the answer.                                  */
/* The shortest path is discovered using beacons                               */
/*******************************************************************************/
implementation {
    // could that be bigger in case of more motes?
    nodes_t neighbours = 0;
    // array keeping the last arrival time of the motes
    uint8_t LAST_ARRIVAL[MAX_MOTES];
    // structure keeping the message to forward
    message_t pkt;
    // 
    uint16_t periodCount = 0;

    // structure that keeps the hop count for every of the neighbors
    uint8_t HOP_COUNTS[MAX_MOTES];
    int8_t RSSI_VALS[MAX_MOTES];
    
    // number of hops of the closest to the base neighbour
    nodeid_t parent;

    void initGlobalVariables(void);
    void checkTimeout(uint32_t);
    void addNeighbour(nodeid_t);
    void removeNeighbour(nodeid_t);
    uint8_t isNeighbour(nodeid_t);
    void updateHops(uint8_t);
    uint8_t otherReceivers(nodeid_t);
    void selectBestParent(void);
    void updateRssi(nodeid_t, message_t *);
    
    // Using tasks we can't pass arguments to them and we must use instead global variables

    command error_t Init.init() {
        initGlobalVariables();
        call Timer.startPeriodic(PERIOD);
        return SUCCESS;
    }

    /** 
     * Initializing all the global variables used later
     * - HOP_COUNTS
     * - LAST_ARRIVAL
     * - Beacon message fields
     */
    void initGlobalVariables(void) {
        int i;
        BeaconMsg* message =  ((BeaconMsg *) (call Packet.getPayload(&pkt, 0)));
        
        // arrival time = 0 means we have never received a beacon from that node
        for (i = 0; i < MAX_MOTES; i++) {
            LAST_ARRIVAL[i] = 0;
        }

        // create a message with the correct message created
        message->src_node = TOS_NODE_ID;
        // the HOP_COUNTS keeps track of the minimal distances between every mote and the base station
        // This means that it's at first set to \infinity for all except the base station itself
        
        for (i = 0; i < MAX_MOTES; i++) {
            HOP_COUNTS[i] = MAX_HOPS;
        }

        // ROOT_NODE_ID is a special case, with distance 0 from itself of course
        if (TOS_NODE_ID == ROOT_NODE_ID) {
            // in the base station of course there can't be shortest paths
            message->hops_count = 0;
            HOP_COUNTS[ROOT_NODE_ID] = 0;
        } else {
            message->hops_count = MAX_HOPS;
        }
    }

    /** 
     * Broadcast the beacon package
     * 
     */
    task void broadcastBeacon(void) {
        call BeaconSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BeaconMsg));
    }

    event void Timer.fired() {
        periodCount++;
        // motes in timeout can be checked at every
        if ((periodCount % BEACON) == 0)
            post broadcastBeacon();
        checkTimeout(call Timer.getNow());
        call Leds.set(HOP_COUNTS[TOS_NODE_ID]);
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
            // Remove ourself from the destination list
            nodes_t destinations = bMsg->dests & ~(1 << TOS_NODE_ID);
            type_t type = bMsg->type;
            
            // We will not be a receiver anymore
            bMsg->dests = destinations;

            if (!otherReceivers(destinations))
                return SUCCESS;

            dbg("Routing", "Sending started with destinations %d\n", destinations);
            
            // only in the case of sensing data we really use the routing tree that we've created
            if (type == MSG_SENS_DATA) {
                dbg("Routing", "The parent is %d \n", parent);
                // sending only to parent node as a bitmask
                result = call RelSend.send((1 << parent), msg, len);
            }
            else {
                // If one of the destinations is not in our neighbour list, we make a broadcast,
                // otherwise a multi/unicast
                if ((destinations & ~neighbours) != 0) {
                    dbg("Routing", "Forwarding to all neighbours %d\n",  neighbours);
                    result = call RelSend.send(neighbours, msg, len);
                } else {
                    dbg("Routing", "Sending to nodes %d\n", destinations);
                    result = call RelSend.send(destinations, msg, len);
                }
            }

        } else {
            // Should normally not be used
            // For now, everything is only forwarded.
            dbg("Routing", "using third way\n");
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
        if ((destinations & ~(1 << TOS_NODE_ID)) == 0)
            return 0;
        else
            return 1;
    }

    /** 
     * Overriding of the receive function, takes a beacon and sets the last arrival of its origin
     */
    event message_t * BeaconReceive.receive(message_t *msg, void *payload, uint8_t len) {
        if (len == sizeof(BeaconMsg)) {
            BeaconMsg* beacon = (BeaconMsg *) payload;
            // when we got the message
            uint32_t arrivalTime = call Timer.getNow();
            
            uint8_t hops_count = beacon->hops_count;
            nodeid_t sender = beacon->src_node;

/* #ifndef TOSSIM             */
/*             int8_t rssi = call CC2420Packet.getRssi(msg); */
            
/*             if (rssi < -35) { */
/*                 return msg; */
/*             } */
/* #endif */

            // this should not happen anyway
            if (sender == TOS_NODE_ID) {
                return msg;
            }
            /* dbg("Routing", "Received beacon from %d\n", sender); */

            // set the time of the last arrival and then add the source node to the neighbours list
            /* dbg("Routing", "Received a beacon from node %d\n", beacon->src_node); */
            LAST_ARRIVAL[sender] = arrivalTime / PERIOD;
            addNeighbour(sender);

            // Should I always set it or should I check it first?
            // Maybe the mote has moved away from the base and then the path became longer
            HOP_COUNTS[sender] = hops_count;

            // update in the array of RSSI values
            updateRssi(sender, msg);
           
            if (TOS_NODE_ID != ROOT_NODE_ID) {
                // now select what is the best possible parent unless it's the root node
                selectBestParent();
            }
        }
        return msg;
    }

    void updateRssi(nodeid_t sender, message_t *msg) {
#ifndef TOSSIM        
        RSSI_VALS[sender] = call CC2420Packet.getRssi(msg);
#endif
    }

    /** 
     * Update the variable hops_count in the global variable pkt
     */
    void updateHops(uint8_t hops_count) {
        BeaconMsg* message = ((BeaconMsg *) (call Packet.getPayload(&pkt, 0)));
        uint8_t my_hop_count = hops_count + 1;
        if (my_hop_count == 0) // redundant test
            return;

        /* dbg("Routing", "Setting hop count to %d\n", hops_count+1); */

        // update the hop count to the minimum path given in input +1
        // careful here with variables with the same names - no kidding
        message->hops_count = my_hop_count;
        // distance of the mote with the minimal distance
        // this is not really needed maybe, it's just to keep the array complete
        HOP_COUNTS[TOS_NODE_ID] = my_hop_count;
    }

    event message_t * RelReceive.receive(message_t *msg, void *payload, uint8_t len) {
        if (len == sizeof(BlinkMsg)) {
            dbg("Routing", "Received a message\n");
            
            signal Receive.receive(msg, payload, len);
        }
        return msg;
    }

    /** 
     * Check for every mote if there is a timeout
     * 
     * @param delay time passed from Timer start
     */
    void checkTimeout(uint32_t delay) {
        int i;
        for (i = 0; i < MAX_MOTES; i++) {
            /* dbg("Routing", "delay = %d and LAST_ARRIVAL[%d] = %d\n", delay, i, LAST_ARRIVAL[i]); */
            
            // maybe it would be better to check only for the neighbours, but also adding 
            if ((isNeighbour(i) != 0) &&
                (((delay / PERIOD) - LAST_ARRIVAL[i]) >= TIMEOUT)) {
                removeNeighbour(i);
            }
        }
    }

    /** 
     * Scan over the list of neighbours to select the best parent
     * 
     */
    void selectBestParent() {
        nodeid_t i;
        nodeid_t closest = 0;
        uint8_t min = MAX_HOPS;

        for (i = 0; i < MAX_MOTES; i++) {
            if (isNeighbour(i)) {
#ifndef TOSSIM
                // in case I have the same hop count as the best actual value I also check the rssi
                if (HOP_COUNTS[i] == min) {
                    if (RSSI_VALS[i] > RSSI_VALS[closest]) {
                        min = HOP_COUNTS[i];
                        closest = i;
                    }
                }
#endif                    
                if (HOP_COUNTS[i] < min) {
                    min = HOP_COUNTS[i];
                    closest = i;
                }
            }
        }

        if (min < MAX_HOPS) {
            /* dbg("Routing", "Selecting parent %d with hop count %d\n", closest, min); */
            parent = closest;
            updateHops(min);
        }
    }

    /** 
     * Set the bit corresponding to mote idx to 0
     * 
     * @param idx index of the mote
     */
    void removeNeighbour(nodeid_t idx) {
        neighbours &= ~(1 << idx);
        // maybe we should check if it's really needed, if it's not there already
        // the other checks are not really needed

        /* dbg("Routing", "Node %d is in timeout\n", idx); */
        // that means that we are removing our parent, so look for the next best one
        // setting to the MAX the hop count because it's not reachable anymore
        HOP_COUNTS[idx] = MAX_HOPS;

        if (idx == parent) {
            /* dbg("Routing", "parent node has been removed from neighbour list\n"); */
            selectBestParent();
        }
    }

    /** 
     * Set the bit corresponding to mote idx to 1
     */
    void addNeighbour(nodeid_t idx) {
        neighbours |= (1 << idx);
    }

    uint8_t isNeighbour(nodeid_t idx) {
        return neighbours & (1 << idx);
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

    event void RelSend.sendDone(message_t* msg, error_t error) {
        signal AMSend.sendDone(msg, error);
    }

    // we don't need to signal anything in this case
    event void BeaconSend.sendDone(message_t* msg, error_t error) {
    }
}
