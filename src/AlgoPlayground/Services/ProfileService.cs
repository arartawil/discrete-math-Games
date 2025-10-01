using AlgoPlayground.Data;
using AlgoPlayground.Domain;
using Microsoft.EntityFrameworkCore;

namespace AlgoPlayground.Services;

public class ProfileService : IProfileService
{
    private const string SessionKey = "ProfileId";
    private readonly AppDbContext _context;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public ProfileService(AppDbContext context, IHttpContextAccessor httpContextAccessor)
    {
        _context = context;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<UserProfile?> GetActiveProfileAsync(CancellationToken cancellationToken = default)
    {
        var id = GetActiveProfileId();
        if (id == null)
        {
            return null;
        }

        var profile = await _context.UserProfiles
            .FirstOrDefaultAsync(p => p.Id == id.Value, cancellationToken);

        if (profile != null)
        {
            await _context.Entry(profile)
                .Collection(p => p.Scores)
                .Query()
                .OrderByDescending(s => s.Timestamp)
                .Take(4)
                .LoadAsync(cancellationToken);
        }

        return profile;
    }

    public async Task<UserProfile> GetOrCreateProfileAsync(string name, string studentNumber, CancellationToken cancellationToken = default)
    {
        var existing = await _context.UserProfiles
            .FirstOrDefaultAsync(p => p.StudentNumber == studentNumber, cancellationToken);

        if (existing != null)
        {
            AttachProfileToSession(existing.Id);
            return existing;
        }

        var profile = new UserProfile
        {
            Name = name,
            StudentNumber = studentNumber,
            CreatedAt = DateTime.UtcNow
        };

        _context.UserProfiles.Add(profile);
        await _context.SaveChangesAsync(cancellationToken);
        AttachProfileToSession(profile.Id);
        return profile;
    }

    public int? GetActiveProfileId()
    {
        var session = _httpContextAccessor.HttpContext?.Session;
        return session?.GetInt32(SessionKey);
    }

    public void AttachProfileToSession(int profileId)
    {
        var session = _httpContextAccessor.HttpContext?.Session;
        session?.SetInt32(SessionKey, profileId);
    }
}
