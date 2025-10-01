using AlgoPlayground.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AlgoPlayground.Pages.Game.MatchingPairs;

public class IndexModel : PageModel
{
    private readonly IProfileService _profileService;

    public IndexModel(IProfileService profileService)
    {
        _profileService = profileService;
    }

    public async Task<IActionResult> OnGetAsync()
    {
        var profile = await _profileService.GetActiveProfileAsync();
        if (profile == null)
        {
            return RedirectToPage("/Index");
        }

        return Page();
    }
}
