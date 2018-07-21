#include <zombie_escape>

// Defines
#define HUD_MONEY				(1<<5)
#define HUD_RADAR_HEALTH_ARMOR	(1<<3)

// Variables
new g_iFwSpawn

// Cvars
new g_pCvarBlockKillCmd, 
	g_pCvarBlockMoneyHUD, 
	g_pCvarBlockOtherHUD

public plugin_init()
{
	register_plugin("[ZE] Blocked Messages & Events", ZE_VERSION, AUTHORS)
	
	// Block some messages
	register_message(get_user_msgid("TextMsg"), "Message_TextMsg")
	register_message(get_user_msgid("SendAudio"), "Message_SendAudio")
	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon")
	register_message(get_user_msgid("HideWeapon"), "Message_HideWeapon")
	
	// Fakemeta
	register_forward(FM_ClientKill, "Fw_ClientKill_Pre", 0)
	unregister_forward(FM_Spawn, g_iFwSpawn)
	
	// Hams
	RegisterHam(Ham_Touch, "weaponbox", "Fw_TouchWeaponBox_Pre", 0)
	RegisterHam(Ham_Touch, "armoury_entity", "Fw_TouchWeaponBox_Pre", 0)
	
	// Cvars
	g_pCvarBlockKillCmd = register_cvar("ze_block_kill", "1")
	g_pCvarBlockMoneyHUD = register_cvar("ze_block_money_hud", "1")
	g_pCvarBlockOtherHUD = register_cvar("ze_block_radar_ap_hp", "1")
}

public plugin_precache()
{
	// Prevent Entities from being spawned like (Rain, Snow, Fog) It's registered here as this called before plugin_init()
	g_iFwSpawn = register_forward(FM_Spawn, "Fw_Spawn")
}

public Message_TextMsg()
{
	new szMsg[22]
	get_msg_arg_string(2, szMsg, charsmax(szMsg))
	
	// Block round end related messages
	if (equal(szMsg, "#Hostages_Not_Rescued") || equal(szMsg, "#Round_Draw") || equal(szMsg, "#CTs_Win") || equal(szMsg, "#Terrorists_Win") || equal(szMsg, "#Game_will_restart_in") || equal(szMsg, "#Game_Commencing"))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public Message_SendAudio()
{
	new szAudio[17]
	get_msg_arg_string(2, szAudio, charsmax(szAudio))
	
	// Block CS round win audio messages
	if (equal(szAudio[7], "terwin") || equal(szAudio[7], "ctwin") || equal(szAudio[7], "rounddraw"))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public Message_StatusIcon(Index, Dest, iEnt)
{
	static szMsg[8]
	get_msg_arg_string(2, szMsg ,charsmax(szMsg))
	
	// Block Buyzone
	if (equal(szMsg, "buyzone") && get_msg_arg_int(1))
	{
		set_pdata_int(iEnt, 235, get_pdata_int(iEnt, 235) & ~(1<<0))
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public Message_HideWeapon(Index, Dest, iEnt)
{
	if (get_pcvar_num(g_pCvarBlockMoneyHUD))
	{
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HUD_MONEY)
	}
	
	if (get_pcvar_num(g_pCvarBlockOtherHUD))
	{
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HUD_RADAR_HEALTH_ARMOR)
	}
}

public Fw_ClientKill_Pre(id)
{
	// Block Kill Command if enabled
	if (get_pcvar_num(g_pCvarBlockKillCmd))
		return FMRES_SUPERCEDE
	
	return PLUGIN_CONTINUE
}

public Fw_Spawn(iEnt)
{
	// Invalid entity
	if (!pev_valid(iEnt))
		return FMRES_IGNORED
	
	// Get classname
	new szClassName[32]
	get_entvar(iEnt, var_classname, szClassName, charsmax(szClassName))
	
	// Prevent All (Rain, Snow, Fog) From the original map, So we can add our Weather
	if (equal(szClassName, "env_rain") || equal(szClassName, "env_snow") || equal(szClassName, "env_fog"))
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public Fw_TouchWeaponBox_Pre(iWeapon, iIndex)
{
	if (!is_user_alive(iIndex))
		return HAM_IGNORED
	
	// Block Zombies From Pick UP Weapons
	if (ze_is_user_zombie(iIndex))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}