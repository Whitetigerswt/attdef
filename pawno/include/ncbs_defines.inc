/*
////////////////////////////////////////////////////////////////////
//================================================================//
//== New Player Callbacks defines include made by BigETI © 2011 ==//
//================================================================//
//== You are not allowed to release this include =================//
//== without my permissions! =====================================//
//================================================================//
//== File name: ncbs_defines.inc =================================//
//== Autor: Ethem Kurt © =========================================//
//== Release Date: 29.10.2011 ====================================//
//== Version: V1.5 ===============================================//
//== Lines: 62 ===================================================//
//== File size: 5,59 KB ==========================================//
//================================================================//
////////////////////////////////////////////////////////////////////
*/
#if defined _BIGETI_NPCBS_DEFINES
	#endinput
#endif
#define _BIGETI_NPCBS_DEFINES
/*
||======================================================================================================================||
||	IMPORTANT: Define FILTERSCRIPT on top of your script to verify if you are yousing a filterscript or a gamemode!     ||
||	If you have changed any parameters below, so recompile all of your scripts using the New Player Callbacks include.  ||
||======================================================================================================================||
*/

//Just comment a define if you don't need it. Otherwise uncomment.

#define USE_IN_ALL_SCRIPTS				//Used to call the callbacks in all scripts else the callbacks gets only called where the include got included.
#define USE_OPU_DELAY					//Uses a delay at OnPlayerUpdate to prevent totally overkill (Usefull for anti cheats but the callbacks may get slower!)
//#define USE_OPU_SECONDS				//Callbacks delays >1 seconds otherwise they delays for >1 milliseconds. (Uncomment USE_OPU_DELAY to make this usable!) [Optional]
#define USE_PLAYER_CALLBACKS			//Makes the use of extended player callbacks.
//#define USE_PVAR_CALLBACKS			//Makes the use of PVar callbacks (Uncomment this if you want to use PVar Callbacks) [Optional]
#define CB_OnPlayerEnteredVehicle		//Makes the use of OnPlayerEnteredVehicle (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerExitedVehicle		//Makes the use of OnPlayerExitedVehicle (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerSkinChange			//Makes the use of OnPlayerSkinChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerHoldWeaponChange		//Makes the use of OnPlayerHoldWeaponChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerWeaponStateChange	//Makes the use of OnPlayerWeaponStateChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define USE_WEAPON_DATA_CALLBACKS		//Makes the use of weapon data callbacks
#define CB_OnPlayerWeaponDataChange		//Makes the use of OnPlayerWeaponDataChange (Uncomment USE_PLAYER_CALLBACKS and USE_WEAPON_DATA_CALLBACKS to make this usable!)
#define CB_OnPlayerAmmoDataChange		//Makes the use of OnPlayerAmmoDataChange (Uncomment USE_PLAYER_CALLBACKS and USE_WEAPON_DATA_CALLBACKS to make this usable!)
#define CB_OnPlayerMoneyChange			//Makes the use of OnPlayerMoneyChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerHealthChange			//Makes the use of OnPlayerHealthChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerArmourChange			//Makes the use of OnPlayerArmourChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerAnimationIndexChange	//Makes the use of OnPlayerAnimationIndexChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerTargetPlayer			//Makes the use of OnPlayerTargetPlayer (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerSpecialActionChange	//Makes the use of OnPlayerSpecialActionChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerAnalogKeysChange		//Makes the use of OnPlayerAnalogKeysChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerXYZChange			//Makes the use of OnPlayerXYZChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerVehicleHealthChange	//Makes the use of OnPlayerVehicleHealthChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPlayerVirtualWorldChange	//Makes the use of OnPlayerVirtualWorldChange (Uncomment USE_PLAYER_CALLBACKS to make this usable!)
#define CB_OnPVarDelete					//Makes the use of OnPVarDelete (Uncomment USE_PVAR_CALLBACKS to make this usable!)
#define CB_OnPVarCreate					//Makes the use of OnPVarCreate (Uncomment USE_PVAR_CALLBACKS to make this usable!)
#define CB_OnPVarTypeChange				//Makes the use of OnPVarTypeChange (Uncomment USE_PVAR_CALLBACKS to make this usable!)
#define CB_OnPVarIntChange				//Makes the use of OnPVarIntChange (Uncomment USE_PVAR_CALLBACKS to make this usable!)
#define CB_OnPVarStringChange			//Makes the use of OnPVarStringChange (Uncomment USE_PVAR_CALLBACKS to make this usable!)
#define CB_OnPVarFloatChange			//Makes the use of OnPVarFloatChange (Uncomment USE_PVAR_CALLBACKS to make this usable!)

//Setable defines
#define ADD_OPU_DELAY	0				//You can increase/decrease the delay of OnPlayerUpdate by setting this define (0 is standard [means >1 s or ms delay]) (If USE_OPU_SECONDS is defined, then in seconds otherwise in milliseconds)