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
    if itemID and itemID > 0 then
        if self.itemID == itemID then
            return true
        elseif string.find(self.macroBody, "/use item:" .. itemID) then
            return true
        elseif string.find(self.macroBody, "/cast item:" .. itemID) then
            return true
        end
    end

    if spellID and spellID > 0 then
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

function KnownSlot:GetAll()
    local knownSlots = {}

    for slot = 1, 180 do
        local actionType, actionID, actionSubType = GetActionInfo(slot)
        local actionText = GetActionText(slot)

        if actionType then
            local newItem

            if not actionSubType then
                actionSubType = ""
            end

            if actionType == "companion" then
                if actionSubType == "MOUNT" then
                    newItem = KnownSlot:Get(actionText, -1, "", "", actionID, slot)
                end
            elseif actionType == "item" then
                if actionSubType == "" then
                    newItem = KnownSlot:Get(actionText, actionID, "", "", -1, slot)
                end
            elseif actionType == "macro" then
                local macroName, macroIcon, macroBody = GetMacroInfo(actionText)

                if actionSubType == "" then
                    newItem = KnownSlot:Get(actionText, -1, macroBody, macroName, -1, slot)
                elseif actionSubType == "item" then
                    newItem = KnownSlot:Get(actionText, -1, macroBody, macroName, -1, slot)
                elseif actionSubType == "MOUNT" then
                    newItem = KnownSlot:Get(actionText, -1, macroBody, macroName, -1, slot)
                elseif actionSubType == "spell" then
                    newItem = KnownSlot:Get(actionText, -1, macroBody, macroName, actionID, slot)
                else
                    print("actionSubType:", actionSubType, ", actionID:", actionID, ", actionText:", actionText, ", macroName:", macroName, ", macroBody:", macroBody)
                end
            elseif actionType == "spell" then
                if actionSubType == "assistedcombat" then
                    newItem = KnownSlot:Get(actionText, -1, "", "", actionID, slot)
                elseif actionSubType == "pet" then
                    newItem = KnownSlot:Get(actionText, -1, "", "", actionID, slot)
                elseif actionSubType == "spell" then
                    newItem = KnownSlot:Get(actionText, -1, "", "", actionID, slot)
                end
            elseif actionType == "summonmount" then
                if actionSubType == "" then
                    local mountID = tonumber(actionID) or -1
                    if mountID > 0 then
                        local _, spellID = C_MountJournal.GetMountInfoByID(mountID)

                        newItem = KnownSlot:Get(actionText, -1, "", "", spellID, slot)
                    end
                end
            end

            if newItem then
                knownSlots[slot] = newItem
            else
                if actionType == "flyout" and actionSubType == "" then
                else
                    print("addon:GetKnownSlots. slot:", slot, ", actionType:", actionType, ", actionID:", actionID, ", actionSubType:", actionSubType, ", actionText:", actionText)
                end
            end
        end
    end

    return knownSlots
end

function KnownSlot:GetKeyBind(itemID, itemName, spellID, spellName, knownSlots)
    for slot, knownSlot in pairs(knownSlots) do
        if knownSlot:IsMatch(itemID, itemName, spellID, spellName) then
            return knownSlot.keyBind
        end
    end

    return ""
end
