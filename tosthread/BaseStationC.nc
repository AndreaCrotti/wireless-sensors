module BaseStationC {
  provides {
    interface Boot as BaseStationBoot;
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
    signal BaseStationBoot.booted();
  }  
}
