#MSProject Project Task Create 

  This handler creates a task under a current project.

#Parameters

[Project Id]  - The project id of the project that you want to create a task under.

[Task Name]   - The name of the task that you want to create.

[Task Note]   - The note that you want to add to the created task.

#Results

[Task Id] - The id of the successfully created task.

#Sample Configuration

Project Id:                   db521c56-44ab-422d-9abd-29d8d359043a

Task Name:                    Testing Task

Task Note:                    This is a test note

#Detailed Description

This handler makes a REST call Microsoft Project Online to the Project Server
API to create a task under a specified Project. After authenticating against 
the Project Server using the inputted username and password, the handler first 
makes a call to Project to get a FormDigestValue which is needed as a part of the 
authentication for future calls. That value is then used along with the Project 
Id, Task Name, and Task Note (if included) parameters to make a POST request to 
the API to create the Task. Any errors that occur during this process will be 
caught and re-raised by the handler.
