local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Configuration Table (Syncs seamlessly with either native UI or the premium custom fallback GUI)
local Config = {
    animals = true,
    thunderstruck = true,
    thunderstruckCactus = false,
    lines = true,
    smooth = false,
    smoothSpeed = 0.25
}

-- UI Library Check & Binding (Seamless integration with Matcha's cconstellation/MatchaScripts UI Engine)
local hasUI = (type(UI) == "table" and type(UI.AddTab) == "function")

if hasUI then
    pcall(function()
        UI.RemoveTab("Matcha ESP") -- Clear any cached/duplicate tabs on re-execution
    end)
    
    pcall(function()
        UI.AddTab("Matcha ESP", function(tab)
            local settingsSec = tab:Section("ESP Targets", "Left")
            settingsSec:Toggle("esp_animals", "Animal ESP", Config.animals)
            settingsSec:Toggle("esp_thunderstruck", "Thunderstruck Tree ESP", Config.thunderstruck)
            settingsSec:Toggle("esp_thunderstruck_cactus", "Thunderstruck Cactus ESP", Config.thunderstruckCactus)
            settingsSec:Toggle("esp_lines", "Show Rare Tracers", Config.lines)
            
            local visualSec = tab:Section("Smooth Settings", "Left")
            visualSec:Toggle("esp_smooth", "Smooth Interpolation", Config.smooth)
            visualSec:SliderFloat("esp_smooth_speed", "Interpolation Speed", 0.05, 1.00, Config.smoothSpeed, "%.2f")
        end)
    end)

    -- Bind the P key to open/close (toggle) the executor's native UI menu overlay itself
    pcall(function() UI.SetToggleKey(Enum.KeyCode.P) end)
    pcall(function() UI.SetToggleKey(0x50) end) -- Virtual key code for P key
    pcall(function() UI.SetOpenKey(Enum.KeyCode.P) end)
    pcall(function() UI.SetOpenKey(0x50) end)
    pcall(function() UI.SetBind(Enum.KeyCode.P) end)
    pcall(function() UI.SetBind(0x50) end)
end

-- =====================================
-- PREMIUM DRAGGING UTILITY
-- =====================================
local function makeDraggable(frame, parent)
    parent = parent or frame
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    parent.InputBegan:Connect(function(input)
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

    parent.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- =====================================
-- DETAILED PURE-LUA FALLBACK GUI CONSTRUCTOR
-- =====================================
local customGui = nil
if not hasUI then
    local targetParent = game:GetService("CoreGui") or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    if targetParent then
        -- Purge any duplicate or stale custom GUI frames from previous runs
        local oldGui = targetParent:FindFirstChild("MatchaESPGui")
        if oldGui then pcall(function() oldGui:Destroy() end) end

        -- Disconnect stale toggle listener connections
        if _G.MatchaESPCustomGuiConnection then
            pcall(function() _G.MatchaESPCustomGuiConnection:Disconnect() end)
            _G.MatchaESPCustomGuiConnection = nil
        end

        local gui = Instance.new("ScreenGui")
        gui.Name = "MatchaESPGui"
        gui.ResetOnSpawn = false
        gui.Parent = targetParent
        customGui = gui

        local main = Instance.new("Frame")
        main.Name = "MainFrame"
        main.Size = UDim2.new(0, 320, 0, 480) -- Increased height to fit new aimbot settings
        main.Position = UDim2.new(0.05, 0, 0.2, 0)
        main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        main.BorderSizePixel = 0
        main.Active = true
        main.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = main

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(60, 60, 80)
        stroke.Thickness = 1.5
        stroke.Parent = main

        -- Title Header Bar (Used for dragging)
        local titleBar = Instance.new("Frame")
        titleBar.Size = UDim2.new(1, 0, 0, 45)
        titleBar.BackgroundTransparency = 1
        titleBar.Parent = main

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 1, 0)
        title.Text = "🌌 Matcha ESP & Aimbot"
        title.TextColor3 = Color3.fromRGB(255, 190, 220)
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.BackgroundTransparency = 1
        title.Parent = titleBar

        local subTitle = Instance.new("TextLabel")
        subTitle.Size = UDim2.new(1, 0, 0, 15)
        subTitle.Position = UDim2.new(0, 0, 0, 30)
        subTitle.Text = "[ Press 'P' to Toggle Menu Overlay ]"
        subTitle.TextColor3 = Color3.fromRGB(160, 160, 180)
        subTitle.TextSize = 9
        subTitle.Font = Enum.Font.GothamMedium
        subTitle.BackgroundTransparency = 1
        subTitle.Parent = titleBar

        -- Settings container with ScrollFrame to handle all options
        local container = Instance.new("ScrollingFrame")
        container.Size = UDim2.new(1, -10, 1, -60)
        container.Position = UDim2.new(0, 5, 0, 55)
        container.BackgroundTransparency = 1
        container.ScrollBarThickness = 4
        container.CanvasSize = UDim2.new(0, 0, 0, 450)
        container.Parent = main

        local layout = Instance.new("UIListLayout")
        layout.Spacing = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.PaddingLeft = UDim.new(0, 5)
        layout.PaddingRight = UDim.new(0, 5)
        layout.Parent = container

        -- Toggle Button Builder
        local function addToggle(id, labelText, defaultVal)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 32)
            frame.BackgroundTransparency = 1
            frame.Parent = container

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Text = "  " .. labelText
            label.TextColor3 = Color3.fromRGB(240, 240, 240)
            label.TextSize = 13
            label.Font = Enum.Font.GothamMedium
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1
            label.Parent = frame

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0.25, 0, 0.8, 0)
            button.Position = UDim2.new(0.75, 0, 0.1, 0)
            button.Text = defaultVal and "ON" or "OFF"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.TextSize = 11
            button.Font = Enum.Font.GothamBold
            button.BackgroundColor3 = defaultVal and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(75, 75, 85)
            button.BorderSizePixel = 0
            button.Parent = frame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = button

            button.MouseButton1Click:Connect(function()
                Config[id] = not Config[id]
                button.Text = Config[id] and "ON" or "OFF"
                button.BackgroundColor3 = Config[id] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(75, 75, 85)
            end)
        end

        -- Slider Builder
        local function addSlider(id, labelText, min, max, defaultVal, isInt)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 42)
            frame.BackgroundTransparency = 1
            frame.Parent = container

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 0.5, 0)
            label.Text = "  " .. labelText
            label.TextColor3 = Color3.fromRGB(240, 240, 240)
            label.TextSize = 12
            label.Font = Enum.Font.GothamMedium
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1
            label.Parent = frame

            local valLabel = Instance.new("TextLabel")
            valLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
            valLabel.Position = UDim2.new(0.7, 0, 0, 0)
            valLabel.Text = string.format(isInt and "%.0f" or "%.2f", defaultVal)
            valLabel.TextColor3 = Color3.fromRGB(255, 190, 220)
            valLabel.TextSize = 12
            valLabel.Font = Enum.Font.GothamBold
            valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.BackgroundTransparency = 1
            valLabel.Parent = frame

            local sliderBar = Instance.new("TextButton")
            sliderBar.Size = UDim2.new(1, -10, 0, 6)
            sliderBar.Position = UDim2.new(0, 5, 0.6, 0)
            sliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            sliderBar.BorderSizePixel = 0
            sliderBar.Text = ""
            sliderBar.Parent = frame

            local barCorner = Instance.new("UICorner")
            barCorner.CornerRadius = UDim.new(0, 3)
            barCorner.Parent = sliderBar

            local sliderFill = Instance.new("Frame")
            local startScale = (defaultVal - min) / (max - min)
            sliderFill.Size = UDim2.new(startScale, 0, 1, 0)
            sliderFill.BackgroundColor3 = Color3.fromRGB(255, 120, 180)
            sliderFill.BorderSizePixel = 0
            sliderFill.Parent = sliderBar

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 3)
            fillCorner.Parent = sliderFill

            local dragging = false
            local function updateVal(input)
                local scale = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                sliderFill.Size = UDim2.new(scale, 0, 1, 0)
                local value = min + (max - min) * scale
                if isInt then value = math.floor(value) end
                Config[id] = value
                valLabel.Text = string.format(isInt and "%.0f" or "%.2f", value)
            end

            sliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateVal(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateVal(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
        end

        -- Populate widgets
        addToggle("animals", "Animal ESP", Config.animals)
        addToggle("thunderstruck", "Thunderstruck Tree ESP", Config.thunderstruck)
        addToggle("thunderstruckCactus", "Thunderstruck Cactus ESP", Config.thunderstruckCactus)
        addToggle("lines", "Show Rare Tracers", Config.lines)

        -- Smooth Rendering
        addToggle("smooth", "Smooth Interpolation", Config.smooth)
        addSlider("smoothSpeed", "Interpolation Speed", 0.05, 1.00, Config.smoothSpeed, false)

        -- Enable Dragging
        makeDraggable(main, titleBar)

        -- Listen for Keyboard Menu Toggle Key (P)
        local keyBindConnection
        keyBindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.P then
                main.Visible = not main.Visible
            end
        end)
        _G.MatchaESPCustomGuiConnection = keyBindConnection
    end
end

-- Helper to safely query active GUI settings with local configuration fallbacks
local function GetUIValue(id, fallback)
    if hasUI then
        local success, val = pcall(function() return UI.GetValue(id) end)
        if success and val ~= nil then
            return val
        end
    end

    -- Direct fallback query to custom config dictionary
    local shortId = string.gsub(id, "esp_", "")
    if shortId == "animals" then return Config.animals end
    if shortId == "thunderstruck" then return Config.thunderstruck end
    if shortId == "thunderstruck_cactus" then return Config.thunderstruckCactus end
    if shortId == "lines" then return Config.lines end
    if shortId == "smooth" then return Config.smooth end
    if shortId == "smooth_speed" then return Config.smoothSpeed end
    
    if id == "aim_enabled" then return Config.aimbot end
    if id == "aim_prediction" then return Config.aimPrediction end
    if id == "aim_velocity" then return Config.aimVelocity end
    if id == "aim_fov" then return Config.aimFOV end
    if id == "aim_smoothness" then return Config.aimSmoothness end
    
    return fallback
end

-- Generate a unique execution ID to safely terminate older loops/threads on reload
local scriptID = math.random()
_G.MatchaESPScriptID = scriptID

-- Global drawing registration for clean teardowns
local activeDrawings = {}
_G.MatchaActiveDrawings = activeDrawings

-- Disconnect any running RenderStepped loops from previous Matcha ESP runs
if _G.MatchaESPConnection then
    pcall(function() _G.MatchaESPConnection:Disconnect() end)
    _G.MatchaESPConnection = nil
end

-- Completely purge drawings from previous executions to avoid memory leaks/crashes
if _G.MatchaHUDText then
    pcall(function() _G.MatchaHUDText.Visible = false end)
    pcall(function()
        if type(_G.MatchaHUDText.Remove) == "function" then
            _G.MatchaHUDText:Remove()
        elseif type(_G.MatchaHUDText.Destroy) == "function" then
            _G.MatchaHUDText:Destroy()
        end
    end)
    _G.MatchaHUDText = nil
end

if _G.MatchaFOVCircle then
    pcall(function() _G.MatchaFOVCircle.Visible = false end)
    pcall(function()
        if type(_G.MatchaFOVCircle.Remove) == "function" then _G.MatchaFOVCircle:Remove() else _G.MatchaFOVCircle:Destroy() end
    end)
    _G.MatchaFOVCircle = nil
end

if _G.MatchaActiveDrawingsOld then
    for _, draw in pairs(_G.MatchaActiveDrawingsOld) do
        pcall(function()
            if draw.text then
                draw.text.Visible = false
                if type(draw.text.Remove) == "function" then draw.text:Remove() else draw.text:Destroy() end
            end
            if draw.line then
                draw.line.Visible = false
                if type(draw.line.Remove) == "function" then draw.line:Remove() else draw.line:Destroy() end
            end
        end)
    end
    _G.MatchaActiveDrawingsOld = nil
end
_G.MatchaActiveDrawingsOld = activeDrawings

-- Teleport / Serverhop Cleanup Handler (Crucial to prevent Roblox hard crashes during teleport)
local teleportConnection
local hasTeleportEvent, teleportEvent = pcall(function() return Players.LocalPlayer.OnTeleport end)
if hasTeleportEvent and teleportEvent then
    pcall(function()
        teleportConnection = teleportEvent:Connect(function(state)
            if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
                pcall(function()
                    if _G.MatchaESPConnection then _G.MatchaESPConnection:Disconnect() end
                    if _G.MatchaESPCustomGuiConnection then _G.MatchaESPCustomGuiConnection:Disconnect() end
                    if customGui then pcall(function() customGui:Destroy() end) end
                    if _G.MatchaHUDText then
                        _G.MatchaHUDText.Visible = false
                        if type(_G.MatchaHUDText.Remove) == "function" then _G.MatchaHUDText:Remove() else _G.MatchaHUDText:Destroy() end
                    end
                    if _G.MatchaFOVCircle then
                        _G.MatchaFOVCircle.Visible = false
                        if type(_G.MatchaFOVCircle.Remove) == "function" then _G.MatchaFOVCircle:Remove() else _G.MatchaFOVCircle:Destroy() end
                    end
                    for _, draw in pairs(activeDrawings) do
                        if draw.text then
                            draw.text.Visible = false
                            if type(draw.text.Remove) == "function" then draw.text:Remove() else draw.text:Destroy() end
                        end
                        if draw.line then
                            draw.line.Visible = false
                            if type(draw.line.Remove) == "function" then draw.line:Remove() else draw.line:Destroy() end
                        end
                    end
                    if teleportConnection then teleportConnection:Disconnect() end
                end)
            end
        end)
    end)
end

-- Robust Game State Yield (WaitForChild ensures it handles slower loads or server hops perfectly)
local WORKSPACE_EntitiesFolder = workspace:WaitForChild("WORKSPACE_Entities", 20)
if not WORKSPACE_EntitiesFolder then return end

local AnimalsFolder = WORKSPACE_EntitiesFolder:WaitForChild("Animals", 20)
if not AnimalsFolder then return end

local excludedNames = {
    Horse = true,
    WendigoHorse = true,
    SkeletonHorse = true,
    Cow = true,
    Capybara = true,
    Reindeer = true,
    Raindeer = true,
    ReindeerHorse = true,
    WildHorse = true,
    Mustang = true,
    Foal = true
}

local trackedItems = {}
local ignoredTrees = {}

-- Legendary Tracker State Variables
local timeOfLastSpawn = nil
local activeLegendaryInstance = nil
local activeLegendaryName = ""

local hudText = nil
pcall(function()
    hudText = Drawing.new("Text")
    if hudText then
        hudText.Size = 16
        hudText.Outline = true
        hudText.Center = true
        hudText.Color = Color3.new(1, 1, 1)
        pcall(function() hudText.Font = 2 end) -- Sleek, smooth vector font (not pixelated/Minecraft block style)
        hudText.Visible = true
    end
end)
_G.MatchaHUDText = hudText

local fovCircle = nil
pcall(function()
    fovCircle = Drawing.new("Circle")
    if fovCircle then
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Thickness = 1
        fovCircle.Filled = false
        fovCircle.Transparency = 0.4
        fovCircle.Visible = false
    end
end)
_G.MatchaFOVCircle = fovCircle

local vegetationFolders = {}
local geoFolder = workspace:FindFirstChild("WORKSPACE_Geometry")
if geoFolder then
    for _, region in pairs(geoFolder:GetChildren()) do
        for _, subFolder in pairs(region:GetChildren()) do
            if subFolder.Name == "Vegetation" then
                table.insert(vegetationFolders, subFolder)
            else
                for _, deepFolder in pairs(subFolder:GetChildren()) do
                    if deepFolder.Name == "Vegetation" then
                        table.insert(vegetationFolders, deepFolder)
                    end
                end
            end
        end
    end
end
-- Also add Entities folder to catch dynamically spawned trees
table.insert(vegetationFolders, WORKSPACE_EntitiesFolder)

-- Add the NaturalResources folder where rare logs actually spawn!
local natResGeo = geoFolder and geoFolder:FindFirstChild("NaturalResources", true)
if natResGeo then table.insert(vegetationFolders, natResGeo) end

local natResEnt = WORKSPACE_EntitiesFolder:FindFirstChild("NaturalResources", true)
if natResEnt then table.insert(vegetationFolders, natResEnt) end

local function clearESP(model)
    local draw = activeDrawings[model]
    if draw then
        if type(draw) == "table" then
            if draw.text then
                pcall(function() draw.text.Visible = false end)
                pcall(function()
                    pcall(function()
                        if type(draw.text.Remove) == "function" then
                            draw.text:Remove()
                        elseif type(draw.text.Destroy) == "function" then
                            draw.text:Destroy()
                        end
                    end)
                end)
            end
            if draw.line then
                pcall(function() draw.line.Visible = false end)
                pcall(function()
                    pcall(function()
                        if type(draw.line.Remove) == "function" then
                            draw.line:Remove()
                        elseif type(draw.line.Destroy) == "function" then
                            draw.line:Destroy()
                        end
                    end)
                end)
            end
        else
            pcall(function() draw.Visible = false end)
            pcall(function()
                pcall(function()
                    if type(draw.Remove) == "function" then
                        draw:Remove()
                    elseif type(draw.Destroy) == "function" then
                        draw:Destroy()
                    end
                end)
            end)
        end
        activeDrawings[model] = nil
    end
    trackedItems[model] = nil
end


-- =====================================
-- ANIMAL SCANNER
-- =====================================
task.spawn(function()
    while true do
        -- Terminate task instantly if a new script version has been run
        if _G.MatchaESPScriptID ~= scriptID then break end

        local currentlyAlive = {}
        local showAnimals = GetUIValue("esp_animals", Config.animals)

        if AnimalsFolder and showAnimals then
            local count = 0
            for _, item in pairs(AnimalsFolder:GetChildren()) do
                count = count + 1
                if count % 20 == 0 then task.wait() end

                if item:IsA("Model") and not excludedNames[item.Name] then
                    currentlyAlive[item] = true
                    if not trackedItems[item] then
                        local ref = item.PrimaryPart or item:FindFirstChild("HumanoidRootPart") or
                            item:FindFirstChildWhichIsA("BasePart", true)
                        if ref then
                            trackedItems[item] = {
                                reference = ref,
                                healthObj = item:FindFirstChild("Health"),
                                label = item.Name,
                                isResource = false
                            }
                            local hpObj = item:FindFirstChild("Health")
                            if hpObj and hpObj.Value > 300 then
                                activeLegendaryInstance = item
                                activeLegendaryName = item.Name
                                timeOfLastSpawn = os.time()
                            end
                        end
                    end
                end
            end
        end

        for model, data in pairs(trackedItems) do
            if not data.isResource then
                if not showAnimals or not currentlyAlive[model] or not model.Parent then
                    clearESP(model)
                end
            end
        end

        task.wait(2)
    end
end)

-- =====================================
-- THUNDERSTRUCK TREE & CACTUS SCANNER
-- =====================================
task.spawn(function()
    while true do
        -- Terminate task instantly if a new script version has been run
        if _G.MatchaESPScriptID ~= scriptID then break end

        local currentlyAliveResources = {}
        local showThunder = GetUIValue("esp_thunderstruck", Config.thunderstruck)
        local showThunderCactus = GetUIValue("esp_thunderstruck_cactus", Config.thunderstruckCactus)

        if showThunder or showThunderCactus then
            for _, folder in pairs(vegetationFolders) do
                task.wait(0.5)
                if _G.MatchaESPScriptID ~= scriptID then break end

                local success, children = pcall(function() return folder:GetChildren() end)
                if success and children then
                    local batchCount = 0
                    for _, item in pairs(children) do
                        batchCount = batchCount + 1
                        if batchCount % 100 == 0 then task.wait() end -- Prevent freezing while scanning

                        if not ignoredTrees[item] then
                            if item.Name then
                                local n = string.lower(item.Name)
                                local isThunder = (string.find(n, "thunderstruck") or string.find(n, "lightning"))
                                    and not string.find(n, "mustache")
                                    and not string.find(n, "hair")
                                    and not string.find(n, "neon")
                                
                                local isThunderTree = isThunder and not string.find(n, "cactus")
                                local isThunderCactus = isThunder and string.find(n, "cactus")

                                if (isThunderTree and showThunder) or (isThunderCactus and showThunderCactus) then
                                    currentlyAliveResources[item] = true
                                    if not trackedItems[item] then
                                        local ref = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
                                        if ref then
                                            trackedItems[item] = {
                                                reference = ref,
                                                healthObj = item:FindFirstChild("Health"),
                                                label = item.Name,
                                                isResource = true,
                                                type = isThunderCactus and "ThunderstruckCactus" or "Thunderstruck"
                                            }
                                        end
                                    end
                                else
                                    ignoredTrees[item] = true
                                end
                            end
                        elseif trackedItems[item] then
                            currentlyAliveResources[item] = true
                        end
                    end
                end
            end
        end

        for model, data in pairs(trackedItems) do
            if data.isResource then
                local shouldKeep = false
                if data.type == "Thunderstruck" and showThunder and currentlyAliveResources[model] then
                    shouldKeep = true
                elseif data.type == "ThunderstruckCactus" and showThunderCactus and currentlyAliveResources[model] then
                    shouldKeep = true
                end

                if not shouldKeep or not model.Parent then
                    clearESP(model)
                end
            end
        end

        task.wait(5)
    end
end)

-- =====================================
-- OPTIMIZED W2S RESOLVER
-- =====================================
local W2S_Func = nil
if type(WorldToScreen) == "function" then
    W2S_Func = WorldToScreen
elseif type(worldtoscreen) == "function" then
    W2S_Func = worldtoscreen
else
    W2S_Func = function(pos)
        if workspace.CurrentCamera then
            return workspace.CurrentCamera:WorldToViewportPoint(pos)
        end
        return nil, false
    end
end

local function SafeWorldToScreen(worldPos)
    local success, pos, onScreen = pcall(W2S_Func, worldPos)
    if success then return pos, onScreen end
    return nil, false
end

-- =====================================
-- RENDER LOOP
-- =====================================
RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local screenBottom = Vector2.new(viewportSize.X / 2, viewportSize.Y)

    -- Dynamic UI Config Polling
    local activeSmooth = GetUIValue("esp_smooth", Config.smooth)
    local activeSpeed = GetUIValue("esp_smooth_speed", Config.smoothSpeed)
    local showLines = GetUIValue("esp_lines", Config.lines)

    -- HUD POSITIONING & RENDER
    if hudText then
        local screenWidth = viewportSize.X
        -- Position at top center, Y = 50 (neatly under or next to the hostile/friendly bar)
        hudText.Position = Vector2.new(screenWidth / 2, 50)
        
        -- Check if active legendary is still alive/valid
        if activeLegendaryInstance then
            local success, parent = pcall(function() return activeLegendaryInstance.Parent end)
            local hpObj = activeLegendaryInstance:FindFirstChild("Health")
            local healthVal = hpObj and hpObj.Value or 0
            if not success or not parent or healthVal <= 0 then
                activeLegendaryInstance = nil
                activeLegendaryName = ""
            end
        end
        
        if activeLegendaryInstance then
            -- Active Legendary Alert State
            local myChar = Players.LocalPlayer and Players.LocalPlayer.Character
            local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChildWhichIsA("BasePart"))
            local distanceText = "Unknown"
            
            local legRef = activeLegendaryInstance.PrimaryPart or activeLegendaryInstance:FindFirstChild("HumanoidRootPart") or activeLegendaryInstance:FindFirstChildWhichIsA("BasePart", true)
            if myRoot and legRef then
                local dist = (myRoot.Position - legRef.Position).Magnitude
                distanceText = string.format("%.0fm", dist)
            end
            
            local hpObj = activeLegendaryInstance:FindFirstChild("Health")
            local maxHp = 450 -- Typical legendary health in The Wild West
            local healthVal = hpObj and hpObj.Value or maxHp
            
            -- Pulse effect using os.clock()
            local pulse = math.floor(os.clock() * 2) % 2 == 0
            if pulse then
                hudText.Color = Color3.fromRGB(255, 60, 180) -- Hot Pink
            else
                hudText.Color = Color3.fromRGB(255, 255, 255) -- White
            end
            
            hudText.Text = string.format("⚠️ LEGENDARY ACTIVE: %s (%s away) | HP: %.0f/%.0f ⚠️", string.upper(activeLegendaryName), distanceText, healthVal, maxHp)
            hudText.Visible = true
        else
            -- Clean HUD Line State
            local uptime = workspace.DistributedGameTime or os.clock() or 0
            local hrs = math.floor(uptime / 3600)
            local mins = math.floor((uptime % 3600) / 60)
            local secs = math.floor(uptime % 60)
            local uptimeStr = string.format("%02dh %02dm %02ds", hrs, mins, secs)
            
            local playerList = Players:GetPlayers()
            local playerCount = #playerList
            local playersStr = tostring(playerCount)
            
            local spawnChance = 0
            if playerCount >= 8 then
                -- Calculate time elapsed since last legendary spawn, or server uptime if none recorded
                local elapsedSeconds = uptime
                if timeOfLastSpawn then
                    elapsedSeconds = os.time() - timeOfLastSpawn
                end
                local elapsedHours = elapsedSeconds / 3600
                spawnChance = math.min(100, elapsedHours * 12)
                playersStr = playersStr .. " (Eligible)"
                hudText.Color = Color3.fromRGB(255, 190, 220) -- Soft Pink theme
            else
                playersStr = playersStr .. " (⚠️ Paused, <8 Players)"
                hudText.Color = Color3.fromRGB(255, 80, 80) -- Light Red theme
            end
            
            local lastSpawnStr = "None"
            if timeOfLastSpawn then
                local lastElapsed = os.time() - timeOfLastSpawn
                if lastElapsed < 60 then
                    lastSpawnStr = string.format("%ds ago", lastElapsed)
                elseif lastElapsed < 3600 then
                    lastSpawnStr = string.format("%dm ago", math.floor(lastElapsed / 60))
                else
                    lastSpawnStr = string.format("%.1fh ago", lastElapsed / 3600)
                end
            end
            
            hudText.Text = string.format("[ ⏱️ Server Uptime: %s | 👥 Players: %s | 🍀 Est. Spawn Chance: ~%.0f%% | ⏳ Last Spawn: %s ]", uptimeStr, playersStr, spawnChance, lastSpawnStr)
            hudText.Visible = true
        end
    end

    for item, data in pairs(trackedItems) do
        if data.reference and data.reference.Parent then
            local refPos = data.reference.Position
            local targetPos = Vector3.new(refPos.X, refPos.Y + 1, refPos.Z)

            local draw = activeDrawings[item]
            if not draw then
                draw = {
                    text = nil,
                    line = nil,
                    currentWorldPos = nil
                }
                pcall(function()
                    draw.text = Drawing.new("Text")
                    if draw.text then
                        draw.text.Size = 18
                        draw.text.Outline = true
                        draw.text.Center = true
                        pcall(function() draw.text.Font = 2 end) -- Sleek, smooth vector font (not pixelated/Minecraft block style)
                    end
                end)
                activeDrawings[item] = draw
            end

            -- Smoothly interpolate positions in 3D world space to completely lock positions relative to camera matrix
            if activeSmooth then
                if not draw.currentWorldPos or (draw.currentWorldPos - targetPos).Magnitude > 150 then
                    draw.currentWorldPos = targetPos
                else
                    draw.currentWorldPos = draw.currentWorldPos + (targetPos - draw.currentWorldPos) * activeSpeed
                end
            else
                draw.currentWorldPos = targetPos
            end

            local pos, onScreen = SafeWorldToScreen(draw.currentWorldPos)

            if onScreen and pos then
                local screenPos = Vector2.new(pos.X, pos.Y)
                local health = data.healthObj and data.healthObj.Value or 0
                local isHighValue = false

                if draw.text then
                    pcall(function()
                        if data.isResource then
                            if data.type == "ThunderstruckCactus" then
                                draw.text.Color = Color3.new(0.2, 1, 0.2) -- Vibrant Green for Cactus
                                draw.text.Text = string.format("⚡🌵 %s", item.Name)
                                isHighValue = true
                            else
                                draw.text.Color = Color3.new(1, 0.75, 0.85) -- Pink for Thunderstruck
                                draw.text.Text = string.format("⚡ %s", item.Name)
                                isHighValue = true
                            end
                        else
                            local lowerName = string.lower(item.Name)
                            if string.find(lowerName, "thunder") or string.find(lowerName, "lightning") then
                                draw.text.Color = Color3.new(1, 0.75, 0.85) -- Pink
                                draw.text.Text = string.format("⚡ %s (%.0f HP)", item.Name, health)
                                isHighValue = true
                            elseif health > 300 then
                                draw.text.Color = Color3.new(1, 0.75, 0.85)
                                draw.text.Text = string.format("%s [LEGENDARY] (%.0f HP)", item.Name, health)
                                isHighValue = true
                            else
                                draw.text.Color = Color3.new(1, 1, 0)
                                draw.text.Text = string.format("%s (%.0f HP)", item.Name, health)
                            end
                        end

                        draw.text.Position = screenPos
                        draw.text.Visible = true
                    end)
                end

                -- Re-evaluate high value criteria in case draw.text was skipped or errored
                if data.isResource then
                    if data.type ~= "ThunderstruckCactus" then
                        isHighValue = true
                    end
                else
                    local lowerName = string.lower(item.Name)
                    if string.find(lowerName, "thunder") or string.find(lowerName, "lightning") or health > 300 then
                        isHighValue = true
                    end
                end

                if isHighValue and showLines then
                    if not draw.line then
                        pcall(function()
                            draw.line = Drawing.new("Line")
                        end)
                    end
                    if draw.line then
                        pcall(function()
                            draw.line.Thickness = 1.5
                            draw.line.Transparency = 0.8
                            draw.line.Color = Color3.new(1, 0.75, 0.85)
                            draw.line.From = screenBottom
                            draw.line.To = screenPos
                            draw.line.Visible = true
                        end)
                    end
                else
                    if draw.line then
                        pcall(function() draw.line.Visible = false end)
                    end
                end
            else
                if draw.text then pcall(function() draw.text.Visible = false end) end
                if draw.line then pcall(function() draw.line.Visible = false end) end
            end
        else
            clearESP(item)
        end
    end
end)
