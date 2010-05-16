/**
 * Implementation of the reliable one-hop multicast primitive.
 * We will transmit a message repeatedly until we receive an acknowledgement from ALL recipients.
 * 
 * @file RultiC.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date Su 16. Mai 17:14:53 CEST 2010
 **/

configuration RultiC {
    provides interface Rulti;
}
implementation {
    components RultiP;

    Rulti = RultiP;
}
