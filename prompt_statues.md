
# Background context
Digest and summarise /Users/johngavin/docs_gh/claude_rix/context.md

# statues_named_john project

This is the system prompt for this project

Build an R package that sources  data about statues in London uk
	Support all the endpoints. 
	Add documentation and tests and make sure it passes check.

Add a vignette to the project compare and contrast memorials honouring
+ men named john v women of any name v dogs (male or female)
+ memorials can include statues or other specific markers
+ add a section summarising all of the data that can be downloaded from londonremembers.com 
+ Vignette tables and plots should include 
	+ type of memorial e.g. statue v plaque v bust
	+ year and decade it was erected
	+ reason for memorial e.g. politican, war hero, artist, scientist, philosopher, writer etc.
	+ location information for mapping
		+ region or postcode
		+ longtitude and latitude 
	+ artist who made the statue and their gender
	+ statues and artists who are people of colour
	+ any other factor that might partition that data
+ name vignetter https://johngavin.github.io/statues_named_john/articles/memorial-analysis.html 

+ Ideally we want a 
	+ database with 
		+ longtitude and latitude information, to include a 
		+ map when outputting results.
+ Exclude statues of mythical or royal people.
+ Summarise results and plan next steps before each stage in overall plan

+ use targets pipelines to generate the vignettes and all of the tables and graphs shown in all vignetters

## Primary sources
+ From a basic websearch
+ Potentially good data sources for statues of men, women or dogs in london, uk
+ https://www.packsend.co.uk/whether-subject-or-artist-uk-publicly-owned-statues-are-very-much-a-mans-world/
	+ https://artuk.org/discover/artworks
		+ https://artuk.org/discover/artworks/view_as/list/search/2025--outdoor_artwork:on--region:englandlondoncentral-london--work_type:sculpturestatue/page/1
	+ "4,912 publicly-owned sculptures were identified using the Art UK online database

		For each sculpture, its title, artist, location and work type were extracted. From this information, 892 sculptures of named individuals were identified.

		Each artist and named individual were assigned a gender. Statues of nameless male and female figures were also assigned a gender. All other statues were classified as ‘unknown’."
+ https://hyperallergic.com/586720/uk-study-women-statues-john-statues/
	+ "In the United Kingdom, public statues of women just barely outnumber those of men named John"
	+ conducted by the shipment company PACK & SEND, analyzed almost 5,000 publicly owned sculptures across the UK using the Art UK online database.
	+ 4,912 statues examined, only 1,470 could be assigned a gender. Of these, less than a quarter were of women (1,119 men and 351 women)
	+ "majority of the statues for women were nameless (64%) whereas most of the statues for men were named (68%). Of the 892 named statues found, only 128 were of women (14%). Now, compare this to the whopping 82 statues of men named John."
	+ "artists who made the public statues in the analysis" ... "majority of them were men: Of 1,914 artists, only 393 were women."
+ https://www.bbc.co.uk/news/uk-43884726
	+ "There were 65 male politicians recorded by the PMSA in public spaces around the UK, and zero female politicians."

## Secondary sources
+	https://www.londonremembers.com/
	+ londonremembers.com doesnt have an api or downloadable csv 
+ e.g. https://en.wikipedia.org/wiki/Museum_Data_Service
	+ includes https://en.wikipedia.org/wiki/Art_UK 
	+ https://museumdata.uk/sharing-data/data-sharing-faqs/
		+ https://rootwebdesign.studio/projects/the-museum-data-service/
			+ Object Search API allows visitors to search over 6 million object records from museums across the UK.
+ e.g. https://museumdata.uk/object-search/?q=statue#filters
+ e.g. https://glher.historicengland.org.uk/search?paging-filter=1
	+ e.g. https://historicengland.org.uk/listing/the-list/results/?search=statue+dog&searchType=NHLE+Simple downloadable as csv at https://historicengland.org.uk/listing/the-list/results/?search=statue+dog&searchType=NHLE+Simple#
	+ such as person statue https://glher.historicengland.org.uk/search?paging-filter=1&tiles=true&format=tilecsv&reportlink=false&precision=6&total=51&term-filter=%5B%7B%22inverted%22%3Afalse%2C%22type%22%3A%22string%22%2C%22context%22%3A%22%22%2C%22context_label%22%3A%22%22%2C%22id%22%3A%22person%20%22%2C%22text%22%3A%22person%20%22%2C%22value%22%3A%22person%20%22%7D%2C%7B%22inverted%22%3Afalse%2C%22type%22%3A%22string%22%2C%22context%22%3A%22%22%2C%22context_label%22%3A%22%22%2C%22id%22%3A%22statue%22%2C%22text%22%3A%22statue%22%2C%22value%22%3A%22statue%22%7D%5D&sort-results=desc
	+ such as Monuments https://glher.historicengland.org.uk/search?paging-filter=1&tiles=true&format=tilecsv&reportlink=false&precision=6&total=180257&resource-type-filter=%5B%7B%22graphid%22%3A%22076f9381-7b00-11e9-8d6b-80000b44d1d9%22%2C%22name%22%3A%22Monument%22%2C%22inverted%22%3Afalse%7D%5D
+ e.g. https://www.heritagegateway.org.uk/
+	e.g. https://artuk.org/ does it have an api or downloadable data?
	londonremembers.com
+	e.g. https://historicengland.org.uk/listing/the-list/results/?page=24&search=monumentType%3A%22Statue%22&searchType=NHLE+Simple
	e.g. / https://historicengland.org.uk/listing/the-list/asset-type-terms/
	e.g. 	historicengland.org.uk data offers:
		List Entry Name,	List Entry, Number,	Link,	Heritage Category,	Grade,	Location
+ https://statuefindr.london/
	+ Westminster only?


+ also digest and add the reference https://statuesforequality.com/pages/london to the vignette.
	- compare and verify to your analysis of data from londonremembers.com
		- https://statuesforequality.com/pages/london claims 
		- "The percentage of women’s statues in the UK that aren’t mythical or royal is approximately 3%, with more statues of statues named John dotted around the country than of women! This puts London, at 6%, double the national average. " 
	
	- compare and verify, to your analysis of data, from londonremembers.com
		- https://artuk.org/discover/stories/revealing-the-facts-and-figures-of-londons-statues-and-monuments
		- This url claims "Perhaps shockingly, there are more sculptures in London depicting animals (8%) than there are of named women (4%)." 
			- is this true according to londonremembers.com or statuesforequality.com?

	- compare your results and cross-check to https://www.weforum.org/stories/2018/08/more-statues-of-everyday-women-are-set-to-be-built-in-the-uk/ 
		- "currently more statues of goats and people called John than of everyday women"
	- compare your results to https://www.newstatesman.com/politics/2016/03/i-sorted-uk-s-statues-gender-mere-27-cent-are-historical-non-royal-women
		- "sorting all the statues in the UK national database of the Public Monuments & Sculpture Association by gender "
		- "826 entries filed under “statue”, which includes a total of 925 statues. Only 158 of those were of women"
		- "woman who actually existed and achieved something in the past. Only 71 statues (that’s 28 per cent of the total female figure) of historical women are listed in the database. Forty-six of those are of royalty – over 50 per cent. Twenty-nine alone are of Queen Victoria."
		- "Women are barely doing better than statues of animals, which number 18 (more if you count all the ones alongside humans, but I leave that task for a sturdier heart than mine)."

