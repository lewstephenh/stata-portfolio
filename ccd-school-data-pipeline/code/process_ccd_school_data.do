* process_ccd_school_data.do
* Author: Stephen Lew
* Date Created: June 21, 2026
* Description: Integrate CCD school data into an analysis file
* Source files: ccd_sch_029, EDGE_GEOCODE_PUBLICSCH, ccd_sch_059,
*               ccd_sch_033, ccd_sch_052
* Output: ${processed_data}/sch[year].dta

* Set command interpreter to version 19.
version 19

* Set the line width to 140 characters.
set linesize 140

* Assign folder paths to global macro names.
global raw_data "S:/data/raw"
global processed_data "S:/data/processed"

* Assign CCD years to be processed to local macro name.
local ccdyears "2024 2025"

* Integrate CCD school data into an analysis file.
foreach yr of local ccdyears {


    *---------------------------------------------------------------------------
    * School Directory (https://nces.ed.gov/ccd/Data/zip/ccd_sch_029*.zip)
    * Number of records per case: Single record for each school uniquely
    * identified by ncessch.
    *---------------------------------------------------------------------------
    
    * Import the SAS file ccd_sch_029.sas7bdat into memory.
    import sas using "${raw_data}/`yr'/ccd_sch_029.sas7bdat", clear case(l)
    
    * Keep variables we want in the analysis file.
    keep ncessch fipst st_leaid st_schid sch_type level charter_text gslo gshi
    
    * Move ncessch (School Identifier (NCES)) and fipst (American National
    * Standards Institute (ANSI) state code) to the beginning of the dataset.
    order ncessch fipst
    
    * Change the variable names to have the suffix of "s" (which stands for
    * "school"), followed by an underscore and then the year.
    rename st_leaid stids_`yr' // State Local Education Number. State's own ID for the education agency.
    rename st_schid seaschs_`yr' // State school identifier
    rename sch_type types_`yr' // School type (code)
    rename level levels_`yr' // School level
    rename charter_text chartrs_`yr' // Whether a Charter school
    rename gslo gslos_`yr' // Grades Offered - Lowest
    rename gshi gshis_`yr' // Grades Offered - Highest
    
    * Reduce the amount of memory used by the dataset
    compress
    
    * Save the data in memory on disk.
    save "${processed_data}/sch`yr'", replace


    *---------------------------------------------------------------------------
    * School Geographic Data (https://nces.ed.gov/programs/edge/data/EDGE_GEOCODE_PUBLICSCH*.zip)
    * Number of records per case: Single record for each school uniquely 
    * identified by ncessch.
    *---------------------------------------------------------------------------
    
    import sas using "${raw_data}/`yr'/EDGE_GEOCODE_PUBLICSCH.sas7bdat", clear case(l)
    keep ncessch locale lat lon
    rename locale ulocals_`yr' // Locale code
    rename lat latcods_`yr' // Latitude of school location
    rename lon loncods_`yr' // Longitude of school location
    
    * Create name for temporary file.
    tempfile sch_geographic_`yr'
    
    * Save the data in memory to temporary file.
    save "`sch_geographic_`yr''", replace
    
    * Load processed data into memory.
    use "${processed_data}/sch`yr'", clear
    
    * One-to-one merge of processed data with school geographic data on ncessch.
    merge 1:1 ncessch using "`sch_geographic_`yr''"
    
    * No records should exist only in geographic file.
    * If the assertion is true, then the assert command produces no output.
    * If the assertion is false, then the assert command returns an error.
    assert _merge != 2
    
    * Drop the variable containing the match results.
    drop _merge
    
    compress
    save "${processed_data}/sch`yr'", replace


    *---------------------------------------------------------------------------
    * School Staff (https://nces.ed.gov/ccd/Data/zip/ccd_sch_059*.zip)
    * Number of records per case: Single record for each school uniquely 
    * identified by ncessch.
    * Schools with no staff data will have missing values for ftes_`yr'.
    *---------------------------------------------------------------------------
    
    import sas using "${raw_data}/`yr'/ccd_sch_059.sas7bdat", clear case(l)
    keep ncessch teachers
    rename teachers ftes_`yr' // Teacher FTE
    tempfile sch_staff_`yr'
    save "`sch_staff_`yr''", replace
    use "${processed_data}/sch`yr'", clear
    merge 1:1 ncessch using "`sch_staff_`yr''"
    assert _merge != 2
    drop _merge
    compress
    save "${processed_data}/sch`yr'", replace


    *---------------------------------------------------------------------------
    * School Lunch Program Eligibility (https://nces.ed.gov/ccd/Data/zip/ccd_sch_033*.zip)
    * Number of records per case: Multiple records for each school. Each record
    * uniquely identified by ncessch lunch_program.
    * Schools with no school lunch program eligibility data will have missing
    * values for frelchs_`yr', redlchs_`yr', and totfrls_`yr'.
    *---------------------------------------------------------------------------

    import sas using "${raw_data}/`yr'/ccd_sch_033.sas7bdat", clear case(l)
        preserve
            keep if lunch_program == "Free lunch qualified"
            keep ncessch student_count
            rename student_count frelchs_`yr' // Number of students eligible for free lunch
            tempfile sch_lunch_frelchs_`yr'
            save "`sch_lunch_frelchs_`yr''", replace
            use "${processed_data}/sch`yr'", clear
            merge 1:1 ncessch using "`sch_lunch_frelchs_`yr''"
            assert _merge != 2
            drop _merge
            compress
            save "${processed_data}/sch`yr'", replace
        restore
        preserve
            keep if lunch_program == "Reduced-price lunch qualified"
            keep ncessch student_count
            rename student_count redlchs_`yr' // Number of students eligible for reduced-price lunch
            tempfile sch_lunch_redlchs_`yr'
            save "`sch_lunch_redlchs_`yr''", replace
            use "${processed_data}/sch`yr'", clear
            merge 1:1 ncessch using "`sch_lunch_redlchs_`yr''"
            assert _merge != 2
            drop _merge
            compress
            save "${processed_data}/sch`yr'", replace
        restore
        preserve
            keep if inlist(lunch_program,"Free lunch qualified","Reduced-price lunch qualified")
            keep ncessch student_count
            
            * Replace the dataset in memory with the sum of student_count for each school.
            collapse (sum) student_count, by(ncessch)

            rename student_count totfrls_`yr' // Number of students eligible for free or reduced-price lunch
            tempfile sch_lunch_totfrls_`yr'
            save "`sch_lunch_totfrls_`yr''", replace
            use "${processed_data}/sch`yr'", clear
            merge 1:1 ncessch using "`sch_lunch_totfrls_`yr''"
            assert _merge != 2
            drop _merge
            compress
            save "${processed_data}/sch`yr'", replace
        restore


    *---------------------------------------------------------------------------
    * School Membership (https://nces.ed.gov/ccd/Data/zip/ccd_sch_052*.zip)
    * Number of records per case: Multiple records for each entity. Each record
    * is uniquely identified by ncessch grade race_ethnicity sex total_indicator.
    * Schools missing membership data will have missing values for members_`yr',
    * blacks_`yr', pacifics_`yr', asians_`yr', whites_`yr', ams_`yr', trs_`yr',
    * and hisps_`yr'.
    *---------------------------------------------------------------------------
    
    import sas using "${raw_data}/`yr'/ccd_sch_052.sas7bdat", clear case(l)
        preserve
            keep if total_indicator == "Derived - Education Unit Total minus Adult Education Count"
            keep ncessch student_count
            rename student_count members_`yr' // Total number of students
            tempfile sch_membership_members_`yr'
            save "`sch_membership_members_`yr''", replace
            use "${processed_data}/sch`yr'", clear
            merge 1:1 ncessch using "`sch_membership_members_`yr''"
            assert _merge != 2
            drop _merge
            compress
            save "${processed_data}/sch`yr'", replace
        restore

        * Macros that will serve as paired lists when creating variables for the
        * number of students of a race/ethnicity category.
        * We won't be adding variables for "Total number of students with no 
        * category codes for race/ethnicity" and "Total number of students with
        * race/ethnicity not specified" to the analysis file.
        local races `" "Black or African American" "Native Hawaiian or Other Pacific Islander" "Asian" "White" "American Indian or Alaska Native" "Two or more races" "Hispanic/Latino" "'
        local stubs "black pacific asian white am tr hisp"

        local i = 1
        
        * Number of tokens in `races'
        * word count correctly counts quoted tokens in a compound-quoted list.
        local n: word count `races'
        
        * While loop will execute for each token in `races'
        while `i' <= `n' {
            * Assign the ith token to local macro names
            local race_word: word `i' of `races'
            local stub_word: word `i' of `stubs'
            
            display "Processing race/ethnicity: `race_word' -> `stub_word's_`yr'"
            preserve
                keep if total_indicator == "Derived - Subtotal by Race/Ethnicity and Sex minus Adult Education Count" & race_ethnicity == "`race_word'"
                keep ncessch student_count
                collapse (sum) student_count, by(ncessch)
                rename student_count `stub_word's_`yr' // Total number of students of a race/ethnicity category
                tempfile sch_membership_`stub_word's_`yr'
                save "`sch_membership_`stub_word's_`yr''", replace
                use "${processed_data}/sch`yr'", clear
                merge 1:1 ncessch using "`sch_membership_`stub_word's_`yr''"
                assert _merge != 2
                drop _merge
                compress
                save "${processed_data}/sch`yr'", replace
            restore
            
            local i = `i' + 1
        }
}