#include <zombie_escape>

new g_iCurrentEC, 
	g_iRequiredEC

public plugin_init()
{
	register_plugin("[ZE] Items Manager: Escape Coins", ZE_VERSION, AUTHORS)
}

public ze_select_item_pre(id, itemid, ignorecost)
{
	if (ignorecost)
		return ZE_ITEM_AVAILABLE
	
	g_iCurrentEC = ze_get_escape_coins(id)
	g_iRequiredEC = ze_get_item_cost(itemid)
	
	if (g_iCurrentEC < g_iRequiredEC)
		return ZE_ITEM_UNAVAILABLE
	
	return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(id, itemid, ignorecost)
{
	if (ignorecost)
		return
	
	g_iCurrentEC = ze_get_escape_coins(id)
	g_iRequiredEC = ze_get_item_cost(itemid)
	
	ze_set_escape_coins(id, g_iCurrentEC - g_iRequiredEC)
}