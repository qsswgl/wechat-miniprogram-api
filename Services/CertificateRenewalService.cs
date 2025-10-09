using WeChatMiniProgramAPI.Services.Certificate;

namespace WeChatMiniProgramAPI.Services
{
    public class CertificateRenewalService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<CertificateRenewalService> _logger;
        private readonly TimeSpan _checkInterval;

        public CertificateRenewalService(
            IServiceProvider serviceProvider,
            ILogger<CertificateRenewalService> logger,
            IConfiguration configuration)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            
            // 默认每天检查一次
            var hours = configuration.GetValue<int>("Certificate:CheckIntervalHours", 24);
            _checkInterval = TimeSpan.FromHours(hours);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("证书自动续订服务已启动，检查间隔：{Interval}", _checkInterval);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CheckAndRenewCertificatesAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "证书检查和续订过程中发生异常");
                }

                await Task.Delay(_checkInterval, stoppingToken);
            }
        }

        private async Task CheckAndRenewCertificatesAsync()
        {
            _logger.LogInformation("开始检查证书状态");

            using var scope = _serviceProvider.CreateScope();
            var certificateService = scope.ServiceProvider.GetRequiredService<ICertificateService>();

            try
            {
                var certificates = await certificateService.GetAllCertificatesAsync();
                var expiringCertificates = certificates
                    .Where(cert => (cert.ExpiryDate - DateTime.UtcNow).Days < 30)
                    .ToList();

                if (!expiringCertificates.Any())
                {
                    _logger.LogInformation("没有需要续订的证书");
                    return;
                }

                _logger.LogInformation("发现 {Count} 个即将过期的证书", expiringCertificates.Count);

                foreach (var cert in expiringCertificates)
                {
                    try
                    {
                        _logger.LogInformation("开始续订证书：{Domain}，剩余天数：{Days}天", 
                            cert.Domain, (cert.ExpiryDate - DateTime.UtcNow).Days);

                        var renewed = await certificateService.RenewCertificateAsync(cert.Domain);
                        
                        if (renewed)
                        {
                            _logger.LogInformation("证书续订成功：{Domain}", cert.Domain);
                        }
                        else
                        {
                            _logger.LogError("证书续订失败：{Domain}", cert.Domain);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "续订证书时发生异常：{Domain}", cert.Domain);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "检查证书状态时发生异常");
            }
        }
    }
}