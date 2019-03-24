###

File Name:          stormrunner-bot-logic.coffee

Written in:         Coffee Script

Description:        This file contains the routines that 'listen' for the user to type
                    various commands.  Each of the available commands are listed below
                    and once the robot 'hears' the command, it processes the code contained
                    within the rountine.  For example, if a user asks the bot to  'list projects'
                    the code under the routine robot.respond /list projects/i, (msg) is processed.

                    Upon completion of the rountine, the robot returns to 'listen' mode.

Author(s):          Cyrus Manouchehrian (Inital Version)
                    Will Zuill

Copyright information:

Copyright 2016 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
Software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
###

# Configuration:
# HUBOT_SLACK_TOKEN "" Slack token for hubot
# https_proxy "" Proxy used for hubot
# SRL_SAAS_PREFIX "https://stormrunner-load.saas.hpe.com/v1" SaaS Rest API URL
# SRL_USERNAME "" Username to StormRunner Load
# SRL_PASSWORD "" Password to StormRunner Load
# SRL_TENANT_ID "" Tenant ID to StormRunner Load
#


# Set the file dependancies

Helpers         = require './helpers'
StormrunnerApi  = require "./libs/stormrunnerApiAdapter.js"
mockData        = require "./mockData"
util            = require('util')

module.exports = (robot) ->
  Helpers.setRobot(robot)

  robot.e.registerIntegration({short_desc: 'StormRunner Load hubot chatops integration', name: 'srl'})
################################################################################
# Name:         list projects
#
# Description:  Gets the current list of SRL projects detailed in the local
#               hubot local web server.  The local web server is populated in the
#               'get projects' section of the file srl-openaspi-proxy.coffee
#
# Called From:  (Direct from Chat client by typing the command 'list projects')
#
# Calls to:     'get projects' section (srl-openapi-proxy.coffee)
#               setSharingRoom (helpers.coffee)
#               sendCustomMessage (helpers.coffee)
#               getTentantId (stormrunnerApiAdapter.js)
#
# Author(s):    Will Zuill (inital Version)
#               Cyrus Manouchehrian
################################################################################

  # Add command to hubot help
  #robot.commands.push "hubot list projects - Lists all the projects in the supplied tenant."

  # listen for the response....

  #robot.respond /list projects/i, (msg) ->
  robot.e.create {verb:'list',entity:'projects',help: 'Lists all projects in supplied tenant',type:'respond'},(msg)->
    Helpers.setSharingRoom(robot,msg)

    # Get the list of projects from the local Hubot web server.  This will cause
    # the 'get projects' section to fire in the file srl-openapi-proxy.coffee
    # should the list of projects need to be populated or updated.

    robot.http("http://localhost:8080/hubot/stormrunner/proxy/getProjects")
      .get() (err, res, body) ->
        if err or res.statusCode!=200
            # If we cannot find any projects, display the error code and drop.
            msg.reply 'Sorry, there was an error retrieving the projects'
            msg.reply 'Status Code: ' + res.statusCode
            return

        robot.logger.debug "Res returned : \n" + body
        # Format the returned list of projects as a JSON string
        prjs = JSON.parse body

        # Initialize all variables

        attachments = []

        strPrjID   = ""
        strPrjName = ""

        # Loop through returned list of projects
        for index,value of prjs
            #console.log "Getting project for : #{value.id}"
            # Append each project ID and Name to a two single string seperated
            # by a carriage return (\n)

            strPrjID   = strPrjID + value.id + "\n"
            strPrjName = strPrjName + value.name + "\n"
        # End of Loop

        # Format the list of projects (id and name) as a SLACK attachment
        fields =
            color : "#0000FF"       # Add a Blue line
            fields : [
              {
                title: "Project ID"
                value: strPrjID
                short: true
              },
              {
                title: "Project Name"
                value: strPrjName
                short: true
              }
            ]

        attachments.push(fields)

        #console.log("room="+msg.message.room)
        # Construct a SLACK message to send to the appropriate chat room.
        msgData = {
          channel: msg.message.room
          text: "Projects for tenant #{StormrunnerApi.getTenantId()}"
          attachments: attachments
        }

        # Send the built message to the chat client/room.

        Helpers.sendCustomMessage(robot,msgData)

############################################################################
# Name:         list tests for project X
#
# Description:  Gets a list of all the tests for the passed in SRL project name or
#               project ID from the hubot local web server.  The local web server
#               is populated in the 'get Tests' section of the
#               file srl-openaspi-proxy.coffee
#
# Called From:  (Direct from Chat client by typing the command 'list tests for
#               project X')
#
# Calls to:     'get Tests' section (srl-openapi-proxy.coffee)
#               setSharingRoom (helpers.coffee)
#               fmtDate (stormrunnerApiAdapter.js)
#               sendCustomMessage (helpers.coffee)
#               getTentantId (stormrunnerApiAdapter.js)
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################

  # Add command to hubot help
  #robot.commands.push "hubot list tests - Lists all the tests for previously set project name or ID."
  #robot.respond /list tests/i, (msg) ->
  robot.e.create {verb:'list',entity:'tests',help: 'Lists all tests for previously set project name or ID',type:'respond'},(msg)->
    Helpers.setSharingRoom(robot,msg)

    # Extract the first variable part of the message (i.e. the project Name or
    # Project ID)
    intProject = Helpers.myProject(robot)       # Could be a Project Name or ID
    strProject = Helpers.findProjName(robot,intProject)

    robot.logger.debug "Showing tests for project #{intProject}"

    robot.http("http://localhost:8080/hubot/stormrunner/proxy/getTests?project=#{intProject}")
    .get() (err, res, body) ->
            # If we cannot find any tests, display the error code and drop.

            if err or res.statusCode!=200
                msg.reply 'Sorry, there was an error retrieving the tests'
                msg.reply 'Status Code: ' + res.statusCode
                return

            robot.logger.debug "Res returned : \n" + body

            tests = JSON.parse body
            # Initalize all variables

            attachments     = []
            strTestID       = ""
            strTestNameDate = ""
            strTestDate     = ""
            strTestName     = ""
            intDate         = 0
            objDate         = []

            # if we have more than 10 runs
            if tests.length > 20
                # Display a message and remove all results after the 10th array element
                strMessage = "There are a total of #{tests.length} tests in #{strProject}. We are displaying 20."
                tests.splice(20,tests.length-20)
            else
                strMessage = "Here are all the tests in project #{strProject}"

            # Loop through returned list of tests

            for index,value of tests
                #console.log "Getting tests for : #{value.id}"
                # Append each Test ID to a single string seperated
                # by a carriage return (\n)

                strTestID       = strTestID + value.id + "\n"
                strTestName     = strTestName + value.name + "\n"

                # As the date returned is in 'ticks' we need to format it
                # Therefore, Convert the returned string 'tick' date into a number
                # and then a date object.

                intDate = Number(value.createDate)
                objDate = new Date(intDate)

                # Now we have the returned date in the right format - call a function
                # to format the date into yyyy-mm-dd (tough luck USA!)

                strTestDate = StormrunnerApi.fmtDate(objDate)

                # As the 'attachment' formatting only has two columns and we want to
                # display three (ID, Name and Creation Date) we need to format name
                # and creation date into a single string.  Therefore format it as:
                # Test Name <TAB> (Test Creation Date)
                strTestNameDate = strTestNameDate + value.name + "\t(" + strTestDate + ")" + "\n"
            # End of Loop

            # Format the list of tests (id and name/creation date) as a SLACK attachment

            fields =
            color : "#0000FF"       # Add a Blue line
            #footer: "----------------------------------------------------------------------------------------"
            fields : [
                {
                title: "Test ID"
                value: strTestID
                short: true
                },
                {
                title: "Test Name"
                value: strTestName
                short: true
                }
            ]

            attachments.push(fields)
            # Send the built message to the chat client/room.

            msgData = {
                channel: msg.message.room
                text: strMessage
                attachments: attachments
                      }

            Helpers.sendCustomMessage(robot,msgData)
############################################################################
# Name:         show latest run for test X in project Y
#
# Description:  shows test details for the latest run of a test (the test ID is
#               passed in) in a passed in project from the hubot local web server.
#               The local web server is populated in the 'get Runs' section of the
#               file srl-openaspi-proxy.coffee
#
# Called From:  (Direct from Chat client by typing the command 'show latest run
#               for test X in Project Y')
#
# Calls to:     'get runs' section (srl-openapi-proxy.coffee)
#               setSharingRoom (helpers.coffee)
#               fmtDate (stormrunnerApiAdapter.js)
#               fmtDuration (stormrunnerApiAdapter.js)
#               sendCustomMessage (helpers.coffee)
#               getTentantId (stormrunnerApiAdapter.js)
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  # Add command to hubot help
  #robot.commands.push "hubot show latest run for test <test id> - Displays the latest run information for supplied test ID."
  #robot.respond /show latest run for test (.*)/i, (msg) ->
  robot.e.create {verb:'get',entity:'latest',
  regex_suffix:{re: "run for test (.*)", optional: false},
  help: 'Displays the latest run information for supplied test ID',type:'respond',
  example: 'run for test 1234'},(msg)->
    Helpers.setSharingRoom(robot,msg)

    # Extract the two variables part of the message (i.e. first the Test ID and then the project Name or
    # Project ID)

    strTestId  = msg.match[1]
    intProject = Helpers.myProject(robot)       # Could be a Project Name or ID
    strProject = Helpers.findProjName(robot,intProject)

    robot.logger.debug "Showing latest run for test #{strTestId} in Project #{strProject}"

    robot.http("http://localhost:8080/hubot/stormrunner/proxy/getRuns?project=#{intProject}&TestID=#{strTestId}")
    .get() (err, res, body) ->

        # If we cannot find any tests, display the error code and drop.
        if err or res.statusCode!=200
          msg.reply 'Sorry, there was an error retrieving the run for this test'
          msg.reply 'Status Code: ' + res.statusCode
          return

        robot.logger.debug "Res returned : \n" + body

        run = JSON.parse(body)

        # Initialize all variables

        attachments     = []
        strTestName     = ""
        strStartDate    = ""
        strDuration     = ""
        intDate         = 0
        intDuration     = 0
        objDate         = []

        # Set the test name

        strTestName = run[0].testName
        strColor = Helpers.getColor(robot,run[0].status)
        # As the date returned is in 'ticks' we need to format it
        # Therefore, Convert the returned string 'tick' date @SRL I’m working on Will Zuill’s Projectinto a number
        # and then a date object.

        intDate = Number(run[0].startOn)
        objDate = new Date(intDate)

        # Now we have the returned date in the right format - call a function
        # to format the date into yyyy-mm-dd (tough luck USA!)

        strStartDate = StormrunnerApi.fmtDate(objDate)

        # The duration is stored in Microseconds.  Thus, convert the returned
        # string to an integer and call the function to format the duration
        # into HH:MM:SS

        intDuration = Number(run[0].duration)
        strDuration = StormrunnerApi.fmtDuration(intDuration)

        # Format the returned parameters as a SLACK attachment

        fields =
          color: strColor
          fields : [
            {
              title: "Run ID"
              value: run[0].id
              short: true
            },
            {
              title: "Status"
              value: run[0].status
              short: true
            },
            {
              title: "Start Date"
              value: strStartDate
              short: true
            },
            {
              title: "Duration"
              value: strDuration
              short: true
            },
            {
              title: "Virtual Users Used"
              value: run[0].vusersNum
              short: true
            }
            ]

        attachments.push(fields)

        # Send the built message to the chat client/room.

        msgData = {
          channel: msg.message.room
          text: "Latest run result for test #{strTestName} in project #{strProject}"
          attachments: attachments
        }

        Helpers.sendCustomMessage(robot,msgData)
############################################################################
# Name:         show runs for test X in project Y
#
# Description:  Shows run details for the a test (the test ID is passed in)
#               in a passed in project from the hubot local web server.
#               The local web server is populated in the 'get Runs' section of the
#               file srl-openaspi-proxy.coffee
#
# Called From:  (Direct from Chat client by typing the command 'show runs
#               for test X in Project Y')
#
# Calls to:     'get runs' section (srl-openapi-proxy.coffee)
#               setSharingRoom (helpers.coffee)
#               fmtDate (stormrunnerApiAdapter.js)
#               fmtDuration (stormrunnerApiAdapter.js)
#               sendCustomMessage (helpers.coffee)
#               getTentantId (stormrunnerApiAdapter.js)
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  # Add command to hubot help
  #robot.commands.push "hubot show runs for test <test id> - Displays run information up to 10 runs for supplied test ID in project Name/ID."

  #robot.respond /show runs for test (.*)/i, (msg) ->
  robot.e.create {verb:'get',entity:'runs',
  regex_suffix:{re: "for test (.*)", optional: false},
  help: 'Displays run information for up to 10 runs for supplied test ID in project name/ID',type:'respond',
  example: 'for test 123'},(msg)->

    Helpers.setSharingRoom(robot,msg)

    # Extract the two variables part of the message (i.e. first the Test ID and then the project Name or
    # Project ID)

    strTestId   = msg.match[1]
    intProject = Helpers.myProject(robot)       # Could be a Project Name or ID
    strProject = Helpers.findProjName(robot,intProject)
    robot.logger.debug "Showing runs for test #{strTestId} in Project #{strProject}"

    robot.http("http://localhost:8080/hubot/stormrunner/proxy/getRuns?project=#{intProject}&TestID=#{strTestId}")
    .get() (err, res, body) ->

        # If we cannot find any tests, display the error code and drop.
        if err or res.statusCode!=200
          msg.reply 'Sorry, there was an error retrieving the runs for the test'
          msg.reply 'Status Code: ' + res.statusCode
          return

        robot.logger.debug "Res returned : \n" + body

        runs = JSON.parse(body)

        # Initialize all variables

        attachments     = []
        strTestName     = ""
        strMessage      = ""
        strStartDate    = ""
        strDuration     = ""
        strTestName     = ""
        intDate         = 0
        intDuration     = 0
        objDate         = []
        strTestName     = runs[0].testName

        # if we have more than 10 runs
        if runs.length > 10
            # Display a message and remove all results after the 10th array element
            strMessage = "There are a total of #{runs.length} for test #{strTestName} in project #{strProject}.  Only displaying last 10."
            runs.splice(10,runs.length-10)
        else
            strMessage = "The last #{runs.length} run results for test #{strTestName} in project #{strProject}"

        # for each of the runs

        for index,value of runs
            # As the date returned is in 'ticks' we need to format it
            # Therefore, Convert the returned string 'tick' date into a number
            # and then a date object.

            intDate = Number(value.startOn)
            objDate = new Date(intDate)

            # Now we have the returned date in the right format - call a function
            # to format the date into yyyy-mm-dd (tough luck USA!)

            strStartDate = StormrunnerApi.fmtDate(objDate)

            # The duration is stored in Microseconds.  Thus, convert the returned
            # string to an integer and call the function to format the duration
            # into HH:MM:SS

            intDuration = Number(value.duration)
            strDuration = StormrunnerApi.fmtDuration(intDuration)
            strColor = Helpers.getColor(robot,value.status)

            # Format the returned parameters as a SLACK attachment

            fields =
              color : strColor
              footer: "----------------------------------------------------------------------------------------"
              fields : [
                {
                  title: "Run ID"
                  value: value.id
                  short: true
                },
                {
                  title: "Status"
                  value: value.status
                  short: true
                },
                {
                  title: "Start Date"
                  value: strStartDate
                  short: true
                },
                {
                  title: "Duration"
                  value: strDuration
                  short: true
                },
                {
                  title: "Virtual Users Used"
                  value: value.vusersNum
                  short: true
                }
                ]

            attachments.push(fields)

        # Send the built message to the chat client/room.

        msgData = {
          channel: msg.message.room
          text: strMessage
          attachments: attachments
        }

        Helpers.sendCustomMessage(robot,msgData)
############################################################################
# Name:         list status for last X runs for test Y in project Z
#
# Description:  Shows X (num of runs is passed in) number run details for the a
#               test (the test ID is passed in) in a passed in project from the
#               hubot local web server.
#               The local web server is populated in the 'get Runs' section of the
#               file srl-openaspi-proxy.coffee
#
# Called From:  (Direct from Chat client by typing the command 'show runs
#               for test X in Project Y')
#
# Calls to:     'get runs' section (srl-openapi-proxy.coffee)
#               setSharingRoom (helpers.coffee)
#               fmtDate (stormrunnerApiAdapter.js)
#               fmtDuration (stormrunnerApiAdapter.js)
#               sendCustomMessage (helpers.coffee)
#               getTentantId (stormrunnerApiAdapter.js)
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  # Add command to hubot help
  #robot.commands.push "hubot list status for last <num of runs> runs for test <test id> - Displays the run information for X number of runs for supplied test ID in project Name/ID."
  #robot.respond /list status for last (.*) runs for test (.*)/i, (msg) ->
  robot.e.create {verb:'get',entity:'status',
  regex_suffix:{re: "for last (.*) runs for test (.*)", optional: false},
  help: 'Displays the run information for X number of runs for supplied test ID in project Name/ID',type:'respond',
  example: 'for last 5 runs for test 123'},(msg)->
    Helpers.setSharingRoom(robot,msg)

    # Extract the three variables part of the message (i.e. first the number of runs, followed by
    # the Test ID and then the project Name or Project ID)

    strRunCnt  = msg.match[1]
    strTestId  = msg.match[2]
    intProject = Helpers.myProject(robot)       # Could be a Project Name or ID
    strProject = Helpers.findProjName(robot,intProject)

    robot.logger.debug "Showing runs for test #{strTestId} in Project #{strProject}"

    robot.http("http://localhost:8080/hubot/stormrunner/proxy/getRuns?project=#{intProject}&TestID=#{strTestId}")
    .get() (err, res, body) ->

        # If we cannot find any runs for the test, display the error code and drop.

        if err or res.statusCode!=200
          msg.reply 'Sorry, there was an error retrieving the runs for the test'
          msg.reply 'Status Code: ' + res.statusCode
          return

        robot.logger.debug "Res returned : \n" + body

        runs = JSON.parse(body)

        # Initialize all variables

        attachments     = []
        strTestName     = ""
        strMessage      = ""
        strStartDate    = ""
        strDuration     = ""
        strHrs          = ""
        strMins         = ""
        strSecs         = ""
        intDate         = 0
        intDuration     = 0
        objDate         = []
        strColor        = ""

        strTestName = runs[0].testName

        # if the number of runs is less than the asked for runs
        if runs.length < Number(strRunCnt)
            # Display a message saying we can only display X runs
            strMessage = "There are only #{runs.length} runs for test #{strTestName} in project #{strProject}."
        else
            # if the total number of runs is greater than then number of runs asked for, then trim the
            # array to limit it to the passed in number

            if runs.length > Number(strRunCnt)
                runs.splice(Number(strRunCnt),runs.length-Number(strRunCnt))

            strMessage = "The last #{runs.length} run results for test #{strTestName} in project #{strProject}"

        # for each of the runs

        for index,value of runs
            # As the date returned is in 'ticks' we need to format it
            # Therefore, Convert the returned string 'tick' date into a number
            # and then a date object.

            intDate = Number(value.startOn)
            objDate = new Date(intDate)

            # We need need to get the time, therefore extract the hours, mins and seconds
            # and convert them to a string

            strHrs  = objDate.getHours().toString()
            strMins = objDate.getMinutes().toString()
            strSecs = objDate.getSeconds().toString()

            # Now we have the returned date in the right format - call a function
            # to format the date into yyyy-mm-dd (tough luck USA!)

            strStartDate = StormrunnerApi.fmtDate(objDate) + " " + strHrs.lpad("0",2) + ":" + strMins.lpad("0",2) + ":" + strSecs.lpad("0",2)

            # The duration is stored in Microseconds.  Thus, convert the returned
            # string to an integer and call the function to format the duration
            # into HH:MM:SS

            intDuration = Number(value.duration)
            strDuration = StormrunnerApi.fmtDuration(intDuration)
            strColor = Helpers.getColor(robot,value.status)

            # Format the returned parameters as a SLACK attachment

            fields =
              color : strColor
              footer: "----------------------------------------------------------------------------------------"
              fields : [
                {
                  title: "Run ID"
                  value: value.id
                  short: true
                },
                {
                  title: "Status"
                  value: value.status
                  short: true
                },
                {
                  title: "Start Date"
                  value: strStartDate
                  short: true
                },
                {
                  title: "Duration"
                  value: strDuration
                  short: true
                },
                {
                  title: "Virtual Users Used"
                  value: value.vusersNum
                  short: true
                }
                ]

            attachments.push(fields)

        # Send the built message to the chat client/room.

        msgData = {
          channel: msg.message.room
          text: strMessage
          attachments: attachments
        }

        Helpers.sendCustomMessage(robot,msgData)
############################################################################
# Name:         show full results for run id X
#
# Description:  Shows all the results for a run run ID is passed in) from the
#               hubot local web server.
#               The local web server is populated in the 'get Runs' section of the
#               file srl-openaspi-proxy.coffee
#
# Called From:  (Direct from Chat client by typing the command 'show full
#               results for run id X')
#
# Calls to:     'get Run Results' section (srl-openapi-proxy.coffee)
#               setSharingRoom (helpers.coffee)
#               fmtDate (stormrunnerApiAdapter.js)
#               fmtDuration (stormrunnerApiAdapter.js)
#               sendCustomMessage (helpers.coffee)
#               getTentantId (stormrunnerApiAdapter.js)
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  # Add command to hubot help
  #robot.commands.push "hubot show results for run id <Run id> - Displays results information for supplied run ID."

  #robot.respond /show results for run id (.*)/i, (msg) ->
  robot.e.create {verb:'get',entity:'results',
  regex_suffix:{re: "for run (.*)", optional: false},
  help: 'Displays results information for supplied run ID',type:'respond',
  example: 'for run 123'},(msg)->
    Helpers.setSharingRoom(robot,msg)

    # Extract the variable part of the message (i.e. the run id)

    strRunid = msg.match[1]

    robot.http("http://localhost:8080/hubot/stormrunner/proxy/getRunResults?runid=#{strRunid}")
      .get() (err, res, body) ->

        # If we cannot find this run, display the error code and drop.

        if err or res.statusCode!=200
          msg.reply 'Sorry, there was an error retrieving the run results'
          msg.reply 'Status Code: ' + res.statusCode
          return

        robot.logger.debug "Res returned : \n" + body

        rslt = JSON.parse body

        # Initialize all variables

        attachments     = []
        strStartTime    = ""
        strEndTime      = ""
        strHrs          = ""
        strMins         = ""
        strSecs         = ""
        intDate         = 0
        objDate         = []
        strColor        = ""

        # As the date returned is in 'ticks' we need to format it
        # Therefore, Convert the returned string 'tick' date into a number
        # and then a date object.

        intDate = Number(rslt.startTime)
        objDate = new Date(intDate)

        # We need need to get the time, therefore extract the hours, mins and seconds
        # and convert them to a string

        strHrs  = objDate.getHours().toString()
        strMins = objDate.getMinutes().toString()
        strSecs = objDate.getSeconds().toString()

        # Now we have the returned date in the right format - call a function
        # to format the date into yyyy-mm-dd (tough luck USA!) and add on the time

        strStartTime = StormrunnerApi.fmtDate(objDate) + " " + strHrs.lpad("0",2) + ":" + strMins.lpad("0",2) + ":" + strSecs.lpad("0",2)

        # As the date returned is in 'ticks' we need to format it
        # Therefore, Convert the returned string 'tick' date into a number
        # and then a date object.

        intDate = Number(rslt.endTime)
        objDate = new Date(intDate)

        # We need need to get the time, therefore extract the hours, mins and seconds
        # and convert them to a string

        strHrs  = objDate.getHours().toString()
        strMins = objDate.getMinutes().toString()
        strSecs = objDate.getSeconds().toString()

        # Now we have the returned date in the right format - call a function
        # to format the date into yyyy-mm-dd (tough luck USA!) and add on the time.

        strEndTime = StormrunnerApi.fmtDate(objDate) + " " + strHrs.lpad("0",2) + ":" + strMins.lpad("0",2) + ":" + strSecs.lpad("0",2)
        strColor = Helpers.getColor(robot,rslt.uiStatus)
        strMessage = Helpers.getQuote(robot,rslt.uiStatus)

        fields =
          color : strColor
          fields : [
            {
              title: "Test ID"
              value: rslt.testId
              short: true
            },
            {
              title: "UI Status"
              value: rslt.uiStatus
              short: true
            },
            {
              title: "Start Time"
              value: strStartTime
              short: true
            },
            {
              title: "End Time"
              value: strEndTime
              short: true
            }
          ]

        #check to see if VU's or VUH's are used and output correct format
        #if VuserNum is greater than 0 and cost is defined (meaning a number is there)
        #output both labels and values
        #if there is only VuserNum, just output that label and value
        #we are separating each license type used into its own array
        if (rslt.uiVusersNum > 0 && rslt.actualUiCost != undefined)
          uiusers = [
                {
                  title: "UI Virtual Users"
                  value: rslt.uiVusersNum
                  short: true
                },
                {
                  title: "Actual UI Cost"
                  value: rslt.actualUiCost
                  short: true
                }
            ]
          #this is concatenating all the arrays used into one array, which gets
          #pushed to the Attachments array
          fields.fields = fields.fields.concat(uiusers)
        else if (rslt.uiVusersNum > 0)
          uiusers = [
                {
                  title: "UI Virtual Users"
                  value: rslt.uiVusersNum
                  short: true
                }
            ]
          fields.fields = fields.fields.concat(uiusers)

        if (rslt.apiVusersNum > 0 && rslt.actualApiCost != undefined)
          apiusers = [
              {
                title: "API Virtual Users"
                value: rslt.apiVusersNum
                short: true
              },
              {
                title: "Actual API Cost"
                value: rslt.actualApiCost
                short: true
              }
            ]
          fields.fields = fields.fields.concat(apiusers)
        else if (rslt.apiVusersNum > 0)
          apiusers = [
              {
                title: "API Virtual Users"
                value: rslt.apiVusersNum
                short: true
              }
            ]
          fields.fields = fields.fields.concat(apiusers)

        if (rslt.devVusersNum > 0 && rslt.actualDevCost != undefined)
          devusers = [
              {
                title: "DEV Virtual Users"
                value: rslt.devVusersNum
                short: true
              },
              {
                title: "Actual DEV Cost"
                value: rslt.actualDevCost
                short: true
              }
            ]
          fields.fields = fields.fields.concat(devusers)
        else if (rslt.devVusersNum > 0)
          devusers = [
              {
                title: "DEV Virtual Users"
                value: rslt.devVusersNum
                short: true
              }
            ]
          fields.fields = fields.fields.concat(devusers)

        attachments.push(fields)

        msgData = {
          channel: msg.message.room
          text: "Here are the run results for run id #{strRunid}. " + strMessage
          attachments: attachments
        }

        #robot.emit 'slack.attachment', msgData
        Helpers.sendCustomMessage(robot,msgData)
############################################################################
# Name:         run test
#
# Description:  Tells the bot to run specified test ID
#
# Called From:  (Direct from Chat client by typing the command 'run test (id)')
#
# Calls to:     'post Run' section (srl-openapi-proxy.coffee)
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  # Add command to hubot help
  #robot.commands.push "hubot run test <test id> - Executes the supplied test ID project Name/ID."
  #robot.respond /run test (.*)/i, (msg) ->
  robot.e.create {verb:'run',entity:'test',
  regex_suffix:{re: "(.*)", optional: false},
  help: 'Executes the supplied test ID project Name/ID',type:'respond',
  example: '1234'},(msg)->
    Helpers.setSharingRoom(robot,msg)

    # Extract the three variables part of the message (i.e. first the number of runs, followed by
    # the Test ID and then the project Name or Project ID)

    strTestId  = msg.match[1]
    intProject = Helpers.myProject(robot)       # Could be a Project Name or ID
    strProject = Helpers.findProjName(robot,intProject)

    robot.logger.debug "Running test #{strTestId} in #{strProject}"

    robot.http("http://localhost:8080/hubot/stormrunner/proxy/postRun?project=#{intProject}&TestID=#{strTestId}")
    .get() (err, res, body) ->

        # If we cannot find any runs for the test, display the error code and drop.

        if err or res.statusCode!=200
          msg.reply 'Sorry, there was an error retrieving the runs for the test'
          msg.reply 'Status Code: ' + res.statusCode
          return

        robot.logger.debug "Res returned : \n" + body

        runs = JSON.parse(body)

        # Initialize all variables

        attachments = []

        # Send the built message to the chat client/room.

        # Send URL to runs page of specified test

        strURL = ""
        strURL = util.format('https://stormrunner-load.saas.hpe.com/loadTests/%s/runs/?TENANTID=%s&projectId=%s', strTestId, process.env.SRL_TENANT_ID, intProject)

        msgData = {
          channel: msg.message.room
          text: "Your test is initializing and the Run ID is #{runs.runId}. Would you like a side of fries with that? \n #{strURL}"
          attachments: attachments
        }

        Helpers.sendCustomMessage(robot,msgData)
############################################################################
# Name:         set mock data <enabled/disabled>
#
# Description:  Tells the bot to use mock data instead of pulling from
#               the API's
#
# Called From:  (Direct from Chat client by typing the command 'set mock
#               data <enabled/disabled>')
#
# Calls to:     <none>
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  robot.respond /set mock data (.*)/i, (msg) ->
  robot.e.create {verb:'set',entity:'mock',
  regex_suffix:{re: "data (.*)", optional: false},
  help: 'Set Mock Data to enabled or disabled',type:'respond',
  example: 'data enabled'},(msg)->
    mockDataStatus= msg.match[1]
    if mockDataStatus is "enabled"
      robot.brain.set 'isMockData',true
    else if mockDataStatus is "disabled"
      robot.brain.set 'isMockData',false
    else
      msg.reply "Sorry, command not recognized!"
      return

    msg.reply "Mock data status set to : " + mockDataStatus
################################################################################
  #robot.commands.push "hubot set project to <Project Name or ID> - Sets the project."

  #robot.respond /set project to (.*)/i, (msg) ->
  robot.e.create {verb:'set',entity:'project',
  regex_suffix:{re: "to (.*)", optional: false},
  help: 'Sets the project to Project Name or ID',type:'respond',
  example: 'to Default Project or 12'},(msg)->
    Helpers.setSharingRoom(robot,msg)

    # Extract the variable part of the message (i.e. the project id or name)

    strProject = msg.match[1]
    robot.http("http://localhost:8080/hubot/stormrunner/proxy/setProject?project=#{strProject}")
      .get() (err, res, body) ->

        # If we cannot find this run, display the error code and drop.

        if err or res.statusCode!=200
          msg.reply 'Sorry, there was an error setting your desired project'
          msg.reply 'Status Code: ' + res.statusCode
          return

        robot.logger.debug "Res returned : \n" + body

        setProject = JSON.parse body

        attachments = []

        msgData = {
          channel: msg.message.room
          text: "I'll set the project to be #{strProject}. Do you also want me to shut down all the garbage smashers on the detention level?"
          attachments: attachments
        }

        #robot.emit 'slack.attachment', msgData
        Helpers.sendCustomMessage(robot,msgData)

############################################################################
# Name:         mock data status
#
# Description:  Shows the current status of the mock data flag
#
# Called From:  (Direct from Chat client by typing the command 'mock data
#               status')
#
# Calls to:     <none>
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  robot.respond /mock data status/i, (msg) ->
    mockDataStatus = robot.brain.get 'isMockData'
    msg.reply "Mock data status is #{mockDataStatus}"

############################################################################
# Name:         set share room <channel name>
#
# Description:  sets the room (channel) in which to post information
#
# Called From:  (Direct from Chat client by typing the command 'set share
#               room <channel name with a hash>')
#
# Calls to:     <none>
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  robot.respond /set share room (.*)/i, (msg) ->
    shareRoom= msg.match[1]
    robot.brain.set "shareRoom",shareRoom
    msg.reply "Share room set to #{shareRoom}"

############################################################################
# Name:         get share room
#
# Description:  Shows the current state of the share room (channel)
#
# Called From:  (Direct from Chat client by typing the command 'mock data
#               status')
#
# Calls to:     <none>
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  robot.respond /get share room/i, (msg) ->
    shareRoom= robot.brain.get "shareRoom"
    msg.reply "Share room is #{shareRoom}"

############################################################################
# Name:         get errror instance
#
# Description:  ?????
#
# Called From:  (Direct from Chat client by typing the command 'get error
#               instance')
#
# Calls to:     <none>
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  robot.respond /get error instance/i, (msg) ->
    Helpers.setSharingRoom(robot,msg)
    Helpers.shareToRoom(robot)

############################################################################
# Name:         share to room
#
# Description:  ???? (Doesn't work)
#
# Called From:  (Direct from Chat client by typing the command 'share to room')
#
# Calls to:     <none>
#
# Author(s):    Cyrus Manouchehrian (inital version)
#               Will Zuill
############################################################################
  robot.respond /share to room/i, (msg) ->
    Helpers.shareToRoom(robot)
############################################################################
# Name: catchAll
#
# Description:  If none of the above commands are typed, then check to see
#               if we are talking to the bot
#
# Called from:  not being called from anywhere - a trapping function
#
# Calls to:     setSharingRoom(helpers.coffee)
#               sendCustomMessage(helpers.cofee)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
############################################################################
  robot.catchAll (msg) ->

    # Check to see if either the robot alias or name is in the contents of the message
    # (we have to check for both with and without an @ symbol)
    rexBotCalled = new RegExp "^(?:#{robot.alias}|@#{robot.alias}#{robot.name}|@#{robot.name}) (.*)","i"

    strMessMatch = msg.message.text.match(rexBotCalled)

    # if it does match (and therefore we are talkig to the bot directly) then send a message

    if strMessMatch != null && strMessMatch.length > 1

      Helpers.setSharingRoom(robot,msg)

      msgData = {
        channel: msg.message.room
        text: "You want to do WHAT with me? That's illegal in all 50 states. Let's check the help."
      }

      Helpers.sendCustomMessage(robot,msgData)
