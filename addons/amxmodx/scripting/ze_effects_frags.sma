#include <zombie_escape>

// Variables
new g_iMaxClients

// Cvars
new g_pCvarHumanInfectedFrags, 
	g_pCvarEscapeSuccessFrags, 
	g_pCvarInfectionDeaths

public plugin_init()
{
	register_plugin("[ZE] Frags Awards/Death Effects", ZE_VERSION, AUTHORS)
	
	// Cvars
	g_pCvarHumanInfectedFrags = register_cvar("ze_human_infected_frags", "1")
	g_pCvarInfectionDeaths = register_cvar("ze_infection_deaths", "1")
	g_pCvarEscapeSuccessFrags = register_cvar("ze_escape_success_frags", "3")
	
	// Static Values
	g_iMaxClients = get_member_game(m_nMaxPlayers)
}

public ze_user_infected(iVictim, iInfector)
{
	if (iInfector == 0) // Block Awards for Zombies Chosen by the Server
		return
	
	// Award Zombie Who infected, And Increase Deaths of the infected human
	UpdateFrags(iInfector, iVictim, get_pcvar_num(g_pCvarHumanInfectedFrags), get_pcvar_num(g_pCvarInfectionDeaths), 1)
	
	// Adding Infection icon on Victim Screen
	InfectionIcon(iVictim)
	
	// Fix Dead Attribute (Delay needed)
	set_task(0.1, "Fix_DeadAttrib", _, _, _, "a", 6)
}

public ze_roundend(WinTeam)
{
	if (WinTeam == ZE_TEAM_HUMAN)
	{
		for (new id = 1; id <= g_iMaxClients; id++)
		{
			// Skip All Dead Players or Zombies
			if (!is_user_alive(id) || ze_is_user_zombie(id))
				continue
			
			// + Frags for All humans Who are Alive
			UpdateFrags(id, 0, get_pcvar_num(g_pCvarEscapeSuccessFrags), 0, 1)
		}
	}
}

public Fix_DeadAttrib()
{
	for (new id = 1; id <= g_iMaxClients; id++)
	{
		// Skip All Dead And Humans
		if (!is_user_alive(id) || !ze_is_user_zombie(id))
			continue
		
		// Fix the Dead Attribute
		FixDeadAttrib(id)
	}
}