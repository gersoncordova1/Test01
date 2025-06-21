using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudyRoomAPI.Data;
using StudyRoomAPI.Models;
using System.Security.Claims; // Necesario para acceder a Claims (si usas JWT más adelante)

namespace StudyRoomAPI.Controllers
{
    [ApiController]
    [Route("[controller]")] // La ruta base para este controlador será /Reservations
    public class ReservationsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        // Constructor que recibe el DbContext por inyección de dependencias
        public ReservationsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: /Reservations/ByRoom/{roomId}
        // Endpoint para obtener todas las reservas de una sala específica
        [HttpGet("ByRoom/{roomId}")]
        public async Task<ActionResult<IEnumerable<Reservation>>> GetReservationsByRoom(Guid roomId)
        {
            // Retorna todas las reservas para la sala dada, incluyendo la información de la sala,
            // y ordenadas por la hora de inicio.
            return await _context.Reservations
                                 .Where(r => r.RoomId == roomId)
                                 .Include(r => r.Room) // Asegura que la sala relacionada se cargue
                                 .AsNoTracking() // Añadido para ayudar en la serialización
                                 .OrderBy(r => r.StartTime)
                                 .ToListAsync();
        }

        // GET: /Reservations/ByUser/{username}
        // Endpoint para obtener todas las reservas de un usuario específico
        [HttpGet("ByUser/{username}")]
        public async Task<ActionResult<IEnumerable<Reservation>>> GetReservationsByUser(string username)
        {
            // NOTA: En un sistema real con JWT, se verificaría que el 'username'
            // en la ruta coincide con el usuario autenticado para mayor seguridad.
            // O, simplemente se obtendría el username del token: User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            return await _context.Reservations
                                 .Where(r => r.Username == username)
                                 .Include(r => r.Room) // Asegura que los datos de la sala relacionada se carguen
                                 .AsNoTracking() // Añadido para ayudar en la serialización
                                 .OrderBy(r => r.StartTime)
                                 .ToListAsync();
        }

        // POST: /Reservations
        // Endpoint para crear una nueva reserva
        [HttpPost]
        public async Task<ActionResult<Reservation>> CreateReservation([FromBody] Reservation reservation)
        {
            // Validaciones básicas de la reserva
            if (reservation.StartTime >= reservation.EndTime)
            {
                return BadRequest(new { message = "La hora de inicio debe ser anterior a la hora de fin." });
            }

            if (reservation.StartTime < DateTime.UtcNow.AddMinutes(-5)) // Permitir un pequeño margen para la hora actual
            {
                 return BadRequest(new { message = "No se pueden crear reservas en el pasado." });
            }

            // 1. Verificar que la sala existe
            var room = await _context.Rooms.FindAsync(reservation.RoomId);
            if (room == null)
            {
                return NotFound(new { message = "La sala especificada para la reserva no existe." });
            }

            // 2. Verificar la disponibilidad de la sala (solapamiento de horarios)
            // Busca reservas EXISTENTES para esta misma sala que se solapen con el nuevo periodo de reserva
            var conflictingReservations = await _context.Reservations
                .Where(r => r.RoomId == reservation.RoomId &&
                            r.Status != ReservationStatus.Cancelled && // Ignora reservas canceladas
                            r.Status != ReservationStatus.Completed &&  // Ignora reservas ya pasadas
                            (
                                (reservation.StartTime < r.EndTime && reservation.EndTime > r.StartTime) || // Solapamiento general
                                (reservation.StartTime >= r.StartTime && reservation.StartTime < r.EndTime) || // Nueva empieza dentro de existente
                                (reservation.EndTime > r.StartTime && reservation.EndTime <= r.EndTime) || // Nueva termina dentro de existente
                                (reservation.StartTime <= r.StartTime && reservation.EndTime >= r.EndTime) // Nueva envuelve a existente
                            )
                        )
                .ToListAsync();

            if (conflictingReservations.Any())
            {
                return BadRequest(new { message = "La sala ya está reservada para el horario solicitado. Por favor, elige otro horario." });
            }

            // Generar un nuevo ID para la reserva
            reservation.Id = Guid.NewGuid();
            reservation.Status = ReservationStatus.Confirmed; // Establecer estado inicial como Confirmada

            _context.Reservations.Add(reservation);
            await _context.SaveChangesAsync();

            // Carga explícitamente la propiedad de navegación Room para la serialización.
            // Esto es crucial para que se incluya en la respuesta 201 Created.
            await _context.Entry(reservation).Reference(r => r.Room).LoadAsync();
            return CreatedAtAction(nameof(GetReservationsByRoom), new { roomId = reservation.RoomId }, reservation);
        }


        // PUT: /Reservations/Cancel/{id}
        // Endpoint para cancelar una reserva (solo cambia el estado a Cancelled)
        [HttpPut("Cancel/{id}")]
        public async Task<IActionResult> CancelReservation(Guid id)
        {
            var reservation = await _context.Reservations.FindAsync(id);
            if (reservation == null)
            {
                return NotFound(new { message = "Reserva no encontrada." });
            }

            // Solo permitir cancelar si la reserva no ha pasado y no está ya cancelada o completada
            if (reservation.EndTime < DateTime.UtcNow)
            {
                return BadRequest(new { message = "No se puede cancelar una reserva que ya ha finalizado." });
            }
            if (reservation.Status == ReservationStatus.Cancelled)
            {
                 return BadRequest(new { message = "Esta reserva ya está cancelada." });
            }
            if (reservation.Status == ReservationStatus.Completed)
            {
                 return BadRequest(new { message = "Esta reserva ya está completada." });
            }

            reservation.Status = ReservationStatus.Cancelled; // Cambiar estado a Cancelled
            _context.Entry(reservation).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await ReservationExists(id))
                {
                    return NotFound(new { message = "Reserva no encontrada." });
                }
                else
                {
                    throw; // Re-lanza si hay otro tipo de error de concurrencia
                }
            }

            return NoContent(); // 204 No Content
        }

        // DELETE: /Reservations/{id}
        // Endpoint para eliminar una reserva (para administradores o casos específicos)
        // Generalmente, 'cancelar' es preferible a 'eliminar' para mantener un registro.
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReservation(Guid id)
        {
            var reservation = await _context.Reservations.FindAsync(id);
            if (reservation == null)
            {
                return NotFound(new { message = "Reserva no encontrada para eliminar." });
            }

            _context.Reservations.Remove(reservation);
            await _context.SaveChangesAsync();

            return NoContent(); // 204 No Content
        }

        // Método auxiliar para verificar si una reserva existe
        private async Task<bool> ReservationExists(Guid id)
        {
            return await _context.Reservations.AnyAsync(e => e.Id == id);
        }
    }
}
