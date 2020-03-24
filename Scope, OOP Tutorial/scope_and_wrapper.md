# CSGO Squirrel Tutorial

> This guide is accurate as from 24rd of March, 2020.
>
> Last Update: 24rd of March, 2020

*This guide is still undergoing development - please keep checking until fully completed*

## Understanding Scopes and Implementing Wrappers

This tutorial will go over `Squirrel's Scope`, `OOP` and how we can implement a `wrapper` with `Squirrel`.



This tutorial will be covered under usage of `CS:GO`. These terms may also apply to the language or any other games that support scripting which implements a `Squirrel VM`.  (We'll be targeting Valves defined functions)



## Scopes

Most languages you've heard the term of `Scopes`. In `Programming` a scope is a defined level of visibility within a ` script` or `program`. As `Squirrel` isn't a complex language in nature, we only care about 3 levels:

> These don't have predefined terms, so these are based on how I view them

- `External Global Scope`
- `Internal Global Scope`
- `Internal Local Scope`

### External Global Scope

The highest in the symbols visibility group is the `External Global Scope`. This scope isn't restricted to the given script and is accessible through out ` Squirrel's VM Lifespan`. You can define this scope by adding a prefix of two colons `::` in front of the variable or functions name.

```squirrel
// A External Global Scope in Squirrel
::level <- 5;
```

> You are required to imply the new slot operator when declaring any `Global Scope`, don't leave any `External Global Scope`'s empty as this may complicate issues during run-time.

```squirrel
// Standard Function Declaration with Prefix :: (The only way)
::print_name <- function(name)
{
    print(name)
}

// Cannot use "syntactic sugar" Function Declaration with Prefix ::!
::function print_name(name)
{
    print(name)
}
/*
	.code.tio line = (1) column = (10) : error expected 'IDENTIFIER'
	Error [expected 'IDENTIFIER']
*/
```

> The `syntactic sugar` way of creating a function won't work as `::function` isn't a valid identifier to the `Squirrel` Language - This is why you get the `IDENTIFIER	` error!

> Did you know: If you target an logic_script entity with hammer, you can use the scripts external global variables! But they ideally would need to be pre-defined global variable! (Cannot be left empty)

### Internal Global Scope

Same as `External Global Scope` but are only visible to the script itself. These variables are hidden from plain site but are accessible during the scripts lifespan. They operate the same way but are less strict and can be left none assign at runtime.

```squirrel
// Assigned as an integer, holds 3
lives <- 3;

// Assigned empty at start (null), assuming we'll assign at runtime!
lives_left <- null;
```



The rule with any global symbol is that you need to initialise the variable with the new slot operator `<-`. After being assigned, you can then operate it under the normal assignment operator `=`.

```squirrel
// Assigned empty at start (null), assuming we'll assign at runtime!
lives_left <- null;

// Fine as it was assigned initially, we can use '='
lives_left = 3;

// This will be an error as this variable doesn't exists at runtime!
score = 3;

/* 
   AN ERROR HAS OCCURED [the index 'score' does not exist]
*/
```

> If you get an `index 'x' does not exist` error, it means the variable that has been accessed isn't a part of `Squirrels Variable Table`. Ensure you don't accidently use the `=` operator for global variables!

### Internal Local Scope

The lowest level of visibility in `Squirrel`. These are used generally in functions due to its `Short-life Span ` during its life in the `Stack`.

> Locals are only accessible (are declarable) only in functions, you'll get an error if you use it above in the same level as global variables! You can still get away with declaring a global scope in a function but it's bad practice!

```squirrel
// Function which counts to amount of character of 'char' and returns back as an integer!
function CountFrequency(word, char)
{
    // Our local scope variable which role is to hold the amount
    local frequency = 0;

    // Since a string is an array of characters, we can use a foreach loop:
    foreach (c in word)
    {	
		if (c.tochar() == char) 
	    	frequency += 1;
    }

    // Return the amount back to the caller
    return frequency;
}

// Here we use a global due to being outwith the function
word <- "I really hope I can fly!";

// Subject: I really hope I can fly!
printl("Subject: " + word);

//Number of 'l': 3
printl("Number of 'l': " + CountFrequency(word, "l"));

//Number of 'I': 2
printl("Number of 'I': " + CountFrequency(word, "I"));

//Number of ' ': 5
printl("Number of ' ': " + CountFrequency(word, " "));
```

> Squirrel doesn't have the `printl` function - this is only available to CS:GO, TF2 etc.
>
> You can re-create it by implementing the following:
>
> ```squirrel
> // You may include brackets if you wish - this still works (As it requires only one line to execute)
> function printl(word)
>     print(word + "\n")
> ```



**In a nutshell**:

1. `External Global Scopes` can be accessed by any script during its lifespan - if the variable is pre-defined in the script, You may use it in `Hammer`.
2. `Internal Global Scopes` are scopes that can be accessed through out the **scripts lifespan**. Functions can even access these variables!
3. `Internal Local Scopes` are scopes that can be accessed and used with the declared function and dies when the *function or method returns*. Once the function is finished, all the local scope variables are destroyed and freed in memory (unless you return the result). 

## Wrapper

A `Wrapper` is a method which encapsulate the complexity or increase its Simplisticity. In these case, we'll create a `Wrapper` to make modifications with our entities inside our `Hammer` map - more simplistic.



In terms of `OOP`, we will use `Inheritance` to simplify things.

**Parent Class**: Will contain our main functionality logic which is accessible to every entity.

**Child Class**:  Will `Inherit` our `Parent ` class logic with extra functionality support to the specific function.

> Link to the available functions: https://developer.valvesoftware.com/wiki/List_of_Counter-Strike:_Global_Offensive_Script_Functions

**What logic are the same for different entities?** (Based on CS:GO)

The basics: `Entity (Handle)`, `Target name/GetName()`, `Validate/Get Scope`, `Destory()`, `GetOwner()` and `EntFireByHandle()`



**What about the other functions that are available in the wiki?**

The Wiki just states what functions are available to use within the game, but not the entities targeted or available commands - Our awesome `wrapper` will make this job easier for us!



### Code

This is what our script will look like for our `Parent Class` which holds the main logic that relates to every entities we target.

> This is the short version of ***scope_tutorial\base.nut***



*Before we show the script,*

our awesome script will allow you to hook onto different `events` which you can target `globally`.  You could implement the events `internally` but making it `external`means we assign the new function once and it will work for all the other `instances`!

> External/Internal G is the shorthand I'll call `External Global` and `Interal Global`

```squirrel
// This will be declared at the top due to its scope level (External G > Internal G)
::events <- {
    OnEntityFound = null,
    OnNameChanged = null
}
```

This `global external`  `table` called `::events` will hold keys of function names to be assigned by the user - *if they wish* - at run time. For now we declare the each`key` `values` to `null`. Lets now create a function which tests if any function is attached to the desired event.

```squirrel
// Example of this from: base.nut @ line 74
if (IsFunctionAssigned(::events, "OnEntityFound"))
    ::events.OnEntityFound.acall([this, {classname=entity_classname,target=" "}])
```

For you to fully understand what is going on, I'll need to explain what's happening with the functions `IsFunctionAssign` and `acall`.

#### IsFunctionAssign

> Function is located in base.nut @ line 40

```squirrel
function IsFunctionAssigned(table, event)
{
    if (event in table)
        if(typeof(table[event]) == "function")
        	return true;
    
    return false;
}
```

This simple function always use to `safely check` if the event we want to target is: 

**A) A valid event that's able to be hooked (Key lookup)**

```squirrel
// Where argument "event" is the event to lookup in table given by argument "table"
if (event in table)
```

**B) The event key that is assigned is a function (Value Compare)**

```squirrel
// Compare the value in key "event" if the value is a function
if(typeof(table[event]) == "function")
```

Which returns:

- `true` : ***if the event is exists*** and ***is assigned as a valid function***
- `false`:  ***if the event given doesn't exist*** or ***if the assigned event isn't a function***



#### acall

> A valid explained and documented response from: https://developer.electricimp.com/squirrel/function/acall

The issue we face is how our response system works - We return back: A response (OK, FAIL or EXCEPTION) with a table containing the information...

`acall` allows us the enhance our call-backs from the methods - for it to work we:

**A) Target the table with the event and call a** `delegate` **to initiate the** `acall` **call**

```Squirrel
// This example in base.nut @ 88 shows us invoking the event "OnEntityFound"
::events.OnEntityFound.acall(...)
```

**B) Supply the parameter of an array with the details to return back**

```Squirrel
// The array with the parameters to input back (this is the caller, ignore this...)
([this, {classname=entity_classname,target=" "}])
```

The second element holds a `table` with our data! This makes `wrapper` we made `adaptable` and `flexible`!

In line 88, we have a table that contains the classname and the targets name!

If we jump to **player.nut**, we have a function which handles the returns:

```squirrel
// Located in: player.nut @ line 29
::events.OnEntityFound <- function(data)
{
    // Short hand for data["classname"]
    local classname = data.classname;

    // Short hand for data["target"]
    local name = data.target;

    // The function as it stands doesn't require validation as the entity has been found!
    ScriptPrintMessageChatAll(format("SUCCESS: Found %s whos is a %s entity", name, classname));
}
```

So this function we've created is `dynamic`, the user can now decide how *they want the code to work*!

This makes the users work easier and more manageable,  you'll get credited for your work (my work in this case, lol)

We can see this logic working from the screenshot here:

<img src="https://raw.githubusercontent.com/TheE7Player/CSGO_Squirrel_Examples/master/Scope%2C%20OOP%20Tutorial/example_1.png" style="zoom:150%;" />

The first two lines on this image are from the code:

```squirrel
ScriptPrintMessageChatAll(format("SUCCESS: Found %s whos is a %s entity", name, classname));
```

Which is retrieved from the argument named `data`:

```squirrel
::events.OnEntityFound <- function(data)
```

You may see the rest of the code from the parent class here: https://github.com/TheE7Player/CSGO_Squirrel_Examples/blob/master/Scope%2C%20OOP%20Tutorial/csgo/scripts/vscripts/scope_tutorial/base.nut

