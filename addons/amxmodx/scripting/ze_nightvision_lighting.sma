#include <zombie_escape>

// Constants
new const szNvgSound[2][] = 
{
	"items/nvg_off.wav",
	"items/nvg_on.wav"
}

// Variables
new Float:g_fLastNvgToggle[33], bool:g_bNvgOn[33], g_szLightStyle[2]

// Cvars
new Cvar_Zombie_iNvision, Cvar_Zombie_iAutoNVision, Cvar_Zombie_Nvision_iDensity,
Cvar_Zombie_Nvision_iRed, Cvar_Zombie_Nvision_iGreen, Cvar_Zombie_Nivision_iBlue,
Cvar_Lighting_Style

public plugin_init()
{
	register_plugin("[ZE] Nightvision/Lighting", ZE_VERSION, AUTHORS)
	
	// Commands
	register_clcmd("nightvision", "Cmd_NvgToggle")
	
	// Cvars
	Cvar_Zombie_iNvision = register_cvar("ze_zombie_nightvision", "1")
	Cvar_Zombie_iAutoNVision = register_cvar("ze_zombie_auto_nightvision", "1")
	Cvar_Zombie_Nvision_iDensity = register_cvar("ze_zombie_nightvision_density", "0.0010")
	Cvar_Zombie_Nvision_iRed = register_cvar("ze_zombie_nvision_red", "255")
	Cvar_Zombie_Nvision_iGreen = register_cvar("ze_zombie_nvision_green", "0")
	Cvar_Zombie_Nivision_iBlue = register_cvar("ze_zombie_nvision_blue", "0")
	Cvar_Lighting_Style = register_cvar("ze_lighting_style", "d")
	
	// Set Lighting Task
	set_task(1.0, "Lighting_Style", _, _, _, "b")
}

public Lighting_Style()
{
	// Get light value from .cfg File and Store it in zero-based string array (If this value changed from sever it will apply instant not need changing map)
	get_pcvar_string(Cvar_Lighting_Style, g_szLightStyle, charsmax(g_szLightStyle))
	
	for (new i = 1; i <= get_member_game(m_nMaxPlayers); i++)
	{
		// Not Set For Un-Connected or Zombies
		if (!is_user_connected(i) || ze_is_user_zombie(i))
			continue
		
		Set_MapLightStyle(i, g_szLightStyle)
	}
}

public ze_user_infected(iVictim, iInfector)
{
	if (get_pcvar_num(Cvar_Zombie_iAutoNVision) != 0)
	{
		Set_NightVision(iVictim, 0, 0, 0x0004, get_pcvar_num(Cvar_Zombie_Nvision_iRed), get_pcvar_num(Cvar_Zombie_Nvision_iGreen), get_pcvar_num(Cvar_Zombie_Nivision_iBlue), get_pcvar_num(Cvar_Zombie_Nvision_iDensity))
		Set_MapLightStyle(iVictim, "z")
		g_bNvgOn[iVictim] = true
		PlaySound(iVictim, szNvgSound[1])
	}
}
	
public Cmd_NvgToggle(id)
{
	if (is_user_connected(id))
	{
		if(ze_is_user_zombie(id) && get_pcvar_num(Cvar_Zombie_iNvision) != 0)
		{
			new Float:fReffrenceTime = get_gametime()
			
			if(g_fLastNvgToggle[id] > fReffrenceTime)
				return
			
			// Just Add Delay like in default one in CS and to allow sound complete
			g_fLastNvgToggle[id] = fReffrenceTime + 1.5
			
			if(!g_bNvgOn[id])
			{
				g_bNvgOn[id] = true
				Set_NightVision(id, 0, 0, 0x0004, get_pcvar_num(Cvar_Zombie_Nvision_iRed), get_pcvar_num(Cvar_Zombie_Nvision_iGreen), get_pcvar_num(Cvar_Zombie_Nivision_iBlue), get_pcvar_num(Cvar_Zombie_Nvision_iDensity))
				Set_MapLightStyle(id, "z")
				PlaySound(id, szNvgSound[1])
			}
			else
			{
				g_bNvgOn[id] = false
				Set_MapLightStyle(id, g_szLightStyle)
				Set_NightVision(id, 0, 0, 0x0000, 0, 0, 0, 0)
				PlaySound(id, szNvgSound[0])
			}
		}
	}
}