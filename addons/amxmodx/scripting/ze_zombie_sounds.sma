#include <zombie_escape>

// Setting File
new const ZE_SETTING_RESOURCES[] = "zombie_escape.ini"

// Default sounds
new const szZombiePainSound[][] = // Pain Sound Same As Fall Sound
{
	"zombie_escape/zombie_pain_1.wav",
	"zombie_escape/zombie_pain_2.wav"
}

new const szZombieMissSlashSound[][] = 
{
	"zombie_escape/zombie_miss_slash_1.wav",
	"zombie_escape/zombie_miss_slash_2.wav",
	"zombie_escape/zombie_miss_slash_3.wav"
}

new const szZombieMissWallSound[][] = 
{
	"zombie_escape/zombie_miss_wall_1.wav",
	"zombie_escape/zombie_miss_wall_2.wav",
	"zombie_escape/zombie_miss_wall_3.wav"
}

new const szZombieAttackSound[][] = 
{
	"zombie_escape/zombie_attack_1.wav",
	"zombie_escape/zombie_attack_2.wav",
	"zombie_escape/zombie_attack_3.wav"
}

new const szZombieDieSound[][] = 
{
	"zombie_escape/zombie_die.wav"
}

// Defines
#define SOUND_MAX_LENGTH 64

// Dynamic Arrays
new Array:g_szZombiePainSound, Array:g_szZombieMissSlashSound, Array:g_szZombieMissWallSound,
Array:g_szZombieAttackSound, Array:g_szZombieDieSound

public plugin_init()
{
	register_plugin("[ZE] Zombie Sounds", ZE_VERSION, AUTHORS)
	
	// Fakemeta
	register_forward(FM_EmitSound, "Fw_EmitSound_Post", 1)
}

public plugin_precache()
{
	// Initialize Arrays
	g_szZombiePainSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szZombieMissSlashSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szZombieMissWallSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szZombieAttackSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szZombieDieSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "ZOMBIE PAIN", g_szZombiePainSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "MISS SLASH", g_szZombieMissSlashSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "MISS WALL", g_szZombieMissWallSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "ATTACK", g_szZombieAttackSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "DIE", g_szZombieDieSound)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new iIndex
	
	if (ArraySize(g_szZombiePainSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szZombiePainSound; iIndex++)
			ArrayPushString(g_szZombiePainSound, szZombiePainSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "ZOMBIE PAIN", g_szZombiePainSound)
	}
	
	if (ArraySize(g_szZombieMissSlashSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szZombieMissSlashSound; iIndex++)
			ArrayPushString(g_szZombieMissSlashSound, szZombieMissSlashSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "MISS SLASH", g_szZombieMissSlashSound)
	}
	
	if (ArraySize(g_szZombieMissWallSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szZombieMissWallSound; iIndex++)
			ArrayPushString(g_szZombieMissWallSound, szZombieMissWallSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "MISS WALL", g_szZombieMissWallSound)
	}
	
	if (ArraySize(g_szZombieAttackSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szZombieAttackSound; iIndex++)
			ArrayPushString(g_szZombieAttackSound, szZombieAttackSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "ATTACK", g_szZombieAttackSound)
	}
	
	if (ArraySize(g_szZombieDieSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szZombieDieSound; iIndex++)
			ArrayPushString(g_szZombieDieSound, szZombieDieSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "DIE", g_szZombieDieSound)
	}
	
	// Precache Sounds
	new szSound[SOUND_MAX_LENGTH]
	
	for (iIndex = 0; iIndex < ArraySize(g_szZombiePainSound); iIndex++)
	{
		ArrayGetString(g_szZombiePainSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szZombieMissSlashSound); iIndex++)
	{
		ArrayGetString(g_szZombieMissSlashSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szZombieMissWallSound); iIndex++)
	{
		ArrayGetString(g_szZombieMissWallSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szZombieAttackSound); iIndex++)
	{
		ArrayGetString(g_szZombieAttackSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szZombieDieSound); iIndex++)
	{
		ArrayGetString(g_szZombieDieSound, iIndex, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
}

public Fw_EmitSound_Post(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Replace these next sounds for zombies only
	if (!is_user_connected(id) || !ze_is_user_zombie(id))
		return FMRES_IGNORED
	
	static szSound[SOUND_MAX_LENGTH]
	
	// Zombie being hit or Fall off - Pain Sound
	if ((sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't') ||
	(sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l'))
	{
		ArrayGetString(g_szZombiePainSound, random_num(0, ArraySize(g_szZombiePainSound) - 1), szSound, charsmax(szSound))
		emit_sound(id, channel, szSound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE
	}
	
	// Zombie Use Knife
	if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		// Miss Slash
		if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
		{
			ArrayGetString(g_szZombieMissSlashSound, random_num(0, ArraySize(g_szZombieMissSlashSound) - 1), szSound, charsmax(szSound))
			emit_sound(id, channel, szSound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE
		}
		
		
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
		{
			// Miss Wall
			if (sample[17] == 'w')
			{
				ArrayGetString(g_szZombieMissWallSound, random_num(0, ArraySize(g_szZombieMissWallSound) - 1), szSound, charsmax(szSound))
				emit_sound(id, channel, szSound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE	
			}
			else // Attack (Except Stab)
			{
				ArrayGetString(g_szZombieAttackSound, random_num(0, ArraySize(g_szZombieAttackSound) - 1), szSound, charsmax(szSound))
				emit_sound(id, channel, szSound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE
			}
		}
		
		// Attack (Stab)
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
		{
			ArrayGetString(g_szZombieAttackSound, random_num(0, ArraySize(g_szZombieAttackSound) - 1), szSound, charsmax(szSound))
			emit_sound(id, channel, szSound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE
		}
	}
	
	// Zombie Die (Die or Death Sounds)
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		ArrayGetString(g_szZombieDieSound, random_num(0, ArraySize(g_szZombieDieSound) - 1), szSound, charsmax(szSound))
		emit_sound(id, channel, szSound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE
	}	
	return FMRES_IGNORED
}