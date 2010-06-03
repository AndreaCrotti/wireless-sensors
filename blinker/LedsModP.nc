module LedsModP @safe() {
    provides {
        interface LedsMod;
    }

    uses interface Leds;
}

implementation {
    async command void LedsMod.set(uint8_t val) {
        call Leds.set(val);
    }

    async command void LedsMod.blinkAll() {
        
    }

    async command void LedsMod.toogle(uint8_t idx) {
        
    }
}