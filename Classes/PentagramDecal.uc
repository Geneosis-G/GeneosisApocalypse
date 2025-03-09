class PentagramDecal extends DecalActorMovable;

DefaultProperties
{
	Begin Object Name=NewDecalComponent
		DecalMaterial=DecalMaterial'Ritual.Materials.Decal'
		Orientation=(Pitch=16384,Yaw=0,Roll=0)
		Width=500.f//868.75f
		Height=500.f//868.75f
		FarPlane=968.75f
		LightingChannels=(Dynamic=true)
		bProjectOnBackfaces=false
		bProjectOnBSP=true
		bProjectOnHidden=false
		bProjectOnSkeletalMeshes=false
		bProjectOnStaticMeshes=true
		bProjectOnTerrain=true
	End Object

	bStatic=false
	bNoDelete=false
	bIgnoreBaseRotation=true
}