class SatanCircle extends DemonCircle;

function bool IsAffectedByCircle(GGNpc npc)
{
	return npc.Controller != none;
}

function AddToCircle(GGNpc npc)
{
	super.AddToCircle(npc);

	class'ApocalypseMutator'.static.KillNpc(npc);
}

DefaultProperties
{
	mSummonerClass=none
	mCancelRitualIfNoTargetInCircle=false;
	mCircleTimeout=10.f
	mReadyTime=0.f
}