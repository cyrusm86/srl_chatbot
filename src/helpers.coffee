###
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


StormrunnerApi = require "./libs/stormrunnerApiAdapter.js"
mockData = require "./mockData"
globalRobot = null

module.exports =
  setRobot:(robot)->
    robot.logger.debug "robot set!"
    globalRobot = robot
  getRobot:()->
    return globalRobot

  getAppId:(apps,appName) ->
    for index,value of apps
      if value.applicationName is appName
        return value.applicationId
    return undefined

################################################################################
# Name:         getProjects
#
# Description:  This will check to see if anything has been saved to the robots
#               brain and then retreive all projects from SRL API
#
# Called from:  srl-openapi-proxy.coffee - '/hubot/stormrunner/proxy/getProjects'
#
# Calls to:     stormrunnerApiAdapter -> getPrjs
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  getProjects:(robot,refresh=false) ->
    #check to see if mock data is enabled
    useMockData = robot.brain.get 'isMockData'

    #checking robot braing for projects 'prjs'
    prjs = robot.brain.get 'prjs'
    prjs = null
    if prjs is null or refresh
      robot.logger.debug "Getting projects from server..."
      #if using mock data, send mock data
      if useMockData
        #set prjs to mock data
        prjs =  mockData.prjsMockData.data.projects
      else
        #make call to the StormRunnerAPI to get results
        prjs = StormrunnerApi.getPrjs()

      #when results are returned, set the prjs in the robot brain
      robot.brain.set("prjs",prjs)

    return prjs
################################################################################
# Name:         findProjID(robot,projectName)
#
# Description:  When a project name is sent, this will retrieve the project ID
#
# Called from:  helpers.coffee - getTests, getRuns, getRunResults
#
# Calls to:     helpers.coffee - getProjects
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  findProjID:(robot,projectName)->
    #set blank variable arrary
    result = []
    #locate project id from getProjects function
    projid = this.getProjects(robot)
    #setting hello to return JSON
    hello = JSON.parse projid
    #loops through return and locates project id
    for index,value of hello
        if value.name is projectName
            result.push(value.id)
    #returns located value (project id)
    return result
###############################################################################
# Name:         getTests(robot,project)
#
# Description:  This will check to see if anything has been saved to the robots
#               brain and then retreive all tests associate with passed project
#
# Called from:  srl-openapi-proxy.coffee - '/hubot/stormrunner/proxy/getTests'
#
# Calls to:     stormrunnerApiAdapter -> getTests(projects)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  getTests:(robot,project) ->
    #check to see if mock data is enabled
    useMockData = robot.brain.get 'isMockData'

    #isNan() determines if a value is an illegal number
    #if it is, grab the project ID
    #if not, then use the passed value as project id
    if isNaN(project)
        projects = this.findProjID(robot,project)
    else
        projects = project

    #set tests to the robot brain for tests values
    tests = robot.brain.get 'tests'
    tests = null
    if tests is null or refresh
      robot.logger.debug "Getting tests from server..."
      #if using mock data, then grab that info
      #if not using mock data, go to the API and grab info
      if useMockData
        tests =  mockData.testsMockData.data.tests
      else
        tests = StormrunnerApi.getTests(projects)

      #set the robot brain to returned value
      robot.brain.set("tests",tests)

    return tests
###############################################################################
# Name:         getRuns(robot,project,testid)
#
# Description:  This will check to see if anything has been saved to the robots
#               brain and then retreive all runs to an associated test and
#               project from SRL API
#
# Called from:  srl-openapi-proxy.coffee - '/hubot/stormrunner/proxy/getRuns'
#
# Calls to:     stormrunnerApiAdapter -> getRuns(projects,testid)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  getRuns:(robot,project,testid) ->
    #check to see if mock data is enabled
    useMockData = robot.brain.get 'isMockData'

    #isNan() determines if a value is an illegal number
    #if it is, grab the project ID
    #if not, then use the passed value as project id
    if isNaN(project)
        projects = this.findProjID(robot,project)
    else
        projects = project

    #set runs to the robot brain for runs values
    runs = robot.brain.get 'runs'
    runs = null
    if runs is null or refresh
      robot.logger.debug "Getting runs from server..."
      #if using mock data, then grab that info
      #if not using mock data, go to the API and grab info
      if useMockData
        runs =  mockData.testsMockData.data.runs
      else
        runs = StormrunnerApi.getRuns(projects,testid)

      #set the robot brain to returned value
      robot.brain.set("runs",runs)

    return runs
###############################################################################
# Name:         getRuns(robot,project,testid)
#
# Description:  This will check to see if anything has been saved to the robots
#               brain and then retreive all runs to an associated test and
#               project from SRL API
#
# Called from:  srl-openapi-proxy.coffee - '/hubot/stormrunner/proxy/getRuns'
#
# Calls to:     stormrunnerApiAdapter -> getRuns(projects,testid)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  postRun:(robot,project,testid) ->
    #check to see if mock data is enabled
    useMockData = robot.brain.get 'isMockData'

    #isNan() determines if a value is an illegal number
    #if it is, grab the project ID
    #if not, then use the passed value as project id
    if isNaN(project)
        projects = this.findProjID(robot,project)
    else
        projects = project

    #set runs to the robot brain for runs values
    postRun = robot.brain.get 'postRun'
    postRun = null
    if postRun is null or refresh
      robot.logger.debug "Starting run from server..."
      #if using mock data, then grab that info
      #if not using mock data, go to the API and grab info
      if useMockData
        postRun =  mockData.testsMockData.data.postRun
      else
        postRun = StormrunnerApi.postRun(projects,testid)

      #set the robot brain to returned value
      robot.brain.set("postRun",postRun)

    return postRun
################################################################################
# Name:         getRunResults(robot,runid)
#
# Description:  This will check to see if anything has been saved to the robots
#               brain and then retreive run result for specifc RUN ID
#
# Called from:  srl-openapi-proxy.coffee - '/hubot/stormrunner/proxy/getRunResults'
#
# Calls to:     stormrunnerApiAdapter -> getRunResult(runid)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  getRunResults:(robot,runid) ->
    #check to see if mock data is enabled
    useMockData = robot.brain.get 'isMockData'

    #set rslt to the robot brain for run result value
    rslt = robot.brain.get 'rslt'
    rslt = null
    if rslt is null or refresh
      robot.logger.debug "Getting run result from server..."
      #if using mock data, then grab that info
      #if not using mock data, go to the API and grab info
      if useMockData
        rslt =  mockData.testsMockData.data.rslt
      else
        rslt = StormrunnerApi.getRunResult(runid)

      #set the robot brain to returned value
      robot.brain.set("rslt",rslt)

    return rslt
###############################################################################
# Name:         setProject(robot,project)
#
# Description:  Setting the project for the bot
#
# Called from:  srl-openapi-proxy.coffee - '/hubot/stormrunner/proxy/setProject'
#
# Calls to:     helper.coffee -> findProjID(robot,project)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  setProject:(robot,project) ->

    #isNan() determines if a value is an illegal number
    #if it is, grab the project ID
    #if not, then use the passed value as project id
    if isNaN(project)
        setproject = this.findProjID(robot,project)
    else
        setproject = project

    robot.brain.set("setproject",setproject)

    return setproject
###############################################################################
# Name:         myProject(robot)
#
# Description:  This will set the project to be worked on to the default project
#               if no project has been set
#
# Called from:  stormrunner-bot-logic.coffee - multiple commands
#
# Calls to:     n/a
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  myProject:(robot) ->

    setproject = robot.brain.get 'setproject'
    if setproject is null
        setproject = 1
        robot.brain.set("setproject",setproject)

    return setproject
###############################################################################
# Name:         findProjName(robot,intProject)
#
# Description:  This will set the project name based on the project id that is
#               passed to the function (intProject)
#
# Called from:  stormrunner-bot-logic.coffee - multiple commands
#
# Calls to:     helpers.coffee - getProjects
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  findProjName:(robot,intProject) ->

    #make a call to getProjects function
    strProjectName = ""
    projname = this.getProjects(robot)
    hello = JSON.parse projname

    #returns JSON and we loop through JSON to find
    #the project name and store it
    for index,value of hello
        if value.id.toString() == intProject.toString()
            strProjectName = value.name

    return strProjectName
###############################################################################
# Name:         getColor(robot,strStatus)
#
# Description:  We set the color for the output passed out on the status of the
#               run(s)
#
# Called from:  stormrunner-bot-logic.coffee - multiple commands
#
# Calls to:     n/a
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  getColor:(robot,strStatus) ->
  #we are adjusting the color to match SRL based on status of the run(s)

    if strStatus is "FAILED"
      strColor = "#F04953"
    else if strStatus is "PASSED"
      strColor = "#01A987"
    else if strStatus is "ABORTED"
      strColor = "#877B75"
    else if strStatus is "HALTED"
      strColor = "#B95596"
    else if strStatus is "STOPPED"
      strColor = "#000000"
    else if strStatus is "SYSTEM_ERROR"
      strColor = "#FF8D6D"
    else
      strColor = "0000FF"

    return strColor
###############################################################################
# Name:         getQuote(robot,strStatus)
#
# Description:  Returns a message based on status of run(s)
#
# Called from:  stormrunner-bot-logic.coffee - multiple commands
#
# Calls to:     n/a
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  getQuote:(robot,strStatus) ->
  #sending a message based on the status of the run(s)

    if strStatus is "FAILED"
      strMessage = "Help me, Obi-Wan Kenobi. You're my only hope."
    else if strStatus is "PASSED"
      strMessage = "You've got to ask yourself one question: 'Do you feel lucky?' Well, do ya punk?"
    else if strStatus is "ABORTED"
      strMessage = "Fear is the path to the dark side."
    else if strStatus is "HALTED"
      strMessage = "I find your lack of faith disturbing."
    else if strStatus is "STOPPED"
      strMessage = "Try not. Do… or do not. There is no try."
    else if strStatus is "SYSTEM_ERROR"
      strMessage = "It's a trap"
    else
      strMessage = "Show me the money!"

    return strMessage
################################################################################

  setSharingRoom:(robot,msg)->
    shareRoom = msg.message.room
    robot.logger.debug "Sharing room set to #{shareRoom}"
    robot.brain.set "shareRoom",shareRoom

  shareToRoom:(robot)->
    date = new Date();

    timeStamp = [date.getFullYear(), (date.getMonth() + 1), date.getDate()].join("-") + " " + [date.getHours()-1, date.getMinutes(), date.getSeconds()].join(":")
    RE_findSingleDigits = /\b(\d)\b/g

    # Places a `0` in front of single digit numbers.
    timeStamp = timeStamp.replace( RE_findSingleDigits, "0$1")
    timeStamp.replace /\s/g, ""

    data = JSON.stringify(mockData.shareDataMock)
    data = data.replace("_CRASH_TIME_",timeStamp)
    robot.http("http://localhost:8080/hubot/stormrunner/botchannel")
      .header('Content-Type', 'application/json')
      .post(data)

  sendCustomMessage: (robot,data,room) =>
    robot.logger.debug "New code!"
    roomToSend = undefined
    if not room
      roomToSend = data.channel
    else
      roomToSend = room


    robot.logger.debug "Sending custom message to #{roomToSend}"

    robot.send {room : roomToSend},data
