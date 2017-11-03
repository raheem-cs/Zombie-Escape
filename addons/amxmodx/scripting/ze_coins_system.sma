#include <zombie_escape>

// Static (Change it if you need)
new const g_szVaultName[] = "Escape_Coins"

// Variables
new g_iMaxClients, g_iEscapeCoins[33], Float:g_fDamage[33], g_iVaultHandle

// Cvars
new Cvar_Escape_Success, Cvar_Human_Infected, Cvar_Damage, Cvar_Damage_Coins, Cvar_Start_Coins, Cvar_Max_Coins,
Cvar_Earn_ChatNotice

public plugin_natives()
{
	register_native("ze_get_escape_coins", "native_ze_get_escape_coins", 1)
	register_native("ze_set_escape_coins", "native_ze_set_escape_coins", 1)
}

public plugin_init()
{
	register_plugin("[ZE] Escape Coins System", ZE_VERSION, AUTHORS)
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Fw_TakeDamage_Post", 1)
	
	// Commands
	register_clcmd("say /EC", "Coins_Info")
	register_clcmd("say_team /EC", "Coins_Info")
	
	// Static Values
	g_iMaxClients = get_member_game(m_nMaxPlayers)
	
	// Cvars
	Cvar_Escape_Success = register_cvar("ze_escape_success_coins", "15")
	Cvar_Human_Infected = register_cvar("ze_human_infected_coins", "5")
	Cvar_Damage = register_cvar("ze_damage_required", "300")
	Cvar_Damage_Coins = register_cvar("ze_damage_coins", "4")
	Cvar_Start_Coins = register_cvar("ze_start_coins", "50")
	Cvar_Max_Coins = register_cvar("ze_max_coins", "200000")
	Cvar_Earn_ChatNotice = register_cvar("ze_earn_chat_notice", "1")
	
	// Open the Vault
	g_iVaultHandle = nvault_open(g_szVaultName)
	
	if (g_iVaultHandle == INVALID_HANDLE)
	{
		set_fail_state("Error opening nVault")
	}
}

public Coins_Info(id)
{
	ze_colored_print(id, "%L", LANG_PLAYER, "COINS_INFO", g_iEscapeCoins[id])
}

public client_putinserver(id) 
{
	if (is_user_bot(id) || is_user_hltv(id))
		return
	
	LoadCoins(id)
}

public client_disconnected(id) 
{
	if (is_user_bot(id) || is_user_hltv(id))
		return
	
	SaveCoins(id)
}

public plugin_end()
{
	nvault_close(g_iVaultHandle)
}

public ze_roundend(WinTeam)
{
	for(new id = 1; id <= g_iMaxClients; id++)
	{
		if (!is_user_alive(id) || ze_is_user_zombie(id))
			continue
		
		if (WinTeam == ZE_TEAM_HUMAN)
		{
			g_iEscapeCoins[id] += get_pcvar_num(Cvar_Escape_Success)
			
			if (get_pcvar_num(Cvar_Earn_ChatNotice) != 0)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "ESCAPE_SUCCESS_COINS", get_pcvar_num(Cvar_Escape_Success))
			}
		}
	}
}

public ze_user_infected(iVictim, iInfector)
{
	if (iInfector == 0) // Server ID
		return

	g_iEscapeCoins[iInfector] += get_pcvar_num(Cvar_Human_Infected)
	
	if (get_pcvar_num(Cvar_Earn_ChatNotice) != 0)
	{
		ze_colored_print(iInfector, "%L", LANG_PLAYER, "HUMAN_INFECTED_COINS", get_pcvar_num(Cvar_Human_Infected))
	}
}

public Fw_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType)
{
	// Player Damage Himself
	if (iVictim == iAttacker)
		return HC_CONTINUE
	
	// Two Players From one Team
	if (get_member(iAttacker, m_iTeam) == get_member(iVictim, m_iTeam))
		return HC_CONTINUE
	
	// iVictim or iAttacker Not Alive
	if (!is_user_alive(iVictim) || !is_user_alive(iAttacker))
		return HC_CONTINUE
	
	// Attacker is Zombie
	if (get_member(iAttacker, m_iTeam) == TEAM_TERRORIST)
		return HC_CONTINUE
	
	// Store Damage For every Player
	g_fDamage[iAttacker] += fDamage
	
	// Damage Calculator Equal or Higher than needed damage
	if (g_fDamage[iAttacker] >= get_pcvar_float(Cvar_Damage))
	{
		// Give Player The Coins
		g_iEscapeCoins[iAttacker] += get_pcvar_num(Cvar_Damage_Coins)
		
		// Rest The Damage Calculator
		g_fDamage[iAttacker] = 0.0
	}
	return HC_CONTINUE
}

LoadCoins(id)
{
	new szAuthID[35], iStartValue
	iStartValue = get_pcvar_num(Cvar_Start_Coins)
	
	get_user_authid(id, szAuthID, charsmax(szAuthID))
	
	new iCoins = nvault_get(g_iVaultHandle , szAuthID)
	
	if(iCoins != 0)
	{
		g_iEscapeCoins[id] = iCoins
	}
	else
	{
		g_iEscapeCoins[id] = iStartValue
	}
}

SaveCoins(id)
{
	new szAuthID[35], iMaxValue
	iMaxValue = get_pcvar_num(Cvar_Max_Coins)
	get_user_authid(id, szAuthID, charsmax(szAuthID))
	
	// Set Him to max if he Higher than Max Value
	if(g_iEscapeCoins[id] > iMaxValue)
	{
		g_iEscapeCoins[id] = iMaxValue
	}
	
	// Temporary solution to prevent saving if coins for player turned to 0
	if (g_iEscapeCoins[id] > 0)
	{
		new szData[16]
		num_to_str(g_iEscapeCoins[id], szData, charsmax(szData))
		
		// Save His SteamID, Escape Coins
		nvault_set(g_iVaultHandle, szAuthID, szData)
	}
}

public native_ze_get_escape_coins(id)
{
	return g_iEscapeCoins[id]
}

public native_ze_set_escape_coins(id, iAmount)
{
	g_iEscapeCoins[id] = iAmount
}