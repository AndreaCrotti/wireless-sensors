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
    // The sequential number of the message
    nx_seqno_t seqno;
    // A specific instruction
    // - For led intruction: led-toggle bitmask
    nx_instr_t instr;
} CmdMsg;

enum {
    BRECEIVE_TIMEOUT = 1000,
    BSEND_SLEEP = 3000
};

/// constants representing the communication channels used
enum {
    AM_RADIO_TOSTHREADS = 6,
    AM_SERIAL_TOSTHREADS = 7
};

enum {
    THREAD_STACK_RADIO_RECEIVE = 300,
    THREAD_STACK_RADIO_SEND = 300
};

enum {
    AM_CMDMSG = 7
};

/// Constants for the Threads stack sizes
enum {
    BOOT_THREAD_STACK_SIZE = 100
}; enum {
    RADIO_RECEIVE_THREAD_STACK_SIZE = 200
}; enum {
    RADIO_SEND_THREAD_STACK_SIZE = 200
}; enum {
    SERIAL_SEND_THREAD_STACK_SIZE = 200
}; enum {
    SERIAL_RECEIVE_THREAD_STACK_SIZE = 200
}; enum {
    QUEUE_SIZE = 5
};


#endif
