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
    elseif spellID > 0 then
        local spellInfo = C_Spell.GetSpellInfo(spellID)

        newFrame.iconName = spellInfo.name
        textID:SetText(tostring(spellID))
        textureIcon:SetTexture(spellInfo.iconID)

        if not newFrame.iconName or newFrame.iconName == "" then
            newFrame.iconName = ""
        end

        if C_Spell.IsSpellHarmful(spellID) then
            newFrame.isHarmful = true
        else
            newFrame.isHarmful = false
        end

        local binding = addon:GetKeyBind(itemID, newFrame.iconName, spellID)
        if binding then
            textBinding:SetText(addon:ReplaceBindings(binding))
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
            return aura
        end
    end

    return nil
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

local function updateIconBuff(frame, playerBuffs, spellID)
    frame.textureIcon:SetDesaturated(false)
    frame.textureIcon:SetVertexColor(1, 1, 1)

    if spellID <= 0 then
        return
    end

    local aura = GetAura(playerBuffs, SettingsDB.buffOverrides[spellID] or spellID, frame.iconName)

    if aura then
        local remaining = aura.expirationTime - GetTime()

        if aura.applications and aura.applications > 0 then
            frame.textCharges:SetText(aura.applications)
        elseif aura.charges and aura.charges > 0 then
            frame.textCharges:SetText(aura.charges)
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

local function updateIconDebuff(frame, showOnCooldown, spellID, targetDebuffs)
    if spellID <= 0 then
        return
    end

    local aura = GetAura(targetDebuffs, spellID, frame.iconName)

    if aura then
        if aura.applications and aura.applications > 0 then
            frame.textCharges:SetText(aura.applications)
        elseif aura.charges and aura.charges > 0 then
            frame.textCharges:SetText(aura.charges)
        else
            frame.textCharges:SetText("")
        end

        if aura.expirationTime <= 0 then
            if showOnCooldown then
                frame:SetAlpha(0.0)
            end

            frame.auraActive = true
            frame.frameBorder:Hide()
            frame.textureIcon:SetDesaturated(false)
        else
            local remaining = aura.expirationTime - GetTime()

            if remaining > 0 then
                frame.textCooldown:SetText(string.format("%d", remaining))
                frame.textCooldown:SetTextColor(0, 1, 0, 1)

                if remaining <= 5 then
                    if showOnCooldown then
                        frame:SetAlpha(1.0)
                    end

                    if not frame.glowActive then
                        ActionButton_ShowOverlayGlow(frame)
                        frame.glowActive = true
                    end
                elseif frame.glowActive then
                    ActionButton_HideOverlayGlow(frame)
                    frame.glowActive = false

                    if showOnCooldown then
                        frame:SetAlpha(0.0)
                    end
                else
                    if showOnCooldown then
                        frame:SetAlpha(0.0)
                    end
                end

                frame.auraActive = true
                frame.frameBorder:Hide()
                frame.textureIcon:SetDesaturated(false)
            else
                if showOnCooldown then
                    frame:SetAlpha(1.0)
                end

                if frame.glowActive then
                    ActionButton_HideOverlayGlow(frame)
                    frame.glowActive = false
                end

                frame.auraActive = false
                frame.frameBorder:Show()
                frame.textCooldown:SetText("")
                frame.textureIcon:SetDesaturated(true)
            end
        end
    else
        if showOnCooldown then
            frame:SetAlpha(1.0)
        end

        if frame.glowActive then
            ActionButton_HideOverlayGlow(frame)
            frame.glowActive = false
        end

        frame.auraActive = false
        frame.frameBorder:Show()
        frame.textCharges:SetText("")
        frame.textCooldown:SetText("")
        frame.textureIcon:SetDesaturated(true)
    end
end

local function updateIconItem(category, frame, playerBuffs)
    frame.frameBorder:Hide()

    if category == addon.ignored or category == addon.unknown then
        return
    end

    local settingsTable = SettingsDB[category] or {}

    local itemID = frame.itemID or 0
    local showOnCooldown = settingsTable.showOnCooldown or false
    local spellID = frame.spellID or 0

    local count = C_Item.GetItemCount(itemID, false, true, false, false)
    if count <= 0 then
        frame:SetAlpha(0.0)
        return
    end

    if showOnCooldown then
        frame:SetAlpha(0.0)
    else
        frame:SetAlpha(1.0)
    end

    updateIconBuff(frame, playerBuffs, spellID)

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
            frame:SetAlpha(1.0)

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

local function updateIconSpell(category, frame, gcdCooldown, playerBuffs, targetDebuffs)
    frame.frameBorder:Hide()

    if category == addon.ignored or category == addon.unknown then
        return
    end

    local frameSpellID = frame.spellID or 0
    local glowActive = false

    local currentSpellID = C_Spell.GetOverrideSpell(frameSpellID) or frameSpellID

    if C_Spell.IsSpellDisabled(currentSpellID) then
        frame:SetAlpha(0.0)
        return
    end

    local settingsTable = SettingsDB[category] or {}

    local isUsable, insufficientPower = C_Spell.IsSpellUsable(currentSpellID)
    local showOnCooldown = settingsTable.showOnCooldown or false
    local showWhenAvailable = settingsTable.showWhenAvailable or false
    local spellCharges = C_Spell.GetSpellCharges(currentSpellID)

    if frame.isHarmful and frame.spellCooldown <= 0 then
        updateIconDebuff(frame, showOnCooldown, currentSpellID, targetDebuffs)

        if frame.auraActive then
            return
        end

        if frameSpellID ~= currentSpellID then
            updateIconDebuff(frame, showOnCooldown, frameSpellID, targetDebuffs)

            if frame.auraActive then
                return
            end
        end
    else
        if showOnCooldown or showWhenAvailable then
            frame:SetAlpha(0.0)
        else
            frame:SetAlpha(1.0)
        end

        if showWhenAvailable then
            if spellCharges and spellCharges.maxCharges > 1 then
                frame.textCharges:SetText(spellCharges.currentCharges)

                if spellCharges.currentCharges > 0 then
                    frame:SetAlpha(1.0)
                end
            else
                local spellCooldown = C_Spell.GetSpellCooldown(currentSpellID)
                if spellCooldown.isEnabled and spellCooldown.duration > 2 then
                else
                    frame:SetAlpha(1.0)
                end
            end
        else
            updateIconBuff(frame, playerBuffs, currentSpellID)

            if frame.auraActive then
                if not frame.glowActive then
                    ActionButton_ShowOverlayGlow(frame)
                    frame.glowActive = true
                end

                frame:SetAlpha(1.0)

                return
            end

            frame.textBinding:Show()
            frame.textCooldown:SetText("")

            if frameSpellID ~= currentSpellID then
                updateIconBuff(frame, playerBuffs, frameSpellID)

                if frame.auraActive then
                    if not frame.glowActive then
                        ActionButton_ShowOverlayGlow(frame)
                        frame.glowActive = true
                    end

                    frame:SetAlpha(1.0)

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
                    frame:SetAlpha(1.0)

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
                    frame:SetAlpha(1.0)
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
                        frame:SetAlpha(1.0)

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
end

function addon:CheckLockState()
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
end

function addon:RefreshCategoryFrames()
    if InCombatLockdown() then
        addon:Debounce("RefreshCategoryFrames", 1, function()
            addon:RefreshCategoryFrames()
        end)

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

        if categories[name] then
            local parentTable = categories[name]
            parentTable.items = {}
            parentTable.spells = {}
        else
            local parentTable = {}
            parentTable.frame = addon:GetFrame(name)
            parentTable.items = {}
            parentTable.spells = {}

            categories[name] = parentTable
        end
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

function addon:UpdateIconState()
    local validCategories = addon:GetValidCategories(true)

    if SettingsDB.isLocked then
        local auraIndex = 1
        local gcdCooldown = C_Spell.GetSpellCooldown(61304)
        local playerBuffs = {}
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

        for index = 1, #validCategories do
            local category = validCategories[index]

            if categories[category] then
                local parentTable = categories[category]

                if parentTable.items then
                    for i = 1, #parentTable.items do
                        updateIconItem(category, parentTable.items[i], playerBuffs)
                    end
                end

                if parentTable.spells then
                    for i = 1, #parentTable.spells do
                        updateIconSpell(category, parentTable.spells[i], gcdCooldown, playerBuffs, targetDebuffs)
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
