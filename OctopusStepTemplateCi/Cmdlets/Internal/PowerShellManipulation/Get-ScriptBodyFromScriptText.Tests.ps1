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
    Get-ScriptBodyFromScriptText.Tests

.SYNOPSIS
    Pester tests for Get-ScriptBodyFromScriptText.
#>

Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Get-VariableStatementFromScriptText.ps1"

Describe "Get-ScriptBodyFromScriptText" {

    Context "Script module" {

        It "Removes the ScriptModuleName, ScriptModuleDescription variables from the script" {         
            $script = @'
function test
{
    $ScriptModuleName = "name"
    $ScriptModuleDescription = "description"
}
'@
            $expected = @'
function test
{
    
    
}
'@
            $result = Get-ScriptBodyFromScriptText -Script $script -Type "ScriptModule";
            $result | Should Be $expected;
        } 

    }
    
    Context "Step template" {

        It "Removes the StepTemplateName, StepTemplateDescription, StepTemplateParameters variables from the script" {         
        $script = @'
function test
{
    $StepTemplateName = "name"
    $StepTemplateDescription = "description"
    $StepTemplateParameters = "parameters"
}
'@
            $expected = @'
function test
{
    
    
    
}
'@
            $result = Get-ScriptBodyFromScriptText -Script $script -Type "StepTemplate";
            $result | Should Be $expected;
        } 

    }

}