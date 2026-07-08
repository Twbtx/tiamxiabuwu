local t = Instance.new("ScreenGui", game.CoreGui)
local l = Instance.new("TextLabel", t)
l.Size = UDim2.new(0, 260, 0, 28)
l.AnchorPoint = Vector2.new(0.5, 0)
l.Position = UDim2.new(0.5, 0, 0, 8)
l.BackgroundColor3 = Color3.new(0,0,0)
l.BackgroundTransparency = 0.4
l.Font = Enum.Font.Code
l.TextScaled = true
l.TextColor3 = Color3.new(1,1,1)
l.Text = "加载中..."
l.Active = true
l.Draggable = true

local stroke = Instance.new("UIStroke", l)
stroke.Color = Color3.new(1,1,1)
stroke.Thickness = 2
stroke.Transparency = 0.3

local closeBtn = Instance.new("TextButton", l)
closeBtn.Size = UDim2.new(0,16,0,16)
closeBtn.Position = UDim2.new(1,-14,0.5,-8)
closeBtn.BackgroundColor3 = Color3.new(1,0,0)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function() t:Destroy() end)

local stats = game:GetService("Stats")
local rs = game:GetService("RunService")

local SMOOTH = 0.1
local realFps = 0
local realPing = 0
local smoothFps = 0
local smoothPing = 0
local frameCount = 0
local lastFpsTime = tick()
local lastPingTime = tick()
local FPS_INTERVAL = 0.075
local PING_INTERVAL = 0.075

rs.RenderStepped:Connect(function()
    local now = tick()
    
    frameCount = frameCount + 1
    if now - lastFpsTime >= FPS_INTERVAL then
        realFps = frameCount / (now - lastFpsTime)
        frameCount = 0
        lastFpsTime = now
    end
    
    if now - lastPingTime >= PING_INTERVAL then
        realPing = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        lastPingTime = now
    end
    
    smoothFps = smoothFps + (realFps - smoothFps) * SMOOTH
    smoothPing = smoothPing + (realPing - smoothPing) * SMOOTH
    
    l.Text = string.format("FPS: %.1f  Ping: %.2fms", smoothFps, smoothPing)
end)