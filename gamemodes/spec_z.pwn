#include <a_samp>
#include <zcmd>
#include <foreach>
#include <sscanf2>

new pSpec[MAX_PLAYERS];
new pSpecBy[MAX_PLAYERS];

main()
{ }

public OnGameModeInit()
{
	ConnectNPC("npcidle","npcidle");
	SetGameModeText("specz");
	UsePlayerPedAnims();
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	SetTimer("onUpdateCall", 1000, true );
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
	return 1;
}

public OnPlayerConnect(playerid)
{
    pSpec[playerid] = INVALID_PLAYER_ID;
    pSpecBy[playerid] = INVALID_PLAYER_ID;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public OnPlayerSpawn(playerid)
{
    if(pSpecBy[playerid] != INVALID_PLAYER_ID )
	{
		cmd_pspecoff(pSpecBy[playerid],"");
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(pSpecBy[playerid] != INVALID_PLAYER_ID )
	{
		cmd_pspecoff(pSpecBy[playerid],"");
	}
	return 1;
}

CMD:pspec(playerid,params[])
{
	new id;
	if( sscanf(params,"i", id) ) return SendClientMessage(playerid,-1,"**pspec <id>");
	if( !IsPlayerConnected(id) ) return SendClientMessage( playerid, -1, "invalid player!");
	if( pSpec[id] != INVALID_PLAYER_ID ) return SendClientMessage( playerid, -1, "Playerid specing someone!");
	pSpec[playerid] = id;
	pSpecBy[id] = playerid;
	TogglePlayerSpectating( playerid, true );
	PlayerSpectatePlayer( playerid, pSpec[playerid], SPECTATE_MODE_FIXED );
	return 1;
}

CMD:pspecoff(playerid,params[])
{
	if( pSpec[playerid] == INVALID_PLAYER_ID ) return SendClientMessage(playerid,-1,"You are not specing anyone");
	pSpecBy[ pSpec[playerid] ] = INVALID_PLAYER_ID;
	pSpec[playerid] = INVALID_PLAYER_ID;
	pSpecBy[playerid] = INVALID_PLAYER_ID;
	TogglePlayerSpectating( playerid, false );
	return 1;
}

forward onUpdateCall();
public onUpdateCall()
{
	foreach(new i:Character)
	{
	    if( pSpecBy[ i ] != INVALID_PLAYER_ID )
	    {
	    	new armid = GetPlayerWeapon(i);
	    	if( armid == 34 ) // sniper
	    	{
            	new Float: zoom = GetPlayerCameraZoom(i);
            	
            	if( zoom > 0.0 )
            	{
	    	    	new specid = pSpecBy[ i ];
	    	    
            	    new string[64] , Float: aspratio;
            	    aspratio = GetPlayerCameraAspectRatio(i);
            	    format(string,sizeof(string),"** %0.1f Zoom || %0.1f Ratio.",zoom, aspratio );
            	    SendClientMessage( specid, -1, string);
	            	new Float: px, Float: py, Float: pz;
	            	GetPlayerPos( i, px, py, pz );

	            	px = px * zoom;
	            	py = py * zoom;

	            	SetPlayerCameraPos( specid, px, py, pz );
            	}
	    	}
		}
		new armid = GetPlayerWeapon(i);
		
    	if( armid == 34 && GetPlayerCameraMode(i) == 7) // sniper
    	{
        	new Float: zoom = GetPlayerCameraZoom(i);

        	if( zoom > 0.0 )
        	{
    	    //	new specid = pSpecBy[ i ];

        	    new string[64] , Float: aspratio;
        	    aspratio = GetPlayerCameraAspectRatio(i);
        	    format(string,sizeof(string),"** %f Zoom || %f Ratio. || ",zoom, aspratio );
        	    SendClientMessage( i, -1, string);
            	new Float: px, Float: py, Float: pz;
            	GetPlayerCameraPos( i, px, py, pz );
            	format(string,sizeof(string),"** %f , %f ,%f ",px,py,pz );
        	    SendClientMessage( i, -1, string);

            	/* px = px * zoom;
            	py = py * zoom;

            	SetPlayerCameraPos( specid, px, py, pz );   */
        	}
    	}
	}
}













