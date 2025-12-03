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

-- Pestaña Visual (Simplificada: Solo toggles para Players y Generators)
local TabVisual = Window:CreateTab("Visual")
TabVisual:CreateSection("ESP")

-- Variables para ESP de players
local playerESPEnhanced = false
local nametagsEnhanced = false
local showDistance = false
local maxDistance = 500

-- Función para aplicar ESP a players (simplificada)
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

-- Toggle para ESP de Players (incluye Survivors y Killers diferenciados)
TabVisual:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESPEnhanced",
    Callback = function(s)
        playerESPEnhanced = s
        if playerESPEnhanced or nametagsEnhanced then startEnhancedESPLoop() else stopEnhancedESPLoop() end
    end
})

-- Toggle para Nametags (opcional, pero útil para players)
TabVisual:CreateToggle({
    Name = "Mostrar nombres",
    CurrentValue = false,
    Flag = "NametagsEnhanced",
    Callback = function(s)
        nametagsEnhanced = s
        if playerESPEnhanced or nametagsEnhanced then startEnhancedESPLoop() else stopEnhancedESPLoop() end
    end
})

-- Función para watch players (necesaria para actualizar ESP)
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

-- Sección Generator ESP (Simplificada)
TabVisual:CreateSection("Generator ESP")

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

-- Toggle para Generator ESP
TabVisual:CreateToggle({
    Name = "Generator ESP",
    CurrentValue = false,
    Flag = "GeneratorESPEnhanced",
    Callback = function(s)
        generatorESPEnhanced = s
        if s then startGeneratorEnhancedLoop() else stopGeneratorEnhancedLoop() end
    end
})
