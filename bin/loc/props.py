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
import codecs


class Prop:
	def __init__(self, astrComments, strPropLine, nLine):
		self.astrComments = astrComments
		if len(strPropLine) == 0:
			raise "ERROR: empty property line!"
		astrParts = strPropLine.split('=',1)
		if len(astrParts) < 2:
			raise "ERROR: property line missing '=': " + strPropLine
		self.key = astrParts[0].strip()
		self.value = astrParts[1].strip()
		self.line = nLine

	def equals(self, pIn):
		return (self.key == pIn.key) and (self.value == pIn.value)
	
	def writeTo(self, fOut):
		if len(self.astrComments) > 0:
			fOut.write('\n') # insert a blank line before any comment block
			for strComment in self.astrComments:
				fOut.write(strComment.strip() + "\n")
		fOut.write(self.key + " = " + self.value + "\n")

class PropFile:
	def __init__(self, obPath, fnPreprocess=None):
		self.obPath = obPath
		self.dProps = {}
		self.readProps(fnPreprocess)
		
	def addProp(self, p):
		self.dProps[p.key] = p
			
	def addPropStr(self, astrComments, strPropLine, nLine, fnPreprocess=None):
		if fnPreprocess != None:
			strPropLine = fnPreprocess(strPropLine)
		p = Prop(astrComments, strPropLine, nLine)
		self.addProp(p)

	def save(self):
		fOut = open(self.obPath, 'w')
		fOut.write(codecs.BOM_UTF8)
		
		aProps = []
		for p in self.dProps.itervalues():
			aProps.append(p)

		aProps.sort(lambda x, y: cmp(x.key, y.key))
		for p in aProps:
			p.writeTo(fOut)
		fOut.close()
	
	def readProps(self, fnPreprocess=None):
		nLine = 0
		try:
			fIn = None
			try:
				fIn = self.obPath.open('r')
			except:
				fIn = None
			if fIn == None and os.path.exists(self.obPath):
				fIn = open(self.obPath, 'r')

			if fIn == None:
				self.dProps = {}
			else:
				astrComments = []
				fInMultiLineProp = False
				for strLine in fIn:
					nLine += 1
					strLine = strLine.strip()
					if len(strLine) > 2 and strLine[0:3] == codecs.BOM_UTF8:
						strLine = strLine[3:]
						
					strLine = strLine.strip('\0')
	
					if fInMultiLineProp:
						strPropLine += '\n' + strLine
						fInMultiLineProp = False
						
						# More efficient to go the other way, but this is easier to write.
						for ch in strLine.strip():
							if ch != '\\':
								fInMultiLineProp = False
							else:
								fInMultiLineProp = not fInMultiLineProp
						if not fInMultiLineProp:
							self.addPropStr(astrComments, strPropLine, nLine, fnPreprocess)
							astrComments = []
					else:
						if len(strLine) > 0:
							if strLine[0] == '#':
								astrComments.append(strLine)
							else:
								# found a property
								strPropLine = strLine
								if strPropLine[-1] != '\\':
									self.addPropStr(astrComments, strPropLine, nLine, fnPreprocess)
									astrComments = []
								else:
									fInMultiLineProp = True
		except:
			print "ERROR: " + str(self.obPath) + ":" + str(nLine)
			raise