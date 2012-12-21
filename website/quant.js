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
/* new param, passing in an option url. first call should be with a null url.
   subsequent calls will provide a url. */
function picnikquantserve(qurl){ 
if((typeof _qacct =="undefined")||(_qacct.length==0))return;
 /* ignore _qpixelsent if we're passing in a url */
if ((qurl == null)&&(typeof _qpixelsent !="undefined")&&(_qpixelsent==_qacct))return;
_qpixelsent=_qacct;
 var r=_qcrnd();
 var ce=(navigator.cookieEnabled)?"1":"0";
 var sr='',qo='',qm='',url='',ref='',je='u',ns='1';
 if(typeof navigator.javaEnabled !='undefined')je=(navigator.javaEnabled())?"1":"0";
 if(typeof _qoptions !="undefined" && _qoptions!=null){for(var k in _qoptions){qo+=';'+k+'='+_qceuc(_qoptions[k]);}_qoptions=null;}
 if(typeof _qmeta !="undefined" && _qmeta!=null){qm=';m='+_qceuc(_qmeta);_qmeta=null;}
 if(self.screen){sr=screen.width+"x"+screen.height+"x"+screen.colorDepth;}
 var d=new Date();
 var dst=_qcdst();



 var dc="1202935502-40710797-60371319";

 var qs="http://pixel.quantserve.com";
 var fp=_qcsc(dc);
 /* if we're passing in a url, use it, and use the last url as the referrer.  */
 if (qurl!=null){
 	url = _qceuc(qurl);
	if (typeof _qref != "undefined" && _qref!=null)	ref = _qref;
}
 /* otherwise, get the url and ref from the browser */
else {
 if(window.location && window.location.href)url=_qceuc(window.location.href);
 if(window.document && window.document.referrer)ref=_qceuc(window.document.referrer); 
 }
 _qref = url; /* Save url as ref for next url */
 if(self==top)ns='0';

 var img=new Image(1,1);
 img.alt="";
 img.src=qs+'/pixel'+';r='+r+fp+';ns='+ns+';url='+url+';ref='+ref+';ce='+ce+';je='+je+';sr='+sr+';dc='+dc+';dst='+dst+';et='+d.getTime()+';tzo='+d.getTimezoneOffset()+';a='+_qacct+qo+qm;
 //alert('creating image:' + img.src);
 img.onload=function() {_qvoid();}
}
picnikquantserve();
