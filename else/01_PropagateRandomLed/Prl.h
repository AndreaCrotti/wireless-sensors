/**
 * \author oscar.dustmann@rwth-aachen.de
 */

#ifndef _PRL_H
#define _PRL_H

/// type of the sequence number
///
typedef uint8_t seqno_t;
/// type of the sequence number suitable for use in messages
///
typedef nx_uint8_t nx_seqno_t;
/// type of the instruction
///
typedef uint8_t instr_t;
/// type of the instruction suitable for use in messages
///
typedef nx_uint8_t nx_instr_t;

/// Message struct used by the prl protocol.
/// It includes an instruction and a sequence number.
typedef nx_struct {
  nx_instr_t instr;
  nx_seqno_t seqno;
} PrlMsg;

/// Active Message IDs used with the AMSenderC/AMReceiverC
///
enum AMID {
  AMID_PRL_MSG
};

/// Interval used by node 0 to periodically send commands.
///
#define PRL_SEND_INTERVAL_MS 10000

/// Shorthand for debugmessages.
///
#define DUMP(s) dbg("PrlC","@ %s : %s\n", sim_time_string(), s)

#endif
