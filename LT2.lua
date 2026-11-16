local function miscPage()
    clearContent()

    addLabel("PLAYER UTILITIES")

    addButton("Reset Character", function()
        Player:LoadCharacter()
    end)

    addButton("Copy Position", function()
        local root = getRoot()
        if not root then error("Character unavailable") end

        local p = root.Position
        local coords = string.format("%.2f, %.2f, %.2f", p.X, p.Y, p.Z)

        if setclipboard then
            setclipboard(coords)
            notify("Copied", coords)
        else
            print(coords)
            notify("Position", coords)
        end
    end)

    addButton("Re-save Position", function()
        local root = getRoot()
        if not root then error("Character unavailable") end
        SavedPosition = root.Position
        notify("Saved", "Position updated")
    end)

    addLabel("WORLD UTILITIES")

    addButton("Scan Secret Locations", function()
        local keywords = {
            "cave", "secret", "maze", "volcano",
            "swamp", "end times", "hidden",
            "gate", "island", "bridge"
        }

        local count = 0

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local name = obj.Name:lower()

                for _, keyword in ipairs(keywords) do
                    if name:find(keyword, 1, true) then
                        count += 1
                        print("[LT2 Secret]", obj:GetFullName())
                        break
                    end
                end
            end
        end

        notify("Secret scanner", count .. " matching objects found. Check console.")
    end)

    addButton("Scan Blueprint Objects", function()
        local count = 0

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("blueprint", 1, true) then
                count += 1
                print("[LT2 Blueprint]", obj:GetFullName())
            end
        end

        notify("Blueprint scanner", count .. " objects found.")
    end)

    addLabel("SPECIAL ITEMS")

    addButton("Find Rukiryie Axe", function()
        local found = 0

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("rukiryie", 1, true)
                or obj.Name:lower():find("ruk", 1, true) then
                found += 1
                print("[LT2 Axe]", obj:GetFullName())
            end
        end

        local backpack = Player:FindFirstChild("Backpack")

        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item.Name:lower():find("ruk", 1, true) then
                    found += 1
                    print("[LT2 Axe Inventory]", item.Name)
                end
            end
        end

        notify("Rukiryie scanner", found .. " matches found.")
    end)

    addButton("Blueprint Purchase Checker", function()
        notify(
            "Blueprints",
            "Purchase requires the game's authorised shop interaction."
        )
    end)

    addLabel("GUI")

    addButton("Return To Main", mainPage)

    addButton("Destroy Hub", function()
        getgenv().LT2HubLoaded = false
        stopFly()
        Gui:Destroy()
    end)
end
