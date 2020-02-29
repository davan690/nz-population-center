# Population-Weighted Center of New Zealand Code

- `make_map.R` contains the code. It requires a google API key to run.

- The output map is `map.png`.

- The `data` folder contains the input data.

	- The `2001-part1-mb01-curpc91-96-01.xlsx` file contains Stats NZ population data from the 1991, 1996 and 2001 census at the 2001 meshblock level.
	- The `2018-sa1-curpc.xlsx` file contains Stats NZ population data from the 2006, 2013 and 2018 census at the 2018 statistical area 1 level.
	- The `statsnzmeshblock-2001-SHP` folder should contain the shapefiles defining the 2001 meshblocks. These are not included in the repository for size reasons, but can be downloaded from [here](https://datafinder.stats.govt.nz/layer/25744-meshblock-2001/).
	- The `statsnzstatistical-area-1-2018-generalised-SHP` folder should contain the shapefiles defining the 2018 statistical areas. These are not included in the repository for size reasons, but can be downloaded from [here](https://datafinder.stats.govt.nz/layer/92210-statistical-area-1-2018-generalised/).

