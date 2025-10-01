using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AlgoPlayground.Domain;

public class ScoreEntry
{
    public int Id { get; set; }

    [Required]
    public GameId GameId { get; set; }

    [Range(1, 99)]
    public int Level { get; set; }

    [Range(0, int.MaxValue)]
    public int Points { get; set; }

    [Range(0, int.MaxValue)]
    public int DurationSec { get; set; }

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(UserProfile))]
    public int UserProfileId { get; set; }

    public UserProfile? UserProfile { get; set; }
}
