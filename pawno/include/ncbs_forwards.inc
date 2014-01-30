/*
/////////////////////////////////////////////////////////////////////
//=================================================================//
//== New Player Callbacks forwards include made by BigETI © 2011 ==//
//=================================================================//
//== You are not allowed to edit this include =====================//
//== and/or release it without my permissions! ====================//
//=================================================================//
//== File name: ncbs_forwards.inc =================================//
//== Autor: Ethem Kurt © ==========================================//
//== Release Date: 29.10.2011 =====================================//
//== Version: V1.5 ================================================//
//== Lines: 165 ===================================================//
//== File size: 7,44 KB ===========================================//
//=================================================================//
/////////////////////////////////////////////////////////////////////

||==============================================================================||
||	This include is only used for remoted callbacks.                            ||
||	You have to use ncbs.inc at another script to make this include usable.     ||
||	Both includes at one script won't work and will give you compiling errors.  ||
||==============================================================================||
*/

//Do not edit those things below!
#include <a_samp>
#if defined _BIGETI_NPCBS_FORWARDS
	#endinput
#endif
#define _BIGETI_NPCBS_FORWARDS
#if defined _BIGETI_NEW_PLAYER_CALLBACKS
	#error Do not use ncbs.inc and ncbs_forwards.inc in one script.
	#endinput
#endif
#include <ncbs_defines>
#pragma library	ncbs_forwards
#if defined USE_IN_ALL_SCRIPTS
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
			#if !defined _ETI_SetPlayerVirtualWorld
				#define _ETI_SetPlayerVirtualWorld
stock ETI_SetPlayerVirtualWorld(playerid, worldid) if(CallRemoteFunction("ETI_SetPlayerVirtualWorld", "dd", playerid, worldid) != 1) SetPlayerVirtualWorld(playerid, worldid);
				#define SetPlayerVirtualWorld(%0) SetPlayerVirtualWorld_ETI(%0)
			#endif
		#endif
		#if !defined _ETI_Kick
			#define _ETI_Kick
stock ETI_Kick(playerid) if(CallRemoteFunction("ETI_Kick", "d", playerid) != 1) Kick(playerid);
			#define Kick(%0) ETI_Kick(%0)
		#endif
		#if !defined _ETI_Ban
			#define _ETI_Ban
stock ETI_Ban(playerid) if(CallRemoteFunction("ETI_Ban", "d", playerid) != 1) Ban(playerid);
			#define Ban(%0) ETI_Ban(%0)
		#endif
		#if !defined _ETI_BanEx
			#define _ETI_BanEx
stock ETI_BanEx(playerid, const reason[]) if(CallRemoteFunction("ETI_BanEx", "ds", playerid, reason) != 1) BanEx(playerid, reason);
			#define BanEx(%0) ETI_BanEx(%0)
		#endif
	#endif
	#if defined USE_PVAR_CALLBACKS
		#if defined CB_OnPVarDelete
forward OnPVarDelete(playerid, varname[], oldtype);
			#if !defined _ETI_DeletePVar
				#define _ETI_DeletePVar
stock ETI_DeletePVar(playerid, varname[]) if(CallRemoteFunction("ETI_DeletePVar", "ds", playerid, varname) != 1) DeletePVar(playerid, varname);
				#define DeletePVar(%0) ETI_DeletePVar(%0)
			#endif
		#endif
		#if defined CB_OnPVarCreate
forward OnPVarCreate(playerid, varname[], type);
		#endif
		#if defined CB_OnPVarTypeChange
forward OnPVarTypeChange(playerid, varname[], oldtype, newtype);
		#endif
		#if defined CB_OnPVarIntChange
forward OnPVarIntChange(playerid, varname[], oldint_value, newint_value);
		#endif
		#if defined CB_OnPVarStringChange
forward OnPVarStringChange(playerid, varname[], oldstring_value[], newstring_value[]);
		#endif
		#if defined CB_OnPVarFloatChange
forward OnPVarFloatChange(playerid, varname[], Float:oldfloat_value, Float:newfloat_value);
		#endif
		#if !defined _ETI_SetPVarInt
			#define _ETI_SetPVarInt
stock ETI_SetPVarInt(playerid, varname[], int_value) if(CallRemoteFunction("ETI_SetPVarInt", "dsd", playerid, varname, int_value) != 1) SetPVarInt(playerid, varname, int_value);
			#define SetPVarInt(%0) ETI_SetPVarInt(%0)
		#endif
		#if !defined _ETI_SetPVarString
			#define _ETI_SetPVarString
stock ETI_SetPVarString(playerid, varname[], string_value[]) if(CallRemoteFunction("ETI_SetPVarString", "dss", playerid, varname, string_value) != 1) SetPVarString(playerid, varname, string_value);
			#define SetPVarString(%0) ETI_SetPVarString(%0)
		#endif
		#if !defined _ETI_SetPVarFloat
			#define _ETI_SetPVarFloat
stock ETI_SetPVarFloat(playerid, varname[], Float:float_value) if(CallRemoteFunction("ETI_SetPVarFloat", "dsf", playerid, varname, float_value) != 1) SetPVarFloat(playerid, varname, float_value);
			#define SetPVarFloat(%0) ETI_SetPVarFloat(%0)
		#endif
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