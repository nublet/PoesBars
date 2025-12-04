local addonName, addon = ...

KnownSpell = {}
KnownSpell.__index = KnownSpell

local LCG = LibStub("LibCustomGlow-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
local font = LSM:Fetch("font", "Naowh") or "Fonts\\FRIZQT__.TTF"

-- Private

local function GetAura(auraList, currentSpellID, frame)
    if not auraList then
        return nil
    end

    local itemBuffs = nil
    local spellBuffs = nil

    if frame.itemID and frame.itemID > 0 then
        itemBuffs = addon.itemBuffs[frame.itemID]
    end

    if frame.spellID and frame.spellID > 0 then
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

    if frame.spellID and frame.spellID > 0 then
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

function KnownSpell:CopyTo(targetFrame)
    targetFrame.iconID = self.iconID
    targetFrame.isHarmful = self.isHarmful
    targetFrame.isUsable = self.isUsable
    targetFrame.itemID = self.itemID
    targetFrame.itemName = self.itemName
    targetFrame.itemRank = self.itemRank
    targetFrame.playerSpecID = self.playerSpecID
    targetFrame.settingName = self.settingName
    targetFrame.slotID = self.slotID
    targetFrame.specID = self.specID
    targetFrame.spellID = self.spellID
    targetFrame.spellName = self.spellName
end

function KnownSpell:CreateIcon()
    if self.itemID <= 0 and self.slotID <= 0 and self.spellID <= 0 then
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

    self:CopyTo(newFrame)

    if newFrame.slotID > 0 then
        newFrame:SetAttribute("type", "item")
        newFrame:SetAttribute("item", "slot:" .. newFrame.slotID)
        newFrame:SetScript("OnEnter", function(control)
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            GameTooltip:SetInventoryItem("player", newFrame.slotID)
            GameTooltip:Show()
        end)
    elseif newFrame.itemID > 0 then
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
    if newFrame.slotID > 0 then
        newFrame.textID:SetText(tostring(newFrame.slotID))
    elseif newFrame.itemID > 0 then
        newFrame.textID:SetText(tostring(newFrame.itemID))
    else
        newFrame.textID:SetText(tostring(newFrame.spellID))

        local portalName = addon.portalNames[newFrame.spellID]
        if portalName and portalName ~= "" then
            newFrame.portalName = newFrame.frameText:CreateFontString(nil, "OVERLAY")
            newFrame.portalName:SetFont(font, 10, "OUTLINE")
            newFrame.portalName:SetPoint("BOTTOM", newFrame.frameText, "BOTTOM", 0, 2)
            newFrame.portalName:SetShadowColor(0, 0, 0, 0.5)
            newFrame.portalName:SetShadowOffset(1, -1)
            newFrame.portalName:SetTextColor(1, 1, 1, 1)
            newFrame.portalName:SetText(portalName)
        end
    end
    if SettingsDB.cooldownFontShadow then
        newFrame.textID:SetShadowColor(0, 0, 0, 0.5)
        newFrame.textID:SetShadowOffset(1, -1)
    end

    newFrame.textureIcon = newFrame:CreateTexture(nil, "ARTWORK")
    newFrame.textureIcon:SetAllPoints(newFrame)

    for _, seasonSpellID in pairs(addon.currentSeason) do
        if newFrame.spellID == seasonSpellID then
            LCG.PixelGlow_Start(newFrame, { 1, 1, 0, 1 }, 6, 0.2, 6, 2, 2, 0, 0)
        end
    end

    function newFrame:RefreshIcon()
        if self.slotID and self.slotID > 0 then
            self.itemID = GetInventoryItemID("player", self.slotID)
        end

        if self.spellID and self.spellID > 0 then
            if C_Spell.IsSpellHarmful(self.spellID) then
                self.isHarmful = true
            else
                self.isHarmful = false
            end

            local spellInfo = C_Spell.GetSpellInfo(self.spellID)
            if spellInfo then
                self.iconID = spellInfo.iconID
                self.spellName = addon:NormalizeText(spellInfo.name)
            else
                local newSpellID = C_Spell.GetOverrideSpell(self.spellID) or self.spellID
                if newSpellID and newSpellID ~= self.spellID then
                    local newSpellInfo = C_Spell.GetSpellInfo(newSpellID)
                    if newSpellInfo then
                        self.iconID = newSpellInfo.iconID
                        self.spellName = addon:NormalizeText(newSpellInfo.name)
                    end
                end
            end

            self.textureIcon:SetTexture(self.iconID)
        end

        if self.itemID and self.itemID > 0 then
            local item = Item:CreateFromItemID(self.itemID)
            local usable, noMana = C_Item.IsUsableItem(self.itemID)

            self.iconID = item:GetItemIcon()
            self.isUsable = usable
            self.itemName = addon:NormalizeText(item:GetItemName())

            if self.spellID <= 0 then
                local _, itemSpellID = C_Item.GetItemSpell(self.itemID)
                if itemSpellID and itemSpellID > 0 then
                    self.spellID = itemSpellID
                else
                    itemSpellID = C_Item.GetFirstTriggeredSpellForItem(self.itemID, 4)
                    if itemSpellID and itemSpellID > 0 then
                        self.spellID = itemSpellID
                    else
                        itemSpellID = C_Item.GetFirstTriggeredSpellForItem(self.itemID, 3)
                        if itemSpellID and itemSpellID > 0 then
                            self.spellID = itemSpellID
                        else
                            itemSpellID = C_Item.GetFirstTriggeredSpellForItem(self.itemID, 2)
                            if itemSpellID and itemSpellID > 0 then
                                self.spellID = itemSpellID
                            end
                        end
                    end
                end

                self.spellID = addon:GetNumberOrDefault(-1, self.spellID)

                if self.spellID > 0 then
                    local spellInfo = C_Spell.GetSpellInfo(self.spellID)
                    if spellInfo then
                        self.spellName = addon:NormalizeText(spellInfo.name)
                    end
                end
            end

            item:ContinueOnItemLoad(function()
                self.iconID = item:GetItemIcon()
                self.itemName = addon:NormalizeText(item:GetItemName())

                self.textureIcon:SetTexture(self.iconID)

                local itemLink = item:GetItemLink()
                if itemLink then
                    local qualityTier = itemLink:match("|A:Professions%-ChatIcon%-Quality%-Tier(%d+)")

                    if qualityTier then
                        if qualityTier == "1" then
                            self.itemRank = "R1"
                        elseif qualityTier == "2" then
                            self.itemRank = "R2"
                        elseif qualityTier == "3" then
                            self.itemRank = "R3"
                        end
                    end
                end
            end)
        end
    end

    function newFrame:RefreshKeyBind(knownSlots)
        local keyBind = KnownSlot:GetKeyBind(self.itemID, self.itemName, self.spellID, self.spellName, knownSlots)

        if keyBind and keyBind ~= "" then
            self.textBinding:SetText(keyBind)
        end
    end

    function newFrame:UpdateAuraBuff(currentSpellID, playerBuffs, playerTotems, settingsTable)
        if settingsTable.showWhenAvailable then
            return false
        end

        if IsAuraActiveBuff(playerBuffs, currentSpellID, self) == false then
            if IsAuraActiveTotem(playerTotems, currentSpellID, self) == false then
                return false
            end
        end

        self:SetAlpha(1.0)
        self.frameBorder:SetBackdropBorderColor(0, 1, 0, 1)
        self.frameBorder:Show()
        self.textureIcon:SetDesaturated(false)
        self.textureIcon:SetVertexColor(0, 1, 0)

        if self.auraIcon > 0 and self.currentIcon ~= self.auraIcon then
            self.currentIcon = self.auraIcon
            self.textureIcon:SetTexture(self.auraIcon)
        end

        if self.auraRemaining > 0 and self.auraRemaining <= 90 then
            self.textCooldown:SetText(string.format("%d", self.auraRemaining))
            self.textCooldown:SetTextColor(0, 1, 0, 1)
        end

        if self.auraStacks > 0 then
            self.textCharges:SetText(tostring(self.auraStacks))
        end

        if self.auraRemaining > 0 and settingsTable.glowWhenAuraActive and not self.isGlowActive then
            ActionButton_ShowOverlayGlow(self)
            self.isGlowActive = true
        end

        return true
    end

    function newFrame:UpdateAuraDebuff(currentSpellID, settingsTable, spellCooldownMS, targetDebuffs)
        if self.isHarmful == false then
            return false
        end

        if settingsTable.showWhenAvailable then
            return false
        end

        if spellCooldownMS > 0 then
            return false
        end

        if IsAuraActiveDebuff(targetDebuffs, currentSpellID, self) == false then
            return false
        end

        if settingsTable.showOnCooldown then
            if self.auraRemaining <= 0 or self.auraRemaining > 5 then
                self:SetAlpha(0.0)

                return true
            end
        end

        self:SetAlpha(1.0)
        self.frameBorder:SetBackdropBorderColor(1, 0, 1, 1)
        self.frameBorder:Show()
        self.textureIcon:SetDesaturated(false)
        self.textureIcon:SetVertexColor(1, 0, 1)

        if self.auraIcon > 0 and self.currentIcon ~= self.auraIcon then
            self.currentIcon = self.auraIcon
            self.textureIcon:SetTexture(self.auraIcon)
        end

        if self.auraRemaining > 0 and self.auraRemaining <= 90 then
            self.textCooldown:SetText(string.format("%d", self.auraRemaining))
            self.textCooldown:SetTextColor(1, 0, 1, 1)
        end

        if self.auraStacks > 0 then
            self.textCharges:SetText(tostring(self.auraStacks))
        end

        if self.auraRemaining > 0 and settingsTable.glowWhenAuraActive and not self.isGlowActive then
            ActionButton_ShowOverlayGlow(self)
            self.isGlowActive = true
        end

        return true
    end

    function newFrame:UpdateState(gcdCooldown, playerBuffs, playerTotems, settingsTable, targetDebuffs)
        if SettingsDB.isLocked == false then
            self:SetAlpha(1.0)
            self.frameBorder:SetBackdropBorderColor(1, 1, 1, 1)
            self.frameBorder:Show()
            return
        end

        self.auraIcon = -1
        self.auraRemaining = -1
        self.auraStacks = -1

        local currentSpellID
        local overrideSpell = C_Spell.GetOverrideSpell(self.spellID) or self.spellID
        local spellCharges = nil
        local spellCooldownMS = 0

        if self.itemID and self.itemID > 0 then
            currentSpellID = self.spellID
        else
            if self.spellID ~= overrideSpell then
                currentSpellID = overrideSpell
            else
                currentSpellID = self.spellID
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

        self.textCharges:SetText("")
        self.textCooldown:SetText("")

        if self:UpdateAuraBuff(currentSpellID, playerBuffs, playerTotems, settingsTable) then
            return
        end

        if self:UpdateAuraDebuff(currentSpellID, settingsTable, spellCooldownMS, targetDebuffs) then
            return
        end

        if self.slotID and self.slotID > 0 then
            if self.isUsable == false then
                self.frameBorder:Hide()
                self.textureIcon:SetDesaturated(true)
                self.textureIcon:SetVertexColor(1, 1, 1)

                if settingsTable.glowWhenAuraActive and self.isGlowActive then
                    ActionButton_HideOverlayGlow(self)
                    self.isGlowActive = false
                end

                return
            end
        elseif self.itemID and self.itemID > 0 then
        elseif self.spellID and self.spellID > 0 then
            if spellCooldownMS <= 0 then
                if settingsTable.showWhenAvailable then
                    self:SetAlpha(0.0)
                else
                    self:SetAlpha(1.0)

                    if currentSpellID == 436854 or currentSpellID == 460003 or currentSpellID == 461063 or currentSpellID == 1231411 then
                        self.frameBorder:Hide()
                    else
                        self.frameBorder:SetBackdropBorderColor(1, 0, 0, 1)
                        self.frameBorder:Show()
                        self.textureIcon:SetDesaturated(true)
                        self.textureIcon:SetVertexColor(1, 1, 1)
                    end
                end

                if settingsTable.glowWhenAuraActive and self.isGlowActive then
                    ActionButton_HideOverlayGlow(self)
                    self.isGlowActive = false
                end

                return
            end
        end

        self.frameBorder:Hide()
        self.textureIcon:SetDesaturated(false)
        self.textureIcon:SetVertexColor(1, 1, 1)

        local isGlowActive = false
        local isOnCooldown = false
        local isVisible = false

        if not settingsTable.showOnCooldown and not settingsTable.showWhenAvailable then
            isVisible = true
        end

        if self.itemID > 0 then
            if self.slotID <= 0 then
                local count = C_Item.GetItemCount(self.itemID, false, true, false, false)
                if count <= 0 then
                    self:SetAlpha(0.0)
                    return
                end

                self.textCharges:SetText(tostring(count))
            end

            local startTime, duration, enable = C_Container.GetItemCooldown(self.itemID)

            if enable and duration > 0 then
                if gcdCooldown.isEnabled and gcdCooldown.duration > 0 then
                else
                    self.frameCooldownSpell:SetCooldown(startTime, duration)
                end
            else
                self.frameCooldownSpell:Clear()
            end

            if enable and duration > 2 then
                local remaining = (startTime + duration) - GetTime()
                if remaining > 0 then
                    if remaining < 90 then
                        self.textCooldown:SetText(string.format("%d", remaining))
                        self.textCooldown:SetTextColor(1, 0, 0, 1)
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
                self:SetAlpha(0.0)
                return
            end

            if self.spellID == currentSpellID then
                if self.currentIcon ~= self.iconID then
                    self.currentIcon = self.iconID
                    self.textureIcon:SetTexture(self.iconID)
                end
            else
                local spellInfo = C_Spell.GetSpellInfo(currentSpellID)
                if spellInfo then
                    if self.currentIcon ~= spellInfo.iconID then
                        self.currentIcon = spellInfo.iconID
                        self.textureIcon:SetTexture(spellInfo.iconID)
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
                    self.frameCooldownSpell:SetCooldown(spellCooldown.startTime, spellCooldown.duration)
                end
            else
                self.frameCooldownSpell:Clear()
            end

            if spellCharges and spellCharges.maxCharges > 1 then
                self.textCharges:SetText(tostring(spellCharges.currentCharges))

                if spellCharges.currentCharges > 0 then
                    if settingsTable.showWhenAvailable then
                        isVisible = true
                    end

                    if isVisible and spellCharges.currentCharges < spellCharges.maxCharges then
                        self.frameBorder:SetBackdropBorderColor(1, 0, 0, 1)
                        self.frameBorder:Show()
                    end
                else
                    if spellCharges.cooldownStartTime and spellCharges.cooldownDuration and spellCharges.cooldownDuration > 2 then
                        local remaining = (spellCharges.cooldownStartTime + spellCharges.cooldownDuration) - GetTime()
                        if remaining > 0 then
                            if remaining < 90 then
                                self.textCooldown:SetText(string.format("%d", remaining))
                                self.textCooldown:SetTextColor(1, 0, 0, 1)
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
                            self.textCooldown:SetText(string.format("%d", remaining))
                            self.textCooldown:SetTextColor(1, 0, 0, 1)
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
            self:SetAlpha(1.0)

            if isOnCooldown then
                self.frameBorder:SetBackdropBorderColor(1, 0, 0, 1)
                self.frameBorder:Show()
                self.textBinding:Hide()
                self.textureIcon:SetDesaturated(true)
            else
                self.textBinding:Show()
                self.textureIcon:SetDesaturated(false)

                if self.itemID <= 0 then
                    local isSpellUsable, inSufficientPower = C_Spell.IsSpellUsable(currentSpellID)

                    if not isSpellUsable then
                        if inSufficientPower then
                            self.textureIcon:SetVertexColor(0.5, 0.5, 1)
                        else
                            self.textureIcon:SetVertexColor(1, 0, 0)
                        end
                    end
                end
            end

            if self.itemID <= 0 then
                if SettingsDB.showGlobalSweep and self.frameCooldownGCD then
                    if gcdCooldown.isEnabled and gcdCooldown.duration > 0 then
                        self.frameCooldownGCD:SetCooldown(gcdCooldown.startTime, gcdCooldown.duration)
                    else
                        self.frameCooldownGCD:Clear()
                    end
                end
            end

            if isGlowActive then
                if not self.isGlowActive then
                    ActionButton_ShowOverlayGlow(self)
                    self.isGlowActive = true
                end
            else
                if self.isGlowActive then
                    ActionButton_HideOverlayGlow(self)
                    self.isGlowActive = false
                end
            end
        else
            self:SetAlpha(0.0)
        end
    end

    return newFrame
end

-- Shared

function KnownSpell:Add(itemID, playerSpecID, slotID, specID, spellID, knownSpells)
    local newItem = setmetatable({}, KnownSpell)
    newItem.iconID = -1
    newItem.isHarmful = false
    newItem.isUsable = false
    newItem.itemID = addon:GetNumberOrDefault(-1, itemID)
    newItem.itemName = ""
    newItem.itemRank = ""
    newItem.playerSpecID = addon:GetNumberOrDefault(-1, playerSpecID)
    newItem.slotID = addon:GetNumberOrDefault(-1, slotID)
    newItem.specID = addon:GetNumberOrDefault(-1, specID)
    newItem.spellID = addon:GetNumberOrDefault(-1, spellID)
    newItem.spellName = ""

    if newItem.slotID > 0 then
        local slotItemID = addon:GetNumberOrDefault(-1, GetInventoryItemID("player", newItem.slotID))
        if slotItemID <= 0 then
            return nil
        end

        newItem.settingName = newItem.slotID .. "_-1_-1"
    elseif newItem.itemID > 0 then
        newItem.settingName = newItem.itemID .. "_-1"
    elseif newItem.spellID > 0 then
        newItem.settingName = "-1_" .. newItem.spellID
    else
        return nil
    end

    local key = addon:NormalizeText(newItem.itemID .. "_" .. newItem.playerSpecID .. "_" .. newItem.slotID .. "_" .. newItem.specID .. "_" .. newItem.spellID)
    if knownSpells[key] then
        return nil
    end

    if not SpellsDB[newItem.specID] then
        SpellsDB[newItem.specID] = {}
    end

    knownSpells[key] = newItem

    return nil
end

function KnownSpell:GetAll()
    local playerSpecID = addon:GetPlayerSpecID()
    if not playerSpecID then
        return nil
    end

    local knownSpells = {}

    local numPetSpells, petNameToken = C_SpellBook.HasPetSpells()
    if numPetSpells and numPetSpells > 0 then
        for i = 1, numPetSpells do
            KnownSpell:Process(playerSpecID, Enum.SpellBookSpellBank.Pet, 0, i, knownSpells)
        end
    end

    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() + 1 do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

        if lineInfo then
            if lineInfo.name == "General" then
                for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                    KnownSpell:Process(playerSpecID, Enum.SpellBookSpellBank.Player, 0, j, knownSpells)
                end
            else
                if lineInfo.specID then
                    if lineInfo.specID == playerSpecID then
                        for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                            KnownSpell:Process(playerSpecID, Enum.SpellBookSpellBank.Player, playerSpecID, j, knownSpells)
                        end
                    end
                else
                    for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                        KnownSpell:Process(playerSpecID, Enum.SpellBookSpellBank.Player, playerSpecID, j, knownSpells)
                    end
                end
            end
        end
    end

    local forcedSpells = SettingsDB.forcedSpells[0]
    if forcedSpells and next(forcedSpells) ~= nil then
        for i = 1, #forcedSpells do
            KnownSpell:Add(-1, playerSpecID, -1, 0, forcedSpells[i], knownSpells)
        end
    end

    forcedSpells = SettingsDB.forcedSpells[playerSpecID]
    if forcedSpells and next(forcedSpells) ~= nil then
        for i = 1, #forcedSpells do
            KnownSpell:Add(-1, playerSpecID, -1, 0, forcedSpells[i], knownSpells)
        end
    end

    for i = 1, #SettingsDB.validItems do
        KnownSpell:Add(SettingsDB.validItems[i], playerSpecID, -1, 0, -1, knownSpells)
    end

    KnownSpell:Add(-1, playerSpecID, 13, 0, -1, knownSpells)
    KnownSpell:Add(-1, playerSpecID, 14, 0, -1, knownSpells)

    return knownSpells
end

function KnownSpell:Process(playerSpecID, spellBank, specID, spellIndex, knownSpells)
    local itemInfo = C_SpellBook.GetSpellBookItemInfo(spellIndex, spellBank)
    if not itemInfo then
        return nil
    end

    if itemInfo.itemType == Enum.SpellBookItemType.Spell or itemInfo.itemType == Enum.SpellBookItemType.PetAction then
        if itemInfo.isOffSpec then
            return nil
        end

        if itemInfo.isPassive then
            local baseChargeInfo = C_Spell.GetSpellCharges(itemInfo.spellID)
            if baseChargeInfo then
                return KnownSpell:Add(-1, playerSpecID, -1, specID, itemInfo.spellID, knownSpells)
            else
                local cooldownMS, gcdMS = GetSpellBaseCooldown(itemInfo.spellID)
                if cooldownMS and cooldownMS > 0 then
                    return KnownSpell:Add(-1, playerSpecID, -1, specID, itemInfo.spellID, knownSpells)
                end
            end

            return nil
        end

        return KnownSpell:Add(-1, playerSpecID, -1, specID, itemInfo.spellID, knownSpells)
    end

    if itemInfo.itemType == Enum.SpellBookItemType.Flyout then
        local flyoutName, flyoutDescription, flyoutSlots, flyoutKnown = GetFlyoutInfo(itemInfo.actionID)
        for slot = 1, flyoutSlots do
            local slotSpellID, slotOverrideSpellID, slotIsKnown, slotSpellName, slotSlotSpecID = GetFlyoutSlotInfo(itemInfo.actionID, slot)
            if slotIsKnown and not C_Spell.IsSpellPassive(slotSpellID) then
                KnownSpell:Add(-1, playerSpecID, -1, specID, slotSpellID, knownSpells)
            end
        end
    end

    return nil
end
