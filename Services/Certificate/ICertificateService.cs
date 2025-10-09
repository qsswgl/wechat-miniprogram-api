using System.Security.Cryptography.X509Certificates;

namespace WeChatMiniProgramAPI.Services.Certificate
{
    public interface ICertificateService
    {
        Task<CertificateResult> RequestCertificateAsync(string domain, bool isWildcard = true);
        Task<bool> DeployCertificateAsync(string domain, byte[] certificateData, string privateKey);
        Task<CertificateInfo?> GetCertificateInfoAsync(string domain);
        Task<bool> RenewCertificateAsync(string domain);
        Task<List<CertificateInfo>> GetAllCertificatesAsync();
    }

    public class CertificateResult
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public byte[]? CertificateData { get; set; }
        public string? PrivateKey { get; set; }
        public DateTime ExpiryDate { get; set; }
    }

    public class CertificateInfo
    {
        public string Domain { get; set; } = string.Empty;
        public DateTime IssueDate { get; set; }
        public DateTime ExpiryDate { get; set; }
        public bool IsWildcard { get; set; }
        public string FilePath { get; set; } = string.Empty;
        public string Issuer { get; set; } = string.Empty;
    }
}