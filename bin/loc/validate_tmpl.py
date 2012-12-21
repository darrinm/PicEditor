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

import os
import sys

# BEGIN: Import serverbin for cheetah code
import ConfigParser
dDefaults = {}
dDefaults['baseDir'] = os.getcwd()
dDefaults['sourceDir'] = os.path.abspath(os.path.dirname(__file__))
dDefaults['serverbinDir'] = os.path.normpath(os.path.join(dDefaults['sourceDir'], '../serverbin'))
Config = ConfigParser.SafeConfigParser(dDefaults)
Config.read('picnik.ini')
try:
	strServerBinDir = os.path.join(Config.get('Locations', 'serverbinDir'), 'site-packages')
except:
	strServerBinDir = os.path.join(os.getcwd(), 'serverbin_lin', 'site-packages')

sys.path.insert(0, strServerBinDir)
# END: Import serverbin for cheetah code

from Cheetah.Template import Template

# fVerbose = False
fVerbose = True

def extensionMatches(strFilePath, strExtension):
	return strFilePath.lower().endswith('.' + strExtension.lower())

def removeExtension(strFile):
	nBreak = strFile.rfind('.')
	if nBreak == -1: return strFile
	return strFile[0:nBreak]

def ValidateTemplateContents(strFile, strFilePath):
    try:
        t = Template(source=strFile)
    except ImportError, e:
        pass # Ignore import errors, we don't know which imports to use
    except:
        print "Failed: " + strFilePath
        for i in range(0, len(sys.exc_info())-1):
            print str(sys.exc_info()[i])
           
        return False
       
    return True
	
def ValidateTemplateFile(strFilePath):
    try:
        t = Template(file=strFilePath)
    except ImportError, e:
        pass # Ignore import errors, we don't know which imports to use
    except:
        print "Failed: " + strFilePath
        for i in range(0, len(sys.exc_info())-1):
            print str(sys.exc_info()[i])
           
        return False
       
    return True
	
def ValidateTemplates(strPath, strExtension):
    nFiles = 0
    fValid = True
    for strFile in os.listdir(strPath):
        strSourcePath = os.path.join(strPath, strFile)
        if extensionMatches(strFile,strExtension):
            if not ValidateTemplateFile(strSourcePath):
                fValid = False
            nFiles += 1
        elif extensionMatches(strSourcePath, "svn"):
            pass
        elif os.path.isdir(strSourcePath):
            nSubFiles, fSubValid = ValidateTemplates(strSourcePath, strExtension)
            fValid = fValid and fSubValid
            nFiles += nSubFiles
    return nFiles, fValid
	
# UNDONE:
# Fix @Resource(...bundle='<bundle>') refs
# Fix [ResourceBundoe("<bundle>") refs
	
def ValidateAllTemplates():
	strPath = os.path.join(os.getcwd(), "server", "templates")
	nFiles, fValid = ValidateTemplates(strPath, "tmpl")
	if fValid:
		print "Validated " + str(nFiles) + " template files in " + strPath
	else:
		print "One or more template files invalid in " + strPath
	
	
if __name__ == '__main__':
	ValidateAllTemplates()
