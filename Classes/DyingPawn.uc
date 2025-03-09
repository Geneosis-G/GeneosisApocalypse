class DyingPawn extends Actor;

var GGPawn mDeadPawn;
var float mRagdollInterval;;
var int mMaxAttempts;
var int mAttempts;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	mDeadPawn=GGPawn(Owner);
	SetTimer(mRagdollInterval, true, NameOf(ForceRagdoll));
}

function ForceRagdoll()
{
 	if(mDeadPawn == none
	|| mDeadPawn.bPendingDelete
	|| mDeadPawn.mIsRagdoll
	|| mDeadPawn.Controller != none
	|| mAttempts >= mMaxAttempts)
	{
		SelfDestroy();
	}
	else
	{
		//WorldInfo.Game.Broadcast(self, "Non ragdoll dead NPC found " $ mDeadPawn);
		mDeadPawn.SetRagdoll(true);
	}
	mAttempts++;
}

function SelfDestroy()
{
	ClearTimer(NameOf(ForceRagdoll));
	ShutDown();
	Destroy();
}

DefaultProperties
{
	mRagdollInterval=1.f
	mMaxAttempts=10

	bBlockActors=false
	bCollideActors=true
	Physics=PHYS_None
	CollisionType=COLLIDE_TouchAll
	bIgnoreBaseRotation=true
}