local addonName, addon = ...

local frameContainer
local radioAnchors = {}

local function RefreshIcon()
    if addon.assistedCombatIcon == nil then
        return
    end

    addon.assistedCombatIcon:RefreshPosition()
end

function addon:GetRotationHelperSettings(parent)
    frameContainer = CreateFrame("Frame", nil, parent)

    SettingsDB.bindingFontSize = SettingsDB.bindingFontSize or 12

    local showRotationHelper = addon:GetControlCheckbox(false, "Show Rotation Helper", frameContainer, function(control)
        SettingsDB.rotationHelperShow = control:GetChecked()
    end)
    showRotationHelper:SetPoint("TOPLEFT", frameContainer, "TOPLEFT", 10, -10)
    if SettingsDB.rotationHelperShow then
        showRotationHelper:SetChecked(true)
    else
        showRotationHelper:SetChecked(false)
    end

    local iconHeightLabel = addon:GetControlLabel(false, frameContainer, "Height:", 100)
    iconHeightLabel:SetPoint("TOPLEFT", showRotationHelper, "BOTTOMLEFT", 0, 0)

    local iconHeightInput = addon:GetControlInput(false, frameContainer, 40, function(control)
        SettingsDB.rotationHelperHeight = addon:GetNumberOrDefault(64, control:GetText())

        RefreshIcon()
    end)
    iconHeightInput:SetPoint("LEFT", iconHeightLabel, "RIGHT", 10, 0)
    iconHeightInput:SetText(addon:GetNumberOrDefault(64, SettingsDB.rotationHelperHeight))

    local iconWidthLabel = addon:GetControlLabel(false, frameContainer, "Width:", 30)
    iconWidthLabel:SetPoint("LEFT", iconHeightInput, "RIGHT", 10, 0)

    local iconWidthInput = addon:GetControlInput(false, frameContainer, 80, function(control)
        SettingsDB.rotationHelperWidth = addon:GetNumberOrDefault(64, control:GetText())

        RefreshIcon()
    end)
    iconWidthInput:SetPoint("LEFT", iconWidthLabel, "RIGHT", 10, 0)
    iconWidthInput:SetText(addon:GetNumberOrDefault(64, SettingsDB.rotationHelperWidth))

    local iconLeftLabel = addon:GetControlLabel(false, frameContainer, "X:", 100)
    iconLeftLabel:SetPoint("TOPLEFT", iconHeightLabel, "BOTTOMLEFT", 0, 0)

    local iconLeftInput = addon:GetControlInput(false, frameContainer, 40, function(control)
        SettingsDB.rotationHelperLeft = addon:GetNumberOrDefault(0, control:GetText())

        RefreshIcon()
    end)
    iconLeftInput:SetPoint("LEFT", iconLeftLabel, "RIGHT", 10, 0)
    iconLeftInput:SetText(addon:GetNumberOrDefault(0, SettingsDB.rotationHelperLeft))

    local iconTopLabel = addon:GetControlLabel(false, frameContainer, "Y:", 30)
    iconTopLabel:SetPoint("LEFT", iconLeftInput, "RIGHT", 10, 0)

    local iconTopInput = addon:GetControlInput(false, frameContainer, 80, function(control)
        SettingsDB.rotationHelperTop = addon:GetNumberOrDefault(0, control:GetText())

        RefreshIcon()
    end)
    iconTopInput:SetPoint("LEFT", iconTopLabel, "RIGHT", 10, 0)
    iconTopInput:SetText(addon:GetNumberOrDefault(0, SettingsDB.rotationHelperTop))

    local anchorLabel = addon:GetControlLabel(true, frameContainer, "Anchor:", 100)
    anchorLabel:SetPoint("TOPLEFT", iconLeftLabel, "BOTTOMLEFT", 0, 0)

    local anchorTopLeft = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Top Left", function(control)
        addon:ClearRadios(radioAnchors)
        control:SetChecked(true)

        SettingsDB.rotationHelperAnchor = "TOPLEFT"
    end)
    anchorTopLeft:SetPoint("LEFT", anchorLabel, "RIGHT", 10, 0)

    local anchorTop = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Top", function(control)
        addon:ClearRadios(radioAnchors)
        control:SetChecked(true)

        SettingsDB.rotationHelperAnchor = "TOP"
    end)
    anchorTop:SetPoint("LEFT", anchorTopLeft, "RIGHT", 110, 0)

    local anchorTopRight = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Top Right", function(control)
        addon:ClearRadios(radioAnchors)
        control:SetChecked(true)

        SettingsDB.rotationHelperAnchor = "TOPRIGHT"
    end)
    anchorTopRight:SetPoint("LEFT", anchorTop, "RIGHT", 110, 0)

    local anchorLeft = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Left", function(control)
        addon:ClearRadios(radioAnchors)
        control:SetChecked(true)

        SettingsDB.rotationHelperAnchor = "LEFT"
    end)
    anchorLeft:SetPoint("TOPLEFT", anchorTopLeft, "BOTTOMLEFT", 0, 0)

    local anchorCenter = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Center", function(control)
        addon:ClearRadios(radioAnchors)
        control:SetChecked(true)

        SettingsDB.rotationHelperAnchor = "CENTER"
    end)
    anchorCenter:SetPoint("LEFT", anchorLeft, "RIGHT", 110, 0)

    local anchorRight = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Right", function(control)
        addon:ClearRadios(radioAnchors)
        control:SetChecked(true)

        SettingsDB.rotationHelperAnchor = "RIGHT"
    end)
    anchorRight:SetPoint("LEFT", anchorCenter, "RIGHT", 110, 0)

    local anchorBottomLeft = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Bottom Left", function(control)
        addon:ClearRadios(radioAnchors)
        control:SetChecked(true)

        SettingsDB.rotationHelperAnchor = "BOTTOMLEFT"
    end)
    anchorBottomLeft:SetPoint("TOPLEFT", anchorLeft, "BOTTOMLEFT", 0, 0)

    local anchorBottom = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Bottom", function(control)
        addon:ClearRadios(radioAnchors)
        control:SetChecked(true)

        SettingsDB.rotationHelperAnchor = "BOTTOM"
    end)
    anchorBottom:SetPoint("LEFT", anchorBottomLeft, "RIGHT", 110, 0)

    local anchorBottomRight = addon:GetControlRadioButton(true, frameContainer, radioAnchors, "Bottom Right", function(control)
        addon:ClearRadios(radioAnchors)
        control:SetChecked(true)

        SettingsDB.rotationHelperAnchor = "BOTTOMRIGHT"
    end)
    anchorBottomRight:SetPoint("LEFT", anchorBottom, "RIGHT", 110, 0)

    if SettingsDB.rotationHelperAnchor == "TOPLEFT" then
        anchorTopLeft:SetChecked(true)
    elseif SettingsDB.rotationHelperAnchor == "TOPRIGHT" then
        anchorTopRight:SetChecked(true)
    elseif SettingsDB.rotationHelperAnchor == "TOP" then
        anchorTop:SetChecked(true)
    elseif SettingsDB.rotationHelperAnchor == "BOTTOMLEFT" then
        anchorBottomLeft:SetChecked(true)
    elseif SettingsDB.rotationHelperAnchor == "BOTTOMRIGHT" then
        anchorBottomRight:SetChecked(true)
    elseif SettingsDB.rotationHelperAnchor == "BOTTOM" then
        anchorBottom:SetChecked(true)
    elseif SettingsDB.rotationHelperAnchor == "LEFT" then
        anchorLeft:SetChecked(true)
    elseif SettingsDB.rotationHelperAnchor == "RIGHT" then
        anchorRight:SetChecked(true)
    else
        anchorCenter:SetChecked(true)
    end

    frameContainer:SetScript("OnShow", function(frame)
        if not addon.isSettingsShown then
            return
        end

        if SettingsDB.rotationHelperHeight and SettingsDB.rotationHelperHeight > 0 then
            iconHeightInput:SetText(SettingsDB.rotationHelperHeight)
        else
            iconHeightInput:SetText(64)
        end

        if SettingsDB.rotationHelperLeft and SettingsDB.rotationHelperLeft > 0 then
            iconLeftInput:SetText(SettingsDB.rotationHelperLeft)
        else
            iconLeftInput:SetText(0)
        end

        if SettingsDB.rotationHelperTop and SettingsDB.rotationHelperTop > 0 then
            iconTopInput:SetText(SettingsDB.rotationHelperTop)
        else
            iconTopInput:SetText(0)
        end

        if SettingsDB.rotationHelperWidth and SettingsDB.rotationHelperWidth > 0 then
            iconWidthInput:SetText(SettingsDB.rotationHelperWidth)
        else
            iconWidthInput:SetText(64)
        end
    end)

    return frameContainer
end
