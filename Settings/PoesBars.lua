local addonName, addon = ...

local radioAnchors = {}
local radioOrientation = {}
local scrollFrame
local scrollFrameChild
local yOffset = 0

local function CreateOptionLine(category, itemID, specID, spellID)
	itemID = itemID or -1
	specID = specID or -1
	spellID = spellID or -1

	local settingName = itemID .. "_" .. spellID

	if not SpellsDB[specID] then
		SpellsDB[specID] = {}
	end

	local spellIcon = scrollFrameChild:CreateTexture(nil, "ARTWORK")
	spellIcon:SetPoint("TOPLEFT", 10, yOffset)
	spellIcon:SetSize(addon.settingsIconSize, addon.settingsIconSize)

	local categoryValue = SpellsDB[specID][settingName]
	if not categoryValue or categoryValue == "" then
		categoryValue = addon.unknown
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
				local rankText = scrollFrameChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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

	local textID = addon:GetControlLabel(false, scrollFrameChild, "", 100)
	textID:SetPoint("LEFT", spellIcon, "RIGHT", 10, 0)
	if itemID > 0 then
		textID:SetText(tostring(itemID))
	else
		textID:SetText(tostring(spellID))
	end

	local textName = addon:GetControlLabel(false, scrollFrameChild, newName, 200)
	textName:SetPoint("LEFT", textID, "RIGHT", 10, 0)

	local dropdownCategory = addon:GetControlDropdown(false, scrollFrameChild, 120)
	dropdownCategory:SetPoint("LEFT", textName, "RIGHT", 10, 0)

	local inputCategory = addon:GetControlInput(false, scrollFrameChild, 120)
	inputCategory:Hide()
	inputCategory:SetPoint("LEFT", dropdownCategory, "RIGHT", 10, 0)

	dropdownCategory.initializeFunc = function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				if text == "Add New..." then
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
		addItem(addon.ignored)
		addItem("Add New...")

		for _, option in ipairs(addon:GetValidCategories(false)) do
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

	yOffset = yOffset - addon.settingsIconSize - 10
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

function addon:AddSettingsPoesBars(parent)
    local showGlobalSweep = addon:GetControlCheckbox(false, "Show GCD Sweep", parent,
		function(control)
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
	end)
	isLocked:SetPoint("TOPLEFT", showGlobalSweep, "BOTTOMLEFT", 0, -10)
	if SettingsDB.isLocked then
		isLocked:SetChecked(true)
	else
		isLocked:SetChecked(false)
	end

	local categoryLabel = addon:GetControlLabel(false, parent, "Category:", 100)
	categoryLabel:SetPoint("TOPLEFT", isLocked, "BOTTOMLEFT", 0, -10)

	local categoryDropdown = addon:GetControlDropdown(false, parent, 120)
	categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", 10, 0)

	local categoryInput = addon:GetControlInput(false, parent, 120)
	categoryInput:Hide()
	categoryInput:SetPoint("LEFT", categoryDropdown, "RIGHT", 10, 0)

	categoryDropdown.initializeFunc = function(frame, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				if scrollFrameChild then
					for i, child in ipairs({ scrollFrameChild:GetChildren() }) do
						child:ClearAllPoints()
						child:Hide()
						child:SetParent(nil)
					end

					scrollFrameChild:ClearAllPoints()
					scrollFrameChild:Hide()
					scrollFrameChild:SetParent(nil)
				end

				if scrollFrame then
					scrollFrame:ClearAllPoints()
					scrollFrame:Hide()
					scrollFrame:SetParent(nil)
				end

				for i, child in ipairs(addon.settingsControls) do
					child:ClearAllPoints()
					child:Hide()
					child:SetParent(nil)

					child = nil
				end

				if text == "Add New..." then
					UIDropDownMenu_SetSelectedName(categoryDropdown, text)

					categoryInput:SetFocus()
					categoryInput:SetText("")
					categoryInput:Show()
				else
					categoryInput:Hide()

					scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
					scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)

					scrollFrameChild = CreateFrame("Frame", nil, scrollFrame)
					scrollFrameChild:SetSize(1, 1)

					scrollFrame:SetScrollChild(scrollFrameChild)

					local category = text
					if not category or category == "" then
						category = addon.unknown
					end

					UIDropDownMenu_SetSelectedName(categoryDropdown, category)

					if category ~= addon.ignored and category ~= addon.unknown then
						local settingsTable = SettingsDB[category] or {}
						local anchor = settingsTable.anchor or "CENTER"
						local iconSize = settingsTable.iconSize or 64
						local iconSpacing = settingsTable.iconSpacing or 2
						local isVertical = settingsTable.isVertical or false
						local showOnCooldown = settingsTable.showOnCooldown or false
						local showWhenAvailable = settingsTable.showWhenAvailable or false
						local wrapAfter = settingsTable.wrapAfter or 0
						local x = settingsTable.x or 0
						local y = settingsTable.y or 0

						x = math.floor(x + 0.5)
						y = math.floor(y + 0.5)

						local categoryDelete = addon:GetControlButton(true, "Delete", parent, 60, function(control)
							if category == "" or category == addon.ignored or category == "Add New..." or category == addon.unknown then
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

						local showOnCooldownCheckbox = addon:GetControlCheckbox(true, "Only Show On Cooldown or Aura Active",parent)
						showOnCooldownCheckbox:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, -10)
						if showOnCooldown then
							showOnCooldownCheckbox:SetChecked(true)
						else
							showOnCooldownCheckbox:SetChecked(false)
						end

						local showWhenAvailableCheckbox = addon:GetControlCheckbox(true, "Only Show When Available",parent)
						showWhenAvailableCheckbox:SetPoint("TOPLEFT", showOnCooldownCheckbox, "BOTTOMLEFT", 0, -10)
						if showWhenAvailable then
							showOnCooldownCheckbox:SetChecked(true)
						else
							showOnCooldownCheckbox:SetChecked(false)
						end

						showOnCooldownCheckbox:SetScript("OnClick",function(control)
							settingsTable.showOnCooldown = control:GetChecked()

							if settingsTable.showOnCooldown then
								showWhenAvailableCheckbox:SetChecked(false)
							end
						end)

						showWhenAvailableCheckbox:SetScript("OnClick",function(control)
							settingsTable.showWhenAvailable = control:GetChecked()

							if settingsTable.showWhenAvailable then
								showOnCooldownCheckbox:SetChecked(false)
							end
						end)

						local iconSizeLabel = addon:GetControlLabel(true, parent, "Icon Size:", 100)
						iconSizeLabel:SetPoint("TOPLEFT", showWhenAvailableCheckbox, "BOTTOMLEFT", 0, -10)

						local iconSizeInput = addon:GetControlInput(true, parent, 40, function(control)
							local value = strtrim(control:GetText())
							if value ~= "" then
								settingsTable.iconSize = tonumber(value)
							end
						end)
						iconSizeInput:SetNumeric(true)
						iconSizeInput:SetPoint("LEFT", iconSizeLabel, "RIGHT", 10, 0)
						iconSizeInput:SetText(tostring(iconSize))

						local positionXLabel = addon:GetControlLabel(true, parent, "X:", 100)
						positionXLabel:SetPoint("LEFT", iconSizeInput, "RIGHT", 10, 0)

						local positionXInput = addon:GetControlInput(true, parent, 40, function(control)
							local value = strtrim(control:GetText())
							if value ~= "" then
								settingsTable.x = tonumber(value)
							end
						end)
						positionXInput:SetNumeric(true)
						positionXInput:SetPoint("LEFT", positionXLabel, "RIGHT", 10, 0)
						positionXInput:SetText(tostring(x))

						local iconSpacingLabel = addon:GetControlLabel(true, parent, "Icon Gap:", 100)
						iconSpacingLabel:SetPoint("TOPLEFT", iconSizeLabel, "BOTTOMLEFT", 0, -10)

						local iconSpacingInput = addon:GetControlInput(true, parent, 40, function(control)
							local value = strtrim(control:GetText())
							if value ~= "" then
								settingsTable.iconSpacing = tonumber(value)
							end
						end)
						iconSpacingInput:SetNumeric(true)
						iconSpacingInput:SetPoint("LEFT", iconSpacingLabel, "RIGHT", 10, 0)
						iconSpacingInput:SetText(tostring(iconSpacing))

						local positionYLabel = addon:GetControlLabel(true, parent, "Y:", 100)
						positionYLabel:SetPoint("LEFT", iconSpacingInput, "RIGHT", 10, 0)

						local positionYInput = addon:GetControlInput(true, parent, 40, function(control)
							local value = strtrim(control:GetText())
							if value ~= "" then
								settingsTable.y = tonumber(value)
							end
						end)
						positionYInput:SetNumeric(true)
						positionYInput:SetPoint("LEFT", positionYLabel, "RIGHT", 10, 0)
						positionYInput:SetText(tostring(y))

						local wrapAfterLabel = addon:GetControlLabel(true, parent, "Wrap After:", 100)
						wrapAfterLabel:SetPoint("TOPLEFT", iconSpacingLabel, "BOTTOMLEFT", 0, -10)

						local wrapAfterInput = addon:GetControlInput(true, parent, 40, function(control)
							local value = strtrim(control:GetText())
							if value ~= "" then
								settingsTable.wrapAfter = tonumber(value)
							end
						end)
						wrapAfterInput:SetNumeric(true)
						wrapAfterInput:SetPoint("LEFT", wrapAfterLabel, "RIGHT", 10, 0)
						wrapAfterInput:SetText(tostring(wrapAfter))

						local orientationLabel = addon:GetControlLabel(true, parent, "Orientation:", 100)
						orientationLabel:SetPoint("TOPLEFT", wrapAfterLabel, "BOTTOMLEFT", 0, -10)

						local orientationHorizontal = addon:GetControlRadioButton(true, parent, radioOrientation, "Horizontal",
							function(control)
								addon:ClearRadios(radioOrientation)
								control:SetChecked(true)

								settingsTable.isVertical = false
							end)
						orientationHorizontal:SetPoint("LEFT", orientationLabel, "RIGHT", 10, 0)

						local orientationVertical = addon:GetControlRadioButton(true, parent, radioOrientation, "Vertical",
							function(control)
								addon:ClearRadios(radioOrientation)
								control:SetChecked(true)

								settingsTable.isVertical = true
							end)
						orientationVertical:SetPoint("LEFT", orientationHorizontal, "RIGHT", 110, 0)

						if isVertical then
							orientationHorizontal:SetChecked(false)
							orientationVertical:SetChecked(true)
						else
							orientationHorizontal:SetChecked(true)
							orientationVertical:SetChecked(false)
						end

						local anchorLabel = addon:GetControlLabel(true, parent, "Anchor:", 100)
						anchorLabel:SetPoint("TOPLEFT", orientationLabel, "BOTTOMLEFT", 0, -10)

						local anchorTopLeft = addon:GetControlRadioButton(true, parent, radioAnchors, "Top Left",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "TOPLEFT"
							end)
						anchorTopLeft:SetPoint("LEFT", anchorLabel, "RIGHT", 10, 0)

						local anchorTop = addon:GetControlRadioButton(true, parent, radioAnchors, "Top",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "TOP"
							end)
						anchorTop:SetPoint("LEFT", anchorTopLeft, "RIGHT", 110, 0)

						local anchorTopRight = addon:GetControlRadioButton(true, parent, radioAnchors, "Top Right",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "TOPRIGHT"
							end)
						anchorTopRight:SetPoint("LEFT", anchorTop, "RIGHT", 110, 0)

						local anchorLeft = addon:GetControlRadioButton(true, parent, radioAnchors, "Left",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "LEFT"
							end)
						anchorLeft:SetPoint("TOPLEFT", anchorTopLeft, "BOTTOMLEFT", 0, -10)

						local anchorCenter = addon:GetControlRadioButton(true, parent, radioAnchors,
							"Center",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "CENTER"
							end)
						anchorCenter:SetPoint("LEFT", anchorLeft, "RIGHT", 110, 0)

						local anchorRight = addon:GetControlRadioButton(true, parent, radioAnchors, "Right",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "RIGHT"
							end)
						anchorRight:SetPoint("LEFT", anchorCenter, "RIGHT", 110, 0)

						local anchorBottomLeft = addon:GetControlRadioButton(true, parent, radioAnchors, "Bottom Left",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "BOTTOMLEFT"
							end)
						anchorBottomLeft:SetPoint("TOPLEFT", anchorLeft, "BOTTOMLEFT", 0, -10)

						local anchorBottom = addon:GetControlRadioButton(true, parent, radioAnchors, "Bottom",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "BOTTOM"
							end)
						anchorBottom:SetPoint("LEFT", anchorBottomLeft, "RIGHT", 110, 0)

						local anchorBottomRight = addon:GetControlRadioButton(true, parent, radioAnchors, "Bottom Right",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "BOTTOMRIGHT"
							end)
						anchorBottomRight:SetPoint("LEFT", anchorBottom, "RIGHT", 110, 0)

						if anchor == "TOPLEFT" then
							anchorTopLeft:SetChecked(true)
						elseif anchor == "TOPRIGHT" then
							anchorTopRight:SetChecked(true)
						elseif anchor == "TOP" then
							anchorTop:SetChecked(true)
						elseif anchor == "BOTTOMLEFT" then
							anchorBottomLeft:SetChecked(true)
						elseif anchor == "BOTTOMRIGHT" then
							anchorBottomRight:SetChecked(true)
						elseif anchor == "BOTTOM" then
							anchorBottom:SetChecked(true)
						elseif anchor == "LEFT" then
							anchorLeft:SetChecked(true)
						elseif anchor == "RIGHT" then
							anchorRight:SetChecked(true)
						else
							anchorCenter:SetChecked(true)
						end

						scrollFrame:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", 0, -80)
					else
						scrollFrame:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, -10)
						scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
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

					for _, itemID in ipairs(SettingsDB.validItems) do
						CreateOptionLine(category, itemID, 0, -1)
					end
				end
			end
			UIDropDownMenu_AddButton(info)
		end

		addItem("")
		addItem("Add New...")
		addItem(addon.ignored)

		table.sort(SettingsDB.validCategories, function(a, b)
			return a < b
		end)

		for _, option in ipairs(addon:GetValidCategories(false)) do
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

	parent:SetScript("OnHide", function(frame)
		addon:RefreshSpells()
	end)
end