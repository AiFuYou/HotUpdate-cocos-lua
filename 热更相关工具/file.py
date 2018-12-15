from __future__ import division
import sys, os, re, getpass, hashlib

global fileCount
global f
global version
global ios_download
global android_download

# md5 = hashlib.md5()
user = getpass.getuser()
resDirPath = '/Users/' + user + '/Documents/warshipX/client/warship/res/'
scriptsDirPath = '/Users/' + user + '/Documents/warshipX/client/warship/src/'
curPath = os.getcwd()

version = 1
force_update = "true"
android_download = "\"http://www.baidu.com\""
ios_download = "\"http://www.google.com.hk\""

f = open(curPath + '/fileList.lua', 'w')
headStr = 'local fileList = {\n\tversion = ' + str(version) + ', \n\tandroid_download = ' + android_download + ', \n\tios_download = '+ ios_download + ', \n\tforce_update = '+ force_update + '\n}\n\n'
tailStr = '\nreturn fileList\n'
fileCount = 0



def getFileFromDir(dir, tag):	
	global fileCount
	for item in os.listdir(dir):
		temp = dir + item
		#Ignore hidden files
		if re.match('^\.', item) or item == "update.zip" or item == "game.zip":
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
			key = 'fileList[\"' + temp + '\"]'
			value = '{md5 = \"' + md5.hexdigest() + '\", ' + 'size = ' + str(size) + '}'
			writeToFile(key + " = " + value + "\n")
			fileCount += 1
			

def writeToFile(str):
	global f
	f.write(str)


writeToFile(headStr)

getFileFromDir(resDirPath, "res")
# getFileFromDir(scriptsDirPath, "src")

writeToFile(tailStr)
f.close()