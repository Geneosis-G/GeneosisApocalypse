class CircleHalo extends Actor;

var RitualCircle mRitualCircle;

var ParticleSystemComponent mCircleHalo;
var bool mIsAttached;
var Actor myBase;

simulated event PostBeginPlay ()
{
	Super.PostBeginPlay();

	mRitualCircle = RitualCircle(Owner);

	SetPhysics(PHYS_None);
	CollisionComponent=none;
	mCircleHalo = WorldInfo.MyEmitterPool.SpawnEmitter( mRitualCircle.mCircleHaloTemplate, Location, Rotation, self );
	mCircleHalo.ActivateSystem();
}

function AttachHalo(Actor target)
{
	myBase=target;
	SetLocation(class'ApocalypseMutator'.static.GetActorPosition(target));
	SetBase(myBase);
	mIsAttached=true;
}

function DetachHalo()
{
	if(!mIsAttached)
		return;

	SetBase(none);
	mCircleHalo.DeactivateSystem();
	mIsAttached=false;
}

event Tick( float deltaTime )
{
    super.Tick( deltaTime );

	if(mIsAttached && (myBase == none || myBase.bPendingDelete))
	{
		DetachHalo();
	}
}

event Destroyed()
{
	DetachHalo();

	super.Destroyed();
}

DefaultProperties
{
	bNoDelete=false
	bStatic=false
	bIgnoreBaseRotation=true
}