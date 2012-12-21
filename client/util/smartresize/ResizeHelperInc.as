// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ActionScript include
/***************  BEGIN: smart resize code chunk ***************/
import util.smartresize.Measurements;
import util.smartresize.SmartResizeHelper;

// UNDONE: Move this to an include?
[Inspectable(arrayType="mx.states.State")]
[ArrayElementType("mx.states.State")]
public function set size_states(a:Array): void {
	super.states = a;
}

private var _srh:SmartResizeHelper;
public function get smartResizeHelper(): SmartResizeHelper {
	return _srh;
}

public override function setActualSize(w:Number, h:Number):void {
	// Adjust the state accordingly
	_srh.adjustStateForSize(w,h);
	super.setActualSize(w,h);
}

public function set ignoreheight(f:Boolean): void {
	_srh.ignoreHeight = f;
}

public function getMeasurementsForCurrentState(): Measurements {
	_srh.measureChildren();
	_srh.measuring = true;
	//trace(this + ".super.measure(" + currentState + ")");
	super.measure();
	//trace(this + ".super.measure(" + currentState + ") returned: " + super.measuredWidth + ", " + super.measuredHeight);
	_srh.measuring = false;
	var ms:Measurements = new Measurements();
	ms.width = super.measuredWidth;
	ms.height = super.measuredHeight;
	ms.minWidth = super.measuredMinWidth;
	ms.minHeight = _srh.ignoreHeight ? 0 : super.measuredMinHeight;
	return ms;
}

override protected function measure():void {
	_srh.measure();
}

override public function invalidateDisplayList():void {
	// trace(this + ".invalidateDisplayList()");
	_srh.invalidateDisplay();
	super.invalidateDisplayList();
}

override public function invalidateSize():void {
	// trace(this + ".invalidateSize()");
	_srh.invalidateSize();
	super.invalidateSize();
}

override public function validateDisplayList():void {
	_srh.validateDisplayList();
	super.validateDisplayList();
}

override public function get measuredWidth():Number {
	if (_srh.measuring) return super.measuredWidth;
	return _srh.measuredWidth;
}

override public function get measuredHeight():Number {
	if (_srh.measuring) return super.measuredHeight;
	return _srh.measuredHeight;
}

override public function get measuredMinWidth():Number {
	if (_srh.measuring) return super.measuredMinWidth;
	return _srh.measuredMinWidth;
}

override public function get measuredMinHeight():Number {
	if (_srh.measuring) return super.measuredMinHeight;
	return _srh.measuredMinHeight;
}

// Add our text_ properties as state overrides	   
override public function initialize():void
{
	_srh.initialize();
	super.initialize();
}
	
/***************  END: smart resize code chunk ***************/
