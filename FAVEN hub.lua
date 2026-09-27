--========================================================--
--                     FAVEN HUB
--========================================================--

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
--                       WINDOW
--========================================================--

local window = Rayfield:CreateWindow({
    name = "Faven Hub",
    subtitle = "FAVEN Hub",
    sidebarLayout = true,
})

local visualTab = window:CreateTab({
    name = "Visual",
    icon = 109164844929627
})

local geneTab = window:CreateTab({
    name = "Gen",
    icon = 109164844929627
})

local parryTab = window:CreateTab({
    name = "Parry",
    icon = 109164844929627
})

--========================================================--
--                     PLAYER ESP
--========================================================--

local ESPEnabled = false
local ESPConnections = {}
local ESPObjects = {}

local function removeESP(player)
    local object = ESPObjects[player]

    if object then
        pcall(function()
            object:Destroy()
        end)
        ESPObjects[player] = nil
    end

    local connection = ESPConnections[player]

    if connection then
        pcall(function()
            connection:Disconnect()
        end)
        ESPConnections[player] = nil
    end
end

local function createPlayerESP(player, character)
    if player == LocalPlayer or not character then
        return
    end

    removeESP(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP"
    highlight.FillTransparency = 0.5
    highlight.FillColor = Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    local teamName = ""

    pcall(function()
        teamName = string.lower(player.Team and player.Team.Name or "")
    end)

    if string.find(teamName, "killer") then
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    else
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    end

    highlight.Adornee = character
    highlight.Parent = character

    ESPObjects[player] = highlight
end

local function setupPlayerESP(player)
    if player == LocalPlayer then
        return
    end

    removeESP(player)

    if player.Character then
        createPlayerESP(player, player.Character)
    end

    ESPConnections[player] = player.CharacterAdded:Connect(function(character)
        if ESPEnabled then
            task.wait(0.2)
            createPlayerESP(player, character)
        end
    end)
end

local function enableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayerESP(player)
    end
end

local function disableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        removeESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if ESPEnabled then
        setupPlayerESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

visualTab:CreateToggle({
    name = "Esp",
    currentValue = false,

    callback = function(value)
        ESPEnabled = value

        if value then
            enableESP()
        else
            disableESP()
        end
    end,
})

--========================================================--
--                  GENERATOR ESP
--========================================================--

local GeneratorESPEnabled = false
local GeneratorObjects = {}

local function isGenerator(object)
    return object:IsA("Model")
        and string.find(string.lower(object.Name), "generator") ~= nil
end

local function convertPercent(value)
    if typeof(value) == "number" then
        if value <= 1 then
            value = value * 100
        end

        return math.clamp(math.floor(value + 0.5), 0, 100)
    end

    if typeof(value) == "string" then
        local number = tonumber(value:match("(%d+%.?%d*)"))

        if number then
            if number <= 1 then
                number = number * 100
            end

            return math.clamp(math.floor(number + 0.5), 0, 100)
        end
    end

    return 0
end

local function getGeneratorPercent(generator)
    local attributes = {
        "Progress",
        "progress",
        "Percentage",
        "percentage",
        "Percent",
        "percent",
        "RepairProgress",
        "repairProgress"
    }

    for _, attribute in ipairs(attributes) do
        local value = generator:GetAttribute(attribute)

        if value ~= nil then
            return convertPercent(value)
        end
    end

    for _, descendant in ipairs(generator:GetDescendants()) do
        if descendant:IsA("NumberValue")
            or descendant:IsA("IntValue") then

            local name = string.lower(descendant.Name)

            if string.find(name, "progress")
                or string.find(name, "percent")
                or string.find(name, "repair") then

                return convertPercent(descendant.Value)
            end
        end
    end

    return 0
end

local function getGeneratorPart(generator)
    if generator.PrimaryPart then
        return generator.PrimaryPart
    end

    return generator:FindFirstChildWhichIsA("BasePart", true)
end

local function getTopGenerator(generator)
    local part = getGeneratorPart(generator)

    if not part then
        return nil
    end

    return part.Position + Vector3.new(0, 4, 0)
end

local function removeGeneratorESP(generator)
    local data = GeneratorObjects[generator]

    if data then
        if data.highlight then
            pcall(function()
                data.highlight:Destroy()
            end)
        end

        if data.billboard then
            pcall(function()
                data.billboard:Destroy()
            end)
        end

        GeneratorObjects[generator] = nil
    end
end

local function createGeneratorESP(generator)
    if not GeneratorESPEnabled or not generator then
        return
    end

    removeGeneratorESP(generator)

    local part = getGeneratorPart(generator)

    if not part then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "GeneratorESP"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = generator
    highlight.Parent = generator

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GeneratorPercentage"
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(45, 15)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 0
    billboard.Parent = part

    local text = Instance.new("TextLabel")
    text.Name = "Percentage"
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1, 1)
    text.Text = "0%"
    text.TextScaled = false
    text.TextSize = 14
    text.Font = Enum.Font.GothamBold
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.Parent = billboard

    GeneratorObjects[generator] = {
        highlight = highlight,
        billboard = billboard,
        text = text
    }
end

local function scanGenerators()
    for _, object in ipairs(workspace:GetDescendants()) do
        if isGenerator(object) then
            createGeneratorESP(object)
        end
    end
end

local function disableGeneratorESP()
    for generator in pairs(GeneratorObjects) do
        removeGeneratorESP(generator)
    end
end

workspace.DescendantAdded:Connect(function(object)
    if GeneratorESPEnabled and isGenerator(object) then
        task.wait(0.1)

        if object.Parent then
            createGeneratorESP(object)
        end
    end
end)

visualTab:CreateToggle({
    name = "ESP Gene",
    currentValue = false,

    callback = function(value)
        GeneratorESPEnabled = value

        if value then
            scanGenerators()
        else
            disableGeneratorESP()
        end
    end,
})

--========================================================--
--                GENERATOR UPDATE LOOP
--========================================================--

RunService.RenderStepped:Connect(function()
    if not GeneratorESPEnabled then
        return
    end

    for generator, data in pairs(GeneratorObjects) do
        if not generator or not generator.Parent then
            removeGeneratorESP(generator)
            continue
        end

        if data.text then
            local percent = getGeneratorPercent(generator)
            data.text.Text = tostring(percent) .. "%"
        end

        local part = getGeneratorPart(generator)

        if part and data.billboard then
            data.billboard.Adornee = part
        end
    end
end)

--========================================================--
--                  AUTO GENERATOR
--========================================================--

local AutoGeneratorEnabled = false

-- Mode:
-- SUCCESS = menekan saat posisi line berada di area goal
-- NEUTRAL = menekan saat skill check tersedia
-- INSTANT = langsung menekan saat skill check muncul

local GeneratorMode = "SUCCESS"

local function getSkillCheckGui()
    local gui = PlayerGui:FindFirstChild("SkillCheckPromptGui")

    if not gui then
        gui = PlayerGui:FindFirstChild("SkillCheckPromptGui", true)
    end

    return gui
end

local function getSkillCheckButton()
    local gui = getSkillCheckGui()

    if not gui then
        return nil
    end

    local action = gui:FindFirstChild("action", true)

    if action and action:IsA("GuiButton") then
        return action
    end

    local button = gui:FindFirstChildWhichIsA("GuiButton", true)

    return button
end

local function getGuiObjectCenter(guiObject)
    if not guiObject or not guiObject:IsA("GuiObject") then
        return nil
    end

    local position = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize

    return position.X + size.X / 2,
           position.Y + size.Y / 2
end

local function isLineInsideGoal(line, goal)
    if not line or not goal then
        return false
    end

    if not line:IsA("GuiObject") or not goal:IsA("GuiObject") then
        return false
    end

    local lineX = line.AbsolutePosition.X
    local lineWidth = line.AbsoluteSize.X

    local goalX = goal.AbsolutePosition.X
    local goalWidth = goal.AbsoluteSize.X

    local lineCenter = lineX + lineWidth / 2
    local goalStart = goalX
    local goalEnd = goalX + goalWidth

    return lineCenter >= goalStart
        and lineCenter <= goalEnd
end

local function pressSkillCheck()
    local gui = getSkillCheckGui()

    if not gui then
        return false
    end

    local button = getSkillCheckButton()

    if not button then
        return false
    end

    local line = gui:FindFirstChild("Line", true)
    local goal = gui:FindFirstChild("Goal", true)

    if GeneratorMode == "SUCCESS" then
        if line and goal then
            if not isLineInsideGoal(line, goal) then
                return false
            end
        end
    elseif GeneratorMode == "NEUTRAL" then
        -- Tekan saat skill check tersedia.
    elseif GeneratorMode == "INSTANT" then
        -- Tekan langsung.
    end

    pcall(function()
        firesignal(button.MouseButton1Down)
    end)

    return true
end

local function findActionButton()
    local survivorMob = PlayerGui:FindFirstChild("Survivor-mob")

    if not survivorMob then
        return nil
    end

    local controls = survivorMob:FindFirstChild("Controls")

    if not controls then
        return nil
    end

    local action = controls:FindFirstChild("action", true)

    if action and action:IsA("GuiButton") then
        return action
    end

    return nil
end

task.spawn(function()
    while task.wait(0.025) do
        if AutoGeneratorEnabled then
            local gui = getSkillCheckGui()

            if gui then
                pressSkillCheck()
            end

            local actionButton = findActionButton()

            if actionButton then
                pcall(function()
                    firesignal(actionButton.MouseButton1Down)
                end)
            end
        end
    end
end)

geneTab:CreateToggle({
    name = "Auto Generator",
    currentValue = false,

    callback = function(value)
        AutoGeneratorEnabled = value
    end,
})

geneTab:CreateDropdown({
    name = "Generator Mode",
    options = {
        "SUCCESS",
        "NEUTRAL",
        "INSTANT"
    },
    currentOption = {"SUCCESS"},

    callback = function(option)
        if typeof(option) == "table" then
            GeneratorMode = option[1] or "SUCCESS"
        else
            GeneratorMode = option
        end
    end,
})

--========================================================--
--                    AUTO PARRY
--========================================================--

local AutoParryEnabled = false
local RangeVisualEnabled = false
local ParryRange = 16

local LocalCharacter
local LocalRoot
local GuiMob

local KillerData = {}

local AttackAnimations = {
    ["139369275981139"] = true,
    ["121216847022485"] = true,
    ["78935059863801"] = true,
    ["74968262036854"] = true,
    ["82666958311998"] = true,
    ["78432063483146"] = true,
    ["132817836308238"] = true,
    ["111920872708571"] = true,
    ["138720291317243"] = true,
    ["130593238885843"] = true,
    ["106871536134254"] = true,
    ["109402730355822"] = true,
}

local Attacking = false

--========================================================--
--                     RANGE VISUAL
--========================================================--

local RangeRing = Instance.new("CylinderHandleAdornment")

RangeRing.Name = "ParryRange"
RangeRing.Height = 0.15
RangeRing.Radius = ParryRange
RangeRing.Transparency = 1
RangeRing.AlwaysOnTop = true

-- Tetap lingkaran mendatar,
-- tetapi posisinya diturunkan ke kaki.
RangeRing.CFrame =
    CFrame.new(0, -2.8, 0) *
    CFrame.Angles(math.rad(90), 0, 0)

RangeRing.Parent = workspace

--========================================================--
--                  LOCAL CHARACTER
--========================================================--

local function UpdateLocalCharacter()
    LocalCharacter = LocalPlayer.Character

    if LocalCharacter then
        LocalRoot = LocalCharacter:FindFirstChild("HumanoidRootPart")

        if LocalRoot then
            RangeRing.Adornee = LocalRoot

            RangeRing.CFrame =
                CFrame.new(0, -2.8, 0) *
                CFrame.Angles(math.rad(90), 0, 0)
        end
    end
end

--========================================================--
--                       GUI MOB
--========================================================--

local function GetGuiMob()
    GuiMob = nil

    local survivorMob = PlayerGui:FindFirstChild("Survivor-mob")

    if not survivorMob then
        return nil
    end

    local controls = survivorMob:FindFirstChild("Controls")

    if not controls then
        return nil
    end

    GuiMob = controls:FindFirstChild("Gui-mob")

    return GuiMob
end

local function TriggerParry()
    if not GuiMob then
        GetGuiMob()
    end

    if not GuiMob then
        return
    end

    local button = GuiMob:FindFirstChildWhichIsA("GuiButton", true)

    if button then
        pcall(function()
            firesignal(button.MouseButton1Down)
        end)
    end
end

--========================================================--
--                    KILLER DETECTION
--========================================================--

local function GetRoot(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function IsKiller(character)
    if not character then
        return false
    end

    return character:FindFirstChild("Lookscriptkiller", true) ~= nil
end

local function DisconnectKiller(character)
    local data = KillerData[character]

    if not data then
        return
    end

    if data.connection then
        pcall(function()
            data.connection:Disconnect()
        end)
    end

    KillerData[character] = nil
end

local function WatchKiller(character)
    if not character or character == LocalCharacter then
        return
    end

    if KillerData[character] then
        return
    end

    if not IsKiller(character) then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")

    if not animator then
        animator = humanoid:WaitForChild("Animator", 2)
    end

    if not animator then
        return
    end

    local data = {
        Root = GetRoot(character),
        connection = nil
    }

    data.connection = animator.AnimationPlayed:Connect(function(track)
        local animation = track.Animation

        if not animation then
            return
        end

        local id = tostring(animation.AnimationId)
        id = id:match("%d+")

        if not id or not AttackAnimations[id] then
            return
        end

        Attacking = true

        task.delay(0.3, function()
            Attacking = false
        end)

        if not AutoParryEnabled then
            return
        end

        if not LocalRoot then
            return
        end

        local root = GetRoot(character)

        if not root then
            return
        end

        local distance =
            (root.Position - LocalRoot.Position).Magnitude

        if distance <= ParryRange then
            TriggerParry()
        end
    end)

    KillerData[character] = data
end

local function ScanKillers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            WatchKiller(player.Character)
        end
    end
end

--========================================================--
--                  RANGE VISUAL UPDATE
--========================================================--

local function UpdateRangeVisual()
    if not AutoParryEnabled or not RangeVisualEnabled then
        RangeRing.Transparency = 1
        return
    end

    if not LocalRoot then
        RangeRing.Transparency = 1
        return
    end

    local killerInRange = false

    for character, data in pairs(KillerData) do
        if character and character.Parent then
            local root = data.Root or GetRoot(character)

            if root then
                data.Root = root

                local distance =
                    (root.Position - LocalRoot.Position).Magnitude

                if distance <= ParryRange then
                    killerInRange = true
                    break
                end
            end
        end
    end

    RangeRing.Radius = ParryRange
    RangeRing.Transparency = 0.35

    if killerInRange and Attacking then
        RangeRing.Color3 = Color3.fromRGB(255, 0, 0)
    else
        RangeRing.Color3 = Color3.fromRGB(0, 255, 0)
    end
end

--========================================================--
--                       PLAYER EVENTS
--========================================================--

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(1)

        if AutoParryEnabled then
            WatchKiller(character)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        DisconnectKiller(player.Character)
    end
end)

--========================================================--
--                       PARRY UI
--========================================================--

parryTab:CreateToggle({
    name = "Auto Parry",
    currentValue = false,

    callback = function(value)
        AutoParryEnabled = value

        if value then
            UpdateLocalCharacter()
            GetGuiMob()
            ScanKillers()
        else
            RangeRing.Transparency = 1
        end
    end,
})

parryTab:CreateSlider({
    name = "Parry Range",
    range = {1, 32},
    increment = 1,
    suffix = " studs",
    currentValue = ParryRange,

    callback = function(value)
        ParryRange = math.clamp(
            tonumber(value) or 16,
            1,
            32
        )

        RangeRing.Radius = ParryRange
    end,
})

parryTab:CreateToggle({
    name = "Range Visual",
    currentValue = false,

    callback = function(value)
        RangeVisualEnabled = value

        if not value or not AutoParryEnabled then
            RangeRing.Transparency = 1
        end
    end,
})

--========================================================--
--                    MAIN UPDATE LOOP
--========================================================--

RunService.RenderStepped:Connect(function()
    UpdateLocalCharacter()

    if AutoParryEnabled then
        GetGuiMob()
    end

    for character, data in pairs(KillerData) do
        if character and character.Parent then
            data.Root = GetRoot(character)
        else
            DisconnectKiller(character)
        end
    end

    UpdateRangeVisual()
end)

--========================================================--
--                    CHARACTER RESPAWN
--========================================================--

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)

    LocalCharacter = character
    LocalRoot = character:FindFirstChild("HumanoidRootPart")

    RangeRing.Adornee = LocalRoot

    if LocalRoot then
        RangeRing.CFrame =
            CFrame.new(0, -2.8, 0) *
            CFrame.Angles(math.rad(90), 0, 0)
    end

    if AutoParryEnabled then
        GetGuiMob()
        ScanKillers()
    end
end)

--========================================================--
--                         END
--========================================================--