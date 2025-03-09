class GGNpcDemonGoat extends GGNpcApocalypseGoat
	placeable;

var SkeletalMeshComponent mLeftHornMesh;
var SkeletalMeshComponent mRightHornMesh;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	mRightHornMesh.SetLightEnvironment( mesh.LightEnvironment );
	mesh.AttachComponentToSocket( mRightHornMesh, 'Horn_01' );
	mLeftHornMesh.SetLightEnvironment( mesh.LightEnvironment );
	mesh.AttachComponentToSocket( mLeftHornMesh, 'Horn_02' );
}

function string GetActorName()
{
	return (Controller == none ? "Dead ":"") $ "Demon Goat";
}

//Demons cannot burn
function bool ShouldBeOnFire( Actor fireCauser, class< GGDamageType > damageType );
function SetOnFire( optional bool turnOnFire );
function SetOnFireByTemplate( ParticleSystem fireTemplate, SoundCue burnSound, optional bool turnOnFire );

//Demons are immune to fire damages
event TakeDamage( int damage, Controller instigatedBy, vector hitLocation, vector momentum, class< DamageType > damageType, optional TraceHitInfo hitInfo, optional Actor damageCauser )
{
	if(class<GGDamageType>(damageType) != none && class<GGDamageType>(damageType).default.mSetOnFire && IsImmune())
		return;

	super.TakeDamage(damage, instigatedBy, hitLocation, momentum, damageType, hitInfo, damageCauser);
}

DefaultProperties
{
	Begin Object name=WPawnSkeletalMeshComponent
		Materials(0)=Material'goat.Materials.Goat_Mat_06'
	End Object

	Begin Object class=SkeletalMeshComponent Name=leftHornMesh
		SkeletalMesh=SkeletalMesh'Ritual.mesh.GoatHorns'
	End Object
	mLeftHornMesh=leftHornMesh

	Begin Object class=SkeletalMeshComponent Name=rightHornMesh
		SkeletalMesh=SkeletalMesh'Ritual.mesh.GoatHorns'
	End Object
	mRightHornMesh=rightHornMesh
}