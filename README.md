# StormRunner Load Chat Bot

The StormRunner Load Chat bot was built on the hubot framework, then updated to hubot-enterprise. The steps below are to install and configure the StormRunner Load bot, which will interact using Slack.

This README is intended to help get you started. Definitely update and improve to talk about your own instance, how to use and deploy, what functionality is available, etc!

## Installing hubot-enterprise

1. Install node.js and npm [here](https://nodejs.org/en/download/package-manager/)

2. Install coffeeScript and hubot-enterprise:

   `sudo npm install -g coffee-script yo eedevops/generator-hubot-enterprise hubot-config-generator hubot-runner`

3. Create a new directory (do **NOT** name it **hubot** and do not user **hubot-** prefix)

4. In the new directory, run the hubot-enterprise generator (do not run as ROOT user):

   `yo hubot-enterprise`

   (NOTE: in case of `EACCES: permission denied` run: `npm cache clean` and the run the above command again)

5. Follow the setup wizard

   (NOTE: when asked for Bot Integrations, leave it blank)

6. Run the following command:

    `hcg --add https://github.com/HPSoftware/hubot-srl`

   (Note: This will add hubot-srl script to your current hubot instance dependencies)

7. Fill in the following environment variables:
    ```
    HUBOT_HELP_REPLY_IN_PRIVATE (Default none)
    HUBOT_SLACK_TOKEN (enter the Slack token for the bot)
    HTTPS_PROXY (Proxy used for hubot: Default none)
    SRL_SAAS_PREFIX (StormRunner API URL: https://stormrunner-load.saas.microfocus.com/v1)
    SRL_USERNAME (Username to log into StormRunner Load)
    SRL_PASSWORD (Password to log into StormRunner Load)
    SRL_TENANT_ID (The Tenant ID to your StormRunner Load Tenant)
    ```

8. Run the following command:

   `hr`

   (Note: This will launch the hubot instance and keep the hubot process alive. In case of failure, the process will automatically restart)

Now the StormRunner Load integration is integrated with your Slack instance

## Sample Interaction
```
user1>> srl list projects
```

## Help
You can use the Hubot Enterprise help commands by typing:

```
@yourbot help srl list
@yourbot help srl get
@yourbot help srl set
@yourbot help srl run
```

## Available commands

##### Lists all projects in the supplied tenant:
    srl list projects

##### Sets the project to Project Name or ID
    srl set project to Default Project or 123

##### Lists all the tests for previously set project name or ID
    srl list tests

##### Displays the latest run information for supplied test ID
    srl get latest run for test 1234

##### Displays run information for up to 10 runs for supplied test ID in set project
    srl get runs for test 1234

##### Displays the run information for x number of runs for supplied test ID in set project
    srl get status for last 6 runs for test 1234

##### Displays results information for supplied run ID
    srl get results for run 2314

##### Executes supplied test ID in respective project
    srl run test 1234
