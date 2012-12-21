#!/usr/bin/python
# Copyright 2011 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys
import urllib
astrLocs = ['de', 'en', 'es', 'es', 'fr', 'id', 'it', 'ja', 'ko', 'no', 'pt', 'ru', 'sv', 'vi', 'zh-CN', 'zh-TW']

strQuery = urllib.quote(' '.join(sys.argv[1:]))

strUrl = 'http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=' + strQuery

for strLoc in astrLocs:
	strUrl += '&langpair=en' + urllib.quote('|') + strLoc

import urllib2
fin = urllib2.urlopen(strUrl)
strJson = fin.read()

# print 'strJson = ', strJson

import json
obJson = json.loads(strJson)

aobResults = obJson['responseData']


fout = open('out.txt', 'wb')
fout.write("Localization of " + ' '.join(sys.argv[1:]) + "\r\n")
for i in range(0, len(astrLocs)):
	fout.write(astrLocs[i] + ": ")
	fout.write(aobResults[i]['responseData']['translatedText'].encode('utf-8'))
	fout.write('\r\n')

fout.close()
