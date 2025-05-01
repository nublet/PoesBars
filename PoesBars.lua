local addOnLoaded      = false
local addonName, addon = ...

local LSM              = LibStub("LibSharedMedia-3.0")
LSM:Register(LSM.MediaType.FONT, "Naowh", [[Interface\AddOns\PoesBars\FONTS\Naowh.ttf]],
	LSM.LOCALE_BIT_ruRU + LSM.LOCALE_BIT_western)

function PoesBarsCommands(msg, editbox)
	msg = msg:lower():trim()

	if msg == "" then
		addon:CreateIcons()
	elseif msg == "config" then
		C_Timer.After(1, function()
			Settings.OpenToCategory(addon.mainCategory)
		end)
	else
		print("Unknown Command: ", msg)
	end
end

SLASH_PBC1 = "/pbc"

SlashCmdList["PBC"] = PoesBarsCommands

local function OnEvent(self, event, ...)
	if event == "BAG_UPDATE_DELAYED" then
		if addOnLoaded and not InCombatLockdown() then
			addon:Debounce("CreateIcons", 1, function()
				addon:CreateIcons()
			end)
		end
	elseif event == "PLAYER_TALENT_UPDATE" then
		if addOnLoaded then
			addon:Debounce("CreateIcons", 1, function()
				addon:CreateIcons()
			end)
		end
	elseif event == "VARIABLES_LOADED" then
		SettingsDB = SettingsDB or {}
		SpellsDB = SpellsDB or {}

		if type(SettingsDB.validCategories) ~= "table" then
			SettingsDB.validCategories = { "Cooldowns", "Crowd Control", "Defensive", "Important", "Movement",
				"Racial", "Rotation", "Utility" }
		end
		if type(SettingsDB.validItems) ~= "table" then
			SettingsDB.validItems = { 211878, 211879, 211880, 5512, 224464, 212263, 212264, 212265 }
		end

		addon:Debounce("CreateSettings", 5, function()
			addon:CreateSettings()
		end)

		addon:Debounce("CreateIcons", 5, function()
			addon:CreateIcons()
		end)

		addOnLoaded = true
	end
end

local f = CreateFrame("Frame")
--f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("PLAYER_TALENT_UPDATE")
f:RegisterEvent("VARIABLES_LOADED")
f:SetScript("OnEvent", OnEvent)

f:SetSize(1, 1)
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
f:Hide()
