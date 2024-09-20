local currentItem -- the current item or nil if no auction is running
local bids = {} -- bids on the current item
local prefix = "[SimpleGDKP]" -- prefix for chat messages

-- default values for saved variables/options
SimpleGDKP_Channel = "RAID_WARNING" -- the chat channel to use
-- SimpleGDKP_AuctionTime = 30 -- the time (in seconds) for an auction
SimpleGDKP_MinBid = 1 -- the minimum amount of gold you have to bid (1 = 100g)
SimpleGDKP_ACL = {} -- the access control list
SimpleGDKP_IdleTime = 10 -- the acceptable idle time (in seconds) for no one placing new bid, > 5

-- declare the fucntions we are going to need
local startAuction, endAuction, placeBid, cancelAuction, onEvent, countdown

do -- only visible in this scope
    local auctionAlreadyRunning = "There is already an auction running! (on %s)" -- Storing strings in variables allows us to change them easily without searching and chang- ing every occurrence of the string. This is also useful when we want to translate our addon later
    local startingAuction = prefix.."Starting auction for item %s, please place your bids in RAID channel. The auction ends in %d seconds if no one places a bid."
    local auctionProgress = prefix.."Time remaining for %s: %d seconds." -- 改the highest bid

    function startAuction(item, starter) -- it's already delcared, "local function startAuction" will create a new variable
        if currentItem then
            local msg = auctionAlreadyRunning:format(currentItem)
            if starter then
                SendChatMessage(msg, "WHISPER", nil, starter) -- The error message is whispered to the player who tried to start the auction if it was started remotely. 
            else
                print(msg)
            end
        else
            currentItem = item
            SendChatMessage(startingAuction:format(item, SimpleGDKP_IdleTime), SimpleGDKP_Channel) -- RAID_WARNING?
            -- if SimpleGDKP_AuctionTime > 30 then -- countdown
            --     SimpleTimingLib_Schedule(SimpleGDKP_AuctionTime - 30, SendChatMessage, auctionProgress:format(item, 30), SimpleGDKP_Channel)
            -- end
            -- if SimpleGDKP_AuctionTime > 15 then
            --     SimpleTimingLib_Schedule(SimpleGDKP_AuctionTime - 15, SendChatMessage, auctionProgress:format(item, 15), SimpleGDKP_Channel)
            -- end
            -- 5 more seconds for thinking at the beginning of an auction
            if SimpleGDKP_IdleTime > 5 then
                countdown(item, SimpleGDKP_IdleTime)
            end
            SimpleTimingLib_Schedule(SimpleGDKP_IdleTime + 5, endAuction)
        end
    end

    function countdown(item, xSecondsLater)
        SimpleTimingLib_Schedule(xSecondsLater, SendChatMessage, auctionProgress:format(item, 5), SimpleGDKP_Channel)
        SimpleTimingLib_Schedule(xSecondsLater + 1, SendChatMessage, auctionProgress:format(item, 4), SimpleGDKP_Channel)
        SimpleTimingLib_Schedule(xSecondsLater + 2, SendChatMessage, auctionProgress:format(item, 3), SimpleGDKP_Channel)
        SimpleTimingLib_Schedule(xSecondsLater + 3, SendChatMessage, auctionProgress:format(item, 2), SimpleGDKP_Channel)
        SimpleTimingLib_Schedule(xSecondsLater + 4, SendChatMessage, auctionProgress:format(item, 1), SimpleGDKP_Channel)
    end
end

do
    local noBids = prefix.."No one wants to have %s :("
    local wonItemFor = prefix.."%s won %s for %d00 G."
    local highestBidders = prefix.."%d. %s bid %d00 G"

    local function sortBids(v1, v2)
        if v1.bid ~= v2.bid then
            return v1.bid > v2.bid
        else
            return v1.time < v2.time
        end
    end
    
    function endAuction()
        table.sort(bids, sortBids)
        if #bids == 0 then
            SendChatMessage(noBids:format(currentItem), SimpleGDKP_Channel)
        else
            SendChatMessage(wonItemFor:format(bids[1].name, currentItem, bids[1].bid), SimpleGDKP_Channel)
            for i = 1, math.min(#bids, 5) do -- print the 5 highest bidders, 'cause I once looted 4 dying curse in one single NAXX.
                SendChatMessage(highestBidders:format(i, bids[i].name, bids[i].bid), SimpleGDKP_Channel)
            end
        end
        currentItem = nil -- set currentItem to nil as there is no longer an ongoing auction
        table.wipe(bids)
    end
end

-- Placing Bids

do
    local oldBidDetected = prefix.."Your old bid was %d00 G, your new bid is %d00 G."
    local bidPlaced = prefix.."Your bid of %d00 G has been placed!"
    local lowBid = prefix.."The minimum bid is %d00 G."

    local exclamationCommandStart = "auction" -- Chinese localization改成拍卖, !auction <item> or !拍卖 <item>
    local exclamationCommandStop = "cancel" -- Chinese localization改成停拍

    function onEvent(self, event, msg, sender)
        if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") and currentItem and tonumber(msg) then -- lua_Number lua_tonumber (lua_State *L, int index); Converts the Lua value at the given acceptable index to the C type lua_Number. The Lua value must be a number or a string convertible to a number; otherwise, lua_tonumber returns 0. (nil)
            local bid = tonumber(msg)
            local time = GetTime()

            SimpleTimingLib_Unschedule(SendChatMessage)
            SimpleTimingLib_Unschedule(endAuction)
            countdown(currentItem, SimpleGDKP_IdleTime - 5)
            SimpleTimingLib_Schedule(SimpleGDKP_IdleTime, endAuction)

            if bid < SimpleGDKP_MinBid then
                SendChatMessage(lowBid:format(SimpleGDKP_MinBid), "Whisper", nil, sender)
                return
            end
            for i, v in ipairs(bids) do -- check if that player has already bid
                if sender == v.name then
                    SendChatMessage(oldBidDetected:format(v.bid, bid), "WHISPER", nil, sender)
                    v.bid = bid
                    v.time = time
                    return
                end
            end
            -- he hasn't bid yet, so create a new entry in bids
            table.insert(bids, {bid = bid, time = time, name = sender})
            SendChatMessage(bidPlaced:format(bid), "WHISPER", nil, sender)
        elseif SimpleGDKP_ACL[sender] then -- Remote Control
            -- not a raid or a raid that is not a bid, and the sender has the permission to send commands
            local cmd, arg = msg:match("^!(%w+)%s*(.*)")
            if cmd and cmd:lower() == exclamationCommandStart and arg then
                startAuction(arg, sender)
            elseif cmd and cmd:lower() == exclamationCommandStop then
                cancelAuction(sender)
            end
        end
    end
end

local frame = CreateFrame("Frame")
-- frame:RegisterEvent("CHAT_MSG_SAY")
frame:RegisterEvent("CHAT_MSG_RAID")
frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
-- frame:RegisterEvent("CHAT_MSG_PARTY")
-- frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
-- frame:RegisterEvent("CHAT_MSG_YELL")
frame:SetScript("OnEvent", onEvent)

-- Creating Slash Commands
SLASH_SimpleGDKP1 = "/simplegdkp"
SLASH_SimpleGDKP2 = "/sgdkp"
SLASH_SimpleGDKP3 = "/sg"

do
    local setChannel = "Channel is now \"%s\""
    local setTime = "Time is now %s"
    local setMinBid = "Lowest bid is now %s"
    local addedToACL = "Added %s player(s) to the ACL"
    local removedFromACL = "Removed %s player(s) from the ACL"
    local currChannel = "Channel is currently set to \"%s\""
    local currTime = "Time is currently set to %s"
    local currMinBid = "Lowest bid is currently set to %s"
    local ACL = "Access Control List:"

    local function addToACL(...) -- adds multiple players to the ACL
        for i = 1, select("#", ...) do -- iterate over the vararg
            SimpleGDKP_ACL[select(i, ...)] = true
        end
        print(addedToACL:format(select("#", ...))) -- print an info message
        print(...)
    end

    local function removeFromACL(...) -- remove multiple players from the ACL
        for i = 1, select("#", ...) do -- iterate over the vararg
            SimpleGDKP_ACL[select(i, ...)] = nil
        end
        print(removedFromACL:format(select("#", ...))) -- print an info message
    end

    SlashCmdList["SimpleGDKP"] = function(msg)
        local cmd, arg = string.split(" ", msg) -- split the string
        cmd = cmd:lower() -- the command should not be case-sensative
        if cmd == "start" and arg then -- /sgdkp start item
            startAuction(msg:match("^start%s+(.+)")) -- extract the item link (shift + click)
        elseif cmd == "stop" then -- /sgdkp stop
            cancelAuction()
        elseif cmd == "channel" then -- /sgdkp channel arg
            if arg then -- a new channel was provided
                SimpleGDKP_Channel = arg:upper() -- set it to arg
                print(setChannel:format(SimpleGDKP_Channel))
            else -- no channel was provided
                print(currChannel:format(SimpleGDKP_Channel)) -- print the current one
            end
        elseif cmd == "time" then -- /sgdkp time arg
            if arg and tonumber(arg) then -- a new time was provided and it's a number
                SimpleGDKP_IdleTime = arg -- set it to arg
                print(setTime:format(SimpleGDKP_IdleTime))
            else -- no time was provided or arg is not a number
                print(currTime:format(SimpleGDKP_IdleTime)) -- print the current one
            end
        elseif cmd == "minbid" then -- /sgdkp minbid arg
            if arg and tonumber(arg) then -- a new minimum bid was provided and it's a number
                SimpleGDKP_MinBid = arg -- set it to arg
                print(setMinBid:format(SimpleGDKP_MinBid))
            else -- no minbid was provided or arg is not a number
                print(currMinBid:format(SimpleGDKP_MinBid)) -- print error message
            end
        elseif cmd == "acl" then -- /sgdkp acl add/remove player1, player2, ...
            if not arg then
                print(ACL) -- output header
                for k, v in pairs(SimpleGDKP_ACL) do -- loop over the ACL
                    print(k) -- print all entries
                end
            elseif arg:lower() == "add" then -- /sgdkp acl add player1, player2, ...
                -- split the string and pass all players to our helper funciton
                addToACL(select(3, string.split(" ", msg)))
            elseif arg:lower() == "remove" then -- /sgdkp acl remove player1, player2, ...
                removeFromACL(select(3, string.split(" ", msg))) -- split & remove
            end
        end
    end
end

-- Canceling Auctions
do 
    local cancelled = "Auction cancelled by %s"
    function cancelAuction(sender)
        currentItem = nil
        table.wipe(bids)
        SimpleTimingLib_Unschedule(SendChatMessage)
        SimpleTimingLib_Unschedule(endAuction)
        SendChatMessage(cancelled:format(sender or UnitName("player")), SimpleGDKP_Channel)
    end
end

-- Hiding Chat Messages
do 
    local filterChannel = "LookingForGroup"
    local filterKeywords = {}

    local function filterIncoming(self, event, ...)
        local msg = ... -- get the message from the vararg
        -- return true if there is an ongoing auction and the whisper is a followed by all event handler arguments
        return currentItem and tonumber(msg), ...
    end

    local function filterOutgoing(self, event, ...)
        local msg = ... -- extract the message
        return msg:sub(0, prefix:len()) == prefix, ...
    end

    -- ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterIncoming)
    -- ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filterIncoming)
    -- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterOutgoing) -- 发出去的私聊

    local function chatFilter(self, event, ...)
        local msg, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName= ...
        msg = msg:lower()
        if channelBaseName == filterChannel and #filterKeywords ~= 0 then
            for k, v in ipairs(filterKeywords) do
                if string.find(msg, v:lower()) then
                    return false
                end
            end
            return true -- filter it
        else
            return false
        end
    end

    local function addToFilter(...)
        print(select("#", ...), ...)
        -- if #arg == 0 then
        --     filterKeywords = {}
        -- else
            for i = 1, select("#", ...) do -- /script print(select("#", string.split(" ", "aa bb cc"))) returns 3
                filterKeywords[i] = select(i, ...)
            end
            for k, v in ipairs(filterKeywords) do
                print(v)
            end
            ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", chatFilter) -- 让chatframe监听message
        -- end
    end

    SLASH_ChatFilter1 = "/ChatFilter"
    SLASH_ChatFilter2 = "/cf"
    SlashCmdList["ChatFilter"] = function(arg) -- arg includes no slash command
        -- /script print(select(3, string.split(" ", "a ab abb abbb bb")))
        -- 上面命令返回abb abbb bb，split函数并不是lua原生的，是wow自个实现的，同理如果select 4就返回abbb bb，奇怪的切割
        -- string.split(" ", "a ab abb abbb bb")返回的实际上还是"a ab abb abbb bb"这个string，只不过能用select任意选择切割段落了
        print(select("#", arg), arg)
        addToFilter(select(1, string.split(" ", arg)))
        
        -- 原来这样就不行，select完只剩第一个空格前的参数，为啥啊？select原理啊没搞懂
        -- print(select("#", arg), arg)
        -- arg = select(1, string.split(" ", arg))
        -- print(select("#", arg), arg)
        -- if #arg == 0 then
        --     filterKeywords = {}
        -- else
        --     for i = 1, select("#", arg) do -- /script print(select("#", string.split(" ", "aa bb cc"))) returns 3
        --         filterKeywords[i] = select(i, arg)
        --     end
        --     for k, v in ipairs(filterKeywords) do
        --         print(v)
        --     end
        --     ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", chatFilter) -- 让chatframe监听message
        -- end
    end
end