Import-Module ActiveDirectory -ErrorAction Stop

# ============================
# VARIABLES
# ============================

$listeServices = @('Administration','Adm','Adhérents','Adh')
$listeStatuts = @('Employés','Responsables')

$chemin = "ou=ETP CHasseneuil,dc=TiersLieux86,dc=fr"
$fichiersPersonnels = "\\srv-intra\FICHIERS_PERSONNELS"
$lettreDossierPerso = "Y:"
$fichierCSV = "./TL_utilisateurs.csv"
$data = Import-CSV -Path $fichierCSV -Delimiter "," -Encoding UTF8

# ============================
# CREATION DES COMPTES UTILISATEURS
# ============================

foreach($user in $data)
{
	$nom = $user.nom
	$prenom = $user.prenom
	$login = $user.login
	$mdp = $user.mdp
	$service = $user.service
	$statut = $user.statut

	if (Get-ADUser -Filter {SamAccountName -eq $login})
	{
		Write-Warning "L'identifiant $login existe déjà dans l'AD"
	}
	else
	{
		# ============================
		# 1. CREATION DE L'UTILISATEUR
		# ============================
        if($service -eq 'Administration'){
            $emplacement = "ou=01_Administration,"+$chemin
        }else{
            $emplacement = "ou=02_Adhérents,"+$chemin
        }

        
        Write-Output "Création de l'utilisateur : $login ($prenom $nom)"

		New-ADUser `
			-Name "$prenom $nom" `
			-DisplayName $login `
			-GivenName $prenom `
			-Surname $nom `
			-SamAccountName $login `
			-UserPrincipalName "$login@TiersLieux86.fr" `
			-Path $emplacement `
			-AccountPassword(ConvertTo-SecureString $mdp -AsPlainText -Force) `
			-ChangePasswordAtLogon $false `
			-Enabled $true
		
		# ============================
		# 2. AJOUT DE L'UTILISATEUR AUX GROUPES ADEQUATS
		# ============================
        
        for($i=0;$i-lt $listeServices.Length;$i++){
            if ($user.service -eq $listeServices[$i]){
                foreach ($statut in $listeStatuts){
                    if ($user.statut -eq $statut){    
                        $index=$i+1
                        $nomGroupe = 'G_TL_'+$listeServices[$index]+'_'+$statut    
                        Write-Output "Ajout de l'utilisateur $login aux groupe $nomGroupe"          
                        Add-ADGroupMember -Identity $nomGroupe -members $login
                    }
                }
            }
        }

		# ============================
		# 3. CREATION DU DOSSIER PERSONNEL DE L'UTILISATEUR
		# ============================
		$dossierUtilisateur = Join-Path $fichiersPersonnels $login

		if (!(Test-Path $dossierUtilisateur)) {
			New-Item -ItemType Directory -Path $dossierUtilisateur | Out-Null
		}
		
		Write-Output "Création du dossier personnel de l'utilisateur $login"
		
		# Attribution des permissions NTFS à l'utilisateur
		$Acl = Get-Acl $dossierUtilisateur
		$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("$login","FullControl","ContainerInherit,ObjectInherit","None","Allow")
		$Acl.AddAccessRule($Ar)
		Set-Acl -Path $dossierUtilisateur -AclObject $Acl

		# Configuration du dossier personnel utilisateur dans Active Directory
		Set-ADUser $login -HomeDrive $lettreDossierPerso -HomeDirectory $dossierUtilisateur
		
		Write-Host "Utilisateur $login créé avec un dossier personnel mappé sur le lecteur $lettreDossierPerso"
        Write-Host "--------------------------------------------------"          

	}
}