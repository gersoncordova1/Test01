using Microsoft.EntityFrameworkCore;
using StudyRoomAPI.Data;
using System.Text.Json; // Necesario para JsonSerializerOptions
using System.Text.Json.Serialization; // Necesario para JsonStringEnumConverter

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Configura el serializador JSON para enums como strings
        // Mantenemos esta configuración porque es útil para RoomType y ReservationStatus.
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
        // *** SE HA ELIMINADO: CustomDateTimeConverter ya no se registra aquí ***
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure DbContext with SQL Server
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// Configure CORS
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

// *** SE HA ELIMINADO LA DEFINICIÓN DE LA CLASE CustomDateTimeConverter ***
// Esta clase ya no es necesaria con la nueva estrategia de manejo de fechas/horas.