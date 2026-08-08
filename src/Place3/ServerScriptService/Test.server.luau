local gen = require(script.Parent.Generation)
local rules : gen.Rules = {
	DeadEnds = true,
	MaxSectionPerDeadEnd = 7,
	Forks = true,
	ForkEvery_Sections = 8,
	MaxFloors = 4,
	MinFloors = 2,
	MaxStriaghtsInARow = 1
}
