local addonName, addon = ...

local frameDialog
local frameTabs = {
    { name = "General",         callback = function(parent) return addon:GetGeneralSettings(parent) end },
    { name = "Categories",      callback = function(parent) return addon:GetCategoriesSettings(parent) end },
    { name = "Forced Items",    callback = function(parent) return addon:GetForcedItemsSettings(parent) end },
    { name = "Forced Spells",   callback = function(parent) return addon:GetForcedSpellsSettings(parent) end },
    { name = "Rotation Helper", callback = function(parent) return addon:GetRotationHelperSettings(parent) end },
}

function addon:ToggleSettingsDialog()
    if frameDialog then
        frameDialog:SetShown(not frameDialog:IsVisible())
        return
    end

    local frame = CreateFrame("Frame", addonName .. "SettingsDialog", UIParent, "ButtonFrameTemplate")
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetPoint("CENTER")
    frame:SetSize(700, 700)
    frame:SetTitle("Customise " .. addonName)
    frame:SetToplevel(true)
    frame:Raise()
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
        frame:SetUserPlaced(false)
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        frame:SetUserPlaced(false)
    end)
    frame:SetScript("OnMouseWheel", function() end)

    table.insert(UISpecialFrames, frame:GetName())
    ButtonFrameTemplate_HidePortrait(frame)
    ButtonFrameTemplate_HideButtonBar(frame)
    frame.Inset:Hide()

    local lastTab
    local tabButtons = {}
    local tabContainers = {}

    for _, setup in ipairs(frameTabs) do
        local tabButton = CreateFrame("Button", nil, frame, "PanelTopTabButtonTemplate")
        local tabContainer = setup.callback(frame)

        tabButton:SetText(setup.name)
        tabButton:SetScript("OnClick", function()
            for _, c in ipairs(tabContainers) do
                PanelTemplates_DeselectTab(c.tabButton)
                c:Hide()
            end
            PanelTemplates_SelectTab(tabButton)
            tabContainer:Show()
        end)
        tabButton:SetScript("OnShow", function(tabFrame)
            PanelTemplates_TabResize(tabFrame, 15, nil, 10)
            PanelTemplates_DeselectTab(tabFrame)
        end)
        tabButton:GetScript("OnShow")(tabButton)

        if lastTab then
            tabButton:SetPoint("LEFT", lastTab, "RIGHT", 5, 0)
        else
            tabButton:SetPoint("TOPLEFT", 10, -25)
        end
        lastTab = tabButton

        tabContainer:SetPoint("TOPLEFT", 5, -65)
        tabContainer:SetPoint("BOTTOMRIGHT")
        tabContainer.tabButton = tabButton
        tabContainer:Hide()

        table.insert(tabButtons, tabButton)
        table.insert(tabContainers, tabContainer)
    end

    frame.tabButtons = tabButtons
    PanelTemplates_SetNumTabs(frame, #frame.tabButtons)
    tabContainers[1].tabButton:Click()

    frame:SetScript("OnHide", function()
        if not addon.isSettingsShown then
            return
        end

        addon.isLoaded = false
        addon.isSettingsShown = false

        CategoryFrame:Create()
    end)
    frame:SetScript("OnShow", function()
        local shownContainer = FindValueInTableIf(tabContainers, function(c) return c:IsShown() end)
        if shownContainer then
            PanelTemplates_SetTab(frame, tIndexOf(tabContainers, shownContainer))
        end
    end)
end
