generic module BaseSendReceiveP() {
    uses {
        interface Boot;
        interface Thread as ReceiveThread;
        interface Thread as SnoopThread;
        interface Thread as SendThread;
        interface ConditionVariable;
        interface Mutex;
        interface Pool<message_t>;
        interface Queue<message_t*>;
        interface Leds;
    
        interface BlockingReceive as BlockingReceiveAny;
        interface BlockingReceive as BlockingSnoopAny;
        interface BlockingAMSend as BlockingAMSend[uint8_t id];
        interface Packet as ReceivePacket;
        interface Packet as SendPacket;
        interface AMPacket as ReceiveAMPacket;
        interface AMPacket as SendAMPacket;
    }
}

implementation {
    condvar_t c_queue, c_pool;
    mutex_t m_queue, m_pool;
  
    event void Boot.booted() {
        call ConditionVariable.init(&c_queue);
        call ConditionVariable.init(&c_pool);
        call Mutex.init(&m_queue);
        call Mutex.init(&m_pool);
        call ReceiveThread.start(NULL);
        call SnoopThread.start(NULL);
        call SendThread.start(NULL);
    }
  
    event void ReceiveThread.run(void* arg) {   
        message_t* msg;
        call Mutex.lock(&m_pool);
        msg = call Pool.get();
        call Mutex.unlock(&m_pool);

        for(;;) {
            if(call BlockingReceiveAny.receive(msg, 0) == SUCCESS) {
                call Leds.led0Toggle();
        
                call Mutex.lock(&m_queue);
                call Queue.enqueue(msg);
                call Mutex.unlock(&m_queue);
                if( call Queue.size() == 1 ) {
                    call ConditionVariable.signalAll(&c_queue);
                }
        
                call Mutex.lock(&m_pool);
                while( call Pool.empty() )
                    call ConditionVariable.wait(&c_pool, &m_pool);
                msg = call Pool.get();
                call Mutex.unlock(&m_pool);
        
            }
            else call Leds.led2Toggle();
        }
    }
  
    event void SnoopThread.run(void* arg) {   
        message_t* msg;
        call Mutex.lock(&m_pool);
        msg = call Pool.get();
        call Mutex.unlock(&m_pool);
        for(;;) {
            if(call BlockingSnoopAny.receive(msg, 0) == SUCCESS) {
                call Leds.led0Toggle();
        
                call Mutex.lock(&m_queue);
                call Queue.enqueue(msg);
                call Mutex.unlock(&m_queue);
                if( call Queue.size() == 1 ) {
                    call ConditionVariable.signalAll(&c_queue);
                }
        
                call Mutex.lock(&m_pool);
                while( call Pool.empty() )
                    call ConditionVariable.wait(&c_pool, &m_pool);
                msg = call Pool.get();
                call Mutex.unlock(&m_pool);
        
            }
            else call Leds.led2Toggle();
        }
    }
  
    event void SendThread.run(void* arg) {  
        message_t* msg;
        am_id_t id;
        am_addr_t source;
        am_addr_t dest;
        uint8_t len;  
  
        for(;;) {
            call Mutex.lock(&m_queue);
            while( call Queue.empty() )
                call ConditionVariable.wait(&c_queue, &m_queue);
            msg = call Queue.dequeue();
            call Mutex.unlock(&m_queue);
      
            id = call ReceiveAMPacket.type(msg);
            source = call ReceiveAMPacket.source(msg);
            dest = call ReceiveAMPacket.destination(msg);
            len = call ReceivePacket.payloadLength(msg);
      
            call SendPacket.clear(msg);
            call SendAMPacket.setSource(msg, source);
      
            call BlockingAMSend.send[id](dest, msg, len);
            call Leds.led1Toggle();
      
            call Mutex.lock(&m_pool);
            call Pool.put(msg);
            call Mutex.unlock(&m_pool);
            if( call Pool.size() == 1 ) {
                call ConditionVariable.signalAll(&c_pool);
            }
        }
    }
  
default command error_t BlockingSnoopAny.receive(message_t* m, uint32_t timeout) { return FAIL; }
default command void* BlockingSnoopAny.getPayload(message_t* msg, uint8_t len) { return NULL; }
default command error_t SnoopThread.start(void* arg) { return FAIL; }
default command error_t SnoopThread.stop() { return FAIL; }
default command error_t SnoopThread.pause() { return FAIL; }
default command error_t SnoopThread.resume() { return FAIL; }
default command error_t SnoopThread.sleep(uint32_t milli) { return FAIL; }	
}
