class GodCircle extends AngelCircle;

function bool IsAffectedByCircle(GGNpc npc)
{
	return npc.Controller.class != class'GGAIController' && npc.Controller.class != class'GGAIControllerPassiveGoat';
}

function AddToCircle(GGNpc npc)
{
	super.AddToCircle(npc);

	MakePassive(npc);
}

DefaultProperties
{
	mSummonerClass=none
	mCancelRitualIfNoTargetInCircle=false;
	mCircleTimeout=10.f
	mReadyTime=0.f
}