/**
 * @file   Blink.h
 * @author Andrea Crotti, Marius Gysla
 * @date   Wed Apr 28 12:02:18 2010
 * 
 * @brief  Interface for Blink program
 * 
 * 
 */

#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

/// we only need the id number of the message and the index of the led to turn on
typedef nx_struct BlinkToRadioMsg {
nx_uint16_t id;
nx_uint16_t led_idx;
} BlinkToRadioMsg;

/// Interval of the timer in Milliseconds
enum {
  /// type of the sent message
  AM_BLINKTORADIO = 6,
  INTERVAL = 10000
};
 
#endif
