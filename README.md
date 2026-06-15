# 📝 Gestor de Tareas & Admin Dashboard

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![NodeJS](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![Vercel](https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)

Una potente e intuitiva aplicación de gestión de tareas desarrollada con **Flutter** y **Supabase**. Diseñada para equipos y empresas, cuenta con un sistema de roles jerárquico, organización mediante carpetas anidadas y sincronización de datos en **tiempo real**.

---

## ✨ Características Principales

### 👥 Sistema de Roles y Permisos
- **👑 Administrador:** Acceso total al sistema. Puede gestionar usuarios, crear carpetas, asignar tareas y tiene la capacidad de realizar borrados globales (limpieza de tareas).
- **👷 Trabajador (Worker):** Interfaz enfocada en la productividad. Solo visualiza las tareas cuyo tiempo programado (`scheduled_for`) ya se ha cumplido o es actual, evitando distracciones.

### ⚡ Tiempo Real (Realtime)
- Gracias a los **Streams de Supabase**, cualquier cambio en tareas, carpetas o perfiles se refleja instantáneamente en los dispositivos de todos los usuarios sin necesidad de recargar la página.

### 📁 Organización por Carpetas
- Clasifica las tareas en **Carpetas y Subcarpetas**. 
- Navegación fluida dentro del Dashboard de Administración para gestionar los proyectos en distintos niveles de profundidad.

### ✅ Control y Trazabilidad de Tareas
- Crea tareas con título, descripción y fecha de programación.
- Al completar una tarea, el sistema registra automáticamente **quién la completó** y **cuándo** (`completed_at`).
- Edición y eliminación ágil desde la interfaz gráfica.

### ⚙️ Panel de Administración (Admin Dashboard)
- **Pestaña de Tareas:** Vista global y gestión de tareas de la carpeta actual.
- **Pestaña de Carpetas:** Creación, edición y eliminación de directorios.
- **Pestaña de Usuarios:** Exclusivo para administradores en la raíz. Permite editar roles, nombres y eliminar empleados.

### 🔒 Seguridad y Backend API
- Integración directa con **Supabase Auth** para inicio de sesión seguro.
- **Vercel Admin API:** Para no afectar la sesión activa del administrador en la app móvil, la creación de nuevos trabajadores se delega a un pequeño backend en Node.js (hospedado en Vercel) protegido por un `x-admin-key`.

---

## 🛠️ Stack Tecnológico

- **Frontend Mobile:** Flutter & Dart
- **Backend (BaaS):** Supabase (Base de datos PostgreSQL, Autenticación y Realtime)
- **Serverless API:** Node.js (Alojado en Vercel, utilizado para Auth con `service_role_key`)

---

## 🚀 Instalación y Configuración

### 1. Requisitos Previos
- Flutter SDK instalado.
- Cuenta en Supabase.
- Cuenta en Vercel (para desplegar la API de Admin).

### 2. Configuración del Backend (Supabase)
1. Crea un proyecto en Supabase.
2. Configura las tablas necesarias en tu base de datos: `profiles`, `tasks`, `folders`, y `task_folders`.
3. Configura las políticas de seguridad (RLS) según tus necesidades y activa el soporte Realtime para las tablas relevantes.

### 3. Despliegue de la API en Vercel
1. Dirígete a la carpeta `server/`.
2. Sigue las instrucciones del archivo `server/README_VERCEL.md` para conectar y desplegar en Vercel.
3. Configura las variables de entorno en Vercel (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ADMIN_API_KEY`).
4. Obtén la URL pública de tu API (ej: `<https://mi-admin-api.vercel.app>`).

### 4. Configuración del App (Flutter)
1. Clona el repositorio e instala las dependencias:
   ```bash
   flutter pub get
   ```
2. Abre el archivo `lib/main.dart` y verifica las credenciales de inicialización de Supabase:
   ```dart
   await Supabase.initialize(
     url: 'TU_SUPABASE_URL',
     publishableKey: 'TU_SUPABASE_ANON_KEY',
   );
   ```
3. Configura las variables de la API en `lib/core/config.dart`:
   ```dart
   static const String adminApiUrl = 'URL_DE_TU_API_VERCEL';
   static const String adminApiKey = 'TU_ADMIN_API_KEY';
   ```
4. ¡Ejecuta la app!
   ```bash
   flutter run
   ```

---

*Desarrollado para optimizar la productividad y colaboración en equipo.*