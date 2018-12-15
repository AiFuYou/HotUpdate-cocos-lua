local new = require("luaList")
local old = require("luaList_old")

local count = 0

function copyFile( file )
	count = count + 1
	os.execute(string.format("cp %s %s", "/Users/$USER/Documents/warshipX/client/warship/src/"..file, "/Users/$USER/Documents/warshipX/client/updateTools/src/"..file))
end

for file,info in pairs(new) do
	if old[file] then
		if type(old[file]) == "table" then
			if old[file].md5 ~= info.md5 then
				copyFile(file)
			end
		end
	else
		copyFile(file)
	end
end

print("共筛选出"..count.."个lua文件")