using Xunit;
using Microsoft.EntityFrameworkCore;
using DanpheEMR.DalLayer;

namespace DanpheEMR.Tests
{
    public class DbConnectionTests
    {
        [Fact]
        public void MasterDbContext_CanBeInitialized()
        {
            var optionsBuilder = new DbContextOptionsBuilder<MasterDbContext>();
            optionsBuilder.UseInMemoryDatabase(databaseName: "DanpheEMR_TestDb");

            using (var context = new MasterDbContext(optionsBuilder.Options))
            {
                Assert.NotNull(context);
            }
        }
    }
}
