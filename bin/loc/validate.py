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

import os
import sys

import threading
import time

from validate_xml import ValidateXmlContents
from verify_utf8_props import validateFile2
# from validate_tmpl import ValidateTemplateContents
from flex3_fix_property_files import validatePropsFile

strCDNServer = 'cdn.mywebsite.com'

######### BEGIN: Set up paths to do imports ###########
import sys
import os
import re
import xml.dom.minidom
import codecs

from p4util import P4File
from p4util import P4Commit

strValidateDir = os.path.abspath(os.path.dirname(__file__))
strSrcRoot = os.path.abspath(os.path.join(strValidateDir, '..', '..'))
# cd to /src/picnik/ root dir. InitConfig assumes this is where we are
os.chdir(strSrcRoot)

from optparse import Values
strIniPath = os.path.join(strSrcRoot, 'picnik.ini')
if not os.path.exists(strIniPath):
	print "Creating Linux picnik.ini"
	fout = open(strIniPath, 'w')
	fout.write("""
[General]
servername=www.mywebsite.com

[Locations]
serverbinDir=%(baseDir)s/serverbin_lin
""")
	fout.close()
	
options = Values({'picnikini': os.path.join(strSrcRoot, 'picnik.ini')})

# from LocaleInfo import LocaleInfo

######### END: Set up paths to do imports ###########

# Globals
fAllFilesFound = False
astrFiles = []
nNextAvailableFile = 0
fAllValid = True

fVerbose = True
nThreads = 5
strFileTypeFilter = None

lkFiles = threading.Lock()


def PathToParts(strFilePath):
	astrParts = []
	strLeft = strFilePath
	while len(strLeft) > 10:
		astrSplit = os.path.split(strLeft)
		astrParts[0:0] = [astrSplit[1]]
		strLeft = astrSplit[0]
	astrParts[0:0] = [strLeft]
	return astrParts

# returns -1 if not found
def FindPat(pat, astrParts):
	for i in range(0, len(astrParts)):
		if pat.match(astrParts[i]):
			return i
	return -1

# Return strTemplatePath, strLocale
def ExtractTemplateAndLocale(strFilePath):
	astrPathParts = PathToParts(strFilePath)
	patLocale = re.compile('[a-z][a-z]_[a-z][a-z]', re.IGNORECASE)
	iLocale = FindPat(patLocale, astrPathParts)
	
	if iLocale == -1:
		strTemplateName = astrPathParts[-1]
		strLocale = "en_US"
	else:
		strTemplateName = os.path.join(*astrPathParts[iLocale+1:])
		strLocale = astrPathParts[iLocale]
	strTemplateName = os.path.splitext(strTemplateName)[0] # remove the extension
	return strLocale, strTemplateName

def ValidateTemplateContents(strFile, strFilePath, fFix):
	# first, figure out the locale (if any)
	strLocale, strTemplateName = ExtractTemplateAndLocale(strFilePath)
	SetLocale(strLocale)
	
	# first, check for #encoding UTF-8 on line one
	# We can fix this if needed.
	# Read the first line
	astrParts = strFile.split('\n', 1)
	strFirstLine = astrParts[0]
	if (len(astrParts) == 1):
		strRest = ''
	else:
		strRest = astrParts[1]
	
	fSuccess = True
	
	if strFile.find('#encoding UTF-8') == -1:
		if strFile.find('#encoding') != -1:
			print "Error: Template: " + strFilePath + "\n\tShould be #encoding UTF-8. Found other encoding.\n"
			return False
		else:
			if fFix:
				# No encoding present. We can fix it.
				# First, remove the BOM (we'll add it back later)
				if strFirstLine[0:3] == codecs.BOM_UTF8:
					# has BOM, remove it
					strFirstLine = strFirstLine[len(codecs.BOM_UTF8):]
				fOut = P4File.open(strFilePath, 'w')
				fOut.write(codecs.BOM_UTF8)
				fOut.write('#encoding UTF-8')
				fOut.write('\n')
				fOut.write(strFirstLine)
				fOut.write('\n')
				fOut.write(strRest)
				fOut.close()
				strResult = "Fixed"
			else:
				strResult = "Error"
				fSuccess = False
				
			print strResult + ": Template error: " + strFilePath + "\n\t#encoding UTF-8 should be the first line of every template\n"
	
	if fSuccess:
		try:
		    t = template = APIUtil.GetTemplate(strTemplateName)
		except ImportError, e:
		    pass # Ignore import errors, we don't know which imports to use
		except:
		    print "Error: Template error: " + strFilePath
		    for i in range(0, len(sys.exc_info())-1):
		        print str(sys.exc_info()[i])
		    fSuccess = False
	   
	return fSuccess
	

def getNextFile():
	lkFiles.acquire()
	global astrFiles
	global nNextAvailableFile
	
	strFile = None
	
	if len(astrFiles) > nNextAvailableFile:
		strFile = astrFiles[nNextAvailableFile]
		nNextAvailableFile += 1
	
	lkFiles.release()
	return strFile

def getExtension(strFilePath):
	nBreak = strFilePath.rfind('.')
	if nBreak == -1: return '' # no extension
	return strFilePath[nBreak+1:]

def extensionMatches(strFilePath, strExtension):
	return strFilePath.lower().endswith('.' + strExtension.lower())

def isLocale(strLocale):
	if len(strLocale) != 5: return False
	return strLocale[2] == '_'

def removeExtension(strFile):
	nBreak = strFile.rfind('.')
	if nBreak == -1: return strFile
	return strFile[0:nBreak]

def FilterMatches(strExt, strFilter):
	if strFilter == None:
		return True
	if strFilter.lower() == strExt.lower():
		return True
	return False

class FileFinder( threading.Thread ):
	def run (self):
		nStart = time.time()
		dPaths = {
				'client/loc/<locale>': 'properties', # property files
				}
				
		self.dFileByType = {}

		# Loop through all files and add them to astrFiles
		for strKey in dPaths.iterkeys():
			self.AddFiles(strKey, dPaths[strKey])
			
		global fAllFilesFound
		fAllFilesFound = True
		nElapsed = time.time() - nStart
		# print "File finder time: " + str(nElapsed)

	def AddFiles(self, strPathParam, strExtensions):
		global strFileTypeFilter
		astrPathParams = strPathParam.split('/')
		astrPathParams = [os.getcwd()] + astrPathParams
		
		astrExtensions = strExtensions.split(',')
		if strFileTypeFilter != None:
			# Only support filter matches
			astrFilteredExtensions = []
			for strExt in astrExtensions:
				if FilterMatches(strExt, strFileTypeFilter):
					astrFilteredExtensions.append(strExt)
			astrExtensions = astrFilteredExtensions
		
		if astrPathParams[-1] == '<locale>':
			strLocBasePath = os.path.join(*astrPathParams[0:-1])
			for strLocale in os.listdir(strLocBasePath):
				if isLocale(strLocale):
					self._AddFiles(os.path.join(strLocBasePath, strLocale), astrExtensions)
		else:
			self._AddFiles(os.path.join(*astrPathParams), astrExtensions)

	def _AddFiles(self, strFolderPath, astrExtensions):
		for strFile in os.listdir(strFolderPath):
			strFilePath = os.path.join(strFolderPath, strFile)
			if extensionMatches(strFilePath, "svn"):
				pass
			elif strFile == "shapesV2":
				pass
			elif os.path.isdir(strFilePath):
				self._AddFiles(strFilePath, astrExtensions)
			elif getExtension(strFilePath) in astrExtensions:
				self._AddFile(strFilePath)

	def _AddFile(self, strFilePath):
		global astrFiles
		astrFiles.append(strFilePath)
		strExt = getExtension(strFilePath)
		if strExt in self.dFileByType:
			self.dFileByType[strExt] += 1
		else:
			self.dFileByType[strExt] = 1

class Validator ( threading.Thread ):
	def run (self):
		fDone = False
		nFiles = 0
		while not fDone:
			strNextFile = getNextFile()
			if strNextFile == None:
				global fAllFilesFound
				if fAllFilesFound:
					fDone = True
				else:
					import time
					time.sleep(0.01)
			else:
				self.validateFile(strNextFile)
				nFiles += 1

				
	def validateFile(self, strFilePath):
		strType = getExtension(strFilePath)
		# all files get utf-8 validation first (can be fixed)
		# then, perform additional validation:
		
		fValid, strFile = validateFile2(strFilePath, self.fFix)
		
		# properties leading blank lines (can be fixed)
		# tmpl: cheetah validation
		# xml: xml validation
		if strType == "properties":
			# Check for blank lines
			if not validatePropsFile(strFile, strFilePath, self.fFix):
				fValid = False
		elif strType == "tmpl":
			if not ValidateTemplateContents(strFile, strFilePath, self.fFix):
				fValid = False
			pass
		elif strType == "xml":
			if not ValidateXmlContents(strFile, strFilePath):
				fValid = False
		
		global fAllValid
		if not fValid: fAllValid = False
		

# Returns True if valid, False if not
def ValidateAll(fFix=False):
	print "Validating loc files..."
	tmStart = time.time()
	# Loop through all source files
	# For files of type "needs validation", add those files to or validate queue
	# Spawn N threads to go through the queue and perform validation
	# When the last thread completes, return the status (success/failure)
	global fAllValid
	global astrFiles
	global fAllFilesFound
	global nNextAvailableFile

	fAllValid = True
	astrFiles = []
	fAllFilesFound = False
	nNextAvailableFile = 0
	
	ff = FileFinder()
	ff.start()
	
	avalidators = []
	global nThreads
	for i in range(0,nThreads):
		vd = Validator()
		vd.fFix = fFix
		avalidators.append(vd)
		vd.start()
	ff.join()
	
	for vd in avalidators:
		vd.join()

	tmEnd = time.time()
	
	# print "elapsed time: " + str(tmEnd - tmStart)
		
	for strKey in ff.dFileByType.iterkeys():
		print "Validated " + str(ff.dFileByType[strKey]) + " " + strKey + " files"
	
	return fAllValid
		
if __name__ == '__main__':
	from optparse import OptionParser
	parser = OptionParser(usage="usage: %prog [options]")
	filetypes = ['all', 'properties', 'tmpl', 'txt', 'html', 'xml']
	parser.add_option('-t', '--type', choices=filetypes, default='all', dest='filetype', help='Type of files to parse (' + ', '.join(filetypes) + ") [default: %default]")
	parser.add_option('-f', '--fix', action="store_true", dest="fix", default=False, help="Fix any fixable problems found")
	(options, args) = parser.parse_args()
	if len(args) > 0:
		parser.error("Incorrect number of arguments. Expected none, got " + str(args))
		sys.exit(1)

	if options.filetype == "all":
		strFileTypeFilter = None
	else:
		strFileTypeFilter = options.filetype

	fValid = ValidateAll(options.fix)
	P4Commit()
	if not fValid:
		print "Error: one or more files invalid"
		sys.exit(1)
	else:
		print "All files valid"
