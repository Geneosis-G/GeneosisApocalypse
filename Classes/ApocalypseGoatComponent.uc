class ApocalypseGoatComponent extends GGMutatorComponent abstract;

var GGGoat gMe;
var GGMutator myMut;

var GGCrosshairActor mCrosshairActor;
var vector mCrosshairHitNormal;
var Actor mCrosshairHitActor;

var bool mUseRightClick;
var bool mIsShooting;
// define in children
var class<RitualCircle> mCircleClass;

var name mBeamSocket;
var float mRange;
var bool mIsHovering;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer( goat, owningMutator );

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		gMe.MaxMultiJump+=1000;

		SetGoatSkin();
	}
}

function DetachFromPlayer()
{
	mCrosshairActor.DestroyCrosshair();
	super.DetachFromPlayer();
}
// Override in children
function SetGoatSkin();

simulated event TickMutatorComponent( float delta )
{
	super.TickMutatorComponent(delta);

	mUseRightClick = GGPlayerControllerGame(gMe.Controller) != none && GGPlayerControllerGame(gMe.Controller).mFreeLook;
	//Update crosshair
	if(mCrosshairActor == none || mCrosshairActor.bPendingDelete)
	{
		mCrosshairActor = gMe.Spawn(class'GGCrosshairActor');
		mCrosshairActor.SetColor(GetCrosshairColor());
	}
	UpdateCrosshair(GetShootLocation());
	//hover ability
	if(gMe.Physics == PHYS_Falling && mIsHovering && gMe.Velocity.Z<0)
	{
		gMe.Velocity.Z=0;
	}
}
// Override in children
function LinearColor GetCrosshairColor();

function UpdateCrosshair(vector aimLocation)
{
	local vector			StartTrace, EndTrace, AdjustedAim, camLocation;
	local rotator 			camRotation;
	local Array<ImpactInfo>	ImpactList;
	local ImpactInfo 		RealImpact;
	local float 			Radius;

	if(gMe == none || GGPlayerControllerGame( gMe.Controller ) == none || mCrosshairActor == none)
		return;

	StartTrace = aimLocation;
	GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
	camRotation.Pitch+=1800.f;
	AdjustedAim = vector(camRotation);

	Radius = mCrosshairActor.SkeletalMeshComponent.SkeletalMesh.Bounds.SphereRadius;
	EndTrace = StartTrace + AdjustedAim * (mRange - Radius);

	RealImpact = CalcWeaponFire(StartTrace, EndTrace, ImpactList);

	mCrosshairHitActor = RealImpact.HitActor;
	mCrosshairHitNormal = RealImpact.HitNormal;
	mCrosshairActor.UpdateCrosshair(RealImpact.hitLocation, -AdjustedAim);
	mCrosshairActor.SetHidden(!mUseRightClick);
}

simulated function ImpactInfo CalcWeaponFire(vector StartTrace, vector EndTrace, optional out array<ImpactInfo> ImpactList)
{
	local vector			HitLocation, HitNormal;
	local Actor				HitActor;
	local TraceHitInfo		HitInfo;
	local ImpactInfo		CurrentImpact;

	HitActor = CustomTrace(HitLocation, HitNormal, EndTrace, StartTrace, HitInfo);

	if( HitActor == None )
	{
		HitLocation	= EndTrace;
	}

	CurrentImpact.HitActor		= HitActor;
	CurrentImpact.HitLocation	= HitLocation;
	CurrentImpact.HitNormal		= HitNormal;
	CurrentImpact.RayDir		= Normal(EndTrace-StartTrace);
	CurrentImpact.StartTrace	= StartTrace;
	CurrentImpact.HitInfo		= HitInfo;

	ImpactList[ImpactList.Length] = CurrentImpact;

	return CurrentImpact;
}

function Actor CustomTrace(out vector HitLocation, out vector HitNormal, vector EndTrace, vector StartTrace, out TraceHitInfo HitInfo)
{
	local Actor hitActor, retActor;

	foreach gMe.TraceActors(class'Actor', hitActor, HitLocation, HitNormal, EndTrace, StartTrace, ,HitInfo)
    {
		if(hitActor != gMe
		&& hitActor.Owner != gMe
		&& hitActor.Base != gMe
		&& hitActor != gMe.mGrabbedItem
		&& !hitActor.bHidden)
		{
			retActor=hitActor;
			break;
		}
    }

    return retActor;
}

function vector GetShootLocation()
{
	return gMe.Location + GetShootOffset();
}

function vector GetShootOffset()
{
	return Normal(vector(gMe.Rotation)) * gMe.GetCollisionRadius() * 1.5f;
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PlayerController( gMe.Controller ).PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed("LeftMouseButton", string( newKey )) || newKey == 'XboxTypeS_RightTrigger')
		{
			if(mUseRightClick && !mIsShooting)
			{
				StartShooting();
			}
		}
		if(localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ))
		{
			if(mUseRightClick)
			{
				SpawnRitualCircle();
			}
		}
		if(localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ))
		{
			mIsHovering=true;
		}
		if(localInput.IsKeyIsPressed("GBA_ToggleRagdoll", string( newKey )))
		{
			//WorldInfo.Game.Broadcast(self, "ragdoll key");
			if(gMe.mIsRagdoll && gMe.mIsInAir)
			{
				StandUpInAir();
			}
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ))
		{
			mIsHovering=false;
		}
	}
}

function StandUpInAir()
{
	local rotator NewRotation;
	local bool tooSoon;

	tooSoon = myMut.WorldInfo.TimeSeconds - gMe.mTimeForRagdoll < gMe.mMinRagdollTime;
	if( tooSoon )
	{
		return;
	}

	gMe.mWasRagdollStartedByPlayer = false;

	// Make sure the rotation when we stand up is same as the rotation of the ragdoll
	NewRotation = gMe.Rotation;
	NewRotation.Yaw = rotator( gMe.mesh.GetBoneAxis( gMe.mStandUpBoneName, AXIS_X ) ).Yaw;
	gMe.SetRotation( NewRotation );

	if(gMe.mIsRagdoll && !gMe.mTerminatingRagdoll && gMe.mIsInAir)
	{
		gMe.CollisionComponent = gMe.mesh;
		gMe.SetPhysics( PHYS_Falling );
		gMe.SetRagdoll( false );
	}
}
// Override in children
function StartShooting()
{
	mIsShooting = true;
}
// Override in children
function StopShooting()
{
	mIsShooting = false;
}

function RitualCircle SpawnRitualCircle()
{
	local vector spawnLoc;
	local RitualCircle newCircle;

	spawnLoc = CalcRingLocation();
	if(!IsZero(spawnLoc) && ! class'RitualCircle'.static.IsCollidingWithCircle(myMut, spawnLoc))
	{
		newCircle = myMut.Spawn(mCircleClass,,, spawnLoc);
	}

	return newCircle;
}

function vector CalcRingLocation()
{
	local vector pos, dest;
	local vector offset;
	local vector traceStart, traceEnd, hitLocation, hitNormal;
	local Actor hitActor;

	hitLocation = mCrosshairActor.Location;
	hitNormal = mCrosshairHitNormal;
	hitActor = mCrosshairHitActor;

	offset=hitNormal;
	offset.Z=0;
	if(GGPawn(hitActor) != none)// if hit pawn, center circle on it
	{
		pos = hitLocation + Normal(offset);
	}
	else // else move away from obstacles
	{
		pos = hitLocation + Normal(offset)*(class'RitualCircle'.default.mRadius + 1.f);
	}
	// By default center the circle on the cursor location
	dest = hitLocation;
	// if hitting a wall or ceiling, then trace down to find floor
	if(hitActor == none || hitNormal.Z < 0.5f)
	{
		traceStart = pos;
		traceEnd = pos;
		traceEnd += vect(0, 0, 1)*-100000.f;

		hitActor = gMe.Trace( hitLocation, hitNormal, traceEnd, traceStart);
		if(hitActor != none)
		{
			dest=hitLocation;
		}
	}

	return dest;
}

DefaultProperties
{
	mBeamSocket="grabSocket"
	mRange=10000.f
}