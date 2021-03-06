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
    Invoke-TeamCityCiUpload.Tests

.SYNOPSIS
    Pester tests for Invoke-TeamCityCiUpload
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Invoke-TeamCityCiUpload" {

        Mock Write-TeamCityBuildLogMessage {};
        Mock Sync-ScriptModule { @{UploadCount = 0} };
        Mock Sync-StepTemplate { @{UploadCount = 0} };
        Mock Test-OctopusApiConnectivity {};
        Mock Reset-OctopusApiCache {};
        Mock Invoke-OctopusScriptTestSuite { @{ Passed = 1; Failed = 0; Success = $true } };

        Context "Parameter validation" {    
            BeforeEach { Push-Location "TestDrive:\" }
            AfterEach { Pop-Location }
            It "Should default the build directory to .BuildOutput" {            
                Invoke-TeamCityCiUpload;
                "TestDrive:\.BuildOutput" | Should Exist;
            } 
        }

        It "Should handle exceptions" {
            Mock Test-OctopusApiConnectivity { throw "bang" }
            {
                Invoke-TeamCityCiUpload -Path "TestDrive:\" -BuildDirectory "TestDrive:\.BuildOutput" -UploadIfSuccessful;
            } | Should Throw;
        }

        It "Should test octopus's connectivity before beginning" {
            Mock Test-OctopusApiConnectivity {} -Verifiable;
            Invoke-TeamCityCiUpload -Path "TestDrive:\" -BuildDirectory "TestDrive:\.BuildOutput" -UploadIfSuccessful;
            Assert-VerifiableMock;
        }

        It "Should reset the build directory before beginning" {
            Mock Reset-BuildOutputDirectory {} -Verifiable;
            Invoke-TeamCityCiUpload -Path "TestDrive:\" -BuildDirectory "TestDrive:\.BuildOutput";
            Assert-VerifiableMock;
        }

        It "Should reset the cache before beginning" {
            Mock Reset-OctopusApiCache {} -Verifiable;
            Invoke-TeamCityCiUpload -Path "TestDrive:\" -BuildDirectory "TestDrive:\.BuildOutput";
            Assert-VerifiableMock;
        }

        It "Should process the entire folder at once in batch mode" {
            Invoke-TeamCityCiUpload -Path "TestDrive:\" -BuildDirectory "TestDrive:\.BuildOutput" -ProcessingMode Batch;
            Assert-MockCalled Invoke-OctopusScriptTestSuite -Exactly 1 -Scope It;
        }

        It "Should process the each item within the folder in individual mode" {
            New-StepTemplate -Name "test" -Path "TestDrive:\" ;
            New-StepTemplate -Name "test1" -Path "TestDrive:\";
            New-StepTemplate -Name "test2" -Path "TestDrive:\";
            Invoke-TeamCityCiUpload -Path "TestDrive:\" -BuildDirectory "TestDrive:\.BuildOutput" -ProcessingMode Individual;
            Assert-MockCalled Invoke-OctopusScriptTestSuite -Exactly 3 -Scope It;
        }

        It "Should handle only a single file being returned from Get-ChildItem in individual mode" {
            New-StepTemplate -Name "test3" -Path "TestDrive:\";
            Mock Get-ChildItem { @{Name = "test3.steptemplate.ps1"; FullName = "TestDrive:\test3.steptemplate.ps1"; BaseName = "test3.steptemplate" } } -ParameterFilter { $Filter -eq "*.steptemplate.ps1" };
            New-ScriptModule -Name "test4" -Path "TestDrive:\";
            Mock Get-ChildItem { @{Name = "test4.scriptmodule.ps1"; FullName = "TestDrive:\test4.scriptmodule.ps1"; BaseName = "test4.steptemplate"  } } -ParameterFilter { $Filter -eq "*.scriptmodule.ps1" };
            {
                Invoke-TeamCityCiUpload -Path "TestDrive:\" -BuildDirectory "TestDrive:\.BuildOutput" -ProcessingMode Individual
            } | Should Not Throw;
        }

        Context "UploadIfSuccessful" {

            It "Should sync the step templates" {
               New-StepTemplate -Name "upload" -Path "TestDrive:\";
               Mock Sync-StepTemplate {  @{UploadCount = 1}  } -ParameterFilter { $Path -like '*\upload.steptemplate.ps1' } -Verifiable;
               Invoke-TeamCityCiUpload -Path "TestDrive:\" -BuildDirectory "TestDrive:\.BuildOutput" -UploadIfSuccessful;
               Assert-VerifiableMock;
            }

            It "Should sync the script modules" {
               New-ScriptModule -Name "upload" -Path "TestDrive:\" ;
               Mock Sync-ScriptModule {  @{UploadCount = 1}  } -ParameterFilter { $Path -like '*\upload.scriptmodule.ps1' } -Verifiable;
               Invoke-TeamCityCiUpload -Path "TestDrive:\" -BuildDirectory "TestDrive:\.BuildOutput" -UploadIfSuccessful;
               Assert-VerifiableMock;
            }

        }

    }

}