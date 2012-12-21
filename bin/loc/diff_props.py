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

import sys
import codecs
from props import PropFile

class DiffUtil:
	@staticmethod
	def diffPropsToPath(strOldProps, strNewProps, strOutPath, fVerbose=False):
		fOut = open(strOutPath, 'w')
		DiffUtil.diff_props(strOldProps, strNewProps, fOut, fVerbose)
		fOut.close()
		
	@staticmethod
	def diff_props(strOldProps, strNewProps, fOut, fVerbose=False):
		fOut.write(codecs.BOM_UTF8)
		pfOld = PropFile(strOldProps)
		pfNew = PropFile(strNewProps)
	
		apropDiff = []
		
		for strKey, p in pfNew.dProps.iteritems():
			if not (strKey in pfOld.dProps) or not p.equals(pfOld.dProps[strKey]):
				if fVerbose: print " - " + strKey
				apropDiff.append(p)
		apropDiff.sort(lambda x, y: cmp(x.key, y.key))
		
		for p in apropDiff:
			p.writeTo(fOut)

if __name__ == '__main__':
	if len(sys.argv) < 3 or len(sys.argv) > 4:
		print "usage: "
		print "diff_props <orig_props> <new_props> <optional: output_file>"
	else:
		if len(sys.argv) > 3:
			fOut = open(sys.argv[3], 'w')
		else:
			fOut = sys.stdout
		DiffUtil.diff_props(sys.argv[1], sys.argv[2], sys.stdout)
		
