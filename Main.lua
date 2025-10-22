local addonName, addon = ...

local lastActiveConfigID
local lastImportString
local lastSpecialization

local LSM = LibStub("LibSharedMedia-3.0")
LSM:Register("font", "Naowh", [[Interface\AddOns\PoesBars\FONTS\Naowh.ttf]])

function PoesBarsCommands(msg, editbox)
	msg = addon:NormalizeText(msg)

	if msg == "lock" or msg == "l" then
		CategoryFrame:Lock()
	elseif msg == "refresh" or msg == "r" then
		addon.isLoaded = false
		addon.isSettingsShown = false

		CategoryFrame:Create()
	elseif msg == "unlock" or msg == "u" then
		CategoryFrame:Unlock()
	else
		addon.isSettingsShown = true

		addon:ToggleSettingsDialog()
	end
end

local function OnEvent(self, event, ...)
	if event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" then
		if addon.isLoaded == false then
			return
		end
		if addon.suppressTalentEvents == false then
			return
		end

		addon.suppressTalentEvents = true

		addon:Debounce("Main:TalentsChanged", 3, function()
			local newActiveConfigID = C_ClassTalents.GetActiveConfigID()
			local newImportString
			local newSpecialization = GetSpecialization()
			local wasChanged

			if newActiveConfigID then
				newImportString = C_Traits.GenerateImportString(newActiveConfigID)
			else
				newImportString = ""
			end

			if lastActiveConfigID ~= newActiveConfigID then
				wasChanged = true
			elseif lastImportString ~= newImportString then
				wasChanged = true
			elseif lastSpecialization ~= newSpecialization then
				wasChanged = true
			end

			lastActiveConfigID = newActiveConfigID
			lastImportString = newImportString
			lastSpecialization = newSpecialization

			if wasChanged then
				addon:Debounce("CategoryFrame:CheckSpells", 1, function()
					CategoryFrame:CheckSpells()
				end)
			end

			addon:Debounce("Main:suppressTalentEvents", 3, function()
				addon.suppressTalentEvents = false
			end)
		end)
	elseif event == "BAG_UPDATE_DELAYED" then
		if addon.isLoaded == false then
			return
		end

		BagItems:Check()
	elseif event == "EDIT_MODE_LAYOUTS_UPDATED" then
		if addon.isLoaded == false then
			return
		end

		addon:Debounce("CategoryFrame:CheckSpells", 1, function()
			CategoryFrame:CheckSpells()
		end)
	elseif event == "PLAYER_ENTERING_WORLD" then
		addon.suppressTalentEvents = true

		addon:Debounce("Main:suppressTalentEvents", 3, function()
			addon.suppressTalentEvents = false
		end)
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		if addon.isLoaded == false then
			return
		end

		local equipmentSlot = ...

		addon:Debounce("CategoryFrame:RefreshEquipmentSlot" .. equipmentSlot, 3, function()
			CategoryFrame:RefreshEquipmentSlot(equipmentSlot)
		end)
	elseif event == "VARIABLES_LOADED" then
		addon.isLoaded = false

		CategoryOrderDB = CategoryOrderDB or {}
		SettingsDB = SettingsDB or {}
		SpellsDB = SpellsDB or {}

		if type(SettingsDB.forcedSpells) ~= "table" then
			SettingsDB.forcedSpells = {}
			SettingsDB.forcedSpells[0] = {}
		end

		if type(SettingsDB.validCategories) ~= "table" then
			SettingsDB.validCategories = { "Trinket" }
		end

		if type(SettingsDB.validItems) ~= "table" then
			SettingsDB.validItems = { 211878, 211879, 211880, 5512, 224464, 212263, 212264, 212265 }
		end

		addon:Debounce("CategoryFrame:Create", 1, function()
			CategoryFrame:Create()
		end)

		addon:Debounce("BagItems:Cache", 1, function()
			BagItems:Cache()
		end)

		addon:Debounce("addon:InitializeSettingsDialog", 3, function()
			addon:InitializeSettingsDialog()
		end)

		if EditModeManagerFrame then
			hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
				addon:Debounce("CategoryFrame:CheckSpells", 1, function()
					CategoryFrame:CheckSpells()
				end)
			end)
		end

		if GameTooltip then
			hooksecurefunc(GameTooltip, "SetUnitAura", function(control, unit, index, filter)
				local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
				if aura then
					addon:AddTooltipID(aura.spellId, "Spell ID", control)
				end
			end)
		end

		if TooltipDataProcessor then
			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
				if data and data.id then
					addon:AddTooltipID(data.id, "Item ID", tooltip)
				end
			end)

			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
				if data and data.id then
					addon:AddTooltipID(data.id, "Spell ID", tooltip)
				end
			end)

			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Quest, function(tooltip, data)
				if data and data.id then
					addon:AddTooltipID(data.id, "Quest ID", tooltip)
				end
			end)
		end
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1, -1)
eventFrame:SetSize(1, 1)

eventFrame:SetScript("OnEvent", OnEvent)

eventFrame:SetScript("OnUpdate", function()
	CategoryFrame:UpdateIconState()
end)

SLASH_PBC1 = "/pbc"

SlashCmdList["PBC"] = PoesBarsCommands
