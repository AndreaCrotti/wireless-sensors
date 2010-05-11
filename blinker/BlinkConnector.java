import javax.swing.JFrame;
import javax.swing.SwingUtilities;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

/**
 * @author Andrea Crotti, Marius Grysla, Oscar Dustmann
 * 
 * TODO: connect correctly connector & GUI
 * TODO: understand how to write on the debug output window
 * 
 */
public class BlinkConnector implements MessageListener {

    // A reference the the user interface
    private BlinkGUI gui;
    
    // The serial interface
    MoteIF moteInterface;
    
    // A sequential number
    short seqNo = 1;
    
    // The mote ID we communicate with directly
    int commID = 0;

    /**
     * Constructor of the BlinkConnector class.
     * 
     * @param moteInterface The interface to a node.
     */
    public BlinkConnector(MoteIF moteInterface){
    	this.moteInterface = moteInterface;
    	this.moteInterface.registerListener(new BlinkMsg(), this);
    }
    
    /**
     * Initializes the serial device and manages the communication.
     */
    public void start(){
        //TODO: Device initialization and communication as in TestSerial.java
        
    }

    /**
     * General method to send an arbitrary LED 
     * 
     * @param destination
     * @param mask
     */
    public void sendLedMask(short destination, short mask){
    	// Create the message
    	BlinkMsg message = new BlinkMsg();
    	
    	// Set the contents
    	message.set_dests(destination);
    	message.set_instr(mask);
    	message.set_seqno(this.seqNo++);
    	
    	gui.print("Sended message with mask " + mask + " and destination "+ destination);
    	
    	try{
            moteInterface.send(this.commID, message);
    	} catch(Exception e) {
            this.gui.print(e.getMessage());
    	}
    }
    
    /**
     * Implements the MessageListener interface.
     */
    public void messageReceived(int to, Message message) {
    	BlinkMsg msg = (BlinkMsg)message;
        System.out.println("Got a packet!");
    }


    /**
     * Sets the Gui to this Class.
     * 
     * @param gui A BlinkGui Instance.
     */
    public void setGui(BlinkGUI gui){
        this.gui = gui;
    }

    private static void usage() {
       	System.err.println("usage: BlinkConnector [-comm <source>]");
    }		
    
    /**
     * This function starts the program.
     * Both the connector class and the corresponding GUI are created and BlinkConnector.start() is called.
	 *
     * @param args Command-line arguments.
     */
    public static void main(String[] args) {
        // Check the command line arguments
    	String source = null;
        if (args.length == 2) {
          if (!args[0].equals("-comm")) {
    	usage();
    	System.exit(1);
          }
          source = args[1];
        }
        else if (args.length != 0) {
          usage();
          System.exit(1);
        }
    	
        PhoenixSource phoenix;
        
        if (source == null) {
          phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
        }
        else {
          phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
        }

        MoteIF mif = new MoteIF(phoenix);
        
    	// Create the Blink Connector
        BlinkConnector connector = new BlinkConnector(mif);

        // Create the Gui
        BlinkGUI gui = new BlinkGUI(connector);

        // Connect the GUI to the connector
        connector.setGui(gui);

        // Start the main cycle
        // connector.start();
    }

}
