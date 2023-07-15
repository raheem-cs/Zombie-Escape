#include <zombie_escape>

// Macro
#define FIsFakeClient(%0) bool:((g_iIsFakeClient & BIT(%0)) ? 1 : 0)

// Save Type
enum (+=1)
{
	Save_NOT = -1,
	Save_nVault,
	Save_MySQL
}

// Database
enum _:SQL_DATA
{
	SQL_HOST[64] = 0,
	SQL_USER[32],
	SQL_PASS[32],
	SQL_DB[128]
}

// Static (Change it if you need)
new const g_szVaultName[] = "Escape_Coins"
new const g_szLogFile[] = "Escape-Coins.log" // MySQL Errors log file

// MySQL Table
new const g_szTable[] = 
" \
	CREATE TABLE IF NOT EXISTS `zombie_escape` \
	( \
		`SteamID` varchar(64) NOT NULL, \
		`EC` int(32) NOT NULL, \
		PRIMARY KEY (`SteamID`) \
	); \
"

// Variables
new g_iVaultHandle,
	g_iIsFakeClient,
	g_iEscapeCoins[MAX_PLAYERS+1], 
	Float:g_flDamage[MAX_PLAYERS+1],
	Handle:g_hTuple

// Cvars
new g_iSaveType,
	g_iMaxCoins,
	g_iStartCoins, 
	g_iDamageCoins, 
	g_iEscapeSuccess, 
	g_iHumanInfected, 
	bool:g_bEarnChatNotice,
	Float:g_flRequiredDamage, 
	g_szDBInfo[SQL_DATA]

// Natives
public plugin_natives()
{
	register_native("ze_get_escape_coins", "native_ze_get_escape_coins")
	register_native("ze_set_escape_coins", "native_ze_set_escape_coins")
}

public plugin_init()
{
	register_plugin("[ZE] Escape Coins System", ZE_VERSION, AUTHORS)
	
	// Hook Chains
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fw_TakeDamage_Post", 1)
	
	// Commands
	register_clcmd("say /EC", "cmd_CoinsInfo")
	register_clcmd("say_team /EC", "cmd_CoinsInfo")
	
	// Cvars
	bind_pcvar_num(register_cvar("ze_coins_save_type", "0"), g_iSaveType)
	bind_pcvar_num(register_cvar("ze_escape_success_coins", "15"), g_iEscapeSuccess)
	bind_pcvar_num(register_cvar("ze_human_infected_coins", "5"), g_iHumanInfected)
	bind_pcvar_num(register_cvar("ze_damage_coins", "4"), g_iDamageCoins)
	bind_pcvar_num(register_cvar("ze_start_coins", "50"), g_iStartCoins)
	bind_pcvar_num(register_cvar("ze_max_coins", "200000"), g_iMaxCoins)
	bind_pcvar_num(register_cvar("ze_earn_chat_notice", "1"), g_bEarnChatNotice)
	bind_pcvar_float(register_cvar("ze_damage_required", "300.0"), g_flRequiredDamage)
	
	bind_pcvar_string(register_cvar("ze_ec_host", "localhost"), g_szDBInfo[SQL_HOST], charsmax(g_szDBInfo) - SQL_HOST)
	bind_pcvar_string(register_cvar("ze_ec_user", "user"), g_szDBInfo[SQL_USER], charsmax(g_szDBInfo) - SQL_USER)
	bind_pcvar_string(register_cvar("ze_ec_pass", "pass"), g_szDBInfo[SQL_PASS], charsmax(g_szDBInfo) - SQL_PASS)
	bind_pcvar_string(register_cvar("ze_ec_dbname", "dbname"), g_szDBInfo[SQL_DB], charsmax(g_szDBInfo) - SQL_DB)
	
	// Initialize MySQL - Delay 0.1 second required so we make sure that our zombie_escape.cfg already executed and cvars values loaded from it
	set_task(0.1, "Delay_MySQL_Init")
}

public plugin_end()
{
	// Free SQL handle.
	if (g_hTuple != Empty_Handle)
		SQL_FreeHandle(g_hTuple)
}

public cmd_CoinsInfo(const id)
{
	ze_colored_print(id, "%L", LANG_PLAYER, "COINS_INFO", g_iEscapeCoins[id])
}

public Delay_MySQL_Init()
{
	MySQL_Init()
}

public MySQL_Init()
{
	if (g_iSaveType != Save_MySQL)
		return;
	
	g_hTuple = SQL_MakeDbTuple(g_szDBInfo[SQL_HOST], g_szDBInfo[SQL_USER], g_szDBInfo[SQL_PASS], g_szDBInfo[SQL_DB])
	
	// Let's ensure that the g_hTuple will be valid, we will access the database to make sure
	new iErrorCode, szError[512], Handle:hSQLConnection
	
	hSQLConnection = SQL_Connect(g_hTuple, iErrorCode, szError, charsmax(szError))
	
	if(hSQLConnection != Empty_Handle)
	{
		log_amx("[MySQL] Successfully connected to host: %s (ALL IS OK).", g_szDBInfo[SQL_HOST])
		SQL_FreeHandle(hSQLConnection)
	}
	else
	{
		// Disable plugin, and display the error
		set_fail_state("Failed to connect to MySQL database: %s", szError)
	}
	
	// Create our table
	SQL_ThreadQuery(g_hTuple, "QueryCreateTable", g_szTable)
}

public QueryCreateTable(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime) 
{
	SQL_IsFail(iFailState, iError, szError, g_szLogFile)
}

public client_putinserver(id)
{
	if (is_user_bot(id) || is_user_hltv(id))
	{
		g_iIsFakeClient |= BIT(id)
		return;
	}

	// Load player Coins.
	LoadCoins(id)
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// Fake Client!
	if (FIsFakeClient(id))
	{
		g_iIsFakeClient &= ~BIT(id)
		return;
	}

	// Save player Coins.
	SaveCoins(id)

	// Reset variables.
	g_iEscapeCoins[id] = 0
	g_flDamage[id] = 0.0
}

public ze_user_infected(iVictim, iInfector)
{
	if (iInfector == 0) // Server ID
		return

	g_iEscapeCoins[iInfector] += g_iHumanInfected

	if (g_bEarnChatNotice)
	{
		ze_colored_print(iInfector, "%L", LANG_PLAYER, "HUMAN_INFECTED_COINS", g_iHumanInfected)
	}
}

public fw_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType)
{
	// Player not in game or Damage himself
	if (iVictim == iAttacker || !is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return;
	
	// Attacker is Zombie
	if (ze_is_user_zombie(iAttacker))
		return;
	
	// Two Players From one Team
	if (get_user_team(iVictim) == get_user_team(iAttacker))
		return;

	if (g_iDamageCoins > 0)
	{
		// Store Damage For every Player
		g_flDamage[iAttacker] += fDamage
		
		// Damage Calculator Equal or Higher than needed damage
		while (g_flDamage[iAttacker] >= g_flRequiredDamage)
		{
			g_iEscapeCoins[iAttacker] += g_iDamageCoins
			g_flDamage[iAttacker] -= g_flRequiredDamage
		}
	}
}

public ze_roundend(WinTeam)
{
	if (WinTeam == ZE_TEAM_HUMAN)
	{
		new iPlayers[MAX_PLAYERS], iAliveNum, id

		// Get index of all alive players.
		get_players(iPlayers, iAliveNum, "a")

		for(new i = 0; i < iAliveNum; i++)
		{
			// Get client index.
			id = iPlayers[i]
			
			if (ze_is_user_zombie(id))
				continue;
			
			g_iEscapeCoins[id] += g_iEscapeSuccess
			
			if (g_bEarnChatNotice)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "ESCAPE_SUCCESS_COINS", g_iEscapeSuccess)
			}
		}
	}
}

/**
 * ===[ Functions ]===
 */
LoadCoins(const id)
{
	new szAuthID[MAX_AUTHID_LENGTH]
	get_user_authid(id, szAuthID, charsmax(szAuthID))
	
	switch (g_iSaveType)
	{
		case Save_nVault:
		{
			// Open the Vault
			g_iVaultHandle = nvault_open(g_szVaultName)
			
			// Error in opening Vault.
			if (g_iVaultHandle == INVALID_HANDLE)
				set_fail_state("Error in opening the nVault!")

			// Get coins from Vault
			g_iEscapeCoins[id] = nvault_get(g_iVaultHandle, szAuthID)

			// Close the Vault
			nvault_close(g_iVaultHandle)
		}
		case Save_MySQL:
		{
			new szQuery[128], szData[5]
			formatex(szQuery, charsmax(szQuery), "SELECT `EC` FROM `zombie_escape` WHERE ( `SteamID` = '%s' );", szAuthID)

			num_to_str(id, szData, charsmax(szData))
			SQL_ThreadQuery(g_hTuple, "@QuerySelectData", szQuery, szData, charsmax(szData))
		}
	}
}

@QuerySelectData(iFailState, Handle:hQuery, szError[], iError, szData[]) 
{
	if(SQL_IsFail(iFailState, iError, szError, g_szLogFile))
		return
	
	new id = str_to_num(szData)
	
	// No results for this query means that player not saved before
	if(!SQL_NumResults(hQuery))
	{
		// This is new player
		g_iEscapeCoins[id] = g_iStartCoins
		
		// Get user steamid
		new szAuthID[MAX_AUTHID_LENGTH]
		get_user_authid(id, szAuthID, charsmax(szAuthID))
		
		// Insert his data to our database
		new szQuery[128]
		formatex(szQuery, charsmax(szQuery), "INSERT INTO `zombie_escape` (`SteamID`, `EC`) VALUES ('%s', '%d');", szAuthID, g_iEscapeCoins[id])
		SQL_ThreadQuery(g_hTuple, "@QueryInsertData", szQuery)
		return;
	}
	
	// Get the "EC" column number (It's 2, always i don't like to hardcode :p)
	new iEC_Column = SQL_FieldNameToNum(hQuery, "EC")
	
	// Read the coins of this player
	g_iEscapeCoins[id] = SQL_ReadResult(hQuery, iEC_Column)
}

@QueryInsertData(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime)
{
	SQL_IsFail(iFailState, iError, szError, g_szLogFile)
}

SaveCoins(id)
{
	new szAuthID[MAX_AUTHID_LENGTH]
	get_user_authid(id, szAuthID, charsmax(szAuthID))
	
	// Set Him to max if he Higher than Max Value
	if (g_iEscapeCoins[id] > g_iMaxCoins)
		g_iEscapeCoins[id] = g_iMaxCoins

	new szData[32]
	num_to_str(g_iEscapeCoins[id], szData, charsmax(szData))

	switch (g_iSaveType)
	{
		case Save_nVault:
		{
			// Open the Vault
			g_iVaultHandle = nvault_open(g_szVaultName)

			// Save His SteamID, Escape Coins
			nvault_pset(g_iVaultHandle, szAuthID, szData)
			
			// Close Vault
			nvault_close(g_iVaultHandle)
		}
		case Save_MySQL:
		{
			new szQuery[128]
			formatex(szQuery, charsmax(szQuery), "UPDATE `zombie_escape` SET `EC` = '%d' WHERE `SteamID` = '%s';", g_iEscapeCoins[id], szAuthID)
			SQL_ThreadQuery(g_hTuple, "@QueryUpdateData", szQuery)
		}
	}
}

@QueryUpdateData(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime) 
{
	SQL_IsFail(iFailState, iError, szError, g_szLogFile)
}

/**
 * ===[ Natives ]===
 */
public native_ze_get_escape_coins(plugin_id, num_params)
{
	new id = get_param(1)

	// Player not in game?
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not in game (%d)", id)
		return NULLENT;
	}
	
	return g_iEscapeCoins[id]
}

public native_ze_set_escape_coins(plugin_id, num_params)
{
	new id = get_param(1)

	// Player not in game?
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not in game (%d)", id)
		return false;
	}
	
	g_iEscapeCoins[id] = get_param(2)
	return true;
}