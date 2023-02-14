<#
.SYNOPSIS
Create Scheduled Task that runs at logon for any user that logs on.
.DESCRIPTION
Create Scheduled Task that runs at logon for any user that logs on.
This uses the Schedule Service COM Obect because the `ScheduledTasks` module doesn't allow you to set "all users".

For other, less specific sceduled tasks needs, just use the `ScheduledTasks` module.
There's no reason to replace the work done on that module; this just makes this one thing a little easier.
.PARAMETER TaskName
The name of the task. If this value is NULL, the task will be registered in the root task folder and the task name will be a GUID value created by the Task Scheduler service.

A task name cannot begin or end with a space character. The '.' character cannot be used to specify the current task folder and the '..' characters cannot be used to specify the parent task folder in the path.
.PARAMETER Description
Sets the description of the task.

- [Description](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-iregistrationinfo-put_description)
.PARAMETER Path
Sets the path to an executable file.

- [Path](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-iexecaction-get_path)
.PARAMETER Arguments
Sets the arguments associated with the command-line operation.

- [Arguments](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-iexecaction-put_arguments)
.PARAMETER WorkingDirectory
Sets the directory that contains either the executable file or the files that are used by the executable file.

- [WorkingDirectory](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-iexecaction-put_workingdirectory)
.NOTES
- [Triggers Create](https://learn.microsoft.com/en-us/windows/win32/taskschd/triggercollection-create#parameters):
  - `TASK_TRIGGER_LOGON` (9): Triggers the task when a specific user logs on.
- [Actions Create](https://learn.microsoft.com/en-us/windows/win32/taskschd/actioncollection-create#parameters):
  - `TASK_ACTION_EXEC` (0): The action performs a command-line operation. For example, the action could run a script, launch an executable, or, if the name of a document is provided, find its associated application and launch the application with the document.
    - [ExecAction](https://learn.microsoft.com/en-us/windows/win32/taskschd/execaction):
      - [Path](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-iexecaction-get_path): Sets the path to an executable file.
      - [Arguments](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-iexecaction-put_arguments): Sets the arguments associated with the command-line operation.
      - [WorkingDirectory](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-iexecaction-put_workingdirectory): Sets the directory that contains either the executable file or the files that are used by the executable file.
- [RegisterTaskDefinition](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-itaskfolder-registertaskdefinition): `TASK_LOGON_INTERACTIVE_TOKEN_OR_PASSWORD` (6)
  - [Path](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-itaskfolder-registertaskdefinition#parameters): *See TaskName parameter description.*
  - [Definition](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-itaskfolder-registertaskdefinition#parameters): The definition of the registered task.
  - [Flags](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/ne-taskschd-task_creation#constants): 6
    - `TASK_CREATE` (*0x2*): The Task Scheduler service registers the task as a new task.
    - `TASK_UPDATE` (*0x4*): The Task Scheduler service registers the task as an updated version of an existing task. When a task with a registration trigger is updated, the task will execute after the update occurs.
  - [UserId](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-itaskfolder-registertaskdefinition#parameters): The user credentials used to register the task. If present, these credentials take priority over the credentials specified in the task definition object pointed to by the Definition parameter.
  - [LogonType](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-itaskfolder-registertaskdefinition#parameters): Defines what logon technique is used to run the registered task.
    - `TASK_LOGON_GROUP` (4): Group activation. The groupId field specifies the group.
  #>
function New-ScheduledTaskTriggerLogonRunAsUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $TaskName,

        [Parameter(Mandatory = $false)]
        [string]
        $Description,

        [Parameter(Mandatory = $true)]
        [IO.FileInfo]
        $Path,

        [Parameter(Mandatory = $false)]
        [string]
        $Arguments,

        [Parameter(Mandatory = $true)]
        [IO.DirectoryInfo]
        $WorkingDirectory
    )

    $shedService = New-Object -ComObject 'Schedule.Service'
    $shedService.Connect()

    $task = $shedService.NewTask(0)
    if ($Description) {
        $task.RegistrationInfo.Description = $Description
    }
    $task.Settings.Enabled = $true
    $task.Settings.AllowDemandStart = $true

    $trigger = $task.Triggers.Create(9)
    $trigger.Enabled = $true

    $action = $task.Actions.Create(0)
    $action.Path = $Path.FullName
    if ($Arguments) {
        $action.Arguments = $Arguments
    }
    if ($WorkingDirectory) {
        $action.WorkingDirectory = $WorkingDirectory.FullName
    }

    $taskFolder = $shedService.GetFolder('\')
    $taskFolder.RegisterTaskDefinition($TaskName, $task , 6, 'Users', $null, 4)
}
