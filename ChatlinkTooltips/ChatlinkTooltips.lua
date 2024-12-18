-- [#] table: 0x116a8d4e0 item:40255::::::::80::::::::: [Dying Curse] table: 0x116a90a50 152 0 82.666687011719 13.866666793823

local function showTooltip(self, linkData) -- ... refers to a tuple which comprises all arguments passed
    local linkType = string.split(":", linkData) -- linkData:split(":")
    -- gmatch returns an iterator which is a function in lua
    -- local linkType = string.gmatch(linkData, "([^:]+)")() -- '[^,]' means "everything but the comma, the + sign means "one or more characters". The parenthesis create a capture (not really needed in this case).
    -- for linkType in string.gmatch(linkData, "([^:]+)") do
        -- print(linkType)
    -- end
    if linkType == "item"
    or linkType == "spell"
    or linkType == "enchant"
    or linkType == "quest"
    or linkType == "talent"
    or linkType == "glyph"
    or linkType == "unit"
    or linkType == "achievement" then -- does not have an associated tooltip like a player
        -- frame GameTooltip to show tooltip
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR") -- self is ChatFrame. A tooltip is always bound to a frame that owns the tooltip, and hiding the owner will also hide the tooltip.
        GameTooltip:SetHyperlink(linkData) -- takes the data from a link (the long string with a lot of numbers separated by colons) and sets the content of the tooltip to the corresponding item, spell, or achievement.
        GameTooltip:Show()
    end
end

local function hideTooltip()
    GameTooltip:Hide() -- so frame GameTooltip is a global variable
end

local function setOrHookHandler(frame, script, func)
    if frame:GetScript(script) then
        frame:HookScript(script, func)
    else
        frame:SetScript(script, func)
    end
end

for i = 1, NUM_CHAT_WINDOWS do
    local frame = getglobal("ChatFrame"..i) -- .. operator concatenates two strings.
    if frame then -- so frames are just tables(global variables)
        setOrHookHandler(frame, "OnHyperLinkEnter", showTooltip)
        setOrHookHandler(frame, "OnHyperLinkLeave", hideTooltip)
    end
end

-- ----------- test OnEvent ----------- --

local frame = CreateFrame("Frame") -- an invisible frame

local function myEventHandler(self, event, msg, sender, ...) -- the author uses script to refer to GUI-related event, event to refer to gameplay event
    print(event, sender, msg)
    print(...) -- 在lua里，后面的参数不写也可以，连...也可以不写，应该是按参数顺序重载了，像下面那样
    -- overloading
    -- myEventHandler(arg0)
    -- myEventHandler(arg0, arg1)
end

-- Registers which events the object would like to monitor. This ensures the code placed in the <OnEvent> section is not called for any unneccessary events such as an incoming chat message when your addon is only looking to perform actions based upon the start of casting a spell. The last frame to register for an event is the last one to receive it.
frame:RegisterEvent("CHAT_MSG_WHISPER") -- 意思是CHAT_MSG_WHISPER是个通用的事件，可以绑定在任何frame上
frame:SetScript("OnEvent", myEventHandler) -- 目前的理解如下
-- Frames绑定着events也就是scripts，每个script需要handler也就是一个个callback function。
-- RegisterEvent可以让frame监听一个新事件(区别是这些事件都统一通过OnEvent触发Handler，不像上面的OnHyperLinkEnter/OnHyperLinkLeave)，所谓“监听monitor”，其实就是在一个事件发生时，返回相关的所需数据，比如当私聊发生时返回私聊的发送者和接收者。
-- 该被监听事件script/event的每一个handler都会得到所有上述“所需的数据”作为参数。

local function onNewZone()
    local mapID = C_Map.GetBestMapForUnit("player")
	print(GetZoneText(), C_Map.GetMapInfo(mapID).name)
end

local function myMultipleEventsHandler(self, event, ...)
    if event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        print(sender, " wrote ", msg)
    elseif event == "ZONE_CHANGED_NEW_AREA" then -- no payload(no arguments), 不register可以吗？测试结果是不可以
        onNewZone()
    elseif event == "..." then
    end
end
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:SetScript("OnEvent", myMultipleEventsHandler)