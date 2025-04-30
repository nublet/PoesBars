local addonName, addon = ...

addon.buffOverrides = {
    [342245] = 342246, -- Alter Time
    [414660] = 11426,  -- Mass Barrier
}

addon.forcedSpellsBySpellID = {
    [66] = {
        [21321332] = 427453, -- Light's Guidance
    },
}

addon.forcedSpellsByHeroTree = {
    [66] = {
        [21321332] = {
            427453, -- Light's Guidance
        },
    },
}

addon.spellOverrides = {
    [342245] = 342246, -- Alter Time
    [414660] = 11426,  -- Mass Barrier
}