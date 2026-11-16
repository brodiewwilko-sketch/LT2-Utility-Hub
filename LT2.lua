
--[[
    LT2 MEGA COMPANION HUB
    Client-side utility and tracking hub

    Right Shift: Show / hide
    No external script downloads.
    No remote-event abuse, forced purchases or duplication exploits.

    Features:
      Home dashboard
      Wood database and selector
      Wood profit calculator
      Blueprint material calculator
      Truck / hauling calculator
      Quest checklists
      Axe and inventory scanner
      Location bookmarks
      Loaded tree / log scanner
      End Times scanner
      Fly, noclip, speed, jump, infinite jump
      RGB interface, search, resize and notifications
]]

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Backpack = Player:WaitForChild("Backpack")

-- CONFIGURATION
local Config = {
    Rainbow = true,
    AccentHue = 0.55,
    FlySpeed = 65,
    WalkSpeed = 16,
    JumpPower = 50,
    Noclip = false,
    InfiniteJump = false,
    Fly = false,
    Search = "",
    Keybind = Enum.KeyCode.RightShift
}

-- DATABASE
local WoodDatabase = {
    Common = {
        "Oak", "Elm", "Birch", "Cherry", "Fir",
        "Pine", "Walnut", "Koa", "Palm"
    },

    Special = {
        "Volcano", "Gold", "Zombie", "Frost",
        "Cavecrawler", "Phantom", "Snowglow"
    },

    Seasonal = {
        "Spooky", "Sinister", "Blue Spruce"
    },

    SpecialOther = {
        "Sign Wood", "Test Wood", "Gray Wood", "Pink Wood"
    }
}

local AllWood = {}
for _, category in pairs(WoodDatabase) do
    for _, name in ipairs(category) do
        table.insert(AllWood, name)
    end
end
table.sort(AllWood)

local SelectedWood = "Oak"
local SelectedTool = nil
local SelectedTree = nil

-- STATE
local SavedPosition = nil
local PreviousPosition = nil
local Bookmarks = {}
local QuestProgress = {}
local OriginalCollisions = {}
local OriginalGravity = Workspace.Gravity

local Character = Player.Character or Player.CharacterAdded:Wait()

local Flying = false
local FlyConnection = nil
local FlyVelocity = nil
local FlyGyro = nil
local NoclipConnection = nil
local InfiniteJumpConnection = nil

-- NOTIFICATIONS
local function notify(message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "LT2 Mega Hub",
            Text = tostring(message),
            Duration = 4
        })
    end)
end

local function getCharacter()
    Character = Player.Character or Character
    return Character
end

local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function savePosition()
    local root = getRoot()
    if not root then
        notify("Cannot save: character not found")
        return false
    end

    SavedPosition = root.CFrame
    notify("Position saved")
    return true
end

local function returnPosition()
    local root = getRoot()
    if not root then
        notify("Cannot return: character not found")
        return
    end

    if not SavedPosition then
        notify("Save a position first")
        return
    end

    PreviousPosition = root.CFrame
    root.CFrame = SavedPosition
    notify("Returned to saved position")
end

-- GUI CREATION
local oldGui
pcall(function()
    local parent = typeof(gethui) == "function" and gethui() or CoreGui
    oldGui = parent:FindFirstChild("LTMegaCompanionHub")
    if oldGui then oldGui:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "LTMegaCompanionHub"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999

local ParentOK = false
pcall(function()
    Gui.Parent = typeof(gethui) == "function" and gethui() or CoreGui
    ParentOK = true
end)

if not ParentOK then
    Gui.Parent = Player:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(790, 555)
Main.Position = UDim2.new(0.5, -395, 0.5, -277)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
Main.BorderSizePixel = 0
Main.Parent = Gui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 47)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
Header.BorderSizePixel = 0
Header.Parent = Main

Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Position = UDim2.fromOffset(15, 0)
Title.Size = UDim2.new(1, -150, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "LT2  /  MEGA COMPANION HUB"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(36, 30)
Minimize.Position = UDim2.new(1, -83, 0, 8)
Minimize.Text = "_"
Minimize.TextSize = 20
Minimize.Font = Enum.Font.GothamBold
Minimize.BackgroundColor3 = Color3.fromRGB(47, 47, 60)
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.Parent = Header
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 5)

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(36, 30)
Close.Position = UDim2.new(1, -42, 0, 8)
Close.Text = "X"
Close.TextSize = 14
Close.Font = Enum.Font.GothamBold
Close.BackgroundColor3 = Color3.fromRGB(130, 45, 55)
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Parent = Header
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 5)

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Position = UDim2.fromOffset(10, 57)
Sidebar.Size = UDim2.fromOffset(155, 485)
Sidebar.BackgroundColor3 = Color3.fromRGB(27, 27, 36)
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 3
Sidebar.CanvasSize = UDim2.new()
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 7)

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 5)
SideLayout.Parent = Sidebar

local Search = Instance.new("TextBox")
Search.Position = UDim2.fromOffset(175, 57)
Search.Size = UDim2.new(1, -190, 0, 32)
Search.BackgroundColor3 = Color3.fromRGB(34, 34, 45)
Search.TextColor3 = Color3.new(1, 1, 1)
Search.PlaceholderText = "Search this page..."
Search.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
Search.Text = ""
Search.TextSize = 13
Search.Font = Enum.Font.Gotham
Search.ClearTextOnFocus = false
Search.Parent = Main
Instance.new("UICorner", Search).CornerRadius = UDim.new(0, 5)

local Page = Instance.new("ScrollingFrame")
Page.Position = UDim2.fromOffset(175, 98)
Page.Size = UDim2.new(1, -190, 1, -115)
Page.BackgroundColor3 = Color3.fromRGB(27, 27, 36)
Page.BorderSizePixel = 0
Page.ScrollBarThickness = 4
Page.CanvasSize = UDim2.new()
Page.Parent = Main
Instance.new("UICorner", Page).CornerRadius = UDim.new(0, 7)

local PageLayout = Instance.new("UIListLayout")
PageLayout.Padding = UDim.new(0, 6)
PageLayout.Parent = Page

local PagePadding = Instance.new("UIPadding")
PagePadding.PaddingTop = UDim.new(0, 9)
PagePadding.PaddingLeft = UDim.new(0, 8)
PagePadding.PaddingRight = UDim.new(0, 8)
PagePadding.PaddingBottom = UDim.new(0, 9)
PagePadding.Parent = Page

local Footer = Instance.new("TextLabel")
Footer.Position = UDim2.new(0, 175, 1, -17)
Footer.Size = UDim2.new(1, -190, 0, 14)
Footer.BackgroundTransparency = 1
Footer.Text = "Ready  |  Right Shift: Toggle"
Footer.TextColor3 = Color3.fromRGB(150, 150, 165)
Footer.TextSize = 10
Footer.Font = Enum.Font.Gotham
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.Parent = Main

local function accent()
    if Config.Rainbow then
        return Color3.fromHSV(Config.AccentHue, 0.8, 1)
    end
    return Color3.fromRGB(105, 125, 255)
end

local function updateCanvas()
    Page.CanvasSize = UDim2.fromOffset(
        0,
        PageLayout.AbsoluteContentSize.Y + 25
    )
    Sidebar.CanvasSize = UDim2.fromOffset(
        0,
        SideLayout.AbsoluteContentSize.Y + 10
    )
end

PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
SideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

task.spawn(function()
    while Gui.Parent do
        if Config.Rainbow then
            Config.AccentHue = (Config.AccentHue + 0.002) % 1
        end
        MainStroke.Color = accent()
        task.wait()
    end
end)

-- DRAGGING
do
    local dragging = false
    local dragStart
    local startPosition

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = Main.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- RESIZE HANDLE
local Resize = Instance.new("TextButton")
Resize.Size = UDim2.fromOffset(20, 20)
Resize.Position = UDim2.new(1, -20, 1, -20)
Resize.BackgroundColor3 = accent()
Resize.Text = "◢"
Resize.TextColor3 = Color3.new(1, 1, 1)
Resize.TextSize = 12
Resize.Parent = Main

do
    local resizing = false
    local startMouse
    local startSize

    Resize.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            startMouse = input.Position
            startSize = Main.Size
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startMouse
            local w = math.clamp(startSize.X.Offset + delta.X, 650, 1100)
            local h = math.clamp(startSize.Y.Offset + delta.Y, 460, 850)
            Main.Size = UDim2.fromOffset(w, h)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
end

Minimize.MouseButton1Click:Connect(function()
    local hidden = Sidebar.Visible
    Sidebar.Visible = not hidden
    Search.Visible = not hidden
    Page.Visible = not hidden
    Footer.Visible = not hidden
    Main.Size = hidden and UDim2.fromOffset(790, 555)
        or UDim2.fromOffset(790, 47)
end)

Close.MouseButton1Click:Connect(function()
    if Flying then
        Config.Fly = false
    end
    Config.Noclip = false
    Gui:Destroy()
end)

-- PAGE HELPERS
local function clearPage()
    for _, child in ipairs(Page:GetChildren()) do
        if child:IsA("GuiObject") and child ~= PageLayout
            and child ~= PagePadding then
            child:Destroy()
        end
    end
    Page.CanvasPosition = Vector2.zero
end

local function makeLabel(text, height)
    local object = Instance.new("TextLabel")
    object.Name = text
    object.Size = UDim2.new(1, -4, 0, height or 29)
    object.BackgroundTransparency = 1
    object.Text = tostring(text)
    object.TextColor3 = Color3.fromRGB(225, 225, 235)
    object.TextSize = 13
    object.Font = Enum.Font.Gotham
    object.TextWrapped = true
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.Parent = Page
    return object
end

local function makeSection(text)
    local object = Instance.new("TextLabel")
    object.Name = text
    object.Size = UDim2.new(1, -4, 0, 30)
    object.BackgroundColor3 = Color3.fromRGB(39, 39, 52)
    object.Text = "   " .. text
    object.TextColor3 = accent()
    object.TextSize = 13
    object.Font = Enum.Font.GothamBold
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.Parent = Page
    Instance.new("UICorner", object).CornerRadius = UDim.new(0, 5)
    return object
end

local function makeButton(text, callback)
    local object = Instance.new("TextButton")
    object.Name = text
    object.Size = UDim2.new(1, -4, 0, 34)
    object.BackgroundColor3 = Color3.fromRGB(44, 44, 58)
    object.Text = text
    object.TextColor3 = Color3.new(1, 1, 1)
    object.TextSize = 12
    object.Font = Enum.Font.GothamSemibold
    object.TextWrapped = true
    object.Parent = Page
    Instance.new("UICorner", object).CornerRadius = UDim.new(0, 5)

    object.MouseButton1Click:Connect(function()
        local success, err = pcall(callback)
        if not success then
            notify("Error: " .. tostring(err))
        end
    end)

    return object
end

local function makeInput(name, defaultValue)
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, -4, 0, 38)
    row.BackgroundTransparency = 1
    row.Parent = Page

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.53, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = Color3.fromRGB(220, 220, 230)
    title.TextSize = 12
    title.Font = Enum.Font.Gotham
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = row

    local input = Instance.new("TextBox")
    input.Position = UDim2.new(0.55, 0, 0, 2)
    input.Size = UDim2.new(0.45, -2, 1, -4)
    input.BackgroundColor3 = Color3.fromRGB(43, 43, 56)
    input.TextColor3 = Color3.new(1, 1, 1)
    input.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
    input.Text = tostring(defaultValue or "")
    input.PlaceholderText = "Enter value"
    input.ClearTextOnFocus = false
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.Parent = row
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)

    return input
end

local function makeToggle(text, initial, callback)
    local enabled = initial == true
    local b

    local function refresh()
        b.Text = text .. (enabled and "   [ON]" or "   [OFF]")
        b.BackgroundColor3 = enabled
            and Color3.fromRGB(50, 85, 65)
            or Color3.fromRGB(44, 44, 58)
    end

    b = makeButton("", function()
        enabled = not enabled
        refresh()
        callback(enabled)
    end)

    b.Name = text
    refresh()

    return function()
        return enabled
    end
end

local function applySearch()
    local query = string.lower(Search.Text or "")

    for _, child in ipairs(Page:GetChildren()) do
        if child:IsA("GuiObject") and child ~= PageLayout
            and child ~= PagePadding then

            if query == "" then
                child.Visible = true
            else
                local text = string.lower(child.Name or "")
                pcall(function()
                    text = text .. " " .. string.lower(child.Text or "")
                end)
                child.Visible = string.find(text, query, 1, true) ~= nil
            end
        end
    end
end

Search:GetPropertyChangedSignal("Text"):Connect(applySearch)

-- MOVEMENT
local function stopFly()
    Config.Fly = false
    Flying = false

    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    if FlyVelocity then
        FlyVelocity:Destroy()
        FlyVelocity = nil
    end

    if FlyGyro then
        FlyGyro:Destroy()
        FlyGyro = nil
    end

    notify("Fly disabled")
end

local function startFly()
    if Flying then
        notify("Already flying")
        return
    end

    local root = getRoot()
    if not root then
        notify("Character root not found")
        return
    end

    Flying = true
    Config.Fly = true

    FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.MaxForce = Vector3.new(1000000, 1000000, 1000000)
    FlyVelocity.Velocity = Vector3.zero
    FlyVelocity.Parent = root

    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.MaxTorque = Vector3.new(1000000, 1000000, 1000000)
    FlyGyro.P = 10000
    FlyGyro.CFrame = root.CFrame
    FlyGyro.Parent = root

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Flying or not root.Parent then
            stopFly()
            return
        end

        local camera = Workspace.CurrentCamera
        if not camera then return end

        local direction = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            direction += camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            direction -= camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then
            direction -= camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) then
            direction += camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.yAxis
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.yAxis
        end

        if direction.Magnitude > 0 then
            FlyVelocity.Velocity = direction.Unit * Config.FlySpeed
        else
            FlyVelocity.Velocity = Vector3.zero
        end

        FlyGyro.CFrame = camera.CFrame
    end)

    notify("Fly enabled: WASD, Space and Ctrl")
end

local function startNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
    end

    Config.Noclip = true

    NoclipConnection = RunService.Stepped:Connect(function()
        local char = getCharacter()
        if not char then return end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if OriginalCollisions[part] == nil then
                    OriginalCollisions[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)

    notify("Noclip enabled")
end

local function stopNoclip()
    Config.Noclip = false

    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end

    for part, original in pairs(OriginalCollisions) do
        if part and part.Parent then
            part.CanCollide = original
        end
    end

    table.clear(OriginalCollisions)
    notify("Noclip disabled")
end

local function setInfiniteJump(value)
    Config.InfiniteJump = value

    if InfiniteJumpConnection then
        InfiniteJumpConnection:Disconnect()
        InfiniteJumpConnection = nil
    end

    if value then
        InfiniteJumpConnection = UIS.JumpRequest:Connect(function()
            local hum = getHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

-- INVENTORY
local function getTools()
    local result = {}
    local backpack = Player:FindFirstChildOfClass("Backpack")

    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(result, tool)
            end
        end
    end

    local char = getCharacter()
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(result, tool)
            end
        end
    end

    return result
end

local function equipTool(tool)
    local hum = getHumanoid()
    if not hum or not tool or not tool.Parent then
        notify("Tool could not be equipped")
        return
    end

    hum:EquipTool(tool)
    notify("Equipped " .. tool.Name)
end

-- SCANNERS
local function scanObjects(keyword)
    local results = {}
    local query = string.lower(keyword)

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if string.find(string.lower(obj.Name), query, 1, true) then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(results, obj)
            end
        end
    end

    return results
end

local function getObjectPart(obj)
    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

-- HOME PAGE
local function showHome()
    clearPage()
    Search.Text = ""

    makeSection("WELCOME")
    makeLabel("LT2 Mega Companion Hub")
    makeLabel("A collection of local tools, trackers and calculators.")
    makeSection("PLAYER")
    makeLabel("Username: " .. Player.Name)
    makeLabel("Display name: " .. Player.DisplayName)

    local function updateStats()
        local hum = getHumanoid()
        local root = getRoot()
        local hp = hum and math.floor(hum.Health) or 0
        local pos = root and tostring(root.Position) or "Unavailable"
        return hp, pos
    end

    local hp, pos = updateStats()
    makeLabel("Health: " .. hp)
    makeLabel("Position: " .. pos, 40)

    makeSection("POSITION")
    makeButton("Save current position", savePosition)
    makeButton("Return to saved position", returnPosition)

    makeSection("QUICK ACCESS")
    makeButton("Open wood database", function()
        showHome()
        notify("Select Wood Database in the sidebar")
    end)

    makeLabel("Use the sidebar to open the other pages.")
    makeLabel("Search filters the currently open page.")
    makeLabel("Saved bookmarks only last while this hub is open.")
end

-- WOOD DATABASE PAGE
local function showWood()
    clearPage()
    Search.Text = ""

    makeSection("WOOD DATABASE")
    makeLabel("Selected wood: " .. SelectedWood)
    makeLabel("Choose a wood type below. This database is a reference, not a list of trees guaranteed to exist in your current server.")

    local groups = {
        {"COMMON WOOD", WoodDatabase.Common},
        {"SPECIAL WOOD", WoodDatabase.Special},
        {"SEASONAL WOOD", WoodDatabase.Seasonal},
        {"SPECIAL / UNOBTAINABLE / OTHER", WoodDatabase.SpecialOther}
    }

    for _, group in ipairs(groups) do
        makeSection(group[1])

        for _, wood in ipairs(group[2]) do
            makeButton("Select " .. wood, function()
                SelectedWood = wood
                Footer.Text = "Selected wood: " .. wood
                notify("Selected " .. wood)
            end)
        end
    end

    makeSection("TREE SCANNER")
    makeButton("Scan currently loaded tree objects", function()
        local results = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local name = string.lower(obj.Name)
                if string.find(name, "tree", 1, true) then
                    table.insert(results, obj)
                end
            end
        end

        clearPage()
        makeSection("TREE SCAN RESULTS")
        makeLabel("Found " .. #results .. " possible loaded tree models.")
        makeLabel("Only currently loaded objects can be scanned.")
        for _, tree in ipairs(results) do
            makeButton("Select: " .. tree.Name, function()
                SelectedTree = tree
                notify("Selected " .. tree.Name)
            end)
        end
    end)

    makeButton("Show selected tree information", function()
        if not SelectedTree or not SelectedTree.Parent then
            return notify("No loaded tree selected")
        end

        local part = getObjectPart(SelectedTree)
        if not part then
            return notify("Selected tree has no position part")
        end

        notify(SelectedTree.Name .. " | " .. tostring(part.Position))
    end)
end

-- WOOD PROFIT CALCULATOR
local function showCalculator()
    clearPage()
    Search.Text = ""

    makeSection("WOOD PROFIT CALCULATOR")
    makeLabel("Enter the value you want to use. The hub does not assume current shop prices.")

    local quantity = makeInput("Number of logs", "1")
    local unitPrice = makeInput("Sale value per log", "0")
    local unitCost = makeInput("Cost per log", "0")

    local result = makeLabel("Result will appear here", 48)

    makeButton("Calculate wood profit", function()
        local q = tonumber(quantity.Text)
        local p = tonumber(unitPrice.Text)
        local c = tonumber(unitCost.Text)

        if not q or not p or not c or q < 0 or p < 0 or c < 0 then
            return notify("Enter valid positive numbers")
        end

        local revenue = q * p
        local cost = q * c
        local profit = revenue - cost

        result.Text = string.format(
            "Gross value: %.2f\nCost: %.2f\nProfit: %.2f",
            revenue, cost, profit
        )
    end)

    makeSection("BLUEPRINT MATERIAL CALCULATOR")
    makeLabel("Enter the cost of each material or component.")

    local material1 = makeInput("Material 1 cost", "0")
    local material2 = makeInput("Material 2 cost", "0")
    local material3 = makeInput("Material 3 cost", "0")
    local material4 = makeInput("Material 4 cost", "0")
    local material5 = makeInput("Material 5 cost", "0")
    local materialResult = makeLabel("Material total will appear here")

    makeButton("Calculate material total", function()
        local inputs = {
            material1, material2, material3, material4, material5
        }

        local total = 0
        for _, input in ipairs(inputs) do
            local value = tonumber(input.Text)
            if not value or value < 0 then
                return notify("Enter valid material costs")
            end
            total += value
        end

        materialResult.Text = "Total material cost: " .. string.format("%.2f", total)
    end)

    makeSection("TRUCK / HAULING CALCULATOR")
    local logCount = makeInput("Logs to transport", "100")
    local truckCapacity = makeInput("Logs per trip", "10")
    local tripsResult = makeLabel("Trip count will appear here")

    makeButton("Calculate trips", function()
        local logs = tonumber(logCount.Text)
        local capacity = tonumber(truckCapacity.Text)

        if not logs or not capacity or logs < 0 or capacity <= 0 then
            return notify("Enter valid log and capacity amounts")
        end

        local trips = math.ceil(logs / capacity)
        tripsResult.Text = "Trips needed: " .. trips
    end)
end

-- QUEST TRACKER
local function showQuests()
    clearPage()
    Search.Text = ""

    makeSection("QUEST AND COLLECTION TRACKER")
    makeLabel("Mark each objective when you complete it. Progress is stored while this hub is open.")

    local quests = {
        "Explore the Cavecrawler area",
        "Locate the End Times Tree",
        "Obtain the End Times Axe",
        "Find the Rukiryaxe",
        "Collect Frost Wood",
        "Collect Sinister Wood",
        "Collect Cavecrawler Wood",
        "Collect Phantom Wood",
        "Collect Snowglow Wood",
        "Collect seasonal wood",
        "Find rare blueprints",
        "Complete personal base project"
    }

    for _, quest in ipairs(quests) do
        if QuestProgress[quest] == nil then
            QuestProgress[quest] = false
        end

        local b
        b = makeButton("", function()
            QuestProgress[quest] = not QuestProgress[quest]
            b.Text = (QuestProgress[quest] and "[DONE]  " or "[TODO]  ") .. quest
            b.BackgroundColor3 = QuestProgress[quest]
                and Color3.fromRGB(48, 86, 60)
                or Color3.fromRGB(44, 44, 58)
        end)

        b.Text = (QuestProgress[quest] and "[DONE]  " or "[TODO]  ") .. quest
        b.BackgroundColor3 = QuestProgress[quest]
            and Color3.fromRGB(48, 86, 60)
            or Color3.fromRGB(44, 44, 58)
    end

    makeButton("Reset all quest checkboxes", function()
        for key in pairs(QuestProgress) do
            QuestProgress[key] = false
        end
        showQuests()
        notify("Quest checklist reset")
    end)
end

-- INVENTORY PAGE
local function showInventory()
    clearPage()
    Search.Text = ""

    makeSection("INVENTORY SCANNER")

    local tools = getTools()
    local axeCount = 0

    makeLabel("Tools found: " .. #tools)

    for _, tool in ipairs(tools) do
        local isAxe = string.find(string.lower(tool.Name), "axe", 1, true) ~= nil
        if isAxe then axeCount += 1 end

        makeButton((isAxe and "[AXE] " or "[TOOL] ") .. tool.Name, function()
            SelectedTool = tool
            notify("Selected " .. tool.Name)
        end)
    end

    makeLabel("Possible axes found: " .. axeCount)

    makeButton("Refresh inventory", showInventory)

    makeButton("Equip selected tool", function()
        if not SelectedTool then
            return notify("Select a tool first")
        end
        equipTool(SelectedTool)
    end)

    makeSection("SPECIAL AXE CHECKS")

    local rukiryieFound = false
    local endTimesFound = false

    for _, tool in ipairs(tools) do
        local name = string.lower(tool.Name)

        if string.find(name, "rukiry", 1, true) then
            rukiryieFound = true
        end

        if string.find(name, "end times", 1, true) then
            endTimesFound = true
        end
    end

    makeLabel("Rukiryaxe detected: " .. (rukiryieFound and "YES" or "NO"))
    makeLabel("End Times Axe detected: " .. (endTimesFound and "YES" or "NO"))

    makeLabel("Axe duplication and server-side axe granting are not provided.")
end

-- LOCATION PAGE
local function showLocations()
    clearPage()
    Search.Text = ""

    makeSection("LOCATION BOOKMARKS")
    makeLabel("Save places you have visited and return to them later.")

    local nameBox = makeInput("Bookmark name", "My location")

    makeButton("Save current position as bookmark", function()
        local root = getRoot()
        if not root then
            return notify("Character not found")
        end

        local name = nameBox.Text
        if name == "" then
            name = "Bookmark " .. tostring(#Bookmarks + 1)
        end

        table.insert(Bookmarks, {
            Name = name,
            CFrame = root.CFrame
        })

        notify("Saved bookmark: " .. name)
    end)

    makeButton("Show saved bookmarks", function()
        clearPage()
        makeSection("SAVED LOCATIONS")

        if #Bookmarks == 0 then
            makeLabel("No bookmarks saved yet.")
        end

        for index, bookmark in ipairs(Bookmarks) do
            makeButton("Go to: " .. bookmark.Name, function()
                local root = getRoot()
                if not root then return notify("Character not found") end

                PreviousPosition = root.CFrame
                root.CFrame = bookmark.CFrame + Vector3.new(0, 4, 0)
                notify("Moved to bookmark: " .. bookmark.Name)
            end)

            makeButton("Delete: " .. bookmark.Name, function()
                table.remove(Bookmarks, index)
                showLocations()
                notify("Bookmark deleted")
            end)
        end

        makeButton("Return to previous position", function()
            local root = getRoot()
            if root and PreviousPosition then
                root.CFrame = PreviousPosition
            else
                notify("No previous position saved")
            end
        end)
    end)

    makeSection("LOCATION DISCOVERY")
    makeLabel("Scan objects with location-related names. Results are only clues, not guaranteed destinations.")

    makeButton("Scan for shops and landmarks", function()
        local words = {
            "shop", "store", "cave", "bridge",
            "dock", "end", "mill", "sawmill"
        }

        local found = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                for _, word in ipairs(words) do
                    if string.find(name, word, 1, true) then
                        table.insert(found, obj)
                        break
                    end
                end
            end
        end

        clearPage()
        makeSection("DISCOVERED OBJECTS")
        makeLabel("Found " .. #found .. " possible location objects.")

        for _, obj in ipairs(found) do
            makeButton("Bookmark: " .. obj.Name, function()
                local part = getObjectPart(obj)
                if not part then return notify("No position found") end

                table.insert(Bookmarks, {
                    Name = obj.Name,
                    CFrame = part.CFrame
                })

                notify("Saved " .. obj.Name)
            end)
        end
    end)
end

-- TREE AND ITEM SCANNER
local function showScanner()
    clearPage()
    Search.Text = ""

    makeSection("WORLD SCANNER")

    makeButton("Scan loaded trees", function()
        local matches = scanObjects("tree")
        clearPage()
        makeSection("TREE RESULTS")
        makeLabel("Found " .. #matches .. " matching objects.")

        for _, obj in ipairs(matches) do
            makeButton("Inspect " .. obj.Name, function()
                SelectedTree = obj
                local part = getObjectPart(obj)
                if part then
                    notify(obj.Name .. " at " .. tostring(part.Position))
                else
                    notify("Selected " .. obj.Name)
                end
            end)
        end
    end)

    makeButton("Scan loaded logs and wood", function()
        local logs = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local name = string.lower(obj.Name)
            if string.find(name, "log", 1, true)
                or string.find(name, "wood", 1, true) then
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    table.insert(logs, obj)
                end
            end
        end

        clearPage()
        makeSection("LOG / WOOD RESULTS")
        makeLabel("Found " .. #logs .. " matching objects.")

        for _, obj in ipairs(logs) do
            makeButton("Inspect " .. obj.Name, function()
                local part = getObjectPart(obj)
                if part then
                    notify(obj.Name .. " at " .. tostring(part.Position))
                else
                    notify("No position part found")
                end
            end)
        end
    end)

    makeButton("Scan blueprints", function()
        local results = scanObjects("blueprint")
        clearPage()
        makeSection("BLUEPRINT RESULTS")
        makeLabel("Possible blueprint objects found: " .. #results)

        for _, obj in ipairs(results) do
            makeLabel(obj.Name)
        end
    end)

    makeLabel("No ESP is created by this scanner.")
    makeLabel("Only objects currently loaded in Workspace can be found.")
end

-- END TIMES PAGE
local function showEndTimes()
    clearPage()
    Search.Text = ""

    makeSection("END TIMES TREE AND AXE")
    makeLabel("Scan loaded objects whose names contain End Times-related words.")

    makeButton("Scan End Times objects", function()
        local terms = {"end times", "endtimes", "end tree"}
        local results = {}

        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            for _, term in ipairs(terms) do
                if string.find(n, term, 1, true) then
                    if obj:IsA("Model") or obj:IsA("BasePart") then
                        table.insert(results, obj)
                    end
                    break
                end
            end
        end

        clearPage()
        makeSection("END TIMES SCAN RESULTS")
        makeLabel("Found " .. #results .. " matching objects.")

        for _, obj in ipairs(results) do
            makeButton("Inspect " .. obj.Name, function()
                local part = getObjectPart(obj)
                if part then
                    notify(obj.Name .. " at " .. tostring(part.Position))
                else
                    notify(obj.Name)
                end
            end)
        end
    end)

    makeSection("AXE CHECK")
    makeButton("Check inventory for End Times Axe", function()
        for _, tool in ipairs(getTools()) do
            if string.find(string.lower(tool.Name), "end times", 1, true) then
                return notify("End Times Axe found: " .. tool.Name)
            end
        end
        notify("End Times Axe not found in your tools")
    end)

    makeLabel("This scanner cannot reveal unloaded or hidden server objects.")
end

-- MOVEMENT PAGE
local function showMovement()
    clearPage()
    Search.Text = ""

    makeSection("FLY")
    makeToggle("Fly", Flying, function(enabled)
        if enabled then
            startFly()
        else
            stopFly()
        end
    end)

    makeLabel("Controls: W A S D, Space to rise, Ctrl to descend.")
    makeButton("Increase fly speed", function()
        Config.FlySpeed = math.clamp(Config.FlySpeed + 10, 10, 250)
        notify("Fly speed: " .. Config.FlySpeed)
    end)

    makeButton("Decrease fly speed", function()
        Config.FlySpeed = math.clamp(Config.FlySpeed - 10, 10, 250)
        notify("Fly speed: " .. Config.FlySpeed)
    end)

    makeSection("CHARACTER MOVEMENT")

    local walkInput = makeInput("WalkSpeed", tostring(Config.WalkSpeed))
    makeButton("Apply WalkSpeed", function()
        local value = tonumber(walkInput.Text)
        local hum = getHumanoid()
        if not value or value < 0 or value > 250 then
            return notify("Enter a value from 0 to 250")
        end
        if hum then
            hum.WalkSpeed = value
            Config.WalkSpeed = value
            notify("WalkSpeed applied")
        end
    end)

    local jumpInput = makeInput("JumpPower", tostring(Config.JumpPower))
    makeButton("Apply JumpPower", function()
        local value = tonumber(jumpInput.Text)
        local hum = getHumanoid()
        if not value or value < 0 or value > 250 then
            return notify("Enter a value from 0 to 250")
        end
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = value
            Config.JumpPower = value
            notify("JumpPower applied")
        end
    end)

    makeToggle("Noclip", Config.Noclip, function(enabled)
        if enabled then startNoclip() else stopNoclip() end
    end)

    makeToggle("Infinite Jump", Config.InfiniteJump, setInfiniteJump)

    makeSection("GRAVITY")

    local gravityInput = makeInput("Gravity", tostring(Workspace.Gravity))
    makeButton("Apply Gravity", function()
        local value = tonumber(gravityInput.Text)
        if not value or value < 0 or value > 500 then
            return notify("Enter gravity between 0 and 500")
        end
        Workspace.Gravity = value
        notify("Gravity changed locally")
    end)

    makeButton("Reset Gravity", function()
        Workspace.Gravity = OriginalGravity
        gravityInput.Text = tostring(OriginalGravity)
        notify("Gravity reset")
    end)

    makeSection("POSITION")
    makeButton("Save position", savePosition)
    makeButton("Return to saved position", returnPosition)
end

-- MISC PAGE
local function showMisc()
    clearPage()
    Search.Text = ""

    makeSection("MISCELLANEOUS")

    makeButton("Show your secret popup", function()
        local popup = Instance.new("TextLabel")
        popup.Size = UDim2.fromOffset(350, 58)
        popup.Position = UDim2.new(0.5, -175, 0.15, 0)
        popup.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        popup.TextColor3 = Color3.new(1, 1, 1)
        popup.Text = "oliver vaughn 187 kingsway"
        popup.TextSize = 18
        popup.Font = Enum.Font.GothamBold
        popup.Parent = Gui

        Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 8)

        local outline = Instance.new("UIStroke")
        outline.Color = accent()
        outline.Thickness = 2
        outline.Parent = popup

        task.delay(5, function()
            if popup and popup.Parent then
                popup:Destroy()
            end
        end)
    end)

    makeButton("Refresh character", function()
        Character = Player.Character or Character
        notify("Character refreshed")
    end)

    makeButton("Refresh inventory", function()
        notify("Tools found: " .. #getTools())
    end)

    makeButton("Show selected wood", function()
        notify("Selected wood: " .. SelectedWood)
    end)

    makeButton("Show saved bookmark count", function()
        notify("Bookmarks saved: " .. #Bookmarks)
    end)

    makeSection("LIMITATIONS")
    makeLabel("This hub does not duplicate axes, force blueprint purchases or force server-side wood movement.")
    makeLabel("Use the game's normal interactions for chopping, buying, selling and transporting.")
    makeLabel("Trolling or flinging other players is not included.")
end

-- SETTINGS PAGE
local function showSettings()
    clearPage()
    Search.Text = ""

    makeSection("INTERFACE SETTINGS")

    makeToggle("RGB border", Config.Rainbow, function(enabled)
        Config.Rainbow = enabled
        notify(enabled and "RGB enabled" or "RGB disabled")
    end)

    makeButton("Set blue accent", function()
        Config.Rainbow = false
        Config.AccentHue = 0.62
        MainStroke.Color = Color3.fromRGB(105, 125, 255)
        notify("Blue accent selected")
    end)

    makeButton("Set purple accent", function()
        Config.Rainbow = false
        Config.AccentHue = 0.76
        MainStroke.Color = Color3.fromRGB(160, 100, 255)
        notify("Purple accent selected")
    end)

    makeButton("Set green accent", function()
        Config.Rainbow = false
        Config.AccentHue = 0.35
        MainStroke.Color = Color3.fromRGB(70, 220, 130)
        notify("Green accent selected")
    end)

    makeSection("KEYBIND")
    makeLabel("Current menu key: Right Shift")
    makeLabel("Press Right Shift to show or hide the menu.")

    makeSection("RESET")
    makeButton("Reset movement settings", function()
        stopFly()
        stopNoclip()
        setInfiniteJump(false)

        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = 16
            hum.UseJumpPower = true
            hum.JumpPower = 50
        end

        Workspace.Gravity = OriginalGravity
        Config.FlySpeed = 65
        Config.WalkSpeed = 16
        Config.JumpPower = 50

        notify("Movement settings reset")
    end)
end

-- SIDEBAR / NAVIGATION
local Pages = {
    {"Home", showHome},
    {"Wood Database", showWood},
    {"Calculators", showCalculator},
    {"Quest Tracker", showQuests},
    {"Inventory and Axes", showInventory},
    {"Locations", showLocations},
    {"World Scanner", showScanner},
    {"End Times", showEndTimes},
    {"Movement", showMovement},
    {"Misc", showMisc},
    {"Settings", showSettings}
}

local function openPage(name, callback)
    Footer.Text = "Page: " .. name
    callback()
    applySearch()
end

for _, item in ipairs(Pages) do
    local name = item[1]
    local callback = item[2]

    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, -10, 0, 35)
    b.BackgroundColor3 = Color3.fromRGB(43, 43, 56)
    b.Text = name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 12
    b.Font = Enum.Font.GothamSemibold
    b.Parent = Sidebar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)

    b.MouseButton1Click:Connect(function()
        openPage(name, callback)
    end)
end

-- KEYBIND
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Config.Keybind then
        Main.Visible = not Main.Visible
    end
end)

-- CHARACTER RESPAWN HANDLING
Player.CharacterAdded:Connect(function(char)
    Character = char

    if Flying then
        stopFly()
    end

    if Config.Noclip then
        stopNoclip()
    end
end)

-- CLOSE CLEANUP
Gui.Destroying:Connect(function()
    if Flying then
        stopFly()
    end

    if Config.Noclip then
        stopNoclip()
    end

    if InfiniteJumpConnection then
        InfiniteJumpConnection:Disconnect()
    end

    Workspace.Gravity = OriginalGravity
end)

-- START
openPage("Home", showHome)
notify("LT2 Mega Companion Hub loaded")
