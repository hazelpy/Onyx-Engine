package;

import flixel.input.gamepad.FlxGamepad;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.addons.text.FlxTextField;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.utils.Assets;
import sys.thread.Thread;
import await.*;

#if windows
import Discord.DiscordClient;
#end

using StringTools;

class FreeplayState extends MusicBeatState {
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;
	var diffText:FlxText;

	var scoreText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';
	var comboText:FlxText;

	var isDebug:Bool = false;
	var itemsFadeIn:Bool = false; // This shows if the items have faded in yet. Makes sure things don't act weird at the beginning of the menu.
	var alphaModifier:Float = 0.7; // This is used to modify how much the song names & icons fade out in the freeplay menu.

	private var iconArray:Array<HealthIcon> = [];
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpBGs:FlxTypedGroup<FlxSprite>;

	// private var curPlaying:Bool = false; // Unused.

	override function create() {
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length) {
			var data:Array<String> = initSonglist[i].split(':');
			songs.push(new SongMetadata(data[0], Std.parseInt(data[2]), data[1]));
		}

		persistentUpdate = persistentDraw = true;

		#if windows
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Browsing Free Play Songs", null);
		#end

		#if debug
		isDebug = true;
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		grpBGs = new FlxTypedGroup<FlxSprite>();
		add(grpBGs);
		add(grpSongs);
		
		var fadeInTimer = new FlxTimer().start(1, function(timer:FlxTimer) {
			itemsFadeIn = true;
		});

		for (i in 0...songs.length) {
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false, true);
				songText.isMenuItem = true; // Makes the movements all cool n' shit.
				songText.targetY = i;

			var songBG:FlxSprite = new FlxSprite(0, songText.y - 43).makeGraphic(FlxG.width, 156, FlxColor.WHITE);
				songBG.alpha = 0;
				songBG.updateHitbox();
				songBG.screenCenter(X);

			grpBGs.add(songBG);
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		comboText = new FlxText(diffText.x + 100, diffText.y, 0, "", 24);
		comboText.font = diffText.font;
		add(comboText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		// var swag:Alphabet = new Alphabet(1, 0, "swag"); // swag

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String) {
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>) {
		if (songCharacters == null)
			songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7) {
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		comboText.text = combo + '\n';

		var upP = FlxG.keys.justPressed.UP;
		var downP = FlxG.keys.justPressed.DOWN;
		var accepted = controls.ACCEPT;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null) {
			if (gamepad.justPressed.DPAD_UP) {
				changeSelection(-1);
			} else if (gamepad.justPressed.DPAD_DOWN) {
				changeSelection(1);
			} else if (gamepad.justPressed.DPAD_LEFT) {
				changeDiff(-1);
			} else if (gamepad.justPressed.DPAD_RIGHT) {
				changeDiff(1);
			}
		}

		if (upP) {
			changeSelection(-1);
		} else if (downP) {
			changeSelection(1);
		}

		if (FlxG.keys.justPressed.LEFT)
			changeDiff(-1);
		else if (FlxG.keys.justPressed.RIGHT)
			changeDiff(1);

		if (controls.BACK) {
			FlxG.switchState(new MainMenuState());
		}

		if (accepted) {
			// adjusting the song name to be compatible
			var songFormat = StringTools.replace(songs[curSelected].songName, " ", "-");
			switch (songFormat) {
				case 'Dad-Battle': songFormat = 'Dadbattle';
				case 'Philly-Nice': songFormat = 'Philly';
			}
			
			trace(songs[curSelected].songName);

			var poop:String = Highscore.formatSong(songFormat, curDifficulty);

			trace(poop);
			
			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			LoadingState.loadAndSwitchState(new PlayState());
		}

		var i:Int = 0;
		for (item in grpSongs.members) {
			if (i != curSelected) {
				if (item.x != 90)
					FlxTween.tween(item, {x: 90}, 0.4, {
						ease: FlxEase.quadOut
					});
			}

			grpBGs.members[i].y = item.y - 43;

			i += 1;
		}

		i = 0;
		for (item in grpBGs.members) {
			if (!itemsFadeIn) continue;
			if (i != curSelected) {
				var dist:Float = Math.abs(curSelected - i);
				var alphaDist:Float = 0.6 / (dist * 2);
				FlxTween.cancelTweensOf(item);
				FlxTween.tween(item, {alpha: alphaDist}, 0.4, {
					ease: FlxEase.quadOut
				});
			} else {
				FlxTween.cancelTweensOf(item);
				FlxTween.tween(item, {alpha: 0.8}, 0.4, {
					ease: FlxEase.quadOut
				});
			}

			i += 1;
		}
	}

	function changeDiff(change:Int = 0) {
		// Change by the interval ^-^
		curDifficulty += change; 

		// Loop around ;
		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		// Adjusting the highscore song name to be compatible (changeSelection)
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", ""); // Can't you just remove the spaces...?
		switch (songHighscore) {
			case 'DadBattle': songHighscore = 'Dadbattle'; // Modify the names to fit the corresponding song in the highscores.
			case 'PhillyNice': songHighscore = 'Philly'; // Wheeeeeee
		}
		
		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty); // Grab the highscore data for the current song.
		combo = Highscore.getCombo(songHighscore, curDifficulty); // Grab the combo data for the current song.
		#end

		// Modify the difficulty text.
		var difficultyText = CoolUtil.difficultyFromInt(curDifficulty);

		// SWITCH PER DIFFICULTY
		// This works with every difficulty depending on what you type here.
		switch(curDifficulty) {
		  /*case 0: // Implement this if you'd wish to modify the looks of a difficulty name in Freeplay.
				diffText.text = difficultyTest.toLowerCase(); */
			default: // Applies to every value without a case. In this case, all of them.
				diffText.text = Capitalize(difficultyText); // Refer to the function below.
		}
	}

	// Capitalizing function ;
	function Capitalize(text:String):String { // I wrote this myself, don't expect it to be fast.
		var words:Array<String> = text.split(" "); // Split the string into words;
		var firstWord:String = words[0]; // Collect first word;
		var chars:Array<String> = firstWord.split(""); // Split first word into characters;

		chars[0] = chars[0].toUpperCase(); // Capitalize the first character of the first word.

		var firstWordRejoin = chars.join(""); // Rejoin the word.

		words.shift(); // Remove the first word from the words array.
		words.unshift(firstWordRejoin); // Add the capitalized version.

		var capitalized = words.join(" "); // Rejoin the string, with the new first word.
		return capitalized; // Return the result.
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4); // Play the scroll sound effect :3

		// Change the selection by the change
		curSelected += change;

		// Loop around in the case it goes negative or above the max
		if (curSelected < 0) 
			curSelected = songs.length - 1;
		else if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty); // Grab the highscore data for the current song.
		combo = Highscore.getCombo(songHighscore, curDifficulty); // Grab the combo data for the current song.
		// lerpScore = 0;
		#end

		#if PRELOAD_ALL
		// This code really sucks. It creates a whole thread just to play music ;;
		// I don't care, I'm keeping it in.
		//new FlxTimer(0.1, function(tmr:FlxTimer) {
		//	// LITERALLY SO BAD. DON'T EVER DO THIS. I DID THIS FOR MY OWN GAIN.
		//	sys.thread.Thread.create(() -> {
		//    playMusic(songs[curSelected].songName, 0);
		//	});
		//});

		// Play the instrumental for the song currently selected.
		playMusic(songs[curSelected].songName, 0);
		#end

		// Originally named bullShit. Changed to iterator, because that's how it's used.
		var iterator:Int = 0; // Do not modify this, this is used to keep track of the current index in the for loop below.

		// Loops through the song icons...
		for (i in 0...iconArray.length)
		{
			var dist = Math.abs(curSelected - i); // Get the distance from the current position & the selected icon's position.
			var fadedAlpha:Float = 1 / (dist * (1 + alphaModifier); // Then, do some quick calculations to get the alpha to change the icon to.

			if (!(i==curSelected)) // ... checks if theyre the selected song's icon ...
			iconArray[i].alpha = fadedAlpha); // ... and if they're not, then set them to the faded alpha.
			else iconArray[i].alpha = 1; // Otherwise, set the alpha to 1, since the current song's icon is selected.
		}

		// This used to be necessary, but it isn't now.
		// iconArray[curSelected].alpha = 1;

		// Looping through the group of song texts.
		for (item in grpSongs.members) {
			var dist = curSelected - iterator; // Grab the distance between the current item & the selected item.
			var absoluteDist = Math.abs(dist); // Get the absolute value of the distance.
			
			item.targetY = dist; // Set the item's target Y to the distance between the selection & the current item.

			if (iterator == curSelected) { // If the current position is the same as the selected's position ...
				FlxTween.cancelTweensOf(item); // ... Make sure it's not tweening ...
				FlxTween.tween(item, {x: 190, alpha: 1}, 0.4, { // ... and tween it to a preferred position & alpha.
					ease: FlxEase.quadOut // Also, this is the easing function used. Any function in FlxEase can be used here.
				});
			}

			iterator++; // Make sure the iterator variable, well, iterates.

			// Set the current item's alpha to some fancy math. I'm too lazy to explain it, lol
			item.alpha = 1 / (absoluteDist * (alphaModifier + 1));
		}
	}

	function playMusic(name:String, data:Float) { 
		// Simple function that plays the music.
		// This might be modified for optimizations later.
		// Optimizations, of course, referring to song scrolling.

		// Play the song specified.
		FlxG.sound.playMusic(Paths.inst(name), Std.int(data) /* Making the data an int just in case;;; */);
	}
}

// This simple class holds song data.
class SongMetadata {
	public var songCharacter:String = ""; // Song opponent is stored here, for icon purposes.
	public var songName:String = ""; // The name is stored here. This is clearly used for song titles.
	public var week:Int = 0; // The week that the song takes place in. Not sure what reason this is here for.

	public function new(song:String, week:Int, songCharacter:String) { // Initialization.
		this.songCharacter = songCharacter; // Set the songCharacter variable.
		this.songName = song; // Set the songName variable.
		this.week = week; // Set the week number variable.
	}
}
