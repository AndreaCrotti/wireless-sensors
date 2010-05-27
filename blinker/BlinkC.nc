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

module BlinkC @safe() {
    // required interfaces to manage and send/receive packets
    uses {
        interface Packet;
        interface AMSend;
        interface Receive;
        interface Init as RoutingInit;
        #ifndef TOSSIM
            interface ActiveMessageAddress;
        #endif

        // serial interface
        interface AMSend as SerialAMSend;
        interface Receive as SerialReceive;

        // used to control the ActiveMessageC component
        interface SplitControl as AMControl;
        interface SplitControl as SerialControl;
    
        // the sensor components
        interface Read<uint16_t> as LightSensor;
        interface Read<uint16_t> as InfraSensor;
        interface Read<uint16_t> as TempSensor;
        interface Read<uint16_t> as HumSensor;

        // additional needed components
        interface Timer<TMilli> as Timer;
        interface Boot;
        interface Leds;
    }
}

implementation {
  
    void setLed(uint8_t);
    uint8_t selectRandomLed();
    char amIaReceiver(BlinkMsg *);
    void sendSensingData(instr_t, data_t);
    uint8_t getIDFromBM(nodeid_t);

    //// variables to control the channel ////
    // The current outgoing radio message
    message_t pkt_cmd_out;
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

    // debug message packet
    message_t debug_pkt;
    
    /**
     * This event is called, after the device was booted and we start AMControl here.
     */
    event void Boot.booted() {
        int i;
        dbg("Boot", "Booting mote number %d\n", TOS_NODE_ID);
        // Now we must wait until the radio channel is actually available.
        // Handling of timer starting is done in AMControl.
        call AMControl.start();
        call SerialControl.start();

	// Initialize the routing module
	call RoutingInit.init();

        #ifndef TOSSIM
            // set the active message address
            call ActiveMessageAddress.setAddress(call ActiveMessageAddress.amGroup(),TOS_NODE_ID);
        #endif

        // initialize the curr_sn
        for (i = 0; i < MAX_MOTES; i++)
            curr_sn[i] = 0;
    }

    #ifndef TOSSIM
        async event void ActiveMessageAddress.changed() {
        }
    #endif

    /**
     * Transmits a command over the network.
     *
     * The send data should be stored in the global pkt_cmd_out variable.
     */
    task void transmitMessage() {
        // TODO: should we also check the result or not?
        call AMSend.send(AM_BROADCAST_ADDR, &pkt_cmd_out, sizeof(BlinkMsg));
    }


    /**
     * Transmits a command over the network.
     *
     * The send data should be stored in the global pkt_cmd_out variable.
     */
    task void transmitSensing() {
         // TODO: should we also check the result or not?
        call AMSend.send(AM_BROADCAST_ADDR, &pkt_sensing_out, sizeof(BlinkMsg));
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
     */
    event void SerialControl.stopDone(error_t err) {
    }

    /** 
     * triggered when the timer fires
     */
    event void Timer.fired() {
    }

    /**
     * Applies an instruction to the leds.
     *
     * @param led Number of the LED to turn on.
     */
    void setLed(instr_t led) {
        // XORing between actual ledmask and led passed in
        ledMask = (ledMask & (~led >> 3)) ^ led;

	dbg("Sensor", "Leds changed to %d\n", ledMask);

        call Leds.set(ledMask);
    }

    /**
     * When the sending is completed successfully, we set the busy-flag to false.
     *
     * @param msg The packet which was submitted as a send request.
     * @param error SUCCESS if it was sent successfully, FAIL if it was not, 
     *   ECANCEL if it was cancelled 
     */
    event void AMSend.sendDone(message_t* msg, error_t error) {
        dbg("Radio", "Sending Done\n");
    }
    
    event void SerialAMSend.sendDone(message_t* msg, error_t error) {
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

    task void sendSerialOut() {
        call SerialAMSend.send(AM_BROADCAST_ADDR, &pkt_serial_out, sizeof(BlinkMsg));
    }

    /** 
     * Handle the message received calling the correct instructions
     * 
     * @param msg pointer to the message
     */
    void handleMessage(BlinkMsg* msg){
        dbg("Sensor", "handleMessage is called \n");
        
        // checking what message type
        switch (msg->type) {
        case MSG_INSTR:
            setLed(msg->instr);
            break;
            
        case MSG_SENS_REQ:
            dbg("Sensor", "recognized sensing request %d\n", msg->instr);
            setLed(1);

            // Message is a sensing request
            // store the message locally
            *(BlinkMsg*)(call Packet.getPayload(&pkt_sensing_in, 0)) = *msg;
            // fetch the sensor data
            switch(msg->instr) {
            case SENS_LIGHT:
                call LightSensor.read();
                break;
            case SENS_INFRA:
                call InfraSensor.read();
                break;
            case SENS_HUMIDITY:
                call HumSensor.read();
                break;
            case SENS_TEMP:
                call TempSensor.read();
            };
            break;

        case MSG_SENS_DATA:
            // Message contains sensing data
            // Send them back over the serial port
            *(BlinkMsg*)(call Packet.getPayload(&pkt_serial_out, 0)) = *msg;
            //call SerialAMSend.send(AM_BROADCAST_ADDR, &pkt_serial_out, sizeof(BlinkMsg));
            post sendSerialOut();
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
        BlinkMsg* btrpkt = (BlinkMsg*) payload;
	seqno_t sn;
	uint8_t senderID;

        //static uint8_t called = 0;
        if (len == sizeof(BlinkMsg)){
            sn = btrpkt->seqno;
            senderID = btrpkt->sender;

	    dbg("Radio", "Received an radio message\n");

            // check if the message was already seen or handle the received message
            if(sn > curr_sn[senderID] || (!sn && curr_sn[senderID])) {
                //call Leds.set(++called);
                curr_sn[senderID] = sn;
                if (amIaReceiver(btrpkt)){
                    handleMessage(btrpkt);
                }
                
                if(btrpkt->type == MSG_SENS_DATA){
                    dbg("Sensor", "About to forward sensing results \n");
                    setLed(4);
                }

                *(BlinkMsg*)(call Packet.getPayload(&pkt_cmd_out, 0)) = *btrpkt; 
                post transmitMessage();
            }
        }
        return message;
    }

    /** 
     * Returns the mote index from the bitmask.
     * Works correctly assuming that only one bit is set
     * 
     * @param bm bitmask
     * 
     * @return index if the mote
     */
    uint8_t getIDFromBM(nodeid_t bm){
        uint8_t counter = 0;
        bm >>= 1;
        while(bm != 0){
            bm >>= 1;
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
            dbg("Serial", "Packet received correctly from serial stuff\n");
	    
            // Set the sender to the current Mote's ID
            msg->sender = TOS_NODE_ID;
            msg->seqno = own_sn++;
            curr_sn[TOS_NODE_ID] = msg->seqno;

            dbg("Serial", "pkt destination is %d\n", msg->dests);
            
            // serial receiver should only work for node 0???
            if (amIaReceiver(msg)) {
                handleMessage(msg);
            }
            
            // set correctly the content of the message and post the trasmission
            *(BlinkMsg*)(call Packet.getPayload(&pkt_cmd_out, 0)) = *msg; 
            post transmitMessage();
        }
        return message;
    }

    /**************************************************
     * Sensor events, they simply pass the value      *
     **************************************************/
    event void LightSensor.readDone(error_t result, uint16_t val){
        if(result == SUCCESS){
            sendSensingData(SENS_LIGHT, val);
        }
    }

    event void InfraSensor.readDone(error_t result, uint16_t val){
        if(result == SUCCESS){
            sendSensingData(SENS_INFRA, val);
        }
    }

    event void HumSensor.readDone(error_t result, uint16_t val){
        if(result == SUCCESS){
            sendSensingData(SENS_HUMIDITY, val);
        }
    }

    event void TempSensor.readDone(error_t result, uint16_t val){
        if(result == SUCCESS){
            sendSensingData(SENS_TEMP, val);
        }
    }
    
    /** 
     * Sensing data handling
     * 
     * @param sensingInstr Instruction to execute on the mote
     * @param sensingData data
     */
    void sendSensingData(instr_t sensingInstr, data_t sensingData){
	// get a message
	BlinkMsg* newMsg = (BlinkMsg*)(call Packet.getPayload(&pkt_sensing_out, 0));
	// get the request message
	BlinkMsg* request = (BlinkMsg*)(call Packet.getPayload(&pkt_sensing_in, 0));
	
        dbg("Sensor", "sendSensingData is called\n");
        setLed(2);

        // Add new contents
	newMsg->dests = (1 << (request->sender));
	newMsg->sender = TOS_NODE_ID;
	newMsg->seqno = own_sn++;
	newMsg->type = 3;
	newMsg->instr = sensingInstr;
	newMsg->data = sensingData;
	
	if (amIaReceiver(newMsg)) {
	    handleMessage(newMsg);
	}

        dbg("Sensor", "After packet creation sender is %d \n", newMsg->sender);

	// assign to the payload of the our global packet the new message created 
	post transmitSensing();
    }

}
