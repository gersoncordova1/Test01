using System.ComponentModel.DataAnnotations; // Necesitas esta importación

namespace StudyRoomAPI.Models
{
    public class User
    {
        [Key] // Marca Username como la clave primaria
        public string Username { get; set; }
        public string Password { get; set; }
    }
}