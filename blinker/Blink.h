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
  nx_instr_t instr;
  nx_seqno_t seqno;
  // The destination of the message stored as a bitmask
  nx_nodeid_t dests;
} BlinkMsg;

enum {
  AM_BLINK = 6,
  AM_SERIAL_BLINK
};

#define BLINK_GENERATE_INTERVAL_MS 1000
#define AM_BLINKMSG AM_SERIAL_BLINK

#endif
