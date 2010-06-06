// should be safe without #ifdef since I have it outside it
#include "storing.h"

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
    // keeping the stored data, should be used as a circular queue
    sensing_entry_t SENSING_DATA[MAX_DATA];
    // we use a pointer to scan the array of last sensed data
    uint8_t lastIdx = 0;

    // mount everything and start the timer for sensing
    command error_t Init.init() {
        call SensingTimer.startPeriodic(1000);
        // check that everything is mounted correctly and so on
    }

    // when the timer is fired means that we need to store new sensing stuff
    event void SensingTimer.fired(){
        // store a new data sensed in the array structure
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