-- Stela dump: finds area names, verity variants/moods and what a box looks like.
-- Open the Verity Index in-game (and scroll a little) BEFORE running this.
local lp = game.Players.LocalPlayer
local RepS = game:GetService("ReplicatedStorage")
local out = {}
local function add(s) out[#out + 1] = s end
local function attrs(o, ind)
    for k, v in pairs(o:GetAttributes()) do add(ind .. "@" .. k .. " = " .. tostring(v)) end
end

local function ser(v, d)
    d = d or 0
    local t = typeof(v)
    if t == "table" then
        if d >= 2 then return "{...}" end
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n = n + 1
            if n > 40 then parts[#parts + 1] = "..." break end
            parts[#parts + 1] = tostring(k) .. "=" .. ser(x, d + 1)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif t == "function" then
        return "function"
    elseif t == "Instance" then
        return "<" .. v.Name .. ">"
    end
    return tostring(v)
end

local function detail(o, ind)
    add(ind .. o:GetFullName() .. " (" .. o.ClassName .. ")")
    attrs(o, ind .. "  ")
    if o:IsA("BasePart") then
        add(ind .. "  size=" .. tostring(o.Size) .. " color=" .. tostring(o.Color) .. " material=" .. o.Material.Name)
    end
    local k = 0
    for _, c in ipairs(o:GetDescendants()) do
        if k >= 25 then break end
        k = k + 1
        local x = ""
        if c:IsA("TextLabel") or c:IsA("TextButton") then x = ' text="' .. c.Text .. '"'
        elseif c:IsA("ValueBase") then x = " = " .. tostring(c.Value)
        elseif c:IsA("MeshPart") or c:IsA("SpecialMesh") then x = " mesh=" .. c.MeshId
        elseif c:IsA("Decal") or c:IsA("Texture") then x = " tex=" .. c.Texture end
        add(ind .. "  - " .. c.Name .. " (" .. c.ClassName .. ")" .. x)
        for key, val in pairs(c:GetAttributes()) do add(ind .. "      @" .. key .. " = " .. tostring(val)) end
    end
end

-- 1) game data modules (best source for every area / variant / mood)
add("== MODULES ==")
local all, n = {}, 0
for _, d in ipairs(RepS:GetDescendants()) do
    if d:IsA("ModuleScript") then
        all[#all + 1] = d:GetFullName()
        local nm = d.Name:lower()
        if n < 25 and (nm:find("area") or nm:find("verity") or nm:find("box") or nm:find("mood")
            or nm:find("variant") or nm:find("rarity") or nm:find("mutation") or nm:find("index")) then
            n = n + 1
            local ok, res = pcall(require, d)
            add(d:GetFullName() .. ": " .. (ok and ser(res):sub(1, 2500) or ("require failed: " .. tostring(res))))
        end
    end
end
add("ALL MODULES: " .. table.concat(all, ", "):sub(1, 3000))

-- 2) areas and what their boxes look like
add("== AREAS ==")
local areas = workspace:FindFirstChild("Areas")
if areas then
    for _, a in ipairs(areas:GetChildren()) do
        local names = {}
        for _, c in ipairs(a:GetChildren()) do names[#names + 1] = c.Name .. "(" .. c.ClassName .. ")" end
        add(a.Name .. " children: " .. table.concat(names, ", "))
        attrs(a, "  ")
        local boxes = a:FindFirstChild("Boxes")
        if boxes then add("  boxes count: " .. #boxes:GetChildren()) end
        local seen, texts = {}, {}
        for _, d in ipairs(a:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" and not seen[d.Text] and #texts < 6 then
                seen[d.Text] = true
                texts[#texts + 1] = d.Text
            end
        end
        if #texts > 0 then add("  texts: " .. table.concat(texts, " | ")) end
    end
    local shown = 0
    for _, a in ipairs(areas:GetChildren()) do
        local boxes = a:FindFirstChild("Boxes")
        local b = boxes and boxes:GetChildren()[1]
        if b and shown < 3 then
            shown = shown + 1
            detail(b, "  ")
        end
    end
end

-- 3) boxes currently spawned in the world
local br = workspace:FindFirstChild("BoxRuntime")
if br then
    add("== BOXRUNTIME ==")
    add("children: " .. #br:GetChildren())
    for i, c in ipairs(br:GetChildren()) do
        if i <= 3 then detail(c, "  ") end
    end
end

-- 4) Verity Index text (variants and moods show up here)
add("== VERITY INDEX TEXTS ==")
local vi = lp.PlayerGui:FindFirstChild("VerityIndex")
if vi then
    local seen, list = {}, {}
    for _, d in ipairs(vi:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" and not seen[d.Text] then
            seen[d.Text] = true
            list[#list + 1] = d.Text
        end
    end
    add(table.concat(list, " | "):sub(1, 6000))
end

-- 5) area banner / night warning text
for _, name in ipairs({"AreaBanner", "NightWarning"}) do
    local g = lp.PlayerGui:FindFirstChild(name)
    if g then
        add("== " .. name .. " ==")
        for _, d in ipairs(g:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" then add("  " .. d.Text) end
        end
    end
end

local text = table.concat(out, "\n")
if writefile then pcall(writefile, "stela_dump.txt", text) end
text = text:sub(1, 30000)
if setclipboard then setclipboard(text) end
print(text)
