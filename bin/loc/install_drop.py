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
import zlib
import zipfile
import StringIO

from install_prop_diff import InstallPropUtil

from buildXML import buildAllXML
from validate import ValidateAll
from p4util import P4File
from p4util import P4Commit
from p4util import P4Time

# BEGIN: Import LocaleInfo
# Calculate and allow imports relative to client base
strClientRootPath = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", ".."))
# sys.path.insert(0, strClientRootPath)

# Calculate picnik root
strPicnikRoot = # your server root here
# Calculate picnik server root and allow relative imports
strServerRootPath = os.path.join(strPicnikRoot, 'server')
sys.path.insert(0, strServerRootPath)
os.chdir(strPicnikRoot)

from LocaleInfo import LocaleInfo
# END: Import LocaleInfo

fVerbose = False
# fVerbose = True

fBuildXML = True 		#default is True
fPreValidate = False 	#default is True
fPostValidate = True 	#default is True
fFailOnLocalChanges = False # default is True

def extensionMatches(strFilePath, strExtension):
	return strFilePath.lower().endswith('.' + strExtension.lower())

# HTML entity decoder from http://snippets.dzone.com/posts/show/4569
from htmlentitydefs import name2codepoint as n2cp
def substitute_html_entity(match):
	ent = match.group(2)
	if match.group(1) == "#":
		return "&#" + ent + ";"
	else:
		if ent in ['br', 'nbsp', 'gt', 'lt', 'quot']:
			return "&" + ent + ";"
		
		cp = n2cp.get(ent)
		if cp:
			return "&#" + str(cp) + ";"
		else:
			return match.group()

def decode_html_entities(string):
	entity_re = re.compile("&(#?)(\d{1,5}|\w{1,8});")
	return entity_re.subn(substitute_html_entity, string)[0]

patFindQuote = re.compile('([^\\\])\"')
patBold = re.compile('</?b>', re.IGNORECASE)

def isNonBold(strLocale):
	return LocaleInfo.dLocales[strLocale]['nonBold']

def cleanLine(strLine, fRemoveBold, fFixQuotes):
	if fFixQuotes:
		strLine = patFindQuote.sub(r'\1\\\\\\"',strLine)
		
	# Fix html entities such as &acute, etc
	strLine = decode_html_entities(strLine)

	# remove <b> and </b> tags for non-bold languages
	if fRemoveBold:
		strLine = patBold.sub('',strLine)
	return strLine

def cleanNonBold(strLine):
	return cleanLine(strLine, True, True)

def cleanBold(strLine):
	return cleanLine(strLine, False, True)

def copyFile(locSource, fOut, strLocale, fFixQuotes):
	# read the source file, escape unescaped quotes, and write it to the dest file
	fIn = locSource.open('r')
	# write out UTF-8 BOM
	fOut.write(codecs.BOM_UTF8 )
	for strLine in fIn:
		# Fix unescaped quotes
		strLine = cleanLine(strLine, isNonBold(strLocale), fFixQuotes)
		fOut.write(strLine)

def copyFileToPath(locSource, strDestPath, strLang, fFixQuotes):
	# read the source file, escape unescaped quotes, and write it to the dest file
	fOut = P4File.open(strDestPath, 'w')
	copyFile(locSource, fOut, strLang, fFixQuotes)
	fOut.close()

def copyFiles(locSource, strExtension, strBase, strLang, fFixQuotes):
	fSuccess = True
	strDest = os.path.join(strBase, strLang)
	if not os.path.exists(strDest):
		os.mkdir(strDest)
	for strFile in locSource.listdir():
		locSourceSub = locSource.subdir([strFile])
		if extensionMatches(strFile, 'properties.properties'):
			strFile = strFile[0:-11]

		if extensionMatches(strFile, strExtension):
			# Found a file to copy/check the status
			strDestPath = os.path.join(strDest, strFile)
			if fVerbose: print "copying " + str(locSourceSub) + " to " + strDestPath
			elif strLang == "no_NO":
				print strDest.replace("\\","/").replace("C:/src/picnik","").replace("no_NO","*") + "/" + strFile
			copyFileToPath(locSourceSub, strDestPath, strLang, fFixQuotes)
	return fSuccess
		

# We have a path to a diff file, a path to a properties file root dir (e.g. loc/de_DE), and a locale (e.g. de_DE)
# Merge the diff into the properties files
def installClientDiffs(locSourceDiff, strClientDest, strLocale):
	if not os.path.exists(strClientDest):
		os.mkdir(strClientDest)

	if isNonBold(strLocale):
		return InstallPropUtil.install_props(locSourceDiff, strClientDest, strLocale, cleanNonBold)
	else:
		return InstallPropUtil.install_props(locSourceDiff, strClientDest, strLocale, cleanBold)
	
def FixLocale(strLocale):
    if strLocale == 'sv_SE':
        strLocale = 'sv_SV'
    return strLocale.replace('-','_')

def locClientLang(locSourceClient, strLang):
	locSourceDiff = locSourceClient.subdir([strLang, 'diff.properties'])
	strClientDest = os.path.join(strPicnikRoot, 'client','loc')
	return installClientDiffs(locSourceDiff, strClientDest, FixLocale(strLang))

class LocSourcePath:
	def __init__(self, strLocBase):
		self.strLocBase = strLocBase
	
	def __str__(self):
		return "LocSourcePath[" + self.strLocBase + "]"
	
	def subdir(self, astrPath):
		return LocSourcePath(os.path.join(*([self.strLocBase] + astrPath)))
	
	def listdir(self):
		return os.listdir(self.strLocBase)

	def find(self, strPart):
		return self.strLocBase.find(strPart)
	
	def open(self, strMode):
		return open(self.strLocBase, strMode)
	
	def exists(self):
		return os.path.exists(self.strLocBase)

class LocSourceZipPath:
	def __init__(self, zip, strFilename, strPath):
		self.zip = zip
		self.strFilename = strFilename
		self.strPath = strPath
		self.isDir = False
		self.isFile = False
		self.fExists = True
		
		if len(self.strPath) == 0:
			self.isDir = True
		else:
			# take a lookfor the info as a file or a dir
			try:
				zi = self.zip.getinfo(self.strPath)
				self.fExists = True
				self.isFile = True
			except:
				try:
					zi = self.zip.getinfo(self.strPath + "/")
					self.fExists = True
					self.isDir = True
				except:
					pass
					# raise "Path not found: " + self.strPath
		
	@staticmethod
	def create(strFilename):
		return LocSourceZipPath(zipfile.ZipFile(strFilename, 'r'), strFilename, '')

	def find(self, strPart):
		return self.strPath.find(strPart)

	def __str__(self):
		return "LocSourceZipPath[" + self.strFilename + ":" + self.strPath + "]"
	
	def subdir(self, astrPath):
		if len(self.strPath) > 0:
			astrPath = [self.strPath] + astrPath
		return LocSourceZipPath(self.zip, self.strFilename, '/'.join(astrPath))

	# return a list of files below this object
	def listdir(self):
		astrSubFiles = []
		strBase = self.strPath
		if len(strBase) > 0: strBase += '/'
		for zi in self.zip.infolist():
			if str(zi.filename).startswith(strBase):
				strRest = str(zi.filename)[len(strBase):]
				astrParts = strRest.split('/',2)
				if len(astrParts[0]) > 0:
					if not astrParts[0] in astrSubFiles:
						astrSubFiles.append(astrParts[0])
			
		return astrSubFiles

	def open(self, strMode):
		strContents = self.zip.read(self.strPath)
		return StringIO.StringIO(strContents)

	def exists(self):
		return self.fExists

def LocFiles(locSource, strDest, astrExtensions, strExclude):
	fSuccess = True
	
	if locSource.exists():
		for f in locSource.listdir():
			if not f == strExclude and not str(f).startswith('.'):
				# Loop through languages
				locSourceSub = locSource.subdir([f])
				for strExtension in astrExtensions:
					if not copyFiles(locSourceSub, strExtension, strDest, FixLocale(f), False): fSuccess = False
	else:
		if fVerbose: print "No source files found: " + str(locSource)
	return fSuccess
	
def locAll(strLocBase):
	fFilesOK = True
	
	# strLocBase the root of the following directory structure:
	# ./client/loc/it_IT/*.properties
	# ./server/it_IT/*.txt, *.html
	# ./server/templates/it_IT/*.tmpl
	# ./website/app/it_IT/*.html
	# ./website/app/it_IT/*.xml
	if strLocBase[-4:].lower() == ".zip":
		locSource = LocSourceZipPath.create(strLocBase)
	else:
		locSource = LocSourcePath(strLocBase)
		
	if fVerbose: print "localizing dirs in: " + str(locSource)

	locSourceClient = locSource.subdir(['loc','client'])
	# strLocSource = os.path.join(strLocBase, 'loc','client')
	
	print "Properties:"
	# First, take care of the client files, looping through locales
	for f in locSourceClient.listdir():
		# Loop through languages
		if not str(f).startswith('.'):
			if not locClientLang(locSourceClient, f): fFilesOK = False
	
	print
	print "Files:"
	
	# web app source files
	if not LocFiles(locSource.subdir(['website','app']), os.path.join(strPicnikRoot, 'website','app'),
			['html', 'txt', 'xml'], None): fFilesOK = False
	
	# web server source files
	if not LocFiles(locSource.subdir(['server','loc']), os.path.join(strPicnikRoot, 'server','loc'),
			['html', 'txt', 'xml'], None): fFilesOK = False
	
	# templates source files
	if not LocFiles(locSource.subdir(['server','templates']), os.path.join(strPicnikRoot, 'server','templates'),
			['tmpl'], 'templates'): fFilesOK = False
			
	return fFilesOK

def findLocBase(strBase):	
	strLocBase = ""
	if os.path.exists(strBase) and os.path.isfile(strBase) and strBase[-4:].lower() == ".zip":
		return strBase
	
	for f in os.listdir(strBase):
		strFullPath = os.path.join(strBase, f)
		if os.path.isdir(strFullPath) and not os.path.islink(strFullPath):
			if f in ["loc_sources"]:
				return os.path.join(strBase, 'loc_sources')
			elif f in ["server", "website", "loc"]:
				return strBase
			else:
				strLocBase = findLocBase(strFullPath)
				if strLocBase != "":
					return strLocBase
	return ""

if __name__ == '__main__':
	if len(sys.argv) > 1:
		strLocBase = findLocBase(sys.argv[1])
		if (strLocBase == ''):
			print "No loc files found in: " + sys.argv[1]
		else:
			nStart = time()
			print "pre-validating..."
			if fPreValidate:
				if not ValidateAll():
					print "ERROR: One or more existing files is invalid. Please fix this first."
					sys.exit()
					
			print "making sure no files are checked out in p4..."
			if fFailOnLocalChanges:
				# Don't let local changes go through
				GetP4C().ExitOnLocalChanges()

			print "installing changes..."
			locAll(strLocBase)

			if fBuildXML:
				print "building xml..."
				buildAllXML()
			
			if fPostValidate:
				print "validating results..."
				ValidateAll(True)

			P4Commit()
			nEnd = time()
			nP4Time = P4Time()
			nElapsed = nEnd - nStart
			print "install drop time:", nElapsed, "p4 time", nP4Time, str(int(100 * nP4Time / nElapsed)) + "%"
			
	else:
		print "usage: install_drop.py <drop base path>"
		
