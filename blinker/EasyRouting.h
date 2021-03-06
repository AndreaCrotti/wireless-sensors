/**
 * @file   NeighBor.h
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Wed May 12 10:43:49 2010
 * 
 * @brief  Constants for neighbor discovery protocol
 * 
 * 
 */

#ifndef EASY_ROUTING_H
#define EASY_ROUTING_H

enum {
    BEACON = 2,
    PERIOD = 1000,
    TIMEOUT = 10
};

enum {
    MAX_HOPS = 255
};

enum {
    ROOT_NODE_ID = 0
};

/// Beacon message is used to create the topology of the network
typedef nx_struct BeaconMsg {
    nx_nodeid_t src_node;
    // number of hops from the base-station
    nx_uint8_t hops_count;
} BeaconMsg;

#endif
