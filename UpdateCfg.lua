--[[
    author:suyongfu
    time:2016.4.9
]]

DEVICE_PLATFORM_ANDROID = 3
DEVICE_PLATFORM_IPHONE = 4
DEVICE_PLATFORM_IPAD = 5

--平台热更文件下载地址
local urlTab = {
    ios = {
        test = "http://192.168.103.129/update/ios/",
    },

    android = {
        test = "http://192.168.103.129/update/android/",
    }
}

local device_platform = ""
local target = cc.Application:getInstance():getTargetPlatform()
if target == DEVICE_PLATFORM_ANDROID then
    device_platform = "android"
elseif target == DEVICE_PLATFORM_IPHONE or DEVICE_PLATFORM_IPAD then
    device_platform = "ios"
end


if device_platform ~= "" and urlTab[device_platform].test then
    --热更文件下载地址
    UPDATE_DOWNLOAD_URL = urlTab[device_platform].test
    --热更开关
    UPDATE_SWITCH_URL = urlTab[device_platform].test.."switch.json"

    UPDATE_OPEN = true
else
    UPDATE_OPEN = false
end



