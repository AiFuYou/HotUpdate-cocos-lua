local new = require("fileList")
local old = require("fileList_old")

local count = 0
local size = 0

function copyFile( file )
	count = count + 1
	size = size + new[file].size
	os.execute(string.format("cp %s %s", "/Users/$USER/Documents/warshipX/client/warship/res/"..file, "/Users/$USER/Documents/warshipX/client/updateTools/res/"..file))
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

print("本次更新共"..count.."个文件")
print("大小为"..size.."KB")