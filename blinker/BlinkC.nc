#include "Blink.h"

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
    uses interface Random;
    uses interface ParameterInit<uint16_t> as SeedInit;
    uses interface CC2420Packet;

}

implementation {
  
    void setLed(uint8_t);
    uint8_t selectRandomLed();
    void transmitLed(BlinkMsg);
    char amIaReceiver(BlinkMsg *);
    

    //// variables to control the channel ////
    // The current message
    message_t pkt;
    // The current sequential ID
    seqno_t curr_sn = 0;
    // led mask
    uint8_t ledMask = 0;
    
    /**
     * This event is called, after the device was booted and we start AMControl here.
     */
    event void Boot.booted() {
        /* dbg("Boot", "Booting mote number %d\n", TOS_NODE_ID); */
        // Now we must wait until the radio channel is actually available.
        // Handling of timer starting is done in AMControl.
        call SeedInit.init(13);
        call AMControl.start();
        call SerialControl.start();

        // start the timer of the NeighBourMod
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
     * Selects a LED number randomly.
     *
     * @return An interger between 0 and 2
     */
    uint8_t selectRandomLed() {
        uint8_t leds = 1 << ((call Random.rand16()) % 3);
        dbg("BlinkC","new command is %u\n",leds);
        //assert(!(leds & ~7));
        return leds;
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
    void transmitLed(BlinkMsg msg) {
        // TODO: in one line?
        void* m = call Packet.getPayload(&pkt, 0);
        *(BlinkMsg *)(m) = msg;
        call CC2420Packet.setPower(&pkt,2);
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkMsg)) == SUCCESS)
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
        if (&pkt == msg) {
            if (error == SUCCESS) {
		//timer();
            } else {
                while (call AMSend.send(AM_BROADCAST_ADDR,msg,sizeof(BlinkMsg)) == FAIL);
            }
        }
    }
    
    event void SerialAMSend.sendDone(message_t* msg, error_t error) {
	if (&pkt == msg) {
            if (error == SUCCESS) {
		//timer();
            } else {
                while (call AMSend.send(AM_BROADCAST_ADDR,msg,sizeof(BlinkMsg)) == FAIL);
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
        return !!(msg->dests & (1 << TOS_NODE_ID));
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
	    
            if(sn > curr_sn || (!sn && curr_sn)) {
                curr_sn = sn;
                if (amIaReceiver(btrpkt)){
		    setLed(btrpkt->instr);
                }
                transmitLed(*btrpkt);
            }
        }
        return message;
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

            if (amIaReceiver(msg)) {
                setLed(msg->instr);
            }

            transmitLed(*msg);
            //note: m is not needed now anymore
        }
        return message;
    }

    /**************************************************
     * Sensor events
     **************************************************/
    
    event void LightSensor.readDone(error_t result, uint16_t val){
	
    }

    event void InfraSensor.readDone(error_t result, uint16_t val){
	
    }

    event void TempSensor.readDone(error_t result, uint16_t val){
	
    }

    event void HumSensor.readDone(error_t result, uint16_t val){
	
    }
}
