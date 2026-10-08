-- XEN HUB v1.0
print("[Xen] Loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

pcall(function()
    local p = gethui and gethui() or game:GetService("CoreGui")
    local o = p:FindFirstChild("XenHub")
    if o then o:Destroy() end
end)

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local C = {
    BG = Color3.fromRGB(18,18,20),
    SURFACE = Color3.fromRGB(26,26,30),
    SURFACE2 = Color3.fromRGB(34,34,40),
    TEXT = Color3.fromRGB(240,240,245),
    DIM = Color3.fromRGB(120,120,130),
    ACCENT = Color3.fromRGB(220,60,60),
    GREEN = Color3.fromRGB(80,220,120),
    GOLD = Color3.fromRGB(255,215,0),
    OFF = Color3.fromRGB(50,50,60),
}

local function getChar()
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not (h and r) or h.Health <= 0 then return nil end
    return c, h, r
end

-- AUTO GRAB
local XenGrab = {Enabled=false,Range=15,Cooldown=0.4,LastGrab=0,IgnoreLocked=false,Count=0,Busy=false}

local function isEnemyPlot(plot)
    if not plot or not plot:IsA("Model") then return false end
    local sign = plot:FindFirstChild("PlotSign")
    local yb = sign and sign:FindFirstChild("YourBase")
    if yb and yb.Enabled then return false end
    local sg = sign and sign:FindFirstChild("SurfaceGui")
    local fr = sg and sg:FindFirstChild("Frame")
    local lb = fr and fr:FindFirstChild("TextLabel")
    if not lb or lb.Text == "Empty Base" then return false end
    local ow = lb.Text:gsub("'s [Bb]ase$",""):gsub("%s+$","")
    return ow ~= LocalPlayer.Name and ow ~= LocalPlayer.DisplayName
end

local function isLocked(plot)
    local pu = plot and plot:FindFirstChild("Purchases")
    local pb = pu and pu:FindFirstChild("PlotBlock")
    local mn = pb and pb:FindFirstChild("Main")
    local bb = mn and mn:FindFirstChild("BillboardGui")
    local lk = bb and bb:FindFirstChild("Locked")
    return lk and lk.Visible
end

local function podParts(pod)
    local b = pod and pod:FindFirstChild("Base")
    local sp = b and b:FindFirstChild("Spawn")
    local at = sp and sp:FindFirstChild("PromptAttachment")
    local pr = at and at:FindFirstChildWhichIsA("ProximityPrompt")
    return sp, pr
end

local function podName(pod)
    local sp = pod and pod:FindFirstChild("Base") and pod.Base:FindFirstChild("Spawn")
    local db = Workspace:FindFirstChild("Debris")
    if not (sp and db) then return "?" end
    local bp = sp.Position
    local best, bd = nil, 7
    for _, o in ipairs(db:GetChildren()) do
        if o.Name == "FastOverheadTemplate" and o:IsA("BasePart") then
            local p = o.Position
            local d = Vector3.new(p.X-bp.X,0,p.Z-bp.Z).Magnitude
            if d < bd and p.Y > bp.Y-2 and p.Y < bp.Y+25 then best,bd = o,d end
        end
    end
    local bb = best and best:FindFirstChild("AnimalOverhead")
    if not bb then return "?" end
    local function t(n)
        local l = bb:FindFirstChild(n,true)
        return (l and l:IsA("TextLabel") and l.Visible and l.Text ~= "") and l.Text or nil
    end
    local nm, mu = t("DisplayName"), t("Mutation")
    if not nm then return "?" end
    return (mu and (mu.." ") or "")..nm
end

local function findCands(hrp)
    local list = {}
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return list end
    for _, plot in ipairs(plots:GetChildren()) do
        if not isEnemyPlot(plot) then continue end
        if not XenGrab.IgnoreLocked and isLocked(plot) then continue end
        local pods = plot:FindFirstChild("AnimalPodiums")
        if not pods then continue end
        for _, pod in ipairs(pods:GetChildren()) do
            local sp, pr = podParts(pod)
            if sp and pr and pr.Enabled then
                local d = (sp.Position-hrp.Position).Magnitude
                if d <= XenGrab.Range then
                    table.insert(list,{prompt=pr,spawn=sp,distance=d,name=podName(pod)})
                end
            end
        end
    end
    table.sort(list,function(a,b) return a.distance < b.distance end)
    return list
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "XenHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = gethui() end)
if not gui.Parent then gui.Parent = game:GetService("CoreGui") end

-- BARRE
local GrabBar = Instance.new("Frame")
GrabBar.Size = UDim2.fromOffset(240,46)
GrabBar.Position = UDim2.new(0.5,-120,1,-90)
GrabBar.BackgroundColor3 = C.BG
GrabBar.BorderSizePixel = 0
GrabBar.Visible = false
GrabBar.ZIndex = 10
GrabBar.Parent = gui
Instance.new("UICorner",GrabBar).CornerRadius = UDim.new(0,10)
local gbs = Instance.new("UIStroke",GrabBar)
gbs.Color = C.ACCENT
gbs.Thickness = 1.5
gbs.Transparency = 0.3

local gTitle = Instance.new("TextLabel",GrabBar)
gTitle.Size = UDim2.new(1,-16,0,14)
gTitle.Position = UDim2.fromOffset(8,3)
gTitle.BackgroundTransparency = 1
gTitle.Text = "AUTO GRAB"
gTitle.TextColor3 = C.ACCENT
gTitle.Font = Enum.Font.GothamBold
gTitle.TextSize = 10
gTitle.TextXAlignment = Enum.TextXAlignment.Left
gTitle.ZIndex = 11

local gName = Instance.new("TextLabel",GrabBar)
gName.Size = UDim2.new(1,-16,0,12)
gName.Position = UDim2.fromOffset(8,16)
gName.BackgroundTransparency = 1
gName.Text = ""
gName.TextColor3 = C.TEXT
gName.Font = Enum.Font.Gotham
gName.TextSize = 9
gName.TextXAlignment = Enum.TextXAlignment.Left
gName.TextTruncate = Enum.TextTruncate.AtEnd
gName.ZIndex = 11

local gTrack = Instance.new("Frame",GrabBar)
gTrack.Size = UDim2.new(1,-16,0,8)
gTrack.Position = UDim2.fromOffset(8,32)
gTrack.BackgroundColor3 = C.SURFACE
gTrack.BorderSizePixel = 0
gTrack.ZIndex = 11
Instance.new("UICorner",gTrack).CornerRadius = UDim.new(0,4)

local gFill = Instance.new("Frame",gTrack)
gFill.Size = UDim2.new(0,0,1,0)
gFill.BackgroundColor3 = C.ACCENT
gFill.BorderSizePixel = 0
gFill.ZIndex = 12
Instance.new("UICorner",gFill).CornerRadius = UDim.new(0,4)

local gPct = Instance.new("TextLabel",gTrack)
gPct.Size = UDim2.fromScale(1,1)
gPct.BackgroundTransparency = 1
gPct.Text = "0%"
gPct.TextColor3 = C.TEXT
gPct.Font = Enum.Font.GothamBold
gPct.TextSize = 8
gPct.TextStrokeTransparency = 0.5
gPct.ZIndex = 13

local function showBar(n)
    gTitle.Text = "AUTO GRAB"
    gTitle.TextColor3 = C.ACCENT
    gbs.Color = C.ACCENT
    gName.Text = n or "Brainrot"
    gFill.Size = UDim2.new(0,0,1,0)
    gFill.BackgroundColor3 = C.ACCENT
    gPct.Text = "0%"
    GrabBar.Visible = true
end
local function updateBar(p)
    p = math.clamp(p,0,1)
    gFill.Size = UDim2.new(p,0,1,0)
    gPct.Text = math.floor(p*100).."%"
end
local function successBar()
    gTitle.Text = "GRABBED"
    gTitle.TextColor3 = C.GREEN
    gbs.Color = C.GREEN
    gFill.BackgroundColor3 = C.GREEN
    gPct.Text = "100%"
    task.delay(1.2,function() GrabBar.Visible = false end)
end
local function failBar(r)
    gTitle.Text = "FAILED"
    gName.Text = r or ""
    task.delay(0.8,function() GrabBar.Visible = false end)
end

local HOLD_TIME = 0.5

local function doGrab(c)
    if not (c and c.prompt and c.prompt.Parent) then return false end
    local pr = c.prompt
    pcall(function()
        pr.RequiresLineOfSight = false
        pr.MaxActivationDistance = math.huge
    end)
    showBar(c.name)
    pcall(function() pr:InputHoldBegin() end)
    local t0 = os.clock()
    while os.clock()-t0 < HOLD_TIME do
        updateBar((os.clock()-t0)/HOLD_TIME)
        task.wait(0.02)
    end
    pcall(function() pr:InputHoldEnd() end)
    updateBar(1)
    local fired = false
    if fireproximityprompt then fired = pcall(fireproximityprompt,pr,0) end
    if not fired and firesignal then pcall(firesignal,pr.Triggered) fired = true end
    if fired then successBar() else failBar("Refuse") end
    return fired
end

task.spawn(function()
    while task.wait(0.1) do
        if not XenGrab.Enabled then continue end
        if XenGrab.Busy then continue end
        if os.clock()-XenGrab.LastGrab < XenGrab.Cooldown then continue end
        local _,_,hrp = getChar()
        if not hrp then continue end
        if LocalPlayer:GetAttribute("Stealing") then continue end
        local ok,list = pcall(findCands,hrp)
        if not ok or #list == 0 then continue end
        XenGrab.Busy = true
        XenGrab.LastGrab = os.clock()
        local got = doGrab(list[1])
        if got then
            XenGrab.Count = XenGrab.Count + 1
            print("[Xen Grab]",list[1].name,"Total:",XenGrab.Count)
        end
        task.wait(0.25)
        XenGrab.Busy = false
    end
end)

function XenGrab.SetEnabled(v)
    XenGrab.Enabled = v and true or false
    if not v then GrabBar.Visible = false end
end

-- AUTO INVISIBLE
local XenInvis = {Enabled=false,Angle=120,Active=false,Conn=nil}

local function applyTilt()
    if XenInvis.Active then return end
    XenInvis.Active = true
    local rad = math.rad(XenInvis.Angle)
    local _,_,hrp = getChar()
    if hrp then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(rad,0,0)
    end
    XenInvis.Conn = RunService.Heartbeat:Connect(function()
        if not XenInvis.Enabled or not XenInvis.Active then return end
        local _,_,h = getChar()
        if not h then return end
        local _,yaw = h.CFrame:ToEulerAnglesYXZ()
        h.CFrame = CFrame.new(h.Position) * CFrame.Angles(rad,yaw,0)
    end)
end

local function removeTilt()
    if XenInvis.Conn then XenInvis.Conn:Disconnect() XenInvis.Conn = nil end
    XenInvis.Active = false
    local _,_,hrp = getChar()
    if hrp then
        local _,yaw = hrp.CFrame:ToEulerAnglesYXZ()
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0,yaw,0)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
    if not XenInvis.Enabled then return end
    if LocalPlayer:GetAttribute("Stealing") then applyTilt() else removeTilt() end
end)
LocalPlayer.CharacterAdded:Connect(function()
    removeTilt()
    task.wait(0.3)
    if XenInvis.Enabled and LocalPlayer:GetAttribute("Stealing") then applyTilt() end
end)

function XenInvis.SetEnabled(v)
    XenInvis.Enabled = v and true or false
    if not v then removeTilt()
    elseif LocalPlayer:GetAttribute("Stealing") then applyTilt() end
end

-- CARPET SPEED
local XenCarpet = {Enabled=false,Speed=160,LastHum=nil,LastSpeed=nil}
local CARPETS = {"carpet","broom","wings","sleigh","waverider","hoverboard","glider","balai","tapis"}

local function hasCarpet()
    local c = LocalPlayer.Character
    local t = c and c:FindFirstChildOfClass("Tool")
    if not t then return false end
    local n = t.Name:lower()
    for _,k in ipairs(CARPETS) do
        if n:find(k,1,true) then return true end
    end
    return false
end

task.spawn(function()
    while task.wait(0.1) do
        if not XenCarpet.Enabled then
            if XenCarpet.LastHum and XenCarpet.LastSpeed then
                pcall(function() XenCarpet.LastHum.WalkSpeed = XenCarpet.LastSpeed end)
            end
            XenCarpet.LastHum, XenCarpet.LastSpeed = nil, nil
            continue
        end
        local _,hum = getChar()
        if not hum then continue end
        if hum ~= XenCarpet.LastHum then
            if XenCarpet.LastHum and XenCarpet.LastSpeed then
                pcall(function() XenCarpet.LastHum.WalkSpeed = XenCarpet.LastSpeed end)
            end
            XenCarpet.LastHum = hum
            XenCarpet.LastSpeed = hum.WalkSpeed
        end
        if hasCarpet() then
            if hum.WalkSpeed ~= XenCarpet.Speed then hum.WalkSpeed = XenCarpet.Speed end
        else
            if XenCarpet.LastSpeed and hum.WalkSpeed ~= XenCarpet.LastSpeed then hum.WalkSpeed = XenCarpet.LastSpeed end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    XenCarpet.LastHum, XenCarpet.LastSpeed = nil, nil
end)

function XenCarpet.SetEnabled(v) XenCarpet.Enabled = v and true or false end
-- ANTI RAGDOLL
local XenRag = {Enabled=false,Conns={},Hum=nil}

local function cleanRag(character)
    if not character then return end
    pcall(function()
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") or obj:IsA("HingeConstraint") then
                obj:Destroy()
            elseif obj:IsA("Attachment") and (obj.Name == "A" or obj.Name == "B") then
                obj:Destroy()
            elseif obj:IsA("Motor6D") then
                obj.Enabled = true
            end
        end
    end)
end

local function harden(hum)
    pcall(function() hum.BreakJointsOnDeath = false end)
    pcall(function() hum.RequiresNeck = false end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
end

local function setupRag()
    for _, c in ipairs(XenRag.Conns) do pcall(function() c:Disconnect() end) end
    XenRag.Conns = {}
    if not XenRag.Enabled then return end
    local char, hum = getChar()
    if not (char and hum) then return end
    XenRag.Hum = hum
    harden(hum)

    table.insert(XenRag.Conns, hum:GetPropertyChangedSignal("Health"):Connect(function()
        if not XenRag.Enabled then return end
        if hum.Parent and hum.Health <= 0 then
            pcall(function() hum.Health = hum.MaxHealth end)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end))

    table.insert(XenRag.Conns, hum.Died:Connect(function()
        if not XenRag.Enabled then return end
        if hum.Parent then
            pcall(function() hum.Health = hum.MaxHealth end)
        end
    end))

    table.insert(XenRag.Conns, hum.StateChanged:Connect(function()
        if not XenRag.Enabled then return end
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
            cleanRag(char)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end))

    table.insert(XenRag.Conns, RunService.Heartbeat:Connect(function()
        if not XenRag.Enabled or not hum.Parent then return end
        harden(hum)
        if hum.Health <= 0 then
            pcall(function() hum.Health = hum.MaxHealth end)
        end
    end))
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    setupRag()
end)

function XenRag.SetEnabled(v)
    XenRag.Enabled = v and true or false
    if XenRag.Enabled then setupRag()
    else
        for _, c in ipairs(XenRag.Conns) do pcall(function() c:Disconnect() end) end
        XenRag.Conns = {}
        if XenRag.Hum then
            pcall(function() XenRag.Hum.BreakJointsOnDeath = true end)
            pcall(function() XenRag.Hum.RequiresNeck = true end)
            pcall(function() XenRag.Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
            pcall(function() XenRag.Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) end)
            pcall(function() XenRag.Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true) end)
        end
    end
end

-- ANTI SENTRY
local XenSentry = {Enabled=false,Range=250,Busy=false,HitDelayook=0.12}

local functionAt isEnemySentry(o)
(sp    if not (o:,IsA("BasePart") orhr o:IsA("Model")).P then return false end
    local id = o.Name:match("^Sentry_(%d+)$") or o.Name:match("^SentryCandy_(%d+)$")
    return id ~= nil and id ~= tostring(LocalPlayer.UserId)
end
local function sentryPart(s)
    if s:IsA("BasePart") then return s end
    if s:IsA("Model") then return s.PrimaryPart or s:FindFirstChild("HumanoidRootPart") or s:FindFirstChildWhichIsA("BasePart") end
end
local function findBat()
    local c = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    for _, cont in ipairs({c,bp}) do
        if cont then
            local b = cont:FindFirstChild("Bat")
            if b and b:IsA("Tool") then return b end
            for _, t in ipairs(cont:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("bat") or t.Name:lower():find("slap")) then return t end
            end
        end
    end
end
local function equipBat()
    local c, h = getChar()
    if not (c and h) then return nil end
    local b = findBat()
    if not b then return nil end
    if b.Parent ~= c then
        pcall(function() h:EquipTool(b) end)
        local t0 = os.clock()
        while b.Parent ~= c and os.clock()-t0 < 0.4 do RunService.Heartbeat:Wait() end
    end
    return b.Parent == c and b or nil
end

local function killSentry(s)
    if XenSentry.Busy then return end
    XenSentry.Busy = true
    task.spawn(function()
        local p = sentryPart(s)
        if not p then XenSentry.Busy = false return end
        local bat = equipBat()
        if not bat then XenSentry.Busy = false return end
        local lim = os.clock() + 5
        while s.Parent and os.clock() < lim do
            if not XenSentry.Enabled then break end
            local ch, hm, hr = getChar()
            if not (ch and hm and hr) then break end
            if (p.Position-hr.Position).Magnitude > XenSentry.Range then break end
            pcall(function()
                for _, d in ipairs(s:GetDescendants()) do
                    if d:IsA("BasePart") then d.CanCollide = false d.CanTouch = false end
                end
                if p:IsA("BasePart") then p.CanCollide = false p.CanTouch = false end
                local lk = hr.CFrame.LookVector
                local sp = hr.Position + lk * 3
                sp = Vector3.new(sp.X,hr.Position.Y,sp.Z)
                if s:IsA("Model") then s:PivotTo(CFrame.lookAt(sp,hr.Position+lk*8))
                else p.CFrame = CFrame.losition+lk*8) end
                p.AssemblyLinearVelocity = Vector3.zero
            end)
            pcall(function()
                local fl = Vector3.new(p.Position.X,hr.Position.Y,p.Position.Z)
                if (fl-hr.Position).Magnitude > 0.1 then hr.CFrame = CFrame.lookAt(hr.Position,fl) end
            end)
            if bat.Parent == ch then pcall(function() bat:Activate() end)
            else bat = equipBat() if not bat then break end end
            task.wait(XenSentry.HitDelay)
        end
        XenSentry.Busy = false
    end)
end

local function scanSentries()
    if XenSentry.Busy then return end
    local _,_,hr = getChar()
    if not hr then return end
    for _, o in ipairs(Workspace:GetChildren()) do
        if isEnemySentry(o) then
            local p = sentryPart(o)
            if p and (p.Position-hr.Position).Magnitude <= XenSentry.Range then killSentry(o) return end
        end
    end
end

Workspace.ChildAdded:Connect(function(c)
    if not XenSentry.Enabled then return end
    task.delay(0.3,function() if c.Parent and isEnemySentry(c) then killSentry(c) end end)
end)
task.spawn(function() while task.wait(1) do if XenSentry.Enabled then pcall(scanSentries) end end end)

function XenSentry.SetEnabled(v)
    XenSentry.Enabled = v and true or false
    if v then task.defer(scanSentries) end
end

-- ESP BEST BRAINROT
local XenBest = {Enabled=false,Current=nil,LastUpdate=0,Rate=1}
local ANIMALS = {}
pcall(function() ANIMALS = require(ReplicatedStorage.Datas.Animals) end)

local function brValue(m)
    local d = ANIMALS[m.Name]
    if d and d.Generation then return tonumber(d.Generation) or 0 end
    for _, x in ipairs(m:GetDescendants()) do
        if x:IsA("TextLabel") then
            local n, u = x.Text:match("%$([%d%.]+)([KMBT]?)")
            if n then return (tonumber(n) or 0) * (({K=1e3,M=1e6,B=1e9,T=1e12})[u] or 1) end
        end
    end
    return 0
end
local function fmtM(n)
    n = tonumber(n) or 0
    for _, u in ipairs({{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}) do
        if n >= u[1] then
            local v = n/u[1]
            return "$"..(v >= 100 and string.format("%d",v) or string.format("%.1f",v))..u[2].."/s"
        end
    end
    return "$"..math.floor(n).."/s"
end
local function plotOw(p)
    local sg = p and p:FindFirstChild("PlotSign")
    local s = sg and sg:FindFirstChild("SurfaceGui")
    local f = s and s:FindFirstChild("Frame")
    local l = f and f:FindFirstChild("TextLabel")
    return l and l.Text:gsub("'s [Bb]ase$",""):gsub("%s+$","") or "?"
end

local function findBest()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local b, bv = nil, 0
    for _, plot in ipairs(plots:GetChildren()) do
        if isEnemyPlot(plot) then
            for _, o in ipairs(plot:GetChildren()) do
                if o:IsA("Model") and ANIMALS[o.Name] then
                    local v = brValue(o)
                    if v > bv then bv = v b = {model=o,name=o.Name,value=v,owner=plotOw(plot)} end
                end
            end
        end
    end
    return b
end

local bestHL = Instance.new("Highlight")
bestHL.FillColor = C.GOLD
bestHL.OutlineColor = Color3.fromRGB(255,255,100)
bestHL.FillTransparency = 0.5
bestHL.OutlineTransparency = 0
bestHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
bestHL.Enabled = false
bestHL.Parent = gui

local bestBB = Instance.new("BillboardGui")
bestBB.Size = UDim2.fromOffset(220,62)
bestBB.StudsOffset = Vector3.new(0,3,0)
bestBB.AlwaysOnTop = true
bestBB.LightInfluence = 0
bestBB.MaxDistance = 100000
bestBB.Enabled = false
bestBB.Parent = gui

local bf = Instance.new("Frame",bestBB)
bf.Size = UDim2.fromScale(1,1)
bf.BackgroundTransparency = 1
local bt = Instance.new("TextLabel",bf)
bt.Size = UDim2.new(1,0,0,20)
bt.BackgroundTransparency = 1
bt.Text = "BEST"
bt.TextColor3 = C.GOLD
bt.Font = Enum.Font.GothamBlack
bt.TextSize = 18
bt.TextStrokeTransparency = 0.3
local bn = Instance.new("TextLabel",bf)
bn.Size = UDim2.new(1,0,0,16)
bn.Position = UDim2.fromOffset(0,20)
bn.BackgroundTransparency = 1
bn.TextColor3 = Color3.fromRGB(255,255,255)
bn.Font = Enum.Font.GothamBold
bn.TextSize = 14
bn.TextStrokeTransparency = 0.3
local bv = Instance.new("TextLabel",bf)
bv.Size = UDim2.new(1,0,0,14)
bv.Position = UDim2.fromOffset(0,36)
bv.BackgroundTransparency = 1
bv.TextColor3 = Color3.fromRGB(200,255,200)
bv.Font = Enum.Font.Gotham
bv.TextSize = 12
local bo = Instance.new("TextLabel",bf)
bo.Size = UDim2.new(1,0,0,12)
bo.Position = UDim2.fromOffset(0,50)
bo.BackgroundTransparency = 1
bo.TextColor3 = Color3.fromRGB(180,180,220)
bo.Font = Enum.Font.Gotham
bo.TextSize = 11

task.spawn(function()
    while task.wait(0.1) do
        if not XenBest.Enabled then
            bestHL.Enabled = false bestBB.Enabled = false
            continue
        end
        if os.clock()-XenBest.LastUpdate < XenBest.Rate then
            if XenBest.Current and XenBest.Current.model.Parent then
                bestHL.Enabled = true bestBB.Enabled = true
            end
            continue
        end
        XenBest.LastUpdate = os.clock()
        local b = findBest()
        if b then
            bestHL.Adornee = b.model
            bestHL.Enabled = true
            local ad = b.model.PrimaryPart or b.model:FindFirstChildWhichIsA("BasePart")
            if ad then bestBB.Adornee = ad bestBB.Enabled = true end
            bn.Text = b.name
            bv.Text = fmtM(b.value)
            bo.Text = "Owner: "..b.owner
            XenBest.Current = b
        else
            bestHL.Enabled = false bestBB.Enabled = false
            XenBest.Current = nil
        end
    end
end)

function XenBest.SetEnabled(v)
    XenBest.Enabled = v and true or false
    if not v then bestHL.Enabled = false bestBB.Enabled = false XenBest.Current = nil end
end

-- UI PRINCIPALE
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.fromOffset(50,50)
floatBtn.Position = UDim2.new(0,20,0.5,-25)
floatBtn.BackgroundColor3 = C.ACCENT
floatBtn.Text = "X"
floatBtn.TextColor3 = C.TEXT
floatBtn.Font = Enum.Font.GothamBlack
floatBtn.TextSize = 22
floatBtn.AutoButtonColor = false
floatBtn.Parent = gui
Instance.new("UICorner",floatBtn).CornerRadius = UDim.new(0,25)

local dg, dgi, dgs, dgp = false, nil, nil, nil
floatBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dg, dgi, dgs, dgp = true, i, i.Position, floatBtn.Position
    end
end)
floatBtn.InputEnded:Connect(function(i) if i == dgi then dg = false end end)
UserInputService.InputChanged:Connect(function(i)
    if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i == dgi) then
        local dd = i.Position - dgs
        floatBtn.Position = UDim2.new(dgp.X.Scale, dgp.X.Offset+dd.X, dgp.Y.Scale, dgp.Y.Offset+dd.Y)
    end
end)

local main = Instance.new("Frame")
main.Size = IsMobile and UDim2.fromOffset(360,300) or UDim2.fromOffset(700,420)
main.Position = UDim2.new(0.5,-(IsMobile and 180 or 350),0.5,-(IsMobile and 150 or 210))
main.BackgroundColor3 = C.BG
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui
Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)
Instance.new("UIStroke",main).Color = C.SURFACE2

local title = Instance.new("Frame",main)
title.Size = UDim2.new(1,0,0,34)
title.BackgroundColor3 = C.SURFACE
title.BorderSizePixel = 0
Instance.new("UICorner",title).CornerRadius = UDim.new(0,12)

local titleLbl = Instance.new("TextLabel",title)
titleLbl.Size = UDim2.new(1,-80,1,0)
titleLbl.Position = UDim2.fromOffset(16,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "XEN HUB v1.0"
titleLbl.TextColor3 = C.ACCENT
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 15
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton",title)
close.Size = UDim2.fromOffset(24,24)
close.Position = UDim2.new(1,-30,0.5,-12)
close.BackgroundColor3 = C.OFF
close.Text = "X"
close.TextColor3 = C.TEXT
close.Font = Enum.Font.GothamBold
close.TextSize = 12
close.AutoButtonColor = false
Instance.new("UICorner",close).CornerRadius = UDim.new(0,6)
close.MouseButton1Click:Connect(function() main.Visible = false end)

floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

local dw, dwi, dws, dwp = false, nil, nil, nil
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dw, dwi, dws, dwp = true, i, i.Position, main.Position
    end
end)
title.InputEnded:Connect(function(i) if i == dwi then dw = false end end)
UserInputService.InputChanged:Connect(function(i)
    if dw and (i.UserInputType == Enum.UserInputType.MouseMovement or i == dwi) then
        local dd = i.Position - dws
        main.Position = UDim2.new(dwp.X.Scale, dwp.X.Offset+dd.X, dwp.Y.Scale, dwp.Y.Offset+dd.Y)
    end
end)

local sideW = IsMobile and 100 or 140
local sidebar = Instance.new("Frame",main)
sidebar.Size = UDim2.new(0,sideW,1,-46)
sidebar.Position = UDim2.fromOffset(8,42)
sidebar.BackgroundColor3 = C.SURFACE
sidebar.BorderSizePixel = 0
Instance.new("UICorner",sidebar).CornerRadius = UDim.new(0,10)
local ll = Instance.new("UIListLayout",sidebar)
ll.Padding = UDim.new(0,3)
ll.SortOrder = Enum.SortOrder.LayoutOrder
local pd = Instance.new("UIPadding",sidebar)
pd.PaddingTop = UDim.new(0,5)
pd.PaddingBottom = UDim.new(0,5)
pd.PaddingLeft = UDim.new(0,5)
pd.PaddingRight = UDim.new(0,5)

local pageHolder = Instance.new("Frame",main)
pageHolder.Size = UDim2.new(1,-(sideW+16),1,-46)
pageHolder.Position = UDim2.fromOffset(sideW+16,42)
pageHolder.BackgroundTransparency = 1

local Tabs, Pages, CurrentTab = {}, {}, nil

local function createTab(name, order)
    local btn = Instance.new("TextButton",sidebar)
    btn.Size = UDim2.new(1,0,0,IsMobile and 32 or 36)
    btn.BackgroundColor3 = C.SURFACE
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = C.DIM
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = IsMobile and 11 or 13
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)

    local ind = Instance.new("Frame",btn)
    ind.Size = UDim2.new(0,3,0.6,0)
    ind.Position = UDim2.new(0,0,0.2,0)
    ind.BackgroundColor3 = C.ACCENT
    ind.BorderSizePixel = 0
    ind.Visible = false
    Instance.new("UICorner",ind).CornerRadius = UDim.new(0,2)

    local page = Instance.new("ScrollingFrame",pageHolder)
    page.Size = UDim2.fromScale(1,1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new()
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.ACCENT
    page.Visible = false
    local pl = Instance.new("UIListLayout",page)
    pl.Padding = UDim.new(0,5)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    local pp = Instance.new("UIPadding",page)
    pp.PaddingTop = UDim.new(0,6)
    pp.PaddingBottom = UDim.new(0,6)
    pp.PaddingLeft = UDim.new(0,4)
    pp.PaddingRight = UDim.new(0,6)

    Tabs[name] = {btn=btn,ind=ind,page=page}
    Pages[name] = page

    btn.MouseButton1Click:Connect(function()
        if CurrentTab == name then return end
        for n, t in pairs(Tabs) do
            t.ind.Visible = (n == name)
            t.page.Visible = (n == name)
            t.btn.TextColor3 = (n == name) and C.ACCENT or C.DIM
            t.btn.BackgroundColor3 = (n == name) and C.SURFACE2 or C.SURFACE
        end
        CurrentTab = name
    end)
end

createTab("Joueur",1)
createTab("Anti",2)
createTab("Voler",3)
createTab("Helper",4)
createTab("Credits",5)

local function makeToggle(parent, label, initialState, callback)
    local row = Instance.new("Frame",parent)
    row.Size = UDim2.new(1,0,0,IsMobile and 38 or 42)
    row.BackgroundColor3 = C.SURFACE
    row.BorderSizePixel = 0
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,10)

    local lbl = Instance.new("TextLabel",row)
    lbl.Size = UDim2.new(1,-60,1,0)
    lbl.Position = UDim2.fromOffset(12,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.TEXT
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = IsMobile and 11 or 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd

    local state = initialState
    local sw = Instance.new("Frame",row)
    sw.Size = UDim2.fromOffset(40,20)
    sw.Position = UDim2.new(1,-50,0.5,-10)
    sw.BackgroundColor3 = state and C.ACCENT or C.OFF
    sw.BorderSizePixel = 0
    Instance.new("UICorner",sw).CornerRadius = UDim.new(0,10)

    local kn = Instance.new("Frame",sw)
    kn.Size = UDim2.fromOffset(16,16)
    kn.Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    kn.BackgroundColor3 = C.TEXT
    kn.BorderSizePixel = 0
    Instance.new("UICorner",kn).CornerRadius = UDim.new(0,8)

    local hit = Instance.new("TextButton",row)
    hit.Size = UDim2.fromScale(1,1)
    hit.BackgroundTransparency = 1
    hit.Text = ""

    hit.MouseButton1Click:Connect(function()
        state = not state
        sw.BackgroundColor3 = state and C.ACCENT or C.OFF
        kn.Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
        if callback then pcall(callback,state) end
    end)
end

makeToggle(Pages["Joueur"],"Carpet Speed",false,function(v) XenCarpet.SetEnabled(v) end)
makeToggle(Pages["Joueur"],"Infinite Jump",false,function(v) end)
makeToggle(Pages["Joueur"],"Instant Reset",false,function(v) end)
makeToggle(Pages["Anti"],"Anti Ragdoll",false,function(v) XenRag.SetEnabled(v) end)
makeToggle(Pages["Anti"],"Anti Sentry",false,function(v) XenSentry.SetEnabled(v) end)
makeToggle(Pages["Voler"],"Auto Grab",false,function(v) XenGrab.SetEnabled(v) end)
makeToggle(Pages["Voler"],"Ignore Locked",false,function(v) XenGrab.IgnoreLocked = v end)
makeToggle(Pages["Voler"],"Auto Invisible",false,function(v) XenInvis.SetEnabled(v) end)
makeToggle(Pages["Helper"],"ESP Best Brainrot",false,function(v) XenBest.SetEnabled(v) end)

CurrentTab = "Voler"
Tabs["Voler"].ind.Visible = true
Tabs["Voler"].page.Visible = true
Tabs["Voler"].btn.TextColor3 = C.ACCENT
Tabs["Voler"].btn.BackgroundColor3 = C.SURFACE2

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible end
end)

_G.XenHub = {Grab=XenGrab,Invis=XenInvis,Carpet=XenCarpet,Rag=XenRag,Sentry=XenSentry,Best=XenBest}

print("[Xen] CHARGE")
