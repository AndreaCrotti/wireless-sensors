/**
 * @file   NeighBourMod.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Tue May 11 17:16:24 2010
 * 
 * @brief  Module to keep the neighbour list of every mote.
 * We use the RADIO package to send beacons through the wireless
 * The neighbor list is simply a 16 bit integer with the correct bits set up
 * 
 */

module NeighBorMod {
    // radio part
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface Receive;

    // maybe seconds could be also enough
    uses interface Timer<TMilli> as Timer;
    
    provides interface 
}

implementation {
    // 2 seconds every beacon, 15 seconds is the timeout
    command void startTimer() {
        Timer.startPeriodic(1000);
    }
}
