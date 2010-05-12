COMPONENT=BlinkAppC
BUILD_EXTRA_DEPS += BlinkGUI.class
# BUILD_EXTRA_DEPS += BlinkConnector.class
CLEAN_EXTRA = *.class BlinkMsg.java
VERSION = 1.6

BlinkGUI.class: $(wildcard *.java) BlinkMsg.java
	javac -target $(VERSION) -source $(VERSION) *.java	

BlinkMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=BlinkMsg Blink.h BlinkMsg -o $@

include $(MAKERULES)

