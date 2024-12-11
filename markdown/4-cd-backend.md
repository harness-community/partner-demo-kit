
<style type="text/css" rel="stylesheet">
hr.cyan { background-color: cyan; color: cyan; height: 2px; margin-bottom: -10px; }
h2.cyan { color: cyan; }
</style><h2 class="cyan">Continuous Deployment - Backend</h2>
<hr class="cyan">
<br><br>

## Now let's deploy the backend artifact
### Go back to the `Pipeline Studio` and add a `Deployment` stage

Click `+Add Stage` <br>

> Choose **Deploy** stage type <br>
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_stage_deploy.png)

> **Deploy Stage**
> - Stage Name: <pre>`Backend - Deployment`</pre>
> - Deployment Type: `Kubernetes`
> Click **Set Up Stage**

<br>

> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_tab_service.png)
> ### On the  **Service** tab
> - Click `Select Service`
> - Select: `backend` (this has been preconfigured for us)
> - Click **Continue >**

<br>

> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_tab_environment.png)
> ### On the  **Environment** tab
> - Click `Propagate Environment From`
> - Select: `Stage [Frontend - Deployment]`
> - Click **Continue >**

<br>

> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_tab_execution.png)
> ### On the  **Execution** tab
> - Select: `Canary` \
>     ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/deploy_canary.png)
> - Click **Use Strategy**

### Execute your Pipeline
> Click **Save** in the top right to save your pipeline. <br>
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_save.png)

> Now click **Run** to execute the pipeline. <br>
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_run.png)

> The build should run using: <br>
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/unscripted-workshop-2024/assets/images/unscripted_lab4_execution.png)
> - Branch Name: `main`
> - Stage: **Frontend - Deployment**
>   - Primary Artifact: `frontend`
> - Stage: **Backend - Deployment**
>   - Primary Artifact: `backend`

===============

Click the **Check** button to continue.
