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
