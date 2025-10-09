namespace WeChatMiniProgramAPI.Services
{
    public interface IDatabaseService
    {
        Task<string> ExecSqlAsync(Dictionary<string, object> procData);
    }
}