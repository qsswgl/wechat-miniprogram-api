using System.Threading;
using System.Threading.Tasks;

namespace WeChatMiniProgramAPI.Services.Certificate
{
    public interface IDnsPodService
    {
        Task<bool> AddTxtRecordAsync(string fqdn, string value);
        Task RemoveTxtRecordAsync(string fqdn, string value);
        Task<bool> WaitForPropagationAsync(string fqdn, string expectedValue, int timeoutSeconds = 120);
    }
}