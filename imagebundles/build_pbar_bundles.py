#!/usr/bin/python2.4
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
import os
import re
import xml.dom.minidom

sys.path.insert(0, '..')

from build_common import *

def UniqueList(astr):
	d = {}
	for strItem in astr:
		d[strItem] = strItem
	return d.values()

class ImageBundle(Project):
	strRoot = os.path.join(strRoot, 'imagebundles')

	@staticmethod
	def BundableExtension(strFilePath):
		strExt = os.path.splitext(strFilePath)[1].lower()
		return strExt[1:] in ['jpg','jpeg','gif','png']
	
	@staticmethod
	def AppendDirFiles(strSourceDir, astrFiles):
		strWebsitePath = os.path.join(ImageBundle.strRoot, '..', 'website')
		for strFile in os.listdir(os.path.join(strWebsitePath, strSourceDir)):
			if ImageBundle.BundableExtension(strFile):
				astrFiles.append(os.path.abspath(os.path.join(strWebsitePath, strSourceDir, strFile)))
		return astrFiles	
	
	#
	# images grouped by directory
	#
	@staticmethod
	def AddBasicBundles(dBundleInfo):
		astrBasicDirs = [
					"graphics/progressbar",
					"graphics/gp_progressbar"];
		
		for strBundleDir in astrBasicDirs:
			ImageBundle.AppendDirFiles(strBundleDir, dBundleInfo['astrFiles'])

	@staticmethod
	def GetBundleInfo():
		# Four kinds of things get built into image bundles, and go in different locations
		dBundleInfo = {'astrFiles':[], 'aastrSubDirSets':[], 'astrSuperBundleDirs':[]}

		ImageBundle.AddBasicBundles(dBundleInfo)
		
		return dBundleInfo

	@staticmethod
	def GetBundleByBase(strBase, strDir, dBundleInfo):
		if not (strBase in dBundleInfo['ddBundles']):
			dBundleInfo['ddBundles'][strBase] = {'strBundleDir':strBase, 'dSourceDirs':{}, 'astrFiles':[]}
		dBundle = dBundleInfo['ddBundles'][strBase]
		dBundle['dSourceDirs'][strDir] = True
		return dBundle

	@staticmethod
	def GetBundle(strFile, dBundleInfo):
		strDir = os.path.dirname(strFile)
		strBase = ImageBundle.GetBundleBase(strDir, dBundleInfo)
		return ImageBundle.GetBundleByBase(strBase, strDir, dBundleInfo)
	
	@staticmethod
	def GetBundleBase(strDir, dBundleInfo):
		for strSuperBundleDir in dBundleInfo['astrSuperBundleDirs']:
			if strDir.startswith(strSuperBundleDir):
				return strSuperBundleDir
		
		# Not a super bundle dir. Try our sub dir setes
		for astrSubDirSet in dBundleInfo['aastrSubDirSets']:
			for strSubDir in astrSubDirSet:
				if strDir == strSubDir:
					return astrSubDirSet[0]

		return strDir

	@staticmethod
	def AddToBundle(strFile, dBundleInfo):
		ImageBundle.GetBundle(strFile, dBundleInfo)['astrFiles'].append(strFile)

	@staticmethod
	def _build(fDebug=False):
		dBundleInfo = ImageBundle.GetBundleInfo()
		# Now we have our bundle info,

		# Sort and dedupe our bundle list
		dBundleInfo['astrFiles'] = UniqueList(dBundleInfo['astrFiles'])
		dBundleInfo['astrFiles'].sort()
		
		# Next, we need to generate a per-bundle list with
		# The dest path for the bundle.swf
		# A list of source dirs
		# a list of source files
		
		# The first step is to figure out our bundle groups
		dMapDirToSubDirSet = {}
		for astrSubDirSet in dBundleInfo['aastrSubDirSets']:
			for strDir in astrSubDirSet:
				dMapDirToSubDirSet[strDir] = astrSubDirSet[0]
		dBundleInfo['dMapDirToSubDirSet'] = dMapDirToSubDirSet
		dBundleInfo['ddBundles'] = {}
		
		# Now put the files into bundles
		for strFile in dBundleInfo['astrFiles']:
			ImageBundle.AddToBundle(strFile, dBundleInfo)

		# Next, compile our bundle files
		for dBundle in dBundleInfo['ddBundles'].values():
			ImageBundle.CompileBundle(dBundle)
			# pass

		print
		print

		
	@staticmethod
	def CompileBundle(dBundle):
		strOut = 'pbar_assets.swf'
		
		strDir = dBundle['strBundleDir']
		#print "ImageBundle: compiling bundle %s" % strDir
		strScript = ImageBundle._GetBundleScript(strDir, dBundle['astrFiles'], True)			
		print "bundle path", os.path.join(ImageBundle.strRoot, 'Bundle.as')
		f = open(os.path.join(ImageBundle.strRoot, 'Bundle.as'), 'w')
		f.write(strScript)
		f.close();
		Flex.mxmlc(ImageBundle.strRoot, 'Bundle.as', strOut, debug=fDebug)	
		Project.CopyFile(os.path.join(ImageBundle.strRoot, strOut), os.path.join(strDir, strOut))


	@staticmethod
	def _GetBundleScript(strDir, aFiles, fAbsoluteFileDirs=False):
		strScript = "package { import flash.display.Sprite; \n"
		strScript = strScript + "public class Bundle extends Sprite {\n"
		strDir = re.sub("\\\\", "/", strDir)
		strWebsitePath = os.path.abspath(os.path.join(ImageBundle.strRoot, '..', 'website'))
		for strFile in aFiles:
			# only .png or .jpg!
			strExt = strFile[strFile.rfind(".") + 1:]
			if not strExt in ["jpg", "png", "gif"]:
				#print "    Skipping file %s" % strFile
				continue
			#print "    Adding file %s" % strFile

			# since we have multiple GlyphSets in a ShapeSection, a single glyph filename is not
			# unique.  So we pull a swiftie and make the shape symbol name a combo of the glyph filename
			# and the directory it's in, with a '_' divider between them.
			strFile2 = strFile
			if fAbsoluteFileDirs and strFile2.startswith(strWebsitePath):
				strFile2 = strFile2[len(strWebsitePath)+1:]
			strFile2 = re.sub("\\\\", "/", strFile2)
			
			if strFile2.find('fonts/glyphs/') == -1:
				pass
			else:
				n = strFile2.rfind('/')
				strFile2 = strFile2[0:n] + '_' + strFile2[n + 1:]

			if fAbsoluteFileDirs:
				strEmbedSource = re.sub("\\\\", "/", strFile)
			else:
				strEmbedSource = strDir + "/" + strFile
				
			strSymbol = "cls" + re.sub(r"[\.\-\\\/ ]", "_", strFile2[ strFile2.rfind('/') + 1 : ])
			strScript = strScript + "[Embed(source='%s')] public static var %s:Class;\n" % (strEmbedSource, strSymbol)
		strScript = strScript + "} }\n"
		#print
		return strScript
				
	def release(self, options, args):
		ImageBundle._build(False)

	def debug(self, options, args):
		ImageBundle._build(True)

dBundleInfo = {'astrFiles':[], 'aastrSubDirSets':[]}
def DumpBundleInfo(dBundleInfo):
	for dBundle in dBundleInfo['ddBundles'].itervalues():
		print "Bundle [", dBundle['strBundleDir'], "]: ", dBundle['dSourceDirs']
		
		#for strFile in dBundle['astrFiles']:
		#	print " - " + strFile

if __name__ == "__main__":
	Project.ProcessArgs()
