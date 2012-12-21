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
package {
	import fl.controls.Button;
	import fl.controls.ComboBox;
	import fl.controls.Label;
	import fl.controls.Slider;
	import fl.data.DataProvider;
	import fl.events.SliderEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import net.hires.debug.Stats;
	
	import org.bytearray.smtp.encoding.JPEGEncoder;
	
	[SWF(width="1200", height="1000", backgroundColor="0xe0e0e0", frameRate="120")]
	
	public class BokehTester extends Sprite {
		
		private var slider1:Slider;
		private var slider2:Slider;
		private var slider3:Slider;
		private var slider4:Slider;
		private var boke:Bokeh;
		private var combo1:ComboBox;
		private var combo2:ComboBox;
		private var combo3:ComboBox;
		private var combo4:ComboBox;
		private var saveBtn:Button;
		private var label1:Label;
		private var label2:Label;
		private var label3:Label;
		private var label4:Label;
		private var label5:Label;
		private var label6:Label;
		private var label7:Label;
		private var label8:Label;
		private var output:Bitmap;
		private var outputBD:BitmapData;
		
		private var stats:Stats;
		private var pic:Loader;
		
		private const LIVE_DRAGGING:Boolean=false;
		
		public function BokehTester()	{
			init("pic1");
			
			label1=new Label();
			label1.text="Threshold";
			addChild(label1);
			slider1=new Slider();
			slider1.minimum=0;
			slider1.maximum=0xffffff;
			addChild(slider1);
			
			label2=new Label();
			label2.text="Radius";
			addChild(label2);
			slider2=new Slider();
			slider2.minimum=1;
			slider2.maximum=150;
			addChild(slider2);
			
			label3=new Label();
			label3.text="Intensity";
			addChild(label3);
			slider3=new Slider();
			slider3.snapInterval=.01;
			slider3.minimum=0;
			slider3.maximum=1;
			addChild(slider3);
			
			label4=new Label();
			label4.text="Lens rotation";
			addChild(label4);
			slider4=new Slider();
			slider4.snapInterval=1;
			slider4.minimum=-180;
			slider4.maximum=180;
			addChild(slider4);
			
			slider1.liveDragging=slider2.liveDragging=LIVE_DRAGGING;
			slider3.liveDragging=slider4.liveDragging=LIVE_DRAGGING;
			
			slider1.addEventListener(SliderEvent.CHANGE, onslider1);
			slider2.addEventListener(SliderEvent.CHANGE, onslider2);
			slider3.addEventListener(SliderEvent.CHANGE, onslider3);
			slider4.addEventListener(SliderEvent.CHANGE, onslider4);

			label5=new Label();
			label5.text="Source picture";
			addChild(label5);
			combo1=new ComboBox();
			var a:Array=[
				{label:"Lake view", 	value:"pic1"},
				{label:"Bee", 	value:"bee"},
				{label:"City by night", value:"pic2"},
				{label:"Mystic", 		value:"pic3"},
				{label:"Big pic 1", 	value:"p1"},
				{label:"Big pic 2", 	value:"p2"},
				{label:"Big pic 3", 	value:"p3"},
				{label:"Big pic 9", 	value:"p9"},
				{label:"Big pic 12", 	value:"p12"},
			];
			var dp:DataProvider=new DataProvider(a);
			combo1.dataProvider=dp;
			addChild(combo1);
			combo1.addEventListener(Event.CHANGE, oncombo1);
			
			label6=new Label();
			label6.text="Mode";
			addChild(label6);
			combo2=new ComboBox();
			var a2:Array=[
				{label:"Real Bokeh", 	value:"real"},
				{label:"Wet lens", 		value:"highlights_only"}
			];
			var dp2:DataProvider=new DataProvider(a2);
			combo2.dataProvider=dp2;
			addChild(combo2);
			combo2.addEventListener(Event.CHANGE, oncombo2);
			
			label7=new Label();
			label7.text="Lens type";
			addChild(label7);
			combo3=new ComboBox();
			var a3:Array=[
				{label:"Circular", 	value:BokehLensType.CIRCULAR},
				{label:"9-sides", 	value:BokehLensType.FACETED9},
				{label:"8-sides", 	value:BokehLensType.FACETED8},
				{label:"7-sides", 	value:BokehLensType.FACETED7},
				{label:"6-sides", 	value:BokehLensType.FACETED6},
				{label:"5-sides", 	value:BokehLensType.FACETED5},
				{label:"4-sides", 	value:BokehLensType.FACETED4},
				{label:"3-sides", 	value:BokehLensType.FACETED3},
				{label:"Heart", 	value:BokehLensType.SHAPE_HEART},
				{label:"Diamond", 	value:BokehLensType.SHAPE_DIAMOND},
				{label:"Star", 		value:BokehLensType.SHAPE_STAR},
				{label:"Star 2", 		value:BokehLensType.SHAPE_STAR2},
				{label:"Sparkle", 		value:BokehLensType.SHAPE_SPARKLE},
				{label:"Sparkle 2", 		value:BokehLensType.SHAPE_SPARKLE2}
			];
			var dp3:DataProvider=new DataProvider(a3);
			combo3.dataProvider=dp3;
			addChild(combo3);
			combo3.addEventListener(Event.CHANGE, oncombo3);
			
			label8=new Label();
			label8.text="Style";
			addChild(label8);
			combo4=new ComboBox();
			var a4:Array=[
				{label:"Vivid", 	value:BokehStyle.VIVID},
				{label:"Sharp", 	value:BokehStyle.SHARP},
				{label:"Creamy", 	value:BokehStyle.CREAMY}
			];
			var dp4:DataProvider=new DataProvider(a4);
			combo4.dataProvider=dp4;
			addChild(combo4);
			combo4.addEventListener(Event.CHANGE, oncombo4);
			
			saveBtn=new Button();
			saveBtn.label="Save";
			saveBtn.addEventListener(MouseEvent.CLICK, save);
			addChild(saveBtn);
			
			stats=new Stats();
			addChild(stats);
		}
		private function init($picName:String):void {
			try {
				removeChild(output);
				removeChild(boke);
			} catch(e:Error) {}
			
			pic=null;
			pic=new Loader();
			pic.contentLoaderInfo.addEventListener(Event.COMPLETE, onloaded);
			pic.load(new URLRequest("assets/"+$picName+".jpg"));
		}
		private function onloaded(event:Event):void {
			var bd:BitmapData=new BitmapData(pic.width, pic.height);
			bd.draw(pic);
			boke=new Bokeh(bd);
			outputBD=boke.render();
			output=new Bitmap(outputBD);
			addChild(output);
			
			positionUI();
		}
		private function positionUI():void {
			if(pic.width>800 || pic.height>600) {
				var horizontal:Boolean = pic.width>pic.height ? true : false;
				var fx:Number;
				if(horizontal) {
					fx=pic.width/800;
					pic.width=output.width=800;
					pic.height=output.height=output.height/fx;
				} else {
					fx=pic.height/600;
					pic.height=output.height=600;
					pic.width=output.width=output.width/fx;
				}
			}
			slider1.y=label1.y=pic.height+20;
			slider2.y=label2.y=pic.height+40;
			slider3.y=label3.y=pic.height+60;
			slider4.y=label4.y=pic.height+80;
			label1.y-=5;
			label2.y-=5;
			label3.y-=5;
			label4.y-=5;
			label1.width=label2.width=label3.width=label4.width=100;
			label1.x=label2.x=label3.x=label4.x=210;
			slider1.x=slider2.x=slider3.x=slider4.x=20;
			slider1.width=slider2.width=slider3.width=slider4.width=180;
			
			saveBtn.x=slider4.x;
			saveBtn.y=slider4.y+40;
			
			combo1.x=combo2.x=combo3.x=combo4.x=300;
			combo1.width=combo2.width=combo3.width=combo4.width=200;
			combo1.y=pic.height+10;
			combo2.y=pic.height+40;
			combo3.y=pic.height+70;
			combo4.y=pic.height+100;

			label5.x=label6.x=label7.x=label8.x=508;
			
			label5.y=combo1.y+3;
			label6.y=combo2.y+3;
			label7.y=combo3.y+3;
			label8.y=combo4.y+3;
			
			setChildIndex(stats, numChildren-1);
			
			slider1.value=boke.threshold;
			slider2.value=boke.radius;
			slider3.value=boke.intensity;
			slider4.value=boke.lensRotation;
			
			combo2.selectedIndex=0;
			combo3.selectedIndex=0;
			combo4.selectedIndex=0;
		}
		private function oncombo1(event:Event):void {
			init(combo1.selectedItem.value);
			positionUI();
		}
		private function oncombo2(event:Event):void {
			boke.mode=combo2.selectedItem.value;
		}
		private function oncombo3(event:Event):void {
			boke.lensType=combo3.selectedItem.value;
		}
		private function oncombo4(event:Event):void {
			boke.style=combo4.selectedItem.value;
		}
		private function onslider1(event:SliderEvent):void {
			boke.threshold=slider1.value;
		}
		private function onslider2(event:SliderEvent):void {
			boke.radius=slider2.value;
		}
		private function onslider3(event:SliderEvent):void {
			boke.intensity=slider3.value;
		}
		private function onslider4(event:SliderEvent):void {
			boke.lensRotation=slider4.value;
		}
		public function save(event:Event=null):void {
			var encoder:JPEGEncoder = new JPEGEncoder(80);
			var rawBytes:ByteArray = encoder.encode(outputBD);
			
			var saveFileRef:FileReference = new FileReference();
			saveFileRef.save(rawBytes, combo1.selectedLabel.split(" ").join("_")+".jpg");
		}
	}
}
