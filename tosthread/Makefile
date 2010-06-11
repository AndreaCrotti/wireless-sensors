COMPONENT=TosthreadsAppC
BUILD_EXTRA_DEPS += CmdMsg.java GUI.class
CLEAN_EXTRA = *.class CmdMsg.java #SerialMsg.py CmdMsg.py
JAVA_VERSION = 1.6
# This is the group of communication
# including directly python2.6 because no better way in sim.extra was found to change the include PATH
CFLAGS+=-DCC2420_NO_ACKNOWLEDGEMENTS
CFLAGS+=-DCC2420_NO_ADDRESS_RECOGNITION
CFLAGS+=-DTOSH_DATA_LENGTH=115

GUI.class: $(wildcard *.java) CmdMsg.java
	javac -target $(JAVA_VERSION) -source $(JAVA_VERSION) *.java

CmdMsg.java:
	mig java -java-classname=CmdMsg Tosthreads.h CmdMsg -o $@
include $(MAKERULES)
