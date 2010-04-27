// $Id: BlinkC.nc,v 1.5 2008/06/26 03:38:26 regehr Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/

#include <stdlib.h>

module BlinkC
{
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  uses interface Timer<TMilli> as Timer;
  uses interface Boot;
  uses interface Leds;
}
implementation
{
  int ch;
  event void Boot.booted()
  {
    dbg("BlinkC", "Booting first");
    dbg("BlinkC", "Booting");
    call Timer.startPeriodic( 1000 );
  }

  event void Timer.fired()
  {
    dbg("Boot", "Timer 0 fired @ %s.\n", sim_time_string());
       
    if (TOS_NODE_ID == 0) {
	       
      // Choose a random LED
      ch = (int) (random() * 3);
      // Turn all LEDs off
      call Leds.set(0);
      // Turn on the new LED
      switch(ch)
	{
	case '0':
	  call Leds.led0On();
	  break;
	case '1':
	  call Leds.led1On();
	  break;
	case '2':
	  call Leds.led2On();
	  break;
	}
    }
  }
  event void AMControl.startDone(error_t err) 
  {
  }
  event void AMControl.stopDone(error_t err)
  {
  }
  event void AMSend.sendDone(message_t* msg, error_t error) 
  {
  }
}

