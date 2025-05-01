local addonName, addon = ...
local categoryIcons = {}
local categoryFrames = {}
local updateInterval = 0.25

local LSM = LibStub("LibSharedMedia-3.0")
local font = LSM:Fetch("font", "Naowh") or "Fonts\\FRIZQT__.TTF"

local function CleanupOldButtons()
    for name, icons in pairs(categoryIcons) do
        for index, icon in ipairs(icons) do
            if icon then
                icon:ClearAllPoints()
                icon:Hide()
                icon:SetParent(nil)

                icon = nil
            end
        end
    end

    for name, frames in pairs(categoryFrames) do
        for index, frame in ipairs(frames) do
            if frame then
                frame:ClearAllPoints()
                frame:Hide()
                frame:SetScript("OnUpdate", nil)
                frame:SetParent(nil)
                frame:UnregisterAllEvents()

                for _, child in ipairs({ frame:GetChildren() }) do
                    child:SetParent(nil)
                    child:Hide()
                end

                frame = nil
            end
        end
    end

    wipe(categoryIcons)
    wipe(categoryFrames)
end

local function IconCreate(itemID, specID, spellID)
    itemID = itemID or -1
    specID = specID or -1
    spellID = spellID or -1

    local settingName = itemID .. "_" .. spellID

    if not SpellsDB[specID] then
        SpellsDB[specID] = {}
    end

    local category = SpellsDB[specID][settingName]
    if not category or category == "" then
        category = "Unknown"
    end
    if category == "Ignored" then
        return
    end
    if not categoryIcons[category] then
        categoryIcons[category] = {}
    end

    local iconFrame = CreateFrame("Frame", nil, UIParent)
    iconFrame:SetSize(40, 40)
    iconFrame:SetPoint("CENTER", 0, 0)

    local newIcon, newName
    if itemID > 0 then
        local count = C_Item.GetItemCount(itemID, false, true, false, false)
        if count <= 0 then
            return
        end

        local itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = C_Item.GetItemInfo(itemID)

        if itemLink then
            local qualityTier = itemLink:match("|A:Professions%-ChatIcon%-Quality%-Tier(%d+)")

            if qualityTier then
                local rankText = iconFrame:CreateFontString(nil, "OVERLAY")
                rankText:SetFont(font, 16, "OUTLINE")
                rankText:SetTextColor(1, 1, 1, 1)
                rankText:SetShadowOffset(0, 0)
                rankText:SetShadowColor(0, 0, 0, 1)
                rankText:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)

                if qualityTier == "1" then
                    rankText:SetText("*")
                elseif qualityTier == "2" then
                    rankText:SetText("**")
                elseif qualityTier == "3" then
                    rankText:SetText("***")
                else
                    rankText:SetText("")
                end
            end
        end

        if itemName then
            newName = itemName
        end

        if itemTexture then
            newIcon = itemTexture
        end

        local _, itemSpellID = C_Item.GetItemSpell(itemID)
        if itemSpellID and itemSpellID > 0 then
            spellID = itemSpellID
        end
    end

    if spellID > 0 then
        local spellInfo = C_Spell.GetSpellInfo(spellID)

        if not newIcon or newIcon == "" then
            newIcon = spellInfo.iconID
        end

        if not newName or newName == "" then
            newName = spellInfo.name
        end
    end

    if not newName or newName == "" then
        return
    end

    local bindText = iconFrame:CreateFontString(nil, "OVERLAY")
    bindText:SetFont(font, 12, "OUTLINE")
    bindText:SetTextColor(1, 1, 1, 1)
    bindText:SetShadowOffset(0, 0)
    bindText:SetShadowColor(0, 0, 0, 1)
    bindText:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 0, 0)
    if category == "Unknown" then
        bindText:SetText(tostring(spellID))
    else
        bindText:SetText("")
    end

    local cooldownFrame = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
    cooldownFrame:SetAllPoints(iconFrame)

    local cooldownText = iconFrame:CreateFontString(nil, "OVERLAY")
    cooldownText:SetFont(font, 16, "OUTLINE")
    cooldownText:SetPoint("CENTER")
    cooldownText:SetShadowOffset(0, 0)
    cooldownText:SetShadowColor(0, 0, 0, 1)
    cooldownText:SetText("")
    cooldownText:SetTextColor(1, 1, 1, 1)

    local chargeText = iconFrame:CreateFontString(nil, "OVERLAY")
    chargeText:SetFont(font, 12, "OUTLINE")
    chargeText:SetTextColor(1, 1, 1, 1)
    chargeText:SetShadowOffset(0, 0)
    chargeText:SetShadowColor(0, 0, 0, 1)
    chargeText:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
    chargeText:SetText("")

    local spellIcon = iconFrame:CreateTexture(nil, "ARTWORK")
    spellIcon:SetAllPoints(iconFrame)
    spellIcon:SetTexture(newIcon)

    local binding = addon:GetKeyBind(itemID, newName:lower():gsub("%s+", ""), spellID)
    if binding then
        binding = binding:gsub("ALT%-", "A+")
        binding = binding:gsub("%BUTTON", "M")
        binding = binding:gsub("CTRL%-", "C+")
        binding = binding:gsub("NUMPAD", "N")
        binding = binding:gsub("SHIFT%-", "S+")

        bindText:SetText(binding)
    end

    local baseChargeInfo = C_Spell.GetSpellCharges(spellID)
    local spellCooldown

    if baseChargeInfo then
        spellCooldown = baseChargeInfo.cooldownDuration * 1000
    else
        local cooldownMS, gcdMS = GetSpellBaseCooldown(spellID)
        if cooldownMS and cooldownMS > 0 then
            spellCooldown = cooldownMS
        else
            spellCooldown = 0
        end
    end

    iconFrame.bindText = bindText
    iconFrame.chargeText = chargeText
    iconFrame.cooldownFrame = cooldownFrame
    iconFrame.cooldownText = cooldownText
    iconFrame.currentSpellID = spellID
    iconFrame.iconName = newName
    iconFrame.itemID = itemID
    iconFrame.spellCooldown = spellCooldown
    iconFrame.spellIcon = spellIcon
    iconFrame.spellID = spellID

    table.insert(categoryIcons[category], iconFrame)
end

local function IconUpdate(gcdCooldown, frame, name)
    local itemID = frame.itemID or 0
    local spellID = frame.spellID or 0

    if itemID > 0 then
        local count = C_Item.GetItemCount(itemID, false, true, false, false)

        if count <= 0 then
            frame:Hide()
            return
        end

        frame:Show()

        if spellID > 0 then
            local playerAura = C_UnitAuras.GetPlayerAuraBySpellID(addon.buffOverrides[spellID] or spellID)

            if playerAura and playerAura.isFromPlayerOrPlayerPet then
                local remaining = playerAura.expirationTime - GetTime()

                frame.spellIcon:SetDesaturated(false)

                if playerAura.charges and playerAura.charges > 0 then
                    frame.chargeText:SetText(tostring(playerAura.charges))
                else
                    frame.chargeText:SetText("")
                end

                if remaining > 0 then
                    frame.cooldownText:SetText(string.format("%d", remaining))
                    frame.cooldownText:SetTextColor(0, 1, 0, 1)
                else
                    frame.cooldownText:SetText("")
                end

                if not frame.isGlowing then
                    ActionButton_ShowOverlayGlow(frame)
                    frame.isGlowing = true
                end
            else
                if frame.isGlowing then
                    ActionButton_HideOverlayGlow(frame)
                    frame.isGlowing = false
                end
            end
        end

        if not frame.isGlowing then
            local startTime, duration, enable = C_Container.GetItemCooldown(itemID)
            if enable == 1 and duration > 1.5 then
                local remaining = (startTime + duration) - GetTime()

                if remaining > 0 then
                    if remaining < 90 then
                        frame.cooldownText:SetText(string.format("%d", remaining))
                        frame.cooldownText:SetTextColor(1, 0, 0, 1)
                    else
                        frame.cooldownText:SetText("")
                    end

                    frame.spellIcon:SetDesaturated(true)
                else
                    frame.cooldownText:SetText("")
                    frame.spellIcon:SetDesaturated(false)
                end
            else
                frame.cooldownText:SetText("")
                frame.spellIcon:SetDesaturated(false)
            end

            frame.chargeText:SetText(tostring(count))
        end
    elseif spellID > 0 then
        local playerAura = C_UnitAuras.GetPlayerAuraBySpellID(addon.buffOverrides[spellID] or spellID)

        if playerAura and playerAura.isFromPlayerOrPlayerPet then
            local remaining = playerAura.expirationTime - GetTime()
            frame:Show()

            frame.spellIcon:SetDesaturated(false)

            if playerAura.charges and playerAura.charges > 0 then
                frame.chargeText:SetText(tostring(playerAura.charges))
            else
                frame.chargeText:SetText("")
            end

            if remaining > 0 then
                frame.cooldownText:SetText(string.format("%d", remaining))
                frame.cooldownText:SetTextColor(0, 1, 0, 1)
            else
                frame.cooldownText:SetText("")
            end

            if not frame.isGlowing then
                ActionButton_ShowOverlayGlow(frame)
                frame.isGlowing = true
            end
        else
            if frame.isGlowing then
                ActionButton_HideOverlayGlow(frame)
                frame.isGlowing = false
            end

            local currentSpellID = C_Spell.GetOverrideSpell(frame.spellID) or frame.spellID
            if currentSpellID ~= frame.currentSpellID then
                local spellInfo = C_Spell.GetSpellInfo(currentSpellID)

                frame.currentSpellID = currentSpellID
                frame.spellIcon:SetTexture(spellInfo.iconID)

                if currentSpellID == frame.spellID then
                    ActionButton_HideOverlayGlow(frame)
                else
                    ActionButton_ShowOverlayGlow(frame)
                end
            end

            local chargeInfo = C_Spell.GetSpellCharges(currentSpellID)
            local onCooldown = false

            if chargeInfo and chargeInfo.maxCharges > 1 then
                frame.chargeText:SetText(tostring(chargeInfo.currentCharges))

                if chargeInfo.currentCharges <= 0 then
                    onCooldown = true
                end

                if chargeInfo.currentCharges < chargeInfo.maxCharges and chargeInfo.cooldownStartTime and chargeInfo.cooldownDuration and chargeInfo.cooldownDuration > 1.5 then
                    local remaining = (chargeInfo.cooldownStartTime + chargeInfo.cooldownDuration) -
                        GetTime()
                    if remaining > 0 then
                        if remaining < 90 then
                            frame.cooldownText:SetText(string.format("%d", remaining))
                            frame.cooldownText:SetTextColor(1, 0, 0, 1)
                        else
                            frame.cooldownText:SetText("")
                        end
                        onCooldown = true
                    end
                end
            else
                local spellCooldown = C_Spell.GetSpellCooldown(currentSpellID)
                if spellCooldown.isEnabled and spellCooldown.duration > 1.5 then
                    local remaining = (spellCooldown.startTime + spellCooldown.duration) - GetTime()
                    if remaining > 0 then
                        if remaining < 90 then
                            frame.cooldownText:SetText(string.format("%d", remaining))
                            frame.cooldownText:SetTextColor(1, 0, 0, 1)
                        else
                            frame.cooldownText:SetText("")
                        end
                        onCooldown = true
                    end
                end
            end

            if onCooldown then
                if name == "Important" then
                    frame:Show()
                end

                frame.bindText:Hide()
                frame.spellIcon:SetDesaturated(true)
            else
                if name == "Important" then
                    frame:Hide()
                end

                frame.bindText:Show()
                frame.cooldownText:SetText("")
                frame.spellIcon:SetDesaturated(false)
            end

            if SettingsDB.showGlobalSweep and frame.cooldownFrame then
                if gcdCooldown.isEnabled and gcdCooldown.duration > 0 then
                    CooldownFrame_Set(frame.cooldownFrame, gcdCooldown.startTime, gcdCooldown.duration, true)
                else
                    frame.cooldownFrame:Clear()
                end
            end
        end
    else
        frame:Hide()
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

    IconCreate(-1, specID, itemInfo.spellID)
end

local function RefreshIconFrames(name, parentFrame)
    if not name then
        return
    end

    if not parentFrame then
        return
    end

    local icons = categoryIcons[name]
    if not icons then
        return
    end

    local settingsTable = SettingsDB[name] or {}
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

    table.sort(icons, function(a, b)
        local function isItemIcon(frame)
            return frame.itemID > 0
        end

        if isItemIcon(a) ~= isItemIcon(b) then
            if reverseSort then
                return not isItemIcon(a)
            else
                return isItemIcon(a)
            end
        end

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

    for index, iconFrame in ipairs(icons) do
        iconFrame:ClearAllPoints()
        iconFrame:SetParent(parentFrame)

        iconFrame:SetSize(iconSize, iconSize)
        iconFrame.spellIcon:SetAllPoints(iconFrame)

        if index == 1 then
            iconFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
        else
            local wrapIndex = (wrapAfter > 0) and ((index - 1) % wrapAfter == 0)
            if wrapIndex then
                local previousWrap = icons[index - wrapAfter]
                if isVertical then
                    iconFrame:SetPoint("TOPLEFT", previousWrap, "TOPRIGHT", iconSpacing, 0)
                else
                    iconFrame:SetPoint("TOPLEFT", previousWrap, "BOTTOMLEFT", 0, iconSpacing)
                end
            else
                local previous = icons[index - 1]
                if isVertical then
                    iconFrame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, iconSpacing)
                else
                    iconFrame:SetPoint("TOPLEFT", previous, "TOPRIGHT", iconSpacing, 0)
                end
            end
        end
    end

    local height, width
    local numIcons = #icons

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

    parentFrame:SetSize(width, height)
end

function addon:CreateIcons()
    CleanupOldButtons()

    local currentSpec = GetSpecialization()
    if not currentSpec then
        return
    end

    local playerSpecID = GetSpecializationInfo(currentSpec)
    if not playerSpecID then
        return
    end

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

    if addon.forcedSpellsBySpellID[playerSpecID] then
        for spellID, forcedSpellID in pairs(addon.forcedSpellsBySpellID[playerSpecID]) do
            if IsSpellKnown(spellID, false) then
                IconCreate(-1, playerSpecID, forcedSpellID)
            end
        end
    end

    if addon.forcedSpellsByHeroTree[playerSpecID] then
        local playerHeroTalentSpec = C_ClassTalents.GetActiveHeroTalentSpec()

        local spells = addon.forcedSpellsByHeroTree[playerSpecID] and
            addon.forcedSpellsByHeroTree[playerSpecID][playerHeroTalentSpec]
        if spells then
            for _, forcedSpellID in ipairs(spells) do
                IconCreate(-1, playerSpecID, forcedSpellID)
            end
        end
    end

    for _, itemID in ipairs(SettingsDB.validItems) do
        IconCreate(itemID, 0, -1)
    end

    for index, name in ipairs(SettingsDB.validCategories) do
        local newFrame = addon:FrameCreate(name)
        local timeSinceLastUpdate = 0

        RefreshIconFrames(name, newFrame)
        addon:FrameRestore(name, newFrame)

        newFrame:SetScript("OnUpdate", function(frame, elapsed)
            local icons = categoryIcons[name]
            if not icons then
                return
            end

            timeSinceLastUpdate = timeSinceLastUpdate + elapsed
            if timeSinceLastUpdate < updateInterval then
                return
            end

            local gcdCooldown = C_Spell.GetSpellCooldown(61304)

            for index, icon in ipairs(icons) do
                IconUpdate(gcdCooldown, icon, name)
            end

            timeSinceLastUpdate = 0
        end)

        categoryFrames[name] = newFrame
    end

    local unknownFrame = addon:FrameCreate("Unknown")
    RefreshIconFrames("Unknown", unknownFrame)
    addon:FrameRestore("Unknown", unknownFrame)
    categoryFrames["Unknown"] = unknownFrame
end
