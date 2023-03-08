# fingertipsR

selection of code using fingertips via the fingertipsR package & from the API direct

Note: indicator ID is not unique in fingertips. The same indicator ID may produce multiple values if the indicator is avaialble seperately (most commonly) by sex & age.

Downloading the data makes more sense if used together with the website as many things that seem odd are to do with the web layout https://fingertips.phe.org.uk/
API is here: https://fingertips.phe.org.uk/api

Indicators are downloaded from profiles, the same indicator may appear in more than one profile. Profiles also contain groups which are the pages in the web version of the profile. You don't need the group to download but can be useful for structuring if you're using many indicators from the same profile.

all areas have parent areas, may need to get an area as a parent area & filter out unwanted child area (e.g. if want both region & combined authority)
AreaTypeID = 402 = UTLA (upper tier local authority) with boundary changes post Apr 2021
