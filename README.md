# fingertipsR

selection of code using fingertips via the fingertipsR package & from the API direct

Note: indicator ID is not unique in fingertips. The same indicator ID may produce multiple values if the indicator is avaialble seperately (most commonly) by sex & age.

Makes more sense if used together with the website (e.g. group id's reflect pagination) https://fingertips.phe.org.uk/
API is here: https://fingertips.phe.org.uk/api

all areas have parent areas, may need to get an area as a parent area & filter out unwanted child area (e.g. if want both region & combined authority)
AreaTypeID = 402 = UTLA (upper tier local authority) with boundary changes post Apr 2021
