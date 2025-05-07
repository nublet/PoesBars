local addonName, addon    = ...
local timeSinceLastUpdate = 0
local updateInterval      = 0.25

local LSM                 = LibStub("LibSharedMedia-3.0")
LSM:Register(LSM.MediaType.FONT, "Naowh", [[Interface\AddOns\PoesBars\FONTS\Naowh.ttf]],
	LSM.LOCALE_BIT_ruRU + LSM.LOCALE_BIT_western)

function PoesBarsCommands(msg, editbox)
	msg = msg:lower():trim()

	if msg == "" or msg == "config" or msg == "c" then
		Settings.OpenToCategory(addon.categoryPoesBarsID)
		Settings.OpenToCategory(addon.categoryPoesBarsID)
		Settings.OpenToCategory(addon.categoryPoesBarsID)
	elseif msg == "buffs" or msg == "b" then
		Settings.OpenToCategory(addon.categoryBuffsID)
		Settings.OpenToCategory(addon.categoryBuffsID)
		Settings.OpenToCategory(addon.categoryBuffsID)
	elseif msg == "forced" or msg == "f" then
		Settings.OpenToCategory(addon.categoryForcedID)
		Settings.OpenToCategory(addon.categoryForcedID)
		Settings.OpenToCategory(addon.categoryForcedID)
	elseif msg == "items" or msg == "i" then
		Settings.OpenToCategory(addon.categoryItemsID)
		Settings.OpenToCategory(addon.categoryItemsID)
		Settings.OpenToCategory(addon.categoryItemsID)
	elseif msg == "lock" or msg == "l" then
		SettingsDB.isLocked = true

		addon:CheckLockState()
	elseif msg == "spells" or msg == "s" then
		Settings.OpenToCategory(addon.categorySpellsID)
		Settings.OpenToCategory(addon.categorySpellsID)
		Settings.OpenToCategory(addon.categorySpellsID)
	elseif msg == "unlock" or msg == "u" then
		SettingsDB.isLocked = false

		addon:CheckLockState()
	else
		print("Unknown Command: ", msg)
	end
end

SLASH_PBC1 = "/pbc"

SlashCmdList["PBC"] = PoesBarsCommands

local function OnEvent(self, event, ...)
	if event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" then
		if addon.isLoaded then
			addon.isLoaded = false

			addon:Debounce("CreateIcons", 1, function()
				addon:CreateIcons()
				addon.isLoaded = true
			end)
		end
	elseif event == "BAG_UPDATE_DELAYED" then
		if addon.isLoaded and not InCombatLockdown() then
			addon:Debounce("RefreshCategoryFrames", 1, function()
				addon:RefreshCategoryFrames()
			end)
		end
	elseif event == "VARIABLES_LOADED" then
		addon.isLoaded = false

		CategoryOrderDB = CategoryOrderDB or {}
		SettingsDB = SettingsDB or {}
		SpellsDB = SpellsDB or {}

		if type(SettingsDB.buffOverrides) ~= "table" then
			SettingsDB.buffOverrides = {}
			SettingsDB.buffOverrides[342245] = 342246 -- Alter Time
			SettingsDB.buffOverrides[414660] = 11426 -- Mass Barrier
			SettingsDB.buffOverrides[53600] = 132403 -- Shield of the Righteous
		end
		if type(SettingsDB.forcedSpells) ~= "table" then
			SettingsDB.forcedSpells = {}
			SettingsDB.forcedSpells[0] = {}
		end
		if type(SettingsDB.validCategories) ~= "table" then
			SettingsDB.validCategories = { "Cooldowns", "Crowd Control", "Defensive", "Important", "Movement", "Racial",
				"Rotation", "Utility" }
		end
		if type(SettingsDB.validItems) ~= "table" then
			SettingsDB.validItems = { 211878, 211879, 211880, 5512, 224464, 212263, 212264, 212265 }
		end

		addon:Debounce("CreateIcons", 1, function()
			addon:CreateIcons()
			addon.isLoaded = true
		end)

		addon:Debounce("CreateSettings", 3, function()
			local categoryPoesBars = addon:CreateSettingsGeneral()
			addon.categoryPoesBarsID = categoryPoesBars:GetID()

			addon.categoryBuffsID = addon:CreateSettingsBuffs(categoryPoesBars);
			addon.categoryForcedID = addon:CreateSettingsForced(categoryPoesBars)
			addon.categoryItemsID = addon:CreateSettingsItems(categoryPoesBars);
			addon.categorySpellsID = addon:CreateSettingsSpells(categoryPoesBars);
		end)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:RegisterEvent("PLAYER_TALENT_UPDATE")
f:RegisterEvent("TRAIT_CONFIG_UPDATED")
f:RegisterEvent("VARIABLES_LOADED")
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1, -1)
f:SetScript("OnEvent", OnEvent)
f:SetScript("OnUpdate", function(frame, elapsed)
	timeSinceLastUpdate = timeSinceLastUpdate + elapsed
	if timeSinceLastUpdate < updateInterval then
		return
	end

	addon:UpdateIconState()

	timeSinceLastUpdate = 0
end)
f:SetSize(1, 1)
