using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudyRoomAPI.Data;
using StudyRoomAPI.Models;

namespace StudyRoomAPI.Controllers
{
    [ApiController]
    [Route("[controller]")] // La ruta base para este controlador será /Rooms
    public class RoomsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        // Constructor que recibe el DbContext por inyección de dependencias
        public RoomsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: /Rooms
        // Endpoint para obtener la lista de todas las salas
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Room>>> GetRooms()
        {
            // Retorna todas las salas de la base de datos
            return await _context.Rooms.ToListAsync();
        }

        // GET: /Rooms/{id}
        // Endpoint para obtener una sala específica por su ID
        [HttpGet("{id}")]
        public async Task<ActionResult<Room>> GetRoom(Guid id)
        {
            // Busca la sala por su ID
            var room = await _context.Rooms.FindAsync(id);

            if (room == null)
            {
                // Si la sala no se encuentra, retorna un 404 Not Found
                return NotFound(new { message = "Sala no encontrada." });
            }

            // Retorna la sala encontrada
            return room;
        }

        // POST: /Rooms
        // Endpoint para crear una nueva sala
        [HttpPost]
        public async Task<ActionResult<Room>> CreateRoom([FromBody] Room room)
        {
            // Genera un nuevo ID para la sala
            room.Id = Guid.NewGuid();

            // Añade la nueva sala al contexto de la base de datos
            _context.Rooms.Add(room);
            // Guarda los cambios en la base de datos
            await _context.SaveChangesAsync();

            // Retorna un 201 CreatedAtAction con la sala creada
            // Esto también incluye la URL para acceder a la sala recién creada
            return CreatedAtAction(nameof(GetRoom), new { id = room.Id }, room);
        }

        // PUT: /Rooms/{id}
        // Endpoint para actualizar una sala existente
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateRoom(Guid id, [FromBody] Room room)
        {
            // Verifica si el ID de la URL coincide con el ID de la sala en el cuerpo
            if (id != room.Id)
            {
                return BadRequest(new { message = "El ID de la sala en la URL no coincide con el ID en el cuerpo de la solicitud." });
            }

            // Marca la sala como modificada para que EF Core la actualice
            _context.Entry(room).State = EntityState.Modified;

            try
            {
                // Intenta guardar los cambios en la base de datos
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                // Si ocurre una excepción de concurrencia, verifica si la sala existe
                if (!await RoomExists(id))
                {
                    return NotFound(new { message = "Sala no encontrada para actualizar." });
                }
                else
                {
                    // Si existe pero hay un problema de concurrencia, relanza la excepción
                    throw;
                }
            }

            // Retorna un 204 No Content si la actualización fue exitosa
            return NoContent();
        }

        // DELETE: /Rooms/{id}
        // Endpoint para eliminar una sala
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRoom(Guid id)
        {
            // Busca la sala a eliminar
            var room = await _context.Rooms.FindAsync(id);
            if (room == null)
            {
                // Si la sala no se encuentra, retorna un 404 Not Found
                return NotFound(new { message = "Sala no encontrada para eliminar." });
            }

            // Elimina la sala del contexto
            _context.Rooms.Remove(room);
            // Guarda los cambios en la base de datos
            await _context.SaveChangesAsync();

            // Retorna un 204 No Content si la eliminación fue exitosa
            return NoContent();
        }

        // Método auxiliar para verificar si una sala existe
        private async Task<bool> RoomExists(Guid id)
        {
            return await _context.Rooms.AnyAsync(e => e.Id == id);
        }
    }
}
