# load csv of choice
data <- read.csv(file.choose())

# assess structure of data
str(data)

# packages
library(lubridate) # load lubridate for working with dates
library(dplyr) # dplyr for manipulated data
library(ggplot2) # for visualizations
library(rmarkdown) # to create report

# convert date to date type
data$date <- as.Date(data$date, format="%Y-%m-%d")

# select desired columns
sel_data <- data %>%
  select(date, Total.Sleep.Duration, REM.Sleep.Duration, Light.Sleep.Duration, 
         Deep.Sleep.Duration, Sleep.Efficiency, Average.Resting.Heart.Rate,
         Lowest.Resting.Heart.Rate, Average.HRV, Respiratory.Rate, 
         Activity.Burn, Steps, Inactive.Time, Long.Periods.of.Inactivity, 
         Restless.Sleep)

# check structure of selected dataframe
str(sel_data)

# seconds to hours function
sec_to_hour <- function(x) x/3600

# apply seconds to hours function to time duration columns
sel_data[c('Total.Sleep.Duration', 'REM.Sleep.Duration', 'Light.Sleep.Duration',
           'Deep.Sleep.Duration', 'Inactive.Time')] <- lapply(sel_data[
             c('Total.Sleep.Duration', 'REM.Sleep.Duration', 
               'Light.Sleep.Duration', 'Deep.Sleep.Duration', 'Inactive.Time')],
             sec_to_hour)

# create % of hours slept for each sleep cycle columns
sel_data$perc_REM <- sel_data$REM.Sleep.Duration / 
  sel_data$Total.Sleep.Duration * 100

sel_data$perc_Light <- sel_data$Light.Sleep.Duration / 
  sel_data$Total.Sleep.Duration * 100

sel_data$perc_Deep <- sel_data$Deep.Sleep.Duration / 
  sel_data$Total.Sleep.Duration * 100

# check descriptive statistics of sel_data
summary(sel_data)

# create quarter with year column
sel_data$qtr_yr <- paste(quarters(sel_data$date), year(sel_data$date))

# initialize empty vector for ordered quarter and year pairs
factored_qtrs <- c()

# nested for loops to create ordered vector of quarter + year
for (yr in unique(year(sel_data$date)))
{
  
  for (qtr in unique(quarters(sel_data$date)))
  {
    factored_qtrs = c(factored_qtrs, paste(qtr, yr))
  }
}

# set qtr_yr as a factor and set factor levels
sel_data$qtr_yr <- as.factor(sel_data$qtr_yr)
sel_data$qtr_yr <- factor(sel_data$qtr_yr, levels = factored_qtrs)

# look at total sleep over time
ggplot(sel_data, aes(qtr_yr, Total.Sleep.Duration)) +
  geom_boxplot() +
  geom_hline(aes(yintercept = mean(Total.Sleep.Duration, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Total Sleep Duration by Quarters", x = "Quarter by Year",
       y = "Total Sleep in Hours",
       caption = paste("Dashed line represents the average time slept of",
                       round(mean(sel_data$Total.Sleep.Duration, na.rm=TRUE), 
                             digits = 2), "hours."))

# create dataframe for REM cycle stats
rem_sleep <- sel_data %>%
  select(date, qtr_yr, REM.Sleep.Duration, perc_REM) %>%
  mutate(cycle = 'REM') %>%
  rename(cycle_duration = REM.Sleep.Duration, perc_duration = perc_REM)

# create dataframe for light cycle stats
light_sleep <- sel_data %>%
  select(date, qtr_yr, Light.Sleep.Duration, perc_Light) %>%
  mutate(cycle = 'Light') %>%
  rename(cycle_duration = Light.Sleep.Duration, perc_duration = perc_Light)

# create dataframe for deep cycle stats
deep_sleep <- sel_data %>%
  select(date, qtr_yr, Deep.Sleep.Duration, perc_Deep) %>%
  mutate(cycle = 'Deep') %>%
  rename(cycle_duration = Deep.Sleep.Duration, perc_duration = perc_Deep)

# union all from sleep cycle stat df's into one dataframe
sleep_cycles <- union_all(rem_sleep, deep_sleep)

# create dataframe of sleep cycle averages by qtr
avg_qtr_cycles <- sleep_cycles %>% 
  group_by(cycle, qtr_yr) %>%
  summarize(avg_cycle_duration = mean(cycle_duration, na.rm = TRUE),
            avg_perc_duration = mean(perc_duration, na.rm = TRUE))

# visualize percentage of sleep in each sleep cycle
ggplot(avg_qtr_cycles, aes(qtr_yr, avg_cycle_duration, fill = cycle)) +
  geom_col(position = 'dodge') +
  labs(title = "Average Nightly Sleep Cycle Duration by Quarter",
       x = "Quarter by Year", y = "Duration in Hours", caption = 
       "As per the Oura ring app, on average the optimal amount of REM sleep 
       hours starts with 1.5. For Deep sleep, it is 1 - 1.5 hours. Both are 
       expected to decrease with age.")

# view mean sleep efficiency by quarter
sel_data %>%
  group_by(qtr_yr) %>%
  summarize(avg_sleep_eff = mean(Sleep.Efficiency, na.rm = TRUE))

# look at avg HRV over time
ggplot(sel_data, aes(x = qtr_yr, y = Average.HRV)) +
  geom_boxplot() +
  geom_hline(aes(yintercept = mean(Average.HRV, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Average HRV by Quarters", x = "Quarter by Year",
       y = "Average HRV at Night",
       caption = paste("Dashed line represents overall average HRV of",
                       round(mean(sel_data$Average.HRV, na.rm=TRUE), 
                             digits = 2)))

# steps over time
ggplot(sel_data, aes(date, Steps)) +
  geom_line() +
  geom_hline(aes(yintercept = mean(Steps, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Daily Steps Over Time", x = "Date",
       y = "Daily Steps",
       caption = paste("Dashed line represents overall average daily steps of",
                       round(mean(sel_data$Steps, na.rm=TRUE), 
                             digits = 2)))

# Inactive Time by Date
ggplot(sel_data, aes(date, Inactive.Time)) +
  geom_line() +
  geom_hline(aes(yintercept = mean(Inactive.Time, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Daily Inactive Hours by Date", x = "Date",
       y = "Inactive Hours",
       caption = paste("Dashed line represents overall average daily 
                       inactive hours of", round(mean(sel_data$Inactive.Time, 
                                                   na.rm=TRUE), digits = 2)))

# Get data for past 90 days
past_90_days <- sel_data %>%
  filter(date >= max(date) - days(89))

# Total Sleep Duration Past 90 Days
ggplot(past_90_days, aes(date, Total.Sleep.Duration)) +
  geom_area(fill = "forestgreen") +
  geom_hline(aes(yintercept = mean(Total.Sleep.Duration, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Total Sleep Duration Past 90 Days", x = "Date",
       y = "Total Sleep in Hours",
       caption = paste("Dashed line represents the mean time slept of",
                       round(mean(past_90_days$Total.Sleep.Duration, na.rm=TRUE), 
                             digits = 2), "hours."))

# create dataframe for REM cycle stats past 90
rem_sleep_past_90 <- past_90_days %>%
  select(date, qtr_yr, REM.Sleep.Duration, perc_REM) %>%
  mutate(cycle = 'REM') %>%
  rename(cycle_duration = REM.Sleep.Duration, perc_duration = perc_REM)

# create dataframe for deep cycle stats past 90
deep_sleep_past_90 <- past_90_days %>%
  select(date, qtr_yr, Deep.Sleep.Duration, perc_Deep) %>%
  mutate(cycle = 'Deep') %>%
  rename(cycle_duration = Deep.Sleep.Duration, perc_duration = perc_Deep)

# union all from sleep cycle stat df's into one dataframe
sleep_cycles_past_90 <- union_all(rem_sleep_past_90, deep_sleep_past_90)

# Sleep Cycles Past 90 days
ggplot(sleep_cycles_past_90, aes(date, cycle_duration, color = cycle)) +
  geom_line() +
  labs(title = "Sleep Cycle Duration Past 90 Days",
       x = "Date", y = "Duration in Hours", caption = 
         "As per the Oura ring app, on average the optimal amount of REM sleep 
       hours starts with 1.5. For Deep sleep, it is 1 - 1.5 hours. Both are 
       expected to decrease with age. Dashed line added for 1.5 hour 
       reference.") +
  geom_hline(aes(yintercept = 1.5), linetype = "dashed")

# HRV Past 90 Days
ggplot(past_90_days, aes(date, Average.HRV)) +
  geom_area(fill = "maroon") +
  geom_hline(aes(yintercept = mean(Average.HRV, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Average HRV Past 90 Days", x = "Date",
       y = "Average HRV at Night",
       caption = paste("Dashed line represents average HRV of",
                       round(mean(past_90_days$Average.HRV, na.rm=TRUE), 
                             digits = 2)))

# Steps Past 90 Days
ggplot(past_90_days, aes(date, Steps)) +
  geom_area(fill = "orange") +
  geom_hline(aes(yintercept = mean(Steps, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Daily Steps Past 90 Days", x = "Date",
       y = "Daily Steps",
       caption = paste("Dashed line represents average daily steps of",
                       round(mean(past_90_days$Steps, na.rm=TRUE), 
                             digits = 2)))

# Inactive Time Past 90 Days
ggplot(past_90_days, aes(date, Inactive.Time)) +
  geom_area(fill = "deeppink") +
  geom_hline(aes(yintercept = mean(Inactive.Time, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Daily Inactive Hours Past 90 Days", x = "Date",
       y = "Inactive Hours",
       caption = paste("Dashed line represents average daily 
                       inactive hours of", 
                       round(mean(past_90_days$Inactive.Time, na.rm=TRUE), 
                             digits = 2)))

# Resting Heart Rate All Time
ggplot(sel_data, aes(x = qtr_yr, y = Average.Resting.Heart.Rate)) +
  geom_boxplot() +
  geom_hline(aes(yintercept = mean(Average.Resting.Heart.Rate, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Average Resting Heart Rate by Quarters", x = "Quarter by Year",
       y = "Average Resting Heart Rate at Night",
       caption = paste("Dashed line represents overall average resting heart
                       rate of",
                       round(mean(sel_data$Average.Resting.Heart.Rate, 
                                  na.rm=TRUE), digits = 2)))

# avg resting heart rate Past 90 Days
ggplot(past_90_days, aes(date, Average.Resting.Heart.Rate)) +
  geom_area(fill = "orange") +
  geom_hline(aes(yintercept = mean(Average.Resting.Heart.Rate, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Average Resting Heart Rate Past 90 Days", x = "Date",
       y = "Average Resting Heart Rate at Night",
       caption = paste("Dashed line represents average resting heart rate of",
                       round(mean(past_90_days$Average.Resting.Heart.Rate, 
                                  na.rm=TRUE), digits = 2)))

# respiratory rate all time
ggplot(sel_data, aes(x = qtr_yr, y = Respiratory.Rate)) +
  geom_boxplot() +
  geom_hline(aes(yintercept = mean(Respiratory.Rate, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Nightly Respiratory Rate by Quarters", x = "Quarter by Year",
       y = "Respiratory Rate",
       caption = paste("Dashed line represents overall average respiratory
                       rate of",
                       round(mean(sel_data$Respiratory.Rate, 
                                  na.rm=TRUE), digits = 2)))

# respiratory rate Past 90 Days
ggplot(past_90_days, aes(date, Respiratory.Rate)) +
  geom_area(fill = "lightblue") +
  geom_hline(aes(yintercept = mean(Respiratory.Rate, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Nightly Respiratory Rate Past 90 Days", x = "Date",
       y = "Respiratory Rate",
       caption = paste("Dashed line represents average respiratory rate of",
                       round(mean(past_90_days$Respiratory.Rate, 
                                  na.rm=TRUE), digits = 2)))

#sleep efficiency all time
ggplot(sel_data, aes(x = qtr_yr, y = Sleep.Efficiency)) +
  geom_boxplot() +
  geom_hline(aes(yintercept = mean(Sleep.Efficiency, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Sleep Efficiency Score by Quarters", x = "Quarter by Year",
       y = "Sleep Efficiency Score",
       caption = paste("Dashed line represents overall average sleep efficiency
                       score of",
                       round(mean(sel_data$Sleep.Efficiency, 
                                  na.rm=TRUE), digits = 2)))

# sleep efficiency Past 90 Days
ggplot(past_90_days, aes(date, Sleep.Efficiency)) +
  geom_area(fill = "forestgreen") +
  geom_hline(aes(yintercept = mean(Sleep.Efficiency, na.rm=TRUE)), 
             linetype = "dashed") +
  labs(title = "Sleep Efficiency Score Past 90 Days", x = "Date",
       y = "Sleep Efficiency Score",
       caption = paste("Dashed line represents average sleep efficiency score
                       of", round(mean(past_90_days$Sleep.Efficiency, 
                                  na.rm=TRUE), digits = 2)))

# Get original column names from data
colnames(data)