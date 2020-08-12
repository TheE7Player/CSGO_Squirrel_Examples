// Variable Arguments Script in Squirrel 2.2
// Tested with Raw Squirrel - Video tutorial: https://youtu.be/GnNkZliWOQk

/*

	Key notes:
	
	vargc - Holds the length for the pseudo-array (variable argument)
	vargv[i] - Access the individual index where i is the index to look at/for
	
	Variable Arguments in Squirrel are denoted as 3 dots (...), which should be at the last in the argument/parameters
	
	VALID: function DoSmth(name, age, ...)
	INVALID: function DoSmth(..., name, age)
	
	Squirrel cannot tell at runtime how long (in theory) the vararg could be, this is why it is declared at the end
	
	~ TheE7Player
	
*/


function Add(...)
{
    local total = 0;
    for(local i = 0; i< vargc; i++) { total += vargv[i]; }
    ::print("Add sums up to: " + total + "\n")
}

function Sub(...)
{
    local total = 0;
    for(local i = 0; i< vargc; i++) { total -= vargv[i]; }
    ::print("Sub sums up to: " + total + "\n")
}

function printl(...)
{
    local string = "";

    for(local i = 0; i < vargc; i++) { string += vargv[i]; }
    string += "\n";

    ::print(string)
}

Add(1,2,3,4,5,6,7,8,9,10)
Sub(1,2,3,4,5,6,7,8,9,10)

printl("Hello: ", "James", "! ( 5 + 3 ) * 20 would be: ", (5+3)*20, "!")

/*

	OUTPUT:
	Add sums up to: 50
	Sub sums up to: -50
	Hello: James! ( 5 + 3 ) * 20 would be: 160!
	
*/