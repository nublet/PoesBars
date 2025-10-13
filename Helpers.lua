local addonName, addon = ...

local debounceMaximum = 120 -- 2 Minutes
local debounceMinimum = 0.05
local debounceQueue = {}

local function SaveFramePosition(categoryName, parentFrame)
    if categoryName == addon.categoryIgnored then
        return nil
    end

    if categoryName == addon.categoryUnknown then
        return nil
    end

    local parentBottom = parentFrame:GetBottom()
    local parentCenterX, parentCenterY = parentFrame:GetCenter()
    local parentLeft = parentFrame:GetLeft()
    local parentRight = parentFrame:GetRight()
    local parentTop = parentFrame:GetTop()
    local screenCenterX, screenCenterY = UIParent:GetCenter()
    local settingTable = SettingsDB[categoryName] or {}

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

    SettingsDB[categoryName] = settingTable
end

function addon:AddTooltipID(id, label, tooltip)
    if not id or id == 0 then
        return
    end

    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName() .. "TextLeft" .. i]
        if line and line:GetText() and string.find(line:GetText(), label) then
            return
        end
    end

    tooltip:AddLine(string.format("|cff999999%s: %d", label, id))
    tooltip:Show()
end

function addon:ClearRadios(radioGroup)
    for i = 1, #radioGroup do
        radioGroup[i]:SetChecked(false)
    end
end

function addon:Debounce(key, delay, func)
    if InCombatLockdown() then
        return
    end

    delay = tonumber(delay) or 3
    delay = math.min(math.max(delay, debounceMinimum), debounceMaximum)

    local entry = debounceQueue[key]

    if entry and entry.timer then
        entry.timer.cancelled = true
    end

    entry = { cancelled = false }
    debounceQueue[key] = entry

    C_Timer.After(delay, function()
        if debounceQueue[key] == nil or entry.cancelled then
            return
        end

        debounceQueue[key] = nil

        func()
    end)
end

function addon:FrameRestore(categoryName, parentFrame)
    if categoryName == addon.categoryIgnored then
        return
    end

    if categoryName == addon.categoryUnknown then
        parentFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    else
        local settingsTable = SettingsDB[categoryName] or {}
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

function addon:GetControlButton(addToTable, label, parent, width, onClick)
    local result = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    result:SetScript("OnClick", onClick)
    result:SetSize(width, 20)
    result:SetText(label)

    if addToTable then
        table.insert(addon.settingsControls, result)
    end

    return result
end

function addon:GetControlCheckbox(addToTable, label, parent, onClick)
    local result = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    result:SetChecked(false)
    result:SetScript("OnClick", onClick)
    result.Text:SetText(label)

    if addToTable then
        table.insert(addon.settingsControls, result)
    end

    return result
end

function addon:GetControlDropdown(addToTable, parent, width)
    local result = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")

    UIDropDownMenu_SetWidth(result, width)

    if addToTable then
        table.insert(addon.settingsControls, result)
    end

    return result
end

function addon:GetControlInput(addToTable, parent, width, onEnterPressed)
    local result = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    result:SetAutoFocus(false)
    result:SetSize(width, 20)

    result:SetScript("OnEnterPressed", onEnterPressed)

    if addToTable then
        table.insert(addon.settingsControls, result)
    end

    return result
end

function addon:GetControlLabel(addToTable, parent, text, width)
    local result = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    result:SetJustifyH("LEFT")
    result:SetJustifyV("MIDDLE")
    result:SetSize(width, 20)
    result:SetText(text)

    if addToTable then
        table.insert(addon.settingsControls, result)
    end

    return result
end

function addon:GetControlRadioButton(addToTable, parent, radioGroup, text, onClick)
    local result = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    result:SetChecked(false)
    result:SetScript("OnClick", onClick)
    result.text:SetText(text)

    table.insert(radioGroup, result)

    if addToTable then
        table.insert(addon.settingsControls, result)
    end

    return result
end

function addon:GetFrame(categoryName)
    if categoryName == addon.categoryIgnored then
        return nil
    end

    local newFrame = CreateFrame("Frame", categoryName .. "Parent", UIParent)
    if categoryName ~= addon.categoryUnknown then
        newFrame:EnableKeyboard(false)
        newFrame:EnableMouse(true)
        newFrame:EnableMouseWheel(false)
        newFrame:RegisterForDrag("LeftButton")
        newFrame:SetClampedToScreen(true)
        newFrame:SetDontSavePosition(true)
        newFrame:SetFrameStrata("LOW")
        newFrame:SetHitRectInsets(0, 0, 0, 0)
        newFrame:SetMovable(true)
        newFrame:SetPropagateKeyboardInput(true)
        newFrame:SetSize(1, 1)
        newFrame:SetToplevel(false)

        newFrame:SetScript("OnDragStart", function(frame)
            if IsControlKeyDown() then
                frame:StartMoving()
            end
        end)

        newFrame:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()

            C_Timer.After(1, function()
                SaveFramePosition(categoryName, frame)
            end)
        end)
    end

    return newFrame
end

function addon:GetKnownSlots()
    local knownSlots = {}
    local numGeneral, numCharacter = GetNumMacros()

    for slot = 1, 180 do
        local actionType, actionID, actionSubType = GetActionInfo(slot)
        local actionText = GetActionText(slot)

        if actionType then
            local newItem

            if not actionSubType then
                actionSubType = ""
            end

            if actionType == "companion" then
                if actionSubType == "MOUNT" then
                    newItem = KnownSlot:Get(actionText, -1, "", "", actionID)
                end
            elseif actionType == "item" then
                if actionSubType == "" then
                    newItem = KnownSlot:Get(actionText, actionID, "", "", -1)
                end
            elseif actionType == "macro" then
                local macroName, macroIcon, macroBody = GetMacroInfo(actionText)

                if actionSubType == "" then
                    newItem = KnownSlot:Get(actionText, -1, macroBody, macroName, -1)
                elseif actionSubType == "item" then
                    newItem = KnownSlot:Get(actionText, -1, macroBody, macroName, -1)
                elseif actionSubType == "MOUNT" then
                    newItem = KnownSlot:Get(actionText, -1, macroBody, macroName, -1)
                elseif actionSubType == "spell" then
                    newItem = KnownSlot:Get(actionText, -1, macroBody, macroName, actionID)
                else
                    print("actionSubType:", actionSubType, ", actionID:", actionID, ", actionText:", actionText, ", macroName:", macroName, ", macroBody:", macroBody)
                end
            elseif actionType == "spell" then
                if actionSubType == "assistedcombat" then
                    newItem = KnownSlot:Get(actionText, -1, "", "", actionID)
                elseif actionSubType == "pet" then
                    newItem = KnownSlot:Get(actionText, -1, "", "", actionID)
                elseif actionSubType == "spell" then
                    newItem = KnownSlot:Get(actionText, -1, "", "", actionID)
                end
            elseif actionType == "summonmount" then
                if actionSubType == "" then
                    local mountID = tonumber(actionID) or -1
                    if mountID > 0 then
                        local _, spellID = C_MountJournal.GetMountInfoByID(mountID)

                        newItem = KnownSlot:Get(actionText, -1, "", "", spellID)
                    end
                end
            end

            if newItem then
                knownSlots[slot] = newItem
            else
                if actionType == "flyout" and actionSubType == "" then
                else
                    print("addon:GetKnownSlots. slot:", slot, ", actionType:", actionType, ", actionID:", actionID, ", actionSubType:", actionSubType, ", actionText:", actionText)
                end
            end
        end
    end

    return knownSlots
end

function addon:GetKnownSpells()
    local playerSpecID = addon:GetPlayerSpecID()
    if not playerSpecID then
        return nil
    end

    local knownSpells = {}

    local numPetSpells, petNameToken = C_SpellBook.HasPetSpells()
    if numPetSpells and numPetSpells > 0 then
        for i = 1, numPetSpells do
            KnownSpell:Process(playerSpecID, Enum.SpellBookSpellBank.Pet, 0, i, knownSpells)
        end
    end

    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() + 1 do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

        if lineInfo then
            if lineInfo.name == "General" then
                for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                    KnownSpell:Process(playerSpecID, Enum.SpellBookSpellBank.Player, 0, j, knownSpells)
                end
            else
                if lineInfo.specID then
                    if lineInfo.specID == playerSpecID then
                        for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                            KnownSpell:Process(playerSpecID, Enum.SpellBookSpellBank.Player, playerSpecID, j, knownSpells)
                        end
                    end
                else
                    for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                        KnownSpell:Process(playerSpecID, Enum.SpellBookSpellBank.Player, playerSpecID, j, knownSpells)
                    end
                end
            end
        end
    end

    local forcedSpells = SettingsDB.forcedSpells[0]
    if forcedSpells and next(forcedSpells) ~= nil then
        for i = 1, #forcedSpells do
            KnownSpell:Add(false, -1, playerSpecID, 0, forcedSpells[i], knownSpells)
        end
    end

    forcedSpells = SettingsDB.forcedSpells[playerSpecID]
    if forcedSpells and next(forcedSpells) ~= nil then
        for i = 1, #forcedSpells do
            KnownSpell:Add(false, -1, playerSpecID, 0, forcedSpells[i], knownSpells)
        end
    end

    for i = 1, #SettingsDB.validItems do
        KnownSpell:Add(false, SettingsDB.validItems[i], playerSpecID, 0, -1, knownSpells)
    end

    KnownSpell:Add(true, GetInventoryItemID("player", 13), playerSpecID, 0, -1, knownSpells)
    KnownSpell:Add(true, GetInventoryItemID("player", 14), playerSpecID, 0, -1, knownSpells)

    return knownSpells
end

function addon:GetNumberOrDefault(defaultValue, number)
    local valueNumber = addon:NormalizeNumber(number)

    if valueNumber < 0 then
        return defaultValue
    end

    return number
end

function addon:GetPlayerSpecID()
    local specializationIndex = C_SpecializationInfo.GetSpecialization()
    if not specializationIndex then
        return -1
    end

    local specID, name, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)
    if not specID then
        return -1
    end

    return specID
end

function addon:GetSettingsTable(category)
    local settingsTable = SettingsDB[category] or {}

    settingsTable.anchor = settingsTable.anchor or "CENTER"
    settingsTable.colorBasedOnState = settingsTable.colorBasedOnState or false
    settingsTable.displayWhen = settingsTable.displayWhen or "Always"
    settingsTable.glowWhenAuraActive = settingsTable.glowWhenAuraActive or false
    settingsTable.glowWhenOverridden = settingsTable.glowWhenOverridden or false
    settingsTable.iconSize = settingsTable.iconSize or 64
    settingsTable.iconSpacing = settingsTable.iconSpacing or 2
    settingsTable.isClickable = settingsTable.isClickable or false
    settingsTable.isVertical = settingsTable.isVertical or false
    settingsTable.showOnCooldown = settingsTable.showOnCooldown or false
    settingsTable.showWhenAvailable = settingsTable.showWhenAvailable or false
    settingsTable.wrapAfter = settingsTable.wrapAfter or 0
    settingsTable.x = settingsTable.x or 0
    settingsTable.y = settingsTable.y or 0

    settingsTable.x = math.floor(settingsTable.x + 0.5)
    settingsTable.y = math.floor(settingsTable.y + 0.5)

    return settingsTable
end

function addon:GetValidCategories()
    local foundIgnored = false
    local foundTrinket = false
    local foundUnknown = false
    local validCategories = {}

    for _, categoryName in ipairs(SettingsDB.validCategories) do
        if categoryName == addon.categoryIgnored then
            foundIgnored = true
        elseif categoryName == addon.categoryTrinket then
            foundTrinket = true
        elseif categoryName == addon.categoryUnknown then
            foundUnknown = true
        end

        table.insert(validCategories, categoryName)
    end

    if not foundIgnored then
        table.insert(validCategories, addon.categoryIgnored)
    end
    if not foundTrinket then
        SettingsDB[addon.categoryTrinket] = addon:GetSettingsTable(addon.categoryTrinket)
        table.insert(validCategories, addon.categoryTrinket)
    end
    if not foundUnknown then
        table.insert(validCategories, addon.categoryUnknown)
    end

    return validCategories
end

function addon:NormalizeNumber(number)
    local valueString = ""

    if number then
        valueString = strtrim(number)
    end

    if valueString == "" then
        return -1
    end

    local valueNumber = tonumber(number) or -1

    if valueNumber < 0 then
        return -1
    end

    return valueNumber
end

function addon:NormalizeText(text)
    if not text then
        return ""
    end

    if text == "" then
        return ""
    end

    return text:lower():gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\n", "")
end
