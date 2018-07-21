#include <zombie_escape>
#include <ze_vip>

// Setting file
new const ZE_EXTRAITEM_FILE[] = "ze_extraitems.ini"

new g_iVIP_Item[MAX_EXTRA_ITEMS],
	bool:g_bRegistered[MAX_EXTRA_ITEMS]

public plugin_natives()
{
	register_native("ze_set_item_vip", "native_ze_set_item_vip")
	register_native("ze_get_item_vip", "native_ze_get_item_vip", 1)
}

public plugin_init()
{
	register_plugin("[ZE] Items Manager: VIP", ZE_VERSION, AUTHORS)
}

public ze_select_item_pre(id, itemid)
{
	if (g_bRegistered[itemid])
	{
		new iFlag = g_iVIP_Item[itemid]
		
		// Skip only in case of Z Flag, normal players
		if (iFlag != VIP_Z)
		{
			// Format extra text
			new szText[32]
			formatex(szText, charsmax(szText), " %L", id, "ITEM_VIP")
			
			// Add it
			ze_add_text_to_item(szText)
			
			// Player not VIP?
			if (!(ze_get_vip_flags(id) & iFlag))
			{
				return ZE_ITEM_UNAVAILABLE
			}
		}

		return ZE_ITEM_AVAILABLE
	}
	
	return ZE_ITEM_AVAILABLE
}

public native_ze_set_item_vip(plugin_id, num_params)
{
	new iItemid, szFlag[6]
	
	iItemid = get_param(1)
	get_string(2, szFlag, charsmax(szFlag))

	if (!ze_is_valid_itemid(iItemid))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid item id (%d)", iItemid)
		return ZE_WRONG_ITEM;
	}
	
	g_iVIP_Item[iItemid] = read_flags(szFlag)
	g_bRegistered[iItemid] = true

	new szItemName[32]
	ze_get_item_name(iItemid, szItemName, charsmax(szItemName))
	
	if (!amx_load_setting_string(ZE_EXTRAITEM_FILE, szItemName, "VIP FLAG", szFlag, charsmax(szFlag)))
	{
		amx_save_setting_string(ZE_EXTRAITEM_FILE, szItemName, "VIP FLAG", szFlag)
		return true;
	}
	
	g_iVIP_Item[iItemid] = read_flags(szFlag)
	
	return true;
}

public native_ze_get_item_vip(iItemid)
{
	if (!ze_is_valid_itemid(iItemid))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid item id (%d)", iItemid)
		return ZE_WRONG_ITEM;
	}
	
	return g_iVIP_Item[iItemid];
}