local generator = {}
export type Rules = {
	DeadEnds : boolean,
	MaxSectionPerDeadEnd : number?,
	DeadEndPerSectionEndChance : number,
	MaxStriaghtsInARow : number?,
	
	Forks : boolean,
	ForksDeadEndChance : number?,
	ForkReconnectChance : number?,
	ForkEvery_Sections : number?,
	MinSectionAfterFork : number?,
	
	MultiFloor : boolean,
	MaxFloors : number?,
	MinFloors : number?,
}
return generator
