To implement this "Until filled" behavior for job postings, we need to intercept the dates at three points in AddUpdPostedJob.aspx.cs:

    When loading the form for a new job (setting the default).

    When parsing the database value to display on the UI.

    When saving the UI value back to the database.

Since ASP.NET Web Forms code-behind files can be tricky to unit test directly due to Page lifecycle dependencies, the cleanest approach is to extract the date translation logic into a separate static helper class. This keeps your code-behind clean and makes your test suite fast and isolated.

Here is the implementation breakdown.
1. Create a Helper Class

Add this utility class anywhere in your BARJobMain namespace (e.g., in the App_Code folder or directly above the AddPostedJob class) to handle the conversions.
C#

using System;

namespace BARJobMain
{
    public static class JobDateHelper
    {
        // Translates DB format (YYYY-MM-DD) to UI display
        public static string FormatDateForDisplay(string dbDate)
        {
            if (string.IsNullOrWhiteSpace(dbDate) || dbDate.Length < 10) 
                return dbDate;

            if (int.TryParse(dbDate.Substring(0, 4), out int yyyy) && yyyy >= 2040)
            {
                return "Until filled";
            }
            
            int mm = Convert.ToInt32(dbDate.Substring(5, 2));
            int dd = Convert.ToInt32(dbDate.Substring(6, 2));
            return $"{mm:D2}/{dd:D2}/{yyyy}";
        }

        // Translates UI display back to DB format
        public static string FormatDateForDatabase(string uiDate)
        {
            if (uiDate.Trim().Equals("Until filled", StringComparison.OrdinalIgnoreCase))
            {
                return "01/01/2099";
            }
            return uiDate; // Assumes it's already a valid date string if not "Until filled"
        }
    }
}

2. Update AddUpdPostedJob.aspx.cs

Now, plug the helper into the three critical lifecycle steps in your code-behind.

Step A: Set the Default in Page_Load
Find the !IsPostBack block in Page_Load and update the datepicker0.Text initialization.
C#

// OLD:
// datepicker0.Text = DateTime.Now.ToString("MM/dd/yyyy");

// NEW:
datepicker0.Text = "Until filled"; 

Step B: Handle the Display in getPostedJob4Update
Replace the manual substring date parsing with the new helper.
C#

// OLD:
// int yyyy = Convert.ToInt32(ds.Tables[0].Rows[0]["finalfiledt"].ToString().Substring(0, 4));
// int mm = Convert.ToInt32(ds.Tables[0].Rows[0]["finalfiledt"].ToString().Substring(5, 2));
// int dd = Convert.ToInt32(ds.Tables[0].Rows[0]["finalfiledt"].ToString().Substring(6, 2));
// datepicker0.Text = mm + "/" + dd + "/" + yyyy;
// hdnFdate.Value = datepicker0.Text;

// NEW:
string rawDbDate = ds.Tables[0].Rows[0]["finalfiledt"].ToString();
datepicker0.Text = JobDateHelper.FormatDateForDisplay(rawDbDate);
hdnFdate.Value = datepicker0.Text;

Step C: Handle the Save in updateJobTable
Intercept the UI value and convert it before passing it into AddPostedJobs and UpdPostedJobs.
C#

protected void updateJobTable()
{
    // Convert the value just before saving
    string dbFilingDate = JobDateHelper.FormatDateForDatabase(datepicker0.Text);

    if (Session["PorcessAction"].ToString() == "AJ")
    {
        result = barjobs.AddPostedJobs(txtJobCntList.Text, ddlJobClass.Text, txtJobLink.Text,
            ddlCitynm.Text, ddlCountynm.Text,
            dbFilingDate, appName, dbName); // Use dbFilingDate here
    }
    else if (Session["PorcessAction"].ToString() == "UJ")
    {
        result = barjobs.UpdPostedJobs(hdnJobId.Value, hdnJobCnx.Value, txtJobCnt1.Text, ddlJobClass.Text,
            txtJobLink.Text, ddlCitynm.Text, ddlCountynm.Text,
            dbFilingDate, appName, dbName); // Use dbFilingDate here
    }
    // ... rest of method remains the same
}

3. MSTest Suite

By pulling the logic into a static helper, testing becomes straightforward. Here is an MSTest class you can drop into your testing project to guarantee the boundary logic holds up.
C#

using Microsoft.VisualStudio.TestTools.UnitTesting;
using BARJobMain;

namespace BARJobMain.Tests
{
    [TestClass]
    public class JobDateHelperTests
    {
        [TestMethod]
        public void FormatDateForDisplay_Year2040_ReturnsUntilFilled()
        {
            string dbDate = "2040-06-15 00:00:00";
            string result = JobDateHelper.FormatDateForDisplay(dbDate);
            Assert.AreEqual("Until filled", result);
        }

        [TestMethod]
        public void FormatDateForDisplay_Year2099_ReturnsUntilFilled()
        {
            string dbDate = "2099-01-01 00:00:00";
            string result = JobDateHelper.FormatDateForDisplay(dbDate);
            Assert.AreEqual("Until filled", result);
        }

        [TestMethod]
        public void FormatDateForDisplay_Year2039_ReturnsFormattedDate()
        {
            string dbDate = "2039-12-31 00:00:00";
            string result = JobDateHelper.FormatDateForDisplay(dbDate);
            Assert.AreEqual("12/31/2039", result);
        }

        [TestMethod]
        public void FormatDateForDatabase_UntilFilled_Returns2099()
        {
            string uiDate = "Until filled";
            string result = JobDateHelper.FormatDateForDatabase(uiDate);
            Assert.AreEqual("01/01/2099", result);
        }

        [TestMethod]
        public void FormatDateForDatabase_StandardDate_ReturnsUnchanged()
        {
            string uiDate = "05/10/2026";
            string result = JobDateHelper.FormatDateForDatabase(uiDate);
            Assert.AreEqual("05/10/2026", result);
        }
    }
}

4. Documentation & Version Control

Wiki / Project Documentation Update:

    Feature: Indefinite Job Postings ("Until filled")

    Overview: The system supports open-ended job postings without a hard final filing date.
    Behavior: > * UI Default: When adding a new job, the date field defaults to "Until filled".

        Database Storage: The system strictly requires a valid DATETIME. Indefinite postings are stored in the database as "01/01/2099".

        Data Retrieval: Any job with a finalfiledt year of 2040 or greater will automatically mask the explicit date and render as "Until filled" to the end user.

    Technical Implementation: Handled via the JobDateHelper class. Ensure any new bulk-imports or DB scripts adhere to the 2040+ rule for open-ended positions.