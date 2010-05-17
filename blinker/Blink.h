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
    nx_nodeid_t dests;
    // The sender of the message
    nx_nodeid_t sender;
    // The sequential number of the message
    nx_seqno_t seqno;
    // The type of the message
    // [1=led instruction, 2=sensing request, 3=sensing data]
    nx_type_t type;
    // A specific instruction
    // - For led intruction: led-toggle bitmask
    // - For sensing: [1=light, 2=infrared, 3=humidity, 4=temperature]
    nx_instr_t instr;
    // Dataload for sensing results (empty for instructions)
    nx_data_t data;
} BlinkMsg;

/// a debug struct to allow serial-debugging
typedef nx_struct DebugMsg {
    // name for every field of data
    nx_uint8_t name[14];
    nx_uint8_t data[14];
} DebugMsg;

/// constants representing the communication channels used
enum {
    AM_BLINK = 6,
    AM_SERIAL_BLINK = 7,
    AM_BEACON = 8,
    AM_DEBUGMSG = 9,
    AM_RULTI_RTX,
    AM_RULTI_ACK
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

#define BLINK_GENERATE_INTERVAL_MS 1000

#endif
