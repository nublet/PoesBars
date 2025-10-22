local addonName, addon = ...

BagItems               = {}
BagItems.__index       = BagItems

local previousBagState = {}

-- Private

local function IsValidItem(itemID)
    for _, id in ipairs(SettingsDB.validItems) do
        if id == itemID then
            return true
        end
    end

    return false
end

-- Shared

function BagItems:Cache()
    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        previousBagState[bagID] = previousBagState[bagID] or {}

        for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
            local newItemID = -1

            local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
            if itemInfo then
                newItemID = addon:NormalizeNumber(itemInfo.itemID)
            end

            previousBagState[bagID][slotID] = newItemID
        end
    end
end

function BagItems:Check()
    local needsUpdate = false

    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
            local newItemID = -1
            local oldItemID = addon:NormalizeNumber(previousBagState[bagID][slotID])

            local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
            if itemInfo then
                newItemID = addon:NormalizeNumber(itemInfo.itemID)
            end

            previousBagState[bagID][slotID] = newItemID

            if newItemID ~= oldItemID then
                if newItemID > 0 and IsValidItem(newItemID) then
                    needsUpdate = true
                end

                if oldItemID > 0 and IsValidItem(oldItemID) then
                    needsUpdate = true
                end
            end
        end
    end

    if needsUpdate then
        addon:Debounce("CategoryFrame:CheckSpells", 1, function()
            CategoryFrame:CheckSpells()
        end)
    end
end
