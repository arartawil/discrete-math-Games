# AlgoPlayground

AlgoPlayground is an ASP.NET Core 8 Razor Pages web app that teaches discrete mathematics concepts through four mini-games. It stores user profiles and scores in SQL Server via Entity Framework Core and keeps the active profile in session.

## Getting Started

1. **Install prerequisites**
   - [.NET SDK 8.0](https://dotnet.microsoft.com/download)
   - SQL Server (LocalDB, Express, or full edition)
2. **Clone the repository**
3. **Restore tools and packages**
   ```bash
   dotnet restore
   ```
4. **Create the solution structure (if starting from scratch)**
   ```bash
   dotnet new sln -n AlgoPlayground
   dotnet new webapp -n AlgoPlayground -f net8.0
   dotnet sln add src/AlgoPlayground/AlgoPlayground.csproj
   dotnet add src/AlgoPlayground package Microsoft.EntityFrameworkCore.SqlServer
   dotnet add src/AlgoPlayground package Microsoft.EntityFrameworkCore.Design
   dotnet add src/AlgoPlayground package Microsoft.Extensions.Logging.Console
   dotnet tool install --global dotnet-ef
   ```
5. **Update the database**
   ```bash
   dotnet ef migrations add InitialCreate -p src/AlgoPlayground -s src/AlgoPlayground
   dotnet ef database update -p src/AlgoPlayground -s src/AlgoPlayground
   ```
6. **Run the app**
   ```bash
   dotnet run --project src/AlgoPlayground
   ```
7. Navigate to `https://localhost:5001` (or the configured port), create your profile, and play.

> The default connection string uses `Server=(localdb)\MSSQLLocalDB`. Override it via `ConnectionStrings__DefaultConnection` environment variable for other SQL Server instances.

## Project Structure

```
AlgoPlayground.sln
src/AlgoPlayground/
  Program.cs
  appsettings.json
  Data/
    AppDbContext.cs
    Seed.cs
    Migrations/
  Domain/
    GameId.cs
    UserProfile.cs
    ScoreEntry.cs
  Services/
    IProfileService.cs
    ProfileService.cs
    IScoreService.cs
    ScoreService.cs
    GraphBfs.cs
    LogicGateEngine.cs
    RelationFunctionValidator.cs
    PuzzleSolver.cs
  Pages/
    Index.cshtml (+.cs)
    Dashboard.cshtml (+.cs)
    Scores.cshtml (+.cs)
    Help.cshtml (+.cs)
    Game/
      MazeRunner/
      TowerLogic/
      MatchingPairs/
      PuzzleSolver/
  wwwroot/
    css/site.css
    js/*.js

tests/AlgoPlayground.Tests/
```

## Data Storage

Scores and profiles live in the SQL Server database configured by `DefaultConnection`. To reset progress, clear the relevant tables (`ScoreEntries`, `UserProfiles`) or delete/recreate the database via `dotnet ef database update`.

## Testing

Run unit tests with:

```bash
dotnet test
```

These tests cover BFS correctness, logic gate evaluation, relation/function validation, and puzzle heuristics.
