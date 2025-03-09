class GGNpcApocalypseGoat extends GGNpcGoat
	placeable;

simulated event PostBeginPlay()
{
	if(Controller == none)
	{
		SpawnDefaultController();
	}
}

simulated function StopBaa()
{
	super.StopBaa();

	if(GGAIControllerApocalypse(Controller) != none)
	{
		GGAIControllerApocalypse(Controller).OnStopBaa();
	}
}

function bool IsImmune()
{
	return GGAIControllerApocalypse(Controller) != none;
}

function OnRitualEnded()
{
	if(GGAIControllerApocalypse(Controller) != none)
	{
		GGAIControllerApocalypse(Controller).OnRitualEnded();
	}
}

DefaultProperties
{
	ControllerClass=class'GGAIControllerApocalypse'

	mTimesKnockedByGoatStayDownLimit=5
	mStandUpDelay=1.0f

	mDefaultAnimationInfo=(AnimationNames=(Idle),AnimationRate=1.0f,MovementSpeed=0.0f,SoundToPlay=())
	mAttackAnimationInfo=(AnimationNames=(Baa),AnimationRate=1.0f,MovementSpeed=0.0f,SoundToPlay=())
	mPanicAnimationInfo=(AnimationNames=(Sprint),AnimationRate=1.0f,MovementSpeed=700.0f,LoopAnimation=true,SoundToPlay=())
	mAngryAnimationInfo=(AnimationNames=(Idle),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=true,SoundToPlay=())

	GroundSpeed  = 700
	AirSpeed  = 700
	WaterSpeed  = 700
	LadderSpeed  = 700
	JumpZ = 650

	SightRadius=5000.f

	mAttackRange=400.0f;
	mBaaSoundCue=none
}