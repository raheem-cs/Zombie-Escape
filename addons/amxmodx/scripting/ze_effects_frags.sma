#include <zombie_escape>

// Variables
new g_iMaxClients

// Cvars
new Cvar_Human_Infected_iFrags, Cvar_Escape_Success_iFrags, Cvar_Infection_Deaths

public plugin_init()
{
	register_plugin("[ZE] Frags Awards/Death Effects", ZE_VERSION, AUTHORS)
	
	// Cvars
	Cvar_Human_Infected_iFrags = register_cvar("ze_human_infected_frags", "1")
	Cvar_Infection_Deaths = register_cvar("ze_infection_deaths", "1")
	Cvar_Escape_Success_iFrags = register_cvar("ze_escape_success_frags", "3")
	
	// Static Values
	g_iMaxClients = get_member_game(m_nMaxPlayers)
}

public ze_user_infected(iVictim, iInfector)
{
	if (iInfector == 0) // Block Awards for Zombies Chosen by the Server
		return
	
	// Award Zombie Who infected, And Increase Deaths of the infected human
	UpdateFrags(iInfector, iVictim, get_pcvar_num(Cvar_Human_Infected_iFrags), get_pcvar_num(Cvar_Infection_Deaths), 1)
	
	// Adding Infection icon on Victim Screen
	InfectionIcon(iVictim)
	
	// Fix Dead Attribute (Delay needed)
	set_task(0.1, "Fix_DeadAttrib", _, _, _, "a", 6)
}

public ze_roundend(WinTeam)
{
	if (WinTeam == ZE_TEAM_HUMAN)
	{
		for (new i = 1; i <= g_iMaxClients; i++)
		{
			// Skip All Dead Players or Zombies
			if (!is_user_alive(i) || get_member(i, m_iTeam) == TEAM_TERRORIST)
				continue
			
			// + Frags for All humans Who are Alive
			UpdateFrags(i, 0, get_pcvar_num(Cvar_Escape_Success_iFrags), 0, 1)
		}
	}
}

public Fix_DeadAttrib()
{
	for (new i = 1; i <= g_iMaxClients; i++)
	{
		// Skip All Dead And Humans
		if (!is_user_alive(i) || get_member(i, m_iTeam) == TEAM_CT)
			continue
		
		// Fix the Dead Attribute
		FixDeadAttrib(i)
	}
}