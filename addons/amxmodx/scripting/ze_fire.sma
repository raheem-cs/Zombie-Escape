#include <zombie_escape>

// Setting File
new const ZE_SETTING_RESOURCES[] = "zombie_escape.ini"

// Defines
#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64
#define SPRITE_MAX_LENGTH 64
#define TASK_BURN 100
#define ID_BURN (taskid - TASK_BURN)

// Default Values
new const szFireGrenadeExplodeSound[][] =
{ 
	"zombie_escape/grenade_explode.wav" 
}

new const szFireGrenadePlayerSound[][] =
{
	"zombie_escape/zombie_burn3.wav",
	"zombie_escape/zombie_burn4.wav",
	"zombie_escape/zombie_burn5.wav",
	"zombie_escape/zombie_burn6.wav",
	"zombie_escape/zombie_burn7.wav"
}

new g_v_szModelFireGrenade[MODEL_MAX_LENGTH] = "models/zombie_escape/v_grenade_fire.mdl"
new g_p_szModelFireGrenade[MODEL_MAX_LENGTH] = "models/zombie_escape/p_grenade_fire.mdl"
new g_w_szModelFireGrenade[MODEL_MAX_LENGTH] = "models/zombie_escape/w_grenade_fire.mdl"

new g_szGrenadeTrailSprite[SPRITE_MAX_LENGTH] = "sprites/laserbeam.spr"
new g_szGrenadeRingSprite[SPRITE_MAX_LENGTH] = "sprites/shockwave.spr"
new g_szGrenadeFireSprite[SPRITE_MAX_LENGTH] = "sprites/flame.spr"
new g_szGrenadeSmokeSprite[SPRITE_MAX_LENGTH] = "sprites/black_smoke3.spr"

// Dynamic Arrays
new Array:g_szFireGrenadeExplodeSound
new Array:g_szFireGrenadePlayerSound

// Forwards
new g_iFwUserBurn, 
	g_iForwardReturn

// Variables
new g_iBurningDuration[33],
	g_iMaxClients

// Sprites
new g_iTrailSpr, 
	g_iExplodeSpr,
	g_iFlameSpr,
	g_iSmokeSpr

//Cvars
new g_pCvarFireDuration, 
	g_pCvarFireDamage,
	g_pCvarFireHudIcon,
	g_pCvarFireExplosion,
	g_pCvarFireSlowDown,
	g_pCvarFireRadius,
	g_pCvarHitType

public plugin_init()
{
	register_plugin("[ZE] Fire Nade", ZE_VERSION, AUTHORS)
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_Killed, "Fw_PlayerKilled_Post", 1)
	
	// Events
	register_event("HLTV", "New_Round", "a", "1=0", "2=0")
	
	// Fakemeta
	register_forward(FM_SetModel, "Fw_SetModel_Post")
	
	// Hams
	RegisterHam(Ham_Think, "grenade", "Fw_ThinkGrenade_Post")
	
	// Forwards
	g_iFwUserBurn = CreateMultiForward("ze_fire_pre", ET_CONTINUE, FP_CELL)
	
	// Cvars
	g_pCvarFireDuration = register_cvar("ze_fire_duration", "6")
	g_pCvarFireDamage = register_cvar("ze_fire_damage", "5")
	g_pCvarFireHudIcon = register_cvar("ze_fire_hud_icon", "1")
	g_pCvarFireExplosion = register_cvar("ze_fire_explosion", "0")
	g_pCvarFireSlowDown = register_cvar("ze_fire_slowdown", "0.1")
	g_pCvarFireRadius = register_cvar("ze_fire_radius", "240.0")
	g_pCvarHitType = register_cvar("ze_fire_hit_type", "0")
	
	// Static Values
	g_iMaxClients = get_member_game(m_nMaxPlayers)
}

public plugin_precache()
{
	// Initialize arrays
	g_szFireGrenadeExplodeSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szFireGrenadePlayerSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "GRENADE FIRE EXPLODE", g_szFireGrenadeExplodeSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "GRENADE FIRE PLAYER", g_szFireGrenadePlayerSound)
	
	// If we couldn't load custom sounds from file, use and save default ones
	
	new iIndex
	
	if (ArraySize(g_szFireGrenadeExplodeSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szFireGrenadeExplodeSound; iIndex++)
			ArrayPushString(g_szFireGrenadeExplodeSound, szFireGrenadeExplodeSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "GRENADE FIRE EXPLODE", g_szFireGrenadeExplodeSound)
	}
	
	if (ArraySize(g_szFireGrenadePlayerSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szFireGrenadePlayerSound; iIndex++)
			ArrayPushString(g_szFireGrenadePlayerSound, szFireGrenadePlayerSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "GRENADE FIRE PLAYER", g_szFireGrenadePlayerSound)
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "V_GRENADE FIRE", g_v_szModelFireGrenade, charsmax(g_v_szModelFireGrenade)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "V_GRENADE FIRE", g_v_szModelFireGrenade)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "P_GRENADE FIRE", g_p_szModelFireGrenade, charsmax(g_p_szModelFireGrenade)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "P_GRENADE FIRE", g_p_szModelFireGrenade)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "W_GRENADE FIRE", g_w_szModelFireGrenade, charsmax(g_w_szModelFireGrenade)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Weapon Models", "W_GRENADE FIRE", g_w_szModelFireGrenade)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "TRAIL", g_szGrenadeTrailSprite, charsmax(g_szGrenadeTrailSprite)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "TRAIL", g_szGrenadeTrailSprite)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "RING", g_szGrenadeRingSprite, charsmax(g_szGrenadeRingSprite)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "RING", g_szGrenadeRingSprite)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "FIRE", g_szGrenadeFireSprite, charsmax(g_szGrenadeFireSprite)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "FIRE", g_szGrenadeFireSprite)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "SMOKE", g_szGrenadeSmokeSprite, charsmax(g_szGrenadeSmokeSprite)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Grenade Sprites", "SMOKE", g_szGrenadeSmokeSprite)
	
	// Precache sounds
	
	new szSound[SOUND_MAX_LENGTH]
	
	for (iIndex = 0; iIndex < ArraySize(g_szFireGrenadeExplodeSound); iIndex++)
	{
		ArrayGetString(g_szFireGrenadeExplodeSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
	for (iIndex = 0; iIndex < ArraySize(g_szFireGrenadePlayerSound); iIndex++)
	{
		ArrayGetString(g_szFireGrenadePlayerSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
	
	// Precache Models
	precache_model(g_v_szModelFireGrenade)
	precache_model(g_p_szModelFireGrenade)
	precache_model(g_w_szModelFireGrenade)
	
	// Precache Sprites
	g_iTrailSpr = precache_model(g_szGrenadeTrailSprite)
	g_iExplodeSpr = precache_model(g_szGrenadeRingSprite)
	g_iFlameSpr = precache_model(g_szGrenadeFireSprite)
	g_iSmokeSpr = precache_model(g_szGrenadeSmokeSprite)
}

public plugin_natives()
{
	register_native("ze_zombie_in_fire", "native_ze_zombie_in_fire", 1)
	register_native("ze_set_fire_grenade", "native_ze_set_fire_grenade", 1)
}

public native_ze_zombie_in_fire(id)
{
	if (!is_user_alive(id))
	{
		return -1;
	}
	
	return task_exists(id+TASK_BURN)
}

public native_ze_set_fire_grenade(id, set)
{
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player (%d)", id)
		return -1;
	}
	
	if (!set)
	{
		if (!task_exists(id+TASK_BURN))
			return true
		
		static origin[3]
		get_user_origin(id, origin)
		
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_iSmokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		remove_task(id+TASK_BURN)
		return true
	}
	
	return set_on_fire(id)
}

public ze_user_humanized(id)
{
	// Stop burning
	remove_task(id+TASK_BURN)
	g_iBurningDuration[id] = 0
	
	cs_set_player_view_model(id, CSW_HEGRENADE, g_v_szModelFireGrenade)
	cs_set_player_weap_model(id, CSW_HEGRENADE, g_p_szModelFireGrenade)
}

public New_Round()
{
	// Set w_ models for grenades on ground
	new szModel[32], iEntity = -1;

	while((iEntity = rg_find_ent_by_class( iEntity, "armoury_entity")))
	{
		get_entvar(iEntity, var_model, szModel, charsmax(szModel))
		
		if (equali(szModel, "models/w_hegrenade.mdl"))
		{
			engfunc(EngFunc_SetModel, iEntity, g_w_szModelFireGrenade)
		}
	}
}

public Fw_PlayerKilled_Post(iVictim, iAttacker)
{
	remove_task(iVictim+TASK_BURN)
	g_iBurningDuration[iVictim] = 0
}

public client_disconnected(id)
{
	remove_task(id+TASK_BURN)
	g_iBurningDuration[id] = 0
}

public Fw_SetModel_Post(entity, const model[])
{
	if (strlen(model) < 8)
		return FMRES_IGNORED
	
	static Float:dmgtime
	get_entvar(entity, var_dmgtime, dmgtime)
	
	if (dmgtime == 0.0)
		return FMRES_IGNORED
	
	if (ze_is_user_zombie(get_entvar(entity, var_owner)))
		return FMRES_IGNORED
	
	if (model[9] == 'h' && model[10] == 'e')
	{
		Set_Rendering(entity, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 16)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_iTrailSpr) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(200) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(200) // brightness
		message_end()
		
		set_entvar(entity, var_flTimeStepSound, 2222.0)
	}
	
	// Set w_ model
	if (equali(model, "models/w_hegrenade.mdl"))
	{
		engfunc(EngFunc_SetModel, entity, g_w_szModelFireGrenade)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public Fw_ThinkGrenade_Post(entity)
{
	if (!pev_valid(entity)) return HAM_IGNORED
	
	static Float:dmgtime
	get_entvar(entity, var_dmgtime, dmgtime)
	
	if (dmgtime > get_gametime())
		return HAM_IGNORED
	
	if (get_entvar(entity, var_flTimeStepSound) != 2222.0)
		return HAM_IGNORED
	
	fire_explode(entity)
	
	if (get_pcvar_num(g_pCvarFireExplosion) == 1)
	{
		set_entvar(entity, var_flTimeStepSound, 0.0)
		return HAM_IGNORED
	}
	
	engfunc(EngFunc_RemoveEntity, entity)
	return HAM_SUPERCEDE
}

fire_explode(ent)
{
	static Float:origin[3]
	get_entvar(ent, var_origin, origin)
	
	if (get_pcvar_num(g_pCvarFireExplosion) == 0)
	{
		create_blast2(origin)
		
		// Fire nade explode sound
		static szSound[SOUND_MAX_LENGTH]
		ArrayGetString(g_szFireGrenadeExplodeSound, random_num(0, ArraySize(g_szFireGrenadeExplodeSound) - 1), szSound, charsmax(szSound))
		emit_sound(ent, CHAN_WEAPON, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	if (!get_pcvar_num(g_pCvarHitType))
	{
		new victim = -1

		while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, get_pcvar_float(g_pCvarFireRadius))) != 0)
		{
			if (!is_user_alive(victim) || !ze_is_user_zombie(victim))
				continue
			
			set_on_fire(victim)
		}
	}
	else
	{
		new Float:flNadeOrigin[3], Float:flVictimOrigin[3], Float:flDistance, tr = create_tr2(), Float:flFraction
		get_entvar(ent, var_origin, flNadeOrigin)
		
		for(new iVictim = 1; iVictim <= g_iMaxClients; iVictim++)
		{
			if (!is_user_alive(iVictim) || !ze_is_user_zombie(iVictim))
				continue
			
			get_entvar(iVictim, var_origin, flVictimOrigin)
			
			// Get distance between nade and player
			flDistance = vector_distance(flNadeOrigin, flVictimOrigin)
			
			if(flDistance > get_pcvar_float(g_pCvarFireRadius))
				continue
			
			flNadeOrigin[2] += 2.0;
			engfunc(EngFunc_TraceLine, flNadeOrigin, flVictimOrigin, DONT_IGNORE_MONSTERS, ent, tr);
			flNadeOrigin[2] -= 2.0;
			
			get_tr2(tr, TR_flFraction, flFraction);
			
			if(flFraction != 1.0 && get_tr2(tr, TR_pHit) != iVictim)
				continue;
			
			set_on_fire(iVictim)
		}
		
		// Free the trace handler
		free_tr2(tr);
	}
}

set_on_fire(victim)
{
	ExecuteForward(g_iFwUserBurn, g_iForwardReturn, victim)
	
	if (g_iForwardReturn >= ZE_STOP)
		return false;
	
	if (get_pcvar_num(g_pCvarFireHudIcon))
	{
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), _, victim)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_BURN) // damage type
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
	}
	
	g_iBurningDuration[victim] += get_pcvar_num(g_pCvarFireDuration) * 5
	
	remove_task(victim+TASK_BURN)
	set_task(0.2, "burning_flame", victim+TASK_BURN, _, _, "b")
	return true
}

// Burning Flames
public burning_flame(taskid)
{
	static origin[3]
	get_user_origin(ID_BURN, origin)
	new flags = get_entvar(ID_BURN, var_flags)
	
	if ((flags & FL_INWATER) || g_iBurningDuration[ID_BURN] < 1)
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_iSmokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// Task not needed anymore
		remove_task(taskid)
		return;
	}
	
	// Randomly play burning zombie scream sounds
	if (random_num(1, 20) == 1)
	{
		static szSound[SOUND_MAX_LENGTH]
		ArrayGetString(g_szFireGrenadePlayerSound, random_num(0, ArraySize(g_szFireGrenadePlayerSound) - 1), szSound, charsmax(szSound))
		emit_sound(ID_BURN, CHAN_VOICE, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	// Fire slow down
	if ((flags & FL_ONGROUND) && get_pcvar_float(g_pCvarFireSlowDown) > 0.0)
	{
		static Float:fVelocity[3]
		get_entvar(ID_BURN, var_velocity, fVelocity)
		VecMulScalar(fVelocity, get_pcvar_float(g_pCvarFireSlowDown), fVelocity)
		set_entvar(ID_BURN, var_velocity, fVelocity)
	}
	
	new health = get_user_health(ID_BURN)
	
	if (health - floatround(get_pcvar_float(g_pCvarFireDamage), floatround_ceil) > 0)
		set_entvar(ID_BURN, var_health, float(health - floatround(get_pcvar_float(g_pCvarFireDamage), floatround_ceil)))
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_iFlameSpr) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()
	
	g_iBurningDuration[ID_BURN] --
}

// Fire Grenade: Fire Blast
create_blast2(const Float:origin[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+385.0) // z axis
	write_short(g_iExplodeSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(100) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+470.0) // z axis
	write_short(g_iExplodeSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(50) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+555.0) // z axis
	write_short(g_iExplodeSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}