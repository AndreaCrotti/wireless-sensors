// maybe making it generic would also make it possible to get the caller
module StorageP @safe() {
    provides interface Init;
#ifndef TOSSIM
    // storing configuration
    uses {
        interface ConfigStorage as Config;
        interface Mount as Mount;
        interface Timer<TMilli> as SensingTimer;
    }
#endif
}

implementation {
    // mount everything and start the timer for sensing
    command error_t Init.init() {
        call SensingTimer.startPeriodic(SENSETIME);
        // check that everything is mounted correctly and so on
    }

    // when the timer is fired means that we need to store new sensing stuff
    event void SensingTimer.fired(){
        
    }

    // Events needed for the configuration protocol
    event void Mount.mountDone(error_t error) {
        
    }

    event void Config.readDone(storage_addr_t addr, void* buf,
                               storage_len_t len, error_t err) __attribute__((noinline)) {
    }

    event void Config.writeDone(storage_addr_t addr, void *buf,
                                storage_len_t len, error_t err) {
    }

    event void Config.commitDone(error_t err) {

    }
}