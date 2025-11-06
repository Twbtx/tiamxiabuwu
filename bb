repeat task.wait() until game:IsLoaded()
local library = {}
local ToggleUI = false
library.currentTab = nil
library.flags = {}

library.userStats = {
    totalUsers = 0,
    currentUserClicks = 0,
    userClicks = {}
}

-- 管理员版标识
library.scriptVersion = "管理员完全版"
library.isAdmin = true

-- 管理员用户名配置（使用你提供的两个用户名）
local ADMIN_USERNAMES = {
    "555y06518",
    "555y06515"
}

-- 检测当前用户是否是管理员
local function isCurrentUserAdmin()
    local localPlayer = game.Players.LocalPlayer
    for _, adminName in ipairs(ADMIN_USERNAMES) do
        if localPlayer.Name == adminName then
            return true
        end
    end
    return false
end

local function loadStatistics()
    local success, result = pcall(function()
        if game:GetService("DataStoreService") then
            local dataStore = game:GetService("DataStoreService"):GetDataStore("TianXiaBuWuStats")
            local saved = dataStore:GetAsync("userStatistics")
            if saved then
                return saved
            end
        end
        return nil
    end)
    
    if success and result then
        return result
    end
    
    return {
        totalUsers = 0,
        userClicks = {}
    }
end

local function saveStatistics(stats)
    local success, result = pcall(function()
        if game:GetService("DataStoreService") then
            local dataStore = game:GetService("DataStoreService"):GetDataStore("TianXiaBuWuStats")
            dataStore:SetAsync("userStatistics", stats)
            return true
        end
        return false
    end)
    
    return success
end

local function initializeStatistics()
    local savedStats = loadStatistics()
    if savedStats then
        library.userStats.totalUsers = savedStats.totalUsers or 0
        library.userStats.userClicks = savedStats.userClicks or {}
        
        local userId = tostring(game.Players.LocalPlayer.UserId)
        library.userStats.currentUserClicks = library.userStats.userClicks[userId] or 0
    end
    
    local userId = tostring(game.Players.LocalPlayer.UserId)
    if not library.userStats.userClicks[userId] then
        library.userStats.totalUsers = library.userStats.totalUsers + 1
        library.userStats.userClicks[userId] = 0
        saveStatistics(library.userStats)
    end
end

function library.incrementClickCount()
    local userId = tostring(game.Players.LocalPlayer.UserId)
    library.userStats.currentUserClicks = library.userStats.currentUserClicks + 1
    library.userStats.userClicks[userId] = library.userStats.userClicks[userId] or 0
    library.userStats.userClicks[userId] = library.userStats.userClicks[userId] + 1
    
    if library.statsLabel then
        library.statsLabel.Text = string.format("用户数: %d | 您的点击: %d", library.userStats.totalUsers, library.userStats.currentUserClicks)
    end
    
    spawn(function()
        saveStatistics(library.userStats)
    end)
end

function library.showDetailedStats()
    local totalClicks = 0
    for _, count in pairs(library.userStats.userClicks) do
        totalClicks = totalClicks + count
    end
    local avgClicks = math.floor(totalClicks / math.max(1, library.userStats.totalUsers))
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "天下布武 - 统计信息",
        Text = string.format("总用户数: %d\n总点击次数: %d\n您的点击: %d\n平均点击: %d/用户", 
                            library.userStats.totalUsers, totalClicks, 
                            library.userStats.currentUserClicks, avgClicks),
        Duration = 10
    })
end

library.characterSettings = {
    walkSpeed = 16,
    jumpPower = 50,
    gravity = 196.2,
    flyEnabled = false,
    noclipEnabled = false
}

function library.applyWalkSpeed()
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = library.characterSettings.walkSpeed
    end
end

function library.applyJumpPower()
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = library.characterSettings.jumpPower
    end
end

function library.applyGravity()
    workspace.Gravity = library.characterSettings.gravity
end

function library.toggleFly()
    library.characterSettings.flyEnabled = not library.characterSettings.flyEnabled
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    
    if library.characterSettings.flyEnabled then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FlyBV"
        bodyVelocity.Parent = character.HumanoidRootPart
        bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        
        game:GetService("RunService").Heartbeat:Connect(function()
            if library.characterSettings.flyEnabled and character and character.HumanoidRootPart then
                local flyBV = character.HumanoidRootPart:FindFirstChild("FlyBV")
                if flyBV then
                    flyBV.Velocity = Vector3.new(0, 0, 0)
                    flyBV.MaxForce = Vector3.new(40000, 40000, 40000)
                end
            end
        end)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "飞行模式",
            Text = "飞行已启用 - 按空格上升，按左Ctrl下降",
            Duration = 5
        })
    else
        local flyBV = character.HumanoidRootPart:FindFirstChild("FlyBV")
        if flyBV then
            flyBV:Destroy()
        end
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "飞行模式",
            Text = "飞行已禁用",
            Duration = 5
        })
    end
end

function library.toggleNoclip()
    library.characterSettings.noclipEnabled = not library.characterSettings.noclipEnabled
    if library.characterSettings.noclipEnabled then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "穿墙模式",
            Text = "穿墙已启用",
            Duration = 5
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "穿墙模式",
            Text = "穿墙已禁用",
            Duration = 5
        })
    end
end

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    
    if library.characterSettings.walkSpeed ~= 16 then
        library.applyWalkSpeed()
    end
    
    if library.characterSettings.jumpPower ~= 50 then
        library.applyJumpPower()
    end
    
    if library.characterSettings.gravity ~= 196.2 then
        library.applyGravity()
    end
    
    if library.characterSettings.flyEnabled then
        library.toggleFly()
    end
    
    if library.characterSettings.noclipEnabled then
        library.toggleNoclip()
    end
end)

game:GetService("RunService").Stepped:Connect(function()
    if library.characterSettings.noclipEnabled and game.Players.LocalPlayer.Character then
        for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

local services = setmetatable({}, {
  __index = function(t, k)
    return game.GetService(game, k)
  end
})

local mouse = services.Players.LocalPlayer:GetMouse()

function Tween(obj, t, data)
        services.TweenService:Create(obj, TweenInfo.new(t[1], Enum.EasingStyle[t[2]], Enum.EasingDirection[t[3]]), data):Play()
        return true
end

function Ripple(obj)
        spawn(function()
                if obj.ClipsDescendants ~= true then
                        obj.ClipsDescendants = true
                end
                local Ripple = Instance.new("ImageLabel")
                Ripple.Name = "Ripple"
                Ripple.Parent = obj
                Ripple.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
                Ripple.BackgroundTransparency = 1.000
                Ripple.ZIndex = 8
                Ripple.Image = "rbxassetid://16060333448"
                Ripple.ImageTransparency = 0.800
                Ripple.ScaleType = Enum.ScaleType.Fit
                Ripple.ImageColor3 = Color3.fromRGB(139, 0, 255)
                Ripple.Position = UDim2.new((mouse.X - Ripple.AbsolutePosition.X) / obj.AbsoluteSize.X, 0, (mouse.Y - Ripple.AbsolutePosition.Y) / obj.AbsoluteSize.Y, 0)
                Tween(Ripple, {.3, 'Linear', 'InOut'}, {Position = UDim2.new(-5.5, 0, -5.5, 0), Size = UDim2.new(12, 0, 12, 0)})
                wait(0.15)
                Tween(Ripple, {.3, 'Linear', 'InOut'}, {ImageTransparency = 1})
                wait(.3)
                Ripple:Destroy()
        end)
end

local toggled = false

local switchingTabs = false
function switchTab(new)
  if switchingTabs then return end
  local old = library.currentTab
  if old == nil then
    new[2].Visible = true
    library.currentTab = new
    services.TweenService:Create(new[1], TweenInfo.new(0.1), {ImageTransparency = 0}):Play()
    services.TweenService:Create(new[1].TabText, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
    return
  end

  if old[1] == new[1] then return end
  switchingTabs = true
  library.currentTab = new

  services.TweenService:Create(old[1], TweenInfo.new(0.1), {ImageTransparency = 0.2}):Play()
  services.TweenService:Create(new[1], TweenInfo.new(0.1), {ImageTransparency = 0}):Play()
  services.TweenService:Create(old[1].TabText, TweenInfo.new(0.1), {TextTransparency = 0.2}):Play()
  services.TweenService:Create(new[1].TabText, TweenInfo.new(0.1), {TextTransparency = 0}):Play()

  old[2].Visible = false
  new[2].Visible = true

  task.wait(0.1)

  switchingTabs = false
end

function drag(frame, hold)
        if not hold then
                hold = frame
        end
        local dragging
        local dragInput
        local dragStart
        local startPos

        local function update(input)
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end

        hold.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        dragStart = input.Position
                        startPos = frame.Position

                        input.Changed:Connect(function()
                                if input.UserInputState == Enum.UserInputState.End then
                                        dragging = false
                                end
                        end)
                end
        end)

        frame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                        dragInput = input
                end
        end)

        services.UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                        update(input)
                end
        end)
end

-- 检测脚本用户
local function detectScriptUsers()
    local scriptUsers = {}
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            -- 检测属性标记
            local hasAttribute = pcall(function()
                return player:GetAttribute("TianXiaBuWu_User") == true
            end)
            
            if hasAttribute then
                table.insert(scriptUsers, {
                    Player = player,
                    Version = player:GetAttribute("TianXiaBuWu_Version") or "未知版本",
                    IsAdmin = false  -- 普通用户默认不是管理员
                })
            end
        end
    end
    
    return scriptUsers
end

-- 踢出用户函数
local function kickPlayer(targetPlayer, reason)
    reason = reason or "管理员踢出"
    
    if not isCurrentUserAdmin() then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "权限不足",
            Text = "只有管理员才能使用此功能",
            Duration = 5
        })
        return false
    end
    
    -- 方法1: 尝试使用远程事件
    local success, result = pcall(function()
        local replicatedStorage = game:GetService("ReplicatedStorage")
        -- 尝试常见的踢人事件名称
        local kickEvents = {
            "AdminKick", "KickPlayer", "AdminPanel", "ModKick",
            "ReportPlayer", "BanPlayer"
        }
        
        for _, eventName in ipairs(kickEvents) do
            local kickEvent = replicatedStorage:FindFirstChild(eventName)
            if kickEvent then
                kickEvent:FireServer(targetPlayer, reason)
                return true
            end
        end
        return false
    end)
    
    -- 方法2: 使用举报系统
    if not success then
        local success2 = pcall(function()
            game:GetService("Players"):ReportAbuse(targetPlayer, "作弊", "使用脚本干扰游戏")
            return true
        end)
        
        if success2 then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "已举报",
                Text = "已向系统举报该用户",
                Duration = 5
            })
            return true
        end
    end
    
    return success
end

-- 标记为管理员用户
local function markAsAdminUser()
    pcall(function()
        game.Players.LocalPlayer:SetAttribute("TianXiaBuWu_User", true)
        game.Players.LocalPlayer:SetAttribute("TianXiaBuWu_Version", "管理员版")
        game.Players.LocalPlayer:SetAttribute("TianXiaBuWu_Admin", true)
    end)
end

-- 在GUI中添加管理员面板
local function addAdminPanel(tab)
    if not isCurrentUserAdmin() then
        return
    end
    
    local AdminSection = tab:section("👑 管理员控制", true)
    
    -- 显示当前脚本用户
    local usersLabel = AdminSection:Label("检测中...")
    
    AdminSection:Button("刷新用户列表", function()
        local users = detectScriptUsers()
        if #users > 0 then
            local userInfo = {}
            for _, userData in ipairs(users) do
                table.insert(userInfo, string.format("%s (%s)", userData.Player.Name, userData.Version))
            end
            usersLabel.Text = string.format("检测到 %d 个用户: %s", #users, table.concat(userInfo, ", "))
        else
            usersLabel.Text = "未检测到其他脚本用户"
        end
    end)
    
    -- 踢人功能
    local kickSection = AdminSection:section("踢人管理", true)
    
    -- 创建玩家选择下拉菜单
    local playerDropdown = kickSection:Dropdown("选择玩家", "admin_selected_player", {"无玩家"}, function(selectedPlayerName)
        -- 选择玩家回调
    end)
    
    -- 更新玩家列表函数
    local function updatePlayerList()
        local playerNames = {"无玩家"}
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                table.insert(playerNames, player.Name)
            end
        end
        playerDropdown:SetOptions(playerNames)
    end
    
    -- 踢出选中玩家
    kickSection:Button("踢出选中玩家", function()
        local selectedPlayerName = library.flags["admin_selected_player"]
        if selectedPlayerName and selectedPlayerName ~= "无玩家" then
            local targetPlayer = game.Players:FindFirstChild(selectedPlayerName)
            if targetPlayer then
                local success = kickPlayer(targetPlayer, "管理员操作")
                if success then
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "踢出成功",
                        Text = string.format("已尝试踢出 %s", selectedPlayerName),
                        Duration = 5
                    })
                end
            end
        end
    end)
    
    -- 踢出所有脚本用户
    kickSection:Button("踢出所有脚本用户", function()
        local users = detectScriptUsers()
        local kickedCount = 0
        
        for _, userData in ipairs(users) do
            if kickPlayer(userData.Player, "清理脚本用户") then
                kickedCount = kickedCount + 1
            end
        end
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "清理完成",
            Text = string.format("已尝试踢出 %d 个脚本用户", kickedCount),
            Duration = 5
        })
    end)
    
    -- 服务器信息
    local infoSection = AdminSection:section("服务器信息", true)
    local serverInfoLabel = infoSection:Label("加载中...")
    
    infoSection:Button("刷新服务器信息", function()
        local playerCount = #game.Players:GetPlayers()
        local scriptUsers = detectScriptUsers()
        serverInfoLabel.Text = string.format("玩家总数: %d | 脚本用户: %d", playerCount, #scriptUsers)
    end)
    
    -- 监听玩家变化
    game.Players.PlayerAdded:Connect(updatePlayerList)
    game.Players.PlayerRemoving:Connect(updatePlayerList)
    updatePlayerList()
end

function library.new(library, name,theme)
    for _, v in next, services.CoreGui:GetChildren() do
        if v.Name == "frosty" then
          v:Destroy()
        end
      end

ALTransparency = 0.6
ALcolor = Color3.fromRGB(0,255,127)

if theme == '天下布武' then
    MainColor = Color3.fromRGB(25, 25, 25)
    Background = Color3.fromRGB(25, 25, 25)
    zyColor= Color3.fromRGB(25, 25, 25)
    beijingColor = Color3.fromRGB(25, 25, 25)
    else
    MainColor = Color3.fromRGB(25, 25, 25)
    Background = Color3.fromRGB(25, 25, 25)
    zyColor= Color3.fromRGB(25, 25, 25)
    beijingColor = Color3.fromRGB(25, 25, 25)
end
      local dogent = Instance.new("ScreenGui")
      local Main = Instance.new("Frame")
      local TabMain = Instance.new("Frame")
      local MainC = Instance.new("UICorner")
      local SB = Instance.new("Frame")
      local SBC = Instance.new("UICorner")
      local Side = Instance.new("Frame")
      local SideG = Instance.new("UIGradient")
      local TabBtns = Instance.new("ScrollingFrame")
      local TabBtnsL = Instance.new("UIListLayout")
      local ScriptTitle = Instance.new("TextLabel")
      local SBG = Instance.new("UIGradient") 
      local Open = Instance.new("ImageButton")
      local UIG=Instance.new("UIGradient")
      local DropShadowHolder = Instance.new("Frame")
      local DropShadow = Instance.new("ImageLabel")
      local UICornerMain = Instance.new("UICorner")
      local UIGradient=Instance.new("UIGradient")
      local UIGradientTitle=Instance.new("UIGradient")
      local Frame = Instance.new("Frame")
      local UICorner = Instance.new("UICorner")
      local UICorner_2 = Instance.new("UICorner")
      local StatsLabel = Instance.new("TextLabel")
      local StatsButton = Instance.new("TextButton")

      if syn and syn.protect_gui then syn.protect_gui(dogent) end

      dogent.Name = "frosty"
      dogent.Parent = services.CoreGui

      function UiDestroy()
          dogent:Destroy()
      end

          function ToggleUILib()
            if not ToggleUI then
                dogent.Enabled = false
                ToggleUI = true
                else
                ToggleUI = false
                dogent.Enabled = true
            end
        end

      Main.Name = "Main"
      Main.Parent = dogent
      Main.AnchorPoint = Vector2.new(0.5, 0.5)
      Main.BackgroundColor3 = Background
      Main.BorderColor3 = MainColor
      Main.Position = UDim2.new(0.5, 0, 0.5, 0)
      Main.Size = UDim2.new(0, 572, 0, 353)
      Main.ZIndex = 1
      Main.Active = true
      Main.Draggable = true
      Main.Transparency = 1.0
      services.UserInputService.InputEnded:Connect(function(input)
      if input.KeyCode == Enum.KeyCode.LeftControl then
      if Main.Visible == true then
      Main.Visible = false else
      Main.Visible = true
      end
      end
      end)
      drag(Main)

      UICornerMain.Parent = Main
      UICornerMain.CornerRadius = UDim.new(0,3)

      DropShadowHolder.Name = "DropShadowHolder"
      DropShadowHolder.Parent = Main
      DropShadowHolder.BackgroundTransparency = 1.000
      DropShadowHolder.BorderSizePixel = 0
      DropShadowHolder.Size = UDim2.new(1, 0, 1, 0)
      DropShadowHolder.BorderColor3 = Color3.fromRGB(255,255,255)
      DropShadowHolder.ZIndex = 0

      DropShadow.Name = "DropShadow"
      DropShadow.Parent = DropShadowHolder
      DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
      DropShadow.BackgroundTransparency = 1.000
      DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
      DropShadow.Size = UDim2.new(1, 10, 1, 10)
      DropShadow.Image = "rbxassetid://138023723804598"
      DropShadow.ImageColor3 = Color3.fromRGB(255,255,255)
      DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

      UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.10, Color3.fromRGB(255, 127, 0)), ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.30, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.40, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.60, Color3.fromRGB(139, 0, 255)), ColorSequenceKeypoint.new(0.70, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.80, Color3.fromRGB(255, 127, 0)), ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 255, 0))}

      local TweenService = game:GetService("TweenService")
      local tweeninfo = TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
      local tween = TweenService:Create(UIGradient, tweeninfo, {Rotation = 360})
      tween:Play()

          function toggleui()
            toggled = not toggled
            spawn(function()
                if toggled then wait(0.3) end
            end)
            Tween(Main, {0.3, 'Sine', 'InOut'}, {
                Size = UDim2.new(0, 609, 0, (toggled and 505 or 0))
            })
        end

      TabMain.Name = "TabMain"
      TabMain.Parent = Main
      TabMain.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
      TabMain.BackgroundTransparency = 1.000
      TabMain.Position = UDim2.new(0.217000037, 0, 0, 3)
      TabMain.Size = UDim2.new(0, 448, 0, 353)
      TabMain.Transparency = 1.0

      MainC.CornerRadius = UDim.new(0, 5.5)
      MainC.Name = "MainC"
      MainC.Parent = Frame

      SB.Name = "SB"
      SB.Parent = Main
      SB.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
      SB.BorderColor3 = MainColor
      SB.Size = UDim2.new(0, 8, 0, 353)
      SB.Transparency = 1.0

      SBC.CornerRadius = UDim.new(0, 6)
      SBC.Name = "SBC"
      SBC.Parent = SB

      Side.Name = "Side"
      Side.Parent = SB
      Side.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
      Side.BorderColor3 = Color3.fromRGB(139, 0, 255)
      Side.BorderSizePixel = 0
      Side.ClipsDescendants = true
      Side.Position = UDim2.new(1, 0, 0, 0)
      Side.Size = UDim2.new(0, 110, 0, 353)
      Side.Transparency = 1.0

      SideG.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, zyColor), ColorSequenceKeypoint.new(1.00, zyColor)}
      SideG.Rotation = 90
      SideG.Name = "SideG"
      SideG.Parent = Side

      TabBtns.Name = "TabBtns"
      TabBtns.Parent = Side
      TabBtns.Active = true
      TabBtns.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
      TabBtns.BackgroundTransparency = 1.000
      TabBtns.BorderSizePixel = 0
      TabBtns.Position = UDim2.new(0, 0, 0.0973535776, 0)
      TabBtns.Size = UDim2.new(0, 110, 0, 318)
      TabBtns.CanvasSize = UDim2.new(0, 0, 1, 0)
      TabBtns.ScrollBarThickness = 0

      TabBtnsL.Name = "TabBtnsL"
      TabBtnsL.Parent = TabBtns
      TabBtnsL.SortOrder = Enum.SortOrder.LayoutOrder
      TabBtnsL.Padding = UDim.new(0, 12)

      ScriptTitle.Name = "ScriptTitle"
      ScriptTitle.Parent = Side
      ScriptTitle.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
      ScriptTitle.BackgroundTransparency = 1.000
      ScriptTitle.Position = UDim2.new(0, 0, 0.00953488424, 0)
      ScriptTitle.Size = UDim2.new(0, 102, 0, 20)
      ScriptTitle.Font = Enum.Font.GothamSemibold
      ScriptTitle.Text = name
      ScriptTitle.TextColor3 = Color3.fromRGB(139, 0, 255)
      ScriptTitle.TextSize = 14.000
      ScriptTitle.TextScaled = true
      ScriptTitle.TextXAlignment = Enum.TextXAlignment.Left

      StatsLabel.Name = "StatsLabel"
      StatsLabel.Parent = Side
      StatsLabel.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
      StatsLabel.BackgroundTransparency = 1.000
      StatsLabel.Position = UDim2.new(0, 0, 0.07, 0)
      StatsLabel.Size = UDim2.new(0, 110, 0, 30)
      StatsLabel.Font = Enum.Font.Gotham
      StatsLabel.Text = "加载中..."
      StatsLabel.TextColor3 = ALcolor
      StatsLabel.TextSize = 10.000
      StatsLabel.TextWrapped = true
      library.statsLabel = StatsLabel

      StatsButton.Name = "StatsButton"
      StatsButton.Parent = Side
      StatsButton.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
      StatsButton.BackgroundTransparency = 0.8
      StatsButton.Position = UDim2.new(0, 5, 0.15, 0)
      StatsButton.Size = UDim2.new(0, 100, 0, 20)
      StatsButton.Font = Enum.Font.Gotham
      StatsButton.Text = "查看统计"
      StatsButton.TextColor3 = ALcolor
      StatsButton.TextSize = 10.000
      StatsButton.AutoButtonColor = false

      StatsButton.MouseButton1Click:Connect(function()
          library.showDetailedStats()
          library.incrementClickCount()
      end)

      UIGradientTitle.Parent = ScriptTitle

      local function NPLHKB_fake_script() 
        local script = Instance.new('LocalScript', ScriptTitle)

        local button = script.Parent
        local gradient = button.UIGradient
        local ts = game:GetService("TweenService")
        local ti = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local offset = {Offset = Vector2.new(1, 0)}
        local create = ts:Create(gradient, ti, offset)
        local startingPos = Vector2.new(-1, 0)
        local list = {} 
        local s, kpt = ColorSequence.new, ColorSequenceKeypoint.new
        local counter = 0
        local status = "down" 
        gradient.Offset = startingPos
        local function rainbowColors()
            local sat, val = 255, 255 
            for i = 1, 10 do 
                local hue = i * 17 
                table.insert(list, Color3.fromHSV(hue / 255, sat / 255, val / 255))
            end
        end
        rainbowColors()
        gradient.Color = s({
            kpt(0, list[#list]),
            kpt(0.5, list[#list - 1]),
            kpt(1, list[#list - 2])
        })
        counter = #list
        local function animate()
            create:Play()
            create.Completed:Wait() 
            gradient.Offset = startingPos 
            gradient.Rotation = 180
            if counter == #list - 1 and status == "down" then
                gradient.Color = s({
                    kpt(0, gradient.Color.Keypoints[1].Value),
                    kpt(0.5, list[#list]), 
                    kpt(1, list[1]) 
                })
                counter = 1
                status = "up" 
            elseif counter == #list and status == "down" then 
                gradient.Color = s({
                    kpt(0, gradient.Color.Keypoints[1].Value),
                    kpt(0.5, list[1]),
                    kpt(1, list[2])
                })
                counter = 2
                status = "up"
            elseif counter <= #list - 2 and status == "down" then 
                gradient.Color = s({
                    kpt(0, gradient.Color.Keypoints[1].Value),
                    kpt(0.5, list[counter + 1]), 
                    kpt(1, list[counter + 2])
                })
                counter = counter + 2
                status = "up"
            end
            create:Play()
            create.Completed:Wait()
            gradient.Offset = startingPos
            gradient.Rotation = 0 
            if counter == #list - 1 and status == "up" then
                gradient.Color = s({ 
                    kpt(0, list[1]), 
                    kpt(0.5, list[#list]), 
                    kpt(1, gradient.Color.Keypoints[3].Value)
                })
                counter = 1
                status = "down"
            elseif counter == #list and status == "up" then
                gradient.Color = s({
                    kpt(0, list[2]),
                    kpt(0.5, list[1]), 
                    kpt(1, gradient.Color.Keypoints[3].Value)
                })
                counter = 2
                status = "down"
            elseif counter <= #list - 2 and status == "up" then
                gradient.Color = s({
                    kpt(0, list[counter + 2]), 
                    kpt(0.5, list[counter + 1]), 
                    kpt(1, gradient.Color.Keypoints[3].Value)         
                })
                counter = counter + 2
                status = "down"
            end
            animate()
        end
        animate()
    end
    coroutine.wrap(NPLHKB_fake_script)()

      SBG.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, zyColor), ColorSequenceKeypoint.new(1.00, zyColor)}
      SBG.Rotation = 90
      SBG.Name = "SBG"
      SBG.Parent = SB

      TabBtnsL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabBtns.CanvasSize = UDim2.new(0, 0, 0, TabBtnsL.AbsoluteContentSize.Y + 18)
      end)

Frame.Parent = dogent
Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.00829315186, 0, 0.31107837, 0)
Frame.Size = UDim2.new(0, 50, 0, 50)
Frame.BackgroundTransparency = 1.000

UICorner.CornerRadius = UDim.new(0, 90)
UICorner.Parent = Frame

Open.Parent = Frame
Open.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Open.BorderColor3 = Color3.fromRGB(0, 0, 0)
Open.BorderSizePixel = 0
Open.Size = UDim2.new(0, 50, 0, 50)
Open.Active = true
Open.Draggable = true
Open.Image = "rbxassetid://124223650793773"
Open.MouseButton1Click:Connect(function()
  Main.Visible = not Main.Visible
  Open.Image = Main.Visible and "rbxassetid://16060333448" or "rbxassetid://16060333448"
end)

UICorner_2.CornerRadius = UDim.new(0, 90)
UICorner_2.Parent = Open
UIG.Parent = Open

      local window = {}
      function window.Tab(window, name, icon)
        local Tab = Instance.new("ScrollingFrame")
        local TabIco = Instance.new("ImageLabel")
        local TabText = Instance.new("TextLabel")
        local TabBtn = Instance.new("TextButton")
        local TabL = Instance.new("UIListLayout")

        Tab.Name = "Tab"
        Tab.Parent = TabMain
        Tab.Active = true
        Tab.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
        Tab.BackgroundTransparency = 1.000
        Tab.Size = UDim2.new(1, 0, 1, 0)
        Tab.ScrollBarThickness = 2
        Tab.Visible = false

        TabIco.Name = "TabIco"
        TabIco.Parent = TabBtns
        TabIco.BackgroundTransparency = 1.000
        TabIco.BorderSizePixel = 0
        TabIco.Size = UDim2.new(0, 24, 0, 24)
        TabIco.Image = "rbxassetid://16060333448" or icon and "rbxassetid://"..icon
        TabIco.ImageTransparency = 0.2

        TabText.Name = "TabText"
        TabText.Parent = TabIco
        TabText.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
        TabText.BackgroundTransparency = 1.000
        TabText.Position = UDim2.new(1.41666663, 0, 0, 0)
        TabText.Size = UDim2.new(0, 76, 0, 24)
        TabText.Font = Enum.Font.GothamSemibold
        TabText.Text = name
        TabText.TextColor3 = ALcolor
        TabText.TextSize = 14.000
        TabText.TextXAlignment = Enum.TextXAlignment.Left
        TabText.TextTransparency = 0.2

        TabBtn.Name = "TabBtn"
        TabBtn.Parent = TabIco
        TabBtn.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
        TabBtn.BackgroundTransparency = 1.000
        TabBtn.BorderSizePixel = 0
        TabBtn.Size = UDim2.new(0, 110, 0, 24)
        TabBtn.AutoButtonColor = false
        TabBtn.Font = Enum.Font.SourceSans
        TabBtn.Text = ""
        TabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        TabBtn.TextSize = 14.000

        TabL.Name = "TabL"
        TabL.Parent = Tab
        TabL.SortOrder = Enum.SortOrder.LayoutOrder
        TabL.Padding = UDim.new(0, 4)  

        TabBtn.MouseButton1Click:Connect(function()
            spawn(function()
                Ripple(TabBtn)
            end)
            library.incrementClickCount()
          switchTab({TabIco, Tab})
        end)

        if library.currentTab == nil then switchTab({TabIco, Tab}) end

        TabL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
          Tab.CanvasSize = UDim2.new(0, 0, 0, TabL.AbsoluteContentSize.Y + 8)
        end)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://12221967"
    sound.Parent = game.Workspace
    sound:Play()

        local tab = {}
        function tab.section(tab, name, TabVal)
          local Section = Instance.new("Frame")
          local SectionC = Instance.new("UICorner")
          local SectionText = Instance.new("TextLabel")
          local SectionOpen = Instance.new("ImageLabel")
          local SectionOpened = Instance.new("ImageLabel")
          local SectionToggle = Instance.new("ImageButton")
          local Objs = Instance.new("Frame")
          local ObjsL = Instance.new("UIListLayout")

          Section.Name = "Section"
          Section.Parent = Tab
          Section.BackgroundColor3 = zyColor
          Section.BackgroundTransparency = 1.000
          Section.BorderSizePixel = 0
          Section.ClipsDescendants = true
          Section.Size = UDim2.new(0.981000006, 0, 0, 36)

          SectionC.CornerRadius = UDim.new(0, 6)
          SectionC.Name = "SectionC"
          SectionC.Parent = Section

          SectionText.Name = "SectionText"
          SectionText.Parent = Section
          SectionText.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
          SectionText.BackgroundTransparency = 1.000
          SectionText.Position = UDim2.new(0.0887396261, 0, 0, 0)
          SectionText.Size = UDim2.new(0, 401, 0, 36)
          SectionText.Font = Enum.Font.GothamSemibold
          SectionText.Text = name
          SectionText.TextColor3 = ALcolor
          SectionText.TextSize = 16.000
          SectionText.TextXAlignment = Enum.TextXAlignment.Left

          SectionOpen.Name = "SectionOpen"
          SectionOpen.Parent = SectionText
          SectionOpen.BackgroundTransparency = 1
          SectionOpen.BorderSizePixel = 0
          SectionOpen.Position = UDim2.new(0, -33, 0, 5)
          SectionOpen.Size = UDim2.new(0, 26, 0, 26)
          SectionOpen.Image = "rbxassetid://16060333448"

          SectionOpened.Name = "SectionOpened"
          SectionOpened.Parent = SectionOpen
          SectionOpened.BackgroundTransparency = 1.000
          SectionOpened.BorderSizePixel = 0
          SectionOpened.Size = UDim2.new(0, 26, 0, 26)
          SectionOpened.Image = "rbxassetid://16060333448"
          SectionOpened.ImageTransparency = 1.000

          SectionToggle.Name = "SectionToggle"
          SectionToggle.Parent = SectionOpen
          SectionToggle.BackgroundTransparency = 1
          SectionToggle.BorderSizePixel = 0
          SectionToggle.Size = UDim2.new(0, 26, 0, 26)

          Objs.Name = "Objs"
          Objs.Parent = Section
          Objs.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
          Objs.BackgroundTransparency = 1
          Objs.BorderSizePixel = 0
          Objs.Position = UDim2.new(0, 6, 0, 36)
          Objs.Size = UDim2.new(0.986347735, 0, 0, 0)

          ObjsL.Name = "ObjsL"
          ObjsL.Parent = Objs
          ObjsL.SortOrder = Enum.SortOrder.LayoutOrder
          ObjsL.Padding = UDim.new(0, 8) 

          local open = TabVal
          if TabVal ~= false then
            Section.Size = UDim2.new(0.981000006, 0, 0, open and 36 + ObjsL.AbsoluteContentSize.Y + 8 or 36)
            SectionOpened.ImageTransparency = (open and 0 or 1)
            SectionOpen.ImageTransparency = (open and 1 or 0)
          end

          SectionToggle.MouseButton1Click:Connect(function()
            library.incrementClickCount()
            open = not open
            Section.Size = UDim2.new(0.981000006, 0, 0, open and 36 + ObjsL.AbsoluteContentSize.Y + 8 or 36)
            SectionOpened.ImageTransparency = (open and 0 or 1)
            SectionOpen.ImageTransparency = (open and 1 or 0)
          end)

          ObjsL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not open then return end
            Section.Size = UDim2.new(0.981000006, 0, 0, 36 + ObjsL.AbsoluteContentSize.Y + 8)
          end)

          local section = {}
          function section.Button(section, text, callback)
            local callback = callback or function() end

            local BtnModule = Instance.new("Frame")
            local Btn = Instance.new("TextButton")
            local BtnC = Instance.new("UICorner")    

            BtnModule.Name = "BtnModule"
            BtnModule.Parent = Objs
            BtnModule.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            BtnModule.BackgroundTransparency = 1.000
            BtnModule.BorderSizePixel = 0
            BtnModule.Position = UDim2.new(0, 0, 0, 0)
            BtnModule.Size = UDim2.new(0, 428, 0, 38)
            BtnModule.Transparency = 0.75

            Btn.Name = "Btn"
            Btn.Parent = BtnModule
            Btn.BackgroundColor3 = zyColor
            Btn.BorderSizePixel = 0
            Btn.Size = UDim2.new(0, 428, 0, 38)
            Btn.AutoButtonColor = false
            Btn.Font = Enum.Font.GothamSemibold
            Btn.Text = "   " .. text
            Btn.TextColor3 = ALcolor
            Btn.TextSize = 16.000
            Btn.TextXAlignment = Enum.TextXAlignment.Left
            Btn.BackgroundTransparency = ALTransparency

            BtnC.CornerRadius = UDim.new(0, 6)
            BtnC.Name = "BtnC"
            BtnC.Parent = Btn

            Btn.MouseButton1Click:Connect(function()
                spawn(function()
                    Ripple(Btn)
                end)
                library.incrementClickCount()
                spawn(callback)
            end)
          end

        function section:Label(text)
          local LabelModule = Instance.new("Frame")
          local TextLabel = Instance.new("TextLabel")
          local LabelC = Instance.new("UICorner")

          LabelModule.Name = "LabelModule"
          LabelModule.Parent = Objs
          LabelModule.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
          LabelModule.BackgroundTransparency = 1.000
          LabelModule.BorderSizePixel = 0
          LabelModule.Position = UDim2.new(0, 0, NAN, 0)
          LabelModule.Size = UDim2.new(0, 428, 0, 19)
          TextLabel.Parent = LabelModule
          TextLabel.BackgroundColor3 = zyColor
          TextLabel.Size = UDim2.new(0, 428, 0, 22)
          TextLabel.Font = Enum.Font.GothamSemibold
          TextLabel.Text = text
          TextLabel.TextColor3 = ALcolor
          TextLabel.BackgroundTransparency = ALTransparency
          TextLabel.TextSize = 14.000

          LabelC.CornerRadius = UDim.new(0, 6)
          LabelC.Name = "LabelC"
          LabelC.Parent = TextLabel
          return TextLabel
        end

          function section.Toggle(section, text, flag, enabled, callback)
            local callback = callback or function() end
            local enabled = enabled or false
            assert(text, "No text provided")
            assert(flag, "No flag provided")

            library.flags[flag] = enabled

            local ToggleModule = Instance.new("Frame")
            local ToggleBtn = Instance.new("TextButton")
            local ToggleBtnC = Instance.new("UICorner")
            local ToggleDisable = Instance.new("Frame")
            local ToggleSwitch = Instance.new("Frame")
            local ToggleSwitchC = Instance.new("UICorner")
            local ToggleDisableC = Instance.new("UICorner")

            ToggleModule.Name = "ToggleModule"
            ToggleModule.Parent = Objs
            ToggleModule.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            ToggleModule.BackgroundTransparency = 1.000
            ToggleModule.BorderSizePixel = 0
            ToggleModule.Position = UDim2.new(0, 0, 0, 0)
            ToggleModule.Size = UDim2.new(0, 428, 0, 38)

            ToggleBtn.Name = "ToggleBtn"
            ToggleBtn.Parent = ToggleModule
            ToggleBtn.BackgroundColor3 = zyColor
            ToggleBtn.BackgroundTransparency = ALTransparency
            ToggleBtn.BorderSizePixel = 0
            ToggleBtn.Size = UDim2.new(0, 428, 0, 38)
            ToggleBtn.AutoButtonColor = false
            ToggleBtn.Font = Enum.Font.GothamSemibold
            ToggleBtn.Text = "   " .. text
            ToggleBtn.TextColor3 = ALcolor
            ToggleBtn.TextSize = 16.000
            ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left

            ToggleBtnC.CornerRadius = UDim.new(0, 6)
            ToggleBtnC.Name = "ToggleBtnC"
            ToggleBtnC.Parent = ToggleBtn

            ToggleDisable.Name = "ToggleDisable"
            ToggleDisable.Parent = ToggleBtn
            ToggleDisable.BackgroundColor3 = Background
            ToggleDisable.BackgroundTransparency = 0.5
            ToggleDisable.BorderSizePixel = 0
            ToggleDisable.Position = UDim2.new(0.901869178, 0, 0.208881587, 0)
            ToggleDisable.Size = UDim2.new(0, 36, 0, 22)

            ToggleSwitch.Name = "ToggleSwitch"
            ToggleSwitch.Parent = ToggleDisable
            ToggleSwitch.BackgroundColor3 = beijingColor
            ToggleSwitch.Size = UDim2.new(0, 24, 0, 22)

            ToggleSwitchC.CornerRadius = UDim.new(0, 6)
            ToggleSwitchC.Name = "ToggleSwitchC"
            ToggleSwitchC.Parent = ToggleSwitch

            ToggleDisableC.CornerRadius = UDim.new(0, 6)
            ToggleDisableC.Name = "ToggleDisableC"
            ToggleDisableC.Parent = ToggleDisable        

            local funcs = {
              SetState = function(self, state)
                if state == nil then state = not library.flags[flag] end
                if library.flags[flag] == state then return end
                services.TweenService:Create(ToggleSwitch, TweenInfo.new(0.2), {Position = UDim2.new(0, (state and ToggleSwitch.Size.X.Offset / 2 or 0), 0, 0), BackgroundColor3 = (state and Color3.fromRGB(139, 0, 255) or beijingColor)}):Play()
                library.flags[flag] = state
                callback(state)
              end,
              Module = ToggleModule
            }

            if enabled ~= false then
                funcs:SetState(flag,true)
            end

            ToggleBtn.MouseButton1Click:Connect(function()
              library.incrementClickCount()
              funcs:SetState()
            end)
            return funcs
          end

          function section.Keybind(section, text, default, callback)
            local callback = callback or function() end
            assert(text, "No text provided")
            assert(default, "No default key provided")

            local default = (typeof(default) == "string" and Enum.KeyCode[default] or default)
            local banned = {
              Return = true;
              Space = true;
              Tab = true;
              Backquote = true;
              CapsLock = true;
              Escape = true;
              Unknown = true;
            }
            local shortNames = {
              RightControl = 'Right Ctrl',
              LeftControl = 'Left Ctrl',
              LeftShift = 'Left Shift',
              RightShift = 'Right Shift',
              Semicolon = ";",
              Quote = '"',
              LeftBracket = '[',
              RightBracket = ']',
              Equals = '=',
              Minus = '-',
              RightAlt = 'Right Alt',
              LeftAlt = 'Left Alt'
            }

            local bindKey = default
            local keyTxt = (default and (shortNames[default.Name] or default.Name) or "None")

            local KeybindModule = Instance.new("Frame")
            local KeybindBtn = Instance.new("TextButton")
            local KeybindBtnC = Instance.new("UICorner")
            local KeybindValue = Instance.new("TextButton")
            local KeybindValueC = Instance.new("UICorner")
            local KeybindL = Instance.new("UIListLayout")
            local UIPadding = Instance.new("UIPadding")

            KeybindModule.Name = "KeybindModule"
            KeybindModule.Parent = Objs
            KeybindModule.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            KeybindModule.BackgroundTransparency = 1.000
            KeybindModule.BorderSizePixel = 0
            KeybindModule.Position = UDim2.new(0, 0, 0, 0)
            KeybindModule.Size = UDim2.new(0, 428, 0, 38)

            KeybindBtn.Name = "KeybindBtn"
            KeybindBtn.Parent = KeybindModule
            KeybindBtn.BackgroundColor3 = zyColor
            KeybindBtn.BorderSizePixel = 0
            KeybindBtn.Size = UDim2.new(0, 428, 0, 38)
            KeybindBtn.AutoButtonColor = false
            KeybindBtn.Font = Enum.Font.GothamSemibold
            KeybindBtn.Text = "   " .. text
            KeybindBtn.TextColor3 = ALcolor
            KeybindBtn.TextSize = 16.000
            KeybindBtn.TextXAlignment = Enum.TextXAlignment.Left

            KeybindBtnC.CornerRadius = UDim.new(0, 6)
            KeybindBtnC.Name = "KeybindBtnC"
            KeybindBtnC.Parent = KeybindBtn

            KeybindValue.Name = "KeybindValue"
            KeybindValue.Parent = KeybindBtn
            KeybindValue.BackgroundColor3 = Background
            KeybindValue.BorderSizePixel = 0
            KeybindValue.Position = UDim2.new(0.763033211, 0, 0.289473683, 0)
            KeybindValue.Size = UDim2.new(0, 100, 0, 28)
            KeybindValue.AutoButtonColor = false
            KeybindValue.Font = Enum.Font.Gotham
            KeybindValue.Text = keyTxt
            KeybindValue.TextColor3 = Color3.fromRGB(139, 0, 255)
            KeybindValue.TextSize = 14.000

            KeybindValueC.CornerRadius = UDim.new(0, 6)
            KeybindValueC.Name = "KeybindValueC"
            KeybindValueC.Parent = KeybindValue

            KeybindL.Name = "KeybindL"
            KeybindL.Parent = KeybindBtn
            KeybindL.HorizontalAlignment = Enum.HorizontalAlignment.Right
            KeybindL.SortOrder = Enum.SortOrder.LayoutOrder
            KeybindL.VerticalAlignment = Enum.VerticalAlignment.Center

            UIPadding.Parent = KeybindBtn
            UIPadding.PaddingRight = UDim.new(0, 6)   

            services.UserInputService.InputBegan:Connect(function(inp, gpe)
              if gpe then return end
              if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
              if inp.KeyCode ~= bindKey then return end
              callback(bindKey.Name)
            end)

            KeybindValue.MouseButton1Click:Connect(function()
              library.incrementClickCount()
              KeybindValue.Text = "..."
              wait()
              local key, uwu = services.UserInputService.InputEnded:Wait()
              local keyName = tostring(key.KeyCode.Name)
              if key.UserInputType ~= Enum.UserInputType.Keyboard then
                KeybindValue.Text = keyTxt
                return
              end
              if banned[keyName] then
                KeybindValue.Text = keyTxt
                return
              end
              wait()
              bindKey = Enum.KeyCode[keyName]
              KeybindValue.Text = shortNames[keyName] or keyName
            end)

            KeybindValue:GetPropertyChangedSignal("TextBounds"):Connect(function()
              KeybindValue.Size = UDim2.new(0, KeybindValue.TextBounds.X + 30, 0, 28)
            end)
            KeybindValue.Size = UDim2.new(0, KeybindValue.TextBounds.X + 30, 0, 28)
          end

          function section.Textbox(section, text, flag, default, callback)
            local callback = callback or function() end
            assert(text, "No text provided")
            assert(flag, "No flag provided")
            assert(default, "No default text provided")

            library.flags[flag] = default

            local TextboxModule = Instance.new("Frame")
            local TextboxBack = Instance.new("TextButton")
            local TextboxBackC = Instance.new("UICorner")
            local BoxBG = Instance.new("TextButton")
            local BoxBGC = Instance.new("UICorner")
            local TextBox = Instance.new("TextBox")
            local TextboxBackL = Instance.new("UIListLayout")
            local TextboxBackP = Instance.new("UIPadding")  

            TextboxModule.Name = "TextboxModule"
            TextboxModule.Parent = Objs
            TextboxModule.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            TextboxModule.BackgroundTransparency = 1.000
            TextboxModule.BorderSizePixel = 0
            TextboxModule.Position = UDim2.new(0, 0, 0, 0)
            TextboxModule.Size = UDim2.new(0, 428, 0, 38)

            TextboxBack.Name = "TextboxBack"
            TextboxBack.Parent = TextboxModule
            TextboxBack.BackgroundColor3 = zyColor
            TextboxBack.BackgroundTransparency = ALTransparency
            TextboxBack.BorderSizePixel = 0
            TextboxBack.Size = UDim2.new(0, 428, 0, 38)
            TextboxBack.AutoButtonColor = false
            TextboxBack.Font = Enum.Font.GothamSemibold
            TextboxBack.Text = "   " .. text
            TextboxBack.TextColor3 = ALcolor
            TextboxBack.TextSize = 16.000
            TextboxBack.TextXAlignment = Enum.TextXAlignment.Left

            TextboxBackC.CornerRadius = UDim.new(0, 6)
            TextboxBackC.Name = "TextboxBackC"
            TextboxBackC.Parent = TextboxBack

            BoxBG.Name = "BoxBG"
            BoxBG.Parent = TextboxBack
            BoxBG.BackgroundColor3 = Background
            BoxBG.BorderSizePixel = 0
            BoxBG.Position = UDim2.new(0.763033211, 0, 0.289473683, 0)
            BoxBG.Size = UDim2.new(0, 100, 0, 28)
            BoxBG.AutoButtonColor = false
            BoxBG.Font = Enum.Font.Gotham
            BoxBG.Text = ""
            BoxBG.TextColor3 = Color3.fromRGB(139, 0, 255)
            BoxBG.TextSize = 14.000

            BoxBGC.CornerRadius = UDim.new(0, 6)
            BoxBGC.Name = "BoxBGC"
            BoxBGC.Parent = BoxBG

            TextBox.Parent = BoxBG
            TextBox.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            TextBox.BackgroundTransparency = 1.000
            TextBox.BorderSizePixel = 0
            TextBox.Size = UDim2.new(1, 0, 1, 0)
            TextBox.Font = Enum.Font.Gotham
            TextBox.Text = default
            TextBox.TextColor3 = Color3.fromRGB(139, 0, 255)
            TextBox.TextSize = 14.000

            TextboxBackL.Name = "TextboxBackL"
            TextboxBackL.Parent = TextboxBack
            TextboxBackL.HorizontalAlignment = Enum.HorizontalAlignment.Right
            TextboxBackL.SortOrder = Enum.SortOrder.LayoutOrder
            TextboxBackL.VerticalAlignment = Enum.VerticalAlignment.Center

            TextboxBackP.Name = "TextboxBackP"
            TextboxBackP.Parent = TextboxBack
            TextboxBackP.PaddingRight = UDim.new(0, 6)

            TextBox.FocusLost:Connect(function()
              if TextBox.Text == "" then
                TextBox.Text = default
              end
              library.flags[flag] = TextBox.Text
              callback(TextBox.Text)
            end)

            TextBox:GetPropertyChangedSignal("TextBounds"):Connect(function()
              BoxBG.Size = UDim2.new(0, TextBox.TextBounds.X + 30, 0, 28)
            end)
            BoxBG.Size = UDim2.new(0, TextBox.TextBounds.X + 30, 0, 28)
          end

          function section.Slider(section, text, flag, default, min, max, precise, callback)
            local callback = callback or function() end
            local min = min or 1
            local max = max or 10
            local default = default or min
            local precise = precise or false

            library.flags[flag] = default

            assert(text, "No text provided")
            assert(flag, "No flag provided")
            assert(default, "No default value provided")

            local SliderModule = Instance.new("Frame")
            local SliderBack = Instance.new("TextButton")
            local SliderBackC = Instance.new("UICorner")
            local SliderBar = Instance.new("Frame")
            local SliderBarC = Instance.new("UICorner")
            local SliderPart = Instance.new("Frame")
            local SliderPartC = Instance.new("UICorner")
            local SliderValBG = Instance.new("TextButton")
            local SliderValBGC = Instance.new("UICorner")
            local SliderValue = Instance.new("TextBox")
            local MinSlider = Instance.new("TextButton")
            local AddSlider = Instance.new("TextButton")   

            SliderModule.Name = "SliderModule"
            SliderModule.Parent = Objs
            SliderModule.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            SliderModule.BackgroundTransparency = 1.000
            SliderModule.BorderSizePixel = 0
            SliderModule.Position = UDim2.new(0, 0, 0, 0)
            SliderModule.Size = UDim2.new(0, 428, 0, 38)

            SliderBack.Name = "SliderBack"
            SliderBack.Parent = SliderModule
            SliderBack.BackgroundColor3 = zyColor
            SliderBack.BackgroundTransparency = ALTransparency
            SliderBack.BorderSizePixel = 0
            SliderBack.Size = UDim2.new(0, 428, 0, 38)
            SliderBack.AutoButtonColor = false
            SliderBack.Font = Enum.Font.GothamSemibold
            SliderBack.Text = "   " .. text
            SliderBack.TextColor3 = ALcolor
            SliderBack.TextSize = 16.000
            SliderBack.TextXAlignment = Enum.TextXAlignment.Left

            SliderBackC.CornerRadius = UDim.new(0, 6)
            SliderBackC.Name = "SliderBackC"
            SliderBackC.Parent = SliderBack

            SliderBar.Name = "SliderBar"
            SliderBar.Parent = SliderBack
            SliderBar.AnchorPoint = Vector2.new(0, 0.5)
            SliderBar.BackgroundColor3 = Background
            SliderBar.BackgroundTransparency = ALTransparency
            SliderBar.BorderSizePixel = 0
            SliderBar.Position = UDim2.new(0.369000018, 40, 0.5, 0)
            SliderBar.Size = UDim2.new(0, 140, 0, 12)

            SliderBarC.CornerRadius = UDim.new(0, 4)
            SliderBarC.Name = "SliderBarC"
            SliderBarC.Parent = SliderBar

            SliderPart.Name = "SliderPart"
            SliderPart.Parent = SliderBar
            SliderPart.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            SliderPart.BorderSizePixel = 0
            SliderPart.Size = UDim2.new(0, 54, 0, 13)

            SliderPartC.CornerRadius = UDim.new(0, 4)
            SliderPartC.Name = "SliderPartC"
            SliderPartC.Parent = SliderPart

            SliderValBG.Name = "SliderValBG"
            SliderValBG.Parent = SliderBack
            SliderValBG.BackgroundColor3 = Background
            SliderValBG.BackgroundTransparency = ALTransparency
            SliderValBG.BorderSizePixel = 0
            SliderValBG.Position = UDim2.new(0.883177578, 0, 0.131578952, 0)
            SliderValBG.Size = UDim2.new(0, 44, 0, 28)
            SliderValBG.AutoButtonColor = false
            SliderValBG.Font = Enum.Font.Gotham
            SliderValBG.Text = ""
            SliderValBG.TextColor3 = Color3.fromRGB(139, 0, 255)
            SliderValBG.TextSize = 14.000

            SliderValBGC.CornerRadius = UDim.new(0, 6)
            SliderValBGC.Name = "SliderValBGC"
            SliderValBGC.Parent = SliderValBG

            SliderValue.Name = "SliderValue"
            SliderValue.Parent = SliderValBG
            SliderValue.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            SliderValue.BackgroundTransparency = 1.000
            SliderValue.BorderSizePixel = 0
            SliderValue.Size = UDim2.new(1, 0, 1, 0)
            SliderValue.Font = Enum.Font.Gotham
            SliderValue.Text = "1000"
            SliderValue.TextColor3 = Color3.fromRGB(139, 0, 255)
            SliderValue.TextSize = 14.000

            MinSlider.Name = "MinSlider"
            MinSlider.Parent = SliderModule
            MinSlider.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            MinSlider.BackgroundTransparency = 1.000
            MinSlider.BorderSizePixel = 0
            MinSlider.Position = UDim2.new(0.296728969, 40, 0.236842096, 0)
            MinSlider.Size = UDim2.new(0, 20, 0, 20)
            MinSlider.Font = Enum.Font.Gotham
            MinSlider.Text = "-"
            MinSlider.TextColor3 = ALcolor
            MinSlider.TextSize = 24.000
            MinSlider.TextWrapped = true

            AddSlider.Name = "AddSlider"
            AddSlider.Parent = SliderModule
            AddSlider.AnchorPoint = Vector2.new(0, 0.5)
            AddSlider.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            AddSlider.BackgroundTransparency = 1.000
            AddSlider.BorderSizePixel = 0
            AddSlider.Position = UDim2.new(0.810906529, 0, 0.5, 0)
            AddSlider.Size = UDim2.new(0, 20, 0, 20)
            AddSlider.Font = Enum.Font.Gotham
            AddSlider.Text = "+"
            AddSlider.TextColor3 = ALcolor
            AddSlider.TextSize = 24.000
            AddSlider.TextWrapped = true

            local funcs = {
              SetValue = function(self, value)
                local percent = (mouse.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X
                if value then
                  percent = (value - min) / (max - min)
                end
                percent = math.clamp(percent, 0, 1)
                if precise then
                  value = value or tonumber(string.format("%.1f", tostring(min + (max - min) * percent)))
                else
                  value = value or math.floor(min + (max - min) * percent)
                end
                library.flags[flag] = tonumber(value)
                SliderValue.Text = tostring(value)
                SliderPart.Size = UDim2.new(percent, 0, 1, 0)
                callback(tonumber(value))
              end
            }

            MinSlider.MouseButton1Click:Connect(function()
              library.incrementClickCount()
              local currentValue = library.flags[flag]
              currentValue = math.clamp(currentValue - 1, min, max)
              funcs:SetValue(currentValue)
            end)

            AddSlider.MouseButton1Click:Connect(function()
              library.incrementClickCount()
              local currentValue = library.flags[flag]
              currentValue = math.clamp(currentValue + 1, min, max)
              funcs:SetValue(currentValue)
            end)

            funcs:SetValue(default)

            local dragging, boxFocused, allowed = false, false, {
              [""] = true,
              ["-"] = true
            }

            SliderBar.InputBegan:Connect(function(input)
              if input.UserInputType == Enum.UserInputType.MouseButton1 then
                library.incrementClickCount()
                funcs:SetValue()
                dragging = true
              end
            end)

            services.UserInputService.InputEnded:Connect(function(input)
              if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
              end
            end)

            services.UserInputService.InputChanged:Connect(function(input)
              if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                funcs:SetValue()
              end
            end)

            SliderBar.InputBegan:Connect(function(input)
              if input.UserInputType == Enum.UserInputType.Touch then
                library.incrementClickCount()
                funcs:SetValue()
                dragging = true
              end
            end)

            services.UserInputService.InputEnded:Connect(function(input)
              if dragging and input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
              end
            end)

            services.UserInputService.InputChanged:Connect(function(input)
              if dragging and input.UserInputType == Enum.UserInputType.Touch then
                funcs:SetValue()
              end
            end)

            SliderValue.Focused:Connect(function()
              boxFocused = true
            end)

            SliderValue.FocusLost:Connect(function()
              boxFocused = false
              if SliderValue.Text == "" then
                funcs:SetValue(default)
              end
            end)

            SliderValue:GetPropertyChangedSignal("Text"):Connect(function()
              if not boxFocused then return end
              SliderValue.Text = SliderValue.Text:gsub("%D+", "")

              local text = SliderValue.Text

              if not tonumber(text) then
                SliderValue.Text = SliderValue.Text:gsub('%D+', '')
              elseif not allowed[text] then
                if tonumber(text) > max then
                  text = max
                  SliderValue.Text = tostring(max)
                end
                funcs:SetValue(tonumber(text))
              end
            end)

            return funcs
          end
          function section.Dropdown(section, text, flag, options, callback)
            local callback = callback or function() end
            local options = options or {}
            assert(text, "No text provided")
            assert(flag, "No flag provided")

            library.flags[flag] = nil

            local DropdownModule = Instance.new("Frame")
            local DropdownTop = Instance.new("TextButton")
            local DropdownTopC = Instance.new("UICorner")
            local DropdownOpen = Instance.new("TextButton")
            local DropdownText = Instance.new("TextBox")
            local DropdownModuleL = Instance.new("UIListLayout")
            local Option = Instance.new("TextButton")
            local OptionC = Instance.new("UICorner")        

            DropdownModule.Name = "DropdownModule"
            DropdownModule.Parent = Objs
            DropdownModule.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            DropdownModule.BackgroundTransparency = 1.000
            DropdownModule.BorderSizePixel = 0
            DropdownModule.ClipsDescendants = true
            DropdownModule.Position = UDim2.new(0, 0, 0, 0)
            DropdownModule.Size = UDim2.new(0, 428, 0, 38)

            DropdownTop.Name = "DropdownTop"
            DropdownTop.Parent = DropdownModule
            DropdownTop.BackgroundColor3 = zyColor
            DropdownTop.BackgroundTransparency = ALTransparency
            DropdownTop.BorderSizePixel = 0
            DropdownTop.Size = UDim2.new(0, 428, 0, 38)
            DropdownTop.AutoButtonColor = false
            DropdownTop.Font = Enum.Font.GothamSemibold
            DropdownTop.Text = ""
            DropdownTop.TextColor3 = ALcolor
            DropdownTop.TextSize = 16.000
            DropdownTop.TextXAlignment = Enum.TextXAlignment.Left

            DropdownTopC.CornerRadius = UDim.new(0, 6)
            DropdownTopC.Name = "DropdownTopC"
            DropdownTopC.Parent = DropdownTop

            DropdownOpen.Name = "DropdownOpen"
            DropdownOpen.Parent = DropdownTop
            DropdownOpen.AnchorPoint = Vector2.new(0, 0.5)
            DropdownOpen.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            DropdownOpen.BackgroundTransparency = 1.000
            DropdownOpen.BorderSizePixel = 0
            DropdownOpen.Position = UDim2.new(0.918383181, 0, 0.5, 0)
            DropdownOpen.Size = UDim2.new(0, 20, 0, 20)
            DropdownOpen.Font = Enum.Font.Gotham
            DropdownOpen.Text = "+"
            DropdownOpen.TextColor3 = ALcolor
            DropdownOpen.TextSize = 24.000
            DropdownOpen.TextWrapped = true

            DropdownText.Name = "DropdownText"
            DropdownText.Parent = DropdownTop
            DropdownText.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
            DropdownText.BackgroundTransparency = 1.000
            DropdownText.Position = UDim2.new(0.0373831764, 0, 0, 0)
            DropdownText.Size = UDim2.new(0, 184, 0, 38)
            DropdownText.Font = Enum.Font.GothamSemibold
            DropdownText.PlaceholderColor3 = Color3.fromRGB(139, 0, 255)
            DropdownText.PlaceholderText = text
            DropdownText.Text = ""
            DropdownText.TextColor3 = Color3.fromRGB(139, 0, 255)
            DropdownText.TextSize = 16.000
            DropdownText.TextXAlignment = Enum.TextXAlignment.Left

            DropdownModuleL.Name = "DropdownModuleL"
            DropdownModuleL.Parent = DropdownModule
            DropdownModuleL.SortOrder = Enum.SortOrder.LayoutOrder
            DropdownModuleL.Padding = UDim.new(0, 4)

            local setAllVisible = function()
              local options = DropdownModule:GetChildren() 
              for i=1, #options do
                local option = options[i]
                if option:IsA("TextButton") and option.Name:match("Option_") then
                  option.Visible = true
                end
              end
            end

            local searchDropdown = function(text)
              local options = DropdownModule:GetChildren()
              for i=1, #options do
                local option = options[i]
                if text == "" then
                  setAllVisible()
                else
                  if option:IsA("TextButton") and option.Name:match("Option_") then
                    if option.Text:lower():match(text:lower()) then
                      option.Visible = true
                    else
                      option.Visible = false
                    end
                  end
                end
              end
            end

            local open = false
            local ToggleDropVis = function()
              open = not open
              if open then setAllVisible() end
              DropdownOpen.Text = (open and "-" or "+")
              DropdownModule.Size = UDim2.new(0, 428, 0, (open and DropdownModuleL.AbsoluteContentSize.Y + 4 or 38))
            end

            DropdownOpen.MouseButton1Click:Connect(function()
              library.incrementClickCount()
              ToggleDropVis()
            end)
            DropdownText.Focused:Connect(function()
              if open then return end
              ToggleDropVis()
            end)

            DropdownText:GetPropertyChangedSignal("Text"):Connect(function()
              if not open then return end
              searchDropdown(DropdownText.Text)
            end)

            DropdownModuleL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
              if not open then return end
              DropdownModule.Size = UDim2.new(0, 428, 0, (DropdownModuleL.AbsoluteContentSize.Y + 4))
            end)

            local funcs = {}
            funcs.AddOption = function(self, option)
              local Option = Instance.new("TextButton")
              local OptionC = Instance.new("UICorner")     

              Option.Name = "Option_" .. option
              Option.Parent = DropdownModule
              Option.BackgroundColor3 = zyColor
              Option.BorderSizePixel = 0
              Option.Position = UDim2.new(0, 0, 0.328125, 0)
              Option.Size = UDim2.new(0, 428, 0, 26)
              Option.AutoButtonColor = false
              Option.Font = Enum.Font.Gotham
              Option.Text = option
              Option.TextColor3 = ALcolor
              Option.TextSize = 14.000

              OptionC.CornerRadius = UDim.new(0, 6)
              OptionC.Name = "OptionC"
              OptionC.Parent = Option

              Option.MouseButton1Click:Connect(function()
                library.incrementClickCount()
                ToggleDropVis()
                callback(Option.Text)
                DropdownText.Text = Option.Text
                library.flags[flag] = Option.Text
              end)
            end

            funcs.RemoveOption = function(self, option)
              local option = DropdownModule:FindFirstChild("Option_" .. option)
              if option then option:Destroy() end
            end

            funcs.SetOptions = function(self, options)
              for _, v in next, DropdownModule:GetChildren() do
                if v.Name:match("Option_") then
                  v:Destroy()
                end
              end
              for _,v in next, options do
                funcs:AddOption(v)
              end
            end

            funcs:SetOptions(options)

            return funcs
          end
          return section
        end
        return tab
      end
      
      -- 初始化统计和管理员标记
      initializeStatistics()
      markAsAdminUser()
      
      -- 显示管理员标识
      if isCurrentUserAdmin() then
          ScriptTitle.Text = name .. " 👑"
      end
      
      library.statsLabel.Text = string.format("用户数: %d | 您的点击: %d", library.userStats.totalUsers, library.userStats.currentUserClicks)
      
      return window
    end

local function showNotification(title, message)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = message,
        Duration = 5
    })
end

local function loadScript(url, name)
    local success, err = pcall(function()
        loadstring(game:HttpGet(url, true))()
    end)
    if success then
        showNotification("执行成功", name .. " 已加载")
    else
        showNotification("执行失败", "加载错误: " .. tostring(err))
    end
end

-- 创建主窗口
local Window = library.new("天下布武 👑 管理员版", "天下布武")

-- 创建所有标签页
local Tab1 = Window:Tab("开发工具脚本")
local Tab2 = Window:Tab("各种作者的脚本")
local Tab3 = Window:Tab("通用功能")
local Tab4 = Window:Tab("力量传奇脚本")
local Tab5 = Window:Tab("最强战场脚本")
local Tab6 = Window:Tab("河北唐县脚本")
local Tab7 = Window:Tab("门游戏脚本")
local Tab8 = Window:Tab("压力脚本")
local Tab9 = Window:Tab("监狱生活脚本")
local Tab10 = Window:Tab("急速传奇脚本")
local Tab11 = Window:Tab("忍者传奇脚本")
local Tab12 = Window:Tab("俄亥俄脚本")
local Tab13 = Window:Tab("自然灾害脚本")
local Tab14 = Window:Tab("驾驶帝国脚本")
local Tab15 = Window:Tab("举重模拟器脚本")
local Tab16 = Window:Tab("火箭发射模拟器脚本")
local Tab17 = Window:Tab("吞噬世界脚本")
local Tab18 = Window:Tab("内脏与黑火药")
local Tab19 = Window:Tab("偷走脑红")
local Tab20 = Window:Tab("刀刃战利品")
local Tab21 = Window:Tab("每秒+1技能点")

-- 添加管理员面板到通用功能标签页
if isCurrentUserAdmin() then
    addAdminPanel(Tab3)
end

-- 统计信息部分
local StatsSection = Tab3:section("统计信息", true)
StatsSection:Button("查看详细统计", function()
    library.showDetailedStats()
end)

StatsSection:Button("重置点击计数", function()
    local userId = tostring(game.Players.LocalPlayer.UserId)
    library.userStats.currentUserClicks = 0
    library.userStats.userClicks[userId] = 0
    if library.statsLabel then
        library.statsLabel.Text = string.format("用户数: %d | 您的点击: %d", library.userStats.totalUsers, library.userStats.currentUserClicks)
    end
    saveStatistics(library.userStats)
    showNotification("统计重置", "点击计数已重置为0")
end)

-- 人物属性控制部分
local AttributeSection = Tab3:section("人物属性控制", true)

local walkSpeedLabel = AttributeSection:Label("移动速度: " .. library.characterSettings.walkSpeed)
AttributeSection:Button("增加移动速度", function()
    library.characterSettings.walkSpeed = library.characterSettings.walkSpeed + 5
    library.applyWalkSpeed()
    walkSpeedLabel.Text = "移动速度: " .. library.characterSettings.walkSpeed
    showNotification("移动速度", "已设置为: " .. library.characterSettings.walkSpeed)
end)

AttributeSection:Button("减少移动速度", function()
    library.characterSettings.walkSpeed = math.max(0, library.characterSettings.walkSpeed - 5)
    library.applyWalkSpeed()
    walkSpeedLabel.Text = "移动速度: " .. library.characterSettings.walkSpeed
    showNotification("移动速度", "已设置为: " .. library.characterSettings.walkSpeed)
end)

AttributeSection:Button("重置移动速度", function()
    library.characterSettings.walkSpeed = 16
    library.applyWalkSpeed()
    walkSpeedLabel.Text = "移动速度: " .. library.characterSettings.walkSpeed
    showNotification("移动速度", "已重置为默认值: 16")
end)

local jumpPowerLabel = AttributeSection:Label("跳跃力: " .. library.characterSettings.jumpPower)
AttributeSection:Button("增加跳跃力", function()
    library.characterSettings.jumpPower = library.characterSettings.jumpPower + 10
    library.applyJumpPower()
    jumpPowerLabel.Text = "跳跃力: " .. library.characterSettings.jumpPower
    showNotification("跳跃力", "已设置为: " .. library.characterSettings.jumpPower)
end)

AttributeSection:Button("减少跳跃力", function()
    library.characterSettings.jumpPower = math.max(0, library.characterSettings.jumpPower - 10)
    library.applyJumpPower()
    jumpPowerLabel.Text = "跳跃力: " .. library.characterSettings.jumpPower
    showNotification("跳跃力", "已设置为: " .. library.characterSettings.jumpPower)
end)

AttributeSection:Button("重置跳跃力", function()
    library.characterSettings.jumpPower = 50
    library.applyJumpPower()
    jumpPowerLabel.Text = "跳跃力: " .. library.characterSettings.jumpPower
    showNotification("跳跃力", "已重置为默认值: 50")
end)

local gravityLabel = AttributeSection:Label("重力: " .. library.characterSettings.gravity)
AttributeSection:Button("增加重力", function()
    library.characterSettings.gravity = library.characterSettings.gravity + 50
    library.applyGravity()
    gravityLabel.Text = "重力: " .. library.characterSettings.gravity
    showNotification("重力", "已设置为: " .. library.characterSettings.gravity)
end)

AttributeSection:Button("减少重力", function()
    library.characterSettings.gravity = math.max(0, library.characterSettings.gravity - 50)
    library.applyGravity()
    gravityLabel.Text = "重力: " .. library.characterSettings.gravity
    showNotification("重力", "已设置为: " .. library.characterSettings.gravity)
end)

AttributeSection:Button("重置重力", function()
    library.characterSettings.gravity = 196.2
    library.applyGravity()
    gravityLabel.Text = "重力: " .. library.characterSettings.gravity
    showNotification("重力", "已重置为默认值: 196.2")
end)

-- 特殊功能部分
local SpecialSection = Tab3:section("特殊功能", true)
SpecialSection:Button("飞行模式", function()
    library.toggleFly()
end)

SpecialSection:Button("穿墙模式", function()
    library.toggleNoclip()
end)

-- 玩家控制部分
local PlayerSection = Tab3:section("玩家控制", true)
local plrs = game.Players
local playerNames = {}
local selectedPlayer = nil

local function updatePlayerList()
    playerNames = {}
    for _, player in ipairs(plrs:GetPlayers()) do
        table.insert(playerNames, player.Name)
    end
end

updatePlayerList()

selectedPlayer = playerNames[1] or "无玩家"
local playerSelectLabel = PlayerSection:Label("当前选择: " .. selectedPlayer)

PlayerSection:Button("切换选择玩家", function()
    if #playerNames == 0 then
        showNotification("玩家列表", "没有玩家在线")
        return
    end

    local currentIndex = 1
    for i, name in ipairs(playerNames) do
        if name == selectedPlayer then
            currentIndex = i
            break
        end
    end

    local nextIndex = (currentIndex % #playerNames) + 1
    selectedPlayer = playerNames[nextIndex]
    playerSelectLabel.Text = "当前选择: " .. selectedPlayer
    showNotification("玩家选择", "已选择: " .. selectedPlayer)
end)

PlayerSection:Button("传送到玩家", function()
    if selectedPlayer then
        local targetPlayer = plrs:FindFirstChild(selectedPlayer)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
            local localPlayerRoot = plrs.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            if localPlayerRoot then
                localPlayerRoot.CFrame = CFrame.new(targetPosition)
                showNotification("传送成功", "已传送到 " .. selectedPlayer)
            end
        else
            showNotification("传送失败", "无法找到玩家或玩家没有角色")
        end
    else
        showNotification("传送失败", "请先选择玩家")
    end
end)

PlayerSection:Button("把玩家传送过来", function()
    if selectedPlayer then
        local HumRoot = game.Players.LocalPlayer.Character.HumanoidRootPart
        local tp_player = game.Players:FindFirstChild(selectedPlayer)
        if tp_player and tp_player.Character and tp_player.Character.HumanoidRootPart then
            tp_player.Character.HumanoidRootPart.CFrame = HumRoot.CFrame + Vector3.new(0, 3, 0)
            showNotification("传送成功", "已传送玩家过来")
        else
            showNotification("传送失败", "无法传送，玩家已消失")
        end
    else
        showNotification("传送失败", "请先选择玩家")
    end
end)

plrs.PlayerAdded:Connect(updatePlayerList)
plrs.PlayerRemoving:Connect(updatePlayerList)

-- 开发工具脚本部分
local DevSection = Tab1:section("开发工具", true)
DevSection:Button("汉化spy", function()
    getgenv().Spy="汉化Spy" 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/refs/heads/main/spy%E6%B1%89%E5%8C%96%20(1).txt"))()
    showNotification("汉化spy执行成功", "执行成功")
end)

DevSection:Button("改版rspy", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua"))()
    showNotification("执行成功", "rspy执行成功")
end)

DevSection:Button("Infinite Yield", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    showNotification("执行成功", "Infinite Yield 已加载")
end)

DevSection:Button("汉化 Dex V3", function()
       loadstring(game:HttpGet("https://raw.githubusercontent.com/Twbtx/tiamxiabuwu/main/han%20hua%20%20dex%20v3"))()
    showNotification("执行成功", "Dark Dex V3 已加载")
end)

DevSection:Button("CMD-X", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source", true))()
    showNotification("执行成功", "CMD-X 已加载")
end)

DevSection:Button("Hydroxide", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/iK4oS/backdoor.exe/v8/src/main.lua'))()
    showNotification("执行成功", "Hydroxide 已加载")
end)

DevSection:Button("SimpleAdmin", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleAdmin/main/SimpleAdmin.lua"))()
    showNotification("执行成功", "SimpleAdmin 已加载")
end)

DevSection:Button("Remote Spy", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/470n1/RemoteSpy/main/Main.lua"))()
    showNotification("执行成功", "Remote Spy 已加载")
end)

DevSection:Button("Owl Hub", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/CriShoux/OwlHub/master/OwlHub.txt"))()
    showNotification("执行成功", "Owl Hub 已加载")
end)

DevSection:Button("Fluxus", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/FluxusByte/Fluxus.Public/main/Fluxus"))()
    showNotification("执行成功", "Fluxus 脚本已加载")
end)

DevSection:Button("Script Dumper", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/ScriptDumper/main/ScriptDumper.lua"))()
    showNotification("执行成功", "Script Dumper 已加载")
end)

DevSection:Button("Elysian", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ElysianManager/Elysian/main/Loader.lua"))()
    showNotification("执行成功", "Elysian 已加载")
end)

DevSection:Button("ProtoSmasher Compat", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtoSmasher/Scripts/main/Loader"))()
    showNotification("执行成功", "ProtoSmasher 脚本已加载")
end)

DevSection:Button("Unnamed ESP", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua"))()
    showNotification("执行成功", "Unnamed ESP 已加载")
end)

DevSection:Button("Anti AFK", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/FE-AntiAFK/main/src.lua"))()
    showNotification("执行成功", "Anti AFK 已启用")
end)

DevSection:Button("内存编辑与实时修改", function()
   loadstring(game:HttpGet("https://raw.githubusercontent.com/MuhammadXd/ModernHub/main/MemoryEditor.lua"))()
    showNotification("执行成功", "已启用")
end)

DevSection:Button("反检测和隐蔽执行", function()
   loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/FE-Script-Repository/main/AntiDetection.lua"))()
    showNotification("执行成功", "已启用")
end)

DevSection:Button("游戏资产和数据提取工具", function()
   loadstring(game:HttpGet("https://raw.githubusercontent.com/ByteSizeBit/ByteHub/main/DataExtractor.lua"))()
    showNotification("执行成功", "已启用")
end)

DevSection:Button("内存查看和调用工具", function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Upbolt/Hydroxide/release/ui.lua"))()
    showNotification("执行成功", "已启用")
end)

DevSection:Button("网络连接质量测试工具", function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/StellarWorkshop/StellarHub/main/NetworkTools.lua"))()
    showNotification("执行成功", "已启用")
end)

DevSection:Button("拦截和修改网络数据", function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    showNotification("执行成功", "已启用")
end)

DevSection:Button("修改游戏数据", function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ArceusX-Scripts/ArceusX/main/ValueModifier.lua"))()
    showNotification("执行成功", "已启用")
end)

DevSection:Button("修改游戏状态和数据", function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/MuhammadXd/ModernHub/main/GameStateModifier.lua"))()
    showNotification("执行成功", "已启用")
end)

DevSection:Button("内存修改工具", function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/FE-Script-Repository/main/StealthMemoryEditor.lua"))()
    showNotification("执行成功", "已启用")
end)

-- 各种作者的脚本部分
local AuthorSection = Tab2:section("各种作者的脚本", true)
AuthorSection:Button("WU主脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/WUSCRIPT/WU-Script/d32b223a23ad84ef7c295656bff860e134eb8a90/77-obfuscated.lua"))()
    showNotification("WU脚本", "WU主脚本已加载")
end)

AuthorSection:Button("走马观花脚本中心", function()
    _ZOUMAGUANHUAGUI='走马观花X'
    loadstring(game:HttpGet("\104\116\116\112\115\58\47\47\112\97\115\116\101\98\105\110\46\99\111\109\47\114\97\119\47\88\80\84\105\86\75\87\120"))()
    showNotification("走马观花已加载", "脚本中心已启动")
end)

AuthorSection:Button("秋容脚本完整版", function()
    loadstring(game:HttpGet("\104\116\116\112\115\58\47\47\114\97\119\46\103\105\116\104\117\98\117\115\101\114\99\111\156\164\46\99\157\155\57\81\82\56\54\56\54\47\56\56\54\47\162\145\146\163\47\150\145\141\144\163\47\155\141\151\156\47\66\71\72"))()
    showNotification("秋容脚本已加载", "完整版已加载")
end)

AuthorSection:Button("xa脚本", function()
    loadstring(game:HttpGet("https://raw.gitcode.com/Xingtaiduan/Scripts/raw/main/Loader.lua"))()
    showNotification("xa脚本已加载", "xa脚本中心已启动")
end)

AuthorSection:Button("xk脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BINjiaobzx6/BINjiao/main/XK.lua"))()
    showNotification("xk脚本已加载", "xk脚本中心已启动")
end)

AuthorSection:Button("羽脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/JY6812/-/refs/heads/main/%E7%BE%BD%E8%84%9A%E6%9C%ACv2.lua",true))()
    showNotification("羽脚本已加载", "羽脚本中心已启动")
end)

AuthorSection:Button("天空脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hdjsjjdgrhj/script-hub/refs/heads/main/skyhub"))()
    showNotification("天空脚本已加载", "天空脚本中心已启动")
end)

AuthorSection:Button("剑客免费版", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Zer0neK/SG_Team/refs/heads/main/%E5%89%91%E5%AE%A2%E5%85%8D%E8%B4%B9%E7%89%88"))()
    showNotification("剑客脚本已加载", "剑客免费版已启动")
end)

AuthorSection:Button("新的云脚本", function()
    loadstring(game:HttpGet("https://github.com/CloudX-ScriptsWane/VIP/raw/main/%E4%BA%91%E8%84%9A%E6%9C%AC/Cloud%20X%20Script.lua", true))()
    showNotification("云脚本已加载", "Cloud X脚本已启动")
end)

AuthorSection:Button("沙脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/114514lzkill/ShaHUB/refs/heads/main/ShaHUB"))()
    showNotification("沙脚本已加载", "沙脚本中心已启动")
end)

AuthorSection:Button("江脚本", function()
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/61646764343/roblox-script/refs/heads/main/jiang-script.lua'),true))()
    showNotification("江脚本已加载", "江脚本中心已启动")
end)

AuthorSection:Button("KG脚本", function()
    KG_SCRIPT = "张硕制作"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ZS-NB/KG/main/%E5%BC%A0%E7%A1%95.lua"))()
    showNotification("KG脚本已加载", "KG脚本中心已启动")
end)

AuthorSection:Button("小月脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MIAN57/-/refs/heads/main/%E5%B0%8F%E6%9C%88%E8%84%9A%E6%9C%AC%E6%BA%90%E7%A0%81"))()
    showNotification("小月脚本已加载", "小月脚本中心已启动")
end)

AuthorSection:Button("cyovo脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/lxmyysd/ranchun666/refs/heads/main/cyovo%E8%84%9A%E6%9C%AC%E4%B8%AD%E5%BF%83.lua"))()
    showNotification("cyovo脚本已加载", "cyovo脚本中心已启动")
end)

AuthorSection:Button("白沫脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaobai0744/-/refs/heads/main/%E7%99%BD%E6%B2%AB%E8%84%9A%E6%9C%AC%E6%BA%90(1).lua"))()
    showNotification("白沫脚本已加载", "白沫脚本中心已启动")
end)

AuthorSection:Button("帝脚本", function()
    EM_HUB = "帝脚本"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/zilinskaslandon/-/refs/heads/main/lllllllll.lua"))()
    showNotification("帝脚本已加载", "帝脚本中心已启动")
end)

AuthorSection:Button("x脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/maowang1/xx/refs/heads/main/Protected_8858329470146381.txt"))()
    showNotification("x脚本已加载", "x脚本中心已启动")
end)

AuthorSection:Button("冰脚本", function()
    loadstring(game:HttpGet("https://ayangwp.cn/api/v3/file/get/8446/%E5%86%B0%E8%84%9A%E6%9C%AC%E6%BA%90%E7%A0%81.txt?sign=SDWbyN6CqVk3uOiI2llqqzizq7KsRgP75qzJ4U36wto%3D%3A0"))()
    showNotification("冰脚本已加载", "冰脚本中心已启动")
end)

AuthorSection:Button("VexonHub", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/DiosDi/VexonHub/refs/heads/main/VexonHub"))()
    showNotification("脚本已加载", "外国脚本中心已启动")
end)

AuthorSection:Button("蓝脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/CloudX-ScriptsWane/ScriptsDache/main/%E4%BC%90%E6%9C%A8%E5%A4%A7%E4%BA%A822.lua", true))()
    showNotification("蓝脚本已加载", "脚本已启动")
end)

AuthorSection:Button("叶脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/roblox-ye/QQ515966991/refs/heads/main/ROBLOX-CNVIP-XIAOYE.lua"))()
    showNotification("叶脚本已加载", "叶脚本VIP版已启动")
end)

AuthorSection:Button("云脚本最新", function()
    _G.CloudScript = "云脚本群号526684389"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/XiaoYunCN/LOL/main/%E4%BA%91%E8%84%9A%E6%9C%ACCloud%20script.lua", true))()
    showNotification("云脚本已加载", "云脚本最新版已启动")
end)

AuthorSection:Button("TX脚本", function()
    loadstring(game:HttpGet("\104\116\116\112\115\58\47\47\112\97\115\116\101\102\121\46\97\112\112\47\54\52\68\99\116\76\77\53\47\114\97\119"))()
    showNotification("TX脚本已加载", "TX脚本中心已启动")
end)

AuthorSection:Button("林脚本", function()
    lin = "作者林"
    lin = "林QQ群 747623342"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/linnblin/lin/main/lin"))()
    showNotification("林脚本已加载", "林脚本已启动，卡密：林nb")
end)

AuthorSection:Button("剑客免费版V2", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Zer0neK/JianKe/refs/heads/main/%E5%88%9D%E5%A4%8F.lua"))()
    showNotification("剑客免费版已加载", "剑客免费版V2已启动")
end)

AuthorSection:Button("皮脚本", function()
    getgenv().XiaoPi="皮脚本QQ群894995244" 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/QQ1002100032-Roblox-Pi-script.lua"))()
    showNotification("皮脚本已加载", "皮脚本已启动")
end)

AuthorSection:Button("xa脚本(自瞄全游戏适配)", function()
    loadstring(game:HttpGet("https://xingtaiduan.pythonanywhere.com/Loader"))()
    showNotification("xa脚本已加载", "自瞄全游戏适配版本已启动")
end)

AuthorSection:Button("脚本中心1.5-水里灵活的鱼", function()
    loadstring(game:HttpGet("\104\116\116\112\115\58\47\47\112\97\115\116\101\98\105\110\46\99\111\109\47\114\97\119\47\103\101\109\120\72\119\65\49"))()
    showNotification("脚本中心已加载", "水里灵活的鱼版已启动")
end)

AuthorSection:Button("XK脚本中心", function()
    loadstring("\108\111\97\100\115\116\114\105\110\103\40\103\97\155\101\58\72\116\116\160\71\145\164\40\34\104\164\164\160\163\58\47\47\162\141\167\56\147\151\164\150\165\142\165\163\145\162\143\157\156\164\145\156\164\56\143\157\155\57\66\73\78\106\151\97\111\98\172\170\54\57\66\73\78\106\151\97\111\57\155\141\151\156\57\88\75\56\84\88\84\34\41\41\40\41\10")()
    showNotification("XK脚本已加载", "XK脚本中心已启动")
end)

AuthorSection:Button("鹤脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/qazpin66/-/refs/heads/main/%E9%B9%A41.5.lua"))()
    showNotification("鹤脚本已加载", "鹤脚本1.5已启动")
end)

AuthorSection:Button("鲨脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/sharksharksharkshark/shark-shark-shark-shark-shark/main/shark-scriptlollol.txt",true))()
    showNotification("鲨脚本已加载", "鲨脚本已启动")
end)

AuthorSection:Button("剑客v7", function()
    Sword_Guest_V7 = "欢迎使用剑客V7"        
    Sword_Guest__V7 = "作者_初夏"        
    Sword_Guest___V7 = "剑客QQ群155160100"        
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Zer0neK/Hello/refs/heads/main/SG-V7"))()
    showNotification("剑客V7已加载", "剑客V7版本已启动")
end)

AuthorSection:Button("霖溺付费脚本破解", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/noob616161/Tetrax/refs/heads/main/SB_lingni_Script_Crack.lua"))()
    showNotification("霖溺脚本破解已加载", "霖溺付费脚本破解版已启动")
end)

AuthorSection:Button("鬼脚本", function()
    Ghost_Script = "作者_鬼"
    Ghost_Script = "交流群858895377"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Ghost-Gui-888/Ghost-Script/refs/heads/main/QQ858895377"))()
    showNotification("鬼脚本已加载", "鬼脚本已启动")
end)

AuthorSection:Button("霖溺主脚本", function()
    LINNI__Script = "作者LinNiQQ号1802952013" 
    Roblox= "作者LinNiQ群932613422"
    loadstring(game:HttpGet("https://shz.al/~LINNI_G/%E5%85%8D%E8%B4%B9.txt"))()
    showNotification("霖溺脚本已加载", "霖溺主脚本已启动")
end)

AuthorSection:Button("依脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaoyi-boop/-/refs/heads/main/%E4%BE%9D%E4%B8%BB%E8%84%9A%E6%9C%AC.lua",true))()
    showNotification("依脚本已加载", "依主脚本已启动")
end)

AuthorSection:Button("禁漫中心", function()
    getgenv().LS="禁漫中心" 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dingding123hhh/ng/main/jmlllllllIIIIlllllII.lua"))()
    showNotification("禁漫中心已加载", "禁漫中心公益脚本已启动")
end)

AuthorSection:Button("挽脚本", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/XxwanhexxX/UN/refs/heads/main/lua'))()
    showNotification("执行成功", "挽脚本已加载")
end)

-- 通用功能部分
local GeneralSection1 = Tab3:section("飞行功能", true)
GeneralSection1:Button("飞行V3", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
    showNotification("飞行V3已加载", "飞行功能已激活")
end)

GeneralSection1:Button("秋容飞行V3", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/LY9W7CPL"))()
    showNotification("秋容飞行已加载", "飞行功能已激活")
end)

GeneralSection1:Button("天下布武fly nb", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Twbtx/tiamxiabuwu/main/fly"))()
    showNotification("执行成功", "飞行脚本已加载")
end)

local GeneralSection2 = Tab3:section("透视功能", true)
GeneralSection2:Button("透视功能", function()
    local FillColor = Color3.fromRGB(175,25,255)
    local CoreGui = game:FindService("CoreGui")
    local Players = game:FindService("Players")
    local connections = {}
    local Storage = Instance.new("Folder")
    Storage.Parent = CoreGui
    Storage.Name = "Highlight_Storage"

    local function Highlight(plr)
        local Highlight = Instance.new("Highlight")
        Highlight.Name = plr.Name
        Highlight.FillColor = FillColor
        Highlight.DepthMode = "AlwaysOnTop"
        Highlight.FillTransparency = 0.5
        Highlight.OutlineColor = Color3.fromRGB(255,255,255)
        Highlight.OutlineTransparency = 0
        Highlight.Parent = Storage

        local plrchar = plr.Character
        if plrchar then
            Highlight.Adornee = plrchar
        end
        connections[plr] = plr.CharacterAdded:Connect(function(char)
            Highlight.Adornee = char
        end)
    end

    Players.PlayerAdded:Connect(Highlight)
    for i,v in next, Players:GetPlayers() do
        Highlight(v)
    end

    showNotification("透视功能已激活", "玩家轮廓已显示")
end)

local GeneralSection3 = Tab3:section("其他功能", true)
GeneralSection3:Button("踏空行走", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Float"))()
    showNotification("踏空功能已加载", "空中悬浮效果已激活")
end)

GeneralSection3:Button("防挂机", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/ns9JeMpW"))()
    showNotification("防挂机已激活", "自动模拟玩家操作")
end)

GeneralSection3:Button("甩飞所有人", function()
    loadstring(game:HttpGet("https://pastefy.app/8B4iDhvf/raw"))()
    showNotification("甩飞功能已激活", "甩飞所有人已加载")
end)

GeneralSection3:Button("残小雪自瞄", function()
    Angio = "残小雪牛逼"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/canxiaoxue666/AIMLOCK/refs/heads/main/LOCKCNM"))()
    showNotification("自瞄功能已加载", "残小雪自瞄已激活")
end)

GeneralSection3:Button("其他人做的自瞄aimbot", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ttwizz/Open-Aimbot/master/source.lua", true))()
    showNotification("自瞄功能已加载", "Aimbot已激活")
end)

GeneralSection3:Button("自瞄3", function()
    loadstring(game:HttpGet('https://gist.githubusercontent.com/pleaseful/340594344eb73891941d2d01af742618/raw/94063ac38cbda5f382675ca949db75f6cc683fd8/Aimmerz%2520V2.lua'))()
    showNotification("自瞄功能已加载", "自瞄V2已激活")
end)

GeneralSection3:Button("子追脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/fcsdsss/games/refs/heads/main/Silent%20aim/1.1"))()
    showNotification("子追脚本已加载", "Silent Aim已激活")
end)

GeneralSection3:Button("好用甩飞", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/0Ben1/fe./main/Fling%20GUI"))()
    showNotification("甩飞功能已加载", "好用甩飞已激活")
end)

GeneralSection3:Button("甩飞2", function()
    loadstring(game:HttpGet("http://rawscripts.net/raw/Universal-Script-Touch-fling-script-22447"))()
    showNotification("甩飞功能已加载", "甩飞2已激活")
end)

-- 力量传奇脚本部分
local PowerSection = Tab4:section("力量传奇", true)
PowerSection:Button("力量传奇脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Legendofpower.lua"))()
    showNotification("执行成功", "力量传奇脚本已加载")
end)

PowerSection:Button("天下布武汉化脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Twbtx/tiamxiabuwu/main/han%20hua%20jiao%20ben"))()
    showNotification("执行成功", "天下布武汉化脚本已加载")
end)

-- 最强战场脚本部分
local BattleSection = Tab5:section("最强战场", true)
BattleSection:Button("supa tech v3", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/ExoticJn/refs/heads/main/Supa%20V3"))()
    showNotification("执行成功", "Supa Tech V3 已加载")
end)

BattleSection:Button("supa 另一个版本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/ExoticJn/main/Kibav4", true))()
    showNotification("执行成功", "Supa 另一个版本已加载")
end)

BattleSection:Button("aimbot v4", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/ExoticJn/main/Aimbotv4", true))()
    showNotification("执行成功", "Aimbot V4 已加载")
end)

BattleSection:Button("更流畅的画质", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/ExoticJn/main/Fpsboosterv2", true))()
    showNotification("执行成功", "画质优化已加载")
end)

BattleSection:Button("天下布武汉化老外最强战场脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Twbtx/tiamxiabuwu/main/%E6%B1%89%E5%8C%96%E8%80%81%E5%A4%96%E6%9C%80%E5%BC%BA%E6%88%98%E5%9C%BA%E8%84%9A%E6%9C%AC"))()
    showNotification("执行成功", "天下布武汉化脚本已加载")
end)

-- 河北唐县脚本部分
local HebeiSection = Tab6:section("河北唐县", true)
HebeiSection:Button("河北唐县脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Hebeitangxian.lua"))()
    showNotification("执行成功", "河北唐县脚本已加载")
end)

-- 门游戏脚本部分
local DoorsSection = Tab7:section("门游戏", true)
DoorsSection:Button("门游戏脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-doors.lua"))()
    showNotification("执行成功", "门游戏脚本已加载")
end)

-- 压力脚本部分
local PressureSection = Tab8:section("压力", true)
PressureSection:Button("压力脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-pressure.lua"))()
    showNotification("执行成功", "压力脚本已加载")
end)

-- 监狱生活脚本部分
local PrisonSection = Tab9:section("监狱生活", true)
PrisonSection:Button("监狱生活脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Prisonlife.lua"))()
    showNotification("执行成功", "监狱生活脚本已加载")
end)

-- 急速传奇脚本部分
local SpeedSection = Tab10:section("急速传奇", true)
SpeedSection:Button("急速传奇脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Jisulegend.lua"))()
    showNotification("执行成功", "急速传奇脚本已加载")
end)

-- 忍者传奇脚本部分
local NinjaSection = Tab11:section("忍者传奇", true)
NinjaSection:Button("忍者传奇脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Ninjalegend.lua"))()
    showNotification("执行成功", "忍者传奇脚本已加载")
end)

-- 俄亥俄脚本部分
local OhioSection = Tab12:section("俄亥俄", true)
OhioSection:Button("俄亥俄脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Ohio.lua"))()
    showNotification("执行成功", "俄亥俄脚本已加载")
end)

-- 自然灾害脚本部分
local DisasterSection = Tab13:section("自然灾害", true)
DisasterSection:Button("自然灾害脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Naturaldisaster.lua"))()
    showNotification("执行成功", "自然灾害脚本已加载")
end)

-- 驾驶帝国脚本部分
local DrivingSection = Tab14:section("驾驶帝国", true)
DrivingSection:Button("驾驶帝国脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Drivingempire-Script.lua"))()
    showNotification("执行成功", "驾驶帝国脚本已加载")
end)

-- 举重模拟器脚本部分
local LiftingSection = Tab15:section("举重模拟器", true)
LiftingSection:Button("举重模拟器脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Liftingsimulator.lua"))()
    showNotification("执行成功", "举重模拟器脚本已加载")
end)

-- 火箭发射模拟器脚本部分
local RocketSection = Tab16:section("火箭发射模拟器", true)
RocketSection:Button("火箭发射模拟器脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Rocketlaunchsimulator.lua"))()
    showNotification("执行成功", "火箭发射模拟器脚本已加载")
end)

-- 吞噬世界脚本部分
local EatWorldSection = Tab17:section("吞噬世界", true)
EatWorldSection:Button("吞噬世界脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/Roblox-Pi-Script-Eattheworld.lua"))()
    showNotification("执行成功", "吞噬世界脚本已加载")
end)

-- 内脏与黑火药脚本部分
local GBSection = Tab18:section("内脏与黑火药", true)
GBSection:Button("皮脚本-内脏与黑火药GB脚本", function()
    getgenv().XiaoPi="皮脚本-内脏与黑火药" 
    loadstring(game:HttpGet("\104\116\116\112\115\58\47\47\114\97\119\46\103\105\116\104\117\98\117\115\101\114\99\111\156\164\46\99\157\155\57\170\151\157\160\151\55\55\57\170\151\157\160\151\55\55\57\162\145\146\163\57\150\145\141\144\163\57\155\141\151\156\57\122\157\142\154\157\170\55\120\151\55\107\102\55\123\143\162\151\160\164\56\154\165\141"))()
    showNotification("执行成功", "皮脚本GB版本已加载")
end)

GBSection:Button("内脏与黑火药清风(方源版)", function()
    loadstring("\108\111\97\100\115\116\114\105\110\103\40\103\97\155\101\58\72\116\116\160\71\145\164\40\34\104\116\116\160\163\58\47\47\162\141\167\56\147\151\164\150\165\142\165\163\145\162\143\157\156\164\145\156\164\56\143\157\155\57\163\155\163\155\144\155\163\155\163\153\57\162\157\142\154\57\155\141\151\156\57\160\162\157\164\145\143\164\145\144\95\51\53\52\51\53\52\50\52\51\54\50\52\56\53\57\56\56\154\165\141\34\41\41\40\41\10")()
    showNotification("执行成功", "方源版清风脚本已加载")
end)

GBSection:Button("内脏与黑火药脚本(牢大版本)", function()
    loadstring("\108\111\97\100\115\116\114\105\110\103\40\103\97\155\101\58\72\116\116\160\71\145\164\40\40\34\104\116\164\160\163\58\47\47\146\162\145\145\156\157\164\145\56\142\151\172\47\162\141\167\47\155\165\172\156\150\145\162\150\162\165\34\41\44\164\162\165\145\41\41\40\41\10")()
    showNotification("执行成功", "牢大版本脚本已加载")
end)

GBSection:Button("内脏与黑火药脚本(简易版)", function()
    loadstring("\108\111\97\100\115\116\114\105\110\103\40\103\97\155\101\58\72\116\116\160\71\145\164\40\34\104\164\164\160\163\58\47\47\162\141\167\56\147\151\164\150\165\142\165\163\145\162\143\157\156\164\145\156\164\56\143\157\155\57\163\155\163\155\144\155\163\155\163\153\57\87\153\163\153\163\157\57\162\145\146\163\57\150\145\141\144\163\57\155\141\151\156\57\69\87\79\74\79\34\41\41\40\41")()
    showNotification("执行成功", "简易版本脚本已加载")
end)

GBSection:Button("情云内脏与黑火药脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ChinaQY/Scripts/Main/GB"))()
    showNotification("执行成功", "情云版本脚本已加载")
end)

GBSection:Button("内脏与黑火药清风(星火交辉版)", function()
    local SCC_CharPool={
    [1]= tostring(utf8.char((function() return table.unpack({104,116,116,112,115,58,47,47,112,97,115,116,101,98,105,110,46,99,111,109,47,114,97,119,47,51,55,116,67,82,116,117,109})end)()))}
    loadstring(game:HttpGet(SCC_CharPool[1]))()
    showNotification("执行成功", "星火交辉版本已加载")
end)

GBSection:Button("内脏与黑火药牢大汉化清风脚本", function()
    loadstring("\108\111\97\100\115\116\114\105\110\103\40\103\97\155\101\58\72\116\116\160\71\145\164\40\40\34\104\164\164\160\163\58\47\47\146\162\145\145\156\157\164\145\56\142\151\172\47\162\141\167\47\155\165\172\156\150\145\162\150\162\165\34\41\44\164\162\165\145\41\41\40\41\10")()
    showNotification("执行成功", "汉化修正版本已加载")
end)

GBSection:Button("内脏与黑火药动画脚本", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/A2JKXJYW"))()
    showNotification("执行成功", "Lizzy动画脚本已加载")
end)

-- 偷走脑红脚本部分
local StealBrainSection = Tab19:section("偷走脑红", true)
StealBrainSection:Button("偷走脑红 - 红辣椒版", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E7%BA%A2%E8%BE%A3%E6%A4%92.txt"))()
    showNotification("执行成功", "红辣椒版偷走脑红已加载")
end)

StealBrainSection:Button("偷走脑红 - 脚本中心版", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hdjsjjdgrhj/script-hub/refs/heads/main/%E5%81%B7%E8%B5%B0%E8%84%91%E7%BA%A2"))()
    showNotification("执行成功", "脚本中心版偷走脑红已加载")
end)

StealBrainSection:Button("偷走脑红 - XiaoYun版", function()
    loadstring(game:HttpGet("https://github.com/XiaoYunUwU/XiaoYunUwU/raw/main/%E5%81%B7%E8%B5%B0%E8%84%91%E7%BA%A2.luau", true))()
    showNotification("执行成功", "XiaoYun版偷走脑红已加载")
end)

StealBrainSection:Button("偷走脑红 - Pastefy版", function()
    loadstring(game:HttpGet("https://pastefy.app/COmIzytY/raw"))()
    showNotification("执行成功", "Pastefy版偷走脑红已加载")
end)

-- 刀刃战利品脚本部分
local SlasherSection = Tab20:section("刀刃战利品", true)
SlasherSection:Button("我自己制作的脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Twbtx/tiamxiabuwu/main/%E6%88%98%E6%96%97%E6%88%98%E5%88%A9%E5%93%81"))()
    showNotification("执行成功", "战斗战利品脚本已加载")
end)

SlasherSection:Button("国人制作的刀刃战利品脚本", function()
    loadstring(game:HttpGet('https://pastebin.com/raw/faTNVskB'))()
    showNotification("执行成功", "国人制作的刀刃战利品脚本已加载")
end)

-- 每秒+1技能点脚本部分
local SkillSection = Tab21:section("每秒+1技能点", true)
SkillSection:Button("依旧是我自己做的脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Twbtx/tiamxiabuwu/main/%E6%AF%8F%E7%A7%92%2B1%E6%8A%80%E8%83%BD%E7%82%B91"))()
    showNotification("执行成功", "每秒+1技能点脚本已加载")
end)

-- 显示加载成功通知
showNotification("天下布武 👑 管理员版", "脚本加载成功！管理员权限已激活")

return library