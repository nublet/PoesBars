local addonName, addon = ...

local parentFrame
local scrollFrame
local scrollFrameChild
local yOffset = 0

local function CreateOptionLine(itemID)
    itemID = itemID or -1
    if itemID <= 0 then
        return
    end

    local frameIcon = CreateFrame("Frame", nil, scrollFrameChild)
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

    local textRank = frameIcon:CreateFontString(nil, "OVERLAY","GameFontNormal")
    textRank:SetFont(textRank:GetFont(), 10, "OUTLINE")
    textRank:SetPoint("BOTTOMLEFT", frameIcon, "BOTTOMLEFT", 0, 0)
    textRank:SetShadowColor(0, 0, 0, 1)
    textRank:SetShadowOffset(0, 0)
    textRank:SetText("")
    textRank:SetTextColor(0, 1, 0, 1)

    local textItemID = addon:GetControlLabel(false, scrollFrameChild, "", 100)
    textItemID:SetPoint("LEFT", frameIcon, "RIGHT", 10, 0)
    textItemID:SetText(itemID)

    local textItemName = addon:GetControlLabel(false, scrollFrameChild, "", 200)
    textItemName:SetPoint("LEFT", textItemID, "RIGHT", 10, 0)

    local deleteButton = addon:GetControlButton(false, "DELETE", scrollFrameChild, 60, function(control)
        for index, id in ipairs(SettingsDB.validItems) do
            if id == itemID then
                table.remove(SettingsDB.validItems, index)
                break
            end
        end

        addon:GetDataItems()
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

function addon:AddSettingsItems(parent)
    parentFrame = parent

    local newItemLabel = addon:GetControlLabel(false, parentFrame, "ItemID:", 100)
    newItemLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -10)

    local newItemInput = addon:GetControlInput(false, parentFrame, 120)
    newItemInput:SetNumeric(true)
    newItemInput:SetPoint("LEFT", newItemLabel, "RIGHT", 10, 0)

    local newItemButton = addon:GetControlButton(false, "ADD", parentFrame, 60, function(control)
        local itemID = newItemInput:GetNumber()

        if itemID and itemID > 0 then
            local exists = false
            for _, id in ipairs(SettingsDB.validItems) do
                if id == itemID then
                    exists = true
                    break
                end
            end

            if not exists then
                table.insert(SettingsDB.validItems, itemID)
            end
        end

        addon:GetDataItems()
    end)
    newItemButton:SetPoint("LEFT", newItemInput, "RIGHT", 10, 0)

    addon:GetDataItems()
end

function addon:GetDataItems()
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

    for _, itemID in ipairs(SettingsDB.validItems) do
        CreateOptionLine(itemID)
    end
end
