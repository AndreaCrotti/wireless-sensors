/**
 * @file   Blink.h
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Wed Apr 28 12:02:18 2010
 * 
 * @brief  Interface for Blink program
 * 
 * 
 */

#ifndef BLINK_H
#define BLINK_H

#include "types.h"

/// we only need the id number of the message and the index of the led to turn on
typedef nx_struct BlinkMsg {
    // The destination of the message stored as a bitmask
    nx_nodes_t dests;
    // The sender of the message
    nx_nodeid_t sender;
    // The sequential number of the message
    nx_seqno_t seqno;
    // A specific instruction
    // - For led intruction: led-toggle bitmask
    nx_instr_t instr;
} BlinkMsg;

/// constants representing the communication channels used
enum {
    AM_BLINK = 6,
    AM_SERIAL_BLINK = 7
};

enum {
    AM_BLINKMSG = AM_SERIAL_BLINK
};

/// Message type constants
enum {
    MSG_INSTR = 1,
    MSG_SENS_REQ = 2,
    MSG_SENS_DATA = 3
};

/// Sensing type constants
enum {
    SENS_LIGHT = 1,
    SENS_INFRA = 2,
    SENS_HUMIDITY = 3,
    SENS_TEMP = 4
};

enum {
    RETRANSMIT_TIME = 50
};

#endif
