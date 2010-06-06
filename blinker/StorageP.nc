// inside this module we can avoid all the #ifndef since we have it outside it
#include "storing.h"

// maybe making it generic would also make it possible to get the caller
module StorageP @safe() {
    provides {
        // give also an interface to fetch the actual message with the last
        // n logs inside it
        interface Storage;
        interface Init;
    }

    uses {
        // configuration interfaces
        interface ConfigStorage as Config;
        interface Mount as Mount;
        // sensing timer
        interface Timer<TMilli> as SensingTimer;
        // sensor reading interfaces
        interface Read<data_t> as LightSensor;
        interface Read<data_t> as InfraSensor;
        interface Read<data_t> as TempSensor;
        interface Read<data_t> as HumSensor;
        // logging interfaces
        interface LogRead;
        interface LogWrite;
    }
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
    command logentry_t getLastLogEntry() {
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

    /** 
     * Every time the timer is fired we store all the new data
     * and put the pointer to the next position possible
     */
    event void SensingTimer.fired(){
        // store a new data sensed in the array structure
        SENSING_DATA[lastIdx].sense_time = call SensingTimer.getNow();
        call LightSensor.read();
        call HumSensor.read();
        call InfraSensor.read();
        call TempSensor.read();
        // HOW CAN WE BE SURE THAT THEY'RE SET ALWAYS BEFORE THE NEXT TIMER FIRES??

        // now we can go forward in our array
        lastIdx = (lastIdx + 1) % MAX_DATA;
    }

    void setSensingData(instr_t type, data_t data) {
        switch (type) {
        case SENS_LIGHT:
            SENSING_DATA[lastIdx].light = data;
            break;
        case SENS_INFRA:
            SENSING_DATA[lastIdx].infra = data;
            break;
        case SENS_TEMP:
            SENSING_DATA[lastIdx].temp = data;
            break;
        case SENS_HUMIDITY:
            SENSING_DATA[lastIdx].humidity = data;
        }
    }

    // events needed for the configuration protocol
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

    /****************/
    /* logging part */
    /****************/
    event void LogWrite.appendDone(void* buf, storage_len_t len, 
                                   bool recordsLost, error_t err) {
    }

    event void LogRead.seekDone(error_t err) {
    }

    event void LogWrite.syncDone(error_t err) {
    }

    
    event void LogWrite.eraseDone(error_t err) {
        if (err == SUCCESS) {
            m_busy = FALSE;
        }
        else {
            // Handle error.
        }
        call Leds.led0Off();
    }
    

    event void LightSensor.readDone(error_t result, data_t val){
        setSensingData(SENS_LIGHT, val);
    }

    event void InfraSensor.readDone(error_t result, data_t val){
        setSensingData(SENS_INFRA, val);
    }

    // don't use an #ifdef here since the humidity sensor is the one we're using
    // in the simulation, but this only depends on the order of wiring
    event void HumSensor.readDone(error_t result, data_t val){
        setSensingData(SENS_HUMIDITY, val);
    }

    event void TempSensor.readDone(error_t result, data_t val){
        setSensingData(SENS_TEMP, val);
    }
}
