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

import xml.dom.minidom
from xml.parsers.expat import ExpatError

strPicnikBase = 'C:\\src\\picnik'
# fVerbose = False
fVerbose = True

def extensionMatches(strFilePath, strExtension):
	return strFilePath.lower().endswith('.' + strExtension.lower())

def removeExtension(strFile):
	nBreak = strFile.rfind('.')
	if nBreak == -1: return strFile
	return strFile[0:nBreak]

def ValidateXmlContents(strFile, strFilePath):
	import xml.parsers.expat
	p = xml.parsers.expat.ParserCreate()
	try:
		strFile = strFile.replace(' -- ', ' - - ')
		p.Parse(strFile)
	except ExpatError, e:
		print "Error: XML Validation Failed: " + strFilePath
		print "   : " + str(e)
		
		# Read the file and find the line in question
		file = open(strFilePath, 'r')
		nLine = 0
		for strLine in file:
			nLine += 1
			if nLine == e.lineno:
				print "   : " + strLine.rstrip()
				print "-^-".rjust(e.offset + 6, ' ')
				break
		file.close()
		print
		return False
	return True
	
def ValidateXmlFile(strFilePath):
	try:
		file = open(strFilePath, 'r')
		strFile = file.read()
		file.close()
		strFile = strFile.replace(' -- ', ' - - ')
		xml.dom.minidom.parseString(strFile)
	except ExpatError, e:
		print "Failed: " + strFilePath
		print "   : " + str(e)
		
		# Read the file and find the line in question
		file = open(strFilePath, 'r')
		nLine = 0
		for strLine in file:
			nLine += 1
			if nLine == e.lineno:
				print "   : " + strLine.rstrip()
				print "-^-".rjust(e.offset + 6, ' ')
				break
		file.close()
		print
		return False
	return True
	
def ValidateXml(strPath, strExtension):
	nFiles = 0
	fValid = True
	for strFile in os.listdir(strPath):
		strSourcePath = os.path.join(strPath, strFile)
		if strFile == "BugTips.xml":
			pass # Ignore bug tips
		elif extensionMatches(strFile,strExtension):
			if not ValidateXmlFile(strSourcePath):
				fValid = False
			nFiles += 1
		elif extensionMatches(strSourcePath, "svn"):
			pass
		elif os.path.isdir(strSourcePath):
			nSubFiles, fSubValid = ValidateXml(strSourcePath, strExtension)
			fValid = fValid and fSubValid
			nFiles += nSubFiles
	return nFiles, fValid
	
# UNDONE:
# Fix @Resource(...bundle='<bundle>') refs
# Fix [ResourceBundoe("<bundle>") refs
	
def ValidateAllXml():
	strPath = os.path.join(os.getcwd(), "website", "app")
	nFiles, fValid = ValidateXml(strPath, "xml")
	if fValid:
		print "Validated " + str(nFiles) + " xml files in " + strPath
	else:
		print "One or more xml files invalid in " + strPath
	
	
if __name__ == '__main__':
	ValidateAllXml()
