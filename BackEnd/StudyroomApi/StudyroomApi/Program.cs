using Microsoft.EntityFrameworkCore;
using StudyRoomAPI.Data;
using System.Text.Json.Serialization; // Necesario para JsonStringEnumConverter

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Configura el serializador JSON para enums como strings
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
        // Opcional: para una mejor legibilidad en desarrollo, puedes añadir Indented:
        options.JsonSerializerOptions.WriteIndented = true; // Descomenta si quieres el JSON formateado
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure DbContext with SQL Server
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// Configure CORS (versión flexible para desarrollo)
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(
        policy =>
        {
            policy.SetIsOriginAllowed(origin => new Uri(origin).Host == "localhost")
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
        });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();
app.UseAuthorization();

app.MapControllers();

app.Run();