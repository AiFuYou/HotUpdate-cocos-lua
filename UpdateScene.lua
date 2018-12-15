--[[
	author:suyongfu
	time:2016.4.9
]]

require("UpdateCfg")

local JSON = require("json")
local api = require("UpdateAPI")
local UpdateScene = {}

function UpdateScene:checkUpdate(  )
	if not UPDATE_OPEN then
		self:startGame()
		return
	end

	if not api.getNetworkStatus() then
		self:showAlert({
			message = "网络连接失败\n请在 设置 中将您的设备连接到网络",
			listener = function ( event )
				os.exit()
			end
		})
	else
		api.requestSwitch(function ( response )
			local result = JSON.decode(response).open
			if result then
				self:init()
			else
				self:startGame()
			end
		end)
	end
end

function UpdateScene:init(  )
	self.scene_ = cc.Scene:create()
	cc.Director:getInstance():runWithScene(self.scene_)
	self.size_ = cc.Director:getInstance():getWinSize()
	self.layer_ = cc.Layer:create()
	self.scene_:addChild(self.layer_)

	self.progressText_ = cc.Label:createWithSystemFont("检测更新中……", "Arial", 30)
	self.progressText_:setAnchorPoint(0.5, 0.5)
	self.progressText_:setPosition(self.size_.width / 2, self.size_.height / 2)
	self.progressText_:setTextColor({r = 255, g = 0, b = 0})
	self.layer_:addChild(self.progressText_)

	self:getDownloadList()
end

function UpdateScene:getDownloadList(  )
	self.progressText_:setString("获取下载列表中……")
	self.downloadList_ = {}
	self.downloadSize_ = 0

	api.requestFileList(function ( downloadList, downloadSize )
		self.downloadList_ = downloadList
		self.downloadSize_ = downloadSize

		self.progressText_:setString("开始下载")
		self.progress_ = 0
		self:downloadFiles()
	end, function ( url )
		self:showAlert({
			message = "您需要下载新版本才能进行游戏，是否下载？",
			buttonLabels = {"取消", "确定"},
			listener = function ( event )
				if event.buttonIndex == 2 then
					cc.Native:openURL(url)
				end

				os.exit()
			end
		})
	end)
end

function UpdateScene:downloadFiles(  )
	dump(self.downloadList_)
	if next(self.downloadList_) then
		api.downloadFiles(function ( progress )
			if progress == "success" then
				self:startGame()
			else
				self.progress_ = math.floor(progress + 0.5)
				if self.progress_ > 100 then
					self.progress_ = 100
				end
				self.progressText_:setString(string.format("下载进度  %s%%", self.progress_))
			end
		end, function ( errorCode )
			self:showAlert({
				message = string.format("手机网络异常，异常代码：%s，请重试！", errorCode),
				listener = function ( event )
					os.exit()
				end
			})
		end, self.downloadList_, self.downloadSize_)
	else
		self:startGame()
	end
end

function UpdateScene:startGame(  )
	cc.LuaLoadChunksFromZIP("res/data/game.zip")
	if cc.FileUtils:getInstance():isFileExist("res/data/gameupdate.zip") then
		cc.LuaLoadChunksFromZIP("res/data/gameupdate.zip")
	end
	require("main")
end

function UpdateScene:showAlert( param )
	local title = param.title or "提示"
	local buttonLabels = param.buttonLabels or {"确定"}
	local message = param.message
	local listener = param.listener

	if type(buttonLabels) ~= "table" then
        buttonLabels = {tostring(buttonLabels)}
    else
        table.map(buttonLabels, function(v) return tostring(v) end)
    end

	if cc.Application:getInstance():getTargetPlatform() == DEVICE_PLATFORM_ANDROID then  --3是这卓平台
		local tempListner = function(event)
			if type(event) == "string" then
				event = JSON.decode(event)
				event.buttonIndex = tonumber(event.buttonIndex)
			end
			if listener then listener(event) end
		end
		require("luaj").callStaticMethod("org/cocos2dx/utils/PSNative", "createAlert", {title, message, buttonLabels, tempListner}, "(Ljava/lang/String;Ljava/lang/String;Ljava/util/Vector;I)V");
	else
	    local defaultLabel = ""
	    if #buttonLabels > 0 then
	        defaultLabel = buttonLabels[1]
	        table.remove(buttonLabels, 1)
	    end

	    cc.Native:createAlert(title, message, defaultLabel)
	    for i, label in ipairs(buttonLabels) do
	        cc.Native:addAlertButton(label)
	    end

	    if type(listener) ~= "function" then
	        listener = function() end
	    end

	    cc.Native:showAlert(listener)
	end
end

return UpdateScene