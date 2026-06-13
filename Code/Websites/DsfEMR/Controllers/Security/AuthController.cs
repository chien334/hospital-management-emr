using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Configuration;
using System.Linq;
using DsfEMR.Security;
using DsfEMR.ServerModel;

namespace DsfEMR.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IConfiguration _config;
        private readonly RbacDbContext _context;

        public AuthController(IConfiguration config, RbacDbContext context)
        {
            _config = config;
            _context = context;
        }

        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            if (request == null || string.IsNullOrEmpty(request.UserName) || string.IsNullOrEmpty(request.Password))
            {
                return BadRequest(new { message = "Username and password are required" });
            }

            // 1. Verify User Credentials in RbacDbContext
            var user = _context.Users.FirstOrDefault(u => u.UserName == request.UserName && u.Password == request.Password);
            if (user == null)
            {
                // Return unauthorized if user doesn't exist
                return Unauthorized(new { message = "Invalid username or password" });
            }

            // 2. Retrieve Roles associated with user
            var userRoles = _context.UserRoleMaps
                .Where(urm => urm.UserId == user.UserId && urm.IsActive == true)
                .Select(urm => urm.RoleId)
                .ToList();

            var primaryRoleId = userRoles.FirstOrDefault();

            // 3. Define JWT Claims based on user role and details
            var claims = new System.Collections.Generic.List<System.Security.Claims.Claim> {
                new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Name, user.UserName ?? string.Empty)
            };

            foreach (var roleId in userRoles)
            {
                claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Role, roleId.ToString()));
            }

            // 4. Create Signing Credentials using the Secret Key configured under JwtTokenConfig
            var jwtKey = _config["JwtTokenConfig:JwtKey"];
            if (string.IsNullOrEmpty(jwtKey) || jwtKey.Length < 16)
            {
                jwtKey = "Dsf_EMR@1234567890#Dsf_EMR@1234567890#";
            }
            
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            // 5. Generate the Signed Token using issuer and audience from config
            var token = new JwtSecurityToken(
                issuer: _config["JwtTokenConfig:JwtIssuer"] ?? "localhost",
                audience: _config["JwtTokenConfig:JwtAudience"] ?? "localhost",
                claims: claims,
                expires: DateTime.Now.AddMinutes(Convert.ToDouble(_config["JwtTokenConfig:JwtValidMinutes"] ?? "1440")),
                signingCredentials: creds
            );

            return Ok(new {
                token = new JwtSecurityTokenHandler().WriteToken(token),
                userName = user.UserName,
                userId = user.UserId,
                roleId = primaryRoleId
            });
        }
    }

    public class LoginRequest
    {
        public string UserName { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
