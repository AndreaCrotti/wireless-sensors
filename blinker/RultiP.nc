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
    uses interface AMSend as PayloadSend;
    uses interface Receive as PayloadReceive;
    uses interface AMSend as AckSend;
    uses interface Receive as AckReceive;
    uses interface Random;
    uses interface ParameterInit<uint16_t> as SeedInit;

    uses interface Leds;

    // additional components
    uses interface Timer<TMilli> as RtxTimer;
    uses interface Timer<TMilli> as AckTimer;

    provides interface AMSend;
    provides interface Receive;
}
implementation {
    // member variables
    unsigned char transmissions = 0;
    message_t* originalMessage = NULL;
    message_t pkt;
    message_t ackpkt;
    seqno_t receivedSeqno[RULTI_SEQNO_COUNT];
    uint8_t lastSeqnoIdx = RULTI_SEQNO_COUNT-1;
    nx_nodes_t* receivers;

    /* ******************************** private helpers ******************************** */

    SendArguments sendPayloadArguments;
    /**
     * Send the payload. If sending fails, the task will be reposted.
     *
     * \param sendPayloadArgumenst [logical] the exact values to pass to the AMSend.send command.
     */
    task void payloadSend() {
        if (transmissions && (call PayloadSend.send(sendPayloadArguments.dest,sendPayloadArguments.msg,sendPayloadArguments.len) != SUCCESS))
            post payloadSend();
    }
    /**
     * Will perform no check whatsoever and just plain retransmit the message.
     * IT IS YOUR RESPONSIBILITY TO CHECK EVERYTHING ELSE!
     */
    void retransmit(void) {
        call Leds.led0Toggle();
        transmissions++;
        post payloadSend();
    }

    /** 
     * Stop the communication.
     */
    void stopRtx(void) {
        receivers = NULL;
        transmissions = 0;
        call RtxTimer.stop();
    }

    SendArguments sendAckArguments;
    char ackSendBusy = 0;
    /**
     * Send an acknowledgement. If sending fails, the task will be reposted.
     *
     * \param sendAckArguments [logical] the exact values to pass to the AMSend.send command.
     */
    task void ackSend() {
        call Leds.led2Toggle();
        if (call AckSend.send(sendAckArguments.dest,sendAckArguments.msg,sendAckArguments.len) != SUCCESS)
            post ackSend();
    }


    /* ******************************** used interfaces ******************************** */

    /**
     * Start retransmission if we did not exceed the maximal number of retransmissions. Otherwise stop.
     */
    event void RtxTimer.fired() {
        if (transmissions < RULTI_MAX_TRANSMISSIONS) {
            retransmit();
        } else {
            stopRtx();
            signal AMSend.sendDone(originalMessage,ENOACK);
        }
    }
    /**
     * Relay the sendDone error to our user if sending was NOT successfull.
     */
    event void PayloadSend.sendDone(message_t* m, error_t err) {
        if (err != SUCCESS) {
            stopRtx();
            signal AMSend.sendDone(originalMessage,err);
        }
    }
    /**
     * This timer is needed to add a random delay between receiving a message and acknowledging it (avoid interference).
     */
    event void AckTimer.fired() {
        post ackSend();
    }
    /**
     * Event will be triggered we notice a payload. We still have to check if it is valid and is adressed to us.
     */
    event message_t* PayloadReceive.receive(message_t* message, void* payload, uint8_t len) {
        RultiMsg* prm;
        RultiMsg* pld;
        uint16_t timeDelta;
        if (ackSendBusy)
            // this is somewhat ugly, but right now, we just cannot handle the transmission, so we will wait for the next one
            return message;
        prm = payload + len-sizeof(RultiMsg);
        if (!(prm->to & (1<<TOS_NODE_ID)))
            // that transmission was not for us
            return message;
        if (!prm->seqno)
            // drop invalid packet (invalid seqno)
            return message;
        pld = (RultiMsg*)(call Packet.getPayload(&ackpkt, 0));
        pld->seqno = prm->seqno;
        pld->from = TOS_NODE_ID;
        pld->to = (1<<prm->from);


        ackSendBusy = 1;
        sendAckArguments.dest = prm->from;
        sendAckArguments.msg = &ackpkt;
        sendAckArguments.len = sizeof(RultiMsg);
        timeDelta = call Random.rand16();
        call AckTimer.startOneShot(timeDelta % RULTI_ACK_DELTA_MS);

        do {
            // in case the message we just acknowledged was already reported
            // to the user, we should not do that again!
            char duplicate = 0;
            uint8_t i = 0;
            while (i < RULTI_SEQNO_COUNT) {
                if ((duplicate = (receivedSeqno[i] == prm->seqno)))
                    i = RULTI_SEQNO_COUNT;
                else
                    i++;
            }
            if (!duplicate) {
                lastSeqnoIdx = (lastSeqnoIdx+1)%RULTI_SEQNO_COUNT;
                receivedSeqno[lastSeqnoIdx] = prm->seqno;
                signal Receive.receive(message,payload,len);
            }
        } while (0); // take THIS, nesC!
        return message;
    }
    /**
     * If we successfully got our message out, we signal the receiver, that we did (sender is not busy anymore).
     */
    event void AckSend.sendDone(message_t* m, error_t err) {
        ackSendBusy = 0;
    }
    /**
     * Receiving an acknowledgement tells us that one of our receivers actually received the message.
     */
    event message_t* AckReceive.receive(message_t* message, void* payload, uint8_t len) {
        RultiMsg* prm = payload;
        call Leds.led1Toggle();
        if (len != sizeof(RultiMsg))
            return message;
        if (!(prm->to & (1<<TOS_NODE_ID)))
            // the message was not for us
            return message;
        if (!receivers)
            // we are not waiting for any acknowlwedgement
            return message;
        *receivers &= ~(1<<prm->from);
        if (!*receivers) {
            stopRtx();
            signal AMSend.sendDone(originalMessage, SUCCESS); // as far as we are concerned
        }
	return message;
    }

    /* ******************************** provided interfaces ******************************** */

    /**
     * Our sending interface. We will then initiate a reliable transmission to the specified receivers.
     * \param dest Bitset containing the receivers.
     */
    command error_t AMSend.send(am_addr_t dest, message_t* msg, uint8_t len) {
        if (transmissions)
            return EBUSY; // EBUSY: "The underlying system is busy; retry later"

        if (!originalMessage) // we have not been initialised yet
            call SeedInit.init(TOS_NODE_ID);
        
        sendPayloadArguments.dest = AM_BROADCAST_ADDR;
        sendPayloadArguments.msg = &pkt;
        sendPayloadArguments.len = len+sizeof(RultiMsg);
        do {
            char* i = call Packet.getPayload(&pkt,0);
            char* j = call Packet.getPayload(msg,0);
            char* end = i+len;
            while (i<end)
                *i++ = *j++;

            while (!(((RultiMsg*)i)->seqno = (seqno_t)(call Random.rand16()))); // 0 is not a valid sequence number
            ((RultiMsg*)i)->from = TOS_NODE_ID;
            ((RultiMsg*)i)->to = dest;

            // note 1: 'receivers' points to the actual place in the message_t buffer that holds the value of the 'to' field
            //         thereby, when we get an acknowledgement and flip the appropriate bit, it will be set to zero in the message
            //         as well. Hence, on retransmission, the receivers that have acknowledged the message will not "receive" it again.
            // note 2: this is no problem, since that operation is atomar. hence we cannot end up with invalid memory.
            // note 3: it is not crucial that the message is not retransmitted to verified receivers. however, it saves bandwidth and collisions.
            receivers = &(((RultiMsg*)i)->to);
        } while(0);
        originalMessage = msg;
        retransmit();
        call RtxTimer.startPeriodic(RULTI_RTX_INTERVAL_MS + (call Random.rand16() % RULTI_RTX_DELTA_MS));

        return SUCCESS;
    }
    /**
     * The user may want to cancel the transmission. Subsequent acknowledgements will be ignored.
     */
    command error_t AMSend.cancel(message_t* msg) {
        stopRtx();
        return call PayloadSend.cancel(msg);
    }
    /**
     * Getter. Patched through from the lower layer.
     */
    command uint8_t AMSend.maxPayloadLength() {
        return call PayloadSend.maxPayloadLength();
    }
    /**
     * Getter. Patched through from the lower layer.
     */
    command void* AMSend.getPayload(message_t* m, uint8_t len) {
        return call PayloadSend.getPayload(m,len);
    }
}

