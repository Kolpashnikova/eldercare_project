# Eldercare Project

author: Kamila Kolpashnikova

## Project Overview

Aging society and the burden of eldercare are one of the biggest challenges of the modern society. 

In this project, I estimate how many person-hours the eldercare will cost us, when the number of caregivers rises from today's level to 50% of the population (estimated to reach in 2100), and if the level of caregivers reaches 80% (hypothetical only).

## Data

Data is from the Bureau of Labor Statistics, which can be downloaded (from multiple files) from this link: ['ATUS Data Link'](https://www.bls.gov/tus/data.htm).

ATUS data is separated into multiple datasets, which were combined in this project. Particularly, the project uses:
- [activity file](https://www.bls.gov/tus/special.requests/atusact-0320.zip)
- [eldercare file](https://www.bls.gov/tus/special.requests/atusrostec-1120.zip). This helps to identify eldecare givers.
- [respondent file](https://www.bls.gov/tus/special.requests/atusresp-0320.zip). This file contains survey weights that were used to weigh the diaries.
- [summary file](https://www.bls.gov/tus/special.requests/atussum-0320.zip). This file contains demographic information such as age and diary day information such as day of the week, which were used to subset the data. The analyses are done for the subsample of those who are of 20-65 years of age and for weekdays.

## Repo Files and Folders

- WranglingATUS.ipynb -- contains jupyter notebook with steps for wrangling ATUS data files
- WranglingATUS.html -- same file in the .html format
- Django_app -- all files for the Django app used for the project

## Procedures performed

- the filter for caregivers is created by merging diary and eldecare givers files
- weights are created merging the diary and respondents files
- ajusted weights are calculated based on the total number of observations
- demographic data is extracted from the summary files and used to subset the data for working age population (>=20 and <65 years of age)
- day of the week data is extracted and merged with the diary data to subset only weekdays (b/c weekends are usually specific and vary a lot compared to weekdays)
- transformed start/stop diary data into sequences of minutes (this makes possible the next step for calculating obsevations at each minute)
- original activity codes are combined into larger categories. For this project into Work/Education, Travel, Housework, Eldercare, Childcare, and Leisure (including sleep)
- timeStamp data is transformed into minute-hour timestamps. Linux time is used.
- observations are counted for each activity of interest for each time/minute of the diary day. 
- these aggregated numbers are used for stacked area plots that report the diary information
- altair is used to create visualizations
- Django app developed for the website 
- the app is hosted on a server     
- domain connected to the website address

## Packages Used:

- altair==4.1.0
- asgiref==3.4.1
- astroid==2.6.6
- attrs==21.2.0
- Django==3.2.6
- django-debug-toolbar==3.2.1
- entrypoints==0.3
- isort==5.9.3
- Jinja2==3.0.1
- jsonschema==3.2.0
- lazy-object-proxy==1.6.0
- MarkupSafe==2.0.1
- mccabe==0.6.1
- numpy==1.21.1
- pandas==1.3.1
- pylint==2.9.6
- pyrsistent==0.18.0
- python-dateutil==2.8.2
- pytz==2021.1
- six==1.16.0
- sqlparse==0.4.1
- toml==0.10.2
- toolz==0.11.1
- wrapt==1.12.1

## Temporary Hosting

[kamilakolpashnikova.com](http://kamilakolpashnikova.com/)

Runs on Chrome
