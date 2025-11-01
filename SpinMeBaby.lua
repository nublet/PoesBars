local addonName, addon = ...

local fireworksMinimum = 1
local fireworksMaximum = 25
local frameResult
local frameSpinner
local rollValue = -1
local triggerWords = { "spin", "games begin", "roll", "feeling lucky", "dizzy" }

local rollValuesFirst = {}
rollValuesFirst[1] = "Playing for envelope "
rollValuesFirst[3] = "Playing for envelope "
rollValuesFirst[7] = "Playing for envelope "
rollValuesFirst[9] = "Playing for envelope "
rollValuesFirst[11] = "Playing for envelope "
rollValuesFirst[12] = "Playing for envelope "
rollValuesFirst[13] = "Playing for envelope "
rollValuesFirst[14] = "Playing for envelope "
rollValuesFirst[17] = "Playing for envelope "
rollValuesFirst[18] = "Playing for envelope "
rollValuesFirst[19] = "Playing for envelope "
rollValuesFirst[22] = "Playing for envelope "
rollValuesFirst[23] = "Playing for envelope "
rollValuesFirst[25] = "Playing for envelope "
rollValuesFirst[27] = "Playing for envelope "
rollValuesFirst[28] = "Playing for envelope "
rollValuesFirst[30] = "Playing for envelope "
rollValuesFirst[31] = "Playing for envelope "
rollValuesFirst[32] = "Playing for envelope "
rollValuesFirst[34] = "Playing for envelope "
rollValuesFirst[35] = "Playing for envelope "
rollValuesFirst[37] = "Playing for envelope "
rollValuesFirst[40] = "Playing for envelope "
rollValuesFirst[41] = "Playing for envelope "
rollValuesFirst[46] = "Playing for envelope "
rollValuesFirst[47] = "Playing for envelope "
rollValuesFirst[48] = "Playing for envelope "
rollValuesFirst[49] = "Playing for envelope "
rollValuesFirst[52] = "Playing for envelope "
rollValuesFirst[53] = "Playing for envelope "
rollValuesFirst[55] = "Playing for envelope "
rollValuesFirst[56] = "Playing for envelope "
rollValuesFirst[58] = "Playing for envelope "
rollValuesFirst[60] = "Playing for envelope "
rollValuesFirst[62] = "Playing for envelope "
rollValuesFirst[66] = "Playing for envelope "
rollValuesFirst[69] = "Playing for envelope "
rollValuesFirst[73] = "Playing for envelope "
rollValuesFirst[77] = "Playing for envelope "
rollValuesFirst[79] = "Playing for envelope "
rollValuesFirst[84] = "Playing for envelope "
rollValuesFirst[85] = "Playing for envelope "
rollValuesFirst[87] = "Playing for envelope "
rollValuesFirst[88] = "Playing for envelope "
rollValuesFirst[89] = "Playing for envelope "
rollValuesFirst[90] = "Playing for envelope "
rollValuesFirst[94] = "Playing for envelope "
rollValuesFirst[95] = "Playing for envelope "
rollValuesFirst[97] = "Playing for envelope "
rollValuesFirst[101] = "Playing for envelope "
rollValuesFirst[102] = "Playing for envelope "
rollValuesFirst[103] = "Playing for envelope "
rollValuesFirst[104] = "Playing for envelope "
rollValuesFirst[106] = "Playing for envelope "
rollValuesFirst[109] = "Playing for envelope "
rollValuesFirst[111] = "Playing for envelope "
rollValuesFirst[113] = "Playing for envelope "
rollValuesFirst[115] = "Playing for envelope "
rollValuesFirst[116] = "Playing for envelope "
rollValuesFirst[117] = "Playing for envelope "
rollValuesFirst[120] = "Playing for envelope "
rollValuesFirst[121] = "Playing for envelope "
rollValuesFirst[122] = "Playing for envelope "
rollValuesFirst[123] = "Playing for envelope "
rollValuesFirst[125] = "Playing for envelope "
rollValuesFirst[126] = "Playing for envelope "
rollValuesFirst[128] = "Playing for envelope "
rollValuesFirst[129] = "Playing for envelope "
rollValuesFirst[130] = "Playing for envelope "

local rollValuesSecond = {}
rollValuesSecond[1] = "Win a duel"
rollValuesSecond[3] = "Name 8 Shit doggos"
rollValuesSecond[7] = "Locate or display something duckish in game"
rollValuesSecond[9] = "Death roll 10000"
rollValuesSecond[11] = "Where is trustfall?"
rollValuesSecond[12] = "Death roll 10000"
rollValuesSecond[13] = "Death roll 10000"
rollValuesSecond[14] = "Find and equip something blue"
rollValuesSecond[17] = "Death roll 10000"
rollValuesSecond[18] = "Death roll 10000"
rollValuesSecond[19] = "Death roll 10000"
rollValuesSecond[22] = "Complete a run with only 1 spell bound (not one button macro!)"
rollValuesSecond[23] = "Why are you not a reliable random fact boi?"
rollValuesSecond[25] = "Don't GTFO - stand in all the shinies for a run"
rollValuesSecond[27] = "Win a duel"
rollValuesSecond[28] = "Death roll 10000"
rollValuesSecond[30] = "Retail raid - put on everything that drops, regardless of armour type / usefulness"
rollValuesSecond[31] = "Find a crunchy food"
rollValuesSecond[32] = "Find and equip a plush toy or action figure."
rollValuesSecond[34] = "Find and equip something you'd rather stream didn't see"
rollValuesSecond[35] = "Win a mount off"
rollValuesSecond[37] = "Tank remix using only ranged attacks"
rollValuesSecond[40] = "Win a mount off"
rollValuesSecond[41] = "Complete a run with no addons & UI hidden"
rollValuesSecond[46] = "Win a mount off"
rollValuesSecond[47] = "Why are frogs important?"
rollValuesSecond[48] = "Death roll 10000"
rollValuesSecond[49] = "Find and equip something you’ve owned for more than 10 years."
rollValuesSecond[52] = "Win a duel"
rollValuesSecond[53] = "Win a duel"
rollValuesSecond[55] = "Why should you buy a 5080?"
rollValuesSecond[56] = "Win a mount off"
rollValuesSecond[58] = "Find and equip something that lights up"
rollValuesSecond[60] = "Shuffle 10 important keybinds for a run"
rollValuesSecond[62] = "Death roll 10000"
rollValuesSecond[66] = "Swap W/S and A/D for a run"
rollValuesSecond[69] = "Find and equip something with stripes"
rollValuesSecond[73] = "Find and equip a hair accessory"
rollValuesSecond[77] = "What do you need to explain complex raid tactics?"
rollValuesSecond[79] = "Why do swapblasters suck?"
rollValuesSecond[84] = "Find something that smells weird"
rollValuesSecond[85] = "Swap your interrupt and defensive keybinds for a run."
rollValuesSecond[87] = "Win a mount off"
rollValuesSecond[88] = "How many interrupts can you get?"
rollValuesSecond[89] = "Death roll 10000"
rollValuesSecond[90] = "Complete a run zoomed in to first-person mode."
rollValuesSecond[94] = "Find & equip something you can wear as a crown"
rollValuesSecond[95] = "Find and equip something that could pass as Wow loot"
rollValuesSecond[97] = "Death roll 10000"
rollValuesSecond[101] = "Win a duel"
rollValuesSecond[102] = "Find & equip something belonging to Claire"
rollValuesSecond[103] = "Find and equip something that’s clearly useless."
rollValuesSecond[104] = "Win a mount off"
rollValuesSecond[106] = "Find and equip something purple"
rollValuesSecond[109] = "Find and equip the strangest thing on your keyboard or desk"
rollValuesSecond[111] = "Why is Ben late for keys?"
rollValuesSecond[113] = "Win a mount off"
rollValuesSecond[115] = "Win a duel"
rollValuesSecond[116] = "Win a mount off"
rollValuesSecond[117] = "Win a mount off"
rollValuesSecond[120] = "Death roll 10000"
rollValuesSecond[121] = "Win a mount off"
rollValuesSecond[122] = "Death roll 10000"
rollValuesSecond[123] = "How do play games when your widescreen resolution is set wrong?"
rollValuesSecond[125] = "How do you make Bon rage quit?"
rollValuesSecond[126] = "Death roll 10000"
rollValuesSecond[128] = "Invert your mouse Y-axis in settings for a run."
rollValuesSecond[129] = "Where can you find a Coop de gracie"
rollValuesSecond[130] = "What takes 7-10 Business days?"

local LSM = LibStub("LibSharedMedia-3.0")
local font = LSM:Fetch("font", "Naowh") or "Fonts\\FRIZQT__.TTF"

local function CreateFirework()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(32, 32)
	frame:SetPoint("CENTER", math.random(-1720, 1720), math.random(-720, 720))

	local tex = frame:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints()
	tex:SetTexture("Interface\\Cooldown\\star4") -- A decent built-in starburst texture
	tex:SetVertexColor(math.random(), math.random(), math.random())
	tex:SetBlendMode("ADD")

	-- Animation group
	local ag = tex:CreateAnimationGroup()
	local scale = ag:CreateAnimation("Scale")
	scale:SetScale(math.random(5, 20), math.random(5, 20))
	scale:SetDuration(3)
	scale:SetSmoothing("OUT")

	local fade = ag:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0)
	fade:SetStartDelay(0.5)
	fade:SetDuration(6)
	fade:SetSmoothing("IN")

	ag:SetScript("OnFinished", function()
		frame:Hide()
		frame:SetParent(nil)
	end)

	ag:Play()
end

local function PoesWhisperFilter(self, event, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)
	if not text then
		return
	end

	text = addon:NormalizeText(text)

	rollValue = addon:GetNumberOrDefault(-1, string.match(text, "^add back (%d+)$"))
	if rollValue and rollValue > 0 then
		SpinMeBabyDB[rollValue] = false

		return true
	end

	rollValue = addon:GetNumberOrDefault(-1, string.match(text, "^force (%d+)$"))
	if rollValue and rollValue > 0 then
		SpinMeBabyDB[rollValue] = false
		frameSpinner:Show()

		return true
	end

	rollValue = -1

	for _, word in ipairs(triggerWords) do
		word = addon:NormalizeText(word)
		if text:find(word) then
			addon:Debounce("showSpinner", 1, function()
				frameSpinner:Show()
			end)

			return true
		end
	end
end

function addon:InitializeSpinner()
	SpinMeBabyDB = SpinMeBabyDB or {}

	frameResult = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
	frameResult:EnableKeyboard(false)
	frameResult:EnableMouse(false)
	frameResult:EnableMouseWheel(false)
	frameResult:SetFrameStrata("DIALOG")
	frameResult:SetPoint("CENTER", 0, 0)
	frameResult:SetSize(900, 900)

	frameResult.textCenter = frameResult:CreateFontString(nil, "OVERLAY")
	frameResult.textCenter:SetAllPoints(frameResult)
	frameResult.textCenter:SetFont(font, 60, "OUTLINE")
	frameResult.textCenter:SetJustifyH("CENTER")
	frameResult.textCenter:SetNonSpaceWrap(false)
	frameResult.textCenter:SetShadowColor(0, 0, 0, 1)
	frameResult.textCenter:SetShadowOffset(0, 0)
	frameResult.textCenter:SetWidth(frameResult:GetWidth())
	frameResult.textCenter:SetWordWrap(true)

	frameSpinner = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
	frameSpinner:EnableKeyboard(false)
	frameSpinner:EnableMouse(true)
	frameSpinner:EnableMouseWheel(false)
	frameSpinner:RegisterEvent("CHAT_MSG_BN_WHISPER")
	frameSpinner:RegisterEvent("CHAT_MSG_WHISPER")
	frameSpinner:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
	frameSpinner:SetFrameStrata("DIALOG")
	frameSpinner:SetHitRectInsets(0, 0, 0, 0)
	frameSpinner:SetPoint("CENTER", 0, 0)
	frameSpinner:SetPropagateKeyboardInput(true)
	frameSpinner:SetSize(900, 900)

	frameSpinner:SetScript("OnClick", function()
		frameSpinner:Hide()
		SaveView(1)
		MoveViewRightStart(8)

		C_Timer.After(4, function()
			MoveViewRightStop()
			SetView(1)

			while true do
				if rollValue and rollValue > 0 then
				else
					rollValue = math.random(1, 130)
				end

				local isUsed = SpinMeBabyDB[rollValue]

				if isUsed and isUsed == true then
				else
					break
				end
			end

			SpinMeBabyDB[rollValue] = true

			if rollValuesFirst[rollValue] then
				frameResult.textCenter:SetText(rollValuesFirst[rollValue] .. rollValue .. "\n" .. rollValuesSecond[rollValue])
			else
				frameResult.textCenter:SetText("AMAGAD instant win! Open envelope " .. rollValue .. ".")
			end

			C_Timer.After(1, function()
				for i = fireworksMinimum, fireworksMaximum do
					C_Timer.After(math.random() * 0.5, CreateFirework)
				end
			end)

			C_Timer.After(3, function()
				for i = fireworksMinimum, fireworksMaximum do
					C_Timer.After(math.random() * 0.5, CreateFirework)
				end
			end)

			C_Timer.After(6, function()
				for i = fireworksMinimum, fireworksMaximum do
					C_Timer.After(math.random() * 0.5, CreateFirework)
				end
			end)

			C_Timer.After(9, function()
				for i = fireworksMinimum, fireworksMaximum do
					C_Timer.After(math.random() * 0.5, CreateFirework)
				end
			end)

			C_Timer.After(10, function()
				frameResult:Hide()
			end)

			frameResult:Show()
		end)
	end)

	frameSpinner.textBottom = frameSpinner:CreateFontString(nil, "OVERLAY")
	frameSpinner.textBottom:SetFont(font, 60, "OUTLINE")
	frameSpinner.textBottom:SetPoint("TOP", frameSpinner, "BOTTOM", 0, 0)
	frameSpinner.textBottom:SetShadowColor(0, 0, 0, 1)
	frameSpinner.textBottom:SetShadowOffset(0, 0)
	frameSpinner.textBottom:SetText("^ Click the Spinner ^")
	frameSpinner.textBottom:SetTextColor(1, 1, 1, 1)

	frameSpinner.textTop = frameSpinner:CreateFontString(nil, "OVERLAY")
	frameSpinner.textTop:SetFont(font, 80, "OUTLINE")
	frameSpinner.textTop:SetPoint("BOTTOM", frameSpinner, "TOP", 0, 0)
	frameSpinner.textTop:SetShadowColor(0, 0, 0, 1)
	frameSpinner.textTop:SetShadowOffset(0, 0)
	frameSpinner.textTop:SetText("Winner Winner")
	frameSpinner.textTop:SetTextColor(1, 1, 1, 1)

	frameSpinner.textureIcon = frameSpinner:CreateTexture(nil, "ARTWORK")
	frameSpinner.textureIcon:SetAllPoints(frameSpinner)
	frameSpinner.textureIcon:SetTexture(132369)

	frameSpinner:Hide()

	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", PoesWhisperFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", PoesWhisperFilter)
end
