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
	settings.Add("o", false, "Only End split");
	settings.SetToolTip("o", "Remove all splits except the final one - Resolution");
}

start
{
	return (old.fade == 0 && current.fade == 1 && current.select_index == 0 &&
	       ((current.room == current.menu) || (current.room == current.lvl_select && current.menu_state == 1)));
}

split
{
	return ((!settings["o"] && current.room == current.trauma && old.player_x >= -32 && current.player_x < -32) || // trauma
		(!settings["o"] && current.room == current.showdown && old.showdown_paper == 0 && current.showdown_paper == 1) || // showdown
		(((!settings["o"] && current.room == current.prankcall) || (current.room == current.resolution)) && old.bike_climb <= 0.30 && current.bike_climb > 0.30) ||
		(!settings["o"] && old.grade == 0 && current.grade == 1));
}
