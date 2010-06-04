configuration StorageC {
    // when the storage stuff is started
    provides interface Init;
}

implementation {
    components StorageP;
    Init = StorageP;
}