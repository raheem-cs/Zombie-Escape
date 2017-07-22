#include <zombie_escape>

// Default Sound
new const g_szBuyAmmoSound[] = "items/9mmclip1.wav"

// Variables
new g_iItemID

public plugin_init()
{
	register_plugin("[ZE] Items: Fire Nade", ZE_VERSION, AUTHORS)
	
	// Register our item
	g_iItemID = ze_register_item("Fire Nade", 30, 0)
}

public ze_select_item_pre(id, itemid)
{
	// Return Available and we will block it in Post, So it dosen't affect other plugins
	if (itemid != g_iItemID)
		return ZE_ITEM_AVAILABLE
	
	// Available for Humans only, So don't show it for zombies
	if (ze_is_user_zombie(id))
		return ZE_ITEM_DONT_SHOW
	
	return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(id, itemid)
{
	// This is not our item, Block it here
	if (itemid != g_iItemID)
		return
	
	// Get Weapon ID
	new iWpnID = get_weaponid("weapon_hegrenade")
	
	// Player Don't have Frost Grenade then give him
	if (rg_get_user_bpammo(id, WeaponIdType:iWpnID) == 0)
	{
		rg_give_item(id, "weapon_hegrenade", GT_APPEND)
	}
	else
	{
		// Player have, Increase his Back Pack Ammo, And play buy BP sound + Hud Flash
		rg_set_user_bpammo(id, WeaponIdType:iWpnID, rg_get_user_bpammo(id, WeaponIdType:iWpnID) + 1)
		emit_sound(id, CHAN_ITEM, g_szBuyAmmoSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		Show_Given_BPAmmo(id, 12, 1) // HE Grenade AmmoType Const = 12
	}
}