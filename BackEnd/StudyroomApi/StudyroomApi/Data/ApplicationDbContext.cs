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

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // --- RE-AÑADIDO: Configuración del enum RoomType para que se guarde como String ---
            modelBuilder.Entity<Room>()
                .Property(r => r.Type)
                .HasConversion<string>(); // Convierte el enum a su nombre de string (ej. "Grupal", "Individual")
        }
    }
}