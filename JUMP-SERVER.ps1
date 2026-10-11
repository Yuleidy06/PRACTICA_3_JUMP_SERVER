# =====================================================
# Practica 4 - JUMP-SERVER (Windows Server 2022)
# IP 10.9.50.10/29 - Gateway 10.9.50.9 - DNS 127.0.0.1
# Dominio: practica3JUMP.local (NetBIOS PRACTICA3)
# Autora: Yuleidy Barrientos - 20220949
# =====================================================

# --- 1. Controlador de dominio (requisito de RDS con Connection Broker) ---
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "practica3JUMP.local" -DomainNetbiosName "PRACTICA3" -InstallDns `
  -SafeModeAdministratorPassword (Read-Host -AsSecureString "Clave DSRM") -Force
# (el servidor se reinicia)

# --- 2. Usuarios y grupo de privilegiados ---
$p = Read-Host -AsSecureString "Clave de los usuarios"
New-ADUser -Name "usuario.priv"   -AccountPassword $p -Enabled $true -PasswordNeverExpires $true
New-ADUser -Name "usuario.nopriv" -AccountPassword $p -Enabled $true -PasswordNeverExpires $true
New-ADGroup -Name "GRP-PRIV" -GroupScope Global
Add-ADGroupMember -Identity "GRP-PRIV" -Members "usuario.priv"

# --- 3. Remote Desktop Services ---
# Se instalo por GUI: Server Manager > Manage > Add Roles and Features >
# Remote Desktop Services installation > Quick Start > Session-based desktop deployment
# (crea la coleccion QuickSessionCollection con Connection Broker, Session Host y Web Access)

$s = "$env:COMPUTERNAME." + (Get-ADDomain).DNSRoot
$d = (Get-ADDomain).NetBIOSName

# --- 4. RemoteApp: quitar las apps de ejemplo y publicar las de la practica ---
Get-RDRemoteApp -CollectionName "QuickSessionCollection" -ConnectionBroker $s | Remove-RDRemoteApp -Force

# Visible para todos los usuarios
New-RDRemoteApp -CollectionName "QuickSessionCollection" -ConnectionBroker $s `
  -DisplayName "Navegador Web" -FilePath "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# Solo usuarios con privilegios (GRP-PRIV)
New-RDRemoteApp -CollectionName "QuickSessionCollection" -ConnectionBroker $s `
  -DisplayName "PuTTY" -FilePath "C:\Program Files\PuTTY\putty.exe" -UserGroups "$d\GRP-PRIV"
New-RDRemoteApp -CollectionName "QuickSessionCollection" -ConnectionBroker $s `
  -DisplayName "Escritorio Remoto" -FilePath "C:\Windows\System32\mstsc.exe" -UserGroups "$d\GRP-PRIV"

Get-RDRemoteApp -CollectionName "QuickSessionCollection" -ConnectionBroker $s |
  Format-Table Alias, DisplayName, UserGroups

# --- 5. Certificado compatible con navegadores actuales para RD Web Access ---
$cert = New-SelfSignedCertificate -DnsName $s -CertStoreLocation Cert:\LocalMachine\My `
  -KeyUsage DigitalSignature,KeyEncipherment -KeyExportPolicy Exportable
Set-RDCertificate -Role RDWebAccess  -Thumbprint $cert.Thumbprint -ConnectionBroker $s -Force
Set-RDCertificate -Role RDPublishing -Thumbprint $cert.Thumbprint -ConnectionBroker $s -Force
Set-RDCertificate -Role RDRedirector -Thumbprint $cert.Thumbprint -ConnectionBroker $s -Force

# Portal web de RemoteApp: https://<FQDN del servidor>/RDWeb
