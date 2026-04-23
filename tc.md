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





When developers talk about a TeamCity recipe, they are referring to a reusable template, script, or specific set of configurations used to automate a build, test, or deployment pipeline in JetBrains' TeamCity (a popular Continuous Integration/Continuous Deployment server).

While "recipe" isn't an official TeamCity terminology (TeamCity officially uses terms like Build Configurations, Templates, or Project Settings), the industry uses "recipe" to describe a proven, step-by-step blueprint for getting a specific CI/CD job done.

Here is a breakdown of what a TeamCity recipe typically includes:
1. Version Control System (VCS) Configuration

A recipe will define exactly how to pull code from source control. For instance, a recipe might dictate how to set up a VCS Root connecting TeamCity to a Subversion (SVN) repository, including the optimal polling intervals, how to handle checkout directories, or how to set up SVN commit hooks to trigger the build.
2. Build Steps (The "Instructions")

This is the core of the recipe—the sequential list of actions TeamCity needs to execute. A common recipe for a web application might look like this:

    Step 1: Restore dependencies (e.g., running dotnet restore or installing Python packages).

    Step 2: Compile the code (e.g., using MSBuild for a .NET framework project).

    Step 3: Run the automated testing suite (e.g., executing MSTest or PyTest).

    Step 4: Package the application for deployment.

3. Triggers and Dependencies

Recipes define when the build should happen. This could be triggered automatically upon every commit to the main branch, set on a nightly schedule, or configured to run only when another specific build finishes successfully.
4. Configuration as Code (Kotlin DSL)

Increasingly, when people ask for a "recipe," they are looking for a Kotlin DSL script. TeamCity allows you to export your entire build configuration as Kotlin code. This means instead of clicking through a UI to set up a pipeline, you can share a text-based "recipe" (a .kts file) that another developer can drop into their project to instantly replicate the pipeline.

Why teams use recipes:

    Standardization: If you have ten different microservices, using a standard recipe ensures they all build and test using the exact same steps.

    Troubleshooting: If a pipeline breaks, developers can look up "recipes" or "cookbooks" online to find the exact configuration settings needed to fix environments or parse metadata correctly.

    Speed: It saves DevOps engineers from reinventing the wheel every time a new project needs a CI/CD pipeline.