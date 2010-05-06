import javax.swing.JFrame;
import javax.swing.SwingUtilities;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;

/**
 * 
 */

/**
 * @author marius
 *
 */
public class BlinkConnector implements MessageListener {

	// A reference the the user interface
	private BlinkGUI gui;
	
	/**
	 * Initializes the serial device and manages the communication.
	 */
	public void start(){
		//TODO: Device initialization and communication as in TestSerial.java
	}
	
	/**
	 * Implements the MessageListener interface.
	 */
	public void messageReceived(int arg0, Message arg1) {
		// TODO Auto-generated method stub
	}
	
	/**
	 * Sets the Gui to this Class.
	 * 
	 * @param gui A BlinkGui Instance.
	 */
	public void setGui(BlinkGUI gui){
		this.gui = gui;
	}
	
	/**
	 * This function starts the program.
	 * Both the connector class and the corresponding GUI are created and BlinkConnector.start() is called.
	 * 
	 * @param args Command-line arguments.
	 */
	public static void main(String[] args) {
		// Create the Blink Connector
		BlinkConnector connector = new BlinkConnector();
		
		// Create the Gui
		BlinkGUI gui = new BlinkGUI(connector);
		
		// Connect the GUI to the connector
		connector.setGui(gui);
		
		// Start the main cycle
		connector.start();
	}

}
