configuration StorageC {
    // when the storage stuff is started
    provides interface Init;
    provides interface Storage;
}

implementation {
    components new ConfigStorageC(VOLUME_CONFIGTEST);
    components StorageP;
    // Humidity and temperature
    components new SensirionSht11C() as SensirionC;
    // Infrared
    components new HamamatsuS10871TsrC() as PhotoActiveC;
    // Normal light
    components new HamamatsuS1087ParC() as TotalSolarC;

    StorageP.LightSensor -> TotalSolarC;
    StorageP.InfraSensor -> PhotoActiveC;
    StorageP.TempSensor -> SensirionC.Temperature;
    StorageP.HumSensor -> SensirionC.Humidity;

    StorageP.Config = ConfigStorageC.ConfigStorage;
    StorageP.Mount -> ConfigStorageC.Mount;
    Init = StorageP;
}