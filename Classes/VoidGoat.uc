class VoidGoat extends GGMutator
	config(Geneosis);

var config bool isVoidGoatUnlocked;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	//Function not called on custom mutators for now so this is not working
	return default.isVoidGoatUnlocked;
}

/**
 * Unlock the mutator
 */
static function UnlockVoidGoat()
{
	if(!default.isVoidGoatUnlocked)
	{
		PostJuice( "Unlocked void Goat" );
		default.isVoidGoatUnlocked=true;
		static.StaticSaveConfig();
	}
}

function static PostJuice( string text )
{
	local GGGameInfo GGGI;
	local GGPlayerControllerGame GGPCG;
	local GGHUD localHUD;

	GGGI = GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game );
	GGPCG = GGPlayerControllerGame( GGGI.GetALocalPlayerController() );

	localHUD = GGHUD( GGPCG.myHUD );

	if( localHUD != none && localHUD.mHUDMovie != none )
	{
		localHUD.mHUDMovie.AddJuice( text );
	}
}

defaultproperties
{
	mMutatorComponentClass=class'VoidGoatComponent'
}