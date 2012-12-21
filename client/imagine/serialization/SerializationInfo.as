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
package imagine.serialization
{
	public class SerializationInfo
	{
		public var parameters:Array = [];
		public function SerializationInfo(astrParameters:Array=null)
		{
			parameters = astrParameters;
		}

		private function GetName(obParam:Object): String {
			if ('name' in obParam) {
				return obParam.name;
			} else {
				return obParam.toString();
			}
		}
		
		public function GetSerializationValues(obLocal:Object): Object {
			var obSerializationValues:Object = {};
			for each (var obParam:Object in parameters) {
				var strName:String = GetName(obParam);
				var obLocalValue:Object = obLocal[strName];
				if (('cleanWriteValue' in obParam) && obParam.cleanWriteValue) {
					obLocalValue = SerializationUtil.CleanSrlzWriteValue(obLocalValue);
				}
				obSerializationValues[strName] = obLocalValue;
			}
			return obSerializationValues;		
		}
		
		public function SetSerializationValues(obSerializationValues:Object, obLocal:Object): void {
			for each (var obParam:Object in parameters) {
				var strName:String = GetName(obParam);
				if (strName in obSerializationValues) {
					var obSerializationValue:Object = obSerializationValues[strName];
					if (('cleanReadValue' in obParam) && obParam.cleanReadValue) {
						obSerializationValue = SerializationUtil.CleanSrlzReadValue(obSerializationValue);
					}
					obLocal[strName] = obSerializationValue;
				}
			}
		}
	
		public function DeserializeValuesFromXml(xmlOp:XML, obLocal:Object): void {
			SetSerializationValues(Util.ObFromXmlProperties(xmlOp.Object[0]), obLocal);
		}
		
		public function SerializeValuesToXml(xmlOp:XML, obLocal:Object): void {
			xmlOp.appendChild(Util.XmlPropertiesFromOb(GetSerializationValues(obLocal), "Object"));
		}
	}
}