#include <zombie_escape>

// Keys
const OFFSET_CSMENUCODE = 205
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

public plugin_init()
{
	register_plugin("[ZE] Main Menu", ZE_VERSION, AUTHORS)
	
	// Commands
	register_clcmd("chooseteam", "Cmd_ChooseTeam")
	register_clcmd("say /ze", "Cmd_ChooseTeam")
	register_clcmd("say_team /ze", "Cmd_ChooseTeam")
	
	// Register Menus
	register_menu("Main Menu", KEYSMENU, "Main_Menu")
}

public Cmd_ChooseTeam(id)
{
	if (get_member(id, m_iTeam) != TEAM_SPECTATOR)
	{
		Show_Menu_Main(id)
		return PLUGIN_HANDLED // Kill the Choose Team Command
	}
	
	// Player in Spec? Allow him to open choose team menu so he can join
	return PLUGIN_CONTINUE
}

// Main Menu
public Show_Menu_Main(id)
{
	static szMenu[250]
	new iLen
    
	// Title
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\w%L^n^n", id, "MAIN_MENU_TITLE")
	
	// 1. Buy Weapons
	if (is_user_alive(id))
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\w1.\r %L^n", id, "MENU_WEAPONBUY")
	}
	else
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d1. %L^n", id, "MENU_WEAPONBUY")
	}
	
	// 2. Extra Items
	if (is_user_alive(id))
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\w2.\r %L^n", id, "MENU_EXTRABUY")
	}
	else
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d2. %L^n", id, "MENU_EXTRABUY")
	}
    
	// 0. Exit
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\w0.\r %L", id, "EXIT")
    
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, szMenu, -1, "Main Menu")
}

// Main Menu
public Main_Menu(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED
    
	switch (key)
	{
		case 0: // Buy Weapons
		{
			client_cmd(id, "guns")
		}
		case 1: // Extra Items
		{
			if (is_user_alive(id))
			{
				ze_show_items_menu(id)
			}
			else
			{
				ze_colored_print(id, "%L", id, "DEAD_CANT_BUY_WEAPON")
			}
		}
	}
	return PLUGIN_HANDLED
}