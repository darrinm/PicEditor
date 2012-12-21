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
package bridges.storageservice {
	public class StorageServiceError {
		public static const None:Number = 0;
		public static const IOError:Number = 1;
		public static const InvalidUserOrPassword:Number = 2;
		public static const NotLoggedIn:Number = 3;
		public static const LoginFailed:Number = 4;
		public static const InvalidServiceResponse:Number = 5;
		public static const ItemNotFound:Number = 6;
		public static const NotEnoughSpace:Number = 7;
		public static const Unknown:Number = 8;
		public static const SecurityError:Number = 9;
		public static const Timeout:Number = 10;
		public static const Exception:Number = 11;
		public static const InvalidParameters:Number = 12;
		public static const PendingAuth:Number = 13;
		public static const UserNotPremium:Number = 54;	// for when trying to save > 3 galleries when not premium
		public static const BridgeOffline:Number = 60;
		public static const ChildObjectFailedToLoad:Number = 2000;
	}
}
