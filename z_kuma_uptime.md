# Standard Work: File-Share NuGet Publishing & Consumption

## 1. Development & Versioning Strategy

All library work is driven by tickets. To maintain traceable artifacts, the versioning scheme combines Semantic Versioning (SemVer) controlled by the developer, and a 4th-quartile revision number controlled by TeamCity.

**Format:** `Major.Minor.Patch.Revision` (e.g., `1.2.0.455`)

- **Ticket Creation:** A ticket is created for the library feature/fix.

- **Branching:** The developer creates a branch for the ticket (e.g., `feature/TICKET-123`).

- **Updating the Version Prefix:** In the library's `.csproj`, the developer manually bumps the SemVer using the `<VersionPrefix>` tag. Do not use `<Version>`.

```xml
<PropertyGroup>
  <VersionPrefix>1.2.0</VersionPrefix> 
</PropertyGroup>
```

## 2. TeamCity Build & Pack (Staging to temp/)

When the library code is pushed, TeamCity intercepts the build, applies the 4th quartile, and pushes the artifact to a temporary staging drive.

TeamCity Build Step Configuration (.NET CLI):

    Command: pack

    Projects: path/to/Library.csproj

    Output directory: \\your-server\shared-drive\temp

    Command line parameters: ```text
    /p:Version=$(VersionPrefix).%build.counter%

    *(This forces MSBuild to combine the `1.2.0` from the `.csproj` with the TeamCity build counter, resulting in `1.2.0.455`)*.

## 3. Automated Validation & Promotion (to teamnuget/)

Packages must not be consumed directly from temp/. A downstream script or secondary TeamCity step is responsible for validating the package and moving it to the permanent directory.

Standard Promotion Script (PowerShell):
This script runs as the final step of the pipeline. It checks if the package exists, verifies it isn't corrupted, moves it to the permanent store, and wipes the temp/ directory.
PowerShell

```xml

$TempPath = "\\your-server\shared-drive\temp"
$PermPath = "\\your-server\shared-drive\teamnuget"
$Packages = Get-ChildItem -Path $TempPath -Filter *.nupkg

foreach ($Pkg in $Packages) {
    # 1. Verification (Check if file is structurally sound by unzipping its manifest)
    $IsValid = Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::OpenRead($Pkg.FullName).Entries | Where-Object Name -eq "$($Pkg.BaseName).nuspec"
    
    if ($IsValid) {
        # 2. Promotion
        Copy-Item -Path $Pkg.FullName -Destination $PermPath -Force
        Write-Host "Promoted $($Pkg.Name) to teamnuget"
    } else {
        Write-Error "Package $($Pkg.Name) failed validation."
        exit 1
    }
}

    # 3. Cleanup
Remove-Item -Path "$TempPath\*" -Include *.nupkg -Force

```

## 4. Consuming the Package

Once the package is in teamnuget/, the library ticket is closed. A new ticket is generated for the consuming application(s) to implement the update.

1. Configure the Consuming App's nuget.config
To ensure the consumer apps can find the file share, configure the local nuget.config to point to the UNC path:
XML

```xml
<configuration>
  <packageSources>
    <add key="InternalSharedDrive" value="\\your-server\shared-drive\teamnuget" />
  </packageSources>
</configuration>
```

2. Developer Updates the Application
The developer checks out the consuming app, runs dotnet add package MyLibrary -v 1.2.0.455, integrates the new library code, and pushes the app to its own CI pipeline.

## 5. Verification Testing

To enforce compliance and ensure the build server actually pulls the correct 4th-quartile version (and doesn't accidentally load a cached, older DLL), the consuming application must contain a unit test verifying the referenced assembly.

MSTest Verification Example:
In the consuming application's MSTest project, use reflection to verify the exact version loaded into the app domain.
C#

```xml
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Reflection;
using MySharedLibrary; // The NuGet package being consumed

namespace ConsumingApp.Tests
{
    [TestClass]
    public class PackageVersionTests
    {
        [TestMethod]
        public void Verify_CorrectLibraryVersion_IsReferenced()
        {
            // Arrange
            string expectedVersion = "1.2.0.455";
            
            // Act
            // Grab any known type from your NuGet package to inspect its assembly
            Assembly libraryAssembly = typeof(SomeClassInYourLibrary).Assembly;
            string actualVersion = libraryAssembly.GetName().Version.ToString();

            // Assert
            Assert.AreEqual(expectedVersion, actualVersion, 
                $"The application is referencing version {actualVersion} of the library, but {expectedVersion} is required by this ticket.");
        }
    }
}
```

Workflow Summary Checklist

    [ ] Library Ticket: Developer updates code and bumps <VersionPrefix>.

    [ ] Library Pipeline: TeamCity packs the .nupkg with %build.counter% to temp/.

    [ ] Promotion: CI script validates the package, moves it to teamnuget/, and empties temp/.

    [ ] App Ticket: Developer updates the consuming app to reference the new version.

    [ ] MSTest Validation: Test suite verifies the exact 4-part assembly version is compiled into the consuming application.