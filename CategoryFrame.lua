local addonName, addon = ...

CategoryFrame = {}
CategoryFrame.__index = KnownSlot

local categoryIgnored
local categoryTables = {}
local categoryUnknown
local cooldownManagerSpells = {}
local existingIcons = {}
local updateIconStateInterval = 0.25
local updateIconStateLast = 0

local LSM = LibStub("LibSharedMedia-3.0")
local font = LSM:Fetch("font", "Naowh") or "Fonts\\FRIZQT__.TTF"

-- Private

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

local function GetFrame(categoryName)
    if categoryName == addon.categoryIgnored then
        return nil
    end

    local newFrame = CreateFrame("Frame", "poesBars" .. categoryName .. "Parent", UIParent)
    if categoryName == addon.categoryUnknown then
        return newFrame
    end

    newFrame:EnableKeyboard(false)
    newFrame:EnableMouse(true)
    newFrame:EnableMouseWheel(false)
    newFrame:RegisterForDrag("LeftButton")
    newFrame:SetClampedToScreen(true)
    newFrame:SetDontSavePosition(true)
    newFrame:SetFrameStrata("LOW")
    newFrame:SetHitRectInsets(0, 0, 0, 0)
    newFrame:SetMovable(true)
    newFrame:SetPropagateKeyboardInput(true)
    newFrame:SetSize(1, 1)
    newFrame:SetToplevel(false)

    newFrame:SetScript("OnDragStart", function(frame)
        if IsControlKeyDown() then
            frame:StartMoving()
        end
    end)

    newFrame:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()

        C_Timer.After(1, function()
            SaveFramePosition(categoryName, frame)
        end)
    end)

    return newFrame
end

local function RefreshFrame(parentTable)
    if parentTable == nil then
        return
    end

    if parentTable.categoryName == "" then
        return
    end

    if parentTable.categoryName == addon.categoryIgnored then
        return
    end

    local settingsTable = SettingsDB[parentTable.categoryName] or {}

    local categoryOrder = CategoryOrderDB[parentTable.categoryName]
    local displayWhen = addon:NormalizeText(settingsTable.displayWhen)
    local frameIcons = {}
    local iconSize = addon:GetNumberOrDefault(64, settingsTable.iconSize)
    local iconSpacing = addon:GetNumberOrDefault(2, settingsTable.iconSpacing)
    local isClickable = settingsTable.isClickable or false
    local isVertical = settingsTable.isVertical or false
    local seenSettingNames = {}
    local validIcons = {}
    local validSettingNames = {}
    local wrapAfter = addon:GetNumberOrDefault(0, settingsTable.wrapAfter)

    if displayWhen == "" then
        displayWhen = "Always"
    end

    for _, icon in pairs(parentTable.icons) do
        validIcons[icon.settingName] = icon
        validSettingNames[icon.settingName] = true
    end

    if categoryOrder then
        for _, settingName in ipairs(categoryOrder) do
            if validSettingNames[settingName] and validIcons[settingName] then
                seenSettingNames[settingName] = true

                local icon = validIcons[settingName]
                if icon then
                    if icon.slotID and icon.slotID > 0 then
                        table.insert(frameIcons, icon)
                    elseif icon.itemID and icon.itemID > 0 then
                        local count = C_Item.GetItemCount(icon.itemID, false, true, false, false)
                        if count and count > 0 then
                            table.insert(frameIcons, icon)
                        end
                    elseif icon.spellID and icon.spellID > 0 then
                        table.insert(frameIcons, icon)
                    end
                end
            end
        end
    end

    for _, icon in pairs(parentTable.icons) do
        if not seenSettingNames[icon.settingName] then
            if icon.slotID and icon.slotID > 0 then
                table.insert(frameIcons, icon)
            elseif icon.itemID and icon.itemID > 0 then
                local count = C_Item.GetItemCount(icon.itemID, false, true, false, false)
                if count and count > 0 then
                    table.insert(frameIcons, icon)
                end
            elseif icon.spellID and icon.spellID > 0 then
                table.insert(frameIcons, icon)
            end
        end
    end

    if frameIcons and next(frameIcons) ~= nil then
        for i = 1, #frameIcons do
            local icon = frameIcons[i]

            if parentTable.categoryName == addon.categoryUnknown then
                icon.textID:Show()

                icon:EnableMouse(false)
                icon:SetFrameStrata("LOW")
                icon:SetToplevel(false)

                UnregisterAttributeDriver(icon, "state-visibility")
                icon:Show()
            else
                icon.textID:Hide()

                if SettingsDB.isLocked then
                    if isClickable then
                        icon:EnableMouse(true)
                        icon:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
                        icon:SetFrameStrata("HIGH")
                        icon:SetToplevel(true)
                    else
                        icon:EnableMouse(false)
                        icon:SetFrameStrata("LOW")
                        icon:SetToplevel(false)
                    end

                    if displayWhen == "Always" then
                        UnregisterAttributeDriver(icon, "state-visibility")
                        icon:Show()
                    elseif displayWhen == "In Combat" then
                        RegisterAttributeDriver(icon, "state-visibility", "[combat] show; hide")
                    elseif displayWhen == "Out Of Combat" then
                        RegisterAttributeDriver(icon, "state-visibility", "[nocombat] show; hide")
                    else
                        UnregisterAttributeDriver(icon, "state-visibility")
                        icon:Show()
                    end
                else
                    icon:EnableMouse(false)
                    icon:SetFrameStrata("LOW")
                    icon:SetToplevel(false)

                    UnregisterAttributeDriver(icon, "state-visibility")
                    icon:Show()
                end
            end

            icon:ClearAllPoints()
            icon:SetParent(parentTable.frame)
            icon:SetSize(iconSize, iconSize)

            if i == 1 then
                icon:SetPoint("TOPLEFT", parentTable.frame, "TOPLEFT", 0, 0)
            else
                local wrapIndex = (wrapAfter > 0) and ((i - 1) % wrapAfter == 0)
                if wrapIndex then
                    local previousWrap = frameIcons[i - wrapAfter]
                    if isVertical then
                        icon:SetPoint("TOPLEFT", previousWrap, "TOPRIGHT", iconSpacing, 0)
                    else
                        icon:SetPoint("TOPLEFT", previousWrap, "BOTTOMLEFT", 0, -iconSpacing)
                    end
                else
                    local previous = frameIcons[i - 1]
                    if isVertical then
                        icon:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -iconSpacing)
                    else
                        icon:SetPoint("TOPLEFT", previous, "TOPRIGHT", iconSpacing, 0)
                    end
                end
            end
        end

        local height, width
        local numIcons = #frameIcons

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

    LoadFramePosition(parentTable.categoryName, parentTable.frame)
end

function LoadFramePosition(categoryName, parentFrame)
    if categoryName == addon.categoryIgnored then
        return
    end

    if categoryName == addon.categoryUnknown then
        parentFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    else
        local settingsTable = SettingsDB[categoryName] or {}
        local anchor = settingsTable.anchor or "CENTER"
        local x = settingsTable.x or 0
        local y = settingsTable.y or 0

        parentFrame:ClearAllPoints()
        if anchor and anchor ~= "" then
            parentFrame:SetPoint(anchor, UIParent, "CENTER", x, y)
        else
            parentFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end
end

function SaveFramePosition(categoryName, parentFrame)
    if categoryName == addon.categoryIgnored then
        return nil
    end

    if categoryName == addon.categoryUnknown then
        return nil
    end

    local parentBottom = parentFrame:GetBottom()
    local parentCenterX, parentCenterY = parentFrame:GetCenter()
    local parentLeft = parentFrame:GetLeft()
    local parentRight = parentFrame:GetRight()
    local parentTop = parentFrame:GetTop()
    local screenCenterX, screenCenterY = UIParent:GetCenter()
    local settingTable = SettingsDB[categoryName] or {}

    if not settingTable.anchor or settingTable.anchor == "" then
        settingTable.anchor = "CENTER"
    end

    if settingTable.anchor == "TOPLEFT" then
        settingTable.x = parentLeft
        settingTable.y = parentTop
    elseif settingTable.anchor == "TOPRIGHT" then
        settingTable.x = parentRight
        settingTable.y = parentTop
    elseif settingTable.anchor == "TOP" then
        settingTable.x = parentCenterX
        settingTable.y = parentTop
    elseif settingTable.anchor == "BOTTOMLEFT" then
        settingTable.x = parentLeft
        settingTable.y = parentBottom
    elseif settingTable.anchor == "BOTTOMRIGHT" then
        settingTable.x = parentRight
        settingTable.y = parentBottom
    elseif settingTable.anchor == "BOTTOM" then
        settingTable.x = parentCenterX
        settingTable.y = parentBottom
    elseif settingTable.anchor == "LEFT" then
        settingTable.x = parentLeft
        settingTable.y = parentCenterY
    elseif settingTable.anchor == "RIGHT" then
        settingTable.x = parentRight
        settingTable.y = parentCenterY
    else
        settingTable.x = parentCenterX
        settingTable.y = parentCenterY
    end

    settingTable.x = settingTable.x - screenCenterX
    settingTable.y = settingTable.y - screenCenterY

    SettingsDB[categoryName] = settingTable
end

-- Shared

function CategoryFrame:CheckSpells()
    if InCombatLockdown() then
        addon:Debounce("CategoryFrame:CheckSpells", 1, function()
            CategoryFrame:CheckSpells()
        end)

        return
    end

    local fontSizeEssential = addon:GetNumberOrDefault(16, SettingsDB.bindingFontSize)
    local fontSizeUtility = fontSizeEssential - 4
    local knownSlots = KnownSlot:GetAll()
    local knownSpells = KnownSpell:GetAll()

    cooldownManagerSpells = {}

    categoryUnknown.icons = {}

    for _, icon in ipairs({ EssentialCooldownViewer:GetChildren() }) do
        CheckTextBinding(fontSizeEssential, icon, knownSlots)
    end

    for _, icon in ipairs({ UtilityCooldownViewer:GetChildren() }) do
        CheckTextBinding(fontSizeUtility, icon, knownSlots)
    end

    for _, icon in pairs(existingIcons) do
        icon:ClearAllPoints()
        icon:Hide()
        icon:SetParent(categoryIgnored.frame)
    end

    categoryUnknown.icons = {}
    for categoryName, parentTable in pairs(categoryTables) do
        parentTable.icons = {}
    end

    for iconKey, knownSpell in pairs(knownSpells) do
        local icon = existingIcons[iconKey]
        if icon == nil then
            icon = knownSpell:CreateIcon()
            if icon then
                existingIcons[iconKey] = icon
            end
        end

        if icon then
            icon:RefreshIcon()
            icon:RefreshKeyBind(knownSlots)

            icon:ClearAllPoints()
            icon:Hide()
            icon:SetParent(categoryIgnored.frame)

            if knownSpell.spellID > 0 and cooldownManagerSpells[knownSpell.spellID] and cooldownManagerSpells[knownSpell.spellID] == true then
                SpellsDB[knownSpell.specID][knownSpell.settingName] = addon.categoryIgnored
            else
                local categoryName = SpellsDB[knownSpell.specID][knownSpell.settingName]
                if not categoryName or categoryName == "" then
                    categoryName = addon.categoryUnknown
                end

                local parentTable = categoryTables[categoryName]
                if parentTable ~= nil then
                    parentTable.icons[iconKey] = icon
                end
            end
        end
    end

    CategoryFrame:Refresh()
end

function CategoryFrame:Create()
    if InCombatLockdown() then
        addon:Debounce("CategoryFrame:Create", 1, function()
            CategoryFrame:Create()
        end)

        return
    end

    SettingsDB.isLocked = true

    categoryIgnored = {}
    categoryIgnored.categoryName = addon.categoryUnknown
    categoryIgnored.frame = GetFrame(addon.categoryUnknown)
    categoryIgnored.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1, -1)
    categoryIgnored.frame:SetSize(1, 1)
    categoryIgnored.icons = {}

    categoryUnknown = {}
    categoryUnknown.categoryName = addon.categoryUnknown
    categoryUnknown.frame = GetFrame(addon.categoryUnknown)
    categoryUnknown.icons = {}

    for _, categoryName in pairs(addon:GetValidCategories()) do
        local parentTable = categoryTables[categoryName]
        if parentTable == nil then
            parentTable = {}
            parentTable.categoryName = categoryName
            parentTable.frame = GetFrame(categoryName)
            parentTable.icons = {}

            categoryTables[categoryName] = parentTable
        end
    end

    CategoryFrame:CheckSpells()

    addon.isLoaded = true
end

function CategoryFrame:Lock()
    if categoryUnknown == nil then
        return
    end

    if InCombatLockdown() then
        addon:Debounce("CategoryFrame:Lock", 1, function()
            CategoryFrame:Lock()
        end)

        return
    end

    SettingsDB.isLocked = true

    updateIconStateInterval = 0
    CategoryFrame:UpdateIconState()

    for categoryName, parentTable in pairs(categoryTables) do
        if parentTable.frame then
            parentTable.frame:EnableKeyboard(false)
            parentTable.frame:EnableMouse(false)
            parentTable.frame:EnableMouseWheel(false)
            parentTable.frame:RegisterForDrag()
            parentTable.frame:SetMovable(false)

            RefreshFrame(parentTable)
        end
    end
end

function CategoryFrame:Refresh()
    RefreshFrame(categoryUnknown)

    for categoryName, parentTable in pairs(categoryTables) do
        RefreshFrame(parentTable)
    end

    CategoryFrame:UpdateIconState()
end

function CategoryFrame:RefreshEquipmentSlot(equipmentSlot)
    local playerSpecID = addon:GetPlayerSpecID()
    if not playerSpecID then
        return
    end

    local iconKey = addon:NormalizeText("-1_" .. playerSpecID .. "_" .. equipmentSlot .. "_0_-1")
    local icon = existingIcons[iconKey]
    if icon then
        icon:RefreshIcon()
    end
end

function CategoryFrame:Unlock()
    if categoryUnknown == nil then
        return
    end

    if InCombatLockdown() then
        addon:Debounce("CategoryFrame:Unlock", 1, function()
            CategoryFrame:Unlock()
        end)

        return
    end

    SettingsDB.isLocked = false

    updateIconStateInterval = 0
    CategoryFrame:UpdateIconState()

    for categoryName, parentTable in pairs(categoryTables) do
        if parentTable.frame then
            parentTable.frame:EnableMouse(true)
            parentTable.frame:RegisterForDrag("LeftButton")
            parentTable.frame:SetMovable(true)
        else
            print("categoryName:", categoryName, ", frame:", parentTable.frame)
        end

        RefreshFrame(parentTable)
    end
end

function CategoryFrame:UpdateIconState()
    local currentTime = GetTime()
    if currentTime - updateIconStateLast < updateIconStateInterval then
        return
    end

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

    for categoryName, parentTable in pairs(categoryTables) do
        local settingsTable = addon:GetSettingsTable(categoryName)

        for _, icon in pairs(parentTable.icons) do
            icon:UpdateState(gcdCooldown, playerBuffs, playerTotems, settingsTable, targetDebuffs)
        end
    end

    updateIconStateLast = GetTime()
end
