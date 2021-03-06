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
configuration TosthreadsAppC @safe() {
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
    components new ThreadC(SERIAL_RECEIVE_THREAD_STACK_SIZE) as SerialReceiveThread;

    components ActiveMessageAddressC;
    
    // For serial/radio communication;
    components new BlockingAMSenderC(AM_TOSTHREADS) as RadioSender;
    components new BlockingAMReceiverC(AM_TOSTHREADS) as RadioReceiver;
    components BlockingActiveMessageC as BlockingRadioActiveMessageC;             
    components new BlockingAMReceiverC(AM_SERIAL_TOSTHREADS) as SerialReceiver;
    components BlockingActiveMessageC as BlockingSerialActiveMessageC;
    
    // Queue and Pool
    components new PoolC(message_t, QUEUE_SIZE) as RadioPool;
    components new QueueC(message_t*, QUEUE_SIZE) as RadioQueue;

    components ThreadSynchronizationC;

    /**********/
    /* Wiring */
    /**********/
    
    TosthreadsP.Boot -> MainC;
    TosthreadsP.Leds -> LedsC;
    
    // Wiring the packet access to an arbitrary Active message module
    TosthreadsP.Packet -> BlockingSerialActiveMessageC;
    TosthreadsP.AMPacket -> BlockingSerialActiveMessageC;

    TosthreadsP.RadioControl -> BlockingRadioActiveMessageC;
    TosthreadsP.RadioSend -> RadioSender;
    TosthreadsP.RadioReceive -> RadioReceiver;

    TosthreadsP.RadioQueue -> RadioQueue;
    TosthreadsP.RadioPool -> RadioPool;

    TosthreadsP.SerialControl -> BlockingSerialActiveMessageC;
    TosthreadsP.SerialReceive -> SerialReceiver;

    TosthreadsP.ActiveMessageAddress -> ActiveMessageAddressC;

    // Wire the threads
    TosthreadsP.BootThread -> BootThread;
    TosthreadsP.SerialReceiveThread -> SerialReceiveThread;
    TosthreadsP.RadioSendThread -> RadioSendThread;
    TosthreadsP.RadioReceiveThread -> RadioReceiveThread;

    // Thread synchronization
    TosthreadsP.ConditionVariable -> ThreadSynchronizationC;
    TosthreadsP.Mutex -> ThreadSynchronizationC;
}

