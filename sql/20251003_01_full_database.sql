/*
    Script de creación completa de la base de datos ProyectoIaIsaacDb.
    Generado el 2025-10-03.
    Este script reconstruye toda la base desde cero (asegura el esquema y datos iniciales aun si la base ya existe).
*/

SET NOCOUNT ON;

USE master;
GO

IF DB_ID(N'ProyectoIaIsaacDb') IS NULL
BEGIN
    CREATE DATABASE ProyectoIaIsaacDb;
END;
GO

USE ProyectoIaIsaacDb;
GO

/* =========================================================
   Limpieza previa (permite re-ejecutar el script sin errores)
   ========================================================= */

IF OBJECT_ID(N'dbo.Consultas', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Consultas;
END;

IF OBJECT_ID(N'dbo.Usuarios', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Usuarios;
END;

IF OBJECT_ID(N'dbo.Pacientes', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Pacientes;
END;

IF OBJECT_ID(N'dbo.Medicos', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Medicos;
END;

GO

/* =========================================================
   Tablas base
   ========================================================= */

CREATE TABLE dbo.Medicos
(
    Id               INT IDENTITY(1, 1) PRIMARY KEY,
    Primer_Nombre    NVARCHAR(100) NOT NULL,
    Segundo_Nombre   NVARCHAR(100) NULL,
    Apellido_Paterno NVARCHAR(100) NOT NULL,
    Apellido_Materno NVARCHAR(100) NULL,
    Cedula           NVARCHAR(50)  NOT NULL,
    Telefono         NVARCHAR(25)  NULL,
    Especialidad     NVARCHAR(150) NOT NULL,
    Email            NVARCHAR(320) NOT NULL,
    Activo           BIT           NOT NULL DEFAULT (1),
    Fecha_Creacion   DATETIME2(0)  NOT NULL DEFAULT (SYSUTCDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Medicos_Cedula' AND object_id = OBJECT_ID(N'dbo.Medicos'))
BEGIN
    CREATE UNIQUE INDEX IX_Medicos_Cedula ON dbo.Medicos (Cedula);
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Medicos_Email' AND object_id = OBJECT_ID(N'dbo.Medicos'))
BEGIN
    CREATE UNIQUE INDEX IX_Medicos_Email ON dbo.Medicos (Email);
END;
GO

CREATE TABLE dbo.Pacientes
(
    Id              INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    NombreCompleto  NVARCHAR(200) NOT NULL,
    Identificador   NVARCHAR(50) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Sexo            CHAR(1) NOT NULL CHECK (Sexo IN ('M', 'F')),
    FechaAlta       DATE NOT NULL CONSTRAINT DF_Pacientes_FechaAlta DEFAULT (CONVERT(DATE, GETDATE())),
    Activo          BIT NOT NULL CONSTRAINT DF_Pacientes_Activo DEFAULT (1),
    Fecha_Creacion  DATETIME2(0) NOT NULL CONSTRAINT DF_Pacientes_FechaCreacion DEFAULT (SYSUTCDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Pacientes_Identificador' AND object_id = OBJECT_ID(N'dbo.Pacientes'))
BEGIN
    CREATE UNIQUE INDEX UX_Pacientes_Identificador ON dbo.Pacientes (Identificador);
END;
GO

CREATE TABLE dbo.Usuarios
(
    Id              INT IDENTITY(1, 1) PRIMARY KEY,
    Correo          NVARCHAR(320) NOT NULL,
    PasswordHash    NVARCHAR(255) NOT NULL,
    Nombre_Completo NVARCHAR(200) NOT NULL,
    IdMedico        INT NULL,
    Activo          BIT NOT NULL DEFAULT (1),
    Fecha_Creacion  DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Usuarios_Medicos FOREIGN KEY (IdMedico) REFERENCES dbo.Medicos (Id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Usuarios_Correo' AND object_id = OBJECT_ID(N'dbo.Usuarios'))
BEGIN
    CREATE UNIQUE INDEX IX_Usuarios_Correo ON dbo.Usuarios (Correo);
END;
GO

CREATE TABLE dbo.Consultas
(
    Id               INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    PacienteId       INT NOT NULL,
    MedicoId         INT NULL,
    Fecha            DATETIME2(0) NOT NULL CONSTRAINT DF_Consultas_Fecha DEFAULT (SYSUTCDATETIME()),
    Notas            NVARCHAR(MAX) NOT NULL,
    Sintomas         NVARCHAR(MAX) NULL,
    Recomendaciones  NVARCHAR(MAX) NULL,
    Diagnostico      NVARCHAR(MAX) NULL,
    Fecha_Creacion   DATETIME2(0) NOT NULL CONSTRAINT DF_Consultas_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Consultas_Pacientes FOREIGN KEY (PacienteId) REFERENCES dbo.Pacientes (Id),
    CONSTRAINT FK_Consultas_Medicos FOREIGN KEY (MedicoId) REFERENCES dbo.Medicos (Id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Consultas_PacienteId_Fecha' AND object_id = OBJECT_ID(N'dbo.Consultas'))
BEGIN
    CREATE INDEX IX_Consultas_PacienteId_Fecha ON dbo.Consultas (PacienteId, Fecha DESC);
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Consultas_MedicoId' AND object_id = OBJECT_ID(N'dbo.Consultas'))
BEGIN
    CREATE INDEX IX_Consultas_MedicoId ON dbo.Consultas (MedicoId);
END;
GO

/* =========================================================
   Procedimientos almacenados
   ========================================================= */

IF OBJECT_ID(N'dbo.procUsuariosValidarAcceso', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.procUsuariosValidarAcceso;
END;
GO

CREATE PROCEDURE dbo.procUsuariosValidarAcceso
    @pCorreo NVARCHAR(320),
    @pPassword NVARCHAR(255),
    @pMsg VARCHAR(300) OUTPUT,
    @pResultado BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMsg = 'Credenciales inválidas o usuario inactivo.';

    DECLARE @HashedPassword NVARCHAR(255);
    SET @HashedPassword = CONVERT(VARCHAR(255), HASHBYTES('SHA1', CONVERT(NVARCHAR(4000), @pPassword)), 2);

    DECLARE @UsuarioId INT;

    SELECT TOP (1)
        @UsuarioId = U.Id
    FROM dbo.Usuarios AS U
    WHERE U.Correo = @pCorreo
      AND U.PasswordHash = @HashedPassword
      AND U.Activo = 1;

    IF @UsuarioId IS NULL
    BEGIN
        RETURN;
    END;

    SET @pResultado = 1;
    SET @pMsg = 'Autenticación exitosa.';

    SELECT
        U.Id,
        U.Correo,
        U.Nombre_Completo
    FROM dbo.Usuarios AS U
    WHERE U.Id = @UsuarioId;
END;
GO

IF OBJECT_ID(N'dbo.procMedicosBuscar', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.procMedicosBuscar;
END;
GO

CREATE PROCEDURE dbo.procMedicosBuscar
    @pBusqueda NVARCHAR(200) = NULL,
    @pIncluirInactivos BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BusquedaInterna NVARCHAR(200);
    SET @BusquedaInterna = NULLIF(LTRIM(RTRIM(@pBusqueda)), '');

    SELECT
        M.Id,
        M.Primer_Nombre,
        M.Segundo_Nombre,
        M.Apellido_Paterno,
        M.Apellido_Materno,
        M.Cedula,
        M.Telefono,
        M.Especialidad,
        M.Email,
        M.Activo,
        NombreCompleto = LTRIM(RTRIM(
            M.Primer_Nombre + ' ' +
            COALESCE(NULLIF(M.Segundo_Nombre, '') + ' ', '') +
            M.Apellido_Paterno + ' ' +
            COALESCE(NULLIF(M.Apellido_Materno, ''), '')
        ))
    FROM dbo.Medicos AS M
    WHERE (
            @BusquedaInterna IS NULL
            OR M.Primer_Nombre LIKE '%' + @BusquedaInterna + '%'
            OR M.Segundo_Nombre LIKE '%' + @BusquedaInterna + '%'
            OR M.Apellido_Paterno LIKE '%' + @BusquedaInterna + '%'
            OR M.Apellido_Materno LIKE '%' + @BusquedaInterna + '%'
            OR M.Email LIKE '%' + @BusquedaInterna + '%'
            OR M.Cedula LIKE '%' + @BusquedaInterna + '%'
        )
      AND (@pIncluirInactivos = 1 OR M.Activo = 1)
    ORDER BY M.Apellido_Paterno, M.Apellido_Materno, M.Primer_Nombre;
END;
GO

IF OBJECT_ID(N'dbo.procMedicosCrear', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.procMedicosCrear;
END;
GO

CREATE PROCEDURE dbo.procMedicosCrear
    @pPrimerNombre NVARCHAR(100),
    @pSegundoNombre NVARCHAR(100) = NULL,
    @pApellidoPaterno NVARCHAR(100),
    @pApellidoMaterno NVARCHAR(100) = NULL,
    @pCedula NVARCHAR(50),
    @pTelefono NVARCHAR(25) = NULL,
    @pEspecialidad NVARCHAR(150),
    @pEmail NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Medicos (Primer_Nombre, Segundo_Nombre, Apellido_Paterno, Apellido_Materno, Cedula, Telefono, Especialidad, Email)
    VALUES (@pPrimerNombre, NULLIF(@pSegundoNombre, ''), @pApellidoPaterno, NULLIF(@pApellidoMaterno, ''), @pCedula, NULLIF(@pTelefono, ''), @pEspecialidad, @pEmail);

    DECLARE @NuevoId INT = SCOPE_IDENTITY();

    SELECT
        M.Id,
        M.Primer_Nombre,
        M.Segundo_Nombre,
        M.Apellido_Paterno,
        M.Apellido_Materno,
        M.Cedula,
        M.Telefono,
        M.Especialidad,
        M.Email,
        M.Activo,
        NombreCompleto = LTRIM(RTRIM(
            M.Primer_Nombre + ' ' +
            COALESCE(NULLIF(M.Segundo_Nombre, '') + ' ', '') +
            M.Apellido_Paterno + ' ' +
            COALESCE(NULLIF(M.Apellido_Materno, ''), '')
        ))
    FROM dbo.Medicos AS M
    WHERE M.Id = @NuevoId;
END;
GO

IF OBJECT_ID(N'dbo.procMedicosActualizar', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.procMedicosActualizar;
END;
GO

CREATE PROCEDURE dbo.procMedicosActualizar
    @pId INT,
    @pPrimerNombre NVARCHAR(100),
    @pSegundoNombre NVARCHAR(100) = NULL,
    @pApellidoPaterno NVARCHAR(100),
    @pApellidoMaterno NVARCHAR(100) = NULL,
    @pCedula NVARCHAR(50),
    @pTelefono NVARCHAR(25) = NULL,
    @pEspecialidad NVARCHAR(150),
    @pEmail NVARCHAR(320),
    @pActivo BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Medicos
    SET Primer_Nombre = @pPrimerNombre,
        Segundo_Nombre = NULLIF(@pSegundoNombre, ''),
        Apellido_Paterno = @pApellidoPaterno,
        Apellido_Materno = NULLIF(@pApellidoMaterno, ''),
        Cedula = @pCedula,
        Telefono = NULLIF(@pTelefono, ''),
        Especialidad = @pEspecialidad,
        Email = @pEmail,
        Activo = @pActivo
    WHERE Id = @pId;

    IF @@ROWCOUNT = 0
    BEGIN
        RETURN;
    END;

    SELECT
        M.Id,
        M.Primer_Nombre,
        M.Segundo_Nombre,
        M.Apellido_Paterno,
        M.Apellido_Materno,
        M.Cedula,
        M.Telefono,
        M.Especialidad,
        M.Email,
        M.Activo,
        NombreCompleto = LTRIM(RTRIM(
            M.Primer_Nombre + ' ' +
            COALESCE(NULLIF(M.Segundo_Nombre, '') + ' ', '') +
            M.Apellido_Paterno + ' ' +
            COALESCE(NULLIF(M.Apellido_Materno, ''), '')
        ))
    FROM dbo.Medicos AS M
    WHERE M.Id = @pId;
END;
GO

IF OBJECT_ID(N'dbo.procMedicosDesactivar', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.procMedicosDesactivar;
END;
GO

CREATE PROCEDURE dbo.procMedicosDesactivar
    @pId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Medicos
    SET Activo = 0
    WHERE Id = @pId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END;
GO

IF OBJECT_ID(N'dbo.procUsuariosBuscar', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.procUsuariosBuscar;
END;
GO

CREATE PROCEDURE dbo.procUsuariosBuscar
    @pBusqueda NVARCHAR(200) = NULL,
    @pIncluirInactivos BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BusquedaInterna NVARCHAR(200);
    SET @BusquedaInterna = NULLIF(LTRIM(RTRIM(@pBusqueda)), '');

    SELECT
        U.Id,
        U.Correo,
        U.Nombre_Completo,
        U.IdMedico,
        U.Activo,
        MedicoNombre = LTRIM(RTRIM(
            COALESCE(M.Primer_Nombre, '') + ' ' +
            COALESCE(NULLIF(M.Segundo_Nombre, '') + ' ', '') +
            COALESCE(M.Apellido_Paterno, '') + ' ' +
            COALESCE(NULLIF(M.Apellido_Materno, ''), '')
        ))
    FROM dbo.Usuarios AS U
    LEFT JOIN dbo.Medicos AS M ON U.IdMedico = M.Id
    WHERE (
            @BusquedaInterna IS NULL
            OR U.Correo LIKE '%' + @BusquedaInterna + '%'
            OR U.Nombre_Completo LIKE '%' + @BusquedaInterna + '%'
        )
      AND (@pIncluirInactivos = 1 OR U.Activo = 1)
    ORDER BY U.Nombre_Completo;
END;
GO

IF OBJECT_ID(N'dbo.procUsuariosCrear', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.procUsuariosCrear;
END;
GO

CREATE PROCEDURE dbo.procUsuariosCrear
    @pCorreo NVARCHAR(320),
    @pPassword NVARCHAR(255),
    @pNombreCompleto NVARCHAR(200),
    @pIdMedico INT = NULL,
    @pActivo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Hash NVARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA1', CONVERT(NVARCHAR(4000), @pPassword)), 2);

    INSERT INTO dbo.Usuarios (Correo, PasswordHash, Nombre_Completo, IdMedico, Activo)
    VALUES (@pCorreo, @Hash, @pNombreCompleto, @pIdMedico, @pActivo);

    DECLARE @NuevoId INT = SCOPE_IDENTITY();

    SELECT
        U.Id,
        U.Correo,
        U.Nombre_Completo,
        U.IdMedico,
        U.Activo
    FROM dbo.Usuarios AS U
    WHERE U.Id = @NuevoId;
END;
GO

IF OBJECT_ID(N'dbo.procUsuariosActualizar', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.procUsuariosActualizar;
END;
GO

CREATE PROCEDURE dbo.procUsuariosActualizar
    @pId INT,
    @pCorreo NVARCHAR(320),
    @pNombreCompleto NVARCHAR(200),
    @pIdMedico INT = NULL,
    @pActivo BIT,
    @pPassword NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Hash NVARCHAR(255);

    IF NULLIF(@pPassword, '') IS NOT NULL
    BEGIN
        SET @Hash = CONVERT(VARCHAR(255), HASHBYTES('SHA1', CONVERT(NVARCHAR(4000), @pPassword)), 2);
    END;

    UPDATE dbo.Usuarios
    SET Correo = @pCorreo,
        Nombre_Completo = @pNombreCompleto,
        IdMedico = @pIdMedico,
        Activo = @pActivo,
        PasswordHash = COALESCE(@Hash, PasswordHash)
    WHERE Id = @pId;

    IF @@ROWCOUNT = 0
    BEGIN
        RETURN;
    END;

    SELECT
        U.Id,
        U.Correo,
        U.Nombre_Completo,
        U.IdMedico,
        U.Activo
    FROM dbo.Usuarios AS U
    WHERE U.Id = @pId;
END;
GO

IF OBJECT_ID(N'dbo.procUsuariosDesactivar', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.procUsuariosDesactivar;
END;
GO

CREATE PROCEDURE dbo.procUsuariosDesactivar
    @pId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Usuarios
    SET Activo = 0
    WHERE Id = @pId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END;
GO

/* =========================================================
   Datos iniciales
   ========================================================= */

DECLARE @Correo NVARCHAR(320) = N'admin@clinicamagica.test';
DECLARE @Password NVARCHAR(255) = N'Clinica123';
DECLARE @Hash NVARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA1', CONVERT(NVARCHAR(4000), @Password)), 2);

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = @Correo)
BEGIN
    INSERT INTO dbo.Usuarios (Correo, PasswordHash, Nombre_Completo, IdMedico, Activo)
    VALUES (@Correo, @Hash, N'Administrador Demo', NULL, 1);
END;
GO

DECLARE @PasswordMedicos NVARCHAR(255) = N'Clinica123';
DECLARE @HashMedicos NVARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA1', CONVERT(NVARCHAR(4000), @PasswordMedicos)), 2);

DECLARE @MedicoAnaId INT;
SELECT @MedicoAnaId = Id FROM dbo.Medicos WHERE Cedula = N'MED-00123';

IF @MedicoAnaId IS NULL
BEGIN
    INSERT INTO dbo.Medicos (Primer_Nombre, Segundo_Nombre, Apellido_Paterno, Apellido_Materno, Cedula, Telefono, Especialidad, Email)
    VALUES (N'Ana', N'María', N'Romero', N'González', N'MED-00123', N'555-123-001', N'Cardiología', N'ana.romero@clinicamagica.test');

    SET @MedicoAnaId = SCOPE_IDENTITY();
END;

DECLARE @MedicoLuisId INT;
SELECT @MedicoLuisId = Id FROM dbo.Medicos WHERE Cedula = N'MED-00234';

IF @MedicoLuisId IS NULL
BEGIN
    INSERT INTO dbo.Medicos (Primer_Nombre, Segundo_Nombre, Apellido_Paterno, Apellido_Materno, Cedula, Telefono, Especialidad, Email)
    VALUES (N'Luis', NULL, N'Fuentes', N'Maldonado', N'MED-00234', N'555-123-002', N'Medicina Interna', N'luis.fuentes@clinicamagica.test');

    SET @MedicoLuisId = SCOPE_IDENTITY();
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = N'ana.romero@clinicamagica.test')
BEGIN
    INSERT INTO dbo.Usuarios (Correo, PasswordHash, Nombre_Completo, IdMedico, Activo)
    VALUES (N'ana.romero@clinicamagica.test', @HashMedicos, N'Dra. Ana María Romero', @MedicoAnaId, 1);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = N'luis.fuentes@clinicamagica.test')
BEGIN
    INSERT INTO dbo.Usuarios (Correo, PasswordHash, Nombre_Completo, IdMedico, Activo)
    VALUES (N'luis.fuentes@clinicamagica.test', @HashMedicos, N'Dr. Luis Fuentes Maldonado', @MedicoLuisId, 1);
END;
GO

INSERT INTO dbo.Pacientes (NombreCompleto, Identificador, FechaNacimiento, Sexo, FechaAlta)
SELECT N'María López Hernández', N'CLM-001', '1987-03-15', 'F', CONVERT(DATE, DATEADD(DAY, -120, GETDATE()))
WHERE NOT EXISTS (SELECT 1 FROM dbo.Pacientes WHERE Identificador = N'CLM-001');

INSERT INTO dbo.Pacientes (NombreCompleto, Identificador, FechaNacimiento, Sexo, FechaAlta)
SELECT N'Jorge Ramírez Castillo', N'CLM-002', '1979-11-02', 'M', CONVERT(DATE, DATEADD(DAY, -160, GETDATE()))
WHERE NOT EXISTS (SELECT 1 FROM dbo.Pacientes WHERE Identificador = N'CLM-002');

INSERT INTO dbo.Pacientes (NombreCompleto, Identificador, FechaNacimiento, Sexo, FechaAlta)
SELECT N'Paulina Sánchez Ríos', N'CLM-003', '1992-07-28', 'F', CONVERT(DATE, DATEADD(DAY, -200, GETDATE()))
WHERE NOT EXISTS (SELECT 1 FROM dbo.Pacientes WHERE Identificador = N'CLM-003');
GO

DECLARE @Paciente1 INT = (SELECT TOP (1) Id FROM dbo.Pacientes WHERE Identificador = N'CLM-001');
DECLARE @Paciente2 INT = (SELECT TOP (1) Id FROM dbo.Pacientes WHERE Identificador = N'CLM-002');
DECLARE @Consulta1Fecha DATETIME2(0) = DATEADD(DAY, -3, SYSUTCDATETIME());
DECLARE @Consulta2Fecha DATETIME2(0) = DATEADD(DAY, -14, SYSUTCDATETIME());
DECLARE @Consulta3Fecha DATETIME2(0) = DATEADD(DAY, -7, SYSUTCDATETIME());

IF @Paciente1 IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Consultas
        WHERE PacienteId = @Paciente1
          AND CONVERT(DATE, Fecha) = CONVERT(DATE, @Consulta1Fecha)
    )
    BEGIN
        INSERT INTO dbo.Consultas (PacienteId, Fecha, Notas, Sintomas, Recomendaciones, Diagnostico)
        VALUES
            (@Paciente1, @Consulta1Fecha, N'Control general sin novedades. Se recomienda continuar con dieta equilibrada y ejercicio moderado.', NULL, NULL, NULL);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Consultas
        WHERE PacienteId = @Paciente1
          AND CONVERT(DATE, Fecha) = CONVERT(DATE, @Consulta2Fecha)
    )
    BEGIN
        INSERT INTO dbo.Consultas (PacienteId, Fecha, Notas, Sintomas, Recomendaciones, Diagnostico)
        VALUES
            (@Paciente1, @Consulta2Fecha, N'Se registra mejoría en niveles de glucosa. Mantener monitoreo cada 15 días.', NULL, NULL, NULL);
    END;
END;

IF @Paciente2 IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Consultas
        WHERE PacienteId = @Paciente2
          AND CONVERT(DATE, Fecha) = CONVERT(DATE, @Consulta3Fecha)
    )
    BEGIN
        INSERT INTO dbo.Consultas (PacienteId, Fecha, Notas, Sintomas, Recomendaciones, Diagnostico)
        VALUES
            (@Paciente2, @Consulta3Fecha, N'Revisión de seguimiento para hipertensión. Ajuste de medicación nocturna.', NULL, NULL, NULL);
    END;
END;
GO
