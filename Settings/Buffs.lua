local addonName, addon = ...

local parentFrame
local scrollFrame
local scrollFrameChild
local yOffset = 0

local function CreateOptionLine(buffID, spellID)
    buffID = buffID or -1
    if buffID <= 0 then
        return
    end

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

    local frameBuff = CreateFrame("Frame", nil, scrollFrameChild)
    frameBuff:EnableMouse(true)
    frameBuff:SetPoint("LEFT", textSpellName, "RIGHT", 10, 0)
    frameBuff:SetSize(addon.settingsIconSize, addon.settingsIconSize)
    frameBuff:SetScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(buffID)
        GameTooltip:Show()
    end)
    frameBuff:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local textureBuff = frameBuff:CreateTexture(nil, "ARTWORK")
    textureBuff:SetAllPoints()

    local textBuffID = addon:GetControlLabel(false, scrollFrameChild, "", 60)
    textBuffID:SetPoint("LEFT", frameBuff, "RIGHT", 10, 0)
    textBuffID:SetText(buffID)

    local textBuffName = addon:GetControlLabel(false, scrollFrameChild, "", 150)
    textBuffName:SetPoint("LEFT", textBuffID, "RIGHT", 10, 0)

    local deleteButton = addon:GetControlButton(false, "Delete", scrollFrameChild, 60, function(control)
        SettingsDB.buffOverrides[spellID] = nil
        addon:GetDataBuffs()
    end)
    deleteButton:SetPoint("LEFT", textBuffName, "RIGHT", 10, 0)

    local buffSpellInfo = C_Spell.GetSpellInfo(buffID)
    if buffSpellInfo then
        textBuffName:SetText(buffSpellInfo.name)
        textureBuff:SetTexture(buffSpellInfo.iconID)
    end

    local spellSpellInfo = C_Spell.GetSpellInfo(spellID)
    if spellSpellInfo then
        textSpellName:SetText(spellSpellInfo.name)
        textureSpell:SetTexture(spellSpellInfo.iconID)
    end

    yOffset = yOffset - addon.settingsIconSize - 10
end

function addon:CreateSettingsBuffs(mainCategory)
    parentFrame = CreateFrame("Frame", "BuffsSettingsFrame", UIParent)
    parentFrame.name = "Buff Overrides"

    local spellIDLabel = addon:GetControlLabel(false, parentFrame, "Spell:", 100)
    spellIDLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -10)

    local spellIDInput = addon:GetControlInput(false, parentFrame, 120)
    spellIDInput:SetNumeric(true)
    spellIDInput:SetPoint("LEFT", spellIDLabel, "RIGHT", 10, 0)

    local buffIDLabel = addon:GetControlLabel(false, parentFrame, "Buff:", 100)
    buffIDLabel:SetPoint("LEFT", spellIDInput, "RIGHT", 10, 0)

    local buffIDInput = addon:GetControlInput(false, parentFrame, 120)
    buffIDInput:SetNumeric(true)
    buffIDInput:SetPoint("LEFT", buffIDLabel, "RIGHT", 10, 0)

    local newItemButton = addon:GetControlButton(false, "Add", parentFrame, 60, function(control)
        local newBuffID = buffIDInput:GetNumber()
        if not newBuffID or newBuffID <= 0 then
            return
        end

        local newSpellID = spellIDInput:GetNumber()
        if not newSpellID or newSpellID <= 0 then
            return
        end

        local exists = false
        for spellID, buffID in pairs(SettingsDB.buffOverrides) do
            if spellID == newSpellID then
                exists = true
                break
            end
        end

        if not exists then
            SettingsDB.buffOverrides[newSpellID] = newBuffID
        end

        parentFrame:SetScript("OnHide", function(frame)
            addon.isLoaded = false

            addon:Debounce("CreateIcons", 1, function()
                addon:CreateIcons()
                addon.isLoaded = true
            end)
        end)
        parentFrame:SetScript("OnShow", function(frame)
            addon:GetDataBuffs()
        end)

        local subCategory = Settings.RegisterCanvasLayoutSubcategory(mainCategory, parentFrame, parentFrame.name);
        Settings.RegisterAddOnCategory(subCategory);
        return subCategory:GetID()
    end)
    newItemButton:SetPoint("LEFT", buffIDInput, "RIGHT", 10, 0)

    parentFrame:SetScript("OnHide", function(frame)
        addon.isLoaded = false

        addon:Debounce("CreateIcons", 1, function()
            addon:CreateIcons()
            addon.isLoaded = true
        end)
    end)
    parentFrame:SetScript("OnShow", function(frame)
        addon:GetDataBuffs()
    end)

    local subCategory = Settings.RegisterCanvasLayoutSubcategory(mainCategory, parentFrame, parentFrame.name);
    Settings.RegisterAddOnCategory(subCategory);
    return subCategory:GetID()
end

function addon:GetDataBuffs()
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

    table.sort(SettingsDB.buffOverrides)

    yOffset = -10

    for spellID, buffID in pairs(SettingsDB.buffOverrides) do
        CreateOptionLine(buffID, spellID)
    end
end
