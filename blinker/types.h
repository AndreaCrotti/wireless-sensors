/**
 * This is a collection of types needed in several packet structs.

 * @file   types.h
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Wed May 12 19:02:18 2010
 * 
 * @brief  A collection of types needed in several packet structs.
 */


#ifndef TYPES_H
#define TYPES_H

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

/// A typedef for the message type
typedef uint8_t type_t;

/// A typedef for the message type for use in messages
typedef nx_uint8_t nx_type_t;

/// A typedef for the sensing data
typedef uint16_t data_t;

/// A typedef for the sensing data for use in messages
typedef nx_uint16_t nx_data_t;

#endif
