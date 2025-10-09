using Microsoft.Data.SqlClient;
using System.Data;

namespace WeChatMiniProgramAPI.Services
{
    public class DatabaseService : IDatabaseService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<DatabaseService> _logger;

        public DatabaseService(IConfiguration configuration, ILogger<DatabaseService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<string> ExecSqlAsync(Dictionary<string, object> procData)
        {
            try
            {
                var dbName = procData.GetValueOrDefault("DBName")?.ToString();
                var function = procData.GetValueOrDefault("Function")?.ToString();
                var procedureName = procData.GetValueOrDefault("ProcedureName")?.ToString();
                var inputName = procData.GetValueOrDefault("InputName")?.ToString();
                var type = procData.GetValueOrDefault("Type")?.ToString();

                if (string.IsNullOrEmpty(dbName) || string.IsNullOrEmpty(procedureName))
                {
                    _logger.LogError("数据库名称或存储过程名称为空");
                    return string.Empty;
                }

                // 根据DBName构建连接字符串，这里需要根据实际情况调整
                string connectionString = _configuration.GetConnectionString("DefaultConnection")!;
                
                // 如果需要动态切换数据库，可以修改连接字符串
                if (!string.IsNullOrEmpty(dbName))
                {
                    var builder = new SqlConnectionStringBuilder(connectionString);
                    builder.InitialCatalog = dbName;
                    connectionString = builder.ConnectionString;
                }

                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand(procedureName, connection);
                command.CommandType = CommandType.StoredProcedure;
                command.CommandTimeout = 30;

                // 添加参数
                if (!string.IsNullOrEmpty(inputName) && !string.IsNullOrEmpty(type))
                {
                    command.Parameters.AddWithValue($"@{inputName}", type);
                }

                var result = await command.ExecuteScalarAsync();
                return result?.ToString() ?? string.Empty;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "执行数据库操作时发生错误: {Message}", ex.Message);
                return string.Empty;
            }
        }
    }
}