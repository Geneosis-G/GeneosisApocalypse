//-----------------------------------------------------------
//
//-----------------------------------------------------------
class VoidAntimatter extends GGBlackHoleProjectileActor
		placeable;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	StaticMeshComponent.StaticMesh.BodySetup.MassScale = 0.f;
}

function CheckTrace( float deltaTime )
{
	local vector hitLocation, hitNormal;
	local TraceHitInfo hitInfo;
	local float traceDist;
	local actor hitActor;

	traceDist = mBlackHoleSpawnOffset.Z;
	hitActor = Trace( hitLocation, hitNormal, Location - traceDist * vect( 0.0f, 0.0f, 1.0f ), Location, false, , hitInfo );

	if( hitActor != none )
	{
		SpawnBlackHole();
	}
}

DefaultProperties
{
	mBlackHoleClass=class'VoidHole'
	mBlackHoleSpawnOffset=( X=0, Y=0, Z=50 )
}