from __future__ import division
import sys, os, re, getpass, hashlib

global fileCount
global f
global version
global ios_download
global android_download

# md5 = hashlib.md5()
user = getpass.getuser()
resDirPath = '/Users/' + user + '/Documents/warshipX/client/plist/imgs/'
scriptsDirPath = '/Users/' + user + '/Documents/warshipX/client/warship/src/'
curPath = os.getcwd()

version = 1
android_download = "\"\""
ios_download = "\"\""

f = open(curPath + '/luaList.lua', 'w')
headStr = 'local luaList = {}\n\n'
tailStr = '\nreturn luaList\n'
fileCount = 0



def getFileFromDir(dir, tag):	
	global fileCount
	for item in os.listdir(dir):
		temp = dir + item
		
		#Ignore hidden files
		if re.match('^\.', item):
			continue

		if os.path.isdir(temp):
			#Ignore hidden folder
			if re.match('^\.', item):
				continue
			else:
				getFileFromDir(temp + '/', tag)
		else:
			# print temp
			size = ("%.3f" % (os.path.getsize(temp) / 1024))
			md5 = hashlib.md5()
			md5.update(open(temp, "r").read())
			temp = temp[(temp.find("/" + tag + "/") + len("/" + tag + "/")):len(temp)] 
			key = 'luaList[\"' + temp + '\"]'
			value = '{md5 = \"' + md5.hexdigest() + '\", ' + 'size = ' + str(size) + '}'
			writeToFile(key + " = " + value + "\n")
			fileCount += 1
			

def writeToFile(str):
	global f
	f.write(str)


writeToFile(headStr)

# getFileFromDir(resDirPath, "imgs")
getFileFromDir(scriptsDirPath, "src")

writeToFile(tailStr)
f.close()