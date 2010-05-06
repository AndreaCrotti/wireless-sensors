/**
 * @file   Blink.h
 * @author Andrea Crotti, Marius Gysla
 * @date   Wed Apr 28 12:02:18 2010
 * 
 * @brief  Interface for Blink program
 * 
 * 
 */

#ifndef BLINK_H
#define BLINK_H

/// we only need the id number of the message and the index of the led to turn on
typedef nx_struct BlinkMsg {
nx_uint16_t id;
nx_uint16_t led_idx;
} BlinkMsg;

enum {
  AM_BLINK = 6,
  INTERVAL = 10000
};
 
#endif
