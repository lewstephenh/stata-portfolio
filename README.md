# Stata Programming Portfolio

Welcome to my Stata programming portfolio!

## Featured Project
## CCD School Data Pipeline (Stata)

`process_ccd_school_data.do` is a reproducible Stata pipeline that integrates multiple Common Core of Data (CCD) source files into a single school-level analysis file for one or more academic years.

### Source Data
All source files are published by the National Center for Education Statistics (NCES):
- **School Directory** (`ccd_sch_029`) — school identifiers, type, level, charter status, and grade range
- **School Geographic Data** (`EDGE_GEOCODE_PUBLICSCH`) — locale code, latitude, and longitude
- **School Staff** (`ccd_sch_059`) — teacher FTE
- **School Lunch Program Eligibility** (`ccd_sch_033`) — counts of students eligible for free, reduced-price, and combined free or reduced-price lunch
- **School Membership** (`ccd_sch_052`) — total enrollment and enrollment by race/ethnicity

### Output
A school-level `.dta` file per academic year containing one record per school, uniquely identified by `ncessch`.

### Features
- Multi-year processing via a single local macro
- Assertion-based merge validation to catch unexpected data anomalies
- Modular section structure with source URLs for reproducibility
- Automated race/ethnicity variable creation using paired macro lists
