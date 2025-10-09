using Certes;
using Certes.Acme;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Security.Cryptography; // ← 新增

namespace WeChatMiniProgramAPI.Services.Certificate
{
    public class CertificateService : ICertificateService
    {
        private readonly IDnsPodService _dnsPodService;
        private readonly ILogger<CertificateService> _logger;
        private readonly IWebHostEnvironment _environment;
        private readonly string _certificateStorePath;
        private readonly string _acmeEmail;

        public CertificateService(
            IDnsPodService dnsPodService,
            ILogger<CertificateService> logger,
            IWebHostEnvironment environment,
            IConfiguration configuration)
        {
            _dnsPodService = dnsPodService;
            _logger = logger;
            _environment = environment;
            _certificateStorePath = Path.Combine(_environment.ContentRootPath, "certificates");
            _acmeEmail = configuration["Certificate:Email"] ?? "admin@qsgl.net";

            // 确保证书存储目录存在
            if (!System.IO.Directory.Exists(_certificateStorePath))
            {
                System.IO.Directory.CreateDirectory(_certificateStorePath);
            }
        }

        public async Task<CertificateResult> RequestCertificateAsync(string domain, bool isWildcard = true)
        {
            try
            {
                _logger.LogInformation("开始申请{Type}证书：{Domain}", isWildcard ? "泛域名" : "单域名", domain);

                // 准备域名
                var certificateDomain = isWildcard ? $"*.{domain}" : domain;
                var domains = isWildcard ? new[] { $"*.{domain}", domain } : new[] { domain };

                // 创建ACME客户端
                var acme = new AcmeContext(WellKnownServers.LetsEncryptV2);

                // 创建或加载账户
                var accountKey = await LoadOrCreateAccountKeyAsync();
                var account = await acme.NewAccount(_acmeEmail, true);

                _logger.LogInformation("ACME账户创建/加载成功");

                // 创建订单
                var order = await acme.NewOrder(domains);

                // 处理授权验证
                var authzList = await order.Authorizations();

                foreach (var authz in authzList)
                {
                    var dnsChallenge = await authz.Dns();
                    var dnsTxt = acme.AccountKey.DnsTxt(dnsChallenge.Token);

                    var resource = await authz.Resource();
                    var challengeDomain = $"_acme-challenge.{resource.Identifier.Value}";
                    
                    _logger.LogInformation("添加DNS TXT记录：{Domain} = {Value}", challengeDomain, dnsTxt);

                    // 添加DNS TXT记录
                    if (!await _dnsPodService.AddTxtRecordAsync(challengeDomain, dnsTxt))
                    {
                        return new CertificateResult
                        {
                            Success = false,
                            Message = $"无法添加DNS TXT记录到 {challengeDomain}"
                        };
                    }

                    // 等待DNS传播
                    if (!await _dnsPodService.WaitForPropagationAsync(challengeDomain, dnsTxt))
                    {
                        _logger.LogWarning("DNS传播超时，但继续进行验证");
                    }

                    // 验证挑战
                    await dnsChallenge.Validate();
                }

                // 等待订单完成
                await WaitForOrderCompletionAsync(order);

                // 生成私钥和证书
                var privateKey = KeyFactory.NewKey(KeyAlgorithm.ES256);
                var cert = await order.Generate(new CsrInfo
                {
                    CountryName = "CN",
                    State = "Beijing",
                    Locality = "Beijing",
                    Organization = "QSGL",
                    OrganizationUnit = "IT Department",
                    CommonName = certificateDomain
                }, privateKey);

                // 清理DNS记录
                await CleanupDnsRecordsAsync(authzList, acme.AccountKey);

                _logger.LogInformation("证书申请成功：{Domain}", certificateDomain);

                var certBytes = cert.ToPem();
                var keyPem = privateKey.ToPem();

                // 保存证书到本地
                await SaveCertificateAsync(domain, certBytes, keyPem, isWildcard);

                return new CertificateResult
                {
                    Success = true,
                    Message = "证书申请成功",
                    CertificateData = Encoding.UTF8.GetBytes(certBytes),
                    PrivateKey = keyPem,
                    ExpiryDate = DateTime.UtcNow.AddDays(90) // Let's Encrypt 证书有效期90天
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "证书申请失败：{Message}", ex.Message);
                return new CertificateResult
                {
                    Success = false,
                    Message = $"证书申请失败：{ex.Message}"
                };
            }
        }

        public async Task<bool> DeployCertificateAsync(string domain, byte[] certificateData, string privateKey)
        {
            try
            {
                _logger.LogInformation("部署证书：{Domain}", domain);

                // 创建PFX文件
                var cert = X509Certificate2.CreateFromPem(Encoding.UTF8.GetString(certificateData), privateKey);
                var pfxBytes = cert.Export(X509ContentType.Pfx, "qsgl2024");

                // 保存PFX文件
                var pfxPath = Path.Combine(_certificateStorePath, $"{domain}.pfx");
                await File.WriteAllBytesAsync(pfxPath, pfxBytes);

                _logger.LogInformation("证书已保存到：{Path}", pfxPath);

                // TODO: 这里可以添加动态重新加载Kestrel证书的逻辑
                // 或者通知系统重启以加载新证书

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "证书部署失败：{Message}", ex.Message);
                return false;
            }
        }

        public Task<CertificateInfo?> GetCertificateInfoAsync(string domain)
        {
            try
            {
                var pfxPath = Path.Combine(_certificateStorePath, $"{domain}.pfx");
                if (!File.Exists(pfxPath))
                {
                    return Task.FromResult<CertificateInfo?>(null);
                }

                var cert = new X509Certificate2(pfxPath, "qsgl2024", X509KeyStorageFlags.Exportable);
                
                return Task.FromResult<CertificateInfo?>(new CertificateInfo
                {
                    Domain = domain,
                    IssueDate = cert.NotBefore,
                    ExpiryDate = cert.NotAfter,
                    IsWildcard = cert.Subject.Contains("*."),
                    FilePath = pfxPath,
                    Issuer = cert.Issuer
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取证书信息失败：{Message}", ex.Message);
                return Task.FromResult<CertificateInfo?>(null);
            }
        }

        public async Task<bool> RenewCertificateAsync(string domain)
        {
            _logger.LogInformation("续订证书：{Domain}", domain);
            
            var currentCert = await GetCertificateInfoAsync(domain);
            if (currentCert == null)
            {
                _logger.LogWarning("未找到现有证书，将申请新证书");
            }

            var result = await RequestCertificateAsync(domain, currentCert?.IsWildcard ?? true);
            if (result.Success && result.CertificateData != null && result.PrivateKey != null)
            {
                return await DeployCertificateAsync(domain, result.CertificateData, result.PrivateKey);
            }

            return false;
        }

        public async Task<List<CertificateInfo>> GetAllCertificatesAsync()
        {
            var certificates = new List<CertificateInfo>();

            try
            {
                var pfxFiles = System.IO.Directory.GetFiles(_certificateStorePath, "*.pfx");
                
                foreach (var pfxFile in pfxFiles)
                {
                    var domain = Path.GetFileNameWithoutExtension(pfxFile);
                    var certInfo = await GetCertificateInfoAsync(domain);
                    if (certInfo != null)
                    {
                        certificates.Add(certInfo);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取证书列表失败：{Message}", ex.Message);
            }

            return certificates;
        }

        private async Task<IKey> LoadOrCreateAccountKeyAsync()
        {
            var keyPath = Path.Combine(_certificateStorePath, "account.key");
            
            if (File.Exists(keyPath))
            {
                var keyPem = await File.ReadAllTextAsync(keyPath);
                return KeyFactory.FromPem(keyPem);
            }
            else
            {
                var key = KeyFactory.NewKey(KeyAlgorithm.ES256);
                await File.WriteAllTextAsync(keyPath, key.ToPem());
                return key;
            }
        }

        private async Task WaitForOrderCompletionAsync(IOrderContext order)
        {
            var maxAttempts = 30;
            var attempt = 0;

            while (attempt < maxAttempts)
            {
                var orderStatus = await order.Resource();
                
                if (orderStatus.Status == Certes.Acme.Resource.OrderStatus.Ready)
                {
                    _logger.LogInformation("订单验证完成");
                    return;
                }
                else if (orderStatus.Status == Certes.Acme.Resource.OrderStatus.Invalid)
                {
                    throw new InvalidOperationException("订单验证失败");
                }

                _logger.LogDebug("等待订单完成，状态：{Status}", orderStatus.Status);
                await Task.Delay(2000);
                attempt++;
            }

            throw new TimeoutException("等待订单完成超时");
        }

        private async Task CleanupDnsRecordsAsync(IEnumerable<IAuthorizationContext> authzList, IKey accountKey)
        {
            foreach (var authz in authzList)
            {
                try
                {
                    var dnsChallenge = await authz.Dns();
                    var dnsTxt = accountKey.DnsTxt(dnsChallenge.Token);
                    var authzResource = await authz.Resource();
                    var challengeDomain = $"_acme-challenge.{authzResource.Identifier.Value}";
                    
                    await _dnsPodService.RemoveTxtRecordAsync(challengeDomain, dnsTxt);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "清理DNS记录时发生异常");
                }
            }
        }

        private async Task SaveCertificateAsync(string domain, string certPem, string keyPem, bool isWildcard)
        {
            var certPath = Path.Combine(_certificateStorePath, $"{domain}.crt");
            var keyPath = Path.Combine(_certificateStorePath, $"{domain}.key");
            var infoPath = Path.Combine(_certificateStorePath, $"{domain}.info");

            await File.WriteAllTextAsync(certPath, certPem);
            await File.WriteAllTextAsync(keyPath, keyPem);
            
            var info = new
            {
                domain,
                isWildcard,
                issueDate = DateTime.UtcNow,
                expiryDate = DateTime.UtcNow.AddDays(90)
            };
            
            await File.WriteAllTextAsync(infoPath, System.Text.Json.JsonSerializer.Serialize(info, new System.Text.Json.JsonSerializerOptions { WriteIndented = true }));

            // 在证书签发完成处，保存 PFX 时包含完整链
            var pfxPath = Path.Combine(_certificateStorePath, $"{domain}.pfx");
            var chainPem = await GetCertificateChainAsync(domain);
            SavePfxWithChain(certPem, chainPem, keyPem, pfxPath, "qsgl2024");
        }

        private void SavePfxWithChain(string leafPem, string chainPem, string keyPem, string pfxPath, string? password)
        {
            // 1. 叶子证书 + 私钥
            using var leaf = X509Certificate2.CreateFromPem(leafPem);
            using var key = RSA.Create(); // ← 现在可用
            key.ImportFromPem(keyPem);
            using var leafWithKey = leaf.CopyWithPrivateKey(key);

            // 2. 解析链
            var chain = new X509Certificate2Collection();
            foreach (var block in chainPem.Split("-----END CERTIFICATE-----", StringSplitOptions.RemoveEmptyEntries))
            {
                var pem = block + "-----END CERTIFICATE-----";
                try
                {
                    var ca = X509Certificate2.CreateFromPem(pem);
                    chain.Add(ca);
                }
                catch { }
            }

            // 3. 导出 PFX（含链）
            var export = new X509Certificate2Collection(leafWithKey);
            export.AddRange(chain);
            var bytes = export.Export(X509ContentType.Pkcs12, password ?? string.Empty);
            if (bytes is null || bytes.Length == 0)
                throw new InvalidOperationException("PFX 导出失败"); // ← 防御性处理

            Directory.CreateDirectory(Path.GetDirectoryName(pfxPath)!);
            File.WriteAllBytes(pfxPath, bytes);
        }

        private async Task<string> GetCertificateChainAsync(string domain)
        {
            // 这里实现获取证书链的逻辑
            // 可以是从文件读取，也可以是通过 ACME 客户端获取
            // 为了示例，返回一个空的证书链
            return await Task.FromResult(string.Empty);
        }
    }
}