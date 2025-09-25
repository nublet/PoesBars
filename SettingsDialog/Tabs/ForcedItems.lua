local addonName, addon = ...

local frameContainer
local frameScroll
local frameScrollChild
local yOffset = 0

local function CreateOptionLine(itemID)
    itemID = itemID or -1
    if itemID <= 0 then
        return
    end

    local frameIcon = CreateFrame("Frame", nil, frameScrollChild)
    frameIcon:EnableMouse(true)
    frameIcon:SetPoint("TOPLEFT", 10, yOffset)
    frameIcon:SetSize(addon.settingsIconSize, addon.settingsIconSize)
    frameIcon:SetScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(itemID)
        GameTooltip:Show()
    end)
    frameIcon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local textureIcon = frameIcon:CreateTexture(nil, "ARTWORK")
    textureIcon:SetAllPoints()

    local textRank = frameIcon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textRank:SetPoint("BOTTOMLEFT", frameIcon, "BOTTOMLEFT", 0, 0)
    textRank:SetShadowColor(0, 0, 0, 1)
    textRank:SetShadowOffset(0, 0)
    textRank:SetText("")
    textRank:SetTextColor(0, 1, 0, 1)

    local textItemID = addon:GetControlLabel(false, frameScrollChild, "", 100)
    textItemID:SetPoint("LEFT", frameIcon, "RIGHT", 10, 0)
    textItemID:SetText(itemID)

    local textItemName = addon:GetControlLabel(false, frameScrollChild, "", 200)
    textItemName:SetPoint("LEFT", textItemID, "RIGHT", 10, 0)

    local deleteButton = addon:GetControlButton(false, "Delete", frameScrollChild, 60, function(control)
        for i = 1, #SettingsDB.validItems do
            if SettingsDB.validItems[i] == itemID then
                table.remove(SettingsDB.validItems, i)
                break
            end
        end

        addon:GetForcedItemsData()
    end)
    deleteButton:SetPoint("LEFT", textItemName, "RIGHT", 10, 0)

    local item = Item:CreateFromItemID(itemID)
    item:ContinueOnItemLoad(function()
        local itemName = item:GetItemName()
        local itemLink = item:GetItemLink()
        local itemTexture = item:GetItemIcon()

        textItemName:SetText(itemName)
        textureIcon:SetTexture(itemTexture)

        if itemLink then
            local qualityTier = itemLink:match("|A:Professions%-ChatIcon%-Quality%-Tier(%d+)")

            if qualityTier then
                if qualityTier == "1" then
                    textRank:SetText("R1")
                elseif qualityTier == "2" then
                    textRank:SetText("R2")
                elseif qualityTier == "3" then
                    textRank:SetText("R3")
                end
            end
        end
    end)

    yOffset = yOffset - addon.settingsIconSize - 10
end

function addon:GetForcedItemsData()
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

    table.sort(SettingsDB.validItems)

    yOffset = -10

    for i = 1, #SettingsDB.validItems do
        CreateOptionLine(SettingsDB.validItems[i])
    end
end

function addon:GetForcedItemsSettings(parent)
    frameContainer = CreateFrame("Frame", nil, parent)

    local newItemLabel = addon:GetControlLabel(false, frameContainer, "ItemID:", 100)
    newItemLabel:SetPoint("TOPLEFT", frameContainer, "TOPLEFT", 10, -10)

    local newItemInput = addon:GetControlInput(false, frameContainer, 120)
    newItemInput:SetNumeric(true)
    newItemInput:SetPoint("LEFT", newItemLabel, "RIGHT", 10, 0)

    local newItemButton = addon:GetControlButton(false, "Add", frameContainer, 60, function(control)
        local itemID = newItemInput:GetNumber()

        if itemID and itemID > 0 then
            local exists = false
            for i = 1, #SettingsDB.validItems do
                if SettingsDB.validItems[i] == itemID then
                    exists = true
                    break
                end
            end

            if not exists then
                table.insert(SettingsDB.validItems, itemID)
            end
        end

        addon:GetForcedItemsSettings()
    end)
    newItemButton:SetPoint("LEFT", newItemInput, "RIGHT", 10, 0)

    frameContainer:SetScript("OnShow", function(frame)
        addon:GetForcedItemsSettings()
    end)

    return frameContainer
end
