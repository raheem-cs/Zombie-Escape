#include <zombie_escape> // Used only amxmodx and ReAPI to do this

new const szWeaponsEnt[][]=
{
	"weapon_p228",
	"weapon_scout",
	"weapon_xm1014",
	"weapon_mac10",
	"weapon_aug",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_p90"
}

public plugin_init()
{
	register_plugin("[ZE] Unlimited Clip", "1.0", "Raheem")
	set_task(5.0, "CheckAmmo", _, _, _, "b")
}

public CheckAmmo()
{
	for (new i = 1; i <= 32; i++)
	{
		if (!is_user_alive(i))
			continue
		
		for (new iIndex = 1; iIndex <= charsmax(szWeaponsEnt); iIndex++)
		{
			new iWeaponID; iWeaponID = rg_find_weapon_bpack_by_name(i, szWeaponsEnt[iIndex])
			set_member(iWeaponID, m_Weapon_iClip, 999999)
		}
	}
}