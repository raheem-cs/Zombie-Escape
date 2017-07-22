/*================================================================================
	
	----------------------------------
	-*- [CS] Weapon Models API 1.1 -*-
	----------------------------------
	
	- Allows easily replacing player's view models and weapon models in CS and CZ
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define MAXPLAYERS 32
#define CSW_FIRST_WEAPON CSW_P228
#define CSW_LAST_WEAPON CSW_P90
#define POSITION_NULL -1

// CS Weapon CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

// CS Player CBase Offsets (win32)
const OFFSET_ACTIVE_ITEM = 373

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

new g_MaxPlayers
new g_CustomViewModelsPosition[MAXPLAYERS+1][CSW_LAST_WEAPON+1]
new Array:g_CustomViewModelsNames
new g_CustomViewModelsCount
new g_CustomWeaponModelsPosition[MAXPLAYERS+1][CSW_LAST_WEAPON+1]
new Array:g_CustomWeaponModelsNames
new g_CustomWeaponModelsCount

public plugin_init()
{
	register_plugin("[CS] Weapon Models API", "1.1", "WiLS")
	
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	
	g_MaxPlayers = get_maxplayers()
	
	// Initialize dynamic arrays
	g_CustomViewModelsNames = ArrayCreate(128, 1)
	g_CustomWeaponModelsNames = ArrayCreate(128, 1)
	
	// Initialize array positions
	new id, weaponid
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		for (weaponid = CSW_FIRST_WEAPON; weaponid <= CSW_LAST_WEAPON; weaponid++)
		{
			g_CustomViewModelsPosition[id][weaponid] = POSITION_NULL
			g_CustomWeaponModelsPosition[id][weaponid] = POSITION_NULL
		}
	}
}

public plugin_natives()
{
	register_library("cs_weap_models_api")
	register_native("cs_set_player_view_model", "native_set_player_view_model")
	register_native("cs_reset_player_view_model", "native_reset_player_view_model")
	register_native("cs_set_player_weap_model", "native_set_player_weap_model")
	register_native("cs_reset_player_weap_model", "native_reset_player_weap_model")
}

public native_set_player_view_model(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	new weaponid = get_param(2)
	
	if (weaponid < CSW_FIRST_WEAPON || weaponid > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon id (%d)", weaponid)
		return false;
	}
	
	new view_model[128]
	get_string(3, view_model, charsmax(view_model))
	
	// Check whether player already has a custom view model set
	if (g_CustomViewModelsPosition[id][weaponid] == POSITION_NULL)
		AddCustomViewModel(id, weaponid, view_model)
	else
		ReplaceCustomViewModel(id, weaponid, view_model)
	
	// Get current weapon's id
	new current_weapon_ent = fm_cs_get_current_weapon_ent(id)
	new current_weapon_id = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1
	
	// Model was set for the current weapon?
	if (weaponid == current_weapon_id)
	{
		// Update weapon models manually
		fw_Item_Deploy_Post(current_weapon_ent)
	}
	return true;
}

public native_reset_player_view_model(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	new weaponid = get_param(2)
	
	if (weaponid < CSW_FIRST_WEAPON || weaponid > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon id (%d)", weaponid)
		return false;
	}
	
	// Player doesn't have a custom view model, no need to reset
	if (g_CustomViewModelsPosition[id][weaponid] == POSITION_NULL)
		return true;
	
	RemoveCustomViewModel(id, weaponid)
	
	// Get current weapon's id
	new current_weapon_ent = fm_cs_get_current_weapon_ent(id)
	new current_weapon_id = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1
	
	// Model was reset for the current weapon?
	if (weaponid == current_weapon_id)
	{
		// Let CS update weapon models
		ExecuteHamB(Ham_Item_Deploy, current_weapon_ent)
	}
	return true;
}

public native_set_player_weap_model(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	new weaponid = get_param(2)
	
	if (weaponid < CSW_FIRST_WEAPON || weaponid > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon id (%d)", weaponid)
		return false;
	}
	
	new weapon_model[128]
	get_string(3, weapon_model, charsmax(weapon_model))
	
	// Check whether player already has a custom view model set
	if (g_CustomWeaponModelsPosition[id][weaponid] == POSITION_NULL)
		AddCustomWeaponModel(id, weaponid, weapon_model)
	else
		ReplaceCustomWeaponModel(id, weaponid, weapon_model)
	
	// Get current weapon's id
	new current_weapon_ent = fm_cs_get_current_weapon_ent(id)
	new current_weapon_id = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1
	
	// Model was reset for the current weapon?
	if (weaponid == current_weapon_id)
	{
		// Update weapon models manually
		fw_Item_Deploy_Post(current_weapon_ent)
	}
	return true;
}

public native_reset_player_weap_model(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	new weaponid = get_param(2)
	
	if (weaponid < CSW_FIRST_WEAPON || weaponid > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon id (%d)", weaponid)
		return false;
	}
	
	// Player doesn't have a custom weapon model, no need to reset
	if (g_CustomWeaponModelsPosition[id][weaponid] == POSITION_NULL)
		return true;
	
	RemoveCustomWeaponModel(id, weaponid)
	
	// Get current weapon's id
	new current_weapon_ent = fm_cs_get_current_weapon_ent(id)
	new current_weapon_id = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1
	
	// Model was reset for the current weapon?
	if (weaponid == current_weapon_id)
	{
		// Let CS update weapon models
		ExecuteHamB(Ham_Item_Deploy, current_weapon_ent)
	}
	return true;
}

AddCustomViewModel(id, weaponid, const view_model[])
{
	g_CustomViewModelsPosition[id][weaponid] = g_CustomViewModelsCount
	ArrayPushString(g_CustomViewModelsNames, view_model)
	g_CustomViewModelsCount++
}

ReplaceCustomViewModel(id, weaponid, const view_model[])
{
	ArraySetString(g_CustomViewModelsNames, g_CustomViewModelsPosition[id][weaponid], view_model)
}

RemoveCustomViewModel(id, weaponid)
{
	new pos_delete = g_CustomViewModelsPosition[id][weaponid]
	
	ArrayDeleteItem(g_CustomViewModelsNames, pos_delete)
	g_CustomViewModelsPosition[id][weaponid] = POSITION_NULL
	g_CustomViewModelsCount--
	
	// Fix view models array positions
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		for (weaponid = CSW_FIRST_WEAPON; weaponid <= CSW_LAST_WEAPON; weaponid++)
		{
			if (g_CustomViewModelsPosition[id][weaponid] > pos_delete)
				g_CustomViewModelsPosition[id][weaponid]--
		}
	}
}

AddCustomWeaponModel(id, weaponid, const weapon_model[])
{
	ArrayPushString(g_CustomWeaponModelsNames, weapon_model)
	g_CustomWeaponModelsPosition[id][weaponid] = g_CustomWeaponModelsCount
	g_CustomWeaponModelsCount++
}

ReplaceCustomWeaponModel(id, weaponid, const weapon_model[])
{
	ArraySetString(g_CustomWeaponModelsNames, g_CustomWeaponModelsPosition[id][weaponid], weapon_model)
}

RemoveCustomWeaponModel(id, weaponid)
{
	new pos_delete = g_CustomWeaponModelsPosition[id][weaponid]
	
	ArrayDeleteItem(g_CustomWeaponModelsNames, pos_delete)
	g_CustomWeaponModelsPosition[id][weaponid] = POSITION_NULL
	g_CustomWeaponModelsCount--
	
	// Fix weapon models array positions
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		for (weaponid = CSW_FIRST_WEAPON; weaponid <= CSW_LAST_WEAPON; weaponid++)
		{
			if (g_CustomWeaponModelsPosition[id][weaponid] > pos_delete)
				g_CustomWeaponModelsPosition[id][weaponid]--
		}
	}
}

public client_disconnected(id)
{
	// Remove custom models for player after disconnecting
	new weaponid
	for (weaponid = CSW_FIRST_WEAPON; weaponid <= CSW_LAST_WEAPON; weaponid++)
	{
		if (g_CustomViewModelsPosition[id][weaponid] != POSITION_NULL)
			RemoveCustomViewModel(id, weaponid)
		if (g_CustomWeaponModelsPosition[id][weaponid] != POSITION_NULL)
			RemoveCustomWeaponModel(id, weaponid)
	}
}

public fw_Item_Deploy_Post(weapon_ent)
{
	// Get weapon's owner
	new owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	// Owner not valid
	if (!is_user_alive(owner))
		return;
	
	// Get weapon's id
	new weaponid = cs_get_weapon_id(weapon_ent)
	
	// Custom view model?
	if (g_CustomViewModelsPosition[owner][weaponid] != POSITION_NULL)
	{
		new view_model[128]
		ArrayGetString(g_CustomViewModelsNames, g_CustomViewModelsPosition[owner][weaponid], view_model, charsmax(view_model))
		set_pev(owner, pev_viewmodel2, view_model)
	}
	
	// Custom weapon model?
	if (g_CustomWeaponModelsPosition[owner][weaponid] != POSITION_NULL)
	{
		new weapon_model[128]
		ArrayGetString(g_CustomWeaponModelsNames, g_CustomWeaponModelsPosition[owner][weaponid], weapon_model, charsmax(weapon_model))
		set_pev(owner, pev_weaponmodel2, weapon_model)
	}
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}