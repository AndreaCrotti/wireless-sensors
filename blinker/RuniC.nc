/**
 * Implementation of the reliable one-hop unicast primitive.
 * We will transmit a message repeatedly until we receive an acknowledgement.
 * 
 * @file BlinkC.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 * @date So 2. Mai 21:14:53 CEST 2010
 **/

configuration RuniC {
  provides interface Runi;
}
implementation {
  components RuniP;

  Runi = RuniP;
}
