# 使用.NET 9 SDK作为构建镜像
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# 复制项目文件
COPY *.csproj .
RUN dotnet restore

# 复制所有源代码
COPY . .

# 构建和发布应用 (Docker环境使用linux-x64)
RUN dotnet publish -c Release -o /app/publish --no-restore -r linux-x64 --self-contained true

# 使用.NET 9 Runtime作为最终镜像
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# 安装必要的包（用于HTTPS和证书）
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 复制发布的应用
COPY --from=build /app/publish .

# 创建证书目录
RUN mkdir -p /app/certificates
RUN mkdir -p /app/wwwroot/uploadall

# 暴露端口
EXPOSE 8080 8081 8082 8083

# 设置环境变量
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080

# 启动应用
ENTRYPOINT ["dotnet", "WeChatMiniProgramAPI.dll"]