# Instalar PrivadoHub

1. Abre tu propia experiencia en Roblox Studio y detén Play.
2. Copia TODO `InstalarEnStudio.lua` y ejecútalo en Command Bar. Crea `PrivadoHubServer` en ServerScriptService y `PrivadoHubPanel` en StarterPlayerScripts.
3. Si tu experiencia pertenece a un grupo, configura CONFIG.OwnerUserId con tu UserId de Roblox en el servidor. En experiencias de usuario se reconoce automáticamente al propietario.
4. Prueba con un administrador y una cuenta no autorizada antes de publicar. Reinicia los servidores anteriores para aplicar la instalación.

## Cargador GitHub opcional

Conserva el LocalScript `PrivadoHubPanel`. Sustituye el contenido de `PrivadoHubServer` por `CargadorGitHub.server.lua`. Activa Allow HTTP Requests y LoadStringEnabled en ServerScriptService. No ejecutes el servidor directo y el cargador a la vez.

```lua
loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/pepecr9/privado-hub/main/ServidorPrivado.server.lua"))()
```

Este cargador se usa en un Script de servidor, dentro de tu experiencia. Por sí solo no instala el LocalScript del panel. La versión con manejo de errores está en CargadorGitHub.server.lua. Puedes fijar una versión sustituyendo main por el SHA de un commit revisado.

## Funciones y límites

Panel oscuro: cerrar y expulsar no autorizados, abrir, seleccionar y expulsar jugadores, autorizar UserIds y retirar permisos. Incluye confirmaciones y minimizado.

Los cambios del panel solo afectan al servidor actual y duran esa sesión. CONFIG.Whitelist y StartLocked definen permisos y estado inicial. No crea un servidor VIP ni cambia la privacidad de la experiencia. Un rechazo expulsa al usuario al conectar.

Se revisó la sintaxis y se comprobó la lógica de permisos con servicios simulados. Falta probar interfaz y funcionamiento real en Roblox Studio. Un cargador ejecutado solo en Potassium no concede autoridad de servidor.
