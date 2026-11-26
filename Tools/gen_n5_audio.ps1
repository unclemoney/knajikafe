$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Speech

$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$voiceName = "Microsoft Haruka Desktop"
$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$ffprobe = (Get-Command ffprobe -ErrorAction Stop).Source
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
    $synth.SelectVoice($voiceName)
} catch {
    throw "Required Japanese voice '$voiceName' is not installed."
}
$synth.Dispose()

$vocabPath = Join-Path $root "Resources/Vocabulary/n5_vocab.json"
$menuPath = Join-Path $root "Resources/Vocabulary/cafe_menu.json"
$manifestPath = Join-Path $root "Resources/Audio/n5_audio_manifest.json"
$vocab = [System.IO.File]::ReadAllText($vocabPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$menu = [System.IO.File]::ReadAllText($menuPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$existing = @{}
if ([System.IO.File]::Exists($manifestPath)) {
    $oldManifest = [System.IO.File]::ReadAllText($manifestPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    foreach ($entry in $oldManifest) { $existing[$entry.id] = $entry }
}

$clips = @()
foreach ($word in $vocab) {
    $reading = if ($word.hiragana) { $word.hiragana } elseif ($word.katakana) { $word.katakana } else { $word.kanji }
    $clips += [pscustomobject]@{
        id = "vocab:$($word.id)"
        kind = "vocabulary"
        text = $reading
        relative = "Audio/Japanese/Vocabulary/$($word.id).ogg"
    }
}
foreach ($item in $menu) {
    $clips += [pscustomobject]@{
        id = $item.order_clip
        kind = "order"
        text = $item.order_text
        relative = "Audio/Japanese/Orders/$($item.vocab_id).ogg"
    }
}

$sha = [System.Security.Cryptography.SHA256]::Create()
$manifest = @()
$generated = 0
$reused = 0
foreach ($clip in $clips) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($clip.text)
    $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    $output = Join-Path $root $clip.relative
    $directory = [System.IO.Path]::GetDirectoryName($output)
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $resourcePath = "res://" + $clip.relative.Replace("\", "/")
    $canReuse = $existing.ContainsKey($clip.id) -and $existing[$clip.id].source_hash -eq $hash -and [System.IO.File]::Exists($output)
    if (-not $canReuse) {
        $wav = [System.IO.Path]::ChangeExtension($output, ".wav")
        $speaker = New-Object System.Speech.Synthesis.SpeechSynthesizer
        try {
            $speaker.SelectVoice($voiceName)
            $speaker.Rate = 0
            $speaker.SetOutputToWaveFile($wav)
            $speaker.Speak($clip.text)
        } finally {
            $speaker.Dispose()
        }
        & $ffmpeg -y -loglevel error -i $wav -af "highpass=f=70,lowpass=f=10000,loudnorm=I=-18:TP=-2:LRA=7,areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.08,areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.08" -ac 1 -ar 24000 -c:a libvorbis -q:a 4 $output
        if ($LASTEXITCODE -ne 0) { throw "FFmpeg failed for $($clip.id)" }
        Remove-Item $wav -Force
        $generated++
    } else {
        $reused++
    }
    $durationText = & $ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $output
    $duration = [double]::Parse($durationText, [System.Globalization.CultureInfo]::InvariantCulture)
    if ($duration -lt 0.15 -or $duration -gt 10.0) { throw "Invalid duration for $($clip.id): $duration" }
    $manifest += [pscustomobject]@{
        id = $clip.id
        kind = $clip.kind
        source_text = $clip.text
        source_hash = $hash
        file = $resourcePath
        voice = $voiceName
        rate = 0
        duration = [Math]::Round($duration, 3)
        status = "ready"
    }
}
$sha.Dispose()

$manifestDirectory = [System.IO.Path]::GetDirectoryName($manifestPath)
[System.IO.Directory]::CreateDirectory($manifestDirectory) | Out-Null
$json = $manifest | ConvertTo-Json -Depth 5
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestPath, $json + "`n", $utf8)
Write-Output "Audio manifest: $($manifest.Count) clips; generated=$generated reused=$reused"
