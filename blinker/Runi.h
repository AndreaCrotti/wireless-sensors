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
 * Packet struct that defines the message structure sent by the runi primitive for acknowledgements.
 */
typedef nx_struct RuniAckMsg {
  nx_seqno_t seqno;
  nx_nodeid_t from;
} RuniMsg;

#endif
