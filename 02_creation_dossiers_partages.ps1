# ÇA MARCHE ON TOUCHE PLUS !!!!

Import-Module ActiveDirectory -ErrorAction Stop
Import-Module NTFSSecurity -ErrorAction Stop

# ============================
# VARIABLES
# ============================

#saisie des valeurs souhaitées
$entreprise = read-host("Nom de l'entreprise ")
$EN = read-host("Diminutif de l'entreprise ")
$listeSousDossiers = @()
$saisie = (read-host("Dossiers partagés à créer, séparés par une virgule ")).toUpper()
$listeSousDossiers = $saisie -split ',' | ForEach-Object {$_.Trim()}

#changer lettre pour lecteur TrueNas
$chemin = "P:\"
$emplacementAD = "ou=Groupes domaine local,ou=02_Groupes,ou=$entreprise,ou=04_Entreprises clientes,ou=ETP Chasseneuil,dc=TiersLieux86,dc=fr"
$permissions = @('L','ReadAndExecute','LM','Modify','CT','FullControl')

# ============================
# CREATION DU DOSSIER PRINCIPAL
# ============================
Write-Output ""
Write-Output "CRÉATION ET PARTAGE DU DOSSIER PRINCIPAL"
Write-Output "========================================"

$nomDossier = ($entreprise).toUpper() 
New-Item -Path $chemin -Name $nomDossier -ItemType Directory | Out-Null
Write-Host "Création du dossier $nomDossier"

# partage du dossier
$cheminPartage = $chemin+$nomDossier
if(-not (Get-SmbShare -Name $nomDossier -ErrorAction SilentlyContinue)){
    New-SmbShare -Name $nomDossier -Path $cheminPartage -FullAccess "AUTORITE NT\Utilisateurs authentifiés" | Out-Null
}
Write-Host "Partage du dossier $nomDossier"

# autorisations NTFS
Write-Host "Configuration des autorisations NTFS du dossier $nomDossier"	

# désactivation de l'héritage
Disable-NTFSAccessInheritance -Path $cheminPartage -RemoveInheritedAccessRules -ErrorAction SilentlyContinue
Add-NTFSAccess -Path $cheminPartage -Account "AUTORITE NT\Système" -AccessRights FullControl 
Add-NTFSAccess -Path $cheminPartage -Account "BUILTIN\Administrateurs" -AccessRights FullControl 

# ajout des groupes NTFS DL
for($i=0; $i -lt $permissions.Length-1; $i+=2){
    $gdl = 'DL_'+$nomDossier+'_'+$permissions[$i]
    if(-not (Get-ADGroup -Filter "Name -eq '$gdl'" -ErrorAction SilentlyContinue)){
        New-ADGroup -name $gdl -GroupCategory Security -GroupScope DomainLocal -Path $emplacementAD
        $null = Get-ADGroup $gdl
        Add-NTFSAccess -Path $cheminPartage -Account $gdl -AccessRights $permissions[$i+1]  
    }
}
#ajout du groupe global des utilisateurs de l'entreprise au groupe DL du partage racine
$nomGG="DL_"+$nomDossier+"_LM"
Add-ADGroupMember -Identity $nomGG -members "G_$nomDossier"

# ============================
# CREATION DES SOUS-DOSSIERS
# ============================
Write-Output ""
Write-Output "CRÉATION ET PARTAGE DES SOUS-DOSSIERS"
Write-Output "========================================"

foreach ($sousDossier in $listeSousDossiers){
        # création du dossier
        Write-Host "Création du dossier $sousDossier"
        New-Item -Path $cheminPartage -Name $sousDossier -ItemType Directory | Out-Null
        
        # autorisations NTFS			
        Write-Host "Configuration des autorisations NTFS du dossier $sousDossier"
        $dossierCible = Join-path $cheminPartage $sousDossier
		
		# désactivation de l'héritage
		Disable-NTFSAccessInheritance -Path $dossierCible -RemoveInheritedAccessRules -ErrorAction SilentlyContinue
		Add-NTFSAccess -Path $dossierCible -Account "AUTORITE NT\Système" -AccessRights FullControl 
		Add-NTFSAccess -Path $dossierCible -Account "BUILTIN\Administrateurs" -AccessRights FullControl 
		
        # ajout des groupes NTFS DL		

        for($i=0; $i -lt $permissions.Length-1; $i+=2){
            $gdl = 'DL_'+$EN+'_'+$sousDossier+'_'+$permissions[$i]
            if(-not (Get-ADGroup -Filter "Name -eq '$gdl'" -ErrorAction SilentlyContinue)){
                New-ADGroup -name $gdl  -GroupCategory Security -GroupScope DomainLocal -Path $emplacementAD
                Add-NTFSAccess -Path $dossierCible -Account $gdl -AccessRights $permissions[$i+1]  
            }
        }        

}
Write-Output ""
Write-Host "Céfini derien"	
Write-Output "========================================"
