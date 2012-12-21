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

package util {
	import flash.net.LocalConnection;
	
	public dynamic class DynamicLocalConnection extends LocalConnection
	{
		// trivial subclass to allow easy assignment of methods to be invoked.
		
		// while we're at it, this is a good time to note this bug which bit me early on
		// while testing.  Once LocalConnection communication is forcibly interrupted, a
		// global semaphore isn't unlocked and ANY comm via LocalConnection will lock your
		// browser, and only a full reboot will unstick it.  It doesn't seem to happen
		// now that the LocalConnection stuff I was working on is working now, but you never know...
		//	http://bugs.adobe.com/jira/browse/FP-1476
		
		public function allowPicnikDomains(): void {
			allowDomain("www.mywebsite.com",
						"cdn.mywebsite.com",
						"www.gstatic.com",
						"ssl.gstatic.com",
						"test.mywebsite.com",
						"testcdn.mywebsite.com",
						"local.mywebsite.com",
						"localcdn.mywebsite.com");
		}
		
		public override function connect(connectionName:String):void {
			if (connectionName.charAt(0) != "_")
				connectionName = "_" + connectionName;
			super.connect(connectionName);
		}
	}
}
