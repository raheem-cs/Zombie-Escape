#include <zombie_escape>

new g_iCurrent_EscapeCoins, g_iRequired_EscapeCoins

public plugin_init()
{
	register_plugin("[ZE] Items Manager: Escape Coins", ZE_VERSION, AUTHORS)
}

public ze_select_item_pre(id, itemid, ignorecost)
{
	if (ignorecost)
		return ZE_ITEM_AVAILABLE
	
	g_iCurrent_EscapeCoins = ze_get_escape_coins(id)
	g_iRequired_EscapeCoins = ze_get_item_cost(itemid)
	
	if (g_iCurrent_EscapeCoins < g_iRequired_EscapeCoins)
		return ZE_ITEM_UNAVAILABLE
	
	return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(id, itemid, ignorecost)
{
	if (ignorecost)
		return
	
	g_iCurrent_EscapeCoins = ze_get_escape_coins(id)
	g_iRequired_EscapeCoins = ze_get_item_cost(itemid)
	
	ze_set_escape_coins(id, g_iCurrent_EscapeCoins - g_iRequired_EscapeCoins)
}