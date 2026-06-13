using Xunit;
using Microsoft.EntityFrameworkCore;
using DsfEMR.DalLayer;
using System;
using System.Security.Cryptography;
using System.Text;

namespace DsfEMR.Tests
{
    public class DbConnectionTests
    {
        private static string Salt = "Dsfsalt";

        public static string Decrypt(string cipherText)
        {
            byte[] data = Convert.FromBase64String(cipherText);
            using (MD5CryptoServiceProvider md5 = new MD5CryptoServiceProvider())
            {
                byte[] keys = md5.ComputeHash(UTF8Encoding.UTF8.GetBytes(Salt));
                using (TripleDESCryptoServiceProvider tripdes = new TripleDESCryptoServiceProvider() { Key = keys, Mode = CipherMode.ECB, Padding = PaddingMode.PKCS7 })
                {
                    ICryptoTransform transform = tripdes.CreateDecryptor();
                    byte[] results = transform.TransformFinalBlock(data, 0, data.Length);
                    return UTF8Encoding.UTF8.GetString(results);
                }
            }
        }

        public static string Encrypt(string plainText)
        {
            byte[] data = UTF8Encoding.UTF8.GetBytes(plainText);
            using (MD5CryptoServiceProvider md5 = new MD5CryptoServiceProvider())
            {
                byte[] keys = md5.ComputeHash(UTF8Encoding.UTF8.GetBytes(Salt));
                using (TripleDESCryptoServiceProvider tripdes = new TripleDESCryptoServiceProvider() { Key = keys, Mode = CipherMode.ECB, Padding = PaddingMode.PKCS7 })
                {
                    ICryptoTransform transform = tripdes.CreateEncryptor();
                    byte[] results = transform.TransformFinalBlock(data, 0, data.Length);
                    return Convert.ToBase64String(results, 0, results.Length);
                }
            }
        }

        [Fact]
        public void DecryptLicenseValues()
        {
            string startDecrypted = Decrypt("iC0fmfp/49Gy7FopJ3MLKA==");
            string endDecrypted = Decrypt("rJV7hCCRF+rCS+kb64edVA==");
            string noticeDecrypted = Decrypt("9g+iHewEXJE=");

            string newStartEncrypted = Encrypt("2026-01-01");
            string newEndEncrypted = Encrypt("2036-12-31");
            string newNoticeEncrypted = Encrypt("90");

            // Print using Xunit or console
            Console.WriteLine($"Original Start: {startDecrypted}");
            Console.WriteLine($"Original End: {endDecrypted}");
            Console.WriteLine($"Original Notice: {noticeDecrypted}");
            Console.WriteLine($"New Start Encrypted (2026-01-01): {newStartEncrypted}");
            Console.WriteLine($"New End Encrypted (2036-12-31): {newEndEncrypted}");
            Console.WriteLine($"New Notice Encrypted (90): {newNoticeEncrypted}");

            Assert.NotNull(startDecrypted);
        }

        [Fact]
        public void MasterDbContext_CanBeInitialized()
        {
            var optionsBuilder = new DbContextOptionsBuilder<MasterDbContext>();
            optionsBuilder.UseInMemoryDatabase(databaseName: "DsfEMR_TestDb");

            using (var context = new MasterDbContext(optionsBuilder.Options))
            {
                Assert.NotNull(context);
            }
        }
    }
}
