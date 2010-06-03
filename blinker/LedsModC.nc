configuration LedsModC {
    provides interface LedsMod;
}


implementation {
    components LedsC;
    components LedsModP;
    
    LedsMod = LedsModP.LedsMod;
    LedsModP.Leds -> LedsC;
}