configuration StorageC {
    // when the storage stuff is started
    provides interface Init;
}

implementation {
#ifndef TOSSIM
    components new ConfigStorageC(VOLUME_CONFIGTEST);
    StorageC.Config -> ConfigStorageC.ConfigStorage;
    StorageC.Mount  -> ConfigStorageC.Mount;
#endif
}