--[[
	author:suyongfu
	time:2016.4.9
]]

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

--其他方法
function table.map(t, fn)
    for k, v in pairs(t) do
        t[k] = fn(v, k)
    end
end


















require("lfs")

local UpdateAPI = {}
UpdateAPI.WAIT_TIME = 60  --等待时间，超过60秒请求超时

--检查网络状态
function UpdateAPI.getNetworkStatus(  )
	local status = cc.Network:getInternetConnectionStatus()
	if status == cc.kCCNetworkStatusReachableViaWiFi then
		return "wifi"
	elseif status == cc.kCCNetworkStatusReachableViaWWAN then
		return "3G"
	elseif status == cc.kCCNetworkStatusNotReachable then
		return false
	else
		return false
	end
end

function UpdateAPI.sendRequest( callback, url, method )
	local method = method or "GET"
    if string.upper(tostring(method)) == "GET" then
        method = cc.kCCHTTPRequestMethodGET
    else
        method = cc.kCCHTTPRequestMethodPOST
    end

    local request = cc.HTTPRequest:createWithUrl(function ( event )
    	callback(event)
    end, url, method)

    request:setTimeout(UpdateAPI.WAIT_TIME)
    request:start()

    print("发送请求"..url)
end

--热更开关
function UpdateAPI.requestSwitch( callback, url, method )
    local apiCallback = function ( event )
    	local ok = (event.name == "completed")
	    local request = event.request
	 
	    if not ok then
	        -- 请求失败，显示错误代码和错误消息
	        print(request:getErrorCode(), request:getErrorMessage())
	        return
	    end
	 
	    local code = request:getResponseStatusCode()
	    if code ~= 200 then
	        -- 请求结束，但没有返回 200 响应代码
	        print(code)
	        return
	    end
	 
	    -- 请求成功
	    local response = request:getResponseString()
	    callback(response)
    end

    UpdateAPI.sendRequest(apiCallback, UPDATE_SWITCH_URL)
end

function UpdateAPI.requestFileList( callback, forceUpdateCallback )
	local apiCallback = function ( event )
    	local ok = (event.name == "completed")
	    local request = event.request
	 
	    if not ok then
	        -- 请求失败，显示错误代码和错误消息
	        print(request:getErrorCode(), request:getErrorMessage())
	        return
	    end
	 
	    local code = request:getResponseStatusCode()
	    if code ~= 200 then
	        -- 请求结束，但没有返回 200 响应代码
	        print(code)
	        return
	    end
	 
	    -- 请求成功，显示服务端返回的内容
	    local data = request:getResponseData()
	    UpdateAPI.data = data

	    local fileList_old = require("fileList")
		local fileList_new = loadstring(data)()
		local downloadList = {}
		local downloadSize = 0

		for path,fileInfo in pairs(fileList_new) do
			if type(fileInfo) == "table" then
				if fileList_old[path] then
					if fileList_old[path].md5 ~= fileList_new[path].md5 then
						downloadList[#downloadList + 1] = path
						downloadSize = downloadSize + fileInfo.size
					end
				else
					downloadList[#downloadList + 1] = path
					downloadSize = downloadSize + fileInfo.size
				end
			end
		end

		UpdateAPI.fileList_old = fileList_old
    	UpdateAPI.fileList_new = fileList_new

    	if fileList_old.version < fileList_new.version and fileList_new.force_update then
    		--强更大版本，则删除本地fileList.lua文件
			local writablePath = cc.FileUtils:getInstance():getWritablePath()
			local fileListPath = writablePath.."fileList.lua"
			if cc.FileUtils:getInstance():isFileExist(fileListPath) then
				os.remove(fileListPath)
			end
    		
    		if cc.Application:getInstance():getTargetPlatform() == DEVICE_PLATFORM_ANDROID then
    			forceUpdateCallback(fileList_new.android_download)
    		else
    			forceUpdateCallback(fileList_new.ios_download)
    		end
    	else
    		callback(downloadList, downloadSize)
    	end
    end
    
    UpdateAPI.sendRequest(apiCallback, UPDATE_DOWNLOAD_URL.."fileList.lua")
end

--下载文件
function UpdateAPI.downloadFiles( sCallback, fCallback, downloadList, downloadSize )
	UpdateAPI.downloadList_ = downloadList
	UpdateAPI.downloadSize_ = downloadSize
	UpdateAPI.downloadSCallback = sCallback
	UpdateAPI.downloadFCallback = fCallback
	UpdateAPI.downloadIndex_ = 1
	UpdateAPI.haveDownloadSize_ = 0

	UpdateAPI.downloadFile(UpdateAPI.downloadList_[UpdateAPI.downloadIndex_])
end

function UpdateAPI.downloadFile( filePath )
	if cc.UserDefault:getInstance():getStringForKey(filePath) == UpdateAPI.fileList_new[filePath].md5 then
		UpdateAPI.checkDownloadComplete()
		return
	end

	local apiCallback = function ( event )
		dump(event)
    	if event.name == "progress" then
    		UpdateAPI.downloadSCallback((event.dltotal / 1024 + UpdateAPI.haveDownloadSize_) * 100 / UpdateAPI.downloadSize_)
    	elseif event.name == "completed" then
			local request = event.request
			local code = request:getResponseStatusCode()

			if code ~= 200 then
				--重定向解决
				if code == 301 or code == 302 or code == 303 then
		        	local reg = "http%C-%s" --url 提取
	        		local newURL = string.match(request:getResponseHeadersString(),reg)

	        		if newURL then
	        			UpdateAPI.downloadFile(newURL)
	        		else
	        			UpdateAPI.downloadFCallback(110)
	        		end
	        		
	        		return
	        	else
	        		UpdateAPI.downloadFCallback(code)
		        end

				return
			end

			local data = request:getResponseData()
			local writablePath = cc.FileUtils:getInstance():getWritablePath()
			local updateFilePath = writablePath.."res/"..filePath

			--如果文件不存在，则创建文件
			local file = io.open(updateFilePath, "r")
			if file == nil then
				UpdateAPI.makeDir(updateFilePath)
			end

			--写入刚下载的文件
			file = io.open(updateFilePath, "w")
	    	file:write(data)
			io.close(file)

			--断点续下
			cc.UserDefault:getInstance():setStringForKey(filePath, UpdateAPI.fileList_new[filePath].md5)
			cc.UserDefault:getInstance():flush()

			UpdateAPI.checkDownloadComplete()
    	end
    end

    UpdateAPI.sendRequest(apiCallback, UPDATE_DOWNLOAD_URL.."res/"..filePath)
end

function UpdateAPI.checkDownloadComplete(  )
	--计算已下载文件的大小占总需下载文件的百分比
	UpdateAPI.haveDownloadSize_ = 0
	for i=1,UpdateAPI.downloadIndex_ do
		UpdateAPI.haveDownloadSize_ = UpdateAPI.haveDownloadSize_ + UpdateAPI.fileList_new[UpdateAPI.downloadList_[i]].size
	end
	UpdateAPI.downloadSCallback(UpdateAPI.haveDownloadSize_ * 100 / UpdateAPI.downloadSize_)

	--检测是否下载最后一个文件
	if UpdateAPI.downloadIndex_ < #UpdateAPI.downloadList_ then
		UpdateAPI.downloadIndex_ = UpdateAPI.downloadIndex_ + 1
		UpdateAPI.downloadFile(UpdateAPI.downloadList_[UpdateAPI.downloadIndex_])
	else
		--全部更新完毕，则写入最新的fileList文件
		local writablePath = cc.FileUtils:getInstance():getWritablePath()
		local fileListPath = writablePath.."fileList.lua"
		local f = io.open(fileListPath, "w")
		f:write(UpdateAPI.data)
		io.close(f)
		UpdateAPI.downloadSCallback("success")
	end
end

function UpdateAPI.makeDir( path )
 	if lfs.chdir(path) then
        return
    end
    local rt = string.split(path,"/")
    local tmp = ""
    for i = 1,#rt-1 do
        folder = rt[i]
        tmp = tmp..folder.."/"
        if lfs.chdir(tmp) == nil then
            lfs.mkdir(tmp)
        end
    end
end

return UpdateAPI
