param([string]$Source = 'm2.mp4', [string]$Output = 'capwords-analysis/evidence/video/m2', [double]$Start = 0, [double]$End = -1, [double]$Step = 0.5, [int]$Width = 360)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime] | Out-Null
[Windows.Media.Editing.MediaClip, Windows.Media.Editing, ContentType=WindowsRuntime] | Out-Null
[Windows.Media.Editing.MediaComposition, Windows.Media.Editing, ContentType=WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.ImageStream, Windows.Graphics.Imaging, ContentType=WindowsRuntime] | Out-Null
$script:awaitMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1
function Await-Operation($Operation, [Type]$ResultType) {
    $task = $script:awaitMethod.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $task.GetAwaiter().GetResult()
}
$file = Await-Operation ([Windows.Storage.StorageFile]::GetFileFromPathAsync((Resolve-Path -LiteralPath $Source).Path)) ([Windows.Storage.StorageFile])
$clip = Await-Operation ([Windows.Media.Editing.MediaClip]::CreateFromFileAsync($file)) ([Windows.Media.Editing.MediaClip])
$composition = New-Object Windows.Media.Editing.MediaComposition
$clipListType = [System.Collections.Generic.IList[Windows.Media.Editing.MediaClip]]
$clipListType.GetMethod('Insert').Invoke($composition.Clips, @(0, $clip))
New-Item -ItemType Directory -Force -Path $Output | Out-Null
$duration = $clip.OriginalDuration.TotalSeconds
if ($End -lt 0 -or $End -gt $duration) { $End = $duration }
Write-Output "Duration: $duration seconds"
$count = 0
for ($t = $Start; $t -lt $End; $t += $Step) {
    $stream = Await-Operation ($composition.GetThumbnailAsync([TimeSpan]::FromSeconds($t), $Width, 0, [Windows.Media.Editing.VideoFramePrecision]::NearestFrame)) ([Windows.Graphics.Imaging.ImageStream])
    $read = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($stream)
    $path = Join-Path $Output ('t{0:0000000}.jpg' -f [int][Math]::Round($t * 1000))
    $dest = [System.IO.File]::Create([System.IO.Path]::GetFullPath($path))
    try { $read.CopyTo($dest) } finally { $dest.Dispose(); $read.Dispose(); $stream.Dispose() }
    $count++
}
Write-Output "Extracted: $count frames"
