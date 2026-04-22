Connecting the Plumbing (VCS Root)

First, you’ll create a VCS Root in TeamCity to tell it where your SVN repository lives.

    Type: Subversion

    URL: Your SVN repo path (e.g., https://svn.yourserver.com/project/trunk)

    Authentication: Usually "Password" or "Private Key" if you’re fancy.

    Checkout Mode: "Automatically on agent" (This is the fastest).

2. Automatic Semantic Versioning in SVN

Since SVN doesn't have "tags" in the same way Git does (it just treats them as folders), the best way to handle SemVer in TeamCity with SVN is using the Build Number Format.

Go to General Settings and set the Build number format to:
1.0.0.%build.vcs.number%

    Major (1): You change this manually when you break things.

    Minor (0): You change this manually for new features.

    Patch (0): You change this for bug fixes.

    Revision (%build.vcs.number%): This pulls the actual SVN revision number. This is great because if Build #42 was made from SVN Revision 1500, the version of your DLL will literally be 1.0.0.1500. It’s perfect for traceability.

3. The CI Build Steps

You’ll add these three steps to your Build Configuration.
Step 1: Clean

    Runner: .NET

    Command: clean

    Projects: YourSolution.sln

Step 2: Build

    Runner: .NET

    Command: build

    Configuration: Release

    Arguments: /p:Version=%system.build.number%

        This "injects" the TeamCity build number directly into your DLL properties.

Step 3: Test

    Runner: .NET

    Command: test

    Projects: **/*.Tests.csproj

    Arguments: --no-build

4. Handling the Libraries (Artifacts)

Since you have a Core library, a Markdown library, and a UI library, you need to decide how the Web App gets them. In TeamCity, you use Artifacts.

    In your General Settings, set Artifact paths:
    **/bin/Release/*.nupkg => packages

    Now, every time a build finishes, TeamCity stores the compiled library in its internal storage.

    Your Web App build can then use an Artifact Dependency to "grab" the latest successful build of the libraries.