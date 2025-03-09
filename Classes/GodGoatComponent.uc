class GodGoatComponent extends ApocalypseGoatComponent;

var Material mGodMaterial;
var HeavenGate mHeavenGate;

function DetachFromPlayer()
{
	if(mHeavenGate != none)
	{
		mHeavenGate.SelfDestroy();
		mHeavenGate = none;
	}
	super.DetachFromPlayer();
}

function SetGoatSkin()
{
	local int i;

	if(gMe.mesh.PhysicsAsset == class'GGGoat'.default.mesh.PhysicsAsset)
	{
		for(i=0 ; i<gMe.mesh.GetNumElements() ; i++)
		{
			gMe.mesh.SetMaterial( i, mGodMaterial );
		}
	}
}

function LinearColor GetCrosshairColor()
{
	return MakeLinearColor( 255.f/255.f, 255.f/255.f, 255.f/255.f, 1.0f );
}

simulated event TickMutatorComponent( float delta )
{
	super.TickMutatorComponent(delta);

	if(mHeavenGate == none || mHeavenGate.bPendingDelete)
	{
		mHeavenGate = gMe.Spawn(class'HeavenGate', gMe);
		mHeavenGate.SetHidden(true);
		mHeavenGate.mAutoCloseGate = false;
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PlayerController( gMe.Controller ).PlayerInput );

	super.KeyState(newKey, keyState, PCOwner);

	if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed("LeftMouseButton", string( newKey )) || newKey == 'XboxTypeS_RightTrigger')
		{
			CloseGate();
		}
	}
}

function StartShooting()
{
	super.StartShooting();

	mHeavenGate.OpenGateOnTarget(vect(0, 0, 0), mCrosshairActor);
}

function CloseGate()
{
	if(!mIsShooting || mHeavenGate.mIsClosing)
		return;

	mHeavenGate.CloseGate();
	myMut.SetTimer( mHeavenGate.mCloseAnimDuration, false, NameOf(StopShooting), self );
}

DefaultProperties
{
	mCircleClass = class'GodCircle'
	mGodMaterial = Material'goat.Materials.Goat_Mat_03'
}