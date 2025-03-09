class HeavenGate extends DynamicSMActor;

var vector mStartLocation;
var vector mEndLocation;
var Actor mTarget;
var float mAnimProgression;
var bool mIsOpening;
var bool mIsClosing;
var float mOpenAnimDuration;
var float mCloseAnimDuration;
var float mMaxScale;
var bool mDestroyWhenAttackComplete;

var float mAttackRadius;
var float mAttackHeight;
var bool mAutoAttack;
var bool mAutoCloseGate;
var int mDirectHitCounter;
var int mHitCounter;

var float mLCDelay;
var int mLCCount;

var GGPawn mOwner;

event PostBeginPlay()
{
	super.PostBeginPlay();

	mOwner = GGPawn(Owner);
}

function OpenGateOnTarget(vector startLocation, Actor target)
{
	mTarget = target;
	if(IsZero(startLocation))
	{
		startLocation = class'ApocalypseMutator'.static.GetActorPosition(mTarget) + (vect(0, 0, 1) * mAttackHeight);
	}
	OpenGate(startLocation, class'ApocalypseMutator'.static.GetActorPosition(mTarget) + (vect(0, 0, 1) * mAttackHeight));
}

function OpenGate(vector startLocation, vector endLocation)
{
	mStartLocation = startLocation;
	mEndLocation = endLocation;

	SetLocation(mStartLocation);
	SetScale(0.0001f);
	mAnimProgression=0.f;
	SetHidden(false);
	mIsOpening=true;

	ClearTimer( NameOf(GateClosed) );
	SetTimer( mOpenAnimDuration, false, NameOf(HeavenGateReady) );
}

function HeavenGateReady()
{
	mIsOpening=false;
	SetLocation(mEndLocation);
	SetScale(1.f);

	if(mAutoAttack)
	{
		StartLightCrossRain();
	}

	if(mAutoCloseGate)
	{
		SetTimer( (mLCDelay * mLCCount) - (mLCDelay / 2.f), false, NameOf(CloseGate) );
	}
}

function StartLightCrossRain()
{
	mHitCounter=0;

	SetTimer( mLCDelay , true, NameOf(LightCrossRain) );

	LightCrossRain();
}

function LightCrossRain()
{
	local vector spawnLoc, destLoc, topCenter, bottomCenter;
	local rotator spawnRot;
	//WorldInfo.Game.Broadcast(self, "LightCrossRain/" $ isFirstLightCross);
	topCenter = Location;
	bottomCenter = topCenter + (vect(0, 0, -1) * mAttackHeight);

	spawnLoc = GetRandomPosInCircle(topCenter);
	// If hit counter is zero, always aim for center
	if(mHitCounter == 0)
	{
		destLoc = bottomCenter;
	}
	// Compute spawn location and angle
	else
	{
		destLoc = GetRandomPosInCircle(bottomCenter);
	}
	spawnRot = rotator(Normal(destLoc - spawnLoc));

	Spawn(class'LightCross', mOwner,, spawnLoc, spawnRot,, true);

	mHitCounter++;
	if(mHitCounter >= mDirectHitCounter)
	{
		mHitCounter = 0;
	}
}

function vector GetRandomPosInCircle(vector center)
{
	local float r;
	local rotator angle;

	r = mAttackRadius * sqrt(RandRange(0.f, 1.f));
	angle=rotator(vect(1, 0, 0));
	angle.Yaw = RandRange(0.f, 65536.f);

	return center + (Normal(vector(angle)) * r);
}

function CloseGate()
{
	//WorldInfo.Game.Broadcast(self, "CloseGate");
	mIsClosing=true;
	mAnimProgression=0.f;
	ClearTimer( NameOf(HeavenGateReady) );
	ClearTimer( NameOf(LightCrossRain) );
	SetTimer( mCloseAnimDuration, false, NameOf(GateClosed), self );
}

function GateClosed()
{
	mIsClosing=false;
	SetScale(0.0001f);
	SetHidden(true);

	if(GGAIControllerApocalypse(mOwner.Controller) != none)
	{
		GGAIControllerApocalypse(mOwner.Controller).ApocalypseAttackEnded();
	}

	if(mDestroyWhenAttackComplete)
	{
		SelfDestroy();
	}
}

function DestroyWhenAttackComplete()
{
	mDestroyWhenAttackComplete = true;
	if(bHidden)
	{
		SelfDestroy();
	}
}

function SelfDestroy()
{
	ShutDown();
	Destroy();
}

event Tick( float DeltaTime )
{
	local vector interpLocation, dir;
	local float interpScale;

	super.Tick( DeltaTime );
	// if target, follow target
	if(mTarget != none)
	{
		mEndLocation = class'ApocalypseMutator'.static.GetActorPosition(mTarget) + (vect(0, 0, 1) * mAttackHeight);
	}
	mAnimProgression += DeltaTime;
	if(mIsOpening)
	{
		interpScale = mAnimProgression / mOpenAnimDuration;
		dir = mEndLocation - mStartLocation;
		interpLocation = mStartLocation + (Normal(dir) * VSize(dir) * interpScale);

		SetLocation(interpLocation);
		SetScale(interpScale * mMaxScale);
	}
	else if(mIsClosing)
	{
		interpScale = 1.0f - (mAnimProgression / mOpenAnimDuration);
		SetScale(interpScale * mMaxScale);
	}
	else
	{
		SetLocation(mEndLocation);
	}
}

function SetScale(float newScale)
{
	StaticMeshComponent.SetScale(newScale);
}

DefaultProperties
{
	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'GameInAGame.TexPropPlane'
		Materials[0]=Material'MMO_Effects.Materials.Portal_Mat'
		Rotation=(Pitch=16384, Yaw=0, Roll=0)
		bNotifyRigidBodyCollision=false
		CollideActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
	End Object

	bNoDelete=false
	bStatic=false
	bBlockActors=false
	bCollideActors=false
	Physics=PHYS_None
	CollisionType=COLLIDE_NoCollision

	mOpenAnimDuration=0.25f
	mCloseAnimDuration=0.25f

	mMaxScale=1.f
	mAttackRadius=100.f
	mAttackHeight=200.f

	mAutoAttack=true
	mAutoCloseGate=true

	mLCDelay=0.1f
	mLCCount=7
	mDirectHitCounter=6
}