library(tidyverse)
library(gtsummary)

#test change

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

# summarize data / look at data over time
# subjects don't all have 1 row/timepoint
raw_data %>% 
  select(-subject_id) %>% 
  tbl_summary(by = day)

# does the distribution of age or gender differ by treatment arm
raw_data %>% 
  distinct(subject_id, treatment_group, age, gender) %>% 
  tbl_summary(by = treatment_group,
              include = c(treatment_group, age, gender)) %>% 
  add_p()

# need to add blank rows for missing time points
# get 1 row/subject/timepoint
expand_df <- expand_grid(raw_data %>% distinct(subject_id, treatment_group, age, gender), 
            day = unique(raw_data$day))

# check that the number of rows = 4 rows/subject from the number of subjects in the original dataset: confirmed
nrow(expand_df)
nrow(expand_df) == length(unique(raw_data$subject_id))*4

# combine with raw data to get NAs
# merge timepoints back on
data_expanded <- left_join(expand_df,
                           raw_data,
                           by = c("subject_id", "day", "age", "gender",
                                  "treatment_group")) %>% 
  mutate(tx = factor(case_when(treatment_group == "A" ~ "Placebo",
                        treatment_group == "B" ~ "High dose",
                        treatment_group == "C" ~ "Low dose"), levels = c("Placebo", "Low dose", "High dose")))

# look at new dataset
head(raw_data)
head(data_expanded, 40)

# save both datasets
save(raw_data,
     data_expanded,
     file = here::here("datasets.rdata"))

# to load datasets in analysis file
# load(here::here("datasets.rdata"))