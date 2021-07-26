package;

#if sys
import smTools.SMFile;
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import io.newgrounds.NG;
import lime.app.Application;
import openfl.Assets;

#if windows
import Discord.DiscordClient;
#end

#if cpp
import sys.thread.Thread;
#end

using StringTools;

class TitleState extends MusicBeatState {
	// This indicates if the intro is finished or not.
	static var initialized:Bool = false;

	// This is literally just the black background. Pop off, FNF devs.
	var blackScreen:FlxSprite;

	// Credits variables.
	var credGroup:FlxGroup; // The credits group.
	var creditText:Alphabet; // The credits text. Originally named credTextShit. Thanks for that.

	var textGroup:FlxGroup; // Another text group variable. Not entirely sure where this is used, yet.
	var ngSpr:FlxSprite; // This is the variable the Newground sprite is held in, which only shows in the HTML5 version of the game.

	// The curWacky variable holds the fun little intro texts that show up. 
	// UPDATE: Renamed to introTexts.
	var introTexts:Array<String> = [];

	// Creation function.
	override public function create():Void {
		// This stuff loads the mods.
		#if polymod
		polymod.Polymod.init({modRoot: "mods", dirs: ['introMod']});
		#end
		
		// This stuff sets up the replays directory.
		#if sys
		if (!sys.FileSystem.exists(Sys.getCwd() + "/assets/replays"))
			sys.FileSystem.createDirectory(Sys.getCwd() + "/assets/replays");
		#end

		// Assets loaded trace
		@:privateAccess
		{
			trace("Loaded " + openfl.Assets.getLibrary("default").assetsLoaded + " assets (DEFAULT)");
		}
		
		// Initializes player settings. Check PlayerSettings.hx for more info.
		PlayerSettings.init();

		#if windows // Discord client shenanigans.
		DiscordClient.initialize(); // Initialize discord presence.

		Application.current.onExit.add (function (exitCode) {
			DiscordClient.shutdown(); // When game closed, remove the presence.
		 });
		#end

		// This code picks out lines from introText.txt.
		introTexts = FlxG.random.getObject(grabIntroTexts());

		// Why?
		// trace('hello');

		super.create(); // Run super.create(); This creates the derived MusicBeatState.

		// The newgrounds stuff. Ignore this, this is almost never the case.
		#if ng
		var ng:NGio = new NGio(APIStuff.API, APIStuff.EncKey);
		trace('NEWGROUNDS LOL');
		#end

		// Bind OG savestate.
		FlxG.save.bind('funkin', 'ninjamuffin99');
		
		// Initialize save state. Refer to KadeEngineData.hx for more info.
		// NOTE: Will be renamed to EngineData later.
		KadeEngineData.initSave();
		
		// Loads highscore data. Refer to Highscore.hx for more information.
		Highscore.load();

		// Hhhh... why is this code like this... This is unnecessary. I'm leaving this here to show how lazy people can be.
		/* if (FlxG.save.data.weekUnlocked != null)
		{
			// FIX LATER!!!
			// WEEK UNLOCK PROGRESSION!!
			// StoryMenuState.weekUnlocked = FlxG.save.data.weekUnlocked;

			if (StoryMenuState.weekUnlocked.length < 4)
				StoryMenuState.weekUnlocked.insert(0, true);

			// QUICK PATCH OOPS!
			if (!StoryMenuState.weekUnlocked[0])
				StoryMenuState.weekUnlocked[0] = true;
		} */

		// This is debug stuff, if I recall correctly, leave it here. The only part that matters is the part below.
		#if FREEPLAY
		FlxG.switchState(new FreeplayState());
		#elseif CHARTING
		FlxG.switchState(new ChartingState());
		#else
		new FlxTimer().start(1, function(tmr:FlxTimer) { // ... i.e. this part. This is where the whole intro starts. 
			startIntro(); // <--
		});
		#end
	}

	var logoBl:FlxSprite; // This is the OG logoBumpin.png sprite.
	var gfDance:FlxSprite; // This is GF's sprite from the title screen.
	var danceLeft:Bool = false; // This is the toggle that keeps GF's dances alternating.
	var titleText:FlxSprite; // This is the Press Enter to Begin sprite.

	// INTRO START
	function startIntro() {
		// This only acts if initialized is false.
		if (!initialized) {
			var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond); // The fuck is this? Never seen this before.
				diamond.persist = true; // Apparently it's a transition.
				diamond.destroyOnNoUse = false; // Anyway, don't mess with this unless you're smarter than I am, which you probably are.

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;

			// Everything up until these last couple lines of this if statement are transition things, mess with caution.

			// Play intro music.
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}

		// Hardcoding the BPM of the menu loop.
		Conductor.changeBPM(102);
		persistentUpdate = true; // Update even in the background. Helps with music.

		// The 'bg' here is just a black sprite the size of the window. Whoah.
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		// Importing the logoBumpin.png. Removed the Kade version.
		logoBl = new FlxSprite(-150, -100); // Positioning & Initialization
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin'); // Importing Frames
		logoBl.antialiasing = true; // Image Quality
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24); // Add Animations
		logoBl.animation.play('bump'); // Play Animation
		logoBl.updateHitbox(); // Mandatory Hitbox Update

		// Importing GF dancing.
		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07); // Initialization & positioning :3
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle'); // Get textures
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false); // Load animation left
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false); // Load animation right
		gfDance.antialiasing = true; // Image Quality
		gfDance.updateHitbox(); // Mandatory Hitbox Update

		// Add the logoBumpin and GF to the scene.
		add(gfDance);
		add(logoBl);

		// Importing Title Text
		titleText = new FlxSprite(100, FlxG.height * 0.8); // Initialization & Positioning
		titleText.frames = Paths.getSparrowAtlas('titleEnter'); // Get Texture
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24); // Import Animation Idle
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24); // Import Press Animation
		titleText.antialiasing = true; // Image Quality
		titleText.animation.play('idle'); // Play Idle by Default
		titleText.updateHitbox(); // Hitbox Update
		add(titleText); // Add title text to scene.
	    // titleText.screenCenter(X);

		// This is no longer used.
		// var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		// logo.screenCenter();
		// logo.antialiasing = true;
		// add(logo);

		credGroup = new FlxGroup(); // Initializing credGroup.
		textGroup = new FlxGroup(); // textGroup is never added. I wonder why.
		add(credGroup);

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK); // Initializing the black screen.
		credGroup.add(blackScreen); // Adding the black screen to the scene.

		// creditText = new Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true); // Create a new Alphabet instance w/ font
		// creditText.screenCenter(); // Center the text
		// creditText.visible = false; // Hide the text
		// This shit isn't even added ever... why is it in the code..?

		// Newgrounds image importing
		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo')); // Loading graphic & positioning
		ngSpr.visible = false; // Hiding newgrounds image
		ngSpr.antialiasing = true; // Image quality
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8)); // Resize
		// ngSpr.updateHitbox(); // Unnecessary hitbox update
		ngSpr.screenCenter(X); // Screen center along X
		add(ngSpr); // Add newgrounds image to scene.

		// Hiding the mouse? Why?
		FlxG.mouse.visible = false;

		// If initialized, skip the intro.
		if (initialized)
			skipIntro();
		else
			initialized = true; // Make sure it's initialized.
	}

	// This function reads the introText.txt file.
	function grabIntroTexts():Array<Array<String>>
	{
		// Grabbing all of the intro texts.
		var fullText:String = Assets.getText(Paths.txt('introText'));

		// Splitting by new line.
		var firstArray:Array<String> = fullText.split('\n'); // This variable holds the individual lines.
		var swagGoodArray:Array<Array<String>> = []; // This variable holds every pair of lines, split up.

		for (i in firstArray) /* Looping through the individual lines */ {
			swagGoodArray.push(i.split('--')); // Splitting them by their splitters and putting them in the holder array.
		}

		return swagGoodArray; // Return the array of all of the pairs.
	}

	var transitioning:Bool = false; // This trigger indicates if the scene is transitioning. Wish I were this variable.

	// Typical update function. Occurs every frame.
	override function update(elapsed:Float) {
		// Set the song position to the current time of the music.
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		// F to toggle fullscreen.
		if (FlxG.keys.justPressed.F) {
			FlxG.fullscreen = !FlxG.fullscreen; // This toggles the fullscreen variable.
		}

		// Indicator to show if enter was pressed.
		var pressedEnter:Bool = controls.ACCEPT;

		// Mobile shenanigans.
		#if mobile
		for (touch in FlxG.touches.list) {
			if (touch.justPressed) {
				pressedEnter = true;
			}
		}
		#end

		// This shit is what takes you to the main menu.
		if (pressedEnter && !transitioning && skippedIntro) {
			// Switch shenanigans.
			#if !switch
			NGio.unlockMedal(60960);

			// If it's Friday according to da clock
			if (Date.now().getDay() == 5)
				NGio.unlockMedal(61034);
			#end

			// Play the press animation, only if flashing is enabled.
			if (FlxG.save.data.flashing)
				titleText.animation.play('press');

			// Camera flashes white shortly, why isn't this in the flashing if? I have no idea.
			FlxG.camera.flash(FlxColor.WHITE, 1);

			// Play the confirm sound.
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			// yo i wish this were me (sorry for cracking this joke twice)
			transitioning = true;

			// This trigger helps MainMenuState with fade-in stuff.
			MainMenuState.firstStart = true;

			new FlxTimer().start(2, function(tmr:FlxTimer) { // 2 second timer. 
				FlxG.switchState(new MainMenuState()); // Switch to a main menu state.

				// This timer used to manage a bunch of Kade Engine outdated jazz. We don't do that here.
			});
		}

		// This statement skips the intro.
		if (pressedEnter && !skippedIntro && initialized) {
			skipIntro();
		}

		// Of course, super update.
		super.update(elapsed);
	}

	// createCoolText modifies the text at the start.
	function createCoolText(textArray:Array<String>) {
		for (i in 0...textArray.length) { // Loop through text array
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false); // Make new alphabet instance
			money.screenCenter(X); // Center it
			money.y += (i * 60) + 200; // Increment by i + a hardcoded amount
			credGroup.add(money); // Add to credGroup and textGrou[]
			textGroup.add(money);
		}
	}

	// same as createCoolText, just without array functionality
	function addMoreText(text:String)
	{
		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	// Get rid of the cool text
	function deleteCoolText()
	{
		while (textGroup.members.length > 0) // Loop through
		{
			credGroup.remove(textGroup.members[0], true); // Remove bottom of list
			textGroup.remove(textGroup.members[0], true); // Remove bottom of list
		}
	}

	// This is a weird one. This is what makes things happen on the beat.
	override function beatHit()
	{
		super.beatHit(); // Important, don't remove

		// Play the logoBumpin' animation
		logoBl.animation.play('bump');

		// Swap GF's animation direction
		danceLeft = !danceLeft;

		// Play animation based off of direction
		if (danceLeft)
			gfDance.animation.play('danceRight');
		else
			gfDance.animation.play('danceLeft');

		// This shit floods the logs don't use
		// FlxG.log.add(curBeat);

		// Write the new shit on beat, this sucks lol
		switch (curBeat)
		{
			case 1:
				createCoolText(['KadeDeveloper', 'Rushtoxin']); // Add credits to Kade and I on beat 1
			case 3:
				addMoreText('present'); // 2 beats later, add present to the bottom
			case 4:
				deleteCoolText(); // Then remove the text
			case 5:
				createCoolText(['Onyx Engine', 'by']); // Onyx Engine stuff
			case 7:
				addMoreText('Rushtoxin'); // Credit to me kekw
				addMoreText('(built off of Kade Engine)'); // Also credit Kade
			case 8:
				deleteCoolText(); // Remove text again
			case 9:
				createCoolText([introTexts[0]]); // Funny introText stuff, line 1
			case 11:
				addMoreText(introTexts[1]); // introTexts line 2
			case 12:
				deleteCoolText(); // remove intro texts
			case 13:
				addMoreText('FNF'); // FRIDAY
			case 14:
				addMoreText('Onyx'); // NIGHT
			case 15:
				addMoreText('Engine'); // FUNKIN
			case 16:
				skipIntro(); // skip dat shit lol
		}
	}

	// Skipped intro trigger
	var skippedIntro:Bool = false;

	// Skip dat
	function skipIntro():Void
	{
		// If not already skipped
		if (!skippedIntro)
		{
			// remove ng sprite
			remove(ngSpr);

			// Flash white on the screen
			FlxG.camera.flash(FlxColor.WHITE, 4);

			// Remove credGroup
			remove(credGroup);

			// set the trigger
			skippedIntro = true;
		}
	}
}
