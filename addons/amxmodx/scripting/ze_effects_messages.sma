#include <zombie_escape>

// You can change this if you need
static szNone[] = "None"

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
	g_iEscapePoints[33],
	g_iEscapeRank[4]

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
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_Spawn, "Fw_PlayerSpawn_Post", 1)
	
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
	
	// Others
	g_iMaxClients = get_member_game(m_nMaxPlayers)
	
	// Tasks
	set_task(0.3, "Show_Message", _, _, _, "b") // 0.3 Is Enough Delay
}

public plugin_natives()
{
	register_native("ze_get_escape_leader_id", "native_ze_get_escape_leader_id", 1)
}

public ze_user_infected(iVictim, iInfector)
{
	if (get_pcvar_num(g_pCvarInfectNotice) != 0)
	{
		if (iInfector == 0) // Server ID
			return
		
		static szVictimName[32], szAttackerName[32]
		get_user_name(iVictim, szVictimName, charsmax(szVictimName))
		get_user_name(iInfector, szAttackerName, charsmax(szAttackerName))
		set_hudmessage(get_pcvar_num(g_pCvarInfectColors[Red]), get_pcvar_num(g_pCvarInfectColors[Green]), get_pcvar_num(g_pCvarInfectColors[Blue]), 0.05, 0.45, 1, 0.0, 6.0, 0.0, 0.0)
		show_hudmessage(0, "%L", LANG_PLAYER, "INFECTION_NOTICE", szAttackerName, szVictimName)
	}
}

public Show_Message()
{
	for(new id = 1; id <= g_iMaxClients; id++)
	{
		if (!is_user_alive(id))
			continue
	
		// Add Point for Who is Running Fast
		if(!ze_is_user_zombie(id))
		{
			static Float:fVelocity[3], iSpeed
			
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
				if (!is_user_alive(i))
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

public Fw_PlayerSpawn_Post(id)
{
	g_iEscapePoints[id] = 0
}

public Show_Speed_Message(id)
{
	if (get_pcvar_num(g_pCvarMode) == 0 || get_member_game(m_bFreezePeriod) == true) // Disabled
		return
	
	if (get_pcvar_num(g_pCvarMode) == 1) // Leader Mode
	{
		Speed_Stats()
		new iLeaderID; iLeaderID = g_iEscapeRank[RANK_FIRST]
		
		if (is_user_alive(iLeaderID) && !ze_is_user_zombie(iLeaderID) && g_iEscapePoints[iLeaderID] != 0)
		{
			new szLeader[32]
			get_user_name(iLeaderID, szLeader, charsmax(szLeader))
			
			set_hudmessage(get_pcvar_num(g_pCvarRankColors[Red]), get_pcvar_num(g_pCvarRankColors[Green]), get_pcvar_num(g_pCvarRankColors[Blue]), 0.015,  0.18, 0, 0.2, 0.4, 0.09, 0.09)
			ShowSyncHudMsg(id, g_iSpeedRank, "%L", LANG_PLAYER, "RANK_INFO_LEADER", szLeader)
		}
		else
		{
			set_hudmessage(get_pcvar_num(g_pCvarRankColors[Red]), get_pcvar_num(g_pCvarRankColors[Green]), get_pcvar_num(g_pCvarRankColors[Blue]), 0.015,  0.18, 0, 0.2, 0.4, 0.09, 0.09)
			ShowSyncHudMsg(id, g_iSpeedRank, "%L", LANG_PLAYER, "RANK_INFO_LEADER", szNone)
		}
	}
	
	if (get_pcvar_num(g_pCvarMode) == 2) // Rank Mode
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
			szFirst = szNone
		}
		
		if (is_user_alive(iSecondID) && !ze_is_user_zombie(iSecondID) && g_iEscapePoints[iSecondID] != 0)
		{
			get_user_name(iSecondID, szSecond, charsmax(szSecond))
		}
		else
		{
			szSecond = szNone
		}
		
		if (is_user_alive(iThirdID) && !ze_is_user_zombie(iThirdID) && g_iEscapePoints[iThirdID] != 0)
		{
			get_user_name(iThirdID, szThird, charsmax(szThird))		
		}
		else
		{
			szThird = szNone
		}
		
		set_hudmessage(get_pcvar_num(g_pCvarRankColors[Red]), get_pcvar_num(g_pCvarRankColors[Green]), get_pcvar_num(g_pCvarRankColors[Blue]), 0.015,  0.18, 0, 0.2, 0.4, 0.09, 0.09)
		ShowSyncHudMsg(id, g_iSpeedRank, "%L", LANG_PLAYER, "RANK_INFO", szFirst, szSecond, szThird)
	}
}

public Speed_Stats()
{
	static iHighest, iCurrentID
	
	// Rank First
	iHighest = 0; iCurrentID = 0
	
	for(new i = 1; i <= g_iMaxClients; i++)
	{
		if(!is_user_alive(i) || ze_is_user_zombie(i))
			continue
			
		if(g_iEscapePoints[i] > iHighest)
		{
			iCurrentID = i
			iHighest = g_iEscapePoints[i]
		}
	}
	
	g_iEscapeRank[RANK_FIRST] = iCurrentID
	
	// Rank Second
	iHighest = 0; iCurrentID = 0
	
	for(new i = 1; i <= g_iMaxClients; i++)
	{
		if(!is_user_alive(i) || ze_is_user_zombie(i))
			continue
		
		if (g_iEscapeRank[RANK_FIRST] == i)
			continue
			
		if(g_iEscapePoints[i] > iHighest)
		{
			iCurrentID = i
			iHighest = g_iEscapePoints[i]
		}
	}
	
	g_iEscapeRank[RANK_SECOND] = iCurrentID		
	
	// Rank Third
	iHighest = 0; iCurrentID = 0
	
	for(new i = 1; i <= g_iMaxClients; i++)
	{
		if(!is_user_alive(i) || ze_is_user_zombie(i))
			continue
		
		if(g_iEscapeRank[RANK_FIRST] == i || g_iEscapeRank[RANK_SECOND] == i)
			continue
			
		if(g_iEscapePoints[i] > iHighest)
		{
			iCurrentID = i
			iHighest = g_iEscapePoints[i]
		}
	}
	
	g_iEscapeRank[RANK_THIRD] = iCurrentID	
}

public native_ze_get_escape_leader_id()
{
	return g_iEscapeRank[RANK_FIRST]
}