
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


/// type of the sequence number
typedef uint8_t seqno_t;

/// type of the sequence number suitable for use in messages
typedef nx_uint8_t nx_seqno_t;

/// type of the instruction
typedef uint8_t instr_t;

/// type of the instruction suitable for use in messages
typedef nx_uint8_t nx_instr_t;

/// type of the node id
typedef uint16_t nodeid_t;

/// type of the node id suitable for use in messages
typedef nx_uint16_t nx_nodeid_t;

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
