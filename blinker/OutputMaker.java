public class OutputMaker {
    private BlinkGUI gui;
    private BlinkConsole console;
    private boolean has_gui;

    public OutputMaker(boolean has_gui, BlinkConnector connector) {
        this.has_gui = has_gui;

        if (has_gui)
            gui = new BlinkGUI(connector);
        else
            console = new BlinkConsole(connector);
    }

    public void print(String message) {
        if (has_gui)
            gui.print(message);
        else
            console.print(message);
    }
}
