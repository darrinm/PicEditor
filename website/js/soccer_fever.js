// Copyright 2010 Google Inc. All Rights Reserved.
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

/**
* @fileoverview loads picasa photo feed via Google feed API.
*     Generates html to present the photos in a 2x6 grid.
* @author angelacao@google.com (Angela Cao)
*/
google.load('feeds', '1');

/**
* Generates HTML to present the photos in a 2x6 grid.
*/
function generatePicasaModule() {
  var feed = new google.feeds.Feed('http://picasaweb.google.com/' +
  'data/feed/base/featured?alt=rss&kind=photo&slabel=picnikfanphoto' +
  '&imgmax=64&max-results=16');
  var numPhotos = 16;
  var picasa = document.getElementById('picasa');

  if (!picasa) {
    return;
  }

  var loader = picasa.getElementsByTagName('img')[0];
  var counter = 0;

  feed.setNumEntries(numPhotos);
  feed.load(function(result) {
    var html = '';

    if (!result.error) {
      for (var i = 0; i < result.feed.entries.length; i++) {
        var entry = result.feed.entries[i];
        counter++;
        html += '<li' + (counter % 8 == 0 ? ' class="last"' : '') +
        '><a target="_blank" href="' + entry.link + '"><img src="' +
        entry.mediaGroups[0].contents[0].url + '" /></a></li>';
      }

      var photoList = document.createElement('ul');
    } else {
      html = 'Error!  Please try again later.'
      var photoList = document.createElement('p');
    }
    picasa.removeChild(loader);
    photoList.innerHTML = html;
    picasa.appendChild(photoList);
  });
}
google.setOnLoadCallback(generatePicasaModule);

/**
* Get the list of elements with a specific classname.
* http://robertnyman.com/2005/11/07/the-ultimate-getelementsbyclassname/
* @param {HTMLElement} oElm Parent HTML element.
* @param {string} strTagName Tag name as string.
* @param {string} strClassName Class name as string.
* @return {list} List of matching elements.
*/
function getElementsByClassName(oElm, strTagName, strClassName) {
  var arrElements = (strTagName == '*' && oElm.all) ?
    oElm.all : oElm.getElementsByTagName(strTagName);
  var arrReturnElements = new Array();
  strClassName = strClassName.replace(/\-/g, '\\-');
  var oRegExp = new RegExp('(^|\\s)' + strClassName + '(\\s|$)');
  var oElement;

  for (var i = 0; i < arrElements.length; i++) {
    oElement = arrElements[i];
    if (oRegExp.test(oElement.className)) {
      arrReturnElements.push(oElement);
    }
  }
  return (arrReturnElements);
}
