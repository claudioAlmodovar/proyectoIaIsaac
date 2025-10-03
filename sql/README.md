# Scripts SQL Server 2008

Coloca en esta carpeta los scripts de definición y mantenimiento de la base de datos dirigida a Microsoft SQL Server 2008.

## Scripts incluidos

- `20251003_01_full_database.sql`: reconstruye la base de datos completa (`ProyectoIaIsaacDb`) desde cero, creando el esquema, el procedimiento de autenticación y los datos semilla necesarios.

> ⚠️ El script elimina la base de datos existente antes de crearla de nuevo. Ejecútalo únicamente en entornos donde sea seguro descartar los datos actuales.
