# Build optimizado para Lighthouse - Coffee Cat PWA
# Ejecutar desde la raiz del proyecto: .\scripts\build_web.ps1

Write-Host "Construyendo Coffee Cat PWA (release optimizado)..." -ForegroundColor Cyan

flutter clean
flutter pub get

# Release con optimizacion maxima para reducir JS y mejorar Performance/TBT
flutter build web --release --tree-shake-icons --no-web-resources-cdn

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Build completado en build/web" -ForegroundColor Green
    Write-Host ""
    Write-Host "Para desplegar:" -ForegroundColor Yellow
    Write-Host "  firebase deploy --only hosting"
    Write-Host ""
    Write-Host "Para probar Lighthouse localmente (servir build release):" -ForegroundColor Yellow
    Write-Host "  npx --yes serve build/web -p 5000"
    Write-Host "  Luego abre http://localhost:5000 en Chrome Incognito y corre Lighthouse"
    Write-Host ""
    Write-Host "IMPORTANTE: Lighthouse debe correr sobre el build RELEASE desplegado en HTTPS," -ForegroundColor Magenta
    Write-Host "NO sobre 'flutter run' (modo debug baja mucho el Performance)." -ForegroundColor Magenta
} else {
    Write-Host "Error en el build" -ForegroundColor Red
    exit 1
}
