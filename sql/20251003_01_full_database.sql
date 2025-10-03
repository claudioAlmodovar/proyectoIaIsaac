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
