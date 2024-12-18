local _, L = ...;
print(GetLocale())
print(L["Hello, World!"])

HelloWorld_Text = {}
local channel = "SAY"

SLASH_HELLO_WORLD_ADD1 = "/hwadd"
SLASH_HELLO_WORLD_ADD2 = "/helloworldadd" -- an alias
SlashCmdList["HELLO_WORLD_ADD"] = function(msg)
    local id, text = msg:match("(%S+)%s+(.+)")
    if id and text then
        HelloWorld_Text[id:lower()] = text
    else
        print("Usage: /hwadd <id> <text>")
    end
end

SLASH_HELLO_WORLD_SHOW1 = "/hwshow"
SLASH_HELLO_WORLD_SHOW2 = "/helloworldshow" -- an alias
SlashCmdList["HELLO_WORLD_SHOW"] = function(msg)
    local text = HelloWorld_Text[msg:lower()]
    if text then -- in case empty
        SendChatMessage(text, channel) -- you send a message in <channel> channel
    end
end