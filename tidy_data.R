library(tidyverse)
library(gtsummary)

# import dataset
raw_data <- read.csv("~/Google Drive/Grad School/CUMC/P9185 SPRIS/Projects/P9185_Project3/SPRIS-Project3/data.csv") %>% 
  janitor::clean_names()

head(raw_data)

# number of records
nrow(raw_data)

# number of subjects
nrow(raw_data %>% distinct(subject_id))

# skim dataset: no rows for missing data in the dataset
skimr::skim(raw_data)
map(raw_data, class)

# number of obs/subject
# half the subjects have all 4 time points
raw_data %>% 
  group_by(subject_id) %>% 
  summarize(n_recs = n(), .groups = "drop") %>% 
  tbl_summary(include = n_recs)

# summarize data
# subjects don't all have 1 row/timepoint
raw_data %>% 
  select(-subject_id) %>% 
  tbl_summary(by = day)
