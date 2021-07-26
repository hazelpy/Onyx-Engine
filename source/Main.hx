package;

import openfl.display.BlendMode;
import openfl.text.TextFormat;
import openfl.display.Application;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;

/*
 = ONYX ENGINE MAIN.HX SCRIPT
 - CREDITS TO KADE FOR ORIGINAL SCRIPT
 = COMMENTED BY RUSHTOXIN
*/

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 120; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var watermarks = true; // Whether to put watermarks literally anywhere

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		// Quick checks

		// What even does this do???
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		// Initialization
		if (stage != null) {
			init();
		} else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	public static var webmHandler:WebmHandler;

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		// Setup the game.
		setupGame();
	}

	private function setupGame():Void
	{
		// Stage dimensions
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		// Edge case of -1
		if (zoom == -1)
		{
			// Calculate zoom automatically.
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;

			// Minimum of the two.
			zoom = Math.min(ratioX, ratioY);

			// Ceil stage dimensions divided by zoom for actual game dimensions.
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		// new FlxGame if on C++
		#if cpp
		initialState = Caching;
		game = new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen);
		#else
		game = new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen);
		#end

		// Add the game as child
		addChild(game);
		
		// If not mobile case FPS counter
		#if !mobile
		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);
		toggleFPS(FlxG.save.data.fps);
		#end
	}

	// Initialize game & FPS counter
	var game:FlxGame;
	var fpsCounter:FPS;

	// FPS Counter Visibility
	public function toggleFPS(fpsEnabled:Bool):Void {
		fpsCounter.visible = fpsEnabled;
	}

	// FPS Counter Coloring
	public function changeFPSColor(color:FlxColor)
	{
		fpsCounter.textColor = color;
	}

	// FPS Cap setter
	public function setFPSCap(cap:Float)
	{
		openfl.Lib.current.stage.frameRate = cap;
	}

	// FPS Cap getter
	public function getFPSCap():Float
	{
		return openfl.Lib.current.stage.frameRate;
	}

	// Current FPS getter
	public function getFPS():Float
	{
		return fpsCounter.currentFPS;
	}
}
