#include "Blink.h"
#include "Constants.h"

/**
 * Implementation of the first task.
 * Node number 0 of the network select a random led
 * and broadcast it to the whole network.
 * The other nodes accept the command, make sure they only receive once
 * and set the led also.
 * 
 * @file BlinkC.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date So 2. Mai 21:14:53 CEST 2010
 **/

module BlinkC {
    // required interfaces to manage and send/receive packets
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface Receive;
    // serial interface
    uses interface Packet as SerialPacket;
    uses interface AMPacket as SerialAMPacket;
    uses interface AMSend as SerialAMSend;
    uses interface Receive as SerialReceive;

    // used to control the ActiveMessageC component
    uses interface SplitControl as AMControl;
    uses interface SplitControl as SerialControl;
    
    // the sensor components
    uses interface Read<uint16_t> as LightSensor;
    uses interface Read<uint16_t> as InfraSensor;
    uses interface Read<uint16_t> as TempSensor;
    uses interface Read<uint16_t> as HumSensor;

    // additional needed components
    uses interface Timer<TMilli> as Timer;
    uses interface Boot;
    uses interface Leds;
    uses interface CC2420Packet;

    // Neighbor
    uses interface Init;
}

implementation {
  
    void setLed(uint8_t);
    uint8_t selectRandomLed();
    void transmitLed(BlinkMsg);
    char amIaReceiver(BlinkMsg *);
    void sendSensingData(instr_t sensingInstr, data_t sensingData);
    uint8_t getIDFromBM(nodeid_t bm);

    //// variables to control the channel ////
    // The current outgoing radio message
    message_t pkt_radio_out;
    // The current outgoing serial message
    message_t pkt_serial_out;
    // The last incoming sensing message
    message_t pkt_sensing_in;
    // The current sensing message
    message_t pkt_sensing_out;
    // An array of sequential numbers of the other motes
    seqno_t curr_sn[MAX_MOTES];
    // own sequential numbers
    seqno_t own_sn = 1;
    // led mask
    uint8_t ledMask = 0;
    
    /**
     * This event is called, after the device was booted and we start AMControl here.
     */
    event void Boot.booted() {
        int i;
        /* dbg("Boot", "Booting mote number %d\n", TOS_NODE_ID); */
        // Now we must wait until the radio channel is actually available.
        // Handling of timer starting is done in AMControl.
        call AMControl.start();
        call SerialControl.start();

        // start the timer of the NeighBourMod
        // initialize the curr_sn
        for (i = 0; i < MAX_MOTES; i++)
            curr_sn[i] = 0;
    }

    /**
     *  Helper function to start a one-shot timer for node 0 and do
     *  nothing for other nodes.
     */
    void timer(void) {
        // if we use one time shots, we do not need a busy flag or anything
        // also: we cannot have timer fires while we are still busy
        call Timer.startPeriodic(BLINK_GENERATE_INTERVAL_MS);
    }

    /**
     * Is called, if the radio module is started.
     * In this case, we start the timer.
     *
     * @param err SUCCESS if the component was successfully turned on, FAIL otherwise.
     */
    event void AMControl.startDone(error_t err) {
        if (err == FAIL) {
            call AMControl.start();
        } else {
            timer(); 
        }
    }

    /**
     * Called, when the radio module has stopped.
     * - not used -
     */
    event void AMControl.stopDone(error_t err) {
    }

    /**
     * Is called, if the serial module is started.
     *
     * @param err SUCCESS if the component was successfully turned on, FAIL otherwise.
     */
    event void SerialControl.startDone(error_t err) {
        if (err == FAIL) {
            call SerialControl.start();
        }
    }

    /**
     * Called, when the serial module has stopped.
     * - not used -
     */
    event void SerialControl.stopDone(error_t err) {
    }

    /**
     * This event is triggered whenever the timer fires.
     * If the mote has ID 0, a LED is randomly choosen and activated,
     * and the choice is braodcasted over the network. 
     */
    event void Timer.fired() {
        //if (TOS_NODE_ID == 0) {
            //instr_t leds = (instr_t)selectRandomLed();
            /* dbg("BlinkC", "got led %d\n", led_idx); */
            //setLed(2);
//            BlinkMsg msg;// = {.instr = leds, .seqno = ++curr_sn, .dest = AM_BROADCAST_ADDR };
//transmitLed(msg);
	    //}
    }

    /**
     * Applies an instruction to the leds.
     *
     * @param led Number of the LED to turn on.
     */
    void setLed(instr_t led) {
        ledMask = (ledMask & (~led >> 3)) ^ led;
        call Leds.set(ledMask);
    }

    /**
     * Broadcast a led number over the radio network.
     *
     * @param id The sequential ID of the message.
     * @param led_idx The ID of the LED.
     */
    void transmitMessage(BlinkMsg msg) {
        *(BlinkMsg*)(call Packet.getPayload(&pkt_radio_out, 0)) = msg;
        call CC2420Packet.setPower(&pkt_radio_out, 2);
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt_radio_out, sizeof(BlinkMsg)) == SUCCESS)
           dbg("BlinkC", "Broadcasting message with sequential number %i and led number %i\n", msg.seqno, msg.instr);
    }

    
    /**
     * When the sending is completed successfully, we set the busy-flag to false.
     *
     * @param msg The packet which was submitted as a send request.
     * @param error SUCCESS if it was sent successfully, FAIL if it was not, 
     *   ECANCEL if it was cancelled 
     */
    event void AMSend.sendDone(message_t* msg, error_t error) {
        if (&pkt_radio_out == msg) {
            if (error == SUCCESS) {
		//timer();
            } else {
                while (call AMSend.send(AM_BROADCAST_ADDR,msg,sizeof(BlinkMsg)) == EBUSY);
            }
        }
    }
    
    event void SerialAMSend.sendDone(message_t* msg, error_t error) {
	setLed(2);
	if (&pkt_serial_out == msg) {
            if (error == SUCCESS) {
		//timer();
		setLed(4);
            } else {
                while (call AMSend.send(AM_BROADCAST_ADDR,msg,sizeof(BlinkMsg)) == EBUSY);
            }
        }
    }

    /**
     * Check whether we are one of the receivers of the message in question.
     * Our messages are multicast.
     * 
     * @param msg The message we want to check.
     * @return 1 if we are one receiver.
     */
    char amIaReceiver(BlinkMsg* msg) {
        /// !! is needed to avoid possible overflow in the casting to char
        return !!(msg->dests & (1 << TOS_NODE_ID));
    }

    /** 
     * Handle the message received calling the correct instructions
     * 
     * @param msg pointer to the message
     */
    void handleMessage(BlinkMsg* msg){
        /// checking what message type
        switch (msg->type) {
        case MSG_INSTR:
	    setLed(msg->instr);
            break;
            
        case MSG_SENS_REQ:
	    // Message is a sensing request
	    // store the message locally
	    *(BlinkMsg*)(call Packet.getPayload(&pkt_sensing_in, 0)) = *msg;
	    // fetch the sensor data
            switch(msg->instr) {
            case LIGHT:
		call LightSensor.read();
                break;
            case INFRA:
		call InfraSensor.read();
                break;
            case HUMIDITY:
		call HumSensor.read();
                break;
            case TEMP:
		call TempSensor.read();
	    };
            break;

        case MSG_SENS_DATA:
	    // Message contains sensing data
	    // Send them back over the serial port
	    setLed(1);
	    *(BlinkMsg*)(call Packet.getPayload(&pkt_serial_out, 0)) = *msg;
	    call SerialAMSend.send(AM_BROADCAST_ADDR, &pkt_serial_out, sizeof(BlinkMsg));
            break;
	};
    }
    
    /**
     * This event is triggered, whenever a message is received.
     * If the message is new to the mote, it sets his LED to the LED number specified in
     * the messages payload and broadcasts the message.
     *
     * @param message The received packet.
     * @param payload A pointer to the packet's payload.
     * @param len The length of the data region pointed to by payload. 
     * @return The received message.
     */
    event message_t* Receive.receive(message_t* message, void* payload, uint8_t len) {
        if (len == sizeof(BlinkMsg)){
            BlinkMsg* btrpkt = (BlinkMsg*) payload;

	    seqno_t sn = btrpkt->seqno;

	    uint8_t senderID = getIDFromBM(btrpkt->sender);

            if(sn > curr_sn[senderID] || (!sn && curr_sn[senderID])) {
                curr_sn[senderID] = sn;
                if (amIaReceiver(btrpkt)){
		    handleMessage(btrpkt);
                }
                transmitMessage(*btrpkt);
            }
        }
        return message;
    }

    uint8_t getIDFromBM(nodeid_t bm){
	nodeid_t local_bm = bm;
	uint8_t counter = 0;
	local_bm >>= 1;
	while(local_bm != 0){
	    local_bm >>= 1;
	    counter++;
	}
	return counter;
    }

    /**
     * This event is triggered, whenever a message is received via the serial interface.
     * If the message is new to the mote, it sets his LED to the LED number specified in
     * the messages payload and broadcasts the message.
     *
     * @param message The received packet.
     * @param payload A pointer to the packet's payload.
     * @param len The length of the data region pointed to by payload. 
     * @return The received message.
     */
    event message_t* SerialReceive.receive(message_t* message, void* payload, uint8_t len) {
        if (len == sizeof(BlinkMsg)) {
            BlinkMsg* msg = (BlinkMsg *) payload;

	    // Set the sender to the current Mote's ID
	    msg->sender = (1 << TOS_NODE_ID);
	    msg->seqno = own_sn++;

            if (amIaReceiver(msg)) {
                handleMessage(msg);
            }

            transmitMessage(*msg);
        }
        return message;
    }

    /**************************************************
     * Sensor events
     **************************************************/
    
    event void LightSensor.readDone(error_t result, uint16_t val){
	if(result == SUCCESS){
	    sendSensingData(1, val);
	}
    }

    event void InfraSensor.readDone(error_t result, uint16_t val){
	if(result == SUCCESS){
	    sendSensingData(2, val);
	}
    }

    event void TempSensor.readDone(error_t result, uint16_t val){
	if(result == SUCCESS){
	    sendSensingData(3, val);
	}
    }

    event void HumSensor.readDone(error_t result, uint16_t val){
	if(result == SUCCESS){
	    sendSensingData(4, val);
	}
    }
    
    void sendSensingData(instr_t sensingInstr, data_t sensingData){
	// get a message
	BlinkMsg* newMsg = (BlinkMsg*)(call Packet.getPayload(&pkt_sensing_out, 0));
	// get the request message
	BlinkMsg* request = (BlinkMsg*)(call Packet.getPayload(&pkt_sensing_in, 0));
	// Add new contents
	newMsg->dests = request->sender;
	newMsg->sender = (1 << TOS_NODE_ID);
	newMsg->seqno = own_sn++;
	newMsg->type = 3;
	newMsg->instr = sensingInstr;
	newMsg->data = sensingData;
	
	if (amIaReceiver(newMsg)) {
	    handleMessage(newMsg);
	}else{
	    transmitMessage(*newMsg);
	}
    }

}
