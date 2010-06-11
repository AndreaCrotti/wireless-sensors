import java.io.IOException;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

/**
 * @author Andrea Crotti, Marius Grysla, Oscar Dustmann
 */
public class Connector implements MessageListener {

    // The serial interface
    MoteIF moteInterface = null;

    public void messageReceived(int to, Message message) {
        // print only the led settings
        CmdMsg msg = (CmdMsg) message;
        
        short instr = msg.get_instr();
        
        System.out.printf("Ledmask %d %n", instr);
    }

   /**
     * Constructor of the BlinkConnector class.
     * 
     * @param moteInterface The interface to a node.
     * @param Message type of the message to listen to
     */
    public Connector(MoteIF moteInterface, Message message){
        // we get as input the more generic message from Message
        this.moteInterface = moteInterface;
        this.moteInterface.registerListener(new CmdMsg(), this);
    }
    
    private static MoteIF makeSFIf(String ip, String port) {
        String source = "sf@" + ip  + ":" + port;
        PhoenixSource phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
        MoteIF mif = new MoteIF(phoenix);
        return mif;
    }
        
    /** 
     * Creates a new serial connection for the main mote
     * 
     * @param mif 
     */
    private static void makeSerialConnector(MoteIF mif) {
        Connector connector;
        connector = new Connector(mif, new CmdMsg());
    }

    /**
     * This function starts the program.
     * Both the connector class and the corresponding GUI are created and Connector.start() is called.
     *
     * @param args Command-line arguments.
     */
    public static void main(String[] args) {
        // Check the command line arguments
        String ip = null;
        String port = null;

        if (args.length < 2) {
            System.err.println("java Connector <ip> <port>");
            System.exit(1);
        }
        ip = args[0];
        port = args[1];
            
        makeSerialConnector(makeSFIf(ip, port));
    }
}