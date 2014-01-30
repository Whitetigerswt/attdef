/*
////////////////////////////////////////////////////////////
//========================================================//
//== New Player Callbacks include made by BigETI © 2011 ==//
//========================================================//
//== You are not allowed to edit this include ============//
//== and/or release it without my permissions! ===========//
//========================================================//
//== File name: ncbs.inc =================================//
//== Autor: Ethem Kurt © =================================//
//== Release Date: 29.10.2011 ============================//
//== Version: V1.5 =======================================//
//== Lines: 874 ==========================================//
//== File size: 39 KB ====================================//
//========================================================//
////////////////////////////////////////////////////////////

||=====================================================================================================================================================||
||	IMPORTANT: Define FILTERSCRIPT on top of your script to verify if you are yousing a filterscript or a gamemode!                                    ||
||	If you want to call the callbacks at another scripts, so you have to use ncbs_forwards.inc at another scripts to make the callbacks usable there.  ||
||=====================================================================================================================================================||
*/

//Do not edit those things below!
#include <a_samp>
#if defined _BIGETI_NEW_PLAYER_CALLBACKS
	#endinput
#endif
#define	_BIGETI_NEW_PLAYER_CALLBACKS
#if defined _BIGETI_NPCBS_FORWARDS
	#error Do not use ncbs.inc and ncbs_forwards.inc in one script.
	#endinput
#endif
#include <ncbs_defines>
#pragma library					ncbs
#define MAX_WEAPON_SLOTS		13
#define INVALID_WEAPON_SLOT_ID	-1
#if defined USE_PLAYER_CALLBACKS
enum CallBack_Infos
{
	nCallBack_VehicleID,
	nCallBack_VehicleSeat,
	nCallBack_Skin,
	nCallBack_HoldWeapon,
	nCallBack_WeaponState,
	nCallBack_Weapon[MAX_WEAPON_SLOTS],
	nCallBack_Ammo[MAX_WEAPON_SLOTS],
	nCallBack_Money,
	Float:nCallBack_Health,
	Float:nCallBack_Armour,
	nCallBack_Animation,
	nCallBack_Target,
	nCallBack_SpecialAction,
	nCallBack_KeyY,
	nCallBack_KeyX,
	Float:nCallBack_X,
	Float:nCallBack_Y,
	Float:nCallBack_Z,
	Float:nCallBack_VehicleHealth,
	bool:nCallBack_KickedBanned,
	nCallBack_OPUTime,
};
new pCallBack_Info[MAX_PLAYERS][CallBack_Infos], OPC_CallBack, OPDC_CallBack, OPSC_CallBack, OPU_CallBack
	#if defined CB_OnPlayerEnteredVehicle
, OPEnV_CallBack
	#endif
	#if defined CB_OnPlayerExitedVehicle
, OPExV_CallBack
	#endif
	#if defined CB_OnPlayerSkinChange
, OPSkC_CallBack
	#endif
	#if defined CB_OnPlayerHoldWeaponChange
, OPHWC_CallBack
	#endif
	#if defined CB_OnPlayerWeaponStateChange
, OPWSC_CallBack
	#endif
	#if defined CB_OnPlayerWeaponDataChange
, OPWDC_CallBack
	#endif
	#if defined CB_OnPlayerAmmoDataChange
, OPADC_CallBack
	#endif
	#if defined CB_OnPlayerMoneyChange
, OPMC_CallBack
	#endif
	#if defined CB_OnPlayerHealthChange
, OPHC_CallBack
	#endif
	#if defined CB_OnPlayerArmourChange
, OPAC_CallBack
	#endif
	#if defined CB_OnPlayerAnimationIndexChange
, OPAIC_CallBack
	#endif
	#if defined CB_OnPlayerTargetPlayer
, OPTP_CallBack
	#endif
	#if defined CB_OnPlayerSpecialActionChange
, OPSAC_CallBack
	#endif
	#if defined CB_OnPlayerAnalogKeysChange
, OPAKC_CallBack
	#endif
	#if defined CB_OnPlayerXYZChange
, OPXYZC_CallBack
	#endif
	#if defined CB_OnPlayerVehicleHealthChange
, OPVHC_CallBack
	#endif
	#if defined CB_OnPlayerVirtualWorldChange
, OPVWC_CallBack
	#endif
;
#endif
#if defined USE_PVAR_CALLBACKS
	#if defined CB_OnPVarDelete
new OPVarD_CallBack;
	#endif
	#if defined CB_OnPVarCreate
new OPVarC_CallBack;
	#endif
	#if defined CB_OnPVarTypeChange
new OPVarTC_CallBack;
	#endif
	#if defined CB_OnPVarIntChange
new OPVarIC_CallBack;
	#endif
	#if defined CB_OnPVarStringChange
new OPVarSC_CallBack;
	#endif
	#if defined CB_OnPVarFloatChange
new OPVarFC_CallBack;
	#endif
#endif
#if defined USE_PLAYER_CALLBACKS
	#define ETI_ReturnOPC(%0) ((OPC_CallBack != -1) ? CallLocalFunction("ETI_OnPlayerConnect", %0) : 1)
	#define ETI_ReturnOPDC(%0) ((OPDC_CallBack != -1) ? CallLocalFunction("ETI_OnPlayerDisconnect", %0) : 1)
	#define ETI_ReturnOPSC(%0) ((OPSC_CallBack != -1) ? CallLocalFunction("ETI_OnPlayerStateChange", %0) : 1)
	#define ETI_ReturnOPU(%0) ((OPU_CallBack != -1) ? CallLocalFunction("ETI_OnPlayerUpdate", %0) : 1)
#endif
#if defined FILTERSCRIPT
public OnFilterScriptInit()
{
#else
public OnGameModeInit()
{
#endif
#if defined USE_PLAYER_CALLBACKS
	OPC_CallBack = funcidx("OnPlayerConnect");
	OPDC_CallBack = funcidx("OnPlayerDisconnect");
	OPSC_CallBack = funcidx("OnPlayerStateChange");
	OPU_CallBack = funcidx("OnPlayerUpdate");
	#if defined CB_OnPlayerEnteredVehicle
	OPEnV_CallBack = funcidx("OnPlayerEnteredVehicle");
	#endif
	#if defined CB_OnPlayerExitedVehicle
	OPExV_CallBack = funcidx("OnPlayerExitedVehicle");
	#endif
	#if defined CB_OnPlayerSkinChange
	OPSkC_CallBack = funcidx("OnPlayerSkinChange");
	#endif
	#if defined CB_OnPlayerHoldWeaponChange
	OPHWC_CallBack = funcidx("OnPlayerHoldWeaponChange");
	#endif
	#if defined CB_OnPlayerWeaponStateChange
	OPWSC_CallBack = funcidx("OnPlayerWeaponStateChange");
	#endif
	#if defined CB_OnPlayerWeaponDataChange
	OPWDC_CallBack = funcidx("OnPlayerWeaponDataChange");
	#endif
	#if defined CB_OnPlayerAmmoDataChange
	OPADC_CallBack = funcidx("OnPlayerAmmoDataChange");
	#endif
	#if defined CB_OnPlayerMoneyChange
	OPMC_CallBack = funcidx("OnPlayerMoneyChange");
	#endif
	#if defined CB_OnPlayerHealthChange
	OPHC_CallBack = funcidx("OnPlayerHealthChange");
	#endif
	#if defined CB_OnPlayerArmourChange
	OPAC_CallBack = funcidx("OnPlayerArmourChange");
	#endif
	#if defined CB_OnPlayerAnimationIndexChange
	OPAIC_CallBack = funcidx("OnPlayerAnimationIndexChange");
	#endif
	#if defined CB_OnPlayerTargetPlayer
	OPTP_CallBack = funcidx("OnPlayerTargetPlayer");
	#endif
	#if defined CB_OnPlayerSpecialActionChange
	OPSAC_CallBack = funcidx("OnPlayerSpecialActionChange");
	#endif
	#if defined CB_OnPlayerAnalogKeysChange
	OPAKC_CallBack = funcidx("OnPlayerAnalogKeysChange");
	#endif
	#if defined CB_OnPlayerXYZChange
	OPXYZC_CallBack = funcidx("OnPlayerXYZChange");
	#endif
	#if defined CB_OnPlayerVehicleHealthChange
	OPVHC_CallBack = funcidx("OnPlayerVehicleHealthChange");
	#endif
	#if defined CB_OnPlayerVirtualWorldChange
	OPVWC_CallBack = funcidx("OnPlayerVirtualWorldChange");
	#endif
#endif
#if defined USE_PVAR_CALLBACKS
	#if defined CB_OnPVarDelete
	OPVarD_CallBack = funcidx("OnPVarDelete");
	#endif
	#if defined CB_OnPVarCreate
	OPVarC_CallBack = funcidx("OnPVarCreate");
	#endif
	#if defined CB_OnPVarTypeChange
	OPVarTC_CallBack = funcidx("OnPVarTypeChange");
	#endif
	#if defined CB_OnPVarIntChange
	OPVarIC_CallBack = funcidx("OnPVarIntChange");
	#endif
	#if defined CB_OnPVarStringChange
	OPVarSC_CallBack = funcidx("OnPVarStringChange");
	#endif
	#if defined CB_OnPVarFloatChange
	OPVarFC_CallBack = funcidx("OnPVarFloatChange");
	#endif
#endif
#if defined FILTERSCRIPT
	return (funcidx("ETI_OnFilterScriptInit") != -1) ? CallLocalFunction("ETI_OnFilterScriptInit","") : 1;
#else
	return (funcidx("ETI_OnGameModeInit") != -1) ? CallLocalFunction("ETI_OnGameModeInit","") : 1;
#endif
}
#if defined FILTERSCRIPT
	#if defined _ALS_OnFilterScriptInit
		#undef OnFilterScriptInit
	#else
		#define _ALS_OnFilterScriptInit
	#endif
	#define OnFilterScriptInit ETI_OnFilterScriptInit
forward ETI_OnFilterScriptInit();
#else
	#if defined _ALS_OnGameModeInit
		#undef OnGameModeInit
	#else
		#define _ALS_OnGameModeInit
	#endif
	#define OnGameModeInit ETI_OnGameModeInit
forward ETI_OnGameModeInit();
#endif
#if defined USE_PLAYER_CALLBACKS
	#if defined CB_OnPlayerEnteredVehicle
forward OnPlayerEnteredVehicle(playerid, vehicleid, seatid);
	#endif
	#if defined CB_OnPlayerExitedVehicle
forward OnPlayerExitedVehicle(playerid, vehicleid);
	#endif
	#if defined CB_OnPlayerSkinChange
forward OnPlayerSkinChange(playerid, oldskin, newskin);
	#endif
	#if defined CB_OnPlayerHoldWeaponChange
forward OnPlayerHoldWeaponChange(playerid, oldslot, oldweapon, newslot, newweapon);
	#endif
	#if defined CB_OnPlayerWeaponStateChange
forward OnPlayerWeaponStateChange(playerid, oldstate, newstate);
	#endif
	#if defined USE_WEAPON_DATA_CALLBACKS
		#if defined CB_OnPlayerWeaponDataChange
forward OnPlayerWeaponDataChange(playerid, slot, oldweapon, newweapon);
		#endif
		#if defined CB_OnPlayerAmmoDataChange
forward OnPlayerAmmoDataChange(playerid, slot, oldammo, newammo);
		#endif
	#endif
	#if defined CB_OnPlayerMoneyChange
forward OnPlayerMoneyChange(playerid, oldmoney, newmoney);
	#endif
	#if defined CB_OnPlayerHealthChange
forward OnPlayerHealthChange(playerid, Float:oldhealth, Float:newhealth);
	#endif
	#if defined CB_OnPlayerArmourChange
forward OnPlayerArmourChange(playerid, Float:oldarmour, Float:newarmour);
	#endif
	#if defined CB_OnPlayerAnimationIndexChange
forward OnPlayerAnimationIndexChange(playerid, oldindex, newindex);
	#endif
	#if defined CB_OnPlayerTargetPlayer
forward OnPlayerTargetPlayer(playerid, oldtarget, newtarget, bool:istargeting);
	#endif
	#if defined CB_OnPlayerSpecialActionChange
forward OnPlayerSpecialActionChange(playerid, oldsaction, newsaction);
	#endif
	#if defined CB_OnPlayerAnalogKeysChange
forward OnPlayerAnalogKeysChange(playerid, oldy, newy, oldx, newx);
	#endif
	#if defined CB_OnPlayerXYZChange
forward OnPlayerXYZChange(playerid, Float:oldx, Float:oldy, Float:oldz, Float:newx, Float:newy, Float:newz);
	#endif
	#if defined CB_OnPlayerVehicleHealthChange
forward OnPlayerVehicleHealthChange(playerid, vehicleid, Float:oldhealth, Float:newhealth, bool:isissuer);
	#endif
	#if defined CB_OnPlayerVirtualWorldChange
forward OnPlayerVirtualWorldChange(playerid, oldworld, newworld);
	#endif
	#if !defined _ETI_GetWeaponSlot
		#define _ETI_GetWeaponSlot
stock ETI_GetWeaponSlot(weaponid)
{
    new slot;
	switch(weaponid)
	{
		case 0,1: slot = 0;
		case 2..9: slot = 1;
		case 22..24: slot = 2;
		case 25..27: slot = 3;
		case 28,29,32: slot = 4;
		case 30,31: slot = 5;
		case 33,34: slot = 6;
		case 35..38: slot = 7;
		case 16..18,39: slot = 8;
		case 41..43: slot = 9;
		case 10..15: slot = 10;
		case 44..46: slot = 11;
		case 40: slot = 12;
		default: slot = INVALID_WEAPON_SLOT_ID;
	}
	return slot;
}
	#endif
public OnPlayerConnect(playerid)
{
	#if defined CB_OnPlayerHealthChange
	pCallBack_Info[playerid][nCallBack_Health] = 100.0;
	#endif
	#if defined CB_OnPlayerTargetPlayer
	pCallBack_Info[playerid][nCallBack_Target] = INVALID_PLAYER_ID;
	#endif
	#if defined CB_OnPlayerVehicleHealthChange
	pCallBack_Info[playerid][nCallBack_VehicleHealth] = 1000.0;
	#endif
	#if defined CB_OnPlayerEnteredVehicle
	pCallBack_Info[playerid][nCallBack_VehicleSeat] = -1;
	#elseif defined CB_OnPlayerExitedVehicle
	pCallBack_Info[playerid][nCallBack_VehicleSeat] = -1;
	#endif
	pCallBack_Info[playerid][nCallBack_KickedBanned] = false;
	return ETI_ReturnOPC("d", playerid);
}
	#if defined _ALS_OnPlayerConnect
		#undef OnPlayerConnect
	#else
		#define _ALS_OnPlayerConnect
	#endif
	#define OnPlayerConnect ETI_OnPlayerConnect
forward ETI_OnPlayerConnect(playerid);
public OnPlayerDisconnect(playerid, reason)
{
	#if defined CB_OnPlayerEnteredVehicle
	pCallBack_Info[playerid][nCallBack_VehicleID] = 0;
	pCallBack_Info[playerid][nCallBack_VehicleSeat] = 0;
	#elseif defined CB_OnPlayerExitedVehicle
	pCallBack_Info[playerid][nCallBack_VehicleID] = 0;
	pCallBack_Info[playerid][nCallBack_VehicleSeat] = 0;
	#endif
	#if defined CB_OnPlayerSkinChange
	pCallBack_Info[playerid][nCallBack_Skin] = 0;
	#endif
	#if defined CB_OnPlayerWeaponChange
	pCallBack_Info[playerid][nCallBack_HoldWeapon] = 0;
	#endif
	#if defined CB_OnPlayerWeaponStateChange
	pCallBack_Info[playerid][nCallBack_WeaponState] = 0;
	#endif
	#if defined USE_WEAPON_DATA_CALLBACKS
	for(new i = 0; i < MAX_WEAPON_SLOTS; i++)
	{
		#if defined CB_OnPlayerWeaponDataChange
		pCallBack_Info[playerid][nCallBack_Weapon][i] = 0;
		#endif
		#if defined CB_OnPlayerAmmoDataChange
		pCallBack_Info[playerid][nCallBack_Ammo][i] = 0;
		#endif
	}
	#endif
	#if defined CB_OnPlayerMoneyChange
	pCallBack_Info[playerid][nCallBack_Money] = 0;
	#endif
	#if defined CB_OnPlayerHealthChange
	pCallBack_Info[playerid][nCallBack_Health] = 0.0;
	#endif
	#if defined CB_OnPlayerArmourChange
	pCallBack_Info[playerid][nCallBack_Armour] = 0.0;
	#endif
	#if defined CB_OnPlayerAnimationIndexChange
	pCallBack_Info[playerid][nCallBack_Animation] = 0;
	#endif
	#if defined CB_OnPlayerTargetPlayer
	pCallBack_Info[playerid][nCallBack_Target] = 0;
	#endif
	#if defined CB_OnPlayerSpecialActionChange
	pCallBack_Info[playerid][nCallBack_SpecialAction] = 0;
	#endif
	#if defined CB_OnPlayerVehicleHealthChange
	pCallBack_Info[playerid][nCallBack_VehicleHealth] = 0.0;
	#endif
	#if defined CB_OnPlayerAnalogKeysChange
	pCallBack_Info[playerid][nCallBack_KeyY] = 0;
	pCallBack_Info[playerid][nCallBack_KeyX] = 0;
	#endif
	#if defined CB_OnPlayerXYZChange
	pCallBack_Info[playerid][nCallBack_X] = 0.0;
	pCallBack_Info[playerid][nCallBack_Y] = 0.0;
	pCallBack_Info[playerid][nCallBack_Z] = 0.0;
	#endif
	return ETI_ReturnOPDC("dd", playerid, reason);
}
	#if defined _ALS_OnPlayerDisconnect
		#undef OnPlayerDisconnect
	#else
		#define _ALS_OnPlayerDisconnect
	#endif
	#define OnPlayerDisconnect ETI_OnPlayerDisconnect
forward ETI_OnPlayerDisconnect(playerid, reason);
public OnPlayerStateChange(playerid, newstate, oldstate)
{
	new OPSC_VehicleID = GetPlayerVehicleID(playerid), OPSC_VehicleSeat = GetPlayerVehicleSeat(playerid);
	#if defined CB_OnPlayerEnteredVehicle
	if((newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER) && (oldstate != PLAYER_STATE_DRIVER && oldstate != PLAYER_STATE_PASSENGER))
	{
		GetVehicleHealth(pCallBack_Info[playerid][nCallBack_VehicleID], pCallBack_Info[playerid][nCallBack_VehicleHealth]);
		#if defined USE_IN_ALL_SCRIPTS
		if(((OPEnV_CallBack != -1) ? CallRemoteFunction("OnPlayerEnteredVehicle", "ddd", playerid, OPSC_VehicleID, OPSC_VehicleSeat) : 1))
		#else
		if(((OPEnV_CallBack != -1) ? CallLocalFunction("OnPlayerEnteredVehicle", "ddd", playerid, OPSC_VehicleID, OPSC_VehicleSeat) : 1))
		#endif
		{
			pCallBack_Info[playerid][nCallBack_VehicleID] = OPSC_VehicleID;
			pCallBack_Info[playerid][nCallBack_VehicleSeat] = OPSC_VehicleSeat;
		}
	}
		#if defined CB_OnPlayerExitedVehicle
	else
		#endif
	#endif
	#if defined CB_OnPlayerExitedVehicle
	if((newstate != PLAYER_STATE_DRIVER && newstate != PLAYER_STATE_PASSENGER) && (oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER))
	{
		pCallBack_Info[playerid][nCallBack_VehicleHealth] = 1000.0;
		#if defined USE_IN_ALL_SCRIPTS
		if(((OPExV_CallBack != -1) ? CallRemoteFunction("OnPlayerExitedVehicle", "dd", playerid, pCallBack_Info[playerid][nCallBack_VehicleID]) : 1))
		#else
		if(((OPExV_CallBack != -1) ? CallLocalFunction("OnPlayerExitedVehicle", "dd", playerid, pCallBack_Info[playerid][nCallBack_VehicleID]) : 1))
		#endif
		{
			pCallBack_Info[playerid][nCallBack_VehicleID] = 0;
			pCallBack_Info[playerid][nCallBack_VehicleSeat] = -1;
		}
	}
	#endif
	return ETI_ReturnOPSC("ddd", playerid, newstate, oldstate);
}
	#if defined _ALS_OnPlayerStateChange
		#undef OnPlayerStateChange
	#else
		#define _ALS_OnPlayerStateChange
	#endif
	#define OnPlayerStateChange ETI_OnPlayerStateChange
forward ETI_OnPlayerStateChange(playerid, newstate, oldstate);
public OnPlayerUpdate(playerid)
{
	if(pCallBack_Info[playerid][nCallBack_KickedBanned]) return ETI_ReturnOPU("d", playerid);
	new update_Variable[CallBack_Infos];
	#if defined USE_OPU_DELAY
		#if defined USE_OPU_SECONDS
	update_Variable[nCallBack_OPUTime] = gettime();
		#else
	update_Variable[nCallBack_OPUTime] = GetTickCount();
		#endif
	if(pCallBack_Info[playerid][nCallBack_OPUTime]+ADD_OPU_DELAY >= update_Variable[nCallBack_OPUTime]) return ETI_ReturnOPU("d", playerid);
	pCallBack_Info[playerid][nCallBack_OPUTime] = update_Variable[nCallBack_OPUTime];
	#endif
	#if defined CB_OnPlayerSkinChange
	update_Variable[nCallBack_Skin] = GetPlayerSkin(playerid);
		#if defined USE_IN_ALL_SCRIPTS
	if(pCallBack_Info[playerid][nCallBack_Skin] != update_Variable[nCallBack_Skin] && ((OPSkC_CallBack != -1) ? CallRemoteFunction("OnPlayerSkinChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_Skin], update_Variable[nCallBack_Skin]) : 1))
		#else
	if(pCallBack_Info[playerid][nCallBack_Skin] != update_Variable[nCallBack_Skin] && ((OPSkC_CallBack != -1) ? CallLocalFunction("OnPlayerSkinChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_Skin], update_Variable[nCallBack_Skin]) : 1))
		#endif
		pCallBack_Info[playerid][nCallBack_Skin] = update_Variable[nCallBack_Skin];
	#endif
	#if defined CB_OnPlayerHoldWeaponChange
	update_Variable[nCallBack_HoldWeapon] = GetPlayerWeapon(playerid);
		#if defined USE_IN_ALL_SCRIPTS
	if(pCallBack_Info[playerid][nCallBack_HoldWeapon] != update_Variable[nCallBack_HoldWeapon] && ((OPHWC_CallBack != -1) ? CallRemoteFunction("OnPlayerHoldWeaponChange", "ddddd", playerid, ETI_GetWeaponSlot(pCallBack_Info[playerid][nCallBack_HoldWeapon]), pCallBack_Info[playerid][nCallBack_HoldWeapon], ETI_GetWeaponSlot(update_Variable[nCallBack_HoldWeapon]), update_Variable[nCallBack_HoldWeapon]) : 1))
		#else
	if(pCallBack_Info[playerid][nCallBack_HoldWeapon] != update_Variable[nCallBack_HoldWeapon] && ((OPHWC_CallBack != -1) ? CallLocalFunction("OnPlayerHoldWeaponChange", "ddddd", playerid, ETI_GetWeaponSlot(pCallBack_Info[playerid][nCallBack_HoldWeapon]), pCallBack_Info[playerid][nCallBack_HoldWeapon], ETI_GetWeaponSlot(update_Variable[nCallBack_HoldWeapon]), update_Variable[nCallBack_HoldWeapon]) : 1))
		#endif
		pCallBack_Info[playerid][nCallBack_HoldWeapon] = update_Variable[nCallBack_HoldWeapon];
	#endif
	#if defined CB_OnPlayerWeaponStateChange
	update_Variable[nCallBack_WeaponState] = GetPlayerWeaponState(playerid);
		#if defined USE_IN_ALL_SCRIPTS
	if(pCallBack_Info[playerid][nCallBack_WeaponState] != update_Variable[nCallBack_WeaponState] && ((OPWSC_CallBack != -1) ? CallRemoteFunction("OnPlayerWeaponStateChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_WeaponState], update_Variable[nCallBack_WeaponState]) : 1))
		#else
	if(pCallBack_Info[playerid][nCallBack_WeaponState] != update_Variable[nCallBack_WeaponState] && ((OPWSC_CallBack != -1) ? CallLocalFunction("OnPlayerWeaponStateChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_WeaponState], update_Variable[nCallBack_WeaponState]) : 1))
		#endif
		pCallBack_Info[playerid][nCallBack_WeaponState] = update_Variable[nCallBack_WeaponState];
	#endif
	#if defined USE_WEAPON_DATA_CALLBACKS
	for(new i = 0; i < MAX_WEAPON_SLOTS; i++)
	{
		GetPlayerWeaponData(playerid, i, update_Variable[nCallBack_Weapon][i], update_Variable[nCallBack_Ammo][i]);
		#if defined CB_OnPlayerWeaponDataChange
			#if defined USE_IN_ALL_SCRIPTS
		if(pCallBack_Info[playerid][nCallBack_Weapon][i] != update_Variable[nCallBack_Weapon][i] && ((OPWDC_CallBack != -1) ? CallRemoteFunction("OnPlayerWeaponDataChange", "dddd", playerid, i, pCallBack_Info[playerid][nCallBack_Weapon][i], update_Variable[nCallBack_Weapon][i]) : 1))
			#else
		if(pCallBack_Info[playerid][nCallBack_Weapon][i] != update_Variable[nCallBack_Weapon][i] && ((OPWDC_CallBack != -1) ? CallLocalFunction("OnPlayerWeaponDataChange", "dddd", playerid, i, pCallBack_Info[playerid][nCallBack_Weapon][i], update_Variable[nCallBack_Weapon][i]) : 1))
			#endif
			pCallBack_Info[playerid][nCallBack_Weapon][i] = update_Variable[nCallBack_Weapon][i];
		#endif
		#if defined CB_OnPlayerAmmoDataChange
			#if defined USE_IN_ALL_SCRIPTS
		if(pCallBack_Info[playerid][nCallBack_Ammo][i] != update_Variable[nCallBack_Ammo][i] && ((OPADC_CallBack != -1) ? CallRemoteFunction("OnPlayerAmmoDataChange", "dddd", playerid, i, pCallBack_Info[playerid][nCallBack_Ammo][i], update_Variable[nCallBack_Ammo][i]) : 1))
			#else
		if(pCallBack_Info[playerid][nCallBack_Ammo][i] != update_Variable[nCallBack_Ammo][i] && ((OPADC_CallBack != -1) ? CallLocalFunction("OnPlayerAmmoDataChange", "dddd", playerid, i, pCallBack_Info[playerid][nCallBack_Ammo][i], update_Variable[nCallBack_Ammo][i]) : 1))
			#endif
			pCallBack_Info[playerid][nCallBack_Ammo][i] = update_Variable[nCallBack_Ammo][i];
		#endif
	}
	#endif
	#if defined CB_OnPlayerMoneyChange
	update_Variable[nCallBack_Money] = GetPlayerMoney(playerid);
		#if defined USE_IN_ALL_SCRIPTS
	if(pCallBack_Info[playerid][nCallBack_Money] != update_Variable[nCallBack_Money] && ((OPMC_CallBack != -1) ? CallRemoteFunction("OnPlayerMoneyChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_Money], update_Variable[nCallBack_Money]) : 1))
		#else
	if(pCallBack_Info[playerid][nCallBack_Money] != update_Variable[nCallBack_Money] && ((OPMC_CallBack != -1) ? CallLocalFunction("OnPlayerMoneyChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_Money], update_Variable[nCallBack_Money]) : 1))
		#endif
		pCallBack_Info[playerid][nCallBack_Money] = update_Variable[nCallBack_Money];
	#endif
	#if defined CB_OnPlayerHealthChange
	GetPlayerHealth(playerid, update_Variable[nCallBack_Health]);
		#if defined USE_IN_ALL_SCRIPTS
	if(pCallBack_Info[playerid][nCallBack_Health] != update_Variable[nCallBack_Health] && ((OPHC_CallBack != -1) ? CallRemoteFunction("OnPlayerHealthChange", "dff", playerid, pCallBack_Info[playerid][nCallBack_Health], update_Variable[nCallBack_Health]) : 1))
		#else
	if(pCallBack_Info[playerid][nCallBack_Health] != update_Variable[nCallBack_Health] && ((OPHC_CallBack != -1) ? CallLocalFunction("OnPlayerHealthChange", "dff", playerid, pCallBack_Info[playerid][nCallBack_Health], update_Variable[nCallBack_Health]) : 1))
		#endif
		pCallBack_Info[playerid][nCallBack_Health] = update_Variable[nCallBack_Health];
	#endif
	#if defined CB_OnPlayerArmourChange
	GetPlayerArmour(playerid, update_Variable[nCallBack_Armour]);
		#if defined USE_IN_ALL_SCRIPTS
	if(pCallBack_Info[playerid][nCallBack_Armour] != update_Variable[nCallBack_Armour] && ((OPAC_CallBack != -1) ? CallRemoteFunction("OnPlayerArmourChange", "dff", playerid, pCallBack_Info[playerid][nCallBack_Armour], update_Variable[nCallBack_Armour]) : 1))
		#else
	if(pCallBack_Info[playerid][nCallBack_Armour] != update_Variable[nCallBack_Armour] && ((OPAC_CallBack != -1) ? CallLocalFunction("OnPlayerArmourChange", "dff", playerid, pCallBack_Info[playerid][nCallBack_Armour], update_Variable[nCallBack_Armour]) : 1))
		#endif
		pCallBack_Info[playerid][nCallBack_Armour] = update_Variable[nCallBack_Armour];
	#endif
	#if defined CB_OnPlayerAnimationIndexChange
	update_Variable[nCallBack_Animation] = GetPlayerAnimationIndex(playerid);
		#if defined USE_IN_ALL_SCRIPTS
	if(pCallBack_Info[playerid][nCallBack_Animation] != update_Variable[nCallBack_Animation] && ((OPAIC_CallBack != -1) ? CallRemoteFunction("OnPlayerAnimationIndexChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_Animation], update_Variable[nCallBack_Animation]) : 1))
		#else
	if(pCallBack_Info[playerid][nCallBack_Animation] != update_Variable[nCallBack_Animation] && ((OPAIC_CallBack != -1) ? CallLocalFunction("OnPlayerAnimationIndexChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_Animation], update_Variable[nCallBack_Animation]) : 1))
		#endif
		pCallBack_Info[playerid][nCallBack_Animation] = update_Variable[nCallBack_Animation];
	#endif
	#if defined CB_OnPlayerTargetPlayer
	update_Variable[nCallBack_Target] = GetPlayerTargetPlayer(playerid);
		#if defined USE_IN_ALL_SCRIPTS
	if(pCallBack_Info[playerid][nCallBack_Target] != update_Variable[nCallBack_Target] && ((OPTP_CallBack != -1) ? CallRemoteFunction("OnPlayerTargetPlayer", "dddl", playerid, pCallBack_Info[playerid][nCallBack_Target], update_Variable[nCallBack_Target], (update_Variable[nCallBack_Target] != INVALID_PLAYER_ID ? true : false)) : 1))
		#else
	if(pCallBack_Info[playerid][nCallBack_Target] != update_Variable[nCallBack_Target] && ((OPTP_CallBack != -1) ? CallLocalFunction("OnPlayerTargetPlayer", "dddl", playerid, pCallBack_Info[playerid][nCallBack_Target], update_Variable[nCallBack_Target], (update_Variable[nCallBack_Target] != INVALID_PLAYER_ID ? true : false)) : 1))
		#endif
		pCallBack_Info[playerid][nCallBack_Target] = update_Variable[nCallBack_Target];
	#endif
	#if defined CB_OnPlayerSpecialActionChange
	update_Variable[nCallBack_SpecialAction] = GetPlayerSpecialAction(playerid);
		#if defined USE_IN_ALL_SCRIPTS
	if(pCallBack_Info[playerid][nCallBack_SpecialAction] != update_Variable[nCallBack_SpecialAction] && ((OPSAC_CallBack != -1) ? CallRemoteFunction("OnPlayerSpecialActionChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_SpecialAction], update_Variable[nCallBack_SpecialAction]) : 1))
		#else
	if(pCallBack_Info[playerid][nCallBack_SpecialAction] != update_Variable[nCallBack_SpecialAction] && ((OPSAC_CallBack != -1) ? CallLocalFunction("OnPlayerSpecialActionChange", "ddd", playerid, pCallBack_Info[playerid][nCallBack_SpecialAction], update_Variable[nCallBack_SpecialAction]) : 1))
		#endif
		pCallBack_Info[playerid][nCallBack_SpecialAction] = update_Variable[nCallBack_SpecialAction];
	#endif
	#if defined CB_OnPlayerAnalogKeysChange
	new dumpkeys;
	GetPlayerKeys(playerid, dumpkeys, update_Variable[nCallBack_KeyY], update_Variable[nCallBack_KeyX]);
	#pragma unused dumpkeys
		#if defined USE_IN_ALL_SCRIPTS
	if((pCallBack_Info[playerid][nCallBack_KeyY] != update_Variable[nCallBack_KeyY] || pCallBack_Info[playerid][nCallBack_KeyX] != update_Variable[nCallBack_KeyX]) && ((OPAKC_CallBack != -1) ? CallRemoteFunction("OnPlayerAnalogKeysChange", "ddddd", playerid, pCallBack_Info[playerid][nCallBack_KeyY], update_Variable[nCallBack_KeyY], pCallBack_Info[playerid][nCallBack_KeyX], update_Variable[nCallBack_KeyX]) : 1))
		#else
	if((pCallBack_Info[playerid][nCallBack_KeyY] != update_Variable[nCallBack_KeyY] || pCallBack_Info[playerid][nCallBack_KeyX] != update_Variable[nCallBack_KeyX]) && ((OPAKC_CallBack != -1) ? CallLocalFunction("OnPlayerAnalogKeysChange", "ddddd", playerid, pCallBack_Info[playerid][nCallBack_KeyY], update_Variable[nCallBack_KeyY], pCallBack_Info[playerid][nCallBack_KeyX], update_Variable[nCallBack_KeyX]) : 1))
		#endif
	{
		pCallBack_Info[playerid][nCallBack_KeyY] = update_Variable[nCallBack_KeyY];
		pCallBack_Info[playerid][nCallBack_KeyX] = update_Variable[nCallBack_KeyX];
	}
	#endif
	#if defined CB_OnPlayerXYZChange
	GetPlayerPos(playerid, update_Variable[nCallBack_X], update_Variable[nCallBack_Y], update_Variable[nCallBack_Z]);
		#if defined USE_IN_ALL_SCRIPTS
	if((pCallBack_Info[playerid][nCallBack_X] != update_Variable[nCallBack_X] || pCallBack_Info[playerid][nCallBack_Y] != update_Variable[nCallBack_Y] || update_Variable[nCallBack_X] || pCallBack_Info[playerid][nCallBack_Z] != update_Variable[nCallBack_Z]) &&
	((OPXYZC_CallBack != -1) ? CallRemoteFunction("OnPlayerXYZChange", "dffffff", playerid, pCallBack_Info[playerid][nCallBack_X], pCallBack_Info[playerid][nCallBack_Y], pCallBack_Info[playerid][nCallBack_Z], update_Variable[nCallBack_X], update_Variable[nCallBack_Y], update_Variable[nCallBack_Z]) : 1))
		#else
	if((pCallBack_Info[playerid][nCallBack_X] != update_Variable[nCallBack_X] || pCallBack_Info[playerid][nCallBack_Y] != update_Variable[nCallBack_Y] || update_Variable[nCallBack_X] || pCallBack_Info[playerid][nCallBack_Z] != update_Variable[nCallBack_Z]) &&
	((OPXYZC_CallBack != -1) ? CallLocalFunction("OnPlayerXYZChange", "dffffff", playerid, pCallBack_Info[playerid][nCallBack_X], pCallBack_Info[playerid][nCallBack_Y], pCallBack_Info[playerid][nCallBack_Z], update_Variable[nCallBack_X], update_Variable[nCallBack_Y], update_Variable[nCallBack_Z]) : 1))
		#endif
	{
		pCallBack_Info[playerid][nCallBack_X] = update_Variable[nCallBack_X];
		pCallBack_Info[playerid][nCallBack_Y] = update_Variable[nCallBack_Y];
		pCallBack_Info[playerid][nCallBack_Z] = update_Variable[nCallBack_Z];
	}
	#endif
	#if defined CB_OnPlayerVehicleHealthChange
	update_Variable[nCallBack_VehicleID] = pCallBack_Info[playerid][nCallBack_VehicleID];
	update_Variable[nCallBack_VehicleSeat] = pCallBack_Info[playerid][nCallBack_VehicleSeat];
	if(update_Variable[nCallBack_VehicleID] != 0)
	{
		GetVehicleHealth(update_Variable[nCallBack_VehicleID], update_Variable[nCallBack_VehicleHealth]);
		#if defined USE_IN_ALL_SCRIPTS
		if(pCallBack_Info[playerid][nCallBack_VehicleHealth] != update_Variable[nCallBack_VehicleHealth] && ((OPVHC_CallBack != -1) ? CallRemoteFunction("OnPlayerVehicleHealthChange", "ddffl", playerid, update_Variable[nCallBack_VehicleID], pCallBack_Info[playerid][nCallBack_VehicleHealth], update_Variable[nCallBack_VehicleHealth], (update_Variable[nCallBack_VehicleSeat] == 0) ? true : false) : 1))
		#else
		if(pCallBack_Info[playerid][nCallBack_VehicleHealth] != update_Variable[nCallBack_VehicleHealth] && ((OPVHC_CallBack != -1) ? CallLocalFunction("OnPlayerVehicleHealthChange", "ddffl", playerid, update_Variable[nCallBack_VehicleID], pCallBack_Info[playerid][nCallBack_VehicleHealth], update_Variable[nCallBack_VehicleHealth], (update_Variable[nCallBack_VehicleSeat] == 0) ? true : false) : 1))
		#endif
			pCallBack_Info[playerid][nCallBack_VehicleHealth] = update_Variable[nCallBack_VehicleHealth];
	}
	#endif
	return ETI_ReturnOPU("d", playerid);
}
	#if defined _ALS_OnPlayerUpdate
		#undef OnPlayerUpdate
	#else
		#define _ALS_OnPlayerUpdate
	#endif
	#define OnPlayerUpdate ETI_OnPlayerUpdate
forward ETI_OnPlayerUpdate(playerid);
	#if defined CB_OnPlayerVirtualWorldChange
		#if !defined _ETI_SetPlayerVirtualWorld
			#define _ETI_SetPlayerVirtualWorld
stock ETI_SetPlayerVirtualWorld(playerid, worldid)
{
	new oldworld = GetPlayerVirtualWorld(playerid);
			#if defined USE_IN_ALL_SCRIPTS
	if(oldworld != worldid && ((OPVWC_CallBack != -1) ? CallRemoteFunction("OnPlayerVirtualWorldChange", "ddd", playerid, oldworld, worldid) : 1))
			#else
	if(oldworld != worldid && ((OPVWC_CallBack != -1) ? CallLocalFunction("OnPlayerVirtualWorldChange", "ddd", playerid, oldworld, worldid) : 1))
			#endif
		SetPlayerVirtualWorld(playerid, worldid);
	return 1;
}
			#define SetPlayerVirtualWorld(%0) ETI_SetPlayerVirtualWorld(%0)
		#endif
	#endif
	#if !defined _ETI_Kick
		#define _ETI_Kick
forward ETI_Kick(playerid);
public ETI_Kick(playerid)
{
	pCallBack_Info[playerid][nCallBack_KickedBanned] = true;
	Kick(playerid);
	return 1;
}
		#define Kick(%0) ETI_Kick(%0)
	#endif
	#if !defined _ETI_Ban
		#define _ETI_Ban
forward ETI_Ban(playerid);
public ETI_Ban(playerid)
{
	pCallBack_Info[playerid][nCallBack_KickedBanned] = true;
	Ban(playerid);
	return 1;
}
		#define Ban(%0) ETI_Ban(%0)
	#endif
	#if !defined _ETI_BanEx
		#define _ETI_BanEx
forward ETI_BanEx(playerid, const reason[]);
public ETI_BanEx(playerid, const reason[])
{
	pCallBack_Info[playerid][nCallBack_KickedBanned] = true;
	BanEx(playerid, reason);
	return 1;
}
		#define BanEx(%0) ETI_BanEx(%0)
	#endif
#endif
#if defined USE_PVAR_CALLBACKS
	#if defined CB_OnPVarDelete
forward OnPVarDelete(playerid, varname[], oldtype);
	#endif
	#if defined CB_OnPVarCreate
forward OnPVarCreate(playerid, varname[], type);
	#endif
	#if defined CB_OnPVarTypeChange
forward OnPVarTypeChange(playerid, varname[], oldtype, newtype);
	#endif
forward OnPVarIntChange(playerid, varname[], oldint_value, newint_value);
forward OnPVarStringChange(playerid, varname[], oldstring_value[], newstring_value[]);
forward OnPVarFloatChange(playerid, varname[], Float:oldfloat_value, Float:newfloat_value);
	#if defined CB_OnPVarDelete
		#if !defined _ETI_DeletePVar
			#define _ETI_DeletePVar
forward ETI_DeletePVar(playerid, varname[]);
public ETI_DeletePVar(playerid, varname[])
{
	new pvartype = GetPVarType(playerid, varname);
			#if defined USE_IN_ALL_SCRIPTS
	if(pvartype != 0 && ((OPVarD_CallBack != -1) ? CallRemoteFunction("OnPVarDelete", "dsd", playerid, varname, pvartype) : 1))
			#else
	if(pvartype != 0 && ((OPVarD_CallBack != -1) ? CallLocalFunction("OnPVarDelete", "dsd", playerid, varname, pvartype) : 1))
			#endif
		return DeletePVar(playerid, varname);
	return 0;
}
			#define DeletePVar(%0) ETI_DeletePVar(%0)
		#endif
	#endif
	#if !defined _ETI_SetPVarInt
		#define _ETI_SetPVarInt
forward ETI_SetPVarInt(playerid, varname[], int_value);
public ETI_SetPVarInt(playerid, varname[], int_value)
{
		#if defined CB_OnPVarCreate
			#if defined USE_IN_ALL_SCRIPTS
	if(GetPVarType(playerid, varname) == 0 && ((OPVarC_CallBack != -1) ? CallRemoteFunction("OnPVarCreate", "dsd", playerid, varname, 1) : 1))
			#else
	if(GetPVarType(playerid, varname) == 0 && ((OPVarC_CallBack != -1) ? CallLocalFunction("OnPVarCreate", "dsd", playerid, varname, 1) : 1))
			#endif
		SetPVarInt(playerid, varname, int_value);
			#if defined CB_OnPVarTypeChange
	else
			#endif
		#endif
		#if defined CB_OnPVarTypeChange
			#if defined USE_IN_ALL_SCRIPTS
	if(GetPVarType(playerid, varname) != 0 && GetPVarType(playerid, varname) != 1 && ((OPVarTC_CallBack != -1) ? CallRemoteFunction("OnPVarTypeChange", "dsdd", playerid, varname, GetPVarType(playerid, varname), 1) : 1))
			#else
	if(GetPVarType(playerid, varname) != 0 && GetPVarType(playerid, varname) != 1 && ((OPVarTC_CallBack != -1) ? CallLocalFunction("OnPVarTypeChange", "dsdd", playerid, varname, GetPVarType(playerid, varname), 1) : 1))
			#endif
		SetPVarInt(playerid, varname, int_value);
			#if defined CB_OnPVarIntChange
	else
			#endif
		#endif
		#if defined CB_OnPVarIntChange
			#if defined USE_IN_ALL_SCRIPTS
	if(GetPVarInt(playerid, varname) != int_value && ((OPVarIC_CallBack != -1) ? CallRemoteFunction("OnPVarIntChange", "dsdd", playerid, varname, GetPVarInt(playerid, varname), int_value) : 1))
			#else
	if(GetPVarInt(playerid, varname) != int_value && ((OPVarIC_CallBack != -1) ? CallLocalFunction("OnPVarIntChange", "dsdd", playerid, varname, GetPVarInt(playerid, varname), int_value) : 1))
			#endif
		SetPVarInt(playerid, varname, int_value);
		#endif
		#if !defined CB_OnPVarCreate
			#if !defined CB_OnPVarTypeChange
				#if !defined CB_OnPVarIntChange
	SetPVarInt(playerid, varname, int_value);
				#endif
			#endif
		#endif
}
		#define SetPVarInt(%0) ETI_SetPVarInt(%0)
	#endif
	#if !defined _ETI_SetPVarString
		#define _ETI_SetPVarString
forward ETI_SetPVarString(playerid, varname[], string_value[]);
public ETI_SetPVarString(playerid, varname[], string_value[])
{
		#if defined CB_OnPVarCreate
			#if defined USE_IN_ALL_SCRIPTS
	if(GetPVarType(playerid, varname) == 0 && ((OPVarC_CallBack != -1) ? CallRemoteFunction("OnPVarCreate", "dsd", playerid, varname, 2) : 1))
			#else
	if(GetPVarType(playerid, varname) == 0 && ((OPVarC_CallBack != -1) ? CallLocalFunction("OnPVarCreate", "dsd", playerid, varname, 2) : 1))
			#endif
		SetPVarString(playerid, varname, string_value);
			#if defined CB_OnPVarTypeChange
	else
			#endif
		#endif
		#if defined CB_OnPVarTypeChange
			#if defined USE_IN_ALL_SCRIPTS
	if(GetPVarType(playerid, varname) != 0 && GetPVarType(playerid, varname) != 2 && ((OPVarTC_CallBack != -1) ? CallRemoteFunction("OnPVarTypeChange", "dsdd", playerid, varname, GetPVarType(playerid, varname), 2) : 1))
			#else
	if(GetPVarType(playerid, varname) != 0 && GetPVarType(playerid, varname) != 2 && ((OPVarTC_CallBack != -1) ? CallLocalFunction("OnPVarTypeChange", "dsdd", playerid, varname, GetPVarType(playerid, varname), 2) : 1))
			#endif
		SetPVarString(playerid, varname, string_value);
			#if defined CB_OnPVarStringChange
	else
	{
			#endif
		#endif
		#if defined CB_OnPVarStringChange
		new pvstr[1024];
		GetPVarString(playerid, varname, pvstr, 1024);
		new strcmpval = strcmp(pvstr, string_value);
			#if defined USE_IN_ALL_SCRIPTS
		if((strcmpval == -1 || strcmpval == 1) && ((OPVarSC_CallBack != -1) ? CallRemoteFunction("OnPVarStringChange", "dsss", playerid, varname, pvstr, string_value) : 1))
			#else
		if((strcmpval == -1 || strcmpval == 1) && ((OPVarSC_CallBack != -1) ? CallLocalFunction("OnPVarStringChange", "dsss", playerid, varname, pvstr, string_value) : 1))
			#endif
			SetPVarString(playerid, varname, string_value);
			#if defined CB_OnPVarTypeChange
	}
			#endif
		#endif
		#if !defined CB_OnPVarCreate
			#if !defined CB_OnPVarTypeChange
				#if defined !CB_OnPVarStringChange
	SetPVarString(playerid, varname, string_value);
				#endif
			#endif
		#endif
	return 1;
}
		#define SetPVarString(%0) ETI_SetPVarString(%0)
	#endif
	#if !defined _ETI_SetPVarFloat
		#define _ETI_SetPVarFloat
forward ETI_SetPVarFloat(playerid, varname[], Float:float_value);
public ETI_SetPVarFloat(playerid, varname[], Float:float_value)
{
		#if defined CB_OnPVarCreate
			#if defined USE_IN_ALL_SCRIPTS
	if(GetPVarType(playerid, varname) == 0 && ((OPVarC_CallBack != -1) ? CallRemoteFunction("OnPVarCreate", "dsd", playerid, varname, 3) : 1))
			#else
	if(GetPVarType(playerid, varname) == 0 && ((OPVarC_CallBack != -1) ? CallLocalFunction("OnPVarCreate", "dsd", playerid, varname, 3) : 1))
			#endif
		SetPVarFloat(playerid, varname, float_value);
			#if defined CB_OnPVarTypeChange
	else
			#endif
		#endif
		#if defined CB_OnPVarTypeChange
			#if defined USE_IN_ALL_SCRIPTS
	if(GetPVarType(playerid, varname) != 0 && GetPVarType(playerid, varname) != 3 && ((OPVarTC_CallBack != -1) ? CallRemoteFunction("OnPVarTypeChange", "dsdd", playerid, varname, GetPVarType(playerid, varname), 3) : 1))
			#else
	if(GetPVarType(playerid, varname) != 0 && GetPVarType(playerid, varname) != 3 && ((OPVarTC_CallBack != -1) ? CallLocalFunction("OnPVarTypeChange", "dsdd", playerid, varname, GetPVarType(playerid, varname), 3) : 1))
			#endif
		SetPVarFloat(playerid, varname, float_value);
			#if defined CB_OnPVarFloatChange
	else
			#endif
		#endif
		#if defined CB_OnPVarFloatChange
			#if defined USE_IN_ALL_SCRIPTS
	if(GetPVarFloat(playerid, varname) != float_value && ((OPVarFC_CallBack != -1) ? CallRemoteFunction("OnPVarFloatChange", "dsff", playerid, varname, GetPVarFloat(playerid, varname), float_value) : 1))
			#else
	if(GetPVarFloat(playerid, varname) != float_value && ((OPVarFC_CallBack != -1) ? CallLocalFunction("OnPVarFloatChange", "dsff", playerid, varname, GetPVarFloat(playerid, varname), float_value) : 1))
			#endif
		SetPVarFloat(playerid, varname, float_value);
		#endif
		#if defined CB_OnPVarCreate
			#if !defined CB_OnPVarTypeChange
				#if !defined CB_OnPVarFloatChange
	SetPVarFloat(playerid, varname, float_value);
				#endif
			#endif
		#endif
	return 1;
}
		#define SetPVarFloat(%0) ETI_SetPVarFloat(%0)
	#endif
#endif

/*
ETIETIETIETI  	ETI		    ETIETIETIETI	BigBigBigBig	BigBigBigBigBig		Big
ETI       ETI 	ETI		  ETI           	Big         	      Big      		Big
ETI        ETI	ETI		 ETI            	Big         	      Big      		Big
ETI       ETI 	ETI		ETI             	Big         	      Big      		Big
ETIETIETIETI  	ETI		ETI    ETIETIETI	BigBigBig   	      Big      		Big
ETI       ETI 	ETI		ETI          ETI	Big         	      Big      		Big
ETI        ETI	ETI		 ETI         ETI	Big         	      Big      		Big
ETI       ETI 	ETI		  ETI        ETI	Big         	      Big      		Big
ETIETIETIETI  	ETI		    ETIETIETIETI	BigBigBigBig	      Big      		Big
*/