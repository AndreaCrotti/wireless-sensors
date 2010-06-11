import java.io.IOException;

import javax.swing.JFrame;
import javax.swing.SwingUtilities;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

import net.tinyos.tools.PrintfClient;

/**
 * @author Andrea Crotti, Marius Grysla, Oscar Dustmann
 * 
 * TODO: change it to start automatically the printf client instead
 */
public class Connector implements MessageListener {

    // A reference the the user interface
    private OutputMaker output;
    
    // The serial interface
    MoteIF moteInterface = null;
    
    // A sequential number
    short seqNo = 1;
    
    // The mote ID we communicate with directly
    int commID = 0;

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

    /**
     * General method to send an arbitrary LED 
     * 
     * @param destination
     * @param mask
     */
    public void sendLedMask(short destination, short mask) {
        // Create the message
        CmdMsg message = new CmdMsg();
        
        // Set the contents
        message.set_dests(destination);
        message.set_instr(mask);
        message.set_seqno(this.seqNo++);
        
        output.print("Sended message with mask " + mask + " and destination "+ destination + " seq number " + message.get_seqno());
        
        try {
            moteInterface.send(this.commID, message);
        } catch(Exception e) {
            this.output.print(e.getMessage());
        }
    }
    
    /**
     * Implements the MessageListener interface.
     */
    public void messageReceived(int to, Message message) { }

    /**
     * Get the ID of a mote from the bitmask
     * Works when only one bit is set to 1
     * 
     * @param int bitmask to convert
     * @return index of the mote
     */
    public int getIDFromBM(int bm){
        int local_bm = bm;
        int counter = 0;
        local_bm >>= 1;
        while(local_bm != 0){
            local_bm >>= 1;
            counter++;
        }
        return counter;
    }
    
    /**
     * Sets the Output to this Class.
     * 
     * @param output A OutputMaker Instance.
     */
    public void setOutput(OutputMaker output){
        this.output = output;
    }

    private static void usage() {
        System.err.println("usage: Connector <ip addr> <port master node> [port debug node1] ...");
        System.exit(1);
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
        // FIXME:now the GUI is hard wired to true, fix this stuff
        connector.setOutput(new OutputMaker(true, connector));
    }

    
    /** 
     * Creating the print connector
     * 
     * @param mif 
     */
    private static void makePrintfConnector(MoteIF mif) {
        // this is also a subclass of MessageListener, so it should automatically start a new one
        PrintfClient client = new PrintfClient(mif);
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
        String[] debug_ports = null; 
        String master_port = null;

        if (args.length < 2)
            usage();
            
        else {
            ip = args[0];
            master_port = args[1];
            debug_ports = new String[args.length - 2];
            
            // for all the other ports given in input I can simply start the
            // printf daemon
            
            for (int i = 2; i < args.length; i++) {
                debug_ports[i-2] = args[i];
            }
        }
        
        makeSerialConnector(makeSFIf(ip, master_port));

        // Connects all the other motes in debug mode only
        for (String port : debug_ports) {
            makePrintfConnector(makeSFIf(ip, port));
        }
        
    }
}