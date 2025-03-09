class RitualCircle extends DynamicSMActor abstract;

var float mRadius;
var float mSummoningRadius;
var float mCircleTimeout;
var float mDissapearTime;
var float mMinDistanceBetweenCircles;

var int mSummonersNeededForRitual;
var int mLastSummonersCount;
var float mRefreshTime;
var float mTotalTime;
var float mReadyTime;
var ParticleSystem mCircleHaloTemplate;
var SoundCue mCompletionSound;
var ParticleSystem mCompletionEffect;

var array<GGNpc> mNpcsInCircle;
var array<CircleHalo> mCircleHalos;
var class<GGNpcApocalypseGoat> mSummonerClass;
var array<GGNpcApocalypseGoat> mRequiredSummoners;

var bool mRitualReady;
var bool mRitualDone;
var bool mCancelRitualIfNoTargetInCircle;

event PostBeginPlay()
{
	local vector v;
	local float borderScale;

	super.PostBeginPlay();

	borderScale = mRadius / 10000.f * 14.5f;
	v.X = borderScale;
	v.Y = borderScale;
	v.Z = borderScale;
	SetDrawScale3D(v);

	if(mCircleTimeout > 0)
	{
		SetTimer(mCircleTimeout, false, NameOf(SelfDestroy));
	}
	if(mReadyTime > 0)
	{
		SetTimer(mReadyTime, false, NameOf(RitualReady));
	}
}

function RitualReady()
{
	mRitualReady = true;
}

event Tick( float DeltaTime )
{
	local array<GGNpc> newNpcsInCircle;
	local GGNPC tmpNpc;
	local GGNpcApocalypseGoat tmpApoNpc;
	local array<GGNpcApocalypseGoat> summonersList;
	local array<GGNpcApocalypseGoat> potentialSummonersList;

	super.Tick( DeltaTime );

	mTotalTime += DeltaTime;
	if(mTotalTime >= mRefreshTime)
	{
		mTotalTime = 0.f;
		// Find NPCs in circle
		foreach CollidingActors(class'GGNpc', tmpNpc, mRadius, Location)
		{
			if(IsAffectedByCircle(tmpNpc))
			{
				newNpcsInCircle.AddItem(tmpNpc);
			}
		}
		// Remove NPCs out of circle
		foreach mNpcsInCircle(tmpNpc)
		{
			if(newNpcsInCircle.Find(tmpNpc) == INDEX_NONE)
			{
				RemoveFromCircle(tmpNpc);
			}
		}
		// Add new NPCs to circle
		foreach newNpcsInCircle(tmpNpc)
		{
			if(mNpcsInCircle.Find(tmpNpc) == INDEX_NONE)
			{
				AddToCircle(tmpNpc);
			}
		}
		// Cancel ritual if no more targe in circle
		if(mCancelRitualIfNoTargetInCircle
		&& mNpcsInCircle.Length == 0
		&& !mRitualDone)
		{
			SelfDestroy();
		}
		// Find summoners near
		foreach CollidingActors(class'GGNpcApocalypseGoat', tmpApoNpc, mSummoningRadius, Location, true)
		{
			if(tmpApoNpc.class == mSummonerClass
			&& GGAIControllerApocalypse(tmpApoNpc.Controller) != none)
			{
				potentialSummonersList.AddItem(tmpApoNpc);
				if(GGAIControllerApocalypse(tmpApoNpc.Controller).isArrived
				&& !tmpApoNpc.mIsRagdoll)
				{
					summonersList.AddItem(tmpApoNpc);
				}
			}
		}
		// if enough summoners, perform ritual
		mLastSummonersCount = summonersList.Length;
		if(mLastSummonersCount >= mSummonersNeededForRitual)
		{
			PerformRitual(summonersList);
		}
		ManageRequiredSummoners(potentialSummonersList);
	}
}

function ManageRequiredSummoners(array<GGNpcApocalypseGoat> summoners)
{
	local int i;
	local GGNpcApocalypseGoat tmpSummoner;

	if(mRitualDone)
		return;

	// if any existing summoner can no longer summon, then reset count
	if(mRequiredSummoners.Length != 0)
	{
		foreach mRequiredSummoners(tmpSummoner)
		{
			if(tmpSummoner == none
			|| tmpSummoner.bPendingDelete
			|| GGAIControllerApocalypse(tmpSummoner.Controller) == none
			|| GGAIControllerApocalypse(tmpSummoner.Controller).mPawnToAttack != none)
			{
				mRequiredSummoners.Length = 0;
				break;
			}
		}
	}
	// if no summoner required and enough summoners near, require them
	if(mRequiredSummoners.Length == 0 && summoners.Length >= mSummonersNeededForRitual)
	{
		for(i= 0 ; i<mSummonersNeededForRitual ; i++)
		{
			mRequiredSummoners.AddItem(summoners[i]);
		}
	}
}

function bool RequireMoreSummoners()
{
	return mRequiredSummoners.Length == 0;
}

function bool IsRequiredSummoner(GGNpcApocalypseGoat summoner)
{
	return mRequiredSummoners.Find(summoner) != INDEX_NONE;
}

function bool IsAffectedByCircle(GGNpc npc)
{
	return npc.Controller == none;
}

function AddToCircle(GGNpc npc)
{
	local CircleHalo newHalo;

	if(mCircleHaloTemplate != none)
	{
		newHalo = Spawn(class'CircleHalo', self);
		newHalo.AttachHalo(npc);
		mCircleHalos.AddItem(newHalo);
	}
	mNpcsInCircle.AddItem(npc);
}

function RemoveFromCircle(GGNpc npc)
{
	local CircleHalo npcHalo, tmpHalo;

	foreach mCircleHalos(tmpHalo)
	{
		if(tmpHalo.myBase == npc)
		{
			npcHalo = tmpHalo;
			break;
		}
	}
	if(npcHalo != none)
	{
		mCircleHalos.RemoveItem(npcHalo);
		npcHalo.Destroy();
	}
	mNpcsInCircle.RemoveItem(npc);
}

function PerformRitual(array<GGNpcApocalypseGoat> summonersList)
{
 	local GGNpc npc;
 	local GGNpcApocalypseGoat summoner;

 	if(mRitualDone || !mRitualReady)
 		return;

 	mRitualDone = true;
 	mRequiredSummoners.Length = 0;

 	PlaySound(mCompletionSound);
 	WorldInfo.MyEmitterPool.SpawnEmitter(mCompletionEffect, Location);

	foreach mNpcsInCircle(npc)
	{
		DoRitualFor(npc);
	}

	foreach summonersList(summoner)
	{
		summoner.OnRitualEnded();
	}

	ClearTimer(NameOf(SelfDestroy));
	SetTimer(mDissapearTime, false, NameOf(SelfDestroy));
}
// Override in child to do the ritual effect on targets
function DoRitualFor(GGNpc npc);

static function bool IsTooCloseToCircle(GGNpc npc)
{
	local RitualCircle tmpCircle;

	foreach npc.AllActors(class'RitualCircle', tmpCircle)
	{
		if(tmpCircle != none && VSize2D(tmpCircle.Location - class'ApocalypseMutator'.static.GetPawnPosition(npc)) < default.mMinDistanceBetweenCircles)
		{
			return true;
		}
	}

	return false;
}

static function bool IsCollidingWithCircle(Actor act, optional vector pos)
{
	local RitualCircle tmpCircle;
	local vector loc;

	loc = IsZero(pos) ? act.Location : pos;
	foreach act.AllActors(class'RitualCircle', tmpCircle)
	{
		if(tmpCircle != none && VSize2D(tmpCircle.Location - loc) < default.mRadius * 2.f)
		{
			return true;
		}
	}

	return false;
}

function SelfDestroy()
{
	ShutDown();
	Destroy();
}

event Destroyed()
{
	local CircleHalo tmpHalo;

	foreach mCircleHalos(tmpHalo)
	{
		tmpHalo.ShutDown();
		tmpHalo.Destroy();
	}
	mCircleHalos.Length = 0;

	super.Destroyed();
}

function rotator GetRandomRotation()
{
	local rotator rot;

	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);

	return rot;
}

function EraseActor(Actor act)
{
	local int i;

	for( i = 0; i < act.Attached.Length; i++ )
	{
		act.Attached[i].ShutDown();
		act.Attached[i].Destroy();
	}
	//Haxx to force destruction if the Destroy function is not enough
	act.SetPhysics(PHYS_None);
	act.SetHidden(true);
	act.SetLocation(vect(0, 0, -1000));
	act.Shutdown();
	act.Destroy();
}

DefaultProperties
{
	mRadius=200.f
	mSummoningRadius=400.f
	mCircleTimeout=30.f
	mReadyTime=10.f
	mDissapearTime=1.f
	mSummonersNeededForRitual=4
	mRefreshTime=0.25f
	mMinDistanceBetweenCircles=5000.f
	mCancelRitualIfNoTargetInCircle=true;

	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'MMO_Effects.mesh.MMO_Questarea'
		Scale3D=(X=1.f,Y=1.f,Z=1.f)
	End Object

	bNoDelete=false
	bStatic=false
	bBlockActors=false
	bCollideActors=false
	Physics=PHYS_None
	CollisionType=COLLIDE_NoCollision


}