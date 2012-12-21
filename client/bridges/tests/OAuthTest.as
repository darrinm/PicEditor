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
package bridges.tests {
	import bridges.OAuth;
	
	import com.adobe.net.URI;
	import com.adobe.utils.IntUtil;
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Base64;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import flexunit.framework.*;

	public class OAuthTest extends TestCase {
		public function testGenerateSignature(): void {
			// Test values taken from http://oauth.net/core/1.0/#auth_step1
			var auth:OAuth = new OAuth();
			var uri:URI = new URI("http://photos.example.net/photos?file=vacation.jpg&size=original");
			var strSig:String = auth.GenerateSignature(uri, "dpf43f3p2l4k3l03", "kd94hf93k423kf44",
					"nnch734d00sl2jdk", "pfkkdhi9sl3r4s00",	"GET", "1191242096", "kllo9940pd9333jh",
					OAuth.kstrHMACSHA1SignatureType);
			
			assertEquals("tR3+Ty81lMeYAr/Fid0kMTYa/WM=", strSig);
		}
		
		public function testGenerateSignatureBase(): void {
			// Test values taken from http://oauth.net/core/1.0/#auth_step1
			var auth:OAuth = new OAuth();
			var uri:URI = new URI("http://photos.example.net/photos?file=vacation.jpg&size=original");
			var strSigBase:String = auth.GenerateSignatureBase(uri, "dpf43f3p2l4k3l03", "kd94hf93k423kf44",
					"nnch734d00sl2jdk", "pfkkdhi9sl3r4s00",	"GET", "1191242096", "kllo9940pd9333jh",
					OAuth.kstrHMACSHA1SignatureType);
			
			assertEquals("GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal", strSigBase);
		}
		
		public function testGenerateSignature_2(): void {
			// Test values taken from http://developer.myspace.com/Community/forums/t/187.aspx?PageIndex=2
			var auth:OAuth = new OAuth();
			var uri:URI = new URI("http://api.msappspace.com/v1/users/30344243.xml");
			var strSig:String = auth.GenerateSignature(uri, "http://www.myspace.com/329303884", "0a8102bd0e3c424ba3eef5ef1e43cd96",
					"", "",	"GET", "1202493637", "0e53f0eb-68dc-44ce-b184-377846bb9519",
					OAuth.kstrHMACSHA1SignatureType);
					
			assertEquals("87VYQDuLUvX2D+P1yZJy/+VmVlE=", strSig);
		}
		
		public function testGenerateSignatureBase_2(): void {
			// Test values taken from http://developer.myspace.com/Community/forums/t/187.aspx?PageIndex=2
			var auth:OAuth = new OAuth();
			var uri:URI = new URI("http://api.msappspace.com/v1/users/30344243.xml");
			var strSigBase:String = auth.GenerateSignatureBase(uri, "http://www.myspace.com/329303884", "0a8102bd0e3c424ba3eef5ef1e43cd96",
					"", "",	"GET", "1202493637", "0e53f0eb-68dc-44ce-b184-377846bb9519",
					OAuth.kstrHMACSHA1SignatureType);
			assertEquals("GET&http%3A%2F%2Fapi.msappspace.com%2Fv1%2Fusers%2F30344243.xml&oauth_consumer_key%3Dhttp%253A%252F%252Fwww.myspace.com%252F329303884%26oauth_nonce%3D0e53f0eb-68dc-44ce-b184-377846bb9519%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1202493637%26oauth_token%3D%26oauth_version%3D1.0", strSigBase);
		}
		
		public function testHMAC(): void {
			// Test values taken from http://oauth.net/core/1.0/#auth_step1
			var hmac:HMAC = new HMAC(new SHA1());
			var baKey:ByteArray = new ByteArray();
			baKey.writeUTFBytes("kd94hf93k423kf44&pfkkdhi9sl3r4s00");
			var baData:ByteArray = new ByteArray();
			baData.writeUTFBytes("GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal");
			var baDigest:ByteArray = hmac.compute(baKey, baData);
			var strDigest:String = Base64.encodeByteArray(baDigest);

			assertEquals("tR3+Ty81lMeYAr/Fid0kMTYa/WM=", strDigest);
		}
		
		public function testHMAC_2(): void {
			// Test values taken from http://www.faqs.org/rfcs/rfc2202.html
			var hmac:HMAC = new HMAC(new SHA1());
			var baKey:ByteArray = new ByteArray();
			baKey.writeUTFBytes("Jefe");
			var baData:ByteArray = new ByteArray();
			baData.writeUTFBytes("what do ya want for nothing?");
			var baDigest:ByteArray = hmac.compute(baKey, baData);
			
			baDigest.endian = Endian.LITTLE_ENDIAN;
			var strHex:String = "";
			baDigest.position = 0;
			for (var i:int = 0; i < baDigest.length; i += 4) {
				strHex += IntUtil.toHex(baDigest.readInt());
			}

			assertEquals("effcdf6ae5eb2fa2d27416d5f184df9c259a7c79", strHex);
		}
		
		public function testSHA1(): void {
			// Test values taken from http://www.nabble.com/test-sha1-tc15203959.html
			var sha:SHA1 = new SHA1();
			var baIn:ByteArray = new ByteArray();
			baIn.writeUTFBytes("abcdefgh");
			var baOut:ByteArray = sha.hash(baIn);
			
			baOut.endian = Endian.LITTLE_ENDIAN;
			var strHex:String = "";
			baOut.position = 0;
			for (var i:int = 0; i < baOut.length; i += 4) {
				strHex += IntUtil.toHex(baOut.readInt());
			}
			
			assertEquals("425af12a0743502b322e93a015bcf868e324d56a", strHex);
		}
		
		public function testSHA1_2(): void {
			// Test values taken from http://www.nabble.com/test-sha1-tc15203959.html
			import com.adobe.crypto.SHA1;
			var strHex:String = com.adobe.crypto.SHA1.hash("abcdefgh")
			
			assertEquals("425af12a0743502b322e93a015bcf868e324d56a", strHex);
		}
	}
}
