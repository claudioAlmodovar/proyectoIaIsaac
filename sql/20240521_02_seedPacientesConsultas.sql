IF NOT EXISTS (SELECT 1 FROM dbo.Pacientes)
BEGIN
    INSERT INTO dbo.Pacientes (NombreCompleto, Identificador, FechaNacimiento, Sexo, FechaAlta)
    VALUES
        (N'María López Hernández', N'CLM-001', '1987-03-15', 'F', CONVERT(DATE, DATEADD(DAY, -120, GETDATE()))),
        (N'Jorge Ramírez Castillo', N'CLM-002', '1979-11-02', 'M', CONVERT(DATE, DATEADD(DAY, -160, GETDATE()))),
        (N'Paulina Sánchez Ríos', N'CLM-003', '1992-07-28', 'F', CONVERT(DATE, DATEADD(DAY, -200, GETDATE())));
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Consultas)
BEGIN
    DECLARE @Paciente1 INT = (SELECT TOP (1) Id FROM dbo.Pacientes WHERE Identificador = N'CLM-001');
    DECLARE @Paciente2 INT = (SELECT TOP (1) Id FROM dbo.Pacientes WHERE Identificador = N'CLM-002');

    IF @Paciente1 IS NOT NULL
    BEGIN
        INSERT INTO dbo.Consultas (PacienteId, Fecha, Notas)
        VALUES
            (@Paciente1, DATEADD(DAY, -3, SYSUTCDATETIME()), N'Control general sin novedades. Se recomienda continuar con dieta equilibrada y ejercicio moderado.'),
            (@Paciente1, DATEADD(DAY, -14, SYSUTCDATETIME()), N'Se registra mejoría en niveles de glucosa. Mantener monitoreo cada 15 días.');
    END

    IF @Paciente2 IS NOT NULL
    BEGIN
        INSERT INTO dbo.Consultas (PacienteId, Fecha, Notas)
        VALUES
            (@Paciente2, DATEADD(DAY, -7, SYSUTCDATETIME()), N'Revisión de seguimiento para hipertensión. Ajuste de medicación nocturna.');
    END
END
GO
