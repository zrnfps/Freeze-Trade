local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(3)

-- =========================
-- WEBSOCKET
-- =========================
local ws = WebSocket.connect("wss://luarmor-ws.onrender.com/ws")

ws:Send(HttpService:JSONEncode({
    type = "register",
    client = "game"
}))

print("🟢 conectado")

-- =========================
-- CHAT UI (ESTILO ROBLOX)
-- =========================
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "BetterChat"

local container = Instance.new("Frame", gui)
container.Position = UDim2.new(1, -320, 0.55, 0)
container.Size = UDim2.new(0, 300, 0, 200)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 6)
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

-- limite de mensagens
local MAX_MSG = 6

local messages = {}

local function createMessage(player, text)
    local msgFrame = Instance.new("Frame")
    msgFrame.Size = UDim2.new(1, 0, 0, 22)
    msgFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", msgFrame)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 17
    label.TextStrokeTransparency = 0.6
    label.TextColor3 = Color3.fromRGB(255,255,255)

    label.Text = player .. ": " .. text
    label.TextTransparency = 1

    msgFrame.Parent = container

    -- fade in
    TweenService:Create(label, TweenInfo.new(0.25), {
        TextTransparency = 0
    }):Play()

    -- remove antigo se passar limite
    table.insert(messages, msgFrame)

    if #messages > MAX_MSG then
        local old = table.remove(messages, 1)

        for _,v in ipairs(old:GetChildren()) do
            TweenService:Create(v, TweenInfo.new(0.2), {
                TextTransparency = 1
            }):Play()
        end

        task.delay(0.2, function()
            if old then old:Destroy() end
        end)
    end

    -- fade out automático
    task.delay(7, function()
        if msgFrame and msgFrame.Parent then
            for _,v in ipairs(msgFrame:GetChildren()) do
                TweenService:Create(v, TweenInfo.new(0.3), {
                    TextTransparency = 1
                }):Play()
            end

            task.delay(0.3, function()
                if msgFrame then msgFrame:Destroy() end
            end)
        end
    end)
end

-- =========================
-- ADMIN ACTIONS
-- =========================
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
    task.wait(math.random(100,300)/1000)

    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(math.random(50,150)/1000)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- =========================
-- PLAYERS
-- =========================
local function sendPlayers()
    local list = {}

    for _,p in ipairs(Players:GetPlayers()) do
        table.insert(list, p.Name)
    end

    ws:Send(HttpService:JSONEncode({
        type = "players",
        list = list
    }))
end

task.delay(2, sendPlayers)

-- =========================
-- RECEBER
-- =========================
ws.OnMessage:Connect(function(msg)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(msg)
    end)

    if not ok then return end

    -- comandos
    if data.button then
        local key = keyActions[data.button]
        if key then
            pressKey(key)
        end
    end

    -- chat visual perfeito
    if data.type == "chat" then
        createMessage(data.player, data.message)
    end

    -- refresh
    if data.type == "refresh" then
        sendPlayers()
    end
end)

print("🚀 CHAT ABSURDO ATIVO (SEM KICK)")
