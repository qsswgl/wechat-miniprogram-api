# 发布脚本：生成自包含单文件到 .\publish\win-x64
param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = 'Stop'

$project = "$PSScriptRoot\WeChatMiniProgramAPI.csproj"
$publishDir = "$PSScriptRoot\publish\win-x64"

Write-Host "Publishing to $publishDir ..."

# 发布为 win-x64 自包含单文件，包含 appsettings 与 certificates 目录
& dotnet publish $project -c $Configuration -r win-x64 --self-contained true /p:PublishSingleFile=true /p:IncludeAllContentForSelfExtract=true /p:PublishTrimmed=false -o $publishDir

Write-Host "Done. Output: $publishDir"
