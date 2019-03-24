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


StormRunnerApi = require './libs/stormrunnerApiAdapter.js'
Helpers = require './helpers'
querystring = require "querystring"
mockData = require "./mockData"

url = require('url')
################################################################################
# Name:         proxy/GetProjects
#
# Description:  This acts as the local web server. It will parse the query
#               url and then send the request to Helpers.getProjects
#
# Called from:  stormrunner-bot-logic.coffee - show me all the projects
#
# Calls to:     Helpers -> getProjects
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
module.exports = (robot) ->
  #listening to proxy command - get projects
  robot.router.get '/hubot/stormrunner/proxy/getProjects', (req, res) ->
    try
      #parses the url sent from stormrunner-bot-logic
      query = querystring.parse(url.parse(req.url).query)
      robot.logger.debug "Getting Projects... refresh=#{query.refresh}"

      #with success, go to Helpers.getProjects function to get projects
      projs = Helpers.getProjects(robot,query.refresh)
      res.send projs
    catch error
      #if there is an error, catch it and output the error for possible
      #troubleshoot
      robot.logger.error "Error getting Projects : \n #{error}"
      res.status(500).send "Error retrieving Projects"

################################################################################
# Name:         proxy/getTests
#
# Description:  This acts as the local web server. It will parse the query
#               url and then send the request to Helpers.getTests
#
# Called from:  stormrunner-bot-logic.coffee - list tests for project (.*)
#
# Calls to:     Helpers -> getTests(robot,project)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  #listening to proxy command - get test
  robot.router.get '/hubot/stormrunner/proxy/getTests', (req, res) ->
    try
      #parses the url sent from stormrunner-bot-logic
      query = querystring.parse(url.parse(req.url).query)
      #from parsing, parses out project ID or project name
      project= query.project
      robot.logger.debug "Getting Tests... refresh=#{query.refresh}"

      #upon success, go to Helpers.GetTests function to get tests
      tests = Helpers.getTests(robot,project)
      res.send tests
    catch error
      #if there is an error, catch it and output the error for possible
      #troubleshoot
      robot.logger.error "Error getting Tests : \n #{error}"
      res.status(500).send "Error retrieving Tests"
################################################################################
# Name:         proxy/getRuns
#
# Description:  This acts as the local web server. It will parse the query
#               url and then send the request to Helpers.getRuns
#
# Called from:  stormrunner-bot-logic.coffee -
#               show latest run for test (.*) in project (.*)
#               list status for last (.*) runs for test (.*) in project (.*)
#               show runs for test (.*) in project (.*)
#
# Calls to:     Helpers -> getRuns(robot,project,testid)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  #listening to proxy command - getRuns
  robot.router.get '/hubot/stormrunner/proxy/getRuns', (req, res) ->
    try
      #parses the url sent from stormrunner-bot-logic
      query = querystring.parse(url.parse(req.url).query)
      #from parsing the url, project id or project name is retrieved
      project = query.project
      #from parsing the url, the test id is retrieved
      testid = query.TestID
      robot.logger.debug "Getting Run Results... refresh=#{query.refresh}"

      #upon success, go to Helpers.getRuns function to get runs
      tests = Helpers.getRuns(robot,project,testid)
      res.send tests
    catch error
      #if there is an error, catch it and output the error for possible
      #troubleshoot
      robot.logger.error "Error getting Tests : \n #{error}"
      res.status(500).send "Error retrieving Tests"
################################################################################
# Name:         proxy/getRunResults
#
# Description:  This acts as the local web server. It will parse the query
#               url and then send the request to Helpers.getRunResults
#
# Called from:  stormrunner-bot-logic.coffee -
#               show full results for run id (.*)
#
# Calls to:     Helpers -> getRunResults(robot,runid)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  #listening to proxy command - getRunResults
  robot.router.get '/hubot/stormrunner/proxy/getRunResults', (req, res) ->
    try
      #parses the url sent from stormrunner-bot-logic
      query = querystring.parse(url.parse(req.url).query)
      #from parsing the url, run id is retrieved
      runid = query.runid
      robot.logger.debug "Getting Tests... refresh=#{query.refresh}"

      #upon success, go to Helpers.getRunResults to run results
      tests = Helpers.getRunResults(robot,runid)
      res.send tests
    catch error
      #if there is an error, catch it and output the error for possible
      #troubleshoot
      robot.logger.error "Error getting Tests : \n #{error}"
      res.status(500).send "Error retrieving Tests"
###############################################################################
# Name:         proxy/getRuns
#
# Description:  This acts as the local web server. It will parse the query
#               url and then send the request to Helpers.getRuns
#
# Called from:  stormrunner-bot-logic.coffee -
#               show latest run for test (.*) in project (.*)
#               list status for last (.*) runs for test (.*) in project (.*)
#               show runs for test (.*) in project (.*)
#
# Calls to:     Helpers -> getRuns(robot,project,testid)
#
# Author(s):    Cyrus Manouchehrian
#               Will Zuill
################################################################################
  #listening to proxy command - getRuns
  robot.router.get '/hubot/stormrunner/proxy/postRun', (req, res) ->
    try
      #parses the url sent from stormrunner-bot-logic
      query = querystring.parse(url.parse(req.url).query)
      #from parsing the url, project id or project name is retrieved
      project = query.project
      #from parsing the url, the test id is retrieved
      testid = query.TestID
      robot.logger.debug "Getting Run Results... refresh=#{query.refresh}"

      #upon success, go to Helpers.getRuns function to get runs
      tests = Helpers.postRun(robot,project,testid)
      res.send tests
    catch error
      #if there is an error, catch it and output the error for possible
      #troubleshoot
      robot.logger.error "Error getting Tests : \n #{error}"
      res.status(500).send "Error retrieving Tests"
################################################################################
  robot.router.get '/hubot/stormrunner/proxy/setProject', (req, res) ->
    try
      query = querystring.parse(url.parse(req.url).query)
      strProject = query.project
      robot.logger.debug "Setting the project... refresh=#{query.refresh}"

      project = Helpers.setProject(robot,strProject)
      res.send project
    catch error
      #if there is an error, catch it and output the error for possible
      #troubleshoot
      robot.logger.error "Error setting Project: \n #{error}"
      res.status(500).send "Error setting Project"
################################################################################
  robot.router.post '/hubot/stormrunner/proxy/jenkinsNotifer', (req, res) ->
    try
      query         = querystring.parse(url.parse(req.url).query)
      data          = req.body
      strUsername   = query.user
      strRoom       = query.room
      strMessage    = ""
      strPhase      = data.build.phase

      # if the username has been passed in, add a '@' symbol to the front and
      # set that as the channel

      if strUsername
            strChannel = "@" + strUsername
      # if the room has been passed in, add a '#' symbol to the front and
      # set that as the channel
      else if strRoom
            strChannel = "#" + strRoom
      else
            strChannel = "#general"     # default channel

      # Depending on the phase of the build - post a message to the room.

      if strPhase == "STARTED"
                strMessage = "Hey - Just wanted to let you know that the Jenkins Job entitled '" + data.name + "' with build number: " + data.build.number + " has started."
      else if strPhase == "COMPLETED"

                strDay = StormRunnerApi.getDayOfTheWeek()

                if data.build.status == "FAILURE"

                    strStatusMess = "Unfortunately, the build failed.  This must be " + strDay + ".  I never could get the hang of " + strDay + "s."

                else
                    strStatusMess = "Good news.  The build was successful.  Now, go and make sure you put cover sheets on your TPS reports."

                strMessage = "Sorry to bother you, but Jenkins Job entitled '" + data.name + "' with build number: " + data.build.number + " is complete.  " + strStatusMess

      # if we do have a message (i.e. we have been passed a status we want to post about) then post the message to the previously defined channel

      if strMessage
                msgData =
                {
                    channel: strChannel
                    text: strMessage
                }

                Helpers.sendCustomMessage(robot,msgData)


    catch error
      robot.logger.error "There's a problem with the Jenkins Notifer : \n #{error}"
      res.status(500).send "Error sending message to Hubot"
