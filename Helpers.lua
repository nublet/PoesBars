local addonName, addon = ...
local DebounceTimers = {}

local function GetKeyBinding(actionButtonName, itemID, name, slotID, spellID)
    local actionType, actionID, subType = GetActionInfo(slotID)

    if actionType == "item" and actionID == itemID then
        return GetBindingKey(actionButtonName)
    elseif actionType == "spell" and actionID == spellID then
        return GetBindingKey(actionButtonName)
    elseif actionType == "macro" then
        if name then
            local actionText = GetActionText(slotID)
            if actionText then
                local body = GetMacroBody(actionText)

                if body then
                    body = body:lower():gsub("%s+", "")

                    if body:find(name, 1, true) then
                        return GetBindingKey(actionButtonName)
                    end

                    if body:find("/use item:" .. itemID, 1, true) then
                        return GetBindingKey(actionButtonName)
                    end

                    if body:find("/cast item:" .. itemID, 1, true) then
                        return GetBindingKey(actionButtonName)
                    end
                end
            end
        end
    end

    return nil
end

local function SaveFramePosition(name, parentFrame)
    if name == "Ignored" then
        return nil
    end

    if name == "Unknown" then
        return nil
    end

    local parentBottom = parentFrame:GetBottom()
    local parentCenterX, parentCenterY = parentFrame:GetCenter()
    local parentLeft = parentFrame:GetLeft()
    local parentRight = parentFrame:GetRight()
    local parentTop = parentFrame:GetTop()
    local screenCenterX, screenCenterY = UIParent:GetCenter()
    local settingTable = SettingsDB[name] or {}

    if not settingTable.anchor or settingTable.anchor == "" then
        settingTable.anchor = "CENTER"
    end

    if settingTable.anchor == "TOPLEFT" then
        settingTable.x = parentLeft
        settingTable.y = parentTop
    elseif settingTable.anchor == "TOPRIGHT" then
        settingTable.x = parentRight
        settingTable.y = parentTop
    elseif settingTable.anchor == "TOP" then
        settingTable.x = parentCenterX
        settingTable.y = parentTop
    elseif settingTable.anchor == "BOTTOMLEFT" then
        settingTable.x = parentLeft
        settingTable.y = parentBottom
    elseif settingTable.anchor == "BOTTOMRIGHT" then
        settingTable.x = parentRight
        settingTable.y = parentBottom
    elseif settingTable.anchor == "BOTTOM" then
        settingTable.x = parentCenterX
        settingTable.y = parentBottom
    elseif settingTable.anchor == "LEFT" then
        settingTable.x = parentLeft
        settingTable.y = parentCenterY
    elseif settingTable.anchor == "RIGHT" then
        settingTable.x = parentRight
        settingTable.y = parentCenterY
    else
        settingTable.x = parentCenterX
        settingTable.y = parentCenterY
    end

    settingTable.x = settingTable.x - screenCenterX
    settingTable.y = settingTable.y - screenCenterY

    SettingsDB[name] = settingTable
end

function addon:Debounce(key, delay, func)
    if DebounceTimers[key] then
        DebounceTimers[key]:Cancel()
    end

    DebounceTimers[key] = C_Timer.NewTimer(delay, function()
        func()
        DebounceTimers[key] = nil
    end)
end

function addon:FrameCreate(name)
    if name == "Ignored" then
        return nil
    end

    local newFrame = CreateFrame("Frame", name .. "Parent", UIParent)
    if name ~= "Unknown" then
        newFrame:EnableMouse(true)
        newFrame:RegisterForDrag("LeftButton")
        newFrame:SetClampedToScreen(true)
        newFrame:SetDontSavePosition(true)
        newFrame:SetMovable(true)
        newFrame:SetSize(1, 1)

        newFrame:SetScript("OnDragStart", function(frame)
            if IsControlKeyDown() and not SettingsDB.isLocked then
                frame:StartMoving()
            end
        end)

        newFrame:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()

            C_Timer.After(1, function()
                SaveFramePosition(name, frame)
            end)
        end)
    end

    return newFrame
end

function addon:FrameRestore(name, parentFrame)
    if name == "Ignored" then
        return
    end

    if name == "Unknown" then
        parentFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    else
        local settingsTable = SettingsDB[name] or {}
        local anchor = settingsTable.anchor or "CENTER"
        local x = settingsTable.x or 0
        local y = settingsTable.y or 0

        parentFrame:ClearAllPoints()
        if anchor and anchor ~= "" then
            parentFrame:SetPoint(anchor, UIParent, "CENTER", x, y)
        else
            parentFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end
end

function addon:GetKeyBind(itemID, name, spellID)
    if _G["Bartender4"] then
        for i = 1, 180 do
            local actionButtonName = "CLICK BT4Button" .. i .. ":Keybind"

            local bindingKey = GetKeyBinding(actionButtonName, itemID, name, i, spellID)
            if bindingKey then
                return bindingKey
            end
        end
    elseif _G["ElvUI"] and _G["ElvUI_Bar1Button1"] then
        for i = 1, 15 do
            for b = 1, 12 do
                local btn = _G["ElvUI_Bar" .. i .. "Button" .. b]

                if btn then
                    local binding = btn.bindstring or btn.keyBoundTarget or
                        ("CLICK " .. btn:GetName() .. ":LeftButton")
                    if i > 6 then
                        local bar = _G["ElvUI_Bar" .. i]

                        if not bar or not bar.db.enabled then
                            binding = "ACTIONBUTTON" .. b
                        end
                    end

                    local action, aType = btn._state_action, "spell"
                    if action and type(action) == "number" then
                        local slot = ((i - 1) * 12) + b
                        local bindingKey = GetKeyBinding(binding, itemID, name, slot, spellID)
                        if bindingKey then
                            return bindingKey
                        end
                    end
                end
            end
        end
    end

    for i = 1, 12 do
        local bindingKey = GetKeyBinding("ACTIONBUTTON" .. i, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    for i = 13, 24 do
        local bindingKey = GetKeyBinding("ACTIONBUTTON" .. i - 12, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    for i = 25, 36 do
        local bindingKey = GetKeyBinding("MULTIACTIONBAR3BUTTON" .. i - 24, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    for i = 37, 48 do
        local bindingKey = GetKeyBinding("MULTIACTIONBAR4BUTTON" .. i - 36, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    for i = 49, 60 do
        local bindingKey = GetKeyBinding("MULTIACTIONBAR2BUTTON" .. i - 48, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    for i = 61, 72 do
        local bindingKey = GetKeyBinding("MULTIACTIONBAR1BUTTON" .. i - 60, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    for i = 72, 143 do
        local bindingKey = GetKeyBinding("ACTIONBUTTON" .. 1 + (i - 72) % 12, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    for i = 145, 156 do
        local bindingKey = GetKeyBinding("MULTIACTIONBAR5BUTTON" .. i - 144, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    for i = 157, 168 do
        local bindingKey = GetKeyBinding("MULTIACTIONBAR6BUTTON" .. i - 156, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    for i = 169, 180 do
        local bindingKey = GetKeyBinding("MULTIACTIONBAR7BUTTON" .. i - 168, itemID, name, i, spellID)
        if bindingKey then
            return bindingKey
        end
    end

    return ""
end
