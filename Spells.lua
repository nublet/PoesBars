local addonName, addon = ...

local categories = {}
local iconFrames = {}

local LSM = LibStub("LibSharedMedia-3.0")
local font = LSM:Fetch("font", "Naowh") or "Fonts\\FRIZQT__.TTF"

local function CreateIconFrame(iconDetail)
    local itemID = iconDetail.itemID or -1
    local specID = iconDetail.specID or -1
    local spellID = iconDetail.spellID or -1

    if itemID <= 0 and spellID <= 0 then
        return nil
    end

    local newFrame = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    newFrame:EnableKeyboard(false)
    newFrame:EnableMouse(false)
    newFrame:EnableMouseWheel(false)
    newFrame:Hide()
    newFrame:SetHitRectInsets(0, 0, 0, 0)
    newFrame:SetPoint("CENTER", 0, 0)
    newFrame:SetPropagateKeyboardInput(true)
    newFrame:SetSize(40, 40)
    if itemID > 0 then
        newFrame:SetAttribute("type", "item")
        newFrame:SetAttribute("item", "item:" .. itemID)
        newFrame:SetScript("OnEnter", function(control)
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemID)
            GameTooltip:Show()
        end)
    else
        newFrame:SetAttribute("type", "spell")
        newFrame:SetAttribute("spell", spellID)
        newFrame:SetScript("OnEnter", function(control)
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(spellID)
            GameTooltip:Show()
        end)
    end
    newFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local frameBorder = CreateFrame("Frame", nil, newFrame, "BackdropTemplate")
    frameBorder:EnableKeyboard(false)
    frameBorder:EnableMouse(false)
    frameBorder:EnableMouseWheel(false)
    frameBorder:SetAllPoints(newFrame)
    frameBorder:SetBackdrop({ edgeFile = "Interface/Buttons/WHITE8x8", edgeSize = 1, })
    frameBorder:SetBackdropBorderColor(1, 0, 0, 1)
    frameBorder:SetFrameLevel(newFrame:GetFrameLevel() + 1)
    frameBorder:SetPropagateKeyboardInput(true)
    frameBorder:SetToplevel(false)

    local frameCooldown = CreateFrame("Cooldown", nil, newFrame, "CooldownFrameTemplate")
    frameCooldown:EnableKeyboard(false)
    frameCooldown:EnableMouse(false)
    frameCooldown:EnableMouseWheel(false)
    frameCooldown:SetAllPoints(newFrame)
    frameCooldown:SetPropagateKeyboardInput(true)
    frameCooldown:SetToplevel(false)

    local textBinding = newFrame:CreateFontString(nil, "OVERLAY")
    textBinding:SetFont(font, SettingsDB.bindingFontSize or 12, SettingsDB.bindingFontFlags or "OUTLINE")
    textBinding:SetPoint("TOPRIGHT", newFrame, "TOPRIGHT", 0, 0)
    textBinding:SetText("")
    textBinding:SetTextColor(1, 1, 1, 1)
    if SettingsDB.bindingFontShadow then
        textBinding:SetShadowColor(0, 0, 0, 0.5)
        textBinding:SetShadowOffset(1, -1)
    end

    local textCharges = newFrame:CreateFontString(nil, "OVERLAY")
    textCharges:SetFont(font, SettingsDB.chargesFontSize or 12, SettingsDB.chargesFontFlags or "OUTLINE")
    textCharges:SetTextColor(1, 1, 1, 1)
    textCharges:SetShadowColor(0, 0, 0, 1)
    textCharges:SetShadowOffset(0, 0)
    textCharges:SetPoint("BOTTOMRIGHT", newFrame, "BOTTOMRIGHT", 0, 0)
    textCharges:SetText("")
    if SettingsDB.chargesFontShadow then
        textCharges:SetShadowColor(0, 0, 0, 0.5)
        textCharges:SetShadowOffset(1, -1)
    end

    local textCooldown = newFrame:CreateFontString(nil, "OVERLAY")
    textCooldown:SetFont(font, SettingsDB.cooldownFontSize or 16, SettingsDB.cooldownFontFlags or "OUTLINE")
    textCooldown:SetPoint("CENTER", newFrame, "CENTER", 0, 0)
    textCooldown:SetText("")
    textCooldown:SetTextColor(1, 1, 1, 1)
    if SettingsDB.cooldownFontShadow then
        textCooldown:SetShadowColor(0, 0, 0, 0.5)
        textCooldown:SetShadowOffset(1, -1)
    end

    local textRank = newFrame:CreateFontString(nil, "OVERLAY")
    textRank:SetFont(font, SettingsDB.rankFontSize or 12, SettingsDB.rankFontFlags or "OUTLINE")
    textRank:SetPoint("BOTTOMLEFT", newFrame, "BOTTOMLEFT", 0, 0)
    textRank:SetText("")
    textRank:SetTextColor(0, 1, 0, 1)
    if SettingsDB.rankFontShadow then
        textRank:SetShadowColor(0, 0, 0, 0.5)
        textRank:SetShadowOffset(1, -1)
    end

    local textID = newFrame:CreateFontString(nil, "OVERLAY")
    textID:SetFont(font, SettingsDB.bindingFontSize or 12, SettingsDB.bindingFontFlags or "OUTLINE")
    textID:SetPoint("CENTER", newFrame, "CENTER", 0, 0)
    textID:SetText("")
    textID:SetTextColor(1, 1, 1, 1)
    if SettingsDB.cooldownFontShadow then
        textID:SetShadowColor(0, 0, 0, 0.5)
        textID:SetShadowOffset(1, -1)
    end

    local textureIcon = newFrame:CreateTexture(nil, "ARTWORK")
    textureIcon:SetAllPoints(newFrame)

    if itemID > 0 then
        newFrame.iconName = ""
        newFrame.isHarmful = false
        textID:SetText(tostring(itemID))

        local _, itemSpellID = C_Item.GetItemSpell(itemID)
        if itemSpellID and itemSpellID > 0 then
            newFrame.spellID = itemSpellID

            local baseChargeInfo = C_Spell.GetSpellCharges(itemSpellID)
            if baseChargeInfo then
                newFrame.spellCooldown = baseChargeInfo.cooldownDuration * 1000
            else
                local cooldownMS, gcdMS = GetSpellBaseCooldown(itemSpellID)
                if cooldownMS and cooldownMS > 0 then
                    newFrame.spellCooldown = cooldownMS
                else
                    newFrame.spellCooldown = 0
                end
            end
        end

        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function()
            local itemName = item:GetItemName()
            local itemLink = item:GetItemLink()
            local itemTexture = item:GetItemIcon()

            newFrame.iconID = itemTexture
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
        end)
    elseif spellID > 0 then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            newFrame.iconID = spellInfo.iconID
            newFrame.iconName = spellInfo.name
            textureIcon:SetTexture(spellInfo.iconID)
        else
            local newSpellID = C_Spell.GetOverrideSpell(spellID) or spellID
            if newSpellID and newSpellID ~= spellID then
                spellInfo = C_Spell.GetSpellInfo(newSpellID)
                if spellInfo then
                    spellID = newSpellID
                    newFrame.iconID = spellInfo.iconID
                    newFrame.iconName = spellInfo.name
                    textureIcon:SetTexture(spellInfo.iconID)
                end
            end
        end

        textID:SetText(tostring(spellID))

        if not newFrame.iconName or newFrame.iconName == "" then
            newFrame.iconName = ""
        end

        if C_Spell.IsSpellHarmful(spellID) then
            newFrame.isHarmful = true
        else
            newFrame.isHarmful = false
        end

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
    end

    newFrame.currentSpellID = spellID
    newFrame.frameBorder = frameBorder
    newFrame.frameCooldown = frameCooldown
    newFrame.itemID = itemID
    newFrame.settingName = itemID .. "_" .. spellID
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

    return newFrame
end

local function GetAura(auraList, spellID, spellName)
    if not auraList then
        return nil
    end

    for i = 1, #auraList do
        local aura = auraList[i]
        if aura.spellId == spellID or aura.name == spellName then
            if spellName == "Ascendance" then
                if aura.spellId == 457594 or aura.spellId == 458573 or aura.spellId == 463003 or aura.spellId == 463095 then
                else
                    return aura
                end
            else
                return aura
            end
        end
    end

    return nil
end

local function GetTotem(playerTotems, spellID, spellName)
    if not playerTotems then
        return nil
    end

    for i = 1, #playerTotems do
        local totem = playerTotems[i]
        if totem.spellID == spellID or totem.totemName == spellName then
            return totem
        end
    end

    return nil
end

local function IsAuraActiveBuff(frame, playerBuffs, spellID)
    if spellID <= 0 then
        return
    end

    local aura = GetAura(playerBuffs, spellID, frame.iconName)

    if aura then
        if aura.applications and aura.applications > 0 then
            frame.auraStacks = aura.applications
        elseif aura.charges and aura.charges > 0 then
            frame.auraStacks = aura.charges
        end

        if aura.expirationTime <= 0 then
            frame.auraIcon = aura.icon or -1
            return true
        else
            local remaining = aura.expirationTime - GetTime()

            if remaining > 0 then
                frame.auraIcon = aura.icon or -1
                frame.auraRemaining = remaining

                return true
            end
        end
    end

    return false
end

local function IsAuraActiveDebuff(frame, spellID, targetDebuffs)
    if spellID <= 0 then
        return
    end

    local aura = GetAura(targetDebuffs, spellID, frame.iconName)

    if aura then
        if aura.applications and aura.applications > 0 then
            frame.auraStacks = aura.applications
        elseif aura.charges and aura.charges > 0 then
            frame.auraStacks = aura.charges
        end

        if aura.expirationTime <= 0 then
            frame.auraIcon = aura.icon or -1
            return true
        else
            local remaining = aura.expirationTime - GetTime()

            if remaining > 0 then
                frame.auraIcon = aura.icon or -1
                frame.auraRemaining = remaining
                return true
            end
        end
    end

    return false
end

local function IsAuraActiveTotem(frame, playerTotems, spellID)
    if spellID <= 0 then
        return
    end

    local totem = GetTotem(playerTotems, spellID, frame.iconName)

    if totem then
        local remaining = (totem.startTime + totem.duration) - GetTime()

        if remaining > 0 then
            frame.auraIcon = totem.icon or -1
            frame.auraRemaining = remaining
            return true
        end
    end

    return false
end

local function RefreshCategoryFrame(category, parentTable, playerSpecID)
    if not category then
        return
    end

    if not parentTable then
        return
    end

    if category == addon.ignored then
        if parentTable.items and next(parentTable.items) ~= nil then
            for i = 1, #parentTable.items do
                local iconFrame = parentTable.items[i]

                iconFrame:ClearAllPoints()
                iconFrame:SetParent(parentTable.frame)

                iconFrame:Hide()
            end
        end

        if parentTable.spells and next(parentTable.spells) ~= nil then
            for i = 1, #parentTable.spells do
                local iconFrame = parentTable.spells[i]

                iconFrame:ClearAllPoints()
                iconFrame:SetParent(parentTable.frame)

                iconFrame:Hide()
            end
        end
    else
        local settingsTable = SettingsDB[category] or {}

        local allIcons = {}
        local displayWhen = settingsTable.displayWhen or "Always"
        local iconSize = settingsTable.iconSize or 64
        local iconSpacing = settingsTable.iconSpacing or 2
        local isClickable = settingsTable.isClickable or false
        local isVertical = settingsTable.isVertical or false
        local seenSettingNames = {}
        local validSettingNames = {}
        local wrapAfter = settingsTable.wrapAfter or 0

        if displayWhen == "" then
            displayWhen = "Always"
        end

        if not CategoryOrderDB[category] then
            CategoryOrderDB[category] = {}
        end

        for _, iconFrame in ipairs(parentTable.items) do
            validSettingNames[iconFrame.settingName] = true
        end
        for _, iconFrame in ipairs(parentTable.spells) do
            validSettingNames[iconFrame.settingName] = true
        end

        for _, settingName in ipairs(CategoryOrderDB[category]) do
            if validSettingNames[settingName] and iconFrames[settingName] then
                seenSettingNames[settingName] = true

                table.insert(allIcons, iconFrames[settingName])
            end
        end

        for i = 1, #parentTable.spells do
            local iconFrame = parentTable.spells[i]

            if not seenSettingNames[iconFrame.settingName] then
                table.insert(allIcons, iconFrame)
            end
        end

        for i = 1, #parentTable.items do
            local iconFrame = parentTable.items[i]

            if not seenSettingNames[iconFrame.settingName] then
                table.insert(allIcons, iconFrame)
            end
        end

        if allIcons and next(allIcons) ~= nil then
            for i = 1, #allIcons do
                local iconFrame = allIcons[i]

                if category == addon.unknown then
                    iconFrame.textID:Show()

                    iconFrame:EnableMouse(false)
                    iconFrame:SetFrameStrata("LOW")
                    iconFrame:SetToplevel(false)

                    UnregisterAttributeDriver(iconFrame, "state-visibility")
                    iconFrame:Show()
                else
                    iconFrame.textID:Hide()

                    if SettingsDB.isLocked then
                        if isClickable then
                            iconFrame:EnableMouse(true)
                            iconFrame:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
                            iconFrame:SetFrameStrata("HIGH")
                            iconFrame:SetToplevel(true)
                        else
                            iconFrame:EnableMouse(false)
                            iconFrame:SetFrameStrata("LOW")
                            iconFrame:SetToplevel(false)
                        end

                        if displayWhen == "Always" then
                            UnregisterAttributeDriver(iconFrame, "state-visibility")
                            iconFrame:Show()
                        elseif displayWhen == "In Combat" then
                            RegisterAttributeDriver(iconFrame, "state-visibility", "[combat] show; hide")
                        elseif displayWhen == "Out Of Combat" then
                            RegisterAttributeDriver(iconFrame, "state-visibility", "[nocombat] show; hide")
                        else
                            UnregisterAttributeDriver(iconFrame, "state-visibility")
                            iconFrame:Show()
                        end
                    else
                        iconFrame:EnableMouse(false)
                        iconFrame:SetFrameStrata("LOW")
                        iconFrame:SetToplevel(false)

                        UnregisterAttributeDriver(iconFrame, "state-visibility")
                        iconFrame:Show()
                    end
                end

                iconFrame:ClearAllPoints()
                iconFrame:SetParent(parentTable.frame)

                iconFrame:SetSize(iconSize, iconSize)
                iconFrame.textureIcon:SetAllPoints(iconFrame)

                if i == 1 then
                    iconFrame:SetPoint("TOPLEFT", parentTable.frame, "TOPLEFT", 0, 0)
                else
                    local wrapIndex = (wrapAfter > 0) and ((i - 1) % wrapAfter == 0)
                    if wrapIndex then
                        local previousWrap = allIcons[i - wrapAfter]
                        if isVertical then
                            iconFrame:SetPoint("TOPLEFT", previousWrap, "TOPRIGHT", iconSpacing, 0)
                        else
                            iconFrame:SetPoint("TOPLEFT", previousWrap, "BOTTOMLEFT", 0, iconSpacing)
                        end
                    else
                        local previous = allIcons[i - 1]
                        if isVertical then
                            iconFrame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, iconSpacing)
                        else
                            iconFrame:SetPoint("TOPLEFT", previous, "TOPRIGHT", iconSpacing, 0)
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
        else
            parentTable.frame:SetSize(1, 1)
        end
    end
end

local function updateIconItem(frame, gcdCooldown, playerBuffs, playerTotems, settingsTable, targetDebuffs)
    frame.itemID = frame.itemID or -1
    frame.spellID = frame.spellID or -1

    local count = C_Item.GetItemCount(frame.itemID, false, true, false, false)
    if count > 0 then
        frame:SetAlpha(1.0)
        frame.textCharges:SetText(count)
    else
        frame:SetAlpha(0.0)
        return
    end

    if not settingsTable.showWhenAvailable then
        local isAuraActive = false

        if frame.spellID > 0 then
            if IsAuraActiveBuff(frame, playerBuffs, frame.spellID) then
                isAuraActive = true
            elseif IsAuraActiveTotem(frame, playerTotems, frame.spellID) then
                isAuraActive = true
            elseif frame.spellCooldown <= 0 and IsAuraActiveDebuff(frame, frame.spellID, targetDebuffs) then
                isAuraActive = true
            end
        end

        if isAuraActive then
            if frame.auraRemaining > 0 then
                frame.textCooldown:SetText(string.format("%d", frame.auraRemaining))
                frame.textCooldown:SetTextColor(0, 1, 0, 1)
            else
                frame.textCooldown:SetText("")
            end

            if frame.auraStacks > 0 then
                frame.textCharges:SetText(frame.auraStacks)
            else
                frame.textCharges:SetText("")
            end

            if frame.auraIcon > 0 and frame.currentIcon ~= frame.auraIcon then
                frame.currentIcon = frame.auraIcon
                frame.textureIcon:SetTexture(frame.auraIcon)
            end

            frame.frameBorder:Hide()
            frame.textureIcon:SetDesaturated(false)

            if settingsTable.colorBasedOnState then
                frame.textureIcon:SetVertexColor(0, 1, 0)
            end

            if settingsTable.glowWhenAuraActive and not frame.isGlowActive then
                ActionButton_ShowOverlayGlow(frame)
                frame.isGlowActive = true
            end

            if settingsTable.showOnCooldown then
                if frame.isHarmful then
                    if frame.auraRemaining >= 0 and frame.auraRemaining <= 5 then
                        frame:SetAlpha(1.0)
                    else
                        frame:SetAlpha(0.0)
                    end
                else
                    frame:SetAlpha(1.0)
                end
            else
                frame:SetAlpha(1.0)
            end

            return
        end
    end

    local isGlowActive = false
    local isOnCooldown = false
    local isVisible = false

    frame.textureIcon:SetDesaturated(false)
    frame.textureIcon:SetVertexColor(1, 1, 1)

    if not settingsTable.showOnCooldown and not settingsTable.showWhenAvailable then
        isVisible = true
    end

    local startTime, duration, enable = C_Container.GetItemCooldown(frame.itemID)
    if enable == 1 and duration > 2 then
        local remaining = (startTime + duration) - GetTime()

        if remaining > 0 then
            if remaining < 90 then
                frame.textCooldown:SetText(string.format("%d", remaining))
                frame.textCooldown:SetTextColor(1, 0, 0, 1)
            else
                frame.textCooldown:SetText("")
            end

            if settingsTable.showOnCooldown then
                isVisible = true
            end

            isOnCooldown = true
        end
    else
        if settingsTable.showWhenAvailable then
            isVisible = true
        end
    end

    if isVisible then
        frame:SetAlpha(1.0)

        if isOnCooldown then
            frame.frameBorder:Show()
            frame.textBinding:Hide()
            frame.textureIcon:SetDesaturated(true)
        else
            frame.frameBorder:Hide()
            frame.textBinding:Show()
            frame.textCooldown:SetText("")
            frame.textureIcon:SetDesaturated(false)
        end

        if isGlowActive then
            if not frame.isGlowActive then
                ActionButton_ShowOverlayGlow(frame)
                frame.isGlowActive = true
            end
        else
            if frame.isGlowActive then
                ActionButton_HideOverlayGlow(frame)
                frame.isGlowActive = false
            end
        end
    else
        frame:SetAlpha(0.0)
    end
end

local function updateIconSpell(frame, gcdCooldown, playerBuffs, playerTotems, settingsTable, targetDebuffs)
    frame.auraIcon = -1
    frame.auraRemaining = -1
    frame.auraStacks = -1
    frame.spellID = frame.spellID or -1

    local buffOverrideSpellID = SettingsDB.buffOverrides[frame.spellID] or frame.spellID
    local isAuraActive = false
    local overrideSpellID = C_Spell.GetOverrideSpell(frame.spellID) or frame.spellID

    if not settingsTable.showWhenAvailable then
        if IsAuraActiveBuff(frame, playerBuffs, frame.spellID) then
            isAuraActive = true
        elseif IsAuraActiveTotem(frame, playerTotems, frame.spellID) then
            isAuraActive = true
        elseif frame.spellCooldown <= 0 and IsAuraActiveDebuff(frame, frame.spellID, targetDebuffs) then
            isAuraActive = true
        end

        if not isAuraActive and frame.spellID ~= buffOverrideSpellID then
            if IsAuraActiveBuff(frame, playerBuffs, buffOverrideSpellID) then
                isAuraActive = true
            elseif IsAuraActiveTotem(frame, playerTotems, buffOverrideSpellID) then
                isAuraActive = true
            elseif frame.spellCooldown <= 0 and IsAuraActiveDebuff(frame, buffOverrideSpellID, targetDebuffs) then
                isAuraActive = true
            end
        end

        if not isAuraActive and frame.spellID ~= overrideSpellID then
            if IsAuraActiveBuff(frame, playerBuffs, overrideSpellID) then
                isAuraActive = true
            elseif IsAuraActiveTotem(frame, playerTotems, overrideSpellID) then
                isAuraActive = true
            elseif frame.spellCooldown <= 0 and IsAuraActiveDebuff(frame, overrideSpellID, targetDebuffs) then
                isAuraActive = true
            end
        end

        if isAuraActive then
            if frame.auraRemaining > 0 then
                frame.textCooldown:SetText(string.format("%d", frame.auraRemaining))
                frame.textCooldown:SetTextColor(0, 1, 0, 1)
            else
                frame.textCooldown:SetText("")
            end

            if frame.auraStacks > 0 then
                frame.textCharges:SetText(frame.auraStacks)
            else
                frame.textCharges:SetText("")
            end

            if frame.auraIcon > 0 and frame.currentIcon ~= frame.auraIcon then
                frame.currentIcon = frame.auraIcon
                frame.textureIcon:SetTexture(frame.auraIcon)
            end

            frame.frameBorder:Hide()
            frame.textureIcon:SetDesaturated(false)

            if settingsTable.colorBasedOnState then
                frame.textureIcon:SetVertexColor(0, 1, 0)
            end

            if settingsTable.glowWhenAuraActive and not frame.isGlowActive then
                ActionButton_ShowOverlayGlow(frame)
                frame.isGlowActive = true
            end

            if settingsTable.showOnCooldown then
                if frame.isHarmful then
                    if frame.auraRemaining >= 0 and frame.auraRemaining <= 5 then
                        frame:SetAlpha(1.0)
                    else
                        frame:SetAlpha(0.0)
                    end
                else
                    frame:SetAlpha(1.0)
                end
            else
                frame:SetAlpha(1.0)
            end

            return
        else
            if frame.isHarmful and frame.spellCooldown <= 0 then
                frame.frameBorder:Hide()
                frame:SetAlpha(1.0)
                frame.textCooldown:SetText("")
                frame.textureIcon:SetDesaturated(true)

                if settingsTable.glowWhenAuraActive and frame.isGlowActive then
                    ActionButton_HideOverlayGlow(frame)
                    frame.isGlowActive = false
                end

                return
            end
        end
    end

    local isSpellDisabled = C_Spell.IsSpellDisabled(overrideSpellID)

    if isSpellDisabled then
        frame:SetAlpha(0.0)
        return
    end

    local isGlowActive = false
    local isOnCooldown = false
    local isSpellUsable, inSufficientPower = C_Spell.IsSpellUsable(overrideSpellID)
    local isVisible = false
    local spellCharges = C_Spell.GetSpellCharges(overrideSpellID)
    local spellCooldown = C_Spell.GetSpellCooldown(overrideSpellID)

    frame.textureIcon:SetDesaturated(false)
    frame.textureIcon:SetVertexColor(1, 1, 1)

    if not settingsTable.showOnCooldown and not settingsTable.showWhenAvailable then
        isVisible = true
    end

    if frame.spellID == overrideSpellID then
        if frame.currentIcon ~= frame.iconID then
            frame.currentIcon = frame.iconID
            frame.textureIcon:SetTexture(frame.iconID)
        end
    else
        local spellInfo = C_Spell.GetSpellInfo(overrideSpellID)
        if spellInfo then
            if frame.currentIcon ~= spellInfo.iconID then
                frame.currentIcon = spellInfo.iconID
                frame.textureIcon:SetTexture(spellInfo.iconID)
            end
        end

        if settingsTable.glowWhenOverridden then
            isGlowActive = true
        end
    end

    if spellCharges and spellCharges.maxCharges > 1 then
        frame.textCharges:SetText(spellCharges.currentCharges)

        if spellCharges.currentCharges > 0 then
            if settingsTable.showWhenAvailable then
                isVisible = true
            end

            if isVisible and spellCharges.currentCharges < spellCharges.maxCharges then
                frame.frameBorder:Show()
            end
        else
            if spellCharges.cooldownStartTime and spellCharges.cooldownDuration and spellCharges.cooldownDuration > 2 then
                local remaining = (spellCharges.cooldownStartTime + spellCharges.cooldownDuration) - GetTime()
                if remaining > 0 then
                    if remaining < 90 then
                        frame.textCooldown:SetText(string.format("%d", remaining))
                        frame.textCooldown:SetTextColor(1, 0, 0, 1)
                    else
                        frame.textCooldown:SetText("")
                    end

                    if settingsTable.showOnCooldown then
                        isVisible = true
                    end

                    isOnCooldown = true
                end
            end
        end
    else
        if spellCooldown.isEnabled and spellCooldown.duration > 2 then
            local remaining = (spellCooldown.startTime + spellCooldown.duration) - GetTime()
            if remaining > 0 then
                if remaining < 90 then
                    frame.textCooldown:SetText(string.format("%d", remaining))
                    frame.textCooldown:SetTextColor(1, 0, 0, 1)
                else
                    frame.textCooldown:SetText("")
                end

                if settingsTable.showOnCooldown then
                    isVisible = true
                end

                isOnCooldown = true
            end
        else
            if settingsTable.showWhenAvailable then
                isVisible = true
            end
        end
    end

    if isVisible then
        frame:SetAlpha(1.0)

        if isOnCooldown then
            frame.frameBorder:Show()
            frame.textBinding:Hide()
            frame.textureIcon:SetDesaturated(true)
        else
            frame.frameBorder:Hide()
            frame.textBinding:Show()
            frame.textCooldown:SetText("")

            frame.textureIcon:SetDesaturated(false)
            if not isSpellUsable then
                if inSufficientPower then
                    frame.textureIcon:SetVertexColor(0.5, 0.5, 1)
                else
                    frame.textureIcon:SetVertexColor(1, 0, 0)
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

        if isGlowActive then
            if not frame.isGlowActive then
                ActionButton_ShowOverlayGlow(frame)
                frame.isGlowActive = true
            end
        else
            if frame.isGlowActive then
                ActionButton_HideOverlayGlow(frame)
                frame.isGlowActive = false
            end
        end
    else
        frame:SetAlpha(0.0)
    end
end

function addon:CheckLockState()
    if InCombatLockdown() then
        addon:Debounce("CheckLockState", 1, function()
            addon:CheckLockState()
        end)

        return
    end

    local validCategories = addon:GetValidCategories(false)

    for i = 1, #validCategories do
        local name = validCategories[i]

        if categories[name] then
            local frame = categories[name].frame

            if SettingsDB.isLocked then
                frame:EnableKeyboard(false)
                frame:EnableMouse(false)
                frame:EnableMouseWheel(false)
                frame:RegisterForDrag()
                frame:SetMovable(false)
            else
                frame:EnableMouse(true)
                frame:RegisterForDrag("LeftButton")
                frame:SetMovable(true)
            end
        end
    end

    addon:RefreshCategoryFrames()
end

function addon:CreateIcons()
    if InCombatLockdown() then
        return
    end

    for settingName, iconFrame in pairs(iconFrames) do
        UnregisterAttributeDriver(iconFrame, "state-visibility")

        iconFrame:ClearAllPoints()
        iconFrame:Hide()
        iconFrame:SetParent(nil)

        iconFrame = nil
    end
    wipe(iconFrames)
    iconFrames = {}

    collectgarbage("collect")

    local tableIconDetails = addon:GetIconDetails()

    if tableIconDetails and next(tableIconDetails) ~= nil then
        for i = 1, #tableIconDetails do
            local iconDetail = tableIconDetails[i]

            local frameIcon = CreateIconFrame(iconDetail)
            if frameIcon then
                iconFrames[frameIcon.settingName] = frameIcon
            end
        end
    end

    addon:CheckLockState()
    addon:UpdateIconBinds()
end

function addon:RefreshCategoryFrames()
    if InCombatLockdown() then
        return
    end

    local currentSpec = GetSpecialization()
    if not currentSpec then
        return
    end

    local playerSpecID = GetSpecializationInfo(currentSpec)
    if not playerSpecID then
        return
    end

    local validCategories = addon:GetValidCategories(true)

    for i = 1, #validCategories do
        local name = validCategories[i]
        local parentTable

        if categories[name] then
            parentTable = categories[name]
        else
            parentTable = {}
            parentTable.frame = addon:GetFrame(name)

            categories[name] = parentTable
        end

        parentTable.items = {}
        parentTable.spells = {}
    end

    for settingName, iconFrame in pairs(iconFrames) do
        local category = SpellsDB[iconFrame.specID][settingName]
        if not category or category == "" then
            category = addon.unknown
        end

        if iconFrame.itemID > 0 then
            local count = C_Item.GetItemCount(iconFrame.itemID, false, true, false, false)
            if count <= 0 then
                table.insert(categories[addon.ignored].items, iconFrame)
            else
                table.insert(categories[category].items, iconFrame)
            end
        else
            table.insert(categories[category].spells, iconFrame)
        end
    end

    for i = 1, #validCategories do
        local category = validCategories[i]

        if categories[category] then
            local parentTable = categories[category]

            RefreshCategoryFrame(category, parentTable, playerSpecID)
            addon:FrameRestore(category, parentTable.frame)
        end
    end
end

function addon:UpdateIconBinds()
    local slotDetails = addon:GetSlotDetails()

    for settingName, iconFrame in pairs(iconFrames) do
        local binding = addon:GetKeyBind(iconFrame.itemID, iconFrame.iconName, slotDetails, iconFrame.spellID)
        if binding then
            iconFrame.textBinding:SetText(addon:ReplaceBindings(binding))
        else
            iconFrame.textBinding:SetText("")
        end
    end
end

function addon:UpdateIconState()
    local validCategories = addon:GetValidCategories(true)

    if SettingsDB.isLocked then
        local auraIndex = 1
        local gcdCooldown = C_Spell.GetSpellCooldown(61304)
        local playerBuffs = {}
        local playerTotems = {}
        local targetDebuffs = {}

        while true do
            local aura = C_UnitAuras.GetDebuffDataByIndex("target", auraIndex, "HARMFUL")
            if not aura then
                break
            end

            if aura.isFromPlayerOrPlayerPet then
                table.insert(targetDebuffs, aura)
            end

            auraIndex = auraIndex + 1
        end

        auraIndex = 1
        while true do
            local aura = C_UnitAuras.GetBuffDataByIndex("player", auraIndex, "HELPFUL")
            if not aura then
                break
            end

            if aura.isFromPlayerOrPlayerPet then
                table.insert(playerBuffs, aura)
            end

            auraIndex = auraIndex + 1
        end

        auraIndex = 1
        while true do
            local aura = C_UnitAuras.GetBuffDataByIndex("pet", auraIndex, "HELPFUL")
            if not aura then
                break
            end

            if aura.isFromPlayerOrPlayerPet then
                table.insert(playerBuffs, aura)
            end

            auraIndex = auraIndex + 1
        end

        for totemIndex = 1, MAX_TOTEMS do
            local haveTotem, totemName, startTime, duration, icon, modRate, spellID = GetTotemInfo(totemIndex)
            if totemName and totemName ~= "" then
                table.insert(playerTotems,
                    {
                        haveTotem = haveTotem,
                        totemName = totemName,
                        startTime = startTime,
                        duration = duration,
                        icon = icon,
                        modRate = modRate,
                        spellID = spellID
                    })
            end
        end

        for index = 1, #validCategories do
            local category = validCategories[index]
            if category ~= addon.ignored and category ~= addon.unknown and categories[category] then
                local parentTable = categories[category]
                local settingsTable = addon:GetSettingsTable(category)

                if parentTable.items then
                    for i = 1, #parentTable.items do
                        updateIconItem(parentTable.items[i], gcdCooldown, playerBuffs, playerTotems, settingsTable, targetDebuffs)
                    end
                end

                if parentTable.spells then
                    for i = 1, #parentTable.spells do
                        updateIconSpell(parentTable.spells[i], gcdCooldown, playerBuffs, playerTotems, settingsTable, targetDebuffs)
                    end
                end
            end
        end
    else
        for index = 1, #validCategories do
            local category = validCategories[index]

            if categories[category] then
                local parentTable = categories[category]

                if parentTable.items then
                    for i = 1, #parentTable.items do
                        parentTable.items[i]:SetAlpha(1.0)
                    end
                end

                if parentTable.spells then
                    for i = 1, #parentTable.spells do
                        parentTable.spells[i]:SetAlpha(1.0)
                    end
                end
            end
        end
    end
end
