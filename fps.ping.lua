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
local f, last = 0, tick()
local updateInterval = 0.1
rs.RenderStepped:Connect(function()
    f = f + 1
    local now = tick()
    local delta = now - last
    if delta >= updateInterval then
        local fps = f / delta
        local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        l.Text = string.format("FPS: %.1f  Ping: %.2fms", fps, ping)
        f, last = 0, now
    end
end)