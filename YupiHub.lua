
-- Farm Industry Hub - Newbie Friendly (berdasarkan konsep ChatGPT)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
local Window = Rayfield:CreateWindow({
    Name = "Yupi Hub",
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
    kirimBerdasarkan = "Setiap 22 detik",
    intervalKirim = 22,
    jenisKirim = {"Mentah", "Olahan", "Jadi"},
    autoAmbilMagnet = false,
    itemDiambil = "Semua",
    jarakAmbil = 2,
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
local function getFilteredTotal()
    local inv = getInventory()
    local c = 0
    for item, cnt in pairs(inv) do
        if DeliveryConfig.Items[item] and allowKirim(item) then c += cnt end
    end
    return c
end
local function getFilteredWeight()
    local inv = getInventory()
    local w = 0
    for item, cnt in pairs(inv) do
        local it = DeliveryConfig.Items[item]
        if it and allowKirim(item) then w += (it.Weight or 1) * cnt end
    end
    return w
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
local FACTORIES = {"FlourFactory","BreadFactory","YarnFactory","SweaterFactory","SausageFactory","HotdogFactory","ButterFactory","CheeseFactory"}
local TIERS = {"Default","Gold","Sakura","Cosmic"}

-- MAIN DASHBOARD
MainTab:CreateText({ name = "YUPI HUB", text = "Yupi Hub - Farm Industry" })
local statusFactory = MainTab:CreateStat({ name = "Factory", value = 0, suffix = " ON" })
local statusWater = MainTab:CreateStat({ name = "Water", value = math.floor((getWaterAmount()/getMaxWater())*100), suffix = "%" })
local statusDelivery = MainTab:CreateStat({ name = "Delivery Items", value = getTotalItems(), suffix = "/360" })
local statusMagnet = MainTab:CreateStat({ name = "Magnet", value = 0, suffix = "" })
MainTab:CreateDivider({ text = "Recent Activity" })
local console = MainTab:CreateConsole({ name = "Aktivitas", height = 100, follow = true, maxLines = 100 })
local function log(msg) console:Append("["..os.date("%H:%M:%S").."] "..msg); print(msg) end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local factoryOn = (cfg.autoAmbil or cfg.produksiTerus) and 1 or 0
            statusFactory:Set(factoryOn)
            statusWater:Set(math.floor((getWaterAmount()/getMaxWater())*100))
            statusDelivery:Set(getTotalItems())
            statusMagnet:Set(cfg.autoAmbilMagnet and 1 or 0)
        end)
    end
end)

-- FACTORY TAB - Progressive disclosure
FactoryTab:CreateText({ name = "Produksi Otomatis", text = "Pilih cara kerja pabrik" })
local modeDropdown = FactoryTab:CreateDropdown({
    name = "Mode Produksi",
    description = "Pilih kapan pabrik memproduksi",
    options = {"Setelah hasil diambil","Produksi terus-menerus"},
    value = "Setelah hasil diambil",
    flag = "ModeProduksi",
    callback = function(v)
        local val = type(v)=="table" and v[1] or v
        cfg.modeProduksi = val
        cfg.produksiTerus = (val == "Produksi terus-menerus")
        log("Mode produksi: "..val.." terus="..tostring(cfg.produksiTerus))
        notify("Mode Produksi", val, 2.5)
        if cfg.produksiTerus then notify("Peringatan", "⚠️ Bahan lebih cepat habis", 3) end
    end,
})
FactoryTab:CreateDropdown({
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
FactoryTab:CreateDropdown({
    name = "Tier Produksi",
    description = "Pilih tier yang diproduksi (bisa pilih banyak) - Default/Emas/Sakura/Cosmic. Queue 3/13 sesuai tier.",
    options = {"Default","Emas","Sakura","Cosmic"},
    value = {"Default","Emas","Sakura","Cosmic"},
    multiSelect = true,
    flag = "TierProduksi",
    callback = function(v)
        -- Rayfield multi returns table
        local vals = type(v)=="table" and v or {v}
        -- map Emas -> Gold internal etc but keep display
        local map = {Default="Default", Emas="Gold", Sakura="Sakura", Cosmic="Cosmic"}
        local enabled = {}
        for _, val in ipairs(vals) do
            local internal = map[val] or val
            table.insert(enabled, internal)
        end
        cfg.enabledTiers = enabled
        log("Tier produksi: "..table.concat(vals,", "))
        notify("Tier Produksi", table.concat(vals,", "), 2.5)
    end,
})
-- default enabled tiers ALL
cfg.enabledTiers = {"Default","Gold","Sakura","Cosmic"}
-- Toggle dihapus per request, pakai Mode Produksi dropdown saja
-- Default: Ambil Otomatis ON, Produksi Lagi ON
cfg.autoAmbil = true
cfg.produksiLagi = true
cfg.produksiTerus = false
FactoryTab:CreateText({ name = "Info Factory", text = "🏭 Produksi → 📦 Ambil Otomatis → 🏭 Produksi Lagi" })

-- WATER TAB
WaterTab:CreateText({ name = "Perawatan Rumput", text = "Jaga rumput tetap hijau" })
local siramToggle = WaterTab:CreateToggle({
    name = "Auto Siram",
    description = "Otomatis mencari rumput kering dan menyiramnya",
    value = false, flag = "AutoSiram",
    callback = function(v) cfg.autoSiram = v; log("Auto siram: "..tostring(v)); notify("Auto Siram", v and "AKTIF" or "MATI", 2) end,
})
local waktuSiramDropdown = WaterTab:CreateDropdown({
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
local isiAirToggle = WaterTab:CreateToggle({
    name = "Auto Isi Air",
    description = "Isi ulang air otomatis saat persediaan rendah",
    value = true, flag = "AutoIsiAir",
    callback = function(v) cfg.autoIsiAir = v; log("Auto isi air: "..tostring(v)); notify("Auto Isi Air", v and "AKTIF" or "MATI", 2) end,
})
local isiSaatSlider = WaterTab:CreateSlider({
    name = "Isi Ulang Saat",
    description = "Teleport ke sumur dan isi sampai penuh",
    range = {10,90}, increment = 5, value = 30, suffix = "%", flag = "IsiSaat",
    callback = function(v) cfg.isiSaat = v; notify("Isi Ulang Saat", v.."%", 1.5) end,
})
WaterTab:CreateText({ name = "Info Isi", text = "Isi ulang saat air di bawah 30% → isi sampai penuh" })

-- DELIVERY TAB
DeliveryTab:CreateText({ name = "Auto Kirim", text = "Kirim hasil ke kota secara otomatis" })
local autoKirimToggle = DeliveryTab:CreateToggle({
    name = "Auto Kirim",
    description = "Kirim otomatis sesuai mode",
    value = false, flag = "AutoKirim",
    callback = function(v) cfg.autoKirim = v; log("Auto kirim: "..tostring(v)); notify("Auto Kirim", v and "AKTIF - "..cfg.kirimBerdasarkan or "MATI", 2.5) end,
})
local kirimDropdown = DeliveryTab:CreateDropdown({
    name = "Kirim Berdasarkan",
    description = "Pilih kapan kirim terjadi",
    options = {"Setiap 22 detik","Saat tas penuh","Saat berat penuh","Saat ada item"},
    value = "Setiap 22 detik",
    flag = "KirimBerdasarkan",
    callback = function(v)
        local val = type(v)=="table" and v[1] or v
        cfg.kirimBerdasarkan = val
        log("Kirim berdasarkan: "..val)
        notify("Kirim Berdasarkan", val, 2.5)
    end,
})
local intervalSlider = DeliveryTab:CreateSlider({
    name = "Interval",
    description = "Jeda antar pengiriman",
    range = {10,60}, increment = 2, value = 22, suffix = " detik", flag = "IntervalKirim",
    callback = function(v) cfg.intervalKirim = v; notify("Interval", v.." detik", 1.5) end,
})
DeliveryTab:CreateDropdown({
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
DeliveryTab:CreateButton({
    name = "KIRIM SEKARANG",
    description = "Kirim semua isi tas sekarang",
    callback = function()
        notify("Kirim", "Mengirim...", 1.5)
        local inv = getInventory()
        local payload, totalW = {}, 0
        local lvl = LocalPlayer:GetAttribute("DeliveryLevel") or 1
        local cap = (DeliveryConfig.Levels[lvl] and DeliveryConfig.Levels[lvl].Capacity) or 4000
        for item,cnt in pairs(inv) do
            if DeliveryConfig.Items[item] and cnt>0 and allowKirim(item) then
                local w = DeliveryConfig.Items[item].Weight or 1
                local can = math.min(cnt, math.floor((cap-totalW)/w))
                if can>0 then payload[item]=can; totalW+=can*w end
            end
        end
        if next(payload)==nil then notify("Kirim", "Tas kosong", 2) return end
        local ok,a,b = pcall(function() return RequestSendDelivery:InvokeServer(payload) end)
        if ok and a then log("Kirim "..totalW.."kg berhasil"); notify("Berhasil", "Terkirim "..totalW.."kg", 3) else notify("Gagal", tostring(b), 3) end
    end,
})

-- MAGNET TAB
MagnetTab:CreateText({ name = "Auto Ambil", text = "Sapu bersih seluruh farm + kembali ke posisi awal" })
local magnetToggle = MagnetTab:CreateToggle({
    name = "Auto Ambil",
    description = "Otomatis menyapu seluruh farm tiap beberapa detik (brutal, tanpa delay 1-1)",
    value = false, flag = "AutoAmbil",
    callback = function(v) cfg.autoAmbilMagnet = v; log("Auto ambil: "..tostring(v)); notify("Auto Ambil", v and "AKTIF" or "MATI", 2) end,
})
local itemDropdown = MagnetTab:CreateDropdown({
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
local jarakSlider = MagnetTab:CreateSlider({
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
local function brutalSweep(maxItems)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local farm = getMyFarm()
    if not hrp or not farm then return 0, 0 end
    local startCf = hrp.CFrame
    local before = getTotalItems()
    local n = 0
    for _, tool in ipairs(farm:GetChildren()) do
        if tool:IsA("Tool") and matchMagnet(tool.Name) then
            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
            local prompt = handle and handle:FindFirstChild("ProductPrompt")
            if prompt and prompt.Enabled then
                pcall(function()
                    prompt.MaxActivationDistance = 60
                    prompt.RequiresLineOfSight = false
                    hrp.CFrame = handle.CFrame * CFrame.new(0, 3, 0)
                end)
                pcall(function() fireproximityprompt(prompt, 0) end)
                n += 1
                if n >= (maxItems or 15) then break end
            end
        end
    end
    task.wait(0.6)
    pcall(function() hrp.CFrame = startCf end)
    task.wait(0.3)
    local delta = getTotalItems() - before
    return delta, n
end
MagnetTab:CreateButton({
    name = "AMBIL SEKARANG",
    description = "Sapu bersih 1x seluruh farm + kembali ke posisi awal",
    callback = function()
        notify("Ambil", "Menyapu farm...", 1.2)
        local delta, n = brutalSweep(15)
        log("Sapu "..n.." delta "..delta)
        if delta>0 then notify("Berhasil", "+"..delta.." item ke tas!", 2.5) else notify("Gagal", "Tidak ada / tas penuh?", 2.5) end
    end,
})

-- Logic helpers
local function tryStart(factory, tier, amount)
    local c = FactoryConfig.Config[factory]
    if not c then return false end
    local suffix = TierSuffix[tier] or ""
    local name = c.InputName .. suffix
    local inv = getInventory()
    local have = inv[name] or 0
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
                    local have = (getInventory()[name] or 0)
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
local function alive() if hasState then return STATE.alive() else return true end end
if hasState then STATE.onCleanup(function() Rayfield:Destroy() end) end

-- Factory loops
task.spawn(function()
    while alive() do
        if cfg.autoAmbil then
            for _, f in ipairs(FACTORIES) do
                if not alive() then break end
                tryClaim(f)
                task.wait(0.15)
            end
        end
        -- Mode produksi
        if cfg.modeProduksi == "Produksi terus-menerus" and cfg.produksiTerus then
            for _, f in ipairs(FACTORIES) do
                if not alive() then break end
                local c = FactoryConfig.Config[f]
                local lvl = LocalPlayer:GetAttribute("Level") or 1
                if c and lvl >= (c.UnlockPlayerLevel or 1) then
                    for _, tier in ipairs(cfg.enabledTiers or TIERS) do
                        local name = c.InputName .. (TierSuffix[tier] or "")
                        local have = (getInventory()[name] or 0)
                        local per = getInputReq(f, tier)
                        if have >= per then
                            local maxAmt = math.min(cfg.amount, math.floor(have/per))
                            if maxAmt>0 and tryStart(f, tier, maxAmt) then log("Produksi terus "..f.." "..tier.." x"..maxAmt) end
                            task.wait(0.18)
                        end
                    end
                end
                task.wait(0.05)
            end
        elseif cfg.modeProduksi == "Setelah hasil diambil" and not cfg.produksiTerus then
            -- produksi hanya via Produksi Lagi Setelah Ambil (di tryClaim)
            -- tidak ada loop tambahan
        end
        task.wait(2.5)
    end
end)

-- Delivery mode loop
task.spawn(function()
    while alive() do
        local interval = cfg.intervalKirim
        if cfg.kirimBerdasarkan ~= "Setiap 22 detik" then task.wait(3) else task.wait(interval) end
        if cfg.autoKirim and alive() and not LocalPlayer:GetAttribute("IsDelivering") then
            local shouldSend, reason = false, ""
            if cfg.kirimBerdasarkan == "Setiap 22 detik" then shouldSend=true; reason="tiap "..interval.."s"
            elseif cfg.kirimBerdasarkan == "Saat tas penuh" then local t=getFilteredTotal(); if t>=350 then shouldSend=true; reason="tas(filter) "..t.."/360" end
            elseif cfg.kirimBerdasarkan == "Saat berat penuh" then local w=getFilteredWeight(); local lvl=LocalPlayer:GetAttribute("DeliveryLevel") or 1; local cap=(DeliveryConfig.Levels[lvl] and DeliveryConfig.Levels[lvl].Capacity) or 4000; if w>=cap-100 then shouldSend=true; reason="berat(filter) "..w.."/"..cap end
            elseif cfg.kirimBerdasarkan == "Saat ada item" then if getFilteredTotal()>20 then shouldSend=true; reason="ada item(filter) "..getFilteredTotal() end end
            if shouldSend then
                local inv=getInventory()
                local payload, totalW={},0
                local lvl=LocalPlayer:GetAttribute("DeliveryLevel") or 1
                local cap=(DeliveryConfig.Levels[lvl] and DeliveryConfig.Levels[lvl].Capacity) or 4000
                for item,cnt in pairs(inv) do if DeliveryConfig.Items[item] and cnt>0 and allowKirim(item) then local w=DeliveryConfig.Items[item].Weight or 1; local can=math.min(cnt, math.floor((cap-totalW)/w)); if can>0 then payload[item]=can; totalW+=can*w end end end
                if next(payload)~=nil then
                    local ok,a,b=pcall(function() return RequestSendDelivery:InvokeServer(payload) end)
                    if ok and a then log("Kirim ["..reason.."] "..totalW.."kg"); notify("Kirim", "Terkirim "..totalW.."kg ("..reason..")", 3) end
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
            local delta, n = brutalSweep(12)
            if delta > 0 then
                log("Sapu otomatis +"..delta.." ("..n.." prompt)")
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
            if hrp then
                local rnd=getFarm1RandomPos()
                if (hrp.Position-rnd).Magnitude>10 then
                    TweenService:Create(hrp, TweenInfo.new(1), {CFrame=CFrame.new(rnd)}):Play()
                    log("Patrol farm sendiri ["..math.floor(rnd.X)..","..math.floor(rnd.Z).."]")
                    task.wait(0.7)
                end
            end
            local tool=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Watering Can") or LocalPlayer.Backpack:FindFirstChild("Watering Can")
            if tool then
                if tool.Parent~=LocalPlayer.Character then
                    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum:EquipTool(tool) end) else tool.Parent=LocalPlayer.Character end
                    task.wait(0.4)
                end
                local before=getWaterAmount()
                if before>8 then
                    doPour(tool, cfg.waktuSiram or 2)
                    task.wait(0.8)
                    local after=getWaterAmount()
                    log("Siram "..math.floor(before).."→"..math.floor(after))
                end
            end
        end
    end
end)

log("Hub loaded - Versi Newbie Friendly")
notify("Hub Siap", "Mode newbie aktif", 3)
return "Hub Newbie running"
