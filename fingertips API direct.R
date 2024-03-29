library(dplyr)
library(data.table)

# gets indicator details direct from API as fingertipsR is no longer on cran

# indicators come as a profile & each profile contains groups (ie dropdown on the profile on the website to change pages)
# indicator group names & numbers for profile 143 (local health)
    local_health_metadata <- httr::GET("https://fingertips.phe.org.uk/api/profile?profile_id=143")$content %>%
      rawToChar() %>%
      jsonlite::fromJSON(flatten = TRUE) %>%
      .$GroupMetadata %>%
      select(Id, Name)
    
    # get group metadata direct from API using group id's obtained from above
    local_health_group_metadata <- httr::GET("https://fingertips.phe.org.uk/api/indicator_names/by_group_id?group_ids=1938133180%2C%201938133183%2C1938133184%2C1938133185")$content %>%
      rawToChar() %>%
      jsonlite::fromJSON(flatten = TRUE)
    
    local_health_indicators <- local_health_group_metadata %>%
      left_join(local_health_metadata, by = c("GroupId" = "Id")) %>%
      rename(DomainName = Name) %>%
      relocate(DomainName, .after = "GroupId")
    
    # remove unjoined file
    rm(local_health_metadata)
    rm(local_health_group_metadata)
    
   # get borough local health data
    local_health_borough <- fread("https://fingertips.phe.org.uk/api/all_data/csv/by_profile_id?child_area_type_id=402&parent_area_type_id=3&profile_id=143&parent_area_code=E08000001") %>%
      janitor::clean_names(case = "upper_camel") # upper camel case used in API json output & fingertipsR

    # get all msoas local health data - takes a bit of a while
        local_health_all_msoa <- fread("https://fingertips.phe.org.uk/api/all_data/csv/by_profile_id?child_area_type_id=3&parent_area_type_id=15&profile_id=143") %>%
          janitor::clean_names(case = "upper_camel") # upper camel case used in API json output & fingertipsR

    # filter just bolton
    local_health_bolton_msoa <- local_health_all_msoa %>%
      filter(stringr::str_detect(AreaName, "^Bolton") & AreaType == "MSOA")

  # join msoa & borough data
    local_health <- bind_rows(local_health_bolton_msoa, local_health_borough)
