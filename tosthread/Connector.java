import java.io.IOException;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

/**
 * @author Andrea Crotti, Marius Grysla, Oscar Dustmann
 * 
 * TODO: change it to start automatically the printf client instead
 */
public class Connector implements MessageListener {

    // The serial interface
    MoteIF moteInterface = null;
    
    // A sequential number
    short seqNo = 1;
    
    // The mote ID we communicate with directly
    int commID = 0;

    public void messageReceived(int to, Message message) {
        // print only the led settings
        CmdMsg msg = (CmdMsg) message;
        
        int sender = msg.get_sender();
        short instr = msg.get_instr();
        
        System.out.printf("From mote %d in ledmask %d %n", sender, instr);
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
        this.moteInterface.registerListener(message, this);
    }
    
    /**
     * Connects to a mote via serial cable.
     * 
     * @param ip The IP-Address
     * @param port The Port
     */
    public void connect(String ip, String port){
        String source = "sf@" + ip + ":" + port;
        
        try{
            connect(source);
        } catch(Exception e){
            output.print(e.getMessage());
        }
    }
    
    // FIXME: this just crashes when we try to connect to an unknown destination
    public void connect(String source) throws IOException{
        PhoenixSource phoenix;
        phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
                
        // Set the mote Interface
        this.moteInterface = new MoteIF(phoenix);
    }
    
    public void disconnect(){
        this.moteInterface = null;
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

        if (args.length < 2) {
            System.err.println("java Connector <ip> <port>");
            exit(1);
        }
            
        makeSerialConnector(makeSFIf(ip, master_port));
    }
}