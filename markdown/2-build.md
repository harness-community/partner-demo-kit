
<style type="text/css" rel="stylesheet">
hr.cyan { background-color: cyan; color: cyan; height: 2px; margin-bottom: -10px; }
h2.cyan { color: cyan; }
</style><h2 class="cyan">Setup a CI Pipeline</h2>
<hr class="cyan">
<br><br>

## Let's create a pipeline
![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/module_unified.png)

Select **Unified View** from the list <br>

> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/nav_pipelines.png)
> ### Click on **Pipelines** in the left Nav
> - Click `+Create Pipeline` \
>     ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_create.png)

> **Create new Pipeline**
> - Name: <pre>`Workshop Build and Deploy`</pre>
> - Store: `Inline`

> [!NOTE]
> Inline vs. Remote - We're using inline for this lab, but you can also use a remote repository like GitHub. This is useful for teams that want to keep their _pipelines as code_ bundled up snuggly with _application code_. Cozy!

Click `+Add Stage` <br>

> Choose **Build** stage type <br>
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_stage_build.png)

> **Build Stage**
> - Stage Name: <pre>`Build`</pre>
> - Clone Codebase: `Enabled`
> - Repository Name: `harnessrepo`
> - Click **Set Up Stage**

<br>

> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_tab_infrastructure.png)
> ### On the  **Infrastructure** tab
> - Select `Cloud` and click **Continue >**

> [!NOTE]
> ***Harness Cloud is the BESTEST cloud*** <br>
> Something awesome happened right there. With zero configuration (well ok... ooooooone click!) you instantly configured an autoscaling build environment in the cloud that requires no management on your part and is dramatically less expensive than on-premise.

Plus Harness is using the [fastest bare-metal hardware](https://www.harness.io/products/continuous-integration/ci-cloud) in the Solar System. Seriously. Astronauts checked.
<br>

> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_tab_execution.png)
> ### On the  **Execution** tab
> - Select `Add Step`, then `Add Step` again \
>     ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/unscripted-workshop-2024/assets/images/unscripted_pipeline_build_test_intelligence.png)
> - Select `Test Intelligence` from the Step Library and configure with the details below ↓


> **Test Intelligence**
> - Name: <pre>`Test Intelligence`</pre>
> - Command:
>  ```
>  cd ./python-tests
>  pytest
>  ```
> - After completing configuration select **Apply Changes** from the top right of the configuration popup

> [!NOTE]
> ***What is Test Intelligence?*** <br>
> Test Intelligence helps accelerate test cycles by up to 80%. By running only relevant tests, you can achieve faster builds, shorter feedback loops, and significant cost savings.

> ### Add a step to compile our application
> - Select `Add Step`,  then `Use template`
>   - To standardize our build, a template has been precreated
>     - Feel free to open up the template if you'd like to see what it's doing
> - Select the `Compile Application` template and click `Use template`
> - Name: <pre>`Compile`</pre>
> - Click **Apply Changes** from the top right of the configuration popup

> ### Add a step to build and push our artifact
> - Select `Add Step`, then `Add Step` again \
>     ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/unscripted-workshop-2024/assets/images/unscripted_pipeline_build_dockerhub.png)
> - Select `Build and Push an image to Dockerhub` from the Step Library and configure with the details below ↓

> **Build and Push an image to Dockerhub**
> - Name: <pre>`Push to Dockerhub`</pre>
> - Docker Connector: `workshop-docker`
> - Docker Repository: <pre>`dockerhubaccountid/harness-demo`</pre>
> - Tags: Click `+ Add`
> - <pre><code>demo-base-<+pipeline.sequenceId></code></pre>
> - **Optional Configuration  ⏷** *(Required for this Lab)*
>   - Dockerfile: <pre>`/harness/frontend-app/harness-webapp/Dockerfile`</pre>
>   - Context: <pre>`/harness/frontend-app/harness-webapp`</pre>
> - After completing configuration select **Apply Changes** from the top right of the configuration popup

### Execute your new Pipeline
> Click **Save** in the top right to save your new pipeline. <br>
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_save.png)

> Now click **Run** to execute the pipeline. <br>
> ![](https://raw.githubusercontent.com/harness-community/field-workshops/main/assets/images/pipeline_run.png)

> [!NOTE]
> You might have noticed an option to pick the branch before running the pipeline. We're using `main` for simplicity, but it's a great example of how this complete build pipeline could easily be reused for other branches (or repositories or services).

![](https://raw.githubusercontent.com/harness-community/field-workshops/main/unscripted-workshop-2024/assets/images/unscripted_lab2_execution.png)

===============

Click the **Check** button to continue.
