# CA MARCHE ON Y TOUCHE PLUS !!!!!!!!!!
Import-Module ActiveDirectory -ErrorAction Stop

# ============================
# VARIABLES
# ============================

$chemin = "ou=04_Entreprises clientes,ou=ETP Chasseneuil,dc=TiersLieux86,dc=fr"
$listeOU = @('00_Ordinateurs','01_Utilisateurs','02_Groupes')

$entreprise = read-host("Nom de l'entreprise ")
$EN = read-host("Diminutif de l'entreprise ")

$listeServices = @()
$saisie = read-host("Services de l'entreprise et leurs diminutifs séparés par une virgule ")
$listeServices = $saisie -split ',' | ForEach-Object {$_.Trim()}

$listeStatuts = @()
$saisie = read-host("Statuts du personnel séparés par une virgule ")
$listeStatuts = $saisie -split ',' | ForEach-Object {$_.Trim()}

$emplacementAD = "ou=Groupes globaux,ou=02_Groupes,ou=$entreprise,ou=04_Entreprises clientes,ou=ETP Chasseneuil,dc=TiersLieux86,dc=fr"

# ============================
# CRÉATION DES OU
# ============================
Write-Output ""
Write-Output "CRÉATION DE L'OU DE L'ENTREPRISE $entreprise"
Write-Output "========================================"

# création de l'OU principale de l'entreprise
New-ADOrganizationalUnit -name $entreprise -Path $chemin -ProtectedFromAccidentalDeletion $false
Write-Output "OU $entreprise créée"
Write-Output ''

# création des OU
Write-Output "CRÉATON DES SOUS-OU DE $entreprise"
Write-Output "========================================"

foreach ($OU in $listeOU)
{

		Write-Output "Création de l'OU $OU"
		New-ADOrganizationalUnit -name $OU -Path "ou=$entreprise,$chemin" -ProtectedFromAccidentalDeletion $false
		
		#création des sous-OU pour l'OU Utilisateurs
		if ($OU -eq "01_Utilisateurs")
		{
            for($i=0;$i -lt $listeServices.Length-1;$i+=2){
                	Write-Output "Création de l'OU $listeServices[$i]"
                	New-ADOrganizationalUnit -name $listeServices[$i] -Path "ou=$OU,ou=$entreprise,$chemin" -ProtectedFromAccidentalDeletion $false
            }
			# foreach ($sousOU in $listeServices)
			# {
			# 	Write-Output "Création de l'OU $sousOU"
			# 	New-ADOrganizationalUnit -name $sousOU -Path "ou=$OU,ou=$entreprise,$chemin" -ProtectedFromAccidentalDeletion $false
			# }	
		}
		#création des sous-OU pour l'OU Groupes
		if ($OU -eq "02_Groupes")
		{
			foreach ($sousOU in @('Groupes globaux','Groupes domaine local'))
			{
				Write-Output "Création de l'OU $sousOU"
				New-ADOrganizationalUnit -name $sousOU -Path "ou=$OU,ou=$entreprise,$chemin" -ProtectedFromAccidentalDeletion $false
			}	
		}		
	}
    
# ============================
# CRÉATION DES GROUPES GLOBAUX
# ============================

Write-Output ""
Write-Output "CRÉATION DES GROUPES GLOBAUX"
Write-Output "========================================"

#création du groupe global de l'entreprise
$ggEntreprise = 'G_'+($entreprise).toUpper()
Write-Output "Création du groupe $ggEntreprise"
New-ADGroup -Name $ggEntreprise -GroupCategory Security -GroupScope Global -Path $emplacementAD


for($i=0; $i -lt $listeServices.Length-1; $i+=2){
	
	#création du groupe global de service
	$ggService = 'G_'+$EN+'_'+$listeServices[$i]
	Write-Output "Création du groupe $ggService"
	New-ADGroup -Name $ggService -GroupCategory Security -GroupScope Global -Path $emplacementAD

	#ajout des groupes globaux de services au groupe global de l'entreprise
	Write-Output "Ajout du groupe $ggService au groupe $ggEntreprise"
	Add-ADGroupMember -Identity $ggEntreprise -members $ggService

	
	#création des groupes globaux de statuts
	foreach ($statut in $listeStatuts){
		$ggStatut = 'G_'+$EN+'_'+$listeServices[$i+1]+'_'+$statut	
		Write-Output "Création du groupe $ggStatut"
		New-ADGroup -Name $ggStatut -GroupCategory Security -GroupScope Global -Path $emplacementAD
		
		#ajout des groupes globaux de statuts au groupe global de service
		Write-Output "Ajout du groupe $ggStatut au groupe $ggService"
		Add-ADGroupMember -Identity $ggService -members $ggStatut
	}

}

Write-Output ""
Write-Output "Céfini derien"
Write-Output "========================================"