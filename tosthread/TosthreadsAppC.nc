#include "Tosthreads.h"

/**
 * 
 * @file   TosthreadsAppC.nc
 * @author Andrea Crotti, Marius Gysla, Oscar Dustmann
 *
 * @date   So 2. Mai 21:11:02 CEST 2010
 * 
 * This files creates all tasks and components and wires them to the TosthreadsC file.
 *
 */
configuration TosthreadsAppC /*@safe()*/ {
}

implementation {
    // Standart components
    components MainC, LedsC;
    
    // Application files
    components TosthreadsP;
    
    // Create the needed threads
    components new ThreadC(BOOT_THREAD_STACK_SIZE) as BootThread;
    components new ThreadC(RADIO_RECEIVE_THREAD_STACK_SIZE) as RadioReceiveThread;
    components new ThreadC(RADIO_SEND_THREAD_STACK_SIZE) as RadioSendThread;
    components new ThreadC(SERIAL_SEND_THREAD_STACK_SIZE) as SerialSendThread;
    components new ThreadC(SERIAL_RECEIVE_THREAD_STACK_SIZE) as SerialReceiveThread;

   
    components ActiveMessageAddressC;
    
    // For serial/radio communication;
    components BlockingActiveMessageC as BlockingRadioActiveMessageC;             
    components BlockingActiveMessageC as BlockingSerialActiveMessageC;

    components ThreadSynchronizationC;

    /**********/
    /* Wiring */
    /**********/
    
    TosthreadsP.Boot -> MainC;
    TosthreadsP.Leds -> LedsC;
    
    // Wiring the packet access to an arbitrary Active message module
    TosthreadsP.Packet -> BlockingSerialActiveMessageC;

    TosthreadsP.RadioControl -> BlockingRadioActiveMessageC;
    TosthreadsP.RadioSend -> BlockingRadioActiveMessageC;
    TosthreadsP.RadioReceive -> BlockingRadioActiveMessageC.BlockingReceiveAny;

    TosthreadsP.SerialControl -> BlockingSerialActiveMessageC;
    TosthreadsP.SerialSend -> BlockingSerialActiveMessageC;
    TosthreadsP.SerialReceive -> BlockingSerialActiveMessageC.BlockingReceiveAny;

    TosthreadsP.ActiveMessageAddress -> ActiveMessageAddressC;

    // Wire the threads
    TosthreadsP.BootThread -> BootThread;
}

