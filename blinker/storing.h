/**
 * @file   storage.h
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Wed Jun  2 18:52:35 2010
 * 
 * @brief  Keeping data structures and constants for storage
 * 
 * 
 */
#ifndef STORING_H
#define STORING_H


enum {
    // Sensing time in milliseconds
    SENSE_TIME = 1000,
    MAX_DATA   = 10
};

// configuration enums
enum {
    // TODO: check exactly what is this CONFIG_ADDR used for
    CONFIG_ADDR    = 0,
    CONFIG_VERSION = 1,
    DEFAULT_PERIOD = 1024,
    MIN_PERIOD     = 128,
    MAX_PERIOD     = 1024
};

// log entry, I can't send it straight away in every case
typedef nx_struct logentry_t {
    nx_uint8_t len;
    message_t msg;
} logentry_t;


// see how big it should be the payload, if it's possible to do some compression and in which layer it would be possible to do it
// We could for example use only the delta of the change since another relevation
// in this way we can gain a lot of space automatically

// structure to keep the sensed data
// this can be also used with non network-safe types
// it's only used to store on the flash disk, but the messages to be sent
// will take the data from here
typedef struct sensing_entry_t {
    uint32_t sense_time;
    data_t light;
    data_t humidity;
    data_t infra;
    data_t temp;
} sensing_entry_t;

// we can keep a pool of log entries and send them when requested
// maybe checking how many of them have been sended

// configuration entries, we could keep some thresholds to use later

typedef struct sense_config_t {
    uint16_t sample_period;
    uint16_t temp_high_threshold;
    uint16_t temp_low_threshold;
    uint16_t max_values;
} sense_config_t;

#endif
