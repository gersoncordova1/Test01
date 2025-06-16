using System.ComponentModel.DataAnnotations;

namespace StudyRoomAPI.Models
{
    public class Room
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; }

        [Required]
        [Range(1, 100)]
        public int Capacity { get; set; }

        [MaxLength(500)]
        public string? Description { get; set; }

        [Required]
        public string CreatorUsername { get; set; }
    }
}