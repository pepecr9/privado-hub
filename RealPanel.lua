-- Panel cliente para el juego del propietario con PrivadoHubServer instalado.
-- Puede cargarse mediante loadstring desde un entorno cliente compatible.
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then error("PrivadoHub: este cargador debe ejecutarse en el cliente.") end
local folder = game:GetService("ReplicatedStorage"):WaitForChild("PrivadoHub", 20)
if not folder then error("PrivadoHub: este servidor no tiene PrivadoHubServer. Publica la instalación y entra en un servidor nuevo.") end
local request = folder:WaitForChild("Request", 10)
local changed = folder:WaitForChild("Changed", 10)
if not request or not changed then error("PrivadoHub: la instalación del servidor está incompleta.") end
local ok, initial = pcall(function() return request:InvokeServer("snapshot") end)
if not ok then error("PrivadoHub: no se pudo contactar con el servidor: "..tostring(initial)) end
if type(initial) ~= "table" or not initial.ok then
    error("PrivadoHub: "..(type(initial) == "table" and initial.message or "respuesta de servidor inválida"))
end
local playerGui = player:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("PrivadoHubUI")
if existing then
    local existingPanel = existing:FindFirstChildWhichIsA("Frame")
    if existingPanel then existingPanel.Visible = true end
    existing.Enabled = true
    print("PrivadoHub: panel existente abierto.")
    return
end
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
