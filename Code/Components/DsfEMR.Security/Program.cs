using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;



namespace DsfEMR.Security
{
    class Program
    {
        static string connStr = ConfigurationManager.ConnectionStrings["RBAC_Connection"].ConnectionString;

        public static void Main(string[] args)
        {
            TestRoutes();
             
        }


        static void TestRoutes()
        {

            RbacDbContext dbContext = new RbacDbContext(connStr);

            List<DsfRoute> allUserRoutes = RBAC.GetRoutesForUser(11, true);

            //below works fine..
            //List<RbacUser> allUsers = dbContext.Users.ToList();
            //List<RbacApplication> applications = dbContext.Applications.ToList();
            //List<RbacPermission> permissions = dbContext.Permissions.ToList();
            //List<RbacRole> roles = dbContext.Roles.ToList();
            //List<DsfRoute> routes = dbContext.Routes.ToList();
            //List<UserRoleMap> userrolemaps = dbContext.UserRoleMaps.ToList();
            //List<RolePermissionMap> rolePermMaps = dbContext.RolePermissionMaps.ToList();
        }

        public static List<DsfRoute> GetAllRoutes()
        {
            List<DsfRoute> retList = new List<DsfRoute>();
            retList.Add(new DsfRoute() { DisplayName = "Dashboard", RouteId = 1, ParentRouteId = null });
            retList.Add(new DsfRoute() { DisplayName = "Appointment", RouteId = 1, ParentRouteId = null });
            retList.Add(new DsfRoute() { DisplayName = "Clinical", RouteId = 1, ParentRouteId = null });


            return retList;
        }

    }
}
