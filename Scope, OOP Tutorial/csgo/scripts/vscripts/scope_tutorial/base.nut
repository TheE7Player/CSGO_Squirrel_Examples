// base.nut - The Parent Class for our wrapper

// Events that trigger things! Comes handy! (Should be class dependent!)
::events <- {
    OnEntityFound = null,
    OnNameChanged = null
}

// Enum for checking case sensitivity
enum Case 
{ 
    Sensitive, Lower 
}


enum Responce
{
    OK, FAIL, EXCEPTION
}

class wrapper
{
    // Our internal print function
    function log(text)
        if (GetDeveloperLevel() > 0)
            printl(text)  

    function CreateResponce(responce_result, append_table)
    {
        local result = (responce_result == Responce.OK) ? "OK" : (responce_result == Responce.FAIL) ? "FAIL" : (responce_result == Responce.EXCEPTION) ? "EXCEPTION" : "RESULT ERROR";

        local responce_table = { responce = result }

        foreach (k,v in append_table)
            responce_table[k] <- v;

        return responce_table;
    }

    function IsFunctionAssigned(table, event)
    {
        if (event in table)
            if(typeof(table[event]) == "function")
                return true;
        
        return false;
    }

    // Classes don't use '<-' for class variables/properties
    disposed = false;

    // Our Internal global scope which holds the entity handle
    entity = null;

    // Our Internal global scope which holds the entity name (left empty if they don't care about the name!)
    entity_name = null;

    // Our constructor which handles how the object works when called for (created)
    constructor(entity_classname, find_by_name = null, sensitivity = Case.Sensitive) 
    {
        // 'entity_classname' requires to be filled in, needed in order to work
        // 'find_by_name' is optional as it contains a default parameter (= null)
        // 'sensitivity' is optional to control how to test the name, compares 'case sensitive' by default.

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

    // Our Neat function, Leave blank to get the name or Add a string to change the name!
    function Name(assigned_name = null)
    {
        // Use our safe-guard to prevent errors if entity is already disposed
        local guard = Gate();
        if(guard != null)
            if(guard["FAIL"] || guard["EXCEPTION"])
                if("error" in guard)
                    if(guard["error"] == "Cannot call function on disposed entity")
                        return guard;


        // If called like ".Name()" - We'll return their name (if any)
        if(assigned_name == null)
            return ( entity_name != null ) ? entity_name : "Empty";

        // If the function gets this far, it means assigned_name has something!
        if(typeof(assigned_name) != "string")
            return CreateResponce(Responce.FAIL, { param = assigned_name, required = "string", got = typeof(assigned_name) });

        // Check if strings match, update if not!
        local actual_name = entity.GetName()
        if(entity_name != actual_name)
            entity_name = actual_name

        // If it got this far, it means the parameter used is correct - a string!
        try
        {
            local old_name = entity_name;

            entity.__KeyValueFromString("targetname", assigned_name);
            entity_name = assigned_name;
            
            if (IsFunctionAssigned(::events, "OnNameChanged"))
                ::events.OnNameChanged.acall([this, CreateResponce(Responce.OK, { old = old_name, new = assigned_name })]);
        }
        catch(ex)
        {
            local fault = getstackinfos(0);
            
            if (IsFunctionAssigned(::events, "OnNameChanged"))
                ::events.OnNameChanged.acall([this, CreateResponce(Responce.EXCEPTION, { script = fault["func"], at_line = fault["line"], reason = ex })]);
        }

    }

    // Our safe guard, if disposed - Call off automatically
    function Gate()
    {
        if(disposed || entity == null )
            return CreateResponce(Responce.FAIL, { error = (disposed) ? "Cannot call function on disposed entity" : "Entity is not valid" });
        else
            return null;   
    }

    function Dispose()
    {
        if(disposed)
           return CreateResponce(Responce.FAIL, { error = "Cannot call entity has its already been disposed" });

        disposed = true;

        entity.Destroy();

        return CreateResponce(Responce.OK, { param = assigned_name, required = "string", got = typeof(assigned_name) });
    }

    function Scope()
    {
        // Use our safe-guard to prevent errors if entity is already disposed
        local guard = Gate();
        if(guard != null)
            if(guard["FAIL"] || guard["EXCEPTION"])
                if("error" in guard)
                    if(guard["error"] == "Cannot call function on disposed entity")
                        return guard;

        local is_valid = ValidateScriptScope();

        if(!is_valid)
            return CreateResponce(Responce.FAIL, { result = "NOT VALID SCOPE" } );
        else
            return CreateResponce(Responce.OK, { target = target_name, result = entity.GetScriptScope() } );
        
    }

    // Our wrapper for the function EntFireByHandle
    function Act(action, value, delay = 0, activator = null, caller = null)
    {
        // Use our safe-guard to prevent errors if entity is already disposed
        local guard = Gate();
        if(guard != null)
            if(guard["FAIL"] || guard["EXCEPTION"])
                if("error" in guard)
                    if(guard["error"] == "Cannot call function on disposed entity")
                        return guard;

        try
        {
            EntFireByHandle(entity, action, value, delay, activator, caller);
            return null;
        }
        catch(ex)
        {
            local fault = getstackinfos(1);

            return CreateResponce(Responce.EXCEPTION, { reason=ex,entity=entity,action=action,value=value,delay=delay,activator=activator,caller=caller});
        }       
    }

    function Owner(handle = null)
    {
        // NOT TYPE SAFE

        // Use our safe-guard to prevent errors if entity is already disposed
        local guard = Gate();
        if(guard != null)
            if(guard["FAIL"] || guard["EXCEPTION"])
                if("error" in guard)
                    if(guard["error"] == "Cannot call function on disposed entity")
                        return guard;

        if(handle == null)
        {
            local _parent = entity.GetOwner();
            return CreateResponce(Responce.OK, {is_child = (_parent == null) ? false : true}, _parent={ name=handle.GetName(), table=handle }, child={ name=entity.GetName(), table=entity })
        }
        else
        {
            entity.SetOwner(handle);
            return CreateResponce(Responce.OK, {_parent={ name=handle.GetName(), table=handle }, child={ name=entity.GetName(), table=entity }})
        }
            
    }
}