module BaseStationC {
    provides {
        interface Boot as BaseStationBoot;
        interface Boot as SenderBoot;
    }
    uses {
        interface Boot;    
        interface Thread as BootThread;
        interface BlockingStdControl as BlockingRadioAMControl;
        interface BlockingStdControl as BlockingSerialAMControl;
    }
}

implementation {

    event void Boot.booted() {
        call BootThread.start(NULL);
    }
  
    event void BootThread.run(void* arg) {
        call BlockingRadioAMControl.start();
        call BlockingSerialAMControl.start();

        if (TOS_NODE_ID == 0) {
            signal BaseStationBoot.booted();
        } else {
            signal SenderBoot.booted();
        }
    }  
}
