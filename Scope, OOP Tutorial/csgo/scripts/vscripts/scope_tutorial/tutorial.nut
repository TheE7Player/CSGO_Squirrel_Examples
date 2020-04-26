
// Youtube tutorial on Scopes & Fake Event Handler
// Date of creation: 26th April 2020

// Internal Global Table which will be our fake handler table for events to invoke

// [NOTE]: Most languages use the prefix "On" to tell the user this is a event.
events <- {
    OnFire = null
}

// Our dummy function to simulate a function call to the event
function OnKill()
{
    // Our internal local variable (accessable to the function only) to simulate a table responce
    // This demo will simulate a tag on an enemy, responding back with the targets name and damage taken

    // [NOTE] local variables cannot use the new-slot operator (<-), you must use assignment operator (=)

    local target =
    {
        name = "James",
        damage_taken = 3
    }

    // Now we can invoke the function call, calling itself with the table above as a responce to the event
    // [NOTE]: THIS IS NOT SAFE CALL, what if OnFire was unassigned or assigned not as a function?!
    // Look at IsFunctionAssigned function from base.nut to see how to approach this safely
    events.OnFire.acall([this, target]);
}

// Now we'll attack onto our fake event with the param "data" which holds the information
events.OnFire <- function(data)
{
    //data.name, data.damage_taken

    // [NOTE]: use printl if using csgo with squirrel, this example works in vanilla (pure) squirrel
    // You can still use this method in csgo, but printl is modern take of the function.

    print("Target: " + data.name + "\n")
    print("Amount: " + data.damage_taken + "hp")

    /*
        MODERN TAKE OF THIS FUNCTION (CSGO, PORTAL 2 ETC)

        printl("Target: " + data.name)
        printl("Amount: " + data.damage_taken + "hp")
    */
}


// Now we simualte the function caller, to test out our input for OnFire
OnKill()