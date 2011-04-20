/**
 * Command
 * This class is a template for a command information. It includes the command 
 * name, the function that has to be executed and the explanation of the 
 * command syntax, function arguments and command description
 */
public class IpipeCommand:GLib.Object {

    public string name;
    public CmdFunc cmd_func;
    public string usage;
    public string doc;
    public string args;

    public delegate int CmdFunc(string[]? s);

    /** Command constructor. Creates an object for a specific command
     * @param _name string of the command name 
     * @param _cmd function that has to be call for the command
     * @param _usage syntax required in order to execute the command in the 
     * command line
     * @param _doc description of the command funcionality
     * @param _args explanation of the function's arguments
     */
    public IpipeCommand(string _name, CmdFunc _cmd, string _usage, string _doc, 
        string _args) {
        this.name = _name;
        this.cmd_func = _cmd;
        this.usage = _usage;
        this.doc = _doc;
        this.args = _args;
    } 

    public IpipeCommand.empty() {
        this.name = "";
        this.cmd_func = null;
        this.usage = "";
        this.doc = "";
        this.args = "";
    }

    ~IpipeCommand() {
    }
}

/**
 * CommandManage
 * This class is a template for a command management information. It include 
 * an array of Command and functions to manipulate them. It is capable of 
 * create and add new commands, find a especific command, execute command's 
 * functions and display the help information.
 */
public class CommandManager:GLib.Object {

    private IpipeCommand[] CmdMap = { };
    /** Command constructor. Creates an object for a specific command
     * @param _name string of the command name 
     * @param _cmd function that has to be call for the command
     * @param _usage syntax required in order to execute the command in the 
     * command line
     * @param _doc description of the command funcionality
     * @param _args explanation of the function's arguments
     */
    public CommandManager() {

    } 

    public  void new_command(string _name, IpipeCommand.CmdFunc _cmdfunc,
        string _usage, string _doc, string _args) {
        IpipeCommand new_cmd = new IpipeCommand(_name, _cmdfunc, _usage, _doc, _args);
        CmdMap += new_cmd;
        return;
    }
    
    /**
     * Look up 'name' as the name of a command, and returns in 'cmd' 
     * the CmdMap instances that matches with the given name.
     * Return non-zero if name isn't a command name. */
    public IpipeCommand ? find_command(string name) {

        int ind;
        for (ind = 0; ind < CmdMap.length; ind++)
            if (strcmp(name, CmdMap[ind].name) == 0) {
                return CmdMap[ind];
            }
        return null;
    }
    /* Execute a command. */
    public int execute_cmd(string[]args) {
        
        IpipeCommand Cmd = new IpipeCommand.empty();
        Cmd = find_command(args[0]);
        if (Cmd == null) {
            stdout.printf("%s: No such command for IpipeClient.\n", args[0]);
            return (1);
        }

        /* Call the function. */
        return (Cmd.cmd_func((string[])args));
    }
    
    public int command_help(string[]? args) {
        int ind;
        int printed = 0;

        for (ind = 0; ind < CmdMap.length; ind++) {
            if (args[1] == null) {
                if (printed == 0)
                    stdout.printf ("Request the syntax of an specific command with " +
                        "\"help <command>\".\n" +
                        "This is the list of supported commands:\n" +
                        "\nCOMMANDS supported:\n\nCommand\t\t\t\tDescription\n\n");
                if (CmdMap[ind].name.length < 8) {
                   stdout.printf("%s\t\t\t%s.\n", CmdMap[ind].name, 
                        CmdMap[ind].doc);
                } else if (CmdMap[ind].name.length < 16){
                    stdout.printf("%s\t\t%s.\n", CmdMap[ind].name, 
                        CmdMap[ind].doc);
                } else {
                   stdout.printf("%s\t%s.\n", CmdMap[ind].name,
                        CmdMap[ind].doc);
                }
                printed++;
            } else if (strcmp(args[1], CmdMap[ind].name) == 0){
                stdout.printf ("\nCommand: %s\n", CmdMap[ind].name);
                stdout.printf ("Syntax: %s\n", CmdMap[ind].usage); 
                stdout.printf ("Description: %s\n", CmdMap[ind].doc);
                if (CmdMap[ind].args != ""){
                    stdout.printf ("Arguments: %s\n", CmdMap[ind].args);     
                }
                printed++;
                break;
            }
        }
        stdout.printf("\n");

        if (printed == 0) {
            stdout.
                printf
                ("No commands match with '%s'.  Possible commands are:\n\n",
                args[1]);

            for (ind = 0; ind < CmdMap.length; ind++) {
                stdout.printf("-%s\n", CmdMap[ind].name);
            }
            return -1;
        }
        return 0;
    }
}

