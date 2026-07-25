-- ============================================================
-- CELESTIAL UI LIBRARY (ЧАСТЬ 1: ЯДРО И НАСТРОЙКИ)
-- ============================================================

local function CreateMenu(options)
    options = options or {}
    local showLoader = (options.showLoader ~= false)

    -- Сервисы
    local UIS = game:GetService("UserInputService")
    local TS = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    local GuiService = game:GetService("GuiService")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    -- Вспомогательные функции для картинок
    local function GetLoaderImg(name, url)
        local path = "Celestial/pngs/" .. name
        if not isfolder("Celestial") then makefolder("Celestial") end
        if not isfolder("Celestial/pngs") then makefolder("Celestial/pngs") end
        if not isfile(path) then
            pcall(function() writefile(path, game:HttpGet(url)) end)
            task.wait(0.3)
        end
        return getcustomasset(path)
    end

    local function GetMellstroy(name, url)
        local folder = "Celestial/pngs"
        local path = folder .. "/" .. name
        if not isfolder("Celestial") then makefolder("Celestial") end
        if not isfolder(folder) then makefolder(folder) end
        if not isfile(path) then
            local success, content = pcall(game.HttpGet, game, url)
            if success then writefile(path, content) end
        end
        return getcustomasset(path)
    end

    -- Библиотека (будет возвращена)
    local library = {
        flags = {},
        theme = { G1 = Color3.fromRGB(180, 40, 40), G2 = Color3.fromRGB(40, 80, 200) },
        _menuOpen = false,
        _connections = {},
        hud = {}  -- здесь будут методы управления HUD
    }

    -- Переменные GUI (меню)
    local ScreenGui, Main, Sidebar, Content, BottomList, Pages, ActiveGradients
    local WaifuGui, WaifuImg
    local MenuKey = Enum.KeyCode.RightShift
    local BindBtnRef = nil

    -- ============================================================
    -- 1. УВЕДОМЛЕНИЯ
    -- ============================================================
    local function CreateNotify(title, text, duration)
        title = title or "Celestial"
        text = text or "Notification"
        duration = duration or 3

        local NotifGui = CoreGui:FindFirstChild("CelestialNotifs")
        if not NotifGui then
            NotifGui = Instance.new("ScreenGui", CoreGui)
            NotifGui.Name = "CelestialNotifs"
            local Holder = Instance.new("Frame", NotifGui)
            Holder.Name = "Holder"
            Holder.Size = UDim2.new(0, 280, 1, -40)
            Holder.Position = UDim2.new(1, -290, 0, 20)
            Holder.BackgroundTransparency = 1
            local Layout = Instance.new("UIListLayout", Holder)
            Layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            Layout.Padding = UDim.new(0, 8)
        end
        local Holder = NotifGui.Holder

        local MainNotif = Instance.new("Frame", Holder)
        MainNotif.Size = UDim2.new(1, 0, 0, 0)
        MainNotif.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
        MainNotif.ClipsDescendants = true
        Instance.new("UICorner", MainNotif).CornerRadius = UDim.new(0, 6)
        local Stroke = Instance.new("UIStroke", MainNotif)
        Stroke.Color = Color3.fromRGB(40, 40, 45)

        local T = Instance.new("TextLabel", MainNotif)
        T.Text = title:upper()
        T.Size = UDim2.new(1, -20, 0, 20)
        T.Position = UDim2.new(0, 10, 0, 8)
        T.BackgroundTransparency = 1
        T.TextColor3 = library.theme.G1
        T.Font = Enum.Font.GothamBold
        T.TextSize = 13
        T.TextXAlignment = Enum.TextXAlignment.Left

        local D = Instance.new("TextLabel", MainNotif)
        D.Text = text
        D.Size = UDim2.new(1, -20, 0, 20)
        D.Position = UDim2.new(0, 10, 0, 26)
        D.BackgroundTransparency = 1
        D.TextColor3 = Color3.fromRGB(200, 200, 200)
        D.Font = Enum.Font.Gotham
        D.TextSize = 12
        D.TextXAlignment = Enum.TextXAlignment.Left
        D.TextWrapped = true

        local TimerBar = Instance.new("Frame", MainNotif)
        TimerBar.Size = UDim2.new(1, 0, 0, 2)
        TimerBar.Position = UDim2.new(0, 0, 1, -2)
        TimerBar.BackgroundColor3 = library.theme.G1
        local G = Instance.new("UIGradient", TimerBar)
        G.Color = ColorSequence.new(library.theme.G1, library.theme.G2)

        TS:Create(MainNotif, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 55) }):Play()

        task.spawn(function()
            TS:Create(TimerBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
            task.wait(duration)
            local CloseTween = TS:Create(MainNotif, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, 0) })
            CloseTween:Play()
            CloseTween.Completed:Wait()
            MainNotif:Destroy()
        end)
    end

    -- ============================================================
    -- 2. ЭЛЕМЕНТЫ УПРАВЛЕНИЯ (Toggle, Slider, ColorPicker, Dropdown)
    -- ============================================================
    local function AddToggle(parent, config)
        local state = config.default or false
        library.flags[config.flag] = state

        local TFrame = Instance.new("TextButton", parent)
        TFrame.Size = UDim2.new(1, 0, 0, 30)
        TFrame.BackgroundTransparency = 1
        TFrame.Text = ""
        local Label = Instance.new("TextLabel", TFrame)
        Label.Text = config.text
        Label.Size = UDim2.new(1, -40, 1, 0)
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left
        local Box = Instance.new("Frame", TFrame)
        Box.Size = UDim2.new(0, 32, 0, 18)
        Box.Position = UDim2.new(1, -35, 0.5, -9)
        Box.BackgroundColor3 = state and library.theme.G1 or Color3.fromRGB(45, 45, 50)
        Instance.new("UICorner", Box).CornerRadius = UDim.new(1, 0)
        local Dot = Instance.new("Frame", Box)
        Dot.Size = UDim2.new(0, 14, 0, 14)
        Dot.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

        table.insert(ActiveGradients, {
            Type = "Toggle",
            Object = Box,
            Flag = config.flag
        })

        TFrame.MouseButton1Click:Connect(function()
            state = not state
            library.flags[config.flag] = state
            TS:Create(Box, TweenInfo.new(0.3), { BackgroundColor3 = state and library.theme.G1 or Color3.fromRGB(45, 45, 50) }):Play()
            TS:Create(Dot, TweenInfo.new(0.3), { Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }):Play()
            if type(config.callback) == "function" then
                task.spawn(config.callback, state)
            end
        end)
    end

    local function AddSlider(parent, config)
        local min, max, default = config.min or 0, config.max or 10, config.value or config.default or 3.5
        library.flags[config.flag] = default

        local SFrame = Instance.new("Frame", parent)
        SFrame.Size = UDim2.new(1, 0, 0, 50)
        SFrame.BackgroundTransparency = 1
        local Label = Instance.new("TextLabel", SFrame)
        Label.Text = config.text .. ": " .. default
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 14
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left
        local Bar = Instance.new("TextButton", SFrame)
        Bar.Size = UDim2.new(1, 0, 0, 6)
        Bar.Position = UDim2.new(0, 0, 0.75, 0)
        Bar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        Bar.Text = ""
        Instance.new("UICorner", Bar)
        local Fill = Instance.new("Frame", Bar)
        Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        Fill.BackgroundColor3 = library.theme.G1
        Instance.new("UICorner", Fill)

        table.insert(ActiveGradients, {
            Type = "Slider",
            Object = Fill
        })

        local dragging = false
        local function update()
            local pos = math.clamp((UIS:GetMouseLocation().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            Fill.Size = UDim2.new(pos, 0, 1, 0)
            local val = math.floor((pos * (max - min) + min) * 10) / 10
            Label.Text = config.text .. ": " .. val
            library.flags[config.flag] = val
            if type(config.callback) == "function" then
                task.spawn(config.callback, val)
            end
        end

        Bar.MouseButton1Down:Connect(function() dragging = true; update() end)
        UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update() end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    local function AddColorPicker(parent, config)
        local ColorPicker = {
            Value = config.default or Color3.fromRGB(255, 255, 255),
            Hue = 0, Sat = 0, Vib = 0,
            Title = config.text or "Color Picker"
        }

        local function UpdateHSV()
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(ColorPicker.Value)
        end
        UpdateHSV()

        local function GetMousePos()
            local mousePos = UIS:GetMouseLocation()
            local inset = GuiService:GetGuiInset()
            return Vector2.new(mousePos.X, mousePos.Y - inset.Y)
        end

        local CPFrame = Instance.new("Frame", parent)
        CPFrame.Size = UDim2.new(1, 0, 0, 30)
        CPFrame.BackgroundTransparency = 1

        local Label = Instance.new("TextLabel", CPFrame)
        Label.Text = ColorPicker.Title
        Label.Size = UDim2.new(1, -40, 1, 0)
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local DisplayFrame = Instance.new("TextButton", CPFrame)
        DisplayFrame.Size = UDim2.new(0, 28, 0, 14)
        DisplayFrame.Position = UDim2.new(1, -35, 0.5, -7)
        DisplayFrame.BackgroundColor3 = ColorPicker.Value
        DisplayFrame.Text = ""
        Instance.new("UIStroke", DisplayFrame).Color = Color3.new(0, 0, 0)

        local PickerFrame = Instance.new("Frame", ScreenGui)
        PickerFrame.Name = "ColorPickerWindow"
        PickerFrame.Size = UDim2.fromOffset(230, 245)
        PickerFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        PickerFrame.Visible = false
        PickerFrame.ZIndex = 100
        local PickerStroke = Instance.new("UIStroke", PickerFrame)
        PickerStroke.Color = Color3.fromRGB(60, 60, 65)
        Instance.new("UICorner", PickerFrame).CornerRadius = UDim.new(0, 4)

        local SatVibMap = Instance.new("ImageLabel", PickerFrame)
        SatVibMap.Size = UDim2.new(0, 200, 0, 200)
        SatVibMap.Position = UDim2.new(0, 5, 0, 5)
        SatVibMap.Image = "rbxassetid://4155801252"
        SatVibMap.ZIndex = 101

        local Cursor = Instance.new("Frame", SatVibMap)
        Cursor.Size = UDim2.fromOffset(6, 6)
        Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
        Cursor.BackgroundColor3 = Color3.new(1, 1, 1)
        Cursor.ZIndex = 105
        Instance.new("UICorner", Cursor).CornerRadius = UDim.new(1, 0)
        Instance.new("UIStroke", Cursor).Color = Color3.new(0, 0, 0)

        local HueSelector = Instance.new("Frame", PickerFrame)
        HueSelector.Size = UDim2.new(0, 15, 0, 200)
        HueSelector.Position = UDim2.new(0, 210, 0, 5)
        HueSelector.ZIndex = 101
        local HueGrad = Instance.new("UIGradient", HueSelector)
        HueGrad.Rotation = 90
        HueGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(0.2, Color3.fromHSV(0.2, 1, 1)),
            ColorSequenceKeypoint.new(0.4, Color3.fromHSV(0.4, 1, 1)),
            ColorSequenceKeypoint.new(0.6, Color3.fromHSV(0.6, 1, 1)),
            ColorSequenceKeypoint.new(0.8, Color3.fromHSV(0.8, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
        })

        local HueCursor = Instance.new("Frame", HueSelector)
        HueCursor.Size = UDim2.new(1, 0, 0, 2)
        HueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
        HueCursor.ZIndex = 105
        Instance.new("UIStroke", HueCursor).Color = Color3.new(0, 0, 0)

        local HexBox = Instance.new("TextBox", PickerFrame)
        HexBox.Size = UDim2.new(1, -10, 0, 25)
        HexBox.Position = UDim2.new(0, 5, 0, 212)
        HexBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        HexBox.TextColor3 = Color3.new(1, 1, 1)
        HexBox.Font = Enum.Font.Gotham
        HexBox.TextSize = 12
        HexBox.ZIndex = 101
        Instance.new("UICorner", HexBox)
        Instance.new("UIStroke", HexBox).Color = Color3.fromRGB(45, 45, 50)

        function ColorPicker:Update()
            local color = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
            ColorPicker.Value = color
            DisplayFrame.BackgroundColor3 = color
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            Cursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0, ColorPicker.Hue)
            HexBox.Text = "#" .. color:ToHex():upper()
            library.flags[config.flag] = color
            if config.callback then config.callback(color) end
        end

        local function InputLogic()
            SatVibMap.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local mPos = GetMousePos()
                        local relX = math.clamp((mPos.X - SatVibMap.AbsolutePosition.X) / SatVibMap.AbsoluteSize.X, 0, 1)
                        local relY = math.clamp((mPos.Y - SatVibMap.AbsolutePosition.Y) / SatVibMap.AbsoluteSize.Y, 0, 1)
                        ColorPicker.Sat = relX
                        ColorPicker.Vib = 1 - relY
                        ColorPicker:Update()
                        RunService.RenderStepped:Wait()
                    end
                end
            end)
            HueSelector.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local mPos = GetMousePos()
                        local relY = math.clamp((mPos.Y - HueSelector.AbsolutePosition.Y) / HueSelector.AbsoluteSize.Y, 0, 1)
                        ColorPicker.Hue = relY
                        ColorPicker:Update()
                        RunService.RenderStepped:Wait()
                    end
                end
            end)
        end
        InputLogic()

        DisplayFrame.MouseButton1Click:Connect(function()
            PickerFrame.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X - 240, DisplayFrame.AbsolutePosition.Y)
            PickerFrame.Visible = not PickerFrame.Visible
            ColorPicker:Update()
        end)

        HexBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HexBox.Text)
                if success then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                    ColorPicker:Update()
                end
            end
        end)

        ColorPicker:Update()
    end

    local function AddDropdown(parent, config)
        local displayName = config.text or config.name or "Dropdown"
        local items = config.options or config.items or {}
        local selected = config.default or items[1] or "None"
        library.flags[config.flag] = selected
        local isOpen = false

        local DFrame = Instance.new("Frame", parent)
        DFrame.Size = UDim2.new(1, 0, 0, 30)
        DFrame.BackgroundTransparency = 1
        DFrame.ClipsDescendants = true

        local MainBtn = Instance.new("TextButton", DFrame)
        MainBtn.Size = UDim2.new(1, 0, 0, 30)
        MainBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        MainBtn.Text = "  " .. tostring(displayName) .. ": " .. tostring(selected)
        MainBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        MainBtn.Font = Enum.Font.GothamBold
        MainBtn.TextSize = 12
        MainBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", MainBtn)

        local ItemList = Instance.new("Frame", DFrame)
        ItemList.Position = UDim2.new(0, 0, 0, 35)
        ItemList.Size = UDim2.new(1, 0, 0, #items * 25)
        ItemList.BackgroundTransparency = 1
        Instance.new("UIListLayout", ItemList).Padding = UDim.new(0, 2)

        for _, item in pairs(items) do
            local B = Instance.new("TextButton", ItemList)
            B.Size = UDim2.new(1, 0, 0, 23)
            B.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            B.Text = tostring(item)
            B.TextColor3 = (item == selected) and library.theme.G1 or Color3.fromRGB(150, 150, 150)
            B.Font = Enum.Font.Gotham
            B.TextSize = 11
            Instance.new("UICorner", B)

            table.insert(ActiveGradients, { Object = B, Type = "DropdownItem", ItemName = item, Flag = config.flag })

            B.MouseButton1Click:Connect(function()
                selected = item
                library.flags[config.flag] = item
                MainBtn.Text = "  " .. tostring(displayName) .. ": " .. tostring(item)
                for _, otherB in pairs(ItemList:GetChildren()) do
                    if otherB:IsA("TextButton") then
                        otherB.TextColor3 = (otherB.Text == item) and library.theme.G1 or Color3.fromRGB(150, 150, 150)
                    end
                end
                isOpen = false
                TS:Create(DFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 30) }):Play()
                if type(config.callback) == "function" then task.spawn(config.callback, item) end
            end)
        end

        MainBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            local targetSize = isOpen and (35 + (#items * 27)) or 30
            TS:Create(DFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, targetSize) }):Play()
        end)
    end

    -- ============================================================
    -- 3. МОДУЛЬ (карточка с переключателем)
    -- ============================================================
    local function CreateModule(parent, title, desc, setupFunc, mainCallback)
        local Mod = Instance.new("TextButton", parent)
        Mod.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        Mod.AutoButtonColor = false
        Mod.Text = ""
        Instance.new("UICorner", Mod).CornerRadius = UDim.new(0, 10)
        local g = Instance.new("UIGradient", Mod)
        g.Color = ColorSequence.new(library.theme.G1, library.theme.G2)
        g.Transparency = NumberSequence.new(1)
        g.Enabled = true
        table.insert(ActiveGradients, g)

        local T = Instance.new("TextLabel", Mod)
        T.Text = "  " .. title
        T.Size = UDim2.new(1, 0, 0.55, 0)
        T.BackgroundTransparency = 1
        T.TextColor3 = Color3.fromRGB(255, 255, 255)
        T.Font = Enum.Font.GothamBold
        T.TextSize = 15
        T.TextXAlignment = Enum.TextXAlignment.Left

        local D = Instance.new("TextLabel", Mod)
        D.Text = "  " .. desc
        D.Position = UDim2.new(0, 0, 0.45, 0)
        D.Size = UDim2.new(1, 0, 0.45, 0)
        D.BackgroundTransparency = 1
        D.TextColor3 = Color3.fromRGB(180, 180, 190)
        D.Font = Enum.Font.Gotham
        D.TextSize = 10
        D.TextXAlignment = Enum.TextXAlignment.Left

        local BindLabel = Instance.new("TextLabel", Mod)
        BindLabel.Text = "[NONE]"
        BindLabel.Size = UDim2.new(0, 40, 0, 20)
        BindLabel.Position = UDim2.new(1, -45, 1, -22)
        BindLabel.BackgroundTransparency = 1
        BindLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
        BindLabel.Font = Enum.Font.GothamMedium
        BindLabel.TextSize = 10
        BindLabel.TextXAlignment = Enum.TextXAlignment.Right

        local function toggle()
            if title == "Unload" then
                library.Unload()
                return
            end
            local enabled = g.Transparency.Keypoints[1].Value == 1
            library.flags[title] = enabled
            g.Transparency = enabled and NumberSequence.new(0) or NumberSequence.new(1)
            TS:Create(Mod, TweenInfo.new(0.4), { BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(35, 35, 40) }):Play()
            if type(mainCallback) == "function" then
                task.spawn(mainCallback, enabled)
            end
        end

        local SWindow
        if setupFunc then
            local Gear = Instance.new("ImageButton", Mod)
            Gear.Size = UDim2.new(0, 18, 0, 18)
            Gear.Position = UDim2.new(1, -25, 0, 8)
            Gear.BackgroundTransparency = 1
            Gear.Image = "rbxassetid://10734950309"
            Gear.ImageColor3 = Color3.fromRGB(200, 200, 200)
            Gear.ZIndex = 5

            SWindow = Instance.new("Frame", Main)
            SWindow.Size = UDim2.new(0, 240, 0, 320)
            SWindow.Position = UDim2.new(1, 20, 0.1, 0)
            SWindow.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
            SWindow.Visible = false
            Instance.new("UICorner", SWindow)
            Instance.new("UIStroke", SWindow).Color = Color3.fromRGB(60, 60, 65)

            local SList = Instance.new("ScrollingFrame", SWindow)
            SList.Position = UDim2.new(0, 15, 0, 45)
            SList.Size = UDim2.new(1, -30, 1, -60)
            SList.BackgroundTransparency = 1
            SList.ScrollBarThickness = 0
            Instance.new("UIListLayout", SList).Padding = UDim.new(0, 12)

            local Close = Instance.new("TextButton", SWindow)
            Close.Text = "×"
            Close.Size = UDim2.new(0, 30, 0, 30)
            Close.Position = UDim2.new(1, -35, 0, 5)
            Close.BackgroundTransparency = 1
            Close.TextColor3 = Color3.fromRGB(200, 50, 50)
            Close.TextSize = 24
            Close.MouseButton1Click:Connect(function() SWindow.Visible = false end)

            Gear.MouseButton1Click:Connect(function() SWindow.Visible = not SWindow.Visible end)

            setupFunc({
                AddSlider = function(_, c) AddSlider(SList, c) end,
                AddToggle = function(_, c) AddToggle(SList, c) end,
                AddColorPicker = function(_, c) AddColorPicker(SList, c) end,
                AddDropdown = function(_, c) AddDropdown(SList, c) end
            })
        end

        Mod.MouseButton1Click:Connect(toggle)

        local isBinding = false
        local currentBind = "NONE"
        Mod.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton3 then
                isBinding = true
                BindLabel.Text = "[...]"
                BindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end)
        UIS.InputBegan:Connect(function(i, gpe)
            if isBinding and i.UserInputType == Enum.UserInputType.Keyboard then
                currentBind = i.KeyCode.Name
                BindLabel.Text = "[" .. currentBind .. "]"
                BindLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
                isBinding = false
                library.flags[title .. "_Bind"] = currentBind
            elseif not gpe and i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == currentBind then
                toggle()
            end
        end)
    end

    -- ============================================================
    -- 4. ВКЛАДКИ (AddTab)
    -- ============================================================
    local function AddTab(name, iconId, isBottom)
        local parent = isBottom and BottomList or BtnList
        local Btn = Instance.new("TextButton", parent)
        Btn.Size = UDim2.new(0, 160, 0, 38)
        Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        Btn.Text = "          " .. name
        Btn.TextColor3 = Color3.fromRGB(140, 140, 140)
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 13
        Btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", Btn)

        local Icon = Instance.new("ImageLabel", Btn)
        Icon.Size = UDim2.new(0, 18, 0, 18)
        Icon.Position = UDim2.new(0, 12, 0.5, -9)
        Icon.BackgroundTransparency = 1
        Icon.Image = iconId or "rbxassetid://0"
        Icon.ImageColor3 = Color3.fromRGB(140, 140, 140)

        local Grad = Instance.new("UIGradient", Btn)
        Grad.Color = ColorSequence.new(library.theme.G1, library.theme.G2)
        Grad.Enabled = false
        table.insert(ActiveGradients, Grad)

        local Page = Instance.new("ScrollingFrame", Content)
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 0
        Instance.new("UIGridLayout", Page).CellSize = UDim2.new(0, 220, 0, 70)

        local existingTabs = {}
        for _, v in pairs(Pages) do table.insert(existingTabs, v) end
        if #existingTabs == 0 then
            Page.Visible = true
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
            Grad.Enabled = true
        end

        Btn.MouseButton1Click:Connect(function()
            for _, v in pairs(Pages) do
                v.Page.Visible = false
                v.Btn.TextColor3 = Color3.fromRGB(140, 140, 140)
                v.Icon.ImageColor3 = Color3.fromRGB(140, 140, 140)
                v.Grad.Enabled = false
            end
            Page.Visible = true
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
            Grad.Enabled = true
        end)

        Pages[name] = { Page = Page, Btn = Btn, Icon = Icon, Grad = Grad }
        return Page
    end

    -- ============================================================
    -- 5. ПОСТРОЕНИЕ ГЛАВНОГО МЕНЮ (BuildMenu)
    -- ============================================================
    local function BuildMenu()
        local MenuName = "Celestial"
        if CoreGui:FindFirstChild(MenuName) then CoreGui[MenuName]:Destroy() end

        ScreenGui = Instance.new("ScreenGui", CoreGui)
        ScreenGui.Name = MenuName
        ScreenGui.IgnoreGuiInset = true

        ActiveGradients = {}

        Main = Instance.new("Frame", ScreenGui)
        Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        Main.Size = UDim2.new(0, 700, 0, 0)
        Main.Position = UDim2.new(0.5, -350, 0.5, 0)
        Main.Active = true
        Main.Draggable = true
        Main.Visible = false
        Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
        Instance.new("UIStroke", Main).Color = Color3.fromRGB(45, 45, 50)

        Sidebar = Instance.new("Frame", Main)
        Sidebar.Size = UDim2.new(0, 180, 1, 0)
        Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

        local Logo = Instance.new("TextLabel", Sidebar)
        Logo.Text = MenuName
        Logo.Size = UDim2.new(1, 0, 0, 60)
        Logo.BackgroundTransparency = 1
        Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
        Logo.Font = Enum.Font.GothamBold
        Logo.TextSize = 22

        BtnList = Instance.new("Frame", Sidebar)
        BtnList.Position = UDim2.new(0, 0, 0, 70)
        BtnList.Size = UDim2.new(1, 0, 1, -120)
        BtnList.BackgroundTransparency = 1
        Instance.new("UIListLayout", BtnList).Padding = UDim.new(0, 5)
        BtnList.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        Content = Instance.new("Frame", Main)
        Content.Position = UDim2.new(0, 195, 0, 20)
        Content.Size = UDim2.new(1, -215, 1, -40)
        Content.BackgroundTransparency = 1

        BottomList = Instance.new("Frame", Sidebar)
        BottomList.Size = UDim2.new(1, 0, 0, 100)
        BottomList.Position = UDim2.new(0, 0, 1, -110)
        BottomList.BackgroundTransparency = 1
        local BLayout = Instance.new("UIListLayout", BottomList)
        BLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        BLayout.Padding = UDim.new(0, 5)
        BLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        Pages = {}

        local UnloadBtn = Instance.new("TextButton", BottomList)
        UnloadBtn.Size = UDim2.new(0, 160, 0, 38)
        UnloadBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        UnloadBtn.Text = "          Выйти"
        UnloadBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
        UnloadBtn.Font = Enum.Font.GothamBold
        UnloadBtn.TextSize = 13
        UnloadBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", UnloadBtn)
        local UnloadIcon = Instance.new("ImageLabel", UnloadBtn)
        UnloadIcon.Size = UDim2.new(0, 18, 0, 18)
        UnloadIcon.Position = UDim2.new(0, 12, 0.5, -9)
        UnloadIcon.BackgroundTransparency = 1
        UnloadIcon.Image = "rbxassetid://10723356507"
        UnloadIcon.ImageColor3 = Color3.fromRGB(200, 50, 50)

        UnloadBtn.MouseButton1Click:Connect(function()
            library.Unload()
        end)

        local GearBtn = Instance.new("ImageButton", Main)
        GearBtn.Size = UDim2.new(0, 20, 0, 20)
        GearBtn.Position = UDim2.new(1, -30, 0, 10)
        GearBtn.BackgroundTransparency = 1
        GearBtn.Image = "rbxassetid://10734950309"
        GearBtn.ImageColor3 = Color3.fromRGB(200, 200, 200)

        GearBtn.MouseButton1Click:Connect(function()
            if Pages and Pages["Settings"] then
                for _, v in pairs(Pages) do
                    v.Page.Visible = false
                    v.Btn.TextColor3 = Color3.fromRGB(140, 140, 140)
                    v.Icon.ImageColor3 = Color3.fromRGB(140, 140, 140)
                    v.Grad.Enabled = false
                end
                local settings = Pages["Settings"]
                settings.Page.Visible = true
                settings.Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                settings.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                settings.Grad.Enabled = true
            else
                CreateNotify("Celestial", "Вкладка Settings не найдена", 2)
            end
        end)

        WaifuGui = Instance.new("ScreenGui", CoreGui)
        WaifuGui.Name = "CelestialWaifu"
        WaifuGui.DisplayOrder = -1
        WaifuImg = Instance.new("ImageLabel", WaifuGui)
        WaifuImg.Name = "WaifuDisplay"
        WaifuImg.Size = UDim2.new(0.4, 0, 0.6, 0)
        WaifuImg.Position = UDim2.new(1, 0, 1, 0)
        WaifuImg.AnchorPoint = Vector2.new(1, 1)
        WaifuImg.BackgroundTransparency = 1
        WaifuImg.ImageTransparency = 1
        WaifuImg.ScaleType = Enum.ScaleType.Fit

        function ToggleMenu()
            library._menuOpen = not library._menuOpen
            if library._menuOpen then
                if library.flags["Menu Waifu"] and library.flags["WaifuSelection"] == "Mellstroy" then
                    TS:Create(WaifuImg, TweenInfo.new(0.5), { ImageTransparency = 0.1 }):Play()
                end
                local blurFlag = library.flags["MenuBlur"]
                local Lighting = game:GetService("Lighting")
                local bEffect = Lighting:FindFirstChild("MenuBlur")
                if blurFlag then
                    if not bEffect then
                        bEffect = Instance.new("BlurEffect", Lighting)
                        bEffect.Name = "MenuBlur"
                    end
                    bEffect.Enabled = true
                    TS:Create(bEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = 18 }):Play()
                end
                Main.Visible = true
                TS:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 700, 0, 500),
                    Position = UDim2.new(0.5, -350, 0.5, -250),
                    BackgroundTransparency = 0
                }):Play()
            else
                local bEffect = game:GetService("Lighting"):FindFirstChild("MenuBlur")
                if bEffect then
                    TS:Create(bEffect, TweenInfo.new(0.3), { Size = 0 }):Play()
                    task.delay(0.3, function()
                        if not library._menuOpen then bEffect.Enabled = false end
                    end)
                end
                for _, v in pairs(Main:GetChildren()) do
                    if v:IsA("Frame") and v.Name:find("SWindow") then v.Visible = false end
                end
                local CloseTween = TS:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 700, 0, 0),
                    Position = UDim2.new(0.5, -350, 0.5, 0),
                    BackgroundTransparency = 1
                })
                CloseTween:Play()
                CloseTween.Completed:Connect(function()
                    if not library._menuOpen then
                        Main.Visible = false
                        library._menuOpen = false
                    end
                end)
                TS:Create(WaifuImg, TweenInfo.new(0.5), { ImageTransparency = 1 }):Play()
            end
        end

        -- Возвращаем методы для библиотеки
        return {
            AddTab = AddTab,
            AddToggle = AddToggle,
            AddSlider = AddSlider,
            AddColorPicker = AddColorPicker,
            AddDropdown = AddDropdown,
            CreateModule = CreateModule,
            AddSettingsTab = AddSettingsTab,
            AddThemesTab = AddThemesTab,
            ToggleMenu = ToggleMenu,
            SetMenuKey = function(key)
                MenuKey = key
                if BindBtnRef then
                    BindBtnRef.Text = "Menu Bind: " .. key.Name:upper()
                    BindBtnRef.TextColor3 = library.theme.G1
                end
            end,
            GetFlags = function() return library.flags end,
            GetTheme = function() return library.theme end,
            SetTheme = function(colors)
                library.theme = colors
                -- Обновление всех градиентов в меню
                for _, data in pairs(ActiveGradients) do
                    if typeof(data) == "Instance" then
                        data.Color = ColorSequence.new(colors.G1, colors.G2)
                    elseif type(data) == "table" then
                        if data.Type == "Toggle" and library.flags[data.Flag] then
                            TS:Create(data.Object, TweenInfo.new(0.3), { BackgroundColor3 = colors.G1 }):Play()
                        elseif data.Type == "Slider" then
                            TS:Create(data.Object, TweenInfo.new(0.3), { BackgroundColor3 = colors.G1 }):Play()
                        end
                    end
                end
                if BindBtnRef then
                    BindBtnRef.TextColor3 = colors.G1
                end
                -- Обновляем HUD, если доступно
                if library.hud and library.hud.updateTheme then
                    library.hud.updateTheme()
                end
                CreateNotify("Celestial", "Тема обновлена", 1)
            end,
            Notify = CreateNotify,
            Unload = function()
                for _, conn in ipairs(library._connections) do
                    pcall(function() conn:Disconnect() end)
                end
                library._connections = {}
                local hudGui = CoreGui:FindFirstChild("CelestialHUD")
                if hudGui then hudGui:Destroy() end
                if ScreenGui then ScreenGui:Destroy() end
                if WaifuGui then WaifuGui:Destroy() end
                local notifGui = CoreGui:FindFirstChild("CelestialNotifs")
                if notifGui then notifGui:Destroy() end
                for flag, _ in pairs(library.flags) do
                    library.flags[flag] = false
                end
                library._menuOpen = false
                library.hud = nil
                print("[Celestial] Unload completed.")
            end
        }
    end

    -- ============================================================
    -- 6. ВКЛАДКА НАСТРОЕК (AddSettingsTab) с тогглами HUD
    -- ============================================================
    local function AddSettingsTab()
        local settingsPage = AddTab("Settings", "rbxassetid://10734950309")
        if Pages["Settings"] then
            Pages["Settings"].Btn.Visible = false
        end

        local SLayout = Instance.new("UIListLayout", settingsPage)
        SLayout.Padding = UDim.new(0, 10)
        SLayout.SortOrder = Enum.SortOrder.LayoutOrder
        SLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        AddToggle(settingsPage, {
            text = "Background Blur",
            flag = "MenuBlur",
            default = false,
            callback = function(v)
                local Lighting = game:GetService("Lighting")
                local B = Lighting:FindFirstChild("MenuBlur") or Instance.new("BlurEffect", Lighting)
                B.Name = "MenuBlur"
                if v then
                    B.Enabled = true
                    TS:Create(B, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = 18 }):Play()
                else
                    local CloseTween = TS:Create(B, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = 0 })
                    CloseTween:Play()
                    CloseTween.Completed:Connect(function()
                        if not library.flags["MenuBlur"] then B.Enabled = false end
                    end)
                end
            end
        })

        CreateModule(settingsPage, "Menu Waifu", "Отображение вайфу в углу", function(section)
            section:AddDropdown({
                text = "Character",
                flag = "WaifuSelection",
                options = { "None", "Mellstroy" },
                default = "None",
                callback = function(val)
                    if val == "Mellstroy" and library.flags["Menu Waifu"] then
                        WaifuImg.Image = GetMellstroy("mellstroy.png", "https://raw.githubusercontent.com/bron4ik/Uilib/main/mellstroy.png")
                        TS:Create(WaifuImg, TweenInfo.new(0.5), { ImageTransparency = 0.1 }):Play()
                    else
                        TS:Create(WaifuImg, TweenInfo.new(0.5), { ImageTransparency = 1 }):Play()
                    end
                end
            })
        end)

        -- Бинд для открытия меню
        local BindBtn = Instance.new("TextButton", settingsPage)
        BindBtn.Size = UDim2.new(1, -10, 0, 30)
        BindBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        BindBtn.Text = "Menu Bind: " .. MenuKey.Name:upper()
        BindBtn.TextColor3 = library.theme.G1
        BindBtn.Font = Enum.Font.GothamBold
        BindBtn.TextSize = 13
        Instance.new("UICorner", BindBtn)

        BindBtnRef = BindBtn
        table.insert(ActiveGradients, { Object = BindBtn, Type = "Slider" })

        local isBinding = false
        BindBtn.MouseButton1Click:Connect(function()
            isBinding = true
            BindBtn.Text = "..."
        end)

        UIS.InputBegan:Connect(function(i, g)
            if g then return end
            if isBinding then
                MenuKey = i.KeyCode
                BindBtn.Text = "Menu Bind: " .. i.KeyCode.Name:upper()
                BindBtn.TextColor3 = library.theme.G1
                isBinding = false
                return
            end
            if i.KeyCode == MenuKey then
                ToggleMenu()
            end
        end)

        -- ДОБАВЛЯЕМ МОДУЛЬ HUD ELEMENTS С ТОГГЛАМИ
        CreateModule(settingsPage, "HUD Elements", "Управление интерфейсом", function(section)
            section:AddToggle({
                text = "Показывать Watermark",
                flag = "HUD_Watermark",
                default = true,
                callback = function(v)
                    if library.hud and library.hud.toggleWatermark then
                        library.hud.toggleWatermark(v)
                    end
                end
            })
            section:AddToggle({
                text = "Показывать Target HUD",
                flag = "HUD_Target",
                default = true,
                callback = function(v)
                    if library.hud and library.hud.toggleTarget then
                        library.hud.toggleTarget(v)
                    end
                end
            })
            section:AddToggle({
                text = "Показывать Keybinds",
                flag = "HUD_Keybinds",
                default = true,
                callback = function(v)
                    if library.hud and library.hud.toggleKeybinds then
                        library.hud.toggleKeybinds(v)
                    end
                end
            })
            section:AddDropdown({
                text = "Цель для Target HUD",
                flag = "HUD_Target_Player",
                options = {"Локальный игрок", "Ближайший игрок", "Первый в списке"},
                default = "Локальный игрок",
                callback = function(val)
                    if val == "Локальный игрок" then
                        if library.hud and library.hud.setTarget then
                            library.hud.setTarget(player)
                        end
                    elseif val == "Ближайший игрок" then
                        local closest, minDist = nil, math.huge
                        for _, plr in ipairs(Players:GetPlayers()) do
                            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                                local dist = (plr.Character.HumanoidRootPart.Position - (player.Character and player.Character.HumanoidRootPart and player.Character.HumanoidRootPart.Position or Vector3.zero)).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    closest = plr
                                end
                            end
                        end
                        if library.hud and library.hud.setTarget then
                            library.hud.setTarget(closest or player)
                        end
                    elseif val == "Первый в списке" then
                        local first = nil
                        for _, plr in ipairs(Players:GetPlayers()) do
                            if plr ~= player then
                                first = plr
                                break
                            end
                        end
                        if library.hud and library.hud.setTarget then
                            library.hud.setTarget(first or player)
                        end
                    end
                end
            })
        end)

        return settingsPage
    end

    -- ============================================================
    -- 7. ВКЛАДКА ТЕМ (Themes)
    -- ============================================================
    local function AddThemesTab()
        local themesPage = AddTab("Themes", "rbxassetid://78489916461314", true)

        local ThemeGrid = themesPage:WaitForChild("UIGridLayout")
        ThemeGrid.CellSize = UDim2.new(0, 100, 0, 40)
        ThemeGrid.CellPadding = UDim2.new(0, 10, 0, 10)
        ThemeGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local AvailableThemes = {
            ["Celestial"] = { G1 = Color3.fromRGB(180, 40, 40), G2 = Color3.fromRGB(40, 80, 200) },
            ["Vape"] = { G1 = Color3.fromRGB(0, 255, 200), G2 = Color3.fromRGB(0, 150, 255) },
            ["Emerald"] = { G1 = Color3.fromRGB(40, 200, 80), G2 = Color3.fromRGB(20, 100, 40) },
            ["Amethyst"] = { G1 = Color3.fromRGB(150, 50, 250), G2 = Color3.fromRGB(70, 20, 150) },
            ["Sunrise"] = { G1 = Color3.fromRGB(255, 150, 50), G2 = Color3.fromRGB(200, 50, 50) }
        }

        for name, colors in pairs(AvailableThemes) do
            local TBtn = Instance.new("TextButton", themesPage)
            TBtn.Name = name
            TBtn.Text = name:upper()
            TBtn.TextColor3 = Color3.new(1, 1, 1)
            TBtn.Font = Enum.Font.GothamBold
            TBtn.TextSize = 10
            TBtn.BackgroundColor3 = Color3.new(1, 1, 1)
            TBtn.AutoButtonColor = false
            Instance.new("UICorner", TBtn).CornerRadius = UDim.new(0, 6)
            local Grad = Instance.new("UIGradient", TBtn)
            Grad.Color = ColorSequence.new(colors.G1, colors.G2)
            Grad.Rotation = 45

            TBtn.MouseButton1Click:Connect(function()
                library.theme = colors
                for _, data in pairs(ActiveGradients) do
                    if typeof(data) == "Instance" then
                        data.Color = ColorSequence.new(colors.G1, colors.G2)
                    elseif type(data) == "table" then
                        if data.Type == "Toggle" and library.flags[data.Flag] then
                            TS:Create(data.Object, TweenInfo.new(0.3), { BackgroundColor3 = colors.G1 }):Play()
                        elseif data.Type == "Slider" then
                            TS:Create(data.Object, TweenInfo.new(0.3), { BackgroundColor3 = colors.G1 }):Play()
                        end
                    end
                end
                if BindBtnRef then
                    BindBtnRef.TextColor3 = colors.G1
                end
                if library.hud and library.hud.updateTheme then
                    library.hud.updateTheme()
                end
                CreateNotify("Celestial", "Тема [" .. name .. "] применена мгновенно!", 2)
            end)
        end

        return themesPage
    end

    -- ============================================================
    -- 8. МЕТОДЫ УПРАВЛЕНИЯ HUD (будут вызваны после создания HUD)
    -- ============================================================
    -- Здесь мы определяем заглушки для методов HUD, которые будут переопределены в setupHUD
    library.hud = {
        setTarget = function() end,
        toggleWatermark = function() end,
        toggleTarget = function() end,
        toggleKeybinds = function() end,
        updateTheme = function() end,
        getWatermark = function() return nil end,
        getTarget = function() return nil end,
        getKeybinds = function() return nil end,
    }

    -- ============================================================
    -- 9. ЗАГРУЗЧИК (Loader)
    -- ============================================================
    local function RunLoader(callback)
        local LoaderGui = Instance.new("ScreenGui", CoreGui)
        LoaderGui.Name = "CelestialLoader"

        local LMain = Instance.new("Frame", LoaderGui)
        LMain.Size = UDim2.new(0, 260, 0, 0)
        LMain.Position = UDim2.new(0.5, -130, 0.5, 0)
        LMain.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        LMain.ClipsDescendants = true
        LMain.BackgroundTransparency = 1
        Instance.new("UICorner", LMain).CornerRadius = UDim.new(0, 15)
        local LStroke = Instance.new("UIStroke", LMain)
        LStroke.Color = Color3.fromRGB(185, 22, 171)
        LStroke.Thickness = 2
        LStroke.Transparency = 1

        local LLogo = Instance.new("ImageLabel", LMain)
        LLogo.Size = UDim2.new(0, 140, 0, 140)
        LLogo.Position = UDim2.new(0.5, -70, 0.35, -70)
        LLogo.BackgroundTransparency = 1
        LLogo.ImageTransparency = 1
        LLogo.Image = GetLoaderImg("celka.png", "https://raw.githubusercontent.com/bron4ik/Uilib/main/celka.png")

        local LStatus = Instance.new("TextLabel", LMain)
        LStatus.Text = "Accessing Modules"
        LStatus.Size = UDim2.new(1, 0, 0, 20)
        LStatus.Position = UDim2.new(0, 0, 0.65, 0)
        LStatus.BackgroundTransparency = 1
        LStatus.TextColor3 = Color3.new(1, 1, 1)
        LStatus.Font = Enum.Font.GothamBold
        LStatus.TextSize = 13
        LStatus.TextTransparency = 1

        local BarBg = Instance.new("Frame", LMain)
        BarBg.Size = UDim2.new(0, 180, 0, 2)
        BarBg.Position = UDim2.new(0.5, -90, 0.8, 0)
        BarBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        BarBg.BackgroundTransparency = 1
        Instance.new("UICorner", BarBg)

        local BarFill = Instance.new("Frame", BarBg)
        BarFill.Size = UDim2.new(0, 0, 1, 0)
        BarFill.BackgroundColor3 = Color3.fromRGB(185, 22, 171)
        Instance.new("UICorner", BarFill)

        local LVer = Instance.new("TextLabel", LMain)
        LVer.Text = "Celestial Recode"
        LVer.Size = UDim2.new(1, 0, 0, 20)
        LVer.Position = UDim2.new(0, 0, 0.9, 0)
        LVer.BackgroundTransparency = 1
        LVer.TextColor3 = Color3.fromRGB(80, 80, 80)
        LVer.Font = Enum.Font.Gotham
        LVer.TextSize = 10
        LVer.TextTransparency = 1

        TS:Create(LMain, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 260, 0, 300),
            Position = UDim2.new(0.5, -130, 0.5, -200),
            BackgroundTransparency = 0
        }):Play()
        TS:Create(LStroke, TweenInfo.new(0.8), { Transparency = 0 }):Play()

        task.wait(0.5)
        TS:Create(LLogo, TweenInfo.new(0.6), { ImageTransparency = 0 }):Play()
        TS:Create(LStatus, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
        TS:Create(BarBg, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()
        TS:Create(LVer, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()

        local stages = { "Accessing Modules", "Downloading Assets", "Running Functions", "Loaded" }
        for i, msg in ipairs(stages) do
            LStatus.Text = msg
            TS:Create(BarFill, TweenInfo.new(0.7), { Size = UDim2.new(i / 4, 0, 1, 0) }):Play()
            task.wait(0.9)
        end

        TS:Create(LLogo, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
        TS:Create(LStatus, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        TS:Create(BarBg, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        TS:Create(LVer, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()

        task.wait(0.2)
        TS:Create(LMain, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 260, 0, 0),
            Position = UDim2.new(0.5, -130, 0.5, -300),
            BackgroundTransparency = 1
        }):Play()
        TS:Create(LStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()

        task.wait(0.7)
        LoaderGui:Destroy()
        callback()
    end

-- ============================================================
-- ЧАСТЬ 2: СОЗДАНИЕ HUD-ЭЛЕМЕНТОВ И ИНТЕГРАЦИЯ
-- ============================================================

-- В этой части мы переопределим library.flags с метатаблицей,
-- создадим setupHUD, который построит Watermark, Target HUD и Keybinds,
-- а также свяжем их с тогглами и темой.

-- Начинаем с того, что сохраним ссылку на старую таблицу флагов,
-- создадим новую с метатаблицей и скопируем старые значения.

-- (Продолжение кода из первой части: мы находимся внутри функции CreateMenu,
-- после определения AddThemesTab и перед RunLoader)

-- ============================================================
-- 8. ПЕРЕОПРЕДЕЛЕНИЕ ФЛАГОВ С МЕТАТАБЛИЦЕЙ
-- ============================================================
local oldFlags = library.flags
local flagCallbacks = {}  -- таблица для хранения колбэков на изменение флагов

library.flags = {}
setmetatable(library.flags, {
    __index = function(t, k)
        return oldFlags[k]
    end,
    __newindex = function(t, k, v)
        oldFlags[k] = v
        -- Вызываем колбэки для этого флага
        if flagCallbacks[k] then
            for _, cb in ipairs(flagCallbacks[k]) do
                pcall(cb, v)
            end
        end
        -- Общий колбэк для всех флагов (опционально)
        if flagCallbacks["*"] then
            for _, cb in ipairs(flagCallbacks["*"]) do
                pcall(cb, k, v)
            end
        end
    end
})

-- Функция для регистрации колбэка на изменение флага
local function onFlagChanged(flag, callback)
    if not flagCallbacks[flag] then
        flagCallbacks[flag] = {}
    end
    table.insert(flagCallbacks[flag], callback)
end

-- Регистрируем универсальный обработчик для отслеживания биндов
onFlagChanged("*", function(flag, value)
    -- Если флаг заканчивается на "_Bind", это бинд
    if flag:sub(-5) == "_Bind" then
        local moduleName = flag:sub(1, -6)
        -- Если модуль активен (есть флаг с таким именем и он true), добавляем бинд
        if library.flags[moduleName] then
            if library.hud and library.hud._addBind then
                local displayName = library.hud._moduleDisplayNames and library.hud._moduleDisplayNames[moduleName] or moduleName
                library.hud._addBind(moduleName, value, displayName)
            end
        else
            -- Если модуль не активен, удаляем бинд
            if library.hud and library.hud._removeBind then
                library.hud._removeBind(moduleName)
            end
        end
    end
    -- Если флаг относится к модулю (например, "Fly"), проверяем наличие бинда
    local bindFlag = flag .. "_Bind"
    if oldFlags[bindFlag] and oldFlags[bindFlag] ~= "NONE" then
        if value then
            -- Модуль включился, добавляем бинд
            if library.hud and library.hud._addBind then
                local displayName = library.hud._moduleDisplayNames and library.hud._moduleDisplayNames[flag] or flag
                library.hud._addBind(flag, oldFlags[bindFlag], displayName)
            end
        else
            -- Модуль выключился, удаляем бинд
            if library.hud and library.hud._removeBind then
                library.hud._removeBind(flag)
            end
        end
    end
end)

-- ============================================================
-- 9. setupHUD (создание Watermark, Target HUD, Keybinds)
-- ============================================================
local function setupHUD()
    -- Удаляем старые HUD-гуи
    for _, name in ipairs({"CelestialHUD", "CelestialWatermarkGui", "CelestialTargetHudGui", "CelestialKeybindsGui"}) do
        if CoreGui:FindFirstChild(name) then CoreGui[name]:Destroy() end
    end

    local hudScreenGui = Instance.new("ScreenGui")
    hudScreenGui.Name = "CelestialHUD"
    hudScreenGui.IgnoreGuiInset = true
    hudScreenGui.ResetOnSpawn = false
    hudScreenGui.DisplayOrder = 99999999
    hudScreenGui.Parent = CoreGui
    table.insert(library._connections, hudScreenGui.Destroying)

    -- Вспомогательная функция для создания фрейма с драгом
    local function CreateDraggableFrame(name, size, position, bgColor)
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.Size = size
        frame.Position = position
        frame.BackgroundColor3 = bgColor
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.ZIndex = 5
        frame.ClipsDescendants = true
        frame.Parent = hudScreenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame

        local dragging, dragInput, dragStart, startPos
        local function registerDrag(object)
            object.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = frame.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end)
            object.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    dragInput = input
                end
            end)
        end
        registerDrag(frame)

        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        return frame, registerDrag
    end

    -- Функция для обводки и свечения
    local function AddStrokeAndGlow(frame)
        local stroke = Instance.new("UIStroke")
        stroke.Color = library.theme.G1
        stroke.Thickness = 1.5
        stroke.Parent = frame

        local glow = Instance.new("ImageLabel")
        glow.Name = "GlowShadow"
        glow.Position = UDim2.new(0, -15, 0, -15)
        glow.Size = UDim2.new(1, 30, 1, 30)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://12974304856"
        glow.ImageColor3 = library.theme.G1
        glow.ImageTransparency = 0.4
        glow.ScaleType = Enum.ScaleType.Slice
        glow.SliceCenter = Rect.new(20, 20, 100, 100)
        glow.ZIndex = 1
        glow.Parent = frame

        return stroke, glow
    end

    -- ===== 1. WATERMARK =====
    local wmFrame, _ = CreateDraggableFrame("Watermark", UDim2.new(0, 100, 0, 32), UDim2.new(0, 20, 0, 20), Color3.fromRGB(10, 10, 12))
    local wmStroke, wmGlow = AddStrokeAndGlow(wmFrame)

    local wmText = Instance.new("TextLabel")
    wmText.AutomaticSize = Enum.AutomaticSize.XY
    wmText.BackgroundTransparency = 1
    wmText.Font = Enum.Font.FredokaOne
    wmText.TextSize = 14
    wmText.TextColor3 = Color3.fromRGB(255, 255, 255)
    wmText.ZIndex = 6
    wmText.Parent = wmFrame

    local pad = Instance.new("UIPadding")
    pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
    pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 14), UDim.new(0, 14)
    pad.Parent = wmFrame

    local fpsCount, lastUpdate, targetWidth = 0, os.clock(), 100
    local wmConnection = RunService.RenderStepped:Connect(function()
        if not library.flags.HUD_Watermark then
            wmFrame.Visible = false
            return
        else
            wmFrame.Visible = true
        end
        fpsCount = fpsCount + 1
        local now = os.clock()
        if now - lastUpdate >= 0.3 then
            local currentFps = math.floor(fpsCount / (now - lastUpdate))
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            wmText.Text = string.format("%s  »  Dev  »  Fps: %d  »  %dms", player.Name, currentFps, ping)
            fpsCount, lastUpdate = 0, now
            task.wait()
            targetWidth = wmText.AbsoluteSize.X + 28
        end
        local curW = wmFrame.Size.X.Offset
        if math.abs(curW - targetWidth) > 1 then
            wmFrame.Size = UDim2.new(0, curW + (targetWidth - curW) * 0.1, 0, 32)
        else
            wmFrame.Size = UDim2.new(0, targetWidth, 0, 32)
        end
    end)
    table.insert(library._connections, wmConnection)

    -- ===== 2. TARGET HUD =====
    local targetFrame, _ = CreateDraggableFrame("Target", UDim2.new(0, 220, 0, 68), UDim2.new(0.5, -110, 0.6, 0), Color3.fromRGB(10, 10, 12))
    local targetStroke, targetGlow = AddStrokeAndGlow(targetFrame)

    -- Аватар
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 48, 0, 48)
    avatar.Position = UDim2.new(0, 10, 0, 10)
    avatar.BackgroundTransparency = 1
    avatar.ZIndex = 6
    avatar.Parent = targetFrame
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 6)
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -80, 0, 18)
    nameLabel.Position = UDim2.new(0, 68, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.FredokaOne
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = player.Name
    nameLabel.ZIndex = 6
    nameLabel.Parent = targetFrame

    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size = UDim2.new(1, -80, 0, 14)
    hpLabel.Position = UDim2.new(0, 68, 0, 26)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Font = Enum.Font.FredokaOne
    hpLabel.TextSize = 11
    hpLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
    hpLabel.TextXAlignment = Enum.TextXAlignment.Left
    hpLabel.ZIndex = 6
    hpLabel.Parent = targetFrame

    local hpBar = Instance.new("Frame")
    hpBar.Size = UDim2.new(1, -78, 0, 12)
    hpBar.Position = UDim2.new(0, 68, 0, 44)
    hpBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    hpBar.ZIndex = 6
    hpBar.Parent = targetFrame
    Instance.new("UICorner", hpBar).CornerRadius = UDim.new(0, 4)

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hpFill.ZIndex = 7
    hpFill.Parent = hpBar
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 4)

    local hpGrad = Instance.new("UIGradient")
    hpGrad.Color = ColorSequence.new(library.theme.G1, library.theme.G2)
    hpGrad.Parent = hpFill

    local targetPlayer = player
    local function updateTarget(playerObj)
        targetPlayer = playerObj or player
        nameLabel.Text = targetPlayer.Name
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
    end

    local hpConnection = RunService.RenderStepped:Connect(function()
        if not library.flags.HUD_Target then
            targetFrame.Visible = false
            return
        else
            targetFrame.Visible = true
        end
        local char = targetPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health and hum.MaxHealth > 0 then
            local hp = hum.Health
            local maxHp = hum.MaxHealth
            hpLabel.Text = "HP: " .. string.format("%.1f", hp)
            TS:Create(hpFill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
            }):Play()
        else
            hpLabel.Text = "HP: 0.0"
            hpFill.Size = UDim2.new(0, 0, 1, 0)
        end
    end)
    table.insert(library._connections, hpConnection)

    -- ===== 3. KEYBINDS =====
    local kbFrame, registerKbDrag = CreateDraggableFrame("Keybinds", UDim2.new(0, 165, 0, 36), UDim2.new(0, 20, 0, 100), Color3.fromRGB(10, 10, 12))
    local kbStroke, kbGlow = AddStrokeAndGlow(kbFrame)

    -- Заголовок с градиентом
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)  -- основа для градиента
    header.BorderSizePixel = 0
    header.ZIndex = 6
    header.Parent = kbFrame
    registerKbDrag(header)

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 6)
    headerCorner.Parent = header

    local headerGrad = Instance.new("UIGradient")
    headerGrad.Color = ColorSequence.new(library.theme.G1, library.theme.G2)
    headerGrad.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.FredokaOne
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.Text = "Keybinds"
    title.ZIndex = 8
    title.Parent = header

    -- Контейнер для списка
    local listContainer = Instance.new("Frame")
    listContainer.Size = UDim2.new(1, 0, 0, 0)
    listContainer.Position = UDim2.new(0, 0, 0, 36)
    listContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    listContainer.BorderSizePixel = 0
    listContainer.ClipsDescendants = true
    listContainer.ZIndex = 6
    listContainer.Visible = false
    listContainer.Parent = kbFrame

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = listContainer

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = listContainer

    local listPad = Instance.new("UIPadding")
    listPad.PaddingTop = UDim.new(0, 12)
    listPad.PaddingBottom = UDim.new(0, 12)
    listPad.PaddingLeft = UDim.new(0, 14)
    listPad.PaddingRight = UDim.new(0, 14)
    listPad.Parent = listContainer

    -- Хранилище активных биндов
    local activeBinds = {}  -- {moduleName = {key, label, element}}
    local activeOrder = {}

    local function updateKeybindsLayout()
        local count = #activeOrder
        local targetHeight = 36
        if count > 0 then
            targetHeight = 36 + (count * 22) + ((count - 1) * 5) + 24
            listContainer.Size = UDim2.new(1, 0, 0, targetHeight - 36)
            listContainer.Visible = true
        else
            listContainer.Size = UDim2.new(1, 0, 0, 0)
            listContainer.Visible = false
        end
        if library.flags.HUD_Keybinds then
            TS:Create(kbFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 165, 0, targetHeight)
            }):Play()
            kbFrame.Visible = true
        else
            kbFrame.Visible = false
        end
    end

    -- Функция добавления бинда (вызывается из обработчика флагов)
    local function addBind(moduleName, key, displayName)
        if activeBinds[moduleName] then return end
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextSize = 13
        lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = string.format("%s [%s]", displayName, key)
        lbl.LayoutOrder = #activeOrder + 1
        lbl.ZIndex = 7
        lbl.Parent = listContainer
        table.insert(activeOrder, moduleName)
        activeBinds[moduleName] = {key = key, label = displayName, element = lbl}
        updateKeybindsLayout()
    end

    local function removeBind(moduleName)
        local data = activeBinds[moduleName]
        if not data then return end
        if data.element then data.element:Destroy() end
        activeBinds[moduleName] = nil
        for i, name in ipairs(activeOrder) do
            if name == moduleName then
                table.remove(activeOrder, i)
                break
            end
        end
        for i, name in ipairs(activeOrder) do
            if activeBinds[name] and activeBinds[name].element then
                activeBinds[name].element.LayoutOrder = i
            end
        end
        updateKeybindsLayout()
    end

    -- Таблица для хранения отображаемых имён модулей
    local moduleDisplayNames = {}

    -- Регистрируем методы для внешнего использования
    library.hud = {
        setTarget = function(playerObj)
            if playerObj and playerObj:IsA("Player") then
                updateTarget(playerObj)
            end
        end,
        toggleWatermark = function(state)
            library.flags.HUD_Watermark = (state ~= nil and state) or not library.flags.HUD_Watermark
            wmFrame.Visible = library.flags.HUD_Watermark
        end,
        toggleTarget = function(state)
            library.flags.HUD_Target = (state ~= nil and state) or not library.flags.HUD_Target
            targetFrame.Visible = library.flags.HUD_Target
        end,
        toggleKeybinds = function(state)
            library.flags.HUD_Keybinds = (state ~= nil and state) or not library.flags.HUD_Keybinds
            if library.flags.HUD_Keybinds then
                kbFrame.Visible = true
                updateKeybindsLayout()
            else
                kbFrame.Visible = false
            end
        end,
        updateTheme = function()
            local c1 = library.theme.G1
            local c2 = library.theme.G2
            for _, stroke in ipairs({wmStroke, targetStroke, kbStroke}) do
                if stroke then stroke.Color = c1 end
            end
            for _, glow in ipairs({wmGlow, targetGlow, kbGlow}) do
                if glow then glow.ImageColor3 = c1 end
            end
            if headerGrad then headerGrad.Color = ColorSequence.new(c1, c2) end
            if hpGrad then hpGrad.Color = ColorSequence.new(c1, c2) end
        end,
        getWatermark = function() return wmFrame end,
        getTarget = function() return targetFrame end,
        getKeybinds = function() return kbFrame end,
        -- Внутренние методы для работы с биндами
        _addBind = addBind,
        _removeBind = removeBind,
        _moduleDisplayNames = moduleDisplayNames,
    }

    -- Устанавливаем флаги по умолчанию
    library.flags.HUD_Watermark = true
    library.flags.HUD_Target = true
    library.flags.HUD_Keybinds = true

    -- Инициализируем видимость
    wmFrame.Visible = true
    targetFrame.Visible = true
    kbFrame.Visible = true
    updateKeybindsLayout()
end

-- ============================================================
-- 10. ДОПОЛНЕНИЕ CreateModule ДЛЯ РЕГИСТРАЦИИ ИМЁН МОДУЛЕЙ
-- ============================================================
-- Мы уже определили CreateModule в первой части, но нам нужно,
-- чтобы при создании модуля его имя регистрировалось в moduleDisplayNames.
-- Так как мы не можем переопределить CreateModule после того, как он был использован в AddSettingsTab,
-- мы сделаем это до вызова AddSettingsTab. Но AddSettingsTab уже определена и использует CreateModule.
-- Поэтому мы переопределим CreateModule прямо сейчас, перед вызовом start.

-- Сохраним старую функцию
local oldCreateModule = CreateModule
CreateModule = function(parent, title, desc, setupFunc, mainCallback)
    -- Регистрируем отображаемое имя
    if library.hud and library.hud._moduleDisplayNames then
        library.hud._moduleDisplayNames[title] = title
    end
    -- Вызываем старую функцию
    return oldCreateModule(parent, title, desc, setupFunc, mainCallback)
end

-- ============================================================
-- 11. ЗАПУСК (start)
-- ============================================================
local function start()
    local menuMethods = BuildMenu()
    for k, v in pairs(menuMethods) do
        library[k] = v
    end
    library._menuOpen = false

    -- Создаём HUD
    setupHUD()

    -- Переопределяем AddSettingsTab и AddThemesTab, чтобы они использовали обновлённый CreateModule?
    -- Но они уже используют CreateModule, который мы переопределили выше, так что всё ок.

    CreateNotify("Celestial", "Меню и HUD загружены! Нажмите " .. MenuKey.Name:upper() .. " для открытия.", 4)
end

-- ============================================================
-- 12. ВЫЗОВ ЗАГРУЗЧИКА ИЛИ ПРЯМОЙ ЗАПУСК
-- ============================================================
if showLoader then
    RunLoader(start)
else
    start()
end

-- ============================================================
-- ВОЗВРАТ БИБЛИОТЕКИ
-- ============================================================
return library

-- Конец первой части
