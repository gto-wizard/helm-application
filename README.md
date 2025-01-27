# application

## Parameters

### Global parameters

| Name               | Description                                              | Value |
| ------------------ | -------------------------------------------------------- | ----- |
| `imagePullSecrets` | List of secrets containing credentials to image registry | `nil` |
| `nameOverride`     | String to fully override application.name template       | `""`  |

### Common parameters

| Name                               | Description                                                                                                                                                                                                                                              | Value |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| `common.labels`                    | Array with labels to add to all pods                                                                                                                                                                                                                     | `{}`  |
| `common.annotations`               | Array with annotations to add to all pods                                                                                                                                                                                                                | `{}`  |
| `common.topologySpreadConstraints` | List with constraints controlling how pods are spread across the cluster. Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/                                                                                      | `[]`  |
| `common.nodeSelector`              | Array with Node labels for all pods assignment is rendered only if deployments and jobs nodeSelector is empty. ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector                                                | `{}`  |
| `common.tolerations`               | List with Tolerations for all pods assignment is rendered only if deployments and jobs tolerations is empty ref: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/                                                           | `[]`  |
| `common.affinity`                  | Array with Affinity for all pods assignment is rendered only if deployments and jobs affinity is empty. ref: https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/#schedule-a-pod-using-required-node-affinity | `{}`  |
| `common.env`                       | Array with extra environment variables to add to all pods                                                                                                                                                                                                | `{}`  |
| `common.extraEnvConfigMaps`        | Name of existing ConfigMap containing extra env vars for main deployment                                                                                                                                                                                 | `[]`  |
| `common.extraEnvSecrets`           | List of names of existing Secret containing extra env vars for all pods                                                                                                                                                                                  | `[]`  |
| `common.podSecurityContext`        | Set common pod's Security Context (Is rendered only if deployments and jobs podSecurityContext is empty) ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod                              | `{}`  |
| `common.priorityClassName`         | String priorityClassName to add to all Pod: https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#pod-priority/                                                                                                               | `""`  |
| `common.containerSecurityContext`  | Configure Container Security Context (is rendered only if deployments and jobs containerSecurityContext is empty) ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container               | `{}`  |

### Application parameters

| Name                                                        | Description                                                                                                                                                                                           | Value           |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `application.enabled`                                       | Specifies whether application should be created                                                                                                                                                       | `true`          |
| `application.kind`                                          | Specifies whether application Deployment or StatefulSet should be created                                                                                                                             | `Deployment`    |
| `application.labels`                                        | Array with labels to add to application deployment                                                                                                                                                    | `{}`            |
| `application.annotations`                                   | Array with annotations to add to application deployment                                                                                                                                               | `{}`            |
| `application.lifecycle`                                     | Array with lifecycle definitions to add to application deployment                                                                                                                                     | `{}`            |
| `application.topologySpreadConstraints`                     | list with constraints controlling how pods are spread across the cluster. Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/                                   | `[]`            |
| `application.nodeSelector`                                  | Array with Node labels for application pods assignment. ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector                                                    | `{}`            |
| `application.tolerations`                                   | list with Tolerations for application pods assignment. ref: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/                                                             | `[]`            |
| `application.affinity`                                      | Array with Affinity for application pods assignment. ref: https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/#schedule-a-pod-using-required-node-affinity | `{}`            |
| `application.jobs`                                          | List of Kubernetes Job definitions                                                                                                                                                                    | `[]`            |
| `application.podAnnotations`                                | Annotations for application pods. ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/                                                                                 | `{}`            |
| `application.containerPortEnabled`                          | Whether enable container port                                                                                                                                                                         | `true`          |
| `application.containerPort`                                 | Map container ports to host ports                                                                                                                                                                     | `80`            |
| `application.containerPortName`                             | Names the default container port                                                                                                                                                                      | `http`          |
| `application.replicaCount`                                  | Number of application replicas to deploy                                                                                                                                                              | `1`             |
| `application.podDisruptionBudget`                           | Limit the number of concurrent disruptions that your application experiences. Ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/                                                    | `{}`            |
| `application.autoscaling.enabled`                           | Whether enable horizontal pod autoscale                                                                                                                                                               | `false`         |
| `application.autoscaling.minReplicas`                       | Configure a minimum amount of pods                                                                                                                                                                    | `1`             |
| `application.autoscaling.maxReplicas`                       | Configure a maximum amount of pods                                                                                                                                                                    | `100`           |
| `application.autoscaling.targetCPUUtilizationPercentage`    | Define the CPU target to trigger the scaling actions (utilization percentage)                                                                                                                         | `80`            |
| `application.autoscaling.targetMemoryUtilizationPercentage` | Define the memory target to trigger the scaling actions (utilization percentage)                                                                                                                      | `80`            |
| `application.revisionHistoryLimit`                          | Specifies how many old ReplicaSets for this Deployment you want to retain.                                                                                                                            | `4`             |
| `application.updateStrategy.type`                           | StrategyType - Can be set to RollingUpdate or Recreate                                                                                                                                                | `RollingUpdate` |
| `application.initContainers`                                | Add additional init containers to the application pod(s). ref: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/                                                                    | `[]`            |
| `application.sidecars`                                      | Add additional sidecar containers to the application pod(s)                                                                                                                                           | `[]`            |
| `application.command`                                       | Override default container command (useful when using custom images)                                                                                                                                  | `[]`            |
| `application.args`                                          | Override default container args (useful when using custom images)                                                                                                                                     | `[]`            |
| `application.env`                                           | Array with extra environment variables to add to main deployment                                                                                                                                      | `{}`            |
| `application.terminationGracePeriodSeconds`                 | Kubernetes waits for a specified time called the termination grace period. By default, this is 30 seconds.                                                                                            | `30`            |
| `application.extraEnvConfigMaps`                            | Name of existing ConfigMap containing extra env vars for main deployment                                                                                                                              | `[]`            |
| `application.extraEnvSecrets`                               | Name of existing Secret containing extra env vars for main deployment                                                                                                                                 | `[]`            |
| `application.volumes`                                       | Optionally specify extra list of additional volumes for the application pod(s)                                                                                                                        | `[]`            |
| `application.volumeMounts`                                  | Optionally specify extra list of additional volumeMounts for the application container(s)                                                                                                             | `[]`            |
| `application.startupProbe`                                  | customize startupProbe on application pods. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#configure-probes                                       | `{}`            |
| `application.livenessProbe`                                 | customize livenessProbe on application pods                                                                                                                                                           | `{}`            |
| `application.readinessProbe`                                | customize readinessProbe on application pods                                                                                                                                                          | `{}`            |
| `application.podSecurityContext`                            | Set application pod's Security Context. ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod                                            | `{}`            |
| `application.priorityClassName`                             | String priorityClassName to add to application Pod: https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#pod-priority/                                                    | `""`            |
| `application.containerSecurityContext`                      | Set Configure Container Security Context. ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container                                    | `{}`            |
| `application.persistentVolumes`                             | List of persistentVolumes and their definitions                                                                                                                                                       | `[]`            |
| `application.persistence.enabled`                           | enable persistence                                                                                                                                                                                    | `false`         |

### Cronjob parameters

| Name                               | Description                                                                                                                                                                                                                                                                                                                                               | Value       |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `cronjob.enabled`                  | Specifies whether a cronjob should be created                                                                                                                                                                                                                                                                                                             | `false`     |
| `cronjob.nameSuffix`               | Adds name suffix to cronjob deployment                                                                                                                                                                                                                                                                                                                    | `cronjob`   |
| `cronjob.labels`                   | Array with labels to add to cronjob deployment                                                                                                                                                                                                                                                                                                            | `{}`        |
| `cronjob.annotations`              | Array with annotations to add to cronjob deployment                                                                                                                                                                                                                                                                                                       | `{}`        |
| `cronjob.nodeSelector`             | Array with Node labels for cronjob pods assignment. ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector                                                                                                                                                                                                            | `{}`        |
| `cronjob.tolerations`              | list with Tolerations for cronjob pods assignment ref: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/                                                                                                                                                                                                                      | `[]`        |
| `cronjob.affinity`                 | Array with Affinity for cronjob pods assignment. ref: https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/#schedule-a-pod-using-required-node-affinity                                                                                                                                                         | `{}`        |
| `cronjob.args`                     | Override default container args (useful when using custom images)                                                                                                                                                                                                                                                                                         | `[]`        |
| `cronjob.env`                      | Array with extra environment variables to add to cronjob                                                                                                                                                                                                                                                                                                  | `{}`        |
| `cronjob.extraEnvConfigMaps`       | Name of existing ConfigMap containing extra env vars for cronjob                                                                                                                                                                                                                                                                                          | `[]`        |
| `cronjob.extraEnvSecrets`          | Name of existing Secret containing extra env vars for cronjob                                                                                                                                                                                                                                                                                             | `[]`        |
| `cronjob.restartPolicy`            | Only a RestartPolicy equal to Never or OnFailure is allowed                                                                                                                                                                                                                                                                                               | `OnFailure` |
| `cronjob.podSecurityContext`       | Configure cronjob's Pods Security Context. ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod                                                                                                                                                                                             | `{}`        |
| `cronjob.containerSecurityContext` | Configure Configure Container Security Context. ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container                                                                                                                                                                                  | `{}`        |
| `cronjob.resources`                | We usually recommend not to specify default resources and to leave this as a conscious choice for the user. This also increases chances charts run on environments with little resources, such as Minikube. If you do want to specify resources, uncomment the following lines, adjust them as necessary, and remove the curly braces after 'resources:'. | `{}`        |
| `cronjob.command`                  | Override default container command (useful when using custom images)                                                                                                                                                                                                                                                                                      | `[]`        |

### External Secrets parameters

| Name                      | Description                                                         | Value   |
| ------------------------- | ------------------------------------------------------------------- | ------- |
| `externalSecrets.enabled` | Specifies whether a automatic external secrets should be integrated | `false` |
| `externalSecrets.secrets` | List of objects used to fetch by External-Secrets operator          | `[]`    |

### Service Account parameters

| Name                         | Description                                                                                                            | Value   |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`      | Specifies whether a service account should be created                                                                  | `false` |
| `serviceAccount.name`        | The name of the service account to use. If not set and create is true, a name is generated using the fullname template | `""`    |
| `serviceAccount.labels`      | Array with labels to add to serviceAccount                                                                             | `{}`    |
| `serviceAccount.annotations` | Array with annotations to add to serviceAccount                                                                        | `{}`    |

### Configmap parameters

| Name                    | Description                                     | Value   |
| ----------------------- | ----------------------------------------------- | ------- |
| `configmap.enabled`     | Specifies whether a configmap should be created | `false` |
| `configmap.name`        | String with custom name of the configmap        | `""`    |
| `configmap.labels`      | Array with labels to add to configmap           | `{}`    |
| `configmap.annotations` | Array with annotations to add to configmap      | `{}`    |

### Service parameters

| Name                     | Description                                                      | Value       |
| ------------------------ | ---------------------------------------------------------------- | ----------- |
| `service.enabled`        | Specifies whether a service should be created                    | `true`      |
| `service.labels`         | Array with labels to add to service                              | `{}`        |
| `service.annotations`    | Array with annotations to add to service                         | `{}`        |
| `service.type`           | String which allows you to specify what kind of Service you want | `ClusterIP` |
| `service.port`           | Intiger with incoming port                                       | `80`        |
| `service.name`           | String with name of the port                                     | `http`      |
| `service.targetPortName` | String with name of the port to target                           | `http`      |
| `service.extraPorts`     | Map with extra container ports                                   | `[]`        |

### Ingress parameters

| Name                  | Description                                   | Value   |
| --------------------- | --------------------------------------------- | ------- |
| `ingress.enabled`     | Specifies whether a ingress should be created | `false` |
| `ingress.labels`      | Array with labels to add to ingresss          | `{}`    |
| `ingress.annotations` | Array with annotations to add to ingresss     | `{}`    |

### Ingresses parameters

| Name                | Description                                     | Value   |
| ------------------- | ----------------------------------------------- | ------- |
| `ingresses.enabled` | Specifies whether a ingresses should be created | `false` |

### Service Monitor parameters

| Name                           | Description                                           | Value      |
| ------------------------------ | ----------------------------------------------------- | ---------- |
| `serviceMonitor.enabled`       | Specifies whether a service monitor should be created | `false`    |
| `serviceMonitor.labels`        | Array with labels to add to serviceMonitor            | `{}`       |
| `serviceMonitor.interval`      | How often should the metrics be scraped               | `30s`      |
| `serviceMonitor.path`          | HTTP path to scrape for metrics.                      | `/metrics` |
| `serviceMonitor.scheme`        | HTTP scheme to use for scraping.                      | `""`       |
| `serviceMonitor.tlsConfig`     | TLS configuration to use when scraping the endpoint   | `{}`       |
| `serviceMonitor.scrapeTimeout` | Timeout after which the scrape is ended               | `""`       |

### RBAC parameters.

| Name           | Description                                | Value   |
| -------------- | ------------------------------------------ | ------- |
| `rbac.enabled` | Specifies whether a role should be created | `false` |
| `rbac.roles`   | Create Roles (Namespaced)                  | `[]`    |

### Keda ScaledObject parameters. Ref: https://keda.sh/docs/2.13/concepts/scaling-deployments/

| Name                    | Description                                                                                                                                              | Value   |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `keda.enabled`          | Specifies whether a KEDA ScaledObject should be created                                                                                                  | `false` |
| `keda.labels`           | Array with labels to add to all pods                                                                                                                     | `{}`    |
| `keda.annotations`      | Array with annotations to add to all pods                                                                                                                | `{}`    |
| `keda.pollingInterval`  | This is the interval to check each trigger on                                                                                                            | `30`    |
| `keda.cooldownPeriod`   | The period to wait after the last trigger reported active before scaling the resource back to 0                                                          | `300`   |
| `keda.idleReplicaCount` | If this property is set, KEDA will scale the resource down to this number of replicas.                                                                   | `0`     |
| `keda.minReplicaCount`  | Minimum number of replicas KEDA will scale the resource down to.                                                                                         | `1`     |
| `keda.maxReplicaCount`  | This setting is passed to the HPA definition that KEDA will create for a given resource and holds the maximum number of replicas of the target resource. | `100`   |
| `keda.fallback`         | Defines a number of replicas to fall back to if a scaler is in an error state. Ref: https://keda.sh/docs/2.13/concepts/scaling-deployments/#fallback     | `{}`    |
| `keda.advanced`         | Ref: https://keda.sh/docs/2.13/concepts/scaling-deployments/#advanced                                                                                    | `{}`    |
| `keda.triggers`         | List of triggers to activate scaling of the target resource. Ref: https://keda.sh/docs/2.13/concepts/scaling-deployments/#triggers                       | `[]`    |
