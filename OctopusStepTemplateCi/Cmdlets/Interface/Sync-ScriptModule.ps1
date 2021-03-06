<#
Copyright 2016 ASOS.com Limited

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#
.NAME 
    Sync-ScriptModule
    
.SYNOPSIS
    Uploads the script module into Octopus if it has changed

.DESCRIPTION
    This will only upload if the script module has changed
    
.PARAMETER Path
    The path to the script module to upload

.PARAMETER UseCache
    If Octopus Retrieval Operations should be cached, this is used when called from Invoke-TeamCityCiUpload where this function is called mulitple times
    When being run interactivley the use of the cache could cause unexpected behaviour

.INPUTS
    None. You cannot pipe objects to  Sync-ScriptModule.

.OUTPUTS
    None.
#>
function Sync-ScriptModule
{

    [CmdletBinding()]
    [OutputType("System.Collections.Hashtable")]
    param
    (

        [Parameter(Mandatory=$true)]
        [string] $Path,

        [Parameter(Mandatory=$false)]
        [switch] $UseCache

    )

    $octopusServerUri = $env:OctopusUri;
    $octopusApiKey    = $env:OctopusApiKey;

    $newVariableSet = Read-ScriptModuleVariableSet -Path $Path;

    $script = Get-Content -LiteralPath $Path -Raw;
    $moduleName = Get-VariableFromScriptText -Script $script -VariableName "ScriptModuleName";
    $moduleDescription = Get-VariableFromScriptText -Script $script -VariableName "ScriptModuleDescription";

    $result = @{ "UploadCount" = 0 };

    $scriptModuleVariableSets = Get-OctopusApiLibraryVariableSet -OctopusServerUri $octopusServerUri `
                                                                 -OctopusApiKey    $octopusApiKey `
                                                                 -ObjectId         "All" `
                                                                 -UseCache:$UseCache;
    $scriptModuleVariableSet  = $scriptModuleVariableSets | where-object { $_.Name -eq $moduleName };

    if( $null -eq $scriptModuleVariableSet )
    {
        Write-TeamCityBuildLogMessage "VariableSet for script module '$moduleName' does not exist. Creating";
        $scriptModuleVariableSet = New-OctopusApiLibraryVariableSet -OctopusServerUri $octopusServerUri `
                                                                    -OctopusApiKey    $octopusApiKey `
                                                                    -Object           $newVariableSet;
        $result.UploadCount++;
    }
    elseif( $scriptModuleVariableSet.Description -ne $moduleDescription )
    {
        Write-TeamCityBuildLogMessage "VariableSet for script module '$moduleName' has different metadata. Updating.";
        $scriptModuleVariableSet.Description = $moduleDescription;
        $response = Update-OctopusApiLibraryVariableSet -OctopusServerUri $octopusServerUri `
                                                        -OctopusApiKey    $octopusApiKey `
                                                        -ObjectId         $scriptModuleVariableSet.Id `
                                                        -Object           $scriptModuleVariableSet;
        $result.UploadCount++;
    }
    else
    {
        Write-TeamCityBuildLogMessage "VariableSet for script module '$moduleName' has not changed. Skipping.";
    }

    $scriptModule = Get-OctopusApiObject -OctopusServerUri $octopusServerUri `
                                         -OctopusApiKey    $octopusApiKey `
                                         -ObjectUri        $scriptModuleVariableSet.Links.Variables `
                                         -UseCache:$UseCache;

    if( $scriptModule.Variables.Count -eq 0 )
    {
        Write-TeamCityBuildLogMessage "Script module '$moduleName' does not exist. Creating";
        $scriptModule.Variables += Read-ScriptModule -Path $Path;
        $response = Update-OctopusApiObject -OctopusServerUri $octopusServerUri `
                                            -OctopusApiKey    $octopusApiKey `
                                            -ObjectUri        $scriptModuleVariableSet.Links.Variables `
                                            -Object           $scriptModule;
        $result.UploadCount++;
    }
    else
    {
        $moduleScript = Get-ScriptBodyFromScriptText -Script $script -Type "ScriptModule";
        if( $scriptModule.Variables[0].Value -ne $moduleScript )
        {
            Write-TeamCityBuildLogMessage "Script module '$moduleName' has changed. Updating";
            $scriptModule.Variables[0].Value = $moduleScript;
            $response = Update-OctopusApiObject -OctopusServerUri $octopusServerUri `
                                                -OctopusApiKey    $octopusApiKey `
                                                -ObjectUri        $scriptModuleVariableSet.Links.Variables `
                                                -Object           $scriptModule;
            $result.UploadCount++;
        }
        else
        {
            Write-TeamCityBuildLogMessage "Script module '$moduleName' has not changed. Skipping.";
        }
    }

    return $result;

}