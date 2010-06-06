configuration StorageC {
    // when the storage stuff is started
    provides interface Init;
}

implementation {
    components new ConfigStorageC(VOLUME_CONFIGTEST);
    components StorageP;

    StorageP.Config = ConfigStorageC.ConfigStorage;
    StorageP.Mount -> ConfigStorageC.Mount;
    Init = StorageP;
}