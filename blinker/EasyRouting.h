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
    TIMEOUT = 15,
    PERIOD = 1000
};

/// structure of the beacon message, both for brooacast and receiving
typedef nx_struct BeaconMsg {
    nx_uint8_t src_node;
} BeaconMsg;

#endif