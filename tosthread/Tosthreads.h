/**
 * @file   Tosthreads.h
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Wed Apr 28 12:02:18 2010
 * 
 * @brief  Interface for the tosthread implementation of task 2.
 * 
 * 
 */

#ifndef TOSTHREADS_H
#define TOSTHREADS_H

#include "types.h"

/// we only need the id number of the message and the index of the led to turn on
typedef nx_struct CmdMsg {
    // The destination of the message stored as a bitmask
    nx_nodes_t dests;
    // The sender of the message
    nx_nodeid_t sender;
    // The sequential number of the message
    nx_seqno_t seqno;
    // A specific instruction
    // - For led intruction: led-toggle bitmask
    nx_instr_t instr;
} CmdMsg;

/// constants representing the communication channels used
enum {
    AM_TOSTHREADS = 6,
    AM_SERIAL_TOSTHREADS = 7
};

/// Constants for the Threads stack sizes
enum {
    BOOT_THREAD_STACK_SIZE = 100,
    RADIO_RECEIVE_THREAD_STACK_SIZE = 200,
    RADIO_SEND_THREAD_STACK_SIZE = 200, 
    SERIAL_SEND_THREAD_STACK_SIZE = 200,
    SERIAL_RECEIVE_THREAD_STACK_SIZE = 200
};

// TODO: What was that for??
/* enum { */
/*     AM_BLINKMSG = AM_SERIAL_BLINK */
/* }; */

#endif
