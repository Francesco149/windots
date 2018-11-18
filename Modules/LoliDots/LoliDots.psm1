$thisSrc = $MyInvocation.MyCommand.Definition

function Open-DotsModule {
  vim $thisSrc
}

function Test-DotsModule {
  Invoke-ScriptAnalyzer $thisSrc
}

function Open-Profile {
  vim ~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
}

function Get-VideoSize {
  [CmdletBinding()]
  [OutputType([psobject])]
  param(
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$Path
  )
  process {
    $Size = @{
      Width = 0
      Height = 0
    }
    ffprobe -v quiet -show_entries stream=width,height -of `
      default=noprint_wrappers=1 $Path |
    ForEach-Object {
      $s = $_.Split("=", 2)
      if ($s.Length -ge 2) {
        switch ($s[0]) {
          "width" { $Size.Width = [uint16]$s[1] }
          "height" { $Size.Height = [uint16]$s[1] }
        }
      }
    }
    if (-not $?) {
      Throw "ffprobe failed: $LastExitCode"
    }
    New-Object -Property $Size -TypeName psobject
  }
}

function Convert-PxUpscale {
  [CmdletBinding()]
  [OutputType([psobject])]
  param(
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$Path,
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [single]$ScaleMultiplier,
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$OutFile,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [uint16]$CropWidth,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [uint16]$CropHeight
  )
  process {
    $size = Get-VideoSize $Path
    $size.Width = [uint16]($size.Width * $ScaleMultiplier)
    $size.Height = [uint16]($size.Height * $ScaleMultiplier)
    Write-Verbose "resizing to $size"
    if ($CropWidth -eq 0 -Or $CropWidth -gt $size.Width) {
      $CropWidth = $size.Width
    }
    if ($CropHeight -eq 0 -Or $CropHeight -gt $size.Height) {
      $CropHeight = $size.Height
    }
    $cropX = [uint16](($size.Width - $CropWidth) / 2)
    $cropY = [uint16](($size.Height - $CropHeight) / 2)
    Write-Verbose `
      "cropping to (${cropX}, ${cropY}) ${CropWidth}x${CropHeight}"
    $filterChain = @(
      "scale=$($size.Width):$($size.Height):flags=neighbor"
      "crop=${CropWidth}:${CropHeight}:${cropX}:${cropY}"
    )
    ffmpeg -i $Path -vf $($filterChain -join ",") $OutFile
    if (-not $?) {
      Throw "ffmpeg failed: $LastExitCode"
    }
    Get-VideoSize $OutFile
  }
}

function Convert-ToGif {
  [CmdletBinding()]
  [OutputType([psobject])]
  param(
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$Path,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$OutFile="$($(Get-Item $Path).Basename).gif",
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$PaletteFile="$($(Get-Item $Path).Basename).png",
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [uint16]$MaxWidth=800
  )
  process {
    $Result = @{
      Source = $Path
      Palette = $PaletteFile
      Result = $OutFile
    }

    $size = Get-VideoSize $Path
    if ($MaxWidth -gt $size.Width) {
      $MaxWidth = $size.Width
    }

    if ($PaletteFile -ne "none") {
      $PaletteFile = "$($(Get-Item $Path).Basename).png"
      $filterChain = @(
        "scale=${MaxWidth}:-1:flags=lanczos"
        "palettegen"
      )
      ffmpeg -i $Path -vf $($filterChain -join ",") $PaletteFile
      if (-not $?) {
        Throw "hq palette generation failed: $LastExitCode"
      }
      $filterChain = @(
        "scale=${MaxWidth}:-1:flags=lanczos[x]"
        "[x][1:v]paletteuse=dither=none"
      )
      ffmpeg -i $Path -i $PaletteFile `
        -filter_complex $($filterChain -join ";") $OutFile
      if (-not $?) {
        Throw "hq conversion failed: $LastExitCode"
      }
    } else {
      ffmpeg -i $Path -vf scale=${MaxWidth}:-1:flags=lanczos $OutFile
      if (-not $?) {
        Throw "conversion failed: $LastExitCode"
      }
    }
    New-Object -Property $Result -TypeName psobject
  }
}

Set-Alias -Name dots -Value Open-DotsModule
Set-Alias -Name profile -Value Open-Profile
Set-Alias -Name ffsize -Value Get-VideoSize
Set-Alias -Name ffpxupscale -Value Convert-PxUpscale
Set-Alias -Name ffgif -Value Convert-ToGif
Set-Alias -Name lint -Value Invoke-ScriptAnalyzer
Set-Alias -Name lintdots -Value Test-DotsModule

Export-ModuleMember -Function * -Alias *
