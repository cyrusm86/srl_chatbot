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


root = exports ? this
root.prjsMockData={
  "metaData": {
    "message": "Success",
    "messageCode": 2000
  },
  "data": {
    "projects": [
      {
        "id": 1,
        "name": "Spy Hunter"
      },
      {
        "id": 2
        "name": "Bubble Bobble"
      },
      {
        "id": 3
        "name": "Wizball"
      },
      {
        "id": 4
        "name": "Paperboy"
      }

    ]
  }
}
root.testsMockData={
  "metaData": {
    "message": "Success",
    "messageCode": 2000,
    "projectId": 1,
    "TENANTID": 123456
  },
  "data": {
    "tests": [
      {
        "id": 10,
        "name": "Mobile",
        "createDate" : 1460403060000
      },
      {
        "id": 20,
        "name": "Desktop Site",
        "createDate" : 1288131120000
      }

    ]
  }
}

