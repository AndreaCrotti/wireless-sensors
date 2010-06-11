#include "base_station.h"
#include "stack.h"
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
    components MainC, LedsC, TosThreadC;

    /********************************/
    /* SENDER COMPONENTS AND WIRING */
    /********************************/

    TosThreadC.Boot -> MainC;

    components Sender;
    components BlockingActiveMessageC;
    Sender.BlockingAMControl -> BlockingActiveMessageC;
    Sender.Leds -> LedsC;

    components new ThreadC(300) as RadioStressThread0;
    components new BlockingAMSenderC(220) as BlockingAMSender0;
    components new BlockingAMReceiverC(220) as BlockingAMReceiver0;
    Sender.RadioStressThread0 -> RadioStressThread0;
    Sender.BlockingAMSend0 -> BlockingAMSender0;
    Sender.BlockingReceive0 -> BlockingAMReceiver0;
  
    components new ThreadC(300) as RadioStressThread1;
    components new BlockingAMSenderC(221) as BlockingAMSender1;
    components new BlockingAMReceiverC(221) as BlockingAMReceiver1;
    Sender.RadioStressThread1 -> RadioStressThread1;
    Sender.BlockingAMSend1 -> BlockingAMSender1;
    Sender.BlockingReceive1 -> BlockingAMReceiver1;
  
    components new ThreadC(300) as RadioStressThread2;
    components new BlockingAMSenderC(222) as BlockingAMSender2;
    components new BlockingAMReceiverC(222) as BlockingAMReceiver2;
    Sender.RadioStressThread2 -> RadioStressThread2;
    Sender.BlockingAMSend2 -> BlockingAMSender2;
    Sender.BlockingReceive2 -> BlockingAMReceiver2;


    /**********************/
    /* BASESTATION WIRING */
    /**********************/
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
    SerialReceiveRadioSendP.BlockingAMSend -> BlockingRadioActiveMessageC;
}

