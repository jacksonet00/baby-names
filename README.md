# Baby Names Analysis

- To clean data and store in database run:
   ```
   julia prepare.jl <ZIP_ARCHIVE> <DB_NAME>
   ```

- To plot data for a particular name and sex
   ```
   julia plot.jl <DB_NAME> <NAME> <SEX></SEX>
   ```

- To find the most similar trending male and female names over time
   ```
   julia similar.jl <DB_NAME>
   ```