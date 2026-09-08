-- Farm Industry Hub - Newbie Friendly (berdasarkan konsep ChatGPT)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Global version biar loop lama mati saat reload (fix duplicate hub)
getgenv().YupiHub_Instance = (getgenv().YupiHub_Instance or 0) + 1
local myInstance = getgenv().YupiHub_Instance
getgenv().YupiHub_Alive = true

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
-- YUPI DARK - tema gelap kustom (palet aksesibel, kontras teks >= 4.5:1)
local YupiDarkTheme = {
    TextColor = Color3.fromRGB(245, 245, 245),
    Background = Color3.fromRGB(26, 26, 26),
    Topbar = Color3.fromRGB(36, 36, 36),
    Shadow = Color3.fromRGB(13, 13, 13),
    NotificationBackground = Color3.fromRGB(36, 36, 36),
    NotificationActionsBackground = Color3.fromRGB(245, 245, 245),
    TabBackground = Color3.fromRGB(36, 36, 36),
    TabStroke = Color3.fromRGB(51, 51, 51),
    TabBackgroundSelected = Color3.fromRGB(245, 245, 245),
    TabTextColor = Color3.fromRGB(156, 163, 175),
    SelectedTabTextColor = Color3.fromRGB(18, 18, 18),
    ElementBackground = Color3.fromRGB(30, 30, 30),
    ElementBackgroundHover = Color3.fromRGB(42, 42, 42),
    SecondaryElementBackground = Color3.fromRGB(36, 36, 36),
    ElementStroke = Color3.fromRGB(58, 58, 58),
    SecondaryElementStroke = Color3.fromRGB(46, 46, 46),
    SliderBackground = Color3.fromRGB(51, 51, 51),
    SliderProgress = Color3.fromRGB(59, 130, 246),
    SliderStroke = Color3.fromRGB(147, 197, 253),
    ToggleBackground = Color3.fromRGB(42, 42, 42),
    ToggleEnabled = Color3.fromRGB(37, 99, 235),
    ToggleDisabled = Color3.fromRGB(82, 82, 82),
    ToggleEnabledStroke = Color3.fromRGB(59, 130, 246),
    ToggleDisabledStroke = Color3.fromRGB(115, 115, 115),
    ToggleEnabledOuterStroke = Color3.fromRGB(30, 64, 175),
    ToggleDisabledOuterStroke = Color3.fromRGB(58, 58, 58),
    DropdownSelected = Color3.fromRGB(42, 42, 42),
    DropdownUnselected = Color3.fromRGB(30, 30, 30),
    InputBackground = Color3.fromRGB(30, 30, 30),
    InputStroke = Color3.fromRGB(58, 58, 58),
    PlaceholderColor = Color3.fromRGB(156, 163, 175),
}
local YUPI_RED_BG = Color3.fromRGB(58, 31, 31)
local YUPI_RED_TEXT = Color3.fromRGB(248, 113, 113)
local YUPI_RED_BAR = Color3.fromRGB(239, 68, 68)
local YUPI_RED_STROKE = Color3.fromRGB(127, 29, 29)
local YUPI_GRAY = Color3.fromRGB(156, 163, 175)
local YUPI_ICON = Color3.fromRGB(209, 213, 219)
-- Auto hancurkan bekas script di layar (banyak window numpuk) - FIX: cari di RobloxGui
pcall(function()
    local doDestroy = true
    pcall(function() if cfg and cfg.autoDestroy == false then doDestroy = false end end)
    if doDestroy then
        -- hancurkan semua Yupi Hub lama yang nyangkut di RobloxGui (GUID folder)
        local robloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        if robloxGui then
            for _,child in ipairs(robloxGui:GetChildren()) do
                local hasYupi = false
                pcall(function()
                    if child:FindFirstChild("Yupi Hub", true) or child.Name:find("Yupi") then hasYupi=true end
                    -- juga cek text label
                    for _,d in ipairs(child:GetDescendants()) do
                        if d:IsA("TextLabel") and (d.Text:find("Yupi Hub") or d.Text:find("Magnet Only") or d.Text:find("Water Only")) then hasYupi=true break end
                    end
                end)
                if hasYupi then pcall(function() child:Destroy() end) end
            end
        end
        -- juga cek gethui dan PlayerGui
        pcall(function()
            local hui = gethui and gethui() or nil
            if hui then
                for _,child in ipairs(hui:GetChildren()) do
                    if child:FindFirstChild("Yupi Hub", true) then pcall(function() child:Destroy() end) end
                end
            end
        end)
        for _,v in ipairs(game.Players.LocalPlayer.PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and (v.Text:find("Yupi Hub") or v.Text:find("Magnet Only")) then
                local top = v:FindFirstAncestorOfClass("ScreenGui")
                if top then pcall(function() top:Destroy() end) end
            end
        end
    end
end)
local Window = Rayfield:CreateWindow({
    Name = "Yupi Hub",
    Theme = YupiDarkTheme,
    ConfigurationSaving = { Enabled = true, FileName = "YupiHub" }
})
local function notify(title, content, duration)
    pcall(function() Rayfield:Notify({ Title = title, Content = content, Duration = duration or 2.5, Image = 4483362458 }) end)
    pcall(function() Window:Notify({ Title = title, Content = content, Duration = duration or 2.5 }) end)
end

local MainTab = Window:CreateTab({ Name = "Main", Icon = "home" })
local FactoryTab = Window:CreateTab({ Name = "Factory", Icon = "factory" })
local WaterTab = Window:CreateTab({ Name = "Water", Icon = "droplet" })
local DeliveryTab = Window:CreateTab({ Name = "Delivery", Icon = "truck" })
local MagnetTab = Window:CreateTab({ Name = "Magnet", Icon = "magnet" })
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings" })
local UpgradeTab = Window:CreateTab({ Name = "Upgrade", Icon = "trending-up" })
local WolfTab = Window:CreateTab({ Name = "Serigala", Icon = "moon" })

-- State
local cfg = {
    amount = 5,
    modeProduksi = "Setelah hasil diambil",
    autoAmbil = true,
    produksiLagi = true,
    produksiTerus = false,
    autoSiram = false,
    waktuSiram = 2,
    autoIsiAir = true,
    isiSaat = 30,
    autoKirim = false,
    kirimBerdasarkan = "Setiap Interval",
    intervalKirim = 22,
    jenisKirim = {"Mentah", "Olahan", "Jadi"},
    kecualikan = {}, -- list item yang dikecualikan dari auto kirim
    autoAmbilMagnet = false,
    itemDiambil = "Semua",
    jarakAmbil = 2,
    autoDestroy = true, -- auto hancurkan script lama
    autoSpeed = false, -- auto speed (kunci WalkSpeed 1-100)
    speedTarget = 36, -- target WalkSpeed (1 pelan - 100 tercepat)
    autoWolf = false, -- auto hajar serigala se-map
    wolfMinHp = 30, -- mundur kalau HP di bawah ini (%)
    autoMisi = false, -- auto complete misi (reservasi + prioritas + auto claim)
    misiFokus = "Semua", -- misi mana diselesaikan dulu: Semua / 1 Teratas / 3 Teratas / 5 Teratas
    autoResearchLab = false,
    researchPilihan = {"RebirthOptimization","RevenueOverclock"}, -- prioritas research (baru)
    researchPriority = {"RebirthOptimization","RevenueOverclock"}, -- legacy untuk dropdown lama
    autoFarmMastery = false,
    farmSkillPilihan = {"DoubleYield","FactoryOverclock","Industrialist"},
    farmMasteryPriority = {"DoubleYield","FactoryOverclock","Industrialist"},
}

local DeliveryConfig = require(ReplicatedStorage.Modules:WaitForChild("DeliveryConfig"))
local FactoryConfig = require(ReplicatedStorage.Modules:WaitForChild("FactoryConfig"))

local function getInventory()
    local ok, data = pcall(function() return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory_JSON") or "{}") end)
    if ok and type(data)=="table" then return data else return {} end
end
local function getTotalItems() local inv=getInventory(); local c=0; for _,v in pairs(inv) do c+=v end; return c end
local function getTotalWeight() local inv=getInventory(); local w=0; for item,cnt in pairs(inv) do local it=DeliveryConfig.Items[item]; if it then w+=(it.Weight or 1)*cnt end end; return w end
local RAW_SET = {Telur=true, Wol=true, Susu=true, Daging=true, ["Daging Serigala"]=true}
local PROC_SET = {Tepung=true, Benang=true, Sosis=true, Mentega=true}
local FINAL_SET = {Roti=true, Sweater=true, Hotdog=true, Keju=true}
local function baseItemName(item)
    local b = item:gsub(" Emas$", ""):gsub(" Sakura$", ""):gsub(" Cosmic$", "")
    return b
end
local function allowKirim(item)
    local set = cfg.jenisKirim
    if not set or #set == 0 then return true end
    local b = baseItemName(item)
    local wantRaw, wantProc, wantFinal = false, false, false
    for _, v in ipairs(set) do
        if v == "Mentah" then wantRaw = true
        elseif v == "Olahan" then wantProc = true
        elseif v == "Jadi" then wantFinal = true end
    end
    if RAW_SET[b] then return wantRaw end
    if PROC_SET[b] then return wantProc end
    if FINAL_SET[b] then return wantFinal end
    return true
end
local function isKecualikan(item)
    if not cfg.kecualikan or #cfg.kecualikan==0 then return false end
    for _, ex in ipairs(cfg.kecualikan) do
        if item == ex then return true end
        if baseItemName(item) == baseItemName(ex) and ex == baseItemName(ex) then return true end
    end
    return false
end
-- AUTO MISI - lapisan reservasi stok (hitung ulang tiap siklus, auto clear saat misi hilang)
local missionReserved = {} -- [itemName] = total Target di-reserve (di-sum semua misi)
-- forward declaration handle kontrol tab (dibuat di bawah) agar applyFactoryConfig bisa sinkron tampilan
local siramToggle, waktuSiramDropdown, isiAirToggle, isiSaatSlider
local autoKirimToggle, kirimDropdown, intervalSlider, jenisDropdown, kecualikanDropdown
local magnetToggle, itemDropdown, jarakSlider
local autoDestroyToggle, researchToggle, farmToggle, researchDropdown, farmDropdown
local wolfToggle, wolfMinSlider, wolfStatusText
local function getFilteredTotal()
    local inv = getInventory()
    local c = 0
    for item, cnt in pairs(inv) do
        if DeliveryConfig.Items[item] and allowKirim(item) and not isKecualikan(item) then
            local use = cnt
            if cfg.autoMisi then use = math.max(0, cnt - (missionReserved[item] or 0)) end
            c += use
        end
    end
    return c
end
local function getFilteredWeight()
    local inv = getInventory()
    local w = 0
    for item, cnt in pairs(inv) do
        local it = DeliveryConfig.Items[item]
        if it and allowKirim(item) and not isKecualikan(item) then
            local use = cnt
            if cfg.autoMisi then use = math.max(0, cnt - (missionReserved[item] or 0)) end
            w += (it.Weight or 1) * use
        end
    end
    return w
end
local function getMisiFocus()
    local open, done = {}, {}
    pcall(function()
        local qs = HttpService:JSONDecode(LocalPlayer:GetAttribute("ActiveQuests_JSON") or "[]")
        if type(qs) == "table" then
            for _, q in ipairs(qs) do
                if type(q.Items) == "table" then
                    if q.Completed then done[#done + 1] = q else open[#open + 1] = q end
                end
            end
        end
    end)
    local mode = type(cfg.misiFokus) == "table" and cfg.misiFokus[1] or cfg.misiFokus
    local n = 0
    if type(mode) == "string" and mode ~= "Semua" then n = tonumber(string.match(mode, "%d+")) or 0 end
    local focus = {}
    if n <= 0 then
        for _, q in ipairs(open) do if q.Id then focus[q.Id] = true end end
    else
        for i = 1, math.min(n, #open) do if open[i].Id then focus[open[i].Id] = true end end
    end
    for _, q in ipairs(done) do if q.Id then focus[q.Id] = true end end
    return open, done, focus, n > 0
end
local function refreshReserved()
    local res = {}
    if cfg.autoMisi then
        local open, done, focus = getMisiFocus()
        local function add(q)
            for _, it in ipairs(q.Items) do
                if it.Name and tonumber(it.Target) then
                    res[it.Name] = (res[it.Name] or 0) + it.Target
                end
            end
        end
        for _, q in ipairs(open) do if q.Id and focus[q.Id] then add(q) end end
        for _, q in ipairs(done) do add(q) end
    end
    missionReserved = res
    return res
end
local function getAvail(name)
    local total = (getInventory()[name] or 0)
    if not cfg.autoMisi then return total end
    local avail = total - (missionReserved[name] or 0)
    if avail < 0 then avail = 0 end
    return avail
end
local function getMisiLines()
    local lines = {}
    pcall(function()
        local inv = getInventory()
        local open, done, focus, limited = getMisiFocus()
        local n = 0
        local function push(q)
            n += 1
            local ndone = 0
            local names = {}
            for _, it in ipairs(q.Items) do
                local have = (inv[it.Name] or 0)
                if have >= (tonumber(it.Target) or 0) then ndone += 1 end
                names[#names + 1] = it.Name .. " " .. have .. "/" .. tostring(it.Target)
            end
            local mark = ""
            if q.Completed then mark = " [SELESAI]" elseif limited and q.Id and focus[q.Id] then mark = " [FOKUS]" end
            lines[#lines + 1] = n .. ". " .. tostring(q.Title) .. " (" .. ndone .. "/" .. #q.Items .. ")" .. mark
            for i = 1, #names, 2 do
                local chunk = names[i]
                if names[i + 1] then chunk = chunk .. ", " .. names[i + 1] end
                lines[#lines + 1] = "    " .. chunk
            end
        end
        for _, q in ipairs(open) do push(q) end
        for _, q in ipairs(done) do push(q) end
    end)
    if #lines == 0 then return {"Tidak ada misi"} end
    return lines
end
local function getReservedText()
    return table.concat(getMisiLines(), "\n")
end
local function getWaterAmount() return LocalPlayer:GetAttribute("WaterAmount") or 0 end
local function getMaxWater()
    local lvl = LocalPlayer:GetAttribute("WellLevel") or 1
    local ok, WellConfig = pcall(function() return require(ReplicatedStorage.Modules:WaitForChild("WellConfig")) end)
    if ok and WellConfig[lvl] then return WellConfig[lvl].MaxWater or 700 end
    return 700
end
local function getGrassData()
    local ok, json = pcall(function() return LocalPlayer:GetAttribute("GrassData_JSON") end)
    if not ok or not json then return {} end
    local ok2, data = pcall(function() return HttpService:JSONDecode(json) end)
    if ok2 and type(data)=="table" then return data else return {} end
end
local function getMyFarm()
    local farms = workspace:FindFirstChild("Farm")
    if not farms then return nil end
    for _, f in ipairs(farms:GetChildren()) do
        local ok, owner = pcall(function() return f:GetAttribute("OwnerId") end)
        if ok and owner == LocalPlayer.UserId then return f end
    end
    return farms:FindFirstChild("Farm1")
end
local function getFarmBounds()
    local farm = getMyFarm()
    local ground = farm and farm:FindFirstChild("Ground")
    if ground and ground:IsA("BasePart") then return ground.Position, ground.Size end
    return Vector3.new(165,-18,-18), Vector3.new(46,1,56)
end
local function isInFarm1(pos)
    local gPos, gSize = getFarmBounds()
    return math.abs(pos.X - gPos.X) <= gSize.X/2 -2 and math.abs(pos.Z - gPos.Z) <= gSize.Z/2 -2
end
local function getFarm1RandomPos()
    local gPos, gSize = getFarmBounds()
    local halfX = gSize.X/2 -4
    local halfZ = gSize.Z/2 -4
    return Vector3.new(gPos.X + math.random(-halfX,halfX), gPos.Y+5, gPos.Z + math.random(-halfZ,halfZ))
end
local function doPour(tool, duration)
    local rem = tool and tool:FindFirstChild("WaterRemote")
    local handle = tool and tool:FindFirstChild("Handle")
    local wp = handle and handle:FindFirstChild("WaterPoint")
    if rem then pcall(function() rem:FireServer("StartPouring") end) end
    local bind = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("WateringStateEvent")
    if bind then pcall(function() bind:Fire("StartPouring", wp) end) end
    task.wait(duration or 2)
    if rem then pcall(function() rem:FireServer("StopPouring") end) end
    if bind then pcall(function() bind:Fire("StopPouring", nil) end) end
end

local TierSuffix = {Default="", Gold=" Emas", Sakura=" Sakura", Cosmic=" Cosmic"}
local function getInputReq(factory, tier)
    local c = FactoryConfig.Config[factory]
    if not c then return 2 end
    if tier=="Default" then return c.InputReq or 2 end
    local input = c.InputName
    if input=="Telur" or input=="Wol" or input=="Daging" or input=="Susu" then return 3 end
    return 2
end
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local RequestStartProduction = RemotesFolder and RemotesFolder:FindFirstChild("RequestStartProduction") or ReplicatedStorage:WaitForChild("RequestStartProduction")
local RequestClaimProduction = RemotesFolder and RemotesFolder:FindFirstChild("RequestClaimProduction") or ReplicatedStorage:WaitForChild("RequestClaimProduction")
local RequestSendDelivery = ReplicatedStorage:WaitForChild("RequestSendDelivery")
local ClaimQuestRemote = (RemotesFolder and RemotesFolder:FindFirstChild("ClaimQuest")) or ReplicatedStorage:WaitForChild("ClaimQuest")
local FACTORIES = {"FlourFactory","BreadFactory","YarnFactory","SweaterFactory","SausageFactory","HotdogFactory","ButterFactory","CheeseFactory"}
local TIERS = {"Default","Gold","Sakura","Cosmic"}

-- MAIN DASHBOARD
MainTab:CreateText({ name = "YUPI HUB", text = "Yupi Hub - Farm Industry" })
local statusFactory = MainTab:CreateStat({ name = "Factory", value = 0, suffix = " ON" })
local statusWater = MainTab:CreateStat({ name = "Water", value = math.floor((getWaterAmount()/getMaxWater())*100), suffix = "%" })
local statusDelivery = MainTab:CreateStat({ name = "Delivery Items", value = getTotalItems(), suffix = "/360" })
local statusMagnet = MainTab:CreateStat({ name = "Magnet", value = 0, suffix = "" })
MainTab:CreateDivider({ text = "Kecepatan Lari" })
local speedToggle = MainTab:CreateToggle({
    name = "Auto Speed",
    description = "Kunci WalkSpeed sesuai slider (1 pelan - 100 tercepat)",
    value = false, flag = "AutoSpeed",
    callback = function(v) cfg.autoSpeed = v; notify("Auto Speed", v and "AKTIF" or "MATI", 2) end,
})
local speedSlider = MainTab:CreateSlider({
    name = "Target Speed",
    description = "1 = pelan banget, 100 = paling cepat",
    range = {1,100}, increment = 1, value = 36, suffix = "", flag = "SpeedTarget",
    callback = function(v) cfg.speedTarget = v; notify("Target Speed", v, 1.5) end,
})
MainTab:CreateDivider({ text = "Recent Activity" })
local console = MainTab:CreateConsole({ name = "Aktivitas", height = 100, follow = true, maxLines = 100 })
local function styleConsoleText()
    pcall(function()
        local rg = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        if not rg then return end
        for _, v in ipairs(rg:GetDescendants()) do
            if v.Name == "Aktivitas" and v:IsA("Frame") then
                for _, d in ipairs(v:GetDescendants()) do
                    if d:IsA("TextLabel") then pcall(function() d.RichText = true end) end
                end
            end
        end
    end)
end
local activityFeed = {}
local dashBuilt = false
local refreshDashActivity = nil
local syncDashFactory = nil
local function log(msg)
    local stamp = os.date("%H:%M:%S")
    console:Append('<font color="#9CA3AF">['..stamp..']</font> '..msg); print("["..stamp.."] "..msg)
    styleConsoleText()
    pcall(function()
        local amt = string.match(msg, "([%+x]%d+)%s*$")
        local clean = msg
        if amt then clean = string.match(string.sub(msg, 1, #msg - #amt), "^(.-)%s*$") or msg end
        table.insert(activityFeed, 1, {t = stamp, m = clean, a = amt or ""})
        while #activityFeed > 25 do table.remove(activityFeed) end
        if dashBuilt and refreshDashActivity then refreshDashActivity() end
    end)
end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local factoryOn = cfg.autoProduksi and 1 or 0
            statusFactory:Set(factoryOn)
            statusWater:Set(math.floor((getWaterAmount()/getMaxWater())*100))
            statusDelivery:Set(getTotalItems())
            statusMagnet:Set(cfg.autoAmbilMagnet and 1 or 0)
        end)
    end
end)

-- FACTORY TAB - Bulk Otomatis (Mode Produksi dihapus, selalu bulk)
FactoryTab:CreateText({ name = "Produksi Otomatis", text = "Bulk Otomatis - Pilih jumlah & tier, produksi jalan sendiri" })
local autoProduksiToggle = FactoryTab:CreateToggle({
    name = "Auto Produksi",
    description = "ON = otomatis ambil + bulk produksi, OFF = stop total",
    value = true,
    flag = "AutoProduksi",
    callback = function(v)
        cfg.autoProduksi = v
        cfg.autoAmbil = v
        cfg.produksiLagi = v
        log("Auto Produksi: "..tostring(v))
        notify("Auto Produksi", v and "AKTIF - Bulk x"..cfg.amount or "MATI", 2)
    end,
})
cfg.autoProduksi = true
local jumlahDropdown = FactoryTab:CreateDropdown({
    name = "Jumlah Produksi",
    description = "Jumlah produk setiap kali pabrik mulai",
    options = {"1","2","5","10"},
    value = "5",
    flag = "JumlahProduksi",
    callback = function(v)
        local val = tonumber(type(v)=="table" and v[1] or v) or 5
        cfg.amount = val
        log("Jumlah produksi: "..val)
        notify("Jumlah Produksi", val.." produk", 2)
    end,
})
local tierDropdown = FactoryTab:CreateDropdown({
    name = "Tier Produksi",
    description = "Pilih tier - Semua = bulk Emas+Sakura+Cosmic, atau pilih spesifik. Default tier dihapus.",
    options = {"Semua","Emas","Sakura","Cosmic"},
    value = {"Semua"},
    multiSelect = true,
    flag = "TierProduksi",
    callback = function(v)
        local vals = type(v)=="table" and v or {v}
        local hasSemua=false
        for _,val in ipairs(vals) do if val=="Semua" then hasSemua=true break end end
        if hasSemua then
            cfg.enabledTiers = {"Default","Gold","Sakura","Cosmic"}
            log("Tier produksi: Semua (Default+Emas+Sakura+Cosmic)")
            notify("Tier Produksi", "Semua (Default+Emas+Sakura+Cosmic)", 2.5)
            return
        end
        local map = {Emas="Gold", Sakura="Sakura", Cosmic="Cosmic"}
        local enabled = {}
        for _, val in ipairs(vals) do
            local internal = map[val] or val
            if internal ~= "Default" then table.insert(enabled, internal) end
        end
        if #enabled==0 then enabled={"Gold"} vals={"Emas"} end
        cfg.enabledTiers = enabled
        log("Tier produksi: "..table.concat(vals,", "))
        notify("Tier Produksi", table.concat(vals,", "), 2.5)
    end,
})
-- default enabled tiers Semua (include Default biar stok Default kepakai)
cfg.enabledTiers = {"Default","Gold","Sakura","Cosmic"}
-- Mode Produksi dihapus per request - selalu bulk otomatis
-- Default: Ambil Otomatis ON, Produksi Lagi ON (bulk x Jumlah Produksi)
cfg.autoAmbil = true
cfg.produksiLagi = true
cfg.produksiTerus = false
cfg.modeProduksi = "Setelah hasil diambil" -- dummy, tidak dipakai
FactoryTab:CreateText({ name = "Info Factory", text = "🏭 Produksi → 📦 Ambil Otomatis → 🏭 Bulk Produksi Lagi x Jumlah" })
local autoMisiToggle = FactoryTab:CreateToggle({
    name = "Auto Misi",
    description = "Reserve stok misi + prioritaskan produksi + auto claim",
    value = false,
    flag = "AutoMisi",
    callback = function(v)
        cfg.autoMisi = v
        if v then refreshReserved() else missionReserved = {} end
        log("Auto Misi: "..tostring(v))
        notify("Auto Misi", v and "AKTIF" or "MATI", 2)
    end,
})
local fokusDropdown = FactoryTab:CreateDropdown({
    name = "Fokus Misi",
    description = "Misi mana diselesaikan dulu (urutan daftar). claim tetap semua yg selesai.",
    options = {"Semua","1 Teratas","3 Teratas","5 Teratas"},
    value = "Semua",
    flag = "MisiFokus",
    callback = function(v)
        local val = type(v)=="table" and v[1] or v
        cfg.misiFokus = val
        if cfg.autoMisi then refreshReserved() end
        log("Fokus misi: "..tostring(val))
        notify("Fokus Misi", tostring(val), 2)
    end,
})
local misiStatusText = FactoryTab:CreateText({ name = "Daftar Misi", text = "Auto Misi OFF" })
FactoryTab:CreateButton({
    name = "LIHAT MISI",
    description = "Tampilkan daftar misi + reserve di log",
    callback = function()
        refreshReserved()
        for _, line in ipairs(getMisiLines()) do log(line) end
    end,
})

-- FACTORY CONFIG - simpan/muat setting tab Factory (folder FactoryConfigs/)
local CONFIG_DIR = "FactoryConfigs"
local selectedConfig, newConfigName, configDropdown = nil, "", nil
local function ensureConfigDir()
    pcall(function()
        if isfolder(CONFIG_DIR) then return end
        makefolder(CONFIG_DIR)
    end)
end
local function configPath(name) return CONFIG_DIR .. "/" .. name .. ".json" end
local function cleanConfigName(name)
    if type(name) ~= "string" then return "" end
    local s = string.match(name, "^%s*(.-)%s*$") or ""
    s = string.gsub(s, "[/\\]", "_")
    return s
end
local function collectFactoryConfig()
    return {
        version = 1,
        autoProduksi = cfg.autoProduksi,
        amount = cfg.amount,
        enabledTiers = cfg.enabledTiers,
        autoMisi = cfg.autoMisi,
        misiFokus = type(cfg.misiFokus) == "table" and cfg.misiFokus[1] or cfg.misiFokus,
        autoKirim = cfg.autoKirim,
        kirimBerdasarkan = cfg.kirimBerdasarkan,
        intervalKirim = cfg.intervalKirim,
        jenisKirim = cfg.jenisKirim,
        kecualikan = cfg.kecualikan,
        autoSiram = cfg.autoSiram,
        waktuSiram = cfg.waktuSiram,
        autoIsiAir = cfg.autoIsiAir,
        isiSaat = cfg.isiSaat,
        autoAmbilMagnet = cfg.autoAmbilMagnet,
        itemDiambil = cfg.itemDiambil,
        jarakAmbil = cfg.jarakAmbil,
        autoDestroy = cfg.autoDestroy,
        autoResearchLab = cfg.autoResearchLab,
        researchPriority = cfg.researchPriority,
        autoFarmMastery = cfg.autoFarmMastery,
        farmMasteryPriority = cfg.farmMasteryPriority,
        autoSpeed = cfg.autoSpeed,
        speedTarget = cfg.speedTarget,
        autoWolf = cfg.autoWolf,
        wolfMinHp = cfg.wolfMinHp,
    }
end
local LAST_PATH = CONFIG_DIR .. "/last.json"
local function saveLast()
    pcall(function()
        ensureConfigDir()
        writefile(LAST_PATH, HttpService:JSONEncode(collectFactoryConfig()))
    end)
end
local function ListConfigs()
    local names = {}
    pcall(function()
        ensureConfigDir()
        for _, p in ipairs(listfiles(CONFIG_DIR)) do
            local n = string.match(p, "([^/\\]+)%.json$")
            if n and n ~= "last" then names[#names + 1] = n end
        end
    end)
    table.sort(names)
    return names
end
local function refreshConfigList()
    if not configDropdown then return end
    local names = ListConfigs()
    if #names == 0 then names = {"Belum ada config"} end
    pcall(function() configDropdown:Refresh(names) end)
    if not selectedConfig then selectedConfig = names[1] end
end
local tierToDisplay = {Default = nil, Gold = "Emas", Sakura = "Sakura", Cosmic = "Cosmic"}
local function applyFactoryConfig(data)
    if type(data) ~= "table" then return false end
    if data.autoProduksi ~= nil then
        cfg.autoProduksi = (data.autoProduksi == true)
        cfg.autoAmbil = cfg.autoProduksi
        cfg.produksiLagi = cfg.autoProduksi
    end
    if tonumber(data.amount) then cfg.amount = math.floor(tonumber(data.amount)) end
    if type(data.enabledTiers) == "table" and #data.enabledTiers > 0 then cfg.enabledTiers = data.enabledTiers end
    if data.autoMisi ~= nil then cfg.autoMisi = (data.autoMisi == true) end
    if type(data.misiFokus) == "string" then cfg.misiFokus = data.misiFokus end
    if data.autoKirim ~= nil then cfg.autoKirim = (data.autoKirim == true) end
    if type(data.kirimBerdasarkan) == "string" then cfg.kirimBerdasarkan = data.kirimBerdasarkan end
    if tonumber(data.intervalKirim) then cfg.intervalKirim = math.floor(tonumber(data.intervalKirim)) end
    if type(data.jenisKirim) == "table" then cfg.jenisKirim = data.jenisKirim end
    if type(data.kecualikan) == "table" then cfg.kecualikan = data.kecualikan end
    if data.autoSiram ~= nil then cfg.autoSiram = (data.autoSiram == true) end
    if tonumber(data.waktuSiram) then cfg.waktuSiram = math.floor(tonumber(data.waktuSiram)) end
    if data.autoIsiAir ~= nil then cfg.autoIsiAir = (data.autoIsiAir == true) end
    if tonumber(data.isiSaat) then cfg.isiSaat = tonumber(data.isiSaat) end
    if data.autoAmbilMagnet ~= nil then cfg.autoAmbilMagnet = (data.autoAmbilMagnet == true) end
    if type(data.itemDiambil) == "string" then cfg.itemDiambil = data.itemDiambil end
    if tonumber(data.jarakAmbil) then cfg.jarakAmbil = tonumber(data.jarakAmbil) end
    if data.autoDestroy ~= nil then cfg.autoDestroy = (data.autoDestroy == true) end
    if data.autoResearchLab ~= nil then cfg.autoResearchLab = (data.autoResearchLab == true) end
    if type(data.researchPriority) == "table" and #data.researchPriority > 0 then cfg.researchPriority = data.researchPriority cfg.researchPilihan = data.researchPriority end
    if data.autoFarmMastery ~= nil then cfg.autoFarmMastery = (data.autoFarmMastery == true) end
    if type(data.farmMasteryPriority) == "table" and #data.farmMasteryPriority > 0 then cfg.farmMasteryPriority = data.farmMasteryPriority cfg.farmSkillPilihan = data.farmMasteryPriority end
    if data.autoSpeed ~= nil then cfg.autoSpeed = (data.autoSpeed == true) end
    if tonumber(data.speedTarget) then cfg.speedTarget = math.clamp(math.floor(tonumber(data.speedTarget)), 1, 100) end
    if data.autoWolf ~= nil then cfg.autoWolf = (data.autoWolf == true) end
    if tonumber(data.wolfMinHp) then cfg.wolfMinHp = tonumber(data.wolfMinHp) end
    if cfg.autoMisi then refreshReserved() else missionReserved = {} end
    pcall(function() autoProduksiToggle:Set(cfg.autoProduksi) end)
    pcall(function() jumlahDropdown:Set(tostring(cfg.amount)) end)
    local disp = {}
    local hasAll = false
    pcall(function()
        local set = {}
        for _, t in ipairs(cfg.enabledTiers or {}) do set[t] = true end
        if set.Default and set.Gold and set.Sakura and set.Cosmic then hasAll = true end
    end)
    if hasAll then
        disp = {"Semua"}
    else
        for _, t in ipairs(cfg.enabledTiers or {}) do
            if tierToDisplay[t] then disp[#disp + 1] = tierToDisplay[t] end
        end
    end
    if #disp > 0 then pcall(function() tierDropdown:Set(disp) end) end
    pcall(function() autoMisiToggle:Set(cfg.autoMisi) end)
    pcall(function() fokusDropdown:Set(cfg.misiFokus) end)
    pcall(function() autoKirimToggle:Set(cfg.autoKirim) end)
    pcall(function() kirimDropdown:Set(cfg.kirimBerdasarkan) end)
    pcall(function() intervalSlider:Set(cfg.intervalKirim) end)
    if type(cfg.jenisKirim) == "table" and #cfg.jenisKirim > 0 then pcall(function() jenisDropdown:Set(cfg.jenisKirim) end) end
    if type(cfg.kecualikan) == "table" then
        if #cfg.kecualikan > 0 then pcall(function() kecualikanDropdown:Set(cfg.kecualikan) end)
        else pcall(function() kecualikanDropdown:Set({"Tidak Ada"}) end) end
    end
    pcall(function() siramToggle:Set(cfg.autoSiram) end)
    pcall(function() waktuSiramDropdown:Set(tostring(cfg.waktuSiram) .. " detik") end)
    pcall(function() isiAirToggle:Set(cfg.autoIsiAir) end)
    pcall(function() isiSaatSlider:Set(cfg.isiSaat) end)
    pcall(function() magnetToggle:Set(cfg.autoAmbilMagnet) end)
    pcall(function() itemDropdown:Set(cfg.itemDiambil) end)
    pcall(function() jarakSlider:Set(cfg.jarakAmbil) end)
    pcall(function() autoDestroyToggle:Set(cfg.autoDestroy) end)
    pcall(function() researchToggle:Set(cfg.autoResearchLab) end)
    if type(cfg.researchPriority) == "table" and #cfg.researchPriority > 0 then pcall(function() researchDropdown:Set(cfg.researchPriority) end) end
    pcall(function() farmToggle:Set(cfg.autoFarmMastery) end)
    if type(cfg.farmMasteryPriority) == "table" and #cfg.farmMasteryPriority > 0 then pcall(function() farmDropdown:Set(cfg.farmMasteryPriority) end) end
    pcall(function() speedToggle:Set(cfg.autoSpeed) end)
    pcall(function() speedSlider:Set(cfg.speedTarget) end)
    pcall(function() wolfToggle:Set(cfg.autoWolf) end)
    pcall(function() wolfMinSlider:Set(cfg.wolfMinHp) end)
    pcall(function() wolfStatusText:Set(cfg.autoWolf and "Mencari serigala..." or "Auto serigala OFF") end)
    pcall(function() misiStatusText:Set(cfg.autoMisi and getReservedText() or "Auto Misi OFF") end)
    pcall(function() if syncDashFactory then syncDashFactory() end end)
    return true
end
local function SaveConfig(name)
    name = cleanConfigName(name)
    if name == "" then notify("Config", "Nama config kosong", 2.5) return false end
    ensureConfigDir()
    local ok, err = pcall(function()
        writefile(configPath(name), HttpService:JSONEncode(collectFactoryConfig()))
    end)
    if ok then
        selectedConfig = name
        saveLast()
        log("Config tersimpan: " .. name)
        notify("Config", "Tersimpan " .. name, 2)
        refreshConfigList()
    else
        notify("Config", "Gagal simpan: " .. tostring(err), 3)
    end
    return ok
end
local function LoadConfig(name)
    name = cleanConfigName(name)
    if name == "" or name == "Belum ada config" then notify("Config", "Pilih config dulu", 2.5) return false end
    ensureConfigDir()
    local exists = false
    pcall(function() exists = isfile(configPath(name)) end)
    if not exists then notify("Config", "File tidak ditemukan: " .. name, 3) return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(configPath(name))) end)
    if not ok or type(data) ~= "table" then notify("Config", "File rusak: " .. name, 3) return false end
    applyFactoryConfig(data)
    selectedConfig = name
    saveLast()
    log("Config dimuat: " .. name)
    notify("Config", "Dimuat " .. name, 2)
    return true
end
local function DeleteConfig(name)
    name = cleanConfigName(name)
    if name == "" or name == "Belum ada config" then notify("Config", "Pilih config dulu", 2.5) return false end
    local ok, err = pcall(function() delfile(configPath(name)) end)
    if ok then
        if selectedConfig == name then selectedConfig = nil end
        log("Config dihapus: " .. name)
        notify("Config", "Dihapus " .. name, 2)
        refreshConfigList()
    else
        notify("Config", "Gagal hapus: " .. tostring(err), 3)
    end
    return ok
end
SettingsTab:CreateText({ name = "Config Title", text = "Simpan & muat semua setting" })
configDropdown = SettingsTab:CreateDropdown({
    name = "Pilih Config",
    description = "Daftar config yang tersimpan",
    options = {"Belum ada config"},
    value = "Belum ada config",
    flag = "PilihConfig",
    callback = function(v)
        local val = type(v)=="table" and v[1] or v
        if val == nil or val == "" then return end
        selectedConfig = val
        log("Config dipilih: " .. tostring(val))
    end,
})
SettingsTab:CreateInput({
    name = "Nama Config Baru",
    placeholder = "cth: hemat-bahan (Enter)",
    flag = "NamaConfig",
    callback = function(v)
        newConfigName = type(v)=="table" and v[1] or v
    end,
})
SettingsTab:CreateButton({
    name = "SAVE CONFIG",
    description = "Simpan setting saat ini ke nama config",
    callback = function() SaveConfig(newConfigName) end,
})
SettingsTab:CreateButton({
    name = "LOAD CONFIG",
    description = "Muat config terpilih + sinkron tampilan",
    callback = function() LoadConfig(selectedConfig) end,
})
SettingsTab:CreateButton({
    name = "DELETE CONFIG",
    description = "Hapus config terpilih",
    callback = function() DeleteConfig(selectedConfig) end,
})
refreshConfigList()

-- WATER TAB
WaterTab:CreateText({ name = "Perawatan Rumput", text = "Jaga rumput tetap hijau" })
siramToggle = WaterTab:CreateToggle({
    name = "Auto Siram",
    description = "Otomatis mencari rumput kering dan menyiramnya",
    value = false, flag = "AutoSiram",
    callback = function(v) cfg.autoSiram = v; log("Auto siram: "..tostring(v)); notify("Auto Siram", v and "AKTIF" or "MATI", 2) end,
})
waktuSiramDropdown = WaterTab:CreateDropdown({
    name = "Waktu Menyiram",
    description = "Lama menyiram di setiap titik",
    options = {"1 detik","2 detik","3 detik"},
    value = "2 detik",
    flag = "WaktuSiram",
    callback = function(v)
        local val = type(v)=="table" and v[1] or v
        local num = tonumber(val:match("%d+")) or 2
        cfg.waktuSiram = num
        log("Waktu siram: "..num.." detik")
        notify("Waktu Menyiram", val, 2)
    end,
})
WaterTab:CreateDivider({ text = "Isi Air" })
isiAirToggle = WaterTab:CreateToggle({
    name = "Auto Isi Air",
    description = "Isi ulang air otomatis saat persediaan rendah",
    value = true, flag = "AutoIsiAir",
    callback = function(v) cfg.autoIsiAir = v; log("Auto isi air: "..tostring(v)); notify("Auto Isi Air", v and "AKTIF" or "MATI", 2) end,
})
isiSaatSlider = WaterTab:CreateSlider({
    name = "Isi Ulang Saat",
    description = "Teleport ke sumur dan isi sampai penuh",
    range = {10,90}, increment = 5, value = 30, suffix = "%", flag = "IsiSaat",
    callback = function(v) cfg.isiSaat = v; notify("Isi Ulang Saat", v.."%", 1.5) end,
})
WaterTab:CreateText({ name = "Info Isi", text = "Isi ulang saat air di bawah 30% → isi sampai penuh" })

-- DELIVERY TAB
DeliveryTab:CreateText({ name = "Auto Kirim", text = "Kirim hasil ke kota secara otomatis" })
autoKirimToggle = DeliveryTab:CreateToggle({
    name = "Auto Kirim",
    description = "Kirim otomatis sesuai mode",
    value = false, flag = "AutoKirim",
    callback = function(v) cfg.autoKirim = v; log("Auto kirim: "..tostring(v)); notify("Auto Kirim", v and "AKTIF - "..cfg.kirimBerdasarkan or "MATI", 2.5) end,
})
kirimDropdown = DeliveryTab:CreateDropdown({
    name = "Kirim Berdasarkan",
    description = "Pilih kapan kirim terjadi (interval di bawah tetap dipakai)",
    options = {"Setiap Interval","Saat tas penuh","Saat berat penuh","Saat ada item"},
    value = "Setiap Interval",
    flag = "KirimBerdasarkan",
    callback = function(v)
        local val = type(v)=="table" and v[1] or v
        -- backward compat: Setiap 22 detik = Setiap Interval
        if val=="Setiap 22 detik" then val="Setiap Interval" end
        cfg.kirimBerdasarkan = val
        log("Kirim berdasarkan: "..val)
        notify("Kirim Berdasarkan", val, 2.5)
    end,
})
intervalSlider = DeliveryTab:CreateSlider({
    name = "Interval",
    description = "Jeda antar pengiriman",
    range = {10,60}, increment = 2, value = 22, suffix = " detik", flag = "IntervalKirim",
    callback = function(v) cfg.intervalKirim = v; notify("Interval", v.." detik", 1.5) end,
})
jenisDropdown = DeliveryTab:CreateDropdown({
    name = "Jenis Item Dikirim",
    description = "Pilih kategori yang dikirim (bisa pilih banyak). Mentah: Telur/Wol/Susu/Daging. Olahan: Tepung/Benang/Sosis/Mentega. Jadi: Roti/Sweater/Hotdog/Keju.",
    options = {"Mentah", "Olahan", "Jadi"},
    value = {"Mentah", "Olahan", "Jadi"},
    multiSelect = true,
    flag = "JenisKirim",
    callback = function(v)
        local vals = type(v)=="table" and v or {v}
        cfg.jenisKirim = vals
        log("Jenis kirim: "..table.concat(vals, ", "))
        notify("Jenis Kirim", table.concat(vals, ", "), 2.5)
    end,
})
kecualikanDropdown = DeliveryTab:CreateDropdown({
    name = "Kecualikan Item",
    description = "Item yang TIDAK dikirim walau lolos Jenis (bisa pilih banyak). Pilih Tidak Ada = kirim semua.",
    options = {"Tidak Ada","Benang","Benang Cosmic","Benang Emas","Benang Sakura","Daging","Daging Cosmic","Daging Emas","Daging Sakura","Daging Serigala","Hotdog","Hotdog Cosmic","Hotdog Emas","Hotdog Sakura","Keju","Keju Cosmic","Keju Emas","Keju Sakura","Mentega","Mentega Cosmic","Mentega Emas","Mentega Sakura","Roti","Roti Cosmic","Roti Emas","Roti Sakura","Sosis","Sosis Cosmic","Sosis Emas","Sosis Sakura","Susu","Susu Cosmic","Susu Emas","Susu Sakura","Sweater","Sweater Cosmic","Sweater Emas","Sweater Sakura","Telur","Telur Cosmic","Telur Emas","Telur Sakura","Tepung","Tepung Cosmic","Tepung Emas","Tepung Sakura","Wol","Wol Cosmic","Wol Emas","Wol Sakura"},
    value = {"Tidak Ada"},
    multiSelect = true,
    flag = "Kecualikan",
    callback = function(v)
        local vals = type(v)=="table" and v or {v}
        local clean={}
        for _,val in ipairs(vals) do if val~="Tidak Ada" then table.insert(clean,val) end end
        cfg.kecualikan = clean
        log("Kecualikan: "..(#clean==0 and "tidak ada" or table.concat(clean,", ")))
        notify("Kecualikan", #clean==0 and "Tidak ada" or table.concat(clean,", "), 2.5)
    end,
})
DeliveryTab:CreateButton({
    name = "KIRIM SEKARANG",
    description = "Kirim semua isi tas sekarang",
    callback = function()
        notify("Kirim", "Mengirim...", 1.5)
        if cfg.autoMisi then refreshReserved() end
        local inv = getInventory()
        local payload, totalW = {}, 0
        local lvl = LocalPlayer:GetAttribute("DeliveryLevel") or 1
        local cap = (DeliveryConfig.Levels[lvl] and DeliveryConfig.Levels[lvl].Capacity) or 4000
        for item,cnt in pairs(inv) do
            local have2 = cnt
            if cfg.autoMisi then have2 = math.max(0, cnt - (missionReserved[item] or 0)) end
            if DeliveryConfig.Items[item] and have2>0 and allowKirim(item) and not isKecualikan(item) then
                local w = DeliveryConfig.Items[item].Weight or 1
                local can = math.min(have2, math.floor((cap-totalW)/w))
                if can>0 then payload[item]=can; totalW+=can*w end
            end
        end
        if next(payload)==nil then notify("Kirim", "Tas kosong / semua dikecualikan", 2) return end
        local ok,a,b = pcall(function() return RequestSendDelivery:InvokeServer(payload) end)
        if ok and a then log("Kirim "..totalW.."kg berhasil"); notify("Berhasil", "Terkirim "..totalW.."kg", 3) else notify("Gagal", tostring(b), 3) end
    end,
})

-- MAGNET TAB
MagnetTab:CreateText({ name = "Auto Ambil", text = "Sapu bersih seluruh farm + kembali ke posisi awal" })
magnetToggle = MagnetTab:CreateToggle({
    name = "Auto Ambil",
    description = "Otomatis menyapu seluruh farm tiap beberapa detik (brutal, tanpa delay 1-1)",
    value = false, flag = "AutoAmbil",
    callback = function(v) cfg.autoAmbilMagnet = v; log("Auto ambil: "..tostring(v)); notify("Auto Ambil", v and "AKTIF" or "MATI", 2) end,
})
itemDropdown = MagnetTab:CreateDropdown({
    name = "Item Yang Diambil",
    description = "Pilih jenis item",
    options = {"Semua","Emas & Cosmic","Sakura & Cosmic","Emas","Cosmic"},
    value = "Semua",
    flag = "ItemDiambil",
    callback = function(v)
        local val = type(v)=="table" and v[1] or v
        cfg.itemDiambil = val
        log("Item diambil: "..val)
        notify("Item Diambil", val, 2)
    end,
})
jarakSlider = MagnetTab:CreateSlider({
    name = "Delay Sapu Otomatis",
    description = "Jeda antar sapuan saat Auto Ambil ON (kecil = brutal, besar = ringan)",
    range = {1,5}, increment = 0.5, value = 2, suffix = " detik", flag = "JarakAmbil",
    callback = function(v) cfg.jarakAmbil = v; notify("Delay Sapu", v.." detik", 1.5) end,
})
local function matchMagnet(name)
    if cfg.itemDiambil=="Semua" then return true end
    if cfg.itemDiambil=="Emas & Cosmic" then return name:find("Emas") or name:find("Cosmic") end
    if cfg.itemDiambil=="Sakura & Cosmic" then return name:find("Sakura") or name:find("Cosmic") end
    if cfg.itemDiambil=="Emas" then return name:find("Emas") end
    if cfg.itemDiambil=="Cosmic" then return name:find("Cosmic") end
    return true
end
local sweeping = false
local function brutalSweep(maxItems)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local farm = getMyFarm()
    if not hrp or not farm then return 0, 0 end
    if sweeping then return 0, 0 end
    sweeping = true
    local startCf = hrp.CFrame
    local before = getTotalItems()
    local n = 0
    for _, tool in ipairs(farm:GetChildren()) do
        if tool:IsA("Tool") and matchMagnet(tool.Name) then
            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
            local prompt = handle and handle:FindFirstChild("ProductPrompt")
            if prompt and prompt.Enabled and prompt.ObjectText ~= "Produk Tetangga" then
                pcall(function()
                    prompt.MaxActivationDistance = 100
                    prompt.RequiresLineOfSight = false
                    hrp.CFrame = handle.CFrame * CFrame.new(0, 3, 0)
                end)
                task.wait(0.2)
                pcall(function() fireproximityprompt(prompt, prompt.HoldDuration) end)
                if prompt.HoldDuration > 0 then task.wait(prompt.HoldDuration + 0.3) else task.wait(0.2) end
                n += 1
                if n >= (maxItems or 25) then break end
            end
        end
    end
    task.wait(0.5)
    pcall(function() hrp.CFrame = startCf end)
    task.wait(0.2)
    local delta = getTotalItems() - before
    sweeping = false
    return delta, n
end
MagnetTab:CreateButton({
    name = "SAPU SAMPAI BERSIH",
    description = "Loop sapu terus sampai farm kosong (brutal) - 250 item",
    callback = function()
        if sweeping then notify("Sapu", "Masih menyapu", 2) return end
        task.spawn(function()
            local total=0
            for i=1, 10 do
                local d,n = brutalSweep(25)
                total+=d
                log("Sapu bersih loop "..i..": +"..d.." ("..n..") total +"..total)
                if n < 25 then break end
                task.wait(0.5)
            end
            notify("Sapu Bersih", "Selesai total +"..total, 3)
        end)
    end,
})

-- SERIGALA TAB - Auto hajar werewolf se-map (nempel brutal, tanpa jalan)
local wolfRegistry = {}
local function inspectWolf(m, hum)
    pcall(function()
        local info = {}
        info[#info + 1] = "name=" .. m.Name .. " class=" .. m.ClassName .. " path=" .. m:GetFullName()
        info[#info + 1] = "hp=" .. tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))
        local hrp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
        info[#info + 1] = "pos=" .. tostring(hrp and hrp.Position)
        local kinds = {}
        for _, d in ipairs(m:GetDescendants()) do
            local k = d.ClassName
            kinds[k] = (kinds[k] or 0) + 1
        end
        local ks = {}
        for k, c in pairs(kinds) do ks[#ks + 1] = k .. "x" .. c end
        table.sort(ks)
        info[#info + 1] = "parts=" .. table.concat(ks, ",")
        local taps = {}
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("ClickDetector") then taps[#taps+1] = "Click:" .. d.Name .. ":dist=" .. tostring(d.MaxActivationDistance) end
            if d:IsA("ProximityPrompt") then taps[#taps+1] = "Prompt:" .. d.Name .. ":hold=" .. tostring(d.HoldDuration) .. ":dist=" .. tostring(d.MaxActivationDistance) end
        end
        info[#info + 1] = "taps=" .. (#taps > 0 and table.concat(taps, "|") or "NONE")
        local at = {}
        pcall(function() for k, v in pairs(m:GetAttributes()) do at[#at+1] = k .. "=" .. tostring(v) end end)
        info[#info + 1] = "attrs=" .. (#at > 0 and table.concat(at, ";") or "-")
        local txt = table.concat(info, "\n")
        log("Serigala spawn:\n" .. txt)
        writefile("mcp/wolf-signature.txt", txt)
    end)
end
pcall(function()
    if getgenv().YupiWolfConn then getgenv().YupiWolfConn:Disconnect() end
    getgenv().YupiWolfConn = workspace.DescendantAdded:Connect(function(v)
        if v:IsA("Humanoid") then
            local m = v.Parent
            local isP = false
            pcall(function() isP = Players:GetPlayerFromCharacter(m) ~= nil end)
            if not isP and m and m:IsA("Model") then
                wolfRegistry[m] = {model = m, hum = v, t = os.clock()}
                inspectWolf(m, v)
            end
        end
    end)
end)
local function liveWolves()
    local res = {}
    for m, w in pairs(wolfRegistry) do
        if m and m.Parent and w.hum and w.hum.Health > 0 then
            res[#res + 1] = w
        else
            wolfRegistry[m] = nil
        end
    end
    return res
end
local function findWolves()
    local live = liveWolves()
    if #live > 0 then return live end
    local res = {}
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Humanoid") and v.Health > 0 then
                local m = v.Parent
                local isP = false
                pcall(function() isP = Players:GetPlayerFromCharacter(m) ~= nil end)
                if not isP and m and m:IsA("Model") then
                    res[#res + 1] = {model = m, hum = v}
                end
            end
        end
    end)
    return res
end
local function equipShears()
    local char = LocalPlayer.Character
    if not char then return false end
    if char:FindFirstChild("Shears") then return true end
    local tool = LocalPlayer.Backpack:FindFirstChild("Shears")
    if tool then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:EquipTool(tool) end) else tool.Parent = char end
        task.wait(0.3)
        return char:FindFirstChild("Shears") ~= nil
    end
    return false
end
local function getWolfText()
    local wolves = findWolves()
    if #wolves == 0 then return "Tidak ada serigala" end
    local lines = {}
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    for i, w in ipairs(wolves) do
        local hrp = w.model:FindFirstChild("HumanoidRootPart") or w.model.PrimaryPart
        local dist = ""
        if myPos and hrp then dist = " [" .. math.floor((myPos - hrp.Position).Magnitude) .. "m]" end
        lines[#lines + 1] = i .. ". " .. w.model.Name .. " " .. math.floor(w.hum.Health) .. "/" .. math.floor(w.hum.MaxHealth) .. dist
        if i >= 8 then break end
    end
    return table.concat(lines, "\n")
end
local wolfBusy = false
local function wolfAnchor(w)
    local m = w.model
    for _, n in ipairs({"HumanoidRootPart", "UpperTorso", "Torso", "Head"}) do
        local p = m:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return m:FindFirstChildWhichIsA("BasePart")
end
local function wolfTap(w)
    local n = 0
    local tb = w.model:FindFirstChild("TextButton", true)
    if not tb then return 0 end
    for _, sig in ipairs({"Activated", "MouseButton1Click"}) do
        local ok, list = pcall(function() return getconnections(tb[sig]) end)
        if ok and list then
            for _, c in ipairs(list) do
                if pcall(function() c.Function() end) then n += 1 end
            end
        end
    end
    return n
end
local function wolfSweep(maxKill)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0, 0 end
    if wolfBusy then return 0, 0 end
    wolfBusy = true
    local startCf = hrp.CFrame
    local beforeDmg = LocalPlayer:GetAttribute("Weekly_WerewolfDamage") or 0
    local kills = 0
    if equipShears() then
        local side = 1
        for _, w in ipairs(findWolves()) do
            if not alive() then break end
            if kills >= (maxKill or 10) then break end
            local anchor = wolfAnchor(w)
            if anchor and w.model.Parent and w.hum.Health > 0 then
                local d0 = LocalPlayer:GetAttribute("Weekly_WerewolfDamage") or 0
                for i = 1, 8 do
                    if not alive() or w.hum.Health <= 0 or not w.model.Parent then break end
                    wolfTap(w)
                    task.wait(0.4)
                end
                task.wait(0.5)
                local d1 = LocalPlayer:GetAttribute("Weekly_WerewolfDamage") or 0
                if d1 > d0 then
                    log("Tap mempan +" .. (d1 - d0) .. ", lanjut tap")
                    local tTap = os.clock()
                    while alive() and w.hum.Health > 0 and w.model.Parent and os.clock() - tTap < 40 do
                        wolfTap(w)
                        task.wait(0.5)
                    end
                else
                    local lastHp = w.hum.Health
                    local stuckT = os.clock()
                    local t0 = os.clock()
                    local warned = false
                    while alive() and w.hum.Health > 0 and w.model.Parent and os.clock() - t0 < 40 do
                        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if myHum and myHum.MaxHealth > 0 and (myHum.Health / myHum.MaxHealth * 100) < cfg.wolfMinHp then
                            if not warned then log("HP rendah, mundur dulu") warned = true end
                            break
                        end
                        side = -side
                        pcall(function()
                            local cur = wolfAnchor(w)
                            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if cur and myHrp then myHrp.CFrame = cur.CFrame * CFrame.new(2 * side, 3, 0) end
                        end)
                        task.wait(0.3)
                        if w.hum.Health < lastHp then lastHp = w.hum.Health stuckT = os.clock()
                        elseif os.clock() - stuckT > 8 then break end
                    end
                end
                if w.hum.Health <= 0 or not w.model.Parent then
                    kills += 1
                    log("Serigala tumbang (" .. kills .. ")")
                end
            end
        end
        for _, tool in ipairs(workspace:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Daging Serigala" then
                local h = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                local p = h and h:FindFirstChild("ProductPrompt")
                if p and p.Enabled then
                    pcall(function() hrp.CFrame = h.CFrame * CFrame.new(0, 3, 0) end)
                    task.wait(0.3)
                    pcall(function() fireproximityprompt(p, p.HoldDuration) end)
                    task.wait(0.4)
                end
            end
        end
    else
        notify("Serigala", "Shears tidak ketemu", 2)
    end
    pcall(function()
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then myHrp.CFrame = startCf end
    end)
    wolfBusy = false
    local afterDmg = LocalPlayer:GetAttribute("Weekly_WerewolfDamage") or 0
    return kills, afterDmg - beforeDmg
end
WolfTab:CreateText({ name = "Auto Serigala", text = "Nempel ke serigala se-map + hajar brutal" })
wolfToggle = WolfTab:CreateToggle({
    name = "Auto Hajar Serigala",
    description = "Otomatis tempel & hajar tiap ada serigala",
    value = false, flag = "AutoWolf",
    callback = function(v) cfg.autoWolf = v; log("Auto serigala: "..tostring(v)); notify("Serigala", v and "AKTIF" or "MATI", 2) end,
})
wolfMinSlider = WolfTab:CreateSlider({
    name = "HP Aman",
    description = "Mundur kalau HP di bawah ini",
    range = {10,100}, increment = 5, value = 30, suffix = "%", flag = "WolfMinHp",
    callback = function(v) cfg.wolfMinHp = v; notify("HP Aman", v.."%", 1.5) end,
})
wolfStatusText = WolfTab:CreateText({ name = "Daftar Serigala", text = "Auto serigala OFF" })
WolfTab:CreateButton({
    name = "HANTAM SEKARANG",
    description = "Sapu serigala 1x + pungut daging",
    callback = function()
        if wolfBusy then notify("Serigala", "Lagi hajar, tunggu", 2) return end
        task.spawn(function()
            local k, d = wolfSweep(10)
            log("Hantam: " .. k .. " tumbang, +" .. d .. " damage")
            pcall(function() wolfStatusText:Set(getWolfText()) end)
            notify("Serigala", k .. " tumbang +" .. d .. " dmg", 2.5)
        end)
    end,
})

-- SETTINGS TAB - Auto Hancurkan bekas script di layar
SettingsTab:CreateText({ name = "Kelola Script", text = "Bersihkan bekas script & window numpuk" })
autoDestroyToggle = SettingsTab:CreateToggle({
    name = "Auto Hancurkan Script Lama",
    description = "ON = tiap buka hub otomatis tutup window lama",
    value = true,
    flag = "AutoDestroy",
    callback = function(v)
        cfg.autoDestroy = v
        log("Auto Hancurkan: "..tostring(v))
        notify("Auto Hancurkan", v and "AKTIF - auto tutup" or "MATI", 2)
    end,
})
SettingsTab:CreateButton({
    name = "HANCURKAN SEMUA SCRIPT SEKARANG",
    description = "Tutup semua window Yupi/Magnet di layar (fix duplicate)",
    callback = function()
        local n=0
        local robloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        if robloxGui then
            for _,child in ipairs(robloxGui:GetChildren()) do
                local hasYupi=false
                pcall(function()
                    if child:FindFirstChild("Yupi Hub", true) then hasYupi=true end
                    for _,d in ipairs(child:GetDescendants()) do if d:IsA("TextLabel") and (d.Text:find("Yupi Hub") or d.Text:find("Magnet Only")) then hasYupi=true break end end
                end)
                if hasYupi then pcall(function() child:Destroy() n+=1 end) end
            end
        end
        for _,v in ipairs(game.Players.LocalPlayer.PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and (v.Text:find("Yupi Hub") or v.Text:find("Magnet Only")) then
                local top=v:FindFirstAncestorOfClass("ScreenGui")
                if top then pcall(function() top:Destroy() n+=1 end) end
            end
        end
        pcall(function()
            local hui=gethui and gethui() or nil
            if hui then for _,child in ipairs(hui:GetChildren()) do if child:FindFirstChild("Yupi Hub", true) then pcall(function() child:Destroy() n+=1 end) end end end
        end)
        getgenv().YupiHub_Instance = (getgenv().YupiHub_Instance or 0) + 1
        getgenv().YupiHub_Alive = false
        notify("Hancurkan", "Ditutup "..n.." window + loop dimatikan", 2)
        log("Hancurkan semua: "..n.." window, instance sekarang "..getgenv().YupiHub_Instance)
    end,
})
SettingsTab:CreateButton({
    name = "RELOAD HUB (BERSIH)",
    description = "Hancurkan lalu buka YupiHub lagi (fresh)",
    callback = function()
        pcall(function()
            for _,v in ipairs(game:GetService("CoreGui"):GetChildren()) do if v.Name:lower():find("rayfield") then v:Destroy() end end
            for _,v in ipairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do if v.Name:lower():find("rayfield") then v:Destroy() end end
        end)
        task.wait(0.3)
        local ok, code = pcall(function() return readfile("YupiHub_Fixed.lua") end)
        if ok and code then pcall(function() loadstring(code)() end) else loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/YupiHub.lua"))() end
    end,
})

-- UPGRADE TAB - Auto Research Lab & Farming Skill
UpgradeTab:CreateText({ name = "Auto Upgrade", text = "Otomatis beli research & farming skill (bulk)" })
researchToggle = UpgradeTab:CreateToggle({
    name = "Auto Research Lab",
    description = "Otomatis research lab jika slot kosong",
    value = false,
    flag = "AutoResearchLab",
    callback = function(v)
        cfg.autoResearchLab = v
        log("Auto Research Lab: "..tostring(v))
        notify("Auto Research", v and "AKTIF" or "MATI", 2)
    end,
})
farmToggle = UpgradeTab:CreateToggle({
    name = "Auto Farming Skill",
    description = "Otomatis beli farming skill (Farm Mastery) termurah",
    value = false,
    flag = "AutoFarmMastery",
    callback = function(v)
        cfg.autoFarmMastery = v
        log("Auto Farming Skill: "..tostring(v))
        notify("Auto Farming", v and "AKTIF" or "MATI", 2)
    end,
})
researchDropdown = UpgradeTab:CreateDropdown({
    name = "Research Prioritas",
    description = "Pilih 1+ research, akan antri: 1 dulu, selesai baru 2 (prioritas urutan pilih)",
    options = {"RebirthOptimization","RevenueOverclock","SalesBonus","CosmicSynthesis","SakuraGenetics","AdvancedScholar","StorageExpansion","TimeWarpScience","RebirthWealth","SakuraGenetics","TimeWarpScience","CosmicSynthesis"},
    value = {"RebirthOptimization","RevenueOverclock"},
    multiSelect = true,
    flag = "ResearchPriority",
    callback = function(v)
        local vals = type(v)=="table" and v or {v}
        cfg.researchPriority = vals
        log("Research prioritas: "..table.concat(vals,", "))
        notify("Research", table.concat(vals,", "), 2)
    end,
})
farmDropdown = UpgradeTab:CreateDropdown({
    name = "Farming Skill Prioritas",
    description = "Pilih farming skill yang mau di-auto beli (urut prioritas)",
    options = {"DoubleYield","FactoryOverclock","Industrialist","ExtraAnimal","FastDelivery","SpeedRunner","ExtraStorage","AutoHarvest","HydroCan","SmartShopper","SmartBuilder","WeaponMastery","StarCollector","PremiumAnimal","MoneyMultiplier","DeliveryCapacity","FastLearner","SmartBuilder","FactoryDiscount"},
    value = {"DoubleYield","FactoryOverclock","Industrialist"},
    multiSelect = true,
    flag = "FarmMasteryPriority",
    callback = function(v)
        local vals = type(v)=="table" and v or {v}
        cfg.farmMasteryPriority = vals
        log("Farming prioritas: "..table.concat(vals,", "))
        notify("Farming", table.concat(vals,", "), 2)
    end,
})
UpgradeTab:CreateText({ name = "Info Upgrade", text = "Pilih prioritas, akan coba beli termurah tiap 12-15 detik jika mampu + slot kosong" })

-- Logic helpers
local function tryStart(factory, tier, amount)
    local c = FactoryConfig.Config[factory]
    if not c then return false end
    local suffix = TierSuffix[tier] or ""
    local name = c.InputName .. suffix
    local have = getAvail(name)
    local need = getInputReq(factory, tier) * amount
    if have < need then return false end
    local ok,a = pcall(function() return RequestStartProduction:InvokeServer("Start", factory, amount, tier) end)
    return ok and a==true
end
local function tryClaim(factory)
    local ok,a,b = pcall(function() return RequestClaimProduction:InvokeServer(factory) end)
    if ok and a and type(b)=="number" and b>0 then
        log("Ambil "..factory.." +"..b)
        notify("Ambil", factory.." +"..b, 1)
        if cfg.produksiLagi and cfg.autoAmbil then
            for _, tier in ipairs(cfg.enabledTiers or TIERS) do
                local c = FactoryConfig.Config[factory]
                if c then
                    local name = c.InputName .. (TierSuffix[tier] or "")
                    local have = getAvail(name)
                    local per = getInputReq(factory, tier)
                    if have >= per then
                        local maxAmt = math.min(cfg.amount, math.floor(have/per))
                        if maxAmt>0 and tryStart(factory, tier, maxAmt) then log("Produksi lagi "..factory.." "..tier.." x"..maxAmt); break end
                    end
                end
            end
        end
        return true
    end
    return false
end

local hasState = typeof(STATE)=="table" and STATE.alive
local function alive()
    if getgenv().YupiHub_Instance ~= myInstance then return false end
    if hasState then return STATE.alive() else return true end
end
if hasState then STATE.onCleanup(function() Rayfield:Destroy() getgenv().YupiHub_Alive=false end) end
-- juga cleanup global saat window ditutup
pcall(function() Window:OnDestroy(function() getgenv().YupiHub_Alive=false end) end)

-- Factory loops - FIX: auto produksi harus bulk terus, bukan cuma habis claim
task.spawn(function()
    while alive() do
        if cfg.autoProduksi then
            if cfg.autoMisi then refreshReserved() end
            -- 1. Ambil hasil yang sudah jadi (bulk)
            for _, f in ipairs(FACTORIES) do
                if not alive() then break end
                tryClaim(f)
                task.wait(0.12)
            end
            -- 2. Coba start produksi bulk untuk semua factory yang punya bahan (misi diprioritaskan)
            local order = FACTORIES
            if cfg.autoMisi then
                local needFirst, rest = {}, {}
                for _, f in ipairs(FACTORIES) do
                    local c0 = FactoryConfig.Config[f]
                    local need = false
                    if c0 and c0.OutputName then
                        for _, t2 in ipairs(TIERS) do
                            local out = c0.OutputName .. (TierSuffix[t2] or "")
                            if (missionReserved[out] or 0) > 0 then need = true break end
                        end
                    end
                    if need then needFirst[#needFirst + 1] = f else rest[#rest + 1] = f end
                end
                order = {}
                for _, f in ipairs(needFirst) do order[#order + 1] = f end
                for _, f in ipairs(rest) do order[#order + 1] = f end
            end
            for _, f in ipairs(order) do
                if not alive() then break end
                local c = FactoryConfig.Config[f]
                local lvl = LocalPlayer:GetAttribute("Level") or 1
                if c and lvl >= (c.UnlockPlayerLevel or 1) then
                    local tiers = cfg.enabledTiers or TIERS
                    if cfg.autoMisi and c.OutputName then
                        local seen = {}
                        for _, t in ipairs(tiers) do seen[t] = true end
                        local merged = {}
                        for _, t in ipairs(TIERS) do
                            if not seen[t] then
                                local out = c.OutputName .. (TierSuffix[t] or "")
                                if (missionReserved[out] or 0) > 0 then merged[#merged + 1] = t end
                            end
                        end
                        if #merged > 0 then
                            for _, t in ipairs(tiers) do merged[#merged + 1] = t end
                            tiers = merged
                        end
                    end
                    for _, tier in ipairs(tiers) do
                        local name = c.InputName .. (TierSuffix[tier] or "")
                        local have = getAvail(name)
                        local per = getInputReq(f, tier)
                        if have >= per then
                            local maxAmt = math.min(cfg.amount, math.floor(have / per))
                            -- batasi dengan sisa queue (max 3, kalau penuh gak bisa produksi)
                            local qLen = 0
                            local maxQ = 3
                            pcall(function()
                                local qData = HttpService:JSONDecode(LocalPlayer:GetAttribute("FactoryQueue_JSON") or "{}")
                                if qData[f] and qData[f].Q then qLen = #qData[f].Q end
                                -- coba ambil MaxQueue dari config jika ada
                                if c.QueueSize then maxQ = c.QueueSize end
                                if c.MaxQueue then maxQ = c.MaxQueue end
                            end)
                            local remain = maxQ - qLen
                            if remain <= 0 then
                                -- queue penuh, skip tier ini
                            else
                                maxAmt = math.min(maxAmt, remain)
                                if maxAmt > 0 then
                                    if tryStart(f, tier, maxAmt) then
                                        log("Auto Produksi "..f.." "..tier.." x"..maxAmt.." ("..name..") sisaQ "..(remain-maxAmt))
                                        task.wait(0.15)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0.05)
            end
        end
        task.wait(2.2)
    end
end)

-- Delivery mode loop - FIX: interval harus sesuai slider, tidak ke-kirim sebelum waktunya
task.spawn(function()
    local lastSend = os.clock()
    while alive() do
        task.wait(1)
        if cfg.autoKirim and alive() and not LocalPlayer:GetAttribute("IsDelivering") then
            if os.clock() - lastSend >= cfg.intervalKirim then
                if cfg.autoMisi then refreshReserved() end
                local shouldSend, reason = false, ""
                local mode = cfg.kirimBerdasarkan
                if mode == "Setiap 22 detik" then mode = "Setiap Interval" end
                if mode == "Setiap Interval" then shouldSend=true; reason="tiap "..cfg.intervalKirim.."s"
                elseif mode == "Saat tas penuh" then local t=getFilteredTotal(); if t>=350 then shouldSend=true; reason="tas "..t.."/360" end
                elseif mode == "Saat berat penuh" then local w=getFilteredWeight(); local lvl=LocalPlayer:GetAttribute("DeliveryLevel") or 1; local cap=(DeliveryConfig.Levels[lvl] and DeliveryConfig.Levels[lvl].Capacity) or 4000; if w>=cap-100 then shouldSend=true; reason="berat "..w.."/"..cap end
                elseif mode == "Saat ada item" then if getFilteredTotal()>20 then shouldSend=true; reason="ada item "..getFilteredTotal() end end
                if shouldSend then
                    local inv=getInventory()
                    local payload, totalW={},0
                    local lvl=LocalPlayer:GetAttribute("DeliveryLevel") or 1
                    local cap=(DeliveryConfig.Levels[lvl] and DeliveryConfig.Levels[lvl].Capacity) or 4000
                    for item, cnt in pairs(inv) do
                        local have2 = cnt
                        if cfg.autoMisi then have2 = math.max(0, cnt - (missionReserved[item] or 0)) end
                        if DeliveryConfig.Items[item] and have2>0 and allowKirim(item) and not isKecualikan(item) then local w=DeliveryConfig.Items[item].Weight or 1; local can=math.min(have2, math.floor((cap-totalW)/w)); if can>0 then payload[item]=can; totalW+=can*w end end
                    end
                    if next(payload)~=nil then
                        local ok,a,b=pcall(function() return RequestSendDelivery:InvokeServer(payload) end)
                        if ok and a then log("Kirim ["..reason.."] "..totalW.."kg"); notify("Kirim", "Terkirim "..totalW.."kg ("..reason..")", 3) lastSend = os.clock() end
                    else
                        -- tidak ada payload, jangan reset timer biar tidak spam
                    end
                end
            end
        end
    end
end)

-- Magnet auto brutal (sapu + kembali, tanpa delay 1-1)
task.spawn(function()
    while alive() do
        local delay = math.clamp(tonumber(cfg.jarakAmbil) or 2, 1, 5)
        task.wait(delay)
        if cfg.autoAmbilMagnet and alive() then
            local delta, n = brutalSweep(15)
            if delta > 0 then
                log("Sapu otomatis +"..delta.." ("..n.." prompt)")
            elseif n==0 then
                -- farm kosong, delay lebih lama
                task.wait(1)
            end
        end
    end
end)

-- Water Farm1 only
local lastRefill=0
task.spawn(function()
    while alive() do
        task.wait(cfg.autoSiram and 3 or 1)
        -- refill with cooldown
        local water=getWaterAmount()
        local maxW=getMaxWater()
        local pct=(water/maxW)*100
        if cfg.autoIsiAir and pct < cfg.isiSaat and (os.clock()-lastRefill)>10 then
            if LocalPlayer:GetAttribute("IsAutoRefill") ~= true then
                log("Air rendah "..math.floor(pct).."% -> isi")
                notify("Isi Air", "Air "..math.floor(pct).."% - mengisi...",2)
                local myFarm = getMyFarm()
                local well=myFarm and myFarm:FindFirstChild("ActiveWell")
                local part=well and well:FindFirstChild("WaterClaim")
                local prompt=part and part:FindFirstChild("ProximityPrompt")
                if well and part and prompt then
                    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame=CFrame.new(part.Position+Vector3.new(0,3,0))
                        task.wait(0.6)
                        local tool=LocalPlayer.Backpack:FindFirstChild("Watering Can")
                        if tool and tool.Parent~=LocalPlayer.Character then tool.Parent=LocalPlayer.Character; task.wait(0.4) end
                        local before=getWaterAmount()
                        local loops=0
                        while getWaterAmount() < maxW-5 and loops<14 do pcall(function() fireproximityprompt(prompt,0) end); loops+=1; task.wait(0.7); if getWaterAmount()<=before and loops>2 then break end; before=getWaterAmount() end
                        log("Air "..math.floor(getWaterAmount()).."/"..maxW.." loops "..loops)
                        notify("Isi Air", "Selesai "..math.floor(getWaterAmount()).."/"..maxW,2.5)
                        lastRefill=os.clock()
                        task.wait(1)
                    end
                end
            end
        end
        if cfg.autoSiram then
            local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local tool=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Watering Can") or LocalPlayer.Backpack:FindFirstChild("Watering Can")
            if tool then
                if tool.Parent~=LocalPlayer.Character then
                    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum:EquipTool(tool) end) else tool.Parent=LocalPlayer.Character end
                    task.wait(0.4)
                end
                local before=getWaterAmount()
                if before>8 and hrp then
                    -- diem ditempat max 4 detik sambil muter 360 derajat (fix AutoRotate)
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    local startCf = hrp.CFrame
                    log("Siram muter 360 4 detik di tempat")
                    local rem = tool:FindFirstChild("WaterRemote")
                    local handle = tool:FindFirstChild("Handle")
                    local wp = handle and handle:FindFirstChild("WaterPoint")
                    local bind = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("WateringStateEvent")
                    if hum then hum.AutoRotate = false end
                    if rem then pcall(function() rem:FireServer("StartPouring") end) end
                    if bind then pcall(function() bind:Fire("StartPouring", wp) end) end
                    -- muter 360 pakai loop biar presisi (tween ketahan AutoRotate)
                    for i=1,40 do
                        if not alive() then break end
                        hrp.CFrame = startCf * CFrame.Angles(0, math.rad(i*9), 0)
                        task.wait(0.1)
                    end
                    if rem then pcall(function() rem:FireServer("StopPouring") end) end
                    if bind then pcall(function() bind:Fire("StopPouring", nil) end) end
                    if hum then hum.AutoRotate = true end
                    task.wait(0.3)
                    local after=getWaterAmount()
                    log("Siram "..math.floor(before).."→"..math.floor(after).." (muter 360)")
                end
            end
        end
    end
end)

-- Auto Research Lab (prioritas sesuai pilihan user di menu, ceklis 2+ = antri 1 dulu, selesai auto 2)
task.spawn(function()
    while alive() do
        task.wait(12)
        if cfg.autoResearchLab and alive() then
            pcall(function()
                local lp = game.Players.LocalPlayer
                local HttpService = game:GetService("HttpService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local queue = HttpService:JSONDecode(lp:GetAttribute("LabQueue_JSON") or "[]")
                local skills = HttpService:JSONDecode(lp:GetAttribute("LabSkills_JSON") or "{}")
                local labCfg = require(ReplicatedStorage.Modules.LaboratoryConfig)
                local maxSlots = labCfg.Slots and labCfg.Slots.MaxSlots or 8
                if #queue >= maxSlots then return end
                -- pakai pilihan user dari dropdown, fallback ke default jika kosong
                local priority = cfg.researchPriority or cfg.researchPilihan or {"RebirthOptimization","RevenueOverclock","SalesBonus","CosmicSynthesis","SakuraGenetics","AdvancedScholar","StorageExpansion","TimeWarpScience","RebirthWealth"}
                if not priority or #priority==0 then priority = {"RebirthOptimization","RevenueOverclock","SalesBonus","CosmicSynthesis","SakuraGenetics"} end
                for _, skill in ipairs(priority) do
                    if not alive() then break end
                    local cur = skills[skill] or 0
                    local maxLvl = 999
                    pcall(function() if labCfg.Skills[skill] and labCfg.Skills[skill].MaxLevel then maxLvl = labCfg.Skills[skill].MaxLevel end end)
                    if cur < maxLvl then
                        local inQ=false
                        for _, q in ipairs(queue) do if q.skillKey==skill then inQ=true break end end
                        if not inQ then
                            local ok,res = pcall(function() return ReplicatedStorage.RequestStartResearch:InvokeServer(skill) end)
                            if ok and res then
                                log("Auto Research: "..skill.." Lv"..(cur+1).." OK")
                                notify("Research", skill.." Lv"..(cur+1), 2)
                                break
                            end
                        end
                    end
                    task.wait(0.15)
                end
            end)
        end
    end
end)

-- Auto Farming Skill (prioritas sesuai pilihan user di menu)
task.spawn(function()
    while alive() do
        task.wait(15)
        if cfg.autoFarmMastery and alive() then
            pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local farmCfg = require(rs.Modules.FarmMasteryConfig)
                local lp = game.Players.LocalPlayer
                local priority = cfg.farmMasteryPriority or cfg.farmSkillPilihan or {"DoubleYield","FactoryOverclock","Industrialist","ExtraAnimal","FastDelivery","SpeedRunner","ExtraStorage","AutoHarvest","HydroCan","SmartShopper","SmartBuilder","WeaponMastery","StarCollector","PremiumAnimal","MoneyMultiplier"}
                if not priority or #priority==0 then priority = {"DoubleYield","FactoryOverclock","Industrialist"} end
                for _, skill in ipairs(priority) do
                    if not alive() then break end
                    local data = farmCfg.Upgrades and farmCfg.Upgrades[skill]
                    if data then
                        local curLvl = 0
                        pcall(function()
                            local js = lp:GetAttribute("FarmMasteryData_JSON") or "{}"
                            local tbl = game:GetService("HttpService"):JSONDecode(js)
                            curLvl = tbl[skill] or 0
                        end)
                        local maxLvl = data.MaxLevel or 999
                        if curLvl < maxLvl and data.Prices and data.Prices[curLvl+1] then
                            local price = data.Prices[curLvl+1]
                            local money = lp:GetAttribute("Money_BN") or lp:GetAttribute("Money") or 0
                            if type(price)=="number" and money >= price then
                                local ok,res = pcall(function() return rs.RequestBuyFarmMastery:InvokeServer(skill) end)
                                if ok and res then
                                    log("Auto Farming: "..skill.." Lv"..(curLvl+1).." harga "..price.." OK")
                                    notify("Farming", skill.." Lv"..(curLvl+1), 2)
                                    break
                                else
                                    -- coba next skill jika gagal (mahal atau belum unlock)
                                end
                            end
                        end
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
end)

-- Auto Misi: claim misi selesai + refresh reserve (reserve auto clear saat misi hilang)
task.spawn(function()
    while alive() do
        task.wait(10)
        if cfg.autoMisi and alive() then
            pcall(function()
                local qs = HttpService:JSONDecode(LocalPlayer:GetAttribute("ActiveQuests_JSON") or "[]")
                if type(qs) ~= "table" then return end
                for _, q in ipairs(qs) do
                    if not alive() then break end
                    if q.Completed and q.Id and type(q.Items) == "table" then
                        local ready = true
                        local inv = getInventory()
                        for _, it in ipairs(q.Items) do
                            if (inv[it.Name] or 0) < (tonumber(it.Target) or 0) then ready = false break end
                        end
                        if ready then
                            local ok, res = pcall(function() return ClaimQuestRemote:InvokeServer(q.Id) end)
                            if ok and res then
                                log("Misi selesai: " .. tostring(q.Title or q.Id) .. " klaim OK")
                                notify("Misi", "Klaim " .. tostring(q.Title or q.Id), 2.5)
                            end
                        end
                        task.wait(0.5)
                    end
                end
            end)
            refreshReserved()
        end
    end
end)

-- Auto Misi: update daftar misi di tab Factory tiap 5 detik
task.spawn(function()
    while alive() do
        task.wait(5)
        if cfg.autoMisi and alive() then
            refreshReserved()
            pcall(function() misiStatusText:Set(getReservedText()) end)
        end
    end
end)

-- AUTO SPEED - kunci WalkSpeed 1-100 sesuai slider (1 pelan - 100 tercepat)
task.spawn(function()
    while alive() do
        task.wait(1)
        if cfg.autoSpeed and alive() then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local goal = math.clamp(math.floor(tonumber(cfg.speedTarget) or 36), 1, 100)
                    if hum.WalkSpeed ~= goal then hum.WalkSpeed = goal end
                end
            end)
        end
    end
end)

-- AUTO SERIGALA - sapu tiap ada yang spawn + update daftar
task.spawn(function()
    while alive() do
        task.wait(2)
        if cfg.autoWolf and alive() and not wolfBusy then
            local wolves = findWolves()
            pcall(function() wolfStatusText:Set(getWolfText()) end)
            if #wolves > 0 then
                local k, d = wolfSweep(10)
                if k > 0 or d > 0 then log("Auto serigala: " .. k .. " tumbang +" .. d .. " dmg") end
                pcall(function() wolfStatusText:Set(getWolfText()) end)
            end
        end
    end
end)

-- FACTORY CONFIG - autosave tiap 60 detik + autoload saat hub dibuka (biar setting tidak hilang)
task.spawn(function()
    while alive() do
        task.wait(60)
        if alive() then saveLast() end
    end
end)
task.spawn(function()
    task.wait(3)
    if getgenv().YupiHub_Instance ~= myInstance then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(LAST_PATH)) end)
    if ok and type(data) == "table" then
        applyFactoryConfig(data)
        log("Config otomatis dimuat (terakhir)")
        notify("Config", "Otomatis: setting terakhir dipulihkan", 2.5)
    end
end)

-- YUPI DARK - penegakan warna kustom (kartu Delivery merah, label sekunder, ikon tab)
local function enforceYupiTheme()
    pcall(function()
        local rg = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        if not rg then return end
        for _, v in ipairs(rg:GetDescendants()) do
            if v:IsA("Frame") and v.Name == "Delivery Items" then
                local hasTitle = false
                pcall(function()
                    for _, d in ipairs(v:GetChildren()) do
                        if d:IsA("TextLabel") then
                            local t = d.Text or ""
                            if t == "Delivery Items" then hasTitle = true break end
                        end
                    end
                end)
                if hasTitle then
                    pcall(function() v.BackgroundColor3 = YUPI_RED_BG end)
                    pcall(function()
                        local u = v:FindFirstChildOfClass("UIStroke")
                        if u then u.Color = YUPI_RED_STROKE end
                    end)
                    for _, d in ipairs(v:GetDescendants()) do
                        if d:IsA("TextLabel") then
                            pcall(function() d.TextColor3 = YUPI_RED_TEXT end)
                            pcall(function() d.BackgroundColor3 = YUPI_RED_BG end)
                        elseif d:IsA("Frame") then
                            pcall(function()
                                local c = d.BackgroundColor3
                                if c.R > 0.9 and c.G > 0.9 and c.B > 0.9 then
                                    d.BackgroundColor3 = YUPI_RED_BAR
                                else
                                    d.BackgroundColor3 = YUPI_RED_BG
                                end
                            end)
                        elseif d:IsA("UIStroke") then
                            pcall(function() d.Color = YUPI_RED_STROKE end)
                        end
                    end
                end
            end
        end
        for _, v in ipairs(rg:GetDescendants()) do
            if v:IsA("TextLabel") then
                local t = ""
                pcall(function() t = v.Text or "" end)
                if #t >= 20 and string.find(t, " ") and t ~= string.upper(t) and string.sub(t, 1, 1) ~= "[" then
                    local skip, isTitle = false, false
                    pcall(function()
                        local p = v.Parent
                        local lvl = 0
                        while p and lvl < 5 do
                            if p.Name == "Delivery Items" then skip = true end
                            if p.Name == "Aktivitas" then skip = true end
                            if p:IsA("Frame") and p.Name == t then isTitle = true end
                            p = p.Parent
                            lvl += 1
                        end
                    end)
                    if not skip and not isTitle then
                        pcall(function() v.TextColor3 = YUPI_GRAY end)
                    end
                end
            end
        end
        for _, v in ipairs(rg:GetDescendants()) do
            if v.Name == "Tabs" and v:IsA("ScrollingFrame") then
                for _, d in ipairs(v:GetDescendants()) do
                    if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                        pcall(function() d.ImageColor3 = YUPI_ICON end)
                    end
                end
            end
        end
        styleConsoleText()
    end)
end
task.delay(2, function() pcall(enforceYupiTheme) end)
task.spawn(function()
    while alive() do
        task.wait(8)
        if alive() then enforceYupiTheme() end
    end
end)

-- YUPI DASHBOARD - shell tampilan kartu (dark): tab, widget, navigasi
local DASH = {
    bg = Color3.fromRGB(26, 26, 26),
    card = Color3.fromRGB(36, 36, 36),
    card2 = Color3.fromRGB(44, 44, 44),
    line = Color3.fromRGB(255, 255, 255),
    text = Color3.fromRGB(245, 245, 245),
    gray = Color3.fromRGB(156, 163, 175),
    darkText = Color3.fromRGB(26, 26, 26),
    accent = Color3.fromRGB(59, 130, 246),
    accentDark = Color3.fromRGB(37, 99, 235),
    unchecked = Color3.fromRGB(75, 75, 75),
    div = Color3.fromRGB(42, 42, 42),
}
local dashGui, dashFloat, dashRoot, dashContent = nil, nil, nil, nil
local dashPages, dashPills = {}, {}
local dashDDRefresh, dashPaints = {}, {}
local customPages = {}
local currentDashPage = "Factory"
local dashOpenPopup, dashScrollHooked = nil, false
local function dMk(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do
        if k == "Corner" then
            local u = Instance.new("UICorner") u.CornerRadius = v u.Parent = o
        elseif k == "Stroke" then
            local u = Instance.new("UIStroke")
            if typeof(v) == "table" then u.Color = v[1] u.Transparency = v[2] else u.Color = v end
            u.ApplyStrokeMode = Enum.ApplyStrokeMode.Border u.Thickness = 1 u.Parent = o
        elseif k == "Pad" then
            local u = Instance.new("UIPadding")
            u.PaddingTop = UDim.new(0, v) u.PaddingBottom = UDim.new(0, v)
            u.PaddingLeft = UDim.new(0, v) u.PaddingRight = UDim.new(0, v)
            u.Parent = o
        else
            o[k] = v
        end
    end
    o.Parent = parent
    return o
end
local function dashParent()
    local par = nil
    pcall(function()
        local rg = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        if rg then
            for _, ch in ipairs(rg:GetChildren()) do
                for _, d in ipairs(ch:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text == "Yupi Hub" then par = ch.Parent break end
                end
                if par then break end
            end
        end
    end)
    if par then return par end
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    return game:GetService("CoreGui")
end
local yupiGuiRef = nil
local function getYupiGui()
    if yupiGuiRef and yupiGuiRef.Parent then return yupiGuiRef end
    yupiGuiRef = nil
    pcall(function()
        local rg = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        if rg then
            for _, ch in ipairs(rg:GetChildren()) do
                local has = false
                for _, d in ipairs(ch:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text == "Yupi Hub" then has = true break end
                end
                if has then yupiGuiRef = ch break end
            end
        end
    end)
    return yupiGuiRef
end
local function dashClosePopup()
    if dashOpenPopup then pcall(function() dashOpenPopup:Destroy() end) dashOpenPopup = nil end
end
local function paintPills(active)
    for name, b in pairs(dashPills) do
        if name == active then
            b.BackgroundColor3 = DASH.text
            local t = b:FindFirstChildOfClass("TextLabel") or b
            pcall(function()
                local lbl = b:FindFirstChild("lbl")
                if lbl then lbl.TextColor3 = DASH.darkText end
            end)
            b.Font = Enum.Font.GothamBold
        else
            b.BackgroundColor3 = DASH.card
            pcall(function()
                local lbl = b:FindFirstChild("lbl")
                if lbl then lbl.TextColor3 = DASH.text end
            end)
            b.Font = Enum.Font.GothamMedium
        end
    end
end
local function showDashPage(name)
    currentDashPage = name
    dashClosePopup()
    for k, p in pairs(dashPages) do p.Visible = (k == name) end
    paintPills(name)
    if dashGui then pcall(function() dashGui.Enabled = true end) end
    if dashFloat then pcall(function() dashFloat.Visible = false end) end
    local g = getYupiGui()
    if g then pcall(function() g.Enabled = false end) end
end
local function gotoRayfieldTab(name)
    dashClosePopup()
    if dashGui then pcall(function() dashGui.Enabled = false end) end
    if dashFloat then pcall(function() dashFloat.Visible = true end) end
    local g = getYupiGui()
    if g then pcall(function() g.Enabled = true end) end
    pcall(function()
        local rg = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        if not rg then return end
        for _, t in ipairs(rg:GetDescendants()) do
            if t.Name == "Tabs" and t:IsA("ScrollingFrame") then
                for _, b in ipairs(t:GetChildren()) do
                    if b:IsA("Frame") then
                        local title = nil
                        for _, d in ipairs(b:GetDescendants()) do
                            if d:IsA("TextLabel") and (d.Text or "") == name then title = d break end
                        end
                        if title then
                            local p = title.Parent
                            local lvl = 0
                            while p and lvl < 5 do
                                for _, s in ipairs(p:GetChildren()) do
                                    if s:IsA("TextButton") or s:IsA("ImageButton") then
                                        for _, sig in ipairs({"Activated", "MouseButton1Click"}) do
                                            local okc, list = pcall(function() return getconnections(s[sig]) end)
                                            if okc and list and #list > 0 then pcall(function() list[1].Function() end) return end
                                        end
                                    end
                                end
                                p = p.Parent
                                lvl += 1
                            end
                        end
                    end
                end
            end
        end
    end)
end
local function dashCheck(parent, get, set)
    local box = dMk("Frame", {Name = "check", BackgroundColor3 = DASH.card2, BorderSizePixel = 0, Size = UDim2.new(0, 26, 0, 26)}, parent)
    dMk("UICorner", {}, box).CornerRadius = UDim.new(0, 6)
    local st = dMk("UIStroke", {}, box)
    st.Color = DASH.unchecked
    st.Thickness = 2
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local b1 = dMk("Frame", {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 1, 0.56, 0), Size = UDim2.new(0, 13, 0, 3), Rotation = 45, Visible = false}, box)
    local b2 = dMk("Frame", {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.38, 0, 0.52, 0), Size = UDim2.new(0, 8, 0, 3), Rotation = -45, Visible = false}, box)
    local function paint()
        local on = get() and true or false
        box.BackgroundColor3 = on and DASH.accent or DASH.card
        box.BackgroundTransparency = on and 0 or 1
        st.Color = on and DASH.accent or DASH.unchecked
        st.Thickness = on and 1 or 2
        b1.Visible = on
        b2.Visible = on
    end
    dashPaints[#dashPaints + 1] = paint
    paint()
    return {box = box, paint = paint}
end
local function dashDropdown(rootLayer, content, get, set, items, multi)
    local pill = dMk("TextButton", {Name = "dd", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(44, 44, 44), Size = UDim2.new(0, 140, 0, 40)}, nil)
    dMk("UICorner", {}, pill).CornerRadius = UDim.new(0, 12)
    local st = dMk("UIStroke", {}, pill)
    st.Color = DASH.line
    st.Transparency = 0.92
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    dMk("TextLabel", {Name = "chev", BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = DASH.gray, Text = "▾", Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -28, 0, 0)}, pill)
    local val = dMk("TextLabel", {Name = "val", BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 17, TextColor3 = DASH.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 16, 0, 0)}, pill)
    local function refresh()
        local sel = get()
        if type(sel) ~= "table" then sel = {tostring(sel)} end
        val.Text = table.concat(sel, ", ")
    end
    dashDDRefresh[#dashDDRefresh + 1] = refresh
    pill.MouseButton1Click:Connect(function()
        if dashOpenPopup then dashClosePopup() return end
        local cur = get()
        if type(cur) ~= "table" then cur = {tostring(cur)} end
        local inSet = {}
        for _, s in ipairs(cur) do inSet[s] = true end
        local pop = dMk("Frame", {Name = "ddpop", BackgroundColor3 = Color3.fromRGB(44, 44, 44), Size = UDim2.new(0, 180, 0, #items * 42 + 12)}, rootLayer)
        dMk("UICorner", {}, pop).CornerRadius = UDim.new(0, 12)
        local pst = dMk("UIStroke", {}, pop)
        pst.Color = DASH.line
        pst.Transparency = 0.92
        pst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        pcall(function()
            local px = pill.AbsolutePosition.X - rootLayer.AbsolutePosition.X
            local py = pill.AbsolutePosition.Y - rootLayer.AbsolutePosition.Y + pill.AbsoluteSize.Y + 6
            pop.Position = UDim2.fromOffset(px - (180 - pill.AbsoluteSize.X), py)
        end)
        local rows = {}
        local function repaint()
            for _, r in ipairs(rows) do
                r.check.Visible = inSet[r.name] and true or false
            end
        end
        for i, name in ipairs(items) do
            local rb = dMk("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 42), LayoutOrder = i}, pop)
            dMk("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = DASH.text, TextXAlignment = Enum.TextXAlignment.Left, Text = name, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 14, 0, 0)}, rb)
            local cb = dMk("Frame", {BackgroundColor3 = inSet[name] and DASH.accent or DASH.card, BorderSizePixel = 0, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -32, 0.5, -10)}, rb)
            dMk("UICorner", {}, cb).CornerRadius = UDim.new(0, 6)
            local entry = {name = name, btn = rb, check = cb}
            rows[#rows + 1] = entry
            rb.MouseButton1Click:Connect(function()
                if multi then
                    if inSet[name] then inSet[name] = nil else inSet[name] = true end
                    local sel = {}
                    for _, it in ipairs(items) do if inSet[it] then sel[#sel + 1] = it end end
                    set(sel)
                    repaint()
                    refresh()
                else
                    set({name})
                    refresh()
                    dashClosePopup()
                end
            end)
        end
        local ll = dMk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0)}, pop)
        repaint()
        dashOpenPopup = pop
    end)
    refresh()
    return {pill = pill, refresh = refresh}
end

-- DASHBOARD: halaman Factory (referensi mockup dark)
local function dashSection(parent, order, text)
    return dMk("TextLabel", {Name = "sec", BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = DASH.gray, TextXAlignment = Enum.TextXAlignment.Left, Text = text, Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0, 4, 0, 0), LayoutOrder = order}, parent)
end
local function dashCard(parent, order)
    local c = dMk("Frame", {Name = "card", BackgroundColor3 = DASH.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order}, parent)
    dMk("UICorner", {}, c).CornerRadius = UDim.new(0, 16)
    local st = dMk("UIStroke", {}, c)
    st.Color = DASH.line
    st.Transparency = 0.92
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Thickness = 1
    dMk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0)}, c)
    return c
end
local function dashDiv(parent, order)
    return dMk("Frame", {BackgroundColor3 = DASH.line, BackgroundTransparency = 0.92, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), LayoutOrder = order}, parent)
end
local function dashCheckRow(parent, order, labelText, get, set)
    local row = dMk("TextButton", {Name = "row", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 60), LayoutOrder = order}, parent)
    dMk("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 17, TextColor3 = DASH.text, TextXAlignment = Enum.TextXAlignment.Left, Text = labelText, Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 18, 0, 0)}, row)
    local chk = dashCheck(row, get, set)
    chk.box.Position = UDim2.new(1, -44, 0.5, -13)
    row.MouseButton1Click:Connect(function()
        set(not get())
        chk.paint()
    end)
    return chk
end
local function dashDropRow(parent, order, labelText, dd)
    local row = dMk("Frame", {Name = "row", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 60), LayoutOrder = order}, parent)
    dMk("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 17, TextColor3 = DASH.text, TextXAlignment = Enum.TextXAlignment.Left, Text = labelText, Size = UDim2.new(1, -190, 1, 0), Position = UDim2.new(0, 18, 0, 0)}, row)
    dd.pill.Parent = row
    dd.pill.Position = UDim2.new(1, -168, 0.5, -20)
    return row
end
local function tierDisplay()
    local set = {}
    for _, t in ipairs(cfg.enabledTiers or {}) do set[t] = true end
    if set.Default and set.Gold and set.Sakura and set.Cosmic then return {"Semua"} end
    local map = {Gold = "Emas", Sakura = "Sakura", Cosmic = "Cosmic"}
    local d = {}
    for _, t in ipairs(cfg.enabledTiers or {}) do if map[t] then d[#d + 1] = map[t] end end
    if #d == 0 then return {"Emas"} end
    return d
end
local function applyTierDisplay(sel)
    local hasSemua = false
    for _, sv in ipairs(sel) do if sv == "Semua" then hasSemua = true break end end
    if hasSemua then
        cfg.enabledTiers = {"Default", "Gold", "Sakura", "Cosmic"}
    else
        local map = {Emas = "Gold", Sakura = "Sakura", Cosmic = "Cosmic"}
        local en = {}
        for _, sv in ipairs(sel) do local it = map[sv] or sv if it ~= "Default" then en[#en + 1] = it end end
        if #en == 0 then en = {"Gold"} sel = {"Emas"} end
        cfg.enabledTiers = en
    end
    pcall(function() tierDropdown:Set(sel) end)
end
local function buildYupiDash()
    local parent = dashParent()
    dashGui = dMk("ScreenGui", {Name = "YupiDash", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 5, Enabled = false}, parent)
    local root = dMk("Frame", {Name = "root", BackgroundColor3 = DASH.bg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0)}, dashGui)
    dashRoot = root
    dashContent = dMk("ScrollingFrame", {Name = "content", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = DASH.gray}, root)
    dMk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0)}, dashContent)
    local cpad = dMk("UIPadding", {}, dashContent)
    cpad.PaddingTop = UDim.new(0, 20)
    cpad.PaddingBottom = UDim.new(0, 24)
    cpad.PaddingLeft = UDim.new(0, 16)
    cpad.PaddingRight = UDim.new(0, 16)
    dashContent:GetPropertyChangedSignal("CanvasPosition"):Connect(function() dashClosePopup() end)
    local tabBar = dMk("Frame", {Name = "tabbar", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 1}, dashContent)
    dMk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10)}, tabBar)
    local pillNames = {"Main", "Factory", "Water", "Delivery"}
    for i, name in ipairs(pillNames) do
        local b = dMk("TextButton", {Name = "pill" .. name, Text = "", AutoButtonColor = false, BackgroundColor3 = DASH.card, BorderSizePixel = 0, Size = UDim2.new(0.25, -8, 1, 0), LayoutOrder = i}, tabBar)
        dMk("UICorner", {}, b).CornerRadius = UDim.new(1, 0)
        local pst = dMk("UIStroke", {}, b)
        pst.Color = DASH.line
        pst.Transparency = 0.92
        pst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        pst.Thickness = 1
        dMk("TextLabel", {Name = "lbl", BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = DASH.gray, Text = name, Size = UDim2.new(1, 0, 1, 0)}, b)
        dashPills[name] = b
        b.MouseButton1Click:Connect(function()
            dashClosePopup()
            if name == "Factory" and customPages.Factory then
                showDashPage("Factory")
            else
                paintPills(name)
                gotoRayfieldTab(name)
            end
        end)
    end
    dMk("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 2}, dashContent)
    local fpage = dMk("Frame", {Name = "pageFactory", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 10, Visible = false}, dashContent)
    dMk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0)}, fpage)
    dashPages.Factory = fpage
    customPages.Factory = true
    local ord = 10
    local function no()
        ord += 1
        return ord
    end
    dashSection(fpage, no(), "Produksi otomatis")
    local card1 = dashCard(fpage, no())
    local corder = 0
    local function co()
        corder += 1
        return corder
    end
    dashCheckRow(card1, co(), "Auto produksi", function() return cfg.autoProduksi end, function(v)
        cfg.autoProduksi = v
        cfg.autoAmbil = v
        cfg.produksiLagi = v
        pcall(function() autoProduksiToggle:Set(v) end)
    end)
    dashDiv(card1, co())
    local jdd = dashDropdown(dashRoot, dashContent, function() return {tostring(cfg.amount)} end, function(sel)
        local val = tonumber(sel[1]) or 5
        cfg.amount = val
        pcall(function() jumlahDropdown:Set(tostring(val)) end)
    end, {"1", "2", "5", "10"}, false)
    dashDropRow(card1, co(), "Jumlah produksi", jdd)
    dashDiv(card1, co())
    local tdd = dashDropdown(dashRoot, dashContent, tierDisplay, applyTierDisplay, {"Semua", "Emas", "Sakura", "Cosmic"}, true)
    dashDropRow(card1, co(), "Tier produksi", tdd)
    dashSection(fpage, no(), "Alur produksi")
    local flow = dashCard(fpage, no())
    local frow = dMk("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 76), LayoutOrder = 1}, flow)
    dMk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10)}, frow)
    local fpad = dMk("UIPadding", {}, frow)
    fpad.PaddingLeft = UDim.new(0, 18)
    fpad.PaddingRight = UDim.new(0, 18)
    for i, ft in ipairs({"Produksi", "→", "Ambil", "→", "Ulang"}) do
        if ft == "→" then
            dMk("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 18, TextColor3 = DASH.gray, Text = ft, Size = UDim2.new(0, 20, 1, 0), LayoutOrder = i}, frow)
        else
            local fp = dMk("Frame", {BackgroundColor3 = Color3.fromRGB(44, 44, 44), BorderSizePixel = 0, Size = UDim2.new(0, 0, 0, 40), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i}, frow)
            dMk("UICorner", {}, fp).CornerRadius = UDim.new(1, 0)
            local fst = dMk("UIStroke", {}, fp)
            fst.Color = DASH.line
            fst.Transparency = 0.92
            fst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            fst.Thickness = 1
            local fpad2 = dMk("UIPadding", {}, fp)
            fpad2.PaddingLeft = UDim.new(0, 18)
            fpad2.PaddingRight = UDim.new(0, 18)
            dMk("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = DASH.text, Text = ft, Size = UDim2.new(1, 0, 1, 0)}, fp)
        end
    end
    dashSection(fpage, no(), "Misi")
    local card2 = dashCard(fpage, no())
    local corder2 = 100
    local function co2()
        corder2 += 1
        return corder2
    end
    dashCheckRow(card2, co2(), "Auto misi", function() return cfg.autoMisi end, function(v)
        cfg.autoMisi = v
        if v then refreshReserved() else missionReserved = {} end
        pcall(function() autoMisiToggle:Set(v) end)
    end)
    dashDiv(card2, co2())
    local fdd = dashDropdown(dashRoot, dashContent, function()
        local m = cfg.misiFokus
        if type(m) == "table" then m = m[1] end
        return {tostring(m)}
    end, function(sel)
        local val = sel[1]
        cfg.misiFokus = val
        if cfg.autoMisi then refreshReserved() end
        pcall(function() fokusDropdown:Set(val) end)
    end, {"Semua", "1 Teratas", "3 Teratas", "5 Teratas"}, false)
    dashDropRow(card2, co2(), "Fokus misi", fdd)
    local lihatBtn = dMk("TextButton", {Name = "lihatBtn", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = no()}, fpage)
    local lbst = dMk("UIStroke", {}, lihatBtn)
    lbst.Color = DASH.line
    lbst.Transparency = 0.92
    lbst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    lbst.Thickness = 1
    dMk("UICorner", {}, lihatBtn).CornerRadius = UDim.new(0, 14)
    dMk("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 17, TextColor3 = DASH.text, Text = "Lihat daftar misi", Size = UDim2.new(1, 0, 1, 0)}, lihatBtn)
    lihatBtn.MouseButton1Click:Connect(function()
        refreshReserved()
        for _, line in ipairs(getMisiLines()) do log(line) end
    end)
    dMk("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = no()}, fpage)
    dashFloat = dMk("TextButton", {Name = "YupiFloat", Text = "", AutoButtonColor = false, BackgroundColor3 = DASH.accentDark, BorderSizePixel = 0, Size = UDim2.new(0, 56, 0, 56), Position = UDim2.new(1, -76, 1, -170), Visible = false}, nil)
    dMk("UICorner", {}, dashFloat).CornerRadius = UDim.new(1, 0)
    local fcb = dMk("TextButton", {BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = Color3.fromRGB(255, 255, 255), Text = "Y", Size = UDim2.new(1, 0, 1, 0)}, dashFloat)
    do
        local fg = dashParent()
        dashFloat.Parent = fg
        local dragging, floatMoved = false, false
        local dsx, dsy, dpx, dpy = 0, 0, 0, 0
        dashFloat.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                floatMoved = false
                dsx, dsy = inp.Position.X, inp.Position.Y
                dpx, dpy = dashFloat.Position.X.Offset, dashFloat.Position.Y.Offset
            end
        end)
        local UIS = game:GetService("UserInputService")
        UIS.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                if math.abs(inp.Position.X - dsx) + math.abs(inp.Position.Y - dsy) > 12 then floatMoved = true end
                dashFloat.Position = UDim2.new(1, dpx + (inp.Position.X - dsx), 1, dpy + (inp.Position.Y - dsy))
            end
        end)
        UIS.InputEnded:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
                dragging = false
            end
        end)
        fcb.MouseButton1Click:Connect(function()
            if floatMoved then return end
            showDashPage(currentDashPage)
        end)
    end
    syncDashFactory = function()
        for _, fn in ipairs(dashPaints) do pcall(fn) end
        for _, fn in ipairs(dashDDRefresh) do pcall(fn) end
    end
    task.spawn(function()
        while alive() do
            task.wait(1)
            if not alive() then break end
            pcall(function() if syncDashFactory then syncDashFactory() end end)
        end
    end)
    showDashPage("Factory")
    task.delay(1.5, function()
        local g = getYupiGui()
        if g then pcall(function() g.Enabled = false end) end
    end)
end
local okDash, errDash = pcall(buildYupiDash)
if not okDash then print("dashboard gagal: " .. tostring(errDash)) end

log("Hub loaded - Versi Newbie Friendly")
notify("Hub Siap", "Mode newbie aktif", 3)
return "Hub Newbie running"
