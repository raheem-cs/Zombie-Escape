#include <zombie_escape>

// Setting File
new const ZE_SETTING_RESOURCES[] = "zombie_escape.ini"

// Defines
#define MODEL_MAX_LENGTH 64
#define PLAYERMODEL_MAX_LENGTH 32
#define SOUND_MAX_LENGTH 64
#define TASK_AMBIENCESOUND 2020
#define TASK_REAMBIENCESOUND 5050

// Default Sounds
new const szReadySound[][] = 
{
	"zombie_escape/ze_ready.mp3"
}

new const szInfectSound[][] = 
{
	"zombie_escape/zombie_infect_1.wav",
	"zombie_escape/zombie_infect_2.wav"
}

new const szComingSound[][] = 
{
	"zombie_escape/zombie_coming_1.wav",
	"zombie_escape/zombie_coming_2.wav",
	"zombie_escape/zombie_coming_3.wav"
}

new const szPreReleaseSound[][] = 
{
	"zombie_escape/ze_pre_release.wav"
}

new const szAmbianceSound[][] = 
{
	"zombie_escape/ze_ambiance1.mp3",
	"zombie_escape/ze_ambiance2.mp3",
	"zombie_escape/ze_ambiance3.mp3"
}

new const szEscapeSuccessSound[][] = 
{
	"zombie_escape/escape_success.wav"
}

new const szEscapeFailSound[][] = 
{
	"zombie_escape/escape_fail.wav"
}

// Default Sounds Duration (Hardcoded Values)
new g_iReadySoundDuration = 19
new g_iPreReleaseSoundDuration = 19
new g_iAmbianceSoundDuration = 160 //(Avarage for the 2 ambiances)

// Default Models
new const szHostZombieModel[][] =
{
	"host_zombie"
}

new const szOriginZombieModel[][] =
{
	"origin_zombie"
}

new const szHumanModels[][] = // These models not prechaced as it's default in cs
{
	"arctic",
	"gign",
	"gsg9",
	"guerilla",
	"leet",
	"sas",
	"terror",
	"urban"
}

new const v_szZombieKnifeModel[][] =
{
	"models/zombie_escape/v_knife_zombie.mdl"
}

new const v_szHumanKnifeModel[][] = 
{
	"models/v_knife.mdl"
}

new const p_szHumanKnifeModel[][] = 
{
	"models/p_knife.mdl"
}

// Dynamic Arrays: Sounds
new Array:g_szReadySound, Array:g_szInfectSound, Array:g_szComingSound, Array:g_szPreReleaseSound,
Array:g_szAmbianceSound, Array:g_szEscapeSuccessSound, Array:g_szEscapeFailSound

// Dynamic Arrays: Models
new Array:g_szHostZombieModel, Array:g_szOriginZombieModel, Array:g_v_szZombieKnifeModel,
Array:g_v_szHumanKnifeModel, Array:g_p_szHumanKnifeModel

// Variables
new g_iMaxPlayers, g_pCvarReleaseTime

public plugin_init()
{
	register_plugin("[ZE] Models & Sounds", ZE_VERSION, AUTHORS)
	
	// Max Players
	g_iMaxPlayers = get_member_game(m_nMaxPlayers)
	
	// Pointers
	g_pCvarReleaseTime = get_cvar_pointer("ze_release_time")
}

public plugin_precache()
{	
	// Initialize Arrays: Sounds
	g_szReadySound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szInfectSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szComingSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szPreReleaseSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szAmbianceSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szEscapeSuccessSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_szEscapeFailSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load From External File: Sounds
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Ready Sound", g_szReadySound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Infect Sound", g_szInfectSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Coming Sound", g_szComingSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Pre-Release Sound", g_szPreReleaseSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Round Ambiance", g_szAmbianceSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Escape Success", g_szEscapeSuccessSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Escape Fail", g_szEscapeFailSound)
	
	// Load our Default Values: Sounds
	new iIndex
	
	if(ArraySize(g_szReadySound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szReadySound; iIndex++)
			ArrayPushString(g_szReadySound, szReadySound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Ready Sound", g_szReadySound)
	}
	
	if(ArraySize(g_szInfectSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szInfectSound; iIndex++)
			ArrayPushString(g_szInfectSound, szInfectSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Infect Sound", g_szInfectSound)
	}
	
	if(ArraySize(g_szComingSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szComingSound; iIndex++)
			ArrayPushString(g_szComingSound, szComingSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Coming Sound", g_szComingSound)
	}
	
	if(ArraySize(g_szPreReleaseSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szPreReleaseSound; iIndex++)
			ArrayPushString(g_szPreReleaseSound, szPreReleaseSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Pre-Release Sound", g_szPreReleaseSound)
	}
	
	if(ArraySize(g_szAmbianceSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szAmbianceSound; iIndex++)
			ArrayPushString(g_szAmbianceSound, szAmbianceSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Round Ambiance", g_szAmbianceSound)
	}
	
	if(ArraySize(g_szEscapeSuccessSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szEscapeSuccessSound; iIndex++)
			ArrayPushString(g_szEscapeSuccessSound, szEscapeSuccessSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Escape Success", g_szEscapeSuccessSound)
	}
	
	if(ArraySize(g_szEscapeFailSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szEscapeFailSound; iIndex++)
			ArrayPushString(g_szEscapeFailSound, szEscapeFailSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Escape Fail", g_szEscapeFailSound)
	}
	
	// Precache: Sounds
	new szSound[SOUND_MAX_LENGTH]
	
	for (iIndex = 0; iIndex < ArraySize(g_szReadySound); iIndex++)
	{
		ArrayGetString(g_szReadySound, iIndex, szSound, charsmax(szSound))
		
		if (equal(szSound[strlen(szSound)-4], ".mp3"))
		{
			format(szSound, charsmax(szSound), "sound/%s", szSound)
			precache_generic(szSound)
		}
		else
		{
			precache_sound(szSound)
		}
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szInfectSound); iIndex++)
	{
		ArrayGetString(g_szInfectSound, iIndex, szSound, charsmax(szSound))
		
		if (equal(szSound[strlen(szSound)-4], ".mp3"))
		{
			format(szSound, charsmax(szSound), "sound/%s", szSound)
			precache_generic(szSound)
		}
		else
		{
			precache_sound(szSound)
		}
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szComingSound); iIndex++)
	{
		ArrayGetString(g_szComingSound, iIndex, szSound, charsmax(szSound))
		
		if (equal(szSound[strlen(szSound)-4], ".mp3"))
		{
			format(szSound, charsmax(szSound), "sound/%s", szSound)
			precache_generic(szSound)
		}
		else
		{
			precache_sound(szSound)
		}
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szPreReleaseSound); iIndex++)
	{
		ArrayGetString(g_szPreReleaseSound, iIndex, szSound, charsmax(szSound))
		
		if (equal(szSound[strlen(szSound)-4], ".mp3"))
		{
			format(szSound, charsmax(szSound), "sound/%s", szSound)
			precache_generic(szSound)
		}
		else
		{
			precache_sound(szSound)
		}
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szAmbianceSound); iIndex++)
	{
		ArrayGetString(g_szAmbianceSound, iIndex, szSound, charsmax(szSound))
		
		if (equal(szSound[strlen(szSound)-4], ".mp3"))
		{
			format(szSound, charsmax(szSound), "sound/%s", szSound)
			precache_generic(szSound)
		}
		else
		{
			precache_sound(szSound)
		}
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szEscapeSuccessSound); iIndex++)
	{
		ArrayGetString(g_szEscapeSuccessSound, iIndex, szSound, charsmax(szSound))
		
		if (equal(szSound[strlen(szSound)-4], ".mp3"))
		{
			format(szSound, charsmax(szSound), "sound/%s", szSound)
			precache_generic(szSound)
		}
		else
		{
			precache_sound(szSound)
		}
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szEscapeFailSound); iIndex++)
	{
		ArrayGetString(g_szEscapeFailSound, iIndex, szSound, charsmax(szSound))
		
		if (equal(szSound[strlen(szSound)-4], ".mp3"))
		{
			format(szSound, charsmax(szSound), "sound/%s", szSound)
			precache_generic(szSound)
		}
		else
		{
			precache_sound(szSound)
		}
	}
	
	// Sound Durations
	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Ready Sound", g_iReadySoundDuration))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Ready Sound", g_iReadySoundDuration)
	
	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Pre-Release Sound", g_iPreReleaseSoundDuration))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Pre-Release Sound", g_iPreReleaseSoundDuration)
	
	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Round Ambiance", g_iAmbianceSoundDuration))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Round Ambiance", g_iAmbianceSoundDuration)
	
	// Initialize Arrays: Models
	g_szHostZombieModel = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_szOriginZombieModel = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_v_szZombieKnifeModel = ArrayCreate(MODEL_MAX_LENGTH, 1)
	g_v_szHumanKnifeModel = ArrayCreate(MODEL_MAX_LENGTH, 1)
	g_p_szHumanKnifeModel = ArrayCreate(MODEL_MAX_LENGTH, 1)
	
	// Load From External File: Models
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "HOST ZOMBIE", g_szHostZombieModel)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "ORIGIN ZOMBIE", g_szOriginZombieModel)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "V_KNIFE ZOMBIE", g_v_szZombieKnifeModel)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "V_KNIFE HUMAN", g_v_szHumanKnifeModel)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "P_KNIFE HUMAN", g_p_szHumanKnifeModel)
	
	// Load our Default Values: Models
	if(ArraySize(g_szHostZombieModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szHostZombieModel; iIndex++)
			ArrayPushString(g_szHostZombieModel, szHostZombieModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "HOST ZOMBIE", g_szHostZombieModel)
	}
	
	if(ArraySize(g_szOriginZombieModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szOriginZombieModel; iIndex++)
			ArrayPushString(g_szOriginZombieModel, szOriginZombieModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "ORIGIN ZOMBIE", g_szOriginZombieModel)
	}
	
	if(ArraySize(g_v_szZombieKnifeModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof v_szZombieKnifeModel; iIndex++)
			ArrayPushString(g_v_szZombieKnifeModel, v_szZombieKnifeModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "V_KNIFE ZOMBIE", g_v_szZombieKnifeModel)
	}
	
	if(ArraySize(g_v_szHumanKnifeModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof v_szHumanKnifeModel; iIndex++)
			ArrayPushString(g_v_szHumanKnifeModel, v_szHumanKnifeModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "V_KNIFE HUMAN", g_v_szHumanKnifeModel)
	}
	
	if(ArraySize(g_p_szHumanKnifeModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof p_szHumanKnifeModel; iIndex++)
			ArrayPushString(g_p_szHumanKnifeModel, p_szHumanKnifeModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "P_KNIFE HUMAN", g_p_szHumanKnifeModel)
	}
	
	// Precache: Models
	new szPlayerModel[PLAYERMODEL_MAX_LENGTH], szModel[MODEL_MAX_LENGTH], szModelPath[128]
	
	for (iIndex = 0; iIndex < ArraySize(g_szHostZombieModel); iIndex++)
	{
		ArrayGetString(g_szHostZombieModel, iIndex, szPlayerModel, charsmax(szPlayerModel))
		formatex(szModelPath, charsmax(szModelPath), "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel)
		precache_model(szModelPath)
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_szOriginZombieModel); iIndex++)
	{
		ArrayGetString(g_szOriginZombieModel, iIndex, szPlayerModel, charsmax(szPlayerModel))
		formatex(szModelPath, charsmax(szModelPath), "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel)
		precache_model(szModelPath)
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_v_szZombieKnifeModel); iIndex++)
	{
		ArrayGetString(g_v_szZombieKnifeModel, iIndex, szModel, charsmax(szModel))
		precache_model(szModel)
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_v_szHumanKnifeModel); iIndex++)
	{
		ArrayGetString(g_v_szHumanKnifeModel, iIndex, szModel, charsmax(szModel))
		precache_model(szModel)
	}
	
	for (iIndex = 0; iIndex < ArraySize(g_p_szHumanKnifeModel); iIndex++)
	{
		ArrayGetString(g_p_szHumanKnifeModel, iIndex, szModel, charsmax(szModel))
		precache_model(szModel)
	}
}

// Play Ready sound only if game started
public ze_game_started()
{
	// Remove Tasks (Again as somehow may it not removed at the roundend)
	remove_task(TASK_AMBIENCESOUND)
	remove_task(TASK_REAMBIENCESOUND)
	
	// Stop All Sounds
	StopSound()
	
	// Play Ready Sound For All Players
	new szSound[SOUND_MAX_LENGTH]
	ArrayGetString(g_szReadySound, random_num(0, ArraySize(g_szReadySound) - 1), szSound, charsmax(szSound))
	
	for(new id = 1; id <= g_iMaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue

		PlaySound(id, szSound)
	}
}

public ze_user_infected(iVictim, iInfector)
{	
	// Emit Sound For infection (Sound Source is The zombie Body)
	new szSound[SOUND_MAX_LENGTH]
	ArrayGetString(g_szInfectSound, random_num(0, ArraySize(g_szInfectSound) - 1), szSound, charsmax(szSound))
	emit_sound(iVictim, CHAN_BODY, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Play Zombie Appear Sound for all Players
	ArrayGetString(g_szComingSound, random_num(0, ArraySize(g_szComingSound) - 1), szSound, charsmax(szSound))
	PlaySound(0, szSound)
	
	// Set Zombie Models
	new szPlayerModel[PLAYERMODEL_MAX_LENGTH], szModel[MODEL_MAX_LENGTH]
	
	// Random Model Set
	switch(random_num(0, 130))
	{
		case 0..30:
		{
			ArrayGetString(g_szHostZombieModel, random_num(0, ArraySize(g_szHostZombieModel) - 1), szPlayerModel, charsmax(szPlayerModel))
			rg_set_user_model(iVictim, szPlayerModel) // This native Faster 100000000000 times than one in fun module
		}
		case 31..70:
		{
			ArrayGetString(g_szOriginZombieModel, random_num(0, ArraySize(g_szOriginZombieModel) - 1), szPlayerModel, charsmax(szPlayerModel))
			rg_set_user_model(iVictim, szPlayerModel)
		}
		case 71..100:
		{
			ArrayGetString(g_szHostZombieModel, random_num(0, ArraySize(g_szHostZombieModel) - 1), szPlayerModel, charsmax(szPlayerModel))
			rg_set_user_model(iVictim, szPlayerModel)
		}
		case 101..130:
		{
			ArrayGetString(g_szOriginZombieModel, random_num(0, ArraySize(g_szOriginZombieModel) - 1), szPlayerModel, charsmax(szPlayerModel))
			rg_set_user_model(iVictim, szPlayerModel)
		}
	}
	
	ArrayGetString(g_v_szZombieKnifeModel, random_num(0, ArraySize(g_v_szZombieKnifeModel) - 1), szModel, charsmax(szModel))
	cs_set_player_view_model(iVictim, CSW_KNIFE, szModel)
	cs_set_player_weap_model(iVictim, CSW_KNIFE, "") // Leave Blank so knife not appear with zombies
}

public ze_zombie_appear()
{
	// Add Delay to let Infection Sound to complete
	set_task(3.0, "ZombieAppear", _, _, _, "a", 1)
}

public ZombieAppear()
{	
	// Play Pre-Release Sound For All Players
	new szSound[SOUND_MAX_LENGTH]
	ArrayGetString(g_szPreReleaseSound, random_num(0, ArraySize(g_szPreReleaseSound) - 1), szSound, charsmax(szSound))
	
	for(new id = 1; id <= g_iMaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue

		PlaySound(id, szSound)
	}
}

public ze_zombie_release()
{
	// Add Delay to make sure Pre-Release Sound Finished
	set_task(float((g_iPreReleaseSoundDuration) - (get_pcvar_num(g_pCvarReleaseTime) - 3)), "AmbianceSound", TASK_AMBIENCESOUND, _, _, "a", 1)
}

public AmbianceSound()
{
	// Stop All Sounds
	StopSound()
	
	// Play The Ambiance Sound For All Players
	new szSound[SOUND_MAX_LENGTH]
	ArrayGetString(g_szAmbianceSound, random_num(0, ArraySize(g_szAmbianceSound) - 1), szSound, charsmax(szSound))
	
	for(new id = 1; id <= g_iMaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue

		PlaySound(id, szSound)
	}

	// We should Set Task back again to replay (Repeated 5 times MAX)
	set_task(float(g_iAmbianceSoundDuration), "RePlayAmbianceSound", TASK_REAMBIENCESOUND, _, _, "a", 5)
}

public RePlayAmbianceSound()
{
	// Play The Ambiance Sound For All Players
	new szSound[SOUND_MAX_LENGTH]
	ArrayGetString(g_szAmbianceSound, random_num(0, ArraySize(g_szAmbianceSound) - 1), szSound, charsmax(szSound))
	
	for(new id = 1; id <= g_iMaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue

		PlaySound(id, szSound)
	}
}

public ze_user_humanized(id)
{
	if(ze_is_user_zombie(id) || !is_user_alive(id))
		return
	
	// Rest Player Model (Model Randomly)
	rg_set_user_model(id, szHumanModels[random_num(0, charsmax(szHumanModels))])
		
	// Rest Player Knife model
	new szModel[MODEL_MAX_LENGTH]
	ArrayGetString(g_v_szHumanKnifeModel, random_num(0, ArraySize(g_v_szHumanKnifeModel) - 1), szModel, charsmax(szModel))
	cs_set_player_view_model(id, CSW_KNIFE, szModel)
	ArrayGetString(g_p_szHumanKnifeModel, random_num(0, ArraySize(g_p_szHumanKnifeModel) - 1), szModel, charsmax(szModel))
	cs_set_player_weap_model(id, CSW_KNIFE, szModel)
}

public ze_roundend(WinTeam)
{
	remove_task(TASK_AMBIENCESOUND)
	remove_task(TASK_REAMBIENCESOUND)
	StopSound()
	
	new szSound[SOUND_MAX_LENGTH]
	
	if (WinTeam == ZE_TEAM_ZOMBIE)
	{
		ArrayGetString(g_szEscapeFailSound, random_num(0, ArraySize(g_szEscapeFailSound) - 1), szSound, charsmax(szSound))
		
		for(new id = 1; id <= g_iMaxPlayers; id++)
		{
			if(!is_user_connected(id))
				continue

			PlaySound(id, szSound)
		}
	}
	
	if (WinTeam == ZE_TEAM_HUMAN)
	{
		ArrayGetString(g_szEscapeSuccessSound, random_num(0, ArraySize(g_szEscapeSuccessSound) - 1), szSound, charsmax(szSound))
		
		for(new id = 1; id <= g_iMaxPlayers; id++)
		{
			if(!is_user_connected(id))
				continue

			PlaySound(id, szSound)
		}
	}
}