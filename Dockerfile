# syntax directive enables BuildKit features (cache mounts)
# Save as Dockerfile
# -----------------------
# Build stage
# -----------------------
# syntax=docker/dockerfile:1.4
ARG DOTNET_SDK_VERSION=8.0
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_SDK_VERSION} AS build
ARG PROJECT_PATH=./src/YourWebApp/YourWebApp.csproj
WORKDIR /src

# Use cache mounts for nuget and the dotnet tools to speed CI builds
# copy csproj(s) only for restore layer caching
COPY *.sln ./
# if you have nested csproj structure, copying all csproj explicitly helps caching
COPY src/ src/

# restore using BuildKit cache mounts
RUN --mount=type=cache,target=/root/.nuget/packages \
    --mount=type=cache,target=/root/.nuget/v3-cache \
    dotnet restore "${PROJECT_PATH}"

# copy everything and publish
COPY . .

# publish optimized release build
RUN --mount=type=cache,target=/root/.nuget/packages \
    dotnet publish "${PROJECT_PATH}" \
      -c Release \
      -o /app/publish \
      /p:UseAppHost=false \
      /p:PublishTrimmed=false

# -----------------------
# Runtime stage (slim)
# -----------------------
ARG DOTNET_ASPNET_VERSION=8.0
FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_ASPNET_VERSION}-slim AS runtime
WORKDIR /app

# create non-root user and set permissions
RUN useradd --create-home appuser && mkdir -p /app && chown -R appuser:appuser /app
USER appuser

# copy published output
COPY --from=build --chown=appuser:appuser /app/publish ./

ENV ASPNETCORE_URLS=http://+:80 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

EXPOSE 80

ENTRYPOINT ["dotnet", "YourWebApp.dll"]
