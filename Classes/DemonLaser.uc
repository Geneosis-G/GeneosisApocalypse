class DemonLaser extends Actor;

var vector mStartLocation;
var vector mEndLocation;
var bool mDestroyWhenAttackComplete;

var ParticleSystemComponent mLaserBeamPSC;
var ParticleSystem mExplosionParticleTemplate;
var SoundCue mExplosionSound;
var float mDamage;
var float mDamageRadius;
var class<DamageType> mDamageType;
var float mExplosiveMomentum;
var name mBeamSocket;
var float mLaserDuration;

var GGPawn mOwner;

event PostBeginPlay()
{
	super.PostBeginPlay();

	mOwner = GGPawn(Owner);
	mOwner.mesh.AttachComponentToSocket( mLaserBeamPSC, 'grabSocket' );
	mLaserBeamPSC.SetVectorParameter( 'color', vect(255, 0, 0) );
}

function ShootLaser(vector startLocation, vector endLocation)
{
	local int t;

	mStartLocation = startLocation;
	mEndLocation = endLocation;

	mLaserBeamPSC.SetVectorParameter( 'BeamEnd', mEndLocation );
	mLaserBeamPSC.SetVectorParameter( 'beamStart', mStartLocation );

	//t == this many different effets in particle that needs to be edited!
	for( t = 0; t < 6 ; t++ )
	{
		mLaserBeamPSC.SetBeamSourcePoint( t, mStartLocation, 0 );
		mLaserBeamPSC.SetBeamTargetPoint( t, mEndLocation, 0 );
	}

	mLaserBeamPSC.ActivateSystem();

	SetTimer( mLaserDuration, false, NameOf(LaserHit) );
}

function LaserHit()
{
	// Stop laser effect
	mLaserBeamPSC.DeactivateSystem();
	mLaserBeamPSC.SetActive( false );
	// do explosive damages
	WorldInfo.MyEmitterPool.SpawnEmitter(mExplosionParticleTemplate, mEndLocation);
	PlaySound(mExplosionSound,,,, mEndLocation);
	mOwner.HurtRadius( mDamage, mDamageRadius, mDamageType, mExplosiveMomentum, mEndLocation, , mOwner.Controller, true );

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
	if(!IsTimerActive(NameOf(LaserHit)))
	{
		SelfDestroy();
	}
}

function SelfDestroy()
{
	ShutDown();
	Destroy();
}

event Destroyed()
{
	mLaserBeamPSC.DeactivateSystem();
	mLaserBeamPSC.KillParticlesForced();

	super.Destroyed();
}

DefaultProperties
{
	bNoDelete=false
	bStatic=false
	bBlockActors=false
	bCollideActors=false
	Physics=PHYS_None
	CollisionType=COLLIDE_NoCollision

	Begin Object class=ParticleSystemComponent Name=BeamComponent
		Template=ParticleSystem'Space_Particles.Particles.GGFPSpaceCraft_Laser'
		bAutoActivate=false
	End Object
	Components.Add(BeamComponent)
	mLaserBeamPSC=BeamComponent

	mExplosionParticleTemplate=ParticleSystem'Goat_Effects.Effects.Projectile_Explosion_01'
	mExplosionSound=SoundCue'Goat_Sounds.Cue.Explosion_Car_Cue'

	mDamageType=class'GGDamageTypeExplosiveActor'
	mDamage=100
	mDamageRadius=200
	mExplosiveMomentum=50000
	mLaserDuration=0.25f
}