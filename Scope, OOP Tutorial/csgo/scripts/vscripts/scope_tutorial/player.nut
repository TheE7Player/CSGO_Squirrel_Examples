if(!DoIncludeScript("scope_tutorial/base.nut", null))
{
    printl("[ERROR] Dependency "base_class" is missing - It holds the main logic!");
}
else
{
    if(GetDeveloperLevel() > 0) 
       printl("[ENTITY-WRAPPER] player.nut has been called!"); 
}


Type <- { CT = "info_player_counterterrorist", T = "info_player_terrorist" }

Me <- null;
Enemy <- null;

function load()
{
    // Pre-assign our variables before hand
    
    // Find the CT classname in the map, and look for any that has the targetname of "ct"
    Me = wrapper(Type.CT, "ct")
    
    // Find the T classname in the map, return first instance - Okay if only one in map!
    Enemy = wrapper(Type.T)
}

// EntityFound returns back a table with classname and the entities targetname!
::events.OnEntityFound <- function(data)
{
    // Short hand for data["classname"]
    local classname = data.classname;
    
    // Short hand for data["target"]
    local name = data.target;

    // The function as it stands doesn't require validation as the entity has been found!
    ScriptPrintMessageChatAll(format("SUCCESS: Found %s whos is a %s entity", name, classname));
}

::events.OnEntityFound <- function(data)
{
    // Short hand for data["classname"]
    local classname = data.classname;
    
    // Short hand for data["target"]
    local name = data.target;

    // The function as it stands doesn't require validation as the entity has been found!
    ScriptPrintMessageChatAll(format("SUCCESS: Found \"%s\" whos is a \"%s\" entity", name, classname));
}

::events.OnNameChanged <- function(data)
{
    local result = data.responce;

    if (result == "OK")
    {
        local old = data.old;
        local new = data.new;
        ScriptPrintMessageChatAll(format("\"%s\" has now been renamed \"%s\"!", old, new))
    }
    else
    {
        // Holds the script responceable to this error
        local error_script = data.script;

        // Holds the line which raises the rror
        local at_line = data.at_line;

        // Holds the exception error
        local message = data.reason;

        // Print out the error
        ScriptPrintMessageChatAll(format("[%s] at line %d: %s",error_script,at_line,message));
    }

}

function TestChange()
{
    Me.Name("James");
    Enemy.Name("Bob");
}

function TestGetName()
{
    ScriptPrintMessageChatAll(Me.Name());
    ScriptPrintMessageChatAll(Enemy.Name());
}

function TestNewNameFind()
{
    // Find the CT classname in the map, and look for any that has the targetname of "ct"
    Me = wrapper(Type.CT, "James")
    
    // Find the T classname in the map, return first instance - Okay if only one in map!
    Enemy = wrapper(Type.T, "Bob")
}
