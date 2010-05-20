/**
 * TODO: Also the master mote should be controllable without a working GUI environment
 */

public class OutputMaker {
    private BlinkGUI gui;
    private BlinkConsole console;
    private boolean has_gui;
    private String port;

    public OutputMaker(boolean has_gui, BlinkConnector connector) {
        this.has_gui = has_gui;
        if (has_gui)
            gui = new BlinkGUI(connector);
        else
            // Not passing the connector since we can only output from the console at the moment
            console = new BlinkConsole();
    }

    public void print(String message) {
        // Adding port number to distinguish from where the message is coming from
        if (has_gui)
            gui.print(message);
        else
            console.print(message);
    }
}
