# NuGet with File-Share and TeamCity 

## 1. Development & Versioning Strategy

Nupkg's versioning scheme will use Semantic Versioning controlled by the dev, and a 4th-quartile SVN revision number provided by TeamCity.

**Format:** `Major.Minor.Patch.Revision` (e.g., `1.0.0.200`)

Old workflow: webapp ticket, webapp branch and CI/CD

New workflow if using nupkg: nupkg ticket, nupkg branch and CI/CD, webapp ticket, webapp branch and CI/CD

- **Ticket Creation:** A ticket is created for the library feature/patch.

- **Branching:** The developer creates a branch for the ticket (e.g., `branches/TICKET-BAR_000`).

- **Updating the Version Prefix:** In the library's `.csproj`, the developer manually bumps the SemVer using the `<VersionPrefix>` tag. Do not use `<Version>` (see below)

```xml
<PropertyGroup>
  <VersionPrefix>1.0.0</VersionPrefix> 
</PropertyGroup>
```


## 2. TeamCity Build & Pack (Staging to temp/)

When the library code is pushed, TeamCity intercepts the merge and starts the build. TC applies the 4th quartile, build with debug config, test, and pack with output dir to be shared drive at temp \\barsvn.dca.cagov\temp\

TeamCity Build Step Configuration:

    Command: pack

    Projects: LibraryProj/LibraryProj.csproj

    Output directory: \\barsvn.dca.cagov\temp\

    Command line parameters: ```text
    /p:Version=$(VersionPrefix).%build.counter%

    *(This forces MSBuild to combine the `1.2.0` from `.csproj` with the TeamCity SVN revision number resulting in `1.2.0.455`)*.

=> We use \\barsvn.dca.cagov\temp\ as Staging for nupkg

## 3. Automated Validation & Promotion (to BARNuget/)

Prod projects must not consume nupkg from temp/. We first validate Staging nupkg with a secondary TeamCity step or in our own local dev. We validate the package can be consumed without errors or warnings. 
This can be done by having webapp projects and test projects consume the ST nupkg, then check for 200 status or smoketest.

Only then we run the next step to robocopy to BARNuget and wipe the nupkg in temp/
PowerShell

```xml

$TempPath = "\\barsvn.dca.cagov\temp\"
$PermPath = "\\barsvn.dca.cagov\barnuget\"
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

Once the package is in BARNuget/, the library ticket is closed. A new ticket is created for the consuming application(s) to implement the update.

1. Configure the consuming app's nuget.config
To ensure the consumer apps can find the file share, configure the local nuget.config (at root, same level as Source and Documentation) to point to the UNC path:
XML

```xml
<configuration>
  <packageSources>
    <add key="InternalSharedDrive" value="\\your-server\shared-drive\teamnuget" />
  </packageSources>
</configuration>
```

2. Developer Updates the Application
The developer checks out the consuming app, runs dotnet add package MyLibrary -v 1.2.0.455 or update PackageReference in csproj, integrates the new library code, and pushes the app to its own CI pipeline. Now we utilize the same workflow for webapp CI/CD with CR then ST, UAT, RC/Prod.

## 5. Verification Testing

To ensure the build server actually pulls the correct version (and doesn't accidentally resolve to a cached different version in global .nuget cache in TeamCity server), the consuming application must contain a unit test verifying the referenced assembly.

MSTest Verification Example:
In the consuming application's MSTest project, use reflection to verify the exact version loaded into the app domain.
C#

```xml
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Reflection;
using MySNugetPkgLibrary; // The NuGet package being consumed

namespace ConsumingApp.Tests
{
    [TestClass]
    public class PackageVersionTests
    {
        [TestMethod]
        public void Verify_CorrectLibraryVersion_IsReferenced()
        {
            // MANUALLY SET THIS
            string expectedVersion = "1.2.0.455";
            
            Assembly libraryAssembly = typeof(SomeClassInYourLibrary).Assembly;
            string actualVersion = libraryAssembly.GetName().Version.ToString();

            Assert.AreEqual(expectedVersion, actualVersion, 
                $"The application is referencing version {actualVersion} of the library, but {expectedVersion} is required by this ticket.");
        }
    }
}
```

Workflow Summary Checklist

    [ ] 1. Library Ticket: Developer updates library code and test, bump <VersionPrefix>, update readme, changelog, release...

    [ ] 2. Library Pipeline: TeamCity packs the .nupkg with %build.counter% to temp/.

    [ ] 3. Promotion: CI script or manually validate the package, moves it to barnuget/, and empty out temp/.

    [ ] 4. App Ticket: Developer updates the consuming app to reference the new version with applicable changes in code and test; update readme, changelog, release

    [ ] 4.5. MSTest Validation: Test suite verifies the exact 4-part assembly version is compiled into the consuming application.

    [ ] 5. Regular CI/CD: app ticket branch then goes through  code review, ST, UAT, RC/Prod.