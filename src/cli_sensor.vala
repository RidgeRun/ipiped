public abstract class CliTarget : GLib.Object {
    /* Include the command's data in the array*/
    public abstract void register(IpipedCli cli);
}
