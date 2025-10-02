var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/", () =>
    Results.Ok(new { message = "API minimal ASP.NET Core lista." })
);

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
