local MAX_MESSAGE_LENGTH = 128

local REPEAT_KEY_WAIT = 500
local REPEAT_KEY_DELAY = 50

local repeatTimer
local repeatStartTimer

local inputActive = false
local inputText = ""

local inputHistory = {}
local inputHistoryCurrent

local currentInputText

Input = {}

function Input.isActive()
    return inputActive
end

function Input.getText()
    return (inputActive and inputText or false)
end

function Input.getHistory()
    return inputHistory
end

-- function Input.getCurrentHistory()
--     if inputHistoryCurrent == nil then
--         return false
--     end
--     return inputHistoryCurrent
-- end

local function historyUp()
    if inputHistoryCurrent == nil then
        if #inputHistory == 0 then
            return false
        end
        inputHistoryCurrent = #inputHistory
        currentInputText = inputText
    elseif inputHistoryCurrent == 1 then
        return false
    else
        inputHistoryCurrent = inputHistoryCurrent - 1
    end
    inputText = inputHistory[inputHistoryCurrent]
    return true
end

local function historyDown()
    if inputHistoryCurrent == nil then
        return false
    end

    if inputHistoryCurrent == #inputHistory then
        inputHistoryCurrent = nil
        inputText = currentInputText
        currentInputText = nil
    else
        inputHistoryCurrent = inputHistoryCurrent + 1
        inputText = inputHistory[inputHistoryCurrent]
    end
    return true
end

local function erase()
    inputText = utf8.sub(inputText, 1, -2)
end

local firstCharSkipped = false -- Чтобы в чат не попадала кнопка бинда
local function insert(character)
    if not firstCharSkipped then
        firstCharSkipped = true
    else
        if #inputText < MAX_MESSAGE_LENGTH then -- Limit message length
            inputText = inputText .. character
        end
    end
end

function Input.open()
    if inputActive then
        return false
    end

    showCursor(true)
    guiSetInputMode("no_binds")

    inputActive = true

    addEventHandler("onClientCharacter", root, insert)

    return true
end

function Input.close()
    if not inputActive then
        return false
    end

    showCursor(false)
    guiSetInputMode("allow_binds")

    inputText = ""
    inputActive = false
    firstCharSkipped = false
    inputHistoryCurrent = nil
    currentInputText = nil

    removeEventHandler("onClientCharacter", root, insert)

    return true
end

local function saveToHistory(inputText)
    table.insert(inputHistory, inputText)
    for i, text in ipairs(inputHistory) do
        outputDebugString(text)
    end
end

local function send()
    if not inputActive then
        return false
    end

    -- Send only if text is not empty
    if inputText ~= "" then
        Chat.send(Chat.getTab(), inputText)
        saveToHistory(inputText)
    end
    Input.close()

    return true
end

local function handleKey(key, repeatKey)
	if not inputActive then
		return false
	end

	if key == "backspace" then
        erase()
	elseif key == "enter" then
        send()
    elseif key == "arrow_u" then
        historyUp()
    elseif key == "arrow_d" then
        historyDown()
	elseif key == "escape" then
        cancelEvent()
        Input.close()
    else
		return false
	end

	if repeatKey and getKeyState(key) then
		repeatTimer = Timer(handleKey, REPEAT_KEY_DELAY, 1, key, true)
	end

    return true
end

addEventHandler("onClientKey", root,
    function (key, pressed)
    	if not inputActive then
    		return
    	end
        -- If key released
    	if not pressed then
    		if isTimer(repeatStartTimer) then
    			repeatStartTimer:destroy()
    		end
            if isTimer(repeatTimer) then
                repeatTimer:destroy()
            end
    		return
    	end
    	handleKey(key, false)
        if key == "backspace" or key == "arrow_u" or key == "arrow_d" then
    	    repeatStartTimer = Timer(handleKey, REPEAT_KEY_WAIT, 1, key, true)
        end
    end
)
