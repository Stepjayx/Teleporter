--==================================================
-- BIGBOSS TELEPORTER (Run-Stop Method)
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

--==================================================
-- COLORS
--==================================================

local BLACK  = Color3.fromRGB(7, 9, 14)
local PANEL  = Color3.fromRGB(15, 20, 32)
local PANEL2 = Color3.fromRGB(24, 31, 47)
local ORANGE = Color3.fromRGB(255, 166, 0)
local WHITE  = Color3.fromRGB(235, 235, 235)
local GREY   = Color3.fromRGB(130, 140, 155)
local GREEN  = Color3.fromRGB(60, 200, 110)
local RED    = Color3.fromRGB(220, 70, 70)

--==================================================
-- CONFIG
--==================================================

local CONFIG = {
    TeleportDelay   = 0.15,
    CooldownTime    = 2.0,
    YOffset         = 3,
    UseRandomDelay  = true,
    HopSize         = 150,
    HopDelay        = 0.4,   -- 👈 faster pause (was 0.9)
}

--==================================================
-- STATE
--==================================================

local savedPoints = {}
local lastTeleport = 0
local teleporting = false

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

--==================================================
-- CIRCLE LOGO
--==================================================

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
local DRAG_THRESHOLD = 8

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

UserInputService.InputEnded:Connect(function(input)
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

--==================================================
-- MAIN PANEL
--==================================================

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(320, 380)
main.Position = UDim2.new(0.5, -160, 0.5, -190)
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

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, -30, 0, 36)
nameBox.Position = UDim2.fromOffset(15, 54)
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
saveBtn.Size = UDim2.new(1, -30, 0, 36)
saveBtn.Position = UDim2.fromOffset(15, 98)
saveBtn.BackgroundColor3 = ORANGE
saveBtn.Text = "+ SAVE CURRENT POSITION"
saveBtn.TextColor3 = BLACK
saveBtn.TextSize = 12
saveBtn.Font = Enum.Font.GothamBold
saveBtn.Parent = main

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 7)
saveCorner.Parent = saveBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 18)
statusLabel.Position = UDim2.fromOffset(15, 138)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = GREY
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main

local list = Instance.new("ScrollingFrame")
list.Name = "PointList"
list.Size = UDim2.new(1, -30, 1, -180)
list.Position = UDim2.fromOffset(15, 160)
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
emptyLabel.Size = UDim2.new(1, -12, 0, 60)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "No setpoints yet.\nType a name and tap SAVE."
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

local function randomBetween(min, max)
    return min + math.random() * (max - min)
end

--==================================================
-- RUN-STOP TELEPORT
--==================================================

local function safeTeleport(point)
    if teleporting then
        setStatus("Already teleporting...", ORANGE)
        return false
    end

    local now = tick()
    local elapsed = now - lastTeleport
    if elapsed < CONFIG.CooldownTime then
        local waitTime = CONFIG.CooldownTime - elapsed
        setStatus(string.format("Cooldown: %.1fs", waitTime), RED)
        return false
    end

    local root, humanoid = getChar()
    if not root or not humanoid then
        setStatus("No character", RED)
        return false
    end

    teleporting = true
    lastTeleport = now

    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)

    local delay = CONFIG.TeleportDelay
    if CONFIG.UseRandomDelay then
        delay = delay + randomBetween(0, 0.1)
    end
    task.wait(delay)

    local startPos = root.Position
    local endPos = Vector3.new(
        point.cframe.X,
        point.cframe.Y + CONFIG.YOffset,
        point.cframe.Z
    )

    local totalDistance = (endPos - startPos).Magnitude
    local steps = math.max(1, math.ceil(totalDistance / CONFIG.HopSize))

    for i = 1, steps do
        root, humanoid = getChar()
        if not root or not humanoid then
            teleporting = false
            pcall(function()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            end)
            setStatus("Died during TP", RED)
            return false
        end

        local t = i / steps
        local stepPos = startPos:Lerp(endPos, t)

        setStatus(string.format("Teleporting... %d/%d", i, steps), ORANGE)

        pcall(function() root.Anchored = true end)
        root.CFrame = CFrame.new(stepPos)
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.Velocity = Vector3.new(0, 0, 0)
        end)

        task.wait(0.05)
        pcall(function() root.Anchored = false end)

        if i < steps then
            task.wait(CONFIG.HopDelay)
        end
    end

    task.wait(0.1)
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        humanoid.PlatformStand = false
    end)

    teleporting = false
    setStatus(string.format("Teleported: %s (%d steps)", point.name, steps), GREEN)
    print(string.format("[BIGBOSS TP] Teleported to %s (%d steps, %.0f studs)", point.name, steps, totalDistance))
    return true
end

--==================================================
-- ROW CREATION
--==================================================

local function createRow(point, index)

    local row = Instance.new("Frame")
    row.Name = "Point_" .. index
    row.Size = UDim2.new(1, -12, 0, 46)
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
    delBtn.Size = UDim2.fromOffset(30, 30)
    delBtn.Position = UDim2.new(1, -38, 0.5, -15)
    delBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
    delBtn.Text = "✕"
    delBtn.TextColor3 = RED
    delBtn.TextSize = 14
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
    clickBtn.Size = UDim2.new(1, -46, 1, 0)
    clickBtn.Position = UDim2.fromOffset(0, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = row
    clickBtn.ZIndex = 2

    clickBtn.MouseButton1Click:Connect(function()
        local ok = safeTeleport(point)
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
print("[BIGBOSS TP] BIGBOSS TELEPORTER (Run-Stop) loaded.")
