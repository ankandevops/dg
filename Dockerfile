# syntax=docker/dockerfile:1.4
ARG DOTNET_SDK_VERSION=8.0
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_SDK_VERSION} AS build
ARG PROJECT_PATH=./WebApplication1/WebApplication1.csproj
WORKDIR /src

# copy solution + project files (cache-friendly)
COPY WebApplication1.sln ./
COPY WebApplication1/ WebApplication1/

# restore using BuildKit cache mounts
RUN --mount=type=cache,target=/root/.nuget/packages \
    --mount=type=cache,target=/root/.nuget/v3-cache \
    dotnet restore "${PROJECT_PATH}"

# copy remaining sources
COPY . .

# publish (framework-dependent, no apphost for lean image)
RUN --mount=type=cache,target=/root/.nuget/packages \
    dotnet publish "${PROJECT_PATH}" \
      -c Release \
      -o /app/publish \
      /p:UseAppHost=false \
      /p:PublishTrimmed=false

# Runtime stage (slim)
ARG DOTNET_ASPNET_VERSION=8.0
FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_ASPNET_VERSION}-slim AS runtime
WORKDIR /app

# non-root user
RUN useradd --create-home appuser && chown -R appuser:appuser /app
USER appuser

# copy published output
COPY --from=build --chown=appuser:appuser /app/publish ./

ENV ASPNETCORE_URLS=http://+:80 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

EXPOSE 80

ENTRYPOINT ["dotnet", "WebApplication1.dll"]
