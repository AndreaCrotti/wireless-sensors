/**
 * TODO: Also the master mote should be controllable without a working GUI environment
 */

public class OutputMaker {
    private BlinkGUI gui;
    private BlinkConsole console;
    private boolean has_gui;
    private String port;

    public OutputMaker(boolean has_gui, BlinkConnector connector, String port) {
        this.has_gui = has_gui;
        this.port = port;

        if (has_gui)
            gui = new BlinkGUI(connector);
        else
            console = new BlinkConsole();
    }

    public void print(String message) {
        // Adding port number to distinguish from where the message is coming from
        String msg = "PORT: " + port + "\n" + message;

        if (has_gui)
            gui.print(msg);
        else
            console.print(msg);
    }
}
