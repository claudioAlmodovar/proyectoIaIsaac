USE ProyectoIaIsaacDb;
GO

DECLARE @Correo NVARCHAR(320) = 'admin@clinicamagica.test';
DECLARE @Password NVARCHAR(255) = 'Clinica123';
DECLARE @Hash NVARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA1', CONVERT(NVARCHAR(4000), @Password)), 2);

IF EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = @Correo)
BEGIN
    UPDATE dbo.Usuarios
    SET PasswordHash = @Hash,
        Nombre_Completo = COALESCE(NULLIF(Nombre_Completo, ''), 'Administrador Demo'),
        Activo = 1
    WHERE Correo = @Correo;
END
ELSE
BEGIN
    INSERT INTO dbo.Usuarios (Correo, PasswordHash, Nombre_Completo, IdMedico, Activo)
    VALUES (@Correo, @Hash, 'Administrador Demo', NULL, 1);
END;
GO
