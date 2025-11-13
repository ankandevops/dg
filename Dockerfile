# syntax=docker/dockerfile:1.4
ARG DOTNET_SDK_VERSION=8.0
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_SDK_VERSION} AS build
ARG PROJECT_PATH=./webapp/webapp.csproj
WORKDIR /src

# copy solution and project files first (cache-friendly)
COPY webapp.sln ./
COPY webapp/*.csproj ./webapp/

# restore (use BuildKit cache when CI runs with cache mounts)
RUN --mount=type=cache,target=/root/.nuget/packages \
    --mount=type=cache,target=/root/.nuget/v3-cache \
    dotnet restore "${PROJECT_PATH}"

# copy full repo and publish
COPY . .

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

# create non-root user
RUN useradd --create-home appuser && mkdir -p /app && chown -R appuser:appuser /app
USER appuser

COPY --from=build --chown=appuser:appuser /app/publish ./

ENV ASPNETCORE_URLS=http://+:80 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

EXPOSE 80

# If your project assembly name differs, change webapp.dll below
ENTRYPOINT ["dotnet", "webapp.dll"]
