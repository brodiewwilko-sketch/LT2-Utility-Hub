
--[[
    LT2 UTILITY HUB
    Client-side Delta Executor script
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local Character = LP.Character or LP.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local Remote = RS:WaitForChild("Interaction"):WaitForChild("RemoteProxy")
local AxeClasses = RS:WaitForChild("AxeClasses")

local savedPosition = nil
local selectedTree = nil
local selectedClass = nil
local flying = false
local flySpeed = 65
local flyConnection = nil
local selectedTab = "Main"

-- WOOD TYPES
local WoodNames = {
    "Oak", "Elm", "Birch", "Cherry", "Walnut",
    "Koa", "Palm", "Fir", "Pine", "Blue Spruce",
    "Gold", "Zombie", "Lava", "Volcano",
    "Frost", "Cavecrawler", "Phantom",
    "Snowglow", "Spooky", "Sinister",
    "Spook", "LoneCave"
}

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "LT2UtilityHub"
GUI.ResetOnSpawn = false
GUI.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(590, 420)
Main.Position = UDim2.new(0.5, -295, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(20, 22, 29)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Color3.fromRGB(30, 34, 45)
Header.Text = "LT2  |  UTILITY HUB"
Header.TextColor3 = Color3.fromRGB(255,255,255)
Header.TextSize = 19
Header.Font = Enum.Font.GothamBold
Header.Parent = Main

local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.fromOffset(0, 48)
Sidebar.Size = UDim2.new(0, 145, 1, -48)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 28, 37)
Sidebar.Parent = Main

local Content = Instance.new("ScrollingFrame")
Content.Position = UDim2.fromOffset(155, 58)
Content.Size = UDim2.new(1, -165, 1, -68)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.new()
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.Parent = Content

local function clearContent()
    for _, v in ipairs(Content:GetChildren()) do
        if v:IsA("GuiObject") and v ~= Layout then
            v:Destroy()
        end
    end
end

local function button(name, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 36)
    b.BackgroundColor3 = Color3.fromRGB(42, 48, 63)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = name
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.Parent = Content

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b

    b.MouseButton1Click:Connect(callback)
    return b
end

local function label(name)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 27)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = Color3.fromRGB(110, 190, 255)
    l.TextSize = 13
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = Content
end

local function notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "LT2 Utility Hub",
            Text = msg,
            Duration = 4
        })
    end)
end

-- POSITION SYSTEM
local function savePosition()
    if Root then
        savedPosition = Root.CFrame
        notify("Position saved!")
    end
end

local function returnPosition()
    if savedPosition and Root then
        Root.CFrame = savedPosition
        notify("Returned to saved position!")
    else
        notify("No saved position!")
    end
end

-- TREE SCANNER
local function getRegions()
    local regions = {}

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "TreeRegion" then
            table.insert(regions, obj)
        end
    end

    return regions
end

local function getTrees()
    local trees = {}

    for _, region in ipairs(getRegions()) do
        for _, tree in ipairs(region:GetChildren()) do
            if tree:IsA("Model")
            and tree:FindFirstChild("TreeClass")
            and tree:FindFirstChild("CutEvent")
            and tree:FindFirstChild("WoodSection") then

                local owner = tree:FindFirstChild("Owner")

                if owner and owner.Value == nil then
                    table.insert(trees, tree)
                end
            end
        end
    end

    return trees
end

local function getTreeClasses()
    local classes = {}

    for _, tree in ipairs(getTrees()) do
        local class = tree.TreeClass.Value
        classes[class] = true
    end

    return classes
end

-- AXE SYSTEM
local function getAxeStats(axeName, treeClass)
    local module = AxeClasses:FindFirstChild("AxeClass_" .. axeName)

    if not module then
        return nil
    end

    local success, stats = pcall(function()
        return require(module).new()
    end)

    if not success or not stats then
        return nil
    end

    if stats.SpecialTrees and stats.SpecialTrees[treeClass] then
        for key, value in pairs(stats.SpecialTrees[treeClass]) do
            stats[key] = value
        end
    end

    return stats
end

local function findBestAxe(treeClass)
    local axes = {}

    for _, tool in ipairs(LP.Backpack:GetChildren()) do
        local toolName = tool:FindFirstChild("ToolName")

        if tool:IsA("Tool") and toolName then
            local stats = getAxeStats(toolName.Value, treeClass)

            if stats then
                table.insert(axes, {
                    Tool = tool,
                    Stats = stats
                })
            end
        end
    end

    table.sort(axes, function(a, b)
        return (a.Stats.Damage or 0) > (b.Stats.Damage or 0)
    end)

    return axes[1]
end

-- TREE INFORMATION
local function getTreeMass(tree)
    local mass = 0

    for _, part in ipairs(tree:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "Leaves" then
            mass = mass + part.Mass
        end
    end

    return mass
end

-- SELECTED TREE
local function findTree(class)
    local matches = {}

    for _, tree in ipairs(getTrees()) do
        if tree.TreeClass.Value == class then
            table.insert(matches, tree)
        end
    end

    table.sort(matches, function(a, b)
        return getTreeMass(a) > getTreeMass(b)
    end)

    return matches[1]
end

-- BRING WOOD
-- Uses the game's chopping and dragging interaction.
local busy = false

local function bringWood(class)
    if busy then
        notify("Already processing a tree!")
        return
    end

    busy = true

    task.spawn(function()
        local success, err = pcall(function()

            savePosition()

            local tree = findTree(class)

            if not tree then
                error("No available " .. class .. " tree found")
            end

            local axeData = findBestAxe(class)

            if not axeData then
                error("No compatible axe found in backpack")
            end

            local axe = axeData.Tool
            local stats = axeData.Stats

            Humanoid:UnequipTools()
            task.wait(0.2)

            Humanoid:EquipTool(axe)
            task.wait(0.3)

            local startPosition = savedPosition

            notify("Chopping " .. class .. "...")

            local wood = nil
            local connection

            connection = workspace.LogModels.ChildAdded:Connect(function(log)
                task.wait()

                local owner = log:FindFirstChild("Owner")

                if owner and owner.Value == LP then
                    wood = log
                    connection:Disconnect()
                end
            end)

            local section = tree:FindFirstChild("WoodSection")

            if not section then
                error("Tree section unavailable")
            end

            Root.CFrame = CFrame.new(
                section.Position + Vector3.new(5, 3, 0)
            )

            task.wait(0.3)

            local properties = {
                tool = axe,
                height = 0.3,
                faceVector = Vector3.new(1, 0, 0),
                sectionId = 1,
                hitPoints = stats.Damage,
                cooldown = stats.SwingCooldown,
                cuttingClass = "Axe"
            }

            local timeout = os.clock() + 180

            repeat
                if not tree.Parent then break end

                Remote:FireServer(tree.CutEvent, properties)

                task.wait(stats.SwingCooldown or 0.3)

            until wood or os.clock() > timeout

            if connection then
                connection:Disconnect()
            end

            if not wood then
                error("Chopping timed out or no log was created")
            end

            notify("Tree chopped! Bringing wood back...")

            task.wait(0.2)

            wood.PrimaryPart = wood:FindFirstChild("WoodSection")

            if not wood.PrimaryPart then
                error("Wood primary part unavailable")
            end

            for i = 1, 60 do
                pcall(function()
                    Remote:FireServer(
                        RS.Interaction.ClientIsDragging,
                        wood
                    )
                end)

                task.wait()
            end

            for i = 1, 60 do
                wood.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
                wood:PivotTo(startPosition)
                task.wait()
            end

            Root.CFrame = startPosition

            notify(class .. " wood returned!")

        end)

        busy = false

        if not success then
            notify("Error: " .. tostring(err))
            if savedPosition and Root then
                Root.CFrame = savedPosition
            end
        end
    end)
end

-- FLY SYSTEM
local function toggleFly()
    flying = not flying

    if flying then
        local attachment = Instance.new("Attachment")
        attachment.Parent = Root

        local velocity = Instance.new("LinearVelocity")
        velocity.Attachment0 = attachment
        velocity.MaxForce = math.huge
        velocity.VectorVelocity = Vector3.zero
        velocity.Parent = Root

        flyConnection = RunService.RenderStepped:Connect(function()
            if not flying or not Root then return end

            local camera = workspace.CurrentCamera
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

            velocity.VectorVelocity = direction * flySpeed
        end)

        notify("Fly enabled - WASD + Space/Ctrl")

        task.spawn(function()
            repeat task.wait() until not flying

            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end

            velocity:Destroy()
            attachment:Destroy()
        end)
    else
        notify("Fly disabled")
    end
end

-- TREE VIEW
local function showTreeInfo()
    local classes = getTreeClasses()
    local count = 0

    for class in pairs(classes) do
        count += 1
        print("[LT2] Tree detected:", class)
    end

    notify(count .. " different tree types detected. Check F9 console.")
end

-- TAB CONTENT
local function loadTab(tab)
    selectedTab = tab
    clearContent()

    if tab == "Main" then

        label("POSITION")
        button("Save Current Position", savePosition)
        button("Return To Saved Position", returnPosition)

        label("QUICK ACTIONS")
        button("Refresh Tree Scanner", showTreeInfo)
        button("Show Secret", function()
            local popup = Instance.new("TextLabel")
            popup.Size = UDim2.fromOffset(350, 65)
            popup.Position = UDim2.new(0.5, -175, 0.15, 0)
            popup.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            popup.TextColor3 = Color3.new(1, 1, 1)
            popup.Font = Enum.Font.GothamBold
            popup.TextSize = 18
            popup.Text = "oliver vaughn 187 kingsway"
            popup.Parent = GUI

            Instance.new("UICorner", popup)

            task.delay(5, function()
                popup:Destroy()
            end)
        end)

    elseif tab == "Wood" then

        label("WOOD HARVESTING")
        button("Refresh Tree List", function()
            loadTab("Wood")
            notify("Tree list refreshed")
        end)

        for class in pairs(getTreeClasses()) do
            button("Bring " .. class, function()
                selectedClass = class
                bringWood(class)
            end)
        end

        label("ADDITIONAL WOOD TYPES")

        for _, class in ipairs(WoodNames) do
            button("Search " .. class, function()
                local tree = findTree(class)

                if tree then
                    selectedTree = tree
                    notify(class .. " tree found")
                else
                    notify("No " .. class .. " tree currently available")
                end
            end)
        end

    elseif tab == "Movement" then

        label("FLIGHT")
        button("Toggle Fly", toggleFly)

        button("Increase Fly Speed", function()
            flySpeed = math.min(flySpeed + 10, 200)
            notify("Fly speed: " .. flySpeed)
        end)

        button("Decrease Fly Speed", function()
            flySpeed = math.max(flySpeed - 10, 10)
            notify("Fly speed: " .. flySpeed)
        end)

        label("CHARACTER")
        button("Speed +", function()
            Humanoid.WalkSpeed = Humanoid.WalkSpeed + 5
        end)

        button("Speed -", function()
            Humanoid.WalkSpeed = math.max(16, Humanoid.WalkSpeed - 5)
        end)

        button("Jump Boost", function()
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = 90
        end)

        button("Reset Movement", function()
            Humanoid.WalkSpeed = 16
            Humanoid.JumpPower = 50
        end)

    elseif tab == "Teleports" then

        label("SAVED LOCATIONS")

        button("Save Teleport Point", function()
            savePosition()
        end)

        button("Teleport To Saved Point", returnPosition)

        label("TREE TELEPORT")

        button("Teleport To Selected Tree", function()
            if selectedTree and selectedTree.Parent then
                Root.CFrame = selectedTree.WoodSection.CFrame
                    + Vector3.new(5, 3, 0)
            else
                notify("Select a tree first")
            end
        end)

    elseif tab == "Tree Info" then

        label("WORLD TREE SCANNER")

        button("Scan All Trees", showTreeInfo)

        button("Print Tree Locations", function()
            for _, tree in ipairs(getTrees()) do
                print(
                    tree.TreeClass.Value,
                    tree.WoodSection.Position
                )
            end

            notify("Tree positions printed to console")
        end)

        button("Show Selected Tree", function()
            if selectedTree then
                notify(selectedTree.TreeClass.Value)
            else
                notify("No tree selected")
            end
        end)

        label("END TIMES")
        button("Find Phantom Trees", function()
            local tree = findTree("LoneCave")

            if tree then
                selectedTree = tree
                notify("Phantom tree detected")
            else
                notify("No accessible Phantom tree found")
            end
        end)

    elseif tab == "Axes" then

        label("AXE INVENTORY")

        for _, tool in ipairs(LP.Backpack:GetChildren()) do
            if tool:FindFirstChild("ToolName") then
                button(tool.ToolName.Value, function()
                    Humanoid:EquipTool(tool)
                    notify("Equipped " .. tool.ToolName.Value)
                end)
            end
        end

        button("Unequip All Axes", function()
            Humanoid:UnequipTools()
        end)

    elseif tab == "Misc" then

        label("MISCELLANEOUS")

        button("Show Secret", function()
            loadTab("Main")
            task.wait(0.1)

            local popup = Instance.new("TextLabel")
            popup.Size = UDim2.fromOffset(350, 65)
            popup.Position = UDim2.new(0.5, -175, 0.15, 0)
            popup.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
            popup.TextColor3 = Color3.new(1, 1, 1)
            popup.Text = "oliver vaughn 187 kingsway"
            popup.Font = Enum.Font.GothamBold
            popup.TextSize = 18
            popup.Parent = GUI

            task.delay(5, function()
                popup:Destroy()
            end)
        end)

        button("Refresh Character", function()
            Character = LP.Character
            Root = Character:WaitForChild("HumanoidRootPart")
            Humanoid = Character:WaitForChild("Humanoid")
            notify("Character refreshed")
        end)

        button("Hide GUI", function()
            Main.Visible = false
        end)

        button("Destroy GUI", function()
            flying = false
            if flyConnection then
                flyConnection:Disconnect()
            end
            GUI:Destroy()
        end)

    end
end

-- SIDEBAR TABS
local tabs = {
    "Main",
    "Wood",
    "Movement",
    "Teleports",
    "Tree Info",
    "Axes",
    "Misc"
}

for i, tab in ipairs(tabs) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 38)
    b.Position = UDim2.fromOffset(6, (i-1)*43 + 8)
    b.BackgroundColor3 = Color3.fromRGB(40, 45, 58)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = tab
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = Sidebar

    Instance.new("UICorner", b)

    b.MouseButton1Click:Connect(function()
        loadTab(tab)
    end)
end

-- SHOW / HIDE WITH RIGHT SHIFT
UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

LP.CharacterAdded:Connect(function(char)
    Character = char
    Root = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end)

loadTab("Main")
notify("LT2 Utility Hub loaded!")
