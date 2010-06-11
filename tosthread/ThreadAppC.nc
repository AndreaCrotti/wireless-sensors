#include "base_station.h"
//include "stack.h"
#include "message.h"

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
configuration ThreadAppC {
}

implementation {
    // Standart components
    components MainC, LedsC;//, TosThreadC;

    /********************************/
    /* SENDER COMPONENTS AND WIRING */
    /********************************/

   // TosThreadC.Boot -> MainC;

    components Radio;
    components BlockingActiveMessageC;
    /////// XXX
    Radio.Boot -> MainC;
    Radio.BlockingAMControl -> BlockingActiveMessageC;
    Radio.Leds -> LedsC;

    components new ThreadC(THREAD_STACK_RADIO_SEND) as RadioSendThread;
    components new BlockingAMSenderC(AM_RADIO_TOSTHREADS) as BlockingSenderC;
    Radio.BlockingSendThread -> RadioSendThread;
    Radio.BlockingAMSend -> BlockingSenderC;
    Radio.Packet -> BlockingSenderC;
    components new ThreadC(THREAD_STACK_RADIO_RECEIVE) as RadioReceiveThread;
    components new BlockingAMReceiverC(AM_RADIO_TOSTHREADS) as BlockingReceive;
    Radio.BlockingReceiveThread -> RadioReceiveThread;
    Radio.BlockingReceive -> BlockingReceive;
  

    /**********************/
    /* BASESTATION WIRING */
    /**********************
    components BaseStationC,
        new BaseSendReceiveP() as RadioReceiveSerialSendP,
        new BaseSendReceiveP() as SerialReceiveRadioSendP,
             
        new ThreadC(BOOT_THREAD_STACK_SIZE) as BootThread,
        new ThreadC(RADIO_RECEIVE_THREAD_STACK_SIZE) as RadioReceiveThread,
        new ThreadC(RADIO_SNOOP_THREAD_STACK_SIZE) as RadioSnoopThread,
        new ThreadC(SERIAL_SEND_THREAD_STACK_SIZE) as SerialSendThread,
        new ThreadC(SERIAL_RECEIVE_THREAD_STACK_SIZE) as SerialReceiveThread,
        new ThreadC(RADIO_SEND_THREAD_STACK_SIZE) as RadioSendThread,
             
        new PoolC(message_t, BASE_STATION_MSG_QUEUE_SIZE) as RadioReceivePool,
        new QueueC(message_t*, BASE_STATION_MSG_QUEUE_SIZE) as RadioReceiveQueue,
        new PoolC(message_t, BASE_STATION_MSG_QUEUE_SIZE) as SerialReceivePool,
        new QueueC(message_t*, BASE_STATION_MSG_QUEUE_SIZE) as SerialReceiveQueue,
             
        ThreadSynchronizationC;


    RadioReceiveSerialSendP.Boot -> BaseStationC;
    SerialReceiveRadioSendP.Boot -> BaseStationC;

    BaseStationC.BootThread -> BootThread;
    RadioReceiveSerialSendP.ReceiveThread -> RadioReceiveThread;
    RadioReceiveSerialSendP.SnoopThread -> RadioSnoopThread;
    RadioReceiveSerialSendP.SendThread -> SerialSendThread;
    SerialReceiveRadioSendP.ReceiveThread -> SerialReceiveThread;
    SerialReceiveRadioSendP.SendThread -> RadioSendThread;  
  
    RadioReceiveSerialSendP.Pool -> RadioReceivePool;
    RadioReceiveSerialSendP.Queue -> RadioReceiveQueue;
    SerialReceiveRadioSendP.Pool -> SerialReceivePool;  
    SerialReceiveRadioSendP.Queue -> SerialReceiveQueue;
  
    RadioReceiveSerialSendP.ConditionVariable -> ThreadSynchronizationC;
    RadioReceiveSerialSendP.Mutex -> ThreadSynchronizationC;
    RadioReceiveSerialSendP.Leds -> LedsC;
    SerialReceiveRadioSendP.ConditionVariable -> ThreadSynchronizationC;
    SerialReceiveRadioSendP.Mutex -> ThreadSynchronizationC;
    SerialReceiveRadioSendP.Leds -> LedsC;
  
    components BlockingActiveMessageC as BlockingRadioActiveMessageC,             
        BlockingSerialActiveMessageC;
             
    BaseStationC.BlockingRadioAMControl -> BlockingRadioActiveMessageC;
    BaseStationC.BlockingSerialAMControl -> BlockingSerialActiveMessageC;
  
    RadioReceiveSerialSendP.ReceivePacket -> BlockingRadioActiveMessageC;
    RadioReceiveSerialSendP.SendPacket -> BlockingSerialActiveMessageC;
    RadioReceiveSerialSendP.ReceiveAMPacket -> BlockingRadioActiveMessageC;
    RadioReceiveSerialSendP.SendAMPacket -> BlockingSerialActiveMessageC;             
    RadioReceiveSerialSendP.BlockingReceiveAny -> BlockingRadioActiveMessageC.BlockingReceiveAny;
    RadioReceiveSerialSendP.BlockingSnoopAny -> BlockingRadioActiveMessageC.BlockingSnoopAny;
    RadioReceiveSerialSendP.BlockingAMSend -> BlockingSerialActiveMessageC;
  
    SerialReceiveRadioSendP.ReceivePacket -> BlockingSerialActiveMessageC;
    SerialReceiveRadioSendP.SendPacket -> BlockingRadioActiveMessageC;
    SerialReceiveRadioSendP.ReceiveAMPacket -> BlockingSerialActiveMessageC;
    SerialReceiveRadioSendP.SendAMPacket -> BlockingRadioActiveMessageC;             
    SerialReceiveRadioSendP.BlockingReceiveAny -> BlockingSerialActiveMessageC.BlockingReceiveAny;
    SerialReceiveRadioSendP.BlockingAMSend -> BlockingRadioActiveMessageC; */
}

