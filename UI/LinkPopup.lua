local addonName, addon = ...

-- A small window that offers a web address to copy. WoW can't open a link or write to the clipboard, so the
-- address sits selected in a box and the player presses Ctrl+C (the window closes when they do).
--
-- All styling goes through addon.Theme. The frame is built on first use, never at load.

local LinkPopup = {}
addon.LinkPopup = LinkPopup

local L = addon.L
local Theme = addon.Theme

local WIDTH, HEIGHT, PAD = 360, 170, 16

local ui                                    -- the widgets, once built
local onDismiss                             -- the caller's "don't show this again", for the open window

local function build()
    ui = {}
    LinkPopup.widgets = ui                  -- for tests
    local frame = Theme:Panel(UIParent, "MapzerothRebuildLinkPopup")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")        -- above the map and our panel
    frame:EnableMouse(true)
    frame:Hide()
    ui.frame = frame
    -- Escape closes it, like the game's own dialogs.
    if UISpecialFrames then table.insert(UISpecialFrames, "MapzerothRebuildLinkPopup") end

    ui.title = Theme:Text(frame, "title")
    ui.title:SetPoint("TOPLEFT", PAD, -PAD)
    ui.title:SetWidth(WIDTH - 2 * PAD)
    ui.title:SetWordWrap(false)

    ui.prompt = Theme:Text(frame, "body")
    ui.prompt:SetPoint("TOPLEFT", PAD, -(PAD + 26))
    ui.prompt:SetWidth(WIDTH - 2 * PAD)
    ui.prompt:SetWordWrap(true)
    ui.prompt:SetText(L["SLLCM_COPY"])

    ui.box = Theme:EditBox(frame, WIDTH - 2 * PAD, 28)
    ui.box:SetPoint("TOPLEFT", PAD, -(PAD + 76))
    ui.box:SetScript("OnEscapePressed", function() LinkPopup:Hide() end)
    -- The address can be selected and copied, not edited.
    ui.box:SetScript("OnTextChanged", function(self, byUser)
        if byUser and ui.url then
            self:SetText(ui.url)
            self:HighlightText()
        end
    end)
    ui.box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    ui.box:SetScript("OnKeyUp", function(_, key)
        if key == "C" and IsControlKeyDown and IsControlKeyDown() then LinkPopup:Hide() end
    end)

    ui.hide = Theme:Button(frame, L["SLLCM_HIDE"], 160, 24)
    ui.hide:SetPoint("BOTTOMLEFT", PAD, PAD)
    ui.hide:SetScript("OnClick", function()
        local callback = onDismiss
        LinkPopup:Hide()
        if callback then callback() end
    end)

    ui.close = Theme:Button(frame, L["SLLCM_CLOSE"], 90, 24, true)
    ui.close:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    ui.close:SetScript("OnClick", function() LinkPopup:Hide() end)
end

-- Open the window with `url` selected. title: its heading. dismiss: if given, a button ("Don't show this
-- again") runs it and closes the window.
function LinkPopup:Show(title, url, dismiss)
    if not ui then build() end
    ui.url, onDismiss = url, dismiss
    ui.title:SetText(title)
    ui.box:SetText(url)
    ui.hide:SetShown(dismiss ~= nil)
    ui.frame:Show()
    ui.box:SetFocus()
    ui.box:HighlightText()
end

function LinkPopup:Hide()
    if ui then
        ui.box:ClearFocus()
        ui.frame:Hide()
    end
end

function LinkPopup:IsShown()
    return ui ~= nil and ui.frame:IsShown()
end
