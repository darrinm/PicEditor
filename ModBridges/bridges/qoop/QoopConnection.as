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
package bridges.qoop
{
	import dialogs.EasyDialogBase;
	
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import util.LocUtil;
	import util.KeyVault;

	public class QoopConnection
	{
		private static const kstrQoopBaseUrl:String = "http://www.qoop.com/photobooks/qops/qops_url_saver.php";
		//private static const kstrQoopBaseUrl:String = "http://local.mywebsite.com/dump";

		static public function LaunchPrintPartner( aitemInfos:Array, obSelection:Object ): void {
			// build up a funky URL that will launch the user into happy QOOP land
			
			var strUrl:String = kstrQoopBaseUrl;
			var urlv:URLVariables = new URLVariables();
				
			var obArgs:Object = {};
			
			urlv['account'] = KeyVault.GetInstance().qoop.pub;		
			if (obSelection && obSelection.data)
				urlv['product'] = obSelection.data;

			var n:Number = 0;				
			for (var i:Number = 0; i < aitemInfos.length; i++) {
				var itemInfo:ItemInfo = aitemInfos[i];

				if (!("sourceurl" in itemInfo))
					continue;		

				n++;
				urlv['original_url' + n] = itemInfo.sourceurl;
				
				if ("width" in itemInfo)
					urlv['original_width' + n] = itemInfo.width;
				if ("height" in itemInfo)
					urlv['original_height' + n] = itemInfo.height;
				if ("last_update" in itemInfo) {
					var dtMod:Date = new Date(itemInfo.last_update)
					urlv['upload' + n] = LocUtil.FormatDate( dtMod, "YYYY-MM-DD" );
				}
				if ("title" in itemInfo)
					urlv['title' + n] = itemInfo.title;
				if ("description" in itemInfo)
					urlv['description' + n] = itemInfo.description;
				if ("thumbnailurl" in itemInfo)
					urlv['small_url' + n] = itemInfo.thumbnailurl;
				if ("thumb320url" in itemInfo)
					urlv['medium_url' + n] = itemInfo.thumb320url;
				if ("thumb75url" in itemInfo)
					urlv['square_url' + n] = itemInfo.thumb75url;				
			}
			
			if (n == 0) {
				// qoop wants us to send them something. If we have nothing, send them a sample image
				n++;
				var strBaseUrl:String = PicnikService.serverURL + "/graphics/qoop/default_image/";
				urlv['original_width' + n] = 601;
				urlv['original_height' + n] = 800;
				urlv['title' + n] = "Picnik Sample";
				urlv['description' + n] = "Picnik sample image";
				urlv['original_url' + n] = PicnikBase.StaticUrl(strBaseUrl + "original.jpg");
				urlv['small_url' + n] = PicnikBase.StaticUrl(strBaseUrl + "small.jpg");
				urlv['medium_url' + n] = PicnikBase.StaticUrl(strBaseUrl + "medium.jpg");
				urlv['square_url' + n] = PicnikBase.StaticUrl(strBaseUrl + "square.jpg");
			}
			
			// Use POST because otherwise the URI is too big
			var urlr:URLRequest = new URLRequest(strUrl);
			urlr.data = urlv;
			urlr.method = URLRequestMethod.POST;
			
			// log
			var strPath:String = "/bridges/out/print/qoop/out";
			if (obSelection && obSelection.data)
				strPath += "/" + obSelection.data;				
			Util.UrchinLogReport(strPath);
			
			// redirect to QOOP
			if (PicnikBase.app.canNavParentFrame) {
				PicnikBase.app.NavigateToURL(urlr, "_self");
			} else {
				EasyDialogBase.Show(PicnikBase.app,
					[Resource.getString("Picnik", "ok")],
					Resource.getString("QoopPicker", "photoready"),
					Resource.getString("QoopPicker", "clicktoprint"),
					function( obResult:Object ): void {
							PicnikBase.app.NavigateToURL(urlr, "_blank");
						} );
			}

		}
	}
}
