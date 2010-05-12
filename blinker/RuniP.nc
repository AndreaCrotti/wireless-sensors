#include "Runi.h"

/**
 * Implementation of the reliable one-hop unicast primitive.
 * We will transmit a message repeatedly until we receive an acknowledgement.
 * 
 * @file BlinkP.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date So 2. Mai 21:14:53 CEST 2010
 **/

module RuniP {
    // required interfaces to manage and send/receive packets
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend as PayloadSend;
    uses interface Receive as PayloadSend;
    uses interface AMSend as AckSend;
    uses interface Receive as AckReceive;

    // additional needed components
    uses interface Timer<TMilli> as Timer;
    uses interface CC2420Packet;
}

implementation {

}

