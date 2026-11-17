
--==================================================
-- LT2 ULTIMATE UTILITY HUB
-- Delta Executor
--==================================================

if _G.LT2HubRunning then
    pcall(function()
        game:GetService("CoreGui"):FindFirstChild("LT2UltimateHub"):Destroy()
    end)
    _G.LT2HubRunning = false
end

_G.LT2HubRunning = true

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local savedPosition
local selectedTree
local selectedTreeClass
local flying = false
local flySpeed = 65
local flyConnection
local selectedHighlight
local currentTab = "Wood"

local function notify(title, message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = tostring(message),
            Duration = 5
        })
    end)
end

local function getCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function getRoot()
    return getCharacter():WaitForChild("HumanoidRootPart")
end

local function savePosition()
    savedPosition = getRoot().CFrame
    notify("Position saved", "Your position has been saved.")
end

local function returnPosition()
    if not savedPosition then
        notify("Error", "No saved position.")
        return
    end

    getRoot().CFrame = savedPosition
    notify("Position", "Returned to saved position.")
end

--==================================================
-- GUI SETUP
--==================================================

local parent = (gethui and gethui()) or game:GetService("CoreGui")

local old = parent:FindFirstChild("LT2UltimateHub")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "LT2UltimateHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(620, 455)
main.Position = UDim2.new(0.5, -310, 0.5, -227)
main.BackgroundColor3 = Color3.fromRGB(24, 25, 29)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 45)
top.BackgroundColor3 = Color3.fromRGB(120, 72, 37)
top.BorderSizePixel = 0
top.Parent = main

Instance.new("UICorner", top).CornerRadius = UDim.new(0, 10)

local heading = Instance.new("TextLabel")
heading.Size = UDim2.new(1, -60, 1, 0)
heading.Position = UDim2.fromOffset(15, 0)
heading.BackgroundTransparency = 1
heading.Text = "LT2  |  ULTIMATE HUB"
heading.TextColor3 = Color3.new(1,1,1)
heading.Font = Enum.Font.GothamBold
heading.TextSize = 18
heading.TextXAlignment = Enum.TextXAlignment.Left
heading.Parent = top

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(35, 32)
close.Position = UDim2.new(1, -42, 0, 6)
close.BackgroundColor3 = Color3.fromRGB(160, 48, 48)
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.Parent = top
close.MouseButton1Click:Connect(function()
    gui:Destroy()
    _G.LT2HubRunning = false
end)

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(0, 45)
sidebar.Size = UDim2.new(0, 145, 1, -45)
sidebar.BackgroundColor3 = Color3.fromRGB(31, 32, 37)
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(155, 57)
content.Size = UDim2.new(1, -167, 1, -69)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.Parent = content

local function clearContent()
    for _, item in ipairs(content:GetChildren()) do
        if item:IsA("GuiObject") and item ~= layout then
            item:Destroy()
        end
    end
end

local function addLabel(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 31)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 195, 150)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = content
    return label
end

local function addButton(text, callback, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -8, 0, 36)
    button.BackgroundColor3 = color or Color3.fromRGB(91, 65, 46)
    button.Text = text
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 13
    button.Parent = content

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    button.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then
            notify("Feature error", err)
        end
    end)

    return button
end

--==================================================
-- TREE DETECTION
--==================================================

local function getTreeRegions()
    local regions = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "TreeRegion" then
            table.insert(regions, obj)
        end
    end

    return regions
end

local function getTreeClasses()
    local classes = {}
    local seen = {}

    for _, region in ipairs(getTreeRegions()) do
        for _, tree in ipairs(region:GetChildren()) do
            local class = tree:FindFirstChild("TreeClass")

            if class and not seen[class.Value] then
                seen[class.Value] = true
                table.insert(classes, class.Value)
            end
        end
    end

    table.sort(classes)
    return classes
end

local function findTrees(className)
    local trees = {}

    for _, region in ipairs(getTreeRegions()) do
        for _, tree in ipairs(region:GetChildren()) do
            local class = tree:FindFirstChild("TreeClass")

            if class and class.Value == className then
                table.insert(trees, tree)
            end
        end
    end

    return trees
end

local function highlightTree(tree)
    if selectedHighlight then
        selectedHighlight:Destroy()
        selectedHighlight = nil
    end

    if not tree then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "LT2TreeHighlight"
    highlight.FillColor = Color3.fromRGB(255, 170, 55)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.75
    highlight.Adornee = tree
    highlight.Parent = gui

    selectedHighlight = highlight
end

local function selectTreeClass(className)
    local trees = findTrees(className)

    if #trees == 0 then
        notify("Tree search", "No " .. className .. " trees found.")
        return
    end

    selectedTreeClass = className
    selectedTree = trees[1]

    highlightTree(selectedTree)

    local section = selectedTree:FindFirstChild("WoodSection")
    if section then
        Camera.CFrame = CFrame.lookAt(
            Camera.CFrame.Position,
            section.Position
        )
    end

    notify("Selected tree", className .. " | " .. #trees .. " found.")
end

--==================================================
-- AXE INVENTORY
--==================================================

local function getAxeTools()
    local result = {}

    for _, container in ipairs({
        Player:FindFirstChildOfClass("Backpack"),
        getCharacter()
    }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local toolName = tool:FindFirstChild("ToolName")
                    if toolName then
                        table.insert(result, tool)
                    end
                end
            end
        end
    end

    return result
end

local function equipAxe(tool)
    local humanoid = getCharacter():FindFirstChildOfClass("Humanoid")
    if not humanoid then
        notify("Axe", "Character humanoid not found.")
        return
    end

    humanoid:EquipTool(tool)
    notify("Axe equipped", tool.Name)
end

--==================================================
-- END TIMES TREE VIEWER
--==================================================

local function viewEndTimesTree()
    local found = {}

    for _, region in ipairs(getTreeRegions()) do
        for _, tree in ipairs(region:GetChildren()) do
            local class = tree:FindFirstChild("TreeClass")

            if class and (
                string.find(string.lower(class.Value), "end")
                or class.Value == "LoneCave"
            ) then
                local section = tree:FindFirstChild("WoodSection")

                if section then
                    table.insert(found, {
                        tree = tree,
                        position = section.Position,
                        distance = (root().Position - section.Position).Magnitude
                    })
                end
            end
        end
    end

    if #found == 0 then
        notify("End Times", "No matching tree found in this server.")
        return
    end

    table.sort(found, function(a,b)
        return a.distance < b.distance
    end)

    local closest = found[1]

    highlightTree(closest.tree)

    Camera.CFrame = CFrame.lookAt(
        Camera.CFrame.Position,
        closest.position
    )

    notify(
        "End Times Tree",
        math.floor(closest.distance) .. " studs away"
    )
end

--==================================================
-- FLY
--==================================================

local function stopFly()
    flying = false

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    local r = getCharacter():FindFirstChild("HumanoidRootPart")

    if r then
        for _, name in ipairs({"LT2FlyVelocity", "LT2FlyGyro"}) do
            local obj = r:FindFirstChild(name)
            if obj then obj:Destroy() end
        end
    end

    notify("Fly", "Fly disabled.")
end

local function startFly()
    if flying then return end

    flying = true

    local r = getRoot()

    local velocity = Instance.new("BodyVelocity")
    velocity.Name = "LT2FlyVelocity"
    velocity.MaxForce = Vector3.new(1000000, 1000000, 1000000)
    velocity.Velocity = Vector3.zero
    velocity.Parent = r

    local gyro = Instance.new("BodyGyro")
    gyro.Name = "LT2FlyGyro"
    gyro.MaxTorque = Vector3.new(1000000, 1000000, 1000000)
    gyro.P = 9000
    gyro.Parent = r

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not r.Parent then return end

        local cam = workspace.CurrentCamera
        local direction = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            direction += cam.CFrame.LookVector
        end

        if UIS:IsKeyDown(Enum.KeyCode.S) then
            direction -= cam.CFrame.LookVector
        end

        if UIS:IsKeyDown(Enum.KeyCode.A) then
            direction -= cam.CFrame.RightVector
        end

        if UIS:IsKeyDown(Enum.KeyCode.D) then
            direction += cam.CFrame.RightVector
        end

        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.yAxis
        end

        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.yAxis
        end

        velocity.Velocity =
            direction.Magnitude > 0
            and direction.Unit * flySpeed
            or Vector3.zero

        gyro.CFrame = cam.CFrame
    end)

    notify("Fly enabled", "WASD move | Space up | Ctrl down")
end

--==================================================
-- LOCATION TELEPORTS
--==================================================

local locations = {
    "Wood R Us",
    "Land Store",
    "Volcano",
    "Cave",
    "Palm Island",
    "Spawn",
    "Fancy Furnishings",
    "Boxed Cars",
    "Furniture Store"
}

local function findLocation(name)
    local wanted = string.lower(name)

    for _, obj in ipairs(workspace:GetDescendants()) do
        if string.find(string.lower(obj.Name), wanted, 1, true) then
            if obj:IsA("BasePart") then
                return obj
            elseif obj:IsA("Model") then
                return obj.PrimaryPart
                    or obj:FindFirstChildWhichIsA("BasePart", true)
            end
        end
    end
end

local function teleportToLocation(name)
    local target = findLocation(name)

    if not target then
        notify("Teleport failed", "Couldn't find " .. name)
        return
    end

    savedPosition = getRoot().CFrame
    getRoot().CFrame = target.CFrame + Vector3.new(0, 5, 0)

    notify("Teleport", "Moved to " .. name)
end

--==================================================
-- SECRET
--==================================================

local function showSecret()
    local popup = Instance.new("TextLabel")
    popup.Size = UDim2.fromOffset(360, 65)
    popup.Position = UDim2.new(0.5, -180, 0.12, 0)
    popup.BackgroundColor3 = Color3.fromRGB(35, 25, 20)
    popup.TextColor3 = Color3.fromRGB(255, 215, 150)
    popup.Text = "oliver vaughn 187 kingsway"
    popup.Font = Enum.Font.GothamBold
    popup.TextSize = 19
    popup.Parent = gui

    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 9)

    task.delay(5, function()
        if popup then popup:Destroy() end
    end)
end

--==================================================
-- PAGES
--==================================================

local function showTab(tab)
    currentTab = tab
    clearContent()

    if tab == "Wood" then
        addLabel("WOOD / TREE SELECTOR")

        addButton("REFRESH TREE TYPES", function()
            showTab("Wood")
            notify("Trees", "Tree list refreshed.")
        end, Color3.fromRGB(60, 105, 65))

        addButton("VIEW SELECTED TREE", function()
            if not selectedTree or not selectedTree.Parent then
                notify("Tree", "Select a tree first.")
                return
            end

            local section = selectedTree:FindFirstChild("WoodSection")
            if section then
                Camera.CFrame = CFrame.lookAt(
                    Camera.CFrame.Position,
                    section.Position
                )
            end
        end)

        addButton("CLEAR TREE HIGHLIGHT", function()
            if selectedHighlight then
                selectedHighlight:Destroy()
                selectedHighlight = nil
            end
            selectedTree = nil
            selectedTreeClass = nil
        end)

        addLabel("AVAILABLE TREE TYPES")

        local classes = getTreeClasses()

        if #classes == 0 then
            addLabel("No trees detected.")
        end

        for _, className in ipairs(classes) do
            addButton(className, function()
                selectTreeClass(className)
            end)
        end

        addLabel("Bring Wood requires supported game-side interactions.")

    elseif tab == "Movement" then
        addLabel("MOVEMENT")

        addButton("ENABLE FLY", startFly, Color3.fromRGB(55, 115, 75))
        addButton("DISABLE FLY", stopFly, Color3.fromRGB(130, 55, 55))

        addButton("FLY SPEED +", function()
            flySpeed = math.min(flySpeed + 10, 200)
            notify("Fly speed", flySpeed)
        end)

        addButton("FLY SPEED -", function()
            flySpeed = math.max(flySpeed - 10, 10)
            notify("Fly speed", flySpeed)
        end)

        addButton("SAVE POSITION", savePosition)
        addButton("RETURN TO SAVED POSITION", returnPosition)

    elseif tab == "Teleports" then
        addLabel("MAIN LOCATIONS")

        addButton("SAVE POSITION", savePosition)
        addButton("RETURN TO SAVED POSITION", returnPosition)

        for _, name in ipairs(locations) do
            addButton(name, function()
                teleportToLocation(name)
            end)
        end

    elseif tab == "Visuals" then
        addLabel("TREE VIEWER")

        addButton("VIEW END TIMES TREE", viewEndTimesTree)
        addButton("CLEAR HIGHLIGHT", function()
            if selectedHighlight then
                selectedHighlight:Destroy()
                selectedHighlight = nil
            end
        end)

        addButton("REFRESH TREE TYPES", function()
            local classes = getTreeClasses()
            notify("Tree types", table.concat(classes, ", "))
        end)

    elseif tab == "Axes" then
        addLabel("AXE INVENTORY")

        local axes = getAxeTools()

        if #axes == 0 then
            addLabel("No axes detected in inventory.")
        end

        for _, tool in ipairs(axes) do
            local toolName = tool:FindFirstChild("ToolName")
            local name = toolName and toolName.Value or tool.Name

            addButton("EQUIP  " .. name, function()
                equipAxe(tool)
            end)
        end

        addButton("REFRESH AXE LIST", function()
            showTab("Axes")
        end)

    elseif tab == "Misc" then
        addLabel("MISCELLANEOUS")

        addButton("SECRET", showSecret, Color3.fromRGB(130, 80, 35))

        addButton("REJOIN SERVER", function()
            game:GetService("TeleportService"):Teleport(
                game.PlaceId,
                Player
            )
        end)

        addButton("RESET CHARACTER", function()
            getCharacter():BreakJoints()
        end)

        addButton("HIDE GUI", function()
            main.Visible = false
        end)

        addButton("SHOW GUI", function()
            main.Visible = true
        end)
    end
end

--==================================================
-- SIDEBAR
--==================================================

local tabs = {
    "Wood",
    "Movement",
    "Teleports",
    "Visuals",
    "Axes",
    "Misc"
}

for i, tab in ipairs(tabs) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -12, 0, 38)
    button.Position = UDim2.fromOffset(6, 9 + (i-1)*45)
    button.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Text = tab
    button.Parent = sidebar

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    button.MouseButton1Click:Connect(function()
        showTab(tab)
    end)
end

--==================================================
-- DRAGGABLE WINDOW
--==================================================

local dragging = false
local dragStart
local startPosition

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart

        main.Position = UDim2.new(
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

--==================================================
-- STARTUP
--==================================================

savedPosition = getRoot().CFrame
showTab("Wood")

notify("LT2 Ultimate Hub", "Successfully loaded!")
print("LT2 Ultimate Hub loaded successfully.")
