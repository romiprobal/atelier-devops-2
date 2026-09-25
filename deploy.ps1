param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("blue", "green")]
    [string]$Color
)

Write-Host "=== Début du déploiement pour la version : $Color ===" -ForegroundColor Cyan

# 1. Détermination de la couleur inactive et de la cible
$oldColor = if ($Color -eq "blue") { "green" } else { "blue" }
$targetApp = "app-$Color"

# 2. Mise à jour dynamique du fichier nginx.conf
$nginxConfPath = "./nginx/nginx.conf"
Write-Host "Mise à jour du routage Nginx vers $targetApp..."

$nginxContent = @"
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server ${targetApp}:5000;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host `$host;
            proxy_set_header X-Real-IP `$remote_addr;
        }
    }
}
"@

[System.IO.File]::WriteAllText("$PWD/nginx/nginx.conf", $nginxContent, (New-Object System.Text.UTF8Encoding $false))

# 3. Lancement de la nouvelle version
Write-Host "Lancement de la version $Color et de l'infrastructure..."
docker compose --profile $Color up -d --build

# 4. Arrêt de l'ancienne application
Write-Host "Arrêt de l'ancienne application (app-$oldColor)..."
docker stop app-$oldColor 2>$null
docker rm app-$oldColor 2>$null

# 5. Petite pause pour laisser Flask/Gunicorn démarrer
Write-Host "Attente du démarrage de l'application..."
Start-Sleep -Seconds 2

# 6. Redémarrage propre de Nginx frontal
Write-Host "Redémarrage de Nginx frontal..."
docker compose stop nginx-frontal
docker compose rm -f nginx-frontal
docker compose up -d nginx-frontal

Write-Host "=== Déploiement de la version $Color terminé avec succès ! ===" -ForegroundColor Green