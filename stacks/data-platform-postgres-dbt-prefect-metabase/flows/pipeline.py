"""Prefect flow that builds the dbt project. `flow.serve` registers the deployment `dbt-hourly`
(hourly schedule, also runnable on demand from the UI or the API) and executes its runs in this process."""
import os
import subprocess

from prefect import flow, task

DBT = os.environ.get("DBT_BIN", "dbt")
ARGS = ["--project-dir", "/dbt", "--profiles-dir", "/dbt"]


@task(retries=2, retry_delay_seconds=10)
def dbt(command: str) -> None:
    subprocess.run([DBT, command, *ARGS], check=True)


@flow(name="dbt-pipeline", log_prints=True)
def dbt_pipeline() -> None:
    dbt("seed")   # load the CSV seeds
    dbt("run")    # build staging views and mart tables
    dbt("test")   # not_null / unique tests
    print("dbt pipeline finished")


if __name__ == "__main__":
    dbt_pipeline.serve(name="dbt-hourly", cron="0 * * * *")
