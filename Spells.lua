local addonName, addon = ...

local categories = {}
local iconFrames = {}
local cooldownManagerSpells = {}

local LCG = LibStub("LibCustomGlow-1.0")

local LSM = LibStub("LibSharedMedia-3.0")
local font = LSM:Fetch("font", "Naowh") or "Fonts\\FRIZQT__.TTF"

local function CheckTextBindingKeyBind(icon, spellID, knownSlots)
    if not spellID then
        return false
    end

    if spellID <= 0 then
        return false
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        local keyBind = KnownSlot:GetKeyBind(-1, "", spellID, addon:NormalizeText(spellInfo.name), knownSlots)

        if keyBind and keyBind ~= "" then
            icon.textBinding:SetText(keyBind)
            return true
        end
    else
        local keyBind = KnownSlot:GetKeyBind(-1, "", spellID, "", knownSlots)

        if keyBind and keyBind ~= "" then
            icon.textBinding:SetText(keyBind)
            return true
        end
    end

    return false
end

local function CheckTextBinding(fontSize, icon, knownSlots)
    if not icon.textBinding then
        icon.frameText = CreateFrame("Frame", nil, icon)
        icon.frameText:SetAllPoints(icon)
        icon.frameText:SetFrameLevel(icon:GetFrameLevel() + 1)

        icon.textBinding = icon.frameText:CreateFontString(nil, "OVERLAY")
        icon.textBinding:SetFont(font, fontSize, SettingsDB.bindingFontFlags or "OUTLINE")
        icon.textBinding:SetPoint("TOPRIGHT", icon.frameText, "TOPRIGHT", 0, 0)
        icon.textBinding:SetTextColor(1, 1, 1, 1)
        if SettingsDB.bindingFontShadow then
            icon.textBinding:SetShadowColor(0, 0, 0, 0.5)
            icon.textBinding:SetShadowOffset(1, -1)
        end
    end

    icon.textBinding:SetText("")

    if not icon.GetCooldownID then
        return
    end

    local cooldownID = icon:GetCooldownID()
    if not cooldownID then
        return
    end

    local cooldownInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    if not cooldownInfo then
        return
    end

    cooldownManagerSpells[cooldownInfo.spellID] = true
    if cooldownInfo.overrideSpellID and cooldownInfo.overrideSpellID > 0 then
        cooldownManagerSpells[cooldownInfo.overrideSpellID] = true
    end

    if CheckTextBindingKeyBind(icon, cooldownInfo.spellID, knownSlots) == true then
        return
    end

    if CheckTextBindingKeyBind(icon, cooldownInfo.overrideSpellID, knownSlots) == true then
        return
    end

    if cooldownInfo.linkedSpellIDs then
        for _, spellID in pairs(cooldownInfo.linkedSpellIDs) do
            if spellID and spellID > 0 then
                cooldownManagerSpells[spellID] = true

                if CheckTextBindingKeyBind(icon, spellID, knownSlots) == true then
                    return
                end
            end
        end
    end
end

local function CreateIconFrame(knownSpell)
    if knownSpell.itemID <= 0 and knownSpell.spellID <= 0 then
        return nil
    end

    local newFrame = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    newFrame:EnableKeyboard(false)
    newFrame:EnableMouse(false)
    newFrame:EnableMouseWheel(false)
    newFrame:Hide()
    newFrame:SetFrameStrata("LOW")
    newFrame:SetHitRectInsets(0, 0, 0, 0)
    newFrame:SetPoint("CENTER", 0, 0)
    newFrame:SetPropagateKeyboardInput(true)
    newFrame:SetSize(40, 40)

    newFrame.iconID = knownSpell.iconID
    newFrame.isHarmful = knownSpell.isHarmful
    newFrame.isTrinket = knownSpell.isTrinket
    newFrame.isUsable = knownSpell.isUsable
    newFrame.itemID = knownSpell.itemID
    newFrame.itemName = knownSpell.itemName
    newFrame.itemRank = knownSpell.itemRank
    newFrame.playerSpecID = knownSpell.playerSpecID
    newFrame.settingName = knownSpell.settingName
    newFrame.specID = knownSpell.specID
    newFrame.spellID = knownSpell.spellID
    newFrame.spellName = knownSpell.spellName

    if newFrame.itemID > 0 then
        newFrame:SetAttribute("type", "item")
        newFrame:SetAttribute("item", "item:" .. newFrame.itemID)
        newFrame:SetScript("OnEnter", function(control)
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(newFrame.itemID)
            GameTooltip:Show()
        end)
    else
        newFrame:SetAttribute("type", "spell")
        newFrame:SetAttribute("spell", newFrame.spellID)
        newFrame:SetScript("OnEnter", function(control)
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(newFrame.spellID)
            GameTooltip:Show()
        end)
    end
    newFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    newFrame.frameBorder = CreateFrame("Frame", nil, newFrame, "BackdropTemplate")
    newFrame.frameBorder:EnableKeyboard(false)
    newFrame.frameBorder:EnableMouse(false)
    newFrame.frameBorder:EnableMouseWheel(false)
    newFrame.frameBorder:SetAllPoints(newFrame)
    newFrame.frameBorder:SetBackdrop({ edgeFile = "Interface/Buttons/WHITE8x8", edgeSize = 1, })
    newFrame.frameBorder:SetFrameLevel(newFrame:GetFrameLevel() + 1)
    newFrame.frameBorder:SetPropagateKeyboardInput(true)
    newFrame.frameBorder:SetToplevel(false)

    newFrame.frameCooldownGCD = CreateFrame("Cooldown", nil, newFrame, "CooldownFrameTemplate")
    newFrame.frameCooldownGCD:EnableKeyboard(false)
    newFrame.frameCooldownGCD:EnableMouse(false)
    newFrame.frameCooldownGCD:EnableMouseWheel(false)
    newFrame.frameCooldownGCD:SetAllPoints(newFrame)
    newFrame.frameCooldownGCD:SetDrawEdge(false)
    newFrame.frameCooldownGCD:SetFrameLevel(newFrame:GetFrameLevel() + 1)
    newFrame.frameCooldownGCD:SetHideCountdownNumbers(true)
    newFrame.frameCooldownGCD:SetPropagateKeyboardInput(true)
    newFrame.frameCooldownGCD:SetSwipeTexture("Interface\\Cooldown\\ping4", 1, 1, 1, 1)
    newFrame.frameCooldownGCD:SetToplevel(false)

    newFrame.frameCooldownSpell = CreateFrame("Cooldown", nil, newFrame, "CooldownFrameTemplate")
    newFrame.frameCooldownSpell:EnableKeyboard(false)
    newFrame.frameCooldownSpell:EnableMouse(false)
    newFrame.frameCooldownSpell:EnableMouseWheel(false)
    newFrame.frameCooldownSpell:SetAllPoints(newFrame)
    newFrame.frameCooldownSpell:SetDrawEdge(false)
    newFrame.frameCooldownSpell:SetFrameLevel(newFrame:GetFrameLevel() + 1)
    newFrame.frameCooldownSpell:SetHideCountdownNumbers(true)
    newFrame.frameCooldownSpell:SetPropagateKeyboardInput(true)
    newFrame.frameCooldownSpell:SetSwipeTexture("Interface\\Cooldown\\ping4", 1, 1, 1, 1)
    newFrame.frameCooldownSpell:SetToplevel(false)

    newFrame.frameText = CreateFrame("Frame", nil, newFrame)
    newFrame.frameText:SetAllPoints(newFrame)
    newFrame.frameText:SetFrameLevel(newFrame.frameCooldownSpell:GetFrameLevel() + 1)

    newFrame.textBinding = newFrame.frameText:CreateFontString(nil, "OVERLAY")
    newFrame.textBinding:SetFont(font, addon:GetNumberOrDefault(12, SettingsDB.bindingFontSize), SettingsDB.bindingFontFlags or "OUTLINE")
    newFrame.textBinding:SetPoint("TOPRIGHT", newFrame.frameText, "TOPRIGHT", 0, 0)
    newFrame.textBinding:SetText("")
    newFrame.textBinding:SetTextColor(1, 1, 1, 1)
    if SettingsDB.bindingFontShadow then
        newFrame.textBinding:SetShadowColor(0, 0, 0, 0.5)
        newFrame.textBinding:SetShadowOffset(1, -1)
    end

    newFrame.textCharges = newFrame.frameText:CreateFontString(nil, "OVERLAY")
    newFrame.textCharges:SetFont(font, addon:GetNumberOrDefault(12, SettingsDB.chargesFontSize), SettingsDB.chargesFontFlags or "OUTLINE")
    newFrame.textCharges:SetTextColor(1, 1, 1, 1)
    newFrame.textCharges:SetShadowColor(0, 0, 0, 1)
    newFrame.textCharges:SetShadowOffset(0, 0)
    newFrame.textCharges:SetPoint("BOTTOMRIGHT", newFrame.frameText, "BOTTOMRIGHT", 0, 0)
    newFrame.textCharges:SetText("")
    if SettingsDB.chargesFontShadow then
        newFrame.textCharges:SetShadowColor(0, 0, 0, 0.5)
        newFrame.textCharges:SetShadowOffset(1, -1)
    end

    newFrame.textCooldown = newFrame.frameText:CreateFontString(nil, "OVERLAY")
    newFrame.textCooldown:SetFont(font, addon:GetNumberOrDefault(16, SettingsDB.cooldownFontSize), SettingsDB.cooldownFontFlags or "OUTLINE")
    newFrame.textCooldown:SetPoint("CENTER", newFrame.frameText, "CENTER", 0, 0)
    newFrame.textCooldown:SetText("")
    newFrame.textCooldown:SetTextColor(1, 1, 1, 1)
    if SettingsDB.cooldownFontShadow then
        newFrame.textCooldown:SetShadowColor(0, 0, 0, 0.5)
        newFrame.textCooldown:SetShadowOffset(1, -1)
    end

    newFrame.textRank = newFrame.frameText:CreateFontString(nil, "OVERLAY")
    newFrame.textRank:SetFont(font, addon:GetNumberOrDefault(12, SettingsDB.rankFontSize), SettingsDB.rankFontFlags or "OUTLINE")
    newFrame.textRank:SetPoint("BOTTOMLEFT", newFrame.frameText, "BOTTOMLEFT", 0, 0)
    newFrame.textRank:SetText(newFrame.itemRank)
    newFrame.textRank:SetTextColor(0, 1, 0, 1)
    if SettingsDB.rankFontShadow then
        newFrame.textRank:SetShadowColor(0, 0, 0, 0.5)
        newFrame.textRank:SetShadowOffset(1, -1)
    end

    newFrame.textID = newFrame.frameText:CreateFontString(nil, "OVERLAY")
    newFrame.textID:SetFont(font, addon:GetNumberOrDefault(12, SettingsDB.bindingFontSize), SettingsDB.bindingFontFlags or "OUTLINE")
    newFrame.textID:SetPoint("CENTER", newFrame.frameText, "CENTER", 0, 0)
    newFrame.textID:SetTextColor(1, 1, 1, 1)
    if newFrame.itemID > 0 then
        newFrame.textID:SetText(tostring(newFrame.itemID))
    else
        newFrame.textID:SetText(tostring(newFrame.spellID))
    end
    if SettingsDB.cooldownFontShadow then
        newFrame.textID:SetShadowColor(0, 0, 0, 0.5)
        newFrame.textID:SetShadowOffset(1, -1)
    end

    newFrame.textureIcon = newFrame:CreateTexture(nil, "ARTWORK")
    newFrame.textureIcon:SetAllPoints(newFrame)
    newFrame.textureIcon:SetTexture(newFrame.iconID)

    for _, seasonSpellID in pairs(addon.currentSeason) do
        if newFrame.spellID == seasonSpellID then
            LCG.PixelGlow_Start(newFrame, { 1, 1, 0, 1 }, 6, 0.2, 6, 2, 2, 0, 0)
        end
    end

    return newFrame
end

local function GetAura(auraList, currentSpellID, frame)
    if not auraList then
        return nil
    end

    local itemBuffs = nil
    local spellBuffs = nil

    if frame.itemID > 0 then
        itemBuffs = addon.itemBuffs[frame.itemID]
    end

    if frame.spellID > 0 then
        spellBuffs = addon.spellBuffs[frame.spellID]
    end

    if itemBuffs then
        for j = 1, #itemBuffs do
            local auraName = itemBuffs[j]

            for i = 1, #auraList do
                local aura = auraList[i]

                if aura.name == auraName then
                    return aura
                end
            end
        end
    end

    if spellBuffs then
        for j = 1, #spellBuffs do
            local auraName = spellBuffs[j]

            for i = 1, #auraList do
                local aura = auraList[i]

                if aura.name == auraName then
                    return aura
                end
            end
        end
    end

    for i = 1, #auraList do
        local aura = auraList[i]

        if aura.spellId == currentSpellID or aura.spellId == frame.spellID or aura.name == frame.itemName or aura.name == frame.spellName then
            if aura.name == "Ascendance" then
                if aura.spellId == 457594 or aura.spellId == 458502 or aura.spellId == 458573 or aura.spellId == 463003 or aura.spellId == 463095 then
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

local function GetTotem(auraList, currentSpellID, frame)
    if not auraList then
        return nil
    end

    local totemBuffs = nil

    if frame.spellID > 0 then
        totemBuffs = addon.totemBuffs[frame.spellID]
    end

    if totemBuffs then
        for j = 1, #totemBuffs do
            local auraName = totemBuffs[j]

            for i = 1, #auraList do
                local aura = auraList[i]

                if aura.name == auraName then
                    return aura
                end
            end
        end
    end

    for i = 1, #auraList do
        local aura = auraList[i]

        if aura.spellId == currentSpellID or aura.spellId == frame.spellID or aura.name == frame.itemName or aura.name == frame.spellName then
            return aura
        end
    end

    return nil
end

local function IsAuraActiveBuff(auraList, currentSpellID, frame)
    local aura = GetAura(auraList, currentSpellID, frame)

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

local function IsAuraActiveDebuff(auraList, currentSpellID, frame)
    local aura = GetAura(auraList, currentSpellID, frame)

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

local function IsAuraActiveTotem(auraList, currentSpellID, frame)
    local aura = GetTotem(auraList, currentSpellID, frame)

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

local function RefreshCategoryFrame(category, parentTable, playerSpecID)
    if not category then
        return
    end

    if not parentTable then
        return
    end

    if category == addon.categoryIgnored then
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

        for i = 1, #parentTable.items do
            local iconFrame = parentTable.items[i]

            if iconFrame.isTrinket then
                table.insert(allIcons, iconFrame)
            end
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

            if iconFrame.isTrinket == false then
                if not seenSettingNames[iconFrame.settingName] then
                    table.insert(allIcons, iconFrame)
                end
            end
        end

        if allIcons and next(allIcons) ~= nil then
            for i = 1, #allIcons do
                local iconFrame = allIcons[i]

                if category == addon.categoryUnknown then
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

                if i == 1 then
                    iconFrame:SetPoint("TOPLEFT", parentTable.frame, "TOPLEFT", 0, 0)
                else
                    local wrapIndex = (wrapAfter > 0) and ((i - 1) % wrapAfter == 0)
                    if wrapIndex then
                        local previousWrap = allIcons[i - wrapAfter]
                        if isVertical then
                            iconFrame:SetPoint("TOPLEFT", previousWrap, "TOPRIGHT", iconSpacing, 0)
                        else
                            iconFrame:SetPoint("TOPLEFT", previousWrap, "BOTTOMLEFT", 0, -iconSpacing)
                        end
                    else
                        local previous = allIcons[i - 1]
                        if isVertical then
                            iconFrame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -iconSpacing)
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

local function updateIconAuraBuff(currentSpellID, frame, playerBuffs, playerTotems, settingsTable)
    if settingsTable.showWhenAvailable then
        return false
    end

    if IsAuraActiveBuff(playerBuffs, currentSpellID, frame) == false then
        if IsAuraActiveTotem(playerTotems, currentSpellID, frame) == false then
            return false
        end
    end

    frame:SetAlpha(1.0)
    frame.frameBorder:SetBackdropBorderColor(0, 1, 0, 1)
    frame.frameBorder:Show()
    frame.textureIcon:SetDesaturated(false)
    frame.textureIcon:SetVertexColor(0, 1, 0)

    if frame.auraIcon > 0 and frame.currentIcon ~= frame.auraIcon then
        frame.currentIcon = frame.auraIcon
        frame.textureIcon:SetTexture(frame.auraIcon)
    end

    if frame.auraRemaining > 0 and frame.auraRemaining <= 90 then
        frame.textCooldown:SetText(string.format("%d", frame.auraRemaining))
        frame.textCooldown:SetTextColor(0, 1, 0, 1)
    end

    if frame.auraStacks > 0 then
        frame.textCharges:SetText(frame.auraStacks)
    end

    if frame.auraRemaining > 0 and settingsTable.glowWhenAuraActive and not frame.isGlowActive then
        ActionButton_ShowOverlayGlow(frame)
        frame.isGlowActive = true
    end

    return true
end

local function updateIconAuraDebuff(currentSpellID, frame, settingsTable, spellCooldownMS, targetDebuffs)
    if frame.isHarmful == false then
        return false
    end

    if settingsTable.showWhenAvailable then
        return false
    end

    if spellCooldownMS > 0 then
        return false
    end

    if IsAuraActiveDebuff(targetDebuffs, currentSpellID, frame) == false then
        return false
    end

    if settingsTable.showOnCooldown then
        if frame.auraRemaining <= 0 or frame.auraRemaining > 5 then
            frame:SetAlpha(0.0)

            return true
        end
    end

    frame:SetAlpha(1.0)
    frame.frameBorder:SetBackdropBorderColor(1, 0, 1, 1)
    frame.frameBorder:Show()
    frame.textureIcon:SetDesaturated(false)
    frame.textureIcon:SetVertexColor(1, 0, 1)

    if frame.auraIcon > 0 and frame.currentIcon ~= frame.auraIcon then
        frame.currentIcon = frame.auraIcon
        frame.textureIcon:SetTexture(frame.auraIcon)
    end

    if frame.auraRemaining > 0 and frame.auraRemaining <= 90 then
        frame.textCooldown:SetText(string.format("%d", frame.auraRemaining))
        frame.textCooldown:SetTextColor(1, 0, 1, 1)
    end

    if frame.auraStacks > 0 then
        frame.textCharges:SetText(frame.auraStacks)
    end

    if frame.auraRemaining > 0 and settingsTable.glowWhenAuraActive and not frame.isGlowActive then
        ActionButton_ShowOverlayGlow(frame)
        frame.isGlowActive = true
    end

    return true
end

local function updateIcon(isItem, frame, gcdCooldown, playerBuffs, playerTotems, settingsTable, targetDebuffs)
    frame.auraIcon = -1
    frame.auraRemaining = -1
    frame.auraStacks = -1

    local currentSpellID
    local overrideSpell = C_Spell.GetOverrideSpell(frame.spellID) or frame.spellID
    local spellCharges = nil
    local spellCooldownMS = 0

    if isItem then
        currentSpellID = frame.spellID
    else
        if frame.spellID ~= overrideSpell then
            currentSpellID = overrideSpell
        else
            currentSpellID = frame.spellID
        end

        spellCharges = C_Spell.GetSpellCharges(currentSpellID)

        if spellCharges then
            if spellCharges.cooldownDuration > 0 then
                spellCooldownMS = spellCharges.cooldownDuration * 1000
            end
        else
            local cooldownMS, gcdMS = GetSpellBaseCooldown(currentSpellID)
            if cooldownMS and cooldownMS > 0 then
                spellCooldownMS = cooldownMS
            end
        end
    end

    frame.textCharges:SetText("")
    frame.textCooldown:SetText("")

    if updateIconAuraBuff(currentSpellID, frame, playerBuffs, playerTotems, settingsTable) then
        return
    end

    if updateIconAuraDebuff(currentSpellID, frame, settingsTable, spellCooldownMS, targetDebuffs) then
        return
    end

    if frame.itemID > 0 then
        if frame.isTrinket and frame.itemIsUsable == false then
            frame.frameBorder:Hide()
            frame.textureIcon:SetDesaturated(true)
            frame.textureIcon:SetVertexColor(1, 1, 1)

            if settingsTable.glowWhenAuraActive and frame.isGlowActive then
                ActionButton_HideOverlayGlow(frame)
                frame.isGlowActive = false
            end

            return
        end
    else
        if spellCooldownMS <= 0 then
            if settingsTable.showWhenAvailable then
                frame:SetAlpha(0.0)
            else
                frame:SetAlpha(1.0)

                if currentSpellID == 436854 or currentSpellID == 460003 or currentSpellID == 461063 or currentSpellID == 1231411 then
                    frame.frameBorder:Hide()
                else
                    frame.frameBorder:SetBackdropBorderColor(1, 0, 0, 1)
                    frame.frameBorder:Show()
                    frame.textureIcon:SetDesaturated(true)
                    frame.textureIcon:SetVertexColor(1, 1, 1)
                end
            end

            if settingsTable.glowWhenAuraActive and frame.isGlowActive then
                ActionButton_HideOverlayGlow(frame)
                frame.isGlowActive = false
            end

            return
        end
    end

    frame.frameBorder:Hide()
    frame.textureIcon:SetDesaturated(false)
    frame.textureIcon:SetVertexColor(1, 1, 1)

    local isGlowActive = false
    local isOnCooldown = false
    local isVisible = false

    if not settingsTable.showOnCooldown and not settingsTable.showWhenAvailable then
        isVisible = true
    end

    if isItem then
        if frame.isTrinket == false then
            local count = C_Item.GetItemCount(frame.itemID, false, true, false, false)
            if count <= 0 then
                frame:SetAlpha(0.0)
                return
            end

            frame.textCharges:SetText(count)
        end

        local startTime, duration, enable = C_Container.GetItemCooldown(frame.itemID)

        if enable and duration > 0 then
            if gcdCooldown.isEnabled and gcdCooldown.duration > 0 then
            else
                frame.frameCooldownSpell:SetCooldown(startTime, duration)
            end
        else
            frame.frameCooldownSpell:Clear()
        end

        if enable and duration > 2 then
            local remaining = (startTime + duration) - GetTime()
            if remaining > 0 then
                if remaining < 90 then
                    frame.textCooldown:SetText(string.format("%d", remaining))
                    frame.textCooldown:SetTextColor(1, 0, 0, 1)
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
    else
        local isSpellDisabled = C_Spell.IsSpellDisabled(currentSpellID)
        if isSpellDisabled then
            frame:SetAlpha(0.0)
            return
        end

        if frame.spellID == currentSpellID then
            if frame.currentIcon ~= frame.iconID then
                frame.currentIcon = frame.iconID
                frame.textureIcon:SetTexture(frame.iconID)
            end
        else
            local spellInfo = C_Spell.GetSpellInfo(currentSpellID)
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

        local spellCooldown = C_Spell.GetSpellCooldown(currentSpellID)

        if spellCooldown and spellCooldown.isEnabled and spellCooldown.duration > 0 then
            if gcdCooldown.isEnabled and gcdCooldown.duration > 0 then
            else
                frame.frameCooldownSpell:SetCooldown(spellCooldown.startTime, spellCooldown.duration)
            end
        else
            frame.frameCooldownSpell:Clear()
        end

        if spellCharges and spellCharges.maxCharges > 1 then
            frame.textCharges:SetText(spellCharges.currentCharges)

            if spellCharges.currentCharges > 0 then
                if settingsTable.showWhenAvailable then
                    isVisible = true
                end

                if isVisible and spellCharges.currentCharges < spellCharges.maxCharges then
                    frame.frameBorder:SetBackdropBorderColor(1, 0, 0, 1)
                    frame.frameBorder:Show()
                end
            else
                if spellCharges.cooldownStartTime and spellCharges.cooldownDuration and spellCharges.cooldownDuration > 2 then
                    local remaining = (spellCharges.cooldownStartTime + spellCharges.cooldownDuration) - GetTime()
                    if remaining > 0 then
                        if remaining < 90 then
                            frame.textCooldown:SetText(string.format("%d", remaining))
                            frame.textCooldown:SetTextColor(1, 0, 0, 1)
                        end

                        if settingsTable.showOnCooldown then
                            isVisible = true
                        end

                        isOnCooldown = true
                    end
                end
            end
        else
            if spellCooldown and spellCooldown.isEnabled and spellCooldown.duration > 2 then
                local remaining = (spellCooldown.startTime + spellCooldown.duration) - GetTime()
                if remaining > 0 then
                    if remaining < 90 then
                        frame.textCooldown:SetText(string.format("%d", remaining))
                        frame.textCooldown:SetTextColor(1, 0, 0, 1)
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
    end

    if isVisible then
        frame:SetAlpha(1.0)

        if isOnCooldown then
            frame.frameBorder:SetBackdropBorderColor(1, 0, 0, 1)
            frame.frameBorder:Show()
            frame.textBinding:Hide()
            frame.textureIcon:SetDesaturated(true)
        else
            frame.textBinding:Show()
            frame.textureIcon:SetDesaturated(false)

            if isItem == false then
                local isSpellUsable, inSufficientPower = C_Spell.IsSpellUsable(currentSpellID)

                if not isSpellUsable then
                    if inSufficientPower then
                        frame.textureIcon:SetVertexColor(0.5, 0.5, 1)
                    else
                        frame.textureIcon:SetVertexColor(1, 0, 0)
                    end
                end
            end
        end

        if isItem == false then
            if SettingsDB.showGlobalSweep and frame.frameCooldownGCD then
                if gcdCooldown.isEnabled and gcdCooldown.duration > 0 then
                    frame.frameCooldownGCD:SetCooldown(gcdCooldown.startTime, gcdCooldown.duration)
                else
                    frame.frameCooldownGCD:Clear()
                end
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

    local validCategories = addon:GetValidCategories()

    for i = 1, #validCategories do
        local name = validCategories[i]

        if categories[name] then
            local frame = categories[name].frame

            if frame then
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
    end

    addon:RefreshCategoryFrames()
end

function addon:InitializeIcons()
    if InCombatLockdown() then
        return
    end

    for _, iconFrame in pairs(iconFrames) do
        UnregisterAttributeDriver(iconFrame, "state-visibility")

        iconFrame:ClearAllPoints()
        iconFrame:Hide()
        iconFrame:SetParent(nil)

        iconFrame = nil
    end
    wipe(iconFrames)
    iconFrames = {}

    collectgarbage("collect")

    for key, knownSpell in pairs(addon:GetKnownSpells()) do
        local newIcon = CreateIconFrame(knownSpell)
        if newIcon then
            iconFrames[newIcon.settingName] = newIcon
        end
    end

    addon:UpdateButtonKeyBinds()
    addon:CheckLockState()
end

function addon:RefreshCategoryFrames()
    if InCombatLockdown() then
        return
    end

    local playerSpecID = addon:GetPlayerSpecID()
    if not playerSpecID then
        return
    end

    local validCategories = addon:GetValidCategories()

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
            if iconFrame.spellID > 0 and cooldownManagerSpells[iconFrame.spellID] and cooldownManagerSpells[iconFrame.spellID] == true then
                category = addon.categoryIgnored
                SpellsDB[iconFrame.specID][settingName] = addon.categoryIgnored
            else
                category = addon.categoryUnknown
            end
        end

        if iconFrame.itemID > 0 then
            if iconFrame.isTrinket then
                table.insert(categories[addon.categoryTrinket].items, iconFrame)
            else
                local count = C_Item.GetItemCount(iconFrame.itemID, false, true, false, false)
                if count <= 0 then
                    table.insert(categories[addon.categoryIgnored].items, iconFrame)
                else
                    table.insert(categories[category].items, iconFrame)
                end
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

function addon:UpdateButtonState()
    local validCategories = addon:GetValidCategories()

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
                        applications = 1,
                        auraInstanceID = 1,
                        canApplyAura = false,
                        charges = 1,
                        dispelName = "",
                        duration = duration,
                        expirationTime = startTime + duration,
                        icon = icon,
                        isBossAura = false,
                        isFromPlayerOrPlayerPet = true,
                        isHarmful = false,
                        isHelpful = true,
                        isNameplateOnly = false,
                        isRaid = false,
                        isStealable = false,
                        maxCharges = 1,
                        name = totemName,
                        nameplateShowAll = false,
                        nameplateShowPersonal = false,
                        points = {},
                        sourceUnit = "",
                        spellId = spellID,
                        timeMod = modRate,
                    })
            end
        end

        for index = 1, #validCategories do
            local category = validCategories[index]
            if category ~= addon.categoryIgnored and category ~= addon.categoryUnknown and categories[category] then
                local parentTable = categories[category]
                local settingsTable = addon:GetSettingsTable(category)

                if parentTable.items then
                    for i = 1, #parentTable.items do
                        updateIcon(true, parentTable.items[i], gcdCooldown, playerBuffs, playerTotems, settingsTable, targetDebuffs)
                    end
                end

                if parentTable.spells then
                    for i = 1, #parentTable.spells do
                        updateIcon(false, parentTable.spells[i], gcdCooldown, playerBuffs, playerTotems, settingsTable, targetDebuffs)
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

function addon:UpdateButtonKeyBinds()
    local fontSizeEssential = SettingsDB.bindingFontSize or 16
    local fontSizeUtility = fontSizeEssential - 4
    local knownSlots = addon:GetKnownSlots()

    cooldownManagerSpells = {}

    for _, iconFrame in pairs(iconFrames) do
        local keyBind = KnownSlot:GetKeyBind(iconFrame.itemID, iconFrame.itemName, iconFrame.spellID, iconFrame.spellName, knownSlots)

        if keyBind and keyBind ~= "" then
            iconFrame.textBinding:SetText(keyBind)
        end
    end

    for _, icon in ipairs({ EssentialCooldownViewer:GetChildren() }) do
        CheckTextBinding(fontSizeEssential, icon, knownSlots)
    end

    for _, icon in ipairs({ UtilityCooldownViewer:GetChildren() }) do
        CheckTextBinding(fontSizeUtility, icon, knownSlots)
    end
end
