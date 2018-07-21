#include <zombie_escape>
#include <ze_levels>

// Setting file
new const ZE_EXTRAITEM_FILE[] = "ze_extraitems.ini"

new g_iItem_Level[MAX_EXTRA_ITEMS],
	bool:g_bRegistered[MAX_EXTRA_ITEMS]

public plugin_natives()
{
	register_native("ze_set_item_level", "native_ze_set_item_level", 1)
	register_native("ze_get_item_level", "native_ze_get_item_level", 1)
}

public plugin_init()
{
	register_plugin("[ZE] Items Manager: Level", ZE_VERSION, AUTHORS)
}

public ze_select_item_pre(id, itemid)
{
	if (g_bRegistered[itemid])
	{
		new iLevel = g_iItem_Level[itemid];

		// Format extra text
		new szText[32]
		formatex(szText, charsmax(szText), " %L", id, "ITEM_LEVEL", iLevel)
			
		// Add it
		ze_add_text_to_item(szText)
			
		// Player level still not higher than require level? Block item
		if (ze_get_user_level(id) < iLevel)
		{
			return ZE_ITEM_UNAVAILABLE
		}

		return ZE_ITEM_AVAILABLE
	}
	
	return ZE_ITEM_AVAILABLE
}

public native_ze_set_item_level(iItemid, iLevel)
{
	if (!ze_is_valid_itemid(iItemid))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid item id (%d)", iItemid)
		return ZE_WRONG_ITEM;
	}
	
	if (iLevel < 0)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid level (%d)", iLevel)
		return false;
	}
	
	g_iItem_Level[iItemid] = iLevel
	g_bRegistered[iItemid] = true

	new szItemName[32]
	ze_get_item_name(iItemid, szItemName, charsmax(szItemName))

	if (!amx_load_setting_int(ZE_EXTRAITEM_FILE, szItemName, "LEVEL", g_iItem_Level[iItemid]))
		amx_save_setting_int(ZE_EXTRAITEM_FILE, szItemName, "LEVEL", g_iItem_Level[iItemid])
	
	return true;
}

public native_ze_get_item_level(iItemid)
{
	if (!ze_is_valid_itemid(iItemid))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid item id (%d)", iItemid)
		return ZE_WRONG_ITEM;
	}
	
	return g_iItem_Level[iItemid];
}