local addonName, addon = ...

local categories = {}
local items = {}
local spells = {}

local LSM = LibStub("LibSharedMedia-3.0")
local font = LSM:Fetch("font", "Naowh") or "Fonts\\FRIZQT__.TTF"

local function CreateIconFrame(itemID, specID, spellID)
    itemID = itemID or -1
    specID = specID or -1
    spellID = spellID or -1

    if itemID <= 0 and spellID <= 0 then
        return
    end

    if itemID > 0 and items[itemID] then
        return
    end

    if spellID > 0 and spells[spellID] then
        return
    end

    local newFrame = CreateFrame("Frame", nil, UIParent)
    newFrame:Hide()
    newFrame:SetSize(40, 40)
    newFrame:SetPoint("CENTER", 0, 0)

    local frameBorder = CreateFrame("Frame", nil, newFrame, "BackdropTemplate")
    frameBorder:SetAllPoints(newFrame)
    frameBorder:SetBackdrop({ edgeFile = "Interface/Buttons/WHITE8x8", edgeSize = 1, })
    frameBorder:SetBackdropBorderColor(1, 0, 0, 1)
    frameBorder:SetFrameLevel(newFrame:GetFrameLevel() + 1)

    local frameCooldown = CreateFrame("Cooldown", nil, newFrame, "CooldownFrameTemplate")
    frameCooldown:SetAllPoints(newFrame)

    local textBinding = newFrame:CreateFontString(nil, "OVERLAY")
    textBinding:SetFont(font, 12, "OUTLINE")
    textBinding:SetPoint("TOPRIGHT", newFrame, "TOPRIGHT", 0, 0)
    textBinding:SetShadowColor(0, 0, 0, 1)
    textBinding:SetShadowOffset(0, 0)
    textBinding:SetText("")
    textBinding:SetTextColor(1, 1, 1, 1)

    local textCharges = newFrame:CreateFontString(nil, "OVERLAY")
    textCharges:SetFont(font, 12, "OUTLINE")
    textCharges:SetTextColor(1, 1, 1, 1)
    textCharges:SetShadowColor(0, 0, 0, 1)
    textCharges:SetShadowOffset(0, 0)
    textCharges:SetPoint("BOTTOMRIGHT", newFrame, "BOTTOMRIGHT", 0, 0)
    textCharges:SetText("")

    local textCooldown = newFrame:CreateFontString(nil, "OVERLAY")
    textCooldown:SetFont(font, 16, "OUTLINE")
    textCooldown:SetPoint("CENTER")
    textCooldown:SetShadowColor(0, 0, 0, 1)
    textCooldown:SetShadowOffset(0, 0)
    textCooldown:SetText("")
    textCooldown:SetTextColor(1, 1, 1, 1)

    local textRank = newFrame:CreateFontString(nil, "OVERLAY")
    textRank:SetFont(font, 10, "OUTLINE")
    textRank:SetPoint("BOTTOMLEFT", newFrame, "BOTTOMLEFT", 0, 0)
    textRank:SetShadowColor(0, 0, 0, 1)
    textRank:SetShadowOffset(0, 0)
    textRank:SetText("")
    textRank:SetTextColor(0, 1, 0, 1)

    local textID = newFrame:CreateFontString(nil, "OVERLAY")
    textID:SetFont(font, 12, "OUTLINE")
    textID:SetPoint("CENTER")
    textID:SetShadowColor(0, 0, 0, 1)
    textID:SetShadowOffset(0, 0)
    textID:SetText("")
    textID:SetTextColor(1, 1, 1, 1)

    local textureIcon = newFrame:CreateTexture(nil, "ARTWORK")
    textureIcon:SetAllPoints(newFrame)

    local baseChargeInfo = C_Spell.GetSpellCharges(spellID)
    if baseChargeInfo then
        newFrame.spellCooldown = baseChargeInfo.cooldownDuration * 1000
    else
        local cooldownMS, gcdMS = GetSpellBaseCooldown(spellID)
        if cooldownMS and cooldownMS > 0 then
            newFrame.spellCooldown = cooldownMS
        else
            newFrame.spellCooldown = 0
        end
    end

    if itemID > 0 then
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function()
            local itemName = item:GetItemName()
            local itemLink = item:GetItemLink()
            local itemTexture = item:GetItemIcon()

            newFrame.iconName = itemName
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

            if not newFrame.iconName or newFrame.iconName == "" then
                newFrame.iconName = ""
            end

            local binding = addon:GetKeyBind(itemID, newFrame.iconName, spellID)
            if binding then
                textBinding:SetText(addon:ReplaceBindings(binding))
            end
        end)

        newFrame.iconName = ""
        textID:SetText(itemID)

        local _, itemSpellID = C_Item.GetItemSpell(itemID)
        if itemSpellID and itemSpellID > 0 then
            newFrame.spellID = itemSpellID
        end
    elseif spellID > 0 then
        local spellInfo = C_Spell.GetSpellInfo(spellID)

        newFrame.iconName = spellInfo.name
        textID:SetText(spellID)
        textureIcon:SetTexture(spellInfo.iconID)

        if not newFrame.iconName or newFrame.iconName == "" then
            newFrame.iconName = ""
        end

        local binding = addon:GetKeyBind(itemID, newFrame.iconName, spellID)
        if binding then
            textBinding:SetText(addon:ReplaceBindings(binding))
        end
    end

    newFrame.currentSpellID = spellID
    newFrame.frameBorder = frameBorder
    newFrame.frameCooldown = frameCooldown
    newFrame.itemID = itemID
    newFrame.specID = specID
    newFrame.spellID = spellID
    newFrame.textBinding = textBinding
    newFrame.textCharges = textCharges
    newFrame.textCooldown = textCooldown
    newFrame.textRank = textRank
    newFrame.textID = textID
    newFrame.textureIcon = textureIcon

    if not SpellsDB[specID] then
        SpellsDB[specID] = {}
    end

    if itemID > 0 then
        items[itemID] = newFrame
    else
        spells[spellID] = newFrame
    end
end

local function ProcessSpell(specID, spellIndex)
    local itemInfo = C_SpellBook.GetSpellBookItemInfo(spellIndex, Enum.SpellBookSpellBank.Player)
    if not itemInfo then
        return
    end

    if itemInfo.isPassive then
        return
    end

    if itemInfo.isOffSpec then
        return
    end

    if itemInfo.itemType ~= Enum.SpellBookItemType.Spell then
        return
    end

    CreateIconFrame(-1, specID, itemInfo.spellID)
end

local function RefreshIconFrames(name, parentTable)
    if not name then
        return
    end

    if not parentTable then
        return
    end

    if name == addon.ignored then
        if parentTable.spells and next(parentTable.spells) ~= nil then
            for index, iconFrame in ipairs(parentTable.spells) do
                iconFrame:ClearAllPoints()
                iconFrame:SetParent(parentTable.frame)

                iconFrame:Hide()
            end
        end

        if parentTable.items and next(parentTable.items) ~= nil then
            for index, iconFrame in ipairs(parentTable.items) do
                iconFrame:ClearAllPoints()
                iconFrame:SetParent(parentTable.frame)

                iconFrame:Hide()
            end
        end
    else
        local settingsTable = SettingsDB[name] or {}

        local allIcons = {}
        local anchor = settingsTable.anchor or "CENTER"
        local iconSize = settingsTable.iconSize or 64
        local iconSpacing = settingsTable.iconSpacing or 2
        local isVertical = settingsTable.isVertical or false
        local reverseSort = true
        local wrapAfter = settingsTable.wrapAfter or 0

        if isVertical then
            if anchor == "BOTTOM" or anchor == "BOTTOMLEFT" or anchor == "BOTTOMRIGHT" then
                reverseSort = false
            end
        else
            if anchor == "BOTTOMRIGHT" or anchor == "RIGHT" or anchor == "TOPRIGHT" then
                reverseSort = false
            end
        end

        if parentTable.spells and next(parentTable.spells) ~= nil then
            table.sort(parentTable.spells, function(a, b)
                if a.spellCooldown ~= b.spellCooldown then
                    if reverseSort then
                        return a.spellCooldown > b.spellCooldown
                    else
                        return a.spellCooldown < b.spellCooldown
                    end
                end

                if reverseSort then
                    return a.iconName > b.iconName
                else
                    return a.iconName < b.iconName
                end
            end)

            for index, iconFrame in ipairs(parentTable.spells) do
                table.insert(allIcons, iconFrame)
            end
        end

        if parentTable.items and next(parentTable.items) ~= nil then
            table.sort(parentTable.items, function(a, b)
                if a.spellCooldown ~= b.spellCooldown then
                    if reverseSort then
                        return a.spellCooldown > b.spellCooldown
                    else
                        return a.spellCooldown < b.spellCooldown
                    end
                end

                if a.spellCooldown ~= b.spellCooldown then
                    if reverseSort then
                        return a.iconName > b.iconName
                    else
                        return a.iconName < b.iconName
                    end
                end

                return a.itemID < b.itemID
            end)

            for index, iconFrame in ipairs(parentTable.items) do
                table.insert(allIcons, iconFrame)
            end
        end

        if allIcons and next(allIcons) ~= nil then
            for index, iconFrame in ipairs(allIcons) do
                if name == addon.unknown then
                    iconFrame.textID:Show()
                else
                    iconFrame.textID:Hide()
                end

                iconFrame:ClearAllPoints()
                iconFrame:SetParent(parentTable.frame)
                iconFrame:Show()

                iconFrame:SetSize(iconSize, iconSize)
                iconFrame.textureIcon:SetAllPoints(iconFrame)

                if index == 1 then
                    iconFrame:SetPoint("TOPLEFT", parentTable.frame, "TOPLEFT", 0, 0)
                else
                    local wrapIndex = (wrapAfter > 0) and ((index - 1) % wrapAfter == 0)
                    if wrapIndex then
                        local previousWrap = allIcons[index - wrapAfter]
                        if isVertical then
                            iconFrame:SetPoint("TOPLEFT", previousWrap, "TOPRIGHT", iconSpacing, 0)
                        else
                            iconFrame:SetPoint("TOPLEFT", previousWrap, "BOTTOMLEFT", 0, iconSpacing)
                        end
                    else
                        local previous = allIcons[index - 1]
                        if isVertical then
                            iconFrame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, iconSpacing)
                        else
                            iconFrame:SetPoint("TOPLEFT", previous, "TOPRIGHT", iconSpacing, 0)
                        end
                    end
                end
            end
        end

        local height, width
        local numIcons = #allIcons

        if wrapAfter > 0 then
            if isVertical then
                local numCols = math.ceil(numIcons / wrapAfter)
                local numRows = math.min(wrapAfter, numIcons)

                width = iconSize * numCols + iconSpacing * (numCols - 1)
                height = iconSize * numRows + iconSpacing * (numRows - 1)
            else
                local numRows = math.ceil(numIcons / wrapAfter)
                local numCols = math.min(wrapAfter, numIcons)

                width = iconSize * numCols + iconSpacing * (numCols - 1)
                height = iconSize * numRows + iconSpacing * (numRows - 1)
            end
        else
            if isVertical then
                height = iconSize * numIcons + iconSpacing * (numIcons - 1)
                width = iconSize
            else
                height = iconSize
                width = iconSize * numIcons + iconSpacing * (numIcons - 1)
            end
        end

        parentTable.frame:SetSize(width, height)
    end
end

local function RefreshIconsItem()
    for _, itemID in ipairs(SettingsDB.validItems) do
        CreateIconFrame(itemID, 0, -1)
    end
end

local function RefreshIconsSpell()
    local currentSpec = GetSpecialization()
    if not currentSpec then
        return
    end

    local playerSpecID = GetSpecializationInfo(currentSpec)
    if not playerSpecID then
        return
    end

    for spellID, iconFrame in pairs(spells) do
        iconFrame:ClearAllPoints()
        iconFrame:Hide()
        iconFrame:SetParent(nil)

        iconFrame = nil
    end
    wipe(spells)
    spells = {}

    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() + 1 do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

        if lineInfo then
            if lineInfo.name == "General" then
                for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                    ProcessSpell(0, j)
                end
            else
                if lineInfo.specID then
                    if lineInfo.specID == playerSpecID then
                        for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                            ProcessSpell(playerSpecID, j)
                        end
                    end
                else
                    for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                        ProcessSpell(playerSpecID, j)
                    end
                end
            end
        end
    end
end

local function updateIconAura(frame, spellID)
    frame.textureIcon:SetDesaturated(false)
    frame.textureIcon:SetVertexColor(1, 1, 1)

    if spellID <= 0 then
        return
    end

    local playerAura = C_UnitAuras.GetPlayerAuraBySpellID(SettingsDB.buffOverrides[spellID] or spellID)

    if playerAura and playerAura.isFromPlayerOrPlayerPet then
        local remaining = playerAura.expirationTime - GetTime()

        if playerAura.applications and playerAura.applications > 0 then
            frame.textCharges:SetText(playerAura.applications)
        elseif playerAura.charges and playerAura.charges > 0 then
            frame.textCharges:SetText(playerAura.charges)
        else
            frame.textCharges:SetText("")
        end

        if remaining > 0 then
            frame.textCooldown:SetText(string.format("%d", remaining))
            frame.textCooldown:SetTextColor(0, 1, 0, 1)
        else
            frame.textCooldown:SetText("")
        end

        frame.auraActive = true
        frame.textureIcon:SetVertexColor(0, 1, 0)
    else
        frame.auraActive = false
    end
end

local function updateIconItem(frame, name)
    frame.frameBorder:Hide()

    if name == addon.ignored or name == addon.unknown then
        return
    end

    local settingsTable = SettingsDB[name] or {}

    local itemID = frame.itemID or 0
    local showOnCooldown = settingsTable.showOnCooldown or false
    local spellID = frame.spellID or 0

    local count = C_Item.GetItemCount(itemID, false, true, false, false)
    if count <= 0 then
        frame:Hide()
        return
    end

    if showOnCooldown then
        frame:Hide()
    else
        frame:Show()
    end

    updateIconAura(frame, spellID)

    if frame.auraActive then
        if not frame.glowActive then
            ActionButton_ShowOverlayGlow(frame)
            frame.glowActive = true
        end

        return
    end

    if frame.glowActive then
        ActionButton_HideOverlayGlow(frame)
        frame.glowActive = false
    end

    local startTime, duration, enable = C_Container.GetItemCooldown(itemID)
    if enable == 1 and duration > 2 then
        local remaining = (startTime + duration) - GetTime()

        if remaining > 0 then
            frame.frameBorder:Show()
            frame.textBinding:Hide()
            frame.textureIcon:SetDesaturated(true)
            frame:Show()

            if remaining < 90 then
                frame.textCooldown:SetText(string.format("%d", remaining))
                frame.textCooldown:SetTextColor(1, 0, 0, 1)
            else
                frame.textCooldown:SetText("")
            end

            frame.textureIcon:SetDesaturated(true)
            frame.textureIcon:SetVertexColor(1, 0, 0)
        else
            frame.textCooldown:SetText("")
        end
    else
        frame.textCooldown:SetText("")
    end

    frame.textCharges:SetText(count)
end

local function updateIconSpell(frame, gcdCooldown, name)
    frame.frameBorder:Hide()

    if name == addon.ignored or name == addon.unknown then
        return
    end

    local frameSpellID = frame.spellID or 0
    local glowActive = false

    local currentSpellID = C_Spell.GetOverrideSpell(frameSpellID) or frameSpellID

    if C_Spell.IsSpellDisabled(currentSpellID) then
        frame:Hide()
        return
    end

    local settingsTable = SettingsDB[name] or {}

    local isUsable, insufficientPower = C_Spell.IsSpellUsable(currentSpellID)
    local showOnCooldown = settingsTable.showOnCooldown or false
    local showWhenAvailable = settingsTable.showWhenAvailable or false
    local spellCharges = C_Spell.GetSpellCharges(currentSpellID)

    if showOnCooldown or showWhenAvailable then
        frame:Hide()
    else
        frame:Show()
    end

    if showWhenAvailable then
        if spellCharges and spellCharges.maxCharges > 1 then
            frame.textCharges:SetText(spellCharges.currentCharges)

            if spellCharges.currentCharges > 0 then
                frame:Show()
            end
        else
            local spellCooldown = C_Spell.GetSpellCooldown(currentSpellID)
            if spellCooldown.isEnabled and spellCooldown.duration > 2 then
            else
                frame:Show()
            end
        end
    else
        updateIconAura(frame, currentSpellID)

        if frame.auraActive then
            if not frame.glowActive then
                ActionButton_ShowOverlayGlow(frame)
                frame.glowActive = true
            end

            frame:Show()

            return
        end

        frame.textBinding:Show()
        frame.textCooldown:SetText("")

        if frameSpellID ~= currentSpellID then
            updateIconAura(frame, frameSpellID)

            if frame.auraActive then
                if not frame.glowActive then
                    ActionButton_ShowOverlayGlow(frame)
                    frame.glowActive = true
                end

                frame:Show()

                return
            end
        end

        if currentSpellID ~= frame.currentSpellID then
            local spellInfo = C_Spell.GetSpellInfo(currentSpellID)

            frame.currentSpellID = currentSpellID
            frame.textureIcon:SetTexture(spellInfo.iconID)

            if currentSpellID ~= frameSpellID then
                glowActive = true
            end
        end

        if spellCharges and spellCharges.maxCharges > 1 then
            frame.textCharges:SetText(spellCharges.currentCharges)

            if spellCharges.currentCharges <= 0 then
                frame.frameBorder:Show()
                frame.textBinding:Hide()
                frame.textureIcon:SetDesaturated(true)
                frame:Show()

                if spellCharges.cooldownStartTime and spellCharges.cooldownDuration and spellCharges.cooldownDuration > 2 then
                    local remaining = (spellCharges.cooldownStartTime + spellCharges.cooldownDuration) - GetTime()
                    if remaining > 0 then
                        if remaining < 90 then
                            frame.textCooldown:SetText(string.format("%d", remaining))
                            frame.textCooldown:SetTextColor(1, 0, 0, 1)
                        else
                            frame.textCooldown:SetText("")
                        end
                    end
                end
            elseif spellCharges.currentCharges < spellCharges.maxCharges then
                frame.frameBorder:Show()
                frame:Show()
            else
                if not isUsable then
                    if insufficientPower then
                        frame.textureIcon:SetVertexColor(0.5, 0.5, 1)
                    else
                        frame.textureIcon:SetVertexColor(1, 0, 0)
                    end
                end
            end
        else
            local spellCooldown = C_Spell.GetSpellCooldown(currentSpellID)
            if spellCooldown.isEnabled and spellCooldown.duration > 2 then
                local remaining = (spellCooldown.startTime + spellCooldown.duration) - GetTime()
                if remaining > 0 then
                    frame.frameBorder:Show()
                    frame.textBinding:Hide()
                    frame.textureIcon:SetDesaturated(true)
                    frame:Show()

                    if remaining < 90 then
                        frame.textCooldown:SetText(string.format("%d", remaining))
                        frame.textCooldown:SetTextColor(1, 0, 0, 1)
                    else
                        frame.textCooldown:SetText("")
                    end
                end
            else
                if not isUsable then
                    if insufficientPower then
                        frame.textureIcon:SetVertexColor(0.5, 0.5, 1)
                    else
                        frame.textureIcon:SetVertexColor(1, 0, 0)
                    end
                end
            end
        end

        if SettingsDB.showGlobalSweep and frame.cooldownFrame then
            if gcdCooldown.isEnabled and gcdCooldown.duration > 0 then
                CooldownFrame_Set(frame.cooldownFrame, gcdCooldown.startTime, gcdCooldown.duration, true)
            else
                frame.cooldownFrame:Clear()
            end
        end

        if glowActive and not frame.glowActive then
            ActionButton_ShowOverlayGlow(frame)
            frame.glowActive = true
        end

        if not glowActive and frame.glowActive then
            ActionButton_HideOverlayGlow(frame)
            frame.glowActive = false
        end
    end
end

function addon:CreateCategoryFrames()
    local validCategories = addon:GetValidCategories(true)

    for index, name in ipairs(validCategories) do
        if not categories[name] then
            local parentTable = {}
            parentTable.frame = addon:GetFrame(name)
            parentTable.items = {}
            parentTable.spells = {}

            categories[name] = parentTable
        end
    end

    if not categories[addon.ignored] then
        local parentTable = {}
        parentTable.frame = addon:GetFrame(addon.ignored)
        parentTable.items = {}
        parentTable.spells = {}

        categories[addon.ignored] = parentTable
    end

    if not categories[addon.unknown] then
        local parentTable = {}
        parentTable.frame = addon:GetFrame(addon.unknown)
        parentTable.items = {}
        parentTable.spells = {}

        categories[addon.unknown] = parentTable
    end

    RefreshIconsItem()
    RefreshIconsSpell()

    addon:RefreshCategoryFrames(true, true)
end

function addon:RefreshItems()
    RefreshIconsItem()

    addon:RefreshCategoryFrames(true, false)
end

function addon:RefreshSpells()
    RefreshIconsSpell()

    addon:RefreshCategoryFrames(false, true)
end

function addon:RefreshCategoryFrames(doItems, doSpells)
    local validCategories = addon:GetValidCategories(true)

    for index, name in ipairs(validCategories) do
        if categories[name] then
            local parentTable = categories[name]
            if doItems then
                parentTable.items = {}
            end
            if doSpells then
                parentTable.spells = {}
            end
        else
            local parentTable = {}
            parentTable.frame = addon:GetFrame(name)
            if doItems then
                parentTable.items = {}
            end
            if doSpells then
                parentTable.spells = {}
            end

            categories[name] = parentTable
        end
    end

    if doItems then
        for itemID, iconFrame in pairs(items) do
            local settingName = itemID .. "_-1"
            local category = SpellsDB[iconFrame.specID][settingName]
            if not category or category == "" then
                category = addon.unknown
            end

            local count = C_Item.GetItemCount(itemID, false, true, false, false)
            if count <= 0 then
                table.insert(categories[addon.ignored].items, iconFrame)
            else
                table.insert(categories[category].items, iconFrame)
            end
        end
    end

    if doSpells then
        for spellID, iconFrame in pairs(spells) do
            local settingName = "-1_" .. spellID
            local category = SpellsDB[iconFrame.specID][settingName]
            if not category or category == "" then
                category = addon.unknown
            end

            table.insert(categories[category].spells, iconFrame)
        end
    end

    for index, name in ipairs(validCategories) do
        if categories[name] then
            local parentTable = categories[name]
            if doItems and parentTable.items and next(parentTable.items) ~= nil then
                RefreshIconFrames(name, parentTable)
            elseif doSpells and parentTable.spells and next(parentTable.spells) ~= nil then
                RefreshIconFrames(name, parentTable)
            end
            addon:FrameRestore(name, parentTable.frame)
        end
    end
end

function addon:UpdateAllIcons()
    local gcdCooldown = C_Spell.GetSpellCooldown(61304)

    for _, name in ipairs(addon:GetValidCategories(true)) do
        if categories[name] then
            local parentTable = categories[name]

            if parentTable.items then
                for _, iconFrame in ipairs(parentTable.items) do
                    updateIconItem(iconFrame, name)
                end
            end

            if parentTable.spells then
                for _, iconFrame in ipairs(parentTable.spells) do
                    updateIconSpell(iconFrame, gcdCooldown, name)
                end
            end
        end
    end
end
