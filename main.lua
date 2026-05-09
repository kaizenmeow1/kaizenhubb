if not LPH_OBFUSCATED then
    LPH_ENCNUM = function(toEncrypt, ...)
        assert(type(toEncrypt) == "number" and #{...} == 0, "LPH_ENCNUM only accepts a single double or integer as an argument.")
        return toEncrypt
    end
    LPH_NUMENC = LPH_ENCNUM

    LPH_ENCSTR = function(toEncrypt, ...)
        assert(type(toEncrypt) == "string" and #{...} == 0, "LPH_ENCSTR only accepts a single string as an argument.")
        return toEncrypt
    end
    LPH_STRENC = LPH_ENCSTR

    LPH_ENCFUNC = function(toEncrypt, encKey, decKey, ...)
        assert(type(toEncrypt) == "function" and type(encKey) == "string" and #{...} == 0, "LPH_ENCFUNC accepts a function, constant string, and string variable as arguments.")
        return toEncrypt
    end
    LPH_FUNCENC = LPH_ENCFUNC

    LPH_JIT = function(f, ...)
        assert(type(f) == "function" and #{...} == 0, "LPH_JIT only accepts a single function as an argument.")
        return f
    end
    LPH_JIT_MAX = LPH_JIT

    LPH_NO_VIRTUALIZE = function(f, ...)
        assert(type(f) == "function" and #{...} == 0, "LPH_NO_VIRTUALIZE only accepts a single function as an argument.")
        return f
    end

    LPH_NO_UPVALUES = function(f, ...)
        assert(type(setfenv) == "function", "LPH_NO_UPVALUES can only be used on Lua versions with getfenv & setfenv")
        assert(type(f) == "function" and #{...} == 0, "LPH_NO_UPVALUES only accepts a single function as an argument.")
        return f
    end

    LPH_CRASH = function(...)
        assert(#{...} == 0, "LPH_CRASH does not accept any arguments.")
        error("LPH_CRASH called")
    end
end

local SpeedHubX
do
    local ok, library = pcall(function()
        if typeof(readfile) == "function"
           and typeof(isfile) == "function"
           and isfile("kaizenhubui.lua") then
            return loadstring(readfile("kaizenhubui.lua"))()
        end
    end)

    SpeedHubX = (ok and library)
        or loadstring(game:HttpGet("https://raw.githubusercontent.com/biarzxc1/kaizenhub/main/Library.lua"))()
end

-- ============================================================
--                    KEY SYSTEM (Kaizen Hub)
-- ============================================================
local KEY_VALID    = "FIRSTRELEASED"
local KEY_FILE     = "kaizenhub_key.txt"
local DISCORD_LINK = "https://discord.gg/kaizenhub"  -- replace with your real invite

local function _readKey()
    local ok, data = pcall(function()
        if typeof(isfile) == "function" and isfile(KEY_FILE)
           and typeof(readfile) == "function" then
            return readfile(KEY_FILE)
        end
    end)
    return ok and data or nil
end

local function _saveKey()
    pcall(function()
        if typeof(writefile) == "function" then writefile(KEY_FILE, KEY_VALID) end
    end)
end

local _verified = (_readKey() == KEY_VALID)

if not _verified then
    -- snapshot existing UI containers so we can find/destroy our key gui
    local function _hui()
        return (gethui and gethui())
            or (cloneref and cloneref(game:GetService("CoreGui")))
            or game:GetService("CoreGui")
    end
    local _before = {}
    for _, c in ipairs(_hui():GetChildren()) do _before[c] = true end

    local KeyWindow = SpeedHubX:CreateWindow({
        Title       = "Kaizen Hub Version 1.0.0",
        Description = "Enter your key to unlock the script",
        SizeUi      = UDim2.fromOffset(460, 280),
    })

    -- locate the freshly-created ScreenGui
    local KeyGui
    for _, c in ipairs(_hui():GetChildren()) do
        if not _before[c] and c:IsA("ScreenGui") then KeyGui = c break end
    end

    local KeyTab     = KeyWindow:CreateTab({ Name = "Key", Icon = "key" })
    local KeySection = KeyTab:AddSection("Authentication", true)

    local _entered = ""

    KeySection:AddInput({
        Title    = "License Key",
        Content  = "Paste your key here",
        Default  = "",
        Callback = function(v) _entered = tostring(v or "") end,
    })

    local function _keyNotify(desc, content, delay)
        pcall(function()
            SpeedHubX:SetNotification({
                Title       = "Kaizen Hub",
                Description = desc or "",
                Content     = content or "",
                Time        = 0.4,
                Delay       = delay or 4,
            })
        end)
    end

    KeySection:AddButton({
        Title    = "Submit Key",
        Content  = "Verify and unlock",
        Callback = function()
            if _entered == KEY_VALID then
                _verified = true
                _saveKey()
                _keyNotify("Key accepted!", "Loading script...", 3)
                task.wait(0.4)
                if KeyGui then pcall(function() KeyGui:Destroy() end) end
            else
                _keyNotify("Invalid key", "Please try again.", 4)
            end
        end,
    })

    KeySection:AddButton({
        Title    = "Get Key (Discord)",
        Callback = function()
            pcall(function()
                if setclipboard then setclipboard(DISCORD_LINK)
                elseif toclipboard then toclipboard(DISCORD_LINK) end
            end)
            _keyNotify("Discord link copied", DISCORD_LINK, 5)
        end,
    })

    -- block until verified
    repeat task.wait(0.1) until _verified
end
-- ============================================================
--                  END KEY SYSTEM
-- ============================================================


local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PromptService     = game:GetService("ProximityPromptService")
local HttpService       = game:GetService("HttpService")

local LocalPlayer      = Players.LocalPlayer
local CharactersFolder = Workspace:WaitForChild("Characters")

local HUB_VERSION     = "Version 1.0.0"
local HUB_CREDIT      = "Developed by Kaizen ZSTAFF"
local HUB_DESCRIPTION = HUB_VERSION .. " | " .. HUB_CREDIT

local State = {
    AutoShoot          = false,
    GunAuraMethod      = "Default",
    Range              = 250,
    FireRate           = 0.01,
    BurstCount         = 1,
    WallCheck          = true,
    MeleeAura          = false,
    MeleeRange         = 20,
    MeleeAttackSpeed   = 0.02,
    MeleeMaxTargets    = 6,

    AutoReload         = false,
    RAAutoReload       = false,
    RAAutoReloadSpeed  = 3,

    ESPEnabled         = false,
    ESPRange           = 250,
    ItemESPRange       = 250,

    AutoLoot           = false,
    PreventLootInBase  = true,
    AutoLootFilters = {
        Medical   = true, Blueprint = true, Throwable = true,
        Melee     = true, Gun       = true, Resource  = true,
        Food      = true, Fuel      = true, Ammo      = true,
    },
    AutoPickUp         = false,
    AutoPickUpRange    = 20,
    AutoPickUpIndicator = false,
    AutoPickUpFilters = {
        Backpack  = true, Gun       = true, Melee     = true,
        Blueprint = true, Throwable = true, Medical   = true,
        Ammo      = true, Armor     = true,
        Misc      = true,
    },

    NoRecoil           = false,
    NoSpread           = false,
    InstantHit         = false,
    NoAnimationReload  = false,

    WalkSpeedEnabled   = false,
    WalkSpeedValue     = 25,
    AutoOpenCrates     = false,
    AutoEat            = false,
    AutoEatThreshold   = 90,
    AutoHeal           = false,
    AutoHealThreshold  = 70,
    InfiniteJump       = false,
    NoClip             = false,
    InstantPrompt      = false,
    ReduceLag          = false,
    RemoveFog          = false,

    ESP_Items = {
        Medical = false, Blueprint = false, Throwable = false,
        Melee   = false, Gun       = false, Resource  = false,
        Food    = false, Fuel      = false, Ammo      = false,
        Emerald = false, Survivors = false, Crates = false,
    },
}


local PICKUP_RANGE_DEFAULT = 20
local PICKUP_RANGE_MIN     = 5
local PICKUP_RANGE_MAX     = 20

function clampPickupRange(value)
    local n = math.floor(tonumber(value) or PICKUP_RANGE_DEFAULT)
    if n < PICKUP_RANGE_MIN then n = PICKUP_RANGE_MIN end
    if n > PICKUP_RANGE_MAX then n = PICKUP_RANGE_MAX end
    return n
end

function getPickupRange()
    local n = clampPickupRange(State.AutoPickUpRange)
    if State.AutoPickUpRange ~= n then
        State.AutoPickUpRange = n
    end
    return n
end

local ThreatTier = {
    Brute = 5, Experiment = 5, Exterminator = 5, ["Electrified Muscle"] = 5,
    Muscle = 4, Screamer = 4, ["Night Hunter"] = 4, Elemental = 4, Electrified = 4,
    ["Armored Zombie"] = 3, ["Enforcer Riot"] = 3,
    ["Bloater Acidic"] = 3, ["Blitzer Runner"] = 3,
    Riot = 3, Spitter = 3, Phaser = 3, Hazmat = 3, Bloater = 3,
    Bandit = 3, Rebel = 3, Gunner = 3, Sniper = 3,
    ["Heavy Rebel"] = 3, Butcher = 3,
    Runner = 2, Crawler = 2,
    Zombie = 1, ["Emerald Zombie"] = 1,
}

local SupportedTypes = {}
for name in pairs(ThreatTier) do SupportedTypes[name] = true end

local math_sqrt  = math.sqrt
local math_floor = math.floor
local os_clock   = os.clock

findHead = LPH_JIT_MAX(function(model)
    local h = model:FindFirstChild("Head")
    if h and h:IsA("BasePart") then return h end
    for _, p in ipairs(model:GetChildren()) do
        if p:IsA("BasePart") and p.Name:lower():find("head") then return p end
    end
    return model:FindFirstChild("HumanoidRootPart")
end)

findAimHead = LPH_JIT_MAX(function(model)
    local h = model and model:FindFirstChild("Head")
    if h and h:IsA("BasePart") then return h end
    if not model then return nil end
    for _, p in ipairs(model:GetChildren()) do
        if p:IsA("BasePart") and p.Name:lower():find("head") then return p end
    end
    return nil
end)

isAliveSupportedEnemy = LPH_JIT_MAX(function(model)
    if not (model and model.Parent and SupportedTypes[model.Name]) then return false end
    if model:GetAttribute("Dead") then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end)

local WallCheckParams = RaycastParams.new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Include
pcall(function() WallCheckParams.RespectCanCollide = true end)
pcall(function() WallCheckParams.CollisionGroup = "Default" end)

local WallCheckRoots = {}
local lastWallCheckRoots = -999

function getWallCheckRoots()
    local now = os_clock()
    if now - lastWallCheckRoots < 0.5 then
        return WallCheckRoots
    end

    lastWallCheckRoots = now
    table.clear(WallCheckRoots)

    local map = Workspace:FindFirstChild("Map")
    if map then
        WallCheckRoots[#WallCheckRoots + 1] = map
        local border = map:FindFirstChild("Border")
        if border then WallCheckRoots[#WallCheckRoots + 1] = border end
    end

    local structures = Workspace:FindFirstChild("Structures")
    if structures then WallCheckRoots[#WallCheckRoots + 1] = structures end

    return WallCheckRoots
end

hasClearShot = LPH_JIT_MAX(function(originPos, targetModel, targetPart)
    if not State.WallCheck then return true end
    if not (originPos and targetPart and targetPart.Parent) then return false end

    local direction = targetPart.Position - originPos
    if (direction.X*direction.X + direction.Y*direction.Y + direction.Z*direction.Z) <= 0.0025 then return true end

    local roots = getWallCheckRoots()
    if #roots == 0 then return true end

    WallCheckParams.FilterDescendantsInstances = roots
    local result = Workspace:Raycast(originPos, direction, WallCheckParams)
    if not result then return true end

    local hit = result.Instance
    return hit ~= nil and targetModel ~= nil and hit:IsDescendantOf(targetModel)
end)

local EnemyCache = {}
local EnemyCacheConns = {}
local enemyCacheDirty = true
local lastEnemyCacheRefresh = -999
local ENEMY_CACHE_REFRESH = 0.2

local function markEnemyCacheDirty()
    enemyCacheDirty = true
end

local function disconnectEnemyWatcher(model)
    local conns = EnemyCacheConns[model]
    if conns then
        for _, conn in ipairs(conns) do
            pcall(function() conn:Disconnect() end)
        end
    end
    EnemyCacheConns[model] = nil
end

local function watchEnemyModel(model)
    if not (model and model:IsA("Model") and SupportedTypes[model.Name]) then return end
    if EnemyCacheConns[model] then return end

    local conns = {}
    conns[#conns + 1] = model.AncestryChanged:Connect(markEnemyCacheDirty)
    conns[#conns + 1] = model.ChildAdded:Connect(markEnemyCacheDirty)
    conns[#conns + 1] = model.ChildRemoved:Connect(markEnemyCacheDirty)

    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        conns[#conns + 1] = hum.Died:Connect(markEnemyCacheDirty)
    end

    EnemyCacheConns[model] = conns
    markEnemyCacheDirty()
end

rebuildEnemyCache = LPH_JIT_MAX(function()
    table.clear(EnemyCache)

    for _, model in ipairs(CharactersFolder:GetChildren()) do
        if SupportedTypes[model.Name] then
            watchEnemyModel(model)
            local head = findAimHead(model)
            local hum = model:FindFirstChildOfClass("Humanoid")
            if head and hum then
                EnemyCache[#EnemyCache + 1] = {
                    Model = model,
                    Head = head,
                    Hum = hum,
                }
            end
        end
    end

    lastEnemyCacheRefresh = os_clock()
    enemyCacheDirty = false
end)

getEnemyCache = LPH_JIT_MAX(function()
    local now = os_clock()
    if enemyCacheDirty or (now - lastEnemyCacheRefresh) >= ENEMY_CACHE_REFRESH then
        rebuildEnemyCache()
    end
    return EnemyCache
end)

CharactersFolder.ChildAdded:Connect(LPH_JIT_MAX(function(model)
    watchEnemyModel(model)
    markEnemyCacheDirty()
end))

CharactersFolder.ChildRemoved:Connect(LPH_JIT_MAX(function(model)
    disconnectEnemyWatcher(model)
    markEnemyCacheDirty()
end))

for _, model in ipairs(CharactersFolder:GetChildren()) do
    watchEnemyModel(model)
end

local CachedCenterTile, CachedCenterPart = nil, nil
local lastCenterResolve = 0

function resolveCenterTile()
    local now = os_clock()
    if CachedCenterPart and CachedCenterPart.Parent and (now - lastCenterResolve) < 1 then
        return CachedCenterTile, CachedCenterPart
    end
    lastCenterResolve = now
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    local tiles = map:FindFirstChild("Tiles")
    if not tiles then return nil end
    local center = tiles:FindFirstChild("Center")
    if not center then return nil end
    local part = center.PrimaryPart
        or center:FindFirstChild("Tile_120")
        or center:FindFirstChild("CollideFloor")
        or center:FindFirstChildWhichIsA("BasePart")
    if not part then return nil end
    CachedCenterTile, CachedCenterPart = center, part
    return center, part
end

function isPlayerInBaseCenter(hrpPos)
    local _, part = resolveCenterTile()
    if not part then return false end
    local lp = part.CFrame:PointToObjectSpace(hrpPos)
    local sz = part.Size
    local halfX, halfZ = sz.X * 0.5, sz.Z * 0.5
    if math.abs(lp.X) > halfX then return false end
    if math.abs(lp.Z) > halfZ then return false end
    if lp.Y < -10 or lp.Y > 80 then return false end
    return true
end

function findRA()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil, nil end
    local ra = char:FindFirstChild("Remote Arsenal")
    if not ra then return nil, nil, nil, nil end
    local shoot    = ra:FindFirstChild("Shoot",    true)
    local reload   = ra:FindFirstChild("Reload",   true)
    local syncAmmo = ra:FindFirstChild("SyncAmmo", true)
    return ra, shoot, reload, syncAmmo
end

local raSlotTools = {}
local raSlotData = {}
local raSlotCount = 0
local raSetWeaponsConn = nil
local raHookedRemote = nil
local raAmmoConns = {}
local raReloadingSlots = {}
local raReloadCooldown = {}
local raSyncCooldown = {}
local raFallbackCooldown = {}
local raOriginalReloadSpeed = nil
local raAppliedReloadSpeed = nil
local raReloadSpeedChar = nil
local raReloadSpeedSaved = false
local RA_RELOAD_CHECK_DELAY = 0.12
local RA_RELOAD_RETRY = 0.22
local RA_SYNC_RETRY = 0.45
local RA_FALLBACK_RELOAD_RETRY = 1.25
local MAIN_AUTO_RELOAD_SPEED = 6
local MAIN_NO_ANIM_RELOAD_SPEED = 8
local doRAReloadSlot

function clearRAAmmoConns()
    for _, conn in ipairs(raAmmoConns) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(raAmmoConns)
end

function getRAStatsObject(entry)
    if not entry then return nil end
    if entry.Stats and entry.Stats.Parent then return entry.Stats end
    local tool = entry.Tool
    return tool and tool:FindFirstChild("Stats") or nil
end

function readRASlotStats(entry)
    local statsObj = getRAStatsObject(entry)
    if not statsObj then return {} end
    local ok, attrs = pcall(function() return statsObj:GetAttributes() end)
    return (ok and attrs) or {}
end

function refreshRASlot(slot)
    local entry = raSlotData[slot]
    if not entry then return nil end
    local tool = entry.Tool
    if not (tool and tool.Parent) then return nil end

    local ammo = tool:GetAttribute("Ammo")
    local stats = readRASlotStats(entry)
    local capacity = tonumber(stats.Capacity) or tonumber(tool:GetAttribute("Capacity")) or 0
    local ammoType = stats.AmmoType or tool:GetAttribute("AmmoType")

    entry.Ammo = tonumber(ammo)
    entry.Capacity = capacity
    entry.AmmoType = ammoType
    entry.StatsCache = stats
    return entry
end

function rebuildRASlots(weapons)
    clearRAAmmoConns()
    raSlotTools = {}
    raSlotData = {}
    raSlotCount = type(weapons) == "table" and #weapons or 0

    if type(weapons) ~= "table" then return end
    for i, w in ipairs(weapons) do
        if type(w) == "table" and w.Tool then
            raSlotTools[i] = w.Tool
            raSlotData[i] = {
                Tool = w.Tool,
                Model = w.Model,
                Stats = w.Stats,
                Barrel = w.Barrel,
            }
            refreshRASlot(i)

            local tool = w.Tool
            if tool then
                local ok, signal = pcall(function()
                    return tool:GetAttributeChangedSignal("Ammo")
                end)
                if ok and signal then
                    raAmmoConns[#raAmmoConns + 1] = signal:Connect(LPH_JIT_MAX(function()
                        refreshRASlot(i)
                        if State.RAAutoReload then
                            local e = raSlotData[i]
                            if e and e.Ammo ~= nil and e.Ammo <= 0 and doRAReloadSlot then
                                task.defer(doRAReloadSlot, i)
                            end
                        end
                    end))
                end
            end
        end
    end
end

function hookSetWeaponsClient(ra)
    if not ra then return end
    local swc = ra:FindFirstChild("SetWeaponsClient", true)
    if not swc then return end
    if raHookedRemote == swc and raSetWeaponsConn then return end

    if raSetWeaponsConn then
        pcall(function() raSetWeaponsConn:Disconnect() end)
        raSetWeaponsConn = nil
    end

    raHookedRemote = swc
    raSetWeaponsConn = swc.OnClientEvent:Connect(rebuildRASlots)
end

function getDesiredReloadSpeedBoost()
    local boost = 0
    if State.RAAutoReload then
        boost = math.max(boost, math.clamp(tonumber(State.RAAutoReloadSpeed) or 3, 1, 6))
    end
    if State.AutoReload then
        boost = math.max(boost, MAIN_AUTO_RELOAD_SPEED)
    end
    if State.NoAnimationReload then
        boost = math.max(boost, MAIN_NO_ANIM_RELOAD_SPEED)
    end
    return boost
end

function resetReloadSpeedAttribute(char)
    if not raReloadSpeedSaved then return end
    local targetChar = char or raReloadSpeedChar
    if targetChar and targetChar.Parent then
        local saved = raOriginalReloadSpeed
        pcall(function() targetChar:SetAttribute("ReloadSpeed", saved) end)
    end
    raOriginalReloadSpeed = nil
    raAppliedReloadSpeed = nil
    raReloadSpeedChar = nil
    raReloadSpeedSaved = false
end

function applyRAReloadSpeedAttribute(_)
    local char = LocalPlayer.Character
    if not char then return end

    local boost = getDesiredReloadSpeedBoost()
    if boost > 0 then
        if raReloadSpeedChar ~= char then
            resetReloadSpeedAttribute()
            raReloadSpeedChar = char
            raOriginalReloadSpeed = char:GetAttribute("ReloadSpeed")
            raReloadSpeedSaved = true
        end
        local original = tonumber(raOriginalReloadSpeed) or 0
        local target = math.max(original, boost)
        if raAppliedReloadSpeed ~= target or char:GetAttribute("ReloadSpeed") ~= target then
            raAppliedReloadSpeed = target
            pcall(function() char:SetAttribute("ReloadSpeed", target) end)
        end
    elseif raReloadSpeedSaved then
        resetReloadSpeedAttribute(char)
    end
end

function getRAReserve(entry)
    local ammoFolder = LocalPlayer:FindFirstChild("Ammo")
    if not ammoFolder then return nil end
    local ammoType = entry and entry.AmmoType
    if not ammoType then return nil end
    local reserve = ammoFolder:GetAttribute(ammoType)
    if typeof(reserve) == "number" then return reserve end
    return nil
end

function getRAReloadWindow(entry)
    local stats = (entry and entry.StatsCache) or readRASlotStats(entry)
    local cap = tonumber(entry and entry.Capacity) or tonumber(stats.Capacity) or 1
    local reloadTime = tonumber(stats.ReloadTime) or 0
    local individual = tonumber(stats.ReloadIndividualTime) or 0
    local endTime = tonumber(stats.ReloadEndTime) or 0
    local total = reloadTime + (individual * math.max(cap, 1)) + endTime
    if total <= 0 then total = 0.35 end

    local boost = 1 + math.max(0, math.min(5, tonumber(State.RAAutoReloadSpeed) or 3))
    return math.clamp((total / boost) + 0.05, 0.08, 2.5)
end

doRAReloadSlot = function(slot)
    slot = tonumber(slot)
    if not slot or slot < 1 then return end

    local now = os_clock()
    if raReloadingSlots[slot] then return end
    if raReloadCooldown[slot] and (now - raReloadCooldown[slot]) < RA_RELOAD_RETRY then return end
    raReloadCooldown[slot] = now

    local entry = refreshRASlot(slot)
    if not (entry and entry.Tool) then return end
    if entry.Ammo ~= nil and entry.Ammo > 0 then return end
    if entry.Capacity and entry.Capacity > 0 and entry.Ammo and entry.Ammo >= entry.Capacity then return end

    local reserve = getRAReserve(entry)
    if reserve ~= nil and reserve <= 0 then return end

    local _, _, reload, syncAmmo = findRA()
    if not reload then return end

    raReloadingSlots[slot] = true
    if entry.Model then
        pcall(function() entry.Model:SetAttribute("Reloading", true) end)
    end
    applyRAReloadSpeedAttribute(true)

    task.spawn(LPH_JIT_MAX(function()
        if syncAmmo then
            pcall(function() syncAmmo:FireServer(slot) end)
        end

        local ok, newAmmo = pcall(function()
            return reload:InvokeServer(nil, slot)
        end)
        if ok and typeof(newAmmo) == "number" and entry.Tool and entry.Tool.Parent then
            pcall(function() entry.Tool:SetAttribute("Ammo", newAmmo) end)
            entry.Ammo = newAmmo
        end

        local waitUntil = os_clock() + getRAReloadWindow(entry)
        while State.RAAutoReload and os_clock() < waitUntil do
            local e = refreshRASlot(slot)
            if e and e.Ammo ~= nil and e.Ammo > 0 then break end
            task.wait(0.04)
        end

        if entry.Model then
            pcall(function() entry.Model:SetAttribute("Reloading", false) end)
        end
        raReloadingSlots[slot] = nil
    end))
end

function syncRASlot(slot)
    local now = os_clock()
    if raSyncCooldown[slot] and (now - raSyncCooldown[slot]) < RA_SYNC_RETRY then return end
    raSyncCooldown[slot] = now
    local _, _, _, syncAmmo = findRA()
    if syncAmmo then
        pcall(function() syncAmmo:FireServer(slot) end)
    end
end

function fallbackRAReloadSlot(slot)
    local now = os_clock()
    if raFallbackCooldown[slot] and (now - raFallbackCooldown[slot]) < RA_FALLBACK_RELOAD_RETRY then return end
    raFallbackCooldown[slot] = now

    local _, _, reload, syncAmmo = findRA()
    if syncAmmo then
        pcall(function() syncAmmo:FireServer(slot) end)
    end
    if reload then
        task.spawn(LPH_JIT_MAX(function()
            pcall(function() reload:InvokeServer(nil, slot) end)
        end))
    end
end

function doRAReload()
    local slots = math.max(raSlotCount, 4)
    for slot = 1, slots do
        local entry = refreshRASlot(slot)
        if entry and entry.Ammo ~= nil then
            if entry.Ammo <= 0 then
                doRAReloadSlot(slot)
            end
        else
            syncRASlot(slot)
            if raSlotCount == 0 then
                fallbackRAReloadSlot(slot)
            end
        end
    end
end

function readRAAmmo()
    local total, any = 0, false
    for slot = 1, math.max(raSlotCount, 4) do
        local entry = refreshRASlot(slot)
        if entry and entry.Ammo ~= nil then
            total = total + entry.Ammo
            any = true
        end
    end
    if not any then return nil end
    return total
end

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(1)
        local ra = findRA()
        if ra then
            hookSetWeaponsClient(ra)
            break
        end
    end
end))

LocalPlayer.CharacterAdded:Connect(LPH_JIT_MAX(function()
    task.wait(2)
    local ra = findRA()
    if ra then hookSetWeaponsClient(ra) end
    applyRAReloadSpeedAttribute()
end))

local CachedRAShoot = nil
function getRAShoot()
    if CachedRAShoot and CachedRAShoot.Parent then return CachedRAShoot end
    local _, shoot = findRA()
    CachedRAShoot = shoot
    return shoot
end

local CachedTool, CachedShoot, CachedReload = nil, nil, nil
local MAIN_AMMO_FIELDS = { "Ammo", "Mag", "Magazine", "Bullets" }

function invalidateWeapon()
    CachedTool, CachedShoot, CachedReload = nil, nil, nil
    CachedRAShoot = nil
end

function resolveWeapon()
    if CachedTool and CachedTool.Parent == LocalPlayer.Character then
        return CachedTool, CachedShoot, CachedReload
    end
    invalidateWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name ~= "Remote Arsenal" then
            local s = tool:FindFirstChild("Shoot")
            local r = tool:FindFirstChild("Reload")
            if s or r then
                CachedTool, CachedShoot, CachedReload = tool, s, r
                return tool, s, r
            end
        end
    end
    return nil
end

function findToolDescendant(tool, ...)
    if not tool then return nil end
    for i = 1, select("#", ...) do
        local inst = tool:FindFirstChild(select(i, ...), true)
        if inst then return inst end
    end
    return nil
end

function getWeaponOrigin(tool, fallbackPos)
    if tool and tool:IsDescendantOf(Workspace) then
        local barrel = findToolDescendant(tool, "Barrel", "Muzzle")
        if barrel then
            if barrel:IsA("Attachment") then return barrel.WorldPosition end
            if barrel:IsA("BasePart")   then return barrel.Position end
        end
        local handle = findToolDescendant(tool, "Handle", "FakeHandle")
        if handle and handle:IsA("BasePart") then return handle.Position end
    end
    return fallbackPos
end

function getToolStats(tool)
    return tool and tool:FindFirstChild("Stats") or nil
end

function getMainAmmoSync(tool)
    local syncAmmo = findToolDescendant(tool, "SyncAmmo")
    if syncAmmo and syncAmmo:IsA("RemoteEvent") then return syncAmmo end
    return nil
end

function getReserveAmmo(tool)
    local stats = getToolStats(tool)
    local ammoFolder = LocalPlayer:FindFirstChild("Ammo")
    if not (stats and ammoFolder) then return nil end

    local ammoType = stats:GetAttribute("AmmoType")
    if not ammoType or ammoType == "Fuel" then return nil end

    if ammoType == "Grenade" then
        local char = LocalPlayer.Character
        local grenade = (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Grenade"))
            or (char and char:FindFirstChild("Grenade"))
        if grenade then return grenade:GetAttribute("Stacks") or 1 end
        return 0
    end

    local reserve = ammoFolder:GetAttribute(ammoType)
    if typeof(reserve) == "number" then return reserve end
    return nil
end

function getReloadWindow(tool)
    local stats = getToolStats(tool)
    if not stats then return 0.3 end

    local animSpeed = tonumber(stats:GetAttribute("ReloadAnimSpeed")) or 1
    if animSpeed <= 0 then animSpeed = 1 end

    local reloadTime       = tonumber(stats:GetAttribute("ReloadTime"))           or 0
    local reloadEnd        = tonumber(stats:GetAttribute("ReloadEndTime"))        or 0
    local reloadIndividual = tonumber(stats:GetAttribute("ReloadIndividualTime")) or 0
    local total = reloadTime + reloadEnd
    if total <= 0 then total = reloadIndividual end
    if total <= 0 then total = 0.15 end

    local char = LocalPlayer.Character
    local ammoType = stats:GetAttribute("AmmoType")
    local speedBoost = 1
    speedBoost = speedBoost + math.max(0, tonumber(char and char:GetAttribute("ReloadSpeed")) or 0)
    speedBoost = speedBoost + math.max(0, tonumber(char and ammoType and char:GetAttribute("ReloadSpeed_" .. ammoType)) or 0)

    return math.clamp((total / math.max(animSpeed * speedBoost, 1)) + 0.06, 0.05, 2)
end

function onCharAdded(char)
    invalidateWeapon()
    char.ChildAdded:Connect(LPH_JIT_MAX(function(c)
        if c:IsA("Tool")     then invalidateWeapon() end
    end))
    char.ChildRemoved:Connect(LPH_JIT_MAX(function(c)
        if c == CachedTool   then invalidateWeapon() end
    end))
end
if LocalPlayer.Character then onCharAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharAdded)
LocalPlayer.CharacterRemoving:Connect(LPH_JIT_MAX(function(char)
    if raReloadSpeedChar == char then resetReloadSpeedAttribute(char) end
    invalidateWeapon()
end))

local TargetCandidateBuffer = {}
local AimCandidateBuffer = {}
local MAX_WALLCHECK_CANDIDATES = 12

local function isLiveEnemyEntry(entry)
    local model = entry and entry.Model
    local head = entry and entry.Head
    local hum = entry and entry.Hum
    return model and model.Parent
        and head and head.Parent
        and hum and hum.Parent
        and hum.Health > 0
        and not model:GetAttribute("Dead")
end

getClosestTarget = LPH_JIT_MAX(function(originPos, rangeSq)
    local bestModel, bestHead, bestDSq = nil, nil, math.huge

    if State.WallCheck then
        table.clear(TargetCandidateBuffer)
    end

    for _, entry in ipairs(getEnemyCache()) do
        if isLiveEnemyEntry(entry) then
            local head = entry.Head
            local hp = head.Position
            local dX, dY, dZ = hp.X - originPos.X, hp.Y - originPos.Y, hp.Z - originPos.Z
            local dSq = dX*dX + dY*dY + dZ*dZ
            if dSq <= rangeSq then
                if State.WallCheck then
                    TargetCandidateBuffer[#TargetCandidateBuffer + 1] = {
                        Entry = entry,
                        Score = dSq,
                    }
                elseif dSq < bestDSq then
                    bestModel, bestHead, bestDSq = entry.Model, head, dSq
                end
            end
        end
    end

    if not State.WallCheck then
        return bestModel, bestHead
    end

    table.sort(TargetCandidateBuffer, function(a, b) return a.Score < b.Score end)
    local limit = math.min(#TargetCandidateBuffer, MAX_WALLCHECK_CANDIDATES)
    for i = 1, limit do
        local entry = TargetCandidateBuffer[i].Entry
        if isLiveEnemyEntry(entry) and hasClearShot(originPos, entry.Model, entry.Head) then
            return entry.Model, entry.Head
        end
    end

    return nil, nil
end)

local OriginalAutoTargetPosition = nil

getHeadOnlyAutoTargetPosition = LPH_JIT_MAX(function(maxRange, sameTeam, force)
    if sameTeam then
        if OriginalAutoTargetPosition and OriginalAutoTargetPosition ~= getHeadOnlyAutoTargetPosition then
            local ok, pos = pcall(OriginalAutoTargetPosition, maxRange, sameTeam, force)
            if ok then return pos end
        end
        return nil
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local range = tonumber(maxRange)
    if not range or range <= 0 then
        range = tonumber(State.Range) or 250
    end

    local originPos = hrp.Position
    local rangeSq = range * range
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize
    local bestHead, bestScore = nil, math.huge

    if State.WallCheck then
        table.clear(AimCandidateBuffer)
    end

    for _, entry in ipairs(getEnemyCache()) do
        if isLiveEnemyEntry(entry) then
            local head = entry.Head
            local hp = head.Position
            local dX, dY, dZ = hp.X - originPos.X, hp.Y - originPos.Y, hp.Z - originPos.Z
            local dSq = dX*dX + dY*dY + dZ*dZ
            if dSq <= rangeSq then
                local score = math_sqrt(dSq)
                if camera and viewport then
                    local screenPos, onScreen = camera:WorldToViewportPoint(hp)
                    if onScreen then
                        local dx = math.abs(screenPos.X - viewport.X * 0.5) / math.max(viewport.X, 1)
                        local dy = math.abs(screenPos.Y - viewport.Y * 0.5) / math.max(viewport.Y, 1)
                        score = score + (dx * 90) + (dy * 55)
                    else
                        score = score + 500
                    end
                end

                if State.WallCheck then
                    AimCandidateBuffer[#AimCandidateBuffer + 1] = {
                        Entry = entry,
                        Score = score,
                    }
                elseif score < bestScore then
                    bestHead, bestScore = head, score
                end
            end
        end
    end

    if not State.WallCheck then
        return bestHead and bestHead.Position or nil
    end

    table.sort(AimCandidateBuffer, function(a, b) return a.Score < b.Score end)
    local limit = math.min(#AimCandidateBuffer, MAX_WALLCHECK_CANDIDATES)
    for i = 1, limit do
        local entry = AimCandidateBuffer[i].Entry
        if isLiveEnemyEntry(entry) and hasClearShot(originPos, entry.Model, entry.Head) then
            return entry.Head.Position
        end
    end

    return nil
end)

function refreshHeadOnlyAutoTarget()
    local current = rawget(_G, "getCurrentAutoTargetPosition")
    if current ~= getHeadOnlyAutoTargetPosition then
        if typeof(current) == "function" then
            OriginalAutoTargetPosition = current
        end
        _G.getCurrentAutoTargetPosition = getHeadOnlyAutoTargetPosition
    end
end

task.spawn(LPH_JIT_MAX(function()
    while true do
        refreshHeadOnlyAutoTarget()
        task.wait(0.75)
    end
end))

fireMainWeapon = LPH_JIT_MAX(function(shoot, originPos, tChar, tHead)
    local hp = tHead.Position
    pcall(function()
        shoot:FireServer(
            vector.create(originPos.X, originPos.Y, originPos.Z),
            {{
                Target  = vector.create(hp.X, hp.Y, hp.Z),
                HitData = {{
                    HitChar = tChar,
                    HitPos  = vector.create(hp.X, hp.Y, hp.Z),
                    HitPart = tHead,
                }}
            }}
        )
    end)
end)

fireRemoteArsenal = LPH_JIT_MAX(function(originPos, tChar, tHead, count)
    local shoot = getRAShoot()
    if not shoot then return end
    local hp      = tHead.Position
    local origin  = vector.create(originPos.X, originPos.Y, originPos.Z)
    local hpVec   = vector.create(hp.X, hp.Y, hp.Z)
    local slots   = math.max(raSlotCount, 4)
    local payload = {{
        Target  = hpVec,
        HitData = {{
            HitChar = tChar,
            HitPos  = hpVec,
            HitPart = tHead,
        }}
    }}
    for _ = 1, count do
        for slot = 1, slots do
            pcall(function() shoot:FireServer(origin, payload, slot) end)
        end
    end
end)

burstFire = LPH_JIT_MAX(function(originPos, tChar, tHead, count)
    local tool, shoot = resolveWeapon()
    if tool and shoot then
        for _ = 1, count do
            fireMainWeapon(shoot, originPos, tChar, tHead)
        end
    end
    fireRemoteArsenal(originPos, tChar, tHead, count)
end)

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(State.RAAutoReload and RA_RELOAD_CHECK_DELAY or 0.45)
        if not State.RAAutoReload then
            applyRAReloadSpeedAttribute(false)
            continue
        end

        local ra = findRA()
        if ra then hookSetWeaponsClient(ra) end
        applyRAReloadSpeedAttribute(true)
        doRAReload()
    end
end))

local regReloading     = false
local regReloadTool    = nil
local regReloadUntil   = 0
local lastRegReload    = 0
local lastMainAmmoSync = 0
local MAIN_RELOAD_RETRY = 0.045
local MAIN_AMMO_SYNC_RETRY = 0.08
local MAIN_RELOAD_SCAN_DELAY = 0.12
local MAIN_RELOAD_ACTIVE_POLL = 0.025
local MAIN_WATCH_REBIND_DELAY = 0.2
local MAIN_AMMO_FIELDS_SET = {}
for _, fieldName in ipairs(MAIN_AMMO_FIELDS) do MAIN_AMMO_FIELDS_SET[fieldName] = true end

function tryGetAmmo(tool)
    if not tool then return nil end
    for _, name in ipairs(MAIN_AMMO_FIELDS) do
        local value = tool:GetAttribute(name)
        if typeof(value) == "number" then return value, name end
    end
    for _, name in ipairs(MAIN_AMMO_FIELDS) do
        local v = tool:FindFirstChild(name)
        if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v.Value, name
        end
    end
    return nil
end

function finishMainReload(tool)
    if tool and regReloadTool and tool ~= regReloadTool then return end
    regReloading   = false
    regReloadTool  = nil
    regReloadUntil = 0
end

function syncMainAmmo(tool)
    local syncAmmo = getMainAmmoSync(tool)
    if not syncAmmo then return end
    local now = os_clock()
    if now - lastMainAmmoSync < MAIN_AMMO_SYNC_RETRY then return end
    lastMainAmmoSync = now
    pcall(function() syncAmmo:FireServer() end)
end

function reloadMainWeapon(tool, reload)
    if not (tool and reload) then return end

    local now = os_clock()
    if regReloading and regReloadTool == tool and now < regReloadUntil then return end
    if now - lastRegReload < MAIN_RELOAD_RETRY then return end

    local reserve = getReserveAmmo(tool)
    if reserve ~= nil and reserve <= 0 then return end

    applyRAReloadSpeedAttribute()
    syncMainAmmo(tool)

    local ammo = tryGetAmmo(tool)
    if ammo ~= nil and ammo > 0 then
        finishMainReload(tool)
        return
    end

    lastRegReload  = now
    regReloading   = true
    regReloadTool  = tool
    regReloadUntil = now + getReloadWindow(tool)

    task.spawn(LPH_JIT_MAX(function()
        local ok, newAmmo = pcall(function() return reload:InvokeServer() end)
        if ok and typeof(newAmmo) == "number" then
            pcall(function() tool:SetAttribute("Ammo", newAmmo) end)
        end

        while regReloading and regReloadTool == tool do
            if not tool.Parent then break end
            local currentAmmo = tryGetAmmo(tool)
            if currentAmmo ~= nil and currentAmmo > 0 then break end
            if os_clock() >= regReloadUntil then break end
            task.wait(MAIN_RELOAD_ACTIVE_POLL)
        end

        if regReloadTool == tool then finishMainReload(tool) end
    end))
end

local ammoWatchTool   = nil
local ammoWatchConns  = {}

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(State.AutoReload and MAIN_RELOAD_SCAN_DELAY or 0.45)
        if not State.AutoReload then
            if ammoWatchTool then disconnectAmmoWatcher() end
            applyRAReloadSpeedAttribute()
            continue
        end
        local tool, _, reload = resolveWeapon()
        if not (tool and reload) then
            finishMainReload()
            continue
        end
        local ammo = tryGetAmmo(tool)
        if ammo == nil then
            syncMainAmmo(tool)
        elseif ammo <= 0 then
            reloadMainWeapon(tool, reload)
        elseif regReloadTool == tool then
            finishMainReload(tool)
        end
    end
end))

function disconnectAmmoWatcher()
    for _, conn in ipairs(ammoWatchConns) do conn:Disconnect() end
    table.clear(ammoWatchConns)
    ammoWatchTool = nil
end

function checkAmmoReload(tool, reload)
    if not (State.AutoReload and tool and reload) then return end
    local ammo = tryGetAmmo(tool)
    if ammo ~= nil and ammo <= 0 then task.defer(reloadMainWeapon, tool, reload) end
end

function bindAmmoWatcher()
    disconnectAmmoWatcher()
    ammoWatchTool = nil
    local tool, _, reload = resolveWeapon()
    if not (tool and reload) then return end
    ammoWatchTool = tool

    for _, name in ipairs(MAIN_AMMO_FIELDS) do
        ammoWatchConns[#ammoWatchConns + 1] = tool:GetAttributeChangedSignal(name):Connect(LPH_JIT_MAX(function()
            if ammoWatchTool ~= tool then return end
            checkAmmoReload(tool, reload)
        end))

        local value = tool:FindFirstChild(name)
        if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then
            ammoWatchConns[#ammoWatchConns + 1] = value.Changed:Connect(LPH_JIT_MAX(function()
                if ammoWatchTool ~= tool then return end
                checkAmmoReload(tool, reload)
            end))
        end
    end

    ammoWatchConns[#ammoWatchConns + 1] = tool.ChildAdded:Connect(LPH_JIT_MAX(function(child)
        if MAIN_AMMO_FIELDS_SET[child.Name]
            and (child:IsA("IntValue") or child:IsA("NumberValue")) then
            task.defer(bindAmmoWatcher)
        end
    end))

    checkAmmoReload(tool, reload)
end

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(State.AutoReload and MAIN_WATCH_REBIND_DELAY or 0.5)
        if not State.AutoReload then
            if ammoWatchTool then disconnectAmmoWatcher() end
            continue
        end
        local tool = resolveWeapon()
        if tool ~= ammoWatchTool then bindAmmoWatcher() end
    end
end))

local lastMainFire = 0
local lastRayGunNotice = -999

function getGunAuraMethod()
    local method = tostring(State.GunAuraMethod or "Default")
    if method ~= "Farm Scrap pile" then
        return "Default"
    end
    return method
end

function normalizeToolName(name)
    return tostring(name or ""):lower():gsub("[%s%-%_]+", "")
end

function isRayGunTool(item)
    return item and item:IsA("Tool") and normalizeToolName(item.Name):find("raygun", 1, true) ~= nil
end

function isOwnedRayGunTool(item)
    if not isRayGunTool(item) then return false end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local char = LocalPlayer.Character
    return item.Parent == char or item.Parent == backpack
end

local CachedRayGun = nil
local CachedRayGunTool = nil
local CachedRayGunShoot = nil

function findRayGun()
    if CachedRayGun and CachedRayGun.Parent and isOwnedRayGunTool(CachedRayGun) then
        return CachedRayGun
    end
    CachedRayGun = nil

    local char = LocalPlayer.Character
    if char then
        local equipped = char:FindFirstChild("Ray Gun")
        if isRayGunTool(equipped) then
            CachedRayGun = equipped
            return equipped
        end

        for _, item in ipairs(char:GetChildren()) do
            if isRayGunTool(item) then
                CachedRayGun = item
                return item
            end
        end
    end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return nil end

    local direct = backpack:FindFirstChild("Ray Gun")
    if isRayGunTool(direct) then
        CachedRayGun = direct
        return direct
    end

    for _, item in ipairs(backpack:GetChildren()) do
        if isRayGunTool(item) then
            CachedRayGun = item
            return item
        end
    end

    return nil
end

function getRayGunShoot(rayGun)
    if CachedRayGunTool == rayGun and CachedRayGunShoot and CachedRayGunShoot.Parent then
        return CachedRayGunShoot
    end
    CachedRayGunTool = rayGun
    CachedRayGunShoot = rayGun and rayGun:FindFirstChild("Shoot", true) or nil
    return CachedRayGunShoot
end

function notifyRayGunRequired(force)
    local now = os_clock()
    if force or (now - lastRayGunNotice > 4) then
        lastRayGunNotice = now
        if typeof(notify) == "function" then
            notify("Gun Aura", "Please get or equip the Ray Gun first to use Farm Scrap pile.", 4)
        end
    end
end

function canUseFarmScrapPile(showNotice)
    local rayGun = findRayGun()
    if rayGun then return true, rayGun end
    if showNotice then notifyRayGunRequired(false) end
    return false, nil
end

function findBackpackRemoteArsenal()
    local char = LocalPlayer.Character
    local equipped = char and char:FindFirstChild("Remote Arsenal")
    if equipped then return equipped end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return nil end
    return backpack:FindFirstChild("Remote Arsenal")
end

function ensureRemoteArsenalHasRayGun(rayGun)
    -- Best-effort Remote Arsenal support: Psychic Editor sends Backpack guns through
    -- Backpack["Remote Arsenal"].SetWeaponsClient. Bind only Ray Gun, throttled so it does not lag.
    if not (rayGun and rayGun.Parent == LocalPlayer:FindFirstChildOfClass("Backpack")) then
        return false
    end

    local now = os_clock()
    if State.__LastRARayGunBind and (now - State.__LastRARayGunBind) < 2 then
        return true
    end

    local ra = findBackpackRemoteArsenal()
    local setWeapons = ra and ra:FindFirstChild("SetWeaponsClient", true)
    if not (setWeapons and setWeapons:IsA("RemoteEvent")) then
        return false
    end

    State.__LastRARayGunBind = now
    pcall(function()
        setWeapons:FireServer({ rayGun }, true)
    end)
    return true
end

function getStructureHealth(model)
    if not model then return nil end

    local mock = model:FindFirstChild("MockHumanoid")
    if mock then
        local hp = tonumber(mock:GetAttribute("Health"))
            or tonumber(mock:GetAttribute("CurrentHealth"))
            or tonumber(mock:GetAttribute("HP"))
        if hp ~= nil then return hp end
    end

    local hum = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Humanoid")
    if hum then
        local ok, hp = pcall(function() return hum.Health end)
        if ok and typeof(hp) == "number" then return hp end
        hp = tonumber(hum:GetAttribute("Health"))
            or tonumber(hum:GetAttribute("CurrentHealth"))
            or tonumber(hum:GetAttribute("HP"))
        if hp ~= nil then return hp end
    end

    local hp = tonumber(model:GetAttribute("Health"))
        or tonumber(model:GetAttribute("CurrentHealth"))
        or tonumber(model:GetAttribute("HP"))
    return hp
end

function isAliveStructure(model)
    if not (model and model.Parent) then return false end
    if model:GetAttribute("Dead") then return false end
    local hp = getStructureHealth(model)
    return hp == nil or hp > 0
end

function findScrapHitPart(scrap)
    if not scrap then return nil end
    local plane = scrap:FindFirstChild("Plane", true)
    if plane and plane:IsA("BasePart") then return plane end
    local hitbox = scrap:FindFirstChild("Hitbox", true) or scrap:FindFirstChild("HitBox", true)
    if hitbox and hitbox:IsA("BasePart") then return hitbox end
    if scrap.PrimaryPart then return scrap.PrimaryPart end
    return scrap:FindFirstChildWhichIsA("BasePart", true)
end

local ScrapPileCache = {}
local lastScrapPileSweep = -999
local scrapPileDirty = true
local scrapBoundStructures = nil
local scrapStructureConns = {}
local ScrapCandidateBuffer = {}
local SCRAP_CACHE_REFRESH = 1.25
local MAX_SCRAP_WALLCHECK_CANDIDATES = 10

function markScrapPileDirty()
    scrapPileDirty = true
    lastScrapPileSweep = -999
end

function bindScrapPileStructures()
    local structures = Workspace:FindFirstChild("Structures")
    if structures == scrapBoundStructures then
        return structures
    end

    for _, conn in ipairs(scrapStructureConns) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(scrapStructureConns)

    scrapBoundStructures = structures
    markScrapPileDirty()

    if structures then
        scrapStructureConns[#scrapStructureConns + 1] = structures.DescendantAdded:Connect(LPH_JIT_MAX(function(inst)
            if inst:IsA("Model") or inst:IsA("BasePart") then
                markScrapPileDirty()
            end
        end))
        scrapStructureConns[#scrapStructureConns + 1] = structures.DescendantRemoving:Connect(LPH_JIT_MAX(function(inst)
            if inst:IsA("Model") or inst:IsA("BasePart") then
                markScrapPileDirty()
            end
        end))
    end

    return structures
end

function getScrapPileCache()
    local now = os_clock()
    local structures = bindScrapPileStructures()
    if not structures then
        table.clear(ScrapPileCache)
        scrapPileDirty = false
        return ScrapPileCache
    end

    if not scrapPileDirty and (now - lastScrapPileSweep) < SCRAP_CACHE_REFRESH then
        return ScrapPileCache
    end

    lastScrapPileSweep = now
    table.clear(ScrapPileCache)

    for _, inst in ipairs(structures:GetDescendants()) do
        if inst:IsA("Model") and inst.Name == "Scrap Pile" then
            ScrapPileCache[#ScrapPileCache + 1] = inst
        end
    end

    scrapPileDirty = false
    return ScrapPileCache
end

getClosestScrapPile = LPH_JIT_MAX(function(originPos, rangeSq)
    local bestModel, bestPart, bestSq = nil, nil, math.huge

    if State.WallCheck then
        table.clear(ScrapCandidateBuffer)
    end

    for _, model in ipairs(getScrapPileCache()) do
        if isAliveStructure(model) then
            local part = findScrapHitPart(model)
            if part then
                local pos = part.Position
                local dX, dY, dZ = pos.X - originPos.X, pos.Y - originPos.Y, pos.Z - originPos.Z
                local dSq = dX*dX + dY*dY + dZ*dZ
                if dSq <= rangeSq then
                    if State.WallCheck then
                        ScrapCandidateBuffer[#ScrapCandidateBuffer + 1] = {
                            Model = model,
                            Part = part,
                            Score = dSq,
                        }
                    elseif dSq < bestSq then
                        bestModel, bestPart, bestSq = model, part, dSq
                    end
                end
            end
        end
    end

    if not State.WallCheck then
        return bestModel, bestPart
    end

    table.sort(ScrapCandidateBuffer, function(a, b) return a.Score < b.Score end)
    local limit = math.min(#ScrapCandidateBuffer, MAX_SCRAP_WALLCHECK_CANDIDATES)
    for i = 1, limit do
        local candidate = ScrapCandidateBuffer[i]
        if isAliveStructure(candidate.Model)
            and candidate.Part
            and candidate.Part.Parent
            and hasClearShot(originPos, candidate.Model, candidate.Part) then
            return candidate.Model, candidate.Part
        end
    end

    return bestModel, bestPart
end)

fireRayGunAtScrap = LPH_JIT_MAX(function(rayGun, originPos, scrap, hitPart)
    if not (rayGun and scrap and hitPart) then return false end

    local hitPos = hitPart.Position
    local originVec = vector.create(originPos.X, originPos.Y, originPos.Z)
    local hitVec = vector.create(hitPos.X, hitPos.Y, hitPos.Z)

    local payload = {{
        Target = hitVec,
        HitData = {}
    }}

    -- Primary path: exact Ray Gun remote shape, matching the args used by the game.
    local shoot = getRayGunShoot(rayGun)
    if shoot and shoot:IsA("RemoteEvent") then
        local ok = pcall(function()
            shoot:FireServer(originVec, payload)
        end)
        if ok then return true end
    end

    -- Fallback path for Remote Arsenal setups after Ray Gun is bound through SetWeaponsClient.
    local ra = findBackpackRemoteArsenal()
    local raShoot = ra and ra:FindFirstChild("Shoot", true)
    if raShoot and raShoot:IsA("RemoteEvent") then
        local fired = false
        for slot = 1, 4 do
            local ok = pcall(function()
                raShoot:FireServer(originVec, payload, slot)
            end)
            fired = fired or ok
        end
        return fired
    end

    return false
end)

runScrapPileRayGunAura = LPH_JIT_MAX(function(hrp)
    local ok, rayGun = canUseFarmScrapPile(true)
    if not ok or not rayGun then return false end

    ensureRemoteArsenalHasRayGun(rayGun)

    local originPos = getWeaponOrigin(rayGun, hrp.Position)
    local range = math.max(10, tonumber(State.Range) or 250)
    local scrap, hitPart = getClosestScrapPile(originPos, range * range)
    if not (scrap and hitPart) then return false end

    return fireRayGunAtScrap(rayGun, originPos, scrap, hitPart)
end)

RunService.Heartbeat:Connect(LPH_JIT_MAX(function()
    if not State.AutoShoot then return end
    local now = os_clock()
    if now - lastMainFire < State.FireRate then return end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if getGunAuraMethod() == "Farm Scrap pile" then
        if runScrapPileRayGunAura(hrp) then
            lastMainFire = now
        end
        return
    end

    local tool = resolveWeapon()
    local originPos = getWeaponOrigin(tool, hrp.Position)
    local rangeSq   = State.Range * State.Range
    local burst     = 1

    local tChar, tHead = getClosestTarget(originPos, rangeSq)
    if not (tChar and tHead) then return end

    lastMainFire = now
    burstFire(originPos, tChar, tHead, burst)
end))

local StructuresFolder = Workspace:FindFirstChild("Structures")

local SupportedStructures = {
    ["Barrel"] = true, ["Scrap Pile"] = true,
    ["Generator"] = true, ["Crate"] = true, ["Locker"] = true,
}

local CombatHitbox = nil
function resolveCombatHitbox()
    if CombatHitbox then return CombatHitbox end
    pcall(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local combat = modules and modules:FindFirstChild("Combat")
        local hitboxModule = combat and combat:FindFirstChild("Hitbox")
        if hitboxModule and hitboxModule:IsA("ModuleScript") then
            CombatHitbox = require(hitboxModule)
        end
    end)
    return CombatHitbox
end

function clampMeleeRange(value)
    return clampPickupRange(value)
end

function getMeleeRange()
    local n = clampMeleeRange(State.MeleeRange or getPickupRange())
    if State.MeleeRange ~= n then State.MeleeRange = n end
    return n
end

function getActiveRadiusRange()
    local r = getPickupRange()
    if State.MeleeAura then
        r = math.max(r, getMeleeRange())
    end
    return clampPickupRange(r)
end

function getMeleeSwingDelay()
    local d = tonumber(State.MeleeAttackSpeed) or 0.02
    if d < 0.012 then d = 0.012 end
    if d > 0.15 then d = 0.15 end
    return d
end

function getMeleeMaxTargets()
    local n = math.floor(tonumber(State.MeleeMaxTargets) or 6)
    if n < 1 then n = 1 end
    if n > 10 then n = 10 end
    return n
end

local CachedMeleeTool, CachedMeleeSwing, CachedMeleeHit = nil, nil, nil
local meleeSpeedSavedChar = nil
local meleeSpeedSavedValue = nil

function invalidateMelee()
    CachedMeleeTool, CachedMeleeSwing, CachedMeleeHit = nil, nil, nil
end

function setMeleeSpeedAttribute(active)
    local char = LocalPlayer.Character
    if not char then return end

    if active then
        if meleeSpeedSavedChar ~= char then
            meleeSpeedSavedChar = char
            meleeSpeedSavedValue = char:GetAttribute("MeleeAttackSpeed")
        end

        local delay = getMeleeSwingDelay()
        local boost = math.clamp((0.14 / delay) - 1, 0, 12)
        pcall(function()
            char:SetAttribute("MeleeAttackSpeed", boost)
        end)
    else
        local savedChar = meleeSpeedSavedChar
        if savedChar and savedChar.Parent then
            pcall(function()
                savedChar:SetAttribute("MeleeAttackSpeed", meleeSpeedSavedValue)
            end)
        end
        meleeSpeedSavedChar = nil
        meleeSpeedSavedValue = nil
    end
end

LocalPlayer.CharacterAdded:Connect(LPH_JIT_MAX(function()
    invalidateMelee()
    meleeSpeedSavedChar = nil
    meleeSpeedSavedValue = nil
    task.delay(0.25, function()
        if State.MeleeAura then setMeleeSpeedAttribute(true) end
    end)
end))

LocalPlayer.CharacterRemoving:Connect(LPH_JIT_MAX(function(char)
    if meleeSpeedSavedChar == char then
        setMeleeSpeedAttribute(false)
    end
    invalidateMelee()
end))

function findMeleeIn(container)
    if not container then return nil end
    for _, tool in ipairs(container:GetChildren()) do
        if tool:IsA("Tool") then
            local swing = tool:FindFirstChild("Swing")
            local hit = tool:FindFirstChild("HitTargets")
            if swing and hit then
                return tool, swing, hit
            end
        end
    end
    return nil
end

function resolveMelee()
    local char = LocalPlayer.Character
    if not char then return nil end

    if CachedMeleeTool and CachedMeleeTool.Parent == char
        and CachedMeleeSwing and CachedMeleeSwing.Parent
        and CachedMeleeHit and CachedMeleeHit.Parent then
        return CachedMeleeTool, CachedMeleeSwing, CachedMeleeHit
    end

    invalidateMelee()

    local tool, swing, hit = findMeleeIn(char)
    if tool and swing and hit then
        CachedMeleeTool, CachedMeleeSwing, CachedMeleeHit = tool, swing, hit
        return tool, swing, hit
    end

    return nil
end

modelDistSq = LPH_JIT_MAX(function(model, originPos)
    local ok, pivot = pcall(function() return model:GetPivot().Position end)
    if not ok or not pivot then return nil end
    local d = pivot - originPos
    return d.X*d.X + d.Y*d.Y + d.Z*d.Z
end)

getMeleeTargetHealth = LPH_JIT_MAX(function(model)
    if not model then return nil end

    local hum = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Humanoid")
    if hum then
        local ok, value = pcall(function() return hum.Health end)
        if ok and typeof(value) == "number" then return value end

        value = tonumber(hum:GetAttribute("Health"))
            or tonumber(hum:GetAttribute("CurrentHealth"))
            or tonumber(hum:GetAttribute("HP"))
        if value then return value end
    end

    local mock = model:FindFirstChild("MockHumanoid")
    if mock then
        local value = tonumber(mock:GetAttribute("Health"))
            or tonumber(mock:GetAttribute("CurrentHealth"))
            or tonumber(mock:GetAttribute("HP"))
        if value then return value end
    end

    local modelHealth = tonumber(model:GetAttribute("Health"))
        or tonumber(model:GetAttribute("CurrentHealth"))
        or tonumber(model:GetAttribute("HP"))
    if modelHealth then return modelHealth end

    return nil
end)

function hasMeleeHealthObject(model)
    if not model then return false end
    return model:FindFirstChildOfClass("Humanoid") ~= nil
        or model:FindFirstChild("Humanoid") ~= nil
        or model:FindFirstChild("MockHumanoid") ~= nil
end

local deadMeleeTargets = setmetatable({}, { __mode = "k" })

isValidMeleeTarget = LPH_JIT_MAX(function(model, char)
    if not model or model == char then return false end
    if not model:IsA("Model") then return false end
    if not model.Parent then return false end
    if deadMeleeTargets[model] then return false end
    if model:GetAttribute("Untouchable") then return false end
    if model:GetAttribute("Dead") then
        deadMeleeTargets[model] = true
        return false
    end
    if not hasMeleeHealthObject(model) then return false end

    local health = getMeleeTargetHealth(model)
    if typeof(health) == "number" and health <= 0 then
        deadMeleeTargets[model] = true
        return false
    end

    return true
end)

collectMeleeTargets = LPH_JIT_MAX(function(char, hrp, range, maxTargets)
    local found = {}
    local seen = {}
    local rangeSq = range * range
    local originPos = hrp.Position

    local function addTarget(model)
        if not isValidMeleeTarget(model, char) then return end
        if seen[model] then return end
        local dSq = modelDistSq(model, originPos)
        if not dSq or dSq > rangeSq then return end
        seen[model] = true
        found[#found + 1] = { model = model, dSq = dSq }
    end

    local hitbox = resolveCombatHitbox()
    if hitbox and typeof(hitbox.RadiusHitbox) == "function" then
        local ok, targets = pcall(function()
            return hitbox.RadiusHitbox(hrp.CFrame, range, 180, char)
        end)
        if ok and type(targets) == "table" then
            for _, model in ipairs(targets) do
                addTarget(model)
            end
        end
    end

    -- Also scan known folders every swing. This catches targets whose parts are
    -- not in the Hitbox collision group yet, while seen[] prevents duplicates.
    for _, entry in ipairs(getEnemyCache()) do
        if isLiveEnemyEntry(entry) then
            addTarget(entry.Model)
        end
    end

    if StructuresFolder then
        for _, model in ipairs(StructuresFolder:GetChildren()) do
            if model:IsA("Model") and SupportedStructures[model.Name] then
                addTarget(model)
            end
        end
    end

    table.sort(found, function(a, b) return a.dSq < b.dSq end)

    local out = {}
    local cap = math.min(#found, maxTargets)
    for i = 1, cap do out[i] = found[i].model end
    return out
end)

Workspace.ChildAdded:Connect(LPH_JIT_MAX(function(child)
    if child.Name == "Structures" then
        StructuresFolder = child
        markScrapPileDirty()
        lastWallCheckRoots = -999
    elseif child.Name == "Map" then
        lastWallCheckRoots = -999
    end
end))

local meleeSwinging = false
local MELEE_IDLE_SCAN_WAIT = 0.2
local MELEE_NO_TARGET_WAIT = 0.025
local MELEE_RECHECK_DELAY = 0.012
local MELEE_HIT_PULSES = 2

fireMeleeAuraOnce = LPH_JIT_MAX(function()
    if meleeSwinging then return false end
    meleeSwinging = true

    local didSwing = false
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local tool, swing, hit = resolveMelee()

    if char and hrp and tool and swing and hit then
        setMeleeSpeedAttribute(true)

        local range = getMeleeRange()
        local targets = collectMeleeTargets(char, hrp, range, getMeleeMaxTargets())
        if #targets > 0 then
            local stats = tool:FindFirstChild("Stats")
            if stats then
                pcall(function()
                    if stats:GetAttribute("Range") ~= nil then
                        stats:SetAttribute("Range", range)
                    end
                end)
            end

            pcall(function() swing:FireServer() end)

            local windup = 0.018
            if stats then
                local statWindup = tonumber(stats:GetAttribute("WindUp"))
                if statWindup then
                    local speedBoost = 1 + (char:GetAttribute("MeleeAttackSpeed") or 0)
                    -- Wait close to the real melee windup so the server accepts the hit,
                    -- but scale it down with the speed boost for faster aura swings.
                    windup = math.clamp(statWindup / math.max(speedBoost, 1), 0.008, 0.035)
                end
            end
            task.wait(windup)

            for pulse = 1, MELEE_HIT_PULSES do
                local liveTargets = {}
                for _, target in ipairs(targets) do
                    if isValidMeleeTarget(target, char) then
                        liveTargets[#liveTargets + 1] = target
                    end
                end

                if #liveTargets > 0 then
                    pcall(function() hit:FireServer(liveTargets) end)
                    didSwing = true
                else
                    break
                end

                if pulse < MELEE_HIT_PULSES then
                    task.wait(MELEE_RECHECK_DELAY)
                end
            end
        end
    end

    meleeSwinging = false
    return didSwing
end)

task.spawn(LPH_JIT_MAX(function()
    while true do
        if not State.MeleeAura then
            task.wait(MELEE_IDLE_SCAN_WAIT)
        else
            local didSwing = fireMeleeAuraOnce()
            if didSwing then
                task.wait(getMeleeSwingDelay())
            else
                task.wait(MELEE_NO_TARGET_WAIT)
            end
        end
    end
end))

local ESPGuis    = {}
local ESPConns   = {}
local ESP_UPDATE = 0.08
local ITEM_ESP_UPDATE = 0.14
local ESP_CREATE_BATCH = 35
local ITEM_ESP_CREATE_BATCH = 60

local ESP_COLOR_NAME   = Color3.fromRGB(85, 255, 85)
local ESP_COLOR_STROKE = Color3.fromRGB(0, 0, 0)

function setGuiVisible(info, visible)
    if info.visible ~= visible then
        info.visible = visible
        info.gui.Enabled = visible
    end
end

destroyESP = LPH_JIT_MAX(function(model)
    local info = ESPGuis[model]
    if info and info.gui then info.gui:Destroy() end
    ESPGuis[model] = nil
    local conns = ESPConns[model]
    if conns then
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end
    ESPConns[model] = nil
end)

createESP = LPH_JIT_MAX(function(model)
    if ESPGuis[model] then return end
    if not SupportedTypes[model.Name] then return end
    local head = findHead(model)
    if not head then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local bb = Instance.new("BillboardGui")
    bb.Name           = "STA_ESP"
    bb.Adornee        = head
    bb.Size           = UDim2.new(0, 220, 0, 18)
    bb.StudsOffset    = Vector3.new(0, 2.8, 0)
    bb.AlwaysOnTop    = true
    bb.LightInfluence = 0
    bb.MaxDistance    = 2500
    bb.ResetOnSpawn   = false
    bb.Enabled        = false
    bb.Parent         = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name                   = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size                   = UDim2.new(1, 0, 1, 0)
    nameLabel.Font                   = Enum.Font.GothamBold
    nameLabel.TextSize               = 14
    nameLabel.TextColor3             = ESP_COLOR_NAME
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3       = ESP_COLOR_STROKE
    nameLabel.Text                   = model.Name
    nameLabel.Parent                 = bb

    ESPGuis[model] = {
        gui       = bb,
        nameLabel = nameLabel,
        head      = head,
        hum       = hum,
        baseName  = model.Name,
        lastDist  = -1,
        visible   = false,
    }

    ESPConns[model] = {
        hum.Died:Connect(LPH_JIT_MAX(function() destroyESP(model) end)),
        model.AncestryChanged:Connect(LPH_JIT_MAX(function(_, parent)
            if not parent then destroyESP(model) end
        end)),
    }
end)

refreshAllESP = LPH_JIT_MAX(function()
    local processed = 0
    for _, model in ipairs(CharactersFolder:GetChildren()) do
        if SupportedTypes[model.Name] then createESP(model) end
        processed += 1
        if processed % ESP_CREATE_BATCH == 0 then task.wait() end
    end
end)

function clearAllESP()
    for model in pairs(ESPGuis) do destroyESP(model) end
end

CharactersFolder.ChildAdded:Connect(LPH_JIT_MAX(function(model)
    if not State.ESPEnabled then return end
    task.defer(function()
        if State.ESPEnabled and model.Parent then createESP(model) end
    end)
end))

CharactersFolder.ChildRemoved:Connect(LPH_JIT_MAX(function(model) destroyESP(model) end))

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(State.ESPEnabled and ESP_UPDATE or 0.35)
        if not State.ESPEnabled then continue end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local mp    = hrp.Position
        local mX, mY, mZ = mp.X, mp.Y, mp.Z
        local maxSq = State.ESPRange * State.ESPRange
        for model, info in pairs(ESPGuis) do
            local head = info.head
            local hum  = info.hum
            if head and head.Parent and hum and hum.Health > 0 then
                local hp  = head.Position
                local dx, dy, dz = hp.X - mX, hp.Y - mY, hp.Z - mZ
                local dSq = dx*dx + dy*dy + dz*dz
                if dSq <= maxSq then
                    setGuiVisible(info, true)
                    local dist = math_floor(math_sqrt(dSq))
                    if dist ~= info.lastDist then
                        info.lastDist       = dist
                        info.nameLabel.Text = string.format("%s [%d studs]", info.baseName, dist)
                    end
                else
                    setGuiVisible(info, false)
                end
            else
                destroyESP(model)
            end
        end
    end
end))

local DroppedFolder = Workspace:FindFirstChild("DroppedItems")
if not DroppedFolder then
    task.spawn(LPH_JIT_MAX(function() DroppedFolder = Workspace:WaitForChild("DroppedItems", 30) end))
end

local ItemESPGuis  = {}
local ItemESPConns = {}

local ITEM_COLORS = {
    Medical   = Color3.fromRGB(255, 120, 140),
    Blueprint = Color3.fromRGB(100, 200, 255),
    Throwable = Color3.fromRGB(255, 150, 50),
    Melee     = Color3.fromRGB(255, 230, 80),
    Gun       = Color3.fromRGB(255, 90,  90),
    Resource  = Color3.fromRGB(190, 190, 210),
    Food      = Color3.fromRGB(120, 230, 120),
    Fuel      = Color3.fromRGB(255, 180, 60),
    Ammo      = Color3.fromRGB(210, 170, 110),
    Emerald   = Color3.fromRGB(0,   230, 118),
    Misc      = Color3.fromRGB(220, 180, 255),
    Survivors = Color3.fromRGB(90,  200, 255),
    Crates    = Color3.fromRGB(255, 210, 110),
}

local ITEM_CATEGORIES = {
    "Medical", "Blueprint", "Throwable", "Melee", "Gun",
    "Resource", "Food", "Fuel", "Ammo", "Emerald", "Misc",
    "Survivors", "Crates",
}

local PICKUP_CATEGORIES = {
    "Backpack", "Gun", "Melee", "Blueprint", "Throwable", "Medical",
    "Ammo", "Armor", "Misc",
}

local MISC_NAMES = {
    ["Gas Mask"]         = true,
    ["Power Armor Arm"]  = true,
    ["Power Armor Core"] = true,
    ["Radio Tower Part"] = true,
}

local ARMOR_NAMES = {
    ["Heavy Armor"] = true, ["Light Armor"] = true,
    ["Medium Armor"] = true, ["Power Armor"] = true,
}

local MAP_ESP_CATEGORIES = {
    Survivors = true,
    Crates    = true,
}

function getMapESPFolder(cat)
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    if cat == "Survivors" then return map:FindFirstChild("Survivors") end
    if cat == "Crates"    then return map:FindFirstChild("Crates")    end
    return nil
end

function isTopLevelModelInsideFolder(model, folder)
    if not (model and folder) then return false end
    if not model:IsA("Model") then return false end
    if not model:IsDescendantOf(folder) then return false end

    local parent = model.Parent
    while parent and parent ~= folder do
        if parent:IsA("Model") then return false end
        parent = parent.Parent
    end

    return true
end

categorizeItem = LPH_JIT_MAX(function(model)
    if not model or not model:IsA("Model") then return nil end

    local survivorsFolder = getMapESPFolder("Survivors")
    if isTopLevelModelInsideFolder(model, survivorsFolder) then return "Survivors" end

    local cratesFolder = getMapESPFolder("Crates")
    if isTopLevelModelInsideFolder(model, cratesFolder) then return "Crates" end

    if model.Name == "Emerald" then return "Emerald" end
    local toolType = model:GetAttribute("ToolType")
    if toolType == "Medical"   then return "Medical"   end
    if toolType == "Blueprint" then return "Blueprint" end
    if toolType == "Throwable" then return "Throwable" end
    if toolType == "Melee"     then return "Melee"     end
    if toolType == "Gun"       then return "Gun"       end
    local itemType = model:GetAttribute("ItemType")
    if itemType == "Emerald"  then return "Emerald"  end
    if itemType == "Resource" then return "Resource" end
    if itemType == "Food"     then return "Food"     end
    if itemType == "Fuel"     then return "Fuel"     end
    if itemType == "Ammo"     then return "Ammo"     end
    if MISC_NAMES[model.Name] then return "Misc" end
    if itemType == "GasMask" or itemType == "QuestItem" then return "Misc" end
    return nil
end)

function findItemAnchor(model)
    if model.PrimaryPart then return model.PrimaryPart end
    local fh = model:FindFirstChild("FakeHandle")
    if fh and fh:IsA("BasePart") then return fh end
    local mp = model:FindFirstChild("MainPart")
    if mp and mp:IsA("BasePart") then return mp end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then return p end
    end
    return nil
end

local CrateCache = {}
local CratePromptCache = setmetatable({}, { __mode = "kv" })
local crateOpenCooldown = {}
local crateCacheDirty = true
local crateBoundFolder = nil
local crateFolderConns = {}
local lastCrateCacheRefresh = -999
local CRATE_CACHE_REFRESH = 1
local CRATE_DIRTY_REFRESH = 0.2
local CRATE_SCAN_DELAY = 0.025
local CRATE_OPEN_RETRY = 0.08
local CRATE_SUCCESS_COOLDOWN = 0.22
local CRATE_OPEN_BATCH = 8
local CRATE_REMOTE_NAMES = { "Accept", "Open", "OpenCrate", "Interact", "Activate", "Collect", "Loot" }

function getCratesFolder()
    local map = Workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("Crates") or nil
end

function markCrateCacheDirty()
    crateCacheDirty = true
    table.clear(CratePromptCache)
end

function bindCrateFolder()
    local folder = getCratesFolder()
    if folder == crateBoundFolder then return folder end

    for _, conn in ipairs(crateFolderConns) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(crateFolderConns)

    crateBoundFolder = folder
    markCrateCacheDirty()

    if folder then
        crateFolderConns[#crateFolderConns + 1] = folder.DescendantAdded:Connect(LPH_JIT_MAX(function(inst)
            if inst:IsA("Model") or inst:IsA("BasePart") or inst:IsA("ProximityPrompt") then
                markCrateCacheDirty()
            end
        end))
        crateFolderConns[#crateFolderConns + 1] = folder.DescendantRemoving:Connect(LPH_JIT_MAX(function(inst)
            if inst:IsA("Model") or inst:IsA("BasePart") or inst:IsA("ProximityPrompt") then
                markCrateCacheDirty()
            end
        end))
    end

    return folder
end

function getTopCrateModel(model, folder)
    if not (model and folder and model:IsA("Model") and model:IsDescendantOf(folder)) then return nil end

    local top = model
    local parent = model.Parent
    while parent and parent ~= folder do
        if parent:IsA("Model") then
            top = parent
        end
        parent = parent.Parent
    end

    return top
end

function isCrateModel(model, folder)
    if not (model and folder and model:IsA("Model") and model:IsDescendantOf(folder)) then return false end
    if model:GetAttribute("Crate") == true then return true end
    if model:GetAttribute("Rarity") ~= nil or model:GetAttribute("Tier") ~= nil then return true end
    return model:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
end

function getCrateCache()
    local now = os_clock()
    local folder = bindCrateFolder()
    if not folder then
        table.clear(CrateCache)
        crateCacheDirty = false
        return CrateCache
    end

    if crateCacheDirty and (now - lastCrateCacheRefresh) < CRATE_DIRTY_REFRESH then
        return CrateCache
    end

    if not crateCacheDirty and (now - lastCrateCacheRefresh) < CRATE_CACHE_REFRESH then
        return CrateCache
    end

    table.clear(CrateCache)
    local seen = {}

    for _, inst in ipairs(folder:GetDescendants()) do
        if inst:IsA("Model") then
            local crate = getTopCrateModel(inst, folder)
            if crate and not seen[crate] and isCrateModel(crate, folder) then
                seen[crate] = true
                CrateCache[#CrateCache + 1] = crate
            end
        end
    end

    lastCrateCacheRefresh = now
    crateCacheDirty = false
    return CrateCache
end

function findCratePrompt(crate)
    local cached = CratePromptCache[crate]
    if cached and cached.Parent and cached:IsDescendantOf(crate) and cached.Enabled then
        return cached
    end

    local direct = crate:FindFirstChild("Prompt", true)
    if direct and direct:IsA("ProximityPrompt") and direct.Enabled then
        CratePromptCache[crate] = direct
        return direct
    end

    local fallback = nil
    for _, inst in ipairs(crate:GetDescendants()) do
        if inst:IsA("ProximityPrompt") and inst.Enabled then
            local text = (tostring(inst.ActionText) .. " " .. tostring(inst.ObjectText) .. " " .. inst.Name):lower()
            if text:find("open", 1, true) or text:find("crate", 1, true) then
                CratePromptCache[crate] = inst
                return inst
            end
            fallback = fallback or inst
        end
    end

    CratePromptCache[crate] = fallback
    return fallback
end

function isCratePrompt(prompt)
    if not (prompt and prompt:IsA("ProximityPrompt")) then return false end

    local text = (tostring(prompt.ActionText) .. " " .. tostring(prompt.ObjectText) .. " " .. prompt.Name):lower()
    if text:find("crate", 1, true) or text:find("open", 1, true) then
        local cratesFolder = getCratesFolder()
        return (not cratesFolder) or prompt:IsDescendantOf(cratesFolder)
    end

    return false
end

function getCratePosition(crate)
    local anchor = findItemAnchor(crate)
    if anchor then return anchor.Position end

    local ok, pos = pcall(function()
        return crate:GetPivot().Position
    end)
    return ok and pos or nil
end

function prepareCratePrompt(prompt, radius)
    if not (prompt and prompt.Parent and prompt.Enabled) then return false end

    pcall(function()
        prompt.HoldDuration = 0
    end)
    pcall(function()
        prompt.RequiresLineOfSight = false
    end)
    pcall(function()
        prompt.ClickablePrompt = true
    end)
    pcall(function()
        prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
    end)
    pcall(function()
        prompt.Style = Enum.ProximityPromptStyle.Custom
    end)
    pcall(function()
        prompt.MaxActivationDistance = math.max(tonumber(prompt.MaxActivationDistance) or 0, radius, 10)
    end)
    pcall(function()
        prompt:SetAttribute("ProgressBarText", "")
    end)

    return true
end

function fireCratePrompt(prompt, radius)
    if not prepareCratePrompt(prompt, radius) then return false end

    local fired = false
    if typeof(fireproximityprompt) == "function" then
        fired = pcall(function()
            fireproximityprompt(prompt)
        end) or fired
        fired = pcall(function()
            fireproximityprompt(prompt, 0)
        end) or fired
        fired = pcall(function()
            fireproximityprompt(prompt, 0, true)
        end) or fired
        fired = pcall(function()
            fireproximityprompt(prompt, 1, true)
        end) or fired
    end

    if not fired then
        fired = pcall(function()
            prompt:InputHoldBegin()
            prompt:InputHoldEnd()
        end)
    end

    return fired
end

function fireCrateRemote(crate, prompt)
    local function fireRemote(remote, ...)
        if remote:IsA("RemoteEvent") then
            return pcall(function(...) remote:FireServer(...) end, ...)
        end
        if remote:IsA("RemoteFunction") then
            return pcall(function(...) remote:InvokeServer(...) end, ...)
        end
        return false
    end

    for _, name in ipairs(CRATE_REMOTE_NAMES) do
        local remote = crate:FindFirstChild(name, true)
        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
            local fired = false
            fired = fireRemote(remote, prompt) or fired
            fired = fireRemote(remote, crate) or fired
            fired = fireRemote(remote, crate, prompt) or fired
            fired = fireRemote(remote, prompt, crate) or fired
            fired = fireRemote(remote) or fired
            if fired then return true end
        end
    end

    return false
end

function refreshCratePromptProperties()
    if not State.AutoOpenCrates then return end
    local radius = getPickupRange()
    for _, crate in ipairs(getCrateCache()) do
        if crate and crate.Parent then
            local prompt = findCratePrompt(crate)
            if prompt then
                prepareCratePrompt(prompt, radius)
            end
        end
    end
end

function openCrate(crate, radius)
    if not (crate and crate.Parent) then return false end

    local prompt = findCratePrompt(crate)
    local remoteFired = fireCrateRemote(crate, prompt)
    if prompt and fireCratePrompt(prompt, radius) then
        return true
    end
    if crate:FindFirstChildWhichIsA("ProximityPrompt", true) then
        return remoteFired
    end

    return remoteFired
end

PromptService.PromptShown:Connect(LPH_JIT_MAX(function(prompt)
    if State.AutoOpenCrates and isCratePrompt(prompt) then
        prepareCratePrompt(prompt, getPickupRange())
    end
end))

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(State.AutoOpenCrates and CRATE_SCAN_DELAY or 0.25)
        if not State.AutoOpenCrates then continue end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local now = os_clock()
        for crate, last in pairs(crateOpenCooldown) do
            if (not crate.Parent) or (now - last) > 10 then
                crateOpenCooldown[crate] = nil
            end
        end

        local radius = getPickupRange()
        local rangeSq = radius * radius
        local originPos = hrp.Position
        local opened = 0

        for _, crate in ipairs(getCrateCache()) do
            if opened >= CRATE_OPEN_BATCH then break end
            if crate and crate.Parent then
                local last = crateOpenCooldown[crate]
                if (not last) or (now - last) >= CRATE_OPEN_RETRY then
                    local pos = getCratePosition(crate)
                    if pos then
                        local dx, dz = pos.X - originPos.X, pos.Z - originPos.Z
                        if (dx*dx + dz*dz) <= rangeSq then
                            crateOpenCooldown[crate] = now
                            if openCrate(crate, radius) then
                                crateOpenCooldown[crate] = now + CRATE_SUCCESS_COOLDOWN
                                opened += 1
                            end
                        end
                    end
                end
            end
        end
    end
end))

function destroyItemESP(model)
    local info = ItemESPGuis[model]
    if info and info.gui then pcall(function() info.gui:Destroy() end) end
    ItemESPGuis[model] = nil
    local conns = ItemESPConns[model]
    if conns then
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end
    ItemESPConns[model] = nil
end

function createItemESP(model)
    if ItemESPGuis[model] then return end
    local cat = categorizeItem(model)
    if not cat then return end
    if not State.ESP_Items[cat] then return end
    local anchor = findItemAnchor(model)
    if not anchor then return end

    local color = ITEM_COLORS[cat] or Color3.fromRGB(255, 255, 255)

    local bb = Instance.new("BillboardGui")
    bb.Name           = "STA_ITEM_ESP"
    bb.Adornee        = anchor
    bb.Size           = UDim2.new(0, 180, 0, 34)
    bb.StudsOffset    = Vector3.new(0, 1.8, 0)
    bb.AlwaysOnTop    = true
    bb.LightInfluence = 0
    bb.MaxDistance    = 2000
    bb.ResetOnSpawn   = false
    bb.Enabled        = false
    bb.Parent         = anchor

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name                   = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size                   = UDim2.new(1, 0, 0, 18)
    nameLabel.Font                   = Enum.Font.GothamBold
    nameLabel.TextSize               = 14
    nameLabel.TextColor3             = color
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    nameLabel.Text                   = model.Name
    nameLabel.Parent                 = bb

    local distLabel = Instance.new("TextLabel")
    distLabel.Name                   = "Dist"
    distLabel.BackgroundTransparency = 1
    distLabel.Size                   = UDim2.new(1, 0, 0, 16)
    distLabel.Position               = UDim2.new(0, 0, 0, 18)
    distLabel.Font                   = Enum.Font.GothamBold
    distLabel.TextSize               = 14
    distLabel.TextColor3             = color
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    distLabel.Text                   = ""
    distLabel.Parent                 = bb

    ItemESPGuis[model] = {
        gui       = bb,
        nameLabel = nameLabel,
        distLabel = distLabel,
        anchor    = anchor,
        category  = cat,
        lastDist  = -1,
        visible   = false,
    }

    ItemESPConns[model] = {
        model.AncestryChanged:Connect(LPH_JIT_MAX(function(_, parent)
            if not parent then destroyItemESP(model) end
        end)),
    }
end

function clearItemESPForCategory(cat)
    for model, info in pairs(ItemESPGuis) do
        if info.category == cat then destroyItemESP(model) end
    end
end

function refreshItemsForCategory(cat)
    if MAP_ESP_CATEGORIES[cat] then
        if State.ESP_Items[cat] then
            local folder = getMapESPFolder(cat)
            if folder then
                local processed = 0
                for _, m in ipairs(folder:GetDescendants()) do
                    if isTopLevelModelInsideFolder(m, folder) then createItemESP(m) end
                    processed += 1
                    if processed % ITEM_ESP_CREATE_BATCH == 0 then task.wait() end
                end
            end
        else
            clearItemESPForCategory(cat)
        end
        return
    end

    if not DroppedFolder then return end
    if State.ESP_Items[cat] then
        local processed = 0
        for _, m in ipairs(DroppedFolder:GetChildren()) do
            if categorizeItem(m) == cat then createItemESP(m) end
            processed += 1
            if processed % ITEM_ESP_CREATE_BATCH == 0 then task.wait() end
        end
    else
        clearItemESPForCategory(cat)
    end
end

task.spawn(LPH_JIT_MAX(function()
    while not DroppedFolder do task.wait(0.5) end
    DroppedFolder.ChildAdded:Connect(LPH_JIT_MAX(function(model)
        task.defer(function()
            if not model.Parent then return end
            local c = categorizeItem(model)
            if c and State.ESP_Items[c] then createItemESP(model) end
        end)
    end))
    DroppedFolder.ChildRemoved:Connect(LPH_JIT_MAX(function(model) destroyItemESP(model) end))
end))

local mapESPFolderConnections = {}
local mapESPBoundFolders = {}

function disconnectMapESPFolder(cat)
    local conns = mapESPFolderConnections[cat]
    if conns then
        for _, conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
    end
    mapESPFolderConnections[cat] = nil
    mapESPBoundFolders[cat] = nil
end

task.spawn(LPH_JIT_MAX(function()
    while true do
        for cat in pairs(MAP_ESP_CATEGORIES) do
            local folder = getMapESPFolder(cat)
            if folder ~= mapESPBoundFolders[cat] then
                disconnectMapESPFolder(cat)
                if folder then
                    mapESPBoundFolders[cat] = folder
                    mapESPFolderConnections[cat] = {
                        folder.DescendantAdded:Connect(LPH_JIT_MAX(function(inst)
                            task.defer(function()
                                if State.ESP_Items[cat]
                                   and inst.Parent
                                   and inst:IsA("Model")
                                   and isTopLevelModelInsideFolder(inst, folder) then
                                    createItemESP(inst)
                                end
                            end)
                        end)),
                        folder.DescendantRemoving:Connect(LPH_JIT_MAX(function(inst)
                            if ItemESPGuis[inst] then destroyItemESP(inst) end
                        end)),
                    }
                    refreshItemsForCategory(cat)
                else
                    clearItemESPForCategory(cat)
                end
            end
        end
        task.wait(2)
    end
end))

function worldModelWantsESP(inst)
    if not inst:IsA("Model") or ItemESPGuis[inst] then return false end
    if State.ESP_Items.Emerald
       and (inst.Name == "Emerald" or inst:GetAttribute("ItemType") == "Emerald")
    then
        return true
    end
    if State.ESP_Items.Misc and (
           MISC_NAMES[inst.Name]
        or inst:GetAttribute("ItemType") == "GasMask"
        or inst:GetAttribute("ItemType") == "QuestItem"
    ) then
        return true
    end
    return false
end

Workspace.ChildAdded:Connect(LPH_JIT_MAX(function(inst)
    task.defer(function()
        if worldModelWantsESP(inst) then createItemESP(inst) end
    end)
end))

function shallowWorldSweep()
    if not (State.ESP_Items.Emerald or State.ESP_Items.Misc) then return end
    for _, inst in ipairs(Workspace:GetChildren()) do
        if worldModelWantsESP(inst) then createItemESP(inst) end
    end
end

function anyItemESPEnabled()
    for _, v in pairs(State.ESP_Items) do
        if v then return true end
    end
    return false
end

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(anyItemESPEnabled() and ITEM_ESP_UPDATE or 0.35)
        local anyEnabled = anyItemESPEnabled()
        if not anyEnabled then continue end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local mp    = hrp.Position
        local mX, mY, mZ = mp.X, mp.Y, mp.Z
        local maxSq = State.ItemESPRange * State.ItemESPRange
        for model, info in pairs(ItemESPGuis) do
            local anchor = info.anchor
            if anchor and anchor.Parent then
                local ap = anchor.Position
                local dx, dy, dz = ap.X - mX, ap.Y - mY, ap.Z - mZ
                local dSq = dx*dx + dy*dy + dz*dz
                if dSq <= maxSq then
                    setGuiVisible(info, true)
                    local dist = math_floor(math_sqrt(dSq))
                    if dist ~= info.lastDist then
                        info.lastDist       = dist
                        info.distLabel.Text = string.format("[%d studs]", dist)
                    end
                else
                    setGuiVisible(info, false)
                end
            else
                destroyItemESP(model)
            end
        end
    end
end))

function getAdjustBackpackRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    local tools = remotes:FindFirstChild("Tools")
    if not tools then return nil end
    return tools:FindFirstChild("AdjustBackpack")
end

function isLootableItem(model)
    if not model or not model:IsA("Model") then return false end
    if not model:IsDescendantOf(Workspace) then return false end
    if model.Name == "Shield" and model.Parent then model = model.Parent end
    if not (DroppedFolder and model:IsDescendantOf(DroppedFolder)) then return false end
    local cat = categorizeItem(model)
    if cat == "Emerald" then return false end
    if not cat then return true end
    return State.AutoLootFilters[cat] ~= false
end

local lootCooldown = {}
local LOOT_RETRY   = 0.12
local LOOT_BURST   = 2
local LOOT_SCAN_DELAY = 0.05
local lastLootScan = -999

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(State.AutoLoot and LOOT_SCAN_DELAY or 0.35)

        if not State.AutoLoot then continue end
        if not DroppedFolder then continue end

        local now = os_clock()
        if now - lastLootScan < LOOT_SCAN_DELAY then continue end
        lastLootScan = now

        local remote = getAdjustBackpackRemote()
        if not remote then continue end

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        if State.PreventLootInBase and isPlayerInBaseCenter(hrp.Position) then continue end

        local userLimit = getPickupRange()
        local effSq = userLimit * userLimit

        for m, t in pairs(lootCooldown) do
            if (not m.Parent) or (now - t > 10) then lootCooldown[m] = nil end
        end

        local originPos = hrp.Position
        for _, model in ipairs(DroppedFolder:GetChildren()) do
            local shouldLoot = State.AutoLoot and isLootableItem(model)

            if shouldLoot then
                local last = lootCooldown[model]
                if (not last) or (now - last) >= LOOT_RETRY then
                    local anchor = findItemAnchor(model)
                    if anchor then
                        local ap = anchor.Position
                        local dx, dz = ap.X - originPos.X, ap.Z - originPos.Z
                        local dSq = dx*dx + dz*dz
                        if dSq <= effSq then
                            lootCooldown[model] = now
                            task.spawn(LPH_JIT_MAX(function()
                                for i = 1, LOOT_BURST do
                                    if not model.Parent then return end
                                    pcall(function() remote:FireServer(model) end)
                                    if i < LOOT_BURST then task.wait() end
                                end
                            end))
                        end
                    end
                end
            end
        end
    end
end))

function getPickUpItemRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    local interaction = remotes:FindFirstChild("Interaction")
    if not interaction then return nil end
    return interaction:FindFirstChild("PickUpItem")
end

do
    local autoEatCooldown = {}
    local autoEatingFood = false
    local lastAutoEatScan = -999
    local AUTO_EAT_RETRY = 0.15
    local AUTO_EAT_SCAN_DELAY = 0.025

    local FOOD_NAME_KEYWORDS = {
        "food", "chips", "bean", "beans", "bread", "meat", "canned",
        "can", "soup", "soda", "water", "apple", "berry", "berries",
        "mre", "ration", "snack",
    }

    local function getCharacterForHunger()
        return LocalPlayer.Character
            or (CharactersFolder and CharactersFolder:FindFirstChild(LocalPlayer.Name))
    end

    local function readHungerAttribute(container)
        if not container then return nil end
        local ok, value = pcall(function()
            return container:GetAttribute("Hunger")
        end)
        value = ok and tonumber(value) or nil
        if value then
            if value <= 1 then value = value * 100 end
            return math.clamp(value, 0, 100)
        end
        return nil
    end

    local function getHungerPercentage()
        -- The real HungerBarScript uses: LocalPlayer.Character:GetAttribute("Hunger") / 100.
        -- This reads that exact attribute first so the Auto Eat percentage is accurate.
        local char = LocalPlayer.Character
        local value = char and char:GetAttribute("Hunger")

        if value == nil then
            local folder = CharactersFolder and CharactersFolder:FindFirstChild(LocalPlayer.Name)
            value = folder and folder:GetAttribute("Hunger")
        end

        value = tonumber(value)
        if value ~= nil then
            if value <= 1 then value = value * 100 end
            return math.clamp(value, 0, 100)
        end

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainUI = playerGui and playerGui:FindFirstChild("MainUI")
        local hungerBar = mainUI and mainUI:FindFirstChild("HungerBar")
        local bar = hungerBar and hungerBar:FindFirstChild("Bar")

        if bar and bar:IsA("GuiObject") then
            local scale = tonumber(bar.Size.X.Scale)
            if scale then return math.clamp(scale * 100, 0, 100) end
        end

        return 100
    end

    local function nameLooksLikeFood(name)
        name = tostring(name or ""):lower()
        for _, key in ipairs(FOOD_NAME_KEYWORDS) do
            if name:find(key, 1, true) then return true end
        end
        return false
    end

    local function isFoodItem(item)
        if not item then return false end
        if item.Name == "Shield" and item.Parent and item.Parent:IsA("Model") then
            item = item.Parent
        end

        local cat = categorizeItem(item)
        if cat == "Food" then return true end

        local okToolType, toolType = pcall(function() return item:GetAttribute("ToolType") end)
        local okItemType, itemType = pcall(function() return item:GetAttribute("ItemType") end)
        if (okToolType and toolType == "Food") or (okItemType and itemType == "Food") then
            return true
        end

        local typeValue = item:FindFirstChild("ItemType")
        if typeValue and typeValue:IsA("StringValue") and typeValue.Value == "Food" then
            return true
        end

        return nameLooksLikeFood(item.Name)
    end

    local function getFoodAnchor(item)
        if not item then return nil end
        if item:IsA("Model") and item.PrimaryPart then return item.PrimaryPart end

        local handle = item:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then return handle end

        local fakeHandle = item:FindFirstChild("FakeHandle")
        if fakeHandle and fakeHandle:IsA("BasePart") then return fakeHandle end

        local mainPart = item:FindFirstChild("MainPart")
        if mainPart and mainPart:IsA("BasePart") then return mainPart end

        return item:FindFirstChildWhichIsA("BasePart", true)
    end

    local function findFoodToolIn(container)
        if not container then return nil end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and isFoodItem(item) then
                return item
            end
        end
        return nil
    end

    local function findFoodTool()
        return findFoodToolIn(LocalPlayer.Character)
            or findFoodToolIn(LocalPlayer:FindFirstChildOfClass("Backpack"))
    end

    local function getUseTime(tool)
        local stats = tool and tool:FindFirstChild("Stats")
        if stats then
            local useTime = tonumber(stats:GetAttribute("UseTime"))
                or tonumber(stats:GetAttribute("EatTime"))
                or tonumber(stats:GetAttribute("ConsumeTime"))
            if useTime and useTime > 0 then
                return math.clamp(useTime, 0.05, 8)
            end
        end
        return 0.2
    end

    local function fireRemote(remote, ...)
        if not remote then return false end
        if remote:IsA("RemoteEvent") then
            return pcall(function(...) remote:FireServer(...) end, ...)
        end
        if remote:IsA("RemoteFunction") then
            return pcall(function(...) remote:InvokeServer(...) end, ...)
        end
        return false
    end

    local function useFoodTool(tool)
        if autoEatingFood or not tool then return false end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hum and hum.Health > 0) then return false end

        autoEatingFood = true

        task.spawn(LPH_JIT_MAX(function()
            local okAny = false

            -- Food BeginUse/EndUse is more reliable when the tool is equipped.
            if tool.Parent ~= char and tool.Parent == LocalPlayer:FindFirstChildOfClass("Backpack") then
                pcall(function() hum:EquipTool(tool) end)
                task.wait(0.06)
            end

            if not tool.Parent then
                autoEatingFood = false
                return
            end

            local beginUse = tool:FindFirstChild("BeginUse")
            local endUse = tool:FindFirstChild("EndUse")

            if beginUse then
                okAny = fireRemote(beginUse) or okAny
                task.wait(getUseTime(tool))
                if endUse then
                    fireRemote(endUse, true)
                end
            else
                local names = { "Eat", "Consume", "Use", "UseItem", "UseFood" }
                for _, name in ipairs(names) do
                    local remote = tool:FindFirstChild(name, true)
                    if remote and fireRemote(remote) then
                        okAny = true
                        break
                    end
                end
            end

            task.wait(okAny and 0.08 or 0.2)
            autoEatingFood = false
        end))

        return true
    end

    local function findNearestDroppedFood(hrp, now)
        if not (DroppedFolder and hrp) then return nil end

        local range = getPickupRange()
        local rangeSq = range * range
        local origin = hrp.Position
        local bestFood, bestSq = nil, math.huge

        for _, item in ipairs(DroppedFolder:GetChildren()) do
            if isFoodItem(item) then
                local last = autoEatCooldown[item]
                if (not last) or (now - last) >= AUTO_EAT_RETRY then
                    local anchor = getFoodAnchor(item)
                    if anchor then
                        local pos = anchor.Position
                        local dx, dz = pos.X - origin.X, pos.Z - origin.Z
                        local distSq = dx * dx + dz * dz
                        if distSq <= rangeSq and distSq < bestSq then
                            bestFood, bestSq = item, distSq
                        end
                    end
                end
            end
        end

        return bestFood
    end

    task.spawn(LPH_JIT_MAX(function()
        while true do
            task.wait(State.AutoEat and AUTO_EAT_SCAN_DELAY or 0.35)
            if not State.AutoEat then continue end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local threshold = math.clamp(math.floor(tonumber(State.AutoEatThreshold) or 90), 1, 100)
            if getHungerPercentage() > threshold then continue end

            local foodTool = findFoodTool()
            if foodTool and useFoodTool(foodTool) then continue end

            local now = os_clock()
            if now - lastAutoEatScan < AUTO_EAT_SCAN_DELAY then continue end
            lastAutoEatScan = now

            local droppedFood = findNearestDroppedFood(hrp, now)
            if not droppedFood then continue end

            autoEatCooldown[droppedFood] = now

            local pickRemote = getPickUpItemRemote()
            if pickRemote then pcall(function() pickRemote:FireServer(droppedFood) end) end

            local backpackRemote = getAdjustBackpackRemote()
            if backpackRemote then
                task.defer(function()
                    if droppedFood and droppedFood.Parent then
                        pcall(function() backpackRemote:FireServer(droppedFood) end)
                    end
                end)
            end
        end
    end))
end

do
local MEDICAL_ITEM_NAMES = {
    "Bandage",
    "Medkit",
    "Med Kit",
    "First Aid Kit",
}

local autoHealing = false
local lastAutoHealAt = -999

function getHealthPercentage()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MaxHealth and hum.MaxHealth > 0 then
        if char:GetAttribute("Dead") then return 0 end
        return math.clamp((hum.Health / hum.MaxHealth) * 100, 0, 100)
    end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainUI = playerGui and playerGui:FindFirstChild("MainUI")
    local healthBar = mainUI and mainUI:FindFirstChild("HealthBar")
    local bar = healthBar and healthBar:FindFirstChild("Bar")
    if bar and bar:IsA("GuiObject") then
        local scale = tonumber(bar.Size.X.Scale)
        if scale then
            return math.clamp(scale * 100, 0, 100)
        end
    end

    return 100
end

function isMedicalTool(tool)
    if not (tool and tool:IsA("Tool")) then return false end
    if not (tool:FindFirstChild("BeginUse") and tool:FindFirstChild("EndUse")) then return false end

    local lower = tool.Name:lower()
    if lower:find("bandage", 1, true)
        or lower:find("medkit", 1, true)
        or lower:find("med kit", 1, true)
        or lower:find("first aid", 1, true) then
        return true
    end

    local toolType = tool:GetAttribute("ToolType")
    local itemType = tool:GetAttribute("ItemType")
    return toolType == "Medical" or itemType == "Medical"
end

function findMedicalTool()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local containers = { char, backpack }

    for _, wantedName in ipairs(MEDICAL_ITEM_NAMES) do
        for _, container in ipairs(containers) do
            local tool = container and container:FindFirstChild(wantedName)
            if isMedicalTool(tool) then
                return tool
            end
        end
    end

    for _, container in ipairs(containers) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if isMedicalTool(tool) then
                    return tool
                end
            end
        end
    end

    return nil
end

function getMedicalUseTime(tool)
    local stats = tool and tool:FindFirstChild("Stats")
    if stats then
        local attrs = stats:GetAttributes()
        local useTime = tonumber(attrs.UseTime)
            or tonumber(attrs.HealTime)
            or tonumber(attrs.Duration)
            or tonumber(stats:GetAttribute("UseTime"))
            or tonumber(stats:GetAttribute("HealTime"))
            or tonumber(stats:GetAttribute("Duration"))
        if useTime and useTime > 0 then
            return math.clamp(useTime, 0.1, 12)
        end
    end

    local lower = tool and tool.Name:lower() or ""
    if lower:find("medkit", 1, true) or lower:find("med kit", 1, true) then
        return 5
    end

    return 3.5
end

function useMedicalTool(tool)
    if autoHealing then return false end
    if not isMedicalTool(tool) then return false end

    local beginUse = tool:FindFirstChild("BeginUse")
    local endUse = tool:FindFirstChild("EndUse")
    if not (beginUse and endUse) then return false end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hum and hum.Health > 0) then return false end
    if char:GetAttribute("Dead") or char:GetAttribute("UsingMedical") then return false end

    autoHealing = true
    lastAutoHealAt = os_clock()

    task.spawn(LPH_JIT_MAX(function()
        local okBegin = pcall(function()
            beginUse:FireServer()
        end)

        if okBegin then
            pcall(function() char:SetAttribute("UsingMedical", true) end)

            local speed = 1 + (tonumber(char:GetAttribute("MedicalSpeed")) or 0)
            if speed <= 0 then speed = 1 end

            local useTime = getMedicalUseTime(tool) / speed
            local started = os_clock()

            while State.AutoHeal
                and tool.Parent
                and hum.Parent
                and hum.Health > 0
                and not char:GetAttribute("Dead")
                and (os_clock() - started) < useTime do
                task.wait(0.05)
            end

            local completed = State.AutoHeal
                and tool.Parent
                and hum.Parent
                and hum.Health > 0
                and not char:GetAttribute("Dead")

            pcall(function()
                endUse:FireServer(completed)
            end)
            pcall(function() char:SetAttribute("UsingMedical", false) end)
        end

        task.wait(0.15)
        autoHealing = false
    end))

    return true
end

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(State.AutoHeal and 0.10 or 0.35)

        if not State.AutoHeal then continue end
        if autoHealing then continue end

        local now = os_clock()
        if now - lastAutoHealAt < 0.25 then continue end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hum and hum.Health > 0 and hum.MaxHealth > 0) then continue end
        if char:GetAttribute("Dead") or char:GetAttribute("UsingMedical") then continue end

        local threshold = math.max(1, math.min(100, math.floor(tonumber(State.AutoHealThreshold) or 70)))
        if getHealthPercentage() > threshold then continue end

        local tool = findMedicalTool()
        if tool then
            useMedicalTool(tool)
        end
    end
end))

end

function classifyPickup(model)
    if not model then return nil end
    local toolType = model:GetAttribute("ToolType")
    if toolType == "Backpack"  then return "Backpack"  end
    if toolType == "Gun"       then return "Gun"       end
    if toolType == "Melee"     then return "Melee"     end
    if toolType == "Blueprint" then return "Blueprint" end
    if toolType == "Throwable" then return "Throwable" end
    if toolType == "Medical"   then return "Medical"   end
    local itemType = model:GetAttribute("ItemType")
    if itemType == "Ammo"  then return "Ammo"  end
    if itemType == "Food"  then return "Food"  end
    if itemType == "Armor" then return "Armor" end
    if ARMOR_NAMES[model.Name] then return "Armor" end
    if itemType == "Emerald" or model.Name == "Emerald" then return "Misc" end
    if itemType == "GasMask" or itemType == "QuestItem" then return "Misc" end
    if MISC_NAMES[model.Name] then return "Misc" end
    return nil
end

function isPickUpItem(model)
    if not model then return false end
    if model.Name == "Shield" and model.Parent and model.Parent:IsA("Model") then
        model = model.Parent
    end
    if model:IsA("Tool") then return true, model end
    if model:GetAttribute("CanPickUp") then return true, model end
    return false
end

local pickUpCooldown = {}
local PICKUP_RETRY   = 0.5
local PICKUP_SCAN_DELAY = 0.05
local lastPickUpScan = -999

function tryPickUp(model, remote, originPos, effSq, now)
    local ok, target = isPickUpItem(model)
    if not ok then return end
    local cat = classifyPickup(target)
    if not cat then return end

    if cat == "Food" then return end
    if not State.AutoPickUp then
        return
    end

    if State.AutoPickUpFilters[cat] == false then return end

    local last = pickUpCooldown[target]
    if last and (now - last) < PICKUP_RETRY then return end

    local anchor = findItemAnchor(target)
    if not anchor then return end
    local ap = anchor.Position
    local dx, dz = ap.X - originPos.X, ap.Z - originPos.Z
    local dSq = dx*dx + dz*dz
    if dSq > effSq then return end

    pickUpCooldown[target] = now
    pcall(function() remote:FireServer(target) end)
end

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(State.AutoPickUp and PICKUP_SCAN_DELAY or 0.35)

        if not State.AutoPickUp then continue end

        local now = os_clock()
        if now - lastPickUpScan < PICKUP_SCAN_DELAY then continue end
        lastPickUpScan = now

        local remote = getPickUpItemRemote()
        if not remote then continue end

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        if State.PreventLootInBase and isPlayerInBaseCenter(hrp.Position) then continue end

        local userLimit = getPickupRange()
        local effSq = userLimit * userLimit

        for m, t in pairs(pickUpCooldown) do
            if (not m.Parent) or (now - t > 5) then pickUpCooldown[m] = nil end
        end

        local originPos = hrp.Position

        if DroppedFolder then
            for _, model in ipairs(DroppedFolder:GetChildren()) do
                tryPickUp(model, remote, originPos, effSq, now)
            end
        end

        for _, inst in ipairs(Workspace:GetChildren()) do
            if inst:IsA("Model")
               and inst ~= DroppedFolder
               and inst ~= char
               and (
                   inst.Name == "Emerald"
                   or MISC_NAMES[inst.Name]
                   or inst:GetAttribute("ItemType") == "Emerald"
                   or inst:GetAttribute("ItemType") == "GasMask"
                   or inst:GetAttribute("ItemType") == "QuestItem"
               )
            then
                tryPickUp(inst, remote, originPos, effSq, now)
            end
        end
    end
end))

local patchedTools = {}

local originalRecoil = _G.recoil
local noopRecoil     = function() end
local recoilPatched  = false

function gunEnhancementsActive()
    return State.NoSpread or State.NoRecoil or State.InstantHit or State.NoAnimationReload
end

function applyRecoilPatch()
    if State.NoRecoil then
        if not recoilPatched then
            originalRecoil = rawget(_G, "recoil") or originalRecoil
            recoilPatched  = true
        end
        _G.recoil = noopRecoil
    else
        if recoilPatched then
            _G.recoil = originalRecoil
            recoilPatched = false
        end
    end
end

function saveToolStats(tool, stats)
    if patchedTools[tool] then return end
    patchedTools[tool] = {
        Inaccuracy           = stats:GetAttribute("Inaccuracy"),
        Recoil               = stats:GetAttribute("Recoil"),
        FireRate             = stats:GetAttribute("FireRate"),
        ReloadTime           = stats:GetAttribute("ReloadTime"),
        ReloadIndividualTime = stats:GetAttribute("ReloadIndividualTime"),
        ReloadEndTime        = stats:GetAttribute("ReloadEndTime"),
        ReloadAnimSpeed      = stats:GetAttribute("ReloadAnimSpeed"),
        ProjectileSpeed      = stats:GetAttribute("ProjectileSpeed"),
        ProjectileGravity    = stats:GetAttribute("ProjectileGravity"),
        ProjectileRange      = stats:GetAttribute("ProjectileRange"),
        Spread               = stats:GetAttribute("Spread"),
        BulletSpread         = stats:GetAttribute("BulletSpread"),
        RecoilKick           = stats:GetAttribute("RecoilKick"),
        RecoilRecovery       = stats:GetAttribute("RecoilRecovery"),
    }
end

function setStatIfPresent(stats, name, value)
    if stats:GetAttribute(name) ~= nil and stats:GetAttribute(name) ~= value then
        stats:SetAttribute(name, value)
    end
end

function restoreToolStats(tool)
    local saved = patchedTools[tool]
    if not saved then return end
    patchedTools[tool] = nil
    if not tool or not tool.Parent then return end
    local stats = tool:FindFirstChild("Stats")
    if not stats then return end
    pcall(function()
        for k, v in pairs(saved) do stats:SetAttribute(k, v) end
    end)
end

function patchGunTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    if not gunEnhancementsActive() then return end
    local stats = tool:FindFirstChild("Stats")
    if not stats then return end
    if stats:GetAttribute("Inaccuracy") == nil
       and stats:GetAttribute("FireRate") == nil
       and stats:GetAttribute("Recoil") == nil
       and stats:GetAttribute("ReloadTime") == nil then return end

    saveToolStats(tool, stats)

    pcall(function()
        if State.NoSpread then
            setStatIfPresent(stats, "Inaccuracy", 0)
            setStatIfPresent(stats, "Spread", 0)
            setStatIfPresent(stats, "BulletSpread", 0)
        end
        if State.NoRecoil then
            setStatIfPresent(stats, "Recoil", 0)
            setStatIfPresent(stats, "RecoilKick", 0)
            setStatIfPresent(stats, "RecoilRecovery", 0)
        end
        if State.InstantHit then
            setStatIfPresent(stats, "FireRate", 99999)
            setStatIfPresent(stats, "ProjectileSpeed", 100000)
            setStatIfPresent(stats, "ProjectileGravity", 0)
            if (tonumber(stats:GetAttribute("ProjectileRange")) or 0) < 5000 then
                setStatIfPresent(stats, "ProjectileRange", 5000)
            end
        end
        if State.NoAnimationReload then
            setStatIfPresent(stats, "ReloadTime",           0)
            setStatIfPresent(stats, "ReloadIndividualTime", 0)
            setStatIfPresent(stats, "ReloadEndTime",        0)
            setStatIfPresent(stats, "ReloadAnimSpeed",      150)
        end
    end)
end

function restoreAllTools()
    for tool, _ in pairs(patchedTools) do restoreToolStats(tool) end
    patchedTools = {}
end

function refreshAllEquippedGuns()
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then patchGunTool(tool) end
    end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then patchGunTool(tool) end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(LPH_JIT_MAX(function(char)
    task.wait(0.2)
    patchedTools = {}
    applyRecoilPatch()
    applyRAReloadSpeedAttribute()
    refreshAllEquippedGuns()
    char.ChildAdded:Connect(LPH_JIT_MAX(function(inst)
        if inst:IsA("Tool") then
            task.wait(0.05)
            patchGunTool(inst)
        end
    end))
end))

if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(LPH_JIT_MAX(function(inst)
        if inst:IsA("Tool") then
            task.wait(0.05)
            patchGunTool(inst)
        end
    end))
end

task.spawn(LPH_JIT_MAX(function()
    local bp = LocalPlayer:WaitForChild("Backpack", 10)
    if bp then
        bp.ChildAdded:Connect(LPH_JIT_MAX(function(inst)
            if inst:IsA("Tool") then
                task.wait(0.05)
                patchGunTool(inst)
            end
        end))
    end
end))

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(gunEnhancementsActive() and 1 or 2)
        applyRecoilPatch()
        if gunEnhancementsActive() then
            refreshAllEquippedGuns()
        end
    end
end))

local PlayerChar, PlayerHum, PlayerHRP
local _noclipConn = nil

local DEFAULT_WALKSPEED = 16

function applyWalkSpeed()
    if not (PlayerChar and PlayerChar.Parent) then return end
    local humanoid = PlayerChar:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if State.WalkSpeedEnabled then
        humanoid.WalkSpeed = math.max(16, math.min(32, tonumber(State.WalkSpeedValue) or 25))
    else
        humanoid.WalkSpeed = DEFAULT_WALKSPEED
    end
end

LocalPlayer.CharacterAdded:Connect(LPH_JIT_MAX(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    if State.WalkSpeedEnabled then
        humanoid.WalkSpeed = math.max(16, math.min(32, tonumber(State.WalkSpeedValue) or 25))
    end
end))

task.spawn(LPH_JIT_MAX(function()
    while true do
        task.wait(State.WalkSpeedEnabled and 0.08 or 0.5)
        if not State.WalkSpeedEnabled then continue end
        local char = LocalPlayer.Character
        if not char then continue end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local target = math.max(16, math.min(32, tonumber(State.WalkSpeedValue) or 25))
            if humanoid.WalkSpeed ~= target then
                humanoid.WalkSpeed = target
            end
        end
    end
end))

function applyNoclip()
    if not State.NoClip then return end
    if not (PlayerChar and PlayerChar.Parent) then return end
    for _, p in ipairs(PlayerChar:GetChildren()) do
        if p:IsA("BasePart") and p.CanCollide then
            p.CanCollide = false
        end
    end
end

local _pickupPart = nil
local _pickupWeld = nil

function destroyPickUpIndicator()
    if _pickupWeld then _pickupWeld:Destroy(); _pickupWeld = nil end
    if _pickupPart then _pickupPart:Destroy(); _pickupPart = nil end
end

function createPickUpIndicator()
    destroyPickUpIndicator()
    if not (PlayerHRP and PlayerHRP.Parent) then return end
    local r = getActiveRadiusRange()

    local part = Instance.new("Part")
    part.Name        = "STA_PICKUP_RANGE"
    part.Shape       = Enum.PartType.Cylinder
    part.Size        = Vector3.new(0.2, r * 2, r * 2)
    part.Anchored    = false
    part.Massless    = true
    part.CanCollide  = false
    part.CanQuery    = false
    part.CanTouch    = false
    part.CastShadow  = false
    part.Material    = Enum.Material.SmoothPlastic
    part.Color       = Color3.fromRGB(30, 110, 45)
    part.Transparency = 0.7
    part.CFrame      = PlayerHRP.CFrame
        * CFrame.new(0, -2.75, 0)
        * CFrame.Angles(0, 0, math.rad(90))
    part.Parent      = Workspace

    local weld = Instance.new("WeldConstraint")
    weld.Part0  = PlayerHRP
    weld.Part1  = part
    weld.Parent = part

    _pickupPart = part
    _pickupWeld = weld
end

function refreshPickUpIndicator()
    if State.AutoPickUpIndicator
        and (State.AutoPickUp or State.AutoLoot or State.AutoEat or State.AutoOpenCrates or State.MeleeAura) then
        createPickUpIndicator()
    else
        destroyPickUpIndicator()
    end
end

function bindCharacter(char)
    PlayerChar = char
    PlayerHum  = char:WaitForChild("Humanoid", 5)
    PlayerHRP  = char:WaitForChild("HumanoidRootPart", 5)
    applyWalkSpeed()
    if State.MeleeAura then setMeleeSpeedAttribute(true) end
    refreshPickUpIndicator()
end

if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(bindCharacter)

UserInputService.JumpRequest:Connect(LPH_JIT_MAX(function()
    if State.InfiniteJump and PlayerHum and PlayerHum.Health > 0 then
        PlayerHum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

function setNoclipActive(active)
    if active and not _noclipConn then
        _noclipConn = RunService.Stepped:Connect(applyNoclip)
    elseif (not active) and _noclipConn then
        _noclipConn:Disconnect()
        _noclipConn = nil
    end
end

local _promptShownConn = nil
local _promptAddedConn = nil
local _promptPatched   = setmetatable({}, { __mode = "k" })
local _promptScanToken = 0
local PROMPT_SCAN_BATCH = 120

local function patchPrompt(prompt)
    if not (State.InstantPrompt and prompt and prompt:IsA("ProximityPrompt")) then return end
    if _promptPatched[prompt] and prompt.HoldDuration == 0 then return end
    _promptPatched[prompt] = true
    pcall(function() prompt.HoldDuration = 0 end)
    pcall(function() prompt.RequiresLineOfSight = false end)
    pcall(function()
        prompt.MaxActivationDistance = math.max(tonumber(prompt.MaxActivationDistance) or 0, getPickupRange(), 10)
    end)
end

local function scanInstantPrompts(token)
    local processed = 0
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if token ~= _promptScanToken or not State.InstantPrompt then return end
        if inst:IsA("ProximityPrompt") then patchPrompt(inst) end
        processed += 1
        if processed % PROMPT_SCAN_BATCH == 0 then task.wait() end
    end
end

local function setInstantPromptActive(active)
    if active then
        _promptScanToken += 1
        task.spawn(scanInstantPrompts, _promptScanToken)
        if not _promptShownConn then
            _promptShownConn = PromptService.PromptShown:Connect(patchPrompt)
        end
        if not _promptAddedConn then
            _promptAddedConn = Workspace.DescendantAdded:Connect(LPH_JIT_MAX(function(inst)
                if inst:IsA("ProximityPrompt") then patchPrompt(inst) end
            end))
        end
    else
        _promptScanToken += 1
        if _promptShownConn then
            _promptShownConn:Disconnect()
            _promptShownConn = nil
        end
        if _promptAddedConn then
            _promptAddedConn:Disconnect()
            _promptAddedConn = nil
        end
    end
end

function notify(title, content, delay)
    pcall(function()
        SpeedHubX:SetNotification({
            Title       = "Kaizen Hub",
            Description = title or "",
            Content     = content or "",
            Time        = 0.4,
            Delay       = delay or 4,
        })
    end)
end

local LowGraphicsCache = {
    Ready = false,
    Overrides = {},
    Variants = {},
}

local function getChangeSettingRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local misc = remotes and remotes:FindFirstChild("Misc")
    return misc and misc:FindFirstChild("ChangeSetting") or nil
end

local function cacheLowGraphicsData()
    if LowGraphicsCache.Ready then return end
    LowGraphicsCache.Ready = true

    pcall(function()
        local materialService = game:GetService("MaterialService")
        local lowQualityFolder = materialService:FindFirstChild("LowQuality")
        if lowQualityFolder then
            for _, materialData in ipairs(lowQualityFolder:GetChildren()) do
                local baseMaterial = materialData.BaseMaterial
                if baseMaterial then
                    LowGraphicsCache.Overrides[baseMaterial] = materialService:GetBaseMaterialOverride(baseMaterial)
                end
            end
        end

        for _, inst in ipairs(materialService:GetChildren()) do
            if inst:IsA("MaterialVariant") then
                LowGraphicsCache.Variants[#LowGraphicsCache.Variants + 1] = inst
            end
        end
    end)
end

local function applyLocalLowGraphics(active)
    cacheLowGraphicsData()

    pcall(function()
        local materialService = game:GetService("MaterialService")
        if active then
            for baseMaterial in pairs(LowGraphicsCache.Overrides) do
                materialService:SetBaseMaterialOverride(baseMaterial, "LowQuality")
            end
            for _, variant in ipairs(LowGraphicsCache.Variants) do
                if variant and variant.Parent then
                    variant.Parent = nil
                end
            end
        else
            for baseMaterial, oldOverride in pairs(LowGraphicsCache.Overrides) do
                materialService:SetBaseMaterialOverride(baseMaterial, oldOverride)
            end
            for _, variant in ipairs(LowGraphicsCache.Variants) do
                if variant and not variant.Parent then
                    variant.Parent = materialService
                end
            end
        end
    end)
end

local function applyReduceLag(active)
    active = active == true
    State.ReduceLag = active

    local remote = getChangeSettingRemote()
    if remote then
        pcall(function()
            remote:FireServer("LowQuality", active)
        end)
    end

    local settingsFolder = LocalPlayer:FindFirstChild("Settings")
    if settingsFolder then
        pcall(function()
            settingsFolder:SetAttribute("LowQuality", active)
        end)
    end

    applyLocalLowGraphics(active)
end

setRemoveFogActive = (function()
    local rf = {
        FogFolder = nil,
        FogRemote = nil,
        Token = 0,
        Scanning = false,
        LastFallback = -999,
        LastScan = -999,
        BoundFolder = nil,
        FolderConn = nil,
        WorkspaceConn = nil,
        LightingConn = nil,
        LightingPropConns = {},
        HrpTouchConn = nil,
        BoundCharacter = nil,
        Touched = setmetatable({}, { __mode = "k" }),
        Tracked = setmetatable({}, { __mode = "k" }),
        TrackedList = {},
        MaintainIndex = 1,
        VisualCache = setmetatable({}, { __mode = "k" }),
        LightingCache = nil,
        AtmosphereCache = setmetatable({}, { __mode = "k" }),
        AtmosphereConns = setmetatable({}, { __mode = "k" }),
        ScanBatch = 80,
        MaintainBatch = 80,
        MaintainDelay = 0.2,
        RescanDelay = 2,
        TouchRetry = 5,
        FallbackRetry = 5,
    }

    local function getFogFolder()
        if rf.FogFolder and rf.FogFolder.Parent then return rf.FogFolder end
        rf.FogFolder = Workspace:FindFirstChild("Fog")
        return rf.FogFolder
    end

    local function getFogTouchedRemote()
        if rf.FogRemote and rf.FogRemote.Parent then return rf.FogRemote end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local misc = remotes and remotes:FindFirstChild("Misc")
        rf.FogRemote = misc and misc:FindFirstChild("FogTouched") or nil
        return rf.FogRemote
    end

    local function parseFogCoords(inst)
        local x, y = tostring(inst and inst.Name or ""):match("^%s*(-?%d+)_(-?%d+)%s*$")
        return tonumber(x), tonumber(y)
    end

    local applyFogLighting

    local function reapplyFogLightingSoon()
        if State.RemoveFog then
            task.defer(function()
                if State.RemoveFog then applyFogLighting(true) end
            end)
        end
    end

    applyFogLighting = function(active)
        if active then
            if not rf.LightingCache then
                rf.LightingCache = {
                    FogStart = Lighting.FogStart,
                    FogEnd = Lighting.FogEnd,
                    FogColor = Lighting.FogColor,
                }
            end

            pcall(function()
                Lighting.FogStart = 0
                Lighting.FogEnd = 1000000
            end)

            for _, inst in ipairs(Lighting:GetChildren()) do
                if inst:IsA("Atmosphere") then
                    if not rf.AtmosphereConns[inst] then
                        rf.AtmosphereConns[inst] = {
                            inst:GetPropertyChangedSignal("Density"):Connect(reapplyFogLightingSoon),
                            inst:GetPropertyChangedSignal("Haze"):Connect(reapplyFogLightingSoon),
                            inst:GetPropertyChangedSignal("Glare"):Connect(reapplyFogLightingSoon),
                        }
                    end
                    if not rf.AtmosphereCache[inst] then
                        rf.AtmosphereCache[inst] = {
                            Density = inst.Density,
                            Haze = inst.Haze,
                            Glare = inst.Glare,
                        }
                    end
                    pcall(function()
                        inst.Density = 0
                        inst.Haze = 0
                        inst.Glare = 0
                    end)
                end
            end
        elseif rf.LightingCache then
            local saved = rf.LightingCache
            pcall(function()
                Lighting.FogStart = saved.FogStart
                Lighting.FogEnd = saved.FogEnd
                Lighting.FogColor = saved.FogColor
            end)
            rf.LightingCache = nil

            for atmosphere, data in pairs(rf.AtmosphereCache) do
                if atmosphere and atmosphere.Parent then
                    pcall(function()
                        atmosphere.Density = data.Density
                        atmosphere.Haze = data.Haze
                        atmosphere.Glare = data.Glare
                    end)
                end
            end
            table.clear(rf.AtmosphereCache)
        end
    end

    local function trackFogVisual(inst)
        if not inst or rf.Tracked[inst] then return end
        rf.Tracked[inst] = true
        rf.TrackedList[#rf.TrackedList + 1] = inst
    end

    local function hideFogVisual(inst)
        if inst:IsA("BasePart") then
            trackFogVisual(inst)
            if not rf.VisualCache[inst] then
                rf.VisualCache[inst] = {
                    Kind = "BasePart",
                    Parent = inst.Parent,
                    Transparency = inst.Transparency,
                    LocalTransparencyModifier = inst.LocalTransparencyModifier,
                    CanCollide = inst.CanCollide,
                    CanTouch = inst.CanTouch,
                    CanQuery = inst.CanQuery,
                }
            end
            pcall(function()
                inst.Transparency = 1
                inst.LocalTransparencyModifier = 1
                inst.CanCollide = false
                inst.CanTouch = false
                inst.CanQuery = false
                inst.Parent = nil
            end)
        elseif inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail") or inst:IsA("Smoke") or inst:IsA("Fire") then
            trackFogVisual(inst)
            if not rf.VisualCache[inst] then
                local okEnabled, enabled = pcall(function() return inst.Enabled end)
                rf.VisualCache[inst] = {
                    Kind = "Effect",
                    Parent = inst.Parent,
                    Enabled = okEnabled and enabled or true,
                }
            end
            pcall(function()
                inst.Enabled = false
                inst.Parent = nil
            end)
        end
    end

    local function restoreFogVisuals()
        for inst, data in pairs(rf.VisualCache) do
            if inst then
                if data.Kind == "BasePart" then
                    pcall(function()
                        if data.Parent and inst.Parent ~= data.Parent then
                            inst.Parent = data.Parent
                        end
                        inst.Transparency = data.Transparency
                        inst.LocalTransparencyModifier = data.LocalTransparencyModifier
                        inst.CanCollide = data.CanCollide
                        inst.CanTouch = data.CanTouch
                        inst.CanQuery = data.CanQuery
                    end)
                elseif data.Kind == "Effect" then
                    pcall(function()
                        if data.Parent and inst.Parent ~= data.Parent then
                            inst.Parent = data.Parent
                        end
                        inst.Enabled = data.Enabled
                    end)
                end
            end
        end
        table.clear(rf.VisualCache)
        table.clear(rf.Tracked)
        table.clear(rf.TrackedList)
        rf.MaintainIndex = 1
    end

    local function touchFogPart(part)
        local now = os_clock()
        local last = rf.Touched[part]
        if last and (now - last) < rf.TouchRetry then return end

        local remote = getFogTouchedRemote()
        if not remote then return end
        local x, y = parseFogCoords(part)
        if not (x and y) then return end

        local ok = pcall(function()
            remote:FireServer(x, y)
        end)
        if ok then rf.Touched[part] = now end
    end

    local function processFogInstance(inst)
        if not State.RemoveFog or not inst then return end
        hideFogVisual(inst)
        if inst:IsA("BasePart") then touchFogPart(inst) end
    end

    local function maintainRemoveFog(token)
        if token ~= rf.Token or not State.RemoveFog then return end

        applyFogLighting(true)

        local total = #rf.TrackedList
        if total <= 0 then return end

        local processed = 0
        local checked = 0
        while processed < rf.MaintainBatch and checked < total do
            if token ~= rf.Token or not State.RemoveFog then return end
            if rf.MaintainIndex > #rf.TrackedList then
                rf.MaintainIndex = 1
            end

            local inst = rf.TrackedList[rf.MaintainIndex]
            rf.MaintainIndex += 1
            checked += 1

            if inst and rf.VisualCache[inst] then
                hideFogVisual(inst)
                if inst:IsA("BasePart") then touchFogPart(inst) end
                processed += 1
            elseif inst and inst.Parent then
                processFogInstance(inst)
                processed += 1
            elseif inst then
                rf.Tracked[inst] = nil
            end
        end
    end

    local function compactRemoveFogTrackedList()
        local write = 1
        for read = 1, #rf.TrackedList do
            local inst = rf.TrackedList[read]
            if inst and rf.Tracked[inst] and (inst.Parent or rf.VisualCache[inst]) then
                rf.TrackedList[write] = inst
                write += 1
            elseif inst then
                rf.Tracked[inst] = nil
            end
        end
        for i = write, #rf.TrackedList do
            rf.TrackedList[i] = nil
        end
        if rf.MaintainIndex > #rf.TrackedList then
            rf.MaintainIndex = 1
        end
    end

    local function disconnectLightingPropertyWatchers()
        for _, conn in ipairs(rf.LightingPropConns) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(rf.LightingPropConns)

        for _, conns in pairs(rf.AtmosphereConns) do
            for _, conn in ipairs(conns) do
                pcall(function() conn:Disconnect() end)
            end
        end
        table.clear(rf.AtmosphereConns)
    end

    local function runRemoveFogPass(token)
        if rf.Scanning then return end
        rf.Scanning = true

        applyFogLighting(true)

        local folder = getFogFolder()
        if folder then
            local processed = 0
            for _, inst in ipairs(folder:GetDescendants()) do
                if token ~= rf.Token or not State.RemoveFog then break end
                if inst:IsA("BasePart")
                    or inst:IsA("ParticleEmitter")
                    or inst:IsA("Beam")
                    or inst:IsA("Trail")
                    or inst:IsA("Smoke")
                    or inst:IsA("Fire") then
                    processFogInstance(inst)
                    processed += 1
                    if processed % rf.ScanBatch == 0 then task.wait() end
                end
            end
        end

        compactRemoveFogTrackedList()

        local remote = getFogTouchedRemote()
        local now = os_clock()
        if remote and token == rf.Token and State.RemoveFog
            and (now - rf.LastFallback) >= rf.FallbackRetry then
            rf.LastFallback = now
            pcall(function() remote:FireServer(1, -5) end)
        end

        rf.Scanning = false
    end

    local function disconnectRemoveFogWatchers()
        if rf.FolderConn then
            rf.FolderConn:Disconnect()
            rf.FolderConn = nil
        end
        if rf.WorkspaceConn then
            rf.WorkspaceConn:Disconnect()
            rf.WorkspaceConn = nil
        end
        if rf.LightingConn then
            rf.LightingConn:Disconnect()
            rf.LightingConn = nil
        end
        disconnectLightingPropertyWatchers()
        if rf.HrpTouchConn then
            rf.HrpTouchConn:Disconnect()
            rf.HrpTouchConn = nil
        end
        rf.BoundFolder = nil
        rf.BoundCharacter = nil
    end

    local function bindCharacterTouch()
        local char = LocalPlayer.Character
        if rf.BoundCharacter == char and rf.HrpTouchConn then return end
        if rf.HrpTouchConn then
            rf.HrpTouchConn:Disconnect()
            rf.HrpTouchConn = nil
        end
        rf.BoundCharacter = char

        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        rf.HrpTouchConn = hrp.Touched:Connect(LPH_JIT_MAX(function(part)
            local folder = getFogFolder()
            if State.RemoveFog and folder and part and part:IsDescendantOf(folder) then
                processFogInstance(part)
            end
        end))
    end

    local function bindRemoveFogWatchers()
        if #rf.LightingPropConns == 0 then
            rf.LightingPropConns[#rf.LightingPropConns + 1] = Lighting:GetPropertyChangedSignal("FogStart"):Connect(reapplyFogLightingSoon)
            rf.LightingPropConns[#rf.LightingPropConns + 1] = Lighting:GetPropertyChangedSignal("FogEnd"):Connect(reapplyFogLightingSoon)
            rf.LightingPropConns[#rf.LightingPropConns + 1] = Lighting:GetPropertyChangedSignal("FogColor"):Connect(reapplyFogLightingSoon)
        end

        if not rf.LightingConn then
            rf.LightingConn = Lighting.ChildAdded:Connect(LPH_JIT_MAX(function(inst)
                if State.RemoveFog and inst:IsA("Atmosphere") then
                    task.defer(function() applyFogLighting(true) end)
                end
            end))
        end

        if not rf.WorkspaceConn then
            rf.WorkspaceConn = Workspace.ChildAdded:Connect(LPH_JIT_MAX(function(child)
                if State.RemoveFog and child.Name == "Fog" then
                    rf.FogFolder = child
                    task.defer(function()
                        bindRemoveFogWatchers()
                        runRemoveFogPass(rf.Token)
                    end)
                end
            end))
        end

        bindCharacterTouch()

        local folder = getFogFolder()
        if folder == rf.BoundFolder then return end

        if rf.FolderConn then
            rf.FolderConn:Disconnect()
            rf.FolderConn = nil
        end

        rf.BoundFolder = folder
        if folder then
            rf.FolderConn = folder.DescendantAdded:Connect(LPH_JIT_MAX(function(inst)
                if State.RemoveFog then processFogInstance(inst) end
            end))
        end
    end

    task.spawn(LPH_JIT_MAX(function()
        while true do
            task.wait(State.RemoveFog and rf.MaintainDelay or 0.75)
            if State.RemoveFog then
                bindRemoveFogWatchers()
                maintainRemoveFog(rf.Token)

                local now = os_clock()
                if (now - rf.LastScan) >= rf.RescanDelay then
                    rf.LastScan = now
                    task.spawn(runRemoveFogPass, rf.Token)
                end
            end
        end
    end))

    return function(active)
        active = active == true
        State.RemoveFog = active
        rf.Token += 1

        if active then
            table.clear(rf.Touched)
            rf.LastFallback = -999
            rf.LastScan = os_clock()
            bindRemoveFogWatchers()
            task.spawn(runRemoveFogPass, rf.Token)
        else
            disconnectRemoveFogWatchers()
            restoreFogVisuals()
            applyFogLighting(false)
        end
    end
end)()

task.spawn(LPH_JIT_MAX(function()
local camera   = Workspace.CurrentCamera
local viewport = camera.ViewportSize
local isTouch  = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isSmall  = viewport.X < 900 or viewport.Y < 550

local winW, winH, tabW
if isTouch or isSmall then
    winW = math.clamp(math.floor(viewport.X * 0.90), 360, 540)
    winH = math.clamp(math.floor(viewport.Y * 0.78), 320, 440)
    tabW = 120
else
    winW = 600
    winH = 380
    tabW = 160
end

local Window = SpeedHubX:CreateWindow({
    Title       = "Kaizen Hub Version 1.0.0",
    Description = HUB_DESCRIPTION,
    ["Tab Width"] = tabW,
    SizeUi      = UDim2.fromOffset(winW, winH),
})

local Tabs
do
    local TAB_ICONS = {
        Main     = "rbxassetid://10734975692",
        Player   = "rbxassetid://10747373176",
        Backpack = "rbxassetid://10709769841",
        Items    = "rbxassetid://10734909540",
        Visual   = "rbxassetid://10734910430",
        ESP      = "rbxassetid://10723346959",
        Info     = "rbxassetid://10723415903",
        Config   = "rbxassetid://10734950309",
    }

    Tabs = {
        Main     = Window:CreateTab({ Name = "Main",     Icon = TAB_ICONS.Main }),
        Player   = Window:CreateTab({ Name = "Player",   Icon = TAB_ICONS.Player }),
        Backpack = Window:CreateTab({ Name = "Backpack", Icon = TAB_ICONS.Backpack }),
        Items    = Window:CreateTab({ Name = "Items",    Icon = TAB_ICONS.Items }),
        Visual   = Window:CreateTab({ Name = "Visuals",  Icon = TAB_ICONS.Visual }),
        ESP      = Window:CreateTab({ Name = "ESP",      Icon = TAB_ICONS.ESP }),
        Info     = Window:CreateTab({ Name = "Info",     Icon = TAB_ICONS.Info }),
        Config   = Window:CreateTab({ Name = "Config",   Icon = TAB_ICONS.Config }),
    }
end
Tabs.Combat = Tabs.Main

local UIRefs = {}
local UIValues = {}
local UISetters = {}
local UITypes = {}

local function setSavedUIValue(name, value)
    UIValues[name] = value
end

local function regToggle(name, section, opts)
    local default = opts.Default or false
    local cb = opts.Callback or function() end
    UIValues[name] = default
    UISetters[name] = cb
    UITypes[name] = "toggle"
    local f = section:AddToggle({
        Title    = opts.Title    or name,
        Content  = opts.Content  or "",
        Default  = default,
        Flag     = name,
        Callback = function(v)
            setSavedUIValue(name, v)
            local ok, err = pcall(cb, v)
            if not ok then warn("[Kaizen Hub] toggle callback failed:", name, err) end
        end,
    })
    UIRefs[name] = f
    return f
end

local function regSlider(name, section, opts)
    local default = opts.Default or 0
    local cb = opts.Callback or function() end
    UIValues[name] = default
    UISetters[name] = cb
    UITypes[name] = "slider"
    local f = section:AddSlider({
        Title     = opts.Title     or name,
        Content   = opts.Content   or "",
        Increment = opts.Increment or 1,
        Min       = opts.Min       or 0,
        Max       = opts.Max       or 100,
        Default   = default,
        Flag      = name,
        Callback  = function(v)
            setSavedUIValue(name, v)
            local ok, err = pcall(cb, v)
            if not ok then warn("[Kaizen Hub] slider callback failed:", name, err) end
        end,
    })
    UIRefs[name] = f
    return f
end

local function regInput(name, section, opts)
    local default = opts.Default or ""
    local cb = opts.Callback or function() end
    UIValues[name] = default
    UISetters[name] = cb
    UITypes[name] = "input"
    local f = section:AddInput({
        Title    = opts.Title    or name,
        Content  = opts.Content  or "",
        Default  = default,
        Flag     = name,
        Callback = function(v)
            setSavedUIValue(name, v)
            local ok, err = pcall(cb, v)
            if not ok then warn("[Kaizen Hub] input callback failed:", name, err) end
        end,
    })
    UIRefs[name] = f
    return f
end

local function regDropdown(name, section, opts)
    local default = opts.Default or ""
    local cb = opts.Callback or function() end
    UIValues[name] = default
    UISetters[name] = cb
    UITypes[name] = "dropdown"
    local f = section:AddDropdown({
        Title    = opts.Title    or name,
        Content  = opts.Content  or "",
        Options  = opts.Options  or {},
        Default  = { default },
        Flag     = name,
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            v = tostring(v or default)
            setSavedUIValue(name, v)
            local ok, err = pcall(cb, v)
            if not ok then warn("[Kaizen Hub] dropdown callback failed:", name, err) end
        end,
    })
    UIRefs[name] = f
    return f
end

do
local AuraSection = Tabs.Combat:AddSection("Gun", true)

regToggle("RangedAura", AuraSection, {
    Title    = "Kill Aura",
    Default  = false,
    Callback = function(v) State.AutoShoot = v end,
})

regDropdown("GunAuraMethod", AuraSection, {
    Title   = "Kill Aura Method",
    Options = { "Default", "Farm Scrap pile" },
    Default = "Default",
    Callback = function(v)
        if v ~= "Farm Scrap pile" then
            State.GunAuraMethod = "Default"
            UIValues.GunAuraMethod = "Default"
            return
        end

        local ok = canUseFarmScrapPile(false)
        if not ok then
            State.GunAuraMethod = "Default"
            UIValues.GunAuraMethod = "Default"
            notifyRayGunRequired(true)
            task.defer(function()
                local f = UIRefs.GunAuraMethod
                if f and typeof(f.Set) == "function" then
                    pcall(function() f:Set({ "Default" }) end)
                elseif f and typeof(f.SetValue) == "function" then
                    pcall(function() f:SetValue("Default") end)
                elseif f and typeof(f.Update) == "function" then
                    pcall(function() f:Update("Default") end)
                elseif f then
                    pcall(function() f.Value = "Default" end)
                end
            end)
            return
        end

        State.GunAuraMethod = "Farm Scrap pile"
        UIValues.GunAuraMethod = "Farm Scrap pile"
    end,
})

regToggle("WallCheck", AuraSection, {
    Title    = "Wall Check",
    Default  = true,
    Callback = function(v) State.WallCheck = v == true end,
})

local TuningSection = Tabs.Combat:AddSection("Tuning", true)

regSlider("Range", TuningSection, {
    Title     = "Range",
    Increment = 1, Min = 10, Max = 500, Default = 250,
    Callback  = function(v) State.Range = tonumber(v) or 250 end,
})

regSlider("FireRate", TuningSection, {
    Title     = "Fire Rate (x100)",
    Increment = 1, Min = 1, Max = 100, Default = 1,
    Callback  = function(v)
        local n = tonumber(v) or 1
        State.FireRate = math.max(0.01, n / 100)
    end,
})

local EnhanceSection = Tabs.Combat:AddSection("Gun Enhancements", false)

regToggle("NoRecoil", EnhanceSection, {
    Title    = "No Recoil",
    Default  = false,
    Callback = function(v)
        State.NoRecoil = v
        applyRecoilPatch()
        if v then refreshAllEquippedGuns()
        else restoreAllTools(); refreshAllEquippedGuns() end
    end,
})

regToggle("NoSpread", EnhanceSection, {
    Title    = "No Spread",
    Default  = false,
    Callback = function(v)
        State.NoSpread = v
        if v then refreshAllEquippedGuns()
        else restoreAllTools(); refreshAllEquippedGuns() end
    end,
})

regToggle("InstantHit", EnhanceSection, {
    Title    = "Instant Hit",
    Default  = false,
    Callback = function(v)
        State.InstantHit = v
        if v then refreshAllEquippedGuns()
        else restoreAllTools(); refreshAllEquippedGuns() end
    end,
})

regToggle("NoAnimationReload", EnhanceSection, {
    Title    = "No-Animation Reload",
    Default  = false,
    Callback = function(v)
        State.NoAnimationReload = v
        applyRAReloadSpeedAttribute()
        if v then refreshAllEquippedGuns()
        else restoreAllTools(); refreshAllEquippedGuns() end
    end,
})

local MeleeSection = Tabs.Combat:AddSection("Melee", false)

regToggle("MeleeAura", MeleeSection, {
    Title    = "Kill Aura",
    Default  = false,
    Callback = function(v)
        State.MeleeAura = v
        if v then
            State.MeleeRange = clampMeleeRange(State.MeleeRange or getPickupRange())
            setMeleeSpeedAttribute(true)
        else
            setMeleeSpeedAttribute(false)
        end
        refreshPickUpIndicator()
    end,
})

regSlider("MeleeRange", MeleeSection, {
    Title     = "Aura Radius",
    Increment = 1, Min = PICKUP_RANGE_MIN, Max = PICKUP_RANGE_MAX, Default = PICKUP_RANGE_DEFAULT,
    Callback  = function(v)
        local n = clampMeleeRange(v)
        State.MeleeRange = n
        State.AutoPickUpRange = n
        if _pickupPart then refreshPickUpIndicator() end
    end,
})

regSlider("MeleeAttackSpeed", MeleeSection, {
    Title     = "Swing Delay (x100)",
    Increment = 1, Min = 1, Max = 15, Default = 2,
    Callback  = function(v)
        local n = tonumber(v) or 2
        State.MeleeAttackSpeed = math.max(0.012, math.min(0.15, n / 100))
        if State.MeleeAura then setMeleeSpeedAttribute(true) end
    end,
})

regSlider("MeleeMaxTargets", MeleeSection, {
    Title     = "Max Targets Per Hit",
    Increment = 1, Min = 1, Max = 10, Default = 6,
    Callback  = function(v)
        State.MeleeMaxTargets = math.max(1, math.min(10, math.floor(tonumber(v) or 6)))
    end,
})

local ReloadSection = Tabs.Combat:AddSection("Reload", false)

regToggle("AutoReload", ReloadSection, {
    Title    = "Auto Reload (Main)",
    Default  = false,
    Callback = function(v)
        State.AutoReload = v
        applyRAReloadSpeedAttribute()
        if v then
            bindAmmoWatcher()
            local tool, _, reload = resolveWeapon()
            checkAmmoReload(tool, reload)
        else
            finishMainReload()
            disconnectAmmoWatcher()
        end
    end,
})

local RemoteArsenalSection = Tabs.Combat:AddSection("Remote Arsenal", false)

RemoteArsenalSection:AddParagraph({
    Title   = "Note",
    Content = "Remote Arsenal options are only for players with the Psychic class.",
})

regToggle("RAAutoReload", RemoteArsenalSection, {
    Title    = "RA Auto Reload",
    Default  = false,
    Callback = function(v)
        State.RAAutoReload = v
        if v then
            task.spawn(LPH_JIT_MAX(function()
                local ra = findRA()
                if ra then hookSetWeaponsClient(ra) end
                applyRAReloadSpeedAttribute(true)
                doRAReload()
            end))
        else
            applyRAReloadSpeedAttribute(false)
            table.clear(raReloadingSlots)
        end
    end,
})

regSlider("RAAutoReloadSpeed", RemoteArsenalSection, {
    Title     = "RA Reload Speed",
    Increment = 1, Min = 1, Max = 5, Default = 3,
    Callback  = function(v)
        State.RAAutoReloadSpeed = math.max(1, math.min(5, math.floor(tonumber(v) or 3)))
        if State.RAAutoReload then applyRAReloadSpeedAttribute(true) end
    end,
})

end

do
local VisualSection = Tabs.Visual:AddSection("Performance", true)

regToggle("ReduceLag", VisualSection, {
    Title    = "Reduce Lag",
    Default  = false,
    Callback = function(v)
        applyReduceLag(v)
    end,
})

regToggle("RemoveFog", VisualSection, {
    Title    = "Remove Fog",
    Default  = false,
    Callback = function(v)
        setRemoveFogActive(v)
    end,
})

end

do
local ESPSection = Tabs.ESP:AddSection("Enemy ESP", true)

regToggle("ShowEnemies", ESPSection, {
    Title    = "Show Enemies",
    Default  = false,
    Callback = function(v)
        State.ESPEnabled = v
        if v then refreshAllESP() else clearAllESP() end
    end,
})

local ItemESPSection = Tabs.ESP:AddSection("Item ESP", false)

for _, cat in ipairs(ITEM_CATEGORIES) do
    local c = cat
    regToggle("ShowItem_" .. c, ItemESPSection, {
        Title    = "Show " .. c,
        Default  = false,
        Callback = function(v)
            State.ESP_Items[c] = v
            refreshItemsForCategory(c)
            if v and (c == "Emerald" or c == "Misc") then shallowWorldSweep() end
        end,
    })
end

regSlider("ItemShowDistance", ItemESPSection, {
    Title     = "Show Distance",
    Increment = 5, Min = 50, Max = 500, Default = 250,
    Callback  = function(v)
        local n = math.max(50, math.min(500, math.floor(tonumber(v) or 250)))
        State.ItemESPRange = n
        State.ESPRange     = n
    end,
})

end

do
local BackpackSection = Tabs.Backpack:AddSection("Loot", true)

regToggle("AutoLoot", BackpackSection, {
    Title    = "Auto Loot",
    Default  = false,
    Callback = function(v)
        State.AutoLoot = v
        if v then lootCooldown = {} end
        refreshPickUpIndicator()
    end,
})

regToggle("PreventLootInBase", BackpackSection, {
    Title    = "Prevent Loot In Base",
    Default  = true,
    Callback = function(v) State.PreventLootInBase = v end,
})

local BackpackFilters = Tabs.Backpack:AddSection("Pick Up Filter", false)

for _, cat in ipairs(ITEM_CATEGORIES) do
    if cat ~= "Emerald" and not MAP_ESP_CATEGORIES[cat] then
        local c = cat
        regToggle("Loot_" .. c, BackpackFilters, {
            Title    = "Pick Up " .. c,
            Default  = true,
            Callback = function(v) State.AutoLootFilters[c] = v end,
        })
    end
end

end

do
local PickUpSection = Tabs.Items:AddSection("Auto PickUp", true)

regToggle("AutoPickUp", PickUpSection, {
    Title    = "Auto PickUp",
    Default  = false,
    Callback = function(v)
        State.AutoPickUp = v
        if v then pickUpCooldown = {} end
        refreshPickUpIndicator()
    end,
})

regToggle("AutoPickUpIndicator", PickUpSection, {
    Title    = "Show PickUp Radius",
    Default  = false,
    Callback = function(v)
        State.AutoPickUpIndicator = v
        refreshPickUpIndicator()
    end,
})

regSlider("AutoPickUpRange", PickUpSection, {
    Title     = "PickUp Range",
    Increment = 1, Min = PICKUP_RANGE_MIN, Max = PICKUP_RANGE_MAX, Default = PICKUP_RANGE_DEFAULT,
    Callback  = function(v)
        local n = clampPickupRange(v)
        State.AutoPickUpRange = n
        State.MeleeRange = n
        if State.AutoOpenCrates then task.defer(refreshCratePromptProperties) end
        if _pickupPart then refreshPickUpIndicator() end
    end,
})

local PickUpFilters = Tabs.Items:AddSection("PickUp Filter", false)

for _, cat in ipairs(PICKUP_CATEGORIES) do
    local c = cat
    regToggle("PickUp_" .. c, PickUpFilters, {
        Title    = "Auto PickUp " .. c,
        Default  = true,
        Callback = function(v) State.AutoPickUpFilters[c] = v end,
    })
end

end

do
    local CrateSection = Tabs.Player:AddSection("Crates", true)

    regToggle("AutoOpenCrates", CrateSection, {
        Title    = "Auto Open Crates",
        Default  = false,
        Callback = function(v)
            State.AutoOpenCrates = v
            if v then
                crateOpenCooldown = {}
                markCrateCacheDirty()
                task.defer(refreshCratePromptProperties)
            end
            refreshPickUpIndicator()
        end,
    })
end

do
    local AutoEatSection = Tabs.Player:AddSection("Auto Eat", true)

    regToggle("AutoEat", AutoEatSection, {
        Title    = "Auto Eat",
        Default  = false,
        Callback = function(v)
            State.AutoEat = v
            refreshPickUpIndicator()
        end,
    })

    regSlider("AutoEatThreshold", AutoEatSection, {
        Title     = "Hunger Percentage",
        Increment = 1, Min = 1, Max = 100, Default = 90,
        Callback  = function(v)
            State.AutoEatThreshold = math.max(1, math.min(100, math.floor(tonumber(v) or 90)))
        end,
    })
end

do
    local AutoHealSection = Tabs.Player:AddSection("Auto Heal", false)

    regToggle("AutoHeal", AutoHealSection, {
        Title    = "Auto Heal",
        Default  = false,
        Callback = function(v)
            State.AutoHeal = v
        end,
    })

    regSlider("AutoHealThreshold", AutoHealSection, {
        Title     = "Health Percentage",
        Increment = 1, Min = 1, Max = 100, Default = 70,
        Callback  = function(v)
            State.AutoHealThreshold = math.max(1, math.min(100, math.floor(tonumber(v) or 70)))
        end,
    })
end

do
local MovementSection = Tabs.Player:AddSection("Movement", true)

regToggle("WalkSpeedEnabled", MovementSection, {
    Title    = "WalkSpeed",
    Default  = false,
    Callback = function(v)
        State.WalkSpeedEnabled = v
        applyWalkSpeed()
    end,
})

regSlider("WalkSpeedValue", MovementSection, {
    Title     = "WalkSpeed Value",
    Increment = 1, Min = 16, Max = 32, Default = 25,
    Callback  = function(v)
        State.WalkSpeedValue = math.max(16, math.min(32, math.floor(tonumber(v) or 25)))
        applyWalkSpeed()
    end,
})

regToggle("InfiniteJump", MovementSection, {
    Title    = "Infinite Jump",
    Default  = false,
    Callback = function(v) State.InfiniteJump = v end,
})

regToggle("NoClip", MovementSection, {
    Title    = "Noclip",
    Default  = false,
    Callback = function(v)
        State.NoClip = v
        setNoclipActive(v)
        if not v and PlayerChar then
            for _, p in ipairs(PlayerChar:GetChildren()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.CanCollide = true
                end
            end
        end
    end,
})

regToggle("InstantPrompt", MovementSection, {
    Title    = "Instant Prompt",
    Default  = false,
    Callback = function(v)
        State.InstantPrompt = v
        setInstantPromptActive(v)
    end,
})

end

local InfoAbout = Tabs.Info:AddSection("About", true)

InfoAbout:AddParagraph({
    Title   = "Kaizen Hub",
    Content = HUB_DESCRIPTION,
})

task.spawn(LPH_JIT_MAX(function()
local CONFIG_ROOT = "KaizenHub"
local CONFIG_DIR  = CONFIG_ROOT .. "/Configs"
local CONFIG_EXT  = ".json"
local AUTOLOAD_FILE = CONFIG_ROOT .. "/autoload.txt"
local CONFIG_VERSION = 3

local configNameInput = ""
local selectedConfigInput = ""
local configDropdown = nil
local configListParagraph = nil
local configStatusParagraph = nil
local configApplying = false

local function updateConfigStatus(message)
    message = tostring(message or "Ready.")
    if configStatusParagraph then
        pcall(function()
            configStatusParagraph:Set({ Title = "Status", Content = message })
        end)
    end
end

local function hasFileApi()
    return typeof(isfile) == "function"
       and typeof(readfile) == "function"
       and typeof(writefile) == "function"
       and typeof(isfolder) == "function"
end

local function ensureConfigFolder()
    if typeof(isfolder) ~= "function" then return false, "isfolder is not supported." end
    if not isfolder(CONFIG_ROOT) then
        if typeof(makefolder) ~= "function" then return false, "makefolder is not supported." end
        local ok, err = pcall(makefolder, CONFIG_ROOT)
        if not ok then return false, tostring(err or "Could not create root folder.") end
    end
    if not isfolder(CONFIG_DIR) then
        if typeof(makefolder) ~= "function" then return false, "makefolder is not supported." end
        local ok, err = pcall(makefolder, CONFIG_DIR)
        if not ok then return false, tostring(err or "Could not create config folder.") end
    end
    return isfolder(CONFIG_DIR), isfolder(CONFIG_DIR) and nil or "Config folder was not created."
end

local function sanitizeName(name)
    name = tostring(name or "")
    name = name:gsub("[\r\n\t]", " ")
    name = name:gsub("[/\\:%*%?\"<>|]", "")
    name = name:gsub("[^%w%-%_ %.]", "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("%s+", " ")
    if #name > 48 then name = name:sub(1, 48) end
    return name
end

local function configPath(name)
    return CONFIG_DIR .. "/" .. sanitizeName(name) .. CONFIG_EXT
end

local TRACKED_OPTIONS = {
    "RangedAura", "GunAuraMethod", "WallCheck",
    "Range", "FireRate",
    "NoRecoil", "NoSpread", "InstantHit", "NoAnimationReload",
    "MeleeAura", "MeleeRange", "MeleeAttackSpeed", "MeleeMaxTargets",
    "AutoReload", "RAAutoReload", "RAAutoReloadSpeed",
    "ShowEnemies", "ItemShowDistance",
    "AutoLoot", "PreventLootInBase",
    "AutoPickUp", "AutoPickUpIndicator", "AutoPickUpRange",
    "AutoOpenCrates", "AutoEat", "AutoEatThreshold", "AutoHeal", "AutoHealThreshold",
    "WalkSpeedEnabled", "WalkSpeedValue",
    "InfiniteJump", "NoClip", "InstantPrompt", "ReduceLag", "RemoveFog",
}

local TRACKED_SET = {}
local function trackOption(name)
    if name and not TRACKED_SET[name] then
        TRACKED_SET[name] = true
        table.insert(TRACKED_OPTIONS, name)
    end
end

for _, name in ipairs(TRACKED_OPTIONS) do
    TRACKED_SET[name] = true
end

for _, c in ipairs(ITEM_CATEGORIES) do
    if c ~= "Emerald" and not MAP_ESP_CATEGORIES[c] then
        trackOption("Loot_" .. c)
    end
    trackOption("ShowItem_" .. c)
end

for _, c in ipairs(PICKUP_CATEGORIES) do
    trackOption("PickUp_" .. c)
end

local function normalizeOptionValue(value)
    if typeof(value) == "number" or typeof(value) == "boolean" or typeof(value) == "string" then
        return value
    end
    return nil
end

local function readOptionValue(name)
    local f = UIRefs[name]
    if f then
        local ok, value = pcall(function() return f.Value end)
        value = ok and normalizeOptionValue(value) or nil
        if value ~= nil then return value end
    end

    return normalizeOptionValue(UIValues[name])
end

local function setUIObjectValue(f, value)
    if not f then return false end
    if typeof(f.Set) == "function" then
        return pcall(function() f:Set(value) end)
    elseif typeof(f.SetValue) == "function" then
        return pcall(function() f:SetValue(value) end)
    elseif typeof(f.Update) == "function" then
        return pcall(function() f:Update(value) end)
    end
    local ok = pcall(function() f.Value = value end)
    return ok
end

local function writeOptionValue(name, value)
    value = normalizeOptionValue(value)
    if value == nil then return false end

    UIValues[name] = value

    local f = UIRefs[name]
    local uiOk
    if UITypes[name] == "dropdown" and f and typeof(f.Set) == "function" then
        uiOk = pcall(function() f:Set({ value }) end)
    else
        uiOk = setUIObjectValue(f, value)
    end

    -- In this UI library, Toggle/Input/Dropdown Set() runs the callback, while Slider Set()
    -- only updates the visual value. Call the real setter once for sliders and for
    -- any control that could not be updated visually.
    local setter = UISetters[name]
    if setter and (UITypes[name] == "slider" or not uiOk) then
        local ok, err = pcall(setter, value)
        if not ok then warn("[Kaizen Hub] config setter failed:", name, err) end
    end

    return f ~= nil or setter ~= nil
end

local function buildSnapshot()
    local snap = {
        __version = CONFIG_VERSION,
        __savedAt = os.date and os.date("%Y-%m-%d %H:%M:%S") or tostring(os_clock()),
        options = {},
    }

    for _, name in ipairs(TRACKED_OPTIONS) do
        local value = readOptionValue(name)
        if value ~= nil then
            snap.options[name] = value
            snap[name] = value -- legacy compatibility for older loader versions
        end
    end

    return snap
end

local function getSnapshotOptions(snap)
    if type(snap) ~= "table" then return nil end
    if type(snap.options) == "table" then return snap.options end
    return snap
end

local function reapplySystemsAfterConfig()
    if State.GunAuraMethod == "Farm Scrap pile" and not canUseFarmScrapPile(false) then
        State.GunAuraMethod = "Default"
        UIValues.GunAuraMethod = "Default"
        if UIRefs.GunAuraMethod and typeof(UIRefs.GunAuraMethod.Set) == "function" then
            pcall(function() UIRefs.GunAuraMethod:Set({ "Default" }) end)
        end
        notifyRayGunRequired(true)
    end

    refreshPickUpIndicator()
    applyWalkSpeed()
    setNoclipActive(State.NoClip)
    setInstantPromptActive(State.InstantPrompt)
    applyReduceLag(State.ReduceLag)
    setRemoveFogActive(State.RemoveFog)
    applyRecoilPatch()

    if State.ESPEnabled then refreshAllESP() else clearAllESP() end
    for _, cat in ipairs(ITEM_CATEGORIES) do
        refreshItemsForCategory(cat)
    end
    if State.ESP_Items.Emerald or State.ESP_Items.Misc then
        shallowWorldSweep()
    end

    if State.NoRecoil or State.NoSpread or State.InstantHit or State.NoAnimationReload then
        refreshAllEquippedGuns()
    else
        restoreAllTools()
    end

    if State.MeleeAura then setMeleeSpeedAttribute(true) else setMeleeSpeedAttribute(false) end
    if State.RAAutoReload then
        applyRAReloadSpeedAttribute(true)
        task.defer(doRAReload)
    else
        applyRAReloadSpeedAttribute(false)
        table.clear(raReloadingSlots)
    end

    if State.AutoLoot then lootCooldown = {} end
    if State.AutoPickUp then pickUpCooldown = {} end
    if State.AutoOpenCrates then
        crateOpenCooldown = {}
        markCrateCacheDirty()
        task.defer(refreshCratePromptProperties)
    end
end

local function applySnapshot(snap)
    local options = getSnapshotOptions(snap)
    if type(options) ~= "table" then return 0 end

    configApplying = true
    local applied = 0
    for i, name in ipairs(TRACKED_OPTIONS) do
        local value = options[name]
        if value ~= nil and writeOptionValue(name, value) then
            applied += 1
        end
        if i % 10 == 0 then task.wait() end
    end
    configApplying = false

    reapplySystemsAfterConfig()
    return applied
end

local function listConfigs()
    local okFolder = ensureConfigFolder()
    if not okFolder or typeof(listfiles) ~= "function" then return {} end

    local out = {}
    local seen = {}
    local ok, files = pcall(listfiles, CONFIG_DIR)
    if not ok or type(files) ~= "table" then return out end

    for _, full in ipairs(files) do
        local base = tostring(full):match("([^/\\]+)$") or tostring(full)
        local nameOnly = base:match("^(.+)%.json$")
        if nameOnly and not seen[nameOnly] then
            seen[nameOnly] = true
            table.insert(out, nameOnly)
        end
    end

    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

local function refreshConfigList()
    local list = listConfigs()
    local text
    if #list == 0 then
        text = "(none)"
    else
        local shown = {}
        for i = 1, math.min(#list, 8) do shown[#shown + 1] = list[i] end
        text = table.concat(shown, ", ")
        if #list > #shown then
            text = text .. ("  +%d more"):format(#list - #shown)
        end
    end

    if configListParagraph then
        pcall(function()
            configListParagraph:Set({ Title = "Saved Configs", Content = text })
        end)
    end

    if configDropdown and typeof(configDropdown.Refresh) == "function" then
        local selecting = selectedConfigInput ~= "" and { selectedConfigInput } or {}
        pcall(function() configDropdown:Refresh(list, selecting) end)
    end
end

local function setSelectedConfig(name)
    name = sanitizeName(name)
    if name == "" then return end
    selectedConfigInput = name
    UIValues.ConfigSelect = name
    setUIObjectValue(UIRefs.ConfigSelect, name)
end

local function saveConfig(name)
    name = sanitizeName(name)
    if name == "" then return false, "Config name is empty." end
    if not hasFileApi() then return false, "Your executor does not support the full file API." end

    local okFolder, folderErr = ensureConfigFolder()
    if not okFolder then return false, folderErr or "Could not create config folder." end

    local snap = buildSnapshot()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(snap) end)
    if not ok then return false, "Failed to encode config." end

    local path = configPath(name)
    if typeof(isfile) == "function" and isfile(path) and typeof(readfile) == "function" then
        local okRead, oldRaw = pcall(readfile, path)
        if okRead and oldRaw and oldRaw ~= "" then
            pcall(writefile, path .. ".bak", oldRaw)
        end
    end

    local okWrite, err = pcall(writefile, path, encoded)
    if not okWrite then return false, tostring(err or "writefile failed") end

    setSelectedConfig(name)
    refreshConfigList()
    return true, #TRACKED_OPTIONS
end

local function loadConfig(name)
    name = sanitizeName(name)
    if name == "" then return false, "Pick a config first." end
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then
        return false, "Your executor does not support readfile/isfile."
    end

    local path = configPath(name)
    if not isfile(path) then return false, "Config not found." end

    local okRead, raw = pcall(readfile, path)
    if not okRead or not raw or raw == "" then return false, "Failed to read config." end

    local okDecode, snap = pcall(function() return HttpService:JSONDecode(raw) end)
    if not okDecode or type(snap) ~= "table" then return false, "Config file is corrupted." end

    setSelectedConfig(name)
    local applied = applySnapshot(snap)
    return true, applied
end

local function deleteConfig(name)
    name = sanitizeName(name)
    if name == "" then return false, "Pick a config first." end
    if typeof(delfile) ~= "function" or typeof(isfile) ~= "function" then
        return false, "Your executor does not support delfile/isfile."
    end

    local path = configPath(name)
    if not isfile(path) then return false, "Config not found." end

    local okDelete, err = pcall(delfile, path)
    if not okDelete then return false, tostring(err or "delfile failed") end

    if selectedConfigInput == name then
        selectedConfigInput = ""
        UIValues.ConfigSelect = ""
        setUIObjectValue(UIRefs.ConfigSelect, "")
    end

    refreshConfigList()
    return true
end

local function getChosenConfigName()
    local saveName = sanitizeName(configNameInput)
    local selected = sanitizeName(selectedConfigInput)
    return selected ~= "" and selected or saveName
end

local ConfigSection = Tabs.Config:AddSection("Save / Load", true)

regInput("ConfigName", ConfigSection, {
    Title    = "Save Name",
    Content  = "Type a name, then press Save Config.",
    Default  = "",
    Callback = function(v) configNameInput = sanitizeName(v) end,
})

configListParagraph = ConfigSection:AddParagraph({
    Title   = "Saved Configs",
    Content = "(loading...)",
})

pcall(function()
    configDropdown = ConfigSection:AddDropdown({
        Title    = "Saved Config",
        Content  = "Pick a config to load, delete, or set as auto-load.",
        Options  = {},
        Default  = {},
        Callback = function(v)
            if typeof(v) == "string" and v ~= "" then
                setSelectedConfig(v)
                updateConfigStatus("Selected \"" .. v .. "\".")
            end
        end,
    })
end)

regInput("ConfigSelect", ConfigSection, {
    Title    = "Selected Config",
    Content  = "Manual fallback. You can type a saved config name here.",
    Default  = "",
    Callback = function(v) selectedConfigInput = sanitizeName(v) end,
})

configStatusParagraph = ConfigSection:AddParagraph({
    Title   = "Status",
    Content = hasFileApi() and "Ready." or "Your executor may not support save/load file APIs.",
})

refreshConfigList()

ConfigSection:AddButton({
    Title    = "Save Config",
    Content  = "Saves every tracked setting and overwrites the same name safely.",
    Callback = function()
        local name = sanitizeName(configNameInput)
        if name == "" then
            notify("Config", "Enter a config name first.", 4)
            updateConfigStatus("Save failed: enter a config name first.")
            return
        end

        local ok, result = saveConfig(name)
        if ok then
            notify("Config", "Saved and selected \"" .. name .. "\".", 4)
            updateConfigStatus(("Saved \"%s\" with %d tracked settings."):format(name, tonumber(result) or 0))
        else
            notify("Config", "Save failed: " .. tostring(result), 5)
            updateConfigStatus("Save failed: " .. tostring(result))
        end
    end,
})

ConfigSection:AddButton({
    Title    = "Load Config",
    Content  = "Loads the selected config and reapplies all active features.",
    Callback = function()
        local name = getChosenConfigName()
        if name == "" then
            notify("Config", "Pick or type a saved config name first.", 4)
            updateConfigStatus("Load failed: no config selected.")
            return
        end

        local ok, result = loadConfig(name)
        if ok then
            notify("Config", ("Loaded \"%s\" (%d settings)."):format(name, tonumber(result) or 0), 4)
            updateConfigStatus(("Loaded \"%s\" and reapplied %d settings."):format(name, tonumber(result) or 0))
        else
            notify("Config", "Load failed: " .. tostring(result), 5)
            updateConfigStatus("Load failed: " .. tostring(result))
        end
    end,
})

ConfigSection:AddButton({
    Title    = "Delete Config",
    Content  = "Deletes the selected saved config file.",
    Callback = function()
        local name = getChosenConfigName()
        if name == "" then
            notify("Config", "Pick or type a saved config name first.", 4)
            updateConfigStatus("Delete failed: no config selected.")
            return
        end

        local ok, err = deleteConfig(name)
        if ok then
            notify("Config", "Deleted \"" .. name .. "\".", 4)
            updateConfigStatus("Deleted \"" .. name .. "\".")
        else
            notify("Config", "Delete failed: " .. tostring(err), 5)
            updateConfigStatus("Delete failed: " .. tostring(err))
        end
    end,
})

ConfigSection:AddButton({
    Title    = "Refresh List",
    Content  = "Refreshes the config list and dropdown from disk.",
    Callback = function()
        refreshConfigList()
        notify("Config", "Config list refreshed.", 3)
        updateConfigStatus("Config list refreshed.")
    end,
})

local AutoLoadSection = Tabs.Config:AddSection("Auto-Load", false)

AutoLoadSection:AddButton({
    Title    = "Set Selected As Auto-Load",
    Content  = "Automatically loads this config next time the script starts.",
    Callback = function()
        local name = getChosenConfigName()
        if name == "" then
            notify("Config", "Pick or type a saved config name first.", 4)
            updateConfigStatus("Auto-load failed: no config selected.")
            return
        end
        if typeof(writefile) ~= "function" then
            notify("Config", "Executor does not support writefile.", 5)
            updateConfigStatus("Auto-load failed: writefile is not supported.")
            return
        end

        local okFolder, folderErr = ensureConfigFolder()
        if not okFolder then
            notify("Config", "Failed: " .. tostring(folderErr), 5)
            updateConfigStatus("Auto-load failed: " .. tostring(folderErr))
            return
        end

        local ok, err = pcall(writefile, AUTOLOAD_FILE, name)
        if ok then
            setSelectedConfig(name)
            notify("Config", "Auto-load set to \"" .. name .. "\".", 4)
            updateConfigStatus("Auto-load set to \"" .. name .. "\".")
        else
            notify("Config", "Failed: " .. tostring(err), 5)
            updateConfigStatus("Auto-load failed: " .. tostring(err))
        end
    end,
})

AutoLoadSection:AddButton({
    Title    = "Load Auto-Load Now",
    Content  = "Immediately loads the config currently saved as auto-load.",
    Callback = function()
        if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" or not isfile(AUTOLOAD_FILE) then
            notify("Config", "No auto-load config is set.", 4)
            updateConfigStatus("No auto-load config is set.")
            return
        end

        local okRead, name = pcall(readfile, AUTOLOAD_FILE)
        name = okRead and sanitizeName(name) or ""
        if name == "" then
            notify("Config", "Auto-load file is empty.", 4)
            updateConfigStatus("Auto-load file is empty.")
            return
        end

        local okLoad, result = loadConfig(name)
        if okLoad then
            notify("Config", ("Loaded auto-load \"%s\"."):format(name), 4)
            updateConfigStatus(("Loaded auto-load \"%s\" (%d settings)."):format(name, tonumber(result) or 0))
        else
            notify("Config", "Auto-load failed: " .. tostring(result), 5)
            updateConfigStatus("Auto-load failed: " .. tostring(result))
        end
    end,
})

AutoLoadSection:AddButton({
    Title    = "Clear Auto-Load",
    Content  = "Stops automatically loading a config on startup.",
    Callback = function()
        if typeof(delfile) == "function" and typeof(isfile) == "function" and isfile(AUTOLOAD_FILE) then
            pcall(delfile, AUTOLOAD_FILE)
        end
        notify("Config", "Auto-load cleared.", 3)
        updateConfigStatus("Auto-load cleared.")
    end,
})

task.spawn(LPH_JIT_MAX(function()
    task.wait(0.65)
    if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(AUTOLOAD_FILE) then
        local okRead, name = pcall(readfile, AUTOLOAD_FILE)
        name = okRead and sanitizeName(name) or ""
        if name ~= "" then
            local okLoad, result = loadConfig(name)
            if okLoad then
                notify("Config", "Auto-loaded \"" .. name .. "\".", 4)
                updateConfigStatus(("Auto-loaded \"%s\" (%d settings)."):format(name, tonumber(result) or 0))
            else
                updateConfigStatus("Auto-load failed: " .. tostring(result))
            end
        end
    end
end))
end))

task.defer(function()
    task.wait(0.25)
    notify("Loaded", (isTouch or isSmall) and "Mobile UI loaded" or "Desktop UI loaded", 4)
end)

end))
