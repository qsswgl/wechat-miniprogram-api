using Microsoft.AspNetCore.Mvc;

namespace WeChatMiniProgramAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HealthController : ControllerBase
    {
        /// <summary>
        /// 健康检查端点
        /// </summary>
        /// <returns>服务状态信息</returns>
        [HttpGet]
        public IActionResult Get()
        {
            return Ok(new
            {
                Status = "Healthy",
                Timestamp = DateTime.UtcNow,
                Version = "1.0.0",
                Service = "WeChat Mini Program API"
            });
        }

        /// <summary>
        /// 获取服务信息
        /// </summary>
        /// <returns>详细的服务信息</returns>
        [HttpGet("info")]
        public IActionResult GetInfo()
        {
            return Ok(new
            {
                ApiName = "WeChat Mini Program API",
                Version = "1.0.0",
                Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Unknown",
                MachineName = Environment.MachineName,
                Platform = Environment.OSVersion.Platform.ToString(),
                DotNetVersion = Environment.Version.ToString(),
                StartTime = DateTime.UtcNow.AddHours(-1), // 模拟启动时间
                Endpoints = new[]
                {
                    "/api/health",
                    "/api/health/info",
                    "/api/wechat/CreateMiniProgramCode"
                }
            });
        }
    }
}