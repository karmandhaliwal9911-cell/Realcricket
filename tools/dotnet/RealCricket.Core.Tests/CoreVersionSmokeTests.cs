using NUnit.Framework;

namespace RealCricket.Core.Tests
{
    /// <summary>
    /// Smoke test for milestone M0.1: proves the test host can reference and load
    /// RealCricket.Core. Detailed simulation tests arrive with M0.2.
    /// </summary>
    [TestFixture]
    public sealed class CoreVersionSmokeTests
    {
        [Test]
        public void CoreVersion_SemVer_IsTheExpectedMilestoneVersion()
        {
            Assert.That(CoreVersion.SemVer, Is.EqualTo("0.1.0-m0.1"));
        }
    }
}
