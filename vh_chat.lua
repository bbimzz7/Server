-- VH CHAT - VertictHub (standalone module)
-- Load via: loadstring(game:HttpGet(URL))(WindUI)
-- WindUI optional — kalau nil, notif pakai toast ScreenGui bawaan

local WindUI      = ...  -- bisa nil kalau script lain ga punya WindUI
local LocalPlayer = game:GetService("Players").LocalPlayer

local VH_WS_URL   = "wss://vh-chat-server-production.up.railway.app"
local currentRoom = "global"
local VH_ICON     = "rbxassetid://83579786748904"

-- ── Fungsi notif universal ────────────────────
-- Pakai WindUI kalau ada, fallback ke toast ScreenGui

local ToastGui = Instance.new("ScreenGui")
ToastGui.Name          = "VHChatToast"
ToastGui.ResetOnSpawn  = false
ToastGui.DisplayOrder  = 999
ToastGui.Parent        = LocalPlayer.PlayerGui

local function vhNotify(title, content, duration)
    duration = duration or 3

    if WindUI then
        pcall(function()
            WindUI:Notify({ Title = title, Content = content, Duration = duration })
        end)
        return
    end

    -- Fallback: toast ScreenGui
    local toast = Instance.new("Frame", ToastGui)
    toast.Size             = UDim2.new(0, 260, 0, 0)
    toast.AutomaticSize    = Enum.AutomaticSize.Y
    toast.Position         = UDim2.new(1, -276, 1, -80)
    toast.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    toast.BorderSizePixel  = 0
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)
    local ts = Instance.new("UIStroke", toast)
    ts.Color = Color3.fromRGB(70, 70, 120) ts.Thickness = 1

    local tp = Instance.new("UIPadding", toast)
    tp.PaddingLeft = UDim.new(0,10) tp.PaddingRight  = UDim.new(0,10)
    tp.PaddingTop  = UDim.new(0,8)  tp.PaddingBottom = UDim.new(0,8)

    local tl = Instance.new("UIListLayout", toast)
    tl.Padding = UDim.new(0, 3) tl.SortOrder = Enum.SortOrder.LayoutOrder

    local titleL = Instance.new("TextLabel", toast)
    titleL.Size               = UDim2.new(1, 0, 0, 14)
    titleL.BackgroundTransparency = 1
    titleL.Text               = title
    titleL.TextColor3         = Color3.fromRGB(200, 200, 255)
    titleL.TextSize           = 12
    titleL.Font               = Enum.Font.GothamBold
    titleL.TextXAlignment     = Enum.TextXAlignment.Left
    titleL.LayoutOrder        = 0

    local msgL = Instance.new("TextLabel", toast)
    msgL.Size               = UDim2.new(1, 0, 0, 0)
    msgL.AutomaticSize      = Enum.AutomaticSize.Y
    msgL.BackgroundTransparency = 1
    msgL.Text               = content
    msgL.TextColor3         = Color3.fromRGB(190, 190, 210)
    msgL.TextSize           = 11
    msgL.Font               = Enum.Font.Gotham
    msgL.TextXAlignment     = Enum.TextXAlignment.Left
    msgL.TextWrapped        = true
    msgL.LayoutOrder        = 1

    -- auto destroy setelah duration
    task.delay(duration, function()
        if toast and toast.Parent then toast:Destroy() end
    end)
end

-- Owner user IDs
local OWNER_IDS = { [10278652817] = true, [5392733334] = true }

local function isOwner(username)
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p.Name == username and OWNER_IDS[p.UserId] then return true end
    end
    return false
end

-- ── ScreenGui ─────────────────────────────────

-- Destroy instance lama kalau ada (mencegah double GUI saat re-execute)
local oldGui = LocalPlayer.PlayerGui:FindFirstChild("VHChat")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "VHChat"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = LocalPlayer.PlayerGui

-- ── MainFrame ─────────────────────────────────

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 280, 0, 360)
MainFrame.Position         = UDim2.new(0, 80, 1, -490)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Draggable        = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color     = Color3.fromRGB(60, 60, 100)
MainStroke.Thickness = 1.5

-- gradient background
local MainGrad = Instance.new("UIGradient", MainFrame)
MainGrad.Color    = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 16)),
})
MainGrad.Rotation = 135

-- ── Title Bar ─────────────────────────────────

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size             = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
TitleBar.BorderSizePixel  = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)
-- fix rounded bottom corners
local TitleFix = Instance.new("Frame", TitleBar)
TitleFix.Size             = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position         = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
TitleFix.BorderSizePixel  = 0

local TitleGrad = Instance.new("UIGradient", TitleBar)
TitleGrad.Color    = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 30)),
})
TitleGrad.Rotation = 90

-- Icon
local IconImg = Instance.new("ImageLabel", TitleBar)
IconImg.Size                   = UDim2.new(0, 26, 0, 26)
IconImg.Position               = UDim2.new(0, 10, 0.5, -13)
IconImg.BackgroundTransparency = 1
IconImg.Image                  = VH_ICON
IconImg.ScaleType              = Enum.ScaleType.Fit
Instance.new("UICorner", IconImg).CornerRadius = UDim.new(1, 0)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size               = UDim2.new(0, 80, 1, 0)
TitleLabel.Position           = UDim2.new(0, 42, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text               = "VH Chat"
TitleLabel.TextColor3         = Color3.fromRGB(220, 220, 255)
TitleLabel.TextSize           = 13
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left

local StatusDot = Instance.new("TextLabel", TitleBar)
StatusDot.Size               = UDim2.new(0, 70, 1, 0)
StatusDot.Position           = UDim2.new(1, -100, 0, 0)
StatusDot.BackgroundTransparency = 1
StatusDot.Text               = "● offline"
StatusDot.TextColor3         = Color3.fromRGB(200, 70, 70)
StatusDot.TextSize           = 10
StatusDot.Font               = Enum.Font.Gotham
StatusDot.TextXAlignment     = Enum.TextXAlignment.Left

local ToggleBtn = Instance.new("TextButton", TitleBar)
ToggleBtn.Size             = UDim2.new(0, 22, 0, 22)
ToggleBtn.Position         = UDim2.new(1, -28, 0.5, -11)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.Text             = "—"
ToggleBtn.TextColor3       = Color3.fromRGB(180, 180, 220)
ToggleBtn.TextSize         = 11
ToggleBtn.Font             = Enum.Font.GothamBold
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

-- ── Room Bar ──────────────────────────────────

local RoomBar = Instance.new("Frame", MainFrame)
RoomBar.Size             = UDim2.new(1, -14, 0, 30)
RoomBar.Position         = UDim2.new(0, 7, 0, 48)
RoomBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
RoomBar.BorderSizePixel  = 0
Instance.new("UICorner", RoomBar).CornerRadius = UDim.new(0, 8)

local BtnGlobal = Instance.new("TextButton", RoomBar)
BtnGlobal.Size             = UDim2.new(0.5, -3, 1, -6)
BtnGlobal.Position         = UDim2.new(0, 3, 0, 3)
BtnGlobal.BackgroundColor3 = Color3.fromRGB(70, 70, 160)
BtnGlobal.BorderSizePixel  = 0
BtnGlobal.Text             = "🌐 All Servers"
BtnGlobal.TextColor3       = Color3.fromRGB(255, 255, 255)
BtnGlobal.TextSize         = 11
BtnGlobal.Font             = Enum.Font.GothamBold
Instance.new("UICorner", BtnGlobal).CornerRadius = UDim.new(0, 6)

local BtnLocal = Instance.new("TextButton", RoomBar)
BtnLocal.Size             = UDim2.new(0.5, -3, 1, -6)
BtnLocal.Position         = UDim2.new(0.5, 0, 0, 3)
BtnLocal.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
BtnLocal.BorderSizePixel  = 0
BtnLocal.Text             = "🏠 This Server"
BtnLocal.TextColor3       = Color3.fromRGB(140, 140, 180)
BtnLocal.TextSize         = 11
BtnLocal.Font             = Enum.Font.Gotham
Instance.new("UICorner", BtnLocal).CornerRadius = UDim.new(0, 6)

-- ── Divider ───────────────────────────────────

local Divider = Instance.new("Frame", MainFrame)
Divider.Size             = UDim2.new(1, -24, 0, 1)
Divider.Position         = UDim2.new(0, 12, 0, 84)
Divider.BackgroundColor3 = Color3.fromRGB(38, 38, 60)
Divider.BorderSizePixel  = 0

-- ── Chat Body ─────────────────────────────────

local ChatBody = Instance.new("ScrollingFrame", MainFrame)
ChatBody.Size                = UDim2.new(1, -10, 1, -134)
ChatBody.Position            = UDim2.new(0, 5, 0, 92)
ChatBody.BackgroundTransparency = 1
ChatBody.BorderSizePixel     = 0
ChatBody.ScrollBarThickness  = 2
ChatBody.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 120)
ChatBody.CanvasSize          = UDim2.new(0, 0, 0, 0)
ChatBody.AutomaticCanvasSize = Enum.AutomaticSize.Y
local ChatLayout = Instance.new("UIListLayout", ChatBody)
ChatLayout.Padding   = UDim.new(0, 3)
ChatLayout.SortOrder = Enum.SortOrder.LayoutOrder
local ChatPad = Instance.new("UIPadding", ChatBody)
ChatPad.PaddingLeft   = UDim.new(0, 3)
ChatPad.PaddingRight  = UDim.new(0, 3)
ChatPad.PaddingTop    = UDim.new(0, 4)
ChatPad.PaddingBottom = UDim.new(0, 4)

-- ── Input Bar ─────────────────────────────────

local InputBar = Instance.new("Frame", MainFrame)
InputBar.Size             = UDim2.new(1, -14, 0, 38)
InputBar.Position         = UDim2.new(0, 7, 1, -44)
InputBar.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
InputBar.BorderSizePixel  = 0
Instance.new("UICorner", InputBar).CornerRadius = UDim.new(0, 10)
local InputStroke = Instance.new("UIStroke", InputBar)
InputStroke.Color     = Color3.fromRGB(50, 50, 85)
InputStroke.Thickness = 1

local ChatInput = Instance.new("TextBox", InputBar)
ChatInput.Size               = UDim2.new(1, -48, 1, -10)
ChatInput.Position           = UDim2.new(0, 10, 0, 5)
ChatInput.BackgroundTransparency = 1
ChatInput.Text               = ""
ChatInput.PlaceholderText    = "Ketik pesan..."
ChatInput.PlaceholderColor3  = Color3.fromRGB(80, 80, 110)
ChatInput.TextColor3         = Color3.fromRGB(220, 220, 255)
ChatInput.TextSize           = 12
ChatInput.Font               = Enum.Font.Gotham
ChatInput.TextXAlignment     = Enum.TextXAlignment.Left
ChatInput.ClearTextOnFocus   = false

local SendBtn = Instance.new("ImageButton", InputBar)
SendBtn.Size             = UDim2.new(0, 28, 0, 28)
SendBtn.Position         = UDim2.new(1, -32, 0.5, -14)
SendBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 160)
SendBtn.BorderSizePixel  = 0
SendBtn.Image            = "rbxassetid://6031068426"
SendBtn.ImageColor3      = Color3.fromRGB(255, 255, 255)
SendBtn.ScaleType        = Enum.ScaleType.Fit
Instance.new("UICorner", SendBtn).CornerRadius = UDim.new(1, 0)

-- ── Toggle Circle (fixed, parent ScreenGui) ───

local ToggleCircle = Instance.new("ImageButton", ScreenGui)
ToggleCircle.Size             = UDim2.new(0, 48, 0, 48)
ToggleCircle.Position         = UDim2.new(0, 16, 0.5, -24)
ToggleCircle.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
ToggleCircle.BorderSizePixel  = 0
ToggleCircle.Image            = VH_ICON
ToggleCircle.ScaleType        = Enum.ScaleType.Fit
ToggleCircle.Active           = true
ToggleCircle.Draggable        = false
Instance.new("UICorner", ToggleCircle).CornerRadius = UDim.new(1, 0)
local CircleStroke = Instance.new("UIStroke", ToggleCircle)
CircleStroke.Color     = Color3.fromRGB(70, 70, 160)
CircleStroke.Thickness = 2.5

-- ── Helper: tambah pesan ──────────────────────

local chatOrder = 0

local function addMsg(sender, msg, isSelf, isSystem)
    chatOrder += 1
    local owner = not isSystem and isOwner(sender)

    -- wrapper: accent bar kiri + content di kanan
    local row = Instance.new("Frame", ChatBody)
    row.Size             = UDim2.new(1, -4, 0, 0)
    row.AutomaticSize    = Enum.AutomaticSize.Y
    row.BackgroundColor3 = isSystem and Color3.fromRGB(18, 18, 26)
        or isSelf        and Color3.fromRGB(28, 28, 52)
        or owner         and Color3.fromRGB(38, 18, 18)
        or                   Color3.fromRGB(20, 20, 32)
    row.BorderSizePixel  = 0
    row.LayoutOrder      = chatOrder
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    -- accent bar kiri
    local accent = Instance.new("Frame", row)
    accent.Size             = UDim2.new(0, 3, 1, -10)
    accent.Position         = UDim2.new(0, 0, 0, 5)
    accent.BackgroundColor3 = isSystem and Color3.fromRGB(70, 70, 95)
        or isSelf            and Color3.fromRGB(75, 95, 215)
        or owner             and Color3.fromRGB(215, 90, 40)
        or                       Color3.fromRGB(50, 170, 90)
    accent.BorderSizePixel  = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

    -- content frame di kanan accent bar
    local content = Instance.new("Frame", row)
    content.Size             = UDim2.new(1, -14, 0, 0)
    content.Position         = UDim2.new(0, 11, 0, 0)
    content.AutomaticSize    = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1

    local contentLayout = Instance.new("UIListLayout", content)
    contentLayout.Padding        = UDim.new(0, 2)
    contentLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    contentLayout.FillDirection  = Enum.FillDirection.Vertical

    local contentPad = Instance.new("UIPadding", content)
    contentPad.PaddingTop    = UDim.new(0, 6)
    contentPad.PaddingBottom = UDim.new(0, 6)
    contentPad.PaddingRight  = UDim.new(0, 6)

    -- nama row
    local nameRow = Instance.new("Frame", content)
    nameRow.Size             = UDim2.new(1, 0, 0, 14)
    nameRow.AutomaticSize    = Enum.AutomaticSize.Y
    nameRow.BackgroundTransparency = 1
    nameRow.LayoutOrder      = 0

    local nameL = Instance.new("TextLabel", nameRow)
    nameL.Size               = UDim2.new(1, 0, 0, 14)
    nameL.BackgroundTransparency = 1
    nameL.Text               = sender
    nameL.TextColor3         = isSystem and Color3.fromRGB(105, 105, 130)
        or isSelf            and Color3.fromRGB(135, 155, 255)
        or owner             and Color3.fromRGB(255, 145, 75)
        or                       Color3.fromRGB(85, 200, 115)
    nameL.TextSize           = 11
    nameL.Font               = Enum.Font.GothamMedium
    nameL.TextXAlignment     = Enum.TextXAlignment.Left
    nameL.TextTruncate       = Enum.TextTruncate.AtEnd

    if owner then
        local nameLayout = Instance.new("UIListLayout", nameRow)
        nameLayout.FillDirection     = Enum.FillDirection.Horizontal
        nameLayout.Padding           = UDim.new(0, 5)
        nameLayout.SortOrder         = Enum.SortOrder.LayoutOrder
        nameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        nameL.Size        = UDim2.new(0, 0, 0, 14)
        nameL.AutomaticSize = Enum.AutomaticSize.X
        nameL.LayoutOrder = 0

        local badge = Instance.new("TextLabel", nameRow)
        badge.AutomaticSize      = Enum.AutomaticSize.X
        badge.Size               = UDim2.new(0, 0, 0, 13)
        badge.BackgroundColor3   = Color3.fromRGB(175, 60, 18)
        badge.BorderSizePixel    = 0
        badge.Text               = " 👑 OWNER "
        badge.TextColor3         = Color3.fromRGB(255, 220, 165)
        badge.TextSize           = 9
        badge.Font               = Enum.Font.GothamBold
        badge.TextXAlignment     = Enum.TextXAlignment.Center
        badge.LayoutOrder        = 1
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)
        local bpad = Instance.new("UIPadding", badge)
        bpad.PaddingLeft  = UDim.new(0, 4)
        bpad.PaddingRight = UDim.new(0, 4)
    end

    -- pesan
    local msgL = Instance.new("TextLabel", content)
    msgL.Size               = UDim2.new(1, 0, 0, 0)
    msgL.AutomaticSize      = Enum.AutomaticSize.Y
    msgL.BackgroundTransparency = 1
    msgL.Text               = msg
    msgL.TextColor3         = isSystem
        and Color3.fromRGB(155, 155, 172)
        or  Color3.fromRGB(202, 202, 218)
    msgL.TextSize           = 12
    msgL.Font               = Enum.Font.Gotham
    msgL.TextXAlignment     = Enum.TextXAlignment.Left
    msgL.TextWrapped        = true
    msgL.LineHeight         = 1.25
    msgL.LayoutOrder        = 1

    -- klik row = salin pesan
    local clickBtn = Instance.new("TextButton", row)
    clickBtn.Size                   = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text                   = ""
    clickBtn.ZIndex                 = row.ZIndex + 5
    clickBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(msg) end)
        local orig = row.BackgroundColor3
        row.BackgroundColor3 = Color3.fromRGB(55, 55, 95)
        task.delay(0.15, function() row.BackgroundColor3 = orig end)
    end)

    task.defer(function()
        ChatBody.CanvasPosition = Vector2.new(0, ChatBody.AbsoluteCanvasSize.Y)
    end)
end

local function sysMsg(m) addMsg("● SISTEM", m, false, true) end

-- ── Buka/Tutup via ToggleCircle ──────────────

local minimized = false

-- Sembunyikan ToggleBtn lama di title bar (ga dipakai)
ToggleBtn.Visible = false

-- Saat minimize: sembunyikan MainFrame isi, tapi ToggleCircle tetap keliatan
-- Karena ToggleCircle adalah child MainFrame, kita sembunyikan konten saja
-- dan kecilkan MainFrame ke 0 opacity tapi tetap ada buat anchor ToggleCircle

local function setChat(open)
    minimized = not open
    TitleBar.Visible = open
    RoomBar.Visible  = open
    Divider.Visible  = open
    ChatBody.Visible = open
    InputBar.Visible = open
    MainFrame.BackgroundTransparency = open and 0 or 1
    MainStroke.Enabled = open
    CircleStroke.Color = open
        and Color3.fromRGB(70, 70, 160)
        or  Color3.fromRGB(120, 50, 50)
end

ToggleCircle.MouseButton1Click:Connect(function()
    setChat(minimized)  -- minimized true = lagi closed, jadi open
end)

setChat(true)  -- mulai dalam keadaan terbuka

-- ── WebSocket ─────────────────────────────────

local ws           = nil
local wsConnected  = false
local wsConnecting = false
local wsSwitching  = false
local wsInstanceId = 0  -- tiap koneksi baru dapat ID unik, listener lama cek ID sebelum act

local function connectWS()
    if wsConnecting then return end
    wsConnecting  = true
    wsInstanceId  = wsInstanceId + 1
    local myId    = wsInstanceId

    sysMsg("Connecting...")
    local ok, result = pcall(function()
        return WebSocket.connect(VH_WS_URL)
    end)

    -- kalau ID udah beda (ada koneksi baru), batalkan ini
    if myId ~= wsInstanceId then
        wsConnecting = false
        if ok and result then pcall(function() result:Close() end) end
        return
    end

    if not ok or not result then
        sysMsg("Gagal: " .. tostring(result))
        StatusDot.Text       = "● offline"
        StatusDot.TextColor3 = Color3.fromRGB(200, 80, 80)
        wsConnecting = false
        task.delay(5, connectWS)
        return
    end

    ws           = result
    wsConnected  = true
    wsConnecting = false
    StatusDot.Text       = "● online"
    StatusDot.TextColor3 = Color3.fromRGB(80, 220, 120)
    sysMsg("Terhubung! Room: " .. (currentRoom == "global" and "All Servers" or "This Server"))

    ws:Send(game:GetService("HttpService"):JSONEncode({
        type     = "join",
        username = LocalPlayer.Name,
        room     = currentRoom,
    }))

    ws.OnMessage:Connect(function(raw)
        -- abaikan kalau bukan koneksi aktif
        if myId ~= wsInstanceId then return end
        local ok2, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(raw)
        end)
        if not ok2 then return end

        if data.type == "chat" then
            local isSelf = data.username == LocalPlayer.Name
            addMsg(data.username, data.msg, isSelf, false)
            if minimized and not isSelf then
                vhNotify("💬 " .. data.username, data.msg, 4)
            end
        elseif data.type == "system" then
            sysMsg(data.msg)
        elseif data.type == "online" then
            sysMsg("Online (" .. #data.users .. "): " .. table.concat(data.users, ", "))
        end
    end)

    ws.OnClose:Connect(function()
        -- abaikan kalau ini bukan koneksi aktif (intentional close)
        if myId ~= wsInstanceId then return end
        wsConnected  = false
        ws           = nil
        StatusDot.Text       = "● offline"
        StatusDot.TextColor3 = Color3.fromRGB(200, 80, 80)
        sysMsg("Koneksi terputus. Reconnecting...")
        task.delay(3, connectWS)
    end)
end

-- ── Room switcher logic ───────────────────────

local lastSwitchTime = 0

local function switchRoom(room)
    if room == currentRoom then return end

    local now = tick()
    if now - lastSwitchTime < 5 then
        local sisa = math.ceil(5 - (now - lastSwitchTime))
        sysMsg("Tunggu " .. sisa .. " detik lagi untuk ganti room.")
        return
    end
    lastSwitchTime = now
    currentRoom = room

    -- increment ID dulu — semua listener lama jadi invalid seketika
    wsInstanceId = wsInstanceId + 1
    wsConnecting = false
    wsConnected  = false

    -- kirim leave ke server sebelum close
    if ws then
        pcall(function()
            ws:Send(game:GetService("HttpService"):JSONEncode({
                type = "leave",
                username = LocalPlayer.Name,
            }))
            ws:Close()
        end)
        ws = nil
    end

    -- update tombol visual
    if room == "global" then
        BtnGlobal.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
        BtnGlobal.TextColor3       = Color3.fromRGB(255, 255, 255)
        BtnGlobal.Font             = Enum.Font.GothamBold
        BtnLocal.BackgroundColor3  = Color3.fromRGB(45, 45, 60)
        BtnLocal.TextColor3        = Color3.fromRGB(180, 180, 200)
        BtnLocal.Font              = Enum.Font.Gotham
    else
        BtnLocal.BackgroundColor3  = Color3.fromRGB(80, 80, 180)
        BtnLocal.TextColor3        = Color3.fromRGB(255, 255, 255)
        BtnLocal.Font              = Enum.Font.GothamBold
        BtnGlobal.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        BtnGlobal.TextColor3       = Color3.fromRGB(180, 180, 200)
        BtnGlobal.Font             = Enum.Font.Gotham
    end

    -- clear chat
    for _, child in ipairs(ChatBody:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    chatOrder = 0

    task.spawn(connectWS)
end

BtnGlobal.MouseButton1Click:Connect(function()
    switchRoom("global")
end)

BtnLocal.MouseButton1Click:Connect(function()
    local jobId = game.JobId ~= "" and game.JobId or "local-server"
    switchRoom(jobId)
end)

-- ── Kirim pesan ──────────────────────────────

local function sendMsg(msg)
    msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then return end
    if not wsConnected or not ws then
        sysMsg("Tidak terhubung.")
        return
    end
    ws:Send(game:GetService("HttpService"):JSONEncode({
        type = "chat",
        msg  = msg,
    }))
    ChatInput.Text = ""
end

SendBtn.MouseButton1Click:Connect(function() sendMsg(ChatInput.Text) end)
ChatInput.FocusLost:Connect(function(enter) if enter then sendMsg(ChatInput.Text) end end)

-- connect langsung saat script jalan (room default: global)
task.spawn(connectWS)

