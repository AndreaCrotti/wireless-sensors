COMPONENT=BlinkAppC
BUILD_EXTRA_DEPS += SerialMsg BlinkMsg.java BlinkGUI.class BlinkConsole.class
CLEAN_EXTRA = *.class BlinkMsg.java SerialMsg.py
JAVA_VERSION = 1.6
# This is the group of communication
DEFAULT_LOCAL_GROUP = 0x55
# set up the transmission power: min=1, max=31
POWER = 15
CFLAGS += -DCC2420_DEF_RFPOWER=$(POWER) -I$(TOSDIR)/lib/printf

BlinkGUI.class: $(wildcard *.java) BlinkMsg.java
	javac -target $(JAVA_VERSION) -source $(JAVA_VERSION) *.java

BlinkConsole.class: $(wildcard *.java) BlinkMsg.java
	javac -target $(JAVA_VERSION) -source $(JAVA_VERSION) *.java

BlinkMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=BlinkMsg Blink.h BlinkMsg -o $@

SerialMsg:
	mig python -target=null -python-classname=SerialMsg Blink.h BlinkMsg -o SerialMsg.py

include $(MAKERULES)

