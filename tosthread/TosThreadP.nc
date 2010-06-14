/**
 * @file   TosThreadP.nc
 * @author Marius Grysla, Andrea Crotti, Oscar Dustmann
 * @date   Mon Jun 14 13:40:48 2010
 * 
 * @brief  Boots either the Radio or the BaseStation module, depending on the motes id.
 */


module TosThreadP {
    provides {
        // The two Boot interfaces
        interface Boot as BaseStationBoot;
        interface Boot as RadioBoot;
    }
    uses {
        interface Boot;
    }
}

implementation {
    /** 
     * Is called, when the Mote is Booted adn boots either the Radio or the BaseStation
     * module then.
     */
    event void Boot.booted() {
        // it's like programming the motes with different programs but
        // directly from software
        if (TOS_NODE_ID == 0) {
            signal BaseStationBoot.booted();
        } else {
            signal RadioBoot.booted();
        }
    }
}
