Import-Module ActiveDirectory -ErrorAction Stop
Import-Module NTFSSecurity -ErrorAction Stop

# ============================
# VARIABLES
# ============================

$chemin = "D:\"
$emplacementAD = "ou=Groupes domaine local,ou=03_Groupes,ou=ETP Chasseneuil,dc=TiersLieux86,dc=fr"
$permissions = @('L','ReadAndExecute','LM','Modify','CT','FullControl')
$listeSousDossiers = @('ADMINISTRATION','ADHERENTS','ECHANGE')

# ============================
# CREATION DU DOSSIER PRINCIPAL
# ============================
Write-Output ""
Write-Output "CRÉATION ET PARTAGE DES DOSSIERS PRINCIPAUX"
Write-Output "========================================"

foreach($partage in @('TIERSLIEUX86','FICHIERS_PERSONNELS')){
    New-Item -Path $chemin -Name $partage -ItemType Directory | Out-Null
    Write-Host "Création du dossier $partage"   
}

foreach($partage in @('TIERSLIEUX86','FICHIERS_PERSONNELS')){
    $cheminPartage = "D:\"+$partage
    if (-not (Get-SmbShare -Name $partage -ErrorAction SilentlyContinue)){
        New-SmbShare -Name $partage -Path $cheminPartage -FullAccess "AUTORITE NT\Utilisateurs authentifiés" | Out-Null
    }
    Write-Host "Partage du dossier $partage"
    # désactivation de l'héritage
    Disable-NTFSAccessInheritance -Path $cheminPartage -RemoveInheritedAccessRules -ErrorAction SilentlyContinue
    Add-NTFSAccess -Path $cheminPartage -Account "AUTORITE NT\Système" -AccessRights FullControl 
    Add-NTFSAccess -Path $cheminPartage -Account "BUILTIN\Administrateurs" -AccessRights FullControl 
}


# ajout des groupes NTFS DL

for($i=0; $i -lt $permissions.Length-1; $i+=2){
    $gdl = 'DL_TIERSLIEUX86_'+$permissions[$i]
    if (-not (Get-ADGroup -Filter "Name -eq '$gdl'" -ErrorAction SilentlyContinue)){
        New-ADGroup -name $gdl  -GroupCategory Security -GroupScope DomainLocal -Path $emplacementAD
        $null = Get-ADGroup $gdl
        Add-NTFSAccess -Path 'D:\TIERSLIEUX86' -Account $gdl -AccessRights $permissions[$i+1] -ErrorAction SilentlyContinue
    }
}
Write-Host "Configuration des autorisations NTFS du dossier TIERSLIEUX86"	

# ============================
# CREATION DES SOUS-DOSSIERS
# ============================
Write-Output ""
Write-Output "CRÉATION ET PARTAGE DES SOUS-DOSSIERS"
Write-Output "========================================"

$cheminPartage = 'D:\TIERSLIEUX86'
foreach ($sousDossier in $listeSousDossiers){
        # création du dossier
        Write-Host "Création du dossier $sousDossier"
        New-Item -Path $cheminPartage -Name $sousDossier -ItemType Directory | Out-Null
        
        # autorisations NTFS			
        Write-Host "Configuration des autorisations NTFS du dossier $sousDossier"
        $dossierCible = Join-path $cheminPartage $sousDossier
		
		# désactivation de l'héritage
		Disable-NTFSAccessInheritance -Path $dossierCible -RemoveInheritedAccessRules
		Add-NTFSAccess -Path $dossierCible -Account "AUTORITE NT\Système" -AccessRights FullControl 
		Add-NTFSAccess -Path $dossierCible -Account "BUILTIN\Administrateurs" -AccessRights FullControl 
		
        # ajout des groupes NTFS DL		

        for($i=0; $i -lt $permissions.Length-1; $i+=2){
            $gdl = 'DL_TL_'+$sousDossier+'_'+$permissions[$i]
            New-ADGroup -name $gdl  -GroupCategory Security -GroupScope DomainLocal -Path $emplacementAD
            Add-NTFSAccess -Path $dossierCible -Account $gdl -AccessRights $permissions[$i+1]  
        }        

}
Write-Output ""
Write-Host "Céfini derien"	
Write-Output "========================================"
