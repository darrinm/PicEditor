#!/usr/bin/env python
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

import datetime
import sys, os
import threading, Queue
from time import time
from time import sleep
import traceback
import re
import shutil
import codecs
import urllib

# BEGIN: Import LocaleInfo
strBase = os.getcwd()
strServerDir = os.path.join(strBase, 'server')
sys.path.insert(0, strServerDir)
from SWFParser import SWFParser
# END: Import LocaleInfo

# BEGIN: Import serverbin for PIL code
import ConfigParser
dDefaults = {}
dDefaults['baseDir'] = os.getcwd()
dDefaults['sourceDir'] = os.path.abspath(os.path.dirname(__file__))
dDefaults['serverbinDir'] = os.path.normpath(os.path.join(dDefaults['sourceDir'], '../serverbin'))
Config = ConfigParser.SafeConfigParser(dDefaults)
Config.read('picnik.ini')
try:
	strServerBinDir = os.path.join(Config.get('Locations', 'serverbinDir'), 'site-packages')
except:
	strServerBinDir = os.path.join(os.getcwd(), 'serverbin_lin', 'site-packages')

sys.path.insert(0, strServerBinDir)
from PIL import Image
# END: Import serverbin for PIL code

'''
Error return looks like this:
ERROR
<error message>

Success return looks like this:
SUCCESS
<created file url>
<source file area>
<created file area>
'''
if __name__ == '__main__':
	if len(sys.argv) < 3:
		print '''ERROR
Not enough parameters

Call png2swf with the following params:
png2swf.py <source file path> <dest folder path> [optional: max area - default is 700 * 700]
		'''
		sys.exit(1)

	strPngFile = urllib.unquote_plus(sys.argv[1])
	strInPath = strPngFile
	strOutPath = urllib.unquote_plus(sys.argv[2])
	
	if len(sys.argv) > 3:
		nSize = int(sys.argv[3])
	else:
		nSize = 700
	
	nBreakPos = max(strOutPath.rfind('\\'), strOutPath.rfind('/'))
	if nBreakPos > 0:
		strDestDirPath = strOutPath[0:nBreakPos]
		if not os.path.exists(strDestDirPath):
			os.mkdir(strDestDirPath)
	
	# Check the size of the input png
	from PIL import Image
	im = Image.open(strInPath)
	nTargetArea = nSize * nSize * 1.0
	
	if len(sys.argv) > 4:
		nQuality = int(sys.argv[4])
	else:
		nQuality = 70
	nWidth, nHeight = im.size
	nMaxArea = nTargetArea * 4.0 / 3.0
	nArea = nWidth * nHeight
	nWidth2 = nWidth
	nHeight2 = nHeight

	import math
	nScaleFactor = math.sqrt(nTargetArea * 1.0 / nArea)
	nScaleFactor = min(nScaleFactor, 2799.0/nWidth, 2799.0/nHeight)
	if nScaleFactor < 1:
		# Create a temporary file
		nWidth2 = int(nWidth * nScaleFactor)
		nHeight2 = int(nHeight * nScaleFactor)
		strTempPath = 'C:\\temp\\temp.png'
		im.thumbnail((nWidth2, nHeight2), Image.ANTIALIAS)
		if nWidth < 10 or nHeight < 10:
			raise "Image is too small: " + str(nWidth) + ' x ' + str(nHeight)
		im.save(strTempPath)
		strInPath = strTempPath

	SWFParser.PNGFilePathToSwf(strInPath, strOutPath, nQuality, 1)
	
	print "SUCCESS"
	print str(nWidth) + ',' +str(nHeight) + "," + str(nWidth2) + "," + str(nHeight2)
