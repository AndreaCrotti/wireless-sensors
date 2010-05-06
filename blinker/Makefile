COMPONENT=BlinkAppC
BUILD_EXTRA_DEPS += BlinkGUI.class
# BUILD_EXTRA_DEPS += BlinkConnector.class
CLEAN_EXTRA = *.class BlinkMsg.java

BlinkGUI.class: $(wildcard *.java) BlinkMsg.java
	javac -target 1.4 -source 1.4 *.java	

BlinkMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=BlinkMsg Blink.h BlinkMsg -o $@

include $(MAKERULES)

