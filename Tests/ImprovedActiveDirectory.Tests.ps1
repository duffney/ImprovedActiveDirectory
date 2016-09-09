$ModuleManifestName = 'ImprovedActiveDirectory.psd1'
# f6497b70-2bfe-4a91-bd45-ccd2f2ba28fd - testing use of PLASTER predefined variables.
Import-Module $PSScriptRoot\..\$ModuleManifestName

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $PSScriptRoot\..\$ModuleManifestName
        $? | Should Be $true
    }
}

