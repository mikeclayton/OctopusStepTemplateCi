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

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "ConvertTo-PSSource" {

        # $null

        It "Should return the value when the InputObject is `$null" {
            $input    = $null;
            $expected = "`$null";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        # [bool]

        It "Should return the value when the InputObject is `$true" {
            $input    = $true;
            $expected = "`$true";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is `$false" {
            $input    = $false;
            $expected = "`$false";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        # [int]

        It "Should return the value when the InputObject is a positive integer" {
            $input    = 100;
            $expected = "100";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is a negative integer" {
            $input    = -100;
            $expected = "-100";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        # [string]

        It "Should return the value when the InputObject is an empty string" {
            $input    = [string]::Empty;
            $expected = "`"`"";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is a simple string" {
            $input    = "my simple string";
            $expected = "`"my simple string`"";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is a string with apostrophes" {
            $input    = "my string with 'apostrophes'";
            $expected = "`"my string with 'apostrophes'`"";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is a string with special characters" {
            $input    = "my \ `"string`" with `r`n special `t characters";
            $expected = "`"my \ ```"string```" with ``r``n special ``t characters`"";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is a string with whitespace between curly brackets" {
            $input    = "{    }";
            $expected = "`"{    }`"";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is a string resembling the json escape sequence for an apostrophe" {
            $input    = "\u0027";
            $expected = "`"\u0027`"";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        # [hashtable]

        It "Should return the value when the InputObject is an empty hashtable" {
            $input    = @{};
            $expected = "@{}";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is a hashtable with a single item" {
            $input    = @{ "myInt" = 100 };
            $expected = @'
@{
    "myInt" = 100
}
'@
            # normalize line breaks in "$expected" here-string in case they get mangled on git commit
            if( $expected.IndexOf("`r`n") -eq -1 ) { $expected = $expected.Replace("`n", "`r`n"); }
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is a hashtable with multiple items" {
            $input    = @{
                "myNull"     = $null
                "myInt"      = 100
                "myString"   = "text"
                "myArray"    = @( $null, 200, "string", [PSCustomObject] [ordered] @{ "nestedProperty" = "nestedValue" } )
                "myPsObject" = [PSCustomObject] [ordered] @{ "childProperty" = "childValue" }
            };
            $expected = @'
@{
    "myArray" = @(
        $null,
        200,
        "string",
        (new-object PSCustomObject -Property ([ordered] @{
            "nestedProperty" = "nestedValue"
        }))
    )
    "myInt" = 100
    "myNull" = $null
    "myPsObject" = new-object PSCustomObject -Property ([ordered] @{
        "childProperty" = "childValue"
    })
    "myString" = "text"
}
'@
            # normalize line breaks in "$expected" here-string in case they get mangled on git commit
            if( $expected.IndexOf("`r`n") -eq -1 ) { $expected = $expected.Replace("`n", "`r`n"); }
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        # [ordered]

        It "Should return the value when the InputObject is an empty ordered dictionary" {
            $input    = [ordered] @{};
            $expected = "[ordered] @{}";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is an ordered dictionary with a single item" {
            $input    = [ordered] @{ "myInt" = 100 };
            $expected = @'
[ordered] @{
    "myInt" = 100
}
'@
            # normalize line breaks in "$expected" here-string in case they get mangled on git commit
            if( $expected.IndexOf("`r`n") -eq -1 ) { $expected = $expected.Replace("`n", "`r`n"); }
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is an ordered dictionary with multiple items" {
            $input    = [ordered] @{
                "myNull"     = $null
                "myInt"      = 100
                "myString"   = "text"
                "myArray"    = @( $null, 200, "string", [PSCustomObject] [ordered] @{ "nestedProperty" = "nestedValue" } )
                "myPsObject" = [PSCustomObject] [ordered] @{ "childProperty" = "childValue" }
            };
            $expected = @'
[ordered] @{
    "myNull" = $null
    "myInt" = 100
    "myString" = "text"
    "myArray" = @(
        $null,
        200,
        "string",
        (new-object PSCustomObject -Property ([ordered] @{
            "nestedProperty" = "nestedValue"
        }))
    )
    "myPsObject" = new-object PSCustomObject -Property ([ordered] @{
        "childProperty" = "childValue"
    })
}
'@
            # normalize line breaks in "$expected" here-string in case they get mangled on git commit
            if( $expected.IndexOf("`r`n") -eq -1 ) { $expected = $expected.Replace("`n", "`r`n"); }
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        # pscustomobject

        It "Should return the value when the InputObject is an empty PSCustomObject" {
            $input    = new-object PSCustomObject;
            $expected = "new-object PSCustomObject";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is a populated PSCustomObject" {
            $input    = [PSCustomObject] [ordered] @{
                "myNull"     = $null
                "myInt"      = 100
                "myString"   = "text"
                "myArray"    = @( $null, 200, "string", [PSCustomObject] [ordered] @{ "nestedProperty" = "nestedValue" } )
                "myPsObject" = [PSCustomObject] [ordered] @{ "childProperty" = "childValue" }
            };
            $expected = @'
new-object PSCustomObject -Property ([ordered] @{
    "myNull" = $null
    "myInt" = 100
    "myString" = "text"
    "myArray" = @(
        $null,
        200,
        "string",
        (new-object PSCustomObject -Property ([ordered] @{
            "nestedProperty" = "nestedValue"
        }))
    )
    "myPsObject" = new-object PSCustomObject -Property ([ordered] @{
        "childProperty" = "childValue"
    })
})
'@
            # normalize line breaks in "$expected" here-string in case they get mangled on git commit
            if( $expected.IndexOf("`r`n") -eq -1 ) { $expected = $expected.Replace("`n", "`r`n"); }
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        # array

        It "Should return the value when the InputObject is an empty array" {
            $input    = @();
            $expected = "@()";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is an array with a single item" {
            $input    = @( 100 );
            $expected = "@(`r`n    100`r`n)";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is an array with multiple items" {
            $input    = @( $null, 100, "my string" );
            $expected = "@(`r`n    `$null,`r`n    100,`r`n    `"my string`"`r`n)";
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is an array of hashtables" {
            $input    = @( @{ "aaa" = "bbb" }, @{ "ccc" = "ddd" } );
            $expected = @'
@(
    @{
        "aaa" = "bbb"
    },
    @{
        "ccc" = "ddd"
    }
)
'@;
            # normalize line breaks in "$expected" here-string in case they get mangled on git commit
            if( $expected.IndexOf("`r`n") -eq -1 ) { $expected = $expected.Replace("`n", "`r`n"); }
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

        It "Should return the value when the InputObject is an array of PSCustomObjects" {
            $input    = @(
                (new-object PSCustomObject -Property @{ "aaa" = "bbb" }),
                (new-object PSCustomObject -Property @{ "ccc" = "ddd" })
            );
            $expected = @'
@(
    (new-object PSCustomObject -Property ([ordered] @{
        "aaa" = "bbb"
    })),
    (new-object PSCustomObject -Property ([ordered] @{
        "ccc" = "ddd"
    }))
)
'@;
            # normalize line breaks in "$expected" here-string in case they get mangled on git commit
            if( $expected.IndexOf("`r`n") -eq -1 ) { $expected = $expected.Replace("`n", "`r`n"); }
            $actual = ConvertTo-PSSource -InputObject $input;
            $actual | Should Be $expected;
        }

    }

}
