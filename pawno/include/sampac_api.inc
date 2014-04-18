/*

	Example usage: https://sixtytiger.com/tiger/script/ac2.txt

*/

#include <a_samp>
#include <a_http>

#if defined _sampac_api_included
	#endinput
#endif
#define _sampac_api_included

#if !defined _sampac_PLUGINS

	#define _sampac_PLUGINS 0

#endif

#if !defined _sampac_TIMERMODE

	#define _sampac_TIMERMODE 0

#endif

#define _sampac_DEBUG 0

#if _sampac_PLUGINS == 1

#include <sscanf2>
#define QUERY_URL 			"sixtytiger.com/AC_API/pInfo1.8.php"
#define UPDATE_URL          "sixtytiger.com/AC_API/update.php"

#else

#include <strlib>
#define QUERY_URL 			"sixtytiger.com/AC_API/pInfo_1.8.php"
#define UPDATE_URL          "sixtytiger.com/AC_API/update_.php"
#define ALL_QUERY_URL       "sixtytiger.com/AC_API/allpInfo.php"

#endif

#define BAN_URL             "sixtytiger.com/AC_API/ban.php"

// in hindsight, pretty stupid to have different PHP scripts for with and without plugin, have to keep them now compatibility, can't be FUCKED to change it either.
// (why is there even options for with and without plugin, anyway?)

#include <YSI\y_iterate>

#define VERSION 2.0

new AC_TIME_OFFSET = 30000;

#define THREAD_OFFSET 100
#define FILES 31

#if THREAD_OFFSET > MAX_PLAYERS
	#undef THREAD_OFFSET
	#define THREAD_OFFSET MAX_PLAYERS
#endif

new AC_Update;

new bool:ACRunning[MAX_PLAYERS];
new bool:HasASI[MAX_PLAYERS];
new bool:HasTrainer[MAX_PLAYERS];
new bool:samp_ac_Frozen[MAX_PLAYERS];
new bool:ignoreNext[MAX_PLAYERS];
new bool:ACOn;
new bool:checkedUpdate;

#if _sampac_TIMERMODE == 1
new ac_Timers[MAX_PLAYERS];
#endif

new bool:Files[MAX_PLAYERS][FILES];

stock bool:AC_Toggle(bool:set);

new fileNames[FILES][50] = {
	!"anim/ped.ifp",             // file_0
    !"data/carmods.dat",         // file_1
    !"data/animgrp.dat",         // file_2
    !"data/melee.dat",           // file_3
    !"data/clothes.dat",         // file_4
    !"data/object.dat",          // file_5
    !"data/default.dat",         // file_6
    !"data/surface.dat",         // file_7
    !"data/default.ide",         // file_8
    !"data/gta.dat",             // file_9
    !"data/surfinfo.dat",        // file_10
    !"data/peds.ide",            // file_11
    !"data/vehicles.ide",        // file_12
    !"data/water.dat",           // file_13
    !"data/txdcut.ide",          // file_14
    !"data/water1.dat",          // file_15
    !"models/coll/weapons.col",  // file_16
    !"data/plants.dat",          // file_17
    !"data/furnitur.dat",        // file_18
    !"data/procobj.dat",         // file_19
    !"data/handling.cfg",        // file_20
    !"models/coll/peds.col",     // file_21
    !"models/coll/vehicles.col", // file_22
    !"samp.saa",                 // file_23
    !"samp.exe",                 // file_24
    !"vorbis.dll",               // file_25
    !"data/pedstats.dat",        // file_26
    !"data/ar_stats.dat",        // file_27
    !"vorbisfile.dll",           // file_28
    !"gta_sa.exe",               // file_29
    !"samp.dll"                  // file_30
    //                              ^^ internal file names for AC

};


public OnFilterScriptInit()
{
	if(checkedUpdate == false) {
		HTTP(THREAD_OFFSET, HTTP_GET, UPDATE_URL, "", "UpdateResponse");
		checkedUpdate = true;
		AC_Update = SetTimer("AC_MainUpdate", AC_TIME_OFFSET, 1);
		ACOn = false;
	}
	return CallLocalFunction("samp_ac_OnFilterScriptInit", "");
}

#if defined _ALS_OnFilterScriptInit
    #undef OnFilterScriptInit
#else
    #define _ALS_OnFilterScriptInit
#endif
#define OnFilterScriptInit samp_ac_OnFilterScriptInit

forward samp_ac_OnFilterScriptInit();

public OnGameModeInit() {
    if(checkedUpdate == false) {
		HTTP(THREAD_OFFSET, HTTP_GET, UPDATE_URL, "", "UpdateResponse");
		checkedUpdate = true;
		AC_Update = SetTimer("AC_MainUpdate", AC_TIME_OFFSET, 1);
		ACOn = false;
	}
	return CallLocalFunction("samp_ac_OnGameModeInit", "");
}

#if defined _ALS_OnGameModeInit
    #undef OnGameModeInit
#else
    #define _ALS_OnGameModeInit
#endif
#define OnGameModeInit samp_ac_OnGameModeInit

forward samp_ac_OnGameModeInit();

public OnGameModeExit() {
	KillTimer(AC_Update);
	return CallLocalFunction("samp_ac_OnGameModeExit", "");
}

#if defined _ALS_OnGameModeExit
    #undef OnGameModeExit
#else
    #define _ALS_OnGameModeExit
#endif
#define OnGameModeExit samp_ac_OnGameModeExit

forward samp_ac_OnGameModeExit();

public OnFilterScriptExit() {
	KillTimer(AC_Update);
	return CallLocalFunction("samp_ac_OnFilterScriptExit", "");
}

#if defined _ALS_OnFilterScriptExit
    #undef OnFilterScriptExit
#else
    #define _ALS_OnFilterScriptExit
#endif
#define OnFilterScriptExit samp_ac_OnFilterScriptExit

forward samp_ac_OnFilterScriptExit();


forward UpdateResponse(index, code, data[]);
public UpdateResponse(index, code, data[]) {
    if(code != 200) {
        //HTTP(THREAD_OFFSET, HTTP_GET, UPDATE_URL, "", "UpdateResponse");
	    return printf("Whitetiger's Anti-cheat error: Failed to connect to website API");
	}
	#pragma unused index

	new Float:version = 0.0, url[128];

	#if _sampac_PLUGINS == 0

	new str[5][128];
	strexplode(str, data, ",");
	version = floatstr(str[0]);
	url = str[1];

	if(!strlen(url) || version == 0.0) {
	    return printf("Whitetiger's AC Error: Failed to check for an update.");
	}

	#else

	if(sscanf(data, "fs[128]", version, url)) {
	    return printf("Whitetiger's AC Error: Failed to check for an update.");
	}

	#endif

	if(version > VERSION) {
	    printf("__________________________________________________");
	    printf("");
	    printf("** Your Whitetiger's Anti-Cheat API include is out of date, your old version may not continue to work.");
		printf("A new version is available at: %s", url);
		printf("");
		printf("__________________________________________________");

	} else if(!strcmp(url, "- Server not approved for Anti-Cheat usage.")) {
	    printf(data);
	    printf("__________________________________________________");
	    printf("");
	    printf("** Server not approved for Whitetiger's Anti-cheat Usage, Disabled.");
	    printf("");
	    printf("__________________________________________________");
	} else if(!strcmp(url, "Under Maintenance.")) {
	    printf("__________________________________________________");
	    printf("");
	    printf("** Whitetiger's Anti-Cheat is current under scheduled maintenance, it cannot be enabled at this time.");
	    printf("");
	    printf("__________________________________________________");
	    AC_Toggle(false);
	} else {
	    printf("__________________________________________________");
	    printf("");
	    printf("** Whitetiger's Anti-Cheat is on the most up-to-date version!");
	    printf("");
	    printf("__________________________________________________");
	}
	
	HTTP(THREAD_OFFSET + THREAD_OFFSET, HTTP_GET, "sixtytiger.com/AC_API/query_bug_thread_wait.php", "", "ThreadWaitTime");
	return 1;
}

/*public OnPlayerConnect(playerid)
{
 	//HTTP(playerid + THREAD_OFFSET + THREAD_OFFSET, HTTP_POST, BAN_URL, postdata, "BanResponse");
   	if(ACOn == true) {
		//AC_GetInfo(playerid);
		#if _sampac_TIMERMODE == 1
		ac_Timers[playerid] = SetTimerEx("AC_GetInfoTimer", AC_TIME_OFFSET, 0, "d", playerid);
		#endif
	}
   	return CallLocalFunction("samp_ac_OnPlayerConnect", "i", playerid);
}

#if defined _ALS_OnPlayerConnect
    #undef OnPlayerConnect
#else
    #define _ALS_OnPlayerConnect
#endif
#define OnPlayerConnect samp_ac_OnPlayerConnect

forward samp_ac_OnPlayerConnect(playerid);*/

public OnPlayerDisconnect(playerid, reason) {
	
	ACRunning[playerid] 		= false;
	HasASI[playerid] 			= false;
	HasTrainer[playerid] 		= false;
	samp_ac_Frozen[playerid]    = false;
	ignoreNext[playerid]        = false;

	for(new i=0; i < FILES; ++i) {
	    Files[playerid][i] = true;
	}
	
	#if _sampac_TIMERMODE == 1
	KillTimer(ac_Timers[playerid]);
	ac_Timers[playerid] = -1;
	#endif

	return CallLocalFunction("samp_ac_OnPlayerDisconnect", "ii", playerid, reason);
}

#if defined _ALS_OnPlayerDisconnect
    #undef OnPlayerDisconnect
#else
    #define _ALS_OnPlayerDisconnect
#endif
#define OnPlayerDisconnect samp_ac_OnPlayerDisconnect

forward samp_ac_OnPlayerDisconnect(playerid, reason);

public OnPlayerSpawn(playerid) {

	samp_ac_Frozen[playerid] = false;

	return CallLocalFunction("samp_ac_OnPlayerSpawn", "i", playerid);
}

#if defined _ALS_OnPlayerSpawn
    #undef OnPlayerSpawn
#else
    #define _ALS_OnPlayerSpawn
#endif
#define OnPlayerSpawn samp_ac_OnPlayerSpawn

forward samp_ac_OnPlayerSpawn(playerid);

stock samp_ac_Controllable(playerid, frozen) {

	samp_ac_Frozen[playerid] = frozen == 0 ? true : false;
	ignoreNext[playerid] = true;
	
	SetPlayerVelocity(playerid, 0.0, 0.0, 0.0);
	if(IsPlayerInAnyVehicle(playerid)) SetVehicleVelocity(GetPlayerVehicleID(playerid), 0.0, 0.0, 0.0);
	else ClearAnimations(playerid);
	
	TogglePlayerControllable(playerid, frozen);
}

#if defined _ALS_TogglePlayerControllable
    #undef TogglePlayerControllable
#else
    #define _ALS_TogglePlayerControllable
#endif
#define TogglePlayerControllable samp_ac_Controllable

#if _sampac_TIMERMODE == 0
forward AC_MainUpdate();
public AC_MainUpdate() {
	if(ACOn == true) {
		AC_GetAllInfo();
	} else {
		KillTimer(AC_Update);
	}
}

#else
forward AC_GetInfoTimer(playerid);
public AC_GetInfoTimer(playerid) {
	if(!IsPlayerConnected(playerid)) return 1;
	
    AC_GetInfo(playerid);
	ac_Timers[playerid] = SetTimerEx("AC_GetInfoTimer", AC_TIME_OFFSET, 0, "d", playerid);
		
	return 1;
}

stock AC_EnableForPlayer(playerid) {
	ac_Timers[playerid] = SetTimerEx("AC_GetInfoTimer", AC_TIME_OFFSET, 0, "d", playerid);
}

stock AC_DisableForPlayer(playerid) {
	KillTimer(ac_Timers[playerid]);
}
#endif

stock AC_GetInfo(playerid) {

    new IP[MAX_PLAYER_NAME], url[128], postdata[50];
	GetPlayerIp(playerid, IP, sizeof(IP));
	
	#if _sampac_DEBUG == 1
	if(!strcmp(IP, "127.0.0.1", true) || !strcmp(IP, "192.168.1.67", true)) {
		IP = "";
	}
	#endif

 	format(url, sizeof(url), QUERY_URL);
 	format(postdata, sizeof(postdata), "IP=%s", IP);
	HTTP(playerid + THREAD_OFFSET, HTTP_POST, url, postdata, "ACResponse");
	
	return 1;
}

stock AC_GetAllInfo() {
	new IP[MAX_PLAYER_NAME], postdata[256];
	
	for(new i=0; i < MAX_PLAYERS; ++i) {
	    if(!IsPlayerConnected(i)) continue;
		GetPlayerIp(i, IP, sizeof(IP));

		#if _sampac_DEBUG == 1
		if(!strcmp(IP, "127.0.0.1", true) || !strcmp(IP, "192.168.1.67", true)) {
			IP = "";
		}
		#endif
		
		if(strlen(postdata) > 0) format(postdata, sizeof(postdata), "%s&IP%d=%s", postdata, i, IP);
		else format(postdata, sizeof(postdata), "IP%d=%s", i, IP);
		
		if(i % 5 == 0) {
		    HTTP(THREAD_OFFSET, HTTP_POST, ALL_QUERY_URL, postdata, "AllACResponse");
		    postdata = "";
		}
	}
	if(strlen(postdata) > 0) {
	    HTTP(THREAD_OFFSET, HTTP_POST, ALL_QUERY_URL, postdata, "AllACResponse");
	}
}

/*forward BanResponse(index, code, data[]);
public BanResponse(index, code, data[]) {
	new playerid = (index - THREAD_OFFSET) - THREAD_OFFSET;
	if(code != 200) {
	    new IP[MAX_PLAYER_NAME], postdata[50];
		GetPlayerIp(playerid, IP, sizeof(IP));

		#if _sampac_DEBUG == 1
		if(!strcmp(IP, "127.0.0.1", true)) {
			IP = "";
		}
		#endif
		format(postdata, sizeof(postdata), "IP=%s", IP);

		HTTP(playerid + THREAD_OFFSET + THREAD_OFFSET, HTTP_POST, BAN_URL, postdata, "BanResponse");
		return printf("Whitetiger's Anti-cheat error: Failed to connect to website API");
	}
	
	if(!strcmp(data, "1", true)) {
	    SetTimerEx("KickPlayer", 1, 0, "d", playerid); // 1 ms timer fix so player who gets kicked actually recieves this message
	    new str[128], name[MAX_PLAYER_NAME];
	    GetPlayerName(playerid, name, sizeof(name));
	    format(str, sizeof(str), "{FF0000}%s{FFFFFF} has been kicked from the server for being banned from Whitetiger's Anti-Cheat", name);
	    SendClientMessageToAll(-1, str);
	}
	return 1;
}

forward KickPlayer(playerid);
public KickPlayer(playerid) {
	Kick(playerid);
}*/

forward ACResponse(index, code, data[]);
public ACResponse(index, code, data[]) {
    if(code != 200 && ACOn) {
        // try again?
        //AC_GetInfo(index - THREAD_OFFSET);
	    return printf("Whitetiger's Anti-cheat error: Failed to connect to website API");
	}

	if(strlen(data) > 1) {
		
		if(!strcmp(data, "Under Maintenance")) {
		    printf("__________________________________________________");
		    printf("");
		    printf("** Whitetiger's Anti-Cheat is current under scheduled maintenance, it cannot be enabled at this time.");
		    printf("");
		    printf("__________________________________________________");
		    AC_Toggle(false);
		    return 1;
		}
		
		#if _sampac_DEBUG == 1
		//printf(data);
		#endif
		
		new Float:X, Float:Y, Float:Z;
		
	    #if _sampac_PLUGINS == 1
	    
		new bool:acrunning, bool:hasasi, bool:hastrainer;
		sscanf(data, "p< >lllA<l>(false)["#FILES"]fff", acrunning, hasasi, hastrainer, Files[index - THREAD_OFFSET], X, Y, Z);
		
		ACRunning[index - THREAD_OFFSET] 		= acrunning;
		HasASI[index - THREAD_OFFSET] 			= hasasi;
		HasTrainer[index - THREAD_OFFSET] 		= hastrainer;

		#else

		new str[38][20];
		strexplode(str, data, ",");
		
		ACRunning[index - THREAD_OFFSET] 			= strcmp(str[0], "false") == 0 ? false : strcmp(str[0], "0") == 0 ? false : true;
		HasASI[index - THREAD_OFFSET] 				= strcmp(str[1], "false") == 0 ? false : strcmp(str[1], "0") == 0 ? false : true;
		HasTrainer[index - THREAD_OFFSET] 			= strcmp(str[2], "false") == 0 ? false : strcmp(str[2], "0") == 0 ? false : true;
		
		for(new i=0; i < FILES; ++i) {

		    if(!strcmp(str[i+3], "0")) { // prevent anim/ped.ifp false kicks
				Files[index - THREAD_OFFSET][i] 	= true;
				continue;
			}
			Files[index - THREAD_OFFSET][i] 		= strcmp(str[i+3], "false") == 0 ? false : true;
		}
		X = floatstr(str[3+FILES]);
		Y = floatstr(str[3+FILES+1]);
		Z = floatstr(str[3+FILES+2]);

		#endif
		
		if(samp_ac_Frozen[index - THREAD_OFFSET] == true && ignoreNext[index - THREAD_OFFSET] == false && ACRunning[index - THREAD_OFFSET] == true && IsPlayerConnected(index - THREAD_OFFSET) && OnPlayerUpdate(index - THREAD_OFFSET) != 0) {

			new Float:X2, Float:Y2, Float:Z2;
			GetPlayerPos(index - THREAD_OFFSET, X2, Y2, Z2);

			new string[128];
			new string2[128];
			new maxcharacters_mismatchable = 1;
			if(!IsPlayerInAnyVehicle(index - THREAD_OFFSET)) {
				format(string, sizeof(string), "%0.5f %0.5f %0.5f", X, Y, Z);
				format(string2, sizeof(string2), "%0.5f %0.5f %0.5f", X2, Y2, Z2);
			} else {

			    new Float:X3, Float:Y3, Float:Z3;
				GetVehicleVelocity(GetPlayerVehicleID(index - THREAD_OFFSET), X3, Y3, Z3);

				if(X3 == 0.0 || Y3 == 0.0 || Z3 == 0.0) { // prevent while in heli or vehicle is moving somehow

				    format(string, sizeof(string), "%0.2f %0.2f", X, Y);
					format(string2, sizeof(string2), "%0.2f %0.2f", X2, Y2);
					maxcharacters_mismatchable = 3;
				}
			}
			

			if(proper_strcmp(string, string2) > maxcharacters_mismatchable && strlen(string) > 0 && strlen(string2) > 0) {
			    // 2 PC trick
			    CallLocalFunction("OnUsingAnotherPC", "d", index - THREAD_OFFSET);
			    samp_ac_Frozen[index - THREAD_OFFSET] = false; // don't call again unless frozen again to avoid spam
			}
		}

		if(ignoreNext[index - THREAD_OFFSET] == true) {
		    ignoreNext[index - THREAD_OFFSET] = false;
		}
	} else {
	    ACRunning[index - THREAD_OFFSET] 			= false;
	}

	// check if they're still connected when the HTTP thread finished.
	if(IsPlayerConnected(index - THREAD_OFFSET)) {
		CallLocalFunction("OnACUpdated", "d", index - THREAD_OFFSET);


		for(new i=0; i < FILES; ++i) {
			if(Files[index - THREAD_OFFSET][i] == false && ACRunning[index - THREAD_OFFSET] == true) {
			    // check if player is connected again (yes, in the loop), in case they got kicked or banned when OnACUpdated got called.
			    if(IsPlayerConnected(index - THREAD_OFFSET)) {
			    	CallLocalFunction("OnACFileModified", "ds", index - THREAD_OFFSET, fileNames[i]);
				}
    		}
		}
	}
	return 0;
}

forward AllACResponse(index, code, data[]);
public AllACResponse(index, code, data[]) {
	new idx = strfind(data, "|"), lastidx = -1, strOut[256], playerid;
	do {
		strmid(strOut, data, lastidx + 1, idx);
		lastidx = idx;
		new str[2];
		strmid(str, strOut, 0, 1);
		playerid = strval(str);
		idx = strfind(data, "|", false, lastidx+1);
		if(!IsPlayerConnected(playerid)) continue;
		strdel(strOut, 0, 3);
		ACResponse(index + playerid, code, strOut);
	} while(idx != -1);
}

stock proper_strcmp(string1[], string2[]) {
	new len = strlen(string1) > strlen(string2) ? strlen(string1) : strlen(string2);
	new differences = 0;
	for(new i=0; i < len; ++i) {
	    if(string1[i] != string2[i]) differences++;
	}
	return differences;
}

#define AC_Running(%0) ACRunning[%0]
#define AC_HasTrainer(%0) HasTrainer[%0]
#define AC_ASI(%0) HasASI[%0]
#define AC_GetEnabled() ACOn

stock bool:AC_Toggle(bool:set) {
	ACOn = set;

	if(set) {
		#if _sampac_TIMERMODE == 0
	    AC_MainUpdate();
	    AC_Update = SetTimer("AC_MainUpdate", AC_TIME_OFFSET, 1);
	    #else
	    foreach(new i : Player) {
	        ac_Timers[i] = SetTimerEx("AC_GetInfoTimer", AC_TIME_OFFSET, 0, "d", i);
	    }
	    #endif
	} else {
	    #if _sampac_TIMERMODE == 0
		KillTimer(AC_Update);
		#else
		/*foreach(new i : Player) {
		    ac_Timers[i] = SetTimerEx("AC_GetInfoTimer", AC_TIME_OFFSET, 0, "d", i);
		}*/
		for(new i=0; i < MAX_PLAYERS; ++i) {
		    KillTimer(ac_Timers[i]);
		}
		#endif
	}
	
	CallLocalFunction("OnACToggled", "d", set);
}

forward ThreadWaitTime(index, code, data[]);
public ThreadWaitTime(index, code, data[]) {

    for (new i = 0, j = strlen(data); i < j; i++)
    {
        if (data[i] > '9' || data[i] < '0') return 0;
    }
    
    AC_TIME_OFFSET = strval(data) + 2500;
	return 1;
}

forward OnACToggled(bool:set);
forward OnACUpdated(playerid);
forward OnUsingAnotherPC(playerid);
forward OnACFileModified(playerid, file[]);
