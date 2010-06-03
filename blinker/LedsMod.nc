interface LedsMod {
    async command void set(uint8_t val);
    
    /** 
     * Start making all the leds blinking
     * 
     */
    async command void blinkAll();
    
    
    /** 
     * Turn ON/OFF a specific led 
     * 
     */
    async command void toogle(uint8_t idx);
}