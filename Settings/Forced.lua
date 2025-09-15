local addonName, addon = ...

local parentFrame
local scrollFrame
local scrollFrameChild
local yOffset = 0

local function CreateOptionLine(spellID)
    spellID = spellID or -1
    if spellID <= 0 then
        return
    end

    local frameSpell = CreateFrame("Frame", nil, scrollFrameChild)
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

    local textSpellID = addon:GetControlLabel(false, scrollFrameChild, "", 60)
    textSpellID:SetPoint("LEFT", frameSpell, "RIGHT", 10, 0)
    textSpellID:SetText(spellID)

    local textSpellName = addon:GetControlLabel(false, scrollFrameChild, "", 150)
    textSpellName:SetPoint("LEFT", textSpellID, "RIGHT", 10, 0)

    local deleteButton = addon:GetControlButton(false, "Delete", scrollFrameChild, 60, function(control)
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

        addon:GetDataForced()
    end)
    deleteButton:SetPoint("LEFT", textSpellName, "RIGHT", 10, 0)

    local spellSpellInfo = C_Spell.GetSpellInfo(spellID)
    if spellSpellInfo then
        textSpellName:SetText(spellSpellInfo.name)
        textureSpell:SetTexture(spellSpellInfo.iconID)
    end

    yOffset = yOffset - addon.settingsIconSize - 10
end

function addon:CreateSettingsForced(mainCategory)
    parentFrame = CreateFrame("Frame", "ForcedSettingsFrame", UIParent)
    parentFrame.name = "Forced Spells"

    local spellIDLabel = addon:GetControlLabel(false, parentFrame, "Spell:", 100)
    spellIDLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -10)

    local spellIDInput = addon:GetControlInput(false, parentFrame, 120)
    spellIDInput:SetNumeric(true)
    spellIDInput:SetPoint("LEFT", spellIDLabel, "RIGHT", 10, 0)

    local everyoneCheckbox = addon:GetControlCheckbox(false, "All Specs", parentFrame)
    everyoneCheckbox:SetChecked(false)
    everyoneCheckbox:SetPoint("LEFT", spellIDInput, "RIGHT", 10, 0)

    local newItemButton = addon:GetControlButton(false, "Add", parentFrame, 60, function(control)
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

        addon:GetDataForced()
    end)
    newItemButton:SetPoint("LEFT", everyoneCheckbox, "RIGHT", 100, 0)

    parentFrame:SetScript("OnHide", function(frame)
        if not addon.isSettingsShown then
            return
        end

        addon.isLoaded = false
        addon.isSettingsShown = false

        addon:Debounce("CreateIcons", 1, function()
            addon:CreateIcons()
            addon.isLoaded = true
        end)
    end)
    parentFrame:SetScript("OnShow", function(frame)
        addon:GetDataForced()
    end)

    local subCategory = Settings.RegisterCanvasLayoutSubcategory(mainCategory, parentFrame, parentFrame.name);
    Settings.RegisterAddOnCategory(subCategory);
    return subCategory:GetID()
end

function addon:GetDataForced()
    if scrollFrameChild then
        local children = scrollFrameChild:GetChildren()

        if children and next(children) ~= nil then
            for i = 1, #children do
                local child = children[i]

                child:ClearAllPoints()
                child:Hide()
                child:SetParent(nil)
            end
        end

        scrollFrameChild:ClearAllPoints()
        scrollFrameChild:Hide()
        scrollFrameChild:SetParent(nil)
    end

    if scrollFrame then
        scrollFrame:ClearAllPoints()
        scrollFrame:Hide()
        scrollFrame:SetParent(nil)
    end

    scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -10, 10)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -30)

    scrollFrameChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrameChild:SetSize(1, 1)

    scrollFrame:SetScrollChild(scrollFrameChild)

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
