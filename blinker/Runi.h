/**
 * @file   Runi.h
 * @author Andrea Crotti, Marius Gysla
 * @author Oscar Dustmann
 * @date   Tue May 11 15:31:18 2010
 * 
 * @brief  Component that implements reliable one hop unicast
 * 
 */

#ifndef RUNI_H
#define RUNI_H

#include "types.h"

/**
 * Packet struct that defines the message structure sent by the runi primitive. It is APPENDED to the original payload.
 */
typedef nx_struct RuniMsg {
  nx_seqno_t seqno;
  nx_nodeid_t from;
} RuniMsg;

// transmissions include the initial transmission. Hence, 5 means up to 4 retransmissions
#define RUNI_MAX_TRANSMISSIONS 5

// retransmit every second
#define RUNI_RTX_INTERVAL_MS 1000

// how many seqnos are we supposed to save?
#define RUNI_SEQNO_COUNT 10

typedef struct {
  am_addr_t dest,
  message_t* msg,
  uint8_t len
} SendArguments;

#endif
