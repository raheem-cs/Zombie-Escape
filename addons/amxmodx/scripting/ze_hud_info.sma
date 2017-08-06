#include <zombie_escape>

// Cvars
new Cvar_Hud_Info_Mode, Cvar_Hud_Info_Comma,
Cvar_Info_Zombie_Red, Cvar_Info_Zombie_Green, Cvar_Info_Zombie_Blue,
Cvar_Info_Human_Red, Cvar_Info_Human_Green, Cvar_Info_Human_Blue,
Cvar_Info_Spec_Red, Cvar_Info_Spec_Green, Cvar_Info_Spec_Blue

// Constants Change X,Y If you need (HUD & DHud)
const Float:HUD_SPECT_X = 0.01
const Float:HUD_SPECT_Y = 0.130
const Float:HUD_STATS_X = -1.0
const Float:HUD_STATS_Y = 0.86

#define TASK_SHOWHUD 100
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

new g_iMsgSync, g_pCvarRankEnabled

public plugin_init()
{
	register_plugin("[ZE] Hud Information", ZE_VERSION, AUTHORS)
	
	// Messages
	g_iMsgSync = CreateHudSyncObj()
	
	//Cvars
	Cvar_Hud_Info_Mode = register_cvar("ze_hud_info_mode", "1")
	Cvar_Hud_Info_Comma = register_cvar("ze_hud_info_commas", "1")
	Cvar_Info_Zombie_Red = register_cvar("ze_hud_info_zombie_red", "255")
	Cvar_Info_Zombie_Green = register_cvar("ze_hud_info_zombie_green", "20")
	Cvar_Info_Zombie_Blue = register_cvar("ze_hud_info_zombie_blue", "20")
	Cvar_Info_Human_Red = register_cvar("ze_hud_info_human_red", "20")
	Cvar_Info_Human_Green = register_cvar("ze_hud_info_human_green", "20")
	Cvar_Info_Human_Blue = register_cvar("ze_hud_info_human_blue", "255")
	Cvar_Info_Spec_Red = register_cvar("ze_hud_info_spec_red", "100")
	Cvar_Info_Spec_Green = register_cvar("ze_hud_info_spec_green", "100")
	Cvar_Info_Spec_Blue = register_cvar("ze_hud_info_spec_blue", "100")
	
	// Pointers
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
	if (get_pcvar_num(Cvar_Hud_Info_Mode) == 0)
		return
	
	new iPlayer = ID_SHOWHUD
	
	if (!is_user_alive(iPlayer))
	{
		iPlayer = pev(iPlayer, pev_iuser2)
		
		if (!is_user_alive(iPlayer))
			return
	}
	
	if(iPlayer != ID_SHOWHUD)
	{
		new szName[32]
		get_user_name(iPlayer, szName, charsmax(szName))

		if (get_pcvar_num(Cvar_Hud_Info_Mode) == 1)
		{
			if (get_pcvar_num(Cvar_Hud_Info_Comma) == 1)
			{
				new szHealth[15]
				AddCommas(get_user_health(iPlayer), szHealth, charsmax(szHealth))
				
				if (ze_is_user_zombie(iPlayer))
				{
					set_hudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "ZOMBIE_SPEC_COMMAS", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
				else if ((iPlayer == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					set_hudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_SPEC_COMMAS_LEADER", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
				else
				{
					set_hudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_SPEC_COMMAS", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
			}
			else
			{
				if (ze_is_user_zombie(iPlayer))
				{
					set_hudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "ZOMBIE_SPEC", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
				else if ((iPlayer == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					set_hudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_SPEC_LEADER", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
				else
				{
					set_hudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_SPEC", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
			}
		}
		else if (get_pcvar_num(Cvar_Hud_Info_Mode) == 2)
		{
			if (get_pcvar_num(Cvar_Hud_Info_Comma) == 1)
			{
				new szHealth[15]
				AddCommas(get_user_health(iPlayer), szHealth, charsmax(szHealth))
				
				if (ze_is_user_zombie(iPlayer))
				{
					set_dhudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "ZOMBIE_SPEC_COMMAS_DHUD", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
				else if ((iPlayer == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					set_dhudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_SPEC_COMMAS_DHUD_LEADER", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
				else
				{
					set_dhudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_SPEC_COMMAS_DHUD", szName, szHealth, ze_get_escape_coins(iPlayer))
				}
			}
			else
			{
				if (ze_is_user_zombie(iPlayer))
				{
					set_dhudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "ZOMBIE_SPEC_DHUD", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
				else if ((iPlayer == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					set_dhudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_SPEC_DHUD_LEADER", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
				else
				{
					set_dhudmessage(get_pcvar_num(Cvar_Info_Spec_Red), get_pcvar_num(Cvar_Info_Spec_Green), get_pcvar_num(Cvar_Info_Spec_Blue), HUD_SPECT_X, HUD_SPECT_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_SPEC_DHUD", szName, get_user_health(iPlayer), ze_get_escape_coins(iPlayer))
				}
			}
		}
	}
	else if (ze_is_user_zombie(iPlayer))
	{
		if (get_pcvar_num(Cvar_Hud_Info_Mode) == 1)
		{
			if (get_pcvar_num(Cvar_Hud_Info_Comma) == 1)
			{
				new szHealth[15]
				AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))

				set_hudmessage(get_pcvar_num(Cvar_Info_Zombie_Red), get_pcvar_num(Cvar_Info_Zombie_Green), get_pcvar_num(Cvar_Info_Zombie_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
				ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "ZOMBIE_HUD_COMMAS", szHealth, ze_get_escape_coins(ID_SHOWHUD))
			}
			else
			{
				set_hudmessage(get_pcvar_num(Cvar_Info_Zombie_Red), get_pcvar_num(Cvar_Info_Zombie_Green), get_pcvar_num(Cvar_Info_Zombie_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
				ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "ZOMBIE_HUD", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
			}
		}
		else if (get_pcvar_num(Cvar_Hud_Info_Mode) == 2)
		{
			if (get_pcvar_num(Cvar_Hud_Info_Comma) == 1)
			{
				new szHealth[15]
				AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
				set_dhudmessage(get_pcvar_num(Cvar_Info_Zombie_Red), get_pcvar_num(Cvar_Info_Zombie_Green), get_pcvar_num(Cvar_Info_Zombie_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6)
				show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "ZOMBIE_HUD_COMMAS_DHUD", szHealth, ze_get_escape_coins(ID_SHOWHUD))
			}
			else
			{
				set_dhudmessage(get_pcvar_num(Cvar_Info_Zombie_Red), get_pcvar_num(Cvar_Info_Zombie_Green), get_pcvar_num(Cvar_Info_Zombie_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6)
				show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "ZOMBIE_DHUD", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))	
			}
		}
	}
	else
	{
		if (get_pcvar_num(Cvar_Hud_Info_Mode) == 1)
		{
			if (get_pcvar_num(Cvar_Hud_Info_Comma) == 1)
			{
				if ((ID_SHOWHUD == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					new szHealth[15]
					AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
					set_hudmessage(get_pcvar_num(Cvar_Info_Human_Red), get_pcvar_num(Cvar_Info_Human_Green), get_pcvar_num(Cvar_Info_Human_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_HUD_COMMAS_LEADER", szHealth, ze_get_escape_coins(ID_SHOWHUD))
				}
				else
				{
					new szHealth[15]
					AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
					set_hudmessage(get_pcvar_num(Cvar_Info_Human_Red), get_pcvar_num(Cvar_Info_Human_Green), get_pcvar_num(Cvar_Info_Human_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_HUD_COMMAS", szHealth, ze_get_escape_coins(ID_SHOWHUD))
				}					
			}
			else
			{
				if ((ID_SHOWHUD == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					set_hudmessage(get_pcvar_num(Cvar_Info_Human_Red), get_pcvar_num(Cvar_Info_Human_Green), get_pcvar_num(Cvar_Info_Human_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_HUD_LEADER", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
				}
				else
				{
					set_hudmessage(get_pcvar_num(Cvar_Info_Human_Red), get_pcvar_num(Cvar_Info_Human_Green), get_pcvar_num(Cvar_Info_Human_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6, -1)
					ShowSyncHudMsg(ID_SHOWHUD, g_iMsgSync, "%L", LANG_PLAYER, "HUMAN_HUD", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
				}					
			}
		}
		else if (get_pcvar_num(Cvar_Hud_Info_Mode) == 2)
		{
			if (get_pcvar_num(Cvar_Hud_Info_Comma) == 1)
			{
				if ((ID_SHOWHUD == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					new szHealth[15]
					AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
					set_dhudmessage(get_pcvar_num(Cvar_Info_Human_Red), get_pcvar_num(Cvar_Info_Human_Green), get_pcvar_num(Cvar_Info_Human_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_DHUD_COMMAS_LEADER", szHealth, ze_get_escape_coins(ID_SHOWHUD))
				}
				else
				{
					new szHealth[15]
					AddCommas(get_user_health(ID_SHOWHUD), szHealth, charsmax(szHealth))
				
					set_dhudmessage(get_pcvar_num(Cvar_Info_Human_Red), get_pcvar_num(Cvar_Info_Human_Green), get_pcvar_num(Cvar_Info_Human_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_DHUD_COMMAS", szHealth, ze_get_escape_coins(ID_SHOWHUD))
				}
			}
			else
			{
				if ((ID_SHOWHUD == ze_get_escape_leader_id()) && (0 < get_pcvar_num(g_pCvarRankEnabled) <= 2))
				{
					set_dhudmessage(get_pcvar_num(Cvar_Info_Human_Red), get_pcvar_num(Cvar_Info_Human_Green), get_pcvar_num(Cvar_Info_Human_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_DHUD_LEADER", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
				}
				else
				{
					set_dhudmessage(get_pcvar_num(Cvar_Info_Human_Red), get_pcvar_num(Cvar_Info_Human_Green), get_pcvar_num(Cvar_Info_Human_Blue), HUD_STATS_X, HUD_STATS_Y, 0, 1.2, 1.1, 0.5, 0.6)
					show_dhudmessage(ID_SHOWHUD, "%L", LANG_PLAYER, "HUMAN_DHUD", get_user_health(ID_SHOWHUD), ze_get_escape_coins(ID_SHOWHUD))
				}
			}
		}
	}
}