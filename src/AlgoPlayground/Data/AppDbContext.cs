using AlgoPlayground.Domain;
using Microsoft.EntityFrameworkCore;

namespace AlgoPlayground.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
    public DbSet<ScoreEntry> ScoreEntries => Set<ScoreEntry>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<UserProfile>(entity =>
        {
            entity.Property(p => p.Name).HasMaxLength(128).IsRequired();
            entity.Property(p => p.StudentNumber).HasMaxLength(32).IsRequired();
            entity.Property(p => p.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
            entity.HasIndex(p => p.StudentNumber).IsUnique();
        });

        modelBuilder.Entity<ScoreEntry>(entity =>
        {
            entity.Property(e => e.Level).IsRequired();
            entity.Property(e => e.Points).IsRequired();
            entity.Property(e => e.Timestamp).HasDefaultValueSql("GETUTCDATE()");
            entity.HasOne(e => e.UserProfile)
                .WithMany(p => p.Scores)
                .HasForeignKey(e => e.UserProfileId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
