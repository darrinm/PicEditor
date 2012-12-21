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
package documentObjects {
	import de.polygonal.math.PM_PRNG;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import mx.containers.ViewStack;
	import mx.core.Application;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.resources.ResourceBundle;
	import mx.resources.ResourceManager;
	
	import util.CollageDocTemplateMgr;
	
	public class PhotoGrid extends DocumentObjectBase {
		static private const kcCellsMax:int = 1000;
		private var _cRows:uint = 0;
		private var _cCols:uint = 0;
		private var _cRowsLast:uint = uint.MAX_VALUE;
		private var _cColsLast:uint = uint.MAX_VALUE;
		private var _nGap:Number = 0.01;
		private var _coBackground:uint = 0x333333;
		private var _nBackgroundAlpha:Number = 1.0;
		private var _nKookiness:Number = 0.0;
		private var _fPersisted:Boolean = false;
		private var _nProportions:Number = 50;
		
		private var _cxPreferredWidth:Number = 0;
		private var _cyPreferredHeight:Number = 0;
		
		public static const SERIALIZED_PIK:String = "pkd:";
		public static const DIRECT_FID:String = "fid:"; // OBSOLETE

	    [ResourceBundle("templatesXmlText")] static private var _srb:ResourceBundle;
		
		// Template stuff
		private var _strTemplate:String;
		private var _cntrTemplate:Container;
		private static var s_vstkTemplates:ViewStack;

		private var _nBaseStatus:Number = DocumentStatus.Static;
		
		// PhotoGrid supports FitMethod.SNAP_TO_EXACT_SIZE and FitMethod.SNAP_TO_MAX_WIDTH_HEIGHT
		private var _nFitMethod:Number = FitMethod.SNAP_TO_EXACT_SIZE;
		private var _cxFit:Number = 0;
		private var _cyFit:Number = 0;
		
		private var _cxCell:Number;
		private var _cyCell:Number;
		private var _cxyGap:Number;
		
		private var _xmlDocTemplate:XML = null;
		private var _dctMapTemplateToLocalAsset:Object = null;
		private var _fCompressed:Boolean = false;
		
		private var _obDocTemplateState:Object = null;

		private var _strAssetRefs:String = "";
		[Bindable] public var templateName:String; // Used for logging purposes
		
		override public function get typeName(): String {
			return "Photo Grid";
		}
		
		public override function get serializableProperties(): Array {
			return super.serializableProperties.concat([
				"numRows", "numColumns", "gap", "backgroundColor", "backgroundAlpha", "templateName",
				"kookiness", "proportions", "fitWidth", "fitHeight", "fitMethod", "template", "preferredWidth", "preferredHeight"
			]);
		}
		
		
		public function set assetRefs(str:String): void {
			// Ignore this - we need this so that our set properties op can see the asset refs hidden in our template XML
			_strAssetRefs = str;
		}
		
		public function get assetRefs(): String {
			return _strAssetRefs;
		}
		
		public function GetAutoFillTargets(): Array {
			var atgt:Array = [];
			for (var i:Number = 0; i < numChildren; i++) {
				var tgt:Target = getChildAt(i) as Target;
				if (tgt && tgt.visible)
					atgt.push(tgt);
			}
			return atgt;
		}
		
		public function get usingDocTemplate(): Boolean {
			return _strTemplate != null && _strTemplate.length > 4 && (_strTemplate.substr(0,4) == (DIRECT_FID) || _strTemplate.substr(0,4) == (SERIALIZED_PIK));
		}

		[Bindable]
		public function set template(strTemplate:String): void {
			if (strTemplate != _strTemplate) {
				_strTemplate = strTemplate;
				_cntrTemplate = null;
				if (usingDocTemplate) {
					// Ignore the apply
					// our children are already set up (by setting appliedTemplate)
				} else {
					if (s_vstkTemplates == null)
						LoadTemplates(null);

					baseStatus = DocumentStatus.Static;
					if (_strTemplate) {
						_cntrTemplate = Container(s_vstkTemplates.getChildByName(_strTemplate));
						s_vstkTemplates.selectedChild = _cntrTemplate;
					}
					Invalidate();
				}
			}
		}
		
		public function get template(): String {
			return _strTemplate;
		}
		
		[Bindable]
		public function set appliedTemplate(strTemplate:String): void {
			template = strTemplate;
			if (usingDocTemplate) {
				LoadDocTemplate();
			}
		}
		
		public function get appliedTemplate(): String {
			return template;
		}
		
		private function SetTemplateXml(xmlTemplate:XML, dctMapTemplateToLocalAsset:Object, fCompressed:Boolean=false): void {
			// Got the template and properties. Go on our merry way.
			_xmlDocTemplate = xmlTemplate;
			_dctMapTemplateToLocalAsset = dctMapTemplateToLocalAsset;
			_fCompressed = fCompressed;
			baseStatus = DocumentStatus.Loaded;

			// Make sure we start with the right aspect ratio
			preferredWidth = Number(_xmlDocTemplate.@width);
			preferredHeight = Number(_xmlDocTemplate.@height);

			var nRatio:Number = preferredWidth / preferredHeight;
			proportions = 100 * nRatio / (nRatio + 1);

			Invalidate();
				
			// Validate now so that our children get created before we play back any operations on the children
			Validate();
		}
		
		private function LoadDocTemplate(): void {
			// Load a document template, given a fid
			baseStatus = DocumentStatus.Loading;
			_dctMapTemplateToLocalAsset = null;
			_fCompressed = false;
			
			var strSelectingTemplate:String = _strTemplate;
			var fnComplete:Function = function(nError:Number, strError:String, xmlTemplate:XML=null, dctProperties:Object=null): void {
				if (strSelectingTemplate != _strTemplate) return; // Already selected a new template
				if (nError != PicnikService.errNone) {
					baseStatus = DocumentStatus.Error;
					trace("load error: " + strError);
				} else {
					SetTemplateXml(xmlTemplate, CollageDocTemplateMgr.GetAssetToAssetMap(document, dctProperties));
				}
			}
			
			var strData:String = _strTemplate.substr(PhotoGrid.DIRECT_FID.length);
			var strType:String = _strTemplate.substr(0,PhotoGrid.DIRECT_FID.length);
			if (strType == DIRECT_FID) {
				// Obsolete. Shipped it in admin mode only. If we change this, docs created with templates by admins before the update will be broken
				CollageDocTemplateMgr.GetDocumentTemplate(strData, fnComplete, this);
			} else if (strType == SERIALIZED_PIK) {
				var obData:Object = CollageDocTemplateMgr.DecodeDocTemplate(strData);
				SetTemplateXml(obData.xml, obData.dctMapTemplateToLocalAsset, obData.fCompressed);
			}
		}
		
		[Bindable]
		public function set numRows(cRows:uint): void {
			_cRows = cRows;
			UpdateDimensions();
		}

		public function get numRows(): uint {
			return _cRows;
		}

		[Bindable]
		public function set numColumns(cColumns:uint): void {
			_cCols = cColumns;
			UpdateDimensions();
		}

		public function get numColumns(): uint {
			return _cCols;
		}

		[Bindable]
		public function set preferredWidth(n:Number): void {
			var fUpdateFit:Boolean = (_cxFit == _cxPreferredWidth);
			_cxPreferredWidth = n;
			if (fUpdateFit) fitWidth = n;
		}

		public function get preferredWidth(): Number {
			return _cxPreferredWidth;
		}
		
		[Bindable]
		public function set preferredHeight(n:Number): void {
			var fUpdateFit:Boolean = (_cyFit == _cyPreferredHeight);
			_cyPreferredHeight = n;
			if (fUpdateFit) fitHeight = n;
		}

		public function get preferredHeight(): Number {
			return _cyPreferredHeight;
		}
		
		[Bindable]
		public function set gap(nGap:Number): void {
			_nGap = nGap;
			UpdateDimensions();
		}

		public function get gap(): Number {
			return _nGap;
		}
		
		[Bindable]
		public function set backgroundColor(coBackground:uint): void {
			_coBackground = coBackground;
			Invalidate();
		}

		public function get backgroundColor(): uint {
			return _coBackground;
		}
		
		[Bindable]
		public function set backgroundAlpha(nAlpha:Number): void {
			_nBackgroundAlpha = nAlpha;
			Invalidate();
		}

		public function get backgroundAlpha(): Number {
			return _nBackgroundAlpha;
		}
		
		[Bindable]
		public function set kookiness(nKookiness:Number): void {
			_nKookiness = nKookiness;
			Invalidate();
		}

		public function get kookiness(): Number {
			return _nKookiness;
		}
		
		[Bindable]
		public function set proportions(nProportions:Number): void {
			_nProportions = nProportions;
			UpdateDimensions();
		}

		public function get proportions(): Number {
			return _nProportions;
		}
		
		[Bindable]
		public function set fitWidth(cxFit:Number): void {
			_cxFit = cxFit;
			UpdateDimensions();
		}

		public function get fitWidth(): Number {
			return _cxFit;
		}
		
		[Bindable]
		public function set fitHeight(cyFit:Number): void {
			_cyFit = cyFit;
			UpdateDimensions();
		}

		public function get fitHeight(): Number {
			return _cyFit;
		}
		
		[Bindable]
		public function set fitMethod(nFitMethod:Number): void {
			_nFitMethod = nFitMethod;
			UpdateDimensions();
		}

		public function get fitMethod(): Number {
			return _nFitMethod;
		}
		
		// DEPRECATED: now using fitWidth instead
		override public function set unscaledWidth(cx:Number): void {
			super.unscaledWidth = cx;
			fitWidth = cx;
		}
		
		// DEPRECATED: now using fitHeight instead
		override public function set unscaledHeight(cy:Number): void {
			super.unscaledHeight = cy;
			fitHeight = cy;
		}
		
		private function UpdateDimensions(): void {
			if (numColumns == 0 || numRows == 0) return; // invalid, don't bother setting dimensions yet.
			_cxyGap = Math.round(Math.min(fitWidth, fitHeight) * _nGap);
			_cxCell = (fitWidth - ((numColumns + 1) * _cxyGap)) / numColumns;
			_cyCell = (fitHeight - ((numRows + 1) * _cxyGap)) / numRows;
			if (_nFitMethod == FitMethod.SNAP_TO_MAX_WIDTH_HEIGHT) {
				var nRatio:Number = _nProportions / (100 - _nProportions);
				if (_cyCell * nRatio > _cxCell)
					_cyCell = _cxCell / nRatio;
				else
					_cxCell = _cyCell * nRatio;
			}
			
			// Resize the PhotoGrid now that we've chosen cell sizes
			super.unscaledWidth = (numColumns * _cxCell) + ((numColumns + 1) * _cxyGap);
			super.unscaledHeight = (numRows * _cyCell) + ((numRows + 1) * _cxyGap);
			Invalidate();
		}
		
		private function CopyTargetDimensions(tgtSrc:Target, tgtDest:Target): void {
			const kstrCopyProps:Array = ["x", "y", "scaleX", "scaleY", "rotation", "circular"];
			for each (var strKey:String in kstrCopyProps) {
				tgtDest[strKey] = tgtSrc[strKey];
			}
		}
		
		private function ApplyDocTemplate(): void {
			if (_xmlDocTemplate == null) return;
			if (baseStatus == DocumentStatus.Error) return;

			var i:Number;
			
			var nPrevWidth:Number;
			var nPrevHeight:Number;
			
			// First, check to see what has changed
			var obNewDocTemplateState:Object = {templateXML:_xmlDocTemplate, width:unscaledWidth, height:unscaledHeight};
			
			var fReset:Boolean = false;
			var fRescale:Boolean = false;
			
			if (_obDocTemplateState == null || obNewDocTemplateState.templateXML != _obDocTemplateState.templateXML) {
				// Redo everything
				fReset = true;
				fRescale = true;
			} else if (_obDocTemplateState.width != obNewDocTemplateState.width || _obDocTemplateState.height != obNewDocTemplateState.height) {
				fRescale = true;
			}
			
			if (fReset) {
				var atgtPrev:Array = [];
				ExtractTargets(this, atgtPrev);
				// Remove all other children
				while (numChildren > 0) removeChildAt(numChildren - 1);
				
				// Now we have a clean slate and an array of potentially reusable targets
				
				// Walk through our doc and create objects as needed.
				if (!ImageDocument.DeserializeDocumentObjects2(this, _xmlDocTemplate.Objects[0])) {
					trace("error deserializing document objects");
					baseStatus = DocumentStatus.Error;
				}
				
				if (baseStatus == DocumentStatus.Error) return;
				
				// Reuse target children, remove the rest.
				var atgtNew:Array = [];
				FindTargets(this, atgtNew);
				
				// Replace the new targets with the prevoius targets
				// Create nicely named targets when needed.
				
				var tgtNew:Target;
				
				while (atgtPrev.length < atgtNew.length) {
					// Create filler items
					tgtNew = new Target();
					tgtNew.name = name + "_target" + atgtPrev.length;
					tgtNew.crop = true;
					atgtPrev.push(tgtNew);
				}
				
				// Now atgtPrev is at least as large as atgtNew (maybe larger)
				for (i = 0; i < atgtPrev.length; i++) {
					var tgtPrev:Target = atgtPrev[i];
					if (i < atgtNew.length) {
						// Do the swap-a-roo
						tgtNew = atgtNew[i];
						// Repalce tgtNew with tgtPrev
						// Set tgtPrev dimensions/rotation to be the same as tgtNew
						// Make sure it is visible
						var iPos:Number = tgtNew.parent.getChildIndex(tgtNew);
						var dobcParent:DisplayObjectContainer = tgtNew.parent;
						dobcParent.removeChildAt(iPos);
						dobcParent.addChildAt(tgtPrev, iPos);
						CopyTargetDimensions(tgtNew, tgtPrev);
						tgtPrev.visible = true;
					} else {
						tgtPrev.visible = false;
						addChild(tgtPrev);
					}
				}
				
				// Rename the new targets
				for (i = 0; i < atgtNew.length; i++) {
					// Targets must be named in this reliable way so references persisted in the
					// undo/redo history will be resolvable after the document is deserialized.
					atgtNew[i].name = name + "_target" + i;
					atgtNew[i].crop = true;
				}
				
				// Now we have real asset refs for all of our assets. Find objects with assets
				FixChildAssetRefs(this, _dctMapTemplateToLocalAsset);
				if (_fCompressed) {
					SetPhotosToSwfs(this);
				}
				LocalizeText(this)
				
				nPrevWidth = Number(_xmlDocTemplate.@width);
				nPrevHeight = Number(_xmlDocTemplate.@height);
			} else {
				nPrevWidth = _obDocTemplateState.width;
				nPrevHeight = _obDocTemplateState.height;
			}
			
			if (fRescale) {
				// use unscaled width and height for our new dimensions
				var nXFact:Number = unscaledWidth / nPrevWidth; // Multiply doc width by this to get real width
				var nYFact:Number = unscaledHeight / nPrevHeight;
	
				for (i = 0; i < numChildren; i++) {
					var dob:DisplayObject = getChildAt(i);
					// Rescale/position our object based in nX/YFact
					dob.x *= nXFact;
					dob.scaleX *= nXFact;
					dob.y *= nYFact;
					dob.scaleY *= nYFact;
					if (fReset) {
						// We need to offset our center
						dob.x -= unscaledWidth / 2;
						dob.y -= unscaledHeight / 2;
					}
					
				}
			}
			
			// Test
			var atgtNew2:Array = [];
			FindTargets(this, atgtNew2);
			for (i = 0; i < atgtNew2.length; i++) {
				atgtNew2[i].crop = true;
			}

			_obDocTemplateState = obNewDocTemplateState;
		}

		private function LocalizeText(dobc:DocumentObjectContainer): void {
			// Our text tool does not currently support system fonts, so don't bother localizing.
			if (PicnikBase.UsingSystemFont()) return;
			
			var txt:documentObjects.Text = (dobc as documentObjects.Text);
			if (txt != null) {
				var strKey:String = txt.text;
				if (strKey != null && strKey.length > 0) {
					strKey = strKey.replace(/ *\r */gm,'_n_');
					strKey = strKey.replace(/[ ]+/g,'_');
					strKey = strKey.replace(/[^A-Za-z0-9_]+/g,'');
					strKey = strKey.toLowerCase();

					// Default key
					var strVal:String = ResourceManager.getInstance().getString("templatesXmlText", strKey);
					if (strVal != null) {
						// Found a match
						// For now, ignore localized strings
						// Wait until Peter and Michael have time to upgrade templates to use the new text object.
						// txt.text = strVal;
					} else if (AccountMgr.GetInstance().isAdmin) {
						trace("Template text key not found in templatesXmlText.properties: " + strKey); 
					}
				}
			} else {
				// Recurse
				for (var i:Number = 0; i < dobc.numChildren; i++) {
					var dobChild:DisplayObject = dobc.getChildAt(i);
					if (dobChild is DocumentObjectContainer)	
						LocalizeText(dobChild as DocumentObjectContainer);
				}
			}
		}
		
		private function set baseStatus(n:Number): void {
			var nPrev:Number = baseStatus;
			status = n;
			_nBaseStatus = n;
		}
		
		private function get baseStatus(): Number {
			return _nBaseStatus;
		}
		
		private function SetPhotosToSwfs(dobc:DocumentObjectContainer): void {
			for (var i:Number = 0; i < dobc.numChildren; i++) {
				var dobChild:DisplayObject = dobc.getChildAt(i);
				var ph:Photo = dobChild as Photo;
				if (ph) ph.isSwf = true;
				if (!(dobChild is Target) && (dobChild is DocumentObjectContainer))	
					SetPhotosToSwfs(dobChild as DocumentObjectContainer);
			}
		}
		
		private function FixChildAssetRefs(dobc:DocumentObjectContainer, obAssetMap:Object): void {
			for (var i:Number = 0; i < dobc.numChildren; i++) {
				var dobChild:DisplayObject = dobc.getChildAt(i);
				if ("assetRef" in dobChild) dobChild["assetRef"] = obAssetMap[dobChild["assetRef"]];
				if (!(dobChild is Target) && (dobChild is DocumentObjectContainer))	
					FixChildAssetRefs(dobChild as DocumentObjectContainer, obAssetMap);
			}
		}
		
		// Convert a rich doc template into a flat list of invisible targets (for use in a simple collage)
		private function FlattenDocTemplate(): void {
			// Remove all non-targets
			// All targets are left invisible
			var atgt:Array = [];
			ExtractTargets(this, atgt); // Remove target descendants
			
			while (numChildren > 0) removeChildAt(numChildren-1); // Remove non-target children
			
			for each (var tgt:Target in atgt)
				addChild(tgt);
		}

		private function FindTargets(dobc:DocumentObjectContainer, atgt:Array): void {
			for (var i:Number = 0; i < dobc.numChildren; i++) {
				var dobChild:DisplayObject = dobc.getChildAt(i);
				if (dobChild is Target) atgt.push(dobChild);
				if (dobChild is DocumentObjectContainer) FindTargets(dobChild as DocumentObjectContainer, atgt);
			}
			_obDocTemplateState = null;
		}
		
		private function ExtractTargets(dobc:DocumentObjectContainer, atgt:Array): void {
			while (dobc.numChildren > 0) {
				var dobChild:DisplayObject = dobc.removeChildAt(0);
				if (dobChild is Target) {
					dobChild.visible = false;
					atgt.push(dobChild);
				} else if (dobChild is DocumentObjectContainer) {
					ExtractTargets(dobChild as DocumentObjectContainer, atgt);
				}
			}
			_obDocTemplateState = null;
		}

		override protected function Redraw(): void {
			if (usingDocTemplate) {
				if (baseStatus >= DocumentStatus.Loaded)
					ApplyDocTemplate();
				return;
			} else if (_obDocTemplateState != null) {
				FlattenDocTemplate();
				// Remove non-target children
			}

			// Calculate the number of Targets needed
			var ctgtNew:int;
			
			if (_strTemplate) {
				var atgtt:Array = GetTemplateTargets();
				ctgtNew = atgtt.length;
			} else {
				ctgtNew = numRows * numColumns;
			}
			
			// Count how many Targets are already present and visible
			var ctgtOld:int = 0;
			for (; ctgtOld < numChildren; ctgtOld++) {
				var dob:DisplayObject = getChildAt(ctgtOld);
				if (!dob.visible)
					break;
			}
				
			// Now is the time to re/create all child objects if necessary
			if (ctgtNew != ctgtOld) {
				
				// We don't want to recreate the child objects if they've just been loaded.
				// We can detect this condition by noticing that _cRows/ColsLast are in their
				// uninitialized state BUT magically the PhotoGrid has child objects.
				if (numChildren == 0 || _cRowsLast != uint.MAX_VALUE || _cColsLast != uint.MAX_VALUE) {
					
					if (ctgtOld > ctgtNew) {
						for (var itgt:int = ctgtNew; itgt < ctgtOld; itgt++) {
							dob = getChildAt(itgt);
							dob.visible = false;
						}
					}
					
					// Restore in-waiting Targets or create new ones if necessary
					if (ctgtNew > ctgtOld) {
						for (itgt = ctgtOld; itgt < ctgtNew; itgt++) {
							if (itgt < numChildren) {
								dob = getChildAt(itgt);
								dob.visible = true;
							} else {
								var tgt:Target = new Target();
								tgt.crop = true;
//								tgt.filters = [ new DropShadowFilter(0, 90, 0, 0.5, 6, 6, 1, 3) ];
								
								// Targets must be named in this reliable way so references persisted in the
								// undo/redo history will be resolvable after the document is deserialized.
								tgt.name = name + "_target" + itgt;
								addChild(tgt);						
							}
						}
					}
				}
			}
			_cRowsLast = numRows;
			_cColsLast = numColumns;
			
			var cxGrid:Number = unscaledWidth;
			var cyGrid:Number = unscaledHeight;
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = parseInt(name.slice(0, 7), 16); // We know the instance's name is a unique 16-digit hex string
			
			if (_strTemplate) {
				ApplyTemplate(atgtt, rnd);				
			} else {
				// Resize and reposition all the Targets
				var nScaleX:Number = Math.ceil(_cxCell) / 100 * (1 - _nGap);
				var nScaleY:Number = Math.ceil(_cyCell) / 100 * (1 - _nGap);
								
				var iTarget:int = 0;
				for (var j:int = 0; j < numRows; j++) {
					var y:Number = _cxyGap + (j * (_cyCell + _cxyGap)) - (cyGrid / 2);
					for (var i:int = 0; i < numColumns; i++) {
						var x:Number = _cxyGap + (i * (_cxCell + _cxyGap)) - (cxGrid / 2);
						tgt = Target(getChildAt(iTarget));
						tgt.x = Math.round(x + _cxCell / 2);
						tgt.y = Math.round(y + _cyCell / 2);
						tgt.scaleX = nScaleX;
						tgt.scaleY = nScaleY;
						
						ApplyKookiness(tgt, rnd);
						
						iTarget++;
					}
				}
			}
			
			if (_nBackgroundAlpha != 0) {
				with (graphics) {
					clear();
					beginFill(_coBackground, _nBackgroundAlpha);
					drawRect(-cxGrid / 2, -cyGrid / 2, cxGrid, cyGrid);
					endFill();
				}
			}
		}

		// Return false to make default drag behavior not lock aspect ratio
		public function get hasFixedAspectRatio(): Boolean {
			return false;
		}
		
		//
		// Template stuff
		//
		
		public static function LoadTemplates(fnOnComplete:Function): void {
			s_vstkTemplates = new PhotoGridTemplates();
			s_vstkTemplates.initialize();
			
			// UNDONE: figure out how to get the templates to layout without adding them to the Display List
			s_vstkTemplates.visible = false;
			s_vstkTemplates.includeInLayout = false;
			Application.application.addChild(s_vstkTemplates);
		}
		
		// Recurse through the template counting TargetTemplate instances.
		// While we're at it update the container's primary layout parameters
		// CONSIDER: move this set up out
		private function GetTemplateTargets(): Array {
			_cntrTemplate.width = unscaledWidth;
			_cntrTemplate.height = unscaledHeight;
			_cntrTemplate.setStyle("paddingLeft", _cxyGap);
			_cntrTemplate.setStyle("paddingTop", _cxyGap);
			_cntrTemplate.setStyle("paddingRight", _cxyGap);
			_cntrTemplate.setStyle("paddingBottom", _cxyGap);
			UpdateContainerGaps(_cntrTemplate, _cxyGap);
			_cntrTemplate.validateNow();
			
			return _GetTemplateTargets(_cntrTemplate, []);
		}
		
		private function _GetTemplateTargets(cntr:Container, atgtt:Array): Array {
			for (var i:int = 0; i < cntr.numChildren; i++) {
				var uic:UIComponent = UIComponent(cntr.getChildAt(i));
				if (uic is TargetTemplate)
					atgtt.push(uic);
				else if (uic is Container)
					_GetTemplateTargets(Container(uic), atgtt);
			}
			return atgtt;
		}
		
		private function UpdateContainerGaps(cntr:Container, cxyGap:Number): void {
			cntr.setStyle("horizontalGap", cxyGap);
			cntr.setStyle("verticalGap", cxyGap);
			for (var i:int = 0; i < cntr.numChildren; i++) {
				var cntrChild:Container = cntr.getChildAt(i) as Container;
				if (cntrChild)
					UpdateContainerGaps(cntrChild, cxyGap);
			}
		}
		
		private function ApplyTemplate(atgtt:Array, rnd:PM_PRNG): void {
			// If the first Target doesn't specify a priority via tabIndex then
			// then priority order is assumed to be the order the Targets are
			// placed in the template.
			if (atgtt.length > 0 && TargetTemplate(atgtt[0]).tabIndex != -1)
				atgtt.sortOn("tabIndex", Array.NUMERIC);
			
			var iTarget:int = 0;
			for each (var tgtt:TargetTemplate in atgtt) {
				var tgt:Target = Target(getChildAt(iTarget));
				
				var ptT:Point = tgtt.localToGlobal(new Point());
				tgt.x = (ptT.x - (unscaledWidth / 2) + tgtt.width / 2);
				tgt.y = (ptT.y - (unscaledHeight / 2) + tgtt.height / 2);
				
				tgt.scaleX = tgtt.width / 100;
				tgt.scaleY = tgtt.height / 100;
				
				ApplyKookiness(tgt, rnd);
				
				iTarget++;
			}
		}
		
		private function ApplyKookiness(tgt:Target, rnd:PM_PRNG): void {
			// It's a little too kooky to have horizontal offsets in single column collages
			if (numColumns != 1)
				tgt.x += rnd.nextDoubleRange(-_cxCell / 2, _cxCell / 2) * _nKookiness;
			// It's a little too kooky to have vertical offsets in single row collages
			if (numRows != 1)
				tgt.y += rnd.nextDoubleRange(-_cyCell / 2, _cyCell / 2) * _nKookiness;
				
			var nKookyScale:Number = (rnd.nextDoubleRange(-0.5, 0.5) * _nKookiness) + 1.0;
			tgt.scaleX *= nKookyScale;
			tgt.scaleY *= nKookyScale;
			tgt.rotation = rnd.nextDoubleRange(-50, 50) * _nKookiness;
		}
	}
}
