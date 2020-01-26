module arc.internals.input.signals; 

import
	arc.math.point,
	arc.types;
	
import tango.core.Signal : Signal;

//
// signals
//
/// Input signals 
class InputSignals
{
	///
	Signal!(int) keyDown;
	///
	Signal!(int) keyUp;
	
	///
	Signal!(int, Point) mouseButtonUp;
	
	///
	Signal!(int, Point) mouseButtonDown;
	
	///
	Signal!(Point) mouseMove; 

	///
	Signal!(ubyte, ubyte) joyButtonDown;
	
	///
	Signal!(ubyte, ubyte) joyButtonUp;
	
	///
	Signal!(ubyte, ubyte, arcfl) joyAxisMove;
	
	// this signal is emitted when the number of joysticks that are plugged in changes
	// the first parameter is the previous number of joysticks, and the second is the current
	// on a hotplug event, nothing else is done but emitting this signal, it is up to the user to respond
	Signal!(ubyte, ubyte) joyHotPlug; 
}

InputSignals signals;

static this()
{
	signals = new InputSignals;
}

