local addonName, addon = ...

function addon:InitializeSettingsDialog()
    local optionsFrame = CreateFrame("Frame")

    local instructions = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge3")
    instructions:SetPoint("CENTER", optionsFrame)
    instructions:SetText(WHITE_FONT_COLOR:WrapTextInColorCode("Access options with /pbc"))

    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    local versionText = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    versionText:SetPoint("CENTER", optionsFrame, 0, 28)
    versionText:SetText(WHITE_FONT_COLOR:WrapTextInColorCode("Version: " .. version))

    local header = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge3")
    header:SetScale(3)
    header:SetPoint("CENTER", optionsFrame, 0, 30)
    header:SetText(LINK_FONT_COLOR:WrapTextInColorCode(addonName))

    local template = "SharedButtonLargeTemplate"
    if not C_XMLUtil.GetTemplateInfo(template) then
        template = "UIPanelDynamicResizeButtonTemplate"
    end
    local button = CreateFrame("Button", nil, optionsFrame, template)
    button:SetText("Open Options")
    DynamicResizeButton_Resize(button)
    button:SetPoint("CENTER", optionsFrame, 0, -30)
    button:SetScale(2)
    button:SetScript("OnClick", function()
        addon.isSettingsShown = true

        addon:ToggleSettingsDialog()
    end)

    optionsFrame.OnCommit = function() end
    optionsFrame.OnDefault = function() end
    optionsFrame.OnRefresh = function() end

    local category = Settings.RegisterCanvasLayoutCategory(optionsFrame, addonName)
    category.ID = addonName
    Settings.RegisterAddOnCategory(category)
end
