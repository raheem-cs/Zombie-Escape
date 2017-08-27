#include <zombie_escape>

// Fowards
enum _:TOTAL_FORWARDS
{
	FORWARD_NONE = 0,
	FORWARD_ROUNDEND,
	FORWARD_HUMANIZED,
	FORWARD_INFECTED,
	FORWARD_ZOMBIE_APPEAR,
	FORWARD_ZOMBIE_RELEASE,
	FORWARD_GAME_STARTED
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

// Variables
new g_iAliveCTNum, g_iAliveTNum, g_iRoundTime, g_iCountDown, g_iReleaseNotice, g_iMaxClients, g_iHumansScore, g_iZombiesScore,
bool:g_bGameStarted, bool:g_bIsZombie[33], bool:g_bIsZombieFrozen[33], bool:g_bZombieFrozenTime, bool:g_bIsRoundEnding,
Float:g_fReferenceTime

// Cvars
new Cvar_Human_fSpeedFactor, Cvar_Human_fGravity, Cvar_Human_iHealth, Cvar_Zombie_fSpeed, Cvar_Zombie_fGravity,
Cvar_Zombie_iReleaseTime, Cvar_iFreezeTime, Cvar_fRoundTime, Cvar_iReqPlayers, Cvar_Zombie_iHealth, Cvar_FirstZombies_iHealth,
Cvar_Zombie_fKnockback, Cvar_ScoreMessage_iType, Cvar_ScoreMessage_iRed, Cvar_ScoreMessage_iGreen, Cvar_ScoreMessage_iBlue

public plugin_natives()
{
	register_native("ze_is_user_zombie", "native_ze_is_user_zombie", 1)
	register_native("ze_set_user_zombie", "native_ze_set_user_zombie", 1)
	register_native("ze_set_user_human", "native_ze_set_user_human", 1)
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
	
	// Events
	register_event("HLTV", "New_Round", "a", "1=0", "2=0")
	register_event("TextMsg", "Map_Restart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in", "2=#Round_Draw")
	register_logevent("Round_Start", 2, "1=Round_Start")
	register_logevent("Round_End", 2, "1=Round_End")
	
	// Hams
	RegisterHam(Ham_Item_PreFrame, "player", "Fw_RestMaxSpeed_Post", 1)
	
	// Create Forwards (All Return Values Ignored)
	g_iForwards[FORWARD_ROUNDEND] = CreateMultiForward("ze_roundend", ET_IGNORE, FP_CELL)
	g_iForwards[FORWARD_HUMANIZED] = CreateMultiForward("ze_user_humanized", ET_IGNORE, FP_CELL)
	g_iForwards[FORWARD_INFECTED] = CreateMultiForward("ze_user_infected", ET_IGNORE, FP_CELL, FP_CELL)
	g_iForwards[FORWARD_ZOMBIE_APPEAR] = CreateMultiForward("ze_zombie_appear", ET_IGNORE)
	g_iForwards[FORWARD_ZOMBIE_RELEASE] = CreateMultiForward("ze_zombie_release", ET_IGNORE)
	g_iForwards[FORWARD_GAME_STARTED] = CreateMultiForward("ze_game_started", ET_IGNORE)
	
	// Hud Messages
	g_iReleaseNotice = CreateHudSyncObj()
	
	// Sequential files (.txt)
	register_dictionary("zombie_escape.txt")
	
	// Humans Cvars
	Cvar_Human_fSpeedFactor = register_cvar("ze_human_speed_factor", "20.0")
	Cvar_Human_fGravity = register_cvar("ze_human_gravity", "800")
	Cvar_Human_iHealth = register_cvar("ze_human_health", "1000")
	
	// Zombie Cvars
	Cvar_Zombie_fSpeed = register_cvar("ze_zombie_speed", "350.0")
	Cvar_Zombie_fGravity = register_cvar("ze_zombie_gravity", "640")
	Cvar_Zombie_iHealth = register_cvar("ze_zombie_health", "10000")
	Cvar_FirstZombies_iHealth = register_cvar("ze_first_zombies_health", "20000")
	Cvar_Zombie_fKnockback = register_cvar("ze_zombie_knockback", "300.0")
	
	// General Cvars
	Cvar_Zombie_iReleaseTime = register_cvar("ze_release_time", "15")
	Cvar_iFreezeTime = register_cvar("ze_freeze_time", "20")
	Cvar_fRoundTime = register_cvar("ze_round_time", "9.0")
	Cvar_iReqPlayers = register_cvar("ze_required_players", "2")
	Cvar_ScoreMessage_iType = register_cvar("ze_score_message_type", "1")
	Cvar_ScoreMessage_iRed = register_cvar("ze_score_message_red", "200")
	Cvar_ScoreMessage_iGreen = register_cvar("ze_score_message_green", "100")
	Cvar_ScoreMessage_iBlue = register_cvar("ze_score_message_blue", "0")
	
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
}

public Fw_CheckMapConditions_Post()
{
	// Block Game Commencing
	set_member_game(m_bGameStarted, true)
	
	// Set Freeze Time
	set_member_game(m_iIntroRoundTime, get_pcvar_num(Cvar_iFreezeTime))
	
	// Set Round Time
	set_member_game(m_iRoundTime, floatround(get_pcvar_float(Cvar_fRoundTime) * 60.0))
}

public Fw_PlayerKilled_Post(id)
{
	new iCTNum; iCTNum = GetAlivePlayersNum(CsTeams:TEAM_CT)
	new iTNum; iTNum = GetAlivePlayersNum(CsTeams:TEAM_TERRORIST)
	
	if (iCTNum == 0 && iTNum == 0)
	{
		// No Winner, All Players in one team killed Or Both teams Killed
		client_print(0, print_center, "%L", LANG_PLAYER, "NO_WINNER")
	}
}

public Fw_RestMaxSpeed_Post(id)
{
	if (!g_bIsZombie[id])
	{
		static Float:fMaxSpeed
		get_entvar(id, var_maxspeed, fMaxSpeed)
		
		if(fMaxSpeed != 1.0 && is_user_alive(id))
		{
			// Set Human Speed Factor
			set_entvar(id, var_maxspeed, fMaxSpeed + get_pcvar_float(Cvar_Human_fSpeedFactor))
			return HAM_IGNORED
		}
	}
	return HAM_SUPERCEDE
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
			if (g_bZombieFrozenTime)
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
		ze_colored_print(0, "%L", LANG_PLAYER, "NO_ENOUGH_PLAYERS", get_pcvar_num(Cvar_iReqPlayers))
		return // Block the execution of the blew code 
	}
	
	if (g_bGameStarted)
	{
		// Game Already started, Countdown now started
		set_task(1.0, "Countdown_Start", TASK_COUNTDOWN, _, _, "b")
		ze_colored_print(0, "%L", LANG_PLAYER, "READY_TO_RUN")
		ExecuteForward(g_iForwards[FORWARD_GAME_STARTED], g_iFwReturn)
		
		// Round Starting
		g_bIsRoundEnding = false
	}
}

// Score Message Task
public Score_Message(TaskID)
{
	if (get_pcvar_num(Cvar_ScoreMessage_iType) == 0)
		return
	
	if (get_pcvar_num(Cvar_ScoreMessage_iType) == 1)
	{
		set_dhudmessage(get_pcvar_num(Cvar_ScoreMessage_iRed), get_pcvar_num(Cvar_ScoreMessage_iGreen), get_pcvar_num(Cvar_ScoreMessage_iBlue), -1.0, 0.01, 0, 0.0, 9.0)
		show_dhudmessage(0, "%L", LANG_PLAYER, "SCORE_MESSAGE", g_iZombiesScore, g_iHumansScore)
	}
	else if (get_pcvar_num(Cvar_ScoreMessage_iType) == 2)
	{
		set_hudmessage(get_pcvar_num(Cvar_ScoreMessage_iRed), get_pcvar_num(Cvar_ScoreMessage_iGreen), get_pcvar_num(Cvar_ScoreMessage_iBlue), -1.0, 0.01, 0, 0.0, 9.0)
		show_hudmessage(0, "%L", LANG_PLAYER, "SCORE_MESSAGE", g_iZombiesScore, g_iHumansScore)
	}
}

public Countdown_Start(TaskID)
{
	// Check if the players Disconnected and there is only one player then remove all messages, and stop tasks
	if (!g_bGameStarted)
		return
	
	if (!g_iCountDown) // When it reach 0 the !0 will be 1 So it's True
	{
		Choose_Zombies()
		remove_task(TaskID) // Remove the task
		return // Block the execution of the blew code
	}
	
	set_hudmessage(random(256), random(256), random(256), -1.0, 0.21, 0, 0.8, 0.8)
	show_hudmessage(0, "%L", LANG_PLAYER, "RUN_NOTICE", g_iCountDown)

	g_iCountDown -- // Means: g_iCountDown = g_iCountDown -1
}

public Choose_Zombies()
{
	new iZombies, id, AliveCount; AliveCount  = GetAllAlivePlayersNum()
	new iReqZombies; iReqZombies = RequiredZombies()
	
	while (iZombies < iReqZombies)
	{
		id = GetRandomAlive(random_num(1, AliveCount))
		
		if (!is_user_alive(id) || g_bIsZombie[id])
			continue

		Set_User_Zombie(id)
		set_entvar(id, var_health, get_pcvar_float(Cvar_FirstZombies_iHealth))
		g_bIsZombieFrozen[id] = true
		g_bZombieFrozenTime = true
		set_entvar(id, var_maxspeed, 1.0)
		set_task(0.1, "Freeze_Zombies", FREEZE_ZOMBIES, _, _, "b") // Better than PreThink
		ExecuteForward(g_iForwards[FORWARD_ZOMBIE_APPEAR], g_iFwReturn)
		iZombies ++
	}
	
	// 2 is Hardcoded Value, It's Fix for the countdown to work correctly
	g_iCountDown = get_pcvar_num(Cvar_Zombie_iReleaseTime) - 2
	
	set_task(1.0, "ReleaseZombie_CountDown", TASK_COUNTDOWN2, _, _, "b")
}

public ReleaseZombie_CountDown(TaskID)
{
	if(!g_iCountDown)
	{
		ReleaseZombie()
		remove_task(TaskID)
		
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
	
	for(new i = 1; i <= g_iMaxClients; i++)
	{
		if(is_user_alive(i) && g_bIsZombie[i])
		{
			g_bIsZombieFrozen[i] = false
			g_bZombieFrozenTime = false
		}
	}
}

public Freeze_Zombies(TaskID)
{
	for(new i = 1; i <= g_iMaxClients; i++)
	{
		if(!is_user_alive(i))
			continue
		
		if (g_bIsZombieFrozen[i] && g_bIsZombie[i])
		{
			// Zombie & Frozen, then Freeze him
			set_entvar(i, var_maxspeed, 1.0)
		}
		
		if (!g_bIsZombieFrozen[i] && g_bIsZombie[i])
		{
			// Zombie but Not Frozen the set his speed form .cfg
			set_entvar(i, var_maxspeed, get_pcvar_float(Cvar_Zombie_fSpeed))
		}
	}
}

public Fw_TraceAttack_Pre(iVictim, iAttacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if (iVictim == iAttacker || !is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return HC_CONTINUE
	
	// Attacker and Victim is in same teams? Skip here only
	if (get_member(iAttacker, m_iTeam) == get_member(iVictim, m_iTeam))
		return HC_CONTINUE
	
	// In freeze time? Skip all other plugins
	if (g_bIsZombieFrozen[iVictim] || g_bIsZombieFrozen[iAttacker])
		return HC_SUPERCEDE
	
	g_iAliveCTNum = GetAlivePlayersNum(CsTeams:TEAM_CT)
	
	if (get_member(iAttacker, m_iTeam) == TEAM_TERRORIST)
	{
		// Death Message with Infection style [Added here because of delay in Forward use]
		SendDeathMsg(iAttacker, iVictim)
		
		Set_User_Zombie(iVictim)
		ExecuteForward(g_iForwards[FORWARD_INFECTED], g_iFwReturn, iVictim, iAttacker)
		
		if (g_iAliveCTNum == 1) // Check if this is Last Human, Because of Delay i can't check if it's 0 instead of 1
		{
			// Zombie Win, Leave text blank so we use ours from ML
			rg_round_end(3.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "")
			
			// Show Our Message
			client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
			
			// This needed so forward work also to add +1 for Zombies
			g_iTeam = 1 // ZE_TEAM_ZOMBIE
			ExecuteForward(g_iForwards[FORWARD_ROUNDEND], g_iFwReturn, g_iTeam)
			
			// Round is Ending
			g_bIsRoundEnding = true
		}
	}
	return HC_CONTINUE
}

public Fw_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType)
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
		static Float:fOrigin[3]
		get_entvar(iAttacker, var_origin, fOrigin)
		Set_Knockback(iVictim, fOrigin, get_pcvar_float(Cvar_Zombie_fKnockback), 2)
	}
	return HC_CONTINUE
}

public Round_End()
{
	g_iAliveTNum = GetAlivePlayersNum(CsTeams:TEAM_TERRORIST)
	g_iAliveCTNum = GetAlivePlayersNum(CsTeams:TEAM_CT)
	
	if (g_iAliveTNum == 0 && g_bGameStarted) 
	{
		g_iTeam = 2 // ZE_TEAM_HUMAN
		ExecuteForward(g_iForwards[FORWARD_ROUNDEND], g_iFwReturn, g_iTeam)
		client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
		g_iHumansScore ++
		g_bIsRoundEnding = true
		return // To block Execute the code blew
	}
	
	g_iTeam = 1 // ZE_TEAM_ZOMBIE
	g_iZombiesScore ++
	g_bIsRoundEnding = true
	ExecuteForward(g_iForwards[FORWARD_ROUNDEND], g_iFwReturn, g_iTeam)
	client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
}

public Round_Start()
{
    g_fReferenceTime = get_gametime()
    g_iRoundTime = get_member_game(m_iRoundTime)
}

public Check_RoundTimeleft()
{
	new Float:fRoundTimeLeft; fRoundTimeLeft = (g_fReferenceTime + float(g_iRoundTime)) - get_gametime()
	
	if (floatround(fRoundTimeLeft) == 0)
	{
		// If Time is Out then Terminate the Round
		rg_round_end(3.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "")
		
		// Show our Message
		client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
		
		// Round is Ending
		g_bIsRoundEnding = true
	}
}

public client_disconnected(id)
{
	// Delay Then Check Players to Terminate The round (Delay needed)
	set_task(0.1, "Check_AlivePlayers", _, _, _, "a", 1)
}

// This check done when player disconnect
public Check_AlivePlayers()
{
	g_iAliveTNum = GetAlivePlayersNum(CsTeams:TEAM_TERRORIST)
	g_iAliveCTNum = GetAlivePlayersNum(CsTeams:TEAM_CT)
	
	new iAllTNum = GetTeamPlayersNum(CsTeams:TEAM_TERRORIST),
	iAllCTNum = GetTeamPlayersNum(CsTeams:TEAM_CT),
	iDeadTNum = GetDeadPlayersNum(CsTeams:TEAM_TERRORIST),
	iDeadCTNum = GetDeadPlayersNum(CsTeams:TEAM_CT)
	
	// Game Started? (There is at least 2 players Alive?)
	if (g_bGameStarted)
	{
		// We are in freeze time?
		if (get_member_game(m_bFreezePeriod))
		{
			// Humans alive number = 1 and no zombies?
			if (g_iAliveCTNum < get_pcvar_num(Cvar_iReqPlayers))
			{
				// Game started false again
				g_bGameStarted = false
			}
		}
		else // Not freeze time?
		{
			// Alive humans number = 1 and no zombies at all, And no dead humans?
			if (g_iAliveCTNum < get_pcvar_num(Cvar_iReqPlayers) && iDeadCTNum == 0 && iAllTNum == 0)
			{
				// Game started is false and humans wins (Escape Success)
				g_bGameStarted = false
				rg_round_end(3.0, WINSTATUS_CTS, ROUND_CTS_WIN, "")
				client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
			}
			
			// Alive zombies number = 1 and no humans at all, And no dead zombies?
			if (g_iAliveTNum < get_pcvar_num(Cvar_iReqPlayers) && iDeadTNum == 0 && iAllCTNum == 0)
			{
				// Game started is false and humans wins (Escape Success)
				g_bGameStarted = false
				rg_round_end(3.0, WINSTATUS_CTS, ROUND_CTS_WIN, "")
				client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
			}
			
			// Humans number more than 1 and no zombies?
			if (g_iAliveCTNum > get_pcvar_num(Cvar_iReqPlayers) && g_iAliveTNum == 0 && !g_bIsRoundEnding)
			{
				// Then Escape success as there is no Zombies
				rg_round_end(3.0, WINSTATUS_CTS, ROUND_CTS_WIN, "")
				client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
			}
			
			// Zombies number more than 1 and no humans?
			if (g_iAliveTNum > get_pcvar_num(Cvar_iReqPlayers) && g_iAliveCTNum == 0 && !g_bIsRoundEnding)
			{
				// Then Escape Fail as there is no humans
				rg_round_end(3.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "")
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

public Check_AllPlayersNumber(TaskID)
{
	if (g_bGameStarted)
	{
		// If game started remove the task and block the blew Checks
		remove_task(TaskID)
		return
	}
		
	if (GetAllAlivePlayersNum() < get_pcvar_num(Cvar_iReqPlayers))
		return
	
	if (GetAllAlivePlayersNum() == get_pcvar_num(Cvar_iReqPlayers))
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
	
	// Simple Fix for bots, If many of them connect fast then the == 2 won't be detected so this to detect it
	if (GetAllAlivePlayersNum() > get_pcvar_num(Cvar_iReqPlayers) && !g_bGameStarted)
	{
		g_bGameStarted = true
		
		// Restart the game
		server_cmd("sv_restart 2")
		
		// Print Fake "Game Commencing" Message
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
	set_entvar(id, var_health, get_pcvar_float(Cvar_Human_iHealth))
	set_entvar(id, var_gravity, get_pcvar_float(Cvar_Human_fGravity)/800.0)
	ExecuteForward(g_iForwards[FORWARD_HUMANIZED], g_iFwReturn, id)
	
	if (get_member(id, m_iTeam) != TEAM_CT)
		rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED)
}

public Set_User_Zombie(id)
{
	if (!is_user_alive(id))
		return
	
	g_bIsZombie[id] = true
	set_entvar(id, var_health, get_pcvar_float(Cvar_Zombie_iHealth))
	set_entvar(id, var_gravity, get_pcvar_float(Cvar_Zombie_fGravity)/800.0)
	rg_remove_all_items(id)
	rg_give_item(id, "weapon_knife", GT_APPEND)
	ExecuteForward(g_iForwards[FORWARD_INFECTED], g_iFwReturn, id, 0)
	
	if (get_member(id, m_iTeam) != TEAM_TERRORIST)
		rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED)
}

public Map_Restart()
{
	// Add Delay To help Rest Scores if player kill himself, and there no one else him so round draw (Delay needed)
	set_task(0.1, "Rest_Score_Message", _, _, _, "a", 1)
}

public Rest_Score_Message()
{
	g_iHumansScore = 0
	g_iZombiesScore = 0
}

// Natives
public native_ze_is_user_zombie(id)
{
	return g_bIsZombie[id]
}

public native_ze_set_user_zombie(id)
{
	Set_User_Zombie(id)
}

public native_ze_set_user_human(id)
{
	Set_User_Human(id)
}