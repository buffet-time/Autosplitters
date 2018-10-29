state("iji") {}

startup
{
	// Optional splits on bosses
	// Krotera and Asha are instakilled in a normal run and Iosa 2 is unintersting, short and RNG based.
	settings.Add("Krotera", false);
	settings.Add("Asha", false);
	settings.Add("Proxima", true);
	settings.Add("Iosa 1", true);
	settings.Add("Iosa 2", false);
	settings.SetToolTip("Iosa 2", "After destroying Iosa's annihilator form");
	settings.Add("Tor", true);
}

init
{
	vars.globalsPtr = new MemoryWatcher<int>(new DeepPointer("iji.exe", 0x189720, 4));
	vars.torPtr = new MemoryWatcher<int>(new DeepPointer("iji.exe", 0x1AF2F4, 0x80, 0x390, 0, 0x10C, 4));
	vars.watchers = new MemoryWatcherList();
	vars.fightingTor = false;
	vars.initialized = false;

	vars.error = (Action<string>)((string info) => {
		MessageBox.Show(timer.Form,
			"Couldn't find " + info +
			"\nTry restarting the game.",
			"Iji Autosplitter script",
			MessageBoxButtons.OK,
			MessageBoxIcon.Error);
		vars.broken = true;
	});
	vars.broken = false;
}

update
{
	if (vars.broken) return false;

	bool globalsUpdated = vars.globalsPtr.Update(game);
	if (globalsUpdated || !vars.initialized) {
		if (vars.globalsPtr.Current == 0) { return false; } // Game loading
		bool found = false;
		IntPtr ptr = new IntPtr(vars.globalsPtr.Current);
		while (true) {
			int key = memory.ReadValue<int>(ptr);
			if (key < 100000 || key > 105000) break;
			if (key == 100058) {
				vars.inGame = new MemoryWatcher<double>(ptr + 0x10);
				found = true;
				break;
			}
			ptr = ptr + 0x28;
		}
		if (!found) { return false; } // Still loading
		vars.initialized = true;
	}

	if (!vars.initialized) return false;

	vars.inGame.Update(game);

	if (vars.inGame.Current == 1) {
		if (globalsUpdated || vars.watchers.Count == 0) {
			int remaining = 4;
			IntPtr sector = IntPtr.Zero,
				levelTime = IntPtr.Zero,
				totalTime = IntPtr.Zero,
				iosa2 = IntPtr.Zero;
			IntPtr ptr = new IntPtr(vars.globalsPtr.Current);
			while (true) {
				int key = memory.ReadValue<int>(ptr);
				if (key < 100000 || key > 105000) break;
				switch (key) {
					case 100159: sector =    ptr + 0x10; --remaining; break;
					case 100172: levelTime = ptr + 0x10; --remaining; break;
					case 100616: totalTime = ptr + 0x10; --remaining; break;
					case 100612: iosa2 =     ptr + 0x10; --remaining; break;
					default: break;
				}
				if (remaining == 0) break;
				ptr = ptr + 0x28;
			}
			if (remaining > 0) { vars.error("Sector Info memory locations."); return false; }

			MemoryWatcher<double> sectorWatcher    = new MemoryWatcher<double>(sector)    { Name = "Sector"     };
			MemoryWatcher<double> levelTimeWatcher = new MemoryWatcher<double>(levelTime) { Name = "Level Time" };
			MemoryWatcher<double> totalTimeWatcher = new MemoryWatcher<double>(totalTime) { Name = "Total Time" };
			MemoryWatcher<double> iosa2Watcher     = new MemoryWatcher<double>(iosa2)     { Name = "Iosa 2"     };

			if (vars.watchers.Count > 0) {
				sectorWatcher.Old = vars.watchers["Sector"].Old;
				sectorWatcher.Current = vars.watchers["Sector"].Current;
				levelTimeWatcher.Old = vars.watchers["Level Time"].Old;
				levelTimeWatcher.Current = vars.watchers["Level Time"].Current;
				totalTimeWatcher.Old = vars.watchers["Total Time"].Old;
				totalTimeWatcher.Current = vars.watchers["Total Time"].Current;
				iosa2Watcher.Old = vars.watchers["Iosa 2"].Old;
				iosa2Watcher.Current = vars.watchers["Iosa 2"].Current;
			}

			vars.watchers.Clear();
			vars.watchers.Add(sectorWatcher);
			vars.watchers.Add(levelTimeWatcher);
			vars.watchers.Add(totalTimeWatcher);
			vars.watchers.Add(iosa2Watcher);
		}
		vars.watchers.UpdateAll(game);

		if (vars.watchers["Sector"].Current == 15) {
			//print("Checking tor");
			if (vars.torPtr.Update(game)) {
				int remaining = 2;
				bool tor = false;
				IntPtr currentHp = IntPtr.Zero, ptr = new IntPtr(vars.torPtr.Current);
				while (true) {
					int key = memory.ReadValue<int>(ptr);
					if (key < 100000 || key > 105000) break;
					switch (key) {
						case 100005:
							currentHp = ptr + 0x10; --remaining; break;
						case 100316:
							// identify tor with security stat
							tor = memory.ReadValue<double>(ptr + 0x10) == 250;
							--remaining; break;
						default: break;
					}
					if (remaining == 0) break;
					ptr = ptr + 0x28;
				}
				if (tor) {
					if (remaining > 0) { vars.error("Tor Hp memory location."); return false; }
					vars.fightingTor = true;
					vars.torHp = new MemoryWatcher<double>(currentHp);
				}
			}
			if (vars.fightingTor)
				vars.torHp.Update(game);
		}
	}
}

start
{
	return vars.inGame.Old == 0 && vars.inGame.Current == 1;
}

reset
{
	return vars.inGame.Old == 1 && vars.inGame.Current == 0;
}

split
{
	if (vars.inGame.Current == 1) {
		double oldSector = vars.watchers["Sector"].Old, currentSector = vars.watchers["Sector"].Current;
		if (oldSector != currentSector) return (
			// standard progression
			(oldSector + 1 == currentSector && currentSector != 1) ||
			// sector 9 to sector X
			(oldSector == 9 && currentSector == 0) ||

			// there's a delay between boss room -> sector -> next sector
			// these are some (probably obsolete) fail-safes
			(oldSector == 11 && currentSector == 4) ||
			(oldSector == 12 && currentSector == 6) ||
			(oldSector == 13 && currentSector == 8) ||
			(oldSector == 14 && currentSector == 0) ||

			// entering boss rooms
			(settings["Krotera"] && currentSector == 11) ||
			(settings["Asha"]    && currentSector == 12) ||
			(settings["Proxima"] && currentSector == 13) ||
			(settings["Iosa 1"]  && currentSector == 14) ||
			(settings["Tor"]     && currentSector == 15));
		else if
			// destroying Iosa's annihilator form
			(settings["Iosa 2"] && currentSector == 14 &&
			 vars.watchers["Iosa 2"].Old == 0 && vars.watchers["Iosa 2"].current == 1) return true;
		else if
			// killing Tor - final split
			(vars.fightingTor && vars.torHp.Current <= 0) { vars.fightingTor = false; return true; }
	}
}

isLoading
{
	return true;
}

gameTime
{
	if (vars.inGame.Current == 1)
		return TimeSpan.FromSeconds(vars.watchers["Level Time"].Current + vars.watchers["Total Time"].Current);
	else return TimeSpan.FromSeconds(0);
}
