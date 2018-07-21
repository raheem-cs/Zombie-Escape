#include <zombie_escape>

// Setting File
new const ZE_SETTING_RESOURCES[] = "zombie_escape.ini"

// Keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
const OFFSET_CSMENUCODE = 205

// Primary Weapons Entities [Default Values]
new const szPrimaryWeaponEnt[][]=
{
	"weapon_m4a1",
	"weapon_ak47",
	"weapon_aug",
	"weapon_sg552",
	"weapon_galil",
	"weapon_famas",
	"weapon_scout",
	"weapon_awp",
	"weapon_sg550",
	"weapon_m249",
	"weapon_g3sg1",
	"weapon_ump45",
	"weapon_mp5navy",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_tmp",
	"weapon_mac10",
	"weapon_p90"
}

// Secondary Weapons Entities [Default Values]
new const szSecondaryWeaponEnt[][]=
{
	"weapon_usp",
	"weapon_glock18",
	"weapon_deagle",
	"weapon_p228",
	"weapon_elite",
	"weapon_fiveseven"
}

// Primary and Secondary Weapons Names [Default Values]
new const szWeaponNames[][] = 
{ 
	"", 
	"P228", 
	"",
	"Scout",
	"HE Grenade",
	"XM1014",
	"",
	"MAC-10",
	"AUG",
	"Smoke Grenade", 
	"Dual Elite",
	"Five Seven",
	"UMP 45",
	"SG-550",
	"Galil",
	"Famas",
	"USP",
	"Glock",
	"AWP",
	"MP5",
	"M249",
	"M3",
	"M4A1",
	"TMP",
	"G3SG1",
	"Flashbang",
	"Desert Eagle",
	"SG-552",
	"AK-47",
	"",
	"P90"
}

// Max Back Clip Ammo (Change it From here if you need)
new const szMaxBPAmmo[] =
{
	-1,
	52,
	-1,
	90,
	1,
	32,
	1,
	100,
	90,
	1,
	120,
	100,
	100,
	90,
	90,
	90,
	100,
	120,
	30,
	120,
	200,
	32,
	90,
	120,
	90,
	2,
	35,
	90,
	90,
	-1,
	100
}

// Menu selections
const MENU_KEY_AUTOSELECT = 7
const MENU_KEY_BACK = 7
const MENU_KEY_NEXT = 8
const MENU_KEY_EXIT = 9

// Variables
new Array:g_szPrimaryWeapons,
	Array:g_szSecondaryWeapons

new g_iMenuData[33][4], 
	Float:g_fBuyTimeStart[33], 
	bool:g_bBoughtPrimary[33], 
	bool:g_bBoughtSecondary[33]

// Define
#define WPN_STARTID g_iMenuData[id][0]
#define WPN_MAXIDS ArraySize(g_szPrimaryWeapons)
#define WPN_SELECTION (g_iMenuData[id][0]+key)
#define WPN_AUTO_ON g_iMenuData[id][1]
#define WPN_AUTO_PRI g_iMenuData[id][2]
#define WPN_AUTO_SEC g_iMenuData[id][3]

// Cvars
new g_pCvarBuyTime, 
	g_pCvarHEGrenade, 
	g_pCvarSmokeGrenade, 
	g_pCvarFlashGrenade
	
public plugin_natives()
{
	register_native("ze_show_weapon_menu", "native_ze_show_weapon_menu", 1)
	register_native("ze_is_auto_buy_enabled", "native_ze_is_auto_buy_enabled", 1)
	register_native("ze_disable_auto_buy", "native_ze_disable_auto_buy", 1)
}

public plugin_precache()
{
	// Initialize arrays (32 is the max length of Weapon Entity like: weapon_ak47)
	g_szPrimaryWeapons = ArrayCreate(32, 1)
	g_szSecondaryWeapons = ArrayCreate(32, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Weapons Menu", "PRIMARY", g_szPrimaryWeapons)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Weapons Menu", "SECONDARY", g_szSecondaryWeapons)
	
	// If we couldn't load from file, use and save default ones
	
	new iIndex
	
	if (ArraySize(g_szPrimaryWeapons) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szPrimaryWeaponEnt; iIndex++)
			ArrayPushString(g_szPrimaryWeapons, szPrimaryWeaponEnt[iIndex])
		
		// If not found .ini File Create it and save default values in it
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Weapons Menu", "PRIMARY", g_szPrimaryWeapons)
	}
	
	if (ArraySize(g_szSecondaryWeapons) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szSecondaryWeaponEnt; iIndex++)
			ArrayPushString(g_szSecondaryWeapons, szSecondaryWeaponEnt[iIndex])
		
		// If not found .ini File Create it and save default values in it
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Weapons Menu", "SECONDARY", g_szSecondaryWeapons)
	}
}

public plugin_init()
{
	register_plugin("[ZE] Weapons Menu", ZE_VERSION, AUTHORS)
	
	// Commands
	register_clcmd("guns", "Cmd_Buy")
	register_clcmd("say /enable", "Cmd_Enable")
	register_clcmd("say_team /enable", "Cmd_Enable")
	
	// Cvars
	g_pCvarBuyTime = register_cvar("ze_buy_time", "60")
	g_pCvarHEGrenade = register_cvar("ze_give_HE_nade", "1") // 0 Nothing || 1 Give HE
	g_pCvarSmokeGrenade = register_cvar("ze_give_SM_nade", "1")
	g_pCvarFlashGrenade = register_cvar("ze_give_FB_nade", "1")
	
	// Menus
	register_menu("Primary Weapons", KEYSMENU, "Menu_Buy_Primary")
	register_menu("Secondary Weapons", KEYSMENU, "Menu_Buy_Secondary")
}

public client_disconnected(id)
{
	WPN_AUTO_ON = 0
	WPN_STARTID = 0
}

public Cmd_Enable(id)
{
	if (WPN_AUTO_ON)
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "BUY_ENABLED")
		WPN_AUTO_ON = 0
	}
}

public Cmd_Buy(id)
{
	// Player Zombie
	if (ze_is_user_zombie(id))
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "NO_BUY_ZOMBIE")
		return
	}
	
	// Player Dead
	if (!is_user_alive(id))
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "DEAD_CANT_BUY_WEAPON")
		return
	}
	
	// Already bought
	if (g_bBoughtPrimary[id] && g_bBoughtSecondary[id])
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "ALREADY_BOUGHT")
	}
	
	Show_Available_Buy_Menus(id)
}

public ze_user_humanized(id)
{
	// Buyzone time starts when player is set to human
	g_fBuyTimeStart[id] = get_gametime()
	
	g_bBoughtPrimary[id] = false
	g_bBoughtSecondary[id] = false
	
	// Player dead or zombie
	if (!is_user_alive(id) || ze_is_user_zombie(id))
		return
	
	if (WPN_AUTO_ON)
		ze_colored_print(id, "%L", LANG_PLAYER, "RE_ENABLE_MENU")
		
	if (WPN_AUTO_ON)
	{
		Buy_Primary_Weapon(id, WPN_AUTO_PRI)
	}

	if (WPN_AUTO_ON)
	{
		Buy_Secondary_Weapon(id, WPN_AUTO_SEC)
	}
	
	// Open available buy menus
	Show_Available_Buy_Menus(id)
	
	// Give HE Grenade
	if (get_pcvar_num(g_pCvarHEGrenade) != 0)
		rg_give_item(id, "weapon_hegrenade")
	
	// Give Smoke Grenade
	if (get_pcvar_num(g_pCvarSmokeGrenade) != 0)
		rg_give_item(id, "weapon_smokegrenade")
	
	// Give Flashbang Grenade
	if (get_pcvar_num(g_pCvarFlashGrenade) != 0)
		rg_give_item(id, "weapon_flashbang")
}

public Show_Available_Buy_Menus(id)
{
	// Already Bought
	if (g_bBoughtPrimary[id] && g_bBoughtSecondary[id])
		return
	
	// Here we use if and else if so we make sure that Primary weapon come first then secondary
	if (!g_bBoughtPrimary[id])
	{
		// Primary		
		Show_Menu_Buy_Primary(id)
	}
	else if (!g_bBoughtSecondary[id])
	{
		// Secondary
		Show_Menu_Buy_Secondary(id)
	}
}

public Show_Menu_Buy_Primary(id)
{
	new iMenuTime = floatround(g_fBuyTimeStart[id] + get_pcvar_float(g_pCvarBuyTime) - get_gametime())
	
	if (iMenuTime <= 0)
	{
		ze_colored_print(id, "%L", id, "BUY_MENU_TIME_EXPIRED")
		return
	}
	
	static szMenu[300], szWeaponName[32]
	new iLen, iIndex, iMaxLoops = min(WPN_STARTID+7, WPN_MAXIDS)
	
	// Title
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%L \w[\r%d\w-\r%d\w]^n^n", id, "MENU_PRIMARY_TITLE", WPN_STARTID+1, min(WPN_STARTID+7, WPN_MAXIDS))
	
	// 1-7. Weapon List
	for (iIndex = WPN_STARTID; iIndex < iMaxLoops; iIndex++)
	{
		ArrayGetString(g_szPrimaryWeapons, iIndex, szWeaponName, charsmax(szWeaponName))
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\w%d.\y %s^n", iIndex-WPN_STARTID+1, szWeaponNames[get_weaponid(szWeaponName)])
	}
	
	// 8. Auto Select
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\w8.\y %L \w[\r%L\w]", id, "MENU_AUTOSELECT", id, (WPN_AUTO_ON) ? "SAVE_YES" : "SAVE_NO")
	
	// 9. Next/Back - 0. Exit
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\y9.\r %L \w/ \r%L^n^n\w0.\y %L", id, "NEXT", id, "BACK", id, "EXIT")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, szMenu, iMenuTime, "Primary Weapons")
}

public Show_Menu_Buy_Secondary(id)
{
	new iMenuTime = floatround(g_fBuyTimeStart[id] + get_pcvar_float(g_pCvarBuyTime) - get_gametime())
	
	if (iMenuTime <= 0)
	{
		ze_colored_print(id, "%L", id, "BUY_MENU_TIME_EXPIRED")
		return
	}
	
	static szMenu[250], szWeaponName[32]
	new iLen, iIndex, iMaxLoops = ArraySize(g_szSecondaryWeapons)
	
	// Title
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%L^n", id, "MENU_SECONDARY_TITLE")
	
	// 1-6. Weapon List
	for (iIndex = 0; iIndex < iMaxLoops; iIndex++)
	{
		ArrayGetString(g_szSecondaryWeapons, iIndex, szWeaponName, charsmax(szWeaponName))
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\w%d.\y %s", iIndex+1, szWeaponNames[get_weaponid(szWeaponName)])
	}
	
	// 8. Auto Select
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\w8.\y %L \w[\r%L\w]", id, "MENU_AUTOSELECT", id, (WPN_AUTO_ON) ? "SAVE_YES" : "SAVE_NO")
	
	// 0. Exit
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\w0.\y %L", id, "EXIT")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, szMenu, iMenuTime, "Secondary Weapons")
}

public Menu_Buy_Primary(id, key)
{
	// Player dead or zombie or already bought primary
	if (!is_user_alive(id) || ze_is_user_zombie(id) || g_bBoughtPrimary[id])
		return PLUGIN_HANDLED
	
	// Special keys / weapon list exceeded
	if (key >= MENU_KEY_AUTOSELECT || WPN_SELECTION >= WPN_MAXIDS)
	{
		switch (key)
		{
			case MENU_KEY_AUTOSELECT: // toggle auto select
			{
				WPN_AUTO_ON = 1 - WPN_AUTO_ON
			}
			case MENU_KEY_NEXT: // next/back
			{
				if (WPN_STARTID+7 < WPN_MAXIDS)
					WPN_STARTID += 7
				else
					WPN_STARTID = 0
			}
			case MENU_KEY_EXIT: // exit
			{
				return PLUGIN_HANDLED
			}
		}
		
		// Show buy menu again
		Show_Menu_Buy_Primary(id)
		return PLUGIN_HANDLED
	}
	
	// Store selected weapon id
	WPN_AUTO_PRI = WPN_SELECTION
	
	// Buy primary weapon
	Buy_Primary_Weapon(id, WPN_AUTO_PRI)
	
	// Show Secondary Weapons
	Show_Available_Buy_Menus(id)
	
	return PLUGIN_HANDLED
}

public Buy_Primary_Weapon(id, selection)
{
	static szWeaponName[32]
	ArrayGetString(g_szPrimaryWeapons, selection, szWeaponName, charsmax(szWeaponName))
	new iWeaponId = get_weaponid(szWeaponName)
	
	// Strip and Give Full Weapon
	rg_give_item(id, szWeaponName, GT_REPLACE)
	rg_set_user_bpammo(id, WeaponIdType:iWeaponId, szMaxBPAmmo[iWeaponId])
	
	// Primary bought
	g_bBoughtPrimary[id] = true
}

public Menu_Buy_Secondary(id, key)
{
	// Player dead or zombie or already bought secondary
	if (!is_user_alive(id) || ze_is_user_zombie(id) || g_bBoughtSecondary[id])
		return PLUGIN_HANDLED
	
	// Special keys / weapon list exceeded
	if (key >= ArraySize(g_szSecondaryWeapons))
	{
		// Toggle autoselect
		if (key == MENU_KEY_AUTOSELECT)
			WPN_AUTO_ON = 1 - WPN_AUTO_ON
		
		// Reshow menu unless user exited
		if (key != MENU_KEY_EXIT)
			Show_Menu_Buy_Secondary(id)
		
		return PLUGIN_HANDLED
	}
	
	// Store selected weapon id
	WPN_AUTO_SEC = key
	
	// Buy secondary weapon
	Buy_Secondary_Weapon(id, key)
	
	return PLUGIN_HANDLED
}

public Buy_Secondary_Weapon(id, selection)
{
	static szWeaponName[32]
	ArrayGetString(g_szSecondaryWeapons, selection, szWeaponName, charsmax(szWeaponName))
	new iWeaponId = get_weaponid(szWeaponName)
	
	// Strip and Give Full Weapon
	rg_give_item(id, szWeaponName, GT_REPLACE)
	rg_set_user_bpammo(id, WeaponIdType:iWeaponId, szMaxBPAmmo[iWeaponId])
	
	// Secondary bought
	g_bBoughtSecondary[id] = true
}

// Natives
public native_ze_show_weapon_menu(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player (%d)", id)
		return false
	}
	
	Cmd_Buy(id)
	return true
}

public native_ze_is_auto_buy_enabled(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player (%d)", id)
		return -1;
	}
	
	return WPN_AUTO_ON;
}

public native_ze_disable_auto_buy(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player (%d)", id)
		return false
	}
	
	WPN_AUTO_ON = 0;
	return true
}