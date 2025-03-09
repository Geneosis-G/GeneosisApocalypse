class AngelCircle extends RitualCircle;

// Override in child to do the ritual effect on targets
function DoRitualFor(GGNpc npc)
{
	local vector spawnLoc;
	local GGNpcAngelGoat newAngel;

	if(npc.Controller != none)
		return;

	// Resurrect angels
	if(GGNpcAngelGoat(npc) != none)
	{
		npc.StandUp();
		npc.SpawnDefaultController();
	}
	// Turn demons into angels
	else if(GGNpcDemonGoat(npc) != none)
	{
		spawnLoc = class'ApocalypseMutator'.static.GetPawnPosition(npc);
		spawnLoc.Z += npc.GetCollisionHeight();
		EraseActor(npc);

		newAngel = Spawn( class'GGNpcAngelGoat',,, spawnLoc, GetRandomRotation(),,true);
		if(newAngel != none)
		{
			newAngel.SetPhysics( PHYS_Falling );
		}
	}
	// Resurrect NPCs as passive
	else
	{
		MakePassive(npc);
	}
}

function MakePassive(GGNpc npc)
{
	local GGAIController contr;
	local class<Controller> contrClass;
	local GGNpcMMOAbstract MMONpc;
	local GGNpcZombieGameModeAbstract zombieNpc;
	local int deathLimit;

	if(PlayerController(npc.Controller) != none)
		return;

	contr = GGAIController(npc.Controller);
	if( contr != none )
	{
		contr.UnPossess();
		contr.ShutDown();
		contr.Destroy();
	}

	MMONpc = GGNpcMMOAbstract(npc);
	zombieNpc = GGNpcZombieGameModeAbstract(npc);
	npc.EnableStandUp( class'GGNpc'.const.SOURCE_EDITOR );
	npc.mTimesKnockedByGoat=0;
	deathLimit = class'ApocalypseMutator'.default.mDeathLimit;
	if(npc.mTimesKnockedByGoatStayDownLimit > deathLimit || npc.mTimesKnockedByGoatStayDownLimit <= 0)
	{
		npc.mTimesKnockedByGoatStayDownLimit = deathLimit;
	}
	if(MMONpc != none)
	{
		MMONpc.mHealth=max(MMONpc.default.mHealthMax, MMONpc.default.mHealth);
		MMONpc.LifeSpan=MMONpc.default.LifeSpan;
		MMONpc.mNameTagColor=MMONpc.default.mNameTagColor;
	}
	if(zombieNpc != none)
	{
		zombieNpc.mHealth=zombieNpc.default.mHealthMax;
		zombieNpc.mIsPendingDeath=false;
	}

	contrClass = static.IsHuman(npc)?class'GGAIController':class'GGAIControllerPassiveGoat';
	npc.Controller = Spawn(contrClass);

	if( npc.Controller != None )
	{
		npc.Controller.Possess( npc, false );
		contr = GGAIController(npc.Controller);
		contr.StandUp();
		contr.ClearTimer('ReturnToOriginalPosition');
		contr.ReturnToOriginalPosition();
	}
}

static function bool IsHuman(GGPawn gpawn)
{
	local GGAIControllerMMO AIMMO;

	if(InStr(string(gpawn.Mesh.PhysicsAsset), "CasualGirl_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "CasualMan_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "SportyMan_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "HeistNPC_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "Explorer_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "SpaceNPC_Physics") != INDEX_NONE)
	{
		return true;
	}
	AIMMO=GGAIControllerMMO(gpawn.Controller);
	if(AIMMO == none)
	{
		return false;
	}
	else
	{
		return AIMMO.PawnIsHuman();
	}
}

DefaultProperties
{
	mSummonerClass=class'GGNpcAngelGoat'
	mCircleHaloTemplate=ParticleSystem'MMO_Effects.Effects.Effects_Glow_01'
	mCompletionSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Level_Up_Cue'
	mCompletionEffect=ParticleSystem'MMO_Effects.Effects.Effects_Levelup_01'

	Begin Object name=StaticMeshComponent0
		Materials[0]=Material'MMO_Effects.Materials.Questarea_Mat_03'
	End Object

	Begin Object class=StaticMeshComponent Name=StaticMeshComponent1
		StaticMesh=StaticMesh'Goat_Effects.mesh.Lightbeam_01'
		Scale3D=(X=20.0f,Y=20.0f,Z=32.0f)
		Materials(0)=MaterialInstanceConstant'Goat_Effects.Materials.UFO_LightBeam_01'
		Translation=(X=0.0f,Y=0.0f,Z=4000.0f)
	End Object
	Components.Add(StaticMeshComponent1)
}