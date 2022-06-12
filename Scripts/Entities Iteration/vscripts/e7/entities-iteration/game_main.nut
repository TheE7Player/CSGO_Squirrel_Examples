// game_main.nut for entities_iteration.vmf CSGO 2022
// This script just basically allows default server/client commands to be used/called

// Ensure we have the following scripts within scope of the vscript folder
if(!DoIncludeScript("e7/e7_colourchat.nut", null))
{
   printl("[!] Colour Script Missing Or Failed: https://github.com/TheE7Player/CSGO_Squirrel_Examples/tree/master/Scripts/Colour%20Chat");
}

if(!DoIncludeScript("e7/entities-iteration/game_text_func.nut", null))
{
   printl("[!] Code missing for text rotations");
}

// Contains a global table where all bot instances in the map will be marked
::BOT_ID_LUT <- {}

// A global slot/variable where the current player/client weakref is stored (Assigned once)
::currentPlayer <- null;

// Bot Text Offsets (For aligning the text more near to the head)
local botZOffset = 40;
local botXOffset = 3;

// InitLoad(): Main entry point, setups up commands and initial logic to run the map
function InitLoad()
{
	// Call all the initial commands required
	E7Colour.ChatAll("[{LIGHTGREEN}INIT{NORMAL}] Running necessary commands... ");
   
	// Call the following methods as a client (not server commands)
	__cmd(false,
		"sv_cheats 1",
		"bot_dont_shoot 1",
		"bot_zombie 1",
		"bot_freeze 1",
		"bot_stop 1",
		"mp_humanteam ct",
		"sv_infinite_ammo 1",
		"mp_ignore_round_win_conditions 1",
		"mp_respawn_on_death_t 1",
		"sv_ignoregrenaderadio 1",
		"bot_ignore_players 1",
		"mp_freezetime 0"
   	);

   // Initiate the bot logic and start binding to entity scopes
   InitBotScopes();
   
   E7Colour.ChatAll("[{LIGHTGREEN}INIT{NORMAL}] COMPLETED ");
}

// Method to call commands as client or server, where the list of commands are numbers of parameters
function __cmd(isServer, ... )
{
	for(local i = 0; i< vargc; i++)
	{
		if(isServer)
			SendToConsoleServer(vargv[i]);
		else
			SendToConsole(vargv[i]);
	}
}

/*
	InitBotScopes(): Logic where it attaches the dynamic text and timers

	Function utilises free variables from top-level scope of the script (local variables) as READ-ONLY.
*/
function InitBotScopes() : ( botXOffset, botZOffset )
{
	local bot = null;			// Local variable which holds the current bot instance that is being iterated over
	local bot_name = null;		// Local variable which holds the bots name (Cached after assignment, reused)
	local num = 1;				// Local variable which holds the current iteration number (Used for naming the bots incrementally)
	local bScope = null;	    // Local variable which will hold the current iterated bots entity scope instance
	local lPlayer = null;		// Local variable which is to hold the current reference player (local-Player)
	
	// First loop is to find the current player and assign its weak reference to the global slot variable 'currentPlayer'
	while(( lPlayer = Entities.FindByClassname( lPlayer, "player" ) ) != null)
	{
		// Found player, stores its weak reference instance
		::currentPlayer = lPlayer.weakref();
		
		// Break the iteration loop, found our player
		break;
	}
	
	E7Colour.ChatAll("[{LIGHTGREEN}INIT{NORMAL}] ATTACHING BOT SCOPES... ");
	
	// Now we iterate over all bot player entities:
	while( ( bot = Entities.FindByClassname( bot, "cs_bot" ) ) != null )
	{
		
		// Ensure the bot we're iterating over's scope is validate, then we grab its newly create scope.
		bot.ValidateScriptScope();
		bScope = bot.GetScriptScope();
	   
	   	// Cache the bots name, as we'll need it a few times further down
		bot_name = format("bot_%i", num);
		
		// Now we dynamic create our text object (point_worldtext) over the players head
		bScope.FT <- Entities.CreateByClassname( "point_worldtext" )
		
		// Create the text objects scope and extra details (keyvalues)
		bScope.FT.ValidateScriptScope();	
		bScope.FT.__KeyValueFromString("message", bot_name);
		bScope.FT.__KeyValueFromFloat("textsize", 10);
		bScope.FT.__KeyValueFromString("color", "0 255 0");
		bScope.FT.__KeyValueFromString("angles", "-0 180 0");

		// We'll create a new slot within that text entities scope which holds the bots last location (Origin)
		// [NOTE]: As the key ("last_origin") may spaced out with an underscore, we'll use the bracket notation 
		// to assign the slot instead. You could use camelCase name styling instead to avoid this:
		// 		bScope["last_origin"] would become:	bScope.lastOrigin

		bScope["last_origin"] <- null;

		// Create an anonymous function which brings the bot and local variables scope into the function scope (Uses Free Variables)
		bScope.CentreTextOrigin <- function() : (bot, botXOffset, botZOffset)
		{
			local scope = bot.GetScriptScope(); // Variable which holds the current bots scope
			local bot_cen = bot.GetCenter();  // Variable which holds the bots centre point (Different from Origin, Centre of point)
					
			local change = true; // Set change to true initially, as scope["last_origin"] is likely null in first pass

			if(scope["last_origin"] != null)
			{
				// Validate further - Validate the lengths using LengthSqr (Less computing expensive function than .Length())
				local currentLen = bot_cen.LengthSqr();
				local lastLen = scope["last_origin"].LengthSqr();

				// Reassign 'change' if the two lengths are not the same (Likely the bot moved from last call)
				change = currentLen != lastLen;
			}

			// If a change is detected, we process the change for the next upcoming call
			if(change)
			{
				/*
					[NOTE]: ::BOT_ID_LUT global table contains a slot called 'text_offset', which helps align the text
					close to the centre of the bot as possible, seems that the offset is defined as:

							* We care only about for y-axis for this part, this is how far left or right the text is.
												Text Centre = bot_name_length * 3.25

					* 3.25 is the rough estimation of units per font size (Font size is set to work for 10 only?) [NOT TESTED]
				*/

				// Re-Align the text to the centre of the bots head
				scope.FT.__KeyValueFromString("origin", format("%f %f %f", 
				bot_cen.x + botXOffset, bot_cen.y - ::BOT_ID_LUT[bot.entindex()].text_offset, bot_cen.z + botZOffset));
				
				// Assign the new bots location as its old location (last_origin)
				scope["last_origin"] <- bot_cen;
			}
		}
		
		// Now we store the bot details to the global BOT_ID_LUT table
		/*
			[NOTE]: LUT suffix means: Look-Up-table

			We cache the 'text_offset' as we don't expect the bots name to change once initialised, this allows the script to
			cut down cost heavy operations (Multiplication can be heavy depending on its usage)

			name: Bots assigned name (incrementally named with prefix "bot_")
			ref: Weak reference to this bot instance (Allows us to only iterate over bots once until next round start)
			uhn: Unique-Health-Number, used to help identify what bot took damage - the health is reset after initialised
			text_offset: The y-axis offset to allow text to be always centre anchored to the bots head
		*/
		::BOT_ID_LUT[bot.entindex()] <- { 
			name = bot_name,
			ref = bot.weakref(),
			uhn = RandomInt(200, 2000),
			text_offset = bot_name.len() * 3.25
		}
		
		// Set the text centre anchor right away (To show initially before first call)
		bScope.CentreTextOrigin();
			
		// Now we increment the bot counter by one, and assign the current iterated bot to that unique health value
		num += 1;
		bot.SetHealth(::BOT_ID_LUT[bot.entindex()].uhn);
			
		// Now, we create the logic_timer, which will allow the text to centre and angle towards a player every few seconds
		bScope.timer <- Entities.CreateByClassname( "logic_timer" );
		bScope.timer.__KeyValueFromFloat( "RefireTime", 0.5 );
		
		bScope.timer.ValidateScriptScope();
		bScope.timer.GetScriptScope().Target <- bot.entindex();
		bScope.timer.GetScriptScope().OnTimer <- TextMove;
		bScope.timer.ConnectOutput( "OnTimer", "OnTimer" );
		
		// Finally, Enable the timer!
		EntFireByHandle( bScope.timer, "Enable", "", 1, null, null )
	}
}