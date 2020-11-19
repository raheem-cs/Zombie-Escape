#include <zombie_escape>

#define TASK_MESSAGE 2030

enum
{
	RANK_NONE = 0,
	RANK_FIRST,
	RANK_SECOND,
	RANK_THIRD
}

// Colors
enum
{
	Red = 0,
	Green,
	Blue
}

// Variables
new g_iMaxClients,
	g_iSpeedRank,
	g_iInfectionMsg,
	g_iEscapePoints[33],
	g_iEscapeRank[4],
	bool:g_bStopRendering[33]

// Cvars
new g_pCvarInfectNotice, 
	g_pCvarInfectColors[3],
	g_pCvarMode,
	g_pCvarRankColors[3],
	g_pCvarLeaderGlow,
	g_pCvarLeaderGlowColors[3],
	g_pCvarLeaderGlowRandom

public plugin_init()
{
	register_plugin("[ZE] Messages", ZE_VERSION, AUTHORS)
	
	// Cvars
	g_pCvarInfectNotice = register_cvar("ze_enable_infect_notice", "1")
	g_pCvarInfectColors[Red] = register_cvar("ze_infect_notice_red", "255")
	g_pCvarInfectColors[Green] = register_cvar("ze_infect_notice_green", "0")
	g_pCvarInfectColors[Blue] = register_cvar("ze_infect_notice_blue", "0")
	g_pCvarMode = register_cvar("ze_speed_rank_mode", "1")
	g_pCvarRankColors[Red] = register_cvar("ze_speed_rank_red", "0")
	g_pCvarRankColors[Green] = register_cvar("ze_speed_rank_green", "255")
	g_pCvarRankColors[Blue] = register_cvar("ze_speed_rank_blue", "0")
	g_pCvarLeaderGlow = register_cvar("ze_leader_glow", "1")
	g_pCvarLeaderGlowColors[Red] = register_cvar("ze_leader_glow_red", "255")
	g_pCvarLeaderGlowColors[Green] = register_cvar("ze_leader_glow_green", "0")
	g_pCvarLeaderGlowColors[Blue] = register_cvar("ze_leader_glow_blue", "0")
	g_pCvarLeaderGlowRandom = register_cvar("ze_leader_random_color", "1")
	
	// Messages
	g_iSpeedRank = CreateHudSyncObj()
	g_iInfectionMsg = CreateHudSyncObj()
	
	// Others
	g_iMaxClients = get_member_game(m_nMaxPlayers)
}

public plugin_natives()
{
	register_native("ze_get_escape_leader_id", "native_ze_get_escape_leader_id", 1)
	register_native("ze_stop_mod_rendering", "native_ze_stop_mod_rendering", 1)
}

public ze_user_infected(iVictim, iInfector)
{
	if (iInfector == 0) // Server ID
		return
		
	if (get_pcvar_num(g_pCvarInfectNotice))
	{
		new szVictimName[32], szAttackerName[32]
		get_user_name(iVictim, szVictimName, charsmax(szVictimName))
		get_user_name(iInfector, szAttackerName, charsmax(szAttackerName))
		set_hudmessage(get_pcvar_num(g_pCvarInfectColors[Red]), get_pcvar_num(g_pCvarInfectColors[Green]), get_pcvar_num(g_pCvarInfectColors[Blue]), 0.05, 0.45, 1, 0.0, 6.0, 0.0, 0.0)
		ShowSyncHudMsg(0, g_iInfectionMsg, "%L", LANG_PLAYER, "INFECTION_NOTICE", szAttackerName, szVictimName)
	}
}

public ze_game_started()
{
	remove_task(TASK_MESSAGE)
}

public ze_zombie_appear()
{
	// Show message when zombies appear to reduce lag
	set_task(0.3, "Show_Message", TASK_MESSAGE, _, _, "b") // 0.3 Is Enough Delay
	arrayset(g_iEscapePoints, 0, charsmax(g_iEscapePoints))
}

public Show_Message()
{
	for (new id = 1; id <= g_iMaxClients; id++)
	{
		if (!is_user_alive(id))
			continue
	
		// Add Point for Who is Running Fast
		if(!ze_is_user_zombie(id))
		{
			new Float:fVelocity[3], iSpeed
			
			get_entvar(id, var_velocity, fVelocity)
			iSpeed = floatround(vector_length(fVelocity))
			
			switch(iSpeed)
			{
				// Starting From Lowest Weapon speed, Finishing at Highest speed (Player maybe have more than 500)
				case 210..229: g_iEscapePoints[id] += 1
				case 230..249: g_iEscapePoints[id] += 2
				case 250..300: g_iEscapePoints[id] += 3
				case 301..350: g_iEscapePoints[id] += 4
				case 351..400: g_iEscapePoints[id] += 5
				case 401..450: g_iEscapePoints[id] += 6
				case 451..500: g_iEscapePoints[id] += 7
			}
		}
	
		if (get_pcvar_num(g_pCvarLeaderGlow) != 0)
		{
			// Set Glow For Escape Leader
			for (new i = 1; i <= g_iMaxClients; i++)
			{
				if (!is_user_alive(i) || g_bStopRendering[i])
					continue
			
				if (g_iEscapeRank[RANK_FIRST] == i) // The Leader id
				{
					if (get_pcvar_num(g_pCvarLeaderGlowRandom) == 0)
					{
						Set_Rendering(i, kRenderFxGlowShell, get_pcvar_num(g_pCvarLeaderGlowColors[Red]), get_pcvar_num(g_pCvarLeaderGlowColors[Green]), get_pcvar_num(g_pCvarLeaderGlowColors[Blue]), kRenderNormal, 40)
					}
					else
					{
						Set_Rendering(i, kRenderFxGlowShell, random(256), random(256), random(256), kRenderNormal, 40)
					}
					
				}
				else
				{
					Set_Rendering(i)
				}
			}
		}
		
		Show_Speed_Message(id)
	}
}

public Show_Speed_Message(id)
{
	// Case 0 has nothing to do in case g_pCvarMode = 0
	switch (get_pcvar_num(g_pCvarMode))
	{
		case 1: // Leader Mode
		{
			Speed_Stats()
			new iLeaderID = g_iEscapeRank[RANK_FIRST]
			new szLeader[32]
			
			if (is_user_alive(iLeaderID) && !ze_is_user_zombie(iLeaderID) && g_iEscapePoints[iLeaderID] != 0)
			{
				get_user_name(iLeaderID, szLeader, charsmax(szLeader))
				
				set_hudmessage(get_pcvar_num(g_pCvarRankColors[Red]), get_pcvar_num(g_pCvarRankColors[Green]), get_pcvar_num(g_pCvarRankColors[Blue]), 0.015,  0.18, 0, 0.2, 0.4, 0.09, 0.09)
				ShowSyncHudMsg(id, g_iSpeedRank, "%L", LANG_PLAYER, "RANK_INFO_LEADER", szLeader)
			}
			else
			{
				formatex(szLeader, charsmax(szLeader), "%L", LANG_PLAYER, "RANK_INFO_NONE")
				set_hudmessage(get_pcvar_num(g_pCvarRankColors[Red]), get_pcvar_num(g_pCvarRankColors[Green]), get_pcvar_num(g_pCvarRankColors[Blue]), 0.015,  0.18, 0, 0.2, 0.4, 0.09, 0.09)
				ShowSyncHudMsg(id, g_iSpeedRank, "%L", LANG_PLAYER, "RANK_INFO_LEADER", szLeader)
			}
		}
		case 2: // Rank Mode
		{
			Speed_Stats()
			
			new szFirst[32], szSecond[32], szThird[32]
			new iFirstID, iSecondID, iThirdID
			
			iFirstID = g_iEscapeRank[RANK_FIRST]
			iSecondID = g_iEscapeRank[RANK_SECOND]
			iThirdID = g_iEscapeRank[RANK_THIRD]
			
			if (is_user_alive(iFirstID) && !ze_is_user_zombie(iFirstID) && g_iEscapePoints[iFirstID] != 0)
			{
				get_user_name(iFirstID, szFirst, charsmax(szFirst))
			}
			else
			{
				formatex(szFirst, charsmax(szFirst), "%L", LANG_PLAYER, "RANK_INFO_NONE")
			}
			
			if (is_user_alive(iSecondID) && !ze_is_user_zombie(iSecondID) && g_iEscapePoints[iSecondID] != 0)
			{
				get_user_name(iSecondID, szSecond, charsmax(szSecond))
			}
			else
			{
				formatex(szSecond, charsmax(szSecond), "%L", LANG_PLAYER, "RANK_INFO_NONE")
			}
			
			if (is_user_alive(iThirdID) && !ze_is_user_zombie(iThirdID) && g_iEscapePoints[iThirdID] != 0)
			{
				get_user_name(iThirdID, szThird, charsmax(szThird))		
			}
			else
			{
				formatex(szThird, charsmax(szThird), "%L", LANG_PLAYER, "RANK_INFO_NONE")
			}
			
			set_hudmessage(get_pcvar_num(g_pCvarRankColors[Red]), get_pcvar_num(g_pCvarRankColors[Green]), get_pcvar_num(g_pCvarRankColors[Blue]), 0.015,  0.18, 0, 0.2, 0.4, 0.09, 0.09)
			ShowSyncHudMsg(id, g_iSpeedRank, "%L", LANG_PLAYER, "RANK_INFO", szFirst, szSecond, szThird)
		}
	}
}

public Speed_Stats()
{
	new iHighest, iCurrentID
	
	// Rank First
	iHighest = 0; iCurrentID = 0
	
	for(new id = 1; id <= g_iMaxClients; id++)
	{
		if(!is_user_alive(id) || ze_is_user_zombie(id))
			continue
			
		if(g_iEscapePoints[id] > iHighest)
		{
			iCurrentID = id
			iHighest = g_iEscapePoints[id]
		}
	}
	
	g_iEscapeRank[RANK_FIRST] = iCurrentID
	
	// Rank Second
	iHighest = 0; iCurrentID = 0
	
	for(new id = 1; id <= g_iMaxClients; id++)
	{
		if(!is_user_alive(id) || ze_is_user_zombie(id))
			continue
		
		if (g_iEscapeRank[RANK_FIRST] == id)
			continue
			
		if(g_iEscapePoints[id] > iHighest)
		{
			iCurrentID = id
			iHighest = g_iEscapePoints[id]
		}
	}
	
	g_iEscapeRank[RANK_SECOND] = iCurrentID		
	
	// Rank Third
	iHighest = 0; iCurrentID = 0
	
	for(new id = 1; id <= g_iMaxClients; id++)
	{
		if(!is_user_alive(id) || ze_is_user_zombie(id))
			continue
		
		if(g_iEscapeRank[RANK_FIRST] == id || g_iEscapeRank[RANK_SECOND] == id)
			continue
			
		if(g_iEscapePoints[id] > iHighest)
		{
			iCurrentID = id
			iHighest = g_iEscapePoints[id]
		}
	}
	
	g_iEscapeRank[RANK_THIRD] = iCurrentID	
}

public native_ze_get_escape_leader_id()
{
	return g_iEscapeRank[RANK_FIRST]
}

public native_ze_stop_mod_rendering(id, bool:bSet)
{
	if (is_user_connected(id))
	{
		g_bStopRendering[id] = bSet
		return true
    }
	
	return false
}