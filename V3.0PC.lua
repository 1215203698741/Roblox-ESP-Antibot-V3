--===========================================================================================
-- Antibot + ESP v3.0 PC版（灵动岛菜单版，热键支持鼠标+红线无残留）
-- 功能：自瞄+ESP+夜视+热能透视+ESP2
-- 灵动岛位置：屏幕顶部，动画完整，目标延伸稳定
-- 热键设置提示：设置鼠标左/右键时，请在按下任意键后点击菜单UI空白区域
--===========================================================================================

local AimConfig = {
    fovsize = 50,
    fovlookAt = false,
    fovcolorFixed = Color3.fromRGB(0, 255, 0),
    fovcolorMode = "固定",
    textColorFixed = Color3.fromRGB(255, 255, 255),
    textColorMode = "固定",
    lineColorFixed = Color3.fromRGB(255, 0, 0),
    lineColorMode = "固定",
    espBoxColorFixed = Color3.fromRGB(255, 255, 255),
    espBoxColorMode = "固定",
    espTracerColorFixed = Color3.fromRGB(255, 0, 0),
    espTracerColorMode = "固定",
    espHeadCircleColorFixed = Color3.fromRGB(0, 255, 0),
    espHeadCircleColorMode = "固定",
    colorSpeed = 2.0,
    fovthickness = 2,
    distance = 200,
    Transparency = 5,
    teamCheck = false,
    wallCheck = false,
    aliveCheck = false,
    prejudgingselfsighting = false,
    prejudgingselfsightingdistance = 100,
    smoothness = 5,
    aimSpeed = 5,
    priorityMode = "Smart",
    aimMode = "AI",
    aimModeType = "普通",
    autoFire = false,
    fireRate = 10,
    dynamicFOV = false,
    dynamicFOVScale = 1.5,
    threatPriority = false,
    healthPriority = false,
    -- 热键配置
    aimActivationMode = "自动",   -- "自动", "按住热键", "单击切换"
    aimHotkey = Enum.KeyCode.LeftControl,
    hotkeyToggleState = false,
}

-- 热键运行时状态
local hotkeyPressed = false

local ESPConfig = {
    enabled = false,
    showBox = false,
    showHealth = false,
    showName = false,
    showDistance = false,
    showTracer = false,
    showHeadCircle = false,
    teamCheck = false,
}

local ParticleConfig = {
    shape = "圆形",
    count = 12,
    size = 10,
    colorFixed = Color3.fromRGB(255, 200, 100),
    colorMode = "固定",
}

local PanelConfig = {
    enabled = true,
    dynamicIslandEnabled = true,
}

-- 夜视配置
local NightVision = {
    enabled = false,
    originalSettings = nil,
    connection = nil,
}

-- 热能透视配置
local ThermalESP = {
    enabled = false,
    color = Color3.fromRGB(255, 0, 0),
    colorMode = "固定",
    highlights = {},
}

-- ==================== ESP2 配置（GIT风格，独立） ====================
local ESP2_Settings = {
    Enabled = false,
    ShowBox = true,
    ShowName = true,
    ShowHealth = true,
    ShowChams = true,
    TeamCheck = true,
    MaxDistance = 5000,
    BoxColor = Color3.fromRGB(255, 255, 255),
    BoxColorMode = "固定",
    NameColor = Color3.fromRGB(255, 255, 255),
    NameColorMode = "固定",
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    HealthBarColorMode = "固定",
}

-- ESP2 内部变量
local ESP2 = {
    ScreenGui = nil,
    PlayerElements = {},
    Connections = {},
    RenderConnection = nil,
    FontSize = 11,
}

-- ==================== 以下为原有功能代码（自瞄、原ESP、夜视、热能等） ====================
local TextSize = 16
local BodyPartDisplay = {"头部", "躯干", "左臂", "右臂", "左腿", "右腿"}
local currentBodyPart = "头部"

local ColorPresets = {"红色", "绿色", "蓝色", "黄色", "青色", "紫色", "橙色", "白色"}
local ColorValues = {
    ["红色"] = Color3.fromRGB(255, 0, 0),
    ["绿色"] = Color3.fromRGB(0, 255, 0),
    ["蓝色"] = Color3.fromRGB(0, 0, 255),
    ["黄色"] = Color3.fromRGB(255, 255, 0),
    ["青色"] = Color3.fromRGB(0, 255, 255),
    ["紫色"] = Color3.fromRGB(128, 0, 128),
    ["橙色"] = Color3.fromRGB(255, 165, 0),
    ["白色"] = Color3.fromRGB(255, 255, 255),
}
local DynamicModes = {"循环色相", "瀑布", "波浪"}
local ParticleShapes = {"圆形", "爱心", "🩸"}
local heartSymbols = {
    "❤", "🧡", "💛", "💚", "💙", "💜", "🤎", "🖤", "💔", "❣",
    "💕", "💞", "💓", "💗", "💖", "💝", "💘", "💟", "💥", "💦", "💫"
}

local function safeClamp(value, minVal, maxVal)
    if minVal > maxVal then minVal, maxVal = maxVal, minVal end
    return math.clamp(value, minVal, maxVal)
end

local function getDynamicColor(mode)
    local t = tick() * AimConfig.colorSpeed
    if mode == "循环色相" then
        local hue = (t % 2) / 2
        return Color3.fromHSV(hue, 1, 1)
    elseif mode == "瀑布" then
        local hue = (t % 2) / 2
        local brightness = (math.sin(t * 2) + 1) / 2
        return Color3.fromHSV(hue, 1, brightness)
    elseif mode == "波浪" then
        local r = (math.sin(t * 1.3) + 1) / 2
        local g = (math.sin(t * 1.7 + 2) + 1) / 2
        local b = (math.sin(t * 2.1 + 4) + 1) / 2
        return Color3.new(r, g, b)
    end
    return Color3.fromHSV(0, 1, 1)
end

local function getCurrentColor(mode, fixedColor)
    if mode == "固定" then return fixedColor end
    return getDynamicColor(mode)
end

local function getParticleColor()
    if ParticleConfig.colorMode == "固定" then
        return ParticleConfig.colorFixed
    else
        return getDynamicColor(ParticleConfig.colorMode)
    end
end

local function IsSameTeam(player)
    return player.Team == game.Players.LocalPlayer.Team
end

local function IsAlive(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function getTargetPart(character)
    if not character then return nil end
    if currentBodyPart == "头部" then return character:FindFirstChild("Head") end
    if currentBodyPart == "躯干" then return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") end
    if currentBodyPart == "左臂" then return character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm") end
    if currentBodyPart == "右臂" then return character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm") end
    if currentBodyPart == "左腿" then return character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg") end
    if currentBodyPart == "右腿" then return character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg") end
    return nil
end

local function CheckWall(player, targetPart)
    if not AimConfig.wallCheck then return true end
    local localChar = game.Players.LocalPlayer.Character
    if not localChar or not targetPart then return false end
    local ray = Ray.new(workspace.CurrentCamera.CFrame.Position, targetPart.Position - workspace.CurrentCamera.CFrame.Position)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {localChar})
    return hit and hit:IsDescendantOf(player.Character) or not hit
end

local function PredictPosition(part)
    return part.Position + part.AssemblyLinearVelocity * ((part.Position - workspace.CurrentCamera.CFrame.Position)).Magnitude / 1000
end

local function IsInFOV(position)
    local camera = workspace.CurrentCamera
    local vp = camera:WorldToViewportPoint(position)
    return (Vector2.new(vp.X, vp.Y) - camera.ViewportSize / 2).Magnitude <= AimConfig.fovsize
end

local function GetBestTarget()
    local bestScore = -math.huge
    local bestTarget = nil
    local localPlayer = game.Players.LocalPlayer
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            local skip = false
            if AimConfig.aliveCheck and not IsAlive(player) then skip = true end
            if not skip and AimConfig.teamCheck and IsSameTeam(player) then skip = true end
            if not skip then
                local targetPart = getTargetPart(player.Character)
                if targetPart then
                    local dist = (targetPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                    if dist <= AimConfig.distance then
                        local speed = targetPart.AssemblyLinearVelocity.Magnitude
                        local camera = workspace.CurrentCamera
                        local screenPoint, isVisible = camera:WorldToViewportPoint(targetPart.Position)
                        local crossDist = math.huge
                        if isVisible and screenPoint then
                            crossDist = (Vector2.new(screenPoint.X, screenPoint.Y) - camera.ViewportSize / 2).Magnitude
                        end
                        local priority = 0
                        if AimConfig.priorityMode == "Distance" then
                            priority = -dist
                        elseif AimConfig.priorityMode == "Crosshair" then
                            priority = -crossDist
                        elseif AimConfig.priorityMode == "Speed" then
                            priority = speed
                        elseif AimConfig.priorityMode == "Smart" then
                            priority = -dist*0.5 + speed*0.3 - crossDist*0.2
                        end
                        if AimConfig.threatPriority then
                            priority = priority * (player:GetAttribute("ThreatLevel") or 1)
                        end
                        if AimConfig.healthPriority then
                            priority = priority * (1 / player.Character.Humanoid.Health)
                        end
                        if bestScore < priority and (not AimConfig.wallCheck or CheckWall(player, targetPart)) then
                            bestScore = priority
                            bestTarget = player
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- 自瞄绘图对象（电脑端 Drawing）
local AimFOVCircle, AimFOVLine1, AimFOVLine2, AimRedLine = nil, nil, nil, nil
local AimTextDrawings = {}
local showFOVCircleFlag = false

local function InitAimFOV(radius, color, thickness, transparency)
    local Camera = workspace.CurrentCamera
    if AimFOVCircle then AimFOVCircle:Remove() end
    if AimFOVLine2 then AimFOVLine2:Remove() end
    AimFOVCircle = Drawing.new("Circle")
    AimFOVCircle.Visible = showFOVCircleFlag
    AimFOVCircle.Thickness = thickness
    AimFOVCircle.Color = color
    AimFOVCircle.Filled = false
    AimFOVCircle.Radius = radius
    AimFOVCircle.Position = Camera.ViewportSize / 2
    AimFOVCircle.Transparency = transparency
    AimFOVLine2 = Drawing.new("Line")
    AimFOVLine2.Visible = true
    AimFOVLine2.Thickness = 1
    AimFOVLine2.Color = Color3.fromRGB(255, 255, 255)
    AimFOVLine2.Transparency = 1
    if not AimFOVLine1 then
        AimFOVLine1 = Drawing.new("Line")
        AimFOVLine1.Visible = false
        AimFOVLine1.Thickness = 2
        AimFOVLine1.Color = Color3.fromRGB(255, 0, 0)
        AimFOVLine1.Transparency = 1
    end
    if not AimRedLine then
        AimRedLine = Drawing.new("Line")
        AimRedLine.Visible = false
        AimRedLine.Thickness = 2
        AimRedLine.Color = getCurrentColor(AimConfig.lineColorMode, AimConfig.lineColorFixed)
        AimRedLine.Transparency = 0.5
    end
    local function UpdateFOVDisplay()
        local vs = Camera.ViewportSize
        if AimFOVCircle then
            AimFOVCircle.Position = vs/2
            AimFOVCircle.Radius = AimConfig.fovsize
        end
        if AimFOVLine2 then
            AimFOVLine2.From = Vector2.new(vs.X/2-5, vs.Y/2)
            AimFOVLine2.To = Vector2.new(vs.X/2+5, vs.Y/2)
            AimFOVLine2.From = Vector2.new(vs.X/2, vs.Y/2-5)
            AimFOVLine2.To = Vector2.new(vs.X/2, vs.Y/2+5)
        end
    end
    game:GetService("RunService").RenderStepped:Connect(UpdateFOVDisplay)
end

local function SetFOVCircleVisible(visible)
    showFOVCircleFlag = visible
    if AimFOVCircle then AimFOVCircle.Visible = visible end
end

local function ClearAimTextDrawings()
    for _, t in pairs(AimTextDrawings) do
        if t.drawing then t.drawing:Remove() end
    end
    AimTextDrawings = {}
end

local function UpdateAimFOVTargetsInfo()
    if not AimFOVCircle or not AimConfig.fovlookAt then
        ClearAimTextDrawings()
        return
    end
    local camera = workspace.CurrentCamera
    local center = camera.ViewportSize / 2
    local fovR = AimFOVCircle.Radius
    local targets = {}
    local lp = game.Players.LocalPlayer
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= lp then
            local skip = false
            if AimConfig.aliveCheck and not IsAlive(p) then skip = true end
            if not skip and AimConfig.teamCheck and IsSameTeam(p) then skip = true end
            if not skip then
                local part = getTargetPart(p.Character)
                if part then
                    local sp, on = camera:WorldToViewportPoint(part.Position)
                    if on then
                        local distToCenter = (Vector2.new(sp.X,sp.Y)-center).Magnitude
                        if distToCenter <= fovR and (not AimConfig.wallCheck or CheckWall(p, part)) then
                            table.insert(targets, {p=p, pos=Vector2.new(sp.X,sp.Y)})
                        end
                    end
                end
            end
        end
    end
    for i, t in pairs(AimTextDrawings) do
        local keep = false
        for _, tt in ipairs(targets) do
            if tt.p == t.p then keep = true; break end
        end
        if not keep then
            if t.drawing then t.drawing:Remove() end
            AimTextDrawings[i] = nil
        end
    end
    for _, info in ipairs(targets) do
        local hum = info.p.Character and info.p.Character:FindFirstChild("Humanoid")
        local hp = hum and math.floor(hum.Health) or 0
        local name = info.p.DisplayName or info.p.Name
        local existing = nil
        for _, t in pairs(AimTextDrawings) do
            if t.p == info.p then existing = t.drawing; break end
        end
        if not existing then
            local nt = Drawing.new("Text")
            nt.Size = TextSize
            nt.Center = true
            nt.Outline = true
            nt.OutlineColor = Color3.new(0,0,0)
            nt.Color = getCurrentColor(AimConfig.textColorMode, AimConfig.textColorFixed)
            nt.Visible = true
            table.insert(AimTextDrawings, {p=info.p, drawing=nt})
            existing = nt
        end
        existing.Text = name.."  ["..hp.." HP]"
        existing.Position = Vector2.new(info.pos.X, info.pos.Y-40)
        if AimConfig.textColorMode == "固定" then
            existing.Color = AimConfig.textColorFixed
        end
    end
end

local function UpdateAimLockLine()
    if not AimConfig.fovlookAt or not AimRedLine then
        if AimRedLine then AimRedLine.Visible = false end
        return
    end
    local target = GetBestTarget()
    if target and target.Character then
        local part = getTargetPart(target.Character)
        if part then
            local sp, on = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
            if on then
                AimRedLine.From = workspace.CurrentCamera.ViewportSize / 2
                AimRedLine.To = Vector2.new(sp.X, sp.Y)
                AimRedLine.Visible = true
                return
            end
        end
    end
    AimRedLine.Visible = false
end

local function AimAI()
    local target = GetBestTarget()
    if target and target.Character then
        local part = getTargetPart(target.Character)
        if part then
            local pos = part.Position
            if IsInFOV(pos) then
                if AimConfig.prejudgingselfsighting then
                    local dist = (pos - workspace.CurrentCamera.CFrame.Position).Magnitude
                    if dist <= AimConfig.prejudgingselfsightingdistance then
                        pos = PredictPosition(part)
                    end
                end
                if AimConfig.aimModeType == "强锁" then
                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, pos)
                else
                    local alpha = math.clamp((AimConfig.aimSpeed / 10) * (1 / AimConfig.smoothness), 0.02, 0.8)
                    local cur = workspace.CurrentCamera.CFrame
                    local targetCF = CFrame.new(cur.Position, pos)
                    workspace.CurrentCamera.CFrame = cur:Lerp(targetCF, alpha)
                end
                if AimFOVLine1 then
                    local vp = workspace.CurrentCamera:WorldToViewportPoint(pos)
                    AimFOVLine1.From = workspace.CurrentCamera.ViewportSize/2
                    AimFOVLine1.To = Vector2.new(vp.X, vp.Y)
                    AimFOVLine1.Visible = true
                end
                if AimConfig.autoFire then
                    local char = game.Players.LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then
                            local now = tick()
                            local lastFire = tool:GetAttribute("LastFireTime") or 0
                            if (now - lastFire) >= (1 / AimConfig.fireRate) then
                                local fired = false
                                local events = {"Fire", "Shoot", "Click", "Attack", "Activate", "RemoteEvent"}
                                for _, evName in ipairs(events) do
                                    local ev = tool:FindFirstChild(evName)
                                    if ev and ev:IsA("RemoteEvent") then
                                        ev:FireServer()
                                        fired = true
                                        break
                                    end
                                end
                                if not fired then pcall(function() tool:Activate() end) end
                                tool:SetAttribute("LastFireTime", now)
                            end
                        end
                    end
                end
            elseif AimFOVLine1 then
                AimFOVLine1.Visible = false
            end
        elseif AimFOVLine1 then
            AimFOVLine1.Visible = false
        end
    elseif AimFOVLine1 then
        AimFOVLine1.Visible = false
    end
end

local function AimFunction()
    local target = GetBestTarget()
    if target and target.Character then
        local part = getTargetPart(target.Character)
        if part then
            local pos = part.Position
            if IsInFOV(pos) then
                local predicted = pos
                if AimConfig.prejudgingselfsighting then
                    local dist = (pos - workspace.CurrentCamera.CFrame.Position).Magnitude
                    if dist <= AimConfig.prejudgingselfsightingdistance then
                        local time = (part.Position - workspace.CurrentCamera.CFrame.Position).Magnitude / 1000
                        predicted = pos + part.AssemblyLinearVelocity * time + 0.5 * Vector3.new(0, -workspace.Gravity, 0) * time^2
                    end
                end
                if AimConfig.aimModeType == "强锁" then
                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, predicted)
                else
                    local alpha = math.clamp((AimConfig.aimSpeed / 10) * (1 / AimConfig.smoothness), 0.02, 0.8)
                    local cur = workspace.CurrentCamera.CFrame
                    local targetCF = CFrame.new(cur.Position, predicted)
                    workspace.CurrentCamera.CFrame = cur:Lerp(targetCF, alpha)
                end
                if AimFOVLine1 then
                    local vp = workspace.CurrentCamera:WorldToViewportPoint(predicted)
                    AimFOVLine1.From = workspace.CurrentCamera.ViewportSize/2
                    AimFOVLine1.To = Vector2.new(vp.X, vp.Y)
                    AimFOVLine1.Visible = true
                end
                if AimConfig.autoFire then
                    local char = game.Players.LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then
                            local now = tick()
                            local lastFire = tool:GetAttribute("LastFireTime") or 0
                            if (now - lastFire) >= (1 / AimConfig.fireRate) then
                                local fired = false
                                local events = {"Fire", "Shoot", "Click", "Attack", "Activate", "RemoteEvent"}
                                for _, evName in ipairs(events) do
                                    local ev = tool:FindFirstChild(evName)
                                    if ev and ev:IsA("RemoteEvent") then
                                        ev:FireServer()
                                        fired = true
                                        break
                                    end
                                end
                                if not fired then pcall(function() tool:Activate() end) end
                                tool:SetAttribute("LastFireTime", now)
                            end
                        end
                    end
                end
            elseif AimFOVLine1 then
                AimFOVLine1.Visible = false
            end
        elseif AimFOVLine1 then
            AimFOVLine1.Visible = false
        end
    elseif AimFOVLine1 then
        AimFOVLine1.Visible = false
    end
end

-- ==================== 原ESP（Drawing） ====================
local ESPDrawings = {}

local function CreateESPForPlayer(player)
    if player == game.Players.LocalPlayer then return end
    local d = {
        box = Drawing.new("Square"),
        health = Drawing.new("Text"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        tracer = Drawing.new("Line"),
        headCircle = Drawing.new("Circle")
    }
    d.box.Visible = false; d.box.Thickness = 1; d.box.Filled = false
    d.health.Visible = false; d.health.Size = 14; d.health.Center = true; d.health.Outline = true; d.health.OutlineColor = Color3.new(0,0,0)
    d.name.Visible = false; d.name.Size = 14; d.name.Center = true; d.name.Outline = true; d.name.OutlineColor = Color3.new(0,0,0)
    d.distance.Visible = false; d.distance.Size = 12; d.distance.Center = true; d.distance.Outline = true; d.distance.OutlineColor = Color3.new(0,0,0)
    d.tracer.Visible = false; d.tracer.Thickness = 1
    d.headCircle.Visible = false; d.headCircle.Thickness = 2; d.headCircle.Filled = false
    ESPDrawings[player] = d
end

local function DestroyESPForPlayer(player)
    local d = ESPDrawings[player]
    if d then
        if d.box then d.box:Remove() end
        if d.health then d.health:Remove() end
        if d.name then d.name:Remove() end
        if d.distance then d.distance:Remove() end
        if d.tracer then d.tracer:Remove() end
        if d.headCircle then d.headCircle:Remove() end
        ESPDrawings[player] = nil
    end
end

local function getFootPosition(char)
    local footNames = {"LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftLeg", "RightLeg"}
    for _, name in ipairs(footNames) do
        local foot = char:FindFirstChild(name)
        if foot then return foot.Position end
    end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if head and hrp then
        local height = (head.Position.Y - hrp.Position.Y) * 1.5
        return hrp.Position - Vector3.new(0, height, 0)
    end
    if hrp then return hrp.Position - Vector3.new(0, 3, 0) end
    return Vector3.new(0,0,0)
end

local function UpdateESP()
    if not ESPConfig.enabled then
        for p, _ in pairs(ESPDrawings) do DestroyESPForPlayer(p) end
        return
    end
    local cam = workspace.CurrentCamera
    local lp = game.Players.LocalPlayer
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= lp then
            if not ESPDrawings[p] then CreateESPForPlayer(p) end
            local d = ESPDrawings[p]
            if not d then continue end
            local char = p.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local head = char and char:FindFirstChild("Head")
            local shouldRender = false
            if char and hum and hum.Health > 0 and head then
                if (not ESPConfig.teamCheck or not IsSameTeam(p)) then
                    local headPos, headOn = cam:WorldToViewportPoint(head.Position)
                    if headOn then
                        local footWorld = getFootPosition(char)
                        local footPos, footOn = cam:WorldToViewportPoint(footWorld)
                        if not footOn then footPos = Vector3.new(headPos.X, headPos.Y + 2, headPos.Z) end
                        local topY = headPos.Y
                        local bottomY = footPos.Y
                        local boxHeight = math.abs(topY - bottomY)
                        local boxWidth = boxHeight * 0.5
                        local boxPos = Vector2.new(headPos.X - boxWidth/2, topY)
                        local boxCol = getCurrentColor(AimConfig.espBoxColorMode, AimConfig.espBoxColorFixed)
                        local tracerCol = getCurrentColor(AimConfig.espTracerColorMode, AimConfig.espTracerColorFixed)
                        local headCircleCol = getCurrentColor(AimConfig.espHeadCircleColorMode, AimConfig.espHeadCircleColorFixed)
                        if ESPConfig.showBox then
                            d.box.Size = Vector2.new(boxWidth, boxHeight)
                            d.box.Position = boxPos
                            d.box.Color = boxCol
                            d.box.Visible = true
                        else
                            d.box.Visible = false
                        end
                        if ESPConfig.showHeadCircle then
                            local headSize = head.Size
                            local rightPos = head.Position + Vector3.new(headSize.X/2, 0, 0)
                            local topPos = head.Position + Vector3.new(0, headSize.Y/2, 0)
                            local rightScreen, _ = cam:WorldToViewportPoint(rightPos)
                            local topScreen, _ = cam:WorldToViewportPoint(topPos)
                            local radiusX = math.abs(rightScreen.X - headPos.X)
                            local radiusY = math.abs(topScreen.Y - headPos.Y)
                            local radius = (radiusX + radiusY) / 2
                            radius = safeClamp(radius, 8, 50)
                            d.headCircle.Radius = radius
                            d.headCircle.Position = Vector2.new(headPos.X, headPos.Y)
                            d.headCircle.Color = headCircleCol
                            d.headCircle.Visible = true
                        else
                            d.headCircle.Visible = false
                        end
                        if ESPConfig.showHealth then
                            d.health.Position = Vector2.new(headPos.X, headPos.Y - boxHeight/2 - 20)
                            d.health.Text = "❤ " .. math.floor(hum.Health)
                            d.health.Color = Color3.fromRGB(255,80,80)
                            d.health.Visible = true
                        else
                            d.health.Visible = false
                        end
                        if ESPConfig.showName then
                            d.name.Position = Vector2.new(headPos.X, headPos.Y - boxHeight/2 - 40)
                            d.name.Text = p.Name
                            d.name.Color = Color3.new(1,1,1)
                            d.name.Visible = true
                        else
                            d.name.Visible = false
                        end
                        if ESPConfig.showDistance then
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            local dist = 0
                            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and hrp then
                                dist = (lp.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                            end
                            d.distance.Position = Vector2.new(headPos.X, headPos.Y + boxHeight/2 + 20)
                            d.distance.Text = math.floor(dist) .. "m"
                            d.distance.Color = Color3.fromRGB(255,255,100)
                            d.distance.Visible = true
                        else
                            d.distance.Visible = false
                        end
                        if ESPConfig.showTracer then
                            d.tracer.From = cam.ViewportSize/2
                            d.tracer.To = Vector2.new(headPos.X, headPos.Y)
                            d.tracer.Color = tracerCol
                            d.tracer.Visible = true
                        else
                            d.tracer.Visible = false
                        end
                        shouldRender = true
                    end
                end
            end
            if not shouldRender then
                if d.box then d.box.Visible = false end
                if d.health then d.health.Visible = false end
                if d.name then d.name.Visible = false end
                if d.distance then d.distance.Visible = false end
                if d.tracer then d.tracer.Visible = false end
                if d.headCircle then d.headCircle.Visible = false end
            end
        end
    end
    for p, _ in pairs(ESPDrawings) do
        if not game.Players:FindFirstChild(p.Name) then
            DestroyESPForPlayer(p)
        end
    end
end

local function refreshAllColors()
    if AimFOVCircle then
        AimFOVCircle.Color = getCurrentColor(AimConfig.fovcolorMode, AimConfig.fovcolorFixed)
    end
    if AimRedLine then
        AimRedLine.Color = getCurrentColor(AimConfig.lineColorMode, AimConfig.lineColorFixed)
    end
    for _, t in pairs(AimTextDrawings) do
        if t.drawing then
            t.drawing.Color = getCurrentColor(AimConfig.textColorMode, AimConfig.textColorFixed)
        end
    end
    for _, d in pairs(ESPDrawings) do
        if d.box and ESPConfig.showBox then
            d.box.Color = getCurrentColor(AimConfig.espBoxColorMode, AimConfig.espBoxColorFixed)
        end
        if d.tracer and ESPConfig.showTracer then
            d.tracer.Color = getCurrentColor(AimConfig.espTracerColorMode, AimConfig.espTracerColorFixed)
        end
        if d.headCircle and ESPConfig.showHeadCircle then
            d.headCircle.Color = getCurrentColor(AimConfig.espHeadCircleColorMode, AimConfig.espHeadCircleColorFixed)
        end
    end
end

-- ==================== 夜视功能 ====================
local Lighting = game:GetService("Lighting")
local function SaveOriginalLighting()
    if NightVision.originalSettings then return end
    NightVision.originalSettings = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        ClockTime = Lighting.ClockTime,
    }
end

local function ApplyNightVision()
    Lighting.Brightness = 3
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
    Lighting.FogColor = Color3.new(0,0,0)
    Lighting.FogEnd = 1e9
    Lighting.GlobalShadows = false
    Lighting.ClockTime = 12
end

local function RestoreLighting()
    if NightVision.originalSettings then
        for k, v in pairs(NightVision.originalSettings) do
            Lighting[k] = v
        end
    end
end

local function StartNightVision()
    if NightVision.connection then NightVision.connection:Disconnect() end
    SaveOriginalLighting()
    ApplyNightVision()
    NightVision.connection = game:GetService("RunService").Heartbeat:Connect(function()
        if Lighting.Brightness ~= 3 or Lighting.Ambient ~= Color3.new(1,1,1) then
            ApplyNightVision()
        end
    end)
end

local function StopNightVision()
    if NightVision.connection then
        NightVision.connection:Disconnect()
        NightVision.connection = nil
    end
    RestoreLighting()
end

-- ==================== 热能透视 ====================
local function UpdateThermalESP()
    local lp = game.Players.LocalPlayer
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp then
            local char = player.Character
            if char then
                local highlight = ThermalESP.highlights[player]
                if ThermalESP.enabled then
                    local shouldShow = (not ESPConfig.teamCheck or not IsSameTeam(player)) and (not AimConfig.aliveCheck or IsAlive(player))
                    if shouldShow then
                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "ThermalESP"
                            highlight.Parent = char
                            highlight.Adornee = char
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.FillTransparency = 0.5
                            highlight.OutlineTransparency = 0
                            highlight.OutlineColor = Color3.new(1,1,1)
                            ThermalESP.highlights[player] = highlight
                        end
                        local color = ThermalESP.colorMode == "固定" and ThermalESP.color or getDynamicColor(ThermalESP.colorMode)
                        highlight.FillColor = color
                        highlight.Enabled = true
                    else
                        if highlight then highlight.Enabled = false end
                    end
                else
                    if highlight then highlight:Destroy() end
                    ThermalESP.highlights[player] = nil
                end
            else
                if highlight then highlight:Destroy() end
                ThermalESP.highlights[player] = nil
            end
        end
    end
end

local function SetupThermalEvents()
    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function() task.wait(0.5); UpdateThermalESP() end)
        UpdateThermalESP()
    end)
    game.Players.PlayerRemoving:Connect(function(player)
        local h = ThermalESP.highlights[player]
        if h then h:Destroy() end
        ThermalESP.highlights[player] = nil
    end)
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            player.CharacterAdded:Connect(function() task.wait(0.5); UpdateThermalESP() end)
        end
    end
end

-- ==================== ESP2 功能函数 ====================
local function ESP2_GetDynamicColor(mode, speed)
    speed = speed or AimConfig.colorSpeed
    local t = tick() * speed
    if mode == "循环色相" then
        local hue = (t % 2) / 2
        return Color3.fromHSV(hue, 1, 1)
    elseif mode == "瀑布" then
        local hue = (t % 2) / 2
        local brightness = (math.sin(t * 2) + 1) / 2
        return Color3.fromHSV(hue, 1, brightness)
    elseif mode == "波浪" then
        local r = (math.sin(t * 1.3) + 1) / 2
        local g = (math.sin(t * 1.7 + 2) + 1) / 2
        local b = (math.sin(t * 2.1 + 4) + 1) / 2
        return Color3.new(r, g, b)
    end
    return Color3.fromHSV(0, 1, 1)
end

local function ESP2_GetCurrentColor(mode, fixedColor)
    if mode == "固定" then return fixedColor end
    return ESP2_GetDynamicColor(mode)
end

local function ESP2_Create(Class, Properties)
    local inst = (type(Class) == "string") and Instance.new(Class) or Class
    for prop, val in pairs(Properties) do
        inst[prop] = val
    end
    return inst
end

local function ESP2_FadeOutOnDist(element, distance, maxDist)
    local maxD = maxDist or ESP2_Settings.MaxDistance
    local transparency = math.max(0.1, 1 - (distance / maxD))
    if element:IsA("TextLabel") then
        element.TextTransparency = 1 - transparency
    elseif element:IsA("ImageLabel") then
        element.ImageTransparency = 1 - transparency
    elseif element:IsA("UIStroke") then
        element.Transparency = 1 - transparency
    elseif element:IsA("Frame") then
        element.BackgroundTransparency = 1 - transparency
    elseif element:IsA("Highlight") then
        element.FillTransparency = 1 - transparency
        element.OutlineTransparency = 1 - transparency
    end
end

local function CreateESP2ScreenGui()
    if ESP2.ScreenGui then return end
    ESP2.ScreenGui = ESP2_Create("ScreenGui", {
        Parent = game:GetService("CoreGui"),
        Name = "ESP2Holder",
        Enabled = true,
    })
end

local function CreateESP2ForPlayer(plr)
    if ESP2.PlayerElements[plr] then return end
    local sg = ESP2.ScreenGui
    if not sg then return end

    local elements = {}
    elements.Name = ESP2_Create("TextLabel", {Parent = sg, Position = UDim2.new(0.5, 0, 0, -11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP2.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
    elements.Distance = ESP2_Create("TextLabel", {Parent = sg, Position = UDim2.new(0.5, 0, 0, 11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP2.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
    elements.Weapon = ESP2_Create("TextLabel", {Parent = sg, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP2.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
    elements.Box = ESP2_Create("Frame", {Parent = sg, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.75, BorderSizePixel = 0})
    elements.Outline = ESP2_Create("UIStroke", {Parent = elements.Box, Enabled = false, Transparency = 0, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Miter})
    elements.Healthbar = ESP2_Create("Frame", {Parent = sg, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0})
    elements.BehindHealthbar = ESP2_Create("Frame", {Parent = sg, ZIndex = -1, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0})
    elements.HealthText = ESP2_Create("TextLabel", {Parent = sg, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP2.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0)})
    elements.Chams = ESP2_Create("Highlight", {Parent = sg, FillTransparency = 1, OutlineTransparency = 0, OutlineColor = Color3.fromRGB(119, 120, 255), DepthMode = "AlwaysOnTop"})
    elements.WeaponIcon = ESP2_Create("ImageLabel", {Parent = sg, BackgroundTransparency = 1, BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(0, 40, 0, 40)})
    elements.Gradient1 = ESP2_Create("UIGradient", {Parent = elements.Box, Enabled = false, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(119, 120, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))}})
    elements.Gradient2 = ESP2_Create("UIGradient", {Parent = elements.Outline, Enabled = false, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(119, 120, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))}})
    elements.Gradient3 = ESP2_Create("UIGradient", {Parent = elements.WeaponIcon, Rotation = -90, Enabled = false, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(119, 120, 255))}})
    for _, v in pairs(elements) do if v and v:IsA("GuiObject") then v.Visible = false end end
    if elements.Chams then elements.Chams.Enabled = false end
    ESP2.PlayerElements[plr] = elements
end

local function DestroyESP2ForPlayer(plr)
    local elements = ESP2.PlayerElements[plr]
    if elements then
        for _, v in pairs(elements) do if v then pcall(function() v:Destroy() end) end end
        ESP2.PlayerElements[plr] = nil
    end
end

local function UpdateESP2()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local lp = game.Players.LocalPlayer
    local maxDist = ESP2_Settings.MaxDistance

    local boxColor = ESP2_GetCurrentColor(ESP2_Settings.BoxColorMode, ESP2_Settings.BoxColor)
    local nameColor = ESP2_GetCurrentColor(ESP2_Settings.NameColorMode, ESP2_Settings.NameColor)
    local healthColor = ESP2_GetCurrentColor(ESP2_Settings.HealthBarColorMode, ESP2_Settings.HealthBarColor)

    for plr, elements in pairs(ESP2.PlayerElements) do
        local shouldHide = true
        if plr and plr.Character then
            local char = plr.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local sameTeam = (ESP2_Settings.TeamCheck and lp.Team == plr.Team and lp.Team ~= nil)
                if not sameTeam then
                    local pos, onScreen = camera:WorldToScreenPoint(hrp.Position)
                    local dist = (camera.CFrame.Position - hrp.Position).Magnitude
                    if onScreen and dist <= maxDist then
                        shouldHide = false
                        local size = hrp.Size.Y
                        local scaleFactor = (size * camera.ViewportSize.Y) / (pos.Z * 2)
                        local w = 3 * scaleFactor
                        local h = 4.5 * scaleFactor

                        ESP2_FadeOutOnDist(elements.Box, dist, maxDist)
                        ESP2_FadeOutOnDist(elements.Outline, dist, maxDist)
                        ESP2_FadeOutOnDist(elements.Name, dist, maxDist)
                        ESP2_FadeOutOnDist(elements.Healthbar, dist, maxDist)
                        ESP2_FadeOutOnDist(elements.BehindHealthbar, dist, maxDist)
                        ESP2_FadeOutOnDist(elements.HealthText, dist, maxDist)
                        ESP2_FadeOutOnDist(elements.Chams, dist, maxDist)

                        if ESP2_Settings.ShowBox then
                            elements.Box.Position = UDim2.new(0, pos.X - w/2, 0, pos.Y - h/2)
                            elements.Box.Size = UDim2.new(0, w, 0, h)
                            elements.Box.Visible = true
                            elements.Box.BackgroundTransparency = 0.75
                            elements.Box.BorderSizePixel = 1
                            elements.Box.BackgroundColor3 = boxColor
                        else
                            elements.Box.Visible = false
                        end

                        if ESP2_Settings.ShowChams then
                            elements.Chams.Adornee = char
                            elements.Chams.Enabled = true
                            elements.Chams.FillColor = Color3.fromRGB(119, 120, 255)
                            elements.Chams.FillTransparency = 0.8
                            elements.Chams.OutlineColor = Color3.fromRGB(119, 120, 255)
                            elements.Chams.OutlineTransparency = 0.5
                            elements.Chams.DepthMode = "AlwaysOnTop"
                        else
                            elements.Chams.Enabled = false
                        end

                        if ESP2_Settings.ShowName then
                            elements.Name.Text = string.format("%s [%dm]", plr.Name, math.floor(dist))
                            elements.Name.Position = UDim2.new(0, pos.X, 0, pos.Y - h/2 - 9)
                            elements.Name.TextColor3 = nameColor
                            elements.Name.Visible = true
                        else
                            elements.Name.Visible = false
                        end

                        if ESP2_Settings.ShowHealth then
                            local health = hum.Health / hum.MaxHealth
                            health = math.clamp(health, 0, 1)
                            elements.Healthbar.Position = UDim2.new(0, pos.X - w/2 - 6, 0, pos.Y - h/2 + h * (1 - health))
                            elements.Healthbar.Size = UDim2.new(0, 2.5, 0, h * health)
                            elements.Healthbar.BackgroundColor3 = healthColor
                            elements.Healthbar.Visible = true
                            elements.BehindHealthbar.Position = UDim2.new(0, pos.X - w/2 - 6, 0, pos.Y - h/2)
                            elements.BehindHealthbar.Size = UDim2.new(0, 2.5, 0, h)
                            elements.BehindHealthbar.Visible = true
                            local healthPercent = math.floor(hum.Health / hum.MaxHealth * 100)
                            elements.HealthText.Position = UDim2.new(0, pos.X - w/2 - 6, 0, pos.Y - h/2 + h * (1 - healthPercent/100) + 3)
                            elements.HealthText.Text = tostring(healthPercent)
                            elements.HealthText.Visible = (hum.Health < hum.MaxHealth)
                        else
                            elements.Healthbar.Visible = false
                            elements.BehindHealthbar.Visible = false
                            elements.HealthText.Visible = false
                        end

                        elements.Weapon.Visible = false
                        elements.WeaponIcon.Visible = false
                        elements.Distance.Visible = false
                    end
                end
            end
        end
        if shouldHide then
            for _, v in pairs(elements) do if v and v:IsA("GuiObject") then v.Visible = false end end
            if elements.Chams then elements.Chams.Enabled = false end
        end
    end

    for plr, _ in pairs(ESP2.PlayerElements) do
        if not game.Players:FindFirstChild(plr.Name) then DestroyESP2ForPlayer(plr) end
    end
end

local function StartESP2()
    if ESP2.RenderConnection then return end
    ESP2.RenderConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if ESP2_Settings.Enabled then
            UpdateESP2()
        else
            for plr, elements in pairs(ESP2.PlayerElements) do
                for _, v in pairs(elements) do if v and v:IsA("GuiObject") then v.Visible = false end end
                if elements.Chams then elements.Chams.Enabled = false end
            end
        end
    end)
end

local function InitESP2Events()
    if ESP2.Connections.PlayerAdded then return end
    ESP2.Connections.PlayerAdded = game.Players.PlayerAdded:Connect(function(plr)
        if plr == game.Players.LocalPlayer then return end
        CreateESP2ForPlayer(plr)
    end)
    ESP2.Connections.PlayerRemoving = game.Players.PlayerRemoving:Connect(function(plr)
        DestroyESP2ForPlayer(plr)
    end)
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer then CreateESP2ForPlayer(plr) end
    end
end

local function SetESP2Enabled(enabled)
    ESP2_Settings.Enabled = enabled
    if enabled then
        CreateESP2ScreenGui()
        InitESP2Events()
        StartESP2()
    else
        for plr, elements in pairs(ESP2.PlayerElements) do
            for _, v in pairs(elements) do if v and v:IsA("GuiObject") then v.Visible = false end end
            if elements.Chams then elements.Chams.Enabled = false end
        end
    end
end

-- ==================== 目标信息面板（小窗） ====================
local TargetInfo = {
    Panel = nil, Avatar = nil, NameLabel = nil, HealthBarBg = nil, HealthBarFill = nil,
    HealthText = nil, DistanceText = nil, CurrentTarget = nil, IsVisible = false,
    TweenIn = nil, TweenOut = nil, UpdateConnection = nil, LastHealth = {},
}

local function ClearAllParticles()
    local parent = TargetInfo.Panel and TargetInfo.Panel.Parent
    if not parent then return end
    for _, child in ipairs(parent:GetChildren()) do if child.Name == "Particle" then child:Destroy() end end
end

local function CreateTargetInfoPanel()
    local screenGui = game:GetService("CoreGui"):FindFirstChild("AimAssistPanel")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "AimAssistPanel"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = game:GetService("CoreGui")
    end
    local existing = screenGui:FindFirstChild("TargetInfoPanel")
    if existing then existing:Destroy() end
    local isMobileDevice = game:GetService("UserInputService").TouchEnabled
    local PANEL_WIDTH, PANEL_HEIGHT, AVATAR_SIZE, FONT_SIZE_NAME, FONT_SIZE_TEXT
    if isMobileDevice then
        PANEL_WIDTH = math.min(220, workspace.CurrentCamera.ViewportSize.X * 0.7)
        PANEL_HEIGHT = 90
        AVATAR_SIZE = 50
        FONT_SIZE_NAME = 12
        FONT_SIZE_TEXT = 10
    else
        PANEL_WIDTH = 280
        PANEL_HEIGHT = 110
        AVATAR_SIZE = 64
        FONT_SIZE_NAME = 14
        FONT_SIZE_TEXT = 12
    end
    local panel = Instance.new("Frame")
    panel.Name = "TargetInfoPanel"
    panel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
    panel.Position = UDim2.new(1, 20, 0.5, -PANEL_HEIGHT/2)
    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.Visible = true
    panel.Parent = screenGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel
    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, AVATAR_SIZE, 0, AVATAR_SIZE)
    avatar.Position = UDim2.new(0, 8, 0.5, -AVATAR_SIZE/2)
    avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    avatar.BackgroundTransparency = 0.2
    avatar.BorderSizePixel = 0
    avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    avatar.Parent = panel
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, AVATAR_SIZE/2)
    avatarCorner.Parent = avatar
    local name = Instance.new("TextLabel")
    name.Name = "NameLabel"
    name.Size = UDim2.new(1, - (AVATAR_SIZE + 16), 0, 24)
    name.Position = UDim2.new(0, AVATAR_SIZE + 12, 0, 6)
    name.BackgroundTransparency = 1
    name.Text = ""
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Font = Enum.Font.GothamBold
    name.TextSize = FONT_SIZE_NAME
    name.Parent = panel
    local healthBg = Instance.new("Frame")
    healthBg.Name = "HealthBg"
    healthBg.Size = UDim2.new(1, - (AVATAR_SIZE + 16), 0, 10)
    healthBg.Position = UDim2.new(0, AVATAR_SIZE + 12, 0, 32)
    healthBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = panel
    local healthBgCorner = Instance.new("UICorner")
    healthBgCorner.CornerRadius = UDim.new(0, 4)
    healthBgCorner.Parent = healthBg
    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg
    local healthFillCorner = Instance.new("UICorner")
    healthFillCorner.CornerRadius = UDim.new(0, 4)
    healthFillCorner.Parent = healthFill
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, - (AVATAR_SIZE + 16), 0, 18)
    healthText.Position = UDim2.new(0, AVATAR_SIZE + 12, 0, 46)
    healthText.BackgroundTransparency = 1
    healthText.Text = ""
    healthText.TextColor3 = Color3.fromRGB(220, 220, 220)
    healthText.TextXAlignment = Enum.TextXAlignment.Left
    healthText.Font = Enum.Font.Gotham
    healthText.TextSize = FONT_SIZE_TEXT
    healthText.Parent = panel
    local distanceText = Instance.new("TextLabel")
    distanceText.Name = "DistanceText"
    distanceText.Size = UDim2.new(0, 70, 0, 18)
    distanceText.Position = UDim2.new(1, -78, 0, PANEL_HEIGHT - 24)
    distanceText.BackgroundTransparency = 1
    distanceText.Text = ""
    distanceText.TextColor3 = Color3.fromRGB(200, 200, 100)
    distanceText.TextXAlignment = Enum.TextXAlignment.Right
    distanceText.Font = Enum.Font.Gotham
    distanceText.TextSize = FONT_SIZE_TEXT
    distanceText.Parent = panel
    local appearTween = game:GetService("TweenService"):Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -PANEL_WIDTH - 20, 0.5, -PANEL_HEIGHT/2),
        BackgroundTransparency = 0.15
    })
    local disappearTween = game:GetService("TweenService"):Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 20, 0.5, -PANEL_HEIGHT/2),
        BackgroundTransparency = 1
    })
    TargetInfo.Panel = panel
    TargetInfo.Avatar = avatar
    TargetInfo.NameLabel = name
    TargetInfo.HealthBarBg = healthBg
    TargetInfo.HealthBarFill = healthFill
    TargetInfo.HealthText = healthText
    TargetInfo.DistanceText = distanceText
    TargetInfo.TweenIn = appearTween
    TargetInfo.TweenOut = disappearTween
end

local function SetPlayerAvatar(player)
    if not TargetInfo.Avatar then return end
    local userId = player.UserId
    local avatarUrl = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId)
    TargetInfo.Avatar.Image = avatarUrl
end

local function createParticle(centerX, centerY, ts)
    local shape = ParticleConfig.shape
    local size = ParticleConfig.size
    local particle
    if shape == "圆形" then
        particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, size, 0, size)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        particle.BackgroundColor3 = getParticleColor()
        particle.BackgroundTransparency = 0.3
        particle.BorderSizePixel = 0
    elseif shape == "爱心" then
        particle = Instance.new("TextLabel")
        local symbol = heartSymbols[math.random(1, #heartSymbols)]
        particle.Text = symbol
        particle.Font = Enum.Font.GothamBold
        particle.TextSize = size
        particle.TextColor3 = getParticleColor()
        particle.BackgroundTransparency = 1
        particle.Size = UDim2.new(0, size+6, 0, size+6)
    elseif shape == "🩸" then
        particle = Instance.new("TextLabel")
        particle.Text = "🩸"
        particle.Font = Enum.Font.GothamBold
        particle.TextSize = size
        particle.TextColor3 = getParticleColor()
        particle.BackgroundTransparency = 1
        particle.Size = UDim2.new(0, size+6, 0, size+6)
    end
    if not particle then return end
    particle.Name = "Particle"
    particle.Parent = TargetInfo.Panel.Parent
    local angle = math.random() * math.pi * 2
    local radius = math.random(20, 60)
    local offsetX = math.cos(angle) * radius
    local offsetY = math.sin(angle) * radius - 20
    particle.Position = UDim2.new(0, centerX + offsetX, 0, centerY + offsetY)
    local endPos = UDim2.new(0, centerX + offsetX * 1.8, 0, centerY + offsetY * 1.8 - 30)
    local tweenProps = (shape == "圆形") and {Position = endPos, BackgroundTransparency = 1} or {Position = endPos, TextTransparency = 1}
    local tween = ts:Create(particle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), tweenProps)
    tween:Play()
    tween.Completed:Connect(function() particle:Destroy() end)
end

local isShaking = false
local function PlayHitEffect()
    local tweenService = game:GetService("TweenService")
    if not TargetInfo.Avatar or not TargetInfo.Avatar.Parent or isShaking or not PanelConfig.enabled then
        return
    end
    isShaking = true
    ClearAllParticles()
    local originalPos = TargetInfo.Avatar.Position
    local offsetRight = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + 6, originalPos.Y.Scale, originalPos.Y.Offset)
    local offsetLeft = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 6, originalPos.Y.Scale, originalPos.Y.Offset)
    local shakeRight = tweenService:Create(TargetInfo.Avatar, TweenInfo.new(0.04, Enum.EasingStyle.Linear), {Position = offsetRight})
    local shakeLeft = tweenService:Create(TargetInfo.Avatar, TweenInfo.new(0.04, Enum.EasingStyle.Linear), {Position = offsetLeft})
    local back = tweenService:Create(TargetInfo.Avatar, TweenInfo.new(0.04, Enum.EasingStyle.Linear), {Position = originalPos})
    shakeRight:Play()
    shakeRight.Completed:Connect(function()
        shakeLeft:Play()
        shakeLeft.Completed:Connect(function()
            back:Play()
            back.Completed:Connect(function() isShaking = false end)
        end)
    end)
    local avatarAbsPos = TargetInfo.Avatar.AbsolutePosition
    local avatarSize = TargetInfo.Avatar.AbsoluteSize
    local center = avatarAbsPos + avatarSize/2
    for i = 1, ParticleConfig.count do createParticle(center.X, center.Y, tweenService) end
end

local function UpdateTargetPanel(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    if AimConfig.aliveCheck and not IsAlive(targetPlayer) then return false end
    if AimConfig.teamCheck and IsSameTeam(targetPlayer) then return false end
    local hum = targetPlayer.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    TargetInfo.NameLabel.Text = targetPlayer.DisplayName or targetPlayer.Name
    local currentHealth = hum.Health
    local maxHealth = hum.MaxHealth
    local healthPercent = math.clamp(currentHealth / maxHealth, 0, 1)
    TargetInfo.HealthBarFill.Size = UDim2.new(healthPercent, 0, 1, 0)
    if healthPercent > 0.6 then
        TargetInfo.HealthBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    elseif healthPercent > 0.3 then
        TargetInfo.HealthBarFill.BackgroundColor3 = Color3.fromRGB(250, 180, 30)
    else
        TargetInfo.HealthBarFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    end
    TargetInfo.HealthText.Text = string.format("%.0f / %.0f", currentHealth, maxHealth)
    local localChar = game.Players.LocalPlayer.Character
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local distance = 0
    if localChar and localChar:FindFirstChild("HumanoidRootPart") and targetRoot then
        distance = (localChar.HumanoidRootPart.Position - targetRoot.Position).Magnitude
    end
    TargetInfo.DistanceText.Text = string.format("%.1f m", distance)
    SetPlayerAvatar(targetPlayer)
    local last = TargetInfo.LastHealth[targetPlayer] or currentHealth
    if currentHealth < last then PlayHitEffect() end
    TargetInfo.LastHealth[targetPlayer] = currentHealth
    return true
end

local function GetBestTargetInFOV()
    local localPlayer = game.Players.LocalPlayer
    local camera = workspace.CurrentCamera
    local fovRadius = AimConfig.fovsize
    local center = camera.ViewportSize / 2
    local bestTarget = nil
    local bestScore = math.huge
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            local skip = false
            if AimConfig.aliveCheck and not IsAlive(player) then skip = true end
            if not skip and AimConfig.teamCheck and IsSameTeam(player) then skip = true end
            if not skip then
                local head = player.Character and player.Character:FindFirstChild("Head")
                if head then
                    local wallOk = true
                    if AimConfig.wallCheck then
                        local localChar = localPlayer.Character
                        local ray = Ray.new(camera.CFrame.Position, head.Position - camera.CFrame.Position)
                        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {localChar})
                        if hit and not hit:IsDescendantOf(player.Character) then wallOk = false end
                    end
                    if wallOk then
                        local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local distToCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                            if distToCenter <= fovRadius and distToCenter < bestScore then
                                bestScore = distToCenter
                                bestTarget = player
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local function ShowPanel()
    if not PanelConfig.enabled then return end
    if TargetInfo.TweenOut and TargetInfo.TweenOut.PlaybackState == Enum.PlaybackState.Playing then
        TargetInfo.TweenOut:Cancel()
        local PANEL_HEIGHT = TargetInfo.Panel.AbsoluteSize.Y
        TargetInfo.Panel.Position = UDim2.new(1, 20, 0.5, -PANEL_HEIGHT/2)
        TargetInfo.Panel.BackgroundTransparency = 1
    end
    TargetInfo.IsVisible = true
    TargetInfo.Panel.Visible = true
    if not (TargetInfo.TweenIn and TargetInfo.TweenIn.PlaybackState == Enum.PlaybackState.Playing) then
        TargetInfo.TweenIn:Play()
    end
end

local function HidePanel()
    if not TargetInfo.IsVisible then return end
    TargetInfo.IsVisible = false
    TargetInfo.TweenOut:Play()
    TargetInfo.TweenOut.Completed:Wait()
    TargetInfo.Panel.Visible = false
    ClearAllParticles()
end

local function RefreshTarget(target)
    if not PanelConfig.enabled then if TargetInfo.IsVisible then HidePanel() end; return end
    if not target then if TargetInfo.IsVisible then HidePanel() end; return end
    local success = UpdateTargetPanel(target)
    if not success then if TargetInfo.IsVisible then HidePanel() end; return end
    if TargetInfo.CurrentTarget ~= target then TargetInfo.CurrentTarget = target end
    if not TargetInfo.IsVisible or not TargetInfo.Panel.Visible then ShowPanel() end
end

local function OnRenderStep()
    if not TargetInfo.Panel then CreateTargetInfoPanel() end
    if not AimConfig.fovlookAt then if TargetInfo.IsVisible then HidePanel() end; return end
    local best = GetBestTargetInFOV()
    RefreshTarget(best)
end

if TargetInfo.UpdateConnection then TargetInfo.UpdateConnection:Disconnect() end
TargetInfo.UpdateConnection = game:GetService("RunService").RenderStepped:Connect(OnRenderStep)

game.Players.PlayerRemoving:Connect(function(player)
    TargetInfo.LastHealth[player] = nil
    if TargetInfo.CurrentTarget == player then TargetInfo.CurrentTarget = nil; if TargetInfo.IsVisible then HidePanel() end end
    for i, t in pairs(AimTextDrawings) do if t.p == player then if t.drawing then t.drawing:Remove() end; AimTextDrawings[i] = nil; break end end
    local h = ThermalESP.highlights[player]; if h then h:Destroy() end; ThermalESP.highlights[player] = nil
end)

local function onPlayerCharacterAdded(player)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            for i, t in pairs(AimTextDrawings) do if t.p == player then if t.drawing then t.drawing:Remove() end; AimTextDrawings[i] = nil; break end end
        end)
    end
end

for _, player in ipairs(game.Players:GetPlayers()) do
    if player ~= game.Players.LocalPlayer then onPlayerCharacterAdded(player) end
end
game.Players.PlayerAdded:Connect(onPlayerCharacterAdded)

-- ==================== 热键监听（支持鼠标按键，用于运行时） ====================
local UserInputService = game:GetService("UserInputService")

local function IsHotkeyPressed(input, hotkey)
    if not hotkey then return false end
    if hotkey.EnumType == Enum.KeyCode then
        return input.KeyCode == hotkey
    elseif hotkey.EnumType == Enum.UserInputType then
        return input.UserInputType == hotkey
    end
    return false
end

local function OnInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if IsHotkeyPressed(input, AimConfig.aimHotkey) then
        if AimConfig.aimActivationMode == "按住热键" then
            hotkeyPressed = true
        elseif AimConfig.aimActivationMode == "单击切换" then
            AimConfig.hotkeyToggleState = not AimConfig.hotkeyToggleState
        end
    end
end

local function OnInputEnded(input, gameProcessed)
    if gameProcessed then return end
    if IsHotkeyPressed(input, AimConfig.aimHotkey) and AimConfig.aimActivationMode == "按住热键" then
        hotkeyPressed = false
    end
end

UserInputService.InputBegan:Connect(OnInputBegan)
UserInputService.InputEnded:Connect(OnInputEnded)

-- 自瞄激活条件判断
local function ShouldAim()
    if not AimConfig.fovlookAt then return false end
    local mode = AimConfig.aimActivationMode
    if mode == "自动" then
        return true
    elseif mode == "按住热键" then
        return hotkeyPressed
    elseif mode == "单击切换" then
        return AimConfig.hotkeyToggleState
    end
    return true
end

-- ==================== 灵动岛菜单系统（热键设置 + 红色提示） ====================
local UIService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Island = {
    gui = nil,
    container = nil,
    corner = nil,
    innerFrame = nil,
    titleButton = nil,
    targetFrame = nil,
    targetLabel = nil,
    scrollFrame = nil,
    isMenuOpen = false,
    tweenService = TweenService,
    animInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    lastTarget = nil,
    lastExtraWidth = 0,
    activeTween = nil,
    targetTween = nil,
    fpsCounter = { lastTime = tick(), fps = 0, frameCount = 0 },
    settingsBuilt = false,
}

function Island:Create()
    if self.gui then self.gui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DynamicIsland"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")
    self.gui = screenGui
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 160, 0, 40)
    container.Position = UDim2.new(0.5, -80, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(20,20,30)
    container.BackgroundTransparency = 0.15
    container.BorderSizePixel = 0
    container.Parent = screenGui
    self.container = container
    
    self.corner = Instance.new("UICorner")
    self.corner.CornerRadius = UDim.new(0, 20)
    self.corner.Parent = container
    
    local title = Instance.new("TextButton")
    title.Name = "Title"
    title.Size = UDim2.new(1,0,1,0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ Antibot | FPS: --"
    title.TextColor3 = Color3.fromRGB(0,255,0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.AutoButtonColor = false
    title.Parent = container
    self.titleButton = title
    
    self.titleButton.MouseButton1Click:Connect(function()
        self:ToggleMenu()
    end)
    
    local targetFrame = Instance.new("Frame")
    targetFrame.Name = "TargetFrame"
    targetFrame.Size = UDim2.new(0,0,1,0)
    targetFrame.Position = UDim2.new(1,0,0,0)
    targetFrame.BackgroundColor3 = Color3.fromRGB(40,40,50)
    targetFrame.BackgroundTransparency = 0.2
    targetFrame.BorderSizePixel = 0
    targetFrame.ClipsDescendants = false
    targetFrame.Parent = container
    self.targetFrame = targetFrame
    Instance.new("UICorner", targetFrame).CornerRadius = UDim.new(0,20)
    
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Name = "TargetLabel"
    targetLabel.Size = UDim2.new(1, -16, 1, 0)
    targetLabel.Position = UDim2.new(0,8,0,0)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = ""
    targetLabel.TextColor3 = Color3.fromRGB(255,255,255)
    targetLabel.Font = Enum.Font.Gotham
    targetLabel.TextSize = 12
    targetLabel.TextXAlignment = Enum.TextXAlignment.Center
    targetLabel.Parent = targetFrame
    self.targetLabel = targetLabel
    
    local inner = Instance.new("Frame")
    inner.Name = "Inner"
    inner.Size = UDim2.new(1,0,1,-50)
    inner.Position = UDim2.new(0,0,0,40)
    inner.BackgroundTransparency = 1
    inner.Visible = false
    inner.Parent = container
    self.innerFrame = inner
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,-12,1,-12)
    scroll.Position = UDim2.new(0,6,0,6)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(150,150,180)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Parent = inner
    self.scrollFrame = scroll
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    self.isMenuOpen = false
end

function Island:BuildSettingsPanel()
    if self.settingsBuilt then return end
    self.settingsBuilt = true
    local parent = self.scrollFrame
    
    local function createGroup(title)
        local group = Instance.new("Frame")
        group.Size = UDim2.new(1,0,0,0)
        group.BackgroundColor3 = Color3.fromRGB(30,30,42)
        group.BackgroundTransparency = 0.3
        group.BorderSizePixel = 0
        group.AutomaticSize = Enum.AutomaticSize.Y
        group.Parent = parent
        local groupCorner = Instance.new("UICorner")
        groupCorner.CornerRadius = UDim.new(0,12)
        groupCorner.Parent = group
        local groupTitle = Instance.new("TextLabel")
        groupTitle.Size = UDim2.new(1,-12,0,34)
        groupTitle.Position = UDim2.new(0,6,0,4)
        groupTitle.BackgroundTransparency = 1
        groupTitle.Text = title
        groupTitle.TextColor3 = Color3.fromRGB(210,210,240)
        groupTitle.TextXAlignment = Enum.TextXAlignment.Left
        groupTitle.Font = Enum.Font.GothamSemibold
        groupTitle.TextSize = 16
        groupTitle.Parent = group
        local content = Instance.new("Frame")
        content.Size = UDim2.new(1,-12,0,0)
        content.Position = UDim2.new(0,6,0,38)
        content.BackgroundTransparency = 1
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.Parent = group
        local innerLayout = Instance.new("UIListLayout")
        innerLayout.Padding = UDim.new(0,6)
        innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        innerLayout.Parent = content
        return group, content
    end
    
    local function createToggle(parent, labelText, defaultValue, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,0,38)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6,-10,1,0)
        label.Position = UDim2.new(0,8,0,0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(235,235,245)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.Parent = frame
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,70,0,30)
        btn.Position = UDim2.new(1,-78,0.5,-15)
        btn.BackgroundColor3 = defaultValue and Color3.fromRGB(0,170,100) or Color3.fromRGB(75,75,95)
        btn.Text = defaultValue and "开启" or "关闭"
        btn.TextColor3 = Color3.new(1,1,1)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = frame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0,6)
        btnCorner.Parent = btn
        local state = defaultValue
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(0,170,100) or Color3.fromRGB(75,75,95)
            btn.Text = state and "开启" or "关闭"
            callback(state)
        end)
        return btn
    end
    
    local function createDropdown(parent, labelText, options, defaultOption, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,0,38)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5,-10,1,0)
        label.Position = UDim2.new(0,8,0,0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(235,235,245)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.Parent = frame
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,110,0,30)
        btn.Position = UDim2.new(1,-118,0.5,-15)
        btn.BackgroundColor3 = Color3.fromRGB(55,55,75)
        btn.Text = defaultOption
        btn.TextColor3 = Color3.new(1,1,1)
        btn.TextSize = 13
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = frame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0,6)
        btnCorner.Parent = btn
        local idx = 1
        for i, opt in ipairs(options) do if opt == defaultOption then idx = i; break end end
        btn.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            local selected = options[idx]
            btn.Text = selected
            callback(selected)
        end)
        return btn
    end
    
    local function createNumberInput(parent, labelText, minVal, maxVal, defaultValue, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,0,38)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5,-10,1,0)
        label.Position = UDim2.new(0,8,0,0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(235,235,245)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.Parent = frame
        local valueBox = Instance.new("TextBox")
        valueBox.Size = UDim2.new(0,60,0,30)
        valueBox.Position = UDim2.new(1,-180,0.5,-15)
        valueBox.BackgroundColor3 = Color3.fromRGB(45,45,65)
        valueBox.Text = tostring(defaultValue)
        valueBox.TextColor3 = Color3.new(1,1,1)
        valueBox.TextSize = 13
        valueBox.Font = Enum.Font.GothamBold
        valueBox.BorderSizePixel = 0
        valueBox.Parent = frame
        local valCorner = Instance.new("UICorner")
        valCorner.CornerRadius = UDim.new(0,6)
        valCorner.Parent = valueBox
        local decBtn = Instance.new("TextButton")
        decBtn.Size = UDim2.new(0,35,0,30)
        decBtn.Position = UDim2.new(1,-110,0.5,-15)
        decBtn.Text = "-"
        decBtn.BackgroundColor3 = Color3.fromRGB(55,55,75)
        decBtn.TextColor3 = Color3.new(1,1,1)
        decBtn.TextSize = 18
        decBtn.Font = Enum.Font.GothamBold
        decBtn.BorderSizePixel = 0
        decBtn.Parent = frame
        local decCorner = Instance.new("UICorner")
        decCorner.CornerRadius = UDim.new(0,6)
        decCorner.Parent = decBtn
        local incBtn = Instance.new("TextButton")
        incBtn.Size = UDim2.new(0,35,0,30)
        incBtn.Position = UDim2.new(1,-70,0.5,-15)
        incBtn.Text = "+"
        incBtn.BackgroundColor3 = Color3.fromRGB(55,55,75)
        incBtn.TextColor3 = Color3.new(1,1,1)
        incBtn.TextSize = 18
        incBtn.Font = Enum.Font.GothamBold
        incBtn.BorderSizePixel = 0
        incBtn.Parent = frame
        local incCorner = Instance.new("UICorner")
        incCorner.CornerRadius = UDim.new(0,6)
        incCorner.Parent = incBtn
        local current = defaultValue
        local function updateValue(newVal)
            local num = tonumber(newVal)
            if num == nil then num = current end
            current = safeClamp(num, minVal, maxVal)
            valueBox.Text = tostring(current)
            callback(current)
        end
        decBtn.MouseButton1Click:Connect(function() updateValue(current-1) end)
        incBtn.MouseButton1Click:Connect(function() updateValue(current+1) end)
        valueBox.FocusLost:Connect(function() updateValue(valueBox.Text) end)
        return valueBox
    end
    
    local function createColorPicker(parent, labelText, modeRef, colorRef, modeCallback, colorCallback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,0,90)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,-10,0,22)
        label.Position = UDim2.new(0,8,0,0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(235,235,245)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.Parent = frame
        
        local modeBtn = Instance.new("TextButton")
        modeBtn.Size = UDim2.new(0,100,0,30)
        modeBtn.Position = UDim2.new(0,8,0,26)
        modeBtn.BackgroundColor3 = Color3.fromRGB(55,55,75)
        local isFixed = (modeRef == "固定")
        modeBtn.Text = isFixed and "固定颜色" or "动态彩色"
        modeBtn.TextColor3 = Color3.new(1,1,1)
        modeBtn.TextSize = 12
        modeBtn.Font = Enum.Font.Gotham
        modeBtn.BorderSizePixel = 0
        modeBtn.Parent = frame
        local modeCorner = Instance.new("UICorner")
        modeCorner.CornerRadius = UDim.new(0,6)
        modeCorner.Parent = modeBtn
        
        local colorBtn = Instance.new("TextButton")
        colorBtn.Size = UDim2.new(0,100,0,30)
        colorBtn.Position = UDim2.new(0,116,0,26)
        colorBtn.BackgroundColor3 = Color3.fromRGB(55,55,75)
        local colorIdx = 1
        for i, opt in ipairs(ColorPresets) do if ColorValues[opt] == colorRef then colorIdx = i; break end end
        colorBtn.Text = ColorPresets[colorIdx]
        colorBtn.TextColor3 = Color3.new(1,1,1)
        colorBtn.TextSize = 12
        colorBtn.Font = Enum.Font.Gotham
        colorBtn.BorderSizePixel = 0
        colorBtn.Visible = isFixed
        colorBtn.Parent = frame
        local colorCorner = Instance.new("UICorner")
        colorCorner.CornerRadius = UDim.new(0,6)
        colorCorner.Parent = colorBtn
        
        local dynModeBtn = Instance.new("TextButton")
        dynModeBtn.Size = UDim2.new(0,140,0,30)
        dynModeBtn.Position = UDim2.new(0,8,0,62)
        dynModeBtn.BackgroundColor3 = Color3.fromRGB(55,55,75)
        local currentDyn = (modeRef == "固定") and "循环色相" or modeRef
        dynModeBtn.Text = "模式: " .. currentDyn
        dynModeBtn.TextColor3 = Color3.new(1,1,1)
        dynModeBtn.TextSize = 12
        dynModeBtn.Font = Enum.Font.Gotham
        dynModeBtn.BorderSizePixel = 0
        dynModeBtn.Visible = not isFixed
        dynModeBtn.Parent = frame
        local dynCorner = Instance.new("UICorner")
        dynCorner.CornerRadius = UDim.new(0,6)
        dynCorner.Parent = dynModeBtn
        
        local currentModeIsFixed = isFixed
        local currentDynamicMode = currentDyn
        modeBtn.MouseButton1Click:Connect(function()
            currentModeIsFixed = not currentModeIsFixed
            modeBtn.Text = currentModeIsFixed and "固定颜色" or "动态彩色"
            colorBtn.Visible = currentModeIsFixed
            dynModeBtn.Visible = not currentModeIsFixed
            if currentModeIsFixed then
                modeCallback("固定")
            else
                modeCallback(currentDynamicMode)
            end
            refreshAllColors()
        end)
        colorBtn.MouseButton1Click:Connect(function()
            colorIdx = colorIdx % #ColorPresets + 1
            local selected = ColorPresets[colorIdx]
            colorBtn.Text = selected
            colorCallback(ColorValues[selected])
            refreshAllColors()
        end)
        local dynIdx = 1
        for i, opt in ipairs(DynamicModes) do if opt == currentDynamicMode then dynIdx = i; break end end
        dynModeBtn.MouseButton1Click:Connect(function()
            dynIdx = dynIdx % #DynamicModes + 1
            local selected = DynamicModes[dynIdx]
            dynModeBtn.Text = "模式: " .. selected
            currentDynamicMode = selected
            if not currentModeIsFixed then
                modeCallback(selected)
                refreshAllColors()
            end
        end)
        return frame
    end
    
    -- 热键捕获按钮（下方添加红色提示）
    local function createHotkeyButtonWithHint(parent, labelText, currentKey, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1,0,0,60)
        container.BackgroundTransparency = 1
        container.Parent = parent
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,0,38)
        frame.BackgroundTransparency = 1
        frame.Parent = container
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5,-10,1,0)
        label.Position = UDim2.new(0,8,0,0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(235,235,245)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,120,0,30)
        btn.Position = UDim2.new(1,-128,0.5,-15)
        btn.BackgroundColor3 = Color3.fromRGB(55,55,75)
        local function getKeyDisplay(k)
            if not k then return "未设置" end
            if k.EnumType == Enum.KeyCode then
                return tostring(k):gsub("Enum.KeyCode.", "")
            elseif k.EnumType == Enum.UserInputType then
                local name = tostring(k):gsub("Enum.UserInputType.", "")
                if name == "MouseButton1" then return "鼠标左键"
                elseif name == "MouseButton2" then return "鼠标右键"
                elseif name == "MouseButton3" then return "鼠标中键"
                else return name end
            end
            return "未知"
        end
        btn.Text = getKeyDisplay(currentKey)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.TextSize = 12
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = frame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0,6)
        btnCorner.Parent = btn
        
        -- 红色提示文字
        local hint = Instance.new("TextLabel")
        hint.Size = UDim2.new(1, -10, 0, 18)
        hint.Position = UDim2.new(0, 8, 0, 42)
        hint.BackgroundTransparency = 1
        hint.Text = "提示：设置鼠标左/右键时，请在「按下任意键」后点击菜单UI空白区域"
        hint.TextColor3 = Color3.fromRGB(255, 80, 80)
        hint.TextSize = 11
        hint.Font = Enum.Font.Gotham
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.Parent = container
        
        local waiting = false
        local tempConnection = nil
        
        local function cancelWaiting()
            if waiting then
                waiting = false
                if tempConnection then tempConnection:Disconnect() end
                btn.Text = getKeyDisplay(currentKey)
                btn.BackgroundColor3 = Color3.fromRGB(55,55,75)
            end
        end
        
        btn.MouseButton1Click:Connect(function()
            if waiting then
                cancelWaiting()
                return
            end
            waiting = true
            btn.Text = "按下任意键..."
            btn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
            tempConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not waiting then return end
                if gameProcessed then return end
                local newKey = nil
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    newKey = input.KeyCode
                elseif input.UserInputType ~= Enum.UserInputType.None then
                    newKey = input.UserInputType
                end
                if newKey then
                    callback(newKey)
                    currentKey = newKey
                    cancelWaiting()
                end
            end)
        end)
        
        return btn
    end
    
    -- 构建各个分组
    local mainGroup, mainContent = createGroup("⚙️ 主控开关")
    createToggle(mainContent, "开启自瞄", AimConfig.fovlookAt, function(val) AimConfig.fovlookAt = val; if not val and AimRedLine then AimRedLine.Visible = false end end)
    createToggle(mainContent, "显示FOV圈圈", showFOVCircleFlag, function(val)
        if val then
            InitAimFOV(AimConfig.fovsize, getCurrentColor(AimConfig.fovcolorMode, AimConfig.fovcolorFixed), AimConfig.fovthickness, AimConfig.Transparency/10)
            refreshAllColors()
            SetFOVCircleVisible(true)
        else
            SetFOVCircleVisible(false)
        end
    end)
    
    local paramGroup, paramContent = createGroup("🎯 自瞄参数")
    createDropdown(paramContent, "瞄准部位", BodyPartDisplay, "头部", function(choice) currentBodyPart = choice end)
    createDropdown(paramContent, "优先模式", {"Distance","Crosshair","Speed","Smart"}, "Smart", function(choice) AimConfig.priorityMode = choice end)
    createDropdown(paramContent, "自瞄模式", {"AI","Function"}, "AI", function(choice) AimConfig.aimMode = choice end)
    createDropdown(paramContent, "自瞄类型", {"普通", "强锁"}, "普通", function(choice) AimConfig.aimModeType = choice end)
    
    -- 热键设置分组（含红色提示）
    local hotkeyGroup, hotkeyContent = createGroup("🎮 热键设置")
    createDropdown(hotkeyContent, "自瞄激活模式", {"自动", "按住热键", "单击切换"}, AimConfig.aimActivationMode, function(choice)
        AimConfig.aimActivationMode = choice
        if choice ~= "按住热键" then hotkeyPressed = false end
        if choice == "单击切换" then AimConfig.hotkeyToggleState = false end
    end)
    createHotkeyButtonWithHint(hotkeyContent, "自瞄热键", AimConfig.aimHotkey, function(newKey)
        AimConfig.aimHotkey = newKey
    end)
    
    local funcGroup, funcContent = createGroup("🔘 功能选项")
    createToggle(funcContent, "队伍检测", AimConfig.teamCheck, function(val) AimConfig.teamCheck = val; ESPConfig.teamCheck = val end)
    createToggle(funcContent, "活体检测", AimConfig.aliveCheck, function(val) AimConfig.aliveCheck = val end)
    createToggle(funcContent, "墙壁检测", AimConfig.wallCheck, function(val) AimConfig.wallCheck = val end)
    createToggle(funcContent, "预判自瞄", AimConfig.prejudgingselfsighting, function(val) AimConfig.prejudgingselfsighting = val end)
    createToggle(funcContent, "自动开火", AimConfig.autoFire, function(val) AimConfig.autoFire = val end)
    
    local valueGroup, valueContent = createGroup("📊 数值调节")
    createNumberInput(valueContent, "FOV大小", 10, 500, AimConfig.fovsize, function(val) AimConfig.fovsize = val; if AimFOVCircle then AimFOVCircle.Radius = val end end)
    createNumberInput(valueContent, "自瞄距离", 10, 1000, AimConfig.distance, function(val) AimConfig.distance = val end)
    createNumberInput(valueContent, "平滑度", 1, 20, AimConfig.smoothness, function(val) AimConfig.smoothness = val end)
    createNumberInput(valueContent, "自瞄速度", 1, 20, AimConfig.aimSpeed, function(val) AimConfig.aimSpeed = val end)
    createNumberInput(valueContent, "文字大小", 10, 30, TextSize, function(val) TextSize = val; for _, t in pairs(AimTextDrawings) do if t.drawing then t.drawing.Size = val end end end)
    createNumberInput(valueContent, "动态彩色速度", 0.5, 5, AimConfig.colorSpeed, function(val) AimConfig.colorSpeed = val end)
    createNumberInput(valueContent, "预判自瞄距离", 10, 500, AimConfig.prejudgingselfsightingdistance, function(val) AimConfig.prejudgingselfsightingdistance = val end)
    
    local espGroup, espContent = createGroup("👁️ 透视 ESP")
    createToggle(espContent, "ESP总开关", ESPConfig.enabled, function(val) ESPConfig.enabled = val; if not val then for p,_ in pairs(ESPDrawings) do DestroyESPForPlayer(p) end end end)
    createToggle(espContent, "身体方框", ESPConfig.showBox, function(val) ESPConfig.showBox = val end)
    createToggle(espContent, "血量显示", ESPConfig.showHealth, function(val) ESPConfig.showHealth = val end)
    createToggle(espContent, "用户名显示", ESPConfig.showName, function(val) ESPConfig.showName = val end)
    createToggle(espContent, "距离显示", ESPConfig.showDistance, function(val) ESPConfig.showDistance = val end)
    createToggle(espContent, "天线 (射线)", ESPConfig.showTracer, function(val) ESPConfig.showTracer = val end)
    createToggle(espContent, "头部圆圈", ESPConfig.showHeadCircle, function(val) ESPConfig.showHeadCircle = val end)
    createToggle(espContent, "队伍检测 (同队不显示)", ESPConfig.teamCheck, function(val) ESPConfig.teamCheck = val; AimConfig.teamCheck = val end)
    createToggle(espContent, "夜视", NightVision.enabled, function(val) if val then StartNightVision() else StopNightVision() end end)
    createToggle(espContent, "热能透视", ThermalESP.enabled, function(val)
        ThermalESP.enabled = val
        if val then SetupThermalEvents(); UpdateThermalESP() else for _, h in pairs(ThermalESP.highlights) do if h then h:Destroy() end end; ThermalESP.highlights = {} end
    end)
    
    local thermalColorFrame = Instance.new("Frame")
    thermalColorFrame.Size = UDim2.new(1,0,0,90)
    thermalColorFrame.BackgroundTransparency = 1
    thermalColorFrame.Parent = espContent
    createColorPicker(thermalColorFrame, "热能透视颜色", ThermalESP.colorMode, ThermalESP.color,
        function(m) ThermalESP.colorMode = m; UpdateThermalESP() end,
        function(c) ThermalESP.color = c; UpdateThermalESP() end)
    
    local esp2Group, esp2Content = createGroup("✨ ESP2 (GIT风格)")
    createToggle(esp2Content, "ESP2 总开关", ESP2_Settings.Enabled, function(val) SetESP2Enabled(val) end)
    createToggle(esp2Content, "显示方框", ESP2_Settings.ShowBox, function(val) ESP2_Settings.ShowBox = val end)
    createToggle(esp2Content, "显示名字", ESP2_Settings.ShowName, function(val) ESP2_Settings.ShowName = val end)
    createToggle(esp2Content, "显示血量", ESP2_Settings.ShowHealth, function(val) ESP2_Settings.ShowHealth = val end)
    createToggle(esp2Content, "上色 (Chams)", ESP2_Settings.ShowChams, function(val) ESP2_Settings.ShowChams = val end)
    createToggle(esp2Content, "队伍检测", ESP2_Settings.TeamCheck, function(val) ESP2_Settings.TeamCheck = val end)
    createNumberInput(esp2Content, "最大距离", 50, 5000, ESP2_Settings.MaxDistance, function(val) ESP2_Settings.MaxDistance = val end)
    
    local particleGroup, particleContent = createGroup("🎨 粒子特效设置")
    createDropdown(particleContent, "粒子形状", ParticleShapes, ParticleConfig.shape, function(choice) ParticleConfig.shape = choice end)
    createNumberInput(particleContent, "粒子数量", 5, 20, ParticleConfig.count, function(val) ParticleConfig.count = val end)
    createNumberInput(particleContent, "粒子大小(px)", 5, 30, ParticleConfig.size, function(val) ParticleConfig.size = val end)
    local particleColorFrame = Instance.new("Frame")
    particleColorFrame.Size = UDim2.new(1,0,0,90)
    particleColorFrame.BackgroundTransparency = 1
    particleColorFrame.Parent = particleContent
    createColorPicker(particleColorFrame, "粒子颜色", ParticleConfig.colorMode, ParticleConfig.colorFixed,
        function(m) ParticleConfig.colorMode = m end,
        function(c) ParticleConfig.colorFixed = c end)
    
    local colorGroup, colorContent = createGroup("🎨 颜色设置")
    createColorPicker(colorContent, "自瞄圈圈颜色", AimConfig.fovcolorMode, AimConfig.fovcolorFixed,
        function(m) AimConfig.fovcolorMode = m; refreshAllColors() end,
        function(c) AimConfig.fovcolorFixed = c; refreshAllColors() end)
    createColorPicker(colorContent, "自瞄文字颜色", AimConfig.textColorMode, AimConfig.textColorFixed,
        function(m) AimConfig.textColorMode = m; refreshAllColors() end,
        function(c) AimConfig.textColorFixed = c; refreshAllColors() end)
    createColorPicker(colorContent, "自瞄红线颜色", AimConfig.lineColorMode, AimConfig.lineColorFixed,
        function(m) AimConfig.lineColorMode = m; refreshAllColors() end,
        function(c) AimConfig.lineColorFixed = c; refreshAllColors() end)
    createColorPicker(colorContent, "ESP方框颜色", AimConfig.espBoxColorMode, AimConfig.espBoxColorFixed,
        function(m) AimConfig.espBoxColorMode = m; refreshAllColors() end,
        function(c) AimConfig.espBoxColorFixed = c; refreshAllColors() end)
    createColorPicker(colorContent, "ESP天线颜色", AimConfig.espTracerColorMode, AimConfig.espTracerColorFixed,
        function(m) AimConfig.espTracerColorMode = m; refreshAllColors() end,
        function(c) AimConfig.espTracerColorFixed = c; refreshAllColors() end)
    createColorPicker(colorContent, "ESP头部圆圈颜色", AimConfig.espHeadCircleColorMode, AimConfig.espHeadCircleColorFixed,
        function(m) AimConfig.espHeadCircleColorMode = m; refreshAllColors() end,
        function(c) AimConfig.espHeadCircleColorFixed = c; refreshAllColors() end)
    createColorPicker(colorContent, "ESP2 方框颜色", ESP2_Settings.BoxColorMode, ESP2_Settings.BoxColor,
        function(m) ESP2_Settings.BoxColorMode = m end,
        function(c) ESP2_Settings.BoxColor = c end)
    createColorPicker(colorContent, "ESP2 名字颜色", ESP2_Settings.NameColorMode, ESP2_Settings.NameColor,
        function(m) ESP2_Settings.NameColorMode = m end,
        function(c) ESP2_Settings.NameColor = c end)
    createColorPicker(colorContent, "ESP2 血量颜色", ESP2_Settings.HealthBarColorMode, ESP2_Settings.HealthBarColor,
        function(m) ESP2_Settings.HealthBarColorMode = m end,
        function(c) ESP2_Settings.HealthBarColor = c end)
    
    local panelGroup, panelContent = createGroup("📐 面板调试")
    createToggle(panelContent, "启用小窗人物信息", PanelConfig.enabled, function(val)
        PanelConfig.enabled = val
        if not val and TargetInfo.Panel then
            TargetInfo.IsVisible = false
            TargetInfo.Panel.Visible = false
            ClearAllParticles()
        end
    end)
    createToggle(panelContent, "灵动岛模式", PanelConfig.dynamicIslandEnabled, function(val)
        PanelConfig.dynamicIslandEnabled = val
        if not val then
            if self.gui then self.gui:Destroy() end
            self.gui = nil
        else
            self:Create()
            self:HideMenu()
        end
    end)
end

function Island:ShowMenu()
    if not PanelConfig.dynamicIslandEnabled or self.isMenuOpen then return end
    self.isMenuOpen = true
    
    self:BuildSettingsPanel()
    
    if self.targetTween then self.targetTween:Cancel() end
    self.targetTween = self.tweenService:Create(self.targetFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 0, 1, 0) })
    self.targetTween:Play()
    self.targetTween.Completed:Connect(function()
        self.targetFrame.Visible = false
    end)
    
    local vs = workspace.CurrentCamera.ViewportSize
    local menuWidth = math.min(vs.X * 0.9, 420)
    local menuHeight = math.min(vs.Y * 0.8, 600)
    
    self.tweenService:Create(self.container, self.animInfo, { Size = UDim2.new(0, menuWidth, 0, menuHeight), Position = UDim2.new(0.5, -menuWidth/2, 0, 0) }):Play()
    self.tweenService:Create(self.corner, self.animInfo, { CornerRadius = UDim.new(0, 16) }):Play()
    self.titleButton.Size = UDim2.new(1, 0, 0, 40)
    self.innerFrame.Visible = true
    self.titleButton.Text = "⚡ Antibot 设置菜单"
end

function Island:HideMenu()
    if not self.isMenuOpen then return end
    self.isMenuOpen = false
    self.innerFrame.Visible = false
    
    local hideTween = self.tweenService:Create(self.container, self.animInfo, { Size = UDim2.new(0, 160, 0, 40), Position = UDim2.new(0.5, -80, 0, 0) })
    hideTween:Play()
    
    self.tweenService:Create(self.corner, self.animInfo, { CornerRadius = UDim.new(0, 20) }):Play()
    self.titleButton.Size = UDim2.new(1, 0, 1, 0)
    
    hideTween.Completed:Connect(function()
        self.titleButton.Text = "⚡ Antibot | FPS: " .. self.fpsCounter.fps
        self.targetFrame.Visible = true
        self.lastExtraWidth = -1
        self:UpdateTarget(true)
    end)
end

function Island:ToggleMenu()
    if self.isMenuOpen then
        self:HideMenu()
    else
        self:ShowMenu()
    end
end

function Island:UpdateTarget(force)
    if not PanelConfig.dynamicIslandEnabled or self.isMenuOpen then
        return
    end
    local target = GetBestTargetInFOV()
    local hasTarget = target and IsAlive(target) and (not AimConfig.teamCheck or not IsSameTeam(target))
    local name, hp, extraWidth = "", 0, 0
    if hasTarget then
        name = target.DisplayName or target.Name
        hp = target.Character and target.Character:FindFirstChild("Humanoid") and math.floor(target.Character.Humanoid.Health) or 0
        self.targetLabel.Text = string.format("🎯 %s  ❤%d", name, hp)
        local textSize = game:GetService("TextService"):GetTextSize(self.targetLabel.Text, self.targetLabel.TextSize, self.targetLabel.Font, Vector2.new(400, 40))
        extraWidth = math.clamp(textSize.X + 30, 80, 200)
    else
        self.targetLabel.Text = ""
        extraWidth = 0
    end
    
    local targetChanged = (self.lastTarget ~= target) or force
    local widthChanged = math.abs(self.lastExtraWidth - extraWidth) > 5 or force
    
    if targetChanged or widthChanged then
        local newWidth = 160 + extraWidth
        if self.activeTween then self.activeTween:Cancel() end
        self.activeTween = self.tweenService:Create(self.container, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.new(0, newWidth, 0, 40), Position = UDim2.new(0.5, -newWidth/2, 0, 0) })
        self.activeTween:Play()
        
        if self.targetTween then self.targetTween:Cancel() end
        self.targetTween = self.tweenService:Create(self.targetFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.new(0, extraWidth, 1, 0) })
        self.targetTween:Play()
    end
    
    self.lastTarget = target
    self.lastExtraWidth = extraWidth
end

function Island:UpdateFPS()
    local counter = self.fpsCounter
    local now = tick()
    counter.frameCount = counter.frameCount + 1
    if now - counter.lastTime >= 0.5 then
        counter.fps = math.floor(counter.frameCount / (now - counter.lastTime))
        counter.frameCount = 0
        counter.lastTime = now
    end
    if not self.isMenuOpen then
        self.titleButton.Text = "⚡ Antibot | FPS: " .. counter.fps
    end
end

-- 创建灵动岛
Island:Create()
Island:HideMenu()

-- ==================== 主渲染循环（修复红线残留） ====================
game:GetService("RunService").RenderStepped:Connect(function()
    -- 自瞄主逻辑：只有满足激活条件才执行
    if AimConfig.fovlookAt and ShouldAim() then
        if AimFOVCircle and AimConfig.fovcolorMode ~= "固定" then AimFOVCircle.Color = getDynamicColor(AimConfig.fovcolorMode) end
        if AimRedLine and AimConfig.lineColorMode ~= "固定" then AimRedLine.Color = getDynamicColor(AimConfig.lineColorMode) end
        for _, t in pairs(AimTextDrawings) do
            if t.drawing and AimConfig.textColorMode ~= "固定" then t.drawing.Color = getDynamicColor(AimConfig.textColorMode) end
        end
        if AimConfig.aimMode == "AI" then AimAI() else AimFunction() end
        UpdateAimFOVTargetsInfo()
        UpdateAimLockLine()
    else
        -- 未激活时，彻底清除所有自瞄绘制，防止残留
        if AimRedLine then AimRedLine.Visible = false end
        if AimFOVLine1 then AimFOVLine1.Visible = false end
        ClearAimTextDrawings()
    end
    
    -- ESP 渲染
    if ESPConfig.enabled then
        for _, d in pairs(ESPDrawings) do
            if d.box and ESPConfig.showBox and AimConfig.espBoxColorMode ~= "固定" then d.box.Color = getDynamicColor(AimConfig.espBoxColorMode) end
            if d.tracer and ESPConfig.showTracer and AimConfig.espTracerColorMode ~= "固定" then d.tracer.Color = getDynamicColor(AimConfig.espTracerColorMode) end
            if d.headCircle and ESPConfig.showHeadCircle and AimConfig.espHeadCircleColorMode ~= "固定" then d.headCircle.Color = getDynamicColor(AimConfig.espHeadCircleColorMode) end
        end
        UpdateESP()
    else
        for p, _ in pairs(ESPDrawings) do DestroyESPForPlayer(p) end
    end
    
    if ThermalESP.enabled then UpdateThermalESP() end
    
    if PanelConfig.dynamicIslandEnabled and Island.container then
        Island:UpdateFPS()
        Island:UpdateTarget()
    end
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "V3.0 加载成功",
    Text = "b站有点微醺啊",
    Duration = 7
})