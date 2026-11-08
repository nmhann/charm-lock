# deploy.ps1
# Builds Charm Lock for the web and uploads it to S3 + CloudFront.
#
# One-time: install the AWS CLI and run `aws configure` with your keys.
# Then, from the project folder in VS Code's terminal:
#     .\deploy.ps1
#
# (If PowerShell says scripts are disabled, run this once first:
#     Set-ExecutionPolicy -Scope CurrentUser RemoteSigned )

# ---- fill these in -------------------------------------------------
$Bucket         = "your-bucket-name"     # the S3 bucket name
$DistributionId = "E1234567890ABC"       # CloudFront distribution ID
# --------------------------------------------------------------------

function Stop-OnError($step) {
    if ($LASTEXITCODE -ne 0) { Write-Host "`n$step failed - stopping." -ForegroundColor Red; exit 1 }
}

Write-Host "1/4  Building the web version..." -ForegroundColor Cyan
flutter build web --release
Stop-OnError "Build"

Write-Host "2/4  Uploading to s3://$Bucket ..." -ForegroundColor Cyan
# Flutter's file names don't change between builds, so tell browsers to
# check for a newer version every time ("no-cache" still uses the cache
# when nothing changed). --delete removes files from old builds.
aws s3 sync build/web "s3://$Bucket" --delete --cache-control "no-cache"
Stop-OnError "Upload"

Write-Host "3/4  Fixing the type of .wasm files..." -ForegroundColor Cyan
# Browsers refuse to run WebAssembly unless it's served as application/wasm,
# and Windows doesn't always know that type.
aws s3 cp build/web "s3://$Bucket" --recursive --exclude "*" --include "*.wasm" `
    --content-type "application/wasm" --cache-control "no-cache"
Stop-OnError "Wasm upload"

Write-Host "4/4  Clearing the CloudFront cache..." -ForegroundColor Cyan
aws cloudfront create-invalidation --distribution-id $DistributionId --paths "/*" | Out-Null
Stop-OnError "Invalidation"

Write-Host "`nDone! Give it a minute, then open your subdomain." -ForegroundColor Green
