using Microsoft.AspNetCore.Cors;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using WeChatMiniProgramAPI.Services.Certificate;

namespace WeChatMiniProgramAPI.Controllers
{
    /// <summary>
    /// 证书申请请求模型
    /// </summary>
    public class CertificateRequestModel
    {
        /// <summary>
        /// 域名，如：qsgl.net
        /// </summary>
        /// <example>qsgl.net</example>
        public string Domain { get; set; } = "";

        /// <summary>
        /// 是否申请泛域名证书，默认true
        /// </summary>
        /// <example>true</example>
        public bool IsWildcard { get; set; } = true;
    }
}

namespace WeChatMiniProgramAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CertificateController : ControllerBase
    {
        private readonly ICertificateService _certificateService;
        private readonly ILogger<CertificateController> _logger;

        public CertificateController(
            ICertificateService certificateService,
            ILogger<CertificateController> logger)
        {
            _certificateService = certificateService;
            _logger = logger;
        }

        /// <summary>
        /// 测试JSON反序列化 - 诊断用
        /// </summary>
        [EnableCors("myCors")]
        [HttpPost]
        [Route("test")]
        public ActionResult TestJsonDeserialization([FromBody] CertificateRequestModel request)
        {
            _logger.LogInformation("诊断测试 - 接收到的原始请求: {@Request}", request);
            
            var domainValue = request?.Domain ?? "null";
            var domainBytes = System.Text.Encoding.UTF8.GetBytes(domainValue);
            
            return Ok(new {
                Success = true,
                Received = request,
                DomainValue = domainValue,
                DomainLength = domainValue.Length,
                DomainBytes = string.Join(",", domainBytes),
                DomainType = domainValue.GetType().Name,
                IsWildcardValue = request?.IsWildcard ?? false,
                RequestIsNull = request == null,
                Message = domainValue == "string" ? "警告：域名被错误解析为'string'" : "域名解析正常"
            });
        }

        /// <summary>
        /// 测试原始JSON反序列化
        /// </summary>
        [EnableCors("myCors")]
        [HttpPost]
        [Route("test-raw")]
        public ActionResult TestRawJson([FromBody] object rawData)
        {
            var bodyText = "未能读取";
            try
            {
                // 获取原始JSON字符串
                bodyText = rawData?.ToString() ?? "null";
                _logger.LogInformation("接收到的原始数据: {RawData}, Type: {Type}", bodyText, rawData?.GetType().Name ?? "null");
                
                return Ok(new {
                    Success = true,
                    ReceivedData = rawData,
                    DataType = rawData?.GetType().Name ?? "null",
                    DataString = bodyText,
                    Message = "原始数据接收成功"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理原始JSON时发生错误");
                return BadRequest(new {
                    Success = false,
                    Error = ex.Message,
                    ReceivedData = bodyText
                });
            }
        }

        /// <summary>
        /// 申请SSL证书（支持泛域名）- 支持JSON请求体
        /// </summary>
        /// <param name="request">证书申请请求</param>
        /// <returns></returns>
        [EnableCors("myCors")]
        [HttpPost]
        [Route("request")]
        public async Task<ActionResult> RequestCertificate([FromBody] CertificateRequestModel request)
        {
            try
            {
                // 验证请求模型
                if (request == null)
                {
                    return BadRequest(new { 
                        type = "https://tools.ietf.org/html/rfc7231#section-6.5.1",
                        title = "One or more validation errors occurred.",
                        status = 400,
                        errors = new { domain = new[] { "The domain field is required." } },
                        traceId = HttpContext.TraceIdentifier
                    });
                }

                _logger.LogInformation("收到证书申请请求：{Domain}，泛域名：{IsWildcard}", request.Domain, request.IsWildcard);
                _logger.LogInformation("请求详细信息 - Domain: '{Domain}', IsWildcard: {IsWildcard}, DomainLength: {Length}", request.Domain, request.IsWildcard, request.Domain?.Length ?? 0);
                
                // 检查是否为Swagger默认值
                if (request.Domain == "string" || request.Domain == "String")
                {
                    return BadRequest(new {
                        Success = false,
                        Message = "检测到Swagger默认值 'string'，请手动输入正确的域名，如：qsgl.net",
                        ReceivedDomain = request.Domain,
                        ExpectedFormat = "qsgl.net",
                        Hint = "请在Swagger UI中清除默认值并输入真实域名"
                    });
                }

                if (string.IsNullOrEmpty(request.Domain))
                {
                    return BadRequest(new { 
                        type = "https://tools.ietf.org/html/rfc7231#section-6.5.1",
                        title = "One or more validation errors occurred.",
                        status = 400,
                        errors = new { domain = new[] { "The domain field is required." } },
                        traceId = HttpContext.TraceIdentifier
                    });
                }

                // 验证域名格式
                if (!IsValidDomain(request.Domain))
                {
                    return BadRequest(new { Message = "域名格式不正确" });
                }

                var result = await _certificateService.RequestCertificateAsync(request.Domain, request.IsWildcard);

                if (result.Success)
                {
                    // 自动部署证书
                    if (result.CertificateData != null && result.PrivateKey != null)
                    {
                        var deployed = await _certificateService.DeployCertificateAsync(request.Domain, result.CertificateData, result.PrivateKey);
                        
                        return Ok(new
                        {
                            Success = true,
                            Message = result.Message,
                            Domain = request.IsWildcard ? $"*.{request.Domain}" : request.Domain,
                            ExpiryDate = result.ExpiryDate,
                            Deployed = deployed
                        });
                    }
                    else
                    {
                        return Ok(new { Success = true, Message = result.Message });
                    }
                }
                else
                {
                    return BadRequest(new { Success = false, Message = result.Message });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理证书申请请求时发生异常");
                return StatusCode(500, new { Message = $"服务器内部错误：{ex.Message}" });
            }
        }

        /// <summary>
        /// 申请SSL证书（支持泛域名）- 支持Query参数方式
        /// </summary>
        /// <param name="domain">域名，如：qsgl.net</param>
        /// <param name="isWildcard">是否申请泛域名证书，默认true</param>
        /// <returns></returns>
        [EnableCors("myCors")]
        [HttpGet]
        [Route("request")]
        public async Task<ActionResult> RequestCertificateQuery([FromQuery] string domain, [FromQuery] bool isWildcard = true)
        {
            // 将Query参数转换为模型
            var request = new CertificateRequestModel 
            { 
                Domain = domain ?? string.Empty, 
                IsWildcard = isWildcard 
            };
            
            // 调用原方法
            return await RequestCertificate(request);
        }

        /// <summary>
        /// 申请SSL证书（弹性POST请求）
        /// 支持以下格式：
        /// 1) JSON对象：{ "domain": "qsgl.net", "isWildcard": true }
        /// 2) JSON字符串："qsgl.net"
        /// 3) 纯文本：qsgl.net（Content-Type: text/plain）
        /// 4) 表单：domain=qsgl.net&isWildcard=true（Content-Type: application/x-www-form-urlencoded）
        /// 5) Query：/api/Certificate/request-flex?domain=qsgl.net&isWildcard=true
        /// </summary>
    [EnableCors("myCors")]
    [HttpPost]
    [Route("request-flex")]
    [Consumes("application/json", "text/plain", "application/x-www-form-urlencoded")]
        public async Task<ActionResult> RequestCertificateFlexible([FromBody] JsonElement body, [FromQuery] string? domain = null, [FromQuery] bool? isWildcard = null)
        {
            try
            {
                string? parsedDomain = domain;
                bool parsedIsWildcard = isWildcard ?? true;

                // 优先从Query取得（若提供）
                if (!string.IsNullOrWhiteSpace(parsedDomain))
                {
                    var req = new CertificateRequestModel { Domain = parsedDomain!, IsWildcard = parsedIsWildcard };
                    return await RequestCertificate(req);
                }

                // Content-Type: application/x-www-form-urlencoded
                if (Request.HasFormContentType)
                {
                    var form = await Request.ReadFormAsync();
                    var formDomain = form["domain"].FirstOrDefault();
                    var formWildcard = form["isWildcard"].FirstOrDefault();

                    if (!string.IsNullOrWhiteSpace(formDomain))
                    {
                        bool tryWildcard = parsedIsWildcard;
                        if (!string.IsNullOrWhiteSpace(formWildcard))
                        {
                            bool.TryParse(formWildcard, out tryWildcard);
                        }

                        var req = new CertificateRequestModel { Domain = formDomain!, IsWildcard = tryWildcard };
                        return await RequestCertificate(req);
                    }
                }

                // 解析JSON主体
                switch (body.ValueKind)
                {
                    case JsonValueKind.Object:
                        {
                            string? objDomain = null;
                            bool objWildcard = parsedIsWildcard;

                            // 不区分大小写地取属性
                            foreach (var prop in body.EnumerateObject())
                            {
                                var name = prop.Name;
                                if (string.Equals(name, "domain", StringComparison.OrdinalIgnoreCase))
                                {
                                    if (prop.Value.ValueKind == JsonValueKind.String)
                                    {
                                        objDomain = prop.Value.GetString();
                                    }
                                }
                                else if (string.Equals(name, "isWildcard", StringComparison.OrdinalIgnoreCase))
                                {
                                    if (prop.Value.ValueKind == JsonValueKind.True || prop.Value.ValueKind == JsonValueKind.False)
                                    {
                                        objWildcard = prop.Value.GetBoolean();
                                    }
                                    else if (prop.Value.ValueKind == JsonValueKind.String && bool.TryParse(prop.Value.GetString(), out var b))
                                    {
                                        objWildcard = b;
                                    }
                                }
                            }

                            if (!string.IsNullOrWhiteSpace(objDomain))
                            {
                                var req = new CertificateRequestModel { Domain = objDomain!, IsWildcard = objWildcard };
                                return await RequestCertificate(req);
                            }
                            break;
                        }
                    case JsonValueKind.String:
                        {
                            var str = body.GetString();
                            if (!string.IsNullOrWhiteSpace(str))
                            {
                                // 允许JSON字符串直接作为域名
                                var req = new CertificateRequestModel { Domain = str!, IsWildcard = parsedIsWildcard };
                                return await RequestCertificate(req);
                            }
                            break;
                        }
                    case JsonValueKind.Null:
                    case JsonValueKind.Undefined:
                    case JsonValueKind.Array:
                    case JsonValueKind.Number:
                    case JsonValueKind.True:
                    case JsonValueKind.False:
                    default:
                        break;
                }

                // 尝试作为纯文本读取（例如 Content-Type: text/plain 但被绑定为空对象的情况）
                Request.EnableBuffering();
                using (var reader = new StreamReader(Request.Body, System.Text.Encoding.UTF8, leaveOpen: true))
                {
                    Request.Body.Position = 0;
                    var raw = await reader.ReadToEndAsync();
                    Request.Body.Position = 0;
                    var rawText = raw?.Trim();
                    if (!string.IsNullOrWhiteSpace(rawText))
                    {
                        // 如果是被引号包裹的JSON字符串，去除引号
                        if ((rawText.StartsWith("\"") && rawText.EndsWith("\"")) ||
                            (rawText.StartsWith("'") && rawText.EndsWith("'")))
                        {
                            rawText = rawText.Substring(1, rawText.Length - 2);
                        }

                        if (!string.IsNullOrWhiteSpace(rawText))
                        {
                            var req = new CertificateRequestModel { Domain = rawText!, IsWildcard = parsedIsWildcard };
                            return await RequestCertificate(req);
                        }
                    }
                }

                // 兜底：提示如何正确提交
                return BadRequest(new
                {
                    Success = false,
                    Message = "无法从请求中解析域名。请使用以下任一方式提交：JSON对象、JSON字符串、纯文本、表单或Query参数。",
                    Examples = new
                    {
                        JsonObject = new { domain = "qsgl.net", isWildcard = true },
                        JsonString = "qsgl.net",
                        PlainText = "qsgl.net",
                        Form = "domain=qsgl.net&isWildcard=true",
                        Query = "/api/Certificate/request-flex?domain=qsgl.net&isWildcard=true"
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理弹性证书申请请求时发生异常");
                return StatusCode(500, new { Message = $"服务器内部错误：{ex.Message}" });
            }
        }

        /// <summary>
        /// 续订SSL证书
        /// </summary>
        /// <param name="domain">域名</param>
        /// <returns></returns>
        [EnableCors("myCors")]
        [HttpPost]
        [Route("renew")]
        public async Task<ActionResult> RenewCertificate([FromQuery] string domain)
        {
            try
            {
                _logger.LogInformation("收到证书续订请求：{Domain}", domain);

                if (string.IsNullOrEmpty(domain))
                {
                    return BadRequest(new { Message = "域名参数不能为空" });
                }

                var renewed = await _certificateService.RenewCertificateAsync(domain);

                if (renewed)
                {
                    return Ok(new { Success = true, Message = "证书续订成功" });
                }
                else
                {
                    return BadRequest(new { Success = false, Message = "证书续订失败" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理证书续订请求时发生异常");
                return StatusCode(500, new { Message = $"服务器内部错误：{ex.Message}" });
            }
        }

        /// <summary>
        /// 获取证书信息
        /// </summary>
        /// <param name="domain">域名</param>
        /// <returns></returns>
        [EnableCors("myCors")]
        [HttpGet]
        [Route("info")]
        public async Task<ActionResult> GetCertificateInfo([FromQuery] string domain)
        {
            try
            {
                if (string.IsNullOrEmpty(domain))
                {
                    return BadRequest(new { Message = "域名参数不能为空" });
                }

                var certInfo = await _certificateService.GetCertificateInfoAsync(domain);

                if (certInfo != null)
                {
                    return Ok(new
                    {
                        Success = true,
                        Certificate = new
                        {
                            certInfo.Domain,
                            certInfo.IssueDate,
                            certInfo.ExpiryDate,
                            certInfo.IsWildcard,
                            certInfo.Issuer,
                            DaysUntilExpiry = (certInfo.ExpiryDate - DateTime.UtcNow).Days,
                            NeedsRenewal = (certInfo.ExpiryDate - DateTime.UtcNow).Days < 30
                        }
                    });
                }
                else
                {
                    return NotFound(new { Message = "未找到该域名的证书" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取证书信息时发生异常");
                return StatusCode(500, new { Message = $"服务器内部错误：{ex.Message}" });
            }
        }

        /// <summary>
        /// 获取所有证书列表
        /// </summary>
        /// <returns></returns>
        [EnableCors("myCors")]
        [HttpGet]
        [Route("list")]
        public async Task<ActionResult> GetAllCertificates()
        {
            try
            {
                var certificates = await _certificateService.GetAllCertificatesAsync();

                var result = certificates.Select(cert => new
                {
                    cert.Domain,
                    cert.IssueDate,
                    cert.ExpiryDate,
                    cert.IsWildcard,
                    cert.Issuer,
                    DaysUntilExpiry = (cert.ExpiryDate - DateTime.UtcNow).Days,
                    NeedsRenewal = (cert.ExpiryDate - DateTime.UtcNow).Days < 30
                }).ToList();

                return Ok(new
                {
                    Success = true,
                    Count = result.Count,
                    Certificates = result
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取证书列表时发生异常");
                return StatusCode(500, new { Message = $"服务器内部错误：{ex.Message}" });
            }
        }

        /// <summary>
        /// 批量续订即将过期的证书
        /// </summary>
        /// <returns></returns>
        [EnableCors("myCors")]
        [HttpPost]
        [Route("auto-renew")]
        public async Task<ActionResult> AutoRenewCertificates()
        {
            try
            {
                _logger.LogInformation("开始自动续订即将过期的证书");

                var certificates = await _certificateService.GetAllCertificatesAsync();
                var expiringCertificates = certificates
                    .Where(cert => (cert.ExpiryDate - DateTime.UtcNow).Days < 30)
                    .ToList();

                if (!expiringCertificates.Any())
                {
                    return Ok(new { Success = true, Message = "没有需要续订的证书" });
                }

                var results = new List<object>();

                foreach (var cert in expiringCertificates)
                {
                    try
                    {
                        var renewed = await _certificateService.RenewCertificateAsync(cert.Domain);
                        results.Add(new
                        {
                            Domain = cert.Domain,
                            Success = renewed,
                            Message = renewed ? "续订成功" : "续订失败"
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "续订证书失败：{Domain}", cert.Domain);
                        results.Add(new
                        {
                            Domain = cert.Domain,
                            Success = false,
                            Message = $"续订失败：{ex.Message}"
                        });
                    }
                }

                return Ok(new
                {
                    Success = true,
                    Message = $"处理了 {expiringCertificates.Count} 个即将过期的证书",
                    Results = results
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "自动续订证书时发生异常");
                return StatusCode(500, new { Message = $"服务器内部错误：{ex.Message}" });
            }
        }

        private bool IsValidDomain(string domain)
        {
            if (string.IsNullOrWhiteSpace(domain))
                return false;

            try
            {
                var uri = new Uri($"http://{domain}");
                return uri.Host == domain;
            }
            catch
            {
                return false;
            }
        }
    }
}