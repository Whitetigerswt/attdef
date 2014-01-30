/*
	Coded by: 
		[KHK]Khalid
	
	Description: 
		This script gives you 2 commands: 
		/togspec to enable/disable someone to/from spectating you
		/togspecall to enable/disable everyone to/from spectating you.
	
	How to install:
		1. Move the file in to your "<server directory>\pawno\include" folder
		2. Open up your main mode and add this line AFTER all the #defines and #includes*, otherwise you will get errors
			Add this: #include <spectoggler>
		3. Compile your mode and you're done.
*/


#include <a_samp>

#define _WHITE          "{FFFFFF}"
#define _YELLOW         "{FFFF00}"
#define _RED            "{FF0000}"
#define _GREEN			"{33CC00}"
#define _ORANGE			"{FF6600}"

new 
	bool:TOGSPEC_AbleToSpec[MAX_PLAYERS][MAX_PLAYERS], 
	TOGSPEC_SpecingID[MAX_PLAYERS];

stock _ALT_PlayerSpectatePlayer(playerid, targetplayerid, mode = SPECTATE_MODE_NORMAL)
{
	if(!TOGSPEC_AbleToSpec[targetplayerid][playerid])
	{
	    SendClientMessage(playerid, -1, ""_RED"ERROR: "_WHITE"This player has disabled you from spectating him/her!");
		new TOGSPEC_name[MAX_PLAYER_NAME];
		GetPlayerName(playerid, TOGSPEC_name, sizeof TOGSPEC_name);
		new TOGSPEC_str[128];
		format(TOGSPEC_str, sizeof TOGSPEC_str, ""_RED"[Spectoggler] "_WHITE"%s was unable to spectate you!", TOGSPEC_name);
	    SendClientMessage(targetplayerid, -1, TOGSPEC_str);
	    return 0;
	}
	TOGSPEC_SpecingID[playerid] = targetplayerid;
    return PlayerSpectatePlayer(playerid, targetplayerid, mode);
}

#if defined _ALS_PlayerSpectatePlayer
    #undef PlayerSpectatePlayer
#else
    #define _ALS_PlayerSpectatePlayer
#endif
#define PlayerSpectatePlayer _ALT_PlayerSpectatePlayer


public OnPlayerConnect(playerid)
{
	for(new i = 0; i < MAX_PLAYERS; i ++)
	{
		TOGSPEC_AbleToSpec[playerid][i] = true;
	}
	return CallLocalFunction("TOGSPEC_OnPlayerConnect", "i", playerid);
}

#if defined ALS_OnPlayerConnect
	#undef OnPlayerConnect
#else
	#define ALS_OnPlayerConnect
#endif
#define OnPlayerConnect TOGSPEC_OnPlayerConnect
forward TOGSPEC_OnPlayerConnect(playerid);

#if defined _zcmd_included
COMMAND:togspec(playerid, params[])
{
	new TOGSPEC_id, TOGSPEC_toggle;
	if(TOGSPEC_sscanf(params, "ui", TOGSPEC_id, TOGSPEC_toggle))
	{
	    SendClientMessage(playerid, -1, ""_RED"Usage: "_WHITE"/togspec [playerid] [toggle <0/1>]");
	    return 1;
	}
	if(!IsPlayerConnected(TOGSPEC_id) || IsPlayerNPC(TOGSPEC_id))
	{
	    SendClientMessage(playerid, 1, ""_RED"ERROR: "_WHITE"Invalid ID");
	    return 1;
	}
	new name[MAX_PLAYER_NAME], name2[MAX_PLAYER_NAME], str[128];
	if(TOGSPEC_toggle == 0 && TOGSPEC_AbleToSpec[playerid][TOGSPEC_id])
	{
		TOGSPEC_AbleToSpec[playerid][TOGSPEC_id] = false;
		if(TOGSPEC_SpecingID[TOGSPEC_id] == playerid)
		{
			TogglePlayerSpectating(TOGSPEC_id, false);
		}
        GetPlayerName(playerid, name, sizeof name);
        GetPlayerName(TOGSPEC_id, name2, sizeof name2);
		format(str, sizeof str, ""_RED"[Spectator Toggler] %s "_WHITE"has disabled "_RED"%s "_WHITE"from spectating him/her.", name, name2);
		SendClientMessageToAll(-1, str);
		format(str, sizeof str, ""_WHITE"You've successfully disabled "_YELLOW"%s "_WHITE"from spectating you!", name2);
		SendClientMessage(playerid, -1, str);
	}
	else if(TOGSPEC_toggle == 1 && !TOGSPEC_AbleToSpec[playerid][TOGSPEC_id])
	{
	    TOGSPEC_AbleToSpec[playerid][TOGSPEC_id] = true;
        GetPlayerName(playerid, name, sizeof name);
        GetPlayerName(TOGSPEC_id, name2, sizeof name2);
		format(str, sizeof str, ""_GREEN"[Spectator Toggler] %s "_WHITE"has enabled "_GREEN"%s "_WHITE"to spectate him/her.", name, name2);
		SendClientMessageToAll(-1, str);
		format(str, sizeof str, ""_WHITE"You've successfully enabled "_YELLOW"%s "_WHITE"to spectate you!", name2);
		SendClientMessage(playerid, -1, str);
	}
	return 1;
}
COMMAND:togspecall(playerid, params[])
{
    new TOGSPEC_toggle;
	if(TOGSPEC_sscanf(params, "i", TOGSPEC_toggle))
	{
	    SendClientMessage(playerid, -1, ""_RED"Usage: "_WHITE"/togspecall [toggle <0/1>]");
	    return 1;
	}
	new name[MAX_PLAYER_NAME], str[128];
	GetPlayerName(playerid, name, sizeof name);
	if(TOGSPEC_toggle == 0)
	{
	    for(new i = 0; i < MAX_PLAYERS; i ++)
	    {
	        if(!IsPlayerConnected(i) || IsPlayerNPC(i))
	            continue;

			TOGSPEC_AbleToSpec[playerid][i] = false;
	        if(TOGSPEC_SpecingID[i] == playerid)
	            TogglePlayerSpectating(i, false);
	    }
		format(str, sizeof str, ""_RED"[Spectator Toggler] %s "_WHITE"has disabled everyone from spectating him/her.", name);
		SendClientMessageToAll(-1, str);
		SendClientMessage(playerid, -1, ""_WHITE"You've successfully disabled everyone from spectating you!");
	}
	else if(TOGSPEC_toggle == 1)
	{
	    for(new i = 0; i < MAX_PLAYERS; i ++)
	    {
	        if(!IsPlayerConnected(i) || IsPlayerNPC(i))
	            continue;

			TOGSPEC_AbleToSpec[playerid][i] = true;
		}

		format(str, sizeof str, ""_GREEN"[Spectator Toggler] %s "_WHITE"has enabled everyone to spectate him/her.", name);
		SendClientMessageToAll(-1, str);
		SendClientMessage(playerid, -1, ""_WHITE"You've successfully enabled everyone to spectate you!");
	}
	return 1;
}

#else
public OnPlayerCommandText(playerid, cmdtext[])
{
	if(!strcmp(cmdtext, "/togspec", true, 8))
	{
		new TOGSPEC_id, TOGSPEC_toggle;
		if(TOGSPEC_sscanf(cmdtext[9], "ui", TOGSPEC_id, TOGSPEC_toggle))
		{
		    SendClientMessage(playerid, -1, ""_RED"Usage: "_WHITE"/togspec [playerid] [toggle <0/1>]");
		    return 1;
		}
		if(!IsPlayerConnected(TOGSPEC_id) || IsPlayerNPC(TOGSPEC_id))
		{
		    SendClientMessage(playerid, -1, ""_RED"ERROR: "_WHITE"Invalid ID");
		    return 1;
		}
		new name[MAX_PLAYER_NAME], name2[MAX_PLAYER_NAME], str[128];
		if(TOGSPEC_toggle == 0 && TOGSPEC_AbleToSpec[playerid][TOGSPEC_id])
		{
			TOGSPEC_AbleToSpec[playerid][id] = false;
			if(TOGSPEC_SpecingID[TOGSPEC_id] == playerid)
			{
				TogglePlayerSpectating(TOGSPEC_id, false);
			}
	        GetPlayerName(playerid, name, sizeof name);
	        GetPlayerName(TOGSPEC_id, name2, sizeof name2);
			format(str, sizeof str, ""_RED"[Spectator Toggler] %s "_WHITE"has disabled "_RED"%s "_WHITE"from spectating him/her.", name, name2);
			SendClientMessageToAll(-1, str);
			format(str, sizeof str, ""_WHITE"You've successfully disabled "_YELLOW"%s "_WHITE"from spectating you!", name2);
			SendClientMessage(playerid, -1, str);
		}
		else if(TOGSPEC_toggle == 1 && !TOGSPEC_AbleToSpec[playerid][TOGSPEC_id])
		{
		    TOGSPEC_AbleToSpec[playerid][TOGSPEC_id] = true;
	        GetPlayerName(playerid, name, sizeof name);
	        GetPlayerName(TOGSPEC_id, name2, sizeof name2);
			format(str, sizeof str, ""_GREEN"[Spectator Toggler] %s "_WHITE"has enabled "_GREEN"%s "_WHITE"to spectate him/her.", name, name2);
			SendClientMessageToAll(-1, str);
			format(str, sizeof str, ""_WHITE"You've successfully enabled "_YELLOW"%s "_WHITE"to spectate you!", name2);
			SendClientMessage(playerid, -1, str);
		}
		return 1;
	}
    if(!strcmp(cmdtext, "/togspecall", true, 11))
	{
	    new TOGSPEC_toggle;
		if(TOGSPEC_sscanf(cmdtext[12], "i", TOGSPEC_toggle))
		{
		    SendClientMessage(playerid, -1, ""_RED"Usage: "_WHITE"/togspecall [toggle <0/1>]");
		    return 1;
		}
		new name[MAX_PLAYER_NAME], str[128];
		GetPlayerName(playerid, name, sizeof name);
		if(TOGSPEC_toggle == 0)
		{
		    for(new i = 0; i < MAX_PLAYERS; i ++)
		    {
		        if(!IsPlayerConnected(i) || IsPlayerNPC(i))
		            continue;

				TOGSPEC_AbleToSpec[playerid][i] = false;
		        if(TOGSPEC_SpecingID[i] == playerid)
		            TogglePlayerSpectating(i, false);
		    }
			format(str, sizeof str, ""_RED"[Spectator Toggler] %s "_WHITE"has disabled everyone from spectating him/her.", name);
			SendClientMessageToAll(-1, str);
			SendClientMessage(playerid, -1, ""_WHITE"You've successfully disabled everyone from spectating you!");
		}
		else if(TOGSPEC_toggle == 1)
		{
		    for(new i = 0; i < MAX_PLAYERS; i ++)
		    {
		        if(!IsPlayerConnected(i) || IsPlayerNPC(i))
		            continue;

				TOGSPEC_AbleToSpec[playerid][i] = true;
			}

			format(str, sizeof str, ""_GREEN"[Spectator Toggler] %s "_WHITE"has enabled everyone to spectate him/her.", name);
			SendClientMessageToAll(-1, str);
			SendClientMessage(playerid, -1, ""_WHITE"You've successfully enabled everyone to spectate you!");
		}
		return 1;
	}
	return CallLocalFunction("TOGSPEC_OnPlayerCommandText", "is", playerid, cmdtext);
}

#if defined ALS_OnPlayerCommandText
	#undef OnPlayerCommandText
#else
	#define ALS_OnPlayerCommandText
#endif
#define OnPlayerCommandText TOGSPEC_OnPlayerCommandText
forward TOGSPEC_OnPlayerCommandText(playerid, cmdtext[]);
#endif

// Y's SSCANF
stock TOGSPEC_sscanf(string[], format[], {Float,_}:...)
{
	#if defined isnull
		if (isnull(string))
	#else
		if (string[0] == 0 || (string[0] == 1 && string[1] == 0))
	#endif
		{
			return format[0];
		}
	#pragma tabsize 4
	new
		formatPos = 0,
		stringPos = 0,
		paramPos = 2,
		paramCount = numargs(),
		delim = ' ';
	while (string[stringPos] && string[stringPos] <= ' ')
	{
		stringPos++;
	}
	while (paramPos < paramCount && string[stringPos])
	{
		switch (format[formatPos++])
		{
			case '\0':
			{
				return 0;
			}
			case 'i', 'd':
			{
				new
					neg = 1,
					num = 0,
					ch = string[stringPos];
				if (ch == '-')
				{
					neg = -1;
					ch = string[++stringPos];
				}
				do
				{
					stringPos++;
					if ('0' <= ch <= '9')
					{
						num = (num * 10) + (ch - '0');
					}
					else
					{
						return -1;
					}
				}
				while ((ch = string[stringPos]) > ' ' && ch != delim);
				setarg(paramPos, 0, num * neg);
			}
			case 'h', 'x':
			{
				new
					num = 0,
					ch = string[stringPos];
				do
				{
					stringPos++;
					switch (ch)
					{
						case 'x', 'X':
						{
							num = 0;
							continue;
						}
						case '0' .. '9':
						{
							num = (num << 4) | (ch - '0');
						}
						case 'a' .. 'f':
						{
							num = (num << 4) | (ch - ('a' - 10));
						}
						case 'A' .. 'F':
						{
							num = (num << 4) | (ch - ('A' - 10));
						}
						default:
						{
							return -1;
						}
					}
				}
				while ((ch = string[stringPos]) > ' ' && ch != delim);
				setarg(paramPos, 0, num);
			}
			case 'c':
			{
				setarg(paramPos, 0, string[stringPos++]);
			}
			case 'f':
			{

				new changestr[16], changepos = 0, strpos = stringPos;
				while(changepos < 16 && string[strpos] && string[strpos] != delim)
				{
					changestr[changepos++] = string[strpos++];
    				}
				changestr[changepos] = '\0';
				setarg(paramPos,0,_:floatstr(changestr));
			}
			case 'p':
			{
				delim = format[formatPos++];
				continue;
			}
			case '\'':
			{
				new
					end = formatPos - 1,
					ch;
				while ((ch = format[++end]) && ch != '\'') {}
				if (!ch)
				{
					return -1;
				}
				format[end] = '\0';
				if ((ch = strfind(string, format[formatPos], false, stringPos)) == -1)
				{
					if (format[end + 1])
					{
						return -1;
					}
					return 0;
				}
				format[end] = '\'';
				stringPos = ch + (end - formatPos);
				formatPos = end + 1;
			}
			case 'u':
			{
				new
					end = stringPos - 1,
					ssf_id = 0,
					bool:num = true,
					ch;
				while ((ch = string[++end]) && ch != delim)
				{
					if (num)
					{
						if ('0' <= ch <= '9')
						{
							ssf_id = (ssf_id * 10) + (ch - '0');
						}
						else
						{
							num = false;
						}
					}
				}
				if (num && IsPlayerConnected(ssf_id))
				{
					setarg(paramPos, 0, ssf_id);
				}
				else
				{
					#if !defined foreach
						#define foreach(%1,%2) for (new %2 = 0; %2 < MAX_PLAYERS; %2++) if (IsPlayerConnected(%2))
						#define __SSCANF_FOREACH__
					#endif
					string[end] = '\0';
					num = false;
					new
						name[MAX_PLAYER_NAME];
					ssf_id = end - stringPos;
					foreach (Player, playerid)
					{
						GetPlayerName(playerid, name, sizeof (name));
						if (!strcmp(name, string[stringPos], true, ssf_id))
						{
							setarg(paramPos, 0, playerid);
							num = true;
							break;
						}
					}
					if (!num)
					{
						setarg(paramPos, 0, INVALID_PLAYER_ID);
					}
					string[end] = ch;
					#if defined __SSCANF_FOREACH__
						#undef foreach
						#undef __SSCANF_FOREACH__
					#endif
				}
				stringPos = end;
			}
			case 's', 'z':
			{
				new
					i = 0,
					ch;
				if (format[formatPos])
				{
					while ((ch = string[stringPos++]) && ch != delim)
					{
						setarg(paramPos, i++, ch);
					}
					if (!i)
					{
						return -1;
					}
				}
				else
				{
					while ((ch = string[stringPos++]))
					{
						setarg(paramPos, i++, ch);
					}
				}
				stringPos--;
				setarg(paramPos, i, '\0');
			}
			default:
			{
				continue;
			}
		}
		while (string[stringPos] && string[stringPos] != delim && string[stringPos] > ' ')
		{
			stringPos++;
		}
		while (string[stringPos] && (string[stringPos] == delim || string[stringPos] <= ' '))
		{
			stringPos++;
		}
		paramPos++;
	}
	do
	{
		if ((delim = format[formatPos++]) > ' ')
		{
			if (delim == '\'')
			{
				while ((delim = format[formatPos++]) && delim != '\'') {}
			}
			else if (delim != 'z')
			{
				return delim;
			}
		}
	}
	while (delim > ' ');
	return 0;
}