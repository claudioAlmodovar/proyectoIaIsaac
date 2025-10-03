# Scripts SQL Server 2008

Coloca en esta carpeta los scripts de definición y mantenimiento de la base de datos dirigida a Microsoft SQL Server 2008.

## Scripts incluidos

- `20251003_01_full_database.sql`: reconstruye la base de datos completa (`ProyectoIaIsaacDb`) desde cero, creando el esquema, el procedimiento de autenticación y los datos semilla necesarios. Puede ejecutarse múltiples veces sin fallos porque limpia y vuelve a crear los objetos necesarios dentro de la misma base.
