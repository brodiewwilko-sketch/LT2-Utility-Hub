
--[[
    LT2 UTILITY HUB V2
    GUI + INVENTORY + TREE SCANNER
    Default GUI key: Right Shift
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local Character = LP.Character or LP.CharacterAdded:Wait()
local Backpack = LP:WaitForChild("Backpack")

local Settings = {
    ToggleKey = Enum.KeyCode.RightShift,
    RGB = true,
    Accent = Color3.fromRGB(0, 210, 255),
    Search = "",
    CurrentTab = "Home"
}

local savedPosition
local selectedTree
local selectedAxe
local busy = false

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "LT2UtilityV2"
GUI.ResetOnSpawn = false
GUI.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(720, 480)
Main.Position = UDim2.new(0.5, -360, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(15, 18, 27)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

corner(Main, 12)

-- RGB BORDER
local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Parent = Main

-- HEADER
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundColor3 = Color3.fromRGB(23, 28, 41)
Header.BorderSizePixel = 0
Header.Parent = Main
corner(Header, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Position = UDim2.fromOffset(18, 0)
Title.BackgroundTransparency = 1
Title.Text = "LT2 UTILITY HUB  V2"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 19
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Status = Instance.new("TextLabel")
Status.Size = UDim2.fromOffset(130, 40)
Status.Position = UDim2.new(1, -145, 0, 8)
Status.BackgroundTransparency = 1
Status.Text = "● READY"
Status.TextColor3 = Settings.Accent
Status.Font = Enum.Font.GothamBold
Status.TextSize = 12
Status.Parent = Header

-- SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.fromOffset(10, 65)
Sidebar.Size = UDim2.new(0, 165, 1, -75)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
Sidebar.Parent = Main
corner(Sidebar, 9)

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 6)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.Parent = Sidebar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 12)
SidePadding.Parent = Sidebar

-- CONTENT
local Content = Instance.new("ScrollingFrame")
Content.Position = UDim2.fromOffset(185, 65)
Content.Size = UDim2.new(1, -195, 1, -75)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.new()
Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.Parent = Content

local function notify(message)
    Status.Text = "● " .. message
end

local function clearContent()
    for _, v in ipairs(Content:GetChildren()) do
        if v ~= ContentLayout then
            v:Destroy()
        end
    end
end

local function section(name)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = name:upper()
    label.TextColor3 = Settings.Accent
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Content
end

local function addButton(name, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 38)
    b.BackgroundColor3 = Color3.fromRGB(34, 40, 55)
    b.Text = name
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.Parent = Content
    corner(b, 7)

    b.MouseEnter:Connect(function()
        b.BackgroundColor3 = Color3.fromRGB(48, 59, 79)
    end)

    b.MouseLeave:Connect(function()
        b.BackgroundColor3 = Color3.fromRGB(34, 40, 55)
    end)

    b.MouseButton1Click:Connect(callback)
end

local function addSearch()
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 0, 38)
    box.BackgroundColor3 = Color3.fromRGB(30, 36, 49)
    box.PlaceholderText = "Search features..."
    box.Text = ""
    box.TextColor3 = Color3.new(1,1,1)
    box.PlaceholderColor3 = Color3.fromRGB(140,145,160)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.Parent = Content
    corner(box, 7)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        Settings.Search = string.lower(box.Text)

        for _, child in ipairs(Content:GetChildren()) do
            if child:IsA("TextButton") then
                child.Visible =
                    Settings.Search == "" or
                    string.find(
                        string.lower(child.Text),
                        Settings.Search,
                        1,
                        true
                    ) ~= nil
            end
        end
    end)
end

-- AXE DETECTION
local function getAxes()
    Character = LP.Character or Character

    local axes = {}

    -- Equipped tools
    for _, tool in ipairs(Character:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(axes, {
                Tool = tool,
                Equipped = true,
                Name = tool.Name
            })
        end
    end

    -- Backpack tools
    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()

            if name:find("axe") then
                table.insert(axes, {
                    Tool = tool,
                    Equipped = false,
                    Name = tool.Name
                })
            end
        end
    end

    return axes
end

local function getCurrentAxe()
    for _, axe in ipairs(getAxes()) do
        if axe.Equipped then
            return axe
        end
    end

    return nil
end

local function equipAxe(axe)
    if not axe or not axe.Tool then
        return false
    end

    if axe.Equipped then
        selectedAxe = axe.Tool
        notify("Existing axe retained")
        return true
    end

    local humanoid = Character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid:EquipTool(axe.Tool)
        selectedAxe = axe.Tool
        notify("Equipped " .. axe.Name)
        return true
    end

    return false
end

-- POSITION
local function savePosition()
    local root = Character:FindFirstChild("HumanoidRootPart")

    if root then
        savedPosition = root.CFrame
        notify("Position saved")
    end
end

local function returnPosition()
    local root = Character:FindFirstChild("HumanoidRootPart")

    if root and savedPosition then
        root.CFrame = savedPosition
        notify("Position restored")
    else
        notify("No saved position")
    end
end

-- TREE SCANNER
local function getTrees()
    local trees = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local class = obj:FindFirstChild("TreeClass")
            local section = obj:FindFirstChild("WoodSection")

            if class and section then
                table.insert(trees, obj)
            end
        end
    end

    return trees
end

local function scanTrees()
    local trees = getTrees()
    local types = {}

    for _, tree in ipairs(trees) do
        local class = tree:FindFirstChild("TreeClass")

        if class then
            types[tostring(class.Value)] =
                (types[tostring(class.Value)] or 0) + 1
        end
    end

    print("===== LT2 TREE SCANNER =====")

    for name, amount in pairs(types) do
        print(name, amount)
    end

    notify("Found " .. #trees .. " tree models")
end

-- INVENTORY SORTING
local function getInventory()
    local items = {}

    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(items, tool)
        end
    end

    table.sort(items, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    return items
end

local function showInventory()
    print("===== INVENTORY =====")

    for i, item in ipairs(getInventory()) do
        print(i, item.Name)
    end

    notify("Inventory sorted alphabetically")
end

local function countItems()
    local count = #getInventory()
    notify("Inventory: " .. count .. " items")
end

-- HOME
local function loadTab(tab)
    Settings.CurrentTab = tab
    clearContent()

    if tab == "Home" then
        section("Dashboard")
        addSearch()

        addButton("Save Current Position", savePosition)
        addButton("Return To Saved Position", returnPosition)
        addButton("Scan All Trees", scanTrees)
        addButton("Show Inventory", showInventory)
        addButton("Count Inventory Items", countItems)

        section("Quick Information")

        addButton("Check Equipped Axe", function()
            local axe = getCurrentAxe()

            if axe then
                notify("Holding " .. axe.Name)
            else
                notify("No axe equipped")
            end
        end)

    elseif tab == "Wood" then
        section("Wood Manager")

        addButton("Scan Tree Types", scanTrees)

        for _, tree in ipairs(getTrees()) do
            local class = tree:FindFirstChild("TreeClass")

            if class then
                addButton("Select " .. tostring(class.Value), function()
                    selectedTree = tree
                    notify("Selected " .. tostring(class.Value))
                end)
            end
        end

    elseif tab == "Items" then
        section("Inventory Manager")

        addButton("Sort Alphabetically", showInventory)
        addButton("Count Items", countItems)

        addButton("Refresh Inventory", function()
            notify("Inventory refreshed")
            loadTab("Items")
        end)

        section("Axe Manager")

        addButton("Find All Axes", function()
            local axes = getAxes()

            for _, axe in ipairs(axes) do
                print(axe.Name, axe.Equipped and "Equipped" or "Backpack")
            end

            notify(#axes .. " axes detected")
        end)

        addButton("Keep Current Axe", function()
            local axe = getCurrentAxe()

            if axe then
                selectedAxe = axe.Tool
                notify("Keeping " .. axe.Name)
            else
                notify("No equipped axe")
            end
        end)

        addButton("Equip First Available Axe", function()
            local axes = getAxes()

            if #axes > 0 then
                for _, axe in ipairs(axes) do
                    if not axe.Equipped then
                        equipAxe(axe)
                        return
                    end
                end

                notify("Axe already equipped")
            else
                notify("No axes found")
            end
        end)

    elseif tab == "Movement" then
        section("Movement Information")

        addButton("Save Position", savePosition)
        addButton("Return Position", returnPosition)

        addButton("Show Current Speed", function()
            local h = Character:FindFirstChildOfClass("Humanoid")

            if h then
                notify("Walk speed: " .. h.WalkSpeed)
            end
        end)

    elseif tab == "Teleports" then
        section("Saved Locations")

        addButton("Save Current Location", savePosition)
        addButton("Return To Saved Location", returnPosition)

        addButton("Select Tree Location", function()
            if selectedTree and selectedTree.Parent then
                local part = selectedTree:FindFirstChild("WoodSection")
                local root = Character:FindFirstChild("HumanoidRootPart")

                if part and root then
                    root.CFrame = part.CFrame + Vector3.new(5,3,0)
                    notify("Tree location reached")
                end
            else
                notify("Select a tree first")
            end
        end)

    elseif tab == "Settings" then
        section("Interface Settings")

        addButton("Toggle RGB Border", function()
            Settings.RGB = not Settings.RGB
            notify("RGB: " .. tostring(Settings.RGB))
        end)

        addButton("Change GUI Keybind", function()
            notify("Press a key to set new toggle")
            local connection

            connection = UIS.InputBegan:Connect(function(input, processed)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Settings.ToggleKey = input.KeyCode
                    notify("Keybind: " .. input.KeyCode.Name)
                    connection:Disconnect()
                end
            end)
        end)

        addButton("Reset Keybind", function()
            Settings.ToggleKey = Enum.KeyCode.RightShift
            notify("Reset to Right Shift")
        end)

        addButton("Reset Interface", function()
            Main.Size = UDim2.fromOffset(720, 480)
            Main.Position = UDim2.new(0.5, -360, 0.5, -240)
            notify("Interface reset")
        end)

    elseif tab == "Misc" then
        section("Miscellaneous")

        addButton("Secret", function()
            local popup = Instance.new("TextLabel")
            popup.Size = UDim2.fromOffset(380, 65)
            popup.Position = UDim2.new(0.5, -190, 0.12, 0)
            popup.BackgroundColor3 = Color3.fromRGB(25,30,45)
            popup.TextColor3 = Color3.new(1,1,1)
            popup.Font = Enum.Font.GothamBold
            popup.TextSize = 18
            popup.Text = "oliver vaughn 187 kingsway"
            popup.Parent = GUI
            corner(popup, 10)

            task.delay(5, function()
                popup:Destroy()
            end)
        end)

        addButton("Hide GUI", function()
            Main.Visible = false
        end)

        addButton("Destroy GUI", function()
            GUI:Destroy()
        end)
    end
end

-- SIDEBAR
local tabs = {
    "Home",
    "Wood",
    "Items",
    "Movement",
    "Teleports",
    "Settings",
    "Misc"
}

for _, tab in ipairs(tabs) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 38)
    b.BackgroundColor3 = Color3.fromRGB(34,40,55)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = tab
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = Sidebar
    corner(b, 7)

    b.MouseButton1Click:Connect(function()
        loadTab(tab)
    end)
end

-- RGB ANIMATION
local hue = 0

RunService.RenderStepped:Connect(function(dt)
    if Settings.RGB then
        hue = (hue + dt * 0.12) % 1
        local color = Color3.fromHSV(hue, 0.85, 1)
        Stroke.Color = color
        Settings.Accent = color
    end
end)

-- KEYBIND
UIS.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Settings.ToggleKey then
        Main.Visible = not Main.Visible
    end
end)

LP.CharacterAdded:Connect(function(char)
    Character = char
    Backpack = LP:WaitForChild("Backpack")
end)

loadTab("Home")
notify("LT2 Utility Hub V2 Loaded")
