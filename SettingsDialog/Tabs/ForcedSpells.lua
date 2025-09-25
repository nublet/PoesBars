local addonName, addon = ...

local frameContainer
local frameScroll
local frameScrollChild
local yOffset = 0

local function CreateOptionLine(spellID)
    spellID = spellID or -1
    if spellID <= 0 then
        return
    end

    local frameSpell = CreateFrame("Frame", nil, frameScroll)
    frameSpell:EnableMouse(true)
    frameSpell:SetPoint("TOPLEFT", 10, yOffset)
    frameSpell:SetSize(addon.settingsIconSize, addon.settingsIconSize)
    frameSpell:SetScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spellID)
        GameTooltip:Show()
    end)
    frameSpell:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local textureSpell = frameSpell:CreateTexture(nil, "ARTWORK")
    textureSpell:SetAllPoints()

    local textSpellID = addon:GetControlLabel(false, frameScroll, "", 60)
    textSpellID:SetPoint("LEFT", frameSpell, "RIGHT", 10, 0)
    textSpellID:SetText(spellID)

    local textSpellName = addon:GetControlLabel(false, frameScroll, "", 150)
    textSpellName:SetPoint("LEFT", textSpellID, "RIGHT", 10, 0)

    local deleteButton = addon:GetControlButton(false, "Delete", frameScroll, 60, function(control)
        local playerSpecID = addon:GetPlayerSpecID()
        if not playerSpecID then
            return
        end

        local listsToCheck = { 0, playerSpecID }
        for _, specID in ipairs(listsToCheck) do
            local list = SettingsDB.forcedSpells[specID]
            if list then
                for i = #list, 1, -1 do
                    if list[i] == spellID then
                        table.remove(list, i)
                        break
                    end
                end
            end
        end

        addon:GetForcedSpellsData()
    end)
    deleteButton:SetPoint("LEFT", textSpellName, "RIGHT", 10, 0)

    local spellSpellInfo = C_Spell.GetSpellInfo(spellID)
    if spellSpellInfo then
        textSpellName:SetText(spellSpellInfo.name)
        textureSpell:SetTexture(spellSpellInfo.iconID)
    end

    yOffset = yOffset - addon.settingsIconSize - 10
end

function addon:GetForcedSpellsData()
    if frameScrollChild then
        local children = frameScrollChild:GetChildren()

        if children and next(children) ~= nil then
            for i = 1, #children do
                local child = children[i]

                child:ClearAllPoints()
                child:Hide()
                child:SetParent(nil)
            end
        end

        frameScrollChild:ClearAllPoints()
        frameScrollChild:Hide()
        frameScrollChild:SetParent(nil)
    end

    if frameScroll then
        frameScroll:ClearAllPoints()
        frameScroll:Hide()
        frameScroll:SetParent(nil)
    end

    frameScroll = CreateFrame("ScrollFrame", nil, frameContainer, "UIPanelScrollFrameTemplate")
    frameScroll:SetPoint("BOTTOMRIGHT", frameContainer, "BOTTOMRIGHT", -30, 10)
    frameScroll:SetPoint("TOPLEFT", frameContainer, "TOPLEFT", 0, -30)

    frameScrollChild = CreateFrame("Frame", nil, frameScroll)
    frameScrollChild:SetSize(1, 1)

    frameScroll:SetScrollChild(frameScrollChild)

    yOffset = -10

    local playerSpecID = addon:GetPlayerSpecID()
    if not playerSpecID then
        return
    end

    local listsToCheck = { 0, playerSpecID }
    for _, specID in ipairs(listsToCheck) do
        local list = SettingsDB.forcedSpells[specID]
        if list then
            table.sort(list)

            for i = 1, #list do
                CreateOptionLine(list[i])
            end
        end
    end
end

function addon:GetForcedSpellsSettings(parent)
    frameContainer = CreateFrame("Frame", nil, parent)

    local spellIDLabel = addon:GetControlLabel(false, frameContainer, "Spell:", 100)
    spellIDLabel:SetPoint("TOPLEFT", frameContainer, "TOPLEFT", 10, -10)

    local spellIDInput = addon:GetControlInput(false, frameContainer, 120)
    spellIDInput:SetNumeric(true)
    spellIDInput:SetPoint("LEFT", spellIDLabel, "RIGHT", 10, 0)

    local everyoneCheckbox = addon:GetControlCheckbox(false, "All Specs", frameContainer)
    everyoneCheckbox:SetChecked(false)
    everyoneCheckbox:SetPoint("LEFT", spellIDInput, "RIGHT", 10, 0)

    local newItemButton = addon:GetControlButton(false, "Add", frameContainer, 60, function(control)
        local newSpellID = spellIDInput:GetNumber()
        if not newSpellID or newSpellID <= 0 then
            return
        end

        local allSpecs = everyoneCheckbox:GetChecked()
        local exists = false

        local playerSpecID = addon:GetPlayerSpecID()
        if not playerSpecID then
            return
        end

        for _, specID in ipairs({ 0, playerSpecID }) do
            if exists then
                break
            end

            local list = SettingsDB.forcedSpells[specID]
            if list and next(list) ~= nil then
                for i = 1, #list do
                    if list[i] == newSpellID then
                        exists = true
                        break
                    end
                end
            end
        end

        if not exists then
            local specID = playerSpecID
            if allSpecs then
                specID = 0
            end

            SettingsDB.forcedSpells[specID] = SettingsDB.forcedSpells[specID] or {}

            table.insert(SettingsDB.forcedSpells[specID], newSpellID)
        end

        addon:GetForcedSpellsData()
    end)
    newItemButton:SetPoint("LEFT", everyoneCheckbox, "RIGHT", 100, 0)

    frameContainer:SetScript("OnShow", function(frame)
        addon:GetForcedSpellsData()
    end)

    return frameContainer
end
