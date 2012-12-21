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

def isLocale(strLocale):
	if len(strLocale) != 5: return False
	return strLocale[2] == '_'
	
def validatePropsFile(strFile, strFilePath, fFix):
	fValid = True
	
	astrLines = strFile.split('\n')
	fFirst = True
	fFoundBlankLine = False
	for strLine in astrLines:
		if fFirst:
			if strLine[0:3] == codecs.BOM_UTF8:
				strLine = strLine[3:]
			fFirst = False
		
		fBlank = len(strLine.strip()) == 0
		if fBlank:
			fFoundBlankLine = True
		else: # found first non-blank line
			fValid = not fFoundBlankLine
			break

	if not fValid:
		if fFix:
			try:
				FixPropFile(strFilePath)
				fValid = True
			except:
				pass
		if fValid:
			print "Fixed: Prop file starts with a blank line: " + strFilePath
		else:
			print "Error: Prop file starts with a blank line: " + strFilePath
	
	return fValid
		
	
def FixPropFile(strFilePath):
	fIn = open(strFilePath, 'r')
	
	strOut = ""
	n = 0
	fFoundLineWithText = False
	fRemovedBlankLine = False
	for strLine in fIn:
		if n == 0:
			# First line. Remove BOM (or throw an error)
			if len(strLine) < 3:
				raise "First line is too short for BOM: " + strFilePath
			if strLine[0:3] != codecs.BOM_UTF8:
				raise "Invalid BOM: " + strFilePath
			strLine = strLine[3:]
		if not fFoundLineWithText:
			if len(strLine.strip()) > 0:
				fFoundLineWithText = True
				strLine = codecs.BOM_UTF8 + strLine # add utf8 header
			else:
				fRemovedBlankLine = True
		if fFoundLineWithText:
			strOut += strLine
		n += 1
	fIn.close()
	#if not fFoundLineWithText:
	#	print "!!!!EMPTY PROP FILE: " + strFilePath
	if fFoundLineWithText and fRemovedBlankLine:
		fOut = open(strFilePath, 'w')
		fOut.write(strOut)
		fOut.close()
	
# UNDONE:
# Fix @Resource(...bundle='<bundle>') refs
# Fix [ResourceBundoe("<bundle>") refs
	
def doAll():
	strLocBasePath = os.path.join(strPicnikBase, 'client', 'loc')
	for strLocale in os.listdir(strLocBasePath):
		if isLocale(strLocale):
			strLangBase = os.path.join(strLocBasePath, strLocale)
			# we have the language base. Now find files and move them
			for strPropFile in os.listdir(strLangBase):
				if extensionMatches(strPropFile, "properties"):
					strPropFullPath = os.path.join(strLangBase, strPropFile)
					FixPropFile(strPropFullPath)
	
if __name__ == '__main__':
	doAll()
