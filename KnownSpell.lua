local addonName, addon = ...

KnownSpell = {}
KnownSpell.__index = KnownSpell

-- Private



-- Shared

function KnownSpell:Add(isTrinket, itemID, playerSpecID, specID, spellID, knownSpells)
    local newItem = {}
    newItem.iconID = -1
    newItem.isHarmful = false
    newItem.isTrinket = isTrinket or false
    newItem.isUsable = false
    newItem.itemID = addon:NormalizeNumber(itemID)
    newItem.itemName = ""
    newItem.itemRank = ""
    newItem.playerSpecID = addon:NormalizeNumber(playerSpecID)
    newItem.settingName = "-1_-1"
    newItem.specID = addon:NormalizeNumber(specID)
    newItem.spellID = addon:NormalizeNumber(spellID)
    newItem.spellName = ""

    if newItem.itemID <= 0 and newItem.spellID <= 0 then
        return nil
    end

    local key = addon:NormalizeText(newItem.itemID .. "_" .. newItem.playerSpecID .. "_" .. newItem.specID .. "_" .. newItem.spellID)
    if knownSpells[key] then
        return nil
    end

    if not SpellsDB[newItem.specID] then
        SpellsDB[newItem.specID] = {}
    end

    if newItem.spellID > 0 then
        newItem.settingName = "-1_" .. newItem.spellID

        if C_Spell.IsSpellHarmful(newItem.spellID) then
            newItem.isHarmful = true
        else
            newItem.isHarmful = false
        end

        local spellInfo = C_Spell.GetSpellInfo(newItem.spellID)
        if spellInfo then
            newItem.iconID = spellInfo.iconID
            newItem.spellName = addon:NormalizeText(spellInfo.name)
        else
            local newSpellID = C_Spell.GetOverrideSpell(newItem.spellID) or newItem.spellID
            if newSpellID and newSpellID ~= newItem.spellID then
                local newSpellInfo = C_Spell.GetSpellInfo(newSpellID)
                if newSpellInfo then
                    newItem.iconID = newSpellInfo.iconID
                    newItem.spellName = addon:NormalizeText(newSpellInfo.name)
                end
            end
        end
    end

    if newItem.itemID > 0 then
        local item = Item:CreateFromItemID(newItem.itemID)
        local usable, noMana = C_Item.IsUsableItem(newItem.itemID)

        newItem.iconID = item:GetItemIcon()
        newItem.isUsable = usable
        newItem.itemName = addon:NormalizeText(item:GetItemName())
        newItem.settingName = newItem.itemID .. "_-1"

        if newItem.spellID <= 0 then
            local _, itemSpellID = C_Item.GetItemSpell(newItem.itemID)
            if itemSpellID and itemSpellID > 0 then
                newItem.spellID = itemSpellID
            else
                itemSpellID = C_Item.GetFirstTriggeredSpellForItem(newItem.itemID, 4)
                if itemSpellID and itemSpellID > 0 then
                    newItem.spellID = itemSpellID
                else
                    itemSpellID = C_Item.GetFirstTriggeredSpellForItem(newItem.itemID, 3)
                    if itemSpellID and itemSpellID > 0 then
                        newItem.spellID = itemSpellID
                    else
                        itemSpellID = C_Item.GetFirstTriggeredSpellForItem(newItem.itemID, 2)
                        if itemSpellID and itemSpellID > 0 then
                            newItem.spellID = itemSpellID
                        end
                    end
                end
            end

            newItem.spellID = addon:NormalizeNumber(newItem.spellID)

            if newItem.spellID > 0 then
                local spellInfo = C_Spell.GetSpellInfo(newItem.spellID)
                if spellInfo then
                    newItem.spellName = addon:NormalizeText(spellInfo.name)
                end
            end
        end

        item:ContinueOnItemLoad(function()
            newItem.iconID = item:GetItemIcon()
            newItem.itemName = addon:NormalizeText(item:GetItemName())

            local itemLink = item:GetItemLink()
            if itemLink then
                local qualityTier = itemLink:match("|A:Professions%-ChatIcon%-Quality%-Tier(%d+)")

                if qualityTier then
                    if qualityTier == "1" then
                        newItem.itemRank = "R1"
                    elseif qualityTier == "2" then
                        newItem.itemRank = "R2"
                    elseif qualityTier == "3" then
                        newItem.itemRank = "R3"
                    end
                end
            end
        end)
    end

    knownSpells[key] = newItem

    return nil
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
                return KnownSpell:Add(false, -1, playerSpecID, specID, itemInfo.spellID, knownSpells)
            else
                local cooldownMS, gcdMS = GetSpellBaseCooldown(itemInfo.spellID)
                if cooldownMS and cooldownMS > 0 then
                    return KnownSpell:Add(false, -1, playerSpecID, specID, itemInfo.spellID, knownSpells)
                end
            end

            return nil
        end

        return KnownSpell:Add(false, -1, playerSpecID, specID, itemInfo.spellID, knownSpells)
    end

    if itemInfo.itemType == Enum.SpellBookItemType.Flyout then
        local flyoutName, flyoutDescription, flyoutSlots, flyoutKnown = GetFlyoutInfo(itemInfo.actionID)
        for slot = 1, flyoutSlots do
            local slotSpellID, slotOverrideSpellID, slotIsKnown, slotSpellName, slotSlotSpecID = GetFlyoutSlotInfo(itemInfo.actionID, slot)
            if slotIsKnown and not C_Spell.IsSpellPassive(slotSpellID) then
                KnownSpell:Add(false, -1, playerSpecID, specID, slotSpellID, knownSpells)
            end
        end
    end

    return nil
end
