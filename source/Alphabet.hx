package;

// Importing essential libraries.
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import haxe.ds.Map;
import haxe.ds.StringMap;

using StringTools;

/*
== Looseley based on FlxTypeText, thanks for that, lol
*/

class Alphabet extends FlxSpriteGroup {
	public var delay:Float = 0.05; // This is useless. What is this even here for..? It's not in the docs of HaxeFlixel anywhere.
	// Not removing delay var because I can't be entirely sure what it does, yet. There's no evidence.
	// Update: I put it to use, it was supposed to be used when writing typed text. Come on, Kade.

	public var paused:Bool = false; // Another variable that the code doesn't reference whatsoever. Won't remove, won't change. Will test later.

	// Menu-related variables.
	public var targetY:Float = 0; // I don't *really* understand what this does, but I'm sure it's used because I checked the code. Will test later.
	public var isMenuItem:Bool = false; // Indicator of whether or not this is a menu item. Don't know why it would be, but okay.

	public var text:String = ""; // The text string.

	var _finalText:String = ""; // The final version of the text.
	var _curText:String = ""; // The current showing text.

	public var widthOfWords:Float = FlxG.width; // Width of the words, defaults to FlxG.width. I'd assume this shows the pixel width of the string when assigned?

	var yMulti:Float = 1; // This variable handles line breaks. Wacky name, I know. I didn't write this.

	public var letterOffset:Map<String, Float> = ['x' => 90, 'y' => 0]; // Modify this to offset the entire text box. Values are in pixels.
	public var spaceWidth:Float = 20; // Modify this value if you want gaps between letters to be wider.
	public static var lineGapHeight:Float = 55; // Modify this value if you want lines to have a bigger gap between them. Value is also in pixels.

	// Custom shit, says Kade.
	var lastSprite:AlphaCharacter; // The last character drawn as a sprite.
	var xPosResetted:Bool = false; // Indicator of if the x pos of the sprite was reset. Only true after a line break.
	var lastWasSpace:Bool = false; // Indicates if the last character was a space.

	// Person talking, for dialogue purposes. This seems to be unused, but I'll leave it in for now.
	// Update: Now using this, it's handy.
	public var personTalking:String = 'gf';
	var soundsMap:StringMap<String> = ['gf' => '_GF'];

	// This is a list of the alphabet characters. Whoah.
	var listOAlphabets:List<AlphaCharacter> = new List<AlphaCharacter>();

	// An array defined at the start, that splits a string into individual letters. This code is spaghetti, I swear.
	var splitWords:Array<String> = [];

	// Bold toggle.
	var isBold:Bool = false;

	// The previous position variables.
	var pastX:Float = 0;
	var pastY:Float = 0;

	// On create new Alphabet.
	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false, shouldMove:Bool = false) {
		// Set the pastX and pastY to the current X and Y.
		pastX = x;
		pastY = y;

		// Create new sprite group w/ the X and Y supplied.
		super(x, y);

		// Set the final expected text to the inputted text. This is a private value.
		_finalText = text;
		
		// Also set the text var to it, for public use.
		this.text = text;

		// Take in the bold input.
		isBold = bold;

		//if (text != "") // ... Why is this an edge case? Just have it return if it is.
		if (text == "") return;
		
		// This simple if-else handles dialogue typing. Neat.
		if (typed) startTypedText(); // If it's typed, do it step by step.
		else addText(); // If not, just add the text.
	}

	// This function resets the text & retypes it. Handy.
	public function reType(text) {
		// Loop through the letters ...
		for (i in listOAlphabets)
			remove(i); // ... and remove them.

		// Reset text and _finalText to the text input.
		_finalText = text;
		this.text = text;

		// Remove the last sprite variable.
		lastSprite = null;

		updateHitbox(); // The usual updateHitbox() on the text box.

		// Reset all of these essential variables.
		listOAlphabets.clear();
		x = pastX;
		y = pastY;
		
		// Re-add the text.
		addText();
	}

	// Text adding function.
	public function addText() {
		doSplitWords(); // Split the text into characters., for utility.

		// Make a variable to keep track of where the text cursor is. (Where the next letter will be drawn)
		var xPos:Float = 0; // Make sure it starts at 0.

		var offsetX = letterOffset.get('x');
		var offsetY = letterOffset.get('y');

		// Loop through the characters.
		for (character in splitWords) {
			if (character == " " || character == "-") // Set lastWasSpace, for utility.
				lastWasSpace = true;

			// Make sure the character exists in the alphabet.
			if (AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1) {
				if (lastSprite != null) { // Check if there was a previous sprite.
					xPos = lastSprite.x + lastSprite.width; // If so, set the X position to the X + the width of said sprite. Simple enough.
				}

				if (lastWasSpace) { // Gotta check this, because if it's the case, you gotta add a blank rather than a sprite.
					xPos += spaceWidth; // Implemented my own variable for this. This adds a blank space.
					lastWasSpace = false; // Reset lastWasSpace.
				}

				var letter:AlphaCharacter = new AlphaCharacter(xPos, 0); // Create an instance of the AlphaCharacter class at the current position.
				listOAlphabets.add(letter); // Add that letter to the list of letters.

				// Bold edge case.
				if (isBold) // If bold ...
					letter.createBold(character); // ... make a bold character.
				else
					letter.createLetter(character); // Else, make a light character.

				// Add the letter to the scene.
				add(letter);

				// Apply text offsets.
				// letter.x += offsetX; // First by X ...
				// letter.y += offsetY; // ... then by Y.

				// Set the last sprite to the current letter.
				lastSprite = letter;
			}
		}
	}

	// This is a lazy function, used to split the text into characters.
	function doSplitWords():Void {
		splitWords = _finalText.split(""); // Literally the simplest shit, why the hell is this its own function???
	}

	// Typed text function.
	public function startTypedText():Void {
		// Set the final text to text, as usual, and split the words.
		_finalText = text;
		doSplitWords();

		// Current position in the split words.
		var loopNum:Int = 0;

		// X position and row.
		var xPos:Float = 0;
		var curRow:Int = 0;

		// Create a new timer, that ticks according to the delay variable. Why did Kade add the variable and not use it here? I had to implement it myself.
		new FlxTimer().start(delay, function(tmr:FlxTimer)
		{
			// This code handles line breaks. It's unreadable as fuck, though.
			if (_finalText.fastCodeAt(loopNum) == "\n".code)
			{
				yMulti += 1; // Increment row by one
				xPosResetted = true; // Resetted X trigger
				xPos = 0; // Reset X pos
				curRow += 1; // Also incrementing row by one.
			}

			// Check if space.
			if (splitWords[loopNum] == " ")
			{
				lastWasSpace = true;
			}

			// Pulling out the letter offsets early for optimization reasons.
			var offsetX = letterOffset.get('x'); 
			var offsetY = letterOffset.get('y');

			// Really, kade??? Using an if-else to fix an edge case? Just use the older one, damn.

		/*  #if (haxe >= "4.0.0")
			var isNumber:Bool = AlphaCharacter.numbers.contains(splitWords[loopNum]);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(splitWords[loopNum]);
			#else
			var isNumber:Bool = AlphaCharacter.numbers.indexOf(splitWords[loopNum]) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(splitWords[loopNum]) != -1;
			#end  */

			// Check if the character is a number/symbol, and plug the result into an indicator.
			var isNumber:Bool = AlphaCharacter.numbers.indexOf(splitWords[loopNum]) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(splitWords[loopNum]) != -1;

			// Basically, this checks if the character is a letter.
			if (AlphaCharacter.alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1 || isNumber || isSymbol) {
				if (lastSprite != null && !xPosResetted) { // If there's a previous sprite, and the x position isn't reset ...
					lastSprite.updateHitbox(); // ... Update the hitbox.
					xPos += lastSprite.width + 3; // And also, increase the X position.
				} else {
					xPosResetted = false; // If the X position was reset, just disable the toggle.
				}

				if (lastWasSpace) { // Check if there was a space before the character.
					xPos += spaceWidth; // If so, add some blank space.
					lastWasSpace = false; // Also, disable the trigger.
				}

				var letter:AlphaCharacter = new AlphaCharacter(xPos, lineGapHeight * yMulti); // Creates a new AlphaCharacter at the current text cursor position.
					letter.row = curRow; // Set the letter's row to the current row. This is very bad.
				listOAlphabets.add(letter); // Add the letter to the list of characters, as well.
				
				if (isBold) { // If the letter is bold ...
					letter.createBold(splitWords[loopNum]); // ... create a bold character.
				} else {
					if (isNumber) { // If the character is a number ...
						letter.createNumber(splitWords[loopNum]); // ... make a number.
					} else if (isSymbol) { // Lastly, if the character is a symbol ...
						letter.createSymbol(splitWords[loopNum]); // ... make a symbol.
					} else { // Of course, if none are the case, it's an ordinary letter ...
						letter.createLetter(splitWords[loopNum]); // ... so make a letter.
					}
				}

				if (FlxG.random.bool(40)) // 40% chance of playing a sound.
				{
					// This picks out the sound from the map.
					var pickedSoundTag:String = soundsMap.get(personTalking); // Variable used to be named daSound. Come on, really?

					// Play a random sound with the sound tag picked.
					FlxG.sound.play(Paths.soundRandom(pickedSoundTag, 1, 4));
				}

				// Offset letters by a letter offset, preset by me.
				letter.x += offsetX;
				letter.y += offsetY;

				// Finally, add the letter to the scene ...
				add(letter);

				// ... and set the last sprite to the letter.
				lastSprite = letter;
			}

			loopNum += 1; // Increment the current index of the writing by 1.

			tmr.time = FlxG.random.float(delay * 0.2, delay * 1.8); // Randomly change the time of the timer...? I'll have this revolve around the delay, I guess.
		}, splitWords.length);
	}

	// Update function override, runs every frame.
	override function update(elapsed:Float) {
		if (isMenuItem) { // Remap the position of the item to the target Y. I don't know why it does this...?
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			// Is it *ever* a menu item anyway? What's this hardcoded dogshit?
			// So apparently this is used for the freeplay menu. WTF?
			y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * 0.48), 0.30);
		}

		// Please ignore the above if statement. Just, never use isMenuItem. It's bad. Please.
		// - Rushtoxin

		super.update(elapsed); // super.update(elapsed); Runs the update function of the class this extends.
	}
}


class AlphaCharacter extends FlxSprite {
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz"; // Ah yes, the typical alphabet string.

	public static var numbers:String = "1234567890"; // All numbers, as well.

	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?"; // These are the allowed symbols.

	public var row:Int = 0; // Current row of the character. Kinda bad, ngl.
	
	var lineGapHeight:Float = Alphabet.lineGapHeight;

	public function new(x:Float, y:Float) {
		// On create, make a sprite at the same position.
		super(x, y);

		// Get the texture from the alphabet image.
		var tex = Paths.getSparrowAtlas('alphabet');
		frames = tex; // ... and set the frames to the texture.

		antialiasing = true; // Antialiasing makes the images look better.
	}

	public function createBold(letter:String) {
		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24); // Add an animation, which holds the image for the bold letter.
		animation.play(letter); // Also, play the animation by default.
		updateHitbox(); // The necessary hitbox update.
	}

	public function getCase(letter:String):String {
		if (letter.toLowerCase() != letter) {
			return 'capital';
		} else {
			return 'lowercase';
		}
	}

	public function createLetter(letter:String):Void
	{
		var letterCase:String = getCase(letter); // Decided to make this a function, for neatness.

		animation.addByPrefix(letter, letter + " " + letterCase, 24); // String together the letter with it's case and add an animation.
		animation.play(letter); // Play the letter animation by default.
		updateHitbox(); // Necessary hitbox update.

		// Log the row. This isn't necessary at the moment.
		// FlxG.log.add('the row' + row);

		y = (110 - height); // Hardcoding jazz
		y += row * lineGapHeight; // Originally was row * 60, implemented my lineGapHeight variable.
	}

	public function createNumber(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24); // This one simply just grabs the number animation, since numbers don't have a case
		animation.play(letter); // Play the letter animation by default
		updateHitbox(); // Necessary hitbox update.
	}

	public function createSymbol(letter:String)
	{
		var symbolAnimationNames:StringMap<String> = [
			"'" => 'apostraphie',
			"?" => 'question mark',
			"!" => 'exclamation point',
			" " => 'space',
			"." => 'period',
			"_" => '_' /* The underscore is here for an edge case, and it overall optimizes it so it doesn't matter. */
		]; // This maps special symbols to their names.

		switch (letter) // This is hardcoded, but I'll improve it anyway.
		{
			case '.', '_':
				animation.addByPrefix(letter, symbolAnimationNames.get(letter), 24); // Grab the animation, with the tag from the variable.
				animation.play(letter); // Play the animation.
				y += 50; // Offset specifically for periods & underscores.
			case "'", "?", "!":
				animation.addByPrefix(letter, symbolAnimationNames.get(letter), 24); // Special case, grab the tag and don't offset.
				animation.play(letter); // Play the animation.
			default:
				animation.addByPrefix(letter, letter, 24); // Default to just using the letter as the tag.
				animation.play(letter); // Play the animation.
		}

		// Managed to save 30+ lines with the switch optimizations. Dayum.

		updateHitbox(); // Necessary hitbox update.
	}
}

// END OF SCRIPT