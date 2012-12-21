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


#
# This script creates English place holders for all files/properties
# that are waiting for localization
#	> cd c:\src\picnik
#	> python bin\loc\dummy_loc.py
#
# Edit bin/loc/loc_sources.xml to add new files for localization.

import xml.dom.minidom
# from datetime import datetime
# from datetime import timedelta
import glob, os
from xml.dom.minidom import Node
# from mergeprops import MergeUtil
# from diff_props import DiffUtil
from props import PropFile
import re
import sys
import codecs
import subprocess as sub

from p4util import P4File
from p4util import P4Commit
from p4util import GetP4C

# need to change the default encoding so that we don't get ascii codec errors
# note that using "utf-8" instead of "latin1" gives errors because our source
# 	files apparently have some invalid UTF bytes.
# import sys
# reload(sys)
# sys.setdefaultencoding("latin1")

# BEGIN: Import LocaleInfo
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

fLocError = False
fReportOnly = False
if len(sys.argv) > 1:
	strParam = sys.argv[1].lower()
	
	if strParam == "-t":
		fReportOnly = True
	else:
		print """
Unknown parameter: %s

usage, from root directory, e.g. \\src\\picnik\\

   To create dummy loc strings:
      src\\bin\\dummy_loc.py

   To test for missing loc strings:
      src\\bin\\dummy_loc.py -t
"""	 % strParam
		sys.exit()

astrAdd = []
astrAddToChangeList = []
		
def copyfile(strSrc, strDest):
	if not os.path.exists(os.path.dirname(strDest)):
		os.mkdir(os.path.dirname(strDest))
	P4File.copyfile(strSrc, strDest, 'dummyloc')

def writeFile(strPath, strFile):
	fOut = P4File.open(strPath, 'w')
	fOut.write(codecs.BOM_UTF8)
	fOut.write(strFile)
	fOut.close()

def CopyFrameworkLocales(strNewLocale):
	astrExec = [os.path.join('flex3_2sdk', 'bin', 'copylocale'), 'en_US', strNewLocale]
	print "calling " + ' '.join(astrExec)
	proc = sub.Popen(astrExec, stdout=sub.PIPE, stderr=sub.STDOUT)
	astrResults = []
	for strLine in proc.stdout:
		astrResults.append(strLine)

	return astrResults
	print "Result: " + '\\n'.join(astrResults)
	
def AddNewLocales():
	# create client/loc/<locale> dirs as needed
	for dLocaleInfo in LocaleInfo.LocaleListSortedByName():
		strClientLocPath = os.path.join('client', 'loc', dLocaleInfo['locale'])
		if not os.path.exists(strClientLocPath):
			# Make the client/loc/<locale> directory
			print "Createing locale directory: " + strClientLocPath
			os.mkdir(strClientLocPath)
		
		strFrameworkPath = os.path.join('flex3_2sdk', 'frameworks', 'locale', dLocaleInfo['locale'])
		if not os.path.exists(strFrameworkPath):
			p4c = GetP4C('dummyloc')
			print "Creating dummy localized framework bundles"
			CopyFrameworkLocales(dLocaleInfo['locale'])
			p4c.Add(strFrameworkPath)

def MergeTips(strFile, strLocFile):
	xmlLocTips = xml.dom.minidom.parse(strLocFile)
	dLocTips = {}
	for node in xmlLocTips.getElementsByTagName("Tip"):
		if node.nodeType == Node.ELEMENT_NODE:
			dLocTips[str(node.getAttribute('id'))] = node
	
	fChanges = False
	
	xmlBaseTips = xml.dom.minidom.parse(strFile)
	for node in xmlBaseTips.getElementsByTagName("Tip"):
		if node.nodeType == Node.ELEMENT_NODE:
			strID = str(node.getAttribute('id'))
			if not strID in dLocTips:
				print "Adding missing tip " + strID + " to " + strLocFile
				fChanges = True
				xmlLocTips.documentElement.appendChild(node)
					
	if fChanges:
		strXML = xmlLocTips.toxml(encoding='utf-8')
		writeFile(strLocFile, strXML)
		
# Read the list of locales in client/loc
patLocale = re.compile('[a-z][a-z]_[a-z][a-z]', re.IGNORECASE)


astrLocales = []
for dLocaleInfo in LocaleInfo.LocaleListSortedByName():
	if dLocaleInfo['locale'] != 'en_US':
		astrLocales.append(dLocaleInfo['locale'])

AddNewLocales()
		
# Take care of properties
strPropFileBase = 'client/loc/en_US'
for strPropFileName in os.listdir(strPropFileBase):
	strSrcPropFilePath = os.path.join(strPropFileBase, strPropFileName)
	if strSrcPropFilePath.lower().endswith('.' + 'properties'):
		pfSrc = PropFile(strSrcPropFilePath)
		
		# Found a properties file.
		for strLocale in astrLocales:
			strDstPropFilePath = strSrcPropFilePath.replace('en_US', strLocale)
			if not os.path.exists(strDstPropFilePath):
				if fReportOnly:
					fLocError = True
					print "Missing file: " + strDstPropFilePath
				else:
					copyfile(strSrcPropFilePath, strDstPropFilePath)
			else:
				pfDst = PropFile(strDstPropFilePath, None, 'dummyloc')
				fDirty = False
				astrDirtyLocales = []
				for strKey, p in pfSrc.dProps.iteritems():
					if not (strKey in pfDst.dProps):
						if fReportOnly:
							print os.path.basename(strDstPropFilePath)[0:-10] + strKey + " missing from " + strLocale
						else:
							print os.path.basename(strDstPropFilePath)[0:-10] + strKey + " added to " + strLocale
						pfDst.addProp(p)
						fDirty = True
						fLocError = True
				if fDirty and not fReportOnly:
					pfDst.save()


# open our files
xmlSources = xml.dom.minidom.parse("bin/loc/loc_sources.xml")

# Read list of files to exclude
dtExclude = {}
for node in xmlSources.getElementsByTagName("exclude"):
	if node.nodeType == Node.ELEMENT_NODE:
		for child in node.childNodes:
			if child.nodeType == Node.TEXT_NODE:
				# use glob to find each file in this dir, and then shove it into the zipf ile
				dtExclude[child.nodeValue] = True

# Don't worry about generated diff.properties file
dtExclude['loc/client/en_US/diff.properties'] = True

# process each node in the sources file
for node in xmlSources.getElementsByTagName("source"):
	if node.nodeType == Node.ELEMENT_NODE:
		for child in node.childNodes:
			if child.nodeType == Node.TEXT_NODE:
				# use glob to find each file in this dir, and then shove it into the zipf ile
				strDir = child.nodeValue
				if strDir is not None:
					for file in glob.glob( strDir ):
						if (file.replace('\\','/') in dtExclude):
							pass
							# print "Excluding file: " + file
						else:
							if file.find('en_US') == -1:
								print "Could not find en_US local in " + file
							else:
								for strLocale in astrLocales:
									strLocFile = file.replace('en_US', strLocale)
									if not os.path.exists(strLocFile):
										if fReportOnly:
											fLocError = True
											print "Missing file: " + strLocFile
										else:
											print "Creating dummy file: " + strLocFile
											copyfile(file, strLocFile)
									elif strLocFile.lower().endswith('tips.xml'):
										MergeTips(file, strLocFile)
							
							pass
							#if os.path.exists(file):
								
							#dtLastUpdated = svnLastUpdate(file, datetime.now() + timedelta(seconds=10)) # default last change is tomorrow
							#if dtLastUpdated > dtLastDrop:
							#	print "+ Including fresh file: " + file + ", last changed " + str(dtLastUpdated)
							#	zip.write( file, file, zipfile.ZIP_DEFLATED)
							#else:
							#	print "- Skipping unmodified file: " + file + ", last changed " + str(dtLastUpdated)

P4Commit()
	
if fLocError:
	sys.exit(1)
else:
	sys.exit(0)
