#include <a_samp>
#include <YSI\y_hooks>

// Players Move Speed
#define MOVE_SPEED              100.0
#define ACCEL_RATE              0.03

// Players Mode
#define CAMERA_MODE_NONE    	0
#define CAMERA_MODE_FLY     	1

// Key state definitions
#define MOVE_FORWARD    		1
#define MOVE_BACK       		2
#define MOVE_LEFT       		3
#define MOVE_RIGHT      		4
#define MOVE_FORWARD_LEFT       5
#define MOVE_FORWARD_RIGHT      6
#define MOVE_BACK_LEFT          7
#define MOVE_BACK_RIGHT         8

// Enumeration for storing data about the player
enum noclipenum
{
	cameramode,
	flyobject,
	noclipcammode,
	lrold,
	udold,
	lastmove,
	Float:accelmul
}
new noclipdata[MAX_PLAYERS][noclipenum];

//--------------------------------------------------

hook OnFilterScriptExit()
{
	// If any players are still in edit mode, boot them out before the filterscript unloads
	for(new x; x<MAX_PLAYERS; x++)
	{
		if(noclipdata[x][cameramode] == CAMERA_MODE_FLY) CancelFlyMode(x);
	}
	return 1;
}

//--------------------------------------------------

hook OnPlayerConnect(playerid)
{
	// Reset the data belonging to this player slot
	noclipdata[playerid][cameramode] 	= CAMERA_MODE_NONE;
	noclipdata[playerid][lrold]	   	 	= 0;
	noclipdata[playerid][udold]   		= 0;
	noclipdata[playerid][noclipcammode]   		= 0;
	noclipdata[playerid][lastmove]   	= 0;
	noclipdata[playerid][accelmul]   	= 0.0;
	return 1;
}

//--------------------------------------------------

COMMAND:freecam(playerid, params[])
{
	if(Player[playerid][Playing] == true) 
		return 1;
	if(Player[playerid][Spectating] == true)
		return 1;
	if(Player[playerid][InDM] == true)
		return 1;
	if(Player[playerid][InDuel] == true)
		return 1;
	if(Player[playerid][IsAFK] == true)
		return 1;		
	if(Player[playerid][IsFrozen] == true)
		return 1;
	if(Player[playerid][IsFreezed] == true)
		return 1;
	if(Player[playerid][ToAddInRound] == true)
		return 1;
	if(Player[playerid][AntiLag] == true)
		return 1;
	if(Player[playerid][InHeadShot] == true)
		return 1;
    // Place the player in and out of edit mode
	if(GetPVarType(playerid, "FlyMode")) CancelFlyMode(playerid);
	else
	{
		FlyMode(playerid);
		SendClientMessage(playerid, -1, "Type /freecam again to exit this mode!");
		//SendClientMessage(playerid, -1, "Use /moveit to move the camera to a player!");
	}
	return 1;
}
/*
COMMAND:moveit(playerid, params[])
{
	if(!GetPVarType(playerid, "FlyMode"))
		return Error(playerid, "You aren't in no-clip fly mode!");
		
	new str[64], ideh;
	if(sscanf(params, "s[64]i", str, ideh))
		return MessageBox(playerid, "~r~~h~~h~Usage", "/moveit [1cp/2cp/arena/battle/base] [ID]");
	
	if(!strcmp(str, "1cp", true))
	{
		if(!OneCPFieldData[ideh][available])
			return Error(playerid, "Invalid field ID");
		MoveIt(playerid, OneCPFieldData[ideh][CP1Pos][0], OneCPFieldData[ideh][CP1Pos][1], OneCPFieldData[ideh][CP1Pos][2] );
		return 1;
	}
	else if(!strcmp(str, "2cp", true))
	{
		if(!TwoCPFieldData[ideh][available])
			return Error(playerid, "Invalid field ID");
		MoveIt(playerid, TwoCPFieldData[ideh][CP1Pos][0], TwoCPFieldData[ideh][CP1Pos][1], TwoCPFieldData[ideh][CP1Pos][2] );	
		return 1;
	}
	else if(!strcmp(str, "arena", true))
	{
		if(!ArenaData[ideh][available])
			return Error(playerid, "Invalid field ID");
		MoveIt(playerid, ArenaData[ideh][Team1Spawn][0], ArenaData[ideh][Team1Spawn][1], ArenaData[ideh][Team1Spawn][2] );	
		return 1;
	}
	else if(!strcmp(str, "battle", true))
	{
		if(!BattleData[ideh][available])
			return Error(playerid, "Invalid field ID");
		MoveIt(playerid, BattleData[ideh][Spawn][0], BattleData[ideh][Spawn][1], BattleData[ideh][Spawn][2] );	
		return 1;
	}
	else if(!strcmp(str, "base", true))
	{
		if(!BaseData[ideh][available])
			return Error(playerid, "Invalid field ID");
		MoveIt(playerid, BaseData[ideh][CP1Pos][0], BaseData[ideh][CP1Pos][1], BaseData[ideh][CP1Pos][2] );
		return 1;
	}
	else
		return MessageBox(playerid, "~r~~h~~h~Usage", "/moveit [1cp/2cp/arena/battle/base] [ID]");
}
*/
//--------------------------------------------------

hook OnPlayerUpdate(playerid)
{
	if(noclipdata[playerid][cameramode] == CAMERA_MODE_FLY)
	{
		SetPlayerVirtualWorld(playerid, 0);
		
		new keys,ud,lr;
		GetPlayerKeys(playerid,keys,ud,lr);

		if(noclipdata[playerid][noclipcammode] && (GetTickCount() - noclipdata[playerid][lastmove] > 100))
		{
		    // If the last move was > 100ms ago, process moving the object the players camera is attached to
		    MoveCamera(playerid);
		}

		// Is the players current key state different than their last keystate?
		if(noclipdata[playerid][udold] != ud || noclipdata[playerid][lrold] != lr)
		{
			if((noclipdata[playerid][udold] != 0 || noclipdata[playerid][lrold] != 0) && ud == 0 && lr == 0)
			{   // All keys have been released, stop the object the camera is attached to and reset the acceleration multiplier
				StopPlayerObject(playerid, noclipdata[playerid][flyobject]);
				noclipdata[playerid][noclipcammode]      = 0;
				noclipdata[playerid][accelmul]  = 0.0;
			}
			else
			{   // Indicates a new key has been pressed

			    // Get the direction the player wants to move as indicated by the keys
				noclipdata[playerid][noclipcammode] = GetMoveDirectionFromKeys(ud, lr);

				// Process moving the object the players camera is attached to
				MoveCamera(playerid);
			}
		}
		noclipdata[playerid][udold] = ud; noclipdata[playerid][lrold] = lr; // Store current keys pressed for comparison next update
		return 0;
	}
	return 1;
}

//--------------------------------------------------

stock GetMoveDirectionFromKeys(ud, lr)
{
	new direction = 0;
	
    if(lr < 0)
	{
		if(ud < 0) 		direction = MOVE_FORWARD_LEFT; 	// Up & Left key pressed
		else if(ud > 0) direction = MOVE_BACK_LEFT; 	// Back & Left key pressed
		else            direction = MOVE_LEFT;          // Left key pressed
	}
	else if(lr > 0) 	// Right pressed
	{
		if(ud < 0)      direction = MOVE_FORWARD_RIGHT;  // Up & Right key pressed
		else if(ud > 0) direction = MOVE_BACK_RIGHT;     // Back & Right key pressed
		else			direction = MOVE_RIGHT;          // Right key pressed
	}
	else if(ud < 0) 	direction = MOVE_FORWARD; 	// Up key pressed
	else if(ud > 0) 	direction = MOVE_BACK;		// Down key pressed
	
	return direction;
}

//--------------------------------------------------

stock MoveCamera(playerid)
{
	new Float:FV[3], Float:CP[3];
	GetPlayerCameraPos(playerid, CP[0], CP[1], CP[2]);          // 	Cameras position in space
    GetPlayerCameraFrontVector(playerid, FV[0], FV[1], FV[2]);  //  Where the camera is looking at

	// Increases the acceleration multiplier the longer the key is held
	if(noclipdata[playerid][accelmul] <= 1) noclipdata[playerid][accelmul] += ACCEL_RATE;

	// Determine the speed to move the camera based on the acceleration multiplier
	new Float:speed = MOVE_SPEED * noclipdata[playerid][accelmul];

	// Calculate the cameras next position based on their current position and the direction their camera is facing
	new Float:X, Float:Y, Float:Z;
	GetNextCameraPosition(noclipdata[playerid][noclipcammode], CP, FV, X, Y, Z);
	MovePlayerObject(playerid, noclipdata[playerid][flyobject], X, Y, Z, speed);

	// Store the last time the camera was moved as now
	noclipdata[playerid][lastmove] = GetTickCount();
	return 1;
}

//--------------------------------------------------

stock GetNextCameraPosition(move_mode, Float:CP[3], Float:FV[3], &Float:X, &Float:Y, &Float:Z)
{
    // Calculate the cameras next position based on their current position and the direction their camera is facing
    #define OFFSET_X (FV[0]*6000.0)
	#define OFFSET_Y (FV[1]*6000.0)
	#define OFFSET_Z (FV[2]*6000.0)
	switch(move_mode)
	{
		case MOVE_FORWARD:
		{
			X = CP[0]+OFFSET_X;
			Y = CP[1]+OFFSET_Y;
			Z = CP[2]+OFFSET_Z;
		}
		case MOVE_BACK:
		{
			X = CP[0]-OFFSET_X;
			Y = CP[1]-OFFSET_Y;
			Z = CP[2]-OFFSET_Z;
		}
		case MOVE_LEFT:
		{
			X = CP[0]-OFFSET_Y;
			Y = CP[1]+OFFSET_X;
			Z = CP[2];
		}
		case MOVE_RIGHT:
		{
			X = CP[0]+OFFSET_Y;
			Y = CP[1]-OFFSET_X;
			Z = CP[2];
		}
		case MOVE_BACK_LEFT:
		{
			X = CP[0]+(-OFFSET_X - OFFSET_Y);
 			Y = CP[1]+(-OFFSET_Y + OFFSET_X);
		 	Z = CP[2]-OFFSET_Z;
		}
		case MOVE_BACK_RIGHT:
		{
			X = CP[0]+(-OFFSET_X + OFFSET_Y);
 			Y = CP[1]+(-OFFSET_Y - OFFSET_X);
		 	Z = CP[2]-OFFSET_Z;
		}
		case MOVE_FORWARD_LEFT:
		{
			X = CP[0]+(OFFSET_X  - OFFSET_Y);
			Y = CP[1]+(OFFSET_Y  + OFFSET_X);
			Z = CP[2]+OFFSET_Z;
		}
		case MOVE_FORWARD_RIGHT:
		{
			X = CP[0]+(OFFSET_X  + OFFSET_Y);
			Y = CP[1]+(OFFSET_Y  - OFFSET_X);
			Z = CP[2]+OFFSET_Z;
		}
	}
}
//--------------------------------------------------

forward SetPosAfterFly(playerid, Float:X, Float:Y, Float:Z);
public SetPosAfterFly(playerid, Float:X, Float:Y, Float:Z)
{
	SetPlayerPos(playerid, X, Y, Z);
	return 1;
}

stock CancelFlyMode(playerid, bool:setpos = true)
{
	DeletePVar(playerid, "FlyMode");
	CancelEdit(playerid);
	new Float:X, Float:Y, Float:Z;
	GetPlayerCameraPos(playerid, X, Y, Z);
	TogglePlayerSpectating(playerid, false);
	if(setpos)
		SetTimerEx("SetPosAfterFly", 1000, false, "ifff", playerid, X, Y, Z);
	

	DestroyPlayerObject(playerid, noclipdata[playerid][flyobject]);
	noclipdata[playerid][cameramode] = CAMERA_MODE_NONE;
	return 1;
}

//--------------------------------------------------

stock FlyMode(playerid)
{
	// Create an invisible object for the players camera to be attached to
	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(playerid, X, Y, Z);
	noclipdata[playerid][flyobject] = CreatePlayerObject(playerid, 19300, X, Y, Z, 0.0, 0.0, 0.0);

	// Place the player in spectating mode so objects will be streamed based on camera location
	TogglePlayerSpectating(playerid, true);
	// Attach the players camera to the created object
	AttachCameraToPlayerObject(playerid, noclipdata[playerid][flyobject]);

	SetPVarInt(playerid, "FlyMode", 1);
	noclipdata[playerid][cameramode] = CAMERA_MODE_FLY;
	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}

//--------------------------------------------------

//--------------------------------------------------

stock MoveIt(playerid, Float:toX, Float:toY, Float:toZ)
{
    new Float:FV[3], Float:CP[3];
	GetPlayerCameraPos(playerid, CP[0], CP[1], CP[2]);          // 	Cameras position in space
    GetPlayerCameraFrontVector(playerid, FV[0], FV[1], FV[2]);  //  Where the camera is looking at

	// Increases the acceleration multiplier the longer the key is held
	if(noclipdata[playerid][accelmul] <= 1) noclipdata[playerid][accelmul] += ACCEL_RATE;

	// Determine the speed to move the camera based on the acceleration multiplier
	new Float:speed = MOVE_SPEED * noclipdata[playerid][accelmul];

	// Calculate the cameras next position based on their current position and the direction their camera is facing
	MovePlayerObject(playerid, noclipdata[playerid][flyobject], toX - 20.0, toY - 10.0, toZ + 40.0, speed + 1000.0);
	
	// Store the last time the camera was moved as now
	noclipdata[playerid][lastmove] = GetTickCount();
	return 1;
}

//--------------------------------------------------
