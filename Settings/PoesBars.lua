local addonName, addon = ...
local frameSample

local LSM = LibStub("LibSharedMedia-3.0")

local function CreateTestIcon(parent)
	if frameSample then
		frameSample:ClearAllPoints()
		frameSample:Hide()
		frameSample:SetParent(nil)

		frameSample = nil
	end

	local font = LSM:Fetch("font", SettingsDB.fontName) or "Fonts\\FRIZQT__.TTF"
	local itemID = 211880

	frameSample = CreateFrame("Frame", nil, parent)
	frameSample:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
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

		local binding = addon:GetKeyBind(itemID, itemName, -1)
		if binding then
			textBinding:SetText(addon:ReplaceBindings(binding))
		else
			textBinding:SetText("S4")
		end
	end)
end

function addon:AddSettingsPoesBars(parent)
	local showGlobalSweep = addon:GetControlCheckbox(false, "Show GCD Sweep", parent, function(control)
		SettingsDB.showGlobalSweep = control:GetChecked()
	end)
	showGlobalSweep:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
	if SettingsDB.showGlobalSweep then
		showGlobalSweep:SetChecked(true)
	else
		showGlobalSweep:SetChecked(false)
	end

	local isLocked = addon:GetControlCheckbox(false, "Lock Groups", parent, function(control)
		SettingsDB.isLocked = control:GetChecked()

		addon:CheckLockState()
	end)
	isLocked:SetPoint("TOPLEFT", showGlobalSweep, "BOTTOMLEFT", 0, -10)
	if SettingsDB.isLocked then
		isLocked:SetChecked(true)
	else
		isLocked:SetChecked(false)
	end

	local textFont = addon:GetControlLabel(false, parent, "Font:", 60)
	textFont:SetPoint("TOPLEFT", isLocked, "BOTTOMLEFT", 0, -10)

	local dropdownFont = addon:GetControlDropdown(false, parent, 120)
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
				CreateTestIcon(parent)
			end
			info.text = fontName

			UIDropDownMenu_AddButton(info, level)
		end
	end)
	UIDropDownMenu_SetText(dropdownFont, SettingsDB.fontName or "<Select>")
	UIDropDownMenu_SetWidth(dropdownFont, 180)

	local textBindingLabel = addon:GetControlLabel(false, parent, "   Bind:", 60)
	textBindingLabel:SetPoint("TOPLEFT", textFont, "BOTTOMLEFT", 0, -10)

	local textBindingFontSize = addon:GetControlLabel(false, parent, "Size", 30)
	textBindingFontSize:SetPoint("LEFT", textBindingLabel, "RIGHT", 10, 0)

	local inputBinding = addon:GetControlInput(false, parent, 30, function(control)
		SettingsDB.bindingFontSize = addon:GetValueNumber(control:GetText())
		CreateTestIcon(parent)
	end)
	inputBinding:SetPoint("LEFT", textBindingFontSize, "RIGHT", 10, 0)
	inputBinding:SetText("")

	local textBindingFontFlags = addon:GetControlLabel(false, parent, "Flags", 30)
	textBindingFontFlags:SetPoint("LEFT", inputBinding, "RIGHT", 10, 0)

	local dropdownBinding = addon:GetControlDropdown(false, parent, 120)
	dropdownBinding:SetPoint("LEFT", textBindingFontFlags, "RIGHT", 10, 0)
	UIDropDownMenu_Initialize(dropdownBinding, function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				SettingsDB.bindingFontFlags = text
				UIDropDownMenu_SetSelectedName(dropdownBinding, text)
				CreateTestIcon(parent)
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

	local checkboxBinding = addon:GetControlCheckbox(false, "Shadow", parent, function(control)
		SettingsDB.bindingFontShadow = control:GetChecked()
		CreateTestIcon(parent)
	end)
	checkboxBinding:SetPoint("LEFT", dropdownBinding, "RIGHT", 10, 0)
	if SettingsDB.bindingFontShadow then
		checkboxBinding:SetChecked(true)
	else
		checkboxBinding:SetChecked(false)
	end

	local textChargesLabel = addon:GetControlLabel(false, parent, "   Stack:", 60)
	textChargesLabel:SetPoint("TOPLEFT", textBindingLabel, "BOTTOMLEFT", 0, -10)

	local textChargesFontSize = addon:GetControlLabel(false, parent, "Size", 30)
	textChargesFontSize:SetPoint("LEFT", textChargesLabel, "RIGHT", 10, 0)

	local inputCharges = addon:GetControlInput(false, parent, 30, function(control)
		SettingsDB.chargesFontSize = addon:GetValueNumber(control:GetText())
		CreateTestIcon(parent)
	end)
	inputCharges:SetPoint("LEFT", textChargesFontSize, "RIGHT", 10, 0)
	inputCharges:SetText("")

	local textChargesFontFlags = addon:GetControlLabel(false, parent, "Flags", 30)
	textChargesFontFlags:SetPoint("LEFT", inputCharges, "RIGHT", 10, 0)

	local dropdownCharges = addon:GetControlDropdown(false, parent, 120)
	dropdownCharges:SetPoint("LEFT", textChargesFontFlags, "RIGHT", 10, 0)
	UIDropDownMenu_Initialize(dropdownCharges, function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				SettingsDB.chargesFontFlags = text
				UIDropDownMenu_SetSelectedName(dropdownCharges, text)
				CreateTestIcon(parent)
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

	local checkboxCharges = addon:GetControlCheckbox(false, "Shadow", parent, function(control)
		SettingsDB.chargesFontShadow = control:GetChecked()
		CreateTestIcon(parent)
	end)
	checkboxCharges:SetPoint("LEFT", dropdownCharges, "RIGHT", 10, 0)
	if SettingsDB.chargesFontShadow then
		checkboxCharges:SetChecked(true)
	else
		checkboxCharges:SetChecked(false)
	end

	local textCooldownLabel = addon:GetControlLabel(false, parent, "   CD:", 60)
	textCooldownLabel:SetPoint("TOPLEFT", textChargesLabel, "BOTTOMLEFT", 0, -10)

	local textCooldownFontSize = addon:GetControlLabel(false, parent, "Size", 30)
	textCooldownFontSize:SetPoint("LEFT", textCooldownLabel, "RIGHT", 10, 0)

	local inputCooldown= addon:GetControlInput(false, parent, 30, function(control)
		SettingsDB.cooldownFontSize = addon:GetValueNumber(control:GetText())
		CreateTestIcon(parent)
	end)
	inputCooldown:SetPoint("LEFT", textCooldownFontSize, "RIGHT", 10, 0)
	inputCooldown:SetText("")

	local textCooldownFontFlags = addon:GetControlLabel(false, parent, "Flags", 30)
	textCooldownFontFlags:SetPoint("LEFT", inputCooldown, "RIGHT", 10, 0)

	local dropdownCooldown = addon:GetControlDropdown(false, parent, 120)
	dropdownCooldown:SetPoint("LEFT", textCooldownFontFlags, "RIGHT", 10, 0)
	UIDropDownMenu_Initialize(dropdownCooldown, function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				SettingsDB.cooldownFontFlags = text
				UIDropDownMenu_SetSelectedName(dropdownCooldown, text)
				CreateTestIcon(parent)
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

	local checkboxCooldown = addon:GetControlCheckbox(false, "Shadow", parent, function(control)
		SettingsDB.cooldownFontShadow = control:GetChecked()
		CreateTestIcon(parent)
	end)
	checkboxCooldown:SetPoint("LEFT", dropdownCooldown, "RIGHT", 10, 0)
	if SettingsDB.cooldownFontShadow then
		checkboxCooldown:SetChecked(true)
	else
		checkboxCooldown:SetChecked(false)
	end

	local textRankLabel = addon:GetControlLabel(false, parent, "   Rank:", 60)
	textRankLabel:SetPoint("TOPLEFT", textCooldownLabel, "BOTTOMLEFT", 0, -10)

	local textRankFontSize = addon:GetControlLabel(false, parent, "Size", 30)
	textRankFontSize:SetPoint("LEFT", textRankLabel, "RIGHT", 10, 0)

	local inputRank = addon:GetControlInput(false, parent, 30, function(control)
		SettingsDB.rankFontSize = addon:GetValueNumber(control:GetText())
		CreateTestIcon(parent)
	end)
	inputRank:SetPoint("LEFT", textRankFontSize, "RIGHT", 10, 0)
	inputRank:SetText("")

	local textRankFontFlags = addon:GetControlLabel(false, parent, "Flags", 30)
	textRankFontFlags:SetPoint("LEFT", inputRank, "RIGHT", 10, 0)

	local dropdownRank = addon:GetControlDropdown(false, parent, 120)
	dropdownRank:SetPoint("LEFT", textRankFontFlags, "RIGHT", 10, 0)
	UIDropDownMenu_Initialize(dropdownRank, function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				SettingsDB.rankFontFlags = text
				UIDropDownMenu_SetSelectedName(dropdownRank, text)
				CreateTestIcon(parent)
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

	local checkboxRank = addon:GetControlCheckbox(false, "Shadow", parent, function(control)
		SettingsDB.rankFontShadow = control:GetChecked()
		CreateTestIcon(parent)
	end)
	checkboxRank:SetPoint("LEFT", dropdownRank, "RIGHT", 10, 0)
	if SettingsDB.rankFontShadow then
		checkboxRank:SetChecked(true)
	else
		checkboxRank:SetChecked(false)
	end

	CreateTestIcon(parent)

	parent:SetScript("OnShow",function(control)
		inputBinding:SetText(SettingsDB.bindingFontSize or 14)
		inputCharges:SetText(SettingsDB.chargesFontSize or 12)
		inputCooldown:SetText(SettingsDB.cooldownFontSize or 16)
		inputRank:SetText(SettingsDB.rankFontSize or 12)
	end)
end
