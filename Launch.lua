--[[
	author:suyongfu
	time:2016.4.9
]]

function __G__TRACKBACK__(errorMessage)
    print("异常错误----------------start------------------------")
    print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    print(debug.traceback("", 2))
    print("异常错误----------------end------------------------")
end

cc.FileUtils:getInstance():setPopupNotify(false)
require("UpdateScene"):checkUpdate()