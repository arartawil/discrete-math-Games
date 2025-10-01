using System.ComponentModel.DataAnnotations;
using AlgoPlayground.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AlgoPlayground.Pages;

public class IndexModel : PageModel
{
    private readonly IProfileService _profileService;

    public IndexModel(IProfileService profileService)
    {
        _profileService = profileService;
    }

    [BindProperty]
    public ProfileInput Input { get; set; } = new();

    public async Task<IActionResult> OnGetAsync()
    {
        var profile = await _profileService.GetActiveProfileAsync();
        if (profile != null)
        {
            return RedirectToPage("/Dashboard");
        }

        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        await _profileService.GetOrCreateProfileAsync(Input.Name, Input.StudentNumber);
        return RedirectToPage("/Dashboard");
    }

    public class ProfileInput
    {
        [Required]
        [StringLength(128, MinimumLength = 2)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^\d+$", ErrorMessage = "Student number must contain digits only.")]
        [StringLength(32, MinimumLength = 3)]
        [Display(Name = "Student Number")]
        public string StudentNumber { get; set; } = string.Empty;
    }
}
