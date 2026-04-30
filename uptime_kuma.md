using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace WebApp.Tests.Models
{
    [TestClass]
    public class ComplaintModelLanguageTests
    {
        private depComplaintModel _model;

        [TestInitialize]
        public void Setup()
        {
            _model = new depComplaintModel
            {
                // Setup bare minimum valid model state
                ComplaintCorrespondenceType = ComplaintCorrespondenceTypes.email,
                ComplaintRefNum = "12345678901",
                UserEmailAddress = "test@domain.com"
            };
        }

        [TestMethod]
        public void PreferredLanguage_IsRequired_When_PreferOtherLanguage_IsYes()
        {
            // Arrange
            _model.PreferOtherLanguage = "Yes";
            _model.PreferredLanguage = null; // Missing required field

            var context = new ValidationContext(_model, serviceProvider: null, items: null);
            var results = new List<ValidationResult>();

            // Act
            bool isValid = Validator.TryValidateObject(_model, context, results, true);

            // Assert
            Assert.IsFalse(isValid, "Model should be invalid when PreferredLanguage is missing but PreferOtherLanguage is 'Yes'");
            Assert.IsTrue(results.Exists(r => r.MemberNames.Contains("PreferredLanguage")), "Validation error should explicitly target PreferredLanguage.");
        }

        [TestMethod]
        public void PreferredLanguage_IsNotRequired_When_PreferOtherLanguage_IsNo()
        {
            // Arrange
            _model.PreferOtherLanguage = "No";
            _model.PreferredLanguage = null; 

            var context = new ValidationContext(_model, serviceProvider: null, items: null);
            var results = new List<ValidationResult>();

            // Act
            bool isValid = Validator.TryValidateObject(_model, context, results, true);

            // Assert
            // Note: If other base model properties are missing in this isolated test, isValid might be false for other reasons. 
            // The key is ensuring PreferredLanguage isn't in the error list.
            Assert.IsFalse(results.Exists(r => r.MemberNames.Contains("PreferredLanguage")), "PreferredLanguage should not throw a validation error when PreferOtherLanguage is 'No'");
        }

        [TestMethod]
        public void PreferredLanguage_Enforces_MaxLength()
        {
            // Arrange
            _model.PreferOtherLanguage = "Yes";
            _model.PreferredLanguage = new string('A', 51); // 51 characters

            var context = new ValidationContext(_model, serviceProvider: null, items: null);
            var results = new List<ValidationResult>();

            // Act
            bool isValid = Validator.TryValidateObject(_model, context, results, true);

            // Assert
            Assert.IsFalse(isValid);
            Assert.IsTrue(results.Exists(r => r.MemberNames.Contains("PreferredLanguage")));
        }
    }
}