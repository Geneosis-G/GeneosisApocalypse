class LightCross extends GGKActor;

var GGPawn mOwner;

/** The velocity we give the cross when launched */
var float mLCSpeed;
var bool mStabbedSomething;
var float mDamage;

var SoundCue mHitPawnSoundCue;
var SoundCue mHitNonPawnSoundCue;
var SoundCue mBreakSound;
var StaticMeshComponent mBarComponent;
var vector mPosOffset;

var rotator mRotOffset;
var float mLifeDuration;
var rotator mLockedRotation;

var bool mIsLaunched;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	mOwner = GGPawn( Owner );
	mLockedRotation = Rotation;

	ShootSpike();
	if(mLifeDuration > 0)
	{
		SetTimer(mLifeDuration, false, NameOf(SelfDestroy));
	}
}

function ShootSpike()
{
	// Update collission
	SetCollision( true, true );
	CollisionComponent.SetActorCollision( true, false );
	StaticMeshComponent.SetBlockRigidBody( true );

	// Fire the spike straight forward
	StaticMeshComponent.BodyInstance.CustomGravityFactor=0.f;
	CollisionComponent.WakeRigidBody();
	StaticMeshComponent.SetRBLinearVelocity(Normal(vector(Rotation)) * mLCSpeed);
	mIsLaunched = true;
}

function bool HandleCollision( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local GGPawn pawn;
	local TraceHitInfo hitInfo;
	local vector dir;
	local float minMaxDist;
	local GGNpcZombieGameModeAbstract zombieEnemy;

	if(ShouldIgnoreActor(Other))
		return false;

	pawn = GGPawn( Other );

	//WorldInfo.Game.Broadcast(self, "HandleCollision with " $ Other $ "/" $ OtherComp $ "/" $ Other.Location $ "/me:" $ Location);
	// Direction the cross is flying
	//dir = normal( StaticMeshComponent.GetRBLinearVelocity() );
	dir = normal( vector(Rotation) );
	if( pawn != None )
	{
		// Several collission might come the first frame
		if( mStabbedSomething )
		{
			return true;
		}

		PlaySound( mHitPawnSoundCue );
		minMaxDist = 100;
		// Find where we hit the mesh if we continue the same path
		if( TraceComponent( HitLocation, HitNormal, pawn.Mesh, Location - dir * minMaxDist, Location + dir * minMaxDist,, hitInfo ) && hitInfo.BoneName != '' )
		{
			mStabbedSomething = true;
			SetPhysics( PHYS_None );

			SetCollision( false, false );
			StaticMeshComponent.SetNotifyRigidBodyCollision( false );
			StaticMeshComponent.SetActorCollision( false, false );
			StaticMeshComponent.SetBlockRigidBody( false );

			StaticMeshComponent.SetLightEnvironment(pawn.mLightEnvironment);

			if(HitLocation != vect(0, 0, 0))
				SetLocation(HitLocation - dir * 50);
;
			SetRotation(rot(0, 0, 0));
			SetBase( pawn,, pawn.mesh, hitInfo.BoneName );

			StaticMeshComponent.SetRotation(rTurn(rotator(dir), rot(0, -16384, 0)));
			mBarComponent.SetRotation(rotator(dir));

			pawn.SetRagdoll(true);

			//Damage zombies
			zombieEnemy = GGNpcZombieGameModeAbstract(pawn);
			if(zombieEnemy != none)
			{
				zombieEnemy.TakeDamage(mDamage, mOwner.Controller, zombieEnemy.Location, vect(0, 0, 0), class'GGDamageTypeZombieSurvivalMode',, mOwner);
			}
			else
			{
				pawn.TakeDamage( mDamage, mOwner.Controller, pawn.Location, vect(0, 0, 0), class'GGDamageType',, mOwner);
			}
		}

		return true;
	}
	else
	{
		if( mStabbedSomething )
		{
			return true;
		}

		mStabbedSomething = true;

		PlaySound( mHitNonPawnSoundCue );

		SetPhysics( PHYS_None );

		SetCollision( false, false );
		StaticMeshComponent.SetNotifyRigidBodyCollision( false );
		StaticMeshComponent.SetActorCollision( false, false );
		StaticMeshComponent.SetBlockRigidBody( false );

		SetRotation(rot(0, 0, 0));
		if(GGKactor(Other) != none)
			mRotOffset = Rotation - GGKactor(Other).StaticMeshComponent.GetRotation();
		SetBase(Other);

		StaticMeshComponent.SetRotation(rTurn(rotator(dir), rot(0, -16384, 0)));
		mBarComponent.SetRotation(rotator(dir));

		return true;
	}

	return false;
}

function SelfDestroy()
{
	PlaySound( mBreakSound );
	ShutDown();
	Destroy();
}

function bool ShouldIgnoreActor(Actor act)
{
	return (!mIsLaunched
	|| LightCross(act) != none
	|| Volume(act) != none
	|| GGApexDestructibleActor(act) != none
	|| act == self
	|| act == Owner
	|| act.Owner == Owner
	|| (GGNpcAngelGoat(act) != none && GGNpcAngelGoat(act).IsImmune()));
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	//WorldInfo.Game.Broadcast(self, "Touch with " $ Other $ "/" $ OtherComp);
	if( !HandleCollision( Other, OtherComp, HitLocation, HitNormal ) )
	{
		super.Touch( Other, OtherComp, HitLocation, HitNormal );
	}
}

event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
	//WorldInfo.Game.Broadcast(self, "Touch with " $ Other $ "/" $ OtherComp);
	if( !HandleCollision( Other, OtherComp, Location, HitNormal ) )
	{
		super.Bump( Other, OtherComp, HitNormal );
	}
}

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
	const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	//WorldInfo.Game.Broadcast(self, "Touch with " $ (OtherComponent != none ? OtherComponent.Owner : none) $ "/" $ OtherComponent);
	// Don't call super if we attach to other, that will ragdoll the other pawn
	if( !HandleCollision( OtherComponent != none ? OtherComponent.Owner : None, OtherComponent, RigidCollisionData.ContactInfos[ContactIndex].ContactPosition, RigidCollisionData.ContactInfos[ContactIndex].ContactNormal ) )
	{
		super.RigidBodyCollision( HitComponent, OtherComponent, RigidCollisionData, ContactIndex );
	}
}

event Tick(float deltaTime)
{
	local float currVelocity;

	super.Tick(DeltaTime);

	if(!mStabbedSomething)
	{
		// Force keep rotation
		SetRotation(mLockedRotation);
		// Destroy the cross if it's too slow
		currVelocity=VSize(StaticMeshComponent.GetRBLinearVelocity());
		if(currVelocity > 0.f)
		{
			if(currVelocity < mLCSpeed / 2.f)
			{
				SelfDestroy();
			}

			// Maintain velocity
			if(currVelocity < mLCSpeed)
			{
				StaticMeshComponent.SetRBLinearVelocity(Normal(vector(Rotation)) * mLCSpeed);
			}
		}
	}
	else
	{
		// Fix glitchy rotation on kactors
		if(GGKactor(Base) != none)
		{
			SetRotation(rTurn(GGKactor(Base).StaticMeshComponent.GetRotation(), mRotOffset));
		}
	}
	SetBarTranslation();
}

function SetBarTranslation()
{
	local vector newTranslation;

	newTranslation = TransformVectorByRotation(StaticMeshComponent.Rotation, mPosOffset);

	mBarComponent.SetTranslation(newTranslation);
}

function rotator rTurn(rotator rHeading,rotator rTurnAngle)
{
	return class'LightCross'.static.srTurn(rHeading, rTurnAngle);
}

static function rotator srTurn(rotator rHeading,rotator rTurnAngle)
{
    // Generate a turn in object coordinates
    //     this should handle any gymbal lock issues

    local vector vForward,vRight,vUpward;
    local vector vForward2,vRight2,vUpward2;
    local rotator T;
    local vector  V;

    GetAxes(rHeading,vForward,vRight,vUpward);
    //  rotate in plane that contains vForward&vRight
    T.Yaw=rTurnAngle.Yaw; V=vector(T);
    vForward2=V.X*vForward + V.Y*vRight;
    vRight2=V.X*vRight - V.Y*vForward;
    vUpward2=vUpward;

    // rotate in plane that contains vForward&vUpward
    T.Yaw=rTurnAngle.Pitch; V=vector(T);
    vForward=V.X*vForward2 + V.Y*vUpward2;
    vRight=vRight2;
    vUpward=V.X*vUpward2 - V.Y*vForward2;

    // rotate in plane that contains vUpward&vRight
    T.Yaw=rTurnAngle.Roll; V=vector(T);
    vForward2=vForward;
    vRight2=V.X*vRight + V.Y*vUpward;
    vUpward2=V.X*vUpward - V.Y*vRight;

    T=OrthoRotation(vForward2,vRight2,vUpward2);

   return(T);
}

DefaultProperties
{
	mLCSpeed=1750
	mLifeDuration=2.f
	mDamage=50.f
	mPosOffset=(X=0.f,Y=-30.f,Z=0.f)

	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'Space_Vendors.Meshes.Carrot'
		Materials[0]=Material'goat.Materials.Gloria_Mat_01'
		Scale3D=(X=1.f,Y=4.f,Z=1.f)
		Rotation=(Yaw=-16384)
		bNotifyRigidBodyCollision=true
		ScriptRigidBodyCollisionThreshold=10.0f //if too big, we won't get any notifications from collisions between kactors
		BlockRigidBody=true
	End Object

	Begin Object class=StaticMeshComponent Name=StaticMeshComponent1
		LightEnvironment=MyLightEnvironment
		bUsePrecomputedShadows=FALSE
		StaticMesh=StaticMesh'Space_Vendors.Meshes.Carrot'
		Materials[0]=Material'goat.Materials.Gloria_Mat_01'
		Scale3D=(X=1.f,Y=2.f,Z=1.f)
		bNotifyRigidBodyCollision=false
		CollideActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
	End Object
	Components.Add(StaticMeshComponent1)
	mBarComponent=StaticMeshComponent1

	bCollideActors=true
	bBlockActors=true

	bCallRigidBodyWakeEvents=true

	mHitPawnSoundCue=SoundCue'MMO_IMPACT_SOUND.Cue.IMP_Metal_Fork'
	mHitNonPawnSoundCue=SoundCue'MMO_IMPACT_SOUND.Cue.IMP_Metal_Fork'
	mBreakSound=SoundCue'MMO_IMPACT_SOUND.Cue.IMP_Metal_Key_Cue'

	bStatic=false
	bNoDelete=false
}