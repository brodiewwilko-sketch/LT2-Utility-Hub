
--[[
    LT2 UTILITY HUB
    Client-side helper rebuild
    Right Shift = Show / Hide
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local function getRoot()
    Character = Player.Character or Character
    return Character:FindFirstChild("HumanoidRootPart")
end

local function notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "LT2 Utility Hub",
            Text = tostring(msg),
            Duration = 4
        })
    end)
end

-- GUI
local old = game:GetService("CoreGui"):FindFirstChild("LT2UtilityHub")
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "LT2UtilityHub"
Gui.ResetOnSpawn = false

pcall(function()
    Gui.Parent = gethui()
end)
if not Gui.Parent then
    Gui.Parent = game:GetService("CoreGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(570, 390)
Main.Position = UDim2.new(0.5, -285, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
Main.BorderSizePixel = 0
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 9)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Parent = Main

local rainbow = true
task.spawn(function()
    local hue = 0
    while Gui.Parent do
        hue = (hue + 0.003) % 1
        Stroke.Color = Color3.fromHSV(hue, 0.9, 1)
        task.wait()
    end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 42)
Title.BackgroundTransparency = 1
Title.Text = "LT2  |  UTILITY HUB"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local Side = Instance.new("Frame")
Side.Position = UDim2.fromOffset(10, 52)
Side.Size = UDim2.fromOffset(135, 325)
Side.BackgroundColor3 = Color3.fromRGB(30, 30, 39)
Side.BorderSizePixel = 0
Side.Parent = Main
Instance.new("UICorner", Side).CornerRadius = UDim.new(0, 7)

local Content = Instance.new("ScrollingFrame")
Content.Position = UDim2.fromOffset(155, 52)
Content.Size = UDim2.fromOffset(405, 325)
Content.BackgroundColor3 = Color3.fromRGB(30, 30, 39)
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.CanvasSize = UDim2.new()
Content.Parent = Main
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 7)

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.Parent = Content

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 10)
end)

local function clear()
    for _, v in ipairs(Content:GetChildren()) do
        if v:IsA("GuiObject") and v ~= Layout then
            v:Destroy()
        end
    end
end

local function label(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 29)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(220, 220, 230)
    l.TextSize = 13
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = Content
    return l
end

local function button(text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 34)
    b.BackgroundColor3 = Color3.fromRGB(49, 49, 64)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamSemibold
    b.Text = text
    b.Parent = Content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then notify("Error: " .. tostring(err)) end
    end)
    return b
end

local SavedPosition = nil
local SelectedTree = nil
local SelectedWood = "Oak"
local Flying = false
local FlySpeed = 65
local FlyConnection = nil
local FlyVelocity = nil
local FlyGyro = nil

local WoodTypes = {
    "Oak", "Elm", "Birch", "Walnut", "Cherry",
    "Fir", "Pine", "Koa", "Palm", "Snow Glow",
    "Frost", "Sinister", "Fire", "Cavecrawler",
    "Spook", "Lava", "Gold", "Silver"
}

local function savePosition()
    local root = getRoot()
    if not root then
        notify("Character root not found")
        return
    end
    SavedPosition = root.CFrame
    notify("Position saved")
end

local function returnPosition()
    local root = getRoot()
    if not root then return notify("Character root not found") end
    if not SavedPosition then return notify("Save a position first") end
    root.CFrame = SavedPosition
    notify("Returned to saved position")
end

-- Tree scanner
local function scanTrees()
    local results = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = string.lower(obj.Name)
            if string.find(name, "tree") or
               table.find(WoodTypes, obj.Name) then
                table.insert(results, obj)
            end
        end
    end
    return results
end

-- Tabs
local tabs = {
    "Home", "Bring Wood", "Trees", "Teleports",
    "Movement", "End Times", "Inventory", "Misc"
}

local function addTab(name, index)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 34)
    b.Position = UDim2.fromOffset(5, 5 + (index - 1) * 39)
    b.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = name
    b.TextSize = 12
    b.Font = Enum.Font.GothamSemibold
    b.Parent = Side
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end

local function showHome()
    clear()
    label("HOME")
    button("Save current position", savePosition)
    button("Return to saved position", returnPosition)
    button("Refresh character", function()
        Character = Player.Character or Character
        notify("Character refreshed")
    end)
    button("Show player information", function()
        local hum = Character:FindFirstChildOfClass("Humanoid")
        notify("Player: " .. Player.Name ..
            " | Health: " .. (hum and math.floor(hum.Health) or "?"))
    end)
    label("Right Shift toggles the hub")
end

local function showBring()
    clear()
    label("BRING WOOD HELPER")
    label("Select a wood type in the Trees tab.")
    button("Save my current position", savePosition)
    button("Teleport near selected tree", function()
        if not SelectedTree or not SelectedTree.Parent then
            return notify("Select a currently loaded tree first")
        end
        local root = getRoot()
        local part = SelectedTree.PrimaryPart or
            SelectedTree:FindFirstChildWhichIsA("BasePart", true)
        if not root or not part then
            return notify("Tree has no usable position")
        end
        if not SavedPosition then SavedPosition = root.CFrame end
        root.CFrame = part.CFrame * CFrame.new(0, 0, 8)
        notify("Moved near " .. SelectedTree.Name)
    end)
    button("Return to saved position", returnPosition)
    button("Clear selected tree", function()
        SelectedTree = nil
        notify("Tree selection cleared")
    end)
    label("Chopping and log transport must use the game's authorised controls.")
    label("This helper does not duplicate axes or force server-side log movement.")
end

local function showTrees()
    clear()
    label("WOOD TYPES")
    for _, wood in ipairs(WoodTypes) do
        button("Select: " .. wood, function()
            SelectedWood = wood
            notify("Selected wood: " .. wood)
        end)
    end
    label("CURRENTLY LOADED TREES")
    button("Scan loaded trees", function()
        local trees = scanTrees()
        clear()
        label("Found " .. #trees .. " possible trees")
        for _, tree in ipairs(trees) do
            button("Select " .. tree.Name, function()
                SelectedTree = tree
                notify("Selected " .. tree.Name)
            end)
        end
    end)
end

local function showTeleports()
    clear()
    label("DISCOVERED LOCATIONS")
    local locations = {
        "Wood R Us", "Link's Logic", "Fancy Furnishings",
        "Boxed Cars", "Bob's Shack"
    }

    for _, name in ipairs(locations) do
        button("Find: " .. name, function()
            local found
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if string.find(string.lower(obj.Name), string.lower(name)) then
                    if obj:IsA("BasePart") then
                        found = obj
                        break
                    elseif obj:IsA("Model") then
                        found = obj.PrimaryPart or
                            obj:FindFirstChildWhichIsA("BasePart", true)
                        if found then break end
                    end
                end
            end
            if not found then
                return notify(name .. " was not found in loaded objects")
            end
            local root = getRoot()
            if root then
                root.CFrame = found.CFrame * CFrame.new(0, 5, 0)
                notify("Teleported near " .. name)
            end
        end)
    end

    button("Scan secret locations", function()
        local matches = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            if string.find(n, "cave") or string.find(n, "secret")
                or string.find(n, "hidden") then
                if obj:IsA("BasePart") then
                    table.insert(matches, obj)
                end
            end
        end
        notify("Found " .. #matches .. " possible secret location parts")
    end)
end

local function stopFly()
    Flying = false
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    if FlyVelocity then FlyVelocity:Destroy() FlyVelocity = nil end
    if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
    notify("Fly disabled")
end

local function startFly()
    local root = getRoot()
    if not root then return notify("Character root not found") end
    if Flying then return end
    Flying = true

    FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    FlyVelocity.Velocity = Vector3.zero
    FlyVelocity.Parent = root

    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    FlyGyro.P = 10000
    FlyGyro.Parent = root

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Flying or not root.Parent then
            stopFly()
            return
        end

        local cam = Workspace.CurrentCamera
        local direction = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then direction += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end

        FlyVelocity.Velocity = direction.Magnitude > 0
            and direction.Unit * FlySpeed or Vector3.zero
        FlyGyro.CFrame = cam.CFrame
    end)

    notify("Fly enabled: WASD, Space and Ctrl")
end

local function showMovement()
    clear()
    label("MOVEMENT")
    button("Enable Fly", startFly)
    button("Disable Fly", stopFly)
    button("Increase fly speed", function()
        FlySpeed = math.clamp(FlySpeed + 10, 10, 250)
        notify("Fly speed: " .. FlySpeed)
    end)
    button("Decrease fly speed", function()
        FlySpeed = math.clamp(FlySpeed - 10, 10, 250)
        notify("Fly speed: " .. FlySpeed)
    end)
    button("WalkSpeed +5", function()
        local h = Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = h.WalkSpeed + 5 end
    end)
    button("Reset WalkSpeed", function()
        local h = Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 end
    end)
    button("JumpPower +10", function()
        local h = Character:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = h.JumpPower + 10 end
    end)
    button("Reset JumpPower", function()
        local h = Character:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = 50 end
    end)
end

local function showEndTimes()
    clear()
    label("END TIMES TREE")
    button("Scan for End Times objects", function()
        local found = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            if string.find(n, "end") or string.find(n, "time") then
                if obj:IsA("BasePart") then
                    table.insert(found, obj)
                end
            end
        end
        clear()
        label("Found " .. #found .. " possible objects")
        for _, part in ipairs(found) do
            button("View: " .. part.Name, function()
                local root = getRoot()
                if root then
                    root.CFrame = part.CFrame * CFrame.new(0, 5, 0)
                end
            end)
        end
    end)
end

local function showInventory()
    clear()
    label("BACKPACK AND AXES")
    button("Scan inventory", function()
        clear()
        label("YOUR TOOLS")
        local backpack = Player:FindFirstChildOfClass("Backpack")
        local tools = {}
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then table.insert(tools, tool) end
            end
        end
        for _, tool in ipairs(Character:GetChildren()) do
            if tool:IsA("Tool") then table.insert(tools, tool) end
        end
        if #tools == 0 then label("No tools found") end
        for _, tool in ipairs(tools) do
            label(tool.Name .. (string.find(string.lower(tool.Name), "axe")
                and "  [AXE]" or ""))
        end
    end)
    button("Check for Rukiryie Axe", function()
        local found = false
        local backpack = Player:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if string.find(string.lower(tool.Name), "rukiryie") then
                    found = true
                end
            end
        end
        for _, tool in ipairs(Character:GetChildren()) do
            if string.find(string.lower(tool.Name), "rukiryie") then
                found = true
            end
        end
        notify(found and "Rukiryie Axe detected" or "Rukiryie Axe not found")
    end)
end

local function showMisc()
    clear()
    label("MISCELLANEOUS")
    button("Show secret", function()
        local popup = Instance.new("TextLabel")
        popup.Size = UDim2.fromOffset(340, 55)
        popup.Position = UDim2.new(0.5, -170, 0.15, 0)
        popup.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        popup.TextColor3 = Color3.new(1, 1, 1)
        popup.TextSize = 19
        popup.Font = Enum.Font.GothamBold
        popup.Text = "oliver vaughn 187 kingsway"
        popup.Parent = Gui
        Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 8)
        task.delay(5, function()
            if popup then popup:Destroy() end
        end)
    end)
    button("Scan blueprint objects", function()
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if string.find(string.lower(obj.Name), "blueprint") then
                count += 1
            end
        end
        notify("Found " .. count .. " possible blueprint objects")
    end)
    button("Refresh character", function()
        Character = Player.Character or Character
        notify("Character refreshed")
    end)
    button("Close hub", function()
        stopFly()
        Gui:Destroy()
    end)
end

local pages = {
    showHome, showBring, showTrees, showTeleports,
    showMovement, showEndTimes, showInventory, showMisc
}

for i, name in ipairs(tabs) do
    local b = addTab(name, i)
    b.MouseButton1Click:Connect(function()
        pages[i]()
    end)
end

showHome()

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

Player.CharacterAdded:Connect(function(char)
    Character = char
    if Flying then stopFly() end
end)

notify("LT2 Utility Hub loaded")
