class VoidCircle extends RitualCircle;

struct BlinkingActor {
	var Actor act;
	var int blinkCount;
	var int framesWithoutTP;
};

var VoidCircle mLinkedPortal;
var array<BlinkingActor> mBlinkingActors;
var float mBlinkBoost;
var int mMaxCountForBlink;
var int mMaxFramesWithoutTP;

event Tick( float DeltaTime )
{
	local Actor tmpAct;
	local vector vel, pos, newVelocity, newLocation, actToCenter, actToCenterN, actFacingN;
	local float angle;

	if(mLinkedPortal == none)
		return;

	// Find actors in circle
	foreach CollidingActors(class'Actor', tmpAct, mRadius, Location, true)
	{
		if(GGGrabbableActorInterface(tmpAct) != none)
		{
			// if actor moving torward circle center or down
			vel = GetActorVelocity(tmpAct);
			pos = class'ApocalypseMutator'.static.GetActorPosition(tmpAct);
			actToCenter = Location - pos;
			actToCenterN = Normal(actToCenter);
			actFacingN = Normal(vel);
			angle = Acos(actToCenterN dot actFacingN) * 180/pi;
			//WorldInfo.Game.Broadcast(self, tmpAct $ " angle=" $ angle);
			if(!IsZero(vel) && angle < 90.f)
			{
				//Detect blinking

				//WorldInfo.Game.Broadcast(self, tmpAct $ " shold teleport");
				//Compute new location and velocity
				newLocation = mLinkedPortal.Location + actToCenter;
				newLocation.Z = mLinkedPortal.Location.Z + abs(actToCenter.Z);
				newVelocity = vel;
				// Apply boost to prevent objects from blinking too much
				if(IsBlinking(tmpAct))
				{
					newVelocity += actToCenterN * mBlinkBoost;
				}
				if(newVelocity.Z < 0)
				{
					newVelocity.Z *= -1.f;
				}
				SetActorLocationAndVelocity(tmpAct, newLocation, newVelocity);
			}
		}
	}
	AddFrame();
}

function bool IsBlinking(Actor act)
{
	local BlinkingActor newBA;
	local int index;
	// See if the same actor teleported one or 2 frames ago
	index = mBlinkingActors.Find('act', act);
	if(index != INDEX_NONE)
	{
		mBlinkingActors[index].blinkCount++;
		mBlinkingActors[index].framesWithoutTP = 0;
	}
	else
	{
		newBA.act = act;
		newBA.blinkCount = 1;
		newBA.framesWithoutTP = 0;
		index = mBlinkingActors.Length;
		mBlinkingActors.AddItem(newBA);
	}

	//WorldInfo.Game.Broadcast(self, act $ " Blink count=" $ mBlinkingActors[index].blinkCount $ ", Frame count=" $ mBlinkingActors[index].framesWithoutTP);
	//if(mBlinkingActors[index].blinkCount >= mMaxCountForBlink)
	//{
	//	WorldInfo.Game.Broadcast(self, "Blinking actor detected: " $ act);
	//}

	return mBlinkingActors[index].blinkCount >= mMaxCountForBlink;
}

function AddFrame()
{
	local int i;

	for(i=0 ; i<mBlinkingActors.Length ; i=i)
	{
		mBlinkingActors[i].framesWithoutTP++;
		//WorldInfo.Game.Broadcast(self, mBlinkingActors[i].act $ " AddFrame=" $ mBlinkingActors[i].framesWithoutTP);
		if(mBlinkingActors[i].framesWithoutTP >= mMaxFramesWithoutTP)
		{
			mBlinkingActors.Remove(i, 1);
		}
		else
		{
			i++;
		}
	}
}

function vector GetActorVelocity(Actor act)
{
	local vector vel;
	local PrimitiveComponent comp;

	vel = act.Velocity;
	//WorldInfo.Game.Broadcast(self, act $ " velocity=" $ vel $ " size=" $ VSize(vel));
	if(act.Physics == PHYS_RigidBody)
	{
		comp = Pawn(act) != none ? Pawn(act).mesh : act.CollisionComponent;
		vel = comp.GetRBLinearVelocity();
		//WorldInfo.Game.Broadcast(self, act $ " RBvelocity=" $ vel $ " size=" $ VSize(vel));
	}

	return vel;
}

function SetActorLocationAndVelocity(Actor act, vector loc, vector vel)
{
	local EPhysics targetPhysics;
	local PrimitiveComponent comp;

	//Fix teleport issues
	act.bCanTeleport=true;
	act.bBlocksTeleport=false;

	// Set physics
	targetPhysics=act.Physics;
	act.SetPhysics(PHYS_None);

	// do the teleport
	act.SetLocation(loc);
	comp = Pawn(act) != none ? Pawn(act).mesh : act.CollisionComponent;
	if(targetPhysics == PHYS_RigidBody)
	{
		comp.SetRBPosition(loc);
	}

	// Reset physics
	act.SetPhysics(targetPhysics);

	// Set RB velocity after going back to RB physics
	act.Velocity = vel;
	if(act.Physics == PHYS_RigidBody)
	{
		// Little boost to velocity to make sure that the copse will go out of the portal
		comp.SetRBLinearVelocity(vel);
		//WorldInfo.Game.Broadcast(self, act $ " expected Velocity=" $ vel $ " actual Vecloity=" $ comp.GetRBLinearVelocity());
	}
}

function LinkPortals(VoidCircle otherPortal)
{
	mLinkedPortal = otherPortal;
	otherPortal.mLinkedPortal = self;
}

DefaultProperties
{
	mSummonerClass=none
	mCancelRitualIfNoTargetInCircle=false;
	mCircleTimeout=0.f
	mReadyTime=0.f
	mBlinkBoost=100.f
	mMaxCountForBlink=5
	mMaxFramesWithoutTP=10

	Begin Object name=StaticMeshComponent0
		Materials[0]=Material'MMO_Effects.Materials.Questarea_Mat_03'
	End Object

	Begin Object class=StaticMeshComponent Name=StaticMeshComponent1
		StaticMesh=StaticMesh'Zombie_Craftable_Items.Meshes.Crystal_Ball'
		Scale3D=(X=82.f,Y=82.f,Z=0.01f)
		Materials[0]=Material'Space_Particles.Materials.Black_Hole'
		bNotifyRigidBodyCollision=false
		CollideActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
	End Object
	Components.Add(StaticMeshComponent1)
}