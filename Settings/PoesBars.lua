local addonName, addon = ...

local frameSample
local parentFrame

local LSM = LibStub("LibSharedMedia-3.0")

local function CreateTestIcon()
	if frameSample then
		frameSample:ClearAllPoints()
		frameSample:Hide()
		frameSample:SetParent(nil)

		frameSample = nil
	end

	local font = LSM:Fetch("font", SettingsDB.fontName) or "Fonts\\FRIZQT__.TTF"
	local itemID = 211880

	frameSample = CreateFrame("Frame", nil, parentFrame)
	frameSample:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -10, -10)
	frameSample:SetSize(64, 64)

	local frameBorder = CreateFrame("Frame", nil, frameSample, "BackdropTemplate")
	frameBorder:EnableKeyboard(false)
	frameBorder:EnableMouse(false)
	frameBorder:EnableMouseWheel(false)
	frameBorder:SetAllPoints(frameSample)
	frameBorder:SetBackdrop({ edgeFile = "Interface/Buttons/WHITE8x8", edgeSize = 1, })
	frameBorder:SetBackdropBorderColor(1, 0, 0, 1)
	frameBorder:SetFrameLevel(frameSample:GetFrameLevel() + 1)
	frameBorder:SetPropagateKeyboardInput(true)
	frameBorder:SetToplevel(false)

	local frameCooldown = CreateFrame("Cooldown", nil, frameSample, "CooldownFrameTemplate")
	frameCooldown:EnableKeyboard(false)
	frameCooldown:EnableMouse(false)
	frameCooldown:EnableMouseWheel(false)
	frameCooldown:SetAllPoints(frameSample)
	frameCooldown:SetPropagateKeyboardInput(true)
	frameCooldown:SetToplevel(false)

	local textBinding = frameSample:CreateFontString(nil, "OVERLAY")
	textBinding:SetFont(font, SettingsDB.bindingFontSize or 12, SettingsDB.bindingFontFlags or "OUTLINE")
	textBinding:SetPoint("TOPRIGHT", frameSample, "TOPRIGHT", 0, 0)
	textBinding:SetText("")
	textBinding:SetTextColor(1, 1, 1, 1)
	if SettingsDB.bindingFontShadow then
		textBinding:SetShadowColor(0, 0, 0, 0.5)
		textBinding:SetShadowOffset(1, -1)
	end

	local textCharges = frameSample:CreateFontString(nil, "OVERLAY")
	textCharges:SetFont(font, SettingsDB.chargesFontSize or 12, SettingsDB.chargesFontFlags or "OUTLINE")
	textCharges:SetTextColor(1, 1, 1, 1)
	textCharges:SetPoint("BOTTOMRIGHT", frameSample, "BOTTOMRIGHT", 0, 0)
	textCharges:SetText("42")
	if SettingsDB.chargesFontShadow then
		textCharges:SetShadowColor(0, 0, 0, 0.5)
		textCharges:SetShadowOffset(1, -1)
	end

	local textCooldown = frameSample:CreateFontString(nil, "OVERLAY")
	textCooldown:SetFont(font, SettingsDB.cooldownFontSize or 16, SettingsDB.cooldownFontFlags or "OUTLINE")
	textCooldown:SetPoint("CENTER", frameSample, "CENTER", 0, 0)
	textCooldown:SetText("42")
	textCooldown:SetTextColor(1, 0, 0, 1)
	if SettingsDB.cooldownFontShadow then
		textCooldown:SetShadowColor(0, 0, 0, 0.5)
		textCooldown:SetShadowOffset(1, -1)
	end

	local textRank = frameSample:CreateFontString(nil, "OVERLAY")
	textRank:SetFont(font, SettingsDB.rankFontSize or 12, SettingsDB.rankFontFlags or "OUTLINE")
	textRank:SetPoint("BOTTOMLEFT", frameSample, "BOTTOMLEFT", 0, 0)
	textRank:SetText("")
	textRank:SetTextColor(0, 1, 0, 1)
	if SettingsDB.rankFontShadow then
		textRank:SetShadowColor(0, 0, 0, 0.5)
		textRank:SetShadowOffset(1, -1)
	end

	local textureIcon = frameSample:CreateTexture(nil, "ARTWORK")
	textureIcon:SetAllPoints(frameSample)

	local item = Item:CreateFromItemID(itemID)
	item:ContinueOnItemLoad(function()
		local itemName = item:GetItemName()
		local itemLink = item:GetItemLink()
		local itemTexture = item:GetItemIcon()

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

		textBinding:SetText("S4")
	end)
end

function addon:CreateSettingsGeneral()
	parentFrame = CreateFrame("Frame", addonName .. "SettingsFrame", UIParent)
	parentFrame.name = addonName

	SettingsDB.bindingFontSize = SettingsDB.bindingFontSize or 12

	local showGlobalSweep = addon:GetControlCheckbox(false, "Show GCD Sweep", parentFrame, function(control)
		SettingsDB.showGlobalSweep = control:GetChecked()
	end)
	showGlobalSweep:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -10)
	if SettingsDB.showGlobalSweep then
		showGlobalSweep:SetChecked(true)
	else
		showGlobalSweep:SetChecked(false)
	end

	local isLocked = addon:GetControlCheckbox(false, "Lock Groups", parentFrame, function(control)
		SettingsDB.isLocked = control:GetChecked()

		addon:CheckLockState()
	end)
	isLocked:SetPoint("TOPLEFT", showGlobalSweep, "BOTTOMLEFT", 0, -10)
	if SettingsDB.isLocked then
		isLocked:SetChecked(true)
	else
		isLocked:SetChecked(false)
	end

	local textFont = addon:GetControlLabel(false, parentFrame, "Font:", 60)
	textFont:SetPoint("TOPLEFT", isLocked, "BOTTOMLEFT", 0, -10)

	local dropdownFont = addon:GetControlDropdown(false, parentFrame, 120)
	dropdownFont:SetPoint("LEFT", textFont, "RIGHT", 10, 0)
	UIDropDownMenu_Initialize(dropdownFont, function(control, level, menuList)
		local fonts = LSM:List("font")
		for _, fontName in ipairs(fonts) do
			local fontObject = CreateFont("PoesBarsFont_" .. fontName)
			fontObject:SetFont(LSM:Fetch("font", fontName) or "Fonts\\FRIZQT__.TTF", 12, "")

			local info = UIDropDownMenu_CreateInfo()
			info.arg1 = fontName
			info.font = LSM:Fetch("font", fontName)
			info.fontObject = fontObject
			info.func = function(control, newFontName)
				SettingsDB.fontName = newFontName
				UIDropDownMenu_SetText(dropdownFont, newFontName)
				CreateTestIcon()
			end
			info.text = fontName

			UIDropDownMenu_AddButton(info, level)
		end
	end)
	UIDropDownMenu_SetText(dropdownFont, SettingsDB.fontName or "<Select>")
	UIDropDownMenu_SetWidth(dropdownFont, 180)

	local textBindingLabel = addon:GetControlLabel(false, parentFrame, "   Bind:", 60)
	textBindingLabel:SetPoint("TOPLEFT", textFont, "BOTTOMLEFT", 0, -10)

	local textBindingFontSize = addon:GetControlLabel(false, parentFrame, "Size", 30)
	textBindingFontSize:SetPoint("LEFT", textBindingLabel, "RIGHT", 10, 0)

	local inputBinding = addon:GetControlInput(false, parentFrame, 30, function(control)
		SettingsDB.bindingFontSize = addon:GetValueNumber(control:GetText())
		CreateTestIcon()
	end)
	inputBinding:SetNumeric(true)
	inputBinding:SetPoint("LEFT", textBindingFontSize, "RIGHT", 10, 0)

	local textBindingFontFlags = addon:GetControlLabel(false, parentFrame, "Flags", 40)
	textBindingFontFlags:SetPoint("LEFT", inputBinding, "RIGHT", 10, 0)

	local dropdownBinding = addon:GetControlDropdown(false, parentFrame, 120)
	dropdownBinding:SetPoint("LEFT", textBindingFontFlags, "RIGHT", 10, 0)
	UIDropDownMenu_Initialize(dropdownBinding, function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				SettingsDB.bindingFontFlags = text
				UIDropDownMenu_SetSelectedName(dropdownBinding, text)
				CreateTestIcon()
			end
			UIDropDownMenu_AddButton(info)
		end

		addItem("NONE")
		addItem("OUTLINE")
		addItem("THICKOUTLINE")
		addItem("MONOCHROME")
		addItem("OUTLINE, MONOCHROME")
		addItem("THICKOUTLINE, MONOCHROME")
	end)
	UIDropDownMenu_SetText(dropdownBinding, SettingsDB.bindingFontFlags or "NONE")

	local checkboxBinding = addon:GetControlCheckbox(false, "Shadow", parentFrame, function(control)
		SettingsDB.bindingFontShadow = control:GetChecked()
		CreateTestIcon()
	end)
	checkboxBinding:SetPoint("LEFT", dropdownBinding, "RIGHT", 10, 0)
	if SettingsDB.bindingFontShadow then
		checkboxBinding:SetChecked(true)
	else
		checkboxBinding:SetChecked(false)
	end

	local textChargesLabel = addon:GetControlLabel(false, parentFrame, "   Stack:", 60)
	textChargesLabel:SetPoint("TOPLEFT", textBindingLabel, "BOTTOMLEFT", 0, -10)

	local textChargesFontSize = addon:GetControlLabel(false, parentFrame, "Size", 30)
	textChargesFontSize:SetPoint("LEFT", textChargesLabel, "RIGHT", 10, 0)

	local inputCharges = addon:GetControlInput(false, parentFrame, 30, function(control)
		SettingsDB.chargesFontSize = addon:GetValueNumber(control:GetText())
		CreateTestIcon()
	end)
	inputCharges:SetNumeric(true)
	inputCharges:SetPoint("LEFT", textChargesFontSize, "RIGHT", 10, 0)

	local textChargesFontFlags = addon:GetControlLabel(false, parentFrame, "Flags", 40)
	textChargesFontFlags:SetPoint("LEFT", inputCharges, "RIGHT", 10, 0)

	local dropdownCharges = addon:GetControlDropdown(false, parentFrame, 120)
	dropdownCharges:SetPoint("LEFT", textChargesFontFlags, "RIGHT", 10, 0)
	UIDropDownMenu_Initialize(dropdownCharges, function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				SettingsDB.chargesFontFlags = text
				UIDropDownMenu_SetSelectedName(dropdownCharges, text)
				CreateTestIcon()
			end
			UIDropDownMenu_AddButton(info)
		end

		addItem("NONE")
		addItem("OUTLINE")
		addItem("THICKOUTLINE")
		addItem("MONOCHROME")
		addItem("OUTLINE, MONOCHROME")
		addItem("THICKOUTLINE, MONOCHROME")
	end)
	UIDropDownMenu_SetText(dropdownCharges, SettingsDB.chargesFontFlags or "NONE")

	local checkboxCharges = addon:GetControlCheckbox(false, "Shadow", parentFrame, function(control)
		SettingsDB.chargesFontShadow = control:GetChecked()
		CreateTestIcon()
	end)
	checkboxCharges:SetPoint("LEFT", dropdownCharges, "RIGHT", 10, 0)
	if SettingsDB.chargesFontShadow then
		checkboxCharges:SetChecked(true)
	else
		checkboxCharges:SetChecked(false)
	end

	local textCooldownLabel = addon:GetControlLabel(false, parentFrame, "   CD:", 60)
	textCooldownLabel:SetPoint("TOPLEFT", textChargesLabel, "BOTTOMLEFT", 0, -10)

	local textCooldownFontSize = addon:GetControlLabel(false, parentFrame, "Size", 30)
	textCooldownFontSize:SetPoint("LEFT", textCooldownLabel, "RIGHT", 10, 0)

	local inputCooldown = addon:GetControlInput(false, parentFrame, 30, function(control)
		SettingsDB.cooldownFontSize = addon:GetValueNumber(control:GetText())
		CreateTestIcon()
	end)
	inputCooldown:SetNumeric(true)
	inputCooldown:SetPoint("LEFT", textCooldownFontSize, "RIGHT", 10, 0)

	local textCooldownFontFlags = addon:GetControlLabel(false, parentFrame, "Flags", 40)
	textCooldownFontFlags:SetPoint("LEFT", inputCooldown, "RIGHT", 10, 0)

	local dropdownCooldown = addon:GetControlDropdown(false, parentFrame, 120)
	dropdownCooldown:SetPoint("LEFT", textCooldownFontFlags, "RIGHT", 10, 0)
	UIDropDownMenu_Initialize(dropdownCooldown, function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				SettingsDB.cooldownFontFlags = text
				UIDropDownMenu_SetSelectedName(dropdownCooldown, text)
				CreateTestIcon()
			end
			UIDropDownMenu_AddButton(info)
		end

		addItem("NONE")
		addItem("OUTLINE")
		addItem("THICKOUTLINE")
		addItem("MONOCHROME")
		addItem("OUTLINE, MONOCHROME")
		addItem("THICKOUTLINE, MONOCHROME")
	end)
	UIDropDownMenu_SetText(dropdownCooldown, SettingsDB.cooldownFontFlags or "NONE")

	local checkboxCooldown = addon:GetControlCheckbox(false, "Shadow", parentFrame, function(control)
		SettingsDB.cooldownFontShadow = control:GetChecked()
		CreateTestIcon()
	end)
	checkboxCooldown:SetPoint("LEFT", dropdownCooldown, "RIGHT", 10, 0)
	if SettingsDB.cooldownFontShadow then
		checkboxCooldown:SetChecked(true)
	else
		checkboxCooldown:SetChecked(false)
	end

	local textRankLabel = addon:GetControlLabel(false, parentFrame, "   Rank:", 60)
	textRankLabel:SetPoint("TOPLEFT", textCooldownLabel, "BOTTOMLEFT", 0, -10)

	local textRankFontSize = addon:GetControlLabel(false, parentFrame, "Size", 30)
	textRankFontSize:SetPoint("LEFT", textRankLabel, "RIGHT", 10, 0)

	local inputRank = addon:GetControlInput(false, parentFrame, 30, function(control)
		SettingsDB.rankFontSize = addon:GetValueNumber(control:GetText())
		CreateTestIcon()
	end)
	inputRank:SetNumeric(true)
	inputRank:SetPoint("LEFT", textRankFontSize, "RIGHT", 10, 0)

	local textRankFontFlags = addon:GetControlLabel(false, parentFrame, "Flags", 40)
	textRankFontFlags:SetPoint("LEFT", inputRank, "RIGHT", 10, 0)

	local dropdownRank = addon:GetControlDropdown(false, parentFrame, 120)
	dropdownRank:SetPoint("LEFT", textRankFontFlags, "RIGHT", 10, 0)
	UIDropDownMenu_Initialize(dropdownRank, function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				SettingsDB.rankFontFlags = text
				UIDropDownMenu_SetSelectedName(dropdownRank, text)
				CreateTestIcon()
			end
			UIDropDownMenu_AddButton(info)
		end

		addItem("NONE")
		addItem("OUTLINE")
		addItem("THICKOUTLINE")
		addItem("MONOCHROME")
		addItem("OUTLINE, MONOCHROME")
		addItem("THICKOUTLINE, MONOCHROME")
	end)
	UIDropDownMenu_SetText(dropdownRank, SettingsDB.rankFontFlags or "NONE")

	local checkboxRank = addon:GetControlCheckbox(false, "Shadow", parentFrame, function(control)
		SettingsDB.rankFontShadow = control:GetChecked()
		CreateTestIcon()
	end)
	checkboxRank:SetPoint("LEFT", dropdownRank, "RIGHT", 10, 0)
	if SettingsDB.rankFontShadow then
		checkboxRank:SetChecked(true)
	else
		checkboxRank:SetChecked(false)
	end

	parentFrame:SetScript("OnHide", function(frame)
		addon.isLoaded = false

		addon:Debounce("CreateIcons", 1, function()
			addon:CreateIcons()
			addon.isLoaded = true
		end)
	end)
	parentFrame:SetScript("OnShow", function(frame)
		inputBinding:SetText(SettingsDB.bindingFontSize)
		inputCharges:SetText(SettingsDB.chargesFontSize)
		inputCooldown:SetText(SettingsDB.cooldownFontSize)
		inputRank:SetText(SettingsDB.rankFontSize)

		CreateTestIcon()
	end)

	local categoryPoesBars = Settings.RegisterCanvasLayoutCategory(parentFrame, parentFrame.name)
	Settings.RegisterAddOnCategory(categoryPoesBars)
	return categoryPoesBars
end
