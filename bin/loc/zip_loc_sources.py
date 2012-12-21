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
# This script gathers all the various files that need to be localized into a single zip file.
# It should be run from the root of the repository, for example:
#	> cd c:\src\picnik
#	> python bin\loc\zip_loc_sources.py
#
# It will create a file named loc_sources.zip containing all the files that need to be localized.
# Edit bin/loc/loc_sources.xml to add new files for localization.

import zlib
import zipfile
import xml.dom.minidom
from datetime import datetime
from datetime import timedelta
import urllib

import glob, os
from xml.dom.minidom import Node
from mergeprops import MergeUtil
from diff_props import DiffUtil
import shutil

from loc_sources_versions import GetGroupInfo
from loc_sources_versions import PrintAllGroupInfo

# need to change the default encoding so that we don't get ascii codec errors
# note that using "utf-8" instead of "latin1" gives errors because our source
# 	files apparently have some invalid UTF bytes.
import sys
reload(sys)
sys.setdefaultencoding("latin1")

# Calculate and allow imports relative to client base
strClientRootPath = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", ".."))
sys.path.insert(0, strClientRootPath)

# Calculate picnik root
strPicnikRoot = # your server root here
# Calculate picnik server root and allow relative imports
strServerRootPath = os.path.join(strPicnikRoot, 'server')
sys.path.insert(0, strServerRootPath)

os.chdir(strPicnikRoot)

from p4util import P4File
from p4util import P4Commit
from p4util import P4Time
from p4util import GetP4C

from datetime import datetime

dtNow = datetime.now()
strChangeDesc = str(dtNow.year) + "-" + str(dtNow.month) + "-" + str(dtNow.day) + " loc snapshot"

if len(sys.argv) < 2 or len(sys.argv) > 3 or GetGroupInfo(sys.argv[1]) == None:
	print "usage:"
	print "  cd <your server root>"
	print "  python2.4 bin/loc/zip_loc_sources.py <LocGroup>"
	print "      where <LocGroup> is one of: "
	PrintAllGroupInfo()
	sys.exit()

strGroupNameSuffix = GetGroupInfo(sys.argv[1])['strPropsFileExtension']
astrLocs = GetGroupInfo(sys.argv[1])['astrLocs']

nLastUpdateChangeNumber = 0
	
if len(sys.argv) == 3:
	nLastUpdateChangeNumber = int(sys.argv[2])
	if nLastUpdateChangeNumber == -2:
		nLastUpdateChangeNumber = 18944585

strOutFileExtension = '_'.join(astrLocs)
	
def ReadChangeNumber(strFile, nDefaultChangeNumber):
	nChangeNumber = 0
	try:
		fIn = open(strFile, 'r')
		strFile = fIn.read()
		fIn.close()
		nChangeNumber = int(strFile)
	except:
		nChangeNumber = 0
	if nChangeNumber == 0:
		nChangeNumber = nDefaultChangeNumber
	return nChangeNumber

# Create a new property diff
# Create a new merge state, diff, and overwrite old merge state with new state
strOldPropsFilePath = 'loc/client/props_at_last_drop' + strGroupNameSuffix + '.properties'
strLastChangeRecordFilePath = 'loc/client/last_sent_change_record' + strGroupNameSuffix + '.txt'
strNewPropsFilePath = 'loc/client/new_drop.properties'
strDiffFileBase = 'loc/client/en_US'
strDiffFilePath = strDiffFileBase + '/diff.properties'

# Merge files to create the new snapshot
MergeUtil.mergeFilesToPath('client/loc', strNewPropsFilePath) # new props file path is not under p4


# Diff
print "Including changed/new properties: "
if not os.path.exists(strDiffFileBase):
	os.mkdir(strDiffFileBase)
DiffUtil.diffPropsToPath(strOldPropsFilePath, strNewPropsFilePath, strDiffFilePath, True)
print

# Replace old props snapshot with new props
P4File.copyfile(strNewPropsFilePath, strOldPropsFilePath, strChangeDesc)

# open our files
xmlSources = xml.dom.minidom.parse("bin/loc/loc_sources.xml")
strZipPath = os.path.expanduser("~/loc_sources_" + strOutFileExtension + ".zip")
zip = zipfile.ZipFile(strZipPath, "w")

if nLastUpdateChangeNumber == 0:
	nLastUpdateChangeNumber = ReadChangeNumber(strLastChangeRecordFilePath, -1) # default last drop is eons ago

print "nLastUpdateChangeNumber = ", nLastUpdateChangeNumber

# Read list of files to exclude
dtExclude = {}
for node in xmlSources.getElementsByTagName("exclude"):
	if node.nodeType == Node.ELEMENT_NODE:
		for child in node.childNodes:
			if child.nodeType == Node.TEXT_NODE:
				# use glob to find each file in this dir, and then shove it into the zipf ile
				dtExclude[child.nodeValue] = True


astrIncludeChangedFiles = []
astrExcludeUnchangedFiles = []
astrExcludeFiles = []

astrFilesToCheck = []

# Now create a list of files we care about
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
							astrExcludeFiles.append(str(file))
						else:
							# Found a filew we ar considering
							if str(file) != strDiffFilePath:
								astrFilesToCheck.append(str(file))

# Now move diff.properties to astrIncludeChangedFiles
astrIncludeChangedFiles.append(strDiffFilePath)

p4c = GetP4C(strChangeDesc)
files = p4c.GetFiles(astrFilesToCheck)

if len(files) != len(astrFilesToCheck):
	print len(files), len(astrFilesToCheck)
	print "found files:"
	for i in range(0, len(files)):
		print files[i].Change(), files[i].DepotFile(), astrFilesToCheck[i]
	print "missing files?"
	for i in range(len(files), len(astrFilesToCheck)):
		print astrFilesToCheck[i]
	print "ERROR: some files appear to missing from p4. Try g4 nothave"
	raise Exception("Missing files")

nMaxChangeNumber = nLastUpdateChangeNumber
for i in range(0, len(files)):
	nChange = int(files[i].Change())
	strFilePath = astrFilesToCheck[i]
	if nChange > nLastUpdateChangeNumber:
		nMaxChangeNumber = nChange
		astrIncludeChangedFiles.append(strFilePath)
	else:
		astrExcludeUnchangedFiles.append(strFilePath)

for strFilePath in astrIncludeChangedFiles:
	zip.write( strFilePath, strFilePath, zipfile.ZIP_DEFLATED)

print "Including changed files:"
astrIncludeChangedFiles.sort()
for strChanged in astrIncludeChangedFiles:
	print " - " + strChanged
print

print "Excluding unchanged files:"
astrExcludeUnchangedFiles.sort()
for strEx in astrExcludeUnchangedFiles:
	print " - " + strEx
print

print "Excluding exclude:"
for strEx in astrExcludeFiles:
	print " - " + strEx
print

# all done
zip.close()

print "new last change number", nMaxChangeNumber
fOut = P4File.open(strLastChangeRecordFilePath, 'w', strChangeDesc)
fOut.write(str(nMaxChangeNumber))
fOut.write("\n")
fOut.close()

# remove temporary files
os.remove(strDiffFilePath)
os.remove(strNewPropsFilePath)

print "Update the snapshot file before running the script: " + strOldPropsFilePath
print "Make sure you check in the snapshot file when you are done: "
dtNow = datetime.now().date()
strNow = str(dtNow)

print '     g4 upload  ' + str(p4c.GetChangeListNumber())
print "email this zip file: " + strZipPath
strEmailSubject = "Pincik " + strNow + " loc sources for: " + ', '.join(astrLocs)
print "email subject: " + strEmailSubject

# Call out to Mac automator to open an email (using your default email client) with the attachment, ready to go
os.system("automator -D locName='" + strEmailSubject + "' -D locPath='" + strZipPath + "' bin/loc/sendLocDrop.workflow")
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

