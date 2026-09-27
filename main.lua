--==================================================
-- BIGBOSS TELEPORTER (Waypoint Safe Path)
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local BLACK  = Color3.fromRGB(7, 9, 14)
local PANEL  = Color3.fromRGB(15, 20, 32)
local PANEL2 = Color3.fromRGB(24, 31, 47)
local ORANGE = Color3.fromRGB(255, 166, 0)
local WHITE  = Color3.fromRGB(235, 235, 235)
local GREY   = Color3.fromRGB(130, 140, 155)
local GREEN  = Color3.fromRGB(60, 200, 110)
local RED    = Color3.fromRGB(220, 70, 70)
local CYAN   = Color3.fromRGB(80, 200, 255)

--==================================================
-- CONFIG
--==================================================

local CONFIG = {
    GlideStartSpeed   = 350,
    GlideMaxSpeed     = 900,
    GlideHeight       = 20,
    CooldownTime      = 1.2,
    AutoReturnEnabled = false,
    ReturnPoint       = nil,
    ReturnCooldown    = 1.0,

    -- ⭐ WAYPOINT (safe hub coordinate)
    -- Character flies here FIRST, then to destination
    Waypoint          = Vector3.new(596, 70, -325),
    UseWaypoint       = true,
}

--==================================================
-- STATE
--==================================================

local savedPoints = {}
local gliding = false
local lastTeleport = 0
local lastReturn = 0
local autoReturnConn = nil

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "BIGBOSS_TELEPORTER"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = player:WaitForChild("PlayerGui")

-- Circle logo
local logo = Instance.new("TextButton")
logo.Name = "CircleLogo"
logo.Size = UDim2.fromOffset(55, 55)
logo.Position = UDim2.new(0, 20, 0.5, -27)
logo.BackgroundColor3 = BLACK
logo.Text = "BBHV3"
logo.TextColor3 = ORANGE
logo.TextSize = 11
logo.Font = Enum.Font.GothamBold
logo.AutoButtonColor = false
logo.Visible = false
logo.BorderSizePixel = 0
logo.Parent = gui

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(1, 0)
logoCorner.Parent = logo

local logoStroke = Instance.new("UIStroke")
logoStroke.Color = ORANGE
logoStroke.Thickness = 2
logoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
logoStroke.Parent = logo

local logoDragging = false
local logoDragStart
local logoStartPos
local logoMoved = false
local DRAG_THRESHOLD = 20

logo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        logoDragging = true
        logoMoved = false
        logoDragStart = input.Position
        logoStartPos = logo.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not logoDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - logoDragStart
        local moved = math.abs(delta.X) + math.abs(delta.Y)
        if moved > DRAG_THRESHOLD then
            logoMoved = true
            logo.Position = UDim2.new(
                logoStartPos.X.Scale,
                logoStartPos.X.Offset + delta.X,
                logoStartPos.Y.Scale,
                logoStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

logo.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        logoDragging = false
        if not logoMoved then
            main.Visible = true
            logo.Visible = false
        end
        logoMoved = false
    end
end)

-- Main panel
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(320, 510)
main.Position = UDim2.new(0.5, -160, 0.5, -255)
main.BackgroundColor3 = BLACK
main.BorderSizePixel = 0
main.Visible = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = BLACK
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Text = "BIGBOSS TELEPORTER"
title.TextColor3 = ORANGE
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
closeBtn.BackgroundColor3 = PANEL2
closeBtn.Text = "X"
closeBtn.TextColor3 = WHITE
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 7)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    logo.Visible = true
end)

-- ⭐ WAYPOINT section
local waypointLabel = Instance.new("TextLabel")
waypointLabel.Size = UDim2.new(1, -30, 0, 18)
waypointLabel.Position = UDim2.fromOffset(15, 52)
waypointLabel.BackgroundTransparency = 1
waypointLabel.Text = "WAYPOINT (Safe Hub)"
waypointLabel.TextColor3 = CYAN
waypointLabel.TextSize = 10
waypointLabel.Font = Enum.Font.GothamBold
waypointLabel.TextXAlignment = Enum.TextXAlignment.Left
waypointLabel.Parent = main

local waypointDisplay = Instance.new("TextLabel")
waypointDisplay.Size = UDim2.new(1, -30, 0, 28)
waypointDisplay.Position = UDim2.fromOffset(15, 72)
waypointDisplay.BackgroundColor3 = PANEL
waypointDisplay.BorderSizePixel = 0
waypointDisplay.Text = string.format("Vector3.new(%d, %d, %d)",
    CONFIG.Waypoint.X, CONFIG.Waypoint.Y, CONFIG.Waypoint.Z)
waypointDisplay.TextColor3 = CYAN
waypointDisplay.TextSize = 11
waypointDisplay.Font = Enum.Font.Code
waypointDisplay.TextXAlignment = Enum.TextXAlignment.Center
waypointDisplay.Parent = main

local waypointCorner = Instance.new("UICorner")
waypointCorner.CornerRadius = UDim.new(0, 6)
waypointCorner.Parent = waypointDisplay

local setWaypointBtn = Instance.new("TextButton")
setWaypointBtn.Size = UDim2.new(1, -30, 0, 30)
setWaypointBtn.Position = UDim2.fromOffset(15, 104)
setWaypointBtn.BackgroundColor3 = PANEL2
setWaypointBtn.Text = "SET WAYPOINT (Current Pos)"
setWaypointBtn.TextColor3 = CYAN
setWaypointBtn.TextSize = 11
setWaypointBtn.Font = Enum.Font.GothamBold
setWaypointBtn.Parent = main

local setWaypointCorner = Instance.new("UICorner")
setWaypointCorner.CornerRadius = UDim.new(0, 7)
setWaypointCorner.Parent = setWaypointBtn

-- Name box
local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, -30, 0, 34)
nameBox.Position = UDim2.fromOffset(15, 142)
nameBox.BackgroundColor3 = PANEL2
nameBox.PlaceholderText = "Setpoint name (area)..."
nameBox.PlaceholderColor3 = GREY
nameBox.Text = ""
nameBox.TextColor3 = WHITE
nameBox.TextSize = 12
nameBox.Font = Enum.Font.Gotham
nameBox.ClearTextOnFocus = false
nameBox.Parent = main

local nameCorner = Instance.new("UICorner")
nameCorner.CornerRadius = UDim.new(0, 7)
nameCorner.Parent = nameBox

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, -30, 0, 34)
saveBtn.Position = UDim2.fromOffset(15, 182)
saveBtn.BackgroundColor3 = ORANGE
saveBtn.Text = "+ SAVE CURRENT POSITION"
saveBtn.TextColor3 = BLACK
saveBtn.TextSize = 12
saveBtn.Font = Enum.Font.GothamBold
saveBtn.Parent = main

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 7)
saveCorner.Parent = saveBtn

-- Auto Return section
local autoLabel = Instance.new("TextLabel")
autoLabel.Size = UDim2.new(1, -30, 0, 16)
autoLabel.Position = UDim2.fromOffset(15, 222)
autoLabel.BackgroundTransparency = 1
autoLabel.Text = "AUTO RETURN ON EGG TOUCH"
autoLabel.TextColor3 = ORANGE
autoLabel.TextSize = 10
autoLabel.Font = Enum.Font.GothamBold
autoLabel.TextXAlignment = Enum.TextXAlignment.Left
autoLabel.Parent = main

local setReturnBtn = Instance.new("TextButton")
setReturnBtn.Size = UDim2.new(1, -30, 0, 30)
setReturnBtn.Position = UDim2.fromOffset(15, 240)
setReturnBtn.BackgroundColor3 = PANEL2
setReturnBtn.Text = "SET RETURN POINT"
setReturnBtn.TextColor3 = ORANGE
setReturnBtn.TextSize = 11
setReturnBtn.Font = Enum.Font.GothamBold
setReturnBtn.Parent = main

local setReturnCorner = Instance.new("UICorner")
setReturnCorner.CornerRadius = UDim.new(0, 7)
setReturnCorner.Parent = setReturnBtn

local autoToggle = Instance.new("TextButton")
autoToggle.Size = UDim2.new(1, -30, 0, 30)
autoToggle.Position = UDim2.fromOffset(15, 274)
autoToggle.BackgroundColor3 = PANEL2
autoToggle.Text = "Auto Return: OFF"
autoToggle.TextColor3 = GREY
autoToggle.TextSize = 11
autoToggle.Font = Enum.Font.GothamBold
autoToggle.Parent = main

local autoToggleCorner = Instance.new("UICorner")
autoToggleCorner.CornerRadius = UDim.new(0, 7)
autoToggleCorner.Parent = autoToggle

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 18)
statusLabel.Position = UDim2.fromOffset(15, 310)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = GREY
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main

local list = Instance.new("ScrollingFrame")
list.Name = "PointList"
list.Size = UDim2.new(1, -30, 1, -345)
list.Position = UDim2.fromOffset(15, 330)
list.BackgroundColor3 = PANEL
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = ORANGE
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = main

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 7)
listCorner.Parent = list

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 6)
listPadding.PaddingLeft = UDim.new(0, 6)
listPadding.PaddingRight = UDim.new(0, 6)
listPadding.PaddingBottom = UDim.new(0, 6)
listPadding.Parent = list

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, -12, 0, 50)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "No setpoints yet."
emptyLabel.TextColor3 = GREY
emptyLabel.TextSize = 11
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextWrapped = true
emptyLabel.Parent = list

--==================================================
-- HELPERS
--==================================================

local function getChar()
    local char = player.Character
    if not char then return nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if root and humanoid and humanoid.Health > 0 then
        return root, humanoid
    end
    return nil, nil
end

local function refreshEmptyLabel()
    emptyLabel.Visible = (#savedPoints == 0)
end

local function setStatus(text, color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color or GREY
end

--==================================================
-- CORE GLIDE (single leg)
--==================================================

local function glideLeg(targetPos, label)
    local root, humanoid = getChar()
    if not root or not humanoid then return false end

    local startPos = root.Position
    local totalDist = (targetPos - startPos).Magnitude
    if totalDist < 3 then return true end

    local useArc = totalDist > 50
    local traveled = 0
    local connection

    local done = false

    connection = RunService.Heartbeat:Connect(function(dt)
        if done then return end

        local currentRoot, currentHum = getChar()
        if not currentRoot or not currentHum then
            connection:Disconnect()
            done = true
            return
        end

        local progress = math.clamp(traveled / totalDist, 0, 1)
        local currentSpeed = CONFIG.GlideStartSpeed +
            (CONFIG.GlideMaxSpeed - CONFIG.GlideStartSpeed) * progress

        traveled = traveled + currentSpeed * dt

        local t = math.clamp(traveled / totalDist, 0, 1)
        local newPos = startPos:Lerp(targetPos, t)

        if useArc then
            local arcHeight = math.sin(t * math.pi) * CONFIG.GlideHeight
            newPos = newPos + Vector3.new(0, arcHeight, 0)
        end

        currentRoot.CFrame = CFrame.new(newPos)

        pcall(function()
            currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            currentRoot.Velocity = Vector3.new(0, 0, 0)
        end)

        if t >= 1 then
            connection:Disconnect()
            done = true
        end
    end)

    -- Wait until glide finishes
    local avgSpeed = (CONFIG.GlideStartSpeed + CONFIG.GlideMaxSpeed) / 2
    local estimatedTime = totalDist / avgSpeed
    local startWait = tick()
    while not done and (tick() - startWait) < (estimatedTime + 2) do
        task.wait(0.05)
    end

    pcall(function() connection:Disconnect() end)
    return true
end

--==================================================
-- FULL GLIDE (with waypoint)
--==================================================

local function glideToCFrame(targetCFrame)
    if gliding then return false end

    local root, humanoid = getChar()
    if not root or not humanoid then return false end

    gliding = true

    local originalHealth = humanoid.Health

    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        humanoid.PlatformStand = true
    end)

    local originalCollide = {}
    for _, part in ipairs(root.Parent:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollide[part] = part.CanCollide
            pcall(function() part.CanCollide = false end)
        end
    end

    local healthConn
    healthConn = humanoid.HealthChanged:Connect(function(newHealth)
        if newHealth < originalHealth and newHealth > 0 then
            pcall(function() humanoid.Health = originalHealth end)
        end
    end)

    -- FINAL DESTINATION
    local finalPos = Vector3.new(
        targetCFrame.X,
        targetCFrame.Y + 3,
        targetCFrame.Z
    )

    -- ============================================
    -- LEG 1: Go to waypoint (safe hub)
    -- ============================================
    if CONFIG.UseWaypoint and CONFIG.Waypoint then
        local wp = CONFIG.Waypoint
        local wpPos = Vector3.new(wp.X, wp.Y + 3, wp.Z)

        -- Only use waypoint if it's not too close to current pos
        local curRoot = getChar()
        if curRoot then
            local distToWp = (wpPos - curRoot.Position).Magnitude
            if distToWp > 30 then
                setStatus("Leg 1/2: To waypoint...", CYAN)
                glideLeg(wpPos, "Waypoint")

                -- Small pause at waypoint
                task.wait(0.15)

                -- Check still alive
                local checkRoot = getChar()
                if not checkRoot then
                    pcall(function() healthConn:Disconnect() end)
                    gliding = false
                    return false
                end
            end
        end
    end

    -- ============================================
    -- LEG 2: From waypoint to destination
    -- ============================================
    setStatus("Leg 2/2: To destination...", ORANGE)
    glideLeg(finalPos, "Destination")

    -- ============================================
    -- CLEANUP
    -- ============================================
    pcall(function() healthConn:Disconnect() end)

    for part, collide in pairs(originalCollide) do
        if part and part.Parent then
            pcall(function() part.CanCollide = collide end)
        end
    end

    task.wait(0.1)
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)

    gliding = false
    return true
end

local function glideTo(point)
    if gliding then
        setStatus("Already gliding...", ORANGE)
        return false
    end

    local now = tick()
    if now - lastTeleport < CONFIG.CooldownTime then
        local waitTime = CONFIG.CooldownTime - (now - lastTeleport)
        setStatus(string.format("Cooldown: %.1fs", waitTime), RED)
        return false
    end

    lastTeleport = now
    local ok = glideToCFrame(point.cframe)
    if ok then
        setStatus("Arrived: " .. point.name, GREEN)
    end
    return ok
end

--==================================================
-- WAYPOINT BUTTON
--==================================================

setWaypointBtn.MouseButton1Click:Connect(function()
    local root, humanoid = getChar()
    if not root then
        setStatus("No character", RED)
        return
    end

    CONFIG.Waypoint = root.Position

    waypointDisplay.Text = string.format("Vector3.new(%d, %d, %d)",
        math.floor(root.Position.X),
        math.floor(root.Position.Y),
        math.floor(root.Position.Z))

    setWaypointBtn.BackgroundColor3 = GREEN
    setWaypointBtn.Text = "WAYPOINT SET!"
    setStatus("Waypoint updated", GREEN)
    task.wait(1.2)
    setWaypointBtn.BackgroundColor3 = PANEL2
    setWaypointBtn.Text = "SET WAYPOINT (Current Pos)"

    print(string.format("[BIGBOSS TP] Waypoint set: Vector3.new(%d, %d, %d)",
        math.floor(root.Position.X),
        math.floor(root.Position.Y),
        math.floor(root.Position.Z)))
end)

--==================================================
-- AUTO RETURN
--==================================================

local function stopAutoReturn()
    if autoReturnConn then
        autoReturnConn:Disconnect()
        autoReturnConn = nil
    end
end

local function startAutoReturn()
    stopAutoReturn()

    local root, humanoid = getChar()
    if not root or not humanoid then return end

    autoReturnConn = root.Touched:Connect(function(hit)
        if not CONFIG.AutoReturnEnabled then return end
        if not CONFIG.ReturnPoint then return end

        local now = tick()
        if now - lastReturn < CONFIG.ReturnCooldown then return end

        if hit and hit.Name:lower():find("egg") then
            lastReturn = now
            setStatus("Egg touched! Returning...", ORANGE)
            glideToCFrame(CONFIG.ReturnPoint)
            setStatus("Returned to base", GREEN)
        end
    end)
end

setReturnBtn.MouseButton1Click:Connect(function()
    local root, humanoid = getChar()
    if not root then
        setStatus("No character", RED)
        return
    end

    CONFIG.ReturnPoint = root.CFrame

    setReturnBtn.BackgroundColor3 = GREEN
    setReturnBtn.Text = "RETURN POINT SET"
    setStatus("Return point saved", GREEN)
    task.wait(1.2)
    setReturnBtn.BackgroundColor3 = PANEL2
    setReturnBtn.Text = "SET RETURN POINT"

    print("[BIGBOSS TP] Return point set")
end)

autoToggle.MouseButton1Click:Connect(function()
    if not CONFIG.ReturnPoint then
        setStatus("Set a return point first!", RED)
        autoToggle.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
        task.wait(0.4)
        autoToggle.BackgroundColor3 = PANEL2
        return
    end

    CONFIG.AutoReturnEnabled = not CONFIG.AutoReturnEnabled

    if CONFIG.AutoReturnEnabled then
        autoToggle.Text = "Auto Return: ON"
        autoToggle.TextColor3 = GREEN
        autoToggle.BackgroundColor3 = Color3.fromRGB(25, 65, 40)
        setStatus("Auto Return active", GREEN)
        startAutoReturn()
    else
        autoToggle.Text = "Auto Return: OFF"
        autoToggle.TextColor3 = GREY
        autoToggle.BackgroundColor3 = PANEL2
        setStatus("Auto Return off", GREY)
        stopAutoReturn()
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if CONFIG.AutoReturnEnabled then
        startAutoReturn()
    end
end)

--==================================================
-- ROW CREATION
--==================================================

local function createRow(point, index)
    local row = Instance.new("Frame")
    row.Name = "Point_" .. index
    row.Size = UDim2.new(1, -12, 0, 44)
    row.BackgroundColor3 = PANEL2
    row.BorderSizePixel = 0
    row.Parent = list

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 7)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text = point.name
    label.TextColor3 = WHITE
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = row

    local delBtn = Instance.new("TextButton")
    delBtn.Size = UDim2.fromOffset(28, 28)
    delBtn.Position = UDim2.new(1, -36, 0.5, -14)
    delBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
    delBtn.Text = "X"
    delBtn.TextColor3 = RED
    delBtn.TextSize = 13
    delBtn.Font = Enum.Font.GothamBold
    delBtn.Parent = row

    local delCorner = Instance.new("UICorner")
    delCorner.CornerRadius = UDim.new(0, 6)
    delCorner.Parent = delBtn

    delBtn.MouseButton1Click:Connect(function()
        for i, p in ipairs(savedPoints) do
            if p.name == point.name and p.cframe == point.cframe then
                table.remove(savedPoints, i)
                break
            end
        end
        row:Destroy()
        refreshEmptyLabel()
    end)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, -44, 1, 0)
    clickBtn.Position = UDim2.fromOffset(0, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = row
    clickBtn.ZIndex = 2

    clickBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local ok = glideTo(point)
            if ok then
                row.BackgroundColor3 = GREEN
                task.wait(0.2)
                row.BackgroundColor3 = PANEL2
            else
                row.BackgroundColor3 = RED
                task.wait(0.2)
                row.BackgroundColor3 = PANEL2
            end
        end)
    end)

    return row
end

--==================================================
-- SAVE LOGIC
--==================================================

saveBtn.MouseButton1Click:Connect(function()
    local name = nameBox.Text
    name = name:gsub("^%s+", ""):gsub("%s+$", "")

    if name == "" then
        nameBox.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
        setStatus("Enter a name first", RED)
        task.wait(0.3)
        nameBox.BackgroundColor3 = PANEL2
        return
    end

    local root, humanoid = getChar()
    if not root or not humanoid then
        setStatus("No character", RED)
        return
    end

    local point = {
        name = name,
        cframe = root.CFrame,
    }

    table.insert(savedPoints, point)
    createRow(point, #savedPoints)

    nameBox.Text = ""
    refreshEmptyLabel()

    saveBtn.BackgroundColor3 = GREEN
    setStatus("Saved: " .. name, GREEN)
    task.wait(0.2)
    saveBtn.BackgroundColor3 = ORANGE

    print("[BIGBOSS TP] Saved: " .. name)
end)

--==================================================
-- DRAG MAIN PANEL
--==================================================

local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--==================================================
-- INIT
--==================================================

refreshEmptyLabel()
setStatus("Ready", GREY)
print("[BIGBOSS TP] Waypoint Teleporter loaded.")
print(string.format("[BIGBOSS TP] Waypoint: Vector3.new(%d, %d, %d)",
    CONFIG.Waypoint.X, CONFIG.Waypoint.Y, CONFIG.Waypoint.Z))
