-- Lua supports this representation by providing a.name as syntactic sugar for a["name"], a.name is the same as a["name"]
local tasks = {}

function SimpleTimingLib_Schedule(time, func, ...) -- time秒后对...参数执行fun函数
    local t = {...}
    t.func = func
    t.time = GetTime() + time -- The API function GetTime() returns the current system uptime with millisecond precision. Adding time to this value gives us the moment in which the task should be executed.
    -- for k,v in pairs(t) do -- ipairs for loop, 查看table里都存了什么
        -- print(k, v)
    -- end
    table.insert(tasks, t)
end

local function onUpdate()
    for i = #tasks, 1, -1 do -- The length operator is denoted by the unary operator #.
        local val = tasks[i]
        if val and val.time <= GetTime() then -- val is not nil
            table.remove(tasks, i)
            val.func(unpack(val))
        end
    end -- numeric for loop
end

local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", onUpdate) -- The OnUpdate script handler is always executed before the game renders the user interface. This means that if your game runs at 25 frames per second, this script handler will be executed 25 times per second.

-- /script SimpleTimingLib_Schedule(1, print, 1, nil, 202171)
-- 1 1
-- 3 202171
-- func function: 0x12f501260
-- time 434982.822
-- 1

-- /script SimpleTimingLib_Schedule(1, print, 3, 2, 1)
-- 1 3
-- 2 2
-- 3 1
-- func function: 0x13c293ad0
-- time 435549.199
-- 3 2 1
-- 可以看出lua的table是1-index的

function SimpleTimingLib_Unschedule(func, ...) -- cancel specific task
    for i = #tasks, 1, -1 do -- 是<=或>=，包含区间边界的
        local val = tasks[i]
        if val.func == func then
            local matches = true
            for i = 1, select("#", ...) do
                if select(i, ...) ~=val[i] then
                    matches = false
                    break
                end
            end
            if matches then
                table.remove(tasks, i)
            end
        end
    end
end

-- SimpleTimingLib_Schedule(1, print, "Foo", 1, 2, 3)
-- SimpleTimingLib_Schedule(1, print, "Foo", 4, 5, 6)
-- SimpleTimingLib_Schedule(1, print, "Bar", 7, 8, 9)

-- SimpleTimingLib_Unschedule(print, "Foo", 1, 2, 3)
-- SimpleTimingLib_Unschedule(print)

-- 2 methods to restrict the frequency that onUpdate is called are skipped here