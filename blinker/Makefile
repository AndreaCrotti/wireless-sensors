COMPONENT=BlinkAppC
BUILD_EXTRA_DEPS += BlinkGUI.class DebugMsg.py
# BUILD_EXTRA_DEPS += BlinkConnector.class
CLEAN_EXTRA = *.class BlinkMsg.java
VERSION = 1.6
DEFAULT_LOCAL_GROUP = 0x55
# set up the transmission power, min=1, max=31
CFLAGS += -DCC2420_DEF_RFPOWER=1

BlinkGUI.class: $(wildcard *.java) BlinkMsg.java
	javac -target $(VERSION) -source $(VERSION) *.java	

BlinkMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=BlinkMsg Blink.h BlinkMsg -o $@

DebugMsg.py:
	mig python -python-classname=DebugMsg Blink.h DebugMsg -o $@

include $(MAKERULES)

