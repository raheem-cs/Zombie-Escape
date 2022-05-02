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
	FORWARD_ZOMBIE_APPEAR_EX,
	FORWARD_ZOMBIE_RELEASE,
	FORWARD_GAME_STARTED_PRE,
	FORWARD_GAME_STARTED,
	FORWARD_DISCONNECT
}

new g_iForwards[TOTAL_FORWARDS], g_iFwReturn

// Tasks IDs
enum
{
	TASK_COUNTDOWN = 1100,
	TASK_COUNTDOWN2,
	TASK_SCORE_MESSAGE,
	ZOMBIES_SPEED,
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
	g_iUserGravity[33],
	bool:g_bGameStarted, 
	bool:g_bIsGameStarted,
	bool:g_bIsZombie[33], 
	bool:g_bIsZombieFrozen[33], 
	bool:g_bZombieFreezeTime, 
	bool:g_bIsRoundEnding,
	bool:g_bHSpeedUsed[33], 
	bool:g_bZSpeedUsed[33],
	bool:g_bEndCalled,
	bool:g_bIsKnockBackUsed[33],
	bool:g_bIsGravityUsed[33],
	bool:g_bEnteredNotChoosed[33],
	bool:g_bDisconnectHumanWin,
	Float:g_flReferenceTime,
	Float:g_flUserKnockback[33]

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
	g_pCvarSmartRandom,
	g_pCvarWinMessageType
	
// Trie's.
new Trie:g_tChosenPlayers

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
	
	register_native("ze_get_user_knockback", "native_ze_get_user_knockback", 1)
	register_native("ze_set_user_knockback", "native_ze_set_user_knockback", 1)
	register_native("ze_reset_user_knockback", "native_ze_reset_user_knockback", 1)
	
	register_native("ze_set_user_gravity", "native_ze_set_user_gravity", 1)
	register_native("ze_reset_user_gravity", "native_ze_reset_user_gravity", 1)
	
	register_native("ze_remove_zombie_freeze_msg", "native_ze_remove_zombie_freeze_msg", 1)

	register_native("ze_force_start_gamemode", "native_ze_force_start_gamemode", 0)
	register_native("ze_is_gamemode_started", "native_ze_is_gamemode_started", 0)
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
	RegisterHookChain(RG_HandleMenu_ChooseAppearance, "Fw_HandleMenu_ChoosedAppearance_Post", 1)
	
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
	g_iForwards[FORWARD_ZOMBIE_APPEAR_EX] = CreateMultiForward("ze_zombie_appear_ex", ET_IGNORE, FP_STRING, FP_CELL)
	g_iForwards[FORWARD_ZOMBIE_RELEASE] = CreateMultiForward("ze_zombie_release", ET_IGNORE)
	g_iForwards[FORWARD_GAME_STARTED_PRE] = CreateMultiForward("ze_game_started_pre", ET_CONTINUE)
	g_iForwards[FORWARD_GAME_STARTED] = CreateMultiForward("ze_game_started", ET_IGNORE)
	g_iForwards[FORWARD_DISCONNECT] = CreateMultiForward("ze_player_disconnect", ET_CONTINUE, FP_CELL)
	
	// Hud Messages
	g_iReleaseNotice = CreateHudSyncObj()
	
	// Registering Messages
	register_message(get_user_msgid("TeamScore"), "Message_Teamscore")
	
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
	g_pCvarWinMessageType = register_cvar("ze_winmessage_type", "0")

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
	
	// Create our Trie to store SteamIDs in.
	g_tChosenPlayers = TrieCreate()

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
	static Float:flMaxSpeed
	get_entvar(id, var_maxspeed, flMaxSpeed)

	// Player is Alive and not Frozen?
	if (is_user_alive(id) && flMaxSpeed != 1.0)
	{
		// Player is Human?
		if (!g_bIsZombie[id])
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
		else // Zombie.
		{
			if (g_bZombieFreezeTime)
			{
				// Freeze Zombie.
				set_entvar(id, var_maxspeed, 1.0)
				return HC_CONTINUE
			}

			// Zombie have custom maxspeed?
			if (g_bZSpeedUsed[id])
			{
				// Set zombie maxspeed from native.
				set_entvar(id, var_maxspeed, float(g_iZSpeedSet[id]))
				return HC_CONTINUE
			}

			// Set Zombie maxspeed from cvar.
			set_entvar(id, var_maxspeed, get_pcvar_float(g_pCvarZombieSpeed))
			return HC_CONTINUE
		}		
	}
	
	// Prevent resetting player maxspeed.
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
	remove_task(ZOMBIES_SPEED)
	
	if (g_bGameStarted)
	{
		g_iRoundNum++
	}
	
	ExecuteForward(g_iForwards[FORWARD_GAME_STARTED_PRE], g_iFwReturn)
	
	if (g_iFwReturn >= ZE_STOP)
		return
	
	// Score Message Task
	set_task(10.0, "Score_Message", TASK_SCORE_MESSAGE, _, _, "b")
	
	if (!g_bGameStarted)
	{
		// No Enough Players
		ze_colored_print(0, "%L", LANG_PLAYER, "NO_ENOUGH_PLAYERS", get_pcvar_num(g_pCvarReqPlayers))
		return // Block the execution of the blew code 
	}
	
	if (g_iRoundNum == 1)
	{
		// 2 is Hardcoded Value, It's Fix for the countdown to work correctly first round
		g_iCountDown = get_member_game(m_iIntroRoundTime) - 2
	}
	else
	{
		// 3 is Hardcoded Value, It's Fix for the countdown to work correctly after first round
		g_iCountDown = get_member_game(m_iIntroRoundTime) - 3
	}
	
	// Game Already started, Countdown now started
	set_task(1.0, "Countdown_Start", TASK_COUNTDOWN, _, _, "b")
	ze_colored_print(0, "%L", LANG_PLAYER, "READY_TO_RUN")
	ExecuteForward(g_iForwards[FORWARD_GAME_STARTED], g_iFwReturn)
	
	// Round Starting
	g_bIsRoundEnding = false
	g_bEndCalled = false
	g_bIsGameStarted = false
}

// Score Message Task
public Score_Message(TaskID)
{
	// If value is 0, there is nothing to do for this case this means CVAR is disabled
	switch(get_pcvar_num(g_pCvarScoreMessageType))
	{
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
	// Check if the players Disconnected and there is only one player then remove all messages, and stop tasks (+Stop sounds)
	if (!g_bGameStarted)
	{
		StopSound()
		remove_task(TaskID) // Remove the task
		return
	}
	
	if (!g_iCountDown)
	{
		Choose_Zombies()
		remove_task(TaskID) // Remove the task
		return // Block the execution of the blew code
	}
	
	set_hudmessage(random(256), random(256), random(256), -1.0, 0.21, 0, 0.8, 0.8)
	show_hudmessage(0, "%L", LANG_PLAYER, "RUN_NOTICE", g_iCountDown--)
}

public Choose_Zombies()
{
	new iFirstZombies[MAX_CLIENTS], iZombies, id, iAliveCount
	new szAuthId[34], iReqZombies
	
	// Get total alive players and required players
	iAliveCount  = GetAllAlivePlayersNum()
	iReqZombies = RequiredZombies()

	// Check smart random is enabled or not.
	new bool:bSmartRandom = get_pcvar_num(g_pCvarSmartRandom) ? true : false

	// Get health of first Zombies.
	new Float:flHealth = get_pcvar_float(g_pCvarFirstZombiesHealth)

	// Loop till we find req players
	while(iZombies < iReqZombies)
	{
		id = GetRandomAlive(random_num(1, iAliveCount))
		
		if (!is_user_alive(id) || g_bIsZombie[id])
			continue
		
		// Get authid (SteamID) of the player.
		get_user_authid(id, szAuthId, charsmax(szAuthId))

		// Check if CVAR enabled and if player in the Trie, it means he chosen previous round so skip him this round
		if (bSmartRandom && TrieKeyExists(g_tChosenPlayers, szAuthId))
			continue

		// Infect player.
		Set_User_Zombie(id)
		set_entvar(id, var_health, flHealth)

		// Set zombie Frozen flag 
		g_bIsZombieFrozen[id] = true

		// Store IDs of first Zombies in Array.
		iFirstZombies[iZombies] = id

		// New Zombie.
		iZombies++
	}
	
	if (iZombies > 0)
	{
		// Freeze all Zombies.
		g_bZombieFreezeTime = true

		// Execute forward ze_zombie_appear().
		ExecuteForward(g_iForwards[FORWARD_ZOMBIE_APPEAR])

		// Execute forward ze_zombie_appear_ex(const iZombies[], iZombieNum)
		ExecuteForward(g_iForwards[FORWARD_ZOMBIE_APPEAR_EX], _/* No return value */, iFirstZombies, iZombies)
	}
	
	if (bSmartRandom)
	{
		// Clear the Trie first
		TrieClear(g_tChosenPlayers)
		
		// Add steamid of chosen zombies, so we don't choose them next round again (using steamid means it support reconnect)
		for (id = 1; id <= g_iMaxClients; id++)
		{
			if(!is_user_connected(id) || !g_bIsZombie[id])
				continue
			
			get_user_authid(id, szAuthId, charsmax(szAuthId))
			
			TrieSetCell(g_tChosenPlayers, szAuthId, 0)
		}
	}
	
	// Gamemode is started.
	g_bIsGameStarted = true

	// 2 is Hardcoded Value, It's Fix for the countdown to work correctly
	g_iCountDown = get_pcvar_num(g_pCvarZombieReleaseTime) - 2
	
	set_task(1.0, "ReleaseZombie_CountDown", TASK_COUNTDOWN2, _, _, "b")
}

public ReleaseZombie_CountDown(TaskID)
{
	if (!g_iCountDown)
	{
		ReleaseZombie()
		remove_task(TaskID)
		return
	}
	
	// Release Hud Message
	set_hudmessage(255, 255, 0, -1.0, 0.21, 1, 2.0, 2.0)
	ShowSyncHudMsg(0, g_iReleaseNotice, "%L", LANG_PLAYER, "ZOMBIE_RELEASE", g_iCountDown--)
}

public ReleaseZombie()
{
	ExecuteForward(g_iForwards[FORWARD_ZOMBIE_RELEASE], g_iFwReturn)
	
	g_bZombieFreezeTime = false
	
	for(new id = 1; id <= g_iMaxClients; id++)
	{
		if (is_user_alive(id) && g_bIsZombie[id])
		{
			g_bIsZombieFrozen[id] = false
			rg_reset_maxspeed(id)
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
	if (g_bZombieFreezeTime)
		return HC_SUPERCEDE
	
	if (g_bIsZombie[iAttacker])
	{
		g_iAliveHumansNum = GetAlivePlayersNum(CsTeams:TEAM_CT)
		
		if (!Set_User_Zombie(iVictim, iAttacker, flDamage))
			return HC_SUPERCEDE
		
		if (g_iAliveHumansNum == 1) // Check if this is Last Human, Because of Delay i can't check if it's 0 instead of 1
		{
			// End round event called one time
			g_bEndCalled = true
			
			// Round is Ending
			g_bIsRoundEnding = true
			
			// Zombie Win, Show message win and finish the round.
			Finish_Round(ZE_TEAM_ZOMBIE)
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
		
		// Knockback is disabled from native.
		if (g_bIsKnockBackUsed[iVictim] && g_flUserKnockback[iVictim] <= 0.0)
			return HC_CONTINUE

		// Get knockback of Zombie.
		static Float:flKnockback
		flKnockback = get_pcvar_float(g_pCvarZombieKnockback)

		// Knockback is disabled from Cvar.
		if (flKnockback <= 0.0)
			return HC_CONTINUE

		// Set Knockback
		static Float:flOrigin[3]
		get_entvar(iAttacker, var_origin, flOrigin)
		Set_Knockback(iVictim, flOrigin, g_bIsKnockBackUsed[iVictim] ? g_flUserKnockback[iVictim] : flKnockback, 2)
	}
	
	return HC_CONTINUE
}

public Round_End()
{
	g_iAliveZombiesNum = GetAlivePlayersNum(CsTeams:TEAM_TERRORIST)
	g_iAliveHumansNum = GetAlivePlayersNum(CsTeams:TEAM_CT)
	
	if ((g_iAliveZombiesNum == 0 && g_bGameStarted) || (g_bDisconnectHumanWin))
	{
		// Show message win and call forward ze_roundend(iWinTeam).
		Finish_Round(ZE_TEAM_HUMAN, true, false)
		g_iHumansScore++
		g_bIsRoundEnding = true
		g_bDisconnectHumanWin = false
		return // To block Execute the code blew
	}
	
	g_iZombiesScore++
	g_bIsRoundEnding = true
	
	// If it's already called one time, don't call it again
	if (!g_bEndCalled)
	{
		// Show message win and call forward ze_roundend(iWinTeam)
		Finish_Round(ZE_TEAM_ZOMBIE, true, false)
	}
	else 
	{
		// Show only message win.
		Finish_Round(ZE_TEAM_ZOMBIE, false, false)	
	}
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
	
	if (floatround(flRoundTimeLeft) == 0 && !g_bIsRoundEnding && !get_member_game(m_bFreezePeriod))
	{
		// Round is Ending
		g_bIsRoundEnding = true
		
		// Show message win and finish round.
		Finish_Round(ZE_TEAM_ZOMBIE, false, true)
	}
}

public client_disconnected(id)
{
	// Reset speed for this dropped id
	g_bHSpeedUsed[id] = false
	g_bZSpeedUsed[id] = false
	g_bIsKnockBackUsed[id] = false
	g_bIsGravityUsed[id] = false
	g_flUserKnockback[id] = 0.0
	g_iUserGravity[id] = 0
	
	remove_task(id)
	
	// Execute our disconnected forward
	ExecuteForward(g_iForwards[FORWARD_DISCONNECT], g_iFwReturn, id)
	
	if (g_iFwReturn >= ZE_STOP)
		return
	
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
		// Get the required number of players.
		new iReqPlayers = get_pcvar_num(g_pCvarReqPlayers)

		// We are in freeze time?
		if (get_member_game(m_bFreezePeriod))
		{
			// Humans alive number = 1 and no zombies?
			if (g_iAliveHumansNum < iReqPlayers)
			{
				// Game started false again
				g_bGameStarted = false
			}
		}
		else // Not freeze time?
		{
			// Variables
			new iAllZombiesNum = get_member_game(m_iNumTerrorist),
			iAllHumansNum = get_member_game(m_iNumCT),
			iDeadZombiesNum = GetDeadPlayersNum(CsTeams:TEAM_TERRORIST),
			iDeadHumansNum = GetDeadPlayersNum(CsTeams:TEAM_CT)
	
			// Alive humans number = 1 and no zombies at all, And no dead humans?
			if (g_iAliveHumansNum < iReqPlayers && iDeadHumansNum == 0 && iAllZombiesNum == 0)
			{
				// Game started is false and humans wins (Escape Success)
				g_bGameStarted = false
				g_bDisconnectHumanWin = true
				Finish_Round(ZE_TEAM_HUMAN, false, true)
			}
			
			// Alive zombies number = 1 and no humans at all, And no dead zombies?
			else if (g_iAliveZombiesNum < iReqPlayers && iDeadZombiesNum == 0 && iAllHumansNum == 0)
			{
				// Game started is false and zombies wins (Escape Fail)
				g_bGameStarted = false
				Finish_Round(ZE_TEAM_ZOMBIE, false, true)
			}
			
			// Humans number more than 1 and no zombies?
			else if (g_iAliveHumansNum >= iReqPlayers && g_iAliveZombiesNum == 0 && !g_bIsRoundEnding)
			{
				// Then Escape success as there is no Zombies
				Finish_Round(ZE_TEAM_HUMAN, false, true)
			}
			
			// Zombies number more than 1 and no humans?
			else if (g_iAliveZombiesNum >= iReqPlayers && g_iAliveHumansNum == 0 && !g_bIsRoundEnding)
			{
				// Then Escape Fail as there is no humans
				Finish_Round(ZE_TEAM_ZOMBIE, false, true)
			}
		}
	}
}

public client_putinserver(id)
{
	// Add Delay and Check Conditions To start the Game (Delay needed)
	set_task(1.0, "Check_AllPlayersNumber", _, _, _, "b")
	
	// Check for dead terrorists - Bug fix
	set_task(0.1, "CheckTerrorists", id, _, _, "b")
}

public CheckTerrorists(id)
{
	if (g_bEnteredNotChoosed[id] && g_bGameStarted)
	{
		if (is_user_connected(id))
		{
			rg_join_team(id, TEAM_CT) // Force user to choose CT
			g_bEnteredNotChoosed[id] = false
		}
	}
}

public Fw_HandleMenu_ChoosedAppearance_Post(const index, const slot)
{
	g_bEnteredNotChoosed[index] = false
}

public Fw_HandleMenu_ChooseTeam_Post(id, MenuChooseTeam:iSlot)
{
	// Fixing Dead-T restarting the round
	if (iSlot == MenuChoose_T) // Choosed T, Still not choosed a player
	{
		g_bEnteredNotChoosed[id] = true
	}
	
	if ((iSlot == MenuChoose_AutoSelect) && (get_member(id, m_iTeam) == TEAM_TERRORIST))
	{
		g_bEnteredNotChoosed[id] = true
	}
	
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

Set_User_Human(id)
{
	if (!is_user_alive(id))
		return
	
	g_bIsZombie[id] = false
	set_entvar(id, var_health, get_pcvar_float(g_pCvarHumanHealth))
	set_entvar(id, var_gravity, float(g_bIsGravityUsed[id] ? g_iUserGravity[id]:get_pcvar_num(g_pCvarHumanGravity))/800.0)
	ExecuteForward(g_iForwards[FORWARD_HUMANIZED], g_iFwReturn, id)
	
	// Reset Nightvision (Useful for antidote, so when someone use sethuman native the nightvision also reset)
	Set_NightVision(id, 0, 0, 0x0000, 0, 0, 0, 0)
	
	if (get_member(id, m_iTeam) != TEAM_CT)
		rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED)
}

Set_User_Zombie(id, iAttacker = 0, Float:flDamage = 0.0)
{
	if (!is_user_alive(id))
		return false
		
	// Execute pre-infection forward
	ExecuteForward(g_iForwards[FORWARD_PRE_INFECTED], g_iFwReturn, id, iAttacker, floatround(flDamage))
	
	if (g_iFwReturn >= ZE_STOP)
	{
		return false
	}
	
	if (iAttacker > 0)
	{
		// Death Message with Infection style, only if infection caused by player not server
		SendDeathMsg(iAttacker, id)
	}
	
	g_bIsZombie[id] = true
	set_entvar(id, var_health, get_pcvar_float(g_pCvarZombieHealth))
	set_entvar(id, var_gravity, float(g_bIsGravityUsed[id] ? g_iUserGravity[id] : get_pcvar_num(g_pCvarZombieGravity))/800.0)
	rg_remove_all_items(id)
	rg_give_item(id, "weapon_knife", GT_APPEND)
	ExecuteForward(g_iForwards[FORWARD_INFECTED], g_iFwReturn, id, iAttacker)
	
	if (get_member(id, m_iTeam) != TEAM_TERRORIST)
		rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED)
	
	return true
}

Finish_Round(iTeam, bool:bCallForward = true, bool:bForceEnd = true)
{
	// Get round end delay
	new Float:flRoundEndDelay = get_pcvar_float(g_pCvarRoundEndDelay)

	switch (iTeam)
	{
		case ZE_TEAM_HUMAN:
		{
			if (bCallForward)
			{
				// Execute forward ze_roundend(iWinTeam).
				ExecuteForward(g_iForwards[FORWARD_ROUNDEND], _/* No return value */, ZE_TEAM_HUMAN)
			}

			if (bForceEnd)
			{
				// Finish the round, and make Humans are winners.
				rg_round_end(flRoundEndDelay, WINSTATUS_CTS, ROUND_CTS_WIN, "", "")
			}

			// Get HUD type of win message.
			switch (get_pcvar_num(g_pCvarWinMessageType))
			{
				case 0: // Normal Text print_center.
					client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
				case 1: // HUD
				{
					set_hudmessage(0, 100, 200, -1.0, 0.4, 1, flRoundEndDelay, flRoundEndDelay, 0.0, 0.0)
					show_hudmessage(0, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
				}
				case 2: // DHUD
				{
					set_dhudmessage(0, 100, 200, -1.0, 0.4, 1, flRoundEndDelay, flRoundEndDelay, 0.0, 0.0)
					show_dhudmessage(0, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")				
				}
			}
		}
		case ZE_TEAM_ZOMBIE:
		{
			if (bCallForward)
			{
				// Execute forward ze_roundend(iWinTeam).
				ExecuteForward(g_iForwards[FORWARD_ROUNDEND], _/* No return value */, ZE_TEAM_ZOMBIE)
			}

			if (bForceEnd)
			{
				// Finish the round, and make Zombies are winners.
				rg_round_end(flRoundEndDelay, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "", "")
			}

			// Get HUD type of win message.
			switch (get_pcvar_num(g_pCvarWinMessageType))
			{
				case 0: // Normal Text print_center.
					client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
				case 1: // HUD
				{
					set_hudmessage(200, 0, 0, -1.0, 0.4, 1, flRoundEndDelay, flRoundEndDelay, 0.0, 0.0)
					show_hudmessage(0, "%L", LANG_PLAYER, "ESCAPE_FAIL")
				}
				case 2: // DHUD
				{
					set_dhudmessage(200, 0, 0, -1.0, 0.4, 1, flRoundEndDelay, flRoundEndDelay, 0.0, 0.0)
					show_dhudmessage(0, "%L", LANG_PLAYER, "ESCAPE_FAIL")				
				}
			}
		}
	}
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
	// Destroy Trie.
	TrieDestroy(g_tChosenPlayers)
}

public Message_Teamscore()
{
	new szTeam[2]
	get_msg_arg_string(1, szTeam, charsmax(szTeam))
	
	switch (szTeam[0])
	{
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_iHumansScore)
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_iZombiesScore)
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

public native_ze_get_user_knockback(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return -1
	}

	return floatround(g_bIsKnockBackUsed[id] ? g_flUserKnockback[id]:get_pcvar_float(g_pCvarZombieKnockback))
}

public native_ze_set_user_knockback(id, Float:flKnockback)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}
	
	g_bIsKnockBackUsed[id] = true
	g_flUserKnockback[id] = flKnockback
	return true
}

public native_ze_reset_user_knockback(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}

	g_bIsKnockBackUsed[id] = false
	g_flUserKnockback[id] = 0.0
	return true
}

public native_ze_set_user_gravity(id, iGravity)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}
	
	g_bIsGravityUsed[id] = true
	g_iUserGravity[id] = iGravity
	set_entvar(id, var_gravity, float(iGravity) / 800.0)

	return true
}

public native_ze_reset_user_gravity(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}

	g_bIsGravityUsed[id] = false
	set_entvar(id, var_gravity, float(g_bIsZombie[id] ? get_pcvar_num(g_pCvarZombieGravity):get_pcvar_num(g_pCvarHumanGravity)) / 800.0)

	return true
}

public native_ze_remove_zombie_freeze_msg()
{
	if (task_exists(TASK_COUNTDOWN2))
	{
		remove_task(TASK_COUNTDOWN2)
		return true
	}
	
	return false
}

public native_ze_force_start_gamemode()
{
	// Gamemode is already started?
	if (g_bIsGameStarted)
		return false

	// Remove countdown.
	if (task_exists(TASK_COUNTDOWN))
		remove_task(TASK_COUNTDOWN)

	// Start gamemode.
	Choose_Zombies()
	return true
}

public native_ze_is_gamemode_started()
{
	if (g_bIsGameStarted)
		return true
	return false
}