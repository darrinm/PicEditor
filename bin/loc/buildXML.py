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
# This script creates the localized versions of shapes and fonts.xml
#
# This should be run when any input file is changed (e.g. changing font categories)
# and when a loc drop is installed (the install loc drop script should do this automatically)
#
# Input files:
#  - client/loc/<locale>/ShapesXml.properties
#  - client/loc/<locale>/FontsXml.properties
#  - website/Shapes.xml
#  - website/fonts/fonts.xml
# Output files:
#  - website/app/<locale>/Shapes.xml
#  - website/app/<locale>/fonts.xml
#
# It should be run from the root of the repository, for example:
#	> cd c:\src\picnik
#	> python bin\loc\buildXML.py
#
# Make sure you check in the output files when you finsih running this script
import glob, os
import re
import codecs
import sys
from cStringIO import StringIO
from p4util import P4File
from p4util import P4Time
from p4util import P4Commit

# Calculate and allow imports relative to client base
strClientRootPath = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", ".."))
sys.path.insert(0, strClientRootPath)

# Calculate picnik root
strPicnikRoot = # your server root here
# Calculate picnik server root and allow relative imports
strServerRootPath = os.path.join(strPicnikRoot, 'server')
sys.path.insert(0, strServerRootPath)

os.chdir(strPicnikRoot)

#BEGIN: Allow imports of PIL, etc.
from optparse import OptionParser
parser = OptionParser()

parser.add_option("-p", dest="picnikini", default=os.path.join(strPicnikRoot, 'picnik.ini'), metavar='FILE',
                                        help="Where to find the main config file (picnik.ini)")
parser.add_option("-s", dest="sqlconfig", default=os.path.join(strPicnikRoot, 'sql.ini'),  metavar='FILE',
                                        help="SQL ini file")
(options, args) = parser.parse_args()
options.picnikini = os.path.abspath(options.picnikini)
options.sqlconfig = os.path.abspath(options.sqlconfig)

import InitConfig # initializes config vars
Config = InitConfig.InitConfig(options)
#END: Allow imports of PIL, etc.

from props import PropFile
import math
import time
from PIL import Image
import md5

nNextCatId = 0

dCheckSums = {}

def NoCacheParam(strFilePath):
	global dCheckSums
	if not(strFilePath in dCheckSums):
		# Calculate the checksum
		fh = open(strFilePath, 'rb')
		dCheckSums[strFilePath] = md5.new(fh.read()).hexdigest()[0:8]
		fh.close()

	return "ver=" + dCheckSums[strFilePath] 

class Bundle:
	def getDimensions(self, strSourceImage):
		tDims = None
		try:
			fh = open(strSourceImage, 'rb')
			im = Image.open(fh)
			tDims = im.size
		finally:
			# Make sure we close and delete the file
			try:
				if fh != None:
					fh.close()
					fh = None
			except:
				pass # Two errors in a row. Let the second one go
		return tDims

	def generate(self, astrUrls, strName, tDims, fGenerateBundles):
		# First, see if we can find these files
		self.dMapUrlToIndex = {}

		strBasePath = os.path.join(os.getcwd(), 'website', 'clipart')
		self.strUrl = '../clipart/bundles/' + strName + ".png"
		strOutPath = os.path.join(strBasePath, self.strUrl)

		# Take the largest of the first three thumbs
		if tDims == None:
			nWidth = 0
			nHeight = 0
			for i in range(0,16):
				if len(astrUrls) > i:
					nWidth2, nHeight2 = self.getDimensions(os.path.join(strBasePath, astrUrls[i]))
					nWidth = max(nWidth, nWidth2)
					nHeight = max(nHeight, nHeight2)
			tDims = (nWidth, nHeight)
		
		if tDims == None:
			raise "no image dimensions!?!"
		
		self.tDims = tDims
		
		nWidth, nHeight = self.tDims

		cTall = math.ceil((len(astrUrls) * nWidth) / 2800.0)
		cWide = math.ceil(1.0 * len(astrUrls) / cTall)
		
		nTotalWidth = cWide * nWidth
		nTotalHeight = cTall * nHeight
		
		if fGenerateBundles: imDest = Image.new('RGBA', (int(nTotalWidth), int(nTotalHeight)))
		
		for i in range(0, len(astrUrls)):
			self.dMapUrlToIndex[astrUrls[i]] = i
			if fGenerateBundles:
				fh = open(os.path.join(strBasePath, astrUrls[i]), 'rb')
				imSrc = Image.open(fh)
				xDest = (i % cWide) * nWidth
				yDest = int(i / cWide) * nHeight
				
				nImWidth, nImHeight = imSrc.size
				
				xDest += int((nWidth - nImWidth)/2)
				yDest += int((nHeight - nImHeight)/2)
				
				# imDest.paste(imSrc, (int(xDest), int(yDest)), imSrc)
				imDest.paste(imSrc, (int(xDest), int(yDest)))
				fh.close()

		if fGenerateBundles:
			p4Out = P4File.open(strOutPath, 'w')
			strBase, strExtension = os.path.splitext(strOutPath)
			strFormat = strExtension.upper()[1:]
			imDest.save(p4Out, strFormat)
			p4Out.close()
		
		self.strUrl += "?" + NoCacheParam(strOutPath)
		
		# def paste(self, im, box=None, mask=None):
		
		# print "strPath = " + strPath + ", " + str(os.path.exists(strPath))
		pass

	def sliceUrl(self, strUrl):
		nIndex = self.dMapUrlToIndex[strUrl]
		return str(self.tDims[0]) + "|" + str(self.tDims[1]) + "|" + str(nIndex) + "|" + self.strUrl
	
	def rotatingUrl(self):
		return str(self.tDims[0]) + "|" + str(self.tDims[1]) + "|" + self.strUrl

def readProps(strPropBase, strLocale, strPropFileName):
	strPath = os.path.join(strPropBase, strLocale, strPropFileName + '.properties')
	return PropFile(strPath)

def readFile(strPath):
	fIn = open(strPath, 'r')
	astrLines = []
	for strLine in fIn:
		if len(strLine) > 2 and strLine[0:3] == codecs.BOM_UTF8:
			strLine = strLine[3:]
		astrLines.append(strLine)
	return astrLines

def writeFile(strPath, astrLines):
	p4Out = P4File.open(strPath, 'w')
	p4Out.write(codecs.BOM_UTF8)
	for strLine in astrLines:
		p4Out.write(strLine)
		p4Out.write('\n')
	p4Out.close()

patLocale = re.compile('[a-z][a-z]_[a-z][a-z]', re.IGNORECASE)

def locMatch(match, propsDefault, propsLocalized):
	strKey = match.group(2)
	strVal = ""
	if strKey in propsLocalized.dProps:
		strVal = propsLocalized.dProps[strKey].value
	elif strKey in propsDefault.dProps:
		strVal = propsDefault.dProps[strKey].value
	else:
		print "ERROR: property '" + strKey + "' not defined"
	# since we're building XML, we should make sure the val
	# doesn't include any HTML entities.  Since we might have a mix
	# of encoded and non-encoded in the props file, we first convert
	# encoded to non-encoded, and then reencode everything.
	strVal = strVal.replace( '&amp;', '&' )
	strVal = strVal.replace( '&quot;', '"' )
	strVal = strVal.replace( '&apos;', "'" )
	strVal = strVal.replace( '&lt;', '<' )
	strVal = strVal.replace( '&gt;', '>' )
	strVal = strVal.replace( '&', '&amp;' )
	strVal = strVal.replace( '"', '&quot;' )
	strVal = strVal.replace( "'", '&apos;' )
	strVal = strVal.replace( '<', '&lt;' )
	strVal = strVal.replace( '>', '&gt;' )
	return match.group(1) + '="' + strVal + '"'

def localizeLine(strIn, apatPropMatches, propsDefault, propsLocalized):
	# Extra work to copy toolTip to toolTipText
	pat2 = re.compile('toolTip\s*=\s*"([^"]*)"')
	strIn = pat2.sub(r'toolTip="\1" toolTipText="\1"', strIn)
	
	# use a lambda function to create a new substitution function which takes one param but knows about propsDefault and propsLocalized
	for pat in apatPropMatches:
		strIn = pat.sub(lambda m: locMatch(m, propsDefault, propsLocalized), strIn)
	return strIn

def localize(astrIn, apatPropMatches, propsDefault, propsLocalized):
	astrLocalized = []
	for strLineIn in astrIn:
		astrLocalized.append(localizeLine(strLineIn, apatPropMatches, propsDefault, propsLocalized))
	return astrLocalized

def buildXML(strSourceXMLPath, astrPropsToLoc, strPropertyFileName, strOutputFileName):
	strPropBase = 'client/loc'
	strLocalizedBase = 'website/app'

	apatPropMatches = []
	for strPropName in astrPropsToLoc:
		apatPropMatches.append(re.compile('(' + strPropName + ')' + '[ \t\n]*=[ \t\n]*"([^"]*)"', re.IGNORECASE))
	
	propsDefault = readProps(strPropBase, 'en_US', strPropertyFileName)
	
	astrSourceXML = readFile(strSourceXMLPath)
	
	# Walk through locales (by folder)
	for strLocale in os.listdir(strPropBase):
		strLocaleFolderPath = os.path.join(strPropBase, strLocale)
		if os.path.isdir(strLocaleFolderPath) and not os.path.islink(strLocaleFolderPath) and patLocale.match(strLocale):
			# found a locale. Do the work
			strOutPath = os.path.join(strLocalizedBase, strLocale, strOutputFileName)
			propsLocalized = readProps(strPropBase, strLocale, strPropertyFileName)
			astrLocalizedXML = localize(astrSourceXML, apatPropMatches, propsDefault, propsLocalized)
			writeFile(strOutPath, astrLocalizedXML)

# for debugging			
def printCat(dCat, strPrefix):
	# Sample cat: {'shapes':[], 'children':[], 'attributes':{'title':strSection, 'id':nNextCatId}}
	print strPrefix + str(dCat['attributes']) + ", " + str(dCat['shapes'])
	printCatList(dCat['children'], strPrefix + "   ")

# for debugging			
def printCatList(aCategories, strPrefix=""):
	for dCat in aCategories:
		printCat(dCat, strPrefix)
		
def ParseChildCategories(xmlParent):
	aCategories = []
	for xmlChild in xmlParent.childNodes:
		if xmlChild.nodeType == xmlChild.ELEMENT_NODE and xmlChild.localName == 'ShapeCategory':
			aCategories.append(ShapeCategory(xmlChild))
	return aCategories

def ParseChildShapes(xmlParent):
	aShapes = []
	for xmlChild in xmlParent.childNodes:
		if xmlChild.nodeType == xmlChild.ELEMENT_NODE and xmlChild.localName != 'ShapeCategory':
			aShapes.append(xmlChild)
	return aShapes
		
class ShapeCategory:
	def __init__(self, xmlCat=None):
		self.dAttributes = {}
		if xmlCat != None:
			for strKey in xmlCat.attributes.keys():
				self.dAttributes[str(strKey)] = xmlCat.getAttribute(strKey)
			self.aCategories = ParseChildCategories(xmlCat)
			self.aShapes = ParseChildShapes(xmlCat)
			self.dAttributes['numShapes'] = str(len(self.aShapes))
	
	def AddToXml(self, doc, xmlParent, fIncludeThumbs, fIncludeShapes=True):
		import xml.dom.minidom
		# Create the category
		xmlNew = doc.createElement("ShapeCategory")
		xmlParent.appendChild(xmlNew)
		
		# Attributes
		for strKey, strVal in self.dAttributes.iteritems():
			if fIncludeThumbs or not strKey == 'thumbUrl':
				xmlNew.setAttribute(strKey, str(strVal))
		
		# child categories
		for catChild in self.aCategories:
			catChild.AddToXml(doc, xmlNew, fIncludeThumbs, fIncludeShapes)
			
		# child shapes
		if len(self.aShapes) > 0 and fIncludeShapes:
			xmlShapes = doc.createElement('Shapes')
			xmlNew.appendChild(xmlShapes)
			for xmlShape in self.aShapes:
				if xmlShape.getAttribute('usePreview') == 'false':
					xmlShape.removeAttribute('usePreview')
					if xmlShape.hasAttribute('previewUrl'):
						xmlShape.removeAttribute('previewUrl')
				xmlShapes.appendChild(xmlShape)
				
	def Save(self, strPath, propsLocalized, propsDefault, fIncludeThumbs=False, fIncludeShapes=True):
		import xml.dom.minidom
		docOut = xml.dom.minidom.Document()
		self.AddToXml(docOut, docOut, fIncludeThumbs, fIncludeShapes)
		
		strPreLoc = docOut.toprettyxml(encoding='utf-8')
		astrLocXml = LocalizeShapeFile(strPreLoc, propsLocalized, propsDefault)
		writeFile(strPath, astrLocXml)

	def Clone(self, fIncludeShapes=True):
		catCopy = ShapeCategory()
		for strKey, strVal in self.dAttributes.iteritems():
			catCopy.dAttributes[strKey] = strVal
		
		catCopy.aCategories = []
		for catChild in self.aCategories:
			catCopy.aCategories.append(catChild.Clone(fIncludeShapes))
		
		catCopy.aShapes = []
		if fIncludeShapes:
			for xmlShape in self.aShapes:
				catCopy.aShapes.append(xmlShape.cloneNode(True))

	def UpdateShapePremiumness(self, fPicnikPremium=False, fFlickrPremium=False):
		if 'flickrPremium' in self.dAttributes:
			fFlickrPremium = self.dAttributes['flickrPremium'] == 'true'
		else:
			self.dAttributes['flickrPremium'] = str(fFlickrPremium).lower()
		
		if 'picnikPremium' in self.dAttributes:
			fPicnikPremium = self.dAttributes['picnikPremium'] == 'true'
		else:
			self.dAttributes['picnikPremium'] = str(fPicnikPremium).lower()
		
		for cat in self.aCategories:
			cat.UpdateShapePremiumness(fPicnikPremium, fFlickrPremium)
			
		for xmlShape in self.aShapes:
			if xmlShape.getAttribute('picnikPremium') == '':
				xmlShape.setAttribute('picnikPremium', str(fPicnikPremium).lower())
			if xmlShape.getAttribute('flickrPremium') == '':
				xmlShape.setAttribute('flickrPremium', str(fFlickrPremium).lower())
			
	def AddShapeArrays(self, aaShapes):
		if len(self.aShapes) > 0:
			aaShapes.append(self.aShapes)
		for catChild in self.aCategories:
			catChild.AddShapeArrays(aaShapes)

	def AddPreviewUrls(self, fGenerateBundles, aThumbs, strAreaIDPrefix):
		# set up the preview array, then set it on the group
		# Create an array of shape arrays for each sub-group
		aaShapes = []
		self.AddShapeArrays(aaShapes)
		aShapes = Weave(aaShapes, 120)
		aPreviews = []
		for xmlShape in aShapes:
			strPreview = str(xmlShape.getAttribute('previewUrl')).replace('/previews/', '/largePreviews/')
			if len(strPreview) > 0: aPreviews.append(strPreview)
			if len(aPreviews) > 8: break
			
		if 'customGroupThumbUrl' in self.dAttributes:
			aPreviews = [self.dAttributes['customGroupThumbUrl']] + aPreviews

		if len(aPreviews) > 0:
			self.dAttributes['thumbUrl'] = aPreviews[0] # We'll go back and replace this after generating the bundle
			aThumbs.append(aPreviews[0])
			aPreviews = aPreviews[1:]

		if len(aPreviews) > 0:
			bundleGroupPreviews = Bundle()
			bundleGroupPreviews.generate(aPreviews, strAreaIDPrefix + "groupPreviews_" + self.dAttributes['id'], None, fGenerateBundles)
			self.dAttributes['previewUrls'] = bundleGroupPreviews.rotatingUrl()

		# Create a bundle for each group
		aShapes = []
		for aMoreShapes in aaShapes:
			aShapes += aMoreShapes
		
		# aShapes represents all of the shapes in this group. First, collect preview urls
		aShapeUrls = []
		fSameAuthor = len(aShapes) > 0
		strPrevAuthor = None
		for xmlShape in aShapes:
			if fSameAuthor:
				strAuthorName = xmlShape.getAttribute('authorName')
				if strAuthorName == '':
					fSameAuthor = False
				else:
					if strPrevAuthor != None and strPrevAuthor != strAuthorName:
						fSameAuthor = False
					else:
						strPrevAuthor = strAuthorName
			strPreview = xmlShape.getAttribute('previewUrl')
			if len(strPreview) > 0:
				strPreview = strPreview.replace('/largePreviews/', '/previews/')
				aShapeUrls.append(strPreview)
		
		if fSameAuthor:
			self.dAttributes['authorName'] = aShapes[0].getAttribute('authorName')
			self.dAttributes['authorUrl'] = aShapes[0].getAttribute('authorUrl')
		
		if len(aShapeUrls) > 0:
			bundleShapes = Bundle()
			bundleShapes.generate(aShapeUrls, strAreaIDPrefix + "shapes_" + self.dAttributes['id'], (40, 40), fGenerateBundles)
			
			# Now update our preview urls
			for xmlShape in aShapes:
				strPreview = xmlShape.getAttribute('previewUrl')
				if len(strPreview) > 0 and xmlShape.getAttribute('usePreview') != 'false':
					xmlShape.setAttribute('previewUrl', bundleShapes.sliceUrl(xmlShape.getAttribute('previewUrl')))

class ShapeArea:
	def __init__(self, xmlShapeArea=None):
		if xmlShapeArea != None:
			self.id = xmlShapeArea.getAttribute('id')
			self.strIDPrefix = self.id
			if len(self.strIDPrefix) > 0:
				self.strIDPrefix = self.strIDPrefix + "Area_"
			self.aCategories = ParseChildCategories(xmlShapeArea)
	
	def SaveRoot(self, strPath, propsLocalized, propsDefault):
		catRoot = ShapeCategory()
		catRoot.aShapes = []
		catRoot.dAttributes = {'id':'root', 'area':self.id}
		catRoot.aCategories = self.aCategories
		
		catRoot.Save(strPath, propsLocalized, propsDefault, True, False)

	def createShapeFiles(self, strDestBasePath, propsLocalized, propsDefault):
		if len(self.id) > 0:
			strDestBasePath = os.path.join(strDestBasePath, self.id)
		if not os.path.exists(strDestBasePath):
			os.mkdir(strDestBasePath)
		
		self.SaveRoot(os.path.join(strDestBasePath, 'ShapesRoot.xml'), propsLocalized, propsDefault)
		
		for catSection in self.aCategories:
			for catGroup in catSection.aCategories:
				catGroup.Save(os.path.join(strDestBasePath, 'Shapes_' + str(catGroup.dAttributes['id']) + '.xml'), propsLocalized, propsDefault)
	
	def UpdateShapePremiumness(self):
		for cat in self.aCategories:
			cat.UpdateShapePremiumness()
			
	def GetCategoriesCopy(self, fIncludeShapes=True):
		aCategories = []
		for cat in self.aCategories:
			aCategories.append(cat.Clone(fIncludeShapes))
		return aCategories
			
	def Clone(self, fIncludeShapes=True):
		areaCopy = ShapeArea()
		areaCopy.id = self.id
		areaCopy.aCategories = self.GetCategoriesCopy(fIncludeShapes)
		areaCopy.strPrefix = self.strPrefix
			
	def AddPreviewUrls(self, fGenerateBundles):
		aThumbs = []
		for catSection in self.aCategories:
			for catGroup in catSection.aCategories:
				catGroup.AddPreviewUrls(fGenerateBundles, aThumbs, self.strIDPrefix)

		bundleGroupThumbs = Bundle()
		bundleGroupThumbs.generate(aThumbs, self.strIDPrefix + "groupThumbs", None, fGenerateBundles)
		for catSection in self.aCategories:
			for catGroup in catSection.aCategories:
				if 'thumbUrl' in catGroup.dAttributes:
					catGroup.dAttributes['thumbUrl'] = bundleGroupThumbs.sliceUrl(catGroup.dAttributes['thumbUrl'])

# Returns an array of shape sections
def parseShapesXML(strSourcePath):
	import xml.dom.minidom
	
	file = open(strSourcePath, 'r')
	strFile = file.read()
	file.close()
	docIn = xml.dom.minidom.parseString(strFile)

	aAreas = []
	for xmlShapeArea in docIn.getElementsByTagName('ShapeArea'):
		# Found a shape area
		aAreas.append(ShapeArea(xmlShapeArea))
	
	return aAreas

def Weave(aa, nMax):
	aOut = []
	i = 0
	fMore = True
	while fMore and len(aOut) < nMax:
		fMore = False
		for aChild in aa:
			if len(aChild) > i:
				fMore = True
				aOut.append(aChild[i])
		i += 1
	
	if len(aOut) > nMax:
		aOut = aOut[0:nMax]
	
	return aOut

def PruneShapes(aCategories):
	for dCat in aCategories:
		dCat['shapes'] = []
		PruneShapes(dCat['children'])

def LocalizeShapes(aShapes, propsLocalized, propsDefault):
	for xmlShape in aShapes:
		if xmlShape.getAttribute('toolTipText') != '':
			strLocVal = LocalizeKey(xmlShape.getAttribute('toolTipText'), propsLocalized, propsDefault)
			xmlShape.setAttribute('toolTipText', strLocVal)

def LocalizeKey(strKey, propsLocalized, propsDefault):
	strVal = "Undefined"
	if strKey in propsLocalized.dProps:
		strVal = propsLocalized.dProps[strKey].value
	elif strKey in propsDefault.dProps:
		strVal = propsDefault.dProps[strKey].value
	else:
		print "Missing loc key: " + strKey
		raise "Missing loc key in shapesXML.properties: " + strKey
	return strVal

def LocalizeCats(aCategories, propsLocalized, propsDefault):
	for dCat in aCategories:
		dCat['attributes']['title'] = LocalizeKey(dCat['attributes']['title'], propsLocalized, propsDefault)
		LocalizeShapes(dCat['shapes'], propsLocalized, propsDefault)
		LocalizeCats(dCat['children'], propsLocalized, propsDefault)

def LocalizeShapeFile(strFileIn, propsLocalized, propsDefault):
	astrPropsToLoc = ['title', 'toolTipText']
	apatPropMatches = []
	for strPropName in astrPropsToLoc:
		apatPropMatches.append(re.compile('(' + strPropName + ')' + '[ \t\n]*=[ \t\n]*"([^"]*)"', re.IGNORECASE))
	
	if strFileIn[0:3] == codecs.BOM_UTF8:
		strFileIn = strFileIn[3:]
	
	return localize(strFileIn.splitlines(), apatPropMatches, propsDefault, propsLocalized)
	
def CloneAreas(aAreas, fIncludeShapes=True):
	aAreasCopy = []
	for area in aAreas:
		aAreasCopy.append(area.Clone(fIncludeShapes))
	return aAreasCopy

def buildShapesV2():
	strAppBase = 'website/app'
	strWebsiteBase = 'website'
	strPropBase = 'client/loc'

	#astrPropsToLoc = ['title', 'toolTipText']
	strPropertyFileName = "ShapesXml"
	
	propsDefault = readProps(strPropBase, 'en_US', strPropertyFileName)

	strSourceXMLPath = os.path.join(strWebsiteBase, 'Shapes.xml')
	aAreas = parseShapesXML(strSourceXMLPath)
	
	for area in aAreas:
		area.AddPreviewUrls(True)
		area.UpdateShapePremiumness()
	
	# LocalizeCats(aCategories, propsLocalized, propsDefault)
	
	# Walk through locales (by folder)
	for strLocale in os.listdir(strPropBase):
		strAppLocalPath = os.path.join(strAppBase, strLocale)
		if os.path.isdir(strAppLocalPath) and not os.path.islink(strAppLocalPath) and patLocale.match(strLocale):
			# Now we have an app local path, e.g. website/app/en_US

			propsLocalized = readProps(strPropBase, strLocale, strPropertyFileName)
			
			# Ouptut directory
			strDestBasePath = os.path.join(strAppLocalPath, 'shapesV2')
			if not os.path.exists(strDestBasePath): os.mkdir(strDestBasePath)
			
			for area in aAreas:
				area.createShapeFiles(strDestBasePath, propsLocalized, propsDefault)

def buildAllXML(dAreas=None):
	nStart = time.time()
	if dAreas is None:
		dAreas = {'fonts':True, 'templates':True, 'shapes':True}
	if 'fonts' in dAreas:
		buildXML('website/fonts/fonts.xml', ['category','title1','title2','blurb'], 'FontsXml', 'fonts.xml')
	if 'templates' in dAreas:
		buildXML('website/templates/templates.xml', ['title','attribUrlText','groupDesc'], 'TemplatesXml', 'templates.xml')
	if 'shapes' in dAreas:
		buildShapesV2()
	P4Commit()
	nEnd = time.time()
	nElapsed = nEnd - nStart
	nP4Time = P4Time()
	print "BuildXML time:", nElapsed, "p4 time:", nP4Time, "(" + str(int(100 * nP4Time / nElapsed)) + "%)" 

if __name__ == '__main__':
	dAreas = None
	if len(sys.argv) > 1:
		dAreas = {}
		for strArea in sys.argv[1:]:
			dAreas[strArea.lower().strip()] = True
	
	buildAllXML(dAreas)
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

