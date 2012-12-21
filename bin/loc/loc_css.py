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

# Create localized css files for client/main.css and client/theme/picniktheme.css

import datetime
import sys, os
import threading, Queue
from time import time
from time import sleep
import traceback
import re
import shutil

# BEGIN: Import LocaleInfo
strBase = os.getcwd()
strServerDir = os.path.join(strBase, 'server')
sys.path.insert(0, strServerDir)
from LocaleInfo import LocaleInfo
# END: Import LocaleInfo

astrSourceFiles = ['main.css', 'theme/picniktheme.css'] # relative to client/
strLocaleDir = 'loc' # relative to client/, look here for a list of supported locales

# group 1: ! or empty
# group 2: var name
patIfLine = re.compile('.*#if\s+(!?)([a-z_\-+$]*)', re.IGNORECASE)
patElseLine = re.compile('.*#else(\s|$)', re.IGNORECASE)
patEndIfLine = re.compile('.*#endif(\s|$)', re.IGNORECASE)

patNoLoc = re.compile('.*/\*\s*no\s*loc', re.IGNORECASE)
patLocDir = re.compile('.*/\*\s*loc\s*dir', re.IGNORECASE)

patLocale = re.compile('[a-z][a-z]_[a-z][a-z]', re.IGNORECASE)

fVerbose = False
#fVerbose = True

# returns a two letter lower case language code
def localeToLang(strLocale):
	return strLocale[0:2].lower()

# returns a two letter lower case country code
def localeToCountryCode(strLocale):
	return strLocale[3:2].lower()

def initTables(strLocale, astrLocales):
	dTruths = {}
	for str in astrLocales:
		dTruths[str.lower()] = False
	dTruths[strLocale.lower()] = True
	dTruths['usesystemfont'] = LocaleInfo.dLocales[strLocale]['useSystemFont']
	dTruths['nonbold'] = LocaleInfo.dLocales[strLocale]['nonBold']
	return dTruths

def initLocales(strLocalePath):
	astrLocales = []
	for strFileName in os.listdir(strLocalePath):
		strFullPath = os.path.join(strLocalePath, strFileName)
		if os.path.isdir(strFullPath):
			# Found a sub-dir
			if patLocale.match(strFileName):
				astrLocales.append(strFileName)
	if fVerbose:
		print "Read locales: " + str(astrLocales)
	return astrLocales

# Convert bold, etc.
def processLine(strLine, dTruths, strLocale):
	if not patNoLoc.match(strLine):
		# handle loc dir lines (replace en_US with the current locale)
		if patLocDir.match(strLine):
			strLine = strLine.replace('en_US', strLocale)
        else:
            # only manipulation (for now) is to replace bold with normal
    		if dTruths['nonbold']:
    			strLine = strLine.replace('bold','normal')

			
	return strLine

def localizeFile(strSourcePath, strLocale, astrLocales):
	dTruths = initTables(strLocale, astrLocales)
	
	# read the source file, escape unescaped quotes, and write it to the dest file
	strDestPath = strSourcePath[0:-4] + "_" + strLocale + ".css"
	if fVerbose: print "localize file: %s,%s -> %s"%(strSourcePath, strLocale , strDestPath)
	fIn = open(strSourcePath, 'r')
	fOut = open(strDestPath, 'w')
	
	fInIf = False
	fInElse = False
	fIfIsTrue = False
	for strLine in fIn:
		fWriteLine = False
		if fInIf:
			# If we are in an if, first look for an else or an endif
			if patElseLine.match(strLine):
				# Found an else. Enter else state
				fInIf = False
				fInElse = True
			elif patEndIfLine.match(strLine):
				fInIf = False
				fInElse = False
			else:
				fWriteLine = fIfIsTrue
		elif fInElse:
			if patEndIfLine.match(strLine):
				fInElse = False
			else:
				fWriteLine = not fIfIsTrue
		else:
			m = patIfLine.match(strLine)
			if m:
				# this is an if line
				strVar = m.group(2).lower()
				fNegative = m.group(1) == '!'
				fInIf = True
				if not strVar in dTruths:
					print "*** ERROR: Unknown condition: " + strVar
				fIfIsTrue = dTruths[strVar]
				if fNegative: fIfIsTrue = not fIfIsTrue
			else:
				# Not in an if, this is just a regular line. write it out
				fWriteLine = True
		if fWriteLine:
			fOut.write(processLine(strLine, dTruths, strLocale))

if __name__ == '__main__':
	strPrevPath = None

	if not os.path.exists('client'):
		strPrevPath = os.getcwd()
		os.chdir('..')
	
	if not os.path.exists('client'):
		print "*** ERROR: Could not find client directory. run loc_css.py from /src/picnik/"
	else:
		# Found a client directory.
		strClientPath = os.path.join(os.getcwd(), 'client')

		# First, init astrLocales
		strLocalePath = os.path.join(strClientPath, 'loc')
		astrLocales = initLocales(strLocalePath)
		
		# Now walk through our local targets
		for strRelPath in astrSourceFiles:
			strFullPath = os.path.join(strClientPath, strRelPath)
			# Localize the file
			for strLocale in astrLocales:
				localizeFile(strFullPath, strLocale, astrLocales)
	
	# put the working dir back to where we started
	if strPrevPath:
		os.chdir(strPrevPath)
	
		
