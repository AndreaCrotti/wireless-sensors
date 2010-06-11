#include "base_station.h"
#include "message.h"

/**
 * 
 * @file   TosthreadsAppC.nc
 * @author Andrea Crotti, Marius Grysla, Oscar Dustmann
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
    components MainC, LedsC, TosThreadC;

    /********************************/
    /* SENDER COMPONENTS AND WIRING */
    /********************************/

    TosThreadC.Boot -> MainC;

    components Radio;
    Radio.Boot -> TosThreadC.RadioBoot;
    components BlockingActiveMessageC as BlockingRadioActiveMessageC;
    Radio.BlockingAMControl -> BlockingRadioActiveMessageC;
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
    /**********************/
    components BaseStationC,
        new BaseSendReceiveP() as RadioReceiveSerialSendP,
        new BaseSendReceiveP() as SerialReceiveRadioSendP,
             
        new ThreadC(BOOT_THREAD_STACK_SIZE) as BootThreadBS,
        new ThreadC(RADIO_RECEIVE_THREAD_STACK_SIZE) as RadioReceiveThreadBS,
        new ThreadC(RADIO_SNOOP_THREAD_STACK_SIZE) as RadioSnoopThreadBS,
        new ThreadC(SERIAL_SEND_THREAD_STACK_SIZE) as SerialSendThreadBS,
        new ThreadC(SERIAL_RECEIVE_THREAD_STACK_SIZE) as SerialReceiveThreadBS,
        new ThreadC(RADIO_SEND_THREAD_STACK_SIZE) as RadioSendThreadBS,
             
        new PoolC(message_t, BASE_STATION_MSG_QUEUE_SIZE) as RadioReceivePool,
        new QueueC(message_t*, BASE_STATION_MSG_QUEUE_SIZE) as RadioReceiveQueue,
        new PoolC(message_t, BASE_STATION_MSG_QUEUE_SIZE) as SerialReceivePool,
        new QueueC(message_t*, BASE_STATION_MSG_QUEUE_SIZE) as SerialReceiveQueue,
             
        ThreadSynchronizationC;

    BaseStationC.Boot -> TosThreadC.BaseStationBoot;
    RadioReceiveSerialSendP.Boot -> BaseStationC;
    SerialReceiveRadioSendP.Boot -> BaseStationC;

    BaseStationC.BootThread -> BootThreadBS;
    RadioReceiveSerialSendP.ReceiveThread -> RadioReceiveThreadBS;
    RadioReceiveSerialSendP.SnoopThread -> RadioSnoopThreadBS;
    RadioReceiveSerialSendP.SendThread -> SerialSendThreadBS;
    SerialReceiveRadioSendP.ReceiveThread -> SerialReceiveThreadBS;
    SerialReceiveRadioSendP.SendThread -> RadioSendThreadBS;  
  
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
  
    components BlockingActiveMessageC as BlockingRadioActiveMessageBSC;
    components BlockingSerialActiveMessageC as BlockingSerialActiveMessageBSC;
             
    BaseStationC.BlockingRadioAMControl -> BlockingRadioActiveMessageBSC;
    BaseStationC.BlockingSerialAMControl -> BlockingSerialActiveMessageBSC;
  
    RadioReceiveSerialSendP.ReceivePacket -> BlockingRadioActiveMessageBSC;
    RadioReceiveSerialSendP.SendPacket -> BlockingSerialActiveMessageBSC;
    RadioReceiveSerialSendP.ReceiveAMPacket -> BlockingRadioActiveMessageBSC;
    RadioReceiveSerialSendP.SendAMPacket -> BlockingSerialActiveMessageBSC;             
    RadioReceiveSerialSendP.BlockingReceiveAny -> BlockingRadioActiveMessageBSC.BlockingReceiveAny;
    RadioReceiveSerialSendP.BlockingSnoopAny -> BlockingRadioActiveMessageBSC.BlockingSnoopAny;
    RadioReceiveSerialSendP.BlockingAMSend -> BlockingSerialActiveMessageBSC;
  
    SerialReceiveRadioSendP.ReceivePacket -> BlockingSerialActiveMessageBSC;
    SerialReceiveRadioSendP.SendPacket -> BlockingRadioActiveMessageBSC;
    SerialReceiveRadioSendP.ReceiveAMPacket -> BlockingSerialActiveMessageBSC;
    SerialReceiveRadioSendP.SendAMPacket -> BlockingRadioActiveMessageBSC;             
    SerialReceiveRadioSendP.BlockingReceiveAny -> BlockingSerialActiveMessageBSC.BlockingReceiveAny;
    SerialReceiveRadioSendP.BlockingAMSend -> BlockingRadioActiveMessageBSC;
}

