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
    Get-OctopusApiActionTemplate.Tests

.SYNOPSIS
    Pester tests for Get-OctopusApiActionTemplate.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Get-OctopusApiActionTemplate" {

        Mock -CommandName "Invoke-WebRequest" `
             -MockWith { throw "Invoke-WebRequest should be mocked with a ParameterFilter!" };

        It "Should construct the uri based on the object type" {

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { ($Uri -eq "https://example.org/api/ActionTemplates/All") -and ($Method -eq "GET") } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Get-OctopusApiActionTemplate -OctopusServerUri "https://example.org" `
                                         -OctopusApiKey    "API-myapikey" `
                                         -ObjectId         "All";

            Assert-VerifiableMock;

        }

        It "Should use the appropriate http method based on the type of request" {

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { ($Uri -eq "https://example.org/api/ActionTemplates/100") -and ($Method -eq "GET") } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Get-OctopusApiActionTemplate -OctopusServerUri "https://example.org" `
                                         -OctopusApiKey    "API-myapikey" `
                                         -ObjectId         "100";

            Assert-VerifiableMock;

        }

        It "Should use the cache if 'UseCache' is specified" {

            $cache = @{};

            Mock -CommandName "Get-OctopusApiCache" `
                 -MockWith { return $cache; } `
                 -Verifiable;

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { ($Uri -eq "https://example.org/api/ActionTemplates/200") -and ($Method -eq "GET") } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Get-OctopusApiActionTemplate -OctopusServerUri "https://example.org" `
                                         -OctopusApiKey    "API-myapikey" `
                                         -ObjectId         "200" `
                                         -UseCache;

            Assert-VerifiableMock;

            $cache.Count | Should Be 1;
            Assert-MockCalled "Invoke-WebRequest" -Exactly 1 -Scope It;

        }

    }

}