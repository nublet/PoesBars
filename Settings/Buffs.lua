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

    local textureSpellIcon = scrollFrameChild:CreateTexture(nil, "ARTWORK")
    textureSpellIcon:SetPoint("TOPLEFT", 10, yOffset)
    textureSpellIcon:SetSize(addon.settingsIconSize, addon.settingsIconSize)

    local textSpellID = addon:GetControlLabel(false, scrollFrameChild, "", 100)
    textSpellID:SetPoint("LEFT", textureSpellIcon, "RIGHT", 10, 0)
    textSpellID:SetText(spellID)

    local textSpellName = addon:GetControlLabel(false, scrollFrameChild, "", 200)
    textSpellName:SetPoint("LEFT", textSpellID, "RIGHT", 10, 0)

    local textureBuffIcon = scrollFrameChild:CreateTexture(nil, "ARTWORK")
    textureBuffIcon:SetPoint("LEFT", textSpellName, "RIGHT", 10, 0)
    textureBuffIcon:SetSize(addon.settingsIconSize, addon.settingsIconSize)

    local textBuffID = addon:GetControlLabel(false, scrollFrameChild, "", 100)
    textBuffID:SetPoint("LEFT", textureBuffIcon, "RIGHT", 10, 0)
    textBuffID:SetText(buffID)

    local textBuffName = addon:GetControlLabel(false, scrollFrameChild, "", 200)
    textBuffName:SetPoint("LEFT", textBuffID, "RIGHT", 10, 0)

    local deleteButton = addon:GetControlButton(false, "DELETE", scrollFrameChild, 60, function(control)
        SettingsDB.buffOverrides[spellID] = nil
        addon:GetDataBuffs()
    end)
    deleteButton:SetPoint("LEFT", textBuffName, "RIGHT", 10, 0)

    local buffSpellInfo = C_Spell.GetSpellInfo(buffID)
    if buffSpellInfo then
        textBuffName:SetText(buffSpellInfo.name)
        textureBuffIcon:SetTexture(buffSpellInfo.iconID)
    end

    local spellSpellInfo = C_Spell.GetSpellInfo(spellID)
    if spellSpellInfo then
        textSpellName:SetText(spellSpellInfo.name)
        textureSpellIcon:SetTexture(spellSpellInfo.iconID)
    end

    yOffset = yOffset - addon.settingsIconSize - 10
end

function addon:AddSettingsBuffs(parent)
    parentFrame = parent

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

    local newItemButton = addon:GetControlButton(false, "ADD", parentFrame, 60, function(control)
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

        addon:GetDataBuffs()
    end)
    newItemButton:SetPoint("LEFT", buffIDInput, "RIGHT", 10, 0)

    addon:GetDataBuffs()
end

function addon:GetDataBuffs()
    if scrollFrameChild then
        for i, child in ipairs({ scrollFrameChild:GetChildren() }) do
            child:ClearAllPoints()
            child:Hide()
            child:SetParent(nil)
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

    table.sort(SettingsDB.validItems)

    yOffset = -10

    for spellID, buffID in pairs(SettingsDB.buffOverrides) do
        CreateOptionLine(buffID, spellID)
    end
end
