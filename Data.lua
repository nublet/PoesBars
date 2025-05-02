local addonName, addon = ...
addon.ignored          = "Ignored"
addon.isLoaded         = false
addon.settingsControls = {}
addon.settingsIconSize = 36
addon.unknown          = "Unknown"

addon.buffOverrides    = {
    [342245] = 342246, -- Alter Time
    [414660] = 11426,  -- Mass Barrier
    [53600] = 132403,  -- Shield of the Righteous
}

addon.spellOverrides   = {
    [342245] = 342246, -- Alter Time
    [414660] = 11426,  -- Mass Barrier
}
