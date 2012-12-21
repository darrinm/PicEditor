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

from subprocess import *
import sys, os
import glob
import re
import shutil
import time
from stat import *

def needsUpdate(astrDependencyPaths, strTargetPath):
    if not os.path.exists(strTargetPath):
        return True

    # for strDependencyPath in astrDependencyPaths:
    #    if os.path.getmtime(strTargetPath) < os.path.getmtime(strDependencyPath):
    #        return True
    return False

def cleanFontFileName(strFontPath):
    strOldFileName = os.path.basename(strFontPath)
    strNewFileName = re.sub('[^A-Za-z0-9._]', '_', strOldFileName)
    if strOldFileName != strNewFileName:
        print "Font has illegal characters: " + strOldFileName + ". Renaming to " + strNewFileName
        strNewFontPath = os.path.join(os.path.dirname(strFontPath), strNewFileName)
        shutil.move(strFontPath, strNewFontPath)
        return strNewFontPath
    else:
        return strFontPath

def IsSwfFont(strFontPath):
    return strFontPath[-3:].lower() == 'swf'
       
def FontRequiresFlaCompile(strFontPath, dTinf):
    strName = os.path.basename(strFontPath)[0:-4]
    if strName.lower() == "sue_ellen_francis": return True
    if 'forceFlash' in dTinf and dTinf['forceFlash'].lower() == 'true': return True
    if 'name' in dTinf and dTinf['name'].find("'") != -1: return True
    if dTinf['bold'] == '1' and dTinf['ital'] == '1': return True
    return False
   
       
def getFontInfo(strFontPath, strTxtPath):
    fIn = None
    fOut = None
    streamIn = None
    dTinf = {}
    strJarPath = os.path.join(os.getcwd(), 'ttdump.jar')
    if not needsUpdate([strFontPath], strTxtPath):
        fIn = open(strTxtPath, 'r')
        streamIn = fIn
    else:
        fOut = open(strTxtPath, 'w')
        if IsSwfFont(strFontPath):
            astrName = os.path.basename(strFontPath)[0:-4].split('_',1)
            strName = astrName[0].lower().title().strip()
            strLanguage = astrName[1].lower().title().strip()
            streamIn = []
            streamIn.append('fileName: ' + os.path.basename(strFontPath))
            streamIn.append('fileName: ' + os.path.basename(strFontPath))
            streamIn.append('name: ' + strName)
            streamIn.append('subfamilyDisplayName: Regular')
            streamIn.append('fullName: ' + strName)
            streamIn.append('displayName: ~ ' + strName + ' ' + strLanguage)
            streamIn.append('ital: 0')
            streamIn.append('bold: 0')
        else:
            # create the file and return the contents
            strCmd = 'java -jar -Xms100m -Xmx100m "' + strJarPath + '" "' + strFontPath + '"'
            proc = Popen(strCmd, shell=True, stdout=PIPE)
            if proc.wait() != 0:
                print "Error getting font info for " + strFontPath
                print "cmd = " + strCmd
                return None
            streamIn = proc.stdout
   
    for strLine in streamIn:
        astrLine = strLine.split(':', 1)
        if len(astrLine) > 0:
            strKey = astrLine[0].strip()
            strVal = None
            if len(astrLine) > 1:
                strVal = astrLine[1].strip()
            dTinf[strKey] = strVal
            if fOut:
                fOut.write(strKey + ": " + strVal + "\n")
   
    if fOut:
        if not 'pkName' in dTinf:
            strKey = 'pkName'
            strVal = 'pk' + dTinf['fileName'][0:-4]
            strVal = re.sub('[^A-Za-z0-9]', '0', strVal)
            fOut.write(strKey + ": " + strVal + "\n")
            dTinf[strKey] = strVal
        fOut.close()
    if fIn:
        fIn.close()
    return dTinf
   
def createFlaSwfIfNeeded(strFontPath, strTxtPath, strFlaSwfPath, dTinf):
    if needsUpdate([strFontPath, strTxtPath], strFlaSwfPath):
        strFlaPath = "file:///" + os.path.join(os.getcwd(), 'publishFLA.fla').replace('\\', '/')
        strJSFLPath = os.path.join(os.getcwd(), 'temp.jsfl')
        # Create the fla file
        strJSFL = '''
fl.openDocument("''' + strFlaPath + '''");
var myDoc_doc = fl.getDocumentDOM();
var myTimeline_tl = myDoc_doc.getTimeline();
var myFrame_frame = myTimeline_tl.layers[0].frames[myTimeline_tl.currentFrame];
myFrame_frame.actionScript = "jsfl_txt.text =\\\"This text was added through JSFL!\\\";";
myDoc_doc.mouseClick({x:140, y:86}, false, true);
myDoc_doc.setElementTextAttr('face', ''' + "'" + dTinf['name'] + "'" + ''');
myDoc_doc.exportSWF("''' + "file:///" + strFlaSwfPath.replace('\\','/') + '''",true);
myDoc_doc.close(false);
'''   
        f = open(strJSFLPath, 'w')
        f.write(strJSFL)
        f.close()
       
        #undone: delete temp jsfl
       
        strCmd = 'flash.exe ' + strJSFLPath
        print "calling " + strCmd
        proc = Popen(strCmd, shell=True, stdout=PIPE).wait()
        print "done calling"
        print "waiting 10s"
        time.sleep(10)
        print "done waiting"

   
def createCssIfNeeded(strFontPath, strTxtPath, strCSSPath, dTinf):
    if dTinf['bold'] == '1':
        strWeight = 'bold'
    else:
        strWeight = 'normal'
   
    if dTinf['ital'] == '1':
        strStyle = 'italic'
    else:
        strStyle = 'normal'

    strFlaSwfPath = strCSSPath[0:-4] + "_fla.swf"
   
    bNeedsUpdate = needsUpdate([strTxtPath], strCSSPath)
    if FontRequiresFlaCompile(strFontPath, dTinf):
        bNeedsUpdate = bNeedsUpdate or needsUpdate([strTxtPath], strFlaSwfPath)

    if IsSwfFont(strFontPath) or FontRequiresFlaCompile(strFontPath, dTinf):
        dTinf['family'] = dTinf['name']
    else:
        dTinf['family'] = dTinf['pkName']

    if bNeedsUpdate:
        strClassName = dTinf['pkName']
        # strFontFamily = dTinf['name']
        strRange = "unicodeRange: U+0000-U+00FF;"
        strFlashType = "flashType: true;"
        strSrc = 'local("' + dTinf['name'] + '");'
        # strSrc = 'url("../ttf/' + os.path.basename(strFontPath) + '");'
       
        # Check for the special case, bold+italic. These need to be compiled by flash due to a bug in the mxmlc compiler
        if IsSwfFont(strFontPath) or FontRequiresFlaCompile(strFontPath, dTinf):
            strRange = "/* unicodeRange: U+0000-U+00FF; */"
            strFlashType = "/* flashType: true; */"

            strSrc = 'url("' + os.path.basename(strFlaSwfPath) + '");'
           
            if IsSwfFont(strFontPath):
                # copy the swf font if needed.
                if needsUpdate([strFontPath], strFlaSwfPath):
                    shutil.copy2(strFontPath, strFlaSwfPath)
            else:
                # Now, see if we need to create the swf
                createFlaSwfIfNeeded(strFontPath, strTxtPath, strFlaSwfPath, dTinf)

        strCssFile = '''
@font-face {
    src:''' + strSrc + '''
    font-family: "''' + dTinf['family'] + '''";
    ''' + strRange + '''
    ''' + strFlashType + '''
    fontWeight: ''' + strWeight + ''';
    fontStyle: ''' + strStyle + ''';
}

.''' + strClassName + '''
{
    font-family: "''' + dTinf['family'] + '''";
    fontWeight: ''' + strWeight + ''';
    fontStyle: ''' + strStyle + ''';
}
'''
        f = open(strCSSPath, 'w')
        f.write(strCssFile)
        f.close()

       
def createSwfIfNeeded(strFontPath, strCSSPath, strSWFPath, dTinf):
    if needsUpdate([strFontPath, strCSSPath], strSWFPath):
        strMxmlc = os.path.join(os.getcwd(), '..','flexsdk','bin','mxmlc')
       
        strCmd = strMxmlc
        # strCmd += ' -managers=flash.fonts.BatikFontManager'
        strCmd += ' -output "' + strSWFPath
        strCmd += '" ' + strCSSPath
        strCmd = strMxmlc + ' -managers=flash.fonts.BatikFontManager ' + ' -output "' + strSWFPath + '" ' + strCSSPath
       
        print "Compiling " + os.path.basename(strFontPath)
        proc = Popen(strCmd, shell=True, stdout=PIPE)
        if proc.wait() != 0:
            print "Error compiling swf " + strCSSPath
       
def needsPng(strSwfPath, strPngBase, dTinf):
    strPngPath = strPngBase + "_pkSmall.png" # One of multiple files that may be created (decided by Air app)
    strUtilDir = os.path.join(os.getcwd(), 'util')
    strAdl = os.path.join('C:\\', 'Program Files', 'Adobe', 'Flex Builder 3', 'sdks' , '3.0.0', 'bin', 'adl.exe')
    strFontToPngPath = "adl src/FontToPng2/bin/FontToPng2-app.xml -- "

    strSwfBaseName = os.path.basename(strSwfPath)
    strSwfUtilPath = os.path.join(strUtilDir, strSwfBaseName)
    if needsUpdate([strSwfPath], strSwfUtilPath):
        shutil.copy2(strSwfPath, strSwfUtilPath)
   
    return needsUpdate([strSwfPath], strPngPath)
    #if needsUpdate([strSwfPath], strPngPath):
    #    strCmd = strFontToPngPath
    #    strCmd += ' ' + '"url:' + strSwfBaseName + '"'
    #    strCmd += ' ' + '"name:' + dTinf['name'] + '"'
    #    strCmd += ' ' + '"style:' + dTinf['pkName'] + '"'
    #    strCmd += ' ' + '"outputbase:' + strPngBase + '"'
    #   
    #    print "Creating PNG " + strPngPath
    #    print strCmd
    #    Popen(strCmd, shell=True, stdout=PIPE)
    #    time.sleep(0.2)

def mkdirForFile(strFilePath):
    mkdirIfNeeded(os.path.dirname(strFilePath))

def mkdirIfNeeded(strFolder):
    if not os.path.exists(strFolder):
        os.mkdir(strFolder)

def fileSize(strSwfPath):
    return os.stat(strSwfPath)[ST_SIZE]
   
   
def compileFont(strFontPath):
    if not IsSwfFont(strFontPath):
        strFontPath = cleanFontFileName(strFontPath)
    strFontFileName = os.path.basename(strFontPath)
    strFontFileNameBase = strFontFileName[0:-4]
    strCWD = os.getcwd() # This should be /src/picnik/fonts
    strBasePicnikDir = os.path.join(strCWD, "..")

    strTxtPath = os.path.join(strCWD, 'txt', strFontFileNameBase + '.txt')
    strCssPath = os.path.join(strCWD, 'css', strFontFileNameBase + '.css')
   
    strSwfPath = os.path.join(strBasePicnikDir, 'website', 'fonts', 'swfs', strFontFileNameBase + '.swf')
    strPngBase = os.path.join(strBasePicnikDir, 'website', 'fonts', 'pngs', strFontFileNameBase)
   
    mkdirForFile(strTxtPath)
    mkdirForFile(strCssPath)
    mkdirForFile(strSwfPath)
    mkdirForFile(strPngBase)
   
    dTinf = getFontInfo(strFontPath, strTxtPath)
    if dTinf:
        # We have font info. Now create the CSS file
        fInstalled = False
        strInstallTarget = os.path.join("C:\\", "windows", "fonts", os.path.basename(strFontPath))
       
        try:
           
            if not os.path.exists(strInstallTarget) and not IsSwfFont(strFontPath):
                shutil.copy(strFontPath, strInstallTarget)
                fInstalled = True
       
            createCssIfNeeded(strFontPath, strTxtPath, strCssPath, dTinf)
            createSwfIfNeeded(strFontPath, strCssPath, strSwfPath, dTinf)
            dTinf['size'] = str(fileSize(strSwfPath))
        finally:
            if fInstalled:
                os.remove(strInstallTarget)
               
        dTinf['needsPng'] = needsPng(strSwfPath, strPngBase, dTinf)
        
    return dTinf

def encodeXmlAttribute(ob):
    return str(ob).replace('%','%25').replace('&','%26').replace('<','%3C').replace('\'','%27').replace('"','%22')

def addFontToFamilies(fname, dTinf, dFontFamilies):
    dTinf['baseFileName'] = encodeXmlAttribute(os.path.basename(fname)[0:-4])
    strKey = dTinf['displayName'].lower()
    if not strKey in dFontFamilies:
        dFontFamilies[strKey] = []
    dFontFamilies[strKey].append(dTinf)
   

def writeFontXml(dFontFamilies, strFontXmlPath):
    mkdirForFile(strFontXmlPath)
    f = open(strFontXmlPath, 'w')
    f.write('<fontCollection>\n')
   
    for k in sorted(set(dFontFamilies.keys())):
        aFamily = dFontFamilies[k]

        nDefaultWeight = -1
        for dFont in aFamily:
            nWeight = 4
            if dFont['bold'] == '1': nWeight -= 2
            if dFont['ital'] == '1': nWeight -= 1
            if nWeight > nDefaultWeight:
                nDefaultWeight = nWeight
                dDefaultFont = dFont
       
        dParams = {}
        for k, v in dDefaultFont.iteritems():
            dParams[k] = encodeXmlAttribute(v)
        f.write('  <fontFamily baseFileName="%(baseFileName)s" familyName="%(name)s"'
            ' displayName="%(displayName)s" authorName="%(authorName)s" authorUrl="%(authorUrl)s">\n' % dParams)
       
        for dFont in aFamily:
            dParams = {}
            for k, v in dFont.iteritems():
                dParams[k] = encodeXmlAttribute(v)
            dParams['embeded'] = 0
            if dParams['name'] == "Trebuchet MS" and not dParams['ital'] == '1':
                dParams['family'] = "trebuchetMS"
                dParams['embeded'] = 1
                dParams['size'] = '0'
            f.write('    <font baseFileName="%(baseFileName)s" className="%(pkName)s" familyName="%(family)s"'
                ' isBold="%(bold)s" isItalic="%(ital)s" isEmbeded="%(embeded)i" size="%(size)s"/>\n' % dParams)
        f.write('  </fontFamily>\n' % dParams)

    f.write('</fontCollection>\n')
    f.close()
	
	
if __name__ == '__main__':
    dirList = glob.glob(os.path.join(os.getcwd(), 'ttf', '*.ttf')) + glob.glob(os.path.join(os.getcwd(), 'ttf', '*.swf'))
    dFontFamilies = {}
    dNewFontFamilies = {}
    for fname in dirList:
        dTinf = compileFont(fname)
        addFontToFamilies(fname, dTinf, dFontFamilies)
        if dTinf['needsPng']:
            addFontToFamilies(fname, dTinf, dNewFontFamilies)

    strFontBasePath = os.path.join(os.getcwd(),'..','website','fonts')
    strFontXmlPath = os.path.join(strFontBasePath,'fonts_temp.xml')
    strNewFontXmlPath = os.path.join(strFontBasePath,'new_fonts.xml')
    writeFontXml(dFontFamilies, strFontXmlPath)
    writeFontXml(dNewFontFamilies, strNewFontXmlPath)

		