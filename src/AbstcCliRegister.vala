public abstract class AbstcCliRegister : GLib.Object {
    /* Include the command's data in the array*/
    public abstract void registration(IpipeCli cli) throws IOError;
}
