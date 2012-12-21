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
# This script looks for UTF-8 BOM in all of our property files

import sys
import codecs
import os

from p4util import P4File

def extensionMatches(strFilePath, strExtension):
	return strFilePath.lower().endswith('.' + strExtension.lower())

def fixBom(strFilePath):
	fIn = open(strFilePath, 'r')
	strFile = fIn.read()
	fIn.close()
	
	# trim off BOM
	nStart = 0
	while (len(strFile) >= nStart + 3) and (strFile[nStart:nStart+3] == codecs.BOM_UTF8):
		nStart += 3
	
	fOut = P4File.open(strFilePath, 'w')
	fOut.write(codecs.BOM_UTF8)
	fOut.write(strFile[nStart:])
	fOut.close()

def validateFile2(strFilePath, fFix):
	fIn = open(strFilePath, 'r')
	strFile = fIn.read()
	fIn.close()
	
	fValid = True
	strError = ""
	
	fBOMOnlyProblem = False
	
	if len(strFile) < 3:
		strError += "\tfile missing BOM (too short)\n"
		fBOMOnlyProblem = True
		fValid = False
	elif strFile[0:3] != codecs.BOM_UTF8:
		strError += "\tfile missing BOM\n"
		fBOMOnlyProblem = True
		fValid = False

	if len(strFile) > 5:
		if (strFile[0:3] == codecs.BOM_UTF8) and (strFile[3:6] == codecs.BOM_UTF8):
			strError += "\tfile includes duplicate BOM\n"
			fBOMOnlyProblem = True
			fValid = False

	try:
		u = unicode( strFile, 'utf-8')
	except UnicodeDecodeError, ex:
		fValid = False
		fBOMOnlyProblem = False
		strError += "\t" + str(sys.exc_value) + "\n"
		
		# Find the start line and print it out
		iLine = 0
		iStartLinePos = 0
		astrFile = strFile.split('\n')
		while iLine < len(astrFile):
			nLineLen = len(astrFile[iLine]) + 1
			if iStartLinePos + nLineLen >= ex.start:
				# found the line with our error
				break
			else:
				iLine += 1
				iStartLinePos += nLineLen
		
		nPos = ex.start - iStartLinePos
		strError += "\tLine " + str(iLine + 1) + ", pos " + str(nPos + 1) + "\n"
		nBefore = min(30, nPos)
		nAfter = min(30, len(astrFile[iLine])-nPos-1)
		strOut = astrFile[iLine][nPos-nBefore:nPos+nAfter+1]
		strError += "\t" + ('-' * nBefore) + 'v' + "\n"
		strError += "\t" + strOut + "\n"
	
	if not fValid:
		if fFix and fBOMOnlyProblem:
			# Fix the bom
			fixBom(strFilePath)
			fFixed = validateFile(strFilePath, False)
			if fFixed:
				fValid = True
			else:
				# Fix failed
				strError = "Failed to fix: " + strError

		if fValid:
			strResult = "Fixed"
		else:
		  strResult = "Error"
		 
		print strResult + ": UTF8 validation failure: " + strFilePath + "\n" + strError

	return fValid, strFile

def validateFile(strFilePath, fFix):
	fValid, strFile = validateFile2(strFilePath, fFix)
	return fValid

def validateLocFiles(strBasePath, strExtension, fFix):
	fValid = True
	for strFolder in os.listdir(strBasePath):
		strFolderPath = os.path.join(strBasePath, strFolder)
		if os.path.isdir(strFolderPath) and not os.path.islink(strFolderPath):
			for strFile in os.listdir(strFolderPath):
				strFilePath = os.path.join(strFolderPath, strFile)
				if extensionMatches(strFilePath, strExtension):
					# Found a target file
					if not validateFile(strFilePath, fFix):
						fValid = False
	return fValid
	

def validatePropFiles(fFix):
	fValid = True
	if not validateLocFiles(os.path.join('client','loc'), 'properties', fFix): fValid = False
	if not validateLocFiles(os.path.join('server','templates'), 'tmpl', fFix): fValid = False
	if not validateLocFiles(os.path.join('server','loc'), 'txt', fFix): fValid = False
	if not validateLocFiles(os.path.join('server','loc'), 'html', fFix): fValid = False
	if not validateLocFiles(os.path.join('website','app'), 'html', fFix): fValid = False
	if not validateLocFiles(os.path.join('website','app'), 'xml', fFix): fValid = False
	return fValid

if __name__ == '__main__':
	fFix = False
	if len(sys.argv) > 1:
		fFix = sys.argv[1] == '-f'
	validatePropFiles(fFix)
	

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

