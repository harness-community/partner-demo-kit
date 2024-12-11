
<style type="text/css" rel="stylesheet">
hr.cyan { background-color: cyan; color: cyan; height: 2px; margin-bottom: -10px; }
h2.cyan { color: cyan; }
</style><h2 class="cyan">Continuous Verification</h2>
<hr class="cyan">
<br><br>

## Now let's add Continuous Verification
### Go back to the `Pipeline Studio`
1) In the existing pipeline, within the ***Backend - Deployment*** stage `after` the ***Canary Deployment*** step click on the `+` icon to add a new step \
   ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/unscripted-workshop-2024/assets/images/unscripted_pipeline_deploy_canary_add_step.png)<br>
2) Select `Add Step` \
   ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_step_verify.png)
3) Select `Verify` from the Step Library and configure with the details below ↓

> **Verify**
> - Name: <pre>`Verify`</pre>
> - Continuous Verification Type: `Canary`
> - Sensitivity: `Low`
> - Duration: `5mins`
> - Click **Apply Changes** from the top right of the configuration popup

> [!NOTE]
> ***Continuous Verification Sensitivity*** <br>
> This is to define how sensitive the ML algorithms are going to be on deviation from the baseline.

### Execute your Pipeline
> Click **Save** in the top right to save your pipeline. <br>
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_save.png)

> Now click **Run** to execute the pipeline. <br>
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_run.png)

> # Switch to the ```Demo App``` tab to continue

### While the canary deployment is ongoing see if you can spot the canary!
- Click the `Check Release` button
- (Don't worry! Keep on clicking it!) \
    ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/unscripted-workshop-2024/assets/images/unscripted_captain_canary.png)

### Distribution Test
- Now click on the `Start` button on the **Distribution Test** panel
- Then click the **Play** `▶️` button to start the test and observe the traffic distribution \
    ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/unscripted-workshop-2024/assets/images/unscripted_traffic_distribution_test.png)

> # Switch to the ```Harness Platform``` tab to continue

### Validate the outcome of the verification on the pipeline execution details
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/unscripted-workshop-2024/assets/images/unscripted_cv_verification.png)
> 1) Toggle `Console View`
> 2) Select the `Verify` step
> 3) Uncheck the option to `Display only anomalous metrics and affected nodes`
> 4) Click the `⏷` to view the details

## This is just the beginning.
`Harness Continuous Verification` integrates with APMs and logging tools to verify that the deployment is running safely and efficiently. Harness CV applies **machine learning** algorithms to every deployment for identifying normal behavior. This allows Harness to identify and flag anomalies in future deployments. During the Verify step, Harness CV `automatically` triggers a **rollback** if anomalies are found.

===============

Click the **Check** button to continue.
