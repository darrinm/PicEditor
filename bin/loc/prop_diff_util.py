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

strPicnikBase = 'C:\\src\\picnik'
fVerbose = False
# fVerbose = True

def extensionMatches(strFilePath, strExtension):
	return strFilePath.lower().endswith('.' + strExtension.lower())

def mergeFiles(strSourceDir, fOut):	
	# Find us_EN dir
	
	if 'en_US' in os.listdir(strSourceDir):
		# go one level down
		strSourceDir = os.path.join(strSourceDir, 'en_US')

	fOut.write(codecs.BOM_UTF8 )
		
	for f in os.listdir(strSourceDir):
		strFilePath = os.path.join(strSourceDir, f)
		if extensionMatches(strFilePath, 'properties'):
			# Found a properties file.
			strFileKey = f[0:-10] # Lop off the properties bit
			
			# read the source file, prepend the properties file, and write it out
			fIn = open(strSourcePath, 'r')
			for strLine in fIn:
				strLine = strLine.strip()
				if len(strLine) > 0 and strLine[0] != '#':
					strLine = strFileKey + strLine
				fOut.write(strLine)
			fIn.close()

if __name__ == '__main__':
	if len(sys.argv) > 1 and (sys.argv[1] == '-help' or sys.argv[1] == '/help' or sys.argv[1] == '-h' or sys.argv[1] == '/h' or sys.argv[1] == '/?'):
		print "usage: "
		print "mergeFiles <optional: source dir> <optional: target file>"
	else:
		if len(sys.argv) > 1:
			strSourceDir = sys.argv[1]
		else:
			strSourceDir = os.path.join(strPicnikBase, 'client','loc')
			
		if len(sys.argv) > 2:
			fOut = open(sys.argv[2], 'w')
		else:
			fOut = sys.stdout
			
		mergeFiles(strSourceDir, fOut)
		
