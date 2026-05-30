
# Avocado-satiety study
# Secondary analysis of the HAT study


# Setup -------------------------------------------------------------------

# Required packages
pacs <- c(
  "tidyverse", 
  "readxl", 
  "janitor", 
  "hms", 
  "tableone", 
  "ggridges", 
  "patchwork",
  "nlme",
  "emmeans"
)

sapply(pacs, require, character.only = TRUE)

# Read functions
source("functions.R")

# Data dictionary ---------------------------------------------------------

# imname = meal name
  # 1 = Breakfast
  # 2 = Brunch
  # 3 = Lunch
  # 4 = Snack
  # 5 = Dinner/Supper
  # 6 = Other
  # 7 = School Lunch
  # 8 = Beverage (just a drink)

# implace = meal location
  # 1 = Home
  # 2 = Work
  # 3 = School
  # 4 = Day care
  # 6 = Deli/take-out/store
  # 7 = Restaurant/cafeteria/fast food
  # 10 = Friend’s home
  # 11 = Community meal program
  # 12 = Party/reception/sporting event
  # 13 = Other
  # 14 = Traveling (car, airport, train, bus, etc.)

# cmealid is sequential within a day (visitcode)

# visitcode: DT1, DT2, DT3, DT4
  # R1 = Recall 1 (screen/BL)
  # R2 = Recall 2 (around week 8)
  # R3 = Recall 3 (around week 16)
  # R4 = Recall 4 (around weeks 20-26)

# Read data ---------------------------------------------------------------

# File listing from data folder
dir('./data')

# The following 5 files were used to create an analytic data
# Subject ID is: pid  (convert cpartid to pid if necessary)

# Protocol file
# Includes all participants who had two or more compliant recalls
# Will be used as demographic data
# n = 900 (cpartid all distinct)
protocol <- read_excel("./data/macro_protocol3.xlsx") %>%
  clean_names() %>%
  rename(pid = cpartid) %>%
  select(pid, site_id, randarm, education, sex, age, bmi, waist, race)

# Contains food group serving counts at the meal or eating occasion level (FGSCMeal),
# Used to identify meals with avocado
# Avocado intake = rfgscmFRU500
# n = 19,643
meal_servings <- read_csv("./data/HAT_SCMeal.csv") %>%
  mutate(tmtime = as.numeric(tmtime))        # readxl reads times as hms; convert to seconds

# Revised Meal file (per meal)
# Contains corrected meal time 
# n = 19,643
meals_updated <- read_excel("./data/meal_timdiff_updated.xlsx") %>%
  clean_names() %>%
  rename(pid = cpartid) %>%
  mutate(
    tmtime = as_hms(tmtime),                 # tmtime read as datetime, convert to hms
    tmtime = as.numeric(tmtime))             # convert to seconds

# Total intake (gram, kcal) per meal, separating beverages 
# Appears to be based on meal file
# This will be used instead of meal file
# n = 19,643
non_beverages <- read_csv("./data/Gram_kcal_new2.csv") %>%
  mutate(pid = as.numeric(cpartid)) %>%
  select(-cpartid)

# Intake (per day) file
# Contains total nutrient intake per day for each participant
# Needed: intake day of the week
# idow: 0 = Sunday, 1 = Monday,..., 6 = Saturday 
# n = 3,901
intake <- read_csv("./data/HAT_Intake.csv") %>%
  mutate(weekday = if_else(idow %in% c(0, 6), 0L, 1L),
         kcal_per_day = rikcal) %>%
  select(pid, visitcode, weekday, kcal_per_day, idow)

# Food-level file
# Not needed for analysis
food <- read_csv("./data/HAT_SCFood.csv")
names(food)

# Identify meals with avocado ---------------------------------------------

# Assume one whole avocado = 168 gram
# One whole avocado = 2.24 serving size

# Avocado intake categories
avocado_intake_cat_labels <- c(
  "No avocado at all", 
  "<1 avocado", 
  "1 whole avocado or more" 
)

# Based on meal_serving file
# Order by pid, visit, and meal sequence
# Identify meals with avocado intake
meal_servings2 <- meal_servings %>%
  arrange(pid, visitcode, cmealid) %>%
  group_by(pid, visitcode) %>%
  mutate(
    meal_with_avocado  = if_else(rfgscmFRU0500 > 2.23, 1L, 0L),
    avocado_gram       = rfgscmFRU0500 * 168 / 2.24,
    avocado_intake_cat = case_when(
      avocado_gram == 0                        ~ 1L,
      avocado_gram > 0   & avocado_gram < 168  ~ 2L,
      avocado_gram >= 168                      ~ 3L,
      
    ),
    avocado_intake_cat = factor(avocado_intake_cat, levels = 1:3, labels = avocado_intake_cat_labels),
    # meal_after_avocado = if_else(cmealid == 1, NA_integer_, lag(meal_with_avocado)),
    # previous_avcd_intk = if_else(cmealid == 1, NA_real_,    lag(rfgscmFRU0500)),
    # previous_meal      = if_else(cmealid == 1, NA_real_,    lag(as.numeric(imname)))
    # tmtime             = if_else(tmtime == 0 , 3600 * 24,   as.numeric(tmtime)),
    # meal_interval      = if_else(cmealid == 1, NA_real_,    (tmtime - lag(tmtime)) / 3600)
  ) %>%
  ungroup() %>%
  select(
    pid, 
    visitcode, 
    cmealid, 
    imname, 
    rfgscmFRU0500,
    meal_with_avocado,
    avocado_gram,
    avocado_intake_cat,
    # meal_after_avocado, 
    # previous_avcd_intk, 
    # previous_meal 
    # meal_interval
  )

# Correcting meal names ---------------------------------------------------

# Based on meals_updated
# meal_freq will be re-calculated at later step
meals_updated2 <- meals_updated %>%
  arrange(pid, visitcode, cmealid) %>%
  group_by(pid, visitcode) %>%
  mutate(
    tmtime        = if_else(tmtime == 0 & cmealid > 1, 3600 * 24,   as.numeric(tmtime)),
    meal_interval = if_else(cmealid == 1 | coding %in% c(3, 5), NA_real_, (tmtime - lag(tmtime)) / 3600),
    coding        = if_else(coding == 0, 2L, as.integer(coding)),
    # meal_freq     = sum(imname != 8)
  ) %>%
  ungroup() %>%
  rename(tmtime_fixed = tmtime) %>%
  select(pid, visitcode, cmealid, imname, tmtime_fixed, meal_interval, coding)

# Merge files for analytic dataset ----------------------------------------

# Time threshold (in seconds)
t11 <- 11 * 3600
t12 <- 12 * 3600
t17 <- 17 * 3600 

# Category labels
race_labels      <- c("African American", "Asian", "Caucasian", "Other")
educ_labels      <- c("None", "Vocational school", "College degree", "Graduate degree")
meal_type_labels <- c(
  "Morning meal", 
  "Morning snack", 
  "Midday meal", 
  "Midday snack", 
  "Evening meal", 
  "Late night snack",
  "Beverage"
)
meal_place_labels <- c(
  "Home/Friend's home",
  "Work/School",
  "Deli/Take-out/Restaurant",
  "Daycare/Party/Travelling/Other"
)
   
# Merge files
# Begin with meals_updated2
analytic_df <- meals_updated2 %>%

  # Inner-join non_beverages
  # Calculate total density, food kcal/grams, and food density
  # Note that food density > 9 is set to missing (5 meals affected)
  inner_join(
    non_beverages %>%
    select(-imname) %>% 
      mutate(
        total_density = total_kcal / total_gram,
        food_kcal     = total_kcal - bvrg_kcal,
        food_gram     = total_gram - bvrg_gram,
        food_density  = food_kcal / food_gram,
        food_density  = if_else(food_density > 9, NA_real_, food_density)
      ),
    by = c("pid", "visitcode", "cmealid")
  ) %>%
  
  # Inner-join meal_servings2 
  inner_join(meal_servings2 %>% select(-imname), by = c("pid", "visitcode", "cmealid")) %>%
  
  # Restrict to per-protocol participants; add demographics
  inner_join(protocol, by = "pid") %>%
  
  # Inner-join with intake per day file: add day_of_wk, kcal_per_day 
  inner_join(intake,   by = c("pid", "visitcode")) %>%
  
  # Correct 3 meals miscoded as beverages
  mutate(imname = case_when(
    pid == 15120643 & visitcode == "DT4" & cmealid == 1 ~ 4L,
    pid == 15131688 & visitcode == "DT4" & cmealid == 1 ~ 1L,
    pid == 10004467 & visitcode == "DT2" & cmealid == 7 ~ 4L,
    TRUE ~ as.integer(imname)
  )) %>%

  # Recode variables 
  mutate(
    bmi_cat = case_when(
      bmi < 25             ~ 1,
      bmi >= 25 & bmi < 30 ~ 2,
      bmi >= 30            ~ 3
    ),
    bmi_cat = factor(bmi_cat, labels = c("Normal", "Overweight", "Obese")),
    
    region = case_when(
      site_id %in% c(401, 402, 501) ~ 1L,  # East Coast
      site_id %in% c(201, 301)      ~ 2L   # West Coast
      ),
    region = factor(region, labels = c("East coast", "West coast")),
    
    hour = tmtime_fixed / 3600,
    
    meal_type  = case_when(
      imname == 8                                             ~ 9L,  # Beverage
      imname == 4 & tmtime_fixed <= t12                       ~ 2L,  # Morning snack
      imname == 4 & tmtime_fixed >  t12 & tmtime_fixed <= t17 ~ 4L,  # PM snack
      imname == 4 & tmtime_fixed >  t17                       ~ 6L,  # HS snack
      tmtime_fixed <= t11                                     ~ 1L,  # Morning meal
      tmtime_fixed >  t11 & tmtime_fixed < t17                ~ 3L,  # Midday meal
      tmtime_fixed >= t17                                     ~ 5L   # Evening meal
    ),
    meal_or_snack = if_else(meal_type %in% c(2, 4, 6), 1, 0),
    meal_type     = factor(meal_type, labels = meal_type_labels),
    meal_or_snack = factor(meal_or_snack, labels = c("Meal", "Snack")), 
    
    idow = factor(idow, labels = c("Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat")),
    
    meal_place  = case_when(
      implace %in% c(1, 10)             ~ 1L,  # Home / Friend's home
      implace %in% c(2, 3)              ~ 2L,  # Work / School
      implace %in% c(6, 7)              ~ 3L,  # Deli/take-out / Restaurant
      implace %in% c(4, 11, 12, 13, 14) ~ 4L   # Daycare / Party / Other / Travelling
    ),
    meal_place = factor(meal_place, labels = meal_place_labels),
    
    race = factor(race, labels = race_labels),
    race = relevel(race, ref = "Caucasian"),
    
    educ_level = case_when(
      education %in% c(0, 1) ~ 1L,     # No high school / none
      education %in% c(2, 6) ~ 2L,     # Vocational / professional school
      education %in% c(3, 4) ~ 3L,     # Community / 4-year college
      education == 5         ~ 4L      # Graduate school
    ),
    educ_level = factor(educ_level, labels = educ_labels),
    
    # previous_meal_type = case_when(
    #   previous_meal %in% c(1, 2, 3, 5, 6)  ~ 0L,  # Any meal
    #   previous_meal == 4                   ~ 1L,  # Snack
    #   previous_meal == 8                   ~ 2L   # Beverage
    # ),
  ) %>%
  
  # Final exclusions: avocado arm only, no baseline, no beverages, no trace meals (total kcal >= 20, food kcal > 0.3)
  filter(
    randarm   == 1,
    visitcode != "DT1",
    total_kcal >= 20,
    imname    != 8,
    food_kcal > 0.3
  ) %>% 
  
  # Recalculate meal frequency
  add_count(pid, visitcode, name = "meal_freq") %>%
  
  # Recalculate meal interval: meal_interval_hr
  arrange(pid, visitcode, cmealid) %>% 
  group_by(pid, visitcode) %>% 
  mutate(
    meal_interval_hr = (tmtime_fixed - lag(tmtime_fixed)) / 60 ^ 2,
    meal_interval_hr = ifelse(coding %in% c(3, 5), NA_real_, meal_interval_hr),
    lag_avocado_intake_cat = lag(avocado_intake_cat)
  ) %>% 
  ungroup()

# Still need to check how the last analytic data was created!!!!

# Check
# Number of subjects = 436
n_distinct(analytic_df$pid)

# Number of recalls = 1,296
analytic_df %>% 
  distinct(pid, visitcode) %>% 
  nrow()

# Most of the participants have 3 recalls (97.2%)
# 12 participants have only 2 recalls
analytic_df %>%
  group_by(pid) %>% 
  summarize(n_recalls = n_distinct(visitcode)) %>% 
  count(n_recalls) %>% 
  mutate(percent = n / sum(n) * 100)

# Number of meals included = 4990
nrow(analytic_df)

# Food kcal near zero
# analytic_df %>% 
#   filter(food_kcal < .3) %>% 
#   select(pid, visitcode, cmealid, imname, food_kcal)
# 
# analytic_df %>% 
#   filter(food_kcal < .3) %>% 
#   select(pid, visitcode, cmealid, imname, food_kcal) %>% 
#   left_join(food, by = c("pid", "visitcode", "cmealid")) %>% 
#   select(pid:corder) %>% 
#   write_csv("food_kcal_near_zero_meals.csv")


# Descriptive analysis ----------------------------------------------------

## Participant characteristics --------------------------------------------

demog <- analytic_df %>%
  distinct(pid, sex, race, bmi_cat, bmi, educ_level, region, waist, age) 

table_vars <- c("age", "sex", "race", "educ_level", "region", "bmi_cat", "bmi", "waist")

CreateTableOne(
    vars = table_vars,
    data = demog
) %>% 
  print(showAllLevels = TRUE, contDigits = 1)



## Recall day -------------------------------------------------------------

# Frequency table by day of the week
analytic_df %>% 
  distinct(pid, visitcode, idow) %>%
  count(idow) %>% 
  mutate(percent = n / sum(n) * 100)

analytic_df %>% 
  mutate(day_of_wk = factor(day_of_wk, labels = c("Weekends", "Weekdays"))) %>% 
  count(day_of_wk) %>% 
  mutate(percent = n / sum(n) * 100)

# Add mean numbers of meals, mean kcal per week
analytic_df %>%
  group_by(pid, visitcode, idow, kcal_per_day) %>%
  summarise(n_meals = n(), .groups = "drop") %>%
  group_by(idow) %>%
  summarise(
    n_visits = n(),
    mean_n_meals = mean(n_meals),
    mean_kcal_per_day = mean(kcal_per_day)
  ) %>%
  mutate(percent = n_visits / sum(n_visits) * 100) %>% 
  select(idow, n_visits, percent, mean_n_meals, mean_kcal_per_day)

## Meals ------------------------------------------------------------------

# Meal type frequencies
analytic_df %>% 
  count(meal_type) %>% 
  mutate(percent = n / sum(n) * 100)

# Descriptive stats by meal type
analytic_df %>% 
  group_by(meal_or_snack, meal_type) %>% 
  summarize(
    n = n(),
    pct = n / nrow(.) * 100,
    mean_total_kcal = mean(total_kcal),
    sd_total_kcal   = sd(total_kcal),
    mean_food_kcal  = mean(food_kcal),
    sd_food_kcal    = sd(food_kcal)
  )

tab <- analytic_df %>% 
  mutate(meal_type = droplevels(meal_type)) %>% 
  CreateTableOne(
    vars = c("total_kcal", "food_kcal"),
    strata = "meal_type",
    data = .,
    test = FALSE
  )

tab_df <- as.data.frame(print(tab, printToggle = FALSE, digits = 1)) %>%
  rownames_to_column("variable") %>%
  pivot_longer(-variable, names_to = "meal_type", values_to = "value") %>%
  pivot_wider(names_from = variable, values_from = value) %>%
  left_join(
    analytic_df %>% distinct(meal_type, meal_or_snack),
    by = "meal_type"
  ) %>%
  mutate(percent = parse_number(n) / nrow(analytic_df) * 100) %>% 
  arrange(meal_or_snack) %>% 
  select(meal_type, n, percent, `total_kcal (mean (SD))`, `food_kcal (mean (SD))`)

tab_df

# Density plot of food kcal by meal/snack type
analytic_df %>% 
  filter(food_kcal > 0) %>% 
  ggplot(aes(x = food_kcal, y = fct_rev(meal_type), fill = meal_type)) +
  geom_density_ridges(alpha = 0.5) +
  theme_ridges() + 
  theme(
    legend.position = "none",
    axis.title.x = element_text(hjust = 0.5)
  ) +
  labs(x = "Food kcal per meal (log axis)", y = "") +
  scale_x_log10() +
  coord_cartesian(xlim = c(10, 5000)) +
  facet_grid(meal_or_snack ~., scales = "free_y") 

# Meal place
analytic_df %>% 
  count(meal_place) %>% 
  mutate(percent = n / sum(n) * 100)

# There is 1 missing on meal_place
analytic_df %>% 
  filter(is.na(meal_place)) %>% 
  select(pid, visitcode, cmealid, imname, implace, meal_place, total_kcal)

# Meal place and mean energy
analytic_df %>% 
  group_by(meal_place) %>% 
  summarize(
    n    = n(),
    Pct  = n() / nrow(.) * 100,
    Mean_total_kcal = mean(total_kcal),
    SD_total_kcal   = sd(total_kcal),
    Mean_food_kcal = mean(food_kcal),
    SD_food_kcal   = sd(food_kcal)
  )


# Outcomes ----------------------------------------------------------------

## Energy content, kcal ---------------------------------------------------

# Kcal from food meal, excluding beverages
analytic_df %>% 
  summarize(
    min     = min(food_kcal),
    Q1      = quantile(food_kcal, prob = 0.25),
    Median  = quantile(food_kcal, prob = 0.50),
    Mean    = mean(food_kcal, na.rm = TRUE),
    SD      = sd(food_kcal, na.rm = TRUE),
    Q3      = quantile(food_kcal, prob = 0.75),
    max     = max(food_kcal)
  )


analytic_df %>% 
  select(food_kcal) %>% 
  summary()

# Histogram
p1 <- analytic_df %>% 
  ggplot(aes(x = food_kcal)) +
  geom_histogram() +
  labs(
    y = "Number of meals", 
    x = "Energy content per meal",
    title = "Histogram of food kcal"
  )

# Log-transformed histogram
analytic_df %>% 
  ggplot(aes(x = food_kcal)) +
  geom_histogram() +
  scale_x_continuous(trans = "log") +
  labs(
    y = "Number of meals", 
    x = "Energy content per meal",
    title = "Histogram of food kcal"
  )

# ECDF
p2 <- analytic_df %>% 
  ggplot(aes(x = food_kcal)) +
  stat_ecdf() +
  scale_y_continuous(labels = scales::percent) +
  labs(
    y = "Cumlative percentage", 
    x = "Energy content per meal",
    title = "Cumulative distribution of food kcal"
  )

p1 + p2

## Energy density ---------------------------------------------------------

# Food density = food kcal / food grams
summary(analytic_df$food_density)

analytic_df %>% 
  summarize(
    min     = min(food_density, na.rm = TRUE),
    Q1      = quantile(food_density, prob = 0.25, na.rm = TRUE),
    Median  = quantile(food_density, prob = 0.50, na.rm = TRUE),
    Mean    = mean(food_density, na.rm = TRUE),
    SD      = sd(food_density, na.rm = TRUE),
    Q3      = quantile(food_density, prob = 0.75, na.rm = TRUE),
    max     = max(food_density, na.rm = TRUE)
  )

# Histogram
p1 <- analytic_df %>% 
  ggplot(aes(x = food_density)) +
  geom_histogram() +
  # scale_x_continuous(trans = "log") +
  labs(
    y = "Number of meals", 
    x = "Food density",
    title = "Histogram of food density"
  )

# ECDF
p2 <- analytic_df %>% 
  ggplot(aes(x = food_density)) +
  stat_ecdf() +
  scale_y_continuous(labels = scales::percent) +
  labs(
    y = "Cumlative percentage", 
    x = "Food density",
    title = "Cumulative distribution of food density"
  )

p1 + p2

# Using ggridges
analytic_df %>% 
  ggplot(aes(x = food_density, y = fct_rev(meal_type), fill = meal_type)) +
  geom_density_ridges(alpha = 0.5) +
  theme_ridges() + 
  theme(
    legend.position = "none",
    axis.title.x = element_text(hjust = 0.5)
  ) +
  labs(x = "Food density", y = "") +
  facet_grid(meal_or_snack ~., scales = "free_y") 


## Meal interval ----------------------------------------------------------

summary(analytic_df$meal_interval_hr)

analytic_df %>% 
  filter(!is.na(meal_interval_hr)) %>% 
  summarize(
    min     = min(meal_interval_hr),
    Q1      = quantile(meal_interval_hr, prob = 0.25),
    Median  = quantile(meal_interval_hr, prob = 0.50),
    Mean    = mean(meal_interval_hr),
    SD      = sd(meal_interval_hr),
    Q3      = quantile(meal_interval_hr, prob = 0.75),
    max     = max(meal_interval_hr)
  )

# Histogram
p1 <- analytic_df %>% 
  filter(!is.na(meal_interval_hr)) %>% 
  ggplot(aes(x = meal_interval_hr)) +
  geom_histogram(bins = 25) +
  labs(
    y = "Number of meals", 
    x = "Meal interval (hours)",
    title = "Histogram of meal interval"
  )

# ECDF
p2 <- analytic_df %>% 
  filter(!is.na(meal_interval_hr)) %>% 
  ggplot(aes(x = meal_interval_hr)) +
  stat_ecdf() +
  scale_y_continuous(labels = scales::percent) +
  labs(
    y = "Cumlative percentage", 
    x = "Meal interval (hours)",
    title = "Cumulative distribution of meal interval"
  )

p1 + p2


# Avocado intake ----------------------------------------------------------

# Avocado intake:
# From 0 to 504 grams
summary(analytic_df$avocado_gram)

# Check: 2 participants ate >500 grams of avocado in one meal
analytic_df %>% 
  filter(avocado_gram > 500) %>% 
  select(pid, visitcode, cmealid, imname, meal_with_avocado, avocado_gram, rfgscmFRU0500, food_gram, total_gram)

# Avocado gram frequency
# ~70% of meals did not have any avocado
# Then 1 avocado, half avocao, 1/4 avocao
analytic_df %>% 
  count(avocado_gram) %>% 
  arrange(-n) %>% 
  mutate(percent = n / sum(n) * 100)

analytic_df %>% 
  ggplot(aes(x = avocado_gram)) +
  geom_histogram()

# Avocado intake categories
analytic_df %>% 
  count(avocado_intake_cat) %>% 
  mutate(percent = n / sum(n) * 100)


## Mean kcal by meal type & avocado ---------------------------------------

# Mean kcal by meal type and avocado intake
tab4_2 <- analytic_df %>%
  group_by(meal_or_snack, meal_type, avocado_intake_cat) %>%
  summarise(
    n    = n(),
    mean = mean(food_kcal, na.rm = TRUE),
    sd   = sd(food_kcal,   na.rm = TRUE),
    .groups = "drop"
  )

Sys.setlocale("LC_CTYPE", "English_United States.utf8")

tab4_2 %>%  
  mutate(
    avocado_label = case_when(
      avocado_intake_cat == "No avocado at all"        ~ "EO with no avocado", 
      avocado_intake_cat == "<1 avocado"               ~ "EO with <1 avocado", 
      avocado_intake_cat == "1 whole avocado or more"  ~ "EO with 1+ avocado"
    ),
    mean_sd = paste0(round(mean), " ± ", round(sd))
  ) %>%
  select(meal_type, avocado_label, n, mean_sd) %>%
  pivot_wider(
    names_from  = avocado_label,
    values_from = c(n, mean_sd)
  ) %>%
  select(
    `Meal type`               = meal_type,
    `n (no avocado)`          = `n_EO with no avocado`,
    `Mean ± SD (no avocado)`  = `mean_sd_EO with no avocado`,
    `n (<1 avocado)`          = `n_EO with <1 avocado`,
    `Mean ± SD (<1 avocado)`  = `mean_sd_EO with <1 avocado`,
    `n (1+ avocado)`          = `n_EO with 1+ avocado`,
    `Mean ± SD (1+ avocado)`  = `mean_sd_EO with 1+ avocado`
  )

# Figure
tab4_2 %>% 
  ggplot(aes(x = meal_type, y = mean, fill = avocado_intake_cat)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  scale_y_continuous(limits = c(0, 1000), breaks = 1:5 * 200) +
  theme(legend.position = "bottom") +
  labs(x = "", y = "Mean food kcal per meal (kcal)", fill = "") +
  facet_wrap(~ meal_or_snack, scales = "free_x")


## Mean density by meal type & avocado ------------------------------------

# Mean food density by meal type and avocado intake
tab4_2_fd <- analytic_df %>%
  group_by(meal_or_snack, meal_type, avocado_intake_cat) %>%
  summarise(
    n    = n(),
    mean = mean(food_density, na.rm = TRUE),
    sd   = sd(food_density,   na.rm = TRUE),
    .groups = "drop"
  )

Sys.setlocale("LC_CTYPE", "English_United States.utf8")

tab4_2_fd %>%  
  mutate(
    avocado_label = case_when(
      avocado_intake_cat == "No avocado at all"        ~ "EO with no avocado", 
      avocado_intake_cat == "<1 avocado"               ~ "EO with <1 avocado", 
      avocado_intake_cat == "1 whole avocado or more"  ~ "EO with 1+ avocado"
    ),
    mean_sd = paste0(round(mean, 2), " ± ", round(sd, 2))
  ) %>%
  select(meal_type, avocado_label, n, mean_sd) %>%
  pivot_wider(
    names_from  = avocado_label,
    values_from = c(n, mean_sd)
  ) %>%
  select(
    `Meal type`               = meal_type,
    `n (no avocado)`          = `n_EO with no avocado`,
    `Mean ± SD (no avocado)`  = `mean_sd_EO with no avocado`,
    `n (<1 avocado)`          = `n_EO with <1 avocado`,
    `Mean ± SD (<1 avocado)`  = `mean_sd_EO with <1 avocado`,
    `n (1+ avocado)`          = `n_EO with 1+ avocado`,
    `Mean ± SD (1+ avocado)`  = `mean_sd_EO with 1+ avocado`
  )

# Figure
tab4_2_fd %>% 
  ggplot(aes(x = meal_type, y = mean, fill = avocado_intake_cat)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  theme(legend.position = "bottom") +
  labs(x = "", y = "Mean food density (kcal/g)", fill = "") +
  facet_wrap(~ meal_or_snack, scales = "free_x")


# Prior avocado intake -------------------------------------------------

# There are 3,694 meals after cmealid == 1
analytic_df %>% 
  filter(!is.na(lag_avocado_intake_cat)) %>%
  nrow()
 
# Prior avocado intake and its effect on meal interval and food kcal 
analytic_df %>% 
  filter(!is.na(lag_avocado_intake_cat)) %>%
  group_by(lag_avocado_intake_cat) %>% 
  summarize(
    n = n(),
    pct = n / nrow(.) * 100,
    mean_meal_interval_hr = mean(meal_interval_hr, na.rm = TRUE),
    sd_meal_interval_hr   =  sd(meal_interval_hr, na.rm = TRUE),
    mean_food_kcal        = mean(food_kcal, na.rm = TRUE),
    sd_food_kcal          =  sd(food_kcal, na.rm = TRUE)
  ) %>% 
  mutate(
    mean_sd_meal_interval = paste0(sprintf("%.2f", mean_meal_interval_hr), " ± ", sprintf("%.2f", sd_meal_interval_hr)),
    mean_sd_food_kcal     = paste0(sprintf("%.1f", mean_food_kcal), " ± ", sprintf("%.1f", sd_food_kcal))
  ) %>% 
  select(lag_avocado_intake_cat, n, pct, starts_with("mean_sd"))

tab <- analytic_df %>% 
  filter(!is.na(lag_avocado_intake_cat)) %>%
  group_by(meal_or_snack, meal_type, lag_avocado_intake_cat) %>% 
  summarize(
    n = n(),
    mean_meal_interval_hr = mean(meal_interval_hr, na.rm = TRUE),
    mean_food_kcal        = mean(food_kcal, na.rm = TRUE),
  )

tab %>% 
  ggplot(aes(x = meal_type, y = mean_meal_interval_hr, fill = lag_avocado_intake_cat)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap(~meal_or_snack, scales = "free") +
  theme(legend.position = "bottom") +
  labs(x = "", y = "Mean meal interval (hour)", fill = "Prior avocado intake")

tab %>% 
  ggplot(aes(x = meal_type, y = mean_food_kcal, fill = lag_avocado_intake_cat)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap(~meal_or_snack, scales = "free") +
  theme(legend.position = "bottom") +
  labs(x = "", y = "Mean energy content (kcal)", fill = "Prior vocado intake")



# Mixed models ------------------------------------------------------------

# Data for model
analytic_df2 <- analytic_df %>% 
  arrange(pid, visitcode, cmealid) %>% 
  filter(!is.na(meal_place)) %>% 
  mutate(
    log_food_kcal = log(food_kcal),
    meal_type = relevel(meal_type, ref = "Evening meal"),
    cmealid = factor(cmealid),
    daily_kcal100 = kcal_per_day / 100,
    meal_time_hr = tmtime_fixed / 3600,
    meal_period = case_when(
      meal_type %in% c("Morning meal", "Morning snack") ~ 1,
      meal_type %in% c("Midday meal", "Midday snack") ~ 2,
      meal_type %in% c("Evening meal", "Late night snack") ~ 0
    ),
    meal_period = factor(meal_period, labels = c("Evening", "Morning", "Midday"))
    )

# Covariates
covars <- c(
  "age", 
  "sex", 
  "race", 
  "bmi", 
  "region", 
  "weekday", 
  "meal_place", 
  "meal_freq", 
  "daily_kcal100"
)


# Effect of avocado intake on the same meal -------------------------------

## Food kcal --------------------------------------------------------------

# Fit the model with covariates only
# Assumes random subjects (intercept) and recall day (nested in pid)
# G matrix: random intercept + visitcode | pid
# R matrix: CAR(1) structure for meals within visitcode(pid)

# Create formula
fm <- formula(paste("log_food_kcal ~", paste(covars, collapse = " + ")))
fm

# Run covariates-only model
log_food_kcal_0 <- lme(
  fixed       = fm,
  random      = ~ 1 + visitcode | pid,          
  # correlation = corCompSymm(form = ~ 1 | pid/visitcode),
  correlation = corCAR1(form = ~ meal_time_hr | pid/visitcode),
  data        = analytic_df2,
  method      = "REML",
  control = lmeControl(
    opt = "optim",
    maxIter = 200,
    msMaxIter = 200
  )
)

# Check results
# Significant: Weekday, meal_place, meal_freq, daily_kcal
summary(log_food_kcal_0)$tTable %>% 
  printCoefmat(digits = 4, P.values = TRUE, has.Pvalue = TRUE)

# LRT tests for each covariate
lrt_each_covariate(log_food_kcal_0)

# Exponentiate beta coefficients
intervals(log_food_kcal_0, which = "fixed")$fixed %>% exp()

# Add avocado intake * meal type interaction
log_food_kcal_1 <- update(log_food_kcal_0, . ~ . + avocado_intake_cat * meal_type)

# LR test for interaction: Highly signifiacnt
lrt_each_covariate(log_food_kcal_1)

# Check results
summary(log_food_kcal_1)$tTable %>% 
  printCoefmat(digits = 4, P.values = TRUE, has.Pvalue = TRUE)

# Estimated marginal means
emmeans_avocado <- emmeans(log_food_kcal_1, ~avocado_intake_cat | meal_type, weights = "proportional")
pairs_avocado   <- pairs(emmeans_avocado, adjust = "tukey")
emmeans_tab     <- make_emmeans_tab(emmeans_avocado, pairs_avocado, exponentiate = TRUE, digits = 1)

# Table format
emmeans_tab %>% select(-meal_or_snack)

# Bar chart
emmeans_tab %>% 
  ggplot(aes(x = meal_type, y = emmean, fill = avocado_intake_cat)) +
  geom_col(position = "dodge") +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width = 0.2,
    position = position_dodge(0.9)
  ) +
  facet_wrap(~ meal_or_snack, scales = "free_x") +
  labs(
    title = "Estimated marginal means (with 95% CI) of food kcal",
    x = "", 
    y = "Adjusted mean energy content (kcal/meal)",
    fill = "") +
  theme(legend.position = "bottom")


## Energy density ---------------------------------------------------------

# Run covariates-only model
energy_density_0 <- update(
  log_food_kcal_0, 
  food_density ~ ., 
  data = analytic_df2,
  subset = !is.na(food_density)
)

# Check results
# Significant: Weekday, meal_place, meal_freq, daily_kcal
summary(energy_density_0)$tTable %>% 
  printCoefmat(digits = 4, P.values = TRUE, has.Pvalue = TRUE)

# LRT tests for each covariate
lrt_each_covariate(energy_density_0)

# Beta coefficients
intervals(energy_density_0, which = "fixed")$fixed

# Add avocado intake * meal type interaction
energy_density_1 <- update(energy_density_0, . ~ . + avocado_intake_cat * meal_type)

# LR test for interaction: Highly signifiacnt
lrt_each_covariate(energy_density_1)

# Check results
summary(energy_density_1)$tTable %>% 
  printCoefmat(digits = 4, P.values = TRUE, has.Pvalue = TRUE)

# Estimated marginal means
emmeans_avocado <- emmeans(energy_density_1, ~avocado_intake_cat | meal_type, weights = "proportional")
pairs_avocado   <- pairs(emmeans_avocado, adjust = "tukey")
emmeans_tab     <- make_emmeans_tab(emmeans_avocado, pairs_avocado, exponentiate = FALSE, digits = 2)

# Table format
emmeans_tab %>% select(-meal_or_snack)

# Bar chart
emmeans_tab %>% 
  ggplot(aes(x = meal_type, y = emmean, fill = avocado_intake_cat)) +
  geom_col(position = "dodge") +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width = 0.2,
    position = position_dodge(0.9)
  ) +
  facet_wrap(~ meal_or_snack, scales = "free_x") +
  labs(
    title = "Estimated marginal means (with 95% CI) of energy density",
    x = "", 
    y = "Adjusted mean energy density (kcal/gram)",
    fill = "") +
  theme(legend.position = "bottom")


# Effect of avocado intake on the subsequent meal -------------------------

## Food kcal --------------------------------------------------------------

# Run covariates-only model
log_food_kcal_0 <- lme(
  fixed       = fm,
  random      = ~ 1 + visitcode | pid,          
  correlation = corCAR1(form = ~ meal_time_hr | pid/visitcode),
  data        = analytic_df2,
  subset      = !is.na(lag_avocado_intake_cat),
  method      = "REML",
  control = lmeControl(
    opt = "optim",
    maxIter = 200,
    msMaxIter = 200
  )
)

# Check results
# Significant: Weekday, meal_place, meal_freq, daily_kcal
summary(log_food_kcal_0)$tTable %>% 
  printCoefmat(digits = 4, P.values = TRUE, has.Pvalue = TRUE)

# LRT tests for each covariate
lrt_each_covariate(log_food_kcal_0)

# Exponentiate beta coefficients
intervals(log_food_kcal_0, which = "fixed")$fixed %>% exp()

# Add avocado intake * meal type interaction
log_food_kcal_1 <- update(log_food_kcal_0, . ~ . + lag_avocado_intake_cat * meal_type)

# LR test for interaction: Highly signifiacnt
lrt_each_covariate(log_food_kcal_1)

# Check results
summary(log_food_kcal_1)$tTable %>% 
  printCoefmat(digits = 4, P.values = TRUE, has.Pvalue = TRUE)

# Estimated marginal means
emmeans_avocado <- emmeans(log_food_kcal_1, ~lag_avocado_intake_cat | meal_type, weights = "proportional")
pairs_avocado   <- pairs(emmeans_avocado, adjust = "tukey")
emmeans_tab     <- make_emmeans_tab(emmeans_avocado, pairs_avocado, exponentiate = TRUE, digits = 1)

# Table format
emmeans_tab %>% select(-meal_or_snack)

# Bar chart
emmeans_tab %>% 
  ggplot(aes(x = meal_type, y = emmean, fill = lag_avocado_intake_cat)) +
  geom_col(position = "dodge") +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width = 0.2,
    position = position_dodge(0.9)
  ) +
  facet_wrap(~ meal_or_snack, scales = "free_x") +
  labs(
    title = "Estimated marginal means (with 95% CI) of energy density",
    x = "", 
    y = "Adjusted mean energy density (kcal/gram)",
    fill = "") +
  theme(legend.position = "bottom")

pairs(emmeans_avocado, adjust = "tukey")


## Energy density ---------------------------------------------------------

# Run covariates-only model
energy_density_0 <- update(
  log_food_kcal_0, 
  food_density ~ ., 
  subset = !is.na(lag_avocado_intake_cat) & !is.na(food_density))

# Check results
# Significant: Weekday, meal_place, meal_freq, daily_kcal
summary(energy_density_0)$tTable %>% 
  printCoefmat(digits = 4, P.values = TRUE, has.Pvalue = TRUE)

# LRT tests for each covariate
lrt_each_covariate(energy_density_0)

# Beta coefficients
intervals(energy_density_0, which = "fixed")$fixed

# Add avocado intake * meal type interaction
energy_density_1 <- update(energy_density_0, . ~ . + lag_avocado_intake_cat * meal_type)

# LR test for interaction: Not significant
lrt_each_covariate(energy_density_1)

# Remove avocado intake * meal type interaction
energy_density_2 <- update(energy_density_1, . ~ . - lag_avocado_intake_cat:meal_type)

# LR test for interaction: Not significant
lrt_each_covariate(energy_density_2)

# Check results
summary(energy_density_2)$tTable %>% 
  printCoefmat(digits = 4, P.values = TRUE, has.Pvalue = TRUE)

# Estimated marginal means
emmeans_avocado <- emmeans(energy_density_2, ~lag_avocado_intake_cat, weights = "proportional")

summary(emmeans_avocado) %>% 
  as.data.frame() %>% 
  select(lag_avocado_intake_cat, emmean, lower.CL, upper.CL)

pairs_df <- pairs(emmeans_avocado, adjust = "tukey") %>%
  summary() %>%
  as.data.frame() %>%
  select(contrast, p.value) %>%
  mutate(p.value = format.pval(round(p.value, 4), digits = 4, eps = 0.0001, scientific = FALSE)) %>%
  pivot_wider(names_from = contrast, values_from = p.value) %>%
  rename(
    vs_no_avoc  = 1,  # "No avocado at all - <1 avocado"
    vs_no_avoc2 = 2,  # "No avocado at all - 1 whole avocado or more"
    vs_lt_1avoc = 3   # "<1 avocado - 1 whole avocado or more"
  )

emmeans_tab_overall <- summary(emmeans_avocado) %>%
  as.data.frame() %>%
  select(lag_avocado_intake_cat, emmean, lower.CL, upper.CL) %>%
  mutate(across(c(emmean, lower.CL, upper.CL), ~ round(., 2))) %>%
  mutate(
    vs_no_avoc = case_when(
      lag_avocado_intake_cat == levels(lag_avocado_intake_cat)[2] ~ pairs_df$vs_no_avoc,
      lag_avocado_intake_cat == levels(lag_avocado_intake_cat)[3] ~ pairs_df$vs_no_avoc2,
      TRUE ~ NA_character_
    ),
    vs_lt_1avoc = case_when(
      lag_avocado_intake_cat == levels(lag_avocado_intake_cat)[3] ~ pairs_df$vs_lt_1avoc,
      TRUE ~ NA_character_
    )
  )



## Effect of avocado intake on mealtime interval --------------------------







# Memo --------------------------------------------------------------------

# R matrix: Toeplitz structure for meals within visitcode(pid)
model_nlme_tp <- lme(
  food_kcal ~ age + sex + race + bmi + meal_type + meal_place + weekday + daily_kcal100 + avocado_intake_cat * meal_type,
  random = ~ 1 + visitcode | pid,          
  correlation = corARMA(form = ~ 1 | pid/visitcode, p = 0, q = 2),
  data = analytic_df2,
  # method = "REML",
  method = "ML",
  control = lmeControl(
    opt = "optim",
    maxIter = 200,
    msMaxIter = 200)
  )

anova(model_nlme, model_nlme_tp)

# R matrix: Continuous AR(1) structure based on actual meal time
model_nlme_car <- lme(
  food_kcal ~ age + sex + race + bmi + meal_type + meal_place + weekday + daily_kcal100 + avocado_intake_cat * meal_type,
  random = ~ 1 + visitcode | pid,          
  correlation = corCAR1(form = ~ meal_time_hr | pid/visitcode),
  data = analytic_df2,
  # method = "REML",
  method = "ML",
  control = lmeControl(
    opt = "optim",
    maxIter = 200,
    msMaxIter = 200)
)

AIC(model_nlme_tp, model_nlme_car)
BIC(model_nlme_tp, model_nlme_car)

