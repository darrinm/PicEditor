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
# This script copies properties between property files
# It should be run from the root of the repository, for example:
#	> cd c:\src\picnik
#	> python bin\loc\copy_props.py
#
# edit the CopyProp() calls, below, to copy the properties

import os
import re
from props import PropFile


# need to change the default encoding so that we don't get ascii codec errors
# note that using "utf-8" instead of "latin1" gives errors because our source
# 	files apparently have some invalid UTF bytes.
import sys
reload(sys)
sys.setdefaultencoding("latin1")

# Read the list of locales in client/loc
patLocale = re.compile('[a-z][a-z]_[a-z][a-z]', re.IGNORECASE)

astrLocales = []
for strLocale in os.listdir('client/loc'):
	strLocaleFolderPath = os.path.join('client/loc', strLocale)
	if os.path.isdir(strLocaleFolderPath) and not os.path.islink(strLocaleFolderPath) and patLocale.match(strLocale):
		astrLocales.append(strLocale)

# copy some strings
def CopyProp(strSrc, strDest):
	astrSrc = strSrc.split(':')
	astrDest = strDest.split(':')

	strSrcKey = astrSrc[1]
	strDestKey = astrDest[1]
	
	for strLocale in astrLocales:
		strPropFileBase = 'client/loc/' + strLocale
		strSrcPropFilePath = os.path.join(strPropFileBase, astrSrc[0]+".properties")
		pfSrc = PropFile(strSrcPropFilePath)

		strDestPropFilePath = os.path.join(strPropFileBase, astrDest[0]+".properties")
		pfDest = PropFile(strDestPropFilePath)
		
		if strSrcKey in pfSrc.dProps:
			prop = pfSrc.dProps[strSrcKey]
			prop.key = strDestKey
			pfDest.addProp(pfSrc.dProps[strSrcKey])
		else:
			print "missing property " + strSrcKey + " in " + strSrcPropFilePath
			
		pfDest.save()
	
	
	print "copy prop from " + str(astrSrc) + " to " + strDest

# Edit and uncomment as needed
# CopyProp('DoodleEffect:Label_1', 'EffectCanvas:brushColor')
# CopyProp('DoodleEffect:Label_2', 'EffectCanvas:brushSize')
# CopyProp('DoodleEffect:Label_3', 'EffectCanvas:fade')
# CopyProp('DoodleEffect:_efbtn_1', 'EffectCanvas:byPicnik')
# CopyProp('ZombifyEffect:_btnEraser', 'EffectCanvas:eraser')
# CopyProp('TeethWhitenEffect:eraserSize', 'EffectCanvas:eraserSize')
# CopyProp('BoostEffect:Label_1', 'EffectCanvas:strength')
# CopyProp('Adjustments:_btnColors', 'EffectCanvas:colors')
# CopyProp('SpecialEffectsCanvas:Label_3', 'EffectCanvas:color')

# all done
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

