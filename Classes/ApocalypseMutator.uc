class ApocalypseMutator extends GGMutator;

var float SRTimeElapsed;
var float spawnRemoveTimer;
var int startAngelCount;
var int startDemonCount;
var int mSpawnGroupCount;

var int mAngelCount;
var int mDemonCount;

var bool mIsInitialSpawnComplete;
var bool mOneSideWon;
var bool mWorldEnded;

var int mDeathLimit;
var ParticleSystem mDeathParticleTemplate;

var array<class<Controller> > mAngelEnemyAIs;

simulated event Tick( float deltaTime )
{
	super.Tick( deltaTime );

	SRTimeElapsed=SRTimeElapsed+deltaTime;
	if(SRTimeElapsed > spawnRemoveTimer)
	{
		SRTimeElapsed=0.f;
		if(!mIsInitialSpawnComplete)
		{
			SpawnAngelsDemons();
		}
		else
		{
			if(!mOneSideWon)
			{
				CheckIfOneSideWon();
			}
			else if(!mWorldEnded)
			{
				CheckIfWorldEnded();
			}
		}
	}
}

function SpawnAngelsDemons()
{
	local GGPawn angelSpawnTarget;
	local GGPawn demonSpawnTarget;
	local GGNpcAngelGoat newAngel;
	local GGNpcDemonGoat newDemon;
	local int i;

	//Spawn new angels and demons until the start number is reached
	if(mAngelCount < startAngelCount)
	{
		angelSpawnTarget = GetSpawnTarget();
	}
	if(mDemonCount < startDemonCount)
	{
		demonSpawnTarget = GetSpawnTarget(angelSpawnTarget);
	}

	if(angelSpawnTarget != none)
	{
		mSpawnGroupCount = class'AngelCircle'.default.mSummonersNeededForRitual + 1 ;
		for(i=0 ; i<mSpawnGroupCount ; i++)
		{
			newAngel = Spawn( class'GGNpcAngelGoat',,, GetSpawnLocation(angelSpawnTarget, i), GetRandomRotation(),,true);
			if(newAngel != none)
			{
				newAngel.SetPhysics( PHYS_Falling );
				mAngelCount++;
			}
		}
	}
	if(demonSpawnTarget != none)
	{
		mSpawnGroupCount = class'DemonCircle'.default.mSummonersNeededForRitual + 1;
		for(i=0 ; i<mSpawnGroupCount  ; i++)
		{
			newDemon = Spawn( class'GGNpcDemonGoat',,, GetSpawnLocation(demonSpawnTarget, i), GetRandomRotation(),,true);
			if(newDemon != none)
			{
				newDemon.SetPhysics( PHYS_Falling );
				mDemonCount++;
			}
		}
	}
	mIsInitialSpawnComplete = (mAngelCount >= startAngelCount) && (mDemonCount >= startDemonCount);
	//if(mIsInitialSpawnComplete)
	//	WorldInfo.Game.Broadcast(self, "Initial Spawn Complete!");
}

function GGPawn GetSpawnTarget(optional GGPawn avoidPawn = none)
{
	local GGPawn tmpGpawn;
	local array<GGPawn> eligiblePawns;

	foreach AllActors(class'GGPawn', tmpGpawn)
	{
		if(tmpGpawn != none && !tmpGpawn.bHidden && !tmpGpawn.bPendingDelete && !tmpGpawn.mIsRagdoll && tmpGpawn != avoidPawn)
		{
			eligiblePawns.AddItem(tmpGpawn);
		}
	}

	if(eligiblePawns.Length > 0)
	{
		return eligiblePawns[Rand(eligiblePawns.Length)];
	}

	return avoidPawn;
}

function vector GetSpawnLocation(GGPawn spawnTarget, int posIndex)
{
	local vector dest;
	local rotator rot;
	local float dist, angle;

	angle = 65536.f / mSpawnGroupCount;
	rot=rot(0, 1, 0) * angle * posIndex;

	dist=(spawnTarget.GetCollisionRadius() * 2.f) + 10.f;

	dest=spawnTarget.Location+Normal(vector(rot))*dist;
	dest.Z+=1000.f;

	return dest;
}

function rotator GetRandomRotation()
{
	local rotator rot;

	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);

	return rot;
}

function CheckIfOneSideWon()
{
	local GGNpcAngelGoat tmpAngel;
	local GGNpcDemonGoat tmpDemon;
	local bool angelsWon;
	local bool demonsWon;

	demonsWon=true;
	foreach AllActors(class'GGNpcAngelGoat', tmpAngel)
	{
		if(GGAIController(tmpAngel.Controller) != none)
		{
			demonsWon=false;
			break;
		}
	}
	if(demonsWon)
	{
		class'SatanGoat'.static.UnlockSatanGoat();
	}

	angelsWon=true;
	foreach AllActors(class'GGNpcDemonGoat', tmpDemon)
	{
		if(GGAIController(tmpDemon.Controller) != none)
		{
			angelsWon=false;
			break;
		}
	}
	if(angelsWon)
	{
		class'GodGoat'.static.UnlockGodGoat();
	}

	mOneSideWon = demonsWon || angelsWon;
}

function CheckIfWorldEnded()
{
	local GGAIController tmpContr;
	local bool allAIControllerDead;

	allAIControllerDead=true;
	foreach AllActors(class'GGAIController', tmpContr)
	{
		if(tmpContr != none)
		{
			allAIControllerDead=false;
			break;
		}
	}
	if(allAIControllerDead)
	{
		mWorldEnded=true;
		class'VoidGoat'.static.UnlockVoidGoat();
	}
}

function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum )
{
	local GGNpc damagedNpc;
	local Controller agressiveContr;

	damagedNpc = GGNpc(damagedActor);
	// Make angels attack any enemy AI that attacked one of them
	if(damagedNpc != none
	&& GGNpcAngelGoat(damagedNpc) != none
	&& GGAIControllerApocalypse(damagedNpc.Controller) != none
	&& damage > 0
	&& dmgType != class'GGDamageTypeCollision'
	&& GGPawn(damageCauser) != none
	&& damagedActor.class != damageCauser.class)
	{
		agressiveContr=GGPawn(damageCauser).Controller;
		if(agressiveContr != none
		&& mAngelEnemyAIs.Find(agressiveContr.class) == INDEX_NONE)
		{
			mAngelEnemyAIs.AddItem(agressiveContr.class);
		}
	}
	// Kill any NPC that take damage 5 times
	if(damagedNpc != none
	&& GGAIController(damagedNpc.Controller) != none
	&& damage > 0
	&& dmgType != class'GGDamageTypeCollision'
	&& damageCauser != none
	&& damagedActor.class != damageCauser.class)
	{
		// Makes sure the damage amount before death is acceptable
		if(damagedNpc.mTimesKnockedByGoatStayDownLimit > mDeathLimit || damagedNpc.mTimesKnockedByGoatStayDownLimit <= 0)
		{
			damagedNpc.mTimesKnockedByGoatStayDownLimit = mDeathLimit;
		}
		// Make sure revided creatures dont die instantly
		if(damagedNpc.mTimesKnockedByGoat >= damagedNpc.mTimesKnockedByGoatStayDownLimit)
		{
			damagedNpc.mTimesKnockedByGoat  = 0;
		}
		// Damage NPC
		damagedNpc.mTimesKnockedByGoat++;
		// Kill NPC if it took too much damage
		if(damagedNpc.mTimesKnockedByGoat >= damagedNpc.mTimesKnockedByGoatStayDownLimit)
		{
			static.KillNpc(damagedNpc);
		}
	}
}

static function KillNpc(GGNpc npc)
{
	local GGAIController contr;

	npc.WorldInfo.MyEmitterPool.SpawnEmitter( default.mDeathParticleTemplate, npc.Location );
	npc.SetRagdoll(true);
	contr = GGAIController(npc.Controller);
	contr.UnPossess();
	contr.ShutDown();
	contr.Destroy();
	npc.Spawn(class'DyingPawn', npc);
}

function bool IsAngelEnemyAI(class<Controller> contrClass)
{
	return mAngelEnemyAIs.Find(contrClass) != INDEX_NONE;
}

static function vector GetActorPosition(Actor act)
{
	return GGPawn(act)!=none?static.GetPawnPosition(GGPawn(act)):act.Location;
}

static function vector GetPawnPosition(GGPawn gpawn)
{
	return gpawn.mIsRagdoll?gpawn.mesh.GetPosition():gpawn.Location;
}

DefaultProperties
{
	spawnRemoveTimer=1f
	mDeathLimit=5
	startAngelCount=25 //100 //TODO Replace me
	startDemonCount=25 //100
	mDeathParticleTemplate=ParticleSystem'Zombie_Particles.Particles.Die_PS'
}