package;

import flixel.input.gamepad.FlxGamepad;
import Controls.KeyboardScheme;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import io.newgrounds.NG;
import lime.app.Application;

// Weird edge case for Discord clients.
#if windows
import Discord.DiscordClient;
#end

using StringTools;

// MainMenuState class extending MusicBeatState, main menu
class MainMenuState extends MusicBeatState {
	// Currently selected menu button.
	var curSelected:Int = 0;

	// Define menu items group.
	var menuItems:FlxTypedGroup<FlxSprite>;

	// Weird edge case on the shits. Will likely remove later.
	// Renamed 'optionShits' to buttonList. More professional.
	#if !switch
	var buttonList:Array<String> = ['story mode', 'freeplay', 'options'];
	#else
	var buttonList:Array<String> = ['story mode', 'freeplay'];
	#end

	// Whether or not this is the first time the menu state is shown.
	public static var firstStart:Bool = true;

	// Current engine version and FNF version.
	public static var engineVer:String = "Beta 0.0.1";
	public static var gameVer:String = "0.2.7.1";

	// Magenta is actually the variable name for the menuDesat used on select. What the fuck, Kade.
	// Changed to menuDesat.
	var menuDesat:FlxSprite;

	// camFollow is an object used to map where the camera follows in the menu.
	// Will be deprecated & removed when I start on visuals.
	var camFollow:FlxObject;

	// Really bad trigger to show when the tweens are done. Really, Kade?
	// Set to true by default, this shit will be removed soon too.
	public static var finishedFunnyMove:Bool = true;

	// Creation function for MainMenuState.
	override function create() {	
		// Once again, only affecting windows with the discord stuff.
		#if windows
		// Updating Discord presence to match location.
		DiscordClient.changePresence("In the Menus", null);
		#end

		// If music is already playing, don't play more menu music.
		if (!FlxG.sound.music.playing)
		{
			// Initializing menu music.
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		// Just leaving this useless stuff here, as I haven't confirmed what it's doing yet.
		// Nevermind, these triggers are used in FlxState to tell if non-showing states are still rendered.
		// Good to know.
		persistentUpdate = persistentDraw = true;

		// Loading the original background graphic.
		// Indented to add some fanciness to the code ;P
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBG'));
			// bg.scrollFactor.x = 0; // X doesn't scroll, couldn't you just use scrollFactor.set();?
			bg.scrollFactor.set(0, 0.10); // Updated to reflect my discovery.
			bg.setGraphicSize(Std.int(bg.width * 1.1));
			// bg.updateHitbox(); // You really don't have to do this directly after setGraphicSize(). It automatically does it.
			bg.screenCenter(); // Centering the background is smart, but right after setting a position in the original definition? Removed original X.
			bg.antialiasing = true; // Image quality.
		add(bg); // Adding the background to the scene.

		// Defining the object that the camera follows ...
		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow); // ... and adding it, of course.

		// Desaturated version of the original background. Flashes on button click.
		// UPDATE: Renamed this variable to menuDesat ... Why exactly was this called "magenta" before?
		menuDesat = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		// menuDesat.scrollFactor.x = 0; // Optimization: scrollFactor.set();
		menuDesat.scrollFactor.set(0, 0.10); // Setting scroll factor.
		menuDesat.setGraphicSize(Std.int(menuDesat.width * 1.1)); // Setting graphic size up.
		// menuDesat.updateHitbox(); // Again, not necessary, setGraphicSize() does it already.
		menuDesat.screenCenter(); // Centering it again.
		menuDesat.visible = false; // Hide menuDesat until further use.
		menuDesat.antialiasing = true; // Image quality.
		menuDesat.color = 0xFFfd719b; // Set color to a nicer color.
		add(menuDesat); // And finally, add menuDesat to the scene.

		// Create the sprite group instance for menuItems ...
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems); // ... and add to the scene.

		// tex : The textures for the menu buttons.
		// UPDATE: rename 'tex' to menuAssets.
		var menuAssets = Paths.getSparrowAtlas('FNF_main_menu_assets');

		// Looping through the options. Man, I should really make a better name for this variable.
		for (i in 0...buttonList.length) { // Looping through every index from 0 to the amount of buttons in the list.
			/*
			  = MENU ITEM INITIALIZATION CODE: WILL BE ALTERED FOR AESTHETIC APPEAL LATER
			  - Currently creates menu items & aligns them in the middle, with their variables.
			*/
			var menuItem:FlxSprite = new FlxSprite(0, FlxG.height * 1.6); // Initialization
				menuItem.frames = menuAssets; // menuAssets = Spritesheet for assets.
				menuItem.animation.addByPrefix('idle', buttonList[i] + " basic", 24); // Add the animations per button name.
				menuItem.animation.addByPrefix('selected', buttonList[i] + " white", 24); // Ditto.
				menuItem.animation.play('idle'); // Play the idle animation as default.
				menuItem.ID = i; // Tag the item with an ID
				menuItem.screenCenter(X); // Center along X
				menuItems.add(menuItem); // Add the item
				menuItem.scrollFactor.set(); // What the fuck, why add this if it's empty??? Think, kade, think!
				menuItem.antialiasing = true; // And of course, image quality.
				// For now, chuck down the Y positioning here.
				menuItem.y = 60 + (i * 160);
			
		/*  if (firstStart)
				FlxTween.tween(menuItem, {y: 60 + (i * 160)}, 1 + (i * 0.25), {ease: FlxEase.expoInOut, onComplete: function(flxTween:FlxTween) 
					{ 
						changeItem(); // This is wonky. I'll redo this later.
					}});
			else */ // For now, remove the original tween in function. It's not gonna be used, anyway. Sorry, Kade.
		}

		// Tell the camera to follow camFollow. Might remove later, not sure.
		FlxG.camera.follow(camFollow, null, 0.60 * (60 / FlxG.save.data.fpsCap));

		// String together the version text before use. It's an extra line of code, but it's for neatness, not optimization.
		var textTag:String = gameVer + (Main.watermarks ? " FNF - " + engineVer + " Onyx Engine" : "");

		// Kade at it again with the shitty variable names.
		// Renamed to versionText.
		var versionText:FlxText = new FlxText(5, FlxG.height - 18, 0, textTag, 12);
		versionText.scrollFactor.set();
		versionText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionText);
	
		/* 
		== NOTE: versionText shows at the bottom of the screen, always. You can modify it to be whatever you want it to be.
		== Just modify textTag, and set it to what you want the watermark to say.
		*/
		
		// God, why is this handled here... Damnit Kade, I'll have to clean this up later.
		if (FlxG.save.data.dfjk)
			// Setting the control scheme, in MainMenuState, ugh.
			controls.setKeyboardScheme(KeyboardScheme.Solo, true);
		else
			controls.setKeyboardScheme(KeyboardScheme.Duo(true), true);

		// changeItem once to have the highlight going- shouldn't this go right after the items are added..? Won't question it.
		changeItem();

		// super.create(); to create original state
		super.create();
	}

	// THIS SHOWS WHETHER OR NOT A BUTTON HAS BEEN PRESSED OR NOT. DON'T TOUCH.
	// Changed name from selectedSomethin to buttonSelected for readability.
	var buttonSelected:Bool = false;

	// Hoooo boy, here we go, the big update function. This one triggers every frame & handles all the selection stuff. Modify with caution.
	override function update(elapsed:Float) {
		// This is the neat lil' fade in function for the music. Neat.
		if (FlxG.sound.music.volume < 0.8) {
			// Adds a multiple of FlxG.elapsed to the volume. Not really sure *how* this works, but that'll be figured out as we go.
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		// Big ol' if statement checking if no menu button is selected.
		if (!buttonSelected) {
			// Checks if the player is using a gamepad.
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			// Makes sure that it doesn't check if the gamepad had inputs sent if there isn't a gamepad used.
			if (gamepad != null) {
				// Scroll up.
				if (gamepad.justPressed.DPAD_UP) {
					// Play a neat lil' sound effect :3
					FlxG.sound.play(Paths.sound('scrollMenu'));
					// Changing by -1 = moving up 1. It's backwards, I know.
					changeItem(-1); 
				} else if (gamepad.justPressed.DPAD_DOWN) { // Rather than using 2 if statements, just use an if - else if.
					// Neat lil' sound effect again :3
					FlxG.sound.play(Paths.sound('scrollMenu'));
					// Changing by 1 = moving down 1.
					changeItem(1); 
				}
			}

			// Same scrolling shits but with keyboard inputs.
			if (FlxG.keys.justPressed.UP) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			} else if (FlxG.keys.justPressed.DOWN) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			// Return to the title screen, if preferred. Will be toggleable.
			if (controls.BACK && FlxG.save.data.titleReturn) // Disabled by default. Check Main.hx.
			{
				FlxG.switchState(new TitleState());
			}

			// On accept press. | DEFAULT: ENTER;
			if (controls.ACCEPT)
			{
				// This was originally if-else's. Changing it to a switch statement.
				switch(buttonList[curSelected]) {
					case 'donate':
						// Send the user to the FNF itch.io page.
						fancyOpenURL("https://ninja-muffin24.itch.io/funkin");
					default:
						// Indicate that a button has been selected. to keep any other selections from overlapping.
						buttonSelected = true;

						// Play the nice lil' confirm sound :3
						FlxG.sound.play(Paths.sound('confirmMenu'));
						
						// Only flicker menuDesat if the user has flashing enabled.
						if (FlxG.save.data.flashing)
							FlxFlicker.flicker(menuDesat, 1.1, 0.15, false);
	
						// Loop through every menuItem and interact with them.
						menuItems.forEach(function(spr:FlxSprite) {
							if (curSelected != spr.ID) {
								// If the current menu item wasn't the selected item ...
								FlxTween.tween(spr, {alpha: 0}, 1.3, { // Make them fade out nicely.
									ease: FlxEase.quadOut, // You can change this easing function to anything under FlxEase. Go wild!
									onComplete: function(twn:FlxTween)
									{
										spr.kill(); // And make sure to kill the sprite before the transition, for optimization.
									}
								});
							} else {
								// If the current menu item WAS selected:
								if (FlxG.save.data.flashing) { // Make sure the player is fine with the flashing.
									FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker) // Flicker the sprite's alpha.
									{
										goToState(); // Once it's done, go to the new state!
									});
								} else { // Otherwise if flashing is disabled:
									new FlxTimer().start(1, function(tmr:FlxTimer) // Just wait a small moment ...
									{
										goToState(); // ... then go to the selected state.
									});
								}
							}
						});
				}
			}
		}

		// Run the original update function w/ the elapsed time. Is a must have.
		super.update(elapsed);

		// This just centers all the menu items. It's handy, but will be removed later.
		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X); // Center along X.
		});
	}
	
	// The handy function to switch states easily.
	function goToState() {
		// daChoice:String | Gets the current selected button name.
		// UPDATE: Change name to selectedButtonName, for readability.
		var selectedButtonName:String = buttonList[curSelected];

		// Check the selected button's name.
		switch (selectedButtonName)
		{
			case 'story mode': // Story Mode selected;
				FlxG.switchState(new StoryMenuState()); // Swap to a new StoryMenuState.
				trace("Story Mode selected!"); // Also, log that it was swapped, for debug purposes.
			case 'freeplay': // Free Play mode selected;
				FlxG.switchState(new FreeplayState()); // Swap to a new FreeplayState.
				trace("Freeplay Mode selected!"); // Again, log the swap for debug purposes.
			case 'options':
				FlxG.switchState(new OptionsMenu()); // Swap to an options menu.
				trace("Options Menu selected!");
		}
	}

	// Scrolling through the menu is controlled with this function.
	function changeItem(interval:Int = 0) // Takes in one integer value, defaults to 0.
	{
		// if (finishedFunnyMove) { // Kade used to have this trigger in here, it's completely unnecessary.
		// Increment the current selection ID by the interval.
		curSelected += interval;

		// Make sure that curSelected doesn't overflow the list, or go negative.
		if (curSelected >= menuItems.length)
			curSelected = 0; // Flat reset.
		if (curSelected < 0)
			curSelected = menuItems.length - 1; // Length - 1 = the length in array notation.

		// Loop through the menu items and interact.
		menuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.ID != curSelected) // If the menu item isn't selected ...
				spr.animation.play('idle'); // ... Reset the item to its idle position.
			else if (spr.ID == curSelected) { // This statement used to check Kade's old tween trigger. Removed that.
				spr.animation.play('selected'); // Play the sprite's 'selected' animation.
				// camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y); // Why exactly would the camera follow be set to the selection..?
			}

			// Update the item's hitbox, just to be safe.
			spr.updateHitbox();
		});
	}
}

// END OF SCRIPT