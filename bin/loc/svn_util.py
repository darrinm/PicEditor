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

import subprocess as sub
import os

# execute a command with optional arguments, return an array of stdout strings
def svnCommand(strCommand, *astrArgs):
	astrExec = ['svn', strCommand] + list(astrArgs)
	proc = sub.Popen(astrExec, stdout=sub.PIPE, stderr=sub.STDOUT)
	astrResults = []
	for strLine in proc.stdout:
		astrResults.append(strLine)

	return astrResults

# Get the status of a file
# Returns a list of status objects
# pass fShowUpdates=True to get back the ninth column (whether or not there are updates on the server)
def svnStatus(strFile, fShowUpdates=False):
	astrExtra = []
	if fShowUpdates:
		astrExtra.append('-u')
	astrExtra.append('-q')
	
	astrLines = svnCommand('stat', strFile, *astrExtra)
	
	ddStatus = {}
	
	for strLine in astrLines:
		if strLine.startswith('--- Changelist') or strLine.startswith('Status against revision'):
			continue
		if len(strLine.strip()) < 9:
			continue
		
		# found a line with a file on it, we think
		dFileStatus = {}
		dFileStatus['astrStatus'] = []
		for i in range(0, 7):
			dFileStatus['astrStatus'].append(strLine[i])
		
		if fShowUpdates:
			strFileName = strLine.rstrip()[21:]
			dFileStatus['strChangeNum'] = strLine[9:18].lstrip()
			dFileStatus['fNeedsUpdate'] = strLine[8:9] == '*'
		else:
			strFileName = strLine.rstrip()[9:]

		dFileStatus['strName'] = strFileName
		dFileStatus['strLine'] = strLine.rstrip()
		ddStatus[strFileName] = dFileStatus
	return ddStatus

dStatusCache = {}

def svnStatusWithCache(strBase, strFile):
	global dStatusCache
	if not strBase in dStatusCache:
		strPath = os.getcwd()
		os.chdir(strBase)
		dStatusCache[strBase] = svnStatus('.', True)
		os.chdir(strPath)
	
	ddStatus = dStatusCache[strBase]
	
	strFile = strFile.replace('/', '\\')
	if strFile in ddStatus:
		return ddStatus[strFile]
	else:
		return None # No changes

def CreateTemp(strPath, strContents):
	DeleteTemp(strPath)
	fout = open(strPath, 'wb')
	fout.write(strContents)
	fout.close()

def DeleteTemp(strPath):
	if os.path.exists(strPath):
		os.remove(strPath)

def svnAddToChangelist(strFile, strChangelist):
	return svnCommand('cl', strChangelist, strFile)

def absPaths(astrFiles):
	return [os.path.abspath(strPath) for strPath in astrFiles]

def findCommonAncestor(strPath1, strPath2):
	i = 0 # i points beyond last match
	while len(strPath1) > i and len(strPath2) > i and strPath1[i:i+1] == strPath2[i:i+1]:
		i += 1
	return strPath1[0:i]
	
def findCommonAncestorPath(astrFiles):
	strAncestor = astrFiles[0]
	for strPath in astrFiles:
		strAncestor = findCommonAncestor(strPath, strAncestor)
	return strAncestor
	
def svnAddManyToChangelist(astrFiles, strChangelist, fIgnoreUnchanged=False):
	astrFiles.sort()
	if fIgnoreUnchanged:
		# First, update our list by removing unchanged files

		# Normalize our list and find the common base
		# on which to perform our svn status
		astrFiles = absPaths(astrFiles)
		astrFiles.sort()
		
		dFiles = dict([(strFile.strip(), True) for strFile in astrFiles])
		
		strBasePath = findCommonAncestorPath(astrFiles)
		astrStat = svnCommand('st', strBasePath)
		
		# astrStat contains a list of lines. Each line starts with a letter. Possible letters include:
		# 'ACDIMR!~': Changed in some way. Add to change list.
		astrChanged = []
		
		for strStatLine in astrStat:
			chStat = strStatLine[0:1]
			strFileFound = strStatLine[8:].strip()
			if chStat in 'ACDIMR!~':
				if strFileFound in dFiles:
					astrChanged.append(strFileFound)
		astrFiles = astrChanged
		if len(astrFiles) == 0:
			return [] # nothing to do

	strPath = 'dummy_loc_add_to_cl_temp.txt'
	CreateTemp(strPath, '\n'.join(astrFiles))
	
	astrRet = svnCommand('cl', strChangelist, '--targets', strPath)
	DeleteTemp(strPath)
	return astrRet

def svnAdd(strFile):
	svnCommand('add', strFile)
	
def svnAddMany(astrFiles):
	strPath = 'dummy_loc_add_temp.txt'
	CreateTemp(strPath, '\n'.join(astrFiles))
	astrRet = svnCommand('add', '--targets', strPath)
	DeleteTemp(strPath)
	return astrRet
	
# return a last updated datetime
def svnLastUpdate(strFile, dtDefault):
	from time import strptime
	from datetime import datetime
	dtResult = None
	try:
		for strLine in svnCommand('info', strFile):
			if strLine.startswith('Last Changed Date'):
				strTime = strLine[19:38] # extract the date. Would be better to use regexp
				tmResult = strptime(strTime, '%Y-%m-%d %H:%M:%S')
				dtResult = apply(datetime, tmResult[0:-3])
	except:
		dtResult = None
	if not dtResult:
		dtResult = dtDefault
	return dtResult

if __name__ == '__main__':
	import sys
	if len(sys.argv) <= 1:
		print "usage: "
		print "svn_util.py <command> <params>"
	else:
		astrLines = svnCommand(sys.argv[1], *sys.argv[2:])
		print ''.join(astrLines)
