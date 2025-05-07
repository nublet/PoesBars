local addonName, addon = ...

local optionLines = {}
local parentFrame
local radioAnchors = {}
local radioDisplay = {}
local radioOrientation = {}
local scrollFrame
local scrollFrameChild

local LSM = LibStub("LibSharedMedia-3.0")

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

	local yOffset = 0
	local seenSettingNames = {}

	for _, settingName in ipairs(CategoryOrderDB[category]) do
		if optionLines[settingName] then
			seenSettingNames[settingName] = true

			optionLines[settingName]:SetPoint("TOPLEFT", 10, yOffset)

			yOffset = yOffset - addon.settingsIconSize - 10
		end
	end

	for settingName, frameLine in pairs(optionLines) do
		if not seenSettingNames[settingName] then
			frameLine:SetPoint("TOPLEFT", 10, yOffset)

			table.insert(CategoryOrderDB[category], settingName)

			yOffset = yOffset - addon.settingsIconSize - 10
		end
	end
end

local function MoveSetting(category, playerSpecID, settingName, direction)
	local orderTable = CategoryOrderDB[category]
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

local function CreateOptionLine(category, iconDetail)
	local itemID = iconDetail.itemID or -1
	local playerSpecID = iconDetail.playerSpecID or -1
	local specID = iconDetail.specID or -1
	local spellID = iconDetail.spellID or -1

	if itemID <= 0 and spellID <= 0 then
		return nil
	end

	local font = LSM:Fetch("font", SettingsDB.fontName) or "Fonts\\FRIZQT__.TTF"
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
		textRank:SetFont(font, 10, "OUTLINE")
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

		frameIcon:SetScript("OnEnter", function(control)
			GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(spellID)
			GameTooltip:Show()
		end)
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

function addon:CreateSettingsSpells(mainCategory)
	parentFrame = CreateFrame("Frame", "SpellsSettingsFrame", UIParent)
	parentFrame.name = "Spell Categories"

	local categoryLabel = addon:GetControlLabel(false, parentFrame, "Category:", 100)
	categoryLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -10)

	local categoryDropdown = addon:GetControlDropdown(false, parentFrame, 120)
	categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", 10, 0)

	local categoryInput = addon:GetControlInput(false, parentFrame, 120)
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

					scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
					scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -10, 10)

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
						local displayWhen = settingsTable.displayWhen or "Always"
						local iconSize = settingsTable.iconSize or 64
						local iconSpacing = settingsTable.iconSpacing or 2
						local isClickable = settingsTable.isClickable or false
						local isVertical = settingsTable.isVertical or false
						local showOnCooldown = settingsTable.showOnCooldown or false
						local showWhenAvailable = settingsTable.showWhenAvailable or false
						local wrapAfter = settingsTable.wrapAfter or 0
						local x = settingsTable.x or 0
						local y = settingsTable.y or 0

						x = math.floor(x + 0.5)
						y = math.floor(y + 0.5)

						local categoryDelete = addon:GetControlButton(true, "Delete", parentFrame, 60, function(control)
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
							"Only Show On Cooldown or Aura Active", parentFrame)
						showOnCooldownCheckbox:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, -10)
						if showOnCooldown then
							showOnCooldownCheckbox:SetChecked(true)
						else
							showOnCooldownCheckbox:SetChecked(false)
						end

						local showWhenAvailableCheckbox = addon:GetControlCheckbox(true, "Only Show When Available",
							parentFrame)
						showWhenAvailableCheckbox:SetPoint("LEFT", showOnCooldownCheckbox, "RIGHT", 200, 0)
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

						local displayLabel = addon:GetControlLabel(true, parentFrame, "Display:", 100)
						displayLabel:SetPoint("TOPLEFT", showOnCooldownCheckbox, "BOTTOMLEFT", 0, -10)

						local displayAlways = addon:GetControlRadioButton(true, parentFrame, radioDisplay, "Always",
							function(control)
								addon:ClearRadios(radioDisplay)
								control:SetChecked(true)

								settingsTable.displayWhen = "Always"
							end)
						displayAlways:SetPoint("LEFT", displayLabel, "RIGHT", 10, 0)

						local displayInCombat = addon:GetControlRadioButton(true, parentFrame, radioDisplay,
							"In Combat",
							function(control)
								addon:ClearRadios(radioDisplay)
								control:SetChecked(true)

								settingsTable.displayWhen = "In Combat"
							end)
						displayInCombat:SetPoint("LEFT", displayAlways, "RIGHT", 110, 0)

						local displayOutOfCombat = addon:GetControlRadioButton(true, parentFrame, radioDisplay,
							"Out Of Combat",
							function(control)
								addon:ClearRadios(radioDisplay)
								control:SetChecked(true)

								settingsTable.displayWhen = "Out Of Combat"
							end)
						displayOutOfCombat:SetPoint("LEFT", displayInCombat, "RIGHT", 110, 0)

						if displayWhen == "" or displayWhen == "Always" then
							displayAlways:SetChecked(true)
							displayInCombat:SetChecked(false)
							displayOutOfCombat:SetChecked(false)
						elseif displayWhen == "In Combat" then
							displayAlways:SetChecked(false)
							displayInCombat:SetChecked(true)
							displayOutOfCombat:SetChecked(false)
						else
							displayAlways:SetChecked(false)
							displayInCombat:SetChecked(false)
							displayOutOfCombat:SetChecked(true)
						end

						local isClickableCheckbox = addon:GetControlCheckbox(true, "Make Clickable", parentFrame,
							function(control)
								settingsTable.isClickable = control:GetChecked()
							end)
						isClickableCheckbox:SetPoint("TOPLEFT", displayLabel, "BOTTOMLEFT", 0, -10)
						if isClickable then
							isClickableCheckbox:SetChecked(true)
						else
							isClickableCheckbox:SetChecked(false)
						end

						local iconSizeLabel = addon:GetControlLabel(true, parentFrame, "Icon Size:", 100)
						iconSizeLabel:SetPoint("TOPLEFT", isClickableCheckbox, "BOTTOMLEFT", 0, -10)

						local iconSizeInput = addon:GetControlInput(true, parentFrame, 40, function(control)
							settingsTable.iconSize = addon:GetValueNumber(control:GetText())
						end)
						iconSizeInput:SetNumeric(true)
						iconSizeInput:SetPoint("LEFT", iconSizeLabel, "RIGHT", 10, 0)
						iconSizeInput:SetText(iconSize)

						local positionXLabel = addon:GetControlLabel(true, parentFrame, "X:", 100)
						positionXLabel:SetPoint("LEFT", iconSizeInput, "RIGHT", 10, 0)

						local positionXInput = addon:GetControlInput(true, parentFrame, 40, function(control)
							settingsTable.x = addon:GetValueNumber(control:GetText())
						end)
						positionXInput:SetNumeric(true)
						positionXInput:SetPoint("LEFT", positionXLabel, "RIGHT", 10, 0)
						positionXInput:SetText(x)

						local iconSpacingLabel = addon:GetControlLabel(true, parentFrame, "Icon Gap:", 100)
						iconSpacingLabel:SetPoint("TOPLEFT", iconSizeLabel, "BOTTOMLEFT", 0, -10)

						local iconSpacingInput = addon:GetControlInput(true, parentFrame, 40, function(control)
							settingsTable.iconSpacing = addon:GetValueNumber(control:GetText())
						end)
						iconSpacingInput:SetNumeric(true)
						iconSpacingInput:SetPoint("LEFT", iconSpacingLabel, "RIGHT", 10, 0)
						iconSpacingInput:SetText(iconSpacing)

						local positionYLabel = addon:GetControlLabel(true, parentFrame, "Y:", 100)
						positionYLabel:SetPoint("LEFT", iconSpacingInput, "RIGHT", 10, 0)

						local positionYInput = addon:GetControlInput(true, parentFrame, 40, function(control)
							settingsTable.y = addon:GetValueNumber(control:GetText())
						end)
						positionYInput:SetNumeric(true)
						positionYInput:SetPoint("LEFT", positionYLabel, "RIGHT", 10, 0)
						positionYInput:SetText(y)

						local wrapAfterLabel = addon:GetControlLabel(true, parentFrame, "Wrap After:", 100)
						wrapAfterLabel:SetPoint("TOPLEFT", iconSpacingLabel, "BOTTOMLEFT", 0, -10)

						local wrapAfterInput = addon:GetControlInput(true, parentFrame, 40, function(control)
							settingsTable.wrapAfter = addon:GetValueNumber(control:GetText())
						end)
						wrapAfterInput:SetNumeric(true)
						wrapAfterInput:SetPoint("LEFT", wrapAfterLabel, "RIGHT", 10, 0)
						wrapAfterInput:SetText(wrapAfter)

						local orientationLabel = addon:GetControlLabel(true, parentFrame, "Orientation:", 100)
						orientationLabel:SetPoint("TOPLEFT", wrapAfterLabel, "BOTTOMLEFT", 0, -10)

						local orientationHorizontal = addon:GetControlRadioButton(true, parentFrame, radioOrientation,
							"Horizontal",
							function(control)
								addon:ClearRadios(radioOrientation)
								control:SetChecked(true)

								settingsTable.isVertical = false
							end)
						orientationHorizontal:SetPoint("LEFT", orientationLabel, "RIGHT", 10, 0)

						local orientationVertical = addon:GetControlRadioButton(true, parentFrame, radioOrientation,
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

						local anchorLabel = addon:GetControlLabel(true, parentFrame, "Anchor:", 100)
						anchorLabel:SetPoint("TOPLEFT", orientationLabel, "BOTTOMLEFT", 0, -10)

						local anchorTopLeft = addon:GetControlRadioButton(true, parentFrame, radioAnchors, "Top Left",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "TOPLEFT"
							end)
						anchorTopLeft:SetPoint("LEFT", anchorLabel, "RIGHT", 10, 0)

						local anchorTop = addon:GetControlRadioButton(true, parentFrame, radioAnchors, "Top",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "TOP"
							end)
						anchorTop:SetPoint("LEFT", anchorTopLeft, "RIGHT", 110, 0)

						local anchorTopRight = addon:GetControlRadioButton(true, parentFrame, radioAnchors, "Top Right",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "TOPRIGHT"
							end)
						anchorTopRight:SetPoint("LEFT", anchorTop, "RIGHT", 110, 0)

						local anchorLeft = addon:GetControlRadioButton(true, parentFrame, radioAnchors, "Left",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "LEFT"
							end)
						anchorLeft:SetPoint("TOPLEFT", anchorTopLeft, "BOTTOMLEFT", 0, -10)

						local anchorCenter = addon:GetControlRadioButton(true, parentFrame, radioAnchors,
							"Center",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "CENTER"
							end)
						anchorCenter:SetPoint("LEFT", anchorLeft, "RIGHT", 110, 0)

						local anchorRight = addon:GetControlRadioButton(true, parentFrame, radioAnchors, "Right",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "RIGHT"
							end)
						anchorRight:SetPoint("LEFT", anchorCenter, "RIGHT", 110, 0)

						local anchorBottomLeft = addon:GetControlRadioButton(true, parentFrame, radioAnchors,
							"Bottom Left",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "BOTTOMLEFT"
							end)
						anchorBottomLeft:SetPoint("TOPLEFT", anchorLeft, "BOTTOMLEFT", 0, -10)

						local anchorBottom = addon:GetControlRadioButton(true, parentFrame, radioAnchors, "Bottom",
							function(control)
								addon:ClearRadios(radioAnchors)
								control:SetChecked(true)

								settingsTable.anchor = "BOTTOM"
							end)
						anchorBottom:SetPoint("LEFT", anchorBottomLeft, "RIGHT", 110, 0)

						local anchorBottomRight = addon:GetControlRadioButton(true, parentFrame, radioAnchors,
							"Bottom Right",
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
						scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -10, 10)
					end

					local tableIconDetails = addon:GetIconDetails()

					if tableIconDetails and next(tableIconDetails) ~= nil then
						for i = 1, #tableIconDetails do
							local iconDetail = tableIconDetails[i]

							local frameLine = CreateOptionLine(category, iconDetail)
							if frameLine then
								optionLines[frameLine.settingName] = frameLine
							end
						end
					end

					local currentSpec = GetSpecialization()
					if currentSpec then
						local playerSpecID = GetSpecializationInfo(currentSpec)
						if playerSpecID then
							LoadLayout(category, playerSpecID)
						end
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

	parentFrame:SetScript("OnHide", function(frame)
		addon.isLoaded = false

		addon:Debounce("CreateIcons", 1, function()
			addon:CreateIcons()
			addon.isLoaded = true
		end)
	end)

	local subCategory = Settings.RegisterCanvasLayoutSubcategory(mainCategory, parentFrame, parentFrame.name);
	Settings.RegisterAddOnCategory(subCategory);
	return subCategory:GetID()
end
