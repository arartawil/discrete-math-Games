using System.ComponentModel.DataAnnotations;

namespace AlgoPlayground.Domain;

public class UserProfile
{
    public int Id { get; set; }

    [Required]
    [StringLength(128)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [RegularExpression(@"^\d+$")]
    [StringLength(32)]
    public string StudentNumber { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<ScoreEntry> Scores { get; set; } = new List<ScoreEntry>();
}
