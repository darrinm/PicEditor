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
adGroupInfo = [
	{	'strName': 'main',
		'astrLocs': ['de', 'es', 'fr', 'it', 'jp', 'kr', 'pt', 'zhHK', 'id', 'vi', 'zhCN', 'no', 'sv', 'ru'],
		'strPropsFileExtension':''},
	{	'strName': 'Tier1',
		'astrLocs': ['enGB', 'nl', 'pl', 'tr', 'tl'],
		'strPropsFileExtension':'_Tier1'}
]

def IsGroup(strGroup):
	return GetGroupInfo(strGroup) is not None

def GetGroupInfo(strGroup):
	global adGroupInfo
	strGroup = strGroup.lower()
	for dGroupInfo in adGroupInfo:
		if dGroupInfo['strName'].lower() == strGroup:
			return dGroupInfo
	return None # not found

def GetAllGroupInfo():
	global adGroupInfo
	return adGroupInfo
	
def PrintAllGroupInfo():
	for dGroupInfo in adGroupInfo:
		print "    - " + dGroupInfo['strName'] + " <" + ', '.join(dGroupInfo['astrLocs']) + ">"

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

