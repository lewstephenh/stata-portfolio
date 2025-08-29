* -----------------------------------------------------------------------------
* regression_analysis.do
*
* This program reads data used in the California School Dashboard and performs
* linear regression analyses of percent of students who are socioeconomically
* disadvantaged on distance from standard on math and ELA among high schools.
*
* Written by Stephen Lew
* -----------------------------------------------------------------------------
cd "C:/Users/Public/Documents"



* -----------------------------------------------------------------------------
* Extract data on total enrollment and percent of students who are
* socioeconomically disadvantaged
* -----------------------------------------------------------------------------
import delimited using https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2024.txt, clear stringcols(1)

* Keep only records for schools. Drop district and state records.
keep if rtype == "S"

* Keep the record with data on socioeconomically disadvantaged students if possible.
* Schools that do not have any socioeconomically disadvantaged students do not
* have such a record. For those schools, keep the first record and then set the
* percentage of socioeconomically disadvantaged students to zero.
generate sed_record = 1 if studentgroup == "SED"
replace sed_record = 0 if missing(sed_record) == 1

gsort cds -sed_record
duplicates drop cds, force
* Data is now one record per school uniquely identified by cds

replace rate = 0 if sed_record == 0

keep cds schoolname districtname totalenrollment rate
rename rate sed
label variable cds "County-District-School Code"
label variable schoolname "School Name"
label variable districtname "District Name"
label variable totalenrollment "Total census day enrollment for all students"
label variable sed "Enrollment rate for socioeconomically disadvantaged students"
save enrollment, replace



* -----------------------------------------------------------------------------
* Extract data on distance from standard on math and ELA
* -----------------------------------------------------------------------------
capture program drop extract_assessments
program define extract_assessments
	import delimited using https://www3.cde.ca.gov/researchfiles/cadashboard/`1'download2024.txt, clear stringcols(1)
	
	* Keep only records for schools that have the data for all students.
	keep if rtype == "S" & studentgroup == "ALL"
	* Data is now one record per school uniquely identified by cds
	
	keep cds currstatus
	rename currstatus `1'
	label variable cds "County-District-School Code"
	label variable `1' "Average Distance From Standard (`2')"
	save `1', replace
end

extract_assessments "math" "Math"
extract_assessments "ela" "ELA"



* -----------------------------------------------------------------------------
* Extract a list of high schools. High schools have a record in the graduation
* rate data
* -----------------------------------------------------------------------------
import delimited using https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2024.txt, clear stringcols(1)

* Keep only records for schools. Drop district and state records.
keep if rtype == "S"
keep cds
label variable cds "County-District-School Code"
duplicates drop cds, force
* Data is now one record per school uniquely identified by cds



* -----------------------------------------------------------------------------
* Integrate the data
* -----------------------------------------------------------------------------
merge 1:1 cds using enrollment
keep if _merge == 3
drop _merge
merge 1:1 cds using math
drop if _merge == 2
drop _merge
merge 1:1 cds using ela
drop if _merge == 2
drop _merge
erase enrollment.dta
erase math.dta
erase ela.dta



* -----------------------------------------------------------------------------
* Summary statistics
* -----------------------------------------------------------------------------
summarize math ela sed totalenrollment



* -----------------------------------------------------------------------------
* Linear regression analyses of percent of students who are socioeconomically
* disadvantaged on distance from standard on math and ELA among high schools. Total
* enrollment is used as the analytic weight.
* -----------------------------------------------------------------------------
capture program drop reg_sed_assessments
program define reg_sed_assessments
	regress `1' sed [aweight = totalenrollment]
	predict `1'predicted if e(sample) & !missing(`1')
	predict `1'resid if e(sample) & !missing(`1'), residuals
	graph twoway (scatter `1' sed) (line `1'predicted sed)
end

reg_sed_assessments "math"
reg_sed_assessments "ela"

export delimited "C:/Users/Public/Documents/regression_analysis_stata.csv", replace
