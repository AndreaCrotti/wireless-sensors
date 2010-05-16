#include "Rulti.h"

/**
 * Implementation of the reliable one-hop multicast primitive.
 * We will transmit a message repeatedly until we receive an acknowledgement.
 * 
 * @file BlinkP.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date So 2. Mai 21:14:53 CEST 2010
 **/

module RultiP {
    // required interfaces to manage and send/receive packets
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend as PayloadSend;
    uses interface Receive as PayloadSend;
    uses interface AMSend as AckSend;
    uses interface Receive as AckReceive;
    uses interface Random;
    uses interface ParameterInit<uint16_t> as SeedInit;

    // additional components
    uses interface Timer<TMilli> as RtxTimer;
    uses interface Timer<TMilli> as AckTimer;
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
    message_t pkt;
    message_t ackpkt;
    seqno_t receivedSeqno[RULTI_SEQNO_COUNT];
    uint8_t lastSeqnoIdx = RULTI_SEQNO_COUNT-1;

    // helper functions

    SendArguments sendPayloadArguments;
    task void payloadSend() {
        if (transmissions && (call PayloadSend.send(sendPayloadArguments.dest,sendPayloadArguments.msg,sendPayloadArguments.len) != SUCCESS))
            post payloadSend();
    }
    /**
     * Will perform no check whatsoever and just plain retransmit the message.
     * IT IS YOUR RESPONSIBILITY TO CHECK EVERYTHING ELSE!
     */
    void retransmit(void) {
        transmissions++;
        post payloadSend();
    }

    /** 
     * Stop the communication
     * 
     */
    void stopRtx(void) {
        transmissions = 0;
        call RtxTimer.stop();
    }

    // used interfaces
    event void RtxTimer.fired() {
        if (transmissions < RULTI_MAX_TRANSMISSIONS) {
            retransmit();
        }
        else {
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
    event void AckTimer.fired() {
        post ackSend();
    }
    
    SendArguments sendAckArguments;
    char ackSendBusy = 0;
    task void ackSend() {
        if (call AckSend.send(sendAckArguments.dest,sendAckArguments.msg,sendAckArguments.len) != SUCCESS)
            post ackSend();
    }

    event message_t* PayloadReceive.receive(message_t* message, void* payload, uint8_t len) {
        if (ackSendBusy)
            // this is somewhat ugly, but right now, we just cannot handle the transmission, so we will wait for the next one
            return message;
        RultiMsg* prm = payload + len-sizeof(RultiMsg);
        if (!prm->seqno)
            return message; // drop invalid packet (invalid seqno)
        *(RultiMsg*)(call Packet.getPayload(&ackpkt, 0)) = {
            .from = TOS_NODE_ID,
            .seqno = prm->seqno
        };

        ackSendBusy = 1;
        sendAckArguments = {.dest = prm->from, .msg = &ackpkt, .len = sizeof(RultiMsg)};
        uint16_t timeDelta = Random.rand16();
        call AckTimer.startOneShot(timeDelta % RULTI_ACK_DELTA_MS);

        // in case the message we just acknowledged was already reported
        // to the user, we should not do that again!
        char duplicate = 0;
        uint8_t i = 0;
        while (i < RULTI_SEQNO_COUNT) {
            if (duplicate = (receivedSeqno[i] == prm->seqno))
                i = RULTI_SEQNO_COUNT;
            else
                i++;
        }
        if (!duplicate) {
            lastSeqnoIdx = (lastSeqnoIdx+1)%RULTI_SEQNO_COUNT;
            receivedSeqno[lastSeqnoIdx] = rm->seqno;
            signal Receive.receive(message,payload,len);
        }
        return message;
    }
    
    event void AckSend.sendDone(message_t* m, error_t err) {
        ackSendBusy = 0;
    }

    event message_t* AckReceive.receive(message_t* message, void* payload, uint8_t len) {
        stopRtx();
        signal AMSend.sendDone(originalMessage, SUCCESS); // as far as we are concerned
    }

    // provided interfaces
    command error_t AMSend.send(am_addr_t dest, message_t* msg, uint8_t len) {
        if (transmissions)
            return EBUSY; // EBUSY: "The underlying system is busy; retry later"

        //if (dest == AM_BROADCAST_ADDR)
        //    return EINVAL; // EINVAL: "An invalid parameter was passed"

        if (!originalMessage) // we have not been initialised yet
            SeedInit.init(TOS_NODE_ID);
        
        sendPayloadArguments = {.dest = dest, .msg = &pkt, .len = len+sizeof(RultiMsg)};
        void* i = Packet.getPayload(&pkt,0);
        // no side effect because only the local copy of the value 'msg', 'len' is changed
        // i.e. that's the stuff on the stack
        while (len--)
            *i++ = *msg++;

        // glue the original payload and our own together
        len = sizeof(RultiMsg);
        // it's important to pre-increment seqno, since 0 is invalid
        RultiMsg rm = {.seqno = call Random.rand8(), .from = TOS_NODE_ID};
        RultiMsg* prm = &rm;

        while (len--)
            *i++ = *prm++;

        originalMessage = msg;
        retransmit();
        uint16_t timeDelta = call Random.rand16();
        call RtxTimer.startPeriodic(RULTI_RTX_INTERVAL_MS + (timeDelta % RULTI_RTX_DELTA_MS));

        return SUCCESS;
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

