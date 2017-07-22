/*================================================================================
	
	------------------------------------
	-*- [AMXX] External Settings API -*-
	------------------------------------
	
	- API to load/save settings in a Key+Value format that resembles
	   Windows INI files (http://en.wikipedia.org/wiki/INI_file)
	
	- Right now this is only meant to be used during mapchange
	- Code is not really optimized
	- Loading/saving takes some time, but it works!!
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>

public plugin_init()
{
	register_plugin("[AMXX] External Settings API", "0.1", "WiLS")
}

public plugin_natives()
{
	register_library("amx_settings_api")
	register_native("amx_load_setting_string_arr", "native_load_setting_string_arr")
	register_native("amx_save_setting_string_arr", "native_save_setting_string_arr")
	register_native("amx_load_setting_int_arr", "native_load_setting_int_arr")
	register_native("amx_save_setting_int_arr", "native_save_setting_int_arr")
	register_native("amx_load_setting_float_arr", "native_load_setting_float_arr")
	register_native("amx_save_setting_float_arr", "native_save_setting_float_arr")
	register_native("amx_load_setting_string", "native_load_setting_string")
	register_native("amx_save_setting_string", "native_save_setting_string")
	register_native("amx_load_setting_int", "native_load_setting_int")
	register_native("amx_save_setting_int", "native_save_setting_int")
	register_native("amx_load_setting_float", "native_load_setting_float")
	register_native("amx_save_setting_float", "native_save_setting_float")
}

public native_load_setting_string_arr(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty section/key")
		return false;
	}
	
	new Array:array_handle = Array:get_param(4)
	
	if (array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Array not initialized")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
		return false;
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], current_value[128]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			// Parse values
			while (values[0] != 0 && strtok(values, current_value, charsmax(current_value), values, charsmax(values), ','))
			{
				// Trim spaces
				trim(current_value)
				trim(values)
				
				// Add to array
				ArrayPushString(array_handle, current_value)
			}
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

public native_save_setting_string_arr(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty section/key")
		return false;
	}
	
	new Array:array_handle = Array:get_param(4)
	
	if (array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Array not initialized")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
	{
		// Create new file
		write_file(path, "", -1)
	}
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64], line = -1
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		// We're done with reading
		fclose(file)
		
		// Format and add section
		formatex(linedata, charsmax(linedata), "^n[%s]", setting_section)
		write_file(path, linedata, -1)
		
		// Format key
		formatex(linedata, charsmax(linedata), "%s =", setting_key)
		
		// Format values
		new index, current_value[128]
		
		// First value, append to linedata with no commas
		ArrayGetString(array_handle, index, current_value, charsmax(current_value))
		format(linedata, charsmax(linedata), "%s %s", linedata, current_value)
		
		// Successive values, append to linedata with commas (start on index = 1 to skip first value)
		for (index = 1; index < ArraySize(array_handle); index++)
		{
			ArrayGetString(array_handle, index, current_value, charsmax(current_value))
			format(linedata, charsmax(linedata), "%s , %s", linedata, current_value)
		}
		
		// Add key + values
		write_file(path, linedata, -1)
		
		return true;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], txtlen
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
			break;
	}
	
	// We're done with reading
	fclose(file)
	
	// Key not found
	if (!equal(key, setting_key))
	{
		// Section ended?
		if (linedata[0] == '[')
			line -= 1
		
		// Read linedata
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Seek to end position of section (last key)
		while (!linedata[0] || linedata[0] == ';')
		{
			// Move to previous line and read linedata
			read_file(path, --line, linedata, charsmax(linedata), txtlen)
			replace(linedata, charsmax(linedata), "^n", "")
		}
		
		// Don't overwrite an already existing line
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		format(linedata, charsmax(linedata), "%s^n", linedata)
		write_file(path, linedata, line)
		line++
	}
	
	// Format key
	formatex(linedata, charsmax(linedata), "%s =", setting_key)
	
	// Format values
	new index, current_value[128]
	
	// First value, append to linedata with no commas
	ArrayGetString(array_handle, index, current_value, charsmax(current_value))
	format(linedata, charsmax(linedata), "%s %s", linedata, current_value)
	
	// Successive values, append to linedata with commas (start on index = 1 to skip first value)
	for (index = 1; index < ArraySize(array_handle); index++)
	{
		ArrayGetString(array_handle, index, current_value, charsmax(current_value))
		format(linedata, charsmax(linedata), "%s , %s", linedata, current_value)
	}
	
	// Add key + values
	write_file(path, linedata, line)
	
	return true;
}

public native_load_setting_int_arr(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty section/key")
		return false;
	}
	
	new Array:array_handle = Array:get_param(4)
	
	if (array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Array not initialized")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
		return false;
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], current_value[128]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			// Parse values
			while (values[0] != 0 && strtok(values, current_value, charsmax(current_value), values, charsmax(values), ','))
			{
				// Trim spaces
				trim(current_value)
				trim(values)
				
				// Add to array
				ArrayPushCell(array_handle, str_to_num(current_value))
			}
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

public native_save_setting_int_arr(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty section/key")
		return false;
	}
	
	new Array:array_handle = Array:get_param(4)
	
	if (array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Array not initialized")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
	{
		// Create new file
		write_file(path, "", -1)
	}
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64], line = -1
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		// We're done with reading
		fclose(file)
		
		// Format and add section
		formatex(linedata, charsmax(linedata), "^n[%s]", setting_section)
		write_file(path, linedata, -1)
		
		// Format key
		formatex(linedata, charsmax(linedata), "%s =", setting_key)
		
		// Format values
		new index
		
		// First value, append to linedata with no commas
		format(linedata, charsmax(linedata), "%s %d", linedata, ArrayGetCell(array_handle, index))
		
		// Successive values, append to linedata with commas (start on index = 1 to skip first value)
		for (index = 1; index < ArraySize(array_handle); index++)
			format(linedata, charsmax(linedata), "%s , %d", linedata, ArrayGetCell(array_handle, index))
		
		// Add key + values
		write_file(path, linedata, -1)
		
		return true;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], txtlen
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
			break;
	}
	
	// We're done with reading
	fclose(file)
	
	// Key not found
	if (!equal(key, setting_key))
	{
		// Section ended?
		if (linedata[0] == '[')
			line -= 1
		
		// Read linedata
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Seek to end position of section (last key)
		while (!linedata[0] || linedata[0] == ';')
		{
			// Move to previous line and read linedata
			read_file(path, --line, linedata, charsmax(linedata), txtlen)
			replace(linedata, charsmax(linedata), "^n", "")
		}
		
		// Don't overwrite an already existing line
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		format(linedata, charsmax(linedata), "%s^n", linedata)
		write_file(path, linedata, line)
		line++
	}
	
	// Format key
	formatex(linedata, charsmax(linedata), "%s =", setting_key)
	
	// Format values
	new index
	
	// First value, append to linedata with no commas
	format(linedata, charsmax(linedata), "%s %d", linedata, ArrayGetCell(array_handle, index))
	
	// Successive values, append to linedata with commas (start on index = 1 to skip first value)
	for (index = 1; index < ArraySize(array_handle); index++)
		format(linedata, charsmax(linedata), "%s , %d", linedata, ArrayGetCell(array_handle, index))
	
	// Add key + values
	write_file(path, linedata, line)
	
	return true;
}

public native_load_setting_float_arr(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty section/key")
		return false;
	}
	
	new Array:array_handle = Array:get_param(4)
	
	if (array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Array not initialized")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
		return false;
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], current_value[128]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			// Parse values
			while (values[0] != 0 && strtok(values, current_value, charsmax(current_value), values, charsmax(values), ','))
			{
				// Trim spaces
				trim(current_value)
				trim(values)
				
				// Add to array
				ArrayPushCell(array_handle, str_to_float(current_value))
			}
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

public native_save_setting_float_arr(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty section/key")
		return false;
	}
	
	new Array:array_handle = Array:get_param(4)
	
	if (array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Array not initialized")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
	{
		// Create new file
		write_file(path, "", -1)
	}
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64], line = -1
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		// We're done with reading
		fclose(file)
		
		// Format and add section
		formatex(linedata, charsmax(linedata), "^n[%s]", setting_section)
		write_file(path, linedata, -1)
		
		// Format key
		formatex(linedata, charsmax(linedata), "%s =", setting_key)
		
		// Format values
		new index
		
		// First value, append to linedata with no commas
		format(linedata, charsmax(linedata), "%s %.2f", linedata, Float:ArrayGetCell(array_handle, index))
		
		// Successive values, append to linedata with commas (start on index = 1 to skip first value)
		for (index = 1; index < ArraySize(array_handle); index++)
			format(linedata, charsmax(linedata), "%s , %.2f", linedata, Float:ArrayGetCell(array_handle, index))
		
		// Add key + values
		write_file(path, linedata, -1)
		
		return true;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], txtlen
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
			break;
	}
	
	// We're done with reading
	fclose(file)
	
	// Key not found
	if (!equal(key, setting_key))
	{
		// Section ended?
		if (linedata[0] == '[')
			line -= 1
		
		// Read linedata
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Seek to end position of section (last key)
		while (!linedata[0] || linedata[0] == ';')
		{
			// Move to previous line and read linedata
			read_file(path, --line, linedata, charsmax(linedata), txtlen)
			replace(linedata, charsmax(linedata), "^n", "")
		}
		
		// Don't overwrite an already existing line
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		format(linedata, charsmax(linedata), "%s^n", linedata)
		write_file(path, linedata, line)
		line++
	}
	
	// Format key
	formatex(linedata, charsmax(linedata), "%s =", setting_key)
	
	// Format values
	new index
	
	// First value, append to linedata with no commas
	format(linedata, charsmax(linedata), "%s %.2f", linedata, Float:ArrayGetCell(array_handle, index))
	
	// Successive values, append to linedata with commas (start on index = 1 to skip first value)
	for (index = 1; index < ArraySize(array_handle); index++)
		format(linedata, charsmax(linedata), "%s , %.2f", linedata, Float:ArrayGetCell(array_handle, index))
	
	// Add key + values
	write_file(path, linedata, line)
	
	return true;
}

public native_load_setting_string(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty section/key")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
		return false;
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], current_value[128]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and value
		strtok(linedata, key, charsmax(key), current_value, charsmax(current_value), '=')
		
		// Trim spaces
		trim(key)
		trim(current_value)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			// Return string by reference
			new len = get_param(5)
			set_string(4, current_value, len)
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

public native_save_setting_string(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty section/key")
		return false;
	}
	
	// Get string
	new setting_string[128]
	get_string(4, setting_string, charsmax(setting_string))
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
	{
		// Create new file
		write_file(path, "", -1)
	}
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64], line = -1
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		new txtlen
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		// We're done with reading
		fclose(file)
		
		// Format and add section
		formatex(linedata, charsmax(linedata), "^n[%s]", setting_section)
		write_file(path, linedata, -1)
		
		// Format key
		formatex(linedata, charsmax(linedata), "%s =", setting_key)
		
		// Format value
		format(linedata, charsmax(linedata), "%s %s", linedata, setting_string)
		
		// Add key + values
		write_file(path, linedata, -1)
		
		return true;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], txtlen
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
			break;
	}
	
	// We're done with reading
	fclose(file)
	
	// Key not found
	if (!equal(key, setting_key))
	{
		// Section ended?
		if (linedata[0] == '[')
			line -= 1
		
		// Read linedata
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Seek to end position of section (last key)
		while (!linedata[0] || linedata[0] == ';')
		{
			// Move to previous line and read linedata
			read_file(path, --line, linedata, charsmax(linedata), txtlen)
			replace(linedata, charsmax(linedata), "^n", "")
		}
		
		// Don't overwrite an already existing line
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		format(linedata, charsmax(linedata), "%s^n", linedata)
		write_file(path, linedata, line)
		line++
	}
	
	// Format key
	formatex(linedata, charsmax(linedata), "%s =", setting_key)
	
	// Format value
	format(linedata, charsmax(linedata), "%s %s", linedata, setting_string)
	
	// Add key + values
	write_file(path, linedata, line)
	
	return true;
}

public native_load_setting_int(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty section/key")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
		return false;
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], current_value[32]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and value
		strtok(linedata, key, charsmax(key), current_value, charsmax(current_value), '=')
		
		// Trim spaces
		trim(key)
		trim(current_value)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			// Return int by reference
			set_param_byref(4, str_to_num(current_value))
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

public native_save_setting_int(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty section/key")
		return false;
	}
	
	// Get int
	new integer_value = get_param(4)
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
	{
		// Create new file
		write_file(path, "", -1)
	}
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64], line = -1
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		// We're done with reading
		fclose(file)
		
		// Format and add section
		formatex(linedata, charsmax(linedata), "^n[%s]", setting_section)
		write_file(path, linedata, -1)
		
		// Format key
		formatex(linedata, charsmax(linedata), "%s =", setting_key)
		
		// Format value
		format(linedata, charsmax(linedata), "%s %d", linedata, integer_value)
		
		// Add key + values
		write_file(path, linedata, -1)
		
		return true;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], txtlen
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
			break;
	}
	
	// We're done with reading
	fclose(file)
	
	// Key not found
	if (!equal(key, setting_key))
	{
		// Section ended?
		if (linedata[0] == '[')
			line -= 1
		
		// Read linedata
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Seek to end position of section (last key)
		while (!linedata[0] || linedata[0] == ';')
		{
			// Move to previous line and read linedata
			read_file(path, --line, linedata, charsmax(linedata), txtlen)
			replace(linedata, charsmax(linedata), "^n", "")
		}
		
		// Don't overwrite an already existing line
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		format(linedata, charsmax(linedata), "%s^n", linedata)
		write_file(path, linedata, line)
		line++
	}
	
	// Format key
	formatex(linedata, charsmax(linedata), "%s =", setting_key)
	
	// Format value
	format(linedata, charsmax(linedata), "%s %d", linedata, integer_value)
	
	// Add key + values
	write_file(path, linedata, line)
	
	return true;
}

public native_load_setting_float(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty section/key")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
		return false;
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], current_value[32]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and value
		strtok(linedata, key, charsmax(key), current_value, charsmax(current_value), '=')
		
		// Trim spaces
		trim(key)
		trim(current_value)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			// Return float by reference
			set_float_byref(4, str_to_float(current_value))
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

public native_save_setting_float(plugin_id, num_params)
{
	new filename[32]
	get_string(1, filename, charsmax(filename))
	
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty filename")
		return false;
	}
	
	new setting_section[64], setting_key[64]
	get_string(2, setting_section, charsmax(setting_section))
	get_string(3, setting_key, charsmax(setting_key))
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't save settings: empty section/key")
		return false;
	}
	
	// Get int
	new Float:float_value = get_param_f(4)
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
	{
		// Create new file
		write_file(path, "", -1)
	}
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64], line = -1
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		// We're done with reading
		fclose(file)
		
		// Format and add section
		formatex(linedata, charsmax(linedata), "^n[%s]", setting_section)
		write_file(path, linedata, -1)
		
		// Format key
		formatex(linedata, charsmax(linedata), "%s =", setting_key)
		
		// Format value
		format(linedata, charsmax(linedata), "%s %.2f", linedata, float_value)
		
		// Add key + values
		write_file(path, linedata, -1)
		
		return true;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], txtlen
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Increase line counter
		line++
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
			break;
	}
	
	// We're done with reading
	fclose(file)
	
	// Key not found
	if (!equal(key, setting_key))
	{
		// Section ended?
		if (linedata[0] == '[')
			line -= 1
		
		// Read linedata
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Seek to end position of section (last key)
		while (!linedata[0] || linedata[0] == ';')
		{
			// Move to previous line and read linedata
			read_file(path, --line, linedata, charsmax(linedata), txtlen)
			replace(linedata, charsmax(linedata), "^n", "")
		}
		
		// Don't overwrite an already existing line
		read_file(path, line, linedata, charsmax(linedata), txtlen)
		format(linedata, charsmax(linedata), "%s^n", linedata)
		write_file(path, linedata, line)
		line++
	}
	
	// Format key
	formatex(linedata, charsmax(linedata), "%s =", setting_key)
	
	// Format value
	format(linedata, charsmax(linedata), "%s %.2f", linedata, float_value)
	
	// Add key + values
	write_file(path, linedata, line)
	
	return true;
}
