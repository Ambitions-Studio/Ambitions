monitoringConfig = {
  enabled = true,

  serverName = GetConvar("sv_hostname", "Server Using Ambitions"),
  globalLabels = {
    framework = "Ambitions",
    version = "0.6.0",
    environment = "production"
  },

  deploymentType = "grafana_oss", -- grafana_cloud or grafana_oss

  logsEnabled = true,
  metricsEnabled = true,

  grafanaCloud = {
    instanceId = GetConvar("grafana_cloud_instance_id", ""),
    apiKey = GetConvar("grafana_cloud_api_key", ""),

    endpoints = {
      loki = "https://logs-prod-us-central1.grafana.net/loki/api/v1/push",
      prometheus = "https://prometheus-prod-01-us-central-0.grafana.net/api/v1/push",
    }
  },

  grafanaOss = {
    baseUrl = GetConvar("grafana_oss_base_url", ""),
    authMethod = "service_account", --- basic or service_account

    username = GetConvar("grafana_oss_username", "admin"),
    password = GetConvar("grafana_oss_password", "admin"),

    serviceAccountToken = GetConvar("grafana_oss_service_token", ""),

    endpoints = {
      loki = "http://141.94.99.154:3100/loki/api/v1/push",
      prometheus = "http://141.94.99.154:9091/metrics/job/fivem-server",
    }
  },

  security = {
    sanitizeData = false,

    sensitiveFields = {
      "password", "token", "api_key", "secret", "private_key",
      "steamid", "license", "discord", "fivem", "ip", "email",
      "phone", "address", "ssn", "credit_card", "mac_address"
    },
    redactionPlaceholder = "[PROTECTED]",
    verifyTls = true
  },

  debug = {
    enabled = false,
    logPerformance = false,
    validateData = false,
    printQueueStats = false
  }
}