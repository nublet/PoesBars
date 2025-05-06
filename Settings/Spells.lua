local addonName, addon = ...

local optionLines = {}
local radioAnchors = {}
local radioOrientation = {}
local scrollFrame
local scrollFrameChild

local LSM = LibStub("LibSharedMedia-3.0")
local font = LSM:Fetch("font", "Naowh") or "Fonts\\FRIZQT__.TTF"

local function ClearScrollFrame()
	for _, frameLine in ipairs(optionLines) do
		for i, child in ipairs({ frameLine:GetChildren() }) do
			child:ClearAllPoints()
			child:Hide()
			child:SetParent(nil)

			child = nil
		end
	end
	wipe(optionLines)

	if scrollFrameChild then
		for i, child in ipairs({ scrollFrameChild:GetChildren() }) do
			child:ClearAllPoints()
			child:Hide()
			child:SetParent(nil)

			child = nil
		end

		scrollFrameChild:ClearAllPoints()
		scrollFrameChild:Hide()
		scrollFrameChild:SetParent(nil)

		scrollFrameChild = nil
	end

	if scrollFrame then
		scrollFrame:ClearAllPoints()
		scrollFrame:Hide()
		scrollFrame:SetParent(nil)

		scrollFrame = nil
	end

	for i, child in ipairs(addon.settingsControls) do
		child:ClearAllPoints()
		child:Hide()
		child:SetParent(nil)

		child = nil
	end
end

local function LoadLayout(category, playerSpecID)
	if not CategoryOrderDB[category] then
		CategoryOrderDB[category] = {}
	end
	if not CategoryOrderDB[category][playerSpecID] then
		CategoryOrderDB[category][playerSpecID] = {}
	end

	local yOffset = 0
	local seenSettingNames = {}

	for _, settingName in ipairs(CategoryOrderDB[category][playerSpecID]) do
		if optionLines[settingName] then
			seenSettingNames[settingName] = true

			optionLines[settingName]:SetPoint("TOPLEFT", 10, yOffset)

			yOffset = yOffset - addon.settingsIconSize - 10
		end
	end

	for settingName, frameLine in pairs(optionLines) do
		if not seenSettingNames[settingName] then
			frameLine:SetPoint("TOPLEFT", 10, yOffset)

			table.insert(CategoryOrderDB[category][playerSpecID], settingName)

			yOffset = yOffset - addon.settingsIconSize - 10
		end
	end
end

local function MoveSetting(category, playerSpecID, settingName, direction)
	local orderTable = CategoryOrderDB[category][playerSpecID]
	if not orderTable then
		return
	end

	for i = 1, #orderTable do
		if orderTable[i] == settingName then
			local targetIndex = i + direction
			if targetIndex >= 1 and targetIndex <= #orderTable then
				orderTable[i], orderTable[targetIndex] = orderTable[targetIndex], orderTable[i]

				LoadLayout(category, playerSpecID)
			end

			break
		end
	end
end

local function CreateOptionLine(category, itemID, playerSpecID, specID, spellID)
	itemID = itemID or -1
	specID = specID or -1
	spellID = spellID or -1

	local settingName = itemID .. "_" .. spellID

	if not SpellsDB[specID] then
		SpellsDB[specID] = {}
	end

	local categoryValue = SpellsDB[specID][settingName]
	if not categoryValue or categoryValue == "" then
		categoryValue = addon.unknown
	end
	if category ~= categoryValue then
		return nil
	end

	local frameLine = CreateFrame("Frame", nil, scrollFrameChild)
	frameLine:SetPoint("TOPLEFT", 0, 0)
	frameLine:SetSize(1, 1)
	frameLine.category = category
	frameLine.itemID = itemID
	frameLine.settingName = settingName
	frameLine.specID = specID
	frameLine.spellID = spellID

	local frameIcon = CreateFrame("Frame", nil, frameLine)
	frameIcon:EnableMouse(true)
	frameIcon:SetPoint("TOPLEFT", 0, 0)
	frameIcon:SetSize(addon.settingsIconSize, addon.settingsIconSize)
	frameIcon:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local textureIcon = frameIcon:CreateTexture(nil, "ARTWORK")
	textureIcon:SetAllPoints()

	local textID = addon:GetControlLabel(false, frameLine, "", 100)
	textID:SetPoint("LEFT", frameIcon, "RIGHT", 10, 0)

	local textName = addon:GetControlLabel(false, frameLine, "", 200)
	textName:SetPoint("LEFT", textID, "RIGHT", 10, 0)

	local dropdownCategory = addon:GetControlDropdown(false, frameLine, 120)
	dropdownCategory:SetPoint("LEFT", textName, "RIGHT", 10, 0)

	local buttonMoveDown = addon:GetControlButton(true, "Down", frameLine, 60, function(control)
		MoveSetting(category, playerSpecID, settingName, 1)
	end)
	buttonMoveDown:SetPoint("TOPLEFT", dropdownCategory, "RIGHT", 5, 0)

	local buttonMoveUp = addon:GetControlButton(true, "Up", frameLine, 60, function(control)
		MoveSetting(category, playerSpecID, settingName, -1)
	end)
	buttonMoveUp:SetPoint("BOTTOMLEFT", dropdownCategory, "RIGHT", 5, 0)

	if itemID > 0 then
		local textRank = frameIcon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		textRank:SetFont(frameIcon:GetFont(), 10, "OUTLINE")
		textRank:SetPoint("BOTTOMLEFT", frameIcon, "BOTTOMLEFT", 0, 0)
		textRank:SetShadowColor(0, 0, 0, 1)
		textRank:SetShadowOffset(0, 0)
		textRank:SetText("")
		textRank:SetTextColor(0, 1, 0, 1)

		local item = Item:CreateFromItemID(itemID)
		item:ContinueOnItemLoad(function()
			local itemName = item:GetItemName()
			local itemLink = item:GetItemLink()
			local itemTexture = item:GetItemIcon()

			textID:SetText(itemID)
			textName:SetText(itemName)
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
		end)

		frameIcon:SetScript("OnEnter", function(control)
			GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
			GameTooltip:SetItemByID(itemID)
			GameTooltip:Show()
		end)
	elseif spellID > 0 then
		local spellInfo = C_Spell.GetSpellInfo(spellID)

		textID:SetText(spellID)
		textName:SetText(spellInfo.name)
		textureIcon:SetTexture(spellInfo.iconID)

		local tooltipData = C_TooltipInfo.GetSpellByID(spellID)
		if tooltipData then
			frameIcon:SetScript("OnEnter", function(control)
				GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
				GameTooltip:SetSpellByID(spellID)
				GameTooltip:Show()
			end)
		end
	end

	dropdownCategory.initializeFunc = function(control, level, menuList)
		local function addItem(text)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.func = function()
				SpellsDB[specID][settingName] = text
				UIDropDownMenu_SetSelectedName(dropdownCategory, text)
			end
			UIDropDownMenu_AddButton(info)
		end

		addItem("")
		addItem(addon.ignored)

		local validCategories = addon:GetValidCategories(false)

		for index = 1, #validCategories do
			local name = validCategories[index]

			addItem(name)
		end
	end

	UIDropDownMenu_Initialize(dropdownCategory, dropdownCategory.initializeFunc)

	if categoryValue ~= "" then
		UIDropDownMenu_SetSelectedName(dropdownCategory, categoryValue)
	else
		UIDropDownMenu_SetText(dropdownCategory, "<Select>")
	end

	return frameLine
end

local function ProcessSpell(category, playerSpecID, specID, spellBank, spellIndex)
	local itemInfo = C_SpellBook.GetSpellBookItemInfo(spellIndex, spellBank)
	if not itemInfo then
		return nil
	end

	if itemInfo.isPassive then
		return nil
	end

	if itemInfo.isOffSpec then
		return nil
	end

	if itemInfo.itemType == Enum.SpellBookItemType.Spell or itemInfo.itemType == Enum.SpellBookItemType.PetAction then
	else
		return nil
	end

	return CreateOptionLine(category, -1, playerSpecID, specID, itemInfo.spellID)
end

function addon:AddSettingsSpells(parent)
	local categoryLabel = addon:GetControlLabel(false, parent, "Category:", 100)
	categoryLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)

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
				ClearScrollFrame()

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

						local showOnCooldownCheckbox = addon:GetControlCheckbox(true,
							"Only Show On Cooldown or Aura Active", parent)
						showOnCooldownCheckbox:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, -10)
						if showOnCooldown then
							showOnCooldownCheckbox:SetChecked(true)
						else
							showOnCooldownCheckbox:SetChecked(false)
						end

						local showWhenAvailableCheckbox = addon:GetControlCheckbox(true, "Only Show When Available",
							parent)
						showWhenAvailableCheckbox:SetPoint("TOPLEFT", showOnCooldownCheckbox, "BOTTOMLEFT", 0, -10)
						if showWhenAvailable then
							showOnCooldownCheckbox:SetChecked(true)
						else
							showOnCooldownCheckbox:SetChecked(false)
						end

						showOnCooldownCheckbox:SetScript("OnClick", function(control)
							settingsTable.showOnCooldown = control:GetChecked()

							if settingsTable.showOnCooldown then
								showWhenAvailableCheckbox:SetChecked(false)
							end
						end)

						showWhenAvailableCheckbox:SetScript("OnClick", function(control)
							settingsTable.showWhenAvailable = control:GetChecked()

							if settingsTable.showWhenAvailable then
								showOnCooldownCheckbox:SetChecked(false)
							end
						end)

						local iconSizeLabel = addon:GetControlLabel(true, parent, "Icon Size:", 100)
						iconSizeLabel:SetPoint("TOPLEFT", showWhenAvailableCheckbox, "BOTTOMLEFT", 0, -10)

						local iconSizeInput = addon:GetControlInput(true, parent, 40, function(control)
							settingsTable.iconSize = addon:GetValueNumber(control:GetText())
						end)
						iconSizeInput:SetNumeric(true)
						iconSizeInput:SetPoint("LEFT", iconSizeLabel, "RIGHT", 10, 0)
						iconSizeInput:SetText(iconSize)

						local positionXLabel = addon:GetControlLabel(true, parent, "X:", 100)
						positionXLabel:SetPoint("LEFT", iconSizeInput, "RIGHT", 10, 0)

						local positionXInput = addon:GetControlInput(true, parent, 40, function(control)
							settingsTable.x = addon:GetValueNumber(control:GetText())
						end)
						positionXInput:SetNumeric(true)
						positionXInput:SetPoint("LEFT", positionXLabel, "RIGHT", 10, 0)
						positionXInput:SetText(x)

						local iconSpacingLabel = addon:GetControlLabel(true, parent, "Icon Gap:", 100)
						iconSpacingLabel:SetPoint("TOPLEFT", iconSizeLabel, "BOTTOMLEFT", 0, -10)

						local iconSpacingInput = addon:GetControlInput(true, parent, 40, function(control)
							settingsTable.iconSpacing = addon:GetValueNumber(control:GetText())
						end)
						iconSpacingInput:SetNumeric(true)
						iconSpacingInput:SetPoint("LEFT", iconSpacingLabel, "RIGHT", 10, 0)
						iconSpacingInput:SetText(iconSpacing)

						local positionYLabel = addon:GetControlLabel(true, parent, "Y:", 100)
						positionYLabel:SetPoint("LEFT", iconSpacingInput, "RIGHT", 10, 0)

						local positionYInput = addon:GetControlInput(true, parent, 40, function(control)
							settingsTable.y = addon:GetValueNumber(control:GetText())
						end)
						positionYInput:SetNumeric(true)
						positionYInput:SetPoint("LEFT", positionYLabel, "RIGHT", 10, 0)
						positionYInput:SetText(y)

						local wrapAfterLabel = addon:GetControlLabel(true, parent, "Wrap After:", 100)
						wrapAfterLabel:SetPoint("TOPLEFT", iconSpacingLabel, "BOTTOMLEFT", 0, -10)

						local wrapAfterInput = addon:GetControlInput(true, parent, 40, function(control)
							settingsTable.wrapAfter = addon:GetValueNumber(control:GetText())
						end)
						wrapAfterInput:SetNumeric(true)
						wrapAfterInput:SetPoint("LEFT", wrapAfterLabel, "RIGHT", 10, 0)
						wrapAfterInput:SetText(wrapAfter)

						local orientationLabel = addon:GetControlLabel(true, parent, "Orientation:", 100)
						orientationLabel:SetPoint("TOPLEFT", wrapAfterLabel, "BOTTOMLEFT", 0, -10)

						local orientationHorizontal = addon:GetControlRadioButton(true, parent, radioOrientation,
							"Horizontal",
							function(control)
								addon:ClearRadios(radioOrientation)
								control:SetChecked(true)

								settingsTable.isVertical = false
							end)
						orientationHorizontal:SetPoint("LEFT", orientationLabel, "RIGHT", 10, 0)

						local orientationVertical = addon:GetControlRadioButton(true, parent, radioOrientation,
							"Vertical",
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

					local numPetSpells, petNameToken = C_SpellBook.HasPetSpells()

					if numPetSpells and numPetSpells > 0 then
						for j = 1, numPetSpells do
							local frameLine = ProcessSpell(category, playerSpecID, 0, Enum.SpellBookSpellBank.Pet, j)
							if frameLine then
								optionLines[frameLine.settingName] = frameLine
							end
						end
					end

					for i = 1, C_SpellBook.GetNumSpellBookSkillLines() + 1 do
						local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

						if lineInfo then
							if lineInfo.name == "General" then
								for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
									local frameLine = ProcessSpell(category, playerSpecID, 0,
										Enum.SpellBookSpellBank.Player, j)
									if frameLine then
										optionLines[frameLine.settingName] = frameLine
									end
								end
							else
								if lineInfo.specID then
									if lineInfo.specID == playerSpecID then
										for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
											local frameLine = ProcessSpell(category, playerSpecID, playerSpecID,
												Enum.SpellBookSpellBank.Player, j)
											if frameLine then
												optionLines[frameLine.settingName] = frameLine
											end
										end
									end
								else
									for j = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
										local frameLine = ProcessSpell(category, playerSpecID, playerSpecID,
											Enum.SpellBookSpellBank.Player, j)
										if frameLine then
											optionLines[frameLine.settingName] = frameLine
										end
									end
								end
							end
						end
					end

					for index = 1, #SettingsDB.validItems do
						local frameLine = CreateOptionLine(category, SettingsDB.validItems[index], playerSpecID, 0, -1)
						if frameLine then
							optionLines[frameLine.settingName] = frameLine
						end
					end

					LoadLayout(category, playerSpecID)
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

		local validCategories = addon:GetValidCategories(false)

		for index = 1, #validCategories do
			local name = validCategories[index]

			addItem(name)
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
end
