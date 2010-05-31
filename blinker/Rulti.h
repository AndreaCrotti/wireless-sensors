/**
 * @file   Rulti.h
 * @author Andrea Crotti, Marius Gysla
 * @author Oscar Dustmann
 * @date   Su May 16 17:31:18 2010
 * 
 * @brief  Component that implements reliable one hop multicast
 * 
 */

#ifndef RULTI_H
#define RULTI_H

#include "types.h"

/**
 * Packet struct that defines the message structure sent by the rulti primitive. It is APPENDED to the original payload.
 */
typedef nx_struct RultiMsg {
    nx_seqno_t seqno;
    nx_nodes_t to;
} RultiMsg;

enum{
    // transmissions include the initial transmission. Hence, 5 means up to 4 retransmissions
    RULTI_MAX_TRANSMISSIONS = 10,

    // retransmit every second +- 100
    RULTI_RTX_INTERVAL_MS = 450,
    // add a random number from [0..200) to every tx timer interval
    RULTI_RTX_DELTA_MS = 100,
    // wait a random number of milliseconds in [0..300) to acknowledge the multicast
    RULTI_ACK_DELTA_MS = 80,

    // how many seqnos are we supposed to save?
    RULTI_SEQNO_COUNT = 10
};

#endif
