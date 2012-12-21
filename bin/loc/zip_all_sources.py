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
import glob, os
from xml.dom.minidom import Node
from mergeprops import MergeUtil
from diff_props import DiffUtil
import shutil
import urllib

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

from loc_sources_versions import GetGroupInfo
from loc_sources_versions import PrintAllGroupInfo

dGroupInfo = None
if len(sys.argv) >= 2:
	dGroupInfo = GetGroupInfo(sys.argv[1])

if dGroupInfo == None:
	print "usage:"
	print "  cd \\src\\picnik"
	print "  bin\\loc\\zip_all_sources.py <LocGroup>"
	print "      where <LocGroup> is one of: "
	PrintAllGroupInfo()
	sys.exit()

strChangeDesc = "Picnik complete loc sources for " + dGroupInfo['strName'] + " on " + str(dtNow.year) + "-" + str(dtNow.month) + "-" + str(dtNow.day)

# Create a new property diff
# Create a new merge state, diff, and overwrite old merge state with new state
strDiffFileBase = 'loc/client/en_US'
strDiffFilePath = strDiffFileBase + '/diff.properties'

if not os.path.exists(strDiffFileBase):
	os.mkdir(strDiffFileBase)

	# Merge files to create the new snapshot
MergeUtil.mergeFilesToPath('client/loc', strDiffFilePath)

# open our files
xmlSources = xml.dom.minidom.parse("bin/loc/loc_sources.xml")
zip = zipfile.ZipFile("loc_sources.zip", "w")

astrFilesToCheck = []

# process each node in the sources file
for node in xmlSources.getElementsByTagName("source"):
	if node.nodeType == Node.ELEMENT_NODE:
		for child in node.childNodes:
			if child.nodeType == Node.TEXT_NODE:
				# use glob to find each file in this dir, and then shove it into the zipf ile
				strDir = child.nodeValue
				print strDir
				if strDir is not None:
					for file in glob.glob( strDir ):
						print "+ Including file: " + file
						zip.write( file, file, zipfile.ZIP_DEFLATED)
						astrFilesToCheck.append(str(file))
						
# all done
zip.close()

p4c = GetP4C(strChangeDesc)

# Calculate the max change number
files = p4c.GetFiles(astrFilesToCheck)
nMaxChangeNumber = 0
for i in range(0, len(files)):
	nChange = int(files[i].Change())
	nMaxChangeNumber = max(nMaxChangeNumber, nChange)
		
strOldPropsFileExtension = dGroupInfo['strPropsFileExtension']
astrLocs = dGroupInfo['astrLocs']
strOldPropsFilePath = 'loc/client/props_at_last_drop' + strOldPropsFileExtension + '.properties'

strLastChangeRecordFilePath = 'loc/client/last_sent_change_record' + strOldPropsFileExtension + '.txt'

fOut = P4File.open(strOldPropsFilePath, 'w', strChangeDesc)
fIn = open(strDiffFilePath, 'r')
fOut.write(fIn.read())
fIn.close()
fOut.close()

os.remove(strDiffFilePath)

print "Last change number:", nMaxChangeNumber
fOut = P4File.open(strLastChangeRecordFilePath, 'w', strChangeDesc)
fOut.write(str(nMaxChangeNumber))
fOut.write("\n")
fOut.close()

strEmailSubject = "Pincik " + str(datetime.now().date()) + " complete loc sources"
if dGroupInfo != None:
	strEmailSubject += " for: " + ', '.join(astrLocs)
	
print "Zipping complete. Next step is to send the mail."
print "to: Welocalize"
print "Subject: " + strEmailSubject
print "Attach: loc_sources.zip"
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

