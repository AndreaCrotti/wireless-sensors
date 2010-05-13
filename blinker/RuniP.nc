#include "Runi.h"

/**
 * Implementation of the reliable one-hop unicast primitive.
 * We will transmit a message repeatedly until we receive an acknowledgement.
 * 
 * @file BlinkP.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date So 2. Mai 21:14:53 CEST 2010
 **/

module RuniP {
    // required interfaces to manage and send/receive packets
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend as PayloadSend;
    uses interface Receive as PayloadSend;
    uses interface AMSend as AckSend;
    uses interface Receive as AckReceive;
    uses interface Timer;
    uses interface Random;
    uses interface ParameterInit<uint16_t> as SeedInit;

    // additional needed components
    uses interface Timer<TMilli> as Timer;
    uses interface CC2420Packet;

    provides interface AMSend;
    provides interface Receive;
}
/*
 * TODO TODO TODO TODO TODO TODO TODO
 * TODO                          TODO
 * TODO      DOCUMENT THIS!      TODO
 * TODO                          TODO
 * TODO TODO TODO TODO TODO TODO TODO
 */
implementation {
  // member variables
  unsigned char transmissions = 0;
  message_t* originalMessage = NULL;
  uint8_t messagelength;
  am_addr_t messagedest;
  message_t pkt;
  message_t ackpkt;
  seqno_t receivedSeqno[RUNI_SEQNO_COUNT];
  uint8_t lastSeqnoIdx = RUNI_SEQNO_COUNT-1;
  SendArguments sendAckArguments;

  // helper functions

  /**
   * Will perform no check whatsoever and just plain retransmit the message.
   * IT IS YOUR RESPONSIBILITY TO CHECK EVERYTHING ELSE!
   */
  error_t retransmit(void) {
    transmissions++;
    return call PayloadSend.send(messagedest,&pkt,messagelength);
  }

  void stopRtx(void) {
    transmissions = 0;
    call Timer.stop();
  }

  // used interfaces
  event void Timer.fired() {
    if (transmissions < RUNI_MAX_TRANSMISSIONS) {
      retransmit();
    } else {
      stopRtx();
      signal AMSend.sendDone(originalMessage,ENOACK);
    }
  }
  event void PayloadSend.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) {
      stopRtx();
      signal AMSend.sendDone(originalMessge,err);
    }
  }
  task void ackSend() {
    if (call AckSend.send(sendAckArguments.dest,sendAckArguments.msg,sendAckArguments.len) != SUCCESS)
      post ackSend();
  }
  event message_t* PayloadReceive.receive(message_t* message, void* payload, uint8_t len) {
    RuniMsg* prm = payload + len-sizeof(RuniMsg);
    if (!prm->seqno)
      return message; // drop invalid packet (invalid seqno)
    *(RuniMsg*)(call Packet.getPayload(&ackpkt, 0)) = {
      .from = TOS_NODE_ID,
      .seqno = prm->seqno
    };
    sendAckArguments = {.dest = prm->from, .msg = &ackpkt, .len = sizeof(RuniMsg)};
    post ackSend();

    // in case the message we just acknowledged was already reported
    // to the user, we should not do that again!
    char duplicate = 0;
    for (uint8_t i = 0; i < RUNI_SEQNO_COUNT; i++) {
      if (duplicate = (receivedSeqno[i] == prm->seqno))
        i = RUNI_SEQNO_COUNT; // exit the loop
    }
    if (!duplicate) {
      lastSeqnoIdx = (lastSeqnoIdx+1)%RUNI_SEQNO_COUNT;
      receivedSeqno[lastSeqnoIdx] = rm->seqno;
      signal Receive.receive(message,payload,len);
    }
    return message;
  }
  event void AckSend.sendDone(message_t* m, error_t err) {}
  event message_t* AckReceive.receive(message_t* message, void* payload, uint8_t len) {
    stopRtx();
    signal AMSend.sendDone(originalMessage,SUCCESS); // as far as we are concerned
  }

  // provided interfaces
  command error_t AMSend.send(am_addr_t dest, message_t* msg, uint8_t len) {
    if (transmissions)
      return EBUSY; // EBUSY: "The underlying system is busy; retry later"
    if (dest == AM_BROADCAST_ADDR)
      return EINVAL; // EINVAL: "An invalid parameter was passed"

    if (!originalMessage) // we have not been initialised yet
      SeedInit.init(TOS_NODE_ID);
    messagedest = dest;
    void* i = Packet.getPayload(&pkt,0);
    messagelength = len+sizeof(RuniMsg);
    // no side effect because only the local copy of the value 'msg', 'len' is changed
    // i.e. that's the stuff on the stack
    while (len--)
      *i++ = *msg++;
    // glue the original payload and our own together
    len = sizeof(RuniMsg);
    // it's important to pre-increment seqno, since 0 is invalid
    RuniMsg rm = {.seqno = call Random.rand8(), .from = TOS_NODE_ID};
    RuniMsg* prm = &rm;
    while (len--)
      *i++ = *prm++;
    originalMessage = msg;
    error_t result = retransmit();
    call Timer.startPeriodic(RUNI_RTX_INTERVAL_MS);
    if (result != SUCCESS)
      stopRtx();
    return result;    
  }
  command error_t AMSend.cancel(message_t* msg) {
    stopRtx();
    return call PayloadSend.cancel(msg);
  }
  command uint8_t AMSend.maxPayloadLength() {
    return call PayloadSend.maxPayloadLength();
  }
  command void* AMSend.getPayload(message_t* m, uint8_t len) {
    return call PayloadSend.getPayload(m,len);
  }

}

