// should be safe without #ifdef since I have it outside it
#include "storing.h"

// maybe making it generic would also make it possible to get the caller
module StorageP @safe() {
    provides {
        // give also an interface to fetch the actual message with the last
        // n logs inside it
        /* interface Storage; */
        interface Init;
    }

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

    sense_config_t conf;
    logentry_t logentry;

    // mount everything and start the timer for sensing
    command error_t Init.init() {
        call SensingTimer.startPeriodic(1000);
        // check that everything is mounted correctly and so on
        
    }

    /** 
     * Getting the last logentry structure
     * 
     * @return a logentry_t with the last sensed results
     */
    command logentry_t getLastLog() {
        // we use a global message packet and fill it with our data
        // find a way to write a log from the sensing_entry_t data structure 
    }

    /** 
     * Constructs a message given some data in it
     * 
     * @return 
     */
    message_t sensingToMsg(sensing_entry_t sensed) {
        
    }

    // when the timer is fired means that we need to store new sensing stuff
    event void SensingTimer.fired(){
        // store a new data sensed in the array structure
    }

    // Events needed for the configuration protocol
    event void Mount.mountDone(error_t error) {
        if (error == SUCCESS) {
            if (call Config.valid() == TRUE) {
                if (call Config.read(CONFIG_ADDR, &conf, sizeof(conf)) != SUCCESS) {
                    // Handle failure
                }
            }
            else {
                // invalid volume, commit to make it valid
                if (call Config.commit() == SUCCESS) {

                }
                else {
                    // Handle failure
                }
            }
        }
        else{
            // Handle failure
        }        
    }

    // event raised when the configuration is succesfully read
    event void Config.readDone(storage_addr_t addr, void* buf,
                               storage_len_t len, error_t err) __attribute__((noinline)) {
        if (err == SUCCESS) {
            // copying memory from buffer received to our configuration structure
            memcpy(&conf, buf, len);
            call Config.write(CONFIG_ADDR, &conf, sizeof(conf));
        }
        else {
            // Handle failure.
        }
    }

    event void Config.writeDone(storage_addr_t addr, void *buf,
                                storage_len_t len, error_t err) {
        if (err == SUCCESS) {
            if (call Config.commit() != SUCCESS) {
                // Handle failure
            }
        }
        else {
            // Handle failure
        }
    }

    event void Config.commitDone(error_t err) {
        // TODO: check why in the BlinkConfig example this is written differently
        if (err != SUCCESS) {
            // Handle failure
        }
    }
}
