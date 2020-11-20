#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>
#include <sqlx>
#include <amxmisc>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <zombie_escape_stocks>

#define ZE_VERSION "1.6"
#define AUTHORS "ZE Dev Team"

/*
*	For more information about these natives and forwards, just vist our forum:
*						Escapers-Zone.net
*/

// Team constants, use them in ze_roundend() forward 
enum
{
	ZE_TEAM_ZOMBIE = 0,
	ZE_TEAM_HUMAN
}

// Items returns used in ze_select_item_pre()
#define ZE_WRONG_ITEM -1
#define ZE_ITEM_AVAILABLE 0
#define ZE_ITEM_UNAVAILABLE 1
#define ZE_ITEM_DONT_SHOW 2

// General forwards return values
#define ZE_CONTINUE 0
#define ZE_STOP 1

// Max Extra-Items
#define MAX_EXTRA_ITEMS 60

// Forwards

/*
* Description:		Called on round end event.
*
* @param WinTeam	The win team ZE_TEAM_ZOMBIE or ZE_TEAM_HUMAN.
*
* @return			Returns here useless, it will not affect the real end round event.
*
*/
forward ze_roundend(WinTeam);

/*
* Description:	Called when user humanized, it called whenever 
*				ze_set_user_human(id) native used.
*				It's called also at every new round when all players humanized.
*
* @param id		Client index.
*
* @return		Returns here useless, it will not affect the real humanization event.
*
*/
forward ze_user_humanized(id);

/*
* Description:		Called before user get infected by player.
*
* @param iVictim	Victim index, human who will catch the infection.
* @param iInfector	Infector index, zombie who will cause the infection.
* @param iDamage	The blocked damage value.
*
* @return			To stop the infection event use:   return ZE_STOP
*					To let the infection continue use: return ZE_CONTINUE
*
* @note				This forward will not called on the zombie choose by the server,
*					only called if player try to infect player.
*					You can use pre to block the infection or to let it in specific conditions.
*					Basically return > ZE_CONTINUE  will stop the infection.
*			
*/
forward ze_user_infected_pre(iVictim, iInfector, iDamage);

/*
* Description:		Called when user infected by player or by the server.
*					Called also at the first choose of zombies (in this case server is the infector).
*
* @param iVictim	Victim index, human who catch the infection.
* @param iInfector	Infector index, zombie or server who caused the infection.
*
* @return			Returns here useless, it will not affect the real infection event.
*
* @note				If the infector is the server, The iInfector will be 0
*					else the iInfector will be the zombie id.		
*
*/
forward ze_user_infected(iVictim, iInfector);

/*
* Description:	Called when zombies chosen.
*
* @return		Returns here useless, it will not affect the real appearing event.
*
*/
forward ze_zombie_appear();

/*
* Description:	Called when the chosen zombies released.
*
* @return		Returns here useless, it will not affect the real releasing event.
*
*/
forward ze_zombie_release();

/*
* Description:	Called every new round if game started.
*
* @return		To block zombie escape round return ZE_STOP, To continue zombie escape mod return ZE_CONTINUE.
*
* @note			This called every new round only if the game started
*				which mean players is higher than required player so game already started.
*				this native somehow similar to new round event but only called when game started.
*				You can use it to block zombie escape mod round, and use your own round like Nemesis round
*				make sure to use this after first round, never return ZE_STOP in first round.
*
*/
forward ze_game_started_pre();

/*
* Description:	Called every new round if game started.
*
* @return		Returns here useless, it will not affect the real new round event.
*
* @note			This called every new round only if the game started
*				which mean players is higher than required player so game already started.
*				this native somehow similar to new round event but only called when game started.
*
*/
forward ze_game_started();

/*
* Description:	Called before zombie (or human) get fired by fire nade.
*
* @return		Return ZE_STOP to stop the fire action, zombie will not get fired.
*				Return ZE_CONTINUE to continue the fire, zombie will be fired.
*
* @note			You can use this to stop the fire action at specific conditions.
*
*/
forward ze_fire_pre(id);

/*
* Description:	Called before zombie (or human) get frozen by frost nade.
*
* @return		Return ZE_STOP to stop the freeze action, zombie will not get frozen.
*				Return ZE_CONTINUE to continue the freeze, zombie will be frozen.
*
* @note			You can use this to stop the freeze action at specific conditions.
*
*/
forward ze_frost_pre(id);

/*
* Description:	Called when zombie get unfrozen.
*
* @return		Returns here useless, it will not affect the real unfreeze event.
*
*/
forward ze_frost_unfreeze(id);

/*
* Description:			Called when player opens the extra-items menu.
*						Or when he choose the item but before he get it.
*
* @param id				Client index.
* @param iItemid		Index of item he try to buy.
* @param bIgnoreCost	true will ignore the cost, false will not ignore cost.
*
* @return				ZE_ITEM_AVAILABLE   | Shows item in the menu, player can also buy it.
*						ZE_ITEM_UNAVAILABLE | Show to player but he can't but it.
*						ZE_ITEM_DONT_SHOW   | Item not appear to that player.
*
*/
forward ze_select_item_pre(id, iItemid, bIgnoreCost);

/*
* Description:			Called after player choose the item,
*						called only if ze_select_item_pre() returned ZE_ITEM_AVAILABLE.
*
* @param id				Client index.
* @param iItemid		Index of item he try to buy.
* @param bIgnoreCost	true will ignore the cost, false will not ignore cost.
*
* @return				Returns here useless, it will not affect the real buy event.
*
*/
forward ze_select_item_post(id, iItemid, bIgnoreCost);

/*
* Description:			Called when player disconnect.
*
* @param id				Client index.
*
* @return				return ZE_CONTINUE | Will continue Mod game rules.
*						return ZE_STOP | Will block Mod game rules, you can use yours.
*
* @note					Useful in plugins like, replacing disconnected zombie/human if he was last zombie/human.
*
*/
forward ze_player_disconnect(id);

// Natives

/*
* Description:	Check if user zombie or not.
*
* @param id		Client index.
*
* @return		true  | If user Zombie.
*				false | If user Human.
*				-1    | If player not connected.
*
*/
native ze_is_user_zombie(id);

/*
* Description:	Check if game started or not.
*				Game start when minimun required players connected.
*
* @return		true  | If game started.
*				false | If game not started yet.
*
*/
native ze_is_game_started();

/*
* Description:	Check if this zombie in pre-release time or not.
*				Pre-Release time is said to be freeze time for zombies.
*
* @param id		Client index.
*
* @return		true  | If this zombie in freeze time.
*				false | If this zombie not in freeze time.
*				-1    | If player not connected or this player is Human.
*
*/
native ze_is_zombie_frozen(id);

/*
* Description:	Return current round number (Integer).
*				First round is round 1, second is 2 ... etc.
*
* @return		Round number | If game started
*				-1           | If game not started yet
*
*/
native ze_get_round_number();

/*
* Description:	Return alive humans number (Integer).
*
* @return		Alive humans number.
*
*/
native ze_get_humans_number();

/*
* Description:	Return alive zombies number (Integer).
*
* @return		Alive zombies number.
*
*/
native ze_get_zombies_number();

/*
* Description:	Set user to zombie team.
*
* @param id		Client index.
*
* @return		true  | If set successfully
*				false | If this player not connected
*
* @note			This will throw error in case of invalid player.
*
*/
native ze_set_user_zombie(id);

/*
* Description:	Set user to human team.
*
* @param id		Client index.
*
* @return		true  | If set successfully
*				false | If this player not connected
*
* @note			This will throw error in case of invalid player.
*
*/
native ze_set_user_human(id);

/*
* Description:		Increase human speed with this factor.
*					This factor added to his current speed depend on which weapon he carries.
*
* @param id			Client index.
* @param iFactor	The factor to be added to current speed.
*
* @return			true  | If set successfully
*					false | If this player not connected
*
* @note				This native will add speed to current speed.
*					For example, ze_set_human_speed_factor(id, 0) will not set player speed to zero
*					it won't increase his speed so he will have normal weapon speed.
*					Example, if player carry knife and ze_set_human_speed_factor(id, 20) his speed will be 
*					increased by 20 so his total speed will be 270 (default knife speed: 250)
*					You may use negative factors to decrease this speed.
*					Using this native will set the players speed for the whole map.
*					Speeds reset if this player disconnect, or reset using reset native.
*					This is limited by sv_maxspeed cvar.
*					This will throw error in case of invalid player.
*
*/
native ze_set_human_speed_factor(id, iFactor);

/*
* Description:	Reset human speed to default value used in ze_human_speed_factor cvar.
*
* @param id		Client index.
*
* @return		true  | If reset successfully
*				false | If this player not connected
*
* @note			This will remove the custom speed factor set by
*				ze_set_human_speed_factor(id, iFactor) native.
*				And will use the default factor in ze_human_speed_factor cvar.
*				This will throw error in case of invalid player.
*
*/
native ze_reset_human_speed(id);

/*
* Description:		Set this zombie speed to custom value.
*
* @param id			Client index.
* @param iSpeed		Speed to set this zombie to.
*
* @return			true  | If set successfully
*					false | If this player not connected
*
* @note				This native will set custom speed for this zombie
*					and will not use value defined in ze_zombie_speed cvar
*					This is limited by sv_maxspeed cvar.
*					This will throw error in case of invalid player.
*
*/
native ze_set_zombie_speed(id, iSpeed);

/*
* Description:	Reset zombie speed to default value used in ze_zombie_speed cvar.
*
* @param id		Client index.
*
* @return		true  | If reset successfully
*				false | If this player not connected
*
* @note			This will throw error in case of invalid player.
*
*/
native ze_reset_zombie_speed(id);

/*
* Description:	Get user knockback.
*
* @param id		Client index.
*
* @return		Knockback value | if client valid
*				-1				| If player not connected
*
* @note			This will throw error in case of invalid player.
*				This function return integer value.
*
*/
native ze_get_user_knockback(id);

/*
* Description:			Set user knockback.
*
* @param id				Client index.
* @param flKnockback	Knockback value as float.	
*
* @return				true	| If set successfully
*						false	| If this player not connected
*
*/
native ze_set_user_knockback(id, Float:flKnockback);

/*
* Description:	Reset user knockback to use value from CVAR.
*
* @param id		Client index.
*
* @return		true	| If reset successfully
*				false	| If this player not connected
*
*/
native ze_reset_user_knockback(id);

/*
* Description:			Set user gravity.
*
* @param id				Client index.
* @param iGravity		Gravity value.	
*
* @return				true	| If set successfully
*						false	| If this player not connected
*
*/
native ze_set_user_gravity(id, iGravity);

/*
* Description:	Reset user gravity to use value from CVAR.
*
* @param id		Client index.
*
* @return		true	| If reset successfully
*				false	| If this player not connected
*
*/
native ze_reset_user_gravity(id);

/*
* Description:	Remove zombie freeze time message.
*
* @return		true	| If removed successfully
*				false	| If message still not appeared (message not there)
*
*/
native ze_remove_zombie_freeze_msg();

/*
* Description:	Get player escape coins.
*
* @param id		Client index.
*
* @return		Player coins  | If this player in server
*				false		  | If this player not connected
*
* @note			This will throw error in case of invalid player.
*
*/
native ze_get_escape_coins(id);

/*
* Description:		Set player escape coins.
*
* @param id			Client index.
* @param iAmount	Client index.
*
* @return			true  | If set successfully
*					false | If this player not connected
*
* @note				This will throw error in case of invalid player.
*
*/
native ze_set_escape_coins(id, iAmount);

/*
* Description:		Get escape leader index.
*
* @return			Escape leader id
*
* @note				Make sure to use it when game already started.
*					If rank mode which is used the native will return rank 1 player.
*
*/
native ze_get_escape_leader_id();

/*
* Description:		Stop/Resume setting rendering from ze_effects_messages.sma plugin.
*
* @param id			Client index.
* @param bSet		True or false, True will stop the rendering that comes from ze_effects_messages.sma
*					false will continue setting rendering from ze_effects_messages.sma
*
* @return			true  | If set successfully
*					false | If this player not connected
*						
* @note				This native will not throw error if player not connected. It will just return false.
*					You before you set rendering for any player in any plugin you should first make: ze_stop_mod_rendering(id, true)
*					This will ensure that no rendering is setting from ze_effects_messages.sma plugin.
*					When you remove rendering, you should use: ze_stop_mod_rendering(id, false)
*
*/
native ze_stop_mod_rendering(id, bool:bSet);

/*
* Description:	Used to set/stop fire on zombie.
*
* @param id		Client index.
* @param bSet	Boolean value, true will set fire on zombie.
*				false will stop fire on zombie.
*
* @return		true  | If successfully set/stop fire on zombie.
*				false | If returned 1 in ze_fire_pre() forward.
*						Mean if fire action stopped by the pre forward.
*				-1	  | If this zombie not alive.
*
* @note			If zombie fired right now, you can use this to stop the fire
*				imediatly by using: ze_set_fire_grenade(id, false)
*				Same you can fire him at anytime.
*				Always check if user alive or not when using this native.
*				This will throw error in case of invalid player.
*				You can also set fire on alive humans.
*
*/
native ze_set_fire_grenade(id, bSet);

/*
* Description:	Tells you if this zombie burning now or not.
*
* @param id		Client index.
*
* @return		true  | If this zombie burning now.
*				false | If this zombie not burning.
*				-1	  | If this zombie not alive.
*
*/
native ze_zombie_in_fire(id);

/*
* Description:	Used to set/stop freeze on zombie.
*
* @param id		Client index.
* @param bSet	Boolean value, true will freeze zombie. false will unfreeze zombie.
*
* @return		true  | If successfully freeze/unfreeze zombie.
*				false | If returned 1 in ze_frost_pre() forward.
*						Mean if freeze action stopped by the pre forward.
*						Or if player already frozen
*				-1	  | If this zombie not alive.
*
* @note			If zombie frozen right now, you can use this to unfreeze him
*				imediatly by using: ze_set_frost_grenade(id, false)
*				Same you can freeze him at anytime.
*				Always check if user alive or not when using this native.
*				This will throw error in case of invalid player.
*				You can also freeze alive humans.
*
*/
native ze_set_frost_grenade(id, bSet);

/*
* Description:	Tells you if this zombie frozen now or not.
*
* @param id		Client index.
*
* @return		true  | If this zombie frozen now.
*				false | If this zombie unfrozen.
*				-1	  | If this zombie not alive.
*
*/
native ze_zombie_in_forst(id);

/*
* Description:		Register extra-item in the items-menu.
*
* @param szItemName[]	Item name.
* @param iCost			Item cost.
* @param iLimit			Item limit.
*
* @return				Item id in the menu, if successfully registered.
*						ZE_WRONG_ITEM | If item name was empty or item already registered.
*
* @note					ZE_WRONG_ITEM is defined as -1
*						Limit must be >= 0, 0 means unlimited.
*						Use this native in plugin_init() forward.
*
*/
native ze_register_item(const szItemName[], iCost, iLimit);

/*
* Description:	Open items menu for specific player.
*
* @param id		Client index.
*
* @return		true  | If successfully opened to the player.
*				false | If this player not connected.
*
*/
native ze_show_items_menu(id);

/*
* Description:			Force player to buy specific extra-item.
*
* @param id				Client index.
* @param iItemid		Item id, returned by ze_register_item() or ze_get_item_id().
* @param bIgnoreCost	true will ignore the cost, false will not ignore cost.
*
* @return				true  | If successfully bought item.
*						false | If this player not connected or itemid is invalid.
*
*/
native ze_force_buy_item(id, iItemid, bIgnoreCost);

/*
* Description:			Get item id by it's name.
*
* @param szItemName[]	Item name that used in ze_register_item().
*
* @return				Item index    | If item name is valid.
*						ZE_WRONG_ITEM | If this item name invalid.
*
* @note					ZE_WRONG_ITEM is defined as -1
*						Item name used in ze_register_item() native,
*						is called the real item name. 
*						this native deal with real name not name in ze_extraitems.ini
*
*/
native ze_get_item_id(const szItemName[]);

/*
* Description:			Get item cost (Integer) by it's id.
*
* @param iItemid		The item id from ze_register_item() or ze_get_item_id().
*
* @return				Item cost     | If item id is valid.
*						ZE_WRONG_ITEM | If item id is invalid.
*
* @note					ZE_WRONG_ITEM is defined as -1
*
*/
native ze_get_item_cost(iItemid);

/*
* Description:		Add extra-text to the item name.
*
* @param szText[]	Text to be added.
*
* @return			No return.
*
* @note				This native is used in ze_select_item_pre() forward.
*					Maximum length of the text is 32
*
*/
native ze_add_text_to_item(const szText[]);

/*
* Description:		Return item limit.
*
* @param iItemid	Item id.
*
* @return			Limit 		  | If this itemid is valid.
*					ZE_WRONG_ITEM | If this itemid is invalid.
*
* @note				ZE_WRONG_ITEM is defined as -1
*
*/
native ze_get_item_limit(iItemid);

/*
* Description:		Return item global limit.
*
* @param iItemid	Item id.
*
* @return			Global Limit  | If this itemid is valid.
*					ZE_WRONG_ITEM | If this itemid is invalid.
*
* @note				ZE_WRONG_ITEM is defined as -1
*
*/
native ze_get_item_global_limit(iItemid);

/*
* Description:		Check if this item id is valid or not.
*
* @param iItemid	Item id to check.
*
* @return			true  | If this itemid is valid.
*					false | If this itemid is invalid.
*
*/
native ze_is_valid_itemid(iItemid);

/*
* Description:		Return the item name by it's id.
*
* @param iItemid	Item id to check.
* @param szName[]	String to copy the string name to.
* @param iLen		The string szName[] max length.
*
* @return			true 		  | If item name copied successfully to szName[] string.
*					ZE_WRONG_ITEM | If this itemid is invalid.
*
*/
native ze_get_item_name(iItemid, const szName[], iLen);

/*
* Description:		Set this item for specific level.
*
* @param iItemid	Item id.
* @param iLevel		Level must player have to buy this item.
*
* @return			true 		  | If level set successfully.
*					false 		  | If level < 0 (Failed).
*					ZE_WRONG_ITEM | If this itemid is invalid.
*
* @note				Use this under ze_register_item() native in plugin_init() forward.
*					To use this native level plugin must be installed.
*
*/
native ze_set_item_level(iItemid, iLevel);

/*
* Description:		Get item level.
*
* @param iItemid	Item id.
*
* @return			Item level 	  | If this itemid is valid.
*					ZE_WRONG_ITEM | If this itemid is invalid.
*					
* @note				To use this native level plugin must be installed.
*
*/
native ze_get_item_level(iItemid);

/*
* Description:		Set this item for VIPs on specific flag.
*
* @param iItemid	Item id.
* @param szFlag		Flag to set item to: a, b, c ... etc.
*
* @return			true 		  | If set successfully for VIPs.
*					ZE_WRONG_ITEM | If this itemid is invalid.
*
* @note				Use this under ze_register_item() native in plugin_init() forward.
*					To use this native VIP plugin must be installed.
*					Make sure to use only one flag.
*
*/
native ze_set_item_vip(iItemid, szFlag[]);

/*
* Description:		See if this item for VIP or not, and on which flag.
*
* @param iItemid	Item id.
*
* @return			Flag this item set to (return integer).
*					ZE_WRONG_ITEM | If this itemid is invalid.
*					
* @note				To use this native VIP plugin must be installed.
*					This native works like ze_get_vip_flags() native.
*
*/
native ze_get_item_vip(iItemid);

/*
* Description:	Check if this zombie in madness or not.
*
* @param id		Client index.
*
* @return		true  | This zombie in madness.
*				false | If this zombie not in madness.
*				-1    | If this player not connected or he is human.
*
*/
native ze_zombie_in_madness(id);

/*
* Description:	Show weapon menu for player.
*
* @param id		Client index.
*
* @return		true  | If menu opened successfully.
*				false | If this player not connected.
*
*/
native ze_show_weapon_menu(id);

/*
* Description:	Check if auto buy enabled or not.
*
* @param id		Client index.
*
* @return		true  | If auto buy enabled.
*				false | If auto buy disabled.
*				-1 	  | If this player not connected.
*
*/
native ze_is_auto_buy_enabled(id);

/*
* Description:	This will disable auto buy for player.
*
* @param id		Client index.
*
* @return		true  | If disabled successfully.
*				false | If this player not connected.
*
*/
native ze_disable_auto_buy(id);

/*
* Description:	Enable and disable Ready&PreRelease sounds for any player.
*
* @param id		Client index.
* @param bSet	true will enable sounds, false will disable sounds.
*
* @return		true  | If successfully disabled/enabled.
*				false | If this player not connected.
*
*/
native ze_set_starting_sounds(id, bool:bSet);

/*
* Description:	Enable and disable ambiance sound for any player.
*
* @param id		Client index.
* @param bSet	true will enable sound, false will disable sound.
*
* @return		true  | If successfully disabled/enabled.
*				false | If this player not connected.
*
*/
native ze_set_ambiance_sounds(id, bool:bSet);

/*
* Description:	Check for any player if Ready&PreRelease sounds enabled or disabled.
*
* @param id		Client index.
*
* @return		true  | If sounds enabled.
*				false | If sounds disabled.
*				-1 	  | If this player not connected.
*
*/
native ze_is_starting_sounds_enabled(id);

/*
* Description:	Check for any player if ambiance sounds enabled or disabled.
*
* @param id		Client index.
*
* @return		true  | If sounds enabled.
*				false | If sounds disabled.
*				-1 	  | If this player not connected.
*
*/
native ze_is_ambiance_sounds_enabled(id);