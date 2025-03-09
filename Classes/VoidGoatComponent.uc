class VoidGoatComponent extends ApocalypseGoatComponent;

var Material mVoidMaterial;
var SoundCue mThrowSound;

var float mThrowVelocity;
var float mBlackHoleClearDelay;

var array<VoidCircle> mPortals;

function SetGoatSkin()
{
	local int i;

	for(i=0 ; i<gMe.mesh.GetNumElements() ; i++)
	{
		gMe.mesh.SetMaterial( i, mVoidMaterial );
	}
}

function LinearColor GetCrosshairColor()
{
	return MakeLinearColor( 100.f/255.f, 100.f/255.f, 100.f/255.f, 1.0f );
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PlayerController( gMe.Controller ).PlayerInput );

	super.KeyState(newKey, keyState, PCOwner);

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ))
		{
			if(mUseRightClick)
			{
				myMut.SetTimer(mBlackHoleClearDelay, true, NameOf(ClearClosestBlackHole), self);
			}
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ))
		{
			myMut.ClearTimer(NameOf(ClearClosestBlackHole), self);
		}
	}
}

function ClearClosestBlackHole()
{
	local GGBlackHoleActor tmpBlackHole, foundBlackHole;
	local float dist, minDist;

	foreach myMut.AllActors(class'GGBlackHoleActor', tmpBlackHole)
	{
		dist = VSize(class'ApocalypseMutator'.static.GetPawnPosition(gMe) - tmpBlackHole.Location);
		if(foundBlackHole == none || dist < minDist)
		{
			minDist = dist;
			foundBlackHole = tmpBlackHole;
		}
	}

	if(foundBlackHole != none)
	{
		foundBlackHole.CollapseHole();
	}
}

function StartShooting()
{
	local GGBlackHoleProjectileActor blackHoleProj;
	local vector spawnLoc, spawnDir;
	local rotator r;
	local float goatSpeed;

	super.StartShooting();

	goatSpeed = VSize( gMe.Velocity );
	gMe.mesh.GetSocketWorldLocationAndRotation(mBeamSocket, spawnLoc, r);
	spawnDir = Normal(mCrosshairActor.Location - spawnLoc);

	blackHoleProj = gMe.Spawn( class'VoidAntimatter', gMe, , spawnLoc);
	blackHoleProj.StaticMeshComponent.BodyInstance.CustomGravityFactor = 0.f;
	blackHoleProj.ApplyImpulse( spawnDir , ( mThrowVelocity + goatSpeed ), blackHoleProj.Location );
	mGoat.PlaySound( mThrowSound );

	StopShooting();
}

function RitualCircle SpawnRitualCircle()
{
	local VoidCircle newCircle, oldCircle;

	newCircle = VoidCircle(super.SpawnRitualCircle());
	if(newCircle != none)
	{
		// if already 2 portals, remove the older one
		if(mPortals.Length >= 2)
		{
			oldCircle = mPortals[0];
			mPortals.RemoveItem(oldCircle);
		}
		// if exactly one portal remaining, link it with new portal
		if(mPortals.Length == 1)
		{
			newCircle.LinkPortals(mPortals[0]);
		}
		// Actually delete portal after relinking the remaining one
		if(oldCircle != none)
		{
			oldCircle.SelfDestroy();
		}
		// Add new portal to table
		mPortals.AddItem(newCircle);
	}

	return newCircle;
}

DefaultProperties
{
	mCircleClass = class'VoidCircle'
	mVoidMaterial = Material'Apocalypse.Space_Cube_Mat_01'
	mThrowSound=SoundCue'Space_ProfessorGoat_Sounds.blackholeProjectile.ProfessorGoat_BlackHoleProjectile_Throw_Cue'
	mThrowVelocity = 650.0f;
	mBlackHoleClearDelay=3.f
}