using Microsoft.EntityFrameworkCore;
using StudyRoomAPI.Models;

namespace StudyRoomAPI.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Room> Rooms { get; set; }

        // El método OnModelCreating (y el DbSet de Reservations) han sido eliminados.
    }
}