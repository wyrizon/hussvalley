local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")


local Hub = {
    Genv = (getgenv and getgenv()) or _G,
    Registry = {},
    Cleaned = false,
}

if Hub.Genv.YvetzalUnload then
    pcall(Hub.Genv.YvetzalUnload)
end

local LocalPlayer = Players.LocalPlayer
local HussValley = ReplicatedStorage:WaitForChild("ChickenOrHero")
local Movement = HussValley:WaitForChild("Movement")
local MovementProfiles = require(Movement:WaitForChild("MovementProfiles"))
local BoostInput = require(Movement:WaitForChild("BoostInput"))
local Game = HussValley:WaitForChild("Game")
local Session = Game:WaitForChild("Session")
local MapVoteState = Game:WaitForChild("MapVoteState")
local MapVoteEvent = Game:WaitForChild("MapVoteEvent")
local ContactCatchConfig = require(Game:WaitForChild("ContactCatchConfig"))
local TacklePrediction = require(Game:WaitForChild("TacklePrediction"))
local MeleeEvent = Game:WaitForChild("MeleeEvent")
local RescueConfig = require(Game:WaitForChild("RescueConfig"))
local RescueRange = math.max(3, tonumber(RescueConfig.Range) or 6) - 0.25
local RescueHold = math.max(0.1, tonumber(RescueConfig.HoldSeconds) or 1.2)
local RescueFinishGrace = math.max(0.1, tonumber(RescueConfig.FinishGrace) or 0.5)
local RescueEvent = Game:WaitForChild("RescueEvent")
local ControlGate = require(Movement:WaitForChild("ControlGate"))
local Gear = HussValley:WaitForChild("Gear")
local GearCatalog = require(Gear:WaitForChild("GearCatalog"))
local ArmoryEvent = HussValley:WaitForChild("Weapons"):WaitForChild("ArmoryEvent")
local SpinWheelEvent = HussValley:WaitForChild("SpinWheelEvent")
local JourneyConfig = require(HussValley:WaitForChild("Progression"):WaitForChild("JourneyConfig"))
local JourneyEvent = HussValley:WaitForChild("Progression"):WaitForChild("JourneyEvent")
local PlayerPreferences = HussValley:WaitForChild("Game"):WaitForChild("PlayerPreferences")
local Presentation = HussValley:WaitForChild("Presentation")
local HudNavigation = require(Presentation:WaitForChild("HudNavigation"))
local WindUI

local Settings = {
    RunnerEnabled = true,
    Strategy = "Auto",
    CustomSpeed = false,
    SpeedMultiplier = 1.0,
    AutoGems = true,
    GemScanInterval = 0.25,
    GemMaxDistance = 220,
    GemCollectDistance = 4.5,
    AutoRevive = true,
    ReviveBeforeGems = true,
    ReviveMaxDistance = 220,
    AvoidCatchers = true,
    PredictionTime = 0.65,
    AvoidStrength = 2.2,
    PanicDistance = 15,
    SafezoneDepthRatio = 0.52,
    SafezoneValidationRatio = 0.44,
    SafezoneEdgeMargin = 4.5,
    EdgeRayHeight = 12,
    EdgeRayDepth = 52,
    EdgeLookAhead = 14,
    EdgeSecondLookAhead = 28,
    AutoDash = true,
    DashCooldown = 0.85,
    DashCooldownSlack = 0.04,
    DashDistance = 48,
    DashClosingSpeed = 10,
    SmoothMovement = true,
    TurnRate = 9,
    EmergencySafeZone = true,
    ShowThreats = true,
    ShowGoal = true,
    CorridorEnabled = true,
    CorridorMinWidth = 4.25,
    CorridorCenterRange = 26,
    CorridorLockTime = 1.65,
    CorridorPassDistance = 20,
    CorridorApproachDistance = 60,
    SideGapEnabled = true,
    SideGapAngles = {18, 30, 42, 54, 68, 82},
    SideGapMinClearance = 3.5,
    SideGapCommitTime = 0.8,
    SideGapForwardBias = 6.5,
    DodgeCommitTime = 0.7,
    DodgeThreatLookahead = 1.1,
    ObstacleLookAhead = 14,
    ObstacleRadius = 2.25,
    ObstacleSideOffset = 3.5,
    ObstacleRecoveryTime = 0.65,

    CatcherChase = true,
    CatcherTargetMode = "Auto",
    CatcherCustomSpeed = false,
    CatcherSpeedMultiplier = 1.0,
    CatcherPrediction = 0.45,
    CatcherSmoothing = 6,
    SmartPriority = true,
    CatcherAttackPriority = "Smart",
    AutoTackle = true,
    TackleRange = 12,
    TackleCooldown = 1.2,
    AutoMelee = true,
    MeleeRange = 9,
    MeleeCooldown = 0.35,
    SmoothTurn = true,
    TurnRateCatcher = 14,
    FollowTarget = true,

    ShowHitboxes = true,
    ShowGoalUtility = true,
    ShowThreatUtility = false,
    ShowDebugUI = false,
    CameraFollow = true,
    CameraResponse = 0.25,
    AutoSpinWheel = false,
    WheelSpinInterval = 6,
    WheelMinimumCredits = 1,
    WheelAnnounce = true,
    AutoClaimJourneyRewards = false,
    JourneyClaimAnnounce = true,
    AutoMapVote = false,
    MapVoteAnnounce = true,
    MapVoteSelections = {},
    DisableBuiltinAFK = false,
}

local Runtime = {
    Profile = nil,
    ProfileRole = nil,
    RunnerTick = 0,
    RunnerPlanAt = -math.huge,
    RunnerPlanDirection = Vector3.zero,
    RunnerPlanGoal = Vector3.zero,
    CatcherTick = 0,
    UtilityTick = 0,
    LastMove = os.clock(),
    LastMovePosition = nil,
    MoveCommandAt = -math.huge,
    Stuck = false,
    Path = Vector3.zero,
    Goal = nil,
    GoalMode = "SafeZone",
    GoalSide = nil,
    AssistMode = nil,
    AssistTarget = nil,
    AssistSince = -math.huge,
    GemTarget = nil,
    GemIgnored = {},
    GemScanAt = -math.huge,
    ReviveTarget = nil,
    ReviveStarted = false,
    ReviveStartAt = 0,
    ReviveInputToken = 0,
    Catchers = {},
    CatcherCacheAt = 0,
    Threats = {},
    ThreatAt = 0,
    ThreatHistory = {},
    DashAt = -math.huge,
    DashStatus = "idle",
    DashLastRequestAt = -math.huge,
    DashLastCount = nil,
    Ping = 0,
    PingAt = 0,
    Armory = {Loaded = false, Abilities = {}},
    ArmoryAt = -math.huge,
    CatcherTargets = {},
    CatcherTargetAt = 0,
    CatcherTarget = nil,
    CatcherRandomTargetAt = -math.huge,
    DodgeDirection = Vector3.zero,
    DodgeUntil = -math.huge,
    EdgeRisk = false,
    EdgeDirection = Vector3.zero,
    CatcherPath = Vector3.zero,
    CatcherVelocity = {},
    MeleeId = 0,
    LastMelee = -math.huge,
    LastTackle = -math.huge,
    MapCacheAt = -math.huge,
    MapCache = nil,
    EdgeCheckAt = -math.huge,
    EdgeCheckPosition = nil,
    EdgeCheckDirection = Vector3.zero,
    EdgeCheckGoal = Vector3.zero,
    EdgeRecoveryAt = -math.huge,
    EdgeRecoveryDirection = Vector3.zero,
    EdgeRecoveryUntil = -math.huge,
    StuckRecoveryUntil = -math.huge,
    StuckRecoveryDirection = Vector3.zero,
    SafeCheckAt = -math.huge,
    SafeCheckPosition = nil,
    SafeCheckA = false,
    SafeCheckB = false,
    RouteActive = false,
    RouteComplete = false,
    RouteStartSide = nil,
    RouteTargetSide = nil,
    RouteCompletePosition = nil,
    RouteCompleteAt = -math.huge,
    CorridorActive = false,
    CorridorGoal = Vector3.zero,
    CorridorCenter = Vector3.zero,
    CorridorAxis = Vector3.zero,
    CorridorGapWidth = 0,
    CorridorStartedAt = -math.huge,
    SideGapDirection = Vector3.zero,
    SideGapUntil = -math.huge,
    SideGapReason = "",
    WheelScanAt = -math.huge,
    WheelActionAt = -math.huge,
    WheelStatus = "disabled",
    WheelLastButton = nil,
    WheelSpinCount = 0,
    WheelCredits = 0,
    WheelNextFreeAt = 0,
    WheelPurchasesAvailable = false,
    WheelDiscountAvailable = false,
    WheelStateRequestAt = -math.huge,
    WheelSpinRequestAt = -math.huge,
    WheelEventReady = false,
    WheelSpinning = false,
    WheelLastStateAt = -math.huge,
    WheelStatusAt = -math.huge,
    WheelNextAttemptAt = -math.huge,
    WheelMinimumCredits = 1,
    AfkOverrideStatus = "disabled",
    AfkOverrideLastRequestAt = -math.huge,
    AfkOverrideRequestInterval = 2.0,
    AfkOverrideInLobby = false,
    AfkOverrideRequestCount = 0,
    JourneyScanAt = -math.huge,
    JourneyStatus = "disabled",
    JourneyClaimCount = 0,
    JourneyLastClaimAt = -math.huge,
    JourneyClaimedButtons = {},
    JourneyLoaded = false,
    JourneySeasonId = nil,
    JourneyRequestAt = -math.huge,
    JourneyClaimInFlight = false,
    JourneyLastStateAt = -math.huge,
    JourneyTier = 1,
    JourneyPremium = false,
    JourneyClaims = {},
    JourneyLastClaimResultAt = -math.huge,
    MapVoteScanAt = -math.huge,
    MapVoteStatus = "disabled",
    MapVoteOptions = {},
    MapVoteLastActionAt = -math.huge,
    MapVoteOpen = false,
    MapVotePhase = "Waiting",
    MapVoteToken = nil,
    MapVoteOptionIds = {},
    MapVoteLastStateAt = -math.huge,
    DebugLastError = nil,
    DebugLastErrorAt = -math.huge,
    DebugEnabled = false,
    DebugGui = nil,
    DebugLabel = nil,
    DebugPanelAt = -math.huge,
    JourneyNextClaimAt = -math.huge,
    JourneyManualPending = false,
    ObstacleParams = nil,
    ObstacleCharacter = nil,
    ObstacleDirection = Vector3.zero,
    ObstacleRisk = false,
    ObstacleRecoveryDirection = Vector3.zero,
    ObstacleRecoveryUntil = -math.huge,
}

local Safezone = {
    Map = nil,
    A = nil,
    B = nil,
    Cached = false,
}

local Visuals = {
    Goal = nil,
    Threats = {},
    Hitboxes = {},
}

local MapVoteSlotIds = {
    "Map 1",
    "Map 2",
    "Map 3",
}

local MapVoteDropdown

local function Flat(V)
    return Vector3.new(V.X, 0, V.Z)
end

local function GetCharacter(Player)
    return (Player or LocalPlayer).Character
end

local function GetHumanoid(Player)
    local C = GetCharacter(Player)
    return C and C:FindFirstChildOfClass("Humanoid") or nil
end

local function GetRoot(Player)
    local C = GetCharacter(Player)
    return C and C:FindFirstChild("HumanoidRootPart") or nil
end

local function GetRole()
    return LocalPlayer:GetAttribute("GameRole") or "Lobby"
end

local function GetRunState()
    return LocalPlayer:GetAttribute("RunState") or "Idle"
end

local function GetRunnerStrategy()
    if Settings.Strategy == "Hero" or Settings.Strategy == "Chicken" then
        return Settings.Strategy
    end

    local ChoiceMoment = Session:GetAttribute("ChoiceMoment")
    if type(ChoiceMoment) == "string" and ChoiceMoment ~= "" then
        local Ok, Choice = pcall(HttpService.JSONDecode, HttpService, ChoiceMoment)
        if Ok and type(Choice) == "table" then
            local Selected = tostring(Choice.choice or Choice.kind or "")
            if Selected == "Hero" or Selected == "Chicken" then
                return Selected
            end
        end
    end

    if tonumber(Session:GetAttribute("HeroUserId")) == LocalPlayer.UserId then
        return "Hero"
    end
    return "Chicken"
end

local function IsRunnerActive()
    if LocalPlayer:GetAttribute("InMatch") ~= true then
        return false
    end
    local Role = GetRole()
    if Role ~= "Runner" then
        return false
    end
    return GetRunState() == "Active"
end

local function IsCatcherActive()
    if LocalPlayer:GetAttribute("InMatch") ~= true then
        return false
    end
    if GetRole() ~= "Catcher" then
        return false
    end
    return GetRunState() == "Active"
end

local function CanMove()
    if LocalPlayer:GetAttribute("ClientReady") ~= true then
        return false
    end
    if Session:GetAttribute("GlobalPaused") == true then
        return false
    end
    if Session:GetAttribute("MapChanging") == true then
        return false
    end
    local C = GetCharacter()
    if not C then
        return false
    end
    if C:GetAttribute("Ragdolled") == true then
        return false
    end
    if C:GetAttribute("GearMotion") == true then
        return false
    end
    if C:GetAttribute("MovementLocked") == true then
        return false
    end
    local H = GetHumanoid()
    if not H or H.Health <= 0 then
        return false
    end
    if H.PlatformStand or H.Sit then
        return false
    end
    return true
end

local function GetBaseSpeed(Role)
    Role = Role or GetRole()
    if Runtime.Profile and Runtime.ProfileRole == Role then
        return Runtime.Profile.MaxSpeed or 16
    end
    local Ok, Profile = pcall(MovementProfiles.get, Role, LocalPlayer)
    if Ok and Profile then
        Runtime.Profile = Profile
        Runtime.ProfileRole = Role
        return Profile.MaxSpeed or 16
    end
    return 16
end

local function GetRunnerSpeed()
    local Speed = math.max(GetBaseSpeed("Runner"), 1)
    if Settings.CustomSpeed then
        Speed *= math.clamp(Settings.SpeedMultiplier, 1, 2)
    end
    return Speed
end

local function GetRunnerDashCooldown()
    local Profile = Runtime.Profile
    if not Profile or Runtime.ProfileRole ~= "Runner" then
        pcall(function()
            Profile = MovementProfiles.get("Runner", LocalPlayer)
        end)
    end
    local Dash = Profile and Profile.Dash
    local Cooldown = Dash and tonumber(Dash.Cooldown)
    if Cooldown and Cooldown >= 0 then
        return Cooldown
    end
    return math.max(tonumber(Settings.DashCooldown) or 0.85, 0.05)
end

local function GetCatcherSpeed()
    local Speed = math.max(GetBaseSpeed("Catcher"), 1)
    if Settings.CatcherCustomSpeed then
        Speed *= math.clamp(Settings.CatcherSpeedMultiplier, 1, 2)
    end
    return Speed
end

local function RestoreNativeWalkSpeed()
    local Hum = GetHumanoid()
    local Character = GetCharacter()
    if not Hum or not Character then
        return
    end
    local Native = tonumber(Character:GetAttribute("MovementSpeed"))
    if Native and Native > 0 then
        Hum.WalkSpeed = Native
    end
end

local function RefreshPing(Now)
    if Now - Runtime.PingAt < 0.5 then
        return
    end
    Runtime.PingAt = Now
    local Value = 0
    pcall(function()
        Value = LocalPlayer:GetNetworkPing() * 0.5
    end)
    Runtime.Ping = math.max(Value, 0)
end

local function GetMap()
    local Now = os.clock()
    if Now - Runtime.MapCacheAt < 0.35 then
        return Runtime.MapCache
    end
    Runtime.MapCacheAt = Now
    local Handle = Game:FindFirstChild("ActiveMap")
    if Handle and Handle:IsA("ObjectValue") and Handle.Value and Handle.Value:IsDescendantOf(workspace) then
        Runtime.MapCache = Handle.Value
        return Runtime.MapCache
    end
    local Found = nil
    for _, Obj in ipairs(workspace:GetChildren()) do
        if Obj:FindFirstChild("Field") then
            Found = Obj
            break
        end
    end
    Runtime.MapCache = Found
    return Found
end

local EdgeRayCache = {
    Map = nil,
    Field = nil,
    InvisWall = nil,
    Params = nil,
    WallParams = nil,
}

local function ResolveActiveField(Map)
    if not Map then
        return nil
    end
    local Field = Map:FindFirstChild("Field")
    if Field then
        return Field
    end
    return Map:FindFirstChild("Field", true)
end

local function ResolveActiveInvisWall(Field)
    if not Field then
        return nil
    end
    return Field:FindFirstChild("InvisWall", true)
end

local function RefreshEdgeRayCache()
    local Map = GetMap()
    local Field = ResolveActiveField(Map)
    local Wall = ResolveActiveInvisWall(Field)
    local Include = Field or Map

    if EdgeRayCache.Map == Map
        and EdgeRayCache.Field == Field
        and EdgeRayCache.InvisWall == Wall
        and EdgeRayCache.Params then
        return
    end

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Include
    Params.FilterDescendantsInstances = Include and {Include} or {}
    Params.IgnoreWater = true

    EdgeRayCache.Map = Map
    EdgeRayCache.Field = Field
    EdgeRayCache.InvisWall = Wall
    EdgeRayCache.Params = Params
    EdgeRayCache.WallParams = nil
end

local function GetEdgeRayParams()
    RefreshEdgeRayCache()
    return EdgeRayCache.Params
end

local function GetInvisWallParams()
    RefreshEdgeRayCache()
    local Wall = EdgeRayCache.InvisWall
    if not Wall or not Wall:IsDescendantOf(workspace) then
        EdgeRayCache.InvisWall = nil
        EdgeRayCache.WallParams = nil
        return nil
    end
    if EdgeRayCache.WallParams then
        return EdgeRayCache.WallParams
    end
    local WallParams = RaycastParams.new()
    WallParams.FilterType = Enum.RaycastFilterType.Include
    WallParams.FilterDescendantsInstances = {Wall}
    WallParams.IgnoreWater = true
    EdgeRayCache.WallParams = WallParams
    return WallParams
end

local function InvisWallHit(Position, Direction, Distance)
    local Dir = Flat(Direction)
    if Dir.Magnitude < 0.05 then
        return nil
    end
    local Params = GetInvisWallParams()
    if not Params then
        return nil
    end
    Dir = Dir.Unit
    local Origin = Vector3.new(Position.X, Position.Y + 2.5, Position.Z)
    return workspace:Raycast(Origin, Dir * Distance, Params)
end

local GroundSupportScore

local function GetObstacleParams()
    local Character = GetCharacter()
    if Runtime.ObstacleParams and Runtime.ObstacleCharacter == Character then
        return Runtime.ObstacleParams
    end

    local Excluded = {}
    if Character then
        Excluded[#Excluded + 1] = Character
    end
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            Excluded[#Excluded + 1] = Player.Character
        end
    end

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = Excluded
    Params.IgnoreWater = true
    Runtime.ObstacleParams = Params
    Runtime.ObstacleCharacter = Character
    return Params
end

local function ObstacleHit(Position, Direction, Distance)
    local Dir = Flat(Direction)
    if Dir.Magnitude < 0.05 then
        return nil
    end

    local Origin = Vector3.new(Position.X, Position.Y + 2.25, Position.Z)
    local Params = GetObstacleParams()
    local Ok, Hit = pcall(function()
        return workspace:Spherecast(Origin, Settings.ObstacleRadius, Dir.Unit * Distance, Params)
    end)
    if Ok and Hit and Hit.Instance and Hit.Instance.CanQuery ~= false then
        return Hit
    end

    local RayHit = workspace:Raycast(Origin, Dir.Unit * Distance, Params)
    if RayHit and RayHit.Instance and RayHit.Instance.CanQuery ~= false then
        return RayHit
    end
    return nil
end

local function ObstacleClearance(Position, Direction, Distance)
    local Dir = Flat(Direction)
    if Dir.Magnitude < 0.05 then
        return 0
    end

    Dir = Dir.Unit
    local Side = Vector3.new(-Dir.Z, 0, Dir.X)
    local Best = Distance
    for _, Offset in ipairs({0, Settings.ObstacleSideOffset, -Settings.ObstacleSideOffset}) do
        local Hit = ObstacleHit(Position + Side * Offset, Dir, Distance)
        if Hit then
            Best = math.min(Best, (Hit.Position - Position).Magnitude)
        end
    end
    return Best
end

local function ChooseObstacleDirection(Position, Desired, Goal, Threats)
    local Dir = Flat(Desired)
    if Dir.Magnitude < 0.05 then
        return Vector3.zero, false
    end
    Dir = Dir.Unit

    local RootPart = GetRoot()
    local Speed = RootPart and Flat(RootPart.AssemblyLinearVelocity).Magnitude or 0
    local LookAhead = math.clamp(Settings.ObstacleLookAhead + Speed * 0.18, Settings.ObstacleLookAhead, 28)
    local Forward = Flat(Goal - Position)
    local ForwardUnit = Forward.Magnitude > 0.05 and Forward.Unit or Dir
    local CurrentClearance = ObstacleClearance(Position, Dir, LookAhead)
    if CurrentClearance >= LookAhead * 0.82 then
        return Dir, false
    end

    local Candidates = {}
    for _, Angle in ipairs({0, 18, -18, 35, -35, 55, -55, 75, -75, 105, -105, 145, -145, 180}) do
        local Radians = math.rad(Angle)
        local Candidate = Vector3.new(
            Dir.X * math.cos(Radians) - Dir.Z * math.sin(Radians),
            0,
            Dir.X * math.sin(Radians) + Dir.Z * math.cos(Radians)
        )
        local Duplicate = false
        for _, Existing in ipairs(Candidates) do
            if Existing:Dot(Candidate) > 0.985 then
                Duplicate = true
                break
            end
        end
        if not Duplicate then
            Candidates[#Candidates + 1] = Candidate
        end
    end

    local Best = Dir
    local BestScore = -math.huge
    for _, Candidate in ipairs(Candidates) do
        local Clearance = ObstacleClearance(Position, Candidate, LookAhead)
        local Progress = Candidate:Dot(ForwardUnit)
        local Support = GroundSupportScore(Position, Candidate, Position.Y)
        local ThreatPenalty = 0
        for _, Threat in ipairs(Threats) do
            local ThreatDirection = Flat(Threat.Position - Position)
            if ThreatDirection.Magnitude > 0.05 then
                ThreatPenalty += math.max(0, Candidate:Dot(ThreatDirection.Unit)) * math.max(0, 14 - Threat.Distance)
            end
        end
        local Score = Clearance * 3.2 + Progress * 8 + Support * 2.5 - ThreatPenalty
        if Clearance < Settings.ObstacleRadius * 1.5 then
            Score -= 30
        end
        if Score > BestScore then
            BestScore = Score
            Best = Candidate
        end
    end

    local Risk = CurrentClearance < LookAhead * 0.65
    return Best, Risk
end

local function FloorRay(Point, Y)
    local Map = GetMap()
    if not Map then
        return true
    end
    local Params = GetEdgeRayParams()
    if not Params or #Params.FilterDescendantsInstances == 0 then
        return false
    end
    local Origin = Vector3.new(Point.X, math.max(Y + 12, Point.Y + 10), Point.Z)
    local Direction = Vector3.new(0, -(Settings.EdgeRayHeight + Settings.EdgeRayDepth), 0)
    local Hit = workspace:Raycast(Origin, Direction, Params)
    return Hit ~= nil and Hit.Normal.Y >= 0.35
end

local function HasFloorAt(Point, Y)
    return FloorRay(Point, Y)
end

local function GetPlayfieldCenter()
    if Safezone.A and Safezone.B then
        return (Safezone.A.Center + Safezone.B.Center) * 0.5
    end
    if Safezone.A then
        return Safezone.A.Center
    end
    if Safezone.B then
        return Safezone.B.Center
    end
    return nil
end

function GroundSupportScore(Position, Direction, Y)
    local Dir = Flat(Direction)
    if Dir.Magnitude < 0.05 then
        return 0
    end
    Dir = Dir.Unit
    local Side = Vector3.new(-Dir.Z, 0, Dir.X)
    local Score = 0
    if HasFloorAt(Position + Dir * 6, Y) then Score += 2 end
    if HasFloorAt(Position + Dir * 14, Y) then Score += 2 end
    if HasFloorAt(Position + Dir * 24, Y) then Score += 1 end
    if HasFloorAt(Position + Dir * 14 + Side * 3, Y) then Score += 1 end
    if HasFloorAt(Position + Dir * 14 - Side * 3, Y) then Score += 1 end
    return Score
end

local function BoundaryInwardDirection(Position, Y)
    local Dirs = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1),
    }
    local Outward = Vector3.zero
    local Missing = 0
    for _, Dir in ipairs(Dirs) do
        local WallHit = InvisWallHit(Position, Dir, 9)
        if WallHit or not HasFloorAt(Position + Dir * 7, Y) then
            Outward += Dir
            Missing += 1
        end
    end
    if Missing == 0 or Outward.Magnitude < 0.05 then
        return Vector3.zero
    end
    local Inward = Flat(-Outward)
    if Inward.Magnitude < 0.05 then
        return Vector3.zero
    end
    Inward = Inward.Unit
    if GroundSupportScore(Position, Inward, Y) < 3 then
        return Vector3.zero
    end
    return Inward
end

local function EdgeDirectionClear(Position, Direction, Y, Distance)
    local Dir = Flat(Direction)
    if Dir.Magnitude < 0.05 then
        return false
    end
    Dir = Dir.Unit
    if InvisWallHit(Position, Dir, math.max(8, Distance)) then
        return false
    end
    local Score = GroundSupportScore(Position, Dir, Y)
    if Distance <= 14 then
        return Score >= 4
    end
    return Score >= 5
end

local function EdgeRiskForDirection(Position, Direction, Y)
    local Dir = Flat(Direction)
    if Dir.Magnitude < 0.05 then
        return true
    end
    Dir = Dir.Unit
    return not EdgeDirectionClear(Position, Dir, Y, Settings.EdgeLookAhead)
        or not EdgeDirectionClear(Position, Dir, Y, Settings.EdgeSecondLookAhead)
end

local function RotateEdge(Dir, Angle)
    local R = math.rad(Angle)
    local C = math.cos(R)
    local S = math.sin(R)
    return Vector3.new(Dir.X * C - Dir.Z * S, 0, Dir.X * S + Dir.Z * C)
end

local function ChooseEdgeDirection(Position, Desired, Goal, Y)
    local Dir = Flat(Desired)
    if Dir.Magnitude < 0.05 then
        return Vector3.zero, false
    end
    Dir = Dir.Unit

    local Now = os.clock()
    if Runtime.EdgeCheckPosition and Runtime.EdgeCheckDirection.Magnitude > 0.05
        and Now - Runtime.EdgeCheckAt < 0.055
        and Flat(Position - Runtime.EdgeCheckPosition).Magnitude < 2.5
        and Runtime.EdgeCheckDirection:Dot(Dir) > 0.96
        and Runtime.EdgeCheckGoal.Magnitude > 0.05
        and Flat(Goal - Runtime.EdgeCheckGoal).Magnitude < 8 then
        return Runtime.EdgeDirection, Runtime.EdgeRisk
    end

    local Boundary = BoundaryInwardDirection(Position, Y)
    local DesiredRisk = EdgeRiskForDirection(Position, Dir, Y)
    local NearBoundary = Boundary.Magnitude > 0.05 and Boundary:Dot(Dir) < 0.35

    Runtime.EdgeCheckAt = Now
    Runtime.EdgeCheckPosition = Position
    Runtime.EdgeCheckDirection = Dir
    Runtime.EdgeCheckGoal = Flat(Goal)

    if not DesiredRisk and not NearBoundary then
        Runtime.EdgeDirection = Dir
        Runtime.EdgeRisk = false
        return Dir, false
    end

    local ToGoal = Flat(Goal - Position)
    if ToGoal.Magnitude < 0.05 then
        ToGoal = Dir
    else
        ToGoal = ToGoal.Unit
    end

    local Inward = Boundary
    if Inward.Magnitude < 0.05 then
        local Center = GetPlayfieldCenter()
        if Center then
            Inward = Flat(Center - Position)
            if Inward.Magnitude > 0.05 then
                Inward = Inward.Unit
            end
        end
    end

    local Candidates = {}
    local function AddCandidate(V)
        V = Flat(V)
        if V.Magnitude < 0.05 then
            return
        end
        V = V.Unit
        for _, Item in ipairs(Candidates) do
            if Item:Dot(V) > 0.985 then
                return
            end
        end
        Candidates[#Candidates + 1] = V
    end

    AddCandidate(Inward)
    AddCandidate(ToGoal)
    AddCandidate(Dir)
    local Base = Inward.Magnitude > 0.05 and Inward or Dir
    for _, Angle in ipairs({-35, 35, -70, 70, 90, -90, 135, -135, 180}) do
        AddCandidate(RotateEdge(Base, Angle))
    end

    local Best = nil
    local BestScore = -math.huge
    for _, Candidate in ipairs(Candidates) do
        local Support = GroundSupportScore(Position, Candidate, Y)
        if Support >= 6 then
            local Score = Support * 4.5 + Candidate:Dot(ToGoal) * 5
            if Inward.Magnitude > 0.05 then
                Score += Candidate:Dot(Inward) * (NearBoundary and 10 or 5)
            end
            if Candidate:Dot(Dir) > 0 then
                Score += 2
            end
            if Score > BestScore then
                BestScore = Score
                Best = Candidate
            end
        end
    end

    if Best then
        Runtime.EdgeDirection = Best
        Runtime.EdgeRisk = true
        Runtime.EdgeRecoveryAt = Now
        return Best, true
    end

    if Inward.Magnitude > 0.05 then
        Runtime.EdgeDirection = Inward
        Runtime.EdgeRisk = true
        Runtime.EdgeRecoveryAt = Now
        return Inward, true
    end

    Runtime.EdgeDirection = -Dir
    Runtime.EdgeRisk = true
    Runtime.EdgeRecoveryAt = Now
    return -Dir, true
end

local function FindZone(Parent, Names)
    for _, Name in ipairs(Names) do
        local Direct = Parent:FindFirstChild(Name)
        if Direct then
            return Direct
        end
    end
    for _, Obj in ipairs(Parent:GetDescendants()) do
        local Lower = Obj.Name:lower()
        for _, Name in ipairs(Names) do
            if Lower == Name:lower() then
                return Obj
            end
        end
    end
    return nil
end

local function GetBounds(Instance)
    if not Instance then
        return nil
    end
    local MinP = Vector3.new(math.huge, math.huge, math.huge)
    local MaxP = Vector3.new(-math.huge, -math.huge, -math.huge)
    local Found = false
    local function Add(Part)
        local P = Part.Position
        local H = Part.Size * 0.5
        MinP = Vector3.new(
            math.min(MinP.X, P.X - H.X),
            math.min(MinP.Y, P.Y - H.Y),
            math.min(MinP.Z, P.Z - H.Z)
        )
        MaxP = Vector3.new(
            math.max(MaxP.X, P.X + H.X),
            math.max(MaxP.Y, P.Y + H.Y),
            math.max(MaxP.Z, P.Z + H.Z)
        )
        Found = true
    end
    if Instance:IsA("BasePart") then
        Add(Instance)
    end
    for _, Obj in ipairs(Instance:GetDescendants()) do
        if Obj:IsA("BasePart") then
            Add(Obj)
        end
    end
    if not Found then
        return nil
    end
    return MinP, MaxP
end

local function BuildZone(Instance)
    local MinP, MaxP = GetBounds(Instance)
    if not MinP then
        return nil
    end
    return {
        Instance = Instance,
        Name = Instance.Name,
        Min = MinP,
        Max = MaxP,
        Center = (MinP + MaxP) * 0.5,
    }
end

local function RefreshSafezones()
    local Map = GetMap()
    if Safezone.Cached and Safezone.Map == Map
        and Safezone.A and Safezone.B
        and Safezone.A.Instance and Safezone.A.Instance.Parent
        and Safezone.B.Instance and Safezone.B.Instance.Parent then
        return
    end
    Safezone.Map = Map
    Safezone.A = nil
    Safezone.B = nil
    Safezone.Cached = true
    local Field = Map and Map:FindFirstChild("Field")
    if not Field then
        return
    end
    local A = FindZone(Field, {"SafezoneASide", "SafeZoneASide"})
    local B = FindZone(Field, {"SafezoneBSide", "SafeZoneBSide"})
    Safezone.A = BuildZone(A)
    Safezone.B = BuildZone(B)
end

local function InZone(Position, Zone)
    if not Zone then
        return false
    end
    return Position.X >= Zone.Min.X
        and Position.X <= Zone.Max.X
        and Position.Z >= Zone.Min.Z
        and Position.Z <= Zone.Max.Z
        and Position.Y >= Zone.Min.Y - 8
        and Position.Y <= Zone.Max.Y + 8
end

local function CurrentZone(Position)
    if InZone(Position, Safezone.A) then
        return Safezone.A
    end
    if InZone(Position, Safezone.B) then
        return Safezone.B
    end
    return nil
end

local function ZoneInwardDirection(Zone, Other)
    if not Zone then
        return Vector3.zero
    end
    local Delta = Other and Flat(Zone.Center - Other.Center) or Vector3.zero
    if Delta.Magnitude > 0.05 then
        if math.abs(Delta.X) >= math.abs(Delta.Z) then
            return Vector3.new(Delta.X >= 0 and 1 or -1, 0, 0)
        end
        return Vector3.new(0, 0, Delta.Z >= 0 and 1 or -1)
    end
    if Zone.Instance and Zone.Instance:IsA("BasePart") then
        local Look = Flat(Zone.Instance.CFrame.LookVector)
        if Look.Magnitude > 0.05 then
            if math.abs(Look.X) >= math.abs(Look.Z) then
                return Vector3.new(Look.X >= 0 and 1 or -1, 0, 0)
            end
            return Vector3.new(0, 0, Look.Z >= 0 and 1 or -1)
        end
    end
    return Vector3.zero
end

local function ZoneAxisHalfExtent(Zone, Inward)
    if not Zone then
        return 0
    end
    local Size = Zone.Max - Zone.Min
    if math.abs(Inward.X) >= math.abs(Inward.Z) then
        return math.abs(Size.X) * 0.5
    end
    return math.abs(Size.Z) * 0.5
end

local function ZoneDeepPoint(Zone, Other, Y)
    if not Zone then
        return nil
    end
    local Inward = ZoneInwardDirection(Zone, Other)
    local Half = ZoneAxisHalfExtent(Zone, Inward)
    local EdgeMargin = math.min(Settings.SafezoneEdgeMargin, math.max(0, Half - 0.75))
    local Depth = math.min(math.max(0, Half - EdgeMargin), Half * Settings.SafezoneDepthRatio)
    local XMargin = math.min(EdgeMargin, math.max(0, (Zone.Max.X - Zone.Min.X) * 0.5 - 0.75))
    local ZMargin = math.min(EdgeMargin, math.max(0, (Zone.Max.Z - Zone.Min.Z) * 0.5 - 0.75))
    local Ratios = {Settings.SafezoneDepthRatio, 0.46, 0.40, 0.34}
    for _, Ratio in ipairs(Ratios) do
        local CandidateDepth = math.min(math.max(0, Half - EdgeMargin), Half * Ratio)
        local Point = Zone.Center + Inward * CandidateDepth
        Point = Vector3.new(
            math.clamp(Point.X, Zone.Min.X + XMargin, Zone.Max.X - XMargin),
            Y,
            math.clamp(Point.Z, Zone.Min.Z + ZMargin, Zone.Max.Z - ZMargin)
        )
        if EdgeDirectionClear(Point, Inward, Y, 6) and EdgeDirectionClear(Point, -Inward, Y, 4) then
            return Point
        end
    end
    local Point = Zone.Center + Inward * Depth
    return Vector3.new(
        math.clamp(Point.X, Zone.Min.X + XMargin, Zone.Max.X - XMargin),
        Y,
        math.clamp(Point.Z, Zone.Min.Z + ZMargin, Zone.Max.Z - ZMargin)
    )
end

local function InValidatedZone(Position, Zone, Other)
    if not Zone or not InZone(Position, Zone) then
        return false
    end
    local Inward = ZoneInwardDirection(Zone, Other)
    if Inward.Magnitude < 0.05 then
        return false
    end
    local Half = ZoneAxisHalfExtent(Zone, Inward)
    local Margin = math.min(Settings.SafezoneEdgeMargin, math.max(0, Half - 0.75))
    local XOk = Position.X >= Zone.Min.X + Margin and Position.X <= Zone.Max.X - Margin
    local ZOk = Position.Z >= Zone.Min.Z + Margin and Position.Z <= Zone.Max.Z - Margin
    if not XOk or not ZOk then
        return false
    end
    local Depth = Flat(Position - Zone.Center):Dot(Inward)
    local Required = math.min(math.max(0, Half - Margin), Half * Settings.SafezoneValidationRatio)
    return Depth >= Required and HasFloorAt(Position, Position.Y)
end

local function ZoneCenter(Zone, Y)
    if not Zone then
        return nil
    end
    return Vector3.new(Zone.Center.X, Y, Zone.Center.Z)
end

local function DetectRoundStartZone(Position, A, B)
    local InA = InZone(Position, A)
    local InB = InZone(Position, B)
    if InA and not InB then
        return A
    end
    if InB and not InA then
        return B
    end
    local Da = Flat(Position - A.Center).Magnitude
    local Db = Flat(Position - B.Center).Magnitude
    return Da <= Db and A or B
end

local function BeginRunnerRound(Position)
    RefreshSafezones()
    local A = Safezone.A
    local B = Safezone.B
    if not A or not B then
        Runtime.RouteActive = false
        Runtime.RouteComplete = false
        Runtime.RouteStartSide = nil
        Runtime.RouteTargetSide = nil
        Runtime.RouteCompletePosition = nil
        Runtime.RouteCompleteAt = -math.huge
        Runtime.GoalSide = nil
        Runtime.Goal = nil
        return nil, nil
    end

    local Start = DetectRoundStartZone(Position, A, B)
    local Target = Start == A and B or A

    Runtime.RouteActive = true
    Runtime.RouteComplete = false
    Runtime.RouteStartSide = Start.Name
    Runtime.RouteTargetSide = Target.Name
    Runtime.RouteCompletePosition = nil
    Runtime.RouteCompleteAt = -math.huge
    Runtime.GoalSide = Target.Name
    Runtime.Goal = ZoneDeepPoint(Target, Start, Position.Y) or ZoneCenter(Target, Position.Y)
    Runtime.SafeCheckAt = -math.huge
    Runtime.SafeCheckPosition = nil
    return Runtime.Goal, Target
end

local function ChooseSafeGoal(Position)
    RefreshSafezones()
    local A = Safezone.A
    local B = Safezone.B
    if not A or not B then
        Runtime.Goal = nil
        Runtime.GoalSide = nil
        Runtime.RouteActive = false
        Runtime.RouteComplete = false
        Runtime.RouteStartSide = nil
        Runtime.RouteTargetSide = nil
        Runtime.RouteCompletePosition = nil
        Runtime.RouteCompleteAt = -math.huge
        return nil, nil
    end

    if not Runtime.RouteActive or not Runtime.RouteTargetSide then
        return BeginRunnerRound(Position)
    end

    if Runtime.RouteComplete then
        return nil, nil
    end

    local Now = os.clock()
    if not Runtime.SafeCheckPosition
        or Now - Runtime.SafeCheckAt >= 0.08
        or Flat(Position - Runtime.SafeCheckPosition).Magnitude >= 2.0 then
        Runtime.SafeCheckAt = Now
        Runtime.SafeCheckPosition = Position
        Runtime.SafeCheckA = InValidatedZone(Position, A, B)
        Runtime.SafeCheckB = InValidatedZone(Position, B, A)
    end

    local Target = Runtime.RouteTargetSide == A.Name and A or B
    local Other = Target == A and B or A

    if (Target == A and Runtime.SafeCheckA) or (Target == B and Runtime.SafeCheckB) then
        Runtime.RouteComplete = true
        Runtime.RouteCompletePosition = Position
        Runtime.RouteCompleteAt = Now
        Runtime.Goal = nil
        Runtime.GoalSide = Target.Name
        return nil, Target
    end

    Runtime.GoalSide = Target.Name
    if not Runtime.Goal then
        Runtime.Goal = ZoneDeepPoint(Target, Other, Position.Y) or ZoneCenter(Target, Position.Y)
    else
        Runtime.Goal = Vector3.new(Runtime.Goal.X, Position.Y, Runtime.Goal.Z)
    end

    return Runtime.Goal, Target
end

local function GetSafeFallback(Position)
    RefreshSafezones()
    local A = Safezone.A
    local B = Safezone.B
    if not A or not B then
        return nil
    end
    local Target
    if Runtime.RouteTargetSide == A.Name then
        Target = A
    elseif Runtime.RouteTargetSide == B.Name then
        Target = B
    elseif Runtime.GoalSide == A.Name then
        Target = A
    elseif Runtime.GoalSide == B.Name then
        Target = B
    elseif InZone(Position, A) and not InZone(Position, B) then
        Target = B
    elseif InZone(Position, B) and not InZone(Position, A) then
        Target = A
    else
        Target = B
    end
    return ZoneDeepPoint(Target, Target == A and B or A, Position.Y) or ZoneCenter(Target, Position.Y)
end

local function IsGemObject(Obj)
    local Name = Obj.Name:lower()
    return Obj:IsA("BasePart") and (
        Name:sub(1, 4) == "gem_"
        or Name == "gem"
        or Name == "gems"
        or Name:find("gempickup", 1, true) ~= nil
    )
end

local function RefreshGems(Now, Position)
    if Now - Runtime.GemScanAt < Settings.GemScanInterval then
        return
    end
    Runtime.GemScanAt = Now
    local Folder = workspace:FindFirstChild("LocalRunnerGems")
    local Best, BestDistance
    if Folder then
        for _, Obj in ipairs(Folder:GetChildren()) do
            if IsGemObject(Obj) and Obj.Parent then
                local D = Flat(Obj.Position - Position).Magnitude
                local Ignored = Runtime.GemIgnored[Obj]
                if D <= Settings.GemMaxDistance and (not Ignored or Now >= Ignored) then
                    if not BestDistance or D < BestDistance then
                        Best = Obj
                        BestDistance = D
                    end
                end
            end
        end
    end
    if not Best then
        local Generic = workspace:FindFirstChild("Gems") or workspace:FindFirstChild("Gem")
        if Generic then
            for _, Obj in ipairs(Generic:GetDescendants()) do
                if IsGemObject(Obj) and Obj.Parent then
                    local D = Flat(Obj.Position - Position).Magnitude
                    local Ignored = Runtime.GemIgnored[Obj]
                    if D <= Settings.GemMaxDistance and (not Ignored or Now >= Ignored) then
                        if not BestDistance or D < BestDistance then
                            Best = Obj
                            BestDistance = D
                        end
                    end
                end
            end
        end
    end
    Runtime.GemTarget = Best
end

local function FindDownedPlayer(Position)
    local Best, BestDistance
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Parent then
            local C = Player.Character
            local Root = C and C:FindFirstChild("HumanoidRootPart")
            if Root and C:GetAttribute("RescueAvailable") == true and C:GetAttribute("Ragdolled") == true then
                local Helper = C:GetAttribute("RescueHelperId")
                if Helper == nil or Helper == LocalPlayer.UserId then
                    local D = Flat(Root.Position - Position).Magnitude
                    if D <= Settings.ReviveMaxDistance and (not BestDistance or D < BestDistance) then
                        Best = Player
                        BestDistance = D
                    end
                end
            end
        end
    end
    return Best
end

local function CancelRevive()
    if Runtime.ReviveTarget and Runtime.ReviveStarted then
        pcall(function()
            RescueEvent:FireServer("Cancel", Runtime.ReviveTarget.UserId)
        end)
    end
    Runtime.ReviveTarget = nil
    Runtime.ReviveStarted = false
    Runtime.ReviveStartAt = 0
end

local function HasReviveLineOfSight(Target)
    local MyRoot = GetRoot()
    local TargetRoot = Target and GetRoot(Target)
    if not MyRoot or not TargetRoot then
        return false
    end
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {MyRoot.Parent, TargetRoot.Parent}
    Params.RespectCanCollide = true
    local Ok, Result = pcall(function()
        return workspace:Raycast(MyRoot.Position, TargetRoot.Position - MyRoot.Position, Params)
    end)
    return Ok and Result == nil
end

local function UpdateRevive(Now, Position)
    if not Settings.AutoRevive then
        CancelRevive()
        return nil
    end
    local Target = Runtime.ReviveTarget
    local Root = Target and GetRoot(Target)
    if not Target or not Target.Parent or not Root or Target.Character:GetAttribute("RescueAvailable") ~= true or Target.Character:GetAttribute("Ragdolled") ~= true then
        CancelRevive()
        Target = nil
    end
    if not Target then
        Target = FindDownedPlayer(Position)
        if not Target then
            return nil
        end
        Runtime.ReviveTarget = Target
    end
    Root = GetRoot(Target)
    if not Root then
        CancelRevive()
        return nil
    end
    Runtime.GoalMode = "Revive"
    local Distance = Flat(Root.Position - Position).Magnitude
    if Distance > math.max(RescueRange, Settings.ReviveMaxDistance) then
        CancelRevive()
        return nil
    end
    if Distance <= RescueRange then
        if not Runtime.ReviveStarted and Now < Runtime.ReviveStartAt then
            return Root.Position
        end
        if HasReviveLineOfSight(Target) then
            if not Runtime.ReviveStarted then
                Runtime.ReviveStarted = true
                Runtime.ReviveStartAt = Now
                pcall(function()
                    RescueEvent:FireServer("Begin", Target.UserId)
                end)
            elseif Now - Runtime.ReviveStartAt >= RescueHold then
                pcall(function()
                    RescueEvent:FireServer("Finish", Target.UserId)
                end)
                Runtime.ReviveStarted = false
                Runtime.ReviveStartAt = Now + RescueFinishGrace + 0.5
            end
        end
    else
        if Runtime.ReviveStarted then
            CancelRevive()
        end
    end
    return Root.Position
end

local function RefreshCatchers(Now)
    if Now - Runtime.CatcherCacheAt < 0.12 then
        return
    end
    Runtime.CatcherCacheAt = Now
    local List = Runtime.Catchers
    table.clear(List)
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Parent and Player:GetAttribute("GameRole") == "Catcher" and Player:GetAttribute("RunState") == "Active" then
            local C = Player.Character
            local H = C and C:FindFirstChildOfClass("Humanoid")
            local R = C and C:FindFirstChild("HumanoidRootPart")
            if H and H.Health > 0 and R and C:GetAttribute("Ragdolled") ~= true and C:GetAttribute("MovementLocked") ~= true then
                List[#List + 1] = Player
            end
        end
    end
end

local function UpdateThreats(Now, Position)
    if Now - Runtime.ThreatAt < 0.045 then
        return Runtime.Threats
    end
    Runtime.ThreatAt = Now
    table.clear(Runtime.Threats)
    local RunRoot = GetRoot()
    local RunVelocity = RunRoot and Flat(RunRoot.AssemblyLinearVelocity) or Vector3.zero
    local RunSpeed = math.max(GetRunnerSpeed(), 1)
    if RunVelocity.Magnitude < 3 and Runtime.Path.Magnitude > 0.05 then
        RunVelocity = Runtime.Path.Unit * RunSpeed
    end

    local NowServer = 0
    pcall(function()
        NowServer = workspace:GetServerTimeNow()
    end)

    for _, Player in ipairs(Runtime.Catchers) do
        local Root = GetRoot(Player)
        if Root then
            local Current = Flat(Root.Position)
            local Offset = Current - Position
            local Distance = Offset.Magnitude
            if Distance <= 105 then
                local Velocity = Flat(Root.AssemblyLinearVelocity)
                local History = Runtime.ThreatHistory[Player]
                if not History then
                    History = {Position = Current, Velocity = Velocity, Time = Now}
                    Runtime.ThreatHistory[Player] = History
                end
                local HistoryDt = Now - History.Time
                local Acceleration = Vector3.zero
                if HistoryDt > 0.025 and HistoryDt < 0.25 then
                    Acceleration = (Velocity - History.Velocity) / HistoryDt
                    if Acceleration.Magnitude > 70 then
                        Acceleration = Acceleration.Unit * 70
                    end
                end
                History.Position = Current
                History.Velocity = Velocity
                History.Time = Now

                local Relative = Current - Position
                local RelativeVelocity = Velocity - RunVelocity
                local RelSpeedSq = RelativeVelocity:Dot(RelativeVelocity)
                local ClosestTime = 0
                if RelSpeedSq > 0.25 then
                    ClosestTime = math.clamp(-Relative:Dot(RelativeVelocity) / RelSpeedSq, 0, 1.8)
                end

                local Prediction = math.clamp(Settings.PredictionTime + Runtime.Ping * 0.85, 0.28, 1.15)
                local VelocityFactor = math.clamp(Velocity.Magnitude / math.max(RunSpeed, 1), 0.65, 1.25)
                Prediction = math.clamp(Prediction * VelocityFactor, 0.28, 1.15)
                local Character = Player.Character
                local Tackle = Character and Character:GetAttribute("TackleActive") == true
                local TackleDirection = Character and Character:GetAttribute("TackleDirection")
                if typeof(TackleDirection) ~= "Vector3" then
                    TackleDirection = Vector3.zero
                end
                TackleDirection = Flat(TackleDirection)
                if TackleDirection.Magnitude < 0.05 then
                    TackleDirection = Velocity
                end
                if TackleDirection.Magnitude < 0.05 then
                    TackleDirection = Flat(Root.CFrame.LookVector)
                end
                if TackleDirection.Magnitude > 0.05 then
                    TackleDirection = TackleDirection.Unit
                end

                if Tackle then
                    Prediction = math.min(1.8, Prediction + 0.32)
                end

                local RelativeFuture = Relative + RelativeVelocity * Prediction + Acceleration * (0.5 * Prediction * Prediction)
                local FutureDistance = RelativeFuture.Magnitude

                local Danger = math.max(8, tonumber(ContactCatchConfig.MinForward) or 0)
                    + math.max(0, tonumber(ContactCatchConfig.HandRadius) or 0)
                    + math.max(0, tonumber(ContactCatchConfig.ContactPadding) or 0)
                    + math.max(0, tonumber(ContactCatchConfig.RunnerRadius) or 0)
                if Tackle then
                    local Reach = tonumber(Character:GetAttribute("TackleReach")) or 0
                    Danger += 8 + math.min(Reach, 8)
                elseif Velocity.Magnitude > RunSpeed * 0.8 then
                    Danger += 2
                end

                local Closing = 0
                if Distance > 0.05 then
                    Closing = math.max(0, Velocity:Dot(-Offset.Unit))
                end
                local TimeToDanger = math.huge
                if Closing > 0.5 then
                    TimeToDanger = math.max(0, (Distance - Danger) / Closing)
                elseif Distance <= Danger then
                    TimeToDanger = 0
                end

                local InterceptTime = math.min(ClosestTime, Prediction)
                if TimeToDanger < InterceptTime then
                    InterceptTime = TimeToDanger
                end

                local InterceptCatcher = Current + Velocity * InterceptTime + Acceleration * (0.5 * InterceptTime * InterceptTime)
                local InterceptRunner = Position + RunVelocity * InterceptTime
                local InterceptGap = Flat(InterceptCatcher - InterceptRunner).Magnitude
                local Predicted = Current + Velocity * Prediction + Acceleration * (0.5 * Prediction * Prediction)

                if Tackle and TackleDirection.Magnitude > 0.05 then
                    local Duration = tonumber(Character:GetAttribute("TackleDuration")) or 0.45
                    local Started = tonumber(Character:GetAttribute("TackleStartedAt")) or 0
                    local Elapsed = NowServer > 0 and math.max(0, NowServer - Started) or 0
                    local ActiveTime = math.clamp(Duration - Elapsed, 0, Prediction)
                    local DashSpeed = math.max(Velocity.Magnitude, RunSpeed * 2.2)
                    local TackleTravel = math.min(DashSpeed * ActiveTime, Danger + 18)
                    Predicted = Current + TackleDirection * TackleTravel
                    local TackleTime = math.min(InterceptTime, ActiveTime)
                    InterceptCatcher = Current + TackleDirection * math.min(DashSpeed * TackleTime, Danger + 18)
                    InterceptGap = Flat(InterceptCatcher - InterceptRunner).Magnitude
                end

                local CollisionRisk = TimeToDanger <= math.min(Prediction + 0.04, 0.72)
                    or InterceptGap <= Danger * 1.35
                    or (Tackle and InterceptGap <= Danger * 2.15)
                local PreTackle = Closing >= math.max(6.5, RunSpeed * 0.34) and Distance <= 50
                Runtime.Threats[#Runtime.Threats + 1] = {
                    Player = Player,
                    Root = Root,
                    Position = Current,
                    Velocity = Velocity,
                    Acceleration = Acceleration,
                    Distance = Distance,
                    Closing = Closing,
                    Predicted = Predicted,
                    Intercept = InterceptCatcher,
                    InterceptRunner = InterceptRunner,
                    InterceptTime = math.max(0, InterceptTime),
                    InterceptGap = InterceptGap,
                    Danger = Danger,
                    Tackle = Tackle,
                    CollisionRisk = CollisionRisk,
                    PreTackle = PreTackle,
                    TimeToDanger = TimeToDanger,
                }
            end
        end
    end

    table.sort(Runtime.Threats, function(A, B)
        if A.CollisionRisk ~= B.CollisionRisk then
            return A.CollisionRisk
        end
        if A.TimeToDanger ~= B.TimeToDanger then
            return A.TimeToDanger < B.TimeToDanger
        end
        if A.Tackle ~= B.Tackle then
            return A.Tackle
        end
        if A.InterceptGap ~= B.InterceptGap then
            return A.InterceptGap < B.InterceptGap
        end
        return A.Distance < B.Distance
    end)

    for Player, History in pairs(Runtime.ThreatHistory) do
        if not Player.Parent or Now - History.Time > 1.2 then
            Runtime.ThreatHistory[Player] = nil
        end
    end
    return Runtime.Threats
end

local function Rotate(Dir, Angle)
    local R = math.rad(Angle)
    local C = math.cos(R)
    local S = math.sin(R)
    return Vector3.new(Dir.X * C - Dir.Z * S, 0, Dir.X * S + Dir.Z * C)
end

local function RouteClear(Position, Direction, Threats)
    if Direction.Magnitude < 0.05 then
        return -math.huge
    end
    local Dir = Direction.Unit
    local Speed = math.max(GetRunnerSpeed(), 1)
    local Clearance = math.huge
    local Samples = {0.10, 0.22, 0.36, 0.52, 0.70, 0.90}
    for _, T in ipairs(Samples) do
        local Runner = Position + Dir * Speed * T
        for _, Threat in ipairs(Threats) do
            local CatchPos
            if Threat.Tackle and Flat(Threat.Intercept - Threat.Position).Magnitude > 0.05 then
                local TackleDir = Flat(Threat.Intercept - Threat.Position).Unit
                local TackleTime = math.min(T, math.max(Threat.InterceptTime, 0.12))
                local TackleSpeed = math.max(Threat.Velocity.Magnitude, Speed * 2.2)
                CatchPos = Threat.Position + TackleDir * math.min(TackleSpeed * TackleTime, Threat.Danger + 18)
            else
                CatchPos = Threat.Position + Threat.Velocity * T + Threat.Acceleration * (0.5 * T * T)
            end
            local Safe = Flat(Runner - CatchPos).Magnitude - Threat.Danger
            if Safe < Clearance then
                Clearance = Safe
            end
        end
    end
    return Clearance
end

local function AddDirection(List, Direction)
    Direction = Flat(Direction)
    if Direction.Magnitude < 0.05 then
        return
    end
    Direction = Direction.Unit
    for _, Item in ipairs(List) do
        if Item:Dot(Direction) > 0.985 then
            return
        end
    end
    List[#List + 1] = Direction
end

local function CorridorAxes(Position, Goal)
    RefreshSafezones()
    local A = Safezone.A
    local B = Safezone.B
    if not A or not B then
        return nil, nil, nil
    end
    local Axis = Flat(B.Center - A.Center)
    if Axis.Magnitude < 0.05 then
        return nil, nil, nil
    end
    if math.abs(Axis.X) >= math.abs(Axis.Z) then
        Axis = Vector3.new(Axis.X >= 0 and 1 or -1, 0, 0)
    else
        Axis = Vector3.new(0, 0, Axis.Z >= 0 and 1 or -1)
    end
    local ToGoal = Flat(Goal - Position)
    if ToGoal.Magnitude > 0.05 and Axis:Dot(ToGoal) < 0 then
        Axis = -Axis
    end
    local Lateral = Vector3.new(-Axis.Z, 0, Axis.X)
    local Center = (A.Center + B.Center) * 0.5
    return Axis, Lateral, Center
end

local function ClearCorridorLock()
    Runtime.CorridorActive = false
    Runtime.CorridorGoal = Vector3.zero
    Runtime.CorridorCenter = Vector3.zero
    Runtime.CorridorAxis = Vector3.zero
    Runtime.CorridorGapWidth = 0
    Runtime.CorridorStartedAt = -math.huge
end

local function FindCorridorGoal(Position, Goal, Threats, Now)
    if not Settings.CorridorEnabled or #Threats < 2 then
        ClearCorridorLock()
        return nil
    end

    local Axis, Lateral, Center = CorridorAxes(Position, Goal)
    if not Axis then
        ClearCorridorLock()
        return nil
    end

    local ForwardDistance = (Center - Position):Dot(Axis)
    if ForwardDistance < -12 or ForwardDistance > Settings.CorridorApproachDistance then
        ClearCorridorLock()
        return nil
    end

    local LineLat = Center:Dot(Lateral)
    local Blockers = {}
    for _, Threat in ipairs(Threats) do
        local Longitudinal = math.abs((Threat.Position - Center):Dot(Axis))
        local LateralPos = (Threat.Position - Center):Dot(Lateral)
        if Longitudinal <= Settings.CorridorCenterRange and Threat.Distance <= 100 then
            Blockers[#Blockers + 1] = {
                Threat = Threat,
                Lateral = LateralPos,
                Buffer = math.clamp(Threat.Danger * 0.38, 2.25, 5.25),
            }
        end
    end
    if #Blockers < 2 then
        if Runtime.CorridorActive and Now - Runtime.CorridorStartedAt <= Settings.CorridorLockTime then
            return Runtime.CorridorGoal
        end
        ClearCorridorLock()
        return nil
    end

    table.sort(Blockers, function(X, Y)
        return X.Lateral < Y.Lateral
    end)

    local BestCenter = nil
    local BestWidth = -math.huge
    local BestScore = -math.huge
    local Low = math.huge
    local High = -math.huge
    for _, Item in ipairs(Blockers) do
        Low = math.min(Low, Item.Lateral - Item.Buffer)
        High = math.max(High, Item.Lateral + Item.Buffer)
    end

    local Gaps = {}
    for I = 1, #Blockers - 1 do
        local Left = Blockers[I].Lateral + Blockers[I].Buffer
        local Right = Blockers[I + 1].Lateral - Blockers[I + 1].Buffer
        if Right > Left then
            Gaps[#Gaps + 1] = {Left = Left, Right = Right, Center = (Left + Right) * 0.5}
        end
    end

    local LateralMin = math.min(Low - 9, LineLat - 28)
    local LateralMax = math.max(High + 9, LineLat + 28)
    if Blockers[1].Lateral - Blockers[1].Buffer > LateralMin then
        Gaps[#Gaps + 1] = {
            Left = LateralMin,
            Right = Blockers[1].Lateral - Blockers[1].Buffer,
            Center = (LateralMin + Blockers[1].Lateral - Blockers[1].Buffer) * 0.5,
        }
    end
    if Blockers[#Blockers].Lateral + Blockers[#Blockers].Buffer < LateralMax then
        Gaps[#Gaps + 1] = {
            Left = Blockers[#Blockers].Lateral + Blockers[#Blockers].Buffer,
            Right = LateralMax,
            Center = (Blockers[#Blockers].Lateral + Blockers[#Blockers].Buffer + LateralMax) * 0.5,
        }
    end

    for _, Gap in ipairs(Gaps) do
        local Width = Gap.Right - Gap.Left
        if Width >= Settings.CorridorMinWidth then
            local LateralOffset = Gap.Center - LineLat
            local LinePoint = Center + Lateral * LateralOffset
            local AheadPoint = LinePoint + Axis * Settings.CorridorPassDistance
            local EntryPoint = LinePoint - Axis * math.min(12, math.max(6, ForwardDistance * 0.15))
            local EntryClear = RouteClear(Position, Flat(EntryPoint - Position), Threats)
            local PassClear = RouteClear(Position, Flat(AheadPoint - Position), Threats)
            local EdgeSafe = EdgeDirectionClear(LinePoint - Axis * 4, Axis, Position.Y, 8)
            local Centrality = 1 - math.min(math.abs(LateralOffset) / 28, 1)
            local Score = Width * 2.8 + Centrality * 6 + math.min(PassClear, 15) * 1.4 + math.min(EntryClear, 10)
            if EdgeSafe then
                Score += 4
            else
                Score -= 6
            end
            if PassClear < -1.5 or EntryClear < -1.5 then
                Score -= 20
            end
            if Score > BestScore then
                BestScore = Score
                BestCenter = Gap.Center
                BestWidth = Width
            end
        end
    end

    if not BestCenter then
        if Runtime.CorridorActive and Now - Runtime.CorridorStartedAt <= Settings.CorridorLockTime then
            local LockedProgress = (Position - Runtime.CorridorCenter):Dot(Runtime.CorridorAxis)
            if LockedProgress > -8 and LockedProgress < Settings.CorridorPassDistance + 10 then
                return Runtime.CorridorGoal
            end
        end
        ClearCorridorLock()
        return nil
    end

    if Runtime.CorridorActive then
        local SameAxis = Runtime.CorridorAxis:Dot(Axis) > 0.98
        local SameCenter = math.abs((Runtime.CorridorCenter - Center):Dot(Lateral) - (BestCenter - LineLat)) <= 5
        local Progress = (Position - Runtime.CorridorCenter):Dot(Runtime.CorridorAxis)
        if SameAxis and SameCenter and Progress > -10 and Progress < Settings.CorridorPassDistance + 12 then
            return Runtime.CorridorGoal
        end
    end

    local GapOffset = BestCenter - LineLat
    local LinePoint = Center + Lateral * GapOffset
    local PassPoint = LinePoint + Axis * Settings.CorridorPassDistance
    Runtime.CorridorActive = true
    Runtime.CorridorGoal = Vector3.new(PassPoint.X, Position.Y, PassPoint.Z)
    Runtime.CorridorCenter = LinePoint
    Runtime.CorridorAxis = Axis
    Runtime.CorridorGapWidth = BestWidth
    Runtime.CorridorStartedAt = Now
    return Runtime.CorridorGoal
end

local function CorridorDirection(Position, Goal, Threats)
    local Desired = Flat(Goal - Position)
    if Desired.Magnitude < 0.05 then
        return Vector3.zero
    end
    Desired = Desired.Unit
    local Candidates = {}
    if Runtime.SideGapDirection.Magnitude > 0.05 and os.clock() < Runtime.SideGapUntil then
        AddDirection(Candidates, Runtime.SideGapDirection)
    end
    AddDirection(Candidates, Desired)
    for _, Angle in ipairs({12, -12, 24, -24, 38, -38, 52, -52, 70, -70, 90, -90}) do
        AddDirection(Candidates, Rotate(Desired, Angle))
    end
    local Best = Desired
    local BestScore = -math.huge
    for _, Candidate in ipairs(Candidates) do
        local Progress = Candidate:Dot(Desired)
        if Progress >= -0.05 then
            local Clearance = RouteClear(Position, Candidate, Threats)
            local Score = Progress * 8 + math.min(Clearance, 16) * 2.2
            if Clearance < 0 then
                Score -= math.abs(Clearance) * 16
            elseif Clearance < 4 then
                Score -= (4 - Clearance) * 7
            end
            if Score > BestScore then
                BestScore = Score
                Best = Candidate
            end
        end
    end
    return Best.Unit
end

local function ChooseSideGapDirection(Position, Desired, Threats)
    if not Settings.SideGapEnabled or #Threats == 0 then
        return nil, nil, -math.huge
    end
    local Front = Flat(Desired)
    if Front.Magnitude < 0.05 then
        return nil, nil, -math.huge
    end
    Front = Front.Unit
    local Lateral = Vector3.new(-Front.Z, 0, Front.X)

    local Nearest = nil
    local NearestDistance = math.huge
    for _, Threat in ipairs(Threats) do
        local Rel = Flat(Threat.Predicted - Position)
        if Rel.Magnitude > 0.05 then
            local Forward = Rel:Dot(Front)
            local LateralOffset = math.abs(Rel:Dot(Lateral))
            if Forward > 0 and Forward <= 34 and LateralOffset <= 16 and Threat.Distance < NearestDistance then
                Nearest = Threat
                NearestDistance = Threat.Distance
            end
        end
    end
    if not Nearest then
        return nil, nil, -math.huge
    end

    local Rel = Flat(Nearest.Predicted - Position)
    local ForwardGap = Rel:Dot(Front)
    local LateralOffset = Rel:Dot(Lateral)
    local FrontBlocked = ForwardGap > 0 and ForwardGap < math.max(12, Nearest.Danger * 2.2)
        and math.abs(LateralOffset) < 13
    if not FrontBlocked then
        return nil, nil, -math.huge
    end

    local Candidates = {}
    for _, Angle in ipairs(Settings.SideGapAngles) do
        local Rad = math.rad(Angle)
        local C = math.cos(Rad)
        local Sn = math.sin(Rad)
        local LeftDir = (Front * C + Lateral * Sn)
        local RightDir = (Front * C - Lateral * Sn)
        Candidates[#Candidates + 1] = {Dir = LeftDir.Unit, Side = "left"}
        Candidates[#Candidates + 1] = {Dir = RightDir.Unit, Side = "right"}
    end

    local Best, BestScore, BestSide = nil, -math.huge, nil
    for _, Item in ipairs(Candidates) do
        local Candidate = Item.Dir
        local Clearance = RouteClear(Position, Candidate, Threats)
        local Support = GroundSupportScore(Position, Candidate, Position.Y)
        local WallBlocked = InvisWallHit(Position, Candidate, 16) ~= nil
        if not WallBlocked and Support >= 3 and Clearance >= -1 then
            local ForwardProgress = Candidate:Dot(Front)
            local SideProgress = math.abs(Candidate:Dot(Lateral))
            local Score = ForwardProgress * Settings.SideGapForwardBias
                + SideProgress * 7
                + math.min(Clearance, 14) * 3.2
                + Support * 1.4
            local TowardCatcher = Rel:Dot(Lateral)
            local Away = Item.Side == "left" and -TowardCatcher or TowardCatcher
            Score += math.clamp(Away / 10, -1, 1) * 4
            if Clearance >= Settings.SideGapMinClearance then
                Score += 5
            end
            if Score > BestScore then
                Best = Candidate
                BestScore = Score
                BestSide = Item.Side
            end
        end
    end

    if Best then
        return Best, BestSide, BestScore
    end
    return nil, nil, -math.huge
end

local function ChooseRunnerDirection(Position, Goal, Threats)
    local Desired = Flat(Goal - Position)
    if Desired.Magnitude < 0.05 then
        return Vector3.zero
    end
    Desired = Desired.Unit
    local Strategy = GetRunnerStrategy()

    local SideGap, SideName = ChooseSideGapDirection(Position, Desired, Threats)
    if SideGap then
        Runtime.SideGapDirection = SideGap
        Runtime.SideGapUntil = os.clock() + Settings.SideGapCommitTime
        Runtime.SideGapReason = "front-blocked:" .. tostring(SideName)
        return SideGap
    elseif Runtime.SideGapDirection.Magnitude > 0.05 and os.clock() < Runtime.SideGapUntil then
        local Clear = RouteClear(Position, Runtime.SideGapDirection, Threats)
        if Clear >= 0 and not InvisWallHit(Position, Runtime.SideGapDirection, 14) then
            return Runtime.SideGapDirection
        end
    else
        Runtime.SideGapDirection = Vector3.zero
        Runtime.SideGapReason = ""
    end

    if not Settings.AvoidCatchers or #Threats == 0 then
        Runtime.SideGapDirection = Vector3.zero
        Runtime.SideGapUntil = -math.huge
        Runtime.SideGapReason = ""
        return Desired
    end

    local Candidates = {}
    AddDirection(Candidates, Desired)

    for _, Angle in ipairs({
        10, -10, 22, -22, 34, -34, 48, -48, 62, -62, 76, -76, 88, -88
    }) do
        AddDirection(Candidates, Rotate(Desired, Angle))
    end

    local Blocker = Threats[1]
    local NearestScore = math.huge
    for _, Threat in ipairs(Threats) do
        local ToThreat = Flat(Threat.Position - Position)
        local Ahead = ToThreat:Dot(Desired)
        local Distance = ToThreat.Magnitude
        if Ahead > 0 and Distance < NearestScore then
            NearestScore = Distance
            Blocker = Threat
        end
    end

    if Blocker then
        local ToBlocker = Flat(Blocker.Position - Position)
        if ToBlocker.Magnitude > 0.05 then
            local Lateral = Vector3.new(-Desired.Z, 0, Desired.X)
            local Side = ToBlocker:Dot(Lateral) >= 0 and -1 or 1
            AddDirection(Candidates, (Desired + Lateral * Side * 0.55).Unit)
            AddDirection(Candidates, (Desired + Lateral * Side * 0.95).Unit)
            AddDirection(Candidates, (Desired - Lateral * Side * 0.55).Unit)
            AddDirection(Candidates, (Desired - Lateral * Side * 0.95).Unit)
        end
    end

    if Runtime.Stuck then
        local Lateral = Vector3.new(-Desired.Z, 0, Desired.X)
        AddDirection(Candidates, Lateral)
        AddDirection(Candidates, -Lateral)
        local Center = GetPlayfieldCenter()
        if Center then
            AddDirection(Candidates, Flat(Center - Position))
        end
    end

    local Best = Desired
    local BestScore = -math.huge
    local Emergency = false
    local HighestUrgency = 0
    for _, Threat in ipairs(Threats) do
        local ThreatTime = tonumber(Threat.TimeToDanger) or math.huge
        local ThreatUrgency = math.clamp(
            1 - ThreatTime / math.max(Settings.DodgeThreatLookahead, 0.1),
            0,
            1
        )
        HighestUrgency = math.max(HighestUrgency, ThreatUrgency)
        if Threat.CollisionRisk or Threat.Tackle
            or (Threat.PreTackle and Threat.Closing > 0) then
            Emergency = true
            break
        end
    end

    for _, Candidate in ipairs(Candidates) do
        local Progress = Candidate:Dot(Desired)
        local Clearance = RouteClear(Position, Candidate, Threats)
        local WallBlocked = InvisWallHit(Position, Candidate, 18) ~= nil
        if WallBlocked then
            continue
        end

        if not Emergency and Progress < 0.04 then
            continue
        end

        local Score = Progress * (Strategy == "Chicken" and 8 or 10)
        local ClearanceWeight = Strategy == "Chicken" and 3.0 or 2.4
        Score += math.min(Clearance, 20) * ClearanceWeight * Settings.AvoidStrength

        if Clearance < 0 then
            Score -= math.abs(Clearance) * 18 * Settings.AvoidStrength
        elseif Clearance < 5 then
            Score -= (5 - Clearance) * 5 * Settings.AvoidStrength
        end

        if Progress > 0.18 and math.abs(Candidate:Dot(Desired)) < 0.96 then
            Score += math.min(math.max(Clearance, 0), 8) * 1.15
        end

        for _, Threat in ipairs(Threats) do
            local Away = Flat(Position - Threat.Intercept)
            if Away.Magnitude > 0.05 then
                local Urgency = math.clamp(
                    1 - math.min(
                        Threat.InterceptGap,
                        Threat.TimeToDanger * math.max(Threat.Closing, 1)
                    ) / math.max(Threat.Danger * 3, 1),
                    0,
                    1
                )
                local Weight = (Threat.CollisionRisk and 14 or 4.5) * Settings.AvoidStrength
                if Strategy == "Chicken" then
                    Weight *= 1.25
                end
                if Threat.Tackle then
                    Weight *= 1.45
                end
                Score += Candidate:Dot(Away.Unit) * Urgency * Weight
            end
        end

        if Runtime.EdgeRisk then
            local Inward = Runtime.EdgeDirection
            if Inward.Magnitude > 0.05 then
                Score += Candidate:Dot(Inward.Unit) * 7
            end
        end

        if Runtime.DodgeDirection.Magnitude > 0.05 and os.clock() < Runtime.DodgeUntil then
            Score += Candidate:Dot(Runtime.DodgeDirection) * (6 + HighestUrgency * 8)
        end

        if Score > BestScore then
            BestScore = Score
            Best = Candidate
        end
    end

    if Best.Magnitude < 0.05 then
        return Desired
    end
    if HighestUrgency >= 0.55 and Best.Magnitude > 0.05 then
        Runtime.DodgeDirection = Best.Unit
        Runtime.DodgeUntil = os.clock() + Settings.DodgeCommitTime
    elseif os.clock() >= Runtime.DodgeUntil then
        Runtime.DodgeDirection = Vector3.zero
    end
    return Best.Unit
end

local function ChooseDashDirection(Position, Direction, Threats)
    local Desired = Flat(Direction)
    local Root = GetRoot()
    if Desired.Magnitude < 0.05 and Root then
        Desired = Flat(Root.CFrame.LookVector)
    end
    if Desired.Magnitude < 0.05 then
        return Vector3.zero
    end
    Desired = Desired.Unit

    local Candidates = {}
    AddDirection(Candidates, Desired)
    for _, Angle in ipairs({
        18, -18, 32, -32, 48, -48, 64, -64, 82, -82, 90, -90
    }) do
        AddDirection(Candidates, Rotate(Desired, Angle))
    end

    if Runtime.EdgeRisk and Runtime.EdgeDirection.Magnitude > 0.05 then
        AddDirection(Candidates, Runtime.EdgeDirection)
        AddDirection(Candidates, Rotate(Runtime.EdgeDirection, 28))
        AddDirection(Candidates, Rotate(Runtime.EdgeDirection, -28))
    end

    local AwaySum = Vector3.zero
    for I = 1, math.min(6, #Threats) do
        local Threat = Threats[I]
        local Away = Flat(Position - Threat.Predicted)
        if Away.Magnitude > 0.05 then
            local Weight = math.clamp(1 - Threat.Distance / 60, 0.2, 1)
            if Threat.Tackle then
                Weight *= 2.2
            elseif Threat.PreTackle then
                Weight *= 1.5
            end
            AwaySum += Away.Unit * Weight
        end
    end
    if AwaySum.Magnitude > 0.05 then
        AddDirection(Candidates, AwaySum.Unit)
        AddDirection(Candidates, Rotate(AwaySum.Unit, 28))
        AddDirection(Candidates, Rotate(AwaySum.Unit, -28))
    end

    local Best = Desired
    local BestScore = -math.huge
    for _, Candidate in ipairs(Candidates) do
        local Clearance = RouteClear(Position, Candidate, Threats)
        local Progress = Candidate:Dot(Desired)
        local Score = Progress * 4.5 + math.min(Clearance, 20) * 5.0

        if Progress < -0.05 then
            Score -= 18
        end

        if Clearance < 0 then
            Score -= math.abs(Clearance) * 22
        elseif Clearance < 5 then
            Score -= (5 - Clearance) * 5
        end

        if AwaySum.Magnitude > 0.05 then
            Score += Candidate:Dot(AwaySum.Unit) * 7
        end

        if Runtime.EdgeRisk and Runtime.EdgeDirection.Magnitude > 0.05 then
            Score += Candidate:Dot(Runtime.EdgeDirection.Unit) * 10
        end

        for _, Threat in ipairs(Threats) do
            local Predicted = Threat.Predicted
            local DashPoint = Position + Candidate * math.min(GetRunnerSpeed() * 0.45, 11)
            local Gap = Flat(DashPoint - Predicted).Magnitude
            if Gap <= Threat.Danger * (Threat.Tackle and 1.55 or 1.2) then
                Score -= Threat.Tackle and 14 or 8
            end
        end

        if Score > BestScore then
            BestScore = Score
            Best = Candidate
        end
    end

    return Best.Unit
end

local function GetAbilityKey()
    local State = Runtime.Armory
    if type(State) ~= "table" or State.Loaded ~= true then
        return nil
    end

    local Candidates = {}
    local function Add(Value)
        if type(Value) ~= "string" or Value == "" then
            return
        end
        for I = 1, #Candidates do
            if Candidates[I] == Value then
                return
            end
        end
        Candidates[#Candidates + 1] = Value
    end

    local Ok, Value = pcall(GearCatalog.equippedForRole, State, "Runner")
    if Ok then Add(Value) end
    Ok, Value = pcall(GearCatalog.equippedForRole, "Runner", State)
    if Ok then Add(Value) end
    Ok, Value = pcall(GearCatalog.equippedForRole, "Runner")
    if Ok then Add(Value) end

    Add(State.EquippedAbility)
    Add(State.RunnerAbility)
    Add(State.RunnerAbility)

    local Equipped = State.Equipped or State.Equipped or State.Loadout or State.Loadout
    if type(Equipped) == "table" then
        Add(Equipped.Runner)
        Add(Equipped.Runner)
        Add(Equipped.Ability)
        Add(Equipped.Ability)
    end

    for I = 1, #Candidates do
        local Key = Candidates[I]
        local OkDef, Def = pcall(GearCatalog.get, Key)
        if OkDef and Def and Def.Kind == "Ability" then
            if (not Def.UseRole or Def.UseRole == "Runner")
                and type(State.Abilities) == "table"
                and State.Abilities[Key] == true then
                return Key
            end
        end
    end
    return nil
end

local function RequestDash(Direction, Now)
    if not Settings.AutoDash or not IsRunnerActive() then
        return false
    end

    local Character = GetCharacter()
    local Root = GetRoot()
    if not Character or not Root then
        Runtime.DashStatus = "no-character"
        return false
    end

    local Clock = os.clock()
    local CooldownUntil = tonumber(Character:GetAttribute("DashCooldownUntil")) or 0
    if Clock + math.max(0, tonumber(Settings.DashCooldownSlack) or 0) < CooldownUntil then
        Runtime.DashStatus = "cooldown"
        return false
    end

    local ProfileCooldown = GetRunnerDashCooldown()
    local LocalCooldown = math.max(0.05, ProfileCooldown - math.max(0, tonumber(Settings.DashCooldownSlack) or 0))
    if Now - Runtime.DashAt < LocalCooldown then
        Runtime.DashStatus = "local-cooldown"
        return false
    end

    local OkAvailable, Available = pcall(BoostInput.available, LocalPlayer)
    if not OkAvailable then
        Runtime.DashStatus = "available-error: " .. tostring(Available)
        return false
    end
    if Available ~= true then
        Runtime.DashStatus = "not-available"
        return false
    end

    local Hum = GetHumanoid()
    local Dir = Hum and Flat(Hum.MoveDirection) or Vector3.zero
    if Dir.Magnitude < 0.05 then
        Dir = Flat(Direction)
    end
    if Dir.Magnitude < 0.05 then
        Dir = Flat(Root.CFrame.LookVector)
    end
    if Dir.Magnitude < 0.05 then
        Runtime.DashStatus = "no-direction"
        return false
    end

    local BeforeCount = tonumber(Character:GetAttribute("DashCount")) or 0
    local OkRequest, Result = pcall(BoostInput.request, nil)
    Runtime.DashLastRequestAt = Now
    Runtime.DashLastCount = BeforeCount

    if not OkRequest then
        Runtime.DashStatus = "request-error: " .. tostring(Result)
        return false
    end
    if Result == false then
        Runtime.DashStatus = "request-rejected"
        return false
    end

    Runtime.DashAt = Now
    Runtime.DashStatus = "requested:waiting-game-client"
    return true
end

local function ShouldDash(Position, Threats, GoalDistance)
    if not Settings.AutoDash or not IsRunnerActive() then
        return false
    end

    local Now = os.clock()
    local Character = GetCharacter()
    local CooldownUntil = Character and tonumber(Character:GetAttribute("DashCooldownUntil")) or 0
    local Slack = math.max(0, tonumber(Settings.DashCooldownSlack) or 0)
    if CooldownUntil > Now + Slack then
        return false
    end
    local LocalCooldown = math.max(0.05, GetRunnerDashCooldown() - Slack)
    if Now - Runtime.DashAt < LocalCooldown then
        return false
    end

    if #Threats == 0 then
        return false
    end

    local NearestDistance = math.huge
    local NearestThreat = nil
    local ImmediateDanger = false
    local HardBlock = false
    local ImminentTime = math.huge

    for _, Threat in ipairs(Threats) do
        if Threat.Distance < NearestDistance then
            NearestDistance = Threat.Distance
            NearestThreat = Threat
        end
        local Gap = tonumber(Threat.InterceptGap) or math.huge
        local Danger = math.max(tonumber(Threat.Danger) or 4, 4)
        ImminentTime = math.min(ImminentTime, tonumber(Threat.TimeToDanger) or math.huge)

        if Threat.Tackle and (
            Gap <= Danger * 1.12
            or (Threat.TimeToDanger or math.huge) <= 0.38
            or Threat.Distance <= 10
        ) then
            ImmediateDanger = true
        elseif Threat.PreTackle and (
            Gap <= Danger * 1.05
            and (Threat.TimeToDanger or math.huge) <= 0.48
        ) then
            ImmediateDanger = true
        elseif Threat.CollisionRisk and (
            Gap <= Danger * 1.02
            and (Threat.TimeToDanger or math.huge) <= 0.42
        ) then
            ImmediateDanger = true
        end
    end

    local CurrentPath = Runtime.Path
    if CurrentPath.Magnitude > 0.05 then
        local PathClearance = RouteClear(Position, CurrentPath, Threats)
        if PathClearance < -2.0 and NearestDistance <= 18 then
            HardBlock = true
        end
    end

    if Runtime.SideGapDirection.Magnitude > 0.05
        and os.clock() < Runtime.SideGapUntil
        and NearestDistance <= 14 then
        local SideClearance = RouteClear(Position, Runtime.SideGapDirection, Threats)
        if SideClearance >= Settings.SideGapMinClearance and ImminentTime <= 0.55 then
            return true
        end
    end

    if ImmediateDanger then
        return true
    end

    if HardBlock and NearestDistance <= 15 and ImminentTime <= 0.55 then
        return true
    end

    if NearestThreat and NearestDistance <= 9 and ImminentTime <= 0.45 then
        return true
    end

    return false
end
local function RunnerGoal(Position, Now)
    Runtime.GoalMode = "SafeZone"
    local Goal = select(1, ChooseSafeGoal(Position))
    if not Goal and Settings.EmergencySafeZone then
        Goal = GetSafeFallback(Position)
    end
    Runtime.Goal = Goal
    return Goal
end

local function RouteDistance(Position, Goal, Target)
    local A = Flat(Position)
    local B = Flat(Goal)
    local P = Flat(Target)
    local Line = B - A
    local LengthSquared = Line:Dot(Line)
    if LengthSquared < 0.01 then
        return (P - A).Magnitude, 0
    end
    local T = math.clamp((P - A):Dot(Line) / LengthSquared, 0, 1)
    local Closest = A + Line * T
    return (P - Closest).Magnitude, T
end

local function ValidReviveTarget(Target)
    if not Target or not Target.Parent then
        return false
    end
    local Character = Target.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Root then
        return false
    end
    if Character:GetAttribute("RescueAvailable") ~= true or Character:GetAttribute("Ragdolled") ~= true then
        return false
    end
    local Helper = Character:GetAttribute("RescueHelperId")
    return Helper == nil or Helper == LocalPlayer.UserId
end

local function ChooseAssistTarget(Position, SafeGoal, Now)
    if not SafeGoal then
        Runtime.AssistMode = nil
        Runtime.AssistTarget = nil
        return nil, nil
    end
    local Strategy = GetRunnerStrategy()

    local CurrentAssist = Runtime.AssistTarget
    if Runtime.AssistMode == "Revive" then
        if ValidReviveTarget(CurrentAssist) then
            local TargetRoot = GetRoot(CurrentAssist)
            if TargetRoot then
                local Distance = Flat(TargetRoot.Position - Position).Magnitude
                local Lateral = RouteDistance(Position, SafeGoal, TargetRoot.Position)
                if Runtime.ReviveStarted or Distance <= Settings.ReviveMaxDistance and (Lateral <= 24 or Distance <= RescueRange + 5) then
                    return CurrentAssist, "Revive"
                end
            end
        end
        if Runtime.ReviveStarted then
            return CurrentAssist, "Revive"
        end
        Runtime.AssistMode = nil
        Runtime.AssistTarget = nil
    elseif Runtime.AssistMode == "Gem" then
        if CurrentAssist and CurrentAssist.Parent then
            local Distance = Flat(CurrentAssist.Position - Position).Magnitude
            local Lateral = RouteDistance(Position, SafeGoal, CurrentAssist.Position)
            if Distance <= Settings.GemMaxDistance and Lateral <= 18 then
                return CurrentAssist, "Gem"
            end
        end
        Runtime.AssistMode = nil
        Runtime.AssistTarget = nil
    end

    local ReviveCandidate
    if Settings.AutoRevive then
        local Target = FindDownedPlayer(Position)
        if Target then
            local TargetRoot = GetRoot(Target)
            if TargetRoot then
                local Distance = Flat(TargetRoot.Position - Position).Magnitude
                local Lateral, T = RouteDistance(Position, SafeGoal, TargetRoot.Position)
                if Distance <= Settings.ReviveMaxDistance and T <= 1.05 and (Lateral <= 24 or Distance <= RescueRange + 5) then
                    ReviveCandidate = Target
                end
            end
        end
    end

    local GemCandidate
    if Settings.AutoGems then
        RefreshGems(Now, Position)
        local Gem = Runtime.GemTarget
        if Gem and Gem.Parent then
            local Distance = Flat(Gem.Position - Position).Magnitude
            local Lateral, T = RouteDistance(Position, SafeGoal, Gem.Position)
            if Distance <= Settings.GemMaxDistance and T <= 1.05 and Lateral <= 18 then
                GemCandidate = Gem
            end
        end
    end

    if Strategy == "Chicken" and ReviveCandidate then
        local Threats = Runtime.Threats
        local NearestThreat = Threats[1]
        local ThreatDistance = NearestThreat and NearestThreat.Distance or math.huge
        if ThreatDistance < math.max(18, Settings.PanicDistance * 1.5) then
            ReviveCandidate = nil
        end
    end

    if Settings.ReviveBeforeGems and ReviveCandidate then
        Runtime.AssistMode = "Revive"
        Runtime.AssistTarget = ReviveCandidate
        Runtime.AssistSince = Now
        return ReviveCandidate, "Revive"
    end
    if GemCandidate then
        Runtime.AssistMode = "Gem"
        Runtime.AssistTarget = GemCandidate
        Runtime.AssistSince = Now
        return GemCandidate, "Gem"
    end
    if ReviveCandidate then
        Runtime.AssistMode = "Revive"
        Runtime.AssistTarget = ReviveCandidate
        Runtime.AssistSince = Now
        return ReviveCandidate, "Revive"
    end

    return nil, nil
end

local function HandleGemArrival(Position, Now)
    local Gem = Runtime.GemTarget
    if not Gem or not Gem.Parent then
        return
    end
    if Flat(Gem.Position - Position).Magnitude <= Settings.GemCollectDistance then
        Runtime.GemIgnored[Gem] = Now + 0.7
        Runtime.GemTarget = nil
    end
end

local function MovementStuck(Now, Position)
    local Previous = Runtime.LastMovePosition
    if not Previous then
        Runtime.LastMovePosition = Position
        Runtime.LastMove = Now
        Runtime.Stuck = false
        return
    end
    if Flat(Position - Previous).Magnitude >= 0.5 then
        Runtime.LastMovePosition = Position
        Runtime.LastMove = Now
        Runtime.Stuck = false
    elseif Now - Runtime.LastMove > 0.55 then
        Runtime.Stuck = true
        Runtime.LastMove = Now
        Runtime.LastMovePosition = Position
    end
end

local function RunnerStep(Now, Dt)

    local Role = GetRole()
    local State = GetRunState()

    if Role ~= "Runner" or State ~= "Active" then
        Runtime.Path = Vector3.zero
        Runtime.RunnerPlanAt = -math.huge
        Runtime.RunnerPlanDirection = Vector3.zero
        Runtime.RunnerPlanGoal = Vector3.zero
        Runtime.Goal = nil
        Runtime.GoalSide = nil
        Runtime.GoalMode = "SafeZone"
        Runtime.RouteActive = false
        Runtime.RouteComplete = false
        Runtime.RouteStartSide = nil
        Runtime.RouteTargetSide = nil
        Runtime.RouteCompletePosition = nil
        Runtime.RouteCompleteAt = -math.huge
        ClearCorridorLock()
        Runtime.EdgeRisk = false
        Runtime.EdgeDirection = Vector3.zero
        Runtime.SideGapDirection = Vector3.zero
        Runtime.SideGapUntil = -math.huge
        Runtime.SideGapReason = ""
        Runtime.DodgeDirection = Vector3.zero
        Runtime.DodgeUntil = -math.huge
        Runtime.AssistMode = nil
        Runtime.AssistTarget = nil
        if Runtime.ReviveStarted then
            CancelRevive()
        end
        return
    end

    if not Settings.RunnerEnabled then
        return
    end

    local Root = GetRoot()
    local Hum = GetHumanoid()
    if not Root or not Hum then
        return
    end

    if not CanMove() then
        Runtime.Path = Vector3.zero
        return
    end

    RefreshPing(Now)
    RefreshSafezones()
    RefreshCatchers(Now)
    local Position = Root.Position

    local BaseGoal = RunnerGoal(Position, Now)
    if Runtime.RouteComplete then
        local TargetZone = Runtime.RouteTargetSide == (Safezone.A and Safezone.A.Name) and Safezone.A or Safezone.B
        local MovedFromCompletion = Runtime.RouteCompletePosition and Flat(Position - Runtime.RouteCompletePosition).Magnitude or 0
        local NewRoundPosition = TargetZone and InZone(Position, TargetZone) and MovedFromCompletion >= 5 and Now - Runtime.RouteCompleteAt >= 0.25
        if NewRoundPosition then
            Runtime.RouteActive = false
            Runtime.RouteComplete = false
            Runtime.RouteStartSide = nil
            Runtime.RouteTargetSide = nil
            Runtime.RouteCompletePosition = nil
            Runtime.RouteCompleteAt = -math.huge
            Runtime.Goal = nil
            Runtime.GoalSide = nil
            BaseGoal = RunnerGoal(Position, Now)
        end
        if Runtime.RouteComplete then
            ClearCorridorLock()
            Runtime.Path = Vector3.zero
            Runtime.GoalMode = "SafeZone"
            Runtime.AssistMode = nil
            Runtime.AssistTarget = nil
            if Runtime.ReviveStarted then
                CancelRevive()
            end
            Hum:Move(Vector3.zero, false)
                            return
        end
    end
    if not BaseGoal then
        local Fallback = GetSafeFallback(Position)
        if Fallback then
            BaseGoal = Fallback
            Runtime.Goal = Fallback
            Runtime.GoalMode = "SafeZone"
        else
            local Forward = Flat(Root.CFrame.LookVector)
            if Forward.Magnitude > 0.05 then
                BaseGoal = Position + Forward.Unit * 40
            end
        end
    end

    if not BaseGoal then
        Hum:Move(Vector3.zero, false)
        Runtime.Path = Vector3.zero
        return
    end

    local AssistTarget, AssistMode = ChooseAssistTarget(Position, BaseGoal, Now)
    local MovementGoal = BaseGoal

    if AssistTarget and AssistMode == "Revive" then
        Runtime.ReviveTarget = AssistTarget
        local TargetRoot = GetRoot(AssistTarget)
        if TargetRoot then
            local TargetPosition = TargetRoot.Position
            local Distance = Flat(TargetPosition - Position).Magnitude
            if Distance <= RescueRange + 0.75 or Runtime.ReviveStarted then
                UpdateRevive(Now, Position)
            end
            if not Runtime.ReviveStarted and Distance > RescueRange then
                MovementGoal = TargetPosition
            elseif Runtime.ReviveStarted then
                MovementGoal = TargetPosition
            end
        end
    elseif AssistTarget and AssistMode == "Gem" and AssistTarget.Parent then
        MovementGoal = AssistTarget.Position
        Runtime.GoalMode = "Gem"
    else
        Runtime.GoalMode = "SafeZone"
    end

    if Runtime.ReviveStarted then
        local TargetRoot = Runtime.ReviveTarget and GetRoot(Runtime.ReviveTarget)
        if TargetRoot then
            local ReviveDistance = Flat(TargetRoot.Position - Position).Magnitude
            if ReviveDistance > RescueRange + 1.25 then
                CancelRevive()
            else
                Hum:Move(Vector3.zero, false)
                Runtime.Path = Vector3.zero
                                        return
            end
        else
            CancelRevive()
        end
    end

    MovementStuck(Now, Position)
    local Threats = UpdateThreats(Now, Position)

    local DistanceToGoal = Flat(MovementGoal - Position).Magnitude
    local ArriveDistance = Runtime.GoalMode == "Gem" and Settings.GemCollectDistance or 2.5

    if DistanceToGoal <= ArriveDistance then
        if Runtime.GoalMode == "Gem" then
            HandleGemArrival(Position, Now)
            Runtime.AssistMode = nil
            Runtime.AssistTarget = nil
            Runtime.GoalMode = "SafeZone"
            MovementGoal = BaseGoal
        elseif Runtime.GoalMode == "SafeZone" then
            local NextGoal = select(1, ChooseSafeGoal(Position))
            if Runtime.RouteComplete then
                Hum:Move(Vector3.zero, false)
                Runtime.Path = Vector3.zero
                                        return
            end
            MovementGoal = NextGoal or BaseGoal
            Runtime.Goal = MovementGoal
        end
    end

    if not MovementGoal then
        Hum:Move(Vector3.zero, false)
        Runtime.Path = Vector3.zero
        return
    end

    local Direction = Flat(MovementGoal - Position)
    if Direction.Magnitude < 0.05 then
        Hum:Move(Vector3.zero, false)
        Runtime.Path = Vector3.zero
        return
    end
    if Runtime.GoalMode == "SafeZone" and Runtime.Goal then
        MovementGoal = Vector3.new(Runtime.Goal.X, Position.Y, Runtime.Goal.Z)
        Direction = Flat(MovementGoal - Position)
        if Direction.Magnitude < 0.05 then
            local NextGoal = select(1, ChooseSafeGoal(Position))
            MovementGoal = NextGoal or MovementGoal
            Runtime.Goal = MovementGoal
            Direction = Flat(MovementGoal - Position)
            if Direction.Magnitude < 0.05 then
                Hum:Move(Vector3.zero, false)
                Runtime.Path = Vector3.zero
                return
            end
        end
    end
    Direction = Direction.Unit

    local CorridorGoal = nil
    if Runtime.GoalMode == "SafeZone" and Settings.AvoidCatchers and #Threats >= 2 then
        CorridorGoal = FindCorridorGoal(Position, MovementGoal, Threats, Now)
        if CorridorGoal then
            MovementGoal = CorridorGoal
            Direction = Flat(CorridorGoal - Position)
            if Direction.Magnitude > 0.05 then
                Direction = CorridorDirection(Position, CorridorGoal, Threats)
            end
        end
    elseif Runtime.CorridorActive then
        ClearCorridorLock()
    end

    if Settings.AvoidCatchers and #Threats > 0 and not (CorridorGoal and Direction.Magnitude > 0.05) then
        Direction = ChooseRunnerDirection(Position, MovementGoal, Threats)
    elseif Settings.AvoidCatchers and #Threats > 0 and CorridorGoal then
        Direction = ChooseRunnerDirection(Position, MovementGoal, Threats)
        if Runtime.CorridorActive then
            Direction = CorridorDirection(Position, MovementGoal, Threats)
        end
    end

    local ObstacleDirection, ObstacleRisk = ChooseObstacleDirection(Position, Direction, MovementGoal, Threats)
    Runtime.ObstacleRisk = ObstacleRisk
    Runtime.ObstacleDirection = ObstacleDirection
    if ObstacleRisk and ObstacleDirection.Magnitude > 0.05 then
        if Runtime.ObstacleRecoveryDirection.Magnitude < 0.05
            or Now >= Runtime.ObstacleRecoveryUntil
            or Runtime.ObstacleRecoveryDirection:Dot(ObstacleDirection) < 0.8 then
            Runtime.ObstacleRecoveryDirection = ObstacleDirection.Unit
            Runtime.ObstacleRecoveryUntil = Now + Settings.ObstacleRecoveryTime
        end
        Direction = Runtime.ObstacleRecoveryDirection
    elseif Now >= Runtime.ObstacleRecoveryUntil then
        Runtime.ObstacleRecoveryDirection = Vector3.zero
    end

    if Runtime.CorridorActive then
        local Axis = Runtime.CorridorAxis
        local Progress = (Position - Runtime.CorridorCenter):Dot(Axis)
        if Progress >= Settings.CorridorPassDistance + 3 then
            ClearCorridorLock()
        end
    end

    local HardThreat = Threats[1]
    local HardDodge = false
    if Settings.AvoidCatchers and HardThreat and (HardThreat.CollisionRisk or HardThreat.Tackle or HardThreat.PreTackle and HardThreat.Closing > 0) then
        local Escape = Flat(Position - HardThreat.Intercept)
        if Escape.Magnitude > 0.05 then
            local EscapeDir = Escape.Unit
            local Candidates = {EscapeDir, Rotate(EscapeDir, 35), Rotate(EscapeDir, -35), Rotate(EscapeDir, 70), Rotate(EscapeDir, -70)}
            if Runtime.CorridorActive then
                local Forward = Flat(Runtime.CorridorGoal - Position)
                if Forward.Magnitude > 0.05 then
                    local Keep = {}
                    for _, Candidate in ipairs(Candidates) do
                        if Candidate:Dot(Forward.Unit) > 0.05 then
                            Keep[#Keep + 1] = Candidate
                        end
                    end
                    Candidates = Keep
                end
            end
            local Best = Direction
            local BestClearance = RouteClear(Position, Direction, Threats)
            local Forward = Flat(MovementGoal - Position)
            local ForwardUnit = Forward.Magnitude > 0.05 and Forward.Unit or Direction
            local NearestGap = HardThreat.InterceptGap
            local AllowReverse = NearestGap <= HardThreat.Danger * 0.52
            local FoundForward = false

            for _, Candidate in ipairs(Candidates) do
                local Progress = Candidate:Dot(ForwardUnit)
                if Progress >= 0.08 then
                    FoundForward = true
                elseif not AllowReverse then
                    continue
                end
                local Clear = RouteClear(Position, Candidate, Threats)
                local Adjusted = Clear + Progress * 2.5
                local BestAdjusted = BestClearance + Best:Dot(ForwardUnit) * 2.5
                if Adjusted > BestAdjusted then
                    Best = Candidate
                    BestClearance = Clear
                end
            end
            local Emergency = HardThreat.InterceptGap <= HardThreat.Danger * (Runtime.CorridorActive and 1.05 or 1.35)
            if Emergency or BestClearance < 3 then
                Direction = Best
                HardDodge = true
            elseif FoundForward then
                HardDodge = false
            end
        end
    end

    local NearestThreat
    local NearestDistance = math.huge
    for _, Threat in ipairs(Threats) do
        if Threat.Distance < NearestDistance then
            NearestDistance = Threat.Distance
            NearestThreat = Threat
        end
    end

    if Settings.EmergencySafeZone and NearestThreat and NearestDistance <= Settings.PanicDistance and Runtime.Stuck then
        local Fallback = GetSafeFallback(Position)
        if Fallback then
            local SafeDirection = Flat(Fallback - Position)
            if SafeDirection.Magnitude > 0.05 then
                Direction = SafeDirection.Unit
                MovementGoal = Fallback
                Runtime.GoalMode = "SafeZone"
                Runtime.AssistMode = nil
                Runtime.AssistTarget = nil
            end
        end
    end

    local NowEdge = Now
    local EdgeDirection, EdgeRisk = ChooseEdgeDirection(Position, Direction, MovementGoal, Position.Y)
    Runtime.EdgeRisk = EdgeRisk
    Runtime.EdgeDirection = EdgeDirection
    if EdgeRisk and EdgeDirection.Magnitude > 0.05 then
        if Runtime.EdgeRecoveryDirection.Magnitude < 0.05
            or NowEdge >= Runtime.EdgeRecoveryUntil
            or Runtime.EdgeRecoveryDirection:Dot(EdgeDirection) < 0.92 then
            Runtime.EdgeRecoveryDirection = EdgeDirection.Unit
            Runtime.EdgeRecoveryAt = NowEdge
            Runtime.EdgeRecoveryUntil = NowEdge + 0.72
        end
        Direction = Runtime.EdgeRecoveryDirection
        HardDodge = true
    elseif NowEdge >= Runtime.EdgeRecoveryUntil then
        Runtime.EdgeRecoveryDirection = Vector3.zero
    end

    if Runtime.Stuck and MovementGoal then
        local Center = GetPlayfieldCenter()
        local Recovery = Center and Flat(Center - Position) or Flat(MovementGoal - Position)
        if Recovery.Magnitude > 0.05 then
            Recovery = Recovery.Unit
            if Runtime.StuckRecoveryDirection.Magnitude < 0.05
                or NowEdge >= Runtime.StuckRecoveryUntil
                or Runtime.StuckRecoveryDirection:Dot(Recovery) < 0.75 then
                local Candidates = {
                    Recovery,
                    RotateEdge(Recovery, 35),
                    RotateEdge(Recovery, -35),
                    RotateEdge(Recovery, 70),
                    RotateEdge(Recovery, -70),
                }
                local Best = Recovery
                local BestScore = -math.huge
                for _, Candidate in ipairs(Candidates) do
                    local Support = GroundSupportScore(Position, Candidate, Position.Y)
                    local Progress = Candidate:Dot(Recovery)
                    local Score = Support * 5 + Progress * 4
                    if Score > BestScore then
                        BestScore = Score
                        Best = Candidate.Unit
                    end
                end
                Runtime.StuckRecoveryDirection = Best
                Runtime.StuckRecoveryUntil = NowEdge + 0.85
            end
            Direction = Runtime.StuckRecoveryDirection
            HardDodge = true
        end
    elseif NowEdge >= Runtime.StuckRecoveryUntil then
        Runtime.StuckRecoveryDirection = Vector3.zero
    end

    if Settings.SmoothMovement and not HardDodge and Runtime.Path.Magnitude > 0.05 and not Runtime.Stuck then
        local Alpha = math.clamp(Settings.TurnRate * math.clamp(Dt or (1 / 60), 0.001, 0.1), 0, 1)
        local Blended = Flat(Runtime.Path:Lerp(Direction, Alpha))
        if Blended.Magnitude > 0.05 then
            Direction = Blended.Unit
        end
    end

    Runtime.Path = Direction

    if Hum.AutoRotate ~= true then
        Hum.AutoRotate = true
    end
    Hum:Move(Direction, false)

    local Character = GetCharacter()
    local DashCount = Character and tonumber(Character:GetAttribute("DashCount")) or nil
    if DashCount and Runtime.DashLastCount ~= nil and DashCount ~= Runtime.DashLastCount then
        Runtime.DashStatus = "active:count " .. tostring(DashCount)
        Runtime.DashLastCount = DashCount
    elseif Runtime.DashLastRequestAt > 0 and Now - Runtime.DashLastRequestAt > 0.35
        and Now - Runtime.DashAt > 0.35 and Runtime.DashStatus == "requested:waiting-game-client" then
        Runtime.DashStatus = "no-dash-state-change"
    end

    local GoalDistance = Flat(MovementGoal - Position).Magnitude
    if ShouldDash(Position, Threats, GoalDistance) then
        local DashDir = ChooseDashDirection(Position, Direction, Threats)
        if Runtime.SideGapDirection.Magnitude > 0.05 and os.clock() < Runtime.SideGapUntil then
            DashDir = Runtime.SideGapDirection
        elseif Runtime.EdgeRisk and Runtime.EdgeRecoveryDirection.Magnitude > 0.05 then
            DashDir = Runtime.EdgeRecoveryDirection
        elseif Runtime.Stuck and Runtime.StuckRecoveryDirection.Magnitude > 0.05 then
            DashDir = Runtime.StuckRecoveryDirection
        end
        RequestDash(DashDir, Now)
    end

end
local function RefreshRunnerTargets(Now)
    if Now - Runtime.CatcherTargetAt < 0.15 then
        return
    end
    Runtime.CatcherTargetAt = Now
    table.clear(Runtime.CatcherTargets)
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Parent and Player:GetAttribute("GameRole") == "Runner" and Player:GetAttribute("RunState") == "Active" then
            local C = Player.Character
            local H = C and C:FindFirstChildOfClass("Humanoid")
            local R = C and C:FindFirstChild("HumanoidRootPart")
            if H and H.Health > 0 and R and C:GetAttribute("Ragdolled") ~= true then
                Runtime.CatcherTargets[#Runtime.CatcherTargets + 1] = Player
            end
        end
    end
end

local function CatcherVelocity(Player, Now)
    local Root = GetRoot(Player)
    if not Root then
        return Vector3.zero
    end
    local Data = Runtime.CatcherVelocity[Player]
    if not Data then
        Data = {Velocity = Flat(Root.AssemblyLinearVelocity), Time = Now}
        Runtime.CatcherVelocity[Player] = Data
        return Data.Velocity
    end
    local Raw = Flat(Root.AssemblyLinearVelocity)
    local Dt = math.clamp(Now - Data.Time, 0.01, 0.25)
    local Alpha = math.clamp(Dt * Settings.CatcherSmoothing, 0, 1)
    Data.Velocity = Data.Velocity:Lerp(Raw, Alpha)
    Data.Time = Now
    return Data.Velocity
end

local function RunnerSafeForCatcher(Player)
    RefreshSafezones()
    local Root = GetRoot(Player)
    return Root and CurrentZone(Root.Position) ~= nil and (
        InZone(Root.Position, Safezone.A) or InZone(Root.Position, Safezone.B)
    )
end

local function SelectCatcherTarget(Now, MyPosition)
    RefreshRunnerTargets(Now)
    local Mode = Settings.CatcherTargetMode
    if Mode == "Random" then
        if #Runtime.CatcherTargets == 0 then
            Runtime.CatcherTarget = nil
            return nil
        end
        if Runtime.CatcherTarget
            and Runtime.CatcherTarget.Parent
            and Now - Runtime.CatcherRandomTargetAt < 2.5 then
            return Runtime.CatcherTarget
        end
        local Pool = {}
        for _, Player in ipairs(Runtime.CatcherTargets) do
            if Player ~= Runtime.CatcherTarget or #Runtime.CatcherTargets == 1 then
                Pool[#Pool + 1] = Player
            end
        end
        local Pick = Pool[Random.new():NextInteger(1, #Pool)]
        Runtime.CatcherTarget = Pick
        Runtime.CatcherRandomTargetAt = Now
        return Pick
    end

    local Best, BestScore
    local CurrentScore
    local CurrentTarget = Runtime.CatcherTarget
    local ChaseSpeed = math.max(GetCatcherSpeed(), 1)

    for _, Player in ipairs(Runtime.CatcherTargets) do
        local Root = GetRoot(Player)
        if Root then
            local Position = Root.Position
            local Velocity = CatcherVelocity(Player, Now)
            local Predicted = Position + Velocity * Settings.CatcherPrediction
            local Distance = Flat(Position - MyPosition).Magnitude
            local PredictedDistance = Flat(Predicted - MyPosition).Magnitude
            local Safe = RunnerSafeForCatcher(Player)
            local TimeToReach = PredictedDistance / ChaseSpeed
            local Score = PredictedDistance + math.min(TimeToReach * 10, 30) + Distance * 0.05
            if (Mode == "Smart" or Settings.SmartPriority) and Velocity.Magnitude >= 4 then
                Score -= 6
            end
            if Safe then
                Score += 18
            end
            if Player == CurrentTarget then
                CurrentScore = Score
            end
            if not BestScore or Score < BestScore then
                Best = Player
                BestScore = Score
            end
        end
    end

    if Mode ~= "Auto"
        and CurrentTarget and CurrentScore and BestScore
        and CurrentTarget ~= Best and CurrentScore <= BestScore + 8 then
        Best = CurrentTarget
    end

    Runtime.CatcherTarget = Best
    return Best
end

local function CatcherDirection(Root, Predicted, Dt)
    local Direction = Flat(Predicted - Root.Position)
    if Direction.Magnitude < 0.05 then
        return Vector3.zero
    end
    Direction = Direction.Unit
    if Settings.SmoothTurn and Runtime.CatcherPath and Runtime.CatcherPath.Magnitude > 0.05 then
        local Alpha = math.clamp(1 - math.exp(-math.max(Settings.TurnRateCatcher, 1) * math.max(Dt, 0.01)), 0, 1)
        local Blended = Runtime.CatcherPath:Lerp(Direction, Alpha)
        if Blended.Magnitude > 0.05 then
            Direction = Blended.Unit
        end
    end
    Runtime.CatcherPath = Direction
    return Direction
end

local function TackleRunning()
    local C = GetCharacter()
    return C and C:GetAttribute("TackleActive") == true
end

local function RequestTackle(Now)
    local RemainingOk, Remaining = pcall(TacklePrediction.remaining)
    if not RemainingOk then
        return false
    end
    if (tonumber(Remaining) or 0) > 0.02 then
        return false
    end

    local Ok, Result = pcall(TacklePrediction.request)
    if not Ok then
        return false
    end
    if Result == false then
        return false
    end
    Runtime.LastTackle = Now
    return true
end

local function CatcherAttack(Target, Now, Root)
    if not Target or not Root or TackleRunning() then
        return
    end
    local Character = GetCharacter()
    local Humanoid = GetHumanoid()
    if not Character or not Humanoid
        or Humanoid.Health <= 0
        or Humanoid.Sit
        or Humanoid.PlatformStand
        or Character:GetAttribute("MovementLocked") == true
        or Character:GetAttribute("Ragdolled") == true
        or Session:GetAttribute("GlobalPaused") == true
        or Session:GetAttribute("MapChanging") == true
        or ControlGate.reason(LocalPlayer) ~= nil
        or (Character:GetAttribute("DaggerEquipped") == true
            and Character:GetAttribute("DaggerState") ~= "Held") then
        return
    end
    local TargetRoot = GetRoot(Target)
    if not TargetRoot then
        return
    end

    local AttackDirection = Flat(Root.CFrame.LookVector)
    local ToTarget = Flat(TargetRoot.Position - Root.Position)
    if AttackDirection.Magnitude < 0.05 or ToTarget.Magnitude < 0.05 then
        return
    end
    local FacingDot = math.clamp(AttackDirection.Unit:Dot(ToTarget.Unit), -1, 1)
    local FacingAngle = math.deg(math.acos(FacingDot))
    local InReachCone = FacingAngle <= (ContactCatchConfig.ReachHalfAngle or 75)

    local TargetVelocity = CatcherVelocity(Target, Now)
    local MeleeLead = (ContactCatchConfig.Windup or 0.15) + (ContactCatchConfig.ActiveDuration or 0.1) * 0.5 + Runtime.Ping
    local MeleePos = TargetRoot.Position + TargetVelocity * MeleeLead
    local TacklePos = TargetRoot.Position + TargetVelocity * Runtime.Ping
    local ServerNow = workspace:GetServerTimeNow()
    local ReachStartedAt = tonumber(Character:GetAttribute("ReachStartedAt"))
    local MeleeBusy = ReachStartedAt
        and ServerNow < ReachStartedAt
            + (ContactCatchConfig.Windup or 0)
            + (ContactCatchConfig.ActiveDuration or 0)
            + (ContactCatchConfig.Recovery or 0)

    local MeleeReady = Settings.AutoMelee and Now - Runtime.LastMelee >= Settings.MeleeCooldown
        and not MeleeBusy
        and InReachCone
        and Flat(MeleePos - Root.Position).Magnitude <= Settings.MeleeRange
    local TackleReady = Settings.AutoTackle and Now - Runtime.LastTackle >= Settings.TackleCooldown
        and Flat(TacklePos - Root.Position).Magnitude <= Settings.TackleRange

    if Settings.CatcherAttackPriority == "Tackle First" then
        if TackleReady then
            if RequestTackle(Now) then
                return
            end
        end
        if MeleeReady then
            Runtime.MeleeId = HttpService:GenerateGUID(false)
            pcall(MeleeEvent.FireServer, MeleeEvent, {
                id = Runtime.MeleeId,
                at = ServerNow,
                direction = AttackDirection.Unit,
                position = Root.Position,
            })
            Runtime.LastMelee = Now
        end
    elseif Settings.CatcherAttackPriority == "Melee First" then
        if MeleeReady then
            Runtime.MeleeId = HttpService:GenerateGUID(false)
            pcall(MeleeEvent.FireServer, MeleeEvent, {
                id = Runtime.MeleeId,
                at = ServerNow,
                direction = AttackDirection.Unit,
                position = Root.Position,
            })
            Runtime.LastMelee = Now
            return
        end
        if TackleReady then
            RequestTackle(Now)
        end
    else
        if TargetVelocity.Magnitude >= 5 and TackleReady then
            RequestTackle(Now)
        elseif MeleeReady then
            Runtime.MeleeId = HttpService:GenerateGUID(false)
            pcall(MeleeEvent.FireServer, MeleeEvent, {
                id = Runtime.MeleeId,
                at = ServerNow,
                direction = AttackDirection.Unit,
                position = Root.Position,
            })
            Runtime.LastMelee = Now
        elseif TackleReady then
            RequestTackle(Now)
        end
    end
end

local function CatcherStep(Now, Dt)
    if not IsCatcherActive() then
        Runtime.CatcherTarget = nil
        Runtime.CatcherPath = Vector3.zero
        return
    end
    local Root = GetRoot()
    local Hum = GetHumanoid()
    if not Root or not Hum or Hum.Health <= 0 or Hum.PlatformStand or Hum.Sit then
        return
    end
    RefreshPing(Now)
    local NeedsTarget = Settings.CatcherChase or Settings.AutoTackle or Settings.AutoMelee or Settings.FollowTarget
    if not NeedsTarget then
        Runtime.CatcherTarget = nil
        Runtime.CatcherPath = Vector3.zero
        return
    end

    local Target = SelectCatcherTarget(Now, Root.Position)
    if not Target then
        Runtime.CatcherTarget = nil
        return
    end
    local TargetRoot = GetRoot(Target)
    if not TargetRoot then
        Runtime.CatcherTarget = nil
        return
    end

    local Velocity = CatcherVelocity(Target, Now)
    local Predicted = TargetRoot.Position + Velocity * Settings.CatcherPrediction
    local Direction = CatcherDirection(Root, Predicted, Dt)

    if Settings.CatcherChase and Direction.Magnitude > 0.05 then
        Hum.AutoRotate = true
        Hum:Move(Direction, false)
    end

    if Settings.AutoTackle or Settings.AutoMelee then
        CatcherAttack(Target, Now, Root)
    end

    if Settings.FollowTarget then
        local Camera = workspace.CurrentCamera
        if Camera then
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.LookAt(Camera.CFrame.Position, Predicted + Vector3.new(0, 1.5, 0)),
                math.clamp(Settings.CameraResponse, 0.01, 1)
            )
        end
    end
end

local function EnsurePart(Store, Key, Size, Color, Transparency)
    local Part = Store[Key]
    if Part and Part.Parent then
        return Part
    end
    Part = Instance.new("Part")
    Part.Name = "CoH_Utility"
    Part.Shape = Enum.PartType.Ball
    Part.Size = Vector3.new(Size, Size, Size)
    Part.Anchored = true
    Part.CanCollide = false
    Part.CanTouch = false
    Part.CanQuery = false
    Part.CastShadow = false
    Part.Material = Enum.Material.ForceField
    Part.Color = Color
    Part.Transparency = Transparency
    Part.Parent = workspace
    Store[Key] = Part
    return Part
end

local function CleanupVisuals()
    if Visuals.Goal and Visuals.Goal.Parent then
        Visuals.Goal:Destroy()
    end
    Visuals.Goal = nil
    for Key, Part in pairs(Visuals.Threats) do
        if Part.Parent then
            Part:Destroy()
        end
        Visuals.Threats[Key] = nil
    end
    for Key, Part in pairs(Visuals.Hitboxes) do
        if Part.Parent then
            Part:Destroy()
        end
        Visuals.Hitboxes[Key] = nil
    end
end

local function GetGuiText(Gui)
    if not Gui then
        return ""
    end
    local Ok, Value = pcall(function()
        if Gui:IsA("TextButton") or Gui:IsA("TextLabel") then
            return Gui.Text or ""
        end
        return Gui:GetAttribute("Text") or ""
    end)
    return Ok and tostring(Value or "") or ""
end

local function WheelNameScore(Gui, Mode)
    if not Gui or not Gui:IsA("GuiButton") then
        return -math.huge
    end
    local Name = string.lower(Gui.Name or "")
    local Text = string.lower(GetGuiText(Gui))
    local All = Name .. " " .. Text
    local Score = 0

    if Mode == "spin" then
        if All:find("spin", 1, true) then Score += 100 end
        if All:find("free", 1, true) then Score += 20 end
        if All:find("roll", 1, true) then Score += 12 end
        if All:find("claim", 1, true) then Score -= 25 end
        if All:find("close", 1, true) then Score -= 80 end
        if All:find("back", 1, true) then Score -= 60 end
    else
        if All:find("spin", 1, true) then Score += 90 end
        if All:find("wheel", 1, true) then Score += 70 end
        if All:find("daily", 1, true) then Score += 10 end
        if All:find("emote", 1, true) then Score -= 100 end
        if All:find("close", 1, true) then Score -= 50 end
    end

    if not Gui.Visible then Score -= 100 end
    if not Gui.Active then Score -= 20 end
    return Score
end

local function FindWheelButton(Mode)
    local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not PlayerGui then
        return nil
    end

    local Best, BestScore = nil, -math.huge
    local Ok, Descendants = pcall(function()
        return PlayerGui:GetDescendants()
    end)
    if not Ok then
        return nil
    end

    for _, Gui in ipairs(Descendants) do
        if Gui:IsA("GuiButton") and Gui.Visible and Gui.Active then
            local Score = WheelNameScore(Gui, Mode)
            if Score > BestScore then
                Best, BestScore = Gui, Score
            end
        end
    end

    if BestScore >= (Mode == "spin" and 90 or 70) then
        return Best
    end

    return nil
end

local function GuiContextText(Gui, Depth)
    local Parts = {}
    local Current = Gui
    local Levels = Depth or 5
    for _ = 1, Levels do
        if not Current then
            break
        end
        local Name = tostring(Current.Name or "")
        local Text = GetGuiText(Current)
        if Name ~= "" then
            table.insert(Parts, Name)
        end
        if Text ~= "" then
            table.insert(Parts, Text)
        end
        current = Current.Parent
    end
    return string.lower(table.concat(Parts, " "))
end

local function GetGuiLabelText(Gui)
    local Direct = GetGuiText(Gui)
    if Direct ~= "" then
        return Direct
    end

    local Ok, Descendants = pcall(function()
        return Gui:GetDescendants()
    end)
    if not Ok then
        return ""
    end

    for Index = 1, math.min(#Descendants, 12) do
        local Child = Descendants[Index]
        if Child:IsA("TextLabel") or Child:IsA("TextButton") then
            local Text = tostring(Child.Text or "")
            if Text ~= "" then
                return Text
            end
        end
    end

    return ""
end

local function RequestJourneyState(Force)
    local Now = os.clock()
    if not Force and Now - Runtime.JourneyRequestAt < 1.5 then
        return false
    end
    Runtime.JourneyRequestAt = Now
    local Ok = pcall(function()
        JourneyEvent:FireServer("Get")
    end)
    if not Ok then
        Runtime.JourneyStatus = "Journey state request failed"
        return false
    end
    return true
end

local function JourneyClaimableCount()
    if not Runtime.JourneyLoaded then
        return 0
    end

    local TrackId = JourneyConfig.TrackId
    local Tier = math.max(1, tonumber(Runtime.JourneyTier) or 1)
    local Premium = Runtime.JourneyPremium == true
    local Claims = Runtime.JourneyClaims or {}
    local Count = 0

    for Index = 1, Tier do
        local RewardTier = JourneyConfig.Rewards[Index]
        if RewardTier then
            local FreeReward = RewardTier.Free
            if FreeReward and Claims[TrackId .. ":" .. tostring(FreeReward.Key)] ~= true then
                Count += 1
            end
            if Premium then
                local PremiumReward = RewardTier.Premium
                if PremiumReward and Claims[TrackId .. ":" .. tostring(PremiumReward.Key)] ~= true then
                    Count += 1
                end
            end
        end
    end

    return Count
end

local function JourneyClaimOnce(Manual)
    if not Settings.AutoClaimJourneyRewards and not Manual then
        Runtime.JourneyStatus = "disabled"
        return false
    end

    if LocalPlayer:GetAttribute("InMatch") == true then
        Runtime.JourneyStatus = "waiting for lobby"
        return false
    end

    local Now = os.clock()
    if Now < (Runtime.JourneyNextClaimAt or -math.huge) then
        return false
    end

    if Runtime.JourneyClaimInFlight then
        Runtime.JourneyStatus = "claim request pending"
        return false
    end

    if not Runtime.JourneyLoaded then
        Runtime.JourneyManualPending = Manual == true or Runtime.JourneyManualPending
        Runtime.JourneyStatus = "loading journey state"
        RequestJourneyState(true)
        return false
    end

    local SeasonId = Runtime.JourneySeasonId or JourneyConfig.SeasonId
    if type(SeasonId) ~= "string" or SeasonId == "" then
        Runtime.JourneyStatus = "season unavailable"
        return false
    end

    local Available = JourneyClaimableCount()
    if Available <= 0 and not Manual then
        Runtime.JourneyStatus = "no claimable rewards"
        Runtime.JourneyNextClaimAt = Now + 2.5
        return false
    end

    Runtime.JourneyClaimInFlight = true
    Runtime.JourneyManualPending = false
    Runtime.JourneyLastClaimAt = Now
    Runtime.JourneyNextClaimAt = Now + 2.5
    Runtime.JourneyStatus = Available > 0 and string.format("claiming %d reward%s", Available, Available == 1 and "" or "s") or "claiming available rewards"

    local Fired = pcall(function()
        JourneyEvent:FireServer("ClaimAll", nil, SeasonId)
    end)

    if not Fired then
        Runtime.JourneyClaimInFlight = false
        Runtime.JourneyStatus = "claim request failed"
        Runtime.JourneyNextClaimAt = Now + 1
        return false
    end

    task.delay(1.25, function()
        if Runtime.JourneyClaimInFlight then
            Runtime.JourneyClaimInFlight = false
            Runtime.JourneyStatus = "waiting for confirmation"
            RequestJourneyState(true)
        end
    end)

    return true
end

local function GetSelectedMapSlot()
    local Selections = Settings.MapVoteSelections or {}
    local Selected = Selections[1]
    if Selected and table.find(MapVoteSlotIds, Selected) then
        return Selected
    end
    return nil
end

local function SetDebugError(Value)
    Runtime.DebugLastError = tostring(Value or "")
    Runtime.DebugLastErrorAt = os.clock()
end

local function GetDebugGui()
    if Runtime.DebugGui and Runtime.DebugGui.Parent and Runtime.DebugLabel and Runtime.DebugLabel.Parent then
        return Runtime.DebugGui, Runtime.DebugLabel
    end

    local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if not PlayerGui then
        return nil, nil
    end

    local Old = PlayerGui:FindFirstChild("CoH_FullDebug")
    if Old then
        Old:Destroy()
    end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "CoH_FullDebug"
    Gui.ResetOnSpawn = false
    Gui.IgnoreGuiInset = true
    Gui.DisplayOrder = 9999
    Gui.Enabled = false
    Gui.Parent = PlayerGui

    local Frame = Instance.new("Frame")
    Frame.Name = "Panel"
    Frame.Size = UDim2.fromOffset(470, 360)
    Frame.Position = UDim2.fromOffset(10, 70)
    Frame.BackgroundTransparency = 0.12
    Frame.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
    Frame.BorderSizePixel = 0
    Frame.Parent = Gui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Name = "Status"
    Label.Size = UDim2.new(1, -20, 1, -20)
    Label.Position = UDim2.fromOffset(10, 10)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(235, 240, 250)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextYAlignment = Enum.TextYAlignment.Top
    Label.Font = Enum.Font.Code
    Label.TextSize = 12
    Label.TextWrapped = false
    Label.Text = "Yvetzal | FULL DEBUG"
    Label.Parent = Frame

    Runtime.DebugGui = Gui
    Runtime.DebugLabel = Label
    return Gui, Label
end

local function UpdateDebugPanel(Now)
    if not Runtime.DebugEnabled then
        if Runtime.DebugGui then
            Runtime.DebugGui.Enabled = false
        end
        return
    end

    local Gui, Label = GetDebugGui()
    if not Gui or not Label then
        return
    end

    Gui.Enabled = true

    local Character = GetCharacter()
    local Humanoid = GetHumanoid()
    local Root = GetRoot()
    local Position = Root and Root.Position or Vector3.zero
    local GoalDistance = Runtime.Goal and Flat(Runtime.Goal - Position).Magnitude or -1
    local Speed = Humanoid and Humanoid.WalkSpeed or -1
    local Health = Humanoid and Humanoid.Health or -1
    local SafeA = Safezone.A and Safezone.A.Name or "nil"
    local SafeB = Safezone.B and Safezone.B.Name or "nil"
    local Threat = Runtime.Threats[1]
    local ErrorText = Runtime.DebugLastError ~= nil and Runtime.DebugLastError ~= "" and Runtime.DebugLastError or "none"
    local ErrorAge = Runtime.DebugLastErrorAt > 0 and math.max(0, Now - Runtime.DebugLastErrorAt) or -1
    local WheelStateAge = Runtime.WheelLastStateAt > 0 and math.max(0, Now - Runtime.WheelLastStateAt) or -1
    local JourneyAge = Runtime.JourneyLastStateAt > 0 and math.max(0, Now - Runtime.JourneyLastStateAt) or -1
    local MapAge = Runtime.MapVoteLastStateAt > 0 and math.max(0, Now - Runtime.MapVoteLastStateAt) or -1
    local SelectedMap = GetSelectedMapSlot() or "none"
    local Path = Runtime.Path or Vector3.zero

    Label.Text = table.concat({
        "Yvetzal | FULL DEBUG",
        string.format("Role=%s | Strategy=%s | RunState=%s | InMatch=%s | ClientReady=%s", tostring(GetRole()), tostring(GetRunnerStrategy()), tostring(GetRunState()), tostring(LocalPlayer:GetAttribute("InMatch")), tostring(LocalPlayer:GetAttribute("ClientReady"))),
        string.format("MovementLocked=%s | Ragdolled=%s | GearMotion=%s | HP=%.1f | WalkSpeed=%.1f", tostring(Character and Character:GetAttribute("MovementLocked")), tostring(Character and Character:GetAttribute("Ragdolled")), tostring(Character and Character:GetAttribute("GearMotion")), Health, Speed),
        string.format("Position=%.1f, %.1f, %.1f | GoalMode=%s | GoalDistance=%.1f", Position.X, Position.Y, Position.Z, tostring(Runtime.GoalMode), GoalDistance),
        string.format("SafeA=%s | SafeB=%s | Cached=%s", SafeA, SafeB, tostring(Safezone.Cached)),
        string.format("Route=%s -> %s | Complete=%s | Stuck=%s | EdgeRisk=%s", tostring(Runtime.RouteStartSide or "none"), tostring(Runtime.RouteTargetSide or "none"), tostring(Runtime.RouteComplete), tostring(Runtime.Stuck), tostring(Runtime.EdgeRisk)),
        string.format("Assist=%s | Revive=%s | Gem=%s | SideGap=%s", tostring(Runtime.AssistMode or "none"), Runtime.ReviveStarted and "started" or "idle", Runtime.GemTarget and Runtime.GemTarget.Parent and Runtime.GemTarget.Name or "none", Runtime.SideGapReason ~= "" and Runtime.SideGapReason or "none"),
        string.format("Threats=%d | Threat0=%s", #Runtime.Threats, Threat and string.format("d=%.1f gap=%.1f t=%.2f risk=%s", Threat.Distance or -1, Threat.InterceptGap or -1, Threat.InterceptTime or -1, tostring(Threat.CollisionRisk)) or "none"),
        string.format("Dash=%s | DashCount=%s | Path=%.2f, %.2f", tostring(Runtime.DashStatus), tostring(Runtime.DashLastCount), Path.X, Path.Z),
        string.format("CatcherTarget=%s | Mode=%s | Chase=%s | Tackle=%s | Melee=%s", Runtime.CatcherTarget and Runtime.CatcherTarget.Name or "none", tostring(Settings.CatcherTargetMode), tostring(Settings.CatcherChase), tostring(Settings.AutoTackle), tostring(Settings.AutoMelee)),
        string.format("Wheel=%s | Credits=%d | Spins=%d | Spinning=%s | StateAge=%.2fs", tostring(Runtime.WheelStatus), math.floor(tonumber(Runtime.WheelCredits) or 0), tonumber(Runtime.WheelSpinCount) or 0, tostring(Runtime.WheelSpinning), WheelStateAge),
        string.format("Journey=%s | Loaded=%s | Tier=%d | Claims=%d | StateAge=%.2fs", tostring(Runtime.JourneyStatus), tostring(Runtime.JourneyLoaded), tonumber(Runtime.JourneyTier) or 1, tonumber(Runtime.JourneyClaimCount) or 0, JourneyAge),
        string.format("MapVote=%s | Phase=%s | Selected=%s | StateAge=%.2fs", tostring(Runtime.MapVoteStatus), tostring(Runtime.MapVotePhase), SelectedMap, MapAge),
        string.format("AutoRun=%s | AutoSpin=%s | AutoClaim=%s | AutoVote=%s", tostring(Settings.RunnerEnabled), tostring(Settings.AutoSpinWheel), tostring(Settings.AutoClaimJourneyRewards), tostring(Settings.AutoMapVote)),
        string.format("Ping=%d ms | LastErrorAge=%.2fs | LastError=%s", math.floor((tonumber(Runtime.Ping) or 0) * 1000 + 0.5), ErrorAge, ErrorText),
    }, "\n")
end


local function ReadMapVoteState()
    if not MapVoteState or not MapVoteState:IsA("StringValue") then
        Runtime.MapVoteOpen = false
        Runtime.MapVotePhase = "Unavailable"
        return nil
    end

    local Ok, State = pcall(function()
        return HttpService:JSONDecode(MapVoteState.Value)
    end)
    if not Ok or type(State) ~= "table" then
        Runtime.MapVoteOpen = false
        Runtime.MapVotePhase = "Waiting"
        return nil
    end

    local Options = type(State.options) == "table" and State.options or {}
    local Ids = {}
    for Index = 1, math.min(#Options, #MapVoteSlotIds) do
        local Option = Options[Index]
        if type(Option) == "table" then
            Ids[Index] = Option.Id or Option.Id or Option.Key or Option.Key
        end
    end

    Runtime.MapVoteOptionIds = Ids
    Runtime.MapVoteToken = State.Token
    Runtime.MapVotePhase = tostring(State.Phase or "Waiting")
    Runtime.MapVoteOpen = Runtime.MapVotePhase == "Voting"
    Runtime.MapVoteLastStateAt = os.clock()
    return State
end

local function MapVoteOnce(Manual)
    if not Settings.AutoMapVote and not Manual then
        Runtime.MapVoteStatus = "disabled"
        return false
    end

    if LocalPlayer:GetAttribute("InMatch") == true then
        Runtime.MapVoteStatus = "waiting for lobby"
        return false
    end

    if LocalPlayer:GetAttribute("ClientReady") ~= true then
        Runtime.MapVoteStatus = "waiting for client"
        return false
    end

    if LocalPlayer:GetAttribute("AFK") == true then
        Runtime.MapVoteStatus = "waiting - AFK"
        return false
    end

    if Session:GetAttribute("GlobalPaused") == true then
        Runtime.MapVoteStatus = "paused"
        return false
    end

    local State = ReadMapVoteState()
    if not State or Runtime.MapVotePhase ~= "Voting" then
        Runtime.MapVoteStatus = "waiting for vote"
        return false
    end

    local Selected = GetSelectedMapSlot()
    if not Selected then
        Runtime.MapVoteStatus = "choose Map 1, Map 2, or Map 3"
        return false
    end

    local Index = table.find(MapVoteSlotIds, Selected)
    local OptionId = Index and Runtime.MapVoteOptionIds[Index]
    if OptionId == nil then
        Runtime.MapVoteStatus = Selected .. " is unavailable"
        return false
    end

    local Token = Runtime.MapVoteToken
    if Token == nil then
        Runtime.MapVoteStatus = "vote token unavailable"
        return false
    end

    local Votes = type(State.Votes) == "table" and State.Votes or nil
    local CurrentVote = Votes and (Votes[tostring(LocalPlayer.UserId)] or Votes[LocalPlayer.UserId]) or nil
    if CurrentVote == OptionId then
        Runtime.MapVoteStatus = Selected .. " already selected"
        return true
    end

    local Now = os.clock()
    if Now - Runtime.MapVoteLastActionAt < 0.75 then
        return false
    end

    local Fired = pcall(function()
        MapVoteEvent:FireServer("Vote", OptionId, Token)
    end)

    if not Fired then
        Runtime.MapVoteStatus = "vote request failed"
        return false
    end

    Runtime.MapVoteLastActionAt = Now
    Runtime.MapVoteStatus = Selected .. " vote sent"
    if Settings.MapVoteAnnounce then
        pcall(function()
            WindUI:Notify({
                Title = "Map Vote",
                Content = Selected .. " selected.",
                Duration = 2.5,
                Icon = "map",
            })
        end)
    end
    return true
end

local function WheelServerNow()
    local Ok, Value = pcall(function()
        return workspace:GetServerTimeNow()
    end)
    if Ok and type(Value) == "number" then
        return Value
    end
    return os.time()
end

local function WheelCooldownRemaining()
    local NextFreeAt = tonumber(Runtime.WheelNextFreeAt) or 0
    if NextFreeAt <= 0 then
        return 0
    end
    if NextFreeAt < 100000000 then
        return math.max(0, NextFreeAt)
    end
    return math.max(0, NextFreeAt - WheelServerNow())
end

local function WheelUpdateStatus(Status)
    Runtime.WheelStatus = tostring(Status or Runtime.WheelStatus or "waiting")
    Runtime.WheelStatusAt = os.clock()
end

local function WheelRequestState(Now, Force)
    if not Force and Now - Runtime.WheelStateRequestAt < 1.25 then
        return false
    end

    Runtime.WheelStateRequestAt = Now
    local Ok = pcall(function()
        SpinWheelEvent:FireServer("State")
    end)
    Runtime.WheelEventReady = Ok

    if Ok then
        return true
    end

    WheelUpdateStatus("state request failed")
    return false
end

local function WheelApplyState(Payload)
    if type(Payload) ~= "table" then
        return
    end
    Runtime.WheelCredits = tonumber(Payload.Credits) or 0
    Runtime.WheelNextFreeAt = tonumber(Payload.NextFreeAt) or 0
    Runtime.WheelPurchasesAvailable = Payload.PurchasesAvailable == true
    Runtime.WheelDiscountAvailable = Payload.DiscountAvailable == true
end

local function WheelCanSpinNow(Manual)
    if not Settings.AutoSpinWheel and not Manual then
        return false, "disabled"
    end

    if LocalPlayer:GetAttribute("InMatch") == true then
        return false, "cannot spin in match"
    end

    if Runtime.WheelSpinning then
        return false, "spinning"
    end

    local Now = os.clock()
    local NextAttempt = tonumber(Runtime.WheelNextAttemptAt) or -math.huge
    if Now < NextAttempt then
        return false, string.format("cooldown %.1fs", NextAttempt - Now)
    end

    local Minimum = math.max(1, math.floor(tonumber(Settings.WheelMinimumCredits) or 1))
    local Credits = math.floor(tonumber(Runtime.WheelCredits) or 0)
    if Credits < Minimum then
        return false, string.format("not enough credits (%d/%d)", Credits, Minimum)
    end

    return true, "ready"
end

local function WheelNotify(Title, content, icon)
    if not Settings.WheelAnnounce then
        return
    end
    pcall(function()
        WindUI:Notify({
            Title = Title,
            Content = content,
            Duration = 2.5,
            Icon = icon or "circle-dot",
        })
    end)
end

local function WheelSpinOnce(Manual)
    local Allowed, Reason = WheelCanSpinNow(Manual)
    if not Allowed then
        WheelUpdateStatus(Reason)
        return false
    end

    local Now = os.clock()
    local Delay = math.clamp(tonumber(Settings.WheelSpinInterval) or 6, 5.5, 30)
    Runtime.WheelSpinning = true
    Runtime.WheelSpinRequestAt = Now
    Runtime.WheelNextAttemptAt = Now + Delay
    Runtime.WheelActionAt = Now
    Runtime.WheelSpinCount += 1
    WheelUpdateStatus("spin requested")

    local Fired = pcall(function()
        SpinWheelEvent:FireServer("Spin")
    end)

    if not Fired then
        Runtime.WheelSpinning = false
        Runtime.WheelNextAttemptAt = Now + 1
        WheelUpdateStatus("spin request failed")
        return false
    end

    if Manual then
        WheelNotify("Wheel", "Spin request sent.", "zap")
    else
        WheelNotify("Auto Spin", string.format("Spin #%d fired.", Runtime.WheelSpinCount), "circle-dot")
    end

    task.delay(0.85, function()
        Runtime.WheelSpinning = false
        WheelRequestState(os.clock(), true)
    end)

    return true
end

local function AutoSpinWheelStep(Now)
    if not Settings.AutoSpinWheel then
        WheelUpdateStatus("disabled")
        return
    end

    WheelRequestState(Now, false)

    local Allowed, Reason = WheelCanSpinNow(false)
    if Allowed then
        WheelSpinOnce(false)
        return
    end

    WheelUpdateStatus(Reason)
end

local function UtilityStep(Now)
    if Now - Runtime.UtilityTick < 0.25 then
        return
    end
    Runtime.UtilityTick = Now
    if Settings.AutoSpinWheel then
        AutoSpinWheelStep(Now)
    end
    if Settings.ShowThreats or Settings.ShowThreatUtility then
        if IsRunnerActive() then
            local Root = GetRoot()
            local Threats = Root and UpdateThreats(Now, Root.Position) or {}
            for I = 1, math.min(#Threats, 8) do
                local Threat = Threats[I]
                local Part = EnsurePart(Visuals.Threats, I, Threat.Danger * 2, Color3.fromRGB(255, 90, 90), 0.82)
                Part.CFrame = CFrame.new(Threat.Position)
            end
            for I = #Threats + 1, #Visuals.Threats do
                local Part = Visuals.Threats[I]
                if Part and Part.Parent then
                    Part:Destroy()
                end
                Visuals.Threats[I] = nil
            end
        end
    else
        for I, Part in pairs(Visuals.Threats) do
            if Part.Parent then
                Part:Destroy()
            end
            Visuals.Threats[I] = nil
        end
    end

    local GoalEnabled = Settings.ShowGoal and Settings.ShowGoalUtility
    if GoalEnabled and Runtime.Goal then
        local Part = Visuals.Goal
        if not Part or not Part.Parent then
            Part = Instance.new("Part")
            Part.Name = "CoH_Goal"
            Part.Shape = Enum.PartType.Ball
            Part.Size = Vector3.new(2.5, 2.5, 2.5)
            Part.Anchored = true
            Part.CanCollide = false
            Part.CanTouch = false
            Part.CanQuery = false
            Part.CastShadow = false
            Part.Material = Enum.Material.ForceField
            Part.Color = Color3.fromRGB(80, 200, 255)
            Part.Transparency = 0.45
            Part.Parent = workspace
            Visuals.Goal = Part
        end
        Part.CFrame = CFrame.new(Runtime.Goal)
    elseif Visuals.Goal then
        if Visuals.Goal.Parent then
            Visuals.Goal:Destroy()
        end
        Visuals.Goal = nil
    end

    if Settings.ShowHitboxes then
        local Role = GetRole()
        local Seen = {}
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer and Player.Parent then
                local TargetRole = Player:GetAttribute("GameRole")
                local Relevant = (Role == "Runner" and TargetRole == "Catcher") or (Role == "Catcher" and TargetRole == "Runner")
                local Root = Relevant and GetRoot(Player) or nil
                if Root then
                    Seen[Player] = true
                    local Part = Visuals.Hitboxes[Player]
                    if not Part or not Part.Parent then
                        Part = Instance.new("Part")
                        Part.Name = "CoH_Hitbox"
                        Part.Shape = Enum.PartType.Ball
                        Part.Anchored = true
                        Part.CanCollide = false
                        Part.CanTouch = false
                        Part.CanQuery = false
                        Part.CastShadow = false
                        Part.Material = Enum.Material.ForceField
                        Part.Color = Color3.fromRGB(255, 180, 80)
                        Part.Transparency = 0.75
                        Part.Parent = workspace
                        Visuals.Hitboxes[Player] = Part
                    end
                    local Radius = ContactCatchConfig.RunnerRadius * 2
                    Part.Size = Vector3.new(Radius, Radius, Radius)
                    Part.CFrame = CFrame.new(Root.Position)
                end
            end
        end
        for Player, Part in pairs(Visuals.Hitboxes) do
            if not Seen[Player] then
                if Part.Parent then
                    Part:Destroy()
                end
                Visuals.Hitboxes[Player] = nil
            end
        end
    else
        for Player, Part in pairs(Visuals.Hitboxes) do
            if Part.Parent then
                Part:Destroy()
            end
            Visuals.Hitboxes[Player] = nil
        end
    end
end

ArmoryEvent.OnClientEvent:Connect(function(Kind, State)
    if Kind == "State" and type(State) == "table" then
        Runtime.Armory = State
        Runtime.Armory.Abilities = Runtime.Armory.Abilities or {}
    end
end)

RescueEvent.OnClientEvent:Connect(function(Kind, Id)
    if Kind == "Cancelled" and Runtime.ReviveTarget and Runtime.ReviveTarget.UserId == Id then
        Runtime.ReviveStarted = false
        Runtime.ReviveStartAt = 0
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    Runtime.profile = nil
    Runtime.ProfileRole = nil
    Runtime.LastMovePosition = nil
    Runtime.MoveCommandAt = -math.huge
    Runtime.Goal = nil
    Runtime.GoalMode = "SafeZone"
    Runtime.GoalSide = nil
    Runtime.RouteActive = false
    Runtime.RouteComplete = false
    Runtime.RouteStartSide = nil
    Runtime.RouteTargetSide = nil
    Runtime.RouteCompletePosition = nil
    Runtime.RouteCompleteAt = -math.huge
    Runtime.GemTarget = nil
    Runtime.ReviveTarget = nil
    Runtime.ReviveStarted = false
    Runtime.ReviveStartAt = 0
    Runtime.ThreatHistory = {}
    Runtime.Threats = {}
    Runtime.Catchers = {}
    Runtime.CatcherTargets = {}
    Runtime.DashAt = -math.huge
    Runtime.DashStatus = "idle"
    Runtime.DashLastRequestAt = -math.huge
    Runtime.DashLastCount = nil
    Runtime.EdgeRecoveryDirection = Vector3.zero
    Runtime.EdgeRecoveryUntil = -math.huge
    Runtime.StuckRecoveryDirection = Vector3.zero
    Runtime.StuckRecoveryUntil = -math.huge
    Runtime.ArmoryAt = -math.huge
    Runtime.Armory = {Loaded = false, Abilities = {}}
    Runtime.WheelScanAt = -math.huge
    Runtime.WheelActionAt = -math.huge
    Runtime.WheelStatus = Settings.AutoSpinWheel and "starting" or "disabled"
    Runtime.WheelLastButton = nil
    Runtime.WheelCredits = 0
    Runtime.WheelNextFreeAt = 0
    Runtime.WheelPurchasesAvailable = false
    Runtime.WheelDiscountAvailable = false
    Runtime.WheelStateRequestAt = -math.huge
    Runtime.WheelSpinRequestAt = -math.huge
    Runtime.WheelNextAttemptAt = -math.huge
    Runtime.WheelEventReady = false
    Runtime.WheelSpinning = false
    Runtime.WheelLastStateAt = -math.huge
    Runtime.WheelStatusAt = -math.huge
    Runtime.WheelMinimumCredits = 1
end)

do
    local Handle = Game:FindFirstChild("ActiveMap")
    if Handle and Handle:IsA("ObjectValue") then
        Handle.Changed:Connect(function()
            Safezone.Cached = false
            Safezone.Map = nil
            Runtime.MapCache = nil
            Runtime.MapCacheAt = -math.huge
            Runtime.SafeCheckAt = -math.huge
            Runtime.SafeCheckPosition = nil
            Runtime.ObstacleParams = nil
            Runtime.ObstacleCharacter = nil
            Runtime.ObstacleDirection = Vector3.zero
            Runtime.ObstacleRisk = false
            Runtime.ObstacleRecoveryDirection = Vector3.zero
            Runtime.ObstacleRecoveryUntil = -math.huge
            EdgeRayCache.Map = nil
            EdgeRayCache.Params = nil
            Runtime.Goal = nil
            Runtime.GoalSide = nil
            Runtime.RouteActive = false
            Runtime.RouteComplete = false
            Runtime.RouteStartSide = nil
            Runtime.RouteTargetSide = nil
            Runtime.RouteCompletePosition = nil
            Runtime.RouteCompleteAt = -math.huge
        end)
    end
end

pcall(function()
    ArmoryEvent:FireServer("Get")
end)

task.spawn(function()
    pcall(function()
        local GemEvent = HussValley:WaitForChild("Collectibles"):WaitForChild("GemEvent")
        GemEvent:FireServer("Sync")
    end)
end)

SpinWheelEvent.OnClientEvent:Connect(function(Kind, Payload)
    if Kind == "State" and type(Payload) == "table" then
        WheelApplyState(Payload)
        Runtime.WheelLastStateAt = os.clock()
        if Payload.Result or Payload.Message then
            Runtime.WheelSpinning = false
        end
        if Settings.AutoSpinWheel then
            local Credits = tonumber(Runtime.WheelCredits) or 0
            local Minimum = math.max(1, math.floor(tonumber(Settings.WheelMinimumCredits) or 1))
            if Credits >= Minimum then
                WheelUpdateStatus("ready")
            else
                WheelUpdateStatus(string.format("waiting - credits %d/%d", math.floor(Credits), Minimum))
            end
            task.defer(function()
                if Settings.AutoSpinWheel and LocalPlayer:GetAttribute("InMatch") ~= true then
                    AutoSpinWheelStep(os.clock())
                end
            end)
        end
        return
    end

    if Kind == "PromptProduct" then
        Runtime.WheelPurchasesAvailable = true
        WheelUpdateStatus("free credits unavailable")
        return
    end

    if type(Kind) == "table" and Payload == nil then
        WheelApplyState(Kind)
        if Settings.AutoSpinWheel then
            WheelUpdateStatus("state refreshed")
            task.defer(function()
                AutoSpinWheelStep(os.clock())
            end)
        end
    end
end)

local function IsLobbyForAFKOverride()
    return Settings.DisableBuiltinAFK and LocalPlayer:GetAttribute("InMatch") ~= true
end

local function ForceBuiltinAFKOff(Reason)
    if not IsLobbyForAFKOverride() then
        Runtime.AfkOverrideInLobby = false
        if not Settings.DisableBuiltinAFK then
            Runtime.AfkOverrideStatus = "disabled"
        end
        return false
    end

    Runtime.AfkOverrideInLobby = true

    local Now = os.clock()
    if Reason ~= "attribute" and Now - Runtime.AfkOverrideLastRequestAt < Runtime.AfkOverrideRequestInterval then
        return false
    end

    local Ok, Err = pcall(function()
        PlayerPreferences:FireServer("SetAFK", false)
    end)

    Runtime.AfkOverrideLastRequestAt = Now

    if Ok then
        Runtime.AfkOverrideRequestCount = (Runtime.AfkOverrideRequestCount or 0) + 1
        Runtime.AfkOverrideStatus = "AFK OFF"
        return true
    end

    Runtime.AfkOverrideStatus = "request failed"
    return false
end

LocalPlayer:GetAttributeChangedSignal("AFK"):Connect(function()
    if not Settings.DisableBuiltinAFK then
        Runtime.AfkOverrideStatus = "disabled"
        return
    end

    if LocalPlayer:GetAttribute("InMatch") == true then
        Runtime.AfkOverrideInLobby = false
        Runtime.AfkOverrideStatus = "in match"
        return
    end

    if LocalPlayer:GetAttribute("AFK") == true then
        ForceBuiltinAFKOff("attribute")
    else
        Runtime.AfkOverrideStatus = "AFK OFF confirmed"
    end
end)

LocalPlayer:GetAttributeChangedSignal("InMatch"):Connect(function()
    if not Settings.DisableBuiltinAFK then
        return
    end

    if LocalPlayer:GetAttribute("InMatch") == true then
        Runtime.AfkOverrideInLobby = false
        Runtime.AfkOverrideStatus = "in match"
    else
        Runtime.AfkOverrideInLobby = true
        Runtime.AfkOverrideLastRequestAt = -math.huge
        ForceBuiltinAFKOff("lobby")
    end
end)

task.spawn(function()
    while LocalPlayer.Parent do
        task.wait(0.5)
        if Settings.DisableBuiltinAFK then
            if LocalPlayer:GetAttribute("InMatch") == true then
                Runtime.AfkOverrideInLobby = false
                Runtime.AfkOverrideStatus = "in match"
            else
                Runtime.AfkOverrideInLobby = true
                ForceBuiltinAFKOff("poll")
            end
        end
    end
end)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Theme = {
    WindowColor = ColorSequence.new(Color3.fromRGB(8, 8, 8), Color3.fromRGB(0, 0, 0)),
    ShadowColor = Color3.fromRGB(0, 0, 0),
    SurfaceStroke = Color3.fromRGB(120, 15, 15),
    CornerRoundness = UDim.new(0, 8),
    ElementCornerRadius = UDim.new(0, 6),
    ContentColor = Color3.fromRGB(230, 230, 230),
    TitlingColor = Color3.fromRGB(255, 255, 255),
    ActionColor = Color3.fromRGB(255, 255, 255),
    ElementTextHoverColor = Color3.fromRGB(255, 255, 255),
    TabColor = Color3.fromRGB(255, 255, 255),
    TabBackground = ColorSequence.new(Color3.fromRGB(22, 22, 22), Color3.fromRGB(8, 8, 8)),
    TabStroke = ColorSequence.new(Color3.fromRGB(230, 30, 30), Color3.fromRGB(110, 10, 10)),
    ElementGradient = ColorSequence.new(Color3.fromRGB(18, 18, 18), Color3.fromRGB(10, 10, 10)),
    ElementStroke = Color3.fromRGB(60, 60, 60),
    ElementStrokeHover = Color3.fromRGB(230, 40, 40),
    StatBackground = Color3.fromRGB(30, 6, 6),
    AccentColor = Color3.fromRGB(220, 20, 60),
    AccentStroke = Color3.fromRGB(255, 70, 100),
    SliderBackground = Color3.fromRGB(35, 35, 35),
    SliderProgress = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(210, 210, 210)),
    SliderHandle = Color3.fromRGB(255, 255, 255),
    SliderStroke = Color3.fromRGB(60, 60, 60),
    ToggleTrack = Color3.fromRGB(30, 30, 30),
    ToggleKnobOff = Color3.fromRGB(220, 220, 220),
    DropdownHighlight = Color3.fromRGB(180, 25, 25),
    FieldBackground = Color3.fromRGB(14, 14, 14),
    FieldGlow = Color3.fromRGB(120, 20, 20),
    PlaceholderColor = Color3.fromRGB(150, 150, 150),
    NeutralButton = Color3.fromRGB(26, 26, 26),
    NeutralButtonHover = Color3.fromRGB(45, 45, 45),
    NeutralButtonStroke = Color3.fromRGB(80, 15, 15),
    ErrorColor = Color3.fromRGB(230, 40, 40),
    ErrorStrokeColor = Color3.fromRGB(255, 90, 90),
}
local Themes = {Default = Theme}
local ThemeName = "Default"

local IconAtlas = {
    ["bell"] = {16898613869, 771, 808},
    ["box"] = {16898612819, 820, 147},
    ["brain"] = {16898613777, 918, 49},
    ["bug"] = {16898612819, 869, 98},
    ["camera"] = {16898612819, 967, 563},
    ["check"] = {16898613869, 820, 98},
    ["check-check"] = {16898613869, 820, 98},
    ["circle-alert"] = {16898613044, 0, 771},
    ["crosshair"] = {16898613044, 453, 869},
    ["flame"] = {16898613353, 967, 306},
    ["file-plus"] = {16898613613, 918, 196},
    ["folder-open"] = {16898613613, 918, 196},
    ["footprints"] = {16898613353, 918, 710},
    ["gauge"] = {16898613869, 514, 771},
    ["gem"] = {16898613044, 869, 612},
    ["gift"] = {16898613613, 918, 196},
    ["heart"] = {16898613509, 661, 771},
    ["heart-pulse"] = {16898613509, 661, 771},
    ["info"] = {16898613044, 0, 771},
    ["keyboard"] = {16898613509, 453, 820},
    ["layers"] = {16898613613, 918, 196},
    ["life-buoy"] = {16898613044, 0, 771},
    ["link"] = {16898613613, 771, 759},
    ["list-checks"] = {16898613869, 820, 98},
    ["map"] = {16898613613, 820, 257},
    ["move"] = {16898613613, 453, 820},
    ["music"] = {16898613613, 967, 563},
    ["pause"] = {16898613869, 820, 98},
    ["palette"] = {16898613613, 453, 918},
    ["play"] = {16898613869, 918, 906},
    ["power"] = {16898613869, 918, 906},
    ["refresh-cw"] = {16898613699, 869, 453},
    ["rotate-ccw"] = {16898613699, 869, 453},
    ["rotate-cw"] = {16898613699, 869, 453},
    ["save"] = {16898613777, 771, 0},
    ["server"] = {16898613777, 771, 0},
    ["settings"] = {16898613777, 771, 257},
    ["shield"] = {16898613777, 49, 869},
    ["sparkles"] = {16898613777, 918, 49},
    ["sun"] = {16898613777, 967, 453},
    ["sword"] = {16898613777, 710, 967},
    ["target"] = {16898613869, 514, 771},
    ["timer"] = {16898613869, 661, 869},
    ["toggle-right"] = {16898613869, 820, 98},
    ["trash-2"] = {16898613777, 49, 869},
    ["user-round-x"] = {16898613869, 661, 869},
    ["wind"] = {16898613869, 820, 857},
    ["wand-2"] = {16898613869, 918, 453},
    ["wrench"] = {16898613777, 771, 257},
    ["zap"] = {16898613869, 918, 906},
}

local function ResolveIcon(Name)
    if type(Name) ~= "string" then
        return Name
    end
    local IconName = Name:gsub("^Lucide:", "")
    local Sprite = IconAtlas[IconName]
    return Sprite and ("rbxassetid://" .. Sprite[1]) or nil
end

local function CropIcon(Image, Name)
    if not Image or type(Name) ~= "string" then
        return
    end
    local Sprite = IconAtlas[Name:gsub("^Lucide:", "")]
    if Sprite then
        Image.ImageRectSize = Vector2.new(48, 48)
        Image.ImageRectOffset = Vector2.new(Sprite[2], Sprite[3])
    end
end

local Window = Rayfield:CreateWindow({
    name = "Yvetzal",
    subtitle = "Huss Valley",
    icon = ResolveIcon("flame"),
    showName = "Yvetzal",
    showIcon = ResolveIcon("flame"),
    sidebarLayout = true,
    profile = "Yvetzal",
    theme = Theme,
})
CropIcon(Window.topbarIcon, "flame")
CropIcon(Window.collapsedIcon, "flame")
if getgenv then
    getgenv().YvetzalUI = Window
end

WindUI = {
    Notify = function(_, Opts)
        if Settings.Notifications == false then
            return
        end
        local Notification = Window:Notify({
            Title = Opts.Title,
            content = Opts.Content,
            duration = Opts.Duration,
            icon = ResolveIcon(Opts.Icon),
        })
        if Notification then
            CropIcon(Notification.iconLabel, Opts.Icon)
        end
        return Notification
    end,
    GetThemes = function()
        return Themes
    end,
    SetTheme = function(_, Name)
        ThemeName = Themes[Name] and Name or "Default"
        Window:ChangeTheme(Themes[ThemeName])
    end,
}

function Window.Tag(Self)
end

function Window.ToggleTransparency(Self, Value)
    if Self.SetTransparency then
        Self:SetTransparency(Value)
    end
end

function Window.SetToggleKey(Self, Key)
    if Self.settings then
        Self.settings.toggleKeybind = Key
    end
end

Window:SetToggleKey(Enum.KeyCode.RightShift)

function Window.Destroy(Self)
    if type(Self.Unload) == "function" then
        Self:Unload()
    end
end


Settings.Notifications = true
Hub.rawNotify = WindUI.Notify



function Hub.register(Key, Element, Default)
    if Element ~= nil then
        table.insert(Hub.Registry, {Key = Key, Element = Element, Default = Default})
    end
end

local function AdaptElement(Tab, Method, Config, TabName)
    local DefaultIcons = {
        CreateButton = "zap",
        CreateDropdown = "list-checks",
        CreateInput = "keyboard",
        CreateSection = "settings",
        CreateSlider = "gauge",
        CreateText = "info",
        CreateToggle = "toggle-right",
    }
    local IconName = Config.Icon or DefaultIcons[Method]
    local Properties = {
        name = Config.Title,
        description = Config.Desc,
        icon = ResolveIcon(IconName),
        callback = Config.Callback,
    }
    if Method == "CreateText" then
        Properties.text = Config.Desc or Config.Text or ""
    elseif Method == "CreateToggle" then
        Properties.value = Config.Value == true
    elseif Method == "CreateSlider" then
        local Value = type(Config.Value) == "table" and Config.Value or {}
        Properties.range = {Value.Min or 0, Value.Max or 100}
        Properties.increment = Config.Step or 1
        Properties.value = Value.Default
    elseif Method == "CreateDropdown" then
        Properties.options = Config.Values or {}
        Properties.value = Config.Value
    elseif Method == "CreateInput" then
        Properties.placeholder = Config.Placeholder or ""
        Properties.value = Config.Value or ""
    end
    local Element = Tab[Method](Tab, Properties)
    if Element then
        CropIcon(Element.iconLabel, IconName)
        if Config.Title and Method ~= "CreateButton" and Method ~= "CreateSection" and Method ~= "CreateText" then
            local Key = TabName .. "_" .. Config.Title
            Hub.register(Key, Element, Properties.value)
        end
    end
    return Element
end

local function WrapTab(Tab, TabName)
    local SelectTab = Tab.Select
    local Methods = {
        Paragraph = "CreateText",
        Section = "CreateSection",
        Toggle = "CreateToggle",
        Slider = "CreateSlider",
        Dropdown = "CreateDropdown",
        Button = "CreateButton",
        Input = "CreateInput",
    }
    for Name, Method in pairs(Methods) do
        Tab[Name] = function(Self, Config)
            return AdaptElement(Self, Method, Config or {}, TabName)
        end
    end
    Tab.Divider = function(Self)
        if type(Self.CreateDivider) == "function" then
            return Self:CreateDivider()
        end
    end
    Tab.Select = function(Self)
        if type(SelectTab) == "function" then
            return SelectTab(Self)
        end
    end
    return Tab
end

Hub.rawTab = function(Self, Config)
    local Tab = Self:CreateTab({
        name = Config.Title,
        icon = ResolveIcon(Config.Icon),
    })
    CropIcon(Tab.topbarItemIcon, Config.Icon)
    return WrapTab(Tab, Config.Title or "Tab")
end
Window.Tab = function(Self, Cfg)
    return Hub.rawTab(Self, Cfg)
end

local RunnerTab = Window:Tab({Title = "Runner", Icon = "footprints"})

local RunnerStatusParagraph = RunnerTab:Paragraph({
    Title = "Runner Status",
    Desc = "Role: Lobby\nState: Idle\nGoal: None",
})

RunnerTab:Section({Title = "Movement"})

RunnerTab:Dropdown({
    Title = "Runner Strategy",
    Desc = "Auto follows the live Hero or Chicken choice; manual modes tune risk and rescue behavior.",
    Values = {"Auto", "Hero", "Chicken"},
    Value = "Auto",
    Multi = false,
    Callback = function(V)
        if type(V) == "table" then
            V = V[1]
        end
        if V == "Auto" or V == "Hero" or V == "Chicken" then
            Settings.Strategy = V
        end
    end,
})

RunnerTab:Toggle({
    Title = "Auto Run",
    Desc = "Automatically travel between Safe Zones with threat and edge checks.",
    Icon = "play",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.RunnerEnabled = V == true
        if not Settings.RunnerEnabled then
            Runtime.Path = Vector3.zero
            Runtime.Goal = nil
            Runtime.AssistMode = nil
            Runtime.AssistTarget = nil
            Runtime.SideGapDirection = Vector3.zero
            Runtime.SideGapUntil = -math.huge
            CancelRevive()
        end
    end,
})

RunnerTab:Toggle({
    Title = "Auto Revive Players",
    Desc = "Move to a downed Runner and complete the real revive hold before continuing.",
    Icon = "heart-pulse",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.AutoRevive = V == true
        if not V then
            CancelRevive()
        end
    end,
})

RunnerTab:Toggle({
    Title = "Runner Speed Override",
    Desc = "Multiply the game's current Runner movement speed without replacing its acceleration or dash system.",
    Icon = "gauge",
    Type = "Checkbox",
    Value = false,
    Callback = function(V)
        Settings.CustomSpeed = V == true
        if not Settings.CustomSpeed then
            RestoreNativeWalkSpeed()
        end
    end,
})

RunnerTab:Slider({
    Title = "Runner Speed Multiplier",
    Desc = "1.0x keeps the native speed; maximum is 2.0x.",
    Step = 0.05,
    Value = {Min = 1.0, Max = 2.0, Default = 1.0},
    Callback = function(V)
        Settings.SpeedMultiplier = math.clamp(tonumber(V) or 1, 1, 2)
    end,
})

RunnerTab:Section({Title = "Collection and Safety"})

RunnerTab:Toggle({
    Title = "Revive Before Gems",
    Desc = "Prioritize downed players before collecting Gems.",
    Icon = "list-checks",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.ReviveBeforeGems = V == true
    end,
})

RunnerTab:Toggle({
    Title = "Auto Collect Gems",
    Desc = "Collect visible Runner Gems, then return to the Safe Zone route when none remain.",
    Icon = "gem",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.AutoGems = V == true
        if not V then
            Runtime.GemTarget = nil
        end
    end,
})

RunnerTab:Toggle({
    Title = "Avoid Catchers",
    Desc = "Predict nearby Catchers and bend the route away from their projected path.",
    Icon = "shield",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.AvoidCatchers = V == true
    end,
})

RunnerTab:Toggle({
    Title = "Auto Dash",
    Desc = "Use the equipped Runner ability before a Catcher reaches the predicted collision area.",
    Icon = "zap",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.AutoDash = V == true
    end,
})

RunnerTab:Slider({
    Title = "Runner Threat Prediction",
    Desc = "How far ahead Catcher movement is predicted for Runner avoidance.",
    Step = 0.05,
    Value = {Min = 0.25, Max = 1.1, Default = 0.65},
    Callback = function(V)
        Settings.PredictionTime = math.clamp(tonumber(V) or 0.65, 0.25, 1.1)
    end,
})

RunnerTab:Slider({
    Title = "Emergency Threat Distance",
    Desc = "Distance at which emergency avoidance becomes more aggressive.",
    Step = 1,
    Value = {Min = 8, Max = 25, Default = 15},
    Callback = function(V)
        Settings.PanicDistance = math.clamp(tonumber(V) or 15, 8, 25)
    end,
})

RunnerTab:Section({Title = "Movement"})

RunnerTab:Toggle({
    Title = "Smooth Direction Changes",
    Desc = "Blend turns to reduce sudden movement changes.",
    Icon = "rotate-cw",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.SmoothMovement = V == true
    end,
})

RunnerTab:Toggle({
    Title = "Emergency Safe Zone",
    Desc = "When movement stalls under heavy pressure, temporarily favor the nearest Safe Zone.",
    Icon = "life-buoy",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.EmergencySafeZone = V == true
    end,
})

RunnerTab:Slider({
    Title = "Avoidance Strength",
    Desc = "How strongly the route moves away from projected Catcher paths.",
    Step = 0.1,
    Value = {Min = 0.5, Max = 2.5, Default = 1.8},
    Callback = function(V)
        Settings.AvoidStrength = math.clamp(tonumber(V) or 1.8, 0.5, 2.5)
    end,
})

local CatcherTab = Window:Tab({Title = "Catcher", Icon = "crosshair"})

local CatcherStatusParagraph = CatcherTab:Paragraph({
    Title = "Catcher Status",
    Desc = "Role: Lobby\nState: Idle\nTarget: None",
})

CatcherTab:Section({Title = "Targeting and Combat"})

CatcherTab:Dropdown({
    Title = "Target Selection",
    Desc = "Auto adapts to the current target; Smart scores interception; Random picks a different active Runner periodically.",
    Values = {"Auto", "Smart", "Random"},
    Value = "Auto",
    Multi = false,
    Callback = function(V)
        if type(V) == "table" then
            V = V[1]
        end
        if V == "Auto" or V == "Smart" or V == "Random" then
            Settings.CatcherTargetMode = V
            Runtime.CatcherTarget = nil
            Runtime.CatcherRandomTargetAt = -math.huge
        end
    end,
})

CatcherTab:Toggle({
    Title = "Auto Chase",
    Desc = "Automatically move toward the best active Runner.",
    Icon = "move",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.CatcherChase = V == true
        if not Settings.CatcherChase then
            Runtime.CatcherTarget = nil
            Runtime.CatcherPath = Vector3.zero
        end
    end,
})

CatcherTab:Dropdown({
    Title = "Attack Priority",
    Desc = "Choose whether Smart, Tackle, or Melee is preferred when attacking.",
    Values = {"Smart", "Tackle First", "Melee First"},
    Value = "Smart",
    Multi = false,
    Callback = function(V)
        if type(V) == "table" then
            V = V[1]
        end
        if V == "Smart" or V == "Tackle First" or V == "Melee First" then
            Settings.CatcherAttackPriority = V
        end
    end,
})

CatcherTab:Toggle({
    Title = "Smart Targeting",
    Desc = "Prefer active targets that can be intercepted instead of simply choosing the nearest Runner.",
    Icon = "brain",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.SmartPriority = V == true
    end,
})

CatcherTab:Toggle({
    Title = "Auto Tackle",
    Desc = "Automatically tackle a Runner when the predicted position enters tackle range.",
    Icon = "zap",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.AutoTackle = V == true
        if not Settings.AutoTackle then
            Runtime.LastTackle = -math.huge
        end
    end,
})

CatcherTab:Slider({
    Title = "Tackle Range",
    Desc = "Distance used before an automatic tackle is attempted.",
    Step = 0.5,
    Value = {Min = 5, Max = 25, Default = 12},
    Callback = function(V)
        Settings.TackleRange = math.clamp(tonumber(V) or 12, 5, 25)
    end,
})

CatcherTab:Toggle({
    Title = "Auto Melee",
    Desc = "Automatically melee a Runner when the predicted position enters melee range.",
    Icon = "sword",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.AutoMelee = V == true
        if not Settings.AutoMelee then
            Runtime.LastMelee = -math.huge
        end
    end,
})

CatcherTab:Slider({
    Title = "Melee Range",
    Desc = "Distance used before an automatic melee attack is attempted.",
    Step = 0.5,
    Value = {Min = 3, Max = 15, Default = 9},
    Callback = function(V)
        Settings.MeleeRange = math.clamp(tonumber(V) or 9, 3, 15)
    end,
})

CatcherTab:Slider({
    Title = "Target Prediction",
    Desc = "How far ahead the Catcher predicts the selected Runner.",
    Step = 0.05,
    Value = {Min = 0.1, Max = 1.0, Default = 0.45},
    Callback = function(V)
        Settings.CatcherPrediction = math.clamp(tonumber(V) or 0.45, 0.1, 1.0)
    end,
})

CatcherTab:Section({Title = "Movement"})

CatcherTab:Toggle({
    Title = "Catcher Speed Override",
    Desc = "Multiply the game's current Catcher movement speed without replacing its acceleration or dash system.",
    Icon = "gauge",
    Type = "Checkbox",
    Value = false,
    Callback = function(V)
        Settings.CatcherCustomSpeed = V == true
        if not Settings.CatcherCustomSpeed then
            RestoreNativeWalkSpeed()
        end
    end,
})

CatcherTab:Slider({
    Title = "Catcher Speed Multiplier",
    Desc = "1.0x keeps the native speed; maximum is 2.0x.",
    Step = 0.05,
    Value = {Min = 1.0, Max = 2.0, Default = 1.0},
    Callback = function(V)
        Settings.CatcherSpeedMultiplier = math.clamp(tonumber(V) or 1, 1, 2)
    end,
})

CatcherTab:Toggle({
    Title = "Smooth Turning",
    Desc = "Rotate toward the predicted Runner position without snapping.",
    Icon = "rotate-cw",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.SmoothTurn = V == true
    end,
})

CatcherTab:Slider({
    Title = "Turn Response",
    Desc = "How quickly the Catcher turns toward the predicted target.",
    Step = 1,
    Value = {Min = 5, Max = 30, Default = 14},
    Callback = function(V)
        Settings.TurnRateCatcher = math.clamp(tonumber(V) or 14, 5, 30)
    end,
})

local WheelTab = Window:Tab({Title = "Wheel", Icon = "rotate-cw"})

WheelTab:Section({Title = "Status"})

local WheelStatusParagraph = WheelTab:Paragraph({
    Title = "Wheel Ready",
    Desc = "Credits: 0 | Spins: 0\nFree spin: Ready | Match: No | Spinning: No",
})

local function UpdateWheelStatusUI()
    local Credits = math.floor(tonumber(Runtime.WheelCredits) or 0)
    local Minimum = math.max(1, math.floor(tonumber(Settings.WheelMinimumCredits) or 1))
    local Free = WheelCooldownRemaining()
    local FreeText = Free > 0 and string.format("%d:%02d", math.floor(Free / 60), math.floor(Free % 60)) or "ready"
    local StateAge = Runtime.WheelLastStateAt > 0 and math.max(0, os.clock() - Runtime.WheelLastStateAt) or math.huge
    local StateText = StateAge < math.huge and string.format("%.1fs ago", StateAge) or "not received"
    local Title = string.format("%s | Credits %d/%d", tostring(Runtime.WheelStatus or "waiting"), Credits, Minimum)
    local Desc = string.format(
        "Spins: %d | Free spin: %s\nMatch: %s | Spinning: %s | State: %s",
        tonumber(Runtime.WheelSpinCount) or 0,
        FreeText,
        LocalPlayer:GetAttribute("InMatch") == true and "Yes" or "No",
        Runtime.WheelSpinning and "Yes" or "No",
        StateText
    )
    pcall(function()
        WheelStatusParagraph:SetTitle(Title)
        WheelStatusParagraph:SetDesc(Desc)
    end)
end

WheelTab:Section({Title = "Automatic Spin"})

WheelTab:Toggle({
    Title = "Enable Auto Spin",
    Desc = "Automatically spin when you have enough credits and are in the lobby.",
    Icon = "play",
    Type = "Checkbox",
    Value = false,
    Callback = function(V)
        Settings.AutoSpinWheel = V == true
        Runtime.WheelSpinning = false
        Runtime.WheelSpinRequestAt = -math.huge
        Runtime.WheelNextAttemptAt = -math.huge
        if Settings.AutoSpinWheel then
            Runtime.WheelStatus = "refreshing state"
            WheelRequestState(os.clock(), true)
            pcall(function()
                WindUI:Notify({Title = "Auto Spin", Content = "Started.", Duration = 2, Icon = "check"})
            end)
        else
            Runtime.WheelStatus = "disabled"
            pcall(function()
                WindUI:Notify({Title = "Auto Spin", Content = "Stopped.", Duration = 2, Icon = "pause"})
            end)
        end
        UpdateWheelStatusUI()
    end,
})

WheelTab:Slider({
    Title = "Delay Between Spins",
    Desc = "Seconds to wait between automatic spin requests.",
    Step = 0.5,
    Value = {Min = 5.5, Max = 30, Default = 6},
    Callback = function(V)
        Settings.WheelSpinInterval = math.clamp(tonumber(V) or 6, 5.5, 30)
        UpdateWheelStatusUI()
    end,
})

WheelTab:Slider({
    Title = "Minimum Credits",
    Desc = "Do not spin unless the wheel has at least this many credits.",
    Step = 1,
    Value = {Min = 1, Max = 50, Default = 1},
    Callback = function(V)
        Settings.WheelMinimumCredits = math.max(1, math.floor(tonumber(V) or 1))
        Runtime.WheelMinimumCredits = Settings.WheelMinimumCredits
        UpdateWheelStatusUI()
    end,
})

WheelTab:Toggle({
    Title = "Spin Notifications",
    Desc = "Show a notification when an automatic spin is sent.",
    Icon = "bell",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.WheelAnnounce = V == true
    end,
})

WheelTab:Divider()
WheelTab:Section({Title = "Manual Controls"})

WheelTab:Button({
    Title = "Spin Once Now",
    Desc = "Send one normal Spin request when the wheel is available.",
    Icon = "zap",
    Callback = function()
        task.spawn(function()
            WheelRequestState(os.clock(), true)
            task.wait(0.1)
            WheelSpinOnce(true)
            UpdateWheelStatusUI()
        end)
    end,
})

WheelTab:Button({
    Title = "Refresh Wheel State",
    Desc = "Request the latest credits and free-spin timer from the game.",
    Icon = "refresh-cw",
    Callback = function()
        WheelRequestState(os.clock(), true)
        task.delay(0.2, UpdateWheelStatusUI)
    end,
})

task.spawn(function()
    while WheelStatusParagraph and WheelStatusParagraph.Parent do
        task.wait(0.5)
        if Settings.AutoSpinWheel then
            local Allowed, Reason = WheelCanSpinNow(false)
            if Runtime.WheelSpinning then
                Runtime.WheelStatus = "spinning"
            elseif Allowed then
                Runtime.WheelStatus = "ready"
            else
                Runtime.WheelStatus = Reason
            end
        end
        UpdateWheelStatusUI()
    end
end)

local JourneyTab = Window:Tab({Title = "Journey", Icon = "gift"})
JourneyTab:Section({Title = "Rewards"})

local JourneyStatusParagraph = JourneyTab:Paragraph({
    Title = "Journey Status",
    Desc = "State: Loading\nAvailable rewards: 0",
})

JourneyTab:Toggle({
    Title = "Auto Claim Rewards",
    Desc = "Automatically claim all unlocked Journey rewards while you are in the lobby.",
    Icon = "gift",
    Type = "Checkbox",
    Value = false,
    Callback = function(V)
        Settings.AutoClaimJourneyRewards = V == true
        Runtime.JourneyClaimInFlight = false
        Runtime.JourneyNextClaimAt = -math.huge
        if Settings.AutoClaimJourneyRewards then
            Runtime.JourneyStatus = "checking rewards"
            RequestJourneyState(true)
        else
            Runtime.JourneyManualPending = false
            Runtime.JourneyStatus = "disabled"
        end
    end,
})

JourneyTab:Toggle({
    Title = "Announce Claims",
    Desc = "Show a notification after Journey rewards are claimed.",
    Icon = "bell",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.JourneyClaimAnnounce = V == true
    end,
})

JourneyTab:Button({
    Title = "Claim Rewards Now",
    Desc = "Claim all currently unlocked rewards once for the current season.",
    Icon = "gift",
    Callback = function()
        JourneyClaimOnce(true)
    end,
})

JourneyEvent.OnClientEvent:Connect(function(Action, Data)
    if Action ~= "State" or type(Data) ~= "table" then
        return
    end

    local SeasonId = Data.SeasonId or JourneyConfig.SeasonId
    if JourneyConfig.SeasonId and SeasonId ~= JourneyConfig.SeasonId then
        return
    end

    local WasClaiming = Runtime.JourneyClaimInFlight
    Runtime.JourneyLoaded = Data.Loaded == true
    Runtime.JourneySeasonId = SeasonId
    Runtime.JourneyTier = tonumber(Data.Tier) or 1
    Runtime.JourneyPremium = Data.Premium == true
    Runtime.JourneyClaims = type(Data.Claims) == "table" and Data.Claims or {}
    Runtime.JourneyLastStateAt = os.clock()

    if WasClaiming then
        Runtime.JourneyClaimInFlight = false
        Runtime.JourneyClaimCount += 1
        Runtime.JourneyLastClaimResultAt = os.clock()
    end

    if Data.Message and tostring(Data.Message) ~= "" then
        Runtime.JourneyStatus = tostring(Data.Message)
    elseif Runtime.JourneyLoaded then
        local Remaining = JourneyClaimableCount()
        Runtime.JourneyStatus = Remaining > 0 and string.format("%d reward%s available", Remaining, Remaining == 1 and "" or "s") or "ready"
    else
        Runtime.JourneyStatus = "loading journey state"
    end

    if (Settings.AutoClaimJourneyRewards or Runtime.JourneyManualPending) and Runtime.JourneyLoaded and LocalPlayer:GetAttribute("InMatch") ~= true and not Runtime.JourneyClaimInFlight then
        local Remaining = JourneyClaimableCount()
        if Remaining > 0 or Runtime.JourneyManualPending then
            local ManualPending = Runtime.JourneyManualPending == true
            task.delay(0.15, function()
                if (Settings.AutoClaimJourneyRewards or ManualPending) and LocalPlayer:GetAttribute("InMatch") ~= true then
                    JourneyClaimOnce(ManualPending)
                end
            end)
        end
    end
end)

task.spawn(function()
    RequestJourneyState(true)
    while task.wait(1.5) do
        if LocalPlayer:GetAttribute("InMatch") ~= true then
            RequestJourneyState(false)
            if Settings.AutoClaimJourneyRewards and Runtime.JourneyLoaded and not Runtime.JourneyClaimInFlight then
                JourneyClaimOnce(false)
            end
        end
    end
end)

local function UpdateRoleStatusUI()
    local Role = GetRole()
    local State = GetRunState()
    local Goal = Runtime.GoalMode or "None"
    local Assist = Runtime.AssistMode or "None"
    local Target = Runtime.CatcherTarget and Runtime.CatcherTarget.Name or "None"
    pcall(function()
        RunnerStatusParagraph:SetTitle("Runner: " .. tostring(Role))
        RunnerStatusParagraph:SetDesc(string.format("State: %s\nGoal: %s | Assist: %s", tostring(State), tostring(Goal), tostring(Assist)))
        CatcherStatusParagraph:SetTitle("Catcher: " .. tostring(Role))
        CatcherStatusParagraph:SetDesc(string.format("State: %s\nTarget: %s", tostring(State), tostring(Target)))
    end)
end

task.spawn(function()
    while RunnerStatusParagraph and RunnerStatusParagraph.Parent do
        task.wait(0.35)
        UpdateRoleStatusUI()
    end
end)

local MapVoteTab = Window:Tab({Title = "Map Vote", Icon = "map"})

MapVoteTab:Section({Title = "Voting"})

local MapVoteStatusParagraph = MapVoteTab:Paragraph({
    Title = "Map Vote",
    Desc = "Phase: Waiting\nSelection: Map 1\nStatus: Ready",
})

MapVoteDropdown = MapVoteTab:Dropdown({
    Title = "Preferred Map",
    Desc = "Choose Map 1, Map 2, or Map 3.",
    Values = MapVoteSlotIds,
    Value = MapVoteSlotIds[1],
    Multi = false,
    AllowNone = false,
    SearchBarEnabled = false,
    Callback = function(Value)
        local Selected = Value
        if type(Value) == "table" then
            Selected = Value[1] or Value.Title or Value.Name or Value.Value
        end
        Selected = tostring(Selected or "")
        if table.find(MapVoteSlotIds, Selected) then
            Settings.MapVoteSelections = {Selected}
            Runtime.MapVoteStatus = Selected .. " selected"
            if Settings.AutoMapVote then
                task.defer(function()
                    MapVoteOnce(false)
                end)
            end
        end
    end,
})

Settings.MapVoteSelections = {MapVoteSlotIds[1]}

local function UpdateMapVoteStatusUI()
    local Selected = GetSelectedMapSlot() or "None"
    local Phase = Runtime.MapVotePhase or "Waiting"
    local Status = Runtime.MapVoteStatus or "ready"
    pcall(function()
        MapVoteStatusParagraph:SetTitle("Map Vote: " .. Phase)
        MapVoteStatusParagraph:SetDesc(string.format("Selection: %s\nStatus: %s", Selected, Status))
    end)
end

MapVoteTab:Toggle({
    Title = "Auto Vote",
    Desc = "Automatically send the selected Map 1, Map 2, or Map 3 vote when voting begins.",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(V)
        Settings.AutoMapVote = V == true
        Runtime.MapVoteLastActionAt = -math.huge
        if Settings.AutoMapVote then
            Runtime.MapVoteStatus = "starting"
            ReadMapVoteState()
            task.defer(function()
                MapVoteOnce(false)
            end)
        else
            Runtime.MapVoteStatus = "disabled"
        end
        UpdateMapVoteStatusUI()
    end,
})

MapVoteTab:Toggle({
    Title = "Vote Notifications",
    Desc = "Show a notification after a vote is sent.",
    Icon = "bell",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.MapVoteAnnounce = V == true
    end,
})

MapVoteTab:Button({
    Title = "Vote Selected Map",
    Desc = "Send one vote immediately using the game's normal MapVoteEvent.",
    Icon = "check-check",
    Callback = function()
        MapVoteOnce(true)
        UpdateMapVoteStatusUI()
    end,
})

if MapVoteState and MapVoteState:IsA("StringValue") then
    MapVoteState.Changed:Connect(function()
        ReadMapVoteState()
        if Settings.AutoMapVote then
            task.defer(function()
                MapVoteOnce(false)
            end)
        end
        UpdateMapVoteStatusUI()
    end)
end

ReadMapVoteState()
UpdateMapVoteStatusUI()

task.spawn(function()
    while MapVoteStatusParagraph and MapVoteStatusParagraph.Parent do
        task.wait(0.5)
        ReadMapVoteState()
        if Settings.AutoMapVote then
            MapVoteOnce(false)
        end
        UpdateMapVoteStatusUI()
    end
end)

local UtilitiesTab = Window:Tab({Title = "Utilities", Icon = "wrench"})

UtilitiesTab:Section({Title = "Camera"})

UtilitiesTab:Toggle({
    Title = "Follow Target",
    Desc = "Smoothly point the camera toward the active Catcher target.",
    Icon = "camera",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.FollowTarget = V == true
        Settings.CameraFollow = Settings.FollowTarget
    end,
})

UtilitiesTab:Slider({
    Title = "Camera Follow Speed",
    Desc = "How quickly the camera follows the target.",
    Step = 0.05,
    Value = {Min = 0.05, Max = 1.0, Default = 0.25},
    Callback = function(V)
        Settings.CameraResponse = V
    end,
})

UtilitiesTab:Section({Title = "Lobby"})

local AFKStatusParagraph = UtilitiesTab:Paragraph({
    Title = "Built-in AFK Status",
    Desc = "Game AFK: OFF\nLobby: No\nRemote Requests: 0",
})

UtilitiesTab:Toggle({
    Title = "Disable Anti AFK Flag",
    Desc = "Turns off the game's built-in AFK state while you are in the lobby and reapplies it if the game turns AFK back on.",
    Icon = "user-round-x",
    Type = "Checkbox",
    Value = false,
    Callback = function(V)
        Settings.DisableBuiltinAFK = V
        Runtime.AfkOverrideLastRequestAt = -math.huge

        if V then
            if LocalPlayer:GetAttribute("InMatch") == true then
                Runtime.AfkOverrideStatus = "in match"
                Runtime.AfkOverrideInLobby = false
            else
                Runtime.AfkOverrideStatus = "starting"
                ForceBuiltinAFKOff("toggle")
            end
        else
            Runtime.AfkOverrideInLobby = false
            Runtime.AfkOverrideStatus = "disabled"
        end
    end,
})

task.spawn(function()
    while AFKStatusParagraph and AFKStatusParagraph.Parent do
        task.wait(0.5)
        pcall(function()
            local Afk = LocalPlayer:GetAttribute("AFK") == true
            local RemoteState = Afk and "ON" or "OFF"
            local Status = Runtime.AfkOverrideStatus or "disabled"
            AFKStatusParagraph:SetTitle(string.format("Game AFK: %s", RemoteState))
            AFKStatusParagraph:SetDesc(string.format(
                "Override: %s\nLobby: %s\nRemote Requests: %d",
                Status,
                Runtime.AfkOverrideInLobby and "Yes" or "No",
                tonumber(Runtime.AfkOverrideRequestCount) or 0
            ))
        end)
    end
end)

UtilitiesTab:Section({Title = "Debug"})

UtilitiesTab:Toggle({
    Title = "Full Debug Panel",
    Desc = "Show the detailed Runner, Catcher, Wheel, Journey, Map Vote, movement, and error panel.",
    Icon = "bug",
    Type = "Checkbox",
    Value = false,
    Callback = function(V)
        Runtime.DebugEnabled = V == true
        Settings.ShowDebugUI = Runtime.DebugEnabled
        if not Runtime.DebugEnabled and Runtime.DebugGui then
            Runtime.DebugGui.Enabled = false
        elseif Runtime.DebugEnabled then
            UpdateDebugPanel(os.clock())
        end
    end,
})

UtilitiesTab:Section({Title = "Visual Helpers"})

UtilitiesTab:Toggle({
    Title = "Show Goal",
    Desc = "Show the current Gem, revive target, or Safe Zone destination.",
    Icon = "target",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.ShowGoal = V == true
        Settings.ShowGoalUtility = Settings.ShowGoal
        if not Settings.ShowGoal then
            if Visuals.Goal and Visuals.Goal.Parent then Visuals.Goal:Destroy() end
            Visuals.Goal = nil
        end
    end,
})

UtilitiesTab:Toggle({
    Title = "Show Threats",
    Desc = "Show the danger areas used by Runner prediction and avoidance.",
    Icon = "circle-alert",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.ShowThreats = V == true
        Settings.ShowThreatUtility = Settings.ShowThreats
        if not Settings.ShowThreats then
            for Key, Part in pairs(Visuals.Threats) do
                if Part.Parent then Part:Destroy() end
                Visuals.Threats[Key] = nil
            end
        end
    end,
})

UtilitiesTab:Toggle({
    Title = "Show Hitboxes",
    Desc = "Show simple visual spheres around players relevant to your current role.",
    Icon = "box",
    Type = "Checkbox",
    Value = true,
    Callback = function(V)
        Settings.ShowHitboxes = V == true
        if not Settings.ShowHitboxes then
            for Player, Part in pairs(Visuals.Hitboxes) do
                if Part.Parent then Part:Destroy() end
                Visuals.Hitboxes[Player] = nil
            end
        end
    end,
})

do
    local SettingsTab = Hub.rawTab(Window, {Title = "Settings", Icon = "settings"})
    Hub.SettingsTab = SettingsTab

    local function Toast(Title, content, icon)
        pcall(function()
            Hub.rawNotify(WindUI, {Title = Title, Content = content, Duration = 3, Icon = icon or "info"})
        end)
    end

    local HasFS = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"

    
    
    
    SettingsTab:Section({Title = "Interface"})

    local ThemeNames = {}
    pcall(function()
        for Name in pairs(WindUI:GetThemes()) do
            table.insert(ThemeNames, Name)
        end
    end)
    table.sort(ThemeNames)
    if #ThemeNames == 0 then
        ThemeNames = {"Dark", "Light"}
    end

    local ThemeDropdown = SettingsTab:Dropdown({
        Title = "Theme",
        Desc = "Change the window colors.",
        Values = ThemeNames,
        Value = "Default",
        Callback = function(V)
            pcall(function() WindUI:SetTheme(V) end)
        end,
    })
    Hub.register("Settings_Theme", ThemeDropdown, "Default")

    local TransparencyToggle = SettingsTab:Toggle({
        Title = "Window Transparency",
        Desc = "Make the window background translucent.",
        Icon = "layers",
        Type = "Checkbox",
        Value = true,
        Callback = function(V)
            pcall(function() Window:ToggleTransparency(V == true) end)
        end,
    })
    Hub.register("Settings_Transparency", TransparencyToggle, true)

    local ToggleKeys = {"RightShift", "LeftAlt", "RightAlt", "RightControl", "Insert", "Home", "End", "Delete", "K", "F6", "F7", "F8"}
    local KeyDropdown = SettingsTab:Dropdown({
        Title = "Toggle UI Key",
        Desc = "Key used to show or hide this window.",
        Values = ToggleKeys,
        Value = "RightShift",
        Callback = function(V)
            local Key = typeof(V) == "EnumItem" and V or Enum.KeyCode[tostring(V)]
            if Key then
                pcall(function() Window:SetToggleKey(Key) end)
            end
        end,
    })
    Hub.register("Settings_ToggleKey", KeyDropdown, "RightShift")

    local NotifyToggle = SettingsTab:Toggle({
        Title = "Notifications",
        Desc = "Show pop-up notifications (Auto Spin, Wheel, loaded message...).",
        Icon = "bell",
        Type = "Checkbox",
        Value = true,
        Callback = function(V)
            Settings.Notifications = V == true
        end,
    })
    Hub.register("Settings_Notifications", NotifyToggle, true)

    
    
    
    SettingsTab:Section({Title = "Utility"})

    local function SetAntiIdle(On)
        if Hub.IdleConn then
            Hub.IdleConn:Disconnect()
            Hub.IdleConn = nil
        end
        if On then
            Hub.IdleConn = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    local Vu = game:GetService("VirtualUser")
                    Vu:CaptureController()
                    Vu:ClickButton2(Vector2.new())
                end)
            end)
        end
    end

    local AntiIdleToggle = SettingsTab:Toggle({
        Title = "Anti Idle Kick",
        Desc = "Prevent Roblox from kicking you after 20 minutes of inactivity.",
        Icon = "timer",
        Type = "Checkbox",
        Value = true,
        Callback = function(V)
            SetAntiIdle(V == true)
        end,
    })
    Hub.register("Settings_AntiIdleKick", AntiIdleToggle, true)
    SetAntiIdle(true)

    SettingsTab:Button({
        Title = "Rejoin Server",
        Desc = "Teleport back into this same place.",
        Icon = "refresh-cw",
        Callback = function()
            pcall(function()
                local Ts = game:GetService("TeleportService")
                if #Players:GetPlayers() <= 1 then
                    Ts:Teleport(game.PlaceId, LocalPlayer)
                else
                    Ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end)
        end,
    })

    
    
    
    local function SetupConfiguration()
    SettingsTab:Section({Title = "Configuration"})

    local AutoloadFile = "Yvetzal_autoload.txt"
    local SelectedConfig = "default"
    local NewConfigName = ""

    local function CleanName(Name)
        local Cleaned = tostring(Name or ""):gsub("[^%w%-_ ]", "")
        return Cleaned:gsub("^%s+", ""):gsub("%s+$", "")
    end

    local function ListConfigs()
        local Out = {}
        local Cm = Window.ConfigManager
        if Cm and Cm.AllConfigs then
            local Ok, Res = pcall(function() return Cm:AllConfigs() end)
            if Ok and type(Res) == "table" then
                for K, V in pairs(Res) do
                    local N = type(V) == "string" and V or (type(K) == "string" and K or nil)
                    if N then
                        table.insert(Out, (N:gsub("%.json$", "")))
                    end
                end
            end
        end
        table.sort(Out)
        return Out
    end

    local function BuildConfig(Name)
        local Cm = Window.ConfigManager
        if not Cm then
            Toast("Config", "Config manager is not available in this UI version.", "triangle-alert")
            return nil
        end
        local Ok, Cfg = pcall(function() return Cm:CreateConfig(Name) end)
        if not Ok or not Cfg then
            Toast("Config", "Could not create config '" .. Name .. "'.", "triangle-alert")
            return nil
        end
        for _, Entry in ipairs(Hub.Registry) do
            pcall(function() Cfg:Register(Entry.Key, Entry.Element) end)
        end
        return Cfg
    end

    local InitialConfigs = ListConfigs()
    if #InitialConfigs == 0 then
        InitialConfigs = {"default"}
    end

    local ConfigDropdown
    local function RefreshConfigs(SelectName)
        local Names = ListConfigs()
        if #Names == 0 then
            Names = {"default"}
        end
        if ConfigDropdown then
            pcall(function() ConfigDropdown:Refresh(Names) end)
        end
        if SelectName then
            SelectedConfig = CleanName(SelectName)
            if ConfigDropdown then
                pcall(function() ConfigDropdown:Select(SelectedConfig) end)
            end
        end
    end

    ConfigDropdown = SettingsTab:Dropdown({
        Title = "Config",
        Desc = "Pick a saved config.",
        Values = InitialConfigs,
        Value = InitialConfigs[1],
        Callback = function(V)
            SelectedConfig = CleanName(V)
        end,
    })
    SelectedConfig = InitialConfigs[1]

    SettingsTab:Input({
        Title = "New Config Name",
        Desc = "Type a name, then press Create & Save.",
        Placeholder = "my-config",
        Value = "",
        Callback = function(V)
            NewConfigName = CleanName(V)
        end,
    })

    SettingsTab:Button({
        Title = "Create & Save",
        Desc = "Save all current settings under the new name.",
        Icon = "file-plus",
        Callback = function()
            if NewConfigName == "" then
                Toast("Config", "Enter a config name first.", "triangle-alert")
                return
            end
            local Cfg = BuildConfig(NewConfigName)
            if Cfg and pcall(function() Cfg:Save() end) then
                Toast("Config", "Saved '" .. NewConfigName .. "'.", "check")
                RefreshConfigs(NewConfigName)
            end
        end,
    })

    SettingsTab:Button({
        Title = "Save Config",
        Desc = "Overwrite the selected config with the current settings.",
        Icon = "save",
        Callback = function()
            local Name = CleanName(SelectedConfig)
            if Name == "" then
                return
            end
            local Cfg = BuildConfig(Name)
            if Cfg and pcall(function() Cfg:Save() end) then
                Toast("Config", "Saved '" .. Name .. "'.", "check")
                RefreshConfigs(Name)
            end
        end,
    })

    SettingsTab:Button({
        Title = "Load Config",
        Desc = "Apply the selected config to every setting.",
        Icon = "folder-open",
        Callback = function()
            local Name = CleanName(SelectedConfig)
            if Name == "" then
                return
            end
            local Cfg = BuildConfig(Name)
            if Cfg then
                if pcall(function() Cfg:Load() end) then
                    Toast("Config", "Loaded '" .. Name .. "'.", "check")
                else
                    Toast("Config", "Config '" .. Name .. "' was not found.", "triangle-alert")
                end
            end
        end,
    })

    SettingsTab:Button({
        Title = "Delete Config",
        Desc = "Permanently delete the selected config.",
        Icon = "trash-2",
        Callback = function()
            local Name = CleanName(SelectedConfig)
            if Name == "" then
                return
            end
            local Cfg = BuildConfig(Name)
            if Cfg and pcall(function() Cfg:Delete() end) then
                Toast("Config", "Deleted '" .. Name .. "'.", "check")
                RefreshConfigs()
            end
        end,
    })

    SettingsTab:Toggle({
        Title = "Auto Load Selected Config",
        Desc = "Load the selected config automatically every time the script is executed.",
        Icon = "rotate-ccw",
        Type = "Checkbox",
        Value = HasFS and isfile(AutoloadFile) or false,
        Callback = function(V)
            if not HasFS then
                Toast("Config", "Your executor has no file access.", "triangle-alert")
                return
            end
            pcall(function()
                if V then
                    writefile(AutoloadFile, CleanName(SelectedConfig))
                elseif isfile(AutoloadFile) and type(delfile) == "function" then
                    delfile(AutoloadFile)
                end
            end)
        end,
    })

    SettingsTab:Button({
        Title = "Reset All Settings",
        Desc = "Restore every Runner, Catcher, Wheel, Journey, Map Vote and Utilities option to its default.",
        Icon = "rotate-ccw",
        Callback = function()
            local Count = 0
            for _, Entry in ipairs(Hub.Registry) do
                if Entry.Default ~= nil then
                    if pcall(function() Entry.Element:Set(Entry.Default) end) then
                        Count = Count + 1
                    end
                end
            end
            Toast("Settings", "Reset " .. Count .. " options to default.", "check")
        end,
    })

    
    
    
    SettingsTab:Section({Title = "About"})

    SettingsTab:Paragraph({
        Title = "Yvetzal",
        Desc = "Huss Valley helper.\nCreated by Wyrizon and the Yvetzal Team.\nToggle the window with the selected key (default: RightShift).",
    })

    SettingsTab:Button({
        Title = "Unload Script",
        Desc = "Stop everything, remove visuals and close the window.",
        Icon = "power",
        Callback = function()
            if Hub.cleanup then
                Hub.cleanup()
            end
        end,
    })

    
    if HasFS then
        local Ok, Saved = pcall(function()
            if isfile(AutoloadFile) then
                return CleanName(readfile(AutoloadFile))
            end
        end)
        if Ok and type(Saved) == "string" and Saved ~= "" then
            SelectedConfig = Saved
            task.delay(1, function()
                if Hub.Cleaned then
                    return
                end
                local Cfg = BuildConfig(Saved)
                if Cfg and pcall(function() Cfg:Load() end) then
                    pcall(function() ConfigDropdown:Select(Saved) end)
                    Toast("Config", "Auto-loaded '" .. Saved .. "'.", "check")
                end
            end)
        end
        end
        SetupConfiguration()
    end
end

WindUI:Notify({
    Title = "Yvetzal",
    Content = "Loaded. Auto Run is enabled by default.",
    Duration = 4,
    Icon = "wind",
})

local SpeedRenderName = "CoH_SpeedOverride"
RunService:UnbindFromRenderStep(SpeedRenderName)
RunService:BindToRenderStep(SpeedRenderName, Enum.RenderPriority.Input.Value + 2, function()
    local Role = GetRole()
    local Character = GetCharacter()
    local Hum = GetHumanoid()
    if not Character or not Hum or Hum.Health <= 0 then
        return
    end

    local State = Character:GetAttribute("MovementState")
    if State == "Dashing" or State == "Boosting" then
        return
    end

    local NativeOutput = tonumber(Character:GetAttribute("MovementSpeed"))
    if NativeOutput and NativeOutput > 0 then
        local DesiredSpeed = NativeOutput
        if Role == "Runner" and Settings.CustomSpeed and Settings.SpeedMultiplier > 1.0001 then
            DesiredSpeed = NativeOutput * math.clamp(Settings.SpeedMultiplier, 1, 2)
        elseif Role == "Catcher" and Settings.CatcherCustomSpeed and Settings.CatcherSpeedMultiplier > 1.0001 then
            DesiredSpeed = NativeOutput * math.clamp(Settings.CatcherSpeedMultiplier, 1, 2)
        end
        if math.abs(Hum.WalkSpeed - DesiredSpeed) > 0.05 then
            Hum.WalkSpeed = DesiredSpeed
        end
    end
end)

local RenderName = "CoH_StableController"
RunService:UnbindFromRenderStep(RenderName)

RunService:BindToRenderStep(RenderName, Enum.RenderPriority.Input.Value, function(Dt)
    local Now = os.clock()
    local Ok, Err = pcall(RunnerStep, Now, Dt)
    if not Ok then
        SetDebugError("Runner: " .. tostring(Err))
    end

    Ok, Err = pcall(CatcherStep, Now, Dt)
    if not Ok then
        SetDebugError("Catcher: " .. tostring(Err))
    end

    if Now - Runtime.UtilityTick >= 0.25 then
        Runtime.UtilityTick = Now
        Ok, Err = pcall(UtilityStep, Now)
        if not Ok then
            SetDebugError("Utility: " .. tostring(Err))
        end
    end

    if Runtime.DebugEnabled and Now - (Runtime.DebugPanelAt or -math.huge) >= 0.1 then
        Runtime.DebugPanelAt = Now
        local DebugOk, DebugErr = pcall(UpdateDebugPanel, Now)
        if not DebugOk then
            SetDebugError("DebugPanel: " .. tostring(DebugErr))
        end
    end
end)




Hub.cleanup = function()
    if Hub.Cleaned then
        return
    end
    Hub.Cleaned = true

    
    for Key, Value in pairs(Settings) do
        if type(Value) == "boolean" then
            Settings[Key] = false
        end
    end

    pcall(CancelRevive)
    pcall(function() RunService:UnbindFromRenderStep(RenderName) end)
    pcall(function() RunService:UnbindFromRenderStep(SpeedRenderName) end)
    pcall(RestoreNativeWalkSpeed)
    pcall(CleanupVisuals)

    if Hub.IdleConn then
        pcall(function() Hub.IdleConn:Disconnect() end)
        Hub.IdleConn = nil
    end

    Runtime.MapCache = nil
    Runtime.MapCacheAt = -math.huge
    Runtime.RunnerPlanAt = -math.huge
    Runtime.RunnerPlanDirection = Vector3.zero
    Runtime.RunnerPlanGoal = Vector3.zero
    Runtime.WheelLastButton = nil
    Runtime.WheelStatus = "disabled"
    Runtime.WheelSpinning = false
    Runtime.WheelNextAttemptAt = -math.huge
    Runtime.JourneyStatus = "disabled"
    Runtime.JourneyClaimedButtons = {}
    Runtime.JourneyLoaded = false
    Runtime.JourneySeasonId = nil
    Runtime.JourneyClaimInFlight = false
    Runtime.JourneyTier = 1
    Runtime.JourneyPremium = false
    Runtime.JourneyClaims = {}
    Runtime.MapVoteStatus = "disabled"
    Runtime.MapVoteOptions = {}
    Runtime.MapVoteOpen = false
    Runtime.SafeCheckAt = -math.huge
    Runtime.SafeCheckPosition = nil
    EdgeRayCache.Map = nil
    EdgeRayCache.Field = nil
    EdgeRayCache.Params = nil
    EdgeRayCache.InvisWall = nil
    EdgeRayCache.WallParams = nil

    pcall(function()
        if Runtime.DebugGui then
            Runtime.DebugGui:Destroy()
        end
    end)

    if Hub.Genv.YvetzalUnload == Hub.cleanup then
        Hub.Genv.YvetzalUnload = nil
    end

    pcall(function() Window:Destroy() end)
end

Hub.Genv.YvetzalUnload = Hub.cleanup
pcall(function()
    Window:OnDestroy(function()
        Hub.cleanup()
    end)
end)


function Hub.selectRunnerTab()
    if Hub.Cleaned then
        return
    end
    pcall(function() RunnerTab:Select() end)
    pcall(function() Window:SelectTab(1) end)
end
Hub.selectRunnerTab()
task.delay(0.5, Hub.selectRunnerTab)
task.delay(1.5, Hub.selectRunnerTab)
