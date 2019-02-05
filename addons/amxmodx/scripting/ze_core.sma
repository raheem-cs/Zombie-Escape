#include <zombie_escape>

// Fowards
enum _:TOTAL_FORWARDS
{
	FORWARD_NONE = 0,
	FORWARD_ROUNDEND,
	FORWARD_HUMANIZED,
	FORWARD_PRE_INFECTED,
	FORWARD_INFECTED,
	FORWARD_ZOMBIE_APPEAR,
	FORWARD_ZOMBIE_RELEASE,
	FORWARD_GAME_STARTED,
	FORWARD_DISCONNECT
}

new g_iForwards[TOTAL_FORWARDS], g_iFwReturn, g_iTeam

// Tasks IDs
enum
{
	TASK_COUNTDOWN = 1100,
	TASK_COUNTDOWN2,
	TASK_SCORE_MESSAGE,
	FREEZE_ZOMBIES,
	ROUND_TIME_LEFT
}

// Colors (g_pCvarColors[] array indexes)
enum
{
	Red = 0,
	Green,
	Blue
}

// Variables
new g_iAliveHumansNum, 
	g_iAliveZombiesNum, 
	g_iRoundTime, 
	g_iCountDown, 
	g_iReleaseNotice, 
	g_iMaxClients, 
	g_iHumansScore, 
	g_iZombiesScore, 
	g_iRoundNum,
	g_iHSpeedFactor[33],
	g_iZSpeedSet[33],
	bool:g_bGameStarted, 
	bool:g_bIsZombie[33], 
	bool:g_bIsZombieFrozen[33], 
	bool:g_bZombieFreezeTime, 
	bool:g_bIsRoundEnding,
	bool:g_bHSpeedUsed[33], 
	bool:g_bZSpeedUsed[33],
	bool:g_bEndCalled,
	Float:g_flReferenceTime

// Cvars
new	g_pCvarHumanSpeedFactor, 
	g_pCvarHumanGravity, 
	g_pCvarHumanHealth, 
	g_pCvarZombieSpeed, 
	g_pCvarZombieGravity,
	g_pCvarZombieReleaseTime, 
	g_pCvarFreezeTime, 
	g_pCvarRoundTime, 
	g_pCvarReqPlayers, 
	g_pCvarZombieHealth, 
	g_pCvarFirstZombiesHealth,
	g_pCvarZombieKnockback, 
	g_pCvarScoreMessageType, 
	g_pCvarColors[3],
	g_pCvarRoundEndDelay,
	g_pCvarSmartRandom
	
// Dynamic Arrays
new Array:g_aChosenPlayers

public plugin_natives()
{
	register_native("ze_is_user_zombie", "native_ze_is_user_zombie", 1)
	register_native("ze_is_game_started", "native_ze_is_game_started", 1)
	register_native("ze_is_zombie_frozen", "native_ze_is_zombie_frozen", 1)
	
	register_native("ze_get_round_number", "native_ze_get_round_number", 1)
	register_native("ze_get_humans_number", "native_ze_get_humans_number", 1)
	register_native("ze_get_zombies_number", "native_ze_get_zombies_number", 1)
	
	register_native("ze_set_user_zombie", "native_ze_set_user_zombie", 1)
	register_native("ze_set_user_human", "native_ze_set_user_human", 1)
	register_native("ze_set_human_speed_factor", "native_ze_set_human_speed_factor", 1)
	register_native("ze_set_zombie_speed", "native_ze_set_zombie_speed", 1)
	
	register_native("ze_reset_human_speed", "native_ze_reset_human_speed", 1)
	register_native("ze_reset_zombie_speed", "native_ze_reset_zombie_speed", 1)
}

public plugin_init()
{
	register_plugin("[ZE] Core/Engine", ZE_VERSION, AUTHORS)
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "Fw_TraceAttack_Pre", 0)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Fw_TakeDamage_Post", 1)
	RegisterHookChain(RG_CBasePlayer_Spawn, "Fw_PlayerSpawn_Post", 1)
	RegisterHookChain(RG_CSGameRules_CheckWinConditions, "Fw_CheckMapConditions_Post", 1)
	RegisterHookChain(RG_CBasePlayer_Killed, "Fw_PlayerKilled_Post", 1)
	RegisterHookChain(RG_RoundEnd, "Event_RoundEnd_Pre", 0)
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "Fw_RestMaxSpeed_Post", 1)
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "Fw_HandleMenu_ChooseTeam_Post", 1)
	
	// Events
	register_event("HLTV", "New_Round", "a", "1=0", "2=0")
	register_event("TextMsg", "Map_Restart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in", "2=#Round_Draw")
	register_logevent("Round_Start", 2, "1=Round_Start")
	register_logevent("Round_End", 2, "1=Round_End")
	
	// Create Forwards
	g_iForwards[FORWARD_ROUNDEND] = CreateMultiForward("ze_roundend", ET_IGNORE, FP_CELL)
	g_iForwards[FORWARD_HUMANIZED] = CreateMultiForward("ze_user_humanized", ET_IGNORE, FP_CELL)
	g_iForwards[FORWARD_PRE_INFECTED] = CreateMultiForward("ze_user_infected_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_iForwards[FORWARD_INFECTED] = CreateMultiForward("ze_user_infected", ET_IGNORE, FP_CELL, FP_CELL)
	g_iForwards[FORWARD_ZOMBIE_APPEAR] = CreateMultiForward("ze_zombie_appear", ET_IGNORE)
	g_iForwards[FORWARD_ZOMBIE_RELEASE] = CreateMultiForward("ze_zombie_release", ET_IGNORE)
	g_iForwards[FORWARD_GAME_STARTED] = CreateMultiForward("ze_game_started", ET_IGNORE)
	g_iForwards[FORWARD_DISCONNECT] = CreateMultiForward("ze_player_disconnect", ET_CONTINUE, FP_CELL)
	
	// Hud Messages
	g_iReleaseNotice = CreateHudSyncObj()
	
	// Sequential files (.txt)
	register_dictionary("zombie_escape.txt")
	
	// Humans Cvars
	g_pCvarHumanSpeedFactor = register_cvar("ze_human_speed_factor", "20.0")
	g_pCvarHumanGravity = register_cvar("ze_human_gravity", "800")
	g_pCvarHumanHealth = register_cvar("ze_human_health", "1000")
	
	// Zombie Cvars
	g_pCvarZombieSpeed = register_cvar("ze_zombie_speed", "350.0")
	g_pCvarZombieGravity = register_cvar("ze_zombie_gravity", "640")
	g_pCvarZombieHealth = register_cvar("ze_zombie_health", "10000")
	g_pCvarFirstZombiesHealth = register_cvar("ze_first_zombies_health", "20000")
	g_pCvarZombieKnockback = register_cvar("ze_zombie_knockback", "300.0")
	
	// General Cvars
	g_pCvarZombieReleaseTime = register_cvar("ze_release_time", "15")
	g_pCvarFreezeTime = register_cvar("ze_freeze_time", "20")
	g_pCvarRoundTime = register_cvar("ze_round_time", "9.0")
	g_pCvarReqPlayers = register_cvar("ze_required_players", "2")
	g_pCvarScoreMessageType = register_cvar("ze_score_message_type", "1")
	g_pCvarColors[Red] = register_cvar("ze_score_message_red", "200")
	g_pCvarColors[Green] = register_cvar("ze_score_message_green", "100")
	g_pCvarColors[Blue] = register_cvar("ze_score_message_blue", "0")
	g_pCvarRoundEndDelay = register_cvar("ze_round_end_delay", "5")
	g_pCvarSmartRandom = register_cvar("ze_smart_random", "1")
	
	// Default Values
	g_bGameStarted = false
	
	// Static Values
	g_iMaxClients = get_member_game(m_nMaxPlayers)
	
	// Check Round Time to Terminate it
	set_task(1.0, "Check_RoundTimeleft", ROUND_TIME_LEFT, _, _, "b")
}

public plugin_cfg()
{
	// Get our configiration file and Execute it
	new szCfgDir[64]
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir))
	server_cmd("exec %s/zombie_escape.cfg", szCfgDir)
	
	// Set Game Name
	new szGameName[64]
	formatex(szGameName, sizeof(szGameName), "Zombie Escape v%s", ZE_VERSION)
	set_member_game(m_GameDesc, szGameName)
	
	// Set Version
	register_cvar("ze_version", ZE_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("ze_version", ZE_VERSION)
	
	// Delay so cvars be loaded from zombie_escape.cfg
	set_task(0.1, "DelaySmartRandom")
	
	// Delay some settings
	set_task(0.1, "DelaySettings")
}

public DelaySettings()
{
	// Set some cvars, not allowed to be changed from any other .cfg file (Not recommended to remove them)
	new pCvarRoundTime, pCvarFreezeTime, pCvarMaxSpeed
	
	pCvarRoundTime = get_cvar_pointer("mp_roundtime")
	pCvarFreezeTime = get_cvar_pointer("mp_freezetime")
	pCvarMaxSpeed = get_cvar_pointer("sv_maxspeed")
	
	set_pcvar_num(pCvarRoundTime, get_pcvar_num(g_pCvarRoundTime))
	set_pcvar_num(pCvarFreezeTime, get_pcvar_num(g_pCvarFreezeTime))
	
	// Max speed at least equal to zombies speed. Here zombies speed assumed to be higher than humans one.
	if (get_pcvar_num(pCvarMaxSpeed) < get_pcvar_num(g_pCvarZombieSpeed))
	{
		set_pcvar_num(pCvarMaxSpeed, get_pcvar_num(g_pCvarZombieSpeed))
	}
}

public DelaySmartRandom()
{
	if (get_pcvar_num(g_pCvarSmartRandom))
	{
		// Create our array to store SteamIDs in
		g_aChosenPlayers = ArrayCreate(34)
	}
}

public Fw_CheckMapConditions_Post()
{
	// Block Game Commencing
	set_member_game(m_bGameStarted, true)
	
	// Set Freeze Time
	set_member_game(m_iIntroRoundTime, get_pcvar_num(g_pCvarFreezeTime))
	
	// Set Round Time
	set_member_game(m_iRoundTime, floatround(get_pcvar_float(g_pCvarRoundTime) * 60.0))
}

public Fw_PlayerKilled_Post(id)
{
	g_iAliveHumansNum = GetAlivePlayersNum(CsTeams:TEAM_CT)
	g_iAliveZombiesNum = GetAlivePlayersNum(CsTeams:TEAM_TERRORIST)
	
	if (g_iAliveHumansNum == 0 && g_iAliveZombiesNum == 0)
	{
		// No Winner, All Players in one team killed Or Both teams Killed
		client_print(0, print_center, "%L", LANG_PLAYER, "NO_WINNER")
	}
}

public Fw_RestMaxSpeed_Post(id)
{
	if (!g_bIsZombie[id])
	{
		static Float:flMaxSpeed
		get_entvar(id, var_maxspeed, flMaxSpeed)
		
		if (flMaxSpeed != 1.0 && is_user_alive(id))
		{
			if (g_bHSpeedUsed[id])
			{
				// Set New Human Speed Factor
				set_entvar(id, var_maxspeed, flMaxSpeed + float(g_iHSpeedFactor[id]))
				return HC_CONTINUE
			}
				
			// Set Human Speed Factor, native not used
			set_entvar(id, var_maxspeed, flMaxSpeed + get_pcvar_float(g_pCvarHumanSpeedFactor))
			return HC_CONTINUE
		}
	}
	
	return HC_SUPERCEDE
}

public Fw_PlayerSpawn_Post(id)
{	
	if (!g_bGameStarted)
	{
		// Force All player to be Humans if Game not started yet
		rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED)
	}
	else
	{
		if (get_member_game(m_bFreezePeriod))
		{
			// Respawn Him As human if we are in freeze time (Zombie Not Chosen yet)
			Set_User_Human(id)
			g_bIsZombieFrozen[id] = false
		}
		else
		{
			if (g_bZombieFreezeTime)
			{
				// Zombie Chosen and zombies Frozen, Spawn him as zombie and Freeze Him
				Set_User_Zombie(id)
				g_bIsZombieFrozen[id] = true
				set_entvar(id, var_maxspeed, 1.0)
			}
			else
			{
				// Respawn him as normal zombie
				Set_User_Zombie(id)
				g_bIsZombieFrozen[id] = false
			}
		}
	}
}

public New_Round()
{
	// Remove All tasks in the New Round
	remove_task(TASK_COUNTDOWN)
	remove_task(TASK_COUNTDOWN2)
	remove_task(TASK_SCORE_MESSAGE)
	remove_task(FREEZE_ZOMBIES)
	
	// Score Message Task
	set_task(10.0, "Score_Message", TASK_SCORE_MESSAGE, _, _, "b")
	
	// 2 is Hardcoded Value, It's Fix for the countdown to work correctly
	g_iCountDown = get_member_game(m_iIntroRoundTime) - 2
	
	if (!g_bGameStarted)
	{
		// No Enough Players
		ze_colored_print(0, "%L", LANG_PLAYER, "NO_ENOUGH_PLAYERS", get_pcvar_num(g_pCvarReqPlayers))
		return // Block the execution of the blew code 
	}
	
	// Game Already started, Countdown now started
	set_task(1.0, "Countdown_Start", TASK_COUNTDOWN, _, _, "b")
	ze_colored_print(0, "%L", LANG_PLAYER, "READY_TO_RUN")
	ExecuteForward(g_iForwards[FORWARD_GAME_STARTED], g_iFwReturn)
	
	g_iRoundNum++
	
	// Round Starting
	g_bIsRoundEnding = false
	g_bEndCalled = false
}

// Score Message Task
public Score_Message(TaskID)
{
	switch(get_pcvar_num(g_pCvarScoreMessageType))
	{
		case 0: // Disabled
		{
			return
		}
		case 1: // DHUD
		{
			set_dhudmessage(get_pcvar_num(g_pCvarColors[Red]), get_pcvar_num(g_pCvarColors[Green]), get_pcvar_num(g_pCvarColors[Blue]), -1.0, 0.01, 0, 0.0, 9.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "SCORE_MESSAGE", g_iZombiesScore, g_iHumansScore)
		}
		case 2: // HUD
		{
			set_hudmessage(get_pcvar_num(g_pCvarColors[Red]), get_pcvar_num(g_pCvarColors[Green]), get_pcvar_num(g_pCvarColors[Blue]), -1.0, 0.01, 0, 0.0, 9.0)
			show_hudmessage(0, "%L", LANG_PLAYER, "SCORE_MESSAGE", g_iZombiesScore, g_iHumansScore)
		}
	}
}

public Countdown_Start(TaskID)
{
	// Check if the players Disconnected and there is only one player then remove all messages, and stop tasks
	if (!g_bGameStarted)
		return
	
	if (!g_iCountDown)
	{
		Choose_Zombies()
		remove_task(TASK_COUNTDOWN) // Remove the task
		return // Block the execution of the blew code
	}
	
	set_hudmessage(random(256), random(256), random(256), -1.0, 0.21, 0, 0.8, 0.8)
	show_hudmessage(0, "%L", LANG_PLAYER, "RUN_NOTICE", g_iCountDown)

	g_iCountDown--
}

public Choose_Zombies()
{
	new iZombies, id, iAliveCount
	new iReqZombies
	
	// Get total alive players and required players
	iAliveCount  = GetAllAlivePlayersNum()
	iReqZombies = RequiredZombies()
	
	// Loop till we find req players
	while(iZombies < iReqZombies)
	{
		id = GetRandomAlive(random_num(1, iAliveCount))
		
		if (!is_user_alive(id) || g_bIsZombie[id])
			continue
		
		if (get_pcvar_num(g_pCvarSmartRandom))
		{
			// If player in the array, it means he chosen previous round so skip him this round
			if (IsPlayerInArray(g_aChosenPlayers, id))
				continue
		}

		Set_User_Zombie(id)
		set_entvar(id, var_health, get_pcvar_float(g_pCvarFirstZombiesHealth))
		g_bIsZombieFrozen[id] = true
		g_bZombieFreezeTime = true
		set_entvar(id, var_maxspeed, 1.0)
		set_task(0.1, "Freeze_Zombies", FREEZE_ZOMBIES, _, _, "b") // Better than PreThink
		ExecuteForward(g_iForwards[FORWARD_ZOMBIE_APPEAR], g_iFwReturn)
		iZombies++
	}
	
	if (get_pcvar_num(g_pCvarSmartRandom))
	{
		// Clear the array first
		ArrayClear(g_aChosenPlayers)
		
		new szAuthId[34]
		
		// Add steamid of chosen zombies, so we don't choose them next round again (using steamid means it support reconnect)
		for (new id = 1; id <= g_iMaxClients; id++)
		{
			if(!is_user_connected(id) || !g_bIsZombie[id])
				continue
			
			get_user_authid(id, szAuthId, charsmax(szAuthId))
			
			ArrayPushString(g_aChosenPlayers, szAuthId)
		}
	}
	
	// 2 is Hardcoded Value, It's Fix for the countdown to work correctly
	g_iCountDown = get_pcvar_num(g_pCvarZombieReleaseTime) - 2
	
	set_task(1.0, "ReleaseZombie_CountDown", TASK_COUNTDOWN2, _, _, "b")
}

public ReleaseZombie_CountDown(TaskID)
{
	if (!g_iCountDown)
	{
		ReleaseZombie()
		remove_task(TASK_COUNTDOWN2)
		return
	}
	
	// Release Hud Message
	set_hudmessage(255, 255, 0, -1.0, 0.21, 1, 2.0, 2.0)
	ShowSyncHudMsg(0, g_iReleaseNotice, "%L", LANG_PLAYER, "ZOMBIE_RELEASE", g_iCountDown)
	
	g_iCountDown --
}

public ReleaseZombie()
{
	ExecuteForward(g_iForwards[FORWARD_ZOMBIE_RELEASE], g_iFwReturn)
	
	for(new id = 1; id <= g_iMaxClients; id++)
	{
		if (is_user_alive(id) && g_bIsZombie[id])
		{
			g_bIsZombieFrozen[id] = false
			g_bZombieFreezeTime = false
		}
	}
}

public Freeze_Zombies(TaskID)
{
	for(new id = 1; id <= g_iMaxClients; id++)
	{
		if(!is_user_alive(id) || !g_bIsZombie[id])
			continue
		
		if (g_bIsZombieFrozen[id])
		{
			// Zombie & Frozen, then Freeze him
			set_entvar(id, var_maxspeed, 1.0)
		}
		else
		{
			if (g_bZSpeedUsed[id])
			{
				// Zombie but Not Frozen the set his speed form .cfg
				set_entvar(id, var_maxspeed, float(g_iZSpeedSet[id]))
				continue;
			}
				
			// Zombie but Not Frozen the set his speed form .cfg
			set_entvar(id, var_maxspeed, get_pcvar_float(g_pCvarZombieSpeed))
		}
	}
}

public Fw_TraceAttack_Pre(iVictim, iAttacker, Float:flDamage, Float:flDirection[3], iTracehandle, bitsDamageType)
{
	if (iVictim == iAttacker || !is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return HC_CONTINUE
	
	// Attacker and Victim is in same teams? Skip code blew
	if (get_member(iAttacker, m_iTeam) == get_member(iVictim, m_iTeam))
		return HC_CONTINUE
	
	// In freeze time? Skip all other plugins (Skip the real trace attack event)
	if (g_bIsZombieFrozen[iVictim] || g_bIsZombieFrozen[iAttacker])
		return HC_SUPERCEDE
	
	// Execute pre-infection forward
	ExecuteForward(g_iForwards[FORWARD_PRE_INFECTED], g_iFwReturn, iVictim, iAttacker, floatround(flDamage))
	
	if (g_iFwReturn > 0)
	{
		return HC_SUPERCEDE
	}
	
	g_iAliveHumansNum = GetAlivePlayersNum(CsTeams:TEAM_CT)
	
	if (g_bIsZombie[iAttacker])
	{
		// Death Message with Infection style [Added here because of delay in Forward use]
		SendDeathMsg(iAttacker, iVictim)
		
		Set_User_Zombie(iVictim)
		
		ExecuteForward(g_iForwards[FORWARD_INFECTED], g_iFwReturn, iVictim, iAttacker)
		
		if (g_iAliveHumansNum == 1) // Check if this is Last Human, Because of Delay i can't check if it's 0 instead of 1
		{
			// End round event called one time
			g_bEndCalled = true
			
			// Round is Ending
			g_bIsRoundEnding = true
			
			// Zombie Win, Leave text blank so we use ours from ML
			rg_round_end(get_pcvar_float(g_pCvarRoundEndDelay), WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "")
			
			// Show Our Message
			client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
			
			// This needed so forward work also to add +1 for Zombies
			g_iTeam = 1 // ZE_TEAM_ZOMBIE
			ExecuteForward(g_iForwards[FORWARD_ROUNDEND], g_iFwReturn, g_iTeam)
		}
	}
	
	return HC_CONTINUE
}

public Fw_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	// Not Vaild Victim or Attacker so skip the event (Important to block out bounds errors)
	if (!is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return HC_CONTINUE
	
	// Set Knockback here, So if we blocked damage in TraceAttack event player won't get knockback (Fix For Madness)
	if (g_bIsZombie[iVictim] && !g_bIsZombie[iAttacker])
	{
		// Remove Shock Pain
		set_member(iVictim, m_flVelocityModifier, 1.0)
		
		// Set Knockback
		static Float:flOrigin[3]
		get_entvar(iAttacker, var_origin, flOrigin)
		Set_Knockback(iVictim, flOrigin, get_pcvar_float(g_pCvarZombieKnockback), 2)
	}
	
	return HC_CONTINUE
}

public Round_End()
{
	g_iAliveZombiesNum = GetAlivePlayersNum(CsTeams:TEAM_TERRORIST)
	
	if (g_iAliveZombiesNum == 0 && g_bGameStarted) 
	{
		g_iTeam = 2 // ZE_TEAM_HUMAN
		ExecuteForward(g_iForwards[FORWARD_ROUNDEND], g_iFwReturn, g_iTeam)
		client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
		g_iHumansScore++
		g_bIsRoundEnding = true
		return // To block Execute the code blew
	}
	
	g_iTeam = 1 // ZE_TEAM_ZOMBIE
	g_iZombiesScore++
	g_bIsRoundEnding = true
	
	// If it's already called one time, don't call it again
	if (!g_bEndCalled)
	{
		ExecuteForward(g_iForwards[FORWARD_ROUNDEND], g_iFwReturn, g_iTeam)
	}
	
	client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
}

public Event_RoundEnd_Pre(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	// The two unhandeld cases by rg_round_end() native in our Mod
	if (event == ROUND_CTS_WIN || event == ROUND_TERRORISTS_WIN)
	{
		SetHookChainArg(3, ATYPE_FLOAT, get_pcvar_float(g_pCvarRoundEndDelay))
	}
}

public Round_Start()
{
    g_flReferenceTime = get_gametime()
    g_iRoundTime = get_member_game(m_iRoundTime)
}

public Check_RoundTimeleft()
{
	new Float:flRoundTimeLeft = (g_flReferenceTime + float(g_iRoundTime)) - get_gametime()
	
	if (floatround(flRoundTimeLeft) == 0 && !g_bIsRoundEnding)
	{
		// Round is Ending
		g_bIsRoundEnding = true
		
		// If Time is Out then Terminate the Round
		rg_round_end(get_pcvar_float(g_pCvarRoundEndDelay), WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "")
		
		// Show our Message
		client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
	}
}

public client_disconnected(id)
{
	// Reset speed for this dropped id
	g_bHSpeedUsed[id] = false
	g_bZSpeedUsed[id] = false
	
	// Execute our disconnected forward
	ExecuteForward(g_iForwards[FORWARD_DISCONNECT], g_iFwReturn, id)
	
	if (g_iFwReturn > 0)
	{
		// Here return, function ended here, below won't be executed
		return
	}
	
	// Delay Then Check Players to Terminate The round (Delay needed)
	set_task(0.1, "Check_AlivePlayers")
}

// This check done when player disconnect
public Check_AlivePlayers()
{
	g_iAliveZombiesNum = GetAlivePlayersNum(CsTeams:TEAM_TERRORIST)
	g_iAliveHumansNum = GetAlivePlayersNum(CsTeams:TEAM_CT)
	
	// Game Started? (There is at least 2 players Alive?)
	if (g_bGameStarted)
	{
		// We are in freeze time?
		if (get_member_game(m_bFreezePeriod))
		{
			// Humans alive number = 1 and no zombies?
			if (g_iAliveHumansNum < get_pcvar_num(g_pCvarReqPlayers))
			{
				// Game started false again
				g_bGameStarted = false
			}
		}
		else // Not freeze time?
		{
			// Variables
			new iAllZombiesNum = GetTeamPlayersNum(CsTeams:TEAM_TERRORIST),
			iAllHumansNum = GetTeamPlayersNum(CsTeams:TEAM_CT),
			iDeadZombiesNum = GetDeadPlayersNum(CsTeams:TEAM_TERRORIST),
			iDeadHumansNum = GetDeadPlayersNum(CsTeams:TEAM_CT)
	
			// Alive humans number = 1 and no zombies at all, And no dead humans?
			if (g_iAliveHumansNum < get_pcvar_num(g_pCvarReqPlayers) && iDeadHumansNum == 0 && iAllZombiesNum == 0)
			{
				// Game started is false and humans wins (Escape Success)
				g_bGameStarted = false
				rg_round_end(get_pcvar_float(g_pCvarRoundEndDelay), WINSTATUS_CTS, ROUND_CTS_WIN, "")
				client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
			}
			
			// Alive zombies number = 1 and no humans at all, And no dead zombies?
			if (g_iAliveZombiesNum < get_pcvar_num(g_pCvarReqPlayers) && iDeadZombiesNum == 0 && iAllHumansNum == 0)
			{
				// Game started is false and zombies wins (Escape Fail)
				g_bGameStarted = false
				rg_round_end(get_pcvar_float(g_pCvarRoundEndDelay), WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "")
				client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
			}
			
			// Humans number more than 1 and no zombies?
			if (g_iAliveHumansNum >= get_pcvar_num(g_pCvarReqPlayers) && g_iAliveZombiesNum == 0 && !g_bIsRoundEnding)
			{
				// Then Escape success as there is no Zombies
				rg_round_end(get_pcvar_float(g_pCvarRoundEndDelay), WINSTATUS_CTS, ROUND_CTS_WIN, "")
				client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
			}
			
			// Zombies number more than 1 and no humans?
			if (g_iAliveZombiesNum >= get_pcvar_num(g_pCvarReqPlayers) && g_iAliveHumansNum == 0 && !g_bIsRoundEnding)
			{
				// Then Escape Fail as there is no humans
				rg_round_end(get_pcvar_float(g_pCvarRoundEndDelay), WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "")
				client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
			}
		}
	}
}

public client_putinserver(id)
{
	// Add Delay and Check Conditions To start the Game (Delay needed)
	set_task(1.0, "Check_AllPlayersNumber", _, _, _, "b")
}

public Fw_HandleMenu_ChooseTeam_Post(id, MenuChooseTeam:iSlot)
{
	// Add Delay and Check Conditions To start the Game (Delay needed)
	set_task(1.0, "Check_AllPlayersNumber", _, _, _, "b")
}

public Check_AllPlayersNumber(TaskID)
{
	if (g_bGameStarted)
	{
		// If game started remove the task and block the blew Checks
		remove_task(TaskID)
		return
	}
	
	if (GetAllAlivePlayersNum() >= get_pcvar_num(g_pCvarReqPlayers))
	{
		// Players In server == The Required so game started is true
		g_bGameStarted = true
		
		// Restart the game
		server_cmd("sv_restart 2")
		
		// Print Fake game Commencing Message
		client_print(0, print_center, "%L", LANG_PLAYER, "START_GAME")
		
		// Remove the task
		remove_task(TaskID)
	}
}

public Set_User_Human(id)
{
	if (!is_user_alive(id))
		return
	
	g_bIsZombie[id] = false
	set_entvar(id, var_health, get_pcvar_float(g_pCvarHumanHealth))
	set_entvar(id, var_gravity, get_pcvar_float(g_pCvarHumanGravity)/800.0)
	ExecuteForward(g_iForwards[FORWARD_HUMANIZED], g_iFwReturn, id)
	
	// Reset Nightvision (Useful for antidote, so when someone use sethuman native the nightvision also reset)
	Set_NightVision(id, 0, 0, 0x0000, 0, 0, 0, 0)
	
	if (get_member(id, m_iTeam) != TEAM_CT)
		rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED)
}

public Set_User_Zombie(id)
{
	if (!is_user_alive(id))
		return
	
	g_bIsZombie[id] = true
	set_entvar(id, var_health, get_pcvar_float(g_pCvarZombieHealth))
	set_entvar(id, var_gravity, get_pcvar_float(g_pCvarZombieGravity)/800.0)
	rg_remove_all_items(id)
	rg_give_item(id, "weapon_knife", GT_APPEND)
	ExecuteForward(g_iForwards[FORWARD_INFECTED], g_iFwReturn, id, 0)
	
	if (get_member(id, m_iTeam) != TEAM_TERRORIST)
		rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED)
}

public Map_Restart()
{
	// Add Delay To help Rest Scores if player kill himself, and there no one else him so round draw (Delay needed)
	set_task(0.1, "Reset_Score_Message")
}

public Reset_Score_Message()
{
	g_iHumansScore = 0
	g_iZombiesScore = 0
	g_iRoundNum = 0
}

public plugin_end()
{
	if (get_pcvar_num(g_pCvarSmartRandom))
	{
		ArrayDestroy(g_aChosenPlayers)
	}
}

// Natives
public native_ze_is_user_zombie(id)
{
	if (!is_user_connected(id))
	{
		return -1;
	}
	
	return g_bIsZombie[id]
}

public native_ze_set_user_zombie(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	Set_User_Zombie(id)
	return true;
}

public native_ze_set_user_human(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	Set_User_Human(id)
	return true;
}

public native_ze_is_game_started()
{
	return g_bGameStarted
}

public native_ze_is_zombie_frozen(id)
{
	if (!is_user_connected(id) || !g_bIsZombie[id])
	{
		return -1;
	}
	
	return g_bIsZombieFrozen[id]
}

public native_ze_get_round_number()
{
	if (!g_bGameStarted)
	{
		return -1;
	}
	
	return g_iRoundNum
}

public native_ze_get_humans_number()
{
	return GetAlivePlayersNum(CsTeams:TEAM_CT)
}

public native_ze_get_zombies_number()
{
	return GetAlivePlayersNum(CsTeams:TEAM_TERRORIST)
}

public native_ze_set_human_speed_factor(id, iFactor)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	g_bHSpeedUsed[id] = true
	g_iHSpeedFactor[id] = iFactor
	rg_reset_maxspeed(id)
	return true;
}

public native_ze_reset_human_speed(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	g_bHSpeedUsed[id] = false
	rg_reset_maxspeed(id)
	return true;
}

public native_ze_set_zombie_speed(id, iSpeed)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	g_bZSpeedUsed[id] = true
	g_iZSpeedSet[id] = iSpeed
	return true;
}

public native_ze_reset_zombie_speed(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	g_bZSpeedUsed[id] = false
	return true;
}