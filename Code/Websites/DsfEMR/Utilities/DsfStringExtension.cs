using System.Text.RegularExpressions;

namespace DsfEMR.Utilities
{
    public static class DsfStringExtension
    {
        // Returns boolean value (true/false) 
        public static bool Like(this string searchExpression, string searchKey)
        {
            return new Regex(@"\A" + new Regex(@"\.|\$|\^|\{|\[|\(|\||\)|\*|\+|\?|\\").Replace(searchKey, ch => @"\" + ch).Replace('_', '.').Replace("%", ".*") + @"\z", RegexOptions.Singleline).IsMatch(searchExpression);
        }
    }
}
