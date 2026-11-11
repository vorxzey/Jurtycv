-- ==========================================
-- KEREN HUB - BARISTA PRECISE ROUTE (FIXED)
-- ==========================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Keren Hub ☕ | Barista Route",
    Icon = "coffee",
    Author = "by Kenzo",
    Folder = "KerenBaristaPreciseConfig",
    Transparent = false,
    Theme = "Dark"
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AntiAfkEnabled = false
local AutoBaristaEnabled = false
local baristaThread = nil

-- Koordinat Sesuai Urutan Permintaan
local COORDS = {
    ShiftSpot     = CFrame.new(-4992.262, 4.287, -716.253), -- Tempat Shift Kerja
    CoffeeMachine = CFrame.new(-4997.648, 4.287, -794.613), -- Mesin Kopi
    Customer      = CFrame.new(-4996.451, 4.287, -760.959)  -- Kasih Kopi ke Pelanggan
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

-- 1. PILIH JOB BARISTA VIA REMOTE
local function selectBaristaJob()
    pcall(function()
        local Event = ReplicatedStorage:FindFirstChild("JobEvents") and ReplicatedStorage.JobEvents:FindFirstChild("TeamChangeRequest")
        if Event then
            Event:FireServer("Barista", 11378976, 1, 0, "Detector")
        end
    end)
end

-- FUNGSI GERAK HALUS (TWEEN) ANTAR TITIK
local function smoothMoveTo(targetCFrame)
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = 16 -- Kecepatan rata-rata normal
        local duration = math.clamp(distance / speed, 0.8, 3.5)

        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        
        tween:Play()
        tween.Completed:Wait()
    end)
end

-- HELPER PROXIMITY PROMPT
local function fireNearestPrompt()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Parent then
                local partPos = v.Parent:IsA("Model") and v.Parent.PrimaryPart and v.Parent.PrimaryPart.Position or (v.Parent:IsA("BasePart") and v.Parent.Position)
                if partPos and (partPos - hrp.Position).Magnitude <= 10 then
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

-- SIKLUS UTAMA AUTO FARM BERDASARKAN URUTAN
local function startBaristaFarm()
    if baristaThread then task.cancel(baristaThread) end

    baristaThread = task.spawn(function()
        -- LANGKAH 1: Pilih Job Barista
        selectBaristaJob()
        WindUI:Notify({ Title = "Barista", Content = "Memilih job Barista...", Duration = 2 })
        task.wait(1.5)

        while AutoBaristaEnabled do
            pcall(function()
                -- LANGKAH 2: Tween ke tempat shift kerja
                smoothMoveTo(COORDS.ShiftSpot)
                task.wait(0.5)
                fireNearestPrompt()
                task.wait(1.0)

                -- LANGKAH 3: Jalan ke mesin kopi buat bikin kopi
                smoothMoveTo(COORDS.CoffeeMachine)
                task.wait(0.5)
                
                -- Proses ngeracik kopi (beberapa kali interaksi santai)
                for i = 1, 3 do
                    if not AutoBaristaEnabled then break end
                    fireNearestPrompt()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.15)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    task.wait(1.2)
                end

                -- LANGKAH 4: Jalan untuk kasih kopinya ke pelanggan
                smoothMoveTo(COORDS.Customer)
                task.wait(0.5)
                fireNearestPrompt()
                
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.15)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

                -- Jeda santai sebelum ngulang shift baru
                task.wait(2.0)
            end)
        end
    end)
end

-- TOGGLE UI
FarmSection:Toggle({
    Title = "Auto Farm Barista (Precise Route)",
    Desc = "Job ➔ Shift ➔ Mesin Kopi ➔ Pelanggan",
    Value = false,
    Callback = function(State)
        AutoBaristaEnabled = State
        if State then
            WindUI:Notify({ Title = "Status", Content = "Auto Farm Berjalan!", Duration = 2 })
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

MainSection:Toggle({
    Title = "Anti-AFK",
    Desc = "Mencegah AFK kick",
    Value = false,
    Callback = function(State)
        AntiAfkEnabled = State
        WindUI:Notify({ Title = "Anti-AFK", Content = State and "Aktif!" or "Mati.", Duration = 2 })
    end
})

WindUI:Notify({
    Title = "Keren Hub Ready",
    Content = "Script rute berurutan siap digunakan! ☕",
    Duration = 3
})
