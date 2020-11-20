#include <zombie_escape>

// Constants
new const szNvgSound[2][] = 
{
	"items/nvg_off.wav",
	"items/nvg_on.wav"
}

// Variables
new Float:g_flLastNvgToggle[33], 
	bool:g_bNvgOn[33], 
	g_szLightStyle[2],
	g_iMaxClients

// Cvars
new g_pCvarZombieNVission, 
	g_pCvarZombieAutoNVision, 
	g_pCvarNVisionDensity,
	g_pCvarZombieNVisionColors[3],
	g_pCvarLightingStyle
	
// Colors
enum
{
	Red = 0,
	Green,
	Blue
}

public plugin_init()
{
	register_plugin("[ZE] Nightvision/Lighting", ZE_VERSION, AUTHORS)
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_Killed, "Fw_PlayerKilled_Post", 1)
	
	// Commands
	register_clcmd("nightvision", "Cmd_NvgToggle")
	
	// Cvars
	g_pCvarZombieNVission = register_cvar("ze_zombie_nightvision", "1")
	g_pCvarZombieAutoNVision = register_cvar("ze_zombie_auto_nightvision", "1")
	g_pCvarNVisionDensity = register_cvar("ze_zombie_nightvision_density", "0.0010")
	g_pCvarZombieNVisionColors[Red] = register_cvar("ze_zombie_nvision_red", "255")
	g_pCvarZombieNVisionColors[Green] = register_cvar("ze_zombie_nvision_green", "0")
	g_pCvarZombieNVisionColors[Blue] = register_cvar("ze_zombie_nvision_blue", "0")
	g_pCvarLightingStyle = register_cvar("ze_lighting_style", "d")
	
	// Static Values
	g_iMaxClients = get_member_game(m_nMaxPlayers)
	
	// Set Lighting Task
	set_task(0.1, "Lighting_Style", _, _, _, "b")
}

public Lighting_Style()
{
	// Get light value from .cfg File and Store it in zero-based string array (If this value changed from sever it will apply instant not need changing map)
	get_pcvar_string(g_pCvarLightingStyle, g_szLightStyle, charsmax(g_szLightStyle))
	
	for (new id = 1; id <= g_iMaxClients; id++)
	{
		// Not Set For Un-Connected or Zombies
		if (!is_user_connected(id))
			continue
		
		if (!is_user_alive(id))
		{
			new iCamMode = get_entvar(id, var_iuser1)
			new iSpecId = get_entvar(id, var_iuser2)
			
			if (iCamMode == OBS_ROAMING) // Free Look
			{
				Set_NightVision(id, 0, 0, 0x0000, 0, 0, 0, 0)
				Set_MapLightStyle(id, g_szLightStyle)
			}
			
			if (!is_user_alive(iSpecId))
				continue
			
			if (ze_is_user_zombie(iSpecId))
			{
				if (g_bNvgOn[iSpecId])
				{
					Set_MapLightStyle(id, "z")
					Set_NightVision(id, 0, 0, 0x0004, get_pcvar_num(g_pCvarZombieNVisionColors[Red]), get_pcvar_num(g_pCvarZombieNVisionColors[Green]), get_pcvar_num(g_pCvarZombieNVisionColors[Blue]), get_pcvar_num(g_pCvarNVisionDensity))
				}
				else
				{
					Set_NightVision(id, 0, 0, 0x0000, 0, 0, 0, 0)
					Set_MapLightStyle(id, g_szLightStyle)
				}
			}
			else
			{
				Set_NightVision(id, 0, 0, 0x0000, 0, 0, 0, 0)
				Set_MapLightStyle(id, g_szLightStyle)
			}
		}
		else
		{
			if (ze_is_user_zombie(id))
				continue
			
			Set_NightVision(id, 0, 0, 0x0000, 0, 0, 0, 0)
			Set_MapLightStyle(id, g_szLightStyle)
		}
	}
}

public ze_user_infected(iVictim, iInfector)
{
	if (get_pcvar_num(g_pCvarZombieAutoNVision) != 0)
	{
		Set_MapLightStyle(iVictim, "z")
		Set_NightVision(iVictim, 0, 0, 0x0004, get_pcvar_num(g_pCvarZombieNVisionColors[Red]), get_pcvar_num(g_pCvarZombieNVisionColors[Green]), get_pcvar_num(g_pCvarZombieNVisionColors[Blue]), get_pcvar_num(g_pCvarNVisionDensity))
		g_bNvgOn[iVictim] = true
		PlaySound(iVictim, szNvgSound[1])
	}
}

public Cmd_NvgToggle(id)
{
	if (is_user_alive(id))
	{
		if(ze_is_user_zombie(id) && get_pcvar_num(g_pCvarZombieNVission) != 0)
		{
			new Float:fReffrenceTime = get_gametime()
			
			if(g_flLastNvgToggle[id] > fReffrenceTime)
				return
			
			// Just Add Delay like in default one in CS and to allow sound complete
			g_flLastNvgToggle[id] = fReffrenceTime + 1.5
			
			if(!g_bNvgOn[id])
			{
				g_bNvgOn[id] = true
				Set_MapLightStyle(id, "z")
				Set_NightVision(id, 0, 0, 0x0004, get_pcvar_num(g_pCvarZombieNVisionColors[Red]), get_pcvar_num(g_pCvarZombieNVisionColors[Green]), get_pcvar_num(g_pCvarZombieNVisionColors[Blue]), get_pcvar_num(g_pCvarNVisionDensity))
				PlaySound(id, szNvgSound[1])
			}
			else
			{
				g_bNvgOn[id] = false
				Set_NightVision(id, 0, 0, 0x0000, 0, 0, 0, 0)
				Set_MapLightStyle(id, g_szLightStyle)
				PlaySound(id, szNvgSound[0])
			}
		}
	}
}

public Fw_PlayerKilled_Post(id)
{
	if (g_bNvgOn[id])
	{
		g_bNvgOn[id] = false
		Set_NightVision(id, 0, 0, 0x0000, 0, 0, 0, 0)
		Set_MapLightStyle(id, g_szLightStyle)
	}
}