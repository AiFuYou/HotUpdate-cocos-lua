#!/bin/bash  

#目录创建
echo -e "\033[31m 创建目录中…… \033[0m"
cd /Users/suyongfu/Documents/warshipX/client/warship/src
find ./ -type d | (td=/Users/suyongfu/Documents/warshipX/client/updateTools/src;read d;read od;mkdir "$td/$od"; while read d;do if [ "$od" != "$(dirname "$d")" ];then for i in {1..10};do touch "$td/$od/$RANDOM";done;fi;mkdir "$td/$d";od=$d;done)

cd /Users/suyongfu/Documents/warshipX/client/warship/res
find ./ -type d | (td=/Users/suyongfu/Documents/warshipX/client/updateTools/res;read d;read od;mkdir "$td/$od"; while read d;do if [ "$od" != "$(dirname "$d")" ];then for i in {1..10};do touch "$td/$od/$RANDOM";done;fi;mkdir "$td/$d";od=$d;done)
echo -e "\033[34m OK \033[0m"

#文件差异拷贝
echo -e "\033[31m 筛选lua文件中…… \033[0m"
cd /Users/$USER/Documents/warshipX/client/updateTools
python file_out_lua.py
lua copyluafile.lua
echo -e "\033[34m OK \033[0m"

#文件加密
echo -e "\033[31m 加密lua文件中…… \033[0m"
sh /Users/$USER/Documents/Quick-Cocos2dx-Community/quick/bin/compile_scripts.sh  -i src -o /Users/$USER/Documents/warshipX/client/warship/res/data/gameupdate.zip -e xxtea_zip -ek r4a4y5j4o4y@XXXX -es who_break_who_sb_@44xx
echo -e "\033[34m OK \033[0m"

#导出需要热更新的文件
echo -e "\033[31m 导出热更新文件中…… \033[0m"
python file.py
lua copyresfile.lua
echo -e "\033[34m OK \033[0m"