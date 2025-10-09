using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.Extensions.Hosting.WindowsServices;
using Microsoft.AspNetCore.StaticFiles;
using System.Security.Cryptography.X509Certificates;
using WeChatMiniProgramAPI.Services; // ← 新增：用于注册服务

var builder = WebApplication.CreateBuilder(args);

// 服务模式：内容根设为发布目录，便于加载相对路径文件（证书/配置）
if (WindowsServiceHelpers.IsWindowsService())
{
    builder.Host.UseContentRoot(AppContext.BaseDirectory);
}

// Docker环境检测和配置
var isDocker = Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true";
if (isDocker)
{
    builder.Host.UseContentRoot("/app");
}

// CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
    options.AddPolicy("AllowAll", p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
    options.AddPolicy("WeChat",  p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

// Windows 服务
builder.Host.UseWindowsService(options => options.ServiceName = "QSGLAPI");

// 从配置文件读取HTTPS重定向端口
var httpsPort = builder.Configuration.GetValue<int>("ServerConfig:HttpsRedirectPort", 8081);
builder.Services.AddHttpsRedirection(o => o.HttpsPort = httpsPort);

// 注册缺失的应用服务（根据命名空间推断）
builder.Services.AddScoped<IDatabaseService, DatabaseService>();
builder.Services.AddScoped<IWeChatService, WeChatService>();
builder.Services.AddHttpClient();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 仅用 appsettings.json 的 Kestrel:Endpoints
builder.WebHost.UseKestrel((context, options) =>
{
    options.Configure(context.Configuration.GetSection("Kestrel"));
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.UseSwagger();
    app.UseSwaggerUI();
}

// 配置静态文件支持，设置MIME类型映射支持图片格式
var provider = new FileExtensionContentTypeProvider();
provider.Mappings[".png"] = "image/png";
provider.Mappings[".jpg"] = "image/jpeg";
provider.Mappings[".jpeg"] = "image/jpeg";
provider.Mappings[".webp"] = "image/webp";

// 静态文件必须在 UseRouting 之前配置
app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = provider,
    ServeUnknownFileTypes = false
});

app.UseRouting();
app.UseCors();            // 支持 [EnableCors]
app.UseHttpsRedirection();
app.UseAuthorization();

app.MapControllers();
app.Run();