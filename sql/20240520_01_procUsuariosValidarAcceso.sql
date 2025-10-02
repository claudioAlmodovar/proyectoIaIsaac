USE ProyectoIaIsaacDb;
GO

IF OBJECT_ID('dbo.procUsuariosValidarAcceso', 'P') IS NOT NULL
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
