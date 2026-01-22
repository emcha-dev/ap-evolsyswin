Import-Module ActiveDirectory -ErrorAction Stop

# ============================
# VARIABLES
# ============================

$domaine = "dc=TiersLieux86,dc=fr"
$ETP = "ETP Chasseneuil"
$chemin = "ou=$ETP,$domaine"
$listeServices = @('Adhérents','Adh','Administration','Adm')
$listeStatuts = @('Employés','Responsables')
$listeOU = @('00_Ordinateurs','01_Administration','02_Adhérents','03_Groupes','04_Entreprises clientes')
$listeJE = @('Esporting','3DPrint86')
$listeJESousOU = @('00_Ordinateurs','01_Utilisateurs','02_Groupes')

# ============================
# CRÉATION DES OU
# ============================

# création de l'OU principale de l'ETP
Write-Output ''
Write-Output "CRÉATON DE L'OU DE l'ETP CHASSENEUIL"
Write-Output "========================================"
New-ADOrganizationalUnit -name $ETP -Path $domaine -ProtectedFromAccidentalDeletion $false
Write-Output 'OU "ETP Chasseneuil" créée'
Write-Output ''

# création des sous-OU
Write-Output "CRÉATON DES OU PRINCIPALES"
Write-Output "========================================"

foreach ($OU in $listeOU)
{
		# ============================
		# OU TIERSLIEUX
		# ============================
		Write-Output "Création de l'OU $OU"
		New-ADOrganizationalUnit -name $OU -Path $chemin -ProtectedFromAccidentalDeletion $false
		
		#création des sous-OU pour l'OU Groupes
		if ($OU -eq "03_Groupes")
		{
			foreach ($sousOU in @('Groupes globaux','Groupes domaine local'))
			{
				Write-Output "Création de l'OU $sousOU"
				New-ADOrganizationalUnit -name $sousOU -Path "ou=$OU,$chemin" -ProtectedFromAccidentalDeletion $false
			}	
		}
		
		# ============================
		# OU ENTREPRISES CLIENTES
		# ============================
		if ($OU -eq "04_Entreprises clientes")
		{
			foreach ($JE in $listeJE)
			{
				Write-Output "Création de l'OU $JE"
				New-ADOrganizationalUnit -name $JE -Path "ou=$OU,$chemin" -ProtectedFromAccidentalDeletion $false
				
				#création des sous-OU pour chaque entreprise
				foreach ($sousOU in $listeJESousOU)
				{
					Write-Output "Création de l'OU $sousOU"
					New-ADOrganizationalUnit -name $sousOU -Path "ou=$JE,ou=$OU,$chemin" -ProtectedFromAccidentalDeletion $false

					#création des sous-OU pour l'OU Groupes
					if ($sousOU -eq "02_Groupes")
					{
						foreach ($sousOU2 in @('Groupes globaux','Groupes domaine local'))
						{
							Write-Output "Création de l'OU $sousOU2"
							New-ADOrganizationalUnit -name $sousOU2 -Path "ou=$sousOU,ou=$JE,ou=$OU,$chemin" -ProtectedFromAccidentalDeletion $false
						}	
					}
					
				}
			}
		}			
	}

# ============================
# CRÉATION DES GROUPES GLOBAUX
# ============================

Write-Output ""
Write-Output "CRÉATION DES GROUPES GLOBAUX"
Write-Output "========================================"

$emplacement = 'ou=Groupes globaux,ou=03_Groupes,'+$chemin

#création du groupe global de TiersLieux
$ggTl = 'G_TIERSLIEUX86'
New-ADGroup -Name $ggTl -GroupCategory Security -GroupScope Global -Path $emplacement
Write-Output "Création du groupe $ggTl"


for ($i=0; $i -lt $listeServices.Count-1; $i+=2){
	
	#création du groupe global de service
	$ggService = 'G_TL_'+$listeServices[$i]
	New-ADGroup -Name $ggService -GroupCategory Security -GroupScope Global -Path $emplacement
	Write-Output "Création du groupe $ggService"
	
	#ajout des groupes globaux de services au groupe global de TiersLieux
	Add-ADGroupMember -Identity $ggTl -members $ggService
	Write-Output "Ajout du groupe $ggService au groupe $ggTl"
	
	#création des groupes globaux de statuts
	foreach ($statut in $listeStatuts){
		$ggStatut = 'G_TL_'+$listeServices[$i+1]+'_'+$statut	
		New-ADGroup -Name $ggStatut -GroupCategory Security -GroupScope Global -Path $emplacement
		Write-Output "Création du groupe $ggStatut"
		
		#ajout des groupes globaux de statuts au groupe global de service
		Add-ADGroupMember -Identity $ggService -members $ggStatut
		Write-Output "Ajout du groupe $ggStatut au groupe $ggService"
	}
	
}

Write-Output ""
Write-Output "Création terminée"
Write-Output "Céfini derien"
Write-Output "========================================"