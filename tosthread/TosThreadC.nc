module TosThreadC {
    provides {
        interface Boot as BaseStationBoot;
        interface Boot as RadioBoot;
    }
    uses {
        interface Boot;
    }
}

implementation {

    event void Boot.booted() {
        if (TOS_NODE_ID == 0) {
            signal BaseStationBoot.booted();
        } else {
            signal RadioBoot.booted();
        }
    }
}
