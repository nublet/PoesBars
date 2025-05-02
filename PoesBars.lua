local addonName, addon    = ...
local timeSinceLastUpdate = 0
local updateInterval      = 0.25

local LSM                 = LibStub("LibSharedMedia-3.0")
LSM:Register(LSM.MediaType.FONT, "Naowh", [[Interface\AddOns\PoesBars\FONTS\Naowh.ttf]],
	LSM.LOCALE_BIT_ruRU + LSM.LOCALE_BIT_western)

function PoesBarsCommands(msg, editbox)
	msg = msg:lower():trim()

	if msg == "" then
		addon:Debounce("CreateCategoryFrames", 5, function()
			addon.isLoaded = false
			addon:CreateCategoryFrames()
			addon.isLoaded = true
		end)
	elseif msg == "config" or msg == "c" then
		C_Timer.After(1, function()
			Settings.OpenToCategory(addon.categoryPoesBarsID)
			Settings.OpenToCategory(addon.categoryPoesBarsID)
			Settings.OpenToCategory(addon.categoryPoesBarsID)
		end)
	elseif msg == "items" or msg == "i" then
		C_Timer.After(1, function()
			Settings.OpenToCategory(addon.categoryItemsID)
			Settings.OpenToCategory(addon.categoryItemsID)
			Settings.OpenToCategory(addon.categoryItemsID)
		end)
	else
		print("Unknown Command: ", msg)
	end
end

SLASH_PBC1 = "/pbc"

SlashCmdList["PBC"] = PoesBarsCommands

local function OnEvent(self, event, ...)
	if event == "BAG_UPDATE_DELAYED" then
		if addon.isLoaded and not InCombatLockdown() then
			addon:Debounce("RefreshItems", 1, function()
				addon:RefreshItems()
			end)
		end
	elseif event == "PLAYER_TALENT_UPDATE" then
		if addon.isLoaded then
			addon.isLoaded = false

			addon:Debounce("RefreshSpells", 1, function()
				addon:RefreshSpells()
				addon.isLoaded = true
			end)
		end
	elseif event == "VARIABLES_LOADED" then
		addon.isLoaded = false

		SettingsDB = SettingsDB or {}
		SpellsDB = SpellsDB or {}

		if type(SettingsDB.validCategories) ~= "table" then
			SettingsDB.validCategories = { "Cooldowns", "Crowd Control", "Defensive", "Important", "Movement", "Racial", "Rotation", "Utility" }
		end
		if type(SettingsDB.validItems) ~= "table" then
			SettingsDB.validItems = { 211878, 211879, 211880, 5512, 224464, 212263, 212264, 212265 }
		end

		addon:Debounce("CreateCategoryFrames", 3, function()
			addon:CreateCategoryFrames()
			addon.isLoaded = true
		end)

		addon:Debounce("CreateSettings", 3, function()
			local framePoesBars = CreateFrame("Frame", addonName .. "SettingsFrame", UIParent)
			framePoesBars.name = addonName
			addon:AddSettingsPoesBars(framePoesBars)

			local frameItems = CreateFrame("Frame", "ItemsSettingsFrame", UIParent)
			frameItems.name = "Items"
			addon:AddSettingsItems(frameItems)

			local categoryPoesBars = Settings.RegisterCanvasLayoutCategory(framePoesBars, framePoesBars.name)
			Settings.RegisterAddOnCategory(categoryPoesBars)
			addon.categoryPoesBarsID = categoryPoesBars:GetID()

			local categoryItems = Settings.RegisterCanvasLayoutSubcategory(categoryPoesBars, frameItems, frameItems.name);
			Settings.RegisterAddOnCategory(categoryItems);
			addon.categoryItemsID = categoryItems:GetID();
		end)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("PLAYER_TALENT_UPDATE")
f:RegisterEvent("VARIABLES_LOADED")
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1, -1)
f:SetScript("OnEvent", OnEvent)
f:SetScript("OnUpdate", function(frame, elapsed)
	timeSinceLastUpdate = timeSinceLastUpdate + elapsed
	if timeSinceLastUpdate < updateInterval then
		return
	end

	addon:UpdateAllIcons()

	timeSinceLastUpdate = 0
end)
f:SetSize(1, 1)
