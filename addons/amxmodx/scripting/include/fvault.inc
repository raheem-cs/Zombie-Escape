#if defined _file_vault_included
	#endinput
#endif

#define _file_vault_included

/**
 * FVault was created by Exolent on 8/24/08
 * This vault system uses actual files and no modules
 * It is very flexible and has many features
 * Visit this page for more information: http://forums.alliedmods.net/showthread.php?t=76453
 */

#include <amxmodx>

stock const _vault_dir[] = "addons/amxmodx/data/file_vault";
stock const _temp_vault[] = "fvault_temp.txt";

/** 
 * Retrieves a key name specified by its number
 * 
 * @param vaultname	Vault name to look in
 * @param keynum	Key number within the vault to find key name
 * @param key		String which key name will be copied to
 * @param len		Length of key name
 * @return		Returns 1 on success, 0 on failue.
 */
stock fvault_get_keyname(const vaultname[], const keynum, key[], len)
{
	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	if( !file_exists(filename) )
	{
		return 0;
	}
	
	new vault = fopen(filename, "rt");
	
	new _data[64], _other[3];
	
	new line = -1;
	
	while( !feof(vault) )
	{
		fgets(vault, _data, sizeof(_data) - 1);
		
		if( ++line == keynum )
		{
			parse(_data, key, len, _other, sizeof(_other) - 1);
			
			fclose(vault);
			
			return 1;
		}
	}
	
	fclose(vault);
	
	return 0;
}

/** 
 * Retrieves a key number specified by its name
 * 
 * @param vaultname	Vault name to look in
 * @param key		Key name to search for
 * @return		Returns key number on success, -1 on failure
 */
stock fvault_get_keynum(const vaultname[], const key[])
{
	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	if( !file_exists(filename) )
	{
		return -1;
	}
	
	new vault = fopen(filename, "rt");
	
	new _data[70], _key[64], _other[3];
	
	new line = -1;
	
	while( !feof(vault) )
	{
		fgets(vault, _data, sizeof(_data) - 1);
		parse(_data, _key, sizeof(_key) - 1, _other, sizeof(_other) - 1);
		
		line++;
		
		if( equal(_key, key) )
		{
			fclose(vault);
			
			return line;
		}
	}
	
	fclose(vault);
	
	return -1;
}

/** 
 * Retrieves data specified by a key
 * 
 * @param vaultname	Vault name to look in
 * @param key		Key name to look for the data
 * @param data		String which data will be copied to
 * @param len		Length of data
 * @param timestamp	The unix time of when the data was last set ( -1 if permanent data, 0 if old fvault version ) ( optional param )
 * @return		Returns 1 on success, 0 on failue.
 */
stock fvault_get_data(const vaultname[], const key[], data[], len, &timestamp=0)
{
	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	if( !file_exists(filename) )
	{
		return 0;
	}
	
	new vault = fopen(filename, "rt");
	
	new _data[512], _key[64], _time[32];
	
	while( !feof(vault) )
	{
		fgets(vault, _data, sizeof(_data) - 1);
		parse(_data, _key, sizeof(_key) - 1);
		
		if( equal(_key, key) )
		{
			new _len = strlen(_key) + 4; // + 2 = quotes on key, + 1 = space, + 1 = first quote
			for( new i = copy(data, len, _data[_len]) - 1; i > 0; i-- )
			{
				if( data[i] == '"' ) break;
				
				if( data[i] == ' '
				&& data[i - 1] == '"' )
				{
					data[i - 1] = '^0';
					
					copy(_time, sizeof(_time) - 1, data[i + 1]);
					timestamp = str_to_num(_time);
					break;
				}
			}
			
			fclose(vault);
			
			return 1;
		}
	}
	
	fclose(vault);
	
	copy(data, len, "");
	
	return 0;
}

/** 
 * Sets data of a key with current timestamp
 * 
 * @param vaultname	Vault name to look in
 * @param key		Key name to which data will be set
 * @param data		Data to set to key
 * @return		Does not return a value.
 */
stock fvault_set_data(const vaultname[], const key[], const data[])
{
	_fvault_set_data(vaultname, key, data, get_systime());
}

/** 
 * Sets data of a key permanently (can't be removed with fvault_prune)
 * 
 * @param vaultname	Vault name to look in
 * @param key		Key name to which data will be set
 * @param data		Data to set to key
 * @return		Does not return a value.
 */
stock fvault_pset_data(const vaultname[], const key[], const data[])
{
	_fvault_set_data(vaultname, key, data, -1);
}

stock _fvault_set_data(const vaultname[], const key[], const data[], const timestamp)
{
	new file = fopen(_temp_vault, "wt");
	
	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	new vault = fopen(filename, "rt");
	
	new _data[512], _key[64], _other[3];
	
	new bool:replaced = false;
	
	while( !feof(vault) )
	{
		fgets(vault, _data, sizeof(_data) - 1);
		parse(_data, _key, sizeof(_key) - 1, _other, sizeof(_other) - 1);
		
		if( equal(_key, key) && !replaced )
		{
			fprintf(file, "^"%s^" ^"%s^" %i^n", key, data, timestamp);
			
			replaced = true;
		}
		else
		{
			fputs(file, _data);
		}
	}
	
	fclose(file);
	fclose(vault);
	
	if( !replaced )
	{
		file = fopen(filename, "a+");
		fprintf(file, "^"%s^" ^"%s^" %i^n", key, data, timestamp);
		fclose(file);
		
		delete_file(_temp_vault);
	}
	else
	{
		delete_file(filename);
		
		while( !rename_file(_temp_vault, filename, 1) ) { }
	}
}

/** 
 * Removes a key from a vault
 * 
 * @param vaultname	Vault name to look in
 * @param key		Key to remove
 * @return		No return
 */
stock fvault_remove_key(const vaultname[], const key[])
{
	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	if( !file_exists(filename) )
	{
		return;
	}
	
	new file = fopen(_temp_vault, "wt");
	
	new vault = fopen(filename, "rt");
	
	new _data[512], _key[64], _other[3];
	new bool:found_key;
	
	while( !feof(vault) )
	{
		fgets(vault, _data, sizeof(_data) - 1);
		parse(_data, _key, sizeof(_key) - 1, _other, sizeof(_other) - 1);
		
		if( equal(_key, key) )
		{
			found_key = true;
			continue;
		}
		
		fputs(file, _data);
	}
	
	fclose(file);
	fclose(vault);
	
	if( found_key )
	{
		delete_file(filename);
		
		while( !rename_file(_temp_vault, filename, 1) ) { }
	}
	else
	{
		delete_file(_temp_vault);
	}
}

/**
 * Prunes the vault for keys that are within the given timestamps
 * 
 * @param vaultname	Vault name to look in
 * @param start		If timestamp is after this Unix Time (set -1 to prune from very start)
 * @param end		If timestamp is before this Unix Time (set -1 to prune to most time)
 * @return		Returns number of keys pruned
 */
stock fvault_prune(const vaultname[], const start=-1, const end=-1)
{
	if( start == -1 && end == -1 )
	{
		new keys = fvault_size(vaultname);
		if( keys )
		{
			fvault_clear(vaultname);
		}
		
		return keys;
	}
	
	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	if( !file_exists(filename) )
	{
		return 0;
	}
	
	new file = fopen(_temp_vault, "wt");
	new vault = fopen(filename, "rt");
	
	new keys;
	
	new data[512], i, _time[32], timestamp;
	while( !feof(vault) )
	{
		fgets(vault, data, sizeof(data) - 1);
		
		if( data[0] )
		{
			_time[0] = 0;
			
			for( i = strlen(data) - 1; i >= 0; i-- )
			{
				if( data[i] == '"' ) break;
				
				if( data[i] == ' ' )
				{
					copy(_time, sizeof(_time) - 1, data[i + 1]);
					break;
				}
			}
			
			timestamp = str_to_num(_time);
			if( timestamp != -1 )
			{
				if( start == -1 && timestamp <= end
				|| end == -1 && timestamp >= start
				|| start <= timestamp <= end )
				{
					keys++;
					continue;
				}
			}
		}
		
		fputs(file, data);
	}
	
	fclose(file);
	fclose(vault);
	
	if( keys )
	{
		delete_file(filename);
		
		while( !rename_file(_temp_vault, filename, 1) ) { }
	}
	else
	{
		delete_file(_temp_vault);
	}
	
	return keys;
}

/**
 * Updates the timestamp on a key located within the vault
 * 
 * @param vaultname	Vault name to look in
 * @param key		Key to update timestamp (if it doesn't exist, a blank value will be set)
 * @param timestamp	Unix Time to set for the key (-1 for current time)
 * @return		Returns 2 on new entry, 1 on success, 0 on failure for the key having a permanent timestamp
 */
stock fvault_touch(const vaultname[], const key[], const timestamp=-1)
{
	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	static new_time;
	if( (new_time = timestamp) == -1 )
	{
		new_time = get_systime();
	}
	
	if( !file_exists(filename) )
	{
		new vault = fopen(filename, "wt");
		fprintf(vault, "^"%s^" ^"^" %i^n", key, new_time);
		fclose(vault);
		return 2;
	}
	
	new file = fopen(_temp_vault, "wt");
	new vault = fopen(filename, "rt");
	
	new bool:updated;
	
	new data[512], _key[64], len, i, _time[32];
	while( !feof(vault) )
	{
		fgets(vault, data, sizeof(data) - 1);
		parse(data, _key, sizeof(_key) - 1);
		
		if( equal(_key, key) )
		{
			_time[0] = 0;
			
			for( i = strlen(data) - 1; i >= 0; i-- )
			{
				if( data[i] == '"' ) break;
				
				if( data[i] == ' ' )
				{
					data[i] = '^0';
					copy(_time, sizeof(_time) - 1, data[i + 1]);
					break;
				}
			}
			
			if( str_to_num(_time) == -1 )
			{
				fclose(file);
				fclose(vault);
				
				delete_file(_temp_vault);
				
				return 0;
			}
			
			fprintf(file, "%s %i^n", data, new_time);
			
			updated = true;
		}
		else
		{
			fputs(file, data);
		}
	}
	
	if( !updated )
	{
		fprintf(file, "^"%s^" ^"^" %i^n", key, new_time);
	}
	
	fclose(file);
	fclose(vault);
	
	delete_file(filename);
	
	while( !rename_file(_temp_vault, filename, 1) ) { }
	
	return (_:(!updated) + 1);
}

/** 
 * Retrieves total keys located within the vault
 * 
 * @param vaultname	Vault name to look in
 * @return		Returns amount of keys in vault
 */
stock fvault_size(const vaultname[])
{
	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	return file_exists(filename) ? file_size(filename, 1) - 1 : 0;
}

/** 
 * Clears all key entries for a vault
 * 
 * @param vaultname	Vault name to erase
 * @return		No return
 */
stock fvault_clear(const vaultname[])
{
 	new filename[128];
	_FormatVaultName(vaultname, filename, sizeof(filename) - 1);
	
	fclose(fopen(filename, "wt"));
}

/** 
 * Retrieves a vault name specified by its number
 * 
 * @param vaultnum	Vault number to find the vault name
 * @param vaultname	String which vault name will be copied to
 * @param len		Length of vault name
 * @return		Returns 1 on success, 0 on failue.
 */
stock fvault_get_vaultname(const vaultnum, vaultname[], len)
{
	if( !dir_exists(_vault_dir) )
	{
		mkdir(_vault_dir);
		return 0;
	}
	
	new filenum;
	
	new dir = open_dir(_vault_dir, vaultname, len);
	
	do
	{
		if( equal(vaultname, ".") || equal(vaultname, "..") )
		{
			continue;
		}
		
		if( filenum == vaultnum )
		{
			close_dir(dir);
			
			replace(vaultname, len, ".txt", "");
			
			return 1;
		}
		
		++filenum;
	}
	while( next_file(dir, vaultname, len) );
	
	close_dir(dir);
	
	copy(vaultname, len, "");
	
	return 0;
}

/** 
 * Retrieves a vault number specified by its name
 * 
 * @param vaultname	Vault name to find the number
 * @return		Returns vault number on success, -1 on failure
 */
stock fvault_get_vaultnum(const vaultname[])
{
	if( !dir_exists(_vault_dir) )
	{
		mkdir(_vault_dir);
		return -1;
	}
	
	new filename[128], filenum;
	
	new dir = open_dir(_vault_dir, filename, sizeof(filename) - 1);
	
	do
	{
		if( equal(filename, ".") || equal(filename, "..") )
		{
			continue;
		}
		
		replace(filename, sizeof(filename) - 1, ".txt", "");
		
		if( equal(filename, vaultname) )
		{
			close_dir(dir);
			
			return filenum;
		}
		
		++filenum;
	}
	while( next_file(dir, filename, sizeof(filename) - 1) );
	
	close_dir(dir);
	
	copy(vaultname, len, "");
	
	return -1;
}

/** 
 * Retrieves total vaults ever created
 * 
 * @return		Returns amount of vaults
 */
stock fvault_total()
{
	if( !dir_exists(_vault_dir) )
	{
		mkdir(_vault_dir);
		return 0;
	}
	
	new vaultname[128], filename[128];
	new dir = open_dir(_vault_dir, vaultname, sizeof(vaultname) - 1);
	
	new filenum;
	do
	{
		if( equal(vaultname, ".") || equal(vaultname, "..") )
		{
			continue;
		}
		
		formatex(filename, sizeof(filename) - 1, "%s/%s", _vault_dir, vaultname);
		if( file_exists(filename) )
		{
			++filenum;
		}
	}
	while( next_file(dir, vaultname, sizeof(vaultname) - 1) );
	
	close_dir(dir);
	
	return filenum;
}

/**
 * Gets all vault keys, data, and timestamps
 * 
 * @param		vaultname - Vault name to look in
 * @param		keys - cellarray holding all of the keys
 * @param		datas - cellarray holding all of the data values
 * @param		timestamps - cellarray holding all of the timestamps
 * 
 * @return		Returns total number of entries in vault
 * 
 * @note		keys needs to be created like this: ArrayCreate(64)
 * 			datas needs to be created like this: ArrayCreate(512)
 * 			timestamps need to be created like this: ArrayCreate()
 */
stock fvault_load(const vaultname[], Array:keys=Invalid_Array, Array:datas=Invalid_Array, Array:timestamps=Invalid_Array)
{
	new filename[128];
	_FormatVaultName(vaultname, filename, 127);
	
	if( !file_exists(filename) )
	{
		return 0;
	}
	
	new vault = fopen(filename, "rt");
	
	new array_size;
	
	new filedata[1024];
	new key[64], data[512], timestamp[32];
	while( !feof(vault) )
	{
		fgets(vault, filedata, 1023);
		
		if( parse(filedata, key, 63, data, 511, timestamp, 31) < 2 )
		{
			continue;
		}
		
		if( keys != Invalid_Array )
		{
			ArrayPushString(keys, key);
		}
		if( datas != Invalid_Array )
		{
			ArrayPushString(datas, data);
		}
		if( timestamps != Invalid_Array )
		{
			ArrayPushCell(timestamps, str_to_num(timestamp));
		}
		
		array_size++;
	}
	
	fclose(vault);
	
	return array_size;
}
 
stock _FormatVaultName(const vaultname[], filename[], len)
{
	static const invalid_chars[][] =
	{
		"/", "\", "*", ":", "?", "^"", "<", ">", "|"
	};
	
	static tempvault[128], i;
	copy(tempvault, sizeof(tempvault) - 1, vaultname);
	
	for( i = 0; i < sizeof(invalid_chars); i++ )
	{
		replace_all(tempvault, sizeof(tempvault) - 1, invalid_chars[i], "");
	}
	
	if( !dir_exists(_vault_dir) )
	{
		mkdir(_vault_dir);
	}
	
	formatex(filename, len, "%s/%s.txt", _vault_dir, tempvault);
}