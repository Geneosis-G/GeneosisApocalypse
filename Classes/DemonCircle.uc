class DemonCircle extends RitualCircle;

var PentagramDecal mPentagram;

event PostBeginPlay()
{
	super.PostBeginPlay();

	mPentagram = Spawn(class'PentagramDecal', self,, Location, Rotator(vect(0, 0, -1)));
	mPentagram.SetBase(self);
}

// Override in child to do the ritual effect on targets
function DoRitualFor(GGNpc npc)
{
	local vector spawnLoc;
	local GGNpcDemonGoat newDemon;

	if(npc.Controller != none)
		return;

	// Destroy angels
	if(GGNpcAngelGoat(npc) != none)
	{
		EraseActor(npc);
	}
	// Revive demons
	else if(GGNpcDemonGoat(npc) != none)
	{
		npc.StandUp();
		npc.SpawnDefaultController();
	}
	// Trun NPCs into demons
	else
	{
		spawnLoc = class'ApocalypseMutator'.static.GetPawnPosition(npc);
		spawnLoc.Z += npc.GetCollisionHeight();
		EraseActor(npc);

		newDemon = Spawn( class'GGNpcDemonGoat',,, spawnLoc, GetRandomRotation(),,true);
		if(newDemon != none)
		{
			newDemon.SetPhysics( PHYS_Falling );
		}
	}
}

event Destroyed()
{
	if(mPentagram != none)
	{
		mPentagram.ShutDown();
		mPentagram.Destroy();
	}

	super.Destroyed();
}

DefaultProperties
{
	mSummonerClass=class'GGNpcDemonGoat'
	mCircleHaloTemplate=ParticleSystem'Goat_Effects.Effects.DemonicPower'
	mCompletionSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Demon_Spawn_Explosion_Cue'
	mCompletionEffect=ParticleSystem'Goat_Effects.Effects.Effects_Explosion_Car_01'

	Begin Object name=StaticMeshComponent0
		Materials[0]=Material'MMO_Effects.Materials.Questarea_Mat_01'
	End Object
}