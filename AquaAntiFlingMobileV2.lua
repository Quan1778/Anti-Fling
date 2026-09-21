local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local GUI_NAME = "Anti Fling Mobile"

pcall(function()
    local old = CoreGui:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end)

local Settings = {
    Enabled = true,
    Recovery = true,
    SafePosition = true,
    StateRecovery = true,
    TouchProtection = false,
    MaxHorizontalSpeed = 85,
    MaxVerticalSpeed = 125,
    MaxAngularSpeed = 55,
    MaxDeltaDistance = 28,
    SafeVelocity = 12,
    RecoveryCooldown = 0.12,
    SaveInterval = 0.18
}

local State = {
    Character = nil,
    Humanoid = nil,
    Root = nil,
    SafeCFrame = nil,
    SpawnCFrame = nil,
    LastPosition = nil,
    LastSafeSave = 0,
    LastRecovery = 0
}

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

local function GetCharacter()
    local Character = LocalPlayer.Character
    if not Character then return end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Root = Character:FindFirstChild("HumanoidRootPart")

    if not Humanoid or not Root or Humanoid.Health <= 0 then return end
    return Character, Humanoid, Root
end

local function HardStop(Root)
    Root.AssemblyLinearVelocity = Vector3.zero
    Root.AssemblyAngularVelocity = Vector3.zero
    pcall(function()
        Root.Velocity = Vector3.zero
        Root.RotVelocity = Vector3.zero
    end)
end

local function Grounded(Humanoid)
    return Humanoid.FloorMaterial ~= Enum.Material.Air
end

local function SaveSafePosition()
    if not Settings.SafePosition then return end

    local Character, Humanoid, Root = GetCharacter()
    if not Character or not Grounded(Humanoid) then return end

    local Velocity = Root.AssemblyLinearVelocity
    local Angular = Root.AssemblyAngularVelocity

    if Velocity.Magnitude > Settings.SafeVelocity then return end
    if Angular.Magnitude > Settings.SafeVelocity then return end

    local Now = os.clock()
    if Now - State.LastSafeSave < Settings.SaveInterval then return end

    State.SafeCFrame = Root.CFrame
    State.LastSafeSave = Now
end

local function IsFlinging()
    local Character, Humanoid, Root = GetCharacter()
    if not Character then return false end

    local Velocity = Root.AssemblyLinearVelocity
    local Angular = Root.AssemblyAngularVelocity

    local Horizontal = Vector3.new(Velocity.X, 0, Velocity.Z).Magnitude
    local Vertical = math.abs(Velocity.Y)

    if Horizontal >= Settings.MaxHorizontalSpeed then return true end
    if Vertical >= Settings.MaxVerticalSpeed then return true end
    if Angular.Magnitude >= Settings.MaxAngularSpeed then return true end

    if State.LastPosition then
        local Distance = (Root.Position - State.LastPosition).Magnitude
        if Distance >= Settings.MaxDeltaDistance then return true end
    end

    if Humanoid.PlatformStand and Velocity.Magnitude > Settings.SafeVelocity then
        return true
    end

    return false
end

local function RecoverCharacter()
    if not Settings.Recovery then return end

    local Character, Humanoid, Root = GetCharacter()
    if not Character then return end

    local Now = os.clock()
    if Now - State.LastRecovery < Settings.RecoveryCooldown then return end

    local Target = State.SafeCFrame or State.SpawnCFrame

    if Target then
        pcall(function()
            Root.CFrame = Target
        end)
    end

    HardStop(Root)

    if Settings.StateRecovery then
        pcall(function()
            Humanoid.PlatformStand = false
            Humanoid.AutoRotate = true

            local CurrentState = Humanoid:GetState()
            if CurrentState == Enum.HumanoidStateType.Physics
                or CurrentState == Enum.HumanoidStateType.Ragdoll
                or CurrentState == Enum.HumanoidStateType.FallingDown
                or CurrentState == Enum.HumanoidStateType.PlatformStanding then
                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end

    State.LastRecovery = Now
end

local function ApplyTouchProtection(Character)
    if not Settings.TouchProtection then return end

    for _, Object in ipairs(Character:GetDescendants()) do
        if Object:IsA("BasePart") then
            pcall(function()
                Object.CanTouch = false
            end)
        end
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Scale = Instance.new("UIScale")
Scale.Parent = ScreenGui

local function UpdateScale()
    local Camera = Workspace.CurrentCamera
    if not Camera then return end

    local Viewport = Camera.ViewportSize
    local Base = math.min(Viewport.X / 390, Viewport.Y / 780)
    Scale.Scale = math.clamp(Base, 0.78, 1.12)
end

UpdateScale()
pcall(function()
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
end)

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(330, 470)
Main.Position = UDim2.new(0.5, -165, 0.5, -235)
Main.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 18)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 210, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.2
MainStroke.Parent = Main

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 68)
Top.BackgroundColor3 = Color3.fromRGB(17, 23, 34)
Top.BorderSizePixel = 0
Top.Active = true
Top.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 18)
TopCorner.Parent = Top

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -105, 0, 30)
Title.Position = UDim2.fromOffset(18, 9)
Title.BackgroundTransparency = 1
Title.Text = "AQUA ANTI FLING"
Title.TextColor3 = Color3.fromRGB(115, 230, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -105, 0, 20)
Status.Position = UDim2.fromOffset(18, 37)
Status.BackgroundTransparency = 1
Status.Text = "Protection enabled"
Status.TextColor3 = Color3.fromRGB(165, 180, 195)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Top

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(38, 38)
Minimize.Position = UDim2.new(1, -90, 0, 15)
Minimize.BackgroundColor3 = Color3.fromRGB(31, 42, 58)
Minimize.Text = "−"
Minimize.TextColor3 = Color3.fromRGB(220, 235, 245)
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 22
Minimize.AutoButtonColor = false
Minimize.Parent = Top

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 11)
MinCorner.Parent = Minimize

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(38, 38)
Close.Position = UDim2.new(1, -45, 0, 15)
Close.BackgroundColor3 = Color3.fromRGB(55, 31, 40)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 185, 195)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 22
Close.AutoButtonColor = false
Close.Parent = Top

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 11)
CloseCorner.Parent = Close

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -28, 1, -86)
Content.Position = UDim2.fromOffset(14, 78)
Content.BackgroundTransparency = 1
Content.Parent = Main

local function Button(text, y)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 0, 48)
    B.Position = UDim2.fromOffset(0, y)
    B.BackgroundColor3 = Color3.fromRGB(25, 34, 48)
    B.BorderSizePixel = 0
    B.Text = text
    B.TextColor3 = Color3.fromRGB(225, 240, 248)
    B.Font = Enum.Font.GothamBold
    B.TextSize = 14
    B.AutoButtonColor = false
    B.Parent = Content

    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, 12)
    C.Parent = B

    local S = Instance.new("UIStroke")
    S.Color = Color3.fromRGB(52, 80, 101)
    S.Transparency = 0.35
    S.Parent = B

    B.MouseEnter:Connect(function()
        TweenService:Create(B, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(31, 48, 66)
        }):Play()
    end)

    B.MouseLeave:Connect(function()
        TweenService:Create(B, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(25, 34, 48)
        }):Play()
    end)

    return B
end

local Master = Button("ANTI FLING  •  ON", 0)
Master.BackgroundColor3 = Color3.fromRGB(0, 150, 205)

local Recovery = Button("AUTO RECOVERY  •  ON", 58)
local Safe = Button("SAFE POSITION  •  ON", 116)
local StateRecovery = Button("STATE RECOVERY  •  ON", 174)
local TouchProtection = Button("TOUCH PROTECTION  •  OFF", 232)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, 0, 0, 70)
Info.Position = UDim2.fromOffset(0, 290)
Info.BackgroundColor3 = Color3.fromRGB(17, 24, 35)
Info.BorderSizePixel = 0
Info.Text = "Detection\nH 85   V 125   R 55\nRecovery distance 28 studs"
Info.TextColor3 = Color3.fromRGB(175, 195, 210)
Info.Font = Enum.Font.Gotham
Info.TextSize = 13
Info.Parent = Content

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 12)
InfoCorner.Parent = Info

local RecoverNow = Button("RECOVER NOW", 368)
RecoverNow.BackgroundColor3 = Color3.fromRGB(0, 120, 170)

local Bubble = Instance.new("TextButton")
Bubble.Size = UDim2.fromOffset(62, 62)
Bubble.Position = UDim2.new(0, 18, 0.5, -31)
Bubble.BackgroundColor3 = Color3.fromRGB(8, 126, 174)
Bubble.BorderSizePixel = 0
Bubble.Text = "A"
Bubble.TextColor3 = Color3.fromRGB(235, 250, 255)
Bubble.Font = Enum.Font.GothamBlack
Bubble.TextSize = 25
Bubble.Visible = false
Bubble.Active = true
Bubble.Parent = ScreenGui

local BubbleCorner = Instance.new("UICorner")
BubbleCorner.CornerRadius = UDim.new(1, 0)
BubbleCorner.Parent = Bubble

local BubbleStroke = Instance.new("UIStroke")
BubbleStroke.Color = Color3.fromRGB(110, 235, 255)
BubbleStroke.Thickness = 2
BubbleStroke.Parent = Bubble

local dragging = false
local dragInput
local dragStart
local startPosition

local function BeginDrag(input, object)
    dragging = true
    dragInput = input
    dragStart = input.Position
    startPosition = object.Position

    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
        end
    end)
end

local function ConnectDrag(object)
    object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            BeginDrag(input, object)
        end
    end)

    object.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            object.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

ConnectDrag(Top)
ConnectDrag(Bubble)

local function ToggleButton(button, label, value)
    button.Text = label .. (value and "  •  ON" or "  •  OFF")
    button.BackgroundColor3 = value
        and Color3.fromRGB(25, 78, 98)
        or Color3.fromRGB(25, 34, 48)
end

Master.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    Master.Text = Settings.Enabled and "ANTI FLING  •  ON" or "ANTI FLING  •  OFF"
    Master.BackgroundColor3 = Settings.Enabled
        and Color3.fromRGB(0, 150, 205)
        or Color3.fromRGB(60, 68, 80)
    Status.Text = Settings.Enabled and "Protection enabled" or "Protection disabled"
end)

Recovery.MouseButton1Click:Connect(function()
    Settings.Recovery = not Settings.Recovery
    ToggleButton(Recovery, "AUTO RECOVERY", Settings.Recovery)
end)

Safe.MouseButton1Click:Connect(function()
    Settings.SafePosition = not Settings.SafePosition
    ToggleButton(Safe, "SAFE POSITION", Settings.SafePosition)
end)

StateRecovery.MouseButton1Click:Connect(function()
    Settings.StateRecovery = not Settings.StateRecovery
    ToggleButton(StateRecovery, "STATE RECOVERY", Settings.StateRecovery)
end)

TouchProtection.MouseButton1Click:Connect(function()
    Settings.TouchProtection = not Settings.TouchProtection
    ToggleButton(TouchProtection, "TOUCH PROTECTION", Settings.TouchProtection)
end)

RecoverNow.MouseButton1Click:Connect(function()
    RecoverCharacter()
end)

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    Bubble.Visible = true
end)

Bubble.MouseButton1Click:Connect(function()
    Bubble.Visible = false
    Main.Visible = true
end)

Close.MouseButton1Click:Connect(function()
    Settings.Enabled = false
    ScreenGui:Destroy()
end)

local function SetupCharacter(Character)
    State.Character = Character
    State.Humanoid = Character:WaitForChild("Humanoid", 10)
    State.Root = Character:WaitForChild("HumanoidRootPart", 10)

    if State.Root then
        State.SpawnCFrame = State.Root.CFrame
        State.SafeCFrame = State.Root.CFrame
        State.LastPosition = State.Root.Position
    end
end

if LocalPlayer.Character then
    task.spawn(SetupCharacter, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(Character)
    State.SafeCFrame = nil
    State.SpawnCFrame = nil
    State.LastPosition = nil
    State.LastSafeSave = 0
    State.LastRecovery = 0
    task.spawn(SetupCharacter, Character)
end)

local Timer = 0

RunService.Heartbeat:Connect(function(dt)
    Timer += dt
    if Timer < 0.04 then return end
    Timer = 0

    local Character, Humanoid, Root = GetCharacter()
    if not Character then return end

    if Settings.Enabled then
        if IsFlinging() then
            HardStop(Root)
            RecoverCharacter()
            Status.Text = "Fling detected • recovering"

            task.delay(0.35, function()
                if ScreenGui.Parent and Settings.Enabled then
                    Status.Text = "Protection enabled"
                end
            end)
        else
            SaveSafePosition()
        end

        ApplyTouchProtection(Character)
    end

    State.LastPosition = Root.Position
end)

Notify("Aqua Anti Fling", "Mobile protection đã được bật")
