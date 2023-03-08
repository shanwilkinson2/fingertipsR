# directorate performance reporting. 

# load packages
  library(fingertipsR)
  library(dplyr)
  library(readr)
  library(lubridate)
  
# # # get a list of all live indicators
#   fingertips_live_indicators <- fingertipsR::indicators()
#   write.csv(fingertips_live_indicators, "fingertips_live_indicators.csv")
  
# details of just wanted indicators
  # my_live_indicators <- fingertips_live_indicators[fingertips_live_indicators$IndicatorID %in% wanted_indicators,]
  
  # list of wanted indicators & areas
  wanted_indicators_df <- data.frame(IndicatorID = c(93085, 92517, 93014, 90366, 90282, 22401, 40401, 30314),
                                     indicatorName = c("SATOD", "breastfeeding 6-8wks", "physically active adults", 
                                                       "life expectancy at birth", "gap betw employment rate LTC & overall", 
                                                       "emerg hosp admissions falls age 65+", "U75 mortality rate all CVD", 
                                                       "flu vaccination 65+"),
                                     indicatororder = c(1, 2, 3, 4, 5, 6, 7, 8),
                                     ProfileID = c(19, 19, 19, 19, 19, 19, 19, 19))
  
  wanted_areacodes_df <- data.frame(AreaCode = c("E08000001", "E92000001", "E12000002", "E47000001"), 
                                    areaname = c("Bolton", "England", "NW", "GM"))
  
  NN <- nearest_neighbours(AreaCode = wanted_areacodes_df$AreaCode[1], # CIPFA nearest neighbours to Bolton
                           AreaTypeID = 102, # LA district/ unitary
                           measure = "CIPFA")
  
# download data 
  # Get data for Bolton, GM combined authority and England 
  phof_data <- fingertips_data(IndicatorID = wanted_indicators_df$IndicatorID, ProfileID = 19, AreaTypeID = 102,
                               ParentAreaTypeID = 126, rank = TRUE) %>%
    filter(AreaCode %in% c("E08000001", "E47000001", "E92000001"))
  
  # Get data for the North West (former GOR)
  phof_data_NW <- fingertips_data(IndicatorID = wanted_indicators_df$IndicatorID, ProfileID = 19, AreaTypeID = 102,
                                  ParentAreaTypeID = 6, rank = TRUE) %>%
    filter(AreaCode=="E12000002")
  
# Combine the two data frames containing the required area types (phof_data and phof_data_NW).
  # To make this easier, first change the name of column 23 which will be different in these two data frames.
  # I used the following line to identify columns with different names:
  # namecheck <- names(phof_data) == names(phof_data_NW)
  # The following lines changes the name of column 23. In the combined data frame this column
  # will only contain a comparison to the parent combined authority (if available) so the
  # new column name is ComparedtoParentCA
  phof_data <- phof_data %>%
    rename(ComparedtoParentCA=ComparedtoCombinedauthoritiesvalueorpercentiles)
  
  phof_data_NW <- phof_data_NW %>%
    rename(ComparedtoParentCA=ComparedtoRegionvalueorpercentiles)
  
  # The two data frames now have identical column names and so they can be merged.
  # Previous phof_data data frame is overwritten by a new merged data frame with the same name. 
  phof_data <- rbind(phof_data, phof_data_NW)
  
  # # Re-sort the rows by indicator
  # phof_data <- phof_data %>%
  #   arrange(factor(IndicatorID, levels = wanted_indicators_df$IndicatorID), TimeperiodSortable, factor(AreaCode, levels = area_code_sort_order)) %>%
  #   mutate(AreaName=if_else(AreaName=="North West region", "NW", if_else(AreaName=="CA-Greater Manchester", "GM", AreaName)))

  # remove phof_data_NW as no longer needed
    rm(phof_data_NW)

# filters    
    # get latest time period only
    phof_data <- phof_data %>%
      group_by(IndicatorID, AreaCode, Sex) %>%
      filter(TimeperiodSortable == max(TimeperiodSortable)) %>%
      arrange(IndicatorID, Sex, AreaCode)

    # get rid of male/ female where persons is available
    # get rid of other age groups from physically active adults
        # 93085 = smoking at time of delivery, female only 
        # 90366 = life expectancy, m/ f only no persons
        # 93014 = physically active adults, comes in multiple age groups
    phof_data <- phof_data %>%
      filter(IndicatorID %in% c(90366, 93085) | Sex == "Persons")  %>%
      filter(!(IndicatorID == 93014 & Sex == "Persons" & Age != "19+ yrs")) %>%
      arrange(IndicatorID, Sex, AreaCode)
 
# # count what's filtered out
#   phof_data2 %>%
#     group_by(IndicatorID, IndicatorName, Sex, Age) %>%
#     summarise(n()) %>%
#   View()
# 
#   phof_data2 %>%
#     group_by(IndicatorID) %>%
#     summarise(n()) %>%
#     View()
#     
  

# save file
    write_csv(phof_data, paste0("phof_data_", ymd(today()), ".csv"))

