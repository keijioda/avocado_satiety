Avocado Satiety Study
================

## Description

- A secondary analysis of the Habitual Diet and Avocado Trial (HAT), a
  randomized clinical trial of two-arm parallel design
- This study examines how avocado consumption affects energy intake,
  energy density, and meal intervals
- The unit of analysis is eating occasion, either meals or snacks

## Datasets

- There are five data files:
  - `macro_protocol3.xlsx`
    - Includes patient demographics
    - n = 900 participants, `cpartid` are all distinct
  - `HAT_SCMeal.csv`
    - Meal-level data from NDSR
    - Used to identify meals containing avocado (`rfgscmFRU500`, in
      serving size)
    - n = 19,643 meals
  - `meal_timdiff_updated.xlsx`
    - Also meal-level data, but time of the meal and meal order were
      manually corrected
    - Includes `Coding` – what types of error was identified for each
      meal, if any  
    - n = 19,643 meals
  - `Gram_kcal_new2.csv`
    - Also meal-level data, but includes total intake as well as food
      intake (excluding beverages)
    - n = 19,643 meals
  - `HAT_Intake.csv`
    - recall-day-level data
    - Includes day of the week, total kcal per day
    - n = 3901 recall days
- Five datasets were merged together to create an analytic dataset

## Inclusion/exclusion criteria

- Note that the data has a three-level nested structure: Participants -
  Recall day - Meals of the day

- At the participant level:

  - Includes only those in the avocado arm

- At the recall-day level:

  - Excludes baseline food recalls (`DT1`)

- At the meal level:

  - Excludes beverage-only eating occasions
  - Excludes meals with total kcal less than 20 kcal
  - Excludes meals with food kcal less than 0.3 kcal (misclassified as
    meals/snacks, rather than beverages)

- After applying inclusion/exclusion criteria, the analytic data
  include:

  - n = 436 participants, all from the avocado arm
  - n = 1,296 recall days
    - Most of the participants (97.2%) have 3 recall days
    - Twelve participants have only 2 recall days
  - n = 4990 meals

## Outcomes

- Total energy content (kcal) of eating occasions

- Energy density (kcal / grams) of eating occasions

  - If the energy density is greater than 9, this was set to as missing
    (implausible)
    - These meals with density \> 9 will be excluded from the analysis
      on energy density

- Meal interval (in hours), or time passed since the previous eating
  occasion of the day, excluding beverages

  - For the first eating occasion of the day, meal interval is NOT
    calculated (missing)
  - Some meal times were incorrectly recorded and the correct times
    could not be determined – set to missing
    - (`Coding = 3 or 5`; beverage-related? See the email from AC on
      5/18/2026)
  - These meals will be excluded from analysis on meal intervals

## Descriptive analysis

### Participant characteristics

<table>

<thead>

<tr>

<th style="text-align:left;">

</th>

<th style="text-align:left;">

level
</th>

<th style="text-align:left;">

Overall
</th>

</tr>

</thead>

<tbody>

<tr>

<td style="text-align:left;font-weight: bold;">

n
</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

436
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

Age, years (mean (SD))
</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

51.0 (14.3)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

Sex (%)
</td>

<td style="text-align:left;">

F
</td>

<td style="text-align:left;">

313 (71.8)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

M
</td>

<td style="text-align:left;">

123 (28.2)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

Race/Ethnicity (%)
</td>

<td style="text-align:left;">

Caucasian
</td>

<td style="text-align:left;">

317 (72.7)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

African American
</td>

<td style="text-align:left;">

59 (13.5)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

Asian
</td>

<td style="text-align:left;">

24 ( 5.5)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

Other
</td>

<td style="text-align:left;">

36 ( 8.3)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

Education level (%)
</td>

<td style="text-align:left;">

None
</td>

<td style="text-align:left;">

29 ( 6.7)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

Vocational school
</td>

<td style="text-align:left;">

51 (11.7)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

College degree
</td>

<td style="text-align:left;">

231 (53.0)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

Graduate degree
</td>

<td style="text-align:left;">

125 (28.7)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

Region (%)
</td>

<td style="text-align:left;">

East coast
</td>

<td style="text-align:left;">

216 (49.5)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

West coast
</td>

<td style="text-align:left;">

220 (50.5)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

BMI category (%)
</td>

<td style="text-align:left;">

Normal
</td>

<td style="text-align:left;">

10 ( 2.3)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

Overweight
</td>

<td style="text-align:left;">

137 (31.4)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

</td>

<td style="text-align:left;">

Obese
</td>

<td style="text-align:left;">

289 (66.3)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

BMI, kg/m² (mean (SD))
</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

32.7 (5.2)
</td>

</tr>

<tr>

<td style="text-align:left;font-weight: bold;">

Waist circumference, cm (mean (SD))
</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

109.0 (12.7)
</td>

</tr>

</tbody>

</table>

### Recall day

- Out of 1,296 recall days, about 30% were during weekends
  - The number of recalls on Fridays was notably lower compared to other
    days of the week
- The number of meals/snacks eaten across days of the week appears to be
  consistent
- Meal kcal per day appears to be higher on Saturdays

| Day of the week | No. recalls |     % | Mean \# of meals | Mean kcal/day |
|:----------------|------------:|------:|-----------------:|--------------:|
| Sun             |         211 | 16.28 |             3.81 |       2001.72 |
| Mon             |         219 | 16.90 |             3.83 |       1996.40 |
| Tue             |         226 | 17.44 |             3.87 |       1996.01 |
| Wed             |         198 | 15.28 |             3.74 |       1950.24 |
| Thur            |         177 | 13.66 |             3.90 |       2060.80 |
| Fri             |          92 |  7.10 |             3.89 |       2086.94 |
| Sat             |         173 | 13.35 |             3.95 |       2205.96 |

### Meal-level

#### Meal type

- Definition: Meal type (meal period):
  - Morning meal (00:00 to 11:00)
  - Midday meal (11:01 to 16:59)
  - Evening meal (17:00 to 23:59)
  - Morning snack (00:00 to 11:59)
  - Evening snacks (12:00 to 16:59)
  - Late-night snack (17:00 to 23:59)
- Frequency table by meal/snack and mean energy per meal
  - The number of morning, midday, evening meals were approximately
    equal
  - The number of snacks increases as the day progresses
  - The energy content of meals and snacks also increases as the day
    progresses

| Meal/Snack       | n    | %    | Mean total kcal (SD) | Mean food kcal (SD) |
|:-----------------|:-----|:-----|:---------------------|:--------------------|
| Morning meal     | 1136 | 22.8 | 466.71 (277.65)      | 432.40 (268.25)     |
| Midday meal      | 1127 | 22.6 | 641.17 (356.95)      | 611.38 (340.15)     |
| Evening meal     | 1178 | 23.6 | 745.28 (416.80)      | 692.06 (388.46)     |
| Morning snack    | 326  | 6.5  | 255.31 (332.02)      | 243.39 (316.24)     |
| Midday snack     | 586  | 11.7 | 266.21 (224.17)      | 257.09 (220.56)     |
| Late night snack | 637  | 12.8 | 306.48 (260.18)      | 280.26 (232.30)     |

- A density plot of food kcal by meal and snack type shows a similar
  trend

![](summary_files/figure-gfm/meal_density-1.png)<!-- -->

#### Meal place

- Meal place
  - Among 4,990 meals, 68% of them were eaten at home or friend’s home
  - The energy content was much higher when eaten at delis/restaurants
    or ordering takeout

| Meal place | n | % | Mean total kcal (SD) | Mean food kcal (SD) |
|:---|:---|:---|:---|:---|
| Home/Friend’s home | 3401 | 68.2 | 490.55 (353.83) | 459.50 (337.55) |
| Work/School | 802 | 16.1 | 440.81 (326.28) | 425.18 (318.40) |
| Deli/Take-out/Restaurant | 530 | 10.6 | 789.61 (441.21) | 728.33 (397.96) |
| Daycare/Party/Travelling/Other | 256 | 5.1 | 484.45 (452.00) | 443.32 (412.07) |

### Outcomes

#### Energy content (food kcal)

- The distribution of food kcal per meal/snack is right-skewed
  - The mean (SD) food kcal was 482 (355.3) kcal

|  Min |    Q1 | Median |  Mean |    SD |    Q3 |    Max |
|-----:|------:|-------:|------:|------:|------:|-------:|
| 16.5 | 229.9 |  406.6 | 481.8 | 356.1 | 642.3 | 4618.5 |

![](summary_files/figure-gfm/distr_food_kcal-1.png)<!-- -->

#### Energy density

- The distribution of food density is slightly right-skewed
  - The mean (SD) food density was 2.17 (1.31) kcal/g

|  Min |   Q1 | Median | Mean |   SD |   Q3 |  Max |
|-----:|-----:|-------:|-----:|-----:|-----:|-----:|
| 0.07 | 1.27 |   1.82 | 2.17 | 1.31 | 2.68 | 6.91 |

![](summary_files/figure-gfm/distr_food_density-1.png)<!-- -->

#### Meal interval

|  Min |   Q1 | Median | Mean |   SD |  Q3 | Max |
|-----:|-----:|-------:|-----:|-----:|----:|----:|
| 0.25 | 2.25 |    3.5 | 3.75 | 1.96 |   5 |  14 |

![](summary_files/figure-gfm/distr_meal_interval-1.png)<!-- -->

### Avocado intake

#### Distribution of avocado intake

- A histogram of avocado intake (grams) per meal/snack is shown below
  - The distribution of avocado intake per meal was trimodal, with the
    three largest bars corresponding to:
    - No avocado (0 grams) – 70% of all meals
    - One-half (84 grams) – 7.4%
    - One whole avocado (168 grams) – 20%
  - The max avocado intake per meal was 504 grams

![](summary_files/figure-gfm/avocado_histogram-1.png)<!-- -->

- Given the distribution of avocado, meals/snaks were categorized into
  the following 3 groups by avocado consumption:

| Avocado intake          |    n |    % |
|:------------------------|-----:|-----:|
| No avocado at all       | 3492 | 70.0 |
| \<1 avocado             |  503 | 10.1 |
| 1 whole avocado or more |  995 | 19.9 |

#### Food kcal by meal type and avocado intake

- Mean (SD) food kcal by meal type and avocado intake are shown below:
  - Food kcal increases with avocado intake for both meals and snacks

| Meal type | No avocado:<br> N | No avocado:<br> Mean ± SD | \<1 avocado:<br> N | \<1 avocado:<br> Mean ± SD | 1+ avocado:<br> N | 1+ avocado:<br> Mean ± SD |
|:---|---:|:---|---:|:---|---:|:---|
| Morning meal | 714 | 385 ± 269 | 138 | 445 ± 209 | 284 | 545 ± 259 |
| Midday meal | 696 | 569 ± 344 | 150 | 556 ± 242 | 281 | 745 ± 342 |
| Evening meal | 792 | 644 ± 378 | 144 | 669 ± 333 | 242 | 863 ± 406 |
| Morning snack | 276 | 223 ± 324 | 20 | 243 ± 115 | 30 | 435 ± 277 |
| Midday snack | 486 | 236 ± 225 | 26 | 249 ± 116 | 74 | 401 ± 160 |
| Late night snack | 528 | 264 ± 242 | 25 | 361 ± 263 | 84 | 361 ± 111 |

![](summary_files/figure-gfm/food_kcal_by_mealtype_avocado-1.png)<!-- -->

#### Food density by meal type and avocado intake

- Mean (SD) food density by meal type and avocado intake are shown
  below:
  - Food density decreases with avocado intake for meals

| Meal type | No avocado:<br> N | No avocado:<br> Mean ± SD | \<1 avocado:<br> N | \<1 avocado:<br> Mean ± SD | 1+ avocado:<br> N | 1+ avocado:<br> Mean ± SD |
|:---|---:|:---|---:|:---|---:|:---|
| Morning meal | 714 | 2.15 ± 1.14 | 138 | 1.81 ± 0.53 | 284 | 1.68 ± 0.38 |
| Midday meal | 696 | 1.92 ± 0.94 | 150 | 1.69 ± 0.56 | 281 | 1.64 ± 0.52 |
| Evening meal | 792 | 1.78 ± 0.81 | 144 | 1.64 ± 0.5 | 242 | 1.64 ± 0.48 |
| Morning snack | 276 | 2.66 ± 1.9 | 20 | 1.53 ± 0.51 | 30 | 1.76 ± 0.47 |
| Midday snack | 486 | 3.25 ± 1.86 | 26 | 1.81 ± 0.71 | 74 | 1.71 ± 0.37 |
| Late night snack | 528 | 3.27 ± 1.76 | 25 | 1.65 ± 0.74 | 84 | 1.7 ± 0.33 |

![](summary_files/figure-gfm/food_density_by_mealtype_avocado-1.png)<!-- -->

#### Prior avocado intake

- Among 3,694 meals/snacks (excluding the first eating occasions of the
  day), 69% of the meals/snack did not have any avocado intake at the
  preceding eating occasion
  - The meal interval appears to increase with greater avocado intake at
    the preceding eating occasion
  - The mean energy intake (from food) was lowest when less than one
    avocado was consumed at the preceding eating occasion

| Prior avocado intake | n | % | Mean meal interval (SD) | Mean food kcal (SD) |
|:---|---:|---:|:---|:---|
| No avocado at all | 2556 | 69.19 | 3.62 ± 1.89 | 509.8 ± 377.6 |
| \<1 avocado | 390 | 10.56 | 3.88 ± 2.06 | 409.7 ± 301.5 |
| 1 whole avocado or more | 748 | 20.25 | 4.13 ± 2.09 | 487.8 ± 402.7 |

- When stratified by meal type, the meal interval increased with greater
  avocado intake at the preceding eating occasion for midday and evening
  meals, but not for morning meals

![](summary_files/figure-gfm/prior_avocado_meal_interval-1.png)<!-- -->

- When stratified by meal type, the mean energy content was lowest when
  less than one avocado was consumed at the preceding eating occasion
  for all meals (morning, midday, and evening meals)
  - For snacks, the mean energy content was highest when no avocado was
    consumed at the preceding eating occasion

![](summary_files/figure-gfm/prior_avocado_food_kcal-1.png)<!-- -->

## Model

- \[**In progress**\] To examine the effect of avocado consumption on
  three outcomes – meal energy intake (kcal from food), dietary energy
  density (kcal/g), and mealtime interval (hours between consecutive
  eating occasions) – we fitted separate linear mixed effects models for
  each outcome using the `lme` function from the `nlme` package in R

- Each model accounted for the three-level nested structure of the data,
  where eating occasions (level 1) were nested within recall days (level
  2), which were in turn nested within participants (level 3)

- The same covariance structure was applied across all three models,
  with an unstructured G matrix at the participant level to capture
  between-person variability in both baseline outcomes and
  recall-to-recall changes, and a compound symmetry structure (???) for
  the R matrix to account for the correlation among meals consumed
  within the same recall day

- Models for food kcal and food density

  - log transform or not?

- Models for meal interval

### Covariates

- \[**In progress**\] Covariates in the mixed models include:
  - Age at baseline
  - Race
  - Education level (May be dropped after model results?)
  - BMI
  - Residential region (May be dropped after model results?)
  - Day of the week
  - Total daily kcal
  - Meal type
  - Meal place
  - Meal frequency
  - Previous meal (meal type? meal or snack?)
  - Previous avocado intake
  - Interactions
    - Avocao intake (on the same meal) \* Meal type
    - Meal after avocado (yes/no) \* Meal type
  - 3-way interactions?
