#include <zombie_escape>

// Settings file
new const ZE_SETTING_RESOURCES[] = "zombie_escape.ini"

// Default Values (Important in case of stupid user delete the .ini File)
new g_iRain = 0
new g_iSnow = 0
new g_iFog = 1
new g_szFogDensity[16] = "0.0018"
new g_szFogColor[16] = "100 100 100"
new szSkyName[32] = "hk"

public plugin_init()
{
	register_plugin("[ZE] Weather Effects", ZE_VERSION, AUTHORS)
	
	// Disable sky lighting so it doesn't mess with our custom lighting
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)
}

public plugin_precache()
{
	// Load Settings From .ini File if not found Create it and save our default Values
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Weather Effects", "FOG DENSITY", g_szFogDensity, charsmax(g_szFogDensity)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Weather Effects", "FOG DENSITY", g_szFogDensity)
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Weather Effects", "FOG COLOR", g_szFogColor, charsmax(g_szFogColor)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Weather Effects", "FOG COLOR", g_szFogColor)
	
	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Weather Effects", "FOG", g_iFog))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Weather Effects", "FOG", g_iFog)
	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Weather Effects", "SNOW", g_iSnow))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Weather Effects", "SNOW", g_iSnow)
	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Weather Effects", "RAIN", g_iRain))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Weather Effects", "RAIN", g_iRain)
	
	if (!amx_load_setting_string(ZE_SETTING_RESOURCES, "Weather Effects", "SKY", szSkyName, charsmax(szSkyName)))
		amx_save_setting_string(ZE_SETTING_RESOURCES, "Weather Effects", "SKY", szSkyName)
	
	// Fog
	if (g_iFog != 0)
	{
		// Create the Fog Entity
		new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		
		if (pev_valid(iEnt))
		{
			// Set The fog
			Set_KeyValue(iEnt, "density", g_szFogDensity, "env_fog")
			Set_KeyValue(iEnt, "rendercolor", g_szFogColor, "env_fog")
		}
	}
	
	// Rain
	if (g_iRain != 0)
		engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	
	// Snow
	if (g_iSnow != 0)
		engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))
	
	// Sky
	Precache_Sky(szSkyName)
}