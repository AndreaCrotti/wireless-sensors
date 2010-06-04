/**
 * @file   Storage.h
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Wed Jun  2 18:52:35 2010
 * 
 * @brief  Keeping data structures and constants for storage
 * 
 * 
 */
#ifndef STORAGE_H
#define STORAGE_H


enum {
    // Sensing time in milliseconds
    SENSETIME = 1000
};

// log entry
typedef nx_struct logentry_t {
    nx_uint8_t len;
    message_t msg;
} logentry_t;

// structure to keep the sensed data
// this can be also used with non network-safe types
// it will be inserted later in the payload of logentry_t
typedef struct sensing_entry_t {
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
