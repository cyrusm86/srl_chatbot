/*
 * Copyright 2016 Hewlett-Packard Development Company, L.P.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * Software distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License.
 */

var request = require('sync-request');
var util = require('util');
var daysToSubtract = 2;
var authDetails=undefined;
var authHeader=undefined;
var saasPrefix = process.env.SRL_SAAS_PREFIX;
var saasUrl = process.env.SRL_SAAS_URL;
var tenantId = process.env.SRL_TENANT_ID;
var cookie = undefined;
var dtExpire = undefined;

/*
 Name:         makeAuth

 Description:  Authenticates with StormRunner Load API. Information regarding
               URL, Tenant ID, Username and Password are set as environment
               variables when initiating the bot. The cookies that are supplied
               with authentication expire after 3 hours, so we are checking to
               make sure time hasn't expired before we authenticate again.

 Called From:  The following within stormrunnerApiAdapter:
               getPrjs
               getRuns
               getRunResult
               getTests

 Calls to:     N/A - just setting authdetails and cookies for executing API's

 Author(s):    Will Zuill (inital Version)
               Cyrus Manouchehrian
*/

function makeAuth(){
  //set current time
  var currTime = new Date().getTime();
  //if we have authenicated, let's see if are cookies have expired
  if(authDetails!=undefined){
    //find the delta between the time when the cookies will expire and now
    var delta = dtExpire - currTime;
    //console.log("This is the auth details - " + JSON.stringify(authDetails));

    console.log(util.format("Auth details : Current time: %s , expiration time: %s delta : %s",
      currTime,dtExpire,delta));

    //if the delta is greater than zero, no need to authenticate
    if(delta> 0){
      console.log("Current time is less than expiration time - no auth required");
      return;
    }

  console.log("Current time is larger than expiration time - auth required!");
  }

    //making a post to the login api (auth api not working yet)
    //saasPrefix = https://stormrunner-load.saas.hpe.com/v1
    //tenantId = whatever is set for customer (i.e.: 159221713)
    //username and password are credentials to log into SaaS portal
    var req = request('POST', util.format('%s/login?TENANTID=%s', saasPrefix, tenantId), {
        json:{
            user: process.env.SRL_USERNAME,
            password: process.env.SRL_PASSWORD
        }
    });

    //setting authdetails to the the body of the response
    authDetails = JSON.parse(req.getBody('utf8'));

    //if we are successful in authenticating, set the cookies
    //cookies expire after 3 hours, setting date for expiration
    //the cookies are what we need to continue with other API's
    //LWSSO_COOKIE_KEY is the token from authentication
    //HPSSO-HEADER-CSRF is hpsso_cookie_csrf from the response header
    if (req.statusCode == 200){
        dtExpire = new Date();
        dtExpire.setHours(dtExpire.getHours() + 3);
        cookie = ("LWSSO_COOKIE_KEY="+authDetails.token) + ";" +
        ("HPSSO-HEADER-CSRF="+req.headers.hpsso_cookie_csrf);
    }
}

/*
 Name:         executeOpenApi(url)

 Description:  Executes the API's that we provide from the url that is being
               passed. Right now, they are all gets. This will eventually be
               extended to posts, updates and deletes.

 Called From:  The following within stormrunnerApiAdapter:
               getPrjs
               getRuns
               getRunResult
               getTests

 Calls to:     Returns JSON response to the above functions

 Author(s):    Will Zuill (inital Version)
               Cyrus Manouchehrian
*/
function executeOpenApi(url,strMethod){
    //append the saasPrefix to the url being passed (i.e.: projects)
    url = saasPrefix + url;
    //set fullURL to the entire url
    var fullURL = url;

    //making request to the specific API, which includes the cookies that we
    //grabbed from makeAuth
    var res = request(strMethod, fullURL, {
        'headers': {'Content-Type': "application/json",
            'cookie': cookie
        }
    });

    return res.getBody();
}

String.prototype.lpad = function(padString, length) {
  var str = this;
  while (str.length < length)
    str = padString + str;
  return str;
}

/*
 Name:         formateDate(date)

 Description:  Formats a passed date to yyyy-mm-dd

 Called From:  multiple places

 Calls to:     Returns properly foramtted date

 Author(s):    Will Zuill (inital Version)
               Cyrus Manouchehrian
*/
function formatDate(date){

  var month = (date.getMonth() +1).toString();
  var day = date.getDate().toString();
  var year = date.getFullYear().toString();

  return date.getFullYear() + "-" + month.lpad("0",2) + "-" + day.lpad("0",2);

}

/*
 Name:         formatDuration(intDuration)

 Description:  Formats a duration into an easy to read format. Duration values
               come back in Unix format xxxxxxxxxx

 Called From:  multiple places

 Calls to:     Returns hh:mm:ss

 Author(s):    Will Zuill (inital Version)
               Cyrus Manouchehrian
*/
function formatDuration(intDuration){

    console.log("this is the intDuration " + intDuration);

    var intMicroSecs    = 0;
    var intSecs         = 0;
    var intMins         = 0;
    var intHrs          = 0;
    var strHrs          = "";
    var strMins         = "";
    var strSecs         = "";

    intMicroSecs = intDuration % 1000
    intDuration  = (intDuration - intMicroSecs) / 1000
    intSecs      = intDuration % 60
    intDuration  = (intDuration - intSecs) / 60
    intMins      = intDuration % 60
    intHrs       = (intDuration - intMins) / 60

    strHrs       = intHrs.toString();
    strMins      = intMins.toString();
    strSecs      = intSecs.toString();

    return strHrs.lpad("0",2) + ":" + strMins.lpad("0",2) + ":" + strSecs.lpad("0",2);

}

module.exports = {
  fmtDuration:function(intDuration){
      strDuration = formatDuration(intDuration);
      return strDuration;
  },
  fmtDate:function(Date){
      strDate = formatDate(Date);
      return strDate;
  },
  getDayOfTheWeek:function() {
    var objTodaysDate   = new Date();
    var intDayNumber    = objTodaysDate.getDay();
    var strDays         = [
                            "Sunday",
                            "Monday",
                            "Tuesday",
                            "Wednesday",
                            "Thursday",
                            "Friday",
                            "Saturday"
                          ];

    return strDays[intDayNumber];

  },
  setDaysToSubstract:function(days){
    daysToSubtract = days;
  },
  getDaysToSubstract:function(){
    return daysToSubtract
  },
  getSaaSUrl:function () {
    return saasUrl;
  },

  getTenantId : function(){
    return tenantId;
  },
  /*
   Name:         getPrjs

   Description:  This makes a GET call to the projects API within StormrunnerApi
                 and returns all available projects within a specific Tenant

   Called From:  Helpers.coffee -> getProjects

   Calls to:     Returns JSON response to the above function

   Author(s):    Will Zuill (inital Version)
                 Cyrus Manouchehrian
  */
  getPrjs: function() {
    //make authentication
    makeAuth();

    //make a GET call with the passed URL (i.e.: projects)
    var resJson = executeOpenApi(util.format('/projects?TENANTID=%s',tenantId),"GET");

    //return JSON retreived from above GET call
    return resJson;
  },
  /*
   Name:         getTests(projid)

   Description:  This makes a GET call to the Tests API within StormrunnerApi
                 and returns all tests within a specific project

   Called From:  Helpers.coffee -> getTests

   Calls to:     Returns JSON response to the above function

   Author(s):    Will Zuill (inital Version)
                 Cyrus Manouchehrian
  */
  getTests: function(projid){
      //making authentication
      makeAuth();

      //make a GET call with the passed url (i.e.: tests)
      var resJson = executeOpenApi(util.format('/projects/%s/load-tests?TENANTID=%s', projid, tenantId),"GET");

      //returns JSON received from above GET call
      return resJson;
  },
  /*
   Name:         getRuns(projid,testid)

   Description:  This makes a GET call to the load-tests/runs API within
                 StormrunnerApi and returns all runs associated with a passed
                 testid within a specific project

   Called From:  Helpers.coffee -> getRuns

   Calls to:     Returns JSON response to the above function

   Author(s):    Will Zuill (inital Version)
                 Cyrus Manouchehrian
  */
  getRuns: function(projid,testid){
      //making authentication
      makeAuth();

      //making a GET call with passed url (i.e.: load-tests/runs)
      var resJson = executeOpenApi(util.format('/projects/%s/load-tests/%s/runs?TENANTID=%s', projid, testid, tenantId),"GET");

      //returns JSON received from above GET call
      return resJson;
  },
  /*
   Name:         getRunResults(runid)

   Description:  This makes a GET call to the load-runs API within
                 StormrunnerApi and returns results of rspecific runas

   Called From:  Helpers.coffee -> getRunResults

   Calls to:     Returns JSON response to the above function

   Author(s):    Will Zuill (inital Version)
                 Cyrus Manouchehrian
  */
  getRunResult: function(runid){
      //making authenciation
      makeAuth();

      //making a GET call with passed url (i.e.: test-runs)
      var resJson = executeOpenApi(util.format('/test-runs/%s?TENANTID=%s', runid, tenantId),"GET");

      //returns JSON received from above GET call
      return resJson;
  },
  /*
   Name:         startRun(projid,testid,strMethod)

   Description:  This makes a GET call to the load-tests/runs API within
                 StormrunnerApi and returns all runs associated with a passed
                 testid within a specific project

   Called From:  Helpers.coffee -> getRuns

   Calls to:     Returns JSON response to the above function

   Author(s):    Will Zuill (inital Version)
                 Cyrus Manouchehrian
  */
  postRun: function(projid,testid){
      //making authentication
      makeAuth();

      //making a GET call with passed url (i.e.: load-tests/runs)
      var resJson = executeOpenApi(util.format('/projects/%s/load-tests/%s/runs?TENANTID=%s', projid, testid, tenantId),"POST");

      //returns JSON received from above GET call
      return resJson;
  }
};
