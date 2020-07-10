function Get-Report {
    # This function should beinvoked after the Test-DataFactory function is completed. This is a dumb function that just traverses through the results
    # and spits out a string. To capture the result into a file, the output of this function can be redirected to a file stream

    [System.Collections.ArrayList]$successfulPipelines = [System.Collections.ArrayList]@()
    [System.Collections.ArrayList]$failedPipelines = [System.Collections.ArrayList]@()

    #cycle through each results to find failed results. This is poor code - need to think of a cooler way ......
    foreach ($result in $pipelineTestResults) {
        if($result.Status -eq "Succeeded") { 
            $succesful = $successfulPipelines.Add($result) 
        }
        else {
            $failed = $failedPipelines.Add($result)
		}
    }

    Write-Output "****************  Execution Results *************************"
    Write-Output "Current Run Executed on: $executionRun"
    Write-Output "Total pipelines tested $($pipelineTestResults.Count)"
    Write-Output "Total pipelines Failed $($failedPipelines.Count)"
    Write-Output ""
    Write-Output "Following Pipelines Executed Successfully"
    Write-Output "-----------------------------------------"

    foreach($result in $successfulPipelines) {
        Write-Output "DataFactoryName: $($result.DataFactoryName), PipelineName: $($result.PipelineName), Pipeline ExecutionTime(ms): $($result.DurationInMs)"
    }

    Write-Output ""
    Write-Output "Following Pipelines Experienced Execution Failures"
    Write-Output "---------------------------------------------------------"
    foreach($result in $failedPipelines) {
        Write-Output "DataFactoryName: $($result.DataFactoryName), PipelineName: $($result.PipelineName), Pipeline ExecutionTime(ms): $($result.DurationInMs)"
        Write-Output "Error $($result.Message)"
        Write-Output ""
    }
    Write-Output ""
    Write-Output "****************  End of Execution Results *************************"

    if ($failedPipelines.Count -gt 0 ) { Write-Host "There were Failures - review the log file" } 
}



function Test-DataFactory
{
    [cmdletbinding()]

    param (
            [string] $config
          )

    process {
    
        # for production use uncomment the below and replace with Managed Service Identity call 
       # $credential = Get-Credential
        # Connect-AzAccount -Credential $credential

        # Get the Azure datafactories in the resource group
        $datafactories = Get-Content $config | Out-String | ConvertFrom-Json

        # Here we loop through the datafactories, invoke pipelines and store the run results into an array for report construction
        foreach ($datafactory in $datafactories) {

            $datafactoryName = $dataFactory.DAName
            $resourceGroupName = $datafactory.ResourceGroup

	        $pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryName

            foreach ($pipeline in $pipelines) {
                Write-Host "Testing DataFactory $($datafactoryName) - Invoking Pipeline : $($pipeline.Name) "
        
                $pipelineRunID = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryName -PipelineName $pipeline.Name

                # loop through until the result is not In Progress. This may result in the script taking too long to execute. Alternatively, we can 
                # terminate the loop after certain time threshold has been reached
                do {
                    Start-Sleep -s 5  # delay for a few seconds before checking again
                    $result = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $datafactoryName -PipelineRunId $pipelineRunID 
		        } until ($result.Status -ne "InProgress")

                $total = $pipelineTestResults.Add($result)       
            }
        }   
    }
}


# This is where it all begins :-) !!
Clear-Host
$executionRun = Get-Date
[System.Collections.ArrayList]$pipelineTestResults = [System.Collections.ArrayList]@()
Test-DataFactory -config DatafactorytoTest.json
 #need to find a better way to add carriage return :-(
Write-Host "Writing Report"
Get-Report
Write-Host "Finished testing......"