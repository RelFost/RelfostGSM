param (
    [string]$gamesRaw
)

# Parse games list into an array
$games = $gamesRaw -split ' '

# Display the list of games for the user to choose
Write-Host "============================================"
Write-Host "No game specified! Please choose one:"
for ($i = 0; $i -lt $games.Count; $i++) {
    $game = $games[$i] -split ':'
    Write-Host "$($i + 1). $($game[0]) ($($game[1]))"
}
Write-Host "============================================"

# Get user input
$choice = Read-Host "Enter the number or name of the game"

# Normalize input and validate selection
$selectedGame = $null
for ($i = 0; $i -lt $games.Count; $i++) {
    $game = $games[$i] -split ':'
    if ($choice -eq ($i + 1).ToString() -or $choice.ToLower() -eq $game[0].ToLower() -or $choice.ToLower() -eq $game[1].ToLower()) {
        $selectedGame = $game[0]
        break
    }
}

# If the selection is invalid, exit with an error
if (-not $selectedGame) {
    Write-Host "Invalid selection. Exiting..." -ForegroundColor Red
    exit 1
}

# Return the selected game code
Write-Output $selectedGame
