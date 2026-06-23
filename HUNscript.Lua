local function Main()
local DyzhUi = Instance.new('ScreenGui')
DyzhUi.Name = 'DyzhUi'
DyzhUi.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

if game:GetService('UserInputService').TouchEnabled then
	local UI = Instance.new('UIScale')
	UI.Scale = 0.5
	UI.Parent = DyzhUi
end

local Background = Instance.new('Frame')
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.new(0, 0, 0)
Background.BackgroundTransparency = 0.7
Background.Position = UDim2.new(1, 0, 0, 0)
Background.Parent = DyzhUi

local Frame1 = Instance.new('Frame')
Frame1.Size = UDim2.new(0, 450, 0, 250)
Frame1.AnchorPoint = Vector2.new(0.5, 0.5)
Frame1.Position = UDim2.new(0.5, 0, 0.45, 0)
Frame1.BackgroundTransparency = 0.35
Frame1.BackgroundColor3 = Color3.new(0, 0, 0)
Frame1.Name = 'Dyzh'
Frame1.Parent = DyzhUi
local Frame1C = Instance.new('UICorner')
Frame1C.CornerRadius = UDim.new(0, 10)
Frame1C.Parent = Frame1
local Frame1Stroke = Instance.new('UIStroke')
Frame1Stroke.Thickness = 5
Frame1Stroke.Color = Color3.new(1, 1, 1)
Frame1Stroke.Parent = Frame1
local GradientStroke = Instance.new('UIGradient')
GradientStroke.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 50, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 208, 255))
})
GradientStroke.Parent = Frame1Stroke

local ImageLabel = Instance.new('ImageLabel')
ImageLabel.Size = UDim2.new(0, 110, 0, 110)
ImageLabel.ImageColor3 = Color3.fromRGB(16, 151, 255)
ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
ImageLabel.Position = UDim2.new(0.5, 0, 0.25, 0)
ImageLabel.BackgroundTransparency = 1
ImageLabel.Image = "rbxassetid://6458974334"
ImageLabel.Parent = Frame1

local TextLabel = Instance.new('TextLabel')
TextLabel.Size = UDim2.new(0.8, 0, 0.4, 0)
TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
TextLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.Text = "HUN HUB"
TextLabel.TextScaled = false
TextLabel.TextSize = 70
TextLabel.Font = Enum.Font.GothamBold
TextLabel.Parent = Frame1

local TextLabel1 = Instance.new('TextLabel')
TextLabel1.Size = UDim2.new(0.8, 0, 0.4, 0)
TextLabel1.AnchorPoint = Vector2.new(0.5, 0.5)
TextLabel1.Position = UDim2.new(0.5, 0, 0.85, 0)
TextLabel1.BackgroundTransparency = 1
TextLabel1.TextColor3 = Color3.new(1, 1, 1)
TextLabel1.Text = "有时更新很快，有时更新很慢"
TextLabel1.TextScaled = false
TextLabel1.TextSize = 30
TextLabel1.Font = Enum.Font.GothamBold
TextLabel1.Parent = Frame1

local TStroke = Instance.new('UIGradient')
TStroke.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 50, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 208, 255))
})
TStroke.Parent = TextLabel

local TStroke1 = Instance.new('UIGradient')
TStroke1.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 50, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 208, 255))
})
TStroke1.Parent = TextLabel1


local LoadState = Instance.new('TextLabel')
LoadState.Size = UDim2.new(0.8, 0, 0.4, 0)
LoadState.AnchorPoint = Vector2.new(0.5, 0.5)
LoadState.Position = UDim2.new(0.5, 0, 1.4, 0)
LoadState.BackgroundTransparency = 1
LoadState.TextColor3 = Color3.new(1, 1, 1)
LoadState.Text = "正在加载UI..."
LoadState.TextScaled = false
LoadState.TextSize = 30
LoadState.Font = Enum.Font.GothamBold
LoadState.Parent = Frame1

local LStroke = Instance.new('UIGradient')
LStroke.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 50, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 208, 255))
})
LStroke.Parent = LoadState

local ProgressBarBackground = Instance.new('Frame')
ProgressBarBackground.Size = UDim2.new(1, 0, 0.15, 0)
ProgressBarBackground.AnchorPoint = Vector2.new(0.5, 0.5)
ProgressBarBackground.Position = UDim2.new(0.5, 0, 1.2, 0)
ProgressBarBackground.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ProgressBarBackground.Parent = Frame1
local ProgressBarBackgroundCorner = Instance.new('UICorner')
ProgressBarBackgroundCorner.CornerRadius = UDim.new(0, 10)
ProgressBarBackgroundCorner.Parent = ProgressBarBackground

local ProgressBar = Instance.new('Frame')
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Color3.new(255, 255, 255)
ProgressBar.Parent = ProgressBarBackground
local ProgressBarCorner = Instance.new('UICorner')
ProgressBarCorner.CornerRadius = UDim.new(0, 10)
ProgressBarCorner.Parent = ProgressBar

local PStroke = Instance.new('UIGradient')
PStroke.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 75, 199))
})
PStroke.Parent = ProgressBar

local B1Stroke = Instance.new('UIStroke')
B1Stroke.Thickness = 5
B1Stroke.Color = Color3.new(1, 1, 1)
B1Stroke.Parent = ProgressBarBackground
local BStroke = Instance.new('UIGradient')
BStroke.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 50, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 208, 255))
})

BStroke.Parent = B1Stroke

task.spawn(function()
	while true do
		GradientStroke.Rotation += 2
		wait()
	end
end)

task.spawn(function()
	while true do
		BStroke.Rotation += 0.5
		wait()
	end
end)

task.spawn(function()
	while true do
		LStroke.Rotation += 0.5
		wait()
	end
end)

task.spawn(function()
	while true do
		TStroke.Rotation += 0.5
		wait()
	end
end)

task.spawn(function()
	while true do
		TStroke1.Rotation += 0.5
		wait()
	end
end)

Background:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 1)
Frame1.Position = UDim2.new(1.5, 0, 0.5, 0)
Frame1:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Quad", 1)

ProgressBar:TweenSize(UDim2.new(0.3, 0, 1, 0), "Out", "Quad", 1)

task.wait(3)

ProgressBar:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Quad", 1)
wait(1)
LoadState.Text = "加载完成"
wait(1)
Frame1:TweenPosition(UDim2.new(0.5, 0, -3, 0), "Out", "Quad", 1)
Background:TweenPosition(UDim2.new(0, 0, -3, 0), "Out", "Quad", 1)

task.wait(1.2)


print("Anti Afk On")
		local vu = game:GetService("VirtualUser")
		game:GetService("Players").LocalPlayer.Idled:connect(function()
		   vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
		   wait(1)
		   vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
		end)
local CoreGui = game:GetService("StarterGui")
CoreGui:SetCore("SendNotification", {
    Title = "反挂机已自动开启",
    Text = "挂机20分钟不会被踢出",
    Duration = 5,
})
wait(1)
local CoreGui = game:GetService("StarterGui")
CoreGui:SetCore("SendNotification", {
    Title = "启动成功",
    Text = "您好"..game.Players.LocalPlayer.Name.."，欢迎使用混脚本",
    Duration = 5,
})

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "混脚本 -- QQ群：587841124",
    Icon = "door-open",
    Author = "由 混 制作",
    Folder = "CloudHub",
    Size = UDim2.fromOffset(500, 300),
    Transparent = true,
    Theme = "Dark",
    Background = "rbxassetid://129429398197953",
    User = {
        Enabled = true,
        Callback = function() 
            print("clicked") 
        end,
        Anonymous = true
    },
})

Window:EditOpenButton(
    {
        Title = "打开HUN脚本",
        Icon = "crown",
        CornerRadius = UDim.new(0, 13),
        StrokeThickness = 4,
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(186, 19, 19)),ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 60, 129))}),
        Draggable = true
    }
)

function Tab(a)
    return Window:Tab({Title = a, Icon = "eye"})
end

function Button(a, b, c)
    return a:Button({Title = b, Callback = c})
end

function Toggle(a, b, c, d)
    return a:Toggle({Title = b, Value = c, Callback = d})
end

function Slider(a, b, c, d, e, f)
    return a:Slider({Title = b, Step = 1, Value = {Min = c, Max = d, Default = e}, Callback = f})
end


function Dropdown(a, b, c, d, e)
    return a:Dropdown({Title = b, Values = c, Value = d, Callback = e})
end

function Input(a, b, c, d, e, f)
    return a:Input({
        Title = b,
        Desc = c or "",
        Value = d or "",
        Placeholder = e or "",
        Callback = f
    })
end

local Tab1 = Tab("通用(包含开发工具)")
local Tab2 = Tab("忍者传奇")
local Tab3 = Tab("力量传奇")
local Tab4 = Tab("驾驶帝国")
local Tab5 = Tab("监狱人生")
local Tab6 = Tab("战争大亨")
local Tab7 = Tab("黑洞")
local Tab8 = Tab("范围")
local Tab9 = Tab("自瞄")
local Tab10 = Tab("子追")
local Tab11 = Tab("汉化器")
local Tab12 = Tab("被遗弃")
local Tab13 = Tab("99夜")
local Tab14 = Tab("GB")
local Tab15 = Tab("死亡之死")
local Tab16 = Tab("刀刃球")
local Tab17 = Tab("墨水游戏")
local Tab18 = Tab("极速传奇")
local Tab19 = Tab("最强战场")
local Tab20 = Tab("其他作者脚本")
local Tab21 = Tab("自然灾害")
local Tab22 = Tab("ohio")
local Tab23 = Tab("一些音效[并不FE]")
local Tab24 = Tab("终极战场")
local Tab25 = Tab("偷走脑红")
local Tab26 = Tab("死铁轨")
local Tab27 = Tab("河北唐县")

Button(Tab1, "复制QQ群587841124", function()
    setclipboard("587841124")
end)

Button(Tab1, "复制用户ID", function()
    setclipboard(game:GetService("Players").LocalPlayer.UserId)
end)

Button(Tab1, "复制服务器名称", function()
    setclipboard(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
end)

Button(Tab1, "复制注册时间", function()
    setclipboard(game:GetService("Players").LocalPlayer.AccountAge)
end)

Button(Tab1, "测试注入器UNC(聊天框输入：/console 查看)", function()
    Window:Dialog({
        Title = "HUNHUB",
        Content = "请勿多次点击，否则会造成游戏卡顿!",
        Buttons = {{
            Title = "确定",
            Variant = "Primary",
            Callback = function()
                loadstring(game:HttpGet "https://raw.githubusercontent.com/Yungengxin/roblox/refs/heads/main/unc")()
                WindUI:Notify({
                    Title = "HUNHUB",
                    Content = "已成功执行，请在控制台查看UNC！",
                    Duration = 5
                })
            end
        }}
    })
end)

Slider(Tab1, "移动速度", 1, 600, game.Players.LocalPlayer.Character.Humanoid.WalkSpeed, function(a) 
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = a
end)

Slider(Tab1, "跳跃高度", 1, 600, game.Players.LocalPlayer.Character.Humanoid.JumpPower, function(a) 
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = a
end)

Slider(Tab1, "重力设置", 1, 500, workspace.Gravity, function(a) 
        workspace.Gravity = a
end)

Slider(Tab1, "视野缩放距离", 0, 2500, game:GetService("Players").LocalPlayer.CameraMaxZoomDistance, function(value)
    game:GetService("Players").LocalPlayer.CameraMaxZoomDistance = value
end)

Slider(Tab1, "广角设置", 1, 120, fovValue, function(value)
    fovValue = value
    workspace.CurrentCamera.FieldOfView = value
end)

Input(Tab1, "设置血量", "输入血量值 (0-999999999)", "", "例如: 100", function(value)
    local numValue = tonumber(value)
    if numValue and numValue >= 0 then
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.Health = numValue
            WindUI:Notify({Title = "血量设置", Content = "血量已设置为: " .. numValue})
        else
            WindUI:Notify({Title = "错误", Content = "角色或Humanoid不存在"})
        end
    else
        WindUI:Notify({Title = "错误", Content = "请输入有效的数字 (≥ 0)"})
    end
end)

Button(Tab1, "恢复视野", function() 
    Workspace.CurrentCamera.FieldOfView = 70
end)

Button(Tab1, "最大视野缩放", function() 
    game:GetService("Players").LocalPlayer.CameraMaxZoomDistance = 200000
end)

Button(Tab1, "视野缩放128", function() 
    game:GetService("Players").LocalPlayer.CameraMaxZoomDistance = 128
end)

local PhysicsSpeedValue = nil
local PhysicsEnabled = false
local PhysicsBV = nil

Input(Tab1, "物理 Speed", "输入物理速度 (最低0，最高无上限)", "", "例如: 150", function(value)
    local numValue = tonumber(value)
    if numValue and numValue >= 0 then
        PhysicsSpeedValue = numValue
        WindUI:Notify({Title = "速度设置", Content = "Physics速度已设置为: " .. numValue})
    else
        WindUI:Notify({Title = "错误", Content = "请输入有效的数字 (≥ 0)"})
    end
end)

Button(Tab1, "启用物理 Speed", function()
    if PhysicsSpeedValue == nil then
        WindUI:Notify({Title = "错误", Content = "请先输入Physics速度值"})
        return
    end
    
    if PhysicsEnabled then
        WindUI:Notify({Title = "提示", Content = "Physics速度已在运行"})
        return
    end
    
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    
    PhysicsBV = Instance.new("BodyVelocity")
    PhysicsBV.Velocity = Vector3.new(0, 0, 0)
    PhysicsBV.MaxForce = Vector3.new(math.huge, 0, math.huge)
    PhysicsBV.Parent = root
    
    PhysicsEnabled = true
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if not PhysicsEnabled then return end
        if character:FindFirstChild("Humanoid") then
            local moveDirection = character.Humanoid.MoveDirection
            PhysicsBV.Velocity = moveDirection * PhysicsSpeedValue
        end
    end)
    
    WindUI:Notify({Title = "Physics Speed", Content = "已启用, 速度: " .. PhysicsSpeedValue})
end)

Button(Tab1, "禁用物理 Speed", function()
    if PhysicsBV then
        PhysicsBV:Destroy()
        PhysicsBV = nil
    end
    PhysicsEnabled = false
    WindUI:Notify({Title = "Physics Speed", Content = "已禁用"})
end)

local TeleportSpeedValue = nil
local TeleportEnabled = false

Input(Tab1, "传送 Speed", "输入传送距离 (最低0，最高无上限)", "", "例如: 5", function(value)
    local numValue = tonumber(value)
    if numValue and numValue >= 0 then
        TeleportSpeedValue = numValue
        WindUI:Notify({Title = "距离设置", Content = "Teleport距离已设置为: " .. numValue})
    else
        WindUI:Notify({Title = "错误", Content = "请输入有效的数字 (≥ 0)"})
    end
end)

Button(Tab1, "启用Teleport Speed", function()
    if TeleportSpeedValue == nil then
        WindUI:Notify({Title = "错误", Content = "请先输入Teleport距离值"})
        return
    end
    
    if TeleportEnabled then
        WindUI:Notify({Title = "提示", Content = "Teleport速度已在运行"})
        return
    end
    
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    
    TeleportEnabled = true
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if not TeleportEnabled then return end
        if character:FindFirstChild("Humanoid") then
            local moveDirection = character.Humanoid.MoveDirection
            if moveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + (moveDirection * TeleportSpeedValue)
            end
        end
    end)
    
    WindUI:Notify({Title = "Teleport Speed", Content = "已启用, 距离: " .. TeleportSpeedValue})
end)

Button(Tab1, "禁用传送 Speed", function()
    TeleportEnabled = false
    WindUI:Notify({Title = "Teleport Speed", Content = "已禁用"})
end)

local JumpPowerValue = nil
local JumpEnabled = false

Input(Tab1, "跳跃高度2" , "输入跳跃高度 (最低0，最高无上限)", "", "例如: 150", function(value)
    local numValue = tonumber(value)
    if numValue and numValue >= 0 then
        JumpPowerValue = numValue
        WindUI:Notify({Title = "高度设置", Content = "跳跃高度已设置为: " .. numValue})
    else
        WindUI:Notify({Title = "错误", Content = "请输入有效的数字 (≥ 0)"})
    end
end)

Button(Tab1, "启用跳跃高度2", function()
    if JumpPowerValue == nil then
        WindUI:Notify({Title = "错误", Content = "请先输入跳跃高度"})
        return
    end
    
    if JumpEnabled then
        WindUI:Notify({Title = "提示", Content = "跳跃高度已在运行"})
        return
    end
    
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoid.JumpPower = JumpPowerValue
    
    JumpEnabled = true
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if not JumpEnabled then return end
        if humanoid.JumpPower ~= JumpPowerValue then
            humanoid.JumpPower = JumpPowerValue
        end
    end)
    
    WindUI:Notify({Title = "Jump Power", Content = "已启用, 跳跃高度: " .. JumpPowerValue})
end)

Button(Tab1, "禁用跳跃高度2", function()
    JumpEnabled = false
    
    local player = game.Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.JumpPower = 50
    end
    
    WindUI:Notify({Title = "Jump Power", Content = "已禁用"})
end)

local downloadInput = Input(Tab1, "下载文件URL", "输入文件下载链接", "", "例如: https://raw.githubusercontent.com/xxxxx(其他的链接也可以)", function(url)
    
end)

Button(Tab1, "下载文件", function()
    local url = downloadInput.Value
    if url == "" or url == nil then
        WindUI:Notify({
            Title = "下载失败",
            Content = "请输入有效的URL",
            Duration = 5
        })
        return
    end
    
    
    if string.find(url:lower(), "loadstring") and string.find(url:lower(), "game:httpget") then
        WindUI:Notify({
            Title = "下载失败",
            Content = "URL格式错误",
            Duration = 5
        })
        return
    end
    
    
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and content then
        
        local filename = "downloaded_file(您下载的文件).txt"
        local lastSlash = string.match(url, "([^/]+)$")
        if lastSlash then
            filename = lastSlash
            
            filename = string.gsub(filename, "%?.*", "")
        end
        
        
        local writeSuccess, writeError = pcall(function()
            writefile(filename, content)
        end)
        
        if writeSuccess then
            WindUI:Notify({
                Title = "下载成功",
                Content = "文件已保存: " .. filename,
                Duration = 5
            })
            
            
            wait(3)
            
            WindUI:Notify({
                Title = "文件位置提示",
                Content = "文件保存在脚本工作目录下的: " .. filename .. "\n请查看执行器的文件管理器",
                Duration = 8
            })
        else
            WindUI:Notify({
                Title = "下载失败",
                Content = "文件保存失败: " .. tostring(writeError),
                Duration = 5
            })
        end
    else
        WindUI:Notify({
            Title = "下载失败",
            Content = "无法从URL获取内容: " .. tostring(content),
            Duration = 5
        })
    end
end)

Button(Tab1, "提升fps", function() 
        loadstring(game:HttpGet("https://raw.githubusercontent.com/smalldesikon/hun/ee906e570c0f5b22e580a20decaba23757533569/fps"))()
end)

Button(Tab1, "好用隐身", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/3Rnd9rHf"))()
end)

Toggle(Tab1, "无限跳(可开关)", false, function(Value)
    Jump = Value
    game:GetService("UserInputService").JumpRequest:Connect(function()
        if Jump then
            game.Players.LocalPlayer.Character.Humanoid:ChangeState("Jumping")
        end
    end)
end)

Button(Tab1, "无限跳(关不了)", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/V5PQy3y0", true))()
end)

Button(Tab1, "飞行(by天下布武)", function() 
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Twbtx/tiamxiabuwu/main/t%20x%20b%20w%20fly"))()
end)

Button(Tab1, "司空同款飞行", function() 
        loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
end)

Button(Tab1, "阿尔飞行", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/5zJu3hfN"))()
end)

Button(Tab1, "踏空行走", function() 
        loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Float'))()
end)

Button(Tab1, "无头加短腿美化", function() 
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Permanent-Headless-And-korblox-Script-4140"))()
end)

Button(Tab1, "动态模糊", function() 
     	local camera = workspace.CurrentCamera
local blurAmount = 10
local blurAmplifier = 5
local lastVector = camera.CFrame.LookVector

local motionBlur = Instance.new("BlurEffect", camera)

local runService = game:GetService("RunService")

workspace.Changed:Connect(function(property)
 if property == "CurrentCamera" then
  print("Changed")
  local camera = workspace.CurrentCamera
  if motionBlur and motionBlur.Parent then
   motionBlur.Parent = camera
  else
   motionBlur = Instance.new("BlurEffect", camera)
  end
 end
end)

runService.Heartbeat:Connect(function()
 if not motionBlur or motionBlur.Parent == nil then
  motionBlur = Instance.new("BlurEffect", camera)
 end
 
 local magnitude = (camera.CFrame.LookVector - lastVector).magnitude
 motionBlur.Size = math.abs(magnitude)*blurAmount*blurAmplifier/2
 lastVector = camera.CFrame.LookVector
end)
end)

Toggle(Tab1, "穿墙模式", false, function(state)
    _G.noclip = state
    
    if state then
        if not game:GetService('Players').LocalPlayer.Character:FindFirstChild("LowerTorso") then
            local connection = game:GetService("RunService").Stepped:Connect(function()
                if not _G.noclip then connection:Disconnect() return end
                game.Players.LocalPlayer.Character.Head.CanCollide = false
                game.Players.LocalPlayer.Character.Torso.CanCollide = false
            end)
        else
            if _G.InitNC ~= true then
                _G.NCFunc = function(part)
                    local pos = game:GetService('Players').LocalPlayer.Character.LowerTorso.Position.Y
                    if _G.noclip and part.Position.Y > pos then
                        part.CanCollide = false
                    end
                end
                _G.InitNC = true
            end
            game:GetService('Players').LocalPlayer.Character.Humanoid.Touched:Connect(_G.NCFunc)
        end
    else
        if game.Players.LocalPlayer.Character then
            for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

Toggle(Tab1, "夜视", false, function(a)
        if a then
            game.Lighting.Ambient = Color3.new(1, 1, 1)
        else
            game.Lighting.Ambient = Color3.new(0, 0, 0)
        end
end)
Button(Tab1, "秒互动(无法关闭)", function() 
    game.ProximityPromptService.PromptButtonHoldBegan:Connect(function(v)
    v.HoldDuration = 0
end)
end)

local autoInteract = false

Toggle(Tab1, "自动互动", false, function(state)
    if state then
        autoInteract = true
        while autoInteract do
            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    fireproximityprompt(descendant)
                end
            end
            task.wait(0.2)
        end
    else
        autoInteract = false
    end
end)

Button(Tab1, "一键偷别人的东西", function() 
    for i,v in pairs (game.Players:GetChildren()) do
wait()
for i,b in pairs (v.Backpack:GetChildren()) do
b.Parent = game.Players.LocalPlayer.Backpack
end
end
end)

Button(Tab1, "通用透视1(关不掉)", function() 
    while wait(1) do
local players = game.Players:GetPlayers()

for i,v in pairs(players) do
 local esp = Instance.new("Highlight")
 esp.Name = v.Name
 esp.FillTransparency = 0.5
 esp.FillColor = Color3.new(0, 0, 0)
 esp.OutlineColor = Color3.new(255, 255, 255)
 esp.OutlineTransparency = 0
 esp.Parent = v.Character
end
end
end)

Button(Tab1, "通用透视2", function() 
    local getnamecallmethod
= getnamecallmethod
local Speaker = cloneref(game:GetService("Players")).LocalPlayer
local OldNameCall
OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
if self ~= Speaker or getnamecallmethod() ~= "IsInGroup" then
return OldNameCall(self, ...)
end
return true
end)
hookfunction(Speaker.IsInGroup, function(self, ...)
return true
end)
    
    loadstring(game:GetObjects("rbxassetid://10092697033")[1].Source)()
end)

Button(Tab1, "↓↓以下的透视有bug↓↓", function() 
    
end)

Button(Tab1, "关闭所有透视(关不了上面的透视)", function()
    if getgenv().HealthBarESP then
        for player, espData in pairs(getgenv().HealthBarESP) do
            if espData and espData.Billboard then
                espData.Billboard:Destroy()
            end
        end
        getgenv().HealthBarESP = nil
    end
    
    
    if getgenv().PlayerHighlight then
        if getgenv().PlayerHighlight.TeamConnection then
            getgenv().PlayerHighlight.TeamConnection:Disconnect()
        end
        for player, highlightData in pairs(getgenv().PlayerHighlight.Table) do
            if highlightData and highlightData.Highlight then
                highlightData.Highlight:Destroy()
            end
        end
        getgenv().PlayerHighlight = nil
    end
    
    
    if getgenv().NPCHighlight then
        if getgenv().NPCHighlight.ScanConnection then
            getgenv().NPCHighlight.ScanConnection:Disconnect()
        end
        if getgenv().NPCHighlight.DescendantConnection then
            getgenv().NPCHighlight.DescendantConnection:Disconnect()
        end
        for npc, highlightData in pairs(getgenv().NPCHighlight.Table) do
            if highlightData and highlightData.Highlight then
                highlightData.Highlight:Destroy()
            end
        end
        getgenv().NPCHighlight = nil
    end
    
    
    if getgenv().NPCESP then
        if getgenv().NPCESP.ScanConnection then
            getgenv().NPCESP.ScanConnection:Disconnect()
        end
        if getgenv().NPCESP.DescendantConnection then
            getgenv().NPCESP.DescendantConnection:Disconnect()
        end
        for npc, espData in pairs(getgenv().NPCESP.Table) do
            if espData then
                if espData.Billboard then espData.Billboard:Destroy() end
                if espData.Highlight then espData.Highlight:Destroy() end
            end
        end
        getgenv().NPCESP = nil
    end
    
    
    if getgenv().EnemyPlayerESP then
        if getgenv().EnemyPlayerESP.Connection then
            getgenv().EnemyPlayerESP.Connection:Disconnect()
        end
        for player, espData in pairs(getgenv().EnemyPlayerESP.Table) do
            if espData then
                if espData.Billboard then espData.Billboard:Destroy() end
                if espData.Highlight then espData.Highlight:Destroy() end
            end
        end
        getgenv().EnemyPlayerESP = nil
    end
    
    
    if getgenv().EnemyNPCESP then
        if getgenv().EnemyNPCESP.ScanConnection then
            getgenv().EnemyNPCESP.ScanConnection:Disconnect()
        end
        if getgenv().EnemyNPCESP.DescendantConnection then
            getgenv().EnemyNPCESP.DescendantConnection:Disconnect()
        end
        for npc, espData in pairs(getgenv().EnemyNPCESP.Table) do
            if espData then
                if espData.Billboard then espData.Billboard:Destroy() end
                if espData.Highlight then espData.Highlight:Destroy() end
            end
        end
        getgenv().EnemyNPCESP = nil
    end
    
    
    if getgenv().DistanceESP then
        if getgenv().DistanceESP.Connection then
            getgenv().DistanceESP.Connection:Disconnect()
        end
        for player, espData in pairs(getgenv().DistanceESP.Table) do
            if espData and espData.Billboard then
                espData.Billboard:Destroy()
            end
        end
        getgenv().DistanceESP = nil
    end
    
    
    if getgenv().ToolESP then
        if getgenv().ToolESP.Connection then
            getgenv().ToolESP.Connection:Disconnect()
        end
        for player, espData in pairs(getgenv().ToolESP.Table) do
            if espData then
                if espData.Billboard then espData.Billboard:Destroy() end
                if espData.Highlight then espData.Highlight:Destroy() end
                if espData.ToolConnection then espData.ToolConnection:Disconnect() end
            end
        end
        getgenv().ToolESP = nil
    end
    
    
    if ESPConnection then
        ESPConnection:Disconnect()
        ESPConnection = nil
    end
    CleanupESP()
    
    
    ESPData = {
        BoxESP = false,
        SkeletonESP = false,
        NameESP = false,
        TracerESP = false
    }
    
    
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            
            local healthBar = player.Character:FindFirstChild("HealthBar_" .. player.Name)
            if healthBar then healthBar:Destroy() end
            
            
            local distanceDisplay = player.Character:FindFirstChild("DistanceDisplay_" .. player.Name)
            if distanceDisplay then distanceDisplay:Destroy() end
            
            
            local highlight = player.Character:FindFirstChild("PlayerHighlight")
            if highlight then highlight:Destroy() end
            
            
            local enemyESP = player.Character:FindFirstChild("EnemyPlayerESP_" .. player.Name)
            if enemyESP then enemyESP:Destroy() end
            
            local enemyHighlight = player.Character:FindFirstChild("EnemyPlayerHighlight")
            if enemyHighlight then enemyHighlight:Destroy() end
            
            
            for _, child in ipairs(player.Character:GetDescendants()) do
                if child:IsA("BillboardGui") and (string.find(child.Name, "ToolESP_") or string.find(child.Name, "EnemyPlayerESP_")) then
                    child:Destroy()
                end
                if child:IsA("Highlight") and (string.find(child.Name, "ToolHighlight_") or string.find(child.Name, "EnemyPlayerHighlight")) then
                    child:Destroy()
                end
            end
        end
    end
    
    
    for _, descendant in pairs(Workspace:GetDescendants()) do
        if descendant:IsA("Model") then
            for _, child in ipairs(descendant:GetDescendants()) do
                
                if child:IsA("Highlight") and (child.Name == "NPCHighlight" or child.Name == "NPCESP_Highlight" or string.find(child.Name, "EnemyNPCHighlight")) then
                    child:Destroy()
                end
                
                if child:IsA("BillboardGui") and (string.find(child.Name, "NPCESP_") or string.find(child.Name, "EnemyNPCESP_")) then
                    child:Destroy()
                end
            end
        end
    end
    
    
    if getgenv().OriginalCameraProperties then
        workspace.CurrentCamera.CameraType = getgenv().OriginalCameraProperties.CameraType
        workspace.CurrentCamera.CameraSubject = getgenv().OriginalCameraProperties.CameraSubject
        getgenv().OriginalCameraProperties = nil
    end
    
    if getgenv().WallhackConnection then
        getgenv().WallhackConnection:Disconnect()
        getgenv().WallhackConnection = nil
    end
    
    
    if getgenv().BulletTrack then
        local GameMetaTable = getrawmetatable(game)
        setreadonly(GameMetaTable, false)
        GameMetaTable.__namecall = getgenv().BulletTrack.OldNamecall
        setreadonly(GameMetaTable, true)
        getgenv().BulletTrack = nil
    end
    
    
    if BulletTrack.oldHook then
        removeHook()
    end
    BulletTrack.enabled = false
    
    WindUI:Notify({Title = "透视", Content = "所有透视已关闭"})
end)

Toggle(Tab1, "透视所有玩家", false, function(value)
    if value then
        local Players = game:GetService("Players")
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "PlayerESP_" .. player.Name
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)    
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 0) 
                    highlight.FillTransparency = 0.3  
                    highlight.OutlineTransparency = 0.3 
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = head
                end
            end
        end
    else
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            if player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local esp = head:FindFirstChild("PlayerESP_" .. player.Name)
                    if esp then
                        esp:Destroy()
                    end
                end
            end
        end
    end
end)

Toggle(Tab1, "血量条显示", false, function(Value)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ESPTable = {}

    if Value then
        local function CreateHealthBar(player)
            if ESPTable[player] then return end
            
            local character = player.Character
            if not character then return end
            
            local humanoid = character:WaitForChild("Humanoid", 5)
            local head = character:WaitForChild("Head", 5)
            
            if not humanoid or not head then return end
            
            
            if head:FindFirstChild("HealthBar_" .. player.Name) then
                head:FindFirstChild("HealthBar_" .. player.Name):Destroy()
            end
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "HealthBar_" .. player.Name
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 80, 0, 15)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
            billboard.AlwaysOnTop = true
            billboard.ResetOnSpawn = false
            billboard.Parent = head
            
            local background = Instance.new("Frame")
            background.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
            background.BackgroundTransparency = 0.3
            background.Size = UDim2.new(1, 0, 1, 0)
            background.BorderSizePixel = 0
            background.Parent = billboard
            
            local healthBar = Instance.new("Frame")
            healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
            healthBar.BorderSizePixel = 0
            healthBar.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
            healthBar.Parent = background
            
            local healthText = Instance.new("TextLabel")
            healthText.Size = UDim2.new(1, 0, 1, 0)
            healthText.BackgroundTransparency = 1
            healthText.Text = tostring(math.floor(humanoid.Health))
            healthText.TextColor3 = Color3.new(1, 1, 1)
            healthText.TextStrokeTransparency = 0
            healthText.TextSize = 12
            healthText.Font = Enum.Font.GothamBold
            healthText.Parent = background
            
            ESPTable[player] = {
                Billboard = billboard,
                HealthBar = healthBar,
                HealthText = healthText,
                Humanoid = humanoid
            }
            
            
            local healthConnection
            healthConnection = humanoid.HealthChanged:Connect(function()
                UpdateHealthBar(player)
            end)
            
            
            local characterRemovingConnection
            characterRemovingConnection = player.CharacterRemoving:Connect(function()
                if ESPTable[player] then
                    RemoveHealthBar(player)
                end
            end)
            
            
            ESPTable[player].Connections = {
                HealthChanged = healthConnection,
                CharacterRemoving = characterRemovingConnection
            }
        end

        local function UpdateHealthBar(player)
            local espData = ESPTable[player]
            if not espData then return end
            
            local humanoid = espData.Humanoid
            if not humanoid or humanoid.Health <= 0 then
                RemoveHealthBar(player)
                return
            end
            
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            espData.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
            espData.HealthText.Text = tostring(math.floor(humanoid.Health))
            
            
            if healthPercent > 0.7 then
                espData.HealthBar.BackgroundColor3 = Color3.new(0, 1, 0) -- 绿色
            elseif healthPercent > 0.3 then
                espData.HealthBar.BackgroundColor3 = Color3.new(1, 1, 0) -- 黄色
            else
                espData.HealthBar.BackgroundColor3 = Color3.new(1, 0, 0) -- 红色
            end
        end

        local function RemoveHealthBar(player)
            local espData = ESPTable[player]
            if espData then
                
                if espData.Connections then
                    for _, connection in pairs(espData.Connections) do
                        if connection then
                            connection:Disconnect()
                        end
                    end
                end
                
                
                if espData.Billboard and espData.Billboard.Parent then
                    espData.Billboard:Destroy()
                end
                
                ESPTable[player] = nil
            end
        end

        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character then
                    coroutine.wrap(CreateHealthBar)(player)
                end
                player.CharacterAdded:Connect(function(character)
                    wait(1)
                    CreateHealthBar(player)
                end)
            end
        end
        
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                wait(1)
                CreateHealthBar(player)
            end)
        end)
        
        
        Players.PlayerRemoving:Connect(function(player)
            if ESPTable[player] then
                RemoveHealthBar(player)
            end
        end)
        
        getgenv().HealthBarESP = ESPTable
        
    else
        
        for player, espData in pairs(ESPTable) do
            RemoveHealthBar(player)
        end
        
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Head") then
                local head = player.Character.Head
                local healthBar = head:FindFirstChild("HealthBar_" .. player.Name)
                if healthBar then
                    healthBar:Destroy()
                end
            end
        end
        
        table.clear(ESPTable)
        if getgenv().HealthBarESP then
            getgenv().HealthBarESP = nil
        end
    end
end)

Toggle(Tab1, "高亮显示玩家", false, function(Value)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local HighlightTable = {}

    if Value then
        local function GetTeamColor(player)
            if player.Team then
                return player.Team.TeamColor.Color
            else
                return Color3.new(0.5, 0.5, 0.5)
            end
        end

        local function CreatePlayerHighlight(player)
            if HighlightTable[player] then return end
            
            local character = player.Character
            if not character then return end
            
            local teamColor = GetTeamColor(player)
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "PlayerHighlight"
            highlight.FillColor = teamColor
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0
            highlight.Adornee = character
            highlight.Parent = character
            
            HighlightTable[player] = {
                Highlight = highlight,
                TeamColor = teamColor
            }
        end

        local function UpdatePlayerHighlight(player)
            local highlightData = HighlightTable[player]
            if highlightData and highlightData.Highlight then
                local teamColor = GetTeamColor(player)
                highlightData.Highlight.FillColor = teamColor
                highlightData.TeamColor = teamColor
            end
        end

        local function RemovePlayerHighlight(player)
            local highlightData = HighlightTable[player]
            if highlightData and highlightData.Highlight then
                highlightData.Highlight:Destroy()
            end
            HighlightTable[player] = nil
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character then
                    CreatePlayerHighlight(player)
                end
                player.CharacterAdded:Connect(function()
                    CreatePlayerHighlight(player)
                end)
            end
        end
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                CreatePlayerHighlight(player)
            end)
        end)
        
        
        local teamChangedConnection
        teamChangedConnection = game:GetService("RunService").Heartbeat:Connect(function()
            for player, highlightData in pairs(HighlightTable) do
                if player and player.Team then
                    local currentTeamColor = GetTeamColor(player)
                    if highlightData.TeamColor ~= currentTeamColor then
                        UpdatePlayerHighlight(player)
                    end
                end
            end
        end)
        
        getgenv().PlayerHighlight = {
            Table = HighlightTable,
            TeamConnection = teamChangedConnection
        }
        
    else
        if getgenv().PlayerHighlight then
            if getgenv().PlayerHighlight.TeamConnection then
                getgenv().PlayerHighlight.TeamConnection:Disconnect()
            end
            
            for player, highlightData in pairs(getgenv().PlayerHighlight.Table) do
                RemovePlayerHighlight(player)
            end
            
            getgenv().PlayerHighlight = nil
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local highlight = player.Character:FindFirstChild("PlayerHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end)

Toggle(Tab1, "高亮显示NPC", false, function(Value)
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    
    if Value then
        local NPCHighlightTable = {}
        
        local function IsNPC(model)
            if not model:IsA("Model") then return false end
            
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid then return false end
            
            local isPlayer = false
            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                if player.Character == model then
                    isPlayer = true
                    break
                end
            end
            
            return not isPlayer and humanoid.Health > 0
        end
        
        local function CreateNPCHighlight(npc)
            if NPCHighlightTable[npc] then return end
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "NPCHighlight"
            highlight.FillColor = Color3.new(1, 0.5, 0)
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0
            highlight.Adornee = npc
            highlight.Parent = npc
            
            NPCHighlightTable[npc] = {
                Highlight = highlight
            }
        end
        
        local function RemoveNPCHighlight(npc)
            local highlightData = NPCHighlightTable[npc]
            if highlightData and highlightData.Highlight then
                highlightData.Highlight:Destroy()
            end
            NPCHighlightTable[npc] = nil
        end
        
        local function ScanForNPCs()
            for _, descendant in pairs(Workspace:GetDescendants()) do
                if IsNPC(descendant) then
                    CreateNPCHighlight(descendant)
                end
            end
        end
        
        ScanForNPCs()
        
        local scanConnection
        scanConnection = RunService.Heartbeat:Connect(function()
            for _, descendant in pairs(Workspace:GetDescendants()) do
                if IsNPC(descendant) and not NPCHighlightTable[descendant] then
                    CreateNPCHighlight(descendant)
                end
            end
            
            for npc, highlightData in pairs(NPCHighlightTable) do
                if not npc:IsDescendantOf(Workspace) then
                    RemoveNPCHighlight(npc)
                end
            end
        end)
        
        local descendantAddedConnection
        descendantAddedConnection = Workspace.DescendantAdded:Connect(function(descendant)
            if IsNPC(descendant) then
                CreateNPCHighlight(descendant)
            end
        end)
        
        getgenv().NPCHighlight = {
            Table = NPCHighlightTable,
            ScanConnection = scanConnection,
            DescendantConnection = descendantAddedConnection
        }
        
    else
        
        if getgenv().NPCHighlight then
            if getgenv().NPCHighlight.ScanConnection then
                getgenv().NPCHighlight.ScanConnection:Disconnect()
            end
            if getgenv().NPCHighlight.DescendantConnection then
                getgenv().NPCHighlight.DescendantConnection:Disconnect()
            end
            
            for npc, highlightData in pairs(getgenv().NPCHighlight.Table) do
                RemoveNPCHighlight(npc)
            end
            
            getgenv().NPCHighlight = nil
        end
        
        
        for _, descendant in pairs(Workspace:GetDescendants()) do
            if descendant:IsA("Model") then
                for _, child in ipairs(descendant:GetChildren()) do
                    if child:IsA("Highlight") and child.Name == "NPCHighlight" then
                        child:Destroy()
                    end
                end
            end
        end
    end
end)

Toggle(Tab1, "透视NPC", false, function(Value)
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    
    if Value then
        local NPCESPTable = {}
        
        local function IsNPC(model)
            if not model:IsA("Model") then return false end
            
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid then return false end
            
            local isPlayer = false
            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                if player.Character == model then
                    isPlayer = true
                    break
                end
            end
            
            return not isPlayer and humanoid.Health > 0
        end
        
        local function CreateNPCESP(npc)
            if NPCESPTable[npc] then return end
            
            local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
            if not head then return end
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "NPCESP_" .. npc.Name
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 150, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = head
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = npc.Name
            textLabel.TextColor3 = Color3.new(1, 1, 1)
            textLabel.TextStrokeTransparency = 0
            textLabel.TextSize = 14
            textLabel.Font = Enum.Font.Gotham
            textLabel.Parent = billboard
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "NPCESP_Highlight"
            highlight.FillColor = Color3.new(0.5, 0, 0.5)
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0
            highlight.Adornee = npc
            highlight.Parent = npc
            
            NPCESPTable[npc] = {
                Billboard = billboard,
                Highlight = highlight
            }
        end
        
        local function RemoveNPCESP(npc)
            local espData = NPCESPTable[npc]
            if espData then
                if espData.Billboard then
                    espData.Billboard:Destroy()
                end
                if espData.Highlight then
                    espData.Highlight:Destroy()
                end
                NPCESPTable[npc] = nil
            end
        end
        
        local function ScanForNPCs()
            for _, descendant in pairs(Workspace:GetDescendants()) do
                if IsNPC(descendant) then
                    CreateNPCESP(descendant)
                end
            end
        end
        
        ScanForNPCs()
        
        local scanConnection
        scanConnection = RunService.Heartbeat:Connect(function()
            for _, descendant in pairs(Workspace:GetDescendants()) do
                if IsNPC(descendant) and not NPCESPTable[descendant] then
                    CreateNPCESP(descendant)
                end
            end
            
            for npc, espData in pairs(NPCESPTable) do
                if not npc:IsDescendantOf(Workspace) then
                    RemoveNPCESP(npc)
                end
            end
        end)
        
        local descendantAddedConnection
        descendantAddedConnection = Workspace.DescendantAdded:Connect(function(descendant)
            if IsNPC(descendant) then
                CreateNPCESP(descendant)
            end
        end)
        
        getgenv().NPCESP = {
            Table = NPCESPTable,
            ScanConnection = scanConnection,
            DescendantConnection = descendantAddedConnection
        }
        
    else
        if getgenv().NPCESP then
            if getgenv().NPCESP.ScanConnection then
                getgenv().NPCESP.ScanConnection:Disconnect()
            end
            if getgenv().NPCESP.DescendantConnection then
                getgenv().NPCESP.DescendantConnection:Disconnect()
            end
            
            for npc, espData in pairs(getgenv().NPCESP.Table) do
                RemoveNPCESP(npc)
            end
            
            getgenv().NPCESP = nil
        end
        
        for _, descendant in pairs(Workspace:GetDescendants()) do
            if descendant:IsA("Model") then
                for _, child in ipairs(descendant:GetDescendants()) do
                    if child:IsA("BillboardGui") and string.find(child.Name, "NPCESP_") then
                        child:Destroy()
                    end
                    if child:IsA("Highlight") and child.Name == "NPCESP_Highlight" then
                        child:Destroy()
                    end
                end
            end
        end
    end
end)

Toggle(Tab1, "透视敌方玩家", false, function(Value)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ESPTable = {}

    if Value then
        local function IsEnemyPlayer(player)
            if player == LocalPlayer then return false end
            
            local localTeam = LocalPlayer.Team
            local playerTeam = player.Team
            
            
            if not localTeam or not playerTeam or localTeam ~= playerTeam then
                return true
            end
            
            return false
        end

        local function CreateEnemyPlayerESP(player)
            if ESPTable[player] or not IsEnemyPlayer(player) then return end
            
            local character = player.Character
            if not character then return end
            
            local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
            if not head then return end
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "EnemyPlayerESP_" .. player.Name
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 150, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = head
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = player.Name
            textLabel.TextColor3 = Color3.new(1, 0, 0) 
            textLabel.TextStrokeTransparency = 0
            textLabel.TextSize = 14
            textLabel.Font = Enum.Font.GothamBold
            textLabel.Parent = billboard
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "EnemyPlayerHighlight"
            highlight.FillColor = Color3.new(1, 0, 0)
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0
            highlight.Adornee = character
            highlight.Parent = character
            
            ESPTable[player] = {
                Billboard = billboard,
                Highlight = highlight
            }
        end

        local function RemoveEnemyPlayerESP(player)
            local espData = ESPTable[player]
            if espData then
                if espData.Billboard then
                    espData.Billboard:Destroy()
                end
                if espData.Highlight then
                    espData.Highlight:Destroy()
                end
                ESPTable[player] = nil
            end
        end

        local function UpdateEnemyPlayers()
            for _, player in pairs(Players:GetPlayers()) do
                if IsEnemyPlayer(player) then
                    if not ESPTable[player] and player.Character then
                        CreateEnemyPlayerESP(player)
                    end
                else
                    if ESPTable[player] then
                        RemoveEnemyPlayerESP(player)
                    end
                end
            end
        end

        for _, player in pairs(Players:GetPlayers()) do
            if IsEnemyPlayer(player) and player.Character then
                CreateEnemyPlayerESP(player)
            end
            player.CharacterAdded:Connect(function()
                if IsEnemyPlayer(player) then
                    CreateEnemyPlayerESP(player)
                end
            end)
        end
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                if IsEnemyPlayer(player) then
                    CreateEnemyPlayerESP(player)
                end
            end)
        end)
        
        local teamCheckConnection
        teamCheckConnection = game:GetService("RunService").Heartbeat:Connect(function()
            UpdateEnemyPlayers()
        end)
        
        getgenv().EnemyPlayerESP = {
            Table = ESPTable,
            Connection = teamCheckConnection
        }
        
    else
        if getgenv().EnemyPlayerESP then
            if getgenv().EnemyPlayerESP.Connection then
                getgenv().EnemyPlayerESP.Connection:Disconnect()
            end
            
            for player, espData in pairs(getgenv().EnemyPlayerESP.Table) do
                RemoveEnemyPlayerESP(player)
            end
            
            getgenv().EnemyPlayerESP = nil
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local esp = player.Character:FindFirstChild("EnemyPlayerESP_" .. player.Name)
                if esp then
                    esp:Destroy()
                end
                local highlight = player.Character:FindFirstChild("EnemyPlayerHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end)

Toggle(Tab1, "透视敌方NPC", false, function(Value)
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    
    if Value then
        local EnemyNPCESPTable = {}
        
        local function IsEnemyNPC(model)
            if not model:IsA("Model") then return false end
            
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid then return false end
            
            local isPlayer = false
            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                if player.Character == model then
                    isPlayer = true
                    break
                end
            end
            
            if isPlayer then return false end
            
            
            local localTeam = game.Players.LocalPlayer.Team
            local npcTeam = model:FindFirstChild("Team") or model:FindFirstChildOfClass("Team")
            
            
            if not localTeam or not npcTeam or localTeam ~= npcTeam then
                return true
            end
            
            return false
        end
        
        local function CreateEnemyNPCESP(npc)
            if EnemyNPCESPTable[npc] then return end
            
            local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
            if not head then return end
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "EnemyNPCESP_" .. npc.Name
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 150, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = head
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = npc.Name
            textLabel.TextColor3 = Color3.new(1, 0, 0)
            textLabel.TextStrokeTransparency = 0
            textLabel.TextSize = 14
            textLabel.Font = Enum.Font.Gotham
            textLabel.Parent = billboard
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "EnemyNPCHighlight"
            highlight.FillColor = Color3.new(1, 0, 0)
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0
            highlight.Adornee = npc
            highlight.Parent = npc
            
            EnemyNPCESPTable[npc] = {
                Billboard = billboard,
                Highlight = highlight
            }
        end
        
        local function RemoveEnemyNPCESP(npc)
            local espData = EnemyNPCESPTable[npc]
            if espData then
                if espData.Billboard then
                    espData.Billboard:Destroy()
                end
                if espData.Highlight then
                    espData.Highlight:Destroy()
                end
                EnemyNPCESPTable[npc] = nil
            end
        end
        
        local function ScanForEnemyNPCs()
            for _, descendant in pairs(Workspace:GetDescendants()) do
                if IsEnemyNPC(descendant) then
                    CreateEnemyNPCESP(descendant)
                end
            end
        end
        
        ScanForEnemyNPCs()
        
        local scanConnection
        scanConnection = RunService.Heartbeat:Connect(function()
            for _, descendant in pairs(Workspace:GetDescendants()) do
                if IsEnemyNPC(descendant) and not EnemyNPCESPTable[descendant] then
                    CreateEnemyNPCESP(descendant)
                end
            end
            
            for npc, espData in pairs(EnemyNPCESPTable) do
                if not npc:IsDescendantOf(Workspace) or not IsEnemyNPC(npc) then
                    RemoveEnemyNPCESP(npc)
                end
            end
        end)
        
        local descendantAddedConnection
        descendantAddedConnection = Workspace.DescendantAdded:Connect(function(descendant)
            if IsEnemyNPC(descendant) then
                CreateEnemyNPCESP(descendant)
            end
        end)
        
        getgenv().EnemyNPCESP = {
            Table = EnemyNPCESPTable,
            ScanConnection = scanConnection,
            DescendantConnection = descendantAddedConnection
        }
        
    else
        if getgenv().EnemyNPCESP then
            if getgenv().EnemyNPCESP.ScanConnection then
                getgenv().EnemyNPCESP.ScanConnection:Disconnect()
            end
            if getgenv().EnemyNPCESP.DescendantConnection then
                getgenv().EnemyNPCESP.DescendantConnection:Disconnect()
            end
            
            for npc, espData in pairs(getgenv().EnemyNPCESP.Table) do
                RemoveEnemyNPCESP(npc)
            end
            
            getgenv().EnemyNPCESP = nil
        end
        
        for _, descendant in pairs(Workspace:GetDescendants()) do
            if descendant:IsA("Model") then
                for _, child in ipairs(descendant:GetDescendants()) do
                    if child:IsA("BillboardGui") and string.find(child.Name, "EnemyNPCESP_") then
                        child:Destroy()
                    end
                    if child:IsA("Highlight") and string.find(child.Name, "EnemyNPCHighlight") then
                        child:Destroy()
                    end
                end
            end
        end
    end
end)

Toggle(Tab1, "esp", false, function(state)
    pcall(function()
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character then
                if state then
                    local highlight = Instance.new("Highlight")
                    highlight.Parent = player.Character
                    highlight.Adornee = player.Character

                    local billboard = Instance.new("BillboardGui")
                    billboard.Parent = player.Character
                    billboard.Adornee = player.Character
                    billboard.Size = UDim2.new(0, 100, 0, 100)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.AlwaysOnTop = true

                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Parent = billboard
                    nameLabel.Size = UDim2.new(1, 0, 1, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = player.Name
                    nameLabel.TextColor3 = Color3.new(1, 1, 1)
                    nameLabel.TextStrokeTransparency = 0.5
                    nameLabel.TextScaled = true

                    local circle = Instance.new("ImageLabel")
                    circle.Parent = billboard
                    circle.Size = UDim2.new(0, 50, 0, 50)
                    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
                    circle.AnchorPoint = Vector2.new(0.5, 0.5)
                    circle.BackgroundTransparency = 1
                    circle.Image = "rbxassetid://2200552246"
                else
                    if player.Character:FindFirstChildOfClass("Highlight") then
                        player.Character:FindFirstChildOfClass("Highlight"):Destroy()
                    end
                    if player.Character:FindFirstChildOfClass("BillboardGui") then
                        player.Character:FindFirstChildOfClass("BillboardGui"):Destroy()
                    end
                end
            end
        end
    end)
end)


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera


local ESPData = {
    BoxESP = false,
    SkeletonESP = false,
    NameESP = false,
    TracerESP = false
}


local ESPObjects = {}


local function CreateSkeletonESP(player)
    if not player.Character then return end
    
    local character = player.Character
    local connections = {}
    
    
    local boneConnections = {
        
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LowerTorso", "RightUpperLeg"},
        
        
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        
        
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        
        
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        
        
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"}
    }
    
    
    for _, connection in ipairs(boneConnections) do
        local part1 = character:FindFirstChild(connection[1])
        local part2 = character:FindFirstChild(connection[2])
        
        if part1 and part2 then
            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = Color3.new(0, 1, 0)
            line.Thickness = 2
            
            table.insert(connections, {
                Part1 = part1,
                Part2 = part2,
                Line = line
            })
        end
    end
    
    return connections
end


local function CreateTracer(player)
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.new(1, 1, 1)
    line.Thickness = 1
    return line
end


local function CreateNameTag(player)
    local text = Drawing.new("Text")
    text.Visible = false
    text.Color = Color3.new(1, 1, 1) 
    text.Size = 18
    text.Text = player.Name
    text.Center = true
    text.Outline = true
    return text
end


local function CreateBoxESP(player)
    if not player.Character then return end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.new(1, 0, 0)
    box.Thickness = 2
    box.Filled = false
    
    return box
end


local function UpdateESP()
    for player, data in pairs(ESPObjects) do
        if not player or not player.Character or player.Character.Humanoid.Health <= 0 then
            
            if data.Box then data.Box.Visible = false end
            if data.NameTag then data.NameTag.Visible = false end
            if data.Tracer then data.Tracer.Visible = false end
            if data.Skeleton then
                for _, bone in ipairs(data.Skeleton) do
                    bone.Line.Visible = false
                end
            end
        else
            local character = player.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                
                local rootPos, rootOnScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
                local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                
                
                if data.Box and ESPData.BoxESP then
                    if rootOnScreen then
                        local size = (headPos.Y - rootPos.Y) * 2
                        data.Box.Size = Vector2.new(size * 0.8, size)
                        data.Box.Position = Vector2.new(rootPos.X - size * 0.4, rootPos.Y - size * 0.5)
                        data.Box.Visible = true
                    else
                        data.Box.Visible = false
                    end
                elseif data.Box then
                    data.Box.Visible = false
                end
                
                
                if data.NameTag and ESPData.NameESP then
                    if headOnScreen then
                        data.NameTag.Position = Vector2.new(headPos.X, headPos.Y - 30)
                        data.NameTag.Visible = true
                    else
                        data.NameTag.Visible = false
                    end
                elseif data.NameTag then
                    data.NameTag.Visible = false
                end
                
                
                if data.Tracer and ESPData.TracerESP then
                    if rootOnScreen then
                        data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                        data.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                        data.Tracer.Visible = true
                    else
                        data.Tracer.Visible = false
                    end
                elseif data.Tracer then
                    data.Tracer.Visible = false
                end
                
                
                if data.Skeleton and ESPData.SkeletonESP then
                    for _, bone in ipairs(data.Skeleton) do
                        if bone.Part1 and bone.Part2 then
                            local pos1, onScreen1 = Camera:WorldToViewportPoint(bone.Part1.Position)
                            local pos2, onScreen2 = Camera:WorldToViewportPoint(bone.Part2.Position)
                            
                            if onScreen1 and onScreen2 then
                                bone.Line.From = Vector2.new(pos1.X, pos1.Y)
                                bone.Line.To = Vector2.new(pos2.X, pos2.Y)
                                bone.Line.Visible = true
                            else
                                bone.Line.Visible = false
                            end
                        else
                            bone.Line.Visible = false
                        end
                    end
                elseif data.Skeleton then
                    for _, bone in ipairs(data.Skeleton) do
                        bone.Line.Visible = false
                    end
                end
            end
        end
    end
end


local function InitializePlayerESP(player)
    if player == LocalPlayer then return end
    
    ESPObjects[player] = {
        Box = CreateBoxESP(player),
        NameTag = CreateNameTag(player),
        Tracer = CreateTracer(player),
        Skeleton = CreateSkeletonESP(player)
    }
    
    
    player.CharacterAdded:Connect(function()
        wait(1) 
        ESPObjects[player] = {
            Box = CreateBoxESP(player),
            NameTag = CreateNameTag(player),
            Tracer = CreateTracer(player),
            Skeleton = CreateSkeletonESP(player)
        }
    end)
    
    player.CharacterRemoving:Connect(function()
        if ESPObjects[player] then
            if ESPObjects[player].Box then ESPObjects[player].Box:Remove() end
            if ESPObjects[player].NameTag then ESPObjects[player].NameTag:Remove() end
            if ESPObjects[player].Tracer then ESPObjects[player].Tracer:Remove() end
            if ESPObjects[player].Skeleton then
                for _, bone in ipairs(ESPObjects[player].Skeleton) do
                    bone.Line:Remove()
                end
            end
            ESPObjects[player] = nil
        end
    end)
end


local function CleanupESP()
    for player, data in pairs(ESPObjects) do
        if data.Box then data.Box:Remove() end
        if data.NameTag then data.NameTag:Remove() end
        if data.Tracer then data.Tracer:Remove() end
        if data.Skeleton then
            for _, bone in ipairs(data.Skeleton) do
                bone.Line:Remove()
            end
        end
    end
    ESPObjects = {}
end


local ESPConnection
local function StartESP()
    if ESPConnection then return end
    
    
    for _, player in pairs(Players:GetPlayers()) do
        InitializePlayerESP(player)
    end
    
    
    Players.PlayerAdded:Connect(InitializePlayerESP)
    
    
    ESPConnection = RunService.RenderStepped:Connect(UpdateESP)
end

local function StopESP()
    if ESPConnection then
        ESPConnection:Disconnect()
        ESPConnection = nil
    end
    CleanupESP()
end


Toggle(Tab1, "方框透视", false, function(Value)
    ESPData.BoxESP = Value
    if not ESPConnection and (ESPData.BoxESP or ESPData.SkeletonESP or ESPData.NameESP or ESPData.TracerESP) then
        StartESP()
    elseif ESPConnection and not (ESPData.BoxESP or ESPData.SkeletonESP or ESPData.NameESP or ESPData.TracerESP) then
        StopESP()
    end
end)

Toggle(Tab1, "骨骼透视", false, function(Value)
    ESPData.SkeletonESP = Value
    if not ESPConnection and (ESPData.BoxESP or ESPData.SkeletonESP or ESPData.NameESP or ESPData.TracerESP) then
        StartESP()
    elseif ESPConnection and not (ESPData.BoxESP or ESPData.SkeletonESP or ESPData.NameESP or ESPData.TracerESP) then
        StopESP()
    end
end)

Toggle(Tab1, "名称透视", false, function(Value)
    ESPData.NameESP = Value
    if not ESPConnection and (ESPData.BoxESP or ESPData.SkeletonESP or ESPData.NameESP or ESPData.TracerESP) then
        StartESP()
    elseif ESPConnection and not (ESPData.BoxESP or ESPData.SkeletonESP or ESPData.NameESP or ESPData.TracerESP) then
        StopESP()
    end
end)

Toggle(Tab1, "透视线条", false, function(Value)
    ESPData.TracerESP = Value
    if not ESPConnection and (ESPData.BoxESP or ESPData.SkeletonESP or ESPData.NameESP or ESPData.TracerESP) then
        StartESP()
    elseif ESPConnection and not (ESPData.BoxESP or ESPData.SkeletonESP or ESPData.NameESP or ESPData.TracerESP) then
        StopESP()
    end
end)

Toggle(Tab1, "距离显示", false, function(Value)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local DistanceTable = {}

    if Value then
        local function CreateDistanceDisplay(player)
            if DistanceTable[player] then return end
            
            local character = player.Character
            if not character then return end
            
            local head = character:FindFirstChild("Head")
            if not head then return end
            
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "DistanceDisplay_" .. player.Name
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 80, 0, 20)
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = head
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = "0m"
            textLabel.TextColor3 = Color3.new(1, 1, 1)
            textLabel.TextStrokeTransparency = 0
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.GothamBold
            textLabel.Parent = billboard
            
            DistanceTable[player] = {
                Billboard = billboard,
                TextLabel = textLabel
            }
        end

        local function UpdateDistance()
            for player, espData in pairs(DistanceTable) do
                if player.Character and player.Character:FindFirstChild("Head") and 
                   LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                   
                    local distance = (player.Character.Head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    espData.TextLabel.Text = string.format("%.1fm", distance)
                end
            end
        end
        
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character then
                    CreateDistanceDisplay(player)
                end
                player.CharacterAdded:Connect(function()
                    CreateDistanceDisplay(player)
                end)
            end
        end
        
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                CreateDistanceDisplay(player)
            end)
        end)
        
        
        local connection = RunService.Heartbeat:Connect(UpdateDistance)
        
        getgenv().DistanceESP = {
            Table = DistanceTable,
            Connection = connection
        }
        
    else
        
        if getgenv().DistanceESP then
            if getgenv().DistanceESP.Connection then
                getgenv().DistanceESP.Connection:Disconnect()
            end
            
            for player, espData in pairs(getgenv().DistanceESP.Table) do
                if espData and espData.Billboard then
                    espData.Billboard:Destroy()
                end
            end
            
            getgenv().DistanceESP = nil
        end
        
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local distanceDisplay = player.Character:FindFirstChild("DistanceDisplay_" .. player.Name)
                if distanceDisplay then
                    distanceDisplay:Destroy()
                end
            end
        end
    end
end)

Toggle(Tab1, "透视手中物品", false, function(Value)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    
    if Value then
        local ToolESPTable = {}
        
        local function CreateToolESP(player)
            if ToolESPTable[player] then return end
            
            local character = player.Character
            if not character then return end
            
            
            local function findEquippedTool()
                
                local rightHand = character:FindFirstChild("RightHand")
                if rightHand then
                    for _, tool in ipairs(character:GetChildren()) do
                        if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                            local handle = tool.Handle
                            
                            for _, weld in ipairs(handle:GetChildren()) do
                                if weld:IsA("Weld") and weld.Part1 == rightHand then
                                    return tool
                                end
                            end
                        end
                    end
                end
                
                
                for _, tool in ipairs(character:GetChildren()) do
                    if tool:IsA("Tool") then
                        return tool
                    end
                end
                
                return nil
            end
            
            local tool = findEquippedTool()
            if not tool then return end
            
            local handle = tool:FindFirstChild("Handle")
            if not handle then return end
            
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ToolESP_" .. player.Name
            billboard.Adornee = handle
            billboard.Size = UDim2.new(0, 200, 0, 40)
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = handle
            
            local frame = Instance.new("Frame")
            frame.BackgroundColor3 = Color3.new(1, 0.5, 0)
            frame.BackgroundTransparency = 0.2
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.Parent = billboard
            
            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(0, 5)
            uiCorner.Parent = frame
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = tool.Name
            textLabel.TextColor3 = Color3.new(1, 1, 1)
            textLabel.TextStrokeTransparency = 0
            textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.GothamBold
            textLabel.Parent = frame
            
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "ToolHighlight_" .. player.Name
            highlight.FillColor = Color3.new(1, 0.5, 0)
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0
            highlight.Adornee = tool
            highlight.Parent = tool
            
            ToolESPTable[player] = {
                Billboard = billboard,
                Highlight = highlight,
                Tool = tool
            }
            
            
            local toolConnection
            toolConnection = character.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    
                    wait(0.1)
                    RemoveToolESP(player)
                    CreateToolESP(player)
                end
            end)
            
            ToolESPTable[player].ToolConnection = toolConnection
        end
        
        local function RemoveToolESP(player)
            local espData = ToolESPTable[player]
            if espData then
                if espData.Billboard then
                    espData.Billboard:Destroy()
                end
                if espData.Highlight then
                    espData.Highlight:Destroy()
                end
                if espData.ToolConnection then
                    espData.ToolConnection:Disconnect()
                end
                ToolESPTable[player] = nil
            end
        end
        
        
        local checkConnection
        checkConnection = RunService.Heartbeat:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if not ToolESPTable[player] then
                        CreateToolESP(player)
                    else
                        
                        local espData = ToolESPTable[player]
                        if espData and espData.Tool and not player.Character:FindFirstChild(espData.Tool.Name) then
                            RemoveToolESP(player)
                            CreateToolESP(player)
                        end
                    end
                end
            end
        end)
        
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character then
                    CreateToolESP(player)
                end
                player.CharacterAdded:Connect(function()
                    wait(1)
                    CreateToolESP(player)
                end)
            end
        end
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                wait(1)
                CreateToolESP(player)
            end)
        end)
        
        getgenv().ToolESP = {
            Table = ToolESPTable,
            Connection = checkConnection
        }
        
    else
        
        if getgenv().ToolESP then
            if getgenv().ToolESP.Connection then
                getgenv().ToolESP.Connection:Disconnect()
            end
            
            for player, espData in pairs(getgenv().ToolESP.Table) do
                RemoveToolESP(player)
            end
            
            getgenv().ToolESP = nil
        end
        
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                
                for _, child in ipairs(player.Character:GetDescendants()) do
                    if child:IsA("BillboardGui") and string.find(child.Name, "ToolESP_") then
                        child:Destroy()
                    end
                end
                
                for _, child in ipairs(player.Character:GetDescendants()) do
                    if child:IsA("Highlight") and string.find(child.Name, "ToolHighlight_") then
                        child:Destroy()
                    end
                end
            end
        end
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


function tp(p)
    LocalPlayer.Character:PivotTo(p)
end


local playerList = {}
local selectedPlayer = nil


function refreshPlayerList(includeSelf)
    playerList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if includeSelf or player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
end


refreshPlayerList(true)


local dropdown
dropdown = Tab1:Dropdown({
    Title = "选择玩家名称",
    Values = playerList,
    Callback = function(value)
        selectedPlayer = value
    end
})

Button(Tab1, "刷新列表", function()
    refreshPlayerList(true)
    dropdown:Refresh(playerList)
end)

Button(Tab1, "传送到玩家旁边", function()
    if selectedPlayer and Players:FindFirstChild(selectedPlayer) then
        local targetPlayer = Players[selectedPlayer]
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            tp(targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0))
        end
    end
end)

Button(Tab1, "重置人物", function() 
    game.Players.LocalPlayer.Character.Humanoid.Health = 0
end)

Button(Tab1, "重进服务器", function() 
    game:GetService("TeleportService"):TeleportToPlaceInstance(
            game.PlaceId,
            game.JobId,
            game:GetService("Players").LocalPlayer
        )
end)

Button(Tab1, "离开服务器", function() 
    game:Shutdown()
end)

Button(Tab1, "移动锁", function() 
    local ShiftlockStarterGui = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
ShiftlockStarterGui.Name = "Shiftlock (StarterGui)"
ShiftlockStarterGui.Parent = game.CoreGui
ShiftlockStarterGui.ZIndexBehavior =  Enum.ZIndexBehavior.Sibling
ShiftlockStarterGui.ResetOnSpawn = false

ImageButton.Parent = ShiftlockStarterGui
ImageButton.Active = true
ImageButton.Draggable = true
ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageButton.BackgroundTransparency = 1.000
ImageButton.Position = UDim2.new(0.921914339, 0, 0.552375436, 0)
ImageButton.Size = UDim2.new(0.0636147112, 0, 0.0661305636, 0)
ImageButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
ImageButton.Image = "http://www.roblox.com/asset/?id=182223762"
local function TLQOYN_fake_script()
    local script = Instance.new("LocalScript", ImageButton)

    local MobileCameraFramework = {}
    local Players = game.Players
    local runservice = game:GetService("RunService")
    local CAS = game:GetService("ContextActionService")
    local Player = Players.LocalPlayer
    local character = Player.Character or Player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    local humanoid = character.Humanoid
    local camera = workspace.CurrentCamera
    local button = script.Parent
    uis = game:GetService("UserInputService")
    ismobile = uis.TouchEnabled
    button.Visible = ismobile
    
    local states = {
        OFF = "rbxasset://textures/ui/mouseLock_off@2x.png",
        ON = "rbxasset://textures/ui/mouseLock_on@2x.png"
    }
    local MAX_LENGTH = 900000
    local active = false
    local ENABLED_OFFSET = CFrame.new(1.7, 0, 0)
    local DISABLED_OFFSET = CFrame.new(-1.7, 0, 0)
local rootPos = Vector3.new(0,0,0)
local function UpdatePos()
if Player.Character and Player.Character:FindFirstChildOfClass"Humanoid" and Player.Character:FindFirstChildOfClass"Humanoid".RootPart then
rootPos = Player.Character:FindFirstChildOfClass"Humanoid".RootPart.Position
end
end
    local function UpdateImage(STATE)
        button.Image = states[STATE]
    end
    local function UpdateAutoRotate(BOOL)
if Player.Character and Player.Character:FindFirstChildOfClass"Humanoid" then
Player.Character:FindFirstChildOfClass"Humanoid".AutoRotate = BOOL
end
end
    local function GetUpdatedCameraCFrame()
if game:GetService"Workspace".CurrentCamera then
return CFrame.new(rootPos, Vector3.new(game:GetService"Workspace".CurrentCamera.CFrame.LookVector.X * MAX_LENGTH, rootPos.Y, game:GetService"Workspace".CurrentCamera.CFrame.LookVector.Z * MAX_LENGTH))
end
end
    local function EnableShiftlock()
UpdatePos()
        UpdateAutoRotate(false)
        UpdateImage("ON")
if Player.Character and Player.Character:FindFirstChildOfClass"Humanoid" and Player.Character:FindFirstChildOfClass"Humanoid".RootPart then
Player.Character:FindFirstChildOfClass"Humanoid".RootPart.CFrame = GetUpdatedCameraCFrame()
end
if game:GetService"Workspace".CurrentCamera then
game:GetService"Workspace".CurrentCamera.CFrame = camera.CFrame * ENABLED_OFFSET
end
    end
    local function DisableShiftlock()
UpdatePos()
        UpdateAutoRotate(true)
        UpdateImage("OFF")
        if game:GetService"Workspace".CurrentCamera then
game:GetService"Workspace".CurrentCamera.CFrame = camera.CFrame * DISABLED_OFFSET
end
        pcall(function()
            active:Disconnect()
            active = nil
        end)
    end
    UpdateImage("OFF")
    active = false
    function ShiftLock()
        if not active then
            active = runservice.RenderStepped:Connect(function()
                EnableShiftlock()
            end)
        else
            DisableShiftlock()
        end
    end
    local ShiftLockButton = CAS:BindAction("ShiftLOCK", ShiftLock, false, "On")
    CAS:SetPosition("ShiftLOCK", UDim2.new(0.8, 0, 0.8, 0))
    button.MouseButton1Click:Connect(function()
        if not active then
            active = runservice.RenderStepped:Connect(function()
                EnableShiftlock()
            end)
        else
            DisableShiftlock()
        end
    end)
    return MobileCameraFramework
    
end
coroutine.wrap(TLQOYN_fake_script)()
local function OMQRQRC_fake_script()
    local script = Instance.new("LocalScript", ShiftlockStarterGui)

    local Players = game.Players
    local UserInputService = game:GetService("UserInputService")
    local Settings = UserSettings()
    local GameSettings = Settings.GameSettings
    local ShiftLockController = {}
    while not Players.LocalPlayer do
        wait()
    end
    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local ScreenGui, ShiftLockIcon, InputCn
    local IsShiftLockMode = true
    local IsShiftLocked = true
    local IsActionBound = false
    local IsInFirstPerson = false
    ShiftLockController.OnShiftLockToggled = Instance.new("BindableEvent")
    local function isShiftLockMode()
        return LocalPlayer.DevEnableMouseLock and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.ClickToMove and GameSettings.ComputerMovementMode ~= Enum.ComputerMovementMode.ClickToMove and LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.Scriptable
    end
    if not UserInputService.TouchEnabled then
        IsShiftLockMode = isShiftLockMode()
    end
    local function onShiftLockToggled()
        IsShiftLocked = not IsShiftLocked
        ShiftLockController.OnShiftLockToggled:Fire()
    end
    local initialize = function()
        print("enabled")
    end
    function ShiftLockController:IsShiftLocked()
        return IsShiftLockMode and IsShiftLocked
    end
    function ShiftLockController:SetIsInFirstPerson(isInFirstPerson)
        IsInFirstPerson = isInFirstPerson
    end
    local function mouseLockSwitchFunc(actionName, inputState, inputObject)
        if IsShiftLockMode then
            onShiftLockToggled()
        end
    end
    local function disableShiftLock()
        if ScreenGui then
            ScreenGui.Parent = nil
        end
        IsShiftLockMode = false
        Mouse.Icon = ""
        if InputCn then
            InputCn:disconnect()
            InputCn = nil
        end
        IsActionBound = false
        ShiftLockController.OnShiftLockToggled:Fire()
    end
    local onShiftInputBegan = function(inputObject, isProcessed)
        if isProcessed then
            return
        end
        if inputObject.UserInputType ~= Enum.UserInputType.Keyboard or inputObject.KeyCode == Enum.KeyCode.LeftShift or inputObject.KeyCode == Enum.KeyCode.RightShift then
        end
    end
    local function enableShiftLock()
        IsShiftLockMode = isShiftLockMode()
        if IsShiftLockMode then
            if ScreenGui then
                ScreenGui.Parent = PlayerGui
            end
            if IsShiftLocked then
                ShiftLockController.OnShiftLockToggled:Fire()
            end
            if not IsActionBound then
                InputCn = UserInputService.InputBegan:connect(onShiftInputBegan)
                IsActionBound = true
            end
        end
    end
    GameSettings.Changed:connect(function(property)
        if property == "ControlMode" then
            if GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch then
                enableShiftLock()
            else
                disableShiftLock()
            end
        elseif property == "ComputerMovementMode" then
            if GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove then
                disableShiftLock()
            else
                enableShiftLock()
            end
        end
    end)
    LocalPlayer.Changed:connect(function(property)
        if property == "DevEnableMouseLock" then
            if LocalPlayer.DevEnableMouseLock then
                enableShiftLock()
            else
                disableShiftLock()
            end
        elseif property == "DevComputerMovementMode" then
            if LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.ClickToMove or LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable then
                disableShiftLock()
            else
                enableShiftLock()
            end
        end
    end)
    LocalPlayer.CharacterAdded:connect(function(character)
        if not UserInputService.TouchEnabled then
            initialize()
        end
    end)
    if not UserInputService.TouchEnabled then
        initialize()
        if isShiftLockMode() then
            InputCn = UserInputService.InputBegan:connect(onShiftInputBegan)
            IsActionBound = true
        end
    end
    enableShiftLock()
    return ShiftLockController
    
end
coroutine.wrap(OMQRQRC_fake_script)()
end)

Button(Tab1, "点击传送工具", function() 
    mouse = game.Players.LocalPlayer:GetMouse()
                tool = Instance.new("Tool")
                tool.RequiresHandle = false
                tool.Name = "Click Teleport"
                tool.Activated:connect(function()
                local pos = mouse.Hit+Vector3.new(0,2.5,0)
                pos = CFrame.new(pos.X,pos.Y,pos.Z)
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = pos
                end)
                tool.Parent = game.Players.LocalPlayer.Backpack
end)

Button(Tab1, "玩家进入游戏 退出游戏通知", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/boyscp/scriscriptsc/main/bbn.lua"))()
end)

Button(Tab1, "egro假延迟", function() 
    loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-roblox-egor-script-53041"))()
end)

Button(Tab1, "打飞机r6", function() 
        loadstring(game:HttpGet("https://pastefy.app/wa3v2Vgm/raw"))()
end)

Button(Tab1, "打飞机r15", function() 
        loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))()
end)

Button(Tab1, "无敌少侠", function() 
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Invinicible-Flight-R15-45414"))()
end)

Button(Tab1, "摔落无伤害(可创飞人)", function() 
        loadstring(game:HttpGet("http://rawscripts.net/raw/Universal-Script-Touch-fling-script-22447"))()
end)

Button(Tab1, "飞车(by皮空)", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/smalldesikon/eyidfki/main/%E9%A3%9E%E8%BD%A6(%E6%BA%90%E7%A0%81).lua"))()
end)

Button(Tab1, "飞行v1", function() 
    loadstring("\108\111\97\100\115\116\114\105\110\103\40\103\97\109\101\58\72\116\116\112\71\101\116\40\34\104\116\116\112\115\58\47\47\112\97\115\116\101\98\105\110\46\99\111\109\47\114\97\119\47\90\66\122\99\84\109\49\102\34\41\41\40\41\10")()
end)

Button(Tab1, "冷飞行", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/odhdshhe/-V3.0/refs/heads/main/%E9%A3%9E%E8%A1%8C%E8%84%9A%E6%9C%ACV3(%E5%85%A8%E6%B8%B8%E6%88%8F%E9%80%9A%E7%94%A8)%20(1).txt"))()
end)

Button(Tab1, "反挂机v2", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/9fFu43FF"))()
end)

Button(Tab1, "死亡笔记", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dingding123hhh/tt/main/%E6%AD%BB%E4%BA%A1%E7%AC%94%E8%AE%B0%20(1).txt"))()
end)

Button(Tab1, "爬墙跳脚本(装逼用)", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ScpGuest666/Random-Roblox-script/refs/heads/main/Roblox%20WallHop%20V4%20script"))()
end)

Button(Tab1, "fenny甩飞gui", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/fe-flinger-gui-works-anywhere_1756291955889_SwfaGHMWsT.txt"))()
end)

local AntiFlingEnabled = false
local AntiFlingConnections = {}

Toggle(Tab1, "防甩飞", false, function(Value)
    AntiFlingEnabled = Value
    
    if Value then
        
        local Services = setmetatable({}, {__index = function(Self, Index)
            local NewService = game.GetService(game, Index)
            if NewService then
                Self[Index] = NewService
            end
            return NewService
        end})

        local LocalPlayer = Services.Players.LocalPlayer

        local function PlayerAdded(Player)
            local Detected = false
            local Character
            local PrimaryPart

            local function CharacterAdded(NewCharacter)
                Character = NewCharacter
                repeat
                    wait()
                    PrimaryPart = NewCharacter:FindFirstChild("HumanoidRootPart")
                until PrimaryPart
                Detected = false
            end

            CharacterAdded(Player.Character or Player.CharacterAdded:Wait())
            local charAddedConn = Player.CharacterAdded:Connect(CharacterAdded)
            
            local heartbeatConn = Services.RunService.Heartbeat:Connect(function()
                if not AntiFlingEnabled then return end
                
                if (Character and Character:IsDescendantOf(workspace)) and (PrimaryPart and PrimaryPart:IsDescendantOf(Character)) then
                    if PrimaryPart.AssemblyAngularVelocity.Magnitude > 50 or PrimaryPart.AssemblyLinearVelocity.Magnitude > 100 then
                        Detected = true
                        for i,v in ipairs(Character:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                                v.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                v.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                v.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0)
                            end
                        end
                        PrimaryPart.CanCollide = false
                        PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        PrimaryPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0)
                    end
                end
            end)
            
            
            AntiFlingConnections[Player] = {
                CharacterAdded = charAddedConn,
                Heartbeat = heartbeatConn
            }
        end

        for i,v in ipairs(Services.Players:GetPlayers()) do
            if v ~= LocalPlayer then
                PlayerAdded(v)
            end
        end
        
        local playerAddedConn = Services.Players.PlayerAdded:Connect(PlayerAdded)
        AntiFlingConnections.Global = {PlayerAdded = playerAddedConn}
        
    else
        
        for player, connections in pairs(AntiFlingConnections) do
            if player == "Global" then
                if connections.PlayerAdded then
                    connections.PlayerAdded:Disconnect()
                end
            else
                if connections.CharacterAdded then
                    connections.CharacterAdded:Disconnect()
                end
                if connections.Heartbeat then
                    connections.Heartbeat:Disconnect()
                end
            end
        end
        AntiFlingConnections = {}
    end
end)

Button(Tab1, "防甩飞", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ChinaQY/Scripts/Main/AntiFling.lua"))()
end)

Button(Tab1, "可选人甩飞", function() 
    loadstring(game:HttpGet("https://pastefy.app/A8Kfs9KV/raw", true))()
end)

Button(Tab1, "触摸甩飞", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/LiarRise/FLN-X/refs/heads/main/README.md"))()
end)

Button(Tab1, "kenny甩飞", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/DHJB%E7%94%A9%E9%A3%9E.txt"))()
end)

Button(Tab1, "一键甩飞所有人", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/zqyDSUWX"))()
end)

Button(Tab1, "甩飞中心", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/3LD4D0/OP-FLING-GUI/c1fd15bf3114e6c9e4b76951b7d516c123836efe/OP%20FLING%20GUI%20R6%20AND%20R15"))()
end)


Button(Tab1, "电脑键盘", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/advxzivhsjjdhxhsidifvsh/mobkeyboard/main/main.txt", true))()
end)

Button(Tab1, "改fps", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/gclich/FPS-X-GUI/main/FPS_X.lua"))()
end)

Button(Tab1, "反踢出",function()
    local vu = game:GetService("VirtualUser")
            game:GetService("Players").LocalPlayer.Idled:connect(function()
                    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                    wait(1)
                vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            end)
            
end)

Button(Tab1, "fpsBooster(很猛的提升fps)", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/JoshzzAlteregooo/JoshzzFpsBoosterVersion3/refs/heads/main/JoshzzNewFpsBooster"))()
end)

Button(Tab1, "fps显示", function() 
    loadstring(game:HttpGet("https://pastefy.app/d9j82YJr/raw",true))()
end)

Button(Tab1, "自动弹钢琴", function() 
    loadstring(game:HttpGet("https://rawscripts.net/raw/Tac's-Piano-Stuff-Talentless-script-made-by-hellohellohell012321-44088"))()
end)

Button(Tab1, "显示北京时间", function() 
    local LBLG = Instance.new("ScreenGui", getParent)
local LBL = Instance.new("TextLabel", getParent)
local player = game.Players.LocalPlayer

LBLG.Name = "LBLG"
LBLG.Parent = game.CoreGui
LBLG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LBLG.Enabled = true
LBL.Name = "LBL"
LBL.Parent = LBLG
LBL.BackgroundColor3 = Color3.new(0, 3, 1)
LBL.BackgroundTransparency = 1
LBL.BorderColor3 = Color3.new(0, 3, 1)
LBL.Position = UDim2.new(0.75,0,0.010,0)
LBL.Size = UDim2.new(0, 133, 0, 30)
LBL.Font = Enum.Font.GothamSemibold
LBL.Text = "TextLabel"
LBL.TextColor3 = Color3.new(0, 3, 3)
LBL.TextScaled = true
LBL.TextSize = 14
LBL.TextWrapped = true
LBL.Visible = true

local FpsLabel = LBL
local Heartbeat = game:GetService("RunService").Heartbeat
local LastIteration, Start
local FrameUpdateTable = { }

local function HeartbeatUpdate()
  LastIteration = tick()
  for Index = #FrameUpdateTable, 1, -1 do
    FrameUpdateTable[Index + 1] = (FrameUpdateTable[Index] >= LastIteration - 1) and FrameUpdateTable[Index] or nil
  end
  FrameUpdateTable[1] = LastIteration
  local CurrentFPS = (tick() - Start >= 1 and #FrameUpdateTable) or (#FrameUpdateTable / (tick() - Start))
  CurrentFPS = CurrentFPS - CurrentFPS % 1
  FpsLabel.Text = ("当前时间:"..os.date("%H").."时"..os.date("%M").."分"..os.date("%S"))
end
Start = tick()
Heartbeat:Connect(HeartbeatUpdate)
end)

Button(Tab1, "解帧", function() 
    loadstring(game:HttpGet("https://scriptblox.com/raw/Universal-Script-FpsBoost-9260"))()
end)

Button(Tab1, "飞檐走壁", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/zXk4Rq2r"))()
end)

Button(Tab1, "夜视仪", function() 
    _G.OnShop = true
    loadstring(game:HttpGet('https://raw.githubusercontent.com/DeividComSono/Scripts/main/Scanner.lua'))()
end)

Button(Tab1, "反挂机", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/9fFu43FF"))()
end)

Button(Tab1, "转圈", function() 
    loadstring(game:HttpGet('https://pastebin.com/raw/r97d7dS0', true))()
end)

Button(Tab1, "操人脚本", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/bzmhRgKL"))();
end)

Button(Tab1, "甩人", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/zqyDSUWX"))()
end)

Button(Tab1, "替身", function() 
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/SkrillexMe/SkrillexLoader/main/SkrillexLoadMain')))()
end)

Button(Tab1, "爬墙", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/zXk4Rq2r"))()
end)

Button(Tab1, "工具挂", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Bebo-Mods/BeboScripts/main/StandAwekening.lua"))()
end)

Button(Tab1, "铁拳", function() 
    loadstring(game:HttpGet('https://raw.githubusercontent.com/0Ben1/fe/main/obf_rf6iQURzu1fqrytcnLBAvW34C9N55kS9g9G3CKz086rC47M6632sEd4ZZYB0AYgV.lua.txt'))()
end)

Button(Tab1,"↓以下是开发脚本↓",function()
    
end)
    
Button(Tab1, "汉化spy", function() 
    getgenv().Spy="汉化Spy" 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/refs/heads/main/spy%E6%B1%89%E5%8C%96%20(1).txt"))()
end)

Button(Tab1, "Infinite Yield", function() 
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

Button(Tab1, "汉化Dex v3", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Twbtx/tiamxiabuwu/main/txbw%20dex.v3.lua"))()
end)

Button(Tab1, "Dark Dex V3", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua"))()
end)

Button(Tab1, "CMD-X", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source", true))()
end)

Button(Tab1, "动画spy", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E5%8A%A8%E7%94%BBSpy.lua.txt"))()
end)

Button(Tab1, "音频spy", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/Alrthisfordetection.txt"))()
end)

Button(Tab1, "spy合集", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/Simple_Spy_Utility.txt"))()
end)

Button(Tab1, "简洁spy", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/fuckg1thub/RizzSpy/refs/heads/main/alright"))()
end)

Button(Tab1, "小spy", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/EHvjE2sT"))()
end)

Button(Tab1, "贴花spy", function() 
    loadstring(game:HttpGet('https://pastefy.app/gkqzwu88/raw'))()
end)

Button(Tab1, "西格玛spy", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Sigma-Spy/refs/heads/main/Main.lua"))()
end)

Button(Tab1, "汉化dex++", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Twbtx/tiamxiabuwu/main/txbw%20dex%2B%2B%20huan%20huan%20HUN%20NB%21"))()
end)

Button(Tab1, "dex++", function() 
    loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
end)

Button(Tab1, "氯胺酮spy", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/InfernusScripts/Ketamine/refs/heads/main/Ketamine.lua"))()
end)

Button(Tab1, "http嗅探器", function() 
    loadstring(game:HttpGet("https://ripskids.lol/official/HttpSpy/loader.lua"))()
end)

Button(Tab1, "乌托邦spy", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Klinac/scripts/main/utopia_spy.lua", true))()
end)

Button(Tab1, "Cobaltspy", function() 
    loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))()
end)

Button(Tab1, "夜spyv3", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelo17123/NightSpyV3/refs/heads/main/NightSpy%20V4"))()
end)

Button(Tab1, "httpsSPY", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Hm5011/hussain/refs/heads/main/Links%20Spy"))()
end)

Button(Tab1, "Webhook拦截器webhookspy", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/offperms/emplicswebhookspy/main/release"))()
end)

Button(Tab1, "RedCodespy", function() 
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/RedCodeCheat/Roblox/refs/heads/main/RedCode_Remote_Spy.lua')))() 
end)

Button(Tab1, "HTTPspy", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/293jOse0ejd8du/HttpSpy/refs/heads/main/main.lua"))() 
end)

Button(Tab1, "库尔斯克斯RSPY", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nizartitwaniii/Register-Roblox-/refs/heads/main/Protected_2944435597543940.txt"))() 
end)

Button(Tab1, "SpyOS", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/RENBex6969/SpyOS/refs/heads/main/SpyOS_a2.lua"))() 
end)

Button(Tab1, "杰森SPY", function() 
    loadstring(game:HttpGet("https://pastebin.com/raw/wjF5j5YD"))() 
end)

Button(Tab1, "Hydroxide", function() 
    loadstring(game:HttpGet('https://raw.githubusercontent.com/iK4oS/backdoor.exe/v8/src/main.lua'))()
end)

Button(Tab1, "SimpleAdmin", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleAdmin/main/SimpleAdmin.lua"))()
end)

Button(Tab1, "Remote Spy", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/470n1/RemoteSpy/main/Main.lua"))()
end)

Button(Tab1, "Owl Hub", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/CriShoux/OwlHub/master/OwlHub.txt"))()
end)

Button(Tab1, "Fluxus", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/FluxusByte/Fluxus.Public/main/Fluxus"))()
end)

Button(Tab1, "Script Dumper", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/ScriptDumper/main/ScriptDumper.lua"))()
end)

Button(Tab1, "Elysian", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ElysianManager/Elysian/main/Loader.lua"))()
end)

Button(Tab1, "ProtoSmasher Compat", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtoSmasher/Scripts/main/Loader"))()
end)

Button(Tab1, "Anti AFK", function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/FE-AntiAFK/main/src.lua"))()
end)

Button(Tab1, "坐标提取器", function() 
    local ScreenGui = Instance.new("ScreenGui")
    local MainFrame = Instance.new("Frame")
    local TitleBar = Instance.new("Frame")
    local TitleLabel = Instance.new("TextLabel")
    local MinimizeButton = Instance.new("TextButton")
    local CloseButton = Instance.new("TextButton")
    local ContentFrame = Instance.new("Frame")
    local CurrentPosLabel = Instance.new("TextLabel")
    local PosDisplay = Instance.new("TextBox")
    local ButtonsFrame = Instance.new("Frame")
    local RefreshButton = Instance.new("TextButton")
    local CopyButton = Instance.new("TextButton")
    local TeleportFrame = Instance.new("Frame")
    local TeleportLabel = Instance.new("TextLabel")
    local TeleportInput = Instance.new("TextBox")
    local TeleportButton = Instance.new("TextButton")
    local StatusLabel = Instance.new("TextLabel")

    ScreenGui.Name = "CoordinateExtractor"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Active = true

    TitleBar.Name = "TitleBar"
    TitleBar.Parent = MainFrame
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TitleBar.BorderSizePixel = 0
    TitleBar.Size = UDim2.new(1, 0, 0, 40)

    TitleLabel.Name = "TitleLabel"
    TitleLabel.Parent = TitleBar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "坐标提取器 v2.0"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 18

    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Parent = TitleBar
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 150, 200)
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Position = UDim2.new(0.8, 0, 0.1, 0)
    MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Text = "_"
    MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeButton.TextSize = 16

    CloseButton.Name = "CloseButton"
    CloseButton.Parent = TitleBar
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    CloseButton.BorderSizePixel = 0
    CloseButton.Position = UDim2.new(0.9, 0, 0.1, 0)
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 16

    ContentFrame.Name = "ContentFrame"
    ContentFrame.Parent = MainFrame
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 0, 0, 40)
    ContentFrame.Size = UDim2.new(1, 0, 1, -40)

    CurrentPosLabel.Name = "CurrentPosLabel"
    CurrentPosLabel.Parent = ContentFrame
    CurrentPosLabel.BackgroundTransparency = 1
    CurrentPosLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
    CurrentPosLabel.Size = UDim2.new(0.9, 0, 0, 25)
    CurrentPosLabel.Font = Enum.Font.Gotham
    CurrentPosLabel.Text = "当前位置:"
    CurrentPosLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    CurrentPosLabel.TextSize = 16
    CurrentPosLabel.TextXAlignment = Enum.TextXAlignment.Left

    PosDisplay.Name = "PosDisplay"
    PosDisplay.Parent = ContentFrame
    PosDisplay.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    PosDisplay.BorderSizePixel = 0
    PosDisplay.Position = UDim2.new(0.05, 0, 0.15, 0)
    PosDisplay.Size = UDim2.new(0.9, 0, 0, 60)
    PosDisplay.Font = Enum.Font.Gotham
    PosDisplay.PlaceholderText = "点击刷新获取当前位置..."
    PosDisplay.Text = ""
    PosDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
    PosDisplay.TextSize = 14
    PosDisplay.TextWrapped = true
    PosDisplay.TextXAlignment = Enum.TextXAlignment.Left
    PosDisplay.TextYAlignment = Enum.TextYAlignment.Top

    ButtonsFrame.Name = "ButtonsFrame"
    ButtonsFrame.Parent = ContentFrame
    ButtonsFrame.BackgroundTransparency = 1
    ButtonsFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
    ButtonsFrame.Size = UDim2.new(0.9, 0, 0, 40)

    RefreshButton.Name = "RefreshButton"
    RefreshButton.Parent = ButtonsFrame
    RefreshButton.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    RefreshButton.BorderSizePixel = 0
    RefreshButton.Size = UDim2.new(0.48, 0, 1, 0)
    RefreshButton.Font = Enum.Font.GothamBold
    RefreshButton.Text = "刷新位置"
    RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshButton.TextSize = 16

    CopyButton.Name = "CopyButton"
    CopyButton.Parent = ButtonsFrame
    CopyButton.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
    CopyButton.BorderSizePixel = 0
    CopyButton.Position = UDim2.new(0.52, 0, 0, 0)
    CopyButton.Size = UDim2.new(0.48, 0, 1, 0)
    CopyButton.Font = Enum.Font.GothamBold
    CopyButton.Text = "复制坐标"
    CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyButton.TextSize = 16

    TeleportFrame.Name = "TeleportFrame"
    TeleportFrame.Parent = ContentFrame
    TeleportFrame.BackgroundTransparency = 1
    TeleportFrame.Position = UDim2.new(0.05, 0, 0.6, 0)
    TeleportFrame.Size = UDim2.new(0.9, 0, 0, 80)

    TeleportLabel.Name = "TeleportLabel"
    TeleportLabel.Parent = TeleportFrame
    TeleportLabel.BackgroundTransparency = 1
    TeleportLabel.Size = UDim2.new(1, 0, 0, 25)
    TeleportLabel.Font = Enum.Font.Gotham
    TeleportLabel.Text = "输入坐标传送到指定位置 (格式: X,Y,Z):"
    TeleportLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TeleportLabel.TextSize = 14
    TeleportLabel.TextXAlignment = Enum.TextXAlignment.Left

    TeleportInput.Name = "TeleportInput"
    TeleportInput.Parent = TeleportFrame
    TeleportInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TeleportInput.BorderSizePixel = 0
    TeleportInput.Position = UDim2.new(0, 0, 0.3, 0)
    TeleportInput.Size = UDim2.new(0.7, 0, 0, 35)
    TeleportInput.Font = Enum.Font.Gotham
    TeleportInput.PlaceholderText = "例如: 100,50,200"
    TeleportInput.Text = ""
    TeleportInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    TeleportInput.TextSize = 14

    TeleportButton.Name = "TeleportButton"
    TeleportButton.Parent = TeleportFrame
    TeleportButton.BackgroundColor3 = Color3.fromRGB(200, 120, 60)
    TeleportButton.BorderSizePixel = 0
    TeleportButton.Position = UDim2.new(0.72, 0, 0.3, 0)
    TeleportButton.Size = UDim2.new(0.28, 0, 0, 35)
    TeleportButton.Font = Enum.Font.GothamBold
    TeleportButton.Text = "传送"
    TeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    TeleportButton.TextSize = 16

    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = ContentFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0.05, 0, 0.9, 0)
    StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "就绪"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 12
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

    local function updatePosition()
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local position = character.HumanoidRootPart.Position
            PosDisplay.Text = string.format("X: %.2f\nY: %.2f\nZ: %.2f", position.X, position.Y, position.Z)
            StatusLabel.Text = "位置已更新"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            StatusLabel.Text = "错误: 无法找到角色"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end

    local function copyToClipboard()
        if PosDisplay.Text ~= "" then
            setclipboard(PosDisplay.Text)
            StatusLabel.Text = "坐标已复制到剪贴板"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        else
            StatusLabel.Text = "错误: 没有坐标可复制"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end

    local function teleportToPosition()
        local inputText = TeleportInput.Text
        local coords = {}

        for coord in string.gmatch(inputText, "[%d%.%-]+") do
            table.insert(coords, tonumber(coord))
        end

        if #coords == 3 then
            local character = game.Players.LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = CFrame.new(coords[1], coords[2], coords[3])
                StatusLabel.Text = "传送成功"
                StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                updatePosition()
            else
                StatusLabel.Text = "错误: 无法找到角色"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        else
            StatusLabel.Text = "错误: 坐标格式不正确"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end

    local UIS = game:GetService("UserInputService")
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    local isMinimized = false
    local originalSize = MainFrame.Size

    MinimizeButton.MouseButton1Click:Connect(function()
        if isMinimized then
            MainFrame.Size = originalSize
            ContentFrame.Visible = true
            MinimizeButton.Text = "_"
            isMinimized = false
        else
            originalSize = MainFrame.Size
            MainFrame.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 40)
            ContentFrame.Visible = false
            MinimizeButton.Text = "□"
            isMinimized = true
        end
    end)

    RefreshButton.MouseButton1Click:Connect(updatePosition)
    CopyButton.MouseButton1Click:Connect(copyToClipboard)
    TeleportButton.MouseButton1Click:Connect(teleportToPosition)
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    updatePosition()

    TeleportInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            teleportToPosition()
        end
    end)
end)

Button(Tab1, "复制坐标脚本(无法关闭)", function() 
    local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local coordSystem = {
    isEnabled = true,
    gui = nil,
    updateConn = nil,
    currentPos = Vector3.new(0, 0, 0)
}

local function createCoordUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "Coord"
    gui.Parent = player.PlayerGui

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 240, 0, 60)
    container.Position = UDim2.new(1, -250, 0, 10)
    container.BackgroundTransparency = 1
    container.Parent = gui

    local coordFrame = Instance.new("Frame")
    coordFrame.Size = UDim2.new(0, 200, 1, 0)
    coordFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    coordFrame.BackgroundTransparency = 0.7
    coordFrame.BorderSizePixel = 1
    coordFrame.Parent = container

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.Text = "坐标加载别乱动(警告)"
    textLabel.Parent = coordFrame

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 35, 1, 0)
    copyBtn.Position = UDim2.new(0, 205, 0, 0)
    copyBtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    copyBtn.BackgroundTransparency = 0.5
    copyBtn.Text = "复制坐标"
    copyBtn.TextColor3 = Color3.new(1, 1, 1)
    copyBtn.TextSize = 14
    copyBtn.BorderSizePixel = 1
    copyBtn.Parent = container

    copyBtn.MouseButton1Click:Connect(function()
        if setclipboard and coordSystem.currentPos then
            local coordStr = string.format("X: %.2f, Y: %.2f, Z: %.2f",
                coordSystem.currentPos.X,
                coordSystem.currentPos.Y,
                coordSystem.currentPos.Z
            )
            setclipboard(coordStr)
        end
    end)

    local isDragging = false
    local dragStartPos = nil
    local containerStartPos = nil

    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartPos = input.Position
            containerStartPos = container.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStartPos
            container.Position = UDim2.new(
                containerStartPos.X.Scale,
                containerStartPos.X.Offset + delta.X,
                containerStartPos.Y.Scale,
                containerStartPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and isDragging then
            isDragging = false
        end
    end)

    return { gui = gui, container = container, text = textLabel }
end

coordSystem.gui = createCoordUI()

local function formatCoord(pos)
    return string.format("X: %.2f\nY: %.2f\nZ: %.2f", pos.X, pos.Y, pos.Z)
end

local function updateCoord()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        coordSystem.currentPos = root.Position
        coordSystem.gui.text.Text = formatCoord(root.Position)
    else
        coordSystem.gui.text.Text = "混nb"
        coordSystem.currentPos = nil
    end
end

coordSystem.updateConn = RunService.Heartbeat:Connect(updateCoord)
updateCoord()

game:GetService("Players").LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
    if child == coordSystem.gui then
        if coordSystem.updateConn then
            coordSystem.updateConn:Disconnect()
        end
    end
end)

end)