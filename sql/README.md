# Scripts SQL Server 2008

Coloca en esta carpeta los scripts de definición y mantenimiento de la base de datos dirigida a Microsoft SQL Server 2008.

Se recomienda organizar los archivos en subcarpetas según el propósito (por ejemplo `schema/`, `seed/`, `migrations/`).

## Scripts incluidos

- `01_create_database.sql`: crea la base de datos principal del proyecto.
- `20240520_01_procUsuariosValidarAcceso.sql`: procedimiento almacenado para validar el acceso de usuarios.
- `20240520_02_seedUsuarioAdmin.sql`: datos iniciales para el usuario administrador.
- `20240521_01_createPacientesConsultas.sql`: tablas para pacientes y consultas médicas junto con sus índices.
- `20240521_02_seedPacientesConsultas.sql`: datos de ejemplo para pacientes dados de alta y consultas recientes.
