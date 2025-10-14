using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.Extensions.Hosting.WindowsServices;
using Microsoft.AspNetCore.StaticFiles;
using System.Security.Cryptography.X509Certificates;
using System.Text.Json.Serialization.Metadata;
using System.Text.Json;
using Microsoft.AspNetCore.Http.Json;
using WeChatMiniProgramAPI.Services;

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
    options.AddPolicy("WeChat", p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
    options.AddPolicy("myCors", p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

// Windows 服务
builder.Host.UseWindowsService(options => options.ServiceName = "QSGLAPI");

// 从配置文件读取HTTPS重定向端口
var httpsPort = builder.Configuration.GetValue<int>("ServerConfig:HttpsRedirectPort", 8081);
builder.Services.AddHttpsRedirection(o => o.HttpsPort = httpsPort);

// 注册应用服务
builder.Services.AddScoped<IDatabaseService, DatabaseService>();
builder.Services.AddScoped<IWeChatService, WeChatService>();
builder.Services.AddHttpClient();

// 配置JSON序列化选项
builder.Services.Configure<JsonOptions>(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = null; // 保持原始属性名
    options.SerializerOptions.WriteIndented = true;
    options.SerializerOptions.PropertyNameCaseInsensitive = true;
    // 启用反射序列化
    options.SerializerOptions.TypeInfoResolver = new DefaultJsonTypeInfoResolver();
});

// 添加控制器和API文档
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.PropertyNamingPolicy = null;
    options.JsonSerializerOptions.WriteIndented = true;
    options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
    // 启用反射序列化
    options.JsonSerializerOptions.TypeInfoResolver = new DefaultJsonTypeInfoResolver();
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "WeChat Mini Program API",
        Version = "v1",
        Description = "微信小程序API服务，用于生成小程序二维码等功能",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "API Support",
            Email = "admin@qsgl.net"
        }
    });
    
    // 启用XML注释
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }
});

// 仅用 appsettings.json 的 Kestrel:Endpoints
builder.WebHost.UseKestrel((context, options) =>
{
    options.Configure(context.Configuration.GetSection("Kestrel"));
});

var app = builder.Build();

// 开发环境配置
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

// 在所有环境启用Swagger（包括生产环境）
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "WeChat API v1");
    c.RoutePrefix = "swagger"; // 设置Swagger UI路径为 /swagger
});

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