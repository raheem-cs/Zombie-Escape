/**
 * Sets a custom view model for a specific weapon for a player.
 *
 * Note: if you pass an empty string, model will be hidden.
 *
 * @param id					Player index.
 * @param weaponid				Weapon to replace model for. (in CSW_ format)
 * @param view_model			Full path to model. (e.g. "models/v_knife_custom.mdl")
 */
native cs_set_player_view_model(id, weaponid, const view_model[])

/**
 * Restores a custom view model for a specific weapon for a player.
 *
 * @param id					Player index.
 * @param weaponid				Weapon to restore model for. (in CSW_ format)
 */
native cs_reset_player_view_model(id, weaponid)

/**
 * Sets a custom weapon model for a specific weapon for a player.
 *
 * Note: if you pass an empty string, model will be hidden.
 *
 * @param id					Player index.
 * @param weaponid				Weapon to replace model for. (in CSW_ format)
 * @param view_model			Full path to model. (e.g. "models/p_knife_custom.mdl")
 */
native cs_set_player_weap_model(id, weaponid, const weapon_model[])

/**
 * Restores a custom weapon model for a specific weapon for a player.
 *
 * @param id					Player index.
 * @param weaponid				Weapon to restore model for. (in CSW_ format)
 */
native cs_reset_player_weap_model(id, weaponid)