#----------------------------------------------------#
#----------------------------------------------------#
# Vital Stats Example File Preparation 
# for Labgold 2026 CityMatCH Training
# 'R for Applied MCH Epidemiologist'
#
# K. Labgold 07/13/2026
#
#----------------------------------------------------#
#----------------------------------------------------#

## Data Downloaded from https://www.cdc.gov/nchs/data_access/vitalstatsonline.htm
# U.S. Territories Data: 2024, 2023, 2022, 2021, 2020, 2018
# Used the 2018-2024 User Guide to identify the columns needed for the training example data

pacman::p_load(readr, dplyr, here, stringr, rio) # load r packages

here() # to see root


# Select columns to be used during the training ----
col_spec18to24 <- fwf_positions(
                start = c(9, 75, 117, 313, 314, 315, 316, 317, 408, 503, 504),
                end =   c(12, 76, 117, 313, 314, 315, 316, 317, 408, 503, 507),
                col_names = c("DOB_YY",
                              "MAGER", "MRACEHISP",
                              "RF_PDIAB", "RF_GDIAB", "RF_PHYPE", "RF_GHYPE",
                              "RF_EHYP", "DMETH_REC", "OEGest_R3", "DBWT")
)

# Pull in data ----
# Files are separated by year, so need to be pulled in one by one

ter.births.24 <- read_fwf(
  file = here("vitalstats_raw_datafiles", "Nat2024PublicPS.c20250512.r20250709.txt"), # here package: list folder stemming after project path
  col_positions = col_spec18to24,
  col_types = cols(.default = col_character()) # read in as character class
)

ter.births.23 <- read_fwf(
  file = here("vitalstats_raw_datafiles", "Nat2023PublicPS.c20240509.r20240724.txt"), # here package: list folder stemming after project path
  col_positions = col_spec18to24,
  col_types = cols(.default = col_character()) # read in as character class
)

ter.births.22 <- read_fwf(
  file = here("vitalstats_raw_datafiles", "Nat2022PublicPS.c20230516.r20231002.txt"), # here package: list folder stemming after project path
  col_positions = col_spec18to24,
  col_types = cols(.default = col_character()) # read in as character class
)

ter.births.21 <- read_fwf(
  file = here("vitalstats_raw_datafiles", "Nat2021PS.txt"), # here package: list folder stemming after project path
  col_positions = col_spec18to24,
  col_types = cols(.default = col_character()) # read in as character class
)

ter.births.20 <- read_fwf(
  file = here("vitalstats_raw_datafiles", "Nat2020PublicPS.r20210831.txt"), # here package: list folder stemming after project path
  col_positions = col_spec18to24,
  col_types = cols(.default = col_character()) # read in as character class
)

ter.births.18 <- read_fwf(
  file = here("vitalstats_raw_datafiles", "Nat2018PublicPS.c20190509.r20190710.txt"), # here package: list folder stemming after project path
  col_positions = col_spec18to24,
  col_types = cols(.default = col_character()) # read in as character class
) %>%
  # set DMETH_REC to missing
  dplyr::select(-c("DMETH_REC"))


# Rowbind 2020-2023 data files ----
ter.births.2018_2023 <- ter.births.23 %>%
                          bind_rows(ter.births.22, ter.births.21, ter.births.20, ter.births.18)
                  
### nrow(ter.births.18) + nrow(ter.births.20) + nrow(ter.births.21) + nrow(ter.births.22) + nrow(ter.births.23) # check total


# Create a row id, based on year + row_number
ter.births.2018_2023 <- ter.births.2018_2023 %>%
                          mutate(id = paste0(str_sub(DOB_YY, -2, -1), row_number())) # stringer pull second to last character and stop at last character (i.e. pull 23 from 2023)

ter.births.24 <- ter.births.24 %>%
                          mutate(id = paste0(str_sub(DOB_YY, -2, -1), row_number()))

# Split files to allow for column bind later

territory.births.18_23.demographics <- ter.births.2018_2023 %>%
                                          dplyr::select(id, DOB_YY, MAGER, MRACEHISP)
territory.births.18_23.clinical <- ter.births.2018_2023 %>%
                                          dplyr::select(-c(DOB_YY, MAGER, MRACEHISP)) %>%                                          # change DMETHREC, OEGest_R3 and DBWT to numeric
                                          mutate(
                                            DMETH_REC = as.numeric(DMETH_REC),
                                            OEGest_R3 = as.numeric(OEGest_R3),
                                            DBWT = as.numeric(DBWT)
                                          )

territory.births.24.demographics <- ter.births.24 %>%
                                          dplyr::select(id, DOB_YY, MAGER, MRACEHISP) 

territory.births.24.clinical <- ter.births.24 %>%
                                          dplyr::select(-c(DOB_YY, MAGER, MRACEHISP)) %>%
                                          # change DMETHREC, OEGest_R3 and DBWT to numeric
                                          mutate(
                                            DMETH_REC = as.numeric(DMETH_REC),
                                            OEGest_R3 = as.numeric(OEGest_R3),
                                            DBWT = as.numeric(DBWT)
                                          ) %>%
                                          rename("id2" = "id")


# Remove unnecessary files ----
rm(ter.births.18, ter.births.20, ter.births.21, ter.births.22, ter.births.23, col_spec18to24,
   ter.births.2018_2023, ter.births.24)


# Export 2020-2023 and 2024 to separate excel files ----
## with separate sheets for demographic + clinical
rio::export(list(demographic = territory.births.18_23.demographics,
                 clinical = territory.births.18_23.clinical),
            "training_data_files/raw/territory_births_18to23.xlsx")

rio::export(list(demographic = territory.births.24.demographics,
                 clinical = territory.births.24.clinical),
            "training_data_files/raw/territory_births_24.xlsx")


rm(territory.births.24.demographics, territory.births.24.clinical, territory.births.18_23.demographics,
   territory.births.18_23.clinical)


## Checking exports
##demo.18to23 <- rio::import("territory_births_18to23.xlsx", which = "demographic")
##clin.18to23 <- rio::import("territory_births_18to23.xlsx", which = "clinical")
##demo.24 <- rio::import("territory_births_24.xlsx", which = "demographic")
##clin.24 <- rio::import("territory_births_24.xlsx", which = "clinical")



#--------------------------------------------------------#
#--------------------------------------------------------#
####--------------- BONUS CODE! ---------------------####
# Example of the same code above to pull in the data, 
# but written more efficiently as a function so
# I don't have to run each year separately!
#--------------------------------------------------------#
#--------------------------------------------------------#


# Select columns to be used during the training ----
col_spec18to24 <- fwf_positions(
                    start = c(9, 75, 117, 313, 314, 315, 316, 317, 408, 503, 504),
                    end =   c(12, 76, 117, 313, 314, 315, 316, 317, 408, 503, 507),
                    col_names = c("DOB_YY",
                                  "MAGER", "MRACEHISP", 
                                  "RF_PDIAB", "RF_GDIAB", "RF_PHYPE", "RF_GHYPE",
                                  "RF_EHYP", "DMETH_REC", "OEGest_R3", "DBWT")
                  )

# Get a list of the file paths ----
## the raw data should be in it's own folder, here I named it "vitalstats_raw_datafiles"
file_list <- list.files(path = here("vitalstats_raw_datafiles"), pattern = "\\.txt$", full.names = TRUE)

# Extract file names & pull the file year for custom df naming ----
## This regex looks for any 4-digit number and extracts the last 2 digits
file_names <- basename(file_list)
year_2_digits <- gsub(".*Nat[^0-9]*[0-9]{2}([0-9]{2}).*", "\\1", file_names)
custom_df_names <- paste0("ter.births.", year_2_digits)

# Read files into a list ----
list_of_dfs <- lapply(file_list, function(x){
                  read_fwf(
                    file = x,
                    col_positions = col_spec18to24,
                    col_types = cols(.default = col_character()) # read in as character class
                  )
  
})

# Assign custom names to each dataframe ----
names(list_of_dfs) <- custom_df_names

# Expand from the large list to each having it's own df ----
list2env(list_of_dfs, envir = .GlobalEnv)

