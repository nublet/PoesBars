local addonName, addon = ...

local frameContainer
local frameScroll
local frameScrollChild
local optionLines = {}
local radioAnchors = {}
local radioDisplay = {}
local radioOrientation = {}

local LSM = LibStub("LibSharedMedia-3.0")

local function ClearScrollFrame()
    for _, frameLine in ipairs(optionLines) do
        for i, child in ipairs({ frameLine:GetChildren() }) do
            child:ClearAllPoints()
            child:Hide()
            child:SetParent(nil)

            child = nil
        end
    end
    wipe(optionLines)

    if frameScrollChild then
        for i, child in ipairs({ frameScrollChild:GetChildren() }) do
            child:ClearAllPoints()
            child:Hide()
            child:SetParent(nil)

            child = nil
        end

        frameScrollChild:ClearAllPoints()
        frameScrollChild:Hide()
        frameScrollChild:SetParent(nil)

        frameScrollChild = nil
    end

    if frameScroll then
        frameScroll:ClearAllPoints()
        frameScroll:Hide()
        frameScroll:SetParent(nil)

        frameScroll = nil
    end

    for i, child in ipairs(addon.settingsControls) do
        child:ClearAllPoints()
        child:Hide()
        child:SetParent(nil)

        child = nil
    end
end

local function LoadLayout(categoryName)
    if InCombatLockdown() then
        return
    end

    if not CategoryOrderDB[categoryName] then
        CategoryOrderDB[categoryName] = {}
    end

    local yOffset = 0
    local seenSettingNames = {}

    for _, settingName in ipairs(CategoryOrderDB[categoryName]) do
        if optionLines[settingName] then
            seenSettingNames[settingName] = true

            optionLines[settingName]:SetPoint("TOPLEFT", 0, yOffset)

            yOffset = yOffset - addon.settingsIconSize - 10
        end
    end

    for settingName, frameLine in pairs(optionLines) do
        if not seenSettingNames[settingName] then
            frameLine:SetPoint("TOPLEFT", 0, yOffset)

            table.insert(CategoryOrderDB[categoryName], settingName)

            yOffset = yOffset - addon.settingsIconSize - 10
        end
    end
end

local function MoveSetting(categoryName, settingName, direction)
    local orderTable = CategoryOrderDB[categoryName]
    if not orderTable then
        return
    end

    for i = 1, #orderTable do
        if orderTable[i] == settingName then
            local targetIndex = i + direction
            if targetIndex >= 1 and targetIndex <= #orderTable then
                orderTable[i], orderTable[targetIndex] = orderTable[targetIndex], orderTable[i]

                LoadLayout(categoryName)
            end

            break
        end
    end
end

function GetOptionLine(categoryName, knownSpell)
    if knownSpell.itemID <= 0 and knownSpell.slotID <= 0 and knownSpell.spellID <= 0 then
        return nil
    end

    if not SpellsDB[knownSpell.specID] then
        SpellsDB[knownSpell.specID] = {}
    end

    local categoryValue = SpellsDB[knownSpell.specID][knownSpell.settingName]
    if not categoryValue or categoryValue == "" then
        categoryValue = addon.categoryUnknown
    end
    if categoryName ~= categoryValue then
        return nil
    end

    local frameLine = CreateFrame("Frame", nil, frameScrollChild)
    frameLine:SetPoint("TOPLEFT", 0, 0)
    frameLine:SetSize(1, 1)

    frameLine.categoryName = categoryName
    knownSpell:CopyTo(frameLine)

    local frameIcon = CreateFrame("Frame", nil, frameLine)
    frameIcon:EnableMouse(true)
    frameIcon:SetPoint("TOPLEFT", 0, 0)
    frameIcon:SetSize(addon.settingsIconSize, addon.settingsIconSize)
    frameIcon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    if frameLine.slotID > 0 then
        frameIcon:SetAttribute("type", "item")
        frameIcon:SetAttribute("item", "slot:" .. frameLine.slotID)
        frameIcon:SetScript("OnEnter", function(control)
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            GameTooltip:SetInventoryItem("player", frameLine.slotID)
            GameTooltip:Show()
        end)
    elseif frameLine.itemID > 0 then
        frameIcon:SetAttribute("type", "item")
        frameIcon:SetAttribute("item", "item:" .. frameLine.itemID)
        frameIcon:SetScript("OnEnter", function(control)
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(frameLine.itemID)
            GameTooltip:Show()
        end)
    else
        frameIcon:SetAttribute("type", "spell")
        frameIcon:SetAttribute("spell", frameLine.spellID)
        frameIcon:SetScript("OnEnter", function(control)
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(frameLine.spellID)
            GameTooltip:Show()
        end)
    end
    frameIcon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local textureIcon = frameIcon:CreateTexture(nil, "ARTWORK")
    textureIcon:SetAllPoints()

    local textID = addon:GetControlLabel(false, frameLine, "", 100)
    textID:SetPoint("LEFT", frameIcon, "RIGHT", 10, 0)

    local textName = addon:GetControlLabel(false, frameLine, "", 200)
    textName:SetPoint("LEFT", textID, "RIGHT", 10, 0)

    local dropdownCategory = addon:GetControlDropdown(false, frameLine, 120)
    dropdownCategory:SetPoint("LEFT", textName, "RIGHT", 10, 0)

    local buttonMoveDown = addon:GetControlButton(true, "Down", frameLine, 60, function(control)
        MoveSetting(categoryName, frameLine.settingName, 1)
    end)
    buttonMoveDown:SetPoint("TOPLEFT", dropdownCategory, "RIGHT", 5, 0)

    local buttonMoveUp = addon:GetControlButton(true, "Up", frameLine, 60, function(control)
        MoveSetting(categoryName, frameLine.settingName, -1)
    end)
    buttonMoveUp:SetPoint("BOTTOMLEFT", dropdownCategory, "RIGHT", 5, 0)

    if frameLine.slotID > 0 then
        textID:SetText(frameLine.slotID)

        local item = Item:CreateFromItemID(GetInventoryItemID("player", frameLine.slotID))
        item:ContinueOnItemLoad(function()
            local itemName = item:GetItemName()
            local itemTexture = item:GetItemIcon()

            textName:SetText(itemName)
            textureIcon:SetTexture(itemTexture)
        end)
    elseif frameLine.itemID > 0 then
        textID:SetText(frameLine.itemID)

        local font = LSM:Fetch("font", SettingsDB.fontName) or "Fonts\\FRIZQT__.TTF"

        local textRank = frameIcon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textRank:SetFont(font, 10, "OUTLINE")
        textRank:SetPoint("BOTTOMLEFT", frameIcon, "BOTTOMLEFT", 0, 0)
        textRank:SetShadowColor(0, 0, 0, 1)
        textRank:SetShadowOffset(0, 0)
        textRank:SetText("")
        textRank:SetTextColor(0, 1, 0, 1)

        local item = Item:CreateFromItemID(frameLine.itemID)
        item:ContinueOnItemLoad(function()
            local itemName = item:GetItemName()
            local itemLink = item:GetItemLink()
            local itemTexture = item:GetItemIcon()

            textName:SetText(itemName)
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

        frameIcon:SetScript("OnEnter", function(control)
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(frameLine.itemID)
            GameTooltip:Show()
        end)
    elseif frameLine.spellID > 0 then
        local spellInfo = C_Spell.GetSpellInfo(frameLine.spellID)

        textID:SetText(frameLine.spellID)
        textName:SetText(spellInfo.name)
        textureIcon:SetTexture(spellInfo.iconID)
    end

    dropdownCategory.initializeFunc = function(control, level, menuList)
        local function addItem(text)
            local info = UIDropDownMenu_CreateInfo()
            info.text = text
            info.func = function()
                SpellsDB[frameLine.specID][frameLine.settingName] = text
                UIDropDownMenu_SetSelectedName(dropdownCategory, text)
            end
            UIDropDownMenu_AddButton(info)
        end

        addItem("")

        local validCategories = addon:GetValidCategories()

        for index = 1, #validCategories do
            local name = validCategories[index]

            addItem(name)
        end
    end

    UIDropDownMenu_Initialize(dropdownCategory, dropdownCategory.initializeFunc)

    if categoryValue ~= "" then
        UIDropDownMenu_SetSelectedName(dropdownCategory, categoryValue)
    else
        UIDropDownMenu_SetText(dropdownCategory, "<Select>")
    end

    return frameLine
end

function addon:GetCategoriesSettings(parent)
    frameContainer = CreateFrame("Frame", nil, parent)

    local categoryLabel = addon:GetControlLabel(false, frameContainer, "Category:", 100)
    categoryLabel:SetPoint("TOPLEFT", frameContainer, "TOPLEFT", 10, -10)

    local categoryDropdown = addon:GetControlDropdown(false, frameContainer, 120)
    categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", 10, 0)

    local categoryInput = addon:GetControlInput(false, frameContainer, 120)
    categoryInput:Hide()
    categoryInput:SetPoint("LEFT", categoryDropdown, "RIGHT", 10, 0)

    categoryDropdown.initializeFunc = function(frame, level, menuList)
        local function addItem(text)
            if text == addon.categoryUnknown then
                return
            end

            local info = UIDropDownMenu_CreateInfo()
            info.text = text
            info.func = function()
                if InCombatLockdown() then
                    return
                end

                ClearScrollFrame()

                if text == "Add New..." then
                    UIDropDownMenu_SetSelectedName(categoryDropdown, text)

                    categoryInput:SetFocus()
                    categoryInput:SetText("")
                    categoryInput:Show()
                else
                    categoryInput:Hide()

                    frameScroll = CreateFrame("ScrollFrame", nil, frameContainer, "UIPanelScrollFrameTemplate")

                    frameScrollChild = CreateFrame("Frame", nil, frameScroll)
                    frameScrollChild:SetSize(1, 1)

                    frameScroll:SetScrollChild(frameScrollChild)

                    local categoryName = text
                    if not categoryName or categoryName == "" then
                        categoryName = addon.categoryUnknown
                    end

                    UIDropDownMenu_SetSelectedName(categoryDropdown, categoryName)

                    if categoryName == addon.categoryIgnored or categoryName == addon.categoryUnknown then
                        frameScroll:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, 0)
                    else
                        local settingsTable = addon:GetSettingsTable(categoryName)

                        local categoryDelete = addon:GetControlButton(true, "Delete", frameContainer, 60, function(control)
                            if categoryName == "" or categoryName == addon.categoryIgnored or categoryName == "Add New..." or categoryName == addon.categoryUnknown then
                                return
                            end

                            for _, innerTable in pairs(SpellsDB) do
                                for key, value in pairs(innerTable) do
                                    if value == categoryName then
                                        innerTable[key] = ""
                                    end
                                end
                            end

                            CategoryOrderDB[categoryName] = nil
                            SettingsDB[categoryName] = nil

                            for index, valueName in ipairs(SettingsDB.validCategories) do
                                if categoryName == valueName then
                                    table.remove(SettingsDB.validCategories, index)
                                end
                            end

                            UIDropDownMenu_SetText(categoryDropdown, "<Select>")
                        end)
                        categoryDelete:SetPoint("LEFT", categoryInput, "RIGHT", 10, 0)

                        local displayLabel = addon:GetControlLabel(true, frameContainer, "Display:", 100)
                        displayLabel:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, -5)

                        local displayAlways = addon:GetControlRadioButton(true, frameContainer, radioDisplay, "Always", function(control)
                            addon:ClearRadios(radioDisplay)
                            control:SetChecked(true)

                            settingsTable.displayWhen = "Always"
                        end)
                        displayAlways:SetPoint("LEFT", displayLabel, "RIGHT", 10, 0)

                        local displayInCombat = addon:GetControlRadioButton(true, frameContainer, radioDisplay, "In Combat", function(control)
                            addon:ClearRadios(radioDisplay)
                            control:SetChecked(true)

                            settingsTable.displayWhen = "In Combat"
                        end)
                        displayInCombat:SetPoint("LEFT", displayAlways, "RIGHT", 60, 0)

                        local displayOutOfCombat = addon:GetControlRadioButton(true, frameContainer, radioDisplay, "Out Of Combat", function(control)
                            addon:ClearRadios(radioDisplay)
                            control:SetChecked(true)

                            settingsTable.displayWhen = "Out Of Combat"
                        end)
                        displayOutOfCombat:SetPoint("LEFT", displayInCombat, "RIGHT", 70, 0)

                        if settingsTable.displayWhen == "" or settingsTable.displayWhen == "Always" then
                            displayAlways:SetChecked(true)
                            displayInCombat:SetChecked(false)
                            displayOutOfCombat:SetChecked(false)
                        elseif settingsTable.displayWhen == "In Combat" then
                            displayAlways:SetChecked(false)
                            displayInCombat:SetChecked(true)
                            displayOutOfCombat:SetChecked(false)
                        else
                            displayAlways:SetChecked(false)
                            displayInCombat:SetChecked(false)
                            displayOutOfCombat:SetChecked(true)
                        end

                        local isClickableCheckbox = addon:GetControlCheckbox(true, "Make Clickable", frameContainer, function(control)
                            settingsTable.isClickable = control:GetChecked()
                        end)
                        isClickableCheckbox:SetPoint("TOPLEFT", displayLabel, "BOTTOMLEFT", 0, 0)
                        if settingsTable.isClickable then
                            isClickableCheckbox:SetChecked(true)
                        else
                            isClickableCheckbox:SetChecked(false)
                        end

                        local colorBasedOnStateCheckbox = addon:GetControlCheckbox(true, "Color Based on State", frameContainer, function(control)
                            settingsTable.colorBasedOnState = control:GetChecked()
                        end)
                        colorBasedOnStateCheckbox:SetPoint("LEFT", isClickableCheckbox, "RIGHT", 215, 0)
                        if settingsTable.colorBasedOnState then
                            colorBasedOnStateCheckbox:SetChecked(true)
                        else
                            colorBasedOnStateCheckbox:SetChecked(false)
                        end

                        local glowWhenAuraActiveCheckbox = addon:GetControlCheckbox(true, "Glow When Aura Active", frameContainer, function(control)
                            settingsTable.glowWhenAuraActive = control:GetChecked()
                        end)
                        glowWhenAuraActiveCheckbox:SetPoint("TOPLEFT", isClickableCheckbox, "BOTTOMLEFT", 0, 0)
                        if settingsTable.glowWhenAuraActive then
                            glowWhenAuraActiveCheckbox:SetChecked(true)
                        else
                            glowWhenAuraActiveCheckbox:SetChecked(false)
                        end

                        local glowWhenOverriddenCheckbox = addon:GetControlCheckbox(true, "Glow When Overridden ", frameContainer, function(control)
                            settingsTable.glowWhenOverridden = control:GetChecked()
                        end)
                        glowWhenOverriddenCheckbox:SetPoint("LEFT", glowWhenAuraActiveCheckbox, "RIGHT", 215, 0)
                        if settingsTable.glowWhenOverridden then
                            glowWhenOverriddenCheckbox:SetChecked(true)
                        else
                            glowWhenOverriddenCheckbox:SetChecked(false)
                        end

                        local showOnCooldownCheckbox = addon:GetControlCheckbox(true, "Only Show On Cooldown or Aura Active", frameContainer)
                        showOnCooldownCheckbox:SetPoint("TOPLEFT", glowWhenAuraActiveCheckbox, "BOTTOMLEFT", 0, 0)
                        if settingsTable.showOnCooldown then
                            showOnCooldownCheckbox:SetChecked(true)
                        else
                            showOnCooldownCheckbox:SetChecked(false)
                        end

                        local showWhenAvailableCheckbox = addon:GetControlCheckbox(true, "Only Show When Available", frameContainer)
                        showWhenAvailableCheckbox:SetPoint("LEFT", showOnCooldownCheckbox, "RIGHT", 215, 0)
                        if settingsTable.showWhenAvailable then
                            showWhenAvailableCheckbox:SetChecked(true)
                        else
                            showWhenAvailableCheckbox:SetChecked(false)
                        end

                        showOnCooldownCheckbox:SetScript("OnClick", function(control)
                            settingsTable.showOnCooldown = control:GetChecked()

                            if settingsTable.showOnCooldown then
                                showWhenAvailableCheckbox:SetChecked(false)
                            end
                        end)

                        showWhenAvailableCheckbox:SetScript("OnClick", function(control)
                            settingsTable.showWhenAvailable = control:GetChecked()

                            if settingsTable.showWhenAvailable then
                                showOnCooldownCheckbox:SetChecked(false)
                            end
                        end)

                        local iconSizeLabel = addon:GetControlLabel(true, frameContainer, "Icon Size:", 100)
                        iconSizeLabel:SetPoint("TOPLEFT", showOnCooldownCheckbox, "BOTTOMLEFT", 0, 0)

                        local iconSizeInput = addon:GetControlInput(true, frameContainer, 40, function(control)
                            settingsTable.iconSize = addon:GetNumberOrDefault(48, control:GetText())
                        end)
                        iconSizeInput:SetNumeric(true)
                        iconSizeInput:SetPoint("LEFT", iconSizeLabel, "RIGHT", 10, 0)
                        iconSizeInput:SetText(settingsTable.iconSize)

                        local positionXLabel = addon:GetControlLabel(true, frameContainer, "X:", 30)
                        positionXLabel:SetPoint("LEFT", iconSizeInput, "RIGHT", 10, 0)

                        local positionXInput = addon:GetControlInput(true, frameContainer, 80, function(control)
                            settingsTable.x = addon:GetNumberOrDefault(0, control:GetText())
                        end)
                        positionXInput:SetPoint("LEFT", positionXLabel, "RIGHT", 10, 0)
                        positionXInput:SetText(settingsTable.x)

                        local iconSpacingLabel = addon:GetControlLabel(true, frameContainer, "Icon Gap:", 100)
                        iconSpacingLabel:SetPoint("TOPLEFT", iconSizeLabel, "BOTTOMLEFT", 0, 0)

                        local iconSpacingInput = addon:GetControlInput(true, frameContainer, 40, function(control)
                            settingsTable.iconSpacing = addon:GetNumberOrDefault(2, control:GetText())
                        end)
                        iconSpacingInput:SetPoint("LEFT", iconSpacingLabel, "RIGHT", 10, 0)
                        iconSpacingInput:SetText(settingsTable.iconSpacing)

                        local positionYLabel = addon:GetControlLabel(true, frameContainer, "Y:", 30)
                        positionYLabel:SetPoint("LEFT", iconSpacingInput, "RIGHT", 10, 0)

                        local positionYInput = addon:GetControlInput(true, frameContainer, 80, function(control)
                            settingsTable.y = addon:GetNumberOrDefault(0, control:GetText())
                        end)
                        positionYInput:SetPoint("LEFT", positionYLabel, "RIGHT", 10, 0)
                        positionYInput:SetText(settingsTable.y)

                        local wrapAfterLabel = addon:GetControlLabel(true, frameContainer, "Wrap After:", 100)
                        wrapAfterLabel:SetPoint("TOPLEFT", iconSpacingLabel, "BOTTOMLEFT", 0, 0)

                        local wrapAfterInput = addon:GetControlInput(true, frameContainer, 40, function(control)
                            settingsTable.wrapAfter = addon:GetNumberOrDefault(0, control:GetText())
                        end)
                        wrapAfterInput:SetPoint("LEFT", wrapAfterLabel, "RIGHT", 10, 0)
                        wrapAfterInput:SetText(settingsTable.wrapAfter)

                        local orientationLabel = addon:GetControlLabel(true, frameContainer, "Orientation:", 100)
                        orientationLabel:SetPoint("TOPLEFT", wrapAfterLabel, "BOTTOMLEFT", 0, 0)

                        local orientationHorizontal = addon:GetControlRadioButton(true, frameContainer, radioOrientation, "Horizontal", function(control)
                            addon:ClearRadios(radioOrientation)
                            control:SetChecked(true)

                            settingsTable.isVertical = false
                        end)
                        orientationHorizontal:SetPoint("LEFT", orientationLabel, "RIGHT", 10, 0)

                        local orientationVertical = addon:GetControlRadioButton(true, frameContainer, radioOrientation, "Vertical", function(control)
                            addon:ClearRadios(radioOrientation)
                            control:SetChecked(true)

                            settingsTable.isVertical = true
                        end)
                        orientationVertical:SetPoint("LEFT", orientationHorizontal, "RIGHT", 110, 0)

                        if settingsTable.isVertical then
                            orientationHorizontal:SetChecked(false)
                            orientationVertical:SetChecked(true)
                        else
                            orientationHorizontal:SetChecked(true)
                            orientationVertical:SetChecked(false)
                        end

                        local anchorLabel = addon:GetControlLabel(true, frameContainer, "Anchor:", 100)
                        anchorLabel:SetPoint("TOPLEFT", orientationLabel, "BOTTOMLEFT", 0, 0)

                        local anchorTopLeft = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Top Left", function(control)
                            addon:ClearRadios(radioAnchors)
                            control:SetChecked(true)

                            settingsTable.anchor = "TOPLEFT"
                        end)
                        anchorTopLeft:SetPoint("LEFT", anchorLabel, "RIGHT", 10, 0)

                        local anchorTop = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Top", function(control)
                            addon:ClearRadios(radioAnchors)
                            control:SetChecked(true)

                            settingsTable.anchor = "TOP"
                        end)
                        anchorTop:SetPoint("LEFT", anchorTopLeft, "RIGHT", 110, 0)

                        local anchorTopRight = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Top Right", function(control)
                            addon:ClearRadios(radioAnchors)
                            control:SetChecked(true)

                            settingsTable.anchor = "TOPRIGHT"
                        end)
                        anchorTopRight:SetPoint("LEFT", anchorTop, "RIGHT", 110, 0)

                        local anchorLeft = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Left", function(control)
                            addon:ClearRadios(radioAnchors)
                            control:SetChecked(true)

                            settingsTable.anchor = "LEFT"
                        end)
                        anchorLeft:SetPoint("TOPLEFT", anchorTopLeft, "BOTTOMLEFT", 0, 0)

                        local anchorCenter = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Center", function(control)
                            addon:ClearRadios(radioAnchors)
                            control:SetChecked(true)

                            settingsTable.anchor = "CENTER"
                        end)
                        anchorCenter:SetPoint("LEFT", anchorLeft, "RIGHT", 110, 0)

                        local anchorRight = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Right", function(control)
                            addon:ClearRadios(radioAnchors)
                            control:SetChecked(true)

                            settingsTable.anchor = "RIGHT"
                        end)
                        anchorRight:SetPoint("LEFT", anchorCenter, "RIGHT", 110, 0)

                        local anchorBottomLeft = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Bottom Left", function(control)
                            addon:ClearRadios(radioAnchors)
                            control:SetChecked(true)

                            settingsTable.anchor = "BOTTOMLEFT"
                        end)
                        anchorBottomLeft:SetPoint("TOPLEFT", anchorLeft, "BOTTOMLEFT", 0, 0)

                        local anchorBottom = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Bottom", function(control)
                            addon:ClearRadios(radioAnchors)
                            control:SetChecked(true)

                            settingsTable.anchor = "BOTTOM"
                        end)
                        anchorBottom:SetPoint("LEFT", anchorBottomLeft, "RIGHT", 110, 0)

                        local anchorBottomRight = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Bottom Right", function(control)
                            addon:ClearRadios(radioAnchors)
                            control:SetChecked(true)

                            settingsTable.anchor = "BOTTOMRIGHT"
                        end)
                        anchorBottomRight:SetPoint("LEFT", anchorBottom, "RIGHT", 110, 0)

                        if settingsTable.anchor == "TOPLEFT" then
                            anchorTopLeft:SetChecked(true)
                        elseif settingsTable.anchor == "TOPRIGHT" then
                            anchorTopRight:SetChecked(true)
                        elseif settingsTable.anchor == "TOP" then
                            anchorTop:SetChecked(true)
                        elseif settingsTable.anchor == "BOTTOMLEFT" then
                            anchorBottomLeft:SetChecked(true)
                        elseif settingsTable.anchor == "BOTTOMRIGHT" then
                            anchorBottomRight:SetChecked(true)
                        elseif settingsTable.anchor == "BOTTOM" then
                            anchorBottom:SetChecked(true)
                        elseif settingsTable.anchor == "LEFT" then
                            anchorLeft:SetChecked(true)
                        elseif settingsTable.anchor == "RIGHT" then
                            anchorRight:SetChecked(true)
                        else
                            anchorCenter:SetChecked(true)
                        end

                        frameScroll:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", 0, -30)
                    end
                    frameScroll:SetPoint("BOTTOMRIGHT", frameContainer, "BOTTOMRIGHT", -30, 0)

                    for iconKey, knownSpell in pairs(KnownSpell:GetAll()) do
                        local frameLine = GetOptionLine(categoryName, knownSpell)
                        if frameLine then
                            optionLines[frameLine.settingName] = frameLine
                        end
                    end

                    LoadLayout(categoryName)
                end
            end
            UIDropDownMenu_AddButton(info)
        end

        addItem("")
        addItem("Add New...")

        table.sort(SettingsDB.validCategories, function(a, b)
            return a < b
        end)

        local validCategories = addon:GetValidCategories()

        for index = 1, #validCategories do
            local name = validCategories[index]

            addItem(name)
        end
    end

    categoryInput:SetScript("OnEnterPressed", function(frame)
        local value = strtrim(frame:GetText())
        if value ~= "" then
            table.insert(SettingsDB.validCategories, value)
            UIDropDownMenu_SetSelectedName(categoryDropdown, value)
            frame:ClearFocus()
            frame:Hide()
            UIDropDownMenu_Initialize(categoryDropdown, categoryDropdown.initializeFunc)
        end
    end)

    UIDropDownMenu_Initialize(categoryDropdown, categoryDropdown.initializeFunc)
    UIDropDownMenu_SetText(categoryDropdown, "<Select>")

    return frameContainer
end
