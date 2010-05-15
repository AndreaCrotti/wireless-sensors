/**
 * Propagate a "command" in the sensor network.
 * Command is: Toggle one of the three LEDs.
 * Node 0 initiates a command every 10 seconds.
 * The command is chosen randomly. Commands have seq-numbers to avoid loops.
 *
 * \author oscar.dustmann@rwth-aachen.de
 **/

configuration PrlAppC {
}
implementation {
  components MainC;
  components PrlC;
  components LedsC;
  components RandomC;
  components new TimerMilliC() as Timer;

  components ActiveMessageC;
  components new AMSenderC(AMID_PRL_MSG) as PrlSender;
  components new AMReceiverC(AMID_PRL_MSG) as PrlReceiver;


  PrlC.Boot -> MainC.Boot;

  PrlC.Timer -> Timer.Timer;
  PrlC.Leds -> LedsC.Leds;
  PrlC.Random -> RandomC.Random;

  PrlC.Packet -> PrlSender.Packet;
  PrlC.AMSend -> PrlSender.AMSend;
  PrlC.AMSplitControl -> ActiveMessageC.SplitControl;
  PrlC.Receive -> PrlReceiver.Receive;
}

