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
# fVerbose = False
fVerbose = True

def extensionMatches(strFilePath, strExtension):
	return strFilePath.lower().endswith('.' + strExtension.lower())

def removeExtension(strFile):
	nBreak = strFile.rfind('.')
	if nBreak == -1: return strFile
	return strFile[0:nBreak]
	
def UpdateRefsInFile(strFilePath, strBundle):
	fIn = open(strFilePath, 'r')
	strFile = fIn.read()
	fIn.close()
	
	fChanged = False
	
	p = re.compile("@Resource\((\s*key\s*=\s*\'[^']*\'[^),]*)\)")
	strFile, nChanges = p.subn(r"@Resource(\1, bundle='" + strBundle + "')", strFile)
	fChanged = fChanged or (nChanges > 0)

	p = re.compile("@Resource\((\s*[^kb][^')]*)\)")
	strFile, nChanges = p.subn(r"@Resource(key='\1', bundle='" + strBundle + "')", strFile)
	fChanged = fChanged or (nChanges > 0)
	
	if fChanged:
		fOut = open(strFilePath, 'w')
		fOut.write(strFile)
		fOut.close()

	
def UpdateRefsIn(strPath):
	for strFile in os.listdir(strPath):
		strSourcePath = os.path.join(strPath, strFile)
		if extensionMatches(strFile, "mxml"):
			UpdateRefsInFile(strSourcePath, removeExtension(strFile))
		elif extensionMatches(strSourcePath, "svn"):
			pass
		elif os.path.isdir(strSourcePath):
			UpdateRefsIn(strSourcePath)
	
# UNDONE:
# Fix @Resource(...bundle='<bundle>') refs
# Fix [ResourceBundoe("<bundle>") refs
	
def doAll():
	UpdateRefsIn(strPicnikBase + "\\client")
	UpdateRefsIn(strPicnikBase + "\\modcreate")
	
if __name__ == '__main__':
	doAll()
