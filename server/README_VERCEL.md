# Deploy Admin API to Vercel

## 1) Sube tu repo a GitHub

Asegúrate de que tu proyecto contiene la carpeta `server/` con:
- `server/app.js`
- `server/server.js`
- `server/package.json`
- `server/vercel.json`
- `server/README.md`

## 2) Conecta GitHub a Vercel

1. Ve a https://vercel.com y crea una cuenta si no tienes.
2. Crea un nuevo proyecto y conecta tu repositorio de GitHub.
3. Durante el proceso, selecciona la carpeta `server` si te pregunta "Which directory contains your code?".

## 3) Establece las variables de entorno

En el dashboard de Vercel, ve a Settings -> Environment Variables y agrega:
- `SUPABASE_URL` = tu URL de Supabase, por ejemplo `https://tranonwmjqfnhxluwngt.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY` = tu service role key secreta
- `ADMIN_API_KEY` = un valor seguro que el app móvil enviará en `x-admin-key`

## 4) Configura el build

En Vercel, el proyecto ya debe detectar `server/server.js` con `@vercel/node`.
No necesitas un comando adicional de build si el `server/package.json` tiene:
```json
"scripts": {
  "start": "node server.js"
}
```

## 5) Despliega

Haz deploy y espera a que termine. Vercel te dará una URL pública, por ejemplo:
`https://mi-admin-api.vercel.app`

## 6) Actualiza la app móvil

En `lib/core/config.dart`, pon:
```dart
static const String adminApiUrl = 'https://mi-admin-api.vercel.app';
static const String adminApiKey = 'TU_ADMIN_API_KEY';
```

## 7) Prueba

Prueba desde la app que las operaciones admin funcionen.

## Nota de seguridad
- No pongas `SUPABASE_SERVICE_ROLE_KEY` en la app.
- `ADMIN_API_KEY` es un valor temporal para el cliente. Para producción, evalúa un backend con auth de usuario admin.
