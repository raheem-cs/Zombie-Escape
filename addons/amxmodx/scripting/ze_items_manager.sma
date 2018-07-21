#include <zombie_escape>

// Setting File
new const ZE_EXTRAITEM_FILE[] = "ze_extraitems.ini"

// Defines
#define MENU_PAGE_ITEMS g_iMenuData[id]

// Const
const OFFSET_CSMENUCODE = 205

// Forwards
enum _:TOTAL_FORWARDS
{
	FW_ITEM_SELECT_PRE = 0,
	FW_ITEM_SELECT_POST
}

new g_iForwards[TOTAL_FORWARDS],
	g_iForwardReturn

// Variables
new Array:g_szItemRealName, 
	Array:g_szItemName,  
	Array:g_iItemCost,
	Array:g_iItemLimit

new g_iItemCount, 
	g_szAdditionalMenuText[32],
	g_iMenuData[33]

public plugin_init()
{
	register_plugin("[ZE] Items Manager", ZE_VERSION, AUTHORS)
	
	// Commands
	register_clcmd("say /items", "Cmd_Items")
	
	// Forwards (In Pre Return Values important)
	g_iForwards[FW_ITEM_SELECT_PRE] = CreateMultiForward("ze_select_item_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_iForwards[FW_ITEM_SELECT_POST] = CreateMultiForward("ze_select_item_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
}

public plugin_natives()
{
	register_native("ze_register_item", "native_ze_register_item")
	register_native("ze_show_items_menu", "native_ze_show_items_menu")
	register_native("ze_force_buy_item", "native_ze_force_buy_item")
	register_native("ze_get_item_id", "native_ze_get_item_id")
	register_native("ze_get_item_cost", "native_ze_get_item_cost")
	register_native("ze_add_text_to_item", "native_ze_add_text_to_item")
	register_native("ze_get_item_limit", "native_ze_get_item_limit")
	register_native("ze_is_valid_itemid", "native_ze_is_valid_itemid")
	register_native("ze_get_item_name", "native_ze_get_item_name")
	
	g_szItemRealName = ArrayCreate(32, 1)
	g_szItemName = ArrayCreate(32, 1)
	g_iItemCost = ArrayCreate(1, 1)
	g_iItemLimit = ArrayCreate(1, 1)
}

public client_disconnected(id)
{
	MENU_PAGE_ITEMS = 0
}

public Cmd_Items(id)
{
	if (!is_user_alive(id))
		return
	
	Show_Items_Menu(id)
}

// Items Menu
Show_Items_Menu(id)
{
	static menu[128], name[32], cost, transkey[64]
	new menuid, index, itemdata[2]
	
	// Title
	formatex(menu, charsmax(menu), "%L:\r", id, "BUY_EXTRAITEM")
	menuid = menu_create(menu, "Extra_Items_Menu")
	
	// Item List
	for (index = 0; index < g_iItemCount; index++)
	{
		// Additional text to display
		g_szAdditionalMenuText[0] = 0
		
		// Execute item select attempt forward
		ExecuteForward(g_iForwards[FW_ITEM_SELECT_PRE], g_iForwardReturn, id, index, 0)
		
		// Show item to player?
		if (g_iForwardReturn >= ZE_ITEM_DONT_SHOW)
			continue;
		
		// Add Item Name and Cost
		ArrayGetString(g_szItemName, index, name, charsmax(name))
		cost = ArrayGetCell(g_iItemCost, index)
		
		// ML support for item name
		formatex(transkey, charsmax(transkey), "ITEMNAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		
		// Item available to player?
		if (g_iForwardReturn >= ZE_ITEM_UNAVAILABLE)
			formatex(menu, charsmax(menu), "\d%s %d	%s", name, cost, g_szAdditionalMenuText)
		else
			formatex(menu, charsmax(menu), "%s \y%d	\w%s", name, cost, g_szAdditionalMenuText)
		
		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// No items to display?
	if (menu_items(menuid) <= 0)
	{
		ze_colored_print(id, "%L", id, "NO_EXTRA_ITEMS")
		menu_destroy(menuid)
		return;
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_ITEMS = min(MENU_PAGE_ITEMS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_ITEMS)
}

// Items Menu
public Extra_Items_Menu(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_ITEMS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember items menu page
	MENU_PAGE_ITEMS = item / 7
	
	// Dead players are not allowed to buy items
	if (!is_user_alive(id))
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Retrieve item id
	new itemdata[2], dummy, itemid
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	itemid = itemdata[0]
	
	// Attempt to buy the item
	Buy_Item(id, itemid)
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

// Buy Item
Buy_Item(id, itemid, ignorecost = 0)
{
	// Execute item select attempt forward
	ExecuteForward(g_iForwards[FW_ITEM_SELECT_PRE], g_iForwardReturn, id, itemid, ignorecost)
	
	// Item available to player?
	if (g_iForwardReturn >= ZE_ITEM_UNAVAILABLE)
		return;
	
	// Execute item selected forward
	ExecuteForward(g_iForwards[FW_ITEM_SELECT_POST], g_iForwardReturn, id, itemid, ignorecost)
}

// Natives
public native_ze_register_item(plugin_id, num_params)
{
	new szItem_Name[32], iItem_Cost, iItem_Limit
	
	// Get the Data from first Parameter in the native (Item Name)
	get_string(1, szItem_Name, charsmax(szItem_Name))
	
	// Get the Second Parameter (Item Cost)
	iItem_Cost = get_param(2)
	
	// Get limit third parameter
	iItem_Limit = get_param(3)
	
	if (strlen(szItem_Name) < 1)
	{
		// Can't leave item name empty
		log_error(AMX_ERR_NATIVE, "[ZE] Can't register item with an empty name")
		return ZE_WRONG_ITEM // Same as return -1
	}
	
	new iIndex, szItemName[32]
	
	// Loop from 0 to max items amount
	for (iIndex = 0; iIndex < g_iItemCount; iIndex++)
	{
		ArrayGetString(g_szItemRealName, iIndex, szItemName, charsmax(szItemName))
		
		if (equali(szItem_Name, szItemName))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Item already registered (%s)", szItemName)
			return ZE_WRONG_ITEM; // Return -1
		}
	}
	
	// Load settings from extra items file
	new szItemRealName[32]
	copy(szItemRealName, charsmax(szItemRealName), szItem_Name)
	ArrayPushString(g_szItemRealName, szItemRealName)
	
	// Name
	if (!amx_load_setting_string(ZE_EXTRAITEM_FILE, szItemRealName, "NAME", szItem_Name, charsmax(szItem_Name)))
		amx_save_setting_string(ZE_EXTRAITEM_FILE, szItemRealName, "NAME", szItem_Name)
	ArrayPushString(g_szItemName, szItem_Name)
	
	// Cost
	if (!amx_load_setting_int(ZE_EXTRAITEM_FILE, szItemRealName, "COST", iItem_Cost))
		amx_save_setting_int(ZE_EXTRAITEM_FILE, szItemRealName, "COST", iItem_Cost)
	ArrayPushCell(g_iItemCost, iItem_Cost)
	
	// Limit
	if (!amx_load_setting_int(ZE_EXTRAITEM_FILE, szItemRealName, "LIMIT", iItem_Limit))
		amx_save_setting_int(ZE_EXTRAITEM_FILE, szItemRealName, "LIMIT", iItem_Limit)
	ArrayPushCell(g_iItemLimit, iItem_Limit)
	
	g_iItemCount++
	return g_iItemCount - 1
}

public native_ze_show_items_menu(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player (%d)", id)
		return false;
	}
	
	Cmd_Items(id)
	return true
}

public native_ze_force_buy_item(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player (%d)", id)
		return false;
	}
	
	new item_id = get_param(2)
	
	if (item_id < 0 || item_id >= g_iItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid item id (%d)", item_id)
		return false;
	}
	
	new ignorecost = get_param(3)
	
	Buy_Item(id, item_id, ignorecost)
	return true;
}

public native_ze_get_item_id(plugin_id, num_params)
{
	new szRealName[32]
	get_string(1, szRealName, charsmax(szRealName))

	new index, szItemName[32]
	
	for (index = 0; index < g_iItemCount; index++)
	{
		ArrayGetString(g_szItemRealName, index, szItemName, charsmax(szItemName))
		
		if (equali(szRealName, szItemName))
			return index
	}
	
	return ZE_WRONG_ITEM
}

public native_ze_get_item_cost(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_iItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid item id (%d)", item_id)
		return ZE_WRONG_ITEM;
	}
	
	return ArrayGetCell(g_iItemCost, item_id);
}

public native_ze_add_text_to_item(plugin_id, num_params)
{
	new szText[32]
	get_string(1, szText, charsmax(szText))
	format(g_szAdditionalMenuText, charsmax(g_szAdditionalMenuText), "%s%s", g_szAdditionalMenuText, szText)
}

public native_ze_get_item_limit(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_iItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid item id (%d)", item_id)
		return ZE_WRONG_ITEM;
	}
	
	return ArrayGetCell(g_iItemLimit, item_id);
}

public native_ze_is_valid_itemid(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_iItemCount)
	{
		return false;
	}
	
	return true;
}

public native_ze_get_item_name(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_iItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid item id (%d)", item_id)
		return ZE_WRONG_ITEM;
	}
	
	new szName[32]
	ArrayGetString(g_szItemName, item_id, szName, charsmax(szName))
	
	new iLen = get_param(3)
	set_string(2, szName, iLen)
	return true;
}