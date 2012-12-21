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

package module {
  import util.VersionStamp;

  import flash.system.Security;
  import mx.events.FlexEvent;
  import mx.events.ResizeEvent;
  import mx.modules.Module;

  /**
   * Base module class with common c'tor and common methods.
   */
  public class PicnikModule extends Module {
    public function PicnikModule() {
      addEventListener(FlexEvent.INITIALIZE, onInitializeHandler);
      if (!PicnikBase.isDesktop) {
        Security.allowDomain("www.mywebsite.com");
        Security.allowDomain("cdn.mywebsite.com");
        Security.allowDomain("test.mywebsite.com");
        Security.allowDomain("testcdn.mywebsite.com");
        Security.allowDomain("local.mywebsite.com");
        Security.allowDomain("localcdn.mywebsite.com");
		
		Security.allowDomain("ssl.gstatic.com");
		Security.allowDomain("www.gstatic.com");

        Security.allowDomain("flickr.com");
        Security.allowDomain("www.flickr.com");
        Security.allowDomain("staging.flickr.com");
        Security.allowDomain("extbeta1.flickr.com");
        Security.allowDomain("beta1.flickr.com");
        Security.allowDomain("beta2.flickr.com");
        Security.allowDomain("beta3.flickr.com");
        Security.allowDomain("l.yimg.com");
        Security.allowDomain("backstage.flickr.com");
      }
    }

    public function getVersionStamp():String {
      return VersionStamp.getVersionStamp();
    }

    // Module doesn't seem to pay attention its parent's size (e.g. width="100%"
    // has no effect on it). So here we watch the parent component
    // (IActivatableModuleLoader) ourselves and resize to fill it.
    private function onInitializeHandler(evt:FlexEvent):void {
      parent.addEventListener(ResizeEvent.RESIZE, onParentResizeHandler);
      width = parent.width;
      height = parent.height;
    }

    private function onParentResizeHandler(evt:ResizeEvent):void {
      width = parent.width;
      height = parent.height;
    }
  }
}
