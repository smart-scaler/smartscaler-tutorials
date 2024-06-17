resource "helm_release" "prometheus" {
  namespace        = "monitoring"
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = "25.6.0"
  wait             = true
  verify           = false
  create_namespace = true
}

resource "helm_release" "prometheus-adapter" {
  namespace        = "monitoring"
  name             = "prometheus-adapter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-adapter"
  version          = "4.10.0"
  wait             = true
  verify           = false
  create_namespace = true
}

resource "helm_release" "smartscaler-agent" {
  namespace        = "smart-scaler"
  name             = "smartscaler-agent"
  repository       = "https://smartscaler.nexus.aveshalabs.io/repository/smartscaler-helm-ent-prod/"
  chart            = "smartscaler-agent"
  version          = "2.2.0"
  wait             = true
  verify           = false
  create_namespace = true

  values = ["${file("values.yaml")}"]

  depends_on = [helm_release.prometheus]
}
