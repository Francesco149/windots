Set-ExecutionPolicy Bypass -Force

function Import-ModuleNoCache($Name) {
  Remove-Module $Name -Force -ErrorAction SilentlyContinue
  Import-Module $Name -Force
}

Import-ModuleNoCache LoliDots
