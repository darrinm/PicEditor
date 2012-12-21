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

import sys, os
import codecs
from props import PropFile

# we get a diff file and a dest directory (e.g. C:\src\picnik\client\loc\de_DE)
# Merge the properties into the target file.
class InstallPropUtil:
	# returns None if there are no problems with the status
	@staticmethod
	def StatusToErrorMessage(dStatus):
		astrProblems = []
		if dStatus != None:
			if dStatus['astrStatus'][0] != ' ':
				astrProblems.append('Status is ' + dStatus['astrStatus'][0])
			if dStatus['fNeedsUpdate']:
				astrProblems.append('Needs to be updated.')
		if len(astrProblems) > 0:
			return ", ".join(astrProblems)
		return None

	@staticmethod
	def install_props(obPropDiffFile, strDestRoot, strLocale, fnPreprocess = None):
		strDestBase = os.path.join(strDestRoot, strLocale)
		fSuccess = True
		pfDiff = PropFile(obPropDiffFile, fnPreprocess)
		
		# Output property files (with changes) keyed by path
		dpfOut = {}
		
		astrPrint = []
		
		dpfSeen = {}
		
		for strKey, p in pfDiff.dProps.iteritems():
			astrParts = strKey.split('.',1)
			if len(astrParts) != 2:
				raise "ERROR: Diff prop key has no file: " + strKey + ", file = " + str(obPropDiffFile) + ", line: " + str(p.line)
			strOutPropPath = os.path.join(strDestBase, astrParts[0] + '.properties')
			p.key = astrParts[1]
			
			# Now we have the property with a short key and the output property path
			if not strOutPropPath in dpfOut:
				dpfOut[strOutPropPath] = PropFile(strOutPropPath)
			pfOut = dpfOut[strOutPropPath]
			pfOut.addProp(p)
			if obPropDiffFile.find('no_NO') > -1:
				astrPrint.append(strKey)
		
		for pfOut in dpfOut.itervalues():
			pfOut.save()
			
		astrPrint.sort()
		for strPrint in astrPrint:
			print strPrint
		return fSuccess
	
if __name__ == '__main__':
	if len(sys.argv) != 3:
		print "usage: "
		print "install_prop_diff.py <prop_diff_file> <dest_prop_base (e.g. C:\src\picnik\client\loc>"
	else:
		InstallPropUtil.install_props(sys.argv[1], sys.argv[2])
		
