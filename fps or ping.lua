local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CONFIG = {
    StreamingRadius = 150,
    FarClip = 120,
}

local function isCharacterOrSkin(obj)
    local p = obj
    while p do
        if p:IsA("Model") then
            local n = p.Name:lower()
            if n:match("character") or n:match("skin") or n:match("avatar") or n:match("rig") then
                return true
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character == p then return true end
            end
        end
        p = p.Parent
    end
    return false
end

local totalCleaned = 0

local function cleanWorkspace()
    local count = 0

    if Workspace:FindFirstChild("Terrain") then
        pcall(function() Workspace.Terrain.WaterReflectance = 0 end)
        pcall(function() Workspace.Terrain.WaterTransparency = 1 end)
        pcall(function() Workspace.Terrain.Decoration = false end)
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isCharacterOrSkin(obj) then continue end

        local class = obj.ClassName
        if class == "Decal" or class == "Texture" then
            pcall(function() obj:Destroy() end)
            count = count + 1
        elseif class == "Beam" or class == "Trail" then
            pcall(function() obj:Destroy() end)
            count = count + 1
        elseif class == "ParticleEmitter" or class == "Fire" or class == "Smoke" or class == "Sparkles" then
            pcall(function() obj:Destroy() end)
            count = count + 1
        end
    end

    totalCleaned = totalCleaned + count
    return count
end

local firstCleaned = cleanWorkspace()

Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.3)
    if isCharacterOrSkin(obj) then return end
    local class = obj.ClassName
    if class == "Decal" or class == "Texture" or class == "Beam" or class == "Trail"
       or class == "ParticleEmitter" or class == "Fire" or class == "Smoke" or class == "Sparkles" then
        pcall(function() obj:Destroy() end)
        totalCleaned = totalCleaned + 1
    end
end)

local function optimizeLighting()
    pcall(function() Lighting.GlobalShadows = false end)
    pcall(function() Lighting.Outlines = false end)
    pcall(function() Lighting.Brightness = 0 end)
    pcall(function() Lighting.FogEnd = 9e9 end)
    pcall(function() Lighting.FogStart = 9e9 end)
    pcall(function() Lighting.ClockTime = 12 end)
    pcall(function() Lighting.ShadowSoftness = 0 end)

    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("PostEffect") then
            pcall(function() e.Enabled = false end)
        end
    end
end
optimizeLighting()

Lighting.ChildAdded:Connect(function(ch)
    task.wait(0.2)
    if ch:IsA("PostEffect") then pcall(function() ch.Enabled = false end) end
end)

pcall(function() Workspace.PhysicsSimulationRate = 15 end)
pcall(function() Workspace.PhysicsSteppingMethod = Enum.PhysicsSteppingMethod.Fixed end)
pcall(function() Workspace.StreamingEnabled = true end)
pcall(function() Workspace.StreamingTargetRadius = CONFIG.StreamingRadius end)
pcall(function() Workspace.StreamingMinRadius = 50 end)

if Camera then
    pcall(function() Camera.FarClipPlane = CONFIG.FarClip end)
end

local function muteSound(obj)
    if not obj:IsA("Sound") then return end
    local n = obj.Name:lower()
    if n:match("ambient") or n:match("music") or n:match("bgm") or n:match("wind") or n:match("rain") then
        pcall(function() obj.Volume = 0 end)
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do muteSound(obj) end
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.3)
    muteSound(obj)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "tsb_fps_byhun"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 240, 0, 100)
mainFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(0, 200, 255)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, -60, 0, 18)
title.Position = UDim2.new(0, 28, 0, 2)
title.BackgroundTransparency = 1
title.Text = "纯脚本优化 by hun"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left

local miniBtn = Instance.new("TextButton", mainFrame)
miniBtn.Size = UDim2.new(0, 18, 0, 18)
miniBtn.Position = UDim2.new(0, 4, 0, 2)
miniBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
miniBtn.Text = "−"
miniBtn.TextColor3 = Color3.new(1,1,1)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 12
miniBtn.AutoButtonColor = false
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(1, 0)

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -22, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 3)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local statLabel = Instance.new("TextLabel", mainFrame)
statLabel.Size = UDim2.new(1, -10, 0, 40)
statLabel.Position = UDim2.new(0, 5, 0, 22)
statLabel.BackgroundTransparency = 1
statLabel.Text = "加载中..."
statLabel.TextColor3 = Color3.new(1,1,1)
statLabel.Font = Enum.Font.Code
statLabel.TextSize = 11
statLabel.TextXAlignment = Enum.TextXAlignment.Left
statLabel.TextYAlignment = Enum.TextYAlignment.Top

local btnRow = Instance.new("Frame", mainFrame)
btnRow.Size = UDim2.new(1, -10, 0, 22)
btnRow.Position = UDim2.new(0, 5, 0, 64)
btnRow.BackgroundTransparency = 1

local function makeBtn(text, color, xPos, widthScale, callback)
    local b = Instance.new("TextButton", btnRow)
    b.Size = UDim2.new(widthScale, -3, 1, 0)
    b.Position = UDim2.new(xPos, 0, 0, 0)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
    b.MouseButton1Click:Connect(callback)
    return b
end

-- 重新优化按钮
makeBtn("重新优化", Color3.fromRGB(0, 150, 200), 0, 0.5, function()
    local count = cleanWorkspace()
    optimizeLighting()
    pcall(function() Camera.FarClipPlane = CONFIG.FarClip end)
    statLabel.Text = string.format(
        "FPS: %s  |  Ping: %sms\n玩家: %s/%s  | 本次清理: %d",
        "--", "--", "--", "--", count
    )
    print(string.format("[TSB] 重新优化完成 | 本次清理: %d | 累计: %d", count, totalCleaned))
end)

-- 急救恢复按钮
makeBtn("急救", Color3.fromRGB(40, 120, 40), 0.52, 0.48, function()
    pcall(function() settings().Rendering.QualityLevel = 3 end)
    pcall(function() Lighting.GlobalShadows = true end)
    pcall(function() Lighting.Brightness = 1 end)
    pcall(function() Camera.FarClipPlane = 1000 end)
    print("恢复: 画质已恢复")
end)

local floatFrame = Instance.new("Frame")
floatFrame.Name = "FloatFrame"
floatFrame.Size = UDim2.new(0, 44, 0, 44)
floatFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
floatFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
floatFrame.BackgroundTransparency = 0.15
floatFrame.BorderSizePixel = 0
floatFrame.Active = true
floatFrame.Draggable = true
floatFrame.Visible = false
floatFrame.Parent = gui

Instance.new("UICorner", floatFrame).CornerRadius = UDim.new(1, 0)
local floatStroke = Instance.new("UIStroke", floatFrame)
floatStroke.Color = Color3.fromRGB(100, 255, 150)
floatStroke.Thickness = 2

local floatText = Instance.new("TextLabel", floatFrame)
floatText.Size = UDim2.new(1, 0, 1, 0)
floatText.BackgroundTransparency = 1
floatText.Text = "60"
floatText.TextColor3 = Color3.new(1,1,1)
floatText.Font = Enum.Font.GothamBold
floatText.TextSize = 14
floatText.TextScaled = true

floatFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mainFrame.Visible = true
        floatFrame.Visible = false
    end
end)

miniBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    floatFrame.Visible = true
    floatFrame.Position = UDim2.new(0, mainFrame.AbsolutePosition.X, 0, mainFrame.AbsolutePosition.Y)
end)

local frames, lastTick = 0, tick()
RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = tick()
    if now - lastTick >= 0.5 then
        local fps = math.floor(frames / 0.5)
        frames, lastTick = 0, now

        local ping = 0
        pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)

        local playerCount = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers

        statLabel.Text = string.format(
            "FPS: %d  |  Ping: %.0fms\n玩家: %d/%d  | 累计清理: %d",
            fps, ping, playerCount, maxPlayers, totalCleaned
        )

        floatText.Text = tostring(fps)
        if fps >= 55 then
            floatFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
            floatStroke.Color = Color3.fromRGB(100, 255, 150)
        elseif fps >= 35 then
            floatFrame.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
            floatStroke.Color = Color3.fromRGB(255, 200, 50)
        else
            floatFrame.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
            floatStroke.Color = Color3.fromRGB(255, 100, 100)
        end
    end
end)

Players.PlayerAdded:Connect(function()
    print("[TSB] 玩家加入，当前: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
end)
Players.PlayerRemoving:Connect(function()
    print("[TSB] 玩家离开，当前: " .. (#Players:GetPlayers()-1) .. "/" .. Players.MaxPlayers)
end)
