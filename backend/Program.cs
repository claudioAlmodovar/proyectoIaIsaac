using System.Data;
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

var todos = new List<TodoItem>
{
    new(1, "Configurar base de datos"),
    new(2, "Crear componentes Vue"),
    new(3, "Diseñar endpoints")
};

app.MapGet("/todos", () => todos);

app.MapGet("/todos/{id:int}", (int id) =>
{
    var todo = todos.FirstOrDefault(t => t.Id == id);
    return todo is not null ? Results.Ok(todo) : Results.NotFound();
});

app.MapPost("/todos", (TodoItem todo) =>
{
    if (string.IsNullOrWhiteSpace(todo.Title))
    {
        return Results.BadRequest(new { error = "El título es obligatorio" });
    }

    var nextId = todos.Count == 0 ? 1 : todos.Max(t => t.Id) + 1;
    var item = todo with { Id = nextId };
    todos.Add(item);
    return Results.Created($"/todos/{item.Id}", item);
});

app.MapPut("/todos/{id:int}", (int id, TodoItem input) =>
{
    var index = todos.FindIndex(t => t.Id == id);
    if (index < 0)
    {
        return Results.NotFound();
    }

    todos[index] = input with { Id = id };
    return Results.NoContent();
});

app.MapDelete("/todos/{id:int}", (int id) =>
{
    var removed = todos.RemoveAll(t => t.Id == id) > 0;
    return removed ? Results.NoContent() : Results.NotFound();
});

app.Run();

record TodoItem(int Id, string Title);
record LoginRequest(string Email, string Password);
record LoginResponse(string Message, UsuarioDto Usuario);
record UsuarioDto(int Id, string Correo, string NombreCompleto);
