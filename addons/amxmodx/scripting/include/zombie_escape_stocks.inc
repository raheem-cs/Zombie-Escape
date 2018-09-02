#define ZE_PREFIX "!y[!gZombie Escape!y] "

// Print Color Chat message, This stock Supports ML
stock ze_colored_print(const target, const message[], any:...)
{
	static buffer[512], msg_SayText = 0
	if( !msg_SayText ) msg_SayText = get_user_msgid("SayText") 
	
	// Send to everyone
	if (!target)
	{
		static player, maxplayers, argscount
		maxplayers = get_member_game(m_nMaxPlayers)
		argscount = numargs()
		
		for (player = 1; player <= maxplayers; player++)
		{
			// Not connected
			if (!is_user_connected(player))
				continue;
			
			// Remember changed arguments
			static arg_index, changed_args[20], changedcount // [20] = max LANG_PLAYER occurencies	
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (arg_index = 2; arg_index < argscount; arg_index++)
			{
				if (getarg(arg_index) == LANG_PLAYER && arg_index + 1 < argscount)
				{
					// Check if next param string is a registered language translation
					static lang_key[64], arg_subindex
					arg_subindex = 0
					while ((lang_key[arg_subindex] = getarg(arg_index + 1, arg_subindex++))) { /* keep looping */ }
					if (GetLangTransKey(lang_key) != TransKey_Bad)
					{
						setarg(arg_index, 0, player)
						changed_args[changedcount++] = arg_index
						arg_index++ // skip next argument since we know it's a translation key
					}
				}
			}
			
			// Format message for player (+add ZE prefix)
			vformat(buffer, charsmax(buffer), message, 3)
			format(buffer, charsmax(buffer), "%s%s", ZE_PREFIX, buffer)
			
			replace_all(buffer, charsmax(buffer), "!g", "^x04"); // Green Color  
			replace_all(buffer, charsmax(buffer), "!y", "^x01"); // Yellow Color  
			replace_all(buffer, charsmax(buffer), "!t", "^x03"); // Team Color 
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, msg_SayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (arg_index = 0; arg_index < changedcount; arg_index++)
				setarg(changed_args[arg_index], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		// Format message for player (+add ZE prefix)
		vformat(buffer, charsmax(buffer), message, 3)
		format(buffer, charsmax(buffer), "%s%s", ZE_PREFIX, buffer)
		
		replace_all(buffer, charsmax(buffer), "!g", "^x04"); // Green Color  
		replace_all(buffer, charsmax(buffer), "!y", "^x01"); // Yellow Color  
		replace_all(buffer, charsmax(buffer), "!t", "^x03"); // Team Color 
			
		// Send it
		message_begin(MSG_ONE, msg_SayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

// Return number of alive players from a team
stock GetAlivePlayersNum(CsTeams:iTeam)
{
	new iTAliveNum
	for(new i = 1; i <= get_member_game(m_nMaxPlayers) ; i++)
	{
		if (!is_user_connected(i))
			continue
		
		if(is_user_alive(i) && get_member(i, m_iTeam) == iTeam)
			iTAliveNum++
	}
	return iTAliveNum
}

// Return number of connected players from a team
stock GetTeamPlayersNum(CsTeams:iTeam)
{
	new iTAliveNum
	for(new i = 1; i <= get_member_game(m_nMaxPlayers) ; i++)
	{
		if (!is_user_connected(i))
			continue
		
		if(is_user_connected(i) && get_member(i, m_iTeam) == iTeam)
			iTAliveNum++
	}
	return iTAliveNum
}

// Return number of non-alive players from a team
stock GetDeadPlayersNum(CsTeams:iTeam)
{
	new iTAliveNum
	for(new i = 1; i <= get_member_game(m_nMaxPlayers) ; i++)
	{
		if (!is_user_connected(i))
			continue
		
		if(!is_user_alive(i) && get_member(i, m_iTeam) == iTeam)
			iTAliveNum++
	}
	return iTAliveNum
}

// Return number of all alive players
stock GetAllAlivePlayersNum()
{
	new iAliveAll
	for(new i = 1; i <= get_member_game(m_nMaxPlayers) ; i++)
	{
		if(is_user_alive(i))
			iAliveAll++
	}
	return iAliveAll
}

// Return number of all connected players
stock GetAllPlayersNum()
{
	new iAll
	for(new i = 1; i <= get_member_game(m_nMaxPlayers) ; i++)
	{
		if(is_user_connected(i))
			iAll++
	}
	return iAll
}

// Return Number of required zombies
stock RequiredZombies()
{
	switch(GetAllAlivePlayersNum())
	{
		case 2..5: return 1
		case 6..15: return 2
		case 16..25: return 3
		case 26..32: return 4
	}
	return 0
}

// Choose Random Target
stock GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= get_member_game(m_nMaxPlayers); id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id
	}
	return -1
}

// Set Player Map Light Style
stock Set_MapLightStyle(iIndex, const szMapLightStyle[])
{
	message_begin(MSG_ONE, SVC_LIGHTSTYLE, {0, 0, 0}, iIndex)
	write_byte(0)
	write_string(szMapLightStyle)
	message_end()
}

// Set Player Nightvision
stock Set_NightVision(iIndex, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0, 0, 0}, iIndex)
	write_short(iDuration)
	write_short(iHoldTime)
	write_short(iFlags)
	write_byte(iRed)
	write_byte(iGreen)
	write_byte(iBlue)
	write_byte(iAlpha)
	message_end()
}

// Set Zombie Knockback
stock Set_Knockback(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	get_entvar(ent, var_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	new Float:fl_Time = distance_f / speed
	
	if (type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	}
	else if (type == 2)
	{
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}
	
	set_entvar(ent, var_velocity, fl_Velocity)
}

// Update Player Frags and Deaths
stock UpdateFrags(iAttacker, iVictim, iFrags, iDeaths, iScoreboard)
{
	// Set attacker frags
	set_entvar(iAttacker, var_frags, float(pev(iAttacker, pev_frags) + iFrags))
	
	// Set victim deaths
	set_member(iVictim, m_iDeaths, get_member(iVictim, m_iDeaths) + iDeaths)
	
	// Update scoreboard with attacker and victim info
	if (iScoreboard)
	{
		message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
		write_byte(iAttacker) // id
		write_short(floatround(get_entvar(iAttacker, var_frags))) // frags
		write_short(get_member(iAttacker, m_iDeaths)) // deaths
		write_short(0) // class?
		write_short(get_member(iAttacker, m_iTeam)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
		write_byte(iVictim) // id
		write_short(floatround(get_entvar(iVictim, var_frags))) // frags
		write_short(get_member(iVictim, m_iDeaths)) // deaths
		write_short(0) // class?
		write_short(get_member(iVictim, m_iTeam)) // team
		message_end()
	}
}

// Send Death Message
stock SendDeathMsg(iAttacker, iVictim)
{
	message_begin(MSG_ALL, get_user_msgid("DeathMsg"), {0, 0, 0}, 0)
	write_byte(iAttacker) // killer
	write_byte(iVictim) // victim
	write_byte(1) // headshot flag
	write_string("infection") // killer's weapon
	message_end()
}

// Show infected icon
stock InfectionIcon(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), _, id)
	write_byte(0) // damage save
	write_byte(0) // damage take
	write_long(DMG_NERVEGAS) // damage type - DMG_RADIATION
	write_coord(0) // x
	write_coord(0) // y
	write_coord(0) // z
	message_end()
}

// Fix Dead Attribute
stock FixDeadAttrib(iIndex)
{
	message_begin(MSG_ALL, get_user_msgid("ScoreAttrib"), {0, 0, 0}, 0)
	write_byte(iIndex) // id
	write_byte(0) // attrib (0 = Nothing || 1 = Dead)
	message_end()
}

// Set an entity's key value
stock Set_KeyValue(entity, const key[], const value[], const classname[])
{
	set_kvd(0, KV_ClassName, classname)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	dllfunc(DLLFunc_KeyValue, entity, 0)
}

// Set Custom Sky
stock Precache_Sky(const szSkyName[])
{
	new bool:bFound
	static szTgaFile[35]
	static szSuffix[6][3] = {"up", "dn", "ft", "bk", "lf", "rt"}

	for(new i = 0; i < 6; ++i)
	{
		formatex(szTgaFile, 34, "gfx/env/%s%s.tga", szSkyName, szSuffix[i])
		
		if(file_exists(szTgaFile))
		{
			precache_generic(szTgaFile)
			bFound = true
		}
		else
		{
			log_amx("Cannot locate file '%s'", szTgaFile)
			bFound = false
			break
		}
	}
	
	if(bFound == true)
	{
		set_cvar_string("sv_skyname", szSkyName)
	}
}

// Add Commas
stock AddCommas(iNum , szOutput[] , iLen)  
{  
    new szTmp[15] , iOutputPos , iNumPos , iNumLen 
      
    if (iNum < 0)  
    {  
        szOutput[iOutputPos++] = '-' 
        iNum = abs(iNum)
    }  
      
    iNumLen = num_to_str(iNum , szTmp , charsmax(szTmp))

    if (iNumLen <= 3)  
    {  
        iOutputPos += copy(szOutput[iOutputPos] , iLen , szTmp)
    }  
    else  
    {  
        while ((iNumPos < iNumLen) && (iOutputPos < iLen))   
        {  
            szOutput[iOutputPos++] = szTmp[iNumPos++]
          
            if((iNumLen - iNumPos) && !((iNumLen - iNumPos) % 3))   
                szOutput[iOutputPos++] = ','
        }
        szOutput[iOutputPos] = EOS 
    }  
    return iOutputPos
}

// Play Sound
stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
	{
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	}
	else
	{
		client_cmd(id, "spk ^"%s^"", sound)
	}
}

// Stop Sound
stock StopSound()
{
	for(new id = 1; id <= get_member_game(m_nMaxPlayers); id++)
	{
		client_cmd(id, "mp3 stop")
		client_cmd(id, "spk stop")
		client_cmd(id, "stopsound")
	}
}

// Set Glow
stock Set_Rendering(iEntity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_entvar(iEntity, var_renderfx, fx)
	set_entvar(iEntity, var_rendercolor, color)
	set_entvar(iEntity, var_rendermode, render)
	set_entvar(iEntity, var_renderamt, float(amount))
}

// Multiply Vector by Scalar
stock VecMulScalar(const Float:vec[], Float:scalar, Float:out[])
{
	out[0] = vec[0] * scalar
	out[1] = vec[1] * scalar
	out[2] = vec[2] * scalar
}

// Show Given BP Ammo
stock Show_Given_BPAmmo(id, iAmmoType, iAmmount)
{
	if (iAmmount <= 0)
		return
	
	message_begin(MSG_ONE, get_user_msgid("AmmoPickup"), {0,0,0}, id)
	write_byte(iAmmoType)
	write_byte(iAmmount)
	message_end()
}

// Log MySQL Errors
stock SQL_IsFail(iFailState, iError, szError[], const szLogFile[])
{
	if (iFailState == TQUERY_CONNECT_FAILED)
	{
		log_to_file(szLogFile, "[MySQL] Could not connect to SQL database: %s", szError)
		return true
	}
	else if (iFailState == TQUERY_QUERY_FAILED)
	{
		log_to_file(szLogFile, "[MySQL] Query failed: %s", szError)
		return true
	}
	else if (iError)
	{
		log_to_file(szLogFile, "[MySQL] Error on query: %s", szError)
		return true
	}
	
	return false
}