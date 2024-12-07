# rgsm/tmp/game_selector.ps1
param (
    [string]$gamesRaw
)

# Преобразование списка игр
$games = $gamesRaw -split ' '

# Формирование списка для выбора
Write-Host "============================================"
Write-Host "No game specified! Please choose one:"
for ($i = 0; $i -lt $games.Count; $i++) {
    $game = $games[$i] -split ':'
    Write-Host "$($i + 1). $($game[0]) ($($game[1]))"
}
Write-Host "============================================"

# Получение ввода пользователя
$choice = Read-Host "Enter the number or name of the game"

# Нормализация ввода
$selectedGame = $null
for ($i = 0; $i -lt $games.Count; $i++) {
    $game = $games[$i] -split ':'
    if ($choice -eq ($i + 1).ToString() -or $choice.ToLower() -eq $game[0].ToLower() -or $choice.ToLower() -eq $game[1].ToLower()) {
        $selectedGame = $game[0]
        break
    }
}

# Проверка выбора
if ($null -eq $selectedGame) {
    Write-Host "Invalid selection. Exiting..." -ForegroundColor Red
    exit 1
}

# Возврат результата
Write-Output $selectedGame
