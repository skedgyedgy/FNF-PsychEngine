package;

import flixel.system.scaleModes.*;
import flixel.system.scaleModes.FillScaleMode;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxBasic;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	public static var musInstance:MusicBeatState;
	#if desktop
	public var scaleRatio = ClientPrefs.getResolution()[1] / 720;
	var modeRatio:RatioScaleMode;
	var modeStage:StageSizeScaleMode;
	#end

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();
		musInstance = this;
		// Custom made Trans out
		
		#if desktop
		modeRatio = new RatioScaleMode();
		modeStage = new StageSizeScaleMode();
		#end

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}
	
	#if (VIDEOS_ALLOWED && windows)
	override public function onFocus():Void
	{
		FlxVideo.onFocus();
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		FlxVideo.onFocusLost();
		super.onFocusLost();
	}
	#end

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		// if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen; no

		if (FlxG.keys.pressed.ALT && FlxG.keys.justPressed.ENTER && FlxG.fullscreen) {
			if (FlxG.fullscreen && ClientPrefs.screenScaleMode == "ADAPTIVE") FlxG.fullscreen = false;
			FlxG.save.data.fullscreen = FlxG.fullscreen;
		}

		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor(((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / Conductor.stepCrochet);
	}

	public static function switchState(nextState:FlxState) {
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if(!FlxTransitionableState.skipNextTransIn) {
			#if sys
			ArtemisIntegration.toggleFade (true);
			#end
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if(nextState == FlxG.state) {
				CustomFadeTransition.finishCallback = function() {
					musInstance.fixAspectRatio();
					#if sys
					ArtemisIntegration.toggleFade (false);
					#end
					FlxG.resetState();
				};
				//trace('resetted');
			} else {
				CustomFadeTransition.finishCallback = function() {
					musInstance.fixAspectRatio();
					#if sys
					ArtemisIntegration.toggleFade (false);
					#end
					FlxG.switchState(nextState);
				};
				//trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState() {
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}

	public function fixAspectRatio() {
		// options.GraphicsSettingsSubState.onChangeRes();

		#if desktop
		if (ClientPrefs.screenScaleMode == "LETTERBOX") {
			FlxG.scaleMode = new RatioScaleMode (false);
		} else if (ClientPrefs.screenScaleMode == "PAN") {
			FlxG.scaleMode = new RatioScaleMode (true);
		} else if (ClientPrefs.screenScaleMode == "STRETCH") {
			FlxG.scaleMode = new FillScaleMode ();
		} else if (ClientPrefs.screenScaleMode == "ADAPTIVE") {
			FlxG.scaleMode = modeStage;
		}
		#end
	}
}
