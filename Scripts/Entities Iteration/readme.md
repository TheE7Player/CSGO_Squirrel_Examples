# Entities Iteration

This following example goes over:

- Basic Entries Search Finding using Wildcards

- Weak References

- Various Scopes (Local, Public and Global)

- Creation of Dynamic Hammer Entries

- Referencing Multiple Scripts

> Note: This example uses `vs_math.nut` from samisalreadytaken's vs_library repo : [vs_library: vscript library](https://github.com/samisalreadytaken/vs_library)

> Note: This example also uses my own script called Colour Chat, which can be found here: [Colour Chat](https://github.com/TheE7Player/CSGO_Squirrel_Examples/tree/master/Scripts/Colour%20Chat)

## Information

This example demonstrates various techniques with `Squirrel` and `Hammer` to manipulate entities from inside the map. This always demonstrates how its possible to create your own managed objects outside the map (With of course, constraints to how much you can do with it).

Provided are:

- `entities_iteration.vmf` : Hammer editor map file, used to see the internal map structure with `Source SDK`

- `entities_iteration_compiled.bsp` : This map is already compacted, ready to play and use without any additional files (As the files are packed into the bsp!).

If you plan to not use the `entities_iteration_compiled.bsp`, you'll need to ensure you copy the contains of `vscripts/e7` into your games directory in folder called `/Scripts` to get this working. This method will also allow you to edit the script and experiment with your own approach to the solution provided.

### Pakrat Instructions

I used a tool called `PakRat` to pack the necessary files into the `.bsp` to allow you to experiment with the current solution without the need to copy external files. The following screenshot shows the pakrat setup.

> Pakrat can be downloaded here: https://developer.valvesoftware.com/wiki/Pakrat
> Please be safe with what ever links you click out of this url.

![pakrat screenshot](https://raw.githubusercontent.com/TheE7Player/CSGO_Squirrel_Examples/master/Scripts/Entities%20Iteration/images/pakrat_compile.png)

Notice the path column.  Its important that when adding new files, to replace the absolute path of the file (A Drive, C Drive etc) to relative path (from csgo dir onwards).

The best method would be to remove the string until it just reaches 'csgo' folder.

Example (Abs Path):

`C:\SteamApps\common\Counter Strike Global Offensive\csgo\scripts\vscript\helloworld.nut`

would just become (Rel Path):

`scripts/vscripts`

> Note: The game can sometimes misinterpret if you add an extra `/` at the end, keep note of this behaviour.

# Screenshots

![screenshot 1](https://github.com/TheE7Player/CSGO_Squirrel_Examples/blob/master/Scripts/Entities%20Iteration/images/hammer_overview.png?raw=true)

![screenshot 2](https://github.com/TheE7Player/CSGO_Squirrel_Examples/blob/master/Scripts/Entities%20Iteration/images/bot_damage_text.png?raw=true)

<img src="https://github.com/TheE7Player/CSGO_Squirrel_Examples/blob/master/Scripts/Entities%20Iteration/images/bot_bullet_text_fire.png?raw=true" title="" alt="screenshot 3" data-align="center">
