module LedsModP @safe() {
    provides interface LedsMod;

    uses interface Leds;
}

implementation {
    async command void LedsMod.set(uint8_t val) {
        call Leds.set(val);
    }

    async command void LedsMod.blinkAll() {
        // start a very fast timer that turns on and off all the leds for some time
    }

    async command void LedsMod.toogle(uint8_t idx) {
        
    }
}