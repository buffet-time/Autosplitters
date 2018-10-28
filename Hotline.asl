state("HotlineGL")
{
	int grade :          "HotlineGL.exe", 0x7EC858, 8, 0x5AC, 4, 8;
	int select_index :   "HotlineGL.exe", 0x7EC858, 8, 0x104, 4, 8;
	int menu_state :     "HotlineGL.exe", 0x7EC858, 8, 0x10C, 4, 8;
	int fade :           "HotlineGL.exe", 0x7EC858, 8, 0x11C, 4, 8;
	int showdown_paper : "HotlineGL.exe", 0xBFFCD8, 0x15CC, 8;
	double player_x :    "HotlineGL.exe", 0x9F5DC0, 4, 0, 8, 8, 0x50;
	double bike_climb :  "HotlineGL.exe", 0x9F66F4, 4, 0, 8, 8, 0x98;

	ushort room :        "HotlineGL.exe", 0xBFFC44, 8;
	ushort menu :        "HotlineGL.exe", 0x9F7534;
	ushort lvl_select :  "HotlineGL.exe", 0x9F7660;
	ushort trauma :      "HotlineGL.exe", 0x9F769C;
	ushort showdown :    "HotlineGL.exe", 0x9F7730;
	ushort prankcall :   "HotlineGL.exe", 0x9F7740;
	ushort resolution :  "HotlineGL.exe", 0x9F7774;
}

startup
{
	settings.Add("Grade screen");
	settings.SetToolTip("Grade screen", "Split when the grade appears at the end of a level");
	settings.Add("Showdown");
	settings.SetToolTip("Showdown", "Split when throwing the paper");
	settings.Add("Trauma");
	settings.SetToolTip("Trauma", "Split when exiting the hospital");
	settings.Add("Prank call");
	settings.SetToolTip("Prank call", "Split when getting on the bike");
	settings.Add("Resolution");
	settings.SetToolTip("Resolution", "Split when getting on the bike");
}

start
{
	return (old.fade == 0 && current.fade == 1 && current.select_index == 0 &&
	       ((current.room == current.menu) || (current.room == current.lvl_select && current.menu_state == 1)));
}

split
{
	return ((settings["Trauma"] && current.room == current.trauma && old.player_x >= -32 && current.player_x < -32) || // trauma
		(settings["Showdown"] && current.room == current.showdown && old.showdown_paper == 0 && current.showdown_paper == 1) || // showdown
		(((settings["Prank call"] && current.room == current.prankcall) || (settings["Resolution"] && current.room == current.resolution)) && old.bike_climb <= 0.30 && current.bike_climb > 0.30) ||
		(settings["Grade screen"] && old.grade == 0 && current.grade == 1));
}
