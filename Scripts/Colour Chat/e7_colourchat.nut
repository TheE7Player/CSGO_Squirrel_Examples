// e7_colourchat.nut
// Script which makes it easy to print colour messages to chat or screen!

// [NOTE] Need to call IncludeScript(<this script location>, null) to make this work!

/*
    Thread which holds and explains these colour codes: https://forums.alliedmods.net/showthread.php?t=290562

    Thank you DMax#7777 & Marshak#7777 for expanding the available colours
*/

local COLOUR = {
    INVIS = "\x00", NORMAL = "\x01", RED = "\x02", PURPLE = "\x03",
    GREEN = "\x04", LIGHTGREEN = "\x05", LIMEGREEN = "\x06", LIGHTRED = "\x07",
    GREY = "\x08", YELLOW = "\x09", LIGHTBLUE = "\x0a", BLUE = "\x0b", DARKBLUE = "\x0c",
    DARKGREY = "\x0d", PINK = "\x0e", ORANGERED = "\x0f", ORANGE = "\x10"
}

local BRACKET = { OPEN = 123, CLOSE = 125 }

local GenerateOutput = function (text) : ( COLOUR, BRACKET ) {
    local len = text.len()
    local i = 0

    local stringBuild = ""
    local stringOut = ""	

    while ( i < len )
    { 

        if(text[i] == BRACKET.OPEN)
        {

            // Apply space in front to allow colour change ( fix )
            if ( i == 0 )
                stringOut += " "

            i += 1
            while ( i < len )
            {
                if( text[i] == BRACKET.CLOSE )
                    break
                else
                    stringBuild += text[i].tochar()

                i += 1
            }
            i += 1
            
            if( stringBuild in COLOUR )
            {
                stringOut += COLOUR[stringBuild]
                stringBuild = ""
            }
            else
            {
                printl("Sorry don't know what colour: " + stringBuild + "is!\n")
                return "ERROR"
            }

        }

        stringOut += text[i].tochar()
        i += 1
    }

    return stringOut
}

// Creating the table as an fake namespace
E7Colour <- {}

function E7Colour::ChatAll(text) : ( GenerateOutput )
{
    local text = GenerateOutput(text)

    if(text == "ERROR")
        return

    ScriptPrintMessageChatAll( text )
}

function E7Colour::ChatCT(text) : ( GenerateOutput )
{
    local text = GenerateOutput(text)

    if(text == "ERROR")
        return

    ScriptPrintMessageChatTeam( 3, text )
}

function E7Colour::ChatT(text) : ( GenerateOutput )
{
    local text = GenerateOutput(text)

    if(text == "ERROR")
        return

    ScriptPrintMessageChatTeam( 2, text )
}

function E7Colour::Alert(text) { ScriptPrintMessageCenterAll( text ) }