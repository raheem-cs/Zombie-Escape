#include <zombie_escape>

// Variables
new g_iLimitCounter[MAX_PLAYERS+1][MAX_EXTRA_ITEMS],
	g_iMaxClients

public plugin_init()
{
	register_plugin("[ZE] Items Manager: Limit", ZE_VERSION, AUTHORS)
	
	// Static Values
	g_iMaxClients = get_member_game(m_nMaxPlayers)
}

public ze_select_item_pre(id, itemid, ignorecost)
{
	new iLimit = ze_get_item_limit(itemid)
	
	if (iLimit > 0)
	{
		// Format extra text to be added beside our item
		new szText[32]
		formatex(szText, charsmax(szText), " %L", id, "ITEM_LIMIT", g_iLimitCounter[id][itemid], iLimit)
		
		// Add the text
		ze_add_text_to_item(szText)
		
		// Check if reached max or not?
		if (g_iLimitCounter[id][itemid] >= iLimit)
		{
			return ZE_ITEM_UNAVAILABLE
		}
	}
	
	return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(id, itemid, ignorecost)
{
	if (ignorecost)
		return
	
	// Increase Counter by 1
	g_iLimitCounter[id][itemid]++
}

public ze_game_started()
{
	// Rest our counter to zero
	for (new j = 1; j <= g_iMaxClients; j++)
	{
		for (new i = 0; i < MAX_EXTRA_ITEMS; i++)
		{
			g_iLimitCounter[j][i] = 0
		}
	}
}