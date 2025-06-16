using Microsoft.EntityFrameworkCore;
using StudyRoomAPI.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure DbContext with SQL Server
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// --- INICIO DE LA SECCIÓN DE CONFIGURACIÓN CORS MEJORADA PARA DESARROLLO ---
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(
        policy =>
        {
            // Permite cualquier origen que sea localhost, independientemente del puerto.
            // Esto es ideal para desarrollo con Flutter Web donde los puertos cambian.
            policy.SetIsOriginAllowed(origin => new Uri(origin).Host == "localhost")
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials(); // Mantén esto si planeas usar cookies o autenticación basada en tokens (JWT)
        });
});
// --- FIN DE LA SECCIÓN DE CONFIGURACIÓN CORS MEJORADA PARA DESARROLLO ---


var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors(); // Asegúrate de que UseCors() esté aquí antes de UseAuthorization()
app.UseAuthorization();

app.MapControllers();

app.Run();