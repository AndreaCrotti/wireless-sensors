COMPONENT=ThreadAppC
BUILD_EXTRA_DEPS += CmdMsg.java Connector.class
CLEAN_EXTRA = *.class CmdMsg.java
# This is the group of communication
# including directly python2.6 because no better way in sim.extra was found to change the include PATH
CFLAGS+=-DCC2420_NO_ACKNOWLEDGEMENTS
CFLAGS+=-DCC2420_NO_ADDRESS_RECOGNITION
CFLAGS+=-DTOSH_DATA_LENGTH=115

Connector.class: $(wildcard *.java) CmdMsg.java
	javac *.java

CmdMsg.java:
	mig java -target=telosb -java-classname=CmdMsg Tosthreads.h CmdMsg -o $@

include $(MAKERULES)
