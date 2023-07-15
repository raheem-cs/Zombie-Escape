#include <zombie_escape>
#include <engine>

// Useless Text Messages.
new const g_szTextMessages[][] =
{
	"#CTs_Win",
	"#Round_Draw", 
	"#Terrorists_Win",
	"#Game_Commencing", 
	"#Game_will_restart_in",
	"#Hostages_Not_Rescued" 
}

// Useless Audio Messages.
new const g_szAudioMessages[][] =
{
	"ctwin",
	"terwin", 
	"rounddraw"
}

// Variables
new bool:g_bSpawn

// Cvars
new bool:g_bBlockKillCmd, 
	bool:g_bBlockMoneyHUD, 
	bool:g_bBlockOtherHUD

public plugin_precache()
{
	// Remove useless Entities.
	g_bSpawn = true
}

public plugin_init()
{
	// Load Plug-In
	register_plugin("[ZE] Blocked Messages & Events", ZE_VERSION, AUTHORS)
	
	// Block some messages
	register_message(get_user_msgid("TextMsg"), "fw_TextMsg_Message")
	register_message(get_user_msgid("SendAudio"), "fw_SendAudio_Message")
	register_message(get_user_msgid("HideWeapon"), "fw_HideWeapon_Message")
	
	// Hams
	RegisterHam(Ham_Touch, "weaponbox", "Fw_TouchWeaponBox_Pre", 0)
	RegisterHam(Ham_Touch, "armoury_entity", "Fw_TouchWeaponBox_Pre", 0)
	
	// Cvars
	bind_pcvar_num(register_cvar("ze_block_kill", "1"), g_bBlockKillCmd)
	bind_pcvar_num(register_cvar("ze_block_money_hud", "1"), g_bBlockMoneyHUD)
	bind_pcvar_num(register_cvar("ze_block_radar_ap_hp", "1"), g_bBlockOtherHUD)

	// Reset boolean.
	g_bSpawn = false
}

public plugin_cfg()
{
	// Block Buyzone.
	set_member_game(m_bTCantBuy, true)
	set_member_game(m_bCTCantBuy, true)
	set_member_game(m_bMapHasBuyZone, false)
}

public fw_TextMsg_Message()
{
	new szMsg[22]
	get_msg_arg_string(2, szMsg, charsmax(szMsg))
	
	// Block round end related messages
	for (new i = 0; i < sizeof(g_szTextMessages); i++)
	{
		if (equal(szMsg, g_szTextMessages[i]))
			return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public fw_SendAudio_Message()
{
	new szAudio[17]
	get_msg_arg_string(2, szAudio, charsmax(szAudio))
	
	// Block CS round win audio messages
	for (new i = 0; i < sizeof(g_szAudioMessages); i++)
	{
		if (equal(szAudio[7], g_szAudioMessages[i]))
		{
			server_print(szAudio[7])
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}

public fw_HideWeapon_Message(Index, Dest, iEnt)
{
	new iFlags

	if (g_bBlockMoneyHUD)
		iFlags |= HIDEHUD_MONEY

	if (g_bBlockOtherHUD)
		iFlags |= HIDEHUD_HEALTH // HP, AP, Radar.

	set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | iFlags)
}

public client_kill(id)
{
	// Block suicide command.
	if (g_bBlockKillCmd)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public pfn_spawn(iEnt)
{
	if (!g_bSpawn)
		return PLUGIN_CONTINUE

	// Useless entities
	new const szEntNames[][] =
	{
		"env_fog",
		"env_rain",
		"env_snow",
		"hostage_entity",
		"info_bomb_target",
		"info_hostage_rescue",
		"info_vip_start",
		"monster_scientist",
		"weapon_c4",
		"func_bomb_target",
		"func_buyzone",
		"func_escapezone",
		"func_hostage_rescue",
		"func_vip_safetyzone"
	}

	for (new i = 0; i < sizeof(szEntNames); i++)
	{
		if (FClassnameIs(iEnt, szEntNames[i]))
		{
			// Free edict.
			remove_entity(iEnt)
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_CONTINUE
}

public Fw_TouchWeaponBox_Pre(iWeaponBox, iIndex)
{
	if (!is_user_alive(iIndex))
		return HAM_IGNORED
	
	// Block Zombies From Pick UP Weapons
	if (ze_is_user_zombie(iIndex))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}