using System.Text;
using System.Text.Json;

namespace WeChatMiniProgramAPI.Services
{
    public class WeChatService : IWeChatService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<WeChatService> _logger;

        public WeChatService(IHttpClientFactory httpClientFactory, ILogger<WeChatService> logger)
        {
            _httpClient = httpClientFactory.CreateClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
            _logger = logger;
        }

        public async Task<byte[]?> GenerateQrCodeAsync(string accessToken, string scene, string pagePath, int width = 430)
        {
            try
            {
                string url = $"https://api.weixin.qq.com/wxa/getwxacodeunlimit?access_token={accessToken}";

                var requestData = new
                {
                    scene = scene,
                    page = pagePath,
                    width = width,
                    auto_color = false,
                    line_color = new { r = 0, g = 0, b = 0 },
                    is_hyaline = false
                };

                var jsonData = JsonSerializer.Serialize(requestData);
                var content = new StringContent(jsonData, Encoding.UTF8, "application/json");

                _logger.LogInformation("正在调用微信API生成二维码，URL: {Url}", url);

                var response = await _httpClient.PostAsync(url, content);

                if (response.IsSuccessStatusCode)
                {
                    var imageBytes = await response.Content.ReadAsByteArrayAsync();
                    
                    // 检查返回的内容是否是图片还是错误信息
                    var contentType = response.Content.Headers.ContentType?.MediaType;
                    if (contentType == "image/jpeg" || contentType == "image/png" || imageBytes.Length > 1000)
                    {
                        _logger.LogInformation("成功生成二维码，图片大小: {Size} bytes", imageBytes.Length);
                        return imageBytes;
                    }
                    else
                    {
                        // 可能是错误信息
                        var errorMsg = Encoding.UTF8.GetString(imageBytes);
                        _logger.LogError("微信API返回错误: {Error}", errorMsg);
                        return null;
                    }
                }
                else
                {
                    _logger.LogError("调用微信API失败，状态码: {StatusCode}", response.StatusCode);
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "生成微信小程序二维码时发生异常: {Message}", ex.Message);
                return null;
            }
        }
    }
}