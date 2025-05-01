local addonName, addon = ...
local controlsToClear = {}
local mainFrame
local mainScrollFrame
local mainScrollFrameChild
local iconSize = 36
local radioAnchors = {}
local radioOrientation = {}
local yOffset = 0

local function ClearRadios(radioGroup)
	for _, b in ipairs(radioGroup) do
		b:SetChecked(false)
	end
end

local function CreateButton(addToTable, label, parent, width, onClick)
	local result = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	result:SetScript("OnClick", onClick)
	result:SetSize(width, 20)
	result:SetText(label)

	if addToTable then
		table.insert(controlsToClear, result)
	end

	return result
end

local function CreateCheckbox(addToTable, isChecked, label, parent, onClick)
	local result = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	result:SetChecked(isChecked)
	result:SetScript("OnClick", onClick)
	result.Text:SetText(label)

	if addToTable then
		table.insert(controlsToClear, result)
	end

	return result
end

local function CreateDropdown(addToTable, parent, width)
	local result = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")

	UIDropDownMenu_SetWidth(result, width)

	if addToTable then
		table.insert(controlsToClear, result)
	end

	return result
end

local function CreateInput(addToTable, parent, value, width, onEnterPressed)
	local result = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	result:SetAutoFocus(false)
	result:SetSize(width, 20)
	if value then
		result:SetText(value)
	else
		result:SetText("")
	end

	result:SetScript("OnEnterPressed", onEnterPressed)

	if addToTable then
		table.insert(controlsToClear, result)
	end

	return result
end

local function CreateLabel(addToTable, parent, text, width)
	local result = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	result:SetJustifyH("LEFT")
	result:SetJustifyV("MIDDLE")
	result:SetSize(width, 20)
	result:SetText(text)

	if addToTable then
		table.insert(controlsToClear, result)
	end

	return result
end

local function CreateRadioButton(addToTable, parent, radioGroup, radioValue, text, onClick)
	radioValue = radioValue or ""

	local result = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
	result:SetChecked(text:lower() == radioValue:lower())
	result:SetScript("OnClick", onClick)
	result.text:SetText(text)

	table.insert(radioGroup, result)

	if addToTable then
		table.insert(controlsToClear, result)
	end

	return result
end

local function CreateOptionLine(category, itemID, specID, spellID)
	itemID = itemID or -1
	specID = specID or -1
	spellID = spellID or -1

	local settingName = itemID .. "_" .. spellID

	if not SpellsDB[specID] then
		SpellsDB[specID] = {}
	end

	local spellIcon = mainScrollFrameChild:CreateTexture(nil, "ARTWORK")
	spellIcon:SetPoint("TOPLEFT", 10, yOffset)
	spellIcon:SetSize(iconSize, iconSize)

	local categoryValue = SpellsDB[specID][settingName]
	if not categoryValue or categoryValue == "" then
		categoryValue = "Unknown"
	end
	if category ~= categoryValue then
		return
	end

	local newIcon, newName

	if itemID > 0 then
		local itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = C_Item.GetItemInfo(itemID)

		if itemLink then
			local qualityTier = itemLink:match("|A:Professions%-ChatIcon%-Quality%-Tier(%d+)")

			if qualityTier then
				local rankText = mainScrollFrameChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				rankText:SetFont(rankText:GetFont(), 16, "OUTLINE")
				rankText:SetPoint("BOTTOMLEFT", spellIcon, "BOTTOMLEFT", 0, -10)
				rankText:SetShadowColor(0, 0, 0, 1)
				rankText:SetShadowOffset(0, 0)
				rankText:SetTextColor(1, 1, 1, 1)

				if qualityTier == "1" then
					rankText:SetText("*")
				elseif qualityTier == "2" then
					rankText:SetText("**")
				elseif qualityTier == "3" then
					rankText:SetText("***")
				else
					rankText:SetText("")
				end
			end
		end

		if itemName then
			newName = itemName
		end

		if itemTexture then
			newIcon = itemTexture
		end

		local _, itemSpellID = C_Item.GetItemSpell(itemID)
		if itemSpellID and itemSpellID > 0 then
			spellID = itemSpellID
		end
	end

	if spellID > 0 then
		local spellInfo = C_Spell.GetSpellInfo(spellID)

		if not newIcon or newIcon == "" then
			newIcon = spellInfo.iconID
		end

		if not newName or newName == "" then
			newName = spellInfo.name
		end
	end

	if not newName or newName == "" then
		return
	end

	spellIcon:SetTexture(newIcon)

	local textID = CreateLabel(false, mainScrollFrameChild, "", 100)
	textID:SetPoint("LEFT", spellIcon, "RIGHT", 10, 0)
	if itemID > 0 then
		textID:SetText(tostring(itemID))
	else
		textID:SetText(tostring(spellID))
	end

	local textName = CreateLabel(false, mainScrollFrameChild, newName, 200)
	textName:SetPoint("LEFT", textID, "RIGHT", 10, 0)

	local dropdownCategory = CreateDropdown(false, mainScrollFrameChild, 120)
	dropdownCategory:SetPoint("LEFT", textName, "RIGHT", 10, 0)

	local inputCategory = CreateInput(false, mainScrollFrameChild, "", 120)
	inputCategory:Hide()
	inputCategory:SetPoint("LEFT", dropdownCategory, "RIGHT", 10, 0)

	dropdownCategory.initializeFunc = function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				if text == "Other..." then
					inputCategory:SetFocus()
					inputCategory:SetText("")
					inputCategory:Show()
				else
					SpellsDB[specID][settingName] = text
					UIDropDownMenu_SetSelectedName(dropdownCategory, text)
					inputCategory:Hide()
				end
			end
			UIDropDownMenu_AddButton(info)
		end

		addItem("")
		addItem("Ignored")
		addItem("Other...")

		for _, option in ipairs(SettingsDB.validCategories) do
			addItem(option)
		end
	end

	inputCategory:SetScript("OnEnterPressed", function(control)
		local value = strtrim(control:GetText())
		if value ~= "" then
			table.insert(SettingsDB.validCategories, value)
			SpellsDB[specID][settingName] = value
			UIDropDownMenu_SetSelectedName(dropdownCategory, value)
			control:Hide()
			control:ClearFocus()
			UIDropDownMenu_Initialize(dropdownCategory, dropdownCategory.initializeFunc)
		end
	end)

	UIDropDownMenu_Initialize(dropdownCategory, dropdownCategory.initializeFunc)

	if categoryValue ~= "" then
		UIDropDownMenu_SetSelectedName(dropdownCategory, categoryValue)
	else
		UIDropDownMenu_SetText(dropdownCategory, "<Select>")
	end

	yOffset = yOffset - iconSize - 10
end

local function ProcessSpell(category, specID, spellIndex)
	local itemInfo = C_SpellBook.GetSpellBookItemInfo(spellIndex, Enum.SpellBookSpellBank.Player)
	if not itemInfo then
		return
	end

	if itemInfo.isPassive then
		return
	end

	if itemInfo.isOffSpec then
		return
	end

	if itemInfo.itemType ~= Enum.SpellBookItemType.Spell then
		return
	end

	CreateOptionLine(category, -1, specID, itemInfo.spellID)
end

function addon:CreateSettings()
	mainFrame = CreateFrame("Frame", addonName.."SettingsFrame",UIParent)
	mainFrame.name = addonName

	local showGlobalSweep = CreateCheckbox(false, SettingsDB.showGlobalSweep, "Show GCD Sweep", mainFrame,
		function(frame)
			SettingsDB.showGlobalSweep = frame:GetChecked()
		end)
	showGlobalSweep:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -10)

	local isLocked = CreateCheckbox(false, SettingsDB.isLocked, "Lock Groups", mainFrame, function(frame)
		SettingsDB.isLocked = frame:GetChecked()
	end)
	isLocked:SetPoint("TOPLEFT", showGlobalSweep, "BOTTOMLEFT", 0, -10)

	local categoryLabel = CreateLabel(false, mainFrame, "Category:", 100)
	categoryLabel:SetPoint("TOPLEFT", isLocked, "BOTTOMLEFT", 0, -10)

	local categoryDropdown = CreateDropdown(false, mainFrame, 120)
	categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", 10, 0)

	local categoryInput = CreateInput(false, mainFrame, "", 120)
	categoryInput:Hide()
	categoryInput:SetPoint("LEFT", categoryDropdown, "RIGHT", 10, 0)

	categoryDropdown.initializeFunc = function(frame, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				if mainScrollFrameChild then
					for i, child in ipairs({ mainScrollFrameChild:GetChildren() }) do
						child:ClearAllPoints()
						child:Hide()
						child:SetParent(nil)
					end

					mainScrollFrameChild:ClearAllPoints()
					mainScrollFrameChild:Hide()
					mainScrollFrameChild:SetParent(nil)
				end

				if mainScrollFrame then
					mainScrollFrame:ClearAllPoints()
					mainScrollFrame:Hide()
					mainScrollFrame:SetParent(nil)
				end

				for i, child in ipairs(controlsToClear) do
					child:ClearAllPoints()
					child:Hide()
					child:SetParent(nil)

					child = nil
				end

				if text == "Other..." then
					UIDropDownMenu_SetSelectedName(categoryDropdown, text)

					categoryInput:SetFocus()
					categoryInput:SetText("")
					categoryInput:Show()
				else
					categoryInput:Hide()

					mainScrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
					mainScrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)

					mainScrollFrameChild = CreateFrame("Frame", nil, mainScrollFrame)
					mainScrollFrameChild:SetSize(1, 1)
					mainScrollFrame:SetScrollChild(mainScrollFrameChild)

					local category = text
					if not category or category == "" then
						category = "Unknown"
					end

					UIDropDownMenu_SetSelectedName(categoryDropdown, category)

					if category ~= "Ignored" and category ~= "Unknown" then
						local settingTable = SettingsDB[category] or {}

						local categoryDelete = CreateButton(true, "Delete", mainFrame, 60, function(control)
							if category == "" or category == "Ignored" or category == "Other..." or category == "Unknown" then
								return
							end

							for _, innerTable in pairs(SpellsDB) do
								for key, value in pairs(innerTable) do
									if value == category then
										innerTable[key] = ""
									end
								end
							end

							UIDropDownMenu_SetText(categoryDropdown, "<Select>")
						end)
						categoryDelete:SetPoint("LEFT", categoryInput, "RIGHT", 10, 0)

						local iconSizeLabel = CreateLabel(true, mainFrame, "Icon Size:", 100)
						iconSizeLabel:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, -10)

						local iconSizeInput = CreateInput(true, mainFrame, settingTable.iconSize or 64, 40,
							function(control)
								local value = strtrim(control:GetText())
								if value ~= "" then
									settingTable.iconSize = tonumber(value)
								end
							end)
						iconSizeInput:SetNumeric(true)
						iconSizeInput:SetPoint("LEFT", iconSizeLabel, "RIGHT", 10, 0)

						local positionXLabel = CreateLabel(true, mainFrame, "X:", 100)
						positionXLabel:SetPoint("LEFT", iconSizeInput, "RIGHT", 10, 0)

						local positionXInput = CreateInput(true, mainFrame, settingTable.x or 0, 40,
							function(control)
								local value = strtrim(control:GetText())
								if value ~= "" then
									settingTable.x = tonumber(value)
								end
							end)
						positionXInput:SetNumeric(true)
						positionXInput:SetPoint("LEFT", positionXLabel, "RIGHT", 10, 0)

						local iconSpacingLabel = CreateLabel(true, mainFrame, "Icon Spacing:", 100)
						iconSpacingLabel:SetPoint("TOPLEFT", iconSizeLabel, "BOTTOMLEFT", 0, -10)

						local iconSpacingInput = CreateInput(true, mainFrame, settingTable.iconSpacing or 2, 40,
							function(control)
								local value = strtrim(control:GetText())
								if value ~= "" then
									settingTable.iconSpacing = tonumber(value)
								end
							end)
						iconSpacingInput:SetNumeric(true)
						iconSpacingInput:SetPoint("LEFT", iconSpacingLabel, "RIGHT", 10, 0)

						local positionYLabel = CreateLabel(true, mainFrame, "Y:", 100)
						positionYLabel:SetPoint("LEFT", iconSpacingInput, "RIGHT", 10, 0)

						local positionYInput = CreateInput(true, mainFrame, settingTable.y or 0, 40,
							function(control)
								local value = strtrim(control:GetText())
								if value ~= "" then
									settingTable.y = tonumber(value)
								end
							end)
						positionYInput:SetNumeric(true)
						positionYInput:SetPoint("LEFT", positionYLabel, "RIGHT", 10, 0)

						local orientationLabel = CreateLabel(true, mainFrame, "Orientation:", 100)
						orientationLabel:SetPoint("TOPLEFT", iconSpacingLabel, "BOTTOMLEFT", 0, -10)

						local orientationHorizontal = CreateRadioButton(true, mainFrame, radioOrientation, "",
							"Horizontal",
							function(control)
								ClearRadios(radioOrientation)
								control:SetChecked(true)

								settingTable.isVertical = false
							end)
						orientationHorizontal:SetPoint("LEFT", orientationLabel, "RIGHT", 10, 0)

						local orientationVertical = CreateRadioButton(true, mainFrame, radioOrientation, "", "Vertical",
							function(control)
								ClearRadios(radioOrientation)
								control:SetChecked(true)

								settingTable.isVertical = true
							end)
						orientationVertical:SetPoint("LEFT", orientationHorizontal, "RIGHT", 110, 0)

						if settingTable.isVertical then
							orientationHorizontal:SetChecked(false)
							orientationVertical:SetChecked(true)
						else
							orientationHorizontal:SetChecked(true)
							orientationVertical:SetChecked(false)
						end

						local anchorLabel = CreateLabel(true, mainFrame, "Anchor:", 100)
						anchorLabel:SetPoint("TOPLEFT", orientationLabel, "BOTTOMLEFT", 0, -10)

						local anchorTopLeft = CreateRadioButton(true, mainFrame, radioAnchors, settingTable.anchor,
							"Top Left",
							function(control)
								ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingTable.anchor = "TOPLEFT"
							end)
						anchorTopLeft:SetPoint("LEFT", anchorLabel, "RIGHT", 10, 0)

						local anchorTop = CreateRadioButton(true, mainFrame, radioAnchors, settingTable.anchor, "Top",
							function(control)
								ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingTable.anchor = "TOP"
							end)
						anchorTop:SetPoint("LEFT", anchorTopLeft, "RIGHT", 110, 0)

						local anchorTopRight = CreateRadioButton(true, mainFrame, radioAnchors, settingTable.anchor,
							"Top Right",
							function(control)
								ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingTable.anchor = "TOPRIGHT"
							end)
						anchorTopRight:SetPoint("LEFT", anchorTop, "RIGHT", 110, 0)

						local anchorLeft = CreateRadioButton(true, mainFrame, radioAnchors, settingTable.anchor, "Left",
							function(control)
								ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingTable.anchor = "LEFT"
							end)
						anchorLeft:SetPoint("TOPLEFT", anchorTopLeft, "BOTTOMLEFT", 0, -10)

						local anchorCenter = CreateRadioButton(true, mainFrame, radioAnchors, settingTable.anchor,
							"Center",
							function(control)
								ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingTable.anchor = "CENTER"
							end)
						anchorCenter:SetPoint("LEFT", anchorLeft, "RIGHT", 110, 0)

						local anchorRight = CreateRadioButton(true, mainFrame, radioAnchors, settingTable.anchor, "Right",
							function(control)
								ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingTable.anchor = "RIGHT"
							end)
						anchorRight:SetPoint("LEFT", anchorCenter, "RIGHT", 110, 0)

						local anchorBottomLeft = CreateRadioButton(true, mainFrame, radioAnchors, settingTable.anchor,
							"Bottom Left", function(control)
								ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingTable.anchor = "BOTTOMLEFT"
							end)
						anchorBottomLeft:SetPoint("TOPLEFT", anchorLeft, "BOTTOMLEFT", 0, -10)

						local anchorBottom = CreateRadioButton(true, mainFrame, radioAnchors, settingTable.anchor,
							"Bottom",
							function(control)
								ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingTable.anchor = "BOTTOM"
							end)
						anchorBottom:SetPoint("LEFT", anchorBottomLeft, "RIGHT", 110, 0)

						local anchorBottomRight = CreateRadioButton(true, mainFrame, radioAnchors, settingTable.anchor,
							"Bottom Right",
							function(control)
								ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingTable.anchor = "BOTTOMRIGHT"
							end)
						anchorBottomRight:SetPoint("LEFT", anchorBottom, "RIGHT", 110, 0)

						mainScrollFrame:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", 0, -80)
					else
						mainScrollFrame:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, -10)
						mainScrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)
					end

					local currentSpec = GetSpecialization()
					if not currentSpec then
						return
					end

					local playerSpecID = GetSpecializationInfo(currentSpec)
					if not playerSpecID then
						return
					end

					yOffset = -10

					for i = 1, C_SpellBook.GetNumSpellBookSkillLines() + 1 do
						local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

						if lineInfo then
							if lineInfo.name == "General" then
								for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
									ProcessSpell(category, 0, j)
								end
							else
								if lineInfo.specID then
									if lineInfo.specID == playerSpecID then
										for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
											ProcessSpell(category, playerSpecID, j)
										end
									end
								else
									for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
										ProcessSpell(category, playerSpecID, j)
									end
								end
							end
						end
					end

					if addon.forcedSpellsBySpellID[playerSpecID] then
						for spellID, forcedSpellID in pairs(addon.forcedSpellsBySpellID[playerSpecID]) do
							if IsSpellKnown(spellID, false) then
								CreateOptionLine(category, -1, playerSpecID, forcedSpellID)
							end
						end
					end

					if addon.forcedSpellsByHeroTree[playerSpecID] then
						local playerHeroTalentSpec = C_ClassTalents.GetActiveHeroTalentSpec()

						local spells = addon.forcedSpellsByHeroTree[playerSpecID] and
							addon.forcedSpellsByHeroTree[playerSpecID][playerHeroTalentSpec]
						if spells then
							for _, forcedSpellID in ipairs(spells) do
								CreateOptionLine(category, -1, playerSpecID, forcedSpellID)
							end
						end
					end

					for _, itemID in ipairs(SettingsDB.validItems) do
						CreateOptionLine(category, itemID, 0, -1)
					end
				end
			end
			UIDropDownMenu_AddButton(info)
		end

		addItem("")
		addItem("Ignored")
		addItem("Other...")

		for _, option in ipairs(SettingsDB.validCategories) do
			addItem(option)
		end
	end

	categoryInput:SetScript("OnEnterPressed", function(frame)
		local value = strtrim(frame:GetText())
		if value ~= "" then
			table.insert(SettingsDB.validCategories, value)
			UIDropDownMenu_SetSelectedName(categoryDropdown, value)
			frame:ClearFocus()
			frame:Hide()
			UIDropDownMenu_Initialize(categoryDropdown, categoryDropdown.initializeFunc)
		end
	end)

	UIDropDownMenu_Initialize(categoryDropdown, categoryDropdown.initializeFunc)
	UIDropDownMenu_SetText(categoryDropdown, "<Select>")

	mainFrame:SetScript("OnHide", function(frame)
		addon:CreateIcons()
	end)

	local mainCategory, mainLayout = Settings.RegisterCanvasLayoutCategory(mainFrame, mainFrame.name)
	local registeredCategory = Settings.RegisterAddOnCategory(mainCategory)
	addon.mainCategory = registeredCategory
end
