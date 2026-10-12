-- Pegar en Command Bar de Roblox Studio, en modo edición.
assert(not game:GetService("RunService"):IsRunning(), "Detén Play antes de instalar")
local serverParent=game:GetService("ServerScriptService")
local clientParent=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
assert(not serverParent:FindFirstChild("PrivadoHubServer"), "Ya existe PrivadoHubServer. Revisa el instalado.")
assert(not clientParent:FindFirstChild("PrivadoHubPanel"), "Ya existe PrivadoHubPanel. Revisa el instalado.")
game:GetService("ChangeHistoryService"):SetWaypoint("Antes de instalar PrivadoHub")
local s=Instance.new("Script")
s.Name="PrivadoHubServer"
s.Source=[====[
-- ServerScriptService. Permisos y cambios válidos únicamente en ESTE servidor.
local CONFIG = {
    OwnerUserId = 0, -- 0: propietario automático si la experiencia pertenece a un usuario.
    Admins = {}, -- [123456789] = true. Obligatorio configurar en juegos de grupo.
    Whitelist = {}, -- [123456789] = true
    StartLocked = false,
    StudioTestAdmins = true, -- usuarios de prueba con ID negativo; solo en Studio.
}
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
if RS:FindFirstChild("PrivadoHub") then error("PrivadoHub ya está iniciado") end
local owner = CONFIG.OwnerUserId
if owner == 0 and game.CreatorType == Enum.CreatorType.User then owner = game.CreatorId end
local function admin(p)
    return (owner > 0 and p.UserId == owner) or CONFIG.Admins[p.UserId] == true
        or (CONFIG.StudioTestAdmins and RunService:IsStudio() and p.UserId < 0)
end
local allowed = table.clone(CONFIG.Whitelist)
local locked = CONFIG.StartLocked
local function admitted(p) return admin(p) or allowed[p.UserId] == true end
local folder = Instance.new("Folder")
folder.Name = "PrivadoHub"
local request = Instance.new("RemoteFunction")
request.Name = "Request"
request.Parent = folder
local changed = Instance.new("RemoteEvent")
changed.Name = "Changed"
changed.Parent = folder
folder.Parent = RS
local function snapshot()
    local roster, ids = {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(roster, {id=p.UserId, name=p.Name, display=p.DisplayName, admin=admin(p), allowed=admitted(p)})
    end
    table.sort(roster, function(a,b) return a.name:lower() < b.name:lower() end)
    for id, yes in pairs(allowed) do if yes then table.insert(ids, id) end end
    table.sort(ids)
    return {locked=locked, players=roster, whitelist=ids}
end
local function broadcast()
    local data = snapshot()
    for _, p in ipairs(Players:GetPlayers()) do if admin(p) then changed:FireClient(p, data) end end
end
local function enforce()
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if not admitted(p) then p:Kick("Este servidor es privado."); count = count + 1 end
    end
    return count
end
local last = {}
request.OnServerInvoke = function(p, action, id)
    if not admin(p) then return {ok=false, message="No tienes permisos."} end
    if type(action) ~= "string" then return {ok=false, message="Orden inválida."} end
    local now = os.clock()
    if last[p] and now-last[p] < 0.35 then return {ok=false, message="Espera un momento."} end
    last[p] = now
    local message = "Actualizado."
    if action == "snapshot" then
        return {ok=true, state=snapshot(), message="Conectado al servidor."}
    elseif action == "lock" then
        locked = true
        message = "Servidor cerrado. Expulsados: " .. enforce()
    elseif action == "unlock" then
        locked = false
        message = "Servidor abierto."
    elseif action == "kickGuests" then
        message = "Expulsados: " .. enforce() .. ". El acceso conserva su estado."
    elseif action == "allow" or action == "revoke" or action == "kick" then
        if type(id) ~= "number" or id ~= id or id % 1 ~= 0 or id <= 0 or id > 9007199254740991 then
            return {ok=false, message="Introduce un UserId positivo válido."}
        end
        local target = Players:GetPlayerByUserId(id)
        if action == "allow" then
            allowed[id] = true
            message = "UserId " .. id .. " autorizado en este servidor."
        elseif action == "revoke" then
            if target and admin(target) then return {ok=false, message="No se revocan permisos de administrador desde el panel."} end
            allowed[id] = nil
            if locked and target then target:Kick("Tu permiso para este servidor ha sido retirado.") end
            message = "Autorización retirada."
        else
            if not target then return {ok=false, message="Ese jugador ya no está aquí."} end
            if admin(target) then return {ok=false, message="No puedes expulsar a un administrador."} end
            target:Kick("Has sido expulsado por el administrador.")
            message = "Jugador expulsado. Puede volver si el acceso lo permite."
        end
    else return {ok=false, message="Orden desconocida."} end
    broadcast()
    return {ok=true, state=snapshot(), message=message}
end
Players.PlayerAdded:Connect(function(p)
    if locked and not admitted(p) then p:Kick("Este servidor es privado.") end
    broadcast()
end)
Players.PlayerRemoving:Connect(function(p) last[p]=nil; task.defer(broadcast) end)
if locked then enforce() end
broadcast()
print("PrivadoHub iniciado. Administrador automático:", owner)
]====]
local c=Instance.new("LocalScript")
c.Name="PrivadoHubPanel"
c.Source=[====[
-- LocalScript en StarterPlayer > StarterPlayerScripts.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local player = Players.LocalPlayer
local folder = game:GetService("ReplicatedStorage"):WaitForChild("PrivadoHub", 20)
if not folder then warn("PrivadoHub: falta el script de servidor."); return end
local request = folder:WaitForChild("Request", 10)
local changed = folder:WaitForChild("Changed", 10)
if not request or not changed then return end
local ok, initial = pcall(function() return request:InvokeServer("snapshot") end)
if not ok or not initial.ok then return end
local gui = Instance.new("ScreenGui")
gui.Name="PrivadoHubUI"; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")
local C={bg=Color3.fromRGB(17,19,28),card=Color3.fromRGB(27,30,43),text=Color3.fromRGB(240,243,250),muted=Color3.fromRGB(155,165,186),accent=Color3.fromRGB(121,96,255),red=Color3.fromRGB(208,66,89),green=Color3.fromRGB(39,130,101)}
local function make(class, parent, props)
    local obj=Instance.new(class)
    for k,v in pairs(props) do obj[k]=v end
    obj.Parent=parent; return obj
end
local function round(obj, radius) make("UICorner",obj,{CornerRadius=UDim.new(0,radius or 10)}) end
local function label(parent,text,x,y,w,h,size,color)
    return make("TextLabel",parent,{Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,TextColor3=color or C.text,Font=Enum.Font.Gotham,TextSize=size or 14,TextXAlignment=Enum.TextXAlignment.Left})
end
local function button(parent,text,x,y,w,color)
    local b=make("TextButton",parent,{Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,38),BackgroundColor3=color or C.card,TextColor3=C.text,Font=Enum.Font.GothamMedium,TextSize=13,AutoButtonColor=true})
    round(b); return b
end
local panel=make("Frame",gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(660,530),BackgroundColor3=C.bg,BorderSizePixel=0})
round(panel,16)
make("UIStroke",panel,{Color=Color3.fromRGB(55,59,80),Thickness=1})
local scale=make("UIScale",panel,{Scale=1})
local function resize()
    local camera=workspace.CurrentCamera
    if camera then scale.Scale=math.min(1,(camera.ViewportSize.X-24)/660,(camera.ViewportSize.Y-70)/530) end
end
local viewportConnection
local function bindCamera()
    if viewportConnection then viewportConnection:Disconnect() end
    if workspace.CurrentCamera then viewportConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
    resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera); bindCamera()
label(panel,"PRIVADO / HUB",24,17,400,32,22)
label(panel,"Control de acceso · Este servidor",24,51,450,22,13,C.muted)
local minimize=button(panel,"—",588,18,48)
local status=label(panel,"",24,89,610,28,16)
local close=button(panel,"Cerrar y expulsar",24,130,194,C.accent)
local open=button(panel,"Abrir servidor",232,130,194,C.green)
local guests=button(panel,"Expulsar no autorizados",440,130,194,C.red)
label(panel,"JUGADORES",24,192,320,20,12,C.muted)
label(panel,"AUTORIZACIONES",374,192,260,20,12,C.muted)
local list=make("ScrollingFrame",panel,{Position=UDim2.fromOffset(24,222),Size=UDim2.fromOffset(328,226),BackgroundColor3=C.card,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
round(list)
make("UIListLayout",list,{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
make("UIPadding",list,{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,8)})
local input=make("TextBox",panel,{Position=UDim2.fromOffset(374,222),Size=UDim2.fromOffset(260,40),BackgroundColor3=C.card,Text="",PlaceholderText="UserId de Roblox",ClearTextOnFocus=false,TextColor3=C.text,PlaceholderColor3=C.muted,Font=Enum.Font.Gotham,TextSize=14})
round(input)
local allow=button(panel,"Autorizar ID",374,274,125,C.accent)
local revoke=button(panel,"Retirar permiso",509,274,125)
local selectedLabel=label(panel,"Selecciona un jugador",374,328,260,25,13,C.muted)
selectedLabel.TextTruncate=Enum.TextTruncate.AtEnd
local kick=button(panel,"Expulsar seleccionado",374,364,260,C.red)
local ids=label(panel,"",374,416,260,40,11,C.muted)
ids.TextWrapped=true; ids.TextYAlignment=Enum.TextYAlignment.Top
local notice=label(panel,"Conectado al servidor.",24,468,610,38,12,C.muted)
notice.TextWrapped=true
local toggle=button(gui,"PRIVADO HUB",16,16,150,C.accent)
local selected, state, busy, pending
local modal=make("Frame",panel,{Size=UDim2.fromScale(1,1),BackgroundColor3=C.bg,BackgroundTransparency=.03,Visible=false,ZIndex=10})
round(modal,16)
local confirmText=label(modal,"",40,155,580,90,20); confirmText.TextWrapped=true; confirmText.ZIndex=11
local yes=button(modal,"Confirmar",145,285,180,C.red); yes.ZIndex=11
local no=button(modal,"Cancelar",335,285,180); no.ZIndex=11
local function render(data)
    state=data
    status.Text=(data.locked and "●  PRIVADO" or "●  ABIERTO").."    ·    "..#data.players.." jugadores"
    status.TextColor3=data.locked and Color3.fromRGB(176,156,255) or Color3.fromRGB(99,215,164)
    for _, child in ipairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local found=false
    for index,p in ipairs(data.players) do
        local row=button(list,"",0,0,304,selected==p.id and C.accent or C.bg)
        row.Size=UDim2.new(1,-8,0,46); row.LayoutOrder=index
        local name=label(row,p.name,10,4,208,20,13); name.TextTruncate=Enum.TextTruncate.AtEnd
        label(row,p.admin and "ADMIN" or (p.allowed and "AUTORIZADO" or "INVITADO"),10,25,270,16,10,C.muted)
        row.Activated:Connect(function() selected=p.id; input.Text=tostring(p.id); selectedLabel.Text=p.name; render(state) end)
        if selected==p.id then found=true end
    end
    if not found then selected=nil; selectedLabel.Text="Selecciona un jugador" end
    local strings={}; for _,id in ipairs(data.whitelist) do table.insert(strings,tostring(id)) end
    ids.Text=#strings==0 and "Sin IDs adicionales. Los administradores conservan acceso." or "IDs: "..table.concat(strings,", ")
    ids.TextTruncate=Enum.TextTruncate.AtEnd
end
local function send(action,id)
    if busy then return end
    busy=true; notice.Text="Procesando…"
    task.spawn(function()
        local success,result=pcall(function() return request:InvokeServer(action,id) end)
        busy=false
        if success and type(result)=="table" then
            notice.Text=result.message or "Actualizado."
            notice.TextColor3=result.ok and C.muted or Color3.fromRGB(255,131,147)
            if result.state then render(result.state) end
        else notice.Text="No se pudo contactar con el servidor." end
    end)
end
local function confirm(text,action,id)
    if busy then return end
    pending={action,id}; confirmText.Text=text; modal.Visible=true
end
yes.Activated:Connect(function() local cmd=pending; pending=nil; modal.Visible=false; if cmd then send(cmd[1],cmd[2]) end end)
no.Activated:Connect(function() pending=nil; modal.Visible=false end)
close.Activated:Connect(function() confirm("Cerrar este servidor y expulsar a todos los jugadores no autorizados?","lock") end)
open.Activated:Connect(function() send("unlock") end)
guests.Activated:Connect(function() confirm("Expulsar a los no autorizados? Si el servidor está abierto podrán volver a entrar.","kickGuests") end)
allow.Activated:Connect(function() send("allow",tonumber(input.Text)) end)
revoke.Activated:Connect(function() local id=tonumber(input.Text); if id then confirm("Retirar el permiso del ID "..id.."? Si está dentro y el servidor está cerrado será expulsado.","revoke",id) else notice.Text="Introduce un UserId válido." end end)
kick.Activated:Connect(function() if selected then confirm("Expulsar al jugador seleccionado?","kick",selected) else notice.Text="Selecciona un jugador de la lista." end end)
minimize.Activated:Connect(function() panel.Visible=false end)
toggle.Activated:Connect(function() panel.Visible=not panel.Visible end)
UIS.InputBegan:Connect(function(inputObject,processed) if not processed and inputObject.KeyCode==Enum.KeyCode.RightShift then panel.Visible=not panel.Visible end end)
changed.OnClientEvent:Connect(render)
render(initial.state)
-- Segunda lectura para cubrir cambios entre la primera consulta y la conexión.
task.delay(.5,function() send("snapshot") end)
]====]
s.Parent=serverParent
c.Parent=clientParent
game:GetService("ChangeHistoryService"):SetWaypoint("PrivadoHub instalado")
print("PrivadoHub instalado. Configura OwnerUserId si tu experiencia pertenece a un grupo; después pulsa Play.")
