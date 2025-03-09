class GGNpcAngelGoat extends GGNpcApocalypseGoat
	placeable;

var SkeletalMeshComponent mHaloMesh;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	mHaloMesh.SetLightEnvironment( mesh.LightEnvironment );
	mesh.AttachComponentToSocket( mHaloMesh, 'haloSocket' );
}

function string GetActorName()
{
	return (Controller == none ? "Dead ":"") $ "Angel Goat";
}

DefaultProperties
{
	Begin Object name=WPawnSkeletalMeshComponent
		Materials(0)=Material'goat.Materials.Goat_Mat_03'
	End Object

	Begin Object class=SkeletalMeshComponent Name=haloMesh
		SkeletalMesh=SkeletalMesh'goat.Mesh.Gloria_01'
	End Object
	mHaloMesh=haloMesh
}