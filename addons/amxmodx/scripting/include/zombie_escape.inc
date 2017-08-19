#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>
#include <amxmisc>
#include <zombie_escape_stocks>

#define ZE_VERSION "1.2"
#define AUTHORS "ZE Dev Team"


/*
*   For More Information About These Natives and Forwards, Just vist our site:
*                          Escapers-Zone.XYZ
*/

enum
{
	ZE_TEAM_ZOMBIE = 1,
	ZE_TEAM_HUMAN
}

// Returns Used in ze_select_item_pre()
#define ZE_WRONG_ITEM -1
#define ZE_ITEM_AVAILABLE 0
#define ZE_ITEM_UNAVAILABLE 1
#define ZE_ITEM_DONT_SHOW 2

// Max Extra-Items
#define MAX_EXTRA_ITEMS 40

// Forwards
forward ze_roundend(WinTeam);
forward ze_user_humanized(id);
forward ze_user_infected(iVictim, iInfector);
forward ze_zombie_appear();
forward ze_zombie_release();
forward ze_game_started();

forward ze_select_item_pre(id, iItemid, ignorecost);
forward ze_select_item_post(id, iItemid, ignorecost);

forward ze_fire_pre(id);

forward ze_frost_pre(id);
forward ze_frost_unfreeze(id);

// Natives
native ze_is_user_zombie(id);
native ze_set_user_zombie(id);
native ze_set_user_human(id);
native ze_is_game_started();

native ze_get_escape_coins(id);
native ze_set_escape_coins(id, iAmount);

native ze_register_item(const szItemName[], iCost, iLimit);
native ze_show_items_menu(id);
native ze_force_buy_item(id, iItemid, ignorecost = false);
native ze_get_item_id(const szItemName[]);
native ze_get_item_cost(iItemid);
native ze_add_text_to_item(const szText[]);
native ze_get_item_limit(iItemid);

native ze_zombie_in_madness(id);

native ze_set_fire_grenade(id, set);
native ze_zombie_in_fire(id);

native ze_zombie_in_forst(id);
native ze_set_frost_grenade(id, set);

native ze_get_escape_leader_id();


// Setting API Natives
native amx_load_setting_string_arr(const filename[], const section[], const key[], Array:array_handle)
native amx_save_setting_string_arr(const filename[], const section[], const key[], Array:array_handle)
native amx_load_setting_int_arr(const filename[], const section[], const key[], Array:array_handle)
native amx_save_setting_int_arr(const filename[], const section[], const key[], Array:array_handle)
native amx_load_setting_float_arr(const filename[], const section[], const key[], Array:array_handle)
native amx_save_setting_float_arr(const filename[], const section[], const key[], Array:array_handle)
native amx_load_setting_string(const filename[], const section[], const key[], setting_string[], len)
native amx_save_setting_string(const filename[], const section[], const key[], const setting_string[])
native amx_load_setting_int(const filename[], const section[], const key[], &integer_value)
native amx_save_setting_int(const filename[], const section[], const key[], integer_value)
native amx_load_setting_float(const filename[], const section[], const key[], &Float:float_value)
native amx_save_setting_float(const filename[], const section[], const key[], Float:float_value)

// CS Weapon Model
native cs_set_player_view_model(id, weaponid, const view_model[])
native cs_reset_player_view_model(id, weaponid)
native cs_set_player_weap_model(id, weaponid, const weapon_model[])
native cs_reset_player_weap_model(id, weaponid)