/**
 * Implementation for the prl application.
 * Prl stands for 'propagate random led'.
 * 
 * Note: The invariants given in this file (in curly braces) for
 *       member-variables are true outside of an eventhandler
 *       (they may vary temporally) in idle mode.
 * 
 * \author oscar.dustmann@rwth-aachen.de
 **/

#include <Timer.h>
#include "Prl.h"

module PrlC {
  uses interface Timer<TMilli> as Timer;
  uses interface Leds;
  uses interface Boot;
  uses interface Random;
  uses interface Packet;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMSplitControl;
}
implementation {
  /// The current configuration of the leds.
  /// { ledMask & ~0b111 == 0 }
  uint8_t ledMask = 0;
  /// Sequence number last encountered. The first message will
  /// have a seqno of '1'.
  seqno_t sn = 0;
  /// Total packets received.
  /// { sn === prec   mod min(sizeof(seqno_t),16) }
  uint16_t prec = 0;
  /// Generic message buffer for the used send/recv interfaces.
  /// We do not write directly but need the static memory allocation.
  message_t mbuf;
  /// Per-node configurable forward address.
  /// Set to AM_BROADCAST_ADDR to signal broadcasts rather than unicasts.
  am_addr_t forward = AM_BROADCAST_ADDR;

  /**
   *  Boot handler. Takes care of starting jobs and such.
   */
  event void Boot.booted() {
    call AMSplitControl.start();
  }

  /**
   *  Helper function to start a one-shot timer for node 0 and do
   *  nothing for other nodes.
   */
  void timer(void) {
    if (!TOS_NODE_ID) {
      call Timer.startOneShot(PRL_SEND_INTERVAL_MS);
    }
  }

  /**
   *  AM scheduler boot notification. We use this to actually start
   *  our application which requires the AM i/o.
   *
   *  \param error SUCCESS if the component was successfully turned on, FAIL otherwise
   */
  event void AMSplitControl.startDone(error_t err) {
    if (err == SUCCESS) {
      timer();
    } else {
      call AMSplitControl.start();
    }
  }
  /**
   *  AM scheduler shutdown notification. We are required to implement this
   *  but never use it.
   *
   *  \param error SUCCESS if the component was successfully turned off, FAIL otherwise
   */
  event void AMSplitControl.stopDone(error_t err) {}

  /**
   *  Helper function to send a message.
   *  This function will take care of setting the seqno accordingly.
   *  Passing the struct by-value and not by-reference (i.e. pointer) has
   *  the benefit that we make a hard copy of the data, allowing the struct
   *  used by the caller to be reused DIRECTLY after this call (not just
   *  when AMSend.send finishes its work).
   *
   *  \param m The PrlMsg struct you want to send. \see Prl.h.
   */
  void send(PrlMsg m) {
    *((PrlMsg*)(call Packet.getPayload(&mbuf, 0))) = m;
    sn = m.seqno;
    while (call AMSend.send(forward, &mbuf, sizeof(PrlMsg)) == FAIL);
  }

  /**
   *  AM send event handler. When the transmission is out we will
   *  start the timer for node 0. If 'send' was unsuccessfull we just
   *  try again.
   *
   *  \param msg the packet which was submitted as a send request
   *  \param error SUCCESS if it was sent successfully, FAIL if it was not, ECANCEL if it was cancelled
   */
  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS)
      timer();
    else
      while (call AMSend.send(forward, msg, sizeof(PrlMsg)) == FAIL);
  }

  /**
   *  Helper function to execute a command received from a neighbour.
   *  It will modify our internal state and then flip the leds accordingly.
   *
   *  \param instr The command (instruction) received.
   */
  void exec(instr_t instr) {
    dbg("PrlC_l","@%s, pr=%u, sn=%u; leds: %x ^ %x --> %x\n",sim_time_string(),prec,sn,ledMask,instr,ledMask^instr);
    ledMask ^= instr & 7;
    call Leds.set(ledMask);
  }

  /**
   *  For node 0, we have set up a timer to tell us when to generate and
   *  distribute a new command.
   */
  event void Timer.fired() {
    instr_t rnd;
    DUMP("Timer fired");
    rnd = (instr_t)(call Random.rand16());
    rnd = 1 << (rnd % 3);
    exec(rnd);
    // XXX nx_ causes 'missing braces around initializer' warning.
    // why? it is valid c!
    send((PrlMsg){.instr = rnd,.seqno = ++sn});
  }

  /**
   *  Receive event handler. All messages are flooded through the network.
   *  We will be informed of a new message by this event. We decide if the
   *  message is valid in terms of type and seqno. And - if so - execute
   *  and propagate the message.
   *
   *  \param msg the receied packet
   *  \param payload a pointer to the packet's payload
   *  \param len The length of the data region pointed to by payload
   *  \return a packet buffer for the stack to use for the next received packet.
   */
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    if (len == sizeof(PrlMsg)) {
      PrlMsg* m = (PrlMsg*)payload;
      if (m->seqno > sn || (!m->seqno && sn)) { // catch overflows
        prec++;
        exec(m->instr);
        send(*m);
        DUMP("packet forwarded");
      } else {
        dbg("PrlC","@ %s : packet dropped: %u <= %u, DIFF: %u\n", sim_time_string(), m->seqno, sn, sn - m->seqno);
      }
    } else {
      DUMP("PACKET OF WRONG SIZE!");
    }
    return msg;
  }
}

