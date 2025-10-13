local addonName, addon = ...

KnownSlot = {}
KnownSlot.__index = KnownSlot

-- Private

local function ReplaceBindings(binding)
    if not binding then
        return ""
    end
    if binding == "" then
        return ""
    end

    binding = binding:gsub("ALT%-", "A")
    binding = binding:gsub("%BUTTON", "M")
    binding = binding:gsub("%MOUSEWHEELDOWN", "WD")
    binding = binding:gsub("%MOUSEWHEELUP", "WU")
    binding = binding:gsub("CTRL%-", "C")
    binding = binding:gsub("NUMPAD", "N")
    binding = binding:gsub("SHIFT%-", "S")

    return binding
end

local function GetSlotKeyBind(slot)
    local actionButtonName = addon.actionButtons[slot]
    if actionButtonName and actionButtonName ~= "" then
        local binding = GetBindingKey(actionButtonName)
        if binding and binding ~= "" then
            return binding
        end
    end

    if _G["ElvUI"] and _G["ElvUI_Bar1Button1"] then
        local barIndex = math.floor((slot - 1) / 12) + 1
        local buttonIndex = ((slot - 1) % 12) + 1
        local button = _G["ElvUI_Bar" .. barIndex .. "Button" .. buttonIndex]
        if button then
            actionButtonName = button.bindstring or button.keyBoundTarget
            if not actionButtonName then
                actionButtonName = "CLICK " .. button:GetName() .. ":LeftButton"
            end

            local binding = GetBindingKey(actionButtonName)
            if binding and binding ~= "" then
                return binding
            end
        end
    end

    if _G["Bartender4"] then
        actionButtonName = "CLICK BT4Button" .. slot .. ":Keybind"
        local binding = GetBindingKey(actionButtonName)
        if binding and binding ~= "" then
            return binding
        end
    end

    return ""
end

function KnownSlot:IsMatch(itemID, itemName, spellID, spellName)
    if itemID > 0 then
        if self.itemID == itemID then
            return true
        elseif string.find(self.macroBody, "/use item:" .. itemID) then
            return true
        elseif string.find(self.macroBody, "/cast item:" .. itemID) then
            return true
        end
    end

    if spellID > 0 then
        if self.spellID == spellID then
            return true
        end
    end

    if itemName ~= "" then
        if self.itemName ~= "" then
            if self.itemName == itemName then
                return true
            end

            if string.find(self.itemName, itemName) then
                return true
            end
        end

        if self.actionText ~= "" then
            if string.find(self.actionText, itemName) then
                return true
            end
        end

        if self.macroBody ~= "" then
            if string.find(self.macroBody, itemName) then
                return true
            end
        end

        if self.macroName ~= "" then
            if string.find(self.macroName, itemName) then
                return true
            end
        end
    end

    if spellName ~= "" then
        if self.spellName ~= "" then
            if self.spellName == spellName then
                return true
            end

            if string.find(self.spellName, spellName) then
                return true
            end
        end

        if self.actionText ~= "" then
            if string.find(self.actionText, spellName) then
                return true
            end
        end

        if self.macroBody ~= "" then
            if string.find(self.macroBody, spellName) then
                return true
            end
        end

        if self.macroName ~= "" then
            if string.find(self.macroName, spellName) then
                return true
            end
        end
    end
end

-- Shared

function KnownSlot:Get(actionText, itemID, macroBody, macroName, spellID, slot)
    local newItem = setmetatable({}, KnownSlot)
    newItem.actionText = addon:NormalizeText(actionText)
    newItem.itemID = addon:NormalizeNumber(itemID)
    newItem.itemName = ""
    newItem.macroBody = addon:NormalizeText(macroBody)
    newItem.macroName = addon:NormalizeText(macroName)
    newItem.slot = addon:NormalizeNumber(slot)
    newItem.spellID = addon:NormalizeNumber(spellID)
    newItem.spellName = ""

    newItem.keyBind = ReplaceBindings(GetSlotKeyBind(newItem.slot))

    if newItem.spellID > 0 then
        local spellInfo = C_Spell.GetSpellInfo(newItem.spellID)
        if spellInfo then
            newItem.spellName = addon:NormalizeText(spellInfo.name)
        end
    end

    if newItem.itemID > 0 then
        local item = Item:CreateFromItemID(newItem.itemID)
        item:ContinueOnItemLoad(function()
            newItem.itemName = addon:NormalizeText(item:GetItemName())
        end)
    end

    return newItem
end

function KnownSlot:GetKeyBind(itemID, itemName, spellID, spellName)
    for slot, knownSlot in pairs(addon.knownSlots) do
        if knownSlot:IsMatch(itemID, itemName, spellID, spellName) then
            return knownSlot.keyBind
        end
    end

    return ""
end
