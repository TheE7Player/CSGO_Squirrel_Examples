// game_text_func.nut for entities_iteration.vmf CSGO 2022
// Holds logic to angle the text towards the players at all times (at a set refire interval from logic_timer)

// Check we have vs_math.nut attached prior to calling the method
if(!DoIncludeScript("e7/entities-iteration/vs_math.nut", null))
{
   printl("[!] MISSING DEPENDENT VSCRIPT FROM 'samisalreadytaken/vs_library' (vs_math.nut) FROM: https://github.com/samisalreadytaken/vs_library");
}

// 'self' is reversed for the called reference (The entity which is processing the actions etc)
function TextMove()
{
	// Let's first store a variable which holds a slot named 'Target', which is the bot instance (entity) index.	
	local tIDX = self.GetScriptScope().Target;
	
	// We then access the global bot table, then get the text entity (point_worldtext)
	local textRef = ::BOT_ID_LUT[tIDX].ref.GetScriptScope().FT;
	
	// We then utilise samisalreadytaken's vs_math script to angle the text to the current players position.
	local finalVec = VS.GetAngle(::currentPlayer.GetOrigin(), textRef.GetOrigin());
	
	// Finally, we then set the angle to the text, ignoring the roll change.
	textRef.SetAngles(finalVec.x, finalVec.y, 0);
	
	// Recentre the text above the players head, if any change in location is detected
	::BOT_ID_LUT[tIDX].ref.GetScriptScope().CentreTextOrigin();
}