if(!DoIncludeScript("scope_tutorial/base.nut", null))
{
    printl("[ERROR] Dependency \"base_class\" is missing - It holds the main logic!");
}
else
{
    if(GetDeveloperLevel() > 0) 
       printl("[ENTITY-WRAPPER] player.nut has been called!"); 
}

class Player extends wrapper
{
    // We can use the variables, instances and functions from the class "wrapper" itself!

    // We do need to carry over our constructor though
    constructor(entity_classname, find_by_name = null, sensitivity = Case.Sensitive) 
    {
        // 'entity_classname' requires to be filled in, needed in order to work
        // 'find_by_name' is optional as it contains a default parameter (= null)
        // 'sensitivity' is optional to control how to test the name, compares 'case sensitive' by default.

        EventInit();

        local target = null;
        while( ( target = Entities.FindByClassname(target, entity_classname ) ) != null )
        {	
            if(target.IsValid())
            {
                // Now we validate if 'find_by_name' is assigned, if not assign and jump out (break)
                if(find_by_name == null)
                { 
                    entity = target;
                    if (IsFunctionAssigned(::events, "OnEntityFound"))
                        ::events.OnEntityFound.acall([this, {classname=entity_classname,target=" "}])
                    break;
                }
                
                // Now validate if the object found is what we need
                switch(sensitivity)
                {
                    case Case.Lower:
                        if(target.GetName().tolower() == find_by_name)
                        {   
                            entity_name = target.GetName();
                            entity = target;
                            if (IsFunctionAssigned(::events, "OnEntityFound"))
                                ::events.OnEntityFound.acall([this, {classname=entity_classname,target=entity_name}])                    
                            break;
                        }
                        break;

                    case Case.Sensitive:
                        printl(target.GetName() + " >> " + find_by_name)
                        if(target.GetName() == find_by_name)
                        {   
                            entity_name = target.GetName();
                            entity = target;
                            if (IsFunctionAssigned(::events, "OnEntityFound"))
                                ::events.OnEntityFound.acall([this, {classname=entity_classname,target=entity_name}]) 
                            break;
                        }
                        break;

                    default:
                        throw "Not valid case sensitivty used - Use: Sensitive or Lower";                     
                        break;
                }
            }
        }

        if(entity == null)
        if(find_by_name == null)
            log("[ERROR] : [ " + entity_classname +  " ] >> Cannot find the required entity >> NULL");
        else
            log("[ERROR] : [ " + entity_classname + " : " + find_by_name + " ] >> Cannot find the required entity >> NULL");
        
        return null;
    }
    
    // Add extensions onto the event table
    function EventInit()
    {
        // We cannot do . now as we're outwith the implemention of the table
        // We need to assign it as a key [string] as well as the new slot operator (<-) as it doesn't exist
        
        // Check if event isn't already apart of the list, that means we won't overwrite it if it does!
        if(!("OnHealthCall" in ::events))
            ::events.OnHealthCall <- null;       
    }

    function Safe()
    {
        // Use our safe-guard to prevent errors if entity is already disposed
        local guard = Gate();
        if(guard != null)
            if(guard["FAIL"] || guard["EXCEPTION"])
                if("error" in guard)
                    if(guard["error"] == "Cannot call function on disposed entity")
                        return guard;

        return true;
    }

    function Health (amount = 0)
    {
        
        // As Safe could return back an error, setting as a variable will benefit performance!
        local result = Safe();

        // If the return isn't a boolean, then we've hit an error
        if(typeof(result) != "bool")
            return result;

        if (amount == 0)
        {
            local health = entity.GetHealth();

            if (IsFunctionAssigned(::events, "OnHealthCall"))
                ::events["OnHealthCall"].acall([this, CreateResponce(Responce.OK, { target = entity_name, health = health })]);

            return health;
        }
        else
        {
            // Cache the parameter type for performance
            local param_type = typeof(amount);
            
            local isRange = null;
            try
            {
                isRange = (amount < 0) ? false : true;
            }
            catch(_)
            {
                if (IsFunctionAssigned(::events, "OnHealthCall"))
                    ::events["OnHealthCall"].acall([this, CreateResponce(Responce.FAIL, { param = amount, param_t = param_type, reason = "Given param isn't a valid number above 0" })]); 
                return;
            }
            
            local isInteger = (param_type != "integer") ? false : true;

            // If its not in range or the param isn't an integer...
            if(!isRange || !isInteger)
            {
                if (!isRange && param_type != "string")
                {
                    if (IsFunctionAssigned(::events, "OnHealthCall"))
                        ::events["OnHealthCall"].acall([this, CreateResponce(Responce.FAIL, { param = amount.tostring(), param_t = param_type, reason = "Health cannot be assigned less than 0" })]);
                    
                    return;
                }

                if (!isInteger)
                {
                    if (IsFunctionAssigned(::events, "OnHealthCall"))
                        ::events["OnHealthCall"].acall([this, CreateResponce(Responce.FAIL, { param = amount.tostring(), param_t = param_type, reason = "Given param isn't a valid number above 0" })]);
                    
                    return;
                }
            }

            // This means we want to set our health
            local old = entity.GetHealth();
            entity.SetHealth(amount);

            if (IsFunctionAssigned(::events, "OnHealthCall"))
                ::events["OnHealthCall"].acall([this, CreateResponce(Responce.OK, { target = entity_name, old = old, new = amount})]);
        }

    }

}


Type <- { CT = "info_player_counterterrorist", T = "info_player_terrorist" }

Me <- null;
Enemy <- null;

function load()
{
    // Pre-assign our variables before hand
    
    // Find the CT classname in the map, and look for any that has the targetname of "ct"
    Me = Player(Type.CT, "ct")
    
    // Find the T classname in the map, return first instance - Okay if only one in map!
    Enemy = Player(Type.T, "t") 
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

::ContainsAttribute <- function (table, str_arr) {
    foreach(key in str_arr)
        if (!(key in table))
            return false;

    return true;
}

// Player Class Hooks
::events.OnHealthCall <- function(data)
{
    // Getter
    // target, health
    if(ContainsAttribute(data, ["target", "health"]))
    {
        ScriptPrintMessageChatAll(format("\"%s\"'s health is: %d!", data.target, data.health))
        return;
    }

    // Setter
    // entity, old, new
    if(ContainsAttribute(data, ["target","old","new"]))
    {
        ScriptPrintMessageChatAll(format("\"%s\"'s health was: %d, but is now: %d!", data.target, data.old, data.new))
        return;
    }

    // Error
    // param, param_t, reason
    if(ContainsAttribute(data, ["param","param_t","reason"]))
    {
        ScriptPrintMessageChatAll(format("[ERROR] : { %s, %s } - %s", data.param, data.param_t, data.reason))
        return;
    }
}

function TestChange()
{
    Me.Name("James");
    Enemy.Name("Bob");
}

function TestPlayerClass()
{
    // Test getters (Callback is called from function "::event["OnHealthCall"]")
    Me.Health();
    Enemy.Health();

    // Test setters (Callback is called from function "::event["OnHealthCall"]")
    Me.Health(500);
    Enemy.Health(200);

    // Test faults (Callback is called from function "::event["OnHealthCall"]")
    Me.Health(3.142); // <- This should throw an error
    Enemy.Health("Haha, no."); // <- Should throw error as its a string, not an integer
}

function TestGetName()
{
    ScriptPrintMessageChatAll(Me.Name());
    ScriptPrintMessageChatAll(Enemy.Name());
}

function TestNewNameFind()
{
    // Find the CT classname in the map, and look for any that has the targetname of "ct"
    Me = Player(Type.CT, "James")
    
    // Find the T classname in the map, return first instance - Okay if only one in map!
    Enemy = Player(Type.T, "Bob")
}
