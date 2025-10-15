using Microsoft.AspNetCore.Cors;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using WeChatMiniProgramAPI.Services;

namespace WeChatMiniProgramAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class WeChatController : ControllerBase
    {
        private readonly IDatabaseService _databaseService;
        private readonly IWeChatService _weChatService;
        private readonly IWebHostEnvironment _webHostEnvironment;
        private readonly ILogger<WeChatController> _logger;

        public WeChatController(
            IDatabaseService databaseService, 
            IWeChatService weChatService,
            IWebHostEnvironment webHostEnvironment,
            ILogger<WeChatController> logger)
        {
            _databaseService = databaseService;
            _weChatService = weChatService;
            _webHostEnvironment = webHostEnvironment;
            _logger = logger;
        }

        /// <summary>
        /// 生成微信小程序二维码
        /// </summary>
        /// <param name="dbName">数据库名称</param>
        /// <param name="goodsId">商品ID</param>
        /// <param name="pagePath">小程序页面路径</param>
        /// <param name="accessToken">微信访问令牌</param>
        /// <returns>返回生成的二维码图片或JSON结果</returns>
        [EnableCors("myCors")]
        [HttpGet]
        [Route("CreateMiniProgramCode")]
        [ProducesResponseType(200, Type = typeof(string))]
        [ProducesResponseType(400, Type = typeof(string))]
        [ProducesResponseType(500, Type = typeof(string))]
        public async Task<ContentResult> CreateMiniProgramCode(
            [FromQuery] string dbName,
            [FromQuery] string goodsId, 
            [FromQuery] string pagePath,
            [FromQuery] string accessToken)
        {
            try
            {
                _logger.LogInformation("开始处理微信小程序二维码生成请求");

                // 1. 获取请求参数
                if (string.IsNullOrEmpty(dbName)) dbName = Request.Query["DBName"].ToString();
                if (string.IsNullOrEmpty(goodsId)) goodsId = Request.Query["goodsId"].ToString();
                if (string.IsNullOrEmpty(pagePath)) pagePath = Request.Query["pagePath"].ToString();
                if (string.IsNullOrEmpty(accessToken)) accessToken = Request.Query["accessToken"].ToString();


                _logger.LogInformation("请求参数 - DBName: {DBName}, goodsId: {GoodsId}, pagePath: {PagePath}",
                    dbName, goodsId, pagePath);

                if (string.IsNullOrEmpty(dbName) || string.IsNullOrEmpty(goodsId) || string.IsNullOrEmpty(pagePath))
                {
                    return new ContentResult
                    {
                        Content = JsonSerializer.Serialize(new { Message = "缺少必要参数：DBName、goodsId或pagePath" }),
                        ContentType = "application/json;charset=utf-8"
                    };
                }

                // 3. 调用微信小程序生成二维码API
                string scene = $"goodsId={goodsId}";
                byte[]? imageBytes = await _weChatService.GenerateQrCodeAsync(accessToken, scene, pagePath, 430);

                if (imageBytes == null)
                {
                    _logger.LogError("调用微信API生成二维码失败");
                    return new ContentResult
                    {
                        Content = JsonSerializer.Serialize(new { Message = "调用微信API生成二维码失败" }),
                        ContentType = "application/json;charset=utf-8"
                    };
                }

                // 4. 保存图片到uploadall文件夹
                string webPath = _webHostEnvironment.WebRootPath ?? _webHostEnvironment.ContentRootPath;
                string folderPath = Path.Combine(webPath, "uploadall");

                // 确保文件夹存在
                if (!Directory.Exists(folderPath))
                {
                    Directory.CreateDirectory(folderPath);
                    _logger.LogInformation("创建文件夹: {FolderPath}", folderPath);
                }

                // 生成唯一文件名
                string fileName = $"qrcode_{DateTime.Now:yyyyMMddHHmmss}_{new Random().Next(10000, 99999)}.png";
                string filePath = Path.Combine(folderPath, fileName);

                // 保存图片文件
                await System.IO.File.WriteAllBytesAsync(filePath, imageBytes);
                _logger.LogInformation("二维码图片已保存: {FilePath}", filePath);

                // 5. 构建图片URL
                string host = HttpContext?.Request?.Host.Value ?? "tx.qsgl.net:8092";
                string scheme = HttpContext?.Request?.Scheme ?? "https";
                
                // Host.Value 已经包含端口号，无需重复添加
                string imageUrl = $"{scheme}://{host}/uploadall/{fileName}";

                _logger.LogInformation("二维码生成成功，URL: {ImageUrl}", imageUrl);

                // 6. 返回图片URL
                return new ContentResult
                {
                    Content = JsonSerializer.Serialize(new { success = true, url = imageUrl }),
                    ContentType = "application/json;charset=utf-8"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "生成小程序二维码时发生异常: {Message}", ex.Message);
                return new ContentResult
                {
                    Content = JsonSerializer.Serialize(new { Message = $"生成小程序二维码失败：{ex.Message}" }),
                    ContentType = "application/json;charset=utf-8"
                };
            }
        }
    }
}