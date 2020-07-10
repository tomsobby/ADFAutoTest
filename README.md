# ADFAutoTest
This is a first cut for automated testing of Azure Data Factory pipelines using the poqwershell AZ modules. Ensure the Az modules are installed prior to running the powershell. Rm modules are legacy and replaced with Az.

Features to add
=========================================
1. Add pipeline exclusion
2. Passing parameters to Pipelines
3. Connect to Azure using Managed Service Identity


Usage
======================
1. run the script from the powershell commandline
   e.g. c:\PS> ADFTest.ps1
   all execution and report will be printed to the console
  
2. redirect Report to a log file
   e.g. c:\PS> .\ADFTest.ps1 | Out-File .\Report.log
  
Config File
========================
Ensure the json file is in the same directory as the ps1 file. 
  
