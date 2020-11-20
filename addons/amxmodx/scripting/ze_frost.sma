#include <zombie_escape>

// Setting File
new const ZE_SETTING_RESOURCES[] = "zombie_escape.ini"

// Defines
#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64
#define SPRITE_MAX_LENGTH 64
#define TASK_FROST_REMOVE 200
#define ID_FROST_REMOVE (taskid - TASK_FROST_REMOVE)
#define TASK_FREEZE 2018

// Default Sounds
new const szFrostGrenadeExplodeSound[][] =
{ 
	"warcraft3/frostnova.wav"
}

new const szFrostGrenadePlayerSound[][] =
{ 
	"warcraft3/impalehit.wav"
}

new const szFrostGrenadeBreakSound[][] =
{
	"warcraft3/impalelaunch1.wav"
}

// Default Models
new g_v_szFrostGrenadeModel[MODEL_MAX_LENGTH] = "models/zombie_escape/v_grenade_frost.mdl"
new g_p_szFrostGrenadeModel[MODEL_MAX_LENGTH] = "models/zombie_escape/p_grenade_frost.mdl"
new g_w_szFrostGrenadeModel[MODEL_MAX_LENGTH] = "models/zombie_escape/w_grenade_frost.mdl"

// Default Sprites
new g_szGrenadeTrailSprite[SPRITE_MAX_LENGTH] = "sprites/laserbeam.spr"
new g_szGrenadeRingSprite[SPRITE_MAX_LENGTH] = "sprites/shockwave.spr"
new g_szGrenadeGlassSprite[SPRITE_MAX_LENGTH] = "models/glassgibs.mdl"

// Dynamic Arrays
new Array:g_szFrostGrenadeExplodeSound
new Array:g_szFrostGrenadePlayerSound
new Array:g_szFrostGrenadeBreakSound

// Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_FREEZE_PRE = 0,
	FW_USER_UNFROZEN
}

new g_iForwards[TOTAL_FORWARDS]
new g_iForwardReturn

// Variables
new bool:g_bIsFrozen[33],
	bool:g_bZombieReleased,
	g_iFrozenRenderingFx[33],
	Float:g_fFrozenRenderingColor[33][3],
	g_iFrozenRenderingRender[33],
	Float:g_fFrozenRenderingAmount[33],
	g_iMaxClients

// Sprites
new g_iTrailSpr,
	g_iExplodeSpr,
	g_iGlassSpr

// Cvar
new g_pCvarFrostDuration, 
	g_pCvarFrostHudIcon,
	g_pCvarFrozenDamage,
	g_pCvarFrostRadius,
	g_pCvarHitType

public plugin_init()
{
	register_plugin("[ZE] Frost Nade", ZE_VERSION, AUTHORS)
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "Fw_TraceAttack_Pre", 0)
	RegisterHookChain(RG_CBasePlayer_Killed, "Fw_PlayerKilled_Post", 1)
	RegisterHookChain(RG_CBasePlayer_PreThink, "Fw_PreThink_Post", 1)
	
	// Events
	register_event("HLTV", "New_Round", "a", "1=0", "2=0")
	
	// Hams
	RegisterHam(Ham_Think, "grenade", "Fw_ThinkGrenade_Post", 1)	
	
	// Fakemeta
	register_forward(FM_SetModel, "Fw_SetModel_Post", 1)
	
	// Forwards
	g_iForwards[FW_USER_FREEZE_PRE] = CreateMultiForward("ze_frost_pre", ET_CONTINUE, FP_CELL)
	g_iForwards[FW_USER_UNFROZEN] = CreateMultiForward("ze_frost_unfreeze", ET_IGNORE, FP_CELL)
	
	// Cvars
	g_pCvarFrostDuration = register_cvar("ze_frost_duration", "3")
	g_pCvarFrostHudIcon = register_cvar("ze_frost_hud_icon", "1")
	g_pCvarFrozenDamage = register_cvar("ze_freeze_damage", "0")
	g_pCvarFrostRadius = register_cvar("ze_freeze_radius", "240.0")
	g_pCvarHitType = register_cvar("ze_freeze_hit_type", "0")
	
	// Static Values
	g_iMaxClients = get_member_game(m_nMaxPlayers)
}

public plugin_natives()
{
	register_native("ze_zombie_in_forst", "native_ze_zombie_in_forst", 1)
	register_native("ze_set_frost_grenade", "native_ze_set_frost_grenade", 1)
}

public native_ze_zombie_in_forst(id)
{
	if (!is_user_alive(id))
	{
		return -1
	}
	
	return g_bIsFrozen[id]
}

public native_ze_set_frost_grenade(id, set)
{
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player (%d)", id)
		return -1;
	}
	
	// Unfreeze
	if (!set)
	{
		// Not frozen
		if (!g_bIsFrozen[id])
			return true
		
		// Remove freeze right away and stop the task
		RemoveFreeze(id+TASK_FROST_REMOVE)
		remove_task(id+TASK_FROST_REMOVE)
		return true
	}
	
	return set_freeze(id)
}

public plugin_precache()
{
	// Initialize arrays
	g_szFrostGrenadeExplodeSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szFrostGrenadePlayerSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szFrostGrenadeBreakSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "FROST GRENADE EXPLODE", g_szFrostGrenadeExplodeSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "FROST GRENADE PLAYER", g_szFrostGrenadePlayerSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "FROST GRENADE BREAK", g_szFrostGrenadeBreakSound)
	
	// If we couldn't load custom sounds from file, use and save default ones
	
	new iIndex
	
	if (ArraySize(g_szFrostGrenadeExplodeSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szFrostGrenadeExplodeSound; iIndex++)
			ArrayPushString(g_szFrostGrenadeExplodeSound, szFrostGrenadeExplodeSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "FROST GRENADE EXPLODE", g_szFrostGrenadeExplodeSound)
	}
	
	if (ArraySize(g_szFrostGrenadePlayerSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szFrostGrenadePlayerSound; iIndex++)
			ArrayPushString(g_szFrostGrenadePlayerSound, szFrostGrenadePlayerSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "FROST GRENADE PLAYER", g_szFrostGrenadePlayerSound)
	}
	
	if (ArraySize(g_szFrostGrenadeBreakSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szFrostGrenadeBreakSound; iIndex++)
			ArrayPushString(g_szFrostGrenadeBreakSound, szFrostGrenadeBreakSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "FROST GRENADE BREAK", g_szFrostGrenadeBreakSound)
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "V_GRENADE FROST", g_v_szFrostGrenadeModel, charsmax(g_v_szFrostGrenadeModel)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "V_GRENADE FROST", g_v_szFrostGrenadeModel)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "P_GRENADE FROST", g_p_szFrostGrenadeModel, charsmax(g_p_szFrostGrenadeModel)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "P_GRENADE FROST", g_p_szFrostGrenadeModel)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "W_GRENADE FROST", g_w_szFrostGrenadeModel, charsmax(g_w_szFrostGrenadeModel)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "W_GRENADE FROST", g_w_szFrostGrenadeModel)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "TRAIL", g_szGrenadeTrailSprite, charsmax(g_szGrenadeTrailSprite)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "TRAIL", g_szGrenadeTrailSprite)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "RING", g_szGrenadeRingSprite, charsmax(g_szGrenadeRingSprite)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "RING", g_szGrenadeRingSprite)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "GLASS", g_szGrenadeGlassSprite, charsmax(g_szGrenadeGlassSprite)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "GLASS", g_szGrenadeGlassSprite)
	
	// Precache sounds
	
	new szSound[SOUND_MAX_LENGTH]
	
	for (iIndex = 0; iIndex < ArraySize(g_szFrostGrenadeExplodeSound); iIndex++)
	{
		ArrayGetString(g_szFrostGrenadeExplodeSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
	for (iIndex = 0; iIndex < ArraySize(g_szFrostGrenadePlayerSound); iIndex++)
	{
		ArrayGetString(g_szFrostGrenadePlayerSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
	for (iIndex = 0; iIndex < ArraySize(g_szFrostGrenadeBreakSound); iIndex++)
	{
		ArrayGetString(g_szFrostGrenadeBreakSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
	
	// Precache models
	precache_model(g_v_szFrostGrenadeModel)
	precache_model(g_p_szFrostGrenadeModel)
	precache_model(g_w_szFrostGrenadeModel)
	
	// Precache sprites
	g_iTrailSpr = precache_model(g_szGrenadeTrailSprite)
	g_iExplodeSpr = precache_model(g_szGrenadeRingSprite)
	g_iGlassSpr = precache_model(g_szGrenadeGlassSprite)
}

public ze_user_humanized(id)
{
	// Set custom grenade model
	cs_set_player_view_model(id, CSW_FLASHBANG, g_v_szFrostGrenadeModel)
	cs_set_player_weap_model(id, CSW_FLASHBANG, g_p_szFrostGrenadeModel)
	cs_set_player_view_model(id, CSW_SMOKEGRENADE, g_v_szFrostGrenadeModel)
	cs_set_player_weap_model(id, CSW_SMOKEGRENADE, g_p_szFrostGrenadeModel)
	
	// If frozen, remove freeze after player is cured
	if (g_bIsFrozen[id])
	{
		// Update rendering values first
		ApplyFrozenRendering(id)
		
		// Remove freeze right away and stop the task
		RemoveFreeze(id+TASK_FROST_REMOVE)
		remove_task(id+TASK_FROST_REMOVE)
	}
}

public Fw_PreThink_Post(id)
{
	if (!ze_is_user_zombie(id))
		return

	if (g_bIsFrozen[id] && g_bZombieReleased)
	{
		// Stop and Freeze Zombie
		set_entvar(id, var_velocity, Float:{0.0,0.0,0.0})
		set_entvar(id, var_maxspeed, 1.0)
		ApplyFrozenRendering(id)
	}
}

public client_disconnected(id)
{
	g_bIsFrozen[id] = false
	remove_task(id+TASK_FROST_REMOVE)
}

public New_Round()
{
	remove_task(TASK_FREEZE)
	g_bZombieReleased = false
	
	// Set w_ models for grenades on ground
	new szModel[32], iEntity = -1;

	while((iEntity = rg_find_ent_by_class( iEntity, "armoury_entity")))
	{
		get_entvar(iEntity, var_model, szModel, charsmax(szModel))
		
		if (equali(szModel, "models/w_flashbang.mdl") || equali(szModel, "models/w_smokegrenade.mdl"))
		{
			engfunc(EngFunc_SetModel, iEntity, g_w_szFrostGrenadeModel)
		}
	}
}

public Fw_TraceAttack_Pre(iVictim, iAttacker)
{
	// Block damage while frozen
	if ((get_pcvar_num(g_pCvarFrozenDamage) == 0) && g_bIsFrozen[iVictim])
		return HC_SUPERCEDE
	
	return HC_CONTINUE
}

public Fw_PlayerKilled_Post(iVictim)
{
	// Frozen player being killed
	if (g_bIsFrozen[iVictim])
	{
		// Remove freeze right away and stop the task
		RemoveFreeze(iVictim+TASK_FROST_REMOVE)
		remove_task(iVictim+TASK_FROST_REMOVE)
	}
}

public ze_zombie_release()
{
	g_bZombieReleased = true
}

public Fw_SetModel_Post(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return FMRES_IGNORED
	
	// Get damage time of grenade
	static Float:dmgtime
	get_entvar(entity, var_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return FMRES_IGNORED
	
	// Grenade's owner is zombie?
	if (ze_is_user_zombie(get_entvar(entity, var_owner)))
		return FMRES_IGNORED

	// Flashbang or Smoke
	if ((model[9] == 'f' && model[10] == 'l') || (model[9] == 's' && model[10] == 'm'))
	{
		// Give it a glow
		Set_Rendering(entity, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 16);
		
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_iTrailSpr) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(0) // r
		write_byte(100) // g
		write_byte(200) // b
		write_byte(200) // brightness
		message_end()
		
		// Set grenade type on the thrown grenade entity
		set_entvar(entity, var_flTimeStepSound, 3333.0)
	}
	
	// Set w_ model
	if (equali(model, "models/w_flashbang.mdl") || equali(model, "models/w_smokegrenade.mdl"))
	{
		engfunc(EngFunc_SetModel, entity, g_w_szFrostGrenadeModel)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public Fw_ThinkGrenade_Post(entity)
{
	// Invalid entity
	if (!pev_valid(entity))
		return HAM_IGNORED
	
	// Get damage time of grenade
	static Float:dmgtime
	get_entvar(entity, var_dmgtime, dmgtime)
	
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return HAM_IGNORED
	
	// Check if it's one of our custom nades
	switch (get_entvar(entity, var_flTimeStepSound))
	{
		case 3333.0: // Frost Grenade
		{
			frost_explode(entity)
			return HAM_SUPERCEDE
		}
	}
	return HAM_IGNORED
}

// Frost Grenade Explosion
frost_explode(ent)
{
	// Get origin
	static Float:origin[3]
	get_entvar(ent, var_origin, origin)
	
	// Make the explosion
	create_blast3(origin)
	
	// Frost nade explode sound
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_szFrostGrenadeExplodeSound, random_num(0, ArraySize(g_szFrostGrenadeExplodeSound) - 1), sound, charsmax(sound))
	emit_sound(ent, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Collisions
	if (!get_pcvar_num(g_pCvarHitType))
	{
		new victim = -1
		
		while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, get_pcvar_float(g_pCvarFrostRadius))) != 0)
		{
			// Only effect alive zombies, If player not released yet don't freeze him
			if (!is_user_alive(victim) || !ze_is_user_zombie(victim) || !g_bZombieReleased)
				continue
			
			set_freeze(victim)
		}
	}
	else
	{
		new Float:flNadeOrigin[3], Float:flVictimOrigin[3], Float:flDistance, tr = create_tr2(), Float:flFraction
		get_entvar(ent, var_origin, flNadeOrigin)
		
		for(new iVictim = 1; iVictim <= g_iMaxClients; iVictim++)
		{
			if (!is_user_alive(iVictim) || !ze_is_user_zombie(iVictim) || !g_bZombieReleased)
				continue
			
			get_entvar(iVictim, var_origin, flVictimOrigin)
			
			// Get distance between nade and player
			flDistance = vector_distance(flNadeOrigin, flVictimOrigin)
			
			if(flDistance > get_pcvar_float(g_pCvarFrostRadius))
				continue
			
			flNadeOrigin[2] += 2.0;
			engfunc(EngFunc_TraceLine, flNadeOrigin, flVictimOrigin, DONT_IGNORE_MONSTERS, ent, tr);
			flNadeOrigin[2] -= 2.0;
			
			get_tr2(tr, TR_flFraction, flFraction);
			
			if(flFraction != 1.0 && get_tr2(tr, TR_pHit) != iVictim)
				continue;
			
			set_freeze(iVictim)
		}
		
		// Free the trace handler
		free_tr2(tr);
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, ent)
}

set_freeze(victim)
{
	// Already frozen
	if (g_bIsFrozen[victim])
		return false
	
	// Allow other plugins to decide whether player should be frozen or not
	ExecuteForward(g_iForwards[FW_USER_FREEZE_PRE], g_iForwardReturn, victim)
	
	if (g_iForwardReturn >= ZE_STOP)
	{
		// Get player's origin
		static origin2[3]
		get_user_origin(victim, origin2)
		
		// Broken glass sound
		static sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_szFrostGrenadeBreakSound, random_num(0, ArraySize(g_szFrostGrenadeBreakSound) - 1), sound, charsmax(sound))
		emit_sound(victim, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		// Glass shatter
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin2)
		write_byte(TE_BREAKMODEL) // TE id
		write_coord(origin2[0]) // x
		write_coord(origin2[1]) // y
		write_coord(origin2[2]+24) // z
		write_coord(16) // size x
		write_coord(16) // size y
		write_coord(16) // size z
		write_coord(random_num(-50, 50)) // velocity x
		write_coord(random_num(-50, 50)) // velocity y
		write_coord(25) // velocity z
		write_byte(10) // random velocity
		write_short(g_iGlassSpr) // model
		write_byte(10) // count
		write_byte(25) // life
		write_byte(0x01) // flags
		message_end()
		
		return false
	}
	
	// Freeze icon?
	if (get_pcvar_num(g_pCvarFrostHudIcon))
	{
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), _, victim)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_DROWN) // damage type - DMG_FREEZE
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
	}
	
	// Set frozen flag
	g_bIsFrozen[victim] = true
	
	// Freeze sound
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_szFrostGrenadePlayerSound, random_num(0, ArraySize(g_szFrostGrenadePlayerSound) - 1), sound, charsmax(sound))
	emit_sound(victim, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Add a blue tint to their screen
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, victim)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()
	
	// Update player entity rendering
	ApplyFrozenRendering(victim)
	
	// Set a task to remove the freeze
	set_task(get_pcvar_float(g_pCvarFrostDuration), "RemoveFreeze", victim+TASK_FROST_REMOVE)
	return true
}

ApplyFrozenRendering(id)
{
	// Get current rendering
	new rendering_fx = get_entvar(id, var_renderfx)
	new Float:rendering_color[3]
	get_entvar(id, var_rendercolor, rendering_color)
	new rendering_render = get_entvar(id, var_rendermode)
	new Float:rendering_amount
	get_entvar(id, var_renderamt, rendering_amount)
	
	// Already set, no worries...
	if (rendering_fx == kRenderFxGlowShell && rendering_color[0] == 0.0 && rendering_color[1] == 100.0
		&& rendering_color[2] == 200.0 && rendering_render == kRenderNormal && rendering_amount == 25.0)
		return
	
	// Save player's old rendering
	g_iFrozenRenderingFx[id] = get_entvar(id, var_renderfx)
	get_entvar(id, var_rendercolor, g_fFrozenRenderingColor[id])
	g_iFrozenRenderingRender[id] = get_entvar(id, var_rendermode)
	get_entvar(id, var_renderamt, g_fFrozenRenderingAmount[id])
	
	// Light blue glow while frozen
	Set_Rendering(id, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 25)
}

// Remove freeze task
public RemoveFreeze(taskid)
{
	// Remove frozen flag
	g_bIsFrozen[ID_FROST_REMOVE] = false
	
	// Restore rendering
	new iRed = floatround(g_fFrozenRenderingColor[ID_FROST_REMOVE][0]),
	iGreen = floatround(g_fFrozenRenderingColor[ID_FROST_REMOVE][1]),
	iBlue = floatround(g_fFrozenRenderingColor[ID_FROST_REMOVE][2])

	Set_Rendering(ID_FROST_REMOVE, g_iFrozenRenderingFx[ID_FROST_REMOVE], iRed, iGreen, iBlue, g_iFrozenRenderingRender[ID_FROST_REMOVE], floatround(g_fFrozenRenderingAmount[ID_FROST_REMOVE]))

	// Gradually remove screen's blue tint
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, ID_FROST_REMOVE)
	write_short((1<<12)) // duration
	write_short(0) // hold time
	write_short(0x0000) // fade type
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()
	
	// Broken glass sound
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_szFrostGrenadeBreakSound, random_num(0, ArraySize(g_szFrostGrenadeBreakSound) - 1), sound, charsmax(sound))
	emit_sound(ID_FROST_REMOVE, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Get player's origin
	static origin[3]
	get_user_origin(ID_FROST_REMOVE, origin)
	
	// Glass shatter
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_BREAKMODEL) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]+24) // z
	write_coord(16) // size x
	write_coord(16) // size y
	write_coord(16) // size z
	write_coord(random_num(-50, 50)) // velocity x
	write_coord(random_num(-50, 50)) // velocity y
	write_coord(25) // velocity z
	write_byte(10) // random velocity
	write_short(g_iGlassSpr) // model
	write_byte(10) // count
	write_byte(25) // life
	write_byte(BREAK_GLASS) // flags
	message_end()
	
	ExecuteForward(g_iForwards[FW_USER_UNFROZEN], g_iForwardReturn, ID_FROST_REMOVE)
}

// Frost Grenade: Freeze Blast
create_blast3(const Float:originF[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_iExplodeSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_iExplodeSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_iExplodeSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}