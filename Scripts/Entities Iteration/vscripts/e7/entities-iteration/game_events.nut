// game_events.nut for entities_iteration.vmf CSGO 2022
// Holds all the global event tables that get called when an event gets invoked.

if(!DoIncludeScript("e7/e7_colourchat.nut", null))
{
   printl("[!] Colour Script Missing Or Failed: https://github.com/TheE7Player/CSGO_Squirrel_Examples/tree/master/Scripts/Colour%20Chat");
}

if(!DoIncludeScript("e7/entities-iteration/vs_math.nut", null))
{
   printl("[!] MISSING DEPENDENT VSCRIPT FROM 'samisalreadytaken/vs_library' (vs_math.nut) FROM: https://github.com/samisalreadytaken/vs_library");
}

// These local-scope variables holds the RGB colours we need
local GREEN_RGB = "0 255 0";
local YELLOW_RGB = "255 255 0";
local RED_RGB = "255 0 0";

/* This table variable holds:
	Key: userid
	Value: Key value to access this bots details (Look for '::BOT_ID_LUT' in 'game_main.nut')
*/
UIDBOT <- {}

/*
	This table just holds an singular key-value relation of:
	Key: The person who shot the weapon (userid)
	Value: Vector of where the bullet landed (Likely server-sided bullet location?)
*/
UIDBulletBuffer <- {}

/*
	Function which correlates colour based on value: Input 'x' where:
		x > 50 (or set) : GREEN
		x >= 50 (or set) AND x > 20 (or set) : YELLOW
		ELSE : RED

	Function makes usage of:
	- Default Parameter Values: If not set by the user, red threshold will always be 20, and yellow will always be 50.
	  - This means the user can easily modify the threshold depending on its use case.

	- Free variables
	  - A technique in Squirrel where you can bring in out-of-scope variables into the scope of the function with READ-ONLY access.
	  - This allows use to reuse already available scope within the script boundaries.
*/
function GetRGBByValue(input, red_threshold = 20, yellow_threshold = 50) : (GREEN_RGB, YELLOW_RGB, RED_RGB)
{
	if(input > yellow_threshold) return GREEN_RGB;
	
	return input <= yellow_threshold && input > red_threshold ? YELLOW_RGB : RED_RGB;
}

/*
	Hooked onto Event: player_hurt
	Event details: https://wiki.alliedmods.net/Counter-Strike:_Global_Offensive_Events#player_hurt

	This functions handles table creation of association with bots userid.
	This also handles the colour font above the bots, as well as handle the floating bullet damage text.

	[NOTE]: Depends on 'bullet_impact'/'::Event_OnBulletHit' to get the bullet vector.

	Event call order when a player (or client) shoots:
	- weapon_fire: Event which holds the client/person who shot a weapon (Not required or fetched in this use case)
	- bullet_impact: Event which holds the bullet location (REQUIRED) and its invoker (as an userid)
	- player_hurt: Event (in detail) which states information of who got hurt, who did it, how much they did etc.
*/
::Event_OnHit <- function(data)
{
	// Ensure global table is not empty prior to call/action

	// Check if the global table is set (not empty := len > 0) and if the userid is not present in the table (UIDBOT)
	if(::BOT_ID_LUT.len() > 0 && !(data.userid in UIDBOT))
	{
		/*  [NOTE]:
			When bots first spawn (Look at 'InitBotScopes' function in game_main.nut), an random number is set
			to uniquely identify the bot. This depends on ::BOT_ID_LUT[<idx>].uhn (uhn = Unique Health Number/Identifier).

			This extra logic is required as the event only returns back user id's. We cannot perform any differences on
			entity references as these are numbers. This is the downside to the event approach.

			Extra Note: This logic only gets executed when health sum/count > 100 (The random numbers are likely beyond 100hp)
		*/

		// Variable which holds the desired uhn to search for (Lets us know which bot took damage!)
		// Build up the difference to get the desired uhn number
		local match_health = data.health + data.dmg_health;
		
		// Loop through each bot instance (To stores the bots userid num)
		foreach( k, v in ::BOT_ID_LUT)
		{
			// Is this current bot we are iterating, matches to the unique bot hp we're looking for? Skip this bot if so.
			if(v.uhn != match_health) continue;
		
			// Now we store the correlation of the userid to the bot index (If it hasn't been added already!)
			if(!(data.userid in UIDBOT))
			{
				// userid to table index was not found - lets add the association!
				UIDBOT[data.userid] <- k;
			}
			
			//printl(format("SET BOT WITH TNAME: %s WITH UID OF: %i", v.name, data.userid));
			
			// Since we now found our bot association, we'll reset the value based on the normal hp limit (100hp)
			v.ref.SetHealth(100 - data.dmg_health)
			
			// Stop iteration loop, it's likely we found it here.
			break;
		}	
	}
	
	// Store these variables for quick shorthand approach (More readability-friendly approach)
	local id = UIDBOT[data.userid];
	local health = ::BOT_ID_LUT[id].ref.GetHealth();
	
	// Check if the attacker is in the BulletBuffer table
	if(data.attacker in UIDBulletBuffer)
	{
		// Likely does exist, lets process this information now
		
		// Variable which will hold the text entity (point_worldtext) 
		local hitText = null;
		
		// We'll now store the attackers bullet vector from the buffer (table)
		local bulletVec = UIDBulletBuffer[data.attacker];
		
		// We have an offset, as sometimes the angle can make the text clip into the wall (Push forward 15.00 on x-axis)
		local bulletForwardOffset = 15;
		local objectLifeSpan = 0.5; // 0.5s ~ 50ms

		// Using vs_math.nut to angle the text towards the user
		local angleVec = VS.GetAngle(::currentPlayer.GetOrigin(), bulletVec);
		
		// Now we dynamically create the point_wordtext entity, and store the reference to 'hitText' variable
		hitText = Entities.CreateByClassname( "point_worldtext" );

		// We set the text property (message) to the damage taken (We convert the integer to a string, as '__KeyValueFromString' only allows strings as input)
		hitText.__KeyValueFromString("message", data.dmg_health.tostring());

		// We set the text size to default value (Hammer set its to 10 normally)
		hitText.__KeyValueFromFloat("textsize", 10);

		// Now we set the colour based on the damage value range given
		hitText.__KeyValueFromString("color", GetRGBByValue(data.dmg_health));
		
		// We now angle the text to where the player is facing (Close to forward viewing angle of the user)
		hitText.__KeyValueFromString("angles", format("%f %f %f", angleVec.x, angleVec.y, angleVec.z));
		
		// Now we move the text origin (location) close to the bullet's vector location
		hitText.__KeyValueFromString("origin", format("%f %f %f", 
			bulletVec.x + bulletForwardOffset, bulletVec.y, bulletVec.z
		));
		
		// Now we create an dynamic timer (logic_timer) which will move the text upwards on hit (call)
		local timer = Entities.CreateByClassname( "logic_timer" );
		
		/* 
			IMPORTANT: We set the interval rate (of calling) to 50 ms (Milliseconds, quick firing)

			We have it set to 0.05s to make the text raise more smoothly, we can somewhat get away with this
			frequency as the timer destroys itself after .5 seconds. Any lower may have performance impact for
			low-end systems.
		*/
		timer.__KeyValueFromFloat( "RefireTime", 0.05 );
		
		// Ensure the entity scope is created for this object (To allow us to attach extra slots to the entity itself)
		timer.ValidateScriptScope();
		
		/*
			Now we attach our anonymous function with free variable argument 'hitText'

			[NOTE]:
			- We create a slot named 'OnTimer', which is then attached with an anonymous function.
			  - Anonymous Function: A function where it doesn't attach or belong to a named instance
			- We can use free variables to avoid attaching a weak reference to the object - which may be a faster approach.
			  - Weak Reference: A pointer which holds reference to an existing variable. This object can manipulate the reference,
			  	but cannot unassign/delete the object unless the object itself is destroyed.
			- That means we can call the object directly as READ-ONLY, which works in our case as we only want the objects location (origin)
		*/
		timer.GetScriptScope().OnTimer <- function() : ( hitText )
		{
			// Store the current texts location (Origin) from the referenced free variable 'hitText'
			local curpos = hitText.GetOrigin();
			
			// Lets increase the z-axis by 0.25 units, which allows a smooth raise in text height
			curpos.z += 0.25;
			
			// We now tell the object to set the location to the newly created location
			hitText.SetOrigin(curpos);
		};
		
		// We then have to hook the function we created to logic_timer's output: OnTimer
		timer.ConnectOutput( "OnTimer", "OnTimer" );
	   
	    // We then till the engine to enable the timer, which starts the timer calling the functions approx 2 times a second
		EntFireByHandle( timer, "Enable", "", 0, null, null );
		
		// Now tell the engine to activate the 'Kill' output, after a delay set by variable 'objectLifeSpan'
		// This would then destroy the timer entity, as well as the text entity from the map.

		// Kill the text after x second(s) of existing
		EntFireByHandle( timer, "Kill", "", objectLifeSpan, null, null );
		EntFireByHandle( hitText, "Kill", "", objectLifeSpan, null, null );

		// Finally, we can remove the bullet vector instance for the next bullet to register
		// Remove the slot, prepare for next hit!
		delete UIDBulletBuffer[data.attacker];
	}
	
	// Now we access the bot health text, and assign the text colour accordantly.
	::BOT_ID_LUT[id].ref.GetScriptScope()
					.FT.__KeyValueFromString("color", GetRGBByValue(health));
	
	// If the bot has died, we turn of the text angle timer until they respawn (Prevents unwanted calculations, as the bot is dead).
	if(data.health < 1) EntFireByHandle( ::BOT_ID_LUT[id].ref.GetScriptScope().timer, "Disable", "", 0, null, null )
	
}.bindenv(this);

/*
	Hooked onto Event: player_spawned
	Event details: https://wiki.alliedmods.net/Counter-Strike:_Global_Offensive_Events#player_spawned

	This event gets called when ever a person dies. It only holds the clients/players userid, and if its a restart (pending restart).

	This function basically checks if the bot exists in the table, to reset the text colour and restart the text angle timer.
*/
::Event_OnRespawn <- function(data)
{	
	// Does the current client userid exists in the bot table?
	if(data.userid in UIDBOT)
	{
		// It does, lets store the bot entity index into a variable called 'id' (Shorthand call)
		local id = UIDBOT[data.userid]
	
		// Now we access the bots attached text (scope) and set colour back to GREEN.
		::BOT_ID_LUT[id].ref.GetScriptScope()
						.FT.__KeyValueFromString("color", GetRGBByValue(100));
		
		// We then tell the engine to enable the timer again, to allow the text to angle towards the players current position.
		EntFireByHandle(::BOT_ID_LUT[id].ref.GetScriptScope().timer, "Enable", "", 0, null, null )
	}	
}.bindenv(this);

/*
	Hooked onto Event: bullet_impact
	Event details: https://wiki.alliedmods.net/Counter-Strike:_Global_Offensive_Events#bullet_impact

	This function just registers a bullet vector (value) to the user who shot the weapon (key)
*/
::Event_OnBulletHit <- function(data) {	UIDBulletBuffer[data.userid] <- Vector(data.x, data.y, data.z);	}.bindenv(this);