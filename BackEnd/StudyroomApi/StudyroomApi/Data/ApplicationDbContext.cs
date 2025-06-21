using Microsoft.EntityFrameworkCore;
using StudyRoomAPI.Models;

namespace StudyRoomAPI.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        // DbSet para tu tabla de usuarios
        public DbSet<User> Users { get; set; }

        // DbSet para tu tabla de salas
        public DbSet<Room> Rooms { get; set; }

        // DbSet para tu tabla de reservas
        public DbSet<Reservation> Reservations { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configuración de la relación entre Room y Reservation
            // Una Room puede tener muchas Reservations
            // Una Reservation pertenece a una Room
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Room) // Una reserva tiene una sala
                .WithMany() // Una sala puede tener muchas reservas (sin propiedad de navegación en Room por ahora)
                .HasForeignKey(r => r.RoomId); // Clave foránea en Reservation es RoomId

            // Configuración del enum RoomType para que se guarde como String
            // Esto asegura que "Grupal" o "Individual" se almacenen como texto, no como números.
            modelBuilder.Entity<Room>()
                .Property(r => r.Type)
                .HasConversion<string>();
        }
    }
}