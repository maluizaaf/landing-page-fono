$port = 8080
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$url  = "http://localhost:$port/"

$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
$listener.Start()

Write-Host "Servidor rodando em: $url" -ForegroundColor Green
Write-Host "Pasta: $root" -ForegroundColor Cyan
Write-Host "Pressione Ctrl+C para parar." -ForegroundColor Yellow

Start-Process $url

while ($listener.IsListening) {
    $ctx  = $listener.GetContext()
    $req  = $ctx.Request
    $resp = $ctx.Response

    $localPath = $req.Url.LocalPath.TrimStart("/").Replace("/", [System.IO.Path]::DirectorySeparatorChar)
    if ($localPath -eq "") { $localPath = "index.html" }

    $filePath = [System.IO.Path]::Combine($root, $localPath)

    if ([System.IO.File]::Exists($filePath)) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        $contentType = "application/octet-stream"
        if ($mime.ContainsKey($ext)) { $contentType = $mime[$ext] }
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $resp.ContentType = $contentType
        $resp.ContentLength64 = $bytes.Length
        $resp.StatusCode = 200
        $resp.OutputStream.Write($bytes, 0, $bytes.Length)
        Write-Host "200  $($req.Url.LocalPath)" -ForegroundColor Gray
    } else {
        $body = [System.Text.Encoding]::UTF8.GetBytes("404 - Nao encontrado")
        $resp.StatusCode = 404
        $resp.ContentType = "text/plain"
        $resp.OutputStream.Write($body, 0, $body.Length)
        Write-Host "404  $($req.Url.LocalPath)" -ForegroundColor Red
    }

    $resp.OutputStream.Close()
}
