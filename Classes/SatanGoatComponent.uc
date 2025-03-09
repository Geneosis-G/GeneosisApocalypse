class SatanGoatComponent extends ApocalypseGoatComponent;

var SkeletalMesh mRippedGoatMesh;
var Material mSatanMaterial;

var DemonLaser mDemonLaser;

function DetachFromPlayer()
{
	if(mDemonLaser != none)
	{
		mDemonLaser.SelfDestroy();
		mDemonLaser = none;
	}
	super.DetachFromPlayer();
}

function SetGoatSkin()
{
	local int i;

	if(gMe.mesh.PhysicsAsset == class'GGGoat'.default.mesh.PhysicsAsset)
	{
		gMe.mesh.SetSkeletalMesh( mRippedGoatMesh );
		for(i=0 ; i<gMe.mesh.GetNumElements() ; i++)
		{
			gMe.mesh.SetMaterial( i, mSatanMaterial );
		}
	}
}

function LinearColor GetCrosshairColor()
{
	return MakeLinearColor( 255.f/255.f, 0.f/255.f, 0.f/255.f, 1.0f );
}

simulated event TickMutatorComponent( float delta )
{
	super.TickMutatorComponent(delta);

	if(mDemonLaser == none || mDemonLaser.bPendingDelete)
	{
		mDemonLaser = gMe.Spawn(class'DemonLaser', gMe);
	}
}

function StartShooting()
{
	local vector startLocation, endLocation;
	local rotator r;

	super.StartShooting();

	gMe.mesh.GetSocketWorldLocationAndRotation(mBeamSocket, startLocation, r);
	endLocation = mCrosshairActor.Location;
	mDemonLaser.ShootLaser(startLocation, endLocation);
	myMut.SetTimer( mDemonLaser.mLaserDuration, false, NameOf(StopShooting), self );
}

DefaultProperties
{
	mCircleClass = class'SatanCircle'
	mRippedGoatMesh = SkeletalMesh'goat.mesh.GoatRipped'
	mSatanMaterial = Material'goat.Materials.Goat_Mat_06'
}