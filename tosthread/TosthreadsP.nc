#include "Tosthreads.h"

/**
 * TODO: Dokumentation!!!!!1111elf
 * TODO: check if there are problems with the destination stuff
 * TODO: check if removing completely the serial part will work correctly
 * TODO: check if when and if we signal that the queue/pool are usable
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

        // Thread synchronization
        interface ConditionVariable;
        interface Mutex;
    }
}

implementation {
  
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
    }

    
    event void SerialReceiveThread.run(void* arg){
        message_t* msg;

        call Mutex.lock(&m_pool);
        msg = call RadioPool.get();
        call Mutex.unlock(&m_pool);

        for (;;) {
            setLed(2);
            // wait for a message to arrive
            if (call SerialReceive.receive(msg, 3000) == SUCCESS) {
                setLed(4);

                // Check whether the message is for us and handle it
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

    /*****************/
    /* Other methods */
    /*****************/

    /** 
     * Check whether this node is a receiver and toggle the LEDs if necessary.
     * 
     * @param msg A pointer to the received message.
     */
    void processMessage(message_t* msg){
        static seqno_t curr_sn = 0;
        seqno_t sn;

        CmdMsg* cmdmsg = (CmdMsg *)(call Packet.getPayload(msg, 0));

        sn = cmdmsg->seqno;
        
        // Check, whether this is a new message.
        if(sn > curr_sn || (!sn && curr_sn)) {
            curr_sn = sn;
            if(amIaReceiver(cmdmsg)){
                // We are a receiver!
                // Set the LEDs accordingly
                setLed(cmdmsg->instr);
            }
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
