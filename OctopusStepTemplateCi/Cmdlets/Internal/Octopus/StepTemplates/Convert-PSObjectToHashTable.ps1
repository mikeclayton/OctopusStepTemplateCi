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
    Convert-PSObjectToHashTable

.SYNOPSIS
    Converts a 'PSObject' which the parameters in a step template are into a hashtable
#>
function Convert-PSObjectToHashTable
{

    param
    (
        [Parameter(Mandatory=$false)]
        [PSCustomObject] $InputObject
    )
    
    if( $InputObject -eq $null )
    {
        return $null;
    }

    $output = @{};

    $members = Get-Member -InputObject $InputObject -MemberType *Property;
    foreach( $member in  $members)
    {
        $output[$member.Name] = $InputObject.($member.Name);
    }

    return $output;

}