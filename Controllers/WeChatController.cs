using Microsoft.AspNetCore.Cors;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using WeChatMiniProgramAPI.Services;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.Drawing.Processing;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.Fonts;

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

        /// <summary>
        /// 生成365微信小程序二维码（带文字）
        /// </summary>
        /// <param name="accessToken">微信访问令牌</param>
        /// <param name="pagePath">小程序页面路径</param>
        /// <param name="CustomerID">客户ID</param>
        /// <param name="str1">文字1</param>
        /// <param name="str2">文字2</param>
        /// <param name="env_version">环境版本(release/trial/develop)</param>
        /// <returns>返回生成的二维码图片URL</returns>
        [EnableCors("myCors")]
        [HttpGet]
        [Route("Create365Qrocde")]
        [ProducesResponseType(200, Type = typeof(object))]
        [ProducesResponseType(400, Type = typeof(object))]
        [ProducesResponseType(500, Type = typeof(object))]
        public async Task<ContentResult> Create365Qrocde(
            [FromQuery] string accessToken,
            [FromQuery] string pagePath,
            [FromQuery] string CustomerID,
            [FromQuery] string str1,
            [FromQuery] string str2,
            [FromQuery] string env_version = "release")
        {
            try
            {
                _logger.LogInformation("开始生成365微信小程序二维码");

                // 参数验证
                if (string.IsNullOrEmpty(accessToken))
                    accessToken = Request.Query["accessToken"].ToString();
                if (string.IsNullOrEmpty(pagePath))
                    pagePath = Request.Query["pagePath"].ToString();
                if (string.IsNullOrEmpty(CustomerID))
                    CustomerID = Request.Query["CustomerID"].ToString();
                if (string.IsNullOrEmpty(str1))
                    str1 = Request.Query["str1"].ToString();
                if (string.IsNullOrEmpty(str2))
                    str2 = Request.Query["str2"].ToString();
                if (string.IsNullOrEmpty(env_version))
                    env_version = Request.Query["env_version"].ToString();

                if (string.IsNullOrEmpty(env_version))
                {
                    env_version = "release";
                }

                _logger.LogInformation("参数 - pagePath: {PagePath}, CustomerID: {CustomerID}, env_version: {EnvVersion}",
                    pagePath, CustomerID, env_version);

                // 调用微信小程序生成二维码API
                string url = $"https://api.weixin.qq.com/wxa/getwxacodeunlimit?access_token={accessToken}";

                // 构建请求参数
                var requestData = new
                {
                    scene = $"CustomerID={CustomerID}",
                    env_version = env_version,
                    page = pagePath,
                    width = 430,
                    auto_color = false,
                    line_color = new { r = 0, g = 0, b = 0 },
                    is_hyaline = false
                };

                // 发送请求获取二维码图片
                using (var httpClient = new HttpClient())
                {
                    httpClient.Timeout = TimeSpan.FromSeconds(30);
                    var content = new StringContent(
                        Newtonsoft.Json.JsonConvert.SerializeObject(requestData),
                        System.Text.Encoding.UTF8,
                        "application/json");
                    var response = await httpClient.PostAsync(url, content);

                    if (response.IsSuccessStatusCode)
                    {
                        // 获取响应内容类型，检查是否为图片
                        var contentType = response.Content.Headers.ContentType?.MediaType;
                        if (contentType != null && contentType.StartsWith("image/"))
                        {
                            // 读取二维码图片数据
                            byte[] qrCodeBytes = await response.Content.ReadAsByteArrayAsync();

                            // 验证数据长度
                            if (qrCodeBytes == null || qrCodeBytes.Length == 0)
                            {
                                return new ContentResult
                                {
                                    Content = JsonSerializer.Serialize(new { Message = "微信API返回空的图片数据" }),
                                    ContentType = "application/json;charset=utf-8"
                                };
                            }

                            if (qrCodeBytes.Length < 100)
                            {
                                return new ContentResult
                                {
                                    Content = JsonSerializer.Serialize(new { Message = "微信API返回的数据过小，可能不是有效的图片" }),
                                    ContentType = "application/json;charset=utf-8"
                                };
                            }

                            try
                            {
                                // 使用ImageSharp加载二维码图片
                                using (var qrCodeImage = Image.Load<Rgba32>(qrCodeBytes))
                                {
                                    // 创建手机竖屏比例的画布 (比例约为9:16)
                                    int canvasWidth = 600;
                                    int canvasHeight = 900;

                                    using (var canvas = new Image<Rgba32>(canvasWidth, canvasHeight))
                                    {
                                        // 填充白色背景
                                        canvas.Mutate(ctx => ctx.BackgroundColor(Color.White));

                                        // 计算二维码位置（居中）
                                        int qrWidth = 450;
                                        int qrHeight = 450;
                                        int qrX = (canvasWidth - qrWidth) / 2;
                                        int qrY = canvasHeight - qrHeight - 200; // 底部留出空间

                                        // 缩放并绘制二维码
                                        qrCodeImage.Mutate(x => x.Resize(qrWidth, qrHeight));
                                        canvas.Mutate(ctx => ctx.DrawImage(qrCodeImage, new Point(qrX, qrY), 1f));

                                        // 绘制文字
                                        // 尝试使用系统字体
                                        FontFamily fontFamily;
                                        Font font;
                                        
                                        // 尝试查找中文字体，如果找不到则使用任意可用字体
                                        if (SystemFonts.TryGet("Noto Sans CJK SC", out fontFamily) ||
                                            SystemFonts.TryGet("WenQuanYi Zen Hei", out fontFamily) ||
                                            SystemFonts.TryGet("Microsoft YaHei", out fontFamily) ||
                                            SystemFonts.TryGet("SimHei", out fontFamily) ||
                                            SystemFonts.TryGet("Arial", out fontFamily))
                                        {
                                            font = fontFamily.CreateFont(42, FontStyle.Regular);
                                            _logger.LogInformation("使用字体: {FontName}", fontFamily.Name);
                                        }
                                        else
                                        {
                                            // 如果所有指定字体都不存在，使用第一个可用的系统字体
                                            var availableFonts = SystemFonts.Families.ToList();
                                            if (availableFonts.Any())
                                            {
                                                fontFamily = availableFonts.First();
                                                font = fontFamily.CreateFont(42, FontStyle.Regular);
                                                _logger.LogWarning("未找到指定字体，使用默认字体: {FontName}", fontFamily.Name);
                                            }
                                            else
                                            {
                                                _logger.LogError("系统中没有任何可用字体!");
                                                return new ContentResult
                                                {
                                                    Content = JsonSerializer.Serialize(new { Message = "系统中没有可用字体，无法绘制文字" }),
                                                    ContentType = "application/json;charset=utf-8"
                                                };
                                            }
                                        }

                                        // 计算文字位置
                                        float str1Y = qrY - 100; // 二维码上方100像素
                                        float str2Y = str1Y - 100; // str1上方100像素

                                        // 绘制文字（红色）
                                        var textOptions1 = new RichTextOptions(font)
                                        {
                                            Origin = new PointF(canvasWidth / 2, str1Y),
                                            HorizontalAlignment = HorizontalAlignment.Center,
                                            VerticalAlignment = VerticalAlignment.Top
                                        };

                                        var textOptions2 = new RichTextOptions(font)
                                        {
                                            Origin = new PointF(canvasWidth / 2, str2Y),
                                            HorizontalAlignment = HorizontalAlignment.Center,
                                            VerticalAlignment = VerticalAlignment.Top
                                        };

                                        _logger.LogInformation("绘制文字 - str2: {Str2}, str1: {Str1}", str2, str1);
                                        canvas.Mutate(ctx => ctx
                                            .DrawText(textOptions2, str2, Color.Red)
                                            .DrawText(textOptions1, str1, Color.Red));

                                        // 确保目录存在
                                        string webPath = _webHostEnvironment.WebRootPath ?? _webHostEnvironment.ContentRootPath;
                                        string uploadDir = Path.Combine(webPath, "uploadall");
                                        if (!Directory.Exists(uploadDir))
                                        {
                                            Directory.CreateDirectory(uploadDir);
                                        }

                                        // 生成文件名
                                        string fileName = $"qrcode_{CustomerID}_{DateTime.Now:yyyyMMddHHmmssfff}.png";
                                        string filePath = Path.Combine(uploadDir, fileName);

                                        // 保存图片
                                        await canvas.SaveAsPngAsync(filePath);

                                        // 构建图片URL
                                        string host = HttpContext?.Request?.Host.Value ?? "tx.qsgl.net:8092";
                                        string scheme = HttpContext?.Request?.Scheme ?? "https";
                                        string imageUrl = $"{scheme}://{host}/uploadall/{fileName}";

                                        _logger.LogInformation("365二维码生成成功，URL: {ImageUrl}", imageUrl);

                                        // 返回成功响应
                                        return new ContentResult
                                        {
                                            Content = JsonSerializer.Serialize(new { success = true, url = imageUrl }),
                                            ContentType = "application/json;charset=utf-8"
                                        };
                                    }
                                }
                            }
                            catch (Exception imgEx)
                            {
                                _logger.LogError(imgEx, "处理图片时发生错误");
                                return new ContentResult
                                {
                                    Content = JsonSerializer.Serialize(new { Message = $"处理图片失败：{imgEx.Message}" }),
                                    ContentType = "application/json;charset=utf-8"
                                };
                            }
                        }
                        else
                        {
                            // 如果返回的不是图片，尝试读取错误信息
                            string errorResponse = await response.Content.ReadAsStringAsync();
                            _logger.LogError("微信API返回非图片数据：{ErrorResponse}", errorResponse);
                            return new ContentResult
                            {
                                Content = JsonSerializer.Serialize(new { Message = $"微信API返回非图片数据：{errorResponse}" }),
                                ContentType = "application/json;charset=utf-8"
                            };
                        }
                    }
                    else
                    {
                        // 读取错误响应内容
                        string errorContent = await response.Content.ReadAsStringAsync();
                        _logger.LogError("调用微信API失败，状态码：{StatusCode}，错误信息：{ErrorContent}",
                            response.StatusCode, errorContent);
                        return new ContentResult
                        {
                            Content = JsonSerializer.Serialize(new
                            {
                                Message = $"调用微信API失败，状态码：{response.StatusCode}，错误信息：{errorContent}"
                            }),
                            ContentType = "application/json;charset=utf-8"
                        };
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "生成365小程序二维码时发生异常: {Message}", ex.Message);
                return new ContentResult
                {
                    Content = JsonSerializer.Serialize(new { Message = $"生成小程序二维码失败：{ex.Message}" }),
                    ContentType = "application/json;charset=utf-8"
                };
            }
        }
    }
}