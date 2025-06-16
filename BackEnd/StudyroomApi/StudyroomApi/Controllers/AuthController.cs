using Microsoft.AspNetCore.Mvc;
using StudyRoomAPI.Models;
using StudyRoomAPI.Data; // Importa tu DbContext
using Microsoft.EntityFrameworkCore; // Necesitas esta importación para ContainsAsync

namespace StudyRoomAPI.Controllers
{
    [ApiController]
    [Route("[controller]")] // La ruta será /Auth
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        // Constructor que recibe el DbContext por inyección de dependencias
        public AuthController(ApplicationDbContext context)
        {
            _context = context;
        }

        // Endpoint para el registro de usuarios
        [HttpPost("register")] // Ruta: /Auth/register
        public async Task<IActionResult> Register([FromBody] User user)
        {
            if (string.IsNullOrEmpty(user.Username) || string.IsNullOrEmpty(user.Password))
            {
                return BadRequest(new { message = "Se requieren nombre de usuario y contraseña." });
            }

            // Verifica si el usuario ya existe en la base de datos
            if (await _context.Users.AnyAsync(u => u.Username == user.Username))
            {
                return Conflict(new { message = "El usuario ya existe." });
            }

            // Aquí, en una aplicación real, se debería hashear la contraseña antes de guardarla.
            // Por simplicidad para la persistencia, la guardaremos tal cual por ahora.
            _context.Users.Add(user);
            await _context.SaveChangesAsync(); // Guarda el nuevo usuario en la base de datos

            Console.WriteLine($"Usuario registrado en DB: {user.Username}");
            return Ok(new { message = "Registro exitoso", username = user.Username });
        }

        // Endpoint para el inicio de sesión de usuarios
        [HttpPost("login")] // Ruta: /Auth/login
        public async Task<IActionResult> Login([FromBody] User user)
        {
            if (string.IsNullOrEmpty(user.Username) || string.IsNullOrEmpty(user.Password))
            {
                return BadRequest(new { message = "Se requieren nombre de usuario y contraseña." });
            }

            // Busca el usuario en la base de datos
            var existingUser = await _context.Users
                                             .FirstOrDefaultAsync(u => u.Username == user.Username && u.Password == user.Password);
            // En una aplicación real, compararías la contraseña hasheada.

            if (existingUser != null)
            {
                Console.WriteLine($"Inicio de sesión exitoso para: {user.Username}");
                return Ok(new { message = "Inicio de sesión exitoso", username = user.Username });
            }
            else
            {
                Console.WriteLine($"Intento de inicio de sesión fallido para: {user.Username}");
                return Unauthorized(new { message = "Credenciales inválidas." });
            }
        }
    }
}
