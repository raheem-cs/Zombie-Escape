#include <zombie_escape>

// Setting File
new const ZE_SETTING_RESOURCES[] = "zombie_escape.ini"

// Default Values
new const szZombieMadnessSound[][] =
{
	"zombie_escape/zombie_madness1.wav"
}

// Sound Max Length
#define SOUND_MAX_LENGTH 64

// Dynamic Array to Store our sound in
new Array:g_szZombie_Madness_Sound

// Task IDs
#define TASK_MADNESS 100
#define TASK_AURA 200
#define ID_MADNESS (taskid - TASK_MADNESS)
#define ID_AURA (taskid - TASK_AURA)

// Variables
new g_iItemID, 
	bool:g_bZombieInMadness[33]

// Cvars
new g_pCvarMadnessTime, 
	g_pCvarMadnessAuraColors[3]
	
// Colors
enum
{
	Red = 0,
	Green,
	Blue
}

public plugin_init()
{
	register_plugin("[ZE] Items: Zombie Madness", ZE_VERSION, AUTHORS)
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "Fw_TraceAttack_Pre", 0)
	RegisterHookChain(RG_CBasePlayer_Spawn, "Fw_PlayerSpawn_Post", 1)
	RegisterHookChain(RG_CBasePlayer_Killed, "Fw_PlayerKilled_Post", 1)
	
	// Register our item
	g_iItemID = ze_register_item("Zombie Madness", 50, 0)
	
	// Cvars
	g_pCvarMadnessTime = register_cvar("ze_madness_time", "5.0")
	g_pCvarMadnessAuraColors[Red] = register_cvar("ze_madness_color_red", "255")
	g_pCvarMadnessAuraColors[Green] = register_cvar("ze_madness_color_green", "0")
	g_pCvarMadnessAuraColors[Blue] = register_cvar("ze_madness_color_blue", "0")
}

public plugin_precache()
{
	// Initialize arrays
	g_szZombie_Madness_Sound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "ZOMBIE MADNESS", g_szZombie_Madness_Sound)
	
	// If we couldn't load custom sounds from file, use and save default ones
	
	new iIndex
	
	if (ArraySize(g_szZombie_Madness_Sound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szZombieMadnessSound; iIndex++)
			ArrayPushString(g_szZombie_Madness_Sound, szZombieMadnessSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "ZOMBIE MADNESS", g_szZombie_Madness_Sound)
	}
	
	// Precache sounds
	new szSound[SOUND_MAX_LENGTH]
	for (iIndex = 0; iIndex < ArraySize(g_szZombie_Madness_Sound); iIndex++)
	{
		ArrayGetString(g_szZombie_Madness_Sound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
}

public plugin_natives()
{
	register_native("ze_zombie_in_madness", "native_ze_zombie_in_madness", 1)
}

public ze_select_item_pre(id, itemid)
{
	// Return Available and we will block it in Post, So it dosen't affect other plugins
	if (itemid != g_iItemID)
		return ZE_ITEM_AVAILABLE
	
	// Zombie madness only available to zombies
	if (!ze_is_user_zombie(id))
		return ZE_ITEM_DONT_SHOW
	
	// Player already has madness
	if (g_bZombieInMadness[id])
		return ZE_ITEM_UNAVAILABLE
	
	return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(id, itemid)
{
	// This is not our item, Block it here
	if (itemid != g_iItemID)
		return
	
	// Player In Madness
	g_bZombieInMadness[id] = true
	
	// Madness aura
	set_task(0.1, "Madness_Aura", id+TASK_AURA, _, _, "b")
	
	// Madness sound
	new szSound[SOUND_MAX_LENGTH]
	ArrayGetString(g_szZombie_Madness_Sound, random_num(0, ArraySize(g_szZombie_Madness_Sound) - 1), szSound, charsmax(szSound))
	emit_sound(id, CHAN_VOICE, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Set task to remove it
	set_task(get_pcvar_float(g_pCvarMadnessTime), "Remove_Zombie_Madness", id+TASK_MADNESS)
}

// Player Spawn
public Fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !get_member(id, m_iTeam))
		return
	
	// Remove zombie madness from a previous round
	remove_task(id+TASK_MADNESS)
	remove_task(id+TASK_AURA)
	g_bZombieInMadness[id] = false
}

// Trace Attack
public Fw_TraceAttack_Pre(iVictim, iAttacker)
{
	// Prevent attacks when victim has zombie madness
	if (g_bZombieInMadness[iVictim])
		return HC_SUPERCEDE
	
	return HC_CONTINUE
}

public ze_frost_pre(id)
{
	// Prevent frost when victim has zombie madness
	if (g_bZombieInMadness[id])
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public ze_fire_pre(id)
{
	// Prevent burning when victim has zombie madness
	if (g_bZombieInMadness[id])
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public ze_user_humanized(id)
{
	// Remove zombie madness task if player somehow became human while he still in madness
	remove_task(id+TASK_MADNESS)
	remove_task(id+TASK_AURA)
	g_bZombieInMadness[id] = false
}

// Player Killed
public Fw_PlayerKilled_Post(iVictim)
{
	// Remove zombie madness task
	remove_task(iVictim+TASK_MADNESS)
	remove_task(iVictim+TASK_AURA)
	g_bZombieInMadness[iVictim] = false
}

// Remove Madness
public Remove_Zombie_Madness(taskid)
{
	// Remove aura
	remove_task(ID_MADNESS+TASK_AURA)

	// Remove zombie madness
	g_bZombieInMadness[ID_MADNESS] = false
}

public client_disconnected(id)
{
	// Remove tasks on disconnect
	remove_task(id+TASK_MADNESS)
	remove_task(id+TASK_AURA)
	g_bZombieInMadness[id] = false
}

// Madness aura task
public Madness_Aura(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(get_pcvar_num(g_pCvarMadnessAuraColors[Red])) // r
	write_byte(get_pcvar_num(g_pCvarMadnessAuraColors[Green])) // g
	write_byte(get_pcvar_num(g_pCvarMadnessAuraColors[Blue])) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

public native_ze_zombie_in_madness(id)
{
	if (!is_user_alive(id))
	{
		// Throw Error and return -1 if player isn't alive
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player (%d)", id)
		return -1;
	}
	
	if (!is_user_alive(id))
	{
		// Throw Error and return -1 if player isn't alive
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player, not Zombie (%d)", id)
		return -1;
	}
	
	return g_bZombieInMadness[id]
}