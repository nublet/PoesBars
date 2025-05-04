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
    newFrame:EnableKeyboard(false)
    newFrame:EnableMouse(false)
    newFrame:EnableMouseWheel(false)
    newFrame:Hide()
    newFrame:SetFrameStrata("LOW")
    newFrame:SetHitRectInsets(0, 0, 0, 0)
    newFrame:SetPoint("CENTER", 0, 0)
    newFrame:SetPropagateKeyboardInput(true)
    newFrame:SetSize(40, 40)
    newFrame:SetToplevel(false)

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

    if itemID > 0 then
        newFrame.iconName = ""
        newFrame.isHarmful = false
        textID:SetText(itemID)

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
        textID:SetText(spellID)
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

    if spellID == 119910 then
        print("spellID:", spellID, ", newFrame.iconName", newFrame.iconName, ", newFrame.spellCooldown",
            newFrame.spellCooldown)
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

local function GetDebuffAura(spellID, spellName, targetDebuffs)
    for i = 1, #targetDebuffs do
        local aura = targetDebuffs[i]
        if aura.spellId == spellID or aura.name == spellName then
            return aura
        end
    end

    return nil
end

local function ProcessSpell(spellBank, specID, spellIndex)
    local itemInfo = C_SpellBook.GetSpellBookItemInfo(spellIndex, spellBank)
    if not itemInfo then
        return
    end

    if itemInfo.isPassive then
        return
    end

    if itemInfo.isOffSpec then
        return
    end

    if itemInfo.itemType == Enum.SpellBookItemType.Spell or itemInfo.itemType == Enum.SpellBookItemType.PetAction then
    else
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
            for i = 1, #parentTable.spells do
                local iconFrame = parentTable.spells[i]

                iconFrame:ClearAllPoints()
                iconFrame:SetParent(parentTable.frame)

                iconFrame:Hide()
            end
        end

        if parentTable.items and next(parentTable.items) ~= nil then
            for i = 1, #parentTable.items do
                local iconFrame = parentTable.items[i]

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

            for i = 1, #parentTable.spells do
                table.insert(allIcons, parentTable.spells[i])
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

            for i = 1, #parentTable.items do
                table.insert(allIcons, parentTable.items[i])
            end
        end

        if allIcons and next(allIcons) ~= nil then
            for i = 1, #allIcons do
                local iconFrame = allIcons[i]

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
    for i = 1, #SettingsDB.validItems do
        CreateIconFrame(SettingsDB.validItems[i], 0, -1)
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

    local numPetSpells, petNameToken = C_SpellBook.HasPetSpells()

    if numPetSpells and numPetSpells > 0 then
        for i = 1, numPetSpells do
            ProcessSpell(Enum.SpellBookSpellBank.Pet, 0, i)
        end
    end

    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() + 1 do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

        if lineInfo then
            if lineInfo.name == "General" then
                for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                    ProcessSpell(Enum.SpellBookSpellBank.Player, 0, j)
                end
            else
                if lineInfo.specID then
                    if lineInfo.specID == playerSpecID then
                        for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                            ProcessSpell(Enum.SpellBookSpellBank.Player, playerSpecID, j)
                        end
                    end
                else
                    for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                        ProcessSpell(Enum.SpellBookSpellBank.Player, playerSpecID, j)
                    end
                end
            end
        end
    end
end

local function updateIconBuff(frame, spellID)
    frame.textureIcon:SetDesaturated(false)
    frame.textureIcon:SetVertexColor(1, 1, 1)

    if spellID <= 0 then
        return
    end

    local aura = C_UnitAuras.GetPlayerAuraBySpellID(SettingsDB.buffOverrides[spellID] or spellID)

    if aura and aura.isFromPlayerOrPlayerPet then
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

    local aura = GetDebuffAura(spellID, frame.iconName, targetDebuffs)

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
                frame:Hide()
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
                        frame:Show()
                    end

                    if not frame.glowActive then
                        ActionButton_ShowOverlayGlow(frame)
                        frame.glowActive = true
                    end
                elseif frame.glowActive then
                    ActionButton_HideOverlayGlow(frame)
                    frame.glowActive = false

                    if showOnCooldown then
                        frame:Hide()
                    end
                else
                    if showOnCooldown then
                        frame:Hide()
                    end
                end

                frame.auraActive = true
                frame.frameBorder:Hide()
                frame.textureIcon:SetDesaturated(false)
            else
                if showOnCooldown then
                    frame:Show()
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
            frame:Show()
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

    updateIconBuff(frame, spellID)

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

local function updateIconSpell(frame, gcdCooldown, name, targetDebuffs)
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
            updateIconBuff(frame, currentSpellID)

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
                updateIconBuff(frame, frameSpellID)

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
end

function addon:CreateCategoryFrames()
    local validCategories = addon:GetValidCategories(true)

    for i = 1, #validCategories do
        local name = validCategories[i]

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

    addon:CheckLockState()
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

    for i = 1, #validCategories do
        local name = validCategories[i]

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

    for i = 1, #validCategories do
        local name = validCategories[i]

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
    local targetDebuffs = {}
    local gcdCooldown = C_Spell.GetSpellCooldown(61304)
    local validCategories = addon:GetValidCategories(true)

    local auraIndex = 1
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

    for index = 1, #validCategories do
        local name = validCategories[index]

        if categories[name] then
            local parentTable = categories[name]

            if parentTable.items then
                for i = 1, #parentTable.items do
                    updateIconItem(parentTable.items[i], name)
                end
            end

            if parentTable.spells then
                for i = 1, #parentTable.spells do
                    updateIconSpell(parentTable.spells[i], gcdCooldown, name, targetDebuffs)
                end
            end
        end
    end
end
