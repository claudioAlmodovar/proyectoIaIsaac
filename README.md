# Proyecto IA Isaac

Este repositorio contiene una configuración inicial dividida en tres áreas principales:

- **frontend/**: Aplicación creada con Vue 3, TypeScript, Vite y Tailwind CSS.
- **backend/**: API minimal construida con ASP.NET Core lista para exponer endpoints REST.
- **sql/**: Carpeta destinada a scripts de base de datos para Microsoft SQL Server 2008.

## Frontend

La aplicación Vue está configurada con soporte para TypeScript y Tailwind CSS. Los scripts disponibles son:

```bash
npm install
npm run dev
npm run build
npm run preview
```

## Backend

El proyecto ASP.NET Core expone endpoints mínimos de ejemplo para gestionar una lista de tareas. Para ejecutarlo en un entorno con .NET instalado:

```bash
cd backend
dotnet restore
dotnet run
```

## Base de datos

Ubica los scripts T-SQL orientados a SQL Server 2008 dentro de la carpeta `sql/`. Puedes crear subcarpetas según tus necesidades (por ejemplo `schema/`, `seed/`, `migrations/`).
