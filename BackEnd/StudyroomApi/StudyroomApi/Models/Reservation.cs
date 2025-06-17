using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization; // ¡Necesario para [JsonIgnore]!
using Microsoft.AspNetCore.Mvc.ModelBinding.Validation; // ¡Necesario para [ValidateNever]!

namespace StudyRoomAPI.Models
{
    public enum ReservationStatus
    {
        Confirmed,
        Cancelled,
        Completed
    }

    public class Reservation
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid RoomId { get; set; }

        // --- CAMBIOS AQUI: Añadimos [JsonIgnore] y [ValidateNever] ---
        [JsonIgnore] // Indica al serializador que ignore esta propiedad al enviar JSON
        [ValidateNever] // Indica al validador de modelos que no valide esta propiedad en la entrada
        [ForeignKey("RoomId")]
        public Room Room { get; set; } // Propiedad de navegación

        [Required]
        public string Username { get; set; }

        [Required]
        public DateTime StartTime { get; set; }

        [Required]
        public DateTime EndTime { get; set; }

        [Required]
        public ReservationStatus Status { get; set; } = ReservationStatus.Confirmed;
    }
}