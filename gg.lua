local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(math.random(3,6))

-- =========================
-- WS SAFE CONNECT
-- =========================
local ws
pcall(function()
    ws = WebSocket.connect("wss://luarmor-ws.onrender.com/ws")
end)

if not ws then
    warn("ws fail")
    return
end

pcall(function()
    ws:Send(HttpService:JSONEncode({
        type = "register",
        client = "game"
    }))
end)

print("🟢 conectado")

-- =========================
-- CHAT UI
-- =========================
local gui = Instance.new("ScreenGui", game.CoreGui)

local container = Instance.new("Frame", gui)
container.Position = UDim2.new(1, -320, 0.55, 0)
container.Size = UDim2.new(0, 300, 0, 200)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 6)
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

local function createMessage(player, text)
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1,0,0,22)
    label.BackgroundTransparency = 1
    label.Text = player..": "..text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 17

    task.delay(6,function()
        if label then label:Destroy() end
    end)
end

-- =========================
-- ACTION LIMITER
-- =========================
local lastAction = 0

local keyActions = {
    Ragdoll = Enum.KeyCode.R,
    Control = Enum.KeyCode.C,
    Jail = Enum.KeyCode.J,
    Jumpscr = Enum.KeyCode.U,
    Balloon = Enum.KeyCode.B,
    Inverse = Enum.KeyCode.I,
    Morph = Enum.KeyCode.M
}

local function pressKey(key)
    if tick() - lastAction < 1.5 then return end
    lastAction = tick()

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end

-- =========================
-- PLAYERS (SEM LOOP)
-- =========================
local function sendPlayers()
    local list = {}

    for _,p in ipairs(Players:GetPlayers()) do
        table.insert(list, p.Name)
    end

    pcall(function()
        ws:Send(HttpService:JSONEncode({
            type = "players",
            list = list
        }))
    end)
end

task.delay(4, sendPlayers)

-- =========================
-- RECEBER
-- =========================
ws.OnMessage:Connect(function(msg)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(msg)
    end)

    if not ok then return end

    if data.button then
        local key = keyActions[data.button]
        if key then
            pressKey(key)
        end
    end

    if data.type == "chat" then
        createMessage(data.player, data.message)
    end

    if data.type == "refresh" then
        sendPlayers()
    end
end)

print("🚀 modo reduzido ativo")
