local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")

-- espera carregar
if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(3)

-- =========================
-- CONEXÃO
-- =========================
local ws
pcall(function()
    ws = WebSocket.connect("wss://luarmor-ws.onrender.com/ws")
end)

if not ws then
    warn("❌ falha websocket")
    return
end

ws:Send(HttpService:JSONEncode({
    type = "register",
    client = "game"
}))

print("🟢 conectado")

-- =========================
-- KEYBINDS
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
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
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

    if not ok or not data then return end

    -- comandos
    if data.button then
        local key = keyActions[data.button]
        if key then
            pressKey(key)
        end
    end

    -- 💀 CHAT (VERSÃO ANTIGA - DUPLICA)
    if data.type == "chat" then
        local target = Players:FindFirstChild(data.player)

        if target and target.Character and target.Character:FindFirstChild("Head") then
            game:GetService("Chat"):Chat(
                target.Character.Head,
                data.message,
                Enum.ChatColor.White
            )
        end
    end

    if data.type == "refresh" then
        sendPlayers()
    end
end)

print("🚀 versão antiga ativa (duplica chat)")
