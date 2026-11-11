-- ==========================================
-- KEREN HUB - BARISTA ULTIMATE PRO ROUTE
-- ==========================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Keren Hub ☕ | Pro Barista",
    Icon = "coffee",
    Author = "by Kenzo",
    Folder = "KerenBaristaProConfig",
    Transparent = false,
    Theme = "Dark"
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AntiAfkEnabled = false
local AutoBaristaEnabled = false
local InstantPromptEnabled = false
local AutoCleanEnabled = true
local baristaThread = nil

-- Menyimpan Token Aktif dari Game (Sesuai BaristaClient)
local CurrentToken = nil

local BaristaEvent = ReplicatedStorage:WaitForChild("BaristaAssets"):WaitForChild("Events"):WaitForChild("BaristaEvent")

-- Tangkap Token Otomatis dari Event Game
BaristaEvent.OnClientEvent:Connect(function(action, data)
    if action == "JobStarted" or action == "SpawnNPC" then
        if type(data) == "table" and data.Token then
            CurrentToken = data.Token
        end
    end
end)

-- Koordinat Sesuai Rute Presisi
local COORDS = {
    ShiftSpot     = CFrame.new(-4992.262, 4.287, -716.253),
    CoffeeMachine = CFrame.new(-4997.648, 4.287, -794.613),
    Customer      = CFrame.new(-4996.451, 4.287, -760.959)
}

local MainTab = Window:Tab({ Title = "Main", Icon = "zap" })
local FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "coffee" })

local MainSection = MainTab:Section({ Title = "Pengaturan Umum" })
local FarmSection = FarmTab:Section({ Title = "Barista Automation" })

-- LOGIC ANTI-AFK
task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        if AntiAfkEnabled then
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end)

-- INSTANT PROXIMITY PROMPT
task.spawn(function()
    while true do
        if InstantPromptEnabled then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, v in pairs(Workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") then
                            local part = v.Parent
                            local pos = part:IsA("Model") and part.PrimaryPart and part.PrimaryPart.Position or (part:IsA("BasePart") and part.Position)
                            if pos and (pos - hrp.Position).Magnitude <= 30 then
                                v.HoldDuration = 0
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- PILIH JOB BARISTA
local function selectBaristaJob()
    pcall(function()
        local Event = ReplicatedStorage:FindFirstChild("JobEvents") and ReplicatedStorage.JobEvents:FindFirstChild("TeamChangeRequest")
        if Event then
            Event:FireServer("Barista", 11378976, 1, 0, "Detector")
        end
    end)
end

-- TWEEN HALUS DENGAN SPEED 2 (SANGAT AMAN)
local function smoothMoveTo(targetCFrame)
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = 2 -- Kecepatan lambat anti-cheat
        local duration = distance / speed

        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        
        tween:Play()
        tween.Completed:Wait()
    end)
end

-- HELPER PROMPT
local function fireNearestPrompt()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Parent then
                local partPos = v.Parent:IsA("Model") and v.Parent.PrimaryPart and v.Parent.PrimaryPart.Position or (v.Parent:IsA("BasePart") and v.Parent.Position)
                if partPos and (partPos - hrp.Position).Magnitude <= 12 then
                    if fireproximityprompt then
                        fireproximityprompt(v)
                    else
                        v:InputHoldBegin()
                        task.wait(v.HoldDuration)
                        v:InputHoldEnd()
                    end
                    break
                end
            end
        end
    end)
end

-- SIKLUS UTAMA AUTO FARM BERDASARKAN REMOTE ASLI
local function startBaristaFarm()
    if baristaThread then task.cancel(baristaThread) end

    baristaThread = task.spawn(function()
        selectBaristaJob()
        WindUI:Notify({ Title = "Barista", Content = "Memulai shift Barista...", Duration = 2 })
        task.wait(1.5)

        while AutoBaristaEnabled do
            pcall(function()
                -- 1. Tween ke Tempat Shift
                if not AutoBaristaEnabled then break end
                smoothMoveTo(COORDS.ShiftSpot)
                task.wait(0.5)
                fireNearestPrompt()
                task.wait(1.0)

                -- 2. Tween ke Mesin Kopi & Instant Brew via Remote
                if not AutoBaristaEnabled then break end
                smoothMoveTo(COORDS.CoffeeMachine)
                task.wait(0.5)
                
                -- Tembak remote asli game untuk bikin kopi instan
                BaristaEvent:FireServer("TryBrew")
                task.wait(0.3)
                if CurrentToken then
                    BaristaEvent:FireServer("CompleteMinigame", { ["Token"] = CurrentToken })
                end
                task.wait(1.0)

                -- 3. Tween ke Pelanggan & Serve Order via Remote
                if not AutoBaristaEnabled then break end
                smoothMoveTo(COORDS.Customer)
                task.wait(0.5)
                
                BaristaEvent:FireServer("ServeOrder")
                task.wait(1.5)
            end)
        end
    end)
end

-- TOGGLE UI
FarmSection:Toggle({
    Title = "Auto Farm Barista (Pro Route)",
    Desc = "Speed 2 + Remote Bypass Minigame",
    Value = false,
    Callback = function(State)
        AutoBaristaEnabled = State
        if State then
            WindUI:Notify({ Title = "Status", Content = "Auto Farm Pro Aktif!", Duration = 2 })
            startBaristaFarm()
        else
            WindUI:Notify({ Title = "Status", Content = "Auto Farm Dimatikan.", Duration = 2 })
            if baristaThread then
                task.cancel(baristaThread)
                baristaThread = nil
            end
        end
    end
})

FarmSection:Toggle({
    Title = "Instant Proximity Prompt",
    Desc = "Ubah hold duration prompt jadi 0",
    Value = false,
    Callback = function(State)
        InstantPromptEnabled = State
        WindUI:Notify({ Title = "Prompt", Content = State and "Aktif!" or "Mati.", Duration = 2 })
    end
})

MainSection:Toggle({
    Title = "Anti-AFK",
    Desc = "Mencegah kick karena AFK",
    Value = false,
    Callback = function(State)
        AntiAfkEnabled = State
        WindUI:Notify({ Title = "Anti-AFK", Content = State and "Aktif!" or "Mati.", Duration = 2 })
    end
})

WindUI:Notify({
    Title = "Keren Hub Ready",
    Content = "Script Pro Barista siap gaspol! ☕🚀",
    Duration = 3
})
