namespace WeChatMiniProgramAPI.Models
{
    /// <summary>
    /// 证书申请请求模型
    /// </summary>
    public class CertificateRequestModel
    {
        /// <summary>
        /// 域名，如：qsgl.net
        /// </summary>
        public string Domain { get; set; } = string.Empty;

        /// <summary>
        /// 是否申请泛域名证书，默认true
        /// </summary>
        public bool IsWildcard { get; set; } = true;
    }

    /// <summary>
    /// 证书续订请求模型
    /// </summary>
    public class CertificateRenewModel
    {
        /// <summary>
        /// 域名，如：qsgl.net
        /// </summary>
        public string Domain { get; set; } = string.Empty;
    }
}