using System.Data;
using System.Globalization;
using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendPolicy", policy =>
    {
        policy
            .WithOrigins(
                "http://localhost:5173",
                "https://localhost:5173")
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

builder.Services.AddScoped<SqlConnection>(sp =>
{
    var configuration = sp.GetRequiredService<IConfiguration>();
    var connectionString = configuration.GetConnectionString("DefaultConnection");

    if (string.IsNullOrWhiteSpace(connectionString))
    {
        throw new InvalidOperationException("La cadena de conexión 'DefaultConnection' no está configurada.");
    }

    return new SqlConnection(connectionString);
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("FrontendPolicy");

app.MapGet("/", () =>
    Results.Ok(new { message = "API minimal ASP.NET Core lista." })
);

app.MapGet("/health/database", async (SqlConnection connection, CancellationToken cancellationToken) =>
{
    try
    {
        await connection.OpenAsync(cancellationToken);
        return Results.Ok(new { message = "Conexión con SQL Server exitosa." });
    }
    catch (SqlException ex)
    {
        return Results.Problem(
            title: "Error al conectar con la base de datos",
            detail: ex.Message,
            statusCode: StatusCodes.Status503ServiceUnavailable
        );
    }
    finally
    {
        if (connection.State != System.Data.ConnectionState.Closed)
        {
            await connection.CloseAsync();
        }
    }
});

app.MapPost("/auth/login", async (LoginRequest request, SqlConnection connection, CancellationToken cancellationToken) =>
{
    if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "El correo y la contraseña son obligatorios." });
    }

    SqlParameter? mensajeParametro = null;
    SqlParameter? resultadoParametro = null;
    UsuarioDto? usuario = null;

    try
    {
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand("dbo.procUsuariosValidarAcceso", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add(new SqlParameter("@pCorreo", SqlDbType.NVarChar, 320)
        {
            Value = request.Email.Trim()
        });

        command.Parameters.Add(new SqlParameter("@pPassword", SqlDbType.NVarChar, 255)
        {
            Value = request.Password
        });

        mensajeParametro = new SqlParameter("@pMsg", SqlDbType.VarChar, 300)
        {
            Direction = ParameterDirection.Output
        };
        command.Parameters.Add(mensajeParametro);

        resultadoParametro = new SqlParameter("@pResultado", SqlDbType.Bit)
        {
            Direction = ParameterDirection.Output
        };
        command.Parameters.Add(resultadoParametro);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        if (reader.HasRows && await reader.ReadAsync(cancellationToken))
        {
            var id = reader.GetInt32(reader.GetOrdinal("Id"));
            var correo = reader.GetString(reader.GetOrdinal("Correo"));
            var nombreCompleto = reader.GetString(reader.GetOrdinal("Nombre_Completo"));

            usuario = new UsuarioDto(id, correo, nombreCompleto);
        }
    }
    catch (SqlException ex)
    {
        return Results.Problem(
            title: "Error al consultar la base de datos",
            detail: ex.Message,
            statusCode: StatusCodes.Status500InternalServerError);
    }
    catch (Exception ex)
    {
        return Results.Problem(
            title: "Error inesperado al procesar la autenticación",
            detail: ex.Message,
            statusCode: StatusCodes.Status500InternalServerError);
    }
    finally
    {
        if (connection.State == ConnectionState.Open)
        {
            await connection.CloseAsync();
        }
    }

    var autenticado = resultadoParametro?.Value is bool resultado && resultado;
    var mensaje = mensajeParametro?.Value as string;

    if (!autenticado || usuario is null)
    {
        return Results.Json(
            new { message = string.IsNullOrWhiteSpace(mensaje) ? "Credenciales inválidas." : mensaje },
            statusCode: StatusCodes.Status401Unauthorized);
    }

    var respuesta = new LoginResponse(
        string.IsNullOrWhiteSpace(mensaje) ? "Autenticación exitosa." : mensaje,
        usuario);

    return Results.Ok(respuesta);
});

app.MapGet("/patients", async (string? search, SqlConnection connection, CancellationToken cancellationToken) =>
{
    var pacientes = new List<PatientDto>();
    var searchTerm = string.IsNullOrWhiteSpace(search) ? null : search.Trim();

    try
    {
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(
            """
            SELECT Id, NombreCompleto, Identificador, FechaNacimiento, Sexo, FechaAlta
            FROM dbo.Pacientes
            WHERE (@search IS NULL OR NombreCompleto LIKE @search OR Identificador LIKE @search)
            ORDER BY NombreCompleto ASC
            """,
            connection);

        var parametroBusqueda = command.Parameters.Add("@search", SqlDbType.NVarChar, 200);
        parametroBusqueda.Value = searchTerm is null ? DBNull.Value : $"%{searchTerm}%";

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            var paciente = new PatientDto(
                reader.GetInt32(reader.GetOrdinal("Id")),
                reader.GetString(reader.GetOrdinal("NombreCompleto")),
                reader.GetString(reader.GetOrdinal("Identificador")),
                FormatDateOnly(reader.GetDateTime(reader.GetOrdinal("FechaNacimiento"))),
                reader.GetString(reader.GetOrdinal("Sexo")),
                FormatDateOnly(reader.GetDateTime(reader.GetOrdinal("FechaAlta"))));

            pacientes.Add(paciente);
        }
    }
    catch (SqlException ex)
    {
        return Results.Problem(
            title: "Error al consultar pacientes",
            detail: ex.Message,
            statusCode: StatusCodes.Status500InternalServerError);
    }
    finally
    {
        if (connection.State == ConnectionState.Open)
        {
            await connection.CloseAsync();
        }
    }

    return Results.Ok(pacientes);
});

app.MapGet("/patients/{id:int}", async (int id, SqlConnection connection, CancellationToken cancellationToken) =>
{
    PatientDto? paciente = null;

    try
    {
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(
            """
            SELECT Id, NombreCompleto, Identificador, FechaNacimiento, Sexo, FechaAlta
            FROM dbo.Pacientes
            WHERE Id = @id
            """,
            connection);

        command.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = id });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        if (reader.HasRows && await reader.ReadAsync(cancellationToken))
        {
            paciente = new PatientDto(
                reader.GetInt32(reader.GetOrdinal("Id")),
                reader.GetString(reader.GetOrdinal("NombreCompleto")),
                reader.GetString(reader.GetOrdinal("Identificador")),
                FormatDateOnly(reader.GetDateTime(reader.GetOrdinal("FechaNacimiento"))),
                reader.GetString(reader.GetOrdinal("Sexo")),
                FormatDateOnly(reader.GetDateTime(reader.GetOrdinal("FechaAlta"))));
        }
    }
    catch (SqlException ex)
    {
        return Results.Problem(
            title: "Error al consultar paciente",
            detail: ex.Message,
            statusCode: StatusCodes.Status500InternalServerError);
    }
    finally
    {
        if (connection.State == ConnectionState.Open)
        {
            await connection.CloseAsync();
        }
    }

    return paciente is not null ? Results.Ok(paciente) : Results.NotFound(new { message = "Paciente no encontrado." });
});

app.MapPost("/patients", async (CreatePatientRequest request, SqlConnection connection, CancellationToken cancellationToken) =>
{
    if (string.IsNullOrWhiteSpace(request.NombreCompleto) || string.IsNullOrWhiteSpace(request.Identificador))
    {
        return Results.BadRequest(new { message = "Nombre completo e identificador son obligatorios." });
    }

    if (string.IsNullOrWhiteSpace(request.FechaNacimiento) ||
        !DateOnly.TryParse(request.FechaNacimiento, out var fechaNacimiento))
    {
        return Results.BadRequest(new { message = "La fecha de nacimiento es inválida." });
    }

    if (string.IsNullOrWhiteSpace(request.Sexo) ||
        (request.Sexo.ToUpperInvariant() is not ("M" or "F")))
    {
        return Results.BadRequest(new { message = "El sexo debe ser 'M' o 'F'." });
    }

    PatientDto? paciente = null;

    try
    {
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(
            """
            INSERT INTO dbo.Pacientes (NombreCompleto, Identificador, FechaNacimiento, Sexo)
            OUTPUT INSERTED.Id, INSERTED.NombreCompleto, INSERTED.Identificador, INSERTED.FechaNacimiento, INSERTED.Sexo, INSERTED.FechaAlta
            VALUES (@nombre, @identificador, @fechaNacimiento, @sexo)
            """,
            connection);

        command.Parameters.Add(new SqlParameter("@nombre", SqlDbType.NVarChar, 200)
        {
            Value = request.NombreCompleto.Trim()
        });

        command.Parameters.Add(new SqlParameter("@identificador", SqlDbType.NVarChar, 50)
        {
            Value = request.Identificador.Trim()
        });

        command.Parameters.Add(new SqlParameter("@fechaNacimiento", SqlDbType.Date)
        {
            Value = fechaNacimiento.ToDateTime(TimeOnly.MinValue)
        });

        command.Parameters.Add(new SqlParameter("@sexo", SqlDbType.Char, 1)
        {
            Value = request.Sexo.ToUpperInvariant()
        });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        if (reader.HasRows && await reader.ReadAsync(cancellationToken))
        {
            paciente = new PatientDto(
                reader.GetInt32(reader.GetOrdinal("Id")),
                reader.GetString(reader.GetOrdinal("NombreCompleto")),
                reader.GetString(reader.GetOrdinal("Identificador")),
                FormatDateOnly(reader.GetDateTime(reader.GetOrdinal("FechaNacimiento"))),
                reader.GetString(reader.GetOrdinal("Sexo")),
                FormatDateOnly(reader.GetDateTime(reader.GetOrdinal("FechaAlta"))));
        }
    }
    catch (SqlException ex) when (ex.Number is 2601 or 2627)
    {
        return Results.BadRequest(new { message = "Ya existe un paciente con el mismo identificador." });
    }
    catch (SqlException ex)
    {
        return Results.Problem(
            title: "Error al registrar paciente",
            detail: ex.Message,
            statusCode: StatusCodes.Status500InternalServerError);
    }
    finally
    {
        if (connection.State == ConnectionState.Open)
        {
            await connection.CloseAsync();
        }
    }

    return paciente is not null
        ? Results.Created($"/patients/{paciente.Id}", paciente)
        : Results.Problem(title: "No fue posible registrar al paciente", statusCode: StatusCodes.Status500InternalServerError);
});

app.MapGet("/patients/{id:int}/consultations", async (int id, int? limit, SqlConnection connection, CancellationToken cancellationToken) =>
{
    var consultas = new List<ConsultationDto>();
    var top = limit is > 0 ? Math.Min(limit.Value, 50) : 50;

    try
    {
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(
            """
            SELECT TOP (@top) Id, PacienteId, Fecha, Notas
            FROM dbo.Consultas
            WHERE PacienteId = @id
            ORDER BY Fecha DESC
            """,
            connection);

        command.Parameters.Add(new SqlParameter("@top", SqlDbType.Int) { Value = top });
        command.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = id });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            consultas.Add(new ConsultationDto(
                reader.GetInt32(reader.GetOrdinal("Id")),
                reader.GetInt32(reader.GetOrdinal("PacienteId")),
                FormatDateTime(reader.GetDateTime(reader.GetOrdinal("Fecha"))),
                reader.GetString(reader.GetOrdinal("Notas"))));
        }
    }
    catch (SqlException ex)
    {
        return Results.Problem(
            title: "Error al consultar historial del paciente",
            detail: ex.Message,
            statusCode: StatusCodes.Status500InternalServerError);
    }
    finally
    {
        if (connection.State == ConnectionState.Open)
        {
            await connection.CloseAsync();
        }
    }

    return Results.Ok(consultas);
});

app.MapGet("/consultations", async (string? startDate, string? endDate, SqlConnection connection, CancellationToken cancellationToken) =>
{
    if (!TryParseDateRange(startDate, endDate, out var start, out var end, out var errorMessage))
    {
        return Results.BadRequest(new { message = errorMessage });
    }

    var consultas = new List<ConsultationHistoryDto>();

    try
    {
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(
            """
            SELECT
                c.Id,
                c.PacienteId,
                c.Fecha,
                c.Notas,
                p.Id AS PacienteIdDetalle,
                p.NombreCompleto,
                p.Identificador,
                p.Sexo,
                p.FechaNacimiento,
                p.FechaAlta
            FROM dbo.Consultas AS c
            INNER JOIN dbo.Pacientes AS p ON p.Id = c.PacienteId
            WHERE (@fechaInicio IS NULL OR c.Fecha >= @fechaInicio)
              AND (@fechaFin IS NULL OR c.Fecha <= @fechaFin)
            ORDER BY c.Fecha DESC
            """,
            connection);

        command.Parameters.Add(new SqlParameter("@fechaInicio", SqlDbType.DateTime2)
        {
            Value = start is null ? DBNull.Value : start.Value
        });

        command.Parameters.Add(new SqlParameter("@fechaFin", SqlDbType.DateTime2)
        {
            Value = end is null ? DBNull.Value : end.Value
        });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            var paciente = new PatientSummaryDto(
                reader.GetInt32(reader.GetOrdinal("PacienteIdDetalle")),
                reader.GetString(reader.GetOrdinal("NombreCompleto")),
                reader.GetString(reader.GetOrdinal("Identificador")),
                reader.GetString(reader.GetOrdinal("Sexo")),
                FormatDateOnly(reader.GetDateTime(reader.GetOrdinal("FechaNacimiento"))),
                FormatDateOnly(reader.GetDateTime(reader.GetOrdinal("FechaAlta"))));

            var consulta = new ConsultationHistoryDto(
                reader.GetInt32(reader.GetOrdinal("Id")),
                reader.GetInt32(reader.GetOrdinal("PacienteId")),
                FormatDateTime(reader.GetDateTime(reader.GetOrdinal("Fecha"))),
                reader.GetString(reader.GetOrdinal("Notas")),
                paciente);

            consultas.Add(consulta);
        }
    }
    catch (SqlException ex)
    {
        return Results.Problem(
            title: "Error al consultar historial",
            detail: ex.Message,
            statusCode: StatusCodes.Status500InternalServerError);
    }
    finally
    {
        if (connection.State == ConnectionState.Open)
        {
            await connection.CloseAsync();
        }
    }

    return Results.Ok(consultas);
});

app.MapPost("/consultations", async (CreateConsultationRequest request, SqlConnection connection, CancellationToken cancellationToken) =>
{
    if (request.PacienteId <= 0)
    {
        return Results.BadRequest(new { message = "El identificador del paciente es obligatorio." });
    }

    if (string.IsNullOrWhiteSpace(request.Notas))
    {
        return Results.BadRequest(new { message = "Las notas de la consulta son obligatorias." });
    }

    DateTime? fechaConsulta = null;
    if (!string.IsNullOrWhiteSpace(request.Fecha))
    {
        if (!DateTime.TryParse(request.Fecha, out var parsed))
        {
            return Results.BadRequest(new { message = "La fecha de la consulta es inválida." });
        }

        fechaConsulta = parsed.ToUniversalTime();
    }

    ConsultationDto? consulta = null;

    try
    {
        await connection.OpenAsync(cancellationToken);

        await using (var validateCommand = new SqlCommand(
                   "SELECT COUNT(1) FROM dbo.Pacientes WHERE Id = @id", connection))
        {
            validateCommand.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = request.PacienteId });

            var exists = (int)await validateCommand.ExecuteScalarAsync(cancellationToken);
            if (exists == 0)
            {
                return Results.NotFound(new { message = "El paciente no existe." });
            }
        }

        await using var command = new SqlCommand(
            """
            INSERT INTO dbo.Consultas (PacienteId, Fecha, Notas)
            OUTPUT INSERTED.Id, INSERTED.PacienteId, INSERTED.Fecha, INSERTED.Notas
            VALUES (@pacienteId, @fecha, @notas)
            """,
            connection);

        command.Parameters.Add(new SqlParameter("@pacienteId", SqlDbType.Int) { Value = request.PacienteId });
        command.Parameters.Add(new SqlParameter("@fecha", SqlDbType.DateTime2)
        {
            Value = fechaConsulta ?? DateTime.UtcNow
        });
        command.Parameters.Add(new SqlParameter("@notas", SqlDbType.NVarChar)
        {
            Value = request.Notas.Trim()
        });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        if (reader.HasRows && await reader.ReadAsync(cancellationToken))
        {
            consulta = new ConsultationDto(
                reader.GetInt32(reader.GetOrdinal("Id")),
                reader.GetInt32(reader.GetOrdinal("PacienteId")),
                FormatDateTime(reader.GetDateTime(reader.GetOrdinal("Fecha"))),
                reader.GetString(reader.GetOrdinal("Notas")));
        }
    }
    catch (SqlException ex)
    {
        return Results.Problem(
            title: "Error al registrar la consulta",
            detail: ex.Message,
            statusCode: StatusCodes.Status500InternalServerError);
    }
    finally
    {
        if (connection.State == ConnectionState.Open)
        {
            await connection.CloseAsync();
        }
    }

    return consulta is not null
        ? Results.Created($"/consultations/{consulta.Id}", consulta)
        : Results.Problem(title: "No fue posible registrar la consulta", statusCode: StatusCodes.Status500InternalServerError);
});

app.Run();

static string FormatDateOnly(DateTime dateTime)
    => dateTime.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);

static string FormatDateTime(DateTime dateTime)
    => DateTime.SpecifyKind(dateTime, DateTimeKind.Utc).ToUniversalTime().ToString("o", CultureInfo.InvariantCulture);

static bool TryParseDateRange(string? startDate, string? endDate, out DateTime? start, out DateTime? end, out string? error)
{
    start = null;
    end = null;
    error = null;

    var hasStart = !string.IsNullOrWhiteSpace(startDate);
    var hasEnd = !string.IsNullOrWhiteSpace(endDate);

    DateTime parsedStart = default;
    DateTime parsedEnd = default;

    if (hasStart && !DateTime.TryParse(startDate, out parsedStart))
    {
        error = "La fecha inicial no tiene un formato válido.";
        return false;
    }

    if (hasEnd && !DateTime.TryParse(endDate, out parsedEnd))
    {
        error = "La fecha final no tiene un formato válido.";
        return false;
    }

    if (hasStart)
    {
        start = parsedStart.Date;
    }

    if (hasEnd)
    {
        end = parsedEnd.Date.AddDays(1).AddTicks(-1);
    }

    if (start.HasValue && end.HasValue && start > end)
    {
        error = "La fecha inicial no puede ser posterior a la fecha final.";
        return false;
    }

    return true;
}

record LoginRequest(string Email, string Password);
record LoginResponse(string Message, UsuarioDto Usuario);
record UsuarioDto(int Id, string Correo, string NombreCompleto);
record PatientDto(int Id, string NombreCompleto, string Identificador, string FechaNacimiento, string Sexo, string FechaAlta);
record PatientSummaryDto(int Id, string NombreCompleto, string Identificador, string Sexo, string FechaNacimiento, string FechaAlta);
record ConsultationDto(int Id, int PacienteId, string Fecha, string Notas);
record ConsultationHistoryDto(int Id, int PacienteId, string Fecha, string Notas, PatientSummaryDto Paciente);
record CreatePatientRequest(string NombreCompleto, string Identificador, string FechaNacimiento, string Sexo);
record CreateConsultationRequest(int PacienteId, string Notas, string? Fecha);
