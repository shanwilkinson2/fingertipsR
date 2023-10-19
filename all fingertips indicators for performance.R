# all fingertips indicators 
# gets indicator details direct from API as fingertipsR is no longer on cran

# load packages
  library(dplyr)
  library(data.table)
  library(jsonlite)
  library(httr)
  library(purrr)
  library(tidyr)

# AreaTypeId which includes Bolton
  # CCG id: 
    # 154 (CCGs (2018/19))
    # 165 (CCGs (2019/20))
    # 166 (CCGs (2020/21))
    # 167 (CCGs (from Apr 2021)) 
    # 66 (Sub-ICB, former CCGs)
  # unitary & UTLA: 
    # 102 (Upper tier local authorities (pre 4/19))
    # 202 (Upper tier local authorities (4/19 - 3/20))
    # 302 (Upper tier local authorities (4/20-3/21))
    # 402 (Upper tier local authorities (4/21-3/23))
    # 502 (Upper tier local authorities (post 4/23))
  # unitary & LTLA
    # 101 (Districts & UAs (pre Apr 2019))
    # 201 (Lower tier local authorities (4/19 - 3/20))
    # 301 (Lower tier local authorities (4/20-3/21))
    # 401 (Districts & UAs (2021/22-2022/23))
    # 501(Lower tier local authorities (post 4/23))

  selected_area_types <- data.frame(
    AreaTypeId = c(
    154, 165, 166, 167, 66, 
    102, 202, 302, 402, 502,
    101, 201, 301, 401, 501
    ),
    AreaTypeName = factor(c(
      "CCG", "CCG", "CCG", "CCG", "ICB sub-region",
      "UTLA", "UTLA", "UTLA", "UTLA", "UTLA",
      "LTLA", "LTLA", "LTLA", "LTLA", "LTLA"
    ), levels = c("CCG", "ICB sub-region", "LTLA", "UTLA")),
    # order of preference - UTLA > LTLA > ICB sub-region > CCG 
    # latest to earliest within the categories
    AreaTypeOrder = c(  
      15, 14, 13, 12, 11,
      5, 4, 3, 2, 1,
      10, 9, 8, 7, 6
    )
  )

# list of all metadata avialable for all indicators 
    # heavily nested
  all_metadata <- GET("https://fingertips.phe.org.uk/api/indicator_metadata/all?include_definition=yes")$content %>%
    rawToChar() %>%
    fromJSON(flatten = TRUE)
   
# get list of all indicators available                      
  all_indicators <- GET("https://fingertips.phe.org.uk/api/available_data")$content %>%
    rawToChar() %>%
    fromJSON(flatten = TRUE)  

# get list of all area types
  area_types <- GET("https://fingertips.phe.org.uk/api/area_types")$content %>%
    rawToChar()%>%
    fromJSON(flatten = TRUE)

# see if can get Bolton for indicators 
  all_indicators2 <- left_join(all_indicators, area_types, by = c("AreaTypeId" = "Id")) %>%
    mutate(bolton = ifelse(AreaTypeId %in% selected_area_types$AreaTypeId, 1, 0)) %>%
    group_by(IndicatorId) %>%
    mutate(bolton_available = max(bolton))

# check those not picked up at Bolton level
  all_indicators2 %>%
    filter(bolton_available == 0) %>%
    View()

# get indicator with its best geography for Bolton, from lowest AreaTypeOrder
 all_indicators2b <- all_indicators2 %>% 
   filter(bolton == 1) %>%
   left_join(selected_area_types, by = "AreaTypeId") %>%
   group_by(IndicatorId) %>%
   mutate(best_area_num = min(AreaTypeOrder))

 # just the best level
  all_indicators3 <- all_indicators2b %>%  
   filter(AreaTypeOrder == best_area_num)
 
 ## get indicator names
 
 test_meta <- GET("https://fingertips.phe.org.uk/api/indicator_metadata/all")$content %>%
   rawToChar() %>%
   fromJSON(flatten = TRUE)  
 
 test_meta2 <- map_df(.x = test_meta, .f = ~.x$Descriptive$Name) 
 test_meta2 <- test_meta2%>%
   tidyr::pivot_longer(cols = 1:ncol(test_meta2), 
                       names_to = "Id", 
                       values_to = "Description"
   ) %>%
   mutate(Id = as.numeric(Id))
 
 
# list of indicators & area to pull
 
 all_indicators_bolton <- all_indicators3 %>%
   select(1:2, area_type = AreaTypeName) %>%
   ungroup()  %>%
   mutate(
     area_code = case_when(
       area_type %in% c("UTLA", "LTLA") ~"E08000001",
       area_type == "CCG" ~"E38000016",
       area_type == "ICB sub-region" ~"nE38000016"
                             ),
    row_id = row_number())  %>%
    left_join(test_meta2, by = c("IndicatorId" = "Id"))

  # add variable name to indicaotrs with all geographies available 
     all_indicators_all_levels <- left_join(all_indicators2b, test_meta2,
                              by = c("IndicatorId" = "Id"))
 
###
##  get data for single indicator - only avialble in json, heavily nested
##  pull data for Bolton for a list of indicators - json only
 # test2 <- GET("https://fingertips.phe.org.uk/api/latest_data/specific_indicators_for_single_area?area_type_id=401&area_code=E08000001&indicator_ids=90291%2C90292")$content %>%
 #   rawToChar() %>%
 #   fromJSON(flatten = TRUE)
#  
#  test2_grouping <-map_df(test2, 1) 
#  test2_data <-map(test2, "Data") 
 
# get data for a single indicator as csv as then includes a lot of metadata
  # run through list of all indicators in a for loop to do this 
  # only downloads all levels of that geography to csv, 
  # then filter to keep only the latest, only bolton

       #for(i in 1: 50) {
     for(i in 1: nrow(all_indicators_bolton)){
       bolton_data1 <- 
         fread(glue::glue("https://fingertips.phe.org.uk/api/all_data/csv/by_indicator_id?indicator_ids={all_indicators_bolton[i, 1]}&child_area_type_id={all_indicators_bolton[i, 2]}")) %>%
         filter(`Area Code` == all_indicators_bolton$area_code[i]) %>%
         mutate(latest_date = max(`Time period Sortable`)) %>%
         filter(`Time period Sortable` == latest_date) %>%
         select(-c(latest_date))
       
       if(i ==1) {
         bolton_data_all <- bolton_data1
       } else {
         bolton_data_all <- rbind(bolton_data_all, bolton_data1) 
         
       }
       bolton_data_all
     }
    
# check if all expected indicators are downloaded 
 
 check <- all_indicators_bolton %>% 
   left_join(
     bolton_data_all %>% 
      group_by(`Indicator ID`) %>% 
      slice(1) %>%
      ungroup() %>%
      select(1:10) %>%
       rename(IndicatorId = `Indicator ID`)
     ,
     by = "IndicatorId"
   ) %>%
   mutate(downloaded = ifelse(is.na(`Indicator Name`), "not downloaded", "downloaded"))
 
# get indicator polarity

    #for(i in 1: 50) {
     for(i in 1: nrow(all_indicators_bolton)){
     polarity0 <- 
       GET(paste0("https://fingertips.phe.org.uk/api/latest_data/specific_indicators_for_single_area?area_type_id=",
        all_indicators_bolton$AreaTypeId[i],
        "&area_code=",
        all_indicators_bolton$area_code[i],
        "&indicator_ids=",
        all_indicators_bolton$IndicatorId[i]
        )
           )$content %>%
       rawToChar() %>%
       fromJSON(flatten = TRUE)
     
     if(length(polarity0)>0) {
       polarity1 <- polarity0[,c("IID", "PolarityId")]
       
       if(i ==1) {
         polarity_all <- polarity1
       } else {
         polarity_all <- rbind(polarity_all, polarity1) 
     }
       polarity_all
     }
   }
   
   polarity_all_withkey  <- GET("https://fingertips.phe.org.uk/api/polarities")$content %>%
     rawToChar() %>%
     fromJSON(flatten = TRUE) %>%
     right_join(
       polarity_all,
       by = c("Id" = "PolarityId")
   ) %>%
     relocate(IID) %>%
     rename(polarity_name = Name, polarity_id = Id) %>%
     unique()
 
# join to data
   
   bolton_data_all1 <- left_join( 
     bolton_data_all,
     polarity_all_withkey,
     by = c(`Indicator ID` = "IID")
     )
   
   
# write files 
  writexl::write_xlsx(check %>% 
                        select(c(1:6, 16))
                      , "all fingertips indicators check.xlsx")
  writexl::write_xlsx(check %>% 
                        filter(is.na(`Indicator Name`)) %>%
                        select(c(1:3, 6)),
                      "indicators not downloading.xlsx")
  writexl::write_xlsx(all_indicators_all_levels, "all fingertips indicators all levels.xlsx")
  writexl::write_xlsx(bolton_data_all, "all fingertips indicators data.xlsx")
  writexl::write_xlsx(polarity_all_withkey, "fingertips polarity.xlsx")
  
 