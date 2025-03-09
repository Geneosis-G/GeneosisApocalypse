class GGAIControllerApocalypse extends GGAIControllerPassiveGoat;
// Movement infos
var float mDestinationOffset;

var kActorSpawnable destActor;
var bool cancelNextRagdoll;
var float totalTime;
var bool isArrived;
var bool isPossessing;
var vector mSafeLocation;
var float mDrowningTime;
// Attack infos
var GGPawn mLockedAttackTarget;
var float mAttackAnimDelay;
var bool mIsAngel;
var bool mBaaInProgress;
// Demon Attack infos
var DemonLaser mDemonLaser;
var name mBeamSocket;
// Angel Attack infos
var HeavenGate mHeavenGate;
// Summoning infos
var vector mTargetDestination;
var float mRitualCircleSearchRadius;
// Mutator parent
var ApocalypseMutator myMut;

/**
 * Cache the NPC and mOriginalPosition
 */
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	local ProtectInfo destination;

	super.Possess(inPawn, bVehicleTransition);

	isPossessing=true;
	if(mMyPawn == none)
		return;

	FindApocalypseMutator();

	mIsAngel = GGNpcAngelGoat(mMyPawn) != none;
	SpawnAttackActor();

	mMyPawn.mProtectItems.Length=0;
	SpawnDestActor();
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " destActor=" $ destActor);
	destActor.SetLocation(mMyPawn.Location);
	destination.ProtectItem = mMyPawn;
	destination.ProtectRadius = 1000000.f;
	mMyPawn.mProtectItems.AddItem(destination);
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " mMyPawn.mProtectItems[0].ProtectItem=" $ mMyPawn.mProtectItems[0].ProtectItem);
	StandUp();
	mSafeLocation = mMyPawn.Location;
}

function SpawnDestActor()
{
	if(destActor == none || destActor.bPendingDelete)
	{
		destActor = Spawn(class'kActorSpawnable', mMyPawn,,,,,true);
		destActor.SetHidden(true);
		destActor.SetPhysics(PHYS_None);
		destActor.SetCollision(false, false);
		destActor.SetCollisionType(COLLIDE_NoCollision);
		destActor.CollisionComponent=none;
	}
}

function SpawnAttackActor()
{
	if(mIsAngel && (mHeavenGate == none || mHeavenGate.bPendingDelete))
	{
		mHeavenGate = Spawn(class'HeavenGate', mMyPawn);
		mHeavenGate.SetHidden(true);
	}
	if(!mIsAngel && (mDemonLaser == none || mDemonLaser.bPendingDelete))
	{
		mDemonLaser = Spawn(class'DemonLaser', mMyPawn);
	}
}

event UnPossess()
{
	if(destActor != none)
	{
		destActor.ShutDown();
		destActor.Destroy();
	}
	if(mHeavenGate != none)
	{
		mHeavenGate.DestroyWhenAttackComplete();
		mHeavenGate = none;
	}
	if(mDemonLaser != none)
	{
		mDemonLaser.DestroyWhenAttackComplete();
		mDemonLaser = none;
	}

	isPossessing=false;
	super.UnPossess();
	mMyPawn=none;
}

function FindApocalypseMutator()
{
	if(myMut != none)
		return;

	foreach AllActors(class'ApocalypseMutator', myMut)
	{
		break;
	}
}

//Kill AI if zombie is destroyed
function bool KillAIIfPawnDead()
{
	if(mMyPawn == none || mMyPawn.bPendingDelete || mMyPawn.Controller != self)
	{
		UnPossess();
		Destroy();
		return true;
	}

	return false;
}

event Tick( float deltaTime )
{
	//Kill destroyed angels/demons
	if(isPossessing)
	{
		if(KillAIIfPawnDead())
		{
			return;
		}
	}

	// Optimisation
	if( mMyPawn.IsInState( 'UnrenderedState' ) )
	{
		return;
	}

	Super.Tick( deltaTime );

	// Fix dead attacked pawns
	if( mPawnToAttack != none )
	{
		if( mPawnToAttack.bPendingDelete )
		{
			mPawnToAttack = none;
		}
	}

	//Fix dissapearing dest actor and attach actors
	SpawnDestActor();
	SpawnAttackActor();

	//WorldInfo.Game.Broadcast(self, mMyPawn $ " (1) isArrived=" $ isArrived $ ", Vel=" $ mMyPawn.Velocity);
	cancelNextRagdoll=false;

	if(!mMyPawn.mIsRagdoll)
	{
		//Fix NPC with no collisions
		if(mMyPawn.CollisionComponent == none)
		{
			mMyPawn.CollisionComponent = mMyPawn.Mesh;
		}

		//Fix NPC rotation
		UnlockDesiredRotation();
		if(mPawnToAttack != none)
		{
			Pawn.SetDesiredRotation( rotator( Normal2D( mPawnToAttack.Location - Pawn.Location ) ) );
			mMyPawn.LockDesiredRotation( true );
			// Fix isArrived state during attacks
			isArrived = VSize( mMyPawn.Location - mPawnToAttack.Location ) <= mMyPawn.mAttackRange;
			if(isArrived)
			{
				// Fix ragdoll if not reaching target
				totalTime=0.f;
				// Fix pawn not attacking if in range
				if(ReadyToAttack())
				{
					GotoState('Attack');
				}
			}
			//Fix pawn stuck after attack
			if(!IsValidEnemy(mPawnToAttack) || !PawnInRange(mPawnToAttack))
			{
				EndAttack();
			}
			else if(mCurrentState == '')
			{
				GotoState( 'ChasePawn' );
			}
		}
		else
		{
			//Fix random movement state
			if(mCurrentState == '')
			{
				//WorldInfo.Game.Broadcast(self, mMyPawn $ " no state detected");
				GoToState('FollowTarget');
			}

			UpdateFollowTarget();
		}
		//WorldInfo.Game.Broadcast(self, mMyPawn $ "(" $ mMyPawn.Physics $ ")");
		//WorldInfo.Game.Broadcast(self, mMyPawn $ "(" $ mMyPawn.mCurrentAnimationInfo.AnimationNames[0] $ ")");
		//WorldInfo.Game.Broadcast(self, mMyPawn $ "(" $ mCurrentState $ ")");
		//WorldInfo.Game.Broadcast(self, mMyPawn $ " (2) isArrived=" $ isArrived $ ", Vel=" $ mMyPawn.Velocity);
		// do not override anim if attack in progress
		if(!mBaaInProgress)
		{
			if(IsZero(mMyPawn.Velocity))
			{
				// Baa if doing ritual
				if(isArrived && !IsZero(mTargetDestination))
				{
					GGNpcGoat(mMyPawn).PlayBaa();
					mBaaInProgress = true;
				}
				// else be idle
				else if(isArrived && !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mDefaultAnimationInfo ))
				{
					mMyPawn.SetAnimationInfoStruct( mMyPawn.mDefaultAnimationInfo );//WorldInfo.Game.Broadcast(self, mMyPawn $ "DefaultAnim");
				}
			}
			else
			{
				if(VSize2D(mMyPawn.Velocity) < class'GGGoat'.default.mWalkSpeed)
				{
					if( !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mRunAnimationInfo ) )
					{
						mMyPawn.SetAnimationInfoStruct( mMyPawn.mRunAnimationInfo );//WorldInfo.Game.Broadcast(self, mMyPawn $ "RunAnim");
					}
				}
				else
				{
					if( !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mPanicAnimationInfo ) )
					{
						mMyPawn.SetAnimationInfoStruct( mMyPawn.mPanicAnimationInfo );//WorldInfo.Game.Broadcast(self, mMyPawn $ "RunAnim");
					}
				}
			}
		}
		// if waited too long to before reaching some place or some target, abandon
		totalTime = totalTime + deltaTime;
		if(totalTime > 11.f)
		{
			totalTime=0.f;
			mMyPawn.SetRagdoll(true);
			EndAttack();
		}
	}
	else
	{
		//Fix NPC not standing up
		if(!IsTimerActive( NameOf( StandUp ) ))
		{
			StartStandUpTimer();
		}

		//Make drowning goats reach back safe position
		if(mMyPawn.mInWater)
		{
			totalTime = totalTime + deltaTime;
			if(totalTime > 1.f)
			{
				totalTime=0.f;
				DoRagdollJump();
			}
			// If drowning for too long, kill the goat
			if(!IsTimerActive(NameOf(PawnDrown)))
			{
				SetTimer(mDrowningTime, false, NameOf(PawnDrown));
			}
		}
	}

	if(!mMyPawn.mInWater && mMyPawn.Physics == PHYS_Walking)
	{
		// When walking on land, stop drowning
		ClearTimer(NameOf(PawnDrown));
	}
}

function PawnDrown()
{
	UnPossess();
	Destroy();
}

/**
 * Do ragdoll jump, e.g. for jumping out of water.
 */
function DoRagdollJump()
{
	local vector newVelocity;

	newVelocity = Normal2D(mSafeLocation-GetPosition(mMyPawn));
	newVelocity.Z = 1.f;
	newVelocity = Normal(newVelocity) * class'GGGoat'.default.mRagdollJumpZ;

	mMyPawn.mesh.SetRBLinearVelocity( newVelocity );
}

function UpdateFollowTarget()
{
	local vector dest, voffset;
	local float myRadius,  offset;

	if(mPawnToAttack != none || mMyPawn.mIsRagdoll)
	{
		return;
	}

	myRadius=mMyPawn.GetCollisionRadius();
	dest = IsZero(mTargetDestination) ? mMyPawn.Location : mTargetDestination;
	offset=myRadius*2;
	voffset=Normal2D(GetPosition(mMyPawn)-dest)*offset;
	dest+=voffset;
	dest.Z=GetPosition(mMyPawn).Z;

	if(VSize2D(GetPosition(mMyPawn)-dest) < offset)
	{
		// Makes sure we keep pointing in the direction we were pointing before
		dest=mMyPawn.Location + Normal2D(destActor.Location - mMyPawn.Location);
		if(!isArrived)
		{
			isArrived=true;//WorldInfo.Game.Broadcast(self, mMyPawn $ " (1) isArrived=true");
			mMyPawn.ZeroMovementVariables();
		}
		totalTime=0.f;
	}
	else
	{
		if(isArrived)
		{
			isArrived=false;//WorldInfo.Game.Broadcast(self, mMyPawn $ " (1) isArrived=false");
			totalTime=-10.f;
		}
	}

	//DrawDebugLine (mMyPawn.Location, dest, 0, 0, 0,);

	destActor.SetLocation(dest);
	mMyPawn.SetDesiredRotation( rotator( Normal2D( destActor.Location - mMyPawn.Location ) ) );
	mMyPawn.LockDesiredRotation( true );
}

function vector GetPosition(GGPawn gpawn)
{
	return class'ApocalypseMutator'.static.GetPawnPosition(gpawn);
}

function StartProtectingItem( ProtectInfo protectInformation, GGPawn threat )
{
	StopAllScheduledMovement();
	totalTime=0.f;

	mCurrentlyProtecting = protectInformation;

	mPawnToAttack = threat;

	mTargetDestination = vect(0, 0, 0);

	StartLookAt( threat, 5.0f );

	GotoState( 'ChasePawn' );
}

function StartAttack( Pawn pawnToAttack )
{
	if(mBaaInProgress)
		return;

	Pawn.SetDesiredRotation( rotator( Normal2D( pawnToAttack.Location - Pawn.Location ) ) );

	mMyPawn.LockDesiredRotation( true );

	mPawnToAttack = pawnToAttack;

	GGNpcGoat(mMyPawn).PlayBaa();
	mBaaInProgress = true;

	mMyPawn.ZeroMovementVariables();

	AttackPawn();
}

// When attack animation is over, look for a new target
function OnStopBaa()
{
	mBaaInProgress=false;
	EndAttack();
}

/**
 * Attacks mPawnToAttack using mMyPawn.mAttackMomentum
 * called when our pawn needs to protect and item from a given pawn
 */
function AttackPawn()
{
	mLockedAttackTarget=GGPawn(mPawnToAttack);
	if(mIsAngel)
	{
		SetTimer( mAttackAnimDelay, false, NameOf(CastAngelAttack), self );
	}
	else
	{
		SetTimer( mAttackAnimDelay, false, NameOf(CastDemonAttack), self );
	}

	//Fix pawn stuck after attack (keep chasing pawn until attack animation is over)
	GotoState( 'ChasePawn' );
}

function CastAngelAttack()
{
	local vector startLocation;
	local rotator r;

	if(!IsValidEnemy(mLockedAttackTarget))
	{
		mLockedAttackTarget=none;
		return;
	}

	mMyPawn.mesh.GetSocketWorldLocationAndRotation(mBeamSocket, startLocation, r);
	mHeavenGate.OpenGateOnTarget(startLocation, mLockedAttackTarget);
}

function ApocalypseAttackEnded()
{
	mLockedAttackTarget=none;
}

function CastDemonAttack()
{
	local vector startLocation, endLocation, pos;
	local rotator r;

	if(!IsValidEnemy(mLockedAttackTarget))
	{
		mLockedAttackTarget=none;
		return;
	}

	mMyPawn.mesh.GetSocketWorldLocationAndRotation(mBeamSocket, startLocation, r);
	pos = GetPosition(mLockedAttackTarget);
	endLocation = pos + (Normal(startLocation - pos) * mLockedAttackTarget.GetCollisionRadius());
	endLocation.Z = pos.Z - mLockedAttackTarget.GetCollisionHeight();
	mDemonLaser.ShootLaser(startLocation, endLocation);
}

/**
 * We have to disable the notifications for changing states, since there are so many npcs which all have hundreds of calls.
 */
state MasterState
{
	function BeginState( name prevStateName )
	{
		mCurrentState = GetStateName();
	}
}

state FollowTarget extends MasterState
{
	event PawnFalling()
	{
		GoToState( 'WaitingForLanding',,,true );
	}
Begin:
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " FollowTarget");
	mMyPawn.ZeroMovementVariables();
	while(mPawnToAttack == none && !KillAIIfPawnDead())
	{
		//WorldInfo.Game.Broadcast(self, mMyPawn $ " STATE OK!!!");
		if(!isArrived)
		{
			MoveToward (destActor);
		}
		else
		{
			MoveToward (mMyPawn,, mDestinationOffset);// Ugly hack to prevent "runnaway loop" error
		}
	}
	mMyPawn.ZeroMovementVariables();
}

state WaitingForLanding
{
	event LongFall()
	{
		mDidLongFall = true;
	}

	event NotifyPostLanded()
	{
		if( mDidLongFall || !CanReturnToOrginalPosition() )
		{
			if( mMyPawn.IsDefaultAnimationRestingOnSomething() )
			{
			    mMyPawn.mDefaultAnimationInfo =	mMyPawn.mIdleAnimationInfo;
			}

			mOriginalPosition = mMyPawn.Location;
		}

		mDidLongFall = false;

		StopLatentExecution();
		mMyPawn.ZeroMovementVariables();
		GoToState( 'FollowTarget', 'Begin',,true );
	}

Begin:
	mMyPawn.ZeroMovementVariables();
	WaitForLanding( 1.0f );
}

state ChasePawn extends MasterState
{
	ignores SeePlayer;
 	ignores SeeMonster;
 	ignores HearNoise;
 	ignores OnManual;
 	ignores OnWallJump;
 	ignores OnWallRunning;

begin:
	while(mPawnToAttack != none && !KillAIIfPawnDead() && (!isArrived || !ReadyToAttack()))
	{
		MoveToward( mPawnToAttack,, mMyPawn.mAttackRange - mMyPawn.GetCollisionRadius() );
	}

	if(mPawnToAttack == none)
	{
		ReturnToOriginalPosition();
	}
	else
	{
		FinishRotation();
		GotoState( 'Attack' );
	}
}

state Attack extends MasterState
{
	ignores SeePlayer;
 	ignores SeeMonster;
 	ignores HearNoise;
 	ignores OnManual;
 	ignores OnWallJump;
 	ignores OnWallRunning;

begin:
	Focus = mPawnToAttack;

	StartAttack( mPawnToAttack );
	FinishRotation();
}

//All work done in EnemyNearProtectItem()
function CheckVisibilityOfGoats();
function CheckVisibilityOfEnemies();
event SeePlayer( Pawn Seen );
event SeeMonster( Pawn Seen );

function bool EnemyNearProtectItem( ProtectInfo protectInformation, out GGPawn enemyNear )
{
	local GGPawn tmpPawn;
	local array<GGPawn> visiblePawns;
	local array<GGPawn> priorityPawns;
	local int size;

	// Find nearby enemies
	foreach VisibleCollidingActors(class'GGPawn', tmpPawn, mMyPawn.SightRadius, mMyPawn.Location)
	{
		if(IsValidEnemy(tmpPawn))
		{
			if(IsPriorityEnemy(tmpPawn))
			{
				priorityPawns.AddItem(tmpPawn);
			}
			else
			{
				visiblePawns.AddItem(tmpPawn);
			}
		}
	}
	// if any priority enemy near, attack it
	size=priorityPawns.Length;
	if(size > 0)
	{
		enemyNear=priorityPawns[Rand(size)];
	}
	// Random chance to attack an enemy (50%)
	if(enemyNear == none && Rand(2) == 0)
	{
		size=visiblePawns.Length;
		if(size > 0)
		{
			enemyNear=visiblePawns[Rand(size)];
		}
	}
	// else look for closest ritual circle
	if(enemyNear == none)
	{
		FindOrCreateRitualCircle();
	}
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " EnemyNearProtectItem=" $ enemyNear);
	return (enemyNear != none);
}

function FindOrCreateRitualCircle()
{
	local RitualCircle closestCircle;
	local class<RitualCircle> circleClass;
	local vector spawnLoc;
	local bool ignoreExistingCircles;
	// If not yet looking for a circle, random chance to try to create another circle
	ignoreExistingCircles = IsZero(mTargetDestination) && Rand(2) == 0;
	mTargetDestination=vect(0, 0, 0);
	circleClass = mIsAngel ? class'AngelCircle' : class'DemonCircle';
	if(!ignoreExistingCircles)
	{
		closestCircle = GetClosestCircle();
	}
	// if no friendly circle near, create one
	if(closestCircle == none)
	{
		spawnLoc = GetCircleSpawnLocation();
		if(!IsZero(spawnLoc))
		{
			closestCircle = Spawn(circleClass,,, spawnLoc);
			//WorldInfo.Game.Broadcast(self, closestCircle $ " dirtance to spawner=" $ VSize2D(spawnLoc - GetPosition(mMyPawn)));
		}
	}
	// Move to circle
	if(closestCircle != none)
	{
		mTargetDestination = closestCircle.Location + (Normal2D(mMyPawn.Location - closestCircle.Location) * closestCircle.mRadius);
		mTargetDestination.Z = mMyPawn.Location.Z;
	}
}

function RitualCircle GetClosestCircle()
{
	local RitualCircle tmpCircle, closestCircle;
	local float minDist, dist;
	local class<RitualCircle> circleClass;

	circleClass = mIsAngel ? class'AngelCircle' : class'DemonCircle';
	foreach AllActors(class'RitualCircle', tmpCircle)
	{
		dist = VSize(GetPosition(mMyPawn) - tmpCircle.Location);
		// Go to an existing circle if it's of the correct type, if the ritual is not ended and if more summoners are needed or if my pawn is a required summoner
		if(tmpCircle.class == circleClass
		&& dist <= mRitualCircleSearchRadius
		&& !tmpCircle.mRitualDone
		&& (tmpCircle.RequireMoreSummoners() || tmpCircle.IsRequiredSummoner(GGNpcApocalypseGoat(mMyPawn))))
		{
			if(closestCircle == none || dist < minDist)
			{
				closestCircle = tmpCircle;
				minDist = dist;
			}
		}
	}

	return closestCircle;
}
// Find a dead NPC to open a circle on
function vector GetCircleSpawnLocation()
{
	local GGNpc tmpNpc;
	local array<GGNpc> ritualNpcs;
	local array<GGNpc> priorityNpcs;
	local vector loc;
	local int size;
	local float dist;

	foreach AllActors(class'GGNpc', tmpNpc)
	{
		dist = VSize(GetPosition(mMyPawn) - GetPosition(tmpNpc));
		// Only take NPCs with no controller (dead), not moving, not in water and not too close to an existing circle
		if(dist <= mRitualCircleSearchRadius
		&& !tmpNpc.bHidden
		&& tmpNpc.Controller == none
		&& !tmpNpc.mIsInWater
		&& VSize(tmpNpc.Velocity) < 1.f
		&& !class'RitualCircle'.static.IsTooCloseToCircle(tmpNpc))
		{
			if(IsPriorityNpcForRitual(tmpNpc))
			{
				priorityNpcs.AddItem(tmpNpc);
			}
			else
			{
				ritualNpcs.AddItem(tmpNpc);
			}
		}
	}
	size = priorityNpcs.Length;
	if(size > 0)
	{
		loc = GetPosition(priorityNpcs[Rand(size)]);
	}
	else
	{
		size = ritualNpcs.Length;
		if(size > 0)
		{
			loc = GetPosition(ritualNpcs[Rand(size)]);
		}
	}

	return loc;
}

function bool IsPriorityNpcForRitual(GGNpc npc)
{
	// Give priority to NPCs that will spawn more angel/demon
	if(mIsAngel)
	{
		return GGNpcApocalypseGoat(npc) != none;
	}
	else
	{
		return GGNpcAngelGoat(npc) == none;
	}
}

function OnRitualEnded()
{
	mTargetDestination = vect(0, 0, 0);
}

/**
 * Helper function to determine if our pawn is close to a protect item, called when we arrive at a pathnode
 * @param currentlyAtNode - The pathNode our pawn just arrived at
 * @param out_ProctectInformation - The info about the protect item we are near if any
 * @return true / false depending on if the pawn is near or not
 */
function bool NearProtectItem( PathNode currentlyAtNode, out ProtectInfo out_ProctectInformation )
{
	out_ProctectInformation=mMyPawn.mProtectItems[0];
	return true;
}

function bool IsValidEnemy( Pawn newEnemy )
{
	local GGNpc npc;
	local GGPawn gpawn;

	gpawn=GGPawn(newEnemy);
	if(gpawn == none
	|| gpawn.bPendingDelete
	|| gpawn.bHidden
	|| gpawn.class == mMyPawn.class
	|| mMyPawn.mIsRagdoll
	|| gpawn.Controller == none)
	{
		return false;
	}

	// Demon goat will attack players, and angels will fight back if attacked
	if(GGGoat(gpawn) != none && (!mIsAngel || myMut.IsAngelEnemyAI(gpawn.Controller.class)))
	{
		return true;
	}

	npc = GGNpc(gpawn);
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " canAttack(npc)=" $ npc);
	if(npc != none)
	{
		if(npc.mInWater)
		{
			return false;
		}
		// Demons will attack any NPC
		if(!mIsAngel)
		{
			return true;
		}
		// Angels will attack Demons and NPCs that attacked them
		else
		{
			return GGNpcDemonGoat(npc) != none || myMut.IsAngelEnemyAI(npc.Controller.class);
		}
	}

	return false;
}

function bool IsPriorityEnemy( Pawn newEnemy )
{
	if(mIsAngel && GGNpcDemonGoat(newEnemy) != none)
		return true;

	if(!mIsAngel && GGNpcAngelGoat(newEnemy) != none)
		return true;

	return false;
}

/**
 * Helper functioner for determining if the goat is in range of uur sightradius
 * if other is not specified mLastSeenGoat is checked against
 */
function bool PawnInRange( optional Pawn other )
{
	if(mMyPawn.mIsRagdoll)
	{
		return false;
	}
	else
	{
		return super.PawnInRange(other);
	}
}

/**
 * Called when an actor takes damage
 */
function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum )
{
	if(damagedActor == mMyPawn)
	{
		if(dmgType == class'GGDamageTypeCollision' && !mMyPawn.mIsRagdoll)
		{
			cancelNextRagdoll=true;
		}
	}
}

function bool CanReturnToOrginalPosition()
{
	return false;
}

/**
 * Go back to where the position we spawned on
 */
function ReturnToOriginalPosition()
{
	GotoState( 'FollowTarget' );
}

/**
 * Helper function for when we see the goat to determine if it is carrying a scary object
 */
function bool GoatCarryingDangerItem()
{
	return false;
}

function bool PawnUsesScriptedRoute()
{
	return false;
}

//--------------------------------------------------------------//
//			GGNotificationInterface								//
//--------------------------------------------------------------//

/**
 * Called when an actor begins to ragdoll
 */
function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	local GGNPc npc;

	npc = GGNPc( ragdolledActor );

	if(ragdolledActor == mMyPawn)
	{
		if(isRagdoll)
		{
			if(cancelNextRagdoll)
			{
				cancelNextRagdoll=false;
				StandUp();
				//mMyPawn.SetPhysics( PHYS_Falling);
				//mMyPawn.Velocity+=pushVector;
			}
			else
			{
				if( IsTimerActive( NameOf( StopPointing ) ) )
				{
					StopPointing();
					ClearTimer( NameOf( StopPointing ) );
				}

				if( IsTimerActive( NameOf( StopLookAt ) ) )
				{
					StopLookAt();
					ClearTimer( NameOf( StopLookAt ) );
				}

				if( mCurrentState == 'ProtectItem' )
				{
					ClearTimer( nameof( AttackPawn ) );
					ClearTimer( nameof( DelayedGoToProtect ) );
				}
				StopAllScheduledMovement();
				StartStandUpTimer();
				EndAttack();
			}

			if( npc != none && npc.LifeSpan > 0.0f )
			{
				if( npc == mPawnToAttack )
				{
					EndAttack();
				}

				if( npc == mLookAtActor )
				{
					StopLookAt();
				}
			}
		}
	}
}

DefaultProperties
{
	mDestinationOffset=100.0f
	mAttackAnimDelay=0.25f
	mRitualCircleSearchRadius=10000.f
	mDrowningTime=60.f

	bIsPlayer=true
	mIgnoreGoatMaus=true

	mAttackIntervalInfo=(Min=3.f,Max=3.f,CurrentInterval=3.f)
	mCheckProtItemsThreatIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)
	mVisibilityCheckIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)

	cancelNextRagdoll=false

	mBeamSocket="grabSocket"
}