using AlgoPlayground.Domain;

namespace AlgoPlayground.Services;

public interface IProfileService
{
    Task<UserProfile?> GetActiveProfileAsync(CancellationToken cancellationToken = default);
    Task<UserProfile> GetOrCreateProfileAsync(string name, string studentNumber, CancellationToken cancellationToken = default);
    int? GetActiveProfileId();
    void AttachProfileToSession(int profileId);
}
