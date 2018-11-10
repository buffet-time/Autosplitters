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
	ushort tutorial :    "HotlineGL.exe", 0x9F773C;
	ushort part :        "HotlineGL.exe", 0x9F75E0;
	ushort trauma :      "HotlineGL.exe", 0x9F769C;
	ushort showdown :    "HotlineGL.exe", 0x9F7730;
	ushort prankcall :   "HotlineGL.exe", 0x9F7740;
	ushort resolution :  "HotlineGL.exe", 0x9F7774;
}

init
{
	vars.skip_next = false;
	vars.counter = 0;
}

startup
{
	settings.Add("e", true,  "End split");
	settings.SetToolTip("e", "Splits on completion of Resolution");
	settings.Add("1", true,  "Every Chapter");
	settings.SetToolTip("1", "Splits after each level (except Resolution)");
	settings.Add("2", false, "Every Part (All Levels)");
	settings.SetToolTip("2", "Splits on \"Part X\" screens (except after tutorial)");
	settings.Add("3", false, "Every Part (Any%)");
	settings.SetToolTip("3", "Splits after completion of Decadence, Neighbors, Deadline, and Showdown");
}

update
{
	if (current.room == current.tutorial) vars.skip_next = true;
	if (old.grade == 0 && current.grade == 1) vars.counter++;
}

start
{
	if (old.fade == 0 && current.fade == 1 && current.select_index == 0 &&
	((current.room == current.menu) || (current.room == current.lvl_select && current.menu_state == 1))) {
		vars.counter = 0;
		return true;
	}
}

split
{
	if (settings["2"] && old.room != current.part && current.room == current.part) {
		if (vars.skip_next) vars.skip_next = false;
		else return true;
	}
	return ((settings["1"] && current.room == current.trauma && old.player_x >= -32 && current.player_x < -32) ||                         	// trauma
		((settings["1"] || settings["3"]) && current.room == current.showdown && old.showdown_paper == 0 && current.showdown_paper == 1) || // showdown
		(settings["1"] && current.room == current.prankcall && old.bike_climb <= 0.30 && current.bike_climb > 0.30) ||                      // prankcall
		(current.room == current.resolution && old.bike_climb <= 0.30 && current.bike_climb > 0.30) ||                                      // end split
		(settings["1"] && old.grade == 0 && current.grade == 1) ||                                                                          // grade splits
		(settings["3"] && old.grade == 0 && current.grade == 1 && (vars.counter == 4 || vars.counter == 8 || vars.counter == 12)));         // decadence, neighbors, deadline
}
