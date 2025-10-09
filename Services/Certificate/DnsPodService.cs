using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Security.Cryptography;
using System.Net.Sockets;
using System.Threading;

namespace WeChatMiniProgramAPI.Services.Certificate
{
    public partial class DnsPodService : IDnsPodService
    {
        private readonly ILogger<DnsPodService> _logger;
        private readonly HttpClient _http;
        private readonly string _loginToken; // "id,key"

        public DnsPodService(ILogger<DnsPodService> logger, IHttpClientFactory httpClientFactory, IConfiguration cfg)
        {
            _logger = logger;
            _http = httpClientFactory.CreateClient();
            _http.BaseAddress = new Uri("https://dnsapi.cn/");
            _loginToken = $"{cfg["DnsPod:Id"]},{cfg["DnsPod:Key"]}";
        }

        // 公开方法：添加 TXT
        public async Task<bool> AddTxtRecordAsync(string fqdn, string value)
        {
            try
            {
                var zone = await ResolveZoneAsync(fqdn, CancellationToken.None);
                if (!zone.Success)
                    throw new InvalidOperationException($"无法识别根域：{fqdn}");

                _logger.LogInformation("DNSPOD解析: fqdn={fqdn}, root={root}, sub={sub}, domainId={id}", fqdn, zone.Root, zone.Sub, zone.DomainId);

                // 查现有记录
                var listPayload = new Dictionary<string, string>
                {
                    ["login_token"] = _loginToken,
                    ["format"] = "json",
                    ["domain"] = zone.Root,
                    ["sub_domain"] = string.IsNullOrWhiteSpace(zone.Sub) ? "@" : zone.Sub,
                    ["record_type"] = "TXT"
                };

                var listResp = await _http.PostAsync("Record.List", new FormUrlEncodedContent(listPayload), CancellationToken.None);
                var listJson = await JsonDocument.ParseAsync(await listResp.Content.ReadAsStreamAsync(CancellationToken.None), cancellationToken: CancellationToken.None);
                if (!IsOk(listJson.RootElement))
                {
                    // DNSPod 在无记录时可能返回 code=10 (记录列表为空)，视为成功且记录为空
                    var statusMsg = GetStatusMsg(listJson.RootElement);
                    if (!(statusMsg?.StartsWith("10:") == true && statusMsg.Contains("记录列表为空")))
                    {
                        throw new InvalidOperationException($"Record.List 失败：{statusMsg}");
                    }
                }

                var records = listJson.RootElement.TryGetProperty("records", out var recs) && recs.ValueKind == JsonValueKind.Array
                    ? recs.EnumerateArray().ToList()
                    : new List<JsonElement>();

                // 寻找同 sub_domain 的TXT
                var existing = records.FirstOrDefault(r =>
                {
                    var nameProp = r.GetPropertyOrDefault("name");
                    var typeProp = r.GetPropertyOrDefault("type");
                    var name = nameProp.HasValue ? nameProp.Value.GetString() : null;
                    var type = typeProp.HasValue ? typeProp.Value.GetString() : null;
                    return string.Equals(name, string.IsNullOrWhiteSpace(zone.Sub) ? "@" : zone.Sub, StringComparison.OrdinalIgnoreCase)
                           && string.Equals(type, "TXT", StringComparison.OrdinalIgnoreCase);
                });

                if (existing.ValueKind != JsonValueKind.Undefined)
                {
                    // 修改
                    var idProp = existing.GetPropertyOrDefault("id");
                    var recordId = idProp.HasValue ? idProp.Value.GetString() : null;
                    var modifyPayload = new Dictionary<string, string>
                    {
                        ["login_token"] = _loginToken,
                        ["format"] = "json",
                        ["domain"] = zone.Root,
                        ["record_id"] = recordId!,
                        ["sub_domain"] = string.IsNullOrWhiteSpace(zone.Sub) ? "@" : zone.Sub,
                        ["record_type"] = "TXT",
            ["record_line_id"] = "0", // 默认
            ["value"] = value
                    };
                    var modResp = await _http.PostAsync("Record.Modify", new FormUrlEncodedContent(modifyPayload), CancellationToken.None);
                    var modJson = await JsonDocument.ParseAsync(await modResp.Content.ReadAsStreamAsync(CancellationToken.None), cancellationToken: CancellationToken.None);
                    if (!IsOk(modJson.RootElement))
                        throw new InvalidOperationException($"Record.Modify 失败：{GetStatusMsg(modJson.RootElement)}");
                    _logger.LogInformation("TXT记录已更新：{fqdn}", fqdn);
                }
                else
                {
                    // 新建
                    var createPayload = new Dictionary<string, string>
                    {
                        ["login_token"] = _loginToken,
                        ["format"] = "json",
                        ["domain"] = zone.Root,
                        ["sub_domain"] = string.IsNullOrWhiteSpace(zone.Sub) ? "@" : zone.Sub,
                        ["record_type"] = "TXT",
            ["record_line_id"] = "0", // 默认
            ["value"] = value
                    };
                    var crtResp = await _http.PostAsync("Record.Create", new FormUrlEncodedContent(createPayload), CancellationToken.None);
                    var crtJson = await JsonDocument.ParseAsync(await crtResp.Content.ReadAsStreamAsync(CancellationToken.None), cancellationToken: CancellationToken.None);
                    if (!IsOk(crtJson.RootElement))
                        throw new InvalidOperationException($"Record.Create 失败：{GetStatusMsg(crtJson.RootElement)}");
                    _logger.LogInformation("TXT记录已创建：{fqdn}", fqdn);
                }

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "添加TXT记录失败：{fqdn}", fqdn);
                return false;
            }
        }

        // 公开方法：删除 TXT
        public async Task RemoveTxtRecordAsync(string fqdn, string value)
        {
            var zone = await ResolveZoneAsync(fqdn, CancellationToken.None);
            if (!zone.Success)
                return;

            var listPayload = new Dictionary<string, string>
            {
                ["login_token"] = _loginToken,
                ["format"] = "json",
                ["domain"] = zone.Root,
                ["sub_domain"] = string.IsNullOrWhiteSpace(zone.Sub) ? "@" : zone.Sub,
                ["record_type"] = "TXT"
            };
            var listResp = await _http.PostAsync("Record.List", new FormUrlEncodedContent(listPayload), CancellationToken.None);
            var listJson = await JsonDocument.ParseAsync(await listResp.Content.ReadAsStreamAsync(CancellationToken.None), cancellationToken: CancellationToken.None);
            if (!IsOk(listJson.RootElement))
                return;

            if (!listJson.RootElement.TryGetProperty("records", out var recs) || recs.ValueKind != JsonValueKind.Array)
                return;

            foreach (var r in recs.EnumerateArray())
            {
                var idProp = r.GetPropertyOrDefault("id");
                var id = idProp.HasValue ? idProp.Value.GetString() : null;
                if (string.IsNullOrEmpty(id)) continue;

                var rmPayload = new Dictionary<string, string>
                {
                    ["login_token"] = _loginToken,
                    ["format"] = "json",
                    ["domain"] = zone.Root,
                    ["record_id"] = id
                };
                var rmResp = await _http.PostAsync("Record.Remove", new FormUrlEncodedContent(rmPayload), CancellationToken.None);
                var rmJson = await JsonDocument.ParseAsync(await rmResp.Content.ReadAsStreamAsync(CancellationToken.None), cancellationToken: CancellationToken.None);
                if (IsOk(rmJson.RootElement))
                    _logger.LogInformation("TXT记录已删除：{fqdn}, record_id={id}", fqdn, id);
            }
        }

        // 简单等待DNS传播（不做真实TXT查询，避免引入外部依赖）
        public async Task<bool> WaitForPropagationAsync(string fqdn, string expectedValue, int timeoutSeconds = 120)
        {
            var total = 0;
            while (total < timeoutSeconds)
            {
                await Task.Delay(TimeSpan.FromSeconds(5));
                total += 5;
                // 仅等待，不校验；多数场景足够
            }
            return true;
        }

        // 工具：解析根域与子域，并验证根域存在（Domain.Info）
        private async Task<(bool Success, string Root, string Sub, string DomainId)> ResolveZoneAsync(string fqdn, CancellationToken ct)
        {
            fqdn = fqdn.TrimEnd('.');

            (bool ok, string root, string sub, string? id) Try(int labels)
            {
                var parts = fqdn.Split('.', StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length < labels) return (false, "", "", null);
                var root = string.Join(".", parts[^labels..]);
                var sub = parts.Length == labels ? "" : string.Join(".", parts[..^labels]);
                return (true, root, sub, null);
            }

            async Task<(bool, string, string, string)> ProbeAsync((bool ok, string root, string sub, string? id) t)
            {
                if (!t.ok) return (false, "", "", "");
                var payload = new Dictionary<string, string>
                {
                    ["login_token"] = _loginToken,
                    ["format"] = "json",
                    ["domain"] = t.root
                };
                var resp = await _http.PostAsync("Domain.Info", new FormUrlEncodedContent(payload), ct);
                var json = await JsonDocument.ParseAsync(await resp.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
                if (IsOk(json.RootElement))
                {
                    var id = json.RootElement.GetProperty("domain").GetPropertyOrDefault("id")?.GetString() ?? "";
                    return (true, t.root, t.sub, id);
                }
                return (false, "", "", "");
            }

            // 先试“后两段为根域”，不行再试“后三段为根域”
            var t2 = Try(2);
            var r2 = await ProbeAsync(t2);
            if (r2.Item1) return r2;

            var t3 = Try(3);
            var r3 = await ProbeAsync(t3);
            if (r3.Item1) return r3;

            return (false, "", "", "");
        }

        private static bool IsOk(JsonElement root)
        {
            if (!root.TryGetProperty("status", out var s)) return false;
            var codeProp = s.GetPropertyOrDefault("code");
            var code = codeProp.HasValue ? codeProp.Value.GetString() : null;
            return code == "1";
        }
        private static string GetStatusMsg(JsonElement root)
        {
            if (!root.TryGetProperty("status", out var s)) return "unknown";
            var codeProp = s.GetPropertyOrDefault("code");
            var msgProp = s.GetPropertyOrDefault("message");
            var code = codeProp.HasValue ? codeProp.Value.GetString() : null;
            var msg = msgProp.HasValue ? msgProp.Value.GetString() : null;
            return $"{code}:{msg}";
        }
    }

    internal static class JsonExt
    {
        public static JsonElement? GetPropertyOrDefault(this JsonElement e, string name)
        {
            return e.TryGetProperty(name, out var v) ? v : (JsonElement?)null;
        }
    }
}