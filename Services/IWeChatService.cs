namespace WeChatMiniProgramAPI.Services
{
    public interface IWeChatService
    {
        Task<byte[]?> GenerateQrCodeAsync(string accessToken, string scene, string pagePath, int width = 430);
    }
}