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
    Test-OctopusApiConnectivity.Tests

.SYNOPSIS
    Pester tests for Test-OctopusApiConnectivity.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Test-OctopusApiConnectivity" {

        It "Should make a test api call to the octopus server to see if it is responding" {

           Mock -CommandName "Invoke-OctopusApiOperation" `
                -MockWith { return @{ "Application" = "Octopus Deploy" }; };

           Test-OctopusApiConnectivity -OctopusServerUri "na" -OctopusApiKey "na";

           Assert-MockCalled Invoke-OctopusApiOperation -times 1;

        }

        It "Should throw an exception if test connection is requested and the test api call doesn't return an object" {

            Mock -CommandName "Invoke-OctopusApiOperation" `
                 -MockWith {};

            {
                Test-OctopusApiConnectivity -OctopusServerUri "na" -OctopusApiKey "na";
            } | Should Throw "Octopus Deploy Api is not responding correctly";

        }

    }

}
