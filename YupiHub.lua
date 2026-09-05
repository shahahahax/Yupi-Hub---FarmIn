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
local function getFilteredTotal()
    local inv = getInventory()
    local c = 0
    for item, cnt in pairs(inv) do
        if DeliveryConfig.Items[item] and allowKirim(item) and not isKecualikan(item) then c += cnt end
    end
    return c
end
local function getFilteredWeight()
    local inv = getInventory()
    local w = 0
    for item, cnt in pairs(inv) do
        local it = DeliveryConfig.Items[item]
        if it and allowKirim(item) and not isKecualikan(item) then w += (it.Weight or 1) * cnt end
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
FactoryTab:CreateToggle({
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
DeliveryTab:CreateDropdown({
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
        local inv = getInventory()
        local payload, totalW = {}, 0
        local lvl = LocalPlayer:GetAttribute("DeliveryLevel") or 1
        local cap = (DeliveryConfig.Levels[lvl] and DeliveryConfig.Levels[lvl].Capacity) or 4000
        for item,cnt in pairs(inv) do
            if DeliveryConfig.Items[item] and cnt>0 and allowKirim(item) and not isKecualikan(item) then
                local w = DeliveryConfig.Items[item].Weight or 1
                local can = math.min(cnt, math.floor((cap-totalW)/w))
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

-- SETTINGS TAB - Auto Hancurkan bekas script di layar
SettingsTab:CreateText({ name = "Kelola Script", text = "Bersihkan bekas script & window numpuk" })
SettingsTab:CreateToggle({
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
UpgradeTab:CreateToggle({
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
UpgradeTab:CreateToggle({
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
UpgradeTab:CreateDropdown({
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
UpgradeTab:CreateDropdown({
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
            -- 1. Ambil hasil yang sudah jadi (bulk)
            for _, f in ipairs(FACTORIES) do
                if not alive() then break end
                tryClaim(f)
                task.wait(0.12)
            end
            -- 2. Coba start produksi bulk untuk semua factory yang punya bahan (biar gak nunggu claim)
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
                            local maxAmt = math.min(cfg.amount, math.floor(have / per))
                            -- batasi dengan sisa queue (max 3, kalau penuh gak bisa produksi)
                            local qLen = 0
                            local maxQ = 3
                            pcall(function()
                                local qData = HttpService:JSONDecode(lp:GetAttribute("FactoryQueue_JSON") or "{}")
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
                    for item,cnt in pairs(inv) do if DeliveryConfig.Items[item] and cnt>0 and allowKirim(item) and not isKecualikan(item) then local w=DeliveryConfig.Items[item].Weight or 1; local can=math.min(cnt, math.floor((cap-totalW)/w)); if can>0 then payload[item]=can; totalW+=can*w end end end
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

log("Hub loaded - Versi Newbie Friendly")
notify("Hub Siap", "Mode newbie aktif", 3)
return "Hub Newbie running"
