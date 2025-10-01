using AlgoPlayground.Domain;
using Microsoft.EntityFrameworkCore;

namespace AlgoPlayground.Data;

public static class Seed
{
    public static async Task InitializeAsync(AppDbContext context)
    {
        if (!await context.UserProfiles.AnyAsync())
        {
            var demo = new UserProfile
            {
                Name = "Demo Student",
                StudentNumber = "10000001",
                CreatedAt = DateTime.UtcNow
            };

            context.UserProfiles.Add(demo);
            await context.SaveChangesAsync();
        }
    }
}
