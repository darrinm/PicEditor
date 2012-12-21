import os
astrPbk = [strFile for strFile in os.listdir('.') if strFile.endswith('.pbk')]
for strPbk in astrPbk:
	strCmd = '''pbutil %s %s.pbj''' % (strPbk, os.path.splitext(strPbk)[0])
	print strCmd
	os.system(strCmd)
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

