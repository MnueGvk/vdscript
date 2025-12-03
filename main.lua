local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- Función auxiliar para teleport (definida aquí, ya que faltaba)
local function tpCFrame(cf)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function() hrp.CFrame = cf end)
    end
end

-- Funciones auxiliares
local function alive(i)
    if not i then return false end
    local ok = pcall(function() return i.Parent end)
    return ok and i.Parent ~= nil
end
local function validPart(p) return p and alive(p) and p:IsA("BasePart") end
local function clamp(n, lo, hi) if n < lo then return lo elseif n > hi then return hi else return n end end
local function now() return os.clock() end
local function dist(a, b) return (a - b).Magnitude end
local function firstBasePart(inst)
    if not alive(inst) then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") and alive(inst.PrimaryPart) then return inst.PrimaryPart end
        local p = inst:FindFirstChildWhichIsA("BasePart", true)
        if validPart(p) then return p end
    end
    if inst:IsA("Tool") then
        local h = inst:FindFirstChild("Handle") or inst:FindFirstChildWhichIsA("BasePart")
        if validPart(h) then return h end
    end
    return nil
end
local function makeBillboard(text, color3)
    local g = Instance.new("BillboardGui")
    g.Name = "VD_Tag"
    g.AlwaysOnTop = true
    g.Size = UDim2.new(0, 200, 0, 36)
    g.StudsOffset = Vector3.new(0, 3, 0)
    local l = Instance.new("TextLabel")
    l.Name = "Label"
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Font = Enum.Font.GothamBold
    l.Text = text
    l.TextSize = 14
    l.TextColor3 = color3 or Color3.new(1, 1, 1)
    l.TextStrokeTransparency = 0
    l.TextStrokeColor3 = Color3.new(0, 0, 0)
    l.Parent = g
    return g
end
local function clearChild(o, n)
    if o and alive(o) then
        local c = o:FindFirstChild(n)
        if c then pcall(function() c:Destroy() end) end
    end
end
local function ensureHighlight(model, fill)
    if not (model and model:IsA("Model") and alive(model)) then return end
    local hl = model:FindFirstChild("VD_HL")
    if not hl then
        local ok, obj = pcall(function()
            local h = Instance.new("Highlight")
            h.Name = "VD_HL"
            h.Adornee = model
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = model
            return h
        end)
        if ok then hl = obj else return end
    end
    hl.FillColor = fill
    hl.OutlineColor = fill
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return hl
end
local function clearHighlight(model)
    if model and model:FindFirstChild("VD_HL") then
        pcall(function() model.VD_HL:Destroy() end)
    end
end

-- Funciones para roles y colores
local function getRole(p)
    local tn = p.Team and p.Team.Name and p.Team.Name:lower() or ""
    if tn:find("killer") then return "Killer" end
    if tn:find("survivor") then return "Survivor" end
    return "Survivor"
end
local killerTypeName = "Killer"
local killerColors = {
    Jason = Color3.fromRGB(255, 60, 60),
    Stalker = Color3.fromRGB(255, 120, 60),
    Masked = Color3.fromRGB(255, 160, 60),
    Hidden = Color3.fromRGB(255, 60, 160),
    Abysswalker = Color3.fromRGB(120, 60, 255),
    Killer = Color3.fromRGB(255, 0, 0),
}
local function currentKillerColor()
    return killerColors[killerTypeName] or killerColors.Killer
end
local survivorColor = Color3.fromRGB(0, 255, 0)
local killerBaseColor = killerColors.Killer

-- Inicialización de Window
local Window = Rayfield:CreateWindow({
    Name = "Rayfield Example Window",
    Icon = 0,
    LoadingTitle = "Rayfield Interface Suite",
    LoadingSubtitle = "by Sirius",
    ShowText = "Rayfield",
    Theme = "Default",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "Big Hub"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

-- Pestaña Visual
local TabVisual = Window:CreateTab("Visual")
TabVisual:CreateSection("ESP")

-- Variables para ESP de players
local playerESPEnhanced = false
local nametagsEnhanced = false
local showDistance = false
local maxDistance = 500
local outlineThickness = 2

-- Función para aplicar ESP a players
local function applyEnhancedPlayerESP(p)
    if p == LP then return end
    local c = p.Character
    if not (c and alive(c)) then return end
    local role = getRole(p)
    local baseCol = (role == "Killer") and currentKillerColor() or survivorColor
    local head = c:FindFirstChild("Head")
    local hrp = c:FindFirstChild("HumanoidRootPart")
    
    if playerESPEnhanced then
        local hl = ensureHighlight(c, baseCol)
        if hl then
            hl.OutlineTransparency = 0
            hl.OutlineColor = baseCol
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            if hrp and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local dist = dist(hrp.Position, LP.Character.HumanoidRootPart.Position)
                if dist > maxDistance then
                    hl.FillTransparency = 1
                    hl.OutlineTransparency = 1
                else
                    local fade = clamp(dist / maxDistance, 0, 1)
                    hl.FillTransparency = 0.5 + (fade * 0.5)
                    hl.OutlineTransparency = fade * 0.5
                end
            end
        end
        
        if nametagsEnhanced and validPart(head) then
            local tag = head:FindFirstChild("VD_Tag") or makeBillboard("", baseCol)
            tag.Name = "VD_Tag"
            tag.Parent = head
            local l = tag:FindFirstChild("Label")
            if l then
                local text = (role == "Killer") and (p.Name .. " [" .. tostring(killerTypeName) .. "]") or p.Name
                if showDistance and hrp and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor(dist(hrp.Position, LP.Character.HumanoidRootPart.Position))
                    text = text .. " - " .. dist .. "m"
                end
                l.Text = text
                l.TextColor3 = baseCol
                l.TextStrokeTransparency = 0
                l.TextStrokeColor3 = Color3.new(0, 0, 0)
            end
        else
            local t = head and head:FindFirstChild("VD_Tag")
            if t then pcall(function() t:Destroy() end) end
        end
    else
        clearHighlight(c)
        local head = c:FindFirstChild("Head")
        local t = head and head:FindFirstChild("VD_Tag")
        if t then pcall(function() t:Destroy() end) end
    end
end

local espEnhancedLoopConn = nil
local function startEnhancedESPLoop()
    if espEnhancedLoopConn then return end
    espEnhancedLoopConn = RunService.Heartbeat:Connect(function()
        if not playerESPEnhanced and not nametagsEnhanced then return end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then applyEnhancedPlayerESP(pl) end
        end
    end)
end
local function stopEnhancedESPLoop()
    if espEnhancedLoopConn then espEnhancedLoopConn:Disconnect() espEnhancedLoopConn = nil end
end

-- Controles para ESP de players
TabVisual:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESPEnhanced",
    Callback = function(s)
        playerESPEnhanced = s
        if playerESPEnhanced or nametagsEnhanced then startEnhancedESPLoop() else stopEnhancedESPLoop() end
    end
})
TabVisual:CreateToggle({
    Name = "Nametags Mejorados",
    CurrentValue = false,
    Flag = "NametagsEnhanced",
    Callback = function(s)
        nametagsEnhanced = s
        if playerESPEnhanced or nametagsEnhanced then startEnhancedESPLoop() else stopEnhancedESPLoop() end
    end
})
TabVisual:CreateToggle({
    Name = "Mostrar Distancia en Nametags",
    CurrentValue = false,
    Flag = "ShowDistance",
    Callback = function(s) showDistance = s end
})
TabVisual:CreateSlider({
    Name = "Distancia Máxima ESP",
    Range = {50, 1000},
    Increment = 10,
    CurrentValue = 500,
    Flag = "MaxDistanceESP",
    Callback = function(v) maxDistance = v end
})
TabVisual:CreateColorPicker({
    Name = "Color Survivors",
    Color = survivorColor,
    Flag = "SurvivorColEnhanced",
    Callback = function(c) survivorColor = c end
})
TabVisual:CreateColorPicker({
    Name = "Color Killers",
    Color = killerBaseColor,
    Flag = "KillerColEnhanced",
    Callback = function(c) killerBaseColor = c; killerColors.Killer = c end
})

-- Función para watch players
local playerConns = {}
local function watchPlayer(p)
    if playerConns[p] then for _, cn in ipairs(playerConns[p]) do cn:Disconnect() end end
    playerConns[p] = {}
    table.insert(playerConns[p], p.CharacterAdded:Connect(function()
        task.delay(0.15, function() applyEnhancedPlayerESP(p) end)
    end))
    table.insert(playerConns[p], p:GetPropertyChangedSignal("Team"):Connect(function() applyEnhancedPlayerESP(p) end))
    if p.Character then applyEnhancedPlayerESP(p) end
end
local function unwatchPlayer(p)
    if p.Character then
        clearHighlight(p.Character)
        local head = p.Character:FindFirstChild("Head")
        if head and head:FindFirstChild("VD_Tag") then pcall(function() head.VD_Tag:Destroy() end) end
    end
    if playerConns[p] then for _, cn in ipairs(playerConns[p]) do cn:Disconnect() end end
    playerConns[p] = nil
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then watchPlayer(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LP then watchPlayer(p) end end)
Players.PlayerRemoving:Connect(function(p) unwatchPlayer(p) end)

-- Sección Generator ESP
TabVisual:CreateSection("Generator ESP (Mejorado)")

local generatorESPEnhanced = false
local generatorMaxRange = 300
local worldReg = {Generator = {}}
local mapAdd, mapRem = {}, {}

-- Función para registrar generators
local function ensureWorldEntry(cat, model)
    if not alive(model) or worldReg[cat][model] then return end
    local rep = firstBasePart(model)
    if not validPart(rep) then return end
    worldReg[cat][model] = {model = model, part = rep}
end
local function registerFromDescendant(obj)
    if not alive(obj) then return end
    if obj:IsA("Model") and obj.Name == "Generator" then
        ensureWorldEntry("Generator", obj)
    end
end
local function refreshRoots()
    for _, cn in pairs(mapAdd) do if cn then cn:Disconnect() end end
    for _, cn in pairs(mapRem) do if cn then cn:Disconnect() end end
    mapAdd, mapRem = {}, {}
    local r1 = Workspace:FindFirstChild("Map")
    local r2 = Workspace:FindFirstChild("Map1")
    if r1 then
        mapAdd[r1] = r1.DescendantAdded:Connect(registerFromDescendant)
        for _, d in ipairs(r1:GetDescendants()) do registerFromDescendant(d) end
    end
    if r2 then
        mapAdd[r2] = r2.DescendantAdded:Connect(registerFromDescendant)
        for _, d in ipairs(r2:GetDescendants()) do registerFromDescendant(d) end
    end
    local count = 0
    for _ in pairs(worldReg.Generator) do count = count + 1 end
    Rayfield:Notify({
        Title = "Generator ESP",
        Content = "Generators registrados: " .. count,
        Duration = 3
    })
end
refreshRoots()

-- Función para genProgress
local function genProgress(m)
    local p = tonumber(m:GetAttribute("RepairProgress")) or 0
    if p <= 1.001 then p = p * 100 end
    return clamp(p, 0, 100)
end

-- Función para aplicar ESP a generators
local function applyEnhancedGeneratorESP(entry)
    local model = entry.model
    local part = entry.part
    if not generatorESPEnhanced or not alive(model) or not validPart(part) then return end
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp and dist(part.Position, hrp.Position) > generatorMaxRange then
        clearChild(part, "VD_Generator_Enhanced")
        clearChild(part, "VD_Text_Generator_Enhanced")
        return
    end
    local pct = genProgress(model)
    local hue = clamp(pct / 100, 0, 0.33)
    local dynamicCol = Color3.fromHSV(hue, 1, 1)
    local adornName = "VD_Generator_Enhanced"
    local a = part:FindFirstChild(adornName)
    if not a then
        a = Instance.new("BoxHandleAdornment")
        a.Name = adornName
        a.Adornee = part
        a.ZIndex = 10
        a.AlwaysOnTop = true
        a.Transparency = 0.3
        a.Size = part.Size + Vector3.new(0.5, 0.5, 0.5)
        a.Parent = part
    end
    a.Color3 = dynamicCol
    local textName = "VD_Text_Generator_Enhanced"
    local bb = part:FindFirstChild(textName)
    if not bb then
        bb = makeBillboard("", dynamicCol)
        bb.Name = textName
        bb.Parent = part
    end
    local lbl = bb:FindFirstChild("Label")
    if lbl then
        local txt = "Gen " .. math.floor(pct + 0.5) .. "%"
        lbl.Text = txt
        lbl.TextColor3 = dynamicCol
    end
    if hrp then
        local fadeDist = dist(part.Position, hrp.Position)
        local fade = clamp(fadeDist / generatorMaxRange, 0, 1)
        a.Transparency = 0.3 + (fade * 0.7)
        if lbl then lbl.TextTransparency = fade * 0.5 end
    end
end

local generatorEnhancedLoopConn = nil
local function startGeneratorEnhancedLoop()
    if generatorEnhancedLoopConn then return end
    generatorEnhancedLoopConn = RunService.Heartbeat:Connect(function()
        if not generatorESPEnhanced then return end
        for _, entry in pairs(worldReg.Generator) do
            applyEnhancedGeneratorESP(entry)
        end
    end)
end
local function stopGeneratorEnhancedLoop()
    if generatorEnhancedLoopConn then generatorEnhancedLoopConn:Disconnect() generatorEnhancedLoopConn = nil end
    for _, entry in pairs(worldReg.Generator) do
        if entry.part then
            clearChild(entry.part, "VD_Generator_Enhanced")
            clearChild(entry.part, "VD_Text_Generator_Enhanced")
        end
    end
end

TabVisual:CreateToggle({
    Name = "Generator ESP",
    CurrentValue = false,
    Flag = "GeneratorESPEnhanced",
    Callback = function(s)
        generatorESPEnhanced = s
        if s then startGeneratorEnhancedLoop() else stopGeneratorEnhancedLoop() end
    end
})
TabVisual:CreateSlider({
    Name = "Rango Máximo Generators",
    Range = {50, 1000},
    Increment = 10,
    CurrentValue = 300,
    Flag = "GeneratorMaxRange",
    Callback = function(v) generatorMaxRange = v end
})

-- Pestaña Survivor
local TabSurvivor = Window:CreateTab("Survivor")
TabSurvivor:CreateSection("Reparación Automática")

-- Variables y funciones para auto-repair
local autoRepairEnabled = false
local SCAN_INTERVAL = 1.0
local REPAIR_TICK = 0.25
local AVOID_RADIUS = 80
local MOVE_DIST = 35
local UP_OFFSET = Vector3.new(0, 3, 0)
local gens = {}
local current = nil
local lastScan = 0

local function findRemotes()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if not r then return nil, nil end
    local g = r:FindFirstChild("Generator")
    if not g then return nil, nil end
    local repair = g:FindFirstChild("RepairEvent")
    local anim = g:FindFirstChild("RepairAnim")
    return repair, anim
end
local RepairEvent, RepairAnim = findRemotes()

local function ensureRemotes()
    if RepairEvent and RepairEvent.Parent then return end
    RepairEvent, RepairAnim = findRemotes()
end

local function getGenPartFromModel(m)
    if not (m and alive(m)) then return nil end
    local hb = m:FindFirstChild("HitBox", true)
    if validPart(hb) then return hb end
    return firstBasePart(m)
end

local function genPaused(m)
    return (m:GetAttribute("ProgressPaused") == true)
end

local function rescanGenerators()
    gens = {}
    local function scanRoot(root)
        if not root then return end
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("Model") and d.Name == "Generator" then
                local part = getGenPartFromModel(d)
                if validPart(part) then
                    table.insert(gens, {model = d, part = part})
                end
            end
        end
    end
    scanRoot(Workspace:FindFirstChild("Map"))
    scanRoot(Workspace:FindFirstChild("Map1"))
end

local function nearestKillerDistanceTo(pos)
    local bd = 1e9
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and getRole(pl) == "Killer" then
            local ch = pl.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - pos).Magnitude
                if d < bd then bd = d end
            end
        end
    end
    return bd
end

local function lpHRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function chooseTarget()
    local best = nil
    local bestScore = -1
    for _, g in ipairs(gens) do
        local m = g.model
        if alive(m) then
            local prog = genProgress(m)
            if prog < 100 and not genPaused(m) then
                local pos = g.part.Position
                local kd = nearestKillerDistanceTo(pos)
                local score = (kd >= AVOID_RADIUS and 1000 or 0) + prog
                if score > bestScore then
                    bestScore = score
                    best = g
                end
            end
        end
    end
    return best
end

local function safeFromKiller(target)
    if not target or not target.part then return false end
    local kd = nearestKillerDistanceTo(target.part.Position)
    return kd >= AVOID_RADIUS
end

local function closeEnough(target)
    local hrp = lpHRP()
    if not hrp then return false end
    return (hrp.Position - target.part.Position).Magnitude <= MOVE_DIST
end

local function tpNear(part)
    local cf = part.CFrame * CFrame.new(0, 0, -3)
    tpCFrame((cf + UP_OFFSET))
end

local function doRepair(target)
    ensureRemotes()
    if RepairAnim and RepairAnim.FireServer then pcall(function() RepairAnim:FireServer(target.model) end) end
    if RepairEvent and RepairEvent.FireServer then pcall(function() RepairEvent:FireServer(target.model) end) end
end

task.spawn(function()
    while true do
        local t = now()
        if t - lastScan >= SCAN_INTERVAL then
            lastScan = t
            rescanGenerators()
        end
        task.wait(0.2)
    end
end)

task.spawn(function()
    while true do
        if autoRepairEnabled then
            if (not current) or (not alive(current.model)) or genProgress(current.model) >= 100 or genPaused(current.model) or (not safeFromKiller(current)) then
                current = chooseTarget()
            end
            if current and alive(current.model) and genProgress(current.model) < 100 then
                local me = lpHRP()
                if me and nearestKillerDistanceTo(me.Position) < AVOID_RADIUS then
                    local alt = chooseTarget()
                    if alt and alt ~= current then current = alt end
                end
                if not closeEnough(current) then
                    tpNear(current.part)
                end
                doRepair(current)
            end
        end
        task.wait(REPAIR_TICK)
    end
end)

TabSurvivor:CreateToggle({
    Name = "Auto-Repair Gens",
    CurrentValue = false,
    Flag = "AutoRepairGensSurvivor",
    Callback = function(state)
        autoRepairEnabled = state
        Rayfield:Notify({
            Title = "Auto-Repair",
            Content = state and "activado" or "desactivado",
            Duration = 4
        })
    end
})

ReplicatedStorage.DescendantAdded:Connect(function(d)
    if d:IsA("RemoteEvent") and d.Name == "RepairEvent" then RepairEvent = d end
    if d:IsA("RemoteEvent") and d.Name == "RepairAnim" then RepairAnim = d end
end)

TabSurvivor:CreateSection("Teleports")
local function teleportToNearest(role)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local best, bp, bd = nil, nil, 1e9
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and getRole(pl) == role then
            local ch = pl.Character
            local h = ch and ch:FindFirstChild("HumanoidRootPart")
            if h then
                local d = dist(h.Position, hrp.Position)
                if d < bd then bd = d; best = pl; bp = h end
            end
        end
    end
    if best and bp then
        local cf = bp.CFrame * CFrame.new(0, 0, -3)
        cf = cf + Vector3.new(0, 3, 0)
        tpCFrame(cf)
        Rayfield:Notify({
            Title = "Teleport",
            Content = "A " .. role .. ": " .. best.Name,
            Duration = 4
        })
    else
        Rayfield:Notify({
            Title = "Teleport",
            Content = "No se encontró " .. role .. ".",
            Duration = 4
        })
    end
end

TabSurvivor:CreateButton({
    Name = "Teleport a Killer",
    Callback = function() teleportToNearest("Killer") end
})
TabSurvivor:CreateButton({
    Name = "Teleport a Compañero (Más Cercano)",
    Callback = function() teleportToNearest("Survivor") end
})

TabSurvivor:CreateSection("Escape")
local function findExitLevers()
    local list = {}
    local map = Workspace:FindFirstChild("Map")
    if not map then return list end
    for _, d in ipairs(map:GetDescendants()) do
        if d.Name == "ExitLever" then
            local p = firstBasePart(d)
            if validPart(p) then table.insert(list, p) end
        end
    end
    return list
end

local function teleportRightOfLever(leverPart)
    local right = leverPart.CFrame.RightVector * 50
    local targetPos = leverPart.Position + right
    tpCFrame(CFrame.new(targetPos))
end

TabSurvivor:CreateButton({
    Name = "Instant-Escape (Puerta Más Cercana)",
    Callback = function()
        local levers = findExitLevers()
        if #levers == 0 then
            Rayfield:Notify({
                Title = "Instant-Escape",
                Content = "No se encontró ExitLever.",
                Duration = 5
            })
            return
        end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local pick = levers[1]
        if hrp then
            local bd = 1e9
            for _, p in ipairs(levers) do
                local d = (p.Position - hrp.Position).Magnitude
                if d < bd then bd = d; pick = p end
            end
        end
        teleportRightOfLever(pick)
        Rayfield:Notify({
            Title = "Instant-Escape",
            Content = "Teletransportado detrás de la puerta.",
            Duration = 4
        })
    end
})

TabSurvivor:CreateSection("Otras Herramientas")
TabSurvivor:CreateButton({
    Name = "Resetear Posición (Si Caes)",
    Callback = function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 10, 0)
            Rayfield:Notify({
                Title = "Reset",
                Content = "Posición reseteada.",
                Duration = 3
            })
        end
    end
})

TabSurvivor:CreateSection("Speed Boost")
local speedBoostMultiplier = 1.0
local speedHumanoid = nil  -- Definida aquí
local speedCurrent = 16  -- Velocidad base por defecto (ajusta si es necesario)
local speedEnforced = false  -- Definida aquí

local function canEnforce()  -- Definida aquí
    return speedHumanoid and speedHumanoid.Parent and LP.Character == speedHumanoid.Parent
end

local function setWalkSpeed(h, v)
    if h and h.Parent then
        pcall(function() h.WalkSpeed = v * speedBoostMultiplier end)
    end
end

-- Inicializar speedHumanoid cuando el personaje cargue
LP.CharacterAdded:Connect(function(char)
    speedHumanoid = char:FindFirstChild("Humanoid")
    if speedHumanoid then
        speedCurrent = speedHumanoid.WalkSpeed
    end
end)
if LP.Character then
    speedHumanoid = LP.Character:FindFirstChild("Humanoid")
    if speedHumanoid then
        speedCurrent = speedHumanoid.WalkSpeed
    end
end

TabSurvivor:CreateSlider({
    Name = "Speed Boost Multiplier",
    Range = {1.0, 1.5},
    Increment = 0.1,
    CurrentValue = 1.0,
    Flag = "SpeedBoostMultiplier",
    Callback = function(v)
        speedBoostMultiplier = v
        if speedEnforced and canEnforce() then
            setWalkSpeed(speedHumanoid, speedCurrent)
        elseif speedHumanoid and speedHumanoid.Parent then
            setWalkSpeed(speedHumanoid, speedHumanoid.WalkSpeed)
        end
        Rayfield:Notify({
            Title = "Speed Boost",
            Content = "Boost establecido en " .. tostring(v * 100) .. "%",
            Duration = 3
        })
    end
})

TabSurvivor:CreateSection("Generator Boost")
local generatorBoostMultiplier = 1.0
local isBoostActive = false

task.spawn(function()
    while true do
        local me = lpHRP()
        if me and me.Parent then
            local isNearGen = false
            for _, gen in ipairs(gens) do
                if alive(gen.model) and genProgress(gen.model) < 100 then
                    local dist = (me.Position - gen.part.Position).Magnitude
                    if dist < 10 then
                        isNearGen = true
                        break
                    end
                end
            end
            if isNearGen then
                if me.Parent:FindFirstChild("RepairSpeed") then
                    me.Parent.RepairSpeed.Value = 1.0 * generatorBoostMultiplier
                end
                if not isBoostActive then
                    Rayfield:Notify({
                        Title = "Generator Boost Activado",
                        Content = "¡Estás cerca de un generador! Reparación acelerada en " .. tostring(generatorBoostMultiplier * 100) .. "%.",
                        Duration = 3
                    })
                    isBoostActive = true
                end
            else
                if me.Parent:FindFirstChild("RepairSpeed") then
                    me.Parent.RepairSpeed.Value = 1.0
                end
                if isBoostActive then
                    Rayfield:Notify({
                        Title = "Generator Boost Desactivado",
                        Content = "Te alejaste del generador. Reparación normal.",
                        Duration = 3
                    })
                    isBoostActive = false
                end
            end
        end
        task.wait(0.1)
    end
end)

TabSurvivor:CreateSlider({
    Name = "Generator Boost Multiplier",
    Range = {1.0, 1.5},
    Increment = 0.1,
    CurrentValue = 1.0,
    Flag = "GeneratorBoostMultiplier",
    Callback = function(v)
        generatorBoostMultiplier = v
        Rayfield:Notify({
            Title = "Generator Boost",
            Content = "Boost establecido en " .. tostring(v * 100) .. "%",
            Duration = 3
        })
    end
})

TabSurvivor:CreateSection("Perfect Skill Check")
local perfectSkillEnabled = false
local perfectSkillHookInstalled = false
local perfectSkillConn = nil
local oldNamecall = nil

local function isExactSkill(inst)
    if typeof(inst) == "Instance" and inst:IsA("RemoteEvent") then
        local name = inst.Name:lower()
        return name:find("skillcheck") or name:find("skill") or name:find("check")
    end
    if typeof(inst) == "Instance" and (inst:IsA("ScreenGui") or inst:IsA("GuiObject")) then
        local name = inst.Name:lower()
        return name:find("skillcheck") or name:find("skill")
    end
    return false
end

local function installPerfectSkillHook()
    if perfectSkillHookInstalled or not (typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function") then
        if not typeof(hookmetamethod) == "function" then
            Rayfield:Notify({
                Title = "Perfect Skill Check",
                Content = "Hook no soportado: Requiere un executor avanzado (e.g., Synapse). Usando modo alternativo.",
                Duration = 5
            })
            return false
        end
        return true
    end
    local success, err = pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if perfectSkillEnabled and isExactSkill(self) then
                local m = getnamecallmethod()
                if m == "FireServer" or m == "InvokeServer" then
                    local args = {...}
                    if self.Name == "SkillCheckEvent" or self.Name == "SkillCheckResultEvent" then
                        args[1] = true
                        args[2] = 1.0
                        return oldNamecall(self, table.unpack(args))
                    elseif self.Name == "SkillCheckFailEvent" then
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if success then
        perfectSkillHookInstalled = true
        Rayfield:Notify({
            Title = "Perfect Skill Check",
            Content = "Hook instalado correctamente.",
            Duration = 3
        })
    else
        Rayfield:Notify({
            Title = "Perfect Skill Check",
            Content = "Error al instalar hook: " .. tostring(err) .. ". Usando modo alternativo.",
            Duration = 5
        })
        return false
    end
    return true
end

local function startPerfectSkill()
    if not installPerfectSkillHook() then
        Rayfield:Notify({
            Title = "Perfect Skill Check",
            Content = "Modo alternativo activado: Solo simulación de input.",
            Duration = 3
        })
    end
    perfectSkillEnabled = true
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        if perfectSkillConn then perfectSkillConn:Disconnect() end
        perfectSkillConn = pg.DescendantAdded:Connect(function(d)
            if perfectSkillEnabled and isExactSkill(d) and d:IsA("ScreenGui") then
                task.delay(0.1, function()
                    if d and d.Parent then
                        VirtualUser:Button1Down(Vector2.new(0, 0))
                        task.wait(0.05)
                        VirtualUser:Button1Up(Vector2.new(0, 0))
                        Rayfield:Notify({
                            Title = "Perfect Skill Check",
                            Content = "¡Skill check completado!",
                            Duration = 2
                        })
                    end
                end)
            end
        end)
    end
end

local function stopPerfectSkill()
    perfectSkillEnabled = false
    if perfectSkillConn then 
        perfectSkillConn:Disconnect() 
        perfectSkillConn = nil 
    end
end

local function evalPerfectSkill()
    if perfectSkillEnabled and getRole(LP) ~= "Survivor" then
        stopPerfectSkill()
        Rayfield:Notify({
            Title = "Perfect Skill Check",
            Content = "Desactivado: Solo para Survivors.",
            Duration = 4
        })
    end
end

TabSurvivor:CreateToggle({
    Name = "Perfect Skill Check",
    CurrentValue = false,
    Flag = "PerfectSkillCheck",
    Callback = function(s)
        if s and getRole(LP) ~= "Survivor" then
            Rayfield:Notify({
                Title = "Perfect Skill Check",
                Content = "Solo disponible para Survivors.",
                Duration = 4
            })
            return
        end
        if s then
            startPerfectSkill()
            Rayfield:Notify({
                Title = "Perfect Skill Check",
                Content = "Activado: Skill checks serán perfectos.",
                Duration = 3
            })
        else
            stopPerfectSkill()
            Rayfield:Notify({
                Title = "Perfect Skill Check",
                Content = "Desactivado.",
                Duration = 3
            })
        end
    end
})

LP:GetPropertyChangedSignal("Team"):Connect(evalPerfectSkill)

Rayfield:LoadConfiguration()
