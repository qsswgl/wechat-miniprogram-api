using Microsoft.AspNetCore.Mvc;

namespace WeChatMiniProgramAPI.Controllers
{
    /// <summary>
    /// 测试控制器 - 用于验证API基本功能
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class TestController : ControllerBase
    {
        private readonly ILogger<TestController> _logger;

        public TestController(ILogger<TestController> logger)
        {
            _logger = logger;
        }

        /// <summary>
        /// 健康检查端点
        /// </summary>
        /// <returns>API状态信息</returns>
        /// <response code="200">API运行正常</response>
        [HttpGet("health")]
        [ProducesResponseType(200)]
        public ActionResult<object> GetHealth()
        {
            return Ok(new
            {
                Status = "Healthy",
                Timestamp = DateTime.UtcNow,
                Version = "1.0.0",
                Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Unknown"
            });
        }

        /// <summary>
        /// 获取服务器信息
        /// </summary>
        /// <returns>服务器基本信息</returns>
        /// <response code="200">成功返回服务器信息</response>
        [HttpGet("info")]
        [ProducesResponseType(200)]
        public ActionResult<object> GetInfo()
        {
            return Ok(new
            {
                ServerName = Environment.MachineName,
                OperatingSystem = Environment.OSVersion.ToString(),
                ProcessorCount = Environment.ProcessorCount,
                WorkingSet = Environment.WorkingSet,
                FrameworkVersion = Environment.Version.ToString(),
                CurrentTime = DateTime.Now,
                UtcTime = DateTime.UtcNow
            });
        }

        /// <summary>
        /// Echo测试 - 返回发送的消息
        /// </summary>
        /// <param name="message">要回显的消息</param>
        /// <returns>回显的消息</returns>
        /// <response code="200">成功回显消息</response>
        /// <response code="400">消息为空或无效</response>
        [HttpPost("echo")]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        public ActionResult<object> Echo([FromBody] string message)
        {
            if (string.IsNullOrWhiteSpace(message))
            {
                return BadRequest(new { Error = "消息不能为空" });
            }

            _logger.LogInformation("Echo request: {Message}", message);

            return Ok(new
            {
                Echo = message,
                Length = message.Length,
                Timestamp = DateTime.UtcNow,
                Reversed = new string(message.Reverse().ToArray())
            });
        }

        /// <summary>
        /// 获取随机数
        /// </summary>
        /// <param name="min">最小值 (默认: 1)</param>
        /// <param name="max">最大值 (默认: 100)</param>
        /// <returns>指定范围内的随机数</returns>
        /// <response code="200">成功返回随机数</response>
        /// <response code="400">参数范围无效</response>
        [HttpGet("random")]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        public ActionResult<object> GetRandom([FromQuery] int min = 1, [FromQuery] int max = 100)
        {
            if (min >= max)
            {
                return BadRequest(new { Error = "最小值必须小于最大值" });
            }

            var random = new Random();
            var number = random.Next(min, max + 1);

            return Ok(new
            {
                RandomNumber = number,
                Range = $"{min} - {max}",
                GeneratedAt = DateTime.UtcNow
            });
        }
    }
}