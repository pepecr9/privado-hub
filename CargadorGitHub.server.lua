-- OPCIONAL. Sustituye el Script de servidor; no ejecutes ambos a la vez.
-- El LocalScript PanelPrivado debe seguir instalado en StarterPlayerScripts.
-- Código alojado en el repositorio del propietario.
local URL = "https://raw.githubusercontent.com/pepecr9/privado-hub/main/ServidorPrivado.server.lua"
local HttpService = game:GetService("HttpService")
local ok, code = pcall(function() return HttpService:GetAsync(URL) end)
if not ok then error("PrivadoHub: descarga fallida. " .. tostring(code)) end
local run, compileError = loadstring(code, "PrivadoHubServer")
if not run then error("PrivadoHub: " .. tostring(compileError)) end
run()
