using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Mvc.ModelBinding.Validation; // Necesario para [ValidateNever]

namespace StudyRoomAPI.Models
{
    // Enum para definir el estado de una reserva
    public enum ReservationStatus
    {
        Confirmed, // La reserva ha sido confirmada y está activa
        Cancelled, // La reserva ha sido cancelada por el usuario o administrador
        Completed  // La hora de la reserva ha pasado y se considera completada
    }

    public class Reservation
    {
        // Clave primaria única para cada reserva
        [Key]
        public Guid Id { get; set; }

        // ID de la sala que se está reservando
        [Required]
        public Guid RoomId { get; set; }

        // Propiedad de navegación para la relación con la Sala
        // Indica que RoomId es una clave foránea que apunta a la tabla Rooms
        [ForeignKey("RoomId")]
        // [JsonIgnore] -- Esta línea fue eliminada para permitir la serialización en GETs
        [ValidateNever] // Indica al validador de modelos que no valide esta propiedad en la entrada POST/PUT
        public Room Room { get; set; } // Objeto Room asociado a esta reserva

        // Nombre de usuario del usuario que realiza la reserva
        [Required]
        public string Username { get; set; }

        // Fecha y hora de inicio de la reserva
        [Required]
        public DateTime StartTime { get; set; }

        // Fecha y hora de fin de la reserva
        [Required]
        public DateTime EndTime { get; set; }

        // Estado actual de la reserva
        [Required]
        public ReservationStatus Status { get; set; } = ReservationStatus.Confirmed; // Por defecto, una reserva se crea como "Confirmada"
    }
}