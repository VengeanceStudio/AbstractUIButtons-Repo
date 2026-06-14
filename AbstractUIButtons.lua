local AddonName = "AbstractUIButtons"
local Container
local SettingsCategory -- Stores the category object for modern API
local MasqueGroup 

-- 1. Default Settings
local function GetDefaultSettings()
    return {
        locked = false, hideBG = false, scale = 1.0, fontSize = 16, btnWidth = 30,
        pos = {"CENTER", 0, 0},
        trayColor = {0, 0, 0, 0.7}, btnColor = {0.1, 0.1, 0.1, 0.9}, textColor = {1, 1, 1, 1},
        isClassic = false
    }
end

-- 2. DB Logic
local function GetCharKey() return UnitName("player") .. "-" .. GetRealmName() end
local function InitDB()
    AbstractUIButtonsDB = AbstractUIButtonsDB or {}
    AbstractUIButtonsDB.profiles = AbstractUIButtonsDB.profiles or { ["Default"] = GetDefaultSettings() }
    AbstractUIButtonsDB.charToProfile = AbstractUIButtonsDB.charToProfile or {}
    AbstractUIButtonsDB.customStyles = AbstractUIButtonsDB.customStyles or {}
    for _, profile in pairs(AbstractUIButtonsDB.profiles) do
        if profile.btnWidth == nil then profile.btnWidth = 30 end
    end
    local charKey = GetCharKey()
    if not AbstractUIButtonsDB.charToProfile[charKey] then AbstractUIButtonsDB.charToProfile[charKey] = "Default" end
end

local function GetCfg()
    local charKey = GetCharKey()
    local profileName = AbstractUIButtonsDB.charToProfile[charKey] or "Default"
    return AbstractUIButtonsDB.profiles[profileName] or AbstractUIButtonsDB.profiles["Default"]
end

-- 3. Update Appearance
local function UpdateAppearance()
    if not Container then return end
    local cfg = GetCfg()
    Container:SetScale(cfg.scale or 1.0)
    Container:ClearAllPoints()
    Container:SetPoint(cfg.pos[1], cfg.pos[2], cfg.pos[3])
    
    local width = cfg.btnWidth or 30
    local totalWidth = (width * 4) + 16
    Container:SetSize(totalWidth, 36)

    if MasqueGroup or cfg.hideBG then
        Container.bg:SetAlpha(0)
    else
        Container.bg:SetAlpha(1)
        Container.bg:SetColorTexture(unpack(cfg.trayColor))
    end
    
    local function StyleBtn(btn, idx)
        if not btn then return end
        btn:SetSize(width, 30)
        btn:SetPoint("LEFT", 3 + ((idx-1) * (width + 3)), 0)
        if btn.text then
            btn.text:SetFont("Fonts\\FRIZQT__.TTF", cfg.fontSize or 16, "OUTLINE")
            btn.text:SetTextColor(unpack(cfg.textColor))
        end
        if MasqueGroup then
            if btn.bg then btn.bg:SetTexture(nil) end
            if btn:GetHighlightTexture() then btn:GetHighlightTexture():SetTexture(nil) end
            return
        end
        if cfg.isClassic then
            btn.bg:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
            btn.bg:SetTexCoord(0, 0.625, 0, 0.6875)
            btn:GetHighlightTexture():SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
            btn:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)
            btn.bg:SetVertexColor(1, 1, 1, 1)
        else
            btn.bg:SetTexture(nil); btn.bg:SetColorTexture(unpack(cfg.btnColor))
            btn:GetHighlightTexture():SetTexture(nil); btn:GetHighlightTexture():SetColorTexture(1, 1, 1, 0.2)
        end
    end
    StyleBtn(_G["MDSecureBtn_1"], 1); StyleBtn(_G["MDSecureBtn_2"], 2)
    StyleBtn(_G["MDSecureBtn_3"], 3); StyleBtn(_G["MDNormalBtn_A"], 4)
end

-- 4. Options UI and Opening Logic
local function OpenOptions()
    if InCombatLockdown() then return end
    
    -- Modern WoW (10.0+) requires the Numeric ID, not the name
    if Settings and Settings.OpenToCategory then
        if SettingsCategory then
            Settings.OpenToCategory(SettingsCategory:GetID())
        else
            -- Fallback: Search for ID if variable is somehow missing
            for _, category in ipairs(Settings.GetCategoryList()) do
                if category.name == "Abstract UI Buttons" then
                    Settings.OpenToCategory(category:GetID())
                    return
                end
            end
        end
    -- Legacy WoW
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("Abstract UI Buttons")
    end
end

local function OpenColorPicker(cfgVar, callback)
    local cfg = GetCfg()
    local r, g, b, a = unpack(cfg[cfgVar])
    local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        local newA = ColorPickerFrame:GetColorAlpha()
        cfg[cfgVar] = {newR, newG, newB, newA}; callback()
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        swatchFunc = OnColorChanged, opacityFunc = OnColorChanged,
        cancelFunc = function() cfg[cfgVar] = {r, g, b, a}; callback() end,
        hasOpacity = true, opacity = a, r = r, g = g, b = b
    })
end

local function RegisterOptions()
    local panel = CreateFrame("Frame", "AbstractOptionsPanel", UIParent)
    panel.name = "Abstract UI Buttons"
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16); title:SetText("Abstract UI Buttons (v12.0.51)")

    local visualTab = CreateFrame("Frame", nil, panel); visualTab:SetAllPoints()
    local profileTab = CreateFrame("Frame", nil, panel); profileTab:SetAllPoints(); profileTab:Hide()
    local tabs = {}

    local function ShowTab(tabID)
        visualTab:SetShown(tabID == 1); profileTab:SetShown(tabID == 2)
        for id, btn in ipairs(tabs) do
            btn.text:SetTextColor(id == tabID and 1 or 0.6, id == tabID and 0.82 or 0.6, id == tabID and 0 or 0.6)
        end
    end

    local function CreateTabBtn(id, text, xOff)
        local btn = CreateFrame("Button", nil, panel, "BackdropTemplate")
        btn:SetSize(120, 25); btn:SetPoint("TOPLEFT", 16 + xOff, -45)
        btn:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        btn:SetBackdropColor(0,0,0,0.5); btn:SetBackdropBorderColor(0.5,0.5,0.5,0.5)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); btn.text:SetPoint("CENTER"); btn.text:SetText(text)
        btn:SetScript("OnClick", function() ShowTab(id) end); tabs[id] = btn; return btn
    end

    CreateTabBtn(1, "Visual Settings", 0); CreateTabBtn(2, "Profiles", 125); ShowTab(1)

    -- Visual Tab
    local function CreateCheck(label, var, yOff)
        local cb = CreateFrame("CheckButton", nil, visualTab, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, yOff); local l = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        l:SetPoint("LEFT", cb, "RIGHT", 8, 0); l:SetText(label)
        cb:SetChecked(GetCfg()[var]); cb:SetScript("OnClick", function(self) GetCfg()[var] = self:GetChecked(); UpdateAppearance() end)
    end
    CreateCheck("Lock Position", "locked", -85); CreateCheck("Hide Background", "hideBG", -115)

    local function CreateSlider(label, min, max, step, var, isPercent, yOff)
        local s = CreateFrame("Slider", "MDSlider_"..var, visualTab, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 25, yOff); s:SetMinMaxValues(min, max); s:SetValueStep(step)
        local valSetting = GetCfg()[var] or 30; s:SetValue(valSetting); s:SetWidth(180)
        _G[s:GetName().."Text"]:SetText(label); local val = s:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        val:SetPoint("LEFT", s, "RIGHT", 15, 0)
        s:SetScript("OnValueChanged", function(_, v) GetCfg()[var] = v; UpdateAppearance(); val:SetText(isPercent and math.floor(v*100).."%" or math.floor(v).."px") end)
        val:SetText(isPercent and math.floor(valSetting*100).."%" or math.floor(valSetting).."px")
    end
    CreateSlider("Overall Scale", 0.5, 2.0, 0.05, "scale", true, -165)
    CreateSlider("Button Width (Squish)", 10, 50, 1, "btnWidth", false, -215)
    CreateSlider("Font Size", 10, 30, 1, "fontSize", false, -265)

    local function CreateColorRow(label, var, yOff)
        local btn = CreateFrame("Button", nil, visualTab, "UIPanelButtonTemplate")
        btn:SetSize(140, 24); btn:SetPoint("TOPLEFT", 20, yOff); btn:SetText(label)
        btn:SetScript("OnClick", function() OpenColorPicker(var, UpdateAppearance) end)
        local swatch = visualTab:CreateTexture(nil, "OVERLAY"); swatch:SetSize(18, 18); swatch:SetPoint("LEFT", btn, "RIGHT", 10, 0); swatch:SetColorTexture(1, 1, 1, 1)
        local inner = visualTab:CreateTexture(nil, "OVERLAY"); inner:SetSize(14, 14); inner:SetPoint("CENTER", swatch)
        btn:SetScript("OnUpdate", function() local c = GetCfg()[var]; inner:SetColorTexture(c[1], c[2], c[3], c[4]) end)
    end
    CreateColorRow("Tray Color", "trayColor", -310); CreateColorRow("Button Color", "btnColor", -340); CreateColorRow("Text Color", "textColor", -370)

    -- Profile Tab
    local activeLabel = profileTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    activeLabel:SetPoint("TOPLEFT", 20, -100); activeLabel:SetText("Profile Management")

    local activeDrop = CreateFrame("Frame", "AbstractActiveDrop", profileTab, "UIDropDownMenuTemplate")
    activeDrop:SetPoint("TOPLEFT", 10, -140); UIDropDownMenu_SetWidth(activeDrop, 180)
    
    local delDrop = CreateFrame("Frame", "AbstractDelDrop", profileTab, "UIDropDownMenuTemplate")
    delDrop:SetPoint("TOPLEFT", 10, -280); UIDropDownMenu_SetWidth(delDrop, 180)

    local function RefreshProfileMenus()
        local currentProfile = AbstractUIButtonsDB.charToProfile[GetCharKey()]
        
        UIDropDownMenu_Initialize(activeDrop, function()
            for name in pairs(AbstractUIButtonsDB.profiles) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name; info.func = function() AbstractUIButtonsDB.charToProfile[GetCharKey()] = name; UpdateAppearance(); RefreshProfileMenus() end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetText(activeDrop, "Active: " .. currentProfile)

        UIDropDownMenu_Initialize(delDrop, function()
            local count = 0
            for name in pairs(AbstractUIButtonsDB.profiles) do
                if name ~= "Default" and name ~= currentProfile then
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = name; info.func = function() 
                        AbstractUIButtonsDB.profiles[name] = nil
                        RefreshProfileMenus()
                    end
                    UIDropDownMenu_AddButton(info)
                    count = count + 1
                end
            end
            if count == 0 then
                local info = UIDropDownMenu_CreateInfo(); info.text = "No other profiles"; info.disabled = true; UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetText(delDrop, "Select to Delete...")
    end

    local newLabel = profileTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    newLabel:SetPoint("TOPLEFT", 25, -180); newLabel:SetText("Create New Profile:")
    local newEdit = CreateFrame("EditBox", nil, profileTab, "InputBoxTemplate")
    newEdit:SetSize(150, 25); newEdit:SetPoint("TOPLEFT", 25, -200); newEdit:SetAutoFocus(false)
    local addBtn = CreateFrame("Button", nil, profileTab, "UIPanelButtonTemplate")
    addBtn:SetSize(80, 24); addBtn:SetPoint("LEFT", newEdit, "RIGHT", 10, 0); addBtn:SetText("Create")
    addBtn:SetScript("OnClick", function()
        local name = newEdit:GetText()
        if name ~= "" and not AbstractUIButtonsDB.profiles[name] then
            AbstractUIButtonsDB.profiles[name] = GetDefaultSettings()
            newEdit:SetText(""); RefreshProfileMenus()
        end
    end)

    local delLabel = profileTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    delLabel:SetPoint("TOPLEFT", 25, -260); delLabel:SetText("Delete Profile (Cannot delete Active or Default):")

    RefreshProfileMenus()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        SettingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(SettingsCategory)
    else InterfaceOptions_AddCategory(panel) end
end

-- 5. Main UI & Load
local function CreateButtonUI()
    local cfg = GetCfg()
    Container = CreateFrame("Frame", "AbstractUI_MainContainer", UIParent)
    Container:SetFrameStrata("MEDIUM"); Container:SetMovable(true); Container:EnableMouse(true); Container:SetClampedToScreen(true)
    Container.bg = Container:CreateTexture(nil, "BACKGROUND"); Container.bg:SetAllPoints()
    Container:RegisterForDrag("LeftButton")
    
    Container:SetScript("OnDragStart", function(self) if not GetCfg().locked and not InCombatLockdown() then self:StartMoving() end end)
    Container:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); local p, _, _, x, y = self:GetPoint(); GetCfg().pos = {p, x, y} end)
    
    -- Right Click on Empty Space -> Open Options
    Container:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then OpenOptions() end
    end)
    
    local function SetupButton(btn, textStr)
        btn:SetFrameLevel(Container:GetFrameLevel() + 5); btn:EnableMouse(true)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND"); btn.bg:SetAllPoints()
        local h = btn:CreateTexture(nil, "HIGHLIGHT"); h:SetAllPoints(); btn:SetHighlightTexture(h)
        btn.text = btn:CreateFontString(nil, "OVERLAY"); btn.text:SetFont("Fonts\\FRIZQT__.TTF", cfg.fontSize or 16, "OUTLINE")
        btn.text:SetPoint("CENTER"); btn.text:SetText(textStr)
    end
    
    local labels, macros = {"R", "E", "L"}, {"/reload", "/quit", "/logout"}
    for i = 1, 3 do
        local b = CreateFrame("Button", "MDSecureBtn_"..i, Container, "SecureActionButtonTemplate")
        
        -- FIX: Use 'type1' (Left Click) for macro, leaving Right Click free
        b:SetAttribute("type1", "macro") 
        b:SetAttribute("macrotext1", macros[i])
        
        b:RegisterForClicks("AnyUp", "AnyDown") 
        
        -- FIX: Right Click -> Open Options
        b:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then OpenOptions() end
        end)
        
        SetupButton(b, labels[i])
    end
    
    local btnA = CreateFrame("Button", "MDNormalBtn_A", Container)
    btnA:RegisterForClicks("AnyUp")
    SetupButton(btnA, "A")
    btnA:SetScript("OnClick", function(self, button) 
        if button == "LeftButton" then 
            if AddonList:IsVisible() then AddonList:Hide() else AddonList:Show() end 
        elseif button == "RightButton" then
            OpenOptions() 
        end 
    end)
end

local function InitMasque()
    local Masque = LibStub("Masque", true)
    if Masque then
        MasqueGroup = Masque:Group("Abstract UI Buttons")
        for i = 1, 3 do MasqueGroup:AddButton(_G["MDSecureBtn_"..i]) end
        MasqueGroup:AddButton(_G["MDNormalBtn_A"])
    end
end
local f = CreateFrame("Frame"); f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name) if name == AddonName then InitDB(); CreateButtonUI(); InitMasque(); RegisterOptions(); UpdateAppearance() end end)