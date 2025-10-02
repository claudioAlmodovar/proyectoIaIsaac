IF DB_ID('ProyectoIaIsaacDb') IS NULL
BEGIN
    CREATE DATABASE ProyectoIaIsaacDb;
END;
GO

USE ProyectoIaIsaacDb;
GO

IF OBJECT_ID('dbo.Medicos', 'U') IS NULL
BEGIN
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

    CREATE UNIQUE INDEX IX_Medicos_Cedula ON dbo.Medicos (Cedula);
    CREATE UNIQUE INDEX IX_Medicos_Email ON dbo.Medicos (Email);
END;
GO

IF OBJECT_ID('dbo.Pacientes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Pacientes
    (
        Id               INT IDENTITY(1, 1) PRIMARY KEY,
        Primer_Nombre    NVARCHAR(100) NOT NULL,
        Segundo_Nombre   NVARCHAR(100) NULL,
        Apellido_Paterno NVARCHAR(100) NOT NULL,
        Apellido_Materno NVARCHAR(100) NULL,
        Telefono         NVARCHAR(25)  NULL,
        Activo           BIT           NOT NULL DEFAULT (1),
        Fecha_Creacion   DATETIME2(0)  NOT NULL DEFAULT (SYSUTCDATETIME())
    );
END;
GO

IF OBJECT_ID('dbo.Usuarios', 'U') IS NULL
BEGIN
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

    CREATE UNIQUE INDEX IX_Usuarios_Correo ON dbo.Usuarios (Correo);
END;
GO

IF OBJECT_ID('dbo.Consultas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Consultas
    (
        Id               INT IDENTITY(1, 1) PRIMARY KEY,
        Id_Medico        INT NOT NULL,
        Id_Paciente      INT NOT NULL,
        Sintomas         NVARCHAR(MAX) NULL,
        Recomendaciones  NVARCHAR(MAX) NULL,
        Diagnostico      NVARCHAR(MAX) NULL,
        Fecha_Creacion   DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_Consultas_Medicos FOREIGN KEY (Id_Medico) REFERENCES dbo.Medicos (Id),
        CONSTRAINT FK_Consultas_Pacientes FOREIGN KEY (Id_Paciente) REFERENCES dbo.Pacientes (Id)
    );

    CREATE INDEX IX_Consultas_Id_Medico ON dbo.Consultas (Id_Medico);
    CREATE INDEX IX_Consultas_Id_Paciente ON dbo.Consultas (Id_Paciente);
END;
GO
