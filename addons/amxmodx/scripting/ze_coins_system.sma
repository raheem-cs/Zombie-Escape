#include <zombie_escape>

// Static (Change it if you need)
new const g_szVaultName[] = "Escape_Coins"

// MySQL Table
new const g_szTable[] = "CREATE TABLE IF NOT EXISTS `Escape_Coins` ( `Player SteamID` varchar(34) NOT NULL,`Player EC` int(16) NOT NULL,PRIMARY KEY (`Player SteamID`) );"

// Variables
new g_iMaxClients,
	g_iVaultHandle,
	g_iEscapeCoins[33], 
	Float:g_fDamage[33],
	Handle:g_hTuple,
	Handle:g_hSQLConnection

// Cvars
new g_pCvarEscapeSuccess, 
	g_pCvarHumanInfected, 
	g_pCvarDamage, 
	g_pCvarDamageCoins, 
	g_pCvarStartCoins, 
	g_pCvarMaxCoins,
	g_pCvarEarnChatNotice,
	g_pCvarSaveType,
	g_pCvarDBInfo[4]

// Database
enum
{
	Host = 0,
	User,
	Pass,
	DB
}

// Natives
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
	g_pCvarSaveType = register_cvar("ze_coins_save_type", "0")
	g_pCvarEscapeSuccess = register_cvar("ze_escape_success_coins", "15")
	g_pCvarHumanInfected = register_cvar("ze_human_infected_coins", "5")
	g_pCvarDamage = register_cvar("ze_damage_required", "300")
	g_pCvarDamageCoins = register_cvar("ze_damage_coins", "4")
	g_pCvarStartCoins = register_cvar("ze_start_coins", "50")
	g_pCvarMaxCoins = register_cvar("ze_max_coins", "200000")
	g_pCvarEarnChatNotice = register_cvar("ze_earn_chat_notice", "1")
	
	g_pCvarDBInfo[Host] = register_cvar("ze_ec_host", "localhost")
	g_pCvarDBInfo[User] = register_cvar("ze_ec_user", "user")
	g_pCvarDBInfo[Pass] = register_cvar("ze_ec_pass", "pass")
	g_pCvarDBInfo[DB] = register_cvar("ze_ec_dbname", "dbname")
	
	// Initialize MySQL
	MySQL_Init()
}

public Coins_Info(id)
{
	ze_colored_print(id, "%L", LANG_PLAYER, "COINS_INFO", g_iEscapeCoins[id])
}

public MySQL_Init()
{
	if (!get_pcvar_num(g_pCvarSaveType))
		return
	
	new szHost[64], szUser[32], szPass[32], szDB[128]
	
	get_pcvar_string(g_pCvarDBInfo[Host], szHost, charsmax(szHost))
	get_pcvar_string(g_pCvarDBInfo[User], szUser, charsmax(szUser))
	get_pcvar_string(g_pCvarDBInfo[Pass], szPass, charsmax(szPass))
	get_pcvar_string(g_pCvarDBInfo[DB], szDB, charsmax(szDB))
	
	g_hTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDB)
	
	// Let's ensure that the g_hTuple will be valid, we will access the database to make sure
	new iErrorCode, szError[512]
	
	g_hSQLConnection = SQL_Connect(g_hTuple, iErrorCode, szError, charsmax(szError))
	
	if(g_hSQLConnection != Empty_Handle)
	{
		log_amx("[MySQL] Successfully connected to host: %s (ALL IS OK).", szHost)
	}
	else
	{
		log_amx("[MySQL] [Error] %s", szError)
		
		// Disable plugin
		set_fail_state("Failed to connect to MySQL database.")
	}
	
	SQL_ThreadQuery(g_hTuple, "QueryCreateTable", g_szTable)
}

public QueryCreateTable(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime) 
{
	SQL_IsFail(iFailState, iError, szError)
}

public client_putinserver(id) 
{
	if (is_user_bot(id) || is_user_hltv(id))
		return
	
	// Just 1 second delay
	set_task(1.0, "DelayLoad", id)
}

public DelayLoad(id)
{
	LoadCoins(id)
}

public plugin_end()
{
	if (get_pcvar_num(g_pCvarSaveType))
	{
		SQL_FreeHandle(g_hTuple)
	}
}

public ze_roundend(WinTeam)
{
	if (WinTeam == ZE_TEAM_HUMAN)
	{
		for(new id = 1; id <= g_iMaxClients; id++)
		{
			if (!is_user_alive(id) || ze_is_user_zombie(id))
				continue
			
			g_iEscapeCoins[id] += get_pcvar_num(g_pCvarEscapeSuccess)
			
			SaveCoins(id)
			
			if (get_pcvar_num(g_pCvarEarnChatNotice) != 0)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "ESCAPE_SUCCESS_COINS", get_pcvar_num(g_pCvarEscapeSuccess))
			}
		}
	}
}

public ze_user_infected(iVictim, iInfector)
{
	if (iInfector == 0) // Server ID
		return

	g_iEscapeCoins[iInfector] += get_pcvar_num(g_pCvarHumanInfected)
	
	SaveCoins(iInfector)
	
	if (get_pcvar_num(g_pCvarEarnChatNotice) != 0)
	{
		ze_colored_print(iInfector, "%L", LANG_PLAYER, "HUMAN_INFECTED_COINS", get_pcvar_num(g_pCvarHumanInfected))
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
	if (g_fDamage[iAttacker] >= get_pcvar_float(g_pCvarDamage))
	{
		// Give Player The Coins
		g_iEscapeCoins[iAttacker] += get_pcvar_num(g_pCvarDamageCoins)
		
		SaveCoins(iAttacker)
		
		// Rest The Damage Calculator
		g_fDamage[iAttacker] = 0.0
	}
	return HC_CONTINUE
}

LoadCoins(id)
{
	new szAuthID[35]
	get_user_authid(id, szAuthID, charsmax(szAuthID))
	
	if (!get_pcvar_num(g_pCvarSaveType))
	{
		// Open the Vault
		g_iVaultHandle = nvault_open(g_szVaultName)
		
		// Get coins
		new szCoins[16], iExists, iTimestamp;
		iExists = nvault_lookup(g_iVaultHandle, szAuthID, szCoins, charsmax(szCoins), iTimestamp);
		
		// Close Vault
		nvault_close(g_iVaultHandle)
		
		if (!iExists)
		{
			// Player exist? Load start value then save
			g_iEscapeCoins[id] = get_pcvar_num(g_pCvarStartCoins)
			SaveCoins(id)
		}
		else
		{
			g_iEscapeCoins[id] = str_to_num(szCoins)
		}
	}
	else
	{
		new szQuery[128], szData[5]
		formatex(szQuery, charsmax(szQuery), "SELECT `Player EC` FROM `Escape_Coins` WHERE ( `Player SteamID` = '%s' );", szAuthID)
     
		num_to_str(id, szData, charsmax(szData))
		SQL_ThreadQuery(g_hTuple, "QuerySelectData", szQuery, szData, charsmax(szData))
	}
}

public QuerySelectData(iFailState, Handle:hQuery, szError[], iError, szData[]) 
{
	if(SQL_IsFail(iFailState, iError, szError))
		return
	
	new id = str_to_num(szData)
	
	// No results for this query means that player not saved before
	if(!SQL_NumResults(hQuery))
	{
		// This is new player
		g_iEscapeCoins[id] = get_pcvar_num(g_pCvarStartCoins)
		SaveCoins(id)
		return
	}
	
	// Get the "Player EC" column number (It's 2, always i don't like to hardcode :p)
	new iEC_Column = SQL_FieldNameToNum(hQuery, "Player EC")
	
	// Read the coins of this player
	g_iEscapeCoins[id] = SQL_ReadResult(hQuery, iEC_Column)
}

SaveCoins(id)
{
	new szAuthID[35], iMaxValue
	iMaxValue = get_pcvar_num(g_pCvarMaxCoins)
	get_user_authid(id, szAuthID, charsmax(szAuthID))
	
	// Set Him to max if he Higher than Max Value
	if (g_iEscapeCoins[id] > iMaxValue)
	{
		g_iEscapeCoins[id] = iMaxValue
	}

	new szData[16]
	num_to_str(g_iEscapeCoins[id], szData, charsmax(szData))

	if (!get_pcvar_num(g_pCvarSaveType))
	{
		// Open the Vault
		g_iVaultHandle = nvault_open(g_szVaultName)

		// Save His SteamID, Escape Coins
		nvault_set(g_iVaultHandle, szAuthID, szData)
		
		// Close Vault
		nvault_close(g_iVaultHandle)
	}
	else
	{
		new szQuery[128]
		formatex(szQuery, charsmax(szQuery), "REPLACE INTO `Escape_Coins` (`Player SteamID`, `Player EC`) VALUES ('%s', '%d');", szAuthID, g_iEscapeCoins[id])
		SQL_ThreadQuery(g_hTuple, "QuerySetData", szQuery)
	}
}

public QuerySetData(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime) 
{
	SQL_IsFail(iFailState, iError, szError)
}

// Natives
public native_ze_get_escape_coins(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	return g_iEscapeCoins[id]
}

public native_ze_set_escape_coins(id, iAmount)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	g_iEscapeCoins[id] = iAmount
	
	SaveCoins(id)
	return true;
}