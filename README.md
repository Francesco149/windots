personal PowerShell scripts for windows

you might also need powershell 5.1+, I haven't tested this on older
versions

if you already have a powershell profile set up, delete or rename your
WindowsPowerShell folder in documents otherwise it will be overwritten

WARNING: this powershell profile permanently bypasses the execution policy
and imports this module automatically. only run this if you trust my code

```ps1
Set-ExecutionPolicy Bypass -Scope Process -Force
Install-PackageProvider Nuget -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PSScriptAnalyzer
choco install -y git ffmpeg vim-console
git clone https://github.com/Francesco149/windots `
  ~\Documents\WindowsPowerShell
```

# dots
opens this module in vim

alias of Open-DotsModule

# profile
opens the powershell profile in vim

alias of Open-Profile

# ffsize
gets the width and height of a video file using ffprobe

```ps1
ffsize path\to\file

$size = Get-VideoSize -Path \path\to\file
if ($size.Width -gt 1920 -Or $size.height -gt 1080) {
  Throw "this is an example and your file is too big!"
}
```

# ffpxupscale
pixel-perfect upscales a video and optionally crops it using ffmpeg

the cropping area is automatically placed at the center of the image

cropping happens after the scaling, so specifying a crop area of 1920x1080
means that the resulting video will be 1920x1080

this is meant to be used for pixel art videos and gifs that would otherwise
be ruined by scaling filters

```ps1
ffpxupscale \path\to\input\video 4 output.mp4

ffpxupscale \path\to\input\video 4 output.mp4 1920 1080

$newSize = Convert-PxUpscale `
  -Path \path\to\input\video `
  -ScaleMultiplier 4 `
  -OutFile output.mp4 `
  -CropWidth 1920 `
  -CropHeight 1080

if ($newSize.Width -ne 1920 -Or $newSize.Height -ne 1080) {
  Throw "oh no!"
}
```

# lint
alias of [Invoke-ScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer#usage)

# lintdots
runs lint on this module
