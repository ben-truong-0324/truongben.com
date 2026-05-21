# Ben Truong — Personal Website

Welcome to my personal website and portfolio, built with [Hugo](https://gohugo.io/) and powered by the [HugoBlox framework](https://hugoblox.com/). This site showcases my work in machine learning, data science, fullstack development, and public-interest tech.

🚀 **Live site**: [https://truongben.com](https://truongben.com)  
📄 **Resume**: [View my resume](/files/resume.pdf)

---

## 💡 About the Site

- Showcase selected ML and NLP projects
- Serve as a technical blog & writing space
- Provide easy access to my resume, background, and social links

---

## 🛠️ Tech Stack

- **Static Site Generator:** Hugo (v0.126+)
- **Theme Engine:** HugoBlox (formerly Wowchemy)
- **Deployment:** GitHub Pages, Github Actions
- **Content Format:** Markdown + YAML frontmatter

---

## 🚧 Local Development

To build and preview locally:

```bash
git clone https://github.com/ben-truong-0324/truongben.com.git
cd truongben.com
hugo serve

chmod +x gitpush.sh
./gitpush.sh

docker compose up --build #build hugo for local dev with docker
localhost:1313

git add .
git commit -m "updated"
git push


using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.ComponentModel.DataAnnotations;
// using YourApp.Validation; 
namespace YourApp.Tests.Validation
{
    [TestClass]
    public class foosAttributeTests
    {
        private foosAttribute _attribute;
        private ValidationContext _validationContext;

        [TestInitialize]
        public void Setup()
        {
            _attribute = new foosAttribute();
            // ValidationContext requires a target object, a dummy object works perfectly
            _validationContext = new ValidationContext(new object());
        }

        [DataTestMethod]
        [DataRow(null)]
        [DataRow("")]
        [DataRow("   ")]
        [DataRow("This is a completely normal sentence without any links.")]
        [DataRow("I am learning about http requests.")] // Should pass (no ://)
        [DataRow("My domain does not start with www today.")] // Should pass (no .)
        public void IsValid_WhenInputIsValid_ReturnsSuccess(string input)
        {
            // Act
            var result = _attribute.GetValidationResult(input, _validationContext);

            // Assert
            Assert.AreEqual(ValidationResult.Success, result);
        }

        [DataTestMethod]
        [DataRow("Check out my site at http://example.com")]
        [DataRow("Secure link: https://google.com")]
        [DataRow("Just type www.bing.com in the browser")]
        [DataRow("It is HTTP://UPPERCASE.COM")] // Case-insensitivity check
        [DataRow("Look at HTTPS://TEST.ORG")] // Case-insensitivity check
        [DataRow("WWW.WEBSITE.COM")] // Case-insensitivity check
        public void IsValid_WhenInputContainsForbiddenStrings_ReturnsValidationError(string input)
        {
            // Act
            var result = _attribute.GetValidationResult(input, _validationContext);

            // Assert
            Assert.IsNotNull(result, "Expected a validation error, but got success.");
            Assert.AreEqual("Links and URLs are not allowed in this field.", result.ErrorMessage);
        }

        [TestMethod]
        public void IsValid_WithCustomErrorMessage_ReturnsCustomMessage()
        {
            // Arrange
            var customAttribute = new foosAttribute { ErrorMessage = "Custom error message." };
            var input = "Here is a link: https://test.com";

            // Act
            var result = customAttribute.GetValidationResult(input, _validationContext);

            // Assert
            Assert.IsNotNull(result);
            Assert.AreEqual("Custom error message.", result.ErrorMessage);
        }
    }
}