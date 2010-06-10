#include "Tosthreads.h"

/**
 * TODO: Dokumentation!!!!!1111elf
 * TODO: check if there are problems with the destination stuff
 *       => The destination stuff was overtaken from our BlinkC application and should work.
 *          The current error is definitely not related to the destination, since no message is received at all.
 * TODO: check if removing completely the serial part will work correctly
 *       => probably not, since radio receive is quite the same...
 * TODO: check if when and if we signal that the queue/pool are usable
 *       => just search for 'signalAll' in the code  
 *
 * @file BlinkC.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date So 2. Mai 21:14:53 CEST 2010
 **/

module TosthreadsP @safe() {
    // required interfaces to manage and send/receive packets
    uses {
        // standart components
        interface Boot;
        interface Leds;
        
        // For accessing packets
        interface Packet;
        interface AMPacket;

        // Radio interfaces
        interface BlockingAMSend as RadioSend;
        interface BlockingReceive as RadioReceive;
        interface Pool<message_t> as RadioPool;
        interface Queue<message_t*> as RadioQueue;

        // Serial interface
        interface BlockingReceive as SerialReceive;

        // For setting the node's addresses
        interface ActiveMessageAddress;

        // used to control the ActiveMessageC component
        interface BlockingStdControl as RadioControl;
        interface BlockingStdControl as SerialControl;

        // Threads
        interface Thread as BootThread;
        interface Thread as SerialReceiveThread;
        interface Thread as RadioReceiveThread;
        interface Thread as RadioSendThread;

        // Thread synchronization
        interface ConditionVariable;
        interface Mutex;
    }
}

implementation {

    bool isUnseen(message_t* msg);
    void setLed(instr_t led);
    void processMessage(message_t* msg);
    bool amIaReceiver(CmdMsg* msg);

    /********************/
    /* Global variables */
    /********************/
    
    condvar_t c_queue, c_pool;
    mutex_t m_queue, m_pool;

    /**********/
    /* Events */
    /**********/
    
    /** 
     * Starts the radio and serial module when the mote is booted.
     */
    event void Boot.booted(){
        call BootThread.start(NULL);
    }
    
    async event void ActiveMessageAddress.changed() {
    }

    /***********/
    /* Threads */
    /***********/
    
    /** 
     * Starts the radio and serial module.
     * 
     * @param arg A pointer... 
     */
    event void BootThread.run(void* arg){
        call RadioControl.start();
        call SerialControl.start();

        call ConditionVariable.init(&c_queue);
        call ConditionVariable.init(&c_pool);
        call Mutex.init(&m_queue);
        call Mutex.init(&m_pool);
        
        // set the active message address to workaround the testbed bug
        call ActiveMessageAddress.setAddress(call ActiveMessageAddress.amGroup(), 
                                             TOS_NODE_ID);
        // Start the other threads
        call SerialReceiveThread.start(NULL);
        call RadioReceiveThread.start(NULL);
        call RadioSendThread.start(NULL);
    }

    /** 
     * Receives messages from the serial module and handles them.
     * 
     * @param arg A pointer...
     */
    event void SerialReceiveThread.run(void* arg){
        message_t* msg;

        // Get a message struct from the pool
        call Mutex.lock(&m_pool);
        msg = call RadioPool.get();
        call Mutex.unlock(&m_pool);

        for (;;) {
            setLed(2);
            // wait for a message to arrive
            // TODO: If the last message was not for us, can we then reuse the same
            //       message struct?
            if (call SerialReceive.receive(msg, 0) == SUCCESS) {
                setLed(4);
                
                // Check, whether this is a new message
                if(isUnseen(msg)){
                    // Check whether the message is for us and handle the message.
                    processMessage(msg);
 
                    // Forward the message
                    call Mutex.lock(&m_queue);
                    call RadioQueue.enqueue(msg);
                    call Mutex.unlock(&m_queue);

                    if (call RadioQueue.size() == 1) {
                        call ConditionVariable.signalAll(&c_queue);
                    }

                    // get a new message struct out of the pool
                    call Mutex.lock(&m_pool);
                    while(call RadioPool.empty()) {
                        call ConditionVariable.wait(&c_pool, &m_pool);
                    }
                    msg = call RadioPool.get();
                    call Mutex.unlock(&m_pool);
                }
            }
        }
    }

    /** 
     * Receives messages from the radio module and handles them.
     * 
     * @param arg A pointer...
     */
    event void RadioReceiveThread.run(void* arg){
        message_t* msg;

        // Get a message struct from the pool
        call Mutex.lock(&m_pool);
        msg = call RadioPool.get();
        call Mutex.unlock(&m_pool);

        for (;;) {
            // wait for a message to arrive
            // TODO: If the last message was not for us, can we then reuse the same
            //       message struct?
            if (call RadioReceive.receive(msg, 0) == SUCCESS) {
                // Check, whether this is a new message
                if(isUnseen(msg)){
                    // Check whether the message is for us and handle the message.
                    processMessage(msg);
 
                    // Forward the message
                    call Mutex.lock(&m_queue);
                    call RadioQueue.enqueue(msg);
                    call Mutex.unlock(&m_queue);

                    if (call RadioQueue.size() == 1) {
                        call ConditionVariable.signalAll(&c_queue);
                    }

                    // get a new message struct out of the pool
                    call Mutex.lock(&m_pool);
                    while(call RadioPool.empty()) {
                        call ConditionVariable.wait(&c_pool, &m_pool);
                    }
                    msg = call RadioPool.get();
                    call Mutex.unlock(&m_pool);
                }
            }
        }
    }

    /** 
     * Waits, until a message is in the sending queue and then sends it.
     * 
     * @param arg  
     */
    event void RadioSendThread.run(void* arg){
        message_t* msg;
        uint8_t len;
        
        for(;;){
            // Wait for an outgoing message
            call Mutex.lock(&m_queue);
            while(call RadioQueue.empty()){
                call ConditionVariable.wait(&c_queue, &m_queue);
            }
            msg = call RadioQueue.dequeue();
            call Mutex.unlock(&m_queue);

            // TODO: Synchronization needed?
            len = call Packet.payloadLength(msg);
            
            // Broadcast the message over the radio module
            call RadioSend.send(AM_BROADCAST_ADDR, msg, len);

            // Give the message struct back to the pool
            call Mutex.lock(&m_pool);
            call RadioPool.put(msg);
            call Mutex.unlock(&m_pool);
            if(call RadioPool.size() == 1){
                // Signal other threads, that the pool is not empty anymore
                call ConditionVariable.signalAll(&c_pool);
            }
        }
    }

    /*****************/
    /* Other methods */
    /*****************/

    /** 
     * Check whether this node is a receiver and toggle the LEDs if necessary.
     * 
     * @param msg A pointer to the received message.
     */
    void processMessage(message_t* msg){
        // TODO: Synchronization needed?
        CmdMsg* cmdmsg = (CmdMsg *)(call Packet.getPayload(msg, 0));

        if(amIaReceiver(cmdmsg)){
            // We are a receiver!
            // Set the LEDs accordingly
            setLed(cmdmsg->instr);
        }
    }
    
    /** 
     * Checks, whether this message was seen before or not.
     * 
     * @param msg A pointer to the received message.
     * 
     * @return 1, if is new, 0 otherwise.
     */
    bool isUnseen(message_t* msg){
        static seqno_t curr_sn = 0;
        seqno_t sn;
        
        // TODO: Synchronization needed?
        CmdMsg* cmdmsg = (CmdMsg *)(call Packet.getPayload(msg, 0));
        sn = cmdmsg->seqno;

        // Check, whether this is a new message.
        if(sn > curr_sn || (!sn && curr_sn)) {
            // This is a new message
            curr_sn = sn;
            return 1;
        }else{
            // This message is old
            return 0;
        }
    }
    
    /**
     * Applies an instruction to the LEDs.
     *
     * @param led Number of the LED to turn on.
     */
    void setLed(instr_t led) {
        static uint8_t ledMask = 0;

        // XORing between actual ledmask and led passed in
        ledMask = (ledMask & (~led >> 3)) ^ led;

	dbg("Sensor", "Leds changed to %d\n", ledMask);

        call Leds.set(ledMask);
    }

    /**
     * Check whether we are one of the receivers of the message in question.
     * Our messages are multicast.
     * 
     * @param msg The message we want to check.
     * @return 1 if we are one receiver.
     */
    bool amIaReceiver(CmdMsg* msg) {
        /// !! is needed to avoid possible overflow in the casting to char
        return !!(msg->dests & (1 << TOS_NODE_ID));
    }
}
