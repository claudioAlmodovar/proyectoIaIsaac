IF OBJECT_ID('dbo.Pacientes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Pacientes
    (
        Id INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
        NombreCompleto NVARCHAR(200) NOT NULL,
        Identificador NVARCHAR(50) NOT NULL,
        FechaNacimiento DATE NOT NULL,
        Sexo CHAR(1) NOT NULL CHECK (Sexo IN ('M', 'F')),
        FechaAlta DATE NOT NULL CONSTRAINT DF_Pacientes_FechaAlta DEFAULT (CONVERT(DATE, GETDATE()))
    );

    CREATE UNIQUE INDEX UX_Pacientes_Identificador
        ON dbo.Pacientes (Identificador);
END
GO

IF OBJECT_ID('dbo.Consultas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Consultas
    (
        Id INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
        PacienteId INT NOT NULL,
        Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_Consultas_Fecha DEFAULT (SYSUTCDATETIME()),
        Notas NVARCHAR(MAX) NOT NULL,
        CONSTRAINT FK_Consultas_Pacientes FOREIGN KEY (PacienteId) REFERENCES dbo.Pacientes (Id)
    );

    CREATE INDEX IX_Consultas_PacienteId_Fecha
        ON dbo.Consultas (PacienteId, Fecha DESC);
END
GO
