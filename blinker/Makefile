COMPONENT=BlinkAppC
BUILD_EXTRA_DEPS += BlinkGUI.class BlinkConsole.class DebugMsg.py DebugMsg.java BlinkMsg.java
# BUILD_EXTRA_DEPS += BlinkConnector.class
CLEAN_EXTRA = *.class BlinkMsg.java DebugMsg.py DebugMsg.java
JAVA_VERSION = 1.6
# This is the group of communication
DEFAULT_LOCAL_GROUP = 0x55
# set up the transmission power: min=1, max=31
CFLAGS += -DCC2420_DEF_RFPOWER=1
GOALS += dist

BlinkGUI.class: $(wildcard *.java) BlinkMsg.java
	javac -target $(JAVA_VERSION) -source $(JAVA_VERSION) *.java

BlinkConsole.class: $(wildcard *.java) BlinkMsg.java
	javac -target $(JAVA_VERSION) -source $(JAVA_VERSION) *.java

BlinkMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=BlinkMsg Blink.h BlinkMsg -o $@

DebugMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=DebugMsg Blink.h DebugMsg -o $@


# FIXME: this it's not getting called yet
DebugMsg.py:
	mig python -python-classname=DebugMsg Blink.h DebugMsg -o $@

dist:
	git archive --format tar --output task_sensornet1.tar HEAD

include $(MAKERULES)

