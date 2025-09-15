local addonName, addon = ...

local DebounceTimers = {}

local function AddIconDetail(isTrinket, itemID, playerSpecID, specID, spellID, tableIconDetails)
    isTrinket = isTrinket or false
    itemID = itemID or -1
    playerSpecID = playerSpecID or -1
    specID = specID or -1
    spellID = spellID or -1

    if itemID <= 0 and spellID <= 0 then
        return nil
    end

    local iconDetail = {}
    iconDetail.isTrinket = isTrinket
    iconDetail.itemID = itemID
    iconDetail.playerSpecID = playerSpecID
    iconDetail.specID = specID
    iconDetail.spellID = spellID

    table.insert(tableIconDetails, iconDetail)

    return nil
end

local function GetSlotInformation(actionText, itemID, macroBody, macroName, spellID)
    local result = {}

    result.actionText = actionText or ""
    result.itemID = itemID or -1
    result.macroBody = macroBody or ""
    result.macroName = macroName or ""
    result.spellID = spellID or -1

    result.actionText = result.actionText:lower():gsub("\r\n", "\n"):gsub("\r", "\n")
    result.macroBody = result.macroBody:lower():gsub("\r\n", "\n"):gsub("\r", "\n")
    result.macroName = result.macroName:lower():gsub("\r\n", "\n"):gsub("\r", "\n")

    if result.itemID > 0 then
        local item = Item:CreateFromItemID(result.itemID)
        item:ContinueOnItemLoad(function()
            result.name = item:GetItemName()
        end)
    elseif result.spellID > 0 then
        local spellInfo = C_Spell.GetSpellInfo(result.spellID)
        if spellInfo then
            result.name = spellInfo.name
        else
            local overrideSpellID = C_Spell.GetOverrideSpell(result.spellID) or result.spellID
            if overrideSpellID and overrideSpellID ~= result.spellID then
                spellInfo = C_Spell.GetSpellInfo(overrideSpellID)
                if spellInfo then
                    result.overrideSpellID = overrideSpellID
                    result.name = spellInfo.name
                end
            end
        end
    end

    result.name = result.name or ""
    result.name = result.name:lower():gsub("\r\n", "\n"):gsub("\r", "\n")
    result.overrideSpellID = result.overrideSpellID or -1

    return result
end

local function ProcessSpell(playerSpecID, spellBank, specID, spellIndex, tableIconDetails)
    local itemInfo = C_SpellBook.GetSpellBookItemInfo(spellIndex, spellBank)
    if not itemInfo then
        return nil
    end

    if itemInfo.itemType == Enum.SpellBookItemType.Spell or itemInfo.itemType == Enum.SpellBookItemType.PetAction then
        if itemInfo.isOffSpec then
            return nil
        end

        if itemInfo.isPassive then
            local baseChargeInfo = C_Spell.GetSpellCharges(itemInfo.spellID)
            if baseChargeInfo then
                return AddIconDetail(false, -1, playerSpecID, specID, itemInfo.spellID, tableIconDetails)
            else
                local cooldownMS, gcdMS = GetSpellBaseCooldown(itemInfo.spellID)
                if cooldownMS and cooldownMS > 0 then
                    return AddIconDetail(false, -1, playerSpecID, specID, itemInfo.spellID, tableIconDetails)
                end
            end

            return nil
        end

        return AddIconDetail(false, -1, playerSpecID, specID, itemInfo.spellID, tableIconDetails)
    end

    if itemInfo.itemType == Enum.SpellBookItemType.Flyout then
        local flyoutName, flyoutDescription, flyoutSlots, flyoutKnown = GetFlyoutInfo(itemInfo.actionID)
        if flyoutKnown then
            for slot = 1, flyoutSlots do
                local slotSpellID, slotOverrideSpellID, slotIsKnown, slotSpellName, slotSlotSpecID = GetFlyoutSlotInfo(
                    itemInfo.actionID, slot)
                if slotIsKnown and not C_Spell.IsSpellPassive(slotSpellID) then
                    AddIconDetail(false, -1, playerSpecID, specID, slotSpellID, tableIconDetails)
                end
            end
        end
    end

    return nil
end

local function SaveFramePosition(name, parentFrame)
    if name == addon.categoryIgnored then
        return nil
    end

    if name == addon.categoryUnknown then
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

function addon:AddTooltipID(id, label, tooltip)
    if not id or id == 0 then
        return
    end

    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName() .. "TextLeft" .. i]
        if line and line:GetText() and line:GetText():find(label) then
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
    if DebounceTimers[key] then
        DebounceTimers[key]:Cancel()
    end

    DebounceTimers[key] = C_Timer.NewTimer(delay, function()
        func()
        DebounceTimers[key] = nil
    end)
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

function addon:GetFrame(name)
    if name == addon.categoryIgnored then
        return nil
    end

    local newFrame = CreateFrame("Frame", name .. "Parent", UIParent)
    if name ~= addon.categoryUnknown then
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
                SaveFramePosition(name, frame)
            end)
        end)
    end

    return newFrame
end

function addon:GetIconDetails()
    local playerSpecID = addon:GetPlayerSpecID()
    if not playerSpecID then
        return nil
    end

    local numPetSpells, petNameToken = C_SpellBook.HasPetSpells()
    local tableIconDetails = {}

    if numPetSpells and numPetSpells > 0 then
        for i = 1, numPetSpells do
            ProcessSpell(playerSpecID, Enum.SpellBookSpellBank.Pet, 0, i, tableIconDetails)
        end
    end

    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() + 1 do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

        if lineInfo then
            if lineInfo.name == "General" then
                for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                    ProcessSpell(playerSpecID, Enum.SpellBookSpellBank.Player, 0, j, tableIconDetails)
                end
            else
                if lineInfo.specID then
                    if lineInfo.specID == playerSpecID then
                        for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                            ProcessSpell(playerSpecID, Enum.SpellBookSpellBank.Player, playerSpecID, j, tableIconDetails)
                        end
                    end
                else
                    for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                        ProcessSpell(playerSpecID, Enum.SpellBookSpellBank.Player, playerSpecID, j, tableIconDetails)
                    end
                end
            end
        end
    end

    local forcedSpells = SettingsDB.forcedSpells[0]
    if forcedSpells and next(forcedSpells) ~= nil then
        for i = 1, #forcedSpells do
            AddIconDetail(false, -1, playerSpecID, 0, forcedSpells[i], tableIconDetails)
        end
    end

    forcedSpells = SettingsDB.forcedSpells[playerSpecID]
    if forcedSpells and next(forcedSpells) ~= nil then
        for i = 1, #forcedSpells do
            AddIconDetail(false, -1, playerSpecID, 0, forcedSpells[i], tableIconDetails)
        end
    end

    for i = 1, #SettingsDB.validItems do
        AddIconDetail(false, SettingsDB.validItems[i], playerSpecID, 0, -1, tableIconDetails)
    end

    AddIconDetail(true, GetInventoryItemID("player", 13), playerSpecID, 0, -1, tableIconDetails)
    AddIconDetail(true, GetInventoryItemID("player", 14), playerSpecID, 0, -1, tableIconDetails)

    return tableIconDetails
end

function addon:GetKeyBind(frame, slotDetails)
    local itemID = frame.itemID or -1
    local itemName = frame.itemName or ""
    local spellID = frame.spellID or -1
    local spellName = frame.spellName or ""

    itemName = itemName:lower():gsub("\r\n", "\n"):gsub("\r", "\n")
    spellName = spellName:lower():gsub("\r\n", "\n"):gsub("\r", "\n")

    for slot, slotInfo in pairs(slotDetails) do
        local wasMatched = false

        if itemID > 0 then
            if slotInfo.itemID == itemID then
                wasMatched = true
            elseif slotInfo.macroBody:find("/use item:" .. itemID, 1, true) then
                wasMatched = true
            elseif slotInfo.macroBody:find("/cast item:" .. itemID, 1, true) then
                wasMatched = true
            end
        end

        if spellID > 0 then
            if slotInfo.spellID == spellID then
                wasMatched = true
            elseif slotInfo.overrideSpellID == spellID then
                wasMatched = true
            end
        end

        if itemName ~= "" then
            if slotInfo.name ~= "" then
                if slotInfo.name == itemName then
                    wasMatched = true
                end

                if slotInfo.name:find(itemName, 1, true) then
                    wasMatched = true
                end
            end

            if slotInfo.actionText ~= "" then
                if slotInfo.actionText:find(itemName, 1, true) then
                    wasMatched = true
                end
            end

            if slotInfo.macroBody ~= "" then
                if slotInfo.macroBody:find(itemName, 1, true) then
                    wasMatched = true
                end
            end

            if slotInfo.macroName ~= "" then
                if slotInfo.macroName:find(itemName, 1, true) then
                    wasMatched = true
                end
            end
        end

        if spellName ~= "" then
            if slotInfo.name ~= "" then
                if slotInfo.name == spellName then
                    wasMatched = true
                end

                if slotInfo.name:find(spellName, 1, true) then
                    wasMatched = true
                end
            end

            if slotInfo.actionText ~= "" then
                if slotInfo.actionText:find(spellName, 1, true) then
                    wasMatched = true
                end
            end

            if slotInfo.macroBody ~= "" then
                if slotInfo.macroBody:find(spellName, 1, true) then
                    wasMatched = true
                end
            end

            if slotInfo.macroName ~= "" then
                if slotInfo.macroName:find(spellName, 1, true) then
                    wasMatched = true
                end
            end
        end

        if wasMatched then
            local binding

            local actionButtonName = addon.actionButtons[slot]
            if actionButtonName and actionButtonName ~= "" then
                binding = GetBindingKey(actionButtonName)
                if binding and binding ~= "" then
                    return binding
                end
            end

            if _G["ElvUI"] and _G["ElvUI_Bar1Button1"] then
                local barIndex = math.floor((slot - 1) / 12) + 1
                local buttonIndex = ((slot - 1) % 12) + 1
                local button = _G["ElvUI_Bar" .. barIndex .. "Button" .. buttonIndex]
                if button then
                    actionButtonName = button.bindstring or button.keyBoundTarget
                    if not actionButtonName then
                        actionButtonName = "CLICK " .. button:GetName() .. ":LeftButton"
                    end

                    binding = GetBindingKey(actionButtonName)
                    if binding and binding ~= "" then
                        return binding
                    end
                end
            end
        end
    end

    return ""
end

function addon:GetPlayerSpecID()
    local currentSpec = GetSpecialization()
    if not currentSpec then
        return -1
    end

    local playerSpecID = GetSpecializationInfo(currentSpec)
    if not playerSpecID then
        return -1
    end

    return playerSpecID
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

function addon:GetSlotDetails()
    local numGeneral, numCharacter = GetNumMacros()
    local results = {}

    for slot = 1, 180 do
        local actionType, actionID, actionSubType = GetActionInfo(slot)
        local actionText = GetActionText(slot)

        if actionType then
            local wasHandled = false
            local slotInfo

            if not actionSubType then
                actionSubType = ""
            end

            if actionType == "companion" then
                if actionSubType == "MOUNT" then
                    slotInfo = GetSlotInformation(actionText, -1, "", "", actionID)
                    wasHandled = true
                end
            elseif actionType == "flyout" then
                if actionSubType == "" then
                    wasHandled = true
                end
            elseif actionType == "item" then
                if actionSubType == "" then
                    slotInfo = GetSlotInformation(actionText, actionID, "", "", -1)
                    wasHandled = true
                end
            elseif actionType == "macro" then
                local macroName, macroIcon, macroBody = GetMacroInfo(actionText)

                if actionSubType == "" then
                    slotInfo = GetSlotInformation(actionText, -1, macroBody, macroName, -1)
                    wasHandled = true
                elseif actionSubType == "item" then
                    slotInfo = GetSlotInformation(actionText, -1, macroBody, macroName, -1)
                    wasHandled = true
                elseif actionSubType == "MOUNT" then
                    slotInfo = GetSlotInformation(actionText, -1, macroBody, macroName, -1)
                    wasHandled = true
                elseif actionSubType == "spell" then
                    slotInfo = GetSlotInformation(actionText, -1, macroBody, macroName, actionID)
                    wasHandled = true
                else
                    print("actionSubType:", actionSubType, ", actionID:", actionID, ", actionText:", actionText, ", macroName:", macroName, ", macroBody:", macroBody)
                end
            elseif actionType == "spell" then
                if actionSubType == "assistedcombat" then
                    slotInfo = GetSlotInformation(actionText, -1, "", "", actionID)
                    wasHandled = true
                elseif actionSubType == "pet" then
                    slotInfo = GetSlotInformation(actionText, -1, "", "", actionID)
                    wasHandled = true
                elseif actionSubType == "spell" then
                    slotInfo = GetSlotInformation(actionText, -1, "", "", actionID)
                    wasHandled = true
                end
            elseif actionType == "summonmount" then
                if actionSubType == "" then
                    local mountID = tonumber(actionID) or -1
                    if mountID > 0 then
                        local _, spellID = C_MountJournal.GetMountInfoByID(mountID)

                        slotInfo = GetSlotInformation(actionText, -1, "", "", spellID)
                        wasHandled = true
                    end
                end
            end

            if wasHandled then
                if slotInfo then
                    local actionButtonName = addon.actionButtons[slot]
                    if actionButtonName and actionButtonName ~= "" then
                        local binding = GetBindingKey(actionButtonName)
                        if binding and binding ~= "" then
                            slotInfo.binding = binding
                        end
                    end

                    if not slotInfo.binding or slotInfo.binding == "" then
                        if _G["ElvUI"] and _G["ElvUI_Bar1Button1"] then
                            local barIndex = math.floor((slot - 1) / 12) + 1
                            local buttonIndex = ((slot - 1) % 12) + 1
                            local button = _G["ElvUI_Bar" .. barIndex .. "Button" .. buttonIndex]
                            if button then
                                actionButtonName = button.bindstring or button.keyBoundTarget
                                if not actionButtonName then
                                    actionButtonName = "CLICK " .. button:GetName() .. ":LeftButton"
                                end

                                local binding = GetBindingKey(actionButtonName)
                                if binding and binding ~= "" then
                                    slotInfo.binding = binding
                                end
                            end
                        end
                    end

                    if not slotInfo.binding or slotInfo.binding == "" then
                        if _G["Bartender4"] then
                            actionButtonName = "CLICK BT4Button" .. slot .. ":Keybind"
                            local binding = GetBindingKey(actionButtonName)
                            if binding and binding ~= "" then
                                slotInfo.binding = binding
                            end
                        end
                    end

                    results[slot] = slotInfo
                end
            else
                print("GetSlotDetails. slot:", slot, ", actionType:", actionType, ", actionSubType:", actionSubType, ", actionID:", actionID)
            end
        end
    end

    return results
end

function addon:GetValidCategories()
    local foundIgnored = false
    local foundTrinket = false
    local foundUnknown = false
    local results = {}

    for i = 1, #SettingsDB.validCategories do
        local name = SettingsDB.validCategories[i]
        if name == addon.categoryIgnored then
            foundIgnored = true
        elseif name == addon.categoryTrinket then
            foundTrinket = true
        elseif name == addon.categoryUnknown then
            foundUnknown = true
        end

        table.insert(results, name)
    end

    if not foundIgnored then
        table.insert(results, addon.categoryIgnored)
    end
    if not foundTrinket then
        SettingsDB[addon.categoryTrinket] = addon:GetSettingsTable(addon.categoryTrinket)
        table.insert(results, addon.categoryTrinket)
    end
    if not foundUnknown then
        table.insert(results, addon.categoryUnknown)
    end

    return results
end

function addon:GetValueNumber(value)
    value = strtrim(value)
    if value == "" then
        return 0
    else
        return tonumber(value)
    end
end

function addon:FrameRestore(name, parentFrame)
    if name == addon.categoryIgnored then
        return
    end

    if name == addon.categoryUnknown then
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

function addon:ReplaceBindings(binding)
    binding = binding:gsub("ALT%-", "A")
    binding = binding:gsub("%BUTTON", "M")
    binding = binding:gsub("%MOUSEWHEELDOWN", "WD")
    binding = binding:gsub("%MOUSEWHEELUP", "WU")
    binding = binding:gsub("CTRL%-", "C")
    binding = binding:gsub("NUMPAD", "N")
    binding = binding:gsub("SHIFT%-", "S")

    return binding
end
