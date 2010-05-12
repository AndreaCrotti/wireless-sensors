/**
 * @file   RelMod.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date   Tue May 11 15:59:40 2010
 * 
 * @brief  Implementation of the reliable protocol
 * We keep a list of neighbours which gets created dinamically with beacons packages
 * 
 */


module RelMod {
    // required interfaces to manage and send/receive packets
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface Receive;
    // serial interface
    //uses interface Packet as SerialPacket;
    //uses interface AMPacket as SerialAMPacket;
    //uses interface AMSend as SerialAMSend;
    uses interface Receive as SerialReceive;

    // used to control the ActiveMessageC component
    uses interface SplitControl as AMControl;
    uses interface SplitControl as SerialControl;
    
    // additional needed components
    uses interface Timer<TMilli> as Timer;
    uses interface CC2420Packet;

}

implementation {
  
}