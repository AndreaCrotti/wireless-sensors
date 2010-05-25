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
    uses {
        interface Packet;
        interface AMPacket;
        interface AMSend as PayloadSend;
        interface Receive as PayloadReceive;
        interface AMSend as AckSend;
        interface Receive as AckReceive;
        interface Random;
        interface ParameterInit<uint16_t> as SeedInit;

        interface Leds;

        interface Timer<TMilli> as RtxTimer;
        interface Timer<TMilli> as AckTimer;
    }

    provides {
        interface AMSend;
        interface Receive;
    }
}
implementation {
    // member variables
    /// number of transmissions already sent (0 iff not busy)
    unsigned char transmissions = 0;
    /// When transmitting payload, the user gives us his message,
    /// which - for technical reasons - we cannot use. However, we have to pretend
    /// to have used it (to the user). Hence we save his pointer, for the answer.
    message_t* originalMessage = NULL;
    /// Payload messsage buffer.
    message_t pkt;
    /// Acknowledge message buffer.
    message_t ackpkt;
    /// Probabilistic approach to avoid loops. Save (and always check) so many sequence numbers.
    seqno_t receivedSeqno[RULTI_SEQNO_COUNT];
    /// Index for the bounded queue 'receivedSeqno'.
    uint8_t lastSeqnoIdx = RULTI_SEQNO_COUNT-1;
    /// If (re-)transmitting we store the receivers that did not yet receive our payload (who did not ack).
    /// This points directly to the space withing the 'pkt'.
    nx_nodes_t* receivers;

    /* ******************************** private helpers ******************************** */

    SendArguments sendPayloadArguments;
    /**
     * Send the payload. If sending fails, the task will be reposted.
     *
     * @param sendPayloadArgumenst [logical] the exact values to pass to the AMSend.send command.
     */
    task void payloadSend() {
        // transmissions tells us that we (still) have to send suff.
        // if it is 0, we were called falsely for a strange reason (probably does not occur).
        if (transmissions && (call PayloadSend.send(sendPayloadArguments.dest,sendPayloadArguments.msg,sendPayloadArguments.len) != SUCCESS))
            post payloadSend();
    }
    /**
     * (Re-)transmit a payload by posting a task and increase the transmission counter.
     * Will perform no check whatsoever and just plain retransmit the message.
     * IT IS YOUR RESPONSIBILITY TO CHECK EVERYTHING ELSE!
     */
    void transmit(void) {
        call Leds.led0Toggle();
        transmissions++;
        post payloadSend();
    }

    /** 
     * Stop the communication.
     */
    void stopRtx(void) {
        // setting 'receivers' to NULL makes the receiver silently exit if it receives an acknowledgement.
        receivers = NULL;
        transmissions = 0;
        call RtxTimer.stop();
    }

    /// We cannot have arguments in tasks (if you think about it, it is quite obvious why).
    /// However we still want to pass arguments to the send-task so it is sufficiently generic.
    SendArguments sendAckArguments;
    char ackSendBusy = 0;
    /**
     * Send an acknowledgement. If sending fails, the task will be reposted.
     *
     * \param sendAckArguments [logical] the exact values to pass to the AMSend.send command.
     */
    task void ackSend() {
call Leds.led2Toggle();
        if (call AckSend.send(sendAckArguments.dest,sendAckArguments.msg,sendAckArguments.len) != SUCCESS) {
            //timeDelta = call Random.rand16();
            //call AckTimer.startOneShot(timeDelta % RULTI_ACK_DELTA_MS);
        }
    }
    /// Logical arguments to the receive task.
    ReceiveArguments signalReceiveArguments;
    /**
     * A task to signal the provided receive.
     */
    task void signalReceive() {
        signal Receive.receive(signalReceiveArguments.message,signalReceiveArguments.payload,signalReceiveArguments.len-sizeof(RultiMsg));
    }

    /**
     * Sender of a specific message.
     *   Why would we need this? To decouple the way we determine the sender from the usage of it.
     * 
     * \param message The 'message_t' pointer.
     * \returns The sender of the message.
     */
    nodeid_t getMessageSender(message_t* message) {
        // this is the value set by tinyos on the sending node
        return call AMPacket.source(message);
    }


    /* ******************************** used interfaces ******************************** */

    /**
     * Start retransmission if we did not exceed the maximal number of retransmissions. Otherwise stop.
     */
    event void RtxTimer.fired() {
        if (transmissions < RULTI_MAX_TRANSMISSIONS) {
            transmit();
        } else {
            // just give up after so many (re-)transmissions.
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
        RultiMsg* prm = payload + len-sizeof(RultiMsg); //payload RultiMessage (the one we got)
        uint16_t timeDelta;
        nodeid_t payloadSender = getMessageSender(message);
        { // sanity checks
            // 1) we are still retransmitting
            // 2) that transmission was not for us
            // 3) invalid seqno
            // note: we CANNOT check for the a valid length because we have no clue what the user uses
            if (ackSendBusy || !prm->seqno || !(prm->to & (1<<TOS_NODE_ID)))
                // this is somewhat ugly, but right now, we just cannot handle the transmission,
                // so we will wait for the next one
                return message;
        }

        { // compile the acknowledgement
            RultiMsg* pAck; //payload Acknowledgement (the one we send back) 
            pAck = (RultiMsg*)(call Packet.getPayload(&ackpkt, 0));
            pAck->seqno = prm->seqno;
            pAck->to = (1 << ((payloadSender)));
        }

        { // send the acknowledgement
            ackSendBusy = 1;
            // prepare the logical arguments for the sending clerk
            sendAckArguments.dest = payloadSender;
            sendAckArguments.msg = &ackpkt;
            sendAckArguments.len = sizeof(RultiMsg);

            // randomising the delta time and starting one shot timer - this is a probabilistic
            // approach to avoid collisions between receivers (all sending at once)
            timeDelta = call Random.rand16();
            call AckTimer.startOneShot(timeDelta % RULTI_ACK_DELTA_MS);
        }

        { // pass the message to the upper layer (user) if it's not a duplicate
            char duplicate = 0;
            uint8_t i = 0;
            // seach for the seqno (did we already receive this?)
            while (i < RULTI_SEQNO_COUNT) {
                if ((duplicate = (receivedSeqno[i] == prm->seqno))) // assignment!
                    i = RULTI_SEQNO_COUNT; // hey, yes we did
                else
                    i++; // no, lets continue searching
            }
            // in case the message we just acknowledged was already reported
            // to the user, we should not do that again!
            if (!duplicate) {
                // save that we already got it
                lastSeqnoIdx = (lastSeqnoIdx + 1) % RULTI_SEQNO_COUNT;
                receivedSeqno[lastSeqnoIdx] = prm->seqno;
                // start the task to inform the upper layer (put its arguments in the struct)
                signalReceiveArguments.message = message;
                signalReceiveArguments.payload = payload;
                signalReceiveArguments.len = len;
                post signalReceive();
            }
        }
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
        RultiMsg* prm = payload; // although the message may be bogus it does not hurt
call Leds.led1Toggle();
        // sanity check:
        //  1) receivers == 0  =>  no transmission is going on  => discard
        //  2) wrong lengh  =>  some tx error / other application  =>  discard
        //  3) this node is not a receiver  =>  discard
        if (receivers && (len == sizeof(RultiMsg)) && (prm->to & (1<<TOS_NODE_ID))) {
            // we got an acknowledge from that node, so we do not have to rtx again. kick him out of the receivers.
            *receivers &= ~(1 << (getMessageSender(message)));
            if (!*receivers) {
                // hurray, all receivers got the message, stop retransmitting
                stopRtx();
                signal AMSend.sendDone(originalMessage, SUCCESS); // as far as we are concerned
            }
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

        { // prepare send arguments 
            sendPayloadArguments.dest = AM_BROADCAST_ADDR;
            sendPayloadArguments.msg = &pkt;
            sendPayloadArguments.len = len + sizeof(RultiMsg);
        }

        { // write the message buffer with the original payload and our own layer-specific information
            char* i = call Packet.getPayload(&pkt,0);
            char* j = call Packet.getPayload(msg,0);
            char* end = i+len;
            // memcopy
            while (i<end)
                *i++ = *j++;

            // generate a valid sequence number for the new message
            while (!(((RultiMsg*)i)->seqno = (seqno_t)(call Random.rand16()))); // 0 is not a valid sequence number
            ((RultiMsg*)i)->to = dest;

            // note 1: 'receivers' points to the actual place in the message_t buffer that holds the value of the 'to' field
            //         thereby, when we get an acknowledgement and flip the appropriate bit, it will be set to zero in the message
            //         as well. Hence, on retransmission, the receivers that have acknowledged the message will not "receive" it again.
            // note 2: this is no problem, since that operation is atomic. hence we cannot end up with invalid memory.
            // note 3: it is not crucial that the message is not retransmitted to verified receivers. however, it saves bandwidth and collisions.
            receivers = &(((RultiMsg*)i)->to);
        }
        // we need the originalMessage later
        originalMessage = msg;
        transmit();
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

