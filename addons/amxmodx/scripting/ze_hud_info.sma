#include <zombie_escape>

// Defines
#define TASK_SHOWHUD 100
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

// Constants Change X,Y If you need (HUD & DHud)
const Float:HUD_SPECT_X = 0.01
const Float:HUD_SPECT_Y = 0.130
const Float:HUD_STATS_X = -1.0
const Float:HUD_STATS_Y = 0.86

// Colors
enum
{
	Red = 0,
	Green,
	Blue
}

// Variables
new g_iMsgSync, 
	g_pCvarRankEnabled
	
// Cvars
new g_pCvarHudInfoMode, 
	g_pCvarHudInfoComma,
	g_pCvarZombieInfoColors[3],
	g_pCvarHumanInfoColors[3],
	g_pCvarSpecInfoColors[3]

public plugin_init()
{
	register_plugin("[ZE] Hud Information", ZE_VERSION, AUTHORS)
	
	// Messages
	g_iMsgSync = CreateHudSyncObj()
	
	//Cvars
	g_pCvarHudInfoMode = register_cvar("ze_hud_info_mode", "1")
	g_pCvarHudInfoComma = register_cvar("ze_hud_info_commas", "1")
	g_pCvarZombieInfoColors[Red] = register_cvar("ze_hud_info_zombie_red", "255")
	g_pCvarZombieInfoColors[Green] = register_cvar("ze_hud_info_zombie_green", "20")
	g_pCvarZombieInfoColors[Blue] = register_cvar("ze_hud_info_zombie_blue", "20")
	g_pCvarHumanInfoColors[Red] = register_cvar("ze_hud_info_human_red", "20")
	g_pCvarHumanInfoColors[Green] = register_cvar("ze_hud_info_human_green", "20")
	g_pCvarHumanInfoColors[Blue] = register_cvar("ze_hud_info_human_blue", "255")
	g_pCvarSpecInfoColors[Red] = register_cvar("ze_hud_info_spec_red", "100")
	g_pCvarSpecInfoColors[Green] = register_cvar("ze_hud_info_spec_green", "100")
	g_pCvarSpecInfoColors[Blue] = register_cvar("ze_hud_info_spec_blue", "100")
	
	// Pointer
	g_pCvarRankEnabled = get_cvar_pointer("ze_speed_rank_mode")
}

public client_putinserver(id)
{
	if(!is_user_bot(id))
	{
		set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
	}
}

public client_disconnected(id)
{
	remove_task(id+TASK_SHOWHUD)
}

public ShowHUD(taskid)
{
	if (get_pcvar_num(g_pCvarHudInfoMode) == 0)
		return
	
	new iPlayer = ID_SHOWHUD
	
	if (!is_user_alive(iPlayer))
	{
		iPlayer = get_entvar(iPlayer, var_iuser2)
		
		if (!is_user_alive(iPlayer))
			return
	}
	
	if(iPlayer != ID_SHOWHUD)
	{
		new szName[32]
		get_user_name(iPlayer, szName, charsmax(szName))

		if (get_pcvar_num(g_pCvarHudInfoMode) == 1)
		{
			set_hudmessage(get_pcvar_num(g_pCvarSpecInfoColors[Red]), get_pcvar_num(g_pCvarSpecInfoColors[Green]), get_pcvar_num(g_pCvarSpecInfoColors[Blue]), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
			
			if (get_pcvar_num(g_pCvarHudInfoComma) == 1)
			{
				new szHealth[15]
				AddCommas(get_user_health(iPlayer), szHealth, charsmax(szHealth))
				
				if (ze_is_user_zombie(iPlayer))
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "ZOMBIE_SPEC_COMMAS", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
				else if ((iPlayer == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_SPEC_COMMAS_LEADER", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
				else
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_SPEC_COMMAS", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
			}
			else
			{
				if (ze_is_user_zombie(iPlayer))
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "ZOMBIE_SPEC", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
				else if ((iPlayer == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_SPEC_LEADER", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
				else
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_SPEC", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
			}
		}
		else if (get_pcvar_num(g_pCvarHudInfoMode) == 2)
		{
			set_dhudmessage(get_pcvar_num(g_pCvarSpecInfoColors[Red]), get_pcvar_num(g_pCvarSpecInfoColors[Green]), get_pcvar_num(g_pCvarSpecInfoColors[Blue]), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6)
			
			if (get_pcvar_num(g_pCvarHudInfoComma) == 1)
			{
				new szHealth[15]
				AddCommas(get_user_health(iPlayer), szHealth, charsmax(szHealth))
				
				if (ze_is_user_zombie(iPlayer))
				{
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "ZOMBIE_SPEC_COMMAS", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
				else if ((iPlayer == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_SPEC_COMMAS_LEADER", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
				else
				{
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_SPEC_COMMAS", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
			}
			else
			{
				if (ze_is_user_zombie(iPlayer))
				{
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "ZOMBIE_SPEC", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
				else if ((iPlayer == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_SPEC_LEADER", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
				else
				{
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_SPEC", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
			}
		}
	}
	else if (ze_is_user_zombie(iPlayer))
	{
		if (get_pcvar_num(g_pCvarHudInfoMode) == 1)
		{
			set_hudmessage(get_pcvar_num(g_pCvarZombieInfoColors[Red]), get_pcvar_num(g_pCvarZombieInfoColors[Green]), get_pcvar_num(g_pCvarZombieInfoColors[Blue]), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
			
			if (get_pcvar_num(g_pCvarHudInfoComma) == 1)
			{
				new szHealth[15]
				AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))

				ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "ZOMBIE_COMMAS", szHealth, ze_get_escape_coins(ID_SHOWHUD))
			}
			else
			{
				ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "ZOMBIE", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
			}
		}
		else if (get_pcvar_num(g_pCvarHudInfoMode) == 2)
		{
			set_dhudmessage(get_pcvar_num(g_pCvarZombieInfoColors[Red]), get_pcvar_num(g_pCvarZombieInfoColors[Green]), get_pcvar_num(g_pCvarZombieInfoColors[Blue]), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6)
			
			if (get_pcvar_num(g_pCvarHudInfoComma) == 1)
			{
				new szHealth[15]
				AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
				show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "ZOMBIE_COMMAS", szHealth, ze_get_escape_coins(ID_SHOWHUD))
			}
			else
			{
				show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "ZOMBIE", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))	
			}
		}
	}
	else
	{
		if (get_pcvar_num(g_pCvarHudInfoMode) == 1)
		{
			set_hudmessage(get_pcvar_num(g_pCvarHumanInfoColors[Red]), get_pcvar_num(g_pCvarHumanInfoColors[Green]), get_pcvar_num(g_pCvarHumanInfoColors[Blue]), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
			
			if (get_pcvar_num(g_pCvarHudInfoComma) == 1)
			{
				if ((ID_SHOWHUD == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					new szHealth[15]
					AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_LEADER_COMMAS", szHealth, ze_get_escape_coins(ID_SHOWHUD))
				}
				else
				{
					new szHealth[15]
					AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_COMMAS", szHealth, ze_get_escape_coins(ID_SHOWHUD))
				}					
			}
			else
			{
				if ((ID_SHOWHUD == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_LEADER", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
				}
				else
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
				}					
			}
		}
		else if (get_pcvar_num(g_pCvarHudInfoMode) == 2)
		{
			set_dhudmessage(get_pcvar_num(g_pCvarHumanInfoColors[Red]), get_pcvar_num(g_pCvarHumanInfoColors[Green]), get_pcvar_num(g_pCvarHumanInfoColors[Blue]), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6)
			
			if (get_pcvar_num(g_pCvarHudInfoComma) == 1)
			{
				if ((ID_SHOWHUD == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					new szHealth[15]
					AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_LEADER_COMMAS", szHealth, ze_get_escape_coins(ID_SHOWHUD))
				}
				else
				{
					new szHealth[15]
					AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_COMMAS", szHealth, ze_get_escape_coins(ID_SHOWHUD))
				}
			}
			else
			{
				if ((ID_SHOWHUD == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_LEADER", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
				}
				else
				{
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
				}
			}
		}
	}
}