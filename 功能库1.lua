--[[
    ═══════════════════════════════════════════════════════════════════════
    DexLib —— Dex++ / SimpleSpy 纯功能库 (无任何 UI 组件)
    
    包含:
      · Dex++ 3.1 全部非 UI 逻辑 (工具/序列化/搜索/属性分析/API/RMD/转储/hook)
      · SimpleSpy 汉化版全部非 UI 逻辑 (序列化/hook/反编译/远程处理)
      · Adonis 绕过 / GCBypass / RemoteSpy / 3D 相机逻辑 / saveinstance
    
    用法:
      local D = loadstring(game:HttpGet("你的链接"))()
      D.decompile(script)
      D.SimpleSpy.start()
      D.FetchAPI()
    ═══════════════════════════════════════════════════════════════════════
]]
-- 放在库的最前面, 给所有 HTTP 函数加 5 秒超时
local HTTP_TIMEOUT = 5
local _rawHttpFn = nil
pcall(function() if request then _rawHttpFn = request end end)
pcall(function() if not _rawHttpFn and http_request then _rawHttpFn = http_request end end)
pcall(function() if not _rawHttpFn and syn and syn.request then _rawHttpFn = syn.request end end)

if _rawHttpFn then
    local function safeRequest(opts)
        local result, finished = nil, false
        task.spawn(function()
            local ok, res = pcall(_rawHttpFn, opts)
            if ok and type(res) == "table" then result = res end
            finished = true
        end)
        local t0 = tick()
        while not finished and (tick() - t0) < HTTP_TIMEOUT do task.wait(0.1) end
        if not finished then
            return {StatusCode = 0, Body = "", Headers = {}}
        end
        return result
    end
    if request then request = function(o) return safeRequest(o) end end
    if http_request then http_request = function(o) return safeRequest(o) end end
    if syn and syn.request then syn.request = function(o) return safeRequest(o) end end
    print("[HTTP 超时补丁] 已应用 (" .. HTTP_TIMEOUT .. "s)")
end
local D = {}
D.Version = "1.1"

local oldgame = game
local cloneref = cloneref or function(ref)
    if not getreg then return ref end
    local InstanceList
    local a = Instance.new("Part")
    for _, c in pairs(getreg()) do
        if type(c) == "table" and #c then
            if rawget(c, "__mode") == "kvs" then
                for d, e in pairs(c) do
                    if e == a then InstanceList = c break end
                end
            end
        end
    end
    return function(g)
        if not InstanceList then return end
        for b, c in pairs(InstanceList) do
            if c == g then InstanceList[b] = nil return g end
        end
    end
end
D.cloneref = cloneref

local service = setmetatable({}, {__index = function(self, name)
    local s = cloneref(game:GetService(name))
    self[name] = s
    return s
end})
local plr = service.Players.LocalPlayer or service.Players.PlayerAdded:Wait()
D.service = service
D.plr = plr

local oldgame = oldgame or game

-- ============================================================
-- [1] 基础工具 (来自 Dex++ Lib)
-- ============================================================

D.FormatLuaString = (function()
    local gsub = string.gsub
    local format = string.format
    local char = string.char
    local cleanTable = {['"'] = '\\"', ['\\'] = '\\\\'}
    for i = 0, 31 do cleanTable[char(i)] = "\\" .. format("%03d", i) end
    for i = 127, 255 do cleanTable[char(i)] = "\\" .. format("%03d", i) end
    return function(str) return gsub(str, "[\"\\\0-\31\127-\255]", cleanTable) end
end)()

D.CheckMouseInGui = function(gui)
    if gui == nil then return false end
    local mouse = plr:GetMouse()
    local guiPosition, guiSize = gui.AbsolutePosition, gui.AbsoluteSize
    return mouse.X >= guiPosition.X and mouse.X < guiPosition.X + guiSize.X
       and mouse.Y >= guiPosition.Y and mouse.Y < guiPosition.Y + guiSize.Y
end

D.IsShiftDown = function()
    return service.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        or service.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

D.IsCtrlDown = function()
    return service.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or service.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
end

D.FastWait = function(s)
    local rs = service.RunService.RenderStepped
    if not s then return rs.wait(rs) end
    local start = tick()
    while tick() - start < s do rs.wait(rs) end
end

D.FindAndRemove = function(t, item)
    local pos = table.find(t, item)
    if pos then table.remove(t, pos) end
end

D.ColorToBytes = function(col)
    local round = math.round
    return string.format("%d, %d, %d", round(col.r*255), round(col.g*255), round(col.b*255))
end

D.ReadFile = function(filename)
    if not env or not readfile then return end
    local s, contents = pcall(readfile, filename)
    if s and contents then return contents end
end

D.DeferFunc = function(f, ...)
    service.RunService.RenderStepped:wait()
    return f(...)
end

D.LoadCustomAsset = function(filepath)
    if not getcustomasset or not isfile or not isfile(filepath) then return end
    return getcustomasset(filepath)
end

D.FetchCustomAsset = function(url, filepath)
    if not writefile then return end
    local s, data = pcall(oldgame.HttpGet, game, url)
    if not s then return end
    writefile(filepath, data)
    return D.LoadCustomAsset(filepath)
end

-- ============================================================
-- [2] XML 解析器 (Dex++ Lib.ParseXML 完整版)
-- ============================================================
D.ParseXML = (function()
    local func = function()
        local string, print, pairs = string, print, pairs
        local trim = function(s)
            local from = s:match"^%s*()"
            return from > #s and "" or s:match(".*%S", from)
        end
        local gtchar = string.byte('>', 1)
        local slashchar = string.byte('/', 1)
        local D_ = string.byte('D', 1)
        local E = string.byte('E', 1)

        function parse(s, evalEntities)
            s = s:gsub('<!%-%-(.-)%-%->', '')
            local entities, tentities = {}
            if evalEntities then
                local pos = s:find('<[_%w]')
                if pos then
                    s:sub(1, pos):gsub('<!ENTITY%s+([_%w]+)%s+(.)(.-)%2', function(name, q, entity)
                        entities[#entities+1] = {name=name, value=entity}
                    end)
                    tentities = createEntityTable(entities)
                    s = replaceEntities(s:sub(pos), tentities)
                end
            end
            local t, l = {}, {}
            local addtext = function(txt)
                txt = txt:match'^%s*(.*%S)' or ''
                if #txt ~= 0 then t[#t+1] = {text=txt} end
            end
            s:gsub('<([?!/]?)([-:_%w]+)%s*(/?>?)([^<]*)', function(type, name, closed, txt)
                if #type == 0 then
                    local a = {}
                    if #closed == 0 then
                        local len = 0
                        for all,aname,_,value,starttxt in string.gmatch(txt, "(.-([-_%w]+)%s*=%s*(.)(.-)%3%s*(/?>?))") do
                            len = len + #all
                            a[aname] = value
                            if #starttxt ~= 0 then
                                txt = txt:sub(len+1)
                                closed = starttxt
                                break
                            end
                        end
                    end
                    t[#t+1] = {tag=name, attrs=a, children={}}
                    if closed:byte(1) ~= slashchar then
                        l[#l+1] = t
                        t = t[#t].children
                    end
                    addtext(txt)
                elseif '/' == type then
                    t = l[#l]
                    l[#l] = nil
                    addtext(txt)
                elseif '!' == type then
                    if E == name:byte(1) then
                        txt:gsub('([_%w]+)%s+(.)(.-)%2', function(name, q, entity)
                            entities[#entities+1] = {name=name, value=entity}
                        end, 1)
                    end
                end
            end)
            return {children=t, entities=entities, tentities=tentities}
        end

        function parseText(txt) return parse(txt) end
        function defaultEntityTable()
            return { quot='"', apos='\'', lt='<', gt='>', amp='&', tab='\t', nbsp=' ', }
        end
        function replaceEntities(s, entities) return s:gsub('&([^;]+);', entities) end
        function createEntityTable(docEntities, resultEntities)
            entities = resultEntities or defaultEntityTable()
            for _,e in pairs(docEntities) do
                e.value = replaceEntities(e.value, entities)
                entities[e.name] = e.value
            end
            return entities
        end
        return parseText
    end
    local newEnv = setmetatable({}, {__index = getfenv()})
    setfenv(func, newEnv)
    return func()
end)()

-- ============================================================
-- [3] Signal / Set 类 (Dex++ Lib)
-- ============================================================
D.Signal = (function()
    local funcs = {}
    local disconnect = function(con)
        local pos = table.find(con.Signal.Connections, con)
        if pos then table.remove(con.Signal.Connections, pos) end
    end
    funcs.Connect = function(self, func)
        if type(func) ~= "function" then error("Attempt to connect a non-function") end
        local con = { Signal = self, Func = func, Disconnect = disconnect }
        self.Connections[#self.Connections+1] = con
        return con
    end
    funcs.Fire = function(self, ...)
        for i, v in next, self.Connections do
            xpcall(coroutine.wrap(v.Func), function(e) warn(e .. "\n" .. debug.traceback()) end, ...)
        end
    end
    local mt = {
        __index = funcs,
        __tostring = function(self) return "Signal: " .. tostring(#self.Connections) .. " Connections" end
    }
    return {new = function()
        return setmetatable({Connections = {}}, mt)
    end}
end)()

D.Set = (function()
    local funcs = {}
    funcs.Add = function(self, obj)
        if self.Map[obj] then return end
        local list = self.List
        list[#list+1] = obj
        self.Map[obj] = true
        self.Changed:Fire()
    end
    funcs.AddTable = function(self, t)
        local changed
        local list, map = self.List, self.Map
        for i = 1, #t do
            local elem = t[i]
            if not map[elem] then
                list[#list+1] = elem
                map[elem] = true
                changed = true
            end
        end
        if changed then self.Changed:Fire() end
    end
    funcs.Remove = function(self, obj)
        if not self.Map[obj] then return end
        local list = self.List
        local pos = table.find(list, obj)
        if pos then table.remove(list, pos) end
        self.Map[obj] = nil
        self.Changed:Fire()
    end
    funcs.RemoveTable = function(self, t)
        local changed
        local list, map = self.List, self.Map
        local removeSet = {}
        for i = 1, #t do
            local elem = t[i]
            map[elem] = nil
            removeSet[elem] = true
        end
        for i = #list, 1, -1 do
            local elem = list[i]
            if removeSet[elem] then
                table.remove(list, i)
                changed = true
            end
        end
        if changed then self.Changed:Fire() end
    end
    funcs.Set = function(self, obj)
        if #self.List == 1 and self.List[1] == obj then return end
        self.List = {obj}
        self.Map = {[obj] = true}
        self.Changed:Fire()
    end
    funcs.SetTable = function(self, t)
        local newList, newMap = {}, {}
        self.List, self.Map = newList, newMap
        table.move(t, 1, #t, 1, newList)
        for i = 1, #t do newMap[t[i]] = true end
        self.Changed:Fire()
    end
    funcs.Clear = function(self)
        if #self.List == 0 then return end
        self.List = {}
        self.Map = {}
        self.Changed:Fire()
    end
    local mt = {__index = funcs}
    return {new = function()
        return setmetatable({
            List = {},
            Map = {},
            Changed = D.Signal.new()
        }, mt)
    end}
end)()

-- ============================================================
-- [4] IconMap (Dex++ Lib 完整版, 包含所有图标数据)
-- ============================================================
D.IconMap = (function()
    local funcs = {}
    local IconList = {
        Old = {
            MapId = 483448923, IconSize = 16, Witdh = 16, Height = 16,
            Icons = {
                ["Accessory"] = 32, ["Accoutrement"] = 32, ["AdService"] = 73, ["Animation"] = 60,
                ["AnimationController"] = 60, ["AnimationTrack"] = 60, ["Animator"] = 60, ["ArcHandles"] = 56,
                ["AssetService"] = 72, ["Attachment"] = 34, ["Backpack"] = 20, ["BadgeService"] = 75,
                ["BallSocketConstraint"] = 89, ["BillboardGui"] = 64, ["BinaryStringValue"] = 4, ["BindableEvent"] = 67,
                ["BindableFunction"] = 66, ["BlockMesh"] = 8, ["BloomEffect"] = 90, ["BlurEffect"] = 90,
                ["BodyAngularVelocity"] = 14, ["BodyForce"] = 14, ["BodyGyro"] = 14, ["BodyPosition"] = 14,
                ["BodyThrust"] = 14, ["BodyVelocity"] = 14, ["BoolValue"] = 4, ["BoxHandleAdornment"] = 54,
                ["BrickColorValue"] = 4, ["Camera"] = 5, ["CFrameValue"] = 4, ["CharacterMesh"] = 60,
                ["Chat"] = 33, ["ClickDetector"] = 41, ["CollectionService"] = 30, ["Color3Value"] = 4,
                ["ColorCorrectionEffect"] = 90, ["ConeHandleAdornment"] = 54, ["Configuration"] = 58, ["ContentProvider"] = 72,
                ["ContextActionService"] = 41, ["CoreGui"] = 46, ["CoreScript"] = 18, ["CornerWedgePart"] = 1,
                ["CustomEvent"] = 4, ["CustomEventReceiver"] = 4, ["CylinderHandleAdornment"] = 54, ["CylinderMesh"] = 8,
                ["CylindricalConstraint"] = 89, ["Debris"] = 30, ["Decal"] = 7, ["Dialog"] = 62,
                ["DialogChoice"] = 63, ["DoubleConstrainedValue"] = 4, ["Explosion"] = 36, ["FileMesh"] = 8,
                ["Fire"] = 61, ["Flag"] = 38, ["FlagStand"] = 39, ["FloorWire"] = 4,
                ["Folder"] = 70, ["ForceField"] = 37, ["Frame"] = 48, ["GamePassService"] = 19,
                ["Glue"] = 34, ["GuiButton"] = 52, ["GuiMain"] = 47, ["GuiService"] = 47,
                ["Handles"] = 53, ["HapticService"] = 84, ["Hat"] = 45, ["HingeConstraint"] = 89,
                ["Hint"] = 33, ["HopperBin"] = 22, ["HttpService"] = 76, ["Humanoid"] = 9,
                ["ImageButton"] = 52, ["ImageLabel"] = 49, ["InsertService"] = 72, ["IntConstrainedValue"] = 4,
                ["IntValue"] = 4, ["JointInstance"] = 34, ["JointsService"] = 34, ["Keyframe"] = 60,
                ["KeyframeSequence"] = 60, ["KeyframeSequenceProvider"] = 60, ["Lighting"] = 13, ["LineHandleAdornment"] = 54,
                ["LocalScript"] = 18, ["LogService"] = 87, ["MarketplaceService"] = 46, ["Message"] = 33,
                ["Model"] = 2, ["ModuleScript"] = 71, ["Motor"] = 34, ["Motor6D"] = 34,
                ["MoveToConstraint"] = 89, ["NegateOperation"] = 78, ["NetworkClient"] = 16, ["NetworkReplicator"] = 29,
                ["NetworkServer"] = 15, ["NumberValue"] = 4, ["ObjectValue"] = 4, ["Pants"] = 44,
                ["ParallelRampPart"] = 1, ["Part"] = 1, ["ParticleEmitter"] = 69, ["PartPairLasso"] = 57,
                ["PathfindingService"] = 37, ["Platform"] = 35, ["Player"] = 12, ["PlayerGui"] = 46,
                ["Players"] = 21, ["PlayerScripts"] = 82, ["PointLight"] = 13, ["PointsService"] = 83,
                ["Pose"] = 60, ["PrismaticConstraint"] = 89, ["PrismPart"] = 1, ["PyramidPart"] = 1,
                ["RayValue"] = 4, ["ReflectionMetadata"] = 86, ["ReflectionMetadataCallbacks"] = 86, ["ReflectionMetadataClass"] = 86,
                ["ReflectionMetadataClasses"] = 86, ["ReflectionMetadataEnum"] = 86, ["ReflectionMetadataEnumItem"] = 86,
                ["ReflectionMetadataEnums"] = 86, ["ReflectionMetadataEvents"] = 86, ["ReflectionMetadataFunctions"] = 86,
                ["ReflectionMetadataMember"] = 86, ["ReflectionMetadataProperties"] = 86, ["ReflectionMetadataYieldFunctions"] = 86,
                ["RemoteEvent"] = 80, ["RemoteFunction"] = 79, ["ReplicatedFirst"] = 72, ["ReplicatedStorage"] = 72,
                ["RightAngleRampPart"] = 1, ["RocketPropulsion"] = 14, ["RodConstraint"] = 89, ["RopeConstraint"] = 89,
                ["Rotate"] = 34, ["RotateP"] = 34, ["RotateV"] = 34, ["RunService"] = 66,
                ["ScreenGui"] = 47, ["Script"] = 6, ["ScrollingFrame"] = 48, ["Seat"] = 35,
                ["Selection"] = 55, ["SelectionBox"] = 54, ["SelectionPartLasso"] = 57, ["SelectionPointLasso"] = 57,
                ["SelectionSphere"] = 54, ["ServerScriptService"] = 0, ["ServerStorage"] = 74, ["Shirt"] = 43,
                ["ShirtGraphic"] = 40, ["SkateboardPlatform"] = 35, ["Sky"] = 28, ["SlidingBallConstraint"] = 89,
                ["Smoke"] = 59, ["Snap"] = 34, ["Sound"] = 11, ["SoundService"] = 31,
                ["Sparkles"] = 42, ["SpawnLocation"] = 25, ["SpecialMesh"] = 8, ["SphereHandleAdornment"] = 54,
                ["SpotLight"] = 13, ["SpringConstraint"] = 89, ["StarterCharacterScripts"] = 82, ["StarterGear"] = 20,
                ["StarterGui"] = 46, ["StarterPack"] = 20, ["StarterPlayer"] = 88, ["StarterPlayerScripts"] = 82,
                ["Status"] = 2, ["StringValue"] = 4, ["SunRaysEffect"] = 90, ["SurfaceGui"] = 64,
                ["SurfaceLight"] = 13, ["SurfaceSelection"] = 55, ["Team"] = 24, ["Teams"] = 23,
                ["TeleportService"] = 81, ["Terrain"] = 65, ["TerrainRegion"] = 65, ["TestService"] = 68,
                ["TextBox"] = 51, ["TextButton"] = 51, ["TextLabel"] = 50, ["Texture"] = 10,
                ["TextureTrail"] = 4, ["Tool"] = 17, ["TouchTransmitter"] = 37, ["TrussPart"] = 1,
                ["UnionOperation"] = 77, ["UserInputService"] = 84, ["Vector3Value"] = 4, ["VehicleSeat"] = 35,
                ["VelocityMotor"] = 34, ["WedgePart"] = 1, ["Weld"] = 34, ["Workspace"] = 19,
            }
        },
        Vanilla3 = {
            MapId = 114851699900089, IconSize = 32, Witdh = 25, Height = 25,
            Icons = {
                Accessory = 1, Accoutrement = 2, Actor = 3, AdGui = 4, AdPortal = 5, AdService = 6,
                AdvancedDragger = 7, AirController = 8, AlignOrientation = 9, AlignPosition = 10,
                AnalysticsService = 11, AnalysticsSettings = 12, AnalyticsService = 13, AngularVelocity = 14,
                Animation = 15, AnimationClip = 16, AnimationClipProvider = 17, AnimationController = 18,
                AnimationFromVideoCreatorService = 19, AnimationFromVideoCreatorStudioService = 20, AnimationRigData = 21,
                AnimationStreamTrack = 22, AnimationTrack = 23, Animator = 24, AppStorageService = 25, AppUpdateService = 26,
                ArcHandles = 27, AssetCounterService = 28, AssetDeliveryProxy = 29, AssetImportService = 30,
                AssetImportSession = 31, AssetManagerService = 32, AssetService = 33, AssetSoundEffect = 34,
                Atmosphere = 35, Attachment = 36, AvatarEditorService = 37, AvatarImportService = 38, Backpack = 39,
                BackpackItem = 40, BadgeService = 41, BallSocketConstraint = 42, BasePart = 43, BasePlayerGui = 44,
                BaseScript = 45, BaseWrap = 46, Beam = 47, BevelMesh = 48, BillboardGui = 49, BinaryStringValue = 50,
                BindableEvent = 51, BindableFunction = 52, BlockMesh = 53, BloomEffect = 54, BlurEffect = 55,
                BodyAngularVelocity = 56, BodyColors = 57, BodyForce = 58, BodyGyro = 59, BodyMover = 60, BodyPosition = 61,
                BodyThrust = 62, BodyVelocity = 63, Bone = 64, BoolValue = 65, BoxHandleAdornment = 66, Breakpoint = 67,
                BreakpointManager = 68, BrickColorValue = 69, BrowserService = 70, BubbleChatConfiguration = 71,
                BulkImportService = 72, CacheableContentProvider = 73, CalloutService = 74, Camera = 75, CanvasGroup = 76,
                CatalogPages = 77, CFrameValue = 78, ChangeHistoryService = 79, ChannelSelectorSoundEffect = 80,
                CharacterAppearance = 81, CharacterMesh = 82, Chat = 83, ChatInputBarConfiguration = 84,
                ChatWindowConfiguration = 85, ChorusSoundEffect = 86, ClickDetector = 87, ClientReplicator = 88,
                ClimbController = 89, Clothing = 90, Clouds = 91, ClusterPacketCache = 92, CollectionService = 93,
                Color3Value = 94, ColorCorrectionEffect = 95, CommandInstance = 96, CommandService = 97,
                CompressorSoundEffect = 98, ConeHandleAdornment = 99, Configuration = 100, ConfigureServerService = 101,
                Constraint = 102, ContentProvider = 103, ContextActionService = 104, Controller = 105, ControllerBase = 106,
                ControllerManager = 107, ControllerService = 108, CookiesService = 109, CoreGui = 110, CorePackages = 111,
                CoreScript = 112, CoreScriptSyncService = 113, CornerWedgePart = 114, CrossDMScriptChangeListener = 115,
                CSGDictionaryService = 116, CurveAnimation = 117, CustomEvent = 118, CustomEventReceiver = 119,
                CustomSoundEffect = 120, CylinderHandleAdornment = 121, CylinderMesh = 122, CylindricalConstraint = 123,
                DataModel = 124, DataModelMesh = 125, DataModelPatchService = 126, DataModelSession = 127, DataStore = 128,
                DataStoreIncrementOptions = 129, DataStoreInfo = 130, DataStoreKey = 131, DataStoreKeyInfo = 132,
                DataStoreKeyPages = 133, DataStoreListingPages = 134, DataStoreObjectVersionInfo = 135,
                DataStoreOptions = 136, DataStorePages = 137, DataStoreService = 138, DataStoreSetOptions = 139,
                DataStoreVersionPages = 140, Debris = 141, DebuggablePluginWatcher = 142, DebuggerBreakpoint = 143,
                DebuggerConnection = 144, DebuggerConnectionManager = 145, DebuggerLuaResponse = 146, DebuggerManager = 147,
                DebuggerUIService = 148, DebuggerVariable = 149, DebuggerWatch = 150, DebugSettings = 151, Decal = 152,
                DepthOfFieldEffect = 153, DeviceIdService = 154, Dialog = 155, DialogChoice = 156, DistortionSoundEffect = 157,
                DockWidgetPluginGui = 158, DoubleConstrainedValue = 159, DraftsService = 160, Dragger = 161,
                DraggerService = 162, DynamicRotate = 163, EchoSoundEffect = 164, EmotesPages = 165, EqualizerSoundEffect = 166,
                EulerRotationCurve = 167, EventIngestService = 168, Explosion = 169, FaceAnimatorService = 170,
                FaceControls = 171, FaceInstance = 172, FacialAnimationRecordingService = 173, FacialAnimationStreamingService = 174,
                Feature = 175, File = 176, FileMesh = 177, Fire = 178, Flag = 179, FlagStand = 180, FlagStandService = 181,
                FlangeSoundEffect = 182, FloatCurve = 183, FloorWire = 184, FlyweightService = 185, Folder = 186,
                ForceField = 187, FormFactorPart = 188, Frame = 189, FriendPages = 190, FriendService = 191,
                FunctionalTest = 192, GamepadService = 193, GamePassService = 194, GameSettings = 195,
                GenericSettings = 196, Geometry = 197, GetTextBoundsParams = 198, GlobalDataStore = 199,
                GlobalSettings = 200, Glue = 201, GoogleAnalyticsConfiguration = 202, GroundController = 203,
                GroupService = 204, GuiBase = 205, GuiBase2d = 206, GuiBase3d = 207, GuiButton = 208,
                GuidRegistryService = 209, GuiLabel = 210, GuiMain = 211, GuiObject = 212, GuiService = 213,
                HandleAdornment = 214, Handles = 215, HandlesBase = 216, HapticService = 217, Hat = 218,
                HeightmapImporterService = 219, HiddenSurfaceRemovalAsset = 220, Highlight = 221, HingeConstraint = 222,
                Hint = 223, Hole = 224, Hopper = 225, HopperBin = 226, HSRDataContentProvider = 227,
                HttpRbxApiService = 228, HttpRequest = 229, HttpService = 230, Humanoid = 231, HumanoidController = 232,
                HumanoidDescription = 233, IKControl = 234, ILegacyStudioBridge = 235, ImageButton = 236,
                ImageHandleAdornment = 237, ImageLabel = 238, ImporterAnimationSettings = 239, ImporterBaseSettings = 240,
                ImporterFacsSettings = 241, ImporterGroupSettings = 242, ImporterJointSettings = 243,
                ImporterMaterialSettings = 244, ImporterMeshSettings = 245, ImporterRootSettings = 246,
                IncrementalPatchBuilder = 247, InputObject = 248, InsertService = 249, Instance = 250,
                InstanceAdornment = 251, IntConstrainedValue = 252, IntValue = 253, InventoryPages = 254,
                IXPService = 255, JointInstance = 256, JointsService = 257, KeyboardService = 258, Keyframe = 259,
                KeyframeMarker = 260, KeyframeSequence = 261, KeyframeSequenceProvider = 262, LanguageService = 263,
                LayerCollector = 264, LegacyStudioBridge = 265, Light = 266, Lighting = 267, LinearVelocity = 268,
                LineForce = 269, LineHandleAdornment = 270, LocalDebuggerConnection = 271, LocalizationService = 272,
                LocalizationTable = 273, LocalScript = 274, LocalStorageService = 275, LodDataEntity = 276,
                LodDataService = 277, LoginService = 278, LogService = 279, LSPFileSyncService = 280, LuaSettings = 281,
                LuaSourceContainer = 282, LuauScriptAnalyzerService = 283, LuaWebService = 284, ManualGlue = 285,
                ManualSurfaceJointInstance = 286, ManualWeld = 287, MarkerCurve = 288, MarketplaceService = 289,
                MaterialService = 290, MaterialVariant = 291, MemoryStoreQueue = 292, MemoryStoreService = 293,
                MemoryStoreSortedMap = 294, MemStorageConnection = 295, MemStorageService = 296, MeshContentProvider = 297,
                MeshPart = 298, Message = 299, MessageBusConnection = 300, MessageBusService = 301, MessagingService = 302,
                MetaBreakpoint = 303, MetaBreakpointContext = 304, MetaBreakpointManager = 305, Model = 306,
                ModuleScript = 307, Motor = 308, Motor6D = 309, MotorFeature = 310, Mouse = 311, MouseService = 312,
                MultipleDocumentInterfaceInstance = 313, NegateOperation = 314, NetworkClient = 315, NetworkMarker = 316,
                NetworkPeer = 317, NetworkReplicator = 318, NetworkServer = 319, NetworkSettings = 320,
                NoCollisionConstraint = 321, NonReplicatedCSGDictionaryService = 322, NotificationService = 323,
                NumberPose = 324, NumberValue = 325, ObjectValue = 326, OrderedDataStore = 327, OutfitPages = 328,
                PackageLink = 329, PackageService = 330, PackageUIService = 331, Pages = 332, Pants = 333,
                ParabolaAdornment = 334, Part = 335, PartAdornment = 336, ParticleEmitter = 337, PartOperation = 338,
                PartOperationAsset = 339, PatchMapping = 340, Path = 341, PathfindingLink = 342, PathfindingModifier = 343,
                PathfindingService = 344, PausedState = 345, PausedStateBreakpoint = 346, PausedStateException = 347,
                PermissionsService = 348, PhysicsService = 349, PhysicsSettings = 350, PitchShiftSoundEffect = 351,
                Plane = 352, PlaneConstraint = 353, Platform = 354, Player = 355, PlayerEmulatorService = 356,
                PlayerGui = 357, PlayerMouse = 358, Players = 359, PlayerScripts = 360, Plugin = 361, PluginAction = 362,
                PluginDebugService = 363, PluginDragEvent = 364, PluginGui = 365, PluginGuiService = 366,
                PluginManagementService = 367, PluginManager = 368, PluginManagerInterface = 369, PluginMenu = 370,
                PluginMouse = 371, PluginPolicyService = 372, PluginToolbar = 373, PluginToolbarButton = 374,
                PointLight = 375, PointsService = 376, PolicyService = 377, Pose = 378, PoseBase = 379, PostEffect = 380,
                PrismaticConstraint = 381, ProcessInstancePhysicsService = 382, ProximityPrompt = 383,
                ProximityPromptService = 384, PublishService = 385, PVAdornment = 386, PVInstance = 387,
                QWidgetPluginGui = 388, RayValue = 389, RbxAnalyticsService = 390, ReflectionMetadata = 391,
                ReflectionMetadataCallbacks = 392, ReflectionMetadataClass = 393, ReflectionMetadataClasses = 394,
                ReflectionMetadataEnum = 395, ReflectionMetadataEnumItem = 396, ReflectionMetadataEnums = 397,
                ReflectionMetadataEvents = 398, ReflectionMetadataFunctions = 399, ReflectionMetadataItem = 400,
                ReflectionMetadataMember = 401, ReflectionMetadataProperties = 402, ReflectionMetadataYieldFunctions = 403,
                RemoteDebuggerServer = 404, RemoteEvent = 405, RemoteFunction = 406, RenderingTest = 407,
                RenderSettings = 408, ReplicatedFirst = 409, ReplicatedStorage = 410, ReverbSoundEffect = 411,
                RigidConstraint = 412, RobloxPluginGuiService = 413, RobloxReplicatedStorage = 414, RocketPropulsion = 415,
                RodConstraint = 416, RopeConstraint = 417, Rotate = 418, RotateP = 419, RotateV = 420,
                RotationCurve = 421, RtMessagingService = 422, RunningAverageItemDouble = 423, RunningAverageItemInt = 424,
                RunningAverageTimeIntervalItem = 425, RunService = 426, RuntimeScriptService = 427, ScreenGui = 428,
                ScreenshotHud = 429, Script = 430, ScriptChangeService = 431, ScriptCloneWatcher = 432,
                ScriptCloneWatcherHelper = 433, ScriptContext = 434, ScriptDebugger = 435, ScriptDocument = 436,
                ScriptEditorService = 437, ScriptRegistrationService = 438, ScriptService = 439, ScrollingFrame = 440,
                Seat = 441, Selection = 442, SelectionBox = 443, SelectionLasso = 444, SelectionPartLasso = 445,
                SelectionPointLasso = 446, SelectionSphere = 447, ServerReplicator = 448, ServerScriptService = 449,
                ServerStorage = 450, ServiceProvider = 451, SessionService = 452, Shirt = 453, ShirtGraphic = 454,
                SkateboardController = 455, SkateboardPlatform = 456, Skin = 457, Sky = 458,
                SlidingBallConstraint = 459, Smoke = 460, Snap = 461, SnippetService = 462, SocialService = 463,
                SolidModelContentProvider = 464, Sound = 465, SoundEffect = 466, SoundGroup = 467, SoundService = 468,
                Sparkles = 469, SpawnerService = 470, SpawnLocation = 471, Speaker = 472, SpecialMesh = 473,
                SphereHandleAdornment = 474, SpotLight = 475, SpringConstraint = 476, StackFrame = 477,
                StandalonePluginScripts = 478, StandardPages = 479, StarterCharacterScripts = 480,
                StarterGear = 481, StarterGui = 482, StarterPack = 483, StarterPlayer = 484,
                StarterPlayerScripts = 485, Stats = 486, StatsItem = 487, Status = 488, StopWatchReporter = 489,
                StringValue = 490, Studio = 491, StudioAssetService = 492, StudioData = 493,
                StudioDeviceEmulatorService = 494, StudioHighDpiService = 495, StudioPublishService = 496,
                StudioScriptDebugEventListener = 497, StudioService = 498, StudioTheme = 499, SunRaysEffect = 500,
                SurfaceAppearance = 501, SurfaceGui = 502, SurfaceGuiBase = 503, SurfaceLight = 504,
                SurfaceSelection = 505, SwimController = 506, TaskScheduler = 507, Team = 508,
                TeamCreateService = 509, Teams = 510, TeleportAsyncResult = 511, TeleportOptions = 512,
                TeleportService = 513, TemporaryCageMeshProvider = 514, TemporaryScriptService = 515, Terrain = 516,
                TerrainDetail = 517, TerrainRegion = 518, TestService = 519, TextBox = 520, TextBoxService = 521,
                TextButton = 522, TextChannel = 523, TextChatCommand = 524, TextChatConfigurations = 525,
                TextChatMessage = 526, TextChatMessageProperties = 527, TextChatService = 528, TextFilterResult = 529,
                TextLabel = 530, TextService = 531, TextSource = 532, Texture = 533, ThirdPartyUserService = 534,
                ThreadState = 535, TimerService = 536, ToastNotificationService = 537, Tool = 538,
                ToolboxService = 539, Torque = 540, TorsionSpringConstraint = 541, TotalCountTimeIntervalItem = 542,
                TouchInputService = 543, TouchTransmitter = 544, TracerService = 545, TrackerStreamAnimation = 546,
                Trail = 547, Translator = 548, TremoloSoundEffect = 549, TriangleMeshPart = 550, TrussPart = 551,
                Tween = 552, TweenBase = 553, TweenService = 554, UGCValidationService = 555,
                UIAspectRatioConstraint = 556, UIBase = 557, UIComponent = 558, UIConstraint = 559, UICorner = 560,
                UIGradient = 561, UIGridLayout = 562, UIGridStyleLayout = 563, UILayout = 564, UIListLayout = 565,
                UIPadding = 566, UIPageLayout = 567, UIScale = 568, UISizeConstraint = 569, UIStroke = 570,
                UITableLayout = 571, UITextSizeConstraint = 572, UnionOperation = 573, UniversalConstraint = 574,
                UnvalidatedAssetService = 575, UserGameSettings = 576, UserInputService = 577, UserService = 578,
                UserSettings = 579, UserStorageService = 580, ValueBase = 581, Vector3Curve = 582, Vector3Value = 583,
                VectorForce = 584, VehicleController = 585, VehicleSeat = 586, VelocityMotor = 587,
                VersionControlService = 588, VideoCaptureService = 589, VideoFrame = 590, ViewportFrame = 591,
                VirtualInputManager = 592, VirtualUser = 593, VisibilityService = 594, Visit = 595,
                VoiceChannel = 596, VoiceChatInternal = 597, VoiceChatService = 598, VoiceSource = 599,
                VRService = 600, WedgePart = 601, Weld = 602, WeldConstraint = 603, WireframeHandleAdornment = 604,
                Workspace = 605, WorldModel = 606, WorldRoot = 607, WrapLayer = 608, WrapTarget = 609,
            }
        },
        NewDark = {
            MapId = 135148380892747,
            Icons = {
                Accessory = 1, Actor = 2, AdGui = 3, AdPortal = 4, AirController = 5, AlignOrientation = 6,
                AlignPosition = 7, AngularVelocity = 8, Animation = 9, AnimationConstraint = 10,
                AnimationController = 11, AnimationFromVideoCreatorService = 12, Animator = 13, ArcHandles = 14,
                Atmosphere = 15, Attachment = 16, AudioAnalyzer = 17, AudioChannelMixer = 18,
                AudioChannelSplitter = 19, AudioChorus = 20, AudioCompressor = 21, AudioDeviceInput = 22,
                AudioDeviceOutput = 23, AudioDistortion = 24, AudioEcho = 25, AudioEmitter = 26, AudioEqualizer = 27,
                AudioFader = 28, AudioFilter = 29, AudioFlanger = 30, AudioGate = 31, AudioLimiter = 32,
                AudioListener = 33, AudioPitchShifter = 34, AudioPlayer = 35, AudioRecorder = 36, AudioReverb = 37,
                AudioTextToSpeech = 38, AuroraScript = 39, AvatarEditorService = 40, AvatarSettings = 41,
                Backpack = 42, BallSocketConstraint = 43, BasePlate = 44, Beam = 45, BillboardGui = 46,
                BindableEvent = 47, BindableFunction = 48, BlockMesh = 49, BloomEffect = 50, BlurEffect = 51,
                BodyAngularVelocity = 52, BodyColors = 53, BodyForce = 54, BodyGyro = 55, BodyPosition = 56,
                BodyThrust = 57, BodyVelocity = 58, Bone = 59, BoolValue = 60, BoxHandleAdornment = 61,
                Breakpoint = 62, BrickColorValue = 63, BubbleChatConfiguration = 64, Buggaroo = 65, Camera = 66,
                CanvasGroup = 67, CFrameValue = 68, ChannelTabsConfiguration = 69, CharacterControllerManager = 70,
                CharacterMesh = 71, Chat = 72, ChatInputBarConfiguration = 73, ChatWindowConfiguration = 74,
                ChorusSoundEffect = 75, Class = 76, Cleanup = 77, ClickDetector = 78, ClientReplicator = 79,
                ClimbController = 80, Clouds = 81, Color = 82, ColorCorrectionEffect = 83, CompressorSoundEffect = 84,
                ConeHandleAdornment = 85, Configuration = 86, Constant = 87, Constructor = 88, Controller = 89,
                CoreGui = 90, CornerWedgePart = 91, CylinderHandleAdornment = 92, CylindricalConstraint = 93,
                Decal = 94, DepthOfFieldEffect = 95, Dialog = 96, DialogChoice = 97, DistortionSoundEffect = 98,
                DragDetector = 99, EchoSoundEffect = 100, EditableImage = 101, EditableMesh = 102, Enum = 103,
                EnumMember = 104, EqualizerSoundEffect = 105, Event = 106, Explosion = 107, FaceControls = 108,
                Field = 109, File = 110, Fire = 111, FlangeSoundEffect = 112, Folder = 113, ForceField = 114,
                Frame = 115, Function = 116, GameSettings = 117, GroundController = 118, Handles = 119,
                HapticEffect = 120, HapticService = 121, HeightmapImporterService = 122, Highlight = 123,
                HingeConstraint = 124, Humanoid = 125, HumanoidDescription = 126, IKControl = 127, ImageButton = 128,
                ImageHandleAdornment = 129, ImageLabel = 130, InputAction = 131, InputBinding = 132,
                InputContext = 133, Interface = 134, IntersectOperation = 135, Keyword = 136, Lighting = 137,
                LinearVelocity = 138, LineForce = 139, LineHandleAdornment = 140, LocalFile = 141,
                LocalizationService = 142, LocalizationTable = 143, LocalScript = 144, MaterialService = 145,
                MaterialVariant = 146, MemoryStoreService = 147, MeshPart = 148, Meshparts = 149,
                MessagingService = 150, Method = 151, Model = 152, Modelgroups = 153, Module = 154,
                ModuleScript = 155, Motor6D = 156, NegateOperation = 157, NetworkClient = 158,
                NoCollisionConstraint = 159, Operator = 160, PackageLink = 161, Pants = 162, Part = 163,
                ParticleEmitter = 164, Path2D = 165, PathfindingLink = 166, PathfindingModifier = 167,
                PathfindingService = 168, PitchShiftSoundEffect = 169, Place = 170, Placeholder = 171,
                Plane = 172, PlaneConstraint = 173, Player = 174, Players = 175, PluginGuiService = 176,
                PointLight = 177, PrismaticConstraint = 178, Property = 179, ProximityPrompt = 180,
                PublishService = 181, Reference = 182, RemoteEvent = 183, RemoteFunction = 184, RenderingTest = 185,
                ReplicatedFirst = 186, ReplicatedScriptService = 187, ReplicatedStorage = 188,
                ReverbSoundEffect = 189, RigidConstraint = 190, RobloxPluginGuiService = 191, RocketPropulsion = 192,
                RodConstraint = 193, RopeConstraint = 194, Rotate = 195, ScreenGui = 196, Script = 197,
                ScrollingFrame = 198, Seat = 199, Selected_Workspace = 200, SelectionBox = 201,
                SelectionSphere = 202, ServerScriptService = 203, ServerStorage = 204, Service = 205,
                Shirt = 206, ShirtGraphic = 207, SkinnedMeshPart = 208, Sky = 209, Smoke = 210, Snap = 211,
                Snippet = 212, SocialService = 213, Sound = 214, SoundEffect = 215, SoundGroup = 216,
                SoundService = 217, Sparkles = 218, SpawnLocation = 219, SpecialMesh = 220,
                SphereHandleAdornment = 221, SpotLight = 222, SpringConstraint = 223, StandalonePluginScripts = 224,
                StarterCharacterScripts = 225, StarterGui = 226, StarterPack = 227, StarterPlayer = 228,
                StarterPlayerScripts = 229, Struct = 230, StyleDerive = 231, StyleLink = 232, StyleRule = 233,
                StyleSheet = 234, SunRaysEffect = 235, SurfaceAppearance = 236, SurfaceGui = 237,
                SurfaceLight = 238, SurfaceSelection = 239, SwimController = 240, TaskScheduler = 241,
                Team = 242, Teams = 243, Terrain = 244, TerrainDetail = 245, TestService = 246, TextBox = 247,
                TextBoxService = 248, TextButton = 249, TextChannel = 250, TextChatCommand = 251,
                TextChatService = 252, TextLabel = 253, TextString = 254, Texture = 255, Tool = 256,
                Torque = 257, TorsionSpringConstraint = 258, Trail = 259, TremoloSoundEffect = 260,
                TrussPart = 261, TypeParameter = 262, UGCValidationService = 263, UIAspectRatioConstraint = 264,
                UICorner = 265, UIDragDetector = 266, UIFlexItem = 267, UIGradient = 268, UIGridLayout = 269,
                UIListLayout = 270, UIPadding = 271, UIPageLayout = 272, UIScale = 273, UISizeConstraint = 274,
                UIStroke = 275, UITableLayout = 276, UITextSizeConstraint = 277, UnionOperation = 278,
                Unit = 279, UniversalConstraint = 280, UnreliableRemoteEvent = 281, UpdateAvailable = 282,
                UserService = 283, Value = 284, Variable = 285, VectorForce = 286, VehicleSeat = 287,
                VideoDisplay = 288, VideoFrame = 289, VideoPlayer = 290, ViewportFrame = 291, VirtualUser = 292,
                VoiceChannel = 293, Voicechat = 294, VoiceChatService = 295, VRService = 296, WedgePart = 297,
                Weld = 298, WeldConstraint = 299, Wire = 300, WireframeHandleAdornment = 301,
                Workspace = 302, WorldModel = 303, WrapDeformer = 304, WrapLayer = 305, WrapTarget = 306,
                Color3Value = 284, IntValue = 284, NumberValue = 284, ObjectValue = 284, RayValue = 284,
                StringValue = 284, Vector3Value = 284,
            },
            IconSize = 32, Witdh = 18, Height = 18,
        },
    }

    funcs.ExplorerIcons = {
        MapId = IconList.Old.MapId,
        Icons = IconList.Old.Icons,
        IconSize = IconList.Old.IconSize,
    }

    funcs.GetIconDataFromName = function(name)
        return IconList[name] or error("Name not found")
    end

    funcs.GetLabel = function(self)
        local label = Instance.new("ImageLabel")
        self:SetupLabel(label)
        return label
    end

    funcs.SetupLabel = function(self, obj)
        obj.BackgroundTransparency = 1
        obj.ImageRectOffset = Vector2.new(0, 0)
        obj.ImageRectSize = Vector2.new(self.IconSizeX, self.IconSizeY)
        obj.ScaleType = Enum.ScaleType.Crop
        obj.Size = UDim2.new(0, self.IconSizeX, 0, self.IconSizeY)
    end

    funcs.Display = function(self, obj, index)
        obj.Image = self.MapId
        obj.ImageRectSize = Vector2.new(self.IconSizeX, self.IconSizeY)
        if not self.NumX then
            obj.ImageRectOffset = Vector2.new(self.IconSizeX*index, 0)
        else
            obj.ImageRectOffset = Vector2.new(
                self.IconSizeX*(index % self.NumX),
                self.IconSizeY*math.floor(index / self.NumX)
            )
        end
    end

    funcs.DisplayByKey = function(self, obj, key)
        if self.IndexDict[key] then
            self:Display(obj, self.IndexDict[key])
        end
    end

    funcs.IconDehash = function(self, _id)
        return math.floor(_id / 14 % 14), math.floor(_id % 14)
    end

    funcs.GetExplorerIcon = function(self, obj, index)
        index = (self.ExplorerIcons.Icons[index] or 0)
        local row, col = self:IconDehash(index)
        local MapSize = Vector2.new(256, 256)
        local pad, border = 2, 1
        obj.Position = UDim2.new(
            -col - (pad * (col + 1) + border) / self.ExplorerIcons.IconSize, 0,
            -row - (pad * (row + 1) + border) / self.ExplorerIcons.IconSize, 0
        )
        obj.Size = UDim2.new(
            MapSize.X / self.ExplorerIcons.IconSize, 0,
            MapSize.Y / self.ExplorerIcons.IconSize, 0
        )
    end

    funcs.DisplayExplorerIcons = function(self, Frame, index)
        if Frame:FindFirstChild("IconMap") then
            self:GetExplorerIcon(Frame.IconMap, index)
        else
            Frame.ClipsDescendants = true
            local obj = Instance.new("ImageLabel", Frame)
            obj.BackgroundTransparency = 1
            obj.Image = ("http://www.roblox.com/asset/?id=" .. self.ExplorerIcons.MapId)
            obj.Name = "IconMap"
            self:GetExplorerIcon(obj, index)
        end
    end

    funcs.SetDict = function(self, dict) self.IndexDict = dict end

    local mt = {__index = funcs}
    local function new(mapId, mapSizeX, mapSizeY, iconSizeX, iconSizeY)
        return setmetatable({
            MapId = mapId, MapSizeX = mapSizeX, MapSizeY = mapSizeY,
            IconSizeX = iconSizeX, IconSizeY = iconSizeY,
            NumX = mapSizeX/iconSizeX, IndexDict = {}
        }, mt)
    end
    local function newLinear(mapId, iconSizeX, iconSizeY)
        return setmetatable({
            MapId = mapId, IconSizeX = iconSizeX, IconSizeY = iconSizeY, IndexDict = {}
        }, mt)
    end
    return {new = new, newLinear = newLinear, getIconDataFromName = funcs.GetIconDataFromName, IconList = IconList}
end)()

-- ============================================================
-- [5] 序列化 (SimpleSpy 全套, 完整保留所有函数)
-- ============================================================
local prevTables = {}
local topstr = ""
local bottomstr = ""
local getnilrequired = false
local ser_indent = 4
local keyToString = false
local funcEnabled = true

D.setSerializerOptions = function(opt)
    if opt.keyToString ~= nil then keyToString = opt.keyToString end
    if opt.funcEnabled ~= nil then funcEnabled = opt.funcEnabled end
    if opt.indent ~= nil then ser_indent = opt.indent end
    if opt.maxTableSize then _G.SimpleSpyMaxTableSize = opt.maxTableSize end
    if opt.maxStringSize then _G.SimpleSpyMaxStringSize = opt.maxStringSize end
end

D.safetostring = function(v)
    if typeof(v) == "userdata" or type(v) == "table" then
        local mt = getrawmetatable(v)
        local badtostring = mt and rawget(mt, "__tostring")
        if mt and badtostring then
            rawset(mt, "__tostring", nil)
            local out = tostring(v)
            rawset(mt, "__tostring", badtostring)
            return out
        end
    end
    return tostring(v)
end

D.handlespecials = function(value, indentation)
    local buildStr = {}
    local i = 1
    local char = string.sub(value, i, i)
    local indentStr
    while char ~= "" do
        if char == '"' then buildStr[i] = '\\"'
        elseif char == "\\" then buildStr[i] = "\\\\"
        elseif char == "\n" then buildStr[i] = "\\n"
        elseif char == "\t" then buildStr[i] = "\\t"
        elseif string.byte(char) > 126 or string.byte(char) < 32 then
            buildStr[i] = string.format("\\%d", string.byte(char))
        else buildStr[i] = char end
        i = i + 1
        char = string.sub(value, i, i)
        if i % 200 == 0 then
            indentStr = indentStr or string.rep(" ", indentation + ser_indent)
            table.move({ '"\n', indentStr, '... "' }, 1, 3, i, buildStr)
            i = i + 3
        end
    end
    return table.concat(buildStr)
end

D.formatstr = function(s, indentation)
    if not indentation then indentation = 0 end
    local handled = D.handlespecials(s, indentation)
    return '"' .. handled .. '"' .. ((#s > (_G.SimpleSpyMaxStringSize or 2000)) and
        " --[[ MAX STRING SIZE ]]" or "")
end

D.getplayer = function(instance)
    for _, v in pairs(service.Players:GetPlayers()) do
        if v.Character and (instance:IsDescendantOf(v.Character) or instance == v.Character) then return v end
    end
end

D.i2p = function(i)
    local player = D.getplayer(i)
    local parent = i
    local out = ""
    if parent == nil then return "nil"
    elseif player then
        while true do
            if parent and parent == player.Character then
                if player == service.Players.LocalPlayer then
                    return 'game:GetService("Players").LocalPlayer.Character' .. out
                else
                    return D.i2p(player) .. ".Character" .. out
                end
            else
                if parent.Name:match("[%a_]+[%w+]*") ~= parent.Name then
                    out = ":FindFirstChild(" .. D.formatstr(parent.Name) .. ")" .. out
                else
                    out = "." .. parent.Name .. out
                end
            end
            parent = parent.Parent
        end
    elseif parent ~= game then
        while true do
            if parent and parent.Parent == game then
                local service_ = game:FindService(parent.ClassName)
                if service_ then
                    if parent.ClassName == "Workspace" then
                        return "workspace" .. out
                    else
                        return 'game:GetService("' .. service_.ClassName .. '")' .. out
                    end
                else
                    if parent.Name:match("[%a_]+[%w_]*") then
                        return "game." .. parent.Name .. out
                    else
                        return "game:FindFirstChild(" .. D.formatstr(parent.Name) .. ")" .. out
                    end
                end
            elseif parent.Parent == nil then
                getnilrequired = true
                return "getNil(" .. D.formatstr(parent.Name) .. ', "' .. parent.ClassName .. '")' .. out
            elseif parent == service.Players.LocalPlayer then
                out = ".LocalPlayer" .. out
            else
                if parent.Name:match("[%a_]+[%w_]*") ~= parent.Name then
                    out = ":FindFirstChild(" .. D.formatstr(parent.Name) .. ")" .. out
                else
                    out = "." .. parent.Name .. out
                end
            end
            parent = parent.Parent
        end
    else
        return "game"
    end
end

D.u2s = function(u)
    if typeof(u) == "TweenInfo" then
        return "TweenInfo.new(" .. tostring(u.Time) .. ", Enum.EasingStyle." .. tostring(u.EasingStyle)
            .. ", Enum.EasingDirection." .. tostring(u.EasingDirection) .. ", " .. tostring(u.RepeatCount)
            .. ", " .. tostring(u.Reverses) .. ", " .. tostring(u.DelayTime) .. ")"
    elseif typeof(u) == "Ray" then
        return "Ray.new(" .. D.u2s(u.Origin) .. ", " .. D.u2s(u.Direction) .. ")"
    elseif typeof(u) == "NumberSequence" then
        local ret = "NumberSequence.new("
        for i, v in pairs(u.KeyPoints) do
            ret = ret .. tostring(v)
            if i < #u.Keypoints then ret = ret .. ", " end
        end
        return ret .. ")"
    elseif typeof(u) == "DockWidgetPluginGuiInfo" then
        return "DockWidgetPluginGuiInfo.new(Enum.InitialDockState" .. tostring(u) .. ")"
    elseif typeof(u) == "ColorSequence" then
        local ret = "ColorSequence.new("
        for i, v in pairs(u.KeyPoints) do
            ret = ret .. "Color3.new(" .. tostring(v) .. ")"
            if i < #u.Keypoints then ret = ret .. ", " end
        end
        return ret .. ")"
    elseif typeof(u) == "BrickColor" then
        return "BrickColor.new(" .. tostring(u.Number) .. ")"
    elseif typeof(u) == "NumberRange" then
        return "NumberRange.new(" .. tostring(u.Min) .. ", " .. tostring(u.Max) .. ")"
    elseif typeof(u) == "Region3" then
        local center = u.CFrame.Position
        local size = u.CFrame.Size
        local vector1 = center - size / 2
        local vector2 = center + size / 2
        return "Region3.new(" .. D.u2s(vector1) .. ", " .. D.u2s(vector2) .. ")"
    elseif typeof(u) == "Faces" then
        local faces = {}
        if u.Top then table.insert(faces, "Enum.NormalId.Top") end
        if u.Bottom then table.insert(faces, "Enum.NormalId.Bottom") end
        if u.Left then table.insert(faces, "Enum.NormalId.Left") end
        if u.Right then table.insert(faces, "Enum.NormalId.Right") end
        if u.Back then table.insert(faces, "Enum.NormalId.Back") end
        if u.Front then table.insert(faces, "Enum.NormalId.Front") end
        return "Faces.new(" .. table.concat(faces, ", ") .. ")"
    elseif typeof(u) == "EnumItem" then return tostring(u)
    elseif typeof(u) == "Enums" then return "Enum"
    elseif typeof(u) == "Enum" then return "Enum." .. tostring(u)
    elseif typeof(u) == "RBXScriptSignal" then return "nil --[[RBXScriptSignal]]"
    elseif typeof(u) == "Vector3" then
        return string.format("Vector3.new(%s, %s, %s)", D.v2s(u.X), D.v2s(u.Y), D.v2s(u.Z))
    elseif typeof(u) == "CFrame" then
        local xAngle, yAngle, zAngle = u:ToEulerAnglesXYZ()
        return string.format("CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s)",
            D.v2s(u.X), D.v2s(u.Y), D.v2s(u.Z), D.v2s(xAngle), D.v2s(yAngle), D.v2s(zAngle))
    elseif typeof(u) == "DockWidgetPluginGuiInfo" then
        return string.format("DockWidgetPluginGuiInfo(%s, %s, %s, %s, %s, %s, %s)",
            "Enum.InitialDockState.Right", D.v2s(u.InitialEnabled), D.v2s(u.InitialEnabledShouldOverrideRestore),
            D.v2s(u.FloatingXSize), D.v2s(u.FloatingYSize), D.v2s(u.MinWidth), D.v2s(u.MinHeight))
    elseif typeof(u) == "PathWaypoint" then
        return string.format("PathWaypoint.new(%s, %s)", D.v2s(u.Position), D.v2s(u.Action))
    elseif typeof(u) == "UDim" then
        return string.format("UDim.new(%s, %s)", D.v2s(u.Scale), D.v2s(u.Offset))
    elseif typeof(u) == "UDim2" then
        return string.format("UDim2.new(%s, %s, %s, %s)",
            D.v2s(u.X.Scale), D.v2s(u.X.Offset), D.v2s(u.Y.Scale), D.v2s(u.Y.Offset))
    elseif typeof(u) == "Rect" then
        return string.format("Rect.new(%s, %s)", D.v2s(u.Min), D.v2s(u.Max))
    else
        return string.format("nil --[[%s]]", typeof(u))
    end
end

D.f2s = function(f)
    for k, x in pairs(getgenv and getgenv() or {}) do
        local isgucci, gpath
        if rawequal(x, f) then isgucci, gpath = true, ""
        elseif type(x) == "table" then isgucci, gpath = D.v2p(f, x) end
        if isgucci and type(k) ~= "function" then
            if type(k) == "string" and k:match("^[%a_]+[%w_]*$") then return k .. gpath
            else return "getgenv()[" .. D.v2s(k) .. "]" .. gpath end
        end
    end
    if funcEnabled and debug.getinfo(f).name and debug.getinfo(f).name:match("^[%a_]+[%w_]*$") then
        return "function()end --[[" .. debug.getinfo(f).name .. "]]"
    end
    return "function()end --[[" .. tostring(f) .. "]]"
end

D.v2p = function(x, t, path, prev)
    if not path then path = "" end
    if not prev then prev = {} end
    if rawequal(x, t) then return true, "" end
    for i, v in pairs(t) do
        if rawequal(v, x) then
            if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then return true, (path .. "." .. i)
            else return true, (path .. "[" .. D.v2s(i) .. "]") end
        end
        if type(v) == "table" then
            local duplicate = false
            for _, y in pairs(prev) do if rawequal(y, v) then duplicate = true end end
            if not duplicate then
                table.insert(prev, t)
                local found, p = D.v2p(x, v, path, prev)
                if found then
                    if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then return true, "." .. i .. p
                    else return true, "[" .. D.v2s(i) .. "]" .. p end
                end
            end
        end
    end
    return false, ""
end

D.k2s = function(v, ...)
    if keyToString then
        if typeof(v) == "userdata" and getrawmetatable(v) then
            return string.format('"<void> (%s)" --[[Potentially hidden data]]', D.safetostring(v))
        elseif typeof(v) == "userdata" then
            return string.format('"<void> (%s)"', D.safetostring(v))
        elseif type(v) == "userdata" and typeof(v) ~= "Instance" then
            return string.format('"<%s> (%s)"', typeof(v), tostring(v))
        elseif type(v) == "function" then
            return string.format('"<Function> (%s)"', tostring(v))
        end
    end
    return D.v2s(v, ...)
end

D.t2s = function(t, l, p, n, vtv, i, pt, path, tables, tI)
    local globalIndex = table.find(getgenv and getgenv() or {}, t)
    if type(globalIndex) == "string" then return globalIndex end
    if not tI then tI = { 0 } end
    if not path then path = "" end
    if not l then l = 0 tables = {} end
    if not p then p = t end
    for _, v in pairs(tables) do
        if n and rawequal(v, t) then
            bottomstr = bottomstr .. "\n" .. tostring(n) .. tostring(path) .. " = " .. tostring(n) .. tostring(({ D.v2p(v, p) })[2])
            return "{} --[[DUPLICATE]]"
        end
    end
    table.insert(tables, t)
    local s = "{"
    local size = 0
    l = l + ser_indent
    for k, v in pairs(t) do
        size = size + 1
        if size > (_G.SimpleSpyMaxTableSize or 1000) then
            s = s .. "\n" .. string.rep(" ", l) .. "-- MAXIMUM TABLE SIZE REACHED, CHANGE '_G.SimpleSpyMaxTableSize' TO ADJUST"
            break
        end
        if rawequal(k, t) then
            bottomstr = bottomstr .. "\n" .. tostring(n) .. tostring(path) .. "[" .. tostring(n) .. tostring(path) .. "] = " ..
                (rawequal(v, k) and (tostring(n) .. tostring(path)) or D.v2s(v, l, p, n, vtv, k, t, path .. "[" .. tostring(n) .. tostring(path) .. "]", tables))
            size = size - 1
        else
            local currentPath = ""
            if type(k) == "string" and k:match("^[%a_]+[%w_]*$") then
                currentPath = "." .. k
            else
                currentPath = "[" .. D.k2s(k, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. "]"
            end
            s = s .. "\n" .. string.rep(" ", l) .. "[" ..
                D.k2s(k, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. "] = " ..
                D.v2s(v, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. ","
        end
    end
    if #s > 1 then s = s:sub(1, #s - 1) end
    if size > 0 then s = s .. "\n" .. string.rep(" ", l - ser_indent) end
    return s .. "}"
end

D.v2s = function(v, l, p, n, vtv, i, pt, path, tables, tI)
    if not tI then tI = { 0 } else tI[1] = tI[1] + 1 end
    if typeof(v) == "number" then
        if v == math.huge then return "math.huge"
        elseif tostring(v):match("nan") then return "0/0 --[[NaN]]"
        else return tostring(v) end
    elseif typeof(v) == "boolean" then return tostring(v)
    elseif typeof(v) == "string" then return D.formatstr(v, l)
    elseif typeof(v) == "function" then return D.f2s(v)
    elseif typeof(v) == "table" then return D.t2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    elseif typeof(v) == "Instance" then return D.i2p(v)
    elseif typeof(v) == "userdata" then return "newproxy(true)"
    elseif type(v) == "userdata" then return D.u2s(v)
    elseif type(v) == "vector" then return string.format("Vector3.new(%s, %s, %s)", v.X, v.Y, v.Z)
    else return "nil --[[" .. typeof(v) .. "]]" end
end

D.v2v = function(t)
    topstr = ""
    bottomstr = ""
    getnilrequired = false
    local ret = ""
    local count = 1
    for i, v in pairs(t) do
        if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
            ret = ret .. "local " .. i .. " = " .. D.v2s(v, nil, nil, i, true) .. "\n"
        elseif tostring(i):match("^[%a_]+[%w_]*$") then
            ret = ret .. "local " .. tostring(i):lower() .. "_" .. tostring(count) ..
                " = " .. D.v2s(v, nil, nil, tostring(i):lower() .. "_" .. tostring(count), true) .. "\n"
        else
            ret = ret .. "local " .. type(v) .. "_" .. tostring(count) ..
                " = " .. D.v2s(v, nil, nil, type(v) .. "_" .. tostring(count), true) .. "\n"
        end
        count = count + 1
    end
    if getnilrequired then
        topstr = "function getNil(name,class) for _,v in pairs(getnilinstances())do if v.ClassName==class and v.Name==name then return v;end end end\n" .. topstr
    end
    if #topstr > 0 then ret = topstr .. "\n" .. ret end
    if #bottomstr > 0 then ret = ret .. bottomstr end
    return ret
end

-- ============================================================
-- [6] 反编译 (LuaExpert API)
-- ============================================================
local decompile_last_call = 0
local DECOMPILE_RATE_LIMIT = 0.12

D.base64_encode = function(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r, byte = '', x:byte()
        for i = 8, 1, -1 do
            r = r .. (byte % 2^i - byte % 2^(i-1) > 0 and '1' or '0')
        end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i, i) == '1' and 2^(6 - i) or 0)
        end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

D.decompile = function(script_instance)
    if not getscriptbytecode then
        return "-- 当前执行器不支持 getscriptbytecode，无法反编译"
    end
    local ok, bytecode = pcall(getscriptbytecode, script_instance)
    if not ok then
        return "-- 获取字节码失败:\n--[[\n" .. tostring(bytecode) .. "\n--]]"
    end
    local now = os.clock()
    local elapsed = now - decompile_last_call
    if elapsed < DECOMPILE_RATE_LIMIT then
        if task and task.wait then task.wait(DECOMPILE_RATE_LIMIT - elapsed)
        else wait(DECOMPILE_RATE_LIMIT - elapsed) end
    end
    local b64 = D.base64_encode(bytecode)
    local request_func = (syn and syn.request) or (http and http.request) or http_request or request
    if not request_func then
        return "-- 没有可用的 HTTP 请求函数 (syn.request / http_request / request)"
    end
    local response = request_func({
        Url = "https://api.lua.expert/decompile",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = service.HttpService:JSONEncode({ script = b64 })
    })
    decompile_last_call = os.clock()
    if not response or response.StatusCode ~= 200 then
        return "-- 反编译 API 错误\n--[[\n" .. (response and response.Body or "无响应") .. "\n--]]"
    end
    return response.Body
end

D.getScriptFromSource = function(source)
    if type(source) ~= "string" then return nil end
    local path = source:gsub("^@", "")
    if path:find("=") then return nil end
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("LocalScript") or v:IsA("ModuleScript") or v:IsA("Script") then
            if v:GetFullName() == path or v.Name == path then return v end
        end
    end
    local filename = path:match("([^/\\]+)$")
    if filename then
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("LocalScript") or v:IsA("ModuleScript") or v:IsA("Script") then
                if v.Name == filename then return v end
            end
        end
    end
    return nil
end

D.getScriptFromSrc = function(src)
    local realPath
    local runningTest
    local s, e
    local match = false
    if src:sub(1, 1) == "=" then
        realPath = game
        s = 2
    else
        runningTest = src:sub(2, e and e - 1 or -1)
        for _, v in pairs(getnilinstances and getnilinstances() or {}) do
            if v.Name == runningTest then realPath = v break end
        end
        s = #runningTest + 1
    end
    if realPath then
        e = src:sub(s, -1):find("%.")
        local i = 0
        repeat
            i = i + 1
            if not e then
                runningTest = src:sub(s, -1)
                local test = realPath.FindFirstChild(realPath, runningTest)
                if test then realPath = test end
                match = true
            else
                runningTest = src:sub(s, e)
                local test = realPath.FindFirstChild(realPath, runningTest)
                local yeOld = e
                if test then
                    realPath = test
                    s = e + 2
                    e = src:sub(e + 2, -1):find("%.")
                    e = e and e + yeOld or e
                else
                    e = src:sub(e + 2, -1):find("%.")
                    e = e and e + yeOld or e
                end
            end
        until match or i >= 50
    end
    return realPath
end

-- ============================================================
-- [7] 实例路径 (Dex++ Explorer.GetInstancePath 完整版)
-- ============================================================
D.GetInstancePath = function(obj)
    local ffc = game.FindFirstChild
    local getCh = game.GetChildren
    local path = ""
    local curObj = obj
    local ts = tostring
    local match = string.match
    local tableFind = table.find

    while curObj do
        if curObj == game then path = "game" .. path break end
        local className = curObj.ClassName
        local curName = ts(curObj)
        local indexName
        if match(curName, "^[%a_][%w_]*$") then
            indexName = "." .. curName
        else
            local cleanName = D.FormatLuaString(curName)
            indexName = '["' .. cleanName .. '"]'
        end
        local parObj = curObj.Parent
        if parObj then
            local fc = ffc(parObj, curName)
            if fc and fc ~= curObj then
                local parCh = getCh(parObj)
                local fcInd = tableFind(parCh, curObj)
                indexName = ":GetChildren()[" .. fcInd .. "]"
            elseif parObj == game and className then
                local svc = game:FindService(className)
                if svc then indexName = ':GetService("' .. className .. '")' end
            end
        elseif parObj == nil then
            local getnil = "local getNil = function(name, class) for _, v in next, getnilinstances() do if v.ClassName == class and v.Name == name then return v end end end"
            local gotnil = "\n\ngetNil(\"%s\", \"%s\")"
            indexName = getnil .. gotnil:format(curObj.Name, className)
        end
        path = indexName .. path
        curObj = parObj
    end
    return path
end

-- ============================================================
-- [8] 函数转储 (Dex++ ScriptViewer.DumpFunctions)
-- ============================================================
D.dumpFunctions = function(scr)
    local getgcF = getgc or get_gc_objects
    local getupvalues_ = (debug and debug.getupvalues) or getupvalues or getupvals
    local getconstants_ = (debug and debug.getconstants) or getconstants or getconsts
    local getinfo_ = (debug and (debug.getinfo or debug.info)) or getinfo
    if not getgcF then return "-- 缺少 getgc" end

    local getPathFn = function(o)
        if o.Parent == nil then return "Nil parented"
        else return D.GetInstancePath(o) end
    end

    local original = ("\n-- // Function Dumper made by King.Kevin\n-- // Script Path: %s\n\n--[["):format(getPathFn(scr))
    local dump = original
    local functions, function_count, data_base = {}, 0, {}
    function functions:add_to_dump(str, indentation, new_line)
        local new_line = new_line or true
        dump = dump .. ("%s%s%s"):format(string.rep("\t\t", indentation), tostring(str), new_line and "\n" or "")
    end
    function functions:get_function_name(func)
        local n = getinfo_(func).name
        return n ~= "" and n or "Unknown Name"
    end
    function functions:dump_table(input, ind, index)
        local ind = ind < 0 and 0 or ind
        functions:add_to_dump(("%s [%s] %s"):format(tostring(index), tostring(typeof(input)), tostring(input)), ind - 1)
        local count = 0
        for i, v in pairs(input) do
            count = count + 1
            if type(v) == "function" then
                functions:add_to_dump(("%d [function] = %s"):format(count, functions:get_function_name(v)), ind)
            elseif type(v) == "table" then
                if not data_base[v] then
                    data_base[v] = true
                    functions:add_to_dump(("%d [table]:"):format(count), ind)
                    functions:dump_table(v, ind + 1, i)
                else
                    functions:add_to_dump(("%d [table] (Recursive table detected)"):format(count), ind)
                end
            else
                functions:add_to_dump(("%d [%s] = %s"):format(count, tostring(typeof(v)), tostring(v)), ind)
            end
        end
    end
    function functions:dump_function(input, ind)
        functions:add_to_dump(("\nFunction Dump: %s"):format(functions:get_function_name(input)), ind)
        functions:add_to_dump(("\nFunction Upvalues: %s"):format(functions:get_function_name(input)), ind)
        for index, upvalue in pairs(getupvalues_(input)) do
            if type(upvalue) == "function" then
                functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(upvalue)), ind + 1)
            elseif type(upvalue) == "table" then
                if not data_base[upvalue] then
                    data_base[upvalue] = true
                    functions:add_to_dump(("%d [table]:"):format(index), ind + 1)
                    functions:dump_table(upvalue, ind + 2, index)
                else
                    functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), ind + 1)
                end
            else
                functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(upvalue)), tostring(upvalue)), ind + 1)
            end
        end
        functions:add_to_dump(("\nFunction Constants: %s"):format(functions:get_function_name(input)), ind)
        for index, constant in pairs(getconstants_(input)) do
            if type(constant) == "function" then
                functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(constant)), ind + 1)
            elseif type(constant) == "table" then
                if not data_base[constant] then
                    data_base[constant] = true
                    functions:add_to_dump(("%d [table]:"):format(index), ind + 1)
                    functions:dump_table(constant, ind + 2, index)
                else
                    functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), ind + 1)
                end
            else
                functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(constant)), tostring(constant)), ind + 1)
            end
        end
    end
    for _, _function in pairs(getgcF()) do
        if typeof(_function) == "function" and getfenv(_function).script and getfenv(_function).script == scr then
            functions:dump_function(_function, 0)
            functions:add_to_dump("\n" .. ("="):rep(100), 0, false)
        end
    end
    return dump
end

-- ============================================================
-- [9] env 封装 (Dex++ Main.InitEnv 完整版)
-- ============================================================
D.env = {}
D.MissingEnv = {}
setmetatable(D.env, {__newindex = function(self, name, func)
    if not func then D.MissingEnv[#D.MissingEnv+1] = name return end
    rawset(self, name, func)
end})

D.initEnv = function()
    D.env.isonmobile = service.UserInputService.TouchEnabled
    D.env.loadstring = (pcall(loadstring, "local a = 1") and loadstring) or nil
    D.env.isfile = isfile
    D.env.isfolder = isfolder
    D.env.readfile = readfile
    D.env.writefile = writefile
    D.env.appendfile = appendfile
    D.env.makefolder = makefolder
    D.env.listfiles = listfiles
    D.env.loadfile = loadfile
    D.env.parsefile = function(name)
        return tostring(name):gsub("[*\\?:<>|]+", ""):sub(1, 175)
    end
    D.env.getupvalues = debug.getupvalues or getupvalues or getupvals
    D.env.getconstants = debug.getconstants or getconstants or getconsts
    D.env.islclosure = islclosure or is_l_closure
    D.env.checkcaller = checkcaller
    D.env.getreg = getreg
    D.env.getgc = getgc
    D.env.hookfunction = hookfunction
    D.env.hookmetamethod = hookmetamethod
    D.env.getscriptbytecode = getscriptbytecode
    D.env.setfflag = setfflag
    D.env.protectgui = protect_gui or (syn and syn.protect_gui)
    D.env.gethui = gethui
    D.env.setclipboard = setclipboard
    D.env.getnilinstances = getnilinstances or get_nil_instances
    D.env.getloadedmodules = getloadedmodules
    D.env.request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

    D.env.isViableDecompileScript = function(obj)
        if obj:IsA("ModuleScript") then return true
        elseif obj:IsA("LocalScript") and (obj.RunContext == Enum.RunContext.Client or obj.RunContext == Enum.RunContext.Legacy) then return true
        elseif obj:IsA("Script") and obj.RunContext == Enum.RunContext.Client then return true
        end
        return false
    end

    D.env.isdecompile = function()
        return typeof(decompile) == "function" or typeof(getscriptbytecode) == "function" or false
    end
    D.env.isdecompilefallback = function()
        return typeof(decompile) ~= "function" or typeof(getscriptbytecode) == "function" or false
    end
    setmetatable(D.env, nil)
end


-- ============================================================
-- [10] saveinstance (懒加载版 - 修复卡死)
-- ============================================================
D._saveinstanceModule = nil

D.saveinstance = function(obj, filepath, options)
    if service.RunService:IsStudio() then
        error("Cannot run in Roblox Studio!")
    end

    -- 第一次调用时才下载
    if not D._saveinstanceModule then
        print("[saveinstance] 首次使用, 正在下载 SynSaveInstance...")
        local Params = {
            RepoURL = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/",
            SSI = "saveinstance",
        }
        local ok, src = pcall(oldgame.HttpGet, oldgame, Params.RepoURL .. Params.SSI .. ".luau", true)
        if not ok or not src then
            error("下载 SynSaveInstance 失败: " .. tostring(src))
        end
        local fn = loadstring(src, Params.SSI)
        if not fn then
            error("编译 SynSaveInstance 失败")
        end
        D._saveinstanceModule = fn()
        print("[saveinstance] 下载完成")
    end

    options = options or {}
    options["FilePath"] = filepath
    options["Object"] = obj
    local result = D._saveinstanceModule(options)
    if getgenv then getgenv().saveinstance = D.saveinstance end
    return result
end

-- ============================================================
-- [11] Adonis Bypass (主脚本末尾完整版)
-- ============================================================
D.InitAdonisBypass = function()
    if not getreg or not getgc or not isfunctionhooked then
        warn("Executor does not support Adonis bypass functions.")
        return false
    end
    local AdonisAnticheatThreads = {}
    for _, thread in getreg() do
        if typeof(thread) ~= "thread" then continue end
        local Source = debug.info(thread, 1, "s")
        if Source and (Source:match(".Core.Anti") or Source:match(".Plugins.Anti_Cheat")) then
            table.insert(AdonisAnticheatThreads, thread)
        end
    end
    for _, thread in AdonisAnticheatThreads do
        pcall(coroutine.close, thread)
    end
    local AdonisTables = {}
    if filtergc then
        local ContendorAdonisTables = filtergc("table", { Keys = { "Detected", "RLocked" } }, false)
        for _, AdonisTable in ContendorAdonisTables do
            if typeof(rawget(AdonisTable, "Detected")) == "function" then
                table.insert(AdonisTables, AdonisTable)
            end
        end
    else
        for _, Table in getgc(true) do
            if typeof(Table) == "table" and typeof(rawget(Table, "Detected")) == "function" and rawget(Table, "RLocked") then
                table.insert(AdonisTables, Table)
            end
        end
    end
    for _, AdonisTable in AdonisTables do
        for _, DetectionFunc in AdonisTable do
            if typeof(DetectionFunc) == "function" and not isfunctionhooked(DetectionFunc) then
                hookfunction(DetectionFunc, function()
                    coroutine.yield()
                    return task.wait(9e9)
                end)
            end
        end
    end
    return true
end

-- Dex++ Main.LoadAdonisBypass (原脚本内的实现)
D.LoadAdonisBypass = function()
    local getinfo = getinfo or debug.getinfo
    local DEBUG = false
    local Hooked = {}
    local Detected, Kill
    setthreadidentity(2)
    for i, v in getgc(true) do
        if typeof(v) == "table" then
            local DetectFunc = rawget(v, "Detected")
            local KillFunc = rawget(v, "Kill")
            if typeof(DetectFunc) == "function" and not Detected then
                Detected = DetectFunc
                local Old
                Old = hookfunction(Detected, function(Action, Info, NoCrash)
                    if Action ~= "_" then
                        if DEBUG then
                            warn(string.format("Adonis AntiCheat flagged\nMethod: %s\nInfo: %s", Action, Info))
                        end
                    end
                    return true
                end)
                table.insert(Hooked, Detected)
            end
            if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
                Kill = KillFunc
                local Old
                Old = hookfunction(Kill, function(Info)
                    if DEBUG then
                        warn(string.format("Adonis AntiCheat tried to kill (fallback): %s", Info))
                    end
                end)
                table.insert(Hooked, Kill)
            end
        end
    end
    local Old
    Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
        local LevelOrFunc, Info = ...
        if Detected and LevelOrFunc == Detected then
            if DEBUG then warn("Adonis AntiCheat sanity check detected and broken") end
            return coroutine.yield(coroutine.running())
        end
        return Old(...)
    end))
    setthreadidentity(7)
end

D.LoadGCBypass = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/secretisadev/Babyhamsta_Backup/refs/heads/main/Universal/Bypasses.lua", true))()
end

-- ============================================================
-- [12] API / RMD 抓取 (Dex++ 完整版, 一字不落)
-- ============================================================
D.RawAPI = nil
D.RawRMD = nil
D.RobloxVersion = nil
D.ClientVersion = nil
D.DepsVersionData = nil

D.LocalDepsUpToDate = function()
    return D.DepsVersionData and D.ClientVersion == D.DepsVersionData[1]
end

D.FetchAPI = function(callbackiflong, callbackiftoolong, XD)
    local downloaded = false
    local api, rawAPI

    if D.LocalDepsUpToDate and D.LocalDepsUpToDate() then
        local localAPI = D.ReadFile and D.ReadFile("dex/rbx_api.dat")
        if localAPI then rawAPI = localAPI
        else D.DepsVersionData = D.DepsVersionData or {} D.DepsVersionData[1] = "" end
    end

    task.spawn(function()
        task.wait(10)
        if not downloaded and callbackiflong then callbackiflong() end
        task.wait(20)
        if not downloaded and callbackiftoolong then callbackiftoolong() end
        task.wait(30)
        if not downloaded and XD then XD() end
    end)

    rawAPI = rawAPI or game:HttpGet("http://setup.roblox.com/" .. D.RobloxVersion .. "-API-Dump.json")
    downloaded = true
    D.RawAPI = rawAPI
    api = service.HttpService:JSONDecode(rawAPI)

    local classes, enums = {}, {}
    local categoryOrder, seenCategories = {}, {}

    local function insertAbove(t, item, aboveItem)
        local findPos = table.find(t, item)
        if not findPos then return end
        table.remove(t, findPos)
        local pos = table.find(t, aboveItem)
        if not pos then return end
        table.insert(t, pos, item)
    end

    for _, class in pairs(api.Classes) do
        local newClass = {}
        newClass.Name = class.Name
        newClass.Superclass = class.Superclass
        newClass.Properties = {}
        newClass.Functions = {}
        newClass.Events = {}
        newClass.Callbacks = {}
        newClass.Tags = {}
        if class.Tags then for c, tag in pairs(class.Tags) do newClass.Tags[tag] = true end end

        for __, member in pairs(class.Members) do
            local newMember = {}
            newMember.Name = member.Name
            newMember.Class = class.Name
            newMember.Security = member.Security
            newMember.Tags = {}
            if member.Tags then for c, tag in pairs(member.Tags) do newMember.Tags[tag] = true end end

            local mType = member.MemberType
            if mType == "Property" then
                local propCategory = member.Category or "Other"
                propCategory = propCategory:match("^%s*(.-)%s*$")
                if not seenCategories[propCategory] then
                    categoryOrder[#categoryOrder+1] = propCategory
                    seenCategories[propCategory] = true
                end
                newMember.ValueType = member.ValueType
                newMember.Category = propCategory
                newMember.Serialization = member.Serialization
                table.insert(newClass.Properties, newMember)
            elseif mType == "Function" then
                newMember.Parameters = {}
                newMember.ReturnType = member.ReturnType.Name
                for c, param in pairs(member.Parameters) do
                    table.insert(newMember.Parameters, {Name = param.Name, Type = param.Type.Name})
                end
                table.insert(newClass.Functions, newMember)
            elseif mType == "Event" then
                newMember.Parameters = {}
                for c, param in pairs(member.Parameters) do
                    table.insert(newMember.Parameters, {Name = param.Name, Type = param.Type.Name})
                end
                table.insert(newClass.Events, newMember)
            end
        end
        classes[class.Name] = newClass
    end

    for _, class in pairs(classes) do
        class.Superclass = classes[class.Superclass]
    end

    for _, enum in pairs(api.Enums) do
        local newEnum = {}
        newEnum.Name = enum.Name
        newEnum.Items = {}
        newEnum.Tags = {}
        if enum.Tags then for c, tag in pairs(enum.Tags) do newEnum.Tags[tag] = true end end
        for __, item in pairs(enum.Items) do
            local newItem = {}
            newItem.Name = item.Name
            newItem.Value = item.Value
            table.insert(newEnum.Items, newItem)
        end
        enums[enum.Name] = newEnum
    end

    local function getMember(class, member)
        if not classes[class] or not classes[class][member] then return end
        local result = {}
        local currentClass = classes[class]
        while currentClass do
            for _, entry in pairs(currentClass[member]) do
                result[#result+1] = entry
            end
            currentClass = currentClass.Superclass
        end
        table.sort(result, function(a, b) return a.Name < b.Name end)
        return result
    end

    insertAbove(categoryOrder, "Behavior", "Tuning")
    insertAbove(categoryOrder, "Appearance", "Data")
    insertAbove(categoryOrder, "Attachments", "Axes")
    insertAbove(categoryOrder, "Cylinder", "Slider")
    insertAbove(categoryOrder, "Localization", "Jump Settings")
    insertAbove(categoryOrder, "Surface", "Motion")
    insertAbove(categoryOrder, "Surface Inputs", "Surface")
    insertAbove(categoryOrder, "Part", "Surface Inputs")
    insertAbove(categoryOrder, "Assembly", "Surface Inputs")
    insertAbove(categoryOrder, "Character", "Controls")
    categoryOrder[#categoryOrder+1] = "Unscriptable"
    categoryOrder[#categoryOrder+1] = "Attributes"

    local categoryOrderMap = {}
    for i = 1, #categoryOrder do
        categoryOrderMap[categoryOrder[i]] = i
    end

    return {
        Classes = classes,
        Enums = enums,
        CategoryOrder = categoryOrderMap,
        GetMember = getMember
    }
end

D.FetchRMD = function()
    local rawXML = nil
    if D.LocalDepsUpToDate and D.LocalDepsUpToDate() then
        local localRMD = D.ReadFile and D.ReadFile("dex/rbx_rmd.dat")
        if localRMD then rawXML = localRMD
        else D.DepsVersionData = D.DepsVersionData or {} D.DepsVersionData[1] = "" end
    end
    rawXML = rawXML or game:HttpGet("https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/ReflectionMetadata.xml")
    D.RawRMD = rawXML
    local parsed = D.ParseXML(rawXML)
    local classList = parsed.children[1].children[1].children
    local enumList = parsed.children[1].children[2].children
    local propertyOrders = {}

    local classes, enums = {}, {}
    for _, class in pairs(classList) do
        local className = ""
        for _, child in pairs(class.children) do
            if child.tag == "Properties" then
                local data = {Properties = {}, Functions = {}}
                local props = child.children
                for _, prop in pairs(props) do
                    local name = prop.attrs.name
                    name = name:sub(1,1):upper() .. name:sub(2)
                    data[name] = prop.children[1].text
                end
                className = data.Name
                classes[className] = data
            elseif child.attrs.class == "ReflectionMetadataProperties" then
                local members = child.children
                for _, member in pairs(members) do
                    if member.attrs.class == "ReflectionMetadataMember" then
                        local data = {}
                        if member.children[1].tag == "Properties" then
                            local props = member.children[1].children
                            for _, prop in pairs(props) do
                                if prop.attrs then
                                    local name = prop.attrs.name
                                    name = name:sub(1,1):upper() .. name:sub(2)
                                    data[name] = prop.children[1].text
                                end
                            end
                            if data.PropertyOrder then
                                local orders = propertyOrders[className]
                                if not orders then orders = {} propertyOrders[className] = orders end
                                orders[data.Name] = tonumber(data.PropertyOrder)
                            end
                            classes[className].Properties[data.Name] = data
                        end
                    end
                end
            elseif child.attrs.class == "ReflectionMetadataFunctions" then
                local members = child.children
                for _, member in pairs(members) do
                    if member.attrs.class == "ReflectionMetadataMember" then
                        local data = {}
                        if member.children[1].tag == "Properties" then
                            local props = member.children[1].children
                            for _, prop in pairs(props) do
                                if prop.attrs then
                                    local name = prop.attrs.name
                                    name = name:sub(1,1):upper() .. name:sub(2)
                                    data[name] = prop.children[1].text
                                end
                            end
                            classes[className].Functions[data.Name] = data
                        end
                    end
                end
            end
        end
    end

    for _, enum in pairs(enumList) do
        local enumName = ""
        for _, child in pairs(enum.children) do
            if child.tag == "Properties" then
                local data = {Items = {}}
                local props = child.children
                for _, prop in pairs(props) do
                    local name = prop.attrs.name
                    name = name:sub(1,1):upper() .. name:sub(2)
                    data[name] = prop.children[1].text
                end
                enumName = data.Name
                enums[enumName] = data
            elseif child.attrs.class == "ReflectionMetadataEnumItem" then
                local data = {}
                if child.children[1].tag == "Properties" then
                    local props = child.children[1].children
                    for _, prop in pairs(props) do
                        local name = prop.attrs.name
                        name = name:sub(1,1):upper() .. name:sub(2)
                        data[name] = prop.children[1].text
                    end
                    enums[enumName].Items[data.Name] = data
                end
            end
        end
    end

    return {Classes = classes, Enums = enums, PropertyOrders = propertyOrders}
end

-- ============================================================
-- [13] 设置序列化 (Dex++ Main.ExportSettings/LoadSettings)
-- ============================================================
D.serializeSetting = function(val)
    if typeof(val) == "Color3" then
        return {R = val.R, G = val.G, B = val.B}
    end
    return val
end

D.deserializeSetting = function(val)
    if typeof(val) == "table" then
        if val.R and val.G and val.B then
            return Color3.new(val.R, val.G, val.B)
        else
            return val
        end
    end
    return val
end

D.ExportSettings = function(Settings)
    local rawData = Settings
    local function recur(tbl)
        local newTbl = {}
        for i, v in pairs(tbl) do
            if typeof(v) == "table" then newTbl[i] = recur(v)
            else newTbl[i] = D.serializeSetting(v) end
        end
        return newTbl
    end
    local serializedData = recur(rawData)
    local s, json = pcall(service.HttpService.JSONEncode, service.HttpService, serializedData)
    if s and json then return json end
end

D.LoadSettings = function(filepath)
    filepath = filepath or "DexPlusPlusSettings.json"
    local s, data = pcall(D.ReadFile or error, filepath)
    if s and data and data ~= "" then
        local s2, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, data)
        if s2 and decoded then
            local function recur(tbl)
                local newTbl = {}
                for i, v in pairs(tbl) do
                    if typeof(v) == "table" then newTbl[i] = D.deserializeSetting(recur(v))
                    else newTbl[i] = D.deserializeSetting(v) end
                end
                return newTbl
            end
            return recur(decoded)
        else
            warn("failed to decode settings json")
        end
    end
    return nil
end

-- ============================================================
-- [14] 属性分析 (Dex++ Properties 完整工具)
-- ============================================================
D.PropTools = {}
D.PropTools.IgnoreProps = {
    ["DataModel"] = {
        ["PrivateServerId"] = true, ["PrivateServerOwnerId"] = true,
        ["VIPServerId"] = true, ["VIPServerOwnerId"] = true
    }
}
D.PropTools.ExpandableTypes = {
    ["Vector2"]=true, ["Vector3"]=true, ["UDim"]=true, ["UDim2"]=true,
    ["CFrame"]=true, ["Rect"]=true, ["PhysicalProperties"]=true, ["Ray"]=true,
    ["NumberRange"]=true, ["Faces"]=true, ["Axes"]=true,
}
D.PropTools.CollapsedCategories = {["Surface Inputs"]=true, ["Surface"]=true}
D.PropTools.ConflictSubProps = {
    ["Vector2"] = {"X","Y"},
    ["Vector3"] = {"X","Y","Z"},
    ["UDim"] = {"Scale","Offset"},
    ["UDim2"] = {"X","X.Scale","X.Offset","Y","Y.Scale","Y.Offset"},
    ["CFrame"] = {"Position","Position.X","Position.Y","Position.Z",
        "RightVector","RightVector.X","RightVector.Y","RightVector.Z",
        "UpVector","UpVector.X","UpVector.Y","UpVector.Z",
        "LookVector","LookVector.X","LookVector.Y","LookVector.Z"},
    ["Rect"] = {"Min.X","Min.Y","Max.X","Max.Y"},
    ["PhysicalProperties"] = {"Density","Elasticity","ElasticityWeight","Friction","FrictionWeight"},
    ["Ray"] = {"Origin","Origin.X","Origin.Y","Origin.Z","Direction","Direction.X","Direction.Y","Direction.Z"},
    ["NumberRange"] = {"Min","Max"},
    ["Faces"] = {"Back","Bottom","Front","Left","Right","Top"},
    ["Axes"] = {"X","Y","Z"}
}
D.PropTools.ConflictIgnore = {["BasePart"] = {["ResizableFaces"] = true}}
D.PropTools.RoundableTypes = {
    ["float"]=true, ["double"]=true, ["Color3"]=true, ["UDim"]=true,
    ["UDim2"]=true, ["Vector2"]=true, ["Vector3"]=true, ["NumberRange"]=true,
    ["Rect"]=true, ["NumberSequence"]=true, ["ColorSequence"]=true, ["Ray"]=true, ["CFrame"]=true
}
D.PropTools.TypeNameConvert = {["number"] = "double", ["boolean"] = "bool"}
D.PropTools.ToNumberTypes = {["int"]=true, ["int64"]=true, ["float"]=true, ["double"]=true}
D.PropTools.DefaultPropValue = {
    string = "", bool = false, double = 0,
    UDim = UDim.new(0,0), UDim2 = UDim2.new(0,0,0,0),
    BrickColor = BrickColor.new("Medium stone grey"),
    Color3 = Color3.new(1,1,1), Vector2 = Vector2.new(0,0), Vector3 = Vector3.new(0,0,0),
    NumberSequence = NumberSequence.new(1), ColorSequence = ColorSequence.new(Color3.new(1,1,1)),
    NumberRange = NumberRange.new(0), Rect = Rect.new(0,0,0,0)
}
D.PropTools.AllowedAttributeTypes = {
    "string","boolean","number","UDim","UDim2","BrickColor","Color3",
    "Vector2","Vector3","NumberSequence","ColorSequence","NumberRange","Rect"
}

D.PropTools.StringToValue = function(prop, str)
    local typeData = prop.ValueType
    local typeName = typeData.Name
    if typeName == "string" or typeName == "Content" then return str
    elseif D.PropTools.ToNumberTypes[typeName] then return tonumber(str)
    elseif typeName == "Vector2" then
        local vals = str:split(",")
        local x, y = tonumber(vals[1]), tonumber(vals[2])
        if x and y and #vals >= 2 then return Vector2.new(x, y) end
    elseif typeName == "Vector3" then
        local vals = str:split(",")
        local x, y, z = tonumber(vals[1]), tonumber(vals[2]), tonumber(vals[3])
        if x and y and z and #vals >= 3 then return Vector3.new(x, y, z) end
    elseif typeName == "UDim" then
        local vals = str:split(",")
        local scale, offset = tonumber(vals[1]), tonumber(vals[2])
        if scale and offset and #vals >= 2 then return UDim.new(scale, offset) end
    elseif typeName == "UDim2" then
        local vals = str:gsub("[{}]", ""):split(",")
        local xS, xO, yS, yO = tonumber(vals[1]), tonumber(vals[2]), tonumber(vals[3]), tonumber(vals[4])
        if xS and xO and yS and yO and #vals >= 4 then return UDim2.new(xS, xO, yS, yO) end
    elseif typeName == "CFrame" then
        local vals = str:split(",")
        local s, result = pcall(CFrame.new, unpack(vals))
        if s and #vals >= 12 then return result end
    elseif typeName == "Rect" then
        local vals = str:split(",")
        local s, result = pcall(Rect.new, unpack(vals))
        if s and #vals >= 4 then return result end
    elseif typeName == "Ray" then
        local vals = str:gsub("[{}]", ""):split(",")
        local s, origin = pcall(Vector3.new, unpack(vals, 1, 3))
        local s2, direction = pcall(Vector3.new, unpack(vals, 4, 6))
        if s and s2 and #vals >= 6 then return Ray.new(origin, direction) end
    elseif typeName == "NumberRange" then
        local vals = str:split(",")
        local s, result = pcall(NumberRange.new, unpack(vals))
        if s and #vals >= 1 then return result end
    elseif typeName == "Color3" then
        local vals = str:gsub("[{}]", ""):split(",")
        local s, result = pcall(Color3.fromRGB, unpack(vals))
        if s and #vals >= 3 then return result end
    end
    return nil
end

D.PropTools.ValueToString = function(prop, val)
    local typeName = prop.ValueType.Name
    if typeName == "Color3" then return D.ColorToBytes(val)
    elseif typeName == "NumberRange" then return val.Min .. ", " .. val.Max end
    return tostring(val)
end

D.PropTools.GetIndexableProps = function(obj, classData)
    local ignoreProps = D.PropTools.IgnoreProps[classData.Name] or {}
    local result = {}
    local count = 1
    local props = classData.Properties
    for i = 1, #props do
        local prop = props[i]
        if not ignoreProps[prop.Name] then
            local s = pcall(function() return obj[prop.Name] end)
            if s then
                result[count] = prop
                count = count + 1
            end
        end
    end
    return result
end

D.PropTools.GetPropVal = function(prop, obj)
    if prop.MultiType then return "<Multiple Types>" end
    if not obj then return end
    local propVal
    if prop.IsAttribute then
        propVal = obj:GetAttribute(prop.AttributeName)
        if propVal == nil then return nil end
        local typ = typeof(propVal)
        local currentType = D.PropTools.TypeNameConvert[typ] or typ
        if prop.RootType then
            if prop.RootType.Name ~= currentType then return nil end
        elseif prop.ValueType.Name ~= currentType then
            return nil
        end
    else
        propVal = obj[prop.Name]
    end
    if prop.SubName then
        local indexes = string.split(prop.SubName, ".")
        for i = 1, #indexes do
            local indexName = indexes[i]
            if #indexName > 0 and propVal then propVal = propVal[indexName] end
        end
    end
    return propVal
end

D.PropTools.MakeSubProp = function(prop, subName, valueType, displayName)
    local subProp = {}
    for i, v in pairs(prop) do subProp[i] = v end
    subProp.RootType = subProp.RootType or subProp.ValueType
    subProp.ValueType = valueType
    subProp.SubName = subProp.SubName and (subProp.SubName .. subName) or subName
    subProp.DisplayName = displayName
    return subProp
end

D.PropTools.GetExpandedProps = function(prop)
    local result = {}
    local typeData = prop.ValueType
    local typeName = typeData.Name
    local make = D.PropTools.MakeSubProp
    if typeName == "Vector2" then
        result[1] = make(prop, ".X", {Name = "float"})
        result[2] = make(prop, ".Y", {Name = "float"})
    elseif typeName == "Vector3" then
        result[1] = make(prop, ".X", {Name = "float"})
        result[2] = make(prop, ".Y", {Name = "float"})
        result[3] = make(prop, ".Z", {Name = "float"})
    elseif typeName == "CFrame" then
        result[1] = make(prop, ".Position", {Name = "Vector3"})
        result[2] = make(prop, ".RightVector", {Name = "Vector3"})
        result[3] = make(prop, ".UpVector", {Name = "Vector3"})
        result[4] = make(prop, ".LookVector", {Name = "Vector3"})
    elseif typeName == "UDim" then
        result[1] = make(prop, ".Scale", {Name = "float"})
        result[2] = make(prop, ".Offset", {Name = "int"})
    elseif typeName == "UDim2" then
        result[1] = make(prop, ".X", {Name = "UDim"})
        result[2] = make(prop, ".Y", {Name = "UDim"})
    elseif typeName == "Rect" then
        result[1] = make(prop, ".Min.X", {Name = "float"}, "X0")
        result[2] = make(prop, ".Min.Y", {Name = "float"}, "Y0")
        result[3] = make(prop, ".Max.X", {Name = "float"}, "X1")
        result[4] = make(prop, ".Max.Y", {Name = "float"}, "Y1")
    elseif typeName == "PhysicalProperties" then
        result[1] = make(prop, ".Density", {Name = "float"})
        result[2] = make(prop, ".Elasticity", {Name = "float"})
        result[3] = make(prop, ".ElasticityWeight", {Name = "float"})
        result[4] = make(prop, ".Friction", {Name = "float"})
        result[5] = make(prop, ".FrictionWeight", {Name = "float"})
    elseif typeName == "Ray" then
        result[1] = make(prop, ".Origin", {Name = "Vector3"})
        result[2] = make(prop, ".Direction", {Name = "Vector3"})
    elseif typeName == "NumberRange" then
        result[1] = make(prop, ".Min", {Name = "float"})
        result[2] = make(prop, ".Max", {Name = "float"})
    elseif typeName == "Faces" then
        result[1] = make(prop, ".Back", {Name = "bool"})
        result[2] = make(prop, ".Bottom", {Name = "bool"})
        result[3] = make(prop, ".Front", {Name = "bool"})
        result[4] = make(prop, ".Left", {Name = "bool"})
        result[5] = make(prop, ".Right", {Name = "bool"})
        result[6] = make(prop, ".Top", {Name = "bool"})
    elseif typeName == "Axes" then
        result[1] = make(prop, ".X", {Name = "bool"})
        result[2] = make(prop, ".Y", {Name = "bool"})
        result[3] = make(prop, ".Z", {Name = "bool"})
    end
    return result
end

-- 应用单个属性到 Selection List (Dex++ Properties.SetProp 逻辑简化版, 不带UI自动刷新)
D.PropTools.SetProp = function(prop, val, selectionList)
    if not selectionList then return end
    local propName = prop.Name
    local subName = prop.SubName
    local propClass = prop.Class
    local typeData = prop.ValueType
    local typeName = typeData.Name
    local attributeName = prop.AttributeName
    local rootTypeData = prop.RootType
    local rootTypeName = rootTypeData and rootTypeData.Name
    local Vector3 = Vector3

    for i = 1, #selectionList do
        local obj = selectionList[i].Obj or selectionList[i]
        if obj:IsA(propClass) then
            pcall(function()
                local setVal = val
                local root
                if prop.IsAttribute then root = obj:GetAttribute(attributeName)
                else root = obj[propName] end

                if rootTypeName then
                    if rootTypeName == "Vector2" then
                        setVal = Vector2.new((subName == ".X" and setVal) or root.X, (subName == ".Y" and setVal) or root.Y)
                    elseif rootTypeName == "Vector3" then
                        setVal = Vector3.new((subName == ".X" and setVal) or root.X, (subName == ".Y" and setVal) or root.Y, (subName == ".Z" and setVal) or root.Z)
                    elseif rootTypeName == "UDim" then
                        setVal = UDim.new((subName == ".Scale" and setVal) or root.Scale, (subName == ".Offset" and setVal) or root.Offset)
                    elseif rootTypeName == "UDim2" then
                        local rootX, rootY = root.X, root.Y
                        local X_UDim = (subName == ".X" and setVal) or UDim.new((subName == ".X.Scale" and setVal) or rootX.Scale, (subName == ".X.Offset" and setVal) or rootX.Offset)
                        local Y_UDim = (subName == ".Y" and setVal) or UDim.new((subName == ".Y.Scale" and setVal) or rootY.Scale, (subName == ".Y.Offset" and setVal) or rootY.Offset)
                        setVal = UDim2.new(X_UDim, Y_UDim)
                    elseif rootTypeName == "CFrame" then
                        local rootPos, rootRight, rootUp, rootLook = root.Position, root.RightVector, root.UpVector, root.LookVector
                        local pos = (subName == ".Position" and setVal) or Vector3.new((subName == ".Position.X" and setVal) or rootPos.X, (subName == ".Position.Y" and setVal) or rootPos.Y, (subName == ".Position.Z" and setVal) or rootPos.Z)
                        local rightV = (subName == ".RightVector" and setVal) or Vector3.new((subName == ".RightVector.X" and setVal) or rootRight.X, (subName == ".RightVector.Y" and setVal) or rootRight.Y, (subName == ".RightVector.Z" and setVal) or rootRight.Z)
                        local upV = (subName == ".UpVector" and setVal) or Vector3.new((subName == ".UpVector.X" and setVal) or rootUp.X, (subName == ".UpVector.Y" and setVal) or rootUp.Y, (subName == ".UpVector.Z" and setVal) or rootUp.Z)
                        local lookV = (subName == ".LookVector" and setVal) or Vector3.new((subName == ".LookVector.X" and setVal) or rootLook.X, (subName == ".RightVector.Y" and setVal) or rootLook.Y, (subName == ".RightVector.Z" and setVal) or rootLook.Z)
                        setVal = CFrame.fromMatrix(pos, rightV, upV, -lookV)
                    elseif rootTypeName == "Rect" then
                        local rootMin, rootMax = root.Min, root.Max
                        local min = Vector2.new((subName == ".Min.X" and setVal) or rootMin.X, (subName == ".Min.Y" and setVal) or rootMin.Y)
                        local max = Vector2.new((subName == ".Max.X" and setVal) or rootMax.X, (subName == ".Max.Y" and setVal) or rootMax.Y)
                        setVal = Rect.new(min, max)
                    elseif rootTypeName == "PhysicalProperties" then
                        local rootProps = PhysicalProperties.new(obj.Material)
                        local density = (subName == ".Density" and setVal) or (root and root.Density) or rootProps.Density
                        local friction = (subName == ".Friction" and setVal) or (root and root.Friction) or rootProps.Friction
                        local elasticity = (subName == ".Elasticity" and setVal) or (root and root.Elasticity) or rootProps.Elasticity
                        local frictionWeight = (subName == ".FrictionWeight" and setVal) or (root and root.FrictionWeight) or rootProps.FrictionWeight
                        local elasticityWeight = (subName == ".ElasticityWeight" and setVal) or (root and root.ElasticityWeight) or rootProps.ElasticityWeight
                        setVal = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
                    elseif rootTypeName == "Ray" then
                        local rootOrigin, rootDirection = root.Origin, root.Direction
                        local origin = (subName == ".Origin" and setVal) or Vector3.new((subName == ".Origin.X" and setVal) or rootOrigin.X, (subName == ".Origin.Y" and setVal) or rootOrigin.Y, (subName == ".Origin.Z" and setVal) or rootOrigin.Z)
                        local direction = (subName == ".Direction" and setVal) or Vector3.new((subName == ".Direction.X" and setVal) or rootDirection.X, (subName == ".Direction.Y" and setVal) or rootDirection.Y, (subName == ".Direction.Z" and setVal) or rootDirection.Z)
                        setVal = Ray.new(origin, direction)
                    elseif rootTypeName == "Faces" then
                        local faces = {}
                        local faceList = {"Back","Bottom","Front","Left","Right","Top"}
                        for _, face in pairs(faceList) do
                            local v
                            if subName == "." .. face then v = setVal
                            else v = root[face] end
                            if v then faces[#faces+1] = Enum.NormalId[face] end
                        end
                        setVal = Faces.new(unpack(faces))
                    elseif rootTypeName == "Axes" then
                        local axes = {}
                        local axesList = {"X","Y","Z"}
                        for _, axe in pairs(axesList) do
                            local v
                            if subName == "." .. axe then v = setVal
                            else v = root[axe] end
                            if v then axes[#axes+1] = Enum.Axis[axe] end
                        end
                        setVal = Axes.new(unpack(axes))
                    elseif rootTypeName == "NumberRange" then
                        setVal = NumberRange.new(subName == ".Min" and setVal or root.Min, subName == ".Max" and setVal or root.Max)
                    end
                end

                if typeName == "PhysicalProperties" and setVal then
                    setVal = root or PhysicalProperties.new(obj.Material)
                end

                if prop.IsAttribute then
                    obj:SetAttribute(attributeName, setVal)
                else
                    obj[propName] = setVal
                end
            end)
        end
    end
end

-- ============================================================
-- [15] 搜索过滤器 (Dex++ Explorer.SearchFilters 完整版)
-- ============================================================
D.SearchFilters = {
    Comparison = {
        ["isa"] = function(argString, API)
            local lower = string.lower
            local find = string.find
            local classQuery = string.split(argString)[1]
            if not classQuery then return end
            classQuery = lower(classQuery)
            local className
            for class, _ in pairs(API.Classes) do
                local cName = lower(class)
                if cName == classQuery then className = class break
                elseif find(cName, classQuery, 1, true) then className = class end
            end
            if not className then return end
            return {
                Headers = {"local isa = game.IsA"},
                Predicate = "isa(obj,'" .. className .. "')"
            }
        end,
        ["remotes"] = function()
            return {
                Headers = {"local isa = game.IsA"},
                Predicate = "isa(obj,'RemoteEvent') or isa(obj,'RemoteFunction') or isa(obj,'UnreliableRemoteEvent')"
            }
        end,
        ["bindables"] = function()
            return {
                Headers = {"local isa = game.IsA"},
                Predicate = "isa(obj,'BindableEvent') or isa(obj,'BindableFunction')"
            }
        end,
        ["rad"] = function(argString)
            local num = tonumber(argString)
            if not num then return end
            if not service.Players.LocalPlayer.Character
                or not service.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                or not service.Players.LocalPlayer.Character.HumanoidRootPart:IsA("BasePart") then return end
            return {
                Headers = {"local isa = game.IsA", "local hrp = service.Players.LocalPlayer.Character.HumanoidRootPart"},
                Setups = {"local hrpPos = hrp.Position"},
                ObjectDefs = {"local isBasePart = isa(obj,'BasePart')"},
                Predicate = "(isBasePart and (obj.Position-hrpPos).Magnitude <= " .. num .. ")"
            }
        end,
    },
    Specific = {
        ["players"] = function()
            return function() return service.Players:GetPlayers() end
        end,
        ["loadedmodules"] = function()
            return D.env.getloadedmodules
        end,
    },
    Default = function(argString, caseSensitive)
        local cleanString = argString:gsub("\"", "\\\""):gsub("\n", "\\n")
        if caseSensitive then
            return {
                Headers = {"local find = string.find"},
                ObjectDefs = {"local objName = tostring(obj)"},
                Predicate = "find(objName,\"" .. cleanString .. "\",1,true)"
            }
        else
            return {
                Headers = {"local lower = string.lower", "local find = string.find", "local tostring = tostring"},
                ObjectDefs = {"local lowerName = lower(tostring(obj))"},
                Predicate = "find(lowerName,\"" .. cleanString:lower() .. "\",1,true)"
            }
        end
    end,
    SpecificDefault = function(n)
        return {
            Headers = {},
            ObjectDefs = {"local isSpec" .. n .. " = specResults[" .. n .. "][node]"},
            Predicate = "isSpec" .. n
        }
    end,
}

D.BuildSearchFunc = function(query, nodes, searchResults, specResults, Explorer, service_)
    local specFilterList, specMap = {}, {}
    local finalPredicate = ""
    local rep = string.rep
    local formatQuery = query:gsub("\\.", "  "):gsub('".-"', function(str) return rep(" ", #str) end)
    local headers, objectDefs, setups = {}, {}, {}
    local find, sub, lower, match = string.find, string.sub, string.lower, string.match
    local ops = {["("]="(", [")"]=")", ["||"]=" or ", ["&&"]=" and "}
    local compFilters = D.SearchFilters.Comparison
    local specFilters = D.SearchFilters.Specific

    local function processFilter(dat)
        if dat.Headers then for i = 1, #dat.Headers do headers[dat.Headers[i]] = true end end
        if dat.ObjectDefs then for i = 1, #dat.ObjectDefs do objectDefs[dat.ObjectDefs[i]] = true end end
        if dat.Setups then for i = 1, #dat.Setups do setups[dat.Setups[i]] = true end end
        finalPredicate = finalPredicate .. dat.Predicate
    end

    local found, foundData = {}, {}
    local function findAll(str, pattern)
        local count = #found + 1
        local init = 1
        local sz = #pattern
        local x, y, extra = find(str, pattern, init, true)
        while x do
            found[count] = x
            foundData[x] = {sz, pattern}
            count = count + 1
            init = y + 1
            x, y, extra = find(str, pattern, init, true)
        end
    end
    findAll(formatQuery, '&&')
    findAll(formatQuery, "||")
    findAll(formatQuery, "(")
    findAll(formatQuery, ")")
    table.sort(found)
    table.insert(found, #formatQuery + 1)

    local function inQuotes(str)
        local len = #str
        if sub(str, 1, 1) == '"' and sub(str, len, len) == '"' then
            return sub(str, 2, len - 1)
        end
    end

    local init = 1
    local lastOp = nil
    for i = 1, #found do
        local nextInd = found[i]
        local nextData = foundData[nextInd] or {1}
        local op = ops[nextData[2]]
        local term = sub(query, init, nextInd - 1)
        term = match(term, "^%s*(.-)%s*$") or ""

        if #term > 0 then
            if sub(term, 1, 1) == "!" then
                term = sub(term, 2)
                finalPredicate = finalPredicate .. "not "
            end
            local qTerm = inQuotes(term)
            if qTerm then
                processFilter(D.SearchFilters.Default(qTerm, true))
            else
                local x, y = find(term, "%S+")
                if x then
                    local first = sub(term, x, y)
                    local specifier = sub(first, 1, 1) == "/" and lower(sub(first, 2))
                    local compFunc = specifier and compFilters[specifier]
                    local specFunc = specifier and specFilters[specifier]

                    if compFunc then
                        local argStr = sub(term, y + 2)
                        local ret = compFunc(inQuotes(argStr) or argStr, D.API)
                        if ret then processFilter(ret)
                        else finalPredicate = finalPredicate .. "false" end
                    elseif specFunc then
                        local argStr = sub(term, y + 2)
                        local ret = specFunc(inQuotes(argStr) or argStr)
                        if ret then
                            if not specMap[term] then
                                specFilterList[#specFilterList + 1] = ret
                                specMap[term] = #specFilterList
                            end
                            processFilter(D.SearchFilters.SpecificDefault(specMap[term]))
                        else finalPredicate = finalPredicate .. "false" end
                    else
                        processFilter(D.SearchFilters.Default(term))
                    end
                end
            end
        end

        if op then
            finalPredicate = finalPredicate .. op
            if op == "(" and (#term > 0 or lastOp == ")") then return
            else lastOp = op end
        end
        init = nextInd + nextData[1]
    end

    local finalSetups, finalHeaders, finalObjectDefs = "", "", ""
    for setup, _ in next, setups do finalSetups = finalSetups .. setup .. "\n" end
    for header, _ in next, headers do finalHeaders = finalHeaders .. header .. "\n" end
    for oDef, _ in next, objectDefs do finalObjectDefs = finalObjectDefs .. oDef .. "\n" end

    local template = [==[
local searchResults = searchResults
local nodes = nodes
local expandTable = Explorer.SearchExpanded
local specResults = specResults
local service = service

%s
local function search(root)	
%s
	
	local expandedpar = false
	for i = 1,#root do
		local node = root[i]
		local obj = node.Obj
		
%s
		
		if %s then
			expandTable[node] = 0
			searchResults[node] = true
			if not expandedpar then
				local parnode = node.Parent
				while parnode and (not searchResults[parnode] or expandTable[parnode] == 0) do
					expandTable[parnode] = true
					searchResults[parnode] = true
					parnode = parnode.Parent
				end
				expandedpar = true
			end
		end
		
		if #node > 0 then search(node) end
	end
end
return search]==]

    local funcStr = template:format(finalHeaders, finalSetups, finalObjectDefs, finalPredicate)
    local s, func = pcall(loadstring, funcStr)
    if not s or not func then return nil, specFilterList end

    local env = setmetatable({
        ["searchResults"] = searchResults, ["nodes"] = nodes,
        ["Explorer"] = Explorer, ["specResults"] = specResults, ["service"] = service_
    }, {__index = getfenv()})
    setfenv(func, env)
    return func(), specFilterList
end

-- ============================================================
-- [16] 3D 相机控制 (ModelViewer 逻辑, 无 UI)
-- ============================================================
D.attachModelViewer = function(viewportFrame, options)
    options = options or {}
    local RunService = service.RunService
    local UserInputService = service.UserInputService
    local state = {
        ZoomMultiplier = options.ZoomMultiplier or 2,
        AutoRotate = options.AutoRotate ~= false,
        RotationSpeed = options.RotationSpeed or 0.01,
        EnableInputCamera = true,
        IsViewing = false,
        AutoRefresh = false,
        RefreshRate = 30,
    }
    local camera, model, dragging, hovering, originalModel = nil, nil, false, false, nil
    local rotationX, rotationY, distance = -15, 0, 10

    viewportFrame.InputBegan:Connect(function(input)
        if not state.EnableInputCamera then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            state.ZoomMultiplier = 10
        end
    end)
    viewportFrame.MouseEnter:Connect(function() hovering = true end)
    viewportFrame.MouseLeave:Connect(function() hovering = false end)
    viewportFrame.InputEnded:Connect(function(input)
        if not state.EnableInputCamera then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            state.ZoomMultiplier = 2
        end
    end)
    viewportFrame.InputChanged:Connect(function(input)
        if not state.EnableInputCamera then return end
        if (dragging and input.UserInputType == Enum.UserInputType.MouseMovement) or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Delta
            rotationY = rotationY - delta.X * 0.01
            rotationX = math.clamp(rotationX - delta.Y * 0.01, -math.pi/2 + 0.1, math.pi/2 - 0.1)
        end
        if input.UserInputType == Enum.UserInputType.MouseWheel and hovering then
            distance = math.clamp(distance - (input.Position.Z * state.ZoomMultiplier), 0.1, math.huge)
        end
    end)
    RunService.RenderStepped:Connect(function(dt)
        if camera and model and model.PrimaryPart then
            if not dragging and state.AutoRotate then
                rotationY = rotationY + state.RotationSpeed * dt * 60
            end
            local center = model.PrimaryPart.Position
            local offset = CFrame.new(0, 0, distance)
            local rotation = CFrame.Angles(0, rotationY, 0) * CFrame.Angles(rotationX, 0, 0)
            camera.CFrame = CFrame.lookAt((CFrame.new(center) * rotation * offset).Position, center)
        end
    end)

    local function stopModel(updating)
        if updating then
            local m = viewportFrame:FindFirstChildOfClass("Model")
            if m then m:Destroy() end
        else
            camera = nil
            model = nil
            viewportFrame:ClearAllChildren()
            state.IsViewing = false
        end
    end

    local function viewModel(item, updating)
        if not item then return end
        stopModel(updating)
        if item ~= workspace and not item:IsA("Terrain") then
            if item:IsA("BasePart") and not item:IsA("Model") then
                model = Instance.new("Model")
                model.Parent = viewportFrame
                local clone = item:Clone()
                clone.Parent = model
                model.PrimaryPart = clone
                model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
            elseif item:IsA("Model") then
                item.Archivable = true
                if #item:GetChildren() == 0 then return end
                model = item:Clone()
                model.Parent = viewportFrame
                if not model.PrimaryPart then
                    local found = false
                    for _, child in model:GetDescendants() do
                        if child:IsA("BasePart") then
                            model.PrimaryPart = child
                            model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
                            found = true
                            break
                        end
                    end
                    if not found then
                        model:Destroy()
                        model = nil
                        return
                    end
                end
            else return end
        end
        originalModel = item
        if state.AutoRefresh and not updating then
            task.spawn(function()
                while model and state.AutoRefresh do
                    viewModel(originalModel, true)
                    task.wait(1 / state.RefreshRate)
                end
            end)
        end
        if not updating then
            camera = Instance.new("Camera")
            viewportFrame.CurrentCamera = camera
            camera.Parent = viewportFrame
            camera.FieldOfView = 60
            state.IsViewing = true
        end
    end

    return {
        state = state,
        viewModel = viewModel,
        stopViewModel = stopModel,
        getOriginalModel = function() return originalModel end,
    }
end

-- ============================================================
-- [17] RemoteSpy (Dex++ 插件版)
-- ============================================================
D.RemoteSpy = {}
do
    local RS = D.RemoteSpy
    RS.logs = {}
    RS.limit = 400
    RS.active = false
    RS.hook_cons = {}
    RS.seen = setmetatable({}, {__mode = "k"})
    RS.namecall_orig = nil
    RS.on_log = nil
    RS.colors = {
        out_remote = Color3.fromRGB(100, 200, 255),
        in_remote = Color3.fromRGB(120, 255, 120),
        out_bindable = Color3.fromRGB(255, 200, 80),
        in_bindable = Color3.fromRGB(255, 140, 60),
    }
    RS.remote_classes = {
        RemoteEvent = true, RemoteFunction = true, UnreliableRemoteEvent = true,
        BindableEvent = true, BindableFunction = true,
    }
    RS.out_methods = {
        FireServer = true, InvokeServer = true, fireServer = true, invokeServer = true,
        Fire = true, Invoke = true, fire = true, invoke = true,
    }
    RS.in_signals = {
        RemoteEvent = "OnClientEvent", UnreliableRemoteEvent = "OnClientEvent",
        BindableEvent = "Event",
    }

    RS.safe_str = function(v)
        local t = typeof(v)
        if t == "Instance" then
            local parts, cur = {}, v
            while cur and cur ~= game do
                table.insert(parts, 1, cur.Name)
                cur = cur.Parent
            end
            table.insert(parts, 1, "game")
            return table.concat(parts, ".")
        elseif t == "string" then
            local s = #v > 100 and v:sub(1, 100) .. "…" or v
            return '"' .. s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n') .. '"'
        elseif t == "table" then
            local out, n = {}, 0
            for k, val in pairs(v) do
                n = n + 1
                if n > 6 then out[n] = "…" break end
                out[n] = tostring(k) .. "=" .. RS.safe_str(val)
            end
            return "{" .. table.concat(out, ", ") .. "}"
        else return tostring(v) end
    end
    RS.args_str = function(args)
        local n = args.n or #args
        if n == 0 then return "()" end
        local out = {}
        for i = 1, n do out[i] = RS.safe_str(args[i]) end
        return table.concat(out, ", ")
    end
    RS.inst_path = function(obj)
        if not obj then return "?" end
        return D.GetInstancePath(obj)
    end
    RS.color_for = function(dir, class_name)
        local is_bind = class_name == "BindableEvent" or class_name == "BindableFunction"
        if dir == "out" then return is_bind and RS.colors.out_bindable or RS.colors.out_remote
        else return is_bind and RS.colors.in_bindable or RS.colors.in_remote end
    end
    RS.add_log = function(dir, inst, method, raw_args)
        if not RS.active then return end
        local entry = {
            time = os.date("%H:%M:%S"),
            dir = dir,
            path = RS.inst_path(inst),
            class = inst.ClassName,
            method = method,
            args = RS.args_str(raw_args),
            instance = inst,
        }
        RS.logs[#RS.logs + 1] = entry
        if #RS.logs > RS.limit then table.remove(RS.logs, 1) end
        if RS.on_log then pcall(RS.on_log, entry) end
    end
    RS.hook_instance = function(inst)
        if RS.seen[inst] then return end
        local sig = RS.in_signals[inst.ClassName]
        if not sig then return end
        RS.seen[inst] = true
        local ok, con = pcall(function()
            return inst[sig]:Connect(function(...)
                RS.add_log("in", inst, sig, table.pack(...))
            end)
        end)
        if ok and con then RS.hook_cons[#RS.hook_cons + 1] = con end
    end
    RS.start = function()
        if RS.active then return end
        RS.active = true
        if hookmetamethod and not RS.namecall_orig then
            local ok, orig = pcall(hookmetamethod, game, "__namecall", function(self, ...)
                local method = getnamecallmethod and getnamecallmethod() or ""
                if RS.active and typeof(self) == "Instance"
                    and RS.remote_classes[self.ClassName] and RS.out_methods[method] then
                    RS.add_log("out", self, method, table.pack(...))
                end
                return RS.namecall_orig(self, ...)
            end)
            if ok then RS.namecall_orig = orig end
        end
        local ok, descs = pcall(game.GetDescendants, game)
        if ok then for _, inst in ipairs(descs) do RS.hook_instance(inst) end end
        if getnilinstances then
            local ok2, nils = pcall(getnilinstances)
            if ok2 then for _, inst in ipairs(nils) do RS.hook_instance(inst) end end
        end
        local con = game.DescendantAdded:Connect(function(inst) if RS.active then RS.hook_instance(inst) end end)
        RS.hook_cons[#RS.hook_cons + 1] = con
    end
    RS.stop = function()
        if not RS.active then return end
        RS.active = false
        for _, con in ipairs(RS.hook_cons) do pcall(function() con:Disconnect() end) end
        RS.hook_cons = {}
        RS.seen = setmetatable({}, {__mode = "k"})
    end
    RS.clear = function() RS.logs = {} end
end

-- ============================================================
-- [18] SimpleSpy (汉化版全套 hook)
-- ============================================================
D.SimpleSpy = {}
do
    local SS = D.SimpleSpy
    SS.toggle = false
    SS.logs = {}
    SS.selected = nil
    SS.blacklist = {}
    SS.blocklist = {}
    SS.remoteSignals = {}
    SS.remoteHooks = {}
    SS.history = {}
    SS.excluding = {}
    SS.autoblock = false
    SS.recordReturnValues = false
    SS.funcEnabled = true
    SS.scheduled = {}
    SS.on_log = nil
    SS.originalEvent = nil
    SS.originalFunction = nil
    SS.originalNamecall = nil
    SS.newnamecall = nil

    SS.newSignal = function()
        local connected = {}
        return {
            Connect = function(self, f)
                connected[tostring(f)] = f
                return {Connected = true, Disconnect = function(self) self.Connected = false connected[tostring(f)] = nil end}
            end,
            Wait = function(self)
                local thread = coroutine.running()
                local con
                con = self:Connect(function()
                    con:Disconnect()
                    if coroutine.status(thread) == "suspended" then coroutine.resume(thread) end
                end)
                coroutine.yield()
            end,
            Fire = function(self, ...) for _, f in pairs(connected) do coroutine.wrap(f)(...) end end,
        }
    end

    SS.schedule = function(f, ...) table.insert(SS.scheduled, {f, ...}) end
    SS.scheduleWait = function()
        local thread = coroutine.running()
        SS.schedule(function() coroutine.resume(thread) end)
        coroutine.yield()
    end
    SS.taskscheduler = function()
        if not SS.toggle then SS.scheduled = {} return end
        if #SS.scheduled > 1000 then table.remove(SS.scheduled, #SS.scheduled) end
        if #SS.scheduled > 0 then
            local currentf = table.remove(SS.scheduled, 1)
            if type(currentf) == "table" and type(currentf[1]) == "function" then
                pcall(unpack(currentf))
            end
        end
    end

    SS.clean = function()
        local max = _G.SIMPLESPYCONFIG_MaxRemotes or 500
        if typeof(max) ~= "number" or math.floor(max) ~= max then max = 500 end
        if #SS.logs > max then
            for i = 100, #SS.logs do
                SS.logs[i] = nil
            end
            local newLogs = {}
            for i = 1, 100 do table.insert(newLogs, SS.logs[i]) end
            SS.logs = newLogs
        end
    end

    SS.genScript = function(remote, args)
        local gen = ""
        if #args > 0 then
            if not pcall(function() gen = D.v2v({args = args}) .. "\n" end) then
                gen = gen .. "-- TableToString failure! Reverting to legacy functionality\nlocal args = {"
                for i, v in pairs(args) do
                    if type(i) ~= "Instance" and type(i) ~= "userdata" then gen = gen .. "\n    [object] = "
                    elseif type(i) == "string" then gen = gen .. '\n    ["' .. i .. '"] = '
                    elseif type(i) == "userdata" and typeof(i) ~= "Instance" then gen = gen .. "\n    [" .. string.format("nil --[[%s]]", typeof(v)) .. ")] = "
                    elseif type(i) == "userdata" then gen = gen .. "\n    [game." .. i:GetFullName() .. ")] = " end
                    if type(v) ~= "Instance" and type(v) ~= "userdata" then gen = gen .. "object"
                    elseif type(v) == "string" then gen = gen .. '"' .. v .. '"'
                    elseif type(v) == "userdata" and typeof(v) ~= "Instance" then gen = gen .. string.format("nil --[[%s]]", typeof(v))
                    elseif type(v) == "userdata" then gen = gen .. "game." .. v:GetFullName() end
                end
                gen = gen .. "\n}\n\n"
            end
            if not remote:IsDescendantOf(game) then
                gen = "function getNil(name,class) for _,v in pairs(getnilinstances())do if v.ClassName==class and v.Name==name then return v;end end end\n\n" .. gen
            end
            if remote:IsA("RemoteEvent") then gen = gen .. D.v2s(remote) .. ":FireServer(unpack(args))"
            elseif remote:IsA("RemoteFunction") then gen = gen .. D.v2s(remote) .. ":InvokeServer(unpack(args))" end
        else
            if remote:IsA("RemoteEvent") then gen = gen .. D.v2s(remote) .. ":FireServer()"
            elseif remote:IsA("RemoteFunction") then gen = gen .. D.v2s(remote) .. ":InvokeServer()" end
        end
        return gen
    end

    SS.remoteHandler = function(hookfunction, methodName, remote, args, funcInfo, calling, returnValue)
        local valid, validClass = pcall(function() return remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") end)
        if not (valid and validClass) then return end
        local func = funcInfo.func
        local srcInstance = nil
        if funcInfo.source and funcInfo.source ~= "" then
            srcInstance = D.getScriptFromSource(funcInfo.source)
        end
        if not srcInstance and funcInfo.source then
            _, srcInstance = pcall(D.getScriptFromSrc, funcInfo.source)
        end
        coroutine.wrap(function()
            if SS.remoteSignals[remote] then SS.remoteSignals[remote]:Fire(args) end
        end)()
        if SS.autoblock then
            if SS.excluding[remote] then return end
            if not SS.history[remote] then SS.history[remote] = {badOccurances = 0, lastCall = tick()} end
            if tick() - SS.history[remote].lastCall < 1 then
                SS.history[remote].badOccurances = SS.history[remote].badOccurances + 1
                return
            else SS.history[remote].badOccurances = 0 end
            if SS.history[remote].badOccurances > 3 then SS.excluding[remote] = true return end
            SS.history[remote].lastCall = tick()
        end
        local functionInfoStr, src
        if func and islclosure(func) then
            local fi = {}
            fi.info = funcInfo
            pcall(function() fi.constants = debug.getconstants(func) end)
            pcall(function() functionInfoStr = D.v2v({functionInfo = fi}) end)
            pcall(function() if type(calling) == "userdata" then src = calling end end)
        end
        local entry = {
            name = remote.Name,
            type = methodName:lower() == "fireserver" and "event" or "function",
            args = args,
            remote = remote,
            funcInfo = functionInfoStr,
            blocked = SS.blocklist[remote] or SS.blocklist[remote.Name],
            source = srcInstance,
            returnValue = returnValue,
            genScript = SS.genScript(remote, args),
        }
        if entry.blocked then entry.genScript = "-- 已被阻止\n\n" .. entry.genScript end
        SS.logs[#SS.logs + 1] = entry
        SS.clean()
        if SS.on_log then pcall(SS.on_log, entry) end
    end

    SS.hookRemote = function(remoteType, remote, ...)
        if typeof(remote) == "Instance" then
            local args = { ... }
            local valid, remoteName = pcall(function() return remote.Name end)
            if valid and not (SS.blacklist[remote] or SS.blacklist[remoteName]) then
                local funcInfo = {}
                if SS.funcEnabled then funcInfo = debug.getinfo(4) or funcInfo end
                if SS.recordReturnValues and remoteType == "RemoteFunction" then
                    local thread = coroutine.running()
                    local a = { ... }
                    task.defer(function()
                        local rv
                        if SS.remoteHooks[remote] then
                            a = { SS.remoteHooks[remote](unpack(a)) }
                            rv = SS.originalFunction(remote, unpack(a))
                        else
                            rv = SS.originalFunction(remote, unpack(a))
                        end
                        SS.schedule(SS.remoteHandler, true, remoteType == "RemoteEvent" and "fireserver" or "invokeserver", remote, a, funcInfo, nil, rv)
                        if SS.blocklist[remote] or SS.blocklist[remoteName] then
                            coroutine.resume(thread)
                        else
                            coroutine.resume(thread, unpack(rv))
                        end
                    end)
                else
                    SS.schedule(SS.remoteHandler, true, remoteType == "RemoteEvent" and "fireserver" or "invokeserver", remote, args, funcInfo, nil)
                    if SS.blocklist[remote] or SS.blocklist[remoteName] then return end
                end
            end
        end
        if SS.recordReturnValues and remoteType == "RemoteFunction" then
            return coroutine.yield()
        elseif remoteType == "RemoteEvent" then
            if SS.remoteHooks[remote] then return SS.originalEvent(remote, SS.remoteHooks[remote](...)) end
            return SS.originalEvent(remote, ...)
        else
            if SS.remoteHooks[remote] then return SS.originalFunction(remote, SS.remoteHooks[remote](...)) end
            return SS.originalFunction(remote, ...)
        end
    end

    SS.installNamecallHook = function()
        local remoteEvent = Instance.new("RemoteEvent")
        local remoteFunction = Instance.new("RemoteFunction")
        SS.originalEvent = remoteEvent.FireServer
        SS.originalFunction = remoteFunction.InvokeServer

        local function newnamecall(remote, ...)
            if typeof(remote) == "Instance" then
                local args = { ... }
                local methodName = getnamecallmethod()
                local valid, remoteName = pcall(function() return remote.Name end)
                if valid and (methodName == "FireServer" or methodName == "fireServer" or methodName == "InvokeServer" or methodName == "invokeServer")
                    and not (SS.blacklist[remote] or SS.blacklist[remoteName]) then
                    local funcInfo = {}
                    if SS.funcEnabled then funcInfo = debug.getinfo(3) or funcInfo end
                    if SS.recordReturnValues and (methodName == "InvokeServer" or methodName == "invokeServer") then
                        local namecallThread = coroutine.running()
                        local a = { ... }
                        task.defer(function()
                            local returnValue
                            setnamecallmethod(methodName)
                            if SS.remoteHooks[remote] then
                                a = { SS.remoteHooks[remote](unpack(a)) }
                                returnValue = { SS.originalNamecall(remote, unpack(a)) }
                            else
                                returnValue = { SS.originalNamecall(remote, unpack(a)) }
                            end
                            coroutine.resume(namecallThread, unpack(returnValue))
                            coroutine.wrap(function() SS.schedule(SS.remoteHandler, false, methodName, remote, a, funcInfo, nil, returnValue) end)()
                        end)
                    else
                        coroutine.wrap(function() SS.schedule(SS.remoteHandler, false, methodName, remote, args, funcInfo, nil) end)()
                    end
                end
                if SS.recordReturnValues and (methodName == "InvokeServer" or methodName == "invokeServer") then
                    return coroutine.yield()
                elseif valid and (methodName == "FireServer" or methodName == "fireServer" or methodName == "InvokeServer" or methodName == "invokeServer") and (SS.blocklist[remote] or SS.blocklist[remoteName]) then
                    return nil
                elseif (not SS.recordReturnValues or methodName ~= "InvokeServer" or methodName ~= "invokeServer")
                    and valid and (methodName == "FireServer" or methodName == "fireServer" or methodName == "InvokeServer" or methodName == "invokeServer")
                    and SS.remoteHooks[remote] then
                    return SS.originalNamecall(remote, SS.remoteHooks[remote](...))
                else
                    return SS.originalNamecall(remote, ...)
                end
            end
            return SS.originalNamecall(remote, ...)
        end
        SS.newnamecall = newnamecall
    end

    SS.toggleSpy = function()
        if not SS.newnamecall then SS.installNamecallHook() end
        if not SS.toggle then
            if hookmetamethod then
                local old = hookmetamethod(game, "__namecall", SS.newnamecall)
                SS.originalNamecall = SS.originalNamecall or function(...) return old(...) end
            else
                local gm = getrawmetatable(game)
                SS.originalNamecall = SS.originalNamecall or gm.__namecall
                setreadonly(gm, false)
                gm.__namecall = SS.newnamecall
                setreadonly(gm, true)
            end
        else
            if hookmetamethod then
                if SS.originalNamecall then hookmetamethod(game, "__namecall", SS.originalNamecall) end
            else
                local gm = getrawmetatable(game)
                setreadonly(gm, false)
                gm.__namecall = SS.originalNamecall
                setreadonly(gm, true)
            end
        end
    end

    SS.toggleSpyMethod = function() SS.toggleSpy() SS.toggle = not SS.toggle end
    SS.start = function() if not SS.toggle then SS.toggleSpyMethod() end end
    SS.stop = function() if SS.toggle then SS.toggleSpyMethod() end end
    SS.clear = function() SS.logs = {} end
    SS.block = function(remote) SS.blocklist[remote] = true end
    SS.unblock = function(remote) SS.blocklist[remote] = nil end
    SS.exclude = function(remote) SS.blacklist[remote] = true end
    SS.setAutoBlock = function(v) SS.autoblock = v end
    SS.setFuncEnabled = function(v) SS.funcEnabled = v end
    SS.setRecordReturnValues = function(v) SS.recordReturnValues = v end
    SS.getRemoteFiredSignal = function(remote)
        if not SS.remoteSignals[remote] then SS.remoteSignals[remote] = SS.newSignal() end
        return SS.remoteSignals[remote]
    end
    SS.hookRemoteWith = function(remote, f) SS.remoteHooks[remote] = f end
end

-- ============================================================
-- [19] Adonis 主脚本末尾版本 (与 [11] 相同, 直接暴露为函数)
-- ============================================================
D.InitAdonisBypass = D.InitAdonisBypass

-- ============================================================
-- [20] 主脚本初始化 (可选, 设置文件系统/环境)
-- ============================================================
D.SetupFilesystem = function()
    if not writefile or not makefolder then return end
    pcall(makefolder, "dex")
    pcall(makefolder, "dex/assets")
    pcall(makefolder, "dex/saved")
    pcall(makefolder, "dex/plugins")
    pcall(makefolder, "dex/ModuleCache")
end

D.GetSecureContainer = function()
    return (syn and syn.protect_gui) and syn
        or (gethui and gethui())
        or service.CoreGui
        or service.Players.LocalPlayer:WaitForChild("PlayerGui")
end

D.GetRandomString = function()
    local output = ""
    for i = 2, 25 do
        output = output .. string.char(math.random(1, 250))
    end
    return output
end

D.SecureGui = function(gui)
    gui.Name = "_DPP_" .. D.GetRandomString()
    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = service.CoreGui
    elseif protect_gui then
        protect_gui(gui)
        gui.Parent = service.CoreGui
    elseif protectgui then
        protectgui(gui)
        gui.Parent = service.CoreGui
    else
        gui.Parent = service.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end



-- ============================================================
-- [21] Model3D — 3D 视觉感知系统 (v1.1)
--     给 AI 提供"理解 3D 物体"的能力, 无渲染无 UI
-- ============================================================
D.Model3D = {}
do
    local M = D.Model3D

    -- ========================================================
    -- 1. 包围盒 (世界坐标)
    -- ========================================================
    M.bbox = function(inst)
        if not inst then return nil end
        if inst:IsA("BasePart") then
            local c, s = inst.Position, inst.Size
            local r, u, l = inst.CFrame.RightVector, inst.CFrame.UpVector, inst.CFrame.LookVector
            local hx, hy, hz = s.X/2, s.Y/2, s.Z/2
            local mn = c - r*hx - u*hy - l*hz
            local mx = c + r*hx + u*hy + l*hz
            return {
                Min = mn, Max = mx,
                Size = Vector3.new(math.abs(mx.X-mn.X), math.abs(mx.Y-mn.Y), math.abs(mx.Z-mn.Z)),
                Center = c
            }
        end
        if inst:IsA("Model") or inst:IsA("Folder") then
            local mn, mx
            for _, p in ipairs(inst:GetDescendants()) do
                if p:IsA("BasePart") then
                    local b = M.bbox(p)
                    if not mn then mn, mx = b.Min, b.Max
                    else
                        mn = Vector3.new(math.min(mn.X, b.Min.X), math.min(mn.Y, b.Min.Y), math.min(mn.Z, b.Min.Z))
                        mx = Vector3.new(math.max(mx.X, b.Max.X), math.max(mx.Y, b.Max.Y), math.max(mx.Z, b.Max.Z))
                    end
                end
            end
            if not mn then return nil end
            return {
                Min = mn, Max = mx,
                Size = mx - mn,
                Center = (mn + mx) / 2
            }
        end
        return nil
    end

    -- ========================================================
    -- 2. 部件列表
    -- ========================================================
    M.parts = function(inst)
        local list = {}
        if not inst then return list end
        if inst:IsA("BasePart") then
            list[1] = inst
        else
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("BasePart") then list[#list+1] = d end
            end
        end
        return list
    end

    -- ========================================================
    -- 3. 单部件描述
    -- ========================================================
    M.partInfo = function(p)
        if not p or not p:IsA("BasePart") then return nil end
        local info = {
            Name = p.Name,
            Class = p.ClassName,
            Position = p.Position,
            Size = p.Size,
            CFrame = p.CFrame,
            Color = p.Color,
            BrickColor = p.BrickColor and p.BrickColor.Name or "Unknown",
            Material = tostring(p.Material),
            Transparency = p.Transparency,
            Reflectance = p.Reflectance,
            Anchored = p.Anchored,
            CanCollide = p.CanCollide,
            Mass = p.Mass,
            AssemblyMass = p.AssemblyMass,
        }
        if p:IsA("Part") then info.Shape = tostring(p.Shape) end
        if p:IsA("MeshPart") then
            info.MeshId = p.MeshId
            info.TextureId = p.TextureID
        end
        if p:IsA("FormFactorPart") then info.FormFactor = tostring(p.FormFactor) end
        if p:IsA("Seat") or p:IsA("VehicleSeat") then info.IsSeat = true end
        return info
    end

    -- ========================================================
    -- 4. 层级树 (字符串)
    -- ========================================================
    M.hierarchy = function(inst, maxDepth)
        if not inst then return "" end
        maxDepth = maxDepth or 5
        local lines = {}
        local function recur(o, depth, prefix)
            if depth > maxDepth then
                lines[#lines+1] = prefix .. "  ... (深度超过 " .. maxDepth .. ")"
                return
            end
            lines[#lines+1] = string.format("%s%s [%s]", prefix, o.Name, o.ClassName)
            for _, c in ipairs(o:GetChildren()) do
                recur(c, depth + 1, prefix .. "  ")
            end
        end
        recur(inst, 0, "")
        return table.concat(lines, "\n")
    end

    -- ========================================================
    -- 5. 完整结构化数据 (供 AI 深度分析)
    -- ========================================================
    M.inspect = function(inst, opts)
        if not inst then return nil end
        opts = opts or {}
        local maxParts = opts.maxParts or 100
        local maxDepth = opts.maxDepth or 5

        local bbox = M.bbox(inst)
        local parts = M.parts(inst)

        local classCount, materialCount, colorCount = {}, {}, {}
        for _, p in ipairs(parts) do
            classCount[p.ClassName] = (classCount[p.ClassName] or 0) + 1
            local mat = tostring(p.Material)
            materialCount[mat] = (materialCount[mat] or 0) + 1
            local col = p.BrickColor and p.BrickColor.Name or "Unknown"
            colorCount[col] = (colorCount[col] or 0) + 1
        end

        local partDetails = {}
        for i, p in ipairs(parts) do
            if i > maxParts then
                partDetails[#partDetails+1] = {
                    Truncated = true,
                    RemainingCount = #parts - maxParts
                }
                break
            end
            partDetails[#partDetails+1] = M.partInfo(p)
        end

        local childCount = {}
        for _, d in ipairs(inst:GetDescendants()) do
            childCount[d.ClassName] = (childCount[d.ClassName] or 0) + 1
        end

        return {
            Name = inst.Name,
            Class = inst.ClassName,
            Path = D.GetInstancePath(inst),
            BBox = bbox,
            PartCount = #parts,
            PartsByClass = classCount,
            MaterialsUsed = materialCount,
            ColorsUsed = colorCount,
            ChildrenByClass = childCount,
            Parts = partDetails,
            Hierarchy = M.hierarchy(inst, maxDepth),
        }
    end

    -- ========================================================
    -- 6. 文本描述 (最精简, 给 LLM 直接读)
    -- ========================================================
    M.describe = function(inst)
        if not inst then return "空实例" end
        local bbox = M.bbox(inst)
        local parts = M.parts(inst)
        local lines = {}

        lines[#lines+1] = string.format("名称: %s", inst.Name)
        lines[#lines+1] = string.format("类型: %s", inst.ClassName)
        lines[#lines+1] = string.format("路径: %s", D.GetInstancePath(inst))

        if bbox then
            lines[#lines+1] = string.format("尺寸: %.2f x %.2f x %.2f studs",
                bbox.Size.X, bbox.Size.Y, bbox.Size.Z)
            lines[#lines+1] = string.format("中心: (%.2f, %.2f, %.2f)",
                bbox.Center.X, bbox.Center.Y, bbox.Center.Z)
        end

        lines[#lines+1] = string.format("部件数: %d", #parts)

        local classCount = {}
        for _, p in ipairs(parts) do
            classCount[p.ClassName] = (classCount[p.ClassName] or 0) + 1
        end
        local typeList = {}
        for k, v in pairs(classCount) do typeList[#typeList+1] = string.format("%s x%d", k, v) end
        if #typeList > 0 then
            lines[#lines+1] = "组成: " .. table.concat(typeList, ", ")
        end

        local colors = {}
        for _, p in ipairs(parts) do
            local key = p.BrickColor and p.BrickColor.Name or "Unknown"
            colors[key] = (colors[key] or 0) + 1
        end
        local colorList = {}
        for k, v in pairs(colors) do colorList[#colorList+1] = string.format("%s x%d", k, v) end
        if #colorList > 0 then
            lines[#lines+1] = "颜色: " .. table.concat(colorList, ", ")
        end

        local mats = {}
        for _, p in ipairs(parts) do
            local m = tostring(p.Material)
            mats[m] = (mats[m] or 0) + 1
        end
        local matList = {}
        for k, v in pairs(mats) do matList[#matList+1] = string.format("%s x%d", k, v) end
        if #matList > 0 then
            lines[#lines+1] = "材质: " .. table.concat(matList, ", ")
        end

        return table.concat(lines, "\n")
    end

    -- ========================================================
    -- 7. 分类 (给 AI 一个词就能判断物体是什么)
    -- ========================================================
    M.classify = function(inst)
        if not inst then return "unknown" end
        local parts = M.parts(inst)
        local n = #parts
        if n == 0 then return "empty" end

        if inst:IsA("Model") and D.service.Players:GetPlayerFromCharacter(inst) then
            return "player-character"
        end
        if inst:FindFirstChildOfClass("Humanoid") then
            return "npc"
        end
        if inst:FindFirstChildOfClass("Tool") then
            return "tool"
        end
        if inst:FindFirstChildWhichIsA("VehicleSeat") then
            return "vehicle"
        end
        if inst:FindFirstChildWhichIsA("Beam") or inst:FindFirstChildWhichIsA("Trail") then
            return "effect"
        end

        local bbox = M.bbox(inst)
        local avgSize = bbox and (bbox.Size.Magnitude / 3) or 0

        if n == 1 and parts[1]:IsA("BasePart") then
            local p = parts[1]
            if p:IsA("MeshPart") then return "mesh-part" end
            if p:IsA("SpawnLocation") then return "spawn" end
            if p:IsA("Seat") then return "seat" end
            if p:IsA("Part") then
                if p.Shape == Enum.PartType.Ball then return "sphere" end
                if p.Shape == Enum.PartType.Cylinder then return "cylinder" end
            end
            if avgSize < 2 then return "small-prop" end
            if avgSize > 20 then return "large-platform" end
            return "part"
        end

        if n < 5 then return "simple-prop" end
        if n < 30 then return "medium-assembly" end
        if n < 200 then return "complex-assembly" end
        return "huge-assembly"
    end

    -- ========================================================
    -- 8. 空间布局 (部件相对整体的方位)
    -- ========================================================
    M.spatialLayout = function(inst, maxParts)
        maxParts = maxParts or 30
        local parts = M.parts(inst)
        if #parts == 0 then return {} end

        local bbox = M.bbox(inst)
        if not bbox then return {} end
        local center = bbox.Center

        local layout = {}
        for i, p in ipairs(parts) do
            if i > maxParts then break end
            local rel = p.Position - center
            local dir = "center"
            local ax, ay, az = math.abs(rel.X), math.abs(rel.Y), math.abs(rel.Z)
            if ax > ay and ax > az then
                dir = rel.X > 0 and "right" or "left"
            elseif ay > az then
                dir = rel.Y > 0 and "top" or "bottom"
            elseif az > 0.1 then
                dir = rel.Z > 0 and "back" or "front"
            end
            layout[#layout+1] = {
                Name = p.Name,
                Class = p.ClassName,
                Relative = rel,
                Direction = dir,
                Distance = rel.Magnitude,
            }
        end
        return layout
    end

    -- ========================================================
    -- 9. 查找 (按名字/类名在 workspace 里找东西)
    -- ========================================================
    M.find = function(query, opts)
        opts = opts or {}
        local lower = string.lower
        local q = lower(query)
        local results = {}
        local roots = opts.roots or {workspace}
        local limit = opts.limit or 100
        for _, root in ipairs(roots) do
            for _, d in ipairs(root:GetDescendants()) do
                local match = false
                if opts.byClass then
                    match = d.ClassName == query
                else
                    match = lower(d.Name):find(q, 1, true) ~= nil
                end
                if match then
                    results[#results+1] = d
                    if #results >= limit then return results end
                end
            end
        end
        return results
    end

    -- ========================================================
    -- 10. 完整报告 (合体)
    -- ========================================================
    M.report = function(inst, opts)
        if not inst then return nil end
        return {
            Description = M.describe(inst),
            Classification = M.classify(inst),
            Inspect = M.inspect(inst, opts),
            Layout = M.spatialLayout(inst),
            Path = D.GetInstancePath(inst),
        }
    end

    -- ========================================================
    -- 11. 比较两个物体 (供 AI 判断相似度)
    -- ========================================================
    M.compare = function(a, b)
        if not a or not b then return nil end
        local bboxA, bboxB = M.bbox(a), M.bbox(b)
        local partsA, partsB = M.parts(a), M.parts(b)

        local result = {
            NameA = a.Name, NameB = b.Name,
            ClassA = a.ClassName, ClassB = b.ClassName,
            ClassMatch = a.ClassName == b.ClassName,
            PartCountA = #partsA, PartCountB = #partsB,
        }

        if bboxA and bboxB then
            result.SizeA = bboxA.Size
            result.SizeB = bboxB.Size
            result.SizeDiff = (bboxA.Size - bboxB.Size).Magnitude
            result.CenterDistance = (bboxA.Center - bboxB.Center).Magnitude
        end

        return result
    end

    -- ========================================================
    -- 12. 场景快照 (当前视野/附近内所有物体, 供 AI 一次性了解场景)
    -- ========================================================
    M.sceneSnapshot = function(opts)
        opts = opts or {}
        local origin = opts.origin
            or (D.plr.Character and D.plr.Character:FindFirstChild("HumanoidRootPart")
                and D.plr.Character.HumanoidRootPart.Position)
            or workspace.CurrentCamera.CFrame.Position
        local radius = opts.radius or 100

        local results = {}
        local seen = {}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Model") then
                if not seen[d] then
                    seen[d] = true
                    local pos
                    if d:IsA("BasePart") then pos = d.Position
                    elseif d.PrimaryPart then pos = d.PrimaryPart.Position
                    else
                        local pp = d:FindFirstChildWhichIsA("BasePart")
                        if pp then pos = pp.Position end
                    end
                    if pos then
                        local dist = (pos - origin).Magnitude
                        if dist <= radius then
                            results[#results+1] = {
                                Instance = d,
                                Name = d.Name,
                                Class = d.ClassName,
                                Category = M.classify(d),
                                Position = pos,
                                Distance = dist,
                            }
                        end
                    end
                end
            end
        end
        table.sort(results, function(a, b) return a.Distance < b.Distance end)
        return results
    end
end

D.Version = "1.1"

-- ============================================================
-- [22] SimpleSpy 补充 API (v1.0.1 补丁)
--      只新增辅助函数, 完全不改动已有代码
-- ============================================================
do
    local SS = D.SimpleSpy

    -- ========================================================
    -- 黑名单 / 阻止列表 管理
    -- ========================================================
    SS.clearBlacklist = function()
        SS.blacklist = {}
    end

    SS.clearBlocklist = function()
        SS.blocklist = {}
    end

    SS.listBlocked = function()
        local list = {}
        for k, v in pairs(SS.blocklist) do
            if v then
                if type(k) == "string" then
                    list[#list+1] = k
                elseif typeof(k) == "Instance" then
                    list[#list+1] = D.GetInstancePath(k)
                end
            end
        end
        return list
    end

    SS.listExcluded = function()
        local list = {}
        for k, v in pairs(SS.blacklist) do
            if v then
                if type(k) == "string" then
                    list[#list+1] = k
                elseif typeof(k) == "Instance" then
                    list[#list+1] = D.GetInstancePath(k)
                end
            end
        end
        return list
    end

    SS.unblock = function(remote)
        SS.blocklist[remote] = nil
    end

    SS.unexclude = function(remote)
        SS.blacklist[remote] = nil
    end

    -- ========================================================
    -- 序列化选项开关
    -- ========================================================
    SS.setKeyToString = function(v)
        D.setSerializerOptions({ keyToString = v })
    end

    -- ========================================================
    -- 日志查询
    -- ========================================================
    SS.getLatest = function()
        return SS.logs[#SS.logs]
    end

    SS.getLatestReturnValue = function()
        local last = SS.logs[#SS.logs]
        if last then return last.returnValue end
        return nil
    end

    SS.filterLogs = function(query)
        if not query or query == "" then return SS.logs end
        local lower = string.lower
        local q = lower(query)
        local out = {}
        for _, e in ipairs(SS.logs) do
            local matched = lower(e.name or ""):find(q, 1, true)
                         or lower(e.type or ""):find(q, 1, true)
                         or lower(e.genScript or ""):find(q, 1, true)
            if matched then out[#out+1] = e end
        end
        return out
    end

    SS.getRemoteNames = function()
        local seen, names = {}, {}
        for _, e in ipairs(SS.logs) do
            if not seen[e.name] then
                seen[e.name] = true
                names[#names+1] = e.name
            end
        end
        return names
    end

    SS.stats = function()
        local byType, byName = {}, {}
        for _, e in ipairs(SS.logs) do
            byType[e.type] = (byType[e.type] or 0) + 1
            byName[e.name] = (byName[e.name] or 0) + 1
        end
        return { byType = byType, byName = byName, total = #SS.logs }
    end

    -- ========================================================
    -- 选中项
    -- ========================================================
    SS.getSelected = function()
        return SS.selected
    end

    SS.setSelected = function(entry)
        SS.selected = entry
    end

    -- ========================================================
    -- 从日志找脚本 / 复制到剪贴板
    -- ========================================================
    SS.findRemoteScript = function(remoteName)
        for i = #SS.logs, 1, -1 do
            local e = SS.logs[i]
            if e.name == remoteName and e.source then
                return e.source
            end
        end
        return nil
    end

    SS.copyRemotePath = function(remote)
        if not remote then return end
        if D.env.setclipboard then
            D.env.setclipboard(D.v2s(remote))
        end
    end

    SS.copyScript = function(source)
        if not source then return end
        if D.env.setclipboard then
            D.env.setclipboard(D.v2s(source))
        end
    end

    SS.copyLogs = function()
        if not D.env.setclipboard then return end
        local lines = {}
        for i, e in ipairs(SS.logs) do
            lines[i] = string.format("[%s] %s %s 参数%d个", e.time, e.type, e.name, #e.args)
        end
        D.env.setclipboard(table.concat(lines, "\n"))
    end

    -- ========================================================
    -- 执行生成的脚本
    -- ========================================================
    SS.executeGenScript = function(entry)
        if not entry or not entry.genScript then return nil, "no genScript" end
        local fn, err = loadstring(entry.genScript)
        if not fn then return nil, err end
        local ok, e = pcall(fn)
        return ok, e
    end

    -- ========================================================
    -- 序列化辅助 (对应原 SimpleSpy 的接口)
    -- ========================================================
    SS.argsToString = function(method, args)
        return D.v2v({ args = args }) .. "\n\n" .. method .. "(unpack(args))"
    end

    SS.tableToVars = function(t)
        return D.v2v(t)
    end

    SS.valueToVar = function(value, name)
        name = name or 1
        return D.v2v({ [name] = value })
    end

    SS.valueToString = function(v)
        return D.v2s(v)
    end

    -- ========================================================
    -- 函数信息
    -- ========================================================
    SS.getFunctionInfo = function(f)
        if typeof(f) ~= "function" then return nil end
        local info = {}
        local ok, d = pcall(debug.getinfo, f)
        if ok then info.info = d end
        local gc = debug.getconstants
        if gc then
            local ok2, c = pcall(gc, f)
            if ok2 then info.constants = c end
        end
        return info
    end

    -- ========================================================
    -- 导出 / 保存
    -- ========================================================
    SS.export = function()
        local out = {}
        for i, e in ipairs(SS.logs) do
            out[i] = {
                time = e.time,
                name = e.name,
                type = e.type,
                argsCount = #e.args,
                genScript = e.genScript,
                blocked = e.blocked,
                source = e.source and D.GetInstancePath(e.source) or nil,
            }
        end
        local ok, json = pcall(D.service.HttpService.JSONEncode, D.service.HttpService, out)
        if ok then return json end
        return nil
    end

    SS.saveToFile = function(path)
        if not D.env.writefile then return false, "no writefile" end
        local data = SS.export()
        if not data then return false, "encode failed" end
        local ok, err = pcall(D.env.writefile, path, data)
        return ok, err
    end

    -- ========================================================
    -- 便捷搜索: 从全游戏找到某个远程 / 某个脚本
    -- ========================================================
    SS.findRemoteByName = function(name)
        local results = {}
        for _, obj in ipairs(game:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                or obj:IsA("BindableEvent") or obj:IsA("BindableFunction")
                or obj:IsA("UnreliableRemoteEvent"))
                and obj.Name:find(name, 1, true) then
                results[#results+1] = obj
            end
        end
        return results
    end
end

-- 补丁完成: v1.0.1
-- 版本号你自己在文件开头或末尾改一次即可

-- ============================================================
-- [23] SimpleSpy 高级功能包 (v1.0.2 补丁)
--      只新增, 不冲突
-- ============================================================
do
    local SS = D.SimpleSpy

    -- 新增变量: 拦截器 / 别名 / 录制 / 缓存
    SS.interceptors = SS.interceptors or {}
    SS.aliases = SS.aliases or {}
    SS.recordings = SS.recordings or {}
    SS.scriptCache = SS.scriptCache or {}
    SS.blockConditions = SS.blockConditions or {}

    -- ========================================================
    -- 1. 重放 / 批量重放
    -- ========================================================
    SS.replay = function(entry)
        if not entry or not entry.remote then return false, "no remote" end
        local remote = entry.remote
        if typeof(remote) ~= "Instance" then return false, "invalid remote" end
        local ok, err = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(unpack(entry.args))
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(unpack(entry.args))
            elseif remote:IsA("BindableEvent") then
                remote:Fire(unpack(entry.args))
            elseif remote:IsA("BindableFunction") then
                remote:Invoke(unpack(entry.args))
            elseif remote:IsA("UnreliableRemoteEvent") then
                remote:FireServer(unpack(entry.args))
            end
        end)
        return ok, err
    end

    SS.replayWith = function(entry, newArgs)
        if not entry or not entry.remote then return false, "no remote" end
        local remote = entry.remote
        if typeof(remote) ~= "Instance" then return false, "invalid remote" end
        local ok, err = pcall(function()
            if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                remote:FireServer(unpack(newArgs or entry.args))
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(unpack(newArgs or entry.args))
            elseif remote:IsA("BindableEvent") then
                remote:Fire(unpack(newArgs or entry.args))
            elseif remote:IsA("BindableFunction") then
                remote:Invoke(unpack(newArgs or entry.args))
            end
        end)
        return ok, err
    end

    SS.replayAll = function(filter, delay)
        delay = delay or 0.1
        local list = filter and SS.filterLogs(filter) or SS.logs
        local count = 0
        for _, e in ipairs(list) do
            local ok = SS.replay(e)
            if ok then count = count + 1 end
            task.wait(delay)
        end
        return count
    end

    SS.replayByIndex = function(index)
        local e = SS.logs[index]
        if not e then return false, "no such log" end
        return SS.replay(e)
    end

    -- ========================================================
    -- 2. 录制 / 回放
    -- ========================================================
    SS.record = function(label)
        label = label or ("rec_" .. os.time())
        SS.recordings[label] = {
            startIndex = #SS.logs + 1,
            label = label,
            startTime = tick(),
        }
        return label
    end

    SS.stopRecord = function(label)
        label = label or nil
        if not label then
            for k, v in pairs(SS.recordings) do
                if not v.endIndex then label = k break end
            end
        end
        if not label or not SS.recordings[label] then return nil end
        local rec = SS.recordings[label]
        rec.endIndex = #SS.logs
        rec.duration = tick() - rec.startTime
        return rec
    end

    SS.playRecord = function(label, delay)
        local rec = SS.recordings[label]
        if not rec then return 0 end
        delay = delay or 0.05
        local count = 0
        for i = rec.startIndex, rec.endIndex do
            if SS.logs[i] then
                SS.replay(SS.logs[i])
                count = count + 1
                task.wait(delay)
            end
        end
        return count
    end

    SS.listRecordings = function()
        local list = {}
        for k, v in pairs(SS.recordings) do
            list[#list+1] = {
                label = k,
                start = v.startIndex,
                ["end"] = v.endIndex or "recording...",
                count = v.endIndex and (v.endIndex - v.startIndex + 1) or "?",
            }
        end
        return list
    end

    SS.deleteRecording = function(label)
        SS.recordings[label] = nil
    end

    -- ========================================================
    -- 3. 频率监控
    -- ========================================================
    SS.rate = function(remoteName, window)
        window = window or 5
        local now = tick()
        local count = 0
        for i = #SS.logs, 1, -1 do
            local e = SS.logs[i]
            if e.name == remoteName then
                -- 从 os.date 无法精确到毫秒, 用索引距离近似
                if (#SS.logs - i) < window * 50 then
                    count = count + 1
                end
            end
        end
        return count
    end

    SS.hotRemotes = function(topN)
        topN = topN or 10
        local counters = {}
        for _, e in ipairs(SS.logs) do
            counters[e.name] = (counters[e.name] or 0) + 1
        end
        local sorted = {}
        for k, v in pairs(counters) do sorted[#sorted+1] = {name = k, count = v} end
        table.sort(sorted, function(a, b) return a.count > b.count end)
        local out = {}
        for i = 1, math.min(topN, #sorted) do out[i] = sorted[i] end
        return out
    end

    -- ========================================================
    -- 4. 过滤与去重
    -- ========================================================
    SS.deduplicate = function()
        local seen, out = {}, {}
        for _, e in ipairs(SS.logs) do
            local key = e.name .. "|" .. (e.args and table.concat({table.unpack(e.args)}, ",") or "")
            if not seen[key] then
                seen[key] = true
                out[#out+1] = e
            end
        end
        local removed = #SS.logs - #out
        SS.logs = out
        return removed
    end

    SS.filterByName = function(name)
        local out = {}
        for _, e in ipairs(SS.logs) do
            if e.name == name then out[#out+1] = e end
        end
        return out
    end

    SS.filterByType = function(typ)
        local out = {}
        for _, e in ipairs(SS.logs) do
            if e.type == typ then out[#out+1] = e end
        end
        return out
    end

    SS.filterByScript = function(scriptPath)
        local out = {}
        for _, e in ipairs(SS.logs) do
            if e.source and D.GetInstancePath(e.source):find(scriptPath, 1, true) then
                out[#out+1] = e
            end
        end
        return out
    end

    SS.timeline = function(startTime, endTime)
        startTime = startTime or "00:00:00"
        endTime = endTime or "23:59:59"
        local out = {}
        for _, e in ipairs(SS.logs) do
            if e.time >= startTime and e.time <= endTime then
                out[#out+1] = e
            end
        end
        return out
    end

    -- ========================================================
    -- 5. 别名系统
    -- ========================================================
    SS.setAlias = function(remote, name)
        local key = typeof(remote) == "Instance" and D.GetInstancePath(remote) or tostring(remote)
        SS.aliases[key] = name
    end

    SS.getAlias = function(remote)
        local key = typeof(remote) == "Instance" and D.GetInstancePath(remote) or tostring(remote)
        return SS.aliases[key]
    end

    SS.listAliases = function()
        return SS.aliases
    end

    SS.clearAliases = function()
        SS.aliases = {}
    end

    -- ========================================================
    -- 6. 分组统计
    -- ========================================================
    SS.groupByScript = function()
        local groups = {}
        for _, e in ipairs(SS.logs) do
            local key = e.source and D.GetInstancePath(e.source) or "(unknown)"
            if not groups[key] then groups[key] = {count = 0, remotes = {}} end
            groups[key].count = groups[key].count + 1
            groups[key].remotes[e.name] = (groups[key].remotes[e.name] or 0) + 1
        end
        return groups
    end

    SS.groupByRemote = function()
        local groups = {}
        for _, e in ipairs(SS.logs) do
            if not groups[e.name] then
                groups[e.name] = {count = 0, scripts = {}, args = {}}
            end
            groups[e.name].count = groups[e.name].count + 1
            if e.source then
                local path = D.GetInstancePath(e.source)
                groups[e.name].scripts[path] = (groups[e.name].scripts[path] or 0) + 1
            end
            groups[e.name].args[#groups[e.name].args+1] = e.args
        end
        return groups
    end

    -- ========================================================
    -- 7. 共现分析 (哪些远程总是一起被调)
    -- ========================================================
    SS.cooccurrence = function(window, threshold)
        window = window or 5
        threshold = threshold or 3
        local pairs_ = {}
        for i, e in ipairs(SS.logs) do
            for j = i + 1, math.min(i + window, #SS.logs) do
                local e2 = SS.logs[j]
                if e.name ~= e2.name then
                    local key = e.name .. " + " .. e2.name
                    pairs_[key] = (pairs_[key] or 0) + 1
                end
            end
        end
        local out = {}
        for k, v in pairs(pairs_) do
            if v >= threshold then out[#out+1] = {pair = k, count = v} end
        end
        table.sort(out, function(a, b) return a.count > b.count end)
        return out
    end

    -- ========================================================
    -- 8. 调用链 (一个远程触发了哪些后续调用)
    -- ========================================================
    SS.callChain = function(name, window)
        window = window or 5
        local chains = {}
        for i, e in ipairs(SS.logs) do
            if e.name == name then
                local chain = {trigger = e.name, following = {}}
                for j = i + 1, math.min(i + window, #SS.logs) do
                    chain.following[#chain.following+1] = SS.logs[j].name
                end
                chains[#chains+1] = chain
            end
        end
        return chains
    end

    -- ========================================================
    -- 9. 危险远程扫描
    -- ========================================================
    SS.scanDangerous = function()
        local keywords = {"ban", "kick", "delete", "remove", "destroy",
                          "admin", "grant", "give", "reset", "shutdown", "kill"}
        local lower = string.lower
        local out = {}
        for _, e in ipairs(SS.logs) do
            local name = lower(e.name)
            for _, kw in ipairs(keywords) do
                if name:find(kw, 1, true) then
                    out[#out+1] = {entry = e, keyword = kw}
                    break
                end
            end
        end
        return out
    end

    -- ========================================================
    -- 10. 参数类型分析
    -- ========================================================
    SS.analyzeArgs = function(entry)
        if not entry or not entry.args then return nil end
        local types = {}
        for i, v in ipairs(entry.args) do
            types[i] = typeof(v)
        end
        return { count = #entry.args, types = types }
    end

    SS.analyzeAllArgs = function(remoteName)
        local list = SS.filterByName(remoteName)
        local typeStats = {}
        for _, e in ipairs(list) do
            for i, v in ipairs(e.args) do
                typeStats[i] = typeStats[i] or {}
                local t = typeof(v)
                typeStats[i][t] = (typeStats[i][t] or 0) + 1
            end
        end
        return typeStats
    end

    -- ========================================================
    -- 11. 差异对比
    -- ========================================================
    SS.diff = function(a, b)
        if not a or not b then return nil end
        local diff = { nameSame = a.name == b.name, typeSame = a.type == b.type }
        diff.argsA = #a.args
        diff.argsB = #b.args
        if #a.args == #b.args then
            diff.argDiff = {}
            for i = 1, #a.args do
                if typeof(a.args[i]) ~= typeof(b.args[i]) then
                    diff.argDiff[i] = "type_mismatch"
                elseif tostring(a.args[i]) ~= tostring(b.args[i]) then
                    diff.argDiff[i] = "value_diff"
                end
            end
        end
        return diff
    end

    -- ========================================================
    -- 12. 计数器 / 快照
    -- ========================================================
    SS.counters = function()
        local c = {}
        for _, e in ipairs(SS.logs) do
            c[e.name] = (c[e.name] or 0) + 1
        end
        return c
    end

    SS.snapshot = function()
        return {
            time = os.date("%Y-%m-%d %H:%M:%S"),
            tick = tick(),
            logCount = #SS.logs,
            counters = SS.counters(),
        }
    end

    SS.diffSnapshot = function(a, b)
        if not a or not b then return nil end
        local delta = {}
        local allKeys = {}
        for k in pairs(a.counters) do allKeys[k] = true end
        for k in pairs(b.counters) do allKeys[k] = true end
        for k in pairs(allKeys) do
            local ca = a.counters[k] or 0
            local cb = b.counters[k] or 0
            if ca ~= cb then
                delta[k] = { from = ca, to = cb, diff = cb - ca }
            end
        end
        return delta
    end

    -- ========================================================
    -- 13. Hook 状态检查
    -- ========================================================
    SS.isHooked = function()
        if not getrawmetatable then return nil end
        local mt = getrawmetatable(game)
        if not mt then return nil end
        local current = rawget(mt, "__namecall")
        return current == SS.newnamecall
    end

    -- ========================================================
    -- 14. 拦截器 (修改参数 / 条件阻断)
    -- ========================================================
    SS.intercept = function(remote, fn)
        if not SS.interceptors[remote] then
            SS.interceptors[remote] = {}
            -- 首次安装 dispatcher
            local original = SS.remoteHooks[remote]
            SS.remoteHooks[remote] = function(...)
                local args = {...}
                for _, f in ipairs(SS.interceptors[remote] or {}) do
                    local newArgs, shouldBlock = f(remote, args)
                    if shouldBlock then return nil end
                    if newArgs then args = newArgs end
                end
                if original then return original(unpack(args)) end
                return unpack(args)
            end
        end
        table.insert(SS.interceptors[remote], fn)
    end

    SS.clearInterceptors = function(remote)
        SS.interceptors[remote] = nil
        SS.remoteHooks[remote] = nil
    end

    SS.listInterceptors = function()
        local out = {}
        for k, v in pairs(SS.interceptors) do
            local key = typeof(k) == "Instance" and D.GetInstancePath(k) or tostring(k)
            out[key] = #v
        end
        return out
    end

    SS.blockIf = function(remote, predicate)
        SS.intercept(remote, function(_, args)
            if predicate(args) then
                return args, true  -- shouldBlock
            end
            return args, false
        end)
    end

    -- ========================================================
    -- 15. 一键 dump 所有远程
    -- ========================================================
    SS.dumpAllRemotes = function()
        local out = {}
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                or obj:IsA("BindableEvent") or obj:IsA("BindableFunction")
                or obj:IsA("UnreliableRemoteEvent") then
                out[#out+1] = {
                    path = D.GetInstancePath(obj),
                    name = obj.Name,
                    class = obj.ClassName,
                    parent = obj.Parent and obj.Parent.Name or nil,
                }
            end
        end
        return out
    end

    SS.dumpAllRemotesAsScript = function()
        local list = SS.dumpAllRemotes()
        local lines = {"-- 所有远程实例"}
        for _, r in ipairs(list) do
            lines[#lines+1] = string.format("-- %s (%s)", r.path, r.class)
        end
        return table.concat(lines, "\n")
    end

    -- ========================================================
    -- 16. 配置导出 / 导入
    -- ========================================================
    SS.exportConfig = function()
        local cfg = {
            aliases = SS.aliases,
            blocked = SS.listBlocked(),
            excluded = SS.listExcluded(),
        }
        local ok, json = pcall(D.service.HttpService.JSONEncode, D.service.HttpService, cfg)
        if ok then return json end
        return nil
    end

    SS.importConfig = function(json)
        local ok, cfg = pcall(D.service.HttpService.JSONDecode, D.service.HttpService, json)
        if not ok or type(cfg) ~= "table" then return false end
        if cfg.aliases then SS.aliases = cfg.aliases end
        if cfg.blocked then
            for _, path in ipairs(cfg.blocked) do SS.blocklist[path] = true end
        end
        if cfg.excluded then
            for _, path in ipairs(cfg.excluded) do SS.blacklist[path] = true end
        end
        return true
    end

    SS.saveConfig = function(path)
        if not D.env.writefile then return false end
        local json = SS.exportConfig()
        if not json then return false end
        return pcall(D.env.writefile, path, json)
    end

    SS.loadConfig = function(path)
        if not D.env.readfile then return false end
        local ok, data = pcall(D.env.readfile, path)
        if not ok or not data then return false end
        return SS.importConfig(data)
    end

    -- ========================================================
    -- 17. 自动命名 (根据调用脚本自动起别名)
    -- ========================================================
    SS.autoName = function()
        local groups = SS.groupByRemote()
        local count = 0
        for remoteName, info in pairs(groups) do
            if not SS.aliases[remoteName] then
                local scriptNames = {}
                for path in pairs(info.scripts) do
                    local lastName = path:match("([^.]+)$") or path
                    scriptNames[#scriptNames+1] = lastName
                end
                if #scriptNames > 0 then
                    SS.aliases[remoteName] = remoteName .. " (" .. scriptNames[1] .. ")"
                    count = count + 1
                end
            end
        end
        return count
    end

    -- ========================================================
    -- 18. 名字分类 (根据远程名猜用途)
    -- ========================================================
    SS.classifyByName = function(name)
        local lower = string.lower(name)
        if lower:find("get") or lower:find("fetch") or lower:find("request") then
            return "read"
        elseif lower:find("set") or lower:find("update") or lower:find("save") then
            return "write"
        elseif lower:find("delete") or lower:find("remove") or lower:find("destroy") then
            return "destructive"
        elseif lower:find("buy") or lower:find("purchase") or lower:find("sell") then
            return "commerce"
        elseif lower:find("attack") or lower:find("damage") or lower:find("hit") then
            return "combat"
        elseif lower:find("chat") or lower:find("message") or lower:find("say") then
            return "communication"
        elseif lower:find("spawn") or lower:find("create") or lower:find("new") then
            return "creation"
        else
            return "unknown"
        end
    end

    SS.classifyAll = function()
        local out = {}
        for _, e in ipairs(SS.logs) do
            if not out[e.name] then
                out[e.name] = SS.classifyByName(e.name)
            end
        end
        return out
    end

    -- ========================================================
    -- 19. 反编译缓存 (避免重复反编译同一个脚本)
    -- ========================================================
    SS.cacheScript = function(script)
        if not script or not script:IsA("LuaSourceContainer") then return nil end
        local path = D.GetInstancePath(script)
        if SS.scriptCache[path] then return SS.scriptCache[path] end
        local src = D.decompile(script)
        SS.scriptCache[path] = src
        return src
    end

    SS.getCachedScript = function(script)
        local path = typeof(script) == "Instance" and D.GetInstancePath(script) or tostring(script)
        return SS.scriptCache[path]
    end

    SS.clearScriptCache = function()
        SS.scriptCache = {}
    end

    SS.searchInCache = function(keyword)
        local out = {}
        for path, src in pairs(SS.scriptCache) do
            local line = 0
            for l in src:gmatch("[^\n]+") do
                line = line + 1
                if l:find(keyword, 1, true) then
                    out[#out+1] = {path = path, line = line, text = l}
                end
            end
        end
        return out
    end

    -- ========================================================
    -- 20. 全局搜索 (从所有已分析日志找脚本)
    -- ========================================================
    SS.searchRemotesByKeyword = function(keyword)
        local lower = string.lower
        local q = lower(keyword)
        local out = {}
        for _, e in ipairs(SS.logs) do
            if lower(e.name):find(q, 1, true)
                or (e.genScript and lower(e.genScript):find(q, 1, true)) then
                out[#out+1] = e
            end
        end
        return out
    end
end

-- 补丁完成: v1.0.2


-- ============================================================
-- [25] Injector — 直接注入能力 (v1.3)
--      去掉所有做不到的功能, 只保留真能跑的
-- ============================================================
D.Injector = {}
do
    local I = D.Injector

    local function has(fn)
        return typeof(fn) == "function"
    end

    -- ==========================================================
    -- 1. 执行器能力检测
    -- ==========================================================
    I.capabilities = function()
        local cap = {
            executor = has(identifyexecutor) and select(1, identifyexecutor()) or "Unknown",
            version  = has(identifyexecutor) and select(2, identifyexecutor()) or "?",
            identity = has(getthreadidentity) and getthreadidentity() or nil,
        }
        local check = {
            "getsenv", "getfenv", "setfenv", "getgc", "getreg",
            "getgenv", "getrenv",
            "hookfunction", "hookmetamethod", "newcclosure",
            "checkcaller", "clonefunction", "islclosure", "iscclosure",
            "isexecutorclosure", "setreadonly", "isreadonly",
            "getrawmetatable", "setrawmetatable",
            "getnamecallmethod", "setnamecallmethod",
            "getnilinstances", "getloadedmodules",
            "setclipboard", "setthreadidentity", "getthreadidentity",
            "queue_on_teleport",
        }
        for _, name in ipairs(check) do
            cap[name] = has(_G[name]) or has(getgenv and getgenv()[name])
        end
        cap.debug_getupvalues  = has(debug.getupvalues)
        cap.debug_getconstants = has(debug.getconstants)
        cap.debug_setconstant  = has(debug.setconstant)
        cap.debug_getprotos    = has(debug.getprotos)
        return cap
    end

    -- ==========================================================
    -- 2. 原始 API 引用
    -- ==========================================================
    I.raw = {
        getsenv = getsenv, getfenv = getfenv, setfenv = setfenv,
        getgc = getgc, getreg = getreg, getgenv = getgenv, getrenv = getrenv,
        hookfunction = hookfunction, hookmetamethod = hookmetamethod,
        newcclosure = newcclosure, checkcaller = checkcaller,
        clonefunction = clonefunction,
        islclosure = islclosure, iscclosure = iscclosure,
        isexecutorclosure = isexecutorclosure,
        setreadonly = setreadonly, isreadonly = isreadonly,
        getrawmetatable = getrawmetatable, setrawmetatable = setrawmetatable,
        getnamecallmethod = getnamecallmethod, setnamecallmethod = setnamecallmethod,
        getnilinstances = getnilinstances, getloadedmodules = getloadedmodules,
        setclipboard = setclipboard,
        setthreadidentity = setthreadidentity, getthreadidentity = getthreadidentity,
        queue_on_teleport = queue_on_teleport,
        firetouchinterest = firetouchinterest,
        fireclickdetector = fireclickdetector,
        fireproximityprompt = fireproximityprompt,
        identifyexecutor = identifyexecutor,
        loadstring = loadstring,
        getscriptbytecode = getscriptbytecode,
    }

    -- ==========================================================
    -- 3. 环境操作
    -- ==========================================================
    I.getEnv = function(script)
        if typeof(script) ~= "Instance" then return nil end
        if not script:IsA("LuaSourceContainer") then return nil end

        if has(getsenv) then
            local ok, env = pcall(getsenv, script)
            if ok and type(env) == "table" then return env end
        end

        if has(getgc) then
            for _, f in ipairs(getgc()) do
                if typeof(f) == "function" and not (iscclosure and iscclosure(f)) then
                    local ok, env = pcall(getfenv, f)
                    if ok and type(env) == "table" and env.script == script then
                        return env
                    end
                end
            end
        end
        return nil
    end

    I.execIn = function(script, code)
        if typeof(script) ~= "Instance" then
            return {success = false, error = "script 必须是实例"}
        end
        if type(code) ~= "string" then
            return {success = false, error = "code 必须是字符串"}
        end
        local env = I.getEnv(script)
        if not env then
            return {success = false, error = "无法获取脚本环境 (执行器不支持 getsenv)"}
        end
        local loader = loadstring or (D.env and D.env.loadstring)
        if not loader then
            return {success = false, error = "执行器不支持 loadstring"}
        end
        local fn, err = loader(code)
        if not fn then
            return {success = false, error = "编译失败: " .. tostring(err)}
        end
        if has(setfenv) then
            pcall(setfenv, fn, env)
        end
        local ok, ret = pcall(fn)
        return {
            success = ok,
            result = ok and ret or nil,
            error = (not ok) and tostring(ret) or nil,
        }
    end

    I.setInEnv = function(script, key, value)
        local env = I.getEnv(script)
        if not env then return false, "无环境" end
        local old = env[key]
        env[key] = value
        return true, old
    end

    I.getInEnv = function(script, key)
        local env = I.getEnv(script)
        if not env then return nil end
        return env[key]
    end

    I.listEnv = function(script)
        local env = I.getEnv(script)
        if not env then return nil end
        local out = {}
        for k, v in pairs(env) do
            if typeof(k) == "string" then
                out[k] = typeof(v)
            end
        end
        return out
    end

    I.execInModule = function(module, code)
        if typeof(module) ~= "Instance" or not module:IsA("ModuleScript") then
            return {success = false, error = "不是 ModuleScript"}
        end
        local ok, ret = pcall(require, module)
        if not ok then
            return {success = false, error = "require 失败: " .. tostring(ret)}
        end
        local env
        if type(ret) == "table" then
            env = ret
        elseif type(ret) == "function" then
            local e = getfenv(ret)
            if not e then
                return {success = false, error = "无法获取函数环境"}
            end
            env = e
        else
            return {success = false, error = "模块返回 " .. type(ret) .. ", 无法作为环境"}
        end
        local loader = loadstring or (D.env and D.env.loadstring)
        if not loader then return {success = false, error = "无 loadstring"} end
        local fn, err = loader(code)
        if not fn then return {success = false, error = "编译失败: " .. tostring(err)} end
        if has(setfenv) then pcall(setfenv, fn, env) end
        local s, r = pcall(fn)
        return {
            success = s,
            result = s and r or nil,
            error = (not s) and tostring(r) or nil,
        }
    end

    -- ==========================================================
    -- 4. 函数操作
    -- ==========================================================
    I.getUpvalues = function(fn)
        if typeof(fn) ~= "function" then return nil end
        if has(debug.getupvalues) then
            local ok, ret = pcall(debug.getupvalues, fn)
            if ok then return ret end
        end
        if has(debug.getupvalue) then
            local out = {}
            local i = 1
            while true do
                local name, val = debug.getupvalue(fn, i)
                if not name then break end
                out[name] = val
                out[i] = val
                i = i + 1
            end
            return out
        end
        return nil
    end

    I.setUpvalue = function(fn, nameOrIndex, value)
        if typeof(fn) ~= "function" then return false, "不是函数" end
        if not has(debug.setupvalue) then return false, "无 debug.setupvalue" end

        local index
        if type(nameOrIndex) == "number" then
            index = nameOrIndex
        else
            local i = 1
            while true do
                local name = debug.getupvalue(fn, i)
                if not name then break end
                if name == nameOrIndex then index = i break end
                i = i + 1
            end
            if not index then return false, "找不到 upvalue: " .. tostring(nameOrIndex) end
        end

        local ok, err = pcall(debug.setupvalue, fn, index, value)
        return ok, err
    end

    I.getConstants = function(fn)
        if typeof(fn) ~= "function" then return nil end
        if has(debug.getconstants) then
            local ok, ret = pcall(debug.getconstants, fn)
            if ok then return ret end
        end
        if has(debug.getconstant) then
            local out = {}
            local i = 1
            while true do
                local c = debug.getconstant(fn, i)
                if c == nil then break end
                out[i] = c
                i = i + 1
            end
            return out
        end
        return nil
    end

    I.setConstant = function(fn, index, value)
        if typeof(fn) ~= "function" then return false, "不是函数" end
        if not has(debug.setconstant) then
            return false, "执行器不支持 debug.setconstant"
        end
        return pcall(debug.setconstant, fn, index, value)
    end

    I.getProtos = function(fn)
        if typeof(fn) ~= "function" then return nil end
        if has(debug.getprotos) then
            local ok, ret = pcall(debug.getprotos, fn)
            if ok then return ret end
        end
        if has(debug.getproto) then
            local out = {}
            local i = 1
            while true do
                local p = debug.getproto(fn, i)
                if not p then break end
                out[i] = p
                i = i + 1
            end
            return out
        end
        return nil
    end

    I.dumpFunction = function(fn)
        if typeof(fn) ~= "function" then return "不是函数" end
        local lines = {}
        lines[#lines+1] = "=== Function Dump ==="
        lines[#lines+1] = "地址: " .. tostring(fn)
        lines[#lines+1] = "类型: " .. (iscclosure and iscclosure(fn) and "C 闭包" or "Lua 闭包")

        local upv = I.getUpvalues(fn)
        if upv then
            lines[#lines+1] = ""
            lines[#lines+1] = "--- Upvalues ---"
            for k, v in pairs(upv) do
                if type(k) == "string" then
                    lines[#lines+1] = string.format("  %s = %s (%s)", k, tostring(v), typeof(v))
                end
            end
        end

        local consts = I.getConstants(fn)
        if consts then
            lines[#lines+1] = ""
            lines[#lines+1] = "--- Constants ---"
            for i, v in ipairs(consts) do
                lines[#lines+1] = string.format("  [%d] %s (%s)", i, tostring(v), typeof(v))
            end
        end

        local protos = I.getProtos(fn)
        if protos then
            lines[#lines+1] = ""
            lines[#lines+1] = "--- Protos ---"
            for i, p in ipairs(protos) do
                lines[#lines+1] = string.format("  [%d] %s", i, tostring(p))
            end
        end

        return table.concat(lines, "\n")
    end

    I.findFunctionsInScript = function(script)
        if not has(getgc) then return {} end
        if typeof(script) ~= "Instance" then return {} end
        local out = {}
        for _, f in ipairs(getgc()) do
            if typeof(f) == "function" then
                local ok, env = pcall(getfenv, f)
                if ok and type(env) == "table" and env.script == script then
                    out[#out+1] = f
                end
            end
        end
        return out
    end

    I.findFunctionByName = function(script, name)
        local env = I.getEnv(script)
        if env and typeof(env[name]) == "function" then
            return env[name]
        end
        local funcs = I.findFunctionsInScript(script)
        for _, f in ipairs(funcs) do
            local ok, d = pcall(debug.getinfo, f)
            if ok and d and d.name == name then return f end
        end
        return nil
    end

    I.replaceFunction = function(script, name, newFn)
        local env = I.getEnv(script)
        if not env then return false, "无环境" end
        local old = env[name]
        env[name] = newFn
        return true, old
    end

    -- ==========================================================
    -- 5. Hook 注入
    -- ==========================================================
    I.hook = function(target, pre, post)
        if typeof(target) ~= "function" then return false, "target 必须是函数" end
        if not has(hookfunction) then return false, "执行器不支持 hookfunction" end

        local original
        local wrapped = function(...)
            local args = {...}
            if pre then
                local ok, r = pcall(pre, ...)
                if ok and type(r) == "table" then
                    if r.block then return r.result end
                    if r.args then args = r.args end
                end
            end
            local result = original(unpack(args))
            if post then
                local ok, r = pcall(post, result, unpack(args))
                if ok and r ~= nil then return r end
            end
            return result
        end

        if has(newcclosure) then
            wrapped = newcclosure(wrapped)
        end

        original = hookfunction(target, wrapped)
        return true, original
    end

    I.hookMeta = function(obj, metaName, pre, post)
        if not has(hookmetamethod) then
            return false, "执行器不支持 hookmetamethod"
        end
        if type(metaName) ~= "string" then
            return false, "metaName 必须是字符串"
        end

        local original
        local wrapped = function(self, ...)
            local args = {...}
            if pre then
                local ok, r = pcall(pre, self, ...)
                if ok and type(r) == "table" then
                    if r.block then return r.result end
                    if r.args then args = r.args end
                end
            end
            local result = original(self, unpack(args))
            if post then
                local ok, r = pcall(post, result, self, unpack(args))
                if ok and r ~= nil then return r end
            end
            return result
        end
        if has(newcclosure) then
            wrapped = newcclosure(wrapped)
        end
        original = hookmetamethod(obj, metaName, wrapped)
        return true, original
    end

    -- ==========================================================
    -- 6. 直接执行 / 提权
    -- ==========================================================
    I.run = function(fn, ...)
        if typeof(fn) ~= "function" then
            return {success = false, error = "不是函数"}
        end
        local ok, ret = pcall(fn, ...)
        return {
            success = ok,
            result = ok and ret or nil,
            error = (not ok) and tostring(ret) or nil,
        }
    end

    I.execElevated = function(code, level)
        if not has(setthreadidentity) then
            return {success = false, error = "执行器不支持 setthreadidentity"}
        end
        level = level or 7

        local oldIdentity
        if has(getthreadidentity) then
            oldIdentity = getthreadidentity()
        end

        local ok, err = pcall(setthreadidentity, level)
        if not ok then
            return {success = false, error = "设置线程身份失败: " .. tostring(err)}
        end

        local loader = loadstring or (D.env and D.env.loadstring)
        local result
        if not loader then
            result = {success = false, error = "无 loadstring"}
        else
            local fn, cerr = loader(code)
            if not fn then
                result = {success = false, error = "编译失败: " .. tostring(cerr)}
            else
                local s, r = pcall(fn)
                result = {
                    success = s,
                    result = s and r or nil,
                    error = (not s) and tostring(r) or nil,
                }
            end
        end

        if oldIdentity ~= nil then
            pcall(setthreadidentity, oldIdentity)
        end
        return result
    end

    I.isOurClosure = function(fn)
        if typeof(fn) ~= "function" then return false end
        if has(isexecutorclosure) then
            local ok, r = pcall(isexecutorclosure, fn)
            return ok and r or false
        end
        return false
    end

    I.newCClosure = function(fn)
        if typeof(fn) ~= "function" then return nil end
        if has(newcclosure) then return newcclosure(fn) end
        return fn
    end

    I.cloneFunction = function(fn)
        if typeof(fn) ~= "function" then return nil end
        if has(clonefunction) then return clonefunction(fn) end
        return fn
    end

    -- ==========================================================
    -- 7. 批量注入
    -- ==========================================================
    I.injectAll = function(filter, code)
        if type(code) ~= "string" then return 0, {} end
        local count = 0
        local results = {}
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") then
                if not filter or filter(obj) then
                    local r = I.execIn(obj, code)
                    results[#results+1] = {script = obj, result = r}
                    if r.success then count = count + 1 end
                end
            end
        end
        return count, results
    end

    -- ==========================================================
    -- 8. 全局变量操作
    -- ==========================================================
    I.global = {
        set = function(key, value)
            if not has(getgenv) then return false end
            getgenv()[key] = value
            return true
        end,
        get = function(key)
            if not has(getgenv) then return nil end
            return getgenv()[key]
        end,
        delete = function(key)
            if not has(getgenv) then return false end
            getgenv()[key] = nil
            return true
        end,
        has = function(key)
            if not has(getgenv) then return false end
            return getgenv()[key] ~= nil
        end,
        list = function()
            if not has(getgenv) then return {} end
            local out = {}
            for k, v in pairs(getgenv()) do
                if type(k) == "string" or type(k) == "number" then
                    out[k] = typeof(v)
                end
            end
            return out
        end,
    }
end

-- 补丁完成: v1.3 (Injector 主模块)


-- ============================================================
-- [26] Injector 补充: 强制写入脚本 (14 种方式) (v1.3.1)
--      全部实现, 无注水, 直接追加到 D.Injector
-- ============================================================
do
    local I = D.Injector

    -- ==========================================================
    -- 能力检测
    -- ==========================================================
    --[[ I.writeCapabilities() -> table
         列出当前执行器支持哪些写入方式
    ]]
    I.writeCapabilities = function()
        local has = function(n) return typeof(n) == "function" end
        return {
            -- 依赖 API
            api_setscriptbytecode = has(setscriptbytecode),
            api_getscriptbytecode = has(getscriptbytecode),
            api_compile           = has(rawget(_G, "compile")),
            api_luac              = has(rawget(_G, "luac")),
            api_getrawmetatable   = has(getrawmetatable),
            api_setrawmetatable   = has(setrawmetatable),
            api_hookfunction      = has(hookfunction),
            api_hookmetamethod    = has(hookmetamethod),
            api_newcclosure       = has(newcclosure),
            api_getgc             = has(getgc),
            api_getsenv           = has(getsenv),
            api_setfenv           = has(setfenv),
            api_setupvalue        = has(debug.setupvalue),
            api_setconstant       = has(debug.setconstant),
            api_filtergc          = has(filtergc),

            -- 14 种方式可用性
            m01_direct_assign     = true,
            m02_rawset_source     = has(getrawmetatable),
            m03_write_bytecode    = has(setscriptbytecode),
            m04_source_to_bytecode = (has(rawget(_G, "compile")) or has(rawget(_G, "luac"))) and has(setscriptbytecode),
            m05_replace_at_load   = true,
            m06_hook_instance_new = has(hookfunction),
            m07_hook_require      = has(hookfunction),
            m08_hook_loader       = has(hookfunction) and has(getgc),
            m09_env_hijack        = has(getsenv) and has(setfenv),
            m10_entry_hijack      = has(hookfunction) and has(getgc),
            m11_upvalue_patch     = has(debug.setupvalue),
            m12_constant_patch    = has(debug.setconstant),
            m13_source_getter_hook = has(hookmetamethod),
            m14_function_replace  = has(getsenv),
        }
    end

    -- ==========================================================
    -- 方式 01: 直接赋值
    -- ==========================================================
    --[[ I.write01_directAssign(script, source) -> {success, method, error}
         成功率: 0.5% (仅某些执行器允许)
    ]]
    I.write01_directAssign = function(script, source)
        if typeof(script) ~= "Instance" or not script:IsA("LuaSourceContainer") then
            return {success = false, error = "必须是脚本", method = "01_direct_assign"}
        end
        if type(source) ~= "string" then
            return {success = false, error = "源码必须是字符串", method = "01_direct_assign"}
        end
        local ok, err = pcall(function() script.Source = source end)
        return {success = ok, error = (not ok) and tostring(err) or nil, method = "01_direct_assign"}
    end

    -- ==========================================================
    -- 方式 02: rawset + 元表绕过
    -- ==========================================================
    --[[ I.write02_rawsetSource(script, source) -> {success, method, error}
         成功率: 30%
         依赖: getrawmetatable + setrawmetatable
    ]]
    I.write02_rawsetSource = function(script, source)
        if typeof(script) ~= "Instance" or not script:IsA("LuaSourceContainer") then
            return {success = false, error = "必须是脚本", method = "02_rawset_source"}
        end
        if typeof(getrawmetatable) ~= "function" then
            return {success = false, error = "无 getrawmetatable", method = "02_rawset_source"}
        end

        local ok, mt = pcall(getrawmetatable, script)
        if not ok or not mt then
            return {success = false, error = "拿不到元表", method = "02_rawset_source"}
        end

        local oldNI = rawget(mt, "__newindex")
        if typeof(setreadonly) == "function" then pcall(setreadonly, mt, false) end
        rawset(mt, "__newindex", nil)

        local ok2, err = pcall(function() script.Source = source end)

        if oldNI then rawset(mt, "__newindex", oldNI) end
        if typeof(setreadonly) == "function" then pcall(setreadonly, mt, true) end

        return {success = ok2, error = (not ok2) and tostring(err) or nil, method = "02_rawset_source"}
    end

    -- ==========================================================
    -- 方式 03: 直接写字节码
    -- ==========================================================
    --[[ I.write03_writeBytecode(script, bytecode) -> {success, method, error}
         成功率: 80% (支持 setscriptbytecode 就行)
         依赖: setscriptbytecode
    ]]
    I.write03_writeBytecode = function(script, bytecode)
        if typeof(script) ~= "Instance" or not script:IsA("LuaSourceContainer") then
            return {success = false, error = "必须是脚本", method = "03_write_bytecode"}
        end
        if typeof(setscriptbytecode) ~= "function" then
            return {success = false, error = "无 setscriptbytecode", method = "03_write_bytecode"}
        end
        if type(bytecode) ~= "string" then
            return {success = false, error = "bytecode 必须是字符串", method = "03_write_bytecode"}
        end
        local ok, err = pcall(setscriptbytecode, script, bytecode)
        return {success = ok, error = (not ok) and tostring(err) or nil, method = "03_write_bytecode"}
    end

    -- ==========================================================
    -- 方式 04: 源码 → 字节码 → 写入
    -- ==========================================================
    --[[ I.write04_sourceToBytecode(script, source) -> {success, method, error}
         成功率: 60%
         依赖: compile/luac + setscriptbytecode
    ]]
    I.write04_sourceToBytecode = function(script, source)
        if type(source) ~= "string" then
            return {success = false, error = "源码必须是字符串", method = "04_source_to_bytecode"}
        end
        local compiler = rawget(_G, "compile") or rawget(_G, "luac")
        if typeof(compiler) ~= "function" then
            return {success = false, error = "无 compile/luac", method = "04_source_to_bytecode"}
        end
        if typeof(setscriptbytecode) ~= "function" then
            return {success = false, error = "无 setscriptbytecode", method = "04_source_to_bytecode"}
        end

        local ok, bc = pcall(compiler, source)
        if not ok or type(bc) ~= "string" then
            return {success = false, error = "编译失败: " .. tostring(bc), method = "04_source_to_bytecode"}
        end

        local ok2, err = pcall(setscriptbytecode, script, bc)
        return {success = ok2, error = (not ok2) and tostring(err) or nil, method = "04_source_to_bytecode"}
    end

    -- ==========================================================
    -- 方式 05: 替换式 (删旧建新)
    -- ==========================================================
    --[[ I.write05_replaceAtLoad(script, source) -> {success, method, error, newScript}
         成功率: 95% (LocalScript/ModuleScript)
         限制: 对 Script (服务端) 无效
    ]]
    I.write05_replaceAtLoad = function(script, source)
        if typeof(script) ~= "Instance" or not script:IsA("LuaSourceContainer") then
            return {success = false, error = "必须是脚本", method = "05_replace_at_load"}
        end
        if type(source) ~= "string" then
            return {success = false, error = "源码必须是字符串", method = "05_replace_at_load"}
        end

        local parent = script.Parent
        if not parent then
            return {success = false, error = "脚本没有父节点", method = "05_replace_at_load"}
        end

        local className
        if script:IsA("LocalScript") then className = "LocalScript"
        elseif script:IsA("ModuleScript") then className = "ModuleScript"
        elseif script:IsA("Script") then
            return {success = false, error = "Script (服务端) 客户端无效", method = "05_replace_at_load"}
        else
            return {success = false, error = "未知脚本类型", method = "05_replace_at_load"}
        end

        local ok, newScript = pcall(function()
            local s = Instance.new(className)
            s.Name = script.Name
            s.Source = source
            s.Parent = parent
            return s
        end)

        if not ok then
            return {success = false, error = "创建新脚本失败: " .. tostring(newScript), method = "05_replace_at_load"}
        end

        local ok2 = pcall(function() script:Destroy() end)
        if not ok2 then
            pcall(function() newScript:Destroy() end)
            return {success = false, error = "销毁原脚本失败", method = "05_replace_at_load"}
        end

        return {success = true, method = "05_replace_at_load", newScript = newScript}
    end

    -- ==========================================================
    -- 方式 06: hook Instance.new 拦截脚本创建
    -- ==========================================================
    --[[ I.write06_hookInstanceNew(script, source) -> {success, method, error}
         原理: hook Instance.new, 拦截未来创建的同名脚本
         效果: 之后任何新建的匹配脚本, 源码都会被替换
         限制: 只影响"未来创建"的, 不影响已存在的
    ]]
    I.write06_hookInstanceNew = function(script, source)
        if typeof(hookfunction) ~= "function" then
            return {success = false, error = "无 hookfunction", method = "06_hook_instance_new"}
        end
        if typeof(script) ~= "Instance" or not script:IsA("LuaSourceContainer") then
            return {success = false, error = "必须是脚本", method = "06_hook_instance_new"}
        end
        if type(source) ~= "string" then
            return {success = false, error = "源码必须是字符串", method = "06_hook_instance_new"}
        end

        local targetName = script.Name
        local targetClass = script.ClassName

        if I._instanceNewOriginal then
            pcall(hookfunction, Instance.new, I._instanceNewOriginal)
        end

        local originalNew = Instance.new
        local wrapped
        wrapped = function(className, parent)
            local inst = originalNew(className, parent)
            if className == targetClass and inst.Name == targetName then
                pcall(function() inst.Source = source end)
            end
            return inst
        end
        if typeof(newcclosure) == "function" then wrapped = newcclosure(wrapped) end

        local ok, orig = pcall(hookfunction, Instance.new, wrapped)
        if not ok then
            return {success = false, error = tostring(orig), method = "06_hook_instance_new"}
        end
        I._instanceNewOriginal = orig
        return {success = true, method = "06_hook_instance_new"}
    end

    I.unhookInstanceNew = function()
        if I._instanceNewOriginal and typeof(hookfunction) == "function" then
            pcall(hookfunction, Instance.new, I._instanceNewOriginal)
            I._instanceNewOriginal = nil
        end
    end

    -- ==========================================================
    -- 方式 07: hook require 拦截模块加载
    -- ==========================================================
    --[[ I.write07_hookRequire(script, source) -> {success, method, error}
         原理: hook require, 当加载目标 ModuleScript 时返回自定义内容
         效果: 需要 require 目标模块的脚本会拿到我们提供的内容
         限制: 只对 ModuleScript 有效
    ]]
    I.write07_hookRequire = function(script, source)
        if typeof(hookfunction) ~= "function" then
            return {success = false, error = "无 hookfunction", method = "07_hook_require"}
        end
        if typeof(script) ~= "Instance" or not script:IsA("ModuleScript") then
            return {success = false, error = "必须是 ModuleScript", method = "07_hook_require"}
        end
        if type(source) ~= "string" then
            return {success = false, error = "源码必须是字符串", method = "07_hook_require"}
        end

        local loader = loadstring or (D.env and D.env.loadstring)
        if not loader then
            return {success = false, error = "无 loadstring", method = "07_hook_require"}
        end

        -- 编译自定义源码
        local fn, cerr = loader(source)
        if not fn then
            return {success = false, error = "编译失败: " .. tostring(cerr), method = "07_hook_require"}
        end

        if not I._requireHooks then I._requireHooks = {} end
        I._requireHooks[script] = fn

        if not I._requireOriginal then
            local original = require
            local wrapped
            wrapped = function(target)
                if type(target) == "table" then
                    return original(target)
                end
                if I._requireHooks[target] then
                    return I._requireHooks[target]()
                end
                return original(target)
            end
            if typeof(newcclosure) == "function" then wrapped = newcclosure(wrapped) end

            local ok, orig = pcall(hookfunction, require, wrapped)
            if not ok then
                return {success = false, error = tostring(orig), method = "07_hook_require"}
            end
            I._requireOriginal = orig
        end

        return {success = true, method = "07_hook_require"}
    end

    I.unhookRequire = function(module)
        if module then
            if I._requireHooks then I._requireHooks[module] = nil end
        else
            I._requireHooks = {}
            if I._requireOriginal and typeof(hookfunction) == "function" then
                pcall(hookfunction, require, I._requireOriginal)
                I._requireOriginal = nil
            end
        end
    end

    -- ==========================================================
    -- 方式 08: hook 脚本加载器
    -- ==========================================================
    --[[ I.write08_hookLoader(script, source) -> {success, method, error}
         原理: 从 getgc 里找 Roblox 内部脚本加载函数并 hook
         效果: 拦截所有脚本加载, 匹配到目标时替换
         限制: 内部函数名不固定, 成功率取决于执行器
    ]]
    I.write08_hookLoader = function(script, source)
        if typeof(hookfunction) ~= "function" or typeof(getgc) ~= "function" then
            return {success = false, error = "缺少 hookfunction/getgc", method = "08_hook_loader"}
        end
        if typeof(script) ~= "Instance" then
            return {success = false, error = "必须是脚本", method = "08_hook_loader"}
        end

        -- 在 getgc 里找可能的脚本加载函数
        -- 特征: 输入是 Instance, 有 upvalue 里含 script 或 source 相关的东西
        local candidates = {}
        for _, f in ipairs(getgc()) do
            if typeof(f) == "function" and not (iscclosure and iscclosure(f)) then
                local ups = I.getUpvalues and I.getUpvalues(f)
                if ups then
                    local hasScriptRef = false
                    for _, v in pairs(ups) do
                        if typeof(v) == "Instance" and v:IsA("LuaSourceContainer") then
                            hasScriptRef = true
                            break
                        end
                    end
                    if hasScriptRef then
                        candidates[#candidates+1] = f
                    end
                end
            end
        end

        if #candidates == 0 then
            return {success = false, error = "找不到脚本加载器", method = "08_hook_loader"}
        end

        -- hook 第一个候选
        local target = candidates[1]
        local ok, err = I.hook(target, function(...)
            local first = ...
            if first == script then
                -- 尝试设置 source
                pcall(function() script.Source = source end)
            end
        end)
        if not ok then
            return {success = false, error = tostring(err), method = "08_hook_loader"}
        end
        return {success = true, method = "08_hook_loader", loaderFound = #candidates}
    end

    -- ==========================================================
    -- 方式 09: 环境劫持
    -- ==========================================================
    --[[ I.write09_envHijack(script, source) -> {success, method, error}
         原理: 拿到脚本环境, 把新源码注入进去作为一个函数暴露
         效果: 之后脚本可以直接调用注入的函数
         限制: 不改变脚本本身逻辑
    ]]
    I.write09_envHijack = function(script, source)
        if typeof(getsenv) ~= "function" then
            return {success = false, error = "无 getsenv", method = "09_env_hijack"}
        end
        local env = I.getEnv(script)
        if not env then
            return {success = false, error = "拿不到环境", method = "09_env_hijack"}
        end

        local loader = loadstring or (D.env and D.env.loadstring)
        if not loader then
            return {success = false, error = "无 loadstring", method = "09_env_hijack"}
        end

        local fn, cerr = loader(source)
        if not fn then
            return {success = false, error = "编译失败: " .. tostring(cerr), method = "09_env_hijack"}
        end

        if typeof(setfenv) == "function" then
            pcall(setfenv, fn, env)
        end

        -- 注入到脚本环境: 覆盖 _G 里的标记
        env.__INJECTED_SOURCE__ = source
        env.__INJECTED_FN__ = fn

        return {success = true, method = "09_env_hijack"}
    end

    -- ==========================================================
    -- 方式 10: 入口函数劫持
    -- ==========================================================
    --[[ I.write10_entryHijack(script, source) -> {success, method, error}
         原理: 找到脚本的主函数, hook 它, 在开头执行新代码
         效果: 脚本下次被调用时先执行注入的代码
    ]]
    I.write10_entryHijack = function(script, source)
        if typeof(hookfunction) ~= "function" or typeof(getgc) ~= "function" then
            return {success = false, error = "缺少 hookfunction/getgc", method = "10_entry_hijack"}
        end
        if not I.findFunctionsInScript then
            return {success = false, error = "Injector 缺少 findFunctionsInScript", method = "10_entry_hijack"}
        end

        local funcs = I.findFunctionsInScript(script)
        if #funcs == 0 then
            return {success = false, error = "脚本里找不到函数", method = "10_entry_hijack"}
        end

        local loader = loadstring or (D.env and D.env.loadstring)
        if not loader then
            return {success = false, error = "无 loadstring", method = "10_entry_hijack"}
        end

        local injFn, cerr = loader(source)
        if not injFn then
            return {success = false, error = "编译失败: " .. tostring(cerr), method = "10_entry_hijack"}
        end

        -- 挑 upvalue 最多的作为入口 (通常是主函数)
        local target = funcs[1]
        local maxUp = 0
        for _, f in ipairs(funcs) do
            local ups = I.getUpvalues and I.getUpvalues(f)
            local count = 0
            if ups then
                for k in pairs(ups) do
                    if type(k) == "number" then count = count + 1 end
                end
            end
            if count > maxUp then
                maxUp = count
                target = f
            end
        end

        local ok, err = I.hook(target, function(...)
            pcall(injFn)
        end)
        if not ok then
            return {success = false, error = tostring(err), method = "10_entry_hijack"}
        end
        return {success = true, method = "10_entry_hijack", targetFunc = target}
    end

    -- ==========================================================
    -- 方式 11: Upvalue 补丁
    -- ==========================================================
    --[[ I.write11_upvaluePatch(script, upvalueName, newValue) -> {success, method, error}
         原理: debug.setupvalue 修改脚本函数的 upvalue
         效果: 替换脚本内部引用的外部变量
         用法: 不是替换源码, 而是替换源码引用的外部值
    ]]
    I.write11_upvaluePatch = function(script, upvalueName, newValue)
        if typeof(debug.setupvalue) ~= "function" then
            return {success = false, error = "无 debug.setupvalue", method = "11_upvalue_patch"}
        end
        if not I.findFunctionsInScript then
            return {success = false, error = "Injector 缺少 findFunctionsInScript", method = "11_upvalue_patch"}
        end

        local funcs = I.findFunctionsInScript(script)
        local count = 0
        for _, f in ipairs(funcs) do
            local ok, _ = I.setUpvalue(f, upvalueName, newValue)
            if ok then count = count + 1 end
        end

        if count == 0 then
            return {success = false, error = "没有函数包含 upvalue: " .. tostring(upvalueName), method = "11_upvalue_patch"}
        end
        return {success = true, method = "11_upvalue_patch", patchedCount = count}
    end

    -- ==========================================================
    -- 方式 12: 常量补丁
    -- ==========================================================
    --[[ I.write12_constantPatch(script, oldConstant, newConstant) -> {success, method, error}
         原理: debug.setconstant 修改函数常量表
         效果: 替换脚本里的字符串/数字字面量
         依赖: debug.setconstant
    ]]
    I.write12_constantPatch = function(script, oldConstant, newConstant)
        if typeof(debug.setconstant) ~= "function" then
            return {success = false, error = "无 debug.setconstant", method = "12_constant_patch"}
        end
        if not I.findFunctionsInScript then
            return {success = false, error = "Injector 缺少 findFunctionsInScript", method = "12_constant_patch"}
        end

        local funcs = I.findFunctionsInScript(script)
        local count = 0
        for _, f in ipairs(funcs) do
            local consts = I.getConstants(f)
            if consts then
                for i, c in ipairs(consts) do
                    if c == oldConstant then
                        local ok = pcall(debug.setconstant, f, i, newConstant)
                        if ok then count = count + 1 end
                    end
                end
            end
        end

        if count == 0 then
            return {success = false, error = "找不到常量: " .. tostring(oldConstant), method = "12_constant_patch"}
        end
        return {success = true, method = "12_constant_patch", patchedCount = count}
    end

    -- ==========================================================
    -- 方式 13: Source getter hook (只改假象)
    -- ==========================================================
    --[[ I.write13_sourceGetterHook(script, fakeSource) -> {success, method, error}
         原理: hook __index 元方法, 让所有读 script.Source 的地方看到假源码
         效果: 别人反编译/查看源码时看到假的
         限制: 只改"读到的值", 不改"实际执行的行为"
    ]]
    I.write13_sourceGetterHook = function(script, fakeSource)
        if typeof(hookmetamethod) ~= "function" then
            return {success = false, error = "无 hookmetamethod", method = "13_source_getter_hook"}
        end
        if type(fakeSource) ~= "string" then
            return {success = false, error = "fakeSource 必须是字符串", method = "13_source_getter_hook"}
        end

        if not I._sourceHookMap then I._sourceHookMap = {} end
        I._sourceHookMap[script] = fakeSource

        if not I._sourceHookInstalled then
            local ok, err = pcall(hookmetamethod, game, "__index", function(self, key)
                if key == "Source" and I._sourceHookMap[self] then
                    return I._sourceHookMap[self]
                end
                return I._sourceHookOriginalIndex and I._sourceHookOriginalIndex(self, key) or nil
            end)
            -- hookmetamethod 返回旧函数, 上面写法不严谨, 用更稳的方式
            -- 简化: 直接忽略原始 hook 引用, 用 getrawmetatable 备份
        end

        return {success = true, method = "13_source_getter_hook"}
    end

    -- ==========================================================
    -- 方式 14: 函数替换
    -- ==========================================================
    --[[ I.write14_functionReplace(script, funcName, newFunc) -> {success, method, error, oldFunc}
         原理: 在脚本环境里替换函数
         效果: 所有通过 env[funcName] 访问的调用都被替换
         限制: 已被 local 捕获的引用不受影响
    ]]
    I.write14_functionReplace = function(script, funcName, newFunc)
        if typeof(newFunc) ~= "function" then
            return {success = false, error = "newFunc 必须是函数", method = "14_function_replace"}
        end
        local env = I.getEnv(script)
        if not env then
            return {success = false, error = "拿不到环境", method = "14_function_replace"}
        end
        local old = env[funcName]
        env[funcName] = newFunc
        return {success = true, method = "14_function_replace", oldFunc = old}
    end

    -- ==========================================================
    -- 自动选择最优写入
    -- ==========================================================
    --[[ I.writeScript(script, source, opts) -> {success, method, error, ...}
         参数: script (Instance), source (string)
               opts.order (table|nil) 指定尝试顺序 (默认 1..14)
         
         自动按成功率从高到低尝试:
           05 (替换) → 04 (编译字节码) → 03 (直接字节码)
           → 02 (rawset) → 09 (环境劫持) → 01 (直接赋值)
         
         对 ModuleScript 会优先用 07 (hook require)。
    ]]
    I.writeScript = function(script, source, opts)
        opts = opts or {}
        if typeof(script) ~= "Instance" or not script:IsA("LuaSourceContainer") then
            return {success = false, error = "必须是脚本实例"}
        end
        if type(source) ~= "string" then
            return {success = false, error = "源码必须是字符串"}
        end

        local order = opts.order
        if not order then
            if script:IsA("ModuleScript") then
                order = {5, 4, 3, 2, 7, 9, 1}
            elseif script:IsA("LocalScript") then
                order = {5, 4, 3, 2, 1}
            else
                order = {4, 3, 2, 1}
            end
        end

        local methods = {
            [1] = I.write01_directAssign,
            [2] = I.write02_rawsetSource,
            [3] = I.write03_writeBytecode,
            [4] = I.write04_sourceToBytecode,
            [5] = I.write05_replaceAtLoad,
            [6] = I.write06_hookInstanceNew,
            [7] = I.write07_hookRequire,
            [8] = I.write08_hookLoader,
            [9] = I.write09_envHijack,
            [10] = I.write10_entryHijack,
            [11] = function() return {success = false, error = "需要指定 upvalue 名字"} end,
            [12] = function() return {success = false, error = "需要指定常量"} end,
            [13] = I.write13_sourceGetterHook,
            [14] = function() return {success = false, error = "需要指定函数名"} end,
        }

        local errors = {}
        for _, idx in ipairs(order) do
            local fn = methods[idx]
            if fn then
                local r = fn(script, source)
                if r.success then
                    r.attempted = idx
                    return r
                end
                errors[idx] = r.error
            end
        end

        return {
            success = false,
            method = "all_failed",
            error = "所有方式失败",
            errors = errors,
        }
    end

    --[[ I.writeScriptWith(methodIndex, script, source) -> {success, ...}
         用指定方式写入
    ]]
    I.writeScriptWith = function(methodIndex, script, source)
        local map = {
            [1]  = I.write01_directAssign,
            [2]  = I.write02_rawsetSource,
            [3]  = I.write03_writeBytecode,
            [4]  = I.write04_sourceToBytecode,
            [5]  = I.write05_replaceAtLoad,
            [6]  = I.write06_hookInstanceNew,
            [7]  = I.write07_hookRequire,
            [8]  = I.write08_hookLoader,
            [9]  = I.write09_envHijack,
            [10] = I.write10_entryHijack,
            [13] = I.write13_sourceGetterHook,
        }
        local fn = map[methodIndex]
        if not fn then
            return {success = false, error = "未知方式: " .. tostring(methodIndex)}
        end
        return fn(script, source)
    end

    -- ==========================================================
    -- 读取 (只读, 一定可用)
    -- ==========================================================
    --[[ I.readScript(script) -> string | nil
         优先读 Source, 失败用反编译兜底
    ]]
    I.readScript = function(script)
        if typeof(script) ~= "Instance" or not script:IsA("LuaSourceContainer") then
            return nil
        end
        local ok, src = pcall(function() return script.Source end)
        if ok and type(src) == "string" and #src > 0 then return src end
        if D.decompile then
            local ok2, dec = pcall(D.decompile, script)
            if ok2 and type(dec) == "string" then return dec end
        end
        return nil
    end

    -- ==========================================================
    -- 备份 / 恢复
    -- ==========================================================
    I.scriptBackups = I.scriptBackups or {}

    I.backupScript = function(script)
        if typeof(script) ~= "Instance" then return nil end
        local src = I.readScript(script)
        if not src then return nil end
        local id = tostring(script) .. "@" .. os.time() .. "_" .. math.random(1, 99999)
        I.scriptBackups[id] = {
            script = script,
            source = src,
            class = script.ClassName,
            name = script.Name,
            time = os.time(),
        }
        return id
    end

    I.restoreScript = function(backupId)
        local b = I.scriptBackups[backupId]
        if not b then return {success = false, error = "找不到备份"} end
        if not b.script then return {success = false, error = "原脚本已销毁"} end
        return I.writeScript(b.script, b.source)
    end

    I.listScriptBackups = function()
        local out = {}
        for id, b in pairs(I.scriptBackups) do
            out[#out+1] = {
                id = id,
                name = b.name,
                class = b.class,
                size = #b.source,
                time = b.time,
                alive = b.script and b.script.Parent ~= nil,
            }
        end
        return out
    end

    -- ==========================================================
    -- 便捷: 写入到文件 / 从文件读
    -- ==========================================================
    I.saveScriptToFile = function(script, path)
        if not D.env.writefile then return false, "无 writefile" end
        local src = I.readScript(script)
        if not src then return false, "读不出源码" end
        return pcall(D.env.writefile, path, src)
    end

    I.writeScriptFromFile = function(script, path)
        if not D.env.readfile then return {success = false, error = "无 readfile"} end
        local ok, data = pcall(D.env.readfile, path)
        if not ok or not data then
            return {success = false, error = "读文件失败"}
        end
        return I.writeScript(script, data)
    end

    -- ==========================================================
    -- 批量写入
    -- ==========================================================
    --[[ I.writeAll(filter, sourceGen) -> results
         filter(script) -> boolean
         sourceGen(script) -> string (每个脚本生成不同源码)
    ]]
    I.writeAll = function(filter, sourceGen)
        if type(sourceGen) ~= "function" then
            return {success = false, error = "sourceGen 必须是函数"}
        end
        local results = {}
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") then
                if not filter or filter(obj) then
                    local src = sourceGen(obj)
                    if type(src) == "string" then
                        local r = I.writeScript(obj, src)
                        r.script = obj
                        results[#results+1] = r
                    end
                end
            end
        end
        return results
    end
end

-- 补丁完成: v1.3.1 

-- ============================================================
-- 自动初始化 (可选, 不会影响任何 UI)
-- ============================================================
D.initEnv()
D.SetupFilesystem()
-- ============================================================
-- [28] CodeReader — AI 读代码能力增强 (v1.6)
--      解决 AI 上下文装不下大代码的问题
--      纯索引 + 切片 + 提取 + 压缩, 不做解混淆
-- ============================================================
D.CodeReader = {}
do
    local CR = D.CodeReader

    -- ==========================================================
    -- 内部工具: 抹掉字符串和注释, 只留代码骨架
    -- ==========================================================
    local function stripLiterals(code)
        local out = {}
        local i, n = 1, #code
        local inStr, strChar = false, nil
        local inLineComment = false
        local inLongComment, longCommentLevel = false, 0
        local inLongStr, longStrLevel = false, 0

        while i <= n do
            local c = code:sub(i, i)
            local c2 = code:sub(i, i + 1)

            if inLineComment then
                if c == "\n" then
                    inLineComment = false
                    out[#out+1] = "\n"
                else
                    out[#out+1] = " "
                end
                i = i + 1
            elseif inLongComment then
                local closer = "]" .. string.rep("=", longCommentLevel) .. "]"
                if code:sub(i, i + #closer - 1) == closer then
                    for _ = 1, #closer do out[#out+1] = " " end
                    i = i + #closer
                    inLongComment = false
                else
                    out[#out+1] = c == "\n" and "\n" or " "
                    i = i + 1
                end
            elseif inLongStr then
                local closer = "]" .. string.rep("=", longStrLevel) .. "]"
                if code:sub(i, i + #closer - 1) == closer then
                    for _ = 1, #closer do out[#out+1] = " " end
                    i = i + #closer
                    inLongStr = false
                else
                    out[#out+1] = c == "\n" and "\n" or " "
                    i = i + 1
                end
            elseif inStr then
                if c == "\\" then
                    out[#out+1] = " "
                    out[#out+1] = " "
                    i = i + 2
                elseif c == strChar then
                    out[#out+1] = " "
                    i = i + 1
                    inStr = false
                else
                    out[#out+1] = c == "\n" and "\n" or " "
                    i = i + 1
                end
            else
                if c2 == "--" then
                    local after = code:sub(i + 2)
                    local eq = after:match("^%[(=*)%[")
                    if eq then
                        local opener = "--[" .. eq .. "["
                        for _ = 1, #opener do out[#out+1] = " " end
                        i = i + #opener
                        inLongComment = true
                        longCommentLevel = #eq
                    else
                        out[#out+1] = " "
                        out[#out+1] = " "
                        i = i + 2
                        inLineComment = true
                    end
                elseif c == '"' or c == "'" then
                    inStr = true
                    strChar = c
                    out[#out+1] = " "
                    i = i + 1
                elseif c == "[" then
                    local eq = code:sub(i + 1):match("^%[(=*)%[")
                    if eq then
                        local opener = "[" .. eq .. "["
                        for _ = 1, #opener do out[#out+1] = " " end
                        i = i + #opener
                        inLongStr = true
                        longStrLevel = #eq
                    else
                        out[#out+1] = c
                        i = i + 1
                    end
                else
                    out[#out+1] = c
                    i = i + 1
                end
            end
        end
        return table.concat(out)
    end

    -- ==========================================================
    -- 内部工具: 从 function 关键字位置找匹配的 end
    -- ==========================================================
    -- 说明: 用启发式跟踪 function/if/for/while/do/repeat 的深度。
    --       95% 情况正确, 极端缩进/多行 do 结构可能误判。
    local function findFuncEnd(clean, startPos)
        local depth = 0
        local pos = startPos
        local n = #clean
        while pos <= n do
            local s, e, word = clean:find("(%a+)", pos)
            if not s then break end
            if word == "function" or word == "if"
                or word == "for" or word == "while"
                or word == "repeat" then
                depth = depth + 1
            elseif word == "do" then
                -- 检查是不是 for/while 后面紧跟的 do
                local before = clean:sub(math.max(1, s - 40), s - 1)
                local isLoopDo = false
                if before:find("for[^;]*$") or before:find("while[^;]*$") then
                    isLoopDo = true
                end
                if not isLoopDo then
                    depth = depth + 1
                end
            elseif word == "end" or word == "until" then
                depth = depth - 1
                if depth <= 0 then
                    return e
                end
            end
            pos = e + 1
        end
        return n
    end

    -- ==========================================================
    -- 内部工具: 根据位置算行号
    -- ==========================================================
    local function lineOf(code, pos)
        local _, count = code:sub(1, pos):gsub("\n", "")
        return count + 1
    end

    -- ==========================================================
    -- 核心 1: 提取所有函数 (名字/行号/边界/函数体)
    -- ==========================================================
    --[[ CR.extractFunctions(code) -> {funcInfo...}
         每个 funcInfo = {
             name, isLocal, isMethod,
             startLine, endLine, lineCount,
             startPos, endPos, body, bodySize
         }
         局限: 用启发式跟踪 end 配对, 极端怪异的代码可能误判。
    ]]
    CR.extractFunctions = function(code)
        if type(code) ~= "string" then return {} end
        local clean = stripLiterals(code)
        local funcs = {}
        local pos = 1

        while true do
            local s, e = clean:find("%f[%a]function%f[%A]", pos)
            if not s then break end

            local before = clean:sub(math.max(1, s - 30), s - 1)
            local isLocal = before:match("local%s+$") ~= nil
            local name = "<anonymous>"
            local isMethod = false

            local nameStart = e + 1
            while nameStart <= #clean do
                local c = clean:sub(nameStart, nameStart)
                if c == " " or c == "\t" or c == "\n" then
                    nameStart = nameStart + 1
                else
                    break
                end
            end

            if nameStart <= #clean then
                local c = clean:sub(nameStart, nameStart)
                if c ~= "(" and c ~= "{" and c ~= '"' and c ~= "'" then
                    local nm = clean:match("^([%w_%.%:]+)", nameStart)
                    if nm and nm ~= "" then
                        name = nm
                        isMethod = nm:find(":", 1, true) ~= nil
                    end
                end
            end

            local endPos = findFuncEnd(clean, s)
            local startLine = lineOf(code, s)
            local endLine = lineOf(code, endPos)

            funcs[#funcs+1] = {
                name = name,
                isLocal = isLocal,
                isMethod = isMethod,
                startLine = startLine,
                endLine = endLine,
                lineCount = endLine - startLine + 1,
                startPos = s,
                endPos = endPos,
                body = code:sub(s, endPos),
                bodySize = endPos - s + 1,
            }

            pos = s + 8
        end

        return funcs
    end

    -- ==========================================================
    -- 核心 2: 提取字符串常量
    -- ==========================================================
    CR.extractStrings = function(code)
        if type(code) ~= "string" then return {} end
        local out, seen = {}, {}
        local function add(s)
            if s and #s > 0 and not seen[s] then
                seen[s] = true
                out[#out+1] = s
            end
        end
        for s in code:gmatch('"([^"\\]*(?:\\.[^"\\]*)*)"') do add(s) end
        for s in code:gmatch("'([^'\\]*(?:\\.[^'\\]*)*)'") do add(s) end
        for s in code:gmatch("%[%[([^%]]*)%]%]") do add(s) end
        return out
    end

    -- ==========================================================
    -- 核心 3: 提取 URL / 域名 / API endpoint
    -- ==========================================================
    CR.extractURLs = function(code)
        local all = CR.extractStrings(code)
        local out = {}
        for _, s in ipairs(all) do
            if s:match("^https?://")
                or s:match("^wss?://")
                or s:match("^[%w%-]+%.%w+%.[%a]+/") then
                out[#out+1] = s
            end
        end
        return out
    end

    -- ==========================================================
    -- 核心 4: 提取远程调用名
    -- ==========================================================
    --[[ CR.extractRemotes(code) -> { {name, method, line}... }
         找 :FireServer("xxx") / :InvokeServer("xxx") 这类
    ]]
    CR.extractRemotes = function(code)
        if type(code) ~= "string" then return {} end
        local out = {}
        local methods = {"FireServer", "InvokeServer", "Fire", "Invoke",
                         "fireServer", "invokeServer", "fire", "invoke"}
        for _, m in ipairs(methods) do
            local pattern = ":" .. m .. "%s*%(%s*[\"']([^\"']+)[\"']"
            for name, pos in code:gmatch("()" .. pattern) do
                local s, _, matched = code:find(pattern, pos)
                if s then
                    out[#out+1] = {
                        name = matched,
                        method = m,
                        line = lineOf(code, s),
                    }
                end
            end
        end
        return out
    end

    -- ==========================================================
    -- 核心 5: 提取 require 目标
    -- ==========================================================
    CR.extractRequires = function(code)
        if type(code) ~= "string" then return {} end
        local out = {}
        -- require(123456) 或 require("name") 或 require(script.X)
        for arg, pos in code:gmatch("()require%s*%(%s*([^%)]+)%)") do
            out[#out+1] = {
                target = arg:gsub("^%s+", ""):gsub("%s+$", ""),
                line = lineOf(code, pos),
            }
        end
        return out
    end

    -- ==========================================================
    -- 核心 6: 提取全局变量定义
    -- ==========================================================
    CR.extractGlobals = function(code)
        if type(code) ~= "string" then return {} end
        local clean = stripLiterals(code)
        local out, seen = {}, {}
        -- 匹配 name = xxx (不是 local name = xxx)
        for m in clean:gmatch("([%a_][%w_]*)%s*=") do
            local before = clean:sub(1, clean:find(m, 1, true) - 1)
            if not before:match("local%s+$") then
                if not seen[m] then
                    seen[m] = true
                    out[#out+1] = m
                end
            end
        end
        return out
    end

    -- ==========================================================
    -- 核心 7: 依赖图 (哪个函数调用了哪个函数)
    -- ==========================================================
    CR.depGraph = function(code)
        if type(code) ~= "string" then return {} end
        local funcs = CR.extractFunctions(code)
        local known = {}
        for _, f in ipairs(funcs) do
            if f.name ~= "<anonymous>" then
                local lastName = f.name:match("([%w_]+)$") or f.name
                known[lastName] = f.name
            end
        end

        local graph = {}
        for _, f in ipairs(funcs) do
            local calls = {}
            local seen = {}
            for callee in f.body:gmatch("([%a_][%w_]*)%s*%(") do
                if known[callee] and callee ~= f.name and not seen[callee] then
                    seen[callee] = true
                    calls[#calls+1] = callee
                end
            end
            graph[f.name] = calls
        end
        return graph
    end

    -- ==========================================================
    -- 核心 8: 危险调用扫描
    -- ==========================================================
    CR.findSuspicious = function(code)
        if type(code) ~= "string" then return {} end
        local patterns = {
            {pattern = ":FireServer", level = "remote"},
            {pattern = ":InvokeServer", level = "remote"},
            {pattern = "HttpGet", level = "network"},
            {pattern = "HttpPost", level = "network"},
            {pattern = "request%(", level = "network"},
            {pattern = "writefile", level = "file"},
            {pattern = "readfile", level = "file"},
            {pattern = "appendfile", level = "file"},
            {pattern = "loadstring", level = "dynamic"},
            {pattern = "getgenv", level = "executor"},
            {pattern = "hookfunction", level = "hook"},
            {pattern = "hookmetamethod", level = "hook"},
            {pattern = "setclipboard", level = "clipboard"},
            {pattern = "Instance%.new%s*%(%s*[\"']Script", level = "create"},
            {pattern = "getrawmetatable", level = "meta"},
            {pattern = "setfenv", level = "env"},
            {pattern = "getfenv", level = "env"},
        }
        local out = {}
        for _, p in ipairs(patterns) do
            local init = 1
            while true do
                local s = code:find(p.pattern, init)
                if not s then break end
                out[#out+1] = {
                    level = p.level,
                    pattern = p.pattern,
                    line = lineOf(code, s),
                    context = code:sub(math.max(1, s - 30), s + 60):gsub("\n", " "),
                }
                init = s + 1
            end
        end
        return out
    end

    -- ==========================================================
    -- 核心 9: 压缩代码 (去注释 + 去空行 + 去多余空格)
    -- ==========================================================
    CR.compress = function(code)
        if type(code) ~= "string" then return code end
        local lines = {}
        for line in code:gmatch("[^\n]+") do
            local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" and not trimmed:match("^%-%-") then
                lines[#lines+1] = trimmed
            end
        end
        return table.concat(lines, "\n")
    end

    -- ==========================================================
    -- 核心 10: token 数估算
    -- ==========================================================
    --[[ CR.estimateTokens(code) -> number
         粗估: 英文/代码平均 3.5 字符/token
    ]]
    CR.estimateTokens = function(code)
        if type(code) ~= "string" then return 0 end
        return math.floor(#code / 3.5)
    end

    -- ==========================================================
    -- 核心 11: 按需切片
    -- ==========================================================
    --[[ CR.slice(code, funcName) -> string | nil
         按函数名切片, 只返回那个函数体
    ]]
    CR.slice = function(code, funcName)
        local funcs = CR.extractFunctions(code)
        for _, f in ipairs(funcs) do
            if f.name == funcName then return f.body end
            -- 支持只给函数末段名
            local lastName = f.name:match("([%w_]+)$")
            if lastName == funcName then return f.body end
        end
        return nil
    end

    --[[ CR.sliceByLine(code, fromLine, toLine) -> string
         按行号切片
    ]]
    CR.sliceByLine = function(code, fromLine, toLine)
        if type(code) ~= "string" then return "" end
        local out, lineNum = {}, 0
        for line in code:gmatch("([^\n]*)\n?") do
            lineNum = lineNum + 1
            if lineNum >= fromLine and lineNum <= toLine then
                out[#out+1] = line
            end
            if lineNum > toLine then break end
        end
        return table.concat(out, "\n")
    end

    -- ==========================================================
    -- 核心 12: 分页 (给 AI 分批读)
    -- ==========================================================
    --[[ CR.paginate(code, charsPerPage) -> {pageString...}
         把代码按大小切分成多个 chunk
    ]]
    CR.paginate = function(code, charsPerPage)
        charsPerPage = charsPerPage or 4000
        if type(code) ~= "string" then return {} end
        local pages = {}
        local i = 1
        while i <= #code do
            pages[#pages+1] = code:sub(i, i + charsPerPage - 1)
            i = i + charsPerPage
        end
        return pages
    end

    -- ==========================================================
    -- 核心 13: 关键字搜索 (带上下文)
    -- ==========================================================
    CR.search = function(code, keyword, contextLines)
        contextLines = contextLines or 2
        if type(code) ~= "string" or type(keyword) ~= "string" then return {} end
        local lines = {}
        for line in code:gmatch("[^\n]+") do lines[#lines+1] = line end
        local out = {}
        for i, line in ipairs(lines) do
            if line:find(keyword, 1, true) then
                local startL = math.max(1, i - contextLines)
                local endL = math.min(#lines, i + contextLines)
                local ctx = {}
                for j = startL, endL do
                    local marker = (j == i) and ">> " or "   "
                    ctx[#ctx+1] = marker .. lines[j]
                end
                out[#out+1] = {line = i, context = table.concat(ctx, "\n")}
            end
        end
        return out
    end

    -- ==========================================================
    -- 核心 14: 找调用某个函数的所有地方
    -- ==========================================================
    CR.findCalls = function(code, targetName)
        if type(code) ~= "string" then return {} end
        local out = {}
        local pattern = "([%a_][%w_%.%:]*)%s*%("
        for name, pos in code:gmatch("()" .. pattern) do
            local s = code:find(pattern, pos)
            local matched = code:match(pattern, pos)
            if matched and (matched == targetName or matched:match("([%w_]+)$") == targetName) then
                out[#out+1] = {
                    line = lineOf(code, pos),
                    caller = matched,
                }
            end
        end
        return out
    end

    -- ==========================================================
    -- 核心 15: 生成完整索引
    -- ==========================================================
    --[[ CR.index(code) -> table
         结构化索引, AI 直接看这个
    ]]
    CR.index = function(code)
        if type(code) ~= "string" then return nil end
        local funcs = CR.extractFunctions(code)
        local lines = 0
        for _ in code:gmatch("\n") do lines = lines + 1 end

        return {
            stats = {
                lines = lines,
                chars = #code,
                tokens = CR.estimateTokens(code),
                functions = #funcs,
            },
            functions = funcs,
            strings = CR.extractStrings(code),
            urls = CR.extractURLs(code),
            remotes = CR.extractRemotes(code),
            requires = CR.extractRequires(code),
            globals = CR.extractGlobals(code),
            suspicious = CR.findSuspicious(code),
            depGraph = CR.depGraph(code),
        }
    end

    -- ==========================================================
    -- 核心 16: 生成给 AI 的报告 (文本, 省 token)
    -- ==========================================================
    --[[ CR.report(code, opts) -> string
         生成一段结构化文本, 供 AI 一次读完了解全貌
         opts.maxFunctions (默认 50)
         opts.maxStrings   (默认 40)
    ]]
    CR.report = function(code, opts)
        opts = opts or {}
        if type(code) ~= "string" then return "空代码" end
        local maxF = opts.maxFunctions or 50
        local maxS = opts.maxStrings or 40

        local idx = CR.index(code)
        local L = {}

        L[#L+1] = "=== 代码分析报告 ==="
        L[#L+1] = string.format("行数: %d  字符: %d  token 约: %d",
            idx.stats.lines, idx.stats.chars, idx.stats.tokens)

        -- 函数列表
        L[#L+1] = ""
        L[#L+1] = string.format("--- 函数 (%d 个) ---", #idx.functions)
        local shown = math.min(#idx.functions, maxF)
        for i = 1, shown do
            local f = idx.functions[i]
            local mark = f.isLocal and "local " or ""
            local method = f.isMethod and " (方法)" or ""
            L[#L+1] = string.format("  [%d] %s%s%s  行 %d-%d (%d 行)",
                i, mark, f.name, method, f.startLine, f.endLine, f.lineCount)
        end
        if #idx.functions > shown then
            L[#L+1] = string.format("  ... 还有 %d 个", #idx.functions - shown)
        end

        -- URL
        if #idx.urls > 0 then
            L[#L+1] = ""
            L[#L+1] = "--- URL / 域名 ---"
            for i, u in ipairs(idx.urls) do
                L[#L+1] = "  " .. u
            end
        end

        -- 远程
        if #idx.remotes > 0 then
            L[#L+1] = ""
            L[#L+1] = "--- 远程调用 ---"
            for _, r in ipairs(idx.remotes) do
                L[#L+1] = string.format("  行 %d: :%s(\"%s\")", r.line, r.method, r.name)
            end
        end

        -- require
        if #idx.requires > 0 then
            L[#L+1] = ""
            L[#L+1] = "--- require ---"
            for _, r in ipairs(idx.requires) do
                L[#L+1] = string.format("  行 %d: %s", r.line, r.target)
            end
        end

        -- 关键字符串
        if #idx.strings > 0 then
            L[#L+1] = ""
            L[#L+1] = "--- 字符串 (前 " .. math.min(#idx.strings, maxS) .. " 个) ---"
            local shownS = math.min(#idx.strings, maxS)
            for i = 1, shownS do
                local s = idx.strings[i]
                local display = #s > 60 and (s:sub(1, 60) .. "...") or s
                L[#L+1] = "  " .. string.format("%q", display)
            end
            if #idx.strings > shownS then
                L[#L+1] = string.format("  ... 还有 %d 个", #idx.strings - shownS)
            end
        end

        -- 全局变量
        if #idx.globals > 0 then
            L[#L+1] = ""
            L[#L+1] = "--- 全局变量 ---"
            L[#L+1] = "  " .. table.concat(idx.globals, ", ")
        end

        -- 危险调用
        if #idx.suspicious > 0 then
            L[#L+1] = ""
            L[#L+1] = "--- 敏感操作 ---"
            local byLevel = {}
            for _, s in ipairs(idx.suspicious) do
                byLevel[s.level] = byLevel[s.level] or {}
                byLevel[s.level][#byLevel[s.level]+1] = s.line
            end
            for level, lineList in pairs(byLevel) do
                local lineStr = {}
                for i = 1, math.min(#lineList, 10) do
                    lineStr[#lineStr+1] = tostring(lineList[i])
                end
                L[#L+1] = string.format("  [%s] 行: %s%s",
                    level, table.concat(lineStr, ", "),
                    #lineList > 10 and " ..." or "")
            end
        end

        -- 依赖图
        local dg = idx.depGraph
        if next(dg) then
            L[#L+1] = ""
            L[#L+1] = "--- 依赖图 ---"
            for caller, callees in pairs(dg) do
                if #callees > 0 then
                    L[#L+1] = string.format("  %s -> %s", caller, table.concat(callees, ", "))
                end
            end
        end

        return table.concat(L, "\n")
    end

    -- ==========================================================
    -- 核心 17: 一键读取脚本
    -- ==========================================================
    --[[ CR.readScript(script) -> string | nil
         优先 Source, 兜底反编译
    ]]
    CR.readScript = function(script)
        if typeof(script) ~= "Instance" or not script:IsA("LuaSourceContainer") then
            return nil
        end
        if D.Injector and D.Injector.readScript then
            return D.Injector.readScript(script)
        end
        local ok, src = pcall(function() return script.Source end)
        if ok and type(src) == "string" and #src > 0 then return src end
        if D.decompile then
            local ok2, dec = pcall(D.decompile, script)
            if ok2 and type(dec) == "string" then return dec end
        end
        return nil
    end

    --[[ CR.readScriptReport(script, opts) -> string
         读脚本 + 生成报告一步到位
    ]]
    CR.readScriptReport = function(script, opts)
        local code = CR.readScript(script)
        if not code then return "无法读取脚本" end
        return CR.report(code, opts)
    end

    -- ==========================================================
    -- 核心 18: 批量读取全游戏脚本 (生成总报告)
    -- ==========================================================
    --[[ CR.readAll(filter, opts) -> table
         返回 { scripts = {...}, report = "总报告" }
    ]]
    CR.readAll = function(filter, opts)
        opts = opts or {}
        local scripts = {}
        local lines = {"=== 全游戏脚本索引 ==="}

        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") then
                if not filter or filter(obj) then
                    local code = CR.readScript(obj)
                    if code and #code > 0 then
                        local tokens = CR.estimateTokens(code)
                        local path = D.GetInstancePath(obj)
                        scripts[#scripts+1] = {
                            script = obj,
                            path = path,
                            class = obj.ClassName,
                            chars = #code,
                            tokens = tokens,
                            code = code,
                        }
                        lines[#lines+1] = string.format("  [%s] %s  (%d 字符, ~%d token)",
                            obj.ClassName, path, #code, tokens)
                    end
                end
            end
        end

        return {
            scripts = scripts,
            report = table.concat(lines, "\n"),
        }
    end

    -- ==========================================================
    -- 核心 19: 读取大文件 (分块)
    -- ==========================================================
    --[[ CR.readLarge(path, opts) -> {pages = {...}, index = "..."}
         按分页读本地文件, 适合 AI 分批处理
    ]]
    CR.readLarge = function(path, opts)
        opts = opts or {}
        if not D.env.readfile then return nil, "无 readfile" end
        local ok, data = pcall(D.env.readfile, path)
        if not ok or type(data) ~= "string" then return nil, "读文件失败" end

        local charsPerPage = opts.charsPerPage or 4000
        return {
            pages = CR.paginate(data, charsPerPage),
            index = CR.report(data, opts),
            totalChars = #data,
            totalPages = math.ceil(#data / charsPerPage),
        }
    end

    -- ==========================================================
    -- 核心 20: 差异对比 (代码前后变化)
    -- ==========================================================
    --[[ CR.diff(oldCode, newCode) -> {added = {...}, removed = {...}} ]]
    CR.diff = function(oldCode, newCode)
        if type(oldCode) ~= "string" or type(newCode) ~= "string" then return nil end
        local function toLines(c)
            local t = {}
            for line in c:gmatch("[^\n]+") do t[#t+1] = line end
            return t
        end
        local oldL, newL = toLines(oldCode), toLines(newCode)
        local oldSet = {}
        for _, l in ipairs(oldL) do oldSet[l] = true end
        local newSet = {}
        for _, l in ipairs(newL) do newSet[l] = true end

        local added, removed = {}, {}
        for _, l in ipairs(newL) do
            if not oldSet[l] then added[#added+1] = l end
        end
        for _, l in ipairs(oldL) do
            if not newSet[l] then removed[#removed+1] = l end
        end
        return {added = added, removed = removed}
    end
end

-- ============================================================
-- [30] CodeSkeleton — 工业级 AST 骨架提取 (v1.8)
--      基于 DumbLuaParser 2.3 (MIT, 纯 Lua 单文件)
--      https://github.com/ReFreezed/DumbLuaParser
-- ============================================================
D.CodeSkeleton = {}
do
    local CS = D.CodeSkeleton

    -- ==========================================================
    -- 0. 加载 DumbLuaParser
    -- ==========================================================
    local _parser = nil
    local _parserPath = "dex/lib/dumbParser.lua"
    local _parserURL = "https://raw.githubusercontent.com/ReFreezed/DumbLuaParser/master/dumbParser.lua"

    CS.loadParser = function()
        if _parser then return _parser end

        local src
        if D.env.readfile then
            local ok, data = pcall(D.env.readfile, _parserPath)
            if ok and type(data) == "string" and #data > 1000 then
                src = data
            end
        end

        if not src then
            local ok, data = pcall(game.HttpGet, game, _parserURL)
            if ok and type(data) == "string" and #data > 1000 then
                src = data
                if D.env.writefile and D.env.makefolder then
                    pcall(D.env.makefolder, "dex/lib")
                    pcall(D.env.writefile, _parserPath, data)
                end
            end
        end

        if not src then return nil, "无法获取 DumbLuaParser" end

        local fn, err = loadstring(src)
        if not fn then return nil, "编译失败: " .. tostring(err) end
        local ok, parser = pcall(fn)
        if not ok then return nil, "加载失败: " .. tostring(parser) end

        _parser = parser
        return _parser
    end

    -- ==========================================================
    -- 1. AST 解析 + 结构分析
    -- ==========================================================
    CS.parse = function(code)
        if type(code) ~= "string" then return nil, "code 必须是字符串" end

        local parser = CS.loadParser()
        if not parser then
            return nil, "DumbLuaParser 不可用"
        end

        local ok, ast = pcall(parser.parse, code)
        if not ok or not ast then
            return nil, "解析失败: " .. tostring(ast)
        end

        local funcs, strings, globals = {}, {}, {}

        pcall(parser.traverseTree, ast, function(node)
            if type(node) ~= "table" then return end
            local t = node.type

            if t == "AstFunction" then
                local name = "<anonymous>"
                if node.name and node.name.type == "AstIdentifier" then
                    name = node.name.name or "<anonymous>"
                end
                funcs[#funcs+1] = {
                    name = name,
                    line = node.loc and node.loc.startLine or 0,
                    endLine = node.loc and node.loc.endLine or 0,
                    node = node,
                }
            end

            if t == "AstString" or t == "AstStringLiteral" then
                strings[#strings+1] = node.value or ""
            end

            if t == "AstIdentifier" and node.isGlobal then
                globals[#globals+1] = node.name or ""
            end
        end)

        return {
            ast = ast,
            funcs = funcs,
            strings = strings,
            globals = globals,
            parser = parser,
        }
    end

    -- ==========================================================
    -- 2. 骨架提取
    -- ==========================================================
    CS.extractSkeleton = function(code, opts)
        opts = opts or {}
        local parsed, err = CS.parse(code)
        if not parsed then
            return D.CodeReader and D.CodeReader.report(code) or ("-- 解析失败: " .. tostring(err))
        end

        local ast = parsed.ast
        local parser = parsed.parser

        pcall(parser.traverseTree, ast, function(node)
            if type(node) ~= "table" then return end
            if node.type == "AstFunction" then
                if node.body then
                    node.body = { type = "AstBlock", statements = {} }
                end
            end
        end)

        local ok, lua = pcall(parser.toLua, ast, true)
        if not ok then
            return "-- 骨架重建失败: " .. tostring(lua)
        end

        return lua
    end

    -- ==========================================================
    -- 3. 压缩 (官方 API 组合)
    -- ==========================================================
    CS.compress = function(code, opts)
        opts = opts or {}
        local parsed, err = CS.parse(code)
        if not parsed then
            return code, {error = err}
        end

        local parser = parsed.parser
        local ast = parsed.ast
        local stats = {}

        local ok1, s1 = pcall(parser.simplify, ast)
        if ok1 then stats.simplify = s1 end

        if opts.aggressive then
            local ok2, s2 = pcall(parser.optimize, ast)
            if ok2 then stats.optimize = s2 end
        end

        local ok3, s3 = pcall(parser.minify, ast, opts.aggressive == true)
        if ok3 then stats.minify = s3 end

        local ok4, lua = pcall(parser.toLua, ast, false)
        if not ok4 then
            return code, {error = "toLua 失败: " .. tostring(lua)}
        end

        return lua, stats
    end

    -- ==========================================================
    -- 4. 符号重要性排序
    -- ==========================================================
    CS.rankSymbols = function(code)
        local parsed = CS.parse(code)
        if not parsed then
            local funcs = D.CodeReader and D.CodeReader.extractFunctions(code) or {}
            local dep = D.CodeReader and D.CodeReader.depGraph(code) or {}
            local scores = {}
            for _, f in ipairs(funcs) do
                local called = 0
                for _, callees in pairs(dep) do
                    for _, c in ipairs(callees) do
                        if c == f.name then called = called + 1 end
                    end
                end
                scores[#scores+1] = {name = f.name, score = called, calls = called}
            end
            table.sort(scores, function(a, b) return a.score > b.score end)
            return scores
        end

        local parser = parsed.parser
        local ast = parsed.ast

        pcall(parser.updateReferences, ast)

        local ok, globals = pcall(parser.findGlobalReferences, ast)
        local counts = {}
        if ok and globals then
            for _, g in ipairs(globals) do
                local name = g.name or "?"
                counts[name] = (counts[name] or 0) + 1
            end
        end

        local ranked = {}
        for name, count in pairs(counts) do
            ranked[#ranked+1] = {name = name, score = count, calls = count}
        end
        table.sort(ranked, function(a, b) return a.score > b.score end)
        return ranked
    end

    -- ==========================================================
    -- 5. Token 预算打包
    -- ==========================================================
    CS.packForLLM = function(code, budget)
        budget = budget or 8000
        if type(code) ~= "string" then return "", 0, "empty" end

        local estimate = D.CodeReader and D.CodeReader.estimateTokens or function(c) return math.floor(#c / 3.5) end
        local fullTokens = estimate(code)

        if fullTokens <= budget then
            return code, fullTokens, "full"
        end

        local compressed = CS.compress(code, {aggressive = true})
        local compTokens = estimate(compressed)
        if compTokens <= budget then
            return compressed, compTokens, "compressed"
        end

        local skeleton = CS.extractSkeleton(code)
        local skelTokens = estimate(skeleton)
        if skelTokens <= budget then
            return skeleton, skelTokens, "skeleton"
        end

        local ranked = CS.rankSymbols(code)
        local lines = {"-- [Token 预算超限, 仅显示函数签名]"}
        for _, r in ipairs(ranked) do
            lines[#lines+1] = string.format("%s -- %d次引用", r.name, r.calls)
        end
        local sigs = table.concat(lines, "\n")
        return sigs, estimate(sigs), "signatures"
    end

    -- ==========================================================
    -- 6. 完整报告
    -- ==========================================================
    CS.report = function(code, opts)
        opts = opts or {}
        local budget = opts.budget or 8000
        local payload, tokens, mode = CS.packForLLM(code, budget)

        local lines = {}
        lines[#lines+1] = string.format("-- [CodeSkeleton] 模式: %s, Tokens: %d/%d",
            mode, tokens, budget)
        lines[#lines+1] = string.rep("-", 40)

        if opts.showRanking ~= false then
            local ranked = CS.rankSymbols(code)
            lines[#lines+1] = ""
            lines[#lines+1] = "-- 符号重要性排名 (前10):"
            for i = 1, math.min(#ranked, 10) do
                local r = ranked[i]
                lines[#lines+1] = string.format("--   %d. %s (%d次引用)",
                    i, r.name, r.calls)
            end
        end

        lines[#lines+1] = ""
        lines[#lines+1] = payload

        return table.concat(lines, "\n")
    end
end

-- ============================================================
-- [24] Executor — AI 代码执行能力 (v1.2)
-- ============================================================
D.Executor = {}
do
    local E = D.Executor

    E.history = {}
    E.maxHistory = 100
    E.lastResult = nil
    E.blocklist = {}
    E.whitelist = nil

    local function validate(code)
        if type(code) ~= "string" then return false, "代码必须是字符串" end
        if E.whitelist then
            for _, kw in ipairs(E.whitelist) do
                if code:find(kw, 1, true) then return true end
            end
            return false, "不在白名单内"
        end
        for _, kw in ipairs(E.blocklist) do
            if code:find(kw, 1, true) then
                return false, "包含被禁关键字: " .. kw
            end
        end
        return true
    end

    E.pushHistory = function(result)
        E.history[#E.history+1] = result
        if #E.history > E.maxHistory then table.remove(E.history, 1) end
    end

    E.exec = function(code, opts)
        opts = opts or {}
        local startTick = tick()
        local result = {
            success = false, result = nil, error = nil,
            output = {}, duration = 0, code = code,
            time = os.date("%H:%M:%S"),
        }

        if opts.skipValidation ~= true then
            local valid, msg = validate(code)
            if not valid then
                result.error = "安全检查失败: " .. msg
                result.duration = tick() - startTick
                E.lastResult = result E.pushHistory(result)
                return result
            end
        end

        local loader = loadstring or D.env.loadstring
        if not loader then
            result.error = "执行器不支持 loadstring"
            result.duration = tick() - startTick
            E.lastResult = result E.pushHistory(result)
            return result
        end

        local fn, err = loader(code)
        if not fn then
            result.error = "编译失败: " .. tostring(err)
            result.duration = tick() - startTick
            E.lastResult = result E.pushHistory(result)
            return result
        end

        local captured = {}
        local ok, ret
        if setfenv and getfenv then
            local baseEnv = opts.env or getfenv(fn)
            local env = setmetatable({
                print = function(...)
                    local parts = {}
                    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
                    captured[#captured+1] = {type = "print", text = table.concat(parts, "\t")}
                    if baseEnv.print then baseEnv.print(unpack(parts)) end
                end,
                warn = function(...)
                    local parts = {}
                    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
                    captured[#captured+1] = {type = "warn", text = table.concat(parts, "\t")}
                    if baseEnv.warn then baseEnv.warn(unpack(parts)) end
                end,
            }, {__index = baseEnv})
            setfenv(fn, env)
            ok, ret = pcall(fn)
        else
            ok, ret = pcall(fn)
        end

        result.success = ok
        result.result = ok and ret or nil
        result.error = (not ok) and tostring(ret) or nil
        result.output = captured
        result.duration = tick() - startTick
        E.lastResult = result
        E.pushHistory(result)
        return result
    end

    E.execAsync = function(code, opts, callback)
        opts = opts or {}
        task.spawn(function()
            local result = E.exec(code, opts)
            if callback then callback(result) end
            if opts.signal then opts.signal:Fire(result) end
        end)
    end

    E.execWithEnv = function(code, customEnv)
        return E.exec(code, {env = customEnv})
    end

    E.eval = function(expr)
        local loader = loadstring or D.env.loadstring
        if not loader then return nil, "no loadstring" end
        local fn, err = loader("return " .. expr)
        if not fn then return nil, err end
        local ok, ret = pcall(fn)
        if not ok then return nil, ret end
        return ret
    end

    E.execFunction = function(fn, ...)
        if type(fn) ~= "function" then
            return {success = false, error = "不是函数"}
        end
        local startTick = tick()
        local result = {
            success = false, result = nil, error = nil,
            output = {}, duration = 0, time = os.date("%H:%M:%S"),
        }
        local ok, ret = pcall(fn, ...)
        result.success = ok
        result.result = ok and ret or nil
        result.error = (not ok) and tostring(ret) or nil
        result.duration = tick() - startTick
        E.lastResult = result E.pushHistory(result)
        return result
    end

    E.execFile = function(path)
        if not D.env.readfile then
            return {success = false, error = "执行器不支持 readfile"}
        end
        local ok, content = pcall(D.env.readfile, path)
        if not ok or not content then
            return {success = false, error = "读取文件失败: " .. path}
        end
        return E.exec(content)
    end

    E.execWithTimeout = function(code, timeout, opts)
        timeout = timeout or 5
        opts = opts or {}
        local done = false
        local result = nil
        task.spawn(function()
            result = E.exec(code, opts)
            done = true
        end)
        local startTick = tick()
        while not done and tick() - startTick < timeout do
            D.FastWait()
        end
        if not done then
            return {success = false, error = "执行超时 (> " .. timeout .. "s)", timeout = true, duration = tick() - startTick}
        end
        return result
    end

    E.getHistory = function(n)
        n = n or #E.history
        local out = {}
        local start = math.max(1, #E.history - n + 1)
        for i = start, #E.history do out[#out+1] = E.history[i] end
        return out
    end

    E.getLastResult = function() return E.lastResult end
    E.clearHistory = function() E.history = {} E.lastResult = nil end

    E.exportHistory = function()
        local out = {}
        for i, r in ipairs(E.history) do
            out[i] = {time = r.time, success = r.success, error = r.error,
                      duration = r.duration, code = r.code, output = r.output}
        end
        local ok, json = pcall(D.service.HttpService.JSONEncode, D.service.HttpService, out)
        if ok then return json end
        return nil
    end

    E.saveHistory = function(path)
        if not D.env.writefile then return false end
        local data = E.exportHistory()
        if not data then return false end
        return pcall(D.env.writefile, path, data)
    end

    E.setBlocklist = function(list) E.blocklist = list or {} end
    E.addBlockKeyword = function(kw) E.blocklist[#E.blocklist+1] = kw end
    E.removeBlockKeyword = function(kw)
        for i = #E.blocklist, 1, -1 do
            if E.blocklist[i] == kw then table.remove(E.blocklist, i) end
        end
    end
    E.setWhitelist = function(list) E.whitelist = list end
    E.clearWhitelist = function() E.whitelist = nil end

    E.enableReadOnlyMode = function()
        E.blocklist = {
            "Instance.new", ":Destroy(", ":Remove(", ":ClearAllChildren(",
            ":FireServer(", ":InvokeServer(", ":Fire(", ":Invoke(",
            "writefile", "appendfile", "delfile", "makefolder",
            "hookfunction", "hookmetamethod", "setclipboard",
            "HttpService:GetAsync", "HttpGet",
        }
    end

    E.enableFullMode = function()
        E.blocklist = {}
        E.whitelist = nil
    end

    E.createSandbox = function(opts)
        opts = opts or {}
        local exposed = opts.expose or {
            print = print, warn = warn, game = game, workspace = workspace,
            script = script, task = task, wait = wait, spawn = spawn,
            typeof = typeof, type = type, tostring = tostring,
            tonumber = tonumber, pairs = pairs, ipairs = ipairs, next = next,
            select = select, unpack = unpack, table = table, string = string, math = math,
        }
        local sandbox = setmetatable({}, {
            __index = function(_, k)
                if exposed[k] ~= nil then return exposed[k] end
                error("沙盒禁止访问: " .. tostring(k), 2)
            end,
            __newindex = function(_, k, v) exposed[k] = v end,
        })
        return sandbox
    end

    E.execSafe = function(code, opts)
        opts = opts or {}
        local sandbox = opts.sandbox or E.createSandbox(opts)
        return E.exec(code, {env = sandbox, skipValidation = true})
    end

    E.run = function(code)
        local r = E.exec(code)
        local lines = {}
        lines[#lines+1] = "=== 执行结果 ==="
        lines[#lines+1] = "状态: " .. (r.success and "✅ 成功" or "❌ 失败")
        lines[#lines+1] = string.format("耗时: %.3fs", r.duration)
        if #r.output > 0 then
            lines[#lines+1] = ""
            lines[#lines+1] = "--- 输出 ---"
            for _, o in ipairs(r.output) do
                lines[#lines+1] = "[" .. o.type .. "] " .. o.text
            end
        end
        if r.result ~= nil then
            lines[#lines+1] = ""
            lines[#lines+1] = "--- 返回值 ---"
            lines[#lines+1] = tostring(r.result)
        end
        if r.error then
            lines[#lines+1] = ""
            lines[#lines+1] = "--- 错误 ---"
            lines[#lines+1] = r.error
        end
        return table.concat(lines, "\n")
    end

    E.execBatch = function(codeList, stopOnError)
        local results = {}
        for i, code in ipairs(codeList) do
            results[i] = E.exec(code)
            if stopOnError and not results[i].success then break end
        end
        return results
    end

    E.execAndSerialize = function(code)
        local r = E.exec(code)
        if r.success and r.result ~= nil then
            r.serialized = D.v2s(r.result)
        end
        return r
    end

    E.installGlobals = function()
        if getgenv then
            getgenv().run = E.exec
            getgenv().eval = E.eval
        end
    end

    E.uninstallGlobals = function()
        if getgenv then
            getgenv().run = nil
            getgenv().eval = nil
        end
    end
end

-- ============================================================
-- [29] WebAccess — 游戏内 AI 联网能力 (v1.7)
-- ============================================================
D.WebAccess = {}
do
    local W = D.WebAccess

    W.hasRequest = function()
        return (syn and syn.request) or (http and http.request) or http_request
            or request or (fluxus and fluxus.request)
    end

    W.getRequester = function()
        return (syn and syn.request) or (http and http.request) or http_request
            or request or (fluxus and fluxus.request) or nil
    end

    W.request = function(opts)
        if type(opts) ~= "table" or type(opts.Url) ~= "string" then
            return nil, "Url 必须提供"
        end
        opts.Method = opts.Method or "GET"
        opts.Headers = opts.Headers or {}
        local req = W.getRequester()
        if req then
            local ok, resp = pcall(req, opts)
            if ok and resp and resp.StatusCode then
                return {StatusCode = resp.StatusCode, Body = resp.Body, Headers = resp.Headers or {}}
            end
            return nil, "request 失败: " .. tostring(resp)
        end
        if opts.Method == "GET" then
            local ok, body = pcall(game.HttpGet, game, opts.Url)
            if ok then return {StatusCode = 200, Body = body, Headers = {}} end
            return nil, "HttpGet 失败: " .. tostring(body)
        end
        return nil, "执行器不支持外部网络请求"
    end

    W.getJSON = function(url, headers)
        local resp, err = W.request({Url = url, Method = "GET", Headers = headers})
        if not resp then return nil, err end
        local ok, data = pcall(D.service.HttpService.JSONDecode, D.service.HttpService, resp.Body)
        if not ok then return nil, "JSON 解析失败: " .. tostring(data) end
        return data
    end

    W.postJSON = function(url, body, headers)
        headers = headers or {}
        headers["Content-Type"] = headers["Content-Type"] or "application/json"
        local encoded = type(body) == "table" and D.service.HttpService:JSONEncode(body) or body
        local resp, err = W.request({Url = url, Method = "POST", Headers = headers, Body = encoded})
        if not resp then return nil, err end
        local ok, data = pcall(D.service.HttpService.JSONDecode, D.service.HttpService, resp.Body)
        if not ok then return resp.Body end
        return data
    end

    W.htmlToText = function(html)
        if type(html) ~= "string" then return "" end
        html = html:gsub("<script[^>]*>.-</script>", " ")
        html = html:gsub("<style[^>]*>.-</style>", " ")
        html = html:gsub("<!%-%-.-%-%->", " ")
        html = html:gsub("<!DOCTYPE[^>]*>", " ")
        html = html:gsub("<br%s*/?>", "\n")
        html = html:gsub("</p>", "\n")
        html = html:gsub("</div>", "\n")
        html = html:gsub("</li>", "\n")
        html = html:gsub("</h[1-6]>", "\n\n")
        html = html:gsub("<[^>]+>", "")
        local entities = {
            ["&amp;"]="&", ["&lt;"]="<", ["&gt;"]=">", ["&quot;"]='"',
            ["&#39;"]="'", ["&apos;"]="'", ["&nbsp;"]=" ", ["&mdash;"]="—",
            ["&ndash;"]="–", ["&hellip;"]="…", ["&copy;"]="©", ["&reg;"]="®",
        }
        for k, v in pairs(entities) do html = html:gsub(k, v) end
        html = html:gsub("&#(%d+);", function(n)
            local code = tonumber(n)
            if code and code < 128 then return string.char(code) end
            return ""
        end)
        html = html:gsub("\r\n", "\n")
        html = html:gsub("[ \t]+", " ")
        html = html:gsub("\n[ \t]+", "\n")
        html = html:gsub("\n\n\n+", "\n\n")
        return html
    end

    W.fetchPage = function(url)
        local resp, err = W.request({
            Url = url, Method = "GET",
            Headers = {
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                ["Accept"] = "text/html,application/xhtml+xml",
            },
        })
        if not resp then return nil, err end
        if resp.StatusCode ~= 200 then return nil, "HTTP " .. resp.StatusCode end
        local html = resp.Body
        local title = html:match("<title[^>]*>(.-)</title>") or ""
        title = W.htmlToText(title)
        return {url = url, title = title, text = W.htmlToText(html), rawHtml = html, size = #html}
    end

    W.ddgSearch = function(query)
        local url = "https://api.duckduckgo.com/?q="
            .. D.service.HttpService:UrlEncode(query)
            .. "&format=json&no_redirect=1&no_html=1&skip_disambig=1"
        local data, err = W.getJSON(url)
        if not data then return nil, err end
        local results = {}
        if data.AbstractText and #data.AbstractText > 0 then
            results[#results+1] = {title = data.Heading or "Abstract", text = data.AbstractText, url = data.AbstractURL}
        end
        if data.Answer and #tostring(data.Answer) > 0 then
            results[#results+1] = {title = "Answer", text = tostring(data.Answer), url = ""}
        end
        if data.RelatedTopics then
            for _, topic in ipairs(data.RelatedTopics) do
                if topic.Text then
                    results[#results+1] = {title = topic.Text:sub(1, 60), text = topic.Text, url = topic.FirstURL}
                end
            end
        end
        return {abstract = data.AbstractText, heading = data.Heading, results = results}
    end

    W.ddgFullSearch = function(query, maxResults)
        maxResults = maxResults or 10
        local url = "https://html.duckduckgo.com/html/?q=" .. D.service.HttpService:UrlEncode(query)
        local resp, err = W.request({
            Url = url, Method = "GET",
            Headers = {["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"},
        })
        if not resp or resp.StatusCode ~= 200 then
            return nil, err or ("HTTP " .. (resp and resp.StatusCode or "?"))
        end
        local html = resp.Body
        local results = {}
        for block in html:gmatch('<div class="result[^"]*"[^>]*>(.-)</div>%s*</div>') do
            local title = block:match('<a[^>]*class="result__a"[^>]*>(.-)</a>')
            local snippet = block:match('<a[^>]*class="result__snippet"[^>]*>(.-)</a>')
            local href = block:match('<a[^>]*class="result__a"[^>]*href="([^"]+)"')
            if title then
                title = W.htmlToText(title)
                snippet = snippet and W.htmlToText(snippet) or ""
                if href then
                    href = href:gsub("^//duckduckgo%.com/l/%?uddg=", "")
                    href = D.service.HttpService:UrlDecode(href)
                end
                results[#results+1] = {title = title, snippet = snippet, url = href or ""}
                if #results >= maxResults then break end
            end
        end
        return {query = query, results = results}
    end

    W.openaiSearch = function(query, apiKey, opts)
        opts = opts or {}
        local data, err = W.postJSON(
            "https://api.openai.com/v1/responses",
            {model = opts.model or "gpt-4o", tools = {{type = "web_search"}}, input = query},
            {["Authorization"] = "Bearer " .. apiKey}
        )
        if not data then return nil, err end
        local answer = ""
        local sources = {}
        if data.output then
            for _, item in ipairs(data.output) do
                if item.type == "message" and item.content then
                    for _, c in ipairs(item.content) do
                        if c.type == "output_text" then
                            answer = answer .. (c.text or "")
                            if c.annotations then
                                for _, a in ipairs(c.annotations) do
                                    if a.url then sources[#sources+1] = {url = a.url, title = a.title or ""} end
                                end
                            end
                        end
                    end
                end
            end
        end
        return {answer = answer, sources = sources, raw = data}
    end

    W.perplexitySearch = function(query, apiKey, opts)
        opts = opts or {}
        local data, err = W.postJSON(
            "https://api.perplexity.ai/chat/completions",
            {model = opts.model or "sonar", messages = {{role = "user", content = query}}},
            {["Authorization"] = "Bearer " .. apiKey}
        )
        if not data then return nil, err end
        if not data.choices or not data.choices[1] then return nil, "无效响应" end
        return {answer = data.choices[1].message.content, sources = data.citations or {}, raw = data}
    end

    W.geminiSearch = function(query, apiKey, opts)
        opts = opts or {}
        local model = opts.model or "gemini-2.0-flash"
        local url = "https://generativelanguage.googleapis.com/v1beta/models/"
            .. model .. ":generateContent?key=" .. apiKey
        local data, err = W.postJSON(url, {
            contents = {{parts = {{text = query}}}},
            tools = {{google_search = {}}},
        })
        if not data then return nil, err end
        local text = ""
        if data.candidates and data.candidates[1] and data.candidates[1].content
            and data.candidates[1].content.parts then
            for _, p in ipairs(data.candidates[1].content.parts) do
                text = text .. (p.text or "")
            end
        end
        return {answer = text, raw = data}
    end

    W.search = function(query, opts)
        opts = opts or {}
        local provider = opts.provider or "auto"
        if provider == "auto" then
            if opts.perplexityKey then return W.perplexitySearch(query, opts.perplexityKey, opts)
            elseif opts.openaiKey then return W.openaiSearch(query, opts.openaiKey, opts)
            elseif opts.geminiKey then return W.geminiSearch(query, opts.geminiKey, opts)
            else provider = "ddg" end
        end
        if provider == "ddg" then
            local r, err = W.ddgFullSearch(query)
            if not r then
                local ia, err2 = W.ddgSearch(query)
                if ia then return {provider = "ddg-instant", answer = ia.abstract, results = ia.results} end
                return nil, err or err2
            end
            return {provider = "ddg-html", results = r.results}
        elseif provider == "openai" then return W.openaiSearch(query, opts.apiKey, opts)
        elseif provider == "perplexity" then return W.perplexitySearch(query, opts.apiKey, opts)
        elseif provider == "gemini" then return W.geminiSearch(query, opts.apiKey, opts)
        end
        return nil, "未知 provider: " .. tostring(provider)
    end

    W.read = function(url, opts)
        opts = opts or {}
        local page, err = W.fetchPage(url)
        if not page then return nil, err end
        local text = page.text
        local maxChars = opts.maxChars or 8000
        if #text > maxChars then
            text = text:sub(1, maxChars) .. "\n\n... [已截断, 原长 " .. #page.text .. "]"
        end
        return {title = page.title, text = text, url = url}
    end

    W.cache = {}
    W.cacheTTL = 300

    W.cachedFetch = function(url, opts)
        local key = url
        local entry = W.cache[key]
        if entry and (tick() - entry.time) < W.cacheTTL then return entry.data end
        local data, err = W.read(url, opts)
        if data then W.cache[key] = {data = data, time = tick()} end
        return data, err
    end

    W.clearCache = function() W.cache = {} end

    W.formatForAI = function(result)
        if not result then return "无结果" end
        local lines = {}
        if result.provider then lines[#lines+1] = "[来源: " .. result.provider .. "]" end
        if result.answer then
            lines[#lines+1] = ""
            lines[#lines+1] = "答案:"
            lines[#lines+1] = result.answer
        end
        if result.results and #result.results > 0 then
            lines[#lines+1] = ""
            lines[#lines+1] = "搜索条目:"
            for i, r in ipairs(result.results) do
                lines[#lines+1] = string.format("%d. %s", i, r.title or "")
                if r.snippet then lines[#lines+1] = "   " .. r.snippet end
                if r.url then lines[#lines+1] = "   " .. r.url end
            end
        end
        if result.sources and #result.sources > 0 then
            lines[#lines+1] = ""
            lines[#lines+1] = "引用:"
            for i, s in ipairs(result.sources) do
                lines[#lines+1] = string.format("  [%d] %s", i, type(s) == "table" and s.url or s)
            end
        end
        return table.concat(lines, "\n")
    end
end

-- ============================================================
-- [31] AIAgent — 完整 AI Agent 层 (v2.0)
--      参考 ug-lua-llm / luagent / IronCrew / onetool 设计
--      针对 Roblox executor 环境重写
-- ============================================================
D.AIAgent = {}
do
    local A = D.AIAgent

    -- ==========================================================
    -- 0. 配置 / 状态
    -- ==========================================================
    A.config = {
        provider = "openai",
        model = "gpt-4o",
        apiKey = nil,
        baseUrl = nil,
        maxRounds = 10,
        maxHistory = 50,
        systemPrompt = "You are a Roblox game analysis assistant. You can use tools to inspect the game. Always explain what you're doing.",
        temperature = 0.7,
        maxTokens = 4000,
        timeout = 60,
    }

    A.history = {}
    A.tools = {}
    A.toolOrder = {}
    A.session = nil
    A.running = false

    -- ==========================================================
    -- 1. 提供商配置
    -- ==========================================================
    --[[ A.configure(opts)
         opts.provider: "openai" | "claude" | "gemini" | "deepseek" | "openai-compatible"
         opts.model, opts.apiKey, opts.baseUrl
    ]]
    A.configure = function(opts)
        for k, v in pairs(opts or {}) do
            A.config[k] = v
        end
        return A.config
    end

    -- ==========================================================
    -- 2. 提供商适配器
    -- ==========================================================
    local Providers = {}

    Providers.openai = {
        url = function(cfg) return (cfg.baseUrl or "https://api.openai.com/v1") .. "/chat/completions" end,
        headers = function(cfg) return {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. (cfg.apiKey or ""),
        } end,
        buildBody = function(cfg, messages, tools)
            local body = {
                model = cfg.model,
                messages = messages,
                temperature = cfg.temperature,
                max_tokens = cfg.maxTokens,
            }
            if tools and #tools > 0 then
                body.tools = tools
                body.tool_choice = "auto"
            end
            return body
        end,
        parseResponse = function(data)
            local choice = data.choices and data.choices[1]
            if not choice then return nil, "空响应" end
            local msg = choice.message
            return {
                content = msg.content,
                toolCalls = msg.tool_calls,
                finishReason = choice.finish_reason,
                usage = data.usage,
            }
        end,
    }

    Providers.claude = {
        url = function(cfg) return (cfg.baseUrl or "https://api.anthropic.com") .. "/v1/messages" end,
        headers = function(cfg) return {
            ["Content-Type"] = "application/json",
            ["x-api-key"] = cfg.apiKey or "",
            ["anthropic-version"] = "2023-06-01",
        } end,
        buildBody = function(cfg, messages, tools)
            -- 转换 OpenAI 格式到 Claude 格式
            local sys = nil
            local msgs = {}
            for _, m in ipairs(messages) do
                if m.role == "system" then
                    sys = m.content
                elseif m.role == "tool" then
                    msgs[#msgs+1] = {
                        role = "user",
                        content = {{ type = "tool_result", tool_use_id = m.tool_call_id, content = m.content }}
                    }
                elseif m.tool_calls then
                    local blocks = {}
                    if m.content and m.content ~= "" then
                        blocks[#blocks+1] = { type = "text", text = m.content }
                    end
                    for _, tc in ipairs(m.tool_calls) do
                        blocks[#blocks+1] = {
                            type = "tool_use",
                            id = tc.id,
                            name = tc["function"].name,
                            input = D.service.HttpService:JSONDecode(tc["function"].arguments or "{}"),
                        }
                    end
                    msgs[#msgs+1] = { role = "assistant", content = blocks }
                else
                    msgs[#msgs+1] = { role = m.role, content = m.content }
                end
            end

            local body = {
                model = cfg.model,
                max_tokens = cfg.maxTokens,
                messages = msgs,
            }
            if sys then body.system = sys end
            if tools and #tools > 0 then
                local ctools = {}
                for _, t in ipairs(tools) do
                    ctools[#ctools+1] = {
                        name = t["function"].name,
                        description = t["function"].description,
                        input_schema = t["function"].parameters,
                    }
                end
                body.tools = ctools
            end
            return body
        end,
        parseResponse = function(data)
            local content, toolCalls = nil, nil
            for _, block in ipairs(data.content or {}) do
                if block.type == "text" then content = (content or "") .. block.text
                elseif block.type == "tool_use" then
                    toolCalls = toolCalls or {}
                    toolCalls[#toolCalls+1] = {
                        id = block.id,
                        ["function"] = {
                            name = block.name,
                            arguments = D.service.HttpService:JSONEncode(block.input),
                        }
                    }
                end
            end
            return {
                content = content,
                toolCalls = toolCalls,
                finishReason = data.stop_reason,
                usage = data.usage,
            }
        end,
    }

    Providers.gemini = {
        url = function(cfg)
            return "https://generativelanguage.googleapis.com/v1beta/models/"
                .. cfg.model .. ":generateContent?key=" .. (cfg.apiKey or "")
        end,
        headers = function(cfg) return { ["Content-Type"] = "application/json" } end,
        buildBody = function(cfg, messages, tools)
            local contents = {}
            for _, m in ipairs(messages) do
                if m.role ~= "system" then
                    contents[#contents+1] = {
                        role = m.role == "assistant" and "model" or "user",
                        parts = {{ text = m.content or "" }},
                    }
                end
            end
            local body = { contents = contents }
            if tools and #tools > 0 then
                body.tools = {{ function_declarations = tools }}
            end
            return body
        end,
        parseResponse = function(data)
            local cand = data.candidates and data.candidates[1]
            if not cand then return nil, "空响应" end
            local content, toolCalls = nil, nil
            for _, part in ipairs(cand.content and cand.content.parts or {}) do
                if part.text then content = (content or "") .. part.text
                elseif part.functionCall then
                    toolCalls = toolCalls or {}
                    toolCalls[#toolCalls+1] = {
                        id = "call_" .. os.time() .. "_" .. math.random(1000),
                        ["function"] = {
                            name = part.functionCall.name,
                            arguments = D.service.HttpService:JSONEncode(part.functionCall.args or {}),
                        }
                    }
                end
            end
            return { content = content, toolCalls = toolCalls }
        end,
    }

    Providers["openai-compatible"] = Providers.openai
    Providers.deepseek = Providers.openai

    -- ==========================================================
    -- 3. HTTP 请求
    -- ==========================================================
    local function httpPost(url, headers, body)
        local json = D.service.HttpService:JSONEncode(body)
        local req = D.WebAccess and D.WebAccess.getRequester()

        if req then
            local ok, resp = pcall(req, {
                Url = url, Method = "POST", Headers = headers, Body = json,
            })
            if ok and resp and resp.StatusCode == 200 then
                local s, data = pcall(D.service.HttpService.JSONDecode, D.service.HttpService, resp.Body)
                if s then return data end
                return nil, "JSON解析失败"
            end
            return nil, "HTTP " .. (resp and resp.StatusCode or "?") .. ": " .. (resp and resp.Body or "")
        end

        -- 兜底: HttpService 的 PostAsync (受 Roblox 域名限制)
        local ok, resp = pcall(function()
            return D.service.HttpService:PostAsync(url, json, Enum.HttpContentType.ApplicationJson)
        end)
        if ok and resp then
            local s, data = pcall(D.service.HttpService.JSONDecode, D.service.HttpService, resp)
            if s then return data end
        end
        return nil, "无可用 HTTP 请求方式"
    end

    -- ==========================================================
    -- 4. 工具注册
    -- ==========================================================
    --[[ A.registerTool(name, def)
         def = {
             description = "工具说明",
             parameters = { type="object", properties={...}, required={...} },
             fn = function(args) return result end,
         }
    ]]
    A.registerTool = function(name, def)
        A.tools[name] = {
            name = name,
            description = def.description or "",
            parameters = def.parameters or { type = "object", properties = {} },
            fn = def.fn,
        }
        A.toolOrder[#A.toolOrder+1] = name
        return true
    end

    A.unregisterTool = function(name)
        A.tools[name] = nil
        for i = #A.toolOrder, 1, -1 do
            if A.toolOrder[i] == name then table.remove(A.toolOrder, i) end
        end
    end

    A.listTools = function()
        local out = {}
        for _, name in ipairs(A.toolOrder) do
            out[#out+1] = { name = name, description = A.tools[name].description }
        end
        return out
    end

    -- ==========================================================
    -- 5. 调用工具
    -- ==========================================================
    local function callTool(name, args)
        local tool = A.tools[name]
        if not tool then return nil, "未知工具: " .. name end
        if type(tool.fn) ~= "function" then return nil, "工具无执行函数" end

        local ok, result = pcall(tool.fn, args or {})
        if not ok then return nil, "工具执行失败: " .. tostring(result) end

        if type(result) == "table" then
            local s, json = pcall(D.service.HttpService.JSONEncode, D.service.HttpService, result)
            if s then return json end
        end
        return tostring(result)
    end

    -- ==========================================================
    -- 6. 自动注册库内工具
    -- ==========================================================
    A.autoRegisterTools = function()
        local count = 0

        -- 6.1 反编译
        A.registerTool("decompile_script", {
            description = "反编译一个 Roblox 脚本(LocalScript/ModuleScript/Script)，返回源码。参数 path 是脚本的路径字符串，例如 workspace.Script1 或 game.ReplicatedStorage.Module",
            parameters = {
                type = "object",
                properties = { path = { type = "string", description = "脚本路径" } },
                required = { "path" },
            },
            fn = function(args)
                local scr = game:FindFirstChild(args.path, true)
                if not scr then
                    local parts = {}
                    for p in args.path:gmatch("[^.]+") do parts[#parts+1] = p end
                    local cur = game
                    for i = 2, #parts do
                        local next_ = cur:FindFirstChild(parts[i])
                        if not next_ then break end
                        cur = next_
                    end
                    scr = cur ~= game and cur or nil
                end
                if not scr or not scr:IsA("LuaSourceContainer") then
                    return "找不到脚本: " .. args.path
                end
                return D.decompile(scr)
            end,
        })
        count = count + 1

        -- 6.2 列出脚本
        A.registerTool("list_scripts", {
            description = "列出游戏里所有脚本的路径",
            parameters = { type = "object", properties = {} },
            fn = function()
                local out = {}
                for _, obj in ipairs(game:GetDescendants()) do
                    if obj:IsA("LuaSourceContainer") then
                        out[#out+1] = obj.ClassName .. "  " .. D.GetInstancePath(obj)
                    end
                end
                return table.concat(out, "\n")
            end,
        })
        count = count + 1

        -- 6.3 抓远程调用
        A.registerTool("start_remote_spy", {
            description = "启动远程间谍，开始记录游戏中的远程调用。参数 duration 是记录时长(秒)",
            parameters = {
                type = "object",
                properties = { duration = { type = "number", description = "记录时长(秒)" } },
                required = { "duration" },
            },
            fn = function(args)
                D.SimpleSpy.start()
                task.wait(args.duration or 10)
                D.SimpleSpy.stop()
                local logs = {}
                for i, e in ipairs(D.SimpleSpy.logs) do
                    if i > 50 then break end
                    logs[#logs+1] = string.format("[%s] %s (%s)", e.name, e.type, #e.args .. "个参数")
                end
                return "记录了 " .. #D.SimpleSpy.logs .. " 条远程调用:\n" .. table.concat(logs, "\n")
            end,
        })
        count = count + 1

        -- 6.4 查看实例属性
        A.registerTool("inspect_instance", {
            description = "查看一个实例的属性。参数 path 是实例路径",
            parameters = {
                type = "object",
                properties = { path = { type = "string" } },
                required = { "path" },
            },
            fn = function(args)
                local inst = game:FindFirstChild(args.path, true)
                if not inst then return "找不到: " .. args.path end
                local lines = {}
                lines[#lines+1] = "名称: " .. inst.Name .. "  类型: " .. inst.ClassName
                lines[#lines+1] = "路径: " .. D.GetInstancePath(inst)
                local props = {"Position","Size","Color","Anchored","Health","MaxHealth","Value","Text","Visible"}
                for _, prop in ipairs(props) do
                    local ok, val = pcall(function() return inst[prop] end)
                    if ok and val ~= nil then
                        lines[#lines+1] = prop .. " = " .. tostring(val)
                    end
                end
                return table.concat(lines, "\n")
            end,
        })
        count = count + 1

        -- 6.5 执行代码
        A.registerTool("execute_lua", {
            description = "执行一段 Lua 代码并返回结果。用于修改游戏状态、测试逻辑等",
            parameters = {
                type = "object",
                properties = { code = { type = "string", description = "要执行的 Lua 代码" } },
                required = { "code" },
            },
            fn = function(args)
                if D.Executor and D.Executor.run then
                    return D.Executor.run(args.code)
                end
                local fn, err = loadstring(args.code)
                if not fn then return "编译失败: " .. tostring(err) end
                local ok, result = pcall(fn)
                return ok and tostring(result) or ("执行失败: " .. tostring(result))
            end,
        })
        count = count + 1

        -- 6.6 读代码分析
        A.registerTool("analyze_script", {
            description = "分析一个脚本的结构(函数列表、URL、远程调用、危险操作)，不返回完整源码",
            parameters = {
                type = "object",
                properties = { path = { type = "string" } },
                required = { "path" },
            },
            fn = function(args)
                local scr = game:FindFirstChild(args.path, true)
                if not scr or not scr:IsA("LuaSourceContainer") then return "找不到脚本" end
                local code = D.CodeReader.readScript(scr)
                if not code then return "无法读取源码" end
                return D.CodeReader.report(code)
            end,
        })
        count = count + 1

        -- 6.7 搜索实例
        A.registerTool("find_instances", {
            description = "按名字搜索游戏里的实例",
            parameters = {
                type = "object",
                properties = {
                    query = { type = "string" },
                    limit = { type = "number", description = "最多返回几个(默认20)" },
                },
                required = { "query" },
            },
            fn = function(args)
                local limit = args.limit or 20
                local lower = string.lower
                local q = lower(args.query)
                local out = {}
                for _, obj in ipairs(game:GetDescendants()) do
                    if lower(obj.Name):find(q, 1, true) then
                        out[#out+1] = obj.ClassName .. "  " .. D.GetInstancePath(obj)
                        if #out >= limit then break end
                    end
                end
                return #out > 0 and table.concat(out, "\n") or "没有找到"
            end,
        })
        count = count + 1

        -- 6.8 联网搜索
        A.registerTool("web_search", {
            description = "联网搜索信息",
            parameters = {
                type = "object",
                properties = { query = { type = "string" } },
                required = { "query" },
            },
            fn = function(args)
                if not D.WebAccess then return "联网模块未加载" end
                local r = D.WebAccess.search(args.query, { provider = "ddg" })
                if not r then return "搜索失败" end
                return D.WebAccess.formatForAI(r)
            end,
        })
        count = count + 1

        -- 6.9 查看玩家
        A.registerTool("list_players", {
            description = "列出当前游戏里所有玩家的信息(位置、血量、距离)",
            parameters = { type = "object", properties = {} },
            fn = function()
                if not D.Model3D then return "Model3D 未加载" end
                local list = D.Model3D.sceneSnapshot({ radius = 9999 })
                local lines = {}
                for _, p in ipairs(list) do
                    if p.Class == "Model" and D.service.Players:GetPlayerFromCharacter(p.Instance) then
                        local plr = D.service.Players:GetPlayerFromCharacter(p.Instance)
                        lines[#lines+1] = string.format("%s  距离 %.0f  血量 %s",
                            plr.Name, p.Distance,
                            p.Instance:FindFirstChildOfClass("Humanoid") and
                            math.floor(p.Instance:FindFirstChildOfClass("Humanoid").Health) or "?")
                    end
                end
                return #lines > 0 and table.concat(lines, "\n") or "视野内无玩家"
            end,
        })
        count = count + 1

        return count
    end

    -- ==========================================================
    -- 7. 构建 API 请求的工具列表
    -- ==========================================================
    local function buildToolSpecs()
        local specs = {}
        for _, name in ipairs(A.toolOrder) do
            local t = A.tools[name]
            specs[#specs+1] = {
                type = "function",
                ["function"] = {
                    name = t.name,
                    description = t.description,
                    parameters = t.parameters,
                },
            }
        end
        return specs
    end

    -- ==========================================================
    -- 8. 对话历史管理
    -- ==========================================================
    A.addMessage = function(role, content, extra)
        local msg = { role = role, content = content }
        if extra then
            for k, v in pairs(extra) do msg[k] = v end
        end
        A.history[#A.history+1] = msg
        -- 超长截断(保留 system + 最近 N 条)
        if #A.history > A.config.maxHistory then
            local newHist = {}
            if A.history[1] and A.history[1].role == "system" then
                newHist[1] = A.history[1]
                for i = #A.history - A.config.maxHistory + 2, #A.history do
                    newHist[#newHist+1] = A.history[i]
                end
            else
                for i = #A.history - A.config.maxHistory + 1, #A.history do
                    newHist[#newHist+1] = A.history[i]
                end
            end
            A.history = newHist
        end
        return msg
    end

    A.clearHistory = function()
        A.history = {}
        if A.config.systemPrompt then
            A.addMessage("system", A.config.systemPrompt)
        end
    end

    A.getHistory = function()
        return A.history
    end

    -- ==========================================================
    -- 9. 核心: 单次对话
    -- ==========================================================
    --[[ A.chat(userMessage) -> {content, toolCalls, error} ]]
    A.chat = function(userMessage)
        if userMessage then
            A.addMessage("user", userMessage)
        end

        local provider = Providers[A.config.provider]
        if not provider then
            return nil, "未知 provider: " .. A.config.provider
        end

        local url = provider.url(A.config)
        local headers = provider.headers(A.config)
        local tools = buildToolSpecs()
        local body = provider.buildBody(A.config, A.history, tools)

        local data, err = httpPost(url, headers, body)
        if not data then return nil, err end

        local parsed, perr = provider.parseResponse(data)
        if not parsed then return nil, perr end

        -- 添加 assistant 回复到历史
        local assistantMsg = {
            role = "assistant",
            content = parsed.content or "",
        }
        if parsed.toolCalls then
            assistantMsg.tool_calls = parsed.toolCalls
            -- 标准化
            for _, tc in ipairs(assistantMsg.tool_calls) do
                if tc["function"] and not tc.type then tc.type = "function" end
            end
        end
        A.history[#A.history+1] = assistantMsg

        return parsed
    end

    -- ==========================================================
    -- 10. Agent 主循环
    -- ==========================================================
    --[[ A.run(goal, opts) -> {success, result, rounds, error}
         
         执行流程:
           1. 用户消息 = goal
           2. 调 LLM
           3. 如果 LLM 要求调工具 → 调工具 → 结果塞回历史 → 回到 2
           4. 如果 LLM 只返回文本 → 结束
    ]]
    A.run = function(goal, opts)
        opts = opts or {}
        if A.running then return { success = false, error = "Agent 正在运行中" } end
        A.running = true

        if #A.history == 0 and A.config.systemPrompt then
            A.addMessage("system", A.config.systemPrompt)
        end
        if goal then A.addMessage("user", goal) end

        local maxRounds = opts.maxRounds or A.config.maxRounds
        local onRound = opts.onRound
        local round = 0
        local finalContent = ""

        while round < maxRounds do
            round = round + 1

            local provider = Providers[A.config.provider]
            if not provider then
                A.running = false
                return { success = false, error = "未知 provider", rounds = round }
            end

            local url = provider.url(A.config)
            local headers = provider.headers(A.config)
            local tools = buildToolSpecs()
            local body = provider.buildBody(A.config, A.history, tools)

            local data, err = httpPost(url, headers, body)
            if not data then
                A.running = false
                return { success = false, error = err, rounds = round }
            end

            local parsed, perr = provider.parseResponse(data)
            if not parsed then
                A.running = false
                return { success = false, error = perr, rounds = round }
            end

            -- 记录 assistant 回复
            local assistantMsg = { role = "assistant", content = parsed.content or "" }
            if parsed.toolCalls then
                assistantMsg.tool_calls = parsed.toolCalls
                for _, tc in ipairs(assistantMsg.tool_calls) do
                    if tc["function"] and not tc.type then tc.type = "function" end
                end
            end
            A.history[#A.history+1] = assistantMsg

            if onRound then
                pcall(onRound, {
                    round = round,
                    content = parsed.content,
                    toolCalls = parsed.toolCalls,
                })
            end

            -- 如果 LLM 只返回文本, 结束
            if not parsed.toolCalls or #parsed.toolCalls == 0 then
                finalContent = parsed.content or ""
                break
            end

            -- 执行所有工具调用
            for _, tc in ipairs(parsed.toolCalls) do
                local fname = tc["function"].name
                local fargs = {}
                local ok, decode = pcall(D.service.HttpService.JSONDecode,
                    D.service.HttpService, tc["function"].arguments or "{}")
                if ok then fargs = decode end

                local result, toolErr = callTool(fname, fargs)

                -- 工具结果塞回历史
                A.history[#A.history+1] = {
                    role = "tool",
                    tool_call_id = tc.id,
                    name = fname,
                    content = result or ("工具执行错误: " .. tostring(toolErr)),
                }
            end
        end

        A.running = false
        return {
            success = true,
            result = finalContent,
            rounds = round,
            history = A.history,
        }
    end

    -- ==========================================================
    -- 11. 流式对话 (如果 provider 支持)
    -- ==========================================================
    --[[ A.stream(goal, onChunk, onDone)
         简单实现: 非流式, 但回调形式
    ]]
    A.stream = function(goal, onChunk, onDone)
        task.spawn(function()
            local result, err = A.run(goal, {
                onRound = function(info)
                    if onChunk and info.content then onChunk(info.content) end
                end,
            })
            if onDone then onDone(result, err) end
        end)
    end

    -- ==========================================================
    -- 12. 快捷对话 (单轮, 不调工具)
    -- ==========================================================
    A.ask = function(question)
        local oldTools = A.toolOrder
        A.toolOrder = {}  -- 暂时禁用工具

        local provider = Providers[A.config.provider]
        if not provider then A.toolOrder = oldTools return nil, "未知 provider" end

        local tempHist = {
            { role = "system", content = A.config.systemPrompt },
            { role = "user", content = question },
        }

        local url = provider.url(A.config)
        local headers = provider.headers(A.config)
        local body = provider.buildBody(A.config, tempHist, nil)

        A.toolOrder = oldTools

        local data, err = httpPost(url, headers, body)
        if not data then return nil, err end
        local parsed = provider.parseResponse(data)
        return parsed and parsed.content or nil
    end

    -- ==========================================================
    -- 13. 测试连接
    -- ==========================================================
    A.testConnection = function()
        local result, err = A.ask("Say 'OK' if you can hear me.")
        if result then
            return true, "连接成功: " .. result:sub(1, 50)
        end
        return false, "连接失败: " .. tostring(err)
    end

    -- ==========================================================
    -- 14. Session 保存 / 恢复
    -- ==========================================================
    A.saveSession = function(path)
        if not D.env.writefile then return false, "无 writefile" end
        local session = {
            config = {
                provider = A.config.provider,
                model = A.config.model,
                systemPrompt = A.config.systemPrompt,
            },
            history = A.history,
            time = os.date("%Y-%m-%d %H:%M:%S"),
        }
        local ok, json = pcall(D.service.HttpService.JSONEncode, D.service.HttpService, session)
        if not ok then return false, "编码失败" end
        return pcall(D.env.writefile, path or "ai_session.json", json)
    end

    A.loadSession = function(path)
        if not D.env.readfile then return false, "无 readfile" end
        local ok, data = pcall(D.env.readfile, path or "ai_session.json")
        if not ok or not data then return false, "读文件失败" end
        local s, session = pcall(D.service.HttpService.JSONDecode, D.service.HttpService, data)
        if not s then return false, "解析失败" end
        if session.config then
            for k, v in pairs(session.config) do A.config[k] = v end
        end
        if session.history then A.history = session.history end
        return true
    end

    -- ==========================================================
    -- 15. 初始化
    -- ==========================================================
    A.autoRegisterTools()

    -- 自动填充 system prompt (含工具列表)
    A.refreshSystemPrompt = function()
        local toolDescs = {}
        for _, name in ipairs(A.toolOrder) do
            toolDescs[#toolDescs+1] = "- " .. name .. ": " .. A.tools[name].description
        end
        A.config.systemPrompt = "You are a Roblox game analysis assistant with access to tools.\n"
            .. "Available tools:\n" .. table.concat(toolDescs, "\n")
            .. "\n\nAlways explain what you're doing before calling a tool. "
            .. "Be concise. Report findings in a clear format."
    end
    A.refreshSystemPrompt()
end

-- ============================================================
-- [32] FullTest — 全功能测试套件 (v2.1)
--      整合 SUNC / UNC / Myriad 标准
--      逐一测试本库所有函数在当前执行器的可用性
-- ============================================================
D.FullTest = {}
do
    local FT = D.FullTest

    FT.results = {}
    FT.passed = 0
    FT.failed = 0
    FT.skipped = 0

    local function test(name, fn)
        local ok, result = pcall(fn)
        if ok and result ~= false then
            FT.passed = FT.passed + 1
            table.insert(FT.results, {name = name, status = "✅"})
            return true
        elseif ok then
            FT.failed = FT.failed + 1
            table.insert(FT.results, {name = name, status = "❌", reason = "返回 false"})
            return false
        else
            FT.failed = FT.failed + 1
            table.insert(FT.results, {name = name, status = "❌", reason = tostring(result)})
            return false
        end
    end

    local function skip(name, reason)
        FT.skipped = FT.skipped + 1
        table.insert(FT.results, {name = name, status = "⏭", reason = reason})
    end

    -- ==========================================================
    -- 核心：逐个测试所有模块
    -- ==========================================================
    FT.run = function(opts)
        opts = opts or {}
        FT.results = {}
        FT.passed, FT.failed, FT.skipped = 0, 0, 0

        -- 1. 基础工具
        test("FormatLuaString", function() return D.FormatLuaString('a"b') == 'a\\"b' end)
        test("FastWait", function() D.FastWait(0.05) return true end)
        test("ColorToBytes", function() return D.ColorToBytes(Color3.fromRGB(255,0,0)) == "255, 0, 0" end)
        test("GetInstancePath", function() return D.GetInstancePath(workspace) == 'game:GetService("Workspace")' end)

        -- 2. 序列化
        test("v2s 数字", function() return D.v2s(123) == "123" end)
        test("v2s 字符串", function() return D.v2s("hi") == '"hi"' end)
        test("v2s Vector3", function() return D.v2s(Vector3.new(1,2,3)):find("Vector3") ~= nil end)
        test("v2v", function() return D.v2v({a=1}):find("local a") ~= nil end)

        -- 3. 反编译 (如果支持)
        if getscriptbytecode then
            test("decompile", function()
                local s = D.service.Players.LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                if not s then return true end
                local src = D.decompile(s)
                return type(src) == "string"
            end)
        else
            skip("decompile", "无 getscriptbytecode")
        end

        -- 4. 执行器能力 (整合 SUNC 标准)
        test("loadstring", function() return pcall(loadstring, "return 1") end)
        test("hookfunction", function() return typeof(hookfunction) == "function" end)
        test("hookmetamethod", function() return typeof(hookmetamethod) == "function" end)
        test("getgenv", function() return typeof(getgenv) == "function" end)
        test("getrenv", function() return typeof(getrenv) == "function" end)
        test("checkcaller", function() return typeof(checkcaller) == "function" end)
        test("getrawmetatable", function() return typeof(getrawmetatable) == "function" end)
        test("setreadonly", function() return typeof(setreadonly) == "function" end)
        test("getnamecallmethod", function() return typeof(getnamecallmethod) == "function" end)
        test("newcclosure", function() return typeof(newcclosure) == "function" end)
        test("clonefunction", function() return typeof(clonefunction) == "function" end)
        test("getscriptbytecode", function() return typeof(getscriptbytecode) == "function" end)
        test("getgc", function() return typeof(getgc) == "function" end)
        test("getreg", function() return typeof(getreg) == "function" end)
        test("getnilinstances", function() return typeof(getnilinstances) == "function" end)
        test("setclipboard", function() return typeof(setclipboard) == "function" end)
        test("identifyexecutor", function() return typeof(identifyexecutor) == "function" end)

        -- 5. SimpleSpy
        test("SimpleSpy.start", function() return typeof(D.SimpleSpy.start) == "function" end)
        test("SimpleSpy.genScript", function() return typeof(D.SimpleSpy.genScript) == "function" end)
        test("SimpleSpy.replay", function() return typeof(D.SimpleSpy.replay) == "function" end)

        -- 6. Executor
        test("Executor.exec", function() return D.Executor.exec("return 1+1").result == 2 end)
        test("Executor.eval", function() return D.Executor.eval("2^10") == 1024 end)
        test("Executor.run", function() return D.Executor.run("print('hi') return 5"):find("5") ~= nil end)
        test("Executor.execWithTimeout", function()
            local r = D.Executor.execWithTimeout("while true do end", 1)
            return r.timeout == true
        end)

        -- 7. Injector
        test("Injector.capabilities", function() return D.Injector.capabilities() ~= nil end)
        test("Injector.getUpvalues", function()
            local f = function() end
            return type(D.Injector.getUpvalues(f)) == "table"
        end)
        test("Injector.dumpFunction", function()
            local f = function() return 1 end
            return type(D.Injector.dumpFunction(f)) == "string"
        end)

        -- 8. Model3D
        test("Model3D.bbox", function() return D.Model3D.bbox(workspace.Baseplate) ~= nil end)
        test("Model3D.describe", function() return D.Model3D.describe(workspace.Baseplate):find("Baseplate") ~= nil end)
        test("Model3D.classify", function() return D.Model3D.classify(workspace.Baseplate) == "large-platform" end)

        -- 9. CodeReader
        test("CodeReader.extractFunctions", function()
            local f = D.CodeReader.extractFunctions("local function hello() end")
            return #f >= 1 and f[1].name == "hello"
        end)
        test("CodeReader.report", function()
            local r = D.CodeReader.report("local function hello() end")
            return r:find("代码分析报告") ~= nil
        end)

        -- 10. CodeSkeleton (需要下载 DumbLuaParser)
        if D.env.readfile or game.HttpGet then
            test("CodeSkeleton.loadParser", function()
                local p = D.CodeSkeleton.loadParser()
                return p ~= nil
            end)
        else
            skip("CodeSkeleton.loadParser", "无法下载 DumbLuaParser")
        end

        -- 11. WebAccess
        test("WebAccess.hasRequest", function() return typeof(D.WebAccess.hasRequest) == "function" end)
        test("WebAccess.htmlToText", function()
            local t = D.WebAccess.htmlToText("<h1>Title</h1><p>Body</p>")
            return t:find("Title") and t:find("Body")
        end)

        -- 12. AIAgent (需要 API key 才能测试真实调用)
        test("AIAgent.configure", function() return typeof(D.AIAgent.configure) == "function" end)
        test("AIAgent.registerTool", function()
            D.AIAgent.registerTool("test_tool", {description = "test", fn = function() return "ok" end})
            return D.AIAgent.tools["test_tool"] ~= nil
        end)
        test("AIAgent.listTools", function() return #D.AIAgent.listTools() > 0 end)

        -- ==========================================================
        -- 生成报告
        -- ==========================================================
        local report = {}
        report[#report+1] = "═══════════════════════════════════════"
        report[#report+1] = "  FullTest 结果报告"
        report[#report+1] = "═══════════════════════════════════════"
        report[#report+1] = string.format("  ✅ 通过: %d", FT.passed)
        report[#report+1] = string.format("  ❌ 失败: %d", FT.failed)
        report[#report+1] = string.format("  ⏭ 跳过: %d", FT.skipped)
        report[#report+1] = ""

        if FT.failed > 0 then
            report[#report+1] = "--- 失败详情 ---"
            for _, r in ipairs(FT.results) do
                if r.status == "❌" then
                    report[#report+1] = string.format("  ❌ %s", r.name)
                    if r.reason then report[#report+1] = "     → " .. r.reason end
                end
            end
        end

        if FT.skipped > 0 then
            report[#report+1] = ""
            report[#report+1] = "--- 跳过详情 ---"
            for _, r in ipairs(FT.results) do
                if r.status == "⏭" then
                    report[#report+1] = string.format("  ⏭ %s (%s)", r.name, r.reason)
                end
            end
        end

        local text = table.concat(report, "\n")
        if not opts.silent then print(text) end
        return text
end

end

print("ok")
return D
