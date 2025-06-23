using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudyRoomAPI.Data;
using StudyRoomAPI.Models;
using System.Security.Claims;

namespace StudyRoomAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReservationsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ReservationsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: /Reservations/ByRoom/{roomId}
        [HttpGet("ByRoom/{roomId}")]
        public async Task<ActionResult<IEnumerable<Reservation>>> GetReservationsByRoom(Guid roomId)
        {
            return await _context.Reservations
                                 .Where(r => r.RoomId == roomId)
                                 .Include(r => r.Room)
                                 .AsNoTracking()
                                 .OrderBy(r => r.StartTime)
                                 .ToListAsync();
        }

        // GET: /Reservations/ByUser/{username}
        [HttpGet("ByUser/{username}")]
        public async Task<ActionResult<IEnumerable<Reservation>>> GetReservationsByUser(string username)
        {
            return await _context.Reservations
                                 .Where(r => r.Username == username)
                                 .Include(r => r.Room)
                                 .AsNoTracking()
                                 .OrderBy(r => r.StartTime)
                                 .ToListAsync();
        }

        // POST: /Reservations
        [HttpPost]
        public async Task<ActionResult<Reservation>> CreateReservation([FromBody] Reservation reservation)
        {
            if (reservation.StartTime >= reservation.EndTime)
            {
                return BadRequest(new { message = "La hora de inicio debe ser anterior a la hora de fin." });
            }

            // --- CAMBIO CLAVE AQUÍ: Usamos DateTime.Now (hora local del servidor) para la validación ---
            // Se compara la hora de inicio de la reserva con la hora local actual del servidor.
            if (reservation.StartTime < DateTime.Now.AddMinutes(-1)) // Pequeño margen de 1 minuto para evitar problemas al enviar
            {
                 return BadRequest(new { message = "No se pueden crear reservas en el pasado." });
            }

            var room = await _context.Rooms.FindAsync(reservation.RoomId);
            if (room == null)
            {
                return NotFound(new { message = "La sala especificada para la reserva no existe." });
            }

            var conflictingReservations = await _context.Reservations
                .Where(r => r.RoomId == reservation.RoomId &&
                            r.Status != ReservationStatus.Cancelled &&
                            r.Status != ReservationStatus.Completed &&
                            (
                                (reservation.StartTime < r.EndTime && reservation.EndTime > r.StartTime) ||
                                (reservation.StartTime >= r.StartTime && reservation.StartTime < r.EndTime) ||
                                (reservation.EndTime > r.StartTime && reservation.EndTime <= r.EndTime) ||
                                (reservation.StartTime <= r.StartTime && reservation.EndTime >= r.EndTime)
                            )
                        )
                .ToListAsync();

            if (conflictingReservations.Any())
            {
                return BadRequest(new { message = "La sala ya está reservada para el horario solicitado. Por favor, elige otro horario." });
            }

            reservation.Id = Guid.NewGuid();
            reservation.Status = ReservationStatus.Confirmed;

            _context.Reservations.Add(reservation);
            await _context.SaveChangesAsync();

            await _context.Entry(reservation).Reference(r => r.Room).LoadAsync();
            return CreatedAtAction(nameof(GetReservationsByRoom), new { roomId = reservation.RoomId }, reservation);
        }

        // PUT: /Reservations/Cancel/{id}
        [HttpPut("Cancel/{id}")]
        public async Task<IActionResult> CancelReservation(Guid id)
        {
            var reservation = await _context.Reservations.FindAsync(id);
            if (reservation == null)
            {
                return NotFound(new { message = "Reserva no encontrada." });
            }

            // --- CAMBIO CLAVE AQUÍ: Usamos DateTime.Now para la validación de cancelación ---
            if (reservation.EndTime < DateTime.Now) // Si la hora de fin de la reserva ya pasó la hora local actual
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

            reservation.Status = ReservationStatus.Cancelled;
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
                    throw;
                }
            }

            return NoContent();
        }

        // DELETE: /Reservations/{id}
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

            return NoContent();
        }

        private async Task<bool> ReservationExists(Guid id)
        {
            return await _context.Reservations.AnyAsync(e => e.Id == id);
        }
    }
}
