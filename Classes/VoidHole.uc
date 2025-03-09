//-----------------------------------------------------------
//
//-----------------------------------------------------------
class VoidHole extends GGBlackHoleActor
	placeable;

/**
  *	Checks if any actor is near the center of the black hole.
  */
function CheckActorsInBlackHole()
{
	local GGSVehicle hitVehicle;
	local GGInterpActor hitInterp;

	super.CheckActorsInBlackHole();

	foreach OverlappingActors( class'GGSVehicle', hitVehicle, CylinderComponent( CollisionComponent ).CollisionHeight, Location )
	{
		AddAbsorbingActor( hitVehicle );
	}

	foreach OverlappingActors( class'GGInterpActor', hitInterp, CylinderComponent( CollisionComponent ).CollisionHeight, Location )
	{
		AddAbsorbingActor( hitInterp );
	}
}

/**
  *	Removes the first actor which entered the black hole.
  */
function AbsorbActor()
{
	local GGSVehicle vehicle;
	local int i, attachmentCount;

	vehicle = GGSVehicle( mActorsBeingAbsorbed[0] );
	if( vehicle != none )
	{
		vehicle.KickOutDriver();
		KickOutPassengers(vehicle);
	}
	if(vehicle != none || GGInterpActor(mActorsBeingAbsorbed[0]) != none)
	{
		attachmentCount = mActorsBeingAbsorbed[ 0 ].Attached.length;

		if( attachmentCount > 0 )
		{
			for ( i = attachmentCount-1; i >= 0; i-- )
			{
				if( mActorsBeingAbsorbed[ 0 ].Attached[ i ] != none )
				{
					mActorsBeingAbsorbed[ 0 ].Attached[ i ].ShutDown();
					mActorsBeingAbsorbed[ 0 ].Attached[ i ].Destroy();
				}
			}
		}
		mActorsBeingAbsorbed[ 0 ].ShutDown();
		mActorsBeingAbsorbed[ 0 ].Destroy();
	}

	super.AbsorbActor();
}

/**
 * Kick out all the passengers
 */
function KickOutPassengers(GGSVehicle vehicle)
{
	local int i;
	local bool couldKickOutPassenger;
	local GGPawn passengerPawn;

	for( i = 0; i < vehicle.mPassengerSeats.Length; i++ )
	{
		if( vehicle.mPassengerSeats[ i ].PassengerPawn != none  )
		{
			passengerPawn = vehicle.mPassengerSeats[ i ].PassengerPawn;

			couldKickOutPassenger = vehicle.mPassengerSeats[ i ].VehiclePassengerSeat.DriverLeave( true );

			if( couldKickOutPassenger )
			{
				passengerPawn.SetRagdoll( true );
			}
		}
	}
}

DefaultProperties
{
	mBlackHoleRadiusMax=5000
	mLifeTime=5.0f
}